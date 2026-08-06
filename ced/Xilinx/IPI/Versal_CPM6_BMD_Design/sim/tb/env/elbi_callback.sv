class elbi_callback extends uvm_callback;

  `uvm_object_utils(elbi_callback)

  function new(string name = "elbi_callback");
    super.new(name);
  endfunction

  virtual function void  enter_cb(elbi_txn t); endfunction
  virtual function void middle_cb(elbi_txn t); endfunction
  virtual function void   exit_cb(elbi_txn t); endfunction

endclass
