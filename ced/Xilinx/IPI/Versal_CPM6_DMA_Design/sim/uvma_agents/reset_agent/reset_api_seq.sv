class reset_api_seq extends uvm_sequence#(reset_txn);

  `uvm_object_utils(reset_api_seq)

  reset_txn_type_enum  action;
  sync_async_type_enum assert_type;    
  sync_async_type_enum deassert_type;  
  int unsigned         hold_cycles;
  time                 hold_time;

  function new(string name = "reset_api_seq");
    super.new(name);
  endfunction

  virtual task body;
    reset_txn t = reset_txn::type_id::create("t");
    start_item(t);
    t.action        = action;
    t.assert_type   = assert_type;
    t.deassert_type = deassert_type;
    t.hold_cycles   = hold_cycles;
    t.hold_time     = hold_time;
    finish_item(t);
  endtask

endclass
