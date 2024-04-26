//-----------------------------------------------------------------------------
//
// (c) Copyright 1986-2022 Xilinx, Inc. All rights reserved.
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
`ifndef CDX_DEFINES_SVH
`define CDX_DEFINES_SVH

`include "cdx5n_defines.vh"
`include "cdx5n_attr_defines.svh"
`include "cdx5n_csi_defines.svh"

`define CDX_UNC_ERR_HDR_POISON        1
`define CDX_UNC_ERR_HDR_UR_CA         2
`define CDX_UNC_ERR_HDR_BCNT          3
`define CDX_UNC_ERR_HDR_PARAM         4
`define CDX_UNC_ERR_HDR_ADDR          5
`define CDX_UNC_ERR_HDR_TAG           6
`define CDX_UNC_ERR_HDR_FLR           8
`define CDX_UNC_ERR_HDR_TIMEOUT       9
`define CDX_UNC_ERR_DAT_POISON       16 
`define CDX_UNC_ERR_DAT_PARITY       17
`define CDX_UNC_ERR_WR_UR            18 
`define CDX_UNC_ERR_WR_FLR           19
`define CDX_UNC_ERR_DMA              20    // Error signalled by dma engine
`define CDX_UNC_ERR_SLV_REQ          21    // Error signalled by Slave Port (like Invalid Burst)
`define CDX_UNC_ERR_DSC              21    // Error in use case of dsc engine
`define CDX_UNC_ERR_MISC_FAT         22
`define CDX_UNC_ERR_RAM_DBE          23
`define CDX_COR_ERR_RAM_SBE          24
`define CDX_UNC_ERR_PORT_ID          25   // Mismatching port_id tried to access queue

typedef logic [11:0]                            xmti_t;
typedef logic [11:0]                            pcie_brg_fnid_t;
typedef logic [3:0]                             pcie_brg_host_id_t;
typedef logic [31:0]                            pcie_brg_int_vec_out_t;


localparam CDX_TRQ_SEL_UNMAPPED = 0;
typedef enum logic [3:0]{
    PCIE_BRG_TRQ_SEL_UNMAPPED=0,
    PCIE_BRG_TRQ_SEL_GLBL1, 
    PCIE_BRG_TRQ_SEL_GLBL2, 
    PCIE_BRG_TRQ_SEL_GLBL, 
    PCIE_BRG_TRQ_SEL_FMAP, 
    PCIE_BRG_TRQ_SEL_IRQ, 
    PCIE_BRG_TRQ_SEL_IND, 
    PCIE_BRG_TRQ_SEL_C2H, 
    PCIE_BRG_TRQ_SEL_H2C, 
    PCIE_BRG_TRQ_SEL_C2H_MM0, 
    PCIE_BRG_TRQ_SEL_C2H_MM1, 
    PCIE_BRG_TRQ_SEL_H2C_MM0, 
    PCIE_BRG_TRQ_SEL_H2C_MM1, 
    PCIE_BRG_TRQ_SEL_C2H_2, 
    PCIE_BRG_TRQ_SEL_QUEUE
} pcie_brg_dmap_sel_e;

typedef enum logic {NO_PAYLOAD=0, HAS_PAYLOAD} csi_pkt_type_t;

typedef enum logic [4:0] {
    MODE_1P_GEN5x16          = 5'b00001,
    MODE_2P_GEN5x8           = 5'b00010,
    MODE_4P_GEN5x4           = 5'b00100,
    MODE_P0_GEN5x8_2P_GEN5x4 = 5'b01000,
    MODE_P2_GEN5x8_2P_GEN5x4 = 5'b10000
} pcie_furc_mode_t;

localparam MODE_1P_GEN5x16_LOC           = 0;
localparam MODE_2P_GEN5x8_LOC            = 1;
localparam MODE_4P_GEN5x4_LOC            = 2;
localparam MODE_P0_GEN5x8_2P_GEN5x4_LOC  = 3;
localparam MODE_P2_GEN5x8_2P_GEN5x4_LOC  = 4;

//Struct for new CSI TLP (CSI hdr + 512-payload)
typedef struct packed {
    logic              sop;
    logic              eop;
    csi_capsule_t      hdr;
    logic  [512-1:0]   payload;
} csi_tlp_t;

typedef struct packed {
    logic              sop;
    logic              eop;
    csi_capsule_t      hdr;
    logic  [512-1:0]   payload;
    logic  [32-1:0]    crc;
} csi_tlp_wcrc_t;

typedef struct packed {
    logic              sop;
    logic              eop;
    csi_capsule_t      hdr;
    logic  [256-1:0]   payload;
} csi_tlp256_t;

typedef struct packed {
    logic              sop;
    logic              eop;
    csi_capsule_t      hdr;
    logic  [256-1:0]   payload;
    logic  [32-1:0]    crc;
} csi_tlp256_wcrc_t;

typedef struct packed {
    logic              sop;
    logic              eop;
    csi_capsule_t      hdr;
    logic  [288-1:0]   payload; //256b data + 32b crc
} csi_tlp288_t;

