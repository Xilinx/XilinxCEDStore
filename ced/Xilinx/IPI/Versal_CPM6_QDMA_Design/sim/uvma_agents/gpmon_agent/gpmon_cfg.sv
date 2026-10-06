class gpmon_cfg extends base_cfg;

  `uvm_object_utils(gpmon_cfg)

  int unsigned   width;
  sync_async_t   sync_control = SYNC;
  uvm_radix_enum print_radix  = UVM_HEX;
  bit            print_value  = 1'b1; 
  bit            drop_first;

  function new(string name = "gpmon_cfg");
    super.new(name);
    // Monitor agent will always have this configuration
    activity  = UVM_PASSIVE;
    component = UVM_SLAVE;
  endfunction

  virtual function void do_copy(uvm_object rhs);
    gpmon_cfg _rhs;
    super.do_copy(rhs); 
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      width        = _rhs.width;
      sync_control = _rhs.sync_control;
      print_radix  = _rhs.print_radix;
      drop_first   = _rhs.drop_first;
    end
  endfunction

endclass
