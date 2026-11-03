class gpdrv_cfg extends base_cfg;

  `uvm_object_utils(gpdrv_cfg)

  int unsigned   width;
  bit [63:0]     init_val;
  sync_async_t   sync_control = SYNC;
  uvm_radix_enum print_radix  = UVM_HEX;

  function new(string name = "gpdrv_cfg");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    gpdrv_cfg _rhs;
    super.do_copy(rhs); 
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      width        = _rhs.width;
      init_val     = _rhs.init_val;
      sync_control = _rhs.sync_control;
      print_radix  = _rhs.print_radix;
    end
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_int   ("width",        width,    32, UVM_DEC);
    printer.print_int   ("init_val",     init_val, 64, UVM_HEX);
    printer.print_string("sync_control", sync_control.name());
    printer.print_string("print_radix",  print_radix.name());
  endfunction

endclass
