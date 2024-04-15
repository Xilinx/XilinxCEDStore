
`ifndef CPM5_DMA_REG_SVH
`define CPM5_DMA_REG_SVH

typedef enum logic [5:0] { // Address       // Struct
    DMA_GLBL1_IDENTIFIER_A= 0,              // dma_reg_identifier_t
    DMA_GLBL1_BUSDEV_A       = 6'h1,        // Busdevfunction
    DMA_GLBL1_PCIE_EFF_MPL_A = 6'h2,        // PCIE effect max payload size
    DMA_GLBL1_PCIE_EFF_MRS_A = 6'h3,        // PCIE effective max read request size
    DMA_GLBL1_SYSTEM_ID_A    = 6'h4,        // System ID 
    DMA_GLBL1_MSI_MSIX_EN_A  = 6'h5,        // MSIX, MSI enable status
    DMA_GLBL1_DAT_WIDTH_A    = 6'h6,        // Effective datapath width
    DMA_GLBL1_PCIE_CFG_A     = 6'h7,        // PCIE relaxed ordering 
    DMA_GLBL1_AXI_EFF_MPL_A  = 6'h10,       // AXI MM effective max payload
    DMA_GLBL1_AXI_EFF_MRS_A  = 6'h11,       // AXI MM effective max read request size
    DMA_GLBL1_DMA_CFG_A      = 6'h13,       // (RQ metering multiplier, num tag, xdma axi fetch/wb)
    DMA_GLBL1_XDMA_WTO_A     = 6'h18,       // Xdma c2h st write timeout
    DMA_GLBL1_FAB_CFG_A      = 6'h1a,       // Xdma/Qdma fabric interface cfg
    DMA_GLBL1_SCRATCH0_A     = 6'h20,       // Scratch registers
    DMA_GLBL1_SCRATCH1_A     = 6'h21,       // Scratch registers
    DMA_GLBL1_SCRATCH2_A     = 6'h22,       // Scratch registers
    DMA_GLBL1_SCRATCH3_A     = 6'h23,       // Scratch registers
    DMA_GLBL1_SCRATCH4_A     = 6'h24,       // Scratch registers
    DMA_GLBL1_SCRATCH5_A     = 6'h25,       // Scratch registers
    DMA_GLBL1_SCRATCH6_A     = 6'h26,       // Scratch registers
    DMA_GLBL1_SCRATCH7_A     = 6'h27,       // Scratch registers
    DMA_GLBL1_GIC_A          = 6'h28,       // GIC generation
    DMA_GLBL1_BP0_A          = 6'h30,       // Backpressure ctl RQ
    DMA_GLBL1_BP1_A          = 6'h31,       // Backpressure ctl RC
    DMA_GLBL1_BP2_A          = 6'h32,       // Backpressure ctl CQ
    DMA_GLBL1_BP3_A          = 6'h33,       // Backpressure ctl CC
    DMA_GLBL1_RAM_MSK_SBE_1_A = 6'h38,      // dma_reg_ram_1_t
    DMA_GLBL1_RAM_STS_SBE_1_A = 6'h39,      // dma_reg_ram_1_t
    DMA_GLBL1_RAM_MSK_DBE_1_A = 6'h3a,      // dma_reg_ram_1_t
    DMA_GLBL1_RAM_STS_DBE_1_A = 6'h3b,      // dma_reg_ram_1_t
    DMA_GLBL1_RAM_MSK_SBE_A  = 6'h3c,       // dma_reg_ram_t
    DMA_GLBL1_RAM_STS_SBE_A  = 6'h3d,       // dma_reg_ram_t
    DMA_GLBL1_RAM_MSK_DBE_A  = 6'h3e,       // dma_reg_ram_t
    DMA_GLBL1_RAM_STS_DBE_A  = 6'h3f        // dma_reg_ram_t
} dma_glbl1_csr_addr_e;


