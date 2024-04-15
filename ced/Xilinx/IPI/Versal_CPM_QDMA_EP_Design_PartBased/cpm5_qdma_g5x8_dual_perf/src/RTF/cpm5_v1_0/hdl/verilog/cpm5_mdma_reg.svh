

`ifndef CPM5_MDMA_REG_SVH
`define CPM5_MDMA_REG_SVH

typedef enum logic [3:0]{
  MDMA_TRQ_SEL_UNMAPPED=0,
  DMA_TRQ_SEL_GLBL1, 
  DMA_TRQ_SEL_GLBL2, 
  MDMA_TRQ_SEL_GLBL, 
  MDMA_TRQ_SEL_FMAP, 
  MDMA_TRQ_SEL_IRQ, 
  MDMA_TRQ_SEL_IND, 
  MDMA_TRQ_SEL_C2H, 
  MDMA_TRQ_SEL_H2C, 
  XDMA_TRQ_SEL_C2H_MM0, 
  XDMA_TRQ_SEL_C2H_MM1, 
  XDMA_TRQ_SEL_H2C_MM0, 
  XDMA_TRQ_SEL_H2C_MM1, 
  MDMA_TRQ_SEL_C2H_2, 
  MDMA_TRQ_SEL_QUEUE
} mdma_dmap_sel_e;

// Global Register Space
localparam DMA_CMN_GLBL1_START_A = 32'h0;
localparam DMA_CMN_GLBL1_SIZE    = 256;
localparam DMA_CMN_GLBL1_ABITS   = $clog2(DMA_CMN_GLBL1_SIZE);

localparam DMA_CMN_GLBL2_START_A = DMA_CMN_GLBL1_START_A + DMA_CMN_GLBL1_SIZE;
localparam DMA_CMN_GLBL2_SIZE    = 256;
localparam DMA_CMN_GLBL2_ABITS   = $clog2(DMA_CMN_GLBL2_SIZE);

localparam MDMA_CMN_GLBL_START_A = DMA_CMN_GLBL2_START_A + DMA_CMN_GLBL2_SIZE;
localparam MDMA_CMN_GLBL_SIZE    = 512;
localparam MDMA_CMN_GLBL_ABITS   = $clog2(MDMA_CMN_GLBL_SIZE);

// Function Mapping Ram
localparam MDMA_CMN_FMAP_START_A = MDMA_CMN_GLBL_START_A + MDMA_CMN_GLBL_SIZE;
localparam MDMA_CMN_FMAP_SIZE    = 256 * 4; 
localparam MDMA_CMN_FMAP_ABITS   = $clog2(MDMA_CMN_FMAP_SIZE);

// Indirect Interface Registers
localparam [31:0] MDMA_CMN_IND_START_A=MDMA_CMN_FMAP_START_A + MDMA_CMN_FMAP_SIZE;
localparam [31:0] MDMA_CMN_IND_SIZE =512;
localparam [31:0] MDMA_CMN_IND_ABITS=$clog2(MDMA_CMN_IND_SIZE);

localparam MDMA_CMN_C2H_START_A= MDMA_CMN_IND_START_A+MDMA_CMN_IND_SIZE;
localparam MDMA_CMN_C2H_SIZE   = 512;
localparam MDMA_CMN_C2H_ABITS  = $clog2(MDMA_CMN_C2H_SIZE);

localparam MDMA_CMN_IRQ_START_A= MDMA_CMN_C2H_START_A+MDMA_CMN_C2H_SIZE;
localparam MDMA_CMN_IRQ_SIZE   = 512;

localparam MDMA_CMN_H2C_START_A = MDMA_CMN_IRQ_START_A+MDMA_CMN_IRQ_SIZE;
localparam MDMA_CMN_H2C_SIZE    = 512;
localparam MDMA_CMN_H2C_ABITS   = $clog2(MDMA_CMN_H2C_SIZE);

localparam XDMA_CMN_C2H_MM0_START_A = MDMA_CMN_H2C_START_A+MDMA_CMN_H2C_SIZE;
localparam XDMA_CMN_C2H_MM0_SIZE    = 256;

localparam XDMA_CMN_C2H_MM1_START_A = XDMA_CMN_C2H_MM0_START_A+XDMA_CMN_C2H_MM0_SIZE;
localparam XDMA_CMN_C2H_MM1_SIZE    = 256;

localparam XDMA_CMN_H2C_MM0_START_A = XDMA_CMN_C2H_MM1_START_A+XDMA_CMN_C2H_MM1_SIZE;
localparam XDMA_CMN_H2C_MM0_SIZE    = 256;

localparam XDMA_CMN_H2C_MM1_START_A = XDMA_CMN_H2C_MM0_START_A+XDMA_CMN_H2C_MM0_SIZE;
localparam XDMA_CMN_H2C_MM1_SIZE    = 256;

localparam XDMA_CMN_EXT_START_A = 64*1024;
localparam XDMA_CMN_EXT_SIZE    = 64*1024; 

//localparam MDMA_CMN_MISC_START_A = MDMA_CMN_H2C_START_A+MDMA_CMN_H2C_SIZE;
//localparam MDMA_CMN_MISC_SIZE    = 512;

//Applicable for both VF and PF
//Depending on the requirement BAR size support only 4K
//Queue address offset H2C - qid*16, C2H - qid*16+8 and WRB - qid*16+12

// Direct mapped queue registers
// 2k queues
/// enum this
//   0  INT CIDX   - software interrupt consumer index
//   1  H2C PIDX   - software descriptor ring producer index
//   2  C2H PIDX   - software descriptor ring producer index
//   3  C2H WRB    - software writeback ring consumer index

//  QID encoded in trq.addr[19:4]
//  Reg offset encoded in trq.addr[3:0]

