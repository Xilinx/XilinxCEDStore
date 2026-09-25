// qdma_periph_monitor.sv — Passive UVM monitor for QDMA periphery interfaces
//
// Observes all external AXI interfaces at the cpm6_qdma module boundary:
//   s_axi_mem   — descriptor fetch completions + DMA data (128-bit, CRITICAL)
//   s_axi_reg   — register access (context writes, PIDX doorbells)
//   m_axil_dbi  — DBI register access (ISR write-back, Bug F3 diagnosis)
//   msix        — MSI-X req/grant/error handshake
//
// Logs to shared cpm6_qdma_dbg.log via immediate $fdisplay+$fflush.
// Tag: QPER (QDMA PERiphery).
//
// Key feature: MEM_W beat-level gap timing for completion arrival analysis.
class qdma_periph_monitor extends uvm_monitor;

   `uvm_component_utils(qdma_periph_monitor)

   virtual qdma_periph_if                  vif;
   virtual qdma_periph_tm_dsc_if            vif_tm;
   bit                                      have_vif_tm;
   qdma_periph_cfg                         cfg;
   uvm_analysis_port#(qdma_periph_txn)     ap;

   local int    log_fd;
   int          check_err_count = 0;

   // ---- Per-interface counters ----
   int unsigned cnt_mem_aw, cnt_mem_w, cnt_mem_b, cnt_mem_ar, cnt_mem_r;
   int unsigned cnt_mem_wr_paired; // AW+W matched pairs
   int unsigned cnt_reg_wr, cnt_reg_rd;
   int unsigned cnt_dbi_wr, cnt_dbi_b, cnt_dbi_rd, cnt_dbi_r;
   int unsigned cnt_tm_dsc_sts_vld;
   int unsigned cnt_msix_req, cnt_msix_grant, cnt_msix_error;
   // Grant and error asserted in the SAME cycle. irq_mgr's IRQ_WAIT_GRANT tests
   // grant before error (`if (msix_grant) ... else if (msix_error)`), so a
   // coincident pair is scored as a successful delivery and mbox_irq_ack is
   // raised for an interrupt that was never emitted. Nothing in the TB observed
   // this before; a run could show 78 errors and 78 grants with zero complaint.
   int unsigned cnt_msix_grant_err_coincident;

   // --- msix_error debug hook (2026-08-20) --------------------------------
   // MSI-X enable lives in PCIe CONFIG SPACE, so it is readable by a config
   // read -- no RTL bind into the hard block is needed. Once set it is not
   // expected to clear, so reading it AT THE MOMENT OF THE ERROR answers
   // directly whether CPM is refusing the request because the function's
   // msix_enable is actually clear, or for some other reason.
   //
   // The monitor cannot issue a config read itself (no sequencer/API handle),
   // so it publishes the failing function's identity and triggers an event;
   // the test performs the read. Identity comes from msix_pend_*, latched at
   // msix_req, because grant and error carry no identity of their own.
   event        msix_err_ev;
   bit          msix_err_is_vf;
   bit [2:0]    msix_err_pf;
   bit [7:0]    msix_err_vf;
   bit [10:0]   msix_err_vec;
   bit          msix_err_grant_coincident;

   // ---- MEM_W gap tracking ----
   time         mem_w_last_time;

   // ---- MEM write pairing: buffer AW and W independently (AXI allows any order) ----
   typedef struct {
      logic [63:0] addr;
      logic [3:0]  id;
      logic [7:0]  len;
      logic [2:0]  size;
      time         timestamp_ns;
   } mem_aw_entry_t;

   typedef struct {
      logic [15:0] wstrb;
      logic        wlast;
      int          gap_cycles;
      time         timestamp_ns;
   } mem_w_entry_t;

   mem_aw_entry_t mem_aw_q[$];
   mem_w_entry_t  mem_w_q[$];

   // ---- REG write tracking: capture AW addr, then log on B ----
   logic [42:0] reg_aw_addr_q[$];
   logic [31:0] reg_w_data_q[$];

   // ---- MSIX edge detection ----
   logic        msix_req_prev, msix_grant_prev, msix_error_prev;

   // ---- MSIX in-flight request identity ----
   // func/vfunc/vec are only valid on the request; grant and error carry no
   // identity of their own. Latching at the request is what lets an error name
   // the function it belongs to, which is the whole difference between "78
   // errors happened" and "50 of them targeted PF0, which was never armed".
   logic [2:0]  msix_pend_func;
   logic [7:0]  msix_pend_vfunc;
   logic [10:0] msix_pend_vec;
   logic        msix_pend_is_vf;
   bit          msix_pend_vld;

   function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual qdma_periph_if)::get(this, "", "vif", vif))
         `uvm_fatal("qdma_periph_monitor", "Failed to get virtual qdma_periph_if from config_db")
      if (!uvm_config_db#(qdma_periph_cfg)::get(this, "", "cfg", cfg))
         `uvm_fatal("qdma_periph_monitor", "Failed to get qdma_periph_cfg from config_db")
      if (!uvm_config_db#(int)::get(this, "", "log_fd", log_fd))
         `uvm_fatal("qdma_periph_monitor", "Failed to get shared log_fd from config_db")
      // Soft get: tm_dsc_sts observation is a new, separate bind
      // (bind.tm_dsc_sts.sv, `CPM6_TOP_WRAPPER) added alongside the original
      // 4-interface design_1 bind — not fatal if absent, so this monitor keeps
      // working on configs that predate the new bind file.
      have_vif_tm = uvm_config_db#(virtual qdma_periph_tm_dsc_if)::get(this, "", "vif_tm", vif_tm);
      if (!have_vif_tm)
         `uvm_warning("qdma_periph_monitor",
            "vif_tm_dsc_sts not found in config_db — bind.tm_dsc_sts.sv may not have run; tm_dsc_sts observation disabled for this run")
   endfunction

   // ---- Emit one transaction and log it ----
   local function void emit(qdma_periph_txn txn, string detail);
      $fdisplay(log_fd, "%9t ns  QPER  %-12s  %s",
         txn.timestamp_ns, txn.txn_type.name(), detail);
      $fflush(log_fd);
      ap.write(txn);
   endfunction

   // ---- Register offset decode ----
   local function string decode_reg_offset(logic [42:0] addr, logic [31:0] wdata);
      logic [15:0] offset;
      offset = addr[15:0];
      case (offset) inside
         16'h0844: begin
            // IND_CTXT_CMD layout (cpm6_qdma_reg_space.sv:897-901):
            //   wdata[19:7] = qid (13 bits), wdata[6:5] = op (mdma_ind_ctxt_cmd_e),
            //   wdata[4:1] = sel (mdma_ind_ctxt_sel_e), wdata[0] = busy
            // Enum values (cpm6_qdma_mdma_defines.svh, cpm6_qdma_mdma_reg.svh):
            //   op:  0=CLR, 1=WR, 2=RD, 3=INV
            //   sel: 0=SW_C2H, 1=SW_H2C, 2=HW_C2H, 3=HW_H2C, 6=WRB, 7=PFTCH, ...
            // Prior version had op/sel labels SWAPPED — every log line read backwards.
            return $sformatf("[IND_CTXT_CMD qid=%0d op=%0d sel=%0d]",
               wdata[19:7], wdata[6:5], wdata[4:1]);
         end
         [16'h6400:16'h67FF]: begin
            // PIDX doorbell range: qid = (offset - 0x6400) / 16
            return $sformatf("[PIDX_DB qid=%0d pidx=%0d irq_en=%0b]",
               (offset - 16'h6400) >> 4, wdata[15:0], wdata[16]);
         end
         [16'h0204:16'h0240]: begin
            // MDMA_GLBL_RNG_SZ_A[16] table at 0x204..0x240 (16 entries x 4B).
            // Authoritative: qdma_base_test.sv:1328-1343 TSK_GLBL_PGM.
            return $sformatf("[GLBL_RNG_SZ_%0d]", (offset - 16'h0204) >> 2);
         end
         [16'h0804:16'h0820]: begin
            // IND_CTXT_DATA_[0:7] at 0x804..0x820 (8 x 4B, 256-bit context data).
            // Authoritative: qdma_base_test.sv:3893 DRV_BIND_IND_CTXT_DATA0_OFFSET=0x804.
            // Prior table had this region at 0x0A04..0x0A20 — WRONG; 0xA00 is unused.
            return $sformatf("[IND_CTXT_DATA_%0d]", (offset - 16'h0804) >> 2);
         end
         [16'h0824:16'h0840]: begin
            // IND_CTXT_MASK_[0:7] at 0x824..0x840 (8 x 4B, 256-bit mask).
            // Authoritative: qdma_base_test.sv:1349-1354 TSK_GLBL_PGM.
            return $sformatf("[IND_CTXT_MASK_%0d]", (offset - 16'h0824) >> 2);
         end
         // Additional offsets per the register space documentation.
         16'h0248: return "[QDMA_GLBL_ERR_STAT]";
         16'h024c: return "[QDMA_GLBL_ERR_MASK]";
         16'h0250: return "[QDMA_GLBL_DSC_CFG]";
         16'h0254: return "[QDMA_GLBL_DSC_ERR_STS]";
         16'h0264: return "[QDMA_GLBL_TRQ_ERR_STS]";
         [16'h3000:16'h300c]: begin
            // VF doorbells: qid = (offset - 0x3000) / 16
            return $sformatf("[VF_DB qid=%0d pidx=%0d irq_en=%0b]",
               (offset - 16'h3000) >> 4, wdata[15:0], wdata[16]);
         end
         default:  return "";
      endcase
   endfunction

   // ---- m_axil_dbi channel + register decode ----
   // Base-address-independent: slot/register live in addr[15:0] regardless of
   // which controller's base (0xFC2C0000 ctrl0 / 0xFC6C0000 ctrl1,
   // CPM6_CTRL_REG_OFFSET=0x400000=bit22) is in use.
   // ctrl0-vs-ctrl1 is read directly off addr[22], no external config needed.
   //
   // VERIFIED against the authoritative CPM6 QDMA register map (per-channel
   // 512B block, DMA_REG_SLOT_OFFSET=9).
   // +0x80/+0x8c resolve to DMA_STATUS (ISR polls STATUS!=RUNNING) and
   // DMA_INT_CLEAR (ISR writes 0x3 = STOP+WATERMARK clear). isr.sv clears
   // STOP+WATERMARK but not ABORT, so an observed data=0x7 (covering
   // STOP+WATERMARK+ABORT) vs. the doc's 0x3 example is a real, separately-
   // tracked discrepancy, not a decode error. +0x84/+0x88 added for
   // completeness (err_mgmt / int-mask
   // config paths).
   // NOTE: the doc's own "LLP Programming Order" prose section states FNC at
   // +0x28, contradicting its own register table (+0x38) — the table's +0x38
   // is used here since it independently matches the RTL-derived
   // FNC_START_ADDR citation above; flagging the doc's internal inconsistency
   // rather than silently picking one.
   //
   // Low channel indices additionally have a fixed, documented consumer
   // identity (DMA Channel Index Map table); indices 4+ are the scheduler's
   // dynamically-allocated free-channel pool with no static consumer.
   local function string decode_dbi_ch_name(logic [6:0] ch);
      case (ch)
         7'd0:    return "WRCH_0/wb_desc_writer";
         7'd1:    return "RDCH_0/cmpt_desc_writer";
         7'd2:    return "WRCH_1/dsc_fetch_engine";
         7'd3:    return "RDCH_1/dsc_fetch_engine";
         default: return "";
      endcase
   endfunction

   local function string decode_dbi(logic [31:0] addr);
      logic [8:0] reg_off  = addr[8:0];
      logic [6:0] ch       = addr[15:9];
      int         ctrl_id  = addr[22];
      string      rname;
      string      ch_name;
      case (reg_off)
         9'h004:  rname = "DMA_DOORBELL";
         9'h010:  rname = "DMA_LLP_BASE(low)";
         9'h014:  rname = "DMA_LLP_BASE(high)";
         9'h038:  rname = "DMA_FNC";
         9'h080:  rname = "DMA_STATUS";
         9'h084:  rname = "DMA_INT_STATUS";
         9'h088:  rname = "DMA_INT_SETUP";
         9'h08c:  rname = "DMA_INT_CLEAR";
         default: rname = "";
      endcase
      if (rname == "") return "";
      ch_name = decode_dbi_ch_name(ch);
      return $sformatf("[%s ch=%0d%s ctrl=%0d]", rname, ch,
         (ch_name != "") ? {" (", ch_name, ")"} : "", ctrl_id);
   endfunction

   // ================================================================
   // s_axi_mem sampling — CRITICAL for stall analysis
   //
   // Bug #20 fix: AW and W channels are buffered independently and
   // matched when both are available, since AXI permits W to arrive
   // before AW.
   // ================================================================

   // ---- Try to pair buffered AW and W entries ----
   local function void try_match_mem_aw_w();
      while (mem_aw_q.size() > 0 && mem_w_q.size() > 0) begin
         mem_aw_entry_t aw_e = mem_aw_q.pop_front();
         mem_w_entry_t  w_e  = mem_w_q.pop_front();
         // Byte size: on the WLAST beat, the final beat can be a partial
         // strobe (unaligned transfer) — (len+1)<<size alone over-counts
         // that case. Full beats (all but the last) assumed fully enabled;
         // the WLAST beat's actual enabled-byte count comes from
         // $countones(wstrb). Non-WLAST pairings (this function pops one
         // AW+one W per call, not per-burst) use the plain burst estimate.
         longint unsigned bytes = w_e.wlast
            ? (longint'(aw_e.len) << aw_e.size) + $countones(w_e.wstrb)
            : (longint'(aw_e.len) + 1) << aw_e.size;
         cnt_mem_wr_paired++;
         if (cfg.mem_log_all_beats) begin
            $fdisplay(log_fd, "%9t ns  QPER  MEM_AW_W      addr=0x%016h  id=0x%01h  len=%0d  sz=%0d  wstrb=0x%04h  wlast=%0b  gap=%0d  bytes=%0d",
               w_e.timestamp_ns, aw_e.addr, aw_e.id, aw_e.len, aw_e.size,
               w_e.wstrb, w_e.wlast, w_e.gap_cycles, bytes);
            $fflush(log_fd);
         end
      end
   endfunction

   local task sample_mem();
      qdma_periph_txn txn;
      // ---- AW handshake: buffer for pairing ----
      if (vif.mem_awvalid && vif.mem_awready) begin
         mem_aw_entry_t aw_e;
         aw_e.addr         = vif.mem_awaddr;
         aw_e.id           = vif.mem_awid;
         aw_e.len          = vif.mem_awlen;
         aw_e.size         = vif.mem_awsize;
         aw_e.timestamp_ns = $time;
         mem_aw_q.push_back(aw_e);
         cnt_mem_aw++;

         txn = qdma_periph_txn::type_id::create("qper_mem_aw");
         txn.txn_type     = qdma_periph_txn::MEM_AW;
         txn.timestamp_ns = $time;
         txn.addr         = vif.mem_awaddr;
         txn.id           = vif.mem_awid;
         txn.len          = vif.mem_awlen;
         txn.size         = vif.mem_awsize;
         txn.bytes        = (longint'(vif.mem_awlen) + 1) << vif.mem_awsize;
         emit(txn, $sformatf("addr=0x%016h  id=0x%01h  len=%0d  sz=%0d  bytes_est=%0d",
            vif.mem_awaddr, vif.mem_awid, vif.mem_awlen, vif.mem_awsize, txn.bytes));
      end

      // ---- W beat (every beat, with gap timing): buffer for pairing ----
      if (vif.mem_wvalid && vif.mem_wready) begin
         mem_w_entry_t w_e;
         w_e.wstrb        = vif.mem_wstrb;
         w_e.wlast        = vif.mem_wlast;
         w_e.timestamp_ns = $time;
         if (mem_w_last_time != 0)
            w_e.gap_cycles = int'(($time - mem_w_last_time) / 4ns); // 250 MHz ~ 4ns
         else
            w_e.gap_cycles = 0;
         mem_w_q.push_back(w_e);

         if (cfg.mem_log_all_beats) begin
            txn = qdma_periph_txn::type_id::create("qper_mem_w");
            txn.txn_type     = qdma_periph_txn::MEM_W;
            txn.timestamp_ns = $time;
            txn.gap_cycles   = w_e.gap_cycles;
            cnt_mem_w++;
            emit(txn, $sformatf("wlast=%0b  wstrb=0x%04h  gap=%0d",
               vif.mem_wlast, vif.mem_wstrb, txn.gap_cycles));
         end else begin
            cnt_mem_w++;
         end
         mem_w_last_time = $time;
      end

      // ---- Match any pending AW+W pairs ----
      try_match_mem_aw_w();

      // ---- B response ----
      if (vif.mem_bvalid && vif.mem_bready) begin
         txn = qdma_periph_txn::type_id::create("qper_mem_b");
         txn.txn_type     = qdma_periph_txn::MEM_B;
         txn.timestamp_ns = $time;
         txn.id           = vif.mem_bid;
         txn.resp         = vif.mem_bresp;
         cnt_mem_b++;
         emit(txn, $sformatf("bid=0x%01h  resp=%0d", vif.mem_bid, vif.mem_bresp));
         if (cfg.checks_enable && vif.mem_bresp != 2'b00) begin
            `uvm_error("qdma_periph_monitor",
               $sformatf("s_axi_mem B resp error: bid=0x%01h resp=%0d",
                  vif.mem_bid, vif.mem_bresp))
            check_err_count++;
         end
      end

      // ---- AR handshake ----
      if (vif.mem_arvalid && vif.mem_arready) begin
         txn = qdma_periph_txn::type_id::create("qper_mem_ar");
         txn.txn_type     = qdma_periph_txn::MEM_AR;
         txn.timestamp_ns = $time;
         txn.addr         = vif.mem_araddr;
         txn.id           = vif.mem_arid;
         txn.len          = vif.mem_arlen;
         txn.size         = vif.mem_arsize;
         txn.bytes        = (longint'(vif.mem_arlen) + 1) << vif.mem_arsize;
         cnt_mem_ar++;
         emit(txn, $sformatf("addr=0x%016h  id=0x%01h  len=%0d  sz=%0d  bytes_est=%0d",
            vif.mem_araddr, vif.mem_arid, vif.mem_arlen, vif.mem_arsize, txn.bytes));
      end

      // ---- R last beat ----
      if (vif.mem_rvalid && vif.mem_rready && vif.mem_rlast) begin
         txn = qdma_periph_txn::type_id::create("qper_mem_r");
         txn.txn_type     = qdma_periph_txn::MEM_R;
         txn.timestamp_ns = $time;
         txn.id           = vif.mem_rid;
         txn.resp         = vif.mem_rresp;
         cnt_mem_r++;
         emit(txn, $sformatf("rid=0x%01h  resp=%0d", vif.mem_rid, vif.mem_rresp));
         if (cfg.checks_enable && vif.mem_rresp != 2'b00) begin
            `uvm_error("qdma_periph_monitor",
               $sformatf("s_axi_mem R resp error: rid=0x%01h resp=%0d",
                  vif.mem_rid, vif.mem_rresp))
            check_err_count++;
         end
      end
   endtask

   // ================================================================
   // s_axi_reg sampling — Register access path
   // ================================================================
   local task sample_reg();
      qdma_periph_txn txn;
      // ---- AW: capture addr for later pairing with B ----
      if (vif.reg_awvalid && vif.reg_awready)
         reg_aw_addr_q.push_back(vif.reg_awaddr);

      // ---- W: capture data for later pairing with B ----
      if (vif.reg_wvalid && vif.reg_wready)
         reg_w_data_q.push_back(vif.reg_wdata);

      // ---- B: log write complete with addr+data ----
      if (vif.reg_bvalid && vif.reg_bready) begin
         txn = qdma_periph_txn::type_id::create("qper_reg_wr");
         txn.txn_type     = qdma_periph_txn::REG_WR;
         txn.timestamp_ns = $time;
         txn.resp         = vif.reg_bresp;
         if (reg_aw_addr_q.size() > 0)
            txn.addr = {21'h0, reg_aw_addr_q.pop_front()};
         if (reg_w_data_q.size() > 0)
            txn.data = reg_w_data_q.pop_front();
         if (cfg.reg_decode_enable)
            txn.reg_decode = decode_reg_offset(txn.addr[42:0], txn.data);
         cnt_reg_wr++;
         emit(txn, $sformatf("addr=0x%011h  wdata=0x%08h  resp=%0d%s",
            txn.addr, txn.data, txn.resp,
            (txn.reg_decode != "") ? {" ", txn.reg_decode} : ""));
         if (cfg.checks_enable && vif.reg_bresp != 2'b00) begin
            `uvm_error("qdma_periph_monitor",
               $sformatf("s_axi_reg B resp error: addr=0x%011h resp=%0d",
                  txn.addr, txn.resp))
            check_err_count++;
         end
      end

      // ---- R: read complete ----
      if (vif.reg_rvalid && vif.reg_rready && vif.reg_rlast) begin
         txn = qdma_periph_txn::type_id::create("qper_reg_rd");
         txn.txn_type     = qdma_periph_txn::REG_RD;
         txn.timestamp_ns = $time;
         txn.data         = vif.reg_rdata;
         txn.resp         = vif.reg_rresp;
         cnt_reg_rd++;
         emit(txn, $sformatf("rdata=0x%08h  resp=%0d", vif.reg_rdata, vif.reg_rresp));
         if (cfg.checks_enable && vif.reg_rresp != 2'b00) begin
            `uvm_error("qdma_periph_monitor",
               $sformatf("s_axi_reg R resp error: rdata=0x%08h resp=%0d",
                  vif.reg_rdata, vif.reg_rresp))
            check_err_count++;
         end
      end
   endtask

   // ================================================================
   // m_axil_dbi sampling — ISR write-back path (Bug F3 diagnosis)
   // ================================================================
   local task sample_dbi();
      qdma_periph_txn txn;
      // ---- AW + W: log write address+data (simultaneous for AXI-Lite) ----
      if (vif.dbi_awvalid && vif.dbi_awready) begin
         txn = qdma_periph_txn::type_id::create("qper_dbi_wr");
         txn.txn_type     = qdma_periph_txn::DBI_WR;
         txn.timestamp_ns = $time;
         txn.addr         = {32'h0, vif.dbi_awaddr};
         txn.data         = vif.dbi_wdata;
         if (cfg.dbi_decode_enable)
            txn.dbi_decode = decode_dbi(vif.dbi_awaddr);
         cnt_dbi_wr++;
         emit(txn, $sformatf("addr=0x%08h  wdata=0x%08h%s",
            vif.dbi_awaddr, vif.dbi_wdata,
            (txn.dbi_decode != "") ? {" ", txn.dbi_decode} : ""));
      end

      // ---- B: write response (key F3 diagnosis — bvalid never asserts if undriven) ----
      if (vif.dbi_bvalid && vif.dbi_bready) begin
         txn = qdma_periph_txn::type_id::create("qper_dbi_b");
         txn.txn_type     = qdma_periph_txn::DBI_B;
         txn.timestamp_ns = $time;
         txn.resp         = vif.dbi_bresp;
         cnt_dbi_b++;
         emit(txn, $sformatf("resp=%0d", vif.dbi_bresp));
      end

      // ---- AR: read address ----
      if (vif.dbi_arvalid && vif.dbi_arready) begin
         txn = qdma_periph_txn::type_id::create("qper_dbi_rd");
         txn.txn_type     = qdma_periph_txn::DBI_RD;
         txn.timestamp_ns = $time;
         txn.addr         = {32'h0, vif.dbi_araddr};
         if (cfg.dbi_decode_enable)
            txn.dbi_decode = decode_dbi(vif.dbi_araddr);
         cnt_dbi_rd++;
         emit(txn, $sformatf("addr=0x%08h%s", vif.dbi_araddr,
            (txn.dbi_decode != "") ? {" ", txn.dbi_decode} : ""));
      end

      // ---- R: read response ----
      if (vif.dbi_rvalid && vif.dbi_rready) begin
         txn = qdma_periph_txn::type_id::create("qper_dbi_r");
         txn.txn_type     = qdma_periph_txn::DBI_R;
         txn.timestamp_ns = $time;
         txn.data         = vif.dbi_rdata;
         txn.resp         = vif.dbi_rresp;
         cnt_dbi_r++;
         emit(txn, $sformatf("rdata=0x%08h  resp=%0d", vif.dbi_rdata, vif.dbi_rresp));
      end
   endtask

   // ================================================================
   // MSI-X sideband sampling
   // ================================================================
   // Identity of the request a grant/error belongs to. Reports UNKNOWN rather
   // than a stale or zero function when no request is outstanding, so "not
   // captured" is never mistaken for "function 0".
   local function string msix_pend_str();
      if (!msix_pend_vld)
         return "req=UNKNOWN(no outstanding msix_req)";
      return $sformatf("req_func=%0d req_vfunc=%0d req_is_vf=%0b req_vec=%0d",
                       msix_pend_func, msix_pend_vfunc,
                       msix_pend_is_vf, msix_pend_vec);
   endfunction

   local task sample_msix();
      qdma_periph_txn txn;
      // Rising-edge detection
      if (vif.msix_req && !msix_req_prev) begin
         txn = qdma_periph_txn::type_id::create("qper_msix_req");
         txn.txn_type     = qdma_periph_txn::MSIX_REQ;
         txn.timestamp_ns = $time;
         txn.msix_func    = vif.msix_func_num;
         txn.msix_vfunc   = vif.msix_vfunc_num;
         txn.msix_vec     = vif.msix_vector_num;
         txn.msix_op      = vif.msix_operation;
         cnt_msix_req++;
         msix_pend_func  = vif.msix_func_num;
         msix_pend_vfunc = vif.msix_vfunc_num;
         msix_pend_vec   = vif.msix_vector_num;
         msix_pend_is_vf = vif.msix_vfunc_active;
         msix_pend_vld   = 1'b1;
         emit(txn, $sformatf("func=%0d  vfunc=%0d  vec=%0d  op=%0d",
            vif.msix_func_num, vif.msix_vfunc_num,
            vif.msix_vector_num, vif.msix_operation));
      end

      if (vif.msix_grant && !msix_grant_prev) begin
         txn = qdma_periph_txn::type_id::create("qper_msix_grant");
         txn.txn_type     = qdma_periph_txn::MSIX_GRANT;
         txn.timestamp_ns = $time;
         if (msix_pend_vld) begin
            txn.msix_func  = msix_pend_func;
            txn.msix_vfunc = msix_pend_vfunc;
            txn.msix_vec   = msix_pend_vec;
         end
         cnt_msix_grant++;
         emit(txn, $sformatf("granted  %s", msix_pend_str()));
      end

      if (vif.msix_error && !msix_error_prev) begin
         txn = qdma_periph_txn::type_id::create("qper_msix_error");
         txn.txn_type     = qdma_periph_txn::MSIX_ERROR;
         txn.timestamp_ns = $time;
         if (msix_pend_vld) begin
            txn.msix_func  = msix_pend_func;
            txn.msix_vfunc = msix_pend_vfunc;
            txn.msix_vec   = msix_pend_vec;
         end
         cnt_msix_error++;
         emit(txn, $sformatf("error  %s", msix_pend_str()));
         if (cfg.checks_enable) begin
            `uvm_error("qdma_periph_monitor", $sformatf(
               "MSI-X error asserted  %s  verdict=%s  cite=cpm6_msix_ctrl_logic checks user_function_is_enabled_reg (pf_cfg_status.msix_en / vf_cfg_status.vf_msix_en)",
               msix_pend_str(),
               vif.msix_grant ? "GRANT_ERROR_COINCIDENT" : "ERROR_ONLY"))
            check_err_count++;
         end
         // Publish identity + wake the test-side config-read probe.
         msix_err_is_vf            = msix_pend_is_vf;
         msix_err_pf               = msix_pend_func;
         msix_err_vf               = msix_pend_vfunc;
         msix_err_vec              = msix_pend_vec;
         msix_err_grant_coincident = vif.msix_grant;
         ->msix_err_ev;
      end

      // ---- Grant and error in the same cycle ----------------------------
      // CPM6 answers a request from a function whose msix_enable=0 by asserting
      // BOTH. irq_mgr (IRQ_WAIT_GRANT, `if (msix_grant) ... else if (msix_error)`)
      // therefore never reaches its error branch: it clears msix_req, raises
      // mbox_irq_ack, and returns to IDLE, reporting a delivery that did not
      // occur. The documented "halt in IRQ_ERROR, no retry" behaviour is
      // unreachable whenever this fires, so this is the direct signature of a
      // silently-swallowed interrupt rather than a benign race.
      if (vif.msix_grant && vif.msix_error &&
          !(msix_grant_prev && msix_error_prev)) begin
         cnt_msix_grant_err_coincident++;
         // Also to dbg.log, not just the UVM report server -- `uvm_error` alone
         // routes only to vcs.sim.log, so a check that only calls uvm_error would
         // be invisible to anyone grepping cpm6_qdma_dbg.log, where every other
         // check in this TB lands.
         $fdisplay(log_fd,
            "%0t ns  QPER  MSIX_GRANT_ERROR_COINCIDENT  grant=1 error=1  %s",
            $time, msix_pend_str());
         $fflush(log_fd);
         if (cfg.checks_enable) begin
            `uvm_error("qdma_periph_monitor", $sformatf(
               "MSIX_GRANT_ERROR_COINCIDENT  signal=msix_grant&msix_error  %s  verdict=INTERRUPT_SCORED_DELIVERED_BUT_ERRORED  cite=irq_mgr.sv IRQ_WAIT_GRANT grant-before-error priority",
               msix_pend_str()))
            check_err_count++;
         end
      end

      if ((vif.msix_grant && !msix_grant_prev) ||
          (vif.msix_error && !msix_error_prev))
         msix_pend_vld = 1'b0;

      msix_req_prev   = vif.msix_req;
      msix_grant_prev = vif.msix_grant;
      msix_error_prev = vif.msix_error;
   endtask

   // ================================================================
   // tm_dsc_sts sampling — traffic-manager descriptor status
   // (separate bind/interface, `CPM6_TOP_WRAPPER — see bind.tm_dsc_sts.sv)
   // ================================================================
   local task sample_tm_dsc_sts();
      qdma_periph_txn txn;
      if (vif_tm.tm_dsc_sts_vld) begin
         txn = qdma_periph_txn::type_id::create("qper_tm_dsc_sts");
         txn.txn_type        = qdma_periph_txn::TM_DSC_STS;
         txn.timestamp_ns    = $time;
         txn.tm_qid          = vif_tm.tm_dsc_sts_qid;
         txn.tm_dir          = vif_tm.tm_dsc_sts_dir;
         txn.tm_func         = vif_tm.tm_dsc_sts_func;
         txn.tm_pidx         = vif_tm.tm_dsc_sts_pidx;
         txn.tm_avl          = vif_tm.tm_dsc_sts_avl;
         txn.tm_port_id      = vif_tm.tm_dsc_sts_port_id;
         txn.tm_byp          = vif_tm.tm_dsc_sts_byp;
         txn.tm_qen          = vif_tm.tm_dsc_sts_qen;
         txn.tm_mm           = vif_tm.tm_dsc_sts_mm;
         txn.tm_error        = vif_tm.tm_dsc_sts_error;
         txn.tm_qinv         = vif_tm.tm_dsc_sts_qinv;
         txn.tm_irq_arm      = vif_tm.tm_dsc_sts_irq_arm;
         txn.tm_vio_dsc_crdt = vif_tm.tm_dsc_sts_vio_dsc_crdt;
         txn.tm_vio_en       = vif_tm.tm_dsc_sts_vio_en;
         txn.tm_vio_hw_db    = vif_tm.tm_dsc_sts_vio_hw_db;
         txn.tm_vio_sw_db    = vif_tm.tm_dsc_sts_vio_sw_db;
         txn.tm_vio_avl_flg  = vif_tm.tm_dsc_sts_vio_avl_flg;
         cnt_tm_dsc_sts_vld++;
         emit(txn, $sformatf(
            {"qid=%0d dir=%s func=%0d pidx=%0d avl=%0d port_id=%0d byp=%0b qen=%0b mm=%0b",
             " error=%0b qinv=%0b irq_arm=%0b vio_dsc_crdt=%0b vio_en=%0b vio_hw_db=%0b",
             " vio_sw_db=%0b vio_avl_flg=%0b"},
            txn.tm_qid, txn.tm_dir ? "C2H" : "H2C", txn.tm_func, txn.tm_pidx, txn.tm_avl,
            txn.tm_port_id, txn.tm_byp, txn.tm_qen, txn.tm_mm, txn.tm_error, txn.tm_qinv,
            txn.tm_irq_arm, txn.tm_vio_dsc_crdt, txn.tm_vio_en, txn.tm_vio_hw_db,
            txn.tm_vio_sw_db, txn.tm_vio_avl_flg));
      end
   endtask

   // ---- Clear all state (called on each reset) ----
   local function void clear_state();
      cnt_mem_aw        = 0;
      cnt_mem_w         = 0;
      cnt_mem_b         = 0;
      cnt_mem_ar        = 0;
      cnt_mem_r         = 0;
      cnt_mem_wr_paired = 0;
      cnt_reg_wr        = 0;
      cnt_reg_rd        = 0;
      cnt_dbi_wr        = 0;
      cnt_dbi_b         = 0;
      cnt_dbi_rd        = 0;
      cnt_dbi_r         = 0;
      cnt_tm_dsc_sts_vld = 0;
      cnt_msix_req      = 0;
      cnt_msix_grant    = 0;
      cnt_msix_error    = 0;
      cnt_msix_grant_err_coincident = 0;
      mem_w_last_time   = 0;
      msix_req_prev     = 1'b0;
      msix_grant_prev   = 1'b0;
      msix_error_prev   = 1'b0;
      msix_pend_vld     = 1'b0;
      mem_aw_q.delete();
      mem_w_q.delete();
      reg_aw_addr_q.delete();
      reg_w_data_q.delete();
   endfunction

   // ================================================================
   // run_phase — main sampling loop with reset re-entry
   // ================================================================
   virtual task run_phase(uvm_phase phase);
      forever begin
         @(posedge vif.rst_n);
         clear_state();

         $fdisplay(log_fd, "\n%s", {80{"="}});
         $fdisplay(log_fd, "=== QPER - QDMA Periphery Monitor (s_axi_mem + s_axi_reg + m_axil_dbi + MSIX) ===");
         $fdisplay(log_fd, "    Events: MEM_AW MEM_W MEM_B MEM_AR MEM_R REG_WR REG_RD DBI_WR DBI_B DBI_RD DBI_R TM_DSC_STS MSIX_REQ MSIX_GRANT MSIX_ERROR");
         $fdisplay(log_fd, "%s", {80{"="}});
         $fdisplay(log_fd, "# %0t  QDMA periphery monitor started (reset deasserted)", $time);
         $fflush(log_fd);

         fork
            begin
               forever begin
                  @(posedge vif.clk);
                  #1ps; // settle

                  sample_mem();
                  sample_reg();
                  sample_dbi();
                  sample_msix();
                  // vif_tm shares the same underlying axi_aclk net as vif.clk
                  // (both are the qdma core's AXI clock), so sampling it in
                  // this same loop is safe -- no separate clock-domain fork
                  // needed. Guarded: vif_tm is unbound when bind.tm_dsc_sts.sv
                  // did not run (see build_phase's soft get).
                  if (have_vif_tm) sample_tm_dsc_sts();
               end
            end
            @(negedge vif.rst_n);
         join_any
         disable fork;

         $fdisplay(log_fd, "# %0t  QDMA periphery monitor stopped (reset asserted)", $time);
         $fflush(log_fd);
      end
   endtask

   // ================================================================
   // report_phase — summary of all interface transaction counts
   // ================================================================
   virtual function void report_phase(uvm_phase phase);
      if (log_fd) begin
         $fdisplay(log_fd, "\n%s", {80{"-"}});
         $fdisplay(log_fd, "QPER_SUMMARY");
         $fdisplay(log_fd, "  s_axi_mem : AW=%0d  W=%0d  B=%0d  AR=%0d  R=%0d  AW_W_paired=%0d",
            cnt_mem_aw, cnt_mem_w, cnt_mem_b, cnt_mem_ar, cnt_mem_r, cnt_mem_wr_paired);
         $fdisplay(log_fd, "  s_axi_reg : WR=%0d  RD=%0d",
            cnt_reg_wr, cnt_reg_rd);
         $fdisplay(log_fd, "  m_axil_dbi: WR=%0d  B=%0d  RD=%0d  R=%0d",
            cnt_dbi_wr, cnt_dbi_b, cnt_dbi_rd, cnt_dbi_r);
         $fdisplay(log_fd, "  tm_dsc_sts: vld_fires=%0d%s", cnt_tm_dsc_sts_vld,
            have_vif_tm ? "" : " (NOT MONITORED -- bind.tm_dsc_sts.sv did not run)");
         $fdisplay(log_fd, "  msix      : REQ=%0d  GRANT=%0d  ERROR=%0d  GRANT_ERR_COINCIDENT=%0d",
            cnt_msix_req, cnt_msix_grant, cnt_msix_error,
            cnt_msix_grant_err_coincident);
         if (cnt_msix_grant_err_coincident > 0)
            $fdisplay(log_fd,
               "  msix      : %0d request(s) answered with grant AND error together -- irq_mgr scored these as delivered (mbox_irq_ack) though no MSI-X write was emitted",
               cnt_msix_grant_err_coincident);
         $fdisplay(log_fd, "  Checks    : %0d violation(s) detected", check_err_count);
         $fdisplay(log_fd, "%s", {80{"-"}});
         $fflush(log_fd);
      end
   endfunction

endclass
