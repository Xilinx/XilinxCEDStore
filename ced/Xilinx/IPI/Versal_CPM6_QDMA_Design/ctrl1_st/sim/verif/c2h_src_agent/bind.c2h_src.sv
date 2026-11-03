// bind.c2h_src.sv — observers for the example-design card-to-host stream
// source: the per-port burst controllers (c2h_source_ctrl) and the
// host-programmed control block (c2h_source_cfg, reached from the host
// through AXI-PL3).
//
// Streaming builds only. It needs the register-driven controllers (QID / NUM_PKT /
// START per port) and the wrapper's u_c2h_src_cfg.
//
// Per controller (bound to every c2h_source_ctrl instance):
//   - each burst start and end: port, queue, packets requested, burst
//     sequence, packet length; packets sent and whether a STOP was taken
//   - each packet start: queue, packet index in the burst, length, first beat
//     index
//   - a burst that ends with fewer packets than requested without a STOP, or
//     with more, is an error
//   - a packet started after a STOP was taken is an error
//   - per packet on the stream: c2h_ctrl_qid must be the burst's queue, the
//     first beat must carry the burst's data seed {qid, burst sequence, beat
//     index}, c2h_ctrl_len must equal the packet's beats x 64, and the beats
//     sent must equal the packet's beats
//   - a stream beat while the controller is idle is an error
// At the wrapper:
//   - publishes the descriptor-status events as vif_c2h_tm_dsc_sts
//     (qdma_periph_tm_dsc_if) for the test's doorbell-to-START barrier
//   - per queue, descriptors posted (descriptor-status events, C2H) against
//     descriptors used by the packets started for the queue; a packet started
//     beyond the posted descriptors will be dropped by the DMA, which is an
//     error unless +C2H_EXPECT_PFCH_DROP
// Configuration block (bound to `CPM6_BD_TOP_WRAPPER):
//   - every write with its register, data, strobes and accept / reject code;
//     a reject is a warning unless +C2H_SRC_CFG_NEG (reject checks) is given,
//     except a rejected START, QID, NUM_PKT or PKT_BYTES because the port was
//     busy (code 6), which is an error: the burst software asked for did not
//     run as written
//   - every read with its offset and data
//   - the raw 64-bit addresses on the host-side AXI-Lite channel
//   - a non-OKAY response is an error
// End-of-test summary per port and for the configuration block.

`include "qdma_bd_names.svh"
`default_nettype wire
module bind_c2h_src_ctrl
  import uvm_pkg::*;
