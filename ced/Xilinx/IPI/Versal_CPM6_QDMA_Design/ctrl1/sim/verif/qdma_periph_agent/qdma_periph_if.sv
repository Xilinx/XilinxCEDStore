// qdma_periph_if.sv — Portless SV interface for QDMA periphery monitoring
//
// Captures ALL external interfaces at the cpm6_qdma module boundary as seen
// from the design_1 block-design wire scope:
//
//   s_axi_mem   (axi_noc2_0_M01_AXI_*)     — 128-bit descriptor fetch + DMA data
//   s_axi_reg   (smartconnect_0_M00_AXI_*)  — 32-bit register access (PIDX, CTXT)
//   m_axil_dbi  (cpm6_qdma_0_M_AXIL_DBI_*) — DBI register access (ISR write-back)
//   msix        (cpm6_qdma_0_PCIE_MSIX_*)   — MSI-X req/grant/error handshake
//
// Monitor samples on posedge clk with #1ps settle.

interface qdma_periph_if ();

   // ----------------------------------------------------------------
   // Clock / Reset
   // ----------------------------------------------------------------
   logic         clk;       // ps_wizard_0_pl0_ref_clk (249.997 MHz)
   logic [0:0]   rst_n;     // proc_sys_reset_0_peripheral_aresetn

   // ----------------------------------------------------------------
   // s_axi_mem — AXI4 slave, 128-bit data, 64-bit addr, 2-bit ID
   // Wire prefix: axi_noc2_0_M01_AXI_*
   // ----------------------------------------------------------------
   // Write address channel
   logic [63:0]  mem_awaddr;
   logic [1:0]   mem_awburst;
   logic [3:0]   mem_awcache;
   logic [1:0]   mem_awid;
   logic [7:0]   mem_awlen;
   logic [0:0]   mem_awlock;
   logic [2:0]   mem_awprot;
   logic [3:0]   mem_awqos;
   logic         mem_awready;
   logic [2:0]   mem_awsize;
   logic [17:0]  mem_awuser;
   logic [0:0]   mem_awvalid;
   // Write data channel
   logic [127:0] mem_wdata;
   logic [0:0]   mem_wlast;
   logic         mem_wready;
   logic [15:0]  mem_wstrb;
   logic [0:0]   mem_wvalid;
   // Write response channel
   logic [1:0]   mem_bid;
   logic [0:0]   mem_bready;
   logic [1:0]   mem_bresp;
   logic         mem_bvalid;
   // Read address channel
   logic [63:0]  mem_araddr;
   logic [1:0]   mem_arburst;
   logic [3:0]   mem_arcache;
   logic [1:0]   mem_arid;
   logic [7:0]   mem_arlen;
   logic [0:0]   mem_arlock;
   logic [2:0]   mem_arprot;
   logic [3:0]   mem_arqos;
   logic         mem_arready;
   logic [2:0]   mem_arsize;
   logic [17:0]  mem_aruser;
   logic [0:0]   mem_arvalid;
   // Read data channel
   logic [127:0] mem_rdata;
   logic [1:0]   mem_rid;
   logic         mem_rlast;
   logic [0:0]   mem_rready;
   logic [1:0]   mem_rresp;
   logic         mem_rvalid;

   // ----------------------------------------------------------------
   // s_axi_reg — AXI4 slave, 32-bit data, 43-bit addr
   // Wire prefix: smartconnect_0_M00_AXI_*
   // Note: AWID/ARID are tied to {1'b0,1'b0} in design_1 (constants,
   //       not wires) — cannot be captured; hardcoded as 2'b00 in monitor.
   // ----------------------------------------------------------------
   // Write address channel
   logic [42:0]  reg_awaddr;
   logic [1:0]   reg_awburst;
   logic [3:0]   reg_awcache;
   logic [7:0]   reg_awlen;
   logic [0:0]   reg_awlock;
   logic [2:0]   reg_awprot;
   logic [3:0]   reg_awqos;
   logic         reg_awready;
   logic [2:0]   reg_awsize;
   logic [136:0] reg_awuser;
   logic         reg_awvalid;
   // Write data channel
   logic [31:0]  reg_wdata;
   logic         reg_wlast;
   logic         reg_wready;
   logic [3:0]   reg_wstrb;
   logic         reg_wvalid;
   // Write response channel
   logic         reg_bready;
   logic [1:0]   reg_bresp;
   logic [2:0]   reg_buser;
   logic         reg_bvalid;
   // Read address channel
   logic [42:0]  reg_araddr;
   logic [1:0]   reg_arburst;
   logic [3:0]   reg_arcache;
   logic [7:0]   reg_arlen;
   logic [0:0]   reg_arlock;
   logic [2:0]   reg_arprot;
   logic [3:0]   reg_arqos;
   logic         reg_arready;
   logic [2:0]   reg_arsize;
   logic [45:0]  reg_aruser;
   logic         reg_arvalid;
   // Read data channel
   logic [31:0]  reg_rdata;
   logic         reg_rlast;
   logic         reg_rready;
   logic [1:0]   reg_rresp;
   logic         reg_rvalid;

   // ----------------------------------------------------------------
   // m_axil_dbi — AXI-Lite master, 32-bit data/addr
   // Wire prefix: cpm6_qdma_0_M_AXIL_DBI_*
   // Note: slave side (AWREADY, WREADY, BVALID, ARREADY, RVALID, RDATA,
   //       RRESP, RUSER) undriven by PS VIP — see Bug F3.
   // ----------------------------------------------------------------
   // Write address channel
   logic [31:0]  dbi_awaddr;
   logic [2:0]   dbi_awprot;
   logic         dbi_awready;
   logic [15:0]  dbi_awuser;
   logic         dbi_awvalid;
   // Write data channel
   logic [31:0]  dbi_wdata;
   logic         dbi_wready;
   logic [3:0]   dbi_wstrb;
   logic [3:0]   dbi_wuser;
   logic         dbi_wvalid;
   // Write response channel
   logic         dbi_bready;
   logic [1:0]   dbi_bresp;
   logic         dbi_bvalid;
   // Read address channel
   logic [31:0]  dbi_araddr;
   logic [2:0]   dbi_arprot;
   logic         dbi_arready;
   logic [15:0]  dbi_aruser;
   logic         dbi_arvalid;
   // Read data channel
   logic [31:0]  dbi_rdata;
   logic         dbi_rready;
   logic [1:0]   dbi_rresp;
   logic [3:0]   dbi_ruser;
   logic         dbi_rvalid;

   // ----------------------------------------------------------------
   // MSIX — sideband handshake
   // Wire prefix: cpm6_qdma_0_PCIE_MSIX_*
   // ----------------------------------------------------------------
   logic         msix_error;
   logic [2:0]   msix_func_num;
   logic         msix_grant;
   logic [1:0]   msix_operation;
   logic         msix_req;
   logic [10:0]  msix_vector_num;
   logic         msix_vfunc_active;
   logic [7:0]   msix_vfunc_num;

endinterface
