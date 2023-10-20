`ifndef CPM5_DMA_DEFINES_SVH
`define CPM5_DMA_DEFINES_SVH

`define DMA_FABRIC_OUT_WIDTH   1950
`define DMA_FABRIC_IN_WIDTH    2700
`define SHRD_FABRIC_OUT_WIDTH  2000

// Interface Includes at bottom of file (use some structures defined in this file)
typedef enum logic [2:0] {DMA_DSC_OUT_8B=0, DMA_DSC_OUT_16B=1, DMA_DSC_OUT_32B=2, DMA_DSC_OUT_64B=3, DMA_DSC_OUT_2B=4} dma_dsc_out_size_e;
typedef enum logic       {DMA_VIO_AVL_RNG_FETCH=0, DMA_VIO_AVL_IDX_FETCH=1} dma_dsc_vio_fetch_e;

`define IF_MI_CONVERSION_M \
    always_comb begin \
        ifc.wadr = wadr;\
        ifc.wen  = wen;\
        ifc.wpar = wpar;\
        ifc.wdat = wdat;\
        ifc.ren  = ren;\
        ifc.radr = radr;\
       rpar = ifc.rpar;\
       rdat = ifc.rdat;\
       rsbe = ifc.rsbe;\
       rdbe = ifc.rdbe;\
    end

`define IF_MI_CONVERSION_S \
    always_comb begin \
        wadr = ifc.wadr;\
        wen  = ifc.wen;\
        wpar = ifc.wpar;\
        wdat = ifc.wdat;\
        ren  = ifc.ren;\
        radr = ifc.radr;\
        ifc.rpar = rpar;\
        ifc.rdat = rdat;\
        ifc.rsbe = rsbe;\
        ifc.rdbe = rdbe;\
    end

// Spare Input Ports for DMA5 from dma5_pciea to dma5_wrapper
typedef struct packed {
    logic [511:0]          rsv;    // Allocate bits from here
} spare_input_t;

typedef union packed {
    logic [511:0]          rsv;    // For compile size check
    spare_input_t          spare; 
} dma5_wrapper_spare_input_t;

// Spare Output Ports for DMA5 to dma5_pciea from dma5_wrapper
typedef struct packed {
    logic [511:0]          rsv;    // Allocate bits from here
} spare_output_t;

typedef union packed {
    logic [511:0]          rsv;    // For compile size check
    spare_output_t         spare; 
} dma5_wrapper_spare_output_t;



typedef struct packed {
    logic                  pasid_en;
    logic [21:0]           pasid;
    logic [1:0]            at;
    logic                  spl;
    logic                  err;    // request with error detected
    logic                  sec;    // AXI MM only
    logic [3:0]            host_id; // AXI MM only
    logic [`ADR_WIDTH-1:0] adr;
    logic [`RID_WIDTH-1:0] rid;
    logic [`LEN_WIDTH-1:0] byte_len;   // byte length
    logic [`DID_WIDTH-1:0] did;
    logic [15:0]           fnc;        // function/QID  Keep this in LSB
} rrq_t;

typedef struct packed {
    logic [1:0]            at;
    logic                  spl;
    logic                  err;    // request with error detected
    logic                  dbe;
    logic                  sec;    // AXI MM only
    logic [3:0]            chn;
    logic [3:0]            cache;  // AXI MM only
    logic [`ADR_WIDTH-1:0] adr;
    logic [`RID_WIDTH-1:0] rid;
    logic [`LEN_WIDTH-1:0] byte_len;   // byte length
    logic [`DID_WIDTH-1:0] did;
    logic [12:0]           fnc;        // function
    logic [21:0]           pasid;      // PASID + 2 mode bits
    logic                  pasid_en;   // PASID Enable
} rrq_pasid_t;

typedef struct packed {
    logic                  gen_sop;
    logic [`RID_WIDTH-1:0] rid;
    logic [`CHN_WIDTH-1:0] chn;
    logic [8:0]            btlen;   // beatlen
    logic [`DID_WIDTH-1:0] did;
    logic [4:0]            errc;
    logic [3:0]            err;
} rcp_err_t;

// Descriptor Sideband Info (Context RAM to DSC_CPLI_RAM)
typedef struct packed {
    logic [13:0]                misc;
    logic                       pasid_en;
    logic [21:0]                pasid;
    mdma_host_id_t              host_id;
    logic                       pack_byp_out;
    logic                       vio_idx; // It was a virtio idx fetch
    logic    [2:0]              fmt;
    logic                       virtio_en;
    logic                       byp;
    logic    [2:0]              port_id;
    logic                       is_mm;
    logic                       mm_chn;
    dma_dsc_out_size_e          dsc_sz;
    logic                       end_rng; // The last descriptor of this fetch is the end of the ring
    logic                       wbi_imm;  // Do writeback/interrupt on descriptor completion
    logic                       wbi_chk;  // Check status before writeback/interrupt
    logic                       qen;
    logic   [`QID_WIDTH-1:0]    qid;     // Q ID 
    mdma_fnid_t                 fnc;
    logic   [15:0]              cidx;
} dsc_sbi_t;  

typedef struct packed {
    logic            sop;
    logic            eop;
    logic            wbk;
    logic [4:0]      err; // XDMA mode only
    logic [4:0]      errc;// Encoded error
    //logic [`DAT_WIDTH/32-1:0] wen; // dword write enable
    logic [`RID_WIDTH-1:0]    rid;
    logic [`DID_WIDTH-1:0]    did;
    logic [5:0]               lba;    // Last beat length adjustment (AXI ST C2H)
    logic [`DAT_WIDTH/8-1:0]  par;
    logic [`DAT_WIDTH-1:0]    dat;
} rcp_t;

    typedef struct packed {
        logic           rsv3;
        logic [2:0]     attr;
        logic [2:0]     tc;
        logic           rsv2;
        logic [15:0]    arid;
        logic [ 7:0]    tag;
        logic [15:0]    rid;
        logic           rsv1;
        logic [10:0]    msg_dlen;
        logic           rsv0;
        logic           req_cmptd;
        logic           locked_rc;
        logic [12:0]    rem_bcnt;
        logic [3:0]     err;
        logic [11:0]    addr;
    } rcd_hdr_t;

    typedef struct packed {
        logic [31:0]        parity;
        logic               discontinue;
        logic [2:0]         eop_dptr1; // DW ptr
        logic               eop1;
        logic [2:0]         eop_dptr0; // DW ptr
        logic               eop0;
        logic               sop1;
        logic               sop0;
        logic [31:0]        byte_en;
    } pcie_axis_tuser256_t;

    typedef struct packed {
        logic [63:0]        parity;
        logic               discontinue;
        logic [3:0]         eop_dptr3;
        logic [3:0]         eop_dptr2;
        logic [3:0]         eop_dptr1;
        logic [3:0]         eop_dptr0;
        logic               eop3;
        logic               eop2;
        logic               eop1;
        logic               eop0;
        logic [1:0]         sop_ptr3;
        logic [1:0]         sop_ptr2;
        logic [1:0]         sop_ptr1;
        logic [1:0]         sop_ptr0;
        logic               sop3;
        logic               sop2;
        logic               sop1;
        logic               sop0;
        logic [63:0]        byte_en;
    } pcie_axis_tuser512_t;

    typedef struct packed {
        logic [3:0][7:0]    bcnt; // NOTE: 8b bcnt to allow easier shifting. 1 seg shift translates to 1*8b shift in bcnt if it is 8b.
        logic [3:0]         eop;
        logic [3:0]         sop;
        logic [15:0]        dw_vld;
    } pcie_axis_seg_tuser512_t;

