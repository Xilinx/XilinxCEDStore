// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
// =============================================================================
// dsc_crdt_exerciser.sv
//
// Register-programmable descriptor credit exerciser for CPM6 QDMA.
// Drives the dsc_crdt_in interface (valid/ready handshake) and monitors
// tm_dsc_sts feedback.  Two operating modes:
//
//   mode=0 (burst):          Inject a fixed burst_cnt of credits, then stop.
//   mode=1 (auto-replenish): Monitor tm_dsc_sts.avl and re-inject credits
//                            whenever the available count drops to/below a
//                            programmable threshold.
// =============================================================================

module dsc_crdt_exerciser #(
   parameter int P_QID_WIDTH    = 12,
   parameter int P_CRDT_WIDTH   = 16,
   parameter int P_TM_QID_WIDTH = 13,
   parameter int P_ADDR_WIDTH   = 8
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
   // dsc_crdt_in master
   // -------------------------------------------------------------------------
   output logic                        dsc_crdt_in_vld,
   input  logic                        dsc_crdt_in_rdy,
   output logic                        dsc_crdt_in_dir,
   output logic                        dsc_crdt_in_fence,
   output logic [P_QID_WIDTH-1:0]      dsc_crdt_in_qid,
   output logic [P_CRDT_WIDTH-1:0]     dsc_crdt_in_crdt,

   // -------------------------------------------------------------------------
   // tm_dsc_sts monitor
   // -------------------------------------------------------------------------
   input  logic                        tm_dsc_sts_vld,
   output logic                        tm_dsc_sts_rdy,
   input  logic [P_TM_QID_WIDTH-1:0]   tm_dsc_sts_qid,
   input  logic                        tm_dsc_sts_dir,
   input  logic [P_CRDT_WIDTH-1:0]     tm_dsc_sts_avl,
   input  logic                        tm_dsc_sts_error,
   input  logic                        tm_dsc_sts_qen,
   input  logic                        tm_dsc_sts_byp,
   input  logic                        tm_dsc_sts_mm,
   input  logic                        tm_dsc_sts_qinv,
   input  logic                        tm_dsc_sts_irq_arm,
   input  logic [2:0]                  tm_dsc_sts_port_id,
   input  logic [P_CRDT_WIDTH-1:0]     tm_dsc_sts_pidx,
   input  logic [P_QID_WIDTH-1:0]      tm_dsc_sts_func,

   // -------------------------------------------------------------------------
   // Interrupt
   // -------------------------------------------------------------------------
   output logic                        irq_out
);

   // ==========================================================================
   // FSM state encoding
   // ==========================================================================
   typedef enum logic [2:0] {
      ST_IDLE      = 3'd0,
      ST_INJECT    = 3'd1,
      ST_WAIT_INTV = 3'd2,
      ST_DONE      = 3'd3,
      ST_MONITOR   = 3'd4,
      ST_REPLENISH = 3'd5
   } fsm_state_e;

   // ==========================================================================
   // Register offsets
   // ==========================================================================
   localparam logic [P_ADDR_WIDTH-1:0] ADDR_CTRL         = 8'h00;
   localparam logic [P_ADDR_WIDTH-1:0] ADDR_QID_CFG      = 8'h04;
   localparam logic [P_ADDR_WIDTH-1:0] ADDR_CRDT_CFG     = 8'h08;
   localparam logic [P_ADDR_WIDTH-1:0] ADDR_BURST_CFG    = 8'h0C;
   localparam logic [P_ADDR_WIDTH-1:0] ADDR_THRESH_CFG   = 8'h10;
   localparam logic [P_ADDR_WIDTH-1:0] ADDR_STATUS       = 8'h14;
   localparam logic [P_ADDR_WIDTH-1:0] ADDR_CRDT_SENT    = 8'h18;
   localparam logic [P_ADDR_WIDTH-1:0] ADDR_TM_STS_CNT   = 8'h1C;
   localparam logic [P_ADDR_WIDTH-1:0] ADDR_TM_STS_CAP0  = 8'h20;
   localparam logic [P_ADDR_WIDTH-1:0] ADDR_TM_STS_CAP1  = 8'h24;
   localparam logic [P_ADDR_WIDTH-1:0] ADDR_ERR_CNT      = 8'h28;
   localparam logic [P_ADDR_WIDTH-1:0] ADDR_INTERVAL_CFG = 8'h2C;
   localparam logic [P_ADDR_WIDTH-1:0] ADDR_VERSION      = 8'h30;

   localparam logic [31:0] VERSION_STAMP = 32'h2026_0323;

   // ==========================================================================
   // Configuration registers (no reset: not functionally required)
   // ==========================================================================
   logic [P_QID_WIDTH-1:0]  cfg_qid_r;
   logic                    cfg_dir_r;
   logic                    cfg_fence_r;
   logic [P_CRDT_WIDTH-1:0] cfg_crdt_r;
   logic [15:0]             cfg_burst_cnt_r;
   logic [P_CRDT_WIDTH-1:0] cfg_avl_thresh_r;
   logic [P_CRDT_WIDTH-1:0] cfg_replenish_crdt_r;
   logic                    cfg_mode_r;
   logic                    cfg_irq_en_r;
   logic [31:0]             cfg_interval_r;

   // Control pulses (reset — must be known at reset)
   logic                    ctrl_start_r;
   logic                    ctrl_stop_r;
   logic                    ctrl_clr_stats_r;

   // ==========================================================================
   // Status / statistics (sticky bits reset, counters not reset)
   // ==========================================================================
   logic                    sts_busy_r;
   logic                    sts_done_r;
   logic                    sts_error_r;
   logic                    sts_qen_r;
   logic                    sts_qinv_r;

   logic [31:0]             crdt_sent_cnt_r;
   logic [31:0]             tm_sts_cnt_r;
   logic [31:0]             err_cnt_r;

   // tm_dsc_sts capture registers (no reset)
   logic [P_CRDT_WIDTH-1:0] cap_avl_r;
   logic [P_TM_QID_WIDTH-1:0] cap_qid_r;
   logic                    cap_dir_r;
   logic                    cap_mm_r;
   logic                    cap_byp_r;
   logic [P_CRDT_WIDTH-1:0] cap_pidx_r;
   logic [P_QID_WIDTH-1:0]  cap_func_r;
   logic [2:0]              cap_port_id_r;
   logic                    cap_irq_arm_r;

   // ==========================================================================
   // FSM signals
   // ==========================================================================
   fsm_state_e              fsm_state_r;
   logic [15:0]             burst_remaining_r;
   logic [31:0]             interval_cnt_r;

   // ==========================================================================
   // AXI-Lite write channel state
   // ==========================================================================
   logic                    aw_captured_r;
   logic [P_ADDR_WIDTH-1:0] aw_addr_r;
   logic                    b_pending_r;

   // AXI-Lite read channel state
   logic                    ar_captured_r;
   logic [P_ADDR_WIDTH-1:0] ar_addr_r;
   logic                    r_pending_r;
   logic [31:0]             rdata_r;

   // Internal handshake
   logic                    wr_en;
   logic [P_ADDR_WIDTH-1:0] wr_addr;
   logic [31:0]             wr_data;

   // tm_dsc_sts match
   logic                    tm_match;

   // Credit handshake
   logic                    crdt_handshake;

   // ==========================================================================
   // tm_dsc_sts — always-ready consumer
   // ==========================================================================
   assign tm_dsc_sts_rdy = 1'b1;

   // ==========================================================================
   // tm_dsc_sts match logic
   // ==========================================================================
   assign tm_match = tm_dsc_sts_vld
                   & (tm_dsc_sts_qid[P_QID_WIDTH-1:0] == cfg_qid_r)
                   & (tm_dsc_sts_dir == cfg_dir_r);

   // ==========================================================================
   // Credit output
   // ==========================================================================
   assign dsc_crdt_in_vld   = (fsm_state_r == ST_INJECT) || (fsm_state_r == ST_REPLENISH);
   assign dsc_crdt_in_dir   = cfg_dir_r;
   assign dsc_crdt_in_fence = cfg_fence_r;
   assign dsc_crdt_in_qid   = cfg_qid_r;
   assign dsc_crdt_in_crdt  = (fsm_state_r == ST_REPLENISH && cfg_replenish_crdt_r != '0)
                               ? cfg_replenish_crdt_r : cfg_crdt_r;

   assign crdt_handshake = dsc_crdt_in_vld & dsc_crdt_in_rdy;

   // ==========================================================================
   // Interrupt
   // ==========================================================================
   assign irq_out = cfg_irq_en_r & (sts_done_r | sts_error_r);

   // ==========================================================================
   // AXI-Lite responses — always OKAY (the register block never returns SLVERR)
   // ==========================================================================
   assign s_axil_bresp = 2'b00;
   assign s_axil_rresp = 2'b00;

   // ==========================================================================
   // AXI-Lite write handshake
   // ==========================================================================
   assign s_axil_awready = !aw_captured_r & !b_pending_r;
   assign s_axil_wready  = aw_captured_r & s_axil_wvalid & !b_pending_r;
   assign s_axil_bvalid  = b_pending_r;

   assign wr_en   = aw_captured_r & s_axil_wvalid & !b_pending_r;
   assign wr_addr = aw_addr_r;
   assign wr_data = s_axil_wdata;

   always_ff @(posedge aclk) begin : p_axil_wr
      if (!aresetn) begin
         aw_captured_r <= 1'b0;
         b_pending_r   <= 1'b0;
      end else begin
         // Capture AW
         if (s_axil_awvalid & s_axil_awready) begin
            aw_captured_r <= 1'b1;
            aw_addr_r     <= s_axil_awaddr;
         end else if (wr_en) begin
            aw_captured_r <= 1'b0;
         end

         // B response
         if (wr_en) begin
            b_pending_r <= 1'b1;
         end else if (b_pending_r & s_axil_bready) begin
            b_pending_r <= 1'b0;
         end
      end
   end : p_axil_wr

   // ==========================================================================
   // AXI-Lite read handshake
   // ==========================================================================
   assign s_axil_arready = !ar_captured_r & !r_pending_r;
   assign s_axil_rvalid  = r_pending_r;
   assign s_axil_rdata   = rdata_r;

   always_ff @(posedge aclk) begin : p_axil_rd
      if (!aresetn) begin
         ar_captured_r <= 1'b0;
         r_pending_r   <= 1'b0;
      end else begin
         // Capture AR
         if (s_axil_arvalid & s_axil_arready) begin
            ar_captured_r <= 1'b1;
            ar_addr_r     <= s_axil_araddr;
         end

         // Generate read response
         if (ar_captured_r & !r_pending_r) begin
            r_pending_r   <= 1'b1;
            ar_captured_r <= 1'b0;

            unique case (ar_addr_r)
               ADDR_CTRL:         rdata_r <= {28'd0, cfg_irq_en_r, cfg_mode_r, 2'b00};
               ADDR_QID_CFG:      rdata_r <= {18'd0, cfg_fence_r, cfg_dir_r, cfg_qid_r};
               ADDR_CRDT_CFG:     rdata_r <= {16'd0, cfg_crdt_r};
               ADDR_BURST_CFG:    rdata_r <= {16'd0, cfg_burst_cnt_r};
               ADDR_THRESH_CFG:   rdata_r <= {cfg_replenish_crdt_r, cfg_avl_thresh_r};
               ADDR_STATUS:       rdata_r <= {24'd0, fsm_state_r, sts_qinv_r, sts_qen_r,
                                              sts_error_r, sts_done_r, sts_busy_r};
               ADDR_CRDT_SENT:    rdata_r <= crdt_sent_cnt_r;
               ADDR_TM_STS_CNT:   rdata_r <= tm_sts_cnt_r;
               ADDR_TM_STS_CAP0:  rdata_r <= {cap_byp_r, cap_mm_r, cap_dir_r,
                                               cap_qid_r, cap_avl_r};
               ADDR_TM_STS_CAP1:  rdata_r <= {cap_irq_arm_r, cap_port_id_r,
                                               cap_func_r, cap_pidx_r};
               ADDR_ERR_CNT:      rdata_r <= err_cnt_r;
               ADDR_INTERVAL_CFG: rdata_r <= cfg_interval_r;
               ADDR_VERSION:      rdata_r <= VERSION_STAMP;
               default:           rdata_r <= '0;
            endcase
         end else if (r_pending_r & s_axil_rready) begin
            r_pending_r <= 1'b0;
         end
      end
   end : p_axil_rd

   // ==========================================================================
   // Configuration registers
   // ==========================================================================
   always_ff @(posedge aclk) begin : p_cfg_regs
      if (!aresetn) begin
         ctrl_start_r     <= 1'b0;
         ctrl_stop_r      <= 1'b0;
         ctrl_clr_stats_r <= 1'b0;
      end else begin
         // Self-clear pulses
         if (ctrl_start_r)     ctrl_start_r     <= 1'b0;
         if (ctrl_stop_r)      ctrl_stop_r      <= 1'b0;
         if (ctrl_clr_stats_r) ctrl_clr_stats_r <= 1'b0;

         if (wr_en) begin
            unique case (wr_addr)
               ADDR_CTRL: begin
                  ctrl_start_r     <= wr_data[0];
                  ctrl_stop_r      <= wr_data[1];
                  cfg_mode_r       <= wr_data[2];
                  cfg_irq_en_r     <= wr_data[3];
                  ctrl_clr_stats_r <= wr_data[4];
               end
               ADDR_QID_CFG: begin
                  cfg_qid_r   <= wr_data[P_QID_WIDTH-1:0];
                  cfg_dir_r   <= wr_data[12];
                  cfg_fence_r <= wr_data[13];
               end
               ADDR_CRDT_CFG: begin
                  cfg_crdt_r <= wr_data[P_CRDT_WIDTH-1:0];
               end
               ADDR_BURST_CFG: begin
                  cfg_burst_cnt_r <= wr_data[15:0];
               end
               ADDR_THRESH_CFG: begin
                  cfg_avl_thresh_r     <= wr_data[P_CRDT_WIDTH-1:0];
                  cfg_replenish_crdt_r <= wr_data[31:16];
               end
               ADDR_INTERVAL_CFG: begin
                  cfg_interval_r <= wr_data;
               end
               default: ; // no-op
            endcase
         end
      end
   end : p_cfg_regs

   // ==========================================================================
   // Credit injection FSM
   // ==========================================================================
   always_ff @(posedge aclk) begin : p_fsm
      if (!aresetn) begin
         fsm_state_r <= ST_IDLE;
         sts_busy_r  <= 1'b0;
         sts_done_r  <= 1'b0;
         sts_error_r <= 1'b0;
         sts_qinv_r  <= 1'b0;
      end else begin
         // Sticky status from tm_dsc_sts (must be in this block to avoid multi-driver)
         if (tm_match) begin
            if (tm_dsc_sts_error) sts_error_r <= 1'b1;
            if (tm_dsc_sts_qinv)  sts_qinv_r  <= 1'b1;
            sts_qen_r <= tm_dsc_sts_qen;
         end

         // Stop overrides all states
         if (ctrl_stop_r && fsm_state_r != ST_IDLE) begin
            fsm_state_r <= ST_IDLE;
            sts_busy_r  <= 1'b0;
         end else begin
            unique case (fsm_state_r)
               ST_IDLE: begin
                  if (ctrl_start_r) begin
                     sts_done_r  <= 1'b0;
                     sts_error_r <= 1'b0;
                     sts_qinv_r  <= 1'b0;
                     sts_qen_r   <= 1'b0;
                     sts_busy_r  <= 1'b1;
                     if (cfg_mode_r) begin
                        fsm_state_r <= ST_MONITOR;
                     end else begin
                        burst_remaining_r <= cfg_burst_cnt_r;
                        fsm_state_r       <= ST_INJECT;
                     end
                  end
               end

               ST_INJECT: begin
                  if (crdt_handshake) begin
                     if (burst_remaining_r <= 16'd1) begin
                        fsm_state_r <= ST_DONE;
                     end else begin
                        burst_remaining_r <= burst_remaining_r - 16'd1;
                        interval_cnt_r    <= cfg_interval_r;
                        if (cfg_interval_r == '0) begin
                           fsm_state_r <= ST_INJECT;
                        end else begin
                           fsm_state_r <= ST_WAIT_INTV;
                        end
                     end
                  end
               end

               ST_WAIT_INTV: begin
                  if (interval_cnt_r <= 32'd1) begin
                     fsm_state_r <= ST_INJECT;
                  end else begin
                     interval_cnt_r <= interval_cnt_r - 32'd1;
                  end
               end

               ST_DONE: begin
                  sts_done_r  <= 1'b1;
                  sts_busy_r  <= 1'b0;
                  fsm_state_r <= ST_IDLE;
               end

               ST_MONITOR: begin
                  if (tm_match && (tm_dsc_sts_avl <= cfg_avl_thresh_r)) begin
                     fsm_state_r <= ST_REPLENISH;
                  end
               end

               ST_REPLENISH: begin
                  if (crdt_handshake) begin
                     fsm_state_r <= ST_MONITOR;
                  end
               end

               default: begin
                  fsm_state_r <= ST_IDLE;
               end
            endcase
         end
      end
   end : p_fsm

   // ==========================================================================
   // Statistics counters & tm_dsc_sts capture
   // ==========================================================================
   always_ff @(posedge aclk) begin : p_stats
      if (!aresetn) begin
         // Counters and captures are not reset (not functionally required)
      end else begin
         // W1C — writing to the counter register clears it
         if (wr_en && wr_addr == ADDR_CRDT_SENT)  crdt_sent_cnt_r <= '0;
         if (wr_en && wr_addr == ADDR_TM_STS_CNT)  tm_sts_cnt_r   <= '0;
         if (wr_en && wr_addr == ADDR_ERR_CNT)      err_cnt_r      <= '0;

         // clr_stats also clears all counters
         if (ctrl_clr_stats_r) begin
            crdt_sent_cnt_r <= '0;
            tm_sts_cnt_r    <= '0;
            err_cnt_r       <= '0;
         end

         // Credit handshake counter
         if (crdt_handshake && !(wr_en && wr_addr == ADDR_CRDT_SENT) && !ctrl_clr_stats_r) begin
            if (crdt_sent_cnt_r != 32'hFFFF_FFFF)
               crdt_sent_cnt_r <= crdt_sent_cnt_r + 32'd1;
         end

         // tm_dsc_sts capture & counting
         if (tm_match) begin
            // Increment match counter
            if (!(wr_en && wr_addr == ADDR_TM_STS_CNT) && !ctrl_clr_stats_r) begin
               if (tm_sts_cnt_r != 32'hFFFF_FFFF)
                  tm_sts_cnt_r <= tm_sts_cnt_r + 32'd1;
            end

            // Capture fields
            cap_avl_r     <= tm_dsc_sts_avl;
            cap_qid_r     <= tm_dsc_sts_qid;
            cap_dir_r     <= tm_dsc_sts_dir;
            cap_mm_r      <= tm_dsc_sts_mm;
            cap_byp_r     <= tm_dsc_sts_byp;
            cap_pidx_r    <= tm_dsc_sts_pidx;
            cap_func_r    <= tm_dsc_sts_func;
            cap_port_id_r <= tm_dsc_sts_port_id;
            cap_irq_arm_r <= tm_dsc_sts_irq_arm;

            // Error counter
            if (tm_dsc_sts_error) begin
               if (!(wr_en && wr_addr == ADDR_ERR_CNT) && !ctrl_clr_stats_r) begin
                  if (err_cnt_r != 32'hFFFF_FFFF)
                     err_cnt_r <= err_cnt_r + 32'd1;
               end
            end
         end
      end
   end : p_stats

endmodule : dsc_crdt_exerciser
