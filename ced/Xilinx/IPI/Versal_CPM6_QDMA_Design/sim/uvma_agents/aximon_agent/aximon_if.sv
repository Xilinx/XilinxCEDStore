interface aximon_if #(
  parameter ADDR_WIDTH   = 64,
  parameter DATA_WIDTH   = 1024,
  parameter ID_WIDTH     = 16,
  parameter AWUSER_WIDTH = 512,
  parameter ARUSER_WIDTH = 512,
  parameter RUSER_WIDTH  = 512,
  parameter WUSER_WIDTH  = 512,
  parameter BUSER_WIDTH  = 512
);

wire                       clk;

logic [ADDR_WIDTH-1:0]     araddr;
logic [1:0]                arburst;
logic [3:0]                arcache;
logic [ID_WIDTH-1:0]       arid;
logic [7:0]                arlen;
logic                      arlock;
logic [2:0]                arprot;
logic [3:0]                arqos;
logic [2:0]                arsize;
logic [ARUSER_WIDTH-1:0]   aruser;
logic                      arvalid;
logic                      arready;

logic [ADDR_WIDTH-1:0]     awaddr;
logic [1:0]                awburst;
logic [3:0]                awcache;
logic [ID_WIDTH-1:0]       awid;
logic [7:0]                awlen;
logic                      awlock;
logic [2:0]                awprot;
logic [3:0]                awqos;
logic [2:0]                awsize;
logic [AWUSER_WIDTH-1:0]   awuser;
logic                      awvalid;
logic                      awready;

logic [DATA_WIDTH-1:0]     wdata;
logic                      wlast;
logic [DATA_WIDTH/8-1:0]   wstrb;
logic                      wvalid;
logic [WUSER_WIDTH-1:0]    wuser;
logic                      wready;

logic                      bready;
logic                      bvalid;
logic [BUSER_WIDTH-1:0]    buser;
logic [1:0]                bresp;
logic [ID_WIDTH-1:0]       bid;

logic                      rready;
logic [DATA_WIDTH-1:0]     rdata;
logic [ID_WIDTH-1:0]       rid;
logic                      rlast;
logic [1:0]                rresp;
logic                      rvalid;
logic [RUSER_WIDTH-1:0]    ruser;

modport M (
  output araddr,
  output arburst,
  output arcache,
  output arid,
  output arlen,
  output arlock,
  output arprot,
  output arqos,
  output arsize,
  output aruser,
  output arvalid,
  input  arready,

  output awaddr,
  output awburst,
  output awcache,
  output awid,
  output awlen,
  output awlock,
  output awprot,
  output awqos,
  output awsize,
  output awuser,
  output awvalid,
  input  awready,

  output wdata,
  output wlast,
  output wstrb,
  output wvalid,
  output wuser,
  input  wready,

  output bready,
  input  bvalid,
  input  bresp,
  input  bid,
  input  buser,

  output rready,
  input  rdata,
  input  rid,
  input  rlast,
  input  rresp,
  input  rvalid,
  input  ruser
);

modport S (
  input  araddr,
  input  arburst,
  input  arcache,
  input  arid,
  input  arlen,
  input  arlock,
  input  arprot,
  input  arqos,
  input  arsize,
  input  aruser,
  input  arvalid,
  output arready,

  input  awaddr,
  input  awburst,
  input  awcache,
  input  awid,
  input  awlen,
  input  awlock,
  input  awprot,
  input  awqos,
  input  awsize,
  input  awuser,
  input  awvalid,
  output awready,

  input  wdata,
  input  wlast,
  input  wstrb,
  input  wvalid,
  input  wuser,
  output wready,

  input  bready,
  output bvalid,
  output bresp,
  output bid,
  output buser,

  input  rready,
  output rdata,
  output rid,
  output rlast,
  output rresp,
  output rvalid,
  output ruser
);

clocking cb @(posedge clk);
  default input #10ps output #0ps;

  input araddr;
  input arburst;
  input arcache;
  input arid;
  input arlen;
  input arlock;
  input arprot;
  input arqos;
  input arsize;
  input aruser;
  input arvalid;
  input arready;

  input awaddr;
  input awburst;
  input awcache;
  input awid;
  input awlen;
  input awlock;
  input awprot;
  input awqos;
  input awsize;
  input awuser;
  input awvalid;
  input awready;

  input wdata;
  input wlast;
  input wstrb;
  input wvalid;
  input wuser;
  input wready;

  input bready;
  input bvalid;
  input bresp;
  input bid;
  input buser;

  input rready;
  input rdata;
  input rid;
  input rlast;
  input rresp;
  input rvalid;
  input ruser;
endclocking
endinterface