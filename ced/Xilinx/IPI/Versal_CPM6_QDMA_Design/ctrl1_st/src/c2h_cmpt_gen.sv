//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// =============================================================================
// c2h_cmpt_gen.sv
//
// C2H Completion (CMPT) Generator — drives the QDMA c2h_cmpt_* ports.
//
// One instance per DMA port.  Triggered by cmpt_trigger from c2h_source_ctrl,
// one pulse per C2H packet, in packet order.  The QDMA holds each completion
// and writes it only after its packet's last data beat has been sent
// (ctrl_has_cmpt=1 on every packet).
//
// Packet id: every packet on the port triggers one completion, so the n-th
// trigger (counting from 1) belongs to the n-th packet on the port.  The
// entry carries that count as wait_pld_pkt_id, the value the QDMA's per-port
// C2H packet count reaches when the packet's last beat has been sent.
//
// Back-pressure: cmpt_trigger_rdy is low while the pending FIFO is full, and
// the source starts no packet then, so no completion is dropped.
//
// CMPT entry (8 bytes, size=00), in the driver's standard C2H completion format:
//   tdata[0]     = 0    format: standard
//   tdata[1]     = 0    colour; the DMA writes the ring colour here
//   tdata[2]     = 0    error
//   tdata[3]     = 1    desc_used: the packet used descriptors
//   tdata[19:4]  = len  packet length in bytes
//   tdata[30:20] = QID  (user field, for software identification)
//   tdata[63:31] = 0
//   tdata[511:64]= 0    (unused — size=8B sends only lower 8 bytes)
//
// ctrl_col_idx = 3'd0: the DMA inserts the colour at bit[1] of the entry.
// ctrl_cmpt_type = 2'b11 (HAS_PLD): completion associated with C2H data packet.
// =============================================================================

