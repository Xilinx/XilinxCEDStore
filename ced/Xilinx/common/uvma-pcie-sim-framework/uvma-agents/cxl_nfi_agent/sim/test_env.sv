class test_env extends uvm_env;

  `uvm_component_utils(test_env)

  typedef virtual cxl_nfi_agent_if #(N) t_vif;

  t_vif h2c_mst_vif, h2c_slv_vif;
  t_vif c2h_mst_vif, c2h_slv_vif;

  cxl_nfi_cfg h2c_mst_cfg, h2c_slv_cfg;
  cxl_nfi_cfg c2h_mst_cfg, c2h_slv_cfg;

  cxl_nfi_agent #(N) h2c_mst, h2c_slv;
  cxl_nfi_agent #(N) c2h_mst, c2h_slv;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    h2c_mst_cfg = cxl_nfi_cfg::type_id::create("h2c_mst_cfg");
    h2c_mst_cfg.valid_only_mode          = 1'b0;
    h2c_mst_cfg.dir                      = H2C;
    h2c_mst_cfg.flitmode                 = MODE;
    h2c_mst_cfg.nfi_width                = N;
    h2c_mst_cfg.cxl_cch_sup              = 1;
    h2c_mst_cfg.cxl_mem_sup              = 1;
    h2c_mst_cfg.skip_link_init           = 0;
    h2c_mst_cfg.drive_dec_assts          = 1;
    h2c_mst_cfg.disable_tight_pack_check = 1;
    h2c_mst_cfg.return_crds              = 1;
    h2c_mst_cfg.return_crds_in_flit      = 0;
    $cast(h2c_slv_cfg, h2c_mst_cfg.clone);
    h2c_mst_cfg.remove_tl_assembler_comp = 1'b1;
    h2c_slv_cfg.component                = UVM_SLAVE;

    c2h_mst_cfg = cxl_nfi_cfg::type_id::create("c2h_mst_cfg");
    c2h_mst_cfg.valid_only_mode          = 1'b0;
    c2h_mst_cfg.dir                      = C2H;
    c2h_mst_cfg.flitmode                 = MODE;
    c2h_mst_cfg.nfi_width                = N;
    c2h_mst_cfg.cxl_cch_sup              = 1;
    c2h_mst_cfg.cxl_mem_sup              = 1;
    c2h_mst_cfg.skip_link_init           = 0;
    c2h_mst_cfg.drive_dec_assts          = 1;
    c2h_mst_cfg.disable_tight_pack_check = 1;
    c2h_mst_cfg.return_crds              = 1;
    c2h_mst_cfg.return_crds_in_flit      = 0;
    $cast(c2h_slv_cfg, c2h_mst_cfg.clone);
    c2h_mst_cfg.remove_tl_assembler_comp = 1'b1;
    c2h_slv_cfg.component                = UVM_SLAVE;

    if (!uvm_config_db#(t_vif)::get(this, "", "v_h2c_mst_if", h2c_mst_vif))
      `uvm_fatal(get_type_name, "Couldn't get 'v_h2c_mst_if' from cfg db")
    if (!uvm_config_db#(t_vif)::get(this, "", "v_h2c_slv_if", h2c_slv_vif))
      `uvm_fatal(get_type_name, "Couldn't get 'v_h2c_slv_if' from cfg db")
    if (!uvm_config_db#(t_vif)::get(this, "", "v_c2h_mst_if", c2h_mst_vif))
      `uvm_fatal(get_type_name, "Couldn't get 'v_c2h_mst_if' from cfg db")
    if (!uvm_config_db#(t_vif)::get(this, "", "v_c2h_slv_if", c2h_slv_vif))
      `uvm_fatal(get_type_name, "Couldn't get 'v_c2h_slv_if' from cfg db")

    h2c_mst = cxl_nfi_agent_creator#(N)::spawn("h2c_mst", this, h2c_mst_vif, h2c_mst_cfg); 
    h2c_slv = cxl_nfi_agent_creator#(N)::spawn("h2c_slv", this, h2c_slv_vif, h2c_slv_cfg); 
    c2h_mst = cxl_nfi_agent_creator#(N)::spawn("c2h_mst", this, c2h_mst_vif, c2h_mst_cfg); 
    c2h_slv = cxl_nfi_agent_creator#(N)::spawn("c2h_slv", this, c2h_slv_vif, c2h_slv_cfg); 

  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Slave has some amount of credits, it "gives" them to the local master so
    // so the master may give them across the link to the other side. It gives 
    // master init credits and also gives master the credits that link partner 
    // has consumed by sending transactions.
    h2c_slv.cred_give_ap.connect(c2h_mst.impl_give);
    c2h_slv.cred_give_ap.connect(h2c_mst.impl_give);
    // The local master will give them to the remote master either natively 
    // through flits or just by sending out its analysis port.
    c2h_mst.cred_ret_ap.connect(h2c_mst.impl_avl);
    h2c_mst.cred_ret_ap.connect(c2h_mst.impl_avl);
    // The local master will notify local slave that it has sent the remote
    // master the credits so the slave agent can check it hasn't overflowed.
    // This is a bit circular, but in a back-to-back agent case, this makes
    // sense because this is a contrived example.
    c2h_mst.cred_ret_ap.connect(h2c_slv.impl_avl);
    h2c_mst.cred_ret_ap.connect(c2h_slv.impl_avl);
  endfunction

  virtual function void start_of_simulation_phase(uvm_phase phase);
    // Set backpressure
    h2c_slv.slv_seq.backpressure_ctl = LOW;
    c2h_slv.slv_seq.backpressure_ctl = LOW;
    /* Give the slave agents some initial credits */
    h2c_slv.cfg.init_req_credit[MEM] = 144;             h2c_slv.cfg.init_req_credit[CCH] = 144;
    h2c_slv.cfg.init_dat_credit[MEM] = 144;             h2c_slv.cfg.init_dat_credit[CCH] = 144;
    h2c_slv.cfg.init_rsp_credit[MEM] = (MODE!=F68)*144; h2c_slv.cfg.init_rsp_credit[CCH] = 144;
    // --- // 
    c2h_slv.cfg.init_req_credit[MEM] = (MODE!=F68)*160; c2h_slv.cfg.init_req_credit[CCH] = 160;
    c2h_slv.cfg.init_dat_credit[MEM] = 160;             c2h_slv.cfg.init_dat_credit[CCH] = 160;
    c2h_slv.cfg.init_rsp_credit[MEM] = 160;             c2h_slv.cfg.init_rsp_credit[CCH] = 160;
  endfunction

endclass
