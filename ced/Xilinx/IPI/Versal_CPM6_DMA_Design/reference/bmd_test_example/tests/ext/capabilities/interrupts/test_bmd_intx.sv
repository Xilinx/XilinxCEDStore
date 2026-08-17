//==============================================================================
// test_bmd_intx.sv - Capability Interrupt BMD Tests
//==============================================================================
// Description:
//   BMD test that creates INTx interrupt once traffic is completed
//==============================================================================

class test_bmd_intx extends test_bmd;
    `uvm_component_utils(test_bmd_intx)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_intx", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        disable_extra();

        cap_cfg.cfg_int_disable = 1'b0;

        csr_cfg.rd_int_disable  = 1'b0;
        csr_cfg.wr_int_disable  = 1'b0;

        csr_cfg.wr_int_sel      = 2'b10;
        csr_cfg.rd_int_sel      = 2'b10;
    endtask

endclass : test_bmd_intx
