// pswizard_if.sv — Portless SV interface for PS wizard interface monitoring
//
// Captures the CPM PCIe-to-NOC AXI interfaces and DMA IRQ vector exposed
// by the ps_wizard_0 block at the BD top-level module wire scope.
//
// Interfaces captured:
//   CPM_PCIE_AXI_NOC0 — CPM DMA engine → NOC port 0 (descriptor fetch / DMA)
//                        128-bit data, 64-bit address, 16-bit ID
//   CPM_PCIE_AXI_NOC1 — CPM DMA engine → NOC port 1 (same geometry)
//   dma_irq [127:0]   — DMA completion interrupt vector (1 bit per channel)
//   pl0_resetn        — PL reset (active low)
//
// Wire names at the BD top level use UPPERCASE for NOC channels:
//   ps_wizard_0_CPM_PCIE_AXI_NOC0_ARADDR  etc.
// Scalar wires use lowercase:
//   ps_wizard_0_pl0_ref_clk, ps_wizard_0_pl0_resetn, ps_wizard_0_dma0_irq
//
// Monitor samples on posedge clk.

interface pswizard_if ();

  // ----------------------------------------------------------------
  // Clock / Reset
  // ----------------------------------------------------------------
  logic         clk;       // ps_wizard_0_pl0_ref_clk (249.997 MHz)
  logic         rst_n;     // ps_wizard_0_pl0_resetn (active low)

  // ----------------------------------------------------------------
  // DMA completion IRQ vector
  // ----------------------------------------------------------------
  logic [127:0] dma_irq;   // ps_wizard_0_dma0_irq

  // ----------------------------------------------------------------
  // CPM_PCIE_AXI_NOC0 — CPM to NOC port 0
  // AXI4 master: 128-bit data, 64-bit addr, 16-bit ID
  // ----------------------------------------------------------------
  // Write address channel
  logic [63:0]  noc0_awaddr;
  logic [1:0]   noc0_awburst;
  logic [3:0]   noc0_awcache;
  logic [15:0]  noc0_awid;
  logic [7:0]   noc0_awlen;
  logic         noc0_awlock;
  logic [2:0]   noc0_awprot;
  logic [3:0]   noc0_awqos;
  logic         noc0_awready;
  logic [2:0]   noc0_awsize;
  logic         noc0_awvalid;
  // Write data channel
  logic [127:0] noc0_wdata;
  logic         noc0_wlast;
  logic         noc0_wready;
  logic [15:0]  noc0_wstrb;
  logic         noc0_wvalid;
  // Write response channel
  logic [15:0]  noc0_bid;
  logic         noc0_bready;
  logic [1:0]   noc0_bresp;
  logic         noc0_bvalid;
  // Read address channel
  logic [63:0]  noc0_araddr;
  logic [1:0]   noc0_arburst;
  logic [3:0]   noc0_arcache;
  logic [15:0]  noc0_arid;
  logic [7:0]   noc0_arlen;
  logic         noc0_arlock;
  logic [2:0]   noc0_arprot;
  logic [3:0]   noc0_arqos;
  logic         noc0_arready;
  logic [2:0]   noc0_arsize;
  logic         noc0_arvalid;
  // Read data channel
  logic [127:0] noc0_rdata;
  logic [15:0]  noc0_rid;
  logic         noc0_rlast;
  logic         noc0_rready;
  logic [1:0]   noc0_rresp;
  logic         noc0_rvalid;

  // ----------------------------------------------------------------
  // CPM_PCIE_AXI_NOC1 — CPM to NOC port 1  (identical geometry)
  // ----------------------------------------------------------------
  // Write address channel
  logic [63:0]  noc1_awaddr;
  logic [1:0]   noc1_awburst;
  logic [3:0]   noc1_awcache;
  logic [15:0]  noc1_awid;
  logic [7:0]   noc1_awlen;
  logic         noc1_awlock;
  logic [2:0]   noc1_awprot;
  logic [3:0]   noc1_awqos;
  logic         noc1_awready;
  logic [2:0]   noc1_awsize;
  logic         noc1_awvalid;
  // Write data channel
  logic [127:0] noc1_wdata;
  logic         noc1_wlast;
  logic         noc1_wready;
  logic [15:0]  noc1_wstrb;
  logic         noc1_wvalid;
  // Write response channel
  logic [15:0]  noc1_bid;
  logic         noc1_bready;
  logic [1:0]   noc1_bresp;
  logic         noc1_bvalid;
  // Read address channel
  logic [63:0]  noc1_araddr;
  logic [1:0]   noc1_arburst;
  logic [3:0]   noc1_arcache;
  logic [15:0]  noc1_arid;
  logic [7:0]   noc1_arlen;
  logic         noc1_arlock;
  logic [2:0]   noc1_arprot;
  logic [3:0]   noc1_arqos;
  logic         noc1_arready;
  logic [2:0]   noc1_arsize;
  logic         noc1_arvalid;
  // Read data channel
  logic [127:0] noc1_rdata;
  logic [15:0]  noc1_rid;
  logic         noc1_rlast;
  logic         noc1_rready;
  logic [1:0]   noc1_rresp;
  logic         noc1_rvalid;

  // ----------------------------------------------------------------
  // cpm_axi_pl0 / cpm_axi_pl1 / cpm_axi_pl3 -- for cross-correlation with
  // PSW_DMA_IRQ in the same log stream. Same wire names/widths as this
  // project's own qdma_boundary_probe.sv uses for cpm_axi_pl0-3 at the
  // IP-boundary scope; here they are read one level up, at the ps_wizard_0
  // BD-cell scope (same convention as the NOC0/NOC1 groups above). No pl2
  // group — does not exist on this BD. pl3 is gated behind `ENABLE_PL3_BIND.
  // ----------------------------------------------------------------
`define PSWIZARD_PL_PORT_FIELDS(N) \
  logic [50:0]  pl``N``_awaddr;   \
  logic [9:0]   pl``N``_awid;     \
  logic [7:0]   pl``N``_awlen;    \
  logic [2:0]   pl``N``_awsize;   \
  logic [1:0]   pl``N``_awburst;  \
  logic         pl``N``_awvalid;  \
  logic         pl``N``_awready;  \
  logic [63:0]  pl``N``_wstrb;    \
  logic         pl``N``_wlast;    \
  logic         pl``N``_wvalid;   \
  logic         pl``N``_wready;   \
  logic [9:0]   pl``N``_bid;      \
  logic [1:0]   pl``N``_bresp;    \
  logic         pl``N``_bvalid;   \
  logic         pl``N``_bready;   \
  logic [50:0]  pl``N``_araddr;   \
  logic [9:0]   pl``N``_arid;     \
  logic [7:0]   pl``N``_arlen;    \
  logic [2:0]   pl``N``_arsize;   \
  logic [1:0]   pl``N``_arburst;  \
  logic         pl``N``_arvalid;  \
  logic         pl``N``_arready;  \
  logic [9:0]   pl``N``_rid;      \
  logic [1:0]   pl``N``_rresp;    \
  logic         pl``N``_rlast;    \
  logic         pl``N``_rvalid;   \
  logic         pl``N``_rready;

  `PSWIZARD_PL_PORT_FIELDS(0)
  `PSWIZARD_PL_PORT_FIELDS(1)
`ifdef ENABLE_PL3_BIND
  `PSWIZARD_PL_PORT_FIELDS(3)
`endif
`undef PSWIZARD_PL_PORT_FIELDS

endinterface