localparam MDMA_MSIX_START_A = XDMA_CMN_H2C_MM1_START_A + XDMA_CMN_H2C_MM1_SIZE;      // Space for 32 vectors and PBA
localparam MDMA_MSIX_SIZE    = 0;      // Space for 32 vectors and PBA

// Highjack MSIX for C2H as it is not used anymore.
localparam MDMA_CMN_C2H_2_START_A = MDMA_MSIX_START_A+MDMA_MSIX_SIZE;
localparam MDMA_CMN_C2H_2_SIZE    = 4096;
localparam MDMA_CMN_C2H_2_ABITS   = $clog2(MDMA_CMN_C2H_2_SIZE);


localparam MDMA_CMN_EXT_START_A = MDMA_CMN_C2H_2_START_A + MDMA_CMN_C2H_2_SIZE;      
localparam MDMA_CMN_EXT_SIZE    = 16384; 

localparam MDMA_CMN_EXT_2_START_A = MDMA_CMN_EXT_START_A + MDMA_CMN_EXT_SIZE;      
localparam MDMA_CMN_EXT_2_SIZE    = 39936; 

localparam MDMA_MSIX_2_START_A    = MDMA_CMN_EXT_2_START_A + MDMA_CMN_EXT_2_SIZE;      
localparam MDMA_MSIX_2_SIZE       = 32768;      

localparam MDMA_PF_QUEUE_START_A  = MDMA_MSIX_2_START_A + MDMA_MSIX_2_SIZE;

localparam MDMA_VF_MSIX_START_A = 0;
localparam MDMA_VF_MSIX_SIZE    = 4096;

localparam MDMA_VF_EXT_START_A = MDMA_VF_MSIX_START_A + MDMA_VF_MSIX_SIZE;
localparam MDMA_VF_EXT_SIZE    = 8192;

localparam MDMA_VF_QUEUE_START_A = MDMA_VF_EXT_START_A + MDMA_VF_EXT_SIZE;

localparam MDMA_CMN_QUEUE_SIZE = 16*2*4096;   // 16B * num_queues (4K queues) = address space per pf

// 16B * num_queues + MDMA_VF_QUEUE_START = address space per vf
localparam MDMA_PF_BAR_SIZE = MDMA_PF_QUEUE_START_A + MDMA_CMN_QUEUE_SIZE;
localparam MDMA_VF_BAR_SIZE = MDMA_VF_QUEUE_START_A + MDMA_CMN_QUEUE_SIZE;

localparam MDMA_REG_ADR_BITS  = 16;        // Support up to 64K of address space for all registers.
localparam MDMA_UNIMP_REG_CMP = 32'h0;

localparam MDMA_MAX_IND_PF_SETS = 4;       // Max number of indirect register sets for PCIe
localparam MDMA_MAX_IND_AXS = MDMA_MAX_IND_PF_SETS+ 2;  

`define MDMA_MAX_CTXT_REG 8

localparam MDMA_MAX_CTXT_REG= `MDMA_MAX_CTXT_REG;
localparam MDMA_MAX_IND_SZ=16;

localparam MDMA_REG_UNAMPPED_RDAT=32'h0;

typedef logic [31:0] mdma_csr_data_t;
localparam MDMA_CSR_DATA_SIZE = $bits(mdma_csr_data_t);

//---------------------------------------------------------------------
// Global register space.
typedef logic [MDMA_CMN_GLBL_ABITS:2] mdma_glbl_csr_addr_t;

typedef enum mdma_glbl_csr_addr_t {
  MDMA_GLBL_REG_A = 'h0,
  MDMA_GLBL_RNG_SZ_A[16],         
//MDMA_GLBL_STATUS_A[16],        
//MDMA_GLBL_CONFIG_A[16],       
  MDMA_GLBL_SCRATCH_A,                     // Byte Offset: 0x100 Separate register for each PF
  MDMA_GLBL_ERR_STAT,
  MDMA_GLBL_ERR_MASK,
  MDMA_GLBL_DSC_CFG_A,
  MDMA_GLBL_DSC_ERR_STS_A,
  MDMA_GLBL_DSC_ERR_MSK_A,
  MDMA_GLBL_DSC_ERR_LOG0_A,
  MDMA_GLBL_DSC_ERR_LOG1_A,
  MDMA_GLBL_TRQ_ERR_STS_A,
  MDMA_GLBL_TRQ_ERR_MSK_A,
  MDMA_GLBL_TRQ_ERR_LOG_A,
  MDMA_GLBL_DSC_DBG_DAT0_A,
  MDMA_GLBL_DSC_DBG_DAT1_A,
  MDMA_GLBL_DSC_DBG_CTL_A,
  MDMA_GLBL_DSC_ERR_LOG2_A,
  MDMA_GLBL_DBG_CFG,
  MDMA_GLBL_DBG_REG[16],
  MDMA_GLBL_INTERRUPT_CFG,
  MDMA_GLBL_HOST_ID_A[16],              
  MDMA_GLBL_BDG_HOST_ID,
  MDMA_GLBL_AXIMM_INTERRUPT_DEST_ADDR_A[2],
  MDMA_GLBL_FAB_ERR_LOG_A,
  MDMA_GLBL_REQ_ERR_STAT_A,
  MDMA_GLBL_REQ_ERR_MASK_A
} mdma_glbl_csr_addr_e;

typedef struct packed {
  logic [23:0] rsv;
  logic [3:0]  field1;
  logic [3:0]  field2;
} mdma_glbl_eg_reg_t;

typedef struct packed {
  logic [31:0] scratch;
} mdma_glbl_scratch_t;

