
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
// File       : BMD_AXIST_TX.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_TX.sv
//--
//-- Description: Instantiates TX Read, Write, and Completion modules
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_TX
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
#(
    parameter int                       PATTERN_WIDTH       = 32
)(
    input  logic                        clk,
    input  logic                        rst_n,
    input  logic                        init_rst_i,
    // Memory Read
    input  logic                        mrd_start_i,
    input  logic                        mrd_inc_i,
    input  logic [31:0]                 mrd_addr_i,
    input  logic [31:0]                 mrd_up_addr_i,
    input  logic [10:0]                 mrd_len_i,
    input  logic [15:0]                 mrd_count_i,
    // Read Characteristics
    input  logic                        mrd_nosnoop_i,
    input  logic                        mrd_relaxed_order_i,
    input  logic                        mrd_64b_en_i,
    input  logic [2:0]                  mrd_tlp_tc_i,
    input  logic [11:0]                 mrd_tph_i,
    input  logic                        mrd_tph_vld_i,
    input  logic [23:0]                 mrd_ide_i,
    input  logic                        mrd_ide_vld_i,
    input  logic [23:0]                 mrd_pasid_i,
    input  logic                        mrd_pasid_vld_i,
    input  logic [1:0]                  mrd_ats_i,
    input  logic                        mrd_nw_i,
    input  logic                        mrd_poisoned_i,
    input  logic [7:0]                  mrd_steering_tag_i,
    input  logic [1:0]                  mrd_phint_i,
    input  logic                        mrd_tph_en_i,
    input  logic [4:0]                  mrd_type_i,
    input  logic                        mrd_fmt_i,
    input  logic [3:0]                  mrd_upper_be_i,
    input  logic [3:0]                  mrd_lower_be_i,
    input  logic [15:0]                 mrd_rrid_i,
    input  logic                        mrd_td_i,
    input  logic                        mrd_tbit_i,

    output tx_intf                      read_tx,

    // Memory Write
    input  logic                        mwr_start_i,
    input  logic                        mwr_inc_i,
    input  logic [9:0]                  mwr_tid_i,
    input  logic [31:0]                 mwr_addr_i,
    input  logic [31:0]                 mwr_up_addr_i,
    input  logic [31:0]                 mwr_data_i,
    input  logic [10:0]                 mwr_len_i,
    input  logic [15:0]                 mwr_count_i,
    output logic                        mwr_done_o,
    // Write Characteristics
    input  logic                        mwr_nosnoop_i,
    input  logic                        mwr_relaxed_order_i,
    input  logic                        mwr_64b_en_i,
    input  logic [2:0]                  mwr_tlp_tc_i,
    input  logic                        mwr_poisoned_i,
    input  logic [1:0]                  mwr_ats_i,
    input  logic                        mwr_nw_i,
    input  logic                        mwr_tph_en_i,
    input  logic [7:0]                  mwr_steering_tag_i,
    input  logic [1:0]                  mwr_phint_i,
    input  logic [11:0]                 mwr_tph_i,
    input  logic                        mwr_tph_vld_i,
    input  logic [23:0]                 mwr_ide_i,
    input  logic                        mwr_ide_vld_i,
    input  logic [23:0]                 mwr_pasid_i,
    input  logic                        mwr_pasid_vld_i,
    input  logic [4:0]                  mwr_type_i,
    input  logic                        mwr_fmt_i,
    input  logic [3:0]                  mwr_upper_be_i,
    input  logic [3:0]                  mwr_lower_be_i,
    input  logic [15:0]                 mwr_rrid_i,
    input  logic                        mwr_td_i,
    input  logic                        mwr_tbit_i,

    output tx_intf                      write_tx,

    // Completion signals
    output logic                        cpl_done,
    input  logic                        req_compl,
    input  logic                        req_compl_wd,
    input  logic                        req_compl_ur,
    input  logic [2:0]                  req_tc,
    input  logic [9:0]                  req_len,
    input  logic [13:0]                 req_lookup_id,
    // Memory data
    input  logic [31:0]                 mem_read_data,

    // Read tags
    input  logic [($clog2(NUM_SLOTS)>>1):0]          tag_valid,
    input  logic [($clog2(NUM_SLOTS)>>1):0] [9:0]    tag_released,

    output tx_intf                      cpl_tx,

    input  logic [1:0][NUM_SLOTS-1:0]   fifo_full,
    input  logic                        cfg_10b_tag_req_en,
    input  logic                        cfg_ext_tag_en,

    output logic [31:0]                 debug_cpl,
    output logic [31:0]                 debug_write,
    output logic [31:0]                 debug_read
);

