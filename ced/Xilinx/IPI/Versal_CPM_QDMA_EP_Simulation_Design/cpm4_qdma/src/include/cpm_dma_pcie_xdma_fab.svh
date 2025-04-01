
`ifndef DMA_PCIE_XDMA_FAB_SVH
    `define DMA_PCIE_XDMA_FAB_SVH
`include "cpm_dma_defines.svh"

`timescale 1 ps / 1 ps// Bypass out. Multiplexes H2c and C2H.
typedef struct packed {
    logic [127:0]       dsc;
    logic [15:0]        cidx;
    logic               last;
    logic               vld;
    logic               dir; //0 - H2C, 1-C2H
    logic [1:0]         ch;
} xdma_dsc_byp_out_oif_t;

typedef struct packed {
    logic               crdt;
    logic               dir;
    logic [1:0]         crdt_ch;
} xdma_dsc_byp_out_iif_t;

// VDM
typedef struct packed {
    logic [15:0]                data;
    logic                       sb;
    logic                       last;
    logic                       vld;
} xdma_vdm_oif_t;

// VDM
typedef struct packed {
    logic                       crdt;
} xdma_vdm_iif_t;

//Bypass In
typedef struct packed {
    logic               crdt;
    logic [1:0]         crdt_ch;
} xdma_dsc_byp_in_oif_t;

typedef struct packed {
    logic [127:0]        dsc; 
    logic [15:0]        cidx;
    logic               last;
    logic               vld;
    logic [1:0]         ch;
} xdma_dsc_byp_in_iif_t;

localparam C_C2H_AXIS_DATA_BITS = 512;
localparam C_C2H_AXIS_TUSER_BITS = 64;
// C2H AXI Streaming
typedef struct packed {
    logic               crdt;
    logic [1:0]         crdt_ch;
} xdma_c2h_axis_oif_t;


typedef struct packed {
    logic               tvalid;
    logic [1:0]         tch;
    logic [C_C2H_AXIS_DATA_BITS-1:0]    tdata;
    logic [C_C2H_AXIS_DATA_BITS/8 -1:0] tparity;
    logic                               tlast;
    logic [C_C2H_AXIS_TUSER_BITS-1:0]   tuser;
    logic [C_C2H_AXIS_DATA_BITS/8-1:0]  tkeep;
} xdma_c2h_axis_iif_t;

// H2C AXI Streaming
localparam C_H2C_AXIS_DATA_BITS = 512;
localparam C_H2C_AXIS_TUSER_BITS = 32;
typedef struct packed {
    logic               crdt;
    logic [1:0]         crdt_ch;
} xdma_h2c_axis_iif_t;

typedef struct packed {
    logic               tvalid;
    logic [1:0]         tch;
    logic [C_H2C_AXIS_DATA_BITS-1:0]    tdata;
    logic [C_H2C_AXIS_DATA_BITS/8 -1:0] tparity;
    logic                               tlast;
    logic [C_H2C_AXIS_TUSER_BITS-1:0]   tuser;
    logic [C_H2C_AXIS_DATA_BITS/8-1:0]  tkeep;
} xdma_h2c_axis_oif_t;

    localparam XDMA_FAB_IN_BITS=1353;
    localparam XDMA_FAB_OUT_BITS=(231+759)-8;  //Fabic C + fabric A - 8 bits

    localparam fab_oif_rsv_bits=XDMA_FAB_OUT_BITS-
     1 - 
     32 -
     32 -
     $bits(dma_mgmt_req_if_out_t) - 
     $bits(dma_mgmt_cpl_if_out_t) - 
     $bits(xdma_usr_irq_if_out_t) - 
     $bits(usr_flr_if_out_t) -
     $bits(dma_err_out_t)    -                            
     $bits(xdma_dsc_byp_out_oif_t)-
     $bits(xdma_vdm_oif_t)-
     $bits(xdma_dsc_byp_in_oif_t)-
     $bits(xdma_dsc_byp_in_oif_t)-
     $bits(xdma_c2h_axis_oif_t)-
     $bits(xdma_h2c_axis_oif_t) -
     1;
typedef struct packed {
    logic [fab_oif_rsv_bits-1:0] rsv;   
    logic                        dma_irq_out;
    logic [3:0][7:0]             c2h_sts;
    logic [3:0][7:0]             h2c_sts;
    xdma_vdm_oif_t               vdm;
    dma_mgmt_req_if_out_t        dma_mgmt_req;
    dma_mgmt_cpl_if_out_t        dma_mgmt_cpl;
    xdma_usr_irq_if_out_t   irq_out;
    usr_flr_if_out_t        flr_out;
    dma_err_out_t           dma_err_out;
    xdma_dsc_byp_out_oif_t  byp_out;
    xdma_dsc_byp_in_oif_t   h2c_byp_in;
    xdma_dsc_byp_in_oif_t   c2h_byp_in;
    xdma_c2h_axis_oif_t  c2h_axis;
    xdma_h2c_axis_oif_t  h2c_axis;  
    logic                axi_resetn;
} xdma_fab_oif_t;

localparam XDMA_FAB_IN_RSV_BITS = XDMA_FAB_IN_BITS -  
     4 - 
     $bits(dma_mgmt_req_if_in_t) - $bits(dma_mgmt_cpl_if_in_t) - 
     $bits(xdma_usr_irq_if_in_t) - $bits(usr_flr_if_in_t) - 
     $bits(xdma_dsc_byp_out_iif_t) - $bits(xdma_vdm_iif_t) - 2*$bits(xdma_dsc_byp_in_iif_t) - $bits(xdma_c2h_axis_iif_t) - $bits(xdma_h2c_axis_iif_t) - 
     1;



