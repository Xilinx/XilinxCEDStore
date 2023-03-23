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
// File       : user_control.sv
// Version    : 5.0
//-----------------------------------------------------------------------------

`timescale 1ps / 1ps

module user_control #(
  parameter                    C_DATA_WIDTH = 64,
  parameter                    QID_MAX      = 64,
  parameter                    TM_DSC_BITS  = 16,
  parameter                    C_CNTR_WIDTH = 32
)(
  input                        user_clk,
  input                        user_reset_n,
  input                        wen, 
  input                 [11:0] waddr,
  input                 [31:0] wdata,
  input                        ren,
  output reg                   rvalid,
  input                        rdone,
  input                 [11:0] raddr,
  output reg            [31:0] rdata,
  output                       gen_user_reset_n,
  input                        axi_mm_h2c_valid,
  input                        axi_mm_h2c_ready,
  input                        axi_mm_c2h_valid,
  input                        axi_mm_c2h_ready,
  input                        axi_st_h2c_valid,
  input                        axi_st_h2c_ready,
  input                        axi_st_c2h_valid,
  input                        axi_st_c2h_ready,
  output reg            [31:0] control_reg_c2h,
  output reg            [31:0] control_reg_c2h2,
  output reg            [10:0] c2h_num_pkt,
  output reg            [10:0] c2h_st_qid,
  output                       clr_h2c_match,
  output reg            [15:0] c2h_st_len,
  input                        h2c_match,
  input                 [10:0] h2c_qid,
  input                 [31:0] h2c_count,
  output reg            [31:0] cmpt_size,
  output reg           [255:0] wb_dat,
  output reg [TM_DSC_BITS-1:0] credit_out,
  output reg                   credit_updt,
  output reg [TM_DSC_BITS-1:0] credit_needed,
  output reg [TM_DSC_BITS-1:0] credit_perpkt_in,
  output wire           [15:0] buf_count,
  input                        axis_c2h_drop,
  input                        axis_c2h_drop_valid,
  input                        c2h_st_marker_rsp,
  
  // tm interface signals
  input                        tm_dsc_sts_vld,
  input                        tm_dsc_sts_qen,
  input                        tm_dsc_sts_byp,
  input                        tm_dsc_sts_dir,
  input                        tm_dsc_sts_mm,
  input                 [10:0] tm_dsc_sts_qid,
  input      [TM_DSC_BITS-1:0] tm_dsc_sts_avl,
  input                        tm_dsc_sts_qinv,
  input                        tm_dsc_sts_irq_arm,
  output                       tm_dsc_sts_rdy,
  
  // H2C Checking
  input                        stat_vld,
  input                 [31:0] stat_err,
  
  // qid output signals
  input                        qid_rdy,
  output                       qid_vld,
  output                [10:0] qid,
  output              [16-1:0] qid_desc_avail,
  input                        desc_cnt_dec,
  input                 [10:0] desc_cnt_dec_qid,
  input                        requeue_vld,
  input                 [10:0] requeue_qid,
  output                       requeue_rdy,
  output reg          [16-1:0] dbg_userctrl_credits,
  
  // Performance counter signals
  output reg [C_CNTR_WIDTH-1:0] c2h_user_cntr_max,
  output reg                    c2h_user_cntr_rst,
  output wire                   c2h_user_cntr_read,
  input      [C_CNTR_WIDTH-1:0] c2h_free_cnts,
  input      [C_CNTR_WIDTH-1:0] c2h_idle_cnts,
  input      [C_CNTR_WIDTH-1:0] c2h_busy_cnts,
  input      [C_CNTR_WIDTH-1:0] c2h_actv_cnts,
  
  output reg [C_CNTR_WIDTH-1:0] h2c_user_cntr_max,
  output reg                    h2c_user_cntr_rst,
  output wire                   h2c_user_cntr_read,
  input      [C_CNTR_WIDTH-1:0] h2c_free_cnts,
  input      [C_CNTR_WIDTH-1:0] h2c_idle_cnts,
  input      [C_CNTR_WIDTH-1:0] h2c_busy_cnts,
  input      [C_CNTR_WIDTH-1:0] h2c_actv_cnts,
  
  // l3fwd latency signals
  output reg [C_CNTR_WIDTH-1:0] user_l3fwd_max,
  output reg                    user_l3fwd_en,
  output reg                    user_l3fwd_mode,
  output reg                    user_l3fwd_rst,
  output wire                   user_l3fwd_read,
  
  input      [C_CNTR_WIDTH-1:0] max_latency,
  input      [C_CNTR_WIDTH-1:0] min_latency,
  input      [C_CNTR_WIDTH-1:0] sum_latency,
  input      [C_CNTR_WIDTH-1:0] num_pkt_rcvd
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
  
  wire            [6:0] qid_short; // A temporary reduction of QID width
  assign qid = {{4{1'b0}}, qid_short};
  
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
  
  
  //
  // To Control AXI-Stream pattern generator and checker
  //
  // address 0x0000 : Qid 
  // address 0x0004 : C2H transfer length
  // address 0x0008 : C2H Control
  //                  [0] loopback  // not supported now
  //                  [1] start C2H
  //                  [2] Immediate data
  //                  [3] Every packet starts with 00 insted of continous data 
  //                      stream until number of packets is complete
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
      control_reg_c2h  <= 32'h0;
      control_reg_c2h2 <= 32'h0 | QID_MAX; // Initialize to the QID_MAX supported by the design
      wb_dat[255:0]    <= 0;
      cmpt_size[31:0]  <= 0;
      c2h_num_pkt      <= 11'h1;
      perf_ctl         <= 0;
      scratch_reg1     <= 'd1809051; // After reset it holds the bitfile version number. In Decimal YYMMDDRev
      scratch_reg2     <= 0;
      c2h_st_buffsz    <= 16'h1000;  // default buff size 4K
      dbg_userctrl_credits <= 'd64;   // default to 64B
      c2h_user_cntr_rst    <= 1'b0;
      c2h_user_cntr_max    <= 0;
      h2c_user_cntr_rst    <= 1'b0;
      h2c_user_cntr_max    <= 0;
      h2c_user_cntr_max    <= 0;
      user_l3fwd_mode      <= 1'b0;
      user_l3fwd_en        <= 1'b0;
      user_l3fwd_rst       <= 1'b0;
    end else 
    if (wen) begin
      case (waddr[11:0])
        12'h00 : c2h_st_qid               <= wdata[10:0];
        12'h04 : c2h_st_len               <= wdata[15:0];
        12'h08 : control_reg_c2h          <= wdata[31:0];
        12'h0C : control_reg_h2c          <= wdata[31:0];
        12'h20 : c2h_num_pkt[10:0]        <= wdata[10:0];
        12'h30 : wb_dat[31:0]             <= wdata[31:0];
        12'h34 : wb_dat[63:32]            <= wdata[31:0];
        12'h38 : wb_dat[95:64]            <= wdata[31:0];
        12'h3C : wb_dat[127:96]           <= wdata[31:0];
        12'h40 : wb_dat[159:128]          <= wdata[31:0];
        12'h44 : wb_dat[191:160]          <= wdata[31:0];
        12'h48 : wb_dat[223:192]          <= wdata[31:0];
        12'h4C : wb_dat[255:224]          <= wdata[31:0];
        12'h50 : cmpt_size[31:0]          <= wdata[31:0];
        12'h60 : scratch_reg1[31:0]       <= wdata[31:0];
        12'h64 : scratch_reg2[31:0]       <= wdata[31:0];
        12'h70 : perf_ctl[4:0]            <= wdata[4:0];
        12'h84 : c2h_st_buffsz            <= wdata[15:0];
        12'h90 : dbg_userctrl_credits     <= wdata[15:0];
        12'h94 : control_reg_c2h2         <= wdata[31:0];
        12'h9C : c2h_user_cntr_max[31:0]  <= wdata[31:0];
        12'hA0 : c2h_user_cntr_max[63:32] <= wdata[31:0];
        12'hA4 : c2h_user_cntr_rst        <= wdata[0];
        12'hC8 : h2c_user_cntr_max[31:0]  <= wdata[31:0];
        12'hCC : h2c_user_cntr_max[63:32] <= wdata[31:0];
        12'hD0 : h2c_user_cntr_rst        <= wdata[0];
        12'h100: user_l3fwd_max[31:0]     <= wdata[31:0];
        12'h104: user_l3fwd_max[63:32]    <= wdata[31:0];
        12'h108: {user_l3fwd_mode, 
                  user_l3fwd_en, 
                  user_l3fwd_rst}         <= wdata[2:0];
      endcase 
    end 
    else begin
      control_reg_c2h <= {control_reg_c2h[31:2], start_c2h, control_reg_c2h[0]};
      control_reg_h2c <= {control_reg_h2c[31:1], clr_h2c_match};
      perf_ctl[4:0]   <= {perf_ctl[4:3], perf_clear, perf_stop, (perf_ctl[0]& ~perf_stop)};
      
      if (user_reset_counter[8]) begin // 256 clock cycle
        control_reg_c2h[31] <= 1'b0;
      end
    end
  end // always @ (posedge user_clk)

  always @(posedge user_clk) begin
    if (!user_reset_n)
      rvalid <= 1'b0;
    else if (ren)
      rvalid <= 1'b1;
    else if (rdone)
      rvalid <= 1'b0;
  end

  always_comb begin
    case (raddr[11:0])
      12'h00 : rdata  <= (32'h0 | c2h_st_qid[10:0]);
      12'h04 : rdata  <= (32'h0 | c2h_st_len);
      12'h08 : rdata  <= (32'h0 | control_reg_c2h[31:0]);
      12'h0C : rdata  <= (32'h0 | control_reg_h2c[31:0]);
      12'h10 : rdata  <= (32'h0 | {h2c_qid[10:0],3'b0,h2c_match});
      12'h14 : rdata  <= h2c_stat;
      12'h18 : rdata  <= (32'h0 | c2h_stat);
      12'h20 : rdata  <= (32'h0 | c2h_num_pkt[10:0]);
      12'h30 : rdata  <= wb_dat[31:0];
      12'h34 : rdata  <= wb_dat[63:32];
      12'h38 : rdata  <= wb_dat[95:64];
      12'h3C : rdata  <= wb_dat[127:96];
      12'h40 : rdata  <= wb_dat[159:128];
      12'h44 : rdata  <= wb_dat[191:160];
      12'h48 : rdata  <= wb_dat[223:192];
      12'h4C : rdata  <= wb_dat[255:224];
      12'h50 : rdata  <= cmpt_size[31:0];
      12'h60 : rdata  <= scratch_reg1[31:0];
      12'h64 : rdata  <= scratch_reg2[31:0];
      12'h70 : rdata  <= {32'h0 | perf_ctl[4:0]};
      12'h74 : rdata  <= data_count[31:0];
      12'h78 : rdata  <= data_count[63:32];
      12'h7C : rdata  <= valid_count[31:0];
      12'h80 : rdata  <= valid_count[63:32];
      12'h84 : rdata  <= c2h_st_buffsz[15:0];
      12'h88 : rdata  <= {32'h0 | axis_pkt_drop[7:0]};
      12'h8C : rdata  <= {32'h0 | axis_pkt_accept[7:0]};
      12'h90 : rdata  <= {32'h0 | dbg_userctrl_credits};
      12'h94 : rdata  <= (32'h0 | control_reg_c2h2[31:0]);
      12'h9C : rdata  <= (32'h0 | c2h_user_cntr_max[31:0]);
      12'hA0 : rdata  <= (32'h0 | c2h_user_cntr_max[63:32]);
      12'hA4 : rdata  <= (32'h0 | c2h_user_cntr_rst);
      12'hA8 : rdata  <= (32'h0 | c2h_free_cnts[31:0]);
      12'hAC : rdata  <= (32'h0 | c2h_free_cnts[63:32]);
      12'hB0 : rdata  <= (32'h0 | c2h_idle_cnts[31:0]);
      12'hB4 : rdata  <= (32'h0 | c2h_idle_cnts[63:32]);
      12'hB8 : rdata  <= (32'h0 | c2h_busy_cnts[31:0]);
      12'hBC : rdata  <= (32'h0 | c2h_busy_cnts[63:32]);
      12'hC0 : rdata  <= (32'h0 | c2h_actv_cnts[31:0]);
      12'hC4 : rdata  <= (32'h0 | c2h_actv_cnts[63:32]);
      12'hC8 : rdata  <= (32'h0 | h2c_user_cntr_max[31:0]);
      12'hCC : rdata  <= (32'h0 | h2c_user_cntr_max[63:32]);
      12'hD0 : rdata  <= (32'h0 | h2c_user_cntr_rst);
      12'hD4 : rdata  <= (32'h0 | h2c_free_cnts[31:0]);
      12'hD8 : rdata  <= (32'h0 | h2c_free_cnts[63:32]);
      12'hDC : rdata  <= (32'h0 | h2c_idle_cnts[31:0]);
      12'hE0 : rdata  <= (32'h0 | h2c_idle_cnts[63:32]);
      12'hE4 : rdata  <= (32'h0 | h2c_busy_cnts[31:0]);
      12'hE8 : rdata  <= (32'h0 | h2c_busy_cnts[63:32]);
      12'hEC : rdata  <= (32'h0 | h2c_actv_cnts[31:0]);
      12'hF0 : rdata  <= (32'h0 | h2c_actv_cnts[63:32]);
      12'h100: rdata  <= (32'h0 | user_l3fwd_max[31:0]);
      12'h104: rdata  <= (32'h0 | user_l3fwd_max[63:32]);
      12'h108: rdata  <= (32'h0 | {user_l3fwd_mode, user_l3fwd_en, user_l3fwd_rst});
      12'h10C: rdata  <= (32'h0 | max_latency[31:0]);
      12'h110: rdata  <= (32'h0 | max_latency[63:32]);
      12'h114: rdata  <= (32'h0 | min_latency[31:0]);
      12'h118: rdata  <= (32'h0 | min_latency[63:32]);
      12'h11C: rdata  <= (32'h0 | sum_latency[31:0]);
      12'h120: rdata  <= (32'h0 | sum_latency[63:32]);
      12'h124: rdata  <= (32'h0 | num_pkt_rcvd[31:0]);
      12'h128: rdata  <= (32'h0 | num_pkt_rcvd[63:32]);
      default: rdata  <= 32'h0;
    endcase 
  end 
  
  // Clear Performance Counter once all counters are read
  reg [7:0] c2h_user_fiba_read; // [7/6] = F/ree_cnts read; 
                                // [5/4] = I/dle_cnts read; 
                                // [3/2] = B/usy_cnts read; 
                                // [1/0] = A/ctv_cnts read
  assign c2h_user_cntr_read = &c2h_user_fiba_read;
  
  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      c2h_user_fiba_read <= 8'b0;
    end else begin
      c2h_user_fiba_read[0] <= (c2h_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hA8) ? 1'b1 : c2h_user_fiba_read[0]);
      c2h_user_fiba_read[1] <= (c2h_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hAC) ? 1'b1 : c2h_user_fiba_read[1]);
      c2h_user_fiba_read[2] <= (c2h_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hB0) ? 1'b1 : c2h_user_fiba_read[2]);
      c2h_user_fiba_read[3] <= (c2h_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hB4) ? 1'b1 : c2h_user_fiba_read[3]);
      c2h_user_fiba_read[4] <= (c2h_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hB8) ? 1'b1 : c2h_user_fiba_read[4]);
      c2h_user_fiba_read[5] <= (c2h_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hBC) ? 1'b1 : c2h_user_fiba_read[5]);
      c2h_user_fiba_read[6] <= (c2h_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hC0) ? 1'b1 : c2h_user_fiba_read[6]);
      c2h_user_fiba_read[7] <= (c2h_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hC4) ? 1'b1 : c2h_user_fiba_read[7]);
    end
  end
  
  reg [7:0] h2c_user_fiba_read; // [7/6] = F/ree_cnts read; 
                                // [5/4] = I/dle_cnts read; 
                                // [3/2] = B/usy_cnts read; 
                                // [1/0] = A/ctv_cnts read
  assign h2c_user_cntr_read = &h2c_user_fiba_read;
  
  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      h2c_user_fiba_read <= 8'b0;
    end else begin
      h2c_user_fiba_read[0] <= (h2c_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hD4) ? 1'b1 : h2c_user_fiba_read[0]);
      h2c_user_fiba_read[1] <= (h2c_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hD8) ? 1'b1 : h2c_user_fiba_read[1]);
      h2c_user_fiba_read[2] <= (h2c_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hDC) ? 1'b1 : h2c_user_fiba_read[2]);
      h2c_user_fiba_read[3] <= (h2c_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hE0) ? 1'b1 : h2c_user_fiba_read[3]);
      h2c_user_fiba_read[4] <= (h2c_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hE4) ? 1'b1 : h2c_user_fiba_read[4]);
      h2c_user_fiba_read[5] <= (h2c_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hE8) ? 1'b1 : h2c_user_fiba_read[5]);
      h2c_user_fiba_read[6] <= (h2c_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hEC) ? 1'b1 : h2c_user_fiba_read[6]);
      h2c_user_fiba_read[7] <= (h2c_user_cntr_read) ? 1'b0 : ( (raddr[11:0] == 12'hF0) ? 1'b1 : h2c_user_fiba_read[7]);
    end
  end
  
  reg [7:0] l3fwd_mmsn_read; // [7/6] = max_latency read; 
                             // [5/4] = min_latency read; 
                             // [3/2] = sum_latency read; 
                             // [1/0] = num_pkt_rcvd read
  assign user_l3fwd_read = &l3fwd_mmsn_read;
  
  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      l3fwd_mmsn_read <= 8'b0;
    end else begin
      l3fwd_mmsn_read[0] <= (user_l3fwd_read) ? 1'b0 : ( (raddr[11:0] == 12'h10C) ? 1'b1 : l3fwd_mmsn_read[0]);
      l3fwd_mmsn_read[1] <= (user_l3fwd_read) ? 1'b0 : ( (raddr[11:0] == 12'h110) ? 1'b1 : l3fwd_mmsn_read[1]);
      l3fwd_mmsn_read[2] <= (user_l3fwd_read) ? 1'b0 : ( (raddr[11:0] == 12'h114) ? 1'b1 : l3fwd_mmsn_read[2]);
      l3fwd_mmsn_read[3] <= (user_l3fwd_read) ? 1'b0 : ( (raddr[11:0] == 12'h118) ? 1'b1 : l3fwd_mmsn_read[3]);
      l3fwd_mmsn_read[4] <= (user_l3fwd_read) ? 1'b0 : ( (raddr[11:0] == 12'h11C) ? 1'b1 : l3fwd_mmsn_read[4]);
      l3fwd_mmsn_read[5] <= (user_l3fwd_read) ? 1'b0 : ( (raddr[11:0] == 12'h120) ? 1'b1 : l3fwd_mmsn_read[5]);
      l3fwd_mmsn_read[6] <= (user_l3fwd_read) ? 1'b0 : ( (raddr[11:0] == 12'h124) ? 1'b1 : l3fwd_mmsn_read[6]);
      l3fwd_mmsn_read[7] <= (user_l3fwd_read) ? 1'b0 : ( (raddr[11:0] == 12'h128) ? 1'b1 : l3fwd_mmsn_read[7]);
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
    .MAX_QUEUES       ( 128         ), // Limiting to 128 because 11 bits QID is using too much logic
    .QUEUE_ID_WIDTH   ( 7           )  // Limiting to 128 because 11 bits QID is using too much logic
  
  ) queue_cnts_i (
  
    .user_clk           ( user_clk           ),
    .user_reset_n       ( user_reset_n & gen_user_reset_n ),

  // tm interface signals
    .tm_dsc_sts_vld     ( tm_dsc_sts_vld     ),
    .tm_dsc_sts_qen     ( tm_dsc_sts_qen     ),
    .tm_dsc_sts_byp     ( tm_dsc_sts_byp     ), // 0=desc fetched from host; 1=desc came from descriptory bypass
    .tm_dsc_sts_dir     ( tm_dsc_sts_dir     ), // 0=H2C; 1=C2H
    .tm_dsc_sts_mm      ( tm_dsc_sts_mm      ), // 0=ST; 1=MM
    .tm_dsc_sts_qid     ( tm_dsc_sts_qid[6:0]), // QID for update
    .tm_dsc_sts_avl     ( tm_dsc_sts_avl     ), // Number of new descriptors since last update
    .tm_dsc_sts_qinv    ( tm_dsc_sts_qinv    ), // 1 indicated to invalidate the queue
    .tm_dsc_sts_irq_arm ( tm_dsc_sts_irq_arm ), // 1 indicated to that the driver is using interrupts
    .tm_dsc_sts_rdy     ( tm_dsc_sts_rdy     ), // 1 indicates valid data on the bus

  // qid output signals
    .qid_rdy            ( qid_rdy            ), // ready for the next queue id
    .qid_vld            ( qid_vld            ), // current qid and availability are valid
    .qid                ( qid_short          ),
    .qid_desc_avail     ( qid_desc_avail     ),
    .desc_cnt_dec       ( desc_cnt_dec       ), // decrement the qid count by 1
    .desc_cnt_dec_qid   ( desc_cnt_dec_qid[6:0] ), // qid for desc_cnt_dec signal
    .requeue_vld        ( requeue_vld        ), // requeue the specified qid
    .requeue_qid        ( requeue_qid[6:0]   ), // qid to be requeued
    .requeue_rdy        ( requeue_rdy        ), // requeue accepted
    .back_pres          ( control_reg_c2h[4] ),
    .turn_off           ( control_reg_c2h[3] )
  
  );

endmodule // user_control
