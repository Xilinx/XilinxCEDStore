`ifndef CPM6_QDMA_INTF
`define CPM6_QDMA_INTF
interface axi4_intf #(
  parameter ADDR_WIDTH     = 64,
  parameter DATA_WIDTH     = 128,
  parameter ID_WIDTH       = 16,
  parameter REQ_USER_WIDTH = 18,
  parameter USER_WIDTH     = 17,
  parameter AXI_ID         = 0,
  parameter AXIL           = 0
);


logic [ADDR_WIDTH-1:0]     araddr;
logic [1:0]                arburst;
logic [3:0]                arcache;
logic [ID_WIDTH-1:0]       arid;
logic [7:0]                arlen;
logic                      arlock;
logic [2:0]                arprot;
logic [3:0]                arqos;
logic [2:0]                arsize;
logic [REQ_USER_WIDTH-1:0] aruser;
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
logic [REQ_USER_WIDTH-1:0] awuser;
logic                      awvalid;
logic                      awready;

logic [DATA_WIDTH-1:0]     wdata;
logic                      wlast;
logic [DATA_WIDTH/8-1:0]   wstrb;
logic                      wvalid;
logic [USER_WIDTH-1:0]     wuser;
logic                      wready;

logic                      bready;
logic                      bvalid;
logic [1:0]                bresp;
logic [ID_WIDTH:0]         bid;

logic                      rready;
logic [DATA_WIDTH-1:0]     rdata;
logic [ID_WIDTH-1:0]       rid;
logic                      rlast;
logic [1:0]                rresp;
logic                      rvalid;
logic [USER_WIDTH-1:0]     ruser;

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

  input  rready,
  output rdata,
  output rid,
  output rlast,
  output rresp,
  output rvalid,
  output ruser
);
endinterface:axi4_intf

interface axi4l_intf_def_cpm6_qdma #(parameter AXIL_ADDR_WIDTH=64, parameter AXIL_DATA_WIDTH=64, parameter AXIL_AXUSER_WIDTH=8);

logic   [AXIL_ADDR_WIDTH-1:0]   araddr;
logic                   [2:0]   arprot;
logic                           arready;
logic [AXIL_AXUSER_WIDTH-1:0]   aruser;
logic                           arvalid;
logic   [AXIL_DATA_WIDTH-1:0]   rdata;
logic                           rready;
logic                   [1:0]   rresp;
logic [AXIL_AXUSER_WIDTH-1:0]   ruser;
logic                           rvalid;
logic   [AXIL_ADDR_WIDTH-1:0]   awaddr;
logic                   [2:0]   awprot;
logic                           awready;
logic [AXIL_AXUSER_WIDTH-1:0]   awuser;
logic                           awvalid;
logic                           bready;
logic                   [1:0]   bresp;
logic [AXIL_AXUSER_WIDTH-1:0]   buser;
logic                           bvalid;
logic   [AXIL_DATA_WIDTH-1:0]   wdata;
logic [AXIL_AXUSER_WIDTH-1:0]   wuser;
logic                           wready;
logic [(AXIL_DATA_WIDTH/8)-1:0] wstrb;
logic                           wvalid;

// Master interface
modport master(
   output  araddr
  ,output  arprot
  ,input   arready
  ,output  aruser
  ,output  arvalid
  ,input   rdata
  ,output  rready
  ,input   rresp
  ,input   ruser
  ,input   rvalid
  ,output  awaddr
  ,output  awprot
  ,input   awready
  ,output  awuser
  ,output  awvalid
  ,output  bready
  ,input   bresp
  ,input   buser
  ,input   bvalid
  ,output  wdata
  ,output  wuser
  ,input   wready
  ,output  wstrb
  ,output  wvalid
);

// Slave interface
modport slave(
   input  araddr
  ,input  arprot
  ,output arready
  ,input  aruser
  ,input  arvalid
  ,output rdata
  ,input  rready
  ,output rresp
  ,output ruser
  ,output rvalid
  ,input  awaddr
  ,input  awprot
  ,output awready
  ,input  awuser
  ,input  awvalid
  ,input  bready
  ,output bresp
  ,output buser
  ,output bvalid
  ,input  wdata
  ,input  wuser
  ,output wready
  ,input  wstrb
  ,input  wvalid
);

