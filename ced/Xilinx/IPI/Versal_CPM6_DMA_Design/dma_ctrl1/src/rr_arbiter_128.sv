// Round-robin arbiter for 128 request channels.
//
// Algorithm (masked-priority):
//   1. Build a mask that enables only channels AFTER last_served
//      (i.e., mask[i] = 1 when i > last_served).
//   2. Apply mask to req -> masked_req.
//   3. Isolate the lowest set bit of masked_req using the two's-complement
//      trick: sel = masked_req & (-masked_req).
//   4. If masked_req is empty (wrap-around), fall back to the lowest set bit
//      of the full req vector.
//   5. Encode the one-hot sel to a binary channel number (grant_chn).
//   6. On advance, record served_chn (the channel actually processed by the
//      caller) as last_served — NOT grant_chn, which may have shifted to a
//      newly-arrived lower-indexed channel during processing.
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

    // ----------------------------------------------------------------
    // State
    // ----------------------------------------------------------------
    logic [6:0] last_served;

    // ----------------------------------------------------------------
    // Mask: allow only channels strictly after last_served
    //   mask[i] = 1  when i > last_served
    // ----------------------------------------------------------------
    logic [127:0] mask;

    always_comb begin
        for (int i = 0; i < 128; i++)
            mask[i] = (7'(i) > last_served);
    end

    // ----------------------------------------------------------------
    // Masked request: only post-last_served channels
    // ----------------------------------------------------------------
    logic [127:0] masked_req;
    logic         masked_any;

    assign masked_req = req & mask;
    assign masked_any = |masked_req;

    // ----------------------------------------------------------------
    // Isolate lowest set bit using two's-complement negation:
    //   x & (-x)  ==  x & (~x + 1)
    // sel_masked: lowest requesting channel after last_served
    // sel_full  : lowest requesting channel across all 128 (wrap fallback)
    // ----------------------------------------------------------------
    logic [127:0] sel_masked;
    logic [127:0] sel_full;
    logic [127:0] sel;

    assign sel_masked = masked_req & (~masked_req + 128'd1);
    assign sel_full   = req        & (~req        + 128'd1);

    // prefer masked window; fall back to wrap-around
    assign sel = masked_any ? sel_masked : sel_full;

    // ----------------------------------------------------------------
    // Output: grant valid if any request is pending
    // ----------------------------------------------------------------
    assign grant_vld = |req;

    // ----------------------------------------------------------------
    // One-hot to binary encoder
    // sel has exactly one bit set (by construction); the loop assigns
    // grant_chn for every set bit — with only one bit set the last
    // (and only) assignment is the correct channel number.
    // ----------------------------------------------------------------
    always_comb begin
        grant_chn = 7'h0;
        for (int i = 0; i < 128; i++)
            if (sel[i]) grant_chn = 7'(i);
    end

    // ----------------------------------------------------------------
    // Track the last served channel.
    // Use served_chn (caller's registered chn_num) rather than the
    // combinatorial grant_chn, which may have shifted to a newly-arrived
    // lower-indexed channel by the time advance is asserted.
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