typedef struct packed {
    logic [159:0]      seg;
    logic              sop;
    logic              eop;
    logic              err;
    logic              vld;
} csi_seg_t;

//2-bit encoding of CSI interface id (bits 3:2 of intf_id in CSI capsules)
localparam CDM_INTF_ID  = 2'b00;
localparam PCIE_INTF_ID = 2'b01;
localparam TNOC_INTF_ID = 2'b10;
localparam PSX_INTF_ID  = 2'b11;

//Full 5-bit encoding of CSI interface id (with furcation)
localparam FULL_CDM_INTF_ID   = 5'b0_0000;
localparam FULL_PCIE0_INTF_ID = 5'b0_0100;
localparam FULL_PCIE1_INTF_ID = 5'b0_0101;
localparam FULL_PCIE2_INTF_ID = 5'b0_0110;
localparam FULL_PCIE3_INTF_ID = 5'b0_0111;
localparam FULL_TNOC0_INTF_ID = 5'b0_1000;
localparam FULL_TNOC1_INTF_ID = 5'b0_1001;
localparam FULL_TNOC2_INTF_ID = 5'b0_1010;
localparam FULL_TNOC3_INTF_ID = 5'b0_1011;
localparam FULL_PSX_INTF_ID   = 5'b0_1100;

// Fabric in 
localparam CDX_FAB_LO_IN_0_BITS      = 3400;//3200;    
localparam CDX_FAB_LO_IN_1_BITS      = 2270;//2227;    
localparam CDX_FAB_UP_IN_0_BITS      = 3800;//3200;    
localparam CDX_FAB_UP_IN_1_BITS      = 2670;//1800;    
localparam CDX_FAB_LO_IN_0_RSV_BITS  = CDX_FAB_LO_IN_0_BITS-4-4;      // -4: fab_clk, -4: fab_rst_n
localparam CDX_FAB_LO_IN_1_RSV_BITS  = CDX_FAB_LO_IN_1_BITS;       
localparam CDX_FAB_UP_IN_0_RSV_BITS  = CDX_FAB_UP_IN_0_BITS;
localparam CDX_FAB_UP_IN_1_RSV_BITS  = CDX_FAB_UP_IN_1_BITS;
localparam CDX_FAB_LO_IN_BITS        = CDX_FAB_LO_IN_0_BITS+CDX_FAB_LO_IN_1_BITS;    
localparam CDX_FAB_UP_IN_BITS        = CDX_FAB_UP_IN_0_BITS+CDX_FAB_UP_IN_1_BITS;    
localparam CDX_FAB_IN_BITS           = CDX_FAB_LO_IN_BITS+CDX_FAB_UP_IN_BITS;

// Fabric out
localparam CDX_FAB_LO_OUT_0_BITS     = 2240;//2150;    
localparam CDX_FAB_LO_OUT_1_BITS     = 1391;//1301;    
localparam CDX_FAB_UP_OUT_0_BITS     = 2600;//2150;    
localparam CDX_FAB_UP_OUT_1_BITS     = 1751;//1250;    
localparam CDX_FAB_LO_OUT_0_RSV_BITS = CDX_FAB_LO_OUT_0_BITS;
localparam CDX_FAB_LO_OUT_1_RSV_BITS = CDX_FAB_LO_OUT_1_BITS;
localparam CDX_FAB_UP_OUT_0_RSV_BITS = CDX_FAB_UP_OUT_0_BITS;
localparam CDX_FAB_UP_OUT_1_RSV_BITS = CDX_FAB_UP_OUT_1_BITS;
localparam CDX_FAB_LO_OUT_BITS       = CDX_FAB_LO_OUT_0_BITS+CDX_FAB_LO_OUT_1_BITS;    
localparam CDX_FAB_UP_OUT_BITS       = CDX_FAB_UP_OUT_0_BITS+CDX_FAB_UP_OUT_1_BITS;
localparam CDX_FAB_OUT_BITS          = CDX_FAB_LO_OUT_BITS+CDX_FAB_UP_OUT_BITS;  

//`include "cdx5n_fab_defs.svh"

//--------------------------Moved to cdx5n_fab_defs.svh-----------
//typedef struct packed {
//    logic [CDX_FAB_LO_IN_0_RSV_BITS-1:0]   rsvd;
//    //logic [3:0]                            fab_rst_n;
//    //logic [3:0]                            fab_clk;
//} cdx_fab_lo_in_0_t;
//
//typedef struct packed {
//    logic [CDX_FAB_LO_IN_1_RSV_BITS-1:0]   rsvd;
//} cdx_fab_lo_in_1_t;
//
//typedef struct packed {
//    logic [CDX_FAB_UP_IN_0_RSV_BITS-1:0]   rsvd;
//} cdx_fab_up_in_0_t;
//
//typedef struct packed {
//    logic [CDX_FAB_UP_IN_1_RSV_BITS-1:0]   rsvd;
//} cdx_fab_up_in_1_t;
//
//typedef struct packed {
//    logic [CDX_FAB_LO_OUT_0_RSV_BITS-1:0]  rsvd;
//} cdx_fab_lo_out_0_t;
//
//typedef struct packed {
//    logic [CDX_FAB_LO_OUT_1_RSV_BITS-1:0]  rsvd;
//} cdx_fab_lo_out_1_t;
//
//typedef struct packed {
//    logic [CDX_FAB_UP_OUT_0_RSV_BITS-1:0]  rsvd;
//} cdx_fab_up_out_0_t;
//
//typedef struct packed {
//    logic [CDX_FAB_UP_OUT_1_RSV_BITS-1:0]  rsvd;
//} cdx_fab_up_out_1_t;

