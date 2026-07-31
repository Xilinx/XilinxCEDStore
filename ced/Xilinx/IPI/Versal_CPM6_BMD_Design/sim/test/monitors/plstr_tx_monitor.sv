//-----------------------------------------------------------------------------
//
// Project    : Versal PCI Express Integrated Block
// File       : plstr_tx_monitor.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: plstr_tx_monitor.sv
//--
//-- Description:
//--                -Captures the internal (between BMD and pstbr) tx interfaces.
//--                 Will write each valid beat of slots to analysis port.
//--
//--------------------------------------------------------------------------------
class plstr_tx_monitor_c extends uvm_monitor;
`uvm_component_utils(plstr_tx_monitor_c)

// Analysis port to send transactions to the scoreboard
uvm_analysis_port #(tx_str_transaction) tx_str_ap;

// Virtual interface
virtual plstr_tx_if     tx_str_vif;
virtual plstr_credit_if tx_cr_vif;

int unsigned num_transactions;
int unsigned num_valid_transactions;
int unsigned num_posted_transactions;
int unsigned num_nonposted_transactions;
int unsigned num_nonposted_wdata_transactions;
int unsigned num_completion_transactions;

bit pkt_in_prog;
int unsigned num_starts;
int unsigned num_ends;
int unsigned exp_data_slots;
int unsigned cur_data_slots;

int unsigned credits_used;
int unsigned credits_returned;
int unsigned credit_pool;

tx_str_transaction tx;

bit [7:0][6:0] credit_encoding = {7'd64, 7'd32, 7'd16, 7'd8, 7'd4, 7'd2, 7'd1, 7'd0};

// DMA bandwidth tracking
longint unsigned wr_dma_bytes;       // MWr: device writing to host
int unsigned     wr_dma_count;
real             wr_dma_first;
real             wr_dma_last;
bit              wr_dma_started;

int unsigned     rd_dma_mrd_count;   // MRd: device read requests to host
real             rd_dma_first;
real             rd_dma_last;
bit              rd_dma_started;

// Constructor
function new(string name = "plstr_tx_monitor", uvm_component parent = null);
    super.new(name, parent);
    tx_str_ap = new("tx_str_ap", this);
endfunction

// Build phase
virtual function void build_phase(uvm_phase phase);
    phase.raise_objection(this);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual plstr_tx_if)::get(this, "", "tx_str_vif", tx_str_vif))
        `uvm_fatal("NOVIF", "Virtual interface [transaction] not set for this monitor")
    if (!uvm_config_db#(virtual plstr_credit_if)::get(this, "", "tx_cr_vif", tx_cr_vif))
        `uvm_fatal("NOVIF", "Virtual interface [credits] not set for this monitor")
    phase.drop_objection(this);
endfunction

// Collect a single transaction from the interface
protected task collect_transaction();
    int used_start = 0;
    int used_end = 0;
    string txn_des = "";

    // Wait for clock edge using the clocking block
    @(tx_str_vif.monitor_cb);

    num_transactions++;

    // Check if this is a valid transaction we should capture
    if (tx_str_vif.monitor_cb.tx_intf.tx_valid) begin
        num_valid_transactions++;

        // Bandwidth timing is tracked per-type below

        // Sample all fields from the interface struct
        for (int i = 0; i < pcie_str_pkg::NUM_SLOTS; i++) begin

            // Packet starts here, so we should capture this header
            if (tx_str_vif.monitor_cb.tx_intf.tx_start[used_start] == 1'b1 &&
            tx_str_vif.monitor_cb.tx_intf.tx_startptr[used_start] == i) begin

                credits_used++; // increment credits used since valid slot
                tx = tx_str_transaction::type_id::create("tx");
                cur_data_slots = 0;
                exp_data_slots = 0;

                // Capture type of packet
                case(tx_str_vif.monitor_cb.tx_intf.tx_starttype[used_start])
                    2'b00 : begin
                        // Save header to transaction
                        tx.header = tx_str_vif.monitor_cb.tx_intf.tx_data[i];

                        txn_des = {txn_des, "  P  "};
                        tx.ttype = 2'b00;
                        num_posted_transactions++;
                        // Write DMA tracking (MWr)
                        wr_dma_bytes += tx_str_vif.monitor_cb.tx_intf.tx_data[i].p.byte_len;
                        wr_dma_count++;
                        if (!wr_dma_started) begin
                            wr_dma_first = $realtime;
                            wr_dma_started = 1;
                        end
                        wr_dma_last = $realtime;
                        // Number of data slots
                        if (tx_str_vif.monitor_cb.tx_intf.tx_data[i].p.byte_len != 0) begin
                            exp_data_slots = (((tx_str_vif.monitor_cb.tx_intf.tx_data[i].p.byte_len << 3) - 1) /
                                pcie_str_pkg::DATA_SLOT_WIDTH) + 1;
                        end
                    end

                    2'b01 : begin
                        int num_valid_subslots = 0;
                        for (int j = 0; j < pcie_str_pkg::START_NP_INFO_WIDTH; j++) begin
                            if (tx_str_vif.monitor_cb.tx_intf.tx_startnpinfo[used_start][j]) begin
                                num_valid_subslots++;
                            end
                        end

                        if (num_valid_subslots == 0) begin
                            // Save header to transaction
                            tx.header = tx_str_vif.monitor_cb.tx_intf.tx_data[i];
                            tx.ttype = 2'b11;
                            txn_des = {txn_des, " NPD "};
                            // Number of data slots
                            if (tx_str_vif.monitor_cb.tx_intf.tx_data[i].npd.byte_len != 0) begin
                                exp_data_slots = (((tx_str_vif.monitor_cb.tx_intf.tx_data[i].npd.byte_len << 3) - 1) /
                                    pcie_str_pkg::DATA_SLOT_WIDTH) + 1;
                            end
                            num_nonposted_wdata_transactions++;
                        end else begin
                            txn_des = {txn_des, $sformatf(" NP%0d ", num_valid_subslots)};
                            for (int j = 0; j < num_valid_subslots - 1; j++) begin
                                // Save header to transaction
                                tx.ttype = 2'b01;
                                tx.header = tx_str_vif.monitor_cb.tx_intf.tx_data[i].np[j];
                                tx_str_ap.write(tx);
                                tx = tx_str_transaction::type_id::create("tx");
                            end
                            tx.ttype = 2'b01;
                            tx.header = tx_str_vif.monitor_cb.tx_intf.tx_data[i].np[num_valid_subslots-1];
                            // Number of data slots
                            exp_data_slots = 0;
                            num_nonposted_transactions += num_valid_subslots;
                            // Read DMA tracking (MRd requests)
                            rd_dma_mrd_count += num_valid_subslots;
                            if (!rd_dma_started) begin
                                rd_dma_first = $realtime;
                                rd_dma_started = 1;
                            end
                            rd_dma_last = $realtime;
                        end
                    end

                    2'b10 : begin
                        // Save header to transaction
                        tx.header = tx_str_vif.monitor_cb.tx_intf.tx_data[i];

                        txn_des = {txn_des, " CPL "};
                        tx.ttype = 2'b10;
                        num_completion_transactions++;
                        // CplD on TX = device responding to host reads (not DMA) — ignored for DMA perf
                        // Number of data slots
                        if (tx_str_vif.monitor_cb.tx_intf.tx_data[i].cpl.byte_len != 0) begin
                            exp_data_slots = (((tx_str_vif.monitor_cb.tx_intf.tx_data[i].cpl.byte_len << 3) - 1) /
                                pcie_str_pkg::DATA_SLOT_WIDTH) + 1;
                        end
                    end

                    default : begin
                        `uvm_error(get_type_name(), "Invalid start type value");
                    end
                endcase

                // Initialize data to hold number of data slots
                if (exp_data_slots != 0)
                    tx.data = new[exp_data_slots];

                // Increment statistics
                used_start++; // pointer for this iter
                num_starts++; // overall count
                pkt_in_prog = 1;
            end
            // Not a header, so must be data
            else if (pkt_in_prog) begin
                credits_used++; // increment credits used since valid slot
                txn_des = {txn_des, " DATA"};
                // push onto txn data
                tx.data[cur_data_slots] = tx_str_vif.monitor_cb.tx_intf.tx_data[i];
                cur_data_slots++;
            end
            else begin
                txn_des = {txn_des, "     "};
            end

            // Packet ends here, so we should disable prog,
            // increment counts, and write tx
            if (tx_str_vif.monitor_cb.tx_intf.tx_end[used_end] == 1'b1 &&
            tx_str_vif.monitor_cb.tx_intf.tx_endptr[used_end][5:4] == i) begin
                if (cur_data_slots != exp_data_slots) begin
                    `uvm_error(get_type_name(),
                        {"Streaming interface did not deliver expected amount of data slots:\n",
                        $sformatf("Expected slots: %0d; Actual slots: %0d", exp_data_slots, cur_data_slots)});
                end
                pkt_in_prog = 0;
                used_end++;
                num_ends++;

                tx_str_ap.write(tx);
            end
            if (i != pcie_str_pkg::NUM_SLOTS - 1)
                txn_des = {txn_des, " | "};
        end

        // Debug message with transaction details
        `uvm_info(get_type_name(),
                 $sformatf("Captured transaction (#%0d):                                %s",
                 num_valid_transactions, txn_des), UVM_MEDIUM)
    end
endtask

protected task collect_credit();
    // Wait for clock edge using the clocking block
    @(tx_cr_vif.monitor_cb);
    // Make sure credit interface is active
    if (tx_cr_vif.monitor_cb.cr_active) begin
        // Check if this cycle has valid credits
        if (tx_cr_vif.monitor_cb.cr_valid) begin
            credits_returned = credits_returned +
                credit_encoding[tx_cr_vif.monitor_cb.cr];
        end
    end
endtask

protected task compare_credit();
    if (credits_used == 0) begin // no credits used yet
        credit_pool = credits_returned; //Therefore any credits returned are part of our pool
    end
endtask

// Run phase
task run_phase(uvm_phase phase);
    // Initialize counters
    num_transactions                    = 0;
    num_valid_transactions              = 0;
    num_posted_transactions             = 0;
    num_nonposted_transactions          = 0;
    num_nonposted_wdata_transactions    = 0;
    num_completion_transactions         = 0;

    num_starts                      = 0;
    num_ends                        = 0;
    exp_data_slots                  = 0;
    cur_data_slots                  = 0;

    credits_used                    = 0;
    credits_returned                = 0;

    wr_dma_bytes                    = 0;
    wr_dma_count                    = 0;
    wr_dma_first                    = 0;
    wr_dma_last                     = 0;
    wr_dma_started                  = 0;
    rd_dma_mrd_count                = 0;
    rd_dma_first                    = 0;
    rd_dma_last                     = 0;
    rd_dma_started                  = 0;

    pkt_in_prog                     = 0;
    forever begin
        fork
            collect_transaction(); // track transactions
            collect_credit(); // track credit returns
        join
        compare_credit(); // update credit pool
        if (credits_used > credits_returned) begin
            `uvm_error(get_type_name(), $sformatf("Credit allowance exceeded %0d/%0d", credits_used, credits_returned));
        end
    end
endtask

virtual function void write_logs();
    int f = $fopen("./tx_str_monitor.txt", "w");
    $fwrite(f, {
        $sformatf("Monitor Statistics:\n  Total cycles monitored:     %0d\n  Valid transactions (cycle): %0d\n\n",
        num_transactions, num_valid_transactions),
        $sformatf("# Posted:          %0d\n# Non-Posted:      %0d\n# Non-Posted w/ D: %0d\n# Completions:     %0d\n\n",
        num_posted_transactions, num_nonposted_transactions, num_nonposted_wdata_transactions, num_completion_transactions),
        $sformatf("Number of indicated starts: %0d\nNumber of indicated ends:   %0d\n\n",
        num_starts, num_ends),
        $sformatf("Number of credits used: %0d\nNumber of credits returned: %0d\nNumber of credits in pool: %0d\n\n",
        credits_used, credits_returned, credit_pool)});
    $fclose(f);
endfunction

// Report statistics at end of test
virtual function void call_report();
    if (credit_pool != credits_returned - credits_used) begin
        `uvm_error(get_type_name(), $sformatf("Credit imbalance at end of test: %0d remaining instead of %0d",
                                                (credits_returned - credits_used), credit_pool));
    end
    if (num_starts != num_ends)
        `uvm_error(get_type_name(), "Amount of starts != amount of ends!\nThere was an error in packing!")

    // DMA bandwidth report (TX PLSTR = device outbound)
    begin : tx_bw_report
        real wr_dur_ns, wr_bw, slot_util;
        wr_dur_ns = (wr_dma_started) ?
            (wr_dma_last - wr_dma_first) / 1000.0 : 0;
        wr_bw = (wr_dur_ns > 0) ? real'(wr_dma_bytes) / wr_dur_ns : 0;
        slot_util = (num_transactions > 0) ?
            (real'(num_valid_transactions) / real'(num_transactions)) * 100.0 : 0;

        `uvm_info(get_type_name(), $sformatf({
            "\n",
            "TX PLSTR DMA Report:\n",
            "  Write DMA (MWr):   %0.4f GB/s  (%0d bytes, %0d TLPs, %0.2f ns)\n",
            "  Read DMA (MRd):    %0d requests sent\n",
            "  Slot utilization:  %0.1f%%  (%0d valid / %0d total cycles)"},
            wr_bw, wr_dma_bytes, wr_dma_count, wr_dur_ns,
            rd_dma_mrd_count,
            slot_util, num_valid_transactions, num_transactions), UVM_LOW)
    end
endfunction
endclass
