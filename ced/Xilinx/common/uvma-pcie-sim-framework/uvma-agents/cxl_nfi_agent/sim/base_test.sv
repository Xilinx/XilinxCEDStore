class base_test extends uvm_test;

  `uvm_component_utils(base_test)

  // Components
  test_env env;
  custom_report_server srvr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    srvr = new;
    uvm_report_server::set_server(srvr);
    env = test_env::type_id::create("env", this);
    `uvm_info("TSTINFO", $sformatf("TB configured with NFI_WIDTH = %0d and MODE = %0s",N,MODE.name), UVM_NONE)
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    // Tell slave agents to give the credits to the local masters 
    #100ns;
    fork
      env.c2h_slv.txfer_init_credits();
      env.h2c_slv.txfer_init_credits();
    join
    #100ns;
    phase.drop_objection(this);
  endtask

endclass
