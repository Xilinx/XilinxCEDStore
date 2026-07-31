
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
// File       : BMD_AXIST_TX_WRITE.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_TX_WRITE.sv
//--
//-- Description: Generates MemWr traffic when instructed by CSRs
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_TX_WRITE
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
  import bmd_cfg_pkg::*;
#(
    parameter int                           PATTERN_WIDTH = 32
)(
    input  logic                            clk,
    input  logic                            rst_n,
    input  logic                            init_rst_i,
    // Memory Write
    input  logic                            mwr_start_i,
    input  logic                            mwr_inc_i,
    input  logic [9:0]                      mwr_tid_i,
    input  logic [31:0]                     mwr_addr_i,
    input  logic [31:0]                     mwr_up_addr_i,
    input  logic [31:0]                     mwr_data_i,
    input  logic [10:0]                     mwr_len_i,
    input  logic [15:0]                     mwr_count_i,
    output logic                            mwr_done_o,
    input  logic                            mwr_nosnoop_i,
    input  logic                            mwr_relaxed_order_i,
    input  logic                            mwr_64b_en_i,
    input  logic [2:0]                      mwr_tlp_tc_i,
    input  logic                            mwr_poisoned_i,
    input  logic [1:0]                      mwr_ats_i,
    input  logic                            mwr_nw_i,
    input  logic                            mwr_tph_en_i,
    input  logic [7:0]                      mwr_steering_tag_i,
    input  logic [1:0]                      mwr_phint_i,
    input  logic [3:0]                      mwr_upper_be_i,
    input  logic [3:0]                      mwr_lower_be_i,
    input  logic [15:0]                     mwr_rrid_i,
    input  logic                            mwr_tbit_i,
    input  logic                            mwr_td_i,

    input  logic [11:0]                     mwr_tph_i,
    input  logic                            mwr_tph_vld_i,
    input  logic [23:0]                     mwr_ide_i,
    input  logic                            mwr_ide_vld_i,
    input  logic [23:0]                     mwr_pasid_i,
    input  logic                            mwr_pasid_vld_i,
    input  logic                            mwr_fmt_i,
    input  logic [4:0]                      mwr_type_i,

    output logic [15:0]                     count_o,

    output tx_intf                          write_tx,

    input  logic [NUM_SLOTS-1:0]            fifo_full,

    output logic [31:0]                     debug
);

// Write State Machine States
localparam logic [2:0]      IDLE    = 3'b000;
localparam logic [2:0]      SONE    = 3'b001;
localparam logic [2:0]      SADF    = 3'b010;
localparam logic [2:0]      STWO    = 3'b100;
localparam logic [2:0]      SROLL   = 3'b101;
localparam logic [2:0]      SHDR    = 3'b110;

// State machine registers
logic [2:0]     current_state;
logic [2:0]     next_state;

// Register signals for write instructions
logic           mwr_start_r;
logic [31:0]    mwr_data_r;
logic [10:0]    mwr_len_r;
logic [15:0]    mwr_count_r, mwr_count_r_m1, mwr_count_r_m2, mwr_count_r_m3;
// Register signals for sideband information
logic [9:0]     mwr_tid_r;
logic           mwr_nosnoop_r;
logic           mwr_relaxed_order_r;
logic           mwr_64b_en_r;
logic [2:0]     mwr_tlp_tc_r;
logic           mwr_poisoned_r;
logic [1:0]     mwr_ats_r;
logic           mwr_nw_r;
logic           mwr_tph_en_r;
logic [7:0]     mwr_steering_tag_r;
logic [1:0]     mwr_phint_r;
logic [11:0]    mwr_tph_r;
logic           mwr_tph_vld_r;
logic [23:0]    mwr_ide_r;
logic           mwr_ide_vld_r;
logic [23:0]    mwr_pasid_r;
logic           mwr_pasid_vld_r;
logic           mwr_fmt_r;
logic [4:0]     mwr_type_r;
logic [3:0]     mwr_upper_be_r;
logic [3:0]     mwr_lower_be_r;
logic [15:0]    mwr_rrid_r;
logic           mwr_tbit_r;
logic           mwr_td_r;
// Track progress on writes
logic           mwr_in_progress_r;

