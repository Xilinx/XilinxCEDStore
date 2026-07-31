//==============================================================================
// test_bmd_read_min_size_min_count.sv - Read Traffic BMD Tests
//==============================================================================
// Description:
//   BMD test that creates 1 read of 1 DW length
//==============================================================================

class test_bmd_read_min_size_min_count extends test_bmd;
    `uvm_component_utils(test_bmd_read_min_size_min_count)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_read_min_size_min_count", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        disable_extra();

        csr_cfg.wr_start = 1'b0;
        csr_cfg.rd_start = 1'b1;

        csr_cfg.rd_size = 9'h001;
        csr_cfg.rd_count = 16'h0001;

        csr_cfg.rd_upper_be = 4'b0000;

        csr_cfg.rd_tc_en = 1'b0;
        csr_cfg.rd_tc    = 3'b000;

    endtask

endclass : test_bmd_read_min_size_min_count
