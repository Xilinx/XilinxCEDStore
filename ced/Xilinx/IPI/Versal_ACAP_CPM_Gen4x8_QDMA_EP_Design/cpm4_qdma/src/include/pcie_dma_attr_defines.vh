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
//                       $Author: mkelley $
//                       $DateTime: 2016/07/08 17:50:57 $
//                       $Change: 7769758 $
//       Description:
//
//////////////////////////////////////////////////////////////////////////////

`ifndef PCIE_DMA_ATTR_DEFINES_VH
`define PCIE_DMA_ATTR_DEFINES_VH

typedef struct packed {
    logic  [255:213] unused;                       //255:213
    logic           dis_pfch_evict_cache_fix;      //212      // If set, disable the prefetch eviction fix in cache
    logic           dis_pfch_evict_lru_fix;        //211      // If set, disable the prefetch eviction fix in lru
    logic           dis_crdt_coal_depth_fix;       //210      // If set, disable the credit coal fifo depth fix
    logic           dis_timer_stall_fix;           //209      // If set, disable the mdma timer stall fix
    logic  [3:0]    qinv_cnt_limit;                //208:205  // If qinv_limit_en is set, this is the limit of qinv from dsc engine through c2h st pfch_evt_fifo that is allowed.
    logic           qinv_limit_en;                 //204      // If set, limit the number of qinvalidation in the pipe from dsc engine through C2H ST pfch_evt_fifo
    logic           qinv_arb_stall;                //203      // If set, allow descriptor fetching to continue even if tm_dsc_sts is full.
    logic           brdg_rro_en;                   //202      // If set, enable relaxed ordering for all bridge slave reads to pcie.
    logic           mm_wbrq_ovf_fix_dis;           //201      // If set, disable fix to prevent qdma writeback fifo overflow in the MM engine.
    logic           pcie_mrs_reg_en;               //200      // If set, pcie max read size used will be defined by register
    logic           pcie_mpl_reg_en;               //199      // If set, pcie max payload used will be define by register
    logic           bdg_mst_rw_rlx_dis;            //198      // If set, disable the fix to bypass r/w ordering based on attr[1]
    logic           dis_wrb_prty_chk_fix;          //197      // If set, disable the fix to check WRB parity C2H WRB
    logic           dis_h2c_sbe_dbe_err_fix;       //196      // If set, disable the fix to handle sbe/dbe on h2c-st
    logic           dis_wrb_bad_cidx_chk_fix;      //195      // If set, disable the fix to check bad cidx update in C2H WRB
    logic           dis_xdma_wcp_err_bsy_clr;      //194      // If set, disable fix to clear busy bit in event of wcp error.  Needed for surprise xdma  FLR.
    logic           dis_acc_irq;                   //193      // If set, disable MM/H2C ST periodic interrupts in wb_acc mode
    logic           dis_h2c_wrb_on_src_err_fix;    //192      // If set, disable the fix to send wrb on h2c src err
    logic           sw_crdt_fix_dis;               //191      // If set, disable the sw_crdt fix in c2h_pfch_crdt
    logic           fix_dbe_parity_dis;            //190      // If set, disable fix for EDT-985612, generate invalid parity on dbe at write interfaces
    logic           pcie_rq_vf_flr_check_dis;      //189      // If set, flr for vfs will be assumed to be false in dma_pcie_req
    logic           pcie_rq_pf_flr_check_dis;      //188      // If set, flr for pfs will be assumed to be false in dma_pcie_req
    logic           mm_err_wbk_fix_dis;            //187      // If set, disable the fix for the write completion from the DMA Write Engine
    logic           dis_c2h_ctxt_mgr_fix;          //186      // If set, disable the C2H fix for ctxt mgr, affects both wrb and pfch
    logic           full_upd_fix_dis;              //185      // If set, disable the full_upd feature in the C2H-ST WRB
    logic           slv_bresp_fix_dis;             //184      // If set, disable the fix for Slave Bresp (1: slv_wrq_commit; 0: slave_wcp_vld)
    logic           wr_cmp_fix_dis;                //183      // If set, disable the fix for the write completion from the DMA Write Engine
    logic           rcv_crd_chk_dis;               //182      // If set, disable dsc engine received credit check
    logic           cfg_space_delay_en;            //181      // If set, enable Bridge register to control config space enable in the EP mode
    logic  [31:0]   misc_cap;                      //180:149  // Misc capability registers, register accessible
    logic           st_rx_msg_if_en;               //148      // If set, send vdm to the streaming i/f
    logic           exp_rom_bar_to_axil;           //147      // If set, send hits to bar 6 (exp rom) to axi-lite
    logic           pcie_rq_vf_bme_check_dis;      //146      // If set, bme for vfs will be assumed to be true.
    logic           dsc_upd_ovf_dis;               //145      // If set, disable descriptor overflow detection.
    logic           tm_dsc_sts_pidx_en;            //144      // If set, send out pidx instead of new descriptors available.
    logic           dsc_ctxt_is_mm_en;             //143      // If set, the interface (st or mm) is determined by sw_ctxt.sts.is_mm instead of dsc_sz.
    logic           trq_timeout_dat;               //142      // If set, return all 1 for tcp timeout data, else all 0
    logic           trq_timeout_rsp;               //141      // If set, return all slv_err for tcp timeout response, else okay
    logic           dsc_ctxt_err_on_rcp_ur_ca_dis; //140      // If set, the context error bit will not be set if a dsc fetch receives an ur_ca error including bme check failure
    logic           cfg_mgmt_ep_wr_dis;            //139      // 1'b1: Disable CFG MGMT Write in EP and back to legacy; 1'b0: Enable
    logic           axi_slv_brdge_range;           //138      // 1'b1: 16M, 1'b0: 256M 
    logic           dsc_ctxt_err_on_rcp_flr_dis;   //137      // If set, the context error bit will be set if a dsc fetch receives an flr abort
    logic           dma_rq_0len_dis;               //136      // If set, disble 0 length read support.
    logic           ign_byp_irq_arm;               //135      // If set, in bypass mode ignore the irq arm bit
    logic           dma_mm_linkdown_reset_dis;     //134      // If set, do not reset mm engine rrq, wrq fifos
    logic           rsv_use_h2c_data_aln;          //133      // Reserved. Was: If set, H2C data to AXIS will be aligned and packed
    logic           dma_rst_rc_rdy;                //132      // If set, assert rc_tready when dma in under reset.
    logic           ign_pidx_upd_on_irq_arm;       //131      // If irq_arm bit is set by trq write, do not update the pidx
    logic           use_stm_dsc_format;            //130      // Makes QDMA work on STM descriptor format
    logic           dma_aximm_rsp_clr;             //129      // Clear aximm rsp count for channel when run bit is asserted.
    logic           dsc_qinv_on_err_dis;           //128      // Invalidate queue on error disable
    logic           xdma_drain_dat_en;             //127      // Enable draining of dat when run bit is not set for xdma.  Set to 1 for Evereset
    logic           xdma_drain_dsc_en;             //126      // Enable draining of dsc when run bit is not set for xdma.  Set to 1 for Evereset
    logic           disable_port_id_check;         //125      // Disable the port_id check
    logic           wb_sts_all;                    //124      // All writeback check results from dsc engine are output to wb sts port
    logic  [11:0]   brdg_slv_wr_pasid_offset;      //123:112  // Pasid index offset for bridge slave write requests if shared_rdwr_pasid_dis is set
    logic           brdg_slv_shared_rdwr_pasid_dis;//111      // Enable different pasid for rd and writes from bridge slave.
    logic           dsc_stall_irq_fl_dis ;//110               // Disable stall descriptor context if dsc engine has too many irqs to send.
    logic           axi_parity_chk_dis   ;//109               // Disable AXI slave parity checks
    logic  [7:0]    slv_fnc_msk          ;//108:101           // Mask for function bits received by aximm slave. Useful if number of functions supported needs less than 8 bits.  Upper bits can then be used for SMID
    logic           dsc_rcp_evt_pri      ;//100               // Rcp events have priority for dsc context lookup
    logic           fabric_reset_en      ;//99                // Enable reset from fabric // Not hooked up to reset yet
    logic           rrq_disable_en       ;//98                // Block new read requests on RQ timeout or register write
    logic           shared_rdwr_pasid_dis;//97                // Reads and writes for a qid/function will share the same pasid index.
    logic  [11:0]   brdg_slv_pasid_offset;//96:85             // Pasid index offset for bridge slave requests
    logic           fab_wb_dis           ;//84                // Send out mdma writeback check completions qid/cidx through the descriptor bypass output interface.
    logic           axis_h2c_ext_cmp_en  ;//83                // Use external signal to indicating h2c stream packet is complete, for the purpose of issueing writeback and interrupts.
    logic           axim_auser_mode      ;//82                // Everest only attribute, 1 will pass {vfg, vfg_off} instead of address[63:50]
    logic           dma_bar_ext_en       ;//81                // Enable DMA bar aperture to extranal MM or external Lite interface.
    logic  [4:0]    tcp_timeout_exp      ;//80:76             // Exponential timer for TRQ completion timeout;  2^exp,  0 = disabled
    logic           brdg_slv_pasid_en    ;// 75               // Pasid_en below must also be set to enable pasid for the bridge slave
    logic           system_id_ovr        ;// 74
    logic  [15:0]   system_id            ;//73:58             // System ID csr[15:0]
    logic           rq_flr_check_dis     ;// 57               // Disable RQ FLR check
    logic           pasid_en             ;// 56               // Enable PASID
    logic  [2:0]    vf_bar_num           ;//55:53             // Bar number of VFs
    logic           pcie_rc_unmask_uc    ; //52               // Unmask unexpected completions coming out or dma_pcie_rc
    logic           dsc_ecc_chk_dis      ; //51               // Disable ECC check
    logic           mdma_one_err_wb_dis  ; //50               // If set, allow more writebacks for queue even if writeback with error was sent already
    logic           mdma_dsc_wb_chk_all  ; //49               // Set wb_chk (if ctxt enabled) on all descriptors of fetch even if not last
    logic           mdma_dsc_wb_imm_all  ; //48               //  Set wb_imm (if ctxt enabled) on all descriptors of fetch even if not last
    logic           xdma_byp_eng_flr_done; //47               // Ignore xdma engines for flr_done
    logic           mdma_eng_err_halt    ; //46               // Halt mdma mm engine on logging error in status reg
    logic           mdma_sw_ctxt_clr_all ; //45               // Clear hw and crd ctxt if sw ctxt cleared
    logic  [3:0][3:0]  xdma_c2h_axi_wr_cache;//44:41          // awcache for C2H writeback to AXI
    logic  [3:0]       xdma_c2h_axi_wr_sec  ;//28             // awprot for C2H writeback to AXI
    logic  [3:0][3:0]  xdma_h2c_axi_rd_cache;//23             // arcache for H2C writeback to AXI
    logic  [3:0]       xdma_h2c_axi_rd_sec ;//8               // arprot for H2C writeback to AXI
    logic          mgmt_flr_done_en     ;   //4               // flr_done needs mgmt ifc flr done bit
    logic  [3:0]   mgmt_flr_done_src_dis;   //3:0             // Disable mgmt flr_done access per PF
} attr_spare_t;

