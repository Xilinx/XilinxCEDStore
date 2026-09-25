// bind.qdma_periph.sv — Bind QDMA periphery monitor to the cpm6_qdma BD wrapper
//
// This CED's BD wrapper module type is `cpm6_qdma`, confirmed via
// cpm6_qdma.gen/.../sim/cpm6_qdma.v and this project's own bind.pswizard.sv,
// which already binds the same module. Wire names/widths at this scope
// (qdma_s_axi_mem_*, qdma_s_axi_reg_*, qdma_M_AXIL_DBI_*,
// cpm6_qdma_0_PCIE_MSIX_*) were verified directly against the generated
// netlist.
//
// Bind target: plain "bind cpm6_qdma" (same as this project's own PSW).
//
// All cpm6_qdma wires are declared as input ports so that the bind statement's
// (.*) connects them via standard port resolution (IEEE 1800-2017 section
// 23.3.2), avoiding any dependency on VCS XMRE wire merge across library
// boundaries.
//
// Monitored interfaces:
//   s_axi_mem   — qdma_s_axi_mem_*      (128-bit, descriptor fetch + DMA data)
//   s_axi_reg   — qdma_s_axi_reg_*   (32-bit, register access)
//   m_axil_dbi  — qdma_M_AXIL_DBI_*   (32-bit AXI-Lite, ISR write-back)
//   msix        — cpm6_qdma_0_PCIE_MSIX_*     (sideband handshake)
//
// Note: s_axi_reg AWID/ARID are tied to {1'b0,1'b0} at this wire scope
//       (constants, not wires) — cannot be captured by bind. Hardcoded as
//       2'b00 in monitor.
//
// Note: tm_dsc_sts is NOT wired here (no bind.tm_dsc_sts.sv in this project —
//       it needs a `CPM6_TOP_WRAPPER macro / cpm6_qdma_ver.svh, which this
//       project does not have). qdma_periph_tm_dsc_if.sv is still compiled
//       (the monitor's build_phase references the type), but its config_db
//       get is a soft/non-fatal get — tm_dsc_sts observation is simply
//       disabled here (one-time uvm_warning). Full tm_dsc_sts coverage for
//       this project instead comes from the pre-existing
//       qdma_boundary_probe.sv, which already captures it in full.
//
// Config DB key registered: "vif_qdma_periph" (global path "*")

