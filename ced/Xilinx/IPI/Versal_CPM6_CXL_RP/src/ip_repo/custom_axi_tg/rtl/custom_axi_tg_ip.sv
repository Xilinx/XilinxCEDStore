// MODULE : custom_axi_tg_ip
//
// DESCRIPTION:
// Programmable AXI4 traffic generator for flit_endec test systems using
// pl_axi_cpi_bridge. An AXI4-Lite interface loads a linear program of WRITE,
// READ and WAIT commands into instruction RAM. Independent read and write
// dispatchers issue aligned, single-beat 64-byte transactions with selectable
// address, ID, data and byte-enable patterns.
//
// DETAILS:
//  - Supports 2..512 commands, AXI addresses up to 48 bits and IDs up to 4 bits.
//  - Starts from an AXI4-Lite control write or the optional external start pin.
//  - WAIT drains preceding traffic; STOP drains outstanding transactions.
//  - Reports run state, command completion and first response errors.
//  - Supports synchronous or asynchronous AXI4-Lite and AXI master clocks.
//
// RESTRICTIONS:
//  - Transfers are 64-byte aligned and use a fixed 512-bit data bus.
//  - AXI_ID_WIDTH=0 uses one-bit ID ports with request IDs tied to zero.
//  - SAFE_ID_WIDTH is derived from AXI_ID_WIDTH and is hidden in the IP GUI.

