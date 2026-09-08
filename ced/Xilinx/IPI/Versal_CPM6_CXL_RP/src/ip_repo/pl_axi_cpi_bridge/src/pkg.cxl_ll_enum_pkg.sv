package cxl_ll_enum_pkg;

  // Enumerates all fields of transaction layer
  import cxl_tl_enum_pkg::*;

  /* Flit Type */
  typedef enum logic {PROTOCOL, CONTROL} flit68_t;
  
  /* Slot Formats */ 
  typedef enum logic [2:0] {H0, H1, H2, H3, H4, H5, H6} hslot68_fmt_t; 
  typedef enum logic [2:0] {G0, G1, G2, G3, G4, G5, G6} gslot68_fmt_t; 
  
  /* 68B Flit Header */
  typedef struct packed {
    logic [  3: 0] datcrd;
    logic [  3: 0] reqcrd;
    logic [  3: 0] rspcrd;
    logic [  2: 0] rsvd1;
    struct packed {
      gslot68_fmt_t slot3;
      gslot68_fmt_t slot2;
      gslot68_fmt_t slot1;
      hslot68_fmt_t slot0;
    } fmt;
    logic          sz;
    logic          be;
    logic          ak;
    logic          rsvd0;
    flit68_t       typ;
  } flit68_hdr_t;

  // Link Layer Control Flit :: LLCTRL
  typedef enum logic [3:0] {LLCRD=4'h0, RETRY=4'h1, IDE=4'h2, INIT=4'hC} llctrl_t;
  typedef enum logic [3:0] {_ACK=4'h1} llcrd_subtype_t;
  typedef enum logic [3:0] {_RIDLE=4'h0, _REQ=4'h1, _RACK=4'h2, _FRAME=4'h3} retry_subtype_t;
  typedef enum logic [3:0] {_IDLE=4'h0, _START=4'h1, _TMAC=4'h2} ide_subtype_t;
  typedef enum logic [3:0] {_PARAM=4'h8} init_subtype_t;
  
  /* CXL Transaction Layer 68B */
  // CXL.cache : H2D
  typedef struct packed {
    logic [ 1:0]    rsvd;
    logic [11:0]    uqid;
    logic [51:6]    addr;
    h2dreq_opcode_t opcode;
    logic           val;
  } h2dreq68_t;
  typedef struct packed {
    logic [ 7:0]    rsvd;
    logic           go_e;
    logic           poi;
    logic           ch;
    logic [11:0]    cqid;
    logic           val;
  } h2ddat68_hdr_t;
  typedef struct packed {
    logic           rsvd;
    logic [11:0]    cqid;
    rsp_pre_t       rsp_pre;
    logic [11:0]    rspdata;
    h2drsp_opcode_t opcode;
    logic           val;
  } h2drsp68_t;
  // CXL.cache : D2H
  typedef struct packed {
    logic [ 6:0]    rsvd1;
    logic [51:6]    addr;
    logic [ 6:0]    rsvd0;
    logic           nt;
    logic [11:0]    cqid;
    d2hreq_opcode_t opcode;
    logic           val;
  } d2hreq68_t;
  typedef struct packed {
    logic           rsvd;
    logic           poi;
    logic           bg;
    logic           ch;
    logic [11:0]    uqid;
    logic           val;
  } d2hdat68_hdr_t;
  typedef struct packed {
    logic [ 1:0]    rsvd;
    logic [11:0]    uqid;
    d2hrsp_opcode_t opcode;
    logic           val;
  } d2hrsp68_t;
  // CXL.mem : M2S
  typedef struct packed {
    logic [ 5:0]    rsvd;
    logic [ 3:0]    ldid;
    logic [ 1:0]    tc;
    logic           poi;
    logic [51:6]    addr;
    logic [15:0]    tag;
    mem_metavalue_t metavalue;
    mem_metafield_t metafield;
    mem_snptype_t   snptype;
    m2srwd_opcode_t memop;
    logic           val;
  } m2srwd68_hdr_t;
  typedef struct packed {
    logic [ 5:0]    rsvd;
    logic [ 3:0]    ldid;
    logic [ 1:0]    tc;
    logic [51:5]    addr;
    logic [15:0]    tag;
    mem_metavalue_t metavalue;
    mem_metafield_t metafield;
    mem_snptype_t   snptype;
    m2sreq_opcode_t memop;
    logic           val;
  } m2sreq68_t;
  // CXL.mem : S2M
  typedef struct packed {
    mem_devload_t   devload;
    logic [ 3:0]    ldid;
    logic [15:0]    tag;
    mem_metavalue_t metavalue;
    mem_metafield_t metafield;
    s2mndr_opcode_t opcode;
    logic           val;
  } s2mndr68_t;
  typedef struct packed {
  //mem_devload_t   devload;
    logic [ 3:0]    ldid;
    logic [15:0]    tag;
    mem_metavalue_t metavalue;
    mem_metafield_t metafield;
    s2mndr_opcode_t opcode;
    logic           val;
  } s2mndr_frac_t; //for C2H H4/G4/G5; frac := "fractured"
  typedef struct packed {
    logic [ 8:0]    rsvd;
    mem_devload_t   devload;
    logic [ 3:0]    ldid;
    logic           poi;
    logic [15:0]    tag;
    mem_metavalue_t metavalue;
    mem_metafield_t metafield;
    s2mdrs_opcode_t opcode;
    logic           val;
  } s2mdrs68_hdr_t;

  /* Header Slot */
  // Host to Card
  typedef union packed {
    struct packed {
      h2drsp68_t     h2drsp;
      h2dreq68_t     h2dreq;
      flit68_hdr_t   hdr;
    } H0;
    struct packed {
      logic [7:0]      rsvd;
      h2drsp68_t       h2drsp_1;
      h2drsp68_t       h2drsp_0;
      h2ddat68_hdr_t   h2ddat_hdr;
      flit68_hdr_t     hdr;
    } H1;
    struct packed {
      logic [7:0]      rsvd;
      h2ddat68_hdr_t   h2ddat_hdr;
      h2dreq68_t       h2dreq;
      flit68_hdr_t     hdr;
    } H2;
    struct packed {
      h2ddat68_hdr_t   h2ddat_hdr_3;
      h2ddat68_hdr_t   h2ddat_hdr_2;
      h2ddat68_hdr_t   h2ddat_hdr_1;
      h2ddat68_hdr_t   h2ddat_hdr_0;
      flit68_hdr_t     hdr;
    } H3;
    struct packed {
      logic [8:0]      rsvd;
      m2srwd68_hdr_t   m2srwd_hdr;
      flit68_hdr_t     hdr;
    } H4;
    struct packed {
      logic [8:0]    rsvd;
      m2sreq68_t     m2sreq;
      flit68_hdr_t   hdr;
    } H5;
    struct packed {
      logic [95:0]   mac;
      flit68_hdr_t   hdr;
    } H6;
    struct packed {
      logic [95:0]   dontcare;
      flit68_hdr_t   hdr;
    } Hx; //Hx is when we don't care what the header slot type is
  } h2c_hslot68_u;
  // Card to Host
  typedef union packed {
    struct packed {
      logic [8:0]      rsvd;
      s2mndr68_t       s2mndr;
      d2hrsp68_t       d2hrsp_1;
      d2hrsp68_t       d2hrsp_0;
      d2hdat68_hdr_t   d2hdat_hdr;
      flit68_hdr_t     hdr;
    } H0;
    struct packed {
      d2hdat68_hdr_t   d2hdat_hdr;
      d2hreq68_t       d2hreq;
      flit68_hdr_t     hdr;
    } H1;
    struct packed {
      logic [7:0]      rsvd;
      d2hrsp68_t       d2hrsp;
      d2hdat68_hdr_t   d2hdat_hdr_3;
      d2hdat68_hdr_t   d2hdat_hdr_2;
      d2hdat68_hdr_t   d2hdat_hdr_1;
      d2hdat68_hdr_t   d2hdat_hdr_0;
      flit68_hdr_t     hdr;
    } H2;
    struct packed {
      logic [25:0]     rsvd;
      s2mndr68_t       s2mndr;
      s2mdrs68_hdr_t   s2mdrs_hdr;
      flit68_hdr_t     hdr;
    } H3;
    struct packed {
      logic [35:0]    rsvd;
      mem_devload_t   s2mndr_0_devload;
      s2mndr68_t      s2mndr_1;
      s2mndr_frac_t   s2mndr_0;
      flit68_hdr_t    hdr;
    } H4;
    struct packed {
      logic [15:0]     rsvd;
      s2mdrs68_hdr_t   s2mdrs_hdr_1;
      s2mdrs68_hdr_t   s2mdrs_hdr_0;
      flit68_hdr_t     hdr;
    } H5;
    struct packed {
      logic [95:0]   mac;
      flit68_hdr_t   hdr;
    } H6;
    struct packed {
      logic [95:0]   dontcare;
      flit68_hdr_t   hdr;
    } HX; //HX is when we want to examine header only, this says we don't care
          //what the header actually is
  } c2h_hslot68_u;

  /* Generic Slot */
  // Host to Card
  typedef union packed {
    union packed {
      struct packed {
        logic [127:0] data; 
      } DATA; 
      struct packed {
        logic [63:0] rsvd;
        logic [63:0] be;
      } BE;
    } G0;
    struct packed {
      h2drsp68_t     h2drsp_3;
      h2drsp68_t     h2drsp_2;
      h2drsp68_t     h2drsp_1;
      h2drsp68_t     h2drsp_0;
    } G1;
    struct packed {
      logic [7:0]      rsvd;
      h2drsp68_t       h2drsp;
      h2ddat68_hdr_t   h2ddat_hdr;
      h2dreq68_t       h2dreq;
    } G2;
    struct packed {
      h2drsp68_t       h2drsp;
      h2ddat68_hdr_t   h2ddat_hdr_3;
      h2ddat68_hdr_t   h2ddat_hdr_2;
      h2ddat68_hdr_t   h2ddat_hdr_1;
      h2ddat68_hdr_t   h2ddat_hdr_0;
    } G3;
    struct packed {
      logic [15:0]     rsvd1;
      h2ddat68_hdr_t   h2ddat_hdr;
      logic            rsvd0;
      m2sreq68_t       m2sreq;
    } G4;
    struct packed {
      logic [7:0]     rsvd1;
      h2drsp68_t      h2drsp;
      logic           rsvd0;
      m2srwd68_hdr_t  m2srwd_hdr;
    } G5;
  } h2c_gslot68_u;
  // Card to Host
  typedef union packed {
    union packed {
      struct packed {
        logic [127:0] data; 
      } DATA; 
      struct packed {
        logic [63:0] rsvd;
        logic [63:0] be;
      } BE;
    } G0;
    struct packed {
      logic [8:0]   rsvd;
      d2hrsp68_t    d2hrsp_1;
      d2hrsp68_t    d2hrsp_0;
      d2hreq68_t    d2hreq;
    } G1;
    struct packed {
      logic [11:0]     rsvd;
      d2hrsp68_t       d2hrsp;
      d2hdat68_hdr_t   d2hdat_hdr;
      d2hreq68_t       d2hreq;
    } G2;
    struct packed {
      logic [59:0]     rsvd;
      d2hdat68_hdr_t   d2hdat_hdr_3;
      d2hdat68_hdr_t   d2hdat_hdr_2;
      d2hdat68_hdr_t   d2hdat_hdr_1;
      d2hdat68_hdr_t   d2hdat_hdr_0;
    } G3;
    struct packed {
      logic [27:0]    rsvd;
      mem_devload_t   s2mndr_0_devload;
      s2mndr68_t      s2mndr_1;
      s2mndr_frac_t   s2mndr_0;
      s2mdrs68_hdr_t  s2mdrs_hdr;
    } G4;
    struct packed {
      logic [67:0]    rsvd;
      mem_devload_t   s2mndr_0_devload;
      s2mndr68_t      s2mndr_1;
      s2mndr_frac_t   s2mndr_0;
    } G5;
    struct packed {
      logic [7:0]     rsvd;
      s2mdrs68_hdr_t  s2mdrs_hdr_2;
      s2mdrs68_hdr_t  s2mdrs_hdr_1;
      s2mdrs68_hdr_t  s2mdrs_hdr_0;
    } G6;
  } c2h_gslot68_u;

  // Data chunk
  typedef union packed {
    struct packed {
      logic [127:0] data; 
    } DATA; 
    struct packed {
      logic [63:0] rsvd;
      logic [63:0] be;
    } BE;
  } dc68_u;

  // Full flit
  typedef union packed {
    struct packed {
      h2c_gslot68_u GS_3; //GS="generic slot"
      h2c_gslot68_u GS_2; //GS="generic slot"
      h2c_gslot68_u GS_1; //GS="generic slot"
      h2c_hslot68_u HS;   //HS="header slot" 
    } PF; //protocol flit
    struct packed {
      dc68_u   DC_3; //DC="data chunk"
      dc68_u   DC_2; //DC="data chunk"
      dc68_u   DC_1; //DC="data chunk"
      dc68_u   DC_0; //DC="data chunk"
    } ADF; //all-data-flit
    struct packed {
      logic [471:0] dontcare1;
      union packed {
        init_subtype_t  init;
        ide_subtype_t   ide;
        retry_subtype_t retry;
        llcrd_subtype_t llcrd;
      } subtype; 
      llctrl_t     llctrl;
      logic [31:0] dontcare0;
    } CF; //control flit
  } h2c_flit68_u; 

  typedef union packed {
    struct packed {
      c2h_gslot68_u GS_3; //GS="generic slot"
      c2h_gslot68_u GS_2; //GS="generic slot"
      c2h_gslot68_u GS_1; //GS="generic slot"
      c2h_hslot68_u HS;   //HS="header slot" 
    } PF; //protocol flit
    struct packed {
      dc68_u   DC_3; //DC="data chunk"
      dc68_u   DC_2; //DC="data chunk"
      dc68_u   DC_1; //DC="data chunk"
      dc68_u   DC_0; //DC="data chunk"
    } ADF; //all-data-flit
  } c2h_flit68_u; 

  /* CXL Transaction Layer 256B */
  // CXL.cache : H2D
  typedef struct packed {
    logic [ 5:0]    rsvd;
    logic [ 3:0]    cacheid;
    logic [11:0]    uqid;
    logic [51:6]    addr;
    h2dreq_opcode_t opcode;
    logic           val;
  } h2dreq256_t;
  typedef struct packed {
    logic [ 8:0]    rsvd;
    logic [ 3:0]    cacheid;
    logic           go_e;
    logic           poi;
    logic [11:0]    cqid;
    logic           val;
  } h2ddat256_hdr_t;
  typedef struct packed {
    logic [ 4:0]    rsvd;
    logic [ 3:0]    cacheid;
    logic [11:0]    cqid;
    rsp_pre_t       rsp_pre;
    logic [11:0]    rspdata;
    h2drsp_opcode_t opcode;
    logic           val;
  } h2drsp256_t;
  // CXL.cache : D2H
  typedef struct packed {
    logic [ 3:0]    rsvd1;
    logic [51:6]    addr;
    logic [ 2:0]    rsvd0;
    logic [ 3:0]    cacheid;
    logic           nt;
    logic [11:0]    cqid;
    d2hreq_opcode_t opcode;
    logic           val;
  } d2hreq256_t;
  typedef struct packed {
    logic [ 7:0]    rsvd;
    logic           bep;
    logic           poi;
    logic           bg;
    logic [11:0]    uqid;
    logic           val;
  } d2hdat256_hdr_t;
  typedef struct packed {
    logic [ 5:0]    rsvd;
    logic [11:0]    uqid;
    d2hrsp_opcode_t opcode;
    logic           val;
  } d2hrsp256_t;
  // CXL.mem : M2S
  typedef struct packed {
    logic [ 1:0]    tc;
    logic [ 8:0]    rsvd;
    logic [12:0]    ckid;
    logic [ 3:0]    ldid;
    logic           trp;
    logic           poi;
    logic [51:6]    addr;
    logic [15:0]    tag;
    mem_metavalue_t metavalue;
    mem_metafield_t metafield;
    mem_snptype_t   snptype;
    m2srwd_opcode_t memop;
    logic           val;
  } m2srwd256_hdr_t;
  typedef struct packed {
    logic [ 1:0]    tc;
    logic [ 6:0]    rsvd;
    logic [12:0]    ckid;
    logic [ 3:0]    ldid;
    logic [51:6]    addr;
    logic [15:0]    tag;
    mem_metavalue_t metavalue;
    mem_metafield_t metafield;
    mem_snptype_t   snptype;
    m2sreq_opcode_t memop;
    logic           val;
  } m2sreq256_t;
  typedef struct packed {
    logic [ 8:0]      rsvd;
    logic [ 1:0]      lowaddr;
    logic [11:0]      bitag;
    logic [11:0]      biid;
    m2sbirsp_opcode_t opcode;
    logic             val;
  } m2sbirsp256_t;
  // CXL.mem : S2M
  typedef struct packed {
    logic [ 9:0]    rsvd;
    mem_devload_t   devload;
    logic [ 3:0]    ldid;
    logic [15:0]    tag;
    mem_metavalue_t metavalue;
    mem_metafield_t metafield;
    s2mndr_opcode_t opcode;
    logic           val;
  } s2mndr256_t;
  typedef struct packed {
    logic [ 7:0]    rsvd;
    logic           trp;
    logic [ 3:0]    ldid;
    mem_devload_t   devload;
    logic           poi;
    logic [15:0]    tag;
    mem_metavalue_t metavalue;
    mem_metafield_t metafield;
    s2mdrs_opcode_t opcode;
    logic           val;
  } s2mdrs256_hdr_t;
  typedef struct packed {
    logic [ 8:0]      rsvd;
    logic [51:6]      addr;
    logic [11:0]      bitag;
    logic [11:0]      biid;
    s2mbisnp_opcode_t opcode;
    logic             val;
  } s2mbisnp256_t;

  // Data chunk
  typedef union packed {
    struct packed {
      logic [127:0] data; 
    } DATA; 
    struct packed {
      logic [63:0] rsvd;
      logic [63:0] be;
    } BE;
    struct packed {
      logic [31:0] rsvd;
      logic [31:0] emd;
      logic [63:0] be;
    } BE_EMD;
    struct packed {
      logic [95:0] rsvd;
      logic [31:0] emd;
    } EMD;
    struct packed {
      logic [31:0] rsvd;
      logic [31:0] emd2;
      logic [31:0] emd1;
      logic [31:0] emd0;
    } EMD3;
  } dc256_u;

  typedef union packed {
    struct packed {
      logic [35:0]  rsvd;
      h2dreq256_t   h2dreq;
    } H0;
    struct packed {
      logic [27:0]  rsvd;
      h2drsp256_t   h2drsp_1;
      h2drsp256_t   h2drsp_0;
    } H1;
    struct packed {
      logic [ 7:0]  rsvd;
      d2hrsp256_t   d2hrsp;
      d2hreq256_t   d2hreq;
    } H2;
    struct packed {
      logic [11:0]  rsvd;
      d2hrsp256_t   d2hrsp_3;
      d2hrsp256_t   d2hrsp_2;
      d2hrsp256_t   d2hrsp_1;
      d2hrsp256_t   d2hrsp_0;
    } H3;
    struct packed {
      logic [ 7:0]  rsvd;
      m2sreq256_t   m2sreq;
    } H4;
    struct packed {
      logic [27:0]    rsvd;
      m2sbirsp256_t   m2sbirsp_1;
      m2sbirsp256_t   m2sbirsp_0;
    } H5;
    struct packed {
      logic [23:0]    rsvd;
      s2mbisnp256_t   s2mbisnp;
    } H6;
    struct packed {
      logic [27:0]  rsvd;
      s2mndr256_t   s2mndr_1;
      s2mndr256_t   s2mndr_0;
    } H7;
    struct packed {
      logic [23:0]    rsvd;
      h2ddat256_hdr_t h2ddat_hdr_2;
      h2ddat256_hdr_t h2ddat_hdr_1;
      h2ddat256_hdr_t h2ddat_hdr_0;
    } H12;
    struct packed {
      logic [11:0]    rsvd;
      d2hdat256_hdr_t d2hdat_hdr_3;
      d2hdat256_hdr_t d2hdat_hdr_2;
      d2hdat256_hdr_t d2hdat_hdr_1;
      d2hdat256_hdr_t d2hdat_hdr_0;
    } H13;
    struct packed {
      logic [ 3:0]    rsvd;
      m2srwd256_hdr_t m2srwd_hdr;
    } H14;
    struct packed {
      logic [27:0]    rsvd;
      s2mdrs256_hdr_t s2mdrs_hdr_1;
      s2mdrs256_hdr_t s2mdrs_hdr_0;
    } H15;
  } hslot256_u;

  typedef union packed {
    struct packed {
      logic [11:0]  rsvd;
      h2drsp256_t   h2drsp;
      h2dreq256_t   h2dreq;
    } G0;
    struct packed {
      logic [ 3:0]  rsvd;
      h2drsp256_t   h2drsp_2;
      h2drsp256_t   h2drsp_1;
      h2drsp256_t   h2drsp_0;
    } G1;
    struct packed {
      d2hrsp256_t   d2hrsp_1;
      d2hrsp256_t   d2hrsp_0;
      d2hreq256_t   d2hreq;
    } G2;
    struct packed {
      logic [27:0]  rsvd;
      d2hrsp256_t   d2hrsp_3;
      d2hrsp256_t   d2hrsp_2;
      d2hrsp256_t   d2hrsp_1;
      d2hrsp256_t   d2hrsp_0;
    } G3;
    struct packed {
      logic [23:0]  rsvd;
      m2sreq256_t   m2sreq;
    } G4;
    struct packed {
      logic [ 3:0]    rsvd;
      m2sbirsp256_t   m2sbirsp_2;
      m2sbirsp256_t   m2sbirsp_1;
      m2sbirsp256_t   m2sbirsp_0;
    } G5;
    struct packed {
      s2mndr256_t     s2mndr;
      s2mbisnp256_t   s2mbisnp;
    } G6;
    struct packed {
      logic [ 3:0]  rsvd;
      s2mndr256_t   s2mndr_2;
      s2mndr256_t   s2mndr_1;
      s2mndr256_t   s2mndr_0;
    } G7;
    struct packed {
      logic [11:0]    rsvd;
      h2ddat256_hdr_t h2ddat_hdr_3;
      h2ddat256_hdr_t h2ddat_hdr_2;
      h2ddat256_hdr_t h2ddat_hdr_1;
      h2ddat256_hdr_t h2ddat_hdr_0;
    } G12;
    struct packed {
      logic [27:0]    rsvd;
      d2hdat256_hdr_t d2hdat_hdr_3;
      d2hdat256_hdr_t d2hdat_hdr_2;
      d2hdat256_hdr_t d2hdat_hdr_1;
      d2hdat256_hdr_t d2hdat_hdr_0;
    } G13;
    struct packed {
      logic [19:0]    rsvd;
      m2srwd256_hdr_t m2srwd_hdr;
    } G14;
    struct packed {
      logic [ 3:0]    rsvd;
      s2mdrs256_hdr_t s2mdrs_hdr_2;
      s2mdrs256_hdr_t s2mdrs_hdr_1;
      s2mdrs256_hdr_t s2mdrs_hdr_0;
    } G15;
  } gslot256_u;

  typedef struct packed {
    logic rsvd;
    union packed {
      logic [4:0] s2mndr;
      logic [4:0] m2sbirsp;
      logic [4:0] d2hrsp;
      logic [4:0] h2drsp;
    } UPR;
    union packed {
      logic [4:0] s2mdrs;
      logic [4:0] m2srwd;
      logic [4:0] d2hdat;
      logic [4:0] h2ddat;
    } MID;
    union packed {
      logic [4:0] s2mbisnp;
      logic [4:0] m2sreq;
      logic [4:0] d2hreq;
      logic [4:0] h2dreq;
    } LWR;
  } crd256_t;

  // Full flit contains 16 slots (S_[0-15]) and every slot except S0 and S15
  // can be used for implicit data.
  typedef struct packed {
    struct packed {
      logic [47:0]  FEC;
      logic [63:0]  CRC;
      crd256_t      CRD;
    } S15;
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } SLOT;
    } S14;
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } SLOT;
    } S13;
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } SLOT;
    } S12;
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } SLOT;
    } S11;
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } SLOT;
    } S10;
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } SLOT;
    } S9;
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } SLOT;
    } S8;
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } SLOT;
    } S7;
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } SLOT;
    } S6;
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } SLOT;
    } S5;
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } SLOT;
    } S4;
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } SLOT;
    } S3;
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } SLOT;
    } S2;
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } SLOT;
    } S1;
    struct packed {
      struct packed {
        hslot256_u  SLOT;
        logic [3:0] slotfmt;
      } H; 
      logic [15:0] HDR;
    } S0;
  } flit256_t; 

  // NFI is less than 256B, so it operates on "slot-sets"
  // There is a low (L), mid (M), and upper (U) slot-set (SET_[L,M,U\)
  // Within each slot-set, there is slot offset 0, 1, 2, and 3 slot (S_[0-3])
  typedef union packed {
    struct packed {
      struct packed {
        logic [47:0]  FEC;
        logic [63:0]  CRC;
        crd256_t      CRD;
      } S_3;
      union packed {
        dc256_u DATA;
        struct packed {
          gslot256_u  slot;
          logic [3:0] slotfmt;
        } G;
      } S_2;
      union packed {
        dc256_u DATA;
        struct packed {
          gslot256_u  slot;
          logic [3:0] slotfmt;
        } G;
      } S_1;
      union packed {
        dc256_u DATA;
        struct packed {
          gslot256_u  slot;
          logic [3:0] slotfmt;
        } G;
      } S_0;
    } SET_H; 
    struct packed {
      union packed {
        dc256_u DATA;
        struct packed {
          gslot256_u  slot;
          logic [3:0] slotfmt;
        } G;
      } S_3;
      union packed {
        dc256_u DATA;
        struct packed {
          gslot256_u  slot;
          logic [3:0] slotfmt;
        } G;
      } S_2;
      union packed {
        dc256_u DATA;
        struct packed {
          gslot256_u  slot;
          logic [3:0] slotfmt;
        } G;
      } S_1;
      union packed {
        dc256_u DATA;
        struct packed {
          gslot256_u  slot;
          logic [3:0] slotfmt;
        } G;
      } S_0;
    } SET_M; 
    struct packed {
      union packed {
        dc256_u DATA;
        struct packed {
          gslot256_u  slot;
          logic [3:0] slotfmt;
        } G;
      } S_3;
      union packed {
        dc256_u DATA;
        struct packed {
          gslot256_u  slot;
          logic [3:0] slotfmt;
        } G;
      } S_2;
      union packed {
        dc256_u DATA;
        struct packed {
          gslot256_u  slot;
          logic [3:0] slotfmt;
        } G;
      } S_1;
      struct packed {
        struct packed {
          hslot256_u  slot;
          logic [3:0] slotfmt;
        } H; 
        logic [15:0] HDR;
      } S_0;
    } SET_L;
  } slotset_u;

/* This may preferable compared to the slotset_u above,
   could switch all references in flit_endec RTL

  typedef struct packed {
    // Slot 3/7/11/(15)
    union packed {
      union packed {
        dc256_u DATA;
        struct packed {
          gslot256_u  slot;
          logic [3:0] slotfmt;
        } G;
      } S_D;
      struct packed {
        logic [47:0]  FEC;
        logic [63:0]  CRC;
        crd256_t      CRD;
      } S_15;
    } U_D;
    // Slot 2/6/10/14
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } G;
    } S_C;
    // Slot 1/5/9/13
    union packed {
      dc256_u DATA;
      struct packed {
        gslot256_u  slot;
        logic [3:0] slotfmt;
      } G;
    } S_B;
    // Slot (0)/4/8/12
    union packed {
      union packed {
        dc256_u DATA;
        struct packed {
          gslot256_u  slot;
          logic [3:0] slotfmt;
        } G;
      } S_A;
      // Slot 0
      struct packed {
        struct packed {
          hslot256_u  slot;
          logic [3:0] slotfmt;
        } H; 
        logic [15:0] HDR;
      } S_0;
    } U_A;
  } slotset_s;
*/

endpackage