// FIXME make a struct with fields
// Used Spare Bits
`define   SPARE_SYSTEM_ID_OVR          74
`define   SPARE_SYSTEM_ID             73:58             // System ID csr[15:0]
`define   SPARE_RQ_FLR_CHECK_DIS       57               // Disable RQ FLR check
`define   SPARE_PASID_EN               56               // Enable PASID
`define   SPARE_VF_BAR_NUM            55:53             // Bar number of VFs
`define   SPARE_PCIE_RC_UNMASK_UC      52               // Unmask unexpected completions coming out or dma_pcie_rc
//`define   SPARE_ECC_DIS                51               // Disable ECC check
`define   SPARE_MDMA_ONE_ERR_WB_DIS    50               // If set, allow more writebacks for queue even if writeback with error was sent already
//`define   SPARE_MDMA_DSC_WB_CHK_ALL    49               // Set wb_chk (if ctxt enabled) on all descriptors of fetch even if not last
//`define   SPARE_MDMA_DSC_WB_IMM_ALL    48               //  Set wb_imm (if ctxt enabled) on all descriptors of fetch even if not last
`define   SPARE_XDMA_BYP_ENG_FLR_DONE  47               // Ignore xdma engines for flr_done
`define   SPARE_MDMA_ENG_ERR_HALT      46               // Halt mdma mm engine on logging error in status reg
`define   SPARE_MDMA_SW_CTXT_CLR_ALL   45               // Clear hw and crd ctxt if sw ctxt cleared
//`define   SPARE_XDMA_C2H3_AXI_WR_CACHE 44:41            // awcache for C2H writeback to AXI
//`define   SPARE_XDMA_C2H2_AXI_WR_CACHE 40:37            // awcache for C2H writeback to AXI
//`define   SPARE_XDMA_C2H1_AXI_WR_CACHE 36:33            // awcache for C2H writeback to AXI
//`define   SPARE_XDMA_C2H0_AXI_WR_CACHE 32:29            // awcache for C2H writeback to AXI
//`define   SPARE_XDMA_C2H3_AXI_WR_SEC   28               // awprot for C2H writeback to AXI
//`define   SPARE_XDMA_C2H2_AXI_WR_SEC   27               // awprot for C2H writeback to AXI
//`define   SPARE_XDMA_C2H1_AXI_WR_SEC   26               // awprot for C2H writeback to AXI
//`define   SPARE_XDMA_C2H0_AXI_WR_SEC   25               // awprot for C2H writeback to AXI
//`define   SPARE_XDMA_H2C3_AXI_RD_CACHE 24:21            // arcache for H2C writeback to AXI
//`define   SPARE_XDMA_H2C2_AXI_RD_CACHE 20:17            // arcache for H2C writeback to AXI
//`define   SPARE_XDMA_H2C1_AXI_RD_CACHE 16:13            // arcache for H2C writeback to AXI
//`define   SPARE_XDMA_H2C0_AXI_RD_CACHE 12:9             // arcache for H2C writeback to AXI
//`define   SPARE_XDMA_H2C3_AXI_RD_SEC   8                // arprot for H2C writeback to AXI
//`define   SPARE_XDMA_H2C2_AXI_RD_SEC   7                // arprot for H2C writeback to AXI
//`define   SPARE_XDMA_H2C1_AXI_RD_SEC   6                // arprot for H2C writeback to AXI
//`define   SPARE_XDMA_H2C0_AXI_RD_SEC   5                // arprot for H2C writeback to AXI
`define   SPARE_MGMT_FLR_DONE_EN      4                 // flr_done needs mgmt ifc flr done bit
`define   SPARE_MGMT_FLR_DONE_SRC_DIS 3:0               // Disable mgmt flr_done access per PF