`default_nettype wire
module bind_qdma_periph
   import uvm_pkg::*;
(
   // ----------------------------------------------------------------
   // Clock / Reset
   // ----------------------------------------------------------------
   input wire          ps_wizard_0_pl0_ref_clk,
   input wire [0:0]    proc_sys_reset_0_peripheral_aresetn,

`ifdef QDMA_PERIPH_AXI_BIND
   // ----------------------------------------------------------------
   // s_axi_mem — qdma_s_axi_mem_*
   // ----------------------------------------------------------------
   // Write address channel
   input wire [63:0]   qdma_s_axi_mem_AWADDR,
   input wire [1:0]    qdma_s_axi_mem_AWBURST,
   input wire [3:0]    qdma_s_axi_mem_AWCACHE,
   input wire [1:0]    qdma_s_axi_mem_AWID,
   input wire [7:0]    qdma_s_axi_mem_AWLEN,
   input wire [0:0]    qdma_s_axi_mem_AWLOCK,
   input wire [2:0]    qdma_s_axi_mem_AWPROT,
   input wire [3:0]    qdma_s_axi_mem_AWQOS,
   input wire          qdma_s_axi_mem_AWREADY,
   input wire [2:0]    qdma_s_axi_mem_AWSIZE,
   input wire [17:0]   qdma_s_axi_mem_AWUSER,
   input wire [0:0]    qdma_s_axi_mem_AWVALID,
   // Write data channel
   input wire [127:0]  qdma_s_axi_mem_WDATA,
   input wire [0:0]    qdma_s_axi_mem_WLAST,
   input wire          qdma_s_axi_mem_WREADY,
   input wire [15:0]   qdma_s_axi_mem_WSTRB,
   input wire [0:0]    qdma_s_axi_mem_WVALID,
   // Write response channel
   input wire [1:0]    qdma_s_axi_mem_BID,
   input wire [0:0]    qdma_s_axi_mem_BREADY,
   input wire [1:0]    qdma_s_axi_mem_BRESP,
   input wire          qdma_s_axi_mem_BVALID,
   // Read address channel
   input wire [63:0]   qdma_s_axi_mem_ARADDR,
   input wire [1:0]    qdma_s_axi_mem_ARBURST,
   input wire [3:0]    qdma_s_axi_mem_ARCACHE,
   input wire [1:0]    qdma_s_axi_mem_ARID,
   input wire [7:0]    qdma_s_axi_mem_ARLEN,
   input wire [0:0]    qdma_s_axi_mem_ARLOCK,
   input wire [2:0]    qdma_s_axi_mem_ARPROT,
   input wire [3:0]    qdma_s_axi_mem_ARQOS,
   input wire          qdma_s_axi_mem_ARREADY,
   input wire [2:0]    qdma_s_axi_mem_ARSIZE,
   input wire [17:0]   qdma_s_axi_mem_ARUSER,
   input wire [0:0]    qdma_s_axi_mem_ARVALID,
   // Read data channel
   input wire [127:0]  qdma_s_axi_mem_RDATA,
   input wire [1:0]    qdma_s_axi_mem_RID,
   input wire          qdma_s_axi_mem_RLAST,
   input wire [0:0]    qdma_s_axi_mem_RREADY,
   input wire [1:0]    qdma_s_axi_mem_RRESP,
   input wire          qdma_s_axi_mem_RVALID,

   // ----------------------------------------------------------------
   // s_axi_reg — qdma_s_axi_reg_*
   // Note: No AWID/ARID wires (tied to constants at this wire scope)
   // ----------------------------------------------------------------
   // Write address channel
   input wire [42:0]   qdma_s_axi_reg_AWADDR,
   input wire [1:0]    qdma_s_axi_reg_AWBURST,
   input wire [3:0]    qdma_s_axi_reg_AWCACHE,
   input wire [7:0]    qdma_s_axi_reg_AWLEN,
   input wire [0:0]    qdma_s_axi_reg_AWLOCK,
   input wire [2:0]    qdma_s_axi_reg_AWPROT,
   input wire [3:0]    qdma_s_axi_reg_AWQOS,
   input wire          qdma_s_axi_reg_AWREADY,
   input wire [2:0]    qdma_s_axi_reg_AWSIZE,
   input wire [146:0]  qdma_s_axi_reg_AWUSER,
   input wire          qdma_s_axi_reg_AWVALID,
   // Write data channel
   input wire [31:0]   qdma_s_axi_reg_WDATA,
   input wire          qdma_s_axi_reg_WLAST,
   input wire          qdma_s_axi_reg_WREADY,
   input wire [3:0]    qdma_s_axi_reg_WSTRB,
   input wire          qdma_s_axi_reg_WVALID,
   // Write response channel
   input wire          qdma_s_axi_reg_BREADY,
   input wire [1:0]    qdma_s_axi_reg_BRESP,
