// =============================================================================
// base_rp_gen6x8_bar_access_test
// // =============================================================================
class cfgspc_cb_6bar extends cfgspc_cb;
  virtual function void setup_cfg_space(input apci_device bfm, input apci_cfg_space csp);
    bit [1:0] pid = this.port_id;
    if (pid == csp.port_id && bfm.get("dev_type") == APCI_DEVICE_ep) begin
      `uvm_info("TB_CB", "cfgspc_cb_6bar: enabling BAR3, BAR4/5 for EP (all 6 BARs active)", UVM_LOW)
      // BAR3: 32-bit non-prefetchable, 8kB
      csp.type0.bar3.set_dv        (4'b0000);
      csp.type0.bar3.set_write_mask('h0000_1fff);
      // BAR4/5: 64-bit prefetchable, 64kB pair
      csp.type0.bar4.set_dv        (4'b1100);
      csp.type0.bar4.set_write_mask('h0000_ffff);
      csp.type0.bar5.set_write_mask('0);           // upper word of 64-bit BAR4
    end
  endfunction
endclass

class seq_ps_pcie_enum_fixed_aper extends seq_ps_pcie_enum;

  `uvm_object_utils(seq_ps_pcie_enum_fixed_aper)

  function new(string name = "seq_ps_pcie_enum_fixed_aper");
    super.new(name);
  endfunction

  constraint c_aper_base_alignment {
    io_aper_base[11:0]    == '0;
    mem_aper_base[19:0]   == '0;
    pfmem_aper_base[19:0] == '0;
    dsp_io32 -> io_aper_base[31:16] == '0;
  }

  constraint c_fixed_aper {
    mem_aper_base   == 32'hE000_0000;
    pfmem_aper_base == 64'h0000_0080_0200_0000;
  }

`ifdef CPM6_RTL
  // Override axi_wr to:
  //   1. Set AWUSER/WUSER = SMID=0x200 
  localparam bit [17:0] SMID = 18'h200;
  virtual task axi_wr(bit [47:0] addr, logic [31:0] data);
    string     msg;
    int        num_x;
    bit [31:0] _data = data;
    svt_axi_master_transaction wr;
    if (addr inside {[48'hfc800000:48'hfc8fffff]}) begin
      `uvm_info(get_type_name(), $sformatf("PS_A1: skipping write 0x%h=0x%h (no PS aperture after CFG_DONE)", addr, data), UVM_LOW)
      return;
    end
    wr = svt_axi_master_transaction::type_id::create("wr");
    `uvm_create(wr)
    wr.port_cfg        = cfg;
    wr.xact_type       = svt_axi_transaction::WRITE;
    wr.burst_type      = svt_axi_transaction::INCR;
    wr.burst_size      = svt_axi_transaction::BURST_SIZE_32BIT;
    wr.atomic_type     = svt_axi_transaction::NORMAL;
    wr.addr            = addr;
    wr.burst_length    = 1;
    wr.data            = new[1];
    wr.wstrb           = new[1];
    wr.data_user       = new[1];
    wr.wvalid_delay    = new[1];
    wr.data[0]         = _data;
    for (int ii = 0; ii < 4; ii++) begin
      num_x = $countbits(data[ii*8+:8], 'x);
      case (num_x)
        8       : wr.wstrb[0][ii] = 1'b0;
        0       : wr.wstrb[0][ii] = 1'b1;
        default : begin
                    msg = $sformatf("data[%0d:%0d] contains %0d Xs", (ii+1)*8-1, ii*8, num_x);
                    `uvm_fatal(get_type_name(), msg)
                  end
      endcase
    end
    wr.addr_user       = SMID;
    wr.data_user[0]    = SMID;
    wr.wvalid_delay[0] = $urandom_range(4,10);
    wr.bready_delay    = $urandom_range(4,10);
    `uvm_send(wr)
    get_response(rsp);
    if (rsp.bresp != svt_axi_transaction::OKAY)
      `uvm_error(get_type_name(), $sformatf("AXI Write 0x%h=0x%h -> BRESP=%0s", addr, _data, rsp.bresp.name))
  endtask

  virtual task axi_rd(bit [47:0] addr, output logic [31:0] data);
    svt_axi_master_transaction rd;
    rd = svt_axi_master_transaction::type_id::create("rd");
    `uvm_create(rd)
    rd.port_cfg        = cfg;
    rd.xact_type       = svt_axi_transaction::READ;
    rd.burst_type      = svt_axi_transaction::INCR;
    rd.burst_size      = svt_axi_transaction::BURST_SIZE_32BIT;
    rd.atomic_type     = svt_axi_transaction::NORMAL;
    rd.addr            = addr;
    rd.burst_length    = 1;
    rd.data            = new[1];
    rd.rresp           = new[1];
    rd.data_user       = new[1];
    rd.rready_delay    = new[1];
    rd.addr_user       = SMID;
    rd.rready_delay[0] = $urandom_range(4,10);
    `uvm_send(rd)
    get_response(rsp);
    data = rsp.data[0];
    if (rsp.rresp[0] != svt_axi_transaction::OKAY)
      `uvm_error(get_type_name(), $sformatf("AXI Read 0x%h -> RRESP=%0s", addr, rsp.rresp[0].name))
  endtask
`endif

