// ==============================================================================
// AXI4 Interface Definition for CPM AXI PL Ports
// ==============================================================================
// This interface defines the AXI4 full protocol signals for the cpm_axi_pl
// ports on the ps_wizard_0 instance.
//
// Signal widths match the ps_wizard_0 cpm_axi_pl ports:
//   - Data Width: 512 bits
//   - Address Width: 51 bits
//   - ID Width: 10 bits
// ==============================================================================

`timescale 1ps/1ps

interface axi_if #(
    parameter int DATA_WIDTH = 512,
    parameter int ADDR_WIDTH = 51,
    parameter int ID_WIDTH = 10,
    parameter int ARUSER_WIDTH = 46,
    parameter int AWUSER_WIDTH = 137,
    parameter int RUSER_WIDTH = 128,
    parameter int WUSER_WIDTH = 64,
    parameter int BUSER_WIDTH = 3,
    parameter int STRB_WIDTH = DATA_WIDTH/8  // 64 bytes
)(
    input logic aclk,
    input logic aresetn
);

    // ========================================================================
    // Write Address Channel
    // ========================================================================
    logic [ID_WIDTH-1:0]     awid;
    logic [ADDR_WIDTH-1:0]   awaddr;
    logic [7:0]              awlen;      // Burst length
    logic [2:0]              awsize;     // Burst size
    logic [1:0]              awburst;    // Burst type
    logic                    awlock;     // Lock type
    logic [3:0]              awcache;    // Cache type
    logic [2:0]              awprot;     // Protection type
    logic [3:0]              awqos;      // QoS
    logic [AWUSER_WIDTH-1:0] awuser;     // User signal
    logic                    awvalid;    // Write address valid
    logic                    awready;    // Write address ready

    // ========================================================================
    // Write Data Channel
    // ========================================================================
    logic [DATA_WIDTH-1:0]   wdata;
    logic [STRB_WIDTH-1:0]   wstrb;      // Write strobe
    logic                    wlast;      // Write last
    logic [WUSER_WIDTH-1:0]  wuser;      // User signal
    logic                    wvalid;     // Write data valid
    logic                    wready;     // Write data ready

    // ========================================================================
    // Write Response Channel
    // ========================================================================
    logic [ID_WIDTH-1:0]     bid;
    logic [1:0]              bresp;      // Write response
    logic [BUSER_WIDTH-1:0]  buser;      // User signal
    logic                    bvalid;     // Write response valid
    logic                    bready;     // Write response ready

    // ========================================================================
    // Read Address Channel
    // ========================================================================
    logic [ID_WIDTH-1:0]     arid;
    logic [ADDR_WIDTH-1:0]   araddr;
    logic [7:0]              arlen;      // Burst length
    logic [2:0]              arsize;     // Burst size
    logic [1:0]              arburst;    // Burst type
    logic                    arlock;     // Lock type
    logic [3:0]              arcache;    // Cache type
    logic [2:0]              arprot;     // Protection type
    logic [3:0]              arqos;      // QoS
    logic [ARUSER_WIDTH-1:0] aruser;     // User signal
    logic                    arvalid;    // Read address valid
    logic                    arready;    // Read address ready

    // ========================================================================
    // Read Data Channel
    // ========================================================================
    logic [ID_WIDTH-1:0]     rid;
    logic [DATA_WIDTH-1:0]   rdata;
    logic [1:0]              rresp;      // Read response
    logic                    rlast;      // Read last
    logic [RUSER_WIDTH-1:0]  ruser;      // User signal
    logic                    rvalid;     // Read data valid
    logic                    rready;     // Read data ready

    // ========================================================================
    // Clocking Blocks for Synchronous Operation
    // ========================================================================

`ifdef AXI_IF_ENABLE_ACTIVE_DRIVERS
    // Optional active clocking blocks. Disabled by default so passive bind
    // monitors can structurally drive the interface without clocking-block
    // output drivers creating ICPSD warnings during elaboration.
    clocking master_cb @(posedge aclk);
        default input #1ps output #1ps;

        // Outputs from master
        output awid, awaddr, awlen, awsize, awburst, awlock, awcache;
        output awprot, awqos, awuser, awvalid;
        output wdata, wstrb, wlast, wuser, wvalid;
        output bready;
        output arid, araddr, arlen, arsize, arburst, arlock, arcache;
        output arprot, arqos, aruser, arvalid;
        output rready;

        // Inputs to master
        input awready;
        input wready;
        input bid, bresp, buser, bvalid;
        input arready;
        input rid, rdata, rresp, rlast, ruser, rvalid;
    endclocking

    clocking slave_cb @(posedge aclk);
        default input #1ps output #1ps;

        // Inputs to slave
        input awid, awaddr, awlen, awsize, awburst, awlock, awcache;
        input awprot, awqos, awuser, awvalid;
        input wdata, wstrb, wlast, wuser, wvalid;
        input bready;
        input arid, araddr, arlen, arsize, arburst, arlock, arcache;
        input arprot, arqos, aruser, arvalid;
        input rready;

        // Outputs from slave
        output awready;
        output wready;
        output bid, bresp, buser, bvalid;
        output arready;
        output rid, rdata, rresp, rlast, ruser, rvalid;
    endclocking
