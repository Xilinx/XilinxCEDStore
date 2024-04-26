`ifndef CPM5_DMA_DEBUG_DEFINES_SVH
`define CPM5_DMA_DEBUG_DEFINES_SVH

typedef struct packed {
    logic  [5:0]  rsv;
    logic   fab_wb_fifo_fl_h2c;
    logic   fab_wb_fifo_wen_h2c;
    logic   fab_wb_fifo_ren_h2c;
    logic   fab_wb_fifo_fl_c2h;
    logic   fab_wb_fifo_wen_c2h;
    logic   fab_wb_fifo_ren_c2h;
    logic   sw_evt_vld;
    logic   sw_evt_sel;
    logic [11:0] sw_evt_qid;
    logic   chn_evt_vld_h2c;
    logic [11:0] chn_evt_qid_h2c;
    logic   chn_evt_vld_c2h;
    logic [11:0] chn_evt_qid_c2h;
    logic   rcp_evt_fl_h2c;
    logic   rcp_evt_ep_h2c;
    logic [5:0]            rcp_evt_fifo_used_h2c;
    logic   rcp_evt_fl_c2h;
    logic   rcp_evt_ep_c2h;
    logic [5:0]            rcp_evt_fifo_used_c2h;
    logic                  ctxt_rvld;
    logic                  fen_vld;
    logic                  imm_vld;
    logic                  sel;
    logic [11:0]           qid;
    logic                  qen;
    logic [1:0]            err;
    logic                  evt_pnd;
    logic                  fetch_pnd;
    logic                  dsc_pnd;
    logic [15:0]           crd_avl;
    logic [15:0]           pidx;  // if imm_vld, imm.idx
    logic [15:0]           cidx;
    logic [1:0]            cancel;
    logic                  rrq_vld;
    logic [15:0]           rrq_adr;
    logic [9:0]            rrq_dsc_len;
    logic [9:0]            rrq_did;
    //logic [3:0]            rrq_cnt_h2c;
    logic                  rrq_spc_h2c;
    //logic [3:0]            rrq_cnt_c2h;
    logic                  rrq_spc_c2h;
    logic                  dcp_arb_vld;
    logic                  dcp_arb_gnt;
    logic                  cpl_sop_h2c;
    logic  [9:0]           cpl_did_h2c;
    logic  [11:3]          cpl_len_h2c;
    logic                  cpl_err_h2c;
    logic                  cpl_sop_c2h;
    logic  [9:0]           cpl_did_c2h;
    logic  [11:3]          cpl_len_c2h;
    logic                  cpl_err_c2h;
    logic                  dsc_out_fl_h2c;
    logic                  dsc_out_vld_h2c;
    logic                  dsc_out_rdy_h2c;
    logic  [11:0]          dsc_out_qid_h2c;
    logic                  dsc_out_fl_c2h;
    logic                  dsc_out_vld_c2h;
    logic                  dsc_out_rdy_c2h;
    logic  [11:0]          dsc_out_qid_c2h;
    logic  [2:0]           dsc_out_fmt_c2h;
} udma_dsc_eng_dbg_t;

