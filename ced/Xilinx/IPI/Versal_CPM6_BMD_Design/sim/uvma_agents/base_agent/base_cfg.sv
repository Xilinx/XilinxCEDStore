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

  // Helper functions
  virtual function bit is_master (); return (component==UVM_MASTER); endfunction
  virtual function bit is_slave  (); return (component==UVM_SLAVE);  endfunction
  virtual function bit is_active (); return (activity==UVM_ACTIVE);  endfunction
  virtual function bit is_passive(); return (activity==UVM_PASSIVE); endfunction

endclass