`timescale 1ps/1ps

module c2h_cmpt_gen #(
   parameter int DATA_WIDTH  = 512,
   parameter int FIFO_DEPTH  = 4,     // pending CMPT FIFO depth (power of 2)
   parameter int FIFO_AW     = 2      // $clog2(FIFO_DEPTH)
) (
   input  logic        clk,
   input  logic        rst_n,

   // ---- Trigger from c2h_source_ctrl (one pulse per packet) ----
   input  logic        cmpt_trigger,
   input  logic [10:0] cmpt_trigger_qid,
   input  logic [2:0]  cmpt_trigger_port_id,
   input  logic [15:0] cmpt_trigger_len,      // packet length in bytes
   output logic        cmpt_trigger_rdy,      // a trigger can be taken

   // ---- CMPT AXI-Stream output → QDMA c2h_cmpt_* ports ----
   output logic [DATA_WIDTH-1:0] c2h_cmpt_tdata,
   output logic [1:0]            c2h_cmpt_size,
   output logic [15:0]           c2h_cmpt_dpar,
   output logic                  c2h_cmpt_tvalid,
   input  logic                  c2h_cmpt_tready,
   output logic [10:0]           c2h_cmpt_ctrl_qid,
   output logic                  c2h_cmpt_ctrl_user_trig,
   output logic [1:0]            c2h_cmpt_ctrl_cmpt_type,
   output logic [15:0]           c2h_cmpt_ctrl_wait_pld_pkt_id,
   output logic [2:0]            c2h_cmpt_ctrl_port_id,
   output logic                  c2h_cmpt_ctrl_no_wrb_marker,
   output logic [2:0]            c2h_cmpt_ctrl_col_idx
);

   // =========================================================================
   // Pending CMPT FIFO — decouples trigger from handshake
   // =========================================================================
   typedef struct packed {
      logic [10:0] qid;
      logic [2:0]  port_id;
      logic [15:0] pkt_id;
      logic [15:0] len;
   } cmpt_pend_t;

   cmpt_pend_t fifo_mem [0:FIFO_DEPTH-1];
   logic [FIFO_AW:0] wr_ptr, rd_ptr;
   logic [15:0]      pkt_cnt;   // packets triggered on this port so far

   wire fifo_full  = (wr_ptr[FIFO_AW] != rd_ptr[FIFO_AW]) &&
                     (wr_ptr[FIFO_AW-1:0] == rd_ptr[FIFO_AW-1:0]);
   wire fifo_empty = (wr_ptr == rd_ptr);

   assign cmpt_trigger_rdy = !fifo_full;

   // Push on trigger; the source triggers only while cmpt_trigger_rdy is high
   always_ff @(posedge clk) begin
      if (!rst_n) begin
         wr_ptr  <= '0;
         pkt_cnt <= '0;
      end else if (cmpt_trigger && !fifo_full) begin
         fifo_mem[wr_ptr[FIFO_AW-1:0]] <= '{qid: cmpt_trigger_qid,
                                             port_id: cmpt_trigger_port_id,
                                             pkt_id: pkt_cnt + 1'b1,
                                             len: cmpt_trigger_len};
         wr_ptr  <= wr_ptr + 1'b1;
         pkt_cnt <= pkt_cnt + 1'b1;
      end
   end

   // =========================================================================
   // CMPT output state machine — drive tvalid until tready
   // =========================================================================
   typedef enum logic { SM_IDLE = 1'b0, SM_SEND = 1'b1 } sm_t;
   sm_t state;

   logic [10:0] cur_qid;
   logic [2:0]  cur_port_id;
   logic [15:0] cur_pkt_id;
   logic [15:0] cur_len;

   always_ff @(posedge clk) begin
      if (!rst_n) begin
         state    <= SM_IDLE;
         rd_ptr   <= '0;
         cur_qid     <= '0;
         cur_port_id <= '0;
         cur_pkt_id  <= '0;
      end else begin
         case (state)
            SM_IDLE : begin
               if (!fifo_empty) begin
                  cur_qid     <= fifo_mem[rd_ptr[FIFO_AW-1:0]].qid;
                  cur_port_id <= fifo_mem[rd_ptr[FIFO_AW-1:0]].port_id;
                  cur_pkt_id  <= fifo_mem[rd_ptr[FIFO_AW-1:0]].pkt_id;
                  cur_len     <= fifo_mem[rd_ptr[FIFO_AW-1:0]].len;
                  rd_ptr      <= rd_ptr + 1'b1;
                  state       <= SM_SEND;
               end
            end
            SM_SEND : begin
               if (c2h_cmpt_tready) begin
                  state <= SM_IDLE;
               end
            end
         endcase
      end
   end

   // =========================================================================
   // CMPT Descriptor Construction (8 bytes, size=00)
   // =========================================================================
   // 8-byte entry, driver standard format (see header):
   //   bit[0]     = 0    format (standard)
   //   bit[1]     = 0    colour, inserted by the DMA (ctrl_col_idx=0 -> bit[1])
   //   bit[2]     = 0    error
   //   bit[3]     = 1    desc_used
   //   bit[19:4]  = len  packet length in bytes
   //   bit[30:20] = QID  (user field)
   //   bit[63:31] = 0
   //   bit[511:64]= 0    (not sent; size=8B → only 64 bits to host)

   wire [63:0]  cmpt_desc_8b = {33'd0, cur_qid[10:0], cur_len, 1'b1, 1'b0, 1'b0, 1'b0};
   wire [511:0] cmpt_desc    = {{(512-64){1'b0}}, cmpt_desc_8b};

   // Parity: inverted XOR, one bit per 32-bit dword (16 dwords for 512 bits)
   // For upper 14 dwords (bits[511:64]): all zeros → parity bit = ~0 = 1
   // For dword[0] (bits[31:0]) and dword[1] (bits[63:32]): compute from descriptor
   logic [15:0] cmpt_dpar_val;
   always_comb begin
      for (int i = 0; i < 16; i++) begin
         cmpt_dpar_val[i] = ~(^cmpt_desc[i*32 +: 32]);
      end
   end

   // =========================================================================
   // Output assignments
   // =========================================================================
   assign c2h_cmpt_tvalid               = (state == SM_SEND);
   assign c2h_cmpt_tdata                = cmpt_desc;
   assign c2h_cmpt_size                 = 2'b00;        // 8 bytes
   assign c2h_cmpt_dpar                 = cmpt_dpar_val;
   assign c2h_cmpt_ctrl_qid             = cur_qid;
   assign c2h_cmpt_ctrl_port_id         = cur_port_id;
   assign c2h_cmpt_ctrl_cmpt_type       = 2'b11;        // HAS_PLD: paired with data pkt
   assign c2h_cmpt_ctrl_wait_pld_pkt_id = cur_pkt_id;   // the packet this completion belongs to
   assign c2h_cmpt_ctrl_user_trig       = 1'b0;         // no user interrupt
   assign c2h_cmpt_ctrl_col_idx         = 3'd0;         // colour at bit[1]
   assign c2h_cmpt_ctrl_no_wrb_marker   = 1'b0;         // normal (not suppressed)

endmodule