endinterface:axi4l_intf_def_cpm6_qdma


// cpm6_qdma_dsc_byp_intf
typedef struct packed {
  logic [63:0] src_addr;
  logic [27:0] len;
  logic [35:0] rsvd0;
  logic [63:0] dst_addr;
  logic [63:0] rsvd1;
} desc_mm_fmt_t;

typedef struct packed {
  logic [31:0]  addr_h;
  logic [31:0]  addr_l;
  logic [15:0]  rsvd0;
  logic [15:0]  len;
  logic [31:0]  metadata;
  logic [127:0] rsvd1;
} desc_st_h2c_fmt_t;

typedef struct packed {
  logic [63:0]   addr;
  logic [31:0]   len; //Adding this field so ST modifier can update and pass down through desc converter
  logic [159:0]  rsvd0;
} desc_st_c2h_fmt_t;

typedef union packed {
  desc_mm_fmt_t     mm;
  desc_st_h2c_fmt_t h2c_st;
  desc_st_c2h_fmt_t c2h_st;
} desc_fmt_t;

interface cpm6_qdma_dsc_byp_intf #(
  parameter NUM_FUNCTIONS = 2048,
  parameter NUM_QUEUES    = 2048
);


desc_fmt_t    h2c_dsc;
logic         h2c_st_mm;
logic [1:0]   h2c_dsc_sz;
logic         h2c_err;
logic [15:0]  h2c_cidx;
logic [2:0]   h2c_port;
logic [2:0]   h2c_fmt;
logic         h2c_last;     // last descriptor of a fetch record
logic         h2c_vld;
logic         h2c_rdy;

logic [$clog2(NUM_QUEUES)-1:0]    h2c_qid;
logic [$clog2(NUM_FUNCTIONS)-1:0] h2c_func;

desc_fmt_t    c2h_dsc;
logic         c2h_st_mm;
logic [1:0]   c2h_dsc_sz;
logic         c2h_err;
logic [15:0]  c2h_cidx;
logic [2:0]   c2h_port;
logic [6:0]   c2h_pfch_tag;
logic [2:0]   c2h_fmt;
logic         c2h_last;     // last descriptor of a fetch record or prefetch-pool packet
logic         c2h_vld;
logic         c2h_rdy;

logic [$clog2(NUM_QUEUES)-1:0]    c2h_qid;
logic [$clog2(NUM_FUNCTIONS)-1:0] c2h_func;


logic clk;
logic rst_n;

function void default_out();
  h2c_dsc    = 0;
  h2c_st_mm  = 0;
  h2c_dsc_sz = 0;
  h2c_qid    = 0;
  h2c_err    = 0;
  h2c_func   = 0;
  h2c_cidx   = 0;
  h2c_port   = 0;
  h2c_fmt    = 0;
  h2c_last   = 0;
  h2c_vld    = 0;

  c2h_dsc    = 0;
  c2h_st_mm  = 0;
  c2h_dsc_sz = 0;
  c2h_qid    = 0;
  c2h_err    = 0;
  c2h_func   = 0;
  c2h_cidx   = 0;
  c2h_port   = 0;
  c2h_fmt    = 0;
  c2h_last   = 0;
  c2h_vld    = 0;
endfunction

modport O (
  output h2c_dsc,
  output h2c_st_mm,
  output h2c_dsc_sz,
  output h2c_qid,
  output h2c_err,
  output h2c_func,
  output h2c_cidx,
  output h2c_port,
  output h2c_fmt,
  output h2c_last,
  output h2c_vld,
  input  h2c_rdy,

  output c2h_dsc,
  output c2h_st_mm,
  output c2h_dsc_sz,
  output c2h_qid,
  output c2h_err,
  output c2h_func,
  output c2h_cidx,
  output c2h_port,
  output c2h_pfch_tag,
  output c2h_fmt,
  output c2h_last,
  output c2h_vld,
  input  c2h_rdy
);