typedef struct packed {
    logic [XDMA_FAB_IN_RSV_BITS-1:0] rsv;
    logic  [3:0]                    h2c_axis_cmp;
    xdma_vdm_iif_t                  vdm;
    dma_mgmt_req_if_in_t            dma_mgmt_req;
    dma_mgmt_cpl_if_in_t            dma_mgmt_cpl;
    xdma_usr_irq_if_in_t            irq_in;
    usr_flr_if_in_t                 flr_in;
    xdma_dsc_byp_out_iif_t          byp_out;
    xdma_dsc_byp_in_iif_t           h2c_byp_in;
    xdma_dsc_byp_in_iif_t           c2h_byp_in;
    xdma_c2h_axis_iif_t             c2h_axis;
    xdma_h2c_axis_iif_t             h2c_axis;
    logic                           dma_reset;
} xdma_fab_iif_t;

typedef union packed {
    logic [XDMA_FAB_IN_BITS-1:0]    chk;
    xdma_fab_iif_t                  fab_in;
} xdma_fab_iif_chk_t;

typedef union packed {
    logic [XDMA_FAB_OUT_BITS-1:0]   chk;
    xdma_fab_oif_t                  fab_out;
} xdma_fab_oif_chk_t;

localparam   XDMA_FAB_OUT_H2C_AXIS_START      = 1;
localparam   XDMA_FAB_OUT_C2H_AXIS_START      = XDMA_FAB_OUT_H2C_AXIS_START      + $bits(xdma_h2c_axis_oif_t   );
localparam   XDMA_FAB_OUT_C2H_BYP_IN_START    = XDMA_FAB_OUT_C2H_AXIS_START      + $bits(xdma_c2h_axis_oif_t   );
localparam   XDMA_FAB_OUT_H2C_BYP_IN_START    = XDMA_FAB_OUT_C2H_BYP_IN_START    + $bits(xdma_dsc_byp_in_oif_t );
localparam   XDMA_FAB_OUT_BYP_OUT_START       = XDMA_FAB_OUT_H2C_BYP_IN_START    + $bits(xdma_dsc_byp_in_oif_t );
localparam   XDMA_FAB_OUT_DMA_ERR_OUT_START   = XDMA_FAB_OUT_BYP_OUT_START       + $bits(xdma_dsc_byp_out_oif_t);
localparam   XDMA_FAB_OUT_FLR_OUT_START       = XDMA_FAB_OUT_DMA_ERR_OUT_START   + $bits(dma_err_out_t        );
localparam   XDMA_FAB_OUT_IRQ_OUT_START       = XDMA_FAB_OUT_FLR_OUT_START       + $bits(usr_flr_if_out_t     );
localparam   XDMA_FAB_OUT_DMA_MGMT_CPL_START  = XDMA_FAB_OUT_IRQ_OUT_START       + $bits(xdma_usr_irq_if_out_t);
localparam   XDMA_FAB_OUT_DMA_MGMT_REQ_START  = XDMA_FAB_OUT_DMA_MGMT_CPL_START  + $bits(dma_mgmt_cpl_if_out_t);
localparam   XDMA_FAB_OUT_VDM_START           = XDMA_FAB_OUT_DMA_MGMT_REQ_START  + $bits(dma_mgmt_req_if_out_t);
localparam   XDMA_FAB_OUT_H2C_STS_START       = XDMA_FAB_OUT_VDM_START           + $bits(xdma_vdm_oif_t       );
localparam   XDMA_FAB_OUT_C2H_STS_START       = XDMA_FAB_OUT_H2C_STS_START       + 32;



localparam   XDMA_FAB_IN_H2C_AXIS_START       = 0;
localparam   XDMA_FAB_IN_C2H_AXIS_START       =  XDMA_FAB_IN_H2C_AXIS_START      + $bits(xdma_h2c_axis_iif_t   );
localparam   XDMA_FAB_IN_C2H_BYP_IN_START     =  XDMA_FAB_IN_C2H_AXIS_START      + $bits(xdma_c2h_axis_iif_t   );
localparam   XDMA_FAB_IN_H2C_BYP_IN_START     =  XDMA_FAB_IN_C2H_BYP_IN_START    + $bits(xdma_dsc_byp_in_iif_t );
localparam   XDMA_FAB_IN_BYP_OUT_START        =  XDMA_FAB_IN_H2C_BYP_IN_START    + $bits(xdma_dsc_byp_in_iif_t );
localparam   XDMA_FAB_IN_FLR_IN_START         =  XDMA_FAB_IN_BYP_OUT_START       + $bits(xdma_dsc_byp_out_iif_t);
localparam   XDMA_FAB_IN_IRQ_IN_START         =  XDMA_FAB_IN_FLR_IN_START        + $bits(usr_flr_if_in_t       );
localparam   XDMA_FAB_IN_DMA_MGMT_CPL_START   =  XDMA_FAB_IN_IRQ_IN_START        + $bits(xdma_usr_irq_if_in_t  );
localparam   XDMA_FAB_IN_DMA_MGMT_REQ_START   =  XDMA_FAB_IN_DMA_MGMT_CPL_START  + $bits(dma_mgmt_cpl_if_in_t  );
localparam   XDMA_FAB_IN_VDM_START            =  XDMA_FAB_IN_DMA_MGMT_REQ_START  + $bits(dma_mgmt_req_if_in_t  );



`endif