typedef struct packed {
    logic [21:0]    rsv;
    
    logic  [3:0]    qinv_cnt;
    logic           wbc_rq_vld;
    logic  [11:0]   wbc_rq_qid;
    logic           wbc_rq_sel;
    logic           wbc_cpl_wbi;
    logic           wbc_cpl_irq;
    logic           wbc_cpl_vld;
    logic           wbc_cpl_rdy;
    logic  [15:0]   wbc_cpl_cidx;
    logic           irq_fifo_fl;
    logic           irq_sel;
    logic  [11:0]   irq_qid;
    logic  [15:0]   irq_cidx;
    logic           err;
    logic           trq_rd;
    logic           trq_wr;
    logic           trq_sel;
    logic  [11:0]   trq_qid;

    logic           crd_rcv_vld;  //
    logic           crd_rcv_fen;  //
    logic           crd_rcv_sel;  //
    logic   [11:0]  crd_rcv_qid; //
    logic   [15:0]  crd_rcv_crdt;   //

    logic           crd_imm_vld;  //
    logic           crd_imm_sel;  //
    logic   [11:0]  crd_imm_qid; //
    logic   [15:0]  crd_imm_idx;  //
    logic   [15:0]  crd_imm_crdt;   //
    logic           ind_rd;
    logic           ind_wr;
    logic           ind_clr;
    logic           ind_inv;
    logic           ind_sel;
    logic  [11:0]   ind_qid;
    logic           ctxt_win_src;
    logic  [15:0]   ctxt_win_sw_wdat;
    logic  [1:0]    ctxt_win_sw_werr;
    logic  [15:0]   ctxt_win_hw_wdat;
    logic  [15:0]   ctxt_win_crd_wdat;
    logic           ctxt_win_crd_wen;
    logic           irq_req;
    logic           irq_arm;
    logic           irq_no_last;
    logic           err_wb_sent;
} udma_dsc_reg_dbg_t;


typedef struct  packed {
    logic [30:0]   rsv;
    logic [11:0]   nph_avail;
    logic [10:0]   RcbAvail;
    logic [7:0]    rcb_claim;
    logic          rreq_rcb_ok;

    logic          rreq0_rdy;
    logic          rreq0_vld;
    logic  [3:0]   rreq0_chn;
    logic          rreq0_slv;
    logic [31:0]   rreq0_adr;
    logic [9:0]    rreq0_tag;
    logic [15:0]   rreq0_fnc;

    logic          rreq1_rdy;
    logic          rreq1_vld;
    logic  [3:0]   rreq1_chn;
    logic          rreq1_slv;
    logic  [31:0]  rreq1_adr;
    logic  [9:0]   rreq1_tag;
    logic  [15:0]  rreq1_fnc;

    logic [6:0]    slv_rd_credits;

    logic [15:0]   pcie_rq_seq_ret;

    logic [2:0]   tlpsm;
    logic [2:0]   tlpsm512;
    logic [9:0]   beatrem;

    //Available in dbg2
    //logic [2:0]   wtlp_sm;
    //logic [3:0]   wrq_chn;
    //logic [31:0]  wrq_adr;
    //logic [5:0]   wrq_aln;
    //logic [10:0]  wrq_dwlen;
    //logic [15:0]  wrq_fnc;
    //logic         wrq_eor;

    logic         wtlp_req;
    logic [3:0]   wtlp_chn;
    logic         wtlp_hdr_eor;
    logic         wtlp_hdr_rd;
    logic [3:0]   wtlp_seq;

    logic         wtlp_straddle;
    logic [3:0]   wtlp_rd_dat0_cnt_nn1;
    logic [3:0]   wtlp_rd_dat1_cnt_nn1;
    logic         wtlp_hdr_fifo_fl;
    logic         wtlp_hdr_fifo_ep;
    logic         rq_fifo_ep;
    logic         rq_fifo_fl;
} dma_pcie_rq_dbg_t; 

