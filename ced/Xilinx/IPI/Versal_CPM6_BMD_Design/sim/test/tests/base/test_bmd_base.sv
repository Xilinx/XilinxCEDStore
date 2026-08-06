//==============================================================================
// test_bmd_base.sv - Base test class for all BMD tests
//==============================================================================
// Extends framework's test_basic to provide BMD-specific functionality:
// - Creates and configures BMD config objects
// - Populates configs with runtime context (BAR info, etc.)
// - Provides helper methods for capability programming
// - Provides helper methods for CSR access
// - Sets up BMD environment via config_db
//==============================================================================

class test_bmd_base extends test_bmd_ep;
    `uvm_component_utils(test_bmd_base)

    //--------------------------------------------------------------------------
    // Environment
    //--------------------------------------------------------------------------
    bmd_env_c         bmd_env;

    //--------------------------------------------------------------------------
    // Configuration Objects
    //--------------------------------------------------------------------------
    bmd_csr_config_c  csr_cfg;
    bmd_cap_config_c  cap_cfg;
    bmd_test_config_c tst_cfg;

    //--------------------------------------------------------------------------
    // Device Handles (cached after enumeration)
    //--------------------------------------------------------------------------
    pcie_device         pdev_ep;
    pcie_device         pdev_rp;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_base", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Build Phase: Create configuration objects
    //--------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create BMD environment instance
        bmd_env = bmd_env_c::type_id::create("bmd_env", this);

        // Pass framework environment to BMD environment
        uvm_config_db#(tb_env)::set(this, "bmd_env", "framework_env", env);

        // Set framework environment handle in config_db for sequences
        uvm_config_db#(tb_env)::set(null, "bmd_base_sequence", "env", env);

        // Create configuration objects
        csr_cfg = bmd_csr_config_c::type_id::create("csr_cfg");
        cap_cfg = bmd_cap_config_c::type_id::create("cap_cfg");
        tst_cfg = bmd_test_config_c::type_id::create("tst_cfg");

        // Set configuration objects in config_db for environment
        uvm_config_db#(bmd_csr_config_c)::set(this,  "bmd_env", "csr_cfg", csr_cfg);
        uvm_config_db#(bmd_cap_config_c)::set(this,  "bmd_env", "cap_cfg", cap_cfg);
        uvm_config_db#(bmd_test_config_c)::set(this, "bmd_env", "tst_cfg", tst_cfg);

        // Set configuration objects in config_db for sequences
        uvm_config_db#(bmd_csr_config_c)::set(null,  "bmd_base_sequence", "csr_cfg", csr_cfg);
        uvm_config_db#(bmd_cap_config_c)::set(null,  "bmd_base_sequence", "cap_cfg", cap_cfg);
        uvm_config_db#(bmd_test_config_c)::set(null, "bmd_base_sequence", "tst_cfg", tst_cfg);

        `uvm_info(get_name(), "BMD configuration objects created and set in config_db", UVM_MEDIUM)
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        timeout = 1000us;
    endfunction

    //--------------------------------------------------------------------------
    // Configure Phase: Randomize configuration objects
    //--------------------------------------------------------------------------
    virtual task configure_phase(uvm_phase phase);
        super.configure_phase(phase);

        // Get device handles from shim container
        pdev_ep = env.shim.container.get_pdev_EP();
        pdev_rp = env.shim.container.get_pdev_RP();

        if (pdev_ep == null) begin
            `uvm_fatal(get_name(), "Failed to get endpoint device handle")
        end

        // Populate CSR config with BAR exclusion regions
        foreach (pdev_ep.membar[i]) begin
            if (pdev_ep.membar[i].sz > 0) begin
                csr_cfg.add_excluded_region(pdev_ep.membar[i].base, pdev_ep.membar[i].sz);
                `uvm_info(get_name(), $sformatf("Added BAR%0d exclusion for DMA (csr_cfg): base=0x%016x size=0x%016x",
                    i, pdev_ep.membar[i].base, pdev_ep.membar[i].sz), UVM_MEDIUM)
            end
        end

        // Randomize configuration objects
        // Note: This happens AFTER start_of_simulation_phase, so BAR info is available
        if (!csr_cfg.randomize()) begin
            `uvm_fatal(get_name(), "Failed to randomize CSR configuration")
        end

        // Populate capability config with address exclusion regions
        add_address_exclusion_regions();

        if (!cap_cfg.randomize()) begin
            `uvm_fatal(get_name(), "Failed to randomize capability configuration")
        end

        add_test_exclusions();

        if (!tst_cfg.randomize()) begin
            `uvm_fatal(get_name(), "Failed to randomize test configuration")
        end

        `uvm_info(get_name(), "Configuration objects randomized successfully", UVM_MEDIUM)
    endtask

    //--------------------------------------------------------------------------
    // Main Phase: Override in derived tests
    //--------------------------------------------------------------------------
    virtual task main_phase(uvm_phase phase);
        super.main_phase(phase);
        `uvm_info(get_name(), "Base test main_phase - override in derived test", UVM_LOW)
    endtask

    //--------------------------------------------------------------------------
    // User functions
    //--------------------------------------------------------------------------
    function void add_address_exclusion_regions();
            // 32-bit Read
        cap_cfg.add_excluded_region({32'd0, csr_cfg.rd_addr},
                                    {32'd0, csr_cfg.rd_addr} +
                                    (csr_cfg.rd_count * (csr_cfg.rd_size << 2)));
        `uvm_info(get_name(), $sformatf({"Added MSI / MSI-X exclusion (cap_cfg): ",
                                         "lower bound=0x%016x | upper bound=0x%016x"},
                                            {32'd0, csr_cfg.rd_addr},
                                            {32'd0, csr_cfg.rd_addr} +
                                            (csr_cfg.rd_count * (csr_cfg.rd_size << 2))),
                                            UVM_MEDIUM)
            // 64-bit Read
        cap_cfg.add_excluded_region({csr_cfg.rd_uaddr, csr_cfg.rd_addr},
                                    {csr_cfg.rd_uaddr, csr_cfg.rd_addr} +
                                    (csr_cfg.rd_count * (csr_cfg.rd_size << 2)));
        `uvm_info(get_name(), $sformatf({"Added MSI / MSI-X exclusion (cap_cfg): ",
                                         "lower bound=0x%016x | upper bound=0x%016x"},
                                            {csr_cfg.rd_uaddr, csr_cfg.rd_addr},
                                            {csr_cfg.rd_uaddr, csr_cfg.rd_addr} +
                                            (csr_cfg.rd_count * (csr_cfg.rd_size << 2))),
                                            UVM_MEDIUM)
            // 32-bit Write
        cap_cfg.add_excluded_region({32'd0, csr_cfg.wr_addr},
                                    {32'd0, csr_cfg.wr_addr} +
                                    (csr_cfg.wr_count * (csr_cfg.wr_size << 2)));
        `uvm_info(get_name(), $sformatf({"Added MSI / MSI-X exclusion (cap_cfg): ",
                                         "lower bound=0x%016x | upper bound=0x%016x"},
                                            {32'd0, csr_cfg.wr_addr},
                                            {32'd0, csr_cfg.wr_addr} +
                                            (csr_cfg.wr_count * (csr_cfg.wr_size << 2))),
                                            UVM_MEDIUM)
            // 64-bit Write
        cap_cfg.add_excluded_region({csr_cfg.wr_uaddr, csr_cfg.wr_addr},
                                    {csr_cfg.wr_uaddr, csr_cfg.wr_addr} +
                                    (csr_cfg.wr_count * (csr_cfg.wr_size << 2)));
        `uvm_info(get_name(), $sformatf({"Added MSI / MSI-X exclusion (cap_cfg): ",
                                         "lower bound=0x%016x | upper bound=0x%016x"},
                                            {csr_cfg.wr_uaddr, csr_cfg.wr_addr},
                                            {csr_cfg.wr_uaddr, csr_cfg.wr_addr} +
                                            (csr_cfg.wr_count * (csr_cfg.wr_size << 2))),
                                            UVM_MEDIUM)
    endfunction

    function void add_test_exclusions();
        tst_cfg.add_error_vars(bmd_mem_pkg::MAX_CSR, csr_cfg.rd_pattern);
    endfunction

    function void disable_extra(bit not_pasid = 1'b0, bit not_tph = 1'b0);
        cap_cfg.cfg_int_disable         = 1'b1;
        cap_cfg.cfg_atomic_req_en       = 1'b0;
        cap_cfg.cfg_pf_pasid_en         = not_pasid ? 1'b1 : 1'b0;
        cap_cfg.cfg_msix_en             = 1'b0;
        cap_cfg.cfg_msi_en              = 1'b0;
        cap_cfg.cfg_pf_pasid_exe_en     = not_pasid ? cap_cfg.cfg_pf_pasid_exe_en : 1'b0;
        cap_cfg.cfg_pf_pasid_priv_en    = not_pasid ? cap_cfg.cfg_pf_pasid_priv_en : 1'b0;
        cap_cfg.cfg_tph_en              = not_tph ? 1'b1 : 1'b0;
        cap_cfg.cfg_tph_ext_en          = not_tph ? 1'b1 : 1'b0;

        tst_cfg.send_ur_to_dut          = 1'b0;
        tst_cfg.read_out_of_range       = 1'b0;
        tst_cfg.inject_bad_data         = 1'b0;

        csr_cfg.rd_int_disable          = 1'b1;
        csr_cfg.wr_int_disable          = 1'b1;
    endfunction

    function void configure_new_run();
        bmd_env.clear_components();

        if (!csr_cfg.randomize()) begin
            `uvm_fatal(get_name(), "Failed to randomize CSR configuration")
        end

        add_address_exclusion_regions();

        if (!cap_cfg.randomize()) begin
            `uvm_fatal(get_name(), "Failed to randomize capability configuration")
        end

        add_test_exclusions();

        if (!tst_cfg.randomize()) begin
            `uvm_fatal(get_name(), "Failed to randomize test configuration")
        end
    endfunction

    function void connect_new_run();
        bmd_env.pass_config();
    endfunction
endclass
