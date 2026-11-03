// (c) Copyright 2026 Advanced Micro Devices, Inc. All rights reserved.
//
// dsc_crdt_monitor.sv — Passive UVM monitor for DSC_CRDT handshake.
//
// Observes handshake completions (vld & rdy) and logs each credit
// transaction with tag DCRD to cpm6_qdma_dbg.log.
//
// Fence/credit tracking:
//   fence=1 means each credit triggers an immediate descriptor fetch; fence=0
//   means credits accumulate for that qid until it is processed. This monitor
//   cannot observe when accumulated credits are consumed — it reports per-qid
//   lifetime credit totals and fence=0/fence=1 event counts, plus two checks:
//     DCRD_XPROP     — X/Z on qid/crdt/dir/fence at a vld&&rdy handshake
//     DCRD_ZERO_CRDT — crdt=0 given on a handshake (degenerate/likely
//                      unintentional credit grant)

`ifndef __DSC_CRDT_MONITOR__SV__
`define __DSC_CRDT_MONITOR__SV__

class dsc_crdt_monitor extends uvm_monitor;
   `uvm_component_utils(dsc_crdt_monitor)

   virtual dsc_crdt_if vif;
   int log_fd;
   uvm_analysis_port#(dsc_crdt_seq_item) ap;
   int unsigned txn_count;

   // Fence/credit tracking
   int unsigned qid_credit_total[int];  // lifetime sum of crdt per qid (both dirs combined by qid)
   int unsigned qid_fence1_cnt[int];    // fence=1 (immediate-fetch) event count per qid
   int unsigned qid_fence0_cnt[int];    // fence=0 (accumulate) event count per qid
   int unsigned xprop_count;
   int unsigned zero_crdt_count;

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      ap = new("ap", this);
      if (!uvm_config_db#(virtual dsc_crdt_if)::get(this, "", "vif", vif))
         `uvm_fatal("dsc_crdt_monitor", "Failed to get dsc_crdt_if from config_db")
      if (!uvm_config_db#(int)::get(this, "", "log_fd", log_fd))
         log_fd = 1;
   endfunction

   // ----------------------------------------------------------------
   // Reset internal state — called on initial start and on reset
   // re-assertion mid-simulation.
   // ----------------------------------------------------------------
   local function void clear_state();
      txn_count = 0;
      qid_credit_total.delete();
      qid_fence1_cnt.delete();
      qid_fence0_cnt.delete();
      xprop_count = 0;
      zero_crdt_count = 0;
   endfunction

   task run_phase(uvm_phase phase);
      forever begin
         // Wait for reset to deassert (rst_n is active-low)
         @(posedge vif.rst_n);
         clear_state();
         $fdisplay(log_fd,
            "%0t ns  [DCRD]  MON  reset deasserted  -  monitor (re)started",
            $realtime/1ns);
         $fflush(log_fd);

         fork
            begin : monitor_logic
               forever begin
                  @(vif.mon_cb);
                  if (vif.mon_cb.vld && vif.mon_cb.rdy) begin
                     dsc_crdt_seq_item txn = dsc_crdt_seq_item::type_id::create("txn");
                     int qid_int;
                     txn.qid   = vif.mon_cb.qid;
                     txn.crdt  = vif.mon_cb.crdt;
                     txn.dir   = vif.mon_cb.dir;
                     txn.fence = vif.mon_cb.fence;
                     ap.write(txn);
                     txn_count++;
                     $fdisplay(log_fd,
                        "%0t ns  [DCRD]  MON  qid=%0d  crdt=%0d  dir=%s  fence=%0b  count=%0d",
                        $realtime/1ns, txn.qid, txn.crdt,
                        txn.dir ? "C2H" : "H2C", txn.fence, txn_count);
                     $fflush(log_fd);

                     // DCRD_XPROP — X/Z on any field of a live handshake
                     if ($isunknown(vif.mon_cb.qid) || $isunknown(vif.mon_cb.crdt) ||
                         $isunknown(vif.mon_cb.dir) || $isunknown(vif.mon_cb.fence)) begin
                        xprop_count++;
                        `uvm_error("dsc_crdt_monitor", $sformatf(
                           "DCRD_XPROP: X/Z on qid/crdt/dir/fence at a vld&&rdy handshake  -  qid=%0d crdt=%0d dir=%0d fence=%0d",
                           vif.mon_cb.qid, vif.mon_cb.crdt, vif.mon_cb.dir, vif.mon_cb.fence))
                     end

                     // DCRD_ZERO_CRDT — crdt=0 granted (degenerate/likely unintentional)
                     if (txn.crdt == 16'h0) begin
                        zero_crdt_count++;
                        `uvm_warning("dsc_crdt_monitor", $sformatf(
                           "DCRD_ZERO_CRDT: qid=%0d dir=%s fence=%0b granted crdt=0  -  likely unintentional credit grant",
                           txn.qid, txn.dir ? "C2H" : "H2C", txn.fence))
                     end

                     // Fence/credit semantic tracking (informational — see file header)
                     qid_int = int'(txn.qid);
                     if (!qid_credit_total.exists(qid_int)) qid_credit_total[qid_int] = 0;
                     qid_credit_total[qid_int] += txn.crdt;
                     if (txn.fence) begin
                        if (!qid_fence1_cnt.exists(qid_int)) qid_fence1_cnt[qid_int] = 0;
                        qid_fence1_cnt[qid_int]++;
                     end else begin
                        if (!qid_fence0_cnt.exists(qid_int)) qid_fence0_cnt[qid_int] = 0;
                        qid_fence0_cnt[qid_int]++;
                     end
                  end
               end
            end : monitor_logic

            begin : reset_watch
               @(negedge vif.rst_n);
               $fdisplay(log_fd,
                  "%0t ns  [DCRD]  MON  reset asserted  -  reinitializing",
                  $realtime/1ns);
               $fflush(log_fd);
            end : reset_watch
         join_any
         disable fork;
      end
   endtask

   function void report_phase(uvm_phase phase);
      int qid_int;
      $fdisplay(log_fd,
         "%0t ns  [DCRD]  SUMMARY  total_credits=%0d  xprop=%0d  zero_crdt=%0d",
         $realtime/1ns, txn_count, xprop_count, zero_crdt_count);
      if (qid_credit_total.first(qid_int)) begin
         do begin
            int f1, f0;
            f1 = qid_fence1_cnt.exists(qid_int) ? qid_fence1_cnt[qid_int] : 0;
            f0 = qid_fence0_cnt.exists(qid_int) ? qid_fence0_cnt[qid_int] : 0;
            $fdisplay(log_fd,
               "%0t ns  [DCRD]  QID_SUMMARY  qid=%0d  total_credit=%0d  fence1_cnt=%0d  fence0_cnt=%0d",
               $realtime/1ns, qid_int, qid_credit_total[qid_int], f1, f0);
         end while (qid_credit_total.next(qid_int));
      end
      $fflush(log_fd);
   endfunction

endclass : dsc_crdt_monitor

`endif // __DSC_CRDT_MONITOR__SV__
