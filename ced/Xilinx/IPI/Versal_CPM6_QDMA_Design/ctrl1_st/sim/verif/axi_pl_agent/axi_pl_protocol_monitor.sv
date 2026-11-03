// (c) Copyright 2026 Advanced Micro Devices, Inc. All rights reserved.
//
// axi_pl_protocol_monitor.sv — Passive protocol/error checker for the
// cpm_axi_pl AXI4 ports (PL0/PL1/PL3).
//
// Log tag: AXIPL
//
// Checks:
//   AXIPL_BRESP_ERR — write response != OKAY (SLVERR/DECERR/RESERVED)
//   AXIPL_RRESP_ERR — read response != OKAY on any beat
//   AXIPL_XPROP     — X/Z on a valid-qualified handshake signal
//
// Byte accounting: h2c_bytes_written accumulates $countones(wstrb) on every
// wvalid&&wready W-beat — the bytes that actually reached this AXI-PL port,
// independent of host-side byte counting. Read at end of test by
// TSK_SLT_REPORT_PERF in qdma_base_test.sv. There is no read-side (C2H) byte
// counter.

`ifndef __AXI_PL_PROTOCOL_MONITOR__SV__
`define __AXI_PL_PROTOCOL_MONITOR__SV__

class axi_pl_protocol_monitor extends uvm_monitor;
   `uvm_component_utils(axi_pl_protocol_monitor)

   // AXI-PL clock/width are fixed by the block design (ps_wizard_0 cpm_axi_pl*
   // ports, 512-bit DATA_WIDTH). Theoretical max
   // = 250 MHz * 64 bytes/cycle = 16.0 GB/s.
   localparam real AXI_PL_CLK_MHZ    = 250.0;
   localparam real AXI_PL_WIDTH_BYTES = 64.0;   // 512 bits / 8
   localparam real AXI_PL_MAX_BW_GBPS = (AXI_PL_CLK_MHZ * AXI_PL_WIDTH_BYTES) / 1000.0;

   virtual axi_if vif;
   int log_fd;
   int port_id;
   bit checks_enable = 1'b1;

   int bresp_err_count = 0;
   int rresp_err_count = 0;
   int xprop_count     = 0;

   // H2C bytes actually written to this AXI-PL port — the authoritative
   // "arrived at destination" evidence, independent of host-side counting.
   longint unsigned h2c_bytes_written = 0;

   // Per-burst-address byte accounting: keyed by the AWADDR that opened the
   // burst, not by qid. Single-outstanding-write assumption:
   // the most recent AWADDR is held as the active burst's address until the
   // next AW handshake or wlast, so all W-beats between AW and wlast are
   // attributed to that one address.
   longint unsigned h2c_bytes_by_addr[bit [63:0]];
   bit [63:0] cur_burst_awaddr;
   bit        aw_seen;

   // AXI-PL bandwidth cycle breakdown — per-channel cycle counts for
   // bandwidth analysis on the W (H2C) and R (C2H) data channels. Counting on
   // each channel starts only from that channel's own first valid cycle (w_started/r_started
   // latches) so pre-traffic idle time before the DMA transfer stream begins
   // is excluded from no_data_*_cyc.
   bit w_started;
   bit r_started;
   longint unsigned active_h2c_cyc   = 0;   // wvalid && wready
   longint unsigned mem_busy_h2c_cyc = 0;   // wvalid && !wready
   longint unsigned no_data_h2c_cyc  = 0;   // !wvalid (post first-valid only)
   longint unsigned active_c2h_cyc   = 0;   // rvalid && rready
   longint unsigned mem_busy_c2h_cyc = 0;   // rvalid && !rready
   longint unsigned no_data_c2h_cyc  = 0;   // !rvalid (post first-valid only)

   // Achieved-throughput timing (% of AXI_PL_MAX_BW_GBPS).
   // Window = first valid (same edge as w_started/r_started above) to the
   // last accepted beat, so it lines up with the active/mem_busy/no_data
   // cycle breakdown rather than measuring wall-clock time including
   // trailing post-transfer idle.
   realtime h2c_start_time;
   realtime h2c_last_beat_time;
   realtime c2h_start_time;
   realtime c2h_last_beat_time;

   // --- AW/AR ADDRESS CAPTURE ----------------------------------------------------
   // Every AW and AR handshake is logged with its full address and burst
   // shape, responses are correlated back to the address that caused them, and
   // the aggregate ranges are reported unconditionally.
   int        aw_count = 0;
   int        ar_count = 0;
   bit [63:0] aw_addr_min = '1;
   bit [63:0] aw_addr_max = '0;
   bit [63:0] ar_addr_min = '1;
   bit [63:0] ar_addr_max = '0;
   bit [63:0] cur_burst_araddr;
   bit        ar_seen;
   int        aw_addr_seen[bit [63:0]];   // distinct AW addresses
   int        ar_addr_seen[bit [63:0]];   // distinct AR addresses

   // Per-burst detail-log cap. 0 = unlimited (the default): AW/AR fire once per
   // BURST, not per beat, so volume is bounded by descriptor count, and the whole
   // point of this capture is to have the address when something goes wrong late
   // in a run. Override with +AXIPL_ADDR_LOG_MAX=<n> on a run that would otherwise
   // produce an unmanageable log. The SUMMARY aggregates below are NEVER capped,
   // and a truncation notice is emitted exactly once.
   int addr_log_max = 0;
   int aw_logged    = 0;
   int ar_logged    = 0;

   // --- B-vs-R BEAT COINCIDENCE ---------------------------------------------
   // Read and write traffic of different HDMA channels share this port. When a
   // write response (B) is accepted in the same cycle as a read data beat (R),
   // the cycle is logged with both channels' tags, the R beat's index within its
   // burst, and how many write bursts the B's channel still has outstanding. A
   // B that leaves its channel with none outstanding is that channel's last
   // write so far ("drain"). The channel tag is user[31:24] on AR/AW.
   // R beats are matched to bursts per ARID in issue order, B responses to
   // bursts per AWID in issue order (AXI ordering within an ID).
   typedef struct {
      bit [7:0]        tag;
      bit [63:0]       addr;
      int unsigned     len;
      int unsigned     beat;
   } rd_burst_t;
   rd_burst_t   rd_bursts[int][$];     // outstanding read bursts per ARID
   bit [7:0]    wr_tags[int][$];       // channel tag of outstanding write bursts per AWID
   int unsigned wr_out_by_tag[int];    // outstanding write bursts per channel tag
   int unsigned br_coincide_cnt   = 0;
   int unsigned br_odd_cnt        = 0;
   int unsigned br_even_cnt       = 0;
   int unsigned br_odd_drain_cnt  = 0;
   int unsigned br_even_drain_cnt = 0;
   // R beats / B responses whose ID has no tracked AR/AW. Non-zero means the
   // tag attribution above cannot be trusted (missed address handshake, tap
   // not connected, or tracking state lost), so coincidence counts are suspect.
   int unsigned br_unmatched_r    = 0;
   int unsigned br_unmatched_b    = 0;

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
         `uvm_fatal("axi_pl_protocol_monitor", "Failed to get virtual axi_if")
      if (!uvm_config_db#(int)::get(this, "", "port_id", port_id))
         port_id = -1;
      if (!uvm_config_db#(int)::get(this, "", "log_fd", log_fd))
         log_fd = 1;
      void'($value$plusargs("AXIPL_ADDR_LOG_MAX=%d", addr_log_max));
   endfunction

   task run_phase(uvm_phase phase);
      logic prev_bvalid, prev_bready;
      logic prev_rvalid, prev_rready;
      prev_bvalid = 1'b0; prev_bready = 1'b0;
      prev_rvalid = 1'b0; prev_rready = 1'b0;

      forever begin
         @(posedge vif.aclk);

         // Track the active burst's address (AW handshake) for per-address
         // byte attribution below. Captured before the W-beat check so a
         // same-cycle AW+W (common for single-beat bursts) attributes
         // correctly.
         if (vif.awvalid && vif.awready) begin
            cur_burst_awaddr = vif.awaddr;
            aw_seen          = 1'b1;

            // Address capture: aggregates first (never capped), then detail.
            aw_count++;
            if (vif.awaddr < aw_addr_min) aw_addr_min = vif.awaddr;
            if (vif.awaddr > aw_addr_max) aw_addr_max = vif.awaddr;
            aw_addr_seen[vif.awaddr] = aw_addr_seen.exists(vif.awaddr) ?
                                       aw_addr_seen[vif.awaddr] + 1 : 1;
            if (addr_log_max == 0 || aw_logged < addr_log_max) begin
               aw_logged++;
               $fdisplay(log_fd,
                  "%0.0f ns  AXIPL  AXIPL_AW  port=%0d  addr=0x%016h  id=0x%0h  len=%0d  size=%0d  burst=%0d  cache=0x%0h  prot=0x%0h  bytes=%0d",
                  $realtime/1ns, port_id, vif.awaddr, vif.awid, vif.awlen, vif.awsize,
                  vif.awburst, vif.awcache, vif.awprot,
                  (int'(vif.awlen) + 1) << int'(vif.awsize));
               $fflush(log_fd);
            end else if (aw_logged == addr_log_max) begin
               aw_logged++;
               $fdisplay(log_fd,
                  "%0.0f ns  AXIPL  AXIPL_AW  port=%0d  DETAIL LOG TRUNCATED at %0d entries - further AW bursts counted in SUMMARY but not listed (raise with +AXIPL_ADDR_LOG_MAX)",
                  $realtime/1ns, port_id, addr_log_max);
               $fflush(log_fd);
            end
         end

         // Read address capture.
         if (vif.arvalid && vif.arready) begin
            cur_burst_araddr = vif.araddr;
            ar_seen          = 1'b1;

            ar_count++;
            if (vif.araddr < ar_addr_min) ar_addr_min = vif.araddr;
            if (vif.araddr > ar_addr_max) ar_addr_max = vif.araddr;
            ar_addr_seen[vif.araddr] = ar_addr_seen.exists(vif.araddr) ?
                                       ar_addr_seen[vif.araddr] + 1 : 1;
            if (addr_log_max == 0 || ar_logged < addr_log_max) begin
               ar_logged++;
               $fdisplay(log_fd,
                  "%0.0f ns  AXIPL  AXIPL_AR  port=%0d  addr=0x%016h  id=0x%0h  len=%0d  size=%0d  burst=%0d  cache=0x%0h  prot=0x%0h  bytes=%0d",
                  $realtime/1ns, port_id, vif.araddr, vif.arid, vif.arlen, vif.arsize,
                  vif.arburst, vif.arcache, vif.arprot,
                  (int'(vif.arlen) + 1) << int'(vif.arsize));
               $fflush(log_fd);
            end else if (ar_logged == addr_log_max) begin
               ar_logged++;
               $fdisplay(log_fd,
                  "%0.0f ns  AXIPL  AXIPL_AR  port=%0d  DETAIL LOG TRUNCATED at %0d entries - further AR bursts counted in SUMMARY but not listed (raise with +AXIPL_ADDR_LOG_MAX)",
                  $realtime/1ns, port_id, addr_log_max);
               $fflush(log_fd);
            end
         end

         // H2C byte accounting — every accepted W-beat, regardless of the
         // eventual B response (an errored write still means bytes were
         // driven onto this port; the byte total and the BRESP check are
         // independent evidence).
         if (vif.wvalid && vif.wready) begin
            h2c_bytes_written += longint'($countones(vif.wstrb));
            if (aw_seen)
               h2c_bytes_by_addr[cur_burst_awaddr] += longint'($countones(vif.wstrb));
            if (vif.wlast)
               aw_seen = 1'b0;
         end

         // W-channel (H2C) bandwidth cycle breakdown
         if (!w_started && vif.wvalid) begin
            w_started      = 1'b1;
            h2c_start_time = $realtime;
         end
         if (w_started) begin
            if (vif.wvalid && vif.wready) begin
               active_h2c_cyc++;
               h2c_last_beat_time = $realtime;
            end
            else if (vif.wvalid && !vif.wready)
               mem_busy_h2c_cyc++;
            else
               no_data_h2c_cyc++;
         end

         // R-channel (C2H) bandwidth cycle breakdown
         if (!r_started && vif.rvalid) begin
            r_started      = 1'b1;
            c2h_start_time = $realtime;
         end
         if (r_started) begin
            if (vif.rvalid && vif.rready) begin
               active_c2h_cyc++;
               c2h_last_beat_time = $realtime;
            end
            else if (vif.rvalid && !vif.rready)
               mem_busy_c2h_cyc++;
            else
               no_data_c2h_cyc++;
         end

         // Write response check — fires once per B handshake
         if (vif.bvalid && vif.bready && !(prev_bvalid && prev_bready)) begin
            if (checks_enable) begin
               if ($isunknown(vif.bresp)) begin
                  xprop_count++;
                  `uvm_error("axi_pl_protocol_monitor", $sformatf(
                     "AXIPL_XPROP: PL%0d bresp is X/Z at a bvalid&&bready handshake", port_id))
               end else if (vif.bresp != 2'b00) begin
                  bresp_err_count++;
                  // resp names: 0=OKAY 1=EXOKAY 2=SLVERR 3=DECERR.
                  `uvm_error("axi_pl_protocol_monitor", $sformatf(
                     {"AXIPL_BRESP_ERR: PL%0d write response=0x%0h (%s) addr=0x%016h id=0x%0h",
                      "  -  expected OKAY(2'b00)"},
                     port_id, vif.bresp,
                     (vif.bresp == 2'b11) ? "DECERR" : (vif.bresp == 2'b10) ? "SLVERR" : "EXOKAY",
                     aw_seen ? cur_burst_awaddr : 64'hDEAD_DEAD_DEAD_DEAD, vif.bid))
               end
               // addr= is the AWADDR that opened the burst this response closes
               // (single-outstanding assumption, as documented for
               // h2c_bytes_by_addr above).
               $fdisplay(log_fd,
                  "%0.0f ns  AXIPL  BRESP  port=%0d  id=0x%0h  resp=0x%0h  addr=0x%016h",
                  $realtime/1ns, port_id, vif.bid, vif.bresp,
                  aw_seen ? cur_burst_awaddr : 64'hDEAD_DEAD_DEAD_DEAD);
               $fflush(log_fd);
            end
         end

         // Read response check — fires on every R beat (each beat carries its own resp)
         if (vif.rvalid && vif.rready) begin
            if (checks_enable) begin
               if ($isunknown(vif.rresp)) begin
                  xprop_count++;
                  `uvm_error("axi_pl_protocol_monitor", $sformatf(
                     "AXIPL_XPROP: PL%0d rresp is X/Z at an rvalid&&rready handshake", port_id))
               end else if (vif.rresp != 2'b00) begin
                  rresp_err_count++;
                  `uvm_error("axi_pl_protocol_monitor", $sformatf(
                     {"AXIPL_RRESP_ERR: PL%0d read response=0x%0h (%s) addr=0x%016h id=0x%0h",
                      "  -  expected OKAY(2'b00)"},
                     port_id, vif.rresp,
                     (vif.rresp == 2'b11) ? "DECERR" : (vif.rresp == 2'b10) ? "SLVERR" : "EXOKAY",
                     ar_seen ? cur_burst_araddr : 64'hDEAD_DEAD_DEAD_DEAD, vif.rid))
                  // Emit the failing beat unconditionally, not only its count.
                  $fdisplay(log_fd,
                     "%0.0f ns  AXIPL  RRESP_ERR  port=%0d  id=0x%0h  resp=0x%0h  addr=0x%016h  last=%0b",
                     $realtime/1ns, port_id, vif.rid, vif.rresp,
                     ar_seen ? cur_burst_araddr : 64'hDEAD_DEAD_DEAD_DEAD, vif.rlast);
                  $fflush(log_fd);
               end
            end
         end

         track_br_coincidence();

         prev_bvalid = vif.bvalid; prev_bready = vif.bready;
         prev_rvalid = vif.rvalid; prev_rready = vif.rready;
      end
   endtask

   // Called once per aclk edge. Every handshake is evaluated per cycle (not on
   // valid&&ready edges), so back-to-back beats and responses are all counted.
   function void track_br_coincidence();
      bit          r_hs, b_hs;
      int          rid, bid;
      int          r_beat = -1;
      int unsigned r_len;
      bit [7:0]    r_tag, b_tag;
      bit [63:0]   r_addr;
      bit          b_known = 1'b0;
      int unsigned b_out_after;
      rd_burst_t   nb;

      // Outstanding bursts do not survive a reset of the port.
      if (!vif.aresetn) begin
         rd_bursts.delete();
         wr_tags.delete();
         wr_out_by_tag.delete();
         return;
      end

      if (vif.arvalid && vif.arready) begin
         nb.tag  = vif.aruser[31:24];
         nb.addr = vif.araddr;
         nb.len  = int'(vif.arlen) + 1;
         nb.beat = 0;
         rd_bursts[int'(vif.arid)].push_back(nb);
      end
      if (vif.awvalid && vif.awready) begin
         wr_tags[int'(vif.awid)].push_back(vif.awuser[31:24]);
         wr_out_by_tag[int'(vif.awuser[31:24])] =
            wr_out_by_tag.exists(int'(vif.awuser[31:24])) ? wr_out_by_tag[int'(vif.awuser[31:24])] + 1 : 1;
      end

      r_hs = vif.rvalid && vif.rready;
      b_hs = vif.bvalid && vif.bready;

      if (r_hs) begin
         rid = int'(vif.rid);
         if (rd_bursts.exists(rid) && rd_bursts[rid].size() > 0) begin
            r_beat = int'(rd_bursts[rid][0].beat);
            r_len  = rd_bursts[rid][0].len;
            r_tag  = rd_bursts[rid][0].tag;
            r_addr = rd_bursts[rid][0].addr;
            rd_bursts[rid][0].beat++;
            if (vif.rlast) void'(rd_bursts[rid].pop_front());
         end else
            br_unmatched_r++;
      end

      if (b_hs) begin
         bid = int'(vif.bid);
         if (wr_tags.exists(bid) && wr_tags[bid].size() > 0) begin
            b_tag   = wr_tags[bid].pop_front();
            b_known = 1'b1;
            if (wr_out_by_tag.exists(int'(b_tag)) && wr_out_by_tag[int'(b_tag)] > 0)
               wr_out_by_tag[int'(b_tag)]--;
            b_out_after = wr_out_by_tag.exists(int'(b_tag)) ? wr_out_by_tag[int'(b_tag)] : 0;
         end else
            br_unmatched_b++;
      end

      if (r_hs && b_hs && r_beat >= 0 && b_known) begin
         // Assigned as string variables: a ternary of string literals is
         // sized to the longer literal, which pads the shorter one with spaces.
         string par_s, drain_s;
         if (r_beat % 2) par_s = "odd";
         else            par_s = "even";
         drain_s = "";
         if (b_out_after == 0 && (r_beat % 2)) drain_s = "  odd_drain";
         br_coincide_cnt++;
         if (r_beat % 2) begin
            br_odd_cnt++;
            if (b_out_after == 0) br_odd_drain_cnt++;
         end else begin
            br_even_cnt++;
            if (b_out_after == 0) br_even_drain_cnt++;
         end
         $fdisplay(log_fd,
            "%0.0f ns  AXIPL  BR_COINCIDE  port=%0d  b_tag=0x%02h  b_slot=%0d  b_out_after=%0d  r_tag=0x%02h  r_slot=%0d  r_addr=0x%016h  beat=%0d/%0d  parity=%s%s",
            $realtime/1ns, port_id, b_tag, b_tag >> 1, b_out_after, r_tag, r_tag >> 1, r_addr,
            r_beat, r_len, par_s, drain_s);
         $fflush(log_fd);
      end
   endfunction

   // Called from report_phase() and pre_abort(): report_phase() does not run
   // when the sim ends via UVM_FATAL.
   function void print_summary();
      real h2c_elapsed_ns, c2h_elapsed_ns;
      real h2c_achieved_gbps, c2h_achieved_gbps;
      real h2c_pct_of_max, c2h_pct_of_max;
      longint unsigned c2h_bytes_est;

      $fdisplay(log_fd,
         "%0.0f ns  AXIPL  SUMMARY  port=%0d  bresp_errors=%0d  rresp_errors=%0d  xprop=%0d  h2c_bytes_written=%0d",
         $realtime/1ns, port_id, bresp_err_count, rresp_err_count, xprop_count, h2c_bytes_written);

      // Address-activity aggregate. NEVER capped by +AXIPL_ADDR_LOG_MAX. Read this
      // line first when a port looks dead: aw_bursts=0 states outright that no
      // write address was ever driven on this port. min/max/distinct localise where
      // traffic actually went without trawling the per-burst detail.
      $fdisplay(log_fd,
         "%0.0f ns  AXIPL  ADDR_SUMMARY  port=%0d  aw_bursts=%0d  aw_distinct=%0d  aw_min=0x%016h  aw_max=0x%016h  ar_bursts=%0d  ar_distinct=%0d  ar_min=0x%016h  ar_max=0x%016h",
         $realtime/1ns, port_id,
         aw_count, aw_addr_seen.size(),
         (aw_count == 0) ? 64'h0 : aw_addr_min, (aw_count == 0) ? 64'h0 : aw_addr_max,
         ar_count, ar_addr_seen.size(),
         (ar_count == 0) ? 64'h0 : ar_addr_min, (ar_count == 0) ? 64'h0 : ar_addr_max);
      $fdisplay(log_fd,
         "%0.0f ns  AXIPL  BW_CYC  port=%0d  active_h2c_cyc=%0d  mem_busy_h2c_cyc=%0d  no_data_h2c_cyc=%0d  active_c2h_cyc=%0d  mem_busy_c2h_cyc=%0d  no_data_c2h_cyc=%0d",
         $realtime/1ns, port_id, active_h2c_cyc, mem_busy_h2c_cyc, no_data_h2c_cyc,
         active_c2h_cyc, mem_busy_c2h_cyc, no_data_c2h_cyc);

      // Achieved throughput vs. theoretical max (AXI_PL_MAX_BW_GBPS). H2C uses
      // the h2c_bytes_written counter above. C2H has no byte counter — bytes
      // are estimated as active_c2h_cyc * full port width, which assumes every
      // active R-beat is a full 512b transfer. bytes/ns is numerically equal
      // to GB/s (decimal GB, same convention as AXI_PL_MAX_BW_GBPS's derivation above).
      h2c_elapsed_ns    = real'((h2c_last_beat_time - h2c_start_time) / 1ns);
      h2c_achieved_gbps = (h2c_elapsed_ns > 0.0) ? real'(h2c_bytes_written) / h2c_elapsed_ns : 0.0;
      h2c_pct_of_max    = 100.0 * h2c_achieved_gbps / AXI_PL_MAX_BW_GBPS;

      c2h_bytes_est     = longint'(active_c2h_cyc) * longint'(AXI_PL_WIDTH_BYTES);
      c2h_elapsed_ns    = real'((c2h_last_beat_time - c2h_start_time) / 1ns);
      c2h_achieved_gbps = (c2h_elapsed_ns > 0.0) ? real'(c2h_bytes_est) / c2h_elapsed_ns : 0.0;
      c2h_pct_of_max    = 100.0 * c2h_achieved_gbps / AXI_PL_MAX_BW_GBPS;

      $fdisplay(log_fd,
         "%0.0f ns  AXIPL  THROUGHPUT  port=%0d  max_bw_gbps=%0.1f  h2c_achieved_gbps=%0.3f  h2c_pct_of_max=%0.1f  c2h_achieved_gbps=%0.3f  c2h_pct_of_max=%0.1f  c2h_bytes_estimated=%0d",
         $realtime/1ns, port_id, AXI_PL_MAX_BW_GBPS, h2c_achieved_gbps, h2c_pct_of_max,
         c2h_achieved_gbps, c2h_pct_of_max, c2h_bytes_est);
      $fdisplay(log_fd,
         "%0.0f ns  AXIPL  BR_SUMMARY  port=%0d  coincidences=%0d  odd=%0d  even=%0d  odd_drain=%0d  even_drain=%0d  unmatched_r=%0d  unmatched_b=%0d",
         $realtime/1ns, port_id, br_coincide_cnt, br_odd_cnt, br_even_cnt,
         br_odd_drain_cnt, br_even_drain_cnt, br_unmatched_r, br_unmatched_b);
      $fflush(log_fd);
   endfunction

   function void report_phase(uvm_phase phase);
      print_summary();
   endfunction

   function void pre_abort();
      print_summary();
   endfunction

endclass : axi_pl_protocol_monitor

`endif // __AXI_PL_PROTOCOL_MONITOR__SV__
