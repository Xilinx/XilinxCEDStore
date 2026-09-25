// pswizard_monitor.sv  - Passive UVM monitor for the pswizard interface
//
// Observes CPM_PCIE_AXI_NOC0 and CPM_PCIE_AXI_NOC1 AXI handshakes plus the
// DMA completion IRQ vector (dma_irq[127:0]).  Emits pswizard_txn items on
// the analysis port and logs events to the shared log file (cpm6_qdma_dbg.log).
//
// Events captured on each clock posedge (#1ps settle):
//   PSW_NOC_AW   - awvalid & awready  (either NOC port)
//   PSW_NOC_W    - wvalid  & wready  & wlast  (either NOC port)
//   PSW_NOC_B    - bvalid  & bready  (either NOC port)
//   PSW_NOC_AR   - arvalid & arready  (either NOC port)
//   PSW_NOC_R    - rvalid  & rready  & rlast  (either NOC port)
//   PSW_DMA_IRQ  - any bit of dma_irq newly goes high
//   PSW_RESET    - rst_n first goes high after reset
//
// Address filtering: when cfg.addr_filter_hi != 0, only log NOC events whose
// address falls within [addr_filter_lo, addr_filter_hi].
class pswizard_monitor extends uvm_monitor;

  `uvm_component_utils(pswizard_monitor)

  virtual pswizard_if              vif;
  pswizard_cfg                     cfg;
  uvm_analysis_port#(pswizard_txn) ap;

  local int    log_fd;
  int          check_err_count = 0;

  // ---- MSI-X control-FSM observation (optional, MSIX_CTRL_MON) -----------
  // Present only when bind.pswizard_msix.sv was compiled. The get is soft:
  // absence disables the sampling task and is reported once, rather than
  // uvm_fatal-ing, because the bind is gated OFF by default (it requires the
  // decrypted cpm6 rfs -- see bind.pswizard_msix.sv header).
  virtual pswizard_msix_if msix_vif;
  bit                      msix_mon_en = 1'b0;

  local int unsigned cnt_msix_lookup;
  local int unsigned cnt_msix_disabled;
  local int unsigned cnt_msix_index_skew;
  // Distinct index values observed for PF0 requests, so a summary cannot be
  // read as coverage the run does not have.
  local bit          idx_seen[int];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pswizard_if)::get(this, "", "vif", vif))
      `uvm_fatal("pswizard_monitor", "Failed to get virtual pswizard_if from config_db")
    if (!uvm_config_db#(pswizard_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("pswizard_monitor", "Failed to get pswizard_cfg from config_db")
    if (!uvm_config_db#(int)::get(this, "", "log_fd", log_fd))
      `uvm_fatal("pswizard_monitor", "Failed to get shared log_fd from config_db")
    msix_mon_en = uvm_config_db#(virtual pswizard_msix_if)::get(
                    this, "", "vif_psw_msix", msix_vif);
  endfunction

  // ---- Address filter helper ----
  local function bit addr_pass(logic [63:0] a);
    if (cfg.addr_filter_hi == 64'h0) return 1'b1;
    return (a >= cfg.addr_filter_lo && a <= cfg.addr_filter_hi);
  endfunction

  // ---- cpm_noc0 / cpm_axi_pl0/1/3 channel decode ----
  // slot_id = addr / SLOT_SIZE_BYTES, slot_id == HDMA channel ID directly
  // (dsc_slot_params_pkg imported via pkg.pswizard_agent.sv). No qid step --
  // a channel<->qid heuristic was found to be inaccurate.
  local function logic [6:0] decode_noc_channel(logic [63:0] addr);
    return logic'(addr / SLOT_SIZE_BYTES);
  endfunction

  // ---- dma_irq[N] channel role — duplicated from qdma_periph_monitor.sv's
  // decode_dbi_ch_name() (small per-agent helper, not worth a shared header
  // for 4 entries). Indices 4+ are the scheduler's dynamically-allocated
  // pool — direction is NOT statically known from the channel index alone.
  local function string irq_ch_role(int ch);
    case (ch)
      0: return "WRCH_0/wb_desc_writer dir=C2H";
      1: return "RDCH_0/cmpt_desc_writer dir=C2H";
      2: return "WRCH_1/dsc_fetch_engine dir=H2C";
      3: return "RDCH_1/dsc_fetch_engine dir=H2C";
      default: return "dir=UNKNOWN(dynamic channel)";
    endcase
  endfunction

  // ---- Emit one transaction and log it ----
  local function void emit(pswizard_txn txn);
    string detail;
    `uvm_info("pswizard_monitor", txn.convert2string(), UVM_MEDIUM)
    detail = (txn.txn_type == pswizard_txn::PSW_DMA_IRQ)
        ? $sformatf("irq=0x%032h", txn.irq_new)
      : (txn.txn_type inside
           {pswizard_txn::PSW_NOC_AW, pswizard_txn::PSW_NOC_AR})
        ? $sformatf("noc%0d  addr=0x%016h  id=0x%04h  len=%0d  sz=%0d  bytes_est=%0d%s",
            txn.port, txn.addr, txn.id, txn.len, txn.size, txn.bytes,
            txn.chan_valid ? $sformatf("  ch=%0d", txn.chan) : "")
      : (txn.txn_type == pswizard_txn::PSW_NOC_B)
        ? $sformatf("noc%0d  bid=0x%04h  resp=%0d", txn.port, txn.bid, txn.bresp)
      : (txn.txn_type == pswizard_txn::PSW_NOC_R)
        ? $sformatf("noc%0d  rid=0x%04h  resp=%0d", txn.port, txn.rid, txn.rresp)
      : (txn.txn_type == pswizard_txn::PSW_NOC_W)
        ? $sformatf("noc%0d  w_bytes=%0d", txn.port, txn.w_bytes)
      : (txn.txn_type inside
           {pswizard_txn::PSW_PL_AW, pswizard_txn::PSW_PL_AR})
        ? $sformatf("pl%0d  addr=0x%016h  id=0x%04h  len=%0d  sz=%0d  bytes_est=%0d%s",
            txn.pl_port, txn.addr, txn.id, txn.len, txn.size, txn.bytes,
            txn.chan_valid ? $sformatf("  ch=%0d", txn.chan) : "")
      : (txn.txn_type == pswizard_txn::PSW_PL_B)
        ? $sformatf("pl%0d  bid=0x%04h  resp=%0d", txn.pl_port, txn.bid, txn.bresp)
      : (txn.txn_type == pswizard_txn::PSW_PL_R)
        ? $sformatf("pl%0d  rid=0x%04h  resp=%0d", txn.pl_port, txn.rid, txn.rresp)
      : (txn.txn_type == pswizard_txn::PSW_PL_W)
        ? $sformatf("pl%0d  w_bytes=%0d", txn.pl_port, txn.w_bytes)
      : "";
    $fdisplay(log_fd, "%9t ns  PSW   %-12s  %s",
      txn.timestamp_ns, txn.txn_type.name(), detail);
    $fflush(log_fd);
    ap.write(txn);
  endfunction

  // ---- Sample one NOC port per clock cycle ----
  // port_sel: 0 = NOC0, 1 = NOC1
  local task sample_noc_port(input logic port_sel);
    // Capture signals for the selected port
    logic        awvalid, awready, wvalid, wready, wlast;
    logic        bvalid,  bready,  arvalid, arready, rvalid, rready, rlast;
    logic [63:0] awaddr, araddr;
    logic [15:0] awid,   arid,   bid,   rid;
    logic [7:0]  awlen,  arlen;
    logic [2:0]  awsize, arsize;
    logic [1:0]  awburst, arburst, bresp, rresp;
    logic [15:0] wstrb_hi;

    if (port_sel == 1'b0) begin
      awvalid = vif.noc0_awvalid; awready = vif.noc0_awready;
      awaddr  = vif.noc0_awaddr;  awid    = vif.noc0_awid;
      awlen   = vif.noc0_awlen;   awsize  = vif.noc0_awsize;
      awburst = vif.noc0_awburst;
      wvalid  = vif.noc0_wvalid;  wready  = vif.noc0_wready;
      wlast   = vif.noc0_wlast;   wstrb_hi = vif.noc0_wstrb[15:0];
      bvalid  = vif.noc0_bvalid;  bready  = vif.noc0_bready;
      bid     = vif.noc0_bid;     bresp   = vif.noc0_bresp;
      arvalid = vif.noc0_arvalid; arready = vif.noc0_arready;
      araddr  = vif.noc0_araddr;  arid    = vif.noc0_arid;
      arlen   = vif.noc0_arlen;   arsize  = vif.noc0_arsize;
      arburst = vif.noc0_arburst;
      rvalid  = vif.noc0_rvalid;  rready  = vif.noc0_rready;
      rlast   = vif.noc0_rlast;   rid     = vif.noc0_rid;
      rresp   = vif.noc0_rresp;
    end else begin
      awvalid = vif.noc1_awvalid; awready = vif.noc1_awready;
      awaddr  = vif.noc1_awaddr;  awid    = vif.noc1_awid;
      awlen   = vif.noc1_awlen;   awsize  = vif.noc1_awsize;
      awburst = vif.noc1_awburst;
      wvalid  = vif.noc1_wvalid;  wready  = vif.noc1_wready;
      wlast   = vif.noc1_wlast;   wstrb_hi = vif.noc1_wstrb[15:0];
      bvalid  = vif.noc1_bvalid;  bready  = vif.noc1_bready;
      bid     = vif.noc1_bid;     bresp   = vif.noc1_bresp;
      arvalid = vif.noc1_arvalid; arready = vif.noc1_arready;
      araddr  = vif.noc1_araddr;  arid    = vif.noc1_arid;
      arlen   = vif.noc1_arlen;   arsize  = vif.noc1_arsize;
      arburst = vif.noc1_arburst;
      rvalid  = vif.noc1_rvalid;  rready  = vif.noc1_rready;
      rlast   = vif.noc1_rlast;   rid     = vif.noc1_rid;
      rresp   = vif.noc1_rresp;
    end

    // AW handshake
    if (awvalid && awready && addr_pass(awaddr)) begin
      pswizard_txn txn = pswizard_txn::type_id::create("psw_aw");
      txn.txn_type = pswizard_txn::PSW_NOC_AW;
      txn.port = port_sel; txn.timestamp_ns = $time;
      txn.addr = awaddr; txn.id = awid;
      txn.len = awlen; txn.size = awsize; txn.burst = awburst;
      txn.bytes = (longint'(awlen) + 1) << awsize;
      // Channel decode is NOC0-only per explicit user scope (NOC1 out of scope).
      if (port_sel == 1'b0) begin
        txn.chan = decode_noc_channel(awaddr);
        txn.chan_valid = 1'b1;
      end
      emit(txn);
    end

    // W last beat
    if (wvalid && wready && wlast) begin
      pswizard_txn txn = pswizard_txn::type_id::create("psw_w");
      txn.txn_type = pswizard_txn::PSW_NOC_W;
      txn.port = port_sel; txn.timestamp_ns = $time;
      txn.wstrb_np = wstrb_hi;
      txn.w_bytes  = $countones(wstrb_hi);
      emit(txn);
    end

    // B handshake
    if (bvalid && bready) begin
      pswizard_txn txn = pswizard_txn::type_id::create("psw_b");
      txn.txn_type = pswizard_txn::PSW_NOC_B;
      txn.port = port_sel; txn.timestamp_ns = $time;
      txn.bid = bid; txn.bresp = bresp;
      emit(txn);
      if (cfg.checks_enable && bresp != 2'b00) begin
        `uvm_error("pswizard_monitor", $sformatf("AXI B response error (SLVERR/DECERR) on NOC port %0d: resp=%0d",
          port_sel, bresp))
        check_err_count++;
      end
    end

    // AR handshake
    if (arvalid && arready && addr_pass(araddr)) begin
      pswizard_txn txn = pswizard_txn::type_id::create("psw_ar");
      txn.txn_type = pswizard_txn::PSW_NOC_AR;
      txn.port = port_sel; txn.timestamp_ns = $time;
      txn.addr = araddr; txn.id = arid;
      txn.len = arlen; txn.size = arsize; txn.burst = arburst;
      txn.bytes = (longint'(arlen) + 1) << arsize;
      if (port_sel == 1'b0) begin
        txn.chan = decode_noc_channel(araddr);
        txn.chan_valid = 1'b1;
      end
      emit(txn);
    end

    // R last beat
    if (rvalid && rready && rlast) begin
      pswizard_txn txn = pswizard_txn::type_id::create("psw_r");
      txn.txn_type = pswizard_txn::PSW_NOC_R;
      txn.port = port_sel; txn.timestamp_ns = $time;
      txn.rid = rid; txn.rresp = rresp;
      emit(txn);
      if (cfg.checks_enable && rresp != 2'b00) begin
        `uvm_error("pswizard_monitor", $sformatf("AXI R response error on NOC port %0d: resp=%0d",
          port_sel, rresp))
        check_err_count++;
      end
    end
  endtask

  // ---- Sample one cpm_axi_pl port per clock cycle ----
  // pl_sel: 0 = pl0, 1 = pl1, 3 = pl3 (ENABLE_PL3_BIND only). No pl2 — does
  // not exist on this BD (see pswizard_if.sv header note).
  // Event logging only -- BRESP/RRESP are captured into the transaction but
  // not checked against OKAY here (unlike the NOC-port sampling above); this
  // task exists so PL activity shows up in the same timeline as PSW_DMA_IRQ.
  local task sample_pl_port(input int pl_sel);
    logic        awvalid, awready, wvalid, wready, wlast;
    logic        bvalid,  bready,  arvalid, arready, rvalid, rready, rlast;
    logic [50:0] awaddr, araddr;
    logic [9:0]  awid,   arid,   bid,   rid;
    logic [7:0]  awlen,  arlen;
    logic [2:0]  awsize, arsize;
    logic [1:0]  awburst, arburst, bresp, rresp;
    logic [15:0] wstrb_hi;

    case (pl_sel)
      0: begin
        awvalid = vif.pl0_awvalid; awready = vif.pl0_awready;
        awaddr  = vif.pl0_awaddr;  awid    = vif.pl0_awid;
        awlen   = vif.pl0_awlen;   awsize  = vif.pl0_awsize;
        awburst = vif.pl0_awburst;
        wvalid  = vif.pl0_wvalid;  wready  = vif.pl0_wready;
        wlast   = vif.pl0_wlast;   wstrb_hi = vif.pl0_wstrb[15:0];
        bvalid  = vif.pl0_bvalid;  bready  = vif.pl0_bready;
        bid     = vif.pl0_bid;     bresp   = vif.pl0_bresp;
        arvalid = vif.pl0_arvalid; arready = vif.pl0_arready;
        araddr  = vif.pl0_araddr;  arid    = vif.pl0_arid;
        arlen   = vif.pl0_arlen;   arsize  = vif.pl0_arsize;
        arburst = vif.pl0_arburst;
        rvalid  = vif.pl0_rvalid;  rready  = vif.pl0_rready;
        rlast   = vif.pl0_rlast;   rid     = vif.pl0_rid;
        rresp   = vif.pl0_rresp;
      end
      1: begin
        awvalid = vif.pl1_awvalid; awready = vif.pl1_awready;
        awaddr  = vif.pl1_awaddr;  awid    = vif.pl1_awid;
        awlen   = vif.pl1_awlen;   awsize  = vif.pl1_awsize;
        awburst = vif.pl1_awburst;
        wvalid  = vif.pl1_wvalid;  wready  = vif.pl1_wready;
        wlast   = vif.pl1_wlast;   wstrb_hi = vif.pl1_wstrb[15:0];
        bvalid  = vif.pl1_bvalid;  bready  = vif.pl1_bready;
        bid     = vif.pl1_bid;     bresp   = vif.pl1_bresp;
        arvalid = vif.pl1_arvalid; arready = vif.pl1_arready;
        araddr  = vif.pl1_araddr;  arid    = vif.pl1_arid;
        arlen   = vif.pl1_arlen;   arsize  = vif.pl1_arsize;
        arburst = vif.pl1_arburst;
        rvalid  = vif.pl1_rvalid;  rready  = vif.pl1_rready;
        rlast   = vif.pl1_rlast;   rid     = vif.pl1_rid;
        rresp   = vif.pl1_rresp;
      end
`ifdef ENABLE_PL3_BIND
      3: begin
        awvalid = vif.pl3_awvalid; awready = vif.pl3_awready;
        awaddr  = vif.pl3_awaddr;  awid    = vif.pl3_awid;
        awlen   = vif.pl3_awlen;   awsize  = vif.pl3_awsize;
        awburst = vif.pl3_awburst;
        wvalid  = vif.pl3_wvalid;  wready  = vif.pl3_wready;
        wlast   = vif.pl3_wlast;   wstrb_hi = vif.pl3_wstrb[15:0];
        bvalid  = vif.pl3_bvalid;  bready  = vif.pl3_bready;
        bid     = vif.pl3_bid;     bresp   = vif.pl3_bresp;
        arvalid = vif.pl3_arvalid; arready = vif.pl3_arready;
        araddr  = vif.pl3_araddr;  arid    = vif.pl3_arid;
        arlen   = vif.pl3_arlen;   arsize  = vif.pl3_arsize;
        arburst = vif.pl3_arburst;
        rvalid  = vif.pl3_rvalid;  rready  = vif.pl3_rready;
        rlast   = vif.pl3_rlast;   rid     = vif.pl3_rid;
        rresp   = vif.pl3_rresp;
      end
`endif
      default: return;
    endcase

    if (awvalid && awready) begin
      pswizard_txn txn = pswizard_txn::type_id::create("psw_pl_aw");
      txn.txn_type = pswizard_txn::PSW_PL_AW;
      txn.pl_port = pl_sel; txn.timestamp_ns = $time;
      txn.addr = {13'h0, awaddr}; txn.id = {6'h0, awid};
      txn.len = awlen; txn.size = awsize; txn.burst = awburst;
      txn.bytes = (longint'(awlen) + 1) << awsize;
      // PL0=H2C, PL1=C2H (reference_c2h_all_on_axi_pl1_by_design.md); PL3
      // gated behind ENABLE_PL3_BIND like the rest of its treatment — dead
      // code on the current BD (PL3 removed, see bind.axi_pl.sv). Same
      // decode_noc_channel() formula reused, assuming PL0/1/3 addresses are
      // in the same host-facing space as NOC0.
      txn.chan = decode_noc_channel(txn.addr);
      txn.chan_valid = 1'b1;
      emit(txn);
    end

    if (wvalid && wready && wlast) begin
      pswizard_txn txn = pswizard_txn::type_id::create("psw_pl_w");
      txn.txn_type = pswizard_txn::PSW_PL_W;
      txn.pl_port = pl_sel; txn.timestamp_ns = $time;
      txn.wstrb_np = wstrb_hi;
      txn.w_bytes  = $countones(wstrb_hi);
      emit(txn);
    end

    if (bvalid && bready) begin
      pswizard_txn txn = pswizard_txn::type_id::create("psw_pl_b");
      txn.txn_type = pswizard_txn::PSW_PL_B;
      txn.pl_port = pl_sel; txn.timestamp_ns = $time;
      txn.bid = {6'h0, bid}; txn.bresp = bresp;
      emit(txn);
    end

    if (arvalid && arready) begin
      pswizard_txn txn = pswizard_txn::type_id::create("psw_pl_ar");
      txn.txn_type = pswizard_txn::PSW_PL_AR;
      txn.pl_port = pl_sel; txn.timestamp_ns = $time;
      txn.addr = {13'h0, araddr}; txn.id = {6'h0, arid};
      txn.len = arlen; txn.size = arsize; txn.burst = arburst;
      txn.bytes = (longint'(arlen) + 1) << arsize;
      txn.chan = decode_noc_channel(txn.addr);
      txn.chan_valid = 1'b1;
      emit(txn);
    end

    if (rvalid && rready && rlast) begin
      pswizard_txn txn = pswizard_txn::type_id::create("psw_pl_r");
      txn.txn_type = pswizard_txn::PSW_PL_R;
      txn.pl_port = pl_sel; txn.timestamp_ns = $time;
      txn.rid = {6'h0, rid}; txn.rresp = rresp;
      emit(txn);
    end
  endtask

  // ---- MSI-X enable-lookup sampling -------------------------------------
  // Sampled on the RISING EDGE of user_req only. The lookup is combinational
  // off the requester bus, so sampling every cycle would print the stale bus
  // between requests and would read X before the first request.
  local function string ctrl_state_name(logic [2:0] s);
    case (s)
      3'd0: return "CTRL_WAIT";
      3'd1: return "CTRL_LOOKUP";
      3'd2: return "CTRL_LOOKUP_QUERY_CLEAR";
      3'd3: return "CTRL_SEND";
      3'd4: return "CTRL_SEND_ACK";
      default: return $sformatf("UNKNOWN(%0d)", s);
    endcase
  endfunction

  local task sample_msix_lookup(ref logic req_prev);
    logic        req_now;
    bit          is_vf;
    int          idx, vfn;
    bit          own_bit, read_bit;
    string       verdict;

    req_now = msix_vif.user_req;

    if (req_now === 1'b1 && req_prev !== 1'b1) begin
      is_vf = msix_vif.user_vfunc_active;
      idx   = int'(msix_vif.msix_user_vf_index);
      vfn   = int'(msix_vif.user_vfunc_num);
      cnt_msix_lookup++;

      $fdisplay(log_fd,
        {"%9t ns  PSW   MSIX_LOOKUP   fnc=%0d vfnc=%0d is_vf=%0b vec=%0d op=%0d  ",
         "vf_index=%0d  enabled=%0b  state=%s  vf_en[7:0]=0x%02h pf_en=0x%02h"},
        $time, msix_vif.user_func_num, vfn, is_vf,
        msix_vif.user_vector_num, msix_vif.user_operation,
        idx, msix_vif.user_function_is_enabled,
        ctrl_state_name(msix_vif.ctrl_state),
        msix_vif.msix_vf_msix_enable[7:0], msix_vif.msix_pf_msix_enable);

      if (is_vf) begin
        idx_seen[idx] = 1'b1;

        // INVARIANT, configuration-independent: PF0's VF group always begins
        // at absolute VF 0, so for func_num==0 the lookup index must be the
        // requester's own vfunc_num. This holds for any NUM_PFS and any
        // VFGX_FIRST_VF_OFFSET layout -- it needs no parameter knowledge.
        // For func_num>0 the correct base is that PF's cumulative VF count,
        // which is not exposed here, so no strict check is made.
        if (msix_vif.user_func_num == 3'd0 && idx != vfn) begin
          cnt_msix_index_skew++;
          `uvm_error("pswizard_monitor", $sformatf(
            {"[MSIX_VF_INDEX_SKEW] signal=msix_user_vf_index ",
             "file=cpm6_msix_ctrl_logic.sv observed=%0d expected=%0d ",
             "fnc=0 vfnc=%0d verdict=INDEX_SKEW ",
             "cite=PF0 VF group is based at absolute VF 0 by construction"},
            idx, vfn, vfn))
          $fdisplay(log_fd,
            "%9t ns  PSW   MSIX_VF_INDEX_SKEW  observed=%0d expected=%0d vfnc=%0d",
            $time, idx, vfn, vfn);
        end

        // A request that finds its function disabled. Two causes look
        // identical downstream (both end in a rejected grant), so name the
        // evidence that separates them rather than asserting one.
        if (msix_vif.user_function_is_enabled === 1'b0) begin
          own_bit  = msix_vif.msix_vf_msix_enable[vfn];
          read_bit = msix_vif.msix_vf_msix_enable[idx];
          verdict  = own_bit ? "INDEX_SKEW"        // own bit set, wrong bit read
                             : "HOST_NEVER_ENABLED";
          cnt_msix_disabled++;
          $fdisplay(log_fd,
            {"%9t ns  PSW   MSIX_REQ_WHILE_DISABLED  vfnc=%0d vf_index=%0d ",
             "own_bit=%0b read_bit=%0b verdict=%s"},
            $time, vfn, idx, own_bit, read_bit, verdict);
        end
      end
      $fflush(log_fd);
    end

    req_prev = req_now;
  endtask

  virtual task run_phase(uvm_phase phase);
    logic [127:0] irq_prev = '0;
    logic         msix_req_prev = 1'b0;

    // Wait for reset de-assertion
    @(posedge vif.clk);
    wait(vif.rst_n === 1'b1);

    $fdisplay(log_fd, "\n%s", {"=" * 80});
    $fdisplay(log_fd, "=== PSW  - PS Wizard NOC AXI + DMA IRQ ===");
    $fdisplay(log_fd, "    Events: PSW_RESET  PSW_NOC_AW  PSW_NOC_W  PSW_NOC_B  PSW_NOC_AR  PSW_NOC_R  PSW_DMA_IRQ  DMA_IRQ_CH  PSW_PL_AW  PSW_PL_W  PSW_PL_B  PSW_PL_AR  PSW_PL_R");
    $fdisplay(log_fd, "%s", {"=" * 80});
    $fdisplay(log_fd, "# %0t  PSWIZARD monitor started (reset deasserted)", $time);
    $fflush(log_fd);

    // Log the reset de-assertion event
    begin
      pswizard_txn txn = pswizard_txn::type_id::create("psw_reset");
      txn.txn_type     = pswizard_txn::PSW_RESET;
      txn.timestamp_ns = $time;
      emit(txn);
    end

    forever begin
      @(posedge vif.clk);
      #1ps; // settle

      // ---- NOC0 and NOC1 ----
      sample_noc_port(1'b0);
      sample_noc_port(1'b1);

      // ---- cpm_axi_pl0 / pl1 / pl3 ----
      sample_pl_port(0);
      sample_pl_port(1);
`ifdef ENABLE_PL3_BIND
      sample_pl_port(3);
`endif

      // ---- MSI-X enable lookup (only when the bind is compiled in) ----
      if (msix_mon_en) sample_msix_lookup(msix_req_prev);

      // ---- DMA IRQ edge detect ----
      begin
        logic [127:0] irq_now = vif.dma_irq;
        logic [127:0] new_bits = irq_now & ~irq_prev;
        if (|new_bits) begin
          pswizard_txn txn = pswizard_txn::type_id::create("psw_irq");
          txn.txn_type     = pswizard_txn::PSW_DMA_IRQ;
          txn.timestamp_ns = $time;
          txn.irq_new      = new_bits;
          emit(txn);
          // Channel decode: dma_irq[N] IS the HDMA channel index directly,
          // same indexing as the DBI/NOC0 512B-slot channel number. No
          // lookup needed for the channel number itself; H2C/C2H role is
          // only statically known for the 4 fixed low indices.
          for (int n = 0; n < 128; n++) begin
            if (new_bits[n]) begin
              $fdisplay(log_fd, "%9t ns  PSW   DMA_IRQ_CH    ch=%0d role=%s",
                $time, n, irq_ch_role(n));
            end
          end
          $fflush(log_fd);
          if (cfg.checks_enable && $countones(new_bits) > 1) begin
            `uvm_warning("pswizard_monitor", $sformatf("Multiple DMA IRQ bits asserted simultaneously (%0d bits)",
              $countones(new_bits)))
          end
        end
        irq_prev = irq_now;
      end

    end
  endtask

  virtual function void report_phase(uvm_phase phase);
    if (log_fd) begin
      if (!msix_mon_en) begin
        // Say so explicitly. A summary that simply omits MSI-X would read as
        // "no MSI-X problems" when the truth is "not observed at all".
        $fdisplay(log_fd,
          {"    MSIX_LOOKUP: NOT MONITORED (bind.pswizard_msix.sv not compiled ",
           "-- MSIX_CTRL_MON=0, or the encrypted cpm6 rfs is in use)"});
      end else begin
        string idx_list = "";
        foreach (idx_seen[i]) idx_list = {idx_list, $sformatf("%0d ", i)};
        $fdisplay(log_fd,
          {"    MSIX_SUMMARY: lookups=%0d  index_skew=%0d  req_while_disabled=%0d  ",
           "vf_index values seen={ %s}"},
          cnt_msix_lookup, cnt_msix_index_skew, cnt_msix_disabled, idx_list);
        if (cnt_msix_lookup == 0)
          $fdisplay(log_fd,
            "    MSIX_UNEXERCISED: no MSI-X request observed -- index check did not run");
      end
      $fdisplay(log_fd, "    Checks: %0d violation(s) detected", check_err_count);
      $fdisplay(log_fd, "%s\n", {"=" * 80});
      $fflush(log_fd);
    end
  endfunction

endclass
