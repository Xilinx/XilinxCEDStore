//==============================================================================
// bmd_base_sequence.sv - Base sequence for all BMD sequences
//==============================================================================
// Base class providing common functionality for BMD sequences including:
// - Config object retrieval from config_db
// - Device handle caching (pdev_ep, pdev_rp)
// - Helper methods for CSR access via MMIO
// - Common sequence setup and teardown
//==============================================================================
class bmd_base_sequence_c extends uvm_sequence;
    `uvm_object_utils(bmd_base_sequence_c)

    //--------------------------------------------------------------------------
    // Configuration Objects (retrieved from config_db)
    //--------------------------------------------------------------------------
    bmd_csr_config_c    csr_cfg;
    bmd_cap_config_c    cap_cfg;
    bmd_test_config_c   tst_cfg;

    //--------------------------------------------------------------------------
    // Device Handles (cached for convenience)
    //--------------------------------------------------------------------------
    pcie_device         pdev_ep;    // Endpoint device
    pcie_device         pdev_rp;    // Root port device

    //--------------------------------------------------------------------------
    // Framework Environment Handle (for shim API access)
    //--------------------------------------------------------------------------
    tb_env              env;

    //--------------------------------------------------------------------------
    // Virtual Interfaces (from config_db, bound in tb_top)
    //--------------------------------------------------------------------------
    virtual bmd_write_csr_if wr_csr_vif;  // Write CSR interface (for vseq timeout)
    virtual bmd_read_csr_if  rd_csr_vif;  // Read CSR interface (for vseq timeout)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_base_sequence");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Pre-body: Get configuration objects and device handles
    //--------------------------------------------------------------------------
    virtual task pre_body();
        super.pre_body();

        ///////////////////////////////////////////////////////
        // Get framework handle
        ///////////////////////////////////////////////////////
        if (!uvm_config_db#(tb_env)::get(null, "bmd_base_sequence", "env", env)) begin
            `uvm_fatal(get_name(), "Failed to get framework environment handle from config_db")
        end

        ///////////////////////////////////////////////////////
        // Get device handles from shim
        ///////////////////////////////////////////////////////
        pdev_ep = env.shim.container.get_pdev_EP();
        pdev_rp = env.shim.container.get_pdev_RP();

        if (pdev_ep == null) begin
            `uvm_fatal(get_name(), "Failed to get endpoint device handle")
        end

        ///////////////////////////////////////////////////////
        // Get Configuration Objects (bound in test_bmd_base)
        ///////////////////////////////////////////////////////
        if (!uvm_config_db#(bmd_csr_config_c)::get(null, "bmd_base_sequence", "csr_cfg", csr_cfg)) begin
            `uvm_fatal(get_name(), "Failed to get [csr_cfg] from config_db")
        end

        if (!uvm_config_db#(bmd_cap_config_c)::get(null, "bmd_base_sequence", "cap_cfg", cap_cfg)) begin
            `uvm_fatal(get_name(), "Failed to get [cap_cfg] from config_db")
        end

        if (!uvm_config_db#(bmd_test_config_c)::get(null, "bmd_base_sequence", "tst_cfg", tst_cfg)) begin
            `uvm_fatal(get_name(), "Failed to get [tst_cfg] from config_db")
        end

        ///////////////////////////////////////////////////////
        // Get virtual interfaces (bound in test)
        ///////////////////////////////////////////////////////
        if (!uvm_config_db#(virtual bmd_write_csr_if)::get(null, "", "wr_csr_vif", wr_csr_vif))
            `uvm_fatal(get_name(), "Failed to get [wr_csr_vif] from config_db")

        if (!uvm_config_db#(virtual bmd_read_csr_if)::get(null, "", "rd_csr_vif", rd_csr_vif))
            `uvm_fatal(get_name(), "Failed to get [rd_csr_vif] from config_db")
    endtask

    //--------------------------------------------------------------------------
    // Helper: Issue CSR write via MMIO to BAR0
    //--------------------------------------------------------------------------
    virtual task issue_csr_write(
        input bit [6:0]  csr_offset,    // CSR offset (in DW)
        input bit [31:0] data           // Data to write
    );
        amd_mem_tlp tlp;
        bit [63:0] addr;

        // Calculate address: BAR0 base + (CSR offset << 2)
        addr = pdev_ep.membar[0].base + (csr_offset << 2);

        // Build and send memory write TLP
        tlp = amd_mem_tlp::type_id::create("tlp");
        tlp.build_wr(addr, .data({data}), .blocking(shim_enum_pkg::SCHED));
        env.shim.api.send_mem(tlp);

        `uvm_info(get_name(), $sformatf("CSR Write: offset=0x%x addr=0x%x data=0x%x",
            csr_offset, addr, data), UVM_MEDIUM)
    endtask

    //--------------------------------------------------------------------------
    // Helper: Issue CSR read via MMIO from BAR0
    //--------------------------------------------------------------------------
    virtual task issue_csr_read(
        input  bit [6:0]  csr_offset,   // CSR offset (in DW)
        output bit [31:0] data          // Data read
    );
        amd_mem_tlp tlp;
        bit [63:0] addr;

        // Calculate address: BAR0 base + (CSR offset << 2)
        addr = pdev_ep.membar[0].base + (csr_offset << 2);

        // Build and send memory read TLP
        tlp = amd_mem_tlp::type_id::create("tlp");
        tlp.build_rd(addr, 1, .blocking(shim_enum_pkg::DONE));
        env.shim.api.send_mem(tlp);

        // Extract data from completion
        data = tlp.data[0];

        `uvm_info(get_name(), $sformatf("CSR Read: offset=0x%x addr=0x%x data=0x%x",
            csr_offset, addr, data), UVM_MEDIUM)
    endtask

    //--------------------------------------------------------------------------
    // Helper: Write via MMIO to Address
    //--------------------------------------------------------------------------
    virtual task issue_addr_write(
        input bit [63:0] addr,
        input bit [31:0] data
    );
        amd_mem_tlp tlp;
        bit [31:0]  data_array[];

        data_array = new[1];
        data_array[0] = data;

        tlp = amd_mem_tlp::type_id::create("tlp");
        tlp.build_wr(addr, .data(data_array));

        env.shim.api.send_mem(tlp);
        `uvm_info(get_name(), $sformatf("MMIO Write: addr=0x%x data=0x%x",
            addr, data), UVM_MEDIUM)
    endtask

    //--------------------------------------------------------------------------
    // Helper: Issue CSR read via MMIO from BAR0
    //--------------------------------------------------------------------------
    virtual task issue_addr_read(
        input  bit [63:0] addr,
        output bit [31:0] data
    );
        amd_mem_tlp tlp;

        // Build and send memory read TLP
        tlp = amd_mem_tlp::type_id::create("tlp");
        tlp.build_rd(addr, 1, .blocking(shim_enum_pkg::DONE));
        env.shim.api.send_mem(tlp);

        // Extract data from completion
        data = tlp.data[0];

        `uvm_info(get_name(), $sformatf("MMIO Read: addr=0x%x data=0x%x",
            addr, data), UVM_MEDIUM)
    endtask

    //--------------------------------------------------------------------------
    // Body: Override in derived classes
    //--------------------------------------------------------------------------
    virtual task body();
        `uvm_fatal(get_name(), "body() must be overridden in derived sequence class")
    endtask

endclass
