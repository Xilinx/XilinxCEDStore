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
//       Revision:       $Id: //IP3/DEV/hw/pcie_gen4/branches/pciea_ITR10_FREEZE1/rtl/dma/rtl/mdma/mdma_defines.svh#1 $
//                       $Author: case $
//                       $DateTime: 2018/07/19 16:32:14 $
//                       $Change: 2284012 $
//       Description:
//
//////////////////////////////////////////////////////////////////////////////
`ifndef MDMA_DEFINES_SVH
    `define MDMA_DEFINES_SVH
    `timescale 1 ps / 1 ps
    typedef logic [511:0]                           mdma_int_tdata_t;
    typedef logic [10:0]                            mdma_pid_t;
    typedef logic [11:0]                            mdma_qid_max_t;
    typedef logic [10:0]                            mdma_qid_t;
    typedef logic [15:0]                            mdma_qidx_t;
    typedef logic [20:0]                            mdma_byte_qidx_t;
    typedef logic [11:0]                            mdma_int_pidx_t;
    typedef logic [15:0]                            mdma_qsize_t;
    typedef logic [9:0]                             mdma_qsize_64desc_t;
    typedef logic [15:0]                            mdma_dma_buf_len_t;
    localparam  MDMA_C2H_ST_MAX_LEN = (1<<$bits(mdma_dma_buf_len_t))-1;
    typedef logic [63:6]                            mdma_dma_buf_addr64_t;
    typedef logic [63:12]                           mdma_dma_buf_addr4k_t;
    typedef logic [63:0]                            mdma_dma_buf_addr_t;
    typedef logic [127:0]                           mdma_dma_wrb_data_t;
    typedef logic [255:0]                           mdma_max_dsc_t;
    typedef mdma_max_dsc_t                          mdma_dma_wrb_dual_data_t;
    typedef logic [235:0]                           mdma_dma_wrb_user_data_standard_t;
    typedef logic [252:0]                           mdma_dma_wrb_user_data_defined_t;
    typedef logic [17:0]                            mdma_stat_t;
    typedef logic [7:0]                             mdma_fnid_t;
    typedef logic [2:0]                             mdma_int_page_size_t;
    typedef logic [31:0]                            mdma_int_vec_out_t;
    typedef logic [7:0]                             mdma_int_vec_id_coal_t; // Absolute vector id
    typedef logic [4:0]                             mdma_int_vec_id_t; 
    typedef logic [15:0]                            mdma_int_cnt_th_t; //Absolute interrupt count threshold
    typedef logic [15:0]                            mdma_int_timer_cnt_t; //Absolute interrupt count threshold
    typedef logic [$clog2($bits(mdma_int_tdata_t)/64) -1:0]  mdma_wr_coal_offset_t;
    typedef logic [$clog2($bits(mdma_int_tdata_t)/64):0]     mdma_wr_coal_len64_t;

   // H2C Writeback Data (H2C read engine -> H2C writeback engine)
   typedef struct packed {
      logic                   wbi;
      logic                   wbi_chk;
      logic                   is_wb;
      logic [1:0]             err;      // bit[1] : dsc error, bit[0] dma erro
      mdma_fnid_t             fnc;
      logic [15:0]            cidx;
      logic                   sel;
      mdma_qid_t              qid;     // Q ID
   } mdma_h2c_wb_data_t;

   // H2C Writeback Check Request (H2C writeback engine -> Descriptor engine)
   typedef struct packed {
      logic                   sel;     // 0: H2C; 1: C2H
      logic [1:0]             err;     // Error status      // bit[1] : dma error, bit[0] dsc erro
      logic                   wbi;     //
      logic                   wbi_chk; //
      mdma_qidx_t             cidx;    // Context Index
      mdma_qid_t              qid;     // Queue ID
   } mdma_h2c_wbc_req_t;

   // H2C Writeback Completion Data (Descriptor engine -> H2C writeback engine)
   typedef struct packed {
      logic                   wbi;   // Send writeback
      logic                   irq;   // Send interrupt after writeback posted
      logic [63:0]            wbadr; // Writeback Address
   } mdma_h2c_wbc_info_t;

   typedef struct packed {
      logic                   err;   // Dma error
      logic [15:0]            pidx;  // Current PIDX
   } mdma_h2c_wbc_wpl_t;

   typedef struct packed {
      mdma_h2c_wbc_info_t  info;
      mdma_h2c_wbc_wpl_t   wpl;
   } mdma_h2c_wbc_dat_t;


   typedef struct packed {
      logic [2:0]             port_id;
      logic                   st_mm;   // 
      logic                   err;     // Error status      // bit[1] : dma error, bit[0] dsc erro
      mdma_qidx_t             cidx;    // Context Index
      mdma_qid_t              qid;     // Queue ID
   } mdma_wb_sts_t;

    typedef struct packed {
        logic               marker;        // Make sure the pipeline is completely flushed
        logic [2:0]         port_id;
        logic               imm_data;      // Immediate data
        logic               disable_wrb;
        logic               user_trig;     // User trigger 
        mdma_qid_t          qid;
        mdma_dma_buf_len_t  len;
    } mdma_c2h_axis_ctrl_t;

    typedef struct packed {
        mdma_int_tdata_t    tdata;
        logic [$bits(mdma_int_tdata_t)/8 - 1 :0]   par; 
    } mdma_c2h_axis_data_t;

    typedef struct packed {
        mdma_int_tdata_t    tdata;
        logic [$bits(mdma_int_tdata_t)/8 - 1 :0]   par;
    } mdma_h2c_axis_data_t;

    typedef enum logic [1:0]    {
        WRB_DSC_8B=0, WRB_DSC_16B=1, WRB_DSC_32B=2, WRB_DSC_UNKOWN=3
    } mdma_c2h_wrb_type_e;

    typedef struct packed {
        mdma_dma_wrb_data_t         wrb_data;
        mdma_c2h_wrb_type_e         wrb_type;
        logic [$bits(mdma_dma_wrb_data_t)/32-1:0] dpar; //Data parity
    } mdma_c2h_wrb_data_t;

    typedef struct packed {
        mdma_dma_buf_addr_t     addr;
        mdma_dma_buf_len_t      len;
        mdma_qid_t              qid;
        logic                   drop;
        logic                   last;
        logic                   error;
        mdma_fnid_t             func;
    } mdma_c2h_desc_rsp_t;

    typedef struct packed {
        logic                   marker;
        logic [2:0]             port_id;
        mdma_dma_buf_len_t      len;
        mdma_qid_t              qid;
    } mdma_c2h_desc_req_t;

    typedef struct packed {
        logic                   valid;           // This is asserted per descriptor, or per packet for the case of imm_data or marker
        logic                   last;            
        logic                   drop;
        logic                   imm_or_marker;   // This packet is immediate data or marker
        logic                   cmp;             // This packet will generate a completion
        mdma_qid_t              qid;
    } mdma_desc_rsp_drop_t; 

    typedef struct packed {
        logic                   cmp;      // completion  
    } mdma_c2h_pcie_cmp_t;  

    typedef struct packed {
        logic                   valid;
        logic [4:0]             source;
// Here are the error sources:
//    typedef struct packed {
//        logic [31-9-MDMA_MAX_IND_AXS:0]  rsvd;                 // 10-31
//        logic [MDMA_MAX_IND_AXS-1:0]     ind_ctxt_cmd_err;     // 9
//        logic                            err_c2h_st;           // 8
//        logic                            err_c2h_mm_1;         // 7
//        logic                            err_c2h_mm_0;         // 6
//        logic                            err_h2c_mm_1;         // 5
//        logic                            err_h2c_mm_0;         // 4
//        logic                            err_trq;              // 3
//        logic                            err_dsc;              // 2
//        logic                            err_ram_dbe;          // 1
//        logic                            err_ram_sbe;          // 0
//    } mdma_glbl_err_t;
    } dma_err_out_t;   

    typedef struct packed {
        logic [5:0]         rsvd;
        logic               marker;        // Make sure the pipeline is completely flushed
        logic [2:0]         port_id;       // Port ID
        logic               imm_data;      // immediate data
        logic               disable_wrb;   // direct data placement by user application
        logic               user_trig;     // user trigger
        mdma_qid_t          qid;
        mdma_dma_buf_len_t  len;
    } mdma_qid_fifo_t;

    typedef struct packed {
        logic [5:0]                                    rsvd;
        mdma_c2h_wrb_type_e                            wrb_type;
        mdma_dma_wrb_dual_data_t                       wrb_data;
        logic [$bits(mdma_dma_wrb_dual_data_t)/32-1:0] dpar;
    } mdma_tuser_fifo_data_t;

    typedef struct packed {
        logic                   qid_mismatch; // This will check if the qid in the AXIS Ctrl input and the AXIS User Input matches. This assumes the qid in tuser_data[10:0] 
        logic                   pid_mismatch; // This will check the processing ID in the AXIS User Input matches. This assumes the pid in tuser_data[21:11]
        logic                   len_mismatch; // This checks if the total packet size matches Len
        logic                   mty_mismatch; // This checks if the mty input is zero in the non-last packet
    } mdma_s_axis_c2h_err_t;   

    typedef struct packed {
        logic [31-16:0]         rsvd;
        logic                   wrb_prty_err;       
        logic                   wrb_cidx_err; //Indicates that a PtrUpd was received with a bad cidx
        logic                   wrb_qfull_err; //Indicates that a WRB was received on a FullQ
        logic                   wrb_inv_q_err; //Indicates that a SW pointer UPD was received on an invalid Q
        logic                   port_id_byp_in_mismatch;
        logic                   port_id_ctxt_mismatch;
        logic                   err_desc_cnt;
        logic                   rsvd1;
        logic                   msi_int_fail;
        logic                   eng_wpl_data_par_err;
        logic                   rsvd2;
        logic                   desc_rsp_error;  // The desc_rsp from the Prefetch module has error bit set
        logic                   qid_mismatch;    // This will check if the qid in the AXIS Ctrl input and the AXIS User Input matches. This assumes the qid in tuser_data[10:0] 
        logic                   rsvd3;           
        logic                   len_mismatch;    // This checks if the total packet size matches Len
        logic                   mty_mismatch;    // This checks if the mty input is zero in the non-last packet
    } mdma_c2h_err_t;  

    typedef struct packed {
        logic [31-5:0]          rsvd;
        logic                   sbe;
        logic                   dbe;
        logic                   zero_len_dsc_err;
        logic                   wbi_mod_err;
        logic                   no_dma_dsc_err;
    } mdma_h2c_err_t; 

    typedef struct packed {
        logic [31-20:0]         Rsvd;
        logic                   wrb_prty_err;       
        logic                   wpl_data_par_err;       
        logic                   payload_fifo_ram_rdbe;  
        logic                   qid_fifo_ram_rdbe;      
        logic                   tuser_fifo_ram_rdbe;    
        logic                   wrb_coal_data_ram_rdbe; 
        logic                   int_qid2vec_ram_rdbe;   
        logic                   int_ctxt_ram_rdbe;      
        logic                   desc_req_fifo_ram_rdbe; 
        logic                   pfch_ctxt_ram_rdbe;     
        logic                   wrb_ctxt_ram_rdbe;      
        logic                   pfch_ll_ram_rdbe;      
        logic [3:0]             timer_fifo_ram_rdbe;
        logic                   qid_mismatch; // This will check if the qid in the AXIS Ctrl input and the AXIS User Input matches. This assumes the qid in tuser_data[10:0]
        logic                   Rsvd1;
        logic                   len_mismatch; // This checks if the total packet size matches Len
        logic                   mty_mismatch; // This checks if the mty input is zero in the non-last packet
    } mdma_c2h_fatal_err_t;   

    typedef struct packed {
        logic [32-16-4-1:0]     rsvd;
        logic [3:0]             err_type;
        logic [4:0]             rsvd1;
        mdma_qid_t              qid;
    } mdma_c2h_first_err_t;    

    typedef enum logic [1:0] {
        INV=0, PFCH_ONLY=1, FETCH=2, PFCH=3
    } mdma_cache_state_t;

    typedef enum logic [2:0] {
        DBG_PFCH_KEY_CAM=0, DBG_PFCH_TAG_ST=1, DBG_PFCH_TAG_USED_CNT=2, DBG_PFCH_TAG_DESC_CNT=3, DBG_PFCH_ERR_CTXT=4 
    } mdma_c2h_dbg_pfch_target_e;

    typedef struct packed {
        logic [31-$bits(mdma_c2h_dbg_pfch_target_e)-$bits(mdma_qid_t)-1:0]  rsv;
        logic                                                               err_ctxt;
        mdma_c2h_dbg_pfch_target_e                                          target;    
        mdma_qid_t                                                          qid;
    } mdma_c2h_dbg_pfch_t;

    typedef struct packed {
        mdma_qid_t                qid;
        mdma_dma_buf_addr_t       addr;
        mdma_fnid_t               fnc;
        mdma_wr_coal_offset_t     offset;
        logic                     flsh;
        logic                     is_stat_desc;
        mdma_wr_coal_len64_t      len64;
    } mdma_wr_coal_buf_ctrl_t;

    typedef logic [3:0]             mdma_wrb_timer_th_ix_t;
    typedef logic [3:0]             mdma_wrb_cnt_th_ix_t;

    typedef enum logic [1:0] {
        WRB_INT_ISR, WRB_INT_TRIG
    } mdma_c2h_wrb_int_state_e;


    typedef enum logic [2:0]    {
        WRB_TRIG_DIS=0, WRB_TRIG_EVERY, WRB_TRIG_USER_COUNT, WRB_TRIG_USER, WRB_TRIG_USER_TIMER
    } mdma_c2h_wrb_trig_mode_e;

    typedef enum logic [1:0] {
        WRB_ERR_NONE=0, WRB_ERR_CIDX, WRB_ERR_DSC, WRB_ERR_QFULL
    } mdma_wrb_err_e;

    typedef union packed {
        mdma_wrb_err_e    c2h_err;
        logic [1:0]                 h2c_err;
    } mdma_wrb_stat_err_t;

    typedef struct packed {
        logic [1:0]                 rsv;
        logic                       full_upd;
        logic                       tmr_running;
        logic                       usr_int_pend;
        mdma_wrb_err_e              err;
        logic                       valid;
        mdma_qidx_t                 cidx;
        mdma_qidx_t                 pidx;
        mdma_c2h_wrb_type_e         desc_size;
        // To save space in context make this 64B aligned.
        mdma_dma_buf_addr64_t       baddr_64;
        logic [3:0]                 qsize_ix;
        logic                       color;
        mdma_c2h_wrb_int_state_e    int_st;
        mdma_wrb_timer_th_ix_t      timer_ix;
        mdma_wrb_cnt_th_ix_t        cnt_ix;
        mdma_fnid_t                 fnid;
        mdma_c2h_wrb_trig_mode_e    trig_mode;
        logic                       en_int;
        logic                       en_stat_desc;
    } mdma_wrb_ctxt_t;

    typedef struct packed {
        mdma_dma_wrb_user_data_standard_t       data;
        mdma_dma_buf_len_t                      len;
        logic                                   desc_used;    // 1'b1: packet uses the descriptor; 1'b0: packet doesn't use the descripor, ex imm_data, marker
        logic                                   desc_err;
        logic                                   color; 
        logic                                   data_format;  // 1'b1: User define format; 1'b0: User Standard format
    } mdma_wrb_desc_t;                // User standard format

    typedef struct packed {
        mdma_dma_wrb_user_data_defined_t        data;
        logic                                   desc_err;
        logic                                   color; 
        logic                                   data_format;  // 1'b1: User define format; 1'b0: User Standard format
    } mdma_wrb_desc_user_defined_t;   // User defined format

    typedef union packed {
        mdma_wrb_desc_t                         mdma_wrb_desc;
        mdma_wrb_desc_user_defined_t            mdma_wrb_desc_user_defined;
    } mdma_wrb_desc_all_t;

    typedef struct packed {
        mdma_dma_wrb_user_data_standard_t       data;
        logic [7:0]                             pid; 
        mdma_qid_t                              qid;
        logic                                   data_format;
    } mdma_c2h_wrb_data_user_standard_t;

    typedef struct packed {
        mdma_dma_wrb_user_data_defined_t        data;
        logic [1:0]                             rsvd;
        logic                                   data_format;
    } mdma_c2h_wrb_data_user_defined_t;

    typedef union packed {
        mdma_c2h_wrb_data_user_standard_t       mdma_c2h_wrb_data_user_standard;
        mdma_c2h_wrb_data_user_defined_t        mdma_c2h_wrb_data_user_defined;
    } mdma_c2h_wrb_data_all_t;

    //Dont let this grow more than 8B
    typedef struct packed {
        //logic                       ctxt_vld;
        mdma_wrb_stat_err_t         err;
        mdma_c2h_wrb_int_state_e    int_st;
        logic                       color;
        mdma_qidx_t                 cidx;
        mdma_qidx_t                 pidx;
    } mdma_wrb_stat_desc_t;

    // 8B only
    typedef struct packed {
        logic [15:0]                rsvd1;
        mdma_qidx_t                 pidx;
        mdma_qidx_t                 cidx;
        logic [15:2]                rsvd0;
        logic [1:0]                 err;
    } mdma_h2c_wb_desc_t;

    typedef struct packed {
        mdma_qid_t                  qid;
        logic                       wr;
        logic [31:0]                data;
    } mdma_dyn_ptr_upd_t;

    typedef struct packed {
        logic [$bits(mdma_int_tdata_t)/8 - 1 :0]  par;
        mdma_int_tdata_t                          dat;
    } mdma_wpl_t;

    // FIFO parameters
    localparam MDMA_FIFO_BRAM_READ_LAT      = 2;
    localparam MDMA_FIFO_BRAM_BUF_WR        = 1;
    localparam MDMA_FIFO_BRAM_BUF_RD        = 1;

    // Prefetch parameters
    localparam MDMA_C2H_MAX_STBUF      = 7;        // A packet can have maximum of 7 descriptors
    localparam EVT_INIT_CRDT           = 1;
    localparam CTXT_INIT_CRDT          = 1;
    localparam TM_STS_INIT_CRDT        = 2;
    localparam DESC_REQ_INIT_CRDT      = 8;
    localparam DESC_REQ_ENTRY          = DESC_REQ_INIT_CRDT*MDMA_C2H_MAX_STBUF;   
    localparam DESC_PROC_DEPTH         = EVT_INIT_CRDT+CTXT_INIT_CRDT+TM_STS_INIT_CRDT+DESC_REQ_ENTRY;
    localparam DESC_CNT_FIFO_DEPTH     = EVT_INIT_CRDT+CTXT_INIT_CRDT+TM_STS_INIT_CRDT+DESC_REQ_INIT_CRDT;
    localparam DESC_FIFO_CRDT_BITS     = $clog2(DESC_PROC_DEPTH+1);
    localparam DESC_CNT_FIFO_CRDT_BITS = $clog2(DESC_CNT_FIFO_DEPTH+1);

    // DMA Write Engine parameters
    localparam WR_ENG_FIFO_DEPTH                 = 512;
    localparam WR_ENG_FIFO_ADDR_BITS             = $clog2(WR_ENG_FIFO_DEPTH); 
    localparam WR_ENG_PAYLOAD_FIFO_BITS          = $bits(mdma_wpl_t);
    localparam WR_ENG_QID_FIFO_BITS              = $bits(mdma_qid_fifo_t);
    localparam WR_ENG_TUSER_FIFO_BITS            = $bits(mdma_tuser_fifo_data_t);
    localparam WR_ENG_PAYLOAD_FIFO_BYTE_CNT_BITS = $clog2(WR_ENG_FIFO_DEPTH*WR_ENG_PAYLOAD_FIFO_BITS);

    // Wrb Coal parameters
    localparam WRB_COAL_BUF_BITS        = 512;
    localparam WRB_COAL_MAX_BUF         = 32;
    localparam WRB_COAL_DATA_RAM_NUM    = 8;
    localparam WRB_COAL_RDT_FFOUT       = 1;
    localparam WRB_COAL_BUF_IX_BITS     = $clog2(WRB_COAL_MAX_BUF);
    localparam WRB_COAL_EN_FLUSH        = 1;
    localparam WRB_COAL_BUF_CTRL_BITS   = $bits(mdma_wr_coal_buf_ctrl_t);

    // Interrupt Qid2vec RAM
    localparam INT_QID2VEC_RAM_DATA_BITS            = 18;
    localparam INT_QID2VEC_RAM_DEPTH                = 2048;
    localparam INT_QID2VEC_RAM_ADDR_BITS            = $clog2(INT_QID2VEC_RAM_DEPTH);
    localparam INT_QID2VEC_RAM_RDT_FFOUT            = 1;
    localparam INT_QID2VEC_RAM_DATA_C2H_VEC_MAX_BIT = 7;
    localparam INT_QID2VEC_RAM_DATA_C2H_VEC_MIN_BIT = 0;
    localparam INT_QID2VEC_RAM_DATA_H2C_VEC_MAX_BIT = 16;
    localparam INT_QID2VEC_RAM_DATA_H2C_VEC_MIN_BIT = 9;
    //ALL params for WRB_COAL_CFG register
    localparam MAX_BUF_SZ_BITS             = 6;
    localparam TICK_VAL_BITS               = 12;
    localparam TICK_CNT_BITS               = 12;
    localparam MAX_BUF_SZ_DEF              = 32;
    localparam TICK_VAL_DEF                = 20;
    localparam TICK_CNT_DEF                = 4;
    localparam DONE_GLB_FLSH_LOC           = 0;
    localparam SET_GLB_FLSH_LOC            = 1;
    localparam TICK_CNT_L                  = SET_GLB_FLSH_LOC+1;
    localparam TICK_CNT_H                  = SET_GLB_FLSH_LOC+TICK_CNT_BITS;
    localparam TICK_VAL_L                  = TICK_CNT_H+1;
    localparam TICK_VAL_H                  = TICK_CNT_H+TICK_VAL_BITS;
    localparam MAX_BUF_SZ_L                = TICK_VAL_H+1;
    localparam MAX_BUF_SZ_H                = TICK_VAL_H+MAX_BUF_SZ_BITS;


    typedef struct packed {
        logic                   sel;      // 0: H2C; 1: C2H
        logic                   err_int;  // Error generated interrupt 
        mdma_fnid_t             fnc;
        mdma_qidx_t             qid;
        mdma_wrb_stat_desc_t    stat_desc; 
    } mdma_c2h_wrb2int_t;

    typedef struct packed {
        mdma_qid_t              qid;
        mdma_wrb_timer_th_ix_t  timer_ix;
    } mdma_c2h_wrb2timer_t;

    typedef struct packed {
        mdma_qid_max_t          qid_max;
        mdma_qid_t              qid_base;
    } mdma_func_map_t;

    typedef enum logic [0:0]    {
        WAIT_TRIGGER=0, ISR_RUNNING=1
    } mdma_int_state_e;

    // Interrupt Context RAM data
    typedef struct packed {
        mdma_int_pidx_t             pidx;
        mdma_int_page_size_t        page_size;
        mdma_dma_buf_addr4k_t       baddr_4k;
        logic                       color;
        mdma_int_state_e            int_st;
        logic                       dbg_small_page_size;  // For debug purpose, put some small page size
        mdma_int_vec_id_t           vec;
        logic                       vld;
    } mdma_int_ctxt_t;

    // Interrupt wpl pkt to the WPL FIFO
    typedef struct packed {
        logic                                                                             coal_color;
        mdma_qid_t                                                                        qid;
        logic                                                                             int_type;   // 0: H2C; 1: C2H
        logic                                                                             err_int;    // Error generated interrupt
        mdma_wrb_stat_desc_t                                                              stat_desc;
    } mdma_int_wpl_pkt_t;

    // Interrupt wpl pkt to PCIE
    typedef struct packed {
        logic [$bits(mdma_int_tdata_t)-64-1:0]                                            rsvd1;
        logic                                                                             coal_color;
        mdma_qid_t                                                                        qid;
        logic                                                                             int_type;   // 0: H2C; 1: C2H
        logic                                                                             err_int;    // Error generated interrupt
        logic [64-$bits(mdma_wrb_stat_desc_t)-3-$bits(mdma_qid_t)-1:0]                    rsvd0;
        mdma_wrb_stat_desc_t                                                              stat_desc;
    } mdma_int_wpl_t;

    // Interrupt Context RAM
    localparam INT_CTXT_RAM_DATA_BITS    = $bits(mdma_int_ctxt_t);
    localparam INT_CTXT_RAM_DEPTH        = 256;
    localparam INT_CTXT_RAM_ADDR_BITS    = $clog2(INT_CTXT_RAM_DEPTH);
    localparam INT_CTXT_RAM_RDT_FFOUT    = 1;

    // Fetch Engine and C2H prefetch interface
    typedef logic [$bits(mdma_max_dsc_t) - 1 - $bits(mdma_qid_t) - $bits(mdma_qidx_t) -1:0] mdma_c2h_dsc_usr_t;
    typedef mdma_c2h_wrb_type_e             mdma_dsc_size_e;

    typedef enum logic [1:0] {
        MDMA_CRD_ADD =2'h0, MDMA_CRD_SUB = 2'h1, MDMA_IDX_SUB=2'h2, MDMA_CRD_RSV= 2'h3 
    } mdma_dsc_eng_crdt_op_e;
    typedef struct packed {
        mdma_dsc_eng_crdt_op_e op;
        logic               sel; //0 H2C, 1 C2H
        mdma_qid_t          qid;
        mdma_qidx_t         crdt;
    } mdma_dsc_eng_crdt_t;

    typedef struct packed {
        mdma_c2h_dsc_usr_t      usr;
        mdma_dma_buf_len_t      len; //Only for XDMA mode
        mdma_dma_buf_addr_t     src_addr; //AXI address (XDMA Mode only
        mdma_dma_buf_addr_t     dst_addr; //PCIe address
    } mdma_c2h_dsc_t;

    typedef struct packed {
        mdma_c2h_dsc_t              dsc;
        mdma_qid_t                  qid;
        mdma_dsc_size_e             size;
    } mdma_c2h_dsc_if_t;

    typedef logic [7:0]             mdma_c2h_dsc_cache_ptr_t;
    typedef logic [3:0]             mdma_c2h_buf_size_ix_t;

    typedef struct packed {
        logic                       valid;
        mdma_qidx_t                 sw_crdt;
        logic                       pfch;
        logic                       pfch_en;
        logic                       err;
        logic [9:0]                 rsv;
        mdma_fnid_t                 fnid;        
        logic [2:0]                 port_id;
        mdma_c2h_buf_size_ix_t      buf_size_ix;
        logic                       bypass;
    } mdma_wrb_c2h_pftch_ctxt_t;

    typedef struct packed {
        logic           ctxt_valid;
        mdma_qid_t      qid;
        //Add cache flush here
    } mdma_c2h_pfch_ctxt2cache_t;

    typedef logic[2:0] mdma_c2h_max_desc_t;//Maximum descriptors allowed per packet is 7
    typedef logic[8:0] mdma_c2h_alloc_max_desc_t;//Maximum descriptors allowed per packet is 7

    localparam MDMA_PFCH_CACHE_DEPTH=64;
    typedef logic [$clog2(MDMA_PFCH_CACHE_DEPTH)-1:0] mdma_c2h_cache_tag_t;
    typedef enum logic [1:0] {
        MDMA_PFCH_TYPE_DESC, MDMA_PFCH_TYPE_CFLUSH, MDMA_PFCH_TYPE_EFLUSH, MDMA_PFCH_TYPE_DSC_INV
    } mdma_pfch_cmd_type_e;

    typedef struct packed {
        mdma_qid_t                  qid;
        mdma_c2h_cache_tag_t        tag;
        mdma_c2h_alloc_max_desc_t   cnt;
        logic                       pfch;
        mdma_pfch_cmd_type_e        typ;        
    } mdma_c2h_cache_alloc_t;

    typedef struct packed {
        logic [5:0]                 rsvd;
        logic [2:0]                 port_id;
        mdma_qid_t                  qid;
        mdma_dma_buf_len_t          len;
        logic                       last;
        logic                       byp;
        logic                       drop;
        mdma_c2h_cache_tag_t        tag;
    } mdma_c2h_crdt2cache_t;

    typedef enum logic [0:0]    {
        WRB_SM_IDLE, WRB_SM_SEND_PKT 
    } wrb_sm_type_e;

    typedef enum logic [1:0]    {
        TUSER_INIT_IDLE, TUSER_INIT_ON, TUSER_INIT_DONE 
    } tuser_init_sm_type_e;

    typedef enum logic [1:0]    {
        ERR_CTXT_INIT_IDLE, ERR_CTXT_INIT_ON, ERR_CTXT_INIT_DONE 
    } err_ctxt_init_sm_type_e;

    typedef enum logic [3:0]    {
        ENG_IDLE, WAIT_DESC_RSP, SEND_WR_REQ, WAIT_WRB_ENTRY, DROP_WAIT, DROP, DROP_WAIT_WRQ, ERROR_WAIT, ERROR, ERROR_WAIT_WRQ, WAIT_MARKER_RSP
    } dma_eng_sm_type_e;   

    typedef enum logic [4:0]    {
        INT_IDLE=0, WRB_VEC_RAM_RD=1, WRB_VEC_RAM_RD_BACK=2, WRB_SEND_MSIX=3, H2C_VEC_RAM_RD=4, H2C_VEC_RAM_RD_BACK=5, H2C_SEND_MSIX=6, REG_VEC_RAM_RD=7, REG_VEC_RAM_RD_BACK=8, REG_VEC_RAM_WR=9, REG_CTXT_VEC_RAM_RD=10, REG_CTXT_VEC_RAM_RD_BACK=11, REG_CTXT_VEC_RAM_WR=12, DYN_VEC_RAM_RD=13, DYN_VEC_RAM_RD_BACK=14, DYN_PROCESS=15, REG_CTXT_RAM_RD=16, REG_CTXT_RAM_RD_BACK=17, REG_CTXT_RAM_WR=18 
    } int_sm_type_e;

    typedef enum logic [3:0]    {
        INT_COAL_IDLE=0, RAM_RD=1, RAM_RDATA_BACK=2, RAM_WR=3, WRQ_OUT=4, WPL_FIFO=5, WAIT_WCP=6, SEND_MSIX=7, REG_RAM_RD=8, REG_RAM_RDATA_BACK=9, DYN_RAM_RD=10, DYN_RAM_RDATA_BACK=11, DYN_RAM_WR=12, DYN_WAIT_WCP=13, DYN_SEND_MSIX=14   
    } int_coal_sm_type_e;

    typedef enum logic [0:0]    {
       MARKER_SM_IDLE=0, MARKER_SM_WAIT=1
    } marker_sm_type_e;   

    typedef struct packed {
        logic       reg_ctxt_wr;
        logic       reg_ctxt_rd;
        logic       dyn;
        logic       reg_ctxt_qid2vec_wr;
        logic       reg_ctxt_qid2vec_rd;
        logic       reg_qid2vec_wr;
        logic       reg_qid2vec_rd;
        logic       h2c;
        logic       wrb;
    } mdma_c2h_int_req_t;

    typedef struct packed {
        mdma_fnid_t    fnc;      
        logic [15:0]   sw_cidx;
        logic          sel;
        mdma_qid_t     qid;
    } mdma_dyn_req_t;

    localparam TIMER_BITS   = 9;

    typedef struct packed {
        logic                      par;
        mdma_qid_t                 qid;
        logic [TIMER_BITS-1:0]     timer_inj;
    } mdma_timer_fifo_dat_t;

    localparam  TIMER_FIFO_RAM_NUM        = 4;
    localparam  TIMER_FIFO_TOTAL_DEPTH    = 2048;
    localparam  TIMER_FIFO_DEPTH          = TIMER_FIFO_TOTAL_DEPTH/TIMER_FIFO_RAM_NUM;
    localparam  TIMER_FIFO_ADDR_BITS      = $clog2(TIMER_FIFO_DEPTH);
    localparam  TIMER_FIFO_BITS           = $bits(mdma_timer_fifo_dat_t);
    localparam  TIMER_TOTAL_FIFO_CNT_BITS = $clog2(TIMER_FIFO_TOTAL_DEPTH+1);
    localparam  TIMER_FIFO_CNT_BITS       = $clog2(TIMER_FIFO_DEPTH+1);

    localparam  FIFO_CNT_BITS     = 10;
    localparam  WRB_FIFO_CNT_BITS = 3;
    localparam  WRQ_FIFO_CNT_BITS = 3;

    // Debug status registers
    typedef struct packed {
        logic                             wrb_fifo_write_rdy;
        logic [WRB_FIFO_CNT_BITS-1:0]     wrb_fifo_out_cnt;    
        logic [FIFO_CNT_BITS-1:0]         qid_fifo_out_cnt;    
        logic [FIFO_CNT_BITS-1:0]         payload_fifo_out_cnt;
        logic [WRQ_FIFO_CNT_BITS-1:0]     wrq_fifo_out_cnt;    
        wrb_sm_type_e                     wrb_sm_cs;           
        dma_eng_sm_type_e                 main_sm_cs;          
    } mdma_stat_c2h_debug_dma_eng_0_t; 

    typedef struct packed {
        logic             tuser_comb_in_rdy;
        logic             desc_rsp_last;
        logic [9:0]       payload_fifo_in_cnt;    
        logic [9:0]       payload_fifo_output_cnt;
        logic [9:0]       qid_fifo_in_cnt;        
    } mdma_stat_c2h_debug_dma_eng_1_t; 

    typedef struct packed {
        logic [31-30:0]   rsv;                    
        logic [9:0]       wrb_fifo_in_cnt;    
        logic [9:0]       wrb_fifo_output_cnt;
        logic [9:0]       qid_fifo_output_cnt;
    } mdma_stat_c2h_debug_dma_eng_2_t;

    typedef struct packed {
        logic [31-20:0]   rsv;                    
        logic [9:0]       wrq_fifo_in_cnt;    
        logic [9:0]       wrq_fifo_output_cnt;
    } mdma_stat_c2h_debug_dma_eng_3_t;

    typedef struct packed {
        logic                             tuser_fifo_out_vld;
        logic                             wrb_fifo_in_rdy;
        logic [9:0]                       tuser_fifo_in_cnt;    
        logic [9:0]                       tuser_fifo_output_cnt;    
        logic [FIFO_CNT_BITS-1:0]         tuser_fifo_out_cnt;
    } mdma_stat_c2h_debug_dma_eng_4_t;

    typedef struct packed {
        logic [31-2-20-3:0]               rsv;
        logic                             tuser_comb_out_vld;
        logic                             tuser_fifo_in_rdy;
        logic [9:0]                       tuser_comb_in_cnt;    
        logic [9:0]                       tuser_comb_output_cnt;    
        logic [2:0]                       tuser_comb_cnt;
    } mdma_stat_c2h_debug_dma_eng_5_t; 

    typedef struct packed {
        int_coal_sm_type_e     int_coal_sm_cs;
        int_sm_type_e          sm_cs;
        mdma_int_vec_id_t      vec;
    } mdma_stat_c2h_int_msix_t; 

    typedef struct packed {
        int_coal_sm_type_e     int_coal_sm_cs;
        int_sm_type_e          sm_cs;
    } mdma_stat_c2h_debug_int_t; 
 
    // Debug signals
    typedef struct packed {
        logic [7:0]                 rsvd;
        logic                       s_axis_c2h_tvalid;
        logic                       s_axis_c2h_tready;
        logic                       s_axis_c2h_tlast; 
        logic [5:0]                 s_axis_c2h_mty;   
        mdma_c2h_axis_ctrl_t        s_axis_c2h_ctrl;  
        logic [7:0]                 s_axis_c2h_data;  
        dma_eng_sm_type_e           main_sm_cs;
        wrb_sm_type_e               wrb_sm_cs;
        logic                       qid_fifo_out_dat_qid;
        logic                       qid_fifo_out_dat_len;
        logic                       qid_fifo_out_dat_marker;
        logic                       qid_fifo_out_vld;
        logic [9:0]                 qid_fifo_out_cnt;
        logic [2:0]                 qid_fifo_out_sm_fifo_cnt;
        logic                       tuser_fifo_out_vld;
        logic [9:0]                 tuser_fifo_out_cnt;
        logic [2:0]                 tuser_fifo_out_sm_fifo_cnt;
        logic                       payload_fifo_out_vld;
        logic [9:0]                 payload_fifo_out_cnt;
        logic [2:0]                 payload_fifo_out_sm_fifo_cnt;
        logic [18:0]                payload_fifo_credit_cnt;
        logic                       payload_fifo_crdt_req_final;
        logic [12:0]                payload_fifo_crdt_cnt_final;
        logic                       payload_fifo_crdt_gnt;
        logic                       payload_fifo_crdt_req_drop;
        logic [7:0]                 wrq_pkt_id;
        logic [7:0]                 wrb_pkt_id;
        logic [1:0]                 wrq_pkt_id_adv;
        logic                       desc_rsp_eng_vld;
        logic                       desc_rsp_eng_rdy;
        logic [7:0]                 desc_rsp_eng_addr;
        logic [15:0]                desc_rsp_eng_len;
        logic [10:0]                desc_rsp_eng_qid;
        logic                       desc_rsp_eng_drop;
        logic                       desc_rsp_eng_last;
        logic                       desc_rsp_eng_error;
        logic                       wrq_fifo_in_vld;
        logic                       wrq_fifo_in_rdy;
        logic [2:0]                 wrq_fifo_out_cnt;
        logic                       wrb_fifo_in_vld;
        logic                       wrb_fifo_in_rdy;
        logic [2:0]                 wrb_fifo_out_cnt;
        logic                       wcp_fifo_in_vld;
        logic                       wcp_fifo_in_rdy;
        logic [2:0]                 wcp_fifo_out_cnt;
        logic                       wrq_packet_out_eor;
        logic [11:0]                wrq_packet_out_byte_len;
        logic [7:0]                 wrq_packet_out_adr;
        logic                       wrq_vld_out;
        logic                       payload_fifo_crdt_req;
        logic                       wpl_vld;
        logic [7:0]                 wpl_data;
        logic                       wpl_ren;
        logic                       wpl_inc;
        logic                       wrq_accepted;
        logic                       qid_fifo_out_dat_imm_data;
        logic                       qid_fifo_out_dat_disable_wrb;
        logic                       wrq_fifo_in_vld_drop_error;
        logic                       wrq_fifo_in_disable_wrb;
    } mdma_c2h_debug_dma_wr_eng_t;

    typedef struct packed {
        logic [255-8-20-2-11-8-8-$bits(mdma_stat_t)-$bits(mdma_stat_t):0] rsvd;       
        logic                       s_axis_wrb_tready;
        logic                       s_axis_wrb_tlast; 
        logic                       s_axis_wrb_tvalid;
        logic [7:0]                 s_axis_wrb_data;  
        logic                       wrb_vld;     
        logic                       wrb_rdy;     
        logic [7:0]                 wrb_data_hi; 
        logic [19:0]                wrb_data_low;
        logic [1:0]                 wrb_type;    
        logic [10:0]                wrb_qid;     
        logic                       wrb_user_int;
        logic                       wrb_marker; 
        logic                       stat_total_wrq_len_match; 
        mdma_stat_t                 stat_total_wrq_len; 
        mdma_stat_t                 stat_total_wpl_val_out_len; 
    } mdma_c2h_debug_dma_wr_eng_2_t;

    typedef struct packed {
        logic [1 :0]                                            rsv;
        logic [63:0]                                            tcam_mll;
        logic                                                   evt_vld;
        logic [$clog2(MDMA_PFCH_CACHE_DEPTH)-1:0]               evt_tag;
        mdma_qid_t                                              evt_qid;
        logic                                                   evt_rdy;

        logic [$clog2(MDMA_PFCH_CACHE_DEPTH)-1:0]               pfch_qcnt;

        logic                                                   qid_ram_wen;
        mdma_qid_t                                              qid_ram_wdat;
        logic [$clog2(MDMA_PFCH_CACHE_DEPTH)-1:0]               qid_ram_wadr;
        logic                                                   qid_ram_ren;
        mdma_qid_t                                              qid_ram_rdat;
        logic [$clog2(MDMA_PFCH_CACHE_DEPTH)-1:0]               qid_ram_radr;

        logic                       fl_rtn_vec_vld;    
        mdma_c2h_cache_tag_t        fl_rtn_vec_ix;
                        
        logic                       fl_free_vec_vld;
        logic                       fl_free_vec_rdy;
        mdma_c2h_cache_tag_t        fl_free_vec_ix;

        logic                       ll_rra_enq_gnt;
        logic                       ll_rra_deq_gnt;
        mdma_c2h_cache_tag_t        ll_hptr_enq;
        mdma_c2h_cache_tag_t        ll_tptr_deq;

        logic [1:0]                 ll_hst_enq;
        logic [1:0]                 ll_hst_deq;

        logic                       ll_in_vld;
        mdma_c2h_cache_tag_t        ll_in_tag;
        logic                       ll_in_rdy;
        logic  [31:0]               ll_in_data;

        logic                       ll_flush_vld;
        logic                       ll_flush_done;
        logic                       ll_flush_idle;
        mdma_c2h_cache_tag_t        ll_flush_tag;

        logic [31:0]                ll_out_data;
        logic                       ll_out_vld;
        mdma_c2h_cache_tag_t        ll_out_data_tag;
        logic                       ll_out_deq;
        logic                       ll_out_deq_rdy;
        mdma_c2h_cache_tag_t        ll_out_tag;
    } mdma_c2h_pfch_ll_debug_t;

    typedef struct packed {
        logic [255-5-6-30-4-3-11-16-2-11-16-2-3-26:0] rsvd;               
        logic                                         ctxt_rq_vld;        
        logic                                         ctxt_crdt_avail;    
        logic                                         c2h_tm_sts_vld;     
        logic                                         tm_sts_crdt_avail;  
        logic                                         desc_req_vld;       
        logic                                         desc_req_crdt_avail;
        logic                                         evt_req_vld;        
        logic                                         evt_crdt_avail;     
        logic                                         ctxt_busy;          
        logic                                         dsc_err_vld;        
        logic [4:0]                                   in_rra_gnt;         
        logic [1:0]                                   wr_st;              
        logic [1:0]                                   rd_st;              
        logic [1:0]                                   dsc_rsp_st;         
        logic [5:0]                                   evt_credit;         
        logic [5:0]                                   ctxt_credit;        
        logic [5:0]                                   tm_sts_credit;      
        logic [5:0]                                   desc_req_credit;    
        logic [5:0]                                   desc_fifo_cnt;      
        logic [3:0]                                   desc_cnt_fifo_cnt;  
        logic                                         sm_desc_cnt_vld;    
        logic                                         sm_desc_cnt_rdy;    
        logic [2:0]                                   sm_desc_cnt;        
        logic                                         sm_desc_drop;       
        logic                                         sm_pfch;            
        logic                                         sm_desc_vld;        
        logic                                         sm_desc_rdy;        
        logic [10:0]                                  sm_desc_req_qid;    
        logic [15:0]                                  sm_desc_req_len;    
        logic                                         sm_desc_req_last;   
        logic                                         sm_desc_req_byp;    
        logic [1:0]                                   sm_desc_req_typ;    
        logic                                         desc_req_cache_fifo_vld;
        logic                                         desc_req_cache_fifo_rdy;
        logic [10:0]                                  desc_req_cache_fifo_qid;
        logic [15:0]                                  desc_req_cache_fifo_len;
        logic                                         desc_req_cache_fifo_last;
        logic                                         desc_req_cache_fifo_byp;
        logic [1:0]                                   desc_req_cache_fifo_typ;
        logic                                         desc_cnt_vld;
        logic                                         desc_cnt_rdy;
        logic [2:0]                                   desc_cnt;
        logic                                         desc_drop;
        logic                                         alloc_pfch;
     } mdma_c2h_pfch_crdt_debug_t;

    typedef struct packed {
        logic [127:0]               vec_ary1; 
        logic [127:0]               vec_ary0; 
     } mdma_c2h_pfch_fl_vec_1_debug_t;

    typedef struct packed {
        logic [127:0]               vec_ary3; 
        logic [127:0]               vec_ary2; 
     } mdma_c2h_pfch_fl_vec_2_debug_t;

    typedef struct packed {
        logic [255-6-11-8-11-8-11-6-6-11-6-64-16:0]    rsvd;                    
        logic                       alloc_rsp_vld;           
        logic [5:0]                 alloc_rsp;               
        logic                       alloc_req;               
        logic                       alloc_req_vld;           
        logic                       alloc_req_rdy;           
        logic                       deq_res_rdy;             
        logic                       deq_res_rdy_byp;         
        logic [10:0]                cache_byp_desc_rsp_qid;  
        logic [7:0]                 cache_byp_desc_rsp_func; 
        logic                       cache_byp_desc_rsp_error;
        logic                       cache_byp_desc_rdy;      
        logic                       smpl_byp_desc_vld;       
        logic [10:0]                smpl_byp_desc_rsp_qid;  
        logic [7:0]                 smpl_byp_desc_rsp_func;  
        logic                       smpl_byp_desc_rsp_error; 
        logic                       smpl_byp_desc_rdy;       
        logic                       alloc_srch_vld;          
        logic [10:0]                alloc_srch_key;          
        logic                       alloc_srch_hit;          
        logic [5:0]                 alloc_srch_ix;           
        logic [5:0]                 alloc_srch_free;         
        logic                       alloc_srch_full;         
        logic                       dsc_cmp_srch_vld;        
        logic [10:0]                dsc_cmp_srch_key;        
        logic [5:0]                 dsc_cmp_srch_ix;         
        logic                       dsc_cmp_srch_hit;        
        logic [63:0]                dsc_cmp_srch_mll;        
     } mdma_c2h_pfch_cache_2_debug_t;

    typedef struct packed {
        logic [255-64-73-6-6-73-4-4:0]  rsvd;  
        logic [63:0]                    hst;     
        logic [72:0]                    enq_data;
        logic                           enq_vld; 
        logic [5:0]                     enq_tag; 
        logic                           enq_rdy; 
        logic                           deq_vld; 
        logic                           deq_rdy; 
        logic [5:0]                     deq_tag; 
        logic [72:0]                    rdata; 
        logic [3:0]                     pipe_vld;
     } mdma_c2h_pfch_ll_2_debug_t;

    typedef struct packed {
        logic [12:0]                                 rsv;
        mdma_qid_t                                  cam_wr_key;
        logic                                       cam_wr_vld;
        mdma_c2h_cache_tag_t                        cam_wr_ix;

        logic                                       cam_del_vld;
        mdma_c2h_cache_tag_t                        cam_del_ix ;
        
        mdma_qid_t                                  dsc_cmp_qid;
        logic                                       dsc_cmp_err;
        logic                                       dsc_cmp_last;
        logic[63:0]                                 dsc_cmp_dsc;
        mdma_qidx_t                                 dsc_cmp_cidx;
        logic                                       dsc_cmp_vld;
        logic                                       dsc_cmp_rdy;

        logic                                       desc_rsp_vld;
        mdma_c2h_desc_rsp_t                         desc_rsp;
        logic                                       desc_rsp_rdy;

        logic [$clog2(MDMA_PFCH_CACHE_DEPTH+1)-1:0] cam_cnt;

        logic [$clog2(WR_ENG_FIFO_DEPTH):0]         fl_free_cnt;
        logic [1:0]                                 alloc_st;

    } mdma_c2h_pfch_cache_debug_t;

typedef struct packed {
    logic                       vld;
    logic                       qen;        // queue enable status.  1 : avl hold leftover credits, 0: avl hold available descriptors
    logic   [2:0]               port_id;
    logic                       err;
    logic                       byp;
    logic                       dir;
    logic                       mm;
    logic    [`QID_WIDTH-1:0]   qid;
    logic    [15:0]             avl;
    logic                       qinv;       //  queue enable was 1 but is now 0.  queue was invalidated
    logic                       irq_arm;    //  irq arm bit became set (not current state)
} tm_dsc_sts_t;

