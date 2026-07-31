class tb_env extends uvm_env;

  `uvm_component_utils(tb_env)

  typedef gpmon_monitor#(gpmon_cfg, virtual gpmon_if, gpmon_txn) gpmon_mon_t;

  //pl_isr=connected to 3 PL IRQ pins
  `uvm_analysis_imp_decl(_pl_isr)
  uvm_analysis_imp_pl_isr#(gpmon_txn, tb_env) impl_pl_isr;
  uvm_event pl_isr_event;
  //ps_isr=connected to 3 PS IRQ pins
  `uvm_analysis_imp_decl(_ps_isr)
  uvm_analysis_imp_ps_isr#(gpmon_txn, tb_env) impl_ps_isr;
  uvm_event ps_isr_event;
  //fm="flit mode"
  `uvm_analysis_imp_decl(_cxl_fm)
  uvm_analysis_imp_cxl_fm#(gpmon_txn, tb_env) impl_cxl_fm;
  //elbi="ELBI interface"
  `uvm_analysis_imp_decl(_elbi)
  uvm_analysis_imp_elbi#(elbi_txn, tb_env) impl_elbi;
  `uvm_register_cb(tb_env, elbi_callback)

  // summarized from object
  protected bit isr_used;
  protected bit elbi_used;
  protected bit cxl_cfgsts_used;
  protected bit cxl_pm_out_used;
  protected bit cxl_credit_tx_used;
  protected bit cxl_credit_rx_used;
  protected bit cxl_nfi_rx_used;
  protected bit cxl_nfi_tx_used;

  // the config for this object 
  tb_env_cfg cfg; 

  // wrapper around PCIe VIP
  shim_layer shim;

  // ISR/control
  seq_pl_isr_src   pl_isr_seq;
  seq_ps_isr_src   ps_isr_seq;
  semaphore        pl_sem, ps_sem;
  // Sideband info: grab from cfg db
  int link_width[2];
  bit pipe_sim;

`ifdef CPM6_RTL
  // Generic memory
  svt_mem vip_axi_slv_mem[6]; 
`endif

  // vifs
`ifdef CPM6_RTL
  virtual svt_axi_if          vif_svt_axi;
`endif
  virtual reset_if            vif_ps_axi_reset;
  virtual reset_if            vif_lpd_por_n;
  virtual reset_if            vif_perstn    [0:1];
  virtual gpmon_if            vif_cxl_pm_out[0:1];
  virtual gpmon_if            vif_cxl_cfgsts[0:1];
  virtual cxl_credit_agent_if vif_cxl_crd_tx[0:1];
  virtual cxl_credit_agent_if vif_cxl_crd_rx[0:1];
  virtual cxl_nfi_agent_if    vif_cxl_nfi_tx[0:1];
  virtual cxl_nfi_agent_if    vif_cxl_nfi_rx[0:1];
  virtual elbi_if             vif_elbi      [0:1];
  virtual gpmon_if            vif_cpm_ps_isr;
  virtual gpmon_if            vif_cpm_pl_isr;
`ifdef CPM6_VIVADO
  virtual aximon_if           vif_cpm_pl_axi[4];
  virtual aximon_if           vif_cpm_noc_axi[2];
`endif

  // agents
`ifdef CPM6_RTL
  svt_axi_system_env axi_env; //wrapper of all AXI agents
`else
  aximon_agent       cpm_pl_axi_agnt[4];
  aximon_agent       cpm_noc_axi_agnt[2];
`endif
  reset_agent        ps_axi_reset_agnt;
  reset_agent        perstn_agnt[0:1];
  reset_agent        lpd_por_n_agnt;
  gpmon_agent        cxl_cfgsts_agnt[0:1];
  gpmon_agent        cxl_pm_out_agnt[0:1];
  cxl_nfi_agent      cxl_nfi_agnt_tx[0:1];
  cxl_nfi_agent      cxl_nfi_agnt_rx[0:1];
  cxl_credit_agent   cxl_credit_agnt_tx[0:1]; 
  cxl_credit_agent   cxl_credit_agnt_rx[0:1]; 
  elbi_agent         elbi_agnt[0:1];
  gpmon_agent        ps_isr_agnt;
  gpmon_agent        pl_isr_agnt;

  // vsqr
`ifdef CPM6_VIVADO
  ps_vip_vsequencer         ps_vip_vsqr;
`endif

  // callbacks
  cxl_cfgsts_cb gpmon_cb_cxl_cfgsts;
  cxl_pm_out_cb gpmon_cb_cxl_pm_out;
  isr_cb        gpmon_cb_isr;

  // cfg
`ifdef CPM6_RTL
  svt_axi_system_configuration axi_cfg;