//DBG2 struct
typedef struct  packed {
    logic [9:0]    rsv;
    logic [11:0]   nph_avail;
    logic [10:0]   RcbAvail;
    logic [7:0]    rcb_claim;
    logic          rreq_rcb_ok;

    logic          rreq0_rdy;
    logic          rreq0_vld;
    logic [3:0]    rreq0_chn;
    logic          rreq0_slv;
    logic [31:0]   rreq0_adr;
    //logic [9:0]    rreq0_tag;
    //logic [15:0]   rreq0_fnc;

    logic          rreq1_rdy;
    logic          rreq1_vld;
    logic  [3:0]   rreq1_chn;
    logic          rreq1_slv;
    logic  [31:0]  rreq1_adr;
    //logic  [9:0]   rreq1_tag;
    //logic  [15:0]  rreq1_fnc;

    logic [6:0]    slv_rd_credits;

    logic [15:0]   pcie_rq_seq_ret;

    logic [2:0]   tlpsm;
    logic [2:0]   tlpsm512;
    logic [9:0]   beatrem;

    logic [2:0]   wtlp_sm;
    logic [3:0]   wrq_chn;
    logic [31:0]  wrq_adr;
    logic [5:0]   wrq_aln;
    logic [10:0]  wrq_dwlen;
    logic [15:0]  wrq_fnc;
    logic         wrq_eor;

    logic         wtlp_req;
    logic [3:0]   wtlp_chn;
    logic         wtlp_hdr_eor;
    logic         wtlp_hdr_rd;
    logic [3:0]   wtlp_seq;

    logic         wtlp_straddle;
    logic [3:0]   wtlp_rd_dat0_cnt_nn1;
    logic [3:0]   wtlp_rd_dat1_cnt_nn1;
    logic         wtlp_hdr_fifo_fl;
    logic         wtlp_hdr_fifo_ep;
    logic         rq_fifo_ep;
    logic         rq_fifo_fl;
} dma_pcie_rq_dbg2_t; 

typedef struct packed {
    logic [90:0]    rsv;
    logic           ld_stg1_2_stg2;
    logic           tlp_stg2_sop;
    logic [3:0]     tlp_stg2_sop_loc;
    logic           tlp_stg2_eop;
    logic           tlp_stg2_nopload;
    logic           tlp_stg2_dw_en;
    //logic [511:0]   tlp_stg2_pload;
    logic [7:0]     tlp_stg2_rc_tag;
    logic [5:0]     tlp_stg2_hdr_addr50;
    logic [12:0]    tlp_stg2_hdr_bytecnt;
    logic           tlp_stg2_cfg_tag;
    logic           tlp_stg2_hdr_rcmpl;
    logic [2:0]     tlp_stg2_hdr_stat;
    logic           tlp_stg2_hdr_poison;
    logic [7:0]     tlp_stg2_hdr_fnc;
    logic           tlp_stg2_hdr_error;
    logic           tlp_stg2_parityerr;
    logic [4:0]     tlp_stg2_dw_cnt;

    logic           dw_tlp_1_sop;
    logic           dw_tlp_2_sop;
    logic           dw_tlp_3_sop;
    logic           dw_tlp_4_sop;
    logic [3:0]     dw_tlp_1_sop_ch;
    logic [3:0]     dw_tlp_2_sop_ch;
    logic [3:0]     dw_tlp_3_sop_ch;
    logic [3:0]     dw_tlp_4_sop_ch;
    logic           dw_tlp_0_eop;
    logic           dw_tlp_1_eop;
    logic           dw_tlp_2_eop;
    logic           dw_tlp_3_eop;
    logic           dw_tlp_4_eop;
    logic [3:0]     dw_tlp_0_eidx;
    logic [3:0]     dw_tlp_1_eidx;
    logic [3:0]     dw_tlp_2_eidx;
    logic [3:0]     dw_tlp_3_eidx;
    logic [3:0]     dw_tlp_4_eidx;

    logic [3:0]     rclp_mem_chn;
    logic [9:0]     rclp_tlp_did;
    logic [9:0]     rclp_tlp_rid;
    logic           rclp_tlp_sop;
    logic           rclp_tlp_eop;
    logic [7:0]     rclp_tlp_func;
    logic [3:0]     rclp_tlp_errc;
    logic           rclp_tlp_parityerr;
    logic           rclp_cfg_valid;
    logic           rclp_err_cmp_vld;
    logic           rclp_tlp_tagdone;
    logic [7:0]     rclp_tlp_tag;
    logic [9:0]     rclp_err_cmp_btrem;
    logic [2:0]     rclp_cfg_status;
} dma_pcie_rc_dbg_t;

