`ifndef PCIE4_IF_AXIS_RQ_PCIE_PORT
`define PCIE4_IF_AXIS_RQ_PCIE_PORT 1
`timescale 1 ps / 1 ps
interface pciea_port_axis_rq_if();

  wire [511:0]         axis_rq_tdata;
  wire                 axis_rq_tlast; // gate 'b0
  wire [136:0]         axis_rq_tuser;
  wire [15:0]          axis_rq_tkeep; // gate 'b0
  wire                 axis_rq_tvalid; // gate 'b0
  wire [3:0]           axis_rq_tready;

  modport s (

    input              axis_rq_tdata
   ,input              axis_rq_tlast
   ,input              axis_rq_tuser
   ,input              axis_rq_tkeep
   ,input              axis_rq_tvalid
   ,output             axis_rq_tready

  );

  modport m (

    output             axis_rq_tdata
   ,output             axis_rq_tlast
   ,output             axis_rq_tuser
   ,output             axis_rq_tkeep
   ,output             axis_rq_tvalid
   ,input              axis_rq_tready

  );

endinterface : pciea_port_axis_rq_if
`endif // PCIE4_IF_AXIS_RQ_PCIE_PORT

`ifndef PCIE4_IF_AXIS_CC_PCIE_PORT
`define PCIE4_IF_AXIS_CC_PCIE_PORT 1
interface pciea_port_axis_cc_if();

  wire [511:0]         axis_cc_tdata;
  wire [80:0]          axis_cc_tuser;
  wire                 axis_cc_tlast; // gate 'b0
  wire [15:0]          axis_cc_tkeep; // gate 'b0
  wire                 axis_cc_tvalid; // gate 'b0
  wire [3:0]           axis_cc_tready;

  modport s (
    
    input              axis_cc_tdata
   ,input              axis_cc_tuser
   ,input              axis_cc_tlast
   ,input              axis_cc_tkeep
   ,input              axis_cc_tvalid
   ,output             axis_cc_tready

  );

  modport m (

    output             axis_cc_tdata
   ,output             axis_cc_tuser
   ,output             axis_cc_tlast
   ,output             axis_cc_tkeep
   ,output             axis_cc_tvalid
   ,input              axis_cc_tready

  );
  
endinterface : pciea_port_axis_cc_if
`endif // PCIE4_IF_AXIS_CC_PCIE_PORT

`ifndef PCIE4_IF_AXIS_EXT_CQ_PCIE_PORT
`define PCIE4_IF_AXIS_EXT_CQ_PCIE_PORT 1
interface pciea_port_axis_ext_cq_if();

  logic [511:0]        axis_cq_tdata;
  logic [228:0]        axis_cq_tuser;
  logic                axis_cq_tlast;
  logic [15:0]         axis_cq_tkeep;
  logic                axis_cq_tvalid;
  logic                axis_cq_credit;
  
  modport m (

    output             axis_cq_tdata 
   ,output             axis_cq_tuser 
   ,output             axis_cq_tlast 
   ,output             axis_cq_tkeep 
   ,output             axis_cq_tvalid 
   ,input              axis_cq_credit
  
  );

  modport s (

    input              axis_cq_tdata 
   ,input              axis_cq_tuser 
   ,input              axis_cq_tlast 
   ,input              axis_cq_tkeep 
   ,input              axis_cq_tvalid 
   ,output             axis_cq_credit
  
  );

endinterface : pciea_port_axis_ext_cq_if
`endif // PCIE4_IF_AXIS_EXT_CQ_PCIE_PORT

`ifndef PCIE4_IF_AXIS_EXT_RC_PCIE_PORT
`define PCIE4_IF_AXIS_EXT_RC_PCIE_PORT 1
interface pciea_port_axis_ext_rc_if();

  logic [511:0]        axis_rc_tdata;
  logic                axis_rc_tlast;
  logic [160:0]        axis_rc_tuser;
  logic [15:0]         axis_rc_tkeep;
  logic                axis_rc_tvalid;
  logic                axis_rc_credit;

  modport m (
 
     output            axis_rc_tdata
    ,output            axis_rc_tlast
    ,output            axis_rc_tuser
    ,output            axis_rc_tkeep
    ,output            axis_rc_tvalid
    ,input             axis_rc_credit

  ); 

  modport s (
 
     input             axis_rc_tdata
    ,input             axis_rc_tlast
    ,input             axis_rc_tuser
    ,input             axis_rc_tkeep
    ,input             axis_rc_tvalid
    ,output            axis_rc_credit

  ); 

endinterface : pciea_port_axis_ext_rc_if
`endif // PCIE4_IF_AXIS_EXT_RC_PCIE_PORT