`ifdef ENABLE_AXI_REG_BUSER_BIND
   // BUSER preserved here for re-enablement: dropped from this project's wires
   // when the BD topology was updated; re-enable via +define+ENABLE_AXI_REG_BUSER_BIND
   // when the BD restores the qdma_s_axi_reg BUSER sideband.
   input wire [2:0]    qdma_s_axi_reg_BUSER,
`endif
   input wire          qdma_s_axi_reg_BVALID,
   // Read address channel
   input wire [42:0]   qdma_s_axi_reg_ARADDR,
   input wire [1:0]    qdma_s_axi_reg_ARBURST,
   input wire [3:0]    qdma_s_axi_reg_ARCACHE,
   input wire [7:0]    qdma_s_axi_reg_ARLEN,
   input wire [0:0]    qdma_s_axi_reg_ARLOCK,
   input wire [2:0]    qdma_s_axi_reg_ARPROT,
   input wire [3:0]    qdma_s_axi_reg_ARQOS,
   input wire          qdma_s_axi_reg_ARREADY,
   input wire [2:0]    qdma_s_axi_reg_ARSIZE,
   input wire [55:0]   qdma_s_axi_reg_ARUSER,
   input wire          qdma_s_axi_reg_ARVALID,
   // Read data channel
   input wire [31:0]   qdma_s_axi_reg_RDATA,
   input wire          qdma_s_axi_reg_RLAST,
   input wire          qdma_s_axi_reg_RREADY,
   input wire [1:0]    qdma_s_axi_reg_RRESP,
   input wire          qdma_s_axi_reg_RVALID,

   // ----------------------------------------------------------------
   // m_axil_dbi — qdma_M_AXIL_DBI_*
   // ----------------------------------------------------------------
   // Write address channel
   input wire [31:0]   qdma_M_AXIL_DBI_AWADDR,
   input wire [2:0]    qdma_M_AXIL_DBI_AWPROT,
   input wire          qdma_M_AXIL_DBI_AWREADY,
   input wire [15:0]   qdma_M_AXIL_DBI_AWUSER,
   input wire          qdma_M_AXIL_DBI_AWVALID,
   // Write data channel
   input wire [31:0]   qdma_M_AXIL_DBI_WDATA,
   input wire          qdma_M_AXIL_DBI_WREADY,
   input wire [3:0]    qdma_M_AXIL_DBI_WSTRB,
   input wire [3:0]    qdma_M_AXIL_DBI_WUSER,
   input wire          qdma_M_AXIL_DBI_WVALID,
   // Write response channel
   input wire          qdma_M_AXIL_DBI_BREADY,
   input wire [1:0]    qdma_M_AXIL_DBI_BRESP,
   input wire          qdma_M_AXIL_DBI_BVALID,
   // Read address channel
   input wire [31:0]   qdma_M_AXIL_DBI_ARADDR,
   input wire [2:0]    qdma_M_AXIL_DBI_ARPROT,
   input wire          qdma_M_AXIL_DBI_ARREADY,
   input wire [15:0]   qdma_M_AXIL_DBI_ARUSER,
   input wire          qdma_M_AXIL_DBI_ARVALID,
   // Read data channel
   input wire [31:0]   qdma_M_AXIL_DBI_RDATA,
   input wire          qdma_M_AXIL_DBI_RREADY,
   input wire [1:0]    qdma_M_AXIL_DBI_RRESP,
   input wire [3:0]    qdma_M_AXIL_DBI_RUSER,
   input wire          qdma_M_AXIL_DBI_RVALID,
`endif // QDMA_PERIPH_AXI_BIND

   // ----------------------------------------------------------------
   // MSIX — cpm6_qdma_0_PCIE_MSIX_*
   // ----------------------------------------------------------------
   input wire          cpm6_qdma_0_PCIE_MSIX_error,
   input wire [2:0]    cpm6_qdma_0_PCIE_MSIX_func_num,
   input wire          cpm6_qdma_0_PCIE_MSIX_grant,
   input wire [1:0]    cpm6_qdma_0_PCIE_MSIX_operation,
   input wire          cpm6_qdma_0_PCIE_MSIX_req,
   input wire [10:0]   cpm6_qdma_0_PCIE_MSIX_vector_num,
   input wire          cpm6_qdma_0_PCIE_MSIX_vfunc_active,
   input wire [7:0]    cpm6_qdma_0_PCIE_MSIX_vfunc_num
);
   `include "uvm_macros.svh"

   // ----------------------------------------------------------------
   // Interface instantiation and signal connections
   // ----------------------------------------------------------------
   qdma_periph_if qdma_periph_if_inst ();

   // --- Clock / Reset ---
   assign qdma_periph_if_inst.clk   = ps_wizard_0_pl0_ref_clk;
   assign qdma_periph_if_inst.rst_n = proc_sys_reset_0_peripheral_aresetn;

