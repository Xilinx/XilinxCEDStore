class cxl_nfi_cfg extends base_cfg;

  `uvm_object_utils(cxl_nfi_cfg)

  dir_t              dir;         //H2C, C2H
  flit_mode_t        flitmode;    //UNSPEC, F68, F256, F256_LOPT, FPBR
  bit                right_align;
  int                nfi_width;     //match i/f parameter N
  bit                cxl_cch_sup;   //"sup" = supported
  bit                cxl_mem_sup;   //"sup" = supported
  bit                cxl_membi_sup; //"sup" = supported
  bit                mdh_disable;
  int                emd_bits;      //bits of ext. metadata to support 

  // Affects driver/monitor
  bit                disable_final_txn_reporting;
  bit                disable_tight_pack_check;
  bit                valid_only_mode;
  bit                enable_responder_seq;

  // Affects broadcasting txns out analysis ports
  bit                remove_tl_assembler_comp;

  // Controls API randomization
  bit                split_32B_disable;

  /* Only relevant for ACTIVE MASTER */
  bit                skip_link_init; 
  bit                return_crds;
  bit                return_crds_in_flit; //F68: LLCRD/inFLIT, else inFLIT
  bit                drive_dec_assts;

  // Only relevant to a slave, which should send these out of cred_ret_ap
  // when with txn.info="init" when ready
  int init_req_credit[1:0]; //[protocol]
  int init_dat_credit[1:0]; //[protocol]
  int init_rsp_credit[1:0]; //[protocol]

  function new(string name = "cxl_nfi_cfg");
    super.new(name);
  endfunction 

  virtual function void do_copy(uvm_object rhs);
    cxl_nfi_cfg _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "do_copy got an object that wasn't extended from cxl_nfi_cfg")
    else begin
      dir                         = _rhs.dir;
      flitmode                    = _rhs.flitmode;
      right_align                 = _rhs.right_align;
      nfi_width                   = _rhs.nfi_width;
      cxl_cch_sup                 = _rhs.cxl_cch_sup;
      cxl_mem_sup                 = _rhs.cxl_mem_sup;
      cxl_membi_sup               = _rhs.cxl_membi_sup;
      mdh_disable                 = _rhs.mdh_disable;
      emd_bits                    = _rhs.emd_bits;
      disable_final_txn_reporting = _rhs.disable_final_txn_reporting;
      disable_tight_pack_check    = _rhs.disable_tight_pack_check;
      valid_only_mode             = _rhs.valid_only_mode;
      enable_responder_seq        = _rhs.enable_responder_seq;
      remove_tl_assembler_comp    = _rhs.remove_tl_assembler_comp;
      split_32B_disable           = _rhs.split_32B_disable;
      skip_link_init              = _rhs.skip_link_init;
      return_crds                 = _rhs.return_crds;
      return_crds_in_flit         = _rhs.return_crds_in_flit;
      drive_dec_assts             = _rhs.drive_dec_assts;
      init_req_credit             = _rhs.init_req_credit;
      init_dat_credit             = _rhs.init_dat_credit;
      init_rsp_credit             = _rhs.init_rsp_credit;
    end
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_string("dir",                         dir.name());
    printer.print_string("flitmode",                    flitmode.name());
    printer.print_int   ("right_align",                 right_align,                  1, UVM_BIN);
    printer.print_int   ("nfi_width",                   nfi_width,                   32, UVM_DEC);
    printer.print_int   ("cxl_cch_sup",                 cxl_cch_sup,                  1, UVM_BIN);
    printer.print_int   ("cxl_mem_sup",                 cxl_mem_sup,                  1, UVM_BIN);
    printer.print_int   ("cxl_membi_sup",               cxl_membi_sup,                1, UVM_BIN);
    printer.print_int   ("mdh_disable",                 mdh_disable,                  1, UVM_BIN);
    printer.print_int   ("emd_bits",                    emd_bits,                    32, UVM_DEC);
    printer.print_int   ("disable_final_txn_reporting", disable_final_txn_reporting,  1, UVM_BIN);
    printer.print_int   ("disable_tight_pack_check",    disable_tight_pack_check,     1, UVM_BIN);
    printer.print_int   ("valid_only_mode",             valid_only_mode,              1, UVM_BIN);
    printer.print_int   ("enable_responder_seq",        enable_responder_seq,         1, UVM_BIN);
    printer.print_int   ("remove_tl_assembler_comp",    remove_tl_assembler_comp,     1, UVM_BIN);
    printer.print_int   ("split_32B_disable",           split_32B_disable,            1, UVM_BIN);
    printer.print_int   ("skip_link_init",              skip_link_init,               1, UVM_BIN);
    printer.print_int   ("return_crds",                 return_crds,                  1, UVM_BIN);
    printer.print_int   ("return_crds_in_flit",         return_crds_in_flit,          1, UVM_BIN);
    printer.print_int   ("drive_dec_assts",             drive_dec_assts,              1, UVM_BIN);
    foreach (init_req_credit[i])
      printer.print_int   ($sformatf("init_req_credit[%0d]", i), init_req_credit[i], 32, UVM_DEC);
    foreach (init_dat_credit[i])
      printer.print_int   ($sformatf("init_dat_credit[%0d]", i), init_dat_credit[i], 32, UVM_DEC);
    foreach (init_rsp_credit[i])
      printer.print_int   ($sformatf("init_rsp_credit[%0d]", i), init_rsp_credit[i], 32, UVM_DEC);
  endfunction

endclass
