//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//=============================================================================
//c2h_source_ctrl.sv
//
//C2H data source controller for one C2H port.  Software starts a burst of
//packets for one queue through the configuration block (c2h_source_cfg):
//the queue (QID), the number of packets (NUM_PKT) and the packet length
//(PKT_BYTES) are written first, then START.  The controller sends NUM_PKT
//packets to that queue, one after another, and returns to idle.
//
//Packet generation is independent of the descriptors the host has posted.
//Software posts descriptors on the queue (PIDX update) and starts the burst;
//a packet that arrives at the DMA without a descriptor is the DMA's drop case.
//
//STOP ends a burst early: a packet already started is always sent in full,
//no further packet starts.  START is taken only while idle.
//
//Data pattern:  beat N of a packet is seed + N (the whole 512-bit word is
//               incremented), with seed = {448'd0, qid[10:0], 5'd0,
//               burst_seq[15:0], beat_idx[31:0]}.  burst_seq counts the bursts
//               started on this port; beat_idx is the number of beats the
//               burst has sent before this packet.
//
//When completions are enabled, a packet is started only when the completion
//generator can take its trigger, so no completion is dropped.  One completion
//trigger is issued per packet started.
//=============================================================================

`timescale 1ps/1ps

module c2h_source_ctrl #(
   parameter int DATA_WIDTH     = 512,
   parameter int PORT_ID        = 0,
   parameter bit HAS_CMPT_EN    = 1'b1  //wait for the completion generator
) (
   input  logic clk,
   input  logic rst_n,

   //---- C2H AXI4-Stream output (to the QDMA C2H stream port) ----
   output logic [DATA_WIDTH-1:0] c2h_tdata,
   output logic [DATA_WIDTH/8-1:0] c2h_tkeep,
   output logic                  c2h_tlast,
   output logic                  c2h_tvalid,
   input  logic                  c2h_tready,
   output logic [11:0]           c2h_ctrl_qid,
   output logic [5:0]            c2h_mty,
   output logic [2:0]            c2h_ctrl_port_id,
   output logic                  c2h_ctrl_marker,
   output logic                  c2h_ctrl_has_cmpt,
   output logic [15:0]           c2h_ctrl_len,

   //---- CMPT trigger (one pulse per C2H packet) ----
   output logic                  cmpt_trigger,
   output logic [10:0]           cmpt_trigger_qid,
   output logic [2:0]            cmpt_trigger_port_id,
   output logic [15:0]           cmpt_trigger_len,     //packet length in bytes, for the completion entry
   input  logic                  cmpt_trigger_rdy,     //completion generator can take a trigger

   //---- Configuration (from c2h_source_cfg) ----
   input  logic [9:0]            cfg_pkt_beats,        //packet length in 64-byte beats
   input  logic [3:0]            cfg_pkt_dsc,          //descriptors one packet uses (not needed to send)
   input  logic [10:0]           cfg_qid,              //queue of the next burst
   input  logic [15:0]           cfg_num_pkt,          //packets in the next burst
   input  logic                  cfg_start,            //one-cycle pulse: start a burst (taken when idle)
   input  logic                  cfg_stop,             //one-cycle pulse: end the burst after the packet in flight

   //---- Status (to c2h_source_cfg) ----
   output logic                  sts_pkt_start,        //a packet starts this cycle
   output logic                  sts_busy,             //a burst is in progress
   output logic [15:0]           sts_left,             //packets of the burst not yet started (0 when idle)
   output logic [15:0]           sts_burst_seq         //bursts started on this port
);

   //-----------------------------------------------------------------------
   //Controller FSM
   //-----------------------------------------------------------------------
   typedef enum logic [1:0] {
      ST_IDLE    = 2'd0,
      ST_TRIGGER = 2'd1,
      ST_WAIT    = 2'd2
   } state_t;

   state_t              state;
   logic                stop_req;         //STOP received during the burst
   logic [15:0]         burst_seq_r;      //bursts started on this port
   logic [10:0]         cur_qid;          //queue of the burst
   logic [9:0]          cur_beats_r;      //packet length of the burst in beats
   logic [15:0]         left_r;           //packets of the burst not yet started
   logic [31:0]         beat_idx;         //first beat index of the current packet

   //c2h_source control signals
   logic                src_start;
   logic [15:0]         src_num_beats;
   logic [DATA_WIDTH-1:0] src_seed;
   logic [11:0]         src_qid;
   logic [2:0]          src_port_id;
   logic                src_busy;
   logic                src_done;

   //A START with a zero packet count is a no-op.  A zero length from the
   //configuration is treated as one beat, so a packet always has a beat.
   logic                start_ok;
   logic [9:0]          eff_beats;
   assign start_ok  = cfg_start && (cfg_num_pkt != '0);
   assign eff_beats = (cfg_pkt_beats == '0) ? 10'd1 : cfg_pkt_beats;

   //CMPT enable (runtime plusarg)
   //Build-time in hardware; a simulation plusarg may still override it.
   logic has_cmpt_en;
   initial has_cmpt_en = HAS_CMPT_EN;
   //synthesis translate_off
   initial if ($test$plusargs("ENABLE_C2H_CMPT")) has_cmpt_en = 1'b1;
   //synthesis translate_on

   logic                trig_ok;          //the completion generator can take a trigger
   logic                pkt_start;        //a packet is committed this cycle
   assign trig_ok   = !has_cmpt_en || cmpt_trigger_rdy;
   assign pkt_start = (state == ST_TRIGGER) && trig_ok && !stop_req;

   always_ff @(posedge clk) begin : p_fsm
      if (!rst_n) begin
         state       <= ST_IDLE;
         stop_req    <= 1'b0;
         burst_seq_r <= '0;
         src_start   <= 1'b0;
      end else begin
         src_start <= 1'b0;   //default: one-cycle pulse

         if (cfg_stop && (state != ST_IDLE))
            stop_req <= 1'b1;

         unique case (state)
            ST_IDLE: begin
               if (start_ok) begin
                  stop_req    <= 1'b0;
                  burst_seq_r <= burst_seq_r + 1'b1;
                  state       <= ST_TRIGGER;
               end
            end

            ST_TRIGGER: begin
               if (stop_req) begin
                  state <= ST_IDLE;
               end else if (trig_ok) begin
                  src_start <= 1'b1;
                  state     <= ST_WAIT;
               end
            end

            ST_WAIT: begin
               if (src_done) begin
                  if ((left_r == '0) || stop_req || cfg_stop)
                     state <= ST_IDLE;
                  else
                     state <= ST_TRIGGER;
               end
            end

            default: state <= ST_IDLE;
         endcase
      end
   end : p_fsm

   //Burst state: loaded on START, advanced per packet.  Read only while a
   //burst is in progress, so it needs no reset.
   always_ff @(posedge clk) begin : p_burst
      if ((state == ST_IDLE) && start_ok) begin
         cur_qid     <= cfg_qid;
         cur_beats_r <= eff_beats;
         left_r      <= cfg_num_pkt;
         beat_idx    <= '0;
      end else begin
         if (pkt_start)
            left_r <= left_r - 1'b1;
         if ((state == ST_WAIT) && src_done)
            beat_idx <= beat_idx + 32'(cur_beats_r);
      end
   end : p_burst

   assign sts_busy      = (state != ST_IDLE);
   assign sts_left      = sts_busy ? left_r : 16'd0;
   assign sts_burst_seq = burst_seq_r;
   assign sts_pkt_start = pkt_start;

   //Trigger one completion per packet (fires with src_start)
   assign cmpt_trigger         = src_start & has_cmpt_en;
   assign cmpt_trigger_qid     = cur_qid;
   assign cmpt_trigger_port_id = PORT_ID[2:0];
   assign cmpt_trigger_len     = {cur_beats_r, 6'd0};

   //-----------------------------------------------------------------------
   //Seed generation — matches c2h_source's incrementing pattern.
   //Beat N of the packet gets: seed + N
   //-----------------------------------------------------------------------
   assign src_seed      = {448'd0, cur_qid, 5'd0, burst_seq_r, beat_idx};
   assign src_num_beats = {6'd0, cur_beats_r};
   assign src_qid       = {1'b0, cur_qid};
   assign src_port_id   = PORT_ID[2:0];

   //-----------------------------------------------------------------------
   //c2h_source instance
   //-----------------------------------------------------------------------
   c2h_source #(
      .DATA_WIDTH (DATA_WIDTH),
      .LEN_WIDTH  (16)
   ) u_c2h_src (
      .clk             (clk),
      .rst_n           (rst_n),
      .c2h_tdata       (c2h_tdata),
      .c2h_tkeep       (c2h_tkeep),
      .c2h_tlast       (c2h_tlast),
      .c2h_tvalid      (c2h_tvalid),
      .c2h_tready      (c2h_tready),
      .c2h_ctrl_qid    (c2h_ctrl_qid),
      .c2h_mty         (c2h_mty),
      .c2h_ctrl_port_id(c2h_ctrl_port_id),
      .c2h_ctrl_marker (c2h_ctrl_marker),
      .c2h_ctrl_has_cmpt(c2h_ctrl_has_cmpt),
      .c2h_ctrl_len    (c2h_ctrl_len),
      .start           (src_start),
      .num_beats       (src_num_beats),
      .seed            (src_seed),
      .qid             (src_qid),
      .port_id         (src_port_id),
      .has_cmpt_en     (has_cmpt_en),
      .busy            (src_busy),
      .done            (src_done),
      .beats_sent      ()
   );

endmodule : c2h_source_ctrl