localparam MDMA_TM_DSC_STS_BITS=$bits(tm_dsc_sts_t);

    typedef struct packed {
        logic [12:0]                                             rsvd;
        logic                                                    dsc_crdt_vld;
        logic                                                    dsc_crdt_rdy;
        mdma_dsc_eng_crdt_t                                      dsc_crdt;

        logic [MDMA_TM_DSC_STS_BITS-1:0]                         tm_sts_in;
        logic                                                    tm_sts_in_rdy;

        logic [MDMA_TM_DSC_STS_BITS-1:0]                         tm_sts_out;
        logic                                                    tm_sts_out_rdy;

        logic                                                    dsc_err_vld;
        logic                                                    dsc_err_rdy;
        mdma_qid_t                                               dsc_err_qid;

        logic                                                    evt_vld;
        logic                                                    evt_rdy;
        mdma_c2h_cache_tag_t                                     evt_tag;
        mdma_qid_t                                               evt_qid;

        logic                                                    pfch_err_vld;
        logic                                                    pfch_err_rdy;
        mdma_c2h_pfch_ctxt2cache_t                               pfch_err;

        //Alloc interface. Allows only one outstanding request.
        logic                                                    alloc_req_vld;
        logic                                                    alloc_req_rdy;
        mdma_c2h_cache_alloc_t                                   alloc_req;
        logic                                                    alloc_rsp_vld;
        mdma_c2h_cache_tag_t                                     alloc_rsp;
        
        logic                                                    desc_req_cache_vld;
        mdma_c2h_crdt2cache_t                                    desc_req_cache;
        logic                                                    desc_req_cache_rdy;
    } mdma_c2h_pfch_crdt_2_debug_t;

    typedef struct packed {
        logic                                 int_coal_vec_vld;
        mdma_int_vec_id_coal_t                int_coal_vec;
        mdma_qid_t                            int_coal_qid;
        logic                                 int_coal_type;
        logic                                 int_coal_err_int;
        mdma_wrb_stat_desc_t                  int_coal_stat_desc;  
        logic                                 sm_dyn_int_req;
        logic [INT_CTXT_RAM_ADDR_BITS-1:0]    dyn_int_ctxt_ram_raddr;
        mdma_qidx_t                           dyn_int_sw_cidx;
        logic                                 dyn_process_end;
        int_coal_sm_type_e                    sm_cs;
    } mdma_c2h_debug_int_coal_t;   

    typedef struct packed {
        logic [3+9:0]                                    rsvd;
        logic                                           dyn_msi_int_vld;
        logic                                           wrb_send_msix_no_msix;
        logic                                           wrb_send_msix_ctxt_inval;
        logic                                           wrb_send_msix_ack;
        logic                                           wrb_send_msix_fail;
        mdma_c2h_int_req_t                              qid2vec_ram_ren_req;
        mdma_c2h_int_req_t                              qid2vec_ram_ren_gnt;
        logic [2:0]                                     int_fifo_out_cnt;
        logic [2:0]                                     h2c_fifo_out_cnt;
        logic [2:0]                                     dyn_fifo_out_cnt;
        logic                                           coal_int_vld;
        logic                                           coal_int_rdy;
        mdma_c2h_wrb2int_t                              coal_int_vec;
        logic                                           h2c_int_vld;
        logic                                           h2c_int_rdy;
        mdma_c2h_wrb2int_t                              h2c_int_vec;
        mdma_int_vec_out_t                              c2h_msi_vec;
        logic                                           c2h_msi_int_vld;
        mdma_fnid_t                                     c2h_msi_func_num;  
        logic                                           c2h_msi_sent_ack;
        logic                                           c2h_msi_int_fail;
        logic                                           int_wrq_vld;
        logic                                           int_wrq_rdy;
        logic [7:0]                                     int_wrq_packet_fnc;
        logic [7:0]                                     int_wrq_packet_rid;
        logic                                           int_wpl_ren;
        logic                                           int_wpl_vld;
        logic                                           int_wcp_vld;
        logic [7:0]                                     int_wcp_cpl_rid;
        logic                                           int_wcp_cpl_err;
        int_sm_type_e                                   sm_cs;
        //mdma_c2h_int_req_t                              qid2vec_ram_ren_req_1;
        logic                                           wrb_int_entry_en_coal;
        logic                                           h2c_int_entry_en_coal;
        logic                                           err_int_entry_en_coal;
   } mdma_c2h_debug_interrupt_t;  

    typedef struct packed {
        logic                                                          wrb_timer_vld;
        logic                                                          wrb_timer_rdy;
        mdma_c2h_wrb2timer_t                                           wrb_timer_req;
        logic                                                          timer_exp_vld;
        logic                                                          timer_exp_rdy;
        mdma_qid_t                                                     timer_exp_qid;
        logic                                                          ref_timer_en;
        logic                                                          ref_timer_stall;
        logic                                                          timer_tick_stop;
        logic [TIMER_BITS-1:0]                                         ref_timer;
        logic [3:0][TIMER_TOTAL_FIFO_CNT_BITS-1:0]                     quad_cnt;
        logic [TIMER_BITS-1:0]                                         timer_inj_value;
        logic [TIMER_FIFO_RAM_NUM-1:0]                                 wrb_timer_request;
        logic [TIMER_FIFO_RAM_NUM-1:0]                                 wrb_timer_fifo_accepted;
        logic [TIMER_FIFO_RAM_NUM-1:0]                                 timer_fifo_exp_vld;
        logic [TIMER_FIFO_RAM_NUM-1:0]                                 timer_fifo_exp_gnt;
        logic [TIMER_FIFO_RAM_NUM-1:0] [TIMER_FIFO_CNT_BITS-1:0]       timer_fifo_out_cnt;
        logic [TIMER_FIFO_RAM_NUM-1:0]                                 timer_fifo_in_vld;
        mdma_timer_fifo_dat_t [TIMER_FIFO_RAM_NUM-1:0]                 timer_fifo_in_data;
        logic [TIMER_FIFO_RAM_NUM-1:0]                                 timer_fifo_out_vld;
        logic [TIMER_FIFO_RAM_NUM-1:0]                                 timer_fifo_out_rdy;
        logic [TIMER_FIFO_RAM_NUM-1:0]                                 timer_fifo_exp_accepted;
        logic                                                          timer_fifo_evict;
   } mdma_c2h_debug_timer_1_t;  

    typedef struct packed {
         logic [TIMER_FIFO_RAM_NUM-1:0]                                 fifo_wrap_vld;
         logic [TIMER_FIFO_RAM_NUM-1:0]                                 timer_fifo_evict_accpeted;
         mdma_timer_fifo_dat_t [TIMER_FIFO_RAM_NUM-1:0]                 timer_fifo_out_dat;
         logic [TIMER_FIFO_RAM_NUM-1:0]                                 timer_fifo_evict_gnt;
    } mdma_c2h_debug_timer_part_2_t; 

    localparam DEBUG_TIMER_2_RSVD_BITS = 256 - $bits(mdma_c2h_debug_timer_part_2_t) - $bits(mdma_c2h_debug_int_coal_t) -1; 

    typedef struct packed {
         logic [DEBUG_TIMER_2_RSVD_BITS-1:0]                            rsvd;
         logic                                                          dma_err_int_out;         // DMA error aggregator output              
         mdma_c2h_debug_timer_part_2_t                                  mdma_c2h_debug_timer_part_2;   
         mdma_c2h_debug_int_coal_t                                      mdma_c2h_debug_int_coal;
    } mdma_c2h_debug_timer_2_t;   

    // C2H Debug signals, 256 bits per struct
    typedef union packed {
        mdma_c2h_pfch_fl_vec_1_debug_t c2h_pfch_fl_vec_1;
        mdma_c2h_pfch_fl_vec_2_debug_t c2h_pfch_fl_vec_2;
        mdma_c2h_pfch_ll_debug_t       c2h_pfch_ll;
        mdma_c2h_pfch_ll_2_debug_t     c2h_pfch_ll_2;
        mdma_c2h_pfch_cache_debug_t    c2h_pfch_cache;
        mdma_c2h_pfch_crdt_debug_t     c2h_pfch_crdt;
        mdma_c2h_pfch_cache_2_debug_t  c2h_pfch_cache_2;
        mdma_c2h_debug_dma_wr_eng_t    c2h_dma_eng;
        mdma_c2h_debug_dma_wr_eng_2_t  c2h_dma_eng_2;
        mdma_c2h_debug_interrupt_t     c2h_int;
        mdma_c2h_debug_timer_1_t       c2h_timer_1;
        mdma_c2h_debug_timer_2_t       c2h_timer_2;
        mdma_c2h_pfch_crdt_2_debug_t   c2h_pfch_crdt_2;
        logic [255:0]                  c2h_debug;
    } mdma_c2h_debug_t;
    
    localparam MDMA_MAX_QID        = 1<<$bits(mdma_qid_t);

    // Descriptor Request fifo RAM
    localparam DESC_REQ_FIFO_RAM_DATA_BITS    = $bits(mdma_c2h_crdt2cache_t);
    localparam DESC_REQ_FIFO_RAM_DEPTH        = WR_ENG_FIFO_DEPTH;
    localparam DESC_REQ_FIFO_RAM_ADDR_BITS    = $clog2(WR_ENG_FIFO_DEPTH);
    localparam DESC_REQ_FIFO_RAM_RDT_FFOUT    = 1;

    // Prefetch context RAM
    localparam PFCH_CTXT_RAM_DATA_BITS    = $bits(mdma_wrb_c2h_pftch_ctxt_t);
    localparam PFCH_CTXT_RAM_DEPTH        = 1<<$bits(mdma_qid_t);
    localparam PFCH_CTXT_RAM_ADDR_BITS    = $clog2(PFCH_CTXT_RAM_DEPTH);
    localparam PFCH_CTXT_RAM_RDT_FFOUT    = 1;

    // Prefetch context RAM
    localparam PFCH_LL_RAM_DATA_BITS    = $bits(mdma_dma_buf_addr_t) + $bits(mdma_fnid_t) + 8;
    localparam PFCH_LL_RAM_DEPTH        = WR_ENG_FIFO_DEPTH;
    localparam PFCH_LL_RAM_ADDR_BITS    = $clog2(PFCH_LL_RAM_DEPTH);
    localparam PFCH_LL_RAM_RDT_FFOUT    = 1;

    // WRB context RAM
    localparam WRB_CTXT_RAM_DATA_BITS    = $bits(mdma_wrb_ctxt_t);
    localparam WRB_CTXT_RAM_DEPTH        = 1<<$bits(mdma_qid_t);
    localparam WRB_CTXT_RAM_ADDR_BITS    = $clog2(WRB_CTXT_RAM_DEPTH);
    localparam WRB_CTXT_RAM_RDT_FFOUT    = 1;

    typedef union packed {
        mdma_wrb_ctxt_t     wrb;
        logic [127:0]       chk;
    } mdma_wrb_ctxt_chk_t;

    // WRB context RAM
    localparam PASID_CTXT_RAM_DATA_BITS    = 32;
    localparam PASID_CTXT_RAM_DEPTH        = 1<<$bits(mdma_qid_t);
    localparam PASID_CTXT_RAM_ADDR_BITS    = $clog2(WRB_CTXT_RAM_DEPTH);
    localparam PASID_CTXT_RAM_RDT_FFOUT    = 1;
    localparam MDMA_NUM_PASID_RAMS    = 2;

    typedef enum logic [1:0] {
        MDMA_CTXT_CMD_CLR=0, MDMA_CTXT_CMD_WR, MDMA_CTXT_CMD_RD, MDMA_CTXT_CMD_INV
    } mdma_ind_ctxt_cmd_e;

    //wrb specific defines
    typedef enum logic {
        RD_IDLE=0, WAIT_RVLD
    } wrb_rd_sm_e;

    typedef struct packed {
        logic       ctxt;
        logic       wrb;
        logic       dyn;
        logic       timer;
    } mdma_c2h_wrb_inrra_rq_t;

    typedef struct packed {
        logic                       sw_used_cnt_gt;
        logic                       used_cnt_gt;
        mdma_qidx_t                 pidx_inc1;
        mdma_wrb_ctxt_t             orig;
        mdma_qidx_t                 size; //Usable descriptors
        mdma_byte_qidx_t            byte_size;
        mdma_dma_buf_addr_t         desc_addr;
        mdma_dma_buf_addr_t         stat_addr;
        logic                       pidx_rap; //Wrap around
        mdma_int_cnt_th_t           cnt_thresh;
        logic [5:0]                 desc_bsize; //descriptor byte size
    } mdma_wrb_dec_ctxt_t;

    // WRB Debug signals
    typedef struct packed {
        logic                           pstg_wr_vld;
        mdma_qid_t                      mgr_ctxt_wr_qid;
        mdma_c2h_wrb_inrra_rq_t         in_rra_gnt_wr;
        mdma_ind_ctxt_cmd_e             ctxt_rq_wr_op;
        mdma_dma_buf_len_t              wrb_mux_data_wr_data_len;
        logic                           wrb_mux_data_wr_data_desc_err;
        logic                           wrb_mux_data_wr_marker;
        logic                           wrb_mux_data_wrb_user_int;
        logic                           mgr_ctxt_wdata_tmr_running;
        logic                           mgr_ctxt_wdata_usr_int_pend;
        mdma_wrb_err_e                  mgr_ctxt_wdata_err;
        logic                           mgr_ctxt_wdata_valid;
        mdma_qidx_t                     mgr_ctxt_wdata_cidx;
        mdma_qidx_t                     mgr_ctxt_wdata_pidx;
        logic                           mgr_ctxt_wdata_color;
        mdma_c2h_wrb_int_state_e        mgr_ctxt_wdata_int_st;
        logic                           mgr_ctxt_wdata_en_int;
        logic                           mgr_ctxt_wdata_en_stat_desc;
        mdma_wrb_cnt_th_ix_t            mgr_ctxt_wdata_cnt_ix;
        mdma_wrb_timer_th_ix_t          mgr_ctxt_wdata_timer_ix;
        mdma_c2h_wrb_trig_mode_e        mgr_ctxt_wdata_trig_mode;
        logic                           ctxt_dec_wr_sw_used_cnt_gt;
        logic                           ctxt_dec_wr_used_cnt_gt;
        logic                           ctxt_dec_wr_pidx_rap;
        logic                           ctxt_dec_wr_orig_tmr_running;
        logic                           ctxt_dec_wr_orig_usr_int_pend;
        mdma_wrb_err_e                  ctxt_dec_wr_orig_err;
        logic                           ctxt_dec_wr_orig_valid;
        mdma_qidx_t                     ctxt_dec_wr_orig_cidx;
        mdma_qidx_t                     ctxt_dec_wr_orig_pidx;
        logic                           ctxt_dec_wr_orig_color;
        mdma_c2h_wrb_int_state_e        ctxt_dec_wr_orig_int_st;
        logic                           ctxt_dec_wr_orig_en_int;
        logic                           ctxt_dec_wr_orig_en_stat_desc;
        mdma_wrb_cnt_th_ix_t            ctxt_dec_wr_orig_cnt_ix;
        mdma_wrb_timer_th_ix_t          ctxt_dec_wr_orig_timer_ix;
        mdma_c2h_wrb_trig_mode_e        ctxt_dec_wr_orig_trig_mode;
        logic                           st_out_stat_int;
        logic                           st_out_inj_timer;
        logic                           allow_wrb;
        logic                           allow_std;
        logic                           allow_int;
        logic                           allow_tmr;
        logic                           allow_mrkr;
        logic                           wrb_mux_rdy;
        logic                           wrb_mux_vld_rd;
        wrb_rd_sm_e                     rd_st;
        logic                           sm_wrb_vld;
        logic                           sm_wrb_null;
        logic                           sm_std_vld;
        logic                           sm_std_null;
        logic                           sm_int_vld;
        logic                           sm_int_null;
        logic                           sm_tmr_vld;
        logic                           sm_tmr_null;
        logic                           sm_mrkr_vld;
        logic                           sm_std_ctxt_drp;
        logic                           wrb_dma_fifo_vld;
        logic                           wrb_std_fifo_vld;
        logic                           wrb_int_fifo_vld;
        logic                           wrb_tmr_fifo_vld;
        logic                           wrb_marker_vld;
    } mdma_c2h_debug_wrb_t; 

    typedef struct packed {
        logic [28:0]                rsv;
        logic                       retry_mrkr_req;
        mdma_wrb_err_e              err;
    } wrb_mrkr_rsp_stat_t;

    typedef struct packed {
        wrb_mrkr_rsp_stat_t     wrb_stat;
        logic [2:0]             port_id;
        logic [7:0]             fnc;
        logic [`QID_WIDTH-1:0]  qid;
    } wrb_mrkr_rsp_t;



    //------------------------------------------------------------------------------------------------------------------
    // h2c-st
    //------------------------------------------------------------------------------------------------------------------
    //NOTE: wbc and eop fields of the following structs are hard-coded in:
    //      //IP3/DEV/hw/pcie_gen4/rtl_ev/pciea_dma/rtl/dma_pcie_mdma_fab_demux.sv
    typedef struct packed {
        //logic [57:0]                                    rsv;
        logic                                           zero_b_dma; //[69]
        logic [2:0]                                     port_id;    //[68:66]
        logic [31:0]                                    mdata;      //[65:34]
        logic [7:0]                                     err;        //[33:26]
        logic                                           wbc;        //[25]
        logic [$clog2($bits(mdma_int_tdata_t)/8)-1:0]   meb;        //[24:19]
        logic [$clog2($bits(mdma_int_tdata_t)/8)-1:0]   leb;        //[18:13]
        logic                                           eop;        //[12]
        logic                                           sop;        //[11]
        mdma_qid_t                                      qid;        //[10:0]
    } mdma_h2c_axis_unal_tuser_t;

    typedef struct packed {
        logic                                           zero_b;
        logic [5:0]                                     mty;        //[53:48]
        logic [31:0]                                    mdata;      //[47:16]
        logic                                           err;        //[15]
        logic [2:0]                                     port_id;    //[14:12]
        logic                                           wbc;        //[11]
        mdma_qid_t                                      qid;        //[10:0]
    } mdma_h2c_axis_tuser_t;

    typedef struct packed {
        logic [31:0]        addr_h; //[127:96]
        logic [31:0]        addr_l; //[95:64]
        logic [13:0]        rsv1;   //[63:50]
        logic               eop;    //[49]
        logic               sop;    //[48]
        logic [15:0]        len;    //[47:32]
        logic [31:0]        rsv2;   //[31:0]
    } mdma_h2c_byp_in_dsc_t;

    typedef struct packed {
        logic [31:0]        addr_h; //[127:96]
        logic [31:0]        addr_l; //[95:64]
        logic [15:0]        rsv1;   //[63:48]
        logic [15:0]        len;    //[47:32]
        logic [31:0]        rsv2;   //[31:0]
    } mdma_h2c_dsc_t;

    typedef struct packed {
        mdma_stat_t                     num_dsc_rcvd;
        mdma_stat_t                     num_wrb_sent;
    } mdma_h2c_core_dbg_reg32_0_t;

    typedef struct packed {
        mdma_stat_t                     num_req_sent;
        mdma_stat_t                     num_cmp_rcvd;
    } mdma_h2c_core_dbg_reg32_1_t;

    typedef struct packed {
        mdma_stat_t                     rsv;
        mdma_stat_t                     num_err_dsc_rcvd;
    } mdma_h2c_core_dbg_reg32_2_t;

    typedef struct packed {
        logic                           rsv;
        logic                           dsco_fifo_empty;
        logic                           dsco_fifo_full;
        logic [2:0]                     cur_rc_state;
        logic [9:0]                     rdreq_lines;
        logic [9:0]                     rdata_lines_avail;
        logic                           pend_fifo_empty;
        logic                           pend_fifo_full;
        logic [1:0]                     cur_rq_state;
        logic                           dsci_fifo_full;
        logic                           dsci_fifo_empty;
    } mdma_h2c_core_dbg_reg32_3_t;

    typedef struct packed {
        logic [31:0]                    rdreq_addr;
    } mdma_h2c_core_dbg_reg32_4_t;

    typedef struct packed {
        mdma_h2c_core_dbg_reg32_0_t     reg_0;
        mdma_h2c_core_dbg_reg32_1_t     reg_1;
        mdma_h2c_core_dbg_reg32_2_t     reg_2;
        mdma_h2c_core_dbg_reg32_3_t     reg_3;
        mdma_h2c_core_dbg_reg32_4_t     reg_4;
    } mdma_h2c_core_dbg_reg_t;
    //------------------------------------------------------------------------------------------------------------------


`endif