typedef enum logic [5:0] { // Address            // Struct
    DMA_GLBL2_IDENTIFIER_A= 0,      // dma_reg_identifier_t
    DMA_GLBL2_PF_BARLITE_INT_A,     // dma_reg_barlite_map_t
    DMA_GLBL2_PF_VF_BARLITE_INT_A,  // dma_reg_barlite_map_t
    DMA_GLBL2_PF_BARLITE_EXT_A,     // dma_reg_barlite_map_t
    DMA_GLBL2_PF_VF_BARLITE_EXT_A,  // dma_reg_barlite_map_t
    DMA_GLBL2_CHANNEL_INST_A,       // dma_reg_channel_t     // Which engines are instantiated.  1 bit per engine (see struct)
    DMA_GLBL2_CHANNEL_MDMA_A,       // dma_reg_channel_t     // The dma mode of each engine  1: mdma; 0: xdma.  Valid if engine instantiated. 1 bit per engine.
    DMA_GLBL2_CHANNEL_STRM_A,       // dma_reg_channel_t     // The interface mode of each engine 1: stream: 0: MM.   1 bit per engine.
    DMA_GLBL2_MDMA_CAP_A,           // dma_reg_mdma_cap_t
    DMA_GLBL2_XDMA_CAP_A,           // dma_reg_xdma_cap_t
    DMA_GLBL2_PASID_CAP_A,          // dma_reg_pasid_cap_t
    DMA_GLBL2_FUNC_RET_A,           // function[7:0]         // Returns function number
    DMA_GLBL2_SYSTEM_ID_A,          // system_id[15:0]         // Returns function number
    DMA_GLBL2_MISC_CAP_A,           // attr.spare.misc_cap[31:0]
    DMA_GLBL2_DBG_REG_A[8],          // Allows reading of 256 bit debug data based on the select in MATCH_SEL_A

    DMA_GLBL2_DBG_PCIE_RQ0_A  = 6'h2e, // dma_pcie_rq0_dbg_reg_t
    DMA_GLBL2_DBG_PCIE_RQ1_A  = 6'h2f, // dma_pcie_rq1_dbg_reg_t
    DMA_GLBL2_DBG_AXIMM_WR0_A = 6'h30, // aximm_wr_misc_dbg_reg_t
    DMA_GLBL2_DBG_AXIMM_WR1_A = 6'h31, // aximm_wr_brsp_dbg_reg_t
    DMA_GLBL2_DBG_AXIMM_RD0_A = 6'h32, // aximm_rd_misc_dbg_reg_t
    DMA_GLBL2_DBG_AXIMM_RD1_A = 6'h33, // aximm_rd_rrsp_dbg_reg_t
    DMA_GLBL2_DBG_FAB0_A      = 6'h34,
    DMA_GLBL2_DBG_FAB1_A      = 6'h35,
    DMA_GLBL2_DBG_MATCH_SEL_A = 6'h3d,      
    DMA_GLBL2_DBG_MATCH_MSK_A = 6'h3e,      
    DMA_GLBL2_DBG_MATCH_PAT_A = 6'h3f      
} dma_glbl2_csr_addr_e;

typedef struct packed {
    logic [10:0] id;
    logic        mdma;
    logic [3:0] target; 
    logic [7:0] rsv;
    logic [7:0] version;
}  dma_reg_identifier_t;

typedef struct packed {
    logic [1:0]   rsv;
    logic [5:0]   pf3_bar_map;
    logic [5:0]   pf2_bar_map;
    logic [5:0]   pf1_bar_map;
    logic [5:0]   pf0_bar_map;
}  dma_reg_barlite_map_t;

typedef struct packed {
    logic         c2h_mdma_chnl;
    logic         h2c_mdma_chnl;
    logic [3:0]   rsv1;
    logic [3:0]   c2h_xdma_chnl;
    logic [3:0]   rsv0;
    logic [3:0]   h2c_xdma_chnl;
} dma_reg_channel_t;

typedef struct packed {
    logic [31:12] rsv;
    logic [11:0]  max_queue;
} dma_mdma_cap_t;

typedef struct packed {
    logic [31:2]  rsv;
    logic         xdma_axi_wbk;
    logic         xdma_axi_fetch;
} dma_xdma_cap_t;

typedef struct packed {
    logic [11:0]  brg_pasid_wr_base;     // Only used if brg_share_pasid_dis == 1
    logic [11:0]  brg_pasid_base;
    logic         brg_shared_pasid_dis;
    logic         dma_shared_pasid_dis;
    logic         brg_pasid_en;
    logic         dma_pasid_en;
} dma_pasid_cap_t;

typedef struct packed {
    logic [63-37:0]   rsvd;
//    logic          brg_slv_pasid_ram;
//    logic          pasid_ctxt_ram;
    logic          pfch_ctxt_cam_ram_0;
    logic          pfch_ctxt_cam_ram_1;
    logic          tag_ram_even;
    logic          tag_ram_odd;
    logic          rc_rrq_evn_ram;
    logic          rc_rrq_odd_ram;
    logic          pend_fifo_ram;
    logic          pfch_ll_ram;
    logic          wrb_ctxt_ram;
    logic          pfch_ctxt_ram;
    logic          desc_req_fifo_ram;
    logic          int_ctxt_ram;
    logic          wrb_coal_data_ram;
    logic          qid_fifo_ram;
    logic [3:0]    timer_fifo_ram;
    logic          mi_tl_slv_fifo_ram; 
    logic          mi_h2c_pcie_dsc_cpld; //  XDMA DSC RAM; MDMA DSC RAM
    logic          mi_h2c_pcie_dsc_cpli; //  XDMA unused;  MDMA DSC INFO
    logic          mi_sw_ctxt;
    logic          mi_dsc_crd_rcv;
    logic          mi_hw_ctxt;
    logic          mi_func_map;   // use ony 256 entries
    logic          mi_c2h_wr_brg_dat; // Bridge Slave
    logic          mi_c2h_rd_brg_dat; // Bridge Slave
    logic          mi_h2c_wr_brg_dat; // Bridge Master
    logic          mi_h2c_rd_brg_dat; // Bridge Master
    logic          mi_c2h3_dat;  // XDMA C2H3; MDMA AVL RING 
    logic          mi_c2h2_dat;  // XDMA C2H2
    logic          mi_c2h1_dat;  // XDMA C2H1; MDMA MM1
    logic          mi_c2h0_dat;  // XDMA C2H0; MDMA MM0
    logic          mi_h2c3_dat;  // XDMA H2C3  MDMA C2H ST PAYLOAD
    logic          mi_h2c2_dat;  // XDMA H2C2  MDMA H2C ST
    logic          mi_h2c1_dat;  // XDMA H2C1; MDMA MM1
    logic          mi_h2c0_dat;
} dma_reg_ram_t;