typedef struct packed {
  logic [29:0] rsvd;
  logic lgcy_intr_pending;   // 1'b1: pending legacy interrupt; 1'b0: no pending legacy interrupt
  logic en_lgcy_intr;        // 1'b1: enable the legacy interrupt; 1'b0: disable the legacy interrupt
} mdma_glbl_interrupt_cfg_t;

typedef logic [3:0]   mdma_reg_virt_ch_t;

typedef struct packed {
  logic [31:28]             rsv;             // Reserved
  mdma_reg_virt_ch_t	      vch_h2c_mm;	   // H2C MM source virtual channel, 1'b1: AXIMM, 1'b0: PCIE 
  mdma_reg_virt_ch_t        vch_h2c_st;      // H2C ST source virtual channel, 1'b1: AXIMM, 1'b0: PCIE 
  mdma_reg_virt_ch_t        vch_dsc;         // Descriptor fetch and H2C/MM Writeback Virtual channel, 1'b1: AXIMM, 1'b0: PCIE 
  mdma_reg_virt_ch_t        vch_int_msg;     // Interrupt message write destination virtual channel, 1'b1: AXIMM, 1'b0: PCIE 
  mdma_reg_virt_ch_t        vch_int_aggr;    // Interrrupt aggregation write destination virtual channel, 1'b1: AXIMM, 1'b0: PCIE 
  mdma_reg_virt_ch_t        vch_cmpt;        // CMPT Engine write destination virtual channel, 1'b1: AXIMM, 1'b0: PCIE 
  mdma_reg_virt_ch_t        vch_c2h_payload; // C2H ST payload write destination virtual channel, 1'b1: AXIMM, 1'b0: PCIE 
} mdma_glbl_host_id_t;   // registers.  Also ind.data[0]

typedef struct packed {
  logic [23:0] rsv;

  logic [1:0]  c2h_mm_arprot;      // C2H MM read AXIMM prot.
  logic [3:0]  c2h_mm_arcache;     // C2H MM read AXIMM cache.
  logic [3:0]  c2h_mm_arsteering;  // C2H MM read AXIMM steering.

  logic [1:0]  h2c_mm_arprot;      // H2C MM read AXIMM prot if vch is AXIMM
  logic [3:0]  h2c_mm_arcache;     // H2C MM read AXIMM cache if vch is AXIMM
  logic [3:0]  h2c_mm_arsteering;  // H2C MM read AXIMM steering if vch is AXIMM

  logic [1:0]  h2c_st_arprot;      // H2C ST read AXIMM prot if vch is AXIMM
  logic [3:0]  h2c_st_arcache;     // H2C ST read AXIMM cache if vch is AXIMM
  logic [3:0]  h2c_st_arsteering;  // H2C ST read AXIMM steering if vch is AXIMM

  logic [1:0]  dsc_arprot;     // Descriptor AXIMM fetch AXIMM prot if vch is AXIMM
  logic [3:0]  dsc_arcache;    // Descriptor AXIMM fetch AXIMM cache if vch is AXIMM
  logic [3:0]  dsc_arsteering; // Descriptor AXIMM fetch AXIMM steering if vch is AXIMM

} rd_mdma_ind_host_id_t;  // ind.data[3:2]

typedef struct packed {
  logic [3:0] rsv;

  logic [1:0] h2c_mm_awprot;      // H2C MM write AXIMM prot
  logic [3:0] h2c_mm_awcache;     // H2C MM write AXIMM cache
  logic [3:0] h2c_mm_awsteering;  // H2C MM write AXIMM steering

  logic [1:0] dsc_awprot;     // Descriptor H2C/MM Writeback prot if vch is AXIMM
  logic [3:0] dsc_awcache;    // Descriptor H2C/MM Writeback cache if vch is AXIMM
  logic [3:0] dsc_awsteering; // Descriptor H2C/MM Writeback steering if vch is AXIMM

  logic [1:0] int_msg_awprot;     // Interrupt message write destination if vch is AXIMM
  logic [3:0] int_msg_awcache;    // Interrupt message write destination if vch is AXIMM
  logic [3:0] int_msg_awsteering; // Interrupt message write destination if vch is AXIMM

  logic [1:0] int_aggr_awprot;     // Interrrupt aggregation write destination if vch is AXIMM
  logic [3:0] int_aggr_awcache;    // Interrrupt aggregation write destination if vch is AXIMM
  logic [3:0] int_aggr_awsteering; // Interrrupt aggregation write destination if vch is AXIMM

  logic [1:0] cmpt_awprot;      // CMPT Engine write destination if vch is AXIMM
  logic [3:0] cmpt_awcache;     // CMPT Engine write destination if vch is AXIMM
  logic [3:0] cmpt_awsteering;  // CMPT Engine write destination if vch is AXIMM

  logic [1:0] c2h_payload_awprot;     // C2H ST payload write destination if vch is AXIMM
  logic [3:0] c2h_payload_awcache;    // C2H ST payload write destination if vch is AXIMM
  logic [3:0] c2h_payload_awsteering; // C2H ST payload write destination if vch is AXIMM
} wr_mdma_ind_host_id_t;  // ind.data[5:4] 

typedef struct packed {
  logic [31:10] rsv;
  logic [9:0]   smid;
} misc_mdma_ind_host_id_t;  // ind.data[6] 

typedef union packed {
  rd_mdma_ind_host_id_t rd_mdma_ind;   // Should be 64 bits wide (2 indirect registers)
  wr_mdma_ind_host_id_t wr_mdma_ind;   // Should be 64 bits wide (2 indirect registers)
  logic [63:0]          width;
} rd_mdma_ind_host_id_chk_t;

typedef struct packed {
  misc_mdma_ind_host_id_t misc;
  wr_mdma_ind_host_id_t   wr;
  rd_mdma_ind_host_id_t   rd;
  mdma_glbl_host_id_t     vch;
} ind_host_id_t; // Not used

