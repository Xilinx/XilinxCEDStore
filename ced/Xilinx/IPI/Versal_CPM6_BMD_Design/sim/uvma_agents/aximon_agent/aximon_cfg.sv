class aximon_cfg extends base_cfg;

  `uvm_object_utils(aximon_cfg)

  // Configurable parameters
  int addr_width;
  int data_width;
  int id_width;
  int awuser_width;
  int aruser_width;
  int ruser_width;
  int wuser_width;
  int buser_width;

  function new(string name = "aximon_cfg");
    super.new(name);
    // Monitor agent will always have this configuration
    activity  = UVM_PASSIVE;
    component = UVM_SLAVE;
  endfunction

  virtual function void do_copy(uvm_object rhs);
    aximon_cfg _rhs;
    super.do_copy(rhs); 
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else

    addr_width   = _rhs.addr_width;
    data_width   = _rhs.data_width;
    id_width     = _rhs.id_width;
    awuser_width = _rhs.awuser_width;
    aruser_width = _rhs.aruser_width;
    ruser_width  = _rhs.ruser_width;
    wuser_width  = _rhs.wuser_width;
    buser_width  = _rhs.buser_width;
  endfunction
endclass
