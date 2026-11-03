// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
// =============================================================================
// c2h_source_cfg.sv
//
// Host control of the C2H stream example design. Per C2H port: the packet
// length, the queue, the number of packets, and START/STOP. Each
// c2h_source_ctrl sends a burst of NUM_PKT packets to QID when START is
// written, independently of the descriptors the host has posted.
//
// Sequence per burst: post descriptors on the queue (PIDX), write LEN, QID and
// NUM_PKT, then write START; BUSY (EXT_CONTROL on port 0, CONTROL on ports
// 1-3) reads 0 when the burst is done. QID, NUM_PKT, LEN and START are
// rejected while the port is busy.
//
// Register map (32-bit, byte offsets; full-word writes only). Port 0's QID,
// LEN, CONTROL (bit[1] START) and NUM_PKT use the qdma_v5.1 example design's
// offsets and bit positions (PG302), so host software written for it drives
// port 0 unchanged. Ports 1-3 and the shared registers use this block's own
// layout.
//
//   -- Port 0 (qdma_v5.1-compatible) --
//   0x00 QID          RW  [10:0] queue of the next burst (absolute queue
//                         id), reset 1; [31:11] reserved (reason 1)
//   0x04 LEN          RW  [15:0] packet length in bytes, a non-zero
//                         multiple of 64 whose descriptor count is <= MAX_DSC
//   0x08 CONTROL      write: [1] START a burst (qdma's bit position);
//                         [0],[2],[3],[5] accepted but not implemented by
//                         this generator (qdma defines loopback/immediate
//                         data/disable-completion/marker here -- reserved
//                         no-ops); no reserved-bit rejection, matching
//                         qdma's own unconditional accept
//                     read: literal echo of the last accepted write (matches
//                         qdma's own read-back; BUSY/STOPPED/packets-left
//                         status is NOT here; see EXT_CONTROL below)
//   0x20 NUM_PKT      RW  [10:0] packets per burst, matches qdma's field
//                         width exactly; [15:11] this generator's own
//                         extension (qdma software never sets them), reset
//                         1; 0 makes START a no-op; [31:16] reserved
//                         (reason 1)
//
//   -- Port 0 extensions (this generator only; qdma has no equivalent) --
//   0x100 EXT_CONTROL  write: [0] STOP the burst after the packet in flight
//                         (always accepted); [31:1] reserved (reason 1)
//                     read: [0] BUSY (burst in progress; 0 once the last
//                         packet has entered the DMA), [1] STOPPED (a STOP
//                         was taken during the last burst), [31:16] packets
//                         of the burst not yet started
//   0x104 EXT_BURST_SEQ RO [15:0] bursts started on port 0 (part of the data
//                         pattern)
//   0x108 EXT_PKT_INFO  RO [9:0] length in beats, [19:16] descriptors
//   0x10C EXT_PKT_CNT   RO packets started on port 0 (including packets the
//                         DMA drops); any write clears it
//
//   -- Ports 1-3 (this generator only; no qdma counterpart) --
//   Base(p) = 0x120 + (p-1)*0x20, for p = 1, 2, 3:
//   Base+0x00 QID[p]      RW  same fields as port 0's QID
//   Base+0x04 LEN[p]      RW  same fields as port 0's LEN
//   Base+0x08 CONTROL[p]  write: [0] START, [1] STOP (STOP wins when both
//                         are set; STOP is always accepted); [31:2]
//                         reserved (reason 1)
//                     read: [0] BUSY, [1] STOPPED, [31:16] packets left --
//                         same fields as port 0's EXT_CONTROL
//   Base+0x0C NUM_PKT[p]    RW  same fields as port 0's NUM_PKT (full 16-bit
//                         width, no qdma-width distinction since no qdma
//                         register exists at this offset)
//   Base+0x10 BURST_SEQ[p]  RO  same as port 0's EXT_BURST_SEQ
//   Base+0x14 PKT_INFO[p]   RO  same as port 0's EXT_PKT_INFO
//   Base+0x18 PKT_CNT[p]    RO  same as port 0's EXT_PKT_CNT
//
//   -- Shared / discovery --
//   0x1C0 ID          RO   0x4332_4843
//   0x1C4 VERSION     RO   0x0003_0000
//   0x1C8 CAPS        RO   [3:0] ports, [7:4] length granularity (log2 bytes),
//                         [11:8] largest descriptor count the DMA accepts per
//                         packet, [15:12] largest MAX_DSC value,
//                         [31:16] buffer bytes per descriptor
//   0x1CC STATUS      W1C  [0] a write was rejected (sticky; first error kept)
//                         [7:4] reason: 1 zero length or reserved bits set,
//                         2 length not a multiple of 64, 3 too many
//                         descriptors for MAX_DSC, 4 MAX_DSC out of range or
//                         below a port's descriptor count, 5 partial write,
//                         6 port busy (QID, NUM_PKT, PKT_BYTES or START
//                         while a burst is in progress)
//                         [15:8] word offset, [31:16] written data[15:0]
//                         Writing 1 to bit 0 clears the whole register.
//   0x1D0 BUF_BYTES   RO   buffer bytes per descriptor (P_BUF_BYTES)
//   0x1D4 MAX_DSC     RW   [3:0] largest descriptor count per packet, 1..15.
//                         The DMA drops packets that need more than 7;
//                         larger values are for testing that path only.
//
// A rejected write leaves the register unchanged and still returns OKAY.
// Writes to other offsets and to read-only registers are ignored; reads of
// other offsets return 0.
// =============================================================================