endclass

`ifdef CPM6_RTL
// axi_mon_cb — SVT port monitor callback that fires transaction_ended() after every complete AXI transaction (write: BVALID/BREADY; read: RLAST).
class axi_mon_cb extends svt_axi_port_monitor_callback;
  `uvm_object_utils(axi_mon_cb)
  apci_tlp_sb sb;  
  function new(string name = "axi_mon_cb");
    super.new(name);
  endfunction
  virtual function void transaction_ended(svt_axi_port_monitor axi_monitor, svt_axi_transaction item);
    if (sb != null) sb.write_axi_mon(item);
  endfunction
endclass
`endif

class seq_bar_wr_rd extends seq_base_ps_axi128_bar;

  `uvm_object_utils(seq_bar_wr_rd)

  bit [47:0]     bar_base;
  int            num_beats;
  logic [127:0] rd_data[$:256];
  function new(string name = "seq_bar_wr_rd");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(),$sformatf("BAR WR+RD: base=0x%012h, beats=%0d", bar_base, num_beats), UVM_NONE)

    // Single burst write
    axi_wr_burst(bar_base, num_beats);
    `uvm_info(get_type_name(), "WRITE phase complete", UVM_NONE)

    // Single burst read 
    begin
      int rd_beats;
      if (!std::randomize(rd_beats) with { rd_beats inside {[1:num_beats]}; })
        `uvm_fatal(get_type_name(), "rd_beats randomization failed")
      `uvm_info(get_type_name(), $sformatf("RD burst length randomized to %0d (max=%0d)", rd_beats, num_beats), UVM_LOW)
      axi_rd_burst(bar_base, rd_beats, rd_data);
    end
    `uvm_info(get_type_name(), "READ phase complete", UVM_NONE)

    foreach (rd_data[i])
      `uvm_info(get_type_name(),$sformatf("  RD[%0d] 0x%012h = 0x%032h", i, bar_base + i*16, rd_data[i]), UVM_LOW)
  endtask

endclass

// ---------------------------------------------------------------------------
// Test class
// ---------------------------------------------------------------------------
class base_rp_gen6x8_bar_access_test extends base_rp_test;

  `uvm_component_utils(base_rp_gen6x8_bar_access_test)

  pcie_device pdevs;

`ifdef CPM6_RTL
  vip_tlp_cb                                     tlp_cb;   
  amd_tlp_converter_sb                           ep_sb;    
  axi_mon_cb                                     mon_cb;   // SVT callback: transaction_ended() → ep_sb.write_axi_mon()
`endif

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    seq_ps_pcie_enum::type_id::set_type_override(seq_ps_pcie_enum_fixed_aper::get_type());`uvm_info("bar_access","Factory override: seq_ps_pcie_enum -> seq_ps_pcie_enum_fixed_aper",UVM_LOW)

    env_cfg = tb_env_cfg::type_id::create("env_cfg");
    env_cfg.ps_isr_agnt = PASSIVE_AGNT;
    env_cfg.pl_isr_agnt = UNUSED_AGNT;
`ifdef CPM6_RTL
    env_cfg.axi_mst_agnt = '{default: ACTIVE_AGNT};
    env_cfg.axi_slv_agnt = '{default: ACTIVE_AGNT};
`endif

    uvm_config_db#(tb_env_cfg)::set(this, "env", "env_cfg", env_cfg);
    `uvm_info("bar_access","AXI master agents M_AXIMM_PS_CFG and M_AXIMM_PS_128 set to ACTIVE_AGNT",UVM_LOW)

`ifdef CPM6_RTL
    tlp_cb    = new("tlp_cb");  // created before connect_phase so apci_tlp_wr_rd_req port exists for wiring
    ep_sb     = amd_tlp_converter_sb::type_id::create("ep_sb", this);
    mon_cb    = new("mon_cb");
    mon_cb.sb = ep_sb;          // wire callback directly to SB (no analysis port needed)
`endif
  endfunction

