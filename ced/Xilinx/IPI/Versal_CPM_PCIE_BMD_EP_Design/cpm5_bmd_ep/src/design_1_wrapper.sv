module design_1_wrapper (
    input        gt_refclk1_0_clk_n,
    input        gt_refclk1_0_clk_p,

    input  [7:0] PCIE1_GT_0_grx_n,
    input  [7:0] PCIE1_GT_0_grx_p,
    output [7:0] PCIE1_GT_0_gtx_n,
    output [7:0] PCIE1_GT_0_gtx_p
);

localparam AXIS_DATAW  = 512;

localparam RQ_USERW    = 183;
localparam RC_USERW    = 161;
localparam CC_USERW    = 81;
localparam CQ_USERW    = 232;

localparam RC_STRADDLE = 0;
localparam RQ_STRADDLE = 0;
localparam CC_STRADDLE = 0;
localparam CQ_STRADDLE = 0;

localparam EN_CLNT_TAG = "true";

wire [AXIS_DATAW-1:0]    m_axis_cq_tdata;
wire [AXIS_DATAW/32-1:0] m_axis_cq_tkeep;
wire                     m_axis_cq_tlast;
wire                     m_axis_cq_tready;
wire [CQ_USERW-1:0]      m_axis_cq_tuser;
wire                     m_axis_cq_tvalid;

wire [AXIS_DATAW-1:0]    m_axis_rc_tdata;
wire [AXIS_DATAW/32-1:0] m_axis_rc_tkeep;
wire                     m_axis_rc_tlast;
wire                     m_axis_rc_tready;
wire [RC_USERW-1:0]      m_axis_rc_tuser;
wire                     m_axis_rc_tvalid;

wire [AXIS_DATAW-1:0]    s_axis_cc_tdata;
wire [AXIS_DATAW/32-1:0] s_axis_cc_tkeep;
wire                     s_axis_cc_tlast;
wire                     s_axis_cc_tready;
wire [CC_USERW-1:0]      s_axis_cc_tuser;
wire                     s_axis_cc_tvalid;

wire [AXIS_DATAW-1:0]    s_axis_rq_tdata;
wire [AXIS_DATAW/32-1:0] s_axis_rq_tkeep;
wire                     s_axis_rq_tlast;
wire                     s_axis_rq_tready;
wire [CQ_USERW-1:0]      s_axis_rq_tuser;
wire                     s_axis_rq_tvalid;

wire tag_10b;

design_1 design_1_i (
  .PCIE1_GT_0_grx_n         (PCIE1_GT_0_grx_n),
  .PCIE1_GT_0_grx_p         (PCIE1_GT_0_grx_p),
  .PCIE1_GT_0_gtx_n         (PCIE1_GT_0_gtx_n),
  .PCIE1_GT_0_gtx_p         (PCIE1_GT_0_gtx_p),

  .gt_refclk1_0_clk_n       (gt_refclk1_0_clk_n),
  .gt_refclk1_0_clk_p       (gt_refclk1_0_clk_p),

  .pcie1_m_axis_cq_0_tdata  (m_axis_cq_tdata),
  .pcie1_m_axis_cq_0_tkeep  (m_axis_cq_tkeep),
  .pcie1_m_axis_cq_0_tlast  (m_axis_cq_tlast),
  .pcie1_m_axis_cq_0_tready (m_axis_cq_tready),
  .pcie1_m_axis_cq_0_tuser  (m_axis_cq_tuser),
  .pcie1_m_axis_cq_0_tvalid (m_axis_cq_tvalid),

  .pcie1_m_axis_rc_0_tdata  (m_axis_rc_tdata),
  .pcie1_m_axis_rc_0_tkeep  (m_axis_rc_tkeep),
  .pcie1_m_axis_rc_0_tlast  (m_axis_rc_tlast),
  .pcie1_m_axis_rc_0_tready (m_axis_rc_tready),
  .pcie1_m_axis_rc_0_tuser  (m_axis_rc_tuser),
  .pcie1_m_axis_rc_0_tvalid (m_axis_rc_tvalid),

  .pcie1_s_axis_cc_0_tdata  (s_axis_cc_tdata),
  .pcie1_s_axis_cc_0_tkeep  (s_axis_cc_tkeep),
  .pcie1_s_axis_cc_0_tlast  (s_axis_cc_tlast),
  .pcie1_s_axis_cc_0_tready (s_axis_cc_tready),
  .pcie1_s_axis_cc_0_tuser  (s_axis_cc_tuser),
  .pcie1_s_axis_cc_0_tvalid (s_axis_cc_tvalid),

  .pcie1_s_axis_rq_0_tdata  (s_axis_rq_tdata),
  .pcie1_s_axis_rq_0_tkeep  (s_axis_rq_tkeep),
  .pcie1_s_axis_rq_0_tlast  (s_axis_rq_tlast),
  .pcie1_s_axis_rq_0_tready (s_axis_rq_tready),
  .pcie1_s_axis_rq_0_tuser  (s_axis_rq_tuser),
  .pcie1_s_axis_rq_0_tvalid (s_axis_rq_tvalid),

  .pcie1_cfg_status_0_10b_tag_requester_enable (tag_10b),

  .pcie1_user_clk_0         (pcie1_user_clk_0),
  .pcie1_user_lnk_up_0      (pcie1_user_lnk_up_0),
  .pcie1_user_reset_0       (pcie1_user_reset_0)
);

pcie_app_versal_bmd #( 
   .C_DATA_WIDTH                 (AXIS_DATAW),
   .AXISTEN_IF_ENABLE_CLIENT_TAG (EN_CLNT_TAG),
   .AXISTEN_IF_RQ_STRADDLE       (RQ_STRADDLE),
   .AXISTEN_IF_RC_STRADDLE       (RC_STRADDLE),
   .AXISTEN_IF_CQ_STRADDLE       (CQ_STRADDLE),
   .AXISTEN_IF_CC_STRADDLE       (CC_STRADDLE),
   .AXI4_CQ_TUSER_WIDTH          (CQ_USERW),
   .AXI4_CC_TUSER_WIDTH          (CC_USERW),
   .AXI4_RQ_TUSER_WIDTH          (RQ_USERW),
   .AXI4_RC_TUSER_WIDTH          (RC_USERW)
) pcie_app_uscale_bmd_i (
  .user_clk         ( pcie1_user_clk_0),
  .user_reset       ( pcie1_user_reset_0),
  .user_lnk_up      ( pcie1_user_lnk_up_0),
  .sys_rst          ( 1'b1),

  .s_axis_rq_tlast  (s_axis_rq_tlast),
  .s_axis_rq_tdata  (s_axis_rq_tdata),
  .s_axis_rq_tuser  (s_axis_rq_tuser),
  .s_axis_rq_tkeep  (s_axis_rq_tkeep),
  .s_axis_rq_tready (s_axis_rq_tready),
  .s_axis_rq_tvalid (s_axis_rq_tvalid),

  .m_axis_rc_tdata  (m_axis_rc_tdata),
  .m_axis_rc_tuser  (m_axis_rc_tuser),
  .m_axis_rc_tlast  (m_axis_rc_tlast),
  .m_axis_rc_tkeep  (m_axis_rc_tkeep),
  .m_axis_rc_tvalid (m_axis_rc_tvalid),
  .m_axis_rc_tready (m_axis_rc_tready),

  .m_axis_cq_tdata  (m_axis_cq_tdata),
  .m_axis_cq_tuser  (m_axis_cq_tuser),
  .m_axis_cq_tlast  (m_axis_cq_tlast),
  .m_axis_cq_tkeep  (m_axis_cq_tkeep),
  .m_axis_cq_tvalid (m_axis_cq_tvalid),
  .m_axis_cq_tready (m_axis_cq_tready),

  .s_axis_cc_tdata  (s_axis_cc_tdata),
  .s_axis_cc_tuser  (s_axis_cc_tuser),
  .s_axis_cc_tlast  (s_axis_cc_tlast),
  .s_axis_cc_tkeep  (s_axis_cc_tkeep),
  .s_axis_cc_tvalid (s_axis_cc_tvalid),
  .s_axis_cc_tready (s_axis_cc_tready)
);


endmodule