typedef struct packed {
    logic                  pasid_en;
    logic [21:0]           pasid;       
    logic [3:0]            host_id;
    logic [1:0]            at;
    logic                  err;
    logic                  sec;    // AXI MM only
    logic [`ADR_WIDTH-1:0] adr;
    logic [`RID_WIDTH-1:0] rid;
    logic [`LEN_WIDTH-1:0] byte_len;   // byte length
    logic [5:0]            aln;        // Source alignment
    logic                  sop;
    logic                  eop;
    logic                  eod;
    logic                  eor;
    logic [23:0]           fnc;   // Function  Keep this in LSB
} wrq_t;

typedef struct packed {
    logic [1:0]            at;
    logic                  err;
    logic                  dbe;
    logic                  sec;    // AXI MM only
    logic [3:0]            cache;  // AXI MM only
    logic [3:0]            chn;
    logic [`ADR_WIDTH-1:0] adr;
    logic [`RID_WIDTH-1:0] rid;
    logic [`LEN_WIDTH-1:0] byte_len;   // byte length
    logic [5:0]            aln;        // Source alignment
    logic                  sop;
    logic                  eop;
    logic                  eod;
    logic                  eor;
    logic [12:0]           fnc;    
    logic [21:0]           pasid;
    logic                  pasid_en;
} wrq_pasid_t;

typedef struct packed {
    logic                         dbe;  // RAM dbe error detected
    logic    [`DAT_WIDTH/8-1:0]   par;
    logic    [`DAT_WIDTH-1:0]     dat;
} wpl_t;

typedef struct packed {
    logic    [`RID_WIDTH-1:0]  rid;
    logic    [4:0]             err;
} wcp_t;

typedef struct packed {
    logic [31:0]    dat;
} wbrq_t;

typedef enum logic [1:0]{
   TRQ_PCIE = 0,
   TRQ_AXI  =  1,
   TRQ_MGMT = 2
} trq_src_e;

typedef struct packed {
    mdma_dmap_sel_e  sel;
    trq_src_e        src;
    logic [3:0]      be;    
    logic            rd;
    logic            wr;
    logic [31:0]     adr;
    logic [31:0]     dat;
    mdma_fnid_t      func;
    logic [3:0]      port_id;
} trq_t;

typedef struct packed {
    logic            vld;
    logic [31:0]     dat;
} tcp_t;

typedef struct packed {
    trq_src_e                   src;
    logic [3:0]                 host_id;
    mdma_cqid_t                 qid;
    logic                       wr;
    logic [31:0]                data;
} mdma_dyn_ptr_upd_t;

typedef struct packed {
    logic                     run;
    logic                     c2h_wbk_ena;
    logic                     noninc;
    logic [`ADR_WIDTH-1:0]    cdc_wbk_adr;
} creg_t;

typedef struct packed {
    logic                  pasid1_pr;   // 182 Privilege
    logic                  pasid0_pr;   // 181 Privilege
    logic                  pasid1_ex;   // 180 Execute
    logic                  pasid0_ex;   // 179 Execute
    logic    [19:0]        pasid1;      // 178:159 PASID 1 (20-bits) 
    logic    [19:0]        pasid0;      // 158:139 PASID 0 (20-bits) 
    logic                  pasid1_en;   // 138    PASID TLP Valid 1    
    logic                  pasid0_en;   // 137    PASID TLP Valid 0            
    logic    [63:0]        par;         // 136:73 Parity filled later
    logic    [5:0]         seq1;        // 72:67  Sequence Num 1
    logic    [5:0]         seq0;        // 66:61  Sequence Num 0
    logic    [23:0]        tph;         // 60:45  TPH St Tag
                                        // 44:43  TPH Ind Tag
                                        // 42:39  TPH Type
                                        // 38:37  TPH Present
    logic                  disc;        // 36     Discontinue
    logic    [3:0]         eop1_ptr;    // 35:32  EOP 1 Ptr
    logic    [3:0]         eop0_ptr;    // 31:28  EOP 0 Ptr
    logic                  eop1;        // 27     EOP 1
    logic                  eop0;        // 26     EOP 0
    logic    [1:0]         sop1_ptr;    // 25:24  SOP 1 Ptr
    logic    [1:0]         sop0_ptr;    // 23:22  SOP 0 Ptr
    logic                  sop1;        // 21     SOP 1
    logic                  sop0;        // 20     SOP 0
    logic    [3:0]         adr;         // 19:16  Address offset - Address aligned mode only
    logic    [3:0]         lbe1;
    logic    [3:0]         lbe0;
    logic    [3:0]         fbe1;
    logic    [3:0]         fbe0;
} rq_usr_straddle_t;

