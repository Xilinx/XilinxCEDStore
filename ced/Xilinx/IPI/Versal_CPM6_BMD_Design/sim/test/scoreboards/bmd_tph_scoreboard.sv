// Verify TPH prefix and data exists as programmed

`uvm_analysis_imp_decl(_tph_rx)
class bmd_tph_scoreboard_c extends uvm_scoreboard;
    `uvm_component_utils(bmd_tph_scoreboard_c)

    apci_tlp rx_packets[$];

    uvm_analysis_imp_tph_rx #(apci_packet, bmd_tph_scoreboard_c) rxp;

    virtual bmd_read_csr_if rd_csr_vif;
    virtual bmd_write_csr_if wr_csr_vif;

    bit tph_en;
    bit tph_ext_en;

    bit [63:0]        msi_addr;
    bit [63:0]        msix_addr;

    bit main_phase_started;

    // Constructor
    function new(string name = "bmd_tph_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        rxp = new("rxp", this);
    endfunction

    function void clear();
        rx_packets.delete();

        tph_en      = '0;
        tph_ext_en  = '0;

        msi_addr    = '0;
        msix_addr   = '0;
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        phase.raise_objection(this);
        super.build_phase(phase);
        main_phase_started = 0;
        if (!uvm_config_db#(virtual bmd_write_csr_if)::get(this, "", "wr_csr_vif", wr_csr_vif))
            `uvm_fatal("NOVIF", "Virtual interface [wr_csr_vif] not set for this monitor")
        if (!uvm_config_db#(virtual bmd_read_csr_if)::get(this, "", "rd_csr_vif", rd_csr_vif))
            `uvm_fatal("NOVIF", "Virtual interface [rd_csr_vif] not set for this monitor")
        phase.drop_objection(this);
    endfunction

    task main_phase(uvm_phase phase);
        main_phase_started = 1;
    endtask

    // Write method - called when transaction received
    virtual function void write_tph_rx(apci_packet trans);
        if (main_phase_started) begin
            apci_tlp tlp;
            if($cast(tlp, trans)) begin
                rx_packets.push_back(tlp);
            end else begin
                `uvm_error(get_type_name(), "Failed to cast from rx packet to rx tlp")
            end
        end
    endfunction

    virtual function void call_report();
        bit [63:0]        curr_addr;
        int num_p_tph       = 0;
        int num_p_ext_tph   = 0;
        int num_np_tph      = 0;
        int num_np_ext_tph  = 0;

        // Check for invalid combination of TPH and EXT TPH
        if (!wr_csr_vif.monitor_cb.write_tph_vld && wr_csr_vif.monitor_cb.write_tph_ext_vld) begin
            `uvm_error(get_type_name(), "MWr EXT TPH can not be enabled without enabling MWr TPH")
        end
        if (!rd_csr_vif.monitor_cb.read_tph_vld && rd_csr_vif.monitor_cb.read_tph_ext_vld) begin
            `uvm_error(get_type_name(), "MRd EXT TPH can not be enabled without enabling MRd TPH")
        end

        // Check for config != csr (MWr)
        if (wr_csr_vif.monitor_cb.write_tph_vld == 1'b1 && tph_en != 1'b1) begin
            `uvm_error(get_type_name(), "MWr TPH is enabled in CSR, but not enabled in config")
        end
        if (wr_csr_vif.monitor_cb.write_tph_ext_vld == 1'b1 && tph_ext_en != 1'b1) begin
            `uvm_error(get_type_name(), "MWr Ext TPH is enabled in CSR, but not enabled in config")
        end

        // Check for config != csr (MRd)
        if (rd_csr_vif.monitor_cb.read_tph_vld == 1'b1 && tph_en != 1'b1) begin
            `uvm_error(get_type_name(), "MRd TPH is enabled in CSR, but not enabled in config")
        end
        if (rd_csr_vif.monitor_cb.read_tph_ext_vld == 1'b1 && tph_ext_en != 1'b1) begin
            `uvm_error(get_type_name(), "MRd Ext TPH is enabled in CSR, but not enabled in config")
        end

        // Check if TPH is enabled (MWr)
        if (wr_csr_vif.monitor_cb.write_tph_vld && wr_csr_vif.monitor_cb.write_start) begin
            foreach (rx_packets[j]) begin
                // Check type/format
                if (rx_packets[j].u.fm_com.typ ==
                            {wr_csr_vif.monitor_cb.write_fmt,
                             wr_csr_vif.monitor_cb.write_64b_en,
                             wr_csr_vif.monitor_cb.write_type}) begin

                    if (!rx_packets[j].u.fm_com.typ[5]) begin
                        curr_addr = {32'h0, rx_packets[j].u.fm_mem32.addr.dw_addr, 2'b00};
                    end else begin
                        curr_addr = {rx_packets[j].u.fm_mem64.addr.dw_addr, 2'b00};
                    end

                    if (curr_addr != msi_addr && curr_addr != msix_addr) begin
                        if (rx_packets[j].ohc[1].ohc_b.hv[0] == 1'b1) begin
                            num_p_tph++;

                            // Check ST[7:0]
                            if (rx_packets[j].ohc[1].ohc_b.st_low != wr_csr_vif.monitor_cb.write_st[7:0]) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "MWr TPH Steering Tag (%x) does not match (%x) for TLP at address 0x%x",
                                    rx_packets[j].ohc[1].ohc_b.st_low,
                                    wr_csr_vif.monitor_cb.write_st[7:0],
                                    curr_addr))
                            end

                            // Check PH[1:0]
                            if (rx_packets[j].ohc[1].ohc_b.ph != wr_csr_vif.monitor_cb.write_ph) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "MWr TPH Processing Hints (%x) does not match (%x) for TLP at address 0x%x",
                                    rx_packets[j].ohc[1].ohc_b.ph,
                                    wr_csr_vif.monitor_cb.write_ph,
                                    curr_addr))
                            end
                        end else begin
                            `uvm_error(get_type_name(), $sformatf(
                                "MWr TPH is enabled, but HV[0] is not set for TLP at address 0x%x",
                                curr_addr))
                        end
                    end
                end
            end

            // Check number p_tph matches number of requests
            if (num_p_tph != wr_csr_vif.monitor_cb.write_count) begin
                `uvm_error(get_type_name(), $sformatf(
                    "MWr - Amount of TPH content found (%0d) does not match number of requests (%0d)",
                    num_p_tph, wr_csr_vif.monitor_cb.write_count))
            end
        end

        // Check if TPH is enabled (MRd)
        if (rd_csr_vif.monitor_cb.read_tph_vld && rd_csr_vif.monitor_cb.read_start) begin
            foreach (rx_packets[j]) begin
                // Check type/format
                if (rd_csr_vif.monitor_cb.read_64b_en ?   rx_packets[j].u.fm_com.typ == 8'b00100000 :
                                                            rx_packets[j].u.fm_com.typ == 8'b00000011 &&
                            {rd_csr_vif.monitor_cb.read_fmt,
                             rd_csr_vif.monitor_cb.read_type} == 6'b000000) begin

                    if (!rx_packets[j].u.fm_com.typ[5]) begin
                        curr_addr = {32'h0, rx_packets[j].u.fm_mem32.addr.dw_addr, 2'b00};
                    end else begin
                        curr_addr = {rx_packets[j].u.fm_mem64.addr.dw_addr, 2'b00};
                    end

                    if (rx_packets[j].ohc[1].ohc_b.hv[0] == 1'b1) begin
                        num_np_tph++;

                        // Check ST[7:0]
                        if (rx_packets[j].ohc[1].ohc_b.st_low != rd_csr_vif.monitor_cb.read_st[7:0]) begin
                            `uvm_error(get_type_name(), $sformatf(
                                "MRd TPH Steering Tag (%x) does not match (%x) for TLP at address 0x%x",
                                rx_packets[j].ohc[1].ohc_b.st_low,
                                rd_csr_vif.monitor_cb.read_st[7:0],
                                curr_addr))
                        end

                        // Check PH[1:0]
                        if (rx_packets[j].ohc[1].ohc_b.ph != rd_csr_vif.monitor_cb.read_ph) begin
                            `uvm_error(get_type_name(), $sformatf(
                                "MRd TPH Processing Hints (%x) does not match (%x) for TLP at address 0x%x",
                                rx_packets[j].ohc[1].ohc_b.ph,
                                rd_csr_vif.monitor_cb.read_ph,
                                curr_addr))
                        end
                    end else begin
                        `uvm_error(get_type_name(), $sformatf(
                            "MRd TPH is enabled, but HV[0] is not set for TLP at address 0x%x",
                            curr_addr))
                    end
                end
            end

            // Check number p_tph matches number of requests
            if (num_np_tph != rd_csr_vif.monitor_cb.read_count) begin
                `uvm_error(get_type_name(), $sformatf(
                    "MRd - Amount of TPH content found (%0d) does not match number of requests (%0d)",
                    num_np_tph, rd_csr_vif.monitor_cb.read_count))
            end
        end

        // Check if extended TPH is enabled (MWr)
        if (wr_csr_vif.monitor_cb.write_tph_ext_vld && wr_csr_vif.monitor_cb.write_start) begin
            foreach (rx_packets[j]) begin
                // Check type/format
                if (rx_packets[j].u.fm_com.typ ==
                            {wr_csr_vif.monitor_cb.write_fmt,
                             wr_csr_vif.monitor_cb.write_64b_en,
                             wr_csr_vif.monitor_cb.write_type}) begin

                    if (!rx_packets[j].u.fm_com.typ[5]) begin
                        curr_addr = {32'h0, rx_packets[j].u.fm_mem32.addr.dw_addr, 2'b00};
                    end else begin
                        curr_addr = {rx_packets[j].u.fm_mem64.addr.dw_addr, 2'b00};
                    end

                    if (curr_addr != msi_addr && curr_addr != msix_addr) begin
                        if (rx_packets[j].ohc[1].ohc_b.hv[1] == 1'b1) begin
                            num_p_ext_tph++;

                            // Check ST[15:8]
                            if (rx_packets[j].ohc[1].ohc_b.st_up != wr_csr_vif.monitor_cb.write_tph[11:4]) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "MWr TPH Upper Steering Tag (%x) does not match (%x) for TLP at address 0x%x",
                                    rx_packets[j].ohc[1].ohc_b.st_up,
                                    wr_csr_vif.monitor_cb.write_tph[11:4],
                                    curr_addr))
                            end
                        end else begin
                            `uvm_error(get_type_name(), $sformatf(
                                "MWr Ext TPH is enabled, but HV[1] is not set for TLP at address 0x%x",
                                curr_addr))
                        end
                    end
                end
            end

            // Check number p_tph matches number of requests
            if (num_p_ext_tph != wr_csr_vif.monitor_cb.write_count) begin
                `uvm_error(get_type_name(), $sformatf(
                    "MWr - Amount of Ext TPH content found (%0d) does not match number of requests (%0d)",
                    num_p_ext_tph, wr_csr_vif.monitor_cb.write_count))
            end
        end

        // Check if extended TPH is enabled (MRd)
        if (rd_csr_vif.monitor_cb.read_tph_ext_vld && rd_csr_vif.monitor_cb.read_start) begin
            foreach (rx_packets[j]) begin
                // Check type/format
                if (rd_csr_vif.monitor_cb.read_64b_en ?   rx_packets[j].u.fm_com.typ == 8'b00100000 :
                                                            rx_packets[j].u.fm_com.typ == 8'b00000011 &&
                            {rd_csr_vif.monitor_cb.read_fmt,
                             rd_csr_vif.monitor_cb.read_type} == 6'b000000) begin

                    if (!rx_packets[j].u.fm_com.typ[5]) begin
                        curr_addr = {32'h0, rx_packets[j].u.fm_mem32.addr.dw_addr, 2'b00};
                    end else begin
                        curr_addr = {rx_packets[j].u.fm_mem64.addr.dw_addr, 2'b00};
                    end

                    if (rx_packets[j].ohc[1].ohc_b.hv[1] == 1'b1) begin
                        num_np_ext_tph++;

                        // Check ST[15:8]
                        if (rx_packets[j].ohc[1].ohc_b.st_up != rd_csr_vif.monitor_cb.read_tph[11:4]) begin
                            `uvm_error(get_type_name(), $sformatf(
                                "MRd TPH Upper Steering Tag (%x) does not match (%x) for TLP at address 0x%x",
                                rx_packets[j].ohc[1].ohc_b.st_up,
                                rd_csr_vif.monitor_cb.read_tph[11:4],
                                curr_addr))
                        end
                    end else begin
                        `uvm_error(get_type_name(), $sformatf(
                            "MRd Ext TPH is enabled, but HV[1] is not set for TLP at address 0x%x",
                            curr_addr))
                    end
                end
            end

            // Check number p_tph matches number of requests
            if (num_np_ext_tph != rd_csr_vif.monitor_cb.read_count) begin
                `uvm_error(get_type_name(), $sformatf(
                    "MRd - Amount of Ext TPH content found (%0d) does not match number of requests (%0d)",
                    num_np_ext_tph, rd_csr_vif.monitor_cb.read_count))
            end
        end

        // Make sure some number of TPHs were found
        if (tph_en == 1'b1 && (rd_csr_vif.monitor_cb.read_start || wr_csr_vif.monitor_cb.write_start)) begin
            if (num_p_tph == 0 && num_np_tph == 0) begin
                `uvm_error(get_type_name(), "No TPH found, but TPH is enabled")
            end
        end

        // Make sure some number of EXT TPHs were found
        if (tph_ext_en == 1'b1  && (rd_csr_vif.monitor_cb.read_start || wr_csr_vif.monitor_cb.write_start)) begin
            if (num_p_ext_tph == 0 && num_np_ext_tph == 0) begin
                `uvm_error(get_type_name(), "No EXT TPH found, but EXT TPH is enabled")
            end
        end
    endfunction
endclass
