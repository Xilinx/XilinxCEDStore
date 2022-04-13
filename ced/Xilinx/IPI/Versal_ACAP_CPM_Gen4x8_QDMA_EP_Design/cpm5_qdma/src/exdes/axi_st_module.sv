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

// From pciecoredefines.h
`define XSRREG_SYNC(clk, reset_n, q,d,rstval)        \
    always @(posedge clk)                        \
    begin                                        \
     if (reset_n == 1'b0)                        \
         q <= #(TCQ) rstval;                                \
     else                                        \
         `ifdef FOURVALCLKPROP                        \
            q <= #(TCQ) clk ? d : q;                        \
          `else                                        \
            q <= #(TCQ)  d;                                \
          `endif                                \
     end

// From dma5_axi4mm_axi_bridge.vh
`define XSRREG_XDMA(clk, reset_n, q,d,rstval)        \
`XSRREG_SYNC (clk, reset_n, q,d,rstval) \

module axi_st_module
  #( 
     parameter C_DATA_WIDTH = 256,
     parameter CRC_WIDTH    = 32,
     parameter C_H2C_TUSER_WIDTH = 128,
     parameter TM_DSC_BITS = 16
     )
   (
    input axi_aresetn ,
    input axi_aclk,

    input [10:0] c2h_st_qid,
    input [31:0] c2h_control,
    input clr_h2c_match,
    input [15:0] c2h_st_len,
    input [10:0] c2h_num_pkt,
    input [31:0] cmpt_size,
    input [255:0] wb_dat,
    input   [C_DATA_WIDTH-1 :0]    m_axis_h2c_tdata /* synthesis syn_keep = 1 */,
    input   [CRC_WIDTH-1 :0]       m_axis_h2c_tcrc /* synthesis syn_keep = 1 */,
    input   [10:0]                 m_axis_h2c_tuser_qid /* synthesis syn_keep = 1 */,
    input   [2:0]                  m_axis_h2c_tuser_port_id, 
    input                          m_axis_h2c_tuser_err, 
    input   [31:0]                 m_axis_h2c_tuser_mdata, 
    input   [5:0]                  m_axis_h2c_tuser_mty, 
    input                          m_axis_h2c_tuser_zero_byte, 
    input                          m_axis_h2c_tvalid /* synthesis syn_keep = 1 */,
    output                         m_axis_h2c_tready /* synthesis syn_keep = 1 */,
    input                          m_axis_h2c_tlast /* synthesis syn_keep = 1 */,
    
    output [C_DATA_WIDTH-1 :0]     s_axis_c2h_tdata /* synthesis syn_keep = 1 */,  
    output [C_DATA_WIDTH/8-1:0]       s_axis_c2h_dpar  /* synthesis syn_keep = 1 */, 
    output [CRC_WIDTH-1 :0]        s_axis_c2h_tcrc /* synthesis syn_keep = 1 */,  
    output                         s_axis_c2h_ctrl_marker /* synthesis syn_keep = 1 */,
    output [15:0]                  s_axis_c2h_ctrl_len /* synthesis syn_keep = 1 */,
    output [10:0]                  s_axis_c2h_ctrl_qid /* synthesis syn_keep = 1 */,
    output                         s_axis_c2h_ctrl_has_cmpt /* synthesis syn_keep = 1 */,
    output                         s_axis_c2h_tvalid /* synthesis syn_keep = 1 */,
    input                          s_axis_c2h_tready /* synthesis syn_keep = 1 */,
    output                         s_axis_c2h_tlast /* synthesis syn_keep = 1 */,
    output [5:0]                   s_axis_c2h_mty /* synthesis syn_keep = 1 */ ,
    output [511:0]                 s_axis_c2h_cmpt_tdata,
    output [1:0]                   s_axis_c2h_cmpt_size,
    output [15:0]                  s_axis_c2h_cmpt_dpar,
    output                         s_axis_c2h_cmpt_tvalid,
    output  [10:0]		   s_axis_c2h_cmpt_ctrl_qid,
    output  [1:0]		   s_axis_c2h_cmpt_ctrl_cmpt_type,
    output  [15:0]		   s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id,
    output   		   	   s_axis_c2h_cmpt_ctrl_marker,
    output   		   	   s_axis_c2h_cmpt_ctrl_user_trig,
    output [2:0]                   s_axis_c2h_cmpt_ctrl_col_idx,
    output [2:0]                   s_axis_c2h_cmpt_ctrl_err_idx,
    input                          s_axis_c2h_cmpt_tready,
    input [TM_DSC_BITS-1:0]        credit_in,
    input [TM_DSC_BITS-1:0]        credit_needed,
    input [TM_DSC_BITS-1:0]        credit_perpkt_in,
    input                          credit_updt,
    input [15:0]                   buf_count,
    input 			   byp_to_cmp,
    input [511 : 0] 		   byp_data_to_cmp,
    input [1 : 0]                  c2h_dsc_bypass,
    input [10 : 0] 		   pfch_byp_tag_qid,
    output [31:0]                  h2c_count,
    output                         h2c_match,
    output logic                   h2c_crc_match,
    output                         c2h_end,
    output reg [10:0]              h2c_qid
    );

   logic [CRC_WIDTH-1 : 0]     gen_h2c_tcrc;
   logic 		       s_axis_c2h_tlast_nn1;
   logic [1:0] 		       wb_sm;
   logic [9:0] 		       cmpt_count;
   logic 		       c2h_st_d1;
   logic 		       start_c2h;
   logic 		       start_imm;
   logic [15:0] 	       cmpt_pkt_cnt;
   logic 		       cmpt_tvalid;
   logic 		       start_cmpt;

