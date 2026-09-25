// dma_channel_status_tracker.sv — per-HDMA-channel lifecycle status map
//
// Per-HDMA-channel lifecycle state machine, staying entirely in HDMA-channel-index
// space (channel<->qid mapping rejected as inaccurate):
//
//   IDLE -> DRBL_PROGRAMMED (DBI) -> DSC_FETCHED (NOC0) -> DMA_TRANSFERRED (AXI-PL0/1)
//        -> INT_GENERATED (DBI) -> INT_SERVICED (DBI) -> back to IDLE
//
// Subscribes to qdma_periph_agnt.ap (DBI events) and psw_agnt.ap (NOC0/PL0/1 events).
// Channel attribution:
//   - DBI: ch = addr[15:9], reg_off = addr[8:0] (decoded independently here from the
//     raw address, not by parsing qdma_periph_monitor.sv's decode_dbi() string output
//     — string-parsing a formatted decode string would be fragile).
//   - NOC0/PL0/1: reuses pswizard_monitor.sv's own decode_noc_channel() result, already
//     computed on the txn (txn.chan/txn.chan_valid) — no re-derivation here.
//
// DBI_R carries no address (see qdma_periph_monitor.sv's sample_dbi() — the read-data
// event has no addr field), so HDMA_STATUS reads are attributed via the immediately
// preceding DBI_RD's address, assumed single-outstanding (matches this DBI's AXI-Lite,
// one-request-at-a-time usage pattern).
//
// Host-side MRD/MWR corroboration (dma_req_processor.sv) is intentionally NOT wired in
// here — dma_req_processor.sv has no analysis port and is per-qid, not per-channel;
// forcing a channel index onto it would repeat the rejected channel<->qid guess. Cross-
// check the DMA_SCOREBOARD log lines in the same timeframe as DMA_TRANSFERRED by hand.
//
// This is observability only — no new checks/errors, matching the user's ask for a
// status MAP, not a scoreboard.

`uvm_analysis_imp_decl(_qper)
`uvm_analysis_imp_decl(_psw)

