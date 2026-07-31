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
// File       : pcie_app_versal_pl_st_vivado.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: pcie_app_versal_pl_st_vivado.sv
//--
//-- Description: Top level module for user logic
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module pcie_app_versal_bmd
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
  import cpm6_v1_0_pkg::*;
#(
    parameter int WIDE_MODE_EN          = 1'b0
) (
    input logic                                         clk,
    input logic                                         rst_n,

    // pcie6_pstbr_pl_rx_if.s
    input  logic                                        rx_valid,
    input  logic [2654:0]                               rx_data,
    input  logic [44:0]                                 rx_parity,
    input  logic [2:0]                                  rx_start,
    input  logic [1:0]                                  rx_start0ptr,
    input  logic [1:0]                                  rx_start1ptr,
    input  logic [1:0]                                  rx_start2ptr,
    input  logic [1:0]                                  rx_start0type,
    input  logic [1:0]                                  rx_start1type,
    input  logic [1:0]                                  rx_start2type,
    input  logic [2:0]                                  rx_start0npinfo,
    input  logic [2:0]                                  rx_start1npinfo,
    input  logic [2:0]                                  rx_start2npinfo,
    input  logic [2:0]                                  rx_end,
    input  logic [5:0]                                  rx_end0ptr,
    input  logic [5:0]                                  rx_end1ptr,
    input  logic [5:0]                                  rx_end2ptr,
    input  logic [8:0]                                  rx_end_err,

    output logic                                        rx_credit_valid,
    output logic [2:0]                                  rx_credit,
    input  logic                                        rx_credit_active,

    // pcie6_pstbr_pl_tx_if.m
    output logic                                        tx_valid,
    output logic [2555:0]                               tx_data,
    output logic [43:0]                                 tx_parity,
    output logic [2:0]                                  tx_start,
    output logic [1:0]                                  tx_start0ptr,
    output logic [1:0]                                  tx_start1ptr,
    output logic [1:0]                                  tx_start2ptr,
    output logic [1:0]                                  tx_start0type,
    output logic [1:0]                                  tx_start1type,
    output logic [1:0]                                  tx_start2type,
    output logic [2:0]                                  tx_start0npinfo,
    output logic [2:0]                                  tx_start1npinfo,
    output logic [2:0]                                  tx_start2npinfo,
    output logic [2:0]                                  tx_end,
    output logic [5:0]                                  tx_end0ptr,
    output logic [5:0]                                  tx_end1ptr,
    output logic [5:0]                                  tx_end2ptr,
    output logic [8:0]                                  tx_end_err,

    input  logic                                        tx_credit_valid,
    input  logic [2:0]                                  tx_credit,
    output logic                                        tx_credit_active,

    input logic [11:0]                                  xadm_ph_cdts,
    input logic [15:0]                                  xadm_pd_cdts,
    input logic [11:0]                                  xadm_nph_cdts,
    input logic [15:0]                                  xadm_npd_cdts,
    input logic [11:0]                                  xadm_cplh_cdts,
    input logic [15:0]                                  xadm_cpld_cdts,

    // pcie6_cfg_sts_pl_if.s
    input logic [15:0]                                  pf_cfg_info,
    input logic                                         pf_cfg_status_vld,
    input logic                                         pf_cfg_status_sos,
    input logic [2:0]                                   pf_cfg_status_num,
    input logic [15:0]                                  vf_cfg_info,
    input logic                                         vf_cfg_status_vld,
    input logic                                         vf_cfg_status_sos,
    input logic [7:0]                                   vf_cfg_status_num,

    // pcie6_misc_sts_pl_if.s
    input logic [5:0]                                   cfg_neg_link_width,
    input logic                                         rdlh_link_up,
    input logic                                         smlh_link_up,
    input logic [5:0]                                   smlh_ltssm_state,

    // pcie6_msix_pl_if.m
    output logic [2:0]                                  pl_msi_func_num,
    output logic [7:0]                                  pl_msi_vfunc_num,
    output logic                                        pl_msi_vfunc_active,
    output logic [2:0]                                  pl_msi_tc,
    output logic [4:0]                                  pl_msi_vector,
    output logic [31:0]                                 pl_msi_addr_lo,
    output logic [31:0]                                 pl_msi_addr_hi,
    output logic [31:0]                                 pl_msi_data,
    output logic                                        pl_issue_msi_req,
    output logic                                        pl_issue_msix_req,
    output logic                                        select_pl,
    input  logic                                        pl_done,

    input  logic                                        pl_msix_user_error,
    output logic [2:0]                                  pl_msix_user_func_num,
    output logic [7:0]                                  pl_msix_user_vfunc_num,
    output logic                                        pl_msix_user_vfunc_active,
    output logic                                        pl_msix_user_req,
    output logic [10:0]                                 pl_msix_user_vector_num,
    input  logic                                        pl_msix_user_grant,
    output logic [1:0]                                  pl_msix_user_operation,

    // PME
    output logic                                        app_ready_entr_l23,
    output logic                                        pl_ready,

    // Debug Signals
    output logic [31:0]                                 debug_bmd,
    input  logic [4:0]                                  debug_bmd_sel,

    /* ELBI slave interface connections */
    output logic                                        ext_lbc_override_en,
    output logic [7:0]                                  ext_lbc_ack,
    output logic [63:0]                                 ext_lbc_din,
    input  logic [31:0]                                 lbc_ext_addr,
    input  logic [63:0]                                 lbc_ext_dout,
    input  logic [7:0]                                  lbc_ext_valid,
    input  logic [7:0]                                  lbc_ext_cs,
    input  logic [7:0]                                  lbc_ext_wr,
    input  logic [7:0]                                  lbc_ext_rd,
    input  logic                                        lbc_ext_dbi_access,
    input  logic                                        lbc_ext_cxl_mbar0_access,
    input  logic                                        lbc_ext_rom_access,
    input  logic                                        lbc_ext_io_access,
    input  logic [2:0]                                  lbc_ext_bar_num,
    input  logic [7:0]                                  lbc_ext_vfunc_num,
    input  logic                                        lbc_ext_vfunc_active
);

