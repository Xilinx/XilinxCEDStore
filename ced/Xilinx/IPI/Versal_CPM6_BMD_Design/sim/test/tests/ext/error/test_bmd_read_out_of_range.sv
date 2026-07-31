//==============================================================================
// test_bmd_read_out_of_range.sv - Error BMD Tests
//==============================================================================
// Description:
//   BMD test that reads out of the CSR range (to trigger a UR from BMD)
//==============================================================================

class test_bmd_read_out_of_range extends test_bmd;
    `uvm_component_utils(test_bmd_read_out_of_range)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_read_out_of_range", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        disable_extra();

        tst_cfg.read_out_of_range = 1'b1;

        csr_cfg.rd_start = 1'b0;
        csr_cfg.wr_start = 1'b0;

    endtask

endclass : test_bmd_read_out_of_range
