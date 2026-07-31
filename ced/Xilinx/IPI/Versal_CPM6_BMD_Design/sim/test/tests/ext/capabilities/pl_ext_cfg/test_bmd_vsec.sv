//==============================================================================
// test_bmd_vsec.sv - Capability PL Extended Configuration BMD Tests
//==============================================================================
// Description:
//   BMD test that accesses VSEC capability within BMD (PL Config Space)
//==============================================================================

class test_bmd_vsec extends test_bmd;
    `uvm_component_utils(test_bmd_vsec)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_vsec", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        disable_extra();

        csr_cfg.wr_start            = 1'b0;
        csr_cfg.rd_start            = 1'b0;

        tst_cfg.access_vsec         = 1'b1;

    endtask

endclass : test_bmd_vsec