///////////////////////////////////////////////////////////////////////
//                          Register from Core
///////////////////////////////////////////////////////////////////////
logic                           rst_n_r;

    // pcie6_pstbr_pl_rx_if.s
logic                           rx_valid_r;
logic [2654:0]                  rx_data_r;
logic [44:0]                    rx_parity_r;
logic [2:0]                     rx_start_r;
logic [1:0]                     rx_start0ptr_r;
logic [1:0]                     rx_start1ptr_r;
logic [1:0]                     rx_start2ptr_r;
logic [1:0]                     rx_start0type_r;
logic [1:0]                     rx_start1type_r;
logic [1:0]                     rx_start2type_r;
logic [2:0]                     rx_start0npinfo_r;
logic [2:0]                     rx_start1npinfo_r;
logic [2:0]                     rx_start2npinfo_r;
logic [2:0]                     rx_end_r;
logic [5:0]                     rx_end0ptr_r;
logic [5:0]                     rx_end1ptr_r;
logic [5:0]                     rx_end2ptr_r;
logic [8:0]                     rx_end_err_r;

logic                           next_rx_credit_valid;
logic [2:0]                     next_rx_credit;
logic                           rx_credit_active_r;

    // pcie6_pstbr_pl_tx_if.m
logic                           next_tx_valid;
logic [2555:0]                  next_tx_data;
logic [43:0]                    next_tx_parity;
logic [2:0]                     next_tx_start;
logic [1:0]                     next_tx_start0ptr;
logic [1:0]                     next_tx_start1ptr;
logic [1:0]                     next_tx_start2ptr;
logic [1:0]                     next_tx_start0type;
logic [1:0]                     next_tx_start1type;
logic [1:0]                     next_tx_start2type;
logic [2:0]                     next_tx_start0npinfo;
logic [2:0]                     next_tx_start1npinfo;
logic [2:0]                     next_tx_start2npinfo;
logic [2:0]                     next_tx_end;
logic [5:0]                     next_tx_end0ptr;
logic [5:0]                     next_tx_end1ptr;
logic [5:0]                     next_tx_end2ptr;
logic [8:0]                     next_tx_end_err;

logic                           tx_credit_valid_r;
logic [2:0]                     tx_credit_r;
logic                           next_tx_credit_active;

logic [11:0]                    xadm_ph_cdts_r;
logic [15:0]                    xadm_pd_cdts_r;
logic [11:0]                    xadm_nph_cdts_r;
logic [15:0]                    xadm_npd_cdts_r;
logic [11:0]                    xadm_cplh_cdts_r;
logic [15:0]                    xadm_cpld_cdts_r;

    // pcie6_cfg_sts_pl_if.s
