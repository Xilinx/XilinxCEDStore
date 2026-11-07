class cfg_ext_api#(type SQR) extends base_api#(SQR);

  `uvm_component_param_utils(cfg_ext_api#(SQR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"cfg_ext_api#(", SQR::type_name, ")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task write(bit [11:0] addr, bit [31:0] data, bit [3:0] be = '1, bit [7:0] fnc = '0);
    cfg_ext_api_seq seq = cfg_ext_api_seq::type_id::create("seq");
    if (addr[1:0] != 2'h0) 
      `uvm_fatal("BAD_API_ARG", "address must be dword aligned for writes, use byte enable")
    seq.wr   = 1'b1;
    seq.addr = addr;
    seq.data = data;
    seq.be   = be;
    seq.fnc  = fnc;
    seq.start(sqr);
  endtask

  virtual task read(bit [11:0] addr, bit [7:0] fnc = '0);
    cfg_ext_api_seq seq = cfg_ext_api_seq::type_id::create("seq");
    if (addr[1:0] != 2'h0) 
      `uvm_fatal("BAD_API_ARG", "address must be dword aligned for reads")
    seq.rd   = 1'b1;
    seq.addr = addr;
    seq.fnc  = fnc;
    seq.start(sqr);
  endtask

endclass
