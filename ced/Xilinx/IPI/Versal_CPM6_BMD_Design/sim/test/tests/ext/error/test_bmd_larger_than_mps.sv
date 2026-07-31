//==============================================================================
// test_bmd_larger_than_mps.sv - Error BMD Tests
//==============================================================================
// Description:
//   BMD test that creates randomized write traffic that exceeds the set mps
//==============================================================================

class test_bmd_larger_than_mps extends test_bmd;
    `uvm_component_utils(test_bmd_larger_than_mps)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_larger_than_mps", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        disable_extra();

        csr_cfg.rd_start = 1'b0;
        csr_cfg.wr_start = 1'b1;

        csr_cfg.wr_size = 11'h040;

        startup_seq.cap_vseq.tag_10b_seq.set_mps = 3'b000;

    endtask

endclass : test_bmd_larger_than_mps
