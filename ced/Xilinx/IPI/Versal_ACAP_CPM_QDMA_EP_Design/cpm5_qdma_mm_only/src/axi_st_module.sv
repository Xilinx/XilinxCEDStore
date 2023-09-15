// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////

`timescale 1ps / 1ps

module axi_st_module
  #( 
     parameter C_DATA_WIDTH      = 256,   // 64, 128, 256, or 512 bit only
     parameter QID_MAX           = 64,    // Number of QID currently enabled in the design. Host may choose to enable less Queue to enable at runtime
     parameter QID_WIDTH         = 11,    // Must be 11. Queue ID bit width
     parameter TM_DSC_BITS       = 16,    // Traffic Manager descriptor credit bit width
     parameter CRC_WIDTH         = 32,    // C2H CRC width
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
    output [6:0]                   s_axis_c2h_ctrl_ecc /* synthesis syn_keep = 1 */,
    output                         s_axis_c2h_tvalid /* synthesis syn_keep = 1 */,
    input                          s_axis_c2h_tready /* synthesis syn_keep = 1 */,
    output                         s_axis_c2h_tlast /* synthesis syn_keep = 1 */,
    output [5:0]                   s_axis_c2h_mty /* synthesis syn_keep = 1 */,
    output [CRC_WIDTH-1:0]         s_axis_c2h_tcrc /* synthesis syn_keep = 1 */,
    output [C_DATA_WIDTH-1:0]      s_axis_c2h_cmpt_tdata,
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
    wire                         marker_wb;       // C2H packet for this CMPT is a marker packet
    
    // ST_c2h to l3fwd_cntr signals
    wire [C_DATA_WIDTH-1 :0]     s_axis_c2h_tdata_l3fwd;
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

//   logic  m_axis_h2c_tready;
//   logic [C_DATA_WIDTH-1 :0] s_axis_c2h_tdata;
   
   always @(posedge user_clk) begin
      if (~user_reset_n) begin
        h2c_qid <= 0;
      end
      else begin
        h2c_qid <= m_axis_h2c_tlast ? m_axis_h2c_tuser_qid : h2c_qid;
      end
   end

   // C2H Control Ports
   assign s_axis_c2h_ctrl_user_trig_l3fwd = 1'b0;
   assign s_axis_c2h_ctrl_dis_cmpt_l3fwd = 1'b0;  // disable h2c complete , complete (write back) not valid
   assign s_axis_c2h_ctrl_imm_data_l3fwd = control_reg_c2h[2] ? 1'b1 : 1'b0;   // immediate data, 1 = data in transfer, 0 = no data in transfer
   assign s_axis_c2h_mty_l3fwd = (s_axis_c2h_tlast_l3fwd & (c2h_st_len%(C_DATA_WIDTH/8) > 0)) ? C_DATA_WIDTH/8 - (c2h_st_len%(C_DATA_WIDTH/8)) :
                                                                                                6'b0;  //calculate empty bytes for c2h Streaming interface.

   assign s_axis_c2h_ctrl_len_l3fwd = control_reg_c2h[2] ? 'd0 : c2h_st_len; // in case of Immediate data, length = 0
   
   // Replaced with FIFO
   //assign s_axis_c2h_ctrl_qid = qid;
   assign s_axis_c2h_ctrl_qid_l3fwd = c2h_st_qid;
   
   // Parity Generator for C2H data bus
   assign s_axis_c2h_ctrl_ecc = 7'h0; // To be added
   generate
   begin
     genvar pa;
     for (pa=0; pa < (C_DATA_WIDTH/8); pa = pa + 1) // Parity needs to be computed for every byte of data
     begin : parity_assign
       assign s_axis_c2h_dpar[pa] = !( ^ s_axis_c2h_tdata [8*(pa+1)-1:8*pa] );
     end
   end
   endgenerate
   
   // CRC Generator for C2H data bus
   crc32_gen #(
     .MAX_DATA_WIDTH   ( C_DATA_WIDTH      ),
     .CRC_WIDTH        (  CRC_WIDTH        ),
     .TCQ              ( 1                 )
   ) crc32_gen_i (
     // Clock and Resetd
     .clk              ( user_clk          ),
     .rst_n            ( user_reset_n      ),
     .in_par_err       ( 1'b0              ),
     .in_misc_err      ( 1'b0              ),
     .in_crc_dis       ( 1'b0              ),

     .in_data          ( s_axis_c2h_tdata  ),
     .in_vld           ( s_axis_c2h_tvalid & s_axis_c2h_tready ),
     .in_tlast         ( s_axis_c2h_tlast  ),
     .in_mty           ( s_axis_c2h_mty    ),
     .out_crc          ( s_axis_c2h_tcrc   )
   );
  
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
    
    .knob             ( {27'b0, control_reg_c2h[5], 2'b00, control_reg_c2h[18], 1'b1} ),
    
    .credit_in        ( qid_desc_avail    ),
    .qid              ( qid               ),
    .qid_wb           ( qid_wb            ),
    .btt_wb           ( btt_wb            ),
    .marker_wb        ( marker_wb         ),
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
    .c2h_len          ( c2h_st_len              ),
    .c2h_qid          ( c2h_st_qid              ),
    .c2h_marker       ( s_axis_c2h_ctrl_marker_l3fwd ),
    .c2h_tlast        ( s_axis_c2h_tlast_l3fwd  ),
    .c2h_tvalid       ( s_axis_c2h_tvalid_l3fwd ),
    .c2h_tready       ( s_axis_c2h_tready_l3fwd ),
    
    .cmpt_tvalid      ( s_axis_c2h_cmpt_tvalid  ),
    .cmpt_tready      ( s_axis_c2h_cmpt_tready  ),
    
    .dbg_userctrl_credits ( dbg_userctrl_credits )
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
    .marker_wb              ( marker_wb              ),
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
    .s_axis_c2h_cmpt_ctrl_err_idx         ( s_axis_c2h_cmpt_ctrl_err_idx         )
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