// Content portion of data slot and entire slot
logic [DATA_SLOT_WIDTH-1:0] data_slot;
logic [TX_SLOT_WIDTH-1:0]   full_data_slot;

// Assign data content
localparam int          NUM_REPEATS = DATA_SLOT_WIDTH / PATTERN_WIDTH;
localparam int          OVERFLOW    = DATA_SLOT_WIDTH - (NUM_REPEATS * PATTERN_WIDTH);
localparam int          DATA_DIFF   = TX_SLOT_WIDTH - DATA_SLOT_WIDTH;
always_comb begin
    //if (OVERFLOW != 0)
    //    // Repeat data content and pad
    //    data_slot = { mwr_data_r[OVERFLOW-1:0], {NUM_REPEATS{mwr_data_r}} };
    //else
        data_slot = {NUM_REPEATS{mwr_data_r}};
end
// Now we have appropriate content to fill our write data slots
assign full_data_slot = { {DATA_DIFF{1'b0}}, data_slot };

// How much data per length
logic [6:0]    amt_of_dslots, amt_of_dslots_r, amt_of_dslots_r_m1, amt_of_dslots_r_m2;
always_comb begin
    // Turn mwr_len_r into bits and divide by bit counter per slot
    amt_of_dslots = ((mwr_len_i << 5) / DATA_SLOT_WIDTH);
    if ((mwr_len_i << 5) % DATA_SLOT_WIDTH != 0) begin
        amt_of_dslots = amt_of_dslots + 1;
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

assign byte1_tph    = mwr_tph_r[11:4];
assign byte2_tph    = {mwr_tph_r[3:0], 4'h0};
assign byte3_tph    = '0;

logic [7:0]                     byte1_pasid;
logic [7:0]                     byte2_pasid;
logic [7:0]                     byte3_pasid;

assign byte1_pasid  = {mwr_pasid_r[23:22], 2'b00, mwr_pasid_r[19:16]};
assign byte2_pasid  = mwr_pasid_r[15:8];
assign byte3_pasid  = mwr_pasid_r[7:0];

logic [7:0]                     byte1_ide;
logic [7:0]                     byte2_ide;
logic [7:0]                     byte3_ide;

assign byte1_ide    = mwr_ide_r[23:16];
assign byte2_ide    = mwr_ide_r[15:8];
assign byte3_ide    = {1'b0, mwr_ide_r[6:0]};

logic [31:0]                    tph_prefix;
logic [31:0]                    pasid_prefix;
logic [31:0]                    ide_prefix;

assign tph_prefix       = {byte3_tph,
                           byte2_tph,
                           byte1_tph,
                           byte0_tph};

assign pasid_prefix     = {byte3_pasid,
                           byte2_pasid,
                           byte1_pasid,
                           byte0_pasid};

assign ide_prefix       = {byte3_ide,
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
    case({mwr_ide_vld_r, mwr_pasid_vld_r, mwr_tph_vld_r})
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

// Assign tx interface fields that won't change
assign write_tx.tx_parity       = '0;
assign write_tx.tx_starttype    = {2'b00, 2'b00, 2'b00};
assign write_tx.tx_startnpinfo  = {3'b000, 3'b000, 3'b000};
assign write_tx.tx_end_error    = 9'b0; // TBD
// Create a template header for our P headers
tx_data_p p_hdr;
assign p_hdr.fmt            = { mwr_fmt_r, mwr_64b_en_r };
assign p_hdr.ttype          = mwr_type_r; // See table 2-3 in PCIe Spec 6.2
assign p_hdr.tc             = mwr_tlp_tc_r;
assign p_hdr.attr           = { 1'b0, mwr_relaxed_order_r, mwr_nosnoop_r };
assign p_hdr.remote_req_id  = mwr_rrid_r;
assign p_hdr.tid            = mwr_tid_r; // Tag
assign p_hdr.t_bit          = mwr_tbit_r; // T bit in IDE prefix
assign p_hdr.func_num       = FUNC_NUM;
assign p_hdr.vfunc_num      = VFUNC_NUM;
assign p_hdr.vfunc_active   = VFUNC_ACTIVE;
assign p_hdr.td             = mwr_td_r; // TLP Digest
assign p_hdr.byte_len       = { mwr_len_r, 2'b00 };
assign p_hdr.byte_en        = {mwr_upper_be_r, mwr_lower_be_r};
assign p_hdr.ats            = mwr_ats_r;
assign p_hdr.nw             = mwr_nw_r; // no-write
assign p_hdr.th             = mwr_tph_en_r;
assign p_hdr.ph             = mwr_phint_r;
assign p_hdr.st             = mwr_steering_tag_r;
assign p_hdr.ep             = mwr_poisoned_r;
assign p_hdr.bad_eot        = 1'b0; // Bad packet
assign p_hdr.atu_bypass     = 1'b1;
assign p_hdr.addr_align_en  = 1'b0;
assign p_hdr.prfx           = prfx_r;
assign p_hdr.segment        = '0;
assign p_hdr.dst_segment    = '0;
    // ECC/Parity for header
generate if (HDR_PROT_CHECK) begin : gen_hdr_prot // client2_hdr_prot
    assign p_hdr.hdr_prot[0]    = ^p_hdr.th;
    assign p_hdr.hdr_prot[1]    = ^p_hdr.st;
    assign p_hdr.hdr_prot[2]    = ^p_hdr.ph;
    assign p_hdr.hdr_prot[3]    = ^p_hdr.vfunc_active;
    assign p_hdr.hdr_prot[4]    = ^p_hdr.vfunc_num;
    assign p_hdr.hdr_prot[5]    = '0; // tlp_ln unused
    assign p_hdr.hdr_prot[6]    = ^p_hdr.func_num;
    assign p_hdr.hdr_prot[7]    = ^p_hdr.attr;
    assign p_hdr.hdr_prot[8]    = ^p_hdr.addr_align_en;
    assign p_hdr.hdr_prot[9]    = ^p_hdr.byte_en;
    assign p_hdr.hdr_prot[10]   = ^p_hdr.remote_req_id;
    assign p_hdr.hdr_prot[11]   = '0; // cpl_status unused
    assign p_hdr.hdr_prot[12]   = '0; // cpl_bcm unused
    assign p_hdr.hdr_prot[13]   = '0; // byte_count unused
    assign p_hdr.hdr_prot[14]   = ^p_hdr.tid;
    assign p_hdr.hdr_prot[15]   = ^p_hdr.byte_len;
    assign p_hdr.hdr_prot[16]   = ^p_hdr.ep;
    assign p_hdr.hdr_prot[17]   = ^p_hdr.td;
    assign p_hdr.hdr_prot[18]   = ^p_hdr.tc;
    assign p_hdr.hdr_prot[19]   = ^p_hdr.ttype;
    assign p_hdr.hdr_prot[20]   = ^p_hdr.fmt;
    assign p_hdr.hdr_prot[21]   = ^p_hdr.addr;
end else begin : gen_no_hdr_prot
    assign p_hdr.hdr_prot       = '0;
end
endgenerate

assign p_hdr.reserved       = '0;

// Data Rollover counter
logic [6:0]     rollover_r;

// Packet counter
logic [15:0]    count_r;
assign count_o = count_r;

// Combined reset ('user' and system)
logic           comb_reset;
assign  comb_reset = !rst_n || init_rst_i;

// Helper for adding registers and current state values
logic [6:0]     next_rollover;
logic [1:0]     this_count;
logic [15:0]    next_count;
assign next_count = count_r + this_count;

// Address pointer
logic [63:0]    base_addr_ptr, addr_ptr_r, next_addr_ptr, addr_ptr_p_r,
                addr_ptr_p2_r, addr_ptr_p, addr_ptr_p2, addr_ptr_p3, addr_ptr_p3_r;
logic [10:0]    addr_inc_r;
logic [11:0]    addr_inc2_r;
logic [11:0]    addr_inc3_r;
logic [12:0]    addr_inc4_r;
assign base_addr_ptr = { mwr_64b_en_i ? {mwr_up_addr_i, mwr_addr_i} : {32'b0, mwr_addr_i} };

// Dword offset register
logic [3:0]     dword_r;

assign debug = {
    addr_ptr_r[8:2],
    rollover_r,
    current_state,
    count_r
};

// Handle register and state changes and resets
always @(posedge clk) begin
    if (comb_reset) begin
        current_state       <= '0;

        mwr_data_r          <= '0;
        mwr_len_r           <= '0;
        mwr_count_r         <= '0;
        mwr_count_r_m1      <= '0;
        mwr_count_r_m2      <= '0;
        mwr_count_r_m3      <= '0;
        mwr_nosnoop_r       <= '0;
        mwr_relaxed_order_r <= '0;
        mwr_64b_en_r        <= '0;
        mwr_tlp_tc_r        <= '0;
        mwr_poisoned_r      <= '0;
        mwr_ats_r           <= '0;
        mwr_nw_r            <= '0;
        mwr_tph_en_r        <= '0;
        mwr_steering_tag_r  <= '0;
        mwr_phint_r         <= '0;

        mwr_tid_r           <= '0;
        mwr_tph_r           <= '0;
        mwr_tph_vld_r       <= '0;
        mwr_ide_r           <= '0;
        mwr_ide_vld_r       <= '0;
        mwr_pasid_r         <= '0;
        mwr_pasid_vld_r     <= '0;
        mwr_fmt_r           <= '0;
        mwr_type_r          <= '0;
        mwr_upper_be_r      <= '0;
        mwr_lower_be_r      <= '0;
        mwr_rrid_r          <= '0;
        mwr_tbit_r          <= '0;
        mwr_td_r            <= '0;
        mwr_start_r         <= '0;

        rollover_r          <= '0;
        count_r             <= '0;
        addr_inc_r          <= '0;
        addr_inc2_r         <= '0;
        addr_inc3_r         <= '0;
        addr_inc4_r         <= '0;
        addr_ptr_r          <= '0;
        addr_ptr_p_r        <= '0;
        addr_ptr_p2_r       <= '0;
        addr_ptr_p3_r       <= '0;

        dword_r             <= '0;
        amt_of_dslots_r     <= '0;
        amt_of_dslots_r_m1  <= '0;
        amt_of_dslots_r_m2  <= '0;
        mwr_in_progress_r   <= '0;
    end else begin
        current_state <= next_state;

        addr_ptr_r <= next_addr_ptr;
        addr_ptr_p_r  <= addr_ptr_p;
        addr_ptr_p2_r <= addr_ptr_p2;
        addr_ptr_p3_r <= addr_ptr_p3;
        rollover_r <= next_rollover;
        count_r <= next_count;

        // If we are starting generation this cycle
        if (mwr_start_i && !mwr_in_progress_r) begin
            mwr_start_r         <= mwr_start_i;
            mwr_data_r          <= mwr_data_i;
            mwr_len_r           <= mwr_len_i;
            mwr_count_r         <= mwr_count_i;
            mwr_count_r_m1      <= mwr_count_i - 1;
            mwr_count_r_m2      <= mwr_count_i - 2;
            mwr_count_r_m3      <= mwr_count_i - 3;
            mwr_nosnoop_r       <= mwr_nosnoop_i;
            mwr_relaxed_order_r <= mwr_relaxed_order_i;
            mwr_64b_en_r        <= mwr_64b_en_i;
            mwr_tlp_tc_r        <= mwr_tlp_tc_i;
            mwr_poisoned_r      <= mwr_poisoned_i;
            mwr_ats_r           <= mwr_ats_i;
            mwr_nw_r            <= mwr_nw_i;
            mwr_tph_en_r        <= mwr_tph_en_i;
            mwr_steering_tag_r  <= mwr_steering_tag_i;
            mwr_phint_r         <= mwr_phint_i;

            mwr_tid_r           <= mwr_tid_i;
            mwr_tph_r           <= mwr_tph_i;
            mwr_tph_vld_r       <= mwr_tph_vld_i;
            mwr_ide_r           <= mwr_ide_i;
            mwr_ide_vld_r       <= mwr_ide_vld_i;
            mwr_pasid_r         <= mwr_pasid_i;
            mwr_pasid_vld_r     <= mwr_pasid_vld_i;
            mwr_fmt_r           <= mwr_fmt_i;
            mwr_type_r          <= mwr_type_i;
            mwr_upper_be_r      <= mwr_upper_be_i;
            mwr_lower_be_r      <= mwr_lower_be_i;
            mwr_rrid_r          <= mwr_rrid_i;
            mwr_tbit_r          <= mwr_tbit_i;
            mwr_td_r            <= mwr_td_i;

            addr_ptr_r          <= base_addr_ptr;

            if (!mwr_inc_i) begin
                addr_inc_r          <= mwr_len_i << 2;
                addr_inc2_r         <= mwr_len_i << 3;
                addr_inc3_r         <= (mwr_len_i << 2) + (mwr_len_i << 3);
                addr_inc4_r         <= mwr_len_i << 4;
            end else begin
                addr_inc_r          <= '0;
                addr_inc2_r         <= '0;
                addr_inc3_r         <= '0;
                addr_inc4_r         <= '0;
            end

            dword_r             <= mwr_len_i[3:0];
            amt_of_dslots_r     <= amt_of_dslots;
            amt_of_dslots_r_m1  <= amt_of_dslots - 1;
            amt_of_dslots_r_m2  <= amt_of_dslots - 2;
            mwr_in_progress_r   <= 1'b1;
        end
    end
end

// Combinational logic for each state
always_comb begin
    // Default values
    next_state              = current_state;
    mwr_done_o              = 1'b0;

    // TX Slots
    write_tx.tx_data[0]     = '0;
    write_tx.tx_data[1]     = '0;
    write_tx.tx_data[2]     = '0;

    // TX Info
    write_tx.tx_valid       = 1'b0;
    write_tx.tx_start       = {1'b0, 1'b0, 1'b0};
    write_tx.tx_startptr[0] = 2'b00;
    write_tx.tx_startptr[1] = 2'b00;
    write_tx.tx_startptr[2] = 2'b00;
    write_tx.tx_end         = {1'b0, 1'b0, 1'b0};
    write_tx.tx_endptr[0]   = 6'b000000;
    write_tx.tx_endptr[1]   = 6'b000000;
    write_tx.tx_endptr[2]   = 6'b000000;

    p_hdr.addr              = '0;

    next_addr_ptr           = addr_ptr_r;
    addr_ptr_p              = addr_ptr_p_r;
    addr_ptr_p2             = addr_ptr_p2_r;
    addr_ptr_p3             = addr_ptr_p3_r;
    next_rollover           = rollover_r;
    this_count              = '0;

    case(current_state)

        // Wait until we are instructed to start by CSRs
        IDLE : begin
            addr_ptr_p    = addr_ptr_r + addr_inc_r;
            addr_ptr_p2   = addr_ptr_r + addr_inc2_r;
            addr_ptr_p3   = addr_ptr_r + addr_inc3_r;

            if (mwr_in_progress_r && count_r >= mwr_count_r)
                mwr_done_o = 1'b1;
            else if (mwr_start_r) begin
                if (NUM_SLOTS == 3 && amt_of_dslots_r == 1 && mwr_count_r > 1) begin
                    next_state = STWO;
                end else if (amt_of_dslots_r == 0) begin
                    next_state = SHDR;
                end else begin
                    next_state = SONE;
                end
            end
        end // IDLE

        // Send one P header this cycle ( + Data )
        SONE : begin
            // If we are given control of main stream OR
            // we are already in progress with burst
            if (fifo_full == '0) begin
                addr_ptr_p    = addr_ptr_p_r + addr_inc_r;

                // Overall count
                this_count              = 2'b01;

                // Always correct for SONE
                write_tx.tx_valid       = 1'b1;
                write_tx.tx_start       = {1'b0, 1'b0, 1'b1};

                // Handle addresses and pointers
                p_hdr.addr = addr_ptr_r;
                next_addr_ptr = addr_ptr_p_r;

                case(rollover_r)
                    6'b00_0000 : begin
                        // We can assign here and just control with valids
                        write_tx.tx_data[0] = p_hdr;
                        write_tx.tx_data[1] = full_data_slot;
                        write_tx.tx_data[2] = full_data_slot;

                        write_tx.tx_startptr[0]   = 2'b00;
                        next_rollover           = amt_of_dslots_r_m2;
                        case(amt_of_dslots_r)
                            4'd1 : begin // One data slot + header
                                write_tx.tx_end         = {1'b0, 1'b0, 1'b1};
                                write_tx.tx_endptr[0]   = { 2'b01, 4'(dword_r) };

                                if (count_r == mwr_count_r_m1) begin
                                    next_state = IDLE;
                                end else begin
                                    next_state = SONE;
                                end
                            end
                            4'd2 : begin // Two data slots + header
                                write_tx.tx_end         = {1'b0, 1'b0, 1'b1};
                                write_tx.tx_endptr[0]   = { 2'b10, 4'(dword_r) };

                                if (count_r == mwr_count_r_m1) begin
                                    next_state = IDLE;
                                end else begin
                                    next_state = SONE;
                                end
                            end
                            4'd3, 4'd4 : begin // Three data slots + header
                                if (count_r == mwr_count_r_m1) begin
                                    next_state = SADF;
                                end else begin
                                    next_state = SONE;
                                end
                            end
                            default : begin
                                next_state              = SADF;
                            end
                        endcase
                    end

                    6'b00_0001 : begin
                        // We can assign here and just control with valids
                        write_tx.tx_data[0] = full_data_slot;
                        write_tx.tx_data[1] = p_hdr;
                        write_tx.tx_data[2] = full_data_slot;

                        write_tx.tx_startptr[0]   = 2'b01;
                        next_rollover           = amt_of_dslots_r_m1;
                        case(amt_of_dslots_r)
                            4'd1 : begin // One data slot + header
                                write_tx.tx_end         = {1'b0, 1'b1, 1'b1};
                                write_tx.tx_endptr[0]   = { 2'b00, 4'(dword_r) };
                                write_tx.tx_endptr[1]   = { 2'b10, 4'(dword_r) };

                                if (count_r == mwr_count_r_m1) begin
                                    next_state = IDLE;
                                end else begin
                                    next_state = SONE;
                                end
                            end
                            4'd2, 4'd3 : begin // Two/Three data slots + header
                                write_tx.tx_end         = {1'b0, 1'b0, 1'b1};
                                write_tx.tx_endptr[0]   = { 2'b00, 4'(dword_r) };

                                if (count_r == mwr_count_r_m1) begin
                                    next_state = SADF;
                                end else begin
                                    next_state = SONE;
                                end
                            end
                            default : begin
                                write_tx.tx_end         = {1'b0, 1'b0, 1'b1};
                                write_tx.tx_endptr[0]   = { 2'b00, 4'(dword_r) };
                                next_state              = SADF;
                            end
                        endcase
                    end

                    6'b00_0010 : begin
                        // We can assign here and just control with valids
                        write_tx.tx_data[0] = full_data_slot;
                        write_tx.tx_data[1] = full_data_slot;
                        write_tx.tx_data[2] = p_hdr;

                        write_tx.tx_startptr[0]   = 2'b10;
                        next_rollover             = amt_of_dslots_r;

                        write_tx.tx_end         = {1'b0, 1'b0, 1'b1};
                        write_tx.tx_endptr[0]   = { 2'b01, 4'(dword_r) };
                        if (amt_of_dslots_r >= NUM_SLOTS) begin
                            next_state = SADF;
                        end else if (count_r == mwr_count_r_m1) begin
                            next_state = SADF;
                        end else begin
                            next_state = SONE;
                        end
                    end

                    default : begin
                        // error
                    end
                endcase
            end
        end // SONE

        // Send all data slots this cycle
        SADF : begin
            if (fifo_full == '0) begin
                write_tx.tx_data[0] = full_data_slot;
                write_tx.tx_data[1] = full_data_slot;
                write_tx.tx_data[2] = full_data_slot;

                write_tx.tx_valid       = 1'b1;
                // Rollover will be how much data we need to send
                case (rollover_r)
                    5'd1: begin // Send 1 data slot
                        write_tx.tx_end         = {1'b0, 1'b0, 1'b1};
                        write_tx.tx_endptr[0]   = { 2'b00, 4'(dword_r) };
                        next_rollover           = '0;
                        if (count_r == mwr_count_r) // done?
                            next_state = IDLE;
                        else
                            next_state = SONE;
                    end
                    5'd2: begin // Send 2 data slots
                        write_tx.tx_end         = {1'b0, 1'b0, 1'b1};
                        write_tx.tx_endptr[0]   = { 2'b01, 4'(dword_r) };
                        next_rollover           = '0;
                        if (count_r == mwr_count_r) // done?
                            next_state = IDLE;
                        else
                            next_state = SONE;
                    end
                    5'd3: begin // Send 3 data slots
                        write_tx.tx_end         = {1'b0, 1'b0, 1'b1};
                        write_tx.tx_endptr[0]   = { 2'b10, 4'(dword_r) };
                        next_rollover           = '0;
                        if (count_r == mwr_count_r) // done?
                            next_state = IDLE;
                        else
                            next_state = SONE;
                    end
                    5'd4, 5'd5: begin
                        next_rollover           = rollover_r - 3;
                        if (count_r == mwr_count_r) // done?
                            next_state = SADF;
                        else
                            next_state = SONE;
                    end

                    default: begin // Send 3+ data slots and will send 3+ more...
                    // not much to do here. our data is always data pattern.
                    // not end nor start signals need to be set...
                        next_rollover           = rollover_r - 3;
                        next_state = SADF;
                    end
                endcase
            end
        end // SADF

        // Send two P header this cycle ( + Data )
        STWO : begin
            addr_ptr_p2   = addr_ptr_r + addr_inc2_r;
            addr_ptr_p3   = addr_ptr_r + addr_inc3_r;
            if (fifo_full == '0) begin
                // Overall count
                this_count              = 2'b10;
                unique case(count_r == mwr_count_r_m1)
                    1'b1 : begin // Send one
                        write_tx.tx_valid       = 1'b1;
                        write_tx.tx_start       = {1'b0, 1'b0, 1'b1};
                        write_tx.tx_startptr[0] = 2'b00;

                        // We can assign here and just control with valids
                        write_tx.tx_data[0] = p_hdr;
                        write_tx.tx_data[1] = full_data_slot;
                        write_tx.tx_data[2] = full_data_slot;

                        // Handle addresses and pointers
                        write_tx.tx_data[0].p.addr = addr_ptr_r;

                        write_tx.tx_end         = {1'b0, 1'b0, 1'b1};
                        write_tx.tx_endptr[0]   = { 2'b01, 4'(dword_r) };
                        next_rollover           = '0;
                        next_state              = IDLE;
                    end

                    1'b0 : begin // Send two
                        write_tx.tx_valid       = 1'b1;
                        write_tx.tx_start       = {1'b0, 1'b1, 1'b1};
                        write_tx.tx_startptr[0] = 2'b00;
                        write_tx.tx_startptr[1] = 2'b10;

                        // We can assign here and just control with valids
                        write_tx.tx_data[0] = p_hdr;
                        write_tx.tx_data[1] = full_data_slot;
                        write_tx.tx_data[2] = p_hdr;

                        // Handle addresses and pointers
                        write_tx.tx_data[0].p.addr = addr_ptr_r;
                        write_tx.tx_data[2].p.addr = addr_ptr_p_r;

                        write_tx.tx_end         = {1'b0, 1'b0, 1'b1};
                        write_tx.tx_endptr[0]   = { 2'b01, 4'(dword_r) };
                        next_rollover           = 5'd1;
                        next_state              = SROLL;
                    end
                endcase
            end
        end

        // Pair state for 2 posted headers when only 1 header needed
        SROLL : begin
            addr_ptr_p    = addr_ptr_r + addr_inc4_r;
            if (fifo_full == '0) begin
                this_count    = 2'b01;
                next_addr_ptr = addr_ptr_p3_r;
                case(1'b1)
                    count_r == mwr_count_r : begin // Just finish data
                        write_tx.tx_valid       = 1'b1;
                        write_tx.tx_start       = {1'b0, 1'b0, 1'b0};
                        write_tx.tx_startptr[0] = 2'b00;

                        // We can assign here and just control with valids
                        write_tx.tx_data[0] = full_data_slot;
                        write_tx.tx_data[1] = full_data_slot;
                        write_tx.tx_data[2] = full_data_slot;

                        write_tx.tx_end         = {1'b0, 1'b0, 1'b1};
                        write_tx.tx_endptr[0]   = { 2'b00, 4'(dword_r) };
                        next_rollover           = '0;
                        next_state              = IDLE;
                    end

                    count_r == mwr_count_r_m1 : begin // Last header
                        write_tx.tx_valid       = 1'b1;
                        write_tx.tx_start       = {1'b0, 1'b0, 1'b1};
                        write_tx.tx_startptr[0] = 2'b01;

                        // We can assign here and just control with valids
                        write_tx.tx_data[0] = full_data_slot;
                        write_tx.tx_data[1] = p_hdr;
                        write_tx.tx_data[2] = full_data_slot;

                        // Handle addresses and pointers
                        write_tx.tx_data[1].p.addr = addr_ptr_p2_r;

                        write_tx.tx_end         = {1'b0, 1'b1, 1'b1};
                        write_tx.tx_endptr[0]   = { 2'b00, 4'(dword_r) };
                        write_tx.tx_endptr[1]   = { 2'b10, 4'(dword_r) };
                        next_rollover           = '0;
                        next_state              = IDLE;
                    end

                    default : begin // Send D | P | D and back to STWO
                        write_tx.tx_valid       = 1'b1;
                        write_tx.tx_start       = {1'b0, 1'b0, 1'b1};
                        write_tx.tx_startptr[0] = 2'b01;

                        // We can assign here and just control with valids
                        write_tx.tx_data[0] = full_data_slot;
                        write_tx.tx_data[1] = p_hdr;
                        write_tx.tx_data[2] = full_data_slot;

                        // Handle addresses and pointers
                        write_tx.tx_data[1].p.addr = addr_ptr_p2_r;

                        write_tx.tx_end         = {1'b0, 1'b1, 1'b1};
                        write_tx.tx_endptr[0]   = { 2'b00, 4'(dword_r) };
                        write_tx.tx_endptr[1]   = { 2'b10, 4'(dword_r) };
                        next_rollover           = '0;
                        next_state              = STWO;
                    end
                endcase
            end
        end

        SHDR : begin
            if (fifo_full == '0) begin
                // How much should the count increment
                this_count = NUM_SLOTS;

                write_tx.tx_valid = 1'b1;

                write_tx.tx_data[0] = p_hdr;
                write_tx.tx_data[1] = p_hdr;
                write_tx.tx_data[2] = p_hdr;

                write_tx.tx_data[0].p.addr = addr_ptr_r;
                write_tx.tx_data[1].p.addr = addr_ptr_p_r;
                write_tx.tx_data[2].p.addr = addr_ptr_p2_r;

                write_tx.tx_startptr    = {2'b10, 2'b01, 2'b00};
                write_tx.tx_endptr      = {{2'b10, 4'b0000},
                                           {2'b01, 4'b0000},
                                           {2'b00, 4'b0000}};

                case(NUM_SLOTS)
                    1 : begin
                        write_tx.tx_start       = { 1'b0,  1'b0,  1'b1};
                        write_tx.tx_end         = { 1'b0,  1'b0,  1'b1};

                        next_addr_ptr = addr_ptr_r + addr_inc_r;
                    end

                    2 : begin
                        write_tx.tx_start       = {1'b0, 1'b1, 1'b1};
                        write_tx.tx_end         = {1'b0, 1'b1, 1'b1};

                        next_addr_ptr = addr_ptr_r + addr_inc2_r;
                        addr_ptr_p    = addr_ptr_p_r + addr_inc2_r;
                    end

                    default : begin
                        write_tx.tx_start       = {1'b1, 1'b1, 1'b1};
                        write_tx.tx_end         = {1'b1, 1'b1, 1'b1};

                        next_addr_ptr = addr_ptr_r + addr_inc3_r;
                        addr_ptr_p    = addr_ptr_p_r + addr_inc3_r;
                        addr_ptr_p2   = addr_ptr_p2_r + addr_inc3_r;
                    end
                endcase

                case(1'b1)
                    // All will finish here
                    count_r == mwr_count_r_m1 : begin
                        write_tx.tx_start[1] = 1'b0;
                        write_tx.tx_end[1]   = 1'b0;

                        write_tx.tx_start[2] = 1'b0;
                        write_tx.tx_end[2]   = 1'b0;

                        next_state = IDLE;
                    end

                    // NUM_SLOTS >= 2 will finish here
                    (count_r == mwr_count_r_m2) && (NUM_SLOTS > 1): begin
                        write_tx.tx_start[2] = 1'b0;
                        write_tx.tx_end[2]   = 1'b0;

                        next_state = IDLE;
                    end

                    // NUM_SLOTS >= 3 will finish here
                    (count_r == mwr_count_r_m3) && (NUM_SLOTS > 2): begin
                        next_state = IDLE;
                    end

                    default : begin
                        next_state = SHDR;
                    end
                endcase
            end
        end

        default :
            next_state = IDLE;

    endcase
end

endmodule // BMD_AXIST_TX_WRITE
