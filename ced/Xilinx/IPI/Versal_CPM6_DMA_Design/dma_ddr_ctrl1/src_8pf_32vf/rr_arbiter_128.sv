// Round-robin arbiter for 128 request channels — two-level (16 groups x 8 channels) version.
//
// Drop-in replacement for the earlier flat version (same ports, same combinational behavior,
// cycle-identical grants for identical req/advance/served_chn streams): the flat version isolated
// the lowest set bit of a 128-bit masked vector with a 128-bit two's-complement carry chain
// (~16-22 logic levels). This version splits the 128 channels into 16 groups of 8 and selects in
// two small steps, ~7-8 LUT levels, with no 128-bit carry chain and no last_served compare.
//
// Round-robin rule (unchanged): grant the lowest requesting channel with index > last_served;
// if none, wrap and grant the lowest requesting channel overall. Split by group, with
// last_served = {g_L (group), b_L (bit within group)}:
//   S1: a requesting channel in the SAME group as last_served with bit > b_L     (lowest such)
//   S2: else the lowest group > g_L that has any request, its lowest set bit
//   S3: else (wrap) the lowest group with any request, its lowest set bit
// S1 beats S2 beats S3 — same order as the flat masked-then-full-vector fallback.
//
// Pointer state is kept pre-decoded in registers (updated on advance exactly where the flat version
// updated last_served), so no compare/decode sits in the request-to-grant path:
//   gptr_bin[3:0]  : g_L (binary)          gptr_oh[15:0] : one-hot of g_L
//   gptr_gt[15:0]  : groups > g_L          bmask[7:0]    : bits > b_L within a group
//
// Ports:
//   clk        : system clock (all logic synchronous to rising edge)
//   reset_n    : active-low synchronous reset
//   req        : 128-bit request vector; bit[i] = 1 means channel i has a pending request
//   advance    : pulse for exactly one cycle when the current granted channel has been fully
//                processed (e.g., when pcie_msix_grant fires)
//   served_chn : channel number that was actually serviced (caller's chn_num); latched on
//                advance to preserve correct RR order
//   grant_chn  : binary-encoded channel selected for service (0-127); 0 when no request
//   grant_vld  : at least one channel is requesting (grant_chn is valid)
//
// Reset behaviour: last_served is 127 (group 15, no bits/groups after it), so the first
// arbitration finds nothing "after" and wraps to the lowest requesting channel (channel 0 first).

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

    localparam int NG = 16; // groups
    localparam int GW = 8;  // channels per group

    // ----------------------------------------------------------------
    // Pointer state (pre-decoded last_served)
    // ----------------------------------------------------------------
    logic [3:0]    gptr_bin;
    logic [NG-1:0] gptr_oh;
    logic [NG-1:0] gptr_gt;
    logic [GW-1:0] bmask;

    wire [3:0] srv_g = served_chn[6:3];
    wire [2:0] srv_b = served_chn[2:0];

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            gptr_bin <= 4'd15;
            gptr_oh  <= 16'h8000;
            gptr_gt  <= '0;
            bmask    <= '0;
        end else if (advance) begin
            gptr_bin <= srv_g;
            for (int i = 0; i < NG; i++) begin
                gptr_oh[i] <= (i == int'(srv_g));
                gptr_gt[i] <= (i >  int'(srv_g));
            end
            for (int j = 0; j < GW; j++)
                bmask[j] <= (j > int'(srv_b));
        end
    end

    // ----------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------
    // lowest set bit index of an 8-bit vector (0 if none)
    function automatic logic [2:0] lsb8(input logic [GW-1:0] v);
        logic [2:0] r;
        r = 3'd0;
        for (int i = GW-1; i >= 0; i--)
            if (v[i]) r = 3'(i);
        return r;
    endfunction

    // one-hot of the lowest set bit of a 16-bit vector (0 if none)
    function automatic logic [NG-1:0] lowest_oh16(input logic [NG-1:0] v);
        logic [NG-1:0] r;
        for (int i = 0; i < NG; i++)
            r[i] = v[i] && ((v & ((16'd1 << i) - 16'd1)) == 16'd0);
        return r;
    endfunction

    // binary index of a one-hot 16-bit vector (0 if none)
    function automatic logic [3:0] enc16(input logic [NG-1:0] oh);
        logic [3:0] r;
        r = 4'd0;
        for (int i = 0; i < NG; i++)
            if (oh[i]) r = r | 4'(i);
        return r;
    endfunction

    // ----------------------------------------------------------------
    // Per-group data (depends only on req)
    // ----------------------------------------------------------------
    logic [GW-1:0] req_g [NG];
    logic [NG-1:0] any_g;
    logic [2:0]    fb_g  [NG]; // lowest set bit of each group's requests

    always_comb begin
        for (int g = 0; g < NG; g++) begin
            req_g[g] = req[g*GW +: GW];
            any_g[g] = |req_g[g];
            fb_g[g]  = lsb8(req_g[g]);
        end
    end

    // ----------------------------------------------------------------
    // S1: same group as last_served, bits after last_served's bit
    // ----------------------------------------------------------------
    logic [GW-1:0] reqL;   // requests of the group last_served is in
    logic [GW-1:0] afterL;
    always_comb begin
        reqL = '0;
        for (int g = 0; g < NG; g++)
            reqL = reqL | ({GW{gptr_oh[g]}} & req_g[g]);
    end
    assign afterL   = reqL & bmask;
    wire       s1_valid = |afterL;
    wire [2:0] s1_bit   = lsb8(afterL);

    // ----------------------------------------------------------------
    // S2: next group (> g_L) with any request   S3: wrap — lowest group with any request
    // ----------------------------------------------------------------
    wire [NG-1:0] gm        = any_g & gptr_gt;
    wire          s2_valid  = |gm;
    wire [NG-1:0] s2_oh     = lowest_oh16(gm);
    wire [NG-1:0] s3_oh     = lowest_oh16(any_g);

    logic [2:0] s2_bit, s3_bit;
    always_comb begin
        s2_bit = 3'd0;
        s3_bit = 3'd0;
        for (int g = 0; g < NG; g++) begin
            s2_bit = s2_bit | ({3{s2_oh[g]}} & fb_g[g]);
            s3_bit = s3_bit | ({3{s3_oh[g]}} & fb_g[g]);
        end
    end

    // ----------------------------------------------------------------
    // Final grant: S1, else S2, else S3
    // ----------------------------------------------------------------
    assign grant_vld = |any_g;

    always_comb begin
        if (s1_valid)
            grant_chn = {gptr_bin, s1_bit};
        else if (s2_valid)
            grant_chn = {enc16(s2_oh), s2_bit};
        else
            grant_chn = {enc16(s3_oh), s3_bit};
    end

endmodule