typedef struct packed {
    logic           vf_en;
    logic           msi_en;
    logic           msix_en;
    logic           bme;
    logic           flr;
    logic [11:0]    func;
} usr_fnc_sts_data_t;

typedef enum logic [1:0] {
    SEND_FLR_DONE   = 2'b00,
    SET_FNC_EN      = 2'b01,
    CLR_FNC_EN      = 2'b10
} usr_fnc_upd_opcode_t;

// PCIE Bridge Address Translation
localparam PCQ_FN_TYPES_NUM                = 32;
localparam PCQ_FN_TYPE_ID_NBITS            = $clog2(PCQ_FN_TYPES_NUM);
localparam PCQ_NUM_WINDOWS                 = 256;
localparam PCQ_WINDOW_ID_NBITS             = $clog2(PCQ_NUM_WINDOWS);
localparam HAH_FUNC_ID_NBITS               = 13;

typedef logic [PCQ_WINDOW_ID_NBITS-1:0]    win_id_t; 
typedef logic [HAH_FUNC_ID_NBITS-1:0]      hah_func_id_t;

localparam PCIE_FUNC_CFG_TABLE_RDT_FFOUT   = 1;
localparam PCIE_BAR_CFG_TABLE_RDT_FFOUT    = 1;
localparam PCIE_MEM_WINDOW_TABLE_RDT_FFOUT = 1;
localparam PCIE_MSG_CFG_TABLE_RDT_FFOUT    = 1;

typedef struct packed {
    logic               req_is_pr;
    logic               req_is_msg;
    logic               csi_rro;
    csi_intf_id_t       csi_dst;
    csi_addr_t          csi_addr;
    csi_intf_id_t       msg_csi_dst;
    csi_msg_cookie_t    msg_cookie;
} pcie_addr_trans_data_t;

typedef struct packed {
    logic                            valid;
    logic [PCQ_FN_TYPE_ID_NBITS-1:0] fn_type;
} pcq_fn_cfg_t;

typedef struct packed {
    logic                             valid;
    logic [5:0]                       log2_bar_size_m12;      // Encodes the BAR size
    logic [2:0]                       log2_n_win;             // 1-128 windows
    logic [4:0]                       log2_win_size_m12;      // 4KB -> 8TB
    logic [PCQ_WINDOW_ID_NBITS-1:0]   base_win;
    logic                             wrap;
} pcq_bar_cfg_t;

typedef enum logic {
    PM_ENDPOINT=0, PM_ROOT_PORT=1
} pcie_intf_mode_e;

typedef enum logic [1:0] {
    PCQ_AE_ADDR=0, PCQ_AE_APERTURE=1, PCQ_AE_AP_FUNC_BAR=2
} pcq_addr_enc_mode_e;

typedef struct packed {
    uint52_t                  win_base_page_idx;
} pcq_ae_addr_t;   

typedef struct packed {
    logic [$bits(pcq_ae_addr_t) - $bits(win_id_t) - $bits(csi_ap_id_t)-1:0]  rsvd;
    csi_ap_id_t               ap_id;
    win_id_t                  win_off;
} pcq_ap_t;    

typedef struct packed {
    logic [$bits(pcq_ae_addr_t) - $bits(hah_func_id_t) - $bits(csi_ap_id_t)-1:0] rsvd;
    csi_ap_id_t               ap_id;
    hah_func_id_t             pfunc_to_rfunc;
} pcq_afb_t;    

typedef union packed{
    pcq_ae_addr_t             addr;
    pcq_ap_t                  ap;
    pcq_afb_t                 afb; 
} pcq_addr_ap_afb_t;

typedef struct packed {
  logic [72-2-$bits(csi_intf_id_t)-$bits(pcq_addr_enc_mode_e)-$bits(pcq_addr_ap_afb_t)-1:0]  rsvd;  
  logic                     valid;
  csi_intf_id_t             csi_dst;
  logic                     csi_rro;
  pcq_addr_enc_mode_e       addr_enc_mode;
  pcq_addr_ap_afb_t         addr_ap_afb;
} pcq_mem_win_cfg_t; 

typedef logic [7:0] pcie_msg_code_t;

typedef struct packed {
    logic [PCQ_FN_TYPE_ID_NBITS-1:0] fn_type;
    pcie_msg_code_t                  msg_code;
} msg_key_t;

typedef struct packed {
    csi_intf_id_t       csi_dst;
    csi_msg_cookie_t    msg_cookie;
} msg_value_t;

