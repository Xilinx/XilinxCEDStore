class msix_user_api#(type SQR) extends base_api#(SQR);

  `uvm_component_param_utils(msix_user_api#(SQR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"msix_user_api#(", SQR::type_name,")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task drive(bit [2:0] pf, logic [7:0] vf='x, bit [10:0] vec, msix_op_e op);
    msix_user_api_seq seq = msix_user_api_seq::type_id::create("seq");
    seq.user_func_num     = pf;
    seq.user_vfunc_num    = vf;
    seq.user_vfunc_active = (vf!=='x);
    seq.user_req          = 1'b1;
    seq.user_vector_num   = vec;
    seq.user_operation    = op;
    seq.start(sqr);
  endtask

endclass
