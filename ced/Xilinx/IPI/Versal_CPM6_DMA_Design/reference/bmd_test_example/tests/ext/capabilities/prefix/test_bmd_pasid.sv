//==============================================================================
// test_bmd_pasid.sv - Capability Prefix BMD Tests
//==============================================================================
// Description:
//   BMD test that creates random read and write traffic that use pasid prefixes
//==============================================================================

class test_bmd_pasid extends test_bmd;
    `uvm_component_utils(test_bmd_pasid)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_pasid", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        disable_extra(.not_pasid(1'b1));

        csr_cfg.wr_start            = 1'b1;
        csr_cfg.rd_start            = 1'b1;

    endtask

endclass : test_bmd_pasid