module custom_axi_tg_ip #(
  //--- AXI master geometry -------------------------------------------------
  parameter int AXI_ADDRESS_WIDTH = 48,        // max 48
  parameter int AXI_ID_WIDTH      = 1,         // 0..4;  0 => ID hardcoded to 0
  parameter int MAX_COMMANDS      = 32,        // 2..512 instruction entries
  // DON'T TOUCH
  parameter int SAFE_ID_WIDTH     = !AXI_ID_WIDTH ? 1 : AXI_ID_WIDTH,
  //--- Clocking ------------------------------------------------------------
  parameter bit AXI_AXIL_SYNC     = 1'b0,      // 0 = async (CDC generated)
                                               // 1 = s_axil_aclk == m_axi_aclk
  //--- External start pin presentation --------------------------------------
  //  Show i_start on the block-design symbol when enabled.
  parameter bit EXTERNAL_START_EN = 1'b0,
  //--- LFSR implementation ---------------------------------------------------
  //  Fixed Galois generators and nonzero seeds for traffic patterns.
  localparam bit LFSR64_GALOIS     = 1'b1,      // 1 = Galois, 0 = Fibonacci
  localparam bit LFSR27_GALOIS     = 1'b1,
  localparam bit LFSR8_GALOIS      = 1'b1,
  //  Full-width seeds provide varied patterns from the first transaction.
  localparam logic [63:0] LFSR64_SEED    = 64'h9E37_79B9_7F4A_7C15,
  localparam logic [26:0] LFSR27_WR_SEED = 27'h63779B9,
  localparam logic [26:0] LFSR27_RD_SEED = 27'h367AE85,
  localparam logic [ 7:0] LFSR8_WR_SEED  = 8'hB5,
  localparam logic [ 7:0] LFSR8_RD_SEED  = 8'h6D,
  //--- CAN'T TOUCH ---------------------------------------------------------
  //  Fixed data and sideband widths for the bridge interface.
  localparam int AXI_DATA_WIDTH = 512,
  localparam int AXI_STRB_WIDTH = 64,
  localparam int WUSER_WIDTH    = 33,
  localparam int BUSER_WIDTH    = 2,
  localparam int ARUSER_WIDTH   = 35,
  localparam int RUSER_WIDTH    = 34
)(
  /*** Clocks and resets - both clock pins always present ***/
  input                                 m_axi_aclk,
  input                                 m_axi_aresetn,   // active-low SYNC
  input                                 s_axil_aclk,
  input                                 s_axil_aresetn,  // active-low SYNC

  /*** External start pin (async, edge detected, 2FF sync) ***/
  input                                 i_start,

  /*** Status outputs (m_axi_aclk domain) - pins AND AXI-L readable ***/
  output logic [                   2:0] o_state,
  // Inline parameter expression lets packaging track the port width.
  // Include the terminal fetch pointer: six bits at 32, ten bits at 512.
  output logic [$clog2(MAX_COMMANDS):0] o_cur_cmd_ptr,
  output logic                          o_running,

  /*** AMBA AXI4 Master Port ***/
  output logic [ AXI_ADDRESS_WIDTH-1:0] m_axi_awaddr,
  output logic [     SAFE_ID_WIDTH-1:0] m_axi_awid,
  output logic [                   2:0] m_axi_awprot,
  output logic [                   1:0] m_axi_awburst,
  output logic [                   2:0] m_axi_awsize,
  output logic [                   3:0] m_axi_awcache,
  output logic [                   7:0] m_axi_awlen,
  output logic                          m_axi_awlock,
  output logic                          m_axi_awvalid,
  input                                 m_axi_awready,
  output logic [       WUSER_WIDTH-1:0] m_axi_wuser,
  output logic [    AXI_DATA_WIDTH-1:0] m_axi_wdata,
  output logic [    AXI_STRB_WIDTH-1:0] m_axi_wstrb,
  output logic                          m_axi_wlast,
  output logic                          m_axi_wvalid,
  input                                 m_axi_wready,
  input        [       BUSER_WIDTH-1:0] m_axi_buser,
  input                                 m_axi_bvalid,
  output logic                          m_axi_bready,
  input        [     SAFE_ID_WIDTH-1:0] m_axi_bid,
  input        [                   1:0] m_axi_bresp,
  output logic [      ARUSER_WIDTH-1:0] m_axi_aruser,
  output logic [ AXI_ADDRESS_WIDTH-1:0] m_axi_araddr,
  output logic [     SAFE_ID_WIDTH-1:0] m_axi_arid,
  output logic [                   2:0] m_axi_arprot,
  output logic [                   1:0] m_axi_arburst,
  output logic [                   2:0] m_axi_arsize,
  output logic [                   3:0] m_axi_arcache,
  output logic [                   7:0] m_axi_arlen,
  output logic                          m_axi_arlock,
  output logic                          m_axi_arvalid,
  input                                 m_axi_arready,
  input        [       RUSER_WIDTH-1:0] m_axi_ruser,
  input        [     SAFE_ID_WIDTH-1:0] m_axi_rid,
  input        [    AXI_DATA_WIDTH-1:0] m_axi_rdata,
  input        [                   1:0] m_axi_rresp,
  input                                 m_axi_rvalid,
  input                                 m_axi_rlast,
  output logic                          m_axi_rready,

  /*** AXI4-Lite Slave Port - programming interface ***/
  input                                 s_axil_awvalid,
  output logic                          s_axil_awready,
  input        [                  15:0] s_axil_awaddr,
  input        [                   2:0] s_axil_awprot,
  input                                 s_axil_wvalid,
  output logic                          s_axil_wready,
  input        [                  31:0] s_axil_wdata,
  input        [                   3:0] s_axil_wstrb,
  output logic                          s_axil_bvalid,
  input                                 s_axil_bready,
  output logic [                   1:0] s_axil_bresp,
  input                                 s_axil_arvalid,
  output logic                          s_axil_arready,
  input        [                  15:0] s_axil_araddr,
  input        [                   2:0] s_axil_arprot,
  output logic                          s_axil_rvalid,
  input                                 s_axil_rready,
  output logic [                   1:0] s_axil_rresp,
  output logic [                  31:0] s_axil_rdata
);

  custom_axi_tg #(
    .AXI_ADDRESS_WIDTH (AXI_ADDRESS_WIDTH),
    .AXI_ID_WIDTH      (AXI_ID_WIDTH),
    .MAX_COMMANDS      (MAX_COMMANDS),
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
