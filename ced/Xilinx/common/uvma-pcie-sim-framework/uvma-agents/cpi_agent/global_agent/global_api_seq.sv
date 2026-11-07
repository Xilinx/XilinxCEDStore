class global_api_seq extends uvm_sequence#(global_txn);

  `uvm_object_utils(global_api_seq)

  bit init;
  bit ras;

  bit txcon_req;
  bit fatal;
  bit viral;

  function new(string name = "global_api_seq");
    super.new(name);
  endfunction

  virtual task body;
    global_txn t = global_txn::type_id::create("t");
    start_item(t);
    t.init      = init;
    t.ras       = ras;
    t.txcon_req = txcon_req;
    t.fatal     = fatal;
    t.viral     = viral;
    finish_item(t);
  endtask

endclass