typedef struct packed {
    logic    [97:0]        rsv2;       // 182:85
    logic                  pasid_pr;   // 84 Privilege
    logic                  pasid_ex;   // 83 Execute
    logic    [19:0]        pasid;      // 82:63 PASID 0 (20-bits) 
    logic                  pasid_en;   // 62    PASID TLP Valid 0    
    logic    [1:0]         rsv0;       // 61:60 
    logic    [31:0]        par;        // 59:28
    logic    [3:0]         seq;        // 27:24
    logic    [11:0]        tph;        // 23:12
    logic                  dis;        // 11
    logic    [2:0]         adr;        // 10:8
    logic    [3:0]         lbe;        // 7:4
    logic    [3:0]         fbe;        // 3:0
} rq_usr_nostraddle_t;

typedef union packed {
    rq_usr_straddle_t        rqu_str;
    rq_usr_nostraddle_t      rqu_nstr;
} rq_usr_t;

typedef struct packed {
    logic   [12:0]  pcie_mrrs;
    logic   [12:0]  pcie_mps;
    logic   [12:0]  axi_mrrs;
    logic   [12:0]  axi_mps;
} cfg_dma_t;

typedef struct packed { 
    logic            ecrc;
    logic     [2:0]        attr;        
    logic    [2:0]        tc;    
    logic            rid_en;
    logic    [15:0]        cpl_id;
    logic    [7:0]        tag;
    logic    [15:0]        req_id;
    logic            poison;
    logic    [3:0]        req;
    logic    [10:0]        len;        
    logic    [63:0]        adr;
} rq_hdr_fields_t;

typedef struct packed { 
    logic    [23:0]        dw3_misc;
    logic    [7:0]        tag;
    logic    [16:0]        dw2_misc;
    logic    [3:0]        req;
    logic    [10:0]        len;        
    logic    [63:0]        adr;
} rq_hdr_compact_t;

typedef struct packed { 
    logic    [31:0]        dw3;
    logic    [31:0]        dw2;
    logic    [31:0]        dw1;
    logic    [31:0]        dw0;
} rq_hdr_dwords_t;

typedef union packed {
    rq_hdr_fields_t        rqh_f;
    rq_hdr_compact_t      rqh_c;
    rq_hdr_dwords_t      rqh_d;
} rq_hdr_t;

typedef struct packed { 
    logic                    tlast;
    logic    [`XDMA_C2H_TUSER_WIDTH-1:0]    tuser;
    logic    [`DAT_WIDTH/8-1:0]        tkeep;
    logic    [`DAT_WIDTH/8-1:0]        tparity;
    logic    [`DAT_WIDTH-1:0]        tdata;
} dma_s_axis_t;

