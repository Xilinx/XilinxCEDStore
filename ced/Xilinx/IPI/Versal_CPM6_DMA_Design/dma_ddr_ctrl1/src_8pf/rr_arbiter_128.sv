// Round-robin arbiter for 128 request channels (2-stage pipelined).
//
// Algorithm (masked-priority), same arbitration result as the original single-cycle version:
//   1. Channels strictly AFTER last_served are preferred (masked window).
//   2. Pick the lowest requesting channel of the masked window; if the window is empty
//      (wrap-around), fall back to the lowest requesting channel of the full vector.
//   3. On advance, record served_chn (the channel actually processed by the caller)
//      as last_served -- NOT grant_chn, which may have shifted to a newly-arrived
//      lower-indexed channel during processing.
//
// Timing: the original version was one deep combinational cone (128-bit negate, mask,
// encode) and did not meet 250 MHz. The cone is now split in two register stages:
//   stage 1 : per group of 16 channels -> any request / lowest requesting index, for both
//             the masked window and the full vector (registered)
//   stage 2 : pick the lowest group (masked first, then full) and form the 7-bit grant
//             (registered: grant_chn / grant_vld)
// grant_chn / grant_vld therefore lag req by 2 clock cycles. The caller must re-validate
// the grant against its current request vector before using it (pl_example does).
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
//   grant_chn  : binary-encoded channel selected for service (0-127), registered
//   grant_vld  : at least one channel was requesting (grant_chn is valid), registered
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

    output logic [6:0]   grant_chn,  // channel selected (0-127), registered
    output logic         grant_vld   // 1 = grant_chn is valid, registered
);

    localparam int NG = 8;   // groups
    localparam int GW = 16;  // channels per group

    // ----------------------------------------------------------------
    // State
    // ----------------------------------------------------------------
    logic [6:0] last_served;

    // lowest set bit index of a 16-bit vector (0 if none set)
    function automatic logic [3:0] lowest_idx16(input logic [GW-1:0] v);
        logic [3:0] r;
        r = 4'd0;
        for (int j = GW-1; j >= 0; j--)
            if (v[j]) r = 4'(j);
        return r;
    endfunction

    // lowest set bit index of an 8-bit vector (0 if none set)
    function automatic logic [2:0] lowest_idx8(input logic [NG-1:0] v);
        logic [2:0] r;
        r = 3'd0;
        for (int j = NG-1; j >= 0; j--)
            if (v[j]) r = 3'(j);
        return r;
    endfunction

    // ----------------------------------------------------------------
    // Stage 1: per-group request summary (masked window and full vector)
    // ----------------------------------------------------------------
    logic [NG-1:0] m_any_q, f_any_q;
    logic [3:0]    m_idx_q [NG];
    logic [3:0]    f_idx_q [NG];

    always_ff @(posedge clk) begin
        for (int g = 0; g < NG; g++) begin
            logic [GW-1:0] req_g, mreq_g;
            for (int j = 0; j < GW; j++) begin
                req_g[j]  = req[g*GW + j];
                // masked window: channels strictly after last_served
                mreq_g[j] = req[g*GW + j] & (7'(g*GW + j) > last_served);
            end
            m_any_q[g] <= |mreq_g;
            f_any_q[g] <= |req_g;
            m_idx_q[g] <= lowest_idx16(mreq_g);
            f_idx_q[g] <= lowest_idx16(req_g);
        end
    end

    // ----------------------------------------------------------------
    // Stage 2: pick the group (masked window first, wrap-around fallback)
    // ----------------------------------------------------------------
    logic       masked_any;
    logic [2:0] sel_grp;
    logic [3:0] sel_idx;

    always_comb begin
        masked_any = |m_any_q;
        sel_grp    = masked_any ? lowest_idx8(m_any_q) : lowest_idx8(f_any_q);
        sel_idx    = masked_any ? m_idx_q[lowest_idx8(m_any_q)] : f_idx_q[lowest_idx8(f_any_q)];
    end

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            grant_chn <= 7'd0;
            grant_vld <= 1'b0;
        end else begin
            grant_chn <= {sel_grp, sel_idx};
            grant_vld <= |f_any_q;
        end
    end

    // ----------------------------------------------------------------
    // Track the last served channel.
    // Use served_chn (caller's registered chn_num) rather than the
    // grant_chn, which may have shifted to a newly-arrived lower-indexed
    // channel by the time advance is asserted.
    // Reset to 127 so the first masked scan finds nothing and falls
    // back to the full vector, effectively starting at channel 0.
    // ----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!reset_n)
            last_served <= 7'd127;
        else if (advance)
            last_served <= served_chn;
    end

endmodule
