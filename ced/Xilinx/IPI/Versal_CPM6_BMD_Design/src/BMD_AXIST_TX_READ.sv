//-----------------------------------------------------------------------------
//
// (c) Copyright 1995, 2007, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : Versal PCI Express Integrated Block
// File       : BMD_AXIST_TX_READ.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_TX_READ.sv
//--
//-- Description: Generates MemRd traffic when instructed by CSRs
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_TX_READ
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
  import bmd_cfg_pkg::*;
(
    input  logic            clk,
    input  logic            rst_n,
    input  logic            init_rst_i,
    // Memory Read
    input  logic            mrd_start_i,
    input  logic            mrd_inc_i,
    input  logic [31:0]     mrd_addr_i,
    input  logic [31:0]     mrd_up_addr_i,
    input  logic [10:0]     mrd_len_i,
    input  logic [15:0]     mrd_count_i,
    input  logic            mrd_nosnoop_i,
    input  logic            mrd_relaxed_order_i,
    input  logic            mrd_64b_en_i,
    input  logic [2:0]      mrd_tlp_tc_i,

    input  logic [11:0]     mrd_tph_i,
    input  logic            mrd_tph_vld_i,
    input  logic [23:0]     mrd_ide_i,
    input  logic            mrd_ide_vld_i,
    input  logic [23:0]     mrd_pasid_i,
    input  logic            mrd_pasid_vld_i,
    input  logic [1:0]      mrd_ats_i,
    input  logic            mrd_nw_i,
    input  logic            mrd_poisoned_i,
    input  logic [7:0]      mrd_steering_tag_i,
    input  logic [1:0]      mrd_phint_i,
    input  logic            mrd_tph_en_i,
    input  logic            mrd_fmt_i,
    input  logic [4:0]      mrd_type_i,
    input  logic [3:0]      mrd_upper_be_i,
    input  logic [3:0]      mrd_lower_be_i,
    input  logic [15:0]     mrd_rrid_i,
    input  logic            mrd_tbit_i,
    input  logic            mrd_td_i,

    output logic [15:0]    count_o,

    // Tags
    input  logic [($clog2(NUM_SLOTS)>>1):0]         tag_valid, // registered in rx_cpl
    input  logic [($clog2(NUM_SLOTS)>>1):0][9:0]    tag_released, // registered in rx_cpl
    input  logic                                    cfg_10b_tag_req_en,
    input  logic                                    cfg_ext_tag_en,

    output tx_intf          read_tx,

    input  logic [NUM_SLOTS-1:0]            fifo_full,

    output logic [31:0]     debug
);

logic [15:0]    count_r;
assign count_o = count_r;

// Read State Machine States
localparam logic [1:0]          IDLE        = 2'b00;
localparam logic [1:0]          PREP        = 2'b11;
localparam logic [1:0]          SEND_ONE    = 2'b01;
localparam logic [1:0]          SEND_TWO    = 2'b10;
// State Machine Registers
logic [1:0]                     current_state_r;
logic [1:0]                     current_state;
logic [1:0]                     next_state;

// Register signals for read instructions
logic [31:0]                mrd_addr_r;
logic [31:0]                mrd_up_addr_r;
logic [10:0]                mrd_len_r;
logic [15:0]                mrd_count_r_m1, mrd_count_r_m2,
                            mrd_count_r_m3, mrd_count_r_m4, mrd_count_r_m5,
                            mrd_count_r_m6, mrd_count_r_m7, mrd_count_r_m8,
                            mrd_count_r_m9, mrd_count_r_m10, mrd_count_r_m11,
                            mrd_count_r_m12, mrd_count_r_m13, mrd_count_r_m14,
                            mrd_count_r_m15, mrd_count_r_m16, mrd_count_r_m17,
                            mrd_count_r_m18;
// Register signals for sideband information
logic                       mrd_nosnoop_r;
logic                       mrd_relaxed_order_r;
logic                       mrd_64b_en_r;
logic [2:0]                 mrd_tlp_tc_r;
logic [11:0]                mrd_tph_r;
logic                       mrd_tph_vld_r;
logic [23:0]                mrd_ide_r;
logic                       mrd_ide_vld_r;
logic [23:0]                mrd_pasid_r;
logic                       mrd_pasid_vld_r;
logic [1:0]                 mrd_ats_r;
logic                       mrd_nw_r;
logic                       mrd_poisoned_r;
logic [7:0]                 mrd_steering_tag_r;
logic [1:0]                 mrd_phint_r;
logic                       mrd_tph_en_r;
logic                       mrd_fmt_r;
logic [4:0]                 mrd_type_r;
logic [3:0]                 mrd_upper_be_r;
logic [3:0]                 mrd_lower_be_r;
logic [15:0]                mrd_rrid_r;
logic                       mrd_tbit_r;
logic                       mrd_td_r;
// Track progress on reads
logic                       mrd_in_progress_r;
// Track next tag
logic                       tag_used_valid_1, tag_used_valid_2;
logic                       tag_used_valid_1_r, tag_used_valid_2_r;
logic [17:0][9:0]           next_tags;
logic [17:0][9:0]           tags_r;
logic [17:0][9:0]           next_tags_r;
logic [17:0][9:0]           tags_r_r;
logic [17:0][9:0]           next_tags_r_r;

logic [17:0][9:0]           future_tags;
logic [9:0]                 tag_ptr_r, next_tag_ptr;
logic [9:0]                 next_tag_ptr_r, future_tag_ptr;

// Tag pool / availability
logic [767:0] tag_pool_r, tag_pool;

logic tag_0_avail,  tag_0_avail_r;
logic tag_1_avail,  tag_1_avail_r;
logic tag_2_avail,  tag_2_avail_r;
logic tag_3_avail,  tag_3_avail_r;
logic tag_4_avail,  tag_4_avail_r;
logic tag_5_avail,  tag_5_avail_r;
logic tag_6_avail,  tag_6_avail_r;
logic tag_7_avail,  tag_7_avail_r;
logic tag_8_avail,  tag_8_avail_r;
logic tag_9_avail,  tag_9_avail_r;
logic tag_10_avail, tag_10_avail_r;
logic tag_11_avail, tag_11_avail_r;
logic tag_12_avail, tag_12_avail_r;
logic tag_13_avail, tag_13_avail_r;
logic tag_14_avail, tag_14_avail_r;
logic tag_15_avail, tag_15_avail_r;
logic tag_16_avail, tag_16_avail_r;
logic tag_17_avail, tag_17_avail_r;