`ifdef QDMA_PERIPH_AXI_BIND
   // --- s_axi_mem write address channel ---
   assign qdma_periph_if_inst.mem_awaddr  = qdma_s_axi_mem_AWADDR;
   assign qdma_periph_if_inst.mem_awburst = qdma_s_axi_mem_AWBURST;
   assign qdma_periph_if_inst.mem_awcache = qdma_s_axi_mem_AWCACHE;
   assign qdma_periph_if_inst.mem_awid    = qdma_s_axi_mem_AWID;
   assign qdma_periph_if_inst.mem_awlen   = qdma_s_axi_mem_AWLEN;
   assign qdma_periph_if_inst.mem_awlock  = qdma_s_axi_mem_AWLOCK;
   assign qdma_periph_if_inst.mem_awprot  = qdma_s_axi_mem_AWPROT;
   assign qdma_periph_if_inst.mem_awqos   = qdma_s_axi_mem_AWQOS;
   assign qdma_periph_if_inst.mem_awready = qdma_s_axi_mem_AWREADY;
   assign qdma_periph_if_inst.mem_awsize  = qdma_s_axi_mem_AWSIZE;
   assign qdma_periph_if_inst.mem_awuser  = qdma_s_axi_mem_AWUSER;
   assign qdma_periph_if_inst.mem_awvalid = qdma_s_axi_mem_AWVALID;
   // --- s_axi_mem write data channel ---
   assign qdma_periph_if_inst.mem_wdata   = qdma_s_axi_mem_WDATA;
   assign qdma_periph_if_inst.mem_wlast   = qdma_s_axi_mem_WLAST;
   assign qdma_periph_if_inst.mem_wready  = qdma_s_axi_mem_WREADY;
   assign qdma_periph_if_inst.mem_wstrb   = qdma_s_axi_mem_WSTRB;
   assign qdma_periph_if_inst.mem_wvalid  = qdma_s_axi_mem_WVALID;
   // --- s_axi_mem write response channel ---
   assign qdma_periph_if_inst.mem_bid     = qdma_s_axi_mem_BID;
   assign qdma_periph_if_inst.mem_bready  = qdma_s_axi_mem_BREADY;
   assign qdma_periph_if_inst.mem_bresp   = qdma_s_axi_mem_BRESP;
   assign qdma_periph_if_inst.mem_bvalid  = qdma_s_axi_mem_BVALID;
   // --- s_axi_mem read address channel ---
   assign qdma_periph_if_inst.mem_araddr  = qdma_s_axi_mem_ARADDR;
   assign qdma_periph_if_inst.mem_arburst = qdma_s_axi_mem_ARBURST;
   assign qdma_periph_if_inst.mem_arcache = qdma_s_axi_mem_ARCACHE;
   assign qdma_periph_if_inst.mem_arid    = qdma_s_axi_mem_ARID;
   assign qdma_periph_if_inst.mem_arlen   = qdma_s_axi_mem_ARLEN;
   assign qdma_periph_if_inst.mem_arlock  = qdma_s_axi_mem_ARLOCK;
   assign qdma_periph_if_inst.mem_arprot  = qdma_s_axi_mem_ARPROT;
   assign qdma_periph_if_inst.mem_arqos   = qdma_s_axi_mem_ARQOS;
   assign qdma_periph_if_inst.mem_arready = qdma_s_axi_mem_ARREADY;
   assign qdma_periph_if_inst.mem_arsize  = qdma_s_axi_mem_ARSIZE;
   assign qdma_periph_if_inst.mem_aruser  = qdma_s_axi_mem_ARUSER;
   assign qdma_periph_if_inst.mem_arvalid = qdma_s_axi_mem_ARVALID;
   // --- s_axi_mem read data channel ---
   assign qdma_periph_if_inst.mem_rdata   = qdma_s_axi_mem_RDATA;
   assign qdma_periph_if_inst.mem_rid     = qdma_s_axi_mem_RID;
   assign qdma_periph_if_inst.mem_rlast   = qdma_s_axi_mem_RLAST;
   assign qdma_periph_if_inst.mem_rready  = qdma_s_axi_mem_RREADY;
   assign qdma_periph_if_inst.mem_rresp   = qdma_s_axi_mem_RRESP;
   assign qdma_periph_if_inst.mem_rvalid  = qdma_s_axi_mem_RVALID;

   // --- s_axi_reg write address channel ---
   assign qdma_periph_if_inst.reg_awaddr  = qdma_s_axi_reg_AWADDR;
   assign qdma_periph_if_inst.reg_awburst = qdma_s_axi_reg_AWBURST;
   assign qdma_periph_if_inst.reg_awcache = qdma_s_axi_reg_AWCACHE;
   assign qdma_periph_if_inst.reg_awlen   = qdma_s_axi_reg_AWLEN;
   assign qdma_periph_if_inst.reg_awlock  = qdma_s_axi_reg_AWLOCK;
   assign qdma_periph_if_inst.reg_awprot  = qdma_s_axi_reg_AWPROT;
   assign qdma_periph_if_inst.reg_awqos   = qdma_s_axi_reg_AWQOS;
   assign qdma_periph_if_inst.reg_awready = qdma_s_axi_reg_AWREADY;
   assign qdma_periph_if_inst.reg_awsize  = qdma_s_axi_reg_AWSIZE;
   assign qdma_periph_if_inst.reg_awuser  = qdma_s_axi_reg_AWUSER;
   assign qdma_periph_if_inst.reg_awvalid = qdma_s_axi_reg_AWVALID;
   // --- s_axi_reg write data channel ---
   assign qdma_periph_if_inst.reg_wdata   = qdma_s_axi_reg_WDATA;
   assign qdma_periph_if_inst.reg_wlast   = qdma_s_axi_reg_WLAST;
   assign qdma_periph_if_inst.reg_wready  = qdma_s_axi_reg_WREADY;
   assign qdma_periph_if_inst.reg_wstrb   = qdma_s_axi_reg_WSTRB;
   assign qdma_periph_if_inst.reg_wvalid  = qdma_s_axi_reg_WVALID;
   // --- s_axi_reg write response channel ---
   assign qdma_periph_if_inst.reg_bready  = qdma_s_axi_reg_BREADY;
   assign qdma_periph_if_inst.reg_bresp   = qdma_s_axi_reg_BRESP;
`ifdef ENABLE_AXI_REG_BUSER_BIND
   assign qdma_periph_if_inst.reg_buser   = qdma_s_axi_reg_BUSER;
