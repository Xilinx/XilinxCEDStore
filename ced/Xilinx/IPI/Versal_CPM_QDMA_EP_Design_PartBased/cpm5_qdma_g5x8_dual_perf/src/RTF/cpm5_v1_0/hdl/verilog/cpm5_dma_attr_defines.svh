`ifndef CPM5_DMA_ATTR_DEFINES_SVH
`define CPM5_DMA_ATTR_DEFINES_SVH


typedef struct packed {
    logic [8:0]                error_loc6;
    logic [8:0]                error_loc5;
    logic [8:0]                error_loc4;
    logic [8:0]                error_loc3;
    logic [8:0]                error_loc2;
    logic [8:0]                error_loc1;
    logic [8:0]                error_loc0;
    logic [8:0]                color_loc6;
    logic [8:0]                color_loc5;
    logic [8:0]                color_loc4;
    logic [8:0]                color_loc3;
    logic [8:0]                color_loc2;
    logic [8:0]                color_loc1;
    logic [8:0]                color_loc0;
} mdma_c2h_wrb_loc_t;

typedef struct packed {
    logic [255:184] rsv3;                         //255:184
    logic           slv_unaligned_addr_dis;       //183      // Unaligned address support
    logic           cmpt_coal_int_race_fix_dis;   //182
    logic           xdma_axil_func_chk_en;        //181 
    logic           ecam_smid_chk_en;             //180      // Enable SMID checks for ECAM transactions via AXI-Lite
    logic           qspc_smid_chk_en;             //179      // Enable SMID checks for qspc transactions via AXI-Lite
    logic           slv_smid_chk_en;              //178      // Slave SMID check enable
    logic           override_lc_cap_en;           //177      // Override last core capability offset enable
    logic [ 11:0]   vsec_len;                     //176:165  // VSEC length
    logic [ 11:0]   last_core_cap_offset;         //164:153  // Last core capability offset  
    logic           axil_dma_slverr_rsp_dis;      //152      // Disable all error response for AXI-Lite input for ECAM, XDMA and QSPC
    logic [ 1:0]    crc_pad;                      //151:150  // crc pad, depends on external and internal data widths 00 : Internal and external DW are same 01: External data width == Internal data width/2 10:External data width == Internal data width/4 & 11: External data width == Internal data width/8
    logic [ 7:0]    fab_mstr_bypo_init_crdt;      //149:142  // Initial credits for the TL master bypo interfaces
    logic           trq_qspc_to_dat;              //141      // If set, return all 1 for qspc tcp timeout data, else all 0
    logic           trq_qspc_to_rsp;              //140      // If set, return all slv_err for qspc tcp timeout response, else okay
    logic [4:0]     tcp_qspc_to_exp;              //139:135  // Exponential timer for TRQ doorbell completion timeout;  2^exp,  0 = disabled
    logic [6:0]     max_pf;                       //134:128  // Max number of physical function
    logic [63:0]    dsn;                          //127:64   // Downstream serial number
    logic           dsc_out_fifo_depth2;          //63       // If set, the dsc engine dsc output buffer will have a threshold of 2 instead of 4.
    logic           h2c_hdr_par_prot;             //62       // If set, parity protection on AXIS H2C header bits, else ECC protection
    logic           c2h_hdr_par_prot;             //61       // If set, parity protection on AXIS C2H header bits, else ECC protection
    logic           h2c_crc_dis;                  //60       // If set, crc support on h2c data is disable
    logic           c2h_crc_dis;                  //59       // If set, crc support on c2h data is disable 
    logic           mrsp_on_qsts;                 //58       // If set, send marker responses (h2c, c2h mm) on qstatus port instead of dsc_byp_out
    logic           apb_dma_slverr_rsp_dis;       //57       // Disable error response for APB CSR access
    logic           bypass_seg;                   //56       // Bypass segmentation for the fabric interfaces
    logic [ 7:0]    fab_mstr_ctrl_init_crdt;      //55:48    // Initial credits for the TL master control intec2hrfaces
    logic [15:0]    fab_mstr_data_init_crdt;      //47:32    // Initial credits for the TL master data interfaces
    logic [31:0]    rsv1;                         //31:0     // Temporarily used in the interconnect steering logic
} attr_mdma_cfg_t;

