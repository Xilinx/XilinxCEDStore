package shim_enum_pkg;

  import shim_caps_pkg::*;
  import shim_ecaps_pkg::*;

  typedef struct packed {
    bit [23:16] base;
    bit [15: 8] sub_class;
    bit [ 7: 0] prog_if;
  } class_code_s;

  typedef enum bit [1:0] {
    USE_AGENT, AGENT_ALLOC, AGENT_NO_ALLOC, BYPASS_AGENT
  } coh_e;

  typedef enum bit [1:0] {
    NONBLOCK, SCHED, SENT, DONE
  } blocking_e;

  typedef struct packed {
    bit [7:0] b;
    union packed {
      struct packed {
        bit [4:0] d;
        bit [2:0] f;
      } df;
      bit [7:0] arif;    
    } id;
  } bdf_s;

  //PCIe_Cap.Device/Port Type
  typedef enum bit [3:0] {
    // Type 0
    PT_PCIE_EP,
    PT_LPCIE_EP,
    PT_RCIEP=9,
    PT_RCEC,
    // Type 1
    PT_RP=4,
    PT_SW_USP,
    PT_SW_DSP,
    PT_PCIE2PCIX,
    PT_PCIX2PCIE
  } amd_devport_t;

  typedef struct {
    bit        is_64;
    bit        is_pftch;
    string     sz_str;
    bit [63:0] sz;
    bit [63:0] base;
  } mem_bar_s;

  typedef struct {
    string     sz_str;
    bit [31:0] sz;
    bit [31:0] base;
  } io_bar_s;

  typedef struct { 
    string     sz_str;
    bit [31:0] sz;
    bit [31:0] base;
    bit        enable;
  } erom_bar_s;

  typedef enum bit [7:0] {
    NULL_REG_BLOCK   = 'h00,
    COMPONENT_REG    = 'h01,
    BAR_VIRT_ACL_REG = 'h02,
    CXL_DEVICE_REG   = 'h03,
    CPMU_REG         = 'h04,
    DVSEC_REG        = 'hFF
  } cxl_reg_blk_id_e;

  typedef struct packed {
    cxl_reg_blk_id_e id;
    bit [ 2: 0]      bar;
    bit [63:16]      offset;     //from BAR; 64K offset 
    bit [63: 0]      abs_offset; //from BAR; absolute
    bit [63: 0]      base;       //BAR+abs_offset
  } cxl_reg_blk_s;

  typedef enum bit [15:0] {
    DEV_STS_REGS    = 'h0001,  
    PRI_MBX_REGS    = 'h0002,  
    SEC_MBX_REGS    = 'h0003,  
    MEMDEV_STS_REGS = 'h4000
  } cxl_dev_cap_id_e;

  typedef struct {
    cxl_dev_cap_id_e id;
    bit [ 7: 0]      version;
    bit [31: 0]      offset; //from start of CXL device registers
    bit [31: 0]      len;
    bit [63: 0]      base; //BAR+RegLocOffset+offset
  } cxl_dev_cap_s;

  typedef struct {
    string     sz_str;
    bit [31:0] sz;
    bit [31:0] base;
  } mem_range32_s;

  typedef struct {
    string     sz_str;
    bit [63:0] sz;
    bit [63:0] base;
  } mem_range64_s;

  // All relevant info about a capability struct
  typedef struct packed {
    pcie_capid_e id;
    bit [ 7:0]   base;
    bit [ 3:0]   version;
  } cap_s;

  // All relevant info about an ext. capability structure
  typedef struct packed {
    pcie_ecapid_e id;
    bit [11:0]    base;
    bit [ 3:0]    version;
    // only relevant if DVSEC
    bit [15:0]    dvsec_vendid;
    bit [ 3:0]    dvsec_rev;
    bit [11:0]    dvsec_len;
    bit [15:0]    dvsec_id;
  } ecap_s;

  typedef struct packed {
    bit        enable;
    bit        func_mask;
    bit [11:0] nvec;
    bit [ 2:0] table_bar;
    bit [31:0] table_offset;
    bit [63:0] table_base; //including BAR
    bit [ 2:0] pba_bar;
    bit [31:0] pba_offset;
    bit [63:0] pba_base;   //including BAR
  } msix_s;

  typedef struct {
    bit        vf_enable;
    bit        vf_mse;
    bit [15:0] total_vfs;
    bit [15:0] num_vfs;
    bit [15:0] first_vf_offset;
    bit [15:0] vf_stride;
    string     sys_page_sz_str;
    bit [43:0] sys_page_sz;
    mem_bar_s  vf_membar[bit [2:0]];
    io_bar_s   vf_iobar [bit [2:0]];
  } sriov_s; 

  typedef enum bit [2:0] {
    CPL_SC, CPL_UR, CPL_RRS, CPL_CA='d4,
    GENERAL_ERR, //any unspecified err
    NO_CPL='d7 //using this locally to this agent
  } cpl_sts_e;

  // CONFIG SPACE REQUEST HEADER ; always 3 DW
  //  - NON FLIT MODE HEADER
  // Alphanumeric Chars: !=T9, @=T8, #=A2, $=TH, %=TD, ^=EP, &=ATTR
  // Constants: FMT=0_0 TC=0 A2=0, ATTR=0, AT=0, LEN=1, L_BE=0
  // | Byte N          | Byte N+1        | Byte N+2        | Byte N+3        |
  // | 7 6 5 4 3 2 1 0 | 7 6 5 4 3 2 1 0 | 7 6 5 4 3 2 1 0 | 7 6 5 4 3 2 1 0 | 
  // | ----------------|-----------------|-----------------|-----------------|
  // | FMT  | TYPE     | !| TC  |@|#|R|$ | %|^|&  |AT | LEN                  |
  // | REQ_ID                            | TAG             | L_BE   | F_BE   |
  // | DST_ID                            | R      | REGNUM              | R  |
  // =========================================================================
  //  - FLIT MODE HEADER
  // Alphanumeric Chars: !=EP, @=DSV
  // Constants: TC=0, LEN=1
  // | Byte N          | Byte N+1        | Byte N+2        | Byte N+3        |
  // | 7 6 5 4 3 2 1 0 | 7 6 5 4 3 2 1 0 | 7 6 5 4 3 2 1 0 | 7 6 5 4 3 2 1 0 | 
  // | ----------------|-----------------|-----------------|-----------------|
  // | TYPE            | TC   | OHC      | TS   |ATTR | LEN                  |
  // | REQ_ID                            | !|R| TAG                          |
  // | DST_BDF                           | R      | REGNUM              | R  |
  // | DST_SEG         | R               | @| R            | L_BE   | F_BE   | (OHC-A3)
  typedef union packed {
    // Non Flit Mode
    struct packed {
      struct packed {
        bit [ 2:0] fmt;
        bit [ 4:0] type_;
        bit        t9;   //tag[9]
        bit [ 2:0] tc;   //Traffic Class
        bit        t8;   //tag[8]
        bit        a2;   //attr[2]
        bit        RSVD0;
        bit        th;   //TLP Hints
        bit        td;   //TLP Digest
        bit        ep;   //Error Poisoned
        bit [ 1:0] attr;
        bit [ 1:0] at;
        bit [ 9:0] len;
      } dw0;
      struct packed {
        bit [15:0] req_id;
        bit [ 7:0] tag;
        bit [ 3:0] l_be;
        bit [ 3:0] f_be;
      } dw1;
      struct packed {
        bit [15:0] dst_id;
        bit [ 3:0] RSVD1;
        bit [11:2] regnum;
        bit [ 1:0] RSVD2;
      } dw2;
    } nfm;
    // Flit Mode
    struct packed {
      struct packed {
        bit [ 7:0] type_;
        bit [ 2:0] tc;
        bit [ 4:0] ohc; //Orthogonal Header Content
        bit [ 2:0] ts;  //Trailer Size
        bit [ 2:0] attr;
        bit [ 9:0] len;
      } dw0;
      struct packed {
        bit [15:0] req_id;
        bit        ep;
        bit        RSVD0;
        bit [13:0] tag;
      } dw1;
      struct packed {
        bit [15:0] dst_bdf;
        bit [ 3:0] RSVD1;
        bit [11:2] regnum;
        bit [ 1:0] RSVD2;
      } dw2;
    } fm;
  } cfg_hdr_u;

  // MEMORY SPACE REQUEST HEADER ; 3 or 4 DW
  //  - NON FLIT MODE HEADER
  // Alphanumeric Chars: !=T9, @=T8, #=A2, $=TH, %=TD, ^=EP, &=ATTR
  // Constants: FMT=0_0 TC=0 A2=0, ATTR=0, AT=0, LEN=1, L_BE=0
  // | Byte N          | Byte N+1        | Byte N+2        | Byte N+3        |
  // | 7 6 5 4 3 2 1 0 | 7 6 5 4 3 2 1 0 | 7 6 5 4 3 2 1 0 | 7 6 5 4 3 2 1 0 | 
  // | ----------------|-----------------|-----------------|-----------------|
  // | FMT  | TYPE     | !| TC  |@|#|R|$ | %|^|&  |AT | LEN                  |
  // | REQ_ID                            | TAG             | L_BE   | F_BE   |
  // | ********************************************************************* |
  // | ADDR[31: 0]                                                      | PH | DW2: (Option A)
  // | ********************************************************************* |
  // | ADDR[63:32]                                                           | DW2: (Option B)
  // | ADDR[31: 0]                                                      | PH | DW3: (Option B)
  // =========================================================================
  //  - FLIT MODE HEADER
  // Alphanumeric Chars: !=EP, @=DSV
  // Constants: TC=0, LEN=1
  // | Byte N          | Byte N+1        | Byte N+2        | Byte N+3        |
  // | 7 6 5 4 3 2 1 0 | 7 6 5 4 3 2 1 0 | 7 6 5 4 3 2 1 0 | 7 6 5 4 3 2 1 0 | 
  // | ----------------|-----------------|-----------------|-----------------|
  // | TYPE            | TC   | OHC      | TS   |ATTR | LEN                  |
  // | REQ_ID                            | !|R| TAG                          |
  // | ********************************************************************* |
  // | ADDR[31: 0]                                                      | AT | DW2: (Option A)
  // | ********************************************************************* |
  // | ADDR[63:32]                                                           | DW2: (Option B)
  // | ADDR[31: 0]                                                      | AT | DW3: (Option B)
  typedef union packed {
    // Non Flit Mode
    struct packed {
      struct packed {
        bit [ 2:0] fmt;
        bit [ 4:0] type_;
        bit        t9;   //tag[9]
        bit [ 2:0] tc;   //Traffic Class
        bit        t8;   //tag[8]
        bit        a2;   //attr[2]
        bit        RSVD0;
        bit        th;   //TLP Hints
        bit        td;   //TLP Digest
        bit        ep;   //Error Poisoned
        bit [ 1:0] attr;
        bit [ 1:0] at;
        bit [ 9:0] len;
      } dw0;
      struct packed {
        bit [15:0] req_id;
        bit [ 7:0] tag;
        bit [ 3:0] l_be;
        bit [ 3:0] f_be;
      } dw1;
      union packed {
        bit [63:32] addr64;
        struct packed {
          bit [31:2] addr;
          bit [ 1:0] ph;
        } addr32;
      } dw2;
      union packed {
        bit [31:0] PAD; //not applicable
        struct packed {
          bit [31:2] addr;
          bit [ 1:0] ph;
        } addr32;
      } dw3;
    } nfm;
    // Flit Mode
    struct packed {
      struct packed {
        bit [ 7:0] type_;
        bit [ 2:0] tc;
        bit [ 4:0] ohc; //Orthogonal Header Content
        bit [ 2:0] ts;  //Trailer Size
        bit [ 2:0] attr;
        bit [ 9:0] len;
      } dw0;
      struct packed {
        bit [15:0] req_id;
        bit        ep;
        bit        RSVD0;
        bit [13:0] tag;
      } dw1;
      union packed {
        bit [63:32] addr64;
        struct packed {
          bit [31:2] addr;
          bit [ 1:0] at;
        } addr32;
      } dw2;
      union packed {
        bit [31:0] PAD; //not applicable
        struct packed {
          bit [31:2] addr;
          bit [ 1:0] at;
        } addr32;
      } dw3;
    } fm;
  } mem_hdr_u;

  // OHC-A1
  typedef struct packed {
    bit         nw;  //No Write; RSVD unless Translation Request
    bit         pv;  //PASID Valid; PASID unknown/unassigned -> 0
    bit         pmr; //Privileged Mode Requested; RSVD unless Translation or Page Request
    bit         er;  //Execute Requested; RSVD unless Translation or Page Request
    bit [19: 0] pasid;
    bit [ 3: 0] l_be;
    bit [ 3: 0] f_be;
  } ohc_a1_s;
  
  // OHC-A2
  typedef struct packed {
    bit [23: 0] RSVD; 
    bit [ 3: 0] l_be;
    bit [ 3: 0] f_be;
  } ohc_a2_s;
  
  // OHC-A3
  typedef struct packed {
    bit [ 7: 0] dst_seg; //Destination Segment; RSVD if dsv=0
    bit [ 7: 0] RSVD0;
    bit         dsv;     //Destination Segment Valid
    bit [ 6: 0] RSVD1;
    bit [ 3: 0] l_be;
    bit [ 3: 0] f_be;
  } ohc_a3_s;
  
  // OHC-A4
  typedef struct packed {
    bit [ 7: 0] dst_seg; //Destination Segment; RSVD if dsv=0
    bit [15: 8] pasid_m; //PASID RSVD if psv=0
    bit         dsv;     //Destination Segment Valid
    bit         pv;      //PASID Valid
    bit [ 1: 0] RSVD;
    bit [19:16] pasid_u; //PASID RSVD if psv=0
    bit [ 7: 0] pasid_l; //PASID RSVD if psv=0
  } ohc_a4_s;
  
  // OHC-A5
  typedef struct packed {
    bit [ 7: 0] dst_seg; //Destination Segment; RSVD if dsv=0
    bit [ 7: 0] cpl_seg; //Completer Segment
    bit         dsv;     //Destination Segment Valid
    bit [ 9: 0] RSVD;
    bit [ 1: 0] la;      //Lower Address
    bit [ 2: 0] cpl_sts; 
  } ohc_a5_s;
  
  // All OHC-A* content
  typedef union packed {
    ohc_a1_s  a1;
    ohc_a2_s  a2;
    ohc_a3_s  a3;
    ohc_a4_s  a4;
    ohc_a5_s  a5;
  } ohc_a_u;
  
  // OHC-B
  typedef struct packed {
    bit [ 7: 0] RSVD; 
    bit [15: 0] st;   //Steering Tag
    bit [ 1: 0] ph;   //Processing Hint
    bit [ 1: 0] hv;   //Hints Valid
    bit [ 2: 0] ama;  //??? RSVD if av=0
    bit         av;   //???
  } ohc_b_s;
  
  // OHC-C
  typedef struct packed {
    bit [ 7: 0] req_seg; //Requester Segment
    bit [ 7: 0] pr_sent_cntr;
    bit [ 7: 0] stream_id;
    bit         RSVD0;
    bit [ 2: 0] substream;
    bit         rsv;
    bit         RSVD1;
    bit         k;
    bit         t;
  } ohc_c_s;
  
  // Defined for OHC-E
  typedef enum bit [3:0] {
    NO_ENTRY, E2E_PFIX_DW, NO_E2, NO_E3, NO_E4, NO_E5, NO_E6, NO_E7, 
    NO_E8, NO_E9, NO_E10, NO_E11, NO_E12, NO_E13, NO_E14, NO_E15
  } ohc_e_dw_t;
  
  typedef enum bit [3:0] {TPH, PASID, IDE, VEND_PFX_E0=4'hE, VEND_PFX_E1
  } e2e_pfx_t;
  
  // - TPH
  // - PASID
  // - IDE
  typedef struct packed { bit [23:0] fixme; } pfx_tph_t;
  typedef struct packed { bit [23:0] fixme; } pfx_pasid_t;
  typedef struct packed { bit [23:0] fixme; } pfx_ide_t;
  
  // OHC-E: an End-to-End TLP Prefix
  typedef struct packed {
    ohc_e_dw_t       type_;
    e2e_pfx_t        e2e_type;
    union packed {
      bit [ 1: 3][7:0] byte_;
      pfx_tph_t        tph;
      pfx_pasid_t      pasid;
      pfx_ide_t        ide;
    } fields;
  } ohc_e_s;
  
  // OHC-E*; Chunks of End-to-End TLP Prefixes
  typedef ohc_e_s ohc_e1_s; 
  typedef struct packed { 
    ohc_e1_s pfx0;
    ohc_e1_s pfx1;
  } ohc_e2_s;
  typedef struct packed { 
    ohc_e1_s pfx0;
    ohc_e1_s pfx1;
    ohc_e1_s pfx2;
    ohc_e1_s pfx3;
  } ohc_e4_s;

endpackage