// Tag availability gate (mirrors BMED_TX_NONPOSTED, lines ~608-627).
//
// The gate MUST validate the exact tags each half will launch, indexed against
// the live pool, in the state that precedes the issue:
//   - tags_r     = current batch; stable across SEND_ONE -> SEND_TWO. Both halves
//                  of the batch being issued NOW live here.
//   - next_tags_r= incoming batch; promoted into tags_r at the SEND_TWO->SEND_ONE
//                  advance (next_tags = next_tags_r).
//
// Default (SEND_ONE / PREP / stall): check the current batch tags_r[*]. Because
// tags_r is stable while stalled, a re-evaluated (stalled) cycle can never
// approve a tag whose pool bit has since gone busy.
//
// SEND_TWO: the lower 9 entries belong to the NEXT batch about to be promoted
// (next_tags_r) -> pre-validate them so the following SEND_ONE only issues tags
// whose pool bit is free at the moment of promotion. The upper 9 are still the
// current batch (tags_r) that SEND_TWO is launching now.
//
// BUG FIX: previously every entry indexed next_tags_r in all states. Under a
// SEND_ONE stall, next_tags_r runs ahead of tags_r (SEND_ONE recomputes the
// look-ahead unconditionally), so the gate validated a *different* batch than the
// one actually launched -> a still-outstanding tag could pass the gate and be
// re-issued before its completion returned (tag reuse / unexpected completion).
always_comb begin
    tag_0_avail  = tag_pool_r[tags_r[0]];
    tag_1_avail  = tag_pool_r[tags_r[1]];
    tag_2_avail  = tag_pool_r[tags_r[2]];
    tag_3_avail  = tag_pool_r[tags_r[3]];
    tag_4_avail  = tag_pool_r[tags_r[4]];
    tag_5_avail  = tag_pool_r[tags_r[5]];
    tag_6_avail  = tag_pool_r[tags_r[6]];
    tag_7_avail  = tag_pool_r[tags_r[7]];
    tag_8_avail  = tag_pool_r[tags_r[8]];
    tag_9_avail  = tag_pool_r[tags_r[9]];
    tag_10_avail = tag_pool_r[tags_r[10]];
    tag_11_avail = tag_pool_r[tags_r[11]];
    tag_12_avail = tag_pool_r[tags_r[12]];
    tag_13_avail = tag_pool_r[tags_r[13]];
    tag_14_avail = tag_pool_r[tags_r[14]];
    tag_15_avail = tag_pool_r[tags_r[15]];
    tag_16_avail = tag_pool_r[tags_r[16]];
    tag_17_avail = tag_pool_r[tags_r[17]];

    // Pre-validate the incoming batch's first half during SEND_TWO so the
    // SEND_ONE gate (which consumes these one cycle later) reflects the tags
    // that will actually be promoted into tags_r.
    if (current_state == SEND_TWO) begin
        tag_0_avail = tag_pool_r[next_tags_r[0]];
        tag_1_avail = tag_pool_r[next_tags_r[1]];
        tag_2_avail = tag_pool_r[next_tags_r[2]];
        tag_3_avail = tag_pool_r[next_tags_r[3]];
        tag_4_avail = tag_pool_r[next_tags_r[4]];
        tag_5_avail = tag_pool_r[next_tags_r[5]];
        tag_6_avail = tag_pool_r[next_tags_r[6]];
        tag_7_avail = tag_pool_r[next_tags_r[7]];
        tag_8_avail = tag_pool_r[next_tags_r[8]];
    end
end

///////////////////////////////////////////////////////////////////
// Create TLP Prefix Content
///////////////////////////////////////////////////////////////////
localparam logic [2:0]          fmt_prefix   = 3'b100;

localparam logic [4:0]          type_tph     = 5'b10000;
localparam logic [4:0]          type_pasid   = 5'b10001;
localparam logic [4:0]          type_ide     = 5'b10010;

localparam logic [7:0]          byte0_tph    = {fmt_prefix, type_tph};
localparam logic [7:0]          byte0_pasid  = {fmt_prefix, type_pasid};
localparam logic [7:0]          byte0_ide    = {fmt_prefix, type_ide};

logic [7:0]                     byte1_tph;
logic [7:0]                     byte2_tph;
logic [7:0]                     byte3_tph;