typedef struct packed {
    logic [206:0] rsv;
    logic [1:0] tag_ep;
    logic [1:0] tag_fl;

    logic       rrq_cancel;
    logic       rrq_vld;
    logic       rrq_rdy;
    logic [3:0] rrq_chn;
    logic [15:0] rrq_fnc;

    logic       wrq_cancel;
    logic       wrq_vld;
    logic [3:0] wrq_chn;
    logic [15:0] wrq_fnc;
} dma_pcie_req_dbg_t;

typedef struct packed {
    logic [31-9:0]   rsv;
    logic          dsc_fl;
    logic          dsc_ep;
    logic  [15:0]  dsc_cidx;
    logic  [11:0]  dsc_qid;
    logic  [31:0]  dsc_radr;
    logic  [31:0]  dsc_wadr;
    logic  [27:0]  dsc_len;
    logic          dsc_stp;
    logic          dsc_cpl;
    logic          dsc_eop;
    logic  [7:0]   wrq_sm_cur;
    logic  [6:0]   rrq_sm_cur;
    logic  [5:0]   rrq_entries;
    logic  [5:0]   rrq_rid;
    logic  [11:0]  rrq_qid;
    logic  [15:0]  rrq_idx;
    logic          rrq_vld;
    logic          rcp_vld;
    logic  [5:0]   rcp_rid;
    logic          rcp_eop;
    logic  [4:0]   rcp_errc;
    logic          rcp_err2;
    logic          wrq_vld;
    logic [11:0]   wrq_qid;
    logic [15:0]   wrq_idx;
    logic          wcp_vld;
    logic [5:0]    wcp_rid;
    logic          wcp_any;
    logic          wcp_err;
} dma_rdwr_eng_dbg_t;
typedef struct packed {
    logic   [81:0]    rsv;
    logic   [8:0]     rrq_head_did;
    logic   [11:0]    rrq_head_len;
    logic   [31:0]    rrq_head_adr;
    logic   [2:0]     rrq_head_chn;
    logic             rrq_head_vld;
    logic             rrq_arb_win;
    logic   [7:0]     rrq_arb_winner;
    logic   [7:0]     reg_ch_dsc_run;
    logic   [7:0]     chn_rrq_pnd;
    logic   [7:0]     chn_rrq_0len;
    logic   [7:0]     chn_crd_avl;
    logic   [7:0]     chn_spc_avl;
    logic   [3:0]     rcp_rid;
    logic   [8:0]     rcp_did;
    logic             rcp_vld;
    logic   [4:0]     rcp_errc;
    logic             rcp_err2;
    logic   [31:0]    rcp_nxt_adr;

    logic   [7:0]     dcp_vld;
    logic   [7:0]     dcp_rdy;
} xdma_dsc_eng_dbg_t;

typedef struct packed {
    logic [5:0]     rsv;
    tcp_t           tcp_qspc;
    trq_t           trq_qspc;
    tcp_t           tcp;
    trq_t           trq;
} dma_trq_dbg_t;

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
    logic [2:0]     c2h_wrb_crdt_stat;
    logic [1:0][6:0] byp_out_crdt_stat;
    logic [6:0]     tm_dsc_sts_crdt_stat;
    logic [6:0]     sts_crdt_stat;
    logic           c2h_dsc_crdt_afifo_full;
    logic           c2h_dsc_crdt_afifo_empty;
    logic           imm_crd_afifo_full;
    logic           imm_crd_afifo_empty;
    logic           irq_in_afifo_full;
    logic           irq_in_afifo_empty;
} dma_mdma_fab_mux_dbg_t;

typedef struct packed {
    logic [3:0][8:0]    h2c_mst_crdt_stat;
    logic [3:0][2:0]    h2c_byp_in_crdt_stat;
    logic [3:0][2:0]    c2h_byp_in_crdt_stat;
    logic               irq_in_afifo_full;
    logic               irq_in_afifo_empty;
    logic               axis_cmp_afifo_full;
    logic               axis_cmp_afifo_empty;
} dma_xdma_fab_mux_dbg_t;