logic [15:0]                    pf_cfg_info_r;
logic                           pf_cfg_status_vld_r;
logic                           pf_cfg_status_sos_r;
logic [2:0]                     pf_cfg_status_num_r;
logic [15:0]                    vf_cfg_info_r;
logic                           vf_cfg_status_vld_r;
logic                           vf_cfg_status_sos_r;
logic [7:0]                     vf_cfg_status_num_r;

    // pcie6_misc_sts_pl_if.s
logic [5:0]                     cfg_neg_link_width_r;
logic                           rdlh_link_up_r;
logic                           smlh_link_up_r;
logic [5:0]                     smlh_ltssm_state_r;

    // pcie6_msix_pl_if.m
logic [2:0]                     next_pl_msi_func_num;
logic [7:0]                     next_pl_msi_vfunc_num;
logic                           next_pl_msi_vfunc_active;
logic [2:0]                     next_pl_msi_tc;
logic [4:0]                     next_pl_msi_vector;
logic [31:0]                    next_pl_msi_addr_lo;
logic [31:0]                    next_pl_msi_addr_hi;
logic [31:0]                    next_pl_msi_data;
logic                           next_pl_issue_msi_req;
logic                           next_pl_issue_msix_req;
logic                           next_select_pl;
logic                           pl_done_r;

logic                           pl_msix_user_error_r;
logic [2:0]                     next_pl_msix_user_func_num;
logic [7:0]                     next_pl_msix_user_vfunc_num;
logic                           next_pl_msix_user_vfunc_active;
logic                           next_pl_msix_user_req;
logic [10:0]                    next_pl_msix_user_vector_num;
logic                           pl_msix_user_grant_r;
logic [1:0]                     next_pl_msix_user_operation;

    // PME
logic                           next_app_ready_entr_l23;
logic                           next_pl_ready;

    // Debug Signals
logic [31:0]                    next_debug_bmd;
logic [4:0]                     debug_bmd_sel_r;

    /* ELBI slave interface connections */
logic                           next_ext_lbc_override_en;
logic [7:0]                     next_ext_lbc_ack;
logic [63:0]                    next_ext_lbc_din;
logic [31:0]                    lbc_ext_addr_r;
logic [63:0]                    lbc_ext_dout_r;
logic [7:0]                     lbc_ext_valid_r;
logic [7:0]                     lbc_ext_cs_r;
logic [7:0]                     lbc_ext_wr_r;
logic [7:0]                     lbc_ext_rd_r;
logic                           lbc_ext_dbi_access_r;
logic                           lbc_ext_cxl_mbar0_access_r;
logic                           lbc_ext_rom_access_r;
logic                           lbc_ext_io_access_r;
logic [2:0]                     lbc_ext_bar_num_r;
logic [7:0]                     lbc_ext_vfunc_num_r;
logic                           lbc_ext_vfunc_active_r;

