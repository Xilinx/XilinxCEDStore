// This class encompasses all AMD to PCIe VIP shims so that a testbench
// and tests are VIP agnostic

// forward typedefs that are compiled after this class
typedef class cfgspc_cb;
typedef class status_cb;
typedef class cxl_cm_reg_cb;
typedef class seq_cap_traverse;
typedef class seq_ep_get_sriov;

class shim_layer extends uvm_component;

  `uvm_component_utils(shim_layer)

  int link_width[2];
  bit pipe_sim;

  `ifdef AVERY_CPM6_COSIM
    savpci_simcluster simcluster;
  `endif

  // control running post_enum sequence
  bit skip_usp_caps;
  bit skip_dsp_caps;

  // vifs
  virtual apci_pipe_intf vif_tmp;
  virtual apci_pipe_intf vif_vip[2][$];

  // api
  shim_api        api;
  shim_vsequencer vsqr; 

  // agent
  apci_device vip;

  // status
  pdev_container container;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);  
    `ifdef AVERY_CPM6_COSIM
      simcluster = new("simcluster", this, "key_qemu");
    `endif
    // get ifs
    for (int link=0; link<2; link++) begin
      for (int ln=0; ln<link_width[link]; ln++) begin
        if (!uvm_config_db#(virtual apci_pipe_intf)::get(this, "", $sformatf("vip_vif[%0d][%0d]",link,ln), vif_tmp))
          `uvm_fatal("CFGDB_NOGET", $sformatf("Could not get 'vip_vif[%0d][%0d]' from cfg db",link,ln))
        else
          vif_vip[link].push_back(vif_tmp);
      end
    end
    // create objects
    vip       = apci_device::type_id::create("vip", this);
    api       = shim_api::type_id::create("api", this);
    vsqr      = shim_vsequencer::type_id::create("vsqr", this);
    container = pdev_container::type_id::create("container", this);
    // if both controllers are active, assign both vifs to vip
    if (link_width[0] > 0 && link_width[1] > 0) begin
      vip.configure(APCI_DEVICE_rc, 2); // max 2 ports
      vip.assign_vi(0, vif_vip[0]);
      vip.assign_vi(1, vif_vip[1]);
      `uvm_info("SHIM", $sformatf("Assigned vif_vip[0] to VIP with %0d lanes to port 0", vif_vip[0].size()), UVM_MEDIUM)
      `uvm_info("SHIM", $sformatf("Assigned vif_vip[1] to VIP with %0d lanes to port 1", vif_vip[1].size()), UVM_MEDIUM)
    end
    else if (link_width[0] > 0) begin
      // pass vif to vip (only one controller for now)
      vip.configure(APCI_DEVICE_rc, 1); // max 1 port
      vip.assign_vi(0, vif_vip[0]);
      `uvm_info("SHIM", $sformatf("Assigned vif_vip[0] to VIP with %0d lanes to port 0", vif_vip[0].size()), UVM_MEDIUM)
    end
    else if (link_width[1] > 0) begin
      // pass vif to vip (only one controller for now)
      vip.configure(APCI_DEVICE_rc, 1); // max 1 port
      vip.assign_vi(0, vif_vip[1]);
      `uvm_info("SHIM", $sformatf("Assigned vif_vip[1] to VIP with %0d lanes to port 0", vif_vip[1].size()), UVM_MEDIUM)
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // pass handle(s) down
    api.vip  = vip;
    vsqr.api = api;
    vsqr.vip = vip;
  endfunction

  `ifdef AVERY_CPM6_COSIM
  virtual task main_phase(uvm_phase phase);
    apci_device bfms[$];
    string      keychain[$:2]; 
    string      key;
    bit         test_done;
    apci_cosim_rp_callbacks rp_cb;
    // QEMU key "from"  
    uvm_config_db#(string)::get(uvm_root::get(), "sav_simcluster",
      "keychain[0]", key);
    keychain.push_back(key);
    // QEMU key "to"  
    uvm_config_db#(string)::get(uvm_root::get(), "sav_simcluster",
      "keychain[1]", key);
    keychain.push_back(key);
    // Need to register callbacks to interface between Agent and QEMU
    rp_cb = new(vip, keychain[1]);
    // Wait until link is up
    vip.port_wait_event(0, "dl_up");
    // Now just interface forever 
    while (!test_done) qemu_wait_sc_cmd(test_done, vip, bfms, keychain[1], keychain[0]); 
  endtask
  `endif

  virtual function void setup_vip_defaults(generic_config cfg);
    bit port_id;
    vip.cfg_info.speed_sup = 6;
    vip.cfg_info.dl_feature_sup = 1; //reqd. when >= Gen4 supported
    vip.cfg_info.use_low_pin = 0;
    vip.cfg_info.use_serdes = 1;
    vip.cfg_info.ide_sup = 1;
    vip.cfg_info.doe_sup = 1;
    vip.cfg_info.bypass_spdm_flow = 0;
    // Provide some basic setup
    vip.set("auto_speedup_to",         6);   // Link train to Gen6, if possible
    vip.set("auto_speedup",            1);   // Enable link training to highest common rate
    vip.set("skip_equal_phase23",      1);   // Bypass Phase2/3 Equalization
    vip.set("bus_enum_bus_base",       $urandom_range(0,254));
    vip.set("bus_enum_skip_vf_enable", 1);   // don't enumerate VFs (takes forever)
    vip.set("auto_enum",               1);   // Enumerate the bus after reaching full speed
    case (1'b1)
      cfg.pcie_cfg[0].pcie_cap.pcie_cap.dev_port_type==pcie_config::EP      : vip.set("dev_type", APCI_DEVICE_ep);
      cfg.pcie_cfg[0].pcie_cap.pcie_cap.dev_port_type==pcie_config::RP      : vip.set("dev_type", APCI_DEVICE_rc);
      cfg.pcie_cfg[0].pcie_cap.pcie_cap.dev_port_type==pcie_config::NO_PORT : /* do nothing */ ;
      default : `uvm_fatal(get_type_name, $sformatf("Unsupported device/port type: %0s", cfg.pcie_cfg[0].pcie_cap.pcie_cap.dev_port_type.name))
    endcase
    case (1'b1)
      cfg.pcie_cfg[1].pcie_cap.pcie_cap.dev_port_type==pcie_config::EP      : vip.set("dev_type", APCI_DEVICE_ep);
      cfg.pcie_cfg[1].pcie_cap.pcie_cap.dev_port_type==pcie_config::RP      : vip.set("dev_type", APCI_DEVICE_rc);
      cfg.pcie_cfg[1].pcie_cap.pcie_cap.dev_port_type==pcie_config::NO_PORT : /* do nothing */ ;
      default : `uvm_fatal(get_type_name, $sformatf("Unsupported device/port type: %0s", cfg.pcie_cfg[1].pcie_cap.pcie_cap.dev_port_type.name))
    endcase
    // Enable tracker logfiles
    foreach (cfg.ctrlr_en[ii]) begin
      port_id = ii==1 ? cfg.ctrlr_en[0] : 0;
      if (cfg.ctrlr_en[ii]) begin
        vip.port_set_tracker(port_id, "phy",   1, $sformatf("tracker_phy_vip%0d.log",ii));
        vip.port_set_tracker(port_id, "dll",   1, $sformatf("tracker_dll_vip%0d.log",ii));
        vip.port_set_tracker(port_id, "tl",    1, $sformatf("tracker_tl_vip%0d.log",ii));
        vip.port_set_tracker(port_id, "cfg",   1, $sformatf("tracker_cfg_vip%0d.log",ii));
        vip.port_set_tracker(port_id, "trans", 1, $sformatf("tracker_trans_vip%0d.log",ii));
        if (cfg.pcie_cfg[ii].pcie_cap.pcie_cap.flit_mode_supp && 
            !cfg.pcie_cfg[ii].pcie_cap.link_ctl.flit_mode_disable) 
        begin
          vip.port_set_tracker(port_id, "phy_flit", 1, $sformatf("tracker_phy_flit_vip%0d.log",ii));
          vip.port_set_tracker(port_id, "dll_flit", 1, $sformatf("tracker_dll_flit_vip%0d.log",ii));
        end
        if (cfg.port_ctl[ii]!=generic_config::PCIE) begin
          vip.port_set_tracker(port_id, "cxl_tl",  1, $sformatf("tracker_cxl_tl_vip%0d.log",ii));
          vip.port_set_tracker(port_id, "cxl_dll", 1, $sformatf("tracker_cxl_dll_vip%0d.log",ii));
          vip.port_set_tracker(port_id, "cxl_arbmux", 1, $sformatf("tracker_cxl_arbmux_vip%0d.log",ii));
        end
      end
    end
    // CXL mode setup
    if ((cfg.ctrlr_en[0] && cfg.port_ctl[0]!=generic_config::PCIE) ||
        (cfg.ctrlr_en[1] && cfg.port_ctl[1]!=generic_config::PCIE))
    begin 
      vip.cfg_info.cxl_sup = 3;
      vip.cfg_info.alt_protocol_sup = 1;
      // These will be sent in ModTS1 for APN
      vip.cfg_info.cxlcfg.common_clock  = 1;
      vip.cfg_info.cxlcfg.pcie_cap      = cfg.port_ctl[0]==generic_config::PCIE_CXL || 
                                          cfg.port_ctl[1]==generic_config::PCIE_CXL;
      vip.cfg_info.cxlcfg.cxl_mem_cap   = cfg.cxl_cfg[0].cxl_device_type inside {2,3} ||
                                          cfg.cxl_cfg[1].cxl_device_type inside {2,3};
      vip.cfg_info.cxlcfg.cxl_cache_cap = cfg.cxl_cfg[0].cxl_device_type inside {1,2} ||
                                          cfg.cxl_cfg[1].cxl_device_type inside {1,2};
      vip.cfg_info.cxlcfg.cxl_io_cap    = 1;
    end
  endfunction

  virtual function void setup_vip(generic_config cfg);
    cfgspc_cb      cfg_cb[2];
    status_cb      sts_cb;
    cxl_cm_reg_cb  cxl_cb;
    cfg.print_settings;
    setup_vip_defaults(cfg);
    // callbacks
    if (&{cfg.ctrlr_en[0], cfg.pcie_cfg[0].pcie_cap.pcie_cap.dev_port_type==pcie_config::RP} ||
        &{cfg.ctrlr_en[1], cfg.pcie_cfg[1].pcie_cap.pcie_cap.dev_port_type==pcie_config::RP})
    begin
      sts_cb = new();
      sts_cb.api           = api;
      sts_cb.container     = container;
      sts_cb.vsqr          = vsqr;
      sts_cb.skip_usp_caps = skip_usp_caps;
      sts_cb.skip_dsp_caps = skip_dsp_caps;
      `uvm_info("TB_CB", "Appending callback to enum_done_user for VIP", UVM_NONE)
      vip.append_callback(sts_cb);
    end
    foreach (cfg_cb[ii]) begin
      if (cfg.ctrlr_en[ii]) begin
        cfg_cb[ii]         = new();
        cfg_cb[ii].port_id = ii==1 ? cfg.ctrlr_en[0] : 0;
        cfg_cb[ii].shim_id = ii;
        cfg_cb[ii].cfg     = cfg;
        `uvm_info("TB_CB", "Appending callback to setup_cfg_space for VIP", UVM_NONE)
        vip.append_callback(cfg_cb[ii]);
      end
    end
    if ((cfg.ctrlr_en[0] && cfg.cxl_cfg[0].cxl_device_type inside {2,3} &&
         cfg.pcie_cfg[0].pcie_cap.pcie_cap.dev_port_type == pcie_config::EP) ||
        (cfg.ctrlr_en[1] && cfg.cxl_cfg[1].cxl_device_type inside {2,3} &&
         cfg.pcie_cfg[1].pcie_cap.pcie_cap.dev_port_type == pcie_config::EP))
    begin
      cxl_cb   = new();
      `uvm_info("TB_CB", "Appending cxl_cb (CXL Component Register memory model) to VIP", UVM_NONE)
      vip.append_callback(cxl_cb);
    end
  endfunction

  // Configure some VIP settings when we know we will operate in non-flit mode
  virtual function void setup_vip_nfm();
    vip.cfg_info.simplified_replay_timer_sup = 1'b1;
  endfunction

endclass

// Avery requires a config space callback class, so we must create it
class cfgspc_cb extends apci_callbacks;

  generic_config cfg; 
  bit            shim_id; //equivalent to controller 

  // - Unroll generic_config to the config space of the agent
  // - Change a reg field by csp.<capability handle>.<reg_field>, you can find
  //   the capabilities and fields in $AVERY_PCIE/svip/apci_all_caps.svh
  // - To remove a capability structure, set the handle to the cap to null in 
  //   below callback i.e. csp.msi = null;
  // - When we modify a reg field that changes the size of a capability, we
  //   must call csp.<cap>.reconfig(); on it.
  // - A BFM may be multi-port, but you can optionally configure a specific
  //   port and function by checking csp.port_id(8b) and csp.func_num(16b) in
  //   the callback.
  /* AVERY DOC: 
    1. Each capability register field is an avery_reg_field class object.
       User can backdoor change a field's property using these methods:
       - avery_reg_field::set_v()         : change current value
       - avery_reg_field::set_dv()        : change default value after reset
       - avery_reg_field::set_sticky()    : change sticky bit
       - avery_reg_field::set_acctype()   : change access policy type
       - avery_reg_field::set_write_mask(): change Write Mask bit, typically used to change BAR size
  */
  virtual function void setup_cfg_space(input apci_device bfm, input apci_cfg_space csp);
    bit [1:0] pid = this.port_id; 
    bit       sid = this.shim_id;
    if (pid==csp.port_id) begin
      `uvm_info("TB_CB", $sformatf("Modifying cfg space for VIP Port %0d and Controller %0d",pid,sid), UVM_NONE)
      /* Perform BAR setup */
      // - RP BARs
      if (bfm.get("dev_type") == APCI_DEVICE_rc) begin
        // - BAR 0
        csp.type1.bar0.set_dv        (4'b1100);     //64bit, prefetchable
        csp.type1.bar0.set_write_mask('h0000_ffff); //64kB
        // - BAR 1 (cont) 
        csp.type1.bar1.set_write_mask('0); 
      end
      // - EP BARs
      else begin
        // - BAR 0
        csp.type0.bar0.set_dv        (4'b1100);     //64bit, prefetchable
        csp.type0.bar0.set_write_mask('h0000_ffff); //64kB
        // - BAR 1 (cont) 
        csp.type0.bar1.set_write_mask('0); 
        // - BAR 2
        csp.type0.bar2.set_dv        (4'b0000);     //32bit, non-prefetchable
        csp.type0.bar2.set_write_mask('h0000_1fff); //8kB
        // - BAR 3 (none)
        csp.type0.bar3.set_dv        ('0); 
        csp.type0.bar3.set_write_mask('1); 
        // - BAR 4 (none)
        csp.type0.bar4.set_dv        ('0); 
        csp.type0.bar4.set_write_mask('1); 
        // - BAR 5 (none)
        csp.type0.bar5.set_dv        ('0); 
        csp.type0.bar5.set_write_mask('1); 
      end
      /* Always available, regardless of port_type */
      // MSI CAP
      csp.msi.multi_msg_cap.set_dv($clog2(cfg.pcie_cfg[sid].msi_cap.msg_control.multi_msg_cap));
      csp.msi.per_vec_mask_cap.set_dv(cfg.pcie_cfg[sid].msi_cap.msg_control.per_vec_mask_cap);
      csp.msi.extend_msg_data_cap.set_dv(cfg.pcie_cfg[sid].msi_cap.msg_control.ext_msg_data_cap);
      csp.msi.is_64_bit_cap.set_dv(cfg.pcie_cfg[sid].msi_cap.msg_control.addr64_cap);
      csp.msi.reconfig();
      // PCIe CAP
      csp.pcie.device_type.set_dv(cfg.pcie_cfg[sid].pcie_cap.pcie_cap.dev_port_type);
      csp.pcie.target_link_speed.set_dv(cfg.pcie_cfg[sid].pcie_cap.link_ctl2.target_link_speed);
      csp.pcie.flit_mode_sup.set_dv(cfg.pcie_cfg[sid].pcie_cap.pcie_cap.flit_mode_supp);
      csp.pcie.flit_mode_disable.set_dv(cfg.pcie_cfg[sid].pcie_cap.link_ctl.flit_mode_disable);
      csp.pcie.max_payload_size_sup.set_dv($clog2(cfg.pcie_cfg[sid].pcie_cap.device_cap.max_payload_size_supp)-7);
      csp.pcie.rx_mps_fixed.set_dv(cfg.pcie_cfg[sid].pcie_cap.device_cap.rx_mps_fixed);
      csp.pcie.extended_tag_field_enable.set_dv(cfg.pcie_cfg[sid].tags.reqr_tag_supp>=8);
      csp.pcie.ten_bit_tag_requester_sup.set_dv(cfg.pcie_cfg[sid].tags.reqr_tag_supp>=10);
      csp.pcie.ten_bit_tag_completer_sup.set_dv(cfg.pcie_cfg[sid].tags.cmpr_tag_supp>=10);
      csp.pcie.retimer_presence_detect_sup.set_dv(cfg.pcie_cfg[sid].pcie_cap.link_cap2.retimer1_pres_det_supp);
      csp.pcie.two_retimers_presence_detect_sup.set_dv(cfg.pcie_cfg[sid].pcie_cap.link_cap2.retimer2_pres_det_supp);
      // Device 3 EXT CAP
      csp.device3.fourteen_bit_tag_requester_sup.set_dv(cfg.pcie_cfg[sid].tags.reqr_tag_supp>=14);
      csp.device3.fourteen_bit_tag_completer_sup.set_dv(cfg.pcie_cfg[sid].tags.cmpr_tag_supp>=14);
      // Physical Layer 32.0 GT/s
      //  -- always turn off EQ for sim
      csp.pl_gen5.no_equal_sup.set_dv(1'b1);
      csp.pl_gen5.no_equal_disable.set_dv(1'b0);
      /* CXL specific config */
      // ---

      /* IDE CFG */
      if (csp.pcie) begin
        //Setup prefix and format for PCIE
        csp.pcie.end2end_tlp_prefix_sup.set_dv(1);
        csp.pcie.extended_fmt_field_sup.set_dv(1);
      end
      // Configure BFM's IDE capability structure
      // Link/Selective block registers must be programmed in the callback setup_cfg_space appended before BFM is started.
      if (csp.ide) begin
          apci_cap_ide ide = csp.ide;
          ide.link_ide_stream_sup.set_dv(1);
          ide.sel_ide_stream_sup.set_dv(1);
          ide.flow_through_ide_stream_sup.set_dv(0);
          ide.partial_header_encryption_sup.set_dv(1);
          ide.aggregation_sup.set_dv(0);
          ide.pcrc_sup.set_dv(1);
          ide.ide_km_protocol_sup.set_dv(1);
          ide.sel_ide_for_cfg_req_sup.set_dv(0);
          ide.num_of_tc_sup_for_link_ide.set_dv(1);
          ide.num_of_sel_ide_stream_sup.set_dv(1);
          ide.tee_limited_stream_sup.set_dv(0);

          ide.reconfig();
          ide.num_of_addr_associate_reg_blk[0].set_dv(2);
          ide.reconfig_sec();
      end

      if (csp.doe_array[0]) begin
        csp.doe_array[0].cap_version.set_dv(1);
      end
      // 1 HDM Aperture 
      if(csp.cxl_device) begin
         `uvm_info("TB_CB", "Modifying CXL EP cfg space through setup_cfg_space callback", UVM_LOW)
         `uvm_info("TB_CB", "1. Setting hdm_count = 1 and aperture to 4 GB", UVM_LOW)
	 csp.cxl_device.dvsec_vendor_id.set_dv(16'h1E98);
         csp.cxl_device.hdm_count.set_dv('h1);
         csp.cxl_device.mem_size_high_range1.set_dv('h1); //4 GB

         // BAR3/BAR4: 64-bit prefetchable 64KB — holds the CXL Component Registers.
         // MUST be configured here for the VIP to generate DVSEC ID=8.
         `uvm_info("TB_CB", "2. Configuring BAR3/BAR4 as 64-bit prefetchable 64KB (Component Registers)", UVM_LOW)
         csp.type0.bars[3].set_dv        (32'hffff_000C);
         csp.type0.bars[3].set_acctype   (AVERY_REG_ACC_WMSK);
         csp.type0.bars[3].set_write_mask(32'h0000_ffff); // bits[15:0] fixed (type+alignment); bits[31:16] writable (address)
         csp.type0.bars[4].set_dv        ('0);
         csp.type0.bars[4].set_acctype   (AVERY_REG_ACC_WMSK);
         csp.type0.bars[4].set_write_mask('0);

         // Register Locator DVSEC (ID=8): Component Registers at BAR3, offset 0x0.
         // reg_block_id: 0x01=COMPONENT_REG, 0x00=NULL_REG_BLOCK
         // DVSEC ID=8 is NOT auto-generated by the VIP — must explicitly instantiate.
         //if (csp.cxl_reg_loc == null)
         //  csp.cxl_reg_loc = new("apci_cap_dvsec_cxl_reg_locator", 4);
         `uvm_info("TB_CB", "3. Setting Register Locator DVSEC: Component Registers at BAR3, offset 0x0", UVM_LOW)
         csp.cxl_reg_loc.reg_bir[0].set_dv('d3);  // BAR3 (64-bit PF, 64KB)
         foreach (csp.cxl_reg_loc.reg_block_id[ii])
           csp.cxl_reg_loc.reg_block_id[ii].set_dv(!ii ? 8'h1 : 8'h0); // [0]=COMPONENT_REG, rest=NULL
         // Set up the capability header  
         //init_cxl_cm_regs;
      end

    end
  endfunction

  // Called by VIP to configure the MMIO register layout for the CXL EP.
  // The auto-generated cxl_pri_mailbox overlaps with cxl_cm (Component Registers
  // at BAR3+0x1000). Disable the mailbox and other unused monitors.
  virtual function void setup_mmio_reg(input apci_device bfm, input apci_mmio_reg mmreg);
    mmreg.cxl_pri_mailbox       = null; // removes overlap with cxl_cm at BAR3+0x1000
    mmreg.cxl_sec_mailbox       = null;
  endfunction

endclass

class status_cb extends apci_callbacks;
  shim_api         api;
  pdev_container   container;
  shim_vsequencer  vsqr;
  bit              skip_usp_caps;
  bit              skip_dsp_caps;
  // This task will be called once and give a queue of handles to each device
  virtual task enum_done_wait_user(input apci_device     bfm,
                                   input apci_device_mgr mgrs[$]);
    pcie_device      pdev;
    pcie_vdevice     vdev;
    seq_cap_traverse seq_cap;
    seq_ep_get_sriov seq_sriov;
    container.clear_pdevs();
    `uvm_info("TB_CB", "ENV: got enum_done_wait_user", UVM_NONE)
    // Convert each device to the AMD one; we will unroll each
    // "device," which may have multiple functions within it, into
    // a flattened structure where each function is an entry
    // -> Device
    foreach (mgrs[ii]) begin
      // -> Function(s)
      foreach (mgrs[ii].finfs[jj]) begin
        pdev = pcie_device::type_id::create("pdev");
        pdev.primary_bus = mgrs[ii].bus_num;
        pdev.vendorid    = mgrs[ii].finfs[jj].vendor_id;
        pdev.deviceid    = mgrs[ii].finfs[jj].device_id;
        pdev.bdf         = mgrs[ii].finfs[jj].bdf;
        pdev.ptype       = amd_devport_t'(mgrs[ii].finfs[jj].ptype);
        // BARs
        foreach (mgrs[ii].finfs[jj].mem_ranges[kk]) begin
          pdev.add_mem_bar(mgrs[ii].finfs[jj].mem_ranges[kk].bar_id,
                           mgrs[ii].finfs[jj].mem_ranges[kk].is_64,
                           mgrs[ii].finfs[jj].mem_ranges[kk].prefetchable,
                           mgrs[ii].finfs[jj].mem_ranges[kk].base,
                           mgrs[ii].finfs[jj].mem_ranges[kk].len);
        end
        foreach (mgrs[ii].finfs[jj].io_ranges[kk]) begin
          pdev.add_io_bar(mgrs[ii].finfs[jj].io_ranges[kk].bar_id,
                          mgrs[ii].finfs[jj].io_ranges[kk].base,
                          mgrs[ii].finfs[jj].io_ranges[kk].len);
        end
        // ...not "technically" a BAR, but close enough
        foreach (mgrs[ii].finfs[jj].cxl_hdm_ranges[kk]) begin
          pdev.add_cxl_hdm(mgrs[ii].finfs[jj].cxl_hdm_ranges[kk].base,
                           mgrs[ii].finfs[jj].cxl_hdm_ranges[kk].len);
        end
        // Apertures
        if (pdev.is_type1) begin
          pdev.add_pmem_aper (mgrs[ii].finfs[jj].behind_pref.base,
                              mgrs[ii].finfs[jj].behind_pref.len);
          pdev.add_npmem_aper(mgrs[ii].finfs[jj].behind_mio.base,
                              mgrs[ii].finfs[jj].behind_mio.len);
          pdev.add_io_aper   (mgrs[ii].finfs[jj].behind_io.base,
                              mgrs[ii].finfs[jj].behind_io.len);
          pdev.add_cxl_aper  (mgrs[ii].finfs[jj].behind_cxl_hdm.base,
                              mgrs[ii].finfs[jj].behind_cxl_hdm.len);
        end
        // Get capability and extended capability structures
        if (&{pdev.ptype==PT_RP,      !skip_dsp_caps} ||
            &{pdev.ptype==PT_PCIE_EP, !skip_usp_caps})
        begin
          seq_cap = seq_cap_traverse::type_id::create("seq_cap");
          {seq_cap.print_caps, seq_cap.print_ecaps} = 2'b00;
          seq_cap.pdev = pdev;
          seq_cap.start(vsqr);
        end
          // Get SR-IOV info 
        if (pdev.ptype==PT_PCIE_EP) begin
          seq_sriov = seq_ep_get_sriov::type_id::create("seq_sriov");
          seq_sriov.pdev = pdev;
          seq_sriov.start(vsqr);
          if (!seq_sriov.ecap_sriov_not_found) begin
            // Populate VF information
            vdev = null;
            pdev.vf.push_back(vdev);
            foreach (mgrs[ii].finfs[jj].virtual_funcs[kk]) begin
              seq_cap_traverse seq_cap_vf;
              vdev = pcie_vdevice::type_id::create("vdev");
              vdev.bdf         = mgrs[ii].finfs[jj].virtual_funcs[kk].bdf;
              vdev.pf          = pdev;
              vdev.vf_num      = kk + 1;
              // Get capability and extended capability structures
              seq_cap_vf = seq_cap_traverse::type_id::create("seq_cap_vf");
              {seq_cap_vf.print_caps, seq_cap_vf.print_ecaps} = 2'b00;
              seq_cap_vf.vdev = vdev;
              seq_cap_vf.start(vsqr);
              pdev.vf.push_back(vdev);
            end
          end
        end
        /* Once built, add to container */
        container.add_pdev(pdev);
      end
    end
    `uvm_info("TB_CB", "ENV: finished enum_done_wait_user", UVM_NONE)
  endtask

endclass
