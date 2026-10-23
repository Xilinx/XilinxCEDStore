// bind.pswizard.sv — Bind ps_wizard interface monitor to the BD top-level
// module's wires.
//
// This CED's own Vivado-generated BD top wrapper is named "cpm6_qdma" (see
// qdma_ced_test.gen/sources_1/bd/cpm6_qdma/sim/cpm6_qdma.v). Every signal
// referenced here was confirmed present, with identical names, against that
// generated netlist.
//
// All BD top wires are declared as input ports so that the bind statement's
// (.*) connects them via standard port resolution (IEEE 1800-2017 section
// 23.3.2), avoiding any dependency on VCS XMRE wire merge across library
// boundaries.
//
// Wire names taken verbatim from cpm6_qdma.v:
//   ps_wizard_0_pl0_ref_clk      — plain scalar (wire)
//   ps_wizard_0_pl0_resetn       — plain scalar (wire)
//   ps_wizard_0_dma0_irq         — wire [127:0]
//   ps_wizard_0_CPM_PCIE_AXI_NOC0_* — UPPERCASE after the underscore prefix
//   ps_wizard_0_CPM_PCIE_AXI_NOC1_* — UPPERCASE after the underscore prefix
// Several NOC handshake signals are wire [0:0] in cpm6_qdma.v; declared here
// as plain scalars — VCS accepts the implicit truncation/extension.
//
// Config DB key registered: "vif_pswizard" (global path "*")