`ifdef CPM6_RTL
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Register SVT callback: transaction_ended() fires after BVALID/BREADY (wr) or RLAST (rd),then calls ep_sb.write_axi_mon()
    uvm_callbacks#(svt_axi_port_monitor, svt_axi_port_monitor_callback)::add(env.axi_env.master[M_AXIMM_PS_128].monitor, mon_cb);
    tlp_cb.apci_tlp_wr_rd_req.connect(ep_sb.analysis_export);  // VIP TLPs → SB write_req/write_rsp
  endfunction
`endif

  virtual function void start_of_simulation_phase(uvm_phase phase);
    cfgspc_cb_6bar cb;
    super.start_of_simulation_phase(phase);  // calls env.shim.setup_vip() → registers base cfgspc_cb
    cb         = new();
    cb.port_id = 0;    // controller 0, port 0
    cb.shim_id = 0;
    cb.cfg     = vip_cfg;
    env.shim.vip.append_callback(cb);
    `uvm_info("bar_access", "Appended cfgspc_cb_6bar: all 6 EP BARs will be enabled", UVM_LOW)
`ifdef CPM6_RTL
    env.shim.vip.append_callback(tlp_cb);
    `uvm_info("bar_access", "Appended vip_tlp_cb: VIP TLPs routed to test-owned ep_sb", UVM_LOW)
`endif
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    dut_ctrlr_en[0] = 1'b1;
    dut_ctrlr_en[1] = 1'b0;
    dut_cfg.use_case[0] = dut_config::PCIE_STR;
    super.end_of_elaboration_phase(phase); // sets RP/EP port types
    bus_enum.ecam_base = 48'h6_0000_0000;
    for (int ii = 0; ii < 2; ii++) begin
      // VIP EP: Gen6, flit mode enabled
      vip_cfg.pcie_cfg[ii].pcie_cap.link_ctl2.target_link_speed = pcie_config::GEN6;
      vip_cfg.pcie_cfg[ii].flit_mode_ctl = 1'b1;
      // DUT RP: flit mode enabled
      dut_cfg.pcie_cfg[ii].flit_mode_ctl  = 1'b1;
      dut_cfg.base_cdo = "cpm6_pcie_rc_c0_g6x8_inb_outb_ps0.cdo.anno";
    end
  endfunction


`ifdef CPM6_RTL
  virtual task pre_reset_phase(uvm_phase phase);
    super.pre_reset_phase(phase);
    demux_sel_vif.set_use_case(PCIE_STR);
  endtask
`endif

  virtual task main_phase(uvm_phase phase);
    seq_bar_wr_rd  bar_seqs[int];
    int            num_beats;

    super.main_phase(phase);  // enumeration runs here; SB checks disabled during this
`ifdef CPM6_RTL
    ep_sb.check_enabled = 1;  // enable Check1/Check2 — all ECAM traffic is done
    `uvm_info("bar_access", "SB checks enabled after enumeration", UVM_LOW)
`endif
    phase.raise_objection(this);

    pdevs = env.shim.container.get_pdev_EP;
    if (pdevs == null)
      `uvm_fatal("bar_access", "No EP device found in container after enumeration!")

    `uvm_info("bar_access", $sformatf("Found EP: vendorid=0x%04h, deviceid=0x%04h",
      pdevs.vendorid, pdevs.deviceid), UVM_NONE)

    if (!pdevs.membar.exists(0))
      `uvm_fatal("bar_access", "No memory BARs found in EP device after enumeration!")

    num_beats = 4; // 4 x 128-bit beats = 64 bytes per BAR

    foreach (pdevs.membar[i]) begin
      `uvm_info("bar_access", $sformatf("BAR%0d: base=0x%016h  sz=0x%016h  is_64=%0b  is_pftch=%0b",
        i, pdevs.membar[i].base, pdevs.membar[i].sz,
        pdevs.membar[i].is_64, pdevs.membar[i].is_pftch), UVM_LOW)

      bar_seqs[i]           = seq_bar_wr_rd::type_id::create($sformatf("bar_seq_%0d", i));
      bar_seqs[i].bar_base  = pdevs.membar[i].base[47:0];
      bar_seqs[i].num_beats = num_beats;

    end

    `uvm_info("bar_access", "--- Starting all BAR sequences in parallel ---", UVM_NONE)
    foreach (pdevs.membar[i]) begin
      automatic int idx = i;  
      fork
        begin
`ifdef CPM6_RTL
          bar_seqs[idx].start(env.axi_env.master[M_AXIMM_PS_128].sequencer);
`else
          bar_seqs[idx].start(env.ps_vip_vsqr);
`endif
        end
      join_none  
    end
    wait fork;   
    `uvm_info("bar_access", "--- All BAR sequences and SB notifications complete ---", UVM_NONE)

    phase.drop_objection(this);
  endtask

endclass
