// Verify MSI-X interrupts are being received shortly after read/write done - Backlog
// Verify MSI-X interrupts disables (config and CSR) are able to prevent interrupts - Backlog
// Verify MSI interrupts are being received shortly after read/write done - Backlog
// Verify MSI interrupts disables (config and CSR) are able to prevent interrupts - Backlog
// Verify INTx interrupts are being received shortly after read/write done
// Verify INTx interrupts disables (config and CSR) are able to prevent interrupts

`uvm_analysis_imp_decl(_int_rx)
class bmd_interrupt_scoreboard_c extends uvm_scoreboard;
    `uvm_component_utils(bmd_interrupt_scoreboard_c)

    apci_tlp intx_interrupts[$];
    apci_tlp write_packets[$];

    uvm_analysis_imp_int_rx #(apci_packet, bmd_interrupt_scoreboard_c) rxp;

    virtual bmd_write_csr_if wr_csr_vif;
    virtual bmd_read_csr_if  rd_csr_vif;

    bit             cfg_int_disable;
    bit             cfg_msix_en;
    bit             cfg_msi_en;

    bit [63:0]      msi_addr;
    bit [63:0]      msix_addr;

    bit [31:0]      msi_data;
    bit [31:0]      msix_data_rd;
    bit [31:0]      msix_data_wr;

    bit             msi_mask_vector;

    bit             main_phase_started;

    // Constructor
    function new(string name = "bmd_interrupt_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        rxp = new("rxp", this);
    endfunction

    function void clear();
        intx_interrupts.delete();
        write_packets.delete();

        cfg_int_disable     = 0;
        cfg_msix_en         = 0;
        cfg_msi_en          = 0;

        msi_addr            = '0;
        msix_addr           = '0;

        msi_data            = '0;
        msix_data_rd        = '0;
        msix_data_wr        = '0;

        msi_mask_vector     = '0;
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        phase.raise_objection(this);
        super.build_phase(phase);
        main_phase_started = 0;
        if (!uvm_config_db#(virtual bmd_write_csr_if)::get(this, "", "wr_csr_vif", wr_csr_vif))
            `uvm_fatal(get_type_name(), "Virtual interface [wr_csr_vif] not set for this monitor")
        if (!uvm_config_db#(virtual bmd_read_csr_if)::get(this, "", "rd_csr_vif", rd_csr_vif))
            `uvm_fatal(get_type_name(), "Virtual interface [rd_csr_vif] not set for this monitor")
        phase.drop_objection(this);
    endfunction

    task main_phase(uvm_phase phase);
        main_phase_started = 1;
    endtask

    // Write method - called when transaction received
    virtual function void write_int_rx(apci_packet trans);
        if (main_phase_started) begin
            apci_tlp tlp;
            if($cast(tlp, trans)) begin
                if (tlp.kind == APCI_TLP_msg) begin
                    if(tlp.u.msg.msg_code inside {APCI_MSG_assert_inta, APCI_MSG_assert_intb,
                                                    APCI_MSG_assert_intc, APCI_MSG_assert_intd}) begin
                        intx_interrupts.push_back(tlp);
                    end
                end

                if (tlp.kind == APCI_TLP_mwr) begin
                    write_packets.push_back(tlp);
                end
            end else begin
                `uvm_error(get_type_name(), "Failed to cast from rx packet to rx tlp")
            end
        end
    endfunction

    virtual function void call_report();
        int wr_intx_found = 0;
        int rd_intx_found = 0;

        int wr_msi_found  = 0;
        int rd_msi_found  = 0;

        int wr_msix_found = 0;
        int rd_msix_found = 0;

        ////////////////////////////////////////////////////////////////////////////////////
        //                                      INTx
        ////////////////////////////////////////////////////////////////////////////////////
        // Verify INTx interrupts are being received shortly after read/write done
        // Verify INTx interrupts disables (config and CSR) are able to prevent interrupts
        foreach(intx_interrupts[i]) begin
            // Look for read intx
            unique case(rd_csr_vif.monitor_cb.intx_rd_vec)
                2'b00 : if (intx_interrupts[i].u.msg.msg_code == APCI_MSG_assert_inta) rd_intx_found = 1;
                2'b01 : if (intx_interrupts[i].u.msg.msg_code == APCI_MSG_assert_intb) rd_intx_found = 1;
                2'b10 : if (intx_interrupts[i].u.msg.msg_code == APCI_MSG_assert_intc) rd_intx_found = 1;
                2'b11 : if (intx_interrupts[i].u.msg.msg_code == APCI_MSG_assert_intd) rd_intx_found = 1;
            endcase

            // Look for write intx
            unique case(wr_csr_vif.monitor_cb.intx_wr_vec)
                2'b00 : if (intx_interrupts[i].u.msg.msg_code == APCI_MSG_assert_inta) wr_intx_found = 1;
                2'b01 : if (intx_interrupts[i].u.msg.msg_code == APCI_MSG_assert_intb) wr_intx_found = 1;
                2'b10 : if (intx_interrupts[i].u.msg.msg_code == APCI_MSG_assert_intc) wr_intx_found = 1;
                2'b11 : if (intx_interrupts[i].u.msg.msg_code == APCI_MSG_assert_intd) wr_intx_found = 1;
            endcase
        end

        // All INTx disabled
        if (cfg_int_disable && (rd_intx_found || wr_intx_found)) begin
            `uvm_error(get_type_name(), "INTx interrupt found when INT Disable is set in config")
        end

        // No Reads
        if (rd_csr_vif.monitor_cb.rd_int_disable && rd_intx_found) begin
            `uvm_error(get_type_name(), "Read INTx interrupt found when Read INT Disable is set in CSR")
        end

        // No Writes
        if (wr_csr_vif.monitor_cb.wr_int_disable && wr_intx_found) begin
            `uvm_error(get_type_name(), "Write INTx interrupt found when Write INT Disable is set in CSR")
        end

        if(!cfg_int_disable &&
            rd_csr_vif.monitor_cb.read_start &&
            !rd_csr_vif.monitor_cb.rd_int_disable &&
            rd_csr_vif.monitor_cb.rd_int_sel == 2'b10) begin
                if (rd_intx_found == 0) `uvm_error(get_type_name(), "Expected Read INTx interrupt not asserted")
            end
        if(!cfg_int_disable &&
            wr_csr_vif.monitor_cb.write_start &&
            !wr_csr_vif.monitor_cb.wr_int_disable &&
            wr_csr_vif.monitor_cb.wr_int_sel == 2'b10) begin
                if (wr_intx_found == 0) `uvm_error(get_type_name(), "Expected Write INTx interrupt not asserted")
        end

        ////////////////////////////////////////////////////////////////////////////////////
        //                                      MSI-X
        ////////////////////////////////////////////////////////////////////////////////////
        // Verify MSI-X interrupts are being received after read/write done
        // Verify MSI-X interrupts disables (config and CSR) are able to prevent interrupts
        foreach(write_packets[i]) begin
            if (msix_addr[63:32] == '0) begin
                if (write_packets[i].u.fm_mem32.addr.dw_addr == msix_addr[31:2]) begin
                    if (write_packets[i].payload[0] == (msix_data_rd)) begin
                        rd_msix_found = 1;
                    end else if (write_packets[i].payload[0] == (msix_data_wr)) begin
                        wr_msix_found = 1;
                    end else begin
                        `uvm_error(get_type_name(), $sformatf(
                            "MSI-X Interrupt found with addr [0x%x] but unknown data [0x%x]",
                            write_packets[i].u.fm_mem32.addr.dw_addr, write_packets[i].payload[0]))
                    end
                end
            end else begin
                if (write_packets[i].u.fm_mem64.addr.dw_addr == msix_addr[63:2]) begin
                    if (write_packets[i].payload[0] == (msix_data_rd)) begin
                        rd_msix_found = 1;
                    end else if (write_packets[i].payload[0] == (msix_data_wr)) begin
                        wr_msix_found = 1;
                    end else begin
                        `uvm_error(get_type_name(), $sformatf(
                            "MSI-X Interrupt found with addr [0x%x] but unknown data [0x%x]",
                            write_packets[i].u.fm_mem64.addr.dw_addr, write_packets[i].payload[0]))
                    end
                end
            end
        end

        if (rd_msix_found && rd_csr_vif.monitor_cb.rd_int_sel != 2'b00) begin
            `uvm_error(get_type_name(), $sformatf("Read MSI-X Interrupt found, but MSI-X is not selected in CSR"))
        end
        if (wr_msix_found && wr_csr_vif.monitor_cb.wr_int_sel != 2'b00) begin
            `uvm_error(get_type_name(), $sformatf("Write MSI-X Interrupt found, but MSI-X is not selected in CSR"))
        end

        if (rd_msix_found && !cfg_msix_en) begin
            `uvm_error(get_type_name(), $sformatf("Read MSI-X Interrupt found, but MSI-X is not enabled in config"))
        end
        if (wr_msix_found && !cfg_msix_en) begin
            `uvm_error(get_type_name(), $sformatf("Write MSI-X Interrupt found, but MSI-X is not enabled in config"))
        end

        if (rd_msix_found && rd_csr_vif.monitor_cb.rd_int_disable) begin
            `uvm_error(get_type_name(), $sformatf("Read MSI-X Interrupt found, but interrupts are disabled in CSR"))
        end
        if (wr_msix_found && wr_csr_vif.monitor_cb.wr_int_disable) begin
            `uvm_error(get_type_name(), $sformatf("Write MSI-X Interrupt found, but interrupts are disabled in CSR"))
        end

        if (rd_csr_vif.monitor_cb.read_start && !rd_msix_found && rd_csr_vif.monitor_cb.rd_int_sel == 2'b00 &&
                !rd_csr_vif.monitor_cb.rd_int_disable && cfg_msix_en) begin
            `uvm_error(get_type_name(), $sformatf("Read MSI-X Interrupt not found, but MSI-X is setup"))
        end
        if (wr_csr_vif.monitor_cb.write_start && !wr_msix_found && wr_csr_vif.monitor_cb.wr_int_sel == 2'b00 &&
                !wr_csr_vif.monitor_cb.wr_int_disable && cfg_msix_en) begin
            `uvm_error(get_type_name(), $sformatf("Write MSI-X Interrupt not found, but MSI-X is setup"))
        end

        ////////////////////////////////////////////////////////////////////////////////////
        //                                       MSI
        ////////////////////////////////////////////////////////////////////////////////////
        // Verify MSI interrupts are being received after read/write done
        // Verify MSI interrupts disables (config and CSR) are able to prevent interrupts
        foreach(write_packets[i]) begin
            if (msi_addr[63:32] == '0) begin
                if (write_packets[i].u.fm_mem32.addr.dw_addr == msi_addr[31:2]) begin
                    if (write_packets[i].payload[0] == (msi_data |
                                                            {27'h0, rd_csr_vif.monitor_cb.msix_rd_vec[4:0]})) begin
                        rd_msi_found = 1;
                    end else if (write_packets[i].payload[0] == (msi_data |
                                                            {27'h0, wr_csr_vif.monitor_cb.msix_wr_vec[4:0]})) begin
                        wr_msi_found = 1;
                    end else begin
                        `uvm_error(get_type_name(), $sformatf(
                            "MSI Interrupt found with addr [0x%x] but unknown data [0x%x]",
                            write_packets[i].u.fm_mem32.addr.dw_addr, write_packets[i].payload[0]))
                    end
                end
            end else begin
                if (write_packets[i].u.fm_mem64.addr.dw_addr == msi_addr[63:2]) begin
                    if (write_packets[i].payload[0] == (msi_data |
                                                            {27'h0, rd_csr_vif.monitor_cb.msix_rd_vec[4:0]})) begin
                        rd_msi_found = 1;
                    end else if (write_packets[i].payload[0] == (msi_data |
                                                            {27'h0, wr_csr_vif.monitor_cb.msix_wr_vec[4:0]})) begin
                        wr_msi_found = 1;
                    end else begin
                        `uvm_error(get_type_name(), $sformatf(
                            "MSI Interrupt found with addr [0x%x] but unknown data [0x%x]",
                            write_packets[i].u.fm_mem64.addr.dw_addr, write_packets[i].payload[0]))
                    end
                end
            end
        end

        if (rd_msi_found && rd_csr_vif.monitor_cb.rd_int_sel != 2'b01) begin
            `uvm_error(get_type_name(), $sformatf("Read MSI Interrupt found, but MSI is not selected in CSR"))
        end
        if (wr_msi_found && wr_csr_vif.monitor_cb.wr_int_sel != 2'b01) begin
            `uvm_error(get_type_name(), $sformatf("Write MSI Interrupt found, but MSI is not selected in CSR"))
        end

        if (rd_msi_found && !cfg_msi_en) begin
            `uvm_error(get_type_name(), $sformatf("Read MSI Interrupt found, but MSI is not enabled in config"))
        end
        if (wr_msi_found && !cfg_msi_en) begin
            `uvm_error(get_type_name(), $sformatf("Write MSI Interrupt found, but MSI is not enabled in config"))
        end

        if (rd_msi_found && rd_csr_vif.monitor_cb.rd_int_disable) begin
            `uvm_error(get_type_name(), $sformatf("Read MSI Interrupt found, but interrupts are disabled in CSR"))
        end
        if (wr_msi_found && wr_csr_vif.monitor_cb.wr_int_disable) begin
            `uvm_error(get_type_name(), $sformatf("Write MSI Interrupt found, but interrupts are disabled in CSR"))
        end

        if ((wr_msi_found || rd_msi_found) && msi_mask_vector) begin
            `uvm_error(get_type_name(), $sformatf("MSI Interrupt found, but MSI is masked"))
        end

        if (rd_csr_vif.monitor_cb.read_start && !rd_msi_found && rd_csr_vif.monitor_cb.rd_int_sel == 2'b01 &&
                !rd_csr_vif.monitor_cb.rd_int_disable && cfg_msi_en && !msi_mask_vector) begin
            `uvm_error(get_type_name(), $sformatf("Read MSI Interrupt not found, but MSI is setup"))
        end
        if (wr_csr_vif.monitor_cb.write_start && !wr_msi_found && wr_csr_vif.monitor_cb.wr_int_sel == 2'b01 &&
                !wr_csr_vif.monitor_cb.wr_int_disable && cfg_msi_en && !msi_mask_vector) begin
            `uvm_error(get_type_name(), $sformatf("Write MSI Interrupt not found, but MSI is setup"))
        end
    endfunction
endclass
