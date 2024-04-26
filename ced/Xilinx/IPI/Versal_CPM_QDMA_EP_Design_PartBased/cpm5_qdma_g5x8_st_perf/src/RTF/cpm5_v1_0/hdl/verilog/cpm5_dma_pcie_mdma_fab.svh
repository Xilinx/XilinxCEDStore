
`ifndef CPM5_MDMA_FAB_SVH
`define CPM5_MDMA_FAB_SVH


    localparam    MDMA_DSC_IN_NUM_CHNL          = 3;

    //Pick the larger of the 2 structs to determine the input data width of byp_out down-converter
    localparam MAX_BYP_OUT_DMA_DSC_BITS = ($bits(mdma_h2c_byp_dsc_out_t) > $bits(mdma_c2h_byp_dsc_out_t)) ? $bits(mdma_h2c_byp_dsc_out_t) :
                                                                                                            $bits(mdma_c2h_byp_dsc_out_t);
    //byp_out conv uses a div-by-2 ratio
    //hence DMA_DSC_BITS parameter of the byp_out conv should be a multiple of 2
    localparam BYP_OUT_DMA_DSC_BITS = (MAX_BYP_OUT_DMA_DSC_BITS%2 == 0) ? MAX_BYP_OUT_DMA_DSC_BITS : MAX_BYP_OUT_DMA_DSC_BITS+1;
    localparam BYP_OUT_TL_DSC_BITS  = BYP_OUT_DMA_DSC_BITS/2;

// Bypass out. Multiplexes H2c and C2H.
typedef struct packed {
    logic [BYP_OUT_TL_DSC_BITS-1:0] data;
    logic                       last;
    logic                       vld;
    logic                       dir; //0 - H2C, 1-C2H
} mdma_dsc_byp_out_oif_t;

typedef struct packed {
    logic               crdt;
    logic               dir;
} mdma_dsc_byp_out_iif_t;

//Bypass In
typedef struct packed {
    logic               crdt;
    logic [2:0]         rd_out;
} mdma_dsc_c2h_byp_in_oif_t;

typedef struct packed {
    logic               crdt;
    logic [2:0]         rd_out;
} mdma_dsc_h2c_byp_in_oif_t;

typedef struct packed {
    logic [169:0]              dat;
    logic                      last;
    logic                      vld;
    logic [1:0]                ch;
} mdma_h2c_dsc_byp_in_iif_t;

typedef struct packed {
    logic [169:0]              dat;
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
    logic [MDMA_C2H_WRB_TL_BITS-1:0]  tl_data;
    mdma_c2h_wrb_user_t               user;
    logic                             last;
    logic                             vld;
    logic [0:0]                       ch;
} mdma_c2h_wrb_axis_iif_t;

// H2C AXI Streaming
localparam MDMA_H2C_AXIS_DATA_BITS = 512;
localparam MDMA_H2C_AXIS_TUSER_BITS = $bits(mdma_h2c_axis_unal_tuser_t);
localparam MDMA_H2C_AXIS_NUM_SEG = 4;
localparam MDMA_C2H_AXIS_NUM_SEG = 4;

typedef struct packed {
    logic               crdt;
} mdma_h2c_axis_iif_t;

typedef struct packed {
    logic               crdt;
} mdma_tm_dsc_sts_iif_t;

typedef struct packed {
    logic               crdt;
} mdma_sts_out_iif_t;

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
    logic [MDMA_H2C_AXIS_NUM_SEG-1:0]           seg_vld;
    logic [MDMA_H2C_AXIS_NUM_SEG-1:0][128-1:0]  seg_data;
    logic [MDMA_H2C_AXIS_NUM_SEG-1:0]           seg_eop;
    logic [3:0]                                 seg_mty;
} mdma_h2c_axis_seg_t;

typedef struct packed {
    logic               valid;
    mdma_h2c_axis_seg_t data;
} mdma_h2c_axis_seg_oif_t;

//Single member used as ready (level) or credit (pulse) depending on the interface
typedef union packed {
    logic ready;
    logic crdt;
} mdma_h2c_axis_seg_iif_t;

typedef struct packed {
    logic [MDMA_C2H_AXIS_NUM_SEG-1:0]           seg_vld;
    logic [MDMA_C2H_AXIS_NUM_SEG-1:0][128-1:0]  seg_data;
    logic [MDMA_C2H_AXIS_NUM_SEG-1:0]           seg_eop;
    logic [3:0]                                 seg_mty;
} mdma_c2h_axis_seg_t;

typedef struct packed {
    logic               valid;
    mdma_c2h_axis_seg_t data;
} mdma_c2h_axis_seg_iif_t;

//Single member used as ready (level) or credit (pulse) depending on the interface
typedef union packed {
    logic ready;
    logic crdt;
} mdma_c2h_axis_seg_oif_t;

