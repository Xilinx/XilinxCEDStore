// Check that number of memory reads = number of received completions - bmd_read_scoreboard
//     > will also verify against received cpls CSR
// Check that number of memory reads = Read DMA TLP Count - bmd_read_scoreboard
// Check that received read data = Read DMA Expected Data Pattern - bmd_read_scoreboard
//     > will also verify against read dma error CSR
// Check that amount of read data = Read DMA TLP Size * Read DMA TLP Count - bmd_read_scoreboard
// Check all read addresses against base address (CSR) + size increments - bmd_read_scoreboard
// Check returned completion content against set byte enables - bmd_read_scoreboard
// Check that reads done is asserted if reads == count
// Check that read dma error is not set (or is set if data was bad)

`uvm_analysis_imp_decl(_rd_tx)
`uvm_analysis_imp_decl(_rd_rx)
class bmd_read_scoreboard_c extends uvm_scoreboard;
    `uvm_component_utils(bmd_read_scoreboard_c)

    apci_tlp rx_packets[$];
    apci_tlp tx_packets[$];
    apci_tlp all_packets[$];

    uvm_analysis_imp_rd_tx #(apci_packet, bmd_read_scoreboard_c) txp;
    uvm_analysis_imp_rd_rx #(apci_packet, bmd_read_scoreboard_c) rxp;

    virtual bmd_read_csr_if rd_csr_vif;

    bit cfg_10b_tag_req_en;
    bit cfg_ext_tag_en;

    bit main_phase_started;

    bit inject_bad_data;

    bit send_ur_to_dut;
    bit [13:0] ur_tag;
    bit [2:0] rd_tc;

    // Constructor
    function new(string name = "bmd_read_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        txp = new("txp", this);
        rxp = new("rxp", this);
    endfunction

    function void clear();
        rx_packets.delete();
        tx_packets.delete();
        all_packets.delete();

        cfg_10b_tag_req_en  = '0;
        cfg_ext_tag_en      = '0;

        inject_bad_data     = '0;

        send_ur_to_dut      = '0;
        ur_tag              = '0;

        rd_tc               = '0;
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        phase.raise_objection(this);
        super.build_phase(phase);
        main_phase_started = 0;

        if (!uvm_config_db#(virtual bmd_read_csr_if)::get(this, "", "rd_csr_vif", rd_csr_vif))
            `uvm_fatal(get_type_name(), "Virtual interface [rd_csr_vif] not set for this monitor")
        phase.drop_objection(this);
    endfunction

    // Write method - called when transaction received
    virtual function void write_rd_tx(apci_packet trans);
        // Add checking logic here
        if (main_phase_started) begin
            apci_tlp tlp;
            if($cast(tlp, trans)) begin
                tx_packets.push_back(tlp);
                all_packets.push_back(tlp);
            end else begin
                `uvm_error(get_type_name(), "Failed to cast from tx packet to tx tlp")
            end
        end
    endfunction

    // Write method - called when transaction received
    virtual function void write_rd_rx(apci_packet trans);
        // Add checking logic here
        if (main_phase_started) begin
            apci_tlp tlp;
            if($cast(tlp, trans)) begin
                rx_packets.push_back(tlp);
                all_packets.push_back(tlp);
            end else begin
                `uvm_error(get_type_name(), "Failed to cast from rx packet to rx tlp")
            end
        end
    endfunction

    task main_phase(uvm_phase phase);
        main_phase_started = 1;
    endtask

    virtual function void write_logs();
        int f = $fopen("./rd_csr_dump.txt");
        $fwrite(f, "Read Size (DW): %0d\n", rd_csr_vif.monitor_cb.read_size);
        $fwrite(f, "Read 64b En:    0x%x\n", rd_csr_vif.monitor_cb.read_64b_en);
        $fwrite(f, "Read Address:   0x%x\n", rd_csr_vif.monitor_cb.read_address);
        $fwrite(f, "Read UAddress:  0x%x\n", rd_csr_vif.monitor_cb.read_up_address);
        $fwrite(f, "Read Count:     %0d\n", rd_csr_vif.monitor_cb.read_count);
        $fwrite(f, "Read Pattern:   0x%x\n", rd_csr_vif.monitor_cb.read_pattern);
        $fwrite(f, "Read Lower BE:  0x%x\n", rd_csr_vif.monitor_cb.read_l_be);
        $fwrite(f, "Read Upper BE:  0x%x\n", rd_csr_vif.monitor_cb.read_u_be);
        $fwrite(f, "Received CPLs:  %0d\n", rd_csr_vif.monitor_cb.received_cpls);
        $fwrite(f, "Read DMA Error: 0x%x\n", rd_csr_vif.monitor_cb.read_dma_err);
        $fwrite(f, "Read Done:      0x%x\n", rd_csr_vif.monitor_cb.read_done);
        $fwrite(f, "Read Start:     0x%x\n\n", rd_csr_vif.monitor_cb.read_start);

        $fwrite(f, "Read Int Dis:   0x%x\n", rd_csr_vif.monitor_cb.rd_int_disable);
        $fwrite(f, "Read Int Sel:   0x%x\n", rd_csr_vif.monitor_cb.rd_int_sel);
        $fwrite(f, "Read INTx Vec:  0x%x\n", rd_csr_vif.monitor_cb.intx_rd_vec);
        $fclose(f);
    endfunction

    int prev_dma_err;
    int number_of_memory_reads;
    int number_of_received_completions;
    int number_of_dw_received;

    bit [1023:0] tags_used;
    bit [9:0]    curr_tag_min;
    bit [9:0]    curr_tag_max;

    // Report phase
    virtual function void call_report();
        prev_dma_err = 0;
        number_of_memory_reads          = 0;
        number_of_received_completions  = 0;
        number_of_dw_received           = 0;

        if (rd_csr_vif.monitor_cb.read_start) begin
            foreach (rx_packets[i]) begin // TX from device perspective
                if (rx_packets[i].kind == APCI_TLP_mrd) begin
                    // Check all read addresses against base address (CSR) + size increments
                    if (rd_csr_vif.monitor_cb.read_64b_en) begin
                        if (({rx_packets[i].u.fm_mem64.addr.dw_addr, 2'b00} -
                            {rd_csr_vif.monitor_cb.read_up_address, rd_csr_vif.monitor_cb.read_address}) !=
                                (number_of_memory_reads * (rd_csr_vif.monitor_cb.read_size << 2)))
                            `uvm_error(get_type_name(), $sformatf("Address [0x%x] not equal to address [0x%x]",
                                {rx_packets[i].u.fm_mem64.addr.dw_addr, 2'b00} -
                                    {rd_csr_vif.monitor_cb.read_up_address, rd_csr_vif.monitor_cb.read_address},
                                (number_of_memory_reads * (rd_csr_vif.monitor_cb.read_size << 2))))
                    end else begin
                        if (({rx_packets[i].u.fm_mem32.addr.dw_addr, 2'b00} - rd_csr_vif.monitor_cb.read_address) !=
                                (number_of_memory_reads * (rd_csr_vif.monitor_cb.read_size << 2)))
                            `uvm_error(get_type_name(), $sformatf("Address [0x%x] not equal to address [0x%x]",
                                {rx_packets[i].u.fm_mem32.addr.dw_addr, 2'b00} - rd_csr_vif.monitor_cb.read_address,
                                (number_of_memory_reads * (rd_csr_vif.monitor_cb.read_size << 2))))
                    end
                    number_of_memory_reads++;
                    // Check traffic class
                    if (rx_packets[i].u.fm_com.tc != rd_tc)
                        `uvm_error(get_type_name(), $sformatf("TC Actual (%x) != Expected (%x)",
                            rx_packets[i].u.fm_com.tc, rd_tc))
                end
            end
            foreach (tx_packets[i]) begin // RX from device perspective
                if (tx_packets[i].kind == APCI_TLP_cpld) begin
                    if (tx_packets[i].u.fm_cpl.byte_cnt <= (tx_packets[i].u.fm_cpl.length << 2)) begin
                        number_of_received_completions++;
                    end

                    number_of_dw_received += tx_packets[i].u.fm_cpl.length;

                    for (int k = 0; k < tx_packets[i].u.fm_cpl.length; k++) begin
                        if (k == 0) begin // first byte enables
                            // Check that received read data = Read DMA Expected Data Pattern - Byte 0
                            if (tx_packets[i].payload[k][7:0] != rd_csr_vif.monitor_cb.read_pattern[7:0]
                                    && !inject_bad_data
                                    && rd_csr_vif.monitor_cb.read_l_be[0]) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "Received data [0x%x] =/= Expected Pattern CSR [0x%x]",
                                    tx_packets[i].payload[k], rd_csr_vif.monitor_cb.read_pattern))
                                prev_dma_err = 1;
                                break;
                            end
                            // Check that received read data = Read DMA Expected Data Pattern - Byte 1
                            if (tx_packets[i].payload[k][15:8] != rd_csr_vif.monitor_cb.read_pattern[15:8]
                                    && !inject_bad_data
                                    && rd_csr_vif.monitor_cb.read_l_be[1]) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "Received data [0x%x] =/= Expected Pattern CSR [0x%x]",
                                    tx_packets[i].payload[k], rd_csr_vif.monitor_cb.read_pattern))
                                prev_dma_err = 1;
                                break;
                            end
                            // Check that received read data = Read DMA Expected Data Pattern - Byte 2
                            if (tx_packets[i].payload[k][23:16] != rd_csr_vif.monitor_cb.read_pattern[23:16]
                                    && !inject_bad_data
                                    && rd_csr_vif.monitor_cb.read_l_be[2]) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "Received data [0x%x] =/= Expected Pattern CSR [0x%x]",
                                    tx_packets[i].payload[k], rd_csr_vif.monitor_cb.read_pattern))
                                prev_dma_err = 1;
                                break;
                            end
                            // Check that received read data = Read DMA Expected Data Pattern - Byte 3
                            if (tx_packets[i].payload[k][31:24] != rd_csr_vif.monitor_cb.read_pattern[31:24]
                                    && !inject_bad_data
                                    && rd_csr_vif.monitor_cb.read_l_be[3]) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "Received data [0x%x] =/= Expected Pattern CSR [0x%x]",
                                    tx_packets[i].payload[k], rd_csr_vif.monitor_cb.read_pattern))
                                prev_dma_err = 1;
                                break;
                            end
                        end else if (k == tx_packets[i].u.fm_cpl.length - 1) begin
                            // Check that received read data = Read DMA Expected Data Pattern - Byte 0
                            if (tx_packets[i].payload[k][7:0] != rd_csr_vif.monitor_cb.read_pattern[7:0]
                                    && !inject_bad_data
                                    && rd_csr_vif.monitor_cb.read_u_be[0]) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "Received data [0x%x] =/= Expected Pattern CSR [0x%x]",
                                    tx_packets[i].payload[k], rd_csr_vif.monitor_cb.read_pattern))
                                prev_dma_err = 1;
                                break;
                            end
                            // Check that received read data = Read DMA Expected Data Pattern - Byte 1
                            if (tx_packets[i].payload[k][15:8] != rd_csr_vif.monitor_cb.read_pattern[15:8]
                                    && !inject_bad_data
                                    && rd_csr_vif.monitor_cb.read_u_be[1]) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "Received data [0x%x] =/= Expected Pattern CSR [0x%x]",
                                    tx_packets[i].payload[k], rd_csr_vif.monitor_cb.read_pattern))
                                prev_dma_err = 1;
                                break;
                            end
                            // Check that received read data = Read DMA Expected Data Pattern - Byte 2
                            if (tx_packets[i].payload[k][23:16] != rd_csr_vif.monitor_cb.read_pattern[23:16]
                                    && !inject_bad_data
                                    && rd_csr_vif.monitor_cb.read_u_be[2]) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "Received data [0x%x] =/= Expected Pattern CSR [0x%x]",
                                    tx_packets[i].payload[k], rd_csr_vif.monitor_cb.read_pattern))
                                prev_dma_err = 1;
                                break;
                            end
                            // Check that received read data = Read DMA Expected Data Pattern - Byte 3
                            if (tx_packets[i].payload[k][31:24] != rd_csr_vif.monitor_cb.read_pattern[31:24]
                                    && !inject_bad_data
                                    && rd_csr_vif.monitor_cb.read_u_be[3]) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "Received data [0x%x] =/= Expected Pattern CSR [0x%x]",
                                    tx_packets[i].payload[k], rd_csr_vif.monitor_cb.read_pattern))
                                prev_dma_err = 1;
                                break;
                            end
                        end else begin
                            if (tx_packets[i].payload[k] != rd_csr_vif.monitor_cb.read_pattern &&
                                    !inject_bad_data) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "Received data [0x%x] =/= Expected Pattern CSR [0x%x]",
                                    tx_packets[i].payload[k], rd_csr_vif.monitor_cb.read_pattern))
                                prev_dma_err = 1;
                                break;
                            end
                        end
                    end
                end
            end

            if (inject_bad_data) begin
                if (!rd_csr_vif.monitor_cb.read_dma_err)
                    `uvm_error(get_type_name(), "Bad data injected, but DMA Error CSR is not set")
            end else if (!inject_bad_data) begin
                //     > will also verify against read dma error CSR
                if (!rd_csr_vif.monitor_cb.read_dma_err && prev_dma_err)
                    `uvm_error(get_type_name(), "DMA Error detected, but DMA Error CSR is not set")

                //     > will also verify against read dma error CSR
                if (rd_csr_vif.monitor_cb.read_dma_err && !prev_dma_err)
                    `uvm_error(get_type_name(), "DMA Error CSR set, but error not detected")
            end

            // Check tags are not used before they are released
            // Check tags are in correct range for the 8b/10b enables
            tags_used = '0;
            curr_tag_min = cfg_10b_tag_req_en ? 10'd256 : 10'd0;
            curr_tag_max = cfg_10b_tag_req_en ? 10'd1023 : cfg_ext_tag_en ? 10'd255 : 10'd31;
            foreach (all_packets[i]) begin
                if (all_packets[i].kind == APCI_TLP_mrd && all_packets[i] inside {rx_packets}) begin
                    if (tags_used[all_packets[i].u.fm_mem64.tag]) begin
                        `uvm_error(get_type_name(), $sformatf(
                            "Tag 0x%x was used before it was released",
                            all_packets[i].u.fm_mem64.tag))
                    end
                    tags_used[all_packets[i].u.fm_mem64.tag] = 1'b1;
                    if (all_packets[i].u.fm_mem64.tag < curr_tag_min || all_packets[i].u.fm_mem64.tag > curr_tag_max)
                        `uvm_error(get_type_name(), $sformatf(
                            "Tag 0x%x out of expected range of 0x%x-0x%x",
                            all_packets[i].u.fm_mem64.tag, curr_tag_min, curr_tag_max))
                end else if (all_packets[i].kind == APCI_TLP_cpld && all_packets[i] inside {tx_packets}) begin
                    tags_used[all_packets[i].u.fm_cpl.tag] = 1'b0;
                end
            end

            `uvm_info(get_type_name(), $sformatf(
                "Number of reads: %0d, Number completions: %0d, Number of DW: %0d",
                number_of_memory_reads, number_of_received_completions + (send_ur_to_dut ? 1 : 0),
                number_of_dw_received), UVM_LOW)

            // Check that number of memory reads = number of received completions
            if (number_of_memory_reads != number_of_received_completions + (send_ur_to_dut ? 1 : 0))
                `uvm_error(get_type_name(), $sformatf(
                    "Number of Memory Reads [%0d] =/= to Received Completions [%0d]",
                    number_of_memory_reads, number_of_received_completions))

            //      > also verify against received cpls CSR
            if (number_of_received_completions + (send_ur_to_dut ? 1 : 0) != rd_csr_vif.monitor_cb.received_cpls)
                `uvm_error(get_type_name(), $sformatf(
                    "Number of Received Completions [%0d] =/= to Received Completions CSR [%0d]",
                    number_of_received_completions, rd_csr_vif.monitor_cb.received_cpls))

            // Check that number of memory reads = Read DMA TLP Count
            if (number_of_memory_reads != rd_csr_vif.monitor_cb.read_count)
                `uvm_error(get_type_name(), $sformatf(
                    "Number of Memory Reads [%0d] =/= to Read Count CSR [%0d]",
                    number_of_memory_reads, rd_csr_vif.monitor_cb.read_count))

            // Check that amount of read data = Read DMA TLP Size * Read DMA TLP Count
            if (number_of_dw_received != (rd_csr_vif.monitor_cb.read_size *
                    (rd_csr_vif.monitor_cb.read_count - (send_ur_to_dut ? 1 : 0))))
                `uvm_error(get_type_name(), $sformatf(
                    "Amount of Read Data [%0d] =/= Read Size CSR [%0d] * Read Count CSR [%0d]",
                    number_of_dw_received, rd_csr_vif.monitor_cb.read_size, rd_csr_vif.monitor_cb.read_count))

            // Check that reads done is asserted if reads == count
            if (number_of_received_completions + (send_ur_to_dut ? 1 : 0) == rd_csr_vif.monitor_cb.read_count &&
                    !rd_csr_vif.monitor_cb.read_done)
                `uvm_error(get_type_name(), $sformatf(
                    "Done not set when Amount of Received Completions [%0d] == Read Count CSR [%0d]",
                    number_of_received_completions, rd_csr_vif.monitor_cb.read_count))

            // Verify that if UR was sent that the CSR reflects updated count and tag information
            if (send_ur_to_dut) begin
                if (rd_csr_vif.monitor_cb.cpl_ur_found_i == 0)
                    `uvm_error(get_type_name(), "Sent a UR to the DUT but it was not logged in CSRs")
                if (rd_csr_vif.monitor_cb.cpl_ur_tag_i[9:0] != ur_tag[9:0]) `uvm_error(get_type_name(),
                    $sformatf("Logged UR tag [0x%x] did not match expected tag [0x%x]",
                        rd_csr_vif.monitor_cb.cpl_ur_tag_i[9:0], ur_tag[9:0]))
            end else begin
                if (rd_csr_vif.monitor_cb.cpl_ur_found_i != 0)
                    `uvm_error(get_type_name(), "Unexpected UR logged in CSR")
            end
        end
    endfunction

endclass