assign byte1_tph = mrd_tph_r[11:4];
assign byte2_tph = {mrd_tph_r[3:0], 4'h0};
assign byte3_tph = '0;

logic [7:0]                     byte1_pasid;
logic [7:0]                     byte2_pasid;
logic [7:0]                     byte3_pasid;

assign byte1_pasid  = {mrd_pasid_r[23:22], 2'b00, mrd_pasid_r[19:16]};
assign byte2_pasid  = mrd_pasid_r[15:8];
assign byte3_pasid  = mrd_pasid_r[7:0];

logic [7:0]                     byte1_ide;
logic [7:0]                     byte2_ide;
logic [7:0]                     byte3_ide;

assign byte1_ide    = mrd_ide_r[23:16];
assign byte2_ide    = mrd_ide_r[15:8];
assign byte3_ide    = {1'b0, mrd_ide_r[6:0]};

logic [31:0]                    tph_prefix;
logic [31:0]                    pasid_prefix;
logic [31:0]                    ide_prefix;

assign tph_prefix =    {byte3_tph,
                        byte2_tph,
                        byte1_tph,
                        byte0_tph};

assign pasid_prefix =  {byte3_pasid,
                        byte2_pasid,
                        byte1_pasid,
                        byte0_pasid};

assign ide_prefix =    {byte3_ide,
                        byte2_ide,
                        byte1_ide,
                        byte0_ide};

logic [63:0] next_prfx;
logic [63:0] prfx_r;
always @(posedge clk) begin
    if (!rst_n) begin
        prfx_r <= '0;
    end else begin
        prfx_r <= next_prfx;
    end
end

always_comb begin
    case({mrd_ide_vld_r, mrd_pasid_vld_r, mrd_tph_vld_r})
        3'b001 : begin
            next_prfx = tph_prefix;
        end

        3'b010 : begin
            next_prfx = pasid_prefix;
        end

        3'b011 : begin
            next_prfx = {tph_prefix, pasid_prefix};
        end

        3'b100 : begin
            next_prfx = ide_prefix;
        end

        default : begin
            next_prfx = '0;
        end
    endcase
end

///////////////////////////////////////////////////////////////////
// Assign header content
///////////////////////////////////////////////////////////////////

tx_data_np np_hdr;
assign np_hdr.vfunc_active      = VFUNC_ACTIVE;
assign np_hdr.vfunc_num         = VFUNC_NUM;
assign np_hdr.func_num          = FUNC_NUM;
assign np_hdr.fmt               = { mrd_fmt_r, mrd_64b_en_r };
assign np_hdr.ttype             = mrd_type_r; // See table 2-3 in PCIe Spec 6.2
assign np_hdr.tc                = mrd_tlp_tc_r;
assign np_hdr.attr              = { 1'b0, mrd_relaxed_order_r, mrd_nosnoop_r };
assign np_hdr.remote_req_id     = mrd_rrid_r;
assign np_hdr.tid               = '0;
assign np_hdr.t_bit             = mrd_tbit_r; // T bit in IDE prefix
assign np_hdr.td                = mrd_td_r; // TLP Digest
assign np_hdr.byte_len          = mrd_len_r << 2;
assign np_hdr.byte_en           = {mrd_upper_be_r, mrd_lower_be_r};
assign np_hdr.ats               = mrd_ats_r;
assign np_hdr.nw                = mrd_nw_r;
assign np_hdr.th                = mrd_tph_en_r;
assign np_hdr.ph                = mrd_phint_r;
assign np_hdr.st                = mrd_steering_tag_r;
assign np_hdr.ep                = mrd_poisoned_r;
assign np_hdr.bad_eot           = '0;
assign np_hdr.atu_bypass        = 1'b1;
assign np_hdr.addr_align_en     = 1'b0;
assign np_hdr.prfx              = prfx_r;
assign np_hdr.segment           = '0;
assign np_hdr.dst_segment       = '0;
assign np_hdr.reserved          = '0;

// Packet counter
logic [15:0]    count_r_r;

// Combined reset ('user' and system)
logic   comb_reset;
assign  comb_reset = !rst_n || init_rst_i;

// Helper for adding registers and current state values
logic [15:0]    next_count;
logic [15:0]    count_p1, count_p1_r;

// Address pointer
logic [63:0]    base_addr_ptr, addr_ptr_r, next_addr_ptr;
logic [31:0]    addr_inc1_r;
logic [31:0]    addr_inc2_r;
logic [31:0]    addr_inc3_r;
logic [31:0]    addr_inc4_r;
logic [31:0]    addr_inc5_r;
logic [31:0]    addr_inc6_r;
logic [31:0]    addr_inc7_r;
logic [31:0]    addr_inc8_r;
logic [31:0]    addr_inc9_r;
logic [31:0]    addr_inc10_r;
logic [31:0]    addr_inc11_r;
logic [31:0]    addr_inc12_r;
logic [31:0]    addr_inc13_r;
logic [31:0]    addr_inc14_r;
logic [31:0]    addr_inc15_r;
logic [31:0]    addr_inc16_r;
logic [31:0]    addr_inc17_r;
logic [31:0]    addr_inc18_r;

logic [63:0]    addr_ptr_0_00, addr_ptr_0_00_r; // Cycle 0, Slot 0, Subslot 0
logic [63:0]    addr_ptr_0_01, addr_ptr_0_01_r; // Cycle 0, Slot 0, Subslot 1
logic [63:0]    addr_ptr_0_02, addr_ptr_0_02_r; // Cycle 0, Slot 0, Subslot 2
logic [63:0]    addr_ptr_0_10, addr_ptr_0_10_r; // Cycle 0, Slot 1, Subslot 0
logic [63:0]    addr_ptr_0_11, addr_ptr_0_11_r; // Cycle 0, Slot 1, Subslot 1
logic [63:0]    addr_ptr_0_12, addr_ptr_0_12_r; // Cycle 0, Slot 1, Subslot 2
logic [63:0]    addr_ptr_0_20, addr_ptr_0_20_r; // Cycle 0, Slot 2, Subslot 0
logic [63:0]    addr_ptr_0_21, addr_ptr_0_21_r; // Cycle 0, Slot 2, Subslot 1
logic [63:0]    addr_ptr_0_22, addr_ptr_0_22_r; // Cycle 0, Slot 2, Subslot 2

logic [63:0]    addr_ptr_1_00, addr_ptr_1_00_r; // Cycle 1, Slot 0, Subslot 0
logic [63:0]    addr_ptr_1_01, addr_ptr_1_01_r; // Cycle 1, Slot 0, Subslot 1
logic [63:0]    addr_ptr_1_02, addr_ptr_1_02_r; // Cycle 1, Slot 0, Subslot 2
logic [63:0]    addr_ptr_1_10, addr_ptr_1_10_r; // Cycle 1, Slot 1, Subslot 0
logic [63:0]    addr_ptr_1_11, addr_ptr_1_11_r; // Cycle 1, Slot 1, Subslot 1
logic [63:0]    addr_ptr_1_12, addr_ptr_1_12_r; // Cycle 1, Slot 1, Subslot 2
logic [63:0]    addr_ptr_1_20, addr_ptr_1_20_r; // Cycle 1, Slot 2, Subslot 0
logic [63:0]    addr_ptr_1_21, addr_ptr_1_21_r; // Cycle 1, Slot 2, Subslot 1
logic [63:0]    addr_ptr_1_22, addr_ptr_1_22_r; // Cycle 1, Slot 2, Subslot 2

logic [63:0]    addr_ptr_2_r, addr_ptr_2; // base pointer + 18

logic s1_tags_avail;
logic s2_tags_avail;

assign base_addr_ptr = { mrd_64b_en_i ? {mrd_up_addr_i, mrd_addr_i} : {32'b0, mrd_addr_i} };

assign debug = {
    1'b0,
    mrd_in_progress_r,
    s2_tags_avail,
    s1_tags_avail,
    tags_r_r[0],
    current_state_r,
    count_r_r
};

// Handle register and state changes and resets
always @(posedge clk) begin
    if (comb_reset) begin
        current_state       <= IDLE;

        mrd_addr_r          <= '0;
        mrd_up_addr_r       <= '0;
        mrd_len_r           <= '0;
        mrd_count_r_m1      <= '0;
        mrd_count_r_m2      <= '0;
        mrd_count_r_m3      <= '0;
        mrd_count_r_m4      <= '0;
        mrd_count_r_m5      <= '0;
        mrd_count_r_m6      <= '0;
        mrd_count_r_m7      <= '0;
        mrd_count_r_m8      <= '0;
        mrd_count_r_m9      <= '0;
        mrd_count_r_m10     <= '0;
        mrd_count_r_m11     <= '0;
        mrd_count_r_m12     <= '0;
        mrd_count_r_m13     <= '0;
        mrd_count_r_m14     <= '0;
        mrd_count_r_m15     <= '0;
        mrd_count_r_m16     <= '0;
        mrd_count_r_m17     <= '0;
        mrd_count_r_m18     <= '0;
        mrd_nosnoop_r       <= '0;
        mrd_relaxed_order_r <= '0;
        mrd_64b_en_r        <= '0;
        mrd_tlp_tc_r        <= '0;
        mrd_tph_r           <= '0;
        mrd_tph_vld_r       <= '0;
        mrd_ide_r           <= '0;
        mrd_ide_vld_r       <= '0;
        mrd_pasid_r         <= '0;
        mrd_pasid_vld_r     <= '0;
        mrd_ats_r           <= '0;
        mrd_nw_r            <= '0;
        mrd_poisoned_r      <= '0;
        mrd_steering_tag_r  <= '0;
        mrd_phint_r         <= '0;
        mrd_tph_en_r        <= '0;
        mrd_upper_be_r      <= '0;
        mrd_lower_be_r      <= '0;
        mrd_rrid_r          <= '0;
        mrd_tbit_r          <= '0;
        mrd_td_r            <= '0;

        addr_ptr_r          <= '0;
        addr_inc1_r         <= '0;
        addr_inc2_r         <= '0;
        addr_inc3_r         <= '0;
        addr_inc4_r         <= '0;
        addr_inc5_r         <= '0;
        addr_inc6_r         <= '0;
        addr_inc7_r         <= '0;
        addr_inc8_r         <= '0;
        addr_inc9_r         <= '0;
        addr_inc10_r        <= '0;
        addr_inc11_r        <= '0;
        addr_inc12_r        <= '0;
        addr_inc13_r        <= '0;
        addr_inc14_r        <= '0;
        addr_inc15_r        <= '0;
        addr_inc16_r        <= '0;
        addr_inc17_r        <= '0;
        addr_inc18_r        <= '0;

        count_r             <= '0;
        count_r_r           <= '0;
        count_p1_r          <= '0;

        addr_ptr_0_00_r     <= '0;
        addr_ptr_0_01_r     <= '0;
        addr_ptr_0_02_r     <= '0;
        addr_ptr_0_10_r     <= '0;
        addr_ptr_0_11_r     <= '0;
        addr_ptr_0_12_r     <= '0;
        addr_ptr_0_20_r     <= '0;
        addr_ptr_0_21_r     <= '0;
        addr_ptr_0_22_r     <= '0;
        addr_ptr_1_00_r     <= '0;
        addr_ptr_1_01_r     <= '0;
        addr_ptr_1_02_r     <= '0;
        addr_ptr_1_10_r     <= '0;
        addr_ptr_1_11_r     <= '0;
        addr_ptr_1_12_r     <= '0;
        addr_ptr_1_20_r     <= '0;
        addr_ptr_1_21_r     <= '0;
        addr_ptr_1_22_r     <= '0;
        addr_ptr_2_r        <= '0;

        tag_used_valid_1_r  <= '0;
        tag_used_valid_2_r  <= '0;
        tags_r_r            <= '0;

        tag_0_avail_r       <= '0;
        tag_1_avail_r       <= '0;
        tag_2_avail_r       <= '0;
        tag_3_avail_r       <= '0;
        tag_4_avail_r       <= '0;
        tag_5_avail_r       <= '0;
        tag_6_avail_r       <= '0;
        tag_7_avail_r       <= '0;
        tag_8_avail_r       <= '0;
        tag_9_avail_r       <= '0;
        tag_10_avail_r      <= '0;
        tag_11_avail_r      <= '0;
        tag_12_avail_r      <= '0;
        tag_13_avail_r      <= '0;
        tag_14_avail_r      <= '0;
        tag_15_avail_r      <= '0;
        tag_16_avail_r      <= '0;
        tag_17_avail_r      <= '0;

        mrd_in_progress_r   <= '0;

        s1_tags_avail       <= '0;
        s2_tags_avail       <= '0;
        current_state_r     <= '0;
    end else begin
        current_state   <= next_state;
        addr_ptr_r      <= next_addr_ptr;
        count_r         <= next_count;

        addr_ptr_0_00_r <= addr_ptr_0_00;
        addr_ptr_0_01_r <= addr_ptr_0_01;
        addr_ptr_0_02_r <= addr_ptr_0_02;
        addr_ptr_0_10_r <= addr_ptr_0_10;
        addr_ptr_0_11_r <= addr_ptr_0_11;
        addr_ptr_0_12_r <= addr_ptr_0_12;
        addr_ptr_0_20_r <= addr_ptr_0_20;
        addr_ptr_0_21_r <= addr_ptr_0_21;
        addr_ptr_0_22_r <= addr_ptr_0_22;
        addr_ptr_1_00_r <= addr_ptr_1_00;
        addr_ptr_1_01_r <= addr_ptr_1_01;
        addr_ptr_1_02_r <= addr_ptr_1_02;
        addr_ptr_1_10_r <= addr_ptr_1_10;
        addr_ptr_1_11_r <= addr_ptr_1_11;
        addr_ptr_1_12_r <= addr_ptr_1_12;
        addr_ptr_1_20_r <= addr_ptr_1_20;
        addr_ptr_1_21_r <= addr_ptr_1_21;
        addr_ptr_1_22_r <= addr_ptr_1_22;
        addr_ptr_2_r    <= addr_ptr_2;

        tags_r_r        <= next_tags_r_r;
        tag_used_valid_1_r <= tag_used_valid_1;
        tag_used_valid_2_r <= tag_used_valid_2;

        tag_0_avail_r   <= tag_0_avail;
        tag_1_avail_r   <= tag_1_avail;
        tag_2_avail_r   <= tag_2_avail;
        tag_3_avail_r   <= tag_3_avail;
        tag_4_avail_r   <= tag_4_avail;
        tag_5_avail_r   <= tag_5_avail;
        tag_6_avail_r   <= tag_6_avail;
        tag_7_avail_r   <= tag_7_avail;
        tag_8_avail_r   <= tag_8_avail;
        tag_9_avail_r   <= tag_9_avail;
        tag_10_avail_r  <= tag_10_avail;
        tag_11_avail_r  <= tag_11_avail;
        tag_12_avail_r  <= tag_12_avail;
        tag_13_avail_r  <= tag_13_avail;
        tag_14_avail_r  <= tag_14_avail;
        tag_15_avail_r  <= tag_15_avail;
        tag_16_avail_r  <= tag_16_avail;
        tag_17_avail_r  <= tag_17_avail;

        s1_tags_avail   <= tag_0_avail_r &&
                           tag_1_avail_r &&
                           tag_2_avail_r &&
                           tag_3_avail_r &&
                           tag_4_avail_r &&
                           tag_5_avail_r &&
                           tag_6_avail_r &&
                           tag_7_avail_r &&
                           tag_8_avail_r;
        s2_tags_avail   <= tag_9_avail_r  &&
                           tag_10_avail_r &&
                           tag_11_avail_r &&
                           tag_12_avail_r &&
                           tag_13_avail_r &&
                           tag_14_avail_r &&
                           tag_15_avail_r &&
                           tag_16_avail_r &&
                           tag_17_avail_r;

        count_p1_r      <= count_p1;
        count_r_r       <= count_r;
        current_state_r <= current_state;

        // If we are starting generation this cycle
        if (!mrd_in_progress_r && mrd_start_i) begin
            mrd_addr_r          <= mrd_addr_i;
            mrd_up_addr_r       <= mrd_up_addr_i;
            mrd_len_r           <= mrd_len_i;
            mrd_nosnoop_r       <= mrd_nosnoop_i;
            mrd_relaxed_order_r <= mrd_relaxed_order_i;
            mrd_64b_en_r        <= mrd_64b_en_i;
            mrd_tlp_tc_r        <= mrd_tlp_tc_i;
            mrd_tph_r           <= mrd_tph_i;
            mrd_tph_vld_r       <= mrd_tph_vld_i;
            mrd_ide_r           <= mrd_ide_i;
            mrd_ide_vld_r       <= mrd_ide_vld_i;
            mrd_pasid_r         <= mrd_pasid_i;
            mrd_pasid_vld_r     <= mrd_pasid_vld_i;
            mrd_ats_r           <= mrd_ats_i;
            mrd_nw_r            <= mrd_nw_i;
            mrd_poisoned_r      <= mrd_poisoned_i;
            mrd_steering_tag_r  <= mrd_steering_tag_i;
            mrd_phint_r         <= mrd_phint_i;
            mrd_tph_en_r        <= mrd_tph_en_i;
            mrd_fmt_r           <= mrd_fmt_i;
            mrd_type_r          <= mrd_type_i;
            mrd_upper_be_r      <= mrd_upper_be_i;
            mrd_lower_be_r      <= mrd_lower_be_i;
            mrd_rrid_r          <= mrd_rrid_i;
            mrd_tbit_r          <= mrd_tbit_i;
            mrd_td_r            <= mrd_td_i;

            mrd_count_r_m1      <= mrd_count_i - 1;
            mrd_count_r_m2      <= mrd_count_i - 2;
            mrd_count_r_m3      <= mrd_count_i - 3;
            mrd_count_r_m4      <= mrd_count_i - 4;
            mrd_count_r_m5      <= mrd_count_i - 5;
            mrd_count_r_m6      <= mrd_count_i - 6;
            mrd_count_r_m7      <= mrd_count_i - 7;
            mrd_count_r_m8      <= mrd_count_i - 8;
            mrd_count_r_m9      <= mrd_count_i - 9;
            mrd_count_r_m10     <= mrd_count_i - 10;
            mrd_count_r_m11     <= mrd_count_i - 11;
            mrd_count_r_m12     <= mrd_count_i - 12;
            mrd_count_r_m13     <= mrd_count_i - 13;
            mrd_count_r_m14     <= mrd_count_i - 14;
            mrd_count_r_m15     <= mrd_count_i - 15;
            mrd_count_r_m16     <= mrd_count_i - 16;
            mrd_count_r_m17     <= mrd_count_i - 17;
            mrd_count_r_m18     <= mrd_count_i - 18;

            // byte addresses from dword length
            addr_ptr_r          <= base_addr_ptr;

            if (!mrd_inc_i) begin
                addr_inc1_r         <= mrd_len_i << 2;
                addr_inc2_r         <= mrd_len_i << 3;
                addr_inc3_r         <= (mrd_len_i << 3) + (mrd_len_i << 2);
                addr_inc4_r         <= mrd_len_i << 4;
                addr_inc5_r         <= (mrd_len_i << 4) + (mrd_len_i << 2);
                addr_inc6_r         <= (mrd_len_i << 4) + (mrd_len_i << 3);
                addr_inc7_r         <= (mrd_len_i << 4) + (mrd_len_i << 3) + (mrd_len_i << 2);
                addr_inc8_r         <= mrd_len_i << 5;
                addr_inc9_r         <= (mrd_len_i << 5) + (mrd_len_i << 2);
                addr_inc10_r        <= (mrd_len_i << 5) + (mrd_len_i << 3);
                addr_inc11_r        <= (mrd_len_i << 5) + (mrd_len_i << 3) + (mrd_len_i << 2);
                addr_inc12_r        <= (mrd_len_i << 5) + (mrd_len_i << 4);
                addr_inc13_r        <= (mrd_len_i << 5) + (mrd_len_i << 4) + (mrd_len_i << 2);
                addr_inc14_r        <= (mrd_len_i << 5) + (mrd_len_i << 4) + (mrd_len_i << 3);
                addr_inc15_r        <= (mrd_len_i << 5) + (mrd_len_i << 4) + (mrd_len_i << 3) + (mrd_len_i << 2);
                addr_inc16_r        <= (mrd_len_i << 6);
                addr_inc17_r        <= (mrd_len_i << 6) + (mrd_len_i << 2);
                addr_inc18_r        <= (mrd_len_i << 6) + (mrd_len_i << 3);
            end else begin
                addr_inc1_r         <= '0;
                addr_inc2_r         <= '0;
                addr_inc3_r         <= '0;
                addr_inc4_r         <= '0;
                addr_inc5_r         <= '0;
                addr_inc6_r         <= '0;
                addr_inc7_r         <= '0;
                addr_inc8_r         <= '0;
                addr_inc9_r         <= '0;
                addr_inc10_r        <= '0;
                addr_inc11_r        <= '0;
                addr_inc12_r        <= '0;
                addr_inc13_r        <= '0;
                addr_inc14_r        <= '0;
                addr_inc15_r        <= '0;
                addr_inc16_r        <= '0;
                addr_inc17_r        <= '0;
                addr_inc18_r        <= '0;
            end

            mrd_in_progress_r   <= 1'b1;
        end
    end
end

    // Combinational logic for each state
always_comb begin
    // Default values
    read_tx                 = '0;
    read_tx.tx_starttype[0] = 2'b01;
    read_tx.tx_starttype[1] = 2'b01;
    read_tx.tx_starttype[2] = 2'b01;
    read_tx.tx_end_error    = 9'b0;
    read_tx.tx_parity       = '0;
    next_state              = current_state;
    next_addr_ptr           = addr_ptr_r;

    // TX sub-slots
    read_tx.tx_data[0].np[0]    = '0;
    read_tx.tx_data[0].np[1]    = '0;
    read_tx.tx_data[0].np[2]    = '0;
    read_tx.tx_data[1].np[0]    = '0;
    read_tx.tx_data[1].np[1]    = '0;
    read_tx.tx_data[1].np[2]    = '0;
    read_tx.tx_data[2].np[0]    = '0;
    read_tx.tx_data[2].np[1]    = '0;
    read_tx.tx_data[2].np[2]    = '0;

    // TX info
    read_tx.tx_valid        = 1'b0;
    read_tx.tx_start        = {1'b0, 1'b0, 1'b0};
    read_tx.tx_startptr     = {2'b00, 2'b00, 2'b00};
    read_tx.tx_end          = {1'b0, 1'b0, 1'b0};
    read_tx.tx_endptr       = {6'b00_0000, 6'b00_0000, 6'b00_0000};
    read_tx.tx_startnpinfo  = {3'b111, 3'b111, 3'b111};

    addr_ptr_0_00           = addr_ptr_0_00_r;
    addr_ptr_0_01           = addr_ptr_0_01_r;
    addr_ptr_0_02           = addr_ptr_0_02_r;
    addr_ptr_0_10           = addr_ptr_0_10_r;
    addr_ptr_0_11           = addr_ptr_0_11_r;
    addr_ptr_0_12           = addr_ptr_0_12_r;
    addr_ptr_0_20           = addr_ptr_0_20_r;
    addr_ptr_0_21           = addr_ptr_0_21_r;
    addr_ptr_0_22           = addr_ptr_0_22_r;
    addr_ptr_1_00           = addr_ptr_1_00_r;
    addr_ptr_1_01           = addr_ptr_1_01_r;
    addr_ptr_1_02           = addr_ptr_1_02_r;
    addr_ptr_1_10           = addr_ptr_1_10_r;
    addr_ptr_1_11           = addr_ptr_1_11_r;
    addr_ptr_1_12           = addr_ptr_1_12_r;
    addr_ptr_1_20           = addr_ptr_1_20_r;
    addr_ptr_1_21           = addr_ptr_1_21_r;
    addr_ptr_1_22           = addr_ptr_1_22_r;
    addr_ptr_2              = addr_ptr_2_r;

    // Tags
    tag_used_valid_1        = '0;
    tag_used_valid_2        = '0;
    next_tags_r_r           = tags_r;

    np_hdr.addr             = '0;
    next_count              = count_r;
    count_p1                = count_p1_r;

    case (current_state)

        // Wait for CSRs to instruct us to start
        IDLE : begin
            if (!mrd_in_progress_r && mrd_start_i) begin
                next_state = PREP;
            end
        end

        PREP : begin
            next_state = SEND_ONE;

            addr_ptr_1_00   = addr_ptr_r;
            addr_ptr_1_01   = addr_ptr_r + addr_inc1_r;
            addr_ptr_1_02   = addr_ptr_r + addr_inc2_r;
            addr_ptr_1_10   = addr_ptr_r + addr_inc3_r;
            addr_ptr_1_11   = addr_ptr_r + addr_inc4_r;
            addr_ptr_1_12   = addr_ptr_r + addr_inc5_r;
            addr_ptr_1_20   = addr_ptr_r + addr_inc6_r;
            addr_ptr_1_21   = addr_ptr_r + addr_inc7_r;
            addr_ptr_1_22   = addr_ptr_r + addr_inc8_r;

            next_addr_ptr   = addr_ptr_r + addr_inc9_r;
        end

        // Start sending whenever we have TX MUX control
        SEND_ONE : begin
            count_p1        = count_r + 18;

            addr_ptr_0_00   = addr_ptr_r;
            addr_ptr_0_01   = addr_ptr_r + addr_inc1_r;
            addr_ptr_0_02   = addr_ptr_r + addr_inc2_r;
            addr_ptr_0_10   = addr_ptr_r + addr_inc3_r;
            addr_ptr_0_11   = addr_ptr_r + addr_inc4_r;
            addr_ptr_0_12   = addr_ptr_r + addr_inc5_r;
            addr_ptr_0_20   = addr_ptr_r + addr_inc6_r;
            addr_ptr_0_21   = addr_ptr_r + addr_inc7_r;
            addr_ptr_0_22   = addr_ptr_r + addr_inc8_r;
            addr_ptr_2      = addr_ptr_r + addr_inc18_r;

            if(tag_0_avail_r && tag_1_avail_r && tag_2_avail_r && tag_3_avail_r && tag_4_avail_r && tag_5_avail_r &&
               tag_6_avail_r && tag_7_avail_r && tag_8_avail_r && fifo_full == '0) begin
                next_state = SEND_TWO;

                read_tx.tx_valid = 1'b1;

                np_hdr.addr = addr_ptr_1_00_r;

                read_tx.tx_data[0].np[0]    = np_hdr;
                read_tx.tx_data[0].np[1]    = np_hdr;
                read_tx.tx_data[0].np[2]    = np_hdr;
                read_tx.tx_data[1].np[0]    = np_hdr;
                read_tx.tx_data[1].np[1]    = np_hdr;
                read_tx.tx_data[1].np[2]    = np_hdr;
                read_tx.tx_data[2].np[0]    = np_hdr;
                read_tx.tx_data[2].np[1]    = np_hdr;
                read_tx.tx_data[2].np[2]    = np_hdr;

                read_tx.tx_data[0].np[1].addr   = addr_ptr_1_01_r;
                read_tx.tx_data[0].np[2].addr   = addr_ptr_1_02_r;
                read_tx.tx_data[1].np[0].addr   = addr_ptr_1_10_r;
                read_tx.tx_data[1].np[1].addr   = addr_ptr_1_11_r;
                read_tx.tx_data[1].np[2].addr   = addr_ptr_1_12_r;
                read_tx.tx_data[2].np[0].addr   = addr_ptr_1_20_r;
                read_tx.tx_data[2].np[1].addr   = addr_ptr_1_21_r;
                read_tx.tx_data[2].np[2].addr   = addr_ptr_1_22_r;

                read_tx.tx_data[0].np[0].tid    = tags_r[0];
                read_tx.tx_data[0].np[1].tid    = tags_r[1];
                read_tx.tx_data[0].np[2].tid    = tags_r[2];
                read_tx.tx_data[1].np[0].tid    = tags_r[3];
                read_tx.tx_data[1].np[1].tid    = tags_r[4];
                read_tx.tx_data[1].np[2].tid    = tags_r[5];
                read_tx.tx_data[2].np[0].tid    = tags_r[6];
                read_tx.tx_data[2].np[1].tid    = tags_r[7];
                read_tx.tx_data[2].np[2].tid    = tags_r[8];

                tag_used_valid_1          = 1'b1;

                case (count_r)
                    mrd_count_r_m1 : begin // one away from goal count
                        next_state                  = IDLE;
                        read_tx.tx_start            = {1'b0, 1'b0, 1'b1};
                        read_tx.tx_startptr[0]      = 2'b00;
                        read_tx.tx_end              = {1'b0, 1'b0, 1'b1};
                        read_tx.tx_endptr[0]        = { 2'b00, 4'b0000 };
                        read_tx.tx_startnpinfo[0]   = 3'b001;
                    end
                    mrd_count_r_m2 : begin // two away from goal count
                        next_state                  = IDLE;
                        read_tx.tx_start            = {1'b0, 1'b0, 1'b1};
                        read_tx.tx_startptr[0]      = 2'b00;
                        read_tx.tx_end              = {1'b0, 1'b0, 1'b1};
                        read_tx.tx_endptr[0]        = { 2'b00, 4'b0000 };
                        read_tx.tx_startnpinfo[0]   = 3'b011;
                    end
                    mrd_count_r_m3 : begin // three away from goal count
                        next_state              = IDLE;
                        read_tx.tx_start        = {1'b0, 1'b0, 1'b1};
                        read_tx.tx_startptr[0]  = 2'b00;
                        read_tx.tx_end          = {1'b0, 1'b0, 1'b1};
                        read_tx.tx_endptr[0]    = { 2'b00, 4'b0000 };
                    end
                    mrd_count_r_m4 : begin // four away from goal count
                        next_state                  = IDLE;
                        read_tx.tx_start            = {1'b0, 1'b1, 1'b1};
                        read_tx.tx_startptr[0]      = 2'b00;
                        read_tx.tx_startptr[1]      = 2'b01;
                        read_tx.tx_end              = {1'b0, 1'b1, 1'b1};
                        read_tx.tx_endptr[0]        = { 2'b00, 4'b0000 };
                        read_tx.tx_endptr[1]        = { 2'b01, 4'b0000 };
                        read_tx.tx_startnpinfo[1]   = 3'b001;
                    end
                    mrd_count_r_m5 : begin // five away from goal count
                        next_state                  = IDLE;
                        read_tx.tx_start            = {1'b0, 1'b1, 1'b1};
                        read_tx.tx_startptr[0]      = 2'b00;
                        read_tx.tx_startptr[1]      = 2'b01;
                        read_tx.tx_end              = {1'b0, 1'b1, 1'b1};
                        read_tx.tx_endptr[0]        = { 2'b00, 4'b0000 };
                        read_tx.tx_endptr[1]        = { 2'b01, 4'b0000 };
                        read_tx.tx_startnpinfo[1]   = 3'b011;
                    end
                    mrd_count_r_m6 : begin // six away from goal count
                        next_state              = IDLE;
                        read_tx.tx_start        = {1'b0, 1'b1, 1'b1};
                        read_tx.tx_startptr[0]  = 2'b00;
                        read_tx.tx_startptr[1]  = 2'b01;
                        read_tx.tx_end          = {1'b0, 1'b1, 1'b1};
                        read_tx.tx_endptr[0]    = { 2'b00, 4'b0000 };
                        read_tx.tx_endptr[1]    = { 2'b01, 4'b0000 };
                    end
                    mrd_count_r_m7 : begin // seven away from goal count
                        next_state                  = IDLE;
                        read_tx.tx_start            = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_startptr[0]      = 2'b00;
                        read_tx.tx_startptr[1]      = 2'b01;
                        read_tx.tx_startptr[2]      = 2'b10;
                        read_tx.tx_end              = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_endptr[0]        = { 2'b00, 4'b0000 };
                        read_tx.tx_endptr[1]        = { 2'b01, 4'b0000 };
                        read_tx.tx_endptr[2]        = { 2'b10, 4'b0000 };
                        read_tx.tx_startnpinfo[2]   = 3'b001;
                    end
                    mrd_count_r_m8 : begin // eight away from goal count
                        next_state                  = IDLE;
                        read_tx.tx_start            = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_startptr[0]      = 2'b00;
                        read_tx.tx_startptr[1]      = 2'b01;
                        read_tx.tx_startptr[2]      = 2'b10;
                        read_tx.tx_end              = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_endptr[0]        = { 2'b00, 4'b0000 };
                        read_tx.tx_endptr[1]        = { 2'b01, 4'b0000 };
                        read_tx.tx_endptr[2]        = { 2'b10, 4'b0000 };
                        read_tx.tx_startnpinfo[2]   = 3'b011;
                    end
                    mrd_count_r_m9 : begin // nine away from goal count
                        next_state              = IDLE;
                        read_tx.tx_start        = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_startptr[0]  = 2'b00;
                        read_tx.tx_startptr[1]  = 2'b01;
                        read_tx.tx_startptr[2]  = 2'b10;
                        read_tx.tx_end          = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_endptr[0]    = { 2'b00, 4'b0000 };
                        read_tx.tx_endptr[1]    = { 2'b01, 4'b0000 };
                        read_tx.tx_endptr[2]    = { 2'b10, 4'b0000 };
                    end
                    default : begin // >9 away from goal count (need more than this cycle)
                        read_tx.tx_start        = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_startptr[0]  = 2'b00;
                        read_tx.tx_startptr[1]  = 2'b01;
                        read_tx.tx_startptr[2]  = 2'b10;
                        read_tx.tx_end          = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_endptr[0]    = { 2'b00, 4'b0000 };
                        read_tx.tx_endptr[1]    = { 2'b01, 4'b0000 };
                        read_tx.tx_endptr[2]    = { 2'b10, 4'b0000 };
                    end
                endcase
            end
        end

        SEND_TWO : begin
            addr_ptr_1_00   = addr_ptr_r + addr_inc9_r;
            addr_ptr_1_01   = addr_ptr_r + addr_inc10_r;
            addr_ptr_1_02   = addr_ptr_r + addr_inc11_r;
            addr_ptr_1_10   = addr_ptr_r + addr_inc12_r;
            addr_ptr_1_11   = addr_ptr_r + addr_inc13_r;
            addr_ptr_1_12   = addr_ptr_r + addr_inc14_r;
            addr_ptr_1_20   = addr_ptr_r + addr_inc15_r;
            addr_ptr_1_21   = addr_ptr_r + addr_inc16_r;
            addr_ptr_1_22   = addr_ptr_r + addr_inc17_r;

            if(tag_9_avail_r && tag_10_avail_r && tag_11_avail_r && tag_12_avail_r && tag_13_avail_r && tag_14_avail_r &&
               tag_15_avail_r && tag_16_avail_r && tag_17_avail_r && fifo_full == '0) begin
                next_state = SEND_ONE;

                read_tx.tx_valid = 1'b1;

                np_hdr.addr = addr_ptr_0_00_r;

                read_tx.tx_data[0].np[0]    = np_hdr;
                read_tx.tx_data[0].np[1]    = np_hdr;
                read_tx.tx_data[0].np[2]    = np_hdr;
                read_tx.tx_data[1].np[0]    = np_hdr;
                read_tx.tx_data[1].np[1]    = np_hdr;
                read_tx.tx_data[1].np[2]    = np_hdr;
                read_tx.tx_data[2].np[0]    = np_hdr;
                read_tx.tx_data[2].np[1]    = np_hdr;
                read_tx.tx_data[2].np[2]    = np_hdr;

                read_tx.tx_data[0].np[1].addr   = addr_ptr_0_01_r;
                read_tx.tx_data[0].np[2].addr   = addr_ptr_0_02_r;
                read_tx.tx_data[1].np[0].addr   = addr_ptr_0_10_r;
                read_tx.tx_data[1].np[1].addr   = addr_ptr_0_11_r;
                read_tx.tx_data[1].np[2].addr   = addr_ptr_0_12_r;
                read_tx.tx_data[2].np[0].addr   = addr_ptr_0_20_r;
                read_tx.tx_data[2].np[1].addr   = addr_ptr_0_21_r;
                read_tx.tx_data[2].np[2].addr   = addr_ptr_0_22_r;

                read_tx.tx_data[0].np[0].tid    = tags_r[9];
                read_tx.tx_data[0].np[1].tid    = tags_r[10];
                read_tx.tx_data[0].np[2].tid    = tags_r[11];
                read_tx.tx_data[1].np[0].tid    = tags_r[12];
                read_tx.tx_data[1].np[1].tid    = tags_r[13];
                read_tx.tx_data[1].np[2].tid    = tags_r[14];
                read_tx.tx_data[2].np[0].tid    = tags_r[15];
                read_tx.tx_data[2].np[1].tid    = tags_r[16];
                read_tx.tx_data[2].np[2].tid    = tags_r[17];

                tag_used_valid_2          = 1'b1;

                next_addr_ptr           = addr_ptr_2;

                next_count              = count_p1_r;

                case (count_r)
                    mrd_count_r_m10 : begin // one away from goal count
                        next_state                  = IDLE;
                        read_tx.tx_start            = {1'b0, 1'b0, 1'b1};
                        read_tx.tx_startptr[0]      = 2'b00;
                        read_tx.tx_end              = {1'b0, 1'b0, 1'b1};
                        read_tx.tx_endptr[0]        = { 2'b00, 4'b0000 };
                        read_tx.tx_startnpinfo[0]   = 3'b001;
                    end
                    mrd_count_r_m11 : begin // two away from goal count
                        next_state                  = IDLE;
                        read_tx.tx_start            = {1'b0, 1'b0, 1'b1};
                        read_tx.tx_startptr[0]      = 2'b00;
                        read_tx.tx_end              = {1'b0, 1'b0, 1'b1};
                        read_tx.tx_endptr[0]        = { 2'b00, 4'b0000 };
                        read_tx.tx_startnpinfo[0]   = 3'b011;
                    end
                    mrd_count_r_m12 : begin // three away from goal count
                        next_state              = IDLE;
                        read_tx.tx_start        = {1'b0, 1'b0, 1'b1};
                        read_tx.tx_startptr[0]  = 2'b00;
                        read_tx.tx_end          = {1'b0, 1'b0, 1'b1};
                        read_tx.tx_endptr[0]    = { 2'b00, 4'b0000 };
                    end
                    mrd_count_r_m13 : begin // four away from goal count
                        next_state                  = IDLE;
                        read_tx.tx_start            = {1'b0, 1'b1, 1'b1};
                        read_tx.tx_startptr[0]      = 2'b00;
                        read_tx.tx_startptr[1]      = 2'b01;
                        read_tx.tx_end              = {1'b0, 1'b1, 1'b1};
                        read_tx.tx_endptr[0]        = { 2'b00, 4'b0000 };
                        read_tx.tx_endptr[1]        = { 2'b01, 4'b0000 };
                        read_tx.tx_startnpinfo[1]   = {1'b0, 1'b0, 1'b1};
                    end
                    mrd_count_r_m14 : begin // five away from goal count
                        next_state                  = IDLE;
                        read_tx.tx_start            = {1'b0, 1'b1, 1'b1};
                        read_tx.tx_startptr[0]      = 2'b00;
                        read_tx.tx_startptr[1]      = 2'b01;
                        read_tx.tx_end              = {1'b0, 1'b1, 1'b1};
                        read_tx.tx_endptr[0]        = { 2'b00, 4'b0000 };
                        read_tx.tx_endptr[1]        = { 2'b01, 4'b0000 };
                        read_tx.tx_startnpinfo[1]   = 3'b011;
                    end
                    mrd_count_r_m15 : begin // six away from goal count
                        next_state              = IDLE;
                        read_tx.tx_start        = {1'b0, 1'b1, 1'b1};
                        read_tx.tx_startptr[0]  = 2'b00;
                        read_tx.tx_startptr[1]  = 2'b01;
                        read_tx.tx_end          = {1'b0, 1'b1, 1'b1};
                        read_tx.tx_endptr[0]    = { 2'b00, 4'b0000 };
                        read_tx.tx_endptr[1]    = { 2'b01, 4'b0000 };
                    end
                    mrd_count_r_m16 : begin // seven away from goal count
                        next_state                  = IDLE;
                        read_tx.tx_start            = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_startptr[0]      = 2'b00;
                        read_tx.tx_startptr[1]      = 2'b01;
                        read_tx.tx_startptr[2]      = 2'b10;
                        read_tx.tx_end              = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_endptr[0]        = { 2'b00, 4'b0000 };
                        read_tx.tx_endptr[1]        = { 2'b01, 4'b0000 };
                        read_tx.tx_endptr[2]        = { 2'b10, 4'b0000 };
                        read_tx.tx_startnpinfo[2]   = 3'b001;
                    end
                    mrd_count_r_m17 : begin // eight away from goal count
                        next_state                  = IDLE;
                        read_tx.tx_start            = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_startptr[0]      = 2'b00;
                        read_tx.tx_startptr[1]      = 2'b01;
                        read_tx.tx_startptr[2]      = 2'b10;
                        read_tx.tx_end              = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_endptr[0]        = { 2'b00, 4'b0000 };
                        read_tx.tx_endptr[1]        = { 2'b01, 4'b0000 };
                        read_tx.tx_endptr[2]        = { 2'b10, 4'b0000 };
                        read_tx.tx_startnpinfo[2]   = 3'b011;
                    end
                    mrd_count_r_m18 : begin // nine away from goal count
                        next_state              = IDLE;
                        read_tx.tx_start        = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_startptr[0]  = 2'b00;
                        read_tx.tx_startptr[1]  = 2'b01;
                        read_tx.tx_startptr[2]  = 2'b10;
                        read_tx.tx_end          = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_endptr[0]    = { 2'b00, 4'b0000 };
                        read_tx.tx_endptr[1]    = { 2'b01, 4'b0000 };
                        read_tx.tx_endptr[2]    = { 2'b10, 4'b0000 };
                    end
                    default : begin // >9 away from goal count (need more than this cycle)
                        read_tx.tx_start        = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_startptr[0]  = 2'b00;
                        read_tx.tx_startptr[1]  = 2'b01;
                        read_tx.tx_startptr[2]  = 2'b10;
                        read_tx.tx_end          = {1'b1, 1'b1, 1'b1};
                        read_tx.tx_endptr[0]    = { 2'b00, 4'b0000 };
                        read_tx.tx_endptr[1]    = { 2'b01, 4'b0000 };
                        read_tx.tx_endptr[2]    = { 2'b10, 4'b0000 };
                    end
                endcase
            end
        end

        default :
            next_state = IDLE;

    endcase
end

always @(posedge clk) begin
    if (comb_reset) begin
        next_tag_ptr_r  <= '0;
        next_tags_r     <= '0;
        tag_ptr_r       <= '0;
        tags_r          <= '0;
    end else begin
        tag_ptr_r       <= next_tag_ptr;
        next_tag_ptr_r  <= future_tag_ptr;
        tags_r          <= next_tags;
        next_tags_r     <= future_tags;
    end
end

// Track next tag
always_comb begin
    next_tags = tags_r;
    future_tags = next_tags_r;

    next_tag_ptr = tag_ptr_r;
    future_tag_ptr = next_tag_ptr_r;


    case(current_state)
        IDLE : begin
            if (cfg_10b_tag_req_en) begin
                next_tag_ptr        = 10'd18;
                next_tags           = {10'd273, 10'd272, 10'd271, 10'd270, 10'd269, 10'd268, 10'd267, 10'd266, 10'd265,
                                            10'd264, 10'd263, 10'd262, 10'd261, 10'd260, 10'd259, 10'd258, 10'd257, 10'd256};
            end else if (cfg_ext_tag_en) begin // applies to both ext tag (8b) and non (5b)
                next_tag_ptr        = 10'd18;
                next_tags           = {10'd17, 10'd16, 10'd15, 10'd14, 10'd13, 10'd12, 10'd11, 10'd10, 10'd9,
                                            10'd8, 10'd7, 10'd6, 10'd5, 10'd4, 10'd3, 10'd2, 10'd1, 10'd0};
            end else begin
                next_tag_ptr        = 10'd0;
                next_tags           = {10'd17, 10'd16, 10'd15, 10'd14, 10'd13, 10'd12, 10'd11, 10'd10, 10'd9,
                                            10'd8, 10'd7, 10'd6, 10'd5, 10'd4, 10'd3, 10'd2, 10'd1, 10'd0};
            end
        end

        SEND_ONE : begin
            // reset counter
            if (cfg_10b_tag_req_en) begin
                for (int unsigned i = 0; i < 18; i++) begin
                    future_tags[i] = 256 + ((tag_ptr_r + i) % 512);
                end
                future_tag_ptr = future_tags[17] >= 768 ? '0 : tag_ptr_r + 18;
            end
            else if (cfg_ext_tag_en) begin
                for (int unsigned i = 0; i < 18; i++) begin
                    future_tags[i] = ((tag_ptr_r + i) % 256);
                end
                future_tag_ptr = future_tags[17] >= 256 ? '0 : tag_ptr_r + 18;
            end
            else if (!cfg_ext_tag_en && !cfg_10b_tag_req_en) begin
                for (int unsigned i = 0; i < 18; i++) begin
                    future_tags[i] = ((tag_ptr_r + i) % 32);
                end
                future_tag_ptr = future_tags[17] >= 32 ? '0 : tag_ptr_r + 18;
            end else begin
                future_tag_ptr = tag_ptr_r + 18;
            end
        end

        SEND_TWO : begin
            if(tag_9_avail_r && tag_10_avail_r && tag_11_avail_r && tag_12_avail_r && tag_13_avail_r && tag_14_avail_r &&
               tag_15_avail_r && tag_16_avail_r && tag_17_avail_r && fifo_full == '0) begin
                next_tags = next_tags_r;
                next_tag_ptr = next_tag_ptr_r;
            end
        end

        default : begin

        end
    endcase
end


// Calculate pool of available tags
always @(posedge clk) begin
    tag_pool_r <= tag_pool;
end

localparam int max_returned_tags = $clog2(NUM_SLOTS)>>1;
always_comb begin
    if (current_state == IDLE) begin
        if (cfg_10b_tag_req_en) begin
            tag_pool = {{512{1'b1}}, {256{1'b0}}};
        end else if (cfg_ext_tag_en) begin
            tag_pool = {{512{1'b0}}, {256{1'b1}}};
        end else begin
            tag_pool = {{736{1'b0}}, {32{1'b1}}};
        end
    end else begin
        tag_pool = tag_pool_r;
        for (int j = 0; j <= max_returned_tags; j++) begin
            if (tag_valid[j]) begin
                tag_pool[tag_released[j]] = 1'b1;
            end
        end
        if (tag_used_valid_1_r) begin
            for (int i = 0; i < 9; i++) begin
                tag_pool[tags_r_r[i]] = 1'b0;
            end
        end
        if (tag_used_valid_2_r) begin
            for (int i = 9; i < 18; i++) begin
                tag_pool[tags_r_r[i]] = 1'b0;
            end
        end
    end
end


// ---------------------------------------------------------------------------
// Validation aid (non-synthesizable): a Memory-Read must never be launched on a
// tag whose pool bit is currently busy (i.e. still outstanding). Fires on the
// pre-fix RTL when the gate/issue batches diverge; should stay silent after the
// fix. Safe to delete once the fix is signed off.
// ---------------------------------------------------------------------------
// synthesis translate_off
`ifndef SYNTHESIS
always @(posedge clk) begin
    if (rst_n) begin
        if (tag_used_valid_1) begin
            for (int i = 0; i < 9; i++) begin
                assert (tag_pool_r[tags_r[i]])
                    else $error("BMD_AXIST_TX_READ: SEND_ONE launched busy tag %0d (pool bit clear) @ %0t",
                                tags_r[i], $time);
            end
        end
        if (tag_used_valid_2) begin
            for (int i = 9; i < 18; i++) begin
                assert (tag_pool_r[tags_r[i]])
                    else $error("BMD_AXIST_TX_READ: SEND_TWO launched busy tag %0d (pool bit clear) @ %0t",
                                tags_r[i], $time);
            end
        end
    end
end
`endif
// synthesis translate_on

endmodule // BMD_AXIST_TX_READ
