class msix_user_api_seq extends uvm_sequence#(msix_user_txn);

  `uvm_object_utils(msix_user_api_seq)

  bit [ 2:0] user_func_num;
  bit [ 7:0] user_vfunc_num;
  bit        user_vfunc_active;
  bit        user_req;
  bit [10:0] user_vector_num;
  bit [ 1:0] user_operation;

  function new(string name = "msix_user_api_seq");
    super.new(name);
  endfunction

  virtual task body;
    msix_user_txn t = msix_user_txn::type_id::create("t");
    start_item(t);
    t.user_func_num     = user_func_num;
    t.user_vfunc_num    = user_vfunc_num;
    t.user_vfunc_active = user_vfunc_active;
    t.user_req          = user_req;
    t.user_vector_num   = user_vector_num;
    t.user_operation    = user_operation;
    finish_item(t);
  endtask

endclass