typedef struct packed {
    logic [`DID_WIDTH-1:0]            waddr;
    logic [`DID_WIDTH-1:0]            raddr;
    logic [`DAT_WIDTH/8-1:0]          wen;
    logic                             ren;
} dat_bram_cmd_t;

typedef struct packed {
    logic                           sbe;
    logic                           dbe;
    logic [`DAT_WIDTH-1:0]          dat;
    logic [`DAT_WIDTH/8-1:0]        parity; // Even parity
}dat_bram_dat_t;


typedef struct packed {
    logic                    tlast;
    logic    [`XDMA_H2C_TUSER_WIDTH-1:0]    tuser;
    logic    [`DAT_WIDTH/8-1:0]        tkeep;
    logic    [`DAT_WIDTH/8-1:0]        tparity;
    logic    [`DAT_WIDTH-1:0]        tdata;
} dma_m_axis_t;
//typedef struct packed {
//    logic                    tlast;
//    logic    [`MULTQ_H2C_TUSER_WIDTH-1:0]    tuser;
//    logic    [`DAT_WIDTH/8-1:0]        tparity;
//    logic    [`DAT_WIDTH-1:0]        tdata;
//} mdma_m_axis_t;


// Descriptor Completion Memory Interface
typedef struct packed {
    logic    [`DAT_WIDTH-1:0]        rdat;
    logic                    rsbe;
    logic                    rdbe;
}dsc_cpl_bram_out_t;

typedef struct packed {
    logic                wen;
    logic    [`DSC_DID_WIDTH-1:0]    waddr;
    logic    [`DAT_WIDTH-1:0]        wdat;
    logic    [`DSC_RID_WIDTH-1:0]    raddr;
}dsc_cpl_bram_in_t;

// XDMA Descriptor Memory Interface
//typedef struct packed {    
    //logic    [255:0]     rdat;
    //logic                rbe;
//}dsc_bram_out_t;      

typedef struct packed {
    logic                wen;
    logic    [`DSC_DID_WIDTH-1:0]    waddr;
    logic    [255:0]            wdat;
    logic    [`DSC_RID_WIDTH-1:0]    raddr;
}dsc_bram_in_t;


//
typedef struct packed {
    logic    [11:0]            func;
    //logic    [3:0]            be;
} dma_axil_user_t;

typedef struct packed {
    logic               rsvd;		// 31
    logic    [11:0]     func;		// 30:19
    logic    [2:0]	steering;	// 18:16
    logic    [3:0]      bar_id;		// 15:12
    logic 		is_brdg_tfc;	// 11 : Set only for bridge traffic
    logic		inst_id;	// 10
    logic    [9:0]	smid;		// 9:0
} dma_axi_mst_br_user_t;

typedef struct packed {
    logic    [12:0]   qid;         // 31:19
    logic    [2:0]    steering;    // 18:16
    logic    [3:0]    host_id;     // 15:12
    logic             is_brdg_tfc; // 11 : Set only for bridge traffic
    logic             inst_id;     // 10
    logic    [9:0]    smid;        // 9:0
} dma_axi_mst_dma_user_t;


typedef union packed {
    dma_axi_mst_br_user_t brdg;
    dma_axi_mst_dma_user_t dma;
} dma_axi_mst_user_t;

typedef struct packed {
    logic    [11:0]   vfg_offset;     // 54:43
    logic    [2:0]    vfg;            // 42:40
    logic    [7:0]    bus_num;        // 39:32
    logic             rsvd;           // 31
    logic    [11:0]   func;           // 30:19
    logic    [2:0]    steering;       // 18:16
    logic    [3:0]    bar_id;         // 15:12
    logic             is_brdg_tfc;    // 11 : Set only for bridge traffic
    logic             inst_id;        // 10
    logic    [9:0]    smid;           // 9:0
} dma_axi_mst_br_user_soft_t;

typedef struct packed {
    logic   [22:0]	   rsvd;        // 54:32
    dma_axi_mst_dma_user_t user;	// 31:0
} dma_axi_mst_dma_user_soft_t;

typedef union packed {
    dma_axi_mst_br_user_soft_t brdg;
    dma_axi_mst_dma_user_soft_t dma;
} dma_axi_mst_user_soft_t;


typedef struct packed {
    logic		pasid_en;	// 34
    logic    [21:0]     pasid;		// 33:12
    logic    [11:0]     func;		// 11:0
} dma_axi_slv_br_user_soft_t;

// Descriptor Completion
`define DCP_SRC_BASE 0
`define DCP_LEN_BASE 64 
`define DCP_STP_BASE 92 
`define DCP_CPL_BASE 93 
`define DCP_EOP_BASE 94 
`define DCP_DST_BASE 128 
typedef struct packed {
    logic              h2cmm_vch_id;
    mdma_host_id_t     host_id;
    mdma_h2c_wb_data_t mdma;
    logic   [63:0]    rsv3;
    logic   [63:0]    wadr;     
    logic   [31:0]    rsv2;
    logic             rsv1;
    logic             eop;
    logic             cpl;
    logic             stp;
    logic   [27:0]    len;
    logic   [63:0]    radr;
} dcp_t;


// Descriptor In Credits (dma credits -> user)
typedef struct packed {
    logic                        vld;
    logic    [8:0]               num;
    logic    [`QID_WIDTH-1:0]    qid;
} dma_dsc_in_crd_t;


//Descriptor Format defines
`define DMA_DSC_FMT_VIO_AVL_RING_ENTRY 3'h4   //Avail-Ring entry
`define DMA_DSC_FMT_VIO_DESC           3'h6   //Virtio-Descriptor

// Descriptor Out (dma descriptors -> user)
typedef struct packed {
    mdma_c2h_misc_t             misc;            
    mdma_dma_buf_len_t          len;             // Length
    logic                       pasid_en;
    logic    [21:0]             pasid;
    logic    [3:0]              host_id; // 0: PCIe, 1: AXIMM
    logic    [5:0]              cnt;   // Number of descriptors completed in the beat
    logic    [1:0]              at;    //  Address type 00: untranslated (physical), 10: translated (virtual), 01 : translation request
    logic    [2:0]              fmt;   // 0: normal descriptor fetch; 2'h1 : is_wb cycle contains wb information, not descriptor; 2'h2 : fetch_imm; 2'h3: fetch_imm_int
    logic    [2:0]              port_id;
    logic                       lst;    // Last descriptor in fetch request (8B descr only)
    logic                       err;    // Error on descriptor fetch
    logic                       wbi;
    logic                       wbi_chk;  // byp mode : generate marker resp;   Internal mode: generate markrer_resp, interrrupt, writeback if idle
    dma_dsc_out_size_e          dsc_sz; // 0: 8B C2H ST, 1: 16B H2C ST, 2: 32B H2C/C2H MM
    logic                       mm_chn; // MM channel 0 or 1
    logic                       sel;    // 0: H2C, 1: C2H
    logic                       st_mm;  // 0: Stream,  1: MM
    logic                       byp;    // Send to bypass out
    mdma_fnid_t                 fnc;
    logic    [15:0]             cidx;
    logic    [`QID_WIDTH-1:0]   qid;    // Q ID
    logic                       qen;    // Qen
    logic    [255:0]            dsc;
} dma_dsc_block_t;


// Descriptor Out Credits (dma_eng credits -> dsc_eng)
typedef struct packed {
    logic                        vld;
    logic    [3:0]               crd;
} dma_dsc_out_crd_t;

    typedef struct packed {
        logic [3:0]     h2c_byp_out;
        logic [3:0]     c2h_byp_out;
        logic [3:0]     h2c_byp_in;
        logic [3:0]     c2h_byp_in;
        logic           xdma_byp_in_axi; //If XDMA is used this globally select 1: AXI 0:load interface
    } reg_dsc_byp_enable_t;

// Descriptor Out (dma descriptors -> user)
typedef struct packed {
    logic [2:0]                 fmt;  //  0: normal descriptor fetch; 3'h1 : is_wb cycle contains wb information, not descriptor; 3'h2 : fetch_imm; 4'h4 virtio_avl_ring, 4'h6 virtio dsc
    logic [2:0]                 port_id;
    logic                       wbi;
    logic                       wbi_chk;
    dma_dsc_out_size_e          dsc_sz;     
    logic                       mm_chn;     // This is for MM only; 0 - MM0, 1 - MM1
    logic                       sel;        // 0: H2C, 1: C2H
    logic                       st_mm;      // 0: Stream,  1: MM
    mdma_qid_t                  qid;
    logic                       last;
    logic                       error;
    mdma_fnid_t                 func;
    logic    [15:0]             cidx;
} dma_h2c_byp_dsc_out_sb_t;

typedef struct packed {
    dma_h2c_byp_dsc_out_sb_t    sb;
    logic    [255:0]            dsc;
} dma_h2c_byp_dsc_out_t;

typedef struct packed {
    mdma_dma_buf_len_t          len;             // Length 
    logic                       var_desc;
    mdma_c2h_cache_tag_t        pfch_tag;        // Tag of C2H Pfch cache
    logic                       pasid_en;
    logic [21:0]                pasid;
    mdma_host_id_t              host_id;    // 0: PCIe, 1: AXIMM
    logic    [5:0]              cnt;       // Number of completed descriptors in the beat
    logic    [2:0]              fmt;  //  0: normal descriptor fetch; 2'h1 : is_wb cycle contains wb information, not descriptor; 2'h2 : fetch_imm
    logic    [2:0]              port_id;
    logic                       wbi;
    logic                       wbi_chk;
    dma_dsc_out_size_e          dsc_sz;    
    logic                       mm_chn;     // This is for MM only; 0 - MM0, 1 - MM1
    logic                       sel;        // 0: H2C, 1: C2H
    logic                       st_mm;      // 0: Stream,  1: MM
    mdma_qid_t                  qid;
    logic                       last;
    logic                       error;
    mdma_fnid_t                 func;
    logic    [15:0]             cidx;
} mdma_c2h_byp_dsc_out_sb_t;

typedef struct packed {
    mdma_c2h_byp_dsc_out_sb_t   sb;  
    logic    [255:0]            dsc;
} mdma_c2h_byp_dsc_out_t;

// Descriptor Out (dma descriptors -> user)
typedef struct packed {
    mdma_dma_buf_len_t          len;             // Length 
    logic                       var_desc;
    mdma_c2h_cache_tag_t        pfch_tag;        // Tag of C2H Pfch cache
    logic                       pasid_en;
    logic [21:0]                pasid;
    mdma_host_id_t              host_id; // 0: PCIe, 1: AXIMM
    logic    [5:0]              cnt;     // Number of completed descriptors in the beat
    logic    [2:0]              fmt;     // 0: normal descriptor fetch; 2'h1 : is_wb cycle contains wb information, not descriptor; 2'h2 : fetch_imm
    logic    [2:0]              port_id;
    logic                       wbi;
    logic                       wbi_chk;
    dma_dsc_out_size_e          dsc_sz;     
    logic                       mm_chn;     // This is for MM only; 0 - MM0, 1 - MM1
    logic                       sel;        // 0: H2C, 1: C2H
    logic                       st_mm;      // 0: Stream,  1: MM
    mdma_qid_t                  qid;
    logic                       last;
    logic                       error;
    mdma_fnid_t                 func;
    logic    [15:0]             cidx;
} mdma_h2c_byp_dsc_out_sb_t;

typedef struct packed {
    mdma_h2c_byp_dsc_out_sb_t   sb;
    logic    [255:0]            dsc;
} mdma_h2c_byp_dsc_out_t;

typedef struct packed {
    logic                       var_desc;
    mdma_c2h_cache_tag_t        pfch_tag;        // Tag of C2H Pfch cache
    logic                       pasid_en;
    logic [21:0]                pasid;
    mdma_dma_buf_len_t          len;             // Length 
    logic [3:0]                 host_id;    // 0: PCIe, 1: AXIMM
    logic [1:0]                 at;
    logic [2:0]                 fmt;        // 0: normal descriptor fetch; 2'h1 : is_wb cycle contains wb information, not descriptor; 2'h2 : fetch_imm
    logic [2:0]                 port_id;
    logic                       wbi;
    logic                       wbi_chk;
    dma_dsc_out_size_e          dsc_sz;     // XDMA 32B, UDMA AXIS/MDMA 8B,UDMA MM 16B
    logic                       mm_chn;     // This is for MM only; 0 - MM0, 1 - MM1
    logic                       sel;        // 0: H2C, 1: C2H
    logic                       st_mm;      // 0: Stream,  1: MM
    mdma_qid_t                  qid;
    logic                       last;
    logic                       error;
    mdma_fnid_t                 func;
    logic    [15:0]             cidx;
} mdma_c2h_byp_dsc_in_sb_t;

typedef struct packed {
    mdma_c2h_byp_dsc_in_sb_t    sb;
    logic    [255:0]            dsc;
} mdma_c2h_byp_dsc_in_t;

typedef struct packed {
    logic [21:0]                pasid;
    logic                       pasid_en;
    logic [11:0]                func;
    logic [3:0]                 host_id;
    logic [2:0]                 port_id;
    logic [15:0]                cidx;
    logic                       error;
    logic [12:0]                qid;
    logic                       mrkr_req;
    logic                       sdi;
    logic [27:0]                len;
    logic                       no_dma;
    logic [1:0]                 at;
    logic [63:0]                wadr;
    logic [63:0]                radr;
} mdma_fab_c2h_byp_dsc_in_mm_t;

typedef struct packed {
    logic [21:0]                pasid;
    logic                       pasid_en;
    logic                       var_desc;
    logic [6:0]                 pfch_tag;
    logic [3:0]                 host_id;
    logic [2:0]                 port_id;
    logic [2:0]                 fmt;
    logic [15:0]                cidx;
    logic [11:0]                func;
    logic                       error;
    logic [1:0]                 at;
    logic [15:0]                len;
    logic [63:0]                addr;
} mdma_fab_c2h_byp_dsc_in_st_t;

typedef struct packed {
    logic                       var_desc;
    mdma_c2h_cache_tag_t        pfch_tag;        // Tag of C2H Pfch cache
    logic                       pasid_en;
    logic [21:0]                pasid;
    mdma_dma_buf_len_t          len;             // Length 
    logic    [3:0]              host_id;    // 0: PCIe, 1: AXIMM
    logic [1:0]                 at;
    logic    [2:0]              fmt;        //  0: normal descriptor fetch; 2'h1 : is_wb cycle contains wb information, not descriptor; 2'h2 : fetch_imm
    logic [2:0]                 port_id;
    logic                       wbi;
    logic                       wbi_chk;
    dma_dsc_out_size_e          dsc_sz;     // XDMA 32B, UDMA AXIS/MDMA 8B,UDMA MM 16B
    logic                       mm_chn;     // This is for MM only; 0 - MM0, 1 - MM1
    logic                       sel;        // 0: H2C, 1: C2H
    logic                       st_mm;      // 0: Stream,  1: MM
    mdma_qid_t                  qid;
    logic                       last;
    logic                       error;
    mdma_fnid_t                 func;
    logic    [15:0]             cidx;
} mdma_h2c_byp_dsc_in_sb_t;

typedef struct packed {
    mdma_h2c_byp_dsc_in_sb_t    sb;
    logic    [255:0]            dsc;
} mdma_h2c_byp_dsc_in_t;

typedef struct packed {
    logic [21:0]                pasid;
    logic                       pasid_en;
    logic [11:0]                func;
    logic [3:0]                 host_id;
    logic [2:0]                 port_id;
    logic [15:0]                cidx;
    logic                       error;
    logic [12:0]                qid;
    logic                       mrkr_req;
    logic                       sdi;
    logic [27:0]                len;
    logic                       no_dma;
    logic [1:0]                 at;
    logic [63:0]                wadr;
    logic [63:0]                radr;
} mdma_fab_h2c_byp_dsc_in_mm_t;

typedef struct packed {
    logic [21:0]                pasid;
    logic                       pasid_en;
    logic [11:0]                func;
    logic [3:0]                 host_id;
    logic [2:0]                 port_id;
    logic [12:0]                qid;
    logic [15:0]                cidx;
    logic                       error;
    logic                       no_dma;
    logic                       mrkr_req;
    logic                       sdi;
    logic                       eop;
    logic                       sop;
    logic [1:0]                 at;
    logic [15:0]                len;
    logic [63:0]                addr;
} mdma_fab_h2c_byp_dsc_in_st_t;

typedef struct packed {
    logic                       wbi;     //(UDMA only)
    logic                       wbi_chk; //(UDMA only)
    logic    [15:0]             cidx;    //(UDMA only)
    dma_dsc_out_size_e          siz;     // XDMA 32B, UDMA AXIS 8B & UDMA MM 16B
    logic    [`QID_WIDTH-1:0]   qid;    // Q ID (UDMA only)
    logic    [255:0]            dsc;
} dma_c2h_byp_dsc_out_t;

//typedef struct packed {
    //logic                       wbi;
    //logic                       wbi_chk;
    //dma_dsc_out_size_e          dsc_sz;
    //logic                       mm_chn;
    //logic    [`QID_WIDTH-1:0]   qid;    // Q ID
    //logic                       last;
    //logic                       error;
    ////logic    [7:0]              func;
    //logic    [15:0]             cidx;
//} dma_h2c_byp_dsc_in_sb_t;

typedef struct packed {
    logic    [255:0]            dsc;
} dma_h2c_byp_dsc_in_t;

    `define NEW_BYPASS_IN_ONLY_XXX

typedef struct packed {
    logic    [255:0]            dsc;
} dma_c2h_byp_dsc_in_t;


typedef struct packed {
    logic                       wbi;
    logic                       wbi_chk;
    logic    [15:0]             cidx;
    logic [`QID_WIDTH-1:0]      qid;
    logic [127:0]               dsc;
    logic                       lsiz; //0 - all bits are valid, 1 - lower 64 bits are valid.
    logic                       last;
    logic [1:0]                 chn;
    logic                       typ;
} dma_h2c_byp_dsc_ev_out_t;