/////////////////////////////
// Inputs
always_ff @(posedge clk) begin
    rst_n_r                     <= rst_n;

    rx_valid_r                  <= rx_valid;
    rx_data_r                   <= rx_data;
    rx_parity_r                 <= rx_parity;
    rx_start_r                  <= rx_start;
    rx_start0ptr_r              <= rx_start0ptr;
    rx_start1ptr_r              <= rx_start1ptr;
    rx_start2ptr_r              <= rx_start2ptr;
    rx_start0type_r             <= rx_start0type;
    rx_start1type_r             <= rx_start1type;
    rx_start2type_r             <= rx_start2type;
    rx_start0npinfo_r           <= rx_start0npinfo;
    rx_start1npinfo_r           <= rx_start1npinfo;
    rx_start2npinfo_r           <= rx_start2npinfo;
    rx_end_r                    <= rx_end;
    rx_end0ptr_r                <= rx_end0ptr;
    rx_end1ptr_r                <= rx_end1ptr;
    rx_end2ptr_r                <= rx_end2ptr;
    rx_end_err_r                <= rx_end_err;

    rx_credit_active_r          <= rx_credit_active;

    tx_credit_valid_r           <= tx_credit_valid;
    tx_credit_r                 <= tx_credit;

    xadm_ph_cdts_r              <= xadm_ph_cdts;
    xadm_pd_cdts_r              <= xadm_pd_cdts;
    xadm_nph_cdts_r             <= xadm_nph_cdts;
    xadm_npd_cdts_r             <= xadm_npd_cdts;
    xadm_cplh_cdts_r            <= xadm_cplh_cdts;
    xadm_cpld_cdts_r            <= xadm_cpld_cdts;

    pf_cfg_info_r               <= pf_cfg_info;
    pf_cfg_status_vld_r         <= pf_cfg_status_vld;
    pf_cfg_status_sos_r         <= pf_cfg_status_sos;
    pf_cfg_status_num_r         <= pf_cfg_status_num;
    vf_cfg_info_r               <= vf_cfg_info;
    vf_cfg_status_vld_r         <= vf_cfg_status_vld;
    vf_cfg_status_sos_r         <= vf_cfg_status_sos;
    vf_cfg_status_num_r         <= vf_cfg_status_num;

    cfg_neg_link_width_r        <= cfg_neg_link_width;
    rdlh_link_up_r              <= rdlh_link_up;
    smlh_link_up_r              <= smlh_link_up;
    smlh_ltssm_state_r          <= smlh_ltssm_state;

    pl_done_r                   <= pl_done;

    pl_msix_user_error_r        <= pl_msix_user_error;
    pl_msix_user_grant_r        <= pl_msix_user_grant;

    lbc_ext_addr_r              <= lbc_ext_addr;
    lbc_ext_dout_r              <= lbc_ext_dout;
    lbc_ext_valid_r             <= lbc_ext_valid;
    lbc_ext_cs_r                <= lbc_ext_cs;
    lbc_ext_wr_r                <= lbc_ext_wr;
    lbc_ext_rd_r                <= lbc_ext_rd;
    lbc_ext_dbi_access_r        <= lbc_ext_dbi_access;
    lbc_ext_cxl_mbar0_access_r  <= lbc_ext_cxl_mbar0_access;
    lbc_ext_rom_access_r        <= lbc_ext_rom_access;
    lbc_ext_io_access_r         <= lbc_ext_io_access;
    lbc_ext_bar_num_r           <= lbc_ext_bar_num;
    lbc_ext_vfunc_num_r         <= lbc_ext_vfunc_num;
    lbc_ext_vfunc_active_r      <= lbc_ext_vfunc_active;

    debug_bmd_sel_r             <= debug_bmd_sel;
end

/////////////////////////////
// Outputs
always_ff @(posedge clk) begin
    rx_credit_valid             <= next_rx_credit_valid;
    rx_credit                   <= next_rx_credit;

    tx_valid                    <= next_tx_valid;
    tx_data                     <= next_tx_data;
    tx_parity                   <= next_tx_parity;
    tx_start                    <= next_tx_start;
    tx_start0ptr                <= next_tx_start0ptr;
    tx_start1ptr                <= next_tx_start1ptr;
    tx_start2ptr                <= next_tx_start2ptr;
    tx_start0type               <= next_tx_start0type;
    tx_start1type               <= next_tx_start1type;
    tx_start2type               <= next_tx_start2type;
    tx_start0npinfo             <= next_tx_start0npinfo;
    tx_start1npinfo             <= next_tx_start1npinfo;
    tx_start2npinfo             <= next_tx_start2npinfo;
    tx_end                      <= next_tx_end;
    tx_end0ptr                  <= next_tx_end0ptr;
    tx_end1ptr                  <= next_tx_end1ptr;
    tx_end2ptr                  <= next_tx_end2ptr;
    tx_end_err                  <= next_tx_end_err;

    tx_credit_active            <= next_tx_credit_active;

    pl_msi_func_num             <= next_pl_msi_func_num;
    pl_msi_vfunc_num            <= next_pl_msi_vfunc_num;
    pl_msi_vfunc_active         <= next_pl_msi_vfunc_active;
    pl_msi_tc                   <= next_pl_msi_tc;
    pl_msi_vector               <= next_pl_msi_vector;
    pl_msi_addr_lo              <= next_pl_msi_addr_lo;
    pl_msi_addr_hi              <= next_pl_msi_addr_hi;
    pl_msi_data                 <= next_pl_msi_data;
    pl_issue_msi_req            <= next_pl_issue_msi_req;
    pl_issue_msix_req           <= next_pl_issue_msix_req;
    select_pl                   <= next_select_pl;

    pl_msix_user_func_num       <= next_pl_msix_user_func_num;
    pl_msix_user_vfunc_num      <= next_pl_msix_user_vfunc_num;
    pl_msix_user_vfunc_active   <= next_pl_msix_user_vfunc_active;
    pl_msix_user_req            <= next_pl_msix_user_req;
    pl_msix_user_vector_num     <= next_pl_msix_user_vector_num;
    pl_msix_user_operation      <= next_pl_msix_user_operation;

    app_ready_entr_l23          <= next_app_ready_entr_l23;
    pl_ready                    <= next_pl_ready;

    debug_bmd                   <= next_debug_bmd;

    ext_lbc_override_en         <= next_ext_lbc_override_en;
    ext_lbc_ack                 <= next_ext_lbc_ack;
    ext_lbc_din                 <= next_ext_lbc_din;
