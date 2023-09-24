//////////////////////////////////////////////////////////////////////////////
// be767e8644eee50b2645307571242b99d62eea726bb276dae1cba7a07fa60690
// Proprietary Note:
// XILINX CONFIDENTIAL
//
// Copyright 2017 Xilinx, Inc. All rights reserved.
// This file contains confidential and proprietary information of Xilinx, Inc.
// and is protected under U.S. and international copyright and other
// intellectual property laws.
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
// US ExportControl: EAR 3E001
//
//       Owner:          
//       Revision:       $Id: //depot/icm/proj/everest/7t_n1/rtl/ref_7t_n1_live/header.v#2 $
//                       $Author: tyu $
//                       $DateTime: 2016/07/08 17:50:57 $
//                       $Change: 7769758 $
//       Description:
//
//////////////////////////////////////////////////////////////////////////////

`ifndef DMA_PCIE_MDMA_FAB_SVH
    `define DMA_PCIE_MDMA_FAB_SVH

    localparam    MDMA_DSC_IN_NUM_CHNL          = 3;

// Bypass out. Multiplexes H2c and C2H.
typedef struct packed {
    logic [127:0]               dsc;
    mdma_c2h_byp_dsc_out_sb_t   sb;
    logic                       last;
    logic                       vld;
    logic                       dir; //0 - H2C, 1-C2H
} mdma_dsc_byp_out_oif_t;

typedef struct packed {
    logic               crdt;
    logic               dir;
} mdma_dsc_byp_out_iif_t;

// VDM
typedef struct packed {
    logic [15:0]                data;
    logic                       sb;
    logic                       last;
    logic                       vld;
} mdma_vdm_oif_t;

// VDM
typedef struct packed {
    logic                       crdt;
} mdma_vdm_iif_t;

//Bypass In
typedef struct packed {
    logic               crdt;
    logic [1:0]         crdt_ch;
} mdma_dsc_byp_in_oif_t;

typedef struct packed {
    logic [63:0]               dsc;
    mdma_h2c_byp_dsc_in_sb_t   sb;
    logic                      last;
    logic                      vld;
    logic [1:0]                ch;
} mdma_h2c_dsc_byp_in_iif_t;

typedef struct packed {
    logic [63:0]               dsc;
    mdma_c2h_byp_dsc_in_sb_t   sb;
    logic                      last;
    logic                      vld;
    logic [1:0]                ch;
} mdma_c2h_dsc_byp_in_iif_t;

// C2H AXI Streaming
typedef struct packed {
    logic               crdt;
} mdma_c2h_axis_oif_t;

typedef struct packed {
    logic               crdt;
} mdma_c2h_dsc_crdt_oif_t;

// C2H AXI Streaming
typedef struct packed {
    logic               crdt;
} mdma_c2h_wrb_axis_oif_t;

typedef struct packed {
    mdma_c2h_axis_data_t   data;  
    mdma_c2h_axis_ctrl_t   ctrl;
    logic                  tlast;
    logic [5:0]            mty; 
} mdma_c2h_axis_tl_data_iif_t;

typedef struct packed {
    logic                  tvalid;
    mdma_c2h_axis_tl_data_iif_t tl_data;
} mdma_c2h_axis_iif_t;

typedef struct packed {
    logic                  tvalid;
    mdma_dsc_eng_crdt_t    tl_data;
} mdma_c2h_dsc_crdt_iif_t;

typedef struct packed {
    mdma_c2h_wrb_data_t    data;  
    logic                  tlast;
} mdma_c2h_wrb_axis_tl_data_iif_t;

typedef struct packed {
    logic                  tvalid;
    mdma_c2h_wrb_axis_tl_data_iif_t tl_data;
} mdma_c2h_wrb_axis_iif_t;

// H2C AXI Streaming
localparam MDMA_H2C_AXIS_DATA_BITS = 512;
localparam MDMA_H2C_AXIS_TUSER_BITS = $bits(mdma_h2c_axis_unal_tuser_t);

typedef struct packed {
    logic               crdt;
} mdma_h2c_axis_iif_t;

typedef struct packed {
    logic               crdt;
} mdma_tm_dsc_sts_iif_t;

typedef struct packed {
    logic [MDMA_H2C_AXIS_DATA_BITS-1:0]     tdata;
    logic [MDMA_H2C_AXIS_DATA_BITS/8 -1:0]  tparity;
    logic                                   tlast;
    logic [MDMA_H2C_AXIS_TUSER_BITS-1:0]    tuser;
} mdma_h2c_axis_tl_data_oif_t;

