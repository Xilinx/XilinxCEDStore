// bind.axi_pl.sv — Bind AXI-PL passive monitor interfaces to BD wires
//
// Bound to the BD module (`CPM6_BD_TOP_MODULE) by type.  Uses wire names
// declared at the BD module scope (ps_wizard_0_cpm_axi_pl*_<SIGNAL>) — no
// SecureIP internal path traversal required.
//
// All BD wires are declared as input ports so that the bind statement's
// (.*) connects them via standard port resolution (IEEE 1800-2017 section
// 23.3.2), avoiding any dependency on VCS XMRE wire merge across library
// boundaries.
//
// Ports bound:
//   PL0 (37 signals): AW/W/B/AR/R standard AXI4 — no QoS or user sideband
//   PL1 (37 signals): same as PL0
//   PL3 (43 signals, ENABLE_PL3_BIND only): AW/W/B/AR/R + AWQOS, ARQOS,
//                     AWUSER[146:0], ARUSER[55:0], WUSER[63:0], BUSER[2:0], RUSER[127:0]
//
// Config DB keys registered (all paths "*"):
//   "vif_axi_pl0"  — axi_if for cpm_axi_pl0
//   "vif_axi_pl1"  — axi_if for cpm_axi_pl1
//   "vif_axi_pl3"  — axi_if for cpm_axi_pl3
//
// Clock:  ps_wizard_0_pl0_ref_clk (249.997 MHz, shared aclk0/aclk1)
// Reset:  PL0/PL1 use `CPM6_BD_PERIPH_RESETN, so AXI assertions
//         (disable iff(!aresetn)) and monitor burst tracking start clean after
//         it. PL3 stays tied to 1'b1.

`include "qdma_bd_names.svh"
`default_nettype wire
module bind_axi_pl
  import uvm_pkg::*;