modport I (
  input  h2c_dsc,
  input  h2c_st_mm,
  input  h2c_dsc_sz,
  input  h2c_qid,
  input  h2c_err,
  input  h2c_func,
  input  h2c_cidx,
  input  h2c_port,
  input  h2c_fmt,
  input  h2c_last,
  input  h2c_vld,
  output h2c_rdy,

  input  c2h_dsc,
  input  c2h_st_mm,
  input  c2h_dsc_sz,
  input  c2h_qid,
  input  c2h_err,
  input  c2h_func,
  input  c2h_cidx,
  input  c2h_port,
  input  c2h_pfch_tag,
  input  c2h_fmt,
  input  c2h_last,
  input  c2h_vld,
  output c2h_rdy
);

endinterface:cpm6_qdma_dsc_byp_intf
// qdma_reg_space
interface qdma_v5_0_12_dma5_mdma_dsc_hw_ctxt_ram_if();
        logic   [12:0]  wadr;
        logic           wen;
        logic   [59:0]  wdat;   //  39:32 = writeback accumulation count, 31:16 = used credits,  15:0= consumer index
        logic           ren;
        logic   [12:0]  radr;
        logic   [59:0]  rdat;
        logic           rsbe;
        logic           rdbe;
 
        modport  m (
                output  wadr,
                output  wen,
                output  wdat,
                output  ren,
                output  radr,
                input   rdat,
                input   rsbe,
                input   rdbe
         );
        modport  s (
                input   wadr,
                input   wen,
                input   wdat,
                input   ren,
                input   radr,
                output  rdat,
                output  rsbe,
                output  rdbe
         );
endinterface:qdma_v5_0_12_dma5_mdma_dsc_hw_ctxt_ram_if

interface qdma_v5_0_12_dma5_mdma_dsc_sw_ctxt_ram_if();
        logic   [12:0]  wadr; // 4048 H2C Qs, 4048 C2H Qs
        logic           wen;
        logic   [239:0] wdat;  // 15:8 func, 3:0 = sts, 63:32 = produce index, 127:64 = base address
        logic           ren;
        logic   [12:0]  radr;
        logic   [239:0] rdat;
        logic           rsbe;
        logic           rdbe;
 
        modport  m (
                output  wadr,
                output  wen,
                output  wdat,
                output  ren,
                output  radr,
                input   rdat,
                input   rsbe,
                input   rdbe
         );
        modport  s (
                input   wadr,
                input   wen,
                input   wdat,
                input   ren,
                input   radr,
                output  rdat,
                output  rsbe,
                output  rdbe
         );
endinterface:qdma_v5_0_12_dma5_mdma_dsc_sw_ctxt_ram_if

interface qdma_v5_0_12_dma5_mdma_dsc_cr_ctxt_ram_if();
        logic   [12:0]  wadr;
        logic           wen;
        logic   [15:0]  wdat;
        logic           ren;
        logic   [12:0]  radr;
        logic   [15:0]  rdat;
        logic           rsbe;
        logic           rdbe;
 
        modport  m (
                output  wadr,
                output  wen,
                output  wdat,
                output  ren,
                output  radr,
                input   rdat,
                input   rsbe,
                input   rdbe
         );
        modport  s (
                input   wadr,
                input   wen,
                input   wdat,
                input   ren,
                input   radr,
                output  rdat,
                output  rsbe,
                output  rdbe
         );
endinterface:qdma_v5_0_12_dma5_mdma_dsc_cr_ctxt_ram_if

