// - Base Cfg Class
// - Gives users the option to create masters and slaves (passive or active) 
//   with a unique id; controls agent components and connections 
class base_cfg extends uvm_object;

  `uvm_object_utils(base_cfg)

  uvm_active_passive_enum activity  = UVM_ACTIVE;
  uvm_master_slave_enum   component = UVM_MASTER; 

  string uid;
  bit    append_uid; //to txn_type for txn printing

  bit    disable_api;
  bit    disable_mon_ap_connect;
  bit    disable_mon_baseap_connect;

  int    compare_addl_txn_info;
  string addl_txn_info[$:4]; //max of 4

  function new(string name = "base_cfg");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    base_cfg _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      activity                   = _rhs.activity;
      component                  = _rhs.component;
      uid                        = _rhs.uid;
      append_uid                 = _rhs.append_uid;
      disable_api                = _rhs.disable_api;
      disable_mon_ap_connect     = _rhs.disable_mon_ap_connect;
      disable_mon_baseap_connect = _rhs.disable_mon_baseap_connect;
      compare_addl_txn_info      = _rhs.compare_addl_txn_info;
      addl_txn_info              = _rhs.addl_txn_info;
    end
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_string("activity",  activity.name());
    printer.print_string("component", component.name());
    if (uid != "")
      printer.print_string("uid",                      uid);
    printer.print_int   ("append_uid",                 append_uid,                  1, UVM_BIN);
    printer.print_int   ("disable_api",                disable_api,                 1, UVM_BIN);
    printer.print_int   ("disable_mon_ap_connect",     disable_mon_ap_connect,      1, UVM_BIN);
    printer.print_int   ("disable_mon_baseap_connect", disable_mon_baseap_connect,  1, UVM_BIN);
    printer.print_int   ("compare_addl_txn_info",      compare_addl_txn_info,      32, UVM_DEC);
    if (addl_txn_info.size) begin
      printer.print_array_header("addl_txn_info", addl_txn_info.size(), "queue(string)");
      foreach (addl_txn_info[i])
        printer.print_string($sformatf("[%0d]", i), addl_txn_info[i]);
      printer.print_array_footer();
    end
    else
      printer.print_string("addl_txn_info", "empty queue");
  endfunction

  // Helper functions
  virtual function bit is_master (); return (component==UVM_MASTER); endfunction
  virtual function bit is_slave  (); return (component==UVM_SLAVE);  endfunction
  virtual function bit is_active (); return (activity==UVM_ACTIVE);  endfunction
  virtual function bit is_passive(); return (activity==UVM_PASSIVE); endfunction

endclass
