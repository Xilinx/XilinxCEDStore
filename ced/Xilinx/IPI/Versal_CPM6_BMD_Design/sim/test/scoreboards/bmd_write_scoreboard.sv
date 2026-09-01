////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
////////////////////////////////////////////////////////////////////////

// Check that number of memory writes = Write DMA TLP Count
//       > will also verify against tb programmed value
// Check that write done is asserted if writes == count
// Check that received write data = Write DMA TLP Data Pattern
//       > will also verify against tb programmed value
// Check that amount of write data = Write DMA TLP Size * Write DMA TLP Count
//       > will also verify against tb programmed value (both size and count)
// Check all write addresses against base address (CSR) + size increments
//       > will also verify against tb programmed value
// Check write content against set byte enables

`uvm_analysis_imp_decl(_wr_rx)
class bmd_write_scoreboard_c extends uvm_scoreboard;
    `uvm_component_utils(bmd_write_scoreboard_c)

    apci_tlp rx_packets[$];

    uvm_analysis_imp_wr_rx #(apci_packet, bmd_write_scoreboard_c) rxp;

    virtual bmd_write_csr_if wr_csr_vif;

    bit main_phase_started;
    bit [2:0] wr_tc;
    bit [63:0] msi_addr;
    bit [63:0] msix_addr;

    // Constructor
    function new(string name = "bmd_write_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        rxp = new("rxp", this);
    endfunction

    function void clear();
        rx_packets.delete();

        wr_tc       = '0;

        msi_addr    = '0;
        msix_addr   = '0;
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        phase.raise_objection(this);
        super.build_phase(phase);
        main_phase_started = 0;
        if (!uvm_config_db#(virtual bmd_write_csr_if)::get(this, "", "wr_csr_vif", wr_csr_vif))
            `uvm_fatal(get_type_name(), "Virtual interface [wr_csr_vif] not set for this monitor")
        phase.drop_objection(this);
    endfunction

    task main_phase(uvm_phase phase);
        main_phase_started = 1;
    endtask

    // Write method - called when transaction received
    virtual function void write_wr_rx(apci_packet trans);
        // Add checking logic here
        if (main_phase_started) begin
            apci_tlp tlp;
            if($cast(tlp, trans)) begin
                rx_packets.push_back(tlp);
            end else begin
                `uvm_error(get_type_name(), "Failed to cast from rx packet to rx tlp")
            end
        end
    endfunction

    virtual function void write_logs();
        int f = $fopen("./wr_csr_dump.txt");
        $fwrite(f, "Write Size (DW): %0d\n", wr_csr_vif.monitor_cb.write_size);
        $fwrite(f, "Write 64b En:    0x%x\n", wr_csr_vif.monitor_cb.write_64b_en);
        $fwrite(f, "Write Address:   0x%x\n", wr_csr_vif.monitor_cb.write_address);
        $fwrite(f, "Write UAddress:  0x%x\n", wr_csr_vif.monitor_cb.write_up_address);
        $fwrite(f, "Write Count:     %0d\n", wr_csr_vif.monitor_cb.write_count);
        $fwrite(f, "Write Pattern:   0x%x\n", wr_csr_vif.monitor_cb.write_pattern);
        $fwrite(f, "Write Lower BE:  0x%x\n", wr_csr_vif.monitor_cb.write_l_be);
        $fwrite(f, "Write Upper BE:  0x%x\n", wr_csr_vif.monitor_cb.write_u_be);
        $fwrite(f, "Write Done:      0x%x\n", wr_csr_vif.monitor_cb.write_done);
        $fwrite(f, "Write Start:     0x%x\n\n", wr_csr_vif.monitor_cb.write_start);

        $fwrite(f, "Write Int Dis:   0x%x\n", wr_csr_vif.monitor_cb.wr_int_disable);
        $fwrite(f, "Write Int Sel:   0x%x\n", wr_csr_vif.monitor_cb.wr_int_sel);
        $fwrite(f, "Write INTx Vec:  0x%x\n", wr_csr_vif.monitor_cb.intx_wr_vec);
        $fclose(f);
    endfunction

    int number_of_memory_writes;
    int number_of_dw_sent;

    function bit [63:0] get_addr64(apci_tlp pkt);
        return pkt.is_flit_mode ? {pkt.u.fm_mem64.addr.dw_addr, 2'b00}
                                : {pkt.u.mem64.addr.dw_addr, 2'b00};
    endfunction

    function bit [31:0] get_addr32(apci_tlp pkt);
        return pkt.is_flit_mode ? {pkt.u.fm_mem32.addr.dw_addr, 2'b00}
                                : {pkt.u.mem32.addr.dw_addr, 2'b00};
    endfunction

    function bit [9:0] get_length(apci_tlp pkt);
        return pkt.is_flit_mode ? pkt.u.fm_mem64.length : pkt.u.mem64.length;
    endfunction

    function bit [2:0] get_tc(apci_tlp pkt);
        return pkt.is_flit_mode ? pkt.u.fm_com.tc : pkt.u.com.tc;
    endfunction

    // Report phase
    virtual function void call_report();
        number_of_memory_writes = 0;
        number_of_dw_sent = 0;

        if (wr_csr_vif.monitor_cb.write_start) begin
            foreach (rx_packets[i]) begin // TX from device perspective
                if (rx_packets[i].kind == APCI_TLP_mwr) begin
                    if (get_addr64(rx_packets[i]) != msi_addr &&
                        get_addr64(rx_packets[i]) != msix_addr) begin
                        // Check all write addresses against base address (CSR) + size increments
                        if (wr_csr_vif.monitor_cb.write_64b_en) begin
                            if ((get_addr64(rx_packets[i]) -
                                    {wr_csr_vif.monitor_cb.write_up_address,
                                    wr_csr_vif.monitor_cb.write_address}) !=
                                        (number_of_memory_writes * (wr_csr_vif.monitor_cb.write_size << 2)))
                                `uvm_error(get_type_name(), $sformatf(
                                    "Address offset [0x%x] not equal to address offset [0x%x]",
                                    get_addr64(rx_packets[i]) -
                                        {wr_csr_vif.monitor_cb.write_up_address,
                                        wr_csr_vif.monitor_cb.write_address},
                                    (number_of_memory_writes * (wr_csr_vif.monitor_cb.write_size << 2))))
                        end else begin
                            if ((get_addr32(rx_packets[i]) -
                                    wr_csr_vif.monitor_cb.write_address) !=
                                        (number_of_memory_writes * (wr_csr_vif.monitor_cb.write_size << 2)))
                                `uvm_error(get_type_name(), $sformatf(
                                    "Address offset [0x%x] not equal to address offset [0x%x]",
                                    get_addr32(rx_packets[i]) -
                                        wr_csr_vif.monitor_cb.write_address,
                                    (number_of_memory_writes * (wr_csr_vif.monitor_cb.write_size << 2))))
                        end
                        number_of_memory_writes++;
                        number_of_dw_sent += get_length(rx_packets[i]);

                        for (int k = 0; k < get_length(rx_packets[i]); k++) begin
                            // Check that received write data = Write DMA TLP Data Pattern
                            if (rx_packets[i].payload[k] != wr_csr_vif.monitor_cb.write_pattern) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "Sent data [0x%x] =/= Expected Pattern CSR [0x%x]",
                                    rx_packets[i].payload[k], wr_csr_vif.monitor_cb.write_pattern))
                            end
                        end

                        // Check TC
                        if (get_tc(rx_packets[i]) != wr_tc) `uvm_error(get_type_name(), $sformatf(
                                "TC Actual (%x) != Expected (%x)", get_tc(rx_packets[i]), wr_tc))
                    end
                end
            end

            `uvm_info(get_type_name(), $sformatf(
                    "Number of writes: %0d, Number of DW: %0d", number_of_memory_writes, number_of_dw_sent), UVM_LOW)

            // Skip count/size comparisons when write engine is in VDM mode —
            // VDM traffic is validated by bmd_vdm_scoreboard instead.
            // Packet-level checks above (address, data, TC) still fire for any
            // unexpected MWr packets that appear during VDM tests.
            if (wr_csr_vif.monitor_cb.write_type != 5'b10010) begin
                // Check that number of memory writes = Write DMA TLP Count
                if (number_of_memory_writes != wr_csr_vif.monitor_cb.write_count)
                    `uvm_error(get_type_name(), $sformatf(
                        "Number of Memory Writes [%0d] =/= to Write Count CSR [%0d]",
                        number_of_memory_writes, wr_csr_vif.monitor_cb.write_count))
                // Check that write done is asserted if writes == count
                if ((number_of_memory_writes == wr_csr_vif.monitor_cb.write_count) &&
                        !wr_csr_vif.monitor_cb.write_done)
                    `uvm_error(get_type_name(), $sformatf(
                        "Done not set when Amount of Sent Writes [%0d] == Write Count CSR [%0d]",
                        number_of_memory_writes, wr_csr_vif.monitor_cb.write_count))
                // Check that amount of write data = Write DMA TLP Size * Write DMA TLP Count
                if (number_of_dw_sent != (wr_csr_vif.monitor_cb.write_count * wr_csr_vif.monitor_cb.write_size))
                    `uvm_error(get_type_name(), $sformatf(
                        "Amount of Write Data [%0d] =/= Write Size CSR [%0d] * Write Count CSR [%0d]",
                        number_of_dw_sent, wr_csr_vif.monitor_cb.write_size, wr_csr_vif.monitor_cb.write_count))
            end
        end
    endfunction
endclass