`default_nettype wire
module bind_pswizard
  import uvm_pkg::*;
(
  // Clock / Reset / IRQ
  input wire          ps_wizard_0_pl0_ref_clk,
  input wire          ps_wizard_0_pl0_resetn,
  input wire [127:0]  ps_wizard_0_dma0_irq,

  // CPM_PCIE_AXI_NOC0 — write address channel
  input wire [63:0]   ps_wizard_0_CPM_PCIE_AXI_NOC0_AWADDR,
  input wire [1:0]    ps_wizard_0_CPM_PCIE_AXI_NOC0_AWBURST,
  input wire [3:0]    ps_wizard_0_CPM_PCIE_AXI_NOC0_AWCACHE,
  input wire [15:0]   ps_wizard_0_CPM_PCIE_AXI_NOC0_AWID,
  input wire [7:0]    ps_wizard_0_CPM_PCIE_AXI_NOC0_AWLEN,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC0_AWLOCK,
  input wire [2:0]    ps_wizard_0_CPM_PCIE_AXI_NOC0_AWPROT,
  input wire [3:0]    ps_wizard_0_CPM_PCIE_AXI_NOC0_AWQOS,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC0_AWREADY,   // [0:0] in cpm6_qdma.v
  input wire [2:0]    ps_wizard_0_CPM_PCIE_AXI_NOC0_AWSIZE,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC0_AWVALID,
  // CPM_PCIE_AXI_NOC0 — write data channel
  input wire [127:0]  ps_wizard_0_CPM_PCIE_AXI_NOC0_WDATA,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC0_WLAST,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC0_WREADY,    // [0:0] in cpm6_qdma.v
  input wire [15:0]   ps_wizard_0_CPM_PCIE_AXI_NOC0_WSTRB,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC0_WVALID,
  // CPM_PCIE_AXI_NOC0 — write response channel
  input wire [15:0]   ps_wizard_0_CPM_PCIE_AXI_NOC0_BID,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC0_BREADY,
  input wire [1:0]    ps_wizard_0_CPM_PCIE_AXI_NOC0_BRESP,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC0_BVALID,    // [0:0] in cpm6_qdma.v
  // CPM_PCIE_AXI_NOC0 — read address channel
  input wire [63:0]   ps_wizard_0_CPM_PCIE_AXI_NOC0_ARADDR,
  input wire [1:0]    ps_wizard_0_CPM_PCIE_AXI_NOC0_ARBURST,
  input wire [3:0]    ps_wizard_0_CPM_PCIE_AXI_NOC0_ARCACHE,
  input wire [15:0]   ps_wizard_0_CPM_PCIE_AXI_NOC0_ARID,
  input wire [7:0]    ps_wizard_0_CPM_PCIE_AXI_NOC0_ARLEN,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC0_ARLOCK,
  input wire [2:0]    ps_wizard_0_CPM_PCIE_AXI_NOC0_ARPROT,
  input wire [3:0]    ps_wizard_0_CPM_PCIE_AXI_NOC0_ARQOS,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC0_ARREADY,   // [0:0] in cpm6_qdma.v
  input wire [2:0]    ps_wizard_0_CPM_PCIE_AXI_NOC0_ARSIZE,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC0_ARVALID,
  // CPM_PCIE_AXI_NOC0 — read data channel
  input wire [127:0]  ps_wizard_0_CPM_PCIE_AXI_NOC0_RDATA,
  input wire [15:0]   ps_wizard_0_CPM_PCIE_AXI_NOC0_RID,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC0_RLAST,     // [0:0] in cpm6_qdma.v
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC0_RREADY,
  input wire [1:0]    ps_wizard_0_CPM_PCIE_AXI_NOC0_RRESP,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC0_RVALID,    // [0:0] in cpm6_qdma.v

  // CPM_PCIE_AXI_NOC1 — write address channel
  input wire [63:0]   ps_wizard_0_CPM_PCIE_AXI_NOC1_AWADDR,
  input wire [1:0]    ps_wizard_0_CPM_PCIE_AXI_NOC1_AWBURST,
  input wire [3:0]    ps_wizard_0_CPM_PCIE_AXI_NOC1_AWCACHE,
  input wire [15:0]   ps_wizard_0_CPM_PCIE_AXI_NOC1_AWID,
  input wire [7:0]    ps_wizard_0_CPM_PCIE_AXI_NOC1_AWLEN,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC1_AWLOCK,
  input wire [2:0]    ps_wizard_0_CPM_PCIE_AXI_NOC1_AWPROT,
  input wire [3:0]    ps_wizard_0_CPM_PCIE_AXI_NOC1_AWQOS,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC1_AWREADY,   // [0:0] in cpm6_qdma.v
  input wire [2:0]    ps_wizard_0_CPM_PCIE_AXI_NOC1_AWSIZE,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC1_AWVALID,
  // CPM_PCIE_AXI_NOC1 — write data channel
  input wire [127:0]  ps_wizard_0_CPM_PCIE_AXI_NOC1_WDATA,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC1_WLAST,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC1_WREADY,    // [0:0] in cpm6_qdma.v
  input wire [15:0]   ps_wizard_0_CPM_PCIE_AXI_NOC1_WSTRB,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC1_WVALID,
  // CPM_PCIE_AXI_NOC1 — write response channel
  input wire [15:0]   ps_wizard_0_CPM_PCIE_AXI_NOC1_BID,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC1_BREADY,
  input wire [1:0]    ps_wizard_0_CPM_PCIE_AXI_NOC1_BRESP,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC1_BVALID,    // [0:0] in cpm6_qdma.v
  // CPM_PCIE_AXI_NOC1 — read address channel
  input wire [63:0]   ps_wizard_0_CPM_PCIE_AXI_NOC1_ARADDR,
  input wire [1:0]    ps_wizard_0_CPM_PCIE_AXI_NOC1_ARBURST,
  input wire [3:0]    ps_wizard_0_CPM_PCIE_AXI_NOC1_ARCACHE,
  input wire [15:0]   ps_wizard_0_CPM_PCIE_AXI_NOC1_ARID,
  input wire [7:0]    ps_wizard_0_CPM_PCIE_AXI_NOC1_ARLEN,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC1_ARLOCK,
  input wire [2:0]    ps_wizard_0_CPM_PCIE_AXI_NOC1_ARPROT,
  input wire [3:0]    ps_wizard_0_CPM_PCIE_AXI_NOC1_ARQOS,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC1_ARREADY,   // [0:0] in cpm6_qdma.v
  input wire [2:0]    ps_wizard_0_CPM_PCIE_AXI_NOC1_ARSIZE,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC1_ARVALID,
  // CPM_PCIE_AXI_NOC1 — read data channel
  input wire [127:0]  ps_wizard_0_CPM_PCIE_AXI_NOC1_RDATA,
  input wire [15:0]   ps_wizard_0_CPM_PCIE_AXI_NOC1_RID,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC1_RLAST,     // [0:0] in cpm6_qdma.v
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC1_RREADY,
  input wire [1:0]    ps_wizard_0_CPM_PCIE_AXI_NOC1_RRESP,
  input wire          ps_wizard_0_CPM_PCIE_AXI_NOC1_RVALID     // [0:0] in cpm6_qdma.v

  // ----------------------------------------------------------------
  // cpm_axi_pl0 / cpm_axi_pl1 / cpm_axi_pl3
  // Leading-comma macro style so the conditionally-compiled PL3 group
  // doesn't leave a dangling trailing comma before the closing `)`.
  // ----------------------------------------------------------------
`define PSWIZARD_PL_PORT_DECLS(N) \
  , input wire [50:0]  ps_wizard_0_cpm_axi_pl``N``_AWADDR  \
  , input wire [9:0]   ps_wizard_0_cpm_axi_pl``N``_AWID    \
  , input wire [7:0]   ps_wizard_0_cpm_axi_pl``N``_AWLEN   \
  , input wire [2:0]   ps_wizard_0_cpm_axi_pl``N``_AWSIZE  \
  , input wire [1:0]   ps_wizard_0_cpm_axi_pl``N``_AWBURST \
  , input wire         ps_wizard_0_cpm_axi_pl``N``_AWVALID \
  , input wire         ps_wizard_0_cpm_axi_pl``N``_AWREADY \
  , input wire [63:0]  ps_wizard_0_cpm_axi_pl``N``_WSTRB   \
  , input wire         ps_wizard_0_cpm_axi_pl``N``_WLAST   \
  , input wire         ps_wizard_0_cpm_axi_pl``N``_WVALID  \
  , input wire         ps_wizard_0_cpm_axi_pl``N``_WREADY  \
  , input wire [9:0]   ps_wizard_0_cpm_axi_pl``N``_BID     \
  , input wire [1:0]   ps_wizard_0_cpm_axi_pl``N``_BRESP   \
  , input wire         ps_wizard_0_cpm_axi_pl``N``_BVALID  \
  , input wire         ps_wizard_0_cpm_axi_pl``N``_BREADY  \
  , input wire [50:0]  ps_wizard_0_cpm_axi_pl``N``_ARADDR  \
  , input wire [9:0]   ps_wizard_0_cpm_axi_pl``N``_ARID    \
  , input wire [7:0]   ps_wizard_0_cpm_axi_pl``N``_ARLEN   \
  , input wire [2:0]   ps_wizard_0_cpm_axi_pl``N``_ARSIZE  \
  , input wire [1:0]   ps_wizard_0_cpm_axi_pl``N``_ARBURST \
  , input wire         ps_wizard_0_cpm_axi_pl``N``_ARVALID \
  , input wire         ps_wizard_0_cpm_axi_pl``N``_ARREADY \
  , input wire [9:0]   ps_wizard_0_cpm_axi_pl``N``_RID     \
  , input wire [1:0]   ps_wizard_0_cpm_axi_pl``N``_RRESP   \
  , input wire         ps_wizard_0_cpm_axi_pl``N``_RLAST   \
  , input wire         ps_wizard_0_cpm_axi_pl``N``_RVALID  \
  , input wire         ps_wizard_0_cpm_axi_pl``N``_RREADY

  `PSWIZARD_PL_PORT_DECLS(0)
  `PSWIZARD_PL_PORT_DECLS(1)
