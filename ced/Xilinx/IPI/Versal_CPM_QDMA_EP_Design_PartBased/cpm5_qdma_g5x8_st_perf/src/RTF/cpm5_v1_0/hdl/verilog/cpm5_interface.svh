`ifndef CPM5_IF_SV
`define CPM5_IF_SV 1

interface pciea_port_axis_rq_if();
  wire [1023:0] axis_rq_tdata;
  wire          axis_rq_tlast; // gate 'b0
  wire [372:0]  axis_rq_tuser;
  wire [31:0]   axis_rq_tkeep; // gate 'b0
  wire          axis_rq_tvalid; // gate 'b0
  wire [3:0]    axis_rq_tready;

  modport s (
    input  axis_rq_tdata,
    input  axis_rq_tlast,
    input  axis_rq_tuser,
    input  axis_rq_tkeep,
    input  axis_rq_tvalid,
    output axis_rq_tready
  );

  modport m (
    output axis_rq_tdata,
    output axis_rq_tlast,
    output axis_rq_tuser,
    output axis_rq_tkeep,
    output axis_rq_tvalid,
    input  axis_rq_tready
  );

endinterface : pciea_port_axis_rq_if

interface pciea_port_axis_cc_if();
  wire [1023:0] axis_cc_tdata;
  wire [164:0]  axis_cc_tuser;
  wire          axis_cc_tlast; // gate 'b0
  wire [31:0]   axis_cc_tkeep; // gate 'b0
  wire          axis_cc_tvalid; // gate 'b0
  wire [3:0]    axis_cc_tready;

  modport s (
    input  axis_cc_tdata,
    input  axis_cc_tuser,
    input  axis_cc_tlast,
    input  axis_cc_tkeep,
    input  axis_cc_tvalid,
    output axis_cc_tready
  );

  modport m (
    output axis_cc_tdata,
    output axis_cc_tuser,
    output axis_cc_tlast,
    output axis_cc_tkeep,
    output axis_cc_tvalid,
    input  axis_cc_tready
  );
endinterface : pciea_port_axis_cc_if

interface pciea_port_axis_ext_cq_if();

  logic [1023:0] axis_cq_tdata;
  logic [465:0]  axis_cq_tuser;
  logic          axis_cq_tlast;
  logic [31:0]   axis_cq_tkeep;
  logic          axis_cq_tvalid;
  logic          axis_cq_credit;

  modport m (
    output axis_cq_tdata,
    output axis_cq_tuser,
    output axis_cq_tlast,
    output axis_cq_tkeep,
    output axis_cq_tvalid,
    input  axis_cq_credit
  );

  modport s (
    input  axis_cq_tdata,
    input  axis_cq_tuser,
    input  axis_cq_tlast,
    input  axis_cq_tkeep,
    input  axis_cq_tvalid,
    output axis_cq_credit
  );

endinterface : pciea_port_axis_ext_cq_if

interface pciea_port_axis_ext_rc_if();
  logic [1023:0] axis_rc_tdata;
  logic          axis_rc_tlast;
  logic [336:0]  axis_rc_tuser;
  logic [31:0]   axis_rc_tkeep;
  logic          axis_rc_tvalid;
  logic          axis_rc_credit;

  modport m (
    output axis_rc_tdata,
    output axis_rc_tlast,
    output axis_rc_tuser,
    output axis_rc_tkeep,
    output axis_rc_tvalid,
    input  axis_rc_credit
  );

  modport s (
    input  axis_rc_tdata,
    input  axis_rc_tlast,
    input  axis_rc_tuser,
    input  axis_rc_tkeep,
    input  axis_rc_tvalid,
    output axis_rc_credit
  );

endinterface : pciea_port_axis_ext_rc_if

interface dma_pcie_mdma_h2c_axis_if#()();
  logic [511:0] tdata;
  logic [512/8-1:0] tparity;
  logic tlast;
  logic tvalid;
  logic [512/8-1:0] tkeep;
  logic tready;
  logic [63:0] tusr;

  modport m (
    output tdata,
    output tparity,
    output tlast,
    output tvalid,
    output tkeep,
    output tusr,
    input  tready
  );

  modport s (
    input  tdata,
    input  tparity,
    input  tlast,
    input  tvalid,
    input  tkeep,
    input  tusr,
    output tready
  );
endinterface : dma_pcie_mdma_h2c_axis_if

interface dma_pcie_mdma_c2h_axis_if
import cpm5_v1_0_14_pkg::*;
#()();
  mdma_c2h_axis_data_t data;
  mdma_c2h_axis_ctrl_t ctrl;
  logic tlast;
  logic [5:0] mty;
  logic tvalid;
  logic tready;

  modport m (
    output data,
    output ctrl,
    output tlast,
    output mty,
    output tvalid,
    input  tready
  );

  modport s (
    input  data,
    input  ctrl,
    input  tlast,
    input  mty,
    input  tvalid,
    output tready
  );
endinterface : dma_pcie_mdma_c2h_axis_if

interface dma_pcie_mdma_byp_out_if;
  logic [255:0] dsc;
  logic [15:0]  cidx;
  logic vld;
  logic rdy;

  modport m (
    output dsc,
    output cidx,
    output vld,
    input  rdy
  );

  modport s (
    input  dsc,
    input  cidx,
    input  vld,
    output rdy
  );