// Should be defined so default is 0.

// DMA PF Attributes
typedef struct packed {
    logic    [3:0]       ch_alloc;
    logic                rd_sec;
    logic                wr_sec;
    logic    [3:0]       rd_cache;        // AXI MM
    logic    [3:0]       wr_cache;        // AXI MM
    logic                vf_rd_sec;
    logic                vf_wr_sec;
    logic    [3:0]       vf_rd_cache;     // AXI MM
    logic    [3:0]       vf_wr_cache;     // AXI MM
    //logic    [1:0]       multq_chbits;
    //logic    [9:0]       multq_maxq;      // MAX 256 queues per channel
    //logic    [2:0]       multq_bits;
    //logic    [10:0]      vfmaxq;          // MAX 1024 queues per vf
    //logic    [2:0]       multq_vfqbits;
    logic    [7:0]       num_vfs;
    logic    [7:0]       firstvf_offset;
} attr_dma_pf_t;

localparam PCIEBR_MAX_BAR_LEN=64;
typedef logic [PCIEBR_MAX_BAR_LEN-1:0]      pciebr_bar_offset_t;
// DMA PCIeBAR to AXIBAR Attributes
typedef struct packed {
    logic    [63:12]     bar;
    logic                rd_sec;
    logic                wr_sec;
    logic    [3:0]       rd_cache;
    logic    [3:0]       wr_cache;
    logic    [6:0]       len;
    logic    [63:12]     bar_vf;
    logic                rd_sec_vf;
    logic    [3:0]       rd_cache_vf;
    logic                wr_sec_vf;
    logic    [3:0]       wr_cache_vf;
    logic    [6:0]       len_vf;
} attr_dma_pciebar2axibar_pf_t;

