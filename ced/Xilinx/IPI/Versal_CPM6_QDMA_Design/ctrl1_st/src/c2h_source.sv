//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// =============================================================================
// c2h_source.sv
//
// Sample C2H (card→host) AXI4-Stream producer for one QDMA C2H stream port
// (c2h_st_portN). c2h_source_ctrl instantiates one per port and decides when
// each packet starts and how many beats it has.
//
// Design
// ------
//   FSM:  IDLE ──(start)──► FILL ──(last beat accepted)──► IDLE
//
//   In FILL state the module drives c2h_tvalid=1 and sends an incrementing
//   data pattern, one beat per cycle, subject to backpressure from c2h_tready.
//
//   'start'     - one-cycle pulse to begin a packet
//   'num_beats' - total beats in the packet
//   'seed'      - initial data value; each subsequent beat increments by 1
//   'busy'      - high while transmitting
//   'done'      - one-cycle pulse when the last beat is accepted
//
// Parameters:
//   DATA_WIDTH  - must match the QDMA C2H stream data width (default 512)
//   LEN_WIDTH   - width of num_beats counter (16 → max 65535 beats per packet)
// =============================================================================

`timescale 1ps/1ps

module c2h_source #(
    parameter int DATA_WIDTH = 512,
    parameter int STRB_WIDTH = DATA_WIDTH / 8,   // 64
    parameter int LEN_WIDTH  = 16
) (
    input  logic clk,
    input  logic rst_n,

    // -------------------------------------------------------------------------
    // C2H AXI4-Stream output  (connect to the QDMA c2h_st_portN interface)
    // -------------------------------------------------------------------------
    output logic [DATA_WIDTH-1:0] c2h_tdata,
    output logic [STRB_WIDTH-1:0] c2h_tkeep,
    output logic                  c2h_tlast,
    output logic                  c2h_tvalid,
    input  logic                  c2h_tready,    // backpressure from the QDMA
    // C2H control sideband, sent alongside the data
    output logic [11:0]           c2h_ctrl_qid,
    output logic [5:0]            c2h_mty,
    output logic [2:0]            c2h_ctrl_port_id,
    output logic                  c2h_ctrl_marker,
    output logic                  c2h_ctrl_has_cmpt,
    output logic [15:0]           c2h_ctrl_len,

    // -------------------------------------------------------------------------
    // Control
    // -------------------------------------------------------------------------
    input  logic                  start,         // one-cycle pulse: begin packet
    input  logic [LEN_WIDTH-1:0]  num_beats,     // beats to send (must be ≥1)
    input  logic [DATA_WIDTH-1:0] seed,          // first data word value
    input  logic [11:0]           qid,           // queue ID for this packet
    input  logic [2:0]            port_id,       // port ID for this packet
    input  logic                  has_cmpt_en,   // 1=assert ctrl_has_cmpt

    // -------------------------------------------------------------------------
    // Status
    // -------------------------------------------------------------------------
    output logic                  busy,          // high while sending
    output logic                  done,          // one-cycle pulse: last beat sent
    output logic [LEN_WIDTH-1:0]  beats_sent     // beats pushed so far
);

// ---------------------------------------------------------------------------
// FSM
// ---------------------------------------------------------------------------
typedef enum logic [1:0] {
    S_IDLE = 2'd0,
    S_FILL = 2'd1,
    S_DONE = 2'd2
} state_t;

state_t              state;
logic [LEN_WIDTH-1:0] remaining;      // beats left to send
logic [LEN_WIDTH-1:0] num_beats_q;    // latched num_beats (for ctrl_len first-beat detection)
logic [DATA_WIDTH-1:0] data_reg;      // current beat data (incrementing pattern)

always_ff @(posedge clk) begin
    if (!rst_n) begin
        state       <= S_IDLE;
        remaining   <= '0;
        num_beats_q <= '0;
        data_reg    <= '0;
        beats_sent  <= '0;
    end else begin
        case (state)

            S_IDLE: begin
                if (start && num_beats != '0) begin
                    remaining   <= num_beats;
                    num_beats_q <= num_beats;
                    data_reg    <= seed;
                    beats_sent  <= '0;
                    state       <= S_FILL;
                end
            end

            S_FILL: begin
                // A beat is sent whenever the QDMA accepts it
                if (c2h_tvalid && c2h_tready) begin
                    data_reg   <= data_reg + 1'b1;   // increment pattern
                    beats_sent <= beats_sent + 1'b1;
                    if (remaining == 1) begin
                        state <= S_DONE;
                    end else begin
                        remaining <= remaining - 1'b1;
                    end
                end
            end

            S_DONE: begin
                // Hold done for exactly one cycle then return to idle
                state <= S_IDLE;
            end

            default: state <= S_IDLE;

        endcase
    end
end

// ---------------------------------------------------------------------------
// Output assignments
// ---------------------------------------------------------------------------
assign c2h_tvalid = (state == S_FILL);
assign c2h_tdata  = data_reg;
assign c2h_tkeep  = '1;                                // all byte lanes valid
assign c2h_tlast  = (state == S_FILL) & (remaining == 1);

// C2H ctrl sideband: QID and port_id from inputs; ctrl_len valid on first beat
assign c2h_ctrl_qid      = qid;
assign c2h_mty            = '0;    // all bytes valid (full 64B beats)
assign c2h_ctrl_port_id  = port_id;
assign c2h_ctrl_marker   = 1'b0;
assign c2h_ctrl_has_cmpt = has_cmpt_en;
assign c2h_ctrl_len      = (state == S_FILL && remaining == num_beats_q)
                           ? 16'(num_beats_q) * 16'd64 : 16'h0;

assign busy = (state == S_FILL);
assign done = (state == S_DONE);

endmodule
