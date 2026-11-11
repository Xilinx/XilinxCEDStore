// cpm_user_aligner
// Latches CPM AXI AW/AR user bits on CPM AW/AR handshakes and holds them
// until the next transaction fires. Since SmartConnect is a 1:1 pass-through,
// the M00 channel fires after CPM, so the latched bits are valid by the time
// axil_slave sees the transaction.
//
// All transactions on this interface are destined for context programming of
// this AXI-Lite slave, so every AW/AR handshake updates the latched user bits
// unconditionally — no address range filtering is applied.
//
// IMPORTANT: This module holds a single set of latched user bits. Correct
// operation requires that the SmartConnect between CPM and M00_AXI is
// configured with max outstanding AW transactions = 1 (no pipelining of
// multiple AW transactions). If two back-to-back transactions from different
// PF/VFs were in flight simultaneously, the second would overwrite the latch
// before axil_slave samples it for the first, causing a wrong channel index.
//
// User bit extraction (same mapping for AW and AR channels):
//   cpm_awuser/aruser[11]    -> vfunc_active
//   cpm_awuser/aruser[19:12] -> vfunc_num[7:0]
//   cpm_awuser/aruser[22:20] -> pf_num[2:0]
//
// Output packing into m00_awuser/aruser[11:0]:
//   [0]    = vfunc_active
//   [8:1]  = vfunc_num[7:0]
//   [11:9] = pf_num[2:0]

`timescale 1 ps / 1 ps

module cpm_user_aligner (
    input  logic         clk,
    input  logic         reset_n,

    // CPM AXI AW channel
    input  logic         cpm_awvalid,
    input  logic         cpm_awready,
    input  logic [146:0] cpm_awuser,

    // CPM AXI AR channel
    input  logic         cpm_arvalid,
    input  logic         cpm_arready,
    input  logic [55:0]  cpm_aruser,

    // Aligned user bits (held from last qualifying handshake)
    output logic [11:0]  m00_awuser,
    output logic [11:0]  m00_aruser
);

    always_ff @(posedge clk) begin
        if (!reset_n)
            m00_awuser <= '0;
        else if (cpm_awvalid && cpm_awready)
            m00_awuser <= {cpm_awuser[22:20], cpm_awuser[19:12], cpm_awuser[11]};
    end

    always_ff @(posedge clk) begin
        if (!reset_n)
            m00_aruser <= '0;
        else if (cpm_arvalid && cpm_arready)
            m00_aruser <= {cpm_aruser[22:20], cpm_aruser[19:12], cpm_aruser[11]};
    end

endmodule