typedef struct packed {
    logic           valid;
    msg_key_t       key;
    msg_value_t     value;
} pcq_msg_cfg_t;

typedef struct packed {
    logic rsvd;
    logic msix_mask;
    logic evt_pend;
    logic flr;
    logic msi_en;
    logic msix_en;
    logic bme;
} fnc_sts_data_t;

typedef struct packed {
    logic           ide_valid;
    logic           tbit;
    logic [ 2:0]    attr;
    logic           tph_present;
    logic [ 1:0]    tph_type;
    logic [ 7:0]    tph_st_tag;
    logic [15:0]    function_number;
    logic [15:0]    vector;
} pcie_interrupt_data_t;

typedef struct packed {
    logic             rsvd; 
    logic             pasidv;
    logic [19:0]      pasid;
    logic [11:0]      xmti;
} intc_psx_to_cdx_user_t;

// User Bits Definition
localparam PSX_TO_CDX_AWUSER_WIDTH         = $bits(intc_psx_to_cdx_user_t);
localparam PSX_TO_CDX_ARUSER_WIDTH         = PSX_TO_CDX_AWUSER_WIDTH;
localparam CDX_TO_PSX_AWUSER_WIDTH         = 81;
localparam CDX_TO_PSX_ARUSER_WIDTH         = 57;

// AXI Interconnect Definition
localparam AXI_INT_BURST_WIDTH             = 2;
localparam AXI_INT_CACHE_WIDTH             = 4;
localparam AXI_INT_LOCK_WIDTH              = 1;
localparam AXI_INT_PROT_WIDTH              = 3;
localparam AXI_INT_SIZE_WIDTH              = 3;
localparam AXI_INT_BRESP_WIDTH             = 2;

// Config Interconnect Definition
localparam AXIL_CSI_BRIDGE_MASTER_DATA_WIDTH    = 32;
localparam AXIL_CSI_BRIDGE_MASTER_ADDR_WIDTH    = 32;
localparam AXIL_CSI_BRIDGE_MASTER_USER_WIDTH    = 13;
localparam AXIL_PCIE_BRIDGE_SLAVE_DATA_WIDTH    = 32;
localparam AXIL_PCIE_BRIDGE_SLAVE_ADDR_WIDTH    = 16;
localparam AXIL_PCIE_BRIDGE_SLAVE_USER_WIDTH    = 0;
localparam AXIL_PSX_BRIDGE_SLAVE_DATA_WIDTH     = 32;
localparam AXIL_PSX_BRIDGE_SLAVE_ADDR_WIDTH     = 16;
localparam AXIL_PSX_BRIDGE_SLAVE_USER_WIDTH     = 13;
localparam AXIL_CSI_SLAVE_DATA_WIDTH            = 32;
localparam AXIL_CSI_SLAVE_ADDR_WIDTH            = 17;
localparam AXIL_CSI_SLAVE_USER_WIDTH            = 0;
localparam AXIL_EQDMA_SLAVE_DATA_WIDTH          = 32;
localparam AXIL_EQDMA_SLAVE_ADDR_WIDTH          = 16;
localparam AXIL_EQDMA_SLAVE_USER_WIDTH          = 0;
localparam AXIL_CDM_SLAVE_DATA_WIDTH            = 32;
localparam AXIL_CDM_SLAVE_ADDR_WIDTH            = 16;
localparam AXIL_CDM_SLAVE_USER_WIDTH            = 0;
localparam AXIL_HAH_SLAVE_DATA_WIDTH            = 32;
localparam AXIL_HAH_SLAVE_ADDR_WIDTH            = 16;
localparam AXIL_HAH_SLAVE_USER_WIDTH            = 13;
localparam AXIL_CDC_SLAVE_DATA_WIDTH            = 32;
localparam AXIL_CDC_SLAVE_ADDR_WIDTH            = 16;
localparam AXIL_CDC_SLAVE_USER_WIDTH            = 0;
localparam AXIL_DMAC_SLAVE_DATA_WIDTH           = 32;
localparam AXIL_DMAC_SLAVE_ADDR_WIDTH           = 16;
localparam AXIL_DMAC_SLAVE_USER_WIDTH           = 0;
localparam AXIL_DPU_SLAVE_DATA_WIDTH            = 32;
localparam AXIL_DPU_SLAVE_ADDR_WIDTH            = 16;
localparam AXIL_DPU_SLAVE_USER_WIDTH            = 0;
localparam AXIL_SCHED_SLAVE_DATA_WIDTH          = 32;
localparam AXIL_SCHED_SLAVE_ADDR_WIDTH          = 20;
localparam AXIL_SCHED_SLAVE_USER_WIDTH          = 0;

// Re-order Buffer
localparam REORDER_BUF_ADDR_WIDTH               = 10;
localparam REORDER_BUF_DATA_WIDTH               = 577;

typedef struct packed {
   logic             from_lpd; 
   logic [4:0]       stash_idx;
   logic             pasidv;
   logic [19:0]      pasid;
   logic [3:0]       csi_id;
   logic [15:0]      bdf;
   logic [11:0]      xmti;
} intc_axi_user_t;

