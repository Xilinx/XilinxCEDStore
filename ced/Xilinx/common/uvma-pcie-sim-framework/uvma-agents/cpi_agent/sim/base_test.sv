class base_test extends uvm_test;

  `uvm_component_utils(base_test)

  test_env env;
  int REQ, DAT, RSP;
  custom_report_server srvr;
  string mst_id, slv_id;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    srvr = new;
    uvm_report_server::set_server(srvr);
    env = test_env::type_id::create("env", this);
    if (!uvm_config_db#(int)::get(this, "", "REQ", REQ))
      `uvm_fatal(get_type_name, "Couldn't get 'REQ' from cfg db")
    if (!uvm_config_db#(int)::get(this, "", "DAT", DAT))
      `uvm_fatal(get_type_name, "Couldn't get 'DAT' from cfg db")
    if (!uvm_config_db#(int)::get(this, "", "RSP", RSP))
      `uvm_fatal(get_type_name, "Couldn't get 'RSP' from cfg db")
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    if (env.mst_cfg.a2f) begin
      mst_id = "agent"; 
      slv_id = "fabric";
    end
    else begin
      mst_id = "fabric";
      slv_id = "agent";
    end
    `uvm_info(get_type_name,$sformatf("TB configured with back-to-back CPI agents emulating %0s %0s", env.mst.cfg.port.name, env.mst.cfg.a2f?"A2F":"F2A"), UVM_NONE)
    `uvm_info(get_type_name,$sformatf("Agent mst emulates '%s' and agent slv emulates '%s'",mst_id,slv_id), UVM_NONE)
    `uvm_info(get_type_name,$sformatf("TB configured with CPI channels: %0d REQ, %0d DAT, %0d RSP", REQ, DAT, RSP), UVM_NONE)
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    // Initiate connection on GLOBAL channel
    env.mst.glbl.api.control_connection(CONNECT);
    wait(env.mst.glbl.shr.conn_state == CONNECTED);
    // Wait until all credits are returned
    env.slv.init_crd_done.wait_on;
    phase.drop_objection(this);
  endtask

  virtual task wait_cycles(int n);
    repeat(n) @(posedge env.mst.vif.clk);
  endtask

endclass