end

///////////////////////////////////////////////////////////////////////
//                          Interface Creation
///////////////////////////////////////////////////////////////////////
tx_intf     tx;
rx_intf     rx;

pf_cfg_intf     pf_cfg;
vf_cfg_intf     vf_cfg;

tx_credit_if    tx_crd();
rx_credit_if    rx_crd();

// User interface
msix_user_intf  msix();
// Native interface
pcie6_msix_pl_if msi();

axil_intf_defs_cpm6 user_app_axil_if();

axil_intf_defs_cpm6 user_app_axil_if_vsec();
axil_intf_defs_cpm6 user_app_axil_if_tph();

assign next_pl_ready = rst_n_r && smlh_link_up_r;

///////////////////////////////////////////////////////////////////////
//                          MSIX Interface
///////////////////////////////////////////////////////////////////////
assign msix.user_error                  = pl_msix_user_error_r;
assign msix.user_grant                  = pl_msix_user_grant_r;
assign next_pl_msix_user_func_num       = msix.user_func_num;
assign next_pl_msix_user_vfunc_num      = msix.user_vfunc_num;
assign next_pl_msix_user_vfunc_active   = msix.user_vfunc_active;
assign next_pl_msix_user_req            = msix.user_req;
assign next_pl_msix_user_vector_num     = msix.user_vector_num;
assign next_pl_msix_user_operation      = msix.user_operation;

///////////////////////////////////////////////////////////////////////
//                         MSI Interfaces
///////////////////////////////////////////////////////////////////////
assign next_pl_msi_func_num     = msi.pl_msi_func_num;
assign next_pl_msi_vfunc_num    = msi.pl_msi_vfunc_num;
assign next_pl_msi_vfunc_active = msi.pl_msi_vfunc_active;
assign next_pl_msi_tc           = msi.pl_msi_tc;
assign next_pl_msi_vector       = msi.pl_msi_vector;
assign next_pl_msi_addr_lo      = '0;
assign next_pl_msi_addr_hi      = '0;
assign next_pl_msi_data         = '0;
assign next_pl_issue_msi_req    = msi.pl_issue_msi_req;
assign next_pl_issue_msix_req   = '0;
assign next_select_pl           = msi.select_pl;
assign msi.pl_done              = pl_done_r;

///////////////////////////////////////////////////////////////////////
//                      PCIe Str Interfaces
///////////////////////////////////////////////////////////////////////
assign next_tx_valid                                         = tx.tx_valid;
assign next_tx_data[(TX_SLOT_WIDTH*3)-1:(TX_SLOT_WIDTH*2)]   = tx.tx_data[2];
assign next_tx_data[(TX_SLOT_WIDTH*2)-1:TX_SLOT_WIDTH]       = tx.tx_data[1];
assign next_tx_data[TX_SLOT_WIDTH-1:0]                       = tx.tx_data[0];
assign next_tx_parity                                        = tx.tx_parity;
assign next_tx_start[2]                                      = tx.tx_start[2];
assign next_tx_start[1]                                      = tx.tx_start[1];
assign next_tx_start[0]                                      = tx.tx_start[0];
assign next_tx_start2ptr                                     = tx.tx_startptr[2];
assign next_tx_start1ptr                                     = tx.tx_startptr[1];
assign next_tx_start0ptr                                     = tx.tx_startptr[0];
assign next_tx_start2type                                    = tx.tx_starttype[2];
assign next_tx_start1type                                    = tx.tx_starttype[1];
assign next_tx_start0type                                    = tx.tx_starttype[0];
assign next_tx_start2npinfo                                  = tx.tx_startnpinfo[2];
assign next_tx_start1npinfo                                  = tx.tx_startnpinfo[1];
assign next_tx_start0npinfo                                  = tx.tx_startnpinfo[0];
assign next_tx_end[2]                                        = tx.tx_end[2];
assign next_tx_end[1]                                        = tx.tx_end[1];
assign next_tx_end[0]                                        = tx.tx_end[0];
assign next_tx_end2ptr                                       = tx.tx_endptr[2];
assign next_tx_end1ptr                                       = tx.tx_endptr[1];
assign next_tx_end0ptr                                       = tx.tx_endptr[0];
assign next_tx_end_err                                       = tx.tx_end_error;