localparam INTC_AXI_USER_WIDTH = $bits(intc_axi_user_t);

typedef enum logic {
  PCIE_RCB_64=0,
  PCIE_RCB_128=1
} pcie_rcb_t;

typedef enum logic[2:0] {
  PCIE_MPS_128=0,
  PCIE_MPS_256=1,
  PCIE_MPS_512=2,
  PCIE_MPS_1024=3,
  PCIE_MPS_2048=4,
  PCIE_MPS_4096=5
} pcie_mps_t;

typedef struct packed {
    logic [11:0]    xmti;
    logic           apb; 
    logic [3:0]     sel;
    logic [3:0]     be;
    logic           rd;
    logic           wr;
    logic [31:0]    adr;
    logic [31:0]    dat;
} cdx_trq_t;

typedef struct packed {
    logic            vld;
    logic [31:0]     dat;
    logic [1:0]      rsp; // 2'h0:OK, 2'h2:SLV_ERR, 2'h3:DEC_ERR
} cdx_tcp_t;

// in cdx5n_defines.vh
//`define AXIMM_RRESP_OK 2'b00
//`define AXIMM_RRESP_EXOK 2'b01
//`define AXIMM_RRESP_SLVERR 2'b10
//`define AXIMM_RRESP_DECERR 2'b11


// FIXME Move to separate indirect bus define?
    `define    MAX_IND_BUS_REG 8

    localparam MAX_IND_BUS_REG= `MAX_IND_BUS_REG;
    localparam MAX_IND_BUS_SZ=16;


    typedef logic [31:0] csr_data_t;
    localparam CSR_DATA_SIZE = $bits(csr_data_t);

    typedef enum logic [1:0] {
        CTXT_CMD_CLR=0, CTXT_CMD_WR, CTXT_CMD_RD, CTXT_CMD_INV
    } ind_bus_cmd_e;

    typedef logic [12:0]         ind_bus_max_id_t;
    typedef enum logic [5:0]  {
        IND_BUS_SELC_PCIE_BRIDGE0_FNC_STS             = 6'h10,
        IND_BUS_SELC_PCIE_BRIDGE0_ADDR_TRANS_WINDOWS  = 6'h11,
        IND_BUS_SELC_PCIE_BRIDGE0_FNC_CFG             = 6'h12,
        IND_BUS_SELC_PCIE_BRIDGE0_BAR_CFG             = 6'h13,
        IND_BUS_SELC_PCIE_BRIDGE1_FNC_STS             = 6'h14,
        IND_BUS_SELC_PCIE_BRIDGE1_ADDR_TRANS_WINDOWS  = 6'h15,
        IND_BUS_SELC_PCIE_BRIDGE1_FNC_CFG             = 6'h16,
        IND_BUS_SELC_PCIE_BRIDGE1_BAR_CFG             = 6'h17,
        IND_BUS_SELC_PCIE_BRIDGE2_FNC_STS             = 6'h18,
        IND_BUS_SELC_PCIE_BRIDGE2_ADDR_TRANS_WINDOWS  = 6'h19,
        IND_BUS_SELC_PCIE_BRIDGE2_FNC_CFG             = 6'h1a,
        IND_BUS_SELC_PCIE_BRIDGE2_BAR_CFG             = 6'h1b,
        IND_BUS_SELC_PCIE_BRIDGE3_FNC_STS             = 6'h1c,
        IND_BUS_SELC_PCIE_BRIDGE3_ADDR_TRANS_WINDOWS  = 6'h1d,
        IND_BUS_SELC_PCIE_BRIDGE3_FNC_CFG             = 6'h1e,
        IND_BUS_SELC_PCIE_BRIDGE3_BAR_CFG             = 6'h1f,
        IND_BUS_SELC_PSX_BRIDGE_A2C_APERTURE_ID       = 6'h20,
        IND_BUS_SELC_PSX_BRIDGE_A2C_APERTURE_CONFIG   = 6'h21,
        IND_BUS_SELC_PSX_BRIDGE_A2C_APERTURE_WINDOWS  = 6'h22,
        IND_BUS_SELC_PSX_BRIDGE_C2A_APERTURE_TABLE    = 6'h23,
        IND_BUS_SELC_PSX_BRIDGE_C2A_WAXID_TABLE       = 6'h24,
        IND_BUS_SELC_PSX_BRIDGE_C2A_RAXID_TABLE       = 6'h25,
        IND_BUS_SELC_PSX_BRIDGE_STASH_TABLE           = 6'h26,
        IND_BUS_SELC_PSX_BRIDGE_C2A_GIC_ADDR          = 6'h27, // FIXME What is this for?
        IND_BUS_SELC_PSX_BRIDGE_IRQ_CLIENT_CFG       =  6'h28,  // 4 clients available
        IND_BUS_SELC_PCIE_BRIDGE0_MSG_CFG             = 6'h30,
        IND_BUS_SELC_PCIE_BRIDGE1_MSG_CFG             = 6'h31,
        IND_BUS_SELC_PCIE_BRIDGE2_MSG_CFG             = 6'h32,
        IND_BUS_SELC_PCIE_BRIDGE3_MSG_CFG             = 6'h33,
        IND_BUS_SELC_PSX_BRIDGE_DDR_MAP_TABLE         = 6'h34
    } ind_bus_sel_t;
 

    typedef struct packed {
        logic [$bits(csr_data_t)-$bits(ind_bus_max_id_t)-$bits(ind_bus_cmd_e)-$bits(ind_bus_sel_t)-1 -1 :0] pad;
        ind_bus_max_id_t        id;
        ind_bus_cmd_e           op;
        ind_bus_sel_t           sel;
        // Writes will be dropped when busy=1.
        logic                   busy;
    } ind_bus_cmd_t;

    typedef struct packed {
        csr_data_t [MAX_IND_BUS_REG-1:0]     data;
    //    csr_data_t [MAX_IND_BUS_REG-1:0]     mask;
        ind_bus_cmd_t                        cmd;
        logic                                valid;
    } ind_bus_req_t;

    typedef struct packed {
        csr_data_t [MAX_IND_BUS_REG-1:0]     data;
        logic                             valid;
    } ind_bus_cmp_t;

