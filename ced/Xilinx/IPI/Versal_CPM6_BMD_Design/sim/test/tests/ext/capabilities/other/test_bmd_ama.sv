//==============================================================================
// test_bmd_ama.sv - Capability Other BMD Tests
//==============================================================================
// Description:
//   BMD test that creates TPH traffic with AMA enabled
//==============================================================================

class test_bmd_ama extends test_bmd;
    `uvm_component_utils(test_bmd_ama)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_ama", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        disable_extra(.not_tph(1'b1));

        csr_cfg.rd_start = 1'b1;
        csr_cfg.wr_start = 1'b1;

        csr_cfg.rd_size  = 9'h001;
        csr_cfg.rd_count = 16'h0001;

        csr_cfg.wr_size  = 9'h001;
        csr_cfg.wr_count = 16'h0001;

        csr_cfg.wr_ats   = 2'b10;
        csr_cfg.rd_ats   = 2'b10;

        csr_cfg.ama      = 4'b1101;

    endtask

endclass : test_bmd_ama
