// ==============================================================================
// CPM AXI Performance Monitor
// ==============================================================================
// This UVM component monitors AXI transactions and calculates performance
// metrics including:
//   - Bandwidth (GB/s) for read and write operations
//   - Transaction latency (min/max/average)
//   - Outstanding transaction depth
//   - Protocol compliance via assertions
// ==============================================================================

`ifndef CPM_AXI_PERF_MONITOR_SV
`define CPM_AXI_PERF_MONITOR_SV

class cpm_axi_perf_monitor extends uvm_monitor;
    `uvm_component_utils(cpm_axi_perf_monitor)

    // Virtual interface
    virtual axi_if vif;

    // Port ID for this monitor instance
    int port_id;
    string port_name;

    // Performance metrics storage
    typedef struct {
        real    write_bandwidth_gbps;
        real    read_bandwidth_gbps;
        longint write_bytes;
        longint read_bytes;
        real    write_latency_min_ns;
        real    write_latency_max_ns;
        real    write_latency_avg_ns;
        real    read_latency_min_ns;
        real    read_latency_max_ns;
        real    read_latency_avg_ns;
        int     write_transactions;
        int     read_transactions;
        int     peak_outstanding_wr;
        int     peak_outstanding_rd;
        int     protocol_violations;
        real    simulation_time_ns;
    } perf_metrics_t;

    perf_metrics_t metrics;

    // Transaction tracking — use queues per ID to handle multiple outstanding
    // transactions with the same AXI ID (AXI4 allows this; responses are
    // in-order per ID).
    typedef struct {
        time start_time;
        int  burst_len;
        bit [9:0] id;
        int  beats_received;
    } txn_tracker_t;

    txn_tracker_t wr_txn_queues[bit[9:0]][$];  // Queue per AWID
    txn_tracker_t rd_txn_queues[bit[9:0]][$];  // Queue per ARID

    int current_outstanding_wr;
    int current_outstanding_rd;

    real total_write_latency;
    real total_read_latency;

    time sim_start_time;

    // Analysis port for sending metrics to scoreboard
    uvm_analysis_port #(perf_metrics_t) metrics_ap;

    // ========================================================================
    // Constructor
    // ========================================================================
    function new(string name = "cpm_axi_perf_monitor", uvm_component parent = null);
        super.new(name, parent);
        metrics_ap = new("metrics_ap", this);
    endfunction

    // ========================================================================
    // Build Phase
    // ========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Virtual interface not set")

        if (!uvm_config_db#(int)::get(this, "", "port_id", port_id))
            port_id = 0;

        port_name = $sformatf("cpm_axi_pl%0d", port_id);

        // Initialize metrics
        reset_metrics();
    endfunction

    // ========================================================================
    // Reset Metrics
    // ========================================================================
    function void reset_metrics();
        metrics.write_bandwidth_gbps = 0.0;
        metrics.read_bandwidth_gbps = 0.0;
        metrics.write_bytes = 0;
        metrics.read_bytes = 0;
        metrics.write_latency_min_ns = 1e9;  // Large initial value
        metrics.write_latency_max_ns = 0.0;
        metrics.write_latency_avg_ns = 0.0;
        metrics.read_latency_min_ns = 1e9;
        metrics.read_latency_max_ns = 0.0;
        metrics.read_latency_avg_ns = 0.0;
        metrics.write_transactions = 0;
        metrics.read_transactions = 0;
        metrics.peak_outstanding_wr = 0;
        metrics.peak_outstanding_rd = 0;
        metrics.protocol_violations = 0;
        metrics.simulation_time_ns = 0.0;

        current_outstanding_wr = 0;
        current_outstanding_rd = 0;
        total_write_latency = 0.0;
        total_read_latency = 0.0;

        wr_txn_queues.delete();
        rd_txn_queues.delete();
    endfunction

    // ========================================================================
    // Run Phase - Monitor AXI transactions
    // ========================================================================
    task run_phase(uvm_phase phase);
        sim_start_time = $time;

        fork
            monitor_write_address();
            monitor_write_data();
            monitor_write_response();
            monitor_read_address();
            monitor_read_data();
            track_outstanding();
        join_none

    endtask

    // ========================================================================
    // Monitor Write Address Channel
    // ========================================================================
    task monitor_write_address();
        forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.awvalid && vif.monitor_cb.awready) begin
                bit [9:0] awid = vif.monitor_cb.awid;
                txn_tracker_t tracker;

                tracker.start_time = $time;
                tracker.burst_len = vif.monitor_cb.awlen + 1;  // AWLEN is 0-based
                tracker.id = awid;
                tracker.beats_received = 0;

                wr_txn_queues[awid].push_back(tracker);
                current_outstanding_wr++;

                `uvm_info(get_type_name(),
                    $sformatf("[%s] Write Addr: ID=0x%0h, Addr=0x%0h, Len=%0d",
                        port_name, awid, vif.monitor_cb.awaddr, tracker.burst_len),
                    UVM_HIGH)
            end
        end
    endtask

    // ========================================================================
    // Monitor Write Data Channel
    // ========================================================================
    task monitor_write_data();
        forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.wvalid && vif.monitor_cb.wready) begin
                // Calculate bytes transferred based on wstrb
                int byte_count = $countones(vif.monitor_cb.wstrb);
                metrics.write_bytes += byte_count;

                if (vif.monitor_cb.wlast) begin
                    `uvm_info(get_type_name(),
                        $sformatf("[%s] Write Data Complete (WLAST)", port_name),
                        UVM_HIGH)
                end
            end
        end
    endtask

    // ========================================================================
    // Monitor Write Response Channel
    // ========================================================================
    task monitor_write_response();
        forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.bvalid && vif.monitor_cb.bready) begin
                bit [9:0] bid = vif.monitor_cb.bid;

                if (wr_txn_queues.exists(bid) && wr_txn_queues[bid].size() > 0) begin
                    txn_tracker_t tracker = wr_txn_queues[bid].pop_front();
                    real latency_ns = ($time - tracker.start_time) / 1000.0;  // ps to ns

                    // Update latency statistics
                    if (latency_ns < metrics.write_latency_min_ns)
                        metrics.write_latency_min_ns = latency_ns;
                    if (latency_ns > metrics.write_latency_max_ns)
                        metrics.write_latency_max_ns = latency_ns;

                    total_write_latency += latency_ns;
                    metrics.write_transactions++;

                    current_outstanding_wr--;

                    // Clean up empty queue entry
                    if (wr_txn_queues[bid].size() == 0)
                        wr_txn_queues.delete(bid);

                    `uvm_info(get_type_name(),
                        $sformatf("[%s] Write Complete: ID=0x%0h, Latency=%.2f ns, BRESP=%0d",
                            port_name, bid, latency_ns, vif.monitor_cb.bresp),
                        UVM_MEDIUM)

                    // Check for error response
                    if (vif.monitor_cb.bresp != 2'b00) begin
                        `uvm_warning(get_type_name(),
                            $sformatf("[%s] Non-OKAY write response: BRESP=%0d",
                                port_name, vif.monitor_cb.bresp))
                        metrics.protocol_violations++;
                    end
                end else begin
                    `uvm_error(get_type_name(),
                        $sformatf("[%s] Unexpected BID=0x%0h (no matching AWID)",
                            port_name, bid))
                    metrics.protocol_violations++;
                end
            end
        end
    endtask

    // ========================================================================
    // Monitor Read Address Channel
    // ========================================================================
    task monitor_read_address();
        forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.arvalid && vif.monitor_cb.arready) begin
                bit [9:0] arid = vif.monitor_cb.arid;
                txn_tracker_t tracker;

                tracker.start_time = $time;
                tracker.burst_len = vif.monitor_cb.arlen + 1;  // ARLEN is 0-based
                tracker.id = arid;
                tracker.beats_received = 0;

                rd_txn_queues[arid].push_back(tracker);
                current_outstanding_rd++;

                `uvm_info(get_type_name(),
                    $sformatf("[%s] Read Addr: ID=0x%0h, Addr=0x%0h, Len=%0d",
                        port_name, arid, vif.monitor_cb.araddr, tracker.burst_len),
                    UVM_HIGH)
            end
        end
    endtask

    // ========================================================================
    // Monitor Read Data Channel
    // ========================================================================
    task monitor_read_data();
        forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.rvalid && vif.monitor_cb.rready) begin
                bit [9:0] rid = vif.monitor_cb.rid;

                // Assume full 64 bytes per beat (512 bits)
                metrics.read_bytes += 64;

                if (rd_txn_queues.exists(rid) && rd_txn_queues[rid].size() > 0) begin
                    rd_txn_queues[rid][0].beats_received++;

                    if (vif.monitor_cb.rlast) begin
                        txn_tracker_t tracker = rd_txn_queues[rid].pop_front();
                        real latency_ns = ($time - tracker.start_time) / 1000.0;  // ps to ns

                        // Update latency statistics
                        if (latency_ns < metrics.read_latency_min_ns)
                            metrics.read_latency_min_ns = latency_ns;
                        if (latency_ns > metrics.read_latency_max_ns)
                            metrics.read_latency_max_ns = latency_ns;

                        total_read_latency += latency_ns;
                        metrics.read_transactions++;

                        current_outstanding_rd--;

                        // Clean up empty queue entry
                        if (rd_txn_queues[rid].size() == 0)
                            rd_txn_queues.delete(rid);

                        `uvm_info(get_type_name(),
                            $sformatf("[%s] Read Complete: ID=0x%0h, Latency=%.2f ns, RRESP=%0d",
                                port_name, rid, latency_ns, vif.monitor_cb.rresp),
                            UVM_MEDIUM)

                        // Check for error response
                        if (vif.monitor_cb.rresp != 2'b00) begin
                            `uvm_warning(get_type_name(),
                                $sformatf("[%s] Non-OKAY read response: RRESP=%0d",
                                    port_name, vif.monitor_cb.rresp))
                            metrics.protocol_violations++;
                        end
                    end
                end else begin
                    if (vif.monitor_cb.rlast) begin
                        `uvm_error(get_type_name(),
                            $sformatf("[%s] Unexpected RID=0x%0h (no matching ARID)",
                                port_name, rid))
                        metrics.protocol_violations++;
                    end
                end
            end
        end
    endtask

    // ========================================================================
    // Track Outstanding Transactions
    // ========================================================================
    task track_outstanding();
        forever begin
            @(vif.monitor_cb);

            if (current_outstanding_wr > metrics.peak_outstanding_wr)
                metrics.peak_outstanding_wr = current_outstanding_wr;

            if (current_outstanding_rd > metrics.peak_outstanding_rd)
                metrics.peak_outstanding_rd = current_outstanding_rd;
        end
    endtask

    // ========================================================================
    // Extract Phase - Calculate final metrics
    // ========================================================================
    function void extract_phase(uvm_phase phase);
        real sim_time_ns;
        super.extract_phase(phase);

        sim_time_ns = ($time - sim_start_time) / 1000.0;  // ps to ns
        metrics.simulation_time_ns = sim_time_ns;

        if (sim_time_ns > 0) begin
            // Calculate bandwidth in GB/s
            // GB/s = (Bytes / (time_ns * 1e-9)) / 1e9 = Bytes / time_ns
            metrics.write_bandwidth_gbps = (metrics.write_bytes / sim_time_ns);
            metrics.read_bandwidth_gbps = (metrics.read_bytes / sim_time_ns);
        end

        // Calculate average latencies
        if (metrics.write_transactions > 0)
            metrics.write_latency_avg_ns = total_write_latency / metrics.write_transactions;

        if (metrics.read_transactions > 0)
            metrics.read_latency_avg_ns = total_read_latency / metrics.read_transactions;

        // Handle case where no transactions occurred
        if (metrics.write_latency_min_ns == 1e9)
            metrics.write_latency_min_ns = 0.0;
        if (metrics.read_latency_min_ns == 1e9)
            metrics.read_latency_min_ns = 0.0;

    endfunction

    // ========================================================================
    // Report Phase - Display performance metrics
    // ========================================================================
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info(get_type_name(), {"\n", get_performance_report()}, UVM_LOW)

        // Send metrics to scoreboard via analysis port
        metrics_ap.write(metrics);
    endfunction

    // ========================================================================
    // Get Performance Report String
    // ========================================================================
    function string get_performance_report();
        string report;

        report = $sformatf("\n");
        report = {report, $sformatf("========================================\n")};
        report = {report, $sformatf("  Performance Report: %s\n", port_name)};
        report = {report, $sformatf("========================================\n")};
        report = {report, $sformatf("Simulation Time:     %.2f us\n",
            metrics.simulation_time_ns / 1000.0)};
        report = {report, $sformatf("----------------------------------------\n")};
        report = {report, $sformatf("WRITE PERFORMANCE:\n")};
        report = {report, $sformatf("  Transactions:      %0d\n",
            metrics.write_transactions)};
        report = {report, $sformatf("  Total Bytes:       %0d (%.2f MB)\n",
            metrics.write_bytes, metrics.write_bytes / 1048576.0)};
        report = {report, $sformatf("  Bandwidth:         %.3f GB/s\n",
            metrics.write_bandwidth_gbps)};
        report = {report, $sformatf("  Latency Min:       %.2f ns\n",
            metrics.write_latency_min_ns)};
        report = {report, $sformatf("  Latency Avg:       %.2f ns\n",
            metrics.write_latency_avg_ns)};
        report = {report, $sformatf("  Latency Max:       %.2f ns\n",
            metrics.write_latency_max_ns)};
        report = {report, $sformatf("  Peak Outstanding:  %0d\n",
            metrics.peak_outstanding_wr)};
        report = {report, $sformatf("----------------------------------------\n")};
        report = {report, $sformatf("READ PERFORMANCE:\n")};
        report = {report, $sformatf("  Transactions:      %0d\n",
            metrics.read_transactions)};
        report = {report, $sformatf("  Total Bytes:       %0d (%.2f MB)\n",
            metrics.read_bytes, metrics.read_bytes / 1048576.0)};
        report = {report, $sformatf("  Bandwidth:         %.3f GB/s\n",
            metrics.read_bandwidth_gbps)};
        report = {report, $sformatf("  Latency Min:       %.2f ns\n",
            metrics.read_latency_min_ns)};
        report = {report, $sformatf("  Latency Avg:       %.2f ns\n",
            metrics.read_latency_avg_ns)};
        report = {report, $sformatf("  Latency Max:       %.2f ns\n",
            metrics.read_latency_max_ns)};
        report = {report, $sformatf("  Peak Outstanding:  %0d\n",
            metrics.peak_outstanding_rd)};
        report = {report, $sformatf("----------------------------------------\n")};
        report = {report, $sformatf("PROTOCOL COMPLIANCE:\n")};
        report = {report, $sformatf("  Violations:        %0d\n",
            metrics.protocol_violations)};
        report = {report, $sformatf("========================================\n")};

        return report;
    endfunction

endclass : cpm_axi_perf_monitor

`endif // CPM_AXI_PERF_MONITOR_SV
