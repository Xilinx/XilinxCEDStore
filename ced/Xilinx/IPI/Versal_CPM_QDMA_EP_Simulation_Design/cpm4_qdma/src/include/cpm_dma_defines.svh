`ifndef DMA_DEFINES_SVH
`define DMA_DEFINES_SVH
`timescale 1 ps / 1 ps
`include "cpm_dma_defines.vh"
`include "cpm_pcie_dma_attr_defines.svh"
`include "cpm_mdma_reg.svh"
`include "cpm_dma_reg.svh"

// Interface Includes at bottom of file (use some structures defined in this file)

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

typedef struct packed {
    logic                  spl;
    logic                  err;    // request with error detected
    logic                  sec;    // AXI MM only
    logic [3:0]            cache;  // AXI MM only
    logic [`ADR_WIDTH-1:0] adr;
    logic [`RID_WIDTH-1:0] rid;
    logic [`LEN_WIDTH-1:0] byte_len;   // byte length
    logic [`DID_WIDTH-1:0] did;
    logic [10:0]           fnc;        // function/QID  Keep this in LSB
} rrq_t;

typedef struct packed {
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
    logic [7:0]            fnc;        // function
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
    logic                       byp;
    logic    [2:0]              port_id;
    logic                       is_mm;
    logic                       mm_chn;
    logic    [1:0]              dsc_sz;
    logic                       end_rng; // The last descriptor of this fetch is the end of the ring
    logic                       wbi_imm;  // Do writeback/interrupt on descriptor completion
    logic                       wbi_chk;  // Check status before writeback/interrupt
    logic                       qen;
    logic   [`QID_WIDTH-1:0]    qid;     // Q ID 
    logic   [7:0]               fnc;
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
    logic                  err;
    logic                  sec;    // AXI MM only
    logic [3:0]            cache;  // AXI MM only
    logic [`ADR_WIDTH-1:0] adr;
    logic [`RID_WIDTH-1:0] rid;
    logic [`LEN_WIDTH-1:0] byte_len;   // byte length
    logic [5:0]            aln;        // Source alignment
    logic                  eop;
    logic                  eod;
    logic                  eor;
    logic [10:0]           fnc;   // Function/QID  Keep this in LSB
} wrq_t;

typedef struct packed {
    logic                  err;
    logic                  dbe;
    logic                  sec;    // AXI MM only
    logic [3:0]            cache;  // AXI MM only
    logic [3:0]            chn;
    logic [`ADR_WIDTH-1:0] adr;
    logic [`RID_WIDTH-1:0] rid;
    logic [`LEN_WIDTH-1:0] byte_len;   // byte length
    logic [5:0]            aln;        // Source alignment
    logic                  eop;
    logic                  eod;
    logic                  eor;
    logic [7:0]            fnc;    
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
    logic [7:0]      func;
} trq_t;

typedef struct packed {
    logic            vld;
    logic [31:0]     dat;
} tcp_t;

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
    logic    [7:0]            func;
    //logic    [3:0]            be;
} dma_axil_user_t;