typedef struct packed {
    logic               tvalid;
    logic [35:0]        tl_data;
    logic               tlast;
} mdma_tm_dsc_sts_oif_t;

typedef struct packed {
    logic               tvalid;
    logic [24:0]        tl_data;
    logic               tlast;
} mdma_sts_out_oif_t;

//    localparam MDMA_FAB_IN_BITS=1353;
    localparam MDMA_FAB_IN_BITS=`DMA_FABRIC_IN_WIDTH - $bits(com_fab_iif_t);
    //localparam MDMA_FAB_OUT_BITS=(231+759) - 8;    // 8 Bits taken away
//    localparam MDMA_FAB_OUT_BITS=1500;
    localparam MDMA_FAB_OUT_BITS=`DMA_FABRIC_OUT_WIDTH - $bits(com_fab_oif_t);
    localparam mdma_fab_oif_rsv_bits=MDMA_FAB_OUT_BITS-
     $bits(mdma_sts_out_oif_t)-
     $bits(mdma_dsc_imm_crd_oif_t) -                                  
     $bits(mdma_usr_irq_if_out_t) - 
     $bits(mdma_dsc_byp_out_oif_t)-
     $bits(mdma_dsc_h2c_byp_in_oif_t)-
     $bits(mdma_dsc_c2h_byp_in_oif_t)-
     $bits(mdma_c2h_axis_seg_oif_t)-
     $bits(mdma_c2h_wrb_axis_oif_t)-
     $bits(mdma_h2c_axis_seg_oif_t)-
     $bits(mdma_tm_dsc_sts_oif_t)-
     $bits(mdma_c2h_dsc_crdt_oif_t);

typedef struct packed {
    logic [mdma_fab_oif_rsv_bits-1:0] rsv;
    mdma_sts_out_oif_t           sts_out;
    mdma_dsc_imm_crd_oif_t       imm_crd;
    mdma_usr_irq_if_out_t        irq_out;
    mdma_dsc_byp_out_oif_t       byp_out;
    mdma_dsc_h2c_byp_in_oif_t    h2c_byp_in;
    mdma_dsc_c2h_byp_in_oif_t    c2h_byp_in;
    mdma_c2h_axis_seg_oif_t      seg_c2h_axis;
    mdma_c2h_wrb_axis_oif_t      c2h_wrb_axis;
    mdma_h2c_axis_seg_oif_t      seg_h2c_axis; 
    mdma_tm_dsc_sts_oif_t        tm_dsc_sts;
    mdma_c2h_dsc_crdt_oif_t      c2h_dsc_crdt;
} mdma_fab_oif_t;

localparam MDMA_FAB_IN_RSV_BITS = MDMA_FAB_IN_BITS - 
     $bits(mdma_sts_out_iif_t) -
     $bits(mdma_dsc_imm_crd_iif_t) -
     $bits(mdma_usr_irq_if_in_t) - 
     $bits(mdma_dsc_byp_out_iif_t) -
     $bits(mdma_h2c_dsc_byp_in_iif_t) - 
     $bits(mdma_c2h_dsc_byp_in_iif_t) - 
     $bits(mdma_c2h_axis_seg_iif_t) - 
     $bits(mdma_c2h_wrb_axis_iif_t) - 
     $bits(mdma_h2c_axis_seg_iif_t) - 
     $bits(mdma_tm_dsc_sts_iif_t) - 
     $bits(mdma_c2h_dsc_crdt_iif_t);

typedef struct packed {
    logic [MDMA_FAB_IN_RSV_BITS-1:0] rsv;
    mdma_sts_out_iif_t               sts_out;
    mdma_dsc_imm_crd_iif_t           imm_crd;
    mdma_usr_irq_if_in_t             irq_in;
    mdma_dsc_byp_out_iif_t           byp_out;
    mdma_h2c_dsc_byp_in_iif_t        h2c_byp_in;
    mdma_c2h_dsc_byp_in_iif_t        c2h_byp_in;
    mdma_c2h_axis_seg_iif_t          seg_c2h_axis;
    mdma_c2h_wrb_axis_iif_t          c2h_wrb_axis;
    mdma_h2c_axis_seg_iif_t          seg_h2c_axis;
    mdma_tm_dsc_sts_iif_t            tm_dsc_sts;
    mdma_c2h_dsc_crdt_iif_t          c2h_dsc_crdt;
} mdma_fab_iif_t;

typedef union packed {
    logic [MDMA_FAB_IN_BITS-1:0]     chk;
    mdma_fab_iif_t                  fab_in;
} mdma_fab_iif_chk_t;

typedef union packed {
    logic [MDMA_FAB_OUT_BITS-1:0]   chk;
    mdma_fab_oif_t                  fab_out;
} mdma_fab_oif_chk_t;

`endif
