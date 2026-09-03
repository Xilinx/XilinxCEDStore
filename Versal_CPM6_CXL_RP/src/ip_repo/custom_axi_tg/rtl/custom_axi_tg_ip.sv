// MODULE : custom_axi_tg_ip
//
// DESCRIPTION:
// Packaging wrapper around custom_axi_tg.  The DUT boundary is already flat -
// there are no SystemVerilog interface ports - so this wrapper exists for one
// narrow reason: the Vivado IP Packager's port-width resolver can only
// evaluate a width that is a plain integer literal or a simple expression on a
// PARAMETER.  It cannot evaluate a localparam that is itself an expression, so
// custom_axi_tg's
//
//   localparam ID_PORT_W      = (AXI_ID_WIDTH==0) ? 1 : AXI_ID_WIDTH
//   localparam AXI_STRB_WIDTH = AXI_DATA_WIDTH/8
//
// make the packager fail on m_axi_wstrb if AXI_STRB_WIDTH were written the
// same way (it is a plain literal below instead, since AXI_DATA_WIDTH is
// fixed and never user-configurable).  The AXI ID ports below get the same
// ternary WRITTEN INLINE, directly on the parameter, rather than through an
// intermediate localparam name: the packager CAN auto-infer a dependent port
// width from a ternary on a real parameter it can see in the module's own
// port list, it just cannot chase the ternary through a second, derived
// name. (Confirmed empirically: routing the same expression through an
// intermediate `parameter int ID_PORT_W = (AXI_ID_WIDTH==0) ? 1 :
// AXI_ID_WIDTH` packages without error and looks identical in component.xml,
// but never actually re-evaluates when AXI_ID_WIDTH changes - Vivado does
// not cascade a "generated" model parameter's dependency through to the
// user-facing side automatically.  Writing the ternary inline avoids that
// dead end entirely.)
//
// DETAILS:
//  - The AXI ID ports are genuinely (AXI_ID_WIDTH==0 ? 1 : AXI_ID_WIDTH) bits
//    wide, exactly matching custom_axi_tg's own ID_PORT_W - so the packaged
//    IP's block design symbol actually resizes m_axi_awid/bid/arid/rid when
//    AXI_ID_WIDTH is changed, the same way pl_axi_cpi_bridge's AXI ID ports
//    do.
//  - Everything else is a direct 1:1 pass-through to custom_axi_tg.
//
// RESTRICTIONS:
//  - AXI_ID_WIDTH == 0 means the AXI ID is hardcoded to 0.  The ID ports
//    still exist, at 1 bit, and never carry a non-zero value.