`endif

    // Monitor clocking block - for passive monitoring
    clocking monitor_cb @(posedge aclk);
        default input #1ps;

        input awid, awaddr, awlen, awsize, awburst, awlock, awcache;
        input awprot, awqos, awuser, awvalid, awready;
        input wdata, wstrb, wlast, wuser, wvalid, wready;
        input bid, bresp, buser, bvalid, bready;
        input arid, araddr, arlen, arsize, arburst, arlock, arcache;
        input arprot, arqos, aruser, arvalid, arready;
        input rid, rdata, rresp, rlast, ruser, rvalid, rready;
    endclocking

    // ========================================================================
    // Modports
    // ========================================================================

`ifdef AXI_IF_ENABLE_ACTIVE_DRIVERS
    modport master (
        clocking master_cb,
        input aclk, aresetn
    );

    modport slave (
        clocking slave_cb,
        input aclk, aresetn
    );
`endif

    modport monitor (
        clocking monitor_cb,
        input aclk, aresetn,
        input awid, awaddr, awlen, awsize, awburst, awlock, awcache,
        input awprot, awqos, awuser, awvalid, awready,
        input wdata, wstrb, wlast, wuser, wvalid, wready,
        input bid, bresp, buser, bvalid, bready,
        input arid, araddr, arlen, arsize, arburst, arlock, arcache,
        input arprot, arqos, aruser, arvalid, arready,
        input rid, rdata, rresp, rlast, ruser, rvalid, rready
    );

    // ========================================================================
    // Assertions for Protocol Checking
    // ========================================================================

    // Check that valid doesn't drop before ready (handshake protocol)
    property p_awvalid_stable;
        @(posedge aclk) disable iff (!aresetn)
        (awvalid && !awready) |=> awvalid;
    endproperty

    property p_wvalid_stable;
        @(posedge aclk) disable iff (!aresetn)
        (wvalid && !wready) |=> wvalid;
    endproperty

    property p_arvalid_stable;
        @(posedge aclk) disable iff (!aresetn)
        (arvalid && !arready) |=> arvalid;
    endproperty

    // Check that wlast aligns with awlen
    // This is a simplified check - full checking would track IDs

    assert_awvalid_stable: assert property (p_awvalid_stable)
        else $error("[AXI Protocol] AWVALID dropped before AWREADY");

    assert_wvalid_stable: assert property (p_wvalid_stable)
        else $error("[AXI Protocol] WVALID dropped before WREADY");

    assert_arvalid_stable: assert property (p_arvalid_stable)
        else $error("[AXI Protocol] ARVALID dropped before ARREADY");

endinterface : axi_if
