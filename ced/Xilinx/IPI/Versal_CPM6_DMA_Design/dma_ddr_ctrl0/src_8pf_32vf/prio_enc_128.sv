// Lowest-set-bit priority encoder for a 128-bit vector — two-level (16 groups x 8 bits).
//
// Replaces the "isolate lowest set bit with the two's-complement trick, then one-hot->binary"
// encoder (sel = req & (~req + 1), then a 128-iteration if-chain), whose 128-bit carry chain plus
// 64-input OR encode trees synthesized to 17-20 logic levels. This version has no wide carry chain:
// per-group any/lowest-bit (8-input functions), a 16-bit lowest-group select, then a pick of the
// chosen group's lowest bit — ~6-8 levels.
//
// Pure combinational, same function as the original:
//   any = |req;   idx = index of the lowest set bit of req (0 when req == 0).
//
// Ports:
//   req : 128-bit request vector
//   idx : binary index (0-127) of the lowest set bit; 0 when no bit is set
//   any : 1 when at least one bit of req is set

`timescale 1 ps / 1 ps

module prio_enc_128 (
    input  logic [127:0] req,
    output logic [6:0]   idx,
    output logic         any
);

    localparam int NG = 16; // groups
    localparam int GW = 8;  // bits per group

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

    logic [NG-1:0] any_g;
    logic [2:0]    fb_g [NG];

    always_comb begin
        for (int g = 0; g < NG; g++) begin
            any_g[g] = |req[g*GW +: GW];
            fb_g[g]  = lsb8(req[g*GW +: GW]);
        end
    end

    wire [NG-1:0] grp_oh = lowest_oh16(any_g);

    logic [2:0] bit_sel;
    always_comb begin
        bit_sel = 3'd0;
        for (int g = 0; g < NG; g++)
            bit_sel = bit_sel | ({3{grp_oh[g]}} & fb_g[g]);
    end

    assign any = |any_g;
    assign idx = {enc16(grp_oh), bit_sel};

endmodule