`endif
  reset_cfg                    lpd_por_n_cfg;
  reset_cfg                    ps_axi_reset_cfg;
  reset_cfg                    perstn_cfg    [0:1];
  cxl_nfi_cfg                  cxl_nfi_cfg_tx[0:1];
  cxl_nfi_cfg                  cxl_nfi_cfg_rx[0:1];
  elbi_cfg                     pl_elbi_cfg   [0:1];

  // scoreboards
  print_sb                     base_printer;
  print_sb #(elbi_txn)         elbi_printer;

  // other
  cxl_credit_shim              cxl_crd_shim[0:1];

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    string id;
    super.build_phase(phase);
    /* Sidebands from cfg db */
    if (!uvm_config_db#(int)::get(this, "", "LINK0_WIDTH", link_width[0]))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'LINK0_WIDTH' from cfg db")
    if (!uvm_config_db#(int)::get(this, "", "LINK1_WIDTH", link_width[1]))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'LINK1_WIDTH' from cfg db")
    if (!uvm_config_db#(int)::get(this, "", "PIPE_SIM", pipe_sim))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'PIPE_SIM' from cfg db")
    /* env config; get from cfg db if it exists, else create it */
    if (!uvm_config_db#(tb_env_cfg)::get(this, "", "env_cfg", cfg)) begin
      `uvm_info("CFGDB_NOGET", "Could not get 'env_cfg' from cfg db, creating it", UVM_NONE)
      cfg = tb_env_cfg::type_id::create("cfg", this);
    end
    else begin
      `uvm_info("CFGDB_GOT", "Got 'env_cfg' from cfg db, using it directly", UVM_NONE)
    end
    cfg.print;
    // summarize the options into these protected bits
    isr_used           = |{cfg.pl_isr_agnt!=UNUSED_AGNT,           cfg.ps_isr_agnt!=UNUSED_AGNT};
    elbi_used          = |{cfg.elbi_agnt[0]!=UNUSED_AGNT,          cfg.elbi_agnt[1]!=UNUSED_AGNT};
    cxl_cfgsts_used    = |{cfg.cxl_cfgsts_agnt[0]!=UNUSED_AGNT,    cfg.cxl_cfgsts_agnt[1]!=UNUSED_AGNT};
    cxl_pm_out_used    = |{cfg.cxl_pm_out_agnt[0]!=UNUSED_AGNT,    cfg.cxl_pm_out_agnt[1]!=UNUSED_AGNT};
    cxl_credit_tx_used = |{cfg.cxl_credit_agnt_tx[0]!=UNUSED_AGNT, cfg.cxl_credit_agnt_tx[1]!=UNUSED_AGNT};
    cxl_credit_rx_used = |{cfg.cxl_credit_agnt_rx[0]!=UNUSED_AGNT, cfg.cxl_credit_agnt_rx[1]!=UNUSED_AGNT};
    cxl_nfi_tx_used    = |{cfg.cxl_nfi_agnt_tx[0]!=UNUSED_AGNT,    cfg.cxl_nfi_agnt_tx[1]!=UNUSED_AGNT};
    cxl_nfi_rx_used    = |{cfg.cxl_nfi_agnt_rx[0]!=UNUSED_AGNT,    cfg.cxl_nfi_agnt_rx[1]!=UNUSED_AGNT};
    /* Create child wrapper objects */
    shim = shim_layer::type_id::create("shim", this);
    shim.link_width = link_width;
    shim.pipe_sim   = pipe_sim;
    /* agent vifs from cfg db */
    if (!uvm_config_db#(virtual reset_if)::get(this, "", "lpd_por_n_vif", vif_lpd_por_n))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'lpd_por_n_vif' from cfg db")
`ifdef CPM6_RTL
    if (!uvm_config_db#(virtual reset_if)::get(this, "", "ps_axi_reset_vif", vif_ps_axi_reset))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'ps_axi_reset_vif' from cfg db")
    if (!uvm_config_db#(virtual svt_axi_if)::get(this, "", "svt_axi_vif", vif_svt_axi))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'svt_axi_vif' from cfg db")
`endif
    if (!uvm_config_db#(virtual gpmon_if)::get(this, "", "vif_cpm_pl_isr", vif_cpm_pl_isr))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'vif_cpm_pl_isr' from cfg db")
    if (!uvm_config_db#(virtual gpmon_if)::get(this, "", "vif_cpm_ps_isr", vif_cpm_ps_isr))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'vif_cpm_ps_isr' from cfg db")
`ifdef CPM6_VIVADO
    for (int ii=0; ii<4; ii++) begin
      if (!uvm_config_db#(virtual aximon_if)::get(this, "", $sformatf("cpm_pl_axi_if[%0d]", ii), vif_cpm_pl_axi[ii]))
        `uvm_fatal("CFGDB_NOGET", $sformatf("Could not get 'cpm_pl_axi_if[%0d]' from cfg db", ii))
    end
    for (int ii=0; ii<2; ii++) begin
      if (!uvm_config_db#(virtual aximon_if)::get(this, "", $sformatf("cpm_noc_axi_if[%0d]", ii), vif_cpm_noc_axi[ii]))
        `uvm_fatal("CFGDB_NOGET", $sformatf("Could not get 'cpm_noc_axi_if[%0d]' from cfg db", ii))
    end
`endif
    // per-controller vifs
    for (int ii=0; ii<2; ii++) begin
      if (!uvm_config_db#(virtual reset_if)::get(this, "", $sformatf("vif_perstn[%0d]",ii), vif_perstn[ii]))
        `uvm_fatal("CFGDB_NOGET", $sformatf("Could not get 'vif_perstn[%0d]' from cfg db",ii))
      if (cfg.elbi_agnt[ii] != UNUSED_AGNT)
        if (!uvm_config_db#(virtual elbi_if)::get(this, "", $sformatf("vif_elbi[%0d]",ii), vif_elbi[ii]))
          `uvm_fatal("CFGDB_NOGET", $sformatf("Could not get 'vif_elbi[%0d]' from cfg db",ii))
      if (cfg.cxl_cfgsts_agnt[ii] != UNUSED_AGNT)
        if (!uvm_config_db#(virtual gpmon_if)::get(this, "", $sformatf("vif_cxl_cfgsts[%0d]",ii), vif_cxl_cfgsts[ii]))
          `uvm_fatal("CFGDB_NOGET", $sformatf("Could not get 'vif_cxl_cfgsts[%0d]' from cfg db",ii))
      if (cfg.cxl_pm_out_agnt[ii] != UNUSED_AGNT)
        if (!uvm_config_db#(virtual gpmon_if)::get(this, "", $sformatf("vif_cxl_pm_out[%0d]",ii), vif_cxl_pm_out[ii]))
          `uvm_fatal("CFGDB_NOGET", $sformatf("Could not get 'vif_cxl_pm_out[%0d]' from cfg db",ii))
      if (cfg.cxl_nfi_agnt_tx[ii] != UNUSED_AGNT)
        if (!uvm_config_db#(virtual cxl_nfi_agent_if)::get(this, "", $sformatf("vif_cxl_tx_nfi[%0d]",ii), vif_cxl_nfi_tx[ii]))
          `uvm_fatal("CFGDB_NOGET", $sformatf("Could not get 'vif_cxl_tx_nfi[%0d]' from cfg db",ii))
      if (cfg.cxl_nfi_agnt_rx[ii] != UNUSED_AGNT)
        if (!uvm_config_db#(virtual cxl_nfi_agent_if)::get(this, "", $sformatf("vif_cxl_rx_nfi[%0d]",ii), vif_cxl_nfi_rx[ii]))
          `uvm_fatal("CFGDB_NOGET", $sformatf("Could not get 'vif_cxl_rx_nfi[%0d]' from cfg db",ii))
      if (cfg.cxl_credit_agnt_tx[ii] != UNUSED_AGNT)
        if (!uvm_config_db#(virtual cxl_credit_agent_if)::get(this, "", $sformatf("vif_cxl_tx_crd[%0d]",ii), vif_cxl_crd_tx[ii]))
          `uvm_fatal("CFGDB_NOGET", $sformatf("Could not get 'vif_cxl_tx_crd[%0d]' from cfg db",ii))
      if (cfg.cxl_credit_agnt_rx[ii] != UNUSED_AGNT)
        if (!uvm_config_db#(virtual cxl_credit_agent_if)::get(this, "", $sformatf("vif_cxl_rx_crd[%0d]",ii), vif_cxl_crd_rx[ii]))
          `uvm_fatal("CFGDB_NOGET", $sformatf("Could not get 'vif_cxl_rx_crd[%0d]' from cfg db",ii))
    end
    /* cfgs */
`ifdef CPM6_RTL
    ps_axi_reset_cfg = reset_cfg::type_id::create("ps_axi_reset_cfg", this);
    ps_axi_reset_cfg.uid     = "PS_AXI_ARESETN";
    ps_axi_reset_cfg.has_clk = 1'b0;
    lpd_por_n_cfg = reset_cfg::type_id::create("lpd_por_n_cfg", this);
    lpd_por_n_cfg.uid     = "LPD_POR_N";
    lpd_por_n_cfg.has_clk = 1'b0;
`endif
    perstn_cfg[0] = reset_cfg::type_id::create("perstn_cfg[0]", this);
    perstn_cfg[0].uid     = "PERSTN[0]";
    perstn_cfg[0].has_clk = 1'b0;
    $cast(perstn_cfg[1], perstn_cfg[0].clone);
    perstn_cfg[1].uid     = "PERSTN[1]";
    for (int ii=0; ii<2; ii++) begin
      if (cfg.cxl_nfi_agnt_tx[ii] != UNUSED_AGNT) begin
        cxl_nfi_cfg_tx[ii] = cxl_nfi_cfg::type_id::create($sformatf("cxl_nfi_cfg_tx[%0d]",ii));
        cxl_nfi_cfg_tx[ii].uid                 = $sformatf("CXL Tx[%0d]",ii);
        cxl_nfi_cfg_tx[ii].component           = UVM_MASTER;
        cxl_nfi_cfg_tx[ii].activity            = cfg.cxl_nfi_agnt_tx[ii]==ACTIVE_AGNT ? UVM_ACTIVE : UVM_PASSIVE;
        cxl_nfi_cfg_tx[ii].dir                 = C2H;
        cxl_nfi_cfg_tx[ii].right_align         = 1'b1;
        cxl_nfi_cfg_tx[ii].nfi_width           = 3;
        cxl_nfi_cfg_tx[ii].addl_txn_info.push_back("Sends toward link");
      end
      // --- //
      if (cfg.cxl_nfi_agnt_rx[ii] != UNUSED_AGNT) begin
        if (cfg.cxl_nfi_agnt_rx[ii]==ACTIVE_AGNT)
          `uvm_warning(get_type_name(), $sformatf("cfg.cxl_nfi_agnt_rx[%0d] needn't be active because it has no driven signals to DUT",ii))
        cxl_nfi_cfg_rx[ii] = cxl_nfi_cfg::type_id::create($sformatf("cxl_nfi_cfg_rx[%0d]",ii));
        cxl_nfi_cfg_rx[ii].uid             = $sformatf("CXL Rx[%0d]",ii);
        cxl_nfi_cfg_rx[ii].component       = UVM_SLAVE;
        cxl_nfi_cfg_rx[ii].activity        = UVM_PASSIVE;
        cxl_nfi_cfg_rx[ii].dir             = H2C;
        cxl_nfi_cfg_rx[ii].right_align     = 1'b1;
        cxl_nfi_cfg_rx[ii].nfi_width       = 3;
        cxl_nfi_cfg_rx[ii].addl_txn_info.push_back("Receives from link");
      end
      // --- //
      if (cfg.elbi_agnt[ii] != UNUSED_AGNT) begin
        pl_elbi_cfg[ii] = elbi_cfg::type_id::create($sformatf("pl_elbi_cfg[%0d]", ii));
        pl_elbi_cfg[ii].activity   = cfg.elbi_agnt[ii]==ACTIVE_AGNT ? UVM_ACTIVE : UVM_PASSIVE;
        pl_elbi_cfg[ii].component  = UVM_SLAVE;
        pl_elbi_cfg[ii].uid        = $sformatf("ELBI[%0d]",ii);
      end
    end
`ifdef CPM6_RTL
    // * all axi cfg * //
    // - notes
    //   1. the CPM6 NoC routing is complex and controlled by aperture control
    //      registers in many cases
    //   2. there are also translation units to remap address spaces 
    axi_cfg = svt_axi_system_configuration::type_id::create("axi_cfg", this);
    // - general options
    axi_cfg.system_monitor_enable  = 0;
    axi_cfg.display_summary_report = 0;
    axi_cfg.common_clock_mode      = 0;
    // - master options (so many knobs available)
    axi_cfg.num_masters = 5;
    //   - Master 0
    //     - Can only access 0xFC00_0000->0xFCFF_FFFF (16 MB)
    axi_cfg.master_cfg[M_AXIMM_PS_CFG].set_port_name("M_AXIMM_PS_CFG");
    axi_cfg.master_cfg[M_AXIMM_PS_CFG].axi_interface_type = svt_axi_port_configuration::AXI4;
    axi_cfg.master_cfg[M_AXIMM_PS_CFG].initialize_output_signals_at_start = 1; //0 at t=0, not z
    axi_cfg.master_cfg[M_AXIMM_PS_CFG].is_active   = cfg.axi_mst_agnt[M_AXIMM_PS_CFG]==ACTIVE_AGNT;
    axi_cfg.master_cfg[M_AXIMM_PS_CFG].aruser_enable    = 1;    //added for PS_NoC                                                                                                                                
    axi_cfg.master_cfg[M_AXIMM_PS_CFG].awuser_enable    = 1;    //added for PS_NoC
    axi_cfg.master_cfg[M_AXIMM_PS_CFG].data_width  = 32;
    axi_cfg.master_cfg[M_AXIMM_PS_CFG].silent_mode = 1; //0->TxnInfo=UVM_LOW, 1->TxnInfo=UVM_HIGH
    //   - Master 1
    //     - Can access any of the below regions when configured
    //     - Region 1: 0xE000_0000->0xEFFF_FFFF (256 MB)
    //     - Region 2: 0x6_0000_0000->0x7_FFFF_FFFF (8 GB)
    //     - Region 3: 0x80_0000_0000->0xBF_FFFF_FFFF (256 GB)
    axi_cfg.master_cfg[M_AXIMM_PS_128].set_port_name("M_AXIMM_PS_128");
    axi_cfg.master_cfg[M_AXIMM_PS_128].axi_interface_type = svt_axi_port_configuration::AXI4;
    axi_cfg.master_cfg[M_AXIMM_PS_128].initialize_output_signals_at_start = 1; //0 at t=0, not z
    axi_cfg.master_cfg[M_AXIMM_PS_128].is_active   = cfg.axi_mst_agnt[M_AXIMM_PS_128]==ACTIVE_AGNT;
    axi_cfg.master_cfg[M_AXIMM_PS_128].data_width       = 128;
    axi_cfg.master_cfg[M_AXIMM_PS_128].aruser_enable = 1; // For changing user width 
    axi_cfg.master_cfg[M_AXIMM_PS_128].awuser_enable = 1; // For changing user width 
    axi_cfg.master_cfg[M_AXIMM_PS_128].wuser_enable  = 1; // For changing user width 
    axi_cfg.master_cfg[M_AXIMM_PS_128].silent_mode = 1; //0->TxnInfo=UVM_LOW, 1->TxnInfo=UVM_HIGH
    axi_cfg.master_cfg[M_AXIMM_PS_128].awregion_enable = 1; // For changing user width 
    axi_cfg.master_cfg[M_AXIMM_PS_128].arregion_enable = 1; // For changing user width 
    //   - Master 2
    //     - Can only access 0xFC00_0000->0xFCFF_FFFF (16 MB)
    axi_cfg.master_cfg[M_AXIL_PL_DBI0].set_port_name("M_AXIL_PL_DBI0");
    axi_cfg.master_cfg[M_AXIL_PL_DBI0].axi_interface_type = svt_axi_port_configuration::AXI4_LITE;
    axi_cfg.master_cfg[M_AXIL_PL_DBI0].initialize_output_signals_at_start = 1; //0 at t=0, not z
    axi_cfg.master_cfg[M_AXIL_PL_DBI0].is_active   = cfg.axi_mst_agnt[M_AXIL_PL_DBI0]==ACTIVE_AGNT;
    axi_cfg.master_cfg[M_AXIL_PL_DBI0].data_width  = 32;
    axi_cfg.master_cfg[M_AXIL_PL_DBI0].silent_mode = 1; //0->TxnInfo=UVM_LOW, 1->TxnInfo=UVM_HIGH
    //   - Master 3
    //     - Can only access 0xFC00_0000->0xFCFF_FFFF (16 MB)
    axi_cfg.master_cfg[M_AXIL_PL_DBI1].set_port_name("M_AXIL_PL_DBI1");
    axi_cfg.master_cfg[M_AXIL_PL_DBI1].axi_interface_type = svt_axi_port_configuration::AXI4_LITE;
    axi_cfg.master_cfg[M_AXIL_PL_DBI1].initialize_output_signals_at_start = 1; //0 at t=0, not z
    axi_cfg.master_cfg[M_AXIL_PL_DBI1].is_active   = cfg.axi_mst_agnt[M_AXIL_PL_DBI1]==ACTIVE_AGNT;
    axi_cfg.master_cfg[M_AXIL_PL_DBI1].data_width  = 32;
    axi_cfg.master_cfg[M_AXIL_PL_DBI1].silent_mode = 1; //0->TxnInfo=UVM_LOW, 1->TxnInfo=UVM_HIGH
    //   - Master 4
    //     - Can access any of the below regions when configured
    //     - Region 1: 0xE000_0000->0xEFFF_FFFF (256 MB)
    //     - Region 2: 0x6_0000_0000->0x7_FFFF_FFFF (8 GB)
    //     - Region 3: 0x80_0000_0000->0xBF_FFFF_FFFF (256 GB)
    axi_cfg.master_cfg[M_AXIMM_PL_512].set_port_name("M_AXIMM_PL_512");
    axi_cfg.master_cfg[M_AXIMM_PL_512].axi_interface_type = svt_axi_port_configuration::AXI4;
    axi_cfg.master_cfg[M_AXIMM_PL_512].initialize_output_signals_at_start = 1; //0 at t=0, not z
    axi_cfg.master_cfg[M_AXIMM_PL_512].is_active   = cfg.axi_mst_agnt[M_AXIMM_PL_512]==ACTIVE_AGNT;
    axi_cfg.master_cfg[M_AXIMM_PL_512].data_width  = 512;
    axi_cfg.master_cfg[M_AXIMM_PL_512].silent_mode = 1; //0->TxnInfo=UVM_LOW, 1->TxnInfo=UVM_HIGH
    // - slave options (so many knobs available)
    axi_cfg.num_slaves = 6;
    axi_cfg.set_addr_range(S_AXIMM_PS0_128, '0, '1); //all addresses valid
    axi_cfg.set_addr_range(S_AXIMM_PS1_128, '0, '1); //all addresses valid
    axi_cfg.set_addr_range(S_AXIMM_PL0_512, '0, '1); //all addresses valid
    axi_cfg.set_addr_range(S_AXIMM_PL1_512, '0, '1); //all addresses valid
    axi_cfg.set_addr_range(S_AXIMM_PL2_512, '0, '1); //all addresses valid
    axi_cfg.set_addr_range(S_AXIMM_PL3_512, '0, '1); //all addresses valid
    //   - Slave 0
    axi_cfg.slave_cfg[S_AXIMM_PS0_128].set_port_name("S_AXIMM_PS0_128");
    axi_cfg.slave_cfg[S_AXIMM_PS0_128].axi_interface_type = svt_axi_port_configuration::AXI4;
    axi_cfg.slave_cfg[S_AXIMM_PS0_128].initialize_output_signals_at_start = 1; //0 at t=0, not z
    axi_cfg.slave_cfg[S_AXIMM_PS0_128].is_active   = cfg.axi_slv_agnt[S_AXIMM_PS0_128]==ACTIVE_AGNT;
    axi_cfg.slave_cfg[S_AXIMM_PS0_128].data_width  = 128;
    axi_cfg.slave_cfg[S_AXIMM_PS0_128].silent_mode = 1; //0->TxnInfo=UVM_LOW, 1->TxnInfo=UVM_HIGH
    //     -> Create a memory associated with the slave, configure it, pass the handle down to slv agent
    vip_axi_slv_mem[S_AXIMM_PS0_128] = new(.name("PS0_128"),
                                           .suite_name(""), //?
                                           .data_wdth(axi_cfg.slave_cfg[S_AXIMM_PS0_128].data_width),
                                           .addr_region(0), //?
                                           .min_addr('0), 
                                           .max_addr('1));
    uvm_config_db#(svt_mem)::set(this, $sformatf("axi_env.slave[%0d]",S_AXIMM_PS0_128), 
                                 "axi_slave_mem", 
                                 vip_axi_slv_mem[S_AXIMM_PS0_128]);
    //   - Slave 1
    axi_cfg.slave_cfg[S_AXIMM_PS1_128].set_port_name("S_AXIMM_PS1_128");
    axi_cfg.slave_cfg[S_AXIMM_PS1_128].axi_interface_type = svt_axi_port_configuration::AXI4;
    axi_cfg.slave_cfg[S_AXIMM_PS1_128].initialize_output_signals_at_start = 1; //0 at t=0, not z
    axi_cfg.slave_cfg[S_AXIMM_PS1_128].is_active   = cfg.axi_slv_agnt[S_AXIMM_PS1_128]==ACTIVE_AGNT;
    axi_cfg.slave_cfg[S_AXIMM_PS1_128].data_width  = 128;
    axi_cfg.slave_cfg[S_AXIMM_PS1_128].silent_mode = 1; //0->TxnInfo=UVM_LOW, 1->TxnInfo=UVM_HIGH
    //     -> Create a memory associated with the slave, configure it, pass the handle down to slv agent
    vip_axi_slv_mem[S_AXIMM_PS1_128] = new(.name("PS1_128"),
                                           .suite_name(""), //?
                                           .data_wdth(axi_cfg.slave_cfg[S_AXIMM_PS1_128].data_width),
                                           .addr_region(0), //?
                                           .min_addr('0), 
                                           .max_addr('1));
    uvm_config_db#(svt_mem)::set(this, $sformatf("axi_env.slave[%0d]",S_AXIMM_PS1_128), 
                                 "axi_slave_mem", 
                                 vip_axi_slv_mem[S_AXIMM_PS1_128]);
    //   - Slave 2
    axi_cfg.slave_cfg[S_AXIMM_PL0_512].set_port_name("S_AXIMM_PL0_512");
    axi_cfg.slave_cfg[S_AXIMM_PL0_512].axi_interface_type = svt_axi_port_configuration::AXI4;
    axi_cfg.slave_cfg[S_AXIMM_PL0_512].initialize_output_signals_at_start = 1; //0 at t=0, not z
    axi_cfg.slave_cfg[S_AXIMM_PL0_512].is_active   = cfg.axi_slv_agnt[S_AXIMM_PL0_512]==ACTIVE_AGNT;
    axi_cfg.slave_cfg[S_AXIMM_PL0_512].data_width  = 512;
    axi_cfg.slave_cfg[S_AXIMM_PL0_512].silent_mode = 1; //0->TxnInfo=UVM_LOW, 1->TxnInfo=UVM_HIGH
    //     -> Create a memory associated with the slave, configure it, pass the handle down to slv agent
    vip_axi_slv_mem[S_AXIMM_PL0_512] = new(.name("PL0_512"),
                                           .suite_name(""), //?
                                           .data_wdth(axi_cfg.slave_cfg[S_AXIMM_PL0_512].data_width),
                                           .addr_region(0), //?
                                           .min_addr('0), 
                                           .max_addr('1));
    uvm_config_db#(svt_mem)::set(this, $sformatf("axi_env.slave[%0d]",S_AXIMM_PL0_512), 
                                 "axi_slave_mem", 
                                 vip_axi_slv_mem[S_AXIMM_PL0_512]);
    //   - Slave 3
    axi_cfg.slave_cfg[S_AXIMM_PL1_512].set_port_name("S_AXIMM_PL1_512");
    axi_cfg.slave_cfg[S_AXIMM_PL1_512].axi_interface_type = svt_axi_port_configuration::AXI4;
    axi_cfg.slave_cfg[S_AXIMM_PL1_512].initialize_output_signals_at_start = 1; //0 at t=0, not z
    axi_cfg.slave_cfg[S_AXIMM_PL1_512].is_active   = cfg.axi_slv_agnt[S_AXIMM_PL1_512]==ACTIVE_AGNT;
    axi_cfg.slave_cfg[S_AXIMM_PL1_512].data_width  = 512;
    axi_cfg.slave_cfg[S_AXIMM_PL1_512].silent_mode = 1; //0->TxnInfo=UVM_LOW, 1->TxnInfo=UVM_HIGH
    //     -> Create a memory associated with the slave, configure it, pass the handle down to slv agent
    vip_axi_slv_mem[S_AXIMM_PL1_512] = new(.name("PL1_512"),
                                           .suite_name(""), //?
                                           .data_wdth(axi_cfg.slave_cfg[S_AXIMM_PL1_512].data_width),
                                           .addr_region(0), //?
                                           .min_addr('0), 
                                           .max_addr('1));
    uvm_config_db#(svt_mem)::set(this, $sformatf("axi_env.slave[%0d]",S_AXIMM_PL1_512), 
                                 "axi_slave_mem", 
                                 vip_axi_slv_mem[S_AXIMM_PL1_512]);
    //   - Slave 4
    axi_cfg.slave_cfg[S_AXIMM_PL2_512].set_port_name("S_AXIMM_PL2_512");
    axi_cfg.slave_cfg[S_AXIMM_PL2_512].axi_interface_type = svt_axi_port_configuration::AXI4;
    axi_cfg.slave_cfg[S_AXIMM_PL2_512].initialize_output_signals_at_start = 1; //0 at t=0, not z
    axi_cfg.slave_cfg[S_AXIMM_PL2_512].is_active   = cfg.axi_slv_agnt[S_AXIMM_PL2_512]==ACTIVE_AGNT;
    axi_cfg.slave_cfg[S_AXIMM_PL2_512].data_width  = 512;
    axi_cfg.slave_cfg[S_AXIMM_PL2_512].silent_mode = 1; //0->TxnInfo=UVM_LOW, 1->TxnInfo=UVM_HIGH
    //     -> Create a memory associated with the slave, configure it, pass the handle down to slv agent
    vip_axi_slv_mem[S_AXIMM_PL2_512] = new(.name("PL2_512"),
                                           .suite_name(""), //?
                                           .data_wdth(axi_cfg.slave_cfg[S_AXIMM_PL2_512].data_width),
                                           .addr_region(0), //?
                                           .min_addr('0), 
                                           .max_addr('1));
    uvm_config_db#(svt_mem)::set(this, $sformatf("axi_env.slave[%0d]",S_AXIMM_PL2_512), 
                                 "axi_slave_mem", 
                                 vip_axi_slv_mem[S_AXIMM_PL2_512]);
    //   - Slave 5
    axi_cfg.slave_cfg[S_AXIMM_PL3_512].set_port_name("S_AXIMM_PL3_512");
    axi_cfg.slave_cfg[S_AXIMM_PL3_512].axi_interface_type = svt_axi_port_configuration::AXI4;
    axi_cfg.slave_cfg[S_AXIMM_PL3_512].initialize_output_signals_at_start = 1; //0 at t=0, not z
    axi_cfg.slave_cfg[S_AXIMM_PL3_512].is_active   = cfg.axi_slv_agnt[S_AXIMM_PL3_512]==ACTIVE_AGNT;
    axi_cfg.slave_cfg[S_AXIMM_PL3_512].data_width  = 512;
    axi_cfg.slave_cfg[S_AXIMM_PL3_512].silent_mode = 1; //0->TxnInfo=UVM_LOW, 1->TxnInfo=UVM_HIGH
    //     -> Create a memory associated with the slave, configure it, pass the handle down to slv agent
    vip_axi_slv_mem[S_AXIMM_PL3_512] = new(.name("PL3_512"),
                                           .suite_name(""), //?
                                           .data_wdth(axi_cfg.slave_cfg[S_AXIMM_PL3_512].data_width),
                                           .addr_region(0), //?
                                           .min_addr('0), 
                                           .max_addr('1));
    uvm_config_db#(svt_mem)::set(this, $sformatf("axi_env.slave[%0d]",S_AXIMM_PL3_512), 
                                 "axi_slave_mem", 
                                 vip_axi_slv_mem[S_AXIMM_PL3_512]);
    // - interface handle passing
    axi_cfg.set_if(vif_svt_axi);
    /* create agent objects */
    axi_env           = svt_axi_system_env::type_id::create("axi_env", this);
    ps_axi_reset_agnt = reset_agent_creator#()::spawn("ps_axi_reset_agnt", this, vif_ps_axi_reset, ps_axi_reset_cfg);
`endif
`ifdef CPM6_VIVADO
    /* vsqr */
    ps_vip_vsqr = ps_vip_vsequencer::type_id::create("ps_vip_vsqr", this);
`endif
    lpd_por_n_agnt    = reset_agent_creator#()::spawn("lpd_por_n_agnt",    this, vif_lpd_por_n,    lpd_por_n_cfg);
    // --- //
    if (cfg.ps_isr_agnt != UNUSED_AGNT) begin
      ps_isr_agnt                 = gpmon_agent_creator#()::spawn("ps_isr_agnt", this, vif_cpm_ps_isr);
      ps_isr_agnt.cfg.width       = 3; //{corr, uncorr, misc}
      ps_isr_agnt.cfg.uid         = "PS_ISR";
      ps_isr_agnt.cfg.print_radix = UVM_BIN;
      // event
      ps_isr_event = new("ps_isr_event");
      // impl port
      impl_ps_isr = new("impl_ps_isr", this);
    end
    // --- //
    if (cfg.pl_isr_agnt != UNUSED_AGNT) begin
      pl_isr_agnt                 = gpmon_agent_creator#()::spawn("pl_isr_agnt", this, vif_cpm_pl_isr);
      pl_isr_agnt.cfg.width       = 3; //{corr, uncorr, misc}
      pl_isr_agnt.cfg.uid         = "PL_ISR";
      pl_isr_agnt.cfg.print_radix = UVM_BIN;
      // event
      pl_isr_event = new("pl_isr_event");
      // impl port
      impl_pl_isr = new("impl_pl_isr", this);
    end
`ifdef CPM6_VIVADO
    for (int ii=0; ii<4; ii++) begin
      if (cfg.cpm_pl_axi_agnt[ii] != UNUSED_AGNT) begin
        cpm_pl_axi_agnt[ii] = aximon_agent_creator#()::spawn($sformatf("cpm_pl_axi_agnt[%0d]",ii), this, vif_cpm_pl_axi[ii]);

        cpm_pl_axi_agnt[ii].cfg.addr_width   = 51;
        cpm_pl_axi_agnt[ii].cfg.data_width   = 512;
        cpm_pl_axi_agnt[ii].cfg.id_width     = 10;
        cpm_pl_axi_agnt[ii].cfg.awuser_width = 147;
        cpm_pl_axi_agnt[ii].cfg.aruser_width = 56;
        cpm_pl_axi_agnt[ii].cfg.ruser_width  = 68;
        cpm_pl_axi_agnt[ii].cfg.wuser_width  = 64;
        cpm_pl_axi_agnt[ii].cfg.buser_width  = 3;
      end
    end
    for (int ii=0; ii<2; ii++) begin
      if(cfg.cpm_noc_axi_agnt[ii] != UNUSED_AGNT) begin
        cpm_noc_axi_agnt[ii] = aximon_agent_creator#()::spawn($sformatf("cpm_noc_axi_agnt[%0d]",ii), this, vif_cpm_noc_axi[ii]);

        cpm_noc_axi_agnt[ii].cfg.addr_width   = 64;
        cpm_noc_axi_agnt[ii].cfg.data_width   = 128;
        cpm_noc_axi_agnt[ii].cfg.id_width     = 16;
        cpm_noc_axi_agnt[ii].cfg.awuser_width = 32;
        cpm_noc_axi_agnt[ii].cfg.aruser_width = 32;
        cpm_noc_axi_agnt[ii].cfg.ruser_width  = 18;
        cpm_noc_axi_agnt[ii].cfg.wuser_width  = 18;
        cpm_noc_axi_agnt[ii].cfg.buser_width  = 1;
      end
    end
`endif
    // implementation ports
    if (cxl_cfgsts_used) impl_cxl_fm = new("impl_cxl_fm", this);
    if (elbi_used)       impl_elbi   = new("impl_elbi", this);
    // per-controller agents
    for (int ii=0; ii<2; ii++) begin
      perstn_agnt[ii] = reset_agent_creator#()::spawn($sformatf("perstn_agnt[%0d]",ii), 
                                                      this, 
                                                      vif_perstn[ii], 
                                                      perstn_cfg[ii]);
      if (cfg.cxl_cfgsts_agnt[ii] != UNUSED_AGNT) begin
        if (cfg.cxl_cfgsts_agnt[ii]==ACTIVE_AGNT)
          `uvm_warning(get_type_name(), $sformatf("cfg.cxl_cfgsts_agnt[%0d] needn't be active because it has no driven signals to DUT",ii))
        cxl_cfgsts_agnt[ii] = gpmon_agent_creator#()::spawn($sformatf("cxl_cfgsts_agnt[%0d]",ii), 
                                                            this,
                                                            vif_cxl_cfgsts[ii]);
        cxl_cfgsts_agnt[ii].cfg.width = 55;
        cxl_cfgsts_agnt[ii].cfg.uid   = $sformatf("CXL Cfg/Sts[%0d]",ii);
        cxl_cfgsts_agnt[ii].cfg.print_value = 1'b0;
      end
      // --- //
      if (cfg.cxl_pm_out_agnt[ii] != UNUSED_AGNT) begin
        if (cfg.cxl_pm_out_agnt[ii]==ACTIVE_AGNT)
          `uvm_warning(get_type_name(), $sformatf("cfg.cxl_pm_out_agnt[%0d] needn't be active because it has no driven signals to DUT",ii))
        cxl_pm_out_agnt[ii] = gpmon_agent_creator#()::spawn($sformatf("cxl_pm_out_agnt[%0d]",ii), 
                                                            this,
                                                            vif_cxl_pm_out[ii]);
        cxl_pm_out_agnt[ii].cfg.width = 33;
        cxl_pm_out_agnt[ii].cfg.uid = $sformatf("CXL PM Out[%0d]",ii);
      end
      // --- //
      if (cfg.cxl_credit_agnt_tx[ii] != UNUSED_AGNT) begin
        cxl_credit_agnt_tx[ii] = cxl_credit_agent_creator::spawn($sformatf("cxl_credit_agnt_tx[%0d]",ii),
                                                                 this,
                                                                 vif_cxl_crd_tx[ii]);
        cxl_credit_agnt_tx[ii].cfg.uid                 = $sformatf("Tx Credit[%0d]",ii);
        cxl_credit_agnt_tx[ii].cfg.mst_use_credit_pool = 1'b1;
        cxl_credit_agnt_tx[ii].cfg.activity            = cfg.cxl_credit_agnt_tx[ii]==ACTIVE_AGNT ? UVM_ACTIVE : UVM_PASSIVE;
        cxl_credit_agnt_tx[ii].cfg.component           = UVM_MASTER;
        cxl_credit_agnt_tx[ii].cfg.addl_txn_info.push_back("Local credits available");
      end
      // --- //
      if (cfg.cxl_credit_agnt_rx[ii] != UNUSED_AGNT) begin
        if (cfg.cxl_credit_agnt_rx[ii]==ACTIVE_AGNT)
          `uvm_warning(get_type_name(), $sformatf("cfg.cxl_credit_agnt_rx[%0d] needn't be active because it has no driven signals to DUT",ii))
        cxl_credit_agnt_rx[ii] = cxl_credit_agent_creator::spawn($sformatf("cxl_credit_agnt_rx[%0d]",ii),
                                                                 this,
                                                                 vif_cxl_crd_rx[ii]);
        cxl_credit_agnt_rx[ii].cfg.uid        = $sformatf("Rx Credit[%0d]",ii);
        cxl_credit_agnt_rx[ii].cfg.activity   = UVM_PASSIVE;
        cxl_credit_agnt_rx[ii].cfg.component  = UVM_SLAVE;
        cxl_credit_agnt_rx[ii].cfg.addl_txn_info.push_back("Remote credits available");
      end
      // --- //
      if (cfg.cxl_nfi_agnt_tx[ii] != UNUSED_AGNT) begin
        cxl_nfi_agnt_tx[ii] = cxl_nfi_agent_creator#()::spawn($sformatf("cxl_nfi_agnt_tx[%0d]",ii),
                                                              this,
                                                              vif_cxl_nfi_tx[ii],
                                                              cxl_nfi_cfg_tx[ii]);
      end
      // --- //
      if (cfg.cxl_nfi_agnt_rx[ii] != UNUSED_AGNT) begin
        cxl_nfi_agnt_rx[ii] = cxl_nfi_agent_creator#()::spawn($sformatf("cxl_nfi_agnt_rx[%0d]",ii),
                                                              this,
                                                              vif_cxl_nfi_rx[ii],
                                                              cxl_nfi_cfg_rx[ii]);
      end
      // --- //
      if (cfg.elbi_agnt[ii] != UNUSED_AGNT) begin
        elbi_agnt[ii] = elbi_agent_creator::spawn($sformatf("elbi_agnt[%0d]",ii),
                                                  this,
                                                  vif_elbi[ii],
                                                  pl_elbi_cfg[ii]);
      end
      // --- //
      // Other
      // --- //
      cxl_crd_shim[ii] = cxl_credit_shim::type_id::create($sformatf("cxl_crd_shim[%0d]",ii), this);
    end
`ifdef CPM6_RTL
    // pass AXI system config down to AXI system wrapper
    uvm_config_db#(svt_axi_system_configuration)::set(this, "axi_env", "cfg", axi_cfg);
`endif
    // callbacks for gpmon
    if (cxl_cfgsts_used) gpmon_cb_cxl_cfgsts = cxl_cfgsts_cb::type_id::create("gpmon_cb_cxl_cfgsts");
    if (cxl_pm_out_used) gpmon_cb_cxl_pm_out = cxl_pm_out_cb::type_id::create("gpmon_cb_cxl_pm_out");
    if (isr_used)        gpmon_cb_isr        = isr_cb       ::type_id::create("gpmon_cb_isr");
    // scoreboards
    base_printer = print_sb#()::type_id::create("base_printer", this);
    if (elbi_used) elbi_printer = print_sb#(elbi_txn)::type_id::create("elbi_printer", this);
  endfunction 

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
`ifdef CPM6_RTL 
    shim.vsqr.axi_env     = axi_env;
`else
    shim.vsqr.ps_vip_vsqr = ps_vip_vsqr;
`endif
    // Callbacks; single instance
    if (cfg.pl_isr_agnt != UNUSED_AGNT) begin
      uvm_callbacks#(gpmon_mon_t, isr_cb)::add(pl_isr_agnt.mon, gpmon_cb_isr); 
      pl_isr_agnt.ap.connect(impl_pl_isr);
    end
    if (cfg.ps_isr_agnt != UNUSED_AGNT) begin
      uvm_callbacks#(gpmon_mon_t, isr_cb)::add(ps_isr_agnt.mon, gpmon_cb_isr); 
      ps_isr_agnt.ap.connect(impl_ps_isr);
    end
    // Callbacks; per controller
    for (int ii=0; ii<2; ii++) begin
      // Add callbacks for GPMONs
      if (cfg.cxl_cfgsts_agnt[ii]!=UNUSED_AGNT)
        uvm_callbacks#(gpmon_mon_t, cxl_cfgsts_cb)::add(cxl_cfgsts_agnt[ii].mon, gpmon_cb_cxl_cfgsts); 
      if (cfg.cxl_pm_out_agnt[ii]!=UNUSED_AGNT)
        uvm_callbacks#(gpmon_mon_t, cxl_pm_out_cb)::add(cxl_pm_out_agnt[ii].mon, gpmon_cb_cxl_pm_out); 
      if (&{cfg.cxl_nfi_agnt_tx[ii]!=UNUSED_AGNT, cfg.cxl_nfi_agnt_rx[ii]!=UNUSED_AGNT}) begin
        // CXL inter-master/slave port connections 
        //  - returned/available credits
        cxl_nfi_agnt_tx[ii].cred_ret_ap.connect(cxl_nfi_agnt_rx[ii].impl_avl);
        cxl_nfi_agnt_rx[ii].cred_ret_ap.connect(cxl_nfi_agnt_tx[ii].impl_avl);
        cxl_nfi_agnt_rx[ii].cred_give_ap.connect(cxl_nfi_agnt_tx[ii].impl_give);
        // CXL: return credits using credit agent (optional)
        cxl_nfi_agnt_tx[ii].cred_ret_ap.connect(cxl_crd_shim[ii].impl_nfi2crd);
        cxl_crd_shim[ii].ap_crd.connect(cxl_credit_agnt_tx[ii].impl_pool_bus);
        cxl_credit_agnt_rx[ii].ap.connect(cxl_crd_shim[ii].impl_crd2nfi);
        cxl_credit_agnt_tx[ii].ap.connect(cxl_crd_shim[ii].impl_crd2nfi);
        cxl_crd_shim[ii].ap_nfi_from_tx.connect(cxl_nfi_agnt_rx[ii].impl_avl);
        cxl_crd_shim[ii].ap_nfi_from_rx.connect(cxl_nfi_agnt_tx[ii].impl_avl);
      end
      if (cfg.cxl_cfgsts_agnt[ii]!=UNUSED_AGNT) begin
        // Shim to control CXL agent
        cxl_cfgsts_agnt[ii].ap.connect(impl_cxl_fm);
      end
      if (cfg.elbi_agnt[ii]!=UNUSED_AGNT) begin
        // Shim to give callbacks for external ELBI txns
        elbi_agnt[ii].reqext_ap.connect(impl_elbi);
      end
      // Just print these txns for now; eventually will likely remove some/all these connections
      if (cfg.cxl_nfi_agnt_rx[ii]!=UNUSED_AGNT)
        cxl_nfi_agnt_rx[ii]   .base_tl_ap.connect(base_printer.analysis_export);
      if (cfg.cxl_nfi_agnt_tx[ii]!=UNUSED_AGNT)
        cxl_nfi_agnt_tx[ii]   .base_tl_ap.connect(base_printer.analysis_export);
      if (cfg.cxl_cfgsts_agnt[ii]!=UNUSED_AGNT)
        cxl_cfgsts_agnt[ii]   .base_ap   .connect(base_printer.analysis_export);
      if (cfg.cxl_pm_out_agnt[ii]!=UNUSED_AGNT)
        cxl_pm_out_agnt[ii]   .base_ap   .connect(base_printer.analysis_export);
      if (cfg.pl_isr_agnt!=UNUSED_AGNT)
        pl_isr_agnt           .base_ap   .connect(base_printer.analysis_export);
      if (cfg.ps_isr_agnt!=UNUSED_AGNT)
        ps_isr_agnt           .base_ap   .connect(base_printer.analysis_export);
      if (cfg.cxl_credit_agnt_rx[ii]!=UNUSED_AGNT)
        cxl_credit_agnt_rx[ii].base_ap   .connect(base_printer.analysis_export);
      if (cfg.cxl_credit_agnt_tx[ii]!=UNUSED_AGNT)
        cxl_credit_agnt_tx[ii].base_ap   .connect(base_printer.analysis_export);
      if (cfg.elbi_agnt[ii]!=UNUSED_AGNT) begin
        elbi_agnt[ii]         .reqext_ap .connect(elbi_printer.analysis_export); //only broadcast external requests
        elbi_agnt[ii]         .cmb_ap    .connect(elbi_printer.analysis_export);
      end
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    uvm_object  _pl, _ps; 
    gpmon_txn    pl,  ps;
`ifdef CPM6_RTL
    seq_svt_slv_mem_rsp axi_slv_seq[6];
`endif
    phase.raise_objection(this);
    super.run_phase(phase);
`ifdef CPM6_RTL
    // Kick off AXI slave memory responses, if active
    foreach (cfg.axi_slv_agnt[ii]) begin
      automatic int j = ii;
      fork
        if (cfg.axi_slv_agnt[j]==ACTIVE_AGNT) begin 
          axi_slv_seq[j] = seq_svt_slv_mem_rsp::type_id::create($sformatf("axi_slv_seq[%0d]",j));
          axi_slv_seq[j].start(axi_env.slave[j].sequencer);
        end
      join_none
    end
`endif
    // Kick off ISR loops
    ps_isr_seq = seq_ps_isr_src::type_id::create("ps_isr_seq");
    pl_isr_seq = seq_pl_isr_src::type_id::create("pl_isr_seq");
`ifdef CPM6_RTL
    ps_isr_seq.p_sequencer = axi_env.master[M_AXIMM_PS_CFG].sequencer;
    pl_isr_seq.p_sequencer = axi_env.master[M_AXIMM_PS_CFG].sequencer;
`else
    ps_isr_seq.p_sequencer = ps_vip_vsqr;
    pl_isr_seq.p_sequencer = ps_vip_vsqr;
`endif
    fork
      // trigger loop
      if (cfg.pl_isr_agnt==ACTIVE_AGNT) begin
        pl_sem = new(1);
        forever begin : _pl_isr_trig
          pl_isr_event.wait_trigger_data(_pl);
          $cast(pl, _pl);
           // Rising edge detector
          if (&{!pl_isr_seq.irq[0], pl.sig[0]} ||
              &{!pl_isr_seq.irq[1], pl.sig[1]} ||
              &{!pl_isr_seq.irq[2], pl.sig[2]})
          begin
            pl_isr_seq.irq = pl.sig; 
            pl_sem.get(1);
            `uvm_info(get_type_name(), "PL IRQ interrupt triggered; running sequence to handle", UVM_LOW)
`ifdef CPM6_RTL
            pl_isr_seq.start(axi_env.master[M_AXIMM_PS_CFG].sequencer);
`else
            pl_isr_seq.start(ps_vip_vsqr);
`endif
            pl_sem.put(1);
          end
          else
            pl_isr_seq.irq = pl.sig; 
        end
      end
      // recheck loop
      if (cfg.pl_isr_agnt==ACTIVE_AGNT) begin
        forever begin : pl_isr_loop
          @(pl_isr_seq.seq_done);
          while ($countones(pl_isr_seq.irq)) begin
            #cfg.pl_isr_recheck_time;
            if (pl_sem.try_get(1)) begin
              `uvm_info(get_type_name(), "PL IRQ interrupt re-checking; running sequence to handle", UVM_LOW)
`ifdef CPM6_RTL
              pl_isr_seq.start(axi_env.master[M_AXIMM_PS_CFG].sequencer);
`else
              pl_isr_seq.start(ps_vip_vsqr);
`endif
              pl_sem.put(1);
            end
          end
        end
      end
      // trigger loop
      if (cfg.ps_isr_agnt==ACTIVE_AGNT) begin
        ps_sem = new(1);
        forever begin : _ps_isr_trig
          ps_isr_event.wait_trigger_data(_ps);
          $cast(ps, _ps);
           // Rising edge detector
          if (&{!ps_isr_seq.irq[0], ps.sig[0]} ||
              &{!ps_isr_seq.irq[1], ps.sig[1]} ||
              &{!ps_isr_seq.irq[2], ps.sig[2]})
          begin
            ps_isr_seq.irq = ps.sig; 
            ps_sem.get(1);
            `uvm_info(get_type_name(), "PS IRQ interrupt triggered; running sequence to handle", UVM_LOW)
`ifdef CPM6_RTL
            ps_isr_seq.start(axi_env.master[M_AXIMM_PS_CFG].sequencer);
`else
            ps_isr_seq.start(ps_vip_vsqr);
`endif
            ps_sem.put(1);
          end
          else
            ps_isr_seq.irq = ps.sig; 
        end
      end
      // recheck loop
      if (cfg.ps_isr_agnt==ACTIVE_AGNT) begin
        forever begin : ps_isr_loop
          @(ps_isr_seq.seq_done);
          while ($countones(ps_isr_seq.irq)) begin
            #cfg.ps_isr_recheck_time;
            if (ps_sem.try_get(1)) begin
              `uvm_info(get_type_name(), "PS IRQ interrupt re-checking; running sequence to handle", UVM_LOW)
`ifdef CPM6_RTL
              ps_isr_seq.start(axi_env.master[M_AXIMM_PS_CFG].sequencer);
`else
              ps_isr_seq.start(ps_vip_vsqr);
`endif
              ps_sem.put(1);
            end
          end
        end
      end
    join_none
    phase.drop_objection(this);
  endtask

  virtual function void check_phase(uvm_phase phase);
    string msg;
    int    severity;
    if (vif_cpm_ps_isr.sig[2:0] !== '0) begin
      msg = "PS ISR pins are not 0 at end of sim: ";
      msg = {msg, $sformatf("CORR=%b, ",   vif_cpm_ps_isr.sig[2])};
      msg = {msg, $sformatf("UNCORR=%b, ", vif_cpm_ps_isr.sig[1])};
      msg = {msg, $sformatf("MISC=%b",     vif_cpm_ps_isr.sig[0])};
      // an x or z is always an error
      if ($isunknown(vif_cpm_ps_isr.sig[2:0]))
        `uvm_error  ("PS_ISR_FINAL", msg)
      // only need to print if a bit is set that doesn't have "ignore" setting
      else if (&{vif_cpm_ps_isr.sig[0], cfg.ps_isr_final[0]!=3} ||
               &{vif_cpm_ps_isr.sig[1], cfg.ps_isr_final[1]!=3} ||
               &{vif_cpm_ps_isr.sig[2], cfg.ps_isr_final[2]!=3})
      begin
        if (&{vif_cpm_ps_isr.sig[0], cfg.ps_isr_final[0]!=3})                               severity = cfg.ps_isr_final[0];
        if (&{vif_cpm_ps_isr.sig[1], cfg.ps_isr_final[1]!=3, cfg.ps_isr_final[1]>severity}) severity = cfg.ps_isr_final[1];
        if (&{vif_cpm_ps_isr.sig[2], cfg.ps_isr_final[1]!=3, cfg.ps_isr_final[2]>severity}) severity = cfg.ps_isr_final[2];
        case (severity)
          0       : `uvm_info   ("PS_ISR_FINAL", msg, UVM_LOW)
          1       : `uvm_warning("PS_ISR_FINAL", msg)
          2       : `uvm_error  ("PS_ISR_FINAL", msg)
          default : `uvm_error  ("PS_ISR_FINAL", "TB error hit; investigate further")
        endcase
      end
    end
    if (vif_cpm_pl_isr.sig[2:0] !== '0) begin 
      msg = "PL ISR pins are not 0 at end of sim: ";
      msg = {msg, $sformatf("CORR=%b, ",   vif_cpm_pl_isr.sig[2])};
      msg = {msg, $sformatf("UNCORR=%b, ", vif_cpm_pl_isr.sig[1])};
      msg = {msg, $sformatf("MISC=%b",     vif_cpm_pl_isr.sig[0])};
      // an x or z is always an error
      if ($isunknown(vif_cpm_pl_isr.sig[2:0]))
        `uvm_error  ("PL_ISR_FINAL", msg)
      // only need to print if a bit is set that doesn't have "ignore" setting
      else if (&{vif_cpm_pl_isr.sig[0], cfg.pl_isr_final[0]!=3} ||
               &{vif_cpm_pl_isr.sig[1], cfg.pl_isr_final[1]!=3} ||
               &{vif_cpm_pl_isr.sig[2], cfg.pl_isr_final[2]!=3})
      begin
        if (&{vif_cpm_pl_isr.sig[0], cfg.pl_isr_final[0]!=3})                               severity = cfg.pl_isr_final[0];
        if (&{vif_cpm_pl_isr.sig[1], cfg.pl_isr_final[1]!=3, cfg.pl_isr_final[1]>severity}) severity = cfg.pl_isr_final[1];
        if (&{vif_cpm_pl_isr.sig[2], cfg.pl_isr_final[1]!=3, cfg.pl_isr_final[2]>severity}) severity = cfg.pl_isr_final[2];
        case (severity)
          0       : `uvm_info   ("PL_ISR_FINAL", msg, UVM_LOW)
          1       : `uvm_warning("PL_ISR_FINAL", msg)
          2       : `uvm_error  ("PL_ISR_FINAL", msg)
          default : `uvm_error  ("PL_ISR_FINAL", "TB error hit; investigate further")
        endcase
      end
    end
  endfunction

  // Set up the VIP attached to DUT ports
  virtual function void setup_pl_vip(dut_config cfg);
    foreach (cfg.ctrlr_en[ii]) begin
      /* CXL interfaces' agents */
      if (this.cfg.cxl_nfi_agnt_tx[ii] == ACTIVE_AGNT) begin
        // -- //
        cxl_nfi_agnt_tx[ii].cfg.cxl_cch_sup         = cfg.cxl_cfg[ii].cxl_device_type inside {1,2};
        cxl_nfi_agnt_tx[ii].cfg.cxl_mem_sup         = cfg.cxl_cfg[ii].cxl_device_type inside {2,3};
        cxl_nfi_agnt_tx[ii].cfg.cxl_membi_sup       = 1'b0;
        cxl_nfi_agnt_tx[ii].cfg.return_crds         = 1'b1;
        cxl_nfi_agnt_tx[ii].cfg.return_crds_in_flit = 1'b0;
        // -- //
        // RP DUT
        if (cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type == pcie_config::RP) begin
          cxl_nfi_agnt_rx[ii].cfg.init_rsp_credit[1]  = $urandom_range(32,512); 
          cxl_nfi_agnt_rx[ii].cfg.init_dat_credit[1]  = $urandom_range(32,512); 
        end
        // EP DUT
        else if (cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type == pcie_config::EP) begin
          cxl_nfi_agnt_rx[ii].cfg.init_req_credit[1]  = $urandom_range(32,512); 
          cxl_nfi_agnt_rx[ii].cfg.init_dat_credit[1]  = $urandom_range(32,512); 
        end
        else
          `uvm_fatal(get_type_name, "Port type must be RP or EP")
      end
    end
  endfunction

  // Convert a TXN that has CXL flit mode in it to modify the CXL agent behavior
  function void write_cxl_fm(gpmon_txn t);
    int i = (t.uid.substr(t.uid.len-2,t.uid.len-2)=="0") ? 0 : 1;
    case (t.sig[1:0])
      2'b00   : begin
                  cxl_nfi_agnt_rx[i].cfg.flitmode     = F68;
                  cxl_nfi_agnt_rx[i].mon.vif.f68_mode = 1;
                  // -- //
                  cxl_nfi_agnt_tx[i].cfg.flitmode     = F68;
                  cxl_nfi_agnt_tx[i].mon.vif.f68_mode = 1;
                  // -- //
                  shim.vsqr.flitmode                   = F68;
                end
      2'b11   : begin
                  cxl_nfi_agnt_rx[i].cfg.flitmode     = F256;
                  cxl_nfi_agnt_rx[i].mon.vif.f68_mode = 0;
                  // -- //
                  cxl_nfi_agnt_tx[i].cfg.flitmode     = F256;
                  cxl_nfi_agnt_tx[i].mon.vif.f68_mode = 0;
                  // -- //
                  shim.vsqr.flitmode                   = F256;
                end
      default : `uvm_error(get_type_name(), $sformatf("Unsupported CXL Flit Mode=%b", t.sig[1:0]))
    endcase
  endfunction

  // Register some callbacks for ELBI 
  function void write_elbi(elbi_txn t);
    `uvm_do_callbacks(tb_env, elbi_callback,  enter_cb(t));
    `uvm_do_callbacks(tb_env, elbi_callback, middle_cb(t));
    `uvm_do_callbacks(tb_env, elbi_callback,   exit_cb(t));
  endfunction

  // Get a PL ISR txn and trigger stuff to happen
  // We use an event because then users can do event.add_callback
  function void write_pl_isr(gpmon_txn t);
    // Zero out unused bits
    for (int ii=t.width; ii<64; ii++) t.sig[ii] = 1'b0;
    if ($isunknown(t.sig))
      `uvm_error("PL_ISR_CHECK", "PL ISR pin(s) are x or z")
    if ($countones(t.sig)) begin
      pl_isr_event.trigger(t);
    end
  endfunction

  // Get a PS ISR txn and trigger stuff to happen
  // We use an event because then users can do event.add_callback
  function void write_ps_isr(gpmon_txn t);
    // Zero out unused bits
    for (int ii=t.width; ii<64; ii++) t.sig[ii] = 1'b0;
    if ($isunknown(t.sig))
      `uvm_error("PS_ISR_CHECK", "PS ISR pin(s) are x or z")
    if ($countones(t.sig)) begin
      ps_isr_event.trigger(t);
    end
  endfunction

endclass