module c2h_source_cfg #(
   parameter int          P_NUM_PORTS     = 4,
   parameter int          P_ADDR_WIDTH    = 16,
   parameter logic [15:0] P_RST_PKT_BYTES = 16'd512,
   parameter logic [15:0] P_BUF_BYTES     = 16'd4096,
   parameter logic [3:0]  P_RST_MAX_DSC   = 4'd7
) (
   input  logic                        aclk,
   input  logic                        aresetn,

   // -------------------------------------------------------------------------
   // AXI-Lite Slave
   // -------------------------------------------------------------------------
   input  logic [P_ADDR_WIDTH-1:0]     s_axil_awaddr,
   input  logic [2:0]                  s_axil_awprot,
   input  logic                        s_axil_awvalid,
   output logic                        s_axil_awready,

   input  logic [31:0]                 s_axil_wdata,
   input  logic [3:0]                  s_axil_wstrb,
   input  logic                        s_axil_wvalid,
   output logic                        s_axil_wready,

   output logic [1:0]                  s_axil_bresp,
   output logic                        s_axil_bvalid,
   input  logic                        s_axil_bready,

   input  logic [P_ADDR_WIDTH-1:0]     s_axil_araddr,
   input  logic [2:0]                  s_axil_arprot,
   input  logic                        s_axil_arvalid,
   output logic                        s_axil_arready,

   output logic [31:0]                 s_axil_rdata,
   output logic [1:0]                  s_axil_rresp,
   output logic                        s_axil_rvalid,
   input  logic                        s_axil_rready,

   // -------------------------------------------------------------------------
   // Per-port burst control, and the status from each port's controller
   // -------------------------------------------------------------------------
   output logic [P_NUM_PORTS-1:0][9:0]  cfg_pkt_beats,
   output logic [P_NUM_PORTS-1:0][3:0]  cfg_pkt_dsc,
   output logic [P_NUM_PORTS-1:0][10:0] cfg_qid,
   output logic [P_NUM_PORTS-1:0][15:0] cfg_num_pkt,
   output logic [P_NUM_PORTS-1:0]       cfg_start,
   output logic [P_NUM_PORTS-1:0]       cfg_stop,
   input  logic [P_NUM_PORTS-1:0]       sts_pkt_start,
   input  logic [P_NUM_PORTS-1:0]       sts_busy,
   input  logic [P_NUM_PORTS-1:0][15:0] sts_left,
   input  logic [P_NUM_PORTS-1:0][15:0] sts_burst_seq
);

   // ==========================================================================
   // Register offsets (word index = byte offset / 4). Port 0 at the qdma_v5.1
   // offsets; ports 1-3 at a 0x20-byte stride from 0x120; shared registers at
   // 0x1C0-0x1D4.
   // ==========================================================================
   localparam logic [31:0] ID_VALUE      = 32'h4332_4843;
   localparam logic [31:0] VERSION_VALUE = 32'h0003_0000;

   // Port 0: qdma_v5.1-aligned
   localparam int IDX_QID0        = 'h000 >> 2;
   localparam int IDX_LEN0        = 'h004 >> 2;
   localparam int IDX_CONTROL0    = 'h008 >> 2;
   localparam int IDX_NUM_PKT0    = 'h020 >> 2;

   // Port 0: this generator's own extensions (no qdma counterpart)
   localparam int IDX_EXT_CONTROL0   = 'h100 >> 2;
   localparam int IDX_EXT_BURST_SEQ0 = 'h104 >> 2;
   localparam int IDX_EXT_PKT_INFO0  = 'h108 >> 2;
   localparam int IDX_EXT_PKT_CNT0   = 'h10C >> 2;

   // Ports 1..P_NUM_PORTS-1: 8-word (0x20-byte) stride per port, no qdma
   // counterpart. Within a port's block: +0 QID, +1 LEN, +2 CONTROL,
   // +3 NUM_PKT, +4 BURST_SEQ, +5 PKT_INFO, +6 PKT_CNT, +7 reserved.
   localparam int IDX_P13_BASE    = 'h120 >> 2;
   localparam int IDX_P13_STRIDE  = 8;
   localparam int IDX_P13_SPAN    = (P_NUM_PORTS - 1) * IDX_P13_STRIDE;

   // Shared / discovery
   localparam int IDX_ID         = 'h1C0 >> 2;
   localparam int IDX_VERSION    = 'h1C4 >> 2;
   localparam int IDX_CAPS       = 'h1C8 >> 2;
   localparam int IDX_STATUS     = 'h1CC >> 2;
   localparam int IDX_BUF_BYTES  = 'h1D0 >> 2;
   localparam int IDX_MAX_DSC    = 'h1D4 >> 2;

   // Length granularity is one 64-byte beat; the DMA accepts up to 7
   // descriptors per packet.
   localparam logic [3:0]  GRAN_LOG2     = 4'd6;
   localparam logic [3:0]  DMA_MAX_DSC   = 4'd7;
   localparam logic [3:0]  CFG_MAX_DSC   = 4'd15;
   localparam int          BUF_LOG2      = $clog2(int'(P_BUF_BYTES));

   localparam logic [3:0]  ERR_ZERO      = 4'd1;
   localparam logic [3:0]  ERR_ALIGN     = 4'd2;
   localparam logic [3:0]  ERR_DSC       = 4'd3;
   localparam logic [3:0]  ERR_MAX_DSC   = 4'd4;
   localparam logic [3:0]  ERR_STRB      = 4'd5;
   localparam logic [3:0]  ERR_BUSY      = 4'd6;

   // Descriptors a packet of len bytes uses: ceil(len / P_BUF_BYTES), with
   // P_BUF_BYTES a power of two.
   function automatic logic [4:0] dsc_of(input logic [15:0] len);
      logic [16:0] sum;
      sum    = 17'(len) + 17'(P_BUF_BYTES) - 17'd1;
      dsc_of = 5'(sum >> BUF_LOG2);
   endfunction

   // ==========================================================================
   // Registers
   // ==========================================================================
   logic [15:0]                    pkt_bytes_r [P_NUM_PORTS];
   logic [3:0]                     pkt_dsc_r   [P_NUM_PORTS];
   logic [31:0]                    pkt_cnt_r   [P_NUM_PORTS];
   logic [10:0]                    qid_r       [P_NUM_PORTS];
   logic [15:0]                    num_pkt_r   [P_NUM_PORTS];
   logic [P_NUM_PORTS-1:0]         start_r;      // one-cycle START pulse per port
   logic [P_NUM_PORTS-1:0]         stop_r;       // one-cycle STOP pulse per port
   logic [P_NUM_PORTS-1:0]         stopped_r;    // a STOP was taken during the last burst
   logic [31:0]                    ctl0_echo_r;  // port 0's CONTROL read-back: literal
                                                  // echo of the last accepted write, matching
                                                  // qdma_v5.1's own CONTROL read behavior
   logic [3:0]                     max_dsc_r;
   logic                           err_r;
   logic [3:0]                     err_code_r;
   logic [7:0]                     err_off_r;
   logic [15:0]                    err_wdata_r;

   // AXI-Lite handshake state
   logic                           aw_captured_r;
   logic [P_ADDR_WIDTH-1:0]        aw_addr_r;
   logic                           b_pending_r;
   logic                           ar_captured_r;
   logic [P_ADDR_WIDTH-1:0]        ar_addr_r;
   logic                           r_pending_r;
   logic [31:0]                    rdata_r;

   logic                           wr_en;
   logic [P_ADDR_WIDTH-3:0]        wr_idx;
   logic [P_ADDR_WIDTH-3:0]        rd_idx;

   assign wr_idx = aw_addr_r[P_ADDR_WIDTH-1:2];
   assign rd_idx = ar_addr_r[P_ADDR_WIDTH-1:2];

   for (genvar p = 0; p < P_NUM_PORTS; p++) begin : g_out
      assign cfg_pkt_beats[p] = pkt_bytes_r[p][15:6];
      assign cfg_pkt_dsc[p]   = pkt_dsc_r[p];
      assign cfg_qid[p]       = qid_r[p];
      assign cfg_num_pkt[p]   = num_pkt_r[p];
   end : g_out
   assign cfg_start = start_r;
   assign cfg_stop  = stop_r;

   // A port is busy from the cycle its START is taken: the controller's BUSY
   // follows one cycle after the START pulse.
   logic [P_NUM_PORTS-1:0]         port_busy;
   assign port_busy = sts_busy | start_r;

   // ==========================================================================
   // Write decode: accept or reject, and the reason for a reject
   // ==========================================================================
   logic                           wr_pkt;        // a LEN/PKT_BYTES register (port 0 or 1-3)
   logic                           wr_cnt;        // a PKT_CNT register (port 0 or 1-3)
   logic                           wr_qid;        // a QID register (port 0 or 1-3)
   logic                           wr_num;        // a NUM_PKT register (port 0 or 1-3)
   logic                           wr_ctl0;       // port 0's CONTROL (qdma-aligned, START only)
   logic                           wr_extctl0;    // port 0's EXT_CONTROL (STOP + status)
   logic                           wr_ctl_p13;    // a ports-1-3 CONTROL (combined START/STOP)
   int unsigned                    wr_port;
   logic [4:0]                     wr_dsc;        // descriptors for the written length
   logic [3:0]                     wr_err;        // 0: accepted
   logic [3:0]                     dsc_max_cur;   // largest descriptor count in use
   logic                           wr_start;      // ports-1-3 CONTROL write requests START (and not STOP)

   always_comb begin : wr_check
      automatic int p13_rel  = int'(wr_idx) - IDX_P13_BASE;          // word offset into the ports-1-3 region
      automatic bit p13_in   = (p13_rel >= 0) && (p13_rel < IDX_P13_SPAN);
      automatic int p13_port = p13_in ? (p13_rel / IDX_P13_STRIDE) + 1 : 0;
      automatic int p13_word = p13_in ? (p13_rel % IDX_P13_STRIDE)     : -1;

      wr_qid  = (int'(wr_idx) == IDX_QID0)     || (p13_in && (p13_word == 0));
      wr_pkt  = (int'(wr_idx) == IDX_LEN0)     || (p13_in && (p13_word == 1));
      wr_num  = (int'(wr_idx) == IDX_NUM_PKT0) || (p13_in && (p13_word == 3));
      wr_cnt  = (int'(wr_idx) == IDX_EXT_PKT_CNT0) || (p13_in && (p13_word == 6));
      wr_ctl0    = (int'(wr_idx) == IDX_CONTROL0);
      wr_extctl0 = (int'(wr_idx) == IDX_EXT_CONTROL0);
      wr_ctl_p13 = p13_in && (p13_word == 2);

      wr_port = p13_in ? p13_port : 0;   // port 0's own addresses always resolve to port 0

      wr_dsc   = dsc_of(s_axil_wdata[15:0]);
      wr_start = s_axil_wdata[0] && !s_axil_wdata[1];
      dsc_max_cur = '0;
      for (int p = 0; p < P_NUM_PORTS; p++)
         if (pkt_dsc_r[p] > dsc_max_cur) dsc_max_cur = pkt_dsc_r[p];
      wr_err = '0;
      if (wr_pkt) begin
         if (s_axil_wstrb != 4'hF)                                        wr_err = ERR_STRB;
         else if ((s_axil_wdata[31:16] != '0) || (s_axil_wdata[15:0] == '0)) wr_err = ERR_ZERO;
         else if (s_axil_wdata[5:0] != '0)                                wr_err = ERR_ALIGN;
         else if (wr_dsc > 5'(max_dsc_r))                                 wr_err = ERR_DSC;
         else if (port_busy[wr_port])                                     wr_err = ERR_BUSY;
      end else if (wr_qid) begin
         if (s_axil_wstrb != 4'hF)                                        wr_err = ERR_STRB;
         else if (s_axil_wdata[31:11] != '0)                              wr_err = ERR_ZERO;
         else if (port_busy[wr_port])                                     wr_err = ERR_BUSY;
      end else if (wr_num) begin
         if (s_axil_wstrb != 4'hF)                                        wr_err = ERR_STRB;
         else if (s_axil_wdata[31:16] != '0)                              wr_err = ERR_ZERO;
         else if (port_busy[wr_port])                                     wr_err = ERR_BUSY;
      end else if (wr_ctl0) begin
         // qdma_v5.1 accepts any value here (no reserved-bit rejection):
         // bits [0],[2],[3],[5] are qdma-defined but not implemented by this
         // generator; only a START request while busy is rejected.
         if (s_axil_wstrb != 4'hF)                                        wr_err = ERR_STRB;
         else if (s_axil_wdata[1] && port_busy[0])                        wr_err = ERR_BUSY;
      end else if (wr_extctl0) begin
         if (s_axil_wstrb != 4'hF)                                        wr_err = ERR_STRB;
         else if (s_axil_wdata[31:1] != '0)                               wr_err = ERR_ZERO;
         // STOP (bit 0) is always accepted, same as ports 1-3's CONTROL.
      end else if (wr_ctl_p13) begin
         if (s_axil_wstrb != 4'hF)                                        wr_err = ERR_STRB;
         else if (s_axil_wdata[31:2] != '0)                               wr_err = ERR_ZERO;
         else if (wr_start && port_busy[wr_port])                         wr_err = ERR_BUSY;
      end else if (int'(wr_idx) == IDX_MAX_DSC) begin
         if (s_axil_wstrb != 4'hF)                                        wr_err = ERR_STRB;
         else if ((s_axil_wdata[31:4] != '0) || (s_axil_wdata[3:0] == '0)
                  || (s_axil_wdata[3:0] < dsc_max_cur))                   wr_err = ERR_MAX_DSC;
      end else if (wr_cnt || (int'(wr_idx) == IDX_STATUS)) begin
         if (s_axil_wstrb != 4'hF)                                        wr_err = ERR_STRB;
      end
   end : wr_check

   always_ff @(posedge aclk) begin : p_regs
      if (!aresetn) begin
         for (int p = 0; p < P_NUM_PORTS; p++) begin
            pkt_bytes_r[p] <= P_RST_PKT_BYTES;
            pkt_dsc_r[p]   <= 4'(dsc_of(P_RST_PKT_BYTES));
            pkt_cnt_r[p]   <= '0;
            qid_r[p]       <= 11'd1;
            num_pkt_r[p]   <= 16'd1;
         end
         start_r     <= '0;
         stop_r      <= '0;
         stopped_r   <= '0;
         ctl0_echo_r <= '0;
         max_dsc_r   <= P_RST_MAX_DSC;
         err_r       <= 1'b0;
         err_code_r  <= '0;
         err_off_r   <= '0;
         err_wdata_r <= '0;
      end else begin
         start_r <= '0;   // default: one-cycle pulses
         stop_r  <= '0;
         for (int p = 0; p < P_NUM_PORTS; p++)
            if (sts_pkt_start[p]) pkt_cnt_r[p] <= pkt_cnt_r[p] + 1'b1;

         // Port 0: CONTROL (qdma-aligned), bit[1]=START only; the written
         // value is stored verbatim for read-back (qdma's own echo-style
         // read), bits [0]/[2]/[3]/[5] have no effect on this generator.
         if (wr_en && wr_ctl0 && (wr_err == '0)) begin
            ctl0_echo_r <= s_axil_wdata;
            if (s_axil_wdata[1]) begin
               start_r[0]   <= 1'b1;
               stopped_r[0] <= 1'b0;
            end
         end

         // Port 0: EXT_CONTROL, STOP only (status read lives here instead
         // of at CONTROL, since qdma's CONTROL read is a bit-echo).
         if (wr_en && wr_extctl0 && (wr_err == '0)) begin
            stop_r[0] <= 1'b1;
            if (sts_busy[0]) stopped_r[0] <= 1'b1;
         end

         // Ports 1-3: combined START/STOP CONTROL.
         if (wr_en && wr_ctl_p13 && (wr_err == '0)) begin
            if (s_axil_wdata[1]) begin
               stop_r[wr_port] <= 1'b1;
               if (sts_busy[wr_port]) stopped_r[wr_port] <= 1'b1;
            end else if (s_axil_wdata[0]) begin
               start_r[wr_port]   <= 1'b1;
               stopped_r[wr_port] <= 1'b0;
            end
         end

         if (wr_en) begin
            if (wr_err != '0) begin
               if (!err_r) begin
                  err_r       <= 1'b1;
                  err_code_r  <= wr_err;
                  err_off_r   <= 8'(wr_idx);
                  err_wdata_r <= s_axil_wdata[15:0];
               end
            end else if (wr_pkt) begin
               // Length and descriptor count change together.
               pkt_bytes_r[wr_port] <= s_axil_wdata[15:0];
               pkt_dsc_r[wr_port]   <= wr_dsc[3:0];
            end else if (wr_cnt) begin
               pkt_cnt_r[wr_port]   <= '0;
            end else if (wr_qid) begin
               qid_r[wr_port]       <= s_axil_wdata[10:0];
            end else if (wr_num) begin
               num_pkt_r[wr_port]   <= s_axil_wdata[15:0];
            end else if (int'(wr_idx) == IDX_MAX_DSC) begin
               max_dsc_r <= s_axil_wdata[3:0];
            end else if ((int'(wr_idx) == IDX_STATUS) && s_axil_wdata[0]) begin
               err_r       <= 1'b0;
               err_code_r  <= '0;
               err_off_r   <= '0;
               err_wdata_r <= '0;
            end
         end
      end
   end : p_regs

   // ==========================================================================
   // AXI-Lite responses: always OKAY
   // ==========================================================================
   assign s_axil_bresp = 2'b00;
   assign s_axil_rresp = 2'b00;

   // ==========================================================================
   // AXI-Lite write handshake
   // ==========================================================================
   assign s_axil_awready = !aw_captured_r & !b_pending_r;
   assign s_axil_wready  = aw_captured_r & s_axil_wvalid & !b_pending_r;
   assign s_axil_bvalid  = b_pending_r;
   assign wr_en          = aw_captured_r & s_axil_wvalid & !b_pending_r;

   always_ff @(posedge aclk) begin : p_axil_wr
      if (!aresetn) begin
         aw_captured_r <= 1'b0;
         b_pending_r   <= 1'b0;
      end else begin
         if (s_axil_awvalid & s_axil_awready) begin
            aw_captured_r <= 1'b1;
            aw_addr_r     <= s_axil_awaddr;
         end else if (wr_en) begin
            aw_captured_r <= 1'b0;
         end

         if (wr_en) begin
            b_pending_r <= 1'b1;
         end else if (b_pending_r & s_axil_bready) begin
            b_pending_r <= 1'b0;
         end
      end
   end : p_axil_wr

   // ==========================================================================
   // AXI-Lite read handshake and read mux
   // ==========================================================================
   assign s_axil_arready = !ar_captured_r & !r_pending_r;
   assign s_axil_rvalid  = r_pending_r;
   assign s_axil_rdata   = rdata_r;

   logic [31:0] rd_word;
   always_comb begin : rd_mux
      automatic int rp13_rel  = int'(rd_idx) - IDX_P13_BASE;
      automatic bit rp13_in   = (rp13_rel >= 0) && (rp13_rel < IDX_P13_SPAN);
      automatic int rp13_port = rp13_in ? (rp13_rel / IDX_P13_STRIDE) + 1 : 0;
      automatic int rp13_word = rp13_in ? (rp13_rel % IDX_P13_STRIDE)     : -1;

      rd_word = '0;
      // Port 0: qdma_v5.1-aligned
      if (int'(rd_idx) == IDX_QID0)
         rd_word = {21'd0, qid_r[0]};
      else if (int'(rd_idx) == IDX_LEN0)
         rd_word = {16'd0, pkt_bytes_r[0]};
      else if (int'(rd_idx) == IDX_CONTROL0)
         rd_word = ctl0_echo_r;                       // literal echo, matches qdma's own read
      else if (int'(rd_idx) == IDX_NUM_PKT0)
         rd_word = {16'd0, num_pkt_r[0]};
      // Port 0: this generator's extensions
      else if (int'(rd_idx) == IDX_EXT_CONTROL0)
         rd_word = {sts_left[0], 14'd0, stopped_r[0], port_busy[0]};
      else if (int'(rd_idx) == IDX_EXT_BURST_SEQ0)
         rd_word = {16'd0, sts_burst_seq[0]};
      else if (int'(rd_idx) == IDX_EXT_PKT_INFO0)
         rd_word = {12'd0, pkt_dsc_r[0], 6'd0, pkt_bytes_r[0][15:6]};
      else if (int'(rd_idx) == IDX_EXT_PKT_CNT0)
         rd_word = pkt_cnt_r[0];
      // Shared / discovery
      else if (int'(rd_idx) == IDX_ID)
         rd_word = ID_VALUE;
      else if (int'(rd_idx) == IDX_VERSION)
         rd_word = VERSION_VALUE;
      else if (int'(rd_idx) == IDX_CAPS)
         rd_word = {P_BUF_BYTES, CFG_MAX_DSC, DMA_MAX_DSC, GRAN_LOG2, 4'(P_NUM_PORTS)};
      else if (int'(rd_idx) == IDX_STATUS)
         rd_word = {err_wdata_r, err_off_r, err_code_r, 3'd0, err_r};
      else if (int'(rd_idx) == IDX_BUF_BYTES)
         rd_word = {16'd0, P_BUF_BYTES};
      else if (int'(rd_idx) == IDX_MAX_DSC)
         rd_word = {28'd0, max_dsc_r};
      // Ports 1..P_NUM_PORTS-1: combined CONTROL
      else if (rp13_in) begin
         unique case (rp13_word)
            0: rd_word = {21'd0, qid_r[rp13_port]};
            1: rd_word = {16'd0, pkt_bytes_r[rp13_port]};
            2: rd_word = {sts_left[rp13_port], 14'd0, stopped_r[rp13_port], port_busy[rp13_port]};
            3: rd_word = {16'd0, num_pkt_r[rp13_port]};
            4: rd_word = {16'd0, sts_burst_seq[rp13_port]};
            5: rd_word = {12'd0, pkt_dsc_r[rp13_port], 6'd0, pkt_bytes_r[rp13_port][15:6]};
            6: rd_word = pkt_cnt_r[rp13_port];
            default: rd_word = '0;
         endcase
      end
   end : rd_mux

   always_ff @(posedge aclk) begin : p_axil_rd
      if (!aresetn) begin
         ar_captured_r <= 1'b0;
         r_pending_r   <= 1'b0;
      end else begin
         if (s_axil_arvalid & s_axil_arready) begin
            ar_captured_r <= 1'b1;
            ar_addr_r     <= s_axil_araddr;
         end

         if (ar_captured_r & !r_pending_r) begin
            r_pending_r   <= 1'b1;
            ar_captured_r <= 1'b0;
            rdata_r       <= rd_word;
         end else if (r_pending_r & s_axil_rready) begin
            r_pending_r <= 1'b0;
         end
      end
   end : p_axil_rd

endmodule : c2h_source_cfg
