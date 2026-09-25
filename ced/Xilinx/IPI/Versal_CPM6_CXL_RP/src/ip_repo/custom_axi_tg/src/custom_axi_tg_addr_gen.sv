// MODULE : custom_axi_tg_addr_gen
//
// DESCRIPTION:
// Combinational next-address datapath shared by both dispatchers.  The moving
// address window is described by a compact 5-bit field addr_k (K), defined as
// "the number of moving address bits above bit [5:0]", rather than by a full
// 48-bit stride mask -- five instruction bits instead of forty-eight, with no
// loss of expressiveness because every useful window is a power of two:
//
//   mask[x] = 1 for 6 <= x <= K+5, else 0
//   addr[n] = (start_address & ~mask) | (generated & mask)
//
//   K=0  -> mask = 0            -> address is fixed at start_address
//   K=1  -> bit [6] moves       -> 128 B window
//   K=10 -> bits [15:6] move    -> 64 KiB window
//   K=26 -> bits [31:6] move    -> 4 GiB window, consumes tmp[31:0] exactly
//
// Window size is (2**K) * 64 B.  Carry out of bit K+5 is discarded by the
// mask, so the address wraps modulo the window rather than escaping it.
//
// DETAILS:
//  - Stride mode (addr_mode==0): generated = addr_q[31:0] + addr_stride[31:0].
//    addr_stride[5:0] therefore has no effect.
//  - LFSR mode (addr_mode==1): generated = {16'h0, lfsr27_state[25:0], 6'h0}.
//    start_address doubles as the "base".  The LFSR is 27 bits wide because
//    addr_k maxes at 26, so only 26 LFSR bits can ever reach the address and
//    anything wider would be pure waste.  27 bits are maximal - the state as a
//    whole is never all-zero - but the LOW 26 bits ARE all zero in the single
//    state where only bit[26] is set, so an address OFFSET OF ZERO IS
//    REACHABLE.  lfsr27_state[26] never reaches the address; it exists only to
//    make the sequence maximal.
//  - addr[5:0] is always 6'b0 because mask[5:0] is always 0 and
//    start_address[5:0] is forced to zero when it is loaded.  Every generated
//    transaction is therefore 64 B aligned.
//
// RESTRICTIONS:
//  - Legal addr_k is 0..26.  Values 27..31 are CLAMPED TO 26 AT iRAM COMMIT
//    TIME, so this generator only ever sees 0..26 and needs no saturation
//    logic of its own.  Because K maxes at 26 the mask never sets a bit above
//    31, so addr[47:32] always comes from start_address[47:32].
//
// ACRONYMS:
//  - K = addr_k, the count of moving address bits above bit [5:0]

module custom_axi_tg_addr_gen (
  input        [47:0] start_address,
  input        [31:0] addr_stride,
  input        [ 4:0] addr_k,
  input               addr_mode,      // 0 = stride, 1 = lfsr27
  input        [47:0] addr_q,
  input        [26:0] lfsr27_state,
  output logic [47:0] addr_next
);

  logic [47:0] k_mask;
  logic [31:0] tmp;
  logic [47:0] lfsr_win;
  logic [47:0] generated;

  // mask[x] = 1 for 6 <= x <= K+5.  The shift amount is computed 6 bits wide
  // so that addr_k = 26 gives 32, which a 5-bit add would have wrapped to 0.
  assign k_mask    = ((48'h1 << (6'(addr_k) + 6'd6)) - 48'h1) &
                     ~48'h0000_0000_003F;

  assign tmp       = addr_q[31:0] + addr_stride;
  assign lfsr_win  = {16'h0, lfsr27_state[25:0], 6'h0};   // 16 + 26 + 6 = 48

  assign generated = addr_mode ? lfsr_win : {16'h0, tmp};

  assign addr_next = (start_address & ~k_mask) | (generated & k_mask);

endmodule
