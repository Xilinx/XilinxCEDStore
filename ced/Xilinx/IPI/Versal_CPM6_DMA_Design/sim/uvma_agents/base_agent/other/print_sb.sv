// Not really a scoreboard by the typically definition, this will
// just print transactions as they come in.
class print_sb#(type TXN = base_txn) extends uvm_subscriber#(TXN);

  `uvm_component_param_utils(print_sb#(TXN))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"print_sb#(",
                                   TXN::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void write(T t);
    t.stamp;
    `uvm_info(get_type_name, {"Got txn: \n", t.sprint}, UVM_MEDIUM)
  endfunction

endclass