// Descriptor Completion
`define DCP_SRC_BASE 0
`define DCP_LEN_BASE 64 
`define DCP_STP_BASE 92 
`define DCP_CPL_BASE 93 
`define DCP_EOP_BASE 94 
`define DCP_DST_BASE 128 
typedef struct packed {
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

// Descriptor Out (dma descriptors -> user)
typedef struct packed {
    logic                     is_wb;    // Cycle contains wb information, not descriptor
    logic    [2:0]            port_id;
    logic                       lst;    // Last descriptor in fetch request (8B descr only)
    logic                       err;    // Error on descriptor fetch
    logic                       wbi;
    logic                       wbi_chk;
    logic    [1:0]              dsc_sz; // 0: 8B C2H ST, 1: 16B H2C ST, 2: 32B H2C/C2H MM
    logic                       mm_chn; // MM channel 0 or 1
    logic                       sel;    // 0: H2C, 1: C2H
    logic                       st_mm;  // 0: Stream,  1: MM
    logic                       byp;    // Send to bypass out
    logic    [7:0]              fnc;
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

    typedef enum logic [1:0] {DMA_DSC_OUT_8B=0, DMA_DSC_OUT_16B=1, DMA_DSC_OUT_32B=2} dma_dsc_out_size_e;
// Descriptor Out (dma descriptors -> user)
typedef struct packed {
    logic                       is_wb;      // Is writeback status.  If set, this is not a valid descriptor.  Instead wbi indicates writeback.  error, st_mm, cidx, pidx also valid. 
    logic [2:0]                 port_id;
    logic                       wbi;
    logic                       wbi_chk;
    logic [1:0]                 dsc_sz;     
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
    logic                       is_wb;  // Is writeback status.  If set, this is not a valid descriptor.  Instead wbi indicates writeback.  error, cidx, pidx also valid. 
    logic [2:0]                 port_id;
    logic                       wbi;
    logic                       wbi_chk;
    logic [1:0]                 dsc_sz;    
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
    logic                       is_wb;      // Is writeback status.  If set, this is not a valid descriptor.  Instead wbi indicates writeback.  error, st_mm, cidx, pidx also valid.
    logic [2:0]                 port_id;
    logic                       wbi;
    logic                       wbi_chk;
    logic [1:0]                 dsc_sz;     
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
    logic                       is_wb;
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
    logic                       is_wb;
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
    logic [1:0]                 pend;
    logic [31:0]                vec;
    logic [7:0]                 fnc;
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
    logic  [`MSIX_WIDTH-1:0]    vec;
    logic  [7:0]                fnc;
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
    logic  [7:0]                fnc;
    logic  [1:0]                pnd;
} xdma_usr_irq_if_in_t;

typedef struct packed {
    logic [7:0]          fnc;
    logic                set;
    logic                clr;
} usr_flr_if_out_t;

typedef struct packed {
    logic   [7:0]         fnc;
    logic                 vld;
} usr_flr_if_in_t;

// Dma Management Interface Mux Structs
typedef struct packed {
   logic                 eop;
   logic  [15:0]         dat;
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


// Dma Management Transaction Structs
typedef struct packed  {
    logic [31:0]  dat;
    logic [31:0]  adr;
    logic [7:0]   fnc;
    logic [5:0]   msc;  // Misc.  Reserved
    logic [1:0]   cmd;  // 2'h0: Read, 2'h1 Write.  
} dma_mgmt_req_t;

typedef struct packed  {
    logic [1:0]   sts;
    logic [31:0]  dat;
} dma_mgmt_cpl_t;

typedef struct packed {
   logic                upd;
   logic  [7:0]         fnc;
} dma_mgmt_flr_done_t;

typedef struct packed {
   logic        sbe;
   logic        dbe;
   logic [31:0] log;
} ram_err_log_t;

typedef struct packed {
         logic [4:0]              err;
         logic [0:0]              chn; // H2C or C2H
         logic [`QID_WIDTH-1:0]   qid;
         logic                    rcp;
} ctxt_arb_t;

typedef struct packed {
        logic   [0:0]                    chn; // H2C or C2H
        logic   [`QID_WIDTH-1:0]         qid;
        logic   [15:0]                   crd_avl;
        logic   [63:0]                   adr;
        logic   [15:0]                   dsc_avl;
        mdma_dsc_hw_ctxt_t               hw_ctxt; 
        mdma_ind_dsc_ctl_t               ctl_ctxt;
        mdma_ind_dsc_sts_t               sts_ctxt;
} dscf_pipe_t;



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

    /*
`include "dma_pcie_axis_cc_if.sv"
`include "dma_pcie_axis_cq_if.sv"
`include "dma_pcie_axis_rc_if.sv"
`include "dma_pcie_axis_rq_if.sv"
`include "pciea_port_dbg_if.sv"
//`include "dma_pcie_c2h_axis_if.sv"
`include "dma_pcie_c2h_crdt_if.sv"
`include "dma_pcie_fabric_input_if.sv"
`include "dma_pcie_fabric_output_if.sv"
`include "dma_pcie_gic_if.sv"
//`include "dma_pcie_h2c_axis_if.sv"
`include "dma_pcie_h2c_crdt_if.sv"
`include "dma_pcie_mi_16Bx4096_4Bwe_ram_if.sv"
`include "dma_pcie_mi_2Bx4096_ram_if.sv"
`include "dma_pcie_mi_6Bx4096_ram_if.sv"
`include "dma_pcie_mi_4Bx256_4Bwe_ram_if.sv"
`include "dma_pcie_mi_64Bx128_32Bwe_ram_if.sv"
`include "dma_pcie_mi_64Bx256_32Bwe_ram_if.sv"
`include "dma_pcie_mi_64Bx512_32Bwe_ram_if.sv"
`include "dma_pcie_mi_8Bx2048_4Bwe_ram_if.sv"
`include "dma_pcie_mi_dsc_cpld_if.sv"
`include "dma_pcie_mi_dsc_cpli_if.sv"
`include "dma_pcie_misc_input_if.sv"
`include "dma_pcie_misc_output_if.sv"
`include "dma_pcie_h2c_byp_out_if.sv"
`include "dma_pcie_c2h_byp_out_if.sv"
`include "dma_pcie_h2c_byp_in_if.sv"
`include "dma_pcie_c2h_byp_in_if.sv"
`include "dma_pcie_mi_pasid_ram_if.sv"
    */
`include "cpm_dma_debug_defines.svh"
`endif


