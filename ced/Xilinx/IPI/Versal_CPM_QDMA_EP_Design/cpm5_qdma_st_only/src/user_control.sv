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

module user_control #(
  parameter                    C_DATA_WIDTH = 64,
  parameter                    QID_MAX      = 64,
  parameter                    TM_DSC_BITS  = 16,
  parameter                    C_CNTR_WIDTH = 32
)(
  input 			user_clk,
  input 			user_reset_n,
  input 			m_axil_wvalid,
  input wire 			m_axil_wready,
  input [31:0] 			m_axil_awaddr,
  input [31:0] 			m_axil_wdata,
  output logic [31:0] 		m_axil_rdata,
  input [31:0] 			m_axil_rdata_bram,
  input [31:0] 			m_axil_araddr,
  output 			gen_user_reset_n,
  input 			axi_mm_h2c_valid,
  input 			axi_mm_h2c_ready,
  input 			axi_mm_c2h_valid,
  input 			axi_mm_c2h_ready,
  input 			axi_st_h2c_valid,
  input 			axi_st_h2c_ready,
  input 			axi_st_c2h_valid,
  input 			axi_st_c2h_ready,
  output reg [31:0] 		control_reg_c2h,
  output reg [31:0] 		control_reg_c2h2,
  output reg [10:0] 		c2h_num_pkt,
  output reg [10:0] 		c2h_st_qid,
  output 			clr_h2c_match,
  output reg [15:0] 		c2h_st_len,
  input 			h2c_match,
  input [10:0] 			h2c_qid,
  input [31:0] 			h2c_count,
  output reg [31:0] 		cmpt_size,
  output reg [255:0] 		wb_dat,
  output reg [TM_DSC_BITS-1:0] 	credit_out,
  output reg 			credit_updt,
  output reg [TM_DSC_BITS-1:0] 	credit_needed,
  output reg [TM_DSC_BITS-1:0] 	credit_perpkt_in,
  output wire [15:0] 		buf_count,
  input 			axis_c2h_drop,
  input 			axis_c2h_drop_valid,
  input 			c2h_st_marker_rsp,
  output reg [3:0] 		dsc_bypass,
  output wire [6:0] 		pfch_byp_tag,
  output wire [11:0] 		pfch_byp_tag_qid,

  // user flr and IRD
  input [11:0] 			usr_flr_fnc,
  input 			usr_flr_set,
  input 			usr_flr_clr,
  output reg [11:0] 		usr_flr_done_fnc,
  output reg 			usr_flr_done_vld,
  input 			usr_irq_out_fail,
  input 			usr_irq_out_ack,
  output reg [10:0] 		usr_irq_in_vec,
  output reg [11:0] 		usr_irq_in_fnc,
  output reg 			usr_irq_in_vld,

  // tm interface signals
  input 			tm_dsc_sts_vld,
  input 			tm_dsc_sts_qen,
  input 			tm_dsc_sts_byp,
  input 			tm_dsc_sts_dir,
  input 			tm_dsc_sts_mm,
  input [10:0] 			tm_dsc_sts_qid,
  input [TM_DSC_BITS-1:0] 	tm_dsc_sts_avl,
  input 			tm_dsc_sts_qinv,
  input 			tm_dsc_sts_irq_arm,
  output 			tm_dsc_sts_rdy,
  
  // H2C Checking
  input 			stat_vld,
  input [31:0] 			stat_err,
  
  // qid output signals
  input 			qid_rdy,
  output 			qid_vld,
  output [10:0] 		qid,
  output [16-1:0] 		qid_desc_avail,
  input 			desc_cnt_dec,
  input [10:0] 			desc_cnt_dec_qid,
  input 			requeue_vld,
  input [10:0] 			requeue_qid,
  output 			requeue_rdy,
  output reg [16-1:0] 		dbg_userctrl_credits,
  output reg [15:0] 		sdi_count_reg, // default set to 64
  
  // Performance counter signals
  output reg [C_CNTR_WIDTH-1:0] user_cntr_max,
  output reg 			user_cntr_rst,
  output wire 			user_cntr_read,
  input [C_CNTR_WIDTH-1:0] 	free_cnts,
  input [C_CNTR_WIDTH-1:0] 	idle_cnts,
  input [C_CNTR_WIDTH-1:0] 	busy_cnts,
  input [C_CNTR_WIDTH-1:0] 	actv_cnts,
  
  output reg [C_CNTR_WIDTH-1:0] h2c_user_cntr_max,
  output reg 			h2c_user_cntr_rst,
  output wire 			h2c_user_cntr_read,
  input [C_CNTR_WIDTH-1:0] 	h2c_free_cnts,
  input [C_CNTR_WIDTH-1:0] 	h2c_idle_cnts,
  input [C_CNTR_WIDTH-1:0] 	h2c_busy_cnts,
  input [C_CNTR_WIDTH-1:0] 	h2c_actv_cnts,

  // debug counters
  input [10:0] 			c2h_data_cnt_q0,
  input [10:0] 			c2h_data_cnt_q1,
  input [10:0] 			c2h_data_cnt_q2,
  input [10:0] 			c2h_data_cnt_q3,
  input [10:0] 			c2h_cmpt_cnt_q0,
  input [10:0] 			c2h_cmpt_cnt_q1,
  input [10:0] 			c2h_cmpt_cnt_q2,
  input [10:0] 			c2h_cmpt_cnt_q3,
  input [10:0] 			c2h_bypin_cnt_q0,
  input [10:0] 			c2h_bypin_cnt_q1,
  input [10:0] 			c2h_bypin_cnt_q2,
  input [10:0] 			c2h_bypin_cnt_q3,
  
  // l3fwd latency signals
  output reg [C_CNTR_WIDTH-1:0] user_l3fwd_max,
  output reg 			user_l3fwd_en,
  output reg 			user_l3fwd_mode,
  output reg 			user_l3fwd_rst,
  output wire 			user_l3fwd_read,
  
  input [C_CNTR_WIDTH-1:0] 	max_latency,
  input [C_CNTR_WIDTH-1:0] 	min_latency,
  input [C_CNTR_WIDTH-1:0] 	sum_latency,
  input [C_CNTR_WIDTH-1:0] 	num_pkt_rcvd
);

  reg            [9:0]  user_reset_counter; // Used to assert gen_user_reset_n

  reg            [31:0] control_reg_h2c;
  reg            [31:0] scratch_reg1, scratch_reg2;
  reg             [4:0] perf_ctl;
  reg                   control_h2c_clr;
  reg                   control_c2h_str;
  wire                  perf_stop;
  wire                  perf_clear;

  reg                   start_counter;
  wire                  start_c2h;
  reg            [63:0] data_count;
  reg            [63:0] valid_count;
  reg            [15:0] c2h_st_buffsz;

  reg [TM_DSC_BITS-1:0] credit_avl [0:QID_MAX];
  reg                   tm_vld_out;
  reg             [7:0] axis_pkt_drop;
  reg             [7:0] axis_pkt_accept;
  
  reg            [31:0] h2c_stat;
  reg                   c2h_stat;
  
  wire            [7:0] qid_short; // A temporary reduction of QID width
   reg           [31:0]	pfch_byp_tag_reg;
   reg [31:0]      usr_irq;
   reg             usr_irq_fail;
   reg             usr_irq_d;
   