typedef struct packed {
    logic                  pasid_en;
    logic [21:0]           pasid;
    logic [1:0]            at;
    logic                  spl;
    logic                  err;    // request with error detected
    logic                  sec;    // AXI MM only
    logic [3:0]            host_id; // AXI MM only
    logic [63:0]           adr;
    logic [8:0]            rid;
    logic [27:0]           byte_len;   // byte length
    logic [9:0]            did;
    logic [15:0]           fnc;        // function/QID  Keep this in LSB
} pcie_brg_rrq_t;

typedef struct packed {
    logic            sop;
    logic            eop;
    logic            wbk;
    logic [4:0]      err; // XDMA mode only
    logic [4:0]      errc;// Encoded error
    //logic [`DAT_WIDTH/32-1:0] wen; // dword write enable
    logic [8:0]    rid;
    logic [9:0]    did;
    logic [5:0]               lba;    // Last beat length adjustment (AXI ST C2H)
    logic [512/8-1:0]  par;
    logic [512-1:0]    dat;
} pcie_brg_rcp_t;

typedef struct packed {
    logic                  gen_sop;
    logic [9-1:0] rid;
    logic [4-1:0] chn;
    logic [8:0]            btlen;   // beatlen
    logic [10-1:0] did;
    logic [4:0]            errc;
    logic [3:0]            err;
} pcie_brg_rcp_err_t;

typedef struct packed {
    logic                  pasid_en;
    logic [21:0]           pasid;       
    logic [3:0]            host_id;
    logic [1:0]            at;
    logic                  err;
    logic                  sec;    // AXI MM only
    logic [64-1:0]         adr;
    logic [9-1:0]          rid;
    logic [28-1:0]         byte_len;   // byte length
    logic [5:0]            aln;        // Source alignment
    logic                  sop;
    logic                  eop;
    logic                  eod;
    logic                  eor;
    logic [23:0]           fnc; 
} pcie_brg_wrq_t;

typedef struct packed {
    logic                         dbe;  // RAM dbe error detected
    logic    [512/8-1:0]   par;
    logic    [512-1:0]     dat;
} pcie_brg_wpl_t;

typedef struct packed {
    logic    [8:0]             rid;
    logic    [4:0]             err;
} pcie_brg_wcp_t;

typedef struct packed {
    logic   [12:0]        fnc;
    logic                 vld;
} pcie_brg_usr_flr_if_in_t;

typedef struct packed {
    logic [12:0]         fnc;
    logic                vld;
} pcie_brg_usr_flr_if_out_t;

typedef struct packed {
    logic  [11-1:0]             ack;
    logic                       fail;
// No completion function needed 
// legacy mode supports only function 0.
// new mode supports 1 outstanding request at a time
} pcie_brg_usr_irq_if_out_t;

typedef struct packed {
    logic                       vld;
    pcie_brg_host_id_t          host_id;
    logic  [11-1:0]             vec;
    logic  [12:0]               fnc;
    logic  [1:0]                pnd;
} pcie_brg_usr_irq_if_in_t;

typedef struct packed {
   logic [31:0]		timer_tick;
   logic [31:0]		timeout_threshold;
} pcie_brg_attr_dma_iep_timer;


    typedef struct packed {
        logic [31-$bits(pcie_brg_host_id_t):0]    rsv;         // Reserved
        pcie_brg_host_id_t                        bdg_host_id; // Host_id for bridge 
    } pcie_brg_bdg_host_id_t;

    typedef struct packed {
        logic   [29:0]          rsvd;
        logic                   lgcy_intr_pending;   // 1'b1: pending legacy interrupt; 1'b0: no pending legacy interrupt
        logic                   en_lgcy_intr;        // 1'b1: enable the legacy interrupt; 1'b0: disable the legacy interrupt
    } pcie_brg_interrupt_cfg_t;

    typedef struct packed {
        pcie_brg_interrupt_cfg_t      reg_glbl_intr_cfg;
        pcie_brg_host_id_t [15:0]     reg_glbl_host_id;
        pcie_brg_bdg_host_id_t        reg_glbl_bdg_host_id;
        logic [63:0]                   reg_aximm_intr_dest_addr;
    } pcie_brg_reg_t;