typedef struct packed {
    logic               tvalid;
    mdma_h2c_axis_tl_data_oif_t tl_data;
} mdma_h2c_axis_oif_t;

typedef struct packed {
    logic               tvalid;
    tm_dsc_sts_t        tl_data;
} mdma_tm_dsc_sts_oif_t;

    localparam MDMA_FAB_IN_BITS=1353;
    localparam MDMA_FAB_OUT_BITS=(231+759) - 8;    // 8 Bits taken away
    localparam mdma_fab_oif_rsv_bits=MDMA_FAB_OUT_BITS-
     $bits(dma_mgmt_req_if_out_t) - 
     $bits(dma_mgmt_cpl_if_out_t) - 
     $bits(mdma_usr_irq_if_out_t) - 
     $bits(usr_flr_if_out_t) - 
     $bits(mdma_desc_rsp_drop_t) - 
     $bits(mdma_c2h_pcie_cmp_t) - 
     $bits(dma_err_out_t) -
     $bits(mdma_dsc_byp_out_oif_t)-
     $bits(mdma_vdm_oif_t)-
     2*$bits(mdma_dsc_byp_in_oif_t)-
     $bits(mdma_c2h_axis_oif_t)-
     $bits(mdma_c2h_wrb_axis_oif_t)-
     $bits(mdma_h2c_axis_oif_t)-
     $bits(mdma_tm_dsc_sts_oif_t)-
     $bits(mdma_c2h_dsc_crdt_oif_t) -
     1;
typedef struct packed {
    logic [mdma_fab_oif_rsv_bits-1:0] rsv;
    mdma_vdm_oif_t               vdm;
    dma_mgmt_req_if_out_t        dma_mgmt_req;
    dma_mgmt_cpl_if_out_t        dma_mgmt_cpl;
    mdma_usr_irq_if_out_t        irq_out;
    usr_flr_if_out_t             flr_out;
    mdma_desc_rsp_drop_t         mdma_c2h_drop;
    mdma_c2h_pcie_cmp_t          mdma_c2h_pcie_cmp;
    dma_err_out_t                dma_err_out;
    mdma_dsc_byp_out_oif_t       byp_out;
    mdma_dsc_byp_in_oif_t        h2c_byp_in;
    mdma_dsc_byp_in_oif_t        c2h_byp_in;
    mdma_c2h_axis_oif_t          c2h_axis;
    mdma_c2h_wrb_axis_oif_t      c2h_wrb_axis;
    mdma_h2c_axis_oif_t          h2c_axis; 
    mdma_tm_dsc_sts_oif_t        tm_dsc_sts;
    mdma_c2h_dsc_crdt_oif_t      c2h_dsc_crdt;
    logic                        axi_resetn;
} mdma_fab_oif_t;

localparam MDMA_FAB_IN_RSV_BITS = MDMA_FAB_IN_BITS - 1 - 
     $bits(dma_mgmt_req_if_in_t) - $bits(dma_mgmt_cpl_if_in_t) - 
     $bits(mdma_usr_irq_if_in_t) - $bits(usr_flr_if_in_t) - 
     $bits(mdma_dsc_byp_out_iif_t) - $bits(mdma_vdm_iif_t) - $bits(mdma_h2c_dsc_byp_in_iif_t) - $bits(mdma_c2h_dsc_byp_in_iif_t) - $bits(mdma_c2h_axis_iif_t) - $bits(mdma_c2h_wrb_axis_iif_t) - $bits(mdma_h2c_axis_iif_t) - $bits(mdma_tm_dsc_sts_iif_t) - $bits(mdma_c2h_dsc_crdt_iif_t) - 1;

typedef struct packed {
    logic [MDMA_FAB_IN_RSV_BITS-1:0] rsv;
    logic                            h2c_axis_last_pkt;
    mdma_vdm_iif_t                   vdm;
    dma_mgmt_req_if_in_t             dma_mgmt_req;
    dma_mgmt_cpl_if_in_t             dma_mgmt_cpl;
    mdma_usr_irq_if_in_t             irq_in;
    usr_flr_if_in_t                  flr_in;
    mdma_dsc_byp_out_iif_t           byp_out;
    mdma_h2c_dsc_byp_in_iif_t        h2c_byp_in;
    mdma_c2h_dsc_byp_in_iif_t        c2h_byp_in;
    mdma_c2h_axis_iif_t              c2h_axis;
    mdma_c2h_wrb_axis_iif_t          c2h_wrb_axis;
    mdma_h2c_axis_iif_t              h2c_axis;
    mdma_tm_dsc_sts_iif_t            tm_dsc_sts;
    mdma_c2h_dsc_crdt_iif_t          c2h_dsc_crdt;
    logic                            dma_reset;
} mdma_fab_iif_t;

