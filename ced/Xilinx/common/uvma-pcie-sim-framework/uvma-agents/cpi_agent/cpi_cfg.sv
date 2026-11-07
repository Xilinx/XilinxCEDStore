// Note : Users must set the initial credits for responders for each channel
//        before the start_of_simulation phase in that child agent's cfg 
//        object 
class cpi_cfg extends base_cfg;

  `uvm_object_utils(cpi_cfg)

  bit       a2f;
  port_t    port;
  bit       cxl_mem_sup;     //"sup" = supported
  bit       cxl_cch_sup;     //"sup" = supported
  bit       cxl_mem_emd_sup; //"sup" = supported
  bit [1:0] blocking;
  bit       pbr_flit_mode_en;
  bit       flit_mode_enc_en;
  bit       ide_epoch_support;
  bit       skip_credit_returns; //active slave; don't drive
  bit       skip_credit_check; //master; skip api_seq check

  // REQ specific
  bit           req_cmd_parity_en;
  generic_ctl_t req_crd_ret_ctl;
  int           req_compare_addl_txn_info;
  string        req_addl_txn_info[$:4];

  // DATA specific 
  bit [2:0]     data_hdr_sep;
  bit           data_cmd_parity_en;
  bit           data_be_parity_en;
  bit           txfer_32b_en;
  bit           mem_dathdr_split;
  int           emd_bits;
  generic_ctl_t dat_crd_ret_ctl;
  int           dat_compare_addl_txn_info;
  string        dat_addl_txn_info[$:4];

  // RSP specific
  bit           rsp_cmd_parity_en;
  generic_ctl_t rsp_crd_ret_ctl;
  int           rsp_compare_addl_txn_info;
  string        rsp_addl_txn_info[$:4];

  // GLOBAL specific
  bit       viral_en;
  bit       fatal_en;
  bit       skip_glbl_connection;

  function new(string name = "cpi_cfg");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    cpi_cfg _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      this.a2f                       = _rhs.a2f;
      this.port                      = _rhs.port;
      this.cxl_mem_sup               = _rhs.cxl_mem_sup;
      this.cxl_cch_sup               = _rhs.cxl_cch_sup;
      this.cxl_mem_emd_sup           = _rhs.cxl_mem_emd_sup;
      this.blocking                  = _rhs.blocking;
      this.pbr_flit_mode_en          = _rhs.pbr_flit_mode_en;
      this.flit_mode_enc_en          = _rhs.flit_mode_enc_en;
      this.ide_epoch_support         = _rhs.ide_epoch_support;
      this.skip_credit_returns       = _rhs.skip_credit_returns;
      this.skip_credit_check         = _rhs.skip_credit_check;
      this.req_cmd_parity_en         = _rhs.req_cmd_parity_en;
      this.req_crd_ret_ctl           = _rhs.req_crd_ret_ctl;
      this.data_hdr_sep              = _rhs.data_hdr_sep;
      this.data_cmd_parity_en        = _rhs.data_cmd_parity_en;
      this.data_be_parity_en         = _rhs.data_be_parity_en;
      this.emd_bits                  = _rhs.emd_bits;
      this.txfer_32b_en              = _rhs.txfer_32b_en;
      this.mem_dathdr_split          = _rhs.mem_dathdr_split;
      this.dat_crd_ret_ctl           = _rhs.dat_crd_ret_ctl;
      this.rsp_cmd_parity_en         = _rhs.rsp_cmd_parity_en;
      this.rsp_crd_ret_ctl           = _rhs.rsp_crd_ret_ctl;
      this.viral_en                  = _rhs.viral_en;
      this.fatal_en                  = _rhs.fatal_en;
      this.req_compare_addl_txn_info = _rhs.req_compare_addl_txn_info;
      this.req_addl_txn_info         = _rhs.req_addl_txn_info;
      this.dat_compare_addl_txn_info = _rhs.dat_compare_addl_txn_info;
      this.dat_addl_txn_info         = _rhs.dat_addl_txn_info;
      this.rsp_compare_addl_txn_info = _rhs.rsp_compare_addl_txn_info;
      this.rsp_addl_txn_info         = _rhs.rsp_addl_txn_info;
    end
  endfunction

  protected function void print_txn_info(uvm_printer printer, string name, string info[$:4]);
    if (info.size()) begin
      printer.print_array_header(name, info.size(), "queue(string)");
      foreach (info[i])
        printer.print_string($sformatf("[%0d]", i), info[i]);
      printer.print_array_footer();
    end
    else
      printer.print_string(name, "empty queue");
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_int   ("a2f",                       a2f,                        1, UVM_BIN);
    printer.print_string("port",                      port.name());
    printer.print_int   ("cxl_mem_sup",               cxl_mem_sup,                1, UVM_BIN);
    printer.print_int   ("cxl_cch_sup",               cxl_cch_sup,                1, UVM_BIN);
    printer.print_int   ("cxl_mem_emd_sup",           cxl_mem_emd_sup,            1, UVM_BIN);
    printer.print_int   ("blocking",                  blocking,                   2, UVM_BIN);
    printer.print_int   ("pbr_flit_mode_en",          pbr_flit_mode_en,           1, UVM_BIN);
    printer.print_int   ("flit_mode_enc_en",          flit_mode_enc_en,           1, UVM_BIN);
    printer.print_int   ("ide_epoch_support",         ide_epoch_support,          1, UVM_BIN);
    printer.print_int   ("skip_credit_returns",       skip_credit_returns,        1, UVM_BIN);
    printer.print_int   ("skip_credit_check",         skip_credit_check,          1, UVM_BIN);
    printer.print_int   ("req_cmd_parity_en",         req_cmd_parity_en,          1, UVM_BIN);
    printer.print_string("req_crd_ret_ctl",           req_crd_ret_ctl.name());
    printer.print_int   ("req_compare_addl_txn_info", req_compare_addl_txn_info, 32, UVM_DEC);
    print_txn_info(printer, "req_addl_txn_info", req_addl_txn_info);
    printer.print_int   ("data_hdr_sep",              data_hdr_sep,               3, UVM_BIN);
    printer.print_int   ("data_cmd_parity_en",        data_cmd_parity_en,         1, UVM_BIN);
    printer.print_int   ("data_be_parity_en",         data_be_parity_en,          1, UVM_BIN);
    printer.print_int   ("txfer_32b_en",              txfer_32b_en,               1, UVM_BIN);
    printer.print_int   ("mem_dathdr_split",          mem_dathdr_split,           1, UVM_BIN);
    printer.print_int   ("emd_bits",                  emd_bits,                  32, UVM_DEC);
    printer.print_string("dat_crd_ret_ctl",           dat_crd_ret_ctl.name());
    printer.print_int   ("dat_compare_addl_txn_info", dat_compare_addl_txn_info, 32, UVM_DEC);
    print_txn_info(printer, "dat_addl_txn_info", dat_addl_txn_info);
    printer.print_int   ("rsp_cmd_parity_en",         rsp_cmd_parity_en,          1, UVM_BIN);
    printer.print_string("rsp_crd_ret_ctl",           rsp_crd_ret_ctl.name());
    printer.print_int   ("rsp_compare_addl_txn_info", rsp_compare_addl_txn_info, 32, UVM_DEC);
    print_txn_info(printer, "rsp_addl_txn_info", rsp_addl_txn_info);
    printer.print_int   ("viral_en",                  viral_en,                   1, UVM_BIN);
    printer.print_int   ("fatal_en",                  fatal_en,                   1, UVM_BIN);
    printer.print_int   ("skip_glbl_connection",      skip_glbl_connection,       1, UVM_BIN);
  endfunction

endclass