assign rx.rx_valid          = rx_valid_r;
generate if (WIDE_MODE_EN) begin : g_wide_mode_enabled

assign rx.rx_data           = {
    rx_data_r[(RX_SLOT_WIDTH*3)-1:(RX_SLOT_WIDTH*2)],
    rx_data_r[(RX_SLOT_WIDTH*2)-1:RX_SLOT_WIDTH],
    rx_data_r[RX_SLOT_WIDTH-1:0]
};

end else begin : g_wide_mode_disabled

assign rx.rx_data           = {
    {{(RX_SLOT_WIDTH - 512){1'b0}}, rx_data_r[1535:1024]},
    {{(RX_SLOT_WIDTH - 512){1'b0}}, rx_data_r[1023:512]},
    {{(RX_SLOT_WIDTH - 512){1'b0}}, rx_data_r[511:0]}
};

end endgenerate

assign rx.rx_parity         = rx_parity_r;
assign rx.rx_start          = {rx_start_r[2], rx_start_r[1], rx_start_r[0]};
assign rx.rx_startptr       = {rx_start2ptr_r, rx_start1ptr_r, rx_start0ptr_r};
assign rx.rx_starttype      = {rx_start2type_r, rx_start1type_r, rx_start0type_r};
assign rx.rx_startnpinfo    = {rx_start2npinfo_r, rx_start1npinfo_r, rx_start0npinfo_r};
assign rx.rx_end            = {rx_end_r[2], rx_end_r[1], rx_end_r[0]};
assign rx.rx_endptr         = {rx_end2ptr_r, rx_end1ptr_r, rx_end0ptr_r};
assign rx.rx_end_error      = rx_end_err_r;

///////////////////////////////////////////////////////////////////////
//                        Credit Interfaces
///////////////////////////////////////////////////////////////////////
assign tx_crd.cr_valid          = tx_credit_valid_r;
assign tx_crd.cr                = tx_credit_r;
assign next_tx_credit_active    = tx_crd.cr_active;

assign next_rx_credit_valid     = rx_crd.cr_valid;
assign next_rx_credit           = rx_crd.cr;
assign rx_crd.cr_active         = rx_credit_active_r;

///////////////////////////////////////////////////////////////////////
//                      Config Status Interfaces
///////////////////////////////////////////////////////////////////////
assign pf_cfg.pvld          = pf_cfg_status_vld_r;
assign pf_cfg.info          = pf_cfg_info_r;
assign pf_cfg.sos           = pf_cfg_status_sos_r;
assign pf_cfg.func_num      = pf_cfg_status_num_r;

assign vf_cfg.pvld          = vf_cfg_status_vld_r;
assign vf_cfg.info          = vf_cfg_info_r;
assign vf_cfg.sos           = vf_cfg_status_sos_r;
assign vf_cfg.func_num      = vf_cfg_status_num_r;

BMD_AXIST BMD_AXIST (
    .clk                    ( clk ),
    .rst_n                  ( rst_n_r ),

    .tx                     ( tx ),
    .rx                     ( rx ),

    .tx_crd                 ( tx_crd.slave ),
    .rx_crd                 ( rx_crd.master ),

    .pf_cfg                 ( pf_cfg ),
    .vf_cfg                 ( vf_cfg ),

    .ltssm_state            ( smlh_ltssm_state_r ),
    .link_up                ( smlh_link_up_r ),

    .msix                   ( msix.master ),
    .msi                    ( msi.s ),

    .axil_vsec              ( user_app_axil_if_vsec ),
    .axil_tph               ( user_app_axil_if_tph ),

    .app_ready_entr_l23     ( next_app_ready_entr_l23 ),

    .debug_bmd              ( next_debug_bmd ),
    .debug_bmd_sel          ( debug_bmd_sel_r )
);

//***************************************************************************************************************
//******************************  ELBI WRAPPER INSTANTIATION ****************************************************
//***************************************************************************************************************

ELBI_AXIL_MUX #(
    .CONSUMERS                  ( 2 )
) ELBI_AXIL_MUX (
    .clk                        ( clk ),
    .rst_n                      ( rst_n_r ),
    .elbi_axil                  ( user_app_axil_if.slave ),

    .consumer_araddr            ( '{user_app_axil_if_tph.araddr,   user_app_axil_if_vsec.araddr} ),
    .consumer_arprot            ( '{user_app_axil_if_tph.arprot,   user_app_axil_if_vsec.arprot} ),
    .consumer_arready           (  {user_app_axil_if_tph.arready,  user_app_axil_if_vsec.arready} ),
    .consumer_aruser            ( '{user_app_axil_if_tph.aruser,   user_app_axil_if_vsec.aruser} ),
    .consumer_arvalid           (  {user_app_axil_if_tph.arvalid,  user_app_axil_if_vsec.arvalid} ),
    .consumer_rdata             (  {user_app_axil_if_tph.rdata,    user_app_axil_if_vsec.rdata} ),
    .consumer_rready            (  {user_app_axil_if_tph.rready,   user_app_axil_if_vsec.rready} ),
    .consumer_rresp             (  {user_app_axil_if_tph.rresp,    user_app_axil_if_vsec.rresp} ),
    .consumer_ruser             (  {user_app_axil_if_tph.ruser,    user_app_axil_if_vsec.ruser} ),
    .consumer_rvalid            (  {user_app_axil_if_tph.rvalid,   user_app_axil_if_vsec.rvalid} ),
    .consumer_awaddr            ( '{user_app_axil_if_tph.awaddr,   user_app_axil_if_vsec.awaddr} ),
    .consumer_awprot            ( '{user_app_axil_if_tph.awprot,   user_app_axil_if_vsec.awprot} ),
    .consumer_awready           (  {user_app_axil_if_tph.awready,  user_app_axil_if_vsec.awready} ),
    .consumer_awuser            ( '{user_app_axil_if_tph.awuser,   user_app_axil_if_vsec.awuser} ),
    .consumer_awvalid           (  {user_app_axil_if_tph.awvalid,  user_app_axil_if_vsec.awvalid} ),
    .consumer_bready            (  {user_app_axil_if_tph.bready,   user_app_axil_if_vsec.bready} ),
    .consumer_bresp             (  {user_app_axil_if_tph.bresp,    user_app_axil_if_vsec.bresp} ),
    .consumer_buser             (  {user_app_axil_if_tph.buser,    user_app_axil_if_vsec.buser} ),
    .consumer_bvalid            (  {user_app_axil_if_tph.bvalid,   user_app_axil_if_vsec.bvalid} ),
    .consumer_wdata             ( '{user_app_axil_if_tph.wdata,    user_app_axil_if_vsec.wdata} ),
    .consumer_wuser             ( '{user_app_axil_if_tph.wuser,    user_app_axil_if_vsec.wuser} ),
    .consumer_wready            (  {user_app_axil_if_tph.wready,   user_app_axil_if_vsec.wready} ),
    .consumer_wstrb             ( '{user_app_axil_if_tph.wstrb,    user_app_axil_if_vsec.wstrb} ),
    .consumer_wvalid            (  {user_app_axil_if_tph.wvalid,   user_app_axil_if_vsec.wvalid} )
);

elbi_wrapper # (
    .AXIL_ADDR_WIDTH                        ( 64 ),
    .AXIL_DATA_WIDTH                        ( 64 ),
    .AXIL_AXUSER_WIDTH                      ( 8 )
) u_elbi_wrapper_bot (
    /* Clock Interface */
    .pl_aximm_clk                           ( clk ),
    .pl_aximm_rst_n                         ( rst_n_r ),

    /* ELBI slave interface connections */
    .pcie1_elbi_ext_lbc_override_en         ( next_ext_lbc_override_en ),
    .pcie1_elbi_ext_lbc_ack                 ( next_ext_lbc_ack ),
    .pcie1_elbi_ext_lbc_din                 ( next_ext_lbc_din ),
    .pcie1_elbi_lbc_ext_addr                ( lbc_ext_addr_r ),
    .pcie1_elbi_lbc_ext_dout                ( lbc_ext_dout_r ),
    .pcie1_elbi_lbc_ext_valid               ( lbc_ext_valid_r ),
    .pcie1_elbi_lbc_ext_cs                  ( lbc_ext_cs_r ),
    .pcie1_elbi_lbc_ext_wr                  ( lbc_ext_wr_r ),
    .pcie1_elbi_lbc_ext_rd                  ( lbc_ext_rd_r ),
    .pcie1_elbi_lbc_ext_dbi_access          ( lbc_ext_dbi_access_r ),
    .pcie1_elbi_lbc_ext_cxl_mbar0_access    ( lbc_ext_cxl_mbar0_access_r ),
    .pcie1_elbi_lbc_ext_rom_access          ( lbc_ext_rom_access_r ),
    .pcie1_elbi_lbc_ext_io_access           ( lbc_ext_io_access_r ),
    .pcie1_elbi_lbc_ext_bar_num             ( lbc_ext_bar_num_r ),
    .pcie1_elbi_lbc_ext_vfunc_num           ( lbc_ext_vfunc_num_r ),
    .pcie1_elbi_lbc_ext_vfunc_active        ( lbc_ext_vfunc_active_r ),

    /* AXI-L CONNECTIONS to control ELBI-AXI registers */
    .axil_slv_regs_araddr                   (/*axil_araddr*/),
    .axil_slv_regs_arprot                   (/*axil_arprot*/),
    .axil_slv_regs_arready                  (/*axil_arready*/),
    .axil_slv_regs_aruser                   (/*axil_aruser*/),
    .axil_slv_regs_arvalid                  (/*axil_arvalid*/),
    .axil_slv_regs_rdata                    (/*axil_rdata*/),
    .axil_slv_regs_rready                   (/*axil_rready*/),
    .axil_slv_regs_rresp                    (/*axil_rresp*/),
    .axil_slv_regs_ruser                    (/*axil_ruser*/),
    .axil_slv_regs_rvalid                   (/*axil_rvalid*/),
    .axil_slv_regs_awaddr                   (/*axil_awaddr*/),
    .axil_slv_regs_awprot                   (/*axil_awprot*/),
    .axil_slv_regs_awready                  (/*axil_awready*/),
    .axil_slv_regs_awuser                   (/*axil_awuser*/),
    .axil_slv_regs_awvalid                  (/*axil_awvalid*/),
    .axil_slv_regs_bready                   (/*axil_bready*/),
    .axil_slv_regs_bresp                    (/*axil_bresp*/),
    .axil_slv_regs_buser                    (/*axil_buser*/),
    .axil_slv_regs_bvalid                   (/*axil_bvalid*/),
    .axil_slv_regs_wdata                    (/*axil_wdata*/),
    .axil_slv_regs_wuser                    (/*axil_wuser*/),
    .axil_slv_regs_wready                   (/*axil_wready*/),
    .axil_slv_regs_wstrb                    (/*axil_wstrb*/),
    .axil_slv_regs_wvalid                   (/*axil_wvalid*/),

    /* AXI-L CONNECTIONS to User Applications */
    .pl_elbi_axil_mstr_araddr               ( user_app_axil_if.araddr ),
    .pl_elbi_axil_mstr_arprot               ( user_app_axil_if.arprot ),
    .pl_elbi_axil_mstr_arready              ( user_app_axil_if.arready ),
    .pl_elbi_axil_mstr_aruser               ( user_app_axil_if.aruser ),
    .pl_elbi_axil_mstr_arvalid              ( user_app_axil_if.arvalid ),
    .pl_elbi_axil_mstr_rdata                ( user_app_axil_if.rdata ),
    .pl_elbi_axil_mstr_rready               ( user_app_axil_if.rready ),
    .pl_elbi_axil_mstr_rresp                ( user_app_axil_if.rresp ),
    .pl_elbi_axil_mstr_ruser                ( user_app_axil_if.ruser ),
    .pl_elbi_axil_mstr_rvalid               ( user_app_axil_if.rvalid ),
    .pl_elbi_axil_mstr_awaddr               ( user_app_axil_if.awaddr ),
    .pl_elbi_axil_mstr_awprot               ( user_app_axil_if.awprot ),
    .pl_elbi_axil_mstr_awready              ( user_app_axil_if.awready ),
    .pl_elbi_axil_mstr_awuser               ( user_app_axil_if.awuser ),
    .pl_elbi_axil_mstr_awvalid              ( user_app_axil_if.awvalid ),
    .pl_elbi_axil_mstr_bready               ( user_app_axil_if.bready ),
    .pl_elbi_axil_mstr_bresp                ( user_app_axil_if.bresp ),
    .pl_elbi_axil_mstr_buser                ( user_app_axil_if.buser ),
    .pl_elbi_axil_mstr_bvalid               ( user_app_axil_if.bvalid ),
    .pl_elbi_axil_mstr_wdata                ( user_app_axil_if.wdata ),
    .pl_elbi_axil_mstr_wuser                ( user_app_axil_if.wuser ),
    .pl_elbi_axil_mstr_wready               ( user_app_axil_if.wready ),
    .pl_elbi_axil_mstr_wstrb                ( user_app_axil_if.wstrb ),
    .pl_elbi_axil_mstr_wvalid               ( user_app_axil_if.wvalid )
);

endmodule
