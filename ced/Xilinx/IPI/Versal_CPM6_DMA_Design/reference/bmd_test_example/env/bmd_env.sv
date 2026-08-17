//==============================================================================
// BMD Environment
//
// Description:
//   UVM environment that integrates all BMD verification components including
//   scoreboards, monitors, and interfaces. Connects to framework's tb_env for
//   BFM access and analysis port connections.
//
// Key Responsibilities:
//   - Get configuration objects from config_db (set by test)
//   - Get framework environment handle for shim access
//   - Get virtual interfaces for RTL signal monitoring
//   - Create and configure all scoreboards and monitors
//   - Connect analysis ports from BFM to scoreboards
//   - Connect monitors to scoreboards
//   - Pass configuration flags to scoreboards
//==============================================================================

class bmd_env_c extends uvm_env;
    `uvm_component_utils(bmd_env_c)

    bit print_logs = 1'b1;

    //--------------------------------------------------------------------------
    // Framework Environment Handle
    //--------------------------------------------------------------------------
    // Handle to framework's tb_env for accessing:
    //   - env.rc (root complex BFM with analysis ports)
    //   - env.shim (BFM abstraction layer)
    tb_env framework_env;

    //--------------------------------------------------------------------------
    // Configuration Objects (from config_db, set by test)
    //--------------------------------------------------------------------------
    bmd_test_config_c tst_cfg;  // Error injection, test control
    bmd_csr_config_c  csr_cfg;  // Traffic parameters
    bmd_cap_config_c  cap_cfg;  // Capability settings

    //--------------------------------------------------------------------------
    // Virtual Interfaces (from config_db, bound in tb_top)
    //--------------------------------------------------------------------------
    virtual plstr_tx_if      tx_str_vif;  // TX streaming interface
    virtual plstr_rx_if      rx_str_vif;  // RX streaming interface
    virtual plstr_credit_if  rx_cr_vif;   // RX credit interface
    virtual plstr_credit_if  tx_cr_vif;   // TX credit interface
    virtual bmd_write_csr_if wr_csr_vif;  // Write CSR interface
    virtual bmd_read_csr_if  rd_csr_vif;  // Read CSR interface

    //--------------------------------------------------------------------------
    // Scoreboards (verification components)
    //--------------------------------------------------------------------------
    bmd_read_scoreboard_c              rd_sb;       // Read traffic verification
    bmd_write_scoreboard_c             wr_sb;       // Write traffic verification
    bmd_vdm_scoreboard_c               vdm_sb;      // VDM traffic verification
    bmd_rx_scoreboard_c                rx_sb;       // RX stream verification
    bmd_tx_scoreboard_c                tx_sb;       // TX stream verification
    bmd_tph_scoreboard_c               tph_sb;      // TPH prefix verification
    bmd_pasid_scoreboard_c             pasid_sb;    // PASID prefix verification
    bmd_interrupt_scoreboard_c         intr_sb;     // Interrupt verification
    bmd_ur_scoreboard_c                ur_sb;       // UR handling verification
    bmd_extended_config_scoreboard_c   ext_cfg_sb;  // Extended config verification
    bmd_performance_scoreboard_c       perf_sb;     // Performance tracking

    //--------------------------------------------------------------------------
    // Monitors (RTL signal observers)
    //--------------------------------------------------------------------------
    plstr_tx_monitor_c tx_str_monitor;  // TX streaming monitor
    plstr_rx_monitor_c rx_str_monitor;  // RX streaming monitor

    //--------------------------------------------------------------------------
    // Callbacks
    //--------------------------------------------------------------------------
    bmd_mem_callback_c mem_cb; // Memory Callback
    bmd_ur_callback_c  ur_cb;  // Unsupported Request Callback

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Build Phase
    //--------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ///////////////////////////////////////////////////////
        // Get framework environment handle
        ///////////////////////////////////////////////////////
        if (!uvm_config_db#(tb_env)::get(this, "", "framework_env", framework_env))
            `uvm_fatal(get_name(), "Failed to get [framework_env] from config_db")

        ///////////////////////////////////////////////////////
        // Get configuration objects (set by test)
        ///////////////////////////////////////////////////////
        if (!uvm_config_db#(bmd_test_config_c)::get(this, "", "tst_cfg", tst_cfg))
            `uvm_fatal(get_name(), "Failed to get [tst_cfg] from config_db")

        if (!uvm_config_db#(bmd_csr_config_c)::get(this, "", "csr_cfg", csr_cfg))
            `uvm_fatal(get_name(), "Failed to get [csr_cfg] from config_db")

        if (!uvm_config_db#(bmd_cap_config_c)::get(this, "", "cap_cfg", cap_cfg))
            `uvm_fatal(get_name(), "Failed to get [cap_cfg] from config_db")

        ///////////////////////////////////////////////////////
        // Get virtual interfaces (bound in test)
        ///////////////////////////////////////////////////////
        if (!uvm_config_db#(virtual plstr_tx_if)::get(this, "", "tx_str_vif", tx_str_vif))
            `uvm_fatal(get_name(), "Failed to get [tx_str_vif] from config_db")

        if (!uvm_config_db#(virtual plstr_rx_if)::get(this, "", "rx_str_vif", rx_str_vif))
            `uvm_fatal(get_name(), "Failed to get [rx_str_vif] from config_db")

        if (!uvm_config_db#(virtual plstr_credit_if)::get(this, "", "rx_cr_vif", rx_cr_vif))
            `uvm_fatal(get_name(), "Failed to get [rx_cr_vif] from config_db")

        if (!uvm_config_db#(virtual plstr_credit_if)::get(this, "", "tx_cr_vif", tx_cr_vif))
            `uvm_fatal(get_name(), "Failed to get [tx_cr_vif] from config_db")

        if (!uvm_config_db#(virtual bmd_write_csr_if)::get(this, "", "wr_csr_vif", wr_csr_vif))
            `uvm_fatal(get_name(), "Failed to get [wr_csr_vif] from config_db")

        if (!uvm_config_db#(virtual bmd_read_csr_if)::get(this, "", "rd_csr_vif", rd_csr_vif))
            `uvm_fatal(get_name(), "Failed to get [rd_csr_vif] from config_db")

        ///////////////////////////////////////////////////////
        // Create scoreboards
        ///////////////////////////////////////////////////////
        rx_sb      = bmd_rx_scoreboard_c::type_id::create("rx_sb", this);
        tx_sb      = bmd_tx_scoreboard_c::type_id::create("tx_sb", this);

        rd_sb      = bmd_read_scoreboard_c::type_id::create("rd_sb", this);
            // Pass virtual interfaces to read scoreboard via config_db
        uvm_config_db#(virtual bmd_read_csr_if)::set(this, "rd_sb", "rd_csr_vif", rd_csr_vif);

        wr_sb      = bmd_write_scoreboard_c::type_id::create("wr_sb", this);
            // Pass virtual interfaces to write scoreboard via config_db
        uvm_config_db#(virtual bmd_write_csr_if)::set(this, "wr_sb", "wr_csr_vif", wr_csr_vif);

        vdm_sb     = bmd_vdm_scoreboard_c::type_id::create("vdm_sb", this);
            // Pass virtual interfaces to VDM scoreboard via config_db
        uvm_config_db#(virtual bmd_write_csr_if)::set(this, "vdm_sb", "wr_csr_vif", wr_csr_vif);

        tph_sb     = bmd_tph_scoreboard_c::type_id::create("tph_sb", this);
            // Pass virtual interfaces to tph scoreboard via config_db
        uvm_config_db#(virtual bmd_write_csr_if)::set(this, "tph_sb", "wr_csr_vif", wr_csr_vif);
        uvm_config_db#(virtual bmd_read_csr_if)::set(this, "tph_sb", "rd_csr_vif", rd_csr_vif);

        pasid_sb   = bmd_pasid_scoreboard_c::type_id::create("pasid_sb", this);
            // Pass virtual interfaces to pasid scoreboard via config_db
        uvm_config_db#(virtual bmd_write_csr_if)::set(this, "pasid_sb", "wr_csr_vif", wr_csr_vif);
        uvm_config_db#(virtual bmd_read_csr_if)::set(this, "pasid_sb", "rd_csr_vif", rd_csr_vif);

        intr_sb    = bmd_interrupt_scoreboard_c::type_id::create("intr_sb", this);
            // Pass virtual interfaces to interrupt scoreboard via config_db
        uvm_config_db#(virtual bmd_write_csr_if)::set(this, "intr_sb", "wr_csr_vif", wr_csr_vif);
        uvm_config_db#(virtual bmd_read_csr_if)::set(this, "intr_sb", "rd_csr_vif", rd_csr_vif);

        ur_sb      = bmd_ur_scoreboard_c::type_id::create("ur_sb", this);
        ext_cfg_sb = bmd_extended_config_scoreboard_c::type_id::create("ext_cfg_sb", this);

        perf_sb    = bmd_performance_scoreboard_c::type_id::create("perf_sb", this);
            // Pass virtual interfaces to performance scoreboard via config_db
        uvm_config_db#(virtual bmd_write_csr_if)::set(this, "perf_sb", "wr_csr_vif", wr_csr_vif);
        uvm_config_db#(virtual bmd_read_csr_if)::set(this, "perf_sb", "rd_csr_vif", rd_csr_vif);

        ///////////////////////////////////////////////////////
        // Create monitors
        ///////////////////////////////////////////////////////
        tx_str_monitor = plstr_tx_monitor_c::type_id::create("tx_str_monitor", this);
            // Pass virtual interfaces to tx monitor via config_db
        uvm_config_db#(virtual plstr_tx_if)::set(this, "tx_str_monitor", "tx_str_vif", tx_str_vif);
        uvm_config_db#(virtual plstr_credit_if)::set(this, "tx_str_monitor", "tx_crd_vif", tx_cr_vif);

        rx_str_monitor = plstr_rx_monitor_c::type_id::create("rx_str_monitor", this);
            // Pass virtual interfaces to rx monitor via config_db
        uvm_config_db#(virtual plstr_rx_if)::set(this, "rx_str_monitor", "rx_str_vif", rx_str_vif);
        uvm_config_db#(virtual plstr_credit_if)::set(this, "rx_str_monitor", "rx_crd_vif", rx_cr_vif);

        ///////////////////////////////////////////////////////
        // Create Callbacks
        ///////////////////////////////////////////////////////
        mem_cb = new();
        ur_cb  = new();

        `uvm_info(get_name(), "BMD Environment build_phase complete", UVM_MEDIUM)
    endfunction

    //--------------------------------------------------------------------------
    // Connect Phase
    //--------------------------------------------------------------------------
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect BFM analysis ports to scoreboards
        // framework_env.shim.vip is the root complex BFM (apci_device)
        // ap_tx_pkt_exit_tl = packets exiting TL (going to link) = TX from RC perspective
        // ap_rx_pkt_enter_tl = packets entering TL (from link) = RX from RC perspective

        // Read scoreboard: monitors read requests (TX) and completions (RX)
        framework_env.shim.vip.ap_tx_pkt_exit_tl.connect(rd_sb.txp);
        framework_env.shim.vip.ap_rx_pkt_enter_tl.connect(rd_sb.rxp);

        // Write scoreboard: monitors write requests (TX)
        framework_env.shim.vip.ap_rx_pkt_enter_tl.connect(wr_sb.rxp);

        // VDM scoreboard: monitors VDM messages (TX from device)
        framework_env.shim.vip.ap_rx_pkt_enter_tl.connect(vdm_sb.rxp);

        // RX scoreboard: monitors packets exiting TL
        framework_env.shim.vip.ap_tx_pkt_exit_tl.connect(rx_sb.txp);

        // TX scoreboard: monitors packets entering TL
        framework_env.shim.vip.ap_rx_pkt_enter_tl.connect(tx_sb.rxp);

        // TPH scoreboard: monitors packets for TPH prefix
        framework_env.shim.vip.ap_rx_pkt_enter_tl.connect(tph_sb.rxp);

        // PASID scoreboard: monitors packets for PASID prefix
        framework_env.shim.vip.ap_rx_pkt_enter_tl.connect(pasid_sb.rxp);

        // Interrupt scoreboard: monitors message TLPs
        framework_env.shim.vip.ap_rx_pkt_enter_tl.connect(intr_sb.rxp);

        // UR scoreboard: monitors unsupported request completions
        framework_env.shim.vip.ap_rx_pkt_enter_tl.connect(ur_sb.rxp);

        // Extended config scoreboard: monitors config space accesses
        framework_env.shim.vip.ap_tx_pkt_exit_tl.connect(ext_cfg_sb.txp);
        framework_env.shim.vip.ap_rx_pkt_enter_tl.connect(ext_cfg_sb.rxp);

        // Performance scoreboard: monitors all traffic
        framework_env.shim.vip.ap_tx_pkt_exit_tl.connect(perf_sb.txp);
        framework_env.shim.vip.ap_rx_pkt_enter_tl.connect(perf_sb.rxp);

        // Connect monitors to scoreboards
        // TX/RX stream monitors observe BMD RTL streaming interfaces
        tx_str_monitor.tx_str_ap.connect(tx_sb.tx_str_ai);
        rx_str_monitor.rx_str_ap.connect(rx_sb.rx_str_ai);

        `uvm_info(get_name(), "BMD Environment connect_phase complete", UVM_MEDIUM)
    endfunction

    //--------------------------------------------------------------------------
    // Pre-Main Phase
    //--------------------------------------------------------------------------
    virtual task pre_main_phase(uvm_phase phase);
        super.pre_main_phase(phase);

        // Pass configuration flags to scoreboards
        // These flags control scoreboard behavior and checking

        this.pass_config();

        // Append callbacks to VIP
        this.framework_env.shim.vip.append_callback(mem_cb);
        this.framework_env.shim.vip.append_callback(ur_cb);

        `uvm_info(get_name(), "Configuration objects written to scoreboards", UVM_MEDIUM)
    endtask

    //--------------------------------------------------------------------------
    // Report Phase
    //--------------------------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        // Call Summary and Logs
        print_bmd_summary();
        write_sb_logs();

        // Call scoreboard report functions
        `uvm_info(get_name(), "==============================", UVM_LOW)
        `uvm_info(get_name(), "=== BMD Scoreboard Reports ===", UVM_LOW)
        `uvm_info(get_name(), "==============================", UVM_LOW)
        print_sb_reports();
        `uvm_info(get_name(), "==============================", UVM_LOW)
        `uvm_info(get_name(), "===== End of BMD Reports =====", UVM_LOW)
        `uvm_info(get_name(), "==============================", UVM_LOW)
    endfunction

    //--------------------------------------------------------------------------
    // User Functions
    //--------------------------------------------------------------------------
    virtual function void print_bmd_summary();
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("\n==================================================="),
                UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("---------------------------------------------------"),
                UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("Write Traffic Enabled: %h, Read Traffic Enabled: %h",
                csr_cfg.wr_start, csr_cfg.rd_start), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("---------------------------------------------------"),
                UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("Write Characteristics:"),
                UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > 64-bit Enable:        0x%h",
                csr_cfg.w64_en), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Upper Address:        0x%h",
                csr_cfg.wr_uaddr), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Address:              0x%h",
                csr_cfg.wr_addr), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Size (DW):            0x%h",
                csr_cfg.wr_size), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Count:                0x%h",
                csr_cfg.wr_count), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Write Pattern:        0x%h",
            csr_cfg.wr_pattern), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Lower Byte Enable:    0x%h",
                csr_cfg.wr_lower_be), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Upper Byte Enable:    0x%h",
                csr_cfg.wr_upper_be), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Traffic Class:        0x%h",
                csr_cfg.wr_tc), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("---------------------------------------------------"),
                UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("Read Characteristics:"), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > 64-bit Enable:        0x%h",
                csr_cfg.r64_en), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Upper Address:        0x%h",
                csr_cfg.rd_uaddr), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Address:              0x%h",
                csr_cfg.rd_addr), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Size (DW):            0x%h",
                csr_cfg.rd_size), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Count:                0x%h",
                csr_cfg.rd_count), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Expected Pattern:     0x%h",
                csr_cfg.rd_pattern), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Lower Byte Enable:    0x%h",
                csr_cfg.rd_lower_be), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Upper Byte Enable:    0x%h",
                csr_cfg.rd_upper_be), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > Traffic Class:        0x%h",
                csr_cfg.rd_tc), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("---------------------------------------------------"),
                UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("Config Information:"),
                UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_10b_tag_req_en:   0x%h",
                cap_cfg.cfg_10b_tag_req_en), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_ext_tag_en:       0x%h",
                cap_cfg.cfg_ext_tag_en), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("  MSI-X:                            "),
                UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_msix_en:          0x%h",
                cap_cfg.cfg_msix_en), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_msix_addr:        0x%h",
                cap_cfg.cfg_msix_addr), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_msix_data_rd:     0x%h",
                cap_cfg.cfg_msix_data_rd), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_msix_data_wr:     0x%h",
                cap_cfg.cfg_msix_data_wr), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("  MSI:                            "),
                UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_msi_en:           0x%h",
                cap_cfg.cfg_msi_en), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_msi_ext_data_en:  0x%h",
                cap_cfg.cfg_msi_ext_data_en), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_msi_mask_vector:  0x%h",
                cap_cfg.cfg_msi_mask_vector), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_msi_addr:         0x%h",
                cap_cfg.cfg_msi_addr), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_msi_data:         0x%h",
                cap_cfg.cfg_msi_data), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_multi_msg_en:     0x%h",
                cap_cfg.cfg_multi_msg_en), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("  Atomics:                            "),
                UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_atomic_req_en:    0x%h",
                cap_cfg.cfg_atomic_req_en), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("---------------------------------------------------"),
                UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("Interrupt Information:"),
                UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_int_disable:      0x%h",
                cap_cfg.cfg_int_disable), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > rd_int_disable:       0x%h",
                csr_cfg.rd_int_disable), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > wr_int_disable:       0x%h",
                csr_cfg.wr_int_disable), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > wr_int_sel:           0x%h",
                csr_cfg.wr_int_sel), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > rd_int_sel:           0x%h",
                csr_cfg.rd_int_sel), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > msix_wr_vec:          0x%h",
                csr_cfg.msix_wr_vec), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > msix_rd_vec:          0x%h",
                csr_cfg.msix_rd_vec), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > intx_wr_vec:          0x%h",
                csr_cfg.intx_wr_vec), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > intx_rd_vec:          0x%h",
                csr_cfg.intx_rd_vec), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("---------------------------------------------------"),
                UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("Error Injection Information:"),
                UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > read_out_of_range:    0x%h",
                tst_cfg.read_out_of_range), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > out_of_range_addr:    0x%h",
                tst_cfg.out_of_range_addr), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > inject_bad_data:      0x%h",
                tst_cfg.inject_bad_data), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > bad_data:             0x%h",
                tst_cfg.bad_data), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > send_ur_to_dut:       0x%h",
                tst_cfg.send_ur_to_dut), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > bad_byte:             0x%h",
                tst_cfg.bad_byte), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("---------------------------------------------------"),
                UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("PASID Information:"), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_pf_pasid_en:      0x%h",
                cap_cfg.cfg_pf_pasid_en), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_pf_pasid_exe_en:  0x%h",
                cap_cfg.cfg_pf_pasid_exe_en), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_pf_pasid_priv_en: 0x%h",
                cap_cfg.cfg_pf_pasid_priv_en), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > pasid:                0x%h",
                csr_cfg.pasid), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("TPH Information:"), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_tph_en:           0x%h",
                cap_cfg.cfg_tph_en), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > cfg_tph_ext_en:       0x%h",
                cap_cfg.cfg_tph_ext_en), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > st:                   0x%h",
                csr_cfg.st), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("      > ph:                   0x%h",
                csr_cfg.ph), UVM_NONE)
        if (this.print_logs) `uvm_info("BMD Overview",
            $sformatf("==================================================="),
                UVM_NONE)
    endfunction

    virtual function void write_sb_logs();
        if (this.print_logs) this.tx_str_monitor.write_logs();
        if (this.print_logs) this.rx_str_monitor.write_logs();
        if (this.print_logs) this.rd_sb.write_logs();
        if (this.print_logs) this.wr_sb.write_logs();
        if (this.print_logs) this.rx_sb.write_logs();
        if (this.print_logs) this.tx_sb.write_logs();
    endfunction

    virtual function void print_sb_reports();
        this.tx_str_monitor.call_report();
        this.rx_str_monitor.call_report();
        this.rd_sb.call_report();
        this.wr_sb.call_report();
        this.vdm_sb.call_report();
        this.intr_sb.call_report();
        this.ur_sb.call_report();
        this.pasid_sb.call_report();
        this.tph_sb.call_report();
        this.ext_cfg_sb.call_report();
        this.perf_sb.call_report();
    endfunction

    function void clear_components();
        this.rd_sb.clear();
        this.wr_sb.clear();
        this.vdm_sb.clear();
        this.intr_sb.clear();
        this.ur_sb.clear();
        this.pasid_sb.clear();
        this.tph_sb.clear();
        this.ext_cfg_sb.clear();
        this.perf_sb.clear();

        this.mem_cb.clear();
        this.ur_cb.clear();

        this.csr_cfg.clear_excluded_regions();
    endfunction

    function void pass_config();
        // Connect Write Scoreboard to Configs
        this.wr_sb.wr_tc                    = csr_cfg.wr_tc;
        this.wr_sb.msi_addr                 = cap_cfg.cfg_msi_addr;
        this.wr_sb.msix_addr                = cap_cfg.cfg_msix_addr;

        // Connect Read Scoreboard to Configs
        this.rd_sb.cfg_10b_tag_req_en       = cap_cfg.cfg_10b_tag_req_en;
        this.rd_sb.cfg_ext_tag_en           = cap_cfg.cfg_ext_tag_en;
        this.rd_sb.rd_tc                    = csr_cfg.rd_tc;
        this.rd_sb.inject_bad_data          = tst_cfg.inject_bad_data;
        this.rd_sb.send_ur_to_dut           = tst_cfg.send_ur_to_dut;

        // Connect Interrupt Scoreboard to Configs
        this.intr_sb.cfg_int_disable        = cap_cfg.cfg_int_disable;
        this.intr_sb.cfg_msix_en            = cap_cfg.cfg_msix_en;
        this.intr_sb.cfg_msi_en             = cap_cfg.cfg_msi_en;
        this.intr_sb.msi_addr               = cap_cfg.cfg_msi_addr;
        this.intr_sb.msix_addr              = cap_cfg.cfg_msix_addr;
        this.intr_sb.msi_data               = cap_cfg.cfg_msi_data;
        this.intr_sb.msix_data_wr           = cap_cfg.cfg_msix_data_wr;
        this.intr_sb.msix_data_rd           = cap_cfg.cfg_msix_data_rd;
        this.intr_sb.msi_mask_vector        = cap_cfg.cfg_msi_mask_vector;

        // Connect PASID Scoreboard to Configs
        this.pasid_sb.pasid_en              = cap_cfg.cfg_pf_pasid_en;
        this.pasid_sb.pasid_exe_en          = cap_cfg.cfg_pf_pasid_exe_en;
        this.pasid_sb.pasid_priv_en         = cap_cfg.cfg_pf_pasid_priv_en;
        this.pasid_sb.msi_addr              = cap_cfg.cfg_msi_addr;
        this.pasid_sb.msix_addr             = cap_cfg.cfg_msix_addr;

        // Connect TPH Scoreboard to Configs
        this.tph_sb.tph_en                  = cap_cfg.cfg_tph_en;
        this.tph_sb.tph_ext_en              = cap_cfg.cfg_tph_ext_en;
        this.tph_sb.msi_addr                = cap_cfg.cfg_msi_addr;
        this.tph_sb.msix_addr               = cap_cfg.cfg_msix_addr;

        // Connect UR Scoreboard to Configs
        this.ur_sb.read_out_of_range        = tst_cfg.read_out_of_range;

        // Connect Memory Callback to Configs
        this.mem_cb.inject_bad_data         = tst_cfg.inject_bad_data;
        this.mem_cb.bad_data                = tst_cfg.bad_data;
        this.mem_cb.bad_byte                = tst_cfg.bad_byte;
        this.mem_cb.pattern                 = csr_cfg.rd_pattern;

        // Connect UR Callback to Configs
        this.ur_cb.send_ur_to_dut           = tst_cfg.send_ur_to_dut;
    endfunction
endclass