//  assign qid = {{4{1'b0}}, qid_short};
  assign qid = ( 'h0 | qid_short);
  
  always @ (posedge user_clk) begin
    if (~user_reset_n) begin
      h2c_stat <= 32'h0;
    end else begin
      if (clr_h2c_match)
        h2c_stat <= 32'h0;
      else
        h2c_stat <= stat_vld ? stat_err : h2c_stat;
    end
  end
  
  always @ (posedge user_clk) begin
    if (~user_reset_n) begin
      c2h_stat <= 1'b0;
    end else begin
      if (~control_reg_c2h[5]) // Clear marker response when marker request is cleared
        c2h_stat <= 1'b0;
      else
        c2h_stat <= c2h_st_marker_rsp ? 1'b1 : c2h_stat;
    end
  end
  
  // Checking FLR request and provide ack
   
    always @ (posedge user_clk) begin
      if (~user_reset_n) begin
         usr_flr_done_fnc <= 'h0;
	 usr_flr_done_vld <= 0;
	 
      end
      else begin
	 usr_flr_done_vld <= usr_flr_set;
	 usr_flr_done_fnc <= usr_flr_set ? usr_flr_fnc : 'h0;
      end
   end

 
  //
  // To Control AXI-Stream pattern generator and checker
  //
  // address 0x0000 : Qid 
  // address 0x0004 : C2H transfer length
  // address 0x0008 : C2H Control
  //                  [0] loog back  // not supported now
  //                  [1] start C2H
  //                  [2] Immediate data
  //                  [3] Every packet starts with 00 insted of continous data stream until number of pakets is complete
  //                  [5] Send Marker
  //                  [18] Stop data traffic immediately
  //                  [21] Stop CMPT traffic immediately
  //                  [28:24] Batching credits. 0 : 1 credit per Q, 7 : 8 credit per Q (+1)
  //                  [30] Hold C2h credit input so no data will be filled in FIFO. 
  //                  [31] gen_user_reset_n
  // address 0x00C0 : H2C Control
  //                  [0] clear match for H2C transfer
  // address 0x0010 : H2C Qid, 3'b0, h2c transfer match // Read only
  // address 0x0014 : H2C tranfer count // Read only
  // address 0x0020 : C2H number of packets to transfer
  // address 0x0030 : C2H Write back data [31:0]
  // address 0x0034 : C2H Write back data [63:32]
  // address 0x0038 : C2H Write back data [95:64]
  // address 0x003C : C2H Write back data [127:96]
  // address 0x0040 : C2H Write back data [159:128]
  // address 0x0044 : C2H Write back data [191:160]
  // address 0x0048 : C2H Write back data [223:192]
  // address 0x004C : C2H Write back data [255:224]
  // address 0x0050 : C2H Write back type [31:0]
  // address 0x0060 : Scratch pad reg0 
  // address 0x0064 : Scratch pad reg1
  // address 0x0070 : Performance control
  //                  [0] start
  //                  [1] end
  //                  [2] clear
  //                  [4:3] : 00 AXI-MM H2C, 01 AXI-MM C2H
  //                        : 10 AXI-ST H2C, 11 AXI-ST C2H
  // address 0x0074 : Performance data count [31:0]
  // address 0x0078 : Performance data count [63:30]
  // address 0x007C : Performance valid count [31:0]
  // address 0x0080 : Performance valid count [63:30]
  // address 0x0084 : C2H Streaming Buffer size, default 4K
  // address 0x0088 : C2H Streaming packet drop count
  // address 0x008C : C2H Streaming packet accepted 
   
  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      c2h_st_qid       <= 1;
      c2h_st_len       <= 16'h80;  // default transfer size set to 128Bytes
      control_reg_h2c  <= 32'h0;
      control_reg_c2h  <= 32'h09000000;    // setting default batch to 9
      control_reg_c2h2 <= 32'h0 | QID_MAX; // Initialize to the QID_MAX supported by the design
      wb_dat[255:0]    <= 0;
      cmpt_size[31:0]  <= 0;
      c2h_num_pkt      <= 11'h1;
      perf_ctl         <= 0;
//      perf_ctl         <= 5'b11001;
      scratch_reg1     <= 'h20230606; // After reset it holds the bitfile version number. In Decimal YYMMDDRev
      scratch_reg2     <=0;
      c2h_st_buffsz    <=16'h1000;  // default buff size 4K
      dbg_userctrl_credits<='d64;   // default to 64B
      user_cntr_rst    <=1'b0;
      user_cntr_max    <=0;
      h2c_user_cntr_rst    <=1'b0;
      h2c_user_cntr_max    <=0;
      h2c_user_cntr_max    <=0;
      user_l3fwd_mode      <=1'b0;
      user_l3fwd_en        <=1'b0;
      user_l3fwd_rst       <=1'b0;
      dsc_bypass           <=4'h0;
      pfch_byp_tag_reg     <=32'h0;
      sdi_count_reg        <=32'h8;
      usr_irq              <= 'h0;
    end else 
    if (m_axil_wvalid && m_axil_wready ) begin
      case (m_axil_awaddr[15:0])
        16'h00 : c2h_st_qid         <= m_axil_wdata[10:0];
        16'h04 : c2h_st_len         <= m_axil_wdata[15:0];
        16'h08 : control_reg_c2h    <= m_axil_wdata[31:0];
        16'h0C : control_reg_h2c    <= m_axil_wdata[31:0];
        16'h20 : c2h_num_pkt[10:0]  <= m_axil_wdata[10:0];
        16'h24 : pfch_byp_tag_reg   <= m_axil_wdata[31:0];
        16'h30 : wb_dat[31:0]       <= m_axil_wdata[31:0];
        16'h34 : wb_dat[63:32]      <= m_axil_wdata[31:0];
        16'h38 : wb_dat[95:64]      <= m_axil_wdata[31:0];
        16'h3C : wb_dat[127:96]     <= m_axil_wdata[31:0];
        16'h40 : wb_dat[159:128]    <= m_axil_wdata[31:0];
        16'h44 : wb_dat[191:160]    <= m_axil_wdata[31:0];
        16'h48 : wb_dat[223:192]    <= m_axil_wdata[31:0];
        16'h4C : wb_dat[255:224]    <= m_axil_wdata[31:0];
        16'h50 : cmpt_size[31:0]    <= m_axil_wdata[31:0];
        16'h58 : sdi_count_reg      <= m_axil_wdata[31:0];
        16'h60 : scratch_reg1[31:0] <= m_axil_wdata[31:0];
        16'h64 : scratch_reg2[31:0] <= m_axil_wdata[31:0];
        16'h68 : usr_irq[31:0]      <= m_axil_wdata[31:0];
        16'h70 : perf_ctl[4:0]      <= m_axil_wdata[4:0];
        16'h84 : c2h_st_buffsz      <= m_axil_wdata[15:0];
        16'h90 : dbg_userctrl_credits <= m_axil_wdata[15:0];
        16'h94 : control_reg_c2h2     <= m_axil_wdata[31:0];
        16'h98 : dsc_bypass           <= m_axil_wdata[3:0];
        16'h9C : user_cntr_max[31:0]  <= m_axil_wdata[31:0];
        16'hA0 : user_cntr_max[63:32] <= m_axil_wdata[31:0];
        16'hA4 : user_cntr_rst        <= m_axil_wdata[0];
        16'hC8 : h2c_user_cntr_max[31:0]  <= m_axil_wdata[31:0];
        16'hCC : h2c_user_cntr_max[63:32] <= m_axil_wdata[31:0];
        16'hD0 : h2c_user_cntr_rst        <= m_axil_wdata[0];
        16'h100: user_l3fwd_max[31:0]     <= m_axil_wdata[31:0];
        16'h104: user_l3fwd_max[63:32]    <= m_axil_wdata[31:0];
        16'h108: {user_l3fwd_mode, user_l3fwd_en, user_l3fwd_rst} <= m_axil_wdata[2:0];
      endcase // case (m_axil_awaddr[15:0])
    end // if (m_axil_wvalid && m_axil_wready )
    else begin
      control_reg_c2h <= {control_reg_c2h[31:2],start_c2h,control_reg_c2h[0]};
      control_reg_h2c <= {control_reg_h2c[31:1],clr_h2c_match};
      perf_ctl[4:0] <= {perf_ctl[4:3],perf_clear,perf_stop, (perf_ctl[0]& ~perf_stop)};
      usr_irq[31:0] <= {usr_irq[31:1],usr_irq_in_vld};
      if (user_reset_counter[8]) begin // 256 clock cycle
        control_reg_c2h[31] <= 1'b0;
      end
      
    end
  end // always @ (posedge user_clk)

  always_comb begin
    case (m_axil_araddr[15:0])
      16'h00 : m_axil_rdata <= (32'h0 | c2h_st_qid[10:0]);
      16'h04 : m_axil_rdata <= (32'h0 | c2h_st_len);
      16'h08 : m_axil_rdata <= (32'h0 | control_reg_c2h[31:0]);
      16'h0C : m_axil_rdata <= (32'h0 | control_reg_h2c[31:0]);
      16'h10 : m_axil_rdata <= (32'h0 | {h2c_qid[10:0],3'b0,h2c_match});
      16'h14 : m_axil_rdata <= h2c_stat;
      16'h18 : m_axil_rdata <= (32'h0 | c2h_stat);
      16'h20 : m_axil_rdata <= (32'h0 | c2h_num_pkt[10:0]);
      16'h24 : m_axil_rdata <= (32'h0 | pfch_byp_tag_reg );
      16'h30 : m_axil_rdata <= wb_dat[31:0];
      16'h34 : m_axil_rdata <= wb_dat[63:32];
      16'h38 : m_axil_rdata <= wb_dat[95:64];
      16'h3C : m_axil_rdata <= wb_dat[127:96];
      16'h40 : m_axil_rdata <= wb_dat[159:128];
      16'h44 : m_axil_rdata <= wb_dat[191:160];
      16'h48 : m_axil_rdata <= wb_dat[223:192];
      16'h4C : m_axil_rdata <= wb_dat[255:224];
      16'h50 : m_axil_rdata <= cmpt_size[31:0];
      16'h58 : m_axil_rdata <= (32'h0 | sdi_count_reg );
      16'h60 : m_axil_rdata <= scratch_reg1[31:0];
      16'h64 : m_axil_rdata <= scratch_reg2[31:0];
      16'h68 : m_axil_rdata <= {usr_irq_fail,  usr_irq[30:0]};
      16'h70 : m_axil_rdata <= {32'h0 | perf_ctl[4:0]};
      16'h74 : m_axil_rdata <= data_count[31:0];
      16'h78 : m_axil_rdata <= data_count[63:32];
      16'h7C : m_axil_rdata <= valid_count[31:0];
      16'h80 : m_axil_rdata <= valid_count[63:32];
      16'h84 : m_axil_rdata <= c2h_st_buffsz[15:0];
      16'h88 : m_axil_rdata <= {32'h0 | axis_pkt_drop[7:0]};
      16'h8C : m_axil_rdata <= {32'h0 | axis_pkt_accept[7:0]};
      16'h90 : m_axil_rdata <= {32'h0 | dbg_userctrl_credits};
      16'h94 : m_axil_rdata <= (32'h0 | control_reg_c2h2[31:0]);
      16'h98 : m_axil_rdata <= {32'h0 | dsc_bypass[3:0]};
      16'h9C : m_axil_rdata <= (32'h0 | user_cntr_max[31:0]);
      16'hA0 : m_axil_rdata <= (32'h0 | user_cntr_max[63:32]);
      16'hA4 : m_axil_rdata <= (32'h0 | user_cntr_rst);
      16'hA8 : m_axil_rdata <= (32'h0 | free_cnts[31:0]);
      16'hAC : m_axil_rdata <= (32'h0 | free_cnts[63:32]);
      16'hB0 : m_axil_rdata <= (32'h0 | idle_cnts[31:0]);
      16'hB4 : m_axil_rdata <= (32'h0 | idle_cnts[63:32]);
      16'hB8 : m_axil_rdata <= (32'h0 | busy_cnts[31:0]);
      16'hBC : m_axil_rdata <= (32'h0 | busy_cnts[63:32]);
      16'hC0 : m_axil_rdata <= (32'h0 | actv_cnts[31:0]);
      16'hC4 : m_axil_rdata <= (32'h0 | actv_cnts[63:32]);
      16'hC8 : m_axil_rdata <= (32'h0 | h2c_user_cntr_max[31:0]);
      16'hCC : m_axil_rdata <= (32'h0 | h2c_user_cntr_max[63:32]);
      16'hD0 : m_axil_rdata <= (32'h0 | h2c_user_cntr_rst);
      16'hD4 : m_axil_rdata <= (32'h0 | h2c_free_cnts[31:0]);
      16'hD8 : m_axil_rdata <= (32'h0 | h2c_free_cnts[63:32]);
      16'hDC : m_axil_rdata <= (32'h0 | h2c_idle_cnts[31:0]);
      16'hE0 : m_axil_rdata <= (32'h0 | h2c_idle_cnts[63:32]);
      16'hE4 : m_axil_rdata <= (32'h0 | h2c_busy_cnts[31:0]);
      16'hE8 : m_axil_rdata <= (32'h0 | h2c_busy_cnts[63:32]);
      16'hEC : m_axil_rdata <= (32'h0 | h2c_actv_cnts[31:0]);
      16'hF0 : m_axil_rdata <= (32'h0 | h2c_actv_cnts[63:32]);
      16'h100: m_axil_rdata <= (32'h0 | user_l3fwd_max[31:0]);
      16'h104: m_axil_rdata <= (32'h0 | user_l3fwd_max[63:32]);
      16'h108: m_axil_rdata <= (32'h0 | {user_l3fwd_mode, user_l3fwd_en, user_l3fwd_rst});
      16'h10C: m_axil_rdata <= (32'h0 | max_latency[31:0]);
      16'h110: m_axil_rdata <= (32'h0 | max_latency[63:32]);
      16'h114: m_axil_rdata <= (32'h0 | min_latency[31:0]);
      16'h118: m_axil_rdata <= (32'h0 | min_latency[63:32]);
      16'h11C: m_axil_rdata <= (32'h0 | sum_latency[31:0]);
      16'h120: m_axil_rdata <= (32'h0 | sum_latency[63:32]);
      16'h124: m_axil_rdata <= (32'h0 | num_pkt_rcvd[31:0]);
      16'h128: m_axil_rdata <= (32'h0 | num_pkt_rcvd[63:32]);
      16'h130: m_axil_rdata <= (32'h0 | {c2h_data_cnt_q1, 5'b0, c2h_data_cnt_q0});
      16'h134: m_axil_rdata <= (32'h0 | {c2h_data_cnt_q3, 5'b0, c2h_data_cnt_q2});
      16'h138: m_axil_rdata <= (32'h0 | {c2h_cmpt_cnt_q1, 5'b0, c2h_cmpt_cnt_q0});
      16'h13C: m_axil_rdata <= (32'h0 | {c2h_cmpt_cnt_q3, 5'b0, c2h_cmpt_cnt_q2});
      16'h140: m_axil_rdata <= (32'h0 | {c2h_bypin_cnt_q1, 5'b0, c2h_bypin_cnt_q0});
      16'h144: m_axil_rdata <= (32'h0 | {c2h_bypin_cnt_q3, 5'b0, c2h_bypin_cnt_q2});
      default: m_axil_rdata <= m_axil_rdata_bram;
    endcase // case (m_axil_araddr[31:0]...
  end // always_comb begin

  assign pfch_byp_tag[6:0]      = pfch_byp_tag_reg[6:0];
  assign pfch_byp_tag_qid[11:0] = pfch_byp_tag_reg[27:16]; 
  
  // Clear Performance Counter once all counters are read
  reg [7:0] user_fiba_read;      // [7/6] = F/ree_cnts read; [5/4] = I/dle_cnts read; [3/2] = B/usy_cnts read; [1/0] = A/ctv_cnts read
  assign user_cntr_read = &user_fiba_read;
  
  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      user_fiba_read <= 8'b0;
    end else begin
      user_fiba_read[0] <= (user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hA8) ? 1'b1 : user_fiba_read[0]);
      user_fiba_read[1] <= (user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hAC) ? 1'b1 : user_fiba_read[1]);
      user_fiba_read[2] <= (user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hB0) ? 1'b1 : user_fiba_read[2]);
      user_fiba_read[3] <= (user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hB4) ? 1'b1 : user_fiba_read[3]);
      user_fiba_read[4] <= (user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hB8) ? 1'b1 : user_fiba_read[4]);
      user_fiba_read[5] <= (user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hBC) ? 1'b1 : user_fiba_read[5]);
      user_fiba_read[6] <= (user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hC0) ? 1'b1 : user_fiba_read[6]);
      user_fiba_read[7] <= (user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hC4) ? 1'b1 : user_fiba_read[7]);
    end
  end
  
  reg [7:0] h2c_user_fiba_read;      // [7/6] = F/ree_cnts read; [5/4] = I/dle_cnts read; [3/2] = B/usy_cnts read; [1/0] = A/ctv_cnts read
  assign h2c_user_cntr_read = &h2c_user_fiba_read;
  
  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      h2c_user_fiba_read <= 8'b0;
    end else begin
      h2c_user_fiba_read[0] <= (h2c_user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hD4) ? 1'b1 : h2c_user_fiba_read[0]);
      h2c_user_fiba_read[1] <= (h2c_user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hD8) ? 1'b1 : h2c_user_fiba_read[1]);
      h2c_user_fiba_read[2] <= (h2c_user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hDC) ? 1'b1 : h2c_user_fiba_read[2]);
      h2c_user_fiba_read[3] <= (h2c_user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hE0) ? 1'b1 : h2c_user_fiba_read[3]);
      h2c_user_fiba_read[4] <= (h2c_user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hE4) ? 1'b1 : h2c_user_fiba_read[4]);
      h2c_user_fiba_read[5] <= (h2c_user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hE8) ? 1'b1 : h2c_user_fiba_read[5]);
      h2c_user_fiba_read[6] <= (h2c_user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hEC) ? 1'b1 : h2c_user_fiba_read[6]);
      h2c_user_fiba_read[7] <= (h2c_user_cntr_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'hF0) ? 1'b1 : h2c_user_fiba_read[7]);
    end
  end
  
  reg [7:0] l3fwd_mmsn_read;      // [7/6] = max_latency read; [5/4] = min_latency read; [3/2] = sum_latency read; [1/0] = num_pkt_rcvd read
  assign user_l3fwd_read = &l3fwd_mmsn_read;
  
  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      l3fwd_mmsn_read <= 8'b0;
    end else begin
      l3fwd_mmsn_read[0] <= (user_l3fwd_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'h10C) ? 1'b1 : l3fwd_mmsn_read[0]);
      l3fwd_mmsn_read[1] <= (user_l3fwd_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'h110) ? 1'b1 : l3fwd_mmsn_read[1]);
      l3fwd_mmsn_read[2] <= (user_l3fwd_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'h114) ? 1'b1 : l3fwd_mmsn_read[2]);
      l3fwd_mmsn_read[3] <= (user_l3fwd_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'h118) ? 1'b1 : l3fwd_mmsn_read[3]);
      l3fwd_mmsn_read[4] <= (user_l3fwd_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'h11C) ? 1'b1 : l3fwd_mmsn_read[4]);
      l3fwd_mmsn_read[5] <= (user_l3fwd_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'h120) ? 1'b1 : l3fwd_mmsn_read[5]);
      l3fwd_mmsn_read[6] <= (user_l3fwd_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'h124) ? 1'b1 : l3fwd_mmsn_read[6]);
      l3fwd_mmsn_read[7] <= (user_l3fwd_read) ? 1'b0 : ( (m_axil_araddr[15:0] == 16'h128) ? 1'b1 : l3fwd_mmsn_read[7]);
    end
  end
  
  reg perf_ctl_stp;
  reg perf_ctl_clr;

  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      control_h2c_clr <= 0;
      control_c2h_str <= 0;
      perf_ctl_stp <= 0;
      perf_ctl_clr <= 0;
    end
    else begin
      control_h2c_clr <= control_reg_h2c[0];
      control_c2h_str <= control_reg_c2h[1];
      perf_ctl_stp <=  perf_ctl[1];
      perf_ctl_clr <=  perf_ctl[2];
    end
  end
  
  assign clr_h2c_match = control_reg_h2c[0] & ~control_h2c_clr;
  assign start_c2h = control_reg_c2h[1] & ~control_c2h_str;
  assign perf_stop = perf_ctl[1] & ~perf_ctl_stp;
  assign perf_clear = perf_ctl[2] & ~perf_ctl_clr;
  
  always @(posedge user_clk) begin
    if (~control_reg_c2h[31]) begin
      user_reset_counter <= 0;
    end else begin // (control_reg_c2h[31])
      user_reset_counter <= user_reset_counter + 1;
    end
  end
  assign gen_user_reset_n = ~control_reg_c2h[31];
  
  wire perf_start = perf_ctl[0];
  // Performance 
  wire      valids;
  wire      readys;
  assign valids = axi_mm_h2c_valid | axi_mm_c2h_valid | axi_st_h2c_valid | axi_st_c2h_valid;
  assign readys = axi_mm_h2c_ready | axi_mm_c2h_ready | axi_st_h2c_ready | axi_st_c2h_ready;

  reg       valids_d1;
  wire      valids_pls;
  wire      vld_rdys_pls;
  
  always @(posedge user_clk) begin
    if (!user_reset_n | perf_stop) begin
      valids_d1 <= 1'b0;
    end
    else if (~valids_d1) begin
      valids_d1 <= valids;
    end
  end
   
  assign valids_pls   = valids & ~valids_d1;
  assign vld_rdys_pls = (valids & ~valids_d1) & readys;
  
  always @(posedge user_clk) begin
    if (!user_reset_n | perf_stop) begin
      start_counter <= 0;      end
    else if (perf_start & valids & readys) begin
      start_counter <= 1'b1;
    end
  end
   
  always @(posedge user_clk) begin
    if (!user_reset_n | perf_clear) begin
      data_count  <= 0;
      valid_count <= 0;
    end
    else begin
      case (perf_ctl[4:3])
        2'b00 : begin
          data_count  <= ((vld_rdys_pls | start_counter) && axi_mm_h2c_valid && axi_mm_h2c_ready) ? data_count+1 :data_count;
          valid_count <= (valids_pls | start_counter) ? valid_count + 1 : valid_count;
        end
        2'b01 : begin
          data_count  <= ((vld_rdys_pls | start_counter) && axi_mm_c2h_valid && axi_mm_c2h_ready) ? data_count+1 :data_count;
          valid_count <= (valids_pls | start_counter) ? valid_count + 1 : valid_count;
        end
        2'b10 : begin
          data_count  <= ((vld_rdys_pls | start_counter) && axi_st_h2c_valid && axi_st_h2c_ready) ? data_count+1 :data_count;
          valid_count <= (valids_pls | start_counter) ? valid_count + 1 : valid_count;
        end
        2'b11 : begin
          data_count  <= ((vld_rdys_pls | start_counter) && axi_st_c2h_valid && axi_st_c2h_ready) ? data_count+1 :data_count;
          valid_count <= (valids_pls | start_counter) ? valid_count + 1 : valid_count;
        end
      endcase // case (perf_sel[1:0])
    end
  end // always @ (posedge user_clk)

 
  // Traffic Manager and Queue Manager
  queue_cnts # (
    .DIR              ( 1           ), // C2H
    .DESC_CNT_WIDTH   ( 16          ),
    .DESC_AVAIL_WIDTH ( TM_DSC_BITS ),
//    .MAX_QUEUES       ( 128         ), // Limiting to 128 because 11 bits QID is using too much logic
    .MAX_QUEUES       ( QID_MAX     ), // Limiting to 128 because 11 bits QID is using too much logic
    .QUEUE_ID_WIDTH   ( 8           )  // Limiting to 128 because 11 bits QID is using too much logic
  
  ) queue_cnts_i (
  
    .user_clk           ( user_clk           ),
    .user_reset_n       ( user_reset_n & gen_user_reset_n ),
    .knob                ( {31'h0,control_reg_c2h[30]}), 

  // tm interface signals
    .tm_dsc_sts_vld     ( tm_dsc_sts_vld     ),
    .tm_dsc_sts_qen     ( tm_dsc_sts_qen     ),
    .tm_dsc_sts_byp     ( tm_dsc_sts_byp     ), // 0=desc fetched from host; 1=desc came from descriptory bypass
    .tm_dsc_sts_dir     ( tm_dsc_sts_dir     ), // 0=H2C; 1=C2H
    .tm_dsc_sts_mm      ( tm_dsc_sts_mm      ), // 0=ST; 1=MM
//    .tm_dsc_sts_qid     ( tm_dsc_sts_qid     ), // QID for update
    .tm_dsc_sts_qid     ( tm_dsc_sts_qid[7:0] ), // QID for update
    .tm_dsc_sts_avl     ( tm_dsc_sts_avl     ), // Number of new descriptors since last update
    .tm_dsc_sts_qinv    ( tm_dsc_sts_qinv    ), // 1 indicated to invalidate the queue
    .tm_dsc_sts_irq_arm ( tm_dsc_sts_irq_arm ), // 1 indicated to that the driver is using interrupts
    .tm_dsc_sts_rdy     ( tm_dsc_sts_rdy     ), // 1 indicates valid data on the bus

  // qid output signals
    .qid_rdy            ( qid_rdy            ), // ready for the next queue id
    .qid_vld            ( qid_vld            ), // current qid and availability are valid
//    .qid                ( qid                ),    
    .qid                ( qid_short          ),
    .qid_desc_avail     ( qid_desc_avail     ),
    .desc_cnt_dec       ( desc_cnt_dec       ), // decrement the qid count by 1
    .desc_cnt_dec_qid   ( desc_cnt_dec_qid[7:0] ), // qid for desc_cnt_dec signal
    .requeue_vld        ( requeue_vld        ), // requeue the specified qid
    .requeue_qid        ( requeue_qid[7:0]   ), // qid to be requeued
    .requeue_rdy        ( requeue_rdy        ), // requeue accepted
    .back_pres          ( control_reg_c2h[4] ),
    .turn_off           ( control_reg_c2h[3] )
  
  );
  
  //assign m_axil_wready = 1'b1;

   //USR IRQ
   assign usr_irq_in_vec = {6'h0,usr_irq[8:4]};   // vector
   assign usr_irq_in_fnc = usr_irq[22:12]; // function number

   always @(posedge user_clk) begin
     if (~user_reset_n) begin
          usr_irq_d <= 1'b0;
          usr_irq_in_vld <= 1'b0;
	  usr_irq_fail <= 1'b0;
     end	      
     else begin
	  usr_irq_d <= usr_irq[0];
          usr_irq_in_vld <= (usr_irq[0] & ~usr_irq_d) ? 1'b1 : (usr_irq_out_ack) ? 1'b0 : usr_irq_in_vld;
	
	  usr_irq_fail <= usr_irq_out_fail ? 1'b1 : (m_axil_wvalid && m_axil_wready && (m_axil_awaddr ==16'h68) && m_axil_wdata[0]) ? 1'b0 : usr_irq_fail;
	
     end 
   end // always @ (posedge axi_aclk)
   
   
endmodule // user_control