`else
   assign qdma_periph_if_inst.reg_buser   = '0;
`endif
   assign qdma_periph_if_inst.reg_bvalid  = qdma_s_axi_reg_BVALID;
   // --- s_axi_reg read address channel ---
   assign qdma_periph_if_inst.reg_araddr  = qdma_s_axi_reg_ARADDR;
   assign qdma_periph_if_inst.reg_arburst = qdma_s_axi_reg_ARBURST;
   assign qdma_periph_if_inst.reg_arcache = qdma_s_axi_reg_ARCACHE;
   assign qdma_periph_if_inst.reg_arlen   = qdma_s_axi_reg_ARLEN;
   assign qdma_periph_if_inst.reg_arlock  = qdma_s_axi_reg_ARLOCK;
   assign qdma_periph_if_inst.reg_arprot  = qdma_s_axi_reg_ARPROT;
   assign qdma_periph_if_inst.reg_arqos   = qdma_s_axi_reg_ARQOS;
   assign qdma_periph_if_inst.reg_arready = qdma_s_axi_reg_ARREADY;
   assign qdma_periph_if_inst.reg_arsize  = qdma_s_axi_reg_ARSIZE;
   assign qdma_periph_if_inst.reg_aruser  = qdma_s_axi_reg_ARUSER;
   assign qdma_periph_if_inst.reg_arvalid = qdma_s_axi_reg_ARVALID;
   // --- s_axi_reg read data channel ---
   assign qdma_periph_if_inst.reg_rdata   = qdma_s_axi_reg_RDATA;
   assign qdma_periph_if_inst.reg_rlast   = qdma_s_axi_reg_RLAST;
   assign qdma_periph_if_inst.reg_rready  = qdma_s_axi_reg_RREADY;
   assign qdma_periph_if_inst.reg_rresp   = qdma_s_axi_reg_RRESP;
   assign qdma_periph_if_inst.reg_rvalid  = qdma_s_axi_reg_RVALID;

   // --- m_axil_dbi write address channel ---
   assign qdma_periph_if_inst.dbi_awaddr  = qdma_M_AXIL_DBI_AWADDR;
   assign qdma_periph_if_inst.dbi_awprot  = qdma_M_AXIL_DBI_AWPROT;
   assign qdma_periph_if_inst.dbi_awready = qdma_M_AXIL_DBI_AWREADY;
   assign qdma_periph_if_inst.dbi_awuser  = qdma_M_AXIL_DBI_AWUSER;
   assign qdma_periph_if_inst.dbi_awvalid = qdma_M_AXIL_DBI_AWVALID;
   // --- m_axil_dbi write data channel ---
   assign qdma_periph_if_inst.dbi_wdata   = qdma_M_AXIL_DBI_WDATA;
   assign qdma_periph_if_inst.dbi_wready  = qdma_M_AXIL_DBI_WREADY;
   assign qdma_periph_if_inst.dbi_wstrb   = qdma_M_AXIL_DBI_WSTRB;
   assign qdma_periph_if_inst.dbi_wuser   = qdma_M_AXIL_DBI_WUSER;
   assign qdma_periph_if_inst.dbi_wvalid  = qdma_M_AXIL_DBI_WVALID;
   // --- m_axil_dbi write response channel ---
   assign qdma_periph_if_inst.dbi_bready  = qdma_M_AXIL_DBI_BREADY;
   assign qdma_periph_if_inst.dbi_bresp   = qdma_M_AXIL_DBI_BRESP;
   assign qdma_periph_if_inst.dbi_bvalid  = qdma_M_AXIL_DBI_BVALID;
   // --- m_axil_dbi read address channel ---
   assign qdma_periph_if_inst.dbi_araddr  = qdma_M_AXIL_DBI_ARADDR;
   assign qdma_periph_if_inst.dbi_arprot  = qdma_M_AXIL_DBI_ARPROT;
   assign qdma_periph_if_inst.dbi_arready = qdma_M_AXIL_DBI_ARREADY;
   assign qdma_periph_if_inst.dbi_aruser  = qdma_M_AXIL_DBI_ARUSER;
   assign qdma_periph_if_inst.dbi_arvalid = qdma_M_AXIL_DBI_ARVALID;
   // --- m_axil_dbi read data channel ---
   assign qdma_periph_if_inst.dbi_rdata   = qdma_M_AXIL_DBI_RDATA;
   assign qdma_periph_if_inst.dbi_rready  = qdma_M_AXIL_DBI_RREADY;
   assign qdma_periph_if_inst.dbi_rresp   = qdma_M_AXIL_DBI_RRESP;
   assign qdma_periph_if_inst.dbi_ruser   = qdma_M_AXIL_DBI_RUSER;
   assign qdma_periph_if_inst.dbi_rvalid  = qdma_M_AXIL_DBI_RVALID;