typedef struct packed {
    logic [4:0]   rsv;
    logic         wr_req;
    logic  [2:0]  wr_chn;
    logic         wtlp_dat_fifo_ep;
    logic         wpl_fifo_ep;
    logic  [2:0]  brsp_claim_chnl;
    logic  [5:0]  wrreq_cnt;
    logic  [2:0]  bid;
    logic         bvalid;
    logic         bready;
    logic         wvalid;
    logic         wready;
    logic  [2:0]  awid;    
    logic         awvalid;
    logic         awready;
} aximm_wr_misc_dbg_reg_t;

typedef struct packed {
    logic [1:0] rsv;
    logic [5:0] brsp_cnt4;
    logic [5:0] brsp_cnt3;
    logic [5:0] brsp_cnt2;
    logic [5:0] brsp_cnt1;
    logic [5:0] brsp_cnt0;
} aximm_wr_brsp_dbg_reg_t;

typedef struct packed {
    logic [8:0] rsv;
    logic [5:0] pnd_cnt;
    logic       rd_req;
    logic [2:0] rd_chnl;
    logic [2:0] rrsp_claim_chnl;
    logic [2:0] rid;
    logic       rvalid;
    logic       rready;
    logic [2:0] arid;
    logic       arvalid;
    logic       arready;
} aximm_rd_misc_dbg_reg_t;

typedef struct packed {
    logic [1:0] rsv;
    logic [5:0] rrsp_cnt4;
    logic [5:0] rrsp_cnt3;
    logic [5:0] rrsp_cnt2;
    logic [5:0] rrsp_cnt1;
    logic [5:0] rrsp_cnt0;
} aximm_rd_rrsp_dbg_reg_t;

typedef struct packed {
    logic [11:0] nph_avail;
    logic [10:0] RcbAvail;
    logic [6:0]  slv_rd_credits;
    logic [1:0]  tag_ep; 
} dma_pcie_rq0_dbg_reg_t;

typedef struct packed {
    logic [ 9:0] rsv;
    logic [1:0]  tag_fl;
    logic        wtlp_hdr_fifo_fl;
    logic        wtlp_hdr_fifo_ep;
    logic        rq_fifo_ep;
    logic        rq_fifo_fl;
    logic [2:0]  tlpsm;
    logic [2:0]  tlpsm512;
    logic       rreq_rcb_ok;
    logic       rreq0_slv;
    logic       rreq0_vld;
    logic       rreq0_rdy;
    logic       rreq1_slv;
    logic       rreq1_vld;
    logic       rreq1_rdy;
    logic       wtlp_req;
    logic       wtlp_straddle;
} dma_pcie_rq1_dbg_reg_t;

typedef struct packed {
    logic           h2c_inb_conv_in_vld;
    logic           h2c_inb_conv_in_rdy;
    logic           h2c_seg_in_vld;
    logic           h2c_seg_in_rdy;
    logic [3:0]     h2c_seg_out_vld;
    logic           h2c_seg_out_rdy;
    logic [6:0]     h2c_mst_crdt_stat;
    logic           c2h_slv_afifo_full;
    logic           c2h_slv_afifo_empty;
    logic [3:0]     c2h_deseg_seg_vld;
    logic           c2h_deseg_seg_rdy;
    logic           c2h_deseg_out_vld;
    logic           c2h_deseg_out_rdy;
    logic           c2h_inb_deconv_out_vld;
    logic           c2h_inb_deconv_out_rdy;
    logic           c2h_dsc_crdt_afifo_full;
    logic           c2h_dsc_crdt_afifo_empty;
    logic           irq_in_afifo_full;
    logic           irq_in_afifo_empty;
    logic           imm_crd_afifo_empty;
} dma_fab_dbg0_reg_t;

typedef struct packed {
    logic [6:0]     byp_out_crdt_stat;
    logic [6:0]     tm_dsc_sts_crdt_stat;
    logic           c2h_cmn_afifo_full;
    logic           c2h_cmn_afifo_empty;
    logic [3:0]     c2h_byp_in_afifo_full;
    logic [3:0]     c2h_byp_in_afifo_empty;
    logic [3:0]     h2c_byp_in_afifo_full;
    logic [3:0]     h2c_byp_in_afifo_empty;
} dma_fab_dbg1_reg_t;


`endif
