class gpdrv_api#(type SQR) extends base_api#(SQR);

  `uvm_component_param_utils(gpdrv_api#(SQR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"gpdrv_api#(", SQR::type_name,")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task drive(logic [63:0] sig);
    gpdrv_api_seq seq = gpdrv_api_seq::type_id::create("seq");
    seq.sig = sig;
    seq.start(sqr);
  endtask

endclass