logic                   write_enabled;

logic [NUM_SLOTS-1:0]   read_halt;
logic [15:0]            read_count, read_count_r;
logic [15:0]            write_count, write_count_r;
logic [15:0]            count_diff_r;
logic [10:0]            mrd_len_r;
logic [2:0]             mrd_ratio_r;

BMD_AXIST_TX_READ EP_TX_READ (
    .clk                    ( clk ),
    .rst_n                  ( rst_n ),
    .init_rst_i             ( init_rst_i ),
    // Memory Read
    .mrd_start_i            ( mrd_start_i ),
    .mrd_inc_i              ( mrd_inc_i ),
    .mrd_addr_i             ( mrd_addr_i ),
    .mrd_up_addr_i          ( mrd_up_addr_i ),
    .mrd_len_i              ( mrd_len_i ),
    .mrd_count_i            ( mrd_count_i ),
    // Read Characteristics
    .mrd_nosnoop_i          ( mrd_nosnoop_i ),
    .mrd_relaxed_order_i    ( mrd_relaxed_order_i ),
    .mrd_64b_en_i           ( mrd_64b_en_i ),
    .mrd_tlp_tc_i           ( mrd_tlp_tc_i ),
    .mrd_tph_i              ( mrd_tph_i ),
    .mrd_tph_vld_i          ( mrd_tph_vld_i ),
    .mrd_ide_i              ( mrd_ide_i ),
    .mrd_ide_vld_i          ( mrd_ide_vld_i ),
    .mrd_pasid_i            ( mrd_pasid_i ),
    .mrd_pasid_vld_i        ( mrd_pasid_vld_i ),
    .mrd_ats_i              ( mrd_ats_i ),
    .mrd_nw_i               ( mrd_nw_i ),
    .mrd_poisoned_i         ( mrd_poisoned_i ),
    .mrd_steering_tag_i     ( mrd_steering_tag_i ),
    .mrd_phint_i            ( mrd_phint_i ),
    .mrd_tph_en_i           ( mrd_tph_en_i ),
    .mrd_type_i             ( mrd_type_i ),
    .mrd_fmt_i              ( mrd_fmt_i ),
    .mrd_upper_be_i         ( mrd_upper_be_i ),
    .mrd_lower_be_i         ( mrd_lower_be_i ),
    .mrd_rrid_i             ( mrd_rrid_i ),
    .mrd_tbit_i             ( mrd_tbit_i ),
    .mrd_td_i               ( mrd_td_i ),

    .count_o                ( read_count ),

    // Read tags
    .tag_valid              ( tag_valid ),
    .tag_released           ( tag_released ),

    .read_tx                ( read_tx ),

    .fifo_full              ( fifo_full[1] | read_halt ),
    .cfg_10b_tag_req_en     ( cfg_10b_tag_req_en ),
    .cfg_ext_tag_en         ( cfg_ext_tag_en ),

    .debug                  ( debug_read )
);