typedef struct packed {
    pcie_brg_host_id_t          host_id;
    logic [1:0]                 pend;
    logic [31:0]                vec;
    pcie_brg_fnid_t             fnc;
    logic                       req;
} pcie_brg_interrupt_msix_req_t;

typedef struct packed {
    logic                       fail;
    logic                       sent;
} pcie_brg_interrupt_msix_ack_t;

    typedef struct packed {
        logic [31:0]        parity;
        logic               discontinue;
        logic [2:0]         eop_dptr1;
        logic               eop1;
        logic [2:0]         eop_dptr0;
        logic               eop0;
        logic               sop1;
        logic               sop0;
        logic [31:0]        byte_en;
    } pcie_brg_axis_tuser256_t;

    typedef struct packed {
        logic [63:0]        parity;
        logic               discontinue;
        logic [3:0]         eop_dptr3;
        logic [3:0]         eop_dptr2;
        logic [3:0]         eop_dptr1;
        logic [3:0]         eop_dptr0;
        logic               eop3;
        logic               eop2;
        logic               eop1;
        logic               eop0;
        logic [1:0]         sop_ptr3;
        logic [1:0]         sop_ptr2;
        logic [1:0]         sop_ptr1;
        logic [1:0]         sop_ptr0;
        logic               sop3;
        logic               sop2;
        logic               sop1;
        logic               sop0;
        logic [63:0]        byte_en;
    } pcie_brg_axis_tuser512_t;

    localparam PCIE_BRG_CMN_GLBL_SIZE       = 512;
    localparam PCIE_BRG_CMN_GLBL_ABITS      = $clog2(PCIE_BRG_CMN_GLBL_SIZE);
    typedef logic [PCIE_BRG_CMN_GLBL_ABITS:2] pcie_brg_csr_addr_t;
    typedef enum pcie_brg_csr_addr_t {
        PCIE_BRG_REG_A     = 'h0,
        PCIE_BRG_RNG_SZ_A[16],         
        //PCIE_BRG_STATUS_A[16],        
        //PCIE_BRG_CONFIG_A[16],       
        PCIE_BRG_SCRATCH_A,                     // Byte Offset: 0x100 Separate register for each PF
        PCIE_BRG_ERR_STAT,
        PCIE_BRG_ERR_MASK,
        PCIE_BRG_DSC_CFG_A,
        PCIE_BRG_DSC_ERR_STS_A,
        PCIE_BRG_DSC_ERR_MSK_A,
        PCIE_BRG_DSC_ERR_LOG0_A,
        PCIE_BRG_DSC_ERR_LOG1_A,
        PCIE_BRG_TRQ_ERR_STS_A,
        PCIE_BRG_TRQ_ERR_MSK_A,
        PCIE_BRG_TRQ_ERR_LOG_A,
        PCIE_BRG_DSC_DBG_DAT0_A,
        PCIE_BRG_DSC_DBG_DAT1_A,
        PCIE_BRG_DSC_DBG_CTL_A,
        PCIE_BRG_DSC_ERR_LOG2_A,
        PCIE_BRG_DBG_CFG,
        PCIE_BRG_DBG_REG[16],
        PCIE_BRG_INTERRUPT_CFG,
        PCIE_BRG_HOST_ID_A[16],              
        PCIE_BRG_BDG_HOST_ID,
        PCIE_BRG_AXIMM_INTERRUPT_DEST_ADDR_A[2],
        PCIE_BRG_FAB_ERR_LOG_A,
        PCIE_BRG_REQ_ERR_STAT_A,
        PCIE_BRG_REQ_ERR_MASK_A
    } pcie_brg_csr_addr_e;

typedef struct packed {
    logic                  pasid1_pr;   // 182 Privilege
    logic                  pasid0_pr;   // 181 Privilege
    logic                  pasid1_ex;   // 180 Execute
    logic                  pasid0_ex;   // 179 Execute
    logic    [19:0]        pasid1;      // 178:159 PASID 1 (20-bits) 
    logic    [19:0]        pasid0;      // 158:139 PASID 0 (20-bits) 
    logic                  pasid1_en;   // 138    PASID TLP Valid 1    
    logic                  pasid0_en;   // 137    PASID TLP Valid 0            
    logic    [63:0]        par;         // 136:73 Parity filled later
    logic    [5:0]         seq1;        // 72:67  Sequence Num 1
    logic    [5:0]         seq0;        // 66:61  Sequence Num 0
    logic    [23:0]        tph;         // 60:45  TPH St Tag
                                        // 44:43  TPH Ind Tag
                                        // 42:39  TPH Type
                                        // 38:37  TPH Present
    logic                  disc;        // 36     Discontinue
    logic    [3:0]         eop1_ptr;    // 35:32  EOP 1 Ptr
    logic    [3:0]         eop0_ptr;    // 31:28  EOP 0 Ptr
    logic                  eop1;        // 27     EOP 1
    logic                  eop0;        // 26     EOP 0
    logic    [1:0]         sop1_ptr;    // 25:24  SOP 1 Ptr
    logic    [1:0]         sop0_ptr;    // 23:22  SOP 0 Ptr
    logic                  sop1;        // 21     SOP 1
    logic                  sop0;        // 20     SOP 0
    logic    [3:0]         adr;         // 19:16  Address offset - Address aligned mode only
    logic    [3:0]         lbe1;
    logic    [3:0]         lbe0;
    logic    [3:0]         fbe1;
    logic    [3:0]         fbe0;
} pcie_brg_rq_usr_straddle_t;

