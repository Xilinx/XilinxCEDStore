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
// Project    : Everest FPGA PCI Express Integrated Block
// File       : BMD_AXIST_CC_512.sv
// Version    : 1.0 
//-----------------------------------------------------------------------------

`include "pcie_app_versal_bmd.vh"
`timescale 1ps / 1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_CC_512 #(
   parameter         AXISTEN_IF_CMP_ALIGNMENT_MODE = 0,
   parameter         AXISTEN_IF_CC_STRADDLE        = 0,
   parameter         AXISTEN_IF_CMP_PARITY_CHECK   = 0,
   parameter         AXI4_CQ_TUSER_WIDTH           = 183,
   parameter         AXI4_CC_TUSER_WIDTH           = 81,
   parameter         AXI4_RQ_TUSER_WIDTH           = 137,
   parameter         AXI4_RC_TUSER_WIDTH           = 161,
   parameter         TCQ                           = 1
)(
   // Clock and Reset
   input                            user_clk,
   input                            reset_n,

   // AXI-S Completer Competion Interface
   output logic [511:0]             s_axis_cc_tdata,
   output logic [15:0]              s_axis_cc_tkeep,
   output logic                     s_axis_cc_tlast,
   output logic                     s_axis_cc_tvalid,
   output logic [80:0]              s_axis_cc_tuser,
   input                            s_axis_cc_tready,

   // TX Message Interface
   output logic                     cfg_msg_transmit,
   output logic [2:0]               cfg_msg_transmit_type,
   output logic [31:0]              cfg_msg_transmit_data,

   // BMD_AXIST RX Engine Interface
   input                            req_compl,
   input                            req_compl_wd,
   input                            req_compl_ur,
   input                            payload_len,
   output logic                     compl_done,

   input        [2:0]               req_tc,
   input        [2:0]               req_attr,
   input        [15:0]              req_rid,
   input        [9:0]               req_tag,
   input        [7:0]               req_be,
   input        [12:0]              req_addr, 
   input        [1:0]               req_at,

   //Indicate that the Request was a Mem lock Read Req  // Inputs to the TX Block in case of an UR
   // Required to form the completions
   input        [63:0]              req_des_qword0,
   input        [63:0]              req_des_qword1,
   input                            req_des_tph_present,
   input        [1:0]               req_des_tph_type,
   input        [7:0]               req_des_tph_st_tag,

   input                            req_mem_lock,
   input                            req_mem,

   // BMD_AXIST Memory Access Control Interface
   output logic [10:0]              rd_addr,
   output logic [3:0]               rd_be,
   input        [31:0]              rd_data
);
   `STRUCT_AXI_CC_IF

   logic          dword_count;
   logic [31:0]   rd_data_reg;   // To Store the 1st rd_data in case of 2DW payload
   logic [6:0]    lower_addr;
   logic [3:0]    state;
   logic          req_compl_q, req_compl_qq;
   logic          req_compl_wd_q, req_compl_wd_qq;
   logic          req_compl_ur_q, req_compl_ur_qq;

   logic [511:0]  s_axis_cc_tdata_wire;
   logic [63:0]   s_axis_cc_parity;
   reg   [6:0]    lower_addr_q;

   // TODO: Legacy code, need to review
   localparam BMD_AXIST_TX_RST_STATE                  = 4'b0000;
   localparam BMD_AXIST_TX_COMPL_C1                   = 4'b0001;
   localparam BMD_AXIST_TX_COMPL_WD_C1                = 4'b0011;
   localparam BMD_AXIST_TX_COMPL_PYLD                 = 4'b0101;
   localparam BMD_AXIST_TX_CPL_UR_C1                  = 4'b0110;
   localparam BMD_AXIST_TX_COMPL_WD_2DW               = 4'b1010;
   localparam BMD_AXIST_TX_COMPL_WD_2DW_ADDR_ALGN_C1  = 4'b1011;
   localparam BMD_AXIST_TX_COMPL_WD_2DW_ADDR_ALGN_C2  = 4'b1100;
 
   `BMDREG(user_clk, reset_n, req_compl_q, req_compl, 'd0)
   `BMDREG(user_clk, reset_n, req_compl_wd_q, req_compl_wd, 'd0)
   `BMDREG(user_clk, reset_n, req_compl_ur_q, req_compl_ur, 'd0)
   `BMDREG(user_clk, reset_n, req_compl_qq, req_compl_q, 'd0)
   `BMDREG(user_clk, reset_n, req_compl_wd_qq, req_compl_wd_q, 'd0)
   `BMDREG(user_clk, reset_n, req_compl_ur_qq, req_compl_ur_q, 'd0)

   // Calculate lower address based on byte enable
   always_comb begin
      casex ({req_compl_wd_qq, rd_be[3:0]})
         5'b0_xxxx : lower_addr = 8'h0;
         5'b1_0000 : lower_addr = {req_addr[6:2], 2'b00};
         5'b1_xxx1 : lower_addr = {req_addr[6:2], 2'b00};
         5'b1_xx10 : lower_addr = {req_addr[6:2], 2'b01};
         5'b1_x100 : lower_addr = {req_addr[6:2], 2'b10};
         5'b1_1000 : lower_addr = {req_addr[6:2], 2'b11};
      endcase
   end

   always_ff @ ( posedge user_clk ) begin
      if(!reset_n ) begin
        lower_addr_q    <= #TCQ 'd0;
      end
      else begin
        lower_addr_q    <= #TCQ lower_addr;
      end
   end
   // Generate parity for data
   always_comb begin
      case (state)
         BMD_AXIST_TX_COMPL_C1 :
            s_axis_cc_tdata_wire = {416'b0,        // Tied to 0 for 3DW completion descriptor
                                    1'b0,          // Force ECRC
                                    req_attr,      // 3- bits
                                    req_tc,        // 3- bits
                                    1'b0,          // Completer ID to control selection of Client
                                                   // Supplied Bus number
                                    8'hAA,         // Completer Bus number - selected if Compl ID    = 1
                                    8'hBB,         // Compl Dev / Func no - sel if Compl ID = 1
                                    req_tag[7:0],  // Select Client Tag or core's internal tag
                                    req_rid,       // Requester ID - 16 bits
                                    req_tag[9],    // T9
                                    1'b0,          // Poisoned completion
                                    3'b000,        // SuccessFull completion
                                    (req_mem ? (11'h1 + payload_len) : 11'b0),         // DWord Count 0 - IO Write completions
                                    req_tag[8],    // T8
                                    1'b0,          // Rsvd
                                    1'b0,          // Locked Read Completion
                                    13'h0004,      // Byte Count
                                    6'b0,          // Rsvd
                                    req_at,        // Adress Type - 2 bits
                                    1'b0,          // Rsvd
                                    lower_addr};   // Starting address of the mem byte - 7 bits         
         BMD_AXIST_TX_COMPL_WD_C1 :
          if(AXISTEN_IF_CMP_ALIGNMENT_MODE == "FALSE") begin // DWORD_aligned_Mode
            s_axis_cc_tdata_wire = {384'b0,        // Tied to 0 for 3DW completion descriptor
                                    rd_data,       // 32- bit read data
                                    1'b0,          // Force ECRC
                                    req_attr,      // 3- bits
                                    req_tc,        // 3- bits
                                    1'b0,          // Completer ID to control selection of Client
                                                   // Supplied Bus number
                                    8'hAA,         // Completer Bus number - selected if Compl ID    = 1
                                    8'hBB,         // Compl Dev / Func no - sel if Compl ID = 1
                                    req_tag[7:0],  // Select Client Tag or core's internal tag
                                    req_rid,       // Requester ID - 16 bits
                                    req_tag[9],    // T9
                                    1'b0,          // Poisoned completion
                                    3'b000,        // SuccessFull completion
                                    (req_mem ? (11'h1 + payload_len) : 11'b1),         // DWord Count 0 - IO Write completions
                                    req_tag[8],    // T8
                                    1'b0,          // Rsvd
                                    (req_mem_lock? 1'b1 : 1'b0),  // Locked Read Completion
                                    13'h0004,      // Byte Count
                                    6'b0,          // Rsvd
                                    req_at,        // Adress Type - 2 bits
                                    1'b0,          // Rsvd
                                    lower_addr};   // Starting address of the mem byte - 7 bits
          end
          else begin // Addr_aligned_mode
            s_axis_cc_tdata_wire[511:128]  =  (lower_addr[3:2]==2'b00)   ? {256'b0, 96'b0, rd_data}
                                             :(lower_addr[3:2]==2'b01)   ? {256'b0, 64'b0, rd_data, 32'b0}
                                             :(lower_addr[3:2]==2'b10)   ? {256'b0, 32'b0, rd_data, 64'b0}
                                             :/*(lower_addr[3:2]==2'b11)?*/{256'b0,        rd_data, 96'b0};
            s_axis_cc_tdata_wire[127:0]    =  {
                                    32'b0,         // Tied to 0 for 3DW completion descriptor
                                    1'b0,          // Force ECRC
                                    req_attr,      // 3- bits
                                    req_tc,        // 3- bits
                                    1'b0,          // Completer ID to control selection of Client
                                                   // Supplied Bus number
                                    8'hAA,         // Completer Bus number - selected if Compl ID    = 1
                                    8'hBB,         // Compl Dev / Func no - sel if Compl ID = 1
                                    req_tag[7:0],  // Select Client Tag or core's internal tag
                                    req_rid,       // Requester ID - 16 bits
                                    req_tag[9],    // T9
                                    1'b0,          // Poisoned completion
                                    3'b000,        // SuccessFull completion
                                    (req_mem ? (11'h1 + payload_len) : 11'b1),         // DWord Count 0 - IO Write completions
                                    req_tag[8],    // T8
                                    1'b0,          // Rsvd
                                    (req_mem_lock? 1'b1 : 1'b0),      // Locked Read Completion
                                    13'h0004,      // Byte Count
                                    6'b0,          // Rsvd
                                    req_at,        // Adress Type - 2 bits
                                    1'b0,          // Rsvd
                                    lower_addr};   // Starting address of the mem byte - 7 bits
          end
         BMD_AXIST_TX_CPL_UR_C1 :
            s_axis_cc_tdata_wire = {req_des_qword1, // 64 bits - Descriptor of the request 2 DW
                                    req_des_qword0, // 64 bits - Descriptor of the request 2 DW
                                    8'b0, // Rsvd
                                    req_des_tph_st_tag,   // TPH Steering tag - 8 bits
                                    5'b0,  // Rsvd
                                    req_des_tph_type,    // TPH type - 2 bits
                                    req_des_tph_present, // TPH present - 1 bit
                                    req_be,          // Request Byte enables - 8bits
                                    1'b0,          // Force ECRC
                                    req_attr,      // 3- bits
                                    req_tc,        // 3- bits
                                    1'b0,          // Completer ID to control selection of Client
                                                   // Supplied Bus number
                                    8'hAA,         // Completer Bus number - selected if Compl ID    = 1
                                    8'hBB,         // Compl Dev / Func no - sel if Compl ID = 1
                                    req_tag[7:0],  // Select Client Tag or core's internal tag
                                    req_rid,       // Requester ID - 16 bits
                                    req_tag[9],    // T9
                                    1'b0,          // Poisoned completion
                                    3'b001,        // Completion Status - UR
                                    11'h005,       // DWord Count -55
                                    req_tag[8],    // T8
                                    1'b0,          // Rsvd
                                    (req_mem_lock? 1'b1 : 1'b0),   // Locked Read Completion
                                    13'h0014,      // Byte Count - 20 bytes of Payload
                                    6'b0,          // Rsvd
                                    req_at,        // Adress Type - 2 bits
                                    1'b0,          // Rsvd
                                    lower_addr};   // Starting address of the mem byte - 7 bits
         BMD_AXIST_TX_COMPL_PYLD : 
            s_axis_cc_tdata_wire = {480'b0, rd_data};
         BMD_AXIST_TX_COMPL_WD_2DW : 
            s_axis_cc_tdata_wire = {
                                    96'b0,         // Tied to 0 for 3DW completion descriptor with 2DW Payload
                                    rd_data,       // 32 bit read data
                                    rd_data_reg,   // 32- bit read data
                                    1'b0,          // Force ECRC
                                    req_attr,      // 3- bits
                                    req_tc,        // 3- bits
                                    1'b0,          // Completer ID to control selection of Client
                                                   // Supplied Bus number
                                    8'hAA,         // Completer Bus number - selected if Compl ID    = 1
                                    8'hBB,         // Compl Dev / Func no - sel if Compl ID = 1
                                    req_tag[7:0],  // Select Client Tag or core's internal tag
                                    req_rid,       // Requester ID - 16 bits
                                    req_tag[9],    // T9
                                    1'b0,          // Poisoned completion
                                    3'b000,        // SuccessFull completion
                                    (req_mem ? (11'h1 + payload_len) : 11'b1),         // DWord Count 0 - IO Write completions
                                    req_tag[8],    // T8
                                    1'b0,          // Rsvd
                                    (req_mem_lock? 1'b1 : 1'b0),   // Locked Read Completion
                                    13'h0004,      // Byte Count
                                    6'b0,          // Rsvd
                                    req_at,        // Adress Type - 2 bits
                                    1'b0,          // Rsvd
                                    lower_addr};   // Starting address of the mem byte - 7 bits
         BMD_AXIST_TX_COMPL_WD_2DW_ADDR_ALGN_C1 : begin // Completions with 2-DW Payload and Addr aligned mode -- Not implemented for 512
            s_axis_cc_tdata_wire[511:128] =  (lower_addr_q[3:2]==2'b00)   ? {256'b0, 64'b0, rd_data,rd_data_reg}
                                            :(lower_addr_q[3:2]==2'b01)   ? {256'b0, 32'b0, rd_data,rd_data_reg, 32'b0}
                                            :(lower_addr_q[3:2]==2'b10)   ? {256'b0,        rd_data,rd_data_reg, 64'b0}
                                            :/*(lower_addr_q[3:2]==2'b11)?*/{224'b0,        rd_data,rd_data_reg, 96'b0};
            s_axis_cc_tdata_wire[127:0]    = {
                                    32'b0,         // Tied to 0 for 3DW completion descriptor with 2DW Payload
                                    1'b0,          // Force ECRC
                                    req_attr,      // 3- bits
                                    req_tc,        // 3- bits
                                    1'b0,          // Completer ID to control selection of Client
                                                   // Supplied Bus number
                                    8'hAA,         // Completer Bus number - selected if Compl ID    = 1
                                    8'hBB,         // Compl Dev / Func no - sel if Compl ID = 1
                                    req_tag[7:0],  // Select Client Tag or core's internal tag
                                    req_rid,       // Requester ID - 16 bits
                                    req_tag[9],    // T9
                                    1'b0,          // Poisoned completion
                                    3'b000,        // SuccessFull completion
                                    (req_mem ? (11'h1 + payload_len) : 11'b1),         // DWord Count 0 - IO Write completions
                                    req_tag[8],    // T8
                                    1'b0,          // Rsvd
                                    (req_mem_lock? 1'b1 : 1'b0),   // Locked Read Completion
                                    13'h0004,      // Byte Count
                                    6'b0,          // Rsvd
                                    req_at,        // Adress Type - 2 bits
                                    1'b0,          // Rsvd
                                    lower_addr_q}; // Starting address of the mem byte - 7 bits
         end
         default: s_axis_cc_tdata_wire = 512'd0;
      endcase
   end

genvar var_i;
generate
   for (var_i = 0; var_i < 64; var_i = var_i + 1) begin: rq_parity_generation
      assign s_axis_cc_parity[var_i] =  ~(^s_axis_cc_tdata_wire[8*(var_i+1)-1:8*var_i]);
   end
endgenerate

   always_ff @ ( posedge user_clk ) begin
      if(!reset_n ) begin
        state                   <= #TCQ BMD_AXIST_TX_RST_STATE;
        s_axis_cc_tdata         <= #TCQ 'd0;
        s_axis_cc_tkeep         <= #TCQ 'd0;
        s_axis_cc_tlast         <= #TCQ 1'b0;
        s_axis_cc_tvalid        <= #TCQ 1'b0;
        s_axis_cc_tuser         <= #TCQ 81'b0;
        cfg_msg_transmit        <= #TCQ 1'b0;
        cfg_msg_transmit_type   <= #TCQ 3'b0;
        cfg_msg_transmit_data   <= #TCQ 32'b0;
        compl_done              <= #TCQ 1'b0;
        dword_count             <= #TCQ 1'b0;
      end else begin // reset_else_block
            case (state)
              BMD_AXIST_TX_RST_STATE : begin  // Reset_State
                state                   <= #TCQ BMD_AXIST_TX_RST_STATE;
                s_axis_cc_tdata         <= #TCQ s_axis_cc_tdata_wire;
                s_axis_cc_tkeep         <= #TCQ 16'hFFFF;
                s_axis_cc_tlast         <= #TCQ 1'b0;
                s_axis_cc_tvalid        <= #TCQ 1'b0;
                s_axis_cc_tuser         <= #TCQ {(AXISTEN_IF_CMP_PARITY_CHECK? s_axis_cc_parity: 64'd0), 17'd0};
                cfg_msg_transmit        <= #TCQ 1'b0;
                cfg_msg_transmit_type   <= #TCQ 3'b0;
                cfg_msg_transmit_data   <= #TCQ 32'b0;
                compl_done              <= #TCQ 1'b0;
                dword_count             <= #TCQ 1'b0;

                if(req_compl) begin
                   state <= #TCQ BMD_AXIST_TX_COMPL_C1;
                end else if (req_compl_wd) begin
                   state <= #TCQ BMD_AXIST_TX_COMPL_WD_C1;
                end else if (req_compl_ur) begin
                   state <= #TCQ BMD_AXIST_TX_CPL_UR_C1;
                end
              end // BMD_AXIST_TX_RST_STATE

              BMD_AXIST_TX_COMPL_C1 : begin // Completion Without Payload - Alignment doesnt matter
                                   // Sent in a Single Beat When Interface Width is 512 bit
                if(req_compl_qq) begin
                  s_axis_cc_tvalid  <= #TCQ 1'b1;
                  s_axis_cc_tlast   <= #TCQ 1'b1;
                  s_axis_cc_tkeep   <= #TCQ 16'h07;
                  s_axis_cc_tdata   <= #TCQ s_axis_cc_tdata_wire; 
                  s_axis_cc_tuser   <= #TCQ {(AXISTEN_IF_CMP_PARITY_CHECK? s_axis_cc_parity: 64'd0), 1'b0, 8'b10, 2'b1, 2'b0, 2'b0, 2'b1};

                  if(s_axis_cc_tready) begin
                    state <= #TCQ BMD_AXIST_TX_RST_STATE;
                    compl_done        <= #TCQ 1'b1;
                  end else begin
                    state <= #TCQ BMD_AXIST_TX_COMPL_C1;
                  end
                end

              end  //BMD_AXIST_TX_COMPL

              BMD_AXIST_TX_COMPL_WD_C1 : begin  // Completion With Payload
                                       // Possible Scenario's Payload can be 1 DW or 2 DW
                                       // Alignment can be either of Dword aligned or address aligned
                if (req_compl_wd_qq) begin

                  if(payload_len == 0) // 1DW_packet - Requires just one cycle to get the data rd_data from the BRAM.
                  begin
                    if(AXISTEN_IF_CMP_ALIGNMENT_MODE == "FALSE") begin // DWORD_aligned_Mode
                      s_axis_cc_tvalid  <= #TCQ 1'b1;
                      s_axis_cc_tlast   <= #TCQ 1'b1;
                      s_axis_cc_tkeep   <= #TCQ 16'h0F;
                      s_axis_cc_tdata   <= #TCQ s_axis_cc_tdata_wire;
                      s_axis_cc_tuser   <= #TCQ {(AXISTEN_IF_CMP_PARITY_CHECK? s_axis_cc_parity: 64'd0), 1'b0, 8'b11, 2'b1, 2'b0, 2'b0, 2'b1};

                      if(s_axis_cc_tready) begin
                        state <= #TCQ BMD_AXIST_TX_RST_STATE;
                        compl_done        <= #TCQ 1'b1;
                      end else begin
                        state <= #TCQ BMD_AXIST_TX_COMPL_WD_C1;
                      end
                    end  //DWORD_aligned_Mode

                    else begin // Addr_aligned_mode
                      s_axis_cc_tvalid  <= #TCQ 1'b1;
                      s_axis_cc_tlast   <= #TCQ 1'b1;
                      s_axis_cc_tkeep   <= #TCQ (lower_addr[3:2]==2'b00)   ?  16'h001F :
                                                (lower_addr[3:2]==2'b01)   ?  16'h003F :
                                                (lower_addr[3:2]==2'b10)   ?  16'h007F :
                                                /*(lower_addr_q[3:2]==2'b10) ?*/16'h00FF;

                      s_axis_cc_tdata   <= #TCQ s_axis_cc_tdata_wire;
                      s_axis_cc_tuser   <= #TCQ {(AXISTEN_IF_CMP_PARITY_CHECK? s_axis_cc_parity: 64'd0), 1'b0, 4'b0, {2'b01,lower_addr[3:2]}, 2'b1, 2'b0, 2'b0, 2'b1};

                      if(s_axis_cc_tready) begin
                        state <= #TCQ BMD_AXIST_TX_RST_STATE;
                        compl_done        <= #TCQ 1'b1;
                      end else begin
                        state <= #TCQ BMD_AXIST_TX_COMPL_WD_C1;
                        compl_done        <= #TCQ 1'b0;
                      end
                    end    // Addr_aligned_mode

                  end //1DW_packet


                  else begin // 2DW_packet -- Not implemented for 512
                    if(AXISTEN_IF_CMP_ALIGNMENT_MODE == "FALSE") begin // DWORD_aligned_Mode

                      dword_count <= #TCQ 1'b1; // To increment the Read Address
                      rd_data_reg <= #TCQ rd_data; // store the current read data
                      state       <= #TCQ BMD_AXIST_TX_COMPL_WD_2DW;

                    end  //DWORD_aligned_Mode

                    else begin // Address ALigned Mode

                      s_axis_cc_tvalid  <= #TCQ 1'b0;
                      s_axis_cc_tlast   <= #TCQ 1'b0;
                      s_axis_cc_tuser   <= #TCQ {(AXISTEN_IF_CMP_PARITY_CHECK? s_axis_cc_parity: 64'd0), 17'd0};
                      rd_data_reg       <= #TCQ rd_data; // store the current read data
                      compl_done        <= #TCQ 1'b0;
                      state <= #TCQ BMD_AXIST_TX_COMPL_WD_2DW_ADDR_ALGN_C1;
                    end  // Address ALigned mode
                  end  // 2DW_packet
                end

              end // BMD_AXIST_TX_COMPL_WD

              BMD_AXIST_TX_COMPL_PYLD : begin // Completion with 1DW Payload in Address Aligned mode

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ 16'h01;
                s_axis_cc_tdata   <= #TCQ s_axis_cc_tdata_wire;
                s_axis_cc_tuser   <= #TCQ {(AXISTEN_IF_CMP_PARITY_CHECK? s_axis_cc_parity: 64'd0), 1'b0, 8'b0, 2'b1, 2'b0, 2'b0, 2'b0};

                if(s_axis_cc_tready) begin
                  state        <= #TCQ BMD_AXIST_TX_RST_STATE;
                  compl_done   <= #TCQ 1'b1;
                end else begin
                  state <= #TCQ BMD_AXIST_TX_COMPL_PYLD;
                end
              end // BMD_AXIST_TX_COMPL_PYLD

              BMD_AXIST_TX_COMPL_WD_2DW : begin // Completion with 2DW Payload in DWord Aligned mode ---- Not implemenetd for 512 case
                                          // Requires 2 states to get the 2DW Payload

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ 8'h1F;
                s_axis_cc_tdata   <= #TCQ s_axis_cc_tdata_wire;
                s_axis_cc_tuser   <= #TCQ {(AXISTEN_IF_CMP_PARITY_CHECK? s_axis_cc_parity: 64'd0), 17'd0};

                if(s_axis_cc_tready) begin
                  state        <= #TCQ BMD_AXIST_TX_RST_STATE;
                  compl_done   <= #TCQ 1'b1;
                end else begin
                  state <= #TCQ BMD_AXIST_TX_COMPL_WD_2DW;
                  dword_count <= #TCQ 1'b1; // To increment the Read Address
                  rd_data_reg <= #TCQ rd_data; // store the current read data
                end

              end //  BMD_AXIST_TX_COMPL_WD_2DW

              BMD_AXIST_TX_COMPL_WD_2DW_ADDR_ALGN_C1 : begin // Completions with 2-DW Payload and Addr aligned mode -- Not implemented for 512

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ (lower_addr_q[3:2]==2'b00)   ?  16'h003F :
                                          (lower_addr_q[3:2]==2'b01)   ?  16'h007F :
                                          (lower_addr_q[3:2]==2'b10)   ?  16'h00FF :
                                          /*(lower_addr_q[3:2]==2'b10) ?*/16'h01FF;
                s_axis_cc_tdata   <= #TCQ s_axis_cc_tdata_wire;

                s_axis_cc_tuser   <= #TCQ {(AXISTEN_IF_CMP_PARITY_CHECK? s_axis_cc_parity: 64'd0), // parity 64 bit -[80:17]
                                          1'b0,                    // Discontinue          
                                          4'b0000,                 // is_eop1_ptr
                                          4'b0000,                 // is_eop0_ptr
                                          2'b01,                   // is_eop[1:0]
                                          2'b00,                   // is_sop1_ptr[1:0]
                                          2'b00,                   // is_sop0_ptr[1:0]
                                          2'b01};                  // is_sop[1:0]


                dword_count       <= #TCQ 1'b0;
                if(s_axis_cc_tready) begin
                 state        <= #TCQ BMD_AXIST_TX_RST_STATE;
                 compl_done   <= #TCQ 1'b1;
                end else begin
                  state <= #TCQ BMD_AXIST_TX_COMPL_WD_2DW_ADDR_ALGN_C1;
                end // BMD_AXIST_TX_COMPL_WD_2DW_ADDR_ALGN
              end


              BMD_AXIST_TX_CPL_UR_C1 : begin // Completions with UR - Alignement mode matters here

                if (req_compl_ur_qq) begin

                     s_axis_cc_tvalid  <= #TCQ 1'b1;
                     s_axis_cc_tlast   <= #TCQ 1'b1;
                     s_axis_cc_tkeep   <= #TCQ 16'hFF;
                     s_axis_cc_tdata   <= #TCQ s_axis_cc_tdata_wire;
                     s_axis_cc_tuser   <= #TCQ {(AXISTEN_IF_CMP_PARITY_CHECK? s_axis_cc_parity: 64'd0), 1'b0, 8'b111, 2'b1, 2'b0, 2'b0, 2'b1};
                     if(s_axis_cc_tready) begin
                       state        <= #TCQ BMD_AXIST_TX_RST_STATE;
                       compl_done   <= #TCQ 1'b1;
                     end else begin
                       state        <= #TCQ BMD_AXIST_TX_CPL_UR_C1;
                     end
                end

              end // BMD_AXIST_TX_CPL_UR

            endcase

          end // reset_else_block

      end // Always Block Ends // 512 CC ends

   // Present address and byte enable to memory module
   assign rd_addr = (dword_count == 0)? req_addr[12:2]: (req_addr[12:2] + 11'h001);
   assign rd_be   = (dword_count == 0)? req_be[3:0]: req_be[7:4];

endmodule // BMD_AXIST_CC_512
