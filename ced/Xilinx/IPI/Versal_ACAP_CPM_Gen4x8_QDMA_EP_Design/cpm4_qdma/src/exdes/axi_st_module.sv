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

`timescale 1 ps / 1 ps

module axi_st_module
  #( 
     parameter C_DATA_WIDTH = 256,
     parameter C_H2C_TUSER_WIDTH = 128,
     parameter TM_DSC_BITS = 16
     )
   (
    input axi_aresetn ,
    input axi_aclk,

    input [10:0] c2h_st_qid,
    input [31:0] control_reg_c2h,
    input clr_h2c_match,
    input [15:0] c2h_st_len,
    input [10:0] c2h_num_pkt,
    input [31:0] cmpt_size,
    input [255:0] wb_dat,
    input   [C_DATA_WIDTH-1 :0]    m_axis_h2c_tdata /* synthesis syn_keep = 1 */,
    input   [C_DATA_WIDTH/8-1 :0]  m_axis_h2c_dpar /* synthesis syn_keep = 1 */,
    input   [C_H2C_TUSER_WIDTH-1:0]m_axis_h2c_tuser /* synthesis syn_keep = 1 */,
    input                          m_axis_h2c_tvalid /* synthesis syn_keep = 1 */,
    output                         m_axis_h2c_tready /* synthesis syn_keep = 1 */,
    input                          m_axis_h2c_tlast /* synthesis syn_keep = 1 */,
    
    output [C_DATA_WIDTH-1 :0]     s_axis_c2h_tdata /* synthesis syn_keep = 1 */,  
    output [C_DATA_WIDTH/8-1 :0]   s_axis_c2h_dpar /* synthesis syn_keep = 1 */,  
    output                         s_axis_c2h_ctrl_marker /* synthesis syn_keep = 1 */,
    output [15:0]                  s_axis_c2h_ctrl_len /* synthesis syn_keep = 1 */,
    output [10:0]                  s_axis_c2h_ctrl_qid /* synthesis syn_keep = 1 */,
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
    input [TM_DSC_BITS-1:0]        credit_in,
    input [TM_DSC_BITS-1:0]        credit_needed,
    input [TM_DSC_BITS-1:0]        credit_perpkt_in,
    input                          credit_updt,
    input [15:0]                   buf_count,
    output [31:0]                  h2c_count,
    output [1:0]                   h2c_match,
    output reg [10:0]              h2c_qid
    );
   

//   logic  m_axis_h2c_tready;
//   logic [C_DATA_WIDTH-1 :0] s_axis_c2h_tdata;
   
   always @(posedge axi_aclk) begin
      if (~axi_aresetn) begin
	 h2c_qid <= 0;
      end
      else begin
	 h2c_qid <= (m_axis_h2c_tlast & m_axis_h2c_tvalid & m_axis_h2c_tready) ? m_axis_h2c_tuser[10:0] : h2c_qid;
      end
   end

   assign s_axis_c2h_ctrl_marker = control_reg_c2h[5];
   assign s_axis_c2h_ctrl_user_trig = 1'b0;
   assign s_axis_c2h_ctrl_dis_cmpt = control_reg_c2h[3];  // disable c2h completion, (write back) not valid
   assign s_axis_c2h_ctrl_imm_data = control_reg_c2h[2];  // immediate data, 1 = data in transfer, 0 = no data in transfer
   assign s_axis_c2h_mty = control_reg_c2h[2] ? 6'h0 :
                           (s_axis_c2h_tlast & (c2h_st_len%(C_DATA_WIDTH/8) > 0)) ? C_DATA_WIDTH/8 - (c2h_st_len%(C_DATA_WIDTH/8)) :
				6'b0;  //calculate empty bytes for c2h Streaming interface.

   assign s_axis_c2h_ctrl_len = control_reg_c2h[2] ?  (16'h0 | C_DATA_WIDTH/8) : c2h_st_len; // in case of Immediate data, length = C_DATA_WIDTH/8
   assign s_axis_c2h_ctrl_qid = c2h_st_qid;
  
  ST_c2h #(
     .BIT_WIDTH ( C_DATA_WIDTH ),
     .TM_DSC_BITS ( TM_DSC_BITS )
      )
     ST_c2h_0 
       (
	.axi_aclk    (axi_aclk),
	.axi_aresetn (axi_aresetn),
	.control_reg (control_reg_c2h),
	.txr_size    (s_axis_c2h_ctrl_len),
	.num_pkt     (c2h_num_pkt),
	.credit_in   (credit_in),
	.credit_perpkt_in (credit_perpkt_in),
	.credit_needed   (credit_needed),
	.credit_updt (credit_updt),
	.buf_count   (buf_count),
	.c2h_tdata   (s_axis_c2h_tdata),
	.c2h_dpar    (s_axis_c2h_dpar),
	.c2h_tvalid  (s_axis_c2h_tvalid),
	.c2h_tlast   (s_axis_c2h_tlast),
	.c2h_tready  (s_axis_c2h_tready)
  );

  ST_h2c #(
     .BIT_WIDTH ( C_DATA_WIDTH ),
     .C_H2C_TUSER_WIDTH ( C_H2C_TUSER_WIDTH)
     )
     ST_h2c_0 (
     .axi_aclk    (axi_aclk),
     .axi_aresetn (axi_aresetn),
     .control_reg (32'h0),
     .control_run (1'b0),
     .h2c_txr_size(32'h0),
     .h2c_tdata   (m_axis_h2c_tdata),
     .h2c_tvalid  (m_axis_h2c_tvalid),
     .h2c_tready  (m_axis_h2c_tready),
     .h2c_tlast   (m_axis_h2c_tlast),
     .h2c_user    (m_axis_h2c_tuser),
     .h2c_count   (h2c_count),
     .h2c_match   (h2c_match),
     .clr_match   (clr_h2c_match)
  );
   
   logic s_axis_c2h_tlast_nn1;
   logic [1:0] wb_sm;
(* mark_debug = "true" *)localparam [1:0] 
	SM_IDL = 3'b00,
	SM_S1 = 3'b01,
        SM_S2 = 3'b10;
   
   always @(posedge axi_aclk or negedge axi_aresetn) begin
      if (~axi_aresetn) begin
	 s_axis_c2h_tlast_nn1 <= 0;
      end
      else begin
	 s_axis_c2h_tlast_nn1 <= s_axis_c2h_tlast;
      end
   end

   always @(posedge axi_aclk) begin
      if (~axi_aresetn) begin
	 wb_sm <= SM_IDL;
      end
      else
	case (wb_sm)
	 SM_IDL : 
//	   if (s_axis_c2h_tlast & s_axis_c2h_tready & s_axis_c2h_cmpt_tready) begin
       // In Everest, c2h_tready only asserts when tvalid is asserted
       if (s_axis_c2h_tlast & s_axis_c2h_tready) begin
	      wb_sm <= cmpt_size[1] ? SM_S1 : SM_S2;
	   end
	  SM_S1 : 
	    if (s_axis_c2h_cmpt_tready)
	     wb_sm <= SM_S2;
	  SM_S2 :
	    if (s_axis_c2h_cmpt_tready)
	     wb_sm <= SM_IDL;
	  default :
	     wb_sm <= SM_IDL;
	endcase // case (wb_sm)
   end
   
   // Completione size information
   // cmpt_size[1:0] = 00 : 8Bytes of data 1 beat.
   // cmpt_size[1:0] = 01 : 16Bytes of data 1 beat.
   // cmpt_size[1:0] = 10 : 32Bytes of data 2 beat.
//   assign s_axis_c2h_cmpt_tdata = wb_dat[127:0];
   logic [128/32-1 : 0] cpar_val;
   // Data parity

   assign s_axis_c2h_cmpt_dpar = ~cpar_val;
   always_comb begin
      for (integer i=0; i< (128/32); i += 1) begin
	 cpar_val[i] = ^s_axis_c2h_cmpt_tdata[i*32 +: 32];
      end
   end

   assign s_axis_c2h_cmpt_size = cmpt_size[1:0];
   wire cmpt_user_fmt;
   assign cmpt_user_fmt = cmpt_size[2];  

   // write back data format
   // Standart format
   // 0 : data format. 0 = standard format, 1 = user defined.
   // [11:1] : QID
   // [19:12] : // reserved
   // [255:20] : User data.
   // this format should be same for two cycle if type is [1] is set.
   assign s_axis_c2h_cmpt_tdata =  cmpt_size[1] ? ((wb_sm == SM_S1) ? {wb_dat[127:20], 8'h0, c2h_st_qid[10:0], cmpt_user_fmt} : wb_dat[255:128]) :
				  {wb_dat[127:20], 8'h0, c2h_st_qid[10:0], cmpt_user_fmt};
   
   assign s_axis_c2h_cmpt_tvalid = (wb_sm == SM_S1 || wb_sm == SM_S2);
   assign s_axis_c2h_cmpt_tlast  = (wb_sm == SM_S2);
   
endmodule // axi_st_module