// DMA AXIBAR to PCIeBAR Attributes
typedef struct packed {
    logic    [63:0]       base;
    logic                 as;
    logic    [2:0]        attr;
    logic    [63:0]       highaddr;
    logic    [63:0]       bar;
    logic                 sec;
} attr_dma_axibar2pciebar_t;

// DMA General Attributes 
// Interface Struct - Do not change
typedef struct packed {
    logic    [63:0]       axi_slv_brdg_base_addr;
    logic    [63:0]       axi_slv_multq_base_addr;
    logic    [63:0]       axi_slv_xdma_base_addr;
    logic                 enable;
    logic                 xdma_irq; // Use non-SRIOV XDMA user interrupt interface
    logic                 enable_secure;
    logic                 bypass_msix;  // Not used
    logic    [2:0]        data_width;
    logic                 metering_enable;
    logic    [5:0]        mask50; 
    logic                 root_port;
    logic                 msi_rx_decode_en;
    logic                 slv_timeout_err_dis;
    logic                 cfg_timeout_err_dis;
    logic                 cfg_ur_err_dis;
    logic                 cfg_crs_sw_visible_en;
    logic                 pcie_if_parity_check;
    logic                 pcie_rq_bme_check_dis;
    logic    [3:0][5:0]   pf_barlite_int;
    logic    [3:0][5:0]   pf_vf_barlite_int;
    logic    [3:0][5:0]   pf_barlite_ext;
    logic    [3:0][5:0]   pf_vf_barlite_ext;
    logic                 ram_init_dis;
    logic                 axibar_notranslate;
    logic                 axi_mm_dma_steering_mode; // Hard IP Only
    logic                 axi_mm_dsc_port; // Hard IP Only
    logic                 axi_mm_bridge_port; // Hard IP Only
    logic    [2:0]        pciebar_num;
    logic    [3:0][3:0]   ch_rd_cache;
    logic    [3:0][3:0]   ch_wr_cache;
    logic    [3:0]        ch_rd_sec;
    logic    [3:0]        ch_wr_sec;
    logic    [3:0]        ch_en;
    logic    [3:0][1:0]   ch_pfid;
    logic    [3:0]        ch_multq;
    logic    [3:0]        ch_stream;
    logic    [3:0]        ch_c2h_axi_dsc; // Not Used
    logic    [3:0]        ch_h2c_axi_dsc; // Not Used
    logic    [3:0]        ch_mm_port;
    logic    [11:0]       multq_max;      // The number of queues supported, minus 1
    logic                 trq_src_dis;
    logic                 irq_gen_via_reg;
    logic    [1:0]        xdma_pf;
    logic                 cq_rcfg_en;
    logic                 rq_rcfg_en;
    logic    [255:0]      mdma_cfg;
    logic    [255:0]      spare;
} attr_dma_t;