BMD_AXIST_TX_WRITE #(
    .PATTERN_WIDTH          ( PATTERN_WIDTH )
) EP_TX_WRITE (
    .clk                    ( clk ),
    .rst_n                  ( rst_n ),
    .init_rst_i             ( init_rst_i ),
    // Memory Write
    .mwr_start_i            ( mwr_start_i ),
    .mwr_inc_i              ( mwr_inc_i ),
    .mwr_tid_i              ( mwr_tid_i ),
    .mwr_addr_i             ( mwr_addr_i ),
    .mwr_up_addr_i          ( mwr_up_addr_i ),
    .mwr_data_i             ( mwr_data_i ),
    .mwr_len_i              ( mwr_len_i ),
    .mwr_count_i            ( mwr_count_i ),
    .mwr_done_o             ( mwr_done_o ),
    // Write Characteristics
    .mwr_nosnoop_i          ( mwr_nosnoop_i ),
    .mwr_relaxed_order_i    ( mwr_relaxed_order_i ),
    .mwr_64b_en_i           ( mwr_64b_en_i ),
    .mwr_tlp_tc_i           ( mwr_tlp_tc_i ),
    .mwr_poisoned_i         ( mwr_poisoned_i ),
    .mwr_ats_i              ( mwr_ats_i ),
    .mwr_nw_i               ( mwr_nw_i ),
    .mwr_tph_en_i           ( mwr_tph_en_i ),
    .mwr_steering_tag_i     ( mwr_steering_tag_i ),
    .mwr_phint_i            ( mwr_phint_i ),
    .mwr_tph_i              ( mwr_tph_i ),
    .mwr_tph_vld_i          ( mwr_tph_vld_i ),
    .mwr_ide_i              ( mwr_ide_i ),
    .mwr_ide_vld_i          ( mwr_ide_vld_i ),
    .mwr_pasid_i            ( mwr_pasid_i ),
    .mwr_pasid_vld_i        ( mwr_pasid_vld_i ),
    .mwr_type_i             ( mwr_type_i ),
    .mwr_fmt_i              ( mwr_fmt_i ),
    .mwr_upper_be_i         ( mwr_upper_be_i ),
    .mwr_lower_be_i         ( mwr_lower_be_i ),
    .mwr_rrid_i             ( mwr_rrid_i ),
    .mwr_tbit_i             ( mwr_tbit_i ),
    .mwr_td_i               ( mwr_td_i ),

    .count_o                ( write_count ),

    .write_tx               ( write_tx ),

    .fifo_full              ( fifo_full[0] ),

    .debug                  ( debug_write )
);

BMD_AXIST_TX_CPL EP_TX_CPL (
    .clk                    ( clk ),
    .rst_n                  ( rst_n ),
    // Completion signals
    .cpl_done               ( cpl_done ),
    .req_compl              ( req_compl ),
    .req_compl_wd           ( req_compl_wd ),
    .req_compl_ur           ( req_compl_ur ),
    .req_tc                 ( req_tc ),
    .req_len                ( req_len ),
    .req_lookup_id          ( req_lookup_id ),
    // Data from memory
    .rd_data                ( mem_read_data ),
    .cpl_tx                 ( cpl_tx ),

    .app_hdr_log            (),
    .app_hdr_flitmode       (),
    .app_hdr_log_size       (),
    .app_err_bus            (),
    .app_err_advisory       (),
    .app_poisoned_tlp_type  (),
    .app_err_func_num       (),

    .debug                  ( debug_cpl )
);

// Read Rate Limiting Logic (to maximize performance)
always @(posedge clk) begin
    if (!rst_n || init_rst_i) begin
        mrd_len_r <= '0;
        mrd_ratio_r <= '0;

        read_count_r <= '0;
        write_count_r <= '0;
        write_enabled <= '0;
    end else begin
        if (mrd_start_i) mrd_len_r <= mrd_len_i;
        if (mwr_start_i) write_enabled <= 1'b1;

        if (mrd_len_r > 3072) begin             // Split 4 times
            mrd_ratio_r <= 4;
        end else if (mrd_len_r > 2048) begin    // Split 3 times
            mrd_ratio_r <= 3;
        end else if (mrd_len_r > 1024) begin    // Split 2 times
            mrd_ratio_r <= 2;
        end else begin // other 1:1
            mrd_ratio_r <= 1;
        end

        read_count_r  <= read_count * mrd_ratio_r;
        write_count_r <= write_count;

        if (read_count_r > write_count_r) begin
            count_diff_r <= read_count_r - write_count_r;
        end else begin
            count_diff_r <= 0;
        end
    end
end

always_comb begin
    read_halt = '0;
    if (count_diff_r > 18 && (write_enabled && !mwr_done_o)) read_halt = '1;
end

endmodule // BMD_AXIST_TX