typedef struct packed {
  logic [31-$bits(mdma_host_id_t):0] rsv;  // Reserved
  mdma_host_id_t bdg_host_id; // Host_id for bridge 
} mdma_glbl_bdg_host_id_t;

typedef struct packed {
  logic [15:0] rsv;    // Reserved
  logic [15:0] rng_sz; // Ring size (includes writeback location)
} mdma_glbl_rng_sz_t;

typedef struct packed {
  logic [$bits(mdma_csr_data_t)- MDMA_MAX_IND_AXS -1:0] rsvd;
  logic [MDMA_MAX_IND_AXS-1:0] ctxt_cmd_err;
} mdma_ind_err_status_t;

typedef struct packed {
  logic [31-13-MDMA_MAX_IND_AXS:0] rsvd; // 19-31
  logic err_req;    // 18
  logic err_fab;    // 17
  logic err_h2c_st; // 16
  logic err_bdg;    // 15
  logic [MDMA_MAX_IND_AXS-1:0] ind_ctxt_cmd_err; // 14:9
  logic err_c2h_st;   // 8
  logic err_c2h_mm_1; // 7
  logic err_c2h_mm_0; // 6
  logic err_h2c_mm_1; // 5
  logic err_h2c_mm_0; // 4
  logic err_trq;      // 3
  logic err_dsc;      // 2
  logic err_ram_dbe;  // 1
  logic err_ram_sbe;  // 0
} mdma_glbl_err_t;

typedef struct packed {
  logic vld;
  logic sel;
  logic [29:24] rsv;
  logic [23:0]  qid;
} mdma_glbl_dsc_err_log0_t;

typedef struct packed {
  logic  [31:28] rsv1;
  logic  [15:0]  cidx;
  logic  [11:9]  rsv0;
  logic  [3:0]   sub;  // Error subtype for dsc use errors
  logic  [4:0]   err;
} mdma_glbl_dsc_err_log1_t;

typedef struct packed {
  logic  [31:16] pidx_old;
  logic  [15:0]  pidx_new;
} mdma_glbl_dsc_err_log2_t;

// DSC Engine Error Status
typedef struct packed {
  logic  [31:0] sts;
} mdma_glbl_dsc_err_sts_t;

// DSC Engine Error Mask 
typedef struct packed {
  logic  [31:0] msk;
} mdma_glbl_dsc_err_msk_t;

// TRQ Access Error Status
//typedef struct packed {
  //logic [31:8]       rsv;
  //logic  [7:0]       sts;
//} mdma_trq_err_sts_t;

//typedef struct packed {
  //logic [31:8]       rsv;
  //logic  [7:0]       msk;
//} mdma_trq_err_msk_t;

// TRQ Access Error Log
typedef struct packed {
  logic src; // 0 for CSR, 1 for QSPC
  mdma_dmap_sel_e sel;
  logic [9:0] fnc;
  logic [16:0] adr;
} mdma_trq_err_log_t;

typedef struct packed {
  logic [31:10] rsv1; // Reserved
  logic unc_ovr_cor;  // Uncorrectable log overwrite correctable
  logic ctxt_fer_dis; // Log both dsc and dma error bit in context, not just first
  logic rsv0;
  logic wb_all; // All dsc get writeback
  logic [2:0]   max_dsc_fetch; // Max nuber of descriptors to fetch in one request.  8 * 2^val // Max value is 6
  logic [2:0]   wb_acc_int;    // Writeback interval.  Interval in descriptors = 2^(val+1)   // Disable via queue context
} mdma_glbl_dsc_cfg_t;

//// Struct of global registers to be passed around
typedef struct packed {
  mdma_glbl_rng_sz_t  [15:0] reg_rng_sz;
  mdma_glbl_scratch_t [3:0]  reg_scratch;
  mdma_glbl_interrupt_cfg_t  reg_glbl_intr_cfg;
  mdma_glbl_host_id_t [15:0] reg_glbl_host_id;
  mdma_glbl_bdg_host_id_t    reg_glbl_bdg_host_id;
  logic [63:0]               reg_aximm_intr_dest_addr;
} mdma_glbl_reg_t;

//---------------------------------------------------------------------
// Direct Mapped Queue Registers Space

typedef enum logic [3:0]{
  MDMA_DMAP_SEL_INT_CIDX=0 , MDMA_DMAP_SEL_H2C_DSC_PIDX=4, MDMA_DMAP_SEL_C2H_DSC_PIDX=8, MDMA_DMAP_SEL_WRB_CIDX=12
} mdma_dmapq_sel_e;

// This struct needs to be 32b. Add padding if needed.
typedef struct packed {
  logic [2:0] pad;
  logic en_int;
  logic en_stat_desc;
  mdma_c2h_wrb_trig_mode_e trig_mode;
  mdma_wrb_timer_th_ix_t timer_ix;
  mdma_wrb_cnt_th_ix_t cnt_ix;
  mdma_qidx_t sw_cidx;
} mdma_dyn_wrb_ptr_upd_t;

//---------------------------------------------------------------------
// Indirect context register space.

typedef logic [MDMA_CMN_C2H_ABITS:2] mdma_c2h_csr_addr_t;
typedef logic [MDMA_CMN_C2H_2_ABITS:2] mdma_c2h_csr2_addr_t;

typedef enum mdma_c2h_csr_addr_t {
  MDMA_IND_CONTROL_A=0, MDMA_IND_CTXT_DATA_A[`MDMA_MAX_CTXT_REG], MDMA_IND_CTXT_MASK_A[`MDMA_MAX_CTXT_REG], MDMA_IND_CTXT_CMD_A
} mdma_ind_csr_addr_e;

