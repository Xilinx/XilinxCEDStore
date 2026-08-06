
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
// File       : BMD_AXIST_EP_MEM_ACCESS.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_EP_MEM_ACCESS.sv
//--
//-- Description: Endpoint Memory Access Unit. This module provides access functions
//--              to the Endpoint memory aperture.
//--
//--              Read Access: Module returns data for the specifed address and
//--              byte enables selected.
//--
//--              Write Access: Module accepts data, byte enables and updates
//--              data when write enable is asserted. Modules signals write busy
//--              when data write is in progress.
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_EP_MEM_ACCESS
  import pcie_intf_pkg::*;
(
    input  logic            clk,
    input  logic            rst_n,

    // PIO Signals
    input  logic [6:0]      addr_i,
    input  logic [3:0]      rd_be_i,
    output logic [31:0]     rd_data_o,
    input  logic [3:0]      wr_be_i,
    input  logic [31:0]     wr_data_i,
    input  logic            wr_en_i,
    output logic            wr_busy_o,

    // DCSR
    output logic            init_rst_o,

    // DDCSR
    input  logic            cpld_data_err_i,
    input  logic            mrd_done_i,
    output logic            mrd_int_dis_o,
    output logic            mrd_nosnoop_o,
    output logic            mrd_relaxed_order_o,
    output logic            mrd_start_o,
    input  logic            mwr_done_i,
    output logic            mwr_int_dis_o,
    output logic            mwr_nosnoop_o,
    output logic            mwr_relaxed_order_o,
    output logic            mwr_start_o,
    input  logic [2:0]      cfg_max_payload_size,
    input  logic [2:0]      cfg_max_rd_req_size,

    output logic [1:0]      mwr_int_select_o,
    output logic [1:0]      mrd_int_select_o,

    // WDMATLPA
    output logic            mwr_inc_o,
    output logic [9:0]      mwr_tid_o,
    output logic [31:0]     mwr_addr_o,

    // WDMATLPS
    output logic [7:0]      mwr_steering_tag_o,
    output logic            mwr_tph_en_o,
    output logic [1:0]      mwr_phint_o,
    output logic            mwr_64b_en_o,
    output logic [2:0]      mwr_tlp_tc_o,
    output logic            mwr_poisoned_o,
    output logic [1:0]      mwr_ats_o,
    output logic            mwr_nw_o,
    output logic [10:0]     mwr_len_o,
    output logic            mwr_td_o,
    output logic            mwr_tbit_o,

    // WDMATLPUA
    output logic [31:0]     mwr_up_addr_o,

    // WDMATLPC
    output logic [15:0]     mwr_count_o,

    // WDMATLPP
    output logic [31:0]     mwr_data_o,

    // RDMATLPP
    output logic [31:0]     cpld_data_o,

    // RDMATLPA
    output logic            mrd_inc_o,
    output logic [31:0]     mrd_addr_o,

    // RDMATLPS
    output logic [7:0]      mrd_steering_tag_o,
    output logic            mrd_tph_en_o,
    output logic [1:0]      mrd_phint_o,
    output logic            mrd_64b_en_o,
    output logic [2:0]      mrd_tlp_tc_o,
    output logic            mrd_poisoned_o,
    output logic [1:0]      mrd_ats_o,
    output logic            mrd_nw_o,
    output logic [10:0]     mrd_len_o,
    output logic            mrd_td_o,
    output logic            mrd_tbit_o,

    // RDMATLPUA
    output logic [31:0]     mrd_up_addr_o,

    // RDMATLPC
    output logic [15:0]     mrd_count_o,

    // DMATLPTYPE
    output logic [4:0]      mrd_type_o,
    output logic            mrd_fmt_o,
    output logic [4:0]      mwr_type_o,
    output logic            mwr_fmt_o,

    // DMATPH
    output logic            mwr_tph_vld_o,
    output logic [11:0]     mwr_tph_o,
    output logic            mrd_tph_vld_o,
    output logic [11:0]     mrd_tph_o,

    // WDMAIDE
    output logic [23:0]     mwr_ide_o,
    output logic            mwr_ide_vld_o,

    // RDMAIDE
    output logic [23:0]     mrd_ide_o,
    output logic            mrd_ide_vld_o,

    // WDMAPASID
    output logic [23:0]     mwr_pasid_o,
    output logic            mwr_pasid_vld_o,

    // RDMAPASID
    output logic [23:0]     mrd_pasid_o,
    output logic            mrd_pasid_vld_o,

    // DMAEXT
    output logic [3:0]      mrd_upper_be_o,
    output logic [3:0]      mrd_lower_be_o,
    output logic [3:0]      mwr_upper_be_o,
    output logic [3:0]      mwr_lower_be_o,

    // DMAEXT2
    output logic [15:0]     mrd_rrid_o,
    output logic [15:0]     mwr_rrid_o,

    // RDMASTAT1
    input  logic [15:0]     cpl_ur_found_i,
    input  logic [9:0]      cpl_ur_tag_i,

    // RDMASTAT2
    input  logic [31:0]     cpld_found_i,

    // RDMASTAT3
    input  logic [31:0]     cpld_data_size_i,

    // DMAMSIX
    output logic [10:0]     mwr_msix_vec_o,
    output logic [10:0]     mrd_msix_vec_o,
    output logic [1:0]      mwr_intx_vec_o,
    output logic [1:0]      mrd_intx_vec_o,

    input  logic            cfg_atomic_req_en,
    input  logic            cfg_pf_pasid_en,
    output logic [31:0]     debug
);