// Internal interface with struct for spares
typedef struct packed {
    logic    [63:0]       axi_slv_brdg_base_addr;
    logic    [63:0]       axi_slv_multq_base_addr;
    logic    [63:0]       axi_slv_xdma_base_addr;
    logic                 enable;
    logic                 xdma_irq; // Use non-SRIOV XDMA user interrupt interface
    logic                 enable_secure;
    logic                 bypass_msix;  // Not used
    logic    [2:0]        data_width;
    logic                 metering_enable;
    logic    [5:0]        mask50; 
    logic                 root_port;
    logic                 msi_rx_decode_en;
    logic                 slv_timeout_err_dis;
    logic                 cfg_timeout_err_dis;
    logic                 cfg_ur_err_dis;
    logic                 cfg_crs_sw_visible_en;
    logic                 pcie_if_parity_check;
    logic                 pcie_rq_bme_check_dis;
    logic    [3:0][5:0]   pf_barlite_int;
    logic    [3:0][5:0]   pf_vf_barlite_int;
    logic    [3:0][5:0]   pf_barlite_ext;
    logic    [3:0][5:0]   pf_vf_barlite_ext;
    logic                 ram_init_dis;
    logic                 axibar_notranslate;
    logic                 axi_mm_dma_steering_mode; // Hard IP Only
    logic                 axi_mm_dsc_port; // Hard IP Only
    logic                 axi_mm_bridge_port; // Hard IP Only
    logic    [2:0]        pciebar_num;
    logic    [3:0][3:0]   ch_rd_cache;
    logic    [3:0][3:0]   ch_wr_cache;
    logic    [3:0]        ch_rd_sec;
    logic    [3:0]        ch_wr_sec;
    logic    [3:0]        ch_en;
    logic    [3:0][1:0]   ch_pfid;
    logic    [3:0]        ch_multq;
    logic    [3:0]        ch_stream;
    logic    [3:0]        ch_c2h_axi_dsc; // Not Used
    logic    [3:0]        ch_h2c_axi_dsc; // Not Used
    logic    [3:0]        ch_mm_port;
    logic    [11:0]       multq_max;
    logic                 trq_src_dis;
    logic                 irq_gen_via_reg;
    logic    [1:0]        xdma_pf;
    logic                 cq_rcfg_en;
    logic                 rq_rcfg_en;
    logic    [255:0]      mdma_cfg;
    attr_spare_t          spare;
} attr_dma_sp_t;

`endif
