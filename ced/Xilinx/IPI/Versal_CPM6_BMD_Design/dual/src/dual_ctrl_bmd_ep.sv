//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2026.1.0 (lin64) Build 6332237 Sun Jan 04 15:44:39 MST 2026
//Date        : Mon Jan  5 12:04:41 2026
//Host        : xsjlc230025 running 64-bit Red Hat Enterprise Linux release 8.10 (Ootpa)
//Command     : generate_target cpm6_dut_wrapper.bd
//Purpose     : IP block instantiation
//--------------------------------------------------------------------------------
module dual_ctrl_bmd_ep 
import bmd_link_pkg::*;
(
    CTRL0_GT_0_grx_n,
    CTRL0_GT_0_grx_p,
    CTRL0_GT_0_gtx_n,
    CTRL0_GT_0_gtx_p,
    CTRL1_GT_0_grx_n,
    CTRL1_GT_0_grx_p,
    CTRL1_GT_0_gtx_n,
    CTRL1_GT_0_gtx_p,
    ctrl0_gt_refclk_0_clk_n,
    ctrl0_gt_refclk_0_clk_p,
    ctrl1_gt_refclk_0_clk_n,
    ctrl1_gt_refclk_0_clk_p
);

    input  [LINK_WIDTH-1:0]    CTRL0_GT_0_grx_n;
    input  [LINK_WIDTH-1:0]    CTRL0_GT_0_grx_p;
    output [LINK_WIDTH-1:0]    CTRL0_GT_0_gtx_n;
    output [LINK_WIDTH-1:0]    CTRL0_GT_0_gtx_p;
    input  [LINK_WIDTH-1:0]    CTRL1_GT_0_grx_n;
    input  [LINK_WIDTH-1:0]    CTRL1_GT_0_grx_p;
    output [LINK_WIDTH-1:0]    CTRL1_GT_0_gtx_n;
    output [LINK_WIDTH-1:0]    CTRL1_GT_0_gtx_p;
    input           ctrl0_gt_refclk_0_clk_n;
    input           ctrl0_gt_refclk_0_clk_p;
    input           ctrl1_gt_refclk_0_clk_n;
    input           ctrl1_gt_refclk_0_clk_p;

    wire [LINK_WIDTH-1:0]      CTRL0_GT_0_grx_n;
    wire [LINK_WIDTH-1:0]      CTRL0_GT_0_grx_p;
    wire [LINK_WIDTH-1:0]      CTRL0_GT_0_gtx_n;
    wire [LINK_WIDTH-1:0]      CTRL0_GT_0_gtx_p;

    wire            ctrl0_gt_refclk_0_clk_n;
    wire            ctrl0_gt_refclk_0_clk_p;

    wire [LINK_WIDTH-1:0]      CTRL1_GT_0_grx_n;
    wire [LINK_WIDTH-1:0]      CTRL1_GT_0_grx_p;
    wire [LINK_WIDTH-1:0]      CTRL1_GT_0_gtx_n;
    wire [LINK_WIDTH-1:0]      CTRL1_GT_0_gtx_p;

    wire            ctrl1_gt_refclk_0_clk_n;
    wire            ctrl1_gt_refclk_0_clk_p;

    wire            pl0_ref_clk_0;
    wire            pl0_resetn_0;

    wire [5:0]      pcie0_cfg_status_0_cfg_neg_link_width;
    wire [2:0]      pcie0_cfg_status_0_pf_func_num;
    wire [15:0]     pcie0_cfg_status_0_pf_info;
    wire            pcie0_cfg_status_0_pf_sos;
    wire            pcie0_cfg_status_0_pf_vld;
    wire            pcie0_cfg_status_0_rdlh_link_up;
    wire            pcie0_cfg_status_0_smlh_link_up;
    wire [5:0]      pcie0_cfg_status_0_smlh_ltssm_state;
    wire [7:0]      pcie0_cfg_status_0_vf_func_num;
    wire [15:0]     pcie0_cfg_status_0_vf_info;
    wire            pcie0_cfg_status_0_vf_sos;
    wire            pcie0_cfg_status_0_vf_vld;

    wire [7:0]      pcie0_flr_0_cxl_rst_active;
    wire [7:0]      pcie0_flr_0_cxl_rst_done;
    wire [7:0]      pcie0_flr_0_cxl_rst_error;
    wire [7:0]      pcie0_flr_0_pf_done;
    wire [255:0]    pcie0_flr_0_vf_done;

    wire [2:0]      pcie0_msi_0_func_num;
    wire            pcie0_msi_0_grant;
    wire            pcie0_msi_0_req;
    wire [4:0]      pcie0_msi_0_vector_num;

    wire            pcie0_msix_0_error;
    wire [2:0]      pcie0_msix_0_func_num;
    wire            pcie0_msix_0_grant;
    wire [1:0]      pcie0_msix_0_operation;
    wire            pcie0_msix_0_req;
    wire [10:0]     pcie0_msix_0_vector_num;
    wire            pcie0_msix_0_vfunc_active;
    wire [7:0]      pcie0_msix_0_vfunc_num;

    wire            pcie0_rstn_0;

    wire [15:0]     pcie0_strm_0_cpld_cdts;
    wire [11:0]     pcie0_strm_0_cplh_cdts;
    wire [15:0]     pcie0_strm_0_npd_cdts;
    wire [11:0]     pcie0_strm_0_nph_cdts;
    wire [15:0]     pcie0_strm_0_pd_cdts;
    wire [11:0]     pcie0_strm_0_ph_cdts;

    wire [2:0]      pcie0_strm_0_rx_credit;
    wire            pcie0_strm_0_rx_credit_ready;
    wire            pcie0_strm_0_rx_credit_valid;

    wire [2654:0]   pcie0_strm_0_rx_data;
    wire [2:0]      pcie0_strm_0_rx_end;
    wire [5:0]      pcie0_strm_0_rx_end0_ptr;
    wire [5:0]      pcie0_strm_0_rx_end1_ptr;
    wire [5:0]      pcie0_strm_0_rx_end2_ptr;
    wire [8:0]      pcie0_strm_0_rx_end_error;
    wire [44:0]     pcie0_strm_0_rx_parity;
    wire [2:0]      pcie0_strm_0_rx_slot0_np_valid = 3'b0;
    wire [1:0]      pcie0_strm_0_rx_slot0_type;
    wire [2:0]      pcie0_strm_0_rx_slot1_np_valid = 3'b0;
    wire [1:0]      pcie0_strm_0_rx_slot1_type;
    wire [2:0]      pcie0_strm_0_rx_slot2_np_valid = 3'b0;
    wire [1:0]      pcie0_strm_0_rx_slot2_type;
    wire [2:0]      pcie0_strm_0_rx_start;
    wire [1:0]      pcie0_strm_0_rx_start0_ptr;
    wire [1:0]      pcie0_strm_0_rx_start1_ptr;
    wire [1:0]      pcie0_strm_0_rx_start2_ptr;
    wire            pcie0_strm_0_rx_valid;

    wire [2:0]      pcie0_strm_0_tx_credit;
    wire            pcie0_strm_0_tx_credit_ready;
    wire            pcie0_strm_0_tx_credit_valid;

    wire [2555:0]   pcie0_strm_0_tx_data;
    wire [2:0]      pcie0_strm_0_tx_end;
    wire [5:0]      pcie0_strm_0_tx_end0_ptr;
    wire [5:0]      pcie0_strm_0_tx_end1_ptr;
    wire [5:0]      pcie0_strm_0_tx_end2_ptr;
    wire [8:0]      pcie0_strm_0_tx_end_error;
    wire [43:0]     pcie0_strm_0_tx_parity;
    wire [2:0]      pcie0_strm_0_tx_slot0_np_valid;
    wire [1:0]      pcie0_strm_0_tx_slot0_type;
    wire [2:0]      pcie0_strm_0_tx_slot1_np_valid;
    wire [1:0]      pcie0_strm_0_tx_slot1_type;
    wire [2:0]      pcie0_strm_0_tx_slot2_np_valid;
    wire [1:0]      pcie0_strm_0_tx_slot2_type;
    wire [2:0]      pcie0_strm_0_tx_start;
    wire [1:0]      pcie0_strm_0_tx_start0_ptr;
    wire [1:0]      pcie0_strm_0_tx_start1_ptr;
    wire [1:0]      pcie0_strm_0_tx_start2_ptr;
    wire            pcie0_strm_0_tx_valid;

    wire [5:0]      pcie1_cfg_status_0_cfg_neg_link_width;
    wire [2:0]      pcie1_cfg_status_0_pf_func_num;
    wire [15:0]     pcie1_cfg_status_0_pf_info;
    wire            pcie1_cfg_status_0_pf_sos;
    wire            pcie1_cfg_status_0_pf_vld;
    wire            pcie1_cfg_status_0_rdlh_link_up;
    wire            pcie1_cfg_status_0_smlh_link_up;
    wire [5:0]      pcie1_cfg_status_0_smlh_ltssm_state;
    wire [7:0]      pcie1_cfg_status_0_vf_func_num;
    wire [15:0]     pcie1_cfg_status_0_vf_info;
    wire            pcie1_cfg_status_0_vf_sos;
    wire            pcie1_cfg_status_0_vf_vld;

    wire [7:0]      pcie1_flr_0_cxl_rst_active;
    wire [7:0]      pcie1_flr_0_cxl_rst_done;
    wire [7:0]      pcie1_flr_0_cxl_rst_error;
    wire [7:0]      pcie1_flr_0_pf_done;
    wire [255:0]    pcie1_flr_0_vf_done;

    wire [2:0]      pcie1_msi_0_func_num;
    wire            pcie1_msi_0_grant;
    wire            pcie1_msi_0_req;
    wire [4:0]      pcie1_msi_0_vector_num;

    wire            pcie1_msix_0_error;
    wire [2:0]      pcie1_msix_0_func_num;
    wire            pcie1_msix_0_grant;
    wire [1:0]      pcie1_msix_0_operation;
    wire            pcie1_msix_0_req;
    wire [10:0]     pcie1_msix_0_vector_num;
    wire            pcie1_msix_0_vfunc_active;
    wire [7:0]      pcie1_msix_0_vfunc_num;

    wire            pcie1_rstn_0;

    wire [15:0]     pcie1_strm_0_cpld_cdts;
    wire [11:0]     pcie1_strm_0_cplh_cdts;
    wire [15:0]     pcie1_strm_0_npd_cdts;
    wire [11:0]     pcie1_strm_0_nph_cdts;
    wire [15:0]     pcie1_strm_0_pd_cdts;
    wire [11:0]     pcie1_strm_0_ph_cdts;

    wire [2:0]      pcie1_strm_0_rx_credit;
    wire            pcie1_strm_0_rx_credit_ready;
    wire            pcie1_strm_0_rx_credit_valid;

    wire [2654:0]   pcie1_strm_0_rx_data;
    wire [2:0]      pcie1_strm_0_rx_end;
    wire [5:0]      pcie1_strm_0_rx_end0_ptr;
    wire [5:0]      pcie1_strm_0_rx_end1_ptr;
    wire [5:0]      pcie1_strm_0_rx_end2_ptr;
    wire [8:0]      pcie1_strm_0_rx_end_error;
    wire [44:0]     pcie1_strm_0_rx_parity;
    wire [2:0]      pcie1_strm_0_rx_slot0_np_valid = 3'b0;
    wire [1:0]      pcie1_strm_0_rx_slot0_type;
    wire [2:0]      pcie1_strm_0_rx_slot1_np_valid = 3'b0;
    wire [1:0]      pcie1_strm_0_rx_slot1_type;
    wire [2:0]      pcie1_strm_0_rx_slot2_np_valid = 3'b0;
    wire [1:0]      pcie1_strm_0_rx_slot2_type;
    wire [2:0]      pcie1_strm_0_rx_start;
    wire [1:0]      pcie1_strm_0_rx_start0_ptr;
    wire [1:0]      pcie1_strm_0_rx_start1_ptr;
    wire [1:0]      pcie1_strm_0_rx_start2_ptr;
    wire            pcie1_strm_0_rx_valid;

    wire [2:0]      pcie1_strm_0_tx_credit;
    wire            pcie1_strm_0_tx_credit_ready;
    wire            pcie1_strm_0_tx_credit_valid;

    wire [2555:0]   pcie1_strm_0_tx_data;
    wire [2:0]      pcie1_strm_0_tx_end;
    wire [5:0]      pcie1_strm_0_tx_end0_ptr;
    wire [5:0]      pcie1_strm_0_tx_end1_ptr;
    wire [5:0]      pcie1_strm_0_tx_end2_ptr;
    wire [8:0]      pcie1_strm_0_tx_end_error;
    wire [43:0]     pcie1_strm_0_tx_parity;
    wire [2:0]      pcie1_strm_0_tx_slot0_np_valid;
    wire [1:0]      pcie1_strm_0_tx_slot0_type;
    wire [2:0]      pcie1_strm_0_tx_slot1_np_valid;
    wire [1:0]      pcie1_strm_0_tx_slot1_type;
    wire [2:0]      pcie1_strm_0_tx_slot2_np_valid;
    wire [1:0]      pcie1_strm_0_tx_slot2_type;
    wire [2:0]      pcie1_strm_0_tx_start;
    wire [1:0]      pcie1_strm_0_tx_start0_ptr;
    wire [1:0]      pcie1_strm_0_tx_start1_ptr;
    wire [1:0]      pcie1_strm_0_tx_start2_ptr;
    wire            pcie1_strm_0_tx_valid;

    cpm6_bmd ctrl1_ep_i (
        .CTRL0_GT_0_grx_n                       ( CTRL0_GT_0_grx_n ),
        .CTRL0_GT_0_grx_p                       ( CTRL0_GT_0_grx_p ),
        .CTRL0_GT_0_gtx_n                       ( CTRL0_GT_0_gtx_n ),
        .CTRL0_GT_0_gtx_p                       ( CTRL0_GT_0_gtx_p ),

        .ctrl0_gt_refclk_0_clk_n                ( ctrl0_gt_refclk_0_clk_n ),
        .ctrl0_gt_refclk_0_clk_p                ( ctrl0_gt_refclk_0_clk_p ),

        .pcie0_cfg_status_0_cfg_neg_link_width  ( pcie0_cfg_status_0_cfg_neg_link_width ),
        .pcie0_cfg_status_0_pf_func_num         ( pcie0_cfg_status_0_pf_func_num ),
        .pcie0_cfg_status_0_pf_info             ( pcie0_cfg_status_0_pf_info ),
        .pcie0_cfg_status_0_pf_sos              ( pcie0_cfg_status_0_pf_sos ),
        .pcie0_cfg_status_0_pf_vld              ( pcie0_cfg_status_0_pf_vld ),

        .pcie0_cfg_status_0_rdlh_link_up        ( pcie0_cfg_status_0_rdlh_link_up ),
        .pcie0_cfg_status_0_smlh_link_up        ( pcie0_cfg_status_0_smlh_link_up ),
        .pcie0_cfg_status_0_smlh_ltssm_state    ( pcie0_cfg_status_0_smlh_ltssm_state ),

        .pcie0_cfg_status_0_vf_func_num         ( pcie0_cfg_status_0_vf_func_num ),
        .pcie0_cfg_status_0_vf_info             ( pcie0_cfg_status_0_vf_info ),
        .pcie0_cfg_status_0_vf_sos              ( pcie0_cfg_status_0_vf_sos ),
        .pcie0_cfg_status_0_vf_vld              ( pcie0_cfg_status_0_vf_vld ),

        .pcie0_flr_0_cxl_rst_active             ( pcie0_flr_0_cxl_rst_active ),
        .pcie0_flr_0_cxl_rst_done               ( pcie0_flr_0_cxl_rst_done ),
        .pcie0_flr_0_cxl_rst_error              ( pcie0_flr_0_cxl_rst_error ),
        .pcie0_flr_0_pf_done                    ( pcie0_flr_0_pf_done ),
        .pcie0_flr_0_vf_done                    ( pcie0_flr_0_vf_done ),

        .pcie0_msi_0_func_num                   ( pcie0_msi_0_func_num ),
        .pcie0_msi_0_grant                      ( pcie0_msi_0_grant ),
        .pcie0_msi_0_req                        ( pcie0_msi_0_req ),
        .pcie0_msi_0_vector_num                 ( pcie0_msi_0_vector_num ),

        .pcie0_msix_0_error                     ( pcie0_msix_0_error ),
        .pcie0_msix_0_func_num                  ( pcie0_msix_0_func_num ),
        .pcie0_msix_0_grant                     ( pcie0_msix_0_grant ),
        .pcie0_msix_0_operation                 ( pcie0_msix_0_operation ),
        .pcie0_msix_0_req                       ( pcie0_msix_0_req ),
        .pcie0_msix_0_vector_num                ( pcie0_msix_0_vector_num ),
        .pcie0_msix_0_vfunc_active              ( pcie0_msix_0_vfunc_active ),
        .pcie0_msix_0_vfunc_num                 ( pcie0_msix_0_vfunc_num ),

        .pcie0_rstn_0                           ( pcie0_rstn_0 ),

        .pcie0_strm_0_cpld_cdts                 ( pcie0_strm_0_cpld_cdts ),
        .pcie0_strm_0_cplh_cdts                 ( pcie0_strm_0_cplh_cdts ),
        .pcie0_strm_0_npd_cdts                  ( pcie0_strm_0_npd_cdts ),
        .pcie0_strm_0_nph_cdts                  ( pcie0_strm_0_nph_cdts ),
        .pcie0_strm_0_pd_cdts                   ( pcie0_strm_0_pd_cdts ),
        .pcie0_strm_0_ph_cdts                   ( pcie0_strm_0_ph_cdts ),

        .pcie0_strm_0_rx_credit                 ( pcie0_strm_0_rx_credit ),
        .pcie0_strm_0_rx_credit_ready           ( pcie0_strm_0_rx_credit_ready ),
        .pcie0_strm_0_rx_credit_valid           ( pcie0_strm_0_rx_credit_valid ),

        .pcie0_strm_0_rx_data                   ( pcie0_strm_0_rx_data ),
        .pcie0_strm_0_rx_end                    ( pcie0_strm_0_rx_end ),
        .pcie0_strm_0_rx_end0_ptr               ( pcie0_strm_0_rx_end0_ptr ),
        .pcie0_strm_0_rx_end1_ptr               ( pcie0_strm_0_rx_end1_ptr ),
        .pcie0_strm_0_rx_end2_ptr               ( pcie0_strm_0_rx_end2_ptr ),
        .pcie0_strm_0_rx_end_error              ( pcie0_strm_0_rx_end_error ),
        .pcie0_strm_0_rx_parity                 ( pcie0_strm_0_rx_parity ),      
        .pcie0_strm_0_rx_slot0_type             ( pcie0_strm_0_rx_slot0_type ),      
        .pcie0_strm_0_rx_slot1_type             ( pcie0_strm_0_rx_slot1_type ),      
        .pcie0_strm_0_rx_slot2_type             ( pcie0_strm_0_rx_slot2_type ),
        .pcie0_strm_0_rx_start                  ( pcie0_strm_0_rx_start ),
        .pcie0_strm_0_rx_start0_ptr             ( pcie0_strm_0_rx_start0_ptr ),
        .pcie0_strm_0_rx_start1_ptr             ( pcie0_strm_0_rx_start1_ptr ),
        .pcie0_strm_0_rx_start2_ptr             ( pcie0_strm_0_rx_start2_ptr ),
        .pcie0_strm_0_rx_valid                  ( pcie0_strm_0_rx_valid ),

        .pcie0_strm_0_tx_credit                 ( pcie0_strm_0_tx_credit ),
        .pcie0_strm_0_tx_credit_ready           ( pcie0_strm_0_tx_credit_ready ),
        .pcie0_strm_0_tx_credit_valid           ( pcie0_strm_0_tx_credit_valid ),

        .pcie0_strm_0_tx_data                   ( pcie0_strm_0_tx_data ),
        .pcie0_strm_0_tx_end                    ( pcie0_strm_0_tx_end ),
        .pcie0_strm_0_tx_end0_ptr               ( pcie0_strm_0_tx_end0_ptr ),
        .pcie0_strm_0_tx_end1_ptr               ( pcie0_strm_0_tx_end1_ptr ),
        .pcie0_strm_0_tx_end2_ptr               ( pcie0_strm_0_tx_end2_ptr ),
        .pcie0_strm_0_tx_end_error              ( pcie0_strm_0_tx_end_error ),
        .pcie0_strm_0_tx_parity                 ( pcie0_strm_0_tx_parity ),
        .pcie0_strm_0_tx_slot0_np_valid         ( pcie0_strm_0_tx_slot0_np_valid ),
        .pcie0_strm_0_tx_slot0_type             ( pcie0_strm_0_tx_slot0_type ),
        .pcie0_strm_0_tx_slot1_np_valid         ( pcie0_strm_0_tx_slot1_np_valid ),
        .pcie0_strm_0_tx_slot1_type             ( pcie0_strm_0_tx_slot1_type ),
        .pcie0_strm_0_tx_slot2_np_valid         ( pcie0_strm_0_tx_slot2_np_valid ),
        .pcie0_strm_0_tx_slot2_type             ( pcie0_strm_0_tx_slot2_type ),
        .pcie0_strm_0_tx_start                  ( pcie0_strm_0_tx_start ),
        .pcie0_strm_0_tx_start0_ptr             ( pcie0_strm_0_tx_start0_ptr ),
        .pcie0_strm_0_tx_start1_ptr             ( pcie0_strm_0_tx_start1_ptr ),
        .pcie0_strm_0_tx_start2_ptr             ( pcie0_strm_0_tx_start2_ptr ),
        .pcie0_strm_0_tx_valid                  ( pcie0_strm_0_tx_valid ),

        .CTRL1_GT_0_grx_n                       ( CTRL1_GT_0_grx_n ),
        .CTRL1_GT_0_grx_p                       ( CTRL1_GT_0_grx_p ),
        .CTRL1_GT_0_gtx_n                       ( CTRL1_GT_0_gtx_n ),
        .CTRL1_GT_0_gtx_p                       ( CTRL1_GT_0_gtx_p ),

        .ctrl1_gt_refclk_0_clk_n                ( ctrl1_gt_refclk_0_clk_n ),
        .ctrl1_gt_refclk_0_clk_p                ( ctrl1_gt_refclk_0_clk_p ),

        .pcie1_cfg_status_0_cfg_neg_link_width  ( pcie1_cfg_status_0_cfg_neg_link_width ),
        .pcie1_cfg_status_0_pf_func_num         ( pcie1_cfg_status_0_pf_func_num ),
        .pcie1_cfg_status_0_pf_info             ( pcie1_cfg_status_0_pf_info ),
        .pcie1_cfg_status_0_pf_sos              ( pcie1_cfg_status_0_pf_sos ),
        .pcie1_cfg_status_0_pf_vld              ( pcie1_cfg_status_0_pf_vld ),

        .pcie1_cfg_status_0_rdlh_link_up        ( pcie1_cfg_status_0_rdlh_link_up ),
        .pcie1_cfg_status_0_smlh_link_up        ( pcie1_cfg_status_0_smlh_link_up ),
        .pcie1_cfg_status_0_smlh_ltssm_state    ( pcie1_cfg_status_0_smlh_ltssm_state ),

        .pcie1_cfg_status_0_vf_func_num         ( pcie1_cfg_status_0_vf_func_num ),
        .pcie1_cfg_status_0_vf_info             ( pcie1_cfg_status_0_vf_info ),
        .pcie1_cfg_status_0_vf_sos              ( pcie1_cfg_status_0_vf_sos ),
        .pcie1_cfg_status_0_vf_vld              ( pcie1_cfg_status_0_vf_vld ),

        .pcie1_flr_0_cxl_rst_active             ( pcie1_flr_0_cxl_rst_active ),
        .pcie1_flr_0_cxl_rst_done               ( pcie1_flr_0_cxl_rst_done ),
        .pcie1_flr_0_cxl_rst_error              ( pcie1_flr_0_cxl_rst_error ),
        .pcie1_flr_0_pf_done                    ( pcie1_flr_0_pf_done ),
        .pcie1_flr_0_vf_done                    ( pcie1_flr_0_vf_done ),

        .pcie1_msi_0_func_num                   ( pcie1_msi_0_func_num ),
        .pcie1_msi_0_grant                      ( pcie1_msi_0_grant ),
        .pcie1_msi_0_req                        ( pcie1_msi_0_req ),
        .pcie1_msi_0_vector_num                 ( pcie1_msi_0_vector_num ),

        .pcie1_msix_0_error                     ( pcie1_msix_0_error ),
        .pcie1_msix_0_func_num                  ( pcie1_msix_0_func_num ),
        .pcie1_msix_0_grant                     ( pcie1_msix_0_grant ),
        .pcie1_msix_0_operation                 ( pcie1_msix_0_operation ),
        .pcie1_msix_0_req                       ( pcie1_msix_0_req ),
        .pcie1_msix_0_vector_num                ( pcie1_msix_0_vector_num ),
        .pcie1_msix_0_vfunc_active              ( pcie1_msix_0_vfunc_active ),
        .pcie1_msix_0_vfunc_num                 ( pcie1_msix_0_vfunc_num ),

        .pcie1_rstn_0                           ( pcie1_rstn_0 ),

        .pcie1_strm_0_cpld_cdts                 ( pcie1_strm_0_cpld_cdts ),
        .pcie1_strm_0_cplh_cdts                 ( pcie1_strm_0_cplh_cdts ),
        .pcie1_strm_0_npd_cdts                  ( pcie1_strm_0_npd_cdts ),
        .pcie1_strm_0_nph_cdts                  ( pcie1_strm_0_nph_cdts ),
        .pcie1_strm_0_pd_cdts                   ( pcie1_strm_0_pd_cdts ),
        .pcie1_strm_0_ph_cdts                   ( pcie1_strm_0_ph_cdts ),

        .pcie1_strm_0_rx_credit                 ( pcie1_strm_0_rx_credit ),
        .pcie1_strm_0_rx_credit_ready           ( pcie1_strm_0_rx_credit_ready ),
        .pcie1_strm_0_rx_credit_valid           ( pcie1_strm_0_rx_credit_valid ),

        .pcie1_strm_0_rx_data                   ( pcie1_strm_0_rx_data ),
        .pcie1_strm_0_rx_end                    ( pcie1_strm_0_rx_end ),
        .pcie1_strm_0_rx_end0_ptr               ( pcie1_strm_0_rx_end0_ptr ),
        .pcie1_strm_0_rx_end1_ptr               ( pcie1_strm_0_rx_end1_ptr ),
        .pcie1_strm_0_rx_end2_ptr               ( pcie1_strm_0_rx_end2_ptr ),
        .pcie1_strm_0_rx_end_error              ( pcie1_strm_0_rx_end_error ),
        .pcie1_strm_0_rx_parity                 ( pcie1_strm_0_rx_parity ),
        .pcie1_strm_0_rx_slot0_type             ( pcie1_strm_0_rx_slot0_type ),
        .pcie1_strm_0_rx_slot1_type             ( pcie1_strm_0_rx_slot1_type ),
        .pcie1_strm_0_rx_slot2_type             ( pcie1_strm_0_rx_slot2_type ),
        .pcie1_strm_0_rx_start                  ( pcie1_strm_0_rx_start ),
        .pcie1_strm_0_rx_start0_ptr             ( pcie1_strm_0_rx_start0_ptr ),
        .pcie1_strm_0_rx_start1_ptr             ( pcie1_strm_0_rx_start1_ptr ),
        .pcie1_strm_0_rx_start2_ptr             ( pcie1_strm_0_rx_start2_ptr ),
        .pcie1_strm_0_rx_valid                  ( pcie1_strm_0_rx_valid ),

        .pcie1_strm_0_tx_credit                 ( pcie1_strm_0_tx_credit ),
        .pcie1_strm_0_tx_credit_ready           ( pcie1_strm_0_tx_credit_ready ),
        .pcie1_strm_0_tx_credit_valid           ( pcie1_strm_0_tx_credit_valid ),

        .pcie1_strm_0_tx_data                   ( pcie1_strm_0_tx_data ),
        .pcie1_strm_0_tx_end                    ( pcie1_strm_0_tx_end ),
        .pcie1_strm_0_tx_end0_ptr               ( pcie1_strm_0_tx_end0_ptr ),
        .pcie1_strm_0_tx_end1_ptr               ( pcie1_strm_0_tx_end1_ptr ),
        .pcie1_strm_0_tx_end2_ptr               ( pcie1_strm_0_tx_end2_ptr ),
        .pcie1_strm_0_tx_end_error              ( pcie1_strm_0_tx_end_error ),
        .pcie1_strm_0_tx_parity                 ( pcie1_strm_0_tx_parity ),
        .pcie1_strm_0_tx_slot0_np_valid         ( pcie1_strm_0_tx_slot0_np_valid ),
        .pcie1_strm_0_tx_slot0_type             ( pcie1_strm_0_tx_slot0_type ),
        .pcie1_strm_0_tx_slot1_np_valid         ( pcie1_strm_0_tx_slot1_np_valid ),
        .pcie1_strm_0_tx_slot1_type             ( pcie1_strm_0_tx_slot1_type ),
        .pcie1_strm_0_tx_slot2_np_valid         ( pcie1_strm_0_tx_slot2_np_valid ),
        .pcie1_strm_0_tx_slot2_type             ( pcie1_strm_0_tx_slot2_type ),
        .pcie1_strm_0_tx_start                  ( pcie1_strm_0_tx_start ),
        .pcie1_strm_0_tx_start0_ptr             ( pcie1_strm_0_tx_start0_ptr ),
        .pcie1_strm_0_tx_start1_ptr             ( pcie1_strm_0_tx_start1_ptr ),
        .pcie1_strm_0_tx_start2_ptr             ( pcie1_strm_0_tx_start2_ptr ),
        .pcie1_strm_0_tx_valid                  ( pcie1_strm_0_tx_valid ),

        .pl0_ref_clk_0                          ( pl0_ref_clk_0 ),
        .pl0_resetn_0                           ( pl0_resetn_0 )
    );


    pcie_app_versal_bmd pcie_app_versal_bmd_top_i (
        .clk                        ( pl0_ref_clk_0 ),
        .rst_n                      ( pl0_resetn_0 ),

        .rx_valid                   ( pcie1_strm_0_rx_valid ),
        .rx_data                    ( pcie1_strm_0_rx_data ),
        .rx_parity                  ( pcie1_strm_0_rx_parity ),
        .rx_start                   ( pcie1_strm_0_rx_start ),
        .rx_start0ptr               ( pcie1_strm_0_rx_start0_ptr ),
        .rx_start1ptr               ( pcie1_strm_0_rx_start1_ptr ),
        .rx_start2ptr               ( pcie1_strm_0_rx_start2_ptr ),
        .rx_start0type              ( pcie1_strm_0_rx_slot0_type ),
        .rx_start1type              ( pcie1_strm_0_rx_slot1_type ),
        .rx_start2type              ( pcie1_strm_0_rx_slot2_type ),
        .rx_start0npinfo            ( pcie1_strm_0_rx_slot0_np_valid ),
        .rx_start1npinfo            ( pcie1_strm_0_rx_slot1_np_valid ),
        .rx_start2npinfo            ( pcie1_strm_0_rx_slot2_np_valid ),
        .rx_end                     ( pcie1_strm_0_rx_end ),
        .rx_end0ptr                 ( pcie1_strm_0_rx_end0_ptr ),
        .rx_end1ptr                 ( pcie1_strm_0_rx_end1_ptr ),
        .rx_end2ptr                 ( pcie1_strm_0_rx_end2_ptr ),
        .rx_end_err                 ( pcie1_strm_0_rx_end_error ),
        .rx_credit_valid            ( pcie1_strm_0_rx_credit_valid ),
        .rx_credit                  ( pcie1_strm_0_rx_credit ),
        .rx_credit_active           ( pcie1_strm_0_rx_credit_ready ),

        .tx_valid                   ( pcie1_strm_0_tx_valid ),
        .tx_data                    ( pcie1_strm_0_tx_data ),
        .tx_parity                  ( pcie1_strm_0_tx_parity ),
        .tx_start                   ( pcie1_strm_0_tx_start ),
        .tx_start0ptr               ( pcie1_strm_0_tx_start0_ptr ),
        .tx_start1ptr               ( pcie1_strm_0_tx_start1_ptr ),
        .tx_start2ptr               ( pcie1_strm_0_tx_start2_ptr ),
        .tx_start0type              ( pcie1_strm_0_tx_slot0_type ),
        .tx_start1type              ( pcie1_strm_0_tx_slot1_type ),
        .tx_start2type              ( pcie1_strm_0_tx_slot2_type ),
        .tx_start0npinfo            ( pcie1_strm_0_tx_slot0_np_valid ),
        .tx_start1npinfo            ( pcie1_strm_0_tx_slot1_np_valid ),
        .tx_start2npinfo            ( pcie1_strm_0_tx_slot2_np_valid ),
        .tx_end                     ( pcie1_strm_0_tx_end ),
        .tx_end0ptr                 ( pcie1_strm_0_tx_end0_ptr ),
        .tx_end1ptr                 ( pcie1_strm_0_tx_end1_ptr ),
        .tx_end2ptr                 ( pcie1_strm_0_tx_end2_ptr ),
        .tx_end_err                 ( pcie1_strm_0_tx_end_error ),
        .tx_credit_valid            ( pcie1_strm_0_tx_credit_valid ),
        .tx_credit                  ( pcie1_strm_0_tx_credit ),
        .tx_credit_active           ( pcie1_strm_0_tx_credit_ready ),
        .xadm_ph_cdts               ( pcie1_strm_0_ph_cdts ),
        .xadm_pd_cdts               ( pcie1_strm_0_pd_cdts ),
        .xadm_nph_cdts              ( pcie1_strm_0_nph_cdts ),
        .xadm_npd_cdts              ( pcie1_strm_0_npd_cdts ),
        .xadm_cplh_cdts             ( pcie1_strm_0_cplh_cdts ),
        .xadm_cpld_cdts             ( pcie1_strm_0_cpld_cdts ),

        .pf_cfg_info                ( pcie1_cfg_status_0_pf_info ),
        .pf_cfg_status_vld          ( pcie1_cfg_status_0_pf_vld ),
        .pf_cfg_status_sos          ( pcie1_cfg_status_0_pf_sos ),
        .pf_cfg_status_num          ( pcie1_cfg_status_0_pf_func_num ),
        .vf_cfg_info                ( pcie1_cfg_status_0_vf_info ),
        .vf_cfg_status_vld          ( pcie1_cfg_status_0_vf_vld ),
        .vf_cfg_status_sos          ( pcie1_cfg_status_0_vf_sos ),
        .vf_cfg_status_num          ( pcie1_cfg_status_0_vf_func_num ),

        .cfg_neg_link_width         ( pcie1_cfg_status_0_cfg_neg_link_width ),
        .rdlh_link_up               ( pcie1_cfg_status_0_rdlh_link_up ),
        .smlh_link_up               ( pcie1_cfg_status_0_smlh_link_up ),
        .smlh_ltssm_state           ( pcie1_cfg_status_0_smlh_ltssm_state ),

        .pl_msi_func_num            ( pcie1_msi_0_func_num ),
        .pl_msi_tc                  (  ),
        .pl_msi_vector              ( pcie1_msi_0_vector_num ),
        .pl_msi_addr_lo             (  ),
        .pl_msi_addr_hi             (  ),
        .pl_msi_data                (  ),
        .pl_issue_msi_req           ( pcie1_msi_0_req ),
        .pl_issue_msix_req          (  ),
        .select_pl                  (  ),
        .pl_done                    ( pcie1_msi_0_grant ),

        .pl_msix_user_error        ( pcie1_msix_0_error ),
        .pl_msix_user_func_num     ( pcie1_msix_0_func_num ),
        .pl_msix_user_vfunc_num    ( pcie1_msix_0_vfunc_num ),
        .pl_msix_user_vfunc_active ( pcie1_msix_0_vfunc_active ),
        .pl_msix_user_req          ( pcie1_msix_0_req ),
        .pl_msix_user_vector_num   ( pcie1_msix_0_vector_num ),
        .pl_msix_user_grant        ( pcie1_msix_0_grant ),
        .pl_msix_user_operation    ( pcie1_msix_0_operation ),

        .app_ready_entr_l23         (  ),
        .pl_ready                   (  ),

        //Wires to be defined for these signals, mostly used as trigger for debug.
        .debug_bmd                  (  ),
        .debug_bmd_sel              ( '0 ),

        // ELBI slave interface connections
        .ext_lbc_override_en       (  ),
        .ext_lbc_ack               (  ),
        .ext_lbc_din               (  ),
        .lbc_ext_addr              ( '0 ),
        .lbc_ext_dout              ( '0 ),
        .lbc_ext_valid             ( '0 ),
        .lbc_ext_cs                ( '0 ),
        .lbc_ext_wr                ( '0 ),
        .lbc_ext_rd                ( '0 ),
        .lbc_ext_dbi_access        ( '0 ),
        .lbc_ext_cxl_mbar0_access  ( '0 ),
        .lbc_ext_rom_access        ( '0 ),
        .lbc_ext_io_access         ( '0 ),
        .lbc_ext_bar_num           ( '0 ),
        .lbc_ext_vfunc_num         ( '0 ),
        .lbc_ext_vfunc_active      ( '0 )
    );

    pcie_app_versal_bmd pcie_app_versal_bmd_bot_i (
        .clk                        ( pl0_ref_clk_0 ),
        .rst_n                      ( pl0_resetn_0 ),

        .rx_valid                   ( pcie0_strm_0_rx_valid ),
        .rx_data                    ( pcie0_strm_0_rx_data ),
        .rx_parity                  ( pcie0_strm_0_rx_parity ),
        .rx_start                   ( pcie0_strm_0_rx_start ),
        .rx_start0ptr               ( pcie0_strm_0_rx_start0_ptr ),
        .rx_start1ptr               ( pcie0_strm_0_rx_start1_ptr ),
        .rx_start2ptr               ( pcie0_strm_0_rx_start2_ptr ),
        .rx_start0type              ( pcie0_strm_0_rx_slot0_type ),
        .rx_start1type              ( pcie0_strm_0_rx_slot1_type ),
        .rx_start2type              ( pcie0_strm_0_rx_slot2_type ),
        .rx_start0npinfo            ( pcie0_strm_0_rx_slot0_np_valid ),
        .rx_start1npinfo            ( pcie0_strm_0_rx_slot1_np_valid ),
        .rx_start2npinfo            ( pcie0_strm_0_rx_slot2_np_valid ),
        .rx_end                     ( pcie0_strm_0_rx_end ),
        .rx_end0ptr                 ( pcie0_strm_0_rx_end0_ptr ),
        .rx_end1ptr                 ( pcie0_strm_0_rx_end1_ptr ),
        .rx_end2ptr                 ( pcie0_strm_0_rx_end2_ptr ),
        .rx_end_err                 ( pcie0_strm_0_rx_end_error ),
        .rx_credit_valid            ( pcie0_strm_0_rx_credit_valid ),
        .rx_credit                  ( pcie0_strm_0_rx_credit ),
        .rx_credit_active           ( pcie0_strm_0_rx_credit_ready ),

        .tx_valid                   ( pcie0_strm_0_tx_valid ),
        .tx_data                    ( pcie0_strm_0_tx_data ),
        .tx_parity                  ( pcie0_strm_0_tx_parity ),
        .tx_start                   ( pcie0_strm_0_tx_start ),
        .tx_start0ptr               ( pcie0_strm_0_tx_start0_ptr ),
        .tx_start1ptr               ( pcie0_strm_0_tx_start1_ptr ),
        .tx_start2ptr               ( pcie0_strm_0_tx_start2_ptr ),
        .tx_start0type              ( pcie0_strm_0_tx_slot0_type ),
        .tx_start1type              ( pcie0_strm_0_tx_slot1_type ),
        .tx_start2type              ( pcie0_strm_0_tx_slot2_type ),
        .tx_start0npinfo            ( pcie0_strm_0_tx_slot0_np_valid ),
        .tx_start1npinfo            ( pcie0_strm_0_tx_slot1_np_valid ),
        .tx_start2npinfo            ( pcie0_strm_0_tx_slot2_np_valid ),
        .tx_end                     ( pcie0_strm_0_tx_end ),
        .tx_end0ptr                 ( pcie0_strm_0_tx_end0_ptr ),
        .tx_end1ptr                 ( pcie0_strm_0_tx_end1_ptr ),
        .tx_end2ptr                 ( pcie0_strm_0_tx_end2_ptr ),
        .tx_end_err                 ( pcie0_strm_0_tx_end_error ),
        .tx_credit_valid            ( pcie0_strm_0_tx_credit_valid ),
        .tx_credit                  ( pcie0_strm_0_tx_credit ),
        .tx_credit_active           ( pcie0_strm_0_tx_credit_ready ),
        .xadm_ph_cdts               ( pcie0_strm_0_ph_cdts ),
        .xadm_pd_cdts               ( pcie0_strm_0_pd_cdts ),
        .xadm_nph_cdts              ( pcie0_strm_0_nph_cdts ),
        .xadm_npd_cdts              ( pcie0_strm_0_npd_cdts ),
        .xadm_cplh_cdts             ( pcie0_strm_0_cplh_cdts ),
        .xadm_cpld_cdts             ( pcie0_strm_0_cpld_cdts ),

        .pf_cfg_info                ( pcie0_cfg_status_0_pf_info ),
        .pf_cfg_status_vld          ( pcie0_cfg_status_0_pf_vld ),
        .pf_cfg_status_sos          ( pcie0_cfg_status_0_pf_sos ),
        .pf_cfg_status_num          ( pcie0_cfg_status_0_pf_func_num ),
        .vf_cfg_info                ( pcie0_cfg_status_0_vf_info ),
        .vf_cfg_status_vld          ( pcie0_cfg_status_0_vf_vld ),
        .vf_cfg_status_sos          ( pcie0_cfg_status_0_vf_sos ),
        .vf_cfg_status_num          ( pcie0_cfg_status_0_vf_func_num ),

        .cfg_neg_link_width         ( pcie0_cfg_status_0_cfg_neg_link_width ),
        .rdlh_link_up               ( pcie0_cfg_status_0_rdlh_link_up ),
        .smlh_link_up               ( pcie0_cfg_status_0_smlh_link_up ),
        .smlh_ltssm_state           ( pcie0_cfg_status_0_smlh_ltssm_state ),

        .pl_msi_func_num            ( pcie0_msi_0_func_num ),
        .pl_msi_tc                  (  ),
        .pl_msi_vector              ( pcie0_msi_0_vector_num ),
        .pl_msi_addr_lo             (  ),
        .pl_msi_addr_hi             (  ),
        .pl_msi_data                (  ),
        .pl_issue_msi_req           ( pcie0_msi_0_req ),
        .pl_issue_msix_req          (  ),
        .select_pl                  (  ),
        .pl_done                    ( pcie0_msi_0_grant ),

        .pl_msix_user_error        ( pcie0_msix_0_error ),
        .pl_msix_user_func_num     ( pcie0_msix_0_func_num ),
        .pl_msix_user_vfunc_num    ( pcie0_msix_0_vfunc_num ),
        .pl_msix_user_vfunc_active ( pcie0_msix_0_vfunc_active ),
        .pl_msix_user_req          ( pcie0_msix_0_req ),
        .pl_msix_user_vector_num   ( pcie0_msix_0_vector_num ),
        .pl_msix_user_grant        ( pcie0_msix_0_grant ),
        .pl_msix_user_operation    ( pcie0_msix_0_operation ),

        .app_ready_entr_l23         (  ),
        .pl_ready                   (  ),

        //Wires to be defined for these signals, mostly used as trigger for debug.
        .debug_bmd                  (  ),
        .debug_bmd_sel              ( '0 ),

        // ELBI slave interface connections
        .ext_lbc_override_en       (  ),
        .ext_lbc_ack               (  ),
        .ext_lbc_din               (  ),
        .lbc_ext_addr              ( '0 ),
        .lbc_ext_dout              ( '0 ),
        .lbc_ext_valid             ( '0 ),
        .lbc_ext_cs                ( '0 ),
        .lbc_ext_wr                ( '0 ),
        .lbc_ext_rd                ( '0 ),
        .lbc_ext_dbi_access        ( '0 ),
        .lbc_ext_cxl_mbar0_access  ( '0 ),
        .lbc_ext_rom_access        ( '0 ),
        .lbc_ext_io_access         ( '0 ),
        .lbc_ext_bar_num           ( '0 ),
        .lbc_ext_vfunc_num         ( '0 ),
        .lbc_ext_vfunc_active      ( '0 )
    );

endmodule