// Prefetch context RAM, one entry per queue. Modelled on the credit-context
// interface above, which is its closest sibling.
//
// Data width is the width of mdma_wrb_c2h_pftch_ctxt_t, which the RAM instance
// sizes itself from through PFCH_CTXT_RAM_DATA_BITS. This file has no imports,
// so the number is written out; it is 46 bits and measured, not derived by
// hand. If that structure changes, this literal must change with it -- a
// mismatch shows as a width warning on the RAM connection rather than an error.
//
// The address is carried thirteen bits wide to match the sibling interfaces;
// the RAM slices it down to its own depth.
interface qdma_v5_0_12_dma5_mdma_pfch_ctxt_ram_if();
        logic   [12:0]  wadr;
        logic           wen;
        logic   [45:0]  wdat;
        logic           ren;
        logic   [12:0]  radr;
        logic   [45:0]  rdat;
        logic           rsbe;
        logic           rdbe;

        modport  m (
                output  wadr,
                output  wen,
                output  wdat,
                output  ren,
                output  radr,
                input   rdat,
                input   rsbe,
                input   rdbe
         );
        modport  s (
                input   wadr,
                input   wen,
                input   wdat,
                input   ren,
                input   radr,
                output  rdat,
                output  rsbe,
                output  rdbe
         );
endinterface:qdma_v5_0_12_dma5_mdma_pfch_ctxt_ram_if

interface qdma_v5_0_12_dma5_pcie_mi_4Bx4096_4Bwe_ram_if();
        logic   [12:0]  wadr;
        logic           wen;
        //logic   [7:0]   wpar;
        logic   [31:0]  wdat;   
        logic           ren;
        logic   [12:0]  radr;
        //logic   [7:0]   rpar;
        logic   [31:0]  rdat;
        logic           rsbe;
        logic           rdbe;
 
        modport  m (
                output  wadr,
                output  wen,
                //output  wpar,
                output  wdat,
                output  ren,
                output  radr,
                //input   rpar,
                input   rdat,
                input   rsbe,
                input   rdbe
         );
        modport  s (
                input   wadr,
                input   wen,
                //input   wpar,
                input   wdat,
                input   ren,
                input   radr,
                //output  rpar,
                output  rdat,
                output  rsbe,
                output  rdbe
         );
endinterface:qdma_v5_0_12_dma5_pcie_mi_4Bx4096_4Bwe_ram_if

interface qdma_v5_0_12_dma5_mdma_wrb_ctxt_ram_if
import cpm6_qdma_v1_0_1_pkg::*;
();

        logic   [WRB_CTXT_HARD_RAM_ADDR_BITS-1:0]   wadr;
        logic                                       wen;
        logic   [WRB_CTXT_RAM_DATA_BITS-1:0]        wdat;
        logic                                       ren;
        logic   [WRB_CTXT_HARD_RAM_ADDR_BITS-1:0]   radr;
        logic   [WRB_CTXT_RAM_DATA_BITS-1:0]        rdat;
        logic                                       rsbe;
        logic                                       rdbe;
 
        modport  m (
                output  wadr,
                output  wen,
                //output  wpar,
                output  wdat,
                output  ren,
                output  radr,
                //input   rpar,
                input   rdat,
                input   rsbe,
                input   rdbe
         );
        modport  s (
                input   wadr,
                input   wen,
                //input   wpar,
                input   wdat,
                input   ren,
                input   radr,
                //output  rpar,
                output  rdat,
                output  rsbe,
                output  rdbe
         );
endinterface:qdma_v5_0_12_dma5_mdma_wrb_ctxt_ram_if

interface qdma_v5_0_12_dma5_mdma_int_ctxt_ram_if();
        logic   [11:0]   wadr; 
        logic           wen;
//        logic   [7:0]   wpar;
        logic   [113:0]  wdat;  
        logic           ren;
        logic   [11:0]   radr;
//        logic   [7:0]   rpar;
        logic   [113:0]  rdat;
        logic           rsbe;
        logic           rdbe;
 
        modport  m (
                output  wadr,
                output  wen,
//                output  wpar,
                output  wdat,
                output  ren,
                output  radr,
//                input   rpar,
                input   rdat,
                input   rsbe,
                input   rdbe
         );
        modport  s (
                input   wadr,
                input   wen,
//                input   wpar,
                input   wdat,
                input   ren,
                input   radr,
//                output  rpar,
                output  rdat,
                output  rsbe,
                output  rdbe
         );
endinterface:qdma_v5_0_12_dma5_mdma_int_ctxt_ram_if

`endif
