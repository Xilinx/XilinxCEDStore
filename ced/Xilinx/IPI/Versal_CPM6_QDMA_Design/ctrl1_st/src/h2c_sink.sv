//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// =============================================================================
// h2c_sink.sv
//
// Sample H2C (host→card) AXI4-Stream consumer for one QDMA H2C stream port
// (h2c_st_portN). Each H2C packet arrives as a stream packet here
// (h2c_tlast marks the last beat of each packet).
//
// Features:
//   - Configurable ready: de-assert sink_enable to apply backpressure to the
//     QDMA H2C stream port.
//   - Beat and packet counters.
//   - Captures the last accepted data word for readback / checking.
//   - Byte-count accumulator (uses h2c_tkeep to count valid bytes per beat).
//
// Parameters:
//   DATA_WIDTH  - must match the QDMA H2C stream data width (default 512)
//   CNT_WIDTH   - width of beat/packet/byte counters
// =============================================================================

`timescale 1ps/1ps

module h2c_sink #(
    parameter int DATA_WIDTH = 512,
    parameter int STRB_WIDTH = DATA_WIDTH / 8,   // 64
    parameter int CNT_WIDTH  = 32
) (
    input  logic clk,
    input  logic rst_n,

    // -------------------------------------------------------------------------
    // H2C AXI4-Stream input  (connect to the QDMA h2c_st_portN interface)
    // -------------------------------------------------------------------------
    input  logic [DATA_WIDTH-1:0] h2c_tdata,
    input  logic [STRB_WIDTH-1:0] h2c_tkeep,
    input  logic                  h2c_tlast,
    input  logic                  h2c_tvalid,
    output logic                  h2c_tready,
    // H2C tuser sideband
    input  logic [11:0]           h2c_tuser_qid,
    input  logic [2:0]            h2c_tuser_port_id,
    input  logic [2:0]            h2c_tuser_zero_byte,
    input  logic [5:0]            h2c_tuser_mty,
    input  logic [2:0]            h2c_tuser_err,

    // -------------------------------------------------------------------------
    // Control
    // -------------------------------------------------------------------------
    // De-assert to apply backpressure.
    // Can be tied high for a simple sink that always accepts.
    input  logic                  sink_enable,

    // -------------------------------------------------------------------------
    // Status outputs
    // -------------------------------------------------------------------------
    output logic [CNT_WIDTH-1:0]  beat_count,    // total beats accepted
    output logic [CNT_WIDTH-1:0]  pkt_count,     // total packets accepted (tlast)
    output logic [CNT_WIDTH-1:0]  byte_count,    // valid bytes accepted (via tkeep)

    // One-cycle pulses
    output logic                  beat_accepted, // high in the cycle a beat is taken
    output logic                  pkt_done,      // high in the cycle tlast is taken

    // Last accepted beat (for scoreboard / checking)
    output logic [DATA_WIDTH-1:0] last_data,
    output logic [STRB_WIDTH-1:0] last_keep,

    // Captured tuser sideband (latched from first beat of each packet)
    output logic [11:0]           last_qid,
    output logic [2:0]            last_port_id,
    output logic [5:0]            last_mty       // from last beat of completed packet
);

// ---------------------------------------------------------------------------
// Ready: combinatorial — backpressure is immediate (no register)
// ---------------------------------------------------------------------------
assign h2c_tready = sink_enable;

// A handshake occurs when both sides agree
assign beat_accepted = h2c_tvalid & h2c_tready;
assign pkt_done      = beat_accepted & h2c_tlast;

// ---------------------------------------------------------------------------
// Count valid bytes in the current beat using popcount of tkeep
// ---------------------------------------------------------------------------
logic [$clog2(STRB_WIDTH+1)-1:0] keep_bits;

always_comb begin : popcount
    keep_bits = '0;
    for (int i = 0; i < STRB_WIDTH; i++)
        keep_bits += h2c_tkeep[i];
end

// ---------------------------------------------------------------------------
// Registered counters and data capture
// ---------------------------------------------------------------------------
// Track whether we are mid-packet (to latch QID on first beat only)
logic in_packet;

always_ff @(posedge clk) begin
    if (!rst_n) begin
        beat_count  <= '0;
        pkt_count   <= '0;
        byte_count  <= '0;
        last_data   <= '0;
        last_keep   <= '0;
        last_qid    <= '0;
        last_port_id <= '0;
        last_mty    <= '0;
        in_packet   <= 1'b0;
    end else if (beat_accepted) begin
        beat_count <= beat_count + 1'b1;
        byte_count <= byte_count + CNT_WIDTH'(keep_bits);
        last_data  <= h2c_tdata;
        last_keep  <= h2c_tkeep;

        // Latch QID and port_id on first beat of each packet
        if (!in_packet) begin
            last_qid     <= h2c_tuser_qid;
            last_port_id <= h2c_tuser_port_id;
        end

        if (h2c_tlast) begin
            pkt_count <= pkt_count + 1'b1;
            last_mty  <= h2c_tuser_mty;
            in_packet <= 1'b0;
        end else begin
            in_packet <= 1'b1;
        end
    end
end

endmodule