typedef union packed {
    logic [MDMA_FAB_IN_BITS-1:0]     chk;
    mdma_fab_iif_t                  fab_in;
} mdma_fab_iif_chk_t;

typedef union packed {
    logic [MDMA_FAB_OUT_BITS-1:0]   chk;
    mdma_fab_oif_t                  fab_out;
} mdma_fab_oif_chk_t;

localparam     MDMA_FABRIC_OUT_C2H_DSC_CRDT_BITS  = $bits(mdma_c2h_dsc_crdt_oif_t);
localparam     MDMA_FABRIC_OUT_TM_DSC_STS_BITS    = $bits(mdma_tm_dsc_sts_oif_t );
localparam     MDMA_FABRIC_OUT_H2C_AXIS_BITS      = $bits(mdma_h2c_axis_oif_t   );
localparam     MDMA_FABRIC_OUT_C2H_WRB_AXIS_BITS  = $bits(mdma_c2h_wrb_axis_oif_t);
localparam     MDMA_FABRIC_OUT_C2H_AXIS_BITS      = $bits(mdma_c2h_axis_oif_t   );
localparam     MDMA_FABRIC_OUT_C2H_BYP_IN_BITS    = $bits(mdma_dsc_byp_in_oif_t );
localparam     MDMA_FABRIC_OUT_H2C_BYP_IN_BITS    = $bits(mdma_dsc_byp_in_oif_t );
localparam     MDMA_FABRIC_OUT_BYP_OUT_BITS       = $bits(mdma_dsc_byp_out_oif_t);
localparam     MDMA_FABRIC_OUT_VDM_BITS           = $bits(mdma_vdm_oif_t);
localparam     MDMA_FABRIC_OUT_DMA_ERR_OUT_BITS   = $bits(dma_err_out_t         );
localparam     MDMA_FABRIC_OUT_MDMA_C2H_DROP_BITS = $bits(mdma_desc_rsp_drop_t  );
localparam     MDMA_FABRIC_OUT_FLR_OUT_BITS       = $bits(usr_flr_if_out_t      );
localparam     MDMA_FABRIC_OUT_IRQ_OUT_BITS       = $bits(mdma_usr_irq_if_out_t );
localparam     MDMA_FABRIC_OUT_DMA_MGMT_CPL_BITS  = $bits(dma_mgmt_cpl_if_out_t );
localparam     MDMA_FABRIC_OUT_DMA_MGMT_REQ_BITS  = $bits(dma_mgmt_req_if_out_t );

