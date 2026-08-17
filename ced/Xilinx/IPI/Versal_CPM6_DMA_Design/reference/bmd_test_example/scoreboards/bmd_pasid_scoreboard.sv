// Verify PASID prefix exists as programmed

`uvm_analysis_imp_decl(_pasid_rx)
class bmd_pasid_scoreboard_c extends uvm_scoreboard;
    `uvm_component_utils(bmd_pasid_scoreboard_c)

    apci_tlp rx_packets[$];

    uvm_analysis_imp_pasid_rx #(apci_packet, bmd_pasid_scoreboard_c) rxp;

    virtual bmd_read_csr_if  rd_csr_vif;
    virtual bmd_write_csr_if wr_csr_vif;

    bit               pasid_en;
    bit               pasid_exe_en;
    bit               pasid_priv_en;

    bit [63:0]        msi_addr;
    bit [63:0]        msix_addr;

    bit main_phase_started;

    // Constructor
    function new(string name = "bmd_pasid_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        rxp = new("rxp", this);
    endfunction

    function void clear();
        rx_packets.delete();

        pasid_en        = '0;
        pasid_exe_en    = '0;
        pasid_priv_en   = '0;

        msi_addr        = '0;
        msix_addr       = '0;
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
    virtual function void write_pasid_rx(apci_packet trans);
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
        bit [63:0] curr_addr;
        int num_p_pasid = 0;
        int num_np_pasid = 0;

        // Check for config != CSR (MWr)
        if (wr_csr_vif.monitor_cb.write_pasid_en == 1'b1 && !pasid_en) begin
            `uvm_error(get_type_name(), "MWr PASID is enable in CSR, but not enabled in config")
        end

        // Check for config != CSR (MRd)
        if (rd_csr_vif.monitor_cb.read_pasid_en == 1'b1 && !pasid_en) begin
            `uvm_error(get_type_name(), "MRd PASID is enable in CSR, but not enabled in config")
        end

        // Check if PASID is enabled (MWr)
        if (wr_csr_vif.monitor_cb.write_pasid_en == 1'b1 && wr_csr_vif.monitor_cb.write_start) begin
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
                        if (rx_packets[j].ohc[0].ohc_a1.pv == 1'b1) begin
                            num_p_pasid++;

                            // Check PASID
                            if (rx_packets[j].ohc[0].ohc_a1.pasid != wr_csr_vif.monitor_cb.write_pasid[19:0]) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "MWr PASID (%x) does not match (%x) for TLP at address 0x%x",
                                    rx_packets[j].ohc[0].ohc_a1.pasid,
                                    wr_csr_vif.monitor_cb.write_pasid[19:0],
                                    curr_addr))
                            end

                            // Check ER
                            if (rx_packets[j].ohc[0].ohc_a1.er != wr_csr_vif.monitor_cb.write_pasid[22]) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "MWr PASID Execute Requested (%x) does not match (%x) for TLP at address 0x%x",
                                    rx_packets[j].ohc[0].ohc_a1.er,
                                    wr_csr_vif.monitor_cb.write_pasid[22],
                                    curr_addr))
                            end

                            // Check PMR
                            if (rx_packets[j].ohc[0].ohc_a1.pmr != wr_csr_vif.monitor_cb.write_pasid[23]) begin
                                `uvm_error(get_type_name(), $sformatf(
                                    "MWr PASID Privledged Mode Request (%x) " +
                                    "does not match (%x) for TLP at address 0x%x",
                                    rx_packets[j].ohc[0].ohc_a1.pmr,
                                    wr_csr_vif.monitor_cb.write_pasid[23],
                                    curr_addr))
                            end
                        end else begin
                            `uvm_error(get_type_name(), $sformatf(
                                "MWr PASID is enabled, but PV is not set for TLP at address 0x%x",
                                curr_addr))
                        end
                    end
                end
            end


            // Check number of p_pasid matches number of requests
            if (num_p_pasid != wr_csr_vif.monitor_cb.write_count) begin
                `uvm_error(get_type_name(), $sformatf(
                    "MWr - Amount of PASID content found (%0d) does not match number of requests (%0d)",
                    num_p_pasid, wr_csr_vif.monitor_cb.write_count))
            end
        end

        // Check if PASID is enabled (MRd)
        if (rd_csr_vif.monitor_cb.read_pasid_en == 1'b1 && rd_csr_vif.monitor_cb.read_start) begin
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

                    if (rx_packets[j].ohc[0].ohc_a1.pv == 1'b1) begin
                        num_np_pasid++;

                        // Check PASID
                        if (rx_packets[j].ohc[0].ohc_a1.pasid != rd_csr_vif.monitor_cb.read_pasid[19:0]) begin
                            `uvm_error(get_type_name(), $sformatf(
                                "MRd PASID (%x) does not match (%x) for TLP at address 0x%x",
                                rx_packets[j].ohc[0].ohc_a1.pasid,
                                rd_csr_vif.monitor_cb.read_pasid[19:0],
                                curr_addr))
                        end

                        // Check ER
                        if (rx_packets[j].ohc[0].ohc_a1.er != rd_csr_vif.monitor_cb.read_pasid[22]) begin
                            `uvm_error(get_type_name(), $sformatf(
                                "MRd PASID Execute Requested (%x) does not match (%x) for TLP at address 0x%x",
                                rx_packets[j].ohc[0].ohc_a1.er,
                                rd_csr_vif.monitor_cb.read_pasid[22],
                                curr_addr))
                        end

                        // Check PMR
                        if (rx_packets[j].ohc[0].ohc_a1.pmr != rd_csr_vif.monitor_cb.read_pasid[23]) begin
                            `uvm_error(get_type_name(), $sformatf(
                                "MRd PASID Privledged Mode Request (%x) does not match (%x) for TLP at address 0x%x",
                                rx_packets[j].ohc[0].ohc_a1.pmr,
                                rd_csr_vif.monitor_cb.read_pasid[23],
                                curr_addr))
                        end
                    end else begin
                        `uvm_error(get_type_name(), $sformatf(
                            "MRd PASID is enabled, but PV is not set for TLP at address 0x%x",
                            curr_addr))
                    end
                end
            end

            // Check number of np_pasid matches number of requests
            if (num_np_pasid != rd_csr_vif.monitor_cb.read_count) begin
                `uvm_error(get_type_name(), $sformatf(
                    "MRd - Amount of PASID content found (%0d) does not match number of requests (%0d)",
                    num_np_pasid, rd_csr_vif.monitor_cb.read_count))
            end
        end

        // Make sure we have at least one PASID
        if (pasid_en == 1'b1  && (rd_csr_vif.monitor_cb.read_start || wr_csr_vif.monitor_cb.write_start)) begin
            if (num_p_pasid == 0 && num_np_pasid == 0) begin
                `uvm_error(get_type_name(), "PASID is enabled, but no PASID found")
            end
        end
    endfunction
endclass
