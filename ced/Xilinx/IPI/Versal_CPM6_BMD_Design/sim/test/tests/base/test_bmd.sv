//==============================================================================
// test_bmd.sv - Base BMD Test with Full Randomization
//==============================================================================
// Description:
//   Baseline BMD test that uses default randomization from test_bmd_base_c.
//   Tests general BMD functionality with randomized traffic parameters,
//   capabilities, and error injection settings.
//
// Test Flow:
//   1. Randomize all config objects (done in base class)
//   2. Run startup sequence (reset, capabilities, CSRs, prefixes)
//   3. Start traffic generation
//   4. Wait for completion with timeout
//   5. Report results
//==============================================================================

class test_bmd extends test_bmd_base;
    `uvm_component_utils(test_bmd)

    bmd_startup_vseq_c startup_seq;
    bmd_traffic_vseq_c traffic_seq;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        startup_seq = bmd_startup_vseq_c::type_id::create("startup_seq");
        traffic_seq = bmd_traffic_vseq_c::type_id::create("traffic_seq");
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);
        if (get_type_name() != "test_bmd")
            `uvm_info(get_type_name(), $sformatf("Customizing configuration for: %s",
                                            get_type_name()), UVM_MEDIUM)
        // No additional configuration needed - use base class randomization
    endtask

    //--------------------------------------------------------------------------
    // Main Phase - Execute Test
    //--------------------------------------------------------------------------
    virtual task main_phase(uvm_phase phase);
        phase.raise_objection(this, "test_bmd executing");

        `uvm_info(get_type_name(), $sformatf("Starting BMD test: %s", get_type_name()), UVM_LOW)

        // Run startup sequence (reset, capabilities, CSRs, prefixes, start)
        startup_seq.start(env.shim.vsqr);

        // [TPH-FIX-A] Refresh scoreboard config after capability sequences
        // may have adjusted cap_cfg fields based on hardware capabilities.
        // Without this, scoreboards use stale pre-main_phase values.
        // Revert: remove this call and the 3 comment lines above.
        bmd_env.pass_config();

        // Wait for traffic completion with timeout
        traffic_seq.start(env.shim.vsqr);

        `uvm_info(get_type_name(), $sformatf("Completed BMD test: %s", get_type_name()), UVM_LOW)

        phase.drop_objection(this, "test_bmd complete");
    endtask

endclass : test_bmd
