//==============================================================================
// test_bmd_10b_tag.sv - Capability Tag BMD Tests
//==============================================================================
// Description:
//   BMD test that creates random read and write traffic that use 10b tags
//==============================================================================

class test_bmd_10b_tag extends test_bmd;
    `uvm_component_utils(test_bmd_10b_tag)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_10b_tag", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        csr_cfg.wr_start            = 1'b1;
        csr_cfg.rd_start            = 1'b1;

        cap_cfg.cfg_10b_tag_req_en  = 1'b1;
        cap_cfg.cfg_ext_tag_en      = 1'b1;

    endtask

endclass : test_bmd_10b_tag