//   logic  m_axis_h2c_tready;
//   logic [C_DATA_WIDTH-1 :0] s_axis_c2h_tdata;
   
   always @(posedge axi_aclk) begin
      if (~axi_aresetn) begin
	 h2c_qid <= 0;
      end
      else begin
	 h2c_qid <= (m_axis_h2c_tvalid & m_axis_h2c_tlast) ? m_axis_h2c_tuser_qid[10:0] : h2c_qid;
      end
   end

   reg [$clog2(C_DATA_WIDTH/8)-1:0]  s_axis_c2h_mty_reg;
   reg [15:0] s_axis_c2h_ctrl_len_reg;

   always @(posedge axi_aclk) begin
      s_axis_c2h_mty_reg <= (start_imm | c2h_control[5]) ? 6'h0 :
                           (c2h_st_len%(C_DATA_WIDTH/8) > 0) ? C_DATA_WIDTH/8 - (c2h_st_len%(C_DATA_WIDTH/8)) :
				6'b0;  //calculate empty bytes for c2h Streaming interface.

      s_axis_c2h_ctrl_len_reg <= (start_imm | c2h_control[5]) ?  (16'h0 | C_DATA_WIDTH/8) : c2h_st_len; // in case of Immediate data, length = C_DATA_WIDTH/8
   end

   assign s_axis_c2h_ctrl_marker = c2h_control[5];   // C2H Marker Enabled

   assign s_axis_c2h_ctrl_has_cmpt =  ~c2h_control[3];  // Disable completions
   assign s_axis_c2h_mty = s_axis_c2h_tlast ? s_axis_c2h_mty_reg : 6'h0;
   assign s_axis_c2h_ctrl_len = s_axis_c2h_ctrl_len_reg;

   assign s_axis_c2h_ctrl_qid = c2h_dsc_bypass[1:0] == 2'b10 ? pfch_byp_tag_qid : c2h_st_qid;
  
 // C2H Stream data CRC Generator
   crc32_gen #(
     .MAX_DATA_WIDTH   ( C_DATA_WIDTH      ),
     .CRC_WIDTH        ( CRC_WIDTH         )
   ) crc32_gen_c2h_i (
     // Clock and Resetd
     .clk              ( axi_aclk          ),
     .rst_n            ( axi_aresetn       ),
     .in_par_err       ( 1'b0              ),
     .in_misc_err      ( 1'b0              ),
     .in_crc_dis       ( 1'b0              ),

     .in_data          ( s_axis_c2h_tdata  ),
     .in_vld           ( (s_axis_c2h_tvalid & s_axis_c2h_tready) ),
     .in_tlast         ( s_axis_c2h_tlast  ),
     .in_mty           ( s_axis_c2h_mty_reg    ),
     .out_crc          ( s_axis_c2h_tcrc   )
   );

     ST_c2h #(
     .BIT_WIDTH   ( C_DATA_WIDTH ),
     .TM_DSC_BITS ( TM_DSC_BITS )
      )
     ST_c2h_0 
       (
	.axi_aclk    (axi_aclk),
	.axi_aresetn (axi_aresetn),
	.control_reg (c2h_control),
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
	.c2h_end     (c2h_end),
	.c2h_tready  (s_axis_c2h_tready)
  );

  ST_h2c #(
     .BIT_WIDTH         ( C_DATA_WIDTH ),
     .C_H2C_TUSER_WIDTH ( C_H2C_TUSER_WIDTH )
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
     .h2c_tuser_qid (m_axis_h2c_tuser_qid),
     .h2c_tuser_port_id (m_axis_h2c_tuser_port_id),
     .h2c_tuser_err (m_axis_h2c_tuser_err),
     .h2c_tuser_mdata (m_axis_h2c_tuser_mdata),
     .h2c_tuser_mty (m_axis_h2c_tuser_mty),
     .h2c_tuser_zero_byte (m_axis_h2c_tuser_zero_byte),
     .h2c_count   (h2c_count),
     .h2c_match   (h2c_match),
     .clr_match   (clr_h2c_match)
  );

   reg [C_DATA_WIDTH-1 :0]    m_axis_h2c_tdata_reg;
   reg 			      m_axis_h2c_tvalid_reg;
   reg 			      m_axis_h2c_tlast_reg;
   reg [CRC_WIDTH-1 : 0]      m_axis_h2c_tcrc_reg;
   reg [$clog2(C_DATA_WIDTH/8)-1 : 0]                m_axis_h2c_tuser_mty_reg;
   
   always @(posedge axi_aclk ) begin
      m_axis_h2c_tdata_reg      <= m_axis_h2c_tdata;
      m_axis_h2c_tvalid_reg     <= m_axis_h2c_tvalid;
      m_axis_h2c_tlast_reg      <= m_axis_h2c_tlast;
      m_axis_h2c_tcrc_reg       <= m_axis_h2c_tcrc;
      m_axis_h2c_tuser_mty_reg  <= m_axis_h2c_tuser_mty;
   end
  
 // C2H Stream data CRC Generator
   crc32_gen #(
     .MAX_DATA_WIDTH   ( C_DATA_WIDTH      ),
     .CRC_WIDTH        ( CRC_WIDTH         )
   ) crc32_gen_h2c_i (
     // Clock and Resetd
     .clk              ( axi_aclk          ),
     .rst_n            ( axi_aresetn       ),
     .in_par_err       ( 1'b0              ),
     .in_misc_err      ( 1'b0              ),
     .in_crc_dis       ( 1'b0              ),

     .in_data          ( m_axis_h2c_tdata_reg  ),
     .in_vld           ( m_axis_h2c_tvalid_reg ),
     .in_tlast         ( m_axis_h2c_tlast_reg  ),
     .in_mty           ( m_axis_h2c_tuser_mty_reg ),
     .out_crc          ( gen_h2c_tcrc   )
   );

   always @(posedge axi_aclk ) begin
      if (~axi_aresetn)
         h2c_crc_match <= 0;
      else if (( clr_h2c_match ) | ((m_axis_h2c_tlast_reg) & (m_axis_h2c_tcrc_reg != gen_h2c_tcrc)))
      	   h2c_crc_match <= 0;
      else if ((m_axis_h2c_tlast_reg) & (m_axis_h2c_tcrc_reg == gen_h2c_tcrc) )
      	   h2c_crc_match <= 1;
      end

localparam [1:0] 
	SM_IDL = 3'b00,
	SM_S1 = 3'b01,
        SM_S2 = 3'b10;
   
   assign start_c2h = c2h_control[1] & ~c2h_control[3];  // dont start if disable completions is set

   always @(posedge axi_aclk ) begin
      if (~axi_aresetn)
	start_imm <= 1'b0;
      else
	start_imm <= c2h_control[2] ? 1'b1 : s_axis_c2h_cmpt_tready ? 1'b0 : start_imm;
   end

   always @(posedge axi_aclk ) begin
      if (~axi_aresetn) begin
	 s_axis_c2h_tlast_nn1 <= 0;
	 c2h_st_d1 <= 0;
      end
      else begin
	 s_axis_c2h_tlast_nn1 <= s_axis_c2h_tlast;
	 c2h_st_d1 <= c2h_control[1];
      end
   end

   always @(posedge axi_aclk ) begin
      if (~axi_aresetn) begin
	 cmpt_count <= 0;
	 start_cmpt <= 0;
	 wb_sm <= SM_IDL;
	 cmpt_tvalid <= 0;
      end
      else 
	case (wb_sm)
	  SM_IDL : begin
	     if (start_c2h  | start_cmpt ) begin
		wb_sm <= SM_S1;
		start_cmpt <= 1;
	        cmpt_tvalid <= 1;
	     end
//	     cmpt_tvalid <= 0;
	     
	  end
	  SM_S1 : 
	    if (start_cmpt & s_axis_c2h_cmpt_tready & (cmpt_count < c2h_num_pkt)) begin
	       cmpt_tvalid <= 0;
	       cmpt_count <= (cmpt_count == (c2h_num_pkt-1)) ? 0 : cmpt_count + 1;
	       start_cmpt <= (cmpt_count == (c2h_num_pkt-1)) ? 0 : 1;
	       wb_sm <= SM_IDL;
	    end
	  default : 
	    wb_sm <= SM_IDL;
	endcase // case (wb_sm)
   end

   logic [15 : 0] cmp_par_val;  // fixed 512/32
   // Completione size information
   // cmpt_size[1:0] = 00 : 8Bytes of data 1 beat.
   // cmpt_size[1:0] = 01 : 16Bytes of data 1 beat.
   // cmpt_size[1:0] = 10 : 32Bytes of data 2 beat.
   assign s_axis_c2h_cmpt_size = byp_to_cmp ? 2'b11 : cmpt_size[1:0];
//   assign s_axis_c2h_cmpt_dpar = 'd0;
   assign s_axis_c2h_cmpt_dpar = ~cmp_par_val;
   
   always_comb begin
      for (integer i=0; i< 16; i += 1) begin // 512/32 fixed.
	 cmp_par_val[i] = ^s_axis_c2h_cmpt_tdata[i*32 +: 32];
      end
   end
   wire cmpt_user_fmt;
   assign cmpt_user_fmt = cmpt_size[2];  

   // write back data format
   // Standart format
   // 0 : data format. 0 = standard format, 1 = user defined.
   // [11:1] : QID
   // [19:12] : // reserved
   // [255:20] : User data.
   // this format should be same for two cycle if type is [1] is set.
   assign s_axis_c2h_cmpt_tdata =  byp_to_cmp ? {byp_data_to_cmp[511:4], 4'b0000} :
				   start_imm ? {wb_dat[255:0],wb_dat[255:4], 4'b0000} :          // dsc used is not set
   	  			   {wb_dat[255:0], wb_dat[255:20], c2h_st_len[15:0], 4'b1000};   // dsc used is set 

   assign s_axis_c2h_cmpt_tvalid = start_imm | cmpt_tvalid;

   assign s_axis_c2h_cmpt_ctrl_qid = c2h_st_qid;
//   assign s_axis_c2h_cmpt_ctrl_cmpt_type = cmpt_size[13:12];
   assign s_axis_c2h_cmpt_ctrl_cmpt_type = start_imm ? 2'b00 : cmpt_size[12] ? 2'b01 : 2'b11;
   assign s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id = cmpt_pkt_cnt[15:0];
   assign s_axis_c2h_cmpt_ctrl_marker = c2h_control[5];    // C2H Marker Enabled
   assign s_axis_c2h_cmpt_ctrl_user_trig = cmpt_size[3];
   assign s_axis_c2h_cmpt_ctrl_col_idx = cmpt_size[6:4];
   assign s_axis_c2h_cmpt_ctrl_err_idx = cmpt_size[10:8];
   
   always @(posedge axi_aclk) begin
      if (~axi_aresetn) begin
	 cmpt_pkt_cnt <= 1;
      end
      else begin
	 cmpt_pkt_cnt <=  (s_axis_c2h_cmpt_tvalid & s_axis_c2h_cmpt_tready) & ~start_imm ? cmpt_pkt_cnt+1 : cmpt_pkt_cnt;
      end
   end
/*
// Marker responce from QSTS interface.
   assign qsts_out_rdy = 1'b1;   // ready is always asserted
   always @(posedge axi_aclk ) begin
      if (~axi_aresetn) begin
         c2h_st_marker_rsp <= 1'b0;
         end
      else begin
         c2h_st_marker_rsp <= (c2h_control[5] & qsts_out_vld & (qsts_out_op == 8'b0)) ? 1'b1 : ~c2h_control[5] ? 1'b0 : c2h_st_marker_rsp;
         end
      end
*/
endmodule // axi_st_module

module crc32_gen #(
    parameter MAX_DATA_WIDTH    = 512,
    parameter CRC_WIDTH         = 32,
    parameter TCQ               = 1,
    parameter MTY_BITS          = $clog2(MAX_DATA_WIDTH/8)
) (
    // Clock and Resetd
    input                                  clk,
    input                                  rst_n,
    input                                  in_par_err,
    input                                  in_misc_err,
    input                                  in_crc_dis,


    input  [MAX_DATA_WIDTH-1:0]            in_data,
    input                                  in_vld,
    input                                  in_tlast,
    input  [MTY_BITS-1:0]                  in_mty,
    output logic [CRC_WIDTH-1:0]           out_crc
);


  localparam CRC_POLY = 32'b00000100110000010001110110110111;

  logic [CRC_WIDTH-1:0]             crc_var, crc_reg;
  logic                             sop_nxt,sop;
  logic                             out_par_err, out_par_err_reg;
  logic                             out_misc_err, out_misc_err_reg;

  logic [MAX_DATA_WIDTH-1:0]        data_mask;
  logic [MAX_DATA_WIDTH-1:0]        data_masked;
  always_comb begin
    data_mask   = ~in_tlast ? {MAX_DATA_WIDTH{1'b1}} : {MAX_DATA_WIDTH{1'b1}} >> {in_mty, 3'b0};
    data_masked = in_data & data_mask;
    crc_var     = crc_reg;
    sop_nxt     = sop;
    if (in_vld) begin
      if (sop) 
        crc_var = {CRC_WIDTH{1'b1}};
        
      for (int i=0; i<MAX_DATA_WIDTH; i=i+1) begin
        crc_var = {crc_var[CRC_WIDTH-1-1:0], 1'b0} ^ (CRC_POLY & {CRC_WIDTH{crc_var[CRC_WIDTH-1]^data_masked[MAX_DATA_WIDTH-i-1]}});
      end
      sop_nxt = in_tlast;
    end
  end

  always_comb begin
    out_par_err  = out_par_err_reg;
    out_misc_err = out_misc_err_reg;
    if (in_vld) begin
      out_par_err  = sop ? in_par_err : out_par_err_reg | in_par_err;
      out_misc_err = sop ? in_misc_err : out_misc_err_reg | in_misc_err;
    end
  end

  `XSRREG_XDMA(clk, rst_n, crc_reg, crc_var, 'h0)
  `XSRREG_XDMA(clk, rst_n, sop, sop_nxt, 'h1)
  `XSRREG_XDMA(clk, rst_n, out_par_err_reg, out_par_err, 'h0)
  `XSRREG_XDMA(clk, rst_n, out_misc_err_reg, out_misc_err, 'h0)

  //----------------------------------------------------------------
  // Update/Corrupt CRC for Parity and User Errors
  // Corrupt CRC LSB 2 bits for parity error
  // Corrupt CRC all bits for misc error
  //----------------------------------------------------------------
  always_comb begin
    out_crc          = crc_var;
    if (in_crc_dis)
      out_crc[1:0]   = {out_misc_err,out_par_err};
    else if (out_par_err) 
      out_crc[1:0]   = crc_var[1:0] ^ 2'h3;
    else if (out_misc_err) 
      out_crc        = crc_var ^ {CRC_WIDTH{1'b1}};
  end


endmodule // crc32_gen
