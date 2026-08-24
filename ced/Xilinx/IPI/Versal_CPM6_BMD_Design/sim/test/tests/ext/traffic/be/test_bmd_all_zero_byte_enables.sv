//==============================================================================
// test_bmd_all_zero_byte_enables.sv - Byte Enable Traffic BMD Tests
//==============================================================================
// Description:
//   BMD test that creates randomized read / write traffic with all zero byte
//   enables
//==============================================================================

class test_bmd_all_zero_byte_enables extends test_bmd;
    `uvm_component_utils(test_bmd_all_zero_byte_enables)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_all_zero_byte_enables", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        disable_extra();

        csr_cfg.rd_start = 1'b1;
        csr_cfg.wr_start = 1'b1;

        csr_cfg.wr_size  = 1;
        csr_cfg.rd_size  = 1;

        csr_cfg.rd_upper_be = 4'h0;
        csr_cfg.rd_lower_be = 4'h0;

        csr_cfg.wr_upper_be = 4'h0;
        csr_cfg.wr_lower_be = 4'h0;

    endtask

endclass : test_bmd_all_zero_byte_enables