class dma_channel_status_tracker extends uvm_component;
   `uvm_component_utils(dma_channel_status_tracker)

   uvm_analysis_imp_qper#(qdma_periph_txn, dma_channel_status_tracker) qper_imp;
   uvm_analysis_imp_psw#(pswizard_txn, dma_channel_status_tracker)     psw_imp;

   typedef enum {
      IDLE,
      DRBL_PROGRAMMED,
      DSC_FETCHED,
      DMA_TRANSFERRED,
      INT_GENERATED,
      INT_SERVICED
   } ch_state_e;

   typedef struct {
      ch_state_e state;
      time       t_drbl;
      time       t_dsc_fetch;
      time       t_transfer;
      time       t_int_gen;
      time       t_int_svc;
      bit        ever_active;
   } ch_status_t;

   ch_status_t ch[128];

   // Per-state transition counters (all channels combined; IDLE excluded per
   // request — IDLE is a default/reset state, not a real transition event).
   int unsigned cnt_drbl_programmed;
   int unsigned cnt_dsc_fetched;
   int unsigned cnt_dma_transferred;
   int unsigned cnt_int_generated;
   int unsigned cnt_int_serviced;

   // Single-outstanding DBI_RD -> DBI_R attribution (see file header).
   local bit          last_rd_valid;
   local logic [6:0]  last_rd_ch;
   local logic [8:0]  last_rd_off;

   // DBI per-channel register offsets, per the register space documentation --
   // see qdma_periph_monitor.sv's decode_dbi().
   localparam logic [8:0] OFF_DRBL       = 9'h004;
   localparam logic [8:0] OFF_STATUS     = 9'h080;
   localparam logic [8:0] OFF_INT_CLEAR  = 9'h08c;

   function new(string name, uvm_component parent);
      super.new(name, parent);
      qper_imp = new("qper_imp", this);
      psw_imp  = new("psw_imp", this);
   endfunction

   // ---- qdma_periph_agnt.ap: DBI events ----
   virtual function void write_qper(qdma_periph_txn t);
      logic [6:0] ch_idx;
      logic [8:0] reg_off;
      case (t.txn_type)
         qdma_periph_txn::DBI_WR: begin
            ch_idx  = t.addr[15:9];
            reg_off = t.addr[8:0];
            if (reg_off == OFF_DRBL) begin
               ch[ch_idx].state       = DRBL_PROGRAMMED;
               ch[ch_idx].t_drbl      = t.timestamp_ns;
               ch[ch_idx].ever_active = 1'b1;
               cnt_drbl_programmed++;
            end else if (reg_off == OFF_INT_CLEAR) begin
               // Per the user-specified state machine, INT_SERVICED is
               // followed by "back to IDLE" — left implicit rather than
               // immediately overwritten here, so the summary table still
               // shows INT_SERVICED as the last real transition for a
               // channel that completed its lifecycle (the channel returns
               // to IDLE in effect the next time DRBL_PROGRAMMED fires for
               // it again).
               ch[ch_idx].state     = INT_SERVICED;
               ch[ch_idx].t_int_svc = t.timestamp_ns;
               cnt_int_serviced++;
            end
         end
         qdma_periph_txn::DBI_RD: begin
            last_rd_ch    = t.addr[15:9];
            last_rd_off   = t.addr[8:0];
            last_rd_valid = 1'b1;
         end
         qdma_periph_txn::DBI_R: begin
            if (last_rd_valid && last_rd_off == OFF_STATUS) begin
               // HDMA_STATUS[1:0]: 0=STOPPED, 1=RUNNING, 3=HALTED (per the register
               // space documentation's own ISR flow description). Non-RUNNING is
               // the DBI-side "interrupt generated" signal for this channel.
               if (t.data[1:0] != 2'b01) begin
                  ch[last_rd_ch].state     = INT_GENERATED;
                  ch[last_rd_ch].t_int_gen = t.timestamp_ns;
                  cnt_int_generated++;
               end
            end
            last_rd_valid = 1'b0;
         end
         default: ; // other qdma_periph events not part of this state machine
      endcase
   endfunction

   // ---- psw_agnt.ap: NOC0 (DSC_FETCHED) + PL0/1 (DMA_TRANSFERRED) events ----
   virtual function void write_psw(pswizard_txn t);
      if (!t.chan_valid) return;
      case (t.txn_type)
         pswizard_txn::PSW_NOC_AW, pswizard_txn::PSW_NOC_AR: begin
            if (t.port == 1'b0) begin // NOC0 only, per user scope
               ch[t.chan].state       = DSC_FETCHED;
               ch[t.chan].t_dsc_fetch = t.timestamp_ns;
               ch[t.chan].ever_active = 1'b1;
               cnt_dsc_fetched++;
            end
         end
         pswizard_txn::PSW_PL_AW, pswizard_txn::PSW_PL_AR: begin
            ch[t.chan].state      = DMA_TRANSFERRED;
            ch[t.chan].t_transfer = t.timestamp_ns;
            ch[t.chan].ever_active = 1'b1;
            cnt_dma_transferred++;
         end
         default: ;
      endcase
   endfunction

   local function string state_name(ch_state_e s);
      case (s)
         IDLE:            return "IDLE";
         DRBL_PROGRAMMED: return "DRBL_PROGRAMMED";
         DSC_FETCHED:     return "DSC_FETCHED";
         DMA_TRANSFERRED: return "DMA_TRANSFERRED";
         INT_GENERATED:   return "INT_GENERATED";
         INT_SERVICED:    return "INT_SERVICED";
         default:         return "UNKNOWN";
      endcase
   endfunction

   virtual function void report_phase(uvm_phase phase);
      int log_fd;
      if (!uvm_config_db#(int)::get(this, "", "log_fd", log_fd)) return;
      if (!log_fd) return;
      $fdisplay(log_fd, "\n%s", {80{"="}});
      $fdisplay(log_fd, "=== DMA_CHANNEL_STATUS_MAP -- per-channel lifecycle (no channel<->qid mapping) ===");
      $fdisplay(log_fd, "    States: IDLE DRBL_PROGRAMMED DSC_FETCHED DMA_TRANSFERRED INT_GENERATED INT_SERVICED");
      $fdisplay(log_fd, "%s", {80{"="}});
      $fdisplay(log_fd,
         "    Transition counts (all channels, IDLE excluded): DRBL_PROGRAMMED=%0d  DSC_FETCHED=%0d  DMA_TRANSFERRED=%0d  INT_GENERATED=%0d  INT_SERVICED=%0d",
         cnt_drbl_programmed, cnt_dsc_fetched, cnt_dma_transferred, cnt_int_generated, cnt_int_serviced);
      for (int c = 0; c < 128; c++) begin
         if (ch[c].ever_active) begin
            $fdisplay(log_fd,
               "  ch=%0d  state=%-16s  t_drbl=%0t  t_dsc_fetch=%0t  t_transfer=%0t  t_int_gen=%0t  t_int_svc=%0t",
               c, state_name(ch[c].state), ch[c].t_drbl, ch[c].t_dsc_fetch,
               ch[c].t_transfer, ch[c].t_int_gen, ch[c].t_int_svc);
         end
      end
      $fdisplay(log_fd,
         "  NOTE: host-side MRD/MWR corroboration (dma_req_processor.sv, per-qid) is NOT");
      $fdisplay(log_fd,
         "  indexed here -- cross-check DMA_SCOREBOARD log lines in the same timeframe by hand.");
      $fdisplay(log_fd, "%s\n", {80{"="}});
      $fflush(log_fd);
   endfunction

endclass