typedef struct packed {
    mdma_host_id_t              host_id;
    logic [1:0]                 pend;
    logic [31:0]                vec;
    mdma_fnid_t                 fnc;
    logic                       req;
} cfg_interrupt_msix_req_t;

typedef struct packed {
    logic                       fail;
    logic                       sent;
} cfg_interrupt_msix_ack_t;

typedef struct packed {
    logic  [`MSIX_WIDTH-1:0]    ack;
    logic                       fail;
// No completion function needed 
// legacy mode supports only function 0.
// new mode supports 1 outstanding request at a time
} mdma_usr_irq_if_out_t;

typedef struct packed {
    logic                       vld;
    mdma_host_id_t              host_id;
    logic  [`MSIX_WIDTH-1:0]    vec;
    logic  [12:0]               fnc;
    logic  [1:0]                pnd;
} mdma_usr_irq_if_in_t;

typedef struct packed {
    logic  [15:0]               ack;
    logic                       fail;
// No completion function needed 
// legacy mode supports only function 0.
// new mode supports outstanding request at a time
} xdma_usr_irq_if_out_t;

typedef struct packed {
    logic  [15:0]               sent_vec;
    logic                       sent_fail;
    logic                       sent_vld;

    logic                       acc_vld;
    logic                       acc_fail;
} xdma_usr_irq_enc_if_out_t;

