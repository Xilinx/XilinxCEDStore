// cpm_user_aligner
// Latches CPM AXI AW/AR user bits on CPM AW/AR handshakes and holds them
// until the next transaction fires. Since SmartConnect is a 1:1 pass-through,
// the M00 channel fires after CPM, so the latched bits are valid by the time
// axil_slave sees the transaction.
//
// User bits are only captured when the address falls within the AXI-Lite
// slave range: 0x5000000000 to 0x5000001000 (4KB). Transactions to other
// ports are ignored and the output holds its previous value.
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
    input  logic [50:0]  cpm_awaddr,
    input  logic [146:0] cpm_awuser,

    // CPM AXI AR channel
    input  logic         cpm_arvalid,
    input  logic         cpm_arready,
    input  logic [50:0]  cpm_araddr,
    input  logic [55:0]  cpm_aruser,

    // Aligned user bits (held from last qualifying handshake)
    output logic [11:0]  m00_awuser,
    output logic [11:0]  m00_aruser
);

    // AXI-Lite slave address range (4KB at 0x5000000000)
    // cpm_awaddr/araddr[47:0] used (bit[49] is controller number, stripped in hdma_ddr_top)
    localparam logic [47:0] AXIL_BASE = 48'h500_0000_0000;
    localparam logic [47:0] AXIL_TOP  = 48'h500_0000_1000;

    wire aw_in_range = (cpm_awaddr[47:0] >= AXIL_BASE) &&
                       (cpm_awaddr[47:0] <  AXIL_TOP);
    wire ar_in_range = (cpm_araddr[47:0] >= AXIL_BASE) &&
                       (cpm_araddr[47:0] <  AXIL_TOP);

    always_ff @(posedge clk) begin
        if (!reset_n)
            m00_awuser <= '0;
        else if (cpm_awvalid && cpm_awready && aw_in_range)
            m00_awuser <= {cpm_awuser[22:20], cpm_awuser[19:12], cpm_awuser[11]};
    end

    always_ff @(posedge clk) begin
        if (!reset_n)
            m00_aruser <= '0;
        else if (cpm_arvalid && cpm_arready && ar_in_range)
            m00_aruser <= {cpm_aruser[22:20], cpm_aruser[19:12], cpm_aruser[11]};
    end

endmodule