localparam    MDMA_FABRIC_OUT_C2H_DSC_CRDT_START   = 1;
localparam    MDMA_FABRIC_OUT_TM_DSC_STS_START     = $bits(mdma_c2h_dsc_crdt_oif_t) +   MDMA_FABRIC_OUT_C2H_DSC_CRDT_START;
localparam    MDMA_FABRIC_OUT_H2C_AXIS_START       = $bits(mdma_tm_dsc_sts_oif_t ) +    MDMA_FABRIC_OUT_TM_DSC_STS_START;
localparam    MDMA_FABRIC_OUT_C2H_WRB_AXIS_START   = $bits(mdma_h2c_axis_oif_t   ) +    MDMA_FABRIC_OUT_H2C_AXIS_START ;
localparam    MDMA_FABRIC_OUT_C2H_AXIS_START       = $bits(mdma_c2h_wrb_axis_oif_t) +   MDMA_FABRIC_OUT_C2H_WRB_AXIS_START;
localparam    MDMA_FABRIC_OUT_C2H_BYP_IN_START     = $bits(mdma_c2h_axis_oif_t   ) +    MDMA_FABRIC_OUT_C2H_AXIS_START;
localparam    MDMA_FABRIC_OUT_H2C_BYP_IN_START     = $bits(mdma_dsc_byp_in_oif_t ) +    MDMA_FABRIC_OUT_C2H_BYP_IN_START;
localparam    MDMA_FABRIC_OUT_BYP_OUT_START        = $bits(mdma_dsc_byp_in_oif_t ) +    MDMA_FABRIC_OUT_H2C_BYP_IN_START;
localparam    MDMA_FABRIC_OUT_DMA_ERR_OUT_START    = $bits(mdma_dsc_byp_out_oif_t) +    MDMA_FABRIC_OUT_BYP_OUT_START;
localparam    MDMA_FABRIC_OUT_MDMA_C2H_DROP_START  = $bits(dma_err_out_t         ) +    MDMA_FABRIC_OUT_DMA_ERR_OUT_START;
localparam    MDMA_FABRIC_OUT_FLR_OUT_START        = $bits(mdma_desc_rsp_drop_t  ) +    MDMA_FABRIC_OUT_MDMA_C2H_DROP_START;
localparam    MDMA_FABRIC_OUT_IRQ_OUT_START        = $bits(usr_flr_if_out_t      ) +    MDMA_FABRIC_OUT_FLR_OUT_START;
localparam    MDMA_FABRIC_OUT_DMA_MGMT_CPL_START   = $bits(mdma_usr_irq_if_out_t ) +    MDMA_FABRIC_OUT_IRQ_OUT_START;
localparam    MDMA_FABRIC_OUT_DMA_MGMT_REQ_START   = $bits(dma_mgmt_cpl_if_out_t ) +    MDMA_FABRIC_OUT_DMA_MGMT_CPL_START;
localparam    MDMA_FABRIC_OUT_VDM_START            = $bits(dma_mgmt_req_if_out_t)  +    MDMA_FABRIC_OUT_DMA_MGMT_REQ_START;

localparam   MDMA_FABRIC_IN_C2H_DSC_CRDT_START    = 0;
localparam   MDMA_FABRIC_IN_TM_DSC_STS_START      = $bits(mdma_c2h_dsc_crdt_iif_t) +    MDMA_FABRIC_IN_C2H_DSC_CRDT_START;
localparam   MDMA_FABRIC_IN_H2C_AXIS_START        = $bits(mdma_tm_dsc_sts_iif_t  ) +    MDMA_FABRIC_IN_TM_DSC_STS_START;
localparam   MDMA_FABRIC_IN_C2H_WRB_AXIS_START    = $bits(mdma_h2c_axis_iif_t    ) +    MDMA_FABRIC_IN_H2C_AXIS_START;
localparam   MDMA_FABRIC_IN_C2H_AXIS_START        = $bits(mdma_c2h_wrb_axis_iif_t) +    MDMA_FABRIC_IN_C2H_WRB_AXIS_START;
localparam   MDMA_FABRIC_IN_C2H_BYP_IN_START      = $bits(mdma_c2h_axis_iif_t    ) +    MDMA_FABRIC_IN_C2H_AXIS_START;
localparam   MDMA_FABRIC_IN_H2C_BYP_IN_START      = $bits(mdma_c2h_dsc_byp_in_iif_t) +  MDMA_FABRIC_IN_C2H_BYP_IN_START;
localparam   MDMA_FABRIC_IN_BYP_OUT_START         = $bits(mdma_h2c_dsc_byp_in_iif_t) +  MDMA_FABRIC_IN_H2C_BYP_IN_START;
localparam   MDMA_FABRIC_IN_FLR_IN_START          = $bits(mdma_dsc_byp_out_iif_t ) +    MDMA_FABRIC_IN_BYP_OUT_START;
localparam   MDMA_FABRIC_IN_IRQ_IN_START          = $bits(usr_flr_if_in_t        ) +    MDMA_FABRIC_IN_FLR_IN_START;
localparam   MDMA_FABRIC_IN_DMA_MGMT_CPL_START    = $bits(mdma_usr_irq_if_in_t   ) +    MDMA_FABRIC_IN_IRQ_IN_START;
localparam   MDMA_FABRIC_IN_DMA_MGMT_REQ_START    = $bits(dma_mgmt_cpl_if_in_t   ) +    MDMA_FABRIC_IN_DMA_MGMT_CPL_START;
localparam   MDMA_FABRIC_IN_VDM_START             = $bits(dma_mgmt_req_if_in_t   ) +    MDMA_FABRIC_IN_DMA_MGMT_REQ_START;

`endif