(
  // Clock
  input wire        ps_wizard_0_pl0_ref_clk,

  // Reset of the PL-side AXI peripherals (connected by name through .*)
  input wire        proc_sys_reset_0_peripheral_aresetn,

  // PL0/PL1 user sidebands. The BD leaves these ps_wizard_0 output ports
  // unconnected, so they are tapped from the instance ports in the bind
  // statement below. [31:24] carries the HDMA channel tag, which lets the
  // monitor attribute every PL0/PL1 burst to its HDMA channel.
  input wire [55:0]  pl0_aruser_tap,
  input wire [146:0] pl0_awuser_tap,
  input wire [55:0]  pl1_aruser_tap,
  input wire [146:0] pl1_awuser_tap,

  // AXI PL0
  input wire [9:0]  ps_wizard_0_cpm_axi_pl0_AWID,
  input wire [50:0] ps_wizard_0_cpm_axi_pl0_AWADDR,
  input wire [7:0]  ps_wizard_0_cpm_axi_pl0_AWLEN,
  input wire [2:0]  ps_wizard_0_cpm_axi_pl0_AWSIZE,
  input wire [1:0]  ps_wizard_0_cpm_axi_pl0_AWBURST,
  input wire        ps_wizard_0_cpm_axi_pl0_AWLOCK,
  input wire [3:0]  ps_wizard_0_cpm_axi_pl0_AWCACHE,
  input wire [2:0]  ps_wizard_0_cpm_axi_pl0_AWPROT,
  input wire        ps_wizard_0_cpm_axi_pl0_AWVALID,
  input wire        ps_wizard_0_cpm_axi_pl0_AWREADY,
  input wire [511:0] ps_wizard_0_cpm_axi_pl0_WDATA,
  input wire [63:0] ps_wizard_0_cpm_axi_pl0_WSTRB,
  input wire        ps_wizard_0_cpm_axi_pl0_WLAST,
  input wire        ps_wizard_0_cpm_axi_pl0_WVALID,
  input wire        ps_wizard_0_cpm_axi_pl0_WREADY,
  input wire [9:0]  ps_wizard_0_cpm_axi_pl0_BID,
  input wire [1:0]  ps_wizard_0_cpm_axi_pl0_BRESP,
  input wire        ps_wizard_0_cpm_axi_pl0_BVALID,
  input wire        ps_wizard_0_cpm_axi_pl0_BREADY,
  input wire [9:0]  ps_wizard_0_cpm_axi_pl0_ARID,
  input wire [50:0] ps_wizard_0_cpm_axi_pl0_ARADDR,
  input wire [7:0]  ps_wizard_0_cpm_axi_pl0_ARLEN,
  input wire [2:0]  ps_wizard_0_cpm_axi_pl0_ARSIZE,
  input wire [1:0]  ps_wizard_0_cpm_axi_pl0_ARBURST,
  input wire        ps_wizard_0_cpm_axi_pl0_ARLOCK,
  input wire [3:0]  ps_wizard_0_cpm_axi_pl0_ARCACHE,
  input wire [2:0]  ps_wizard_0_cpm_axi_pl0_ARPROT,
  input wire        ps_wizard_0_cpm_axi_pl0_ARVALID,
  input wire        ps_wizard_0_cpm_axi_pl0_ARREADY,
  input wire [9:0]  ps_wizard_0_cpm_axi_pl0_RID,
  input wire [511:0] ps_wizard_0_cpm_axi_pl0_RDATA,
  input wire [1:0]  ps_wizard_0_cpm_axi_pl0_RRESP,
  input wire        ps_wizard_0_cpm_axi_pl0_RLAST,
  input wire        ps_wizard_0_cpm_axi_pl0_RVALID,
  input wire        ps_wizard_0_cpm_axi_pl0_RREADY,

  // AXI PL1
  input wire [9:0]  ps_wizard_0_cpm_axi_pl1_AWID,
  input wire [50:0] ps_wizard_0_cpm_axi_pl1_AWADDR,
  input wire [7:0]  ps_wizard_0_cpm_axi_pl1_AWLEN,
  input wire [2:0]  ps_wizard_0_cpm_axi_pl1_AWSIZE,
  input wire [1:0]  ps_wizard_0_cpm_axi_pl1_AWBURST,
  input wire        ps_wizard_0_cpm_axi_pl1_AWLOCK,
  input wire [3:0]  ps_wizard_0_cpm_axi_pl1_AWCACHE,
  input wire [2:0]  ps_wizard_0_cpm_axi_pl1_AWPROT,
  input wire        ps_wizard_0_cpm_axi_pl1_AWVALID,
  input wire        ps_wizard_0_cpm_axi_pl1_AWREADY,
  input wire [511:0] ps_wizard_0_cpm_axi_pl1_WDATA,
  input wire [63:0] ps_wizard_0_cpm_axi_pl1_WSTRB,
  input wire        ps_wizard_0_cpm_axi_pl1_WLAST,
  input wire        ps_wizard_0_cpm_axi_pl1_WVALID,
  input wire        ps_wizard_0_cpm_axi_pl1_WREADY,
  input wire [9:0]  ps_wizard_0_cpm_axi_pl1_BID,
  input wire [1:0]  ps_wizard_0_cpm_axi_pl1_BRESP,
  input wire        ps_wizard_0_cpm_axi_pl1_BVALID,
  input wire        ps_wizard_0_cpm_axi_pl1_BREADY,
  input wire [9:0]  ps_wizard_0_cpm_axi_pl1_ARID,
  input wire [50:0] ps_wizard_0_cpm_axi_pl1_ARADDR,
  input wire [7:0]  ps_wizard_0_cpm_axi_pl1_ARLEN,
  input wire [2:0]  ps_wizard_0_cpm_axi_pl1_ARSIZE,
  input wire [1:0]  ps_wizard_0_cpm_axi_pl1_ARBURST,
  input wire        ps_wizard_0_cpm_axi_pl1_ARLOCK,
  input wire [3:0]  ps_wizard_0_cpm_axi_pl1_ARCACHE,
  input wire [2:0]  ps_wizard_0_cpm_axi_pl1_ARPROT,
  input wire        ps_wizard_0_cpm_axi_pl1_ARVALID,
  input wire        ps_wizard_0_cpm_axi_pl1_ARREADY,
  input wire [9:0]  ps_wizard_0_cpm_axi_pl1_RID,
  input wire [511:0] ps_wizard_0_cpm_axi_pl1_RDATA,
  input wire [1:0]  ps_wizard_0_cpm_axi_pl1_RRESP,
  input wire        ps_wizard_0_cpm_axi_pl1_RLAST,
  input wire        ps_wizard_0_cpm_axi_pl1_RVALID,
  input wire        ps_wizard_0_cpm_axi_pl1_RREADY

`ifdef ENABLE_PL3_BIND
  // AXI PL3 (with QoS and user sideband) — gated by ENABLE_PL3_BIND, which
  // this testbench does not define.
  ,
  input wire [9:0]   ps_wizard_0_cpm_axi_pl3_AWID,
  input wire [50:0]  ps_wizard_0_cpm_axi_pl3_AWADDR,
  input wire [7:0]   ps_wizard_0_cpm_axi_pl3_AWLEN,
  input wire [2:0]   ps_wizard_0_cpm_axi_pl3_AWSIZE,
  input wire [1:0]   ps_wizard_0_cpm_axi_pl3_AWBURST,
  input wire         ps_wizard_0_cpm_axi_pl3_AWLOCK,
  input wire [3:0]   ps_wizard_0_cpm_axi_pl3_AWCACHE,
  input wire [2:0]   ps_wizard_0_cpm_axi_pl3_AWPROT,
  input wire [3:0]   ps_wizard_0_cpm_axi_pl3_AWQOS,
  input wire [146:0] ps_wizard_0_cpm_axi_pl3_AWUSER,
  input wire         ps_wizard_0_cpm_axi_pl3_AWVALID,
  input wire         ps_wizard_0_cpm_axi_pl3_AWREADY,
  input wire [511:0] ps_wizard_0_cpm_axi_pl3_WDATA,
  input wire [63:0]  ps_wizard_0_cpm_axi_pl3_WSTRB,
  input wire         ps_wizard_0_cpm_axi_pl3_WLAST,
  input wire [63:0]  ps_wizard_0_cpm_axi_pl3_WUSER,
  input wire         ps_wizard_0_cpm_axi_pl3_WVALID,
  input wire         ps_wizard_0_cpm_axi_pl3_WREADY,
  input wire [9:0]   ps_wizard_0_cpm_axi_pl3_BID,
  input wire [1:0]   ps_wizard_0_cpm_axi_pl3_BRESP,
  input wire [2:0]   ps_wizard_0_cpm_axi_pl3_BUSER,
  input wire         ps_wizard_0_cpm_axi_pl3_BVALID,
  input wire         ps_wizard_0_cpm_axi_pl3_BREADY,
  input wire [9:0]   ps_wizard_0_cpm_axi_pl3_ARID,
  input wire [50:0]  ps_wizard_0_cpm_axi_pl3_ARADDR,
  input wire [7:0]   ps_wizard_0_cpm_axi_pl3_ARLEN,
  input wire [2:0]   ps_wizard_0_cpm_axi_pl3_ARSIZE,
  input wire [1:0]   ps_wizard_0_cpm_axi_pl3_ARBURST,
  input wire         ps_wizard_0_cpm_axi_pl3_ARLOCK,
  input wire [3:0]   ps_wizard_0_cpm_axi_pl3_ARCACHE,
  input wire [2:0]   ps_wizard_0_cpm_axi_pl3_ARPROT,
  input wire [3:0]   ps_wizard_0_cpm_axi_pl3_ARQOS,
  input wire [55:0]  ps_wizard_0_cpm_axi_pl3_ARUSER,
  input wire         ps_wizard_0_cpm_axi_pl3_ARVALID,
  input wire         ps_wizard_0_cpm_axi_pl3_ARREADY,
  input wire [9:0]   ps_wizard_0_cpm_axi_pl3_RID,
  input wire [511:0] ps_wizard_0_cpm_axi_pl3_RDATA,
  input wire [1:0]   ps_wizard_0_cpm_axi_pl3_RRESP,
  input wire         ps_wizard_0_cpm_axi_pl3_RLAST,
  input wire [127:0] ps_wizard_0_cpm_axi_pl3_RUSER,
  input wire         ps_wizard_0_cpm_axi_pl3_RVALID,
  input wire         ps_wizard_0_cpm_axi_pl3_RREADY
`endif
);
  `include "uvm_macros.svh"

  // ----------------------------------------------------------------
  // PL0 — cpm_axi_pl0  (no QoS/user at BD wire level)
  // ----------------------------------------------------------------
  axi_if #(
    .DATA_WIDTH   (512),
    .ADDR_WIDTH   (51),
    .ID_WIDTH     (10),
    .ARUSER_WIDTH (56),
    .AWUSER_WIDTH (147),
    .RUSER_WIDTH  (128),
    .WUSER_WIDTH  (64),
    .BUSER_WIDTH  (3)
  ) axi_pl0_vif (
    .aclk   (ps_wizard_0_pl0_ref_clk),
    .aresetn(proc_sys_reset_0_peripheral_aresetn)
  );

  // Write address channel
  assign axi_pl0_vif.awid    = ps_wizard_0_cpm_axi_pl0_AWID;
  assign axi_pl0_vif.awaddr  = ps_wizard_0_cpm_axi_pl0_AWADDR;
  assign axi_pl0_vif.awlen   = ps_wizard_0_cpm_axi_pl0_AWLEN;
  assign axi_pl0_vif.awsize  = ps_wizard_0_cpm_axi_pl0_AWSIZE;
  assign axi_pl0_vif.awburst = ps_wizard_0_cpm_axi_pl0_AWBURST;
  assign axi_pl0_vif.awlock  = ps_wizard_0_cpm_axi_pl0_AWLOCK;
  assign axi_pl0_vif.awcache = ps_wizard_0_cpm_axi_pl0_AWCACHE;
  assign axi_pl0_vif.awprot  = ps_wizard_0_cpm_axi_pl0_AWPROT;
  assign axi_pl0_vif.awqos   = 4'b0;   // not wired at BD scope
  assign axi_pl0_vif.awuser  = pl0_awuser_tap;
  assign axi_pl0_vif.awvalid = ps_wizard_0_cpm_axi_pl0_AWVALID;
  assign axi_pl0_vif.awready = ps_wizard_0_cpm_axi_pl0_AWREADY;
  // Write data channel
  assign axi_pl0_vif.wdata   = ps_wizard_0_cpm_axi_pl0_WDATA;
  assign axi_pl0_vif.wstrb   = ps_wizard_0_cpm_axi_pl0_WSTRB;
  assign axi_pl0_vif.wlast   = ps_wizard_0_cpm_axi_pl0_WLAST;
  assign axi_pl0_vif.wuser   = '0;
  assign axi_pl0_vif.wvalid  = ps_wizard_0_cpm_axi_pl0_WVALID;
  assign axi_pl0_vif.wready  = ps_wizard_0_cpm_axi_pl0_WREADY;
  // Write response channel
  assign axi_pl0_vif.bid     = ps_wizard_0_cpm_axi_pl0_BID;
  assign axi_pl0_vif.bresp   = ps_wizard_0_cpm_axi_pl0_BRESP;
  assign axi_pl0_vif.buser   = '0;
  assign axi_pl0_vif.bvalid  = ps_wizard_0_cpm_axi_pl0_BVALID;
  assign axi_pl0_vif.bready  = ps_wizard_0_cpm_axi_pl0_BREADY;
  // Read address channel
  assign axi_pl0_vif.arid    = ps_wizard_0_cpm_axi_pl0_ARID;
  assign axi_pl0_vif.araddr  = ps_wizard_0_cpm_axi_pl0_ARADDR;
  assign axi_pl0_vif.arlen   = ps_wizard_0_cpm_axi_pl0_ARLEN;
  assign axi_pl0_vif.arsize  = ps_wizard_0_cpm_axi_pl0_ARSIZE;
  assign axi_pl0_vif.arburst = ps_wizard_0_cpm_axi_pl0_ARBURST;
  assign axi_pl0_vif.arlock  = ps_wizard_0_cpm_axi_pl0_ARLOCK;
  assign axi_pl0_vif.arcache = ps_wizard_0_cpm_axi_pl0_ARCACHE;
  assign axi_pl0_vif.arprot  = ps_wizard_0_cpm_axi_pl0_ARPROT;
  assign axi_pl0_vif.arqos   = 4'b0;
  assign axi_pl0_vif.aruser  = pl0_aruser_tap;
  assign axi_pl0_vif.arvalid = ps_wizard_0_cpm_axi_pl0_ARVALID;
  assign axi_pl0_vif.arready = ps_wizard_0_cpm_axi_pl0_ARREADY;
  // Read data channel
  assign axi_pl0_vif.rid     = ps_wizard_0_cpm_axi_pl0_RID;
  assign axi_pl0_vif.rdata   = ps_wizard_0_cpm_axi_pl0_RDATA;
  assign axi_pl0_vif.rresp   = ps_wizard_0_cpm_axi_pl0_RRESP;
  assign axi_pl0_vif.rlast   = ps_wizard_0_cpm_axi_pl0_RLAST;
  assign axi_pl0_vif.ruser   = '0;
  assign axi_pl0_vif.rvalid  = ps_wizard_0_cpm_axi_pl0_RVALID;
  assign axi_pl0_vif.rready  = ps_wizard_0_cpm_axi_pl0_RREADY;

  // ----------------------------------------------------------------
  // PL1 — cpm_axi_pl1  (same structure as PL0)
  // ----------------------------------------------------------------
  axi_if #(
    .DATA_WIDTH   (512),
    .ADDR_WIDTH   (51),
    .ID_WIDTH     (10),
    .ARUSER_WIDTH (56),
    .AWUSER_WIDTH (147),
    .RUSER_WIDTH  (128),
    .WUSER_WIDTH  (64),
    .BUSER_WIDTH  (3)
  ) axi_pl1_vif (
    .aclk   (ps_wizard_0_pl0_ref_clk),
    .aresetn(proc_sys_reset_0_peripheral_aresetn)
  );

  assign axi_pl1_vif.awid    = ps_wizard_0_cpm_axi_pl1_AWID;
  assign axi_pl1_vif.awaddr  = ps_wizard_0_cpm_axi_pl1_AWADDR;
  assign axi_pl1_vif.awlen   = ps_wizard_0_cpm_axi_pl1_AWLEN;
  assign axi_pl1_vif.awsize  = ps_wizard_0_cpm_axi_pl1_AWSIZE;
  assign axi_pl1_vif.awburst = ps_wizard_0_cpm_axi_pl1_AWBURST;
  assign axi_pl1_vif.awlock  = ps_wizard_0_cpm_axi_pl1_AWLOCK;
  assign axi_pl1_vif.awcache = ps_wizard_0_cpm_axi_pl1_AWCACHE;
  assign axi_pl1_vif.awprot  = ps_wizard_0_cpm_axi_pl1_AWPROT;
  assign axi_pl1_vif.awqos   = 4'b0;
  assign axi_pl1_vif.awuser  = pl1_awuser_tap;
  assign axi_pl1_vif.awvalid = ps_wizard_0_cpm_axi_pl1_AWVALID;
  assign axi_pl1_vif.awready = ps_wizard_0_cpm_axi_pl1_AWREADY;
  assign axi_pl1_vif.wdata   = ps_wizard_0_cpm_axi_pl1_WDATA;
  assign axi_pl1_vif.wstrb   = ps_wizard_0_cpm_axi_pl1_WSTRB;
  assign axi_pl1_vif.wlast   = ps_wizard_0_cpm_axi_pl1_WLAST;
  assign axi_pl1_vif.wuser   = '0;
  assign axi_pl1_vif.wvalid  = ps_wizard_0_cpm_axi_pl1_WVALID;
  assign axi_pl1_vif.wready  = ps_wizard_0_cpm_axi_pl1_WREADY;
  assign axi_pl1_vif.bid     = ps_wizard_0_cpm_axi_pl1_BID;
  assign axi_pl1_vif.bresp   = ps_wizard_0_cpm_axi_pl1_BRESP;
  assign axi_pl1_vif.buser   = '0;
  assign axi_pl1_vif.bvalid  = ps_wizard_0_cpm_axi_pl1_BVALID;
  assign axi_pl1_vif.bready  = ps_wizard_0_cpm_axi_pl1_BREADY;
  assign axi_pl1_vif.arid    = ps_wizard_0_cpm_axi_pl1_ARID;
  assign axi_pl1_vif.araddr  = ps_wizard_0_cpm_axi_pl1_ARADDR;
  assign axi_pl1_vif.arlen   = ps_wizard_0_cpm_axi_pl1_ARLEN;
  assign axi_pl1_vif.arsize  = ps_wizard_0_cpm_axi_pl1_ARSIZE;
  assign axi_pl1_vif.arburst = ps_wizard_0_cpm_axi_pl1_ARBURST;
  assign axi_pl1_vif.arlock  = ps_wizard_0_cpm_axi_pl1_ARLOCK;
  assign axi_pl1_vif.arcache = ps_wizard_0_cpm_axi_pl1_ARCACHE;
  assign axi_pl1_vif.arprot  = ps_wizard_0_cpm_axi_pl1_ARPROT;
  assign axi_pl1_vif.arqos   = 4'b0;
  assign axi_pl1_vif.aruser  = pl1_aruser_tap;
  assign axi_pl1_vif.arvalid = ps_wizard_0_cpm_axi_pl1_ARVALID;
  assign axi_pl1_vif.arready = ps_wizard_0_cpm_axi_pl1_ARREADY;
  assign axi_pl1_vif.rid     = ps_wizard_0_cpm_axi_pl1_RID;
  assign axi_pl1_vif.rdata   = ps_wizard_0_cpm_axi_pl1_RDATA;
  assign axi_pl1_vif.rresp   = ps_wizard_0_cpm_axi_pl1_RRESP;
  assign axi_pl1_vif.rlast   = ps_wizard_0_cpm_axi_pl1_RLAST;
  assign axi_pl1_vif.ruser   = '0;
  assign axi_pl1_vif.rvalid  = ps_wizard_0_cpm_axi_pl1_RVALID;
  assign axi_pl1_vif.rready  = ps_wizard_0_cpm_axi_pl1_RREADY;

`ifdef ENABLE_PL3_BIND
  // ----------------------------------------------------------------
  // PL3 — cpm_axi_pl3  (full sideband: QoS + user signals wired)
  // Gated by ENABLE_PL3_BIND.
  // ----------------------------------------------------------------
  axi_if #(
    .DATA_WIDTH   (512),
    .ADDR_WIDTH   (51),
    .ID_WIDTH     (10),
    .ARUSER_WIDTH (56),
    .AWUSER_WIDTH (147),
    .RUSER_WIDTH  (128),
    .WUSER_WIDTH  (64),
    .BUSER_WIDTH  (3)
  ) axi_pl3_vif (
    .aclk   (ps_wizard_0_pl0_ref_clk),
    .aresetn(1'b1)
  );

  assign axi_pl3_vif.awid    = ps_wizard_0_cpm_axi_pl3_AWID;
  assign axi_pl3_vif.awaddr  = ps_wizard_0_cpm_axi_pl3_AWADDR;
  assign axi_pl3_vif.awlen   = ps_wizard_0_cpm_axi_pl3_AWLEN;
  assign axi_pl3_vif.awsize  = ps_wizard_0_cpm_axi_pl3_AWSIZE;
  assign axi_pl3_vif.awburst = ps_wizard_0_cpm_axi_pl3_AWBURST;
  assign axi_pl3_vif.awlock  = ps_wizard_0_cpm_axi_pl3_AWLOCK;
  assign axi_pl3_vif.awcache = ps_wizard_0_cpm_axi_pl3_AWCACHE;
  assign axi_pl3_vif.awprot  = ps_wizard_0_cpm_axi_pl3_AWPROT;
  assign axi_pl3_vif.awqos   = ps_wizard_0_cpm_axi_pl3_AWQOS;
  assign axi_pl3_vif.awuser  = ps_wizard_0_cpm_axi_pl3_AWUSER;
  assign axi_pl3_vif.awvalid = ps_wizard_0_cpm_axi_pl3_AWVALID;
  assign axi_pl3_vif.awready = ps_wizard_0_cpm_axi_pl3_AWREADY;
  assign axi_pl3_vif.wdata   = ps_wizard_0_cpm_axi_pl3_WDATA;
  assign axi_pl3_vif.wstrb   = ps_wizard_0_cpm_axi_pl3_WSTRB;
  assign axi_pl3_vif.wlast   = ps_wizard_0_cpm_axi_pl3_WLAST;
  assign axi_pl3_vif.wuser   = ps_wizard_0_cpm_axi_pl3_WUSER;
  assign axi_pl3_vif.wvalid  = ps_wizard_0_cpm_axi_pl3_WVALID;
  assign axi_pl3_vif.wready  = ps_wizard_0_cpm_axi_pl3_WREADY;
  assign axi_pl3_vif.bid     = ps_wizard_0_cpm_axi_pl3_BID;
  assign axi_pl3_vif.bresp   = ps_wizard_0_cpm_axi_pl3_BRESP;
  assign axi_pl3_vif.buser   = ps_wizard_0_cpm_axi_pl3_BUSER;
  assign axi_pl3_vif.bvalid  = ps_wizard_0_cpm_axi_pl3_BVALID;
  assign axi_pl3_vif.bready  = ps_wizard_0_cpm_axi_pl3_BREADY;
  assign axi_pl3_vif.arid    = ps_wizard_0_cpm_axi_pl3_ARID;
  assign axi_pl3_vif.araddr  = ps_wizard_0_cpm_axi_pl3_ARADDR;
  assign axi_pl3_vif.arlen   = ps_wizard_0_cpm_axi_pl3_ARLEN;
  assign axi_pl3_vif.arsize  = ps_wizard_0_cpm_axi_pl3_ARSIZE;
  assign axi_pl3_vif.arburst = ps_wizard_0_cpm_axi_pl3_ARBURST;
  assign axi_pl3_vif.arlock  = ps_wizard_0_cpm_axi_pl3_ARLOCK;
  assign axi_pl3_vif.arcache = ps_wizard_0_cpm_axi_pl3_ARCACHE;
  assign axi_pl3_vif.arprot  = ps_wizard_0_cpm_axi_pl3_ARPROT;
  assign axi_pl3_vif.arqos   = ps_wizard_0_cpm_axi_pl3_ARQOS;
  assign axi_pl3_vif.aruser  = ps_wizard_0_cpm_axi_pl3_ARUSER;
  assign axi_pl3_vif.arvalid = ps_wizard_0_cpm_axi_pl3_ARVALID;
  assign axi_pl3_vif.arready = ps_wizard_0_cpm_axi_pl3_ARREADY;
  assign axi_pl3_vif.rid     = ps_wizard_0_cpm_axi_pl3_RID;
  assign axi_pl3_vif.rdata   = ps_wizard_0_cpm_axi_pl3_RDATA;
  assign axi_pl3_vif.rresp   = ps_wizard_0_cpm_axi_pl3_RRESP;
  assign axi_pl3_vif.rlast   = ps_wizard_0_cpm_axi_pl3_RLAST;
  assign axi_pl3_vif.ruser   = ps_wizard_0_cpm_axi_pl3_RUSER;
  assign axi_pl3_vif.rvalid  = ps_wizard_0_cpm_axi_pl3_RVALID;
  assign axi_pl3_vif.rready  = ps_wizard_0_cpm_axi_pl3_RREADY;
`endif  // ENABLE_PL3_BIND

  // ----------------------------------------------------------------
  // Register interfaces in UVM config DB
  // ----------------------------------------------------------------
  initial begin
    uvm_pkg::uvm_config_db#(virtual axi_if)::set(null, "*", "vif_axi_pl0", axi_pl0_vif);
    uvm_pkg::uvm_config_db#(virtual axi_if)::set(null, "*", "vif_axi_pl1", axi_pl1_vif);
`ifdef ENABLE_PL3_BIND
    uvm_pkg::uvm_config_db#(virtual axi_if)::set(null, "*", "vif_axi_pl3", axi_pl3_vif);
`endif
  end

endmodule : bind_axi_pl
`default_nettype none

bind `CPM6_BD_TOP_MODULE bind_axi_pl bind_axi_pl_inst (
  .*,
  .proc_sys_reset_0_peripheral_aresetn (`CPM6_BD_PERIPH_RESETN),
  .pl0_aruser_tap (ps_wizard_0.cpm_axi_pl0_aruser),
  .pl0_awuser_tap (ps_wizard_0.cpm_axi_pl0_awuser),
  .pl1_aruser_tap (ps_wizard_0.cpm_axi_pl1_aruser),
  .pl1_awuser_tap (ps_wizard_0.cpm_axi_pl1_awuser)
);