localparam logic [1:0] BMD_AXIST_MEM_ACCESS_WR_RST   = 2'b00;
localparam logic [1:0] BMD_AXIST_MEM_ACCESS_WR_READ  = 2'b10;

logic [31:0]        mem_rd_data;
logic               mem_write_en;
logic [31:0]        pre_wr_data;    // pre be write data
logic [31:0]        mem_wr_data;    // post be write data
logic [1:0]         wr_mem_state, next_wr_mem_state;

assign debug = {
    1'b0,
    rd_be_i,
    wr_be_i,
    wr_mem_state,
    mwr_done_i,
    mrd_done_i,
    cpl_ur_tag_i,
    wr_busy_o,
    wr_en_i,
    addr_i
};

always @(posedge clk) begin
    if (!rst_n) begin
        wr_mem_state <= BMD_AXIST_MEM_ACCESS_WR_RST;
    end else begin
        wr_mem_state <= next_wr_mem_state;
    end
end

always_comb begin
    next_wr_mem_state = wr_mem_state;
    mem_write_en = 1'b0;
    mem_wr_data = '0;

    case (wr_mem_state)
        BMD_AXIST_MEM_ACCESS_WR_RST : begin
            if (wr_en_i) begin
                if (wr_be_i != '1) // BE so need to read first
                    next_wr_mem_state = BMD_AXIST_MEM_ACCESS_WR_READ;
                else begin
                    next_wr_mem_state = BMD_AXIST_MEM_ACCESS_WR_RST;
                    mem_wr_data = wr_data_i;
                    mem_write_en = 1'b1;
                end
            end
        end

        BMD_AXIST_MEM_ACCESS_WR_READ : begin
            pre_wr_data = mem_rd_data;
            mem_wr_data = {{wr_be_i[3] ? wr_data_i[31:24]  : pre_wr_data[31:24]},
                           {wr_be_i[2] ? wr_data_i[23:16]  : pre_wr_data[23:16]},
                           {wr_be_i[1] ? wr_data_i[15:8]   : pre_wr_data[15:8]},
                           {wr_be_i[0] ? wr_data_i[7:0]    : pre_wr_data[7:0]}};
            mem_write_en = 1'b1;
            next_wr_mem_state = BMD_AXIST_MEM_ACCESS_WR_RST;
        end

        default : begin
            next_wr_mem_state = BMD_AXIST_MEM_ACCESS_WR_RST;
        end
    endcase
end

//
//  Write controller busy
//
assign wr_busy_o = wr_mem_state != BMD_AXIST_MEM_ACCESS_WR_RST;

//
// Handle Read byte enables
//
assign rd_data_o = {{rd_be_i[3] ? mem_rd_data[31:24] : 8'h0},
                    {rd_be_i[2] ? mem_rd_data[23:16] : 8'h0},
                    {rd_be_i[1] ? mem_rd_data[15:8] : 8'h0},
                    {rd_be_i[0] ? mem_rd_data[7:0] : 8'h0}};

BMD_AXIST_EP_MEM EP_MEM (
    .clk                        ( clk ),
    .rst_n                      ( rst_n ),

    // PIO signals
    .a_i                        ( addr_i[6:0] ),
    .wr_en_i                    ( mem_write_en ),
    .rd_d_o                     ( mem_rd_data ),
    .wr_d_i                     ( mem_wr_data ),

    // DCSR
    .init_rst_o                 ( init_rst_o ),

    // DDCSR
    .cpld_data_err_i            ( cpld_data_err_i ),
    .mrd_done_i                 ( mrd_done_i ),
    .mrd_int_dis_o              ( mrd_int_dis_o ),
    .mrd_nosnoop_o              ( mrd_nosnoop_o ),
    .mrd_relaxed_order_o        ( mrd_relaxed_order_o ),
    .mrd_start_o                ( mrd_start_o ),
    .mwr_done_i                 ( mwr_done_i ),
    .mwr_int_dis_o              ( mwr_int_dis_o ),
    .mwr_nosnoop_o              ( mwr_nosnoop_o ),
    .mwr_relaxed_order_o        ( mwr_relaxed_order_o ),
    .mwr_start_o                ( mwr_start_o ),

    .mwr_int_select_o           ( mwr_int_select_o ),
    .mrd_int_select_o           ( mrd_int_select_o ),

    // WDMATLPA
    .mwr_inc_o                  ( mwr_inc_o ),
    .mwr_tid_o                  ( mwr_tid_o ),
    .mwr_addr_o                 ( mwr_addr_o ),

    // WDMATLPS
    .mwr_steering_tag_o         ( mwr_steering_tag_o ),
    .mwr_tph_en_o               ( mwr_tph_en_o ),
    .mwr_phint_o                ( mwr_phint_o ),
    .mwr_64b_en_o               ( mwr_64b_en_o ),
    .mwr_tlp_tc_o               ( mwr_tlp_tc_o ),
    .mwr_poisoned_o             ( mwr_poisoned_o ),
    .mwr_ats_o                  ( mwr_ats_o ),
    .mwr_nw_o                   ( mwr_nw_o ),
    .mwr_len_o                  ( mwr_len_o ),
    .mwr_td_o                   ( mwr_td_o ),
    .mwr_tbit_o                 ( mwr_tbit_o ),

    // WDMATLPUA
    .mwr_up_addr_o              ( mwr_up_addr_o ),

    // WDMATLPC
    .mwr_count_o                ( mwr_count_o ),

    // WDMATLPP
    .mwr_data_o                 ( mwr_data_o ),

    // RDMATLPP
    .cpld_data_o                ( cpld_data_o ),

    // RDMATLPA
    .mrd_inc_o                  ( mrd_inc_o ),
    .mrd_addr_o                 ( mrd_addr_o ),

    // RDMATLPS
    .mrd_steering_tag_o         ( mrd_steering_tag_o ),
    .mrd_tph_en_o               ( mrd_tph_en_o ),
    .mrd_phint_o                ( mrd_phint_o ),
    .mrd_64b_en_o               ( mrd_64b_en_o ),
    .mrd_tlp_tc_o               ( mrd_tlp_tc_o ),
    .mrd_poisoned_o             ( mrd_poisoned_o ),
    .mrd_ats_o                  ( mrd_ats_o ),
    .mrd_nw_o                   ( mrd_nw_o ),
    .mrd_len_o                  ( mrd_len_o ),
    .mrd_td_o                   ( mrd_td_o ),
    .mrd_tbit_o                 ( mrd_tbit_o ),

    // RDMATLPUA
    .mrd_up_addr_o              ( mrd_up_addr_o ),

    // RDMATLPC
    .mrd_count_o                ( mrd_count_o ),

    // DMATLPTYPE
    .mrd_type_o                 ( mrd_type_o ),
    .mrd_fmt_o                  ( mrd_fmt_o ),
    .mwr_type_o                 ( mwr_type_o ),
    .mwr_fmt_o                  ( mwr_fmt_o ),

    // DMATPH
    .mwr_tph_vld_o              ( mwr_tph_vld_o ),
    .mwr_tph_o                  ( mwr_tph_o ),
    .mrd_tph_vld_o              ( mrd_tph_vld_o ),
    .mrd_tph_o                  ( mrd_tph_o ),

    // WDMAIDE
    .mwr_ide_o                  ( mwr_ide_o ),
    .mwr_ide_vld_o              ( mwr_ide_vld_o ),

    // RDMAIDE
    .mrd_ide_o                  ( mrd_ide_o ),
    .mrd_ide_vld_o              ( mrd_ide_vld_o ),

    // WDMAPASID
    .mwr_pasid_o                ( mwr_pasid_o ),
    .mwr_pasid_vld_o            ( mwr_pasid_vld_o ),

    // RDMAPASID
    .mrd_pasid_o                ( mrd_pasid_o ),
    .mrd_pasid_vld_o            ( mrd_pasid_vld_o ),

    // DMAEXT
    .mrd_upper_be_o             ( mrd_upper_be_o ),
    .mrd_lower_be_o             ( mrd_lower_be_o ),
    .mwr_upper_be_o             ( mwr_upper_be_o ),
    .mwr_lower_be_o             ( mwr_lower_be_o ),

    // DMAEXT2
    .mrd_rrid_o                 ( mrd_rrid_o ),
    .mwr_rrid_o                 ( mwr_rrid_o ),

    // RDMASTAT1
    .cpl_ur_found_i             ( cpl_ur_found_i ),
    .cpl_ur_tag_i               ( cpl_ur_tag_i ),

    // RDMASTAT2
    .cpld_found_i               ( cpld_found_i ),

    // RDMASTAT3
    .cpld_data_size_i           ( cpld_data_size_i ),

    // DLTRSSTAT
    .cfg_max_payload_size       ( cfg_max_payload_size ),
    .cfg_max_rd_req_size        ( cfg_max_rd_req_size ),

    // DMAMSIX
    .mwr_msix_vec_o             ( mwr_msix_vec_o ),
    .mrd_msix_vec_o             ( mrd_msix_vec_o ),
    .mwr_intx_vec_o             ( mwr_intx_vec_o ),
    .mrd_intx_vec_o             ( mrd_intx_vec_o ),

    .cfg_atomic_req_en          ( cfg_atomic_req_en ),
    .cfg_pf_pasid_en            ( cfg_pf_pasid_en )
);
endmodule // BMD_AXIST_EP_MEM_ACCESS
