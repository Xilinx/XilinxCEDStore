class global_api#(type SQR) extends base_api#(SQR);

  `uvm_component_param_utils(global_api#(SQR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"global_api#(", SQR::type_name, ")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task control_ras(bit viral, bit fatal);
    global_api_seq seq = global_api_seq::type_id::create("seq");
    seq.viral = viral;
    seq.fatal = fatal;
    seq.ras   = 1'b1;
    seq.start(sqr);
  endtask

  virtual task control_connection(conn_action_t action);
    global_api_seq seq = global_api_seq::type_id::create("seq");
    seq.txcon_req = action == CONNECT ? 1'b1 : 1'b0; 
    seq.init = 1'b1;
    seq.start(sqr);
  endtask

endclass