#(
  parameter int PORT_ID = 0
) (
  input logic              clk,
  input logic              rst_n,
  input logic              busy,           // controller not idle
  input logic              start_ok,       // a START with a non-zero count is taken this cycle (when idle)
  input logic [10:0]       cfg_qid,
  input logic [15:0]       cfg_num_pkt,
  input logic [9:0]        cfg_pkt_beats,
  input logic              stop_req,       // STOP taken during the burst
  input logic              pkt_start,
  input logic [10:0]       cur_qid,
  input logic [15:0]       burst_seq,
  input logic [31:0]       beat_idx,
  input logic [9:0]        cur_beats,
  input logic [15:0]       left,
  input logic              c2h_tvalid,
  input logic              c2h_tready,
  input logic              c2h_tlast,
  input logic [63:0]       c2h_tdata_lo,
  input logic [11:0]       c2h_ctrl_qid,
  input logic [15:0]       c2h_ctrl_len
);
  `include "uvm_macros.svh"

  string       tag;
  int unsigned n_burst = 0, n_stopped = 0, n_pkt = 0, n_beats_tot = 0;
  int unsigned n_cnt_err = 0, n_after_stop = 0, n_qid_err = 0, n_seed_err = 0;
  int unsigned n_len_err = 0, n_beat_err = 0, n_idle_beat = 0;
  int unsigned b_num = 0, b_pkts = 0;   // current burst: packets requested, started
  bit          b_active = 1'b0;
  bit          busy_prev = 1'b0;
  logic [63:0] exp_seed [$];            // first-beat seed of packets started, in order
  int unsigned exp_beats [$];
  int unsigned exp_qid [$];
  bit          in_pkt   = 1'b0;
  int unsigned beat_cnt = 0, cur_exp = 0;

  initial tag = $sformatf("port%0d", PORT_ID);

  always @(posedge clk) begin
    if (rst_n) begin
      if (!busy && start_ok) begin
        // The burst state loads on this edge; log the request as written.
        b_active = 1'b1; b_num = cfg_num_pkt; b_pkts = 0;
        n_burst++;
        `uvm_info("C2H_SRC_BURST", $sformatf(
          "%s START qid %0d: %0d packets of %0d bytes, burst %0d",
          tag, cfg_qid, cfg_num_pkt, ((cfg_pkt_beats == 0) ? 1 : int'(cfg_pkt_beats)) * 64,
          16'(burst_seq + 1'b1)), UVM_LOW)
      end

      if (pkt_start) begin
        if (stop_req) begin
          n_after_stop++;
          `uvm_error("C2H_SRC_STOP", $sformatf("%s qid %0d packet started after a STOP was taken", tag, cur_qid))
        end
        b_pkts++; n_pkt++;
        exp_seed.push_back({cur_qid, 5'd0, burst_seq, beat_idx});
        exp_beats.push_back(cur_beats);
        exp_qid.push_back(cur_qid);
        `uvm_info("C2H_SRC_PKT", $sformatf(
          "%s qid %0d burst %0d packet %0d of %0d: %0d bytes, %0d beats, first beat %0d",
          tag, cur_qid, burst_seq, b_pkts, b_num, int'(cur_beats) * 64, cur_beats, beat_idx), UVM_LOW)
      end

      if (busy_prev && !busy && b_active) begin
        if (stop_req) n_stopped++;
        if ((b_pkts > b_num) || (!stop_req && b_pkts != b_num)) begin
          n_cnt_err++;
          `uvm_error("C2H_SRC_BURST_CNT", $sformatf(
            "%s qid %0d burst %0d sent %0d packets, %0d requested%s",
            tag, cur_qid, burst_seq, b_pkts, b_num, stop_req ? " (stopped)" : ""))
        end
        `uvm_info("C2H_SRC_BURST", $sformatf(
          "%s END qid %0d burst %0d: %0d of %0d packets sent%s",
          tag, cur_qid, burst_seq, b_pkts, b_num, stop_req ? ", STOP taken" : ""), UVM_LOW)
        b_active = 1'b0;
      end
      busy_prev = busy;

      if (c2h_tvalid && !busy) begin
        n_idle_beat++;
        `uvm_error("C2H_SRC_IDLE_BEAT", $sformatf("%s stream valid while the controller is idle", tag))
      end

      if (c2h_tvalid && c2h_tready) begin
        if (!in_pkt) begin
          if (exp_beats.size() == 0) begin
            n_beat_err++;
            `uvm_error("C2H_SRC_BEATS", $sformatf("%s data beat with no packet started", tag))
            cur_exp = 0;
          end else begin
            automatic logic [63:0] seed = exp_seed.pop_front();
            automatic int unsigned q    = exp_qid.pop_front();
            cur_exp = exp_beats.pop_front();
            if (int'(c2h_ctrl_qid) != q) begin
              n_qid_err++;
              `uvm_error("C2H_SRC_QID", $sformatf("%s packet c2h_ctrl_qid %0d, burst queue %0d", tag, c2h_ctrl_qid, q))
            end
            if (c2h_tdata_lo !== seed) begin
              n_seed_err++;
              `uvm_error("C2H_SRC_SEED", $sformatf(
                "%s qid %0d first beat 0x%016h, expected 0x%016h", tag, q, c2h_tdata_lo, seed))
            end
          end
          if (int'(c2h_ctrl_len) != cur_exp * 64) begin
            n_len_err++;
            `uvm_error("C2H_SRC_LEN", $sformatf(
              "%s first beat carries c2h_ctrl_len %0d, packet is %0d beats (%0d bytes)",
              tag, c2h_ctrl_len, cur_exp, cur_exp * 64))
          end
          beat_cnt = 0;
        end
        beat_cnt++;
        n_beats_tot++;
        in_pkt = !c2h_tlast;
        if (c2h_tlast && beat_cnt != cur_exp) begin
          n_beat_err++;
          `uvm_error("C2H_SRC_BEATS", $sformatf(
            "%s packet ended after %0d beats, expected %0d", tag, beat_cnt, cur_exp))
        end
      end
    end
  end

  final begin
    if (n_burst != 0 || n_pkt != 0)
      `uvm_info("C2H_SRC_SUMMARY", $sformatf(
        "%s bursts %0d (stopped %0d), packets %0d, beats %0d; errors: burst count %0d, packet after STOP %0d, queue %0d, data seed %0d, length field %0d, beat count %0d, beat while idle %0d",
        tag, n_burst, n_stopped, n_pkt, n_beats_tot, n_cnt_err, n_after_stop, n_qid_err, n_seed_err,
        n_len_err, n_beat_err, n_idle_beat), UVM_NONE)
  end
endmodule


module bind_c2h_src_cfg
  import uvm_pkg::*;
(
  input logic        clk,
  input logic        rst_n,
  input logic [48:0] awaddr,
  input logic        awvalid,
  input logic        awready,
  input logic [48:0] araddr,
  input logic        arvalid,
  input logic        arready,
  input logic [1:0]  bresp,
  input logic        bvalid,
  input logic        bready,
  input logic [31:0] rdata,
  input logic [1:0]  rresp,
  input logic        rvalid,
  input logic        rready,
  // descriptor-status events (C2H queues), for the posted / used count
  input logic        tm_valid,
  input logic        tm_dir,
  input logic        tm_qen,
  input logic [12:0] tm_qid,
  input logic [15:0] tm_avl
);
  `include "uvm_macros.svh"

  int unsigned n_wr = 0, n_rej = 0, n_busy_rej = 0, n_rd = 0, n_resp_err = 0, n_short = 0;
  logic [48:0] ar_last;
  bit          neg, expect_drop;
  longint      posted [int];    // descriptors posted per queue
  longint      used   [int];    // descriptors used by packets started per queue

  initial begin
    neg         = $test$plusargs("C2H_SRC_CFG_NEG");
    expect_drop = $test$plusargs("C2H_EXPECT_PFCH_DROP");
  end

  // The descriptor-status events, for the test's doorbell-to-START barrier
  // (qdma_base_test counts C2H descriptors posted per queue from them).
  qdma_periph_tm_dsc_if c2h_tm_if ();
  assign c2h_tm_if.clk            = clk;
  assign c2h_tm_if.rst_n          = rst_n;
  assign c2h_tm_if.tm_dsc_sts_vld = tm_valid;
  assign c2h_tm_if.tm_dsc_sts_dir = tm_dir;
  assign c2h_tm_if.tm_dsc_sts_qen = tm_qen;
  assign c2h_tm_if.tm_dsc_sts_qid = tm_qid;
  assign c2h_tm_if.tm_dsc_sts_avl = tm_avl;
  initial uvm_config_db#(virtual qdma_periph_tm_dsc_if)::set(null, "*", "vif_c2h_tm_dsc_sts", c2h_tm_if);

  // Port 0 at the qdma_v5.1 offsets; ports 1-3 at a 0x20-byte stride from
  // 0x120; shared registers at 0x1C0-0x1D4 (map in c2h_source_cfg.sv).
  function automatic string reg_name(int unsigned off);
    if (off == 'h00)  return "QID[0]";
    if (off == 'h04)  return "LEN[0]";
    if (off == 'h08)  return "CONTROL[0]";
    if (off == 'h20)  return "NUM_PKT[0]";
    if (off == 'h100) return "EXT_CONTROL[0]";
    if (off == 'h104) return "EXT_BURST_SEQ[0]";
    if (off == 'h108) return "EXT_PKT_INFO[0]";
    if (off == 'h10C) return "EXT_PKT_CNT[0]";
    if (off >= 'h120 && off < 'h180) begin
      automatic int unsigned rel  = off - 'h120;
      automatic int unsigned port = (rel / 'h20) + 1;
      automatic int unsigned word = rel % 'h20;
      case (word)
        'h00: return $sformatf("QID[%0d]", port);
        'h04: return $sformatf("LEN[%0d]", port);
        'h08: return $sformatf("CONTROL[%0d]", port);
        'h0C: return $sformatf("NUM_PKT[%0d]", port);
        'h10: return $sformatf("BURST_SEQ[%0d]", port);
        'h14: return $sformatf("PKT_INFO[%0d]", port);
        'h18: return $sformatf("PKT_CNT[%0d]", port);
        default: return $sformatf("0x%02h", off);
      endcase
    end
    case (off)
      'h1C0: return "ID";      'h1C4: return "VERSION"; 'h1C8: return "CAPS";
      'h1CC: return "STATUS";  'h1D0: return "BUF_BYTES"; 'h1D4: return "MAX_DSC";
      default: return $sformatf("0x%02h", off);
    endcase
  endfunction

  // Packets started per port, with the queue and the descriptors one packet uses.
  logic [3:0]        p_start;
  logic [3:0][10:0]  p_qid;
  assign p_start = {u_c2h_ctrl_3.pkt_start, u_c2h_ctrl_2.pkt_start, u_c2h_ctrl_1.pkt_start, u_c2h_ctrl_0.pkt_start};
  assign p_qid   = {u_c2h_ctrl_3.cur_qid,   u_c2h_ctrl_2.cur_qid,   u_c2h_ctrl_1.cur_qid,   u_c2h_ctrl_0.cur_qid};

  always @(posedge clk) begin
    if (rst_n) begin
      if (awvalid && awready)
        `uvm_info("C2H_SRC_CFG_AW", $sformatf("write address 0x%013h", awaddr), UVM_HIGH)
      if (arvalid && arready) begin
        ar_last = araddr;
        `uvm_info("C2H_SRC_CFG_AR", $sformatf("read address 0x%013h", araddr), UVM_HIGH)
      end

      if (u_c2h_src_cfg.wr_en) begin
        automatic int unsigned off  = int'(u_c2h_src_cfg.wr_idx) * 4;
        automatic logic [3:0]  code = u_c2h_src_cfg.wr_err;
        n_wr++;
        if (code == '0)
          `uvm_info("C2H_SRC_CFG_WR", $sformatf(
            "%s <- 0x%08h (strobes 0x%h) accepted",
            reg_name(off), u_c2h_src_cfg.s_axil_wdata, u_c2h_src_cfg.s_axil_wstrb), UVM_LOW)
        else begin
          n_rej++;
          if (code == 4'd6 && !neg) begin
            n_busy_rej++;
            `uvm_error("C2H_SRC_CFG_BUSY", $sformatf(
              "%s <- 0x%08h rejected: the port is busy with a burst",
              reg_name(off), u_c2h_src_cfg.s_axil_wdata))
          end else if (neg)
            `uvm_info("C2H_SRC_CFG_REJ", $sformatf(
              "%s <- 0x%08h (strobes 0x%h) rejected, code %0d",
              reg_name(off), u_c2h_src_cfg.s_axil_wdata, u_c2h_src_cfg.s_axil_wstrb, code), UVM_LOW)
          else
            `uvm_warning("C2H_SRC_CFG_REJ", $sformatf(
              "%s <- 0x%08h (strobes 0x%h) rejected, code %0d",
              reg_name(off), u_c2h_src_cfg.s_axil_wdata, u_c2h_src_cfg.s_axil_wstrb, code))
        end
      end

      if (rvalid && rready) begin
        n_rd++;
        `uvm_info("C2H_SRC_CFG_RD", $sformatf(
          "%s -> 0x%08h", reg_name(int'(ar_last[15:0])), rdata), UVM_MEDIUM)
      end

      if ((bvalid && bready && bresp != 2'b00) || (rvalid && rready && rresp != 2'b00)) begin
        n_resp_err++;
        `uvm_error("C2H_SRC_CFG_RESP", $sformatf(
          "non-OKAY response: write 0x%0h read 0x%0h", bvalid ? bresp : 2'b00, rvalid ? rresp : 2'b00))
      end

      // Descriptors posted per queue, from the C2H descriptor-status events.
      if (tm_valid && tm_dir && tm_qen) begin
        automatic int q = int'(tm_qid[10:0]);
        if (!posted.exists(q)) posted[q] = 0;
        posted[q] += longint'(tm_avl);
      end
      // Descriptors used by each packet started; beyond the posted count the
      // DMA drops the packet.
      for (int p = 0; p < 4; p++)
        if (p_start[p]) begin
          automatic int q = int'(p_qid[p]);
          if (!used.exists(q)) used[q] = 0;
          used[q] += longint'(u_c2h_src_cfg.pkt_dsc_r[p]);
          if (!posted.exists(q) || used[q] > posted[q]) begin
            n_short++;
            if (expect_drop)
              `uvm_info("C2H_SRC_NO_DSC", $sformatf(
                "port%0d qid %0d packet started with descriptors used %0d > posted %0d (drop expected)",
                p, q, used[q], posted.exists(q) ? posted[q] : 0), UVM_LOW)
            else
              `uvm_error("C2H_SRC_NO_DSC", $sformatf(
                "port%0d qid %0d packet started with descriptors used %0d > posted %0d: the DMA will drop it",
                p, q, used[q], posted.exists(q) ? posted[q] : 0))
          end
        end
    end
  end

  final begin
    if (n_wr != 0 || n_rd != 0)
      `uvm_info("C2H_SRC_CFG_SUMMARY", $sformatf(
        "writes %0d (rejected %0d, busy %0d), reads %0d, non-OKAY responses %0d, packets started beyond posted descriptors %0d; per port packet bytes %0d/%0d/%0d/%0d, bursts %0d/%0d/%0d/%0d, packets started %0d/%0d/%0d/%0d",
        n_wr, n_rej, n_busy_rej, n_rd, n_resp_err, n_short,
        u_c2h_src_cfg.pkt_bytes_r[0], u_c2h_src_cfg.pkt_bytes_r[1],
        u_c2h_src_cfg.pkt_bytes_r[2], u_c2h_src_cfg.pkt_bytes_r[3],
        u_c2h_src_cfg.sts_burst_seq[0], u_c2h_src_cfg.sts_burst_seq[1],
        u_c2h_src_cfg.sts_burst_seq[2], u_c2h_src_cfg.sts_burst_seq[3],
        u_c2h_src_cfg.pkt_cnt_r[0], u_c2h_src_cfg.pkt_cnt_r[1],
        u_c2h_src_cfg.pkt_cnt_r[2], u_c2h_src_cfg.pkt_cnt_r[3]), UVM_NONE)
  end
endmodule

`default_nettype none
bind c2h_source_ctrl bind_c2h_src_ctrl #(
  .PORT_ID       (PORT_ID)
) bind_c2h_src_ctrl_inst (
  .clk           (clk),
  .rst_n         (rst_n),
  .busy          (sts_busy),
  .start_ok      (start_ok),
  .cfg_qid       (cfg_qid),
  .cfg_num_pkt   (cfg_num_pkt),
  .cfg_pkt_beats (cfg_pkt_beats),
  .stop_req      (stop_req),
  .pkt_start     (pkt_start),
  .cur_qid       (cur_qid),
  .burst_seq     (burst_seq_r),
  .beat_idx      (beat_idx),
  .cur_beats     (cur_beats_r),
  .left          (left_r),
  .c2h_tvalid    (c2h_tvalid),
  .c2h_tready    (c2h_tready),
  .c2h_tlast     (c2h_tlast),
  .c2h_tdata_lo  (c2h_tdata[63:0]),
  .c2h_ctrl_qid  (c2h_ctrl_qid),
  .c2h_ctrl_len  (c2h_ctrl_len)
);

bind `CPM6_BD_TOP_WRAPPER bind_c2h_src_cfg bind_c2h_src_cfg_inst (
  .clk      (axi_clk),
  .rst_n    (axi_rst_n),
  .awaddr   (c2h_cfg_axil_awaddr),
  .awvalid  (c2h_cfg_axil_awvalid),
  .awready  (c2h_cfg_axil_awready),
  .araddr   (c2h_cfg_axil_araddr),
  .arvalid  (c2h_cfg_axil_arvalid),
  .arready  (c2h_cfg_axil_arready),
  .bresp    (c2h_cfg_axil_bresp),
  .bvalid   (c2h_cfg_axil_bvalid),
  .bready   (c2h_cfg_axil_bready),
  .rdata    (c2h_cfg_axil_rdata),
  .rresp    (c2h_cfg_axil_rresp),
  .rvalid   (c2h_cfg_axil_rvalid),
  .rready   (c2h_cfg_axil_rready),
  .tm_valid (tm_dsc_sts_valid),
  .tm_dir   (tm_dsc_sts_dir),
  .tm_qen   (tm_dsc_sts_qen),
  .tm_qid   (tm_dsc_sts_qid),
  .tm_avl   (tm_dsc_sts_avl)
);

`default_nettype wire