typedef struct packed {
    logic [29:0]    rsv;
    logic           fab_mst_crd_rst;
    logic           fab_slv_crd_rls_en;
    logic [7:0]     mgmt_cpl_mst_crdt_stat;
    logic           mgmt_req_slv_fifo_full;
    logic           mgmt_req_slv_fifo_empty;
    logic [7:0]     vdm_mst_crdt_stat;
    logic           cfg_ext_in_afifo_full;
    logic           cfg_ext_in_afifo_empty;
    logic           cfg_ext_out_afifo_full;
    logic           cfg_ext_out_afifo_empty;
    logic           c2h_drop_afifo_full;
    logic           c2h_drop_afifo_empty;
    logic           c2h_pcie_cmp_afifo_full;
    logic           c2h_pcie_cmp_afifo_empty;
    logic           flr_out_afifo_full;
    logic           flr_out_afifo_empty;
    logic           flr_in_afifo_full;
    logic           flr_in_afifo_empty;
    logic           axi_intr_afifo_full;
    logic           axi_intr_afifo_empty;
} dma_hard_fab_shim_dbg_t;

typedef struct packed {
    logic [57:0]    rsv;
    logic           c2h_cmn_afifo_full;
    logic           c2h_cmn_afifo_empty;
    logic           c2h_byp_in_afifo_full;
    logic           c2h_byp_in_afifo_empty;
    logic           h2c_byp_in_afifo_full;
    logic           h2c_byp_in_afifo_empty;
} dma_fab_mux_tl_slv_dbg_t;

typedef struct packed {
    dma_mdma_fab_mux_dbg_t      mdma_fab_mux_dbg;
    dma_xdma_fab_mux_dbg_t      xdma_fab_mux_dbg;
    dma_hard_fab_shim_dbg_t     hard_fab_shim_dbg;
    dma_fab_mux_tl_slv_dbg_t    fab_mux_tl_slv_dbg;
} dma_fab_dbg_t;

    typedef union packed {
        dma_trq_dbg_t                  dma_trq_dbg;
        dma_pcie_rq_dbg_t              dma_pcie_rq_dbg;
        dma_pcie_rq_dbg2_t             dma_pcie_rq_dbg2;
        dma_pcie_rc_dbg_t              dma_pcie_rc_dbg;
        dma_pcie_req_dbg_t             dma_pcie_req_dbg;
        dma_rdwr_eng_dbg_t             dma_rdwr_eng_dbg;
        xdma_dsc_eng_dbg_t             xdma_dsc_eng_dbg;          
        udma_dsc_eng_dbg_t             udma_dsc_eng_dbg;          
        udma_dsc_reg_dbg_t             udma_dsc_reg_dbg;          
        dma_fab_dbg_t                  dma_fab_dbg;
        logic [255:0]                  dma_debug;
    } dma_debug_t;
localparam DMA_RDWR_ENG_DBG_SIZE = $bits(dma_rdwr_eng_dbg_t);
localparam DSC_ENG_DBG_SIZE = $bits(udma_dsc_eng_dbg_t);
localparam DSC_REG_DBG_SIZE = $bits(udma_dsc_reg_dbg_t);
localparam DMA_PCIE_RQ_DBG_SIZE = $bits(dma_pcie_rq_dbg_t);
localparam DMA_PCIE_RQ_DBG2_SIZE = $bits(dma_pcie_rq_dbg2_t);
localparam DMA_PCIE_REQ_DBG_SIZE = $bits(dma_pcie_req_dbg_t);
localparam DMA_PCIE_RC_DBG_SIZE = $bits(dma_pcie_rc_dbg_t);
localparam DMA_TRQ_DBG_SIZE     = $bits(dma_trq_dbg_t);
localparam DMA_FAB_DBG_SIZE     = $bits(dma_fab_dbg_t);
`endif
