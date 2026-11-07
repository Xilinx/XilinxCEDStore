class req_cfg extends base_cfg;

  `uvm_object_utils(req_cfg)

  bit           a2f;
  port_t        port;
  bit           cxl_mem_sup;     //"sup" = supported
  bit           cxl_cch_sup;     //"sup" = supported
  bit           cxl_mem_emd_sup; //"sup" = supported
  bit [1:0]     blocking;
  bit           pbr_flit_mode_en;
  bit           flit_mode_enc_en; 
  bit           ide_epoch_support;
  generic_ctl_t crd_ret_ctl;

  // REQ specific
  bit       req_cmd_parity_en;

  // Only relevant to "active Slave" configurations
  bit       skip_credit_returns;
  bit [7:0] init_credit_ded[1:0][15:0]; //dedicated credits; per [protocol] (0:CXL.cache, 1:CXL.mem) and [VC-ID]  
  bit [7:0] init_credit_shr;            //shared credits

  // Only relevant to "master" configurations
  bit       skip_credit_check; 

  function new(string name = "req_cfg");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    req_cfg _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      a2f                 = _rhs.a2f;
      port                = _rhs.port;
      cxl_mem_sup         = _rhs.cxl_mem_sup;
      cxl_cch_sup         = _rhs.cxl_cch_sup;
      cxl_mem_emd_sup     = _rhs.cxl_mem_emd_sup;
      blocking            = _rhs.blocking;
      pbr_flit_mode_en    = _rhs.pbr_flit_mode_en;
      flit_mode_enc_en    = _rhs.flit_mode_enc_en;
      ide_epoch_support   = _rhs.ide_epoch_support;
      crd_ret_ctl         = _rhs.crd_ret_ctl;
      req_cmd_parity_en   = _rhs.req_cmd_parity_en;
      skip_credit_returns = _rhs.skip_credit_returns;
      init_credit_ded     = _rhs.init_credit_ded;
      init_credit_shr     = _rhs.init_credit_shr;
      skip_credit_check   = _rhs.skip_credit_check;
    end
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_int   ("a2f",                 a2f,                 1, UVM_BIN);
    printer.print_string("port",                port.name());
    printer.print_int   ("cxl_mem_sup",         cxl_mem_sup,         1, UVM_BIN);
    printer.print_int   ("cxl_cch_sup",         cxl_cch_sup,         1, UVM_BIN);
    printer.print_int   ("cxl_mem_emd_sup",     cxl_mem_emd_sup,     1, UVM_BIN);
    printer.print_int   ("blocking",            blocking,            2, UVM_BIN);
    printer.print_int   ("pbr_flit_mode_en",    pbr_flit_mode_en,    1, UVM_BIN);
    printer.print_int   ("flit_mode_enc_en",    flit_mode_enc_en,    1, UVM_BIN);
    printer.print_int   ("ide_epoch_support",   ide_epoch_support,   1, UVM_BIN);
    printer.print_string("crd_ret_ctl",         crd_ret_ctl.name());
    printer.print_int   ("req_cmd_parity_en",   req_cmd_parity_en,   1, UVM_BIN);
    printer.print_int   ("skip_credit_returns", skip_credit_returns, 1, UVM_BIN);
    foreach (init_credit_ded[p, v])
      printer.print_int   ($sformatf("init_credit_ded[%0d][%0d]", p, v), init_credit_ded[p][v], 8, UVM_HEX);
    printer.print_int   ("init_credit_shr",     init_credit_shr,     8, UVM_HEX);
    printer.print_int   ("skip_credit_check",   skip_credit_check,   1, UVM_BIN);
  endfunction

endclass

