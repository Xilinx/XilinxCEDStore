//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
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
// File       : axi_st_module.sv
// Version    : 5.0
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps

module axi_st_module
  #( 
     parameter C_DATA_WIDTH      = 256,   // 64, 128, 256, or 512 bit only
     parameter QID_MAX           = 64,    // Number of QID currently enabled in the design. Host may choose to enable less Queue to enable at runtime
     parameter QID_WIDTH         = 11,    // Must be 11. Queue ID bit width
     parameter TM_DSC_BITS       = 16,    // Traffic Manager descriptor credit bit width
     parameter C_CNTR_WIDTH      = 32     // Counter bit width
     )
   (
    input user_reset_n,
    input user_clk,

    input  [31:0] control_reg_c2h,
    input  [31:0] control_reg_c2h2,
    input clr_h2c_match,
    input  [10:0] c2h_num_pkt,
    input  [31:0] cmpt_size,
    input  [255:0] wb_dat,
    input  [C_DATA_WIDTH-1 :0]     m_axis_h2c_tdata /* synthesis syn_keep = 1 */,
    input  [C_DATA_WIDTH/8-1 :0]   m_axis_h2c_dpar /* synthesis syn_keep = 1 */,
    input                          m_axis_h2c_tvalid /* synthesis syn_keep = 1 */,
    output                         m_axis_h2c_tready /* synthesis syn_keep = 1 */,
    input                          m_axis_h2c_tlast /* synthesis syn_keep = 1 */,
    input  [QID_WIDTH-1:0]         m_axis_h2c_tuser_qid /* synthesis syn_keep = 1 */,
    input  [2:0]                   m_axis_h2c_tuser_port_id /* synthesis syn_keep = 1 */,
    input                          m_axis_h2c_tuser_err /* synthesis syn_keep = 1 */,
    input  [31:0]                  m_axis_h2c_tuser_mdata /* synthesis syn_keep = 1 */,
    input  [5:0]                   m_axis_h2c_tuser_mty /* synthesis syn_keep = 1 */,
    input                          m_axis_h2c_tuser_zero_byte /* synthesis syn_keep = 1 */,
    
    output [C_DATA_WIDTH-1 :0]     s_axis_c2h_tdata /* synthesis syn_keep = 1 */,  
    output [C_DATA_WIDTH/8-1 :0]   s_axis_c2h_dpar /* synthesis syn_keep = 1 */,  
    output                         s_axis_c2h_ctrl_marker /* synthesis syn_keep = 1 */,
    output [15:0]                  s_axis_c2h_ctrl_len /* synthesis syn_keep = 1 */,
    output [QID_WIDTH-1:0]         s_axis_c2h_ctrl_qid /* synthesis syn_keep = 1 */,
    output                         s_axis_c2h_ctrl_user_trig /* synthesis syn_keep = 1 */,
    output                         s_axis_c2h_ctrl_dis_cmpt /* synthesis syn_keep = 1 */,
    output                         s_axis_c2h_ctrl_imm_data /* synthesis syn_keep = 1 */,
    output                         s_axis_c2h_tvalid /* synthesis syn_keep = 1 */,
    input                          s_axis_c2h_tready /* synthesis syn_keep = 1 */,
    output                         s_axis_c2h_tlast /* synthesis syn_keep = 1 */,
    output [5:0]                   s_axis_c2h_mty /* synthesis syn_keep = 1 */ ,
    output [127:0]                 s_axis_c2h_cmpt_tdata, 
    output [1:0]                   s_axis_c2h_cmpt_size,
    output [15:0]                  s_axis_c2h_cmpt_dpar,
    output                         s_axis_c2h_cmpt_tvalid,
    output                         s_axis_c2h_cmpt_tlast,
    input                          s_axis_c2h_cmpt_tready,
    output [10:0]                  s_axis_c2h_cmpt_ctrl_qid,
    output [1:0]                   s_axis_c2h_cmpt_ctrl_cmpt_type,
    output [15:0]                  s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id,
    output [2:0]                   s_axis_c2h_cmpt_ctrl_port_id,
    output                         s_axis_c2h_cmpt_ctrl_marker,
    output                         s_axis_c2h_cmpt_ctrl_user_trig,
    output [2:0]                   s_axis_c2h_cmpt_ctrl_col_idx,
    output [2:0]                   s_axis_c2h_cmpt_ctrl_err_idx,
    input  [TM_DSC_BITS-1:0]       credit_in,
    input  [TM_DSC_BITS-1:0]       credit_needed,
    input  [TM_DSC_BITS-1:0]       credit_perpkt_in,
    input                          credit_updt,
    input  [15:0]                  buf_count,
    output [31:0]                  h2c_count,
    output                         h2c_match,
    output reg [QID_WIDTH-1:0]     h2c_qid,
    
    // H2C checking
    output                         stat_vld,
    output [31:0]                  stat_err,
    
    // qid input signals
    output                         qid_rdy,
    input                          qid_vld,
    input      [QID_WIDTH-1:0]     qid,
    input      [TM_DSC_BITS-1:0]   qid_desc_avail,
    output                         desc_cnt_dec,
    output     [QID_WIDTH-1:0]     desc_cnt_dec_qid,
    output                         requeue_vld,
    output     [QID_WIDTH-1:0]     requeue_qid,
    input                          requeue_rdy,
    input wire [TM_DSC_BITS-1:0]   dbg_userctrl_credits,
    
    // Performance counter signals
    input      [C_CNTR_WIDTH-1:0]  user_cntr_max,
    input                          user_cntr_rst,
    input                          user_cntr_read,
    output     [C_CNTR_WIDTH-1:0]  free_cnts_o,
    output     [C_CNTR_WIDTH-1:0]  idle_cnts_o,
    output     [C_CNTR_WIDTH-1:0]  busy_cnts_o,
    output     [C_CNTR_WIDTH-1:0]  actv_cnts_o,
    
    input      [C_CNTR_WIDTH-1:0]  h2c_user_cntr_max,
    input                          h2c_user_cntr_rst,
    input                          h2c_user_cntr_read,
    output     [C_CNTR_WIDTH-1:0]  h2c_free_cnts_o,
    output     [C_CNTR_WIDTH-1:0]  h2c_idle_cnts_o,
    output     [C_CNTR_WIDTH-1:0]  h2c_busy_cnts_o,
    output     [C_CNTR_WIDTH-1:0]  h2c_actv_cnts_o,
    
    input      [C_CNTR_WIDTH-1:0]  user_l3fwd_max,
    input                          user_l3fwd_en,
    input                          user_l3fwd_mode,
    input                          user_l3fwd_rst,
    input                          user_l3fwd_read,
    
    output     [C_CNTR_WIDTH-1:0]  max_latency,
    output     [C_CNTR_WIDTH-1:0]  min_latency,
    output     [C_CNTR_WIDTH-1:0]  sum_latency,
    output     [C_CNTR_WIDTH-1:0]  num_pkt_rcvd
);
   
    wire                         c2h_fifo_is_full;
    wire                         wb_is_full;
    wire                         cmpt_sent;
    wire                         c2h_formed;
    wire [15:0]                  c2h_st_len;
    wire [QID_WIDTH-1:0]         c2h_st_qid;
    wire [QID_WIDTH-1:0]         qid_wb;          // QID to send. If credit_in == 0, send a packet to random ID, else takes the valid QID input
    wire [15:0]                  btt_wb;          // C2H Length to send in Writeback. It must match with the Length of the C2H transfer this Writeback is attached to
    
    // ST_c2h to l3fwd_cntr signals
    wire [C_DATA_WIDTH-1 :0]     s_axis_c2h_tdata_l3fwd;
    wire [C_DATA_WIDTH/8-1 :0]   s_axis_c2h_dpar_l3fwd;
    wire                         s_axis_c2h_ctrl_marker_l3fwd;
    wire [15:0]                  s_axis_c2h_ctrl_len_l3fwd;
    wire [10:0]                  s_axis_c2h_ctrl_qid_l3fwd;
    wire                         s_axis_c2h_ctrl_user_trig_l3fwd;
    wire                         s_axis_c2h_ctrl_dis_cmpt_l3fwd;
    wire                         s_axis_c2h_ctrl_imm_data_l3fwd;
    wire                         s_axis_c2h_tvalid_l3fwd;
    wire                         s_axis_c2h_tready_l3fwd;
    wire                         s_axis_c2h_tlast_l3fwd;
    wire [5:0]                   s_axis_c2h_mty_l3fwd;
    
    // l3fwd_cntr to ST_h2c signals
    wire [C_DATA_WIDTH-1 :0]     m_axis_h2c_tdata_l3fwd;
    wire [C_DATA_WIDTH/8-1 :0]   m_axis_h2c_dpar_l3fwd;
    wire                         m_axis_h2c_tvalid_l3fwd;
    wire                         m_axis_h2c_tready_l3fwd;
    wire                         m_axis_h2c_tlast_l3fwd;
    wire [10:0]                  m_axis_h2c_tuser_qid_l3fwd;
    wire [2:0]                   m_axis_h2c_tuser_port_id_l3fwd;
    wire                         m_axis_h2c_tuser_err_l3fwd;
    wire [31:0]                  m_axis_h2c_tuser_mdata_l3fwd;
    wire [5:0]                   m_axis_h2c_tuser_mty_l3fwd;
    wire                         m_axis_h2c_tuser_zero_byte_l3fwd;

   always @(posedge user_clk) begin
      if (~user_reset_n) begin
        h2c_qid <= 0;
      end
      else begin
        h2c_qid <= m_axis_h2c_tlast ? m_axis_h2c_tuser_qid : h2c_qid;
      end
   end

   // C2H Control Ports
   assign s_axis_c2h_ctrl_marker_l3fwd = 1'b0;
   assign s_axis_c2h_ctrl_user_trig_l3fwd = 1'b0;
   assign s_axis_c2h_ctrl_dis_cmpt_l3fwd = 1'b0;  // disable h2c complete , complete (write back) not valid
   assign s_axis_c2h_ctrl_imm_data_l3fwd = control_reg_c2h[2] ? 1'b1 : 1'b0;   // immediate data, 1 = data in transfer, 0 = no data in transfer
   assign s_axis_c2h_mty_l3fwd = (s_axis_c2h_tlast_l3fwd & (c2h_st_len%(C_DATA_WIDTH/8) > 0)) ? C_DATA_WIDTH/8 - (c2h_st_len%(C_DATA_WIDTH/8)) :
                                                                                                6'b0;  //calculate empty bytes for c2h Streaming interface.

   assign s_axis_c2h_ctrl_len_l3fwd = control_reg_c2h[2] ? 'd0 : c2h_st_len; // in case of Immediate data, length = 0
   
   assign s_axis_c2h_ctrl_qid_l3fwd = c2h_st_qid;
  
  ST_c2h #(
    .DATA_WIDTH       ( C_DATA_WIDTH      ),
    .QID_WIDTH        ( QID_WIDTH         ),
    .LEN_WIDTH        ( 16                ),
    .PATT_WIDTH       ( 16                ),
    .TM_DSC_BITS      ( 16                ),
    .BYTE_CREDIT      ( 4096              ),
    .MAX_CRDT         ( 4                 ),
    .QID_MAX          ( QID_MAX           ),
    .SEED             ( 32'hb105f00d      ),
    .TCQ              ( 1                 )
  ) ST_c2h_0 (
    .user_clk         ( user_clk          ),
    .user_reset_n     ( user_reset_n      ),
    
    .knob             ( {29'b0, 1'b0, control_reg_c2h[18], 1'b1} ),
    
    .credit_in        ( qid_desc_avail    ),
    .qid              ( qid               ),
    .qid_wb           ( qid_wb            ),
    .btt_wb           ( btt_wb            ),
    .credit_rdy       ( qid_rdy           ),
    .credit_vld       ( qid_vld           ),
    .dec_qid          ( desc_cnt_dec_qid  ),
    .dec_credit       ( desc_cnt_dec      ),
    .requeue_qid      ( requeue_qid       ),
    .requeue_credit   ( requeue_vld       ),
    .requeue_rdy      ( requeue_rdy       ),
    .cmpt_sent        ( cmpt_sent         ),
    .wb_is_full       ( wb_is_full        ),
    .c2h_formed       ( c2h_formed        ),
    .c2h_fifo_is_full ( c2h_fifo_is_full  ),
    
    .c2h_tdata        ( s_axis_c2h_tdata_l3fwd  ),
    .c2h_dpar         ( s_axis_c2h_dpar_l3fwd   ),
    .c2h_len          ( c2h_st_len              ),
    .c2h_qid          ( c2h_st_qid              ),
    .c2h_tvalid       ( s_axis_c2h_tvalid_l3fwd ),
    .c2h_tlast        ( s_axis_c2h_tlast_l3fwd  ),
    .c2h_tready       ( s_axis_c2h_tready_l3fwd ),
    
    .cmpt_tvalid      ( s_axis_c2h_cmpt_tvalid  ),
    .cmpt_tready      ( s_axis_c2h_cmpt_tready  ),
    
    .dbg_userctrl_credits ( dbg_userctrl_credits ),
    .cnt_c2h_data_fifo_in ()
  );
  
  ST_c2h_cmpt #(
    .DATA_WIDTH             ( C_DATA_WIDTH           ),
    .LEN_WIDTH              ( 16                     ),
    .QID_WIDTH              ( QID_WIDTH              ),
    .TCQ                    ( 1                      )
  ) ST_c2h_cmpt_0 (
    .user_clk               ( user_clk               ),
    .user_reset_n           ( user_reset_n           ),
    
    .knob                   ( {30'b0, control_reg_c2h[21], 1'b1} ),
    .wb_dat                 ( wb_dat                 ),
    
    .c2h_formed             ( c2h_formed             ),
    .cmpt_size              ( cmpt_size              ),
    .qid_wb                 ( qid_wb                 ),
    .btt_wb                 ( btt_wb                 ),
    .c2h_fifo_is_full       ( c2h_fifo_is_full       ),
    .wb_is_full             ( wb_is_full             ),
    .cmpt_sent              ( cmpt_sent              ),
    
    .s_axis_c2h_cmpt_tdata  ( s_axis_c2h_cmpt_tdata  ),
    .s_axis_c2h_cmpt_size   ( s_axis_c2h_cmpt_size   ),
    .s_axis_c2h_cmpt_dpar   ( s_axis_c2h_cmpt_dpar   ),
    .s_axis_c2h_cmpt_tvalid ( s_axis_c2h_cmpt_tvalid ),
    .s_axis_c2h_cmpt_tlast  ( s_axis_c2h_cmpt_tlast  ),
    .s_axis_c2h_cmpt_tready ( s_axis_c2h_cmpt_tready ),
    
    .s_axis_c2h_cmpt_ctrl_qid             ( s_axis_c2h_cmpt_ctrl_qid             ),
    .s_axis_c2h_cmpt_ctrl_cmpt_type       ( s_axis_c2h_cmpt_ctrl_cmpt_type       ),
    .s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id ( s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id ),
    .s_axis_c2h_cmpt_ctrl_port_id         ( s_axis_c2h_cmpt_ctrl_port_id         ),
    .s_axis_c2h_cmpt_ctrl_marker          ( s_axis_c2h_cmpt_ctrl_marker          ),
    .s_axis_c2h_cmpt_ctrl_user_trig       ( s_axis_c2h_cmpt_ctrl_user_trig       ),
    .s_axis_c2h_cmpt_ctrl_col_idx         ( s_axis_c2h_cmpt_ctrl_col_idx         ),
    .s_axis_c2h_cmpt_ctrl_err_idx         ( s_axis_c2h_cmpt_ctrl_err_idx         ),
    .cnt_c2h_cmpt_fifo_in                 ()
  );

  ST_h2c #(
    .DATA_WIDTH          ( C_DATA_WIDTH                     ),
    .QID_WIDTH           ( QID_WIDTH                        ),
    .LEN_WIDTH           ( 16                               ),
    .PATT_WIDTH          ( 16                               ),
    .TM_DSC_BITS         ( TM_DSC_BITS                      ),
    .BYTE_CREDIT         ( 4096                             ),
    .MAX_CRDT            ( 4                                ),
    .SEED                ( 32'hb105f00d                     ),
    .TCQ                 ( 1                                )
  ) ST_h2c_0 (
    .user_clk            ( user_clk                         ),
    .user_reset_n        ( user_reset_n                     ),
    
    .knob                ( 32'h0 ), 
    
    .stat_vld            ( stat_vld                         ),
    .stat_err            ( stat_err                         ),
    
    .h2c_tdata           ( m_axis_h2c_tdata_l3fwd           ),
    .h2c_dpar            ( m_axis_h2c_dpar_l3fwd            ),
    .h2c_tvalid          ( m_axis_h2c_tvalid_l3fwd          ),
    .h2c_tready          ( m_axis_h2c_tready_l3fwd          ),
    .h2c_tlast           ( m_axis_h2c_tlast_l3fwd           ),
    .h2c_tuser_qid       ( m_axis_h2c_tuser_qid_l3fwd       ),
    .h2c_tuser_port_id   ( m_axis_h2c_tuser_port_id_l3fwd   ),
    .h2c_tuser_err       ( m_axis_h2c_tuser_err_l3fwd       ),
    .h2c_tuser_mdata     ( m_axis_h2c_tuser_mdata_l3fwd     ),
    .h2c_tuser_mty       ( m_axis_h2c_tuser_mty_l3fwd       ),
    .h2c_tuser_zero_byte ( m_axis_h2c_tuser_zero_byte_l3fwd )
  );
  
  // C2H Performance Counter
  perf_cntr #(
    .C_CNTR_WIDTH   ( C_CNTR_WIDTH      ),
    .TCQ            ( 1                 )
  ) ST_c2h_perf_cntr_i (
    .user_clk       ( user_clk          ),
    
    .user_cntr_max  ( user_cntr_max     ),
    .user_cntr_rst  ( user_cntr_rst     ),
    .user_cntr_read ( user_cntr_read    ),
    
    .free_cnts_o    ( free_cnts_o       ),
    .idle_cnts_o    ( idle_cnts_o       ),
    .busy_cnts_o    ( busy_cnts_o       ),
    .actv_cnts_o    ( actv_cnts_o       ),
  
    .valid          ( s_axis_c2h_tvalid ),
    .ready          ( s_axis_c2h_tready )
  );
  
  perf_cntr #(
    .C_CNTR_WIDTH   ( 64                     ),
    .TCQ            ( 1                      )
  ) ST_h2c_perf_cntr_i (
    .user_clk       ( user_clk               ),
    
    .user_cntr_max  ( h2c_user_cntr_max      ),
    .user_cntr_rst  ( h2c_user_cntr_rst      ),
    .user_cntr_read ( h2c_user_cntr_read     ),
    
    .free_cnts_o    ( h2c_free_cnts_o        ),
    .idle_cnts_o    ( h2c_idle_cnts_o        ),
    .busy_cnts_o    ( h2c_busy_cnts_o        ),
    .actv_cnts_o    ( h2c_actv_cnts_o        ),
  
    .valid          ( m_axis_h2c_tvalid      ),
    .ready          ( m_axis_h2c_tready      )
  );
  
  l3fwd_cntr #(
    .C_CNTR_WIDTH                ( 64                              ),
    .C_DATA_WIDTH                ( C_DATA_WIDTH                    ),
    .QID_WIDTH                   ( QID_WIDTH                       ),
    .TCQ                         ( 1                               )
  ) l3fwd_cntr_i (
    .user_clk                    ( user_clk                        ),

    .user_l3fwd_max              ( user_l3fwd_max                  ),
    .user_l3fwd_en               ( user_l3fwd_en                   ),
    .user_l3fwd_mode             ( user_l3fwd_mode                 ),
    .user_l3fwd_rst              ( user_l3fwd_rst                  ),
    .user_l3fwd_read             ( user_l3fwd_read                 ),

    .s_axis_c2h_tdata_i          ( s_axis_c2h_tdata_l3fwd          ),
    .s_axis_c2h_dpar_i           ( s_axis_c2h_dpar_l3fwd           ),
    .s_axis_c2h_ctrl_marker_i    ( s_axis_c2h_ctrl_marker_l3fwd    ),
    .s_axis_c2h_ctrl_len_i       ( s_axis_c2h_ctrl_len_l3fwd       ),
    .s_axis_c2h_ctrl_qid_i       ( s_axis_c2h_ctrl_qid_l3fwd       ),
    .s_axis_c2h_ctrl_user_trig_i ( s_axis_c2h_ctrl_user_trig_l3fwd ),
    .s_axis_c2h_ctrl_dis_cmpt_i  ( s_axis_c2h_ctrl_dis_cmpt_l3fwd  ),
    .s_axis_c2h_ctrl_imm_data_i  ( s_axis_c2h_ctrl_imm_data_l3fwd  ),
    .s_axis_c2h_tvalid_i         ( s_axis_c2h_tvalid_l3fwd         ),
    .s_axis_c2h_tready_i         ( s_axis_c2h_tready_l3fwd         ),
    .s_axis_c2h_tlast_i          ( s_axis_c2h_tlast_l3fwd          ),
    .s_axis_c2h_mty_i            ( s_axis_c2h_mty_l3fwd            ),
  
    .s_axis_c2h_tdata_o          ( s_axis_c2h_tdata                ),
    .s_axis_c2h_dpar_o           ( s_axis_c2h_dpar                 ),
    .s_axis_c2h_ctrl_marker_o    ( s_axis_c2h_ctrl_marker          ),
    .s_axis_c2h_ctrl_len_o       ( s_axis_c2h_ctrl_len             ),
    .s_axis_c2h_ctrl_qid_o       ( s_axis_c2h_ctrl_qid             ),
    .s_axis_c2h_ctrl_user_trig_o ( s_axis_c2h_ctrl_user_trig       ),
    .s_axis_c2h_ctrl_dis_cmpt_o  ( s_axis_c2h_ctrl_dis_cmpt        ),
    .s_axis_c2h_ctrl_imm_data_o  ( s_axis_c2h_ctrl_imm_data        ),
    .s_axis_c2h_tvalid_o         ( s_axis_c2h_tvalid               ),
    .s_axis_c2h_tready_o         ( s_axis_c2h_tready               ),
    .s_axis_c2h_tlast_o          ( s_axis_c2h_tlast                ),
    .s_axis_c2h_mty_o            ( s_axis_c2h_mty                  ),
  
    .m_axis_h2c_tdata_i          ( m_axis_h2c_tdata                ),
    .m_axis_h2c_dpar_i           ( m_axis_h2c_dpar                 ),
    .m_axis_h2c_tvalid_i         ( m_axis_h2c_tvalid               ),
    .m_axis_h2c_tready_i         ( m_axis_h2c_tready               ),
    .m_axis_h2c_tlast_i          ( m_axis_h2c_tlast                ),
    .m_axis_h2c_tuser_qid_i      ( m_axis_h2c_tuser_qid            ),
    .m_axis_h2c_tuser_port_id_i  ( m_axis_h2c_tuser_port_id        ),
    .m_axis_h2c_tuser_err_i      ( m_axis_h2c_tuser_err            ),
    .m_axis_h2c_tuser_mdata_i    ( m_axis_h2c_tuser_mdata          ),
    .m_axis_h2c_tuser_mty_i      ( m_axis_h2c_tuser_mty            ),
    .m_axis_h2c_tuser_zero_byte_i( m_axis_h2c_tuser_zero_byte      ),
  
    .m_axis_h2c_tdata_o          ( m_axis_h2c_tdata_l3fwd          ),
    .m_axis_h2c_dpar_o           ( m_axis_h2c_dpar_l3fwd           ),
    .m_axis_h2c_tvalid_o         ( m_axis_h2c_tvalid_l3fwd         ),
    .m_axis_h2c_tready_o         ( m_axis_h2c_tready_l3fwd         ),
    .m_axis_h2c_tlast_o          ( m_axis_h2c_tlast_l3fwd          ),
    .m_axis_h2c_tuser_qid_o      ( m_axis_h2c_tuser_qid_l3fwd      ),
    .m_axis_h2c_tuser_port_id_o  ( m_axis_h2c_tuser_port_id_l3fwd  ),
    .m_axis_h2c_tuser_err_o      ( m_axis_h2c_tuser_err_l3fwd      ),
    .m_axis_h2c_tuser_mdata_o    ( m_axis_h2c_tuser_mdata_l3fwd    ),
    .m_axis_h2c_tuser_mty_o      ( m_axis_h2c_tuser_mty_l3fwd      ),
    .m_axis_h2c_tuser_zero_byte_o( m_axis_h2c_tuser_zero_byte_l3fwd),
  
    .max_latency_o               ( max_latency                     ),
    .min_latency_o               ( min_latency                     ),
    .sum_latency_o               ( sum_latency                     ),
    .num_pkt_rcvd_o              ( num_pkt_rcvd                    )
  );
   
endmodule // axi_st_module