typedef struct packed {
    logic           dis_irq_ord_fix;               //255      // If set, disable the writeback and interrupt ordering fix in wb_core
    logic           tm_dsc_sts_ovr;                //254      // If set, tm_dsc_sts_rdy will be assumed to be high
    logic           fetch_imm_noqual;              //253
    logic           fetch_imm_no_limit;            //252
    logic           func_4k_support_en;            //251
    logic           axi_intr_sel;                  //250      // AXI interrupt delivery mechanism in mhost mode. 0:user interface, 1:AXI MemWr
    logic           pcie_dsc_rcp_arb_pri;          //249      // Enable multi-host support
    logic           mhost_en;                      //248      // Enable multi-host support
    logic           vio_en;                        //247
    logic  [31:0]   pf_legacy_interrupt_wire;      //246:215  // Map PF0-PF15 to legacy interrupt wire, each PF has 2 bits
    logic           pcie_msix_enc;                 //214      // If set, msi_int interface to pcie to specify the msix vector will be encoded.
    logic           phy_rdy_rst_dis;               //213      // Disconnect Phy Ready reset from DMA
    logic  [3:0]    c2h_st_num_buf_byte_loc;       //212:209  // LSB byte location of the num_buffer field in the data payload 
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
    logic           xdma_wcp_throttle;             //195      // If set, limit wcp rid done to max every other cycle to limit event rate to fabric
    logic           dis_xdma_wcp_err_bsy_clr;      //194      // If set, disable fix to clear busy bit in event of wcp error.  Needed for surprise xdma  FLR.
    logic           dis_acc_irq;                   //193      // If set, disable MM/H2C ST periodic interrupts in wb_acc mode
    logic           dis_h2c_wrb_on_src_err_fix;    //192      // If set, disable the fix to send wrb on h2c src err
    logic           dis_c2h_avl_ring_process;      //191      // If set, disable the C2H Avail Ring entry processing inside QDMA 
    logic           fix_dbe_parity_dis;            //190      // If set, disable fix for EDT-985612, generate invalid parity on dbe at write interfaces
    logic           pcie_rq_vf_flr_check_dis;      //189      // If set, flr for vfs will be assumed to be false in dma_pcie_req
    logic           pcie_rq_pf_flr_check_dis;      //188      // If set, flr for pfs will be assumed to be false in dma_pcie_req
    logic           mm_err_wbk_fix_dis;            //187      // If set, disable the fix for the write completion from the DMA Write Engine
    logic           dis_c2h_ctxt_mgr_fix;          //186      // If set, disable the C2H fix for ctxt mgr, affects both wrb and pfch
    logic           new_axiuser_en;                //185      // If set, use new axiuser format
    logic           slv_bresp_fix_dis;             //184      // If set, disable the fix for Slave Bresp (1: slv_wrq_commit; 0: slave_wcp_vld)
    logic           rcb128_en;                     //183      // If set, RCBs are 128B, if not set, RCBs are 64B
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
    logic           bme_clr_on_usr_flr_done;       //133      // If set, bme will be cleared if user signals flr done for function.
    logic           dma_rst_rc_rdy;                //132      // If set, assert rc_tready when dma in under reset.
    logic           ign_pidx_upd_on_irq_arm;       //131      // If irq_arm bit is set by trq write, do not update the pidx
    logic           use_stm_dsc_format;            //130      // Makes QDMA work on STM descriptor format
    logic           dma_aximm_rsp_clr;             //129      // Clear aximm rsp count for channel when run bit is asserted.
    logic           dsc_qinv_on_err_dis;           //128      // Invalidate queue on error disable
    logic           xdma_drain_dat_en;             //127      // Enable draining of dat when run bit is not set for xdma.  Set to 1 for Evereset
    logic           xdma_drain_dsc_en;             //126      // Enable draining of dsc when run bit is not set for xdma.  Set to 1 for Evereset
    logic           disable_port_id_check;         //125      // Disable the port_id check
    logic           wb_sts_all;                    //124      // All writeback check results from dsc engine are output to wb sts port
    logic           dis_rc_splt_cmp_err_fix;       //123      // Fix to indicate err to engine if EOP RCP is err-free, but other RCPs had err.
    logic           en_8k_cmpt_qid;                //122      // Enable 8K CMPT queues
    logic           dis_c2h_st_eng_qid_fix;        //121      // Fix to pass all bits from s_axis_c2h_data.qid downstream instead of just 11b.
    logic           dsc_packed_cidx_roll_dis;      //120      // If set, packed mode dsc byp out will not rollover very last cidx to 0x0.
    logic           dis_brdg_slv_order_hang_fix;   //119      // If set, disable the bridge slave fix for hangs due to ordered requests
    logic           dma_mm_rd_full32_dis;          //118      // If set, allow up to 32 oustanding writes on DMA AXIMM write master.  Else 30
    logic           dma_mm_wr_full32_dis;          //117      // If set, allow up to 32 oustanding writes on DMA AXIMM write master.  Else 30
    logic           no_wrb_marker_fix_dis;         //116      // Disable support for no_wrb_marker
    logic           vio_evnt_supp_en;              //115      // Enable VIO Event Suppression FSM in CMPT Engine.
    logic           vio_int_sprs_aftr_rty;         //114      // Send VIO INT if found suppressed (but enabled in CTXT) even after a retry.
    logic           bme_clr_on_linkdown_dis;       //113      // If set, do not clear bme on linkdown
    logic           rq_rcfg_dis;                   //112      // If set, disable nph reinit sequence after linkdown and firewall enable
    logic           new_rx_vdm           ;         //111      // If set, use new rx_vdm which has full 4dw header 
    logic           dsc_stall_irq_fl_dis ;//110               // Disable stall descriptor context if dsc engine has too many irqs to send.
    logic           axi_parity_chk_dis   ;//109               // Disable AXI slave parity checks
    logic  [7:0]    rsvd4                ;//108:101           // Was: Mask for function bits received by aximm slave. Useful if number of functions supported needs less than 8 bits.  Upper bits can then be used for SMID
    logic           dsc_rcp_evt_pri      ;//100               // Rcp events have priority for dsc context lookup
    logic           fabric_reset_en      ;//99                // Enable reset from fabric // Not hooked up to reset yet
    logic           rrq_disable_en       ;//98                // Block new read requests on RQ timeout or register write
    logic           irq_on_qen_only      ;//97                // If set, dsc engine will generate queue interrupts only if queue is enabled
    logic           dis_brdg_slv_free_buf_fix;    //96       // If set, disable bridge slave read buffer leak fix
    logic           dis_cmpt_port_id_chk;//95                 // Disable port_id check in CMPT Engine.
    logic  [9:0]    slv_fnc_msk          ;//94:85             // Mask for function bits received by aximm slave. For PS transactions, SMID should be masked with attribute for effective SMID to compare with BDF table. 
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
    logic    [12:0]      num_vfs;
    logic    [12:0]      firstvf_offset;
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

// SR: Bridge New Attributes
// BAR Attribute New Struct
typedef struct packed {
//  logic  [64:0]     	rsvd_1;       //197:132	// Used to be {base_addr,as}
    logic  [2:0]      	rlx_rd;       //131:129	// Used to be attr
//  logic  [45:0]     	rsvd_0;       //128:83	// Used to be highaddr[63:18]	 
    logic  [7:0]      	start_entry;  //82:75	// Used to be highaddr[17:10]	 
    logic  [5:0]      	bar_size;     //74:69	// Used to be highaddr[9:4]
    logic  [3:0]      	num_win;      //68:65	// Used to be highaddr[3:0]
    logic  [63:0]     	base_addr;    //64:1	// Used to be bar_addr[63:0]
    logic             	bar_en;       //0	// Used to be sec
} attr_dma_axi2pciebar_new_t;

typedef struct packed {
    logic  [43:0]   badr;           // 63:20
    logic  [9:0]    smid;
    logic  [9:0]    smid_mask;
    logic  [2:0]    tz_prot;
    logic  [1:0]    num_bus;        // 1 - 16 bus, 2 - 64 bus, 3 - 256 bus
    logic           ecam_en;
} attr_dma_ecam_dec_t;

typedef struct packed  {
    logic  [1:0]    ebr_size;       // Bridge CSR size 1 << (ebr_size+12)
    logic  [2:0]    tz_prot;
    logic  [19:0]   badr;           // 31:12
} attr_dma_brdg_dec_t;

typedef struct packed {
    logic  [1:0]    eqdma_csr_size; // EQDMA CSR size 1 << (eqdma_csr_size+12)
    logic  [19:0]   badr;           // 31:12
    logic  [2:0]    tz_prot;
    logic           eqdma_en;
} attr_dma_eqdma_dec_t;

typedef struct packed {
    logic  [2:0]    tz_prot;
    logic  [1:0]    qspc_csr_size;  // QSPC CSR size 1 << (qspc_csr_size+20)
    logic  [43:0]   badr;           // 63:20  
    logic  [9:0]    smid_mask;
    logic           qspc_en;
} attr_dma_qspc_dec_t;

typedef struct packed {
    logic  [43:0]   badr;           
    logic  [1:0]    xdma_csr_size;  // XDMA CSR size 1 << (xdma_csr_size+16)
    logic  [2:0]    tz_prot;
    logic           xdma_en;
} attr_dma_xdma_dec_t;

// DMA General Attributes 
// Interface Struct - Do not change
typedef struct packed {
    logic    [31:0][5:0]  pf_barlite_int;
    logic    [31:0][5:0]  pf_vf_barlite_int;
    logic    [31:0][5:0]  pf_barlite_ext;
    logic    [31:0][5:0]  pf_vf_barlite_ext;
    logic    [125:0]      mdma_c2h_wrb_field_loc;
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
    logic    [3:0][3:0]   xdma_h2c_aximm_steering;
    logic    [3:0][3:0]   xdma_c2h_aximm_steering;
    logic    [3:0][3:0]   rsv2;
    logic    [3:0][5:0]   rsv1;
    logic    [3:0][1:0]   rsv0;
    logic    [11:10]      rsv_smid;
    logic    [9:0]        xdma_smid;
    logic    [3:1]        rsv_dma_id;
    logic                 dma_id;
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
//    logic    [3:0]        ch_h2c_axi_dsc; // Not Used
    logic                 rsvd;
    logic                 pcie_firewall_auto_en;   // 1: PCIe Firewall is enabled by HW automatically upon link-down; 0: Enabled by FW 
    logic                 debug_no_sticky_reset;
    logic                 back_to_legacy_dma_reset;   // 1: Legacy DMA Reset Scheme for S80 which resets DMA with PCIe; 0: New Reset Scheme
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
    logic    [31:0][5:0]  pf_barlite_int;
    logic    [31:0][5:0]  pf_vf_barlite_int;
    logic    [31:0][5:0]  pf_barlite_ext;
    logic    [31:0][5:0]  pf_vf_barlite_ext;
    mdma_c2h_wrb_loc_t    mdma_c2h_wrb_field_loc;
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
    logic    [3:0][3:0]   xdma_h2c_aximm_steering;
    logic    [3:0][3:0]   xdma_c2h_aximm_steering;
    logic    [3:0][3:0]   rsv2;
    logic    [3:0][5:0]   rsv1;
    logic    [3:0][1:0]   rsv0;
    logic    [11:10]      rsv_smid;
    logic    [9:0]        xdma_smid;
    logic    [3:1]        rsv_dma_id;
    logic                 dma_id;
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
//    logic    [3:0]        ch_h2c_axi_dsc; // Not Used
    logic                 rsvd;
    logic                 pcie_firewall_auto_en;   // 1: PCIe Firewall is enabled by HW automatically upon link-down; 0: Enabled by FW 
    logic                 debug_no_sticky_reset;
    logic                 back_to_legacy_dma_reset;   // 1: Legacy DMA Reset Scheme for S80 which resets DMA with PCIe; 0: New Reset Scheme    
    logic    [3:0]        ch_mm_port;
    logic    [11:0]       multq_max;
    logic                 trq_src_dis;
    logic                 irq_gen_via_reg;
    logic    [1:0]        xdma_pf;
    logic                 cq_rcfg_en;
    logic                 rq_rcfg_en;
    attr_mdma_cfg_t       mdma_cfg;
    attr_spare_t          spare;
} attr_dma_sp_t;

typedef struct packed {
   logic [31:0]		timer_tick;
   logic [31:0]		timeout_threshold;
} attr_dma_iep_timer;

`endif
