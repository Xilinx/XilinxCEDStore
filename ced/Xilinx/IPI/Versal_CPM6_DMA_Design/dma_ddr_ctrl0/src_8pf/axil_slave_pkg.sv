// AXI-Lite context register package.
// Defines the 5-word context payload exported by axil_slave via regs_out.
//
// Logical context fields:
//   reg0 - size
//   reg1 - src_lo
//   reg2 - src_hi
//   reg3 - dst_lo
//   reg4 - dst_hi
//
// Notes:
// - The physical AXI-Lite banks/offsets are decoded in axil_slave.
// - write_req generation and transfer direction (is_c2h) are controlled
//   by axil_slave from the triggered bank, not from reg0[31].

package axil_slave_pkg;

    typedef struct packed {
        logic [31:0] reg4;   // [159:128] dst_hi (trigger)
        logic [31:0] reg3;   // [127: 96] dst_lo
        logic [31:0] reg2;   // [ 95: 64] src_hi
        logic [31:0] reg1;   // [ 63: 32] src_lo
        logic [31:0] reg0;   // [ 31:  0] size
    } axil_regs_t;

endpackage