module custom_axi_tg_ip #(
  //--- AXI master geometry -------------------------------------------------
  parameter int AXI_ADDRESS_WIDTH = 48,        // max 48
  parameter int AXI_ID_WIDTH      = 1,         // 0..4;  0 => ID hardcoded to 0
  //--- Clocking ------------------------------------------------------------
  parameter bit AXI_AXIL_SYNC     = 1'b0,      // 0 = async (CDC generated)
                                               // 1 = s_axil_aclk == m_axi_aclk
  //--- External start pin presentation --------------------------------------
  //  Packaging-only knob: gates whether i_start is shown on the packaged
  //  IP's symbol (see package_ip.tcl's enablement_dependency). Most
  //  consumers start the DUT through the AXI-Lite CSR bit and never wire
  //  this pin, so it defaults hidden. The port itself is always present
  //  below regardless of this setting; the DUT is unaffected either way.
  parameter bit EXTERNAL_START_EN = 1'b0,
  //--- LFSR implementation ---------------------------------------------------
  //  Fixed, not user-configurable: the packaged IP must not let a consumer
  //  swap in a poorly-chosen seed that biases the write byte-enable
  //  probability for tens of thousands of transactions (see the seed
  //  localparams below).
  localparam bit LFSR64_GALOIS     = 1'b1,      // 1 = Galois, 0 = Fibonacci
  localparam bit LFSR27_GALOIS     = 1'b1,
  localparam bit LFSR8_GALOIS      = 1'b1,
  //  Must be non-zero and high-entropy across the full width; a seed whose
  //  upper bits are near zero biases the write byte-enable probability for
  //  tens of thousands of transactions.
  localparam logic [63:0] LFSR64_SEED    = 64'h9E37_79B9_7F4A_7C15,
  localparam logic [26:0] LFSR27_WR_SEED = 27'h63779B9,
  localparam logic [26:0] LFSR27_RD_SEED = 27'h367AE85,
  localparam logic [ 7:0] LFSR8_WR_SEED  = 8'hB5,
  localparam logic [ 7:0] LFSR8_RD_SEED  = 8'h6D,
  //--- CAN'T TOUCH ---------------------------------------------------------
  //  Plain integer literals, NOT expressions: the IP Packager cannot evaluate
  //  a localparam defined in terms of another localparam.
  localparam int AXI_DATA_WIDTH = 512,
  localparam int AXI_STRB_WIDTH = 64,
  localparam int WUSER_WIDTH    = 33,
  localparam int BUSER_WIDTH    = 2,
  localparam int ARUSER_WIDTH   = 35,
  localparam int RUSER_WIDTH    = 34
)(
  /*** Clocks and resets - both clock pins always present ***/
  input                                m_axi_aclk,
  input                                m_axi_aresetn,   // active-low SYNC
  input                                s_axil_aclk,
  input                                s_axil_aresetn,  // active-low SYNC

  /*** External start pin (async, edge detected, 2FF sync) ***/
  input                                i_start,

  /*** Status outputs (m_axi_aclk domain) - pins AND AXI-L readable ***/
  output logic [                  2:0] o_state,
  // 6b = $clog2(MAX_COMMANDS)+1 for the DUT's fixed MAX_COMMANDS=32 (not a
  // GUI-exposed parameter). The "+1" covers fetch_ptr settling AT
  // MAX_COMMANDS once a program finishes fetching, which would otherwise
  // alias to 0. Update this literal if MAX_COMMANDS is ever changed.
  output logic [                  5:0] o_cur_cmd_ptr,
  output logic                         o_running,

  /*** AMBA AXI4 Master Port ***/
  output logic [AXI_ADDRESS_WIDTH-1:0] m_axi_awaddr,
  output logic [(AXI_ID_WIDTH == 0 ? 1 : AXI_ID_WIDTH)-1:0] m_axi_awid,
  output logic [                  2:0] m_axi_awprot,
  output logic [                  1:0] m_axi_awburst,
  output logic [                  2:0] m_axi_awsize,
  output logic [                  3:0] m_axi_awcache,
  output logic [                  7:0] m_axi_awlen,
  output logic                         m_axi_awlock,
  output logic                         m_axi_awvalid,
  input                                m_axi_awready,
  output logic [      WUSER_WIDTH-1:0] m_axi_wuser,
  output logic [   AXI_DATA_WIDTH-1:0] m_axi_wdata,
  output logic [   AXI_STRB_WIDTH-1:0] m_axi_wstrb,
  output logic                         m_axi_wlast,
  output logic                         m_axi_wvalid,
  input                                m_axi_wready,
  input        [      BUSER_WIDTH-1:0] m_axi_buser,
  input                                m_axi_bvalid,
  output logic                         m_axi_bready,
  input        [(AXI_ID_WIDTH == 0 ? 1 : AXI_ID_WIDTH)-1:0] m_axi_bid,
  input        [                  1:0] m_axi_bresp,
  output logic [     ARUSER_WIDTH-1:0] m_axi_aruser,
  output logic [AXI_ADDRESS_WIDTH-1:0] m_axi_araddr,
  output logic [(AXI_ID_WIDTH == 0 ? 1 : AXI_ID_WIDTH)-1:0] m_axi_arid,
  output logic [                  2:0] m_axi_arprot,
  output logic [                  1:0] m_axi_arburst,
  output logic [                  2:0] m_axi_arsize,
  output logic [                  3:0] m_axi_arcache,
  output logic [                  7:0] m_axi_arlen,
  output logic                         m_axi_arlock,
  output logic                         m_axi_arvalid,
  input                                m_axi_arready,
  input        [      RUSER_WIDTH-1:0] m_axi_ruser,
  input        [(AXI_ID_WIDTH == 0 ? 1 : AXI_ID_WIDTH)-1:0] m_axi_rid,
  input        [   AXI_DATA_WIDTH-1:0] m_axi_rdata,
  input        [                  1:0] m_axi_rresp,
  input                                m_axi_rvalid,
  input                                m_axi_rlast,
  output logic                         m_axi_rready,

  /*** AXI4-Lite Slave Port - programming interface ***/
  input                                s_axil_awvalid,
  output logic                         s_axil_awready,
  input        [                 15:0] s_axil_awaddr,
  input        [                  2:0] s_axil_awprot,
  input                                s_axil_wvalid,
  output logic                         s_axil_wready,
  input        [                 31:0] s_axil_wdata,
  input        [                  3:0] s_axil_wstrb,
  output logic                         s_axil_bvalid,
  input                                s_axil_bready,
  output logic [                  1:0] s_axil_bresp,
  input                                s_axil_arvalid,
  output logic                         s_axil_arready,
  input        [                 15:0] s_axil_araddr,
  input        [                  2:0] s_axil_arprot,
  output logic                         s_axil_rvalid,
  input                                s_axil_rready,
  output logic [                  1:0] s_axil_rresp,
  output logic [                 31:0] s_axil_rdata
);

  custom_axi_tg #(
    .AXI_ADDRESS_WIDTH (AXI_ADDRESS_WIDTH),
    .AXI_ID_WIDTH      (AXI_ID_WIDTH),
    .AXI_AXIL_SYNC     (AXI_AXIL_SYNC),
    .LFSR64_GALOIS     (LFSR64_GALOIS),
    .LFSR27_GALOIS     (LFSR27_GALOIS),
    .LFSR8_GALOIS      (LFSR8_GALOIS),
    .LFSR64_SEED       (LFSR64_SEED),
    .LFSR27_WR_SEED    (LFSR27_WR_SEED),
    .LFSR27_RD_SEED    (LFSR27_RD_SEED),
    .LFSR8_WR_SEED     (LFSR8_WR_SEED),
    .LFSR8_RD_SEED     (LFSR8_RD_SEED)
  ) i_custom_axi_tg (
    .m_axi_aclk     (m_axi_aclk),
    .m_axi_aresetn  (m_axi_aresetn),
    .s_axil_aclk    (s_axil_aclk),
    .s_axil_aresetn (s_axil_aresetn),
    .i_start        (i_start),
    .o_state        (o_state),
    .o_cur_cmd_ptr  (o_cur_cmd_ptr),
    .o_running      (o_running),
    .m_axi_awaddr   (m_axi_awaddr),
    .m_axi_awid     (m_axi_awid),
    .m_axi_awprot   (m_axi_awprot),
    .m_axi_awburst  (m_axi_awburst),
    .m_axi_awsize   (m_axi_awsize),
    .m_axi_awcache  (m_axi_awcache),
    .m_axi_awlen    (m_axi_awlen),
    .m_axi_awlock   (m_axi_awlock),
    .m_axi_awvalid  (m_axi_awvalid),
    .m_axi_awready  (m_axi_awready),
    .m_axi_wuser    (m_axi_wuser),
    .m_axi_wdata    (m_axi_wdata),
    .m_axi_wstrb    (m_axi_wstrb),
    .m_axi_wlast    (m_axi_wlast),
    .m_axi_wvalid   (m_axi_wvalid),
    .m_axi_wready   (m_axi_wready),
    .m_axi_buser    (m_axi_buser),
    .m_axi_bvalid   (m_axi_bvalid),
    .m_axi_bready   (m_axi_bready),
    .m_axi_bid      (m_axi_bid),
    .m_axi_bresp    (m_axi_bresp),
    .m_axi_aruser   (m_axi_aruser),
    .m_axi_araddr   (m_axi_araddr),
    .m_axi_arid     (m_axi_arid),
    .m_axi_arprot   (m_axi_arprot),
    .m_axi_arburst  (m_axi_arburst),
    .m_axi_arsize   (m_axi_arsize),
    .m_axi_arcache  (m_axi_arcache),
    .m_axi_arlen    (m_axi_arlen),
    .m_axi_arlock   (m_axi_arlock),
    .m_axi_arvalid  (m_axi_arvalid),
    .m_axi_arready  (m_axi_arready),
    .m_axi_ruser    (m_axi_ruser),
    .m_axi_rid      (m_axi_rid),
    .m_axi_rdata    (m_axi_rdata),
    .m_axi_rresp    (m_axi_rresp),
    .m_axi_rvalid   (m_axi_rvalid),
    .m_axi_rlast    (m_axi_rlast),
    .m_axi_rready   (m_axi_rready),
    .s_axil_awvalid (s_axil_awvalid),
    .s_axil_awready (s_axil_awready),
    .s_axil_awaddr  (s_axil_awaddr),
    .s_axil_awprot  (s_axil_awprot),
    .s_axil_wvalid  (s_axil_wvalid),
    .s_axil_wready  (s_axil_wready),
    .s_axil_wdata   (s_axil_wdata),
    .s_axil_wstrb   (s_axil_wstrb),
    .s_axil_bvalid  (s_axil_bvalid),
    .s_axil_bready  (s_axil_bready),
    .s_axil_bresp   (s_axil_bresp),
    .s_axil_arvalid (s_axil_arvalid),
    .s_axil_arready (s_axil_arready),
    .s_axil_araddr  (s_axil_araddr),
    .s_axil_arprot  (s_axil_arprot),
    .s_axil_rvalid  (s_axil_rvalid),
    .s_axil_rready  (s_axil_rready),
    .s_axil_rresp   (s_axil_rresp),
    .s_axil_rdata   (s_axil_rdata)
  );

endmodule