endinterface

interface dma_pcie_mdma_byp_in_if;
  logic [255:0] dsc;
  logic [15:0]  cidx;
  logic vld;
  logic rdy;
  modport m (
    output dsc,
    output cidx,
    output vld,
    input  rdy
  );
  modport s (
    input  dsc,
    input  cidx,
    input  vld,
    output rdy
  );
endinterface

interface dma_pcie_h2c_axis_if#()();
  logic [511:0] tdata;
  logic [512/8-1:0] tparity;
  logic tlast;
  logic tvalid;
  logic [512/8-1:0] tkeep;
  logic tready;
  logic [63:0]  tusr;

  modport m (
    output tdata,
    output tparity,
    output tlast,
    output tvalid,
    output tkeep,
    output tusr,
    input  tready
  );

  modport s (
    input  tdata,
    input  tparity,
    input  tlast,
    input  tvalid,
    input  tkeep,
    input  tusr,
    output tready
  );
endinterface : dma_pcie_h2c_axis_if

interface dma_pcie_c2h_axis_if#()();
  logic [511:0] tdata;
  logic [512/8-1:0] tparity;
  logic tlast;
  logic tvalid;
  logic [512/8-1:0] tkeep;
  logic tready;
  logic [63:0] tusr;

  modport m (
    output tdata,
    output tparity,
    output tlast,
    output tvalid,
    output tkeep,
    output tusr,
    input  tready
  );

  modport s (
    input  tdata,
    input  tparity,
    input  tlast,
    input  tvalid,
    input  tkeep,
    input  tusr,
    output tready
  );
endinterface : dma_pcie_c2h_axis_if

interface dma_pcie_byp_out_if;
  logic [255:0] dsc;
  logic [15:0] cidx;                
  logic vld;
  logic rdy;
  modport m (
    output dsc,
    output cidx,            
    output vld,
    input  rdy
  );
  modport s (
    input  dsc,
    input  cidx,            
    input  vld,
    output rdy
  );
endinterface

interface dma_pcie_byp_in_if;
  logic [255:0] dsc;
  logic [15:0] cidx;        
  logic vld;
  logic rdy;
  modport m (
    output dsc,
    output cidx,
    output vld,
    input  rdy
  );
  modport s (
    input  dsc,
    input  cidx,
    input  vld,
    output rdy
  );
endinterface

interface dma_pcie_axis_rq_if#(DATA_WIDTH = 512, USER_WIDTH = 137)();
  wire [DATA_WIDTH-1:0] tdata;
  wire tlast;
  wire [USER_WIDTH-1:0] tuser;
  wire [DATA_WIDTH/32-1:0] tkeep;
  wire tvalid;
  wire tready;

  modport s (
    input  tdata,
    input  tlast,
    input  tuser,
    input  tkeep,
    input  tvalid,
    output tready
  );

  modport m (
    output tdata,
    output tlast,
    output tuser,
    output tkeep,
    output tvalid,
    input  tready
  );

endinterface : dma_pcie_axis_rq_if

interface dma_pcie_axis_rc_if#(DATA_WIDTH = 512, USER_WIDTH = 161)();
  wire [DATA_WIDTH-1:0] tdata;
  wire tlast;
  wire [USER_WIDTH-1:0] tuser;
  wire [DATA_WIDTH/32-1:0] tkeep;
  wire tvalid;
  wire [21:0] tready;

  modport m ( 
    output tdata,
    output tlast,
    output tuser,
    output tkeep,
    output tvalid,
    input  tready
  ); 

  modport s (
    input  tdata,
    input  tlast,
    input  tuser,
    input  tkeep,
    input  tvalid,
    output tready
  ); 

endinterface : dma_pcie_axis_rc_if

interface dma_pcie_axis_cq_if#(DATA_WIDTH = 512, USER_WIDTH = 183)();
  wire [DATA_WIDTH-1:0] tdata;
  wire tlast;
  wire [USER_WIDTH-1:0] tuser;
  wire [DATA_WIDTH/32-1:0] tkeep;
  wire tvalid;
  wire [21:0] tready;
  
  modport m ( 
    output tdata,
    output tlast,
    output tuser,
    output tkeep,
    output tvalid,
    input  tready
  ); 

  modport s (
    input  tdata,
    input  tlast,
    input  tuser,
    input  tkeep,
    input  tvalid,
    output tready
  ); 

endinterface : dma_pcie_axis_cq_if

interface dma_pcie_axis_cc_if#(DATA_WIDTH = 512, USER_WIDTH = 81)();

  wire [DATA_WIDTH-1:0] tdata;
  wire tlast;
  wire [USER_WIDTH-1:0] tuser;
  wire [DATA_WIDTH/32-1:0] tkeep;
  wire tvalid;
  wire tready;

  modport s (
    input  tdata,
    input  tlast,
    input  tuser,
    input  tkeep,
    input  tvalid,
    output tready
  );

  modport m (
    output tdata,
    output tlast,
    output tuser,
    output tkeep,
    output tvalid,
    input  tready
  ); 
endinterface : dma_pcie_axis_cc_if

`endif