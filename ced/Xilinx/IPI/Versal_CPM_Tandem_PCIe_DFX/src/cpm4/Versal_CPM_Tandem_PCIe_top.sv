//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : The Xilinx PCI Express DMA
// File       : Versal_CPM_Tandem_PCIe_top.sv
// Version    : 5.0
//-----------------------------------------------------------------------------

`timescale 1ps / 1ps

module Versal_CPM_Tandem_PCIe_top #(
  parameter PL_LINK_CAP_MAX_LINK_WIDTH  = 8 // 1- X1; 2- X2; 4- X4; 8- X8
)(
    input  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pcie_gts_grx_p,
    input  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pcie_gts_grx_n,
    output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pcie_gts_gtx_p,
    output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pcie_gts_gtx_n,
    input                                         pcie_refclk_clk_n,
    input                                         pcie_refclk_clk_p
);
   
   //--------------------------------------------------------------------------

   localparam          TM_DSC_BITS      = 16;
   localparam          C_DATA_WIDTH_ST  = 512;
   localparam          QID_MAX          = 256;
   localparam          C_CNTR_WIDTH     = 64; // Performance counter bit width
   
   wire                              axi_aclk;
   wire                              axi_aresetn;
   wire                              soft_resetn;

   //----------------------------------------------//
   //-- AXI-L Master 
   //----------------------------------------------//
   // Write Addr Channel
   wire [41:0]                       m_axil_awaddr;
   wire [2:0]                        m_axil_awprot;
   wire                              m_axil_awvalid;
   wire                              m_axil_awready;
   // Write Data Channel
   wire [31:0]                       m_axil_wdata;
   wire [3:0]                        m_axil_wstrb;
   wire                              m_axil_wvalid;
   wire                              m_axil_wready;
   // Write Response Channel
   wire                              m_axil_bvalid;
   wire                              m_axil_bready;
   // Read Address Channel
   wire [41:0]                       m_axil_araddr;
   wire [2:0]                        m_axil_arprot;
   wire                              m_axil_arvalid;
   wire                              m_axil_arready;
   // Read Data Channel
   wire [31:0]                       m_axil_rdata;
   wire [1:0]                        m_axil_rresp;
   wire                              m_axil_rvalid;
   wire                              m_axil_rready;
   wire [1:0]                        m_axil_bresp;
   //----------------------------------------------//

   wire                              wen;
   wire [31:0]                       waddr;
   wire [31:0]                       wdata;
   wire                              ren;
   wire                              rvalid;
   wire                              rdone;
   wire [31:0]                       raddr;
   wire [31:0]                       rdata;

   // MDMA signals
   wire [C_DATA_WIDTH_ST-1:0]        m_axis_h2c_tdata;
   wire [C_DATA_WIDTH_ST/8-1:0]      m_axis_h2c_dpar;
   wire [53:0]                       m_axis_h2c_tuser; 
   wire                              m_axis_h2c_tvalid;
   wire                              m_axis_h2c_tready;
   wire                              m_axis_h2c_tlast;

   // AXIS C2H packet wire
   wire [C_DATA_WIDTH_ST-1:0]        s_axis_c2h_tdata;
   wire [C_DATA_WIDTH_ST/8-1:0]      s_axis_c2h_dpar;
   wire                              s_axis_c2h_ctrl_marker;
   wire [2:0]                        s_axis_c2h_ctrl_port_id;
   wire [15:0]                       s_axis_c2h_ctrl_len;
   wire [10:0]                       s_axis_c2h_ctrl_qid;
   wire                              s_axis_c2h_ctrl_user_trig;
   wire                              s_axis_c2h_ctrl_dis_cmpt;
   wire                              s_axis_c2h_ctrl_imm_data;
   wire                              s_axis_c2h_tvalid;
   wire                              s_axis_c2h_tready;
   wire                              s_axis_c2h_tlast;
   wire [5:0]                        s_axis_c2h_mty; 

   // AXIS C2H tuser wire 
   wire [127:0]                      dma0_s_axis_c2h_cmpt_tdata;
   wire [1:0]                        dma0_s_axis_c2h_cmpt_size;
   wire [15:0]                       dma0_s_axis_c2h_cmpt_dpar;
   wire                              dma0_s_axis_c2h_cmpt_tvalid;
   wire                              dma0_s_axis_c2h_cmpt_tlast;
   wire                              dma0_s_axis_c2h_cmpt_tready;

   wire                              dma0_tm_dsc_sts_vld;
   wire                              dma0_tm_dsc_sts_qen;
   wire                              dma0_tm_dsc_sts_byp;
   wire                              dma0_tm_dsc_sts_dir;
   wire                              dma0_tm_dsc_sts_mm;
   wire                              dma0_tm_dsc_sts_error;
   wire [10:0]                       dma0_tm_dsc_sts_qid;
   wire [15:0]                       dma0_tm_dsc_sts_avl;
   wire                              dma0_tm_dsc_sts_qinv;
   wire                              dma0_tm_dsc_sts_irq_arm;
   wire                              dma0_tm_dsc_sts_rdy;

   // Report the DROP case
   wire                              dma0_axis_c2h_status_drop; 
   wire                              dma0_axis_c2h_status_last; 
   wire                              dma0_axis_c2h_status_valid; 

   wire [10:0]                       c2h_num_pkt;
   wire [10:0]                       c2h_st_qid;
   wire [15:0]                       c2h_st_len;
   wire [31:0]                       h2c_count;
   wire [1:0]                        h2c_match;
   wire                              clr_h2c_match;
   wire [31:0]                       control_reg_c2h;
   wire [10:0]                       h2c_qid;
   wire [31:0]                       cmpt_size;
   wire [255:0]                      wb_dat;
   wire [TM_DSC_BITS-1:0]            credit_out;
   wire [TM_DSC_BITS-1:0]            credit_needed;
   wire [TM_DSC_BITS-1:0]            credit_perpkt_in;
   wire                              credit_updt;
   wire [15:0] 	                     buf_count;
   
   wire [31:0]                       control_reg_c2h2;
   // H2C checking
   wire                              stat_vld;
   wire [31:0]                       stat_err;

   // qid output signals
   wire                              qid_rdy;
   wire                              qid_vld;
   wire [10:0]                       qid;
   wire [16-1:0]                     qid_desc_avail;
   wire                              desc_cnt_dec;
   wire [10:0]                       desc_cnt_dec_qid;
   wire                              requeue_vld;
   wire [10:0]                       requeue_qid;
   wire                              requeue_rdy;
   wire [16-1:0]                     dbg_userctrl_credits;

   // Performance counter signals
   wire [C_CNTR_WIDTH-1:0]           user_cntr_max;
   wire                              user_cntr_rst;
   wire                              user_cntr_read;
   wire [C_CNTR_WIDTH-1:0]           free_cnts;
   wire [C_CNTR_WIDTH-1:0]           idle_cnts;
   wire [C_CNTR_WIDTH-1:0]           busy_cnts;
   wire [C_CNTR_WIDTH-1:0]           actv_cnts;

   wire [C_CNTR_WIDTH-1:0]           h2c_user_cntr_max;
   wire                              h2c_user_cntr_rst;
   wire                              h2c_user_cntr_read;
   wire [C_CNTR_WIDTH-1:0]           h2c_free_cnts;
   wire [C_CNTR_WIDTH-1:0]           h2c_idle_cnts;
   wire [C_CNTR_WIDTH-1:0]           h2c_busy_cnts;
   wire [C_CNTR_WIDTH-1:0]           h2c_actv_cnts;

   // l3fwd latency signals
   wire [C_CNTR_WIDTH-1:0]           user_l3fwd_max;
   wire                              user_l3fwd_en;
   wire                              user_l3fwd_mode;
   wire                              user_l3fwd_rst;
   wire                              user_l3fwd_read;

   wire [C_CNTR_WIDTH-1:0]           max_latency;
   wire [C_CNTR_WIDTH-1:0]           min_latency;
   wire [C_CNTR_WIDTH-1:0]           sum_latency;
   wire [C_CNTR_WIDTH-1:0]           num_pkt_rcvd;

  <?BD_NAME> <?BD_NAME>_i (

     .pcie_refclk_clk_n(pcie_refclk_clk_n),
     .pcie_refclk_clk_p(pcie_refclk_clk_p),

     .pcie_gts_grx_n(pcie_gts_grx_n),
     .pcie_gts_grx_p(pcie_gts_grx_p),
     .pcie_gts_gtx_n(pcie_gts_gtx_n),
     .pcie_gts_gtx_p(pcie_gts_gtx_p),

     .M_AXIL_araddr  (m_axil_araddr),
     .M_AXIL_arprot  (m_axil_arprot),
     .M_AXIL_arready (m_axil_arready),
     .M_AXIL_arvalid (m_axil_arvalid),
     .M_AXIL_awaddr  (m_axil_awaddr),
     .M_AXIL_awprot  (m_axil_awprot),
     .M_AXIL_awready (m_axil_awready),
     .M_AXIL_awvalid (m_axil_awvalid),
     .M_AXIL_bready  (m_axil_bready),
     .M_AXIL_bresp   (m_axil_bresp),
     .M_AXIL_bvalid  (m_axil_bvalid),
     .M_AXIL_rdata   (m_axil_rdata),
     .M_AXIL_rready  (m_axil_rready),
     .M_AXIL_rresp   (m_axil_rresp),
     .M_AXIL_rvalid  (m_axil_rvalid),
     .M_AXIL_wdata   (m_axil_wdata),
     .M_AXIL_wready  (m_axil_wready),
     .M_AXIL_wstrb   (m_axil_wstrb),
     .M_AXIL_wvalid  (m_axil_wvalid),
 
     .pcie0_user_clk         ( axi_aclk                  ),
     .dma0_soft_resetn       ( soft_resetn               ),
     .dma0_axi_aresetn       ( axi_aresetn               ),
     
     .dma0_s_axis_c2h_ctrl_dis_cmpt  ( s_axis_c2h_ctrl_dis_cmpt  ),
     .dma0_s_axis_c2h_ctrl_imm_data  ( s_axis_c2h_ctrl_imm_data  ),
     .dma0_s_axis_c2h_ctrl_len       ( s_axis_c2h_ctrl_len       ), 
     .dma0_s_axis_c2h_ctrl_marker    ( s_axis_c2h_ctrl_marker    ),
     .dma0_s_axis_c2h_ctrl_port_id   ( 3'b000                    ),
     .dma0_s_axis_c2h_ctrl_qid       ( s_axis_c2h_ctrl_qid       ), 
     .dma0_s_axis_c2h_ctrl_user_trig ( s_axis_c2h_ctrl_user_trig ),
     .dma0_s_axis_c2h_dpar           ( s_axis_c2h_dpar           ),
     .dma0_s_axis_c2h_mty            ( s_axis_c2h_mty            ), // no empty bytes at EOP
     .dma0_s_axis_c2h_tdata          ( s_axis_c2h_tdata          ),
     .dma0_s_axis_c2h_tlast          ( s_axis_c2h_tlast          ),
     .dma0_s_axis_c2h_tready         ( s_axis_c2h_tready         ),
     .dma0_s_axis_c2h_tvalid         ( s_axis_c2h_tvalid         ),

     .dma0_axis_c2h_status_drop      ( dma0_axis_c2h_status_drop ),
     .dma0_axis_c2h_status_qid       ( dma0_axis_c2h_status_qid  ),
     .dma0_axis_c2h_status_valid     ( dma0_axis_c2h_status_valid),
     
     .dma0_s_axis_c2h_cmpt_data      ( dma0_s_axis_c2h_cmpt_tdata     ),
     .dma0_s_axis_c2h_cmpt_dpar      ( dma0_s_axis_c2h_cmpt_dpar[3:0] ),
     .dma0_s_axis_c2h_cmpt_tlast     ( dma0_s_axis_c2h_cmpt_tlast     ),
     .dma0_s_axis_c2h_cmpt_tready    ( dma0_s_axis_c2h_cmpt_tready    ),
     .dma0_s_axis_c2h_cmpt_tvalid    ( dma0_s_axis_c2h_cmpt_tvalid    ),
     .dma0_s_axis_c2h_cmpt_size      ( dma0_s_axis_c2h_cmpt_size      ),
     
     .dma0_m_axis_h2c_tdata          ( m_axis_h2c_tdata          ),
     .dma0_m_axis_h2c_par            ( m_axis_h2c_dpar           ),
     .dma0_m_axis_h2c_tlast          ( m_axis_h2c_tlast          ),
     .dma0_m_axis_h2c_tready         ( m_axis_h2c_tready         ),
     .dma0_m_axis_h2c_tvalid         ( m_axis_h2c_tvalid         ),
     .dma0_m_axis_h2c_qid            ( m_axis_h2c_tuser[10: 0]   ),
     .dma0_m_axis_h2c_port_id        ( m_axis_h2c_tuser[13:11]   ),
     .dma0_m_axis_h2c_err            ( m_axis_h2c_tuser[14]      ),
     .dma0_m_axis_h2c_mdata          ( m_axis_h2c_tuser[46:15]   ),
     .dma0_m_axis_h2c_mty            ( m_axis_h2c_tuser[52:47]   ),
     .dma0_m_axis_h2c_zero_byte      ( m_axis_h2c_tuser[53]      ),

     // Vendor Defined Messages (VDM); PCIe Standard
     // Unused
     .dma0_st_rx_msg_tdata           (      ),
     .dma0_st_rx_msg_tlast           (      ),
     .dma0_st_rx_msg_tready          ( 1'b1 ),
     .dma0_st_rx_msg_tvalid          (      ),
      
     .dma0_tm_dsc_sts_avl            ( dma0_tm_dsc_sts_avl            ),
     .dma0_tm_dsc_sts_byp            ( dma0_tm_dsc_sts_byp            ),
     .dma0_tm_dsc_sts_dir            ( dma0_tm_dsc_sts_dir            ),
     .dma0_tm_dsc_sts_error          ( dma0_tm_dsc_sts_error          ),
     .dma0_tm_dsc_sts_irq_arm        ( dma0_tm_dsc_sts_irq_arm        ),
     .dma0_tm_dsc_sts_mm             ( dma0_tm_dsc_sts_mm             ),
     .dma0_tm_dsc_sts_port_id        ( ),
     .dma0_tm_dsc_sts_qen            ( dma0_tm_dsc_sts_qen            ),
     .dma0_tm_dsc_sts_qid            ( dma0_tm_dsc_sts_qid            ),
     .dma0_tm_dsc_sts_qinv           ( dma0_tm_dsc_sts_qinv           ),
     .dma0_tm_dsc_sts_rdy            ( dma0_tm_dsc_sts_rdy            ),
     .dma0_tm_dsc_sts_valid          ( dma0_tm_dsc_sts_vld            )
  );

  axil_to_reg #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) axil_converter (
    .aclk    (axi_aclk),
    .aresetn (axi_aresetn),
    /* AXI-Lite Slave */
    .s_axil_awvalid( m_axil_awvalid ),
    .s_axil_awready( m_axil_awready ),
    .s_axil_awaddr ( m_axil_awaddr  ),
    .s_axil_awprot ( m_axil_awprot  ),
    .s_axil_wvalid ( m_axil_wvalid  ),
    .s_axil_wready ( m_axil_wready  ),
    .s_axil_wdata  ( m_axil_wdata   ),
    .s_axil_wstrb  ( m_axil_wstrb   ),
    .s_axil_bvalid ( m_axil_bvalid  ),
    .s_axil_bready ( m_axil_bready  ),
    .s_axil_bresp  ( m_axil_bresp   ),
    .s_axil_arvalid( m_axil_arvalid ),
    .s_axil_arready( m_axil_arready ),
    .s_axil_araddr ( m_axil_araddr  ),
    .s_axil_arprot ( m_axil_arprot  ),
    .s_axil_rvalid ( m_axil_rvalid  ),
    .s_axil_rready ( m_axil_rready  ),
    .s_axil_rdata  ( m_axil_rdata   ),
    .s_axil_rresp  ( m_axil_rresp   ),
    /* Register Master */
    .wen           ( wen    ),
    .waddr         ( waddr  ),
    .wdata         ( wdata  ),
    .wbe           ( ),
    .ren           ( ren    ),
    .rvalid        ( rvalid ),
    .rdone         ( rdone  ),
    .raddr         ( raddr  ),
    .rdata         ( rdata  )
  );
   
  user_control #(
    .C_DATA_WIDTH                  ( C_DATA_WIDTH_ST   ),
    .QID_MAX                       ( QID_MAX           ),
    .TM_DSC_BITS                   ( TM_DSC_BITS       ),
    .C_CNTR_WIDTH                  ( C_CNTR_WIDTH      )
  ) user_control_i (
    .user_clk                       ( axi_aclk          ),
    .user_reset_n                   ( axi_aresetn       ),
    .wen                            ( wen               ),
    .waddr                          ( waddr[11:0]       ),
    .wdata                          ( wdata             ),
    .ren                            ( ren               ),
    .rvalid                         ( rvalid            ),
    .rdone                          ( rdone             ),
    .raddr                          ( raddr[11:0]       ),
    .rdata                          ( rdata             ),
    .gen_user_reset_n               ( soft_resetn       ),
    .axi_mm_h2c_valid               ( 1'b0              ), // Used when MM and Stream concurrent test is run
    .axi_mm_h2c_ready               ( 1'b0              ), // Used when MM and Stream concurrent test is run
    .axi_mm_c2h_valid               ( 1'b0              ), // Used when MM and Stream concurrent test is run
    .axi_mm_c2h_ready               ( 1'b0              ), // Used when MM and Stream concurrent test is run
    .axi_st_h2c_valid               ( m_axis_h2c_tvalid   ),
    .axi_st_h2c_ready               ( m_axis_h2c_tready   ),
    .axi_st_c2h_valid               ( s_axis_c2h_tvalid   ),
    .axi_st_c2h_ready               ( s_axis_c2h_tready   ),
    .c2h_st_qid                     ( c2h_st_qid          ),
    .control_reg_c2h                ( control_reg_c2h     ),
    .control_reg_c2h2               ( control_reg_c2h2    ), 
    .c2h_num_pkt                    ( c2h_num_pkt         ),
    .clr_h2c_match                  ( clr_h2c_match       ),
    .c2h_st_len                     ( c2h_st_len          ),
    .h2c_count                      ( h2c_count           ),
    .h2c_match                      ( h2c_match           ),
    .h2c_qid                        ( h2c_qid             ),
    .wb_dat                         ( wb_dat              ),
    .credit_out                     ( credit_out          ),
    .credit_updt                    ( credit_updt         ),
    .credit_perpkt_in               ( credit_perpkt_in    ),
    .credit_needed                  ( credit_needed       ),
    .buf_count                      ( buf_count           ),
    .axis_c2h_drop                  ( dma0_axis_c2h_status_drop  ),
    .axis_c2h_drop_valid            ( dma0_axis_c2h_status_valid ),
    .cmpt_size                      ( cmpt_size           ),
    
    // tm interface signals
    .tm_dsc_sts_vld                 ( dma0_tm_dsc_sts_vld      ),
    .tm_dsc_sts_qen                 ( dma0_tm_dsc_sts_qen      ),
    .tm_dsc_sts_byp                 ( dma0_tm_dsc_sts_byp      ),
    .tm_dsc_sts_dir                 ( dma0_tm_dsc_sts_dir      ),
    .tm_dsc_sts_mm                  ( dma0_tm_dsc_sts_mm       ), 
    .tm_dsc_sts_qid                 ( dma0_tm_dsc_sts_qid      ),
    .tm_dsc_sts_avl                 ( dma0_tm_dsc_sts_avl      ),
    .tm_dsc_sts_qinv                ( dma0_tm_dsc_sts_qinv     ),
    .tm_dsc_sts_irq_arm             ( dma0_tm_dsc_sts_irq_arm  ),
    .tm_dsc_sts_rdy                 ( dma0_tm_dsc_sts_rdy      ),
    
    .stat_vld                       ( stat_vld           ),
    .stat_err                       ( stat_err           ),
    
    // qid output signals
    .qid_rdy                        ( qid_rdy            ),
    .qid_vld                        ( qid_vld            ),
    .qid                            ( qid                ),
    .qid_desc_avail                 ( qid_desc_avail     ),
    .desc_cnt_dec                   ( desc_cnt_dec       ),
    .desc_cnt_dec_qid               ( desc_cnt_dec_qid   ),
    .requeue_vld                    ( requeue_vld        ),
    .requeue_qid                    ( requeue_qid        ),
    .requeue_rdy                    ( requeue_rdy        ),
    .dbg_userctrl_credits           ( dbg_userctrl_credits ),
    
    // Performance counter signals
    .user_cntr_max                  ( user_cntr_max      ),
    .user_cntr_rst                  ( user_cntr_rst      ),
    .user_cntr_read                 ( user_cntr_read     ),
    .free_cnts                      ( free_cnts          ),
    .idle_cnts                      ( idle_cnts          ),
    .busy_cnts                      ( busy_cnts          ),
    .actv_cnts                      ( actv_cnts          ),
    
    .h2c_user_cntr_max              ( h2c_user_cntr_max  ),
    .h2c_user_cntr_rst              ( h2c_user_cntr_rst  ),
    .h2c_user_cntr_read             ( h2c_user_cntr_read ),
    .h2c_free_cnts                  ( h2c_free_cnts      ),
    .h2c_idle_cnts                  ( h2c_idle_cnts      ),
    .h2c_busy_cnts                  ( h2c_busy_cnts      ),
    .h2c_actv_cnts                  ( h2c_actv_cnts      ),
    
    // l3fwd latency signals
    .user_l3fwd_max                 ( user_l3fwd_max     ),
    .user_l3fwd_en                  ( user_l3fwd_en      ),
    .user_l3fwd_mode                ( user_l3fwd_mode    ),
    .user_l3fwd_rst                 ( user_l3fwd_rst     ),
    .user_l3fwd_read                ( user_l3fwd_read    ),
    
    .max_latency                    ( max_latency        ),
    .min_latency                    ( min_latency        ),
    .sum_latency                    ( sum_latency        ),
    .num_pkt_rcvd                   ( num_pkt_rcvd       ) 
  );

  axi_st_module #(
    .C_DATA_WIDTH                   ( C_DATA_WIDTH_ST    ),
    .QID_MAX                        ( QID_MAX            ),
    .TM_DSC_BITS                    ( TM_DSC_BITS        ),
    .C_CNTR_WIDTH                   ( C_CNTR_WIDTH       )
  ) axi_st_module_i (
    .user_reset_n                   ( axi_aresetn & soft_resetn  ),
    .user_clk                       ( axi_aclk                   ),
    .control_reg_c2h                ( control_reg_c2h          ),
    .control_reg_c2h2               ( control_reg_c2h2         ), 
    .clr_h2c_match                  ( clr_h2c_match            ),
    .c2h_num_pkt                    ( c2h_num_pkt              ),
    .h2c_count                      ( h2c_count                ),
    .h2c_match                      ( h2c_match                ),
    .h2c_qid                        ( h2c_qid                  ),
    .wb_dat                         ( wb_dat                   ),
    .cmpt_size                      ( cmpt_size                ),
    .credit_in                      ( credit_out               ),
    .credit_updt                    ( credit_updt              ),
    .credit_perpkt_in               ( credit_perpkt_in         ),
    .credit_needed                  ( credit_needed            ),
    .buf_count                      ( buf_count                ),
    .m_axis_h2c_tvalid              ( m_axis_h2c_tvalid        ),
    .m_axis_h2c_tready              ( m_axis_h2c_tready        ),
    .m_axis_h2c_tdata               ( m_axis_h2c_tdata         ),
    .m_axis_h2c_tlast               ( m_axis_h2c_tlast         ),
    .m_axis_h2c_dpar                ( m_axis_h2c_dpar          ), 
    .m_axis_h2c_tuser_qid           ( m_axis_h2c_tuser[10:0]   ), 
    .m_axis_h2c_tuser_port_id       ( m_axis_h2c_tuser[13:11]  ), 
    .m_axis_h2c_tuser_err           ( m_axis_h2c_tuser[14]     ), 
    .m_axis_h2c_tuser_mdata         ( m_axis_h2c_tuser[46:15]  ), 
    .m_axis_h2c_tuser_mty           ( m_axis_h2c_tuser[52:47]  ), 
    .m_axis_h2c_tuser_zero_byte     ( m_axis_h2c_tuser[53]     ), 
    .s_axis_c2h_tdata               ( s_axis_c2h_tdata         ),
    .s_axis_c2h_dpar                ( s_axis_c2h_dpar          ),
    .s_axis_c2h_ctrl_marker         ( s_axis_c2h_ctrl_marker   ),
    .s_axis_c2h_ctrl_len            ( s_axis_c2h_ctrl_len      ),   // c2h_st_len,
    .s_axis_c2h_ctrl_qid            ( s_axis_c2h_ctrl_qid      ),   // st_qid,
    .s_axis_c2h_ctrl_user_trig      ( s_axis_c2h_ctrl_user_trig),
    .s_axis_c2h_ctrl_dis_cmpt       ( s_axis_c2h_ctrl_dis_cmpt ),   // disable write back, write back not valid
    .s_axis_c2h_ctrl_imm_data       ( s_axis_c2h_ctrl_imm_data ),   // immediate data, 1 = data in transfer, 0 = no data in transfer
    .s_axis_c2h_tvalid              ( s_axis_c2h_tvalid        ),
    .s_axis_c2h_tready              ( s_axis_c2h_tready        ),
    .s_axis_c2h_tlast               ( s_axis_c2h_tlast         ),
    .s_axis_c2h_mty                 ( s_axis_c2h_mty           ),   // no empty bytes at EOP
    .s_axis_c2h_cmpt_tdata          ( dma0_s_axis_c2h_cmpt_tdata    ),
    .s_axis_c2h_cmpt_size           ( dma0_s_axis_c2h_cmpt_size     ),
    .s_axis_c2h_cmpt_dpar           ( dma0_s_axis_c2h_cmpt_dpar     ),
    .s_axis_c2h_cmpt_tvalid         ( dma0_s_axis_c2h_cmpt_tvalid   ),
    .s_axis_c2h_cmpt_tlast          ( dma0_s_axis_c2h_cmpt_tlast    ),
    .s_axis_c2h_cmpt_tready         ( dma0_s_axis_c2h_cmpt_tready   ),
    .s_axis_c2h_cmpt_ctrl_qid             (  ), 
    .s_axis_c2h_cmpt_ctrl_cmpt_type       (  ), 
    .s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id (  ), 
    .s_axis_c2h_cmpt_ctrl_port_id         (  ), 
    .s_axis_c2h_cmpt_ctrl_marker          (  ), 
    .s_axis_c2h_cmpt_ctrl_user_trig       (  ), 
    .s_axis_c2h_cmpt_ctrl_col_idx         (  ), 
    .s_axis_c2h_cmpt_ctrl_err_idx         (  ), 
    
    .stat_vld                       ( stat_vld           ),
    .stat_err                       ( stat_err           ),
    
    // qid input signals
    .qid_rdy                        ( qid_rdy            ),
    .qid_vld                        ( qid_vld            ),
    .qid                            ( qid                ),
    .qid_desc_avail                 ( qid_desc_avail     ),
    .desc_cnt_dec                   ( desc_cnt_dec       ),
    .desc_cnt_dec_qid               ( desc_cnt_dec_qid   ),
    .requeue_vld                    ( requeue_vld        ),
    .requeue_qid                    ( requeue_qid        ),
    .requeue_rdy                    ( requeue_rdy        ),
    .dbg_userctrl_credits           ( dbg_userctrl_credits ),
    
    // Performance counter signals
    .user_cntr_max                  ( user_cntr_max      ),
    .user_cntr_rst                  ( user_cntr_rst      ),
    .user_cntr_read                 ( user_cntr_read     ),
    .free_cnts_o                    ( free_cnts          ),
    .idle_cnts_o                    ( idle_cnts          ),
    .busy_cnts_o                    ( busy_cnts          ),
    .actv_cnts_o                    ( actv_cnts          ),
    
    .h2c_user_cntr_max              ( h2c_user_cntr_max  ),
    .h2c_user_cntr_rst              ( h2c_user_cntr_rst  ),
    .h2c_user_cntr_read             ( h2c_user_cntr_read ),
    .h2c_free_cnts_o                ( h2c_free_cnts      ),
    .h2c_idle_cnts_o                ( h2c_idle_cnts      ),
    .h2c_busy_cnts_o                ( h2c_busy_cnts      ),
    .h2c_actv_cnts_o                ( h2c_actv_cnts      ),
    
    // l3fwd latency signals
    .user_l3fwd_max                 ( user_l3fwd_max     ),
    .user_l3fwd_en                  ( user_l3fwd_en      ),
    .user_l3fwd_mode                ( user_l3fwd_mode    ),
    .user_l3fwd_rst                 ( user_l3fwd_rst     ),
    .user_l3fwd_read                ( user_l3fwd_read    ),
    
    .max_latency                    ( max_latency        ),
    .min_latency                    ( min_latency        ),
    .sum_latency                    ( sum_latency        ),
    .num_pkt_rcvd                   ( num_pkt_rcvd       )
  );

endmodule
