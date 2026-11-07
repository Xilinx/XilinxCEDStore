class global_cfg extends base_cfg;

  `uvm_object_utils(global_cfg)

  bit a2f;

  // GLOBAL specific
  bit viral_en;
  bit fatal_en;
  bit skip_glbl_connection;

  function new(string name = "global_cfg");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    global_cfg _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      a2f                  = _rhs.a2f;
      viral_en             = _rhs.viral_en;
      fatal_en             = _rhs.fatal_en;
      skip_glbl_connection = _rhs.skip_glbl_connection;
    end
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_int   ("a2f",                  a2f,                  1, UVM_BIN);
    printer.print_int   ("viral_en",             viral_en,             1, UVM_BIN);
    printer.print_int   ("fatal_en",             fatal_en,             1, UVM_BIN);
    printer.print_int   ("skip_glbl_connection", skip_glbl_connection, 1, UVM_BIN);
  endfunction

endclass
