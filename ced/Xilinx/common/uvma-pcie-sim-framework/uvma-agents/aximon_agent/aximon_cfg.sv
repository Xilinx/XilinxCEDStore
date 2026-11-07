class aximon_cfg extends base_cfg;

  `uvm_object_utils(aximon_cfg)

  // How to report transactions still outstanding at the end of the sim
  typedef enum {
    AXI_RPT_HIDDEN,
    AXI_RPT_INFO,
    AXI_RPT_WARNING,
    AXI_RPT_ERROR
  } aximon_rpt_t;

  // Configurable parameters
  int addr_width;
  int data_width;
  int id_width;
  int awuser_width;
  int aruser_width;
  int ruser_width;
  int wuser_width;
  int buser_width;

  aximon_rpt_t outstanding_rd_rpt;
  aximon_rpt_t outstanding_wr_rpt;

  function new(string name = "aximon_cfg");
    super.new(name);
    // Monitor agent will always have this configuration
    activity  = UVM_PASSIVE;
    component = UVM_SLAVE;
    outstanding_rd_rpt = AXI_RPT_ERROR;
    outstanding_wr_rpt = AXI_RPT_ERROR;
  endfunction

  virtual function void do_copy(uvm_object rhs);
    aximon_cfg _rhs;
    super.do_copy(rhs); 
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      addr_width   = _rhs.addr_width;
      data_width   = _rhs.data_width;
      id_width     = _rhs.id_width;
      awuser_width = _rhs.awuser_width;
      aruser_width = _rhs.aruser_width;
      ruser_width  = _rhs.ruser_width;
      wuser_width  = _rhs.wuser_width;
      buser_width  = _rhs.buser_width;
      outstanding_rd_rpt = _rhs.outstanding_rd_rpt;
      outstanding_wr_rpt = _rhs.outstanding_wr_rpt;
    end
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_int   ("addr_width",   addr_width,   32, UVM_DEC);
    printer.print_int   ("data_width",   data_width,   32, UVM_DEC);
    printer.print_int   ("id_width",     id_width,     32, UVM_DEC);
    printer.print_int   ("awuser_width", awuser_width, 32, UVM_DEC);
    printer.print_int   ("aruser_width", aruser_width, 32, UVM_DEC);
    printer.print_int   ("ruser_width",  ruser_width,  32, UVM_DEC);
    printer.print_int   ("wuser_width",  wuser_width,  32, UVM_DEC);
    printer.print_int   ("buser_width",  buser_width,  32, UVM_DEC);
    printer.print_string("outstanding_rd_rpt", outstanding_rd_rpt.name());
    printer.print_string("outstanding_wr_rpt", outstanding_wr_rpt.name());
  endfunction

endclass
