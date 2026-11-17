// Round-robin arbiter for 128 request channels, pipelined.
//
// Algorithm (masked-priority):
//   1. Build a mask that enables only channels AFTER last_served
//      (i.e., mask[i] = 1 when i > last_served).
//   2. Find the lowest requesting channel among the masked requests and
//      among all requests (the wrap-around fallback).
//   3. Grant the masked one if there is one, else the full one.
//   4. On advance, record served_chn (the channel actually processed by the
//      caller) as last_served — NOT grant_chn, which may have shifted to a
//      newly-arrived lower-indexed channel during processing.
//
// The lowest-set-bit search is hierarchical (16 groups of 8 channels) and the
// pipeline registers it in three stages, so no path is longer than a few LUT
// levels at a 250 MHz clock:
//   stage 0  mask_q       registered mask for the current last_served
//   stage 1  g_*          per group: any request, lowest requesting channel
//   stage 2  m_*, f_*     lowest requesting channel, masked and full
//   stage 3  grant_*      the grant
// grant_chn/grant_vld therefore follow req a few cycles late. The caller must
// only act on a grant whose channel is still requesting (pl_example checks
// dma_irq_eligible[grant_chn]), and grant_vld is held low from advance until
// the pipeline settles on the new last_served before the next grant.
//
// Ports:
//   clk        : system clock (all logic synchronous to rising edge)
//   reset_n    : active-low synchronous reset
//   req        : 128-bit request vector; bit[i] = 1 means channel i has a
//                pending interrupt
//   advance    : pulse for exactly one cycle when the current granted channel
//                has been fully processed (e.g., when pcie_msix_grant fires)
//   served_chn : channel number that was actually serviced (caller's chn_num);
//                latched into last_served on advance to preserve correct RR order
//   grant_chn  : binary-encoded channel selected for service (0-127)
//   grant_vld  : at least one channel is requesting (grant_chn is valid)
//
// Reset behaviour:
//   last_served is initialised to 127 so the first arbitration starts
//   scanning from channel 0 (lowest-priority fallback covers 0..127).

`timescale 1 ps / 1 ps

module rr_arbiter_128 (
    input  logic         clk,
    input  logic         reset_n,

    input  logic [127:0] req,        // one bit per channel, level-sensitive
    input  logic         advance,    // pulse: current grant has been consumed
    input  logic [6:0]   served_chn, // channel that was actually serviced (caller's chn_num)

    output logic [6:0]   grant_chn,  // channel selected (0-127)
    output logic         grant_vld   // 1 = grant_chn is valid
);

    localparam int HOLD = 3;  // cycles grant_vld stays low after advance (pipeline depth after last_served)

    // ----------------------------------------------------------------
    // State
    // ----------------------------------------------------------------
    logic [6:0] last_served;
    logic [2:0] hold;

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            last_served <= 7'd127;
            hold        <= 3'(HOLD);
        end else if (advance) begin
            last_served <= served_chn;
            hold        <= 3'(HOLD);
        end else if (hold != 3'd0) begin
            hold        <= hold - 3'd1;
        end
    end

    // ----------------------------------------------------------------
    // Stage 0: mask, allowing only channels strictly after last_served
    //   mask_q[i] = 1  when i > last_served
    // ----------------------------------------------------------------
    logic [127:0] mask_q;

    always_ff @(posedge clk) begin
        for (int i = 0; i < 128; i++)
            mask_q[i] <= (7'(i) > last_served);
    end

    // ----------------------------------------------------------------
    // Lowest requesting channel of an 8-channel group: {any, index}
    // ----------------------------------------------------------------
    function automatic logic [3:0] ffs8(input logic [7:0] v);
        ffs8 = 4'b0;
        for (int i = 7; i >= 0; i--)
            if (v[i]) ffs8 = {1'b1, 3'(i)};
    endfunction

    // ----------------------------------------------------------------
    // Stage 1: per group of 8, any request and the lowest one, for the
    // masked requests and for all of them
    // ----------------------------------------------------------------
    logic [15:0] m_gany_q, f_gany_q;
    logic [2:0]  m_gidx_q [16];
    logic [2:0]  f_gidx_q [16];

    always_ff @(posedge clk) begin
        for (int g = 0; g < 16; g++) begin
            {m_gany_q[g], m_gidx_q[g]} <= ffs8(req[g*8 +: 8] & mask_q[g*8 +: 8]);
            {f_gany_q[g], f_gidx_q[g]} <= ffs8(req[g*8 +: 8]);
        end
    end

    // ----------------------------------------------------------------
    // Stage 2: lowest requesting group, then its lowest channel
    // ----------------------------------------------------------------
    logic       m_vld_q, f_vld_q;
    logic [6:0] m_idx_q, f_idx_q;
    logic       m_vld_d, f_vld_d;
    logic [6:0] m_idx_d, f_idx_d;

    always_comb begin
        m_vld_d = 1'b0;
        m_idx_d = 7'd0;
        f_vld_d = 1'b0;
        f_idx_d = 7'd0;
        for (int g = 15; g >= 0; g--) begin
            if (m_gany_q[g]) begin m_vld_d = 1'b1; m_idx_d = {4'(g), m_gidx_q[g]}; end
            if (f_gany_q[g]) begin f_vld_d = 1'b1; f_idx_d = {4'(g), f_gidx_q[g]}; end
        end
    end

    always_ff @(posedge clk) begin
        m_vld_q <= m_vld_d;
        m_idx_q <= m_idx_d;
        f_vld_q <= f_vld_d;
        f_idx_q <= f_idx_d;
    end

    // ----------------------------------------------------------------
    // Stage 3: prefer the masked window; fall back to wrap-around.
    // Valid if any request is pending, once the pipeline has settled after
    // the last advance.
    // ----------------------------------------------------------------
    always_ff @(posedge clk) begin
        grant_chn <= m_vld_q ? m_idx_q : f_idx_q;
        grant_vld <= f_vld_q && (hold == 3'd0) && !advance;
    end

endmodule