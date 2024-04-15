
`ifndef CPM5_MDMA_DEFINES_SVH
`define CPM5_MDMA_DEFINES_SVH
    localparam MDMA_PFCH_CACHE_MAX_DEPTH=128;           // Maximum depth

    typedef logic [511:0]                           mdma_int_tdata_t;
    typedef logic [10:0]                            mdma_pid_t;
    typedef logic [3:0]                             mdma_host_id_t;
    typedef logic [12:0]                            mdma_qid_max_t;
    typedef logic [11:0]                            mdma_qid_t;
    typedef logic [8:0]                             mdma_pfch_cnt_t;
    typedef logic [12:0]                            mdma_cqid_t;
    typedef logic [23:0]                            mdma_qid_outside_t;
    typedef logic [15:0]                            mdma_qidx_t;
    typedef logic [15:0]                            mdma_pld_pkt_id_t;
    typedef logic                                   mdma_virt_ch_t;
    typedef logic [21:0]                            mdma_byte_qidx_t;
    typedef logic [11:0]                            mdma_int_pidx_t;
    typedef logic [15:0]                            mdma_qsize_t;
    typedef logic [9:0]                             mdma_qsize_64desc_t;
    typedef logic [15:0]                            mdma_dma_buf_len_t;
    localparam  MDMA_C2H_ST_MAX_LEN = (1<<$bits(mdma_dma_buf_len_t))-1;
    typedef logic [63:6]                            mdma_dma_buf_addr64_t;
    typedef logic [63:12]                           mdma_dma_buf_addr4k_t;
    typedef logic [63:6]                            mdma_dma_buf_addr4_high_t;
    typedef logic [5:2]                             mdma_dma_buf_addr4_low_t;
    typedef logic [63:2]                            mdma_dma_buf_addr4_t;
    typedef logic [63:0]                            mdma_dma_buf_addr_t;
    typedef logic [511:0]                           mdma_dma_wrb_data_t;
    typedef logic [127:0]                           mdma_dma_wrb_data_fab_t;
    typedef logic [255:0]                           mdma_max_dsc_t;
    //typedef mdma_max_dsc_t                          mdma_dma_wrb_dual_data_t;
    //typedef logic [235:0]                           mdma_dma_wrb_user_data_standard_t;
    //typedef logic [252:0]                           mdma_dma_wrb_user_data_defined_t;
    typedef logic [17:0]                            mdma_stat_t;
    typedef logic [11:0]                            mdma_fnid_t;
    typedef logic [2:0]                             mdma_int_page_size_t;
    typedef logic [31:0]                            mdma_int_vec_out_t;
    typedef logic [7:0]                             mdma_int_vec_id_coal_t; // Absolute vector id
    typedef logic [10:0]                            mdma_int_vec_id_t; 
    typedef logic [15:0]                            mdma_int_cnt_th_t; //Absolute interrupt count threshold
    typedef logic [15:0]                            mdma_int_timer_cnt_t; //Absolute interrupt count threshold
    typedef logic [$clog2($bits(mdma_int_tdata_t)/64) -1:0]  mdma_wr_coal_offset_t;
    typedef logic [$clog2($bits(mdma_int_tdata_t)/64):0]     mdma_wr_coal_len64_t;

    localparam  MDMA_C2H_MAX_STBUF = 31;
    typedef logic [$clog2(MDMA_C2H_MAX_STBUF+1)-1:0]         mdma_desc_cnt_t;
    typedef logic [$clog2(MDMA_PFCH_CACHE_MAX_DEPTH)-1:0]    mdma_c2h_cache_tag_t;
    typedef logic [3:0]                                      mdma_c2h_buf_size_ix_t;

    typedef enum logic {
        H2C=0, C2H=1
    } mdma_dir_e;

    typedef logic [21:0] mdma_pasid_val_t;
    typedef struct packed {
        logic                   pasid_en;
        mdma_pasid_val_t        pasid;
   } mdma_pasid_t;

    typedef struct packed {
        logic                       int_sup;
        logic                       int_allow;
        logic                       noe;
        logic                       sw_db;
        logic                       hw_db;
        logic                       en_not;
        logic                       dis_not;
        mdma_qid_t                  qid;
    } mdma_vio_wm_fifo_t; 

    // H2C Writeback Data (H2C read engine -> H2C writeback engine)
    typedef struct packed {
        mdma_pasid_t                pasid;
        logic [1:0]                 at;
        logic                       wbi;
        logic                       wbi_chk;
        logic [2:0]                 fmt;      // 0x0: std dsc, 0x1: mrkr_rsp, 0x2: non-virtio fetch_imm, 0x3: int reserved (fence), 0x4: virtio_avl, 0x6: virtio_dsc, 0x7 int reserved (fence)
        logic [1:0]                 err;      // bit[1] : dsc error, bit[0] dma erro
        mdma_fnid_t                 fnc;
        logic [15:0]                cidx;
        logic                       sel;
        mdma_qid_t                  qid;     // Q ID
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
      mdma_pasid_t            pasid;
      logic                   vch_id;   //Virtual channel for the WB - 0:PCIe, 1:AXIMM
      mdma_host_id_t          host_id;        
      logic                   dis_intr_on_vf;  // Disable interrupt with VF 
      logic                   int_aggr; // Indirect (1) or direct (0)interupt
      mdma_int_vec_id_t       vec;      // MSI/MSIX vector
      logic                   at;
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
      mdma_host_id_t          host_id;
      logic                   st_mm;   // 
      logic                   err;     // Error status      // bit[1] : dma error, bit[0] dsc erro
      mdma_qidx_t             cidx;    // Context Index
      mdma_qid_t              qid;     // Queue ID
   } mdma_wb_sts_t;

    typedef struct packed {
        logic [6:0]         ecc;           //ECC to protect the header fields
        logic               var_desc;      // Variable descriptor
        logic               drop_req;      // Drop the data packet and CMPT packet
        logic               num_buf_ov;    // Override the num_buf for merge rx buffer
        mdma_host_id_t      host_id;       
        logic               has_cmpt;      // Has completion
        logic               marker;        // Make sure the pipeline is completely flushed
        logic [2:0]         port_id;
        mdma_qid_t          qid;           // FIXME 
        mdma_dma_buf_len_t  len;
    } mdma_c2h_axis_ctrl_t;

    // pciea_int
    typedef struct packed {
        logic [6:0]         ecc;           //ECC to protect the header fields
        logic               var_desc;      // Variable descriptor
        logic               drop_req;      // Drop the data packet and CMPT packet
        logic               num_buf_ov; 
        mdma_host_id_t      host_id;
        logic               has_cmpt;      // Has completion
        logic               marker;        // Make sure the pipeline is completely flushed
        logic [2:0]         port_id;
        mdma_qid_outside_t  qid;           // FIXME 
        mdma_dma_buf_len_t  len;
    } mdma_c2h_axis_ctrl_outside_t;

    typedef struct packed {
        mdma_int_tdata_t    tdata;
        logic [$bits(mdma_int_tdata_t)/8 - 1 :0]   par; 
    } mdma_c2h_axis_data_t;

    typedef struct packed {
        mdma_int_tdata_t    tdata;
        logic [$bits(mdma_int_tdata_t)/8 - 1 :0]   par;
    } mdma_h2c_axis_data_t;

    // Virtual channel
    localparam  MDMA_VIRT_CH = 2;

    typedef enum logic [1:0]    {
        WRB_DSC_8B=0, WRB_DSC_16B=1, WRB_DSC_32B=2, WRB_DSC_64B=3
    } mdma_c2h_wrb_type_e;

    localparam  MDMA_C2H_WRB_PAR_BITS     = $bits(mdma_dma_wrb_data_t)/32;
    localparam  MDMA_C2H_WRB_PAR_FAB_BITS = $bits(mdma_dma_wrb_data_fab_t)/32;

    typedef struct packed {
        logic [$bits(mdma_dma_wrb_data_t)/8-1:0]   wrb_data;
        logic [MDMA_C2H_WRB_PAR_BITS/8-1:0]        dpar; //Data parity
    } mdma_c2h_wrb_data_8B_chunk_t;

    typedef struct packed {
        mdma_dma_wrb_data_t          wrb_data;
        logic [MDMA_C2H_WRB_PAR_BITS-1:0] dpar; //Data parity
    } mdma_c2h_wrb_data_t;

    // HAS_PLD: The CMPT packet has a corresponding payload packet; It needs to wait for the payload packet to be sent before sending the CMPT packet
    // NO_PLD_NO_WAIT: The CMPT packet doesn't have a corresponding payload packet; It doesn't need to wait
    // NO_PLD_BUT_WAIT: The CMPT packet doesn't have a corresponding payload packet; But it still needs to wait for the payload packet to be sent before sending the cmpt packet
    typedef enum logic [1:0]    {
        NO_PLD_NO_WAIT=0, NO_PLD_BUT_WAIT=1, RSVD=2, HAS_PLD=3
    } mdma_c2h_cmpt_type_e;

    typedef struct packed {
        logic                                 non_blocking;     // 1'b1: CMPT non-blocking by payload, 1'b0: CMPT blocking by payload          
        logic                                 no_wrb_marker;
        mdma_virt_ch_t                        pld_virt_ch;      // If it has the paired payload, it is the virtual channel of the payload. 1'b0: PCIE, 1'b1: AXIMM 
        mdma_cqid_t                           cqid;             // Completion queue ID
        mdma_c2h_cmpt_type_e                  cmpt_type;        // Type of completion packet
        mdma_pld_pkt_id_t                     wait_pld_pkt_id;  // The data payload packet ID that it waits for
        logic [2:0]                           port_id;
        logic                                 marker;
        logic                                 user_trig;
        logic [2:0]                           color_idx;
        logic [2:0]                           desc_err_idx;
        mdma_c2h_wrb_type_e                   wrb_type;
    } mdma_c2h_wrb_user_t;

    // On pciea_int
    typedef struct packed {
        logic                                 non_blocking;     // 1'b1: CMPT non-blocking by payload, 1'b0: CMPT blocking by payload          
        logic                                 no_wrb_marker;
        mdma_virt_ch_t                        pld_virt_ch;      // If it has the paired payload, it is the virtual channel of the payload. 1'b0: PCIE, 1'b1: AXIMM 
        mdma_qid_outside_t                    cqid;             // Completion queue ID
        mdma_c2h_cmpt_type_e                  cmpt_type;        // Type of completion packet
        mdma_pld_pkt_id_t                     wait_pld_pkt_id;  // The data payload packet ID that it waits for
        logic [2:0]                           port_id;
        logic                                 marker;
        logic                                 user_trig;
        logic [2:0]                           color_idx;
        logic [2:0]                           desc_err_idx;
        mdma_c2h_wrb_type_e                   wrb_type;
    } mdma_c2h_wrb_user_outside_t;

    typedef struct packed {
        mdma_dma_wrb_data_fab_t          wrb_data;
        logic [MDMA_C2H_WRB_PAR_FAB_BITS-1:0] dpar; //Data parity
    } mdma_c2h_wrb_data_fab_t;

    localparam  MDMA_C2H_WRB_BITS    = $bits(mdma_c2h_wrb_data_t);
    localparam  MDMA_C2H_WRB_TL_BITS = $bits(mdma_c2h_wrb_data_fab_t);

    typedef struct packed {
        logic                   vio_wm;
        logic                   non_block;
        logic                   non_vio;
        logic                   vio_axi;
        logic                   vio_pcie;
    } mdma_wrb_fifo_in_req_t;    

    typedef struct packed {
        logic                   enable;      // Enable the CMPT data replacement by available ring index
        mdma_qidx_t             index;       // VirtIO available ring index
    } mdma_c2h_avl_idx_t;

    typedef struct packed {
        mdma_pasid_t            pasid;
        mdma_desc_cnt_t         cnt;
        mdma_c2h_avl_idx_t      avl_idx;     
        logic [1:0]             at;
        mdma_dma_buf_addr_t     addr;
        mdma_dma_buf_len_t      len;
        mdma_qid_t              qid;
        logic                   drop;
        logic                   last;
        logic                   error;
        mdma_fnid_t             func;
    } mdma_c2h_desc_rsp_t;

    typedef struct packed {
        logic                   var_desc;
        mdma_virt_ch_t          virt_ch;         // 1'b0: PCIE, 1'b1: AXI-MM
        logic                   marker;
        logic [2:0]             port_id;
        mdma_dma_buf_len_t      len;
        mdma_qid_t              qid;
    } mdma_c2h_desc_req_t;

    typedef logic[$clog2(MDMA_C2H_MAX_STBUF+1):0]    mdma_c2h_alloc_max_desc_t;   //Maximum descriptors prefetch

    typedef struct packed {
        mdma_c2h_alloc_max_desc_t    cnt;         
        mdma_qid_t                   qid;
    } mdma_c2h_evt_cmp_t;

    typedef struct packed {
        mdma_c2h_cache_tag_t         tag;         
        mdma_qid_t                   qid;
    } mdma_c2h_evt_t;

    typedef struct packed {
        logic [2:0]             port_id;
        logic                   host_target_id;  // 1'b0: PCIE, 1'b1: AXIMM
        logic                   error;
        logic                   valid;           // This is asserted per descriptor, or per packet for the case of imm_data or marker
        logic                   last;            
        logic                   drop;
        mdma_qid_t              qid;
        logic                   cmp;             // This descriptor has completion
    } mdma_desc_rsp_drop_t;

    typedef struct packed {
        logic [MDMA_VIRT_CH:0]     cmpt_fifo_rd_out;
        logic [MDMA_VIRT_CH-1:0]   qid_fifo_rd_out;
        logic [MDMA_VIRT_CH-1:0]   payload_fifo_rd_out;
        logic [MDMA_VIRT_CH-1:0]   pld_order;
        logic [MDMA_VIRT_CH-1:0]   smpl_byp_rd_out;
    } mdma_c2h_st_mhost_feedback_t;

    typedef struct packed {
        logic [15:0]            cmpt_wait_pld_pkt_id;
        logic [15:0]            data_pld_pkt_id;
    } mdma_stat_pld_pkt_id_t;

    typedef struct packed {
        logic [2:0]             port_id;
        logic                   virt_ch;  // 1'b0: PCIE, 1'b1: AXIMM
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
        logic                 virtio;
        mdma_desc_cnt_t       cnt; 
        mdma_c2h_cache_tag_t  tag;
    } mdma_deq_cnt_fifo_t;

    typedef struct packed {
        logic                 virtio;
        mdma_desc_cnt_t       cnt; 
        mdma_c2h_cache_tag_t  tag;
        mdma_qid_t            qid;
    } mdma_deq_cnt_t;

    typedef struct packed {
        mdma_qid_t          qid;
    } mdma_ctxt_mgr_evt_fifo_t;

    typedef struct packed {
        logic [56-1-$bits(mdma_dma_buf_len_t)-$bits(mdma_qid_t)-3-2-2-$bits(mdma_host_id_t)-1:0]         rsvd;
        logic               var_desc;      // Variable descriptor
        logic               drop_req;      // Drop the data packet and CMPT packet
        logic               num_buf_ov;
        mdma_host_id_t      host_id;
        logic               has_cmpt;      // Has completion
        logic               marker;        // Make sure the pipeline is completely flushed
        logic [2:0]         port_id;       // Port ID
        mdma_qid_t          qid;
        mdma_dma_buf_len_t  len;
    } mdma_qid_fifo_t;

    typedef struct packed {
        logic                   qid_mismatch; // This will check if the qid in the AXIS Ctrl input and the AXIS User Input matches. This assumes the qid in tuser_data[10:0] 
        logic                   pid_mismatch; // This will check the processing ID in the AXIS User Input matches. This assumes the pid in tuser_data[21:11]
        logic                   len_mismatch; // This checks if the total packet size matches Len
        logic                   mty_mismatch; // This checks if the mty input is zero in the non-last packet
    } mdma_s_axis_c2h_err_t;   

    typedef struct packed {
        logic [31-22:0]         rsvd;
        logic                   wrb_port_id_err;            // CMPT or CMPT CIDX update had incorrect port_id
        logic                   int_ctxt_host_id_mismatch;  // Host_ID mismatch on Interrupt Context for Point Update
        logic                   hdr_par_err;                // Parity error on C2H pkt header
        logic                   hdr_ecc_corr_err;           // Single-bit ecc error on the C2H pkt header
        logic                   hdr_ecc_uncorr_err;         // Multi-bit  ecc error on the C2H pkt header
        logic                   avl_ring_dsc_err;           //Indicates the avl-ring entry received with error flag
        logic                   wrb_prty_err;       
        logic                   wrb_cidx_err;               //Indicates that a PtrUpd was received with a bad cidx
        logic                   wrb_qfull_err;              //Indicates that a WRB was received on a FullQ
        logic                   wrb_inv_q_err;              //Indicates that a SW pointer UPD was received on an invalid Q
        logic                   rsvd3;
        logic                   port_id_ctxt_mismatch;
        logic                   err_desc_cnt;
        logic                   rsvd1;
        logic                   msi_int_fail;
        logic                   eng_wpl_data_par_err;
        logic                   rsvd2;
        logic                   desc_rsp_error;             // The desc_rsp from the Prefetch module has error bit set
        logic                   qid_mismatch;               // This will check if the qid in the AXIS Ctrl input and the AXIS User Input matches. This assumes the qid in tuser_data[10:0] 
        logic                   sh_cmpt_dsc_err;            // A shared CMPT queue saw a DSC error.
        logic                   len_mismatch;               // This checks if the total packet size matches Len
        logic                   mty_mismatch;               // This checks if the mty input is zero in the non-last packet
    } mdma_c2h_err_t;  

    typedef struct packed {
        logic [32-6-1:0]        rsvd;
        logic                   par_err;
        logic                   sbe;
        logic                   dbe;
        logic                   no_dma_dsc_err;
        logic                   wbi_mod_err;
        logic                   zero_len_dsc_err;
    } mdma_h2c_err_t; 

    typedef struct packed {
        logic [31-23:0]         Rsvd;
        logic                   hdr_par_err;        // Parity error on C2H pkt header
        logic                   hdr_ecc_uncorr_err; // Multi-bit  ecc error on the C2H pkt header
        logic                   avl_ring_fifo_ram_rdbe;
        logic                   wrb_prty_err;       
        logic                   wpl_data_par_err;       
        logic                   payload_fifo_ram_rdbe;  
        logic                   qid_fifo_ram_rdbe;      
        logic                   cmpt_fifo_ram_rdbe;      
        logic                   wrb_coal_data_ram_rdbe; 
        logic                   Rsvd2;   
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
        logic [32-16-5-1:0]            rsvd;
        logic [4:0]                    err_type;
        logic [15-$bits(mdma_qid_max_t):0] rsvd1;
        mdma_qid_max_t                 qid;
    } mdma_c2h_first_err_t;    

    typedef struct packed {
        logic [32-16-4-1:0]                 rsvd;
        logic [3:0]                         err_type;
        logic [15-$bits(mdma_qid_max_t):0]  rsvd1;
        mdma_qid_max_t                      qid;
    } mdma_h2c_first_err_t;    

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

    typedef enum logic [2:0] {
        NONE        = 0,
        VIO_FLG     = 1,
        VIO_IDX     = 2,
        VIO_FLG_IDX = 3,
        VIO_4K_SPL0 = 4,
        VIO_4K_SPL1 = 5
    } mdma_wrb_coal_vio_ctrl_e;

    typedef struct packed {
        mdma_pasid_t                pasid;
        mdma_host_id_t              host_id;
        logic                       is_vio;
        mdma_wrb_coal_vio_ctrl_e    coal_vio_ctrl;
        logic                       at;
        mdma_cqid_t                 qid;
        mdma_dma_buf_addr_t         addr;
        mdma_fnid_t                 fnc;
        mdma_wr_coal_offset_t       offset;
        logic                       flsh;
        logic                       is_stat_desc;
        mdma_wr_coal_len64_t        len64;
    } mdma_wr_coal_buf_ctrl_t;

    typedef logic [3:0]             mdma_wrb_timer_th_ix_t;
    typedef logic [3:0]             mdma_wrb_cnt_th_ix_t;

    typedef enum logic [1:0] {
        WRB_INT_ISR=0,
        WRB_INT_TRIG=1,
        RSV_ST_0=2,
        RSV_ST_1=3
    } mdma_c2h_wrb_int_state_e;

    typedef enum logic [2:0] {
        IDLE_WT_CMPT    = 0,
        PRI_TMR_PEND    = 1,
        WT_EOP          = 2,
        WT_EOP_INT_RTY  = 3,
        WT_EOP_NOT_RTY  = 4,
        INT_RTY         = 5,
        NOT_RTY         = 6
    } mdma_cmpt_vio_int_st_e;

    //typedef enum logic [1:0] {
    //    WRB_VIO_WT_CMPT, WRB_VIO_ARM, VIO_RSV_ST_1, WRB_VIO_WT_TMR
    //} mdma_c2h_wrb_vio_int_state_e;

    //typedef union packed {
    //    mdma_c2h_wrb_int_state_e        wrb_int_st;
    //    mdma_c2h_wrb_vio_int_state_e    wrb_no_vio_int_st;
    //} mdma_wrb_int_st_t;

    typedef enum logic [2:0]    {
        WRB_TRIG_DIS=0, WRB_TRIG_EVERY, WRB_TRIG_USER_COUNT, WRB_TRIG_USER, WRB_TRIG_USER_TIMER, WRB_TRIG_USER_TIMER_COUNT
    } mdma_c2h_wrb_trig_mode_e;

    typedef enum logic [1:0] {
        WRB_ERR_NONE=0, WRB_ERR_CIDX, WRB_ERR_DSC, WRB_ERR_QFULL
    } mdma_wrb_err_e;

    typedef union packed {
        mdma_wrb_err_e    c2h_err;
        logic [1:0]                 h2c_err;
    } mdma_wrb_stat_err_t;

    // WRB context
    // For HardIP, the RAM is as deep as required to support the cqid struct. This is currently 8K.
    // For SoftIP, the BRAM is as deep as determined by a parameter passed by the user. Max is of course 8K. Stps are 512
    localparam WRB_CTXT_RAM_DATA_BITS      = 200;
    localparam WRB_CTXT_HARD_RAM_ADDR_BITS = $bits(mdma_cqid_t);
    localparam WRB_CTXT_RAM_RDT_FFOUT      = 1;

    localparam WRB_CTXT_RSV_BITS =  WRB_CTXT_RAM_DATA_BITS              -
                                    3                                   -   /*port_id*/
                                    1                                   -   /*sh_cmpt*/
                                    1                                   -   /*vio_eop*/
                                    $bits(mdma_dma_buf_addr4_low_t)     -   /*baddr_4_low*/
                                    $bits(mdma_pasid_t)                 -   /*pasid*/
                                    $bits(mdma_host_id_t)               -   /*host_id*/
                                    1                                   -   /*vio_c2h*/
                                    1                                   -   /*vio*/
                                    1                                   -   /*dis_intr_on_vf*/
                                    1                                   -   /*ind int*/
                                    $bits(mdma_int_vec_id_t)            -   /*msix vec*/
                                    1                                   -   /*at*/
                                    1                                   -   /*ovf_chk_dis*/
                                    1                                   -   /*full_upd*/
                                    1                                   -   /*tmr_running*/
                                    1                                   -   /*usr_int_pend*/
                                    $bits(mdma_wrb_err_e)               -   /*err*/
                                    1                                   -   /*valid*/
                                    $bits(mdma_qidx_t)                  -   /*cidx*/
                                    $bits(mdma_qidx_t)                  -   /*pidx*/
                                    $bits(mdma_c2h_wrb_type_e)          -   /*desc_size*/
                                    $bits(mdma_dma_buf_addr4_high_t)    -   /*baddr_4_high*/
                                    4                                   -   /*qsize_ix*/
                                    1                                   -   /*color*/
                                    $bits(mdma_c2h_wrb_int_state_e)     -   /*int_st*/
                                    $bits(mdma_wrb_timer_th_ix_t)       -   /*timer_ix*/
                                    $bits(mdma_wrb_cnt_th_ix_t)         -   /*cnt_ix*/
                                    $bits(mdma_fnid_t)                  -   /*fnid*/
                                    $bits(mdma_c2h_wrb_trig_mode_e)     -   /*trig_mode*/
                                    1                                   -   /*en_int*/
                                    1;                                      /*en_stat_desc*/

    typedef struct packed {
        logic [WRB_CTXT_RSV_BITS-1:0]   rsv;
        logic [2:0]                     port_id;
        logic                           sh_cmpt;
        logic                           vio_eop;
        mdma_dma_buf_addr4_low_t        baddr4_low;
        mdma_pasid_t                    pasid;
        mdma_host_id_t                  host_id;
        mdma_dir_e                      dir;
        logic                           vio;
        logic                           dis_intr_on_vf;
        logic                           int_aggr;
        mdma_int_vec_id_t               vec;
        logic                           at;
        logic                           ovf_chk_dis;
        logic                           full_upd;
        logic                           tmr_running;
        logic                           usr_int_pend;
        mdma_wrb_err_e                  err;
        logic                           valid;
        mdma_qidx_t                     cidx;
        mdma_qidx_t                     pidx;
        mdma_c2h_wrb_type_e             desc_size;
        mdma_dma_buf_addr4_high_t       baddr4_high;
        logic [3:0]                     qsize_ix;
        logic                           color;
        mdma_c2h_wrb_int_state_e        int_st;
        mdma_wrb_timer_th_ix_t          timer_ix;
        mdma_wrb_cnt_th_ix_t            cnt_ix;
        mdma_fnid_t                     fnid;
        mdma_c2h_wrb_trig_mode_e        trig_mode;
        logic                           en_int;
        logic                           en_stat_desc;
    } mdma_wrb_ctxt_t;

    //typedef struct packed {
    //    mdma_dma_wrb_user_data_standard_t       data;
    //    mdma_dma_buf_len_t                      len;
    //    logic                                   desc_used;    // 1'b1: packet uses the descriptor; 1'b0: packet doesn't use the descripor, ex imm_data, marker
    //    logic                                   desc_err;
    //    logic                                   color; 
    //    logic                                   data_format;  // 1'b1: User define format; 1'b0: User Standard format
    //} mdma_wrb_desc_t;                // User standard format

    //typedef struct packed {
    //    mdma_dma_wrb_user_data_defined_t        data;
    //    logic                                   desc_err;
    //    logic                                   color; 
    //    logic                                   data_format;  // 1'b1: User define format; 1'b0: User Standard format
    //} mdma_wrb_desc_user_defined_t;   // User defined format

    //typedef union packed {
    //    mdma_wrb_desc_t                         mdma_wrb_desc;
    //    mdma_wrb_desc_user_defined_t            mdma_wrb_desc_user_defined;
    //} mdma_wrb_desc_all_t;

    //typedef struct packed {
    //    mdma_dma_wrb_user_data_standard_t       data;
    //    logic [7:0]                             pid; 
    //    mdma_qid_t                              qid;
    //    logic                                   data_format;
    //} mdma_c2h_wrb_data_user_standard_t;

    //typedef struct packed {
    //    mdma_dma_wrb_user_data_defined_t        data;
    //    logic [1:0]                             rsvd;
    //    logic                                   data_format;
    //} mdma_c2h_wrb_data_user_defined_t;

    //typedef union packed {
    //    mdma_c2h_wrb_data_user_standard_t       mdma_c2h_wrb_data_user_standard;
    //    mdma_c2h_wrb_data_user_defined_t        mdma_c2h_wrb_data_user_defined;
    //} mdma_c2h_wrb_data_all_t;

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
        logic [$bits(mdma_int_tdata_t)/8 - 1 :0]  par;
        mdma_int_tdata_t                          dat;
    } mdma_wpl_t;

    typedef struct packed {
        logic [5:0]                 mty;
        mdma_int_tdata_t            dat;
    } mdma_payload_fifo_data_t;

    // FIFO parameters
    localparam MDMA_FIFO_BRAM_READ_LAT      = 2;
    localparam MDMA_FIFO_BRAM_BUF_WR        = 1;
    localparam MDMA_FIFO_BRAM_BUF_RD        = 1;

    // Prefetch parameters
    localparam EVT_INIT_CRDT           = 1;
    localparam CTXT_INIT_CRDT          = 1;
    localparam TM_STS_INIT_CRDT        = 2;
    localparam DEQ_CNT_INIT_CRDT       = 4;
    localparam DESC_REQ_INIT_CRDT      = 8;

    // DMA Write Engine parameters
    localparam WR_ENG_FIFO_DEPTH                 = 1024;
    localparam WR_ENG_PAYLOAD_FIFO_DEPTH         = 1024;
    localparam WR_ENG_QID_FIFO_DEPTH             = 1024;
    localparam WR_ENG_FIFO_ADDR_BITS             = $clog2(WR_ENG_FIFO_DEPTH); 
    localparam WR_ENG_PAYLOAD_FIFO_BITS          = $bits(mdma_wpl_t);
    localparam WR_ENG_QID_FIFO_BITS              = $bits(mdma_qid_fifo_t);
    localparam WR_ENG_PAYLOAD_FIFO_DATA_BYTE     = $bits(mdma_int_tdata_t)/8;
    localparam WR_ENG_PAYLOAD_FIFO_BYTE_CNT_BITS = $clog2(WR_ENG_PAYLOAD_FIFO_DEPTH*WR_ENG_PAYLOAD_FIFO_DATA_BYTE+1);

    // Wrb Coal parameters
    localparam WRB_COAL_BUF_MAX_ADR_BITS    = 7;
    localparam WRB_COAL_BUF_BITS            = 512;
    localparam WRB_COAL_DATA_RAM_NUM        = 8;
    localparam WRB_COAL_RDT_FFOUT           = 1;
    localparam WRB_COAL_EN_FLUSH            = 1;
    localparam WRB_COAL_BUF_CTRL_BITS       = $bits(mdma_wr_coal_buf_ctrl_t);

    //ALL params for WRB_COAL_CFG register
    localparam MAX_BUF_SZ_BITS             = 6;
    localparam TICK_VAL_BITS               = 12;
    localparam TICK_CNT_BITS               = 12;
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
        mdma_host_id_t          host_id;
        logic                   dis_intr_on_vf;  // 1'b1: disable interrupt with VF; 1'b0: allow interrupt with VF
        logic                   int_aggr; // 1'b1: indirect interrupt; 1'b0: direct interrupt
        mdma_int_vec_id_t       vec;   
        logic                   sel;      // 0: H2C; 1: C2H
        logic                   err_int;  // Error generated interrupt 
        mdma_fnid_t             fnc;
        mdma_qidx_t             qid;
        mdma_wrb_stat_desc_t    stat_desc; 
    } mdma_c2h_wrb2int_t;

    typedef struct packed {
        mdma_dir_e              dir;
        logic                   vio;
        mdma_cqid_t             qid;
        mdma_wrb_timer_th_ix_t  timer_ix;
    } mdma_c2h_wrb2timer_t;

    typedef struct packed {
        mdma_dir_e              dir;
        logic                   vio;
        mdma_cqid_t             qid;
    } mdma_c2h_timer2wrb_t;

    typedef struct packed {
        mdma_qid_max_t          qid_max;
        mdma_qid_t              qid_base;
    } mdma_func_map_t;

    typedef enum logic [0:0]    {
        WAIT_TRIGGER=0, ISR_RUNNING=1
    } mdma_int_state_e;

    // Interrupt Context RAM data
    typedef struct packed {
        logic [114-1-4-$bits(mdma_int_vec_id_t)-$bits(mdma_int_state_e)-$bits(mdma_dma_buf_addr4k_t)-$bits(mdma_int_page_size_t)-$bits(mdma_int_pidx_t)-$bits(mdma_host_id_t)-$bits(mdma_pasid_t):0]   rsvd;
        mdma_pasid_t                pasid;
        mdma_host_id_t              host_id;
        logic                       at;
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
        mdma_qid_outside_t                                                                qid;
        logic                                                                             int_type;   // 0: H2C; 1: C2H
        logic                                                                             err_int;    // Error generated interrupt
        mdma_wrb_stat_desc_t                                                              stat_desc;
    } mdma_int_wpl_pkt_t;

    // Interrupt wpl pkt to PCIE
    typedef struct packed {
        logic [$bits(mdma_int_tdata_t)-64-1:0]                                            rsvd1;
        logic                                                                             coal_color;
        mdma_qid_outside_t                                                                qid;
        logic                                                                             int_type;   // 0: H2C; 1: C2H
        logic                                                                             err_int;    // Error generated interrupt
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

    typedef enum logic [2:0] {
        MDMA_CRD_ADD =3'h0, MDMA_CRD_SUB = 3'h1, MDMA_IDX_SUB=3'h2, MDMA_FETCH_IMM= 3'h3 , MDMA_FETCH_IMM_INT=3'd4
    } mdma_dsc_eng_crdt_op_e;

    typedef struct packed {
        logic                    virtio;
        mdma_c2h_cache_tag_t     pfch_tag;
        mdma_c2h_buf_size_ix_t   buf_sz_ix;
        logic                    var_desc;
        logic                    c2h_pfch;
    } mdma_c2h_misc_t;

    typedef struct packed {
        mdma_c2h_misc_t          misc;
        logic [1:0]              bsel;      // Base address select for FETCH_IMM mode. 2'h0: Ctxt base_address/Virtio Desc Base; 2'h1: Virtio Avail Base
        mdma_qidx_t              idx;       // Index from the base to start fetch for FETCH_IMM mode
        logic                    fence;     // Block further credits updates until fetch is completed for this update
        mdma_dsc_eng_crdt_op_e   op;
        logic                    sel;       //0 H2C, 1 C2H
    } mdma_dsc_eng_crdt_info_t;

    typedef struct packed {
        mdma_c2h_misc_t        misc;
        logic [1:0]            bsel;      // Base address select for FETCH_IMM mode. 2'h0: Ctxt base_address/Virtio Desc Base; 2'h1: Virtio Avail Base
        mdma_qidx_t            idx;       // Index from the base to start fetch for FETCH_IMM mode
        logic                  fence;     // Block further credits updates until fetch is completed for this update
        mdma_dsc_eng_crdt_op_e op;
        logic                  sel;       //0 H2C, 1 C2H
        mdma_qid_t             qid;
        mdma_qidx_t            crdt;
    } mdma_dsc_eng_crdt_t;

    typedef struct packed {
        mdma_qid_t                         qid;
        logic                              var_desc;
        mdma_c2h_buf_size_ix_t             buf_sz_ix; // Buffer size index
        mdma_c2h_cache_tag_t               pfch_tag;
        mdma_qidx_t                        cnt;
    } mdma_pfch_tag_ram_data_t;

    localparam  PFCH_TAG_RAM_DEPTH     = 1024;
    localparam  PFCH_TAG_RAM_DATA_BITS = $bits(mdma_pfch_tag_ram_data_t);
    localparam  PFCH_TAG_RAM_CNT_BITS  = $clog2(PFCH_TAG_RAM_DEPTH+1);

    typedef struct packed {
        mdma_c2h_misc_t     misc;
        mdma_qidx_t         idx;       // Index from the base to start fetch for FETCH_IMM mode
        logic               sel;       //0 H2C, 1 C2H
        mdma_qid_t          qid;
        mdma_qidx_t         crdt;
    } mdma_dsc_eng_imm_crdt_t;

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

    typedef struct packed {
        logic                       valid;
        mdma_qidx_t                 sw_crdt;
        logic                       pfch;
        logic                       pfch_en;
        logic                       err;
        logic [16-$bits(mdma_c2h_alloc_max_desc_t)-$bits(mdma_c2h_alloc_max_desc_t)-1:0]  rsv;
        mdma_c2h_alloc_max_desc_t   pfch_need;
        mdma_c2h_alloc_max_desc_t   num_pfch;
        logic                       virtio;
        logic                       var_desc;
        logic [2:0]                 port_id;
        mdma_c2h_buf_size_ix_t      buf_size_ix;
        logic                       bypass;
    } mdma_wrb_c2h_pftch_ctxt_t;

    typedef struct packed {
        logic           ctxt_valid;
        mdma_qid_t      qid;
        //Add cache flush here
    } mdma_c2h_pfch_ctxt2cache_t;

    typedef enum logic [0:0] {
        HPTR_INV, HPTR_VLD
    } hptr_st_e;

    typedef enum logic [2:0] {
        MDMA_PFCH_TYPE_DESC, MDMA_PFCH_TYPE_CFLUSH, MDMA_PFCH_TYPE_EFLUSH, MDMA_PFCH_TYPE_DSC_INV, MDMA_PFCH_TYPE_EFLUSH_CMP, MDMA_PFCH_TYPE_DEQ_CRDT, MDMA_PFCH_TYPE_SMPL_BYP 
    } mdma_pfch_cmd_type_e;

    typedef struct packed {
        mdma_qid_t                  qid;
        mdma_c2h_cache_tag_t        tag;
        mdma_c2h_alloc_max_desc_t   cnt;
        logic                       pfch;
        mdma_pfch_cmd_type_e        typ;        
    } mdma_c2h_cache_alloc_t;

    typedef struct packed {
        logic [141-1-64-$bits(mdma_fnid_t)-2-1-$bits(mdma_c2h_avl_idx_t)-$bits(mdma_dma_buf_len_t)-$bits(mdma_pasid_t):0] rsvd;
        mdma_pasid_t                pasid;
        mdma_c2h_avl_idx_t          avl_idx;
        logic                       err;
        logic [1:0]                 at;
        mdma_fnid_t                 fnc;
        mdma_dma_buf_len_t          len;
        logic [63:0]                dsc;
    } mdma_c2h_pfch_ll_t;

    typedef struct packed {
        logic [64-1-1-$bits(mdma_c2h_cache_tag_t)-3-$bits(mdma_dma_buf_len_t)-$bits(mdma_qid_t)-3-$bits(mdma_virt_ch_t)-$bits(mdma_dma_buf_len_t)-1:0]      rsvd;
        logic                       virtio;
        logic                       var_desc;
        mdma_dma_buf_len_t          buf_len; 
        mdma_virt_ch_t              virt_ch;
        logic [2:0]                 port_id;
        mdma_qid_t                  qid;
        mdma_dma_buf_len_t          len;
        logic                       last;
        logic                       byp;
        logic                       drop;
        mdma_c2h_cache_tag_t        tag;
    } mdma_c2h_crdt2cache_t;

    typedef struct packed {
        logic       ctxt_mgr_evt;
        logic       deq_cnt;
        logic       evt_cmp;
        logic       ctxt;
        logic       tm_sts;
        logic       desc_req;
        logic       dsc_err;
        logic       evt;
    } mdma_crdt_rra_q_t;

    typedef enum logic [0:0]    {
        WRB_SM_IDLE, WRB_SM_START 
    } wrb_sm_type_e;

    typedef enum logic [1:0]    {
        TUSER_INIT_IDLE, TUSER_INIT_ON, TUSER_INIT_DONE 
    } tuser_init_sm_type_e;

    typedef enum logic [1:0]    {
        ERR_CTXT_INIT_IDLE, ERR_CTXT_INIT_ON, ERR_CTXT_INIT_DONE 
    } err_ctxt_init_sm_type_e;

    typedef enum logic [3:0]    {
        ENG_IDLE=0, WAIT_DESC_RSP=1, SEND_WR_REQ=2, DROP_WAIT=3, DROP=4, DROP_WAIT_WRQ=5, ERROR_WAIT=6, ERROR=7, ERROR_WAIT_WRQ=8, WAIT_MARKER_RSP=9, WRQ_NUM_BUF=10
    } dma_eng_sm_type_e;  

    typedef enum logic [1:0]    {
        WPL_IDLE=0, BEAT_ONE=1, BEAT_TWO=2
    } wpl_sm_type_e;   

    typedef enum logic [2:0]    {
        INT_IDLE=0, WRB_SEND_MSIX=1, H2C_SEND_MSIX=2, DYN_PROCESS=3, REG_CTXT_RAM_RD=4, REG_CTXT_RAM_RD_BACK=5, REG_CTXT_RAM_WR=6 
    } int_sm_type_e;

    typedef enum logic [4:0]    {
        INT_COAL_IDLE=0, RAM_RD=1, RAM_RDATA_BACK=2, RAM_WR=3, WRQ_OUT=4, WPL_FIFO=5, WAIT_WCP=6, SEND_MSIX=7, REG_RAM_RD=8, REG_RAM_RDATA_BACK=9, DYN_RAM_RD=10, DYN_RAM_RDATA_BACK=11, DYN_RAM_WR=12, DYN_WAIT_WCP=13, DYN_SEND_MSIX=14, AXI_WRQ_OUT=15, AXI_WPL_FIFO=16, AXI_WAIT_WCP=17   
    } int_coal_sm_type_e;

    typedef enum logic [0:0]    {
       MARKER_SM_IDLE=0, MARKER_SM_WAIT=1
    } marker_sm_type_e;   

    typedef struct packed {
        logic       reg_ctxt_wr;
        logic       reg_ctxt_rd;
        logic       dyn;
        logic       h2c;
        logic       wrb;
    } mdma_c2h_int_req_t;

    typedef struct packed {
        logic                    axi;
        mdma_host_id_t           host_id;      
        mdma_qidx_t              sw_cidx;
        mdma_int_vec_id_coal_t   ring_idx;
    } mdma_dyn_req_t;

    localparam TIMER_BITS   = 9;

    typedef struct packed {
        mdma_dir_e                  dir;
        logic                       vio;
        mdma_cqid_t                 qid;
        logic [TIMER_BITS-1:0]      timer_inj;
    } mdma_timer_fifo_dat_t;

    localparam  TIMER_FIFO_RAM_NUM        = 4;
    localparam  TIMER_FIFO_TOTAL_DEPTH    = 2048;
    localparam  TIMER_FIFO_DEPTH          = TIMER_FIFO_TOTAL_DEPTH/TIMER_FIFO_RAM_NUM;
    localparam  TIMER_FIFO_ADDR_BITS      = $clog2(TIMER_FIFO_DEPTH);
    localparam  TIMER_FIFO_BITS           = $bits(mdma_timer_fifo_dat_t);
    localparam  TIMER_TOTAL_FIFO_CNT_BITS = $clog2(TIMER_FIFO_TOTAL_DEPTH+1);
    localparam  TIMER_FIFO_CNT_BITS       = $clog2(TIMER_FIFO_DEPTH+1);

    localparam  FIFO_CNT_BITS     = 11;
    localparam  WRB_FIFO_CNT_BITS = 3;
    localparam  WRQ_FIFO_CNT_BITS = 5;

    typedef struct packed {
        logic                                          virt_ch;
        mdma_dma_wrb_data_t                            wrb_data;
        mdma_c2h_wrb_user_t                            wrb_user;
    } mdma_tuser_in_fifo_data_t;

    // Tuser Input FIFO
    localparam  TUSER_IN_FIFO_DEPTH           = 32;
    localparam  TUSER_IN_FIFO_ADDR_BITS       = $clog2(TUSER_IN_FIFO_DEPTH);
    localparam  TUSER_IN_FIFO_UPF             = 1;
    localparam  TUSER_IN_FIFO_DNF             = 1;
    localparam  TUSER_IN_FIFO_SB_BITS         = 1;
    localparam  TUSER_IN_FIFO_DNF_LOG         = TUSER_IN_FIFO_DNF > 1 ? $clog2(TUSER_IN_FIFO_DNF+1) : 1;
    localparam  TUSER_IN_FIFO_IN_BITS         = $bits(mdma_tuser_in_fifo_data_t);
    localparam  TUSER_IN_FIFO_OUT_BITS        = TUSER_IN_FIFO_IN_BITS;
    localparam  TUSER_IN_FIFO_LOG_OUT_BITS    = TUSER_IN_FIFO_DNF>1 ? TUSER_IN_FIFO_OUT_BITS : TUSER_IN_FIFO_IN_BITS;
    localparam  TUSER_IN_FIFO_CNT_BITS        = $clog2(TUSER_IN_FIFO_DEPTH+1);

    // Desc Rsp FIFO
    localparam  DESC_RSP_FIFO_CNT_BITS        = 2;

    // Wcp FIFO
    localparam  WCP_FIFO_CNT_BITS             = 7;

    typedef struct packed {
        logic                                 eop;
        logic [2:0]                           port_id;
        mdma_qid_t                            qid;
        mdma_dma_buf_len_t                    buf_len;
        mdma_c2h_avl_idx_t                    avl_idx;
        logic                                 error;
        logic                                 drop;
    } mdma_pld_st_fifo_data_t;

    // Payload Status FIFO
    localparam  PLD_ST_FIFO_CNT_BITS          = 7;

    // Debug status registers
    typedef struct packed {
        logic                               s_axis_c2h_tvalid;
        logic                               s_axis_c2h_tready;
        logic [2:0]                         s_axis_wrb_tvalid;
        logic [2:0]                         s_axis_wrb_tready;
        logic                               payload_fifo_in_rdy;
        logic                               qid_fifo_in_rdy;
        logic                               arb_fifo_out_vld;
        mdma_qid_t                          arb_fifo_out_data_qid;
        logic                               wrb_fifo_in_rdy;
        logic [WRB_FIFO_CNT_BITS-1:0]       wrb_fifo_out_cnt;    
        wrb_sm_type_e                       wrb_sm_cs;           
        dma_eng_sm_type_e                   main_sm_cs;          
    } mdma_stat_c2h_debug_dma_eng_0_t; 

    typedef struct packed {
        logic [2:0]                         rsvd;
        logic [FIFO_CNT_BITS-1:0]           qid_fifo_out_cnt;    
        logic [FIFO_CNT_BITS-1:0]           payload_fifo_out_cnt;
        logic [PLD_ST_FIFO_CNT_BITS-1:0]    pld_st_fifo_cnt;
    } mdma_stat_c2h_debug_dma_eng_1_t;

    typedef struct packed {
        logic [2:0]                         rsvd;
        logic [FIFO_CNT_BITS-1:0]           qid_fifo_out_cnt_1;    
        logic [FIFO_CNT_BITS-1:0]           payload_fifo_out_cnt_1;
        logic [PLD_ST_FIFO_CNT_BITS-1:0]    pld_st_fifo_cnt_1;
    } mdma_stat_c2h_debug_dma_eng_2_t; 

    typedef struct packed {
        logic [7:0]                         rsvd;
        logic [WRQ_FIFO_CNT_BITS-1:0]       wrq_fifo_out_cnt;    
        logic                               qid_fifo_out_vld;
        logic                               payload_fifo_out_vld;
        logic                               pld_st_fifo_out_vld;
        logic                               pld_st_fifo_out_data_eop;
        logic                               pld_st_fifo_out_data_avl_idx_enable;
        logic                               pld_st_fifo_out_data_drop;
        logic                               pld_st_fifo_out_data_error;
        logic                               desc_cnt_fifo_in_rdy;
        logic                               desc_rsp_fifo_in_rdy;
        logic                               pld_pkt_id_larger;
        logic                               wrq_vld;
        logic                               wrq_rdy;
        logic                               wrq_fifo_out_rdy;
        logic                               wrq_fifo_out_data_drop;
        logic                               wrq_fifo_out_data_error;
        logic                               wrq_fifo_out_data_marker;
        logic                               wrq_fifo_out_data_eor;
        logic                               wcp_fifo_in_rdy;
        logic                               pld_st_fifo_in_rdy;
    } mdma_stat_c2h_debug_dma_eng_3_t;

    typedef struct packed {
        logic [7:0]                         rsvd;
        logic [WRQ_FIFO_CNT_BITS-1:0]       wrq_fifo_out_cnt_1;    
        logic                               qid_fifo_out_vld_1;
        logic                               payload_fifo_out_vld_1;
        logic                               pld_st_fifo_out_vld_1;
        logic                               pld_st_fifo_out_data_eop_1;
        logic                               pld_st_fifo_out_data_avl_idx_enable_1;
        logic                               pld_st_fifo_out_data_drop_1;
        logic                               pld_st_fifo_out_data_error_1;
        logic                               desc_cnt_fifo_in_rdy_1;
        logic                               desc_rsp_fifo_in_rdy_1;
        logic                               pld_pkt_id_larger_1;
        logic                               wrq_vld_1;
        logic                               wrq_rdy_1;
        logic                               wrq_fifo_out_rdy_1;
        logic                               wrq_fifo_out_data_drop_1;
        logic                               wrq_fifo_out_data_error_1;
        logic                               wrq_fifo_out_data_marker_1;
        logic                               wrq_fifo_out_data_eor_1;
        logic                               wcp_fifo_in_rdy_1;
        logic                               pld_st_fifo_in_rdy_1;
    } mdma_stat_c2h_debug_dma_eng_4_t;

    typedef struct packed {
        logic [31-30:0]                     rsvd;  
        logic                               wrb_sm_virt_ch;
        mdma_wrb_fifo_in_req_t              wrb_fifo_in_req;
        logic [1:0]                         arb_fifo_out_cnt;
        mdma_dma_buf_len_t                  arb_fifo_out_data_len;
        logic                               arb_fifo_out_virt_ch;
        logic                               arb_fifo_out_data_var_desc;
        logic                               arb_fifo_out_data_drop_req;
        logic                               arb_fifo_out_data_num_buf_ov;
        logic                               arb_fifo_out_data_marker;
        logic                               arb_fifo_out_data_has_cmpt;
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
        logic [19:0]                rsvd;
        logic                       s_axis_c2h_tvalid;
        logic                       s_axis_c2h_tready;
        logic                       s_axis_c2h_tlast; 
        logic [5:0]                 s_axis_c2h_mty;   
        mdma_c2h_axis_ctrl_t        s_axis_c2h_ctrl;  
        logic [7:0]                 s_axis_c2h_data;  
        dma_eng_sm_type_e           main_sm_cs;
        wrb_sm_type_e               wrb_sm_cs;
        logic                       arb_fifo_out_dat_qid;
        logic                       arb_fifo_out_dat_len;
        logic                       arb_fifo_out_dat_marker;
        logic                       arb_fifo_out_dat_has_cmpt;
        logic                       arb_fifo_out_dat_num_buf_ov;
        logic                       arb_fifo_out_dat_var_desc;
        logic                       arb_fifo_out_virt_ch;
        logic                       arb_fifo_out_vld;
        logic                       arb_fifo_out_rdy;
        logic [9:0]                 arb_fifo_out_cnt;
        logic                       payload_fifo_out_vld;
        logic [9:0]                 payload_fifo_out_cnt;
        logic                       payload_fifo_crdt_req_final_p1;
        logic [12:0]                payload_fifo_crdt_cnt_final_p1;
        logic                       payload_fifo_crdt_req_drop;
        logic                       payload_fifo_crdt_req;
        logic                       desc_rsp_eng_vld;
        logic                       desc_rsp_eng_rdy;
        logic [7:0]                 desc_rsp_eng_addr;
        logic [15:0]                desc_rsp_eng_len;
        logic [10:0]                desc_rsp_eng_qid;
        logic                       desc_rsp_eng_drop;
        logic                       desc_rsp_eng_last;
        logic                       desc_rsp_eng_error;
        logic                       wrq_fifo_in_vld_drop;
        logic                       wrq_fifo_in_vld_error;
        logic                       wrq_fifo_in_vld_marker;
        logic                       wrb_fifo_in_vld;
        logic                       wrb_fifo_in_rdy;
        logic [2:0]                 wrb_fifo_out_cnt;
        logic                       wrq_fifo_in_vld_0;
        logic                       wrq_fifo_in_rdy_0;
        logic [2:0]                 wrq_fifo_out_cnt_0;
        logic                       wcp_fifo_in_vld_0;
        logic                       wcp_fifo_in_rdy_0;
        logic [2:0]                 wcp_fifo_out_cnt_0;
        logic                       wrq_packet_out_eor_0;
        logic                       wrq_vld_out_0;
        logic                       payload_fifo_crdt_req_0;
        logic                       wpl_vld_0;
        logic [7:0]                 wpl_data_0;
        logic                       wpl_ren_0;
        logic                       wpl_inc_0;
        logic                       wrq_vld_0;
        logic                       wrq_rdy_0;
        logic [18:0]                payload_fifo_credit_cnt_0;
        logic                       payload_fifo_crdt_gnt_0;
        logic                       pld_st_fifo_out_vld_0;
        logic                       pld_st_fifo_out_rdy_0;
        mdma_qid_t                  pld_st_fifo_out_data_qid_0;
        logic                       pld_st_fifo_out_data_eop_0; 
        logic                       pld_st_fifo_out_data_avl_idx_0; 
        logic                       pld_st_fifo_out_data_drop_0; 
        logic                       pld_st_fifo_out_data_error_0;
        logic                       pld_st_fifo_in_vld_0;
        logic                       pld_st_fifo_in_rdy_0;
        logic [6:0]                 pld_st_fifo_cnt_0;
   } mdma_c2h_debug_dma_wr_eng_t;

    typedef struct packed {
        logic [9:0]                rsvd;
        logic [15:0]                pld_pkt_id_0;
        logic [15:0]                pld_pkt_id_1;
        logic [15:0]                cmpt_wait_pld_pkt_id_0;
        logic [15:0]                cmpt_wait_pld_pkt_id_1;
        logic                       cmpt_non_block_0;
        logic                       cmpt_non_block_1;
        logic [2:0]                 s_axis_wrb_tvalid;
        logic [2:0]                 s_axis_wrb_tready;
        logic                       wrb_sm_virt_ch;
        logic [5:0]                 wrb_fifo_in_req;
        logic [5:0]                 wrb_fifo_in_gnt;
        logic                       wrb_vld;     
        logic                       wrb_rdy;     
        logic [10:0]                wrb_qid;     
        logic                       wrb_user_trig;
        logic                       wrb_marker; 
        logic                       stat_total_wrq_len_match_0; 
        mdma_stat_t                 stat_total_wrq_len_0; 
        mdma_stat_t                 stat_total_wpl_val_out_len_0;
        logic                       stat_total_wrq_len_match_1; 
        mdma_stat_t                 stat_total_wrq_len_1; 
        mdma_stat_t                 stat_total_wpl_val_out_len_1;
        logic                       wrq_fifo_in_vld_1;
        logic                       wrq_fifo_in_rdy_1;
        logic [2:0]                 wrq_fifo_out_cnt_1;
        logic                       wcp_fifo_in_vld_1;
        logic                       wcp_fifo_in_rdy_1;
        logic [2:0]                 wcp_fifo_out_cnt_1;
        logic                       wrq_packet_out_eor_1;
        logic                       wrq_vld_out_1;
        logic                       wpl_vld_1;
        logic [7:0]                 wpl_data_1;
        logic                       wpl_ren_1;
        logic                       wpl_inc_1;
        logic                       wrq_vld_1;
        logic                       wrq_rdy_1;
        logic [18:0]                payload_fifo_credit_cnt_1;
        logic                       payload_fifo_crdt_gnt_1;
        logic                       pld_st_fifo_out_vld_1;
        logic                       pld_st_fifo_out_rdy_1;
        mdma_qid_t                  pld_st_fifo_out_data_qid_1;
        logic                       pld_st_fifo_out_data_eop_1; 
        logic                       pld_st_fifo_out_data_avl_idx_1; 
        logic                       pld_st_fifo_out_data_drop_1; 
        logic                       pld_st_fifo_out_data_error_1;
        logic                       pld_st_fifo_in_vld_1;
        logic                       pld_st_fifo_in_rdy_1;
        logic [6:0]                 pld_st_fifo_cnt_1;
    } mdma_c2h_debug_dma_wr_eng_2_t;

    typedef struct packed {
        logic [50:0]                                            rsv;
        logic                                                   evt_vld;
        logic [$clog2(MDMA_PFCH_CACHE_MAX_DEPTH)-1:0]           evt_tag;
        mdma_qid_t                                              evt_qid;
        logic                                                   evt_rdy;

        logic [$clog2(MDMA_PFCH_CACHE_MAX_DEPTH)-1:0]           pfch_qcnt;

        logic                                                   qid_ram_wen;
        mdma_qid_t                                              qid_ram_wdat;
        logic [$clog2(MDMA_PFCH_CACHE_MAX_DEPTH)-1:0]           qid_ram_wadr;
        logic                                                   qid_ram_ren;
        mdma_qid_t                                              qid_ram_rdat;
        logic [$clog2(MDMA_PFCH_CACHE_MAX_DEPTH)-1:0]           qid_ram_radr;

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
        mdma_c2h_cache_tag_t        ll_out_deq_tag;
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
        logic [255-4-11-8-11-8-11-6-8-16:0]    rsvd;                   
        logic [1:0]                 alloc_st;
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
        mdma_qid_t                                  cam_wr_key;
        logic                                       cam_wr_vld;
        mdma_c2h_cache_tag_t                        cam_wr_ix;

        logic                                       cam_del_vld;
        mdma_c2h_cache_tag_t                        cam_del_ix ;
        
        mdma_qid_t                                  dsc_cmp_qid;
        logic                                       dsc_cmp_err;
        logic                                       dsc_cmp_last;
        logic [1:0]                                 dsc_cmp_atc;
        logic[63:0]                                 dsc_cmp_dsc;
        mdma_qidx_t                                 dsc_cmp_cidx;
        logic                                       dsc_cmp_vld;
        logic                                       dsc_cmp_rdy;

        logic                                       desc_rsp_vld;
        mdma_fnid_t                                 desc_rsp_func;
        logic                                       desc_rsp_error;
        logic                                       desc_rsp_last;
        logic                                       desc_rsp_drop;
        logic [1:0]                                 desc_rsp_at;
        mdma_dma_buf_addr_t                         desc_rsp_addr;
        mdma_dma_buf_len_t                          desc_rsp_len;
        mdma_qid_t                                  desc_rsp_qid;
        logic                                       desc_rsp_rdy;

        logic [$clog2(MDMA_PFCH_CACHE_MAX_DEPTH+1)-1:0] cam_cnt;

        logic [$clog2(WR_ENG_FIFO_DEPTH):0]         fl_free_cnt;

    } mdma_c2h_pfch_cache_debug_t;

typedef struct packed {
    logic                       vio_dsc_crdt;  // If qinv, 1 means virtio dsc negative credits.  0 means virtio avail entry or regular dsc credit.  N/a if qinv == 0
    mdma_qidx_t                 pidx;
    logic                       vio_en;
    logic                       vio_sw_db; // Used for VirtIO only. Set when the tm_sts is due to a SW initiated write to PIDX register
    logic                       vio_hw_db; // Used for VirtIO only. Set when the tm_sts is due to a HW initiated write to PIDX register
    logic                       vio_avl_flg; // Used for VirtIO only. Contains avail.flags field
    mdma_fnid_t                 fnid;
    logic                       vld;
    logic                       qen;        
    logic   [2:0]               port_id;
    logic                       err;
    logic                       byp;
    logic                       dir;
    logic                       mm;
    logic    [`QID_WIDTH-1:0]   qid;
    logic    [15:0]             avl;
    logic                       qinv;       //  queue enable status.  1 : avl hold leftover credits, 0: avl hold available descriptors
                                            //  queue enable was 1 but is now 0.  queue was invalidated
    logic                       irq_arm;    //  irq arm bit became set (not current state)
} tm_dsc_sts_t;

// This ext struct has 13b QID. This is used only in the fab_demux.
typedef struct packed {
    logic                       vio_dsc_crdt;  // If qinv, 1 means virtio dsc negative credits.  0 means virtio avail entry or regular dsc credit.  N/a if qinv == 0
    mdma_qidx_t                 pidx;
    logic                       vio_en;
    logic                       vio_sw_db; // Used for VirtIO only. Set when the tm_sts is due to a SW initiated write to PIDX register
    logic                       vio_hw_db; // Used for VirtIO only. Set when the tm_sts is due to a HW initiated write to PIDX register
    logic                       vio_avl_flg; // Used for VirtIO only. Contains avail.flags field
    mdma_fnid_t                 fnid;
    logic                       vld;
    logic                       qen;        
    logic   [2:0]               port_id;
    logic                       err;
    logic                       byp;
    logic                       dir;
    logic                       mm;
    mdma_qid_max_t              qid;
    logic    [15:0]             avl;
    logic                       qinv;       //  queue enable status.  1 : avl hold leftover credits, 0: avl hold available descriptors
                                            //  queue enable was 1 but is now 0.  queue was invalidated
    logic                       irq_arm;    //  irq arm bit became set (not current state)
} tm_dsc_sts_ext_t;

typedef struct packed {
    logic [3:0]                 ring_sz_idx;  
    tm_dsc_sts_t                tm_sts;
} new_tm_dsc_sts_t;

localparam MDMA_TM_DSC_STS_BITS=$bits(tm_dsc_sts_t);

    typedef struct packed {
        logic [41:0]                                             rsvd;
// FIXME add back in credits
        //logic                                                    dsc_crdt_vld;
        //logic                                                    dsc_crdt_rdy;
        //mdma_dsc_eng_crdt_t                                      dsc_crdt;

        //logic [MDMA_TM_DSC_STS_BITS-1:0]                         tm_sts_in;
        //logic                                                    tm_sts_in_rdy;

        logic [MDMA_TM_DSC_STS_BITS-1:0]                         tm_sts_out;
        logic                                                    tm_sts_out_rdy;

        // FIXME, add back
        //logic                                                    dsc_err_vld;
        //logic                                                    dsc_err_rdy;
        //mdma_qid_t                                               dsc_err_qid;

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
        logic                                           rsvd;
        logic                                           dyn_msi_int_vld;
        logic                                           wrb_send_msix_no_msix;
        logic                                           wrb_send_msix_ctxt_inval;
        logic                                           wrb_send_msix_ack;
        logic                                           wrb_send_msix_fail;
        mdma_c2h_int_req_t                              int_event_req;
        mdma_c2h_int_req_t                              int_event_gnt;
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
//        logic [7:0]                                     int_wrq_packet_fnc;
//        logic [7:0]                                     int_wrq_packet_rid;
        logic                                           int_wpl_ren;
        logic                                           int_wpl_vld;
        logic                                           int_wcp_vld;
//        logic [7:0]                                     int_wcp_cpl_rid;
        logic                                           int_wcp_cpl_err;
        int_sm_type_e                                   sm_cs;
        logic                                           wrb_int_entry_en_coal;
        logic                                           h2c_int_entry_en_coal;
        logic                                           err_int_entry_en_coal;
   } mdma_c2h_debug_interrupt_t;  

   // FIXME: 2 bits (wrb_timer_vld and timer_exp_vld) commented to make room for wider qid.
    typedef struct packed {
        logic [25:0]                                                   rsvd;
        logic                                                          wrb_timer_rdy;
        mdma_c2h_wrb2timer_t                                           wrb_timer_req;
        //logic                                                          timer_exp_vld;
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
        logic [TIMER_FIFO_RAM_NUM-1:0]                                 timer_fifo_in_vld;
        mdma_timer_fifo_dat_t [TIMER_FIFO_RAM_NUM-1:0]                 timer_fifo_in_data;
        logic [TIMER_FIFO_RAM_NUM-1:0]                                 timer_fifo_out_vld;
        logic [TIMER_FIFO_RAM_NUM-1:0]                                 timer_fifo_out_rdy;
        logic [TIMER_FIFO_RAM_NUM-1:0]                                 timer_fifo_exp_accepted;
   } mdma_c2h_debug_timer_1_t;  

    typedef struct packed {
         logic [TIMER_FIFO_RAM_NUM-1:0]                                 fifo_wrap_vld;
         mdma_timer_fifo_dat_t [TIMER_FIFO_RAM_NUM-1:0]                 timer_fifo_out_dat;
         logic [TIMER_FIFO_RAM_NUM-1:0] [TIMER_FIFO_CNT_BITS-1:0]       timer_fifo_out_cnt;
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
    localparam PFCH_LL_RAM_DATA_BITS    = $bits(mdma_c2h_pfch_ll_t);
    localparam PFCH_LL_RAM_DEPTH        = 2048;
    localparam PFCH_LL_RAM_ADDR_BITS    = $clog2(PFCH_LL_RAM_DEPTH);
    localparam PFCH_LL_RAM_RDT_FFOUT    = 1;

    //typedef union packed {
    //    mdma_wrb_ctxt_t     wrb;
    //    logic [127:0]       chk;
    //} mdma_wrb_ctxt_chk_t;

    // WRB context RAM
    //localparam PASID_CTXT_RAM_DATA_BITS    = 32;
    //localparam PASID_CTXT_RAM_DEPTH        = 1<<$bits(mdma_qid_t);
    //localparam PASID_CTXT_RAM_ADDR_BITS    = $clog2(WRB_CTXT_RAM_DEPTH);
    //localparam PASID_CTXT_RAM_RDT_FFOUT    = 1;
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
        //mdma_qidx_t                 mod_cidx; // CTXT.CIDX % rng_sz. Used for VIO
        //mdma_qidx_t                 adj_used_idx; // Adjuested value of CTXT.CIDX to be written via STD
        mdma_wrb_ctxt_t             orig;
        mdma_dma_buf_addr_t         desc_addr;
        //mdma_dma_buf_addr_t         stat_addr;
        mdma_byte_qidx_t            std_byte_ofst;
        logic                       pidx_rap; //Wrap around
        logic [6:0]                 desc_bsize; //wrb descriptor byte size
    } mdma_wrb_dec_ctxt_t;

    // WRB Debug signals
    typedef struct packed {
        logic [82:0]                    rsv;
        logic                           pstg_wr_vld;
        mdma_cqid_t                     mgr_ctxt_wr_qid;
        mdma_c2h_wrb_inrra_rq_t         in_rra_gnt_wr;
        mdma_ind_ctxt_cmd_e             ctxt_rq_wr_op;
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
        logic                           st_out_inv_timer;
        logic                           allow_wrb;
        logic                           allow_std;
        logic                           allow_int;
        logic                           allow_tmr;
        logic                           allow_bypo;
        logic                           wrb_mux_rdy;
        logic                           wrb_mux_vld_rd;
        wrb_rd_sm_e                     rd_st;
        logic                           sm_wrb_vld;
        logic                           sm_wrb_real;
        logic                           sm_std_vld;
        logic                           sm_std_real;
        logic                           sm_int_vld;
        logic                           sm_int_real;
        logic                           sm_tmr_vld;
        logic                           sm_tmr_real;
        logic                           sm_bypo_vld;
        logic                           sm_std_ctxt_drp;
        logic                           wrb_dma_fifo_vld;
        logic                           wrb_std_fifo_vld;
        logic                           wrb_int_fifo_vld;
        logic                           wrb_tmr_fifo_vld;
        logic                           wrb_byp_out_vld;
    } mdma_c2h_debug_wrb_t; 



    // ----------------------------------------------------
    // WRB Marker Response and VIO Timer Expiry (on byp_out) structs
    // ----------------------------------------------------
    localparam WRB_COOKIE_WIDTH = 24;
    typedef struct packed {
        logic [4:0]                     rsv; // Going with a soft limit of 32 right now.
        logic [WRB_COOKIE_WIDTH-1:0]    cookie;
        logic                           retry_mrkr_req;
        mdma_wrb_err_e                  err;
    } wrb_mrkr_rsp_stat_t;

    typedef struct packed {
        wrb_mrkr_rsp_stat_t     wrb_stat;
        mdma_pasid_t            pasid;
        mdma_host_id_t          host_id;
        logic [2:0]             fmt;
        logic [2:0]             port_id;
        logic                   sel;
        mdma_fnid_t             fnc;
        mdma_cqid_t             qid;
    } wrb_byp_out_data_t;
    // ----------------------------------------------------



    //Avail-ring FIFO parameters
    localparam AVL_RING_CRDT_FIFO_WIDTH       = $bits(mdma_dsc_eng_imm_crdt_t) < 64 ? 64 : -1;
    localparam AVL_RING_CRDT_FIFO_DEPTH       = 512;
    localparam AVL_RING_CRDT_FIFO_ADDR_BITS   = $clog2(AVL_RING_CRDT_FIFO_DEPTH);
    localparam AVL_RING_DSC_CRDT_THROTTLE_THRESHOLD = AVL_RING_CRDT_FIFO_DEPTH - 64;

    //------------------------------------------------------------------------------------------------------------------
    // cmpt
    //------------------------------------------------------------------------------------------------------------------
    typedef struct packed {
        logic                       is_rx_vio_msg;
        logic                       no_wrb_marker;
        logic                       eop;
        mdma_dma_wrb_data_t         usr_data;
        logic                       desc_err;
        logic [2:0]                 color_idx;
        logic [2:0]                 desc_err_idx;
        logic                       mrkr;
        logic                       usr_trig;
        logic [2:0]                 port_id;
        mdma_cqid_t                 qid;
    } mdma_c2h_wrb_wrbif_t;

    typedef struct packed {
        logic [8:0]                loc6;
        logic [8:0]                loc5;
        logic [8:0]                loc4;
        logic [8:0]                loc3;
        logic [8:0]                loc2;
        logic [8:0]                loc1;
        logic [8:0]                loc0;
    } mdma_c2h_wrb_field_loc_t;

    //This struct defines the format of the register that SW reads to look up the color/error location in the WRB entry
    typedef struct packed {
        logic [15:0]        error_loc;
        logic [15:0]        color_loc;
    } mdma_c2h_wrb_format_reg_t;

    // VIO CMPT structs
    // B0->B15: CMPT, if present
    // B16->B23: CTRL
    // B24->b63: RESERVED
    typedef logic [127:0]       vio_wrb_data_t;
    typedef struct packed {
        logic [55:0]    rsv;
        logic           noe;
        logic           dis_not;
        logic           en_not;
        logic           int_sup;
        logic           int_allow;
        logic           sw_db;
        logic           hw_db;
        logic           msg_vld;
    } vio_wrb_ctrl_t;
    //------------------------------------------------------------------------------------------------------------------


    //------------------------------------------------------------------------------------------------------------------
    // h2c-st
    //------------------------------------------------------------------------------------------------------------------
    localparam PEND_FIFO_WIDTH      =   6                           +   /*addr*/
                                        32                          +   /*mdata*/
                                        $bits(mdma_dma_buf_len_t)   +   /*len*/
                                        $bits(mdma_qid_max_t)       +   /*qid*/
                                        16                          +   /*cidx*/
                                        $bits(mdma_fnid_t)          +   /*fnid*/
                                        1                           +   /*wbi*/
                                        1                           +   /*wbi_chk*/
                                        1                           +   /*eod*/
                                        1                           +   /*sop*/
                                        1                           +   /*eop*/
                                        1                           +   /*err*/
                                        3                           +   /*port_id*/
                                        1                           +   /*no_dma*/
                                        1                           +   /*byp*/
                                        1                           +   /*vch_id*/
                                        $bits(mdma_pasid_val_t)     +   /*pasid*/
                                        1;                              /*pasid_en*/
    //localparam PEND_FIFO_DEPTH = 512;
    localparam PEND_FIFO_RAM_RDT_FFOUT = 1;
    //NOTE: wbc and eop fields of the following structs are hard-coded in:
    //      //IP3/DEV/hw/pcie_gen4/rtl_ev/pciea_dma/rtl/dma_pcie_mdma_fab_demux.sv
    typedef struct packed {
        //logic [57:0]                                    rsv;
        logic [6:0]                                     ecc;
        logic                                           vch_id;     //[71]
        logic                                           zero_b_dma; //[70]
        logic [2:0]                                     port_id;    //[69:67]
        logic [31:0]                                    mdata;      //[66:35]
        logic [7:0]                                     err;        //[34:27]
        logic                                           wbc;        //[26]
        logic [$clog2($bits(mdma_int_tdata_t)/8)-1:0]   meb;        //[25:20]
        logic [$clog2($bits(mdma_int_tdata_t)/8)-1:0]   leb;        //[19:14]
        logic                                           eop;        //[13]
        logic                                           sop;        //[12]
        mdma_qid_max_t                                  qid;        //[11:0]
    } mdma_h2c_axis_unal_tuser_t;

    typedef struct packed {
        //logic                                           rsv;//added rsv bit to round the size to match hdr size of 64b
        logic [6:0]                                     ecc;
        logic                                           zero_b;
        logic [5:0]                                     mty;
        logic [31:0]                                    mdata;
        logic                                           err;
        logic [2:0]                                     port_id;
        logic                                           wbc;
        mdma_qid_max_t                                  qid;
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
        logic           req_throt_en_req;   // [31]
        logic [11:0]    req_thresh;         // [30:19]
        logic           req_throt_en_data;  // [18]
        logic [17:0]    data_thresh;        // [17:0]
    } mdma_h2c_req_throt_reg_t;

    //H2C-ST Core debug registers
    typedef struct packed {
        logic [15:0]                    num_dsc_rcvd;
        logic [15:0]                    num_wrb_sent;
    } mdma_h2c_core_dbg_reg32_0_t;

    typedef struct packed {
        logic [15:0]                    num_req_sent;
        logic [15:0]                    num_cmp_rcvd;
    } mdma_h2c_core_dbg_reg32_1_t;

    typedef struct packed {
        logic [15:0]                    rsv;
        logic [15:0]                    num_err_dsc_rcvd;
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

    //H2C aligner debug registers
    typedef struct packed {
        logic [15:0]                    rsv;
        logic [15:0]                    num_pkt_sent;
    } mdma_h2c_aln_dbg_reg32_0_t;

    typedef struct packed {
        mdma_h2c_aln_dbg_reg32_0_t      reg_0;
    } mdma_h2c_aln_dbg_reg_t;
    //------------------------------------------------------------------------------------------------------------------



    typedef enum logic [7:0]    {
        TRQ_SRC = 1, WBC_SRC = 2, CRD_SRC= 4, IND_SRC= 8, EVT_SRC = 16, IMM_SRC= 32, RCP_SRC= 64, FEN_SRC= 128 
    } dsc_ctxt_src_e;

    typedef enum logic [2:0]    {
        TRQ_SRC_ENC = 0, WBC_SRC_ENC = 1, CRD_SRC_ENC= 2, IND_SRC_ENC = 3, EVT_SRC_ENC = 4, IMM_SRC_ENC = 5, RCP_SRC_ENC = 6 , FEN_SRC_ENC = 7
    } dsc_ctxt_src_enc_e;

    typedef enum logic [1:0]{
        MDMA_DSC_MISC_EVT = 0,
        MDMA_DSC_RCP_EVT =  1,
        MDMA_DSC_IMM_EVT = 2,
        MDMA_DSC_VIO_IDX_RCP_EVT =  3
    } mdma_dsc_evt_e;

    typedef struct packed {
        //mdma_dsc_evt_e          rcp;
        dsc_ctxt_src_e          src;
        logic                   sel;
        mdma_qid_t              qid;
    } dsc_ctxt_info_t;


    typedef struct packed {
        logic   [25:0]         rsv;
    } dsc_rsv_ctxt_dat_t;

    typedef struct packed {
        logic                  sw_db;
        logic                  hw_db;
        logic   [4:0]          errc;
        logic                  vio_idx;
        logic                  avl_flg;
        logic                  pnd_sub;
        logic  [15:0]          idx;
    } dsc_rcp_ctxt_dat_t;

    typedef struct packed {
        logic   [23:0]          rsv;
        logic   [1:0]           err;
    } dsc_wbc_ctxt_dat_t;

    typedef struct packed {
        logic  [6:0]            rsv;
        mdma_dsc_eng_crdt_op_e  cmd;   // 3 bits
        logic  [15:0]           crd;
    } dsc_crd_ctxt_dat_t;

    typedef union packed {
        dsc_rsv_ctxt_dat_t      rsv;
        dsc_rcp_ctxt_dat_t      rcp;
        dsc_crd_ctxt_dat_t      crd;
        dsc_wbc_ctxt_dat_t      wbc;
    } dsc_ctxt_req_dat_t;



    // ----------------------------------------------------------------
    // STS OUT port
    // ----------------------------------------------------------------
    typedef enum logic [7:0] {
        CMPT_MRKR_RSP=0, H2C_ST_MRKR_RSP=1, C2H_MM_MRKR_RSP=2, H2C_MM_MRKR_RSP=3
    } mdma_sts_out_op_e;

    typedef struct packed {
        logic [31:0]            rsv;
        wrb_mrkr_rsp_stat_t     wrb_stat;
    } mdma_cmpt_mrkr_data_t;

    typedef struct packed {
        logic [46:0]  rsv;
        logic         err;
        logic [15:0]  cidx;
    }  mdma_mm_h2c_st_mrkr_data_t;

    typedef union packed {
        mdma_cmpt_mrkr_data_t      cmpt_mrkr_data;
        mdma_mm_h2c_st_mrkr_data_t mm_h2c_st_mrkr_data;
    } mdma_sts_out_data_u;

    typedef struct packed {
        logic                   rsv2;
        mdma_sts_out_op_e       op;
        mdma_sts_out_data_u     data;
        logic [2:0]             port_id;
        logic [10:0]            rsv;        // These will be part of qid if it becomes 24b
        mdma_qid_max_t          qid;
    } mdma_sts_out_t;
    // ----------------------------------------------------------------


`endif



