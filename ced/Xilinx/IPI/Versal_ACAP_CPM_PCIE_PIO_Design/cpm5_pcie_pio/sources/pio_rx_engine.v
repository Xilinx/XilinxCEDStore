
//-----------------------------------------------------------------------------
//
// (c) Copyright 2017-2019 Xilinx, Inc. All rights reserved.
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
// Project    : Versal PCI Express Integrated Block
// File       : pio_rx_engine.v
// Version    : 1.0 
//-----------------------------------------------------------------------------
//
// Description: Local-Link Receive Unit.
//
//--------------------------------------------------------------------------------

`timescale 1ps/1ps


(* DowngradeIPIdentifiedWarnings = "yes" *)
module pio_rx_engine  #(
  parameter        TCQ = 1,
  parameter [1:0]  AXISTEN_IF_WIDTH = 00,
  parameter        AXISTEN_IF_CQ_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_RC_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_RC_STRADDLE         = 0,
  parameter        AXISTEN_IF_ENABLE_RX_MSG_INTFC = 0,
  parameter        AXISTEN_IF_CQ_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_RC_PARITY_CHECK     = 0,
  parameter [17:0] AXISTEN_IF_ENABLE_MSG_ROUTE    = 18'h2FFFF,


  // Do not override parameters below this line
  //parameter C_DATA_WIDTH = (AXISTEN_IF_WIDTH[1]) ? 256 : (AXISTEN_IF_WIDTH[0])? 128 : 64,
   parameter       AXI4_CQ_TUSER_WIDTH = 183,
   parameter       AXI4_RC_TUSER_WIDTH = 161,
  parameter C_DATA_WIDTH = 512,

  parameter STRB_WIDTH   = C_DATA_WIDTH / 8,               // TSTRB width
  parameter KEEP_WIDTH   = C_DATA_WIDTH / 32,
  parameter PARITY_WIDTH = C_DATA_WIDTH / 8               // TPARITY width
) (


  input                            user_clk,
  input                            reset_n,

  // Completer Request Interface
  input        [C_DATA_WIDTH-1:0]    m_axis_cq_tdata,
  input                              m_axis_cq_tlast,
  input                              m_axis_cq_tvalid,
  input [AXI4_CQ_TUSER_WIDTH-1:0]    m_axis_cq_tuser,
  input          [KEEP_WIDTH-1:0]    m_axis_cq_tkeep,
  input                   [5:0]    pcie_cq_np_req_count,
  output reg                       m_axis_cq_tready,
  output reg                       pcie_cq_np_req,

  // Requester Completion Interface

  input         [C_DATA_WIDTH-1:0]    m_axis_rc_tdata,
  input                               m_axis_rc_tlast,
  input                               m_axis_rc_tvalid,
  input           [KEEP_WIDTH-1:0]    m_axis_rc_tkeep,
  input  [AXI4_RC_TUSER_WIDTH-1:0]    m_axis_rc_tuser,
  output reg                          m_axis_rc_tready,

  //RX Message Interface

  input                            cfg_msg_received,
  input                   [4:0]    cfg_msg_received_type,
  input                   [7:0]    cfg_msg_data,


  // Memory Read data handshake with Completion
  // transmit unit. Transmit unit reponds to
  // req_compl assertion and responds with compl_done
  // assertion when a Completion w/ data is transmitted.


  output reg                       req_compl,
  output reg                       req_compl_wd,
  output reg                       req_compl_ur,
  input                            compl_done,

  output reg              [2:0]    req_tc,             // Memory Read TC
  output reg              [2:0]    req_attr,           // Memory Read Attribute
  output reg             [10:0]    req_len,            // Memory Read Length
  output reg             [15:0]    req_rid,            // Memory Read Requestor ID { 8'b0 (Bus no),
                                                    //                            3'b0 (Dev no),
                                                    //                            5'b0 (Func no)}
  output reg              [7:0]    req_tag,            // Memory Read Tag
  output reg              [7:0]    req_be,             // Memory Read Byte Enables
  output reg             [12:0]    req_addr,           // Memory Read Address
  output reg              [1:0]    req_at,             // Address Translation

  // Outputs to the TX Block in case of an UR
  // Required to form the completions

  output reg             [63:0]    req_des_qword0,     // DWord0 and Dword1 of descriptor of the request
  output reg             [63:0]    req_des_qword1,     // DWord2 and Dword3 of descriptor of the request
  output reg                       req_des_tph_present,// TPH Present in the request
  output reg              [1:0]    req_des_tph_type,   // If TPH Present then TPH type
  output reg              [7:0]    req_des_tph_st_tag, // TPH Steering tag of the request

  //Output to Indicate that the Request was a Mem lock Read Req

  output reg                       req_mem_lock,
  output reg                       req_mem,


  //Memory interface used to save 2 DW data received
  //on Memory Write 32 TLP. Data extracted from
  //inbound TLP is presented to the Endpoint memory
  //unit. Endpoint memory unit reacts to wr_en
  //assertion and asserts wr_busy when it is
  //processing written information.


  output reg             [10:0]    wr_addr,            // Memory Write Address
  output reg              [7:0]    wr_be,              // Memory Write Byte Enable
  output reg             [63:0]    wr_data,            // Memory Write Data
  output reg                       wr_en,              // Memory Write Enable
  output reg                       payload_len,        // Transaction Payload Length
  input                            wr_busy             // Memory Write Busy

);

  localparam PIO_RX_MEM_RD_FMT_TYPE    = 4'b0000;    // Memory Read
  localparam PIO_RX_MEM_WR_FMT_TYPE    = 4'b0001;    // Memory Write
  localparam PIO_RX_IO_RD_FMT_TYPE     = 4'b0010;    // IO Read
  localparam PIO_RX_IO_WR_FMT_TYPE     = 4'b0011;    // IO Write
  localparam PIO_RX_ATOP_FAA_FMT_TYPE  = 4'b0100;    // Fetch and ADD
  localparam PIO_RX_ATOP_UCS_FMT_TYPE  = 4'b0101;    // Unconditional SWAP
  localparam PIO_RX_ATOP_CAS_FMT_TYPE  = 4'b0110;    // Compare and SWAP
  localparam PIO_RX_MEM_LK_RD_FMT_TYPE = 4'b0111;    // Locked Read Request
  localparam PIO_RX_MSG_FMT_TYPE       = 4'b1100;    // MSG Transaction apart from Vendor Defined and ATS
  localparam PIO_RX_MSG_VD_FMT_TYPE    = 4'b1101;    // MSG Transaction apart from Vendor Defined and ATS
  localparam PIO_RX_MSG_ATS_FMT_TYPE   = 4'b1110;    // MSG Transaction apart from Vendor Defined and ATS

  localparam PIO_RX_RST_STATE          = 8'b00000000;
  localparam PIO_RX_WAIT_STATE         = 8'b00000001;
  localparam PIO_RX_64_QW1             = 8'b00000010;
  localparam PIO_RX_DATA               = 8'b00000011;
  localparam PIO_RX_DATA2              = 8'b00000100;

  localparam BAR_ID_SELECT = (C_DATA_WIDTH == 64) ? 48 : 112;

  // Local Registers

  reg [7:0]          state;
  reg [3:0]          trn_type;

  reg [1:0]          region_select;

  wire               sop;                   // Start of packet
  reg                in_packet_q;

  reg [2:0]          data_start_loc;

  wire               io_bar_hit_n;
  wire               mem32_bar_hit_n;
  wire               mem64_bar_hit_n;
  wire               erom_bar_hit_n;

  reg [15:0]         req_snoop_latency;
  reg [15:0]         req_no_snoop_latency;
  reg [3:0]          req_obff_code;
  reg [7:0]          req_msg_code;
  reg [2:0]          req_msg_route;
  reg [15:0]         req_dst_id;
  reg [15:0]         req_vend_id;
  reg [31:0]         req_vend_hdr;
  reg [127:0]        req_tl_hdr;

  reg [C_DATA_WIDTH-1:0] m_axis_cq_tdata_q;
  reg [AXI4_CQ_TUSER_WIDTH-1:0] m_axis_cq_tuser_q;
  reg                m_axis_cq_tvalid_reg;
  reg [AXI4_CQ_TUSER_WIDTH-1:0] m_axis_cq_tuser_reg;

  reg     [63:0]                  m_axis_cq_tparity;
  reg     [63:0]                  m_axis_cq_tparity_q;
  reg     [KEEP_WIDTH-1:0]        m_axis_cq_tkeep_q;
  wire    [PARITY_WIDTH-1:0]      m_axis_cq_tparity_cal;
  reg     [PARITY_WIDTH-1:0]      m_axis_cq_tparity_cal_q;
  reg                             m_axis_cq_tvalid_q;
  wire                            parity_error;
  reg                             parity_error_latch;



 // Generate a signal that indicates if we are currently receiving a packet.
 // This value is one clock cycle delayed from what is actually on the AXIS
 // data bus.

 always@(posedge user_clk)
  begin
    if(!reset_n)
      in_packet_q <= #   TCQ 1'b0;
    else if (m_axis_cq_tvalid && m_axis_cq_tready && m_axis_cq_tlast)
      in_packet_q <= #   TCQ 1'b0;
    else if (sop && m_axis_cq_tready)
      in_packet_q <= #   TCQ 1'b1;
  end

  assign sop = !in_packet_q && m_axis_cq_tvalid;

  always @(posedge user_clk)
  begin
    if(!reset_n)
    begin
      m_axis_cq_tdata_q    <= #TCQ {C_DATA_WIDTH{1'b0}};
      m_axis_cq_tuser_reg  <= #TCQ {AXI4_CQ_TUSER_WIDTH{1'b0}};
    end
    else begin
      if(m_axis_cq_tvalid)
      begin
        m_axis_cq_tdata_q    <= #TCQ m_axis_cq_tdata;
	m_axis_cq_tuser_reg  <= #TCQ m_axis_cq_tuser;
      end
    end
  end
  
  generate
  if(AXISTEN_IF_CQ_PARITY_CHECK == 1) begin
    genvar a;
    for(a=0; a< STRB_WIDTH; a = a + 1) // Parity needs to be computed for every byte of data
    begin : parity_assign
        assign m_axis_cq_tparity_cal[a] = !(  m_axis_cq_tdata[(8*a)+ 0] ^ m_axis_cq_tdata[(8*a)+ 1]
                                            ^ m_axis_cq_tdata[(8*a)+ 2] ^ m_axis_cq_tdata[(8*a)+ 3]
                                            ^ m_axis_cq_tdata[(8*a)+ 4] ^ m_axis_cq_tdata[(8*a)+ 5]
                                            ^ m_axis_cq_tdata[(8*a)+ 6] ^ m_axis_cq_tdata[(8*a)+ 7]);
    end
    
    always @(posedge user_clk)
    begin
      if(!reset_n)
      begin
        m_axis_cq_tuser_q       <= #TCQ {AXI4_CQ_TUSER_WIDTH{1'd0}};
        m_axis_cq_tkeep_q       <= #TCQ {KEEP_WIDTH{1'd0}};
        m_axis_cq_tparity_cal_q <= #TCQ 'd0;
      end
      else begin
        if(m_axis_cq_tvalid)
        begin
          m_axis_cq_tuser_q    <= #TCQ m_axis_cq_tuser;
          m_axis_cq_tkeep_q    <= #TCQ m_axis_cq_tkeep;
          m_axis_cq_tparity_cal_q <= #TCQ m_axis_cq_tparity_cal;
        end
      end
    end

    always @(posedge user_clk)
    begin
      if(!reset_n)
        m_axis_cq_tvalid_q <= 'b0;
      else
        m_axis_cq_tvalid_q <= #TCQ m_axis_cq_tvalid;
    end

    always @(posedge user_clk)
    begin
      if(!reset_n)
        parity_error_latch <= 'd0;
      else if (m_axis_cq_tvalid_q)
        parity_error_latch <= parity_error_latch ? 1'b1 : parity_error;
    end

    if (C_DATA_WIDTH == 512) begin : pio_parity_512
      assign  parity_error  = m_axis_cq_tvalid_q && ((m_axis_cq_tkeep_q[15] && ((m_axis_cq_tparity_cal_q[63:60] != m_axis_cq_tparity[63:60]) ? 1'b1 : 1'b0)) | 
                                                     (m_axis_cq_tkeep_q[14] && ((m_axis_cq_tparity_cal_q[59:56] != m_axis_cq_tparity[59:56]) ? 1'b1 : 1'b0)) | 
                                                     (m_axis_cq_tkeep_q[13] && ((m_axis_cq_tparity_cal_q[55:52] != m_axis_cq_tparity[55:52]) ? 1'b1 : 1'b0)) | 
                                                     (m_axis_cq_tkeep_q[12] && ((m_axis_cq_tparity_cal_q[51:48] != m_axis_cq_tparity[51:48]) ? 1'b1 : 1'b0)) | 
                                                     (m_axis_cq_tkeep_q[11] && ((m_axis_cq_tparity_cal_q[47:44] != m_axis_cq_tparity[47:44]) ? 1'b1 : 1'b0)) | 
                                                     (m_axis_cq_tkeep_q[10] && ((m_axis_cq_tparity_cal_q[43:40] != m_axis_cq_tparity[43:40]) ? 1'b1 : 1'b0)) | 
                                                     (m_axis_cq_tkeep_q[9]  && ((m_axis_cq_tparity_cal_q[39:36] != m_axis_cq_tparity[39:36]) ? 1'b1 : 1'b0)) | 
                                                     (m_axis_cq_tkeep_q[8]  && ((m_axis_cq_tparity_cal_q[35:32] != m_axis_cq_tparity[35:32]) ? 1'b1 : 1'b0)) | 
                                                     (m_axis_cq_tkeep_q[7]  && ((m_axis_cq_tparity_cal_q[31:28] != m_axis_cq_tparity[31:28]) ? 1'b1 : 1'b0)) | 
                                                     (m_axis_cq_tkeep_q[6]  && ((m_axis_cq_tparity_cal_q[27:24] != m_axis_cq_tparity[27:24]) ? 1'b1 : 1'b0)) | 
                                                     (m_axis_cq_tkeep_q[5]  && ((m_axis_cq_tparity_cal_q[23:20] != m_axis_cq_tparity[23:20]) ? 1'b1 : 1'b0)) | 
                                                     (m_axis_cq_tkeep_q[4]  && ((m_axis_cq_tparity_cal_q[19:16] != m_axis_cq_tparity[19:16]) ? 1'b1 : 1'b0)) | 
                                                     (m_axis_cq_tkeep_q[3]  && ((m_axis_cq_tparity_cal_q[15:12] != m_axis_cq_tparity[15:12]) ? 1'b1 : 1'b0)) | 
                                                     (m_axis_cq_tkeep_q[2]  && ((m_axis_cq_tparity_cal_q[11:08] != m_axis_cq_tparity[11:08]) ? 1'b1 : 1'b0)) | 
                                                     (m_axis_cq_tkeep_q[1]  && ((m_axis_cq_tparity_cal_q[07:04] != m_axis_cq_tparity[07:04]) ? 1'b1 : 1'b0)) | 
                                                     (m_axis_cq_tkeep_q[0]  && ((m_axis_cq_tparity_cal_q[03:00] != m_axis_cq_tparity[03:00]) ? 1'b1 : 1'b0))); 
    end
    else if (C_DATA_WIDTH == 256) begin : pio_parity_256
      assign  parity_error  = m_axis_cq_tvalid_q && ((m_axis_cq_tparity_cal_q[31:0] != m_axis_cq_tparity[31:0]) ? 1'b1 : 1'b0);
    end
    else if (C_DATA_WIDTH == 128) begin : pio_parity_128
      assign  parity_error  = m_axis_cq_tvalid_q && ((m_axis_cq_tparity_cal_q[15:0] != m_axis_cq_tparity[15:0]) ? 1'b1 : 1'b0);
    end
    else if (C_DATA_WIDTH == 64) begin : pio_parity_64
      assign  parity_error  = m_axis_cq_tvalid_q && ((m_axis_cq_tparity_cal_q[7:0] != m_axis_cq_tparity[7:0]) ? 1'b1 : 1'b0);
    end
  
  end
  endgenerate



  generate

    if (C_DATA_WIDTH == 64) begin : pio_rx_sm_64
      reg [63:0]           desc_hdr_qw0;
      reg [7:0]            req_byte_enables;

      always@(posedge user_clk) begin
        if (!reset_n) begin

          desc_hdr_qw0        <= #TCQ 64'h0;
          m_axis_cq_tready    <= #TCQ 1'b0;
          m_axis_rc_tready    <= #TCQ 1'b1;
          pcie_cq_np_req      <= #TCQ 1'b1;

          req_compl           <= #TCQ 1'b0;
          req_compl_wd        <= #TCQ 1'b0;
          req_compl_ur        <= #TCQ 1'b0;

          req_tc              <= #TCQ 3'b0;
          req_attr            <= #TCQ 3'b0;
          req_len             <= #TCQ 11'b0;
          req_rid             <= #TCQ 16'b0;
          req_tag             <= #TCQ 8'b0;
          req_be              <= #TCQ 8'b0;
          req_addr            <= #TCQ 13'b0;
          req_at              <= #TCQ 2'b0;

          wr_be               <= #TCQ 8'b0;
          wr_addr             <= #TCQ 11'b0;
          wr_data             <= #TCQ 64'h0;
          wr_en               <= #TCQ 1'b0;
          payload_len         <= #TCQ 1'b0;
          data_start_loc      <= #TCQ 3'b0;

          state               <= #TCQ PIO_RX_RST_STATE;
          trn_type            <= #TCQ 4'b0;

          req_snoop_latency   <= #TCQ 16'b0;
          req_no_snoop_latency<= #TCQ 16'b0;
          req_obff_code       <= #TCQ 4'b0;
          req_msg_code        <= #TCQ 8'b0;
          req_msg_route       <= #TCQ 3'b0;
          req_dst_id          <= #TCQ 16'b0;
          req_vend_id         <= #TCQ 16'b0;
          req_vend_hdr        <= #TCQ 32'b0;
          req_tl_hdr          <= #TCQ 128'b0;


          req_des_qword0      <= #TCQ 64'b0;
          req_des_qword1      <= #TCQ 64'b0;
          req_des_tph_present <= #TCQ 1'b0;
          req_des_tph_type    <= #TCQ 2'b0;
          req_des_tph_st_tag  <= #TCQ 8'b0;

          req_mem_lock        <= #TCQ 1'b0;
          req_mem             <= #TCQ 1'b0;
	  m_axis_cq_tparity   <= #TCQ 32'b0;
	  m_axis_cq_tparity_q <= #TCQ 32'b0;

        end

        else begin

          wr_en               <= #TCQ 1'b0;
          req_compl           <= #TCQ 1'b0;
	  m_axis_cq_tparity   <= #TCQ m_axis_cq_tuser[84:53];
	  m_axis_cq_tparity_q <= #TCQ m_axis_cq_tuser_q[84:53];

          case (state)

            PIO_RX_RST_STATE : begin

              m_axis_cq_tready <= #TCQ 1'b1;
              m_axis_rc_tready <= #TCQ 1'b1;

              if (sop)
              begin

                desc_hdr_qw0     <= #TCQ m_axis_cq_tdata[63:0];
                req_byte_enables <= #TCQ m_axis_cq_tuser[7:0];
                state            <= #TCQ PIO_RX_64_QW1;

              end
              else
                state            <= #TCQ PIO_RX_RST_STATE;

            end // PIO_RX_RST_STATE

            PIO_RX_64_QW1 : begin

              if (m_axis_cq_tvalid) begin
                case (m_axis_cq_tdata[14:11])

                  PIO_RX_MEM_RD_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[14:11];
                    req_len          <= #TCQ m_axis_cq_tdata[10:0];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    req_mem          <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    req_des_qword0      <= #TCQ desc_hdr_qw0[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];

                    if((m_axis_cq_tdata[10:0] == 11'h001) || (m_axis_cq_tdata[10:0] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b1;
                      req_tc           <= #TCQ m_axis_cq_tdata[59:57];
                      req_attr         <= #TCQ m_axis_cq_tdata[62:60];
                      req_rid          <= #TCQ m_axis_cq_tdata[31:16];
                      req_tag          <= #TCQ m_axis_cq_tdata[39:32];
                      req_be           <= #TCQ req_byte_enables;
                      req_addr         <= #TCQ {region_select[1:0],desc_hdr_qw0[10:2], 2'b00};
                      req_at           <= #TCQ desc_hdr_qw0[1:0];

                      if(m_axis_cq_tdata[10:0] == 11'h002)
                        payload_len    <= #TCQ 1'b1;
                      else
                        payload_len    <= #TCQ 1'b0;
                    end
                    else begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                    end

                  end  // PIO_RX_MEM_RD_FMT_TYPE


                  PIO_RX_MEM_WR_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[14:11];
                    req_len          <= #TCQ m_axis_cq_tdata[10:0];
                    req_mem          <= #TCQ 1'b0;
                    req_des_qword0      <= #TCQ desc_hdr_qw0[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];

                    if((m_axis_cq_tdata[10:0] == 11'h001) || (m_axis_cq_tdata[10:0] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_tc           <= #TCQ m_axis_cq_tdata[59:57];
                      req_attr         <= #TCQ m_axis_cq_tdata[62:60];
                      req_rid          <= #TCQ m_axis_cq_tdata[31:16];
                      req_tag          <= #TCQ m_axis_cq_tdata[39:32];
                      req_be           <= #TCQ req_byte_enables;
                      req_addr         <= #TCQ {region_select[1:0],desc_hdr_qw0[10:2], 2'b00};
                      req_at           <= #TCQ desc_hdr_qw0[1:0];

                      if(m_axis_cq_tdata[10:0] == 11'h002)
                        payload_len    <= #TCQ 1'b1;
                      else
                        payload_len    <= #TCQ 1'b0;

                      data_start_loc   <= #TCQ (AXISTEN_IF_CQ_ALIGNMENT_MODE == "TRUE") ? {2'b0,m_axis_cq_tdata_q[2]} : 3'b0;
                      state            <= #TCQ PIO_RX_DATA;
                    end
                    else begin // Payload > 2DWORD
                      state            <= #TCQ PIO_RX_RST_STATE;
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                    end
                  end // PIO_RX_MEM_WR_FMT_TYPE


                  PIO_RX_IO_RD_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[14:11];
                    req_len          <= #TCQ m_axis_cq_tdata[10:0];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    req_mem          <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    req_des_qword0      <= #TCQ desc_hdr_qw0[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];

                    if((m_axis_cq_tdata[10:0] == 11'h001) || (m_axis_cq_tdata[10:0] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b1;
                      req_tc           <= #TCQ m_axis_cq_tdata[59:57];
                      req_attr         <= #TCQ m_axis_cq_tdata[62:60];
                      req_rid          <= #TCQ m_axis_cq_tdata[31:16];
                      req_tag          <= #TCQ m_axis_cq_tdata[39:32];
                      req_be           <= #TCQ req_byte_enables;
                      req_addr         <= #TCQ {region_select[1:0],desc_hdr_qw0[10:2], 2'b00};
                      req_at           <= #TCQ desc_hdr_qw0[1:0];
                      if(m_axis_cq_tdata[10:0] == 11'h002)
                        payload_len    <= #TCQ 1'b1;
                      else
                        payload_len    <= #TCQ 1'b0;
                      end
                    else begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                    end

                  end //PIO_RX_IO_RD_FMT_TYPE


                  PIO_RX_IO_WR_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[14:11];
                    req_len          <= #TCQ m_axis_cq_tdata[10:0];
                    req_mem          <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    req_des_qword0      <= #TCQ desc_hdr_qw0[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];

                    if((m_axis_cq_tdata[10:0] == 11'h001) || (m_axis_cq_tdata[10:0] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_tc           <= #TCQ m_axis_cq_tdata[59:57];
                      req_attr         <= #TCQ m_axis_cq_tdata[62:60];
                      req_rid          <= #TCQ m_axis_cq_tdata[31:16];
                      req_tag          <= #TCQ m_axis_cq_tdata[39:32];
                      req_be           <= #TCQ req_byte_enables;
                      req_addr         <= #TCQ {region_select[1:0],desc_hdr_qw0[10:2], 2'b00};
                      req_at           <= #TCQ desc_hdr_qw0[1:0];
                      if(m_axis_cq_tdata[10:0] == 11'h002)
                        payload_len    <=#TCQ 1'b1;
                      else
                        payload_len   <=#TCQ 1'b0;

                      data_start_loc   <= #TCQ (AXISTEN_IF_CQ_ALIGNMENT_MODE == "TRUE") ? {2'b0,m_axis_cq_tdata_q[2]} : 3'b0;
                      state            <= #TCQ PIO_RX_DATA;

                    end
                    else begin // Payload > 2DWORDs
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                      state            <= #TCQ PIO_RX_RST_STATE;
                    end

                  end // PIO_RX_IO_WR_FMT_TYPE


                  PIO_RX_ATOP_FAA_FMT_TYPE, PIO_RX_ATOP_UCS_FMT_TYPE, PIO_RX_ATOP_CAS_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[14:11];
                    req_len          <= #TCQ m_axis_cq_tdata[10:0];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    req_mem          <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    req_des_qword0      <= #TCQ desc_hdr_qw0[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];

                    if((m_axis_cq_tdata[10:0] == 11'h001) || (m_axis_cq_tdata[10:0] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_tc           <= #TCQ m_axis_cq_tdata[59:57];
                      req_attr         <= #TCQ m_axis_cq_tdata[62:60];
                      req_rid          <= #TCQ m_axis_cq_tdata[31:16];
                      req_tag          <= #TCQ m_axis_cq_tdata[39:32];
                      req_be           <= #TCQ req_byte_enables;
                      end
                    else begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                    end

                  end // PIO_RX_ATOP_FAA_FMT_TYPE, PIO_RX_ATOP_UCS_FMT_TYPE, PIO_RX_ATOP_CAS_FMT_TYPE


                  PIO_RX_MEM_LK_RD_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[14:11];
                    req_len          <= #TCQ m_axis_cq_tdata[10:0];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    req_des_qword0      <= #TCQ desc_hdr_qw0[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];

                    if((m_axis_cq_tdata[10:0] == 11'h001) || (m_axis_cq_tdata[10:0] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b1;
                      req_tc           <= #TCQ m_axis_cq_tdata[59:57];
                      req_attr         <= #TCQ m_axis_cq_tdata[62:60];
                      req_rid          <= #TCQ m_axis_cq_tdata[31:16];
                      req_tag          <= #TCQ m_axis_cq_tdata[39:32];
                      req_be           <= #TCQ req_byte_enables;
                      req_mem_lock     <= #TCQ 1'b1;
                      req_addr         <= #TCQ {region_select[1:0],desc_hdr_qw0[10:2], 2'b00};
                      req_at           <= #TCQ desc_hdr_qw0[1:0];
                      if(m_axis_cq_tdata[10:0] == 11'h002)
                        payload_len    <=#TCQ 1'b1;
                      else
                        payload_len   <=#TCQ 1'b0;
                    end
                    else begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                    end


                  end //PIO_RX_MEM_LK_RD_FMT_TYPE


                  PIO_RX_MSG_FMT_TYPE : begin

                    req_snoop_latency    <= #TCQ desc_hdr_qw0[15:0];
                    req_no_snoop_latency <= #TCQ desc_hdr_qw0[31:16];
                    req_obff_code        <= #TCQ desc_hdr_qw0[35:32];
                    trn_type             <= #TCQ m_axis_cq_tdata[14:11];
                    req_len              <= #TCQ m_axis_cq_tdata[10:0];
                    req_mem              <= #TCQ 1'b0;
                    m_axis_cq_tready     <= #TCQ 1'b0;
                    req_tc               <= #TCQ m_axis_cq_tdata[59:57];
                    req_attr             <= #TCQ m_axis_cq_tdata[62:60];
                    req_at               <= #TCQ desc_hdr_qw0[1:0];
                    req_rid              <= #TCQ m_axis_cq_tdata[31:16];
                    req_tag              <= #TCQ m_axis_cq_tdata[39:32];
                    req_be               <= #TCQ req_byte_enables;
                    req_msg_code         <= #TCQ m_axis_cq_tdata[47:40];
                    req_msg_route        <= #TCQ m_axis_cq_tdata[50:48];
                    state                <= #TCQ PIO_RX_RST_STATE;

                  end // PIO_RX_MSG_FMT_TYPE


                  PIO_RX_MSG_VD_FMT_TYPE : begin

                    trn_type             <= #TCQ m_axis_cq_tdata[14:11];
                    req_len              <= #TCQ m_axis_cq_tdata[10:0];
                    m_axis_cq_tready     <= #TCQ 1'b0;
                    req_mem              <= #TCQ 1'b0;
                    req_tc               <= #TCQ m_axis_cq_tdata[59:57];
                    req_attr             <= #TCQ m_axis_cq_tdata[62:60];
                    req_rid              <= #TCQ m_axis_cq_tdata[31:16];
                    req_tag              <= #TCQ m_axis_cq_tdata[39:32];
                    req_msg_code         <= #TCQ m_axis_cq_tdata[47:40];
                    req_msg_route        <= #TCQ m_axis_cq_tdata[50:48];
                    req_be               <= #TCQ req_byte_enables;
                    req_at               <= #TCQ desc_hdr_qw0[1:0];
                    req_dst_id           <= #TCQ desc_hdr_qw0[15:0];
                    req_vend_id          <= #TCQ desc_hdr_qw0[31:16];
                    req_vend_hdr         <= #TCQ desc_hdr_qw0[63:32];
                    state                <= #TCQ PIO_RX_RST_STATE;

                  end // PIO_RX_MSG_VD_FMT_TYPE


                  PIO_RX_MSG_ATS_FMT_TYPE : begin

                    trn_type             <= #TCQ m_axis_cq_tdata[14:11];
                    req_len              <= #TCQ m_axis_cq_tdata[10:0];
                    m_axis_cq_tready     <= #TCQ 1'b0;
                    req_mem              <= #TCQ 1'b0;
                    req_tc               <= #TCQ m_axis_cq_tdata[59:57];
                    req_attr             <= #TCQ m_axis_cq_tdata[62:60];
                    req_rid              <= #TCQ m_axis_cq_tdata[31:16];
                    req_tag              <= #TCQ m_axis_cq_tdata[39:32];
                    req_msg_code         <= #TCQ m_axis_cq_tdata[47:40];
                    req_msg_route        <= #TCQ m_axis_cq_tdata[50:48];
                    req_be               <= #TCQ req_byte_enables;
                    req_at               <= #TCQ desc_hdr_qw0[1:0];
                    req_tl_hdr[127:64]   <= #TCQ desc_hdr_qw0[63:0];
                    state                <= #TCQ PIO_RX_RST_STATE;

                  end // PIO_RX_MSG_ATS_FMT_TYPE

                  default : begin // other TLPs

                    state        <= #TCQ PIO_RX_64_QW1;
                  end

                endcase // Req_Type
              end // m_axis_cq_tvalid
              else
                state <= #TCQ PIO_RX_64_QW1;

            end // PIO_RX_64_QW1



            PIO_RX_DATA : begin

              if (m_axis_cq_tvalid)
              begin
                wr_addr          <= #TCQ req_addr[12:2];
                case (data_start_loc)
                  3'b000 : begin
                    wr_data          <= #TCQ payload_len ? m_axis_cq_tdata[63:0] : {32'h0, m_axis_cq_tdata[31:0]};
                    wr_be            <= #TCQ payload_len ? m_axis_cq_tuser[15:8] : { 4'h0, m_axis_cq_tuser[11:8]};
                    wr_en            <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ 1'b0;
                  end
                  3'b001 : begin
                    wr_data          <= #TCQ {32'h0, m_axis_cq_tdata[63:32]};
                    wr_be            <= #TCQ { 4'h0, m_axis_cq_tuser[15:12]};
                    wr_en            <= #TCQ payload_len ? 1'b0 : 1'b1;
                    state            <= #TCQ payload_len ? PIO_RX_DATA2 : PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ payload_len ? 1'b1 : 1'b0;
                  end
                  default : begin
                    state        <= #TCQ PIO_RX_DATA;
                  end
                endcase
              end // if (m_axis_cq_tvalid)
              else
                state        <= #TCQ PIO_RX_DATA;

            end // PIO_RX_DATA

            PIO_RX_DATA2 : begin

              if (m_axis_cq_tvalid && m_axis_cq_tlast)
              begin

                  wr_data[63:32]   <= #TCQ m_axis_cq_tdata[31:0];
                  wr_be[7:4]       <= #TCQ m_axis_cq_tuser[11:8];
                  wr_en            <= #TCQ 1'b1;
                  m_axis_cq_tready <= #TCQ 1'b0;
                  state            <= #TCQ PIO_RX_WAIT_STATE;

              end // if (m_axis_cq_tvalid)
              else
              state        <= #TCQ PIO_RX_DATA2;

            end // PIO_RX_DATA2

            PIO_RX_WAIT_STATE : begin

              wr_en      <= #TCQ 1'b0;
              req_compl  <= #TCQ 1'b0;
              req_compl_wd  <= #TCQ 1'b0;

              if ((trn_type == PIO_RX_MEM_WR_FMT_TYPE) && (!wr_busy))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_IO_WR_FMT_TYPE) && (!wr_busy))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_MEM_RD_FMT_TYPE) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_MEM_LK_RD_FMT_TYPE) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_IO_RD_FMT_TYPE) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if (((trn_type == PIO_RX_ATOP_FAA_FMT_TYPE) || (trn_type == PIO_RX_ATOP_UCS_FMT_TYPE) ||
                            (trn_type == PIO_RX_ATOP_CAS_FMT_TYPE)) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;
              end else
                state        <= #TCQ PIO_RX_WAIT_STATE;

            end // PIO_RX_WAIT_STATE

            default : begin
              // default case stmt
              state        <= #TCQ PIO_RX_RST_STATE;
            end // default

          endcase

        end // if reset_n

      end // always @ user_clk
    end // pio_rx_sm_64

    else if (C_DATA_WIDTH == 128) begin : pio_rx_sm_128

      always@(posedge user_clk) begin
        if (!reset_n) begin

          m_axis_cq_tready    <= #TCQ 1'b0;
          m_axis_rc_tready    <= #TCQ 1'b1;
          pcie_cq_np_req      <= #TCQ 1'b1;

          req_compl           <= #TCQ 1'b0;
          req_compl_wd        <= #TCQ 1'b0;
          req_compl_ur        <= #TCQ 1'b0;

          req_tc              <= #TCQ 3'b0;
          req_attr            <= #TCQ 3'b0;
          req_len             <= #TCQ 11'b0;
          req_rid             <= #TCQ 16'b0;
          req_tag             <= #TCQ 8'b0;
          req_be              <= #TCQ 8'b0;
          req_addr            <= #TCQ 13'b0;
          req_at              <= #TCQ 2'b0;

          wr_be               <= #TCQ 8'b0;
          wr_addr             <= #TCQ 11'b0;
          wr_data             <= #TCQ 64'h0;
          wr_en               <= #TCQ 1'b0;
          payload_len         <= #TCQ 1'b0;
          data_start_loc      <= #TCQ 3'b0;

          state               <= #TCQ PIO_RX_RST_STATE;
          trn_type            <= #TCQ 4'b0;

          req_snoop_latency   <= #TCQ 16'b0;
          req_no_snoop_latency<= #TCQ 16'b0;
          req_obff_code       <= #TCQ 4'b0;
          req_msg_code        <= #TCQ 8'b0;
          req_msg_route       <= #TCQ 3'b0;
          req_dst_id          <= #TCQ 16'b0;
          req_vend_id         <= #TCQ 16'b0;
          req_vend_hdr        <= #TCQ 32'b0;
          req_tl_hdr          <= #TCQ 128'b0;


          req_des_qword0      <= #TCQ 64'b0;
          req_des_qword1      <= #TCQ 64'b0;
          req_des_tph_present <= #TCQ 1'b0;
          req_des_tph_type    <= #TCQ 2'b0;
          req_des_tph_st_tag  <= #TCQ 8'b0;

          req_mem_lock        <= #TCQ 1'b0;
          req_mem             <= #TCQ 1'b0;
	  m_axis_cq_tparity   <= #TCQ 32'b0;
	  m_axis_cq_tparity_q <= #TCQ 32'b0;

        end

        else begin

          wr_en               <= #TCQ 1'b0;
          req_compl           <= #TCQ 1'b0;
	  m_axis_cq_tparity   <= #TCQ m_axis_cq_tuser[84:53];
	  m_axis_cq_tparity_q <= #TCQ m_axis_cq_tuser_q[84:53];

          case (state)

            PIO_RX_RST_STATE : begin

              m_axis_cq_tready <= #TCQ 1'b1;
              m_axis_rc_tready <= #TCQ 1'b1;

              if (sop)
              begin

                case (m_axis_cq_tdata[78:75])

                  PIO_RX_MEM_RD_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    req_mem          <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b1;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                      req_be           <= #TCQ m_axis_cq_tuser[7:0];
                      req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2], 2'b00};
                      req_at           <= #TCQ m_axis_cq_tdata[1:0];

                      if(m_axis_cq_tdata[74:64] == 11'h002)
                        payload_len    <= #TCQ 1'b1;
                      else
                        payload_len    <= #TCQ 1'b0;
                    end
                    else begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                      req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                      req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];
                      req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                      req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                      req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];
                    end

                  end  // PIO_RX_MEM_RD_FMT_TYPE


                  PIO_RX_MEM_WR_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    req_mem          <= #TCQ 1'b0;

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                      req_be           <= #TCQ m_axis_cq_tuser[7:0];
                      req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2], 2'b00};
                      req_at           <= #TCQ m_axis_cq_tdata[1:0];

                      if(m_axis_cq_tdata[74:64] == 11'h002)
                        payload_len    <= #TCQ 1'b1;
                      else
                        payload_len    <= #TCQ 1'b0;

                      data_start_loc   <= #TCQ (AXISTEN_IF_CQ_ALIGNMENT_MODE  == "TRUE") ? {1'b0,m_axis_cq_tdata[3:2]} : 3'b0;

                      state            <= #TCQ PIO_RX_DATA;
                    end
                    else begin // Payload > 2DWORD
                      state            <= #TCQ PIO_RX_RST_STATE;
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                      req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                      req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];
                      req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                      req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                      req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];
                    end
                  end // PIO_RX_MEM_WR_FMT_TYPE


                  PIO_RX_IO_RD_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    req_mem          <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b1;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                      req_be           <= #TCQ m_axis_cq_tuser[7:0];
                      req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2], 2'b00};
                      req_at           <= #TCQ m_axis_cq_tdata[1:0];
                      if(m_axis_cq_tdata[74:64] == 11'h002)
                        payload_len    <= #TCQ 1'b1;
                      else
                        payload_len    <= #TCQ 1'b0;
                      end
                    else begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                      req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                      req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];
                      req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                      req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                      req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];
                    end

                  end //PIO_RX_IO_RD_FMT_TYPE


                  PIO_RX_IO_WR_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    req_mem          <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                      req_be           <= #TCQ m_axis_cq_tuser[7:0];
                      req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2], 2'b00};
                      req_at           <= #TCQ m_axis_cq_tdata[1:0];
                      if(m_axis_cq_tdata[74:64] == 11'h002)
                        payload_len    <=#TCQ 1'b1;
                      else
                        payload_len   <=#TCQ 1'b0;

                      data_start_loc   <= #TCQ (AXISTEN_IF_CQ_ALIGNMENT_MODE  == "TRUE") ? {1'b0,m_axis_cq_tdata[3:2]} : 3'b0;

                      state            <= #TCQ PIO_RX_DATA;

                    end
                    else begin // Payload > 2DWORDs
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                      req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                      req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];
                      req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                      req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                      req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];
                      state            <= #TCQ PIO_RX_RST_STATE;
                    end

                  end // PIO_RX_IO_WR_FMT_TYPE


                  PIO_RX_ATOP_FAA_FMT_TYPE, PIO_RX_ATOP_UCS_FMT_TYPE, PIO_RX_ATOP_CAS_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    req_mem          <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                      req_be           <= #TCQ m_axis_cq_tuser[7:0];
                      end
                    else begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                      req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                      req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];
                      req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                      req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                      req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];
                    end

                  end // PIO_RX_ATOP_FAA_FMT_TYPE, PIO_RX_ATOP_UCS_FMT_TYPE, PIO_RX_ATOP_CAS_FMT_TYPE


                  PIO_RX_MEM_LK_RD_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b1;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                      req_be           <= #TCQ m_axis_cq_tuser[7:0];
                      req_mem_lock     <= #TCQ 1'b1;
                      req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2], 2'b00};
                      req_at           <= #TCQ m_axis_cq_tdata[1:0];
                      if(m_axis_cq_tdata[74:64] == 11'h002)
                        payload_len    <=#TCQ 1'b1;
                      else
                        payload_len   <=#TCQ 1'b0;
                    end
                    else begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                      req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                      req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];
                      req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                      req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                      req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];
                    end


                  end //PIO_RX_MEM_LK_RD_FMT_TYPE


                  PIO_RX_MSG_FMT_TYPE : begin

                    req_snoop_latency    <= #TCQ m_axis_cq_tdata[15:0];
                    req_no_snoop_latency <= #TCQ m_axis_cq_tdata[95:80];
                    req_obff_code        <= #TCQ m_axis_cq_tdata[35:32];
                    trn_type             <= #TCQ m_axis_cq_tdata[78:75];
                    req_len              <= #TCQ m_axis_cq_tdata[74:64];
                    req_mem              <= #TCQ 1'b0;
                    m_axis_cq_tready     <= #TCQ 1'b0;
                    req_tc               <= #TCQ m_axis_cq_tdata[123:121];
                    req_attr             <= #TCQ m_axis_cq_tdata[126:124];
                    req_at               <= #TCQ m_axis_cq_tdata[1:0];
                    req_rid              <= #TCQ m_axis_cq_tdata[95:80];
                    req_tag              <= #TCQ m_axis_cq_tdata[103:96];
                    req_be               <= #TCQ m_axis_cq_tuser[7:0];
                    req_msg_code         <= #TCQ m_axis_cq_tdata[47:40];
                    req_msg_route        <= #TCQ m_axis_cq_tdata[50:48];
                    state                <= #TCQ PIO_RX_RST_STATE;

                  end // PIO_RX_MSG_FMT_TYPE


                  PIO_RX_MSG_VD_FMT_TYPE : begin

                    trn_type             <= #TCQ m_axis_cq_tdata[78:75];
                    req_len              <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready     <= #TCQ 1'b0;
                    req_mem              <= #TCQ 1'b0;
                    req_tc               <= #TCQ m_axis_cq_tdata[123:121];
                    req_attr             <= #TCQ m_axis_cq_tdata[126:124];
                    req_rid              <= #TCQ m_axis_cq_tdata[95:80];
                    req_tag              <= #TCQ m_axis_cq_tdata[103:96];
                    req_msg_code         <= #TCQ m_axis_cq_tdata[47:40];
                    req_msg_route        <= #TCQ m_axis_cq_tdata[50:48];
                    req_be               <= #TCQ m_axis_cq_tuser[7:0];
                    req_at               <= #TCQ m_axis_cq_tdata[1:0];
                    req_dst_id           <= #TCQ m_axis_cq_tdata[15:0];
                    req_vend_id          <= #TCQ m_axis_cq_tdata[95:80];
                    req_vend_hdr         <= #TCQ m_axis_cq_tdata[63:32];
                    state                <= #TCQ PIO_RX_RST_STATE;

                  end // PIO_RX_MSG_VD_FMT_TYPE


                  PIO_RX_MSG_ATS_FMT_TYPE : begin

                    trn_type             <= #TCQ m_axis_cq_tdata[78:75];
                    req_len              <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready     <= #TCQ 1'b0;
                    req_mem              <= #TCQ 1'b0;
                    req_tc               <= #TCQ m_axis_cq_tdata[123:121];
                    req_attr             <= #TCQ m_axis_cq_tdata[126:124];
                    req_rid              <= #TCQ m_axis_cq_tdata[95:80];
                    req_tag              <= #TCQ m_axis_cq_tdata[103:96];
                    req_msg_code         <= #TCQ m_axis_cq_tdata[47:40];
                    req_msg_route        <= #TCQ m_axis_cq_tdata[50:48];
                    req_be               <= #TCQ m_axis_cq_tuser[7:0];
                    req_at               <= #TCQ m_axis_cq_tdata[1:0];
                    req_tl_hdr[127:64]   <= #TCQ m_axis_cq_tdata[127:64];
                    state                <= #TCQ PIO_RX_RST_STATE;

                  end // PIO_RX_MSG_ATS_FMT_TYPE

                  default : begin // other TLPs

                    state        <= #TCQ PIO_RX_RST_STATE;
                  end

                endcase // Req_Type
              end // m_axis_cq_tvalid
              else
                state <= #TCQ PIO_RX_RST_STATE;

            end // PIO_RX_RST_STATE


            PIO_RX_DATA : begin

              if (m_axis_cq_tvalid)
              begin
                wr_addr          <= #TCQ req_addr[12:2];
                case (data_start_loc)
                  3'b000 : begin
                    wr_data          <= #TCQ payload_len ? m_axis_cq_tdata[63:0] : {32'h0, m_axis_cq_tdata[31:0]};
                    wr_be            <= #TCQ payload_len ? m_axis_cq_tuser[15:8] : { 4'h0, m_axis_cq_tuser[11:8]};
                    wr_en            <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ 1'b0;
                  end
                  3'b001 : begin
                    wr_data          <= #TCQ payload_len ? m_axis_cq_tdata[95:32] : {32'h0, m_axis_cq_tdata[63:32]};
                    wr_be            <= #TCQ payload_len ? m_axis_cq_tuser[19:12] : { 4'h0, m_axis_cq_tuser[15:12]};
                    wr_en            <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ 1'b0;
                  end
                  3'b010 : begin
                    wr_data          <= #TCQ payload_len ? m_axis_cq_tdata[127:64] : {32'h0, m_axis_cq_tdata[95:64]};
                    wr_be            <= #TCQ payload_len ? m_axis_cq_tuser[23:16] : { 4'h0, m_axis_cq_tuser[19:16]};
                    wr_en            <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ 1'b0;
                  end
                  3'b011 : begin
                    wr_data          <= #TCQ {32'h0, m_axis_cq_tdata[127:96]};
                    wr_be            <= #TCQ { 4'h0, m_axis_cq_tuser[23:20]};
                    wr_en            <= #TCQ payload_len ? 1'b0 : 1'b1;
                    state            <= #TCQ payload_len ? PIO_RX_DATA2 : PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ payload_len ? 1'b1 : 1'b0;
                  end
                  default : begin
                    state        <= #TCQ PIO_RX_DATA;
                  end
                endcase
              end // if (m_axis_cq_tvalid)
              else
                state        <= #TCQ PIO_RX_DATA;

            end // PIO_RX_DATA

            PIO_RX_DATA2 : begin

              if (m_axis_cq_tvalid && m_axis_cq_tlast)
              begin

                  wr_data[63:32]   <= #TCQ m_axis_cq_tdata[31:0];
                  wr_be[7:4]       <= #TCQ m_axis_cq_tuser[11:8];
                  wr_en            <= #TCQ 1'b1;
                  m_axis_cq_tready <= #TCQ 1'b0;
                  state            <= #TCQ PIO_RX_WAIT_STATE;

              end // if (m_axis_cq_tvalid)
              else
              state        <= #TCQ PIO_RX_DATA2;

            end // PIO_RX_DATA2

            PIO_RX_WAIT_STATE : begin

              wr_en      <= #TCQ 1'b0;
              req_compl  <= #TCQ 1'b0;
              req_compl_wd  <= #TCQ 1'b0;

              if ((trn_type == PIO_RX_MEM_WR_FMT_TYPE) && (!wr_busy))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_IO_WR_FMT_TYPE) && (!wr_busy))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_MEM_RD_FMT_TYPE) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_MEM_LK_RD_FMT_TYPE) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_IO_RD_FMT_TYPE) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if (((trn_type == PIO_RX_ATOP_FAA_FMT_TYPE) || (trn_type == PIO_RX_ATOP_UCS_FMT_TYPE) ||
                            (trn_type == PIO_RX_ATOP_CAS_FMT_TYPE)) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;
              end else
                state        <= #TCQ PIO_RX_WAIT_STATE;

            end // PIO_RX_WAIT_STATE

            default : begin
              // default case stmt
              state        <= #TCQ PIO_RX_RST_STATE;
            end // default

          endcase

        end // if reset_n

      end // always @ user_clk
    end // pio_rx_sm_128

    else if (C_DATA_WIDTH == 256) begin : pio_rx_sm_256

      always@(posedge user_clk) begin
        if(!reset_n) begin

          m_axis_cq_tready    <= #TCQ 1'b0;
          m_axis_rc_tready    <= #TCQ 1'b1;
          pcie_cq_np_req      <= #TCQ 1'b1;

          req_compl           <= #TCQ 1'b0;
          req_compl_wd        <= #TCQ 1'b0;
          req_compl_ur        <= #TCQ 1'b0;

          req_tc              <= #TCQ 3'b0;
          req_attr            <= #TCQ 3'b0;
          req_len             <= #TCQ 11'b0;
          req_rid             <= #TCQ 16'b0;
          req_tag             <= #TCQ 8'b0;
          req_be              <= #TCQ 8'b0;
          req_addr            <= #TCQ 13'b0;
          req_at              <= #TCQ 2'b0;

          wr_be               <= #TCQ 8'b0;
          wr_addr             <= #TCQ 11'b0;
          wr_data             <= #TCQ 64'h0;
          wr_en               <= #TCQ 1'b0;
          payload_len         <= #TCQ 1'b0;
          data_start_loc      <= #TCQ 3'b0;

          state               <= #TCQ PIO_RX_RST_STATE;
          trn_type            <= #TCQ 4'b0;

          req_snoop_latency   <= #TCQ 16'b0;
          req_no_snoop_latency<= #TCQ 16'b0;
          req_obff_code       <= #TCQ 4'b0;
          req_msg_code        <= #TCQ 8'b0;
          req_msg_route       <= #TCQ 3'b0;
          req_dst_id          <= #TCQ 16'b0;
          req_vend_id         <= #TCQ 16'b0;
          req_vend_hdr        <= #TCQ 32'b0;
          req_tl_hdr          <= #TCQ 128'b0;

          req_des_qword0      <= #TCQ 64'b0;
          req_des_qword1      <= #TCQ 64'b0;
          req_des_tph_present <= #TCQ 1'b0;
          req_des_tph_type    <= #TCQ 2'b0;
          req_des_tph_st_tag  <= #TCQ 8'b0;

          req_mem_lock        <= #TCQ 1'b0;
          req_mem             <= #TCQ 1'b0;
	  m_axis_cq_tparity   <= #TCQ 32'b0;
	  m_axis_cq_tparity_q <= #TCQ 32'b0;

        end

        else begin

          wr_en               <= #TCQ 1'b0;
          req_compl           <= #TCQ 1'b0;
	  m_axis_cq_tparity   <= #TCQ m_axis_cq_tuser[84:53];
	  m_axis_cq_tparity_q <= #TCQ m_axis_cq_tuser_q[84:53];

          case (state)

            PIO_RX_RST_STATE : begin

              m_axis_cq_tready <= #TCQ 1'b1;
              m_axis_rc_tready <= #TCQ 1'b1;
              //req_compl_wd     <= #TCQ 1'b1;

              if (sop) begin //sop_if

                case( m_axis_cq_tdata[78:75] ) // Req_Type_fsm

                  PIO_RX_MEM_RD_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    req_mem          <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    req_be           <= #TCQ m_axis_cq_tuser[7:0];
                    req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];
                    req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2], 2'b00};
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b1;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                      req_at           <= #TCQ m_axis_cq_tdata[1:0];
                      payload_len    <=#TCQ m_axis_cq_tdata[65];
                    end
                    else begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                    end

                  end  // PIO_RX_MEM_RD_FMT_TYPE


                  PIO_RX_MEM_WR_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    req_mem          <= #TCQ 1'b0;
                    if(m_axis_cq_tdata[74:64] == 11'h002) // 2DWord Payload
                      payload_len    <=#TCQ 1'b1;
                    else
                      payload_len   <=#TCQ 1'b0;

                    if(AXISTEN_IF_CQ_ALIGNMENT_MODE == "FALSE") begin // DWord Aligned Mode
                      if(m_axis_cq_tdata[74:64] == 11'h002) begin // 2DWord Payload
                        wr_data        <= #TCQ m_axis_cq_tdata[191:128];
                      end
                      else if (m_axis_cq_tdata[74:64] == 11'h001) begin // 1DW Payload
                        wr_data       <= #TCQ { 32'b0, m_axis_cq_tdata[159:128]};
                      end
		    end 

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin

                      if(AXISTEN_IF_CQ_ALIGNMENT_MODE == "FALSE") begin // DWord Aligned Mode
                        state            <= #TCQ PIO_RX_WAIT_STATE;
                        wr_be            <= #TCQ m_axis_cq_tuser[7:0];
                        wr_en            <= #TCQ 1'b1;
                        wr_addr          <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2]};
                        m_axis_cq_tready <= #TCQ 1'b0;
                      end // DWord Aligned Mode
                      else begin // Address Aligned Mode
                        state            <= #TCQ PIO_RX_DATA;
                        req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2], 2'b00};
                        data_start_loc   <= #TCQ (AXISTEN_IF_CQ_ALIGNMENT_MODE  == "TRUE") ? {m_axis_cq_tdata[4:2]} : 3'b0;
                      end

                      end
                    else begin // Payload > 2DWORD
                      state            <= #TCQ PIO_RX_RST_STATE;
                    end
                  end // PIO_RX_MEM_WR_FMT_TYPE


                  PIO_RX_IO_RD_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    req_mem          <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    req_be           <= #TCQ m_axis_cq_tuser[7:0];
                    req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];
                    req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2], 2'b00};
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b1;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                      req_at           <= #TCQ m_axis_cq_tdata[1:0];
                      payload_len    <=#TCQ m_axis_cq_tdata[65];
                    end
                    else begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                    end

                  end //PIO_RX_IO_RD_FMT_TYPE


                  PIO_RX_IO_WR_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    req_mem          <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    req_be           <= #TCQ m_axis_cq_tuser[7:0];
                    req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2], 2'b00};
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];
                    req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                      req_at           <= #TCQ m_axis_cq_tdata[1:0];
                      payload_len   <=#TCQ m_axis_cq_tdata[65];
                      if(AXISTEN_IF_CQ_ALIGNMENT_MODE == "FALSE") begin // DWord Aligned Mode
                        state            <= #TCQ PIO_RX_WAIT_STATE;
                        wr_be            <= #TCQ m_axis_cq_tuser[7:0];
                        wr_en            <= #TCQ 1'b1;
                        wr_addr          <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2]};
                        m_axis_cq_tready <= #TCQ 1'b0;
                        if(m_axis_cq_tdata[74:64] == 11'h002) begin // 2DWord Payload
                          wr_data        <= #TCQ m_axis_cq_tdata[191:128];
                        end
                        else if (m_axis_cq_tdata[74:64] == 11'h001) begin // 1DW Payload
                          wr_data       <= #TCQ { 32'b0, m_axis_cq_tdata[159:128]};
                        end
                      end // DWord Aligned Mode
                      else begin // Address Aligned Mode
                        state            <= #TCQ PIO_RX_DATA;
                        data_start_loc   <= #TCQ (AXISTEN_IF_CQ_ALIGNMENT_MODE  == "TRUE") ? {m_axis_cq_tdata_q[4:2]} : 3'b0;
                      end
                    end
                    else begin // Payload > 2DWORDs
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                      state            <= #TCQ PIO_RX_RST_STATE;
                    end

                  end // PIO_RX_IO_WR_FMT_TYPE


                  PIO_RX_ATOP_FAA_FMT_TYPE, PIO_RX_ATOP_UCS_FMT_TYPE, PIO_RX_ATOP_CAS_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    req_mem          <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    req_be           <= #TCQ m_axis_cq_tuser[7:0];
                    req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                    end
                    else begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                    end

                  end // PIO_RX_ATOP_FAA_FMT_TYPE, PIO_RX_ATOP_UCS_FMT_TYPE, PIO_RX_ATOP_CAS_FMT_TYPE


                  PIO_RX_MEM_LK_RD_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    req_be           <= #TCQ m_axis_cq_tuser[7:0];
                    req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];
                    req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2], 2'b00};
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b1;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                      req_mem_lock     <= #TCQ 1'b1;
                      req_at           <= #TCQ m_axis_cq_tdata[1:0];
                      payload_len   <=#TCQ m_axis_cq_tdata[65];
                    end
                    else begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                    end


                  end //PIO_RX_MEM_LK_RD_FMT_TYPE


                  PIO_RX_MSG_FMT_TYPE : begin

                    req_snoop_latency    <= #TCQ m_axis_cq_tdata[15:0];
                    req_no_snoop_latency <= #TCQ m_axis_cq_tdata[31:16];
                    req_obff_code        <= #TCQ m_axis_cq_tdata[35:32];
                    trn_type             <= #TCQ m_axis_cq_tdata[78:75];
                    req_len              <= #TCQ m_axis_cq_tdata[74:64];
                    req_mem              <= #TCQ 1'b0;
                    m_axis_cq_tready     <= #TCQ 1'b0;
                    req_tc               <= #TCQ m_axis_cq_tdata[123:121];
                    req_attr             <= #TCQ m_axis_cq_tdata[126:124];
                    req_at               <= #TCQ m_axis_cq_tdata[1:0];
                    req_rid              <= #TCQ m_axis_cq_tdata[95:80];
                    req_tag              <= #TCQ m_axis_cq_tdata[103:96];
                    req_be               <= #TCQ m_axis_cq_tuser[7:0];
                    req_msg_code         <= #TCQ m_axis_cq_tdata[111:104];
                    req_msg_route        <= #TCQ m_axis_cq_tdata[107:105];
                    state                <= #TCQ PIO_RX_RST_STATE;

                  end // PIO_RX_MSG_FMT_TYPE


                  PIO_RX_MSG_VD_FMT_TYPE : begin

                    trn_type             <= #TCQ m_axis_cq_tdata[78:75];
                    req_len              <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready     <= #TCQ 1'b0;
                    req_mem              <= #TCQ 1'b0;
                    req_tc               <= #TCQ m_axis_cq_tdata[123:121];
                    req_attr             <= #TCQ m_axis_cq_tdata[126:124];
                    req_rid              <= #TCQ m_axis_cq_tdata[95:80];
                    req_tag              <= #TCQ m_axis_cq_tdata[103:96];
                    req_be               <= #TCQ m_axis_cq_tuser[7:0];
                    req_at               <= #TCQ m_axis_cq_tdata[1:0];
                    req_msg_code         <= #TCQ m_axis_cq_tdata[111:104];
                    req_msg_route        <= #TCQ m_axis_cq_tdata[107:105];
                    req_dst_id           <= #TCQ m_axis_cq_tdata[15:0];
                    req_vend_id          <= #TCQ m_axis_cq_tdata[31:16];
                    req_vend_hdr         <= #TCQ m_axis_cq_tdata[63:32];
                    state                <= #TCQ PIO_RX_RST_STATE;

                  end // PIO_RX_MSG_VD_FMT_TYPE


                  PIO_RX_MSG_ATS_FMT_TYPE : begin

                    trn_type             <= #TCQ m_axis_cq_tdata[78:75];
                    req_len              <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready     <= #TCQ 1'b0;
                    req_mem              <= #TCQ 1'b0;
                    req_tc               <= #TCQ m_axis_cq_tdata[123:121];
                    req_attr             <= #TCQ m_axis_cq_tdata[126:124];
                    req_at               <= #TCQ m_axis_cq_tdata[1:0];
                    req_rid              <= #TCQ m_axis_cq_tdata[95:80];
                    req_tag              <= #TCQ m_axis_cq_tdata[103:96];
                    req_be               <= #TCQ m_axis_cq_tuser[7:0];
                    req_msg_code         <= #TCQ m_axis_cq_tdata[111:104];
                    req_msg_route        <= #TCQ m_axis_cq_tdata[107:105];
                    req_tl_hdr           <= #TCQ m_axis_cq_tdata[127:0];
                    state                <= #TCQ PIO_RX_RST_STATE;

                  end // PIO_RX_MSG_ATS_FMT_TYPE

                  default : begin // other TLPs

                    state        <= #TCQ PIO_RX_RST_STATE;
                  end

                endcase // Req_Type_fsm
              end //sop_if

            end // PIO_RX_RST_STATE


            PIO_RX_DATA : begin

              if (m_axis_cq_tvalid)
              begin
                wr_addr          <= #TCQ req_addr[12:2];
                case (data_start_loc)
                  3'b000 : begin
                    wr_data[31:0]    <= #TCQ m_axis_cq_tdata[31:0] ;
                    wr_data[63:32]   <= #TCQ payload_len ? m_axis_cq_tdata[63:32] : 32'h0;
                    wr_be            <= #TCQ payload_len ? m_axis_cq_tuser[15:8] : { 4'h0, m_axis_cq_tuser[11:8]};
                    wr_en            <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ 1'b0;
                  end
                  3'b001 : begin
                    wr_data[31:0]    <= #TCQ m_axis_cq_tdata[63:32] ;
                    wr_data[63:32]   <= #TCQ payload_len ? m_axis_cq_tdata[95:64] : 32'h0;
                    wr_be            <= #TCQ payload_len ? m_axis_cq_tuser[19:12] : { 4'h0, m_axis_cq_tuser[15:12]};
                    wr_en            <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ 1'b0;
                  end
                  3'b010 : begin
                    wr_data[31:0]    <= #TCQ m_axis_cq_tdata[95:64] ;
                    wr_data[63:32]   <= #TCQ payload_len ? m_axis_cq_tdata[127:96] : 32'h0;
                    wr_be            <= #TCQ payload_len ? m_axis_cq_tuser[23:16] : { 4'h0, m_axis_cq_tuser[19:16]};
                    wr_en            <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ 1'b0;
                  end
                  3'b011 : begin
                    wr_data[31:0]    <= #TCQ m_axis_cq_tdata[127:96];
                    wr_data[63:32]   <= #TCQ payload_len ? m_axis_cq_tdata[159:128] : 32'h0;
                    wr_be            <= #TCQ payload_len ? m_axis_cq_tuser[27:20] : { 4'h0, m_axis_cq_tuser[23:20]};
                    wr_en            <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ 1'b0;
                  end
                  3'b100 : begin
                    wr_data[31:0]    <= #TCQ m_axis_cq_tdata[159:128];
                    wr_data[63:32]   <= #TCQ payload_len ? m_axis_cq_tdata[191:160] : 32'h0;
                    wr_be            <= #TCQ payload_len ? m_axis_cq_tuser[31:24] : { 4'h0, m_axis_cq_tuser[27:24]};
                    wr_en            <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ 1'b0;
                  end
                  3'b101 : begin
                    wr_data[31:0]    <= #TCQ m_axis_cq_tdata[191:160];
                    wr_data[63:32]   <= #TCQ payload_len ? m_axis_cq_tdata[223:192] : 32'h0;
                    wr_be            <= #TCQ payload_len ? m_axis_cq_tuser[35:28] : { 4'h0, m_axis_cq_tuser[31:28]};
                    wr_en            <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ 1'b0;
                  end
                  3'b110 : begin
                    wr_data[31:0]    <= #TCQ m_axis_cq_tdata[223:192];
                    wr_data[63:32]   <= #TCQ payload_len ? m_axis_cq_tdata[255:224] : 32'h0;
                    wr_be            <= #TCQ payload_len ? m_axis_cq_tuser[39:32] : { 4'h0, m_axis_cq_tuser[35:32]};
                    wr_en            <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ 1'b0;
                  end
                  3'b111 : begin
                    wr_data[31:0]    <= #TCQ m_axis_cq_tdata[255:224];
                    wr_data[63:32]   <= #TCQ 32'h0;
                    wr_be            <= #TCQ { 4'h0, m_axis_cq_tuser[39:36]};
                    wr_en            <= #TCQ payload_len ? 1'b0 : 1'b1;
                    state            <= #TCQ payload_len ? PIO_RX_DATA2 : PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ payload_len ? 1'b1 : 1'b0;
                  end
                  default : begin
                    state        <= #TCQ PIO_RX_DATA;
                  end
                endcase
              end // if (m_axis_cq_tvalid)
              else
                state        <= #TCQ PIO_RX_DATA;

            end // PIO_RX_DATA

            PIO_RX_DATA2 : begin

              if (m_axis_cq_tvalid && m_axis_cq_tlast)
              begin

                  wr_data[63:32]   <= #TCQ m_axis_cq_tdata[31:0];
                  wr_be[7:4]       <= #TCQ m_axis_cq_tuser[11:8];
                  wr_en            <= #TCQ 1'b1;
                  m_axis_cq_tready <= #TCQ 1'b0;
                  state            <= #TCQ PIO_RX_WAIT_STATE;

              end // if (m_axis_cq_tvalid)
              else
              state        <= #TCQ PIO_RX_DATA2;

            end // PIO_RX_DATA2

            PIO_RX_WAIT_STATE : begin

              wr_en      <= #TCQ 1'b0;
              req_compl  <= #TCQ 1'b0;
              req_compl_wd  <= #TCQ 1'b0;

              if ((trn_type == PIO_RX_MEM_WR_FMT_TYPE) && (!wr_busy))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_IO_WR_FMT_TYPE) && (!wr_busy))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_MEM_RD_FMT_TYPE) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_MEM_LK_RD_FMT_TYPE) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_IO_RD_FMT_TYPE) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if (((trn_type == PIO_RX_ATOP_FAA_FMT_TYPE) || (trn_type == PIO_RX_ATOP_UCS_FMT_TYPE) ||
                            (trn_type == PIO_RX_ATOP_CAS_FMT_TYPE)) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;
              end else
                state        <= #TCQ PIO_RX_WAIT_STATE;

            end // PIO_RX_WAIT_STATE
          endcase // state
        end // reset_n
      end // End of always Block
     end

    else begin : pio_rx_sm_512

      always@(posedge user_clk) begin
        if(!reset_n) begin

          m_axis_cq_tready    <= #TCQ 1'b0;
          m_axis_rc_tready    <= #TCQ 1'b1;
          pcie_cq_np_req      <= #TCQ 1'b1;

          req_compl           <= #TCQ 1'b0;
          req_compl_wd        <= #TCQ 1'b0;
          req_compl_ur        <= #TCQ 1'b0;

          req_tc              <= #TCQ 3'b0;
          req_attr            <= #TCQ 3'b0;
          req_len             <= #TCQ 11'b0;
          req_rid             <= #TCQ 16'b0;
          req_tag             <= #TCQ 8'b0;
          req_be              <= #TCQ 8'b0;
          req_addr            <= #TCQ 13'b0;
          req_at              <= #TCQ 2'b0;

          wr_be               <= #TCQ 8'b0;
          wr_addr             <= #TCQ 11'b0;
          wr_data             <= #TCQ 64'h0;
          wr_en               <= #TCQ 1'b0;
          payload_len         <= #TCQ 1'b0;
          data_start_loc      <= #TCQ 3'b0;

          state               <= #TCQ PIO_RX_RST_STATE;
          trn_type            <= #TCQ 4'b0;

          req_snoop_latency   <= #TCQ 16'b0;
          req_no_snoop_latency<= #TCQ 16'b0;
          req_obff_code       <= #TCQ 4'b0;
          req_msg_code        <= #TCQ 8'b0;
          req_msg_route       <= #TCQ 3'b0;
          req_dst_id          <= #TCQ 16'b0;
          req_vend_id         <= #TCQ 16'b0;
          req_vend_hdr        <= #TCQ 32'b0;
          req_tl_hdr          <= #TCQ 128'b0;

          req_des_qword0      <= #TCQ 64'b0;
          req_des_qword1      <= #TCQ 64'b0;
          req_des_tph_present <= #TCQ 1'b0;
          req_des_tph_type    <= #TCQ 2'b0;
          req_des_tph_st_tag  <= #TCQ 8'b0;

          req_mem_lock        <= #TCQ 1'b0;
          req_mem             <= #TCQ 1'b0;
	  m_axis_cq_tparity   <= #TCQ 64'b0;
	  m_axis_cq_tparity_q <= #TCQ 64'b0;
	   m_axis_cq_tvalid_reg <= #TCQ 1'b0;

        end

        else begin

          wr_en               <= #TCQ 1'b0;
          req_compl           <= #TCQ 1'b0;
	  m_axis_cq_tparity   <= #TCQ m_axis_cq_tuser[182:119];
	  m_axis_cq_tparity_q <= #TCQ m_axis_cq_tuser_q[182:119];
	  m_axis_cq_tvalid_reg <= #TCQ m_axis_cq_tvalid;

          case (state)

            PIO_RX_RST_STATE : begin

              m_axis_cq_tready <= #TCQ 1'b1;
              m_axis_rc_tready <= #TCQ 1'b1;
              //req_compl_wd     <= #TCQ 1'b1;

              if (sop) begin //sop_if

                case( m_axis_cq_tdata[78:75] ) // Req_Type_fsm

                  PIO_RX_MEM_RD_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    req_mem          <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    req_be           <= #TCQ {m_axis_cq_tuser[11:8],m_axis_cq_tuser[3:0]};
                    req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];
                    req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2], 2'b00};
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b1;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                      req_at           <= #TCQ m_axis_cq_tdata[1:0];
                      payload_len    <=#TCQ m_axis_cq_tdata[65];
                    end
                    else begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                    end

                  end  // PIO_RX_MEM_RD_FMT_TYPE


                  PIO_RX_MEM_WR_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    req_mem          <= #TCQ 1'b0;
                    if(m_axis_cq_tdata[74:64] == 11'h002) // 2DWord Payload
                      payload_len    <=#TCQ 1'b1;
                    else
                      payload_len   <=#TCQ 1'b0;

                    if(AXISTEN_IF_CQ_ALIGNMENT_MODE == "FALSE") begin // DWord Aligned Mode
                      if(m_axis_cq_tdata[74:64] == 11'h002) begin // 2DWord Payload
                        wr_data        <= #TCQ m_axis_cq_tdata[191:128];
                      end
                      else if (m_axis_cq_tdata[74:64] == 11'h001) begin // 1DW Payload
                        wr_data       <= #TCQ { 32'b0, m_axis_cq_tdata[159:128]};
                      end
		    end 

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin

                      if(AXISTEN_IF_CQ_ALIGNMENT_MODE == "FALSE") begin // DWord Aligned Mode
                        state            <= #TCQ PIO_RX_WAIT_STATE;
                        wr_be            <= #TCQ {m_axis_cq_tuser[11:8],m_axis_cq_tuser[3:0]};
                        wr_en            <= #TCQ 1'b1;
                        wr_addr          <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2]};
                        m_axis_cq_tready <= #TCQ 1'b0;
                      end // DWord Aligned Mode
                      else begin // Address Aligned Mode
                        state            <= #TCQ PIO_RX_DATA;
                        req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2], 2'b00};
                        data_start_loc   <= #TCQ (AXISTEN_IF_CQ_ALIGNMENT_MODE  == "TRUE") ? {m_axis_cq_tdata[4:2]} : 3'b0;
                      end

                      end
                    else begin // Payload > 2DWORD
                      state            <= #TCQ PIO_RX_RST_STATE;
                    end
                  end // PIO_RX_MEM_WR_FMT_TYPE


                  PIO_RX_IO_RD_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    req_mem          <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    req_be           <= #TCQ {m_axis_cq_tuser[11:8],m_axis_cq_tuser[3:0]};
                    req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];
                    req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2], 2'b00};
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b1;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                      req_at           <= #TCQ m_axis_cq_tdata[1:0];
                      payload_len    <=#TCQ m_axis_cq_tdata[65];
                    end
                    else begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                    end

                  end //PIO_RX_IO_RD_FMT_TYPE


                  PIO_RX_IO_WR_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    req_mem          <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    req_be           <= #TCQ {m_axis_cq_tuser[11:8],m_axis_cq_tuser[3:0]};
                    req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2], 2'b00};
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];
                    req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                      req_at           <= #TCQ m_axis_cq_tdata[1:0];
                      payload_len   <=#TCQ m_axis_cq_tdata[65];
                      if(AXISTEN_IF_CQ_ALIGNMENT_MODE == "FALSE") begin // DWord Aligned Mode
                        state            <= #TCQ PIO_RX_WAIT_STATE;
                        wr_be            <= #TCQ {m_axis_cq_tuser[11:8],m_axis_cq_tuser[3:0]};
                        wr_en            <= #TCQ 1'b1;
                        wr_addr          <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2]};
                        m_axis_cq_tready <= #TCQ 1'b0;
                        if(m_axis_cq_tdata[74:64] == 11'h002) begin // 2DWord Payload
                          wr_data        <= #TCQ m_axis_cq_tdata[191:128];
                        end
                        else if (m_axis_cq_tdata[74:64] == 11'h001) begin // 1DW Payload
                          wr_data       <= #TCQ { 32'b0, m_axis_cq_tdata[159:128]};
                        end
                      end // DWord Aligned Mode
                      else begin // Address Aligned Mode
                        state            <= #TCQ PIO_RX_DATA;
                        data_start_loc   <= #TCQ (AXISTEN_IF_CQ_ALIGNMENT_MODE  == "TRUE") ? {m_axis_cq_tdata[4:2]} : 3'b0;
                      end
                    end
                    else begin // Payload > 2DWORDs
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                      state            <= #TCQ PIO_RX_RST_STATE;
                    end

                  end // PIO_RX_IO_WR_FMT_TYPE


                  PIO_RX_ATOP_FAA_FMT_TYPE, PIO_RX_ATOP_UCS_FMT_TYPE, PIO_RX_ATOP_CAS_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    req_mem          <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    req_be           <= #TCQ {m_axis_cq_tuser[11:8],m_axis_cq_tuser[3:0]};
                    req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                    end
                    else begin
                      req_compl        <= #TCQ 1'b0;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                    end

                  end // PIO_RX_ATOP_FAA_FMT_TYPE, PIO_RX_ATOP_UCS_FMT_TYPE, PIO_RX_ATOP_CAS_FMT_TYPE


                  PIO_RX_MEM_LK_RD_FMT_TYPE : begin

                    trn_type         <= #TCQ m_axis_cq_tdata[78:75];
                    req_len          <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready <= #TCQ 1'b0;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    req_be           <= #TCQ {m_axis_cq_tuser[11:8],m_axis_cq_tuser[3:0]};
                    req_des_qword0      <= #TCQ m_axis_cq_tdata[63:0];
                    req_des_qword1      <= #TCQ m_axis_cq_tdata[127:64];
                    req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata[10:2], 2'b00};
                    req_des_tph_present <= #TCQ m_axis_cq_tuser[42];
                    req_des_tph_type    <= #TCQ m_axis_cq_tuser[44:43];
                    req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser[52:45];

                    if((m_axis_cq_tdata[74:64] == 11'h001) || (m_axis_cq_tdata[74:64] == 11'h002))
                    begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b1;
                      req_tc           <= #TCQ m_axis_cq_tdata[123:121];
                      req_attr         <= #TCQ m_axis_cq_tdata[126:124];
                      req_rid          <= #TCQ m_axis_cq_tdata[95:80];
                      req_tag          <= #TCQ m_axis_cq_tdata[103:96];
                      req_mem_lock     <= #TCQ 1'b1;
                      req_at           <= #TCQ m_axis_cq_tdata[1:0];
                      payload_len   <=#TCQ m_axis_cq_tdata[65];
                    end
                    else begin
                      req_compl        <= #TCQ 1'b1;
                      req_compl_wd     <= #TCQ 1'b0;
                      req_compl_ur     <= #TCQ 1'b1;
                    end


                  end //PIO_RX_MEM_LK_RD_FMT_TYPE


                  PIO_RX_MSG_FMT_TYPE : begin

                    req_snoop_latency    <= #TCQ m_axis_cq_tdata[15:0];
                    req_no_snoop_latency <= #TCQ m_axis_cq_tdata[31:16];
                    req_obff_code        <= #TCQ m_axis_cq_tdata[35:32];
                    trn_type             <= #TCQ m_axis_cq_tdata[78:75];
                    req_len              <= #TCQ m_axis_cq_tdata[74:64];
                    req_mem              <= #TCQ 1'b0;
                    m_axis_cq_tready     <= #TCQ 1'b0;
                    req_tc               <= #TCQ m_axis_cq_tdata[123:121];
                    req_attr             <= #TCQ m_axis_cq_tdata[126:124];
                    req_at               <= #TCQ m_axis_cq_tdata[1:0];
                    req_rid              <= #TCQ m_axis_cq_tdata[95:80];
                    req_tag              <= #TCQ m_axis_cq_tdata[103:96];
                    req_be               <= #TCQ {m_axis_cq_tuser[11:8],m_axis_cq_tuser[3:0]};
                    req_msg_code         <= #TCQ m_axis_cq_tdata[111:104];
                    req_msg_route        <= #TCQ m_axis_cq_tdata[107:105];
                    state                <= #TCQ PIO_RX_RST_STATE;

                  end // PIO_RX_MSG_FMT_TYPE


                  PIO_RX_MSG_VD_FMT_TYPE : begin

                    trn_type             <= #TCQ m_axis_cq_tdata[78:75];
                    req_len              <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready     <= #TCQ 1'b0;
                    req_mem              <= #TCQ 1'b0;
                    req_tc               <= #TCQ m_axis_cq_tdata[123:121];
                    req_attr             <= #TCQ m_axis_cq_tdata[126:124];
                    req_rid              <= #TCQ m_axis_cq_tdata[95:80];
                    req_tag              <= #TCQ m_axis_cq_tdata[103:96];
                    req_be               <= #TCQ {m_axis_cq_tuser[11:8],m_axis_cq_tuser[3:0]};
                    req_at               <= #TCQ m_axis_cq_tdata[1:0];
                    req_msg_code         <= #TCQ m_axis_cq_tdata[111:104];
                    req_msg_route        <= #TCQ m_axis_cq_tdata[107:105];
                    req_dst_id           <= #TCQ m_axis_cq_tdata[15:0];
                    req_vend_id          <= #TCQ m_axis_cq_tdata[31:16];
                    req_vend_hdr         <= #TCQ m_axis_cq_tdata[63:32];
                    state                <= #TCQ PIO_RX_RST_STATE;

                  end // PIO_RX_MSG_VD_FMT_TYPE


                  PIO_RX_MSG_ATS_FMT_TYPE : begin

                    trn_type             <= #TCQ m_axis_cq_tdata[78:75];
                    req_len              <= #TCQ m_axis_cq_tdata[74:64];
                    m_axis_cq_tready     <= #TCQ 1'b0;
                    req_mem              <= #TCQ 1'b0;
                    req_tc               <= #TCQ m_axis_cq_tdata[123:121];
                    req_attr             <= #TCQ m_axis_cq_tdata[126:124];
                    req_at               <= #TCQ m_axis_cq_tdata[1:0];
                    req_rid              <= #TCQ m_axis_cq_tdata[95:80];
                    req_tag              <= #TCQ m_axis_cq_tdata[103:96];
                    req_be               <= #TCQ {m_axis_cq_tuser[11:8],m_axis_cq_tuser[3:0]};
                    req_msg_code         <= #TCQ m_axis_cq_tdata[111:104];
                    req_msg_route        <= #TCQ m_axis_cq_tdata[107:105];
                    req_tl_hdr           <= #TCQ m_axis_cq_tdata[127:0];
                    state                <= #TCQ PIO_RX_RST_STATE;

                  end // PIO_RX_MSG_ATS_FMT_TYPE

                  default : begin // other TLPs

                    state        <= #TCQ PIO_RX_RST_STATE;
                  end

                endcase // Req_Type_fsm
              end //sop_if

            end // PIO_RX_RST_STATE


            PIO_RX_DATA : begin

              if (m_axis_cq_tvalid || m_axis_cq_tvalid_reg)
              begin
                wr_addr          <= #TCQ req_addr[12:2];
                case (data_start_loc[1:0])
                  2'b00 : begin
                    wr_data[31:0]    <= #TCQ m_axis_cq_tdata_q[159:128];
                    wr_data[63:32]   <= #TCQ payload_len ? m_axis_cq_tdata_q[191:160] : 32'h0;
                    wr_be            <= #TCQ payload_len ? m_axis_cq_tuser_reg[39:32] : { 4'h0, m_axis_cq_tuser_reg[35:32]};
                    wr_en            <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ 1'b0;
                  end
                  2'b01 : begin
                    wr_data[31:0]    <= #TCQ m_axis_cq_tdata_q[191:160];
                    wr_data[63:32]   <= #TCQ payload_len ? m_axis_cq_tdata_q[223:192] : 32'h0;
                    wr_be            <= #TCQ payload_len ? m_axis_cq_tuser_reg[43:36] : { 4'h0, m_axis_cq_tuser_reg[39:36]};
                    wr_en            <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ 1'b0;
                  end
                  2'b10 : begin
                    wr_data[31:0]    <= #TCQ m_axis_cq_tdata_q[223:192];
                    wr_data[63:32]   <= #TCQ payload_len ? m_axis_cq_tdata_q[255:224] : 32'h0;
                    wr_be            <= #TCQ payload_len ? m_axis_cq_tuser_reg[47:40] : { 4'h0, m_axis_cq_tuser_reg[43:40]};
                    wr_en            <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ 1'b0;
                  end
                  2'b11 : begin
                    wr_data[31:0]    <= #TCQ m_axis_cq_tdata_q[255:224];
                    wr_data[63:32]   <= #TCQ payload_len ? m_axis_cq_tdata_q[287:256] : 32'h0;
                    wr_be            <= #TCQ payload_len ? m_axis_cq_tuser_reg[51:44] : { 4'h0, m_axis_cq_tuser_reg[47:44]};
                    wr_en            <= #TCQ 1'b1;
                    state            <= #TCQ PIO_RX_WAIT_STATE;
                    m_axis_cq_tready <= #TCQ 1'b0;
                  end
                  default : begin
                    state        <= #TCQ PIO_RX_DATA;
                  end
                endcase
              end // if (m_axis_cq_tvalid)
              else
                state        <= #TCQ PIO_RX_DATA;

            end // PIO_RX_DATA

            PIO_RX_DATA2 : begin

              if (m_axis_cq_tvalid && m_axis_cq_tlast)
              begin

                  wr_data[63:32]   <= #TCQ m_axis_cq_tdata[31:0];
                  wr_be[7:4]       <= #TCQ m_axis_cq_tuser[11:8];
                  wr_en            <= #TCQ 1'b1;
                  m_axis_cq_tready <= #TCQ 1'b0;
                  state            <= #TCQ PIO_RX_WAIT_STATE;

              end // if (m_axis_cq_tvalid)
              else
              state        <= #TCQ PIO_RX_DATA2;

            end // PIO_RX_DATA2

            PIO_RX_WAIT_STATE : begin

              wr_en      <= #TCQ 1'b0;
              req_compl  <= #TCQ 1'b0;
              req_compl_wd  <= #TCQ 1'b0;

              if ((trn_type == PIO_RX_MEM_WR_FMT_TYPE) && (!wr_busy))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_IO_WR_FMT_TYPE) && (!wr_busy))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_MEM_RD_FMT_TYPE) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_MEM_LK_RD_FMT_TYPE) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if ((trn_type == PIO_RX_IO_RD_FMT_TYPE) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;

              end else if (((trn_type == PIO_RX_ATOP_FAA_FMT_TYPE) || (trn_type == PIO_RX_ATOP_UCS_FMT_TYPE) ||
                            (trn_type == PIO_RX_ATOP_CAS_FMT_TYPE)) && (compl_done))
              begin

                m_axis_cq_tready <= #TCQ 1'b1;
                state        <= #TCQ PIO_RX_RST_STATE;
              end else
                state        <= #TCQ PIO_RX_WAIT_STATE;

            end // PIO_RX_WAIT_STATE
          endcase // state
        end // reset_n
      end // End of always Block


    end // pio_rx_sm_512

  endgenerate


  assign io_bar_hit_n    = (m_axis_cq_tdata[BAR_ID_SELECT+:3] == 3'b010) ? 1'b0 : 1'b1;
  assign mem64_bar_hit_n = 1'b1;
  assign erom_bar_hit_n  = (m_axis_cq_tdata[BAR_ID_SELECT+:3] == 3'b110) ? 1'b0 : 1'b1;
  assign mem32_bar_hit_n = (m_axis_cq_tdata[BAR_ID_SELECT+:3] == 3'b000) ? 1'b0 : 1'b1;

  always @*
  begin
    case ({io_bar_hit_n, mem32_bar_hit_n, mem64_bar_hit_n, erom_bar_hit_n})

      4'b0111 : begin
        region_select <= #TCQ 2'b00;    // Select IO region
      end

      4'b1011 : begin
        region_select <= #TCQ 2'b01;    // Select Mem32 region
      end

      4'b1101 : begin
        region_select <= #TCQ 2'b10;    // Select Mem64 region
      end

      4'b1110 : begin
        region_select <= #TCQ 2'b11;    // Select EROM region
      end

      default : begin
        region_select <= #TCQ 2'b00;    // Error selection will select IO region
      end

    endcase

  end

  // synthesis translate_off
  reg  [8*20:1] state_ascii;
  always @(state)
  begin
    case (state)
      PIO_RX_RST_STATE              : state_ascii <= #TCQ "RX_RST_STATE";
      PIO_RX_WAIT_STATE             : state_ascii <= #TCQ "RX_WAIT_STATE";
      PIO_RX_64_QW1                 : state_ascii <= #TCQ "RX_64_QW1";
      PIO_RX_DATA                   : state_ascii <= #TCQ "RX_DATA";
      PIO_RX_DATA2                  : state_ascii <= #TCQ "RX_DATA2";
      default                       : state_ascii <= #TCQ "PIO STATE ERR";
    endcase

  end
  // synthesis translate_on

endmodule // pio_rx_engine
