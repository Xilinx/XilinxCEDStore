// MODULE : custom_axi_tg_id_gen
//
// DESCRIPTION:
// Combinational next-AXI-ID datapath shared by both dispatchers.
//
//   id_mode == 0 : id_next = id_q + id_stride, truncating to AXI_ID_WIDTH bits
//                  (natural wrap == modulo 2**AXI_ID_WIDTH; there is no ID mask)
//   id_mode == 1 : id_next = a 4-bit OUTPUT TAP SUBSET of the lfsr8 state,
//                  narrowed to AXI_ID_WIDTH bits
//
// DETAILS:
//  - start_id and id_stride are 4-bit instruction fields regardless of
//    AXI_ID_WIDTH -- the instruction layout is fixed at maximum widths so that
//    a program is portable across parameterisations; only [AXI_ID_WIDTH-1:0]
//    of each is used.
//  - The lfsr8 instance itself lives in the dispatcher, next to the other
//    LFSRs, and its state is passed in here.
//
//    ID LFSR.  A maximal-length LFSR never enters the all-zeros STATE, so an
//    LFSR whose width tracked AXI_ID_WIDTH could never emit AXI ID 0.  Using a
//    FIXED 8-bit LFSR and taking a 4-bit SUBSET of its state removes that
//    restriction: a subset of a never-all-zero state CAN be all zero, so ID 0
//    is reachable at every AXI_ID_WIDTH.
//
//    Two distinct tap sets are involved -- do not confuse them:
//      * POLYNOMIAL taps {8,6,5,4}  define the FEEDBACK (localparam POLY=8'hB8
//                                   inside lfsr8.sv)
//      * OUTPUT taps    {7,5,2,0}   define the 4-bit ID nibble below, chosen
//                                   for an even spread across the 8-bit state
//
// RESTRICTIONS:
//  - AXI_ID_WIDTH == 0 hardcodes the AXI ID to 0 on a 1-bit tied-off port; no
//    lfsr8 is instantiated and id_mode is ignored.
//  - AXI_ID_WIDTH == 1 DOES instantiate the ID LFSR.  Because lfsr8 has a
//    fixed width there is no minimum-width restriction to work around, so the
//    single-bit case costs 8 flops and gives a genuinely pseudo-random 1-bit
//    ID instead of a deterministic toggle.

module custom_axi_tg_id_gen #(
  parameter int  AXI_ID_WIDTH = 1,
  localparam int ID_PORT_W    = (AXI_ID_WIDTH==0) ? 1 : AXI_ID_WIDTH
)(
  input        [ID_PORT_W-1:0] id_q,
  input        [          3:0] id_stride,
  input                        id_mode,      // 0 = stride, 1 = lfsr8
  input        [          7:0] lfsr8_state,
  output logic [ID_PORT_W-1:0] id_next
);

  // OUTPUT taps {7,5,2,0} -> id_tap[3:0]
  logic [3:0] id_tap;
  assign id_tap = {lfsr8_state[7], lfsr8_state[5],
                   lfsr8_state[2], lfsr8_state[0]};

  generate
  if (AXI_ID_WIDTH == 0) begin : g_id_tied
    // AXI ID is hardcoded to 0; the port exists only so that the module's
    // interface does not change shape with AXI_ID_WIDTH.
    assign id_next = 1'b0;
  end
  else begin : g_id_gen
    assign id_next = id_mode ? id_tap[ID_PORT_W-1:0]
                             : (id_q + id_stride[ID_PORT_W-1:0]);
  end
  endgenerate

endmodule
