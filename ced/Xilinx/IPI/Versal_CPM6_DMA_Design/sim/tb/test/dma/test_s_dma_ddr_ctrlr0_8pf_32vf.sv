// SR-IOV HDMA test: 8 PFs x 4 VFs = 40 functions on controller 0.
//
// Per function: H2C then C2H simple DMA through that function's own BAR1 PL register block,
// completion via MSI-X, then interrupt clear. One function at a time.
//
// Run options (plusargs):
//   +ENABLE_VF=4      REQUIRED. Lets the VIP enumerate/enable VFs (shim_layer.sv), 4 VFs per PF.
//   +VF_MODE=<n>      0 = enumeration + register checks only
//                     1 = PFs only
//                     2 = one VF only (PF0-VF0, channel 8)
//                     3 = all 40 functions (default)
//   +VF_ITER=<n>      iterations over the selected functions (default 1)
//   +VFNUM_GLOBAL     CPM6 HDMA FUNC_NUM "vf" field = global VF index (default: PF-relative)
//   +KEEP_CFG_RETRY   leave CPM6 ATTR_REG_0.app_req_retry_en as the CDO sets it (default: cleared after the CDO load)
//
// PL register map in each function's BAR1 (design ctrl0ep_g6x8_hdma_ddr_8pf_32vf, axil_slave.sv):
//   0x00 version (0xAA000003)   0x50 chn_local_num (this function's channel = (vf+1)*8 + pf)
//   C2H: 0x10 size, 0x14 src_lo, 0x18 src_hi, 0x1C dst_lo, 0x20 dst_hi (TRIGGER), 0x24 status, 0x28 irq clear
//   H2C: 0x30 size, 0x34 src_lo, 0x38 src_hi, 0x3C dst_lo, 0x40 dst_hi (TRIGGER), 0x44 status, 0x48 irq clear
class test_s_dma_ddr_ctrlr0_8pf_32vf extends test_dma_tasks_8pf;

  `uvm_component_utils(test_s_dma_ddr_ctrlr0_8pf_32vf);

  localparam int N_PF   = 8;
  localparam int N_VF   = 4;                  // VFs per PF
  localparam int N_FUNC = N_PF * (N_VF + 1);  // 40 = 8 PFs + 32 VFs

  typedef struct {
    int          pf;
    int          vf;          // -1 = the PF itself, else 0..N_VF-1 (PF-relative)
    int          chan;        // (vf+1)*N_PF + pf
    bit [15:0]   bdf;
    bit [63:0]   bar1_base;
    bit [63:0]   msix_tbl;    // absolute address of this function's MSI-X table
    int          num_vec;
  } func_s;

  func_s funcs[N_FUNC];

  int vf_mode;
  int vf_iter;
  bit vfnum_global;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

    vf_mode = 3;
    vf_iter = 1;
    void'($value$plusargs("VF_MODE=%d", vf_mode));
    void'($value$plusargs("VF_ITER=%d", vf_iter));
    vfnum_global = $test$plusargs("VFNUM_GLOBAL");
    // VF enumeration is enabled by this test itself (pre_enum_seq below); +ENABLE_VF is not needed

    // Controller 0 only
    dut_ctrlr_en[0] = 1'b1;
    dut_ctrlr_en[1] = 1'b0;
    `uvm_info("---- Which Controler enabled.  ---- ", $sformatf("Controler %b is enabled", dut_ctrlr_en[1:0]), UVM_NONE)

    for (int ii=0; ii<2; ii++) begin
      // VIP as RP
      vip_cfg.ctrlr_en[ii] = 1'b1;
      vip_cfg.port_ctl[ii] = generic_config::PCIE;
      vip_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::RP;
      vip_cfg.pcie_cfg[ii].flit_mode_ctl = 1;
      // DUT as EP
      dut_cfg.ctrlr_en[ii] = dut_ctrlr_en[ii];
      dut_cfg.port_ctl[ii] = generic_config::PCIE;
      dut_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::EP;
      dut_cfg.pcie_cfg[ii].flit_mode_ctl = 1;
    end
    // Non-zero num_vfs keeps the SR-IOV extended capability in the generated CDO's capability chain
    dut_cfg.pcie_cfg[0].num_vfs = N_VF;

    // PS_VIP routing for DDR access
    if (!uvm_config_db#(virtual ps_vip_api_if)::get(this, "", "ps_vip_api", ps_vip_api))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'ps_vip_api' from cfg db")
    ps_vip_api.set_routing_config(CPM_PS_AXI_0, PS_NOC_PCI_AXI_0, 1'b1);
    ps_vip_api.set_routing_config(CPM_PS_AXI_1, PS_NOC_PCI_AXI_1, 1'b1);
  endfunction


  // Enable VF enumeration in the VIP. The framework does this in shim_layer.sv on +ENABLE_VF[=<VFs per PF>]; doing it
  // from the test leaves the shared testbench untouched. It has to happen before any simulation time passes: the shim
  // sets bus_enum_skip_vf_enable=1 in setup_vip() (called from test_base.start_of_simulation_phase) and the VIP
  // enumerates by itself (auto_enum) as soon as the link is up, which is only a few us after the CDO load. So the
  // settings are applied here, right after the shim defaults, not from pre_enum_seq().
  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    env.shim.vip.set("bus_enum_skip_vf_enable", 0);
    env.shim.vip.cfg_info.ARI_sup = 1;                 // VFs of the higher PFs need ARI (function numbers > 7)
    for (int pfi=0; pfi<8; pfi++) env.shim.vip.cfg_info.sriov_num_vfs[pfi] = N_VF;
    `uvm_info("SRIOV", $sformatf("VF enumeration enabled from the test: %0d VFs per PF, ARI_sup=1", N_VF), UVM_NONE)
  endfunction

`ifdef CPM6_VIVADO
  // This design's CDO ends with `mask_write 0xFC840100 0x10040 0x40`, i.e. it leaves
  // CPM6_PCIE_CORE0.ATTR_REG_0.app_req_retry_en (bit 6) SET ("defer incoming configuration requests until
  // initialization is complete"). The 8PF design's CDO ends with `0x10040 0x0` (cleared). With the bit set the
  // controller completes EVERY config request with CRS, so bus enumeration never completes. On hardware the
  // firmware releases it once the PL is ready; nothing does that in simulation, so do it here after the CDO load.
  virtual task post_cdo_load();
    super.post_cdo_load();
    if (!$test$plusargs("KEEP_CFG_RETRY")) begin
      // Unlock the core registers, clear ATTR_REG_0.app_req_retry_en (bit 6), re-lock. The 2026.2 CDO re-locks the core
      // registers, which silently drops a plain read-modify-write. This is the sequence the framework's current
      // seq_disable_crs performs; it is done here with the testbench's cdo_write / cdo_mask_write helpers because the
      // shared seq_disable_crs in this testbench is still the older plain read-modify-write version.
      // Core base 0xFC840000 (Controller 0 core). This design is single-controller.
      cdo_write     (32'hFC840000 + 32'h0,   32'h0);      // unlock
      cdo_write     (32'hFC840000 + 32'h4,   32'h0);
      cdo_mask_write(32'hFC840000 + 32'h100, 32'h40, 32'h0);   // ATTR_REG_0.app_req_retry_en = 0
      cdo_write     (32'hFC840000 + 32'h4,   32'h1);      // re-lock
      cdo_write     (32'hFC840000 + 32'h0,   32'h1);
      `uvm_info("SRIOV_CFGRETRY", "ATTR_REG_0.app_req_retry_en (bit 6) cleared (unlock / clear / re-lock) after CDO load; +KEEP_CFG_RETRY keeps the CDO value", UVM_NONE)
    end
  endtask
`endif

  virtual function void connect_phase(uvm_phase phase);
    phase.raise_objection(this);
    super.connect_phase(phase);
    phase.drop_objection(this);
  endfunction

  // ---------------------------------------------------------------------------
  // Raw 1-DW memory write / read at an absolute address (4-byte aligned)
  // ---------------------------------------------------------------------------
  virtual task fn_mwr(input bit [63:0] addr, input bit [31:0] wdata);
    logic [31:0] data_arr[];
    data_arr = {wdata};
    tlp.build_wr(addr, .length(1), .data(data_arr), .f_be(4'b1111), .l_be(4'b0000), .blocking(NONBLOCK));
    env.shim.api.send_mem(tlp);
  endtask

  virtual task fn_mrd(input bit [63:0] addr, output bit [31:0] rdata);
    tlp.build_rd(addr, .length(1), .f_be(4'b1111), .l_be(4'b0000), .blocking(DONE));
    env.shim.api.send_mem(tlp);
    rdata = tlp.data[0];
  endtask

  // BAR base of function idx (PF or VF)
  virtual function bit fn_get_bar(input int idx, input int bar_num, output mem_bar_s mb);
    int pf, vf;
    pf = funcs[idx].pf;
    vf = funcs[idx].vf;
    if (vf < 0) return pdev_ep[pf].get_membar(bar_num, mb);
    else        return pdev_ep[pf].vf[vf+1].get_membar(bar_num, mb);   // vf[0] is a null placeholder
  endfunction

  // ---------------------------------------------------------------------------
  // Gate 1: did the VIP enumerate 8 PFs and 4 VFs per PF?
  // ---------------------------------------------------------------------------
  virtual task check_enumeration();
    bit bad;
    bad = 1'b0;
    `uvm_info("SRIOV_ENUM", $sformatf("pdev_ep.size() = %0d (expect %0d PFs)", pdev_ep.size(), N_PF), UVM_NONE)
    if (pdev_ep.size() < N_PF) `uvm_fatal("SRIOV_ENUM", "fewer PFs enumerated than expected")
    for (int pf=0; pf<N_PF; pf++) begin
      `uvm_info("SRIOV_ENUM", $sformatf(
        "PF%0d bdf=0x%04h vf_enable=%0b vf_mse=%0b total_vfs=%0d num_vfs=%0d first_vf_offset=%0d vf_stride=%0d vf[] entries=%0d (incl. null slot 0)",
        pf, pdev_ep[pf].bdf, pdev_ep[pf].sriov.vf_enable, pdev_ep[pf].sriov.vf_mse, pdev_ep[pf].sriov.total_vfs,
        pdev_ep[pf].sriov.num_vfs, pdev_ep[pf].sriov.first_vf_offset, pdev_ep[pf].sriov.vf_stride,
        pdev_ep[pf].vf.size()), UVM_NONE)
      for (int v=1; v<pdev_ep[pf].vf.size(); v++)
        `uvm_info("SRIOV_ENUM", $sformatf("  PF%0d VF%0d bdf=0x%04h", pf, v-1, pdev_ep[pf].vf[v].bdf), UVM_NONE)
      if (pdev_ep[pf].vf.size() < N_VF + 1) begin
        `uvm_error("SRIOV_ENUM", $sformatf("PF%0d: %0d VFs enumerated, expected %0d (was +ENABLE_VF given?)", pf, pdev_ep[pf].vf.size()-1, N_VF))
        bad = 1'b1;
      end
    end
    if (bad) `uvm_fatal("SRIOV_ENUM", "VF enumeration incomplete, stopping")
  endtask

  // ---------------------------------------------------------------------------
  // Build the 40-entry function table: BDF, BAR1 base, MSI-X table location
  // ---------------------------------------------------------------------------
  virtual task fn_get_msix_info(input int idx);
    bit        err0, err1;
    bit [31:0] dw0, dw1;
    int        tbl_bir;
    bit [31:0] tbl_off;
    mem_bar_s  mb;
    env.shim.api.read_cap_dw(funcs[idx].bdf, .cap(CAP_MSI_X), .offset(0), .data(dw0), .err(err0));
    env.shim.api.read_cap_dw(funcs[idx].bdf, .cap(CAP_MSI_X), .offset(1), .data(dw1), .err(err1));
    funcs[idx].num_vec = dw0[26:16] + 1;
    tbl_bir = dw1[2:0];
    tbl_off = {dw1[31:3], 3'b000};
    if (err0 || err1)
      `uvm_error("SRIOV_MSIX", $sformatf("chan %0d: MSI-X capability read error", idx))
    if (!fn_get_bar(idx, tbl_bir, mb)) begin
      `uvm_error("SRIOV_MSIX", $sformatf("chan %0d: no BAR%0d for the MSI-X table", idx, tbl_bir))
      funcs[idx].msix_tbl = '0;
    end else begin
      funcs[idx].msix_tbl = mb.base + tbl_off;
    end
    `uvm_info("SRIOV_MSIX", $sformatf("chan %0d (PF%0d %s): vectors=%0d table=BAR%0d+0x%0h abs=0x%0h",
              idx, funcs[idx].pf, (funcs[idx].vf < 0) ? "PF" : $sformatf("VF%0d", funcs[idx].vf),
              funcs[idx].num_vec, tbl_bir, tbl_off, funcs[idx].msix_tbl), UVM_NONE)
  endtask

  virtual task build_func_table();
    mem_bar_s mb;
    int       chan;
    for (int pf=0; pf<N_PF; pf++) begin
      for (int v=-1; v<N_VF; v++) begin
        chan = (v + 1) * N_PF + pf;
        funcs[chan].pf   = pf;
        funcs[chan].vf   = v;
        funcs[chan].chan = chan;
        if (v < 0) funcs[chan].bdf = pdev_ep[pf].bdf;
        else       funcs[chan].bdf = pdev_ep[pf].vf[v+1].bdf;
        if (!fn_get_bar(chan, 1, mb))
          `uvm_fatal("SRIOV_BAR", $sformatf("chan %0d (PF%0d VF%0d): BAR1 not found", chan, pf, v))
        if (mb.base === 64'hx || mb.base == 0)
          `uvm_fatal("SRIOV_BAR", $sformatf("chan %0d (PF%0d VF%0d): BAR1 base is 0/X", chan, pf, v))
        funcs[chan].bar1_base = mb.base;
        `uvm_info("SRIOV_FUNC", $sformatf("chan %2d: PF%0d %s bdf=0x%04h BAR1=0x%0h",
                  chan, pf, (v < 0) ? "PF " : $sformatf("VF%0d", v), funcs[chan].bdf, mb.base), UVM_NONE)
        fn_get_msix_info(chan);
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Register sanity per function: version and chn_local_num
  // ---------------------------------------------------------------------------
  virtual task check_registers();
    bit [31:0] v, c;
    for (int idx=0; idx<N_FUNC; idx++) begin
      fn_mrd(funcs[idx].bar1_base + 32'h00, v);
      fn_mrd(funcs[idx].bar1_base + 32'h50, c);
      // bit 15 is the multi-function flag (axil_slave.sv), so 0xAA008003 is the expected value here
      if ((v & 32'hFFFF_7FFF) != 32'hAA000003)
        `uvm_warning("SRIOV_REG", $sformatf("chan %0d: BAR1 version = 0x%08h (expected 0xAA000003, bit 15 = multi-function flag)", idx, v))
      if (c[5:0] != idx)
        `uvm_error("SRIOV_REG", $sformatf("chan %0d (PF%0d VF%0d): chn_local_num = %0d, expected %0d",
                   idx, funcs[idx].pf, funcs[idx].vf, c, idx))
      else
        `uvm_info("SRIOV_REG", $sformatf("chan %0d: version=0x%08h chn_local_num=%0d OK", idx, v, c), UVM_NONE)
    end
  endtask

  // ---------------------------------------------------------------------------
  // CPM6 HDMA FUNC_NUM for every channel, through PF0 BAR0 (docs: hdma_ddr_top_description.md)
  //   C2H: ch*0x400 + 0x38    H2C: 0x200 + ch*0x400 + 0x38
  //   data: [4:0]=pf  [16]=vf_en  [24:17]=vf
  // ---------------------------------------------------------------------------
  virtual task prog_hdma_func_num();
    bit [31:0] d;
    int        vfn;
    for (int ch=0; ch<N_FUNC; ch++) begin
      vfn = (funcs[ch].vf < 0) ? 0 : (vfnum_global ? (funcs[ch].pf * N_VF + funcs[ch].vf) : funcs[ch].vf);
      d = '0;
      d[4:0]   = funcs[ch].pf;
      d[16]    = (funcs[ch].vf >= 0);
      d[24:17] = vfn;
      csr_write((ch * 32'h400) + 32'h38,         d);   // C2H FUNC_NUM
      csr_write(32'h200 + (ch * 32'h400) + 32'h38, d);   // H2C FUNC_NUM
    end
    `uvm_info("SRIOV_FUNCNUM", $sformatf("HDMA FUNC_NUM programmed for %0d channels (vf field = %s)",
              N_FUNC, vfnum_global ? "global VF index" : "PF-relative"), UVM_NONE)
  endtask

  // ---------------------------------------------------------------------------
  // MSI-X: program the function's own table and enable MSI-X in its own capability
  // ---------------------------------------------------------------------------
  virtual task prog_msix(input int idx);
    bit [31:0] dw0;
    bit        err;
    for (int i=0; i<funcs[idx].num_vec; i++) begin
      fn_mwr(funcs[idx].msix_tbl + 16*i + 0,  32'h00000000);                      // msg addr lo
      fn_mwr(funcs[idx].msix_tbl + 16*i + 4,  32'hADD00000);                      // msg addr hi
      fn_mwr(funcs[idx].msix_tbl + 16*i + 8,  32'hDEAD0000 | (idx << 4) | i);     // msg data: channel + vector
      fn_mwr(funcs[idx].msix_tbl + 16*i + 12, 32'h00000000);                      // vector control (unmasked)
    end
    // Without MSI-X enable on this function CPM6 drops the interrupt
    env.shim.api.read_cap_dw(funcs[idx].bdf, .cap(CAP_MSI_X), .offset(0), .data(dw0), .err(err));
    dw0[31] = 1'b1;   // msix_enable
    dw0[30] = 1'b0;   // function mask off
    env.shim.api.write_cap_dw(funcs[idx].bdf, .cap(CAP_MSI_X), .offset(0), .be(4'b1100), .data(dw0), .err(err));
    `uvm_info("SRIOV_MSIX", $sformatf("chan %0d: MSI-X table programmed (%0d vectors) and enabled", idx, funcs[idx].num_vec), UVM_NONE)
  endtask

  // ---------------------------------------------------------------------------
  // On a missing interrupt: dump the PL debug registers (BAR1, design map) and the HDMA channel
  // registers (PF0 BAR0: C2H ch*0x400, H2C 0x200 + ch*0x400) so the failure can be diagnosed from the log.
  // ---------------------------------------------------------------------------
  virtual task dump_pl_debug(input int idx, input bit is_c2h);
    bit [31:0]  v;
    bit [63:0]  bar1;
    mem_bar_s   mb0;
    bit [63:0]  hbase;
    int         pl_off[$];
    int         ch_off[$];
    bar1 = funcs[idx].bar1_base;
    pl_off = '{32'h24, 32'h44, 32'h4C, 32'h50, 32'h60, 32'h64, 32'h68, 32'h6C, 32'h70, 32'h74,
               32'h78, 32'h7C, 32'h80, 32'h84, 32'h88, 32'h8C, 32'h90};
    `uvm_info("SRIOV_DBG", $sformatf("---- PL debug dump, chan %0d (%s), BAR1 regs ----", idx, is_c2h ? "C2H" : "H2C"), UVM_NONE)
    foreach (pl_off[i]) begin
      fn_mrd(bar1 + pl_off[i], v);
      `uvm_info("SRIOV_DBG", $sformatf("  BAR1+0x%02h = 0x%08h", pl_off[i], v), UVM_NONE)
    end
    if (fn_get_bar(0, 0, mb0)) begin
      hbase = mb0.base + (is_c2h ? 0 : 32'h200) + (idx * 32'h400);
      ch_off = '{32'h00, 32'h04, 32'h1C, 32'h20, 32'h24, 32'h28, 32'h2C, 32'h38, 32'h84, 32'h88, 32'h8C};
      `uvm_info("SRIOV_DBG", $sformatf("---- HDMA channel regs (PF0 BAR0 + 0x%0h) ----", hbase - mb0.base), UVM_NONE)
      foreach (ch_off[i]) begin
        fn_mrd(hbase + ch_off[i], v);
        `uvm_info("SRIOV_DBG", $sformatf("  HDMA+0x%02h = 0x%08h", ch_off[i], v), UVM_NONE)
      end
    end
  endtask

  // Bounded wait for the MSI-X of the DMA just triggered on function idx
  virtual task wait_irq(input int idx, input bit is_c2h);
    bit got;
    got = 1'b0;
    fork
      begin wait (mem_cb.int_msix_set == 1); got = 1'b1; end
      begin #50us; end
    join_any
    disable fork;
    if (!got) begin
      `uvm_error("SRIOV_IRQ", $sformatf("chan %0d (PF%0d %s) %s: no MSI-X within 50us (EP->host reads=%0d writes=%0d msix_cnt=%0d)",
                 idx, funcs[idx].pf, (funcs[idx].vf < 0) ? "PF" : $sformatf("VF%0d", funcs[idx].vf), is_c2h ? "C2H" : "H2C",
                 mem_cb.dbg_rd_cnt, mem_cb.dbg_wr_cnt, mem_cb.dbg_msix_cnt))
      dump_pl_debug(idx, is_c2h);
      `uvm_fatal("SRIOV_IRQ", "interrupt not received, stopping")
    end
    mem_cb.int_msix_set = 0;
    `uvm_info("MSIX Interrupt", $sformatf("chan %0d %s Transfer Completed with MSIX interrupt", idx, is_c2h ? "C2H" : "H2C"), UVM_NONE)
  endtask

  // ---------------------------------------------------------------------------
  // One function: H2C then C2H, MSI-X completion, interrupt clear
  // ---------------------------------------------------------------------------
  virtual task do_dma(input int idx);
    bit [63:0] bar1, host_addr, dev_addr;
    bit [31:0] st;
    bar1      = funcs[idx].bar1_base;
    host_addr = {$urandom, 6'h0};
    // PL-AXI 1 (CPM6 DMA aperture 1, 8KB axi_bram_ctrl_1). Not PL-AXI 0 (0x0500_0001_0000): on this design the
    // M00_AXI_0/Reg window on that port is 256KB and BRAM0 moved to 0xC000_0000, so 0x0500_0001_0000 hits the registers.
    dev_addr  = 64'h0500_0002_0000;                    // PL-AXI 1 BRAM

    `uvm_info("---- H2C DMA ---- ", $sformatf("chan %0d PF%0d %s (trigger = BAR1+0x40)", idx, funcs[idx].pf,
              (funcs[idx].vf < 0) ? "PF" : $sformatf("VF%0d", funcs[idx].vf)), UVM_NONE)
    fn_mwr(bar1 + 32'h30, 32'h100);                    // H2C size
    fn_mwr(bar1 + 32'h34, host_addr[31:0]);            // src lo
    fn_mwr(bar1 + 32'h38, host_addr[63:32]);           // src hi
    fn_mwr(bar1 + 32'h3c, dev_addr[31:0]);             // dst lo
    fn_mwr(bar1 + 32'h40, dev_addr[63:32]);            // dst hi (trigger)
    wait_irq(idx, 1'b0);
    fn_mrd(bar1 + 32'h44, st);
    `uvm_info("SRIOV_DMA", $sformatf("chan %0d H2C irq status = 0x%08h", idx, st), UVM_NONE)
    fn_mwr(bar1 + 32'h48, 32'h1);                      // H2C irq clear

    `uvm_info("---- C2H DMA ---- ", $sformatf("chan %0d PF%0d %s (trigger = BAR1+0x20)", idx, funcs[idx].pf,
              (funcs[idx].vf < 0) ? "PF" : $sformatf("VF%0d", funcs[idx].vf)), UVM_NONE)
    fn_mwr(bar1 + 32'h10, 32'h100);                    // C2H size
    fn_mwr(bar1 + 32'h14, dev_addr[31:0]);             // src lo
    fn_mwr(bar1 + 32'h18, dev_addr[63:32]);            // src hi
    fn_mwr(bar1 + 32'h1c, host_addr[31:0]);            // dst lo
    fn_mwr(bar1 + 32'h20, host_addr[63:32]);           // dst hi (trigger)
    wait_irq(idx, 1'b1);
    fn_mrd(bar1 + 32'h24, st);
    `uvm_info("SRIOV_DMA", $sformatf("chan %0d C2H irq status = 0x%08h", idx, st), UVM_NONE)
    fn_mwr(bar1 + 32'h28, 32'h1);                      // C2H irq clear
  endtask

  virtual function bit in_scope(input int idx);
    case (vf_mode)
      1:       return (funcs[idx].vf < 0);             // PFs only
      2:       return (idx == N_PF);                   // PF0-VF0 (channel 8)
      default: return 1'b1;                            // all functions
    endcase
  endfunction

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name, $sformatf("VF_MODE=%0d VF_ITER=%0d, %0d PFs x %0d VFs", vf_mode, vf_iter, N_PF, N_VF), UVM_NONE)

    check_enumeration();
    build_func_table();
    check_registers();

    if (vf_mode == 0) begin
      `uvm_info(get_type_name, "VF_MODE=0: enumeration and register checks only, no DMA", UVM_NONE)
    end else begin
      dma_ctxt_init_prog(N_FUNC);        // enable channels + stop-interrupt for all 40 channels
      prog_hdma_func_num();
      for (int idx=0; idx<N_FUNC; idx++)
        if (in_scope(idx)) prog_msix(idx);
      `uvm_info(get_type_name, "MSI-X vector tables programmed and enabled for all functions in scope", UVM_NONE)

      for (int it=0; it<vf_iter; it++) begin
        for (int idx=0; idx<N_FUNC; idx++)
          if (in_scope(idx)) do_dma(idx);
        `uvm_info(get_type_name, $sformatf("iteration %0d complete", it), UVM_NONE)
      end
    end

    // Wait for some time before exit
    #10000ns;

    phase.drop_objection(this);
  endtask

endclass
