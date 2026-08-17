//==============================================================================
// test_bmd_vdm.sv - Capability Other BMD Tests
//==============================================================================
// Description:
//   BMD test that creates VDMs in-place of normal posted traffic
//==============================================================================

class test_bmd_vdm extends test_bmd;
    `uvm_component_utils(test_bmd_vdm)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_vdm", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        disable_extra();

        csr_cfg.wr_start        = 1'b1;
        csr_cfg.rd_start        = 1'b0;

        csr_cfg.wr_size         = 0;

        csr_cfg.wr_tc           = '0;
        csr_cfg.st              = '0;
        csr_cfg.ph              = '0;

        csr_cfg.wr_inc_addr     = 1'b1;
        csr_cfg.w64_en          = 1'b1;
        csr_cfg.wr_count        = 5;
        csr_cfg.wr_tid          = 10'h067;
        csr_cfg.wr_upper_be     = 4'b0111;
        csr_cfg.wr_lower_be     = 4'b1110;
        csr_cfg.wr_addr         = 32'h1234_ABCD;
        csr_cfg.wr_uaddr        = {pdev_rp.bdf, 16'h10EE};

        csr_cfg.wr_tlp_type     = 5'b10010;
        csr_cfg.wr_fmt_1        = 1'b0;
    endtask

endclass : test_bmd_vdm