//typedef enum logic [1:0] {
//    MDMA_CTXT_CMD_CLR=0, MDMA_CTXT_CMD_WR, MDMA_CTXT_CMD_RD, MDMA_CTXT_CMD_INV
//} mdma_ind_ctxt_cmd_e;

typedef enum logic [3:0]{
  MDMA_CTXT_SEL_DSC_SW_C2H, 
  MDMA_CTXT_SEL_DSC_SW_H2C,
  MDMA_CTXT_SEL_DSC_HW_C2H, 
  MDMA_CTXT_SEL_DSC_HW_H2C,         // NO DATA MASKING/RMW support
  MDMA_CTXT_SEL_DSC_CR_C2H, 
  MDMA_CTXT_SEL_DSC_CR_H2C,         // NO DATA MASKING/RMW support
  MDMA_CTXT_SEL_WRB, 
  MDMA_CTXT_SEL_PFTCH, 
  MDMA_CTXT_SEL_INT_COAL,
  MDMA_CTXT_SEL_PASID_RAM_LOW, 
  MDMA_CTXT_SEL_HOST_PROFILE,
  MDMA_CTXT_SEL_TIMER, 
  MDMA_CTXT_SEL_FMAP, 
  MDMA_CTXT_SEL_FNC_STS
} mdma_ind_ctxt_sel_e;

localparam MDMA_CTXT_SEL_PASID_RAM_HIGH = MDMA_CTXT_SEL_HOST_PROFILE;   // Temp until code using PASID is removed
typedef struct packed {
  logic [$bits(mdma_csr_data_t)-$bits(mdma_qid_max_t)-$bits(mdma_ind_ctxt_cmd_e)-$bits(mdma_ind_ctxt_sel_e)-1 -1 :0] pad;
  mdma_qid_max_t      qid;
  mdma_ind_ctxt_cmd_e op;
  mdma_ind_ctxt_sel_e sel;
  logic busy; // Writes will be dropped when busy=1.
} mdma_ind_ctxt_cmd_t;

//typedef logic [12:0] mdma_qid_max_t;

typedef struct packed {
  mdma_csr_data_t [MDMA_MAX_CTXT_REG-1:0] data;
  mdma_csr_data_t [MDMA_MAX_CTXT_REG-1:0] mask;
  mdma_ind_ctxt_cmd_t cmd;
  logic valid;
} mdma_ctxt_rqif_t;

typedef struct packed {
  mdma_csr_data_t [MDMA_MAX_CTXT_REG-1:0] data;
  logic valid;
} mdma_ctxt_cpif_t;

// Indirect Registers
typedef struct packed {
  logic [15:0] crd_rcv;
} mdma_dsc_crd_rcv_t;

typedef struct packed {
  logic        sw_db;       // Software doorbell
  logic        hw_db;       // Hardware issued a doorbell to read the virtio flags
  logic        reserved;    // reserverd
  logic        vio_idx_req; // Virtio idx fetch requested.
  logic [4:0]  fetch_pnd;   // Fetch pending set when dscf fetch initiated, clear when rcp evt is processed.
  logic        evt_pnd;     // Event pending  set if ctxt needs to be analyzed again later to check for freed resource (irq_fifo_fl, imm wbk full....?)
  logic        idl_stp_b;   // Queue invalid and no descriptors pending
  logic        dsc_pnd;     // Descriptors pending      set when dscf fetch initiated, clear when wbc cidx == pidx
  logic [6:0]  wb_acc;      // Writeback accumulation count
  logic        qinv_req;    // Qinvalidate is required for this queue.
  logic [15:0] crd_use;        
  logic [15:0] cidx;
} mdma_dsc_hw_ctxt_t;

typedef struct packed {
    logic [15:0] crd_rcv;   
} mdma_ind_crd_t; 

typedef struct packed {
  logic [63:0] fetch_imm_base; // Base address for fetch_imm
  logic        pasid_en;
  logic [21:0] pasid;
  logic [3:0]  host_id;      // Index into the dsc host_id registers to determine the virtual channel of the queue.
  logic        irq_byp;      // Descriptor engine will remember if irq could not be sent in bypass mode and resend later. CIDX on delayed interrupt will be -1.  User must get last processed CIDX from status descriptor.
  logic        pack_byp_out; // Descriptors on bypass out will not be split into indivdual descriptors.
  logic        virtio_en;    // Enable Virtio Mode.  spare.vio_en attribute must be enabled as well.
  logic        dis_intr_on_vf; // Disable interrupt with VF
  logic        int_aggr;     // Indirect (1) or direct interrupt (0)
  mdma_int_vec_id_t vec;     // MSIX vector for this queue.
  logic [63:0] dsc_base;
  logic        is_mm;       // The queue is memory mapped.  Enabled via attribute dsc_ctxt_is_mm_en. Otherwise mm vs st is determined by dsc_size.
  logic        mrkr_dis;    // Disable fabric writeback (marker response) in non-bypass mode.
  logic        irq_req;     // Interrupt required to be sent (waiting for arm)
  logic        err_wb_sent;
  logic [1:0]  err;         //  bit[1] dma error, bit[0] dsc error
  logic        irq_no_last; // No interrupt was sent and pidx/cidx was idle due to already pending irq  // 1 VAR-RO
  logic [2:0]  port_id;     // Traffic manager port id which owns this queue       // 3
  logic        irq_en;      // Send interrupt on writeback/irq check        // 1
  logic        wbk_en;      // Send writeback on writeback/irq check        // 1
  logic        mm_chn;      // If 32B descriptor which MM channel to use    // 1
  logic        byp;         // Send to descriptor bypass out                // 1
  logic [1:0]  dsc_sz;      // Descriptor size.  0: 8B, 1:16B; 2:32B; 3:rsv // 2
  logic [3:0]  rng_sz;      // Ring size select                             // 4
  logic        err_irq_snt;
  logic        virtio_f_in_order; // Enbable F_IN_ORDER .  affects only detection of pidx overflow
  logic        rsv;        // Reserved                                     // 8
  logic [3:0]  fetch_max;  // Max number of fetches outstanding.  0 = 1 outstanding, etc.
  logic        at;         // Address type of ring 0: untranslated, 1: translated
  logic        wbi_acc_en; // Write back/Interrupt after accumulation      // 1
  logic        wbi_chk;    // Writeback/Interrupt after pending check      // 1
  logic        fcrd_en;    // Enable fetch credits                         // 1
  logic        qen;        // queue enable                                 // 1
  logic [2:0]  rsv0;       // Reserved
  mdma_fnid_t  fnc;        // Function
  logic        irq_arm;
  logic [15:0] pidx;
} mdma_ind_dsc_t; 

