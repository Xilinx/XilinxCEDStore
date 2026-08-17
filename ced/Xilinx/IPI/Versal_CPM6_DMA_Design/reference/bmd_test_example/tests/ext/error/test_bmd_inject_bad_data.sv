//==============================================================================
// test_bmd_inject_bad_data.sv - Error BMD Tests
//==============================================================================
// Description:
//   BMD test that creates randomized read and (possibly) write traffic with bad
//   data injected in completions to force a dma error
//==============================================================================

class test_bmd_inject_bad_data extends test_bmd;
    `uvm_component_utils(test_bmd_inject_bad_data)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_inject_bad_data", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        disable_extra();

        csr_cfg.rd_start = 1'b1;
        tst_cfg.inject_bad_data = 1'b1;

    endtask

endclass : test_bmd_inject_bad_data