typedef struct packed {
    logic                       vld;
    logic  [15:0]               vec;
    logic  [12:0]               fnc;
    logic  [1:0]                pnd;
} xdma_usr_irq_if_in_t;

typedef struct packed {
    logic [12:0]         fnc;
    logic                vld;
} usr_flr_if_out_t;

typedef struct packed {
    logic   [12:0]        fnc;
    logic                 vld;
} usr_flr_if_in_t;

// Dma Management Interface Mux Structs
typedef struct packed {
   logic                 eop;
   logic  [16:0]         dat;
} dma_mgmt_req_if_t;


typedef struct packed {
   logic  [16:0]         dat;
} dma_mgmt_cpl_if_t;

// Dma Management Interface Fabric Structs
typedef struct packed {
    logic                vld;
    dma_mgmt_cpl_if_t    pay;
} dma_mgmt_cpl_if_out_t;

typedef struct packed {
    logic                crd;
} dma_mgmt_cpl_if_in_t;


typedef struct packed {
    logic                crd;
} dma_mgmt_req_if_out_t;

typedef struct packed {
    logic                vld;
    dma_mgmt_req_if_t    pay;
} dma_mgmt_req_if_in_t;

typedef struct packed {
    logic  crd;
} mdma_dsc_imm_crd_oif_t;
typedef struct packed {
    logic                   vld;
    mdma_dsc_eng_imm_crdt_t info;
} mdma_dsc_imm_crd_iif_t;

