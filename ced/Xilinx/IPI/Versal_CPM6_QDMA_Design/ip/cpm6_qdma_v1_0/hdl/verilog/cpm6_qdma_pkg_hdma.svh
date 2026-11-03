`ifndef CPM6_QDMA_PKG_HDMA_SVH
`define CPM6_QDMA_PKG_HDMA_SVH

typedef struct packed {
  logic [26:0] rsvd_1;
  logic        rw_ie;
  logic        lw_ie;
  logic        llp;
  logic        rsvd_0;
  logic        cycle_bit;
  logic [31:0] transfer_size;
  logic [31:0] source_address_low;
  logic [31:0] source_address_high;
  logic [31:0] destination_address_low;
  logic [31:0] destination_address_high;
} hdma_desc_t;


typedef struct packed {
  logic [63:0] rsvd1;
  logic [63:0] dst_addr;
  logic [35:0] rsvd0;
  logic [27:0] length;
  logic [63:0] src_addr;
} qdma_mm_desc_t;

typedef struct packed {
  logic [31:0] addr_h;
  logic [31:0] addr_l;  
  logic [15:0] rsvd;
  logic [15:0] length;
  logic [31:0] metadata;
} qdma_h2c_st_desc_t;

typedef struct packed {
  logic [63:0] dst_addr;
} qdma_c2h_st_desc_t;

typedef struct packed {
  logic [31:0] addr_h;
  logic [31:0] addr_l;
  logic [15:0] rsvd;
  logic [15:0] length;
  logic [31:0] metadata;
} qdma_c2h_st_16b_desc_t;

//No support for mixed st/mm/c2h/h2c, it is expected to only fetch in one type and a max of 8 descriptors at a time
typedef struct packed {
  union packed {
    qdma_mm_desc_t    mm;
    struct packed {
      qdma_h2c_st_desc_t h2c_st_1;
      qdma_h2c_st_desc_t h2c_st_0;
    } h2c_st;
    struct packed {
      qdma_c2h_st_desc_t c2h_st_3;
      qdma_c2h_st_desc_t c2h_st_2;
      qdma_c2h_st_desc_t c2h_st_1;
      qdma_c2h_st_desc_t c2h_st_0;
    } c2h_st;
    struct packed {
      qdma_c2h_st_16b_desc_t c2h_st_16b_1;
      qdma_c2h_st_16b_desc_t c2h_st_16b_0;
    } c2h_st_16b;
  } desc;
} qdma_desc_t;

typedef struct packed {
  qdma_desc_t desc_1;
  qdma_desc_t desc_0;
} qdma_grp_dsc_t;

typedef struct packed {
  logic [15:0] rsvd1;
  logic [15:0] pidx;
  logic [15:0] cidx;
  logic [13:0] rsvd2;
  logic [1:0]  err;
} qdma_wb_data_t;

typedef struct packed {
  logic [208:0] _r1;
  logic [3:0]   fetch_pnd;
  logic         evt_pnd;
  logic         idl_stp_b;
  logic         dsc_pnd;
  logic [7:0]   _r0;
  logic [15:0]  crd_use;
  logic [15:0]  cidx;
} qdma_hw_ctxt_t;

typedef struct packed {
  logic [115:0] _r2;
  logic         int_aggr;
  logic [10:0]  vec;
  logic [63:0]  dsc_base;
  logic         is_mm;
  logic         mkr_dis;
  logic         irq_req;
  logic         err_wb_sent;
  logic [1:0]   err;
  logic         irq_no_last;
  logic [2:0]   port_id;
  logic         irq_en;
  logic         wbk_en;
  logic         mm_chn;
  logic         bypass;
  logic [1:0]   dsc_sz;
  logic [3:0]   rng_sz;
  logic [2:0]   _r1;
  logic [3:0]   fetch_max;
  logic         at;
  logic         wbi_intvl_en;
  logic         wbi_chk;
  logic         fcrd_en;
  logic         qen;
  logic [6:0]   _r0;
  logic [7:0]   fnc_id;
  logic         irq_arm;
  logic [15:0]  pidx;
} qdma_sw_ctxt_t;

localparam integer QID_WIDTH            = 12;    // SV §26.2.1: package items must be localparam
localparam [31:0]  RING_SIZE            = 2048;
localparam integer DSC_FETCH_MAX_QID    = 7;
typedef struct packed {
         logic vld;
         logic [QID_WIDTH+1:0] qid_info;//includes {qid_st/mm,qid_dir,qid}
         logic [$clog2(RING_SIZE)-1:0] cidx;
         logic [$clog2(DSC_FETCH_MAX_QID)-1:0] fetch_cnt;
} dsc_slot_t;
typedef struct packed {
         logic [QID_WIDTH-1:0] qid;//includes {qid_st/mm,qid_dir,qid}
         logic [$clog2(RING_SIZE)-1:0] cidx;
} qid_cidx_t;

`endif