//---------------------------------------------------------------------
// Indirect C2H register space.
`define MDMA_MAX_TRIG_TIMER_VAL 16
`define MDMA_MAX_TRIG_CNT_VAL   16
`define MDMA_MAX_BUF_SIZE_VAL   16
localparam MDMA_MAX_TRIG_TIMER_VAL = `MDMA_MAX_TRIG_TIMER_VAL; // (VCS bug) (1 << $bits(mdma_wrb_timer_th_ix_t));
localparam MDMA_MAX_TRIG_CNT_VAL   = `MDMA_MAX_TRIG_CNT_VAL;   // (VCS bug) (1 << $bits(mdma_wrb_timer_th_ix_t));
localparam MDMA_MAX_BUF_SIZE_VAL = `MDMA_MAX_BUF_SIZE_VAL;

typedef logic [MDMA_CMN_IND_ABITS:2] mdma_ind_csr_addr_t;
typedef enum mdma_c2h_csr_addr_t {
    MDMA_C2H_TIMER_CNT[`MDMA_MAX_TRIG_TIMER_VAL], MDMA_C2H_CNT_TH[`MDMA_MAX_TRIG_CNT_VAL], MDMA_C2H_PFCH_CFG_1, MDMA_C2H_PFCH_CFG_2, MDMA_C2H_STAT_S_AXIS_C2H_ACCEPTED, MDMA_C2H_STAT_S_AXIS_WRB_ACCEPTED, MDMA_C2H_STAT_DESC_RSP_PKT_ACCEPTED, MDMA_C2H_STAT_AXIS_PKG_CMP, MDMA_C2H_STAT_DESC_RSP_ACCEPTED, MDMA_C2H_STAT_DESC_RSP_CMP, MDMA_C2H_STAT_WRQ_OUT, MDMA_C2H_STAT_WPL_REN_ACCEPTED, MDMA_C2H_STAT_TOTAL_WRQ_LEN, MDMA_C2H_STAT_TOTAL_WPL_LEN, MDMA_C2H_BUF_SZ[`MDMA_MAX_BUF_SIZE_VAL], MDMA_C2H_ERR_STAT, MDMA_C2H_ERR_MASK, MDMA_C2H_FATAL_ERR_STAT, MDMA_C2H_FATAL_ERR_MASK, MDMA_C2H_FATAL_ERR_ENABLE, MDMA_C2H_ERR_INT, MDMA_C2H_PFCH_CFG, MDMA_C2H_INT_TIMER_TICK, MDMA_C2H_STAT_DESC_RSP_DROP_ACCEPTED, MDMA_C2H_STAT_DESC_RSP_ERR_ACCEPTED, MDMA_C2H_STAT_DESC_REQ, MDMA_C2H_STAT_DEBUG_DMA_ENG_0, MDMA_C2H_STAT_DEBUG_DMA_ENG_1, MDMA_C2H_STAT_DEBUG_DMA_ENG_2, MDMA_C2H_STAT_DEBUG_DMA_ENG_3, MDMA_C2H_INTR_MSIX, MDMA_C2H_FIRST_ERR_QID, MDMA_STAT_NUM_WRB_IN, MDMA_STAT_NUM_WRB_OUT, MDMA_STAT_NUM_WRB_DRP, MDMA_STAT_NUM_STAT_DESC_OUT, MDMA_STAT_NUM_DSC_CRDT_SENT, MDMA_STAT_NUM_FCH_DSC_RCVD, MDMA_STAT_NUM_BYP_DSC_RCVD, MDMA_C2H_WRB_COAL_CFG, MDMA_C2H_INTR_H2C_REQ, MDMA_C2H_INTR_C2H_MM_REQ, MDMA_C2H_INTR_ERR_INT_REQ, MDMA_C2H_INTR_C2H_ST_REQ, MDMA_C2H_INTR_H2C_ERR_C2H_MM_MSIX_ACK, MDMA_C2H_INTR_H2C_ERR_C2H_MM_MSIX_FAIL, MDMA_C2H_INTR_H2C_ERR_C2H_MM_NO_MSIX, MDMA_C2H_INTR_H2C_ERR_C2H_MM_CTXT_INVAL, MDMA_C2H_INTR_C2H_ST_MSIX_ACK, MDMA_C2H_INTR_C2H_ST_MSIX_FAIL, MDMA_C2H_INTR_C2H_ST_NO_MSIX, MDMA_C2H_INTR_C2H_ST_CTXT_INVAL, MDMA_C2H_STAT_PCIE_CMP, MDMA_C2H_STAT_DEBUG_DMA_ENG_4, MDMA_C2H_STAT_DEBUG_DMA_ENG_5, MDMA_C2H_DBG_PFCH_QID, MDMA_C2H_DBG_PFCH, MDMA_C2H_INT_DEBUG, MDMA_C2H_STAT_IMM_ACCEPTED, MDMA_C2H_STAT_MARKER_ACCEPTED, MDMA_C2H_STAT_DISABLE_CMP_ACCEPTED, MDMA_C2H_PAYLOAD_FIFO_CRDT_CNT, MDMA_C2H_INTR_DYN_REQ, MDMA_C2H_INTR_DYN_MSIX, MDMA_DROP_LEN_MISMATCH, MDMA_DROP_DESC_RSP_LEN, MDMA_DROP_QID_FIFO_LEN, MDMA_DROP_PAYLOAD_CNT, MDMA_C2H_CMPT_FORMAT_0, MDMA_C2H_CMPT_FORMAT_1, MDMA_C2H_CMPT_FORMAT_2, MDMA_C2H_CMPT_FORMAT_3, MDMA_C2H_CMPT_FORMAT_4, MDMA_C2H_CMPT_FORMAT_5, MDMA_C2H_CMPT_FORMAT_6, MDMA_C2H_PFCH_CACHE_DEPTH, MDMA_C2H_WRB_COAL_BUF_DEPTH, MDMA_C2H_PFCH_CRDT, MDMA_C2H_STAT_HAS_CMPT_ACCEPTED, MDMA_C2H_STAT_HAS_PLD_ACCEPTED, MDMA_C2H_PLD_PKT_ID, MDMA_C2H_PLD_PKT_ID_1, MDMA_DROP_PAYLOAD_CNT_1 
} mdma_c2h_csr_addr_e;

`define MDMA_MAX_WATER_MARK_VAL 16

typedef enum mdma_c2h_csr2_addr_t {
  MDMA_C2H_CRDT_COAL_CFG_1, 
  MDMA_C2H_CRDT_COAL_CFG_2,
  MDMA_C2H_PFCH_BYP_QID,
  MDMA_C2H_PFCH_BYP_TAG,
  MDMA_C2H_WATER_MARK[`MDMA_MAX_WATER_MARK_VAL],
  MDMA_C2H_NOTIFY_EMPTY,
  MDMA_C2H_STAT_S_AXIS_C2H_ACCEPTED_1,
  MDMA_C2H_STAT_S_AXIS_WRB_ACCEPTED_1,
  MDMA_C2H_STAT_DESC_RSP_PKT_ACCEPTED_1,
  MDMA_C2H_STAT_AXIS_PKG_CMP_1,
  MDMA_C2H_STAT_S_AXIS_WRB_ACCEPTED_2,
  MDMA_C2H_ST_PAYLOAD_FIFO_DEPTH,
  MDMA_C2H_STAT_DEBUG_DMA_ENG_6,
  MDMA_C2H_STAT_DEBUG_DMA_ENG_7,
  MDMA_C2H_STAT_PCIE_CMP_1
} mdma_c2h_csr2_addr_e;

typedef logic [MDMA_CMN_H2C_ABITS:2] mdma_h2c_csr_addr_t;

typedef enum mdma_h2c_csr_addr_t {
  MDMA_H2C_ERR_STAT, MDMA_H2C_ERR_MASK, MDMA_H2C_FIRST_ERR_QID, MQDMA_H2C_DBG_REG0, MQDMA_H2C_DBG_REG1, MQDMA_H2C_DBG_REG2, MQDMA_H2C_DBG_REG3, MQDMA_H2C_DBG_REG4, MQDMA_H2C_FATAL_ERR_EN, MQDMA_H2C_DATA_THRESH, MQDMA_H2C_ALN_DBG_REG0
} mdma_h2c_csr_addr_e;

typedef struct packed {
  logic [15:0]     evt_pfch_fl_th; //Start eviction when FL Free count <= evt_pfch_fl_th, minimum value is 16
  logic [15:0]     pfch_fl_th; //Allow prefetch when FL Free count >= pfch_fl_th, minimum value is 256
} mdma_c2h_pfch_cfg_t;

typedef struct packed {
  logic [15:0] evt_qcnt_th; //Start Eviction when pfch qcnt >= evt_qcnt_th; The evc_qcnt_th should always be less than pfch_qcnt  
  logic [15:0] pfch_qcnt; // Max pfch qcnt allowed. Recommended value is < (MDMA_PFCH_CACHE_DEPTH-4)
} mdma_c2h_pfch_cfg_1_t;

typedef struct packed {
  logic fence;    // Credit fence from Prefetch module to Fetch Engine
  logic [30-17-$bits(mdma_c2h_alloc_max_desc_t)-$bits(mdma_c2h_alloc_max_desc_t):0]  rsvd;
  logic var_desc_no_drop; // Don't allow drop in the case of variable descriptor                      
  logic [15:0] pfch_ll_sz_th; //Controls the threshold for small packet sizes in LL performance
  mdma_c2h_alloc_max_desc_t var_desc_num_pfch; //Controls number of entries prefetched in cached per queue for variable descriptor. Recommended value is 31. 
  mdma_c2h_alloc_max_desc_t num_pfch; //Controls number of entries prefetched in cached per queue for fixed descriptor. Recommended value is 8.
} mdma_c2h_pfch_cfg_2_t;

typedef struct packed {
  mdma_qid_t qid;    // bit [19:8]
  logic      rsv;    // bit [7]    
  mdma_c2h_cache_tag_t  tag;    // bit [6:0]
} mdma_c2h_pfch_byp_rsp_t;

typedef struct packed {
  logic [13:0] rsv;
  logic [7:0]  pld_fifo_th;
  logic [9:0]  crdt_timer_th;  // This timer creates backpressure to credit module
} mdma_crdt_coal_cfg_1_t;

typedef struct packed {
  logic [7:0] rsv2;
  logic [7:0] crdt_fifo_th;
  logic [16-PFCH_LL_RAM_ADDR_BITS-1:0] rsv1;
  logic [PFCH_LL_RAM_ADDR_BITS-1:0] crdt_cnt_th;
} mdma_crdt_coal_cfg_2_t;

typedef struct packed {
  logic [15:0] high_wm;
  logic [15:0] low_wm;
} mdma_c2h_water_mark_t;

typedef struct packed {
  logic [14:0] rsvd;
  logic        enable;
  logic [15:0] noe;
} mdma_c2h_notify_empty_t; 

typedef struct packed {
  logic [31-1-1:0] rsv;
  logic enable_wpl_par_inv;
  logic enable_wrq_dis;
} mdma_c2h_fatal_err_enable_t;   

typedef struct packed {
  logic [31-$bits(mdma_fnid_t)-$bits(mdma_int_vec_id_t)-3-$bits(mdma_host_id_t):0]    rsv;
  mdma_host_id_t host_id;
  logic dis_intr_on_vf;
  logic err_int_arm;
  logic en_coal;
  mdma_int_vec_id_t vec;
  mdma_fnid_t func;
} mdma_c2h_err_int_t;   

typedef struct packed {
  logic [32-$bits(mdma_qidx_t)-$bits(mdma_int_vec_id_coal_t)-$bits(mdma_host_id_t)-1:0]    rsv;
  mdma_host_id_t host_id;
  mdma_int_vec_id_coal_t ring_idx; 
  mdma_qidx_t    sw_cidx;
} mdma_c2h_int_upd_cidx_t;    

typedef struct packed {
  logic [$bits(mdma_csr_data_t)-$bits(mdma_qid_t) -1 :0] pad;
  mdma_qid_t          qid;
} mdma_c2h_qid2int_map_qid_t;

typedef struct packed {
  logic [$bits(mdma_csr_data_t)-1 -$bits(mdma_int_vec_id_coal_t)-1 :0] pad;
  logic                  coal_en;
  mdma_int_vec_id_coal_t vec_id;
} mdma_c2h_qid2int_map_t;

//---------------------------------------------------------------------
//Add all the register structure for some self checking.
typedef union packed {
  mdma_csr_data_t                    csr_data;
  mdma_c2h_dbg_pfch_t                pfch_dbg;
  mdma_ind_ctxt_cmd_t                ctxt_cmd;
  mdma_ind_err_status_t              err_status;
  mdma_dyn_wrb_ptr_upd_t             dyn_upd_wrb;
  mdma_glbl_eg_reg_t                 glbl_eg_reg;
  mdma_c2h_qid2int_map_qid_t         qid2int_map_qid;
  mdma_c2h_qid2int_map_t             qid2int_map;
  mdma_c2h_pfch_cfg_t                pfch_cfg;
  mdma_c2h_pfch_cfg_1_t              pfch_cfg_1;
  mdma_c2h_pfch_cfg_2_t              pfch_cfg_2;
  mdma_crdt_coal_cfg_1_t             crdt_coal1;
  mdma_crdt_coal_cfg_2_t             crdt_coal2;
  mdma_c2h_water_mark_t              water_mark;
  mdma_c2h_notify_empty_t            notify_empty;
  mdma_c2h_fatal_err_enable_t        fatal_err_enable;
  mdma_c2h_err_int_t                 err_int_reg;
  mdma_c2h_int_upd_cidx_t            int_upd_cidx;
  mdma_stat_c2h_debug_dma_eng_0_t    stat_c2h_debug_dma_eng_0;  
  mdma_stat_c2h_debug_dma_eng_1_t    stat_c2h_debug_dma_eng_1;  
  mdma_stat_c2h_debug_dma_eng_2_t    stat_c2h_debug_dma_eng_2;   
  mdma_stat_c2h_debug_dma_eng_3_t    stat_c2h_debug_dma_eng_3;  
  mdma_stat_c2h_debug_dma_eng_4_t    stat_c2h_debug_dma_eng_4;  
  mdma_stat_c2h_debug_dma_eng_5_t    stat_c2h_debug_dma_eng_5;  
} mdma_csr_data_chk_t;


// PASID RAM is 36 bits wide
typedef struct packed {
  logic [2:0]  rsv;   
  logic [11:0] fnc;       
  logic        pasid_en;
  logic [19:0] pasid;
} pasid_cxt_t;

typedef struct packed {
  logic [1:0]  rsv;
  logic        ctxt_arb_sel;  // Use dbg_ctl to select which arbiter requester sel (c2h:1, h2c:0)
  logic [11:0] ctxt_arb_qid;  // Use dbg_ctl to select which arbiter requester qid
  logic [4:0]  ctxt_arb_req;  // Vector of ctxt arbitration requesters.  Bit position map: EVT_SRC =0, TRQ_SRC =1, WBC_SRC=2, CRD_SRC=3, IND_SRC=4
  logic        irq_fifo_fl;
  logic        tm_dsc_sts_stall;
  logic [1:0]  rrq_stall;
  logic [1:0]  rcp_fifo_spc_stall;
  logic [1:0]  rrq_fifo_spc_stall;
  logic [1:0]  fab_wb_sts_stall;
  logic [1:0]  dsc_out_stall;
} mdma_dsc_dbg_dat0_t;

typedef struct packed {
  logic [3:0]  rsv;
  logic [5:0]  evt_spc_c2h;
  logic [5:0]  evt_spc_h2c;
  logic [7:0]  dsc_spc_c2h;
  logic [7:0]  dsc_spc_h2c;
} mdma_dsc_dbg_dat1_t;

typedef struct packed {
  logic [31:3] rsv;
  logic [2:0]  sel;  // Used to select the ctxt_arb_sel and ctxt_arb_qid for each requester.
} mdma_dsc_dbg_ctl_t;

`endif