// Dma Management Transaction Structs
typedef struct packed  {
    logic [31:0]  dat;
    logic [31:0]  adr;
    logic [12:0]  fnc;
    logic [5:0]   msc;  // Misc.  Reserved
    logic [1:0]   cmd;  // 2'h0: Read, 2'h1 Write.  
} dma_mgmt_req_t;

typedef struct packed  {
    logic [1:0]   sts;
    logic [31:0]  dat;
} dma_mgmt_cpl_t;

typedef struct packed {
   logic                upd;
   logic  [12:0]        fnc;
} dma_mgmt_flr_done_t;

typedef struct packed {
   logic        sbe;
   logic        dbe;
   logic [31:0] log;
} ram_err_log_t;

    // in dma5_mdma_defines.svh
////typedef enum logic [1:0]{
   //MDMA_DSC_MISC_EVT = 0,
   //MDMA_DSC_RCP_EVT =  1,
   //MDMA_DSC_IMM_EVT = 2,
   //MDMA_DSC_VIO_IDX_RCP_EVT =  3
//} mdma_dsc_evt_e;

typedef enum logic [1:0]{
   MDMA_RCP_DSC     = 0,
   MDMA_RCP_VIO_IDX = 1,
   MDMA_RCP_IMM     = 2,
   MDMA_RCP_RSV1    = 3
} rcp_evt_t;

typedef struct packed {
         logic [4:0]              err;
         logic [16:0]             dat;
         logic [0:0]              chn; // H2C or C2H
         logic [`QID_WIDTH-1:0]   qid;
         mdma_dsc_evt_e           evt;
} ctxt_arb_t;

typedef struct packed {
        logic                            imm;
        dma_dsc_vio_fetch_e              vio_idx;
        logic   [1:0]                    bsel;
        logic   [0:0]                    chn; // H2C or C2H
        logic   [`QID_WIDTH-1:0]         qid;
        logic   [63:0]                   adr;
        mdma_dsc_hw_ctxt_t               hw_ctxt; 
        mdma_ind_dsc_t                   sw_ctxt;
} dscf_pipe_t;

// SR: BDF Table
typedef struct packed {
    logic [31:0]    pcie_addr_lo;
} bdf_addr_reg0;

typedef struct packed {
    logic [31:0]    pcie_addr_hi;
} bdf_addr_reg1;

typedef struct packed {
    logic [8:0]    rsvd;        //31:23
    logic [21:0]    pasid;        //22:1
    logic        pasid_en;    //0
} bdf_pasid_reg;

typedef struct packed {
    logic [19:0]    rsvd;        //31:12
    logic [11:0]    func_id;    //11:0
} bdf_function_reg;

typedef struct packed {
    logic [1:0]    access_perm;    //31:30
    logic        error;        //29
    logic [2:0]    prot;        //28:26
    logic [25:0]    win_size;    //25:0
} bdf_window_reg;

typedef struct packed {
    logic [21:0]    rsvd;        //31:10
    logic [9:0]     smid;        //9:0
} bdf_smid_reg;

// BDF Table Lookup
typedef struct packed {
  logic [9:0]  smid;
  logic [1:0]  access_perm;
  logic        error;
  logic [2:0]  prot;
  logic [25:0] win_size;
  logic [11:0] func_id;
  logic [21:0] pasid;
  logic        pasid_en;
  logic [63:0] pcie_addr;      
} bdf_table_entry_t;                 
  
// BDF Error Type:
// 0 : trustzone violation
// 1 : incompleted BDF entry
// 2 : exceed BDF window size
// 3 : access permission violation
// 4 : error flag is set
// 8 : SMID mismatch
typedef struct packed {
  bdf_table_entry_t bdf_entry;
  logic [7:0]  bdf_tbl_idx;
  logic [3:0]  bdf_err_type;
  logic        bdf_err_det;
  logic [2:0]  bar_rlx_rd;   
} bdf_lookup_result_t;

//AXI interrupt structs
typedef struct packed {
        logic               vld;
        mdma_host_id_t      host_id;
        mdma_int_vec_out_t  vec;
        mdma_fnid_t         func_num;
} axi_intr_out_t;

typedef struct packed {
        logic               ack;
} axi_intr_in_t;

// Cfg Extension Struct
typedef struct packed {
    logic [31:0]   cfg_ext_read_data;
    logic          cfg_ext_read_data_vld;
} cfg_ext_usr_in_t;


typedef struct packed {
logic                cfg_ext_read_received;
logic                cfg_ext_write_received;
logic     [31:0]     cfg_ext_write_data;
logic     [3:0]      cfg_ext_write_byte_enable;
logic     [7:0]      cfg_ext_function_number;
logic     [9:0]      cfg_ext_register_number;
} cfg_ext_usr_out_t;

// Structures for Firmware Controlled Logic via APB such as PCIe Firewall
typedef struct packed {
   logic [25:0]		rsvd;          // TBD
   logic             pcie_rq;       // [5]
   logic             pcie_rc;       // [4]
   logic             pcie_req;      // [3]
   logic             axi_mm_mst_rd; // [2]
   logic             axi_mm_mst_wr; // [1]
   logic             rx_msg_fifo;   // [0]
} dma_sub_domains_t; // DMA Sub-domains

typedef struct packed {
   dma_sub_domains_t dma_soft_reset;   // per sub-domains
   logic             pcie_firewall_en; // PCIe Firewall Enable
} fw_dma_ctl_t; // Controls for Firmware

typedef struct packed {
   dma_sub_domains_t dma_is_busy;   // per sub-domains
} fw_dma_sts_t; // Statuses for Firmware

