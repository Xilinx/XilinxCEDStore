/* DESCRIPTION
 * This class exists to complete enumeration of the bus; after which the user
 * should run test-specific behavior.
|*/
class test_enum extends test_init;

  `uvm_component_utils(test_enum)

  seq_enum bus_enum = seq_enum::type_id::create("bus_enum");

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task configure_phase(uvm_phase phase);

    super.configure_phase(phase);
    phase.raise_objection(this);

`ifdef CPM6_RTL
    // Make sure PL demux has been set by now
    if (!demux_sel_vif.set)
      `uvm_fatal(get_type_name, "You must call 'demux_sel_vif.set_use_case(<arg>)' by this point");
`endif

    // callback
    pre_enum_seq(); 
    // Assign some convenience objects
    bus_enum.env_cfg = env_cfg;
    bus_enum.env     = env;
    bus_enum.dut_cfg = dut_cfg;
    bus_enum.vip_cfg = vip_cfg;
    // Run enumeration sequence
    bus_enum.start(env.shim.vsqr);
    // callback
    post_enum_seq(); 

    phase.drop_objection(this);
  endtask

  // Provide some callbacks for extended classes (tasks; can consume time)
  virtual task pre_enum_seq(); endtask
  virtual task post_enum_seq(); endtask

endclass
