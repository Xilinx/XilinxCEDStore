class cxl_cfgsts_cb extends gpmon_mon_cb#(gpmon_txn);

  `uvm_object_utils(cxl_cfgsts_cb)

  bit          print_always; //0=print only what's changed, 1=print every field
  logic [54:0] last_val;

  function new(string name = "cxl_cfgsts_cb");
    super.new(name);
  endfunction

  // F = field, S = string
  `define check_add_str(F, S) \
    if (last_val[F]!==txn.sig[F] || print_always) \
      txn.ml_sig_enum.push_back(S);

  // S = start, W = width, N = name
  `define check_add_val(S, W, N) \
    if (last_val[S+:W]!==txn.sig[S+:W] || print_always) \
      txn.ml_sig_enum.push_back($sformatf("%0s = %0s'b%0b", N, `"W`", txn.sig[S+:W]));

  virtual function void make_specific(gpmon_txn txn);
    case (txn.sig[0+:2])
      2'h0   : `check_add_str(0+:2, "cxl_flit_mode = 2'b00 (68B Flit)")
      2'h1   : `check_add_str(0+:2, "cxl_flit_mode = 2'b01 (Reserved)")
      2'h2   : `check_add_str(0+:2, "cxl_flit_mode = 2'b10 (Reserved)")
      2'h3   : `check_add_str(0+:2, "cxl_flit_mode = 2'b11 (256B Flit)")
      default: `check_add_str(0+:2, "cxl_flit_mode = 'x or 'z, (Invalid)")
    endcase
    `check_add_val( 2,8,"cxl_error")
    `check_add_val(10,1,"cxl_reset")
    `check_add_val(11,1,"cfg_cxl_dev_cache_en")
    `check_add_val(12,8,"cfg_cxl_dev_mem_en")
    `check_add_val(20,8,"cfg_cxl_dev_cxl_rst_mem_clr_enable")
    `check_add_val(28,1,"cfg_cxl_bi_enable")
    `check_add_val(29,8,"cfg_cxl_dev_initiate_cxl_rst")
    `check_add_val(37,1,"cfg_cxl_dev_disable_caching")
    `check_add_val(38,1,"cfg_cxl_dev_initiate_cache_wr_invld")
    `check_add_val(39,1,"mdh_disable")
    `check_add_val(40,1,"cfg_cxl_io_en")
    `check_add_val(41,1,"cfg_cxl_link_up")
    `check_add_val(42,1,"cxl3_1_emd_enable")
    // Add some type of enumeration to know what the state actually is
    `check_add_val(43,4,"vlsm_mc_state")
    `check_add_val(47,8,"cfg_cxl_mld_hot_rst_active")
    // Save
    last_val = txn.sig;
  endfunction

  `undef check_add_str
  `undef check_add_val

endclass