`ifdef ENABLE_PL3_BIND
  `PSWIZARD_PL_PORT_DECLS(3)
`endif
`undef PSWIZARD_PL_PORT_DECLS
);
  `include "uvm_macros.svh"

  // ----------------------------------------------------------------
  // Interface instantiation and signal connections
  // ----------------------------------------------------------------
  pswizard_if pswizard_if_inst ();

  // --- Clock / Reset / IRQ ---
  assign pswizard_if_inst.clk     = ps_wizard_0_pl0_ref_clk;
  assign pswizard_if_inst.rst_n   = ps_wizard_0_pl0_resetn;
  assign pswizard_if_inst.dma_irq = ps_wizard_0_dma0_irq;

  // --- CPM_PCIE_AXI_NOC0 write address channel ---
  assign pswizard_if_inst.noc0_awaddr  = ps_wizard_0_CPM_PCIE_AXI_NOC0_AWADDR;
  assign pswizard_if_inst.noc0_awburst = ps_wizard_0_CPM_PCIE_AXI_NOC0_AWBURST;
  assign pswizard_if_inst.noc0_awcache = ps_wizard_0_CPM_PCIE_AXI_NOC0_AWCACHE;
  assign pswizard_if_inst.noc0_awid    = ps_wizard_0_CPM_PCIE_AXI_NOC0_AWID;
  assign pswizard_if_inst.noc0_awlen   = ps_wizard_0_CPM_PCIE_AXI_NOC0_AWLEN;
  assign pswizard_if_inst.noc0_awlock  = ps_wizard_0_CPM_PCIE_AXI_NOC0_AWLOCK;
  assign pswizard_if_inst.noc0_awprot  = ps_wizard_0_CPM_PCIE_AXI_NOC0_AWPROT;
  assign pswizard_if_inst.noc0_awqos   = ps_wizard_0_CPM_PCIE_AXI_NOC0_AWQOS;
  assign pswizard_if_inst.noc0_awready = ps_wizard_0_CPM_PCIE_AXI_NOC0_AWREADY;
  assign pswizard_if_inst.noc0_awsize  = ps_wizard_0_CPM_PCIE_AXI_NOC0_AWSIZE;
  assign pswizard_if_inst.noc0_awvalid = ps_wizard_0_CPM_PCIE_AXI_NOC0_AWVALID;
  // --- CPM_PCIE_AXI_NOC0 write data channel ---
  assign pswizard_if_inst.noc0_wdata   = ps_wizard_0_CPM_PCIE_AXI_NOC0_WDATA;
  assign pswizard_if_inst.noc0_wlast   = ps_wizard_0_CPM_PCIE_AXI_NOC0_WLAST;
  assign pswizard_if_inst.noc0_wready  = ps_wizard_0_CPM_PCIE_AXI_NOC0_WREADY;
  assign pswizard_if_inst.noc0_wstrb   = ps_wizard_0_CPM_PCIE_AXI_NOC0_WSTRB;
  assign pswizard_if_inst.noc0_wvalid  = ps_wizard_0_CPM_PCIE_AXI_NOC0_WVALID;
  // --- CPM_PCIE_AXI_NOC0 write response channel ---
  assign pswizard_if_inst.noc0_bid     = ps_wizard_0_CPM_PCIE_AXI_NOC0_BID;
  assign pswizard_if_inst.noc0_bready  = ps_wizard_0_CPM_PCIE_AXI_NOC0_BREADY;
  assign pswizard_if_inst.noc0_bresp   = ps_wizard_0_CPM_PCIE_AXI_NOC0_BRESP;
  assign pswizard_if_inst.noc0_bvalid  = ps_wizard_0_CPM_PCIE_AXI_NOC0_BVALID;
  // --- CPM_PCIE_AXI_NOC0 read address channel ---
  assign pswizard_if_inst.noc0_araddr  = ps_wizard_0_CPM_PCIE_AXI_NOC0_ARADDR;
  assign pswizard_if_inst.noc0_arburst = ps_wizard_0_CPM_PCIE_AXI_NOC0_ARBURST;
  assign pswizard_if_inst.noc0_arcache = ps_wizard_0_CPM_PCIE_AXI_NOC0_ARCACHE;
  assign pswizard_if_inst.noc0_arid    = ps_wizard_0_CPM_PCIE_AXI_NOC0_ARID;
  assign pswizard_if_inst.noc0_arlen   = ps_wizard_0_CPM_PCIE_AXI_NOC0_ARLEN;
  assign pswizard_if_inst.noc0_arlock  = ps_wizard_0_CPM_PCIE_AXI_NOC0_ARLOCK;
  assign pswizard_if_inst.noc0_arprot  = ps_wizard_0_CPM_PCIE_AXI_NOC0_ARPROT;
  assign pswizard_if_inst.noc0_arqos   = ps_wizard_0_CPM_PCIE_AXI_NOC0_ARQOS;
  assign pswizard_if_inst.noc0_arready = ps_wizard_0_CPM_PCIE_AXI_NOC0_ARREADY;
  assign pswizard_if_inst.noc0_arsize  = ps_wizard_0_CPM_PCIE_AXI_NOC0_ARSIZE;
  assign pswizard_if_inst.noc0_arvalid = ps_wizard_0_CPM_PCIE_AXI_NOC0_ARVALID;
  // --- CPM_PCIE_AXI_NOC0 read data channel ---
  assign pswizard_if_inst.noc0_rdata   = ps_wizard_0_CPM_PCIE_AXI_NOC0_RDATA;
  assign pswizard_if_inst.noc0_rid     = ps_wizard_0_CPM_PCIE_AXI_NOC0_RID;
  assign pswizard_if_inst.noc0_rlast   = ps_wizard_0_CPM_PCIE_AXI_NOC0_RLAST;
  assign pswizard_if_inst.noc0_rready  = ps_wizard_0_CPM_PCIE_AXI_NOC0_RREADY;
  assign pswizard_if_inst.noc0_rresp   = ps_wizard_0_CPM_PCIE_AXI_NOC0_RRESP;
  assign pswizard_if_inst.noc0_rvalid  = ps_wizard_0_CPM_PCIE_AXI_NOC0_RVALID;

  // --- CPM_PCIE_AXI_NOC1 write address channel ---
  assign pswizard_if_inst.noc1_awaddr  = ps_wizard_0_CPM_PCIE_AXI_NOC1_AWADDR;
  assign pswizard_if_inst.noc1_awburst = ps_wizard_0_CPM_PCIE_AXI_NOC1_AWBURST;
  assign pswizard_if_inst.noc1_awcache = ps_wizard_0_CPM_PCIE_AXI_NOC1_AWCACHE;
  assign pswizard_if_inst.noc1_awid    = ps_wizard_0_CPM_PCIE_AXI_NOC1_AWID;
  assign pswizard_if_inst.noc1_awlen   = ps_wizard_0_CPM_PCIE_AXI_NOC1_AWLEN;
  assign pswizard_if_inst.noc1_awlock  = ps_wizard_0_CPM_PCIE_AXI_NOC1_AWLOCK;
  assign pswizard_if_inst.noc1_awprot  = ps_wizard_0_CPM_PCIE_AXI_NOC1_AWPROT;
  assign pswizard_if_inst.noc1_awqos   = ps_wizard_0_CPM_PCIE_AXI_NOC1_AWQOS;
  assign pswizard_if_inst.noc1_awready = ps_wizard_0_CPM_PCIE_AXI_NOC1_AWREADY;
  assign pswizard_if_inst.noc1_awsize  = ps_wizard_0_CPM_PCIE_AXI_NOC1_AWSIZE;
  assign pswizard_if_inst.noc1_awvalid = ps_wizard_0_CPM_PCIE_AXI_NOC1_AWVALID;
  // --- CPM_PCIE_AXI_NOC1 write data channel ---
  assign pswizard_if_inst.noc1_wdata   = ps_wizard_0_CPM_PCIE_AXI_NOC1_WDATA;
  assign pswizard_if_inst.noc1_wlast   = ps_wizard_0_CPM_PCIE_AXI_NOC1_WLAST;
  assign pswizard_if_inst.noc1_wready  = ps_wizard_0_CPM_PCIE_AXI_NOC1_WREADY;
  assign pswizard_if_inst.noc1_wstrb   = ps_wizard_0_CPM_PCIE_AXI_NOC1_WSTRB;
  assign pswizard_if_inst.noc1_wvalid  = ps_wizard_0_CPM_PCIE_AXI_NOC1_WVALID;
  // --- CPM_PCIE_AXI_NOC1 write response channel ---
  assign pswizard_if_inst.noc1_bid     = ps_wizard_0_CPM_PCIE_AXI_NOC1_BID;
  assign pswizard_if_inst.noc1_bready  = ps_wizard_0_CPM_PCIE_AXI_NOC1_BREADY;
  assign pswizard_if_inst.noc1_bresp   = ps_wizard_0_CPM_PCIE_AXI_NOC1_BRESP;
  assign pswizard_if_inst.noc1_bvalid  = ps_wizard_0_CPM_PCIE_AXI_NOC1_BVALID;
  // --- CPM_PCIE_AXI_NOC1 read address channel ---
  assign pswizard_if_inst.noc1_araddr  = ps_wizard_0_CPM_PCIE_AXI_NOC1_ARADDR;
  assign pswizard_if_inst.noc1_arburst = ps_wizard_0_CPM_PCIE_AXI_NOC1_ARBURST;
  assign pswizard_if_inst.noc1_arcache = ps_wizard_0_CPM_PCIE_AXI_NOC1_ARCACHE;
  assign pswizard_if_inst.noc1_arid    = ps_wizard_0_CPM_PCIE_AXI_NOC1_ARID;
  assign pswizard_if_inst.noc1_arlen   = ps_wizard_0_CPM_PCIE_AXI_NOC1_ARLEN;
  assign pswizard_if_inst.noc1_arlock  = ps_wizard_0_CPM_PCIE_AXI_NOC1_ARLOCK;
  assign pswizard_if_inst.noc1_arprot  = ps_wizard_0_CPM_PCIE_AXI_NOC1_ARPROT;
  assign pswizard_if_inst.noc1_arqos   = ps_wizard_0_CPM_PCIE_AXI_NOC1_ARQOS;
  assign pswizard_if_inst.noc1_arready = ps_wizard_0_CPM_PCIE_AXI_NOC1_ARREADY;
  assign pswizard_if_inst.noc1_arsize  = ps_wizard_0_CPM_PCIE_AXI_NOC1_ARSIZE;
  assign pswizard_if_inst.noc1_arvalid = ps_wizard_0_CPM_PCIE_AXI_NOC1_ARVALID;
  // --- CPM_PCIE_AXI_NOC1 read data channel ---
  assign pswizard_if_inst.noc1_rdata   = ps_wizard_0_CPM_PCIE_AXI_NOC1_RDATA;
  assign pswizard_if_inst.noc1_rid     = ps_wizard_0_CPM_PCIE_AXI_NOC1_RID;
  assign pswizard_if_inst.noc1_rlast   = ps_wizard_0_CPM_PCIE_AXI_NOC1_RLAST;
  assign pswizard_if_inst.noc1_rready  = ps_wizard_0_CPM_PCIE_AXI_NOC1_RREADY;
  assign pswizard_if_inst.noc1_rresp   = ps_wizard_0_CPM_PCIE_AXI_NOC1_RRESP;
  assign pswizard_if_inst.noc1_rvalid  = ps_wizard_0_CPM_PCIE_AXI_NOC1_RVALID;

  // --- cpm_axi_pl0 / cpm_axi_pl1 / cpm_axi_pl3 ---
`define PSWIZARD_PL_PORT_ASSIGNS(N) \
  assign pswizard_if_inst.pl``N``_awaddr  = ps_wizard_0_cpm_axi_pl``N``_AWADDR;  \
  assign pswizard_if_inst.pl``N``_awid    = ps_wizard_0_cpm_axi_pl``N``_AWID;    \
  assign pswizard_if_inst.pl``N``_awlen   = ps_wizard_0_cpm_axi_pl``N``_AWLEN;   \
  assign pswizard_if_inst.pl``N``_awsize  = ps_wizard_0_cpm_axi_pl``N``_AWSIZE;  \
  assign pswizard_if_inst.pl``N``_awburst = ps_wizard_0_cpm_axi_pl``N``_AWBURST; \
  assign pswizard_if_inst.pl``N``_awvalid = ps_wizard_0_cpm_axi_pl``N``_AWVALID; \
  assign pswizard_if_inst.pl``N``_awready = ps_wizard_0_cpm_axi_pl``N``_AWREADY; \
  assign pswizard_if_inst.pl``N``_wstrb   = ps_wizard_0_cpm_axi_pl``N``_WSTRB;   \
  assign pswizard_if_inst.pl``N``_wlast   = ps_wizard_0_cpm_axi_pl``N``_WLAST;   \
  assign pswizard_if_inst.pl``N``_wvalid  = ps_wizard_0_cpm_axi_pl``N``_WVALID;  \
  assign pswizard_if_inst.pl``N``_wready  = ps_wizard_0_cpm_axi_pl``N``_WREADY;  \
  assign pswizard_if_inst.pl``N``_bid     = ps_wizard_0_cpm_axi_pl``N``_BID;     \
  assign pswizard_if_inst.pl``N``_bresp   = ps_wizard_0_cpm_axi_pl``N``_BRESP;   \
  assign pswizard_if_inst.pl``N``_bvalid  = ps_wizard_0_cpm_axi_pl``N``_BVALID;  \
  assign pswizard_if_inst.pl``N``_bready  = ps_wizard_0_cpm_axi_pl``N``_BREADY;  \
  assign pswizard_if_inst.pl``N``_araddr  = ps_wizard_0_cpm_axi_pl``N``_ARADDR;  \
  assign pswizard_if_inst.pl``N``_arid    = ps_wizard_0_cpm_axi_pl``N``_ARID;    \
  assign pswizard_if_inst.pl``N``_arlen   = ps_wizard_0_cpm_axi_pl``N``_ARLEN;   \
  assign pswizard_if_inst.pl``N``_arsize  = ps_wizard_0_cpm_axi_pl``N``_ARSIZE;  \
  assign pswizard_if_inst.pl``N``_arburst = ps_wizard_0_cpm_axi_pl``N``_ARBURST; \
  assign pswizard_if_inst.pl``N``_arvalid = ps_wizard_0_cpm_axi_pl``N``_ARVALID; \
  assign pswizard_if_inst.pl``N``_arready = ps_wizard_0_cpm_axi_pl``N``_ARREADY; \
  assign pswizard_if_inst.pl``N``_rid     = ps_wizard_0_cpm_axi_pl``N``_RID;     \
  assign pswizard_if_inst.pl``N``_rresp   = ps_wizard_0_cpm_axi_pl``N``_RRESP;   \
  assign pswizard_if_inst.pl``N``_rlast   = ps_wizard_0_cpm_axi_pl``N``_RLAST;   \
  assign pswizard_if_inst.pl``N``_rvalid  = ps_wizard_0_cpm_axi_pl``N``_RVALID;  \
  assign pswizard_if_inst.pl``N``_rready  = ps_wizard_0_cpm_axi_pl``N``_RREADY;

  `PSWIZARD_PL_PORT_ASSIGNS(0)
  `PSWIZARD_PL_PORT_ASSIGNS(1)
`ifdef ENABLE_PL3_BIND
  `PSWIZARD_PL_PORT_ASSIGNS(3)
`endif
`undef PSWIZARD_PL_PORT_ASSIGNS

  initial begin
    uvm_pkg::uvm_config_db#(virtual pswizard_if)::set(
      null, "*", "vif_pswizard", pswizard_if_inst);
    $display("[BIND_DBG] %0t bind_pswizard: instantiated, config_db set", $time);
    #1;
    $display("[BIND_DBG] %0t bind_pswizard: clk=%b rst_n=%b (X=port not connected)",
             $time, ps_wizard_0_pl0_ref_clk, ps_wizard_0_pl0_resetn);
    @(posedge ps_wizard_0_pl0_resetn);
    $display("[BIND_DBG] %0t bind_pswizard: rst_n DEASSERTED  -  monitor should unblock",
             $time);
  end

endmodule : bind_pswizard
`default_nettype none

bind cpm6_qdma bind_pswizard bind_pswizard_inst (.*);