`else // QDMA_PERIPH_AXI_BIND not defined: tie all AXI interface fields to 0
   // s_axi_mem
   assign qdma_periph_if_inst.mem_awaddr  = '0;
   assign qdma_periph_if_inst.mem_awburst = '0;
   assign qdma_periph_if_inst.mem_awcache = '0;
   assign qdma_periph_if_inst.mem_awid    = '0;
   assign qdma_periph_if_inst.mem_awlen   = '0;
   assign qdma_periph_if_inst.mem_awlock  = '0;
   assign qdma_periph_if_inst.mem_awprot  = '0;
   assign qdma_periph_if_inst.mem_awqos   = '0;
   assign qdma_periph_if_inst.mem_awready = '0;
   assign qdma_periph_if_inst.mem_awsize  = '0;
   assign qdma_periph_if_inst.mem_awuser  = '0;
   assign qdma_periph_if_inst.mem_awvalid = '0;
   assign qdma_periph_if_inst.mem_wdata   = '0;
   assign qdma_periph_if_inst.mem_wlast   = '0;
   assign qdma_periph_if_inst.mem_wready  = '0;
   assign qdma_periph_if_inst.mem_wstrb   = '0;
   assign qdma_periph_if_inst.mem_wvalid  = '0;
   assign qdma_periph_if_inst.mem_bid     = '0;
   assign qdma_periph_if_inst.mem_bready  = '0;
   assign qdma_periph_if_inst.mem_bresp   = '0;
   assign qdma_periph_if_inst.mem_bvalid  = '0;
   assign qdma_periph_if_inst.mem_araddr  = '0;
   assign qdma_periph_if_inst.mem_arburst = '0;
   assign qdma_periph_if_inst.mem_arcache = '0;
   assign qdma_periph_if_inst.mem_arid    = '0;
   assign qdma_periph_if_inst.mem_arlen   = '0;
   assign qdma_periph_if_inst.mem_arlock  = '0;
   assign qdma_periph_if_inst.mem_arprot  = '0;
   assign qdma_periph_if_inst.mem_arqos   = '0;
   assign qdma_periph_if_inst.mem_arready = '0;
   assign qdma_periph_if_inst.mem_arsize  = '0;
   assign qdma_periph_if_inst.mem_aruser  = '0;
   assign qdma_periph_if_inst.mem_arvalid = '0;
   assign qdma_periph_if_inst.mem_rdata   = '0;
   assign qdma_periph_if_inst.mem_rid     = '0;
   assign qdma_periph_if_inst.mem_rlast   = '0;
   assign qdma_periph_if_inst.mem_rready  = '0;
   assign qdma_periph_if_inst.mem_rresp   = '0;
   assign qdma_periph_if_inst.mem_rvalid  = '0;
   // s_axi_reg
   assign qdma_periph_if_inst.reg_awaddr  = '0;
   assign qdma_periph_if_inst.reg_awburst = '0;
   assign qdma_periph_if_inst.reg_awcache = '0;
   assign qdma_periph_if_inst.reg_awlen   = '0;
   assign qdma_periph_if_inst.reg_awlock  = '0;
   assign qdma_periph_if_inst.reg_awprot  = '0;
   assign qdma_periph_if_inst.reg_awqos   = '0;
   assign qdma_periph_if_inst.reg_awready = '0;
   assign qdma_periph_if_inst.reg_awsize  = '0;
   assign qdma_periph_if_inst.reg_awuser  = '0;
   assign qdma_periph_if_inst.reg_awvalid = '0;
   assign qdma_periph_if_inst.reg_wdata   = '0;
   assign qdma_periph_if_inst.reg_wlast   = '0;
   assign qdma_periph_if_inst.reg_wready  = '0;
   assign qdma_periph_if_inst.reg_wstrb   = '0;
   assign qdma_periph_if_inst.reg_wvalid  = '0;
   assign qdma_periph_if_inst.reg_bready  = '0;
   assign qdma_periph_if_inst.reg_bresp   = '0;
   assign qdma_periph_if_inst.reg_buser   = '0;
   assign qdma_periph_if_inst.reg_bvalid  = '0;
   assign qdma_periph_if_inst.reg_araddr  = '0;
   assign qdma_periph_if_inst.reg_arburst = '0;
   assign qdma_periph_if_inst.reg_arcache = '0;
   assign qdma_periph_if_inst.reg_arlen   = '0;
   assign qdma_periph_if_inst.reg_arlock  = '0;
   assign qdma_periph_if_inst.reg_arprot  = '0;
   assign qdma_periph_if_inst.reg_arqos   = '0;
   assign qdma_periph_if_inst.reg_arready = '0;
   assign qdma_periph_if_inst.reg_arsize  = '0;
   assign qdma_periph_if_inst.reg_aruser  = '0;
   assign qdma_periph_if_inst.reg_arvalid = '0;
   assign qdma_periph_if_inst.reg_rdata   = '0;
   assign qdma_periph_if_inst.reg_rlast   = '0;
   assign qdma_periph_if_inst.reg_rready  = '0;
   assign qdma_periph_if_inst.reg_rresp   = '0;
   assign qdma_periph_if_inst.reg_rvalid  = '0;
   // m_axil_dbi
   assign qdma_periph_if_inst.dbi_awaddr  = '0;
   assign qdma_periph_if_inst.dbi_awprot  = '0;
   assign qdma_periph_if_inst.dbi_awready = '0;
   assign qdma_periph_if_inst.dbi_awuser  = '0;
   assign qdma_periph_if_inst.dbi_awvalid = '0;
   assign qdma_periph_if_inst.dbi_wdata   = '0;
   assign qdma_periph_if_inst.dbi_wready  = '0;
   assign qdma_periph_if_inst.dbi_wstrb   = '0;
   assign qdma_periph_if_inst.dbi_wuser   = '0;
   assign qdma_periph_if_inst.dbi_wvalid  = '0;
   assign qdma_periph_if_inst.dbi_bready  = '0;
   assign qdma_periph_if_inst.dbi_bresp   = '0;
   assign qdma_periph_if_inst.dbi_bvalid  = '0;
   assign qdma_periph_if_inst.dbi_araddr  = '0;
   assign qdma_periph_if_inst.dbi_arprot  = '0;
   assign qdma_periph_if_inst.dbi_arready = '0;
   assign qdma_periph_if_inst.dbi_aruser  = '0;
   assign qdma_periph_if_inst.dbi_arvalid = '0;
   assign qdma_periph_if_inst.dbi_rdata   = '0;
   assign qdma_periph_if_inst.dbi_rready  = '0;
   assign qdma_periph_if_inst.dbi_rresp   = '0;
   assign qdma_periph_if_inst.dbi_ruser   = '0;
   assign qdma_periph_if_inst.dbi_rvalid  = '0;
`endif // QDMA_PERIPH_AXI_BIND

   // --- MSIX ---
   assign qdma_periph_if_inst.msix_error        = cpm6_qdma_0_PCIE_MSIX_error;
   assign qdma_periph_if_inst.msix_func_num     = cpm6_qdma_0_PCIE_MSIX_func_num;
   assign qdma_periph_if_inst.msix_grant        = cpm6_qdma_0_PCIE_MSIX_grant;
   assign qdma_periph_if_inst.msix_operation    = cpm6_qdma_0_PCIE_MSIX_operation;
   assign qdma_periph_if_inst.msix_req          = cpm6_qdma_0_PCIE_MSIX_req;
   assign qdma_periph_if_inst.msix_vector_num   = cpm6_qdma_0_PCIE_MSIX_vector_num;
   assign qdma_periph_if_inst.msix_vfunc_active = cpm6_qdma_0_PCIE_MSIX_vfunc_active;
   assign qdma_periph_if_inst.msix_vfunc_num    = cpm6_qdma_0_PCIE_MSIX_vfunc_num;

   // ----------------------------------------------------------------
   // Config DB and debug probe
   // ----------------------------------------------------------------
   initial begin
      uvm_pkg::uvm_config_db#(virtual qdma_periph_if)::set(
         null, "*", "vif_qdma_periph", qdma_periph_if_inst);
      $display("[BIND_DBG] %0t bind_qdma_periph: instantiated, config_db set", $time);
      #1;
      // [DBGFIX 0624] disabled - port idents unresolvable in initial block under bind(.*), broke elaboration
      // $display("[BIND_DBG] %0t bind_qdma_periph: clk=%b rst_n=%b mem_awvalid=%b reg_awvalid=%b (X=port not connected)",
               // $time, ps_wizard_0_pl0_ref_clk,
               // proc_sys_reset_0_peripheral_aresetn,
               // qdma_s_axi_mem_AWVALID,
               // qdma_s_axi_reg_AWVALID);
   end

endmodule : bind_qdma_periph
`default_nettype none

bind cpm6_qdma bind_qdma_periph bind_qdma_periph_inst (.*);