typedef struct packed {
    logic    [97:0]        rsv2;       // 182:85
    logic                  pasid_pr;   // 84 Privilege
    logic                  pasid_ex;   // 83 Execute
    logic    [19:0]        pasid;      // 82:63 PASID 0 (20-bits) 
    logic                  pasid_en;   // 62    PASID TLP Valid 0    
    logic    [1:0]         rsv0;       // 61:60 
    logic    [31:0]        par;        // 59:28
    logic    [3:0]         seq;        // 27:24
    logic    [11:0]        tph;        // 23:12
    logic                  dis;        // 11
    logic    [2:0]         adr;        // 10:8
    logic    [3:0]         lbe;        // 7:4
    logic    [3:0]         fbe;        // 3:0
} pcie_brg_rq_usr_nostraddle_t;

typedef union packed {
    pcie_brg_rq_usr_straddle_t        rqu_str;
    pcie_brg_rq_usr_nostraddle_t      rqu_nstr;
} pcie_brg_rq_usr_t;

typedef struct packed { 
    logic            ecrc;
    logic     [2:0]        attr;        
    logic    [2:0]        tc;    
    logic            rid_en;
    logic    [15:0]        cpl_id;
    logic    [7:0]        tag;
    logic    [15:0]        req_id;
    logic            poison;
    logic    [3:0]        req;
    logic    [10:0]        len;        
    logic    [63:0]        adr;
} pcie_brg_rq_hdr_fields_t;

typedef struct packed { 
    logic    [23:0]        dw3_misc;
    logic    [7:0]        tag;
    logic    [16:0]        dw2_misc;
    logic    [3:0]        req;
    logic    [10:0]        len;        
    logic    [63:0]        adr;
} pcie_brg_rq_hdr_compact_t;

typedef struct packed { 
    logic    [31:0]        dw3;
    logic    [31:0]        dw2;
    logic    [31:0]        dw1;
    logic    [31:0]        dw0;
} pcie_brg_rq_hdr_dwords_t;

typedef union packed {
    pcie_brg_rq_hdr_fields_t        rqh_f;
    pcie_brg_rq_hdr_compact_t      rqh_c;
    pcie_brg_rq_hdr_dwords_t      rqh_d;
} pcie_brg_rq_hdr_t;


typedef logic [47:0]  cdx_tel_bus_t;   //Type declaration for Generic Telemeter Bus

typedef logic [63:0]  cdx_tel_trig_t;  //Type declaration for inter Telem block trigger 
                                       // FIXED SIZE: [31:0] Qualified Filter event and [63:32] Stop event signals
                                       
typedef logic [511:0] cdx_tel_st_out_t;//Type declaration for Telemeter stream output

//
typedef struct packed {
    logic       valid;
    logic [6:0] err_type;  
    union packed {
        struct packed {
            logic [5:0]          rsv;                   // 6
            logic [31:0]         dw_addr_31_0;          // 32
            csi_pcie_addr_type_t addr_type;             // 2
            csi_func_t           requester;             // 16
        } rdwr;                                         // 56
        struct packed {
            logic[20:0]              rsv;               // 21
            csi_int_vector_t         vector;            // 16
            csi_interrupt_msg_type_t msg_type;          // 3
            csi_func_t               requester;         // 16
        } intr;
        struct packed {
            logic [13:0]             rsv;               // 14
            logic [2:0]              fmt;               // 3
            logic [4:0]              ptype;             // 5
            logic [9:0]              length;            // 10
            csi_pcie_message_code_t  message_code;      // 8
            csi_func_t               requester;         // 16
        } msg;                                          // --56
        struct packed {
            logic [0:0] is_last;                        // 1
            logic [0:0] is_first;                       // 1
            logic [9:0] byte_count_9_0;                 // 10
            logic [6:0] lower_addr;                     // 7
            csi_tag_t tag;                              // 10
            csi_cpl_status_t status;                    // 3
            csi_pcie_addr_type_t addr_type;             // 2
            csi_cap_type_t request_type;                // 6
            csi_func_t requester;                       // 16
        } cmpl;                                         // --56
    } ptype;
}  csi_small_hdr_log_t;

typedef union packed {
    logic [63:0]          check_bits;
    csi_small_hdr_log_t   check_log;
}  csi_small_hdr_log_width_check_t;


`endif


