// Verify VDM (Vendor Defined Message) TLP count and data integrity
// when the write engine is configured for VDM mode (write_type == 5'b10010).

`uvm_analysis_imp_decl(_vdm_rx)
class bmd_vdm_scoreboard_c extends uvm_scoreboard;
    `uvm_component_utils(bmd_vdm_scoreboard_c)

    apci_tlp rx_packets[$];

    uvm_analysis_imp_vdm_rx #(apci_packet, bmd_vdm_scoreboard_c) rxp;

    virtual bmd_write_csr_if wr_csr_vif;

    bit main_phase_started;

    // Constructor
    function new(string name = "bmd_vdm_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        rxp = new("rxp", this);
    endfunction

    function void clear();
        rx_packets.delete();
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
    virtual function void write_vdm_rx(apci_packet trans);
        if (main_phase_started) begin
            apci_tlp tlp;
            if($cast(tlp, trans)) begin
                rx_packets.push_back(tlp);
            end else begin
                `uvm_error(get_type_name(), "Failed to cast from rx packet to rx tlp")
            end
        end
    endfunction

    int number_of_vdms;
    int number_of_dw_sent;

    // Report phase
    virtual function void call_report();
        number_of_vdms = 0;
        number_of_dw_sent = 0;

        // Only activate when write engine is in VDM mode and was started
        if (wr_csr_vif.monitor_cb.write_type == 5'b10010 &&
                wr_csr_vif.monitor_cb.write_start) begin

            // Count VDM TLPs (msg = no data, msgd = with data)
            foreach (rx_packets[i]) begin
                if (rx_packets[i].kind inside {APCI_TLP_msg, APCI_TLP_msgd}) begin
                    if (rx_packets[i].u.msg.msg_code inside {8'h7E, 8'h7F}) begin
                        number_of_vdms++;

                        // For data-bearing VDMs, accumulate payload length and check pattern
                        if (rx_packets[i].kind == APCI_TLP_msgd) begin
                            number_of_dw_sent += rx_packets[i].u.fm_com.length;

                            for (int k = 0; k < rx_packets[i].u.fm_com.length; k++) begin
                                if (rx_packets[i].payload[k] != wr_csr_vif.monitor_cb.write_pattern) begin
                                    `uvm_error(get_type_name(), $sformatf(
                                        "VDM payload[%0d] data [0x%x] =/= Expected Pattern CSR [0x%x]",
                                        k, rx_packets[i].payload[k], wr_csr_vif.monitor_cb.write_pattern))
                                end
                            end
                        end
                    end
                end
            end

            `uvm_info(get_type_name(), $sformatf(
                    "Number of VDMs: %0d, Number of DW: %0d", number_of_vdms, number_of_dw_sent), UVM_LOW)

            // Check that number of VDMs = Write DMA TLP Count
            if (number_of_vdms != wr_csr_vif.monitor_cb.write_count)
                `uvm_error(get_type_name(), $sformatf(
                    "Number of VDMs [%0d] =/= to Write Count CSR [%0d]",
                    number_of_vdms, wr_csr_vif.monitor_cb.write_count))

            // Check that write done is asserted if VDMs == count
            if ((number_of_vdms == wr_csr_vif.monitor_cb.write_count) &&
                    !wr_csr_vif.monitor_cb.write_done)
                `uvm_error(get_type_name(), $sformatf(
                    "Done not set when Amount of Sent VDMs [%0d] == Write Count CSR [%0d]",
                    number_of_vdms, wr_csr_vif.monitor_cb.write_count))

            // For data-bearing VDMs: check total DW = write_size * write_count
            if (wr_csr_vif.monitor_cb.write_fmt) begin
                if (number_of_dw_sent != (wr_csr_vif.monitor_cb.write_count * wr_csr_vif.monitor_cb.write_size))
                    `uvm_error(get_type_name(), $sformatf(
                        "Amount of VDM Data [%0d DW] =/= Write Size CSR [%0d] * Write Count CSR [%0d]",
                        number_of_dw_sent, wr_csr_vif.monitor_cb.write_size, wr_csr_vif.monitor_cb.write_count))
            end
        end
    endfunction

endclass
