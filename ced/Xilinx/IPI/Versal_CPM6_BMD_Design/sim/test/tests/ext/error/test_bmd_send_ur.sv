//==============================================================================
// test_bmd_send_ur.sv - Error BMD Tests
//==============================================================================
// Description:
//   BMD test that sends a UR to the DUT then runs randomized traffic
//==============================================================================

class test_bmd_send_ur extends test_bmd;
    `uvm_component_utils(test_bmd_send_ur)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_send_ur", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        tst_cfg.send_ur_to_dut = 1'b1;

    endtask

endclass : test_bmd_send_ur