// Convert VF to PF
function automatic mdma_fnid_t vf_to_pf (input mdma_fnid_t func_in, input  attr_dma_pf_t [3:0]  attr_dma_pf);

    localparam PF_NUM = 4;

    vf_to_pf = 'h0;

    if (func_in < PF_NUM) 
    begin
       vf_to_pf = func_in;
    end
    else 
    begin
        for (integer i = 0; i < PF_NUM; i = i+1)
            if ((func_in <  (attr_dma_pf[i].firstvf_offset + i + attr_dma_pf[i].num_vfs)) &&        // 1st vfoffset is relative to the PF
                (func_in >= (attr_dma_pf[i].firstvf_offset + i)))                                   // 1st vfoffset is relative to the PF
                vf_to_pf = i[$bits(mdma_fnid_t)-1:0];
    end

endfunction

// Convert VF to PF
function automatic mdma_fnid_t vf_to_pf2 (integer PF_NUM, input mdma_fnid_t func_in, input  attr_dma_pf_t [31:0]  attr_dma_pf);
    vf_to_pf2 = 'h0;

    if (func_in < PF_NUM) 
    begin
       vf_to_pf2 = func_in;
    end
    else 
    begin
        for (integer i = 0; i < PF_NUM; i = i+1)
            if ((func_in <  (attr_dma_pf[i].firstvf_offset + i + attr_dma_pf[i].num_vfs)) &&        // 1st vfoffset is relative to the PF
                (func_in >= (attr_dma_pf[i].firstvf_offset + i)))                                   // 1st vfoffset is relative to the PF
                vf_to_pf2 = i[$bits(mdma_fnid_t)-1:0];
    end

endfunction


// Interface Conversion

`define PCIE_CC_TO_DMA_CC_IF(pcie_cc, dma_cc) \
assign pcie_cc.axis_cc_tvalid =       dma_cc.tvalid; \
assign pcie_cc.axis_cc_tdata  = 'h0 | dma_cc.tdata; \
assign pcie_cc.axis_cc_tuser  = 'h0 | dma_cc.tuser; \
assign pcie_cc.axis_cc_tkeep  = 'h0 | dma_cc.tkeep; \
assign pcie_cc.axis_cc_tlast  =       dma_cc.tlast; \
assign dma_cc.tready          = 'h0 | pcie_cc.axis_cc_tready; 

`define PCIE_CQ_TO_DMA_CQ_IF(pcie_cq, dma_cq) \
assign dma_cq.tvalid           =     | pcie_cq.axis_cq_tvalid; \
assign dma_cq.tdata            = 'h0 | pcie_cq.axis_cq_tdata; \
assign dma_cq.tuser            = 'h0 | pcie_cq.axis_cq_tuser; \
assign dma_cq.tkeep            = 'h0 | pcie_cq.axis_cq_tkeep; \
assign dma_cq.tlast            =     | pcie_cq.axis_cq_tlast; \
assign pcie_cq.axis_cq_tready  = 'h0 | dma_cq.tready; 

`define PCIE_RC_TO_DMA_RC_IF(pcie_rc, dma_rc) \
assign dma_rc.tvalid           =     | pcie_rc.axis_rc_tvalid; \
assign dma_rc.tdata            = 'h0 | pcie_rc.axis_rc_tdata; \
assign dma_rc.tuser            = 'h0 | pcie_rc.axis_rc_tuser; \
assign dma_rc.tkeep            = 'h0 | pcie_rc.axis_rc_tkeep; \
assign dma_rc.tlast            =     | pcie_rc.axis_rc_tlast; \
assign pcie_rc.axis_rc_tready  = 'h0 | dma_rc.tready; 

`define PCIE_RQ_TO_DMA_RQ_IF(pcie_rq, dma_rq) \
assign pcie_rq.axis_rq_tvalid =       dma_rq.tvalid; \
assign pcie_rq.axis_rq_tdata  = 'h0 | dma_rq.tdata; \
assign pcie_rq.axis_rq_tuser  = 'h0 | dma_rq.tuser; \
assign pcie_rq.axis_rq_tkeep  = 'h0 | dma_rq.tkeep; \
assign pcie_rq.axis_rq_tlast  =       dma_rq.tlast; \
assign dma_rq.tready          = 'h0 | pcie_rq.axis_rq_tready; 

typedef struct packed {
    logic [32-11-1:0] rsv;
    logic       rc_discontinue;
    logic       rc_prty_err;
    logic       rc_flr;
    logic       rc_timeout;
    logic       rc_inv_bcnt;
    logic       rc_inv_tag;
    logic       rc_start_addr_mismch;
    logic       rc_rid_tc_attr_mismch;
    logic       rc_no_data;
    logic       rc_ur_ca_crs;
    logic       rc_poisoned;
} pcie_req_err_stat_t;

// VDM
typedef struct packed {
    logic [15:0]                data;
    logic [ 1:0]                sb;
    logic                       last;
    logic                       vld;
} dma_vdm_oif_t;

// VDM
typedef struct packed {
    logic                       crdt;
} dma_vdm_iif_t;

typedef struct packed {
    dma_vdm_oif_t                vdm;
    dma_mgmt_req_if_out_t        dma_mgmt_req;
    dma_mgmt_cpl_if_out_t        dma_mgmt_cpl;
    cfg_ext_usr_out_t            cfg_ext_out;
    logic                        axi_resetn;
    mdma_desc_rsp_drop_t         c2h_drop;
    mdma_c2h_pcie_cmp_t          c2h_pcie_cmp;
    mdma_c2h_st_mhost_feedback_t c2h_st_mhost_feedback;
    dma_err_out_t                dma_err_out;
    usr_flr_if_out_t             flr_out;
    axi_intr_out_t               axi_interrupt_out;
} com_fab_oif_t;


typedef struct packed {
    dma_vdm_iif_t                    vdm;
    dma_mgmt_req_if_in_t             dma_mgmt_req;
    dma_mgmt_cpl_if_in_t             dma_mgmt_cpl;
    cfg_ext_usr_in_t                 cfg_ext_in;
    logic                            dma_reset;
    usr_flr_if_in_t                  flr_in;
    axi_intr_in_t                    axi_interrupt_in;
    logic                            fab_mst_crd_rst;
    logic                            fab_slv_crd_rls;
} com_fab_iif_t;

`include "cpm5_dma_debug_defines.svh"
`endif


