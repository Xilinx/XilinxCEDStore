class gpdrv_mon_cb#(type TXN) extends uvm_callback;

  `uvm_object_param_utils(gpdrv_mon_cb#(TXN))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"gpdrv_mon_cb#(",
                                   TXN::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name = "gpdrv_mon_cb");
    super.new(name);
  endfunction

  // Take a generic, general purpose transaction, and make it specific
  // by modifying some fields in the transaction so the user can associate
  // it without something instead of just looking at
  virtual function void make_specific(TXN txn); endfunction
endclass

