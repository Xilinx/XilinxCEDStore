package cxl31_tl_pkg;

  // CXL.cache TL field enums
  typedef enum logic [2:0] {
    H2DSnpData = 'b001, 
    H2DSnpInv  = 'b010, 
    H2DSnpCur  = 'b011
  } h2dreq_opcode_t;
  typedef enum logic [3:0] {
    WritePull         = 'b0001, 
    GO                = 'b0100,
    GO_WritePull      = 'b0101,
    ExtCmp            = 'b0110,
    GO_WritePull_Drop = 'b1000,
    Fast_GO           = 'b1100,
    Fast_GO_WritePull = 'b1101,
    GO_ERR_WritePull  = 'b1111
  } h2drsp_opcode_t;
  typedef enum logic [4:0] {
    RspIHitI  = 'b00100,
    RspVHitV  = 'b00110,
    RspIHitSE = 'b00101,
    RspSHitSE = 'b00001,
    RspSFwdM  = 'b00111,
    RspIFwdM  = 'b01111,
    RspVFwdV  = 'b10110
  } d2hrsp_opcode_t;
  typedef enum logic [4:0] {
    RdCurr           = 'b00001,
    RdOwn            = 'b00010,
    RdShared         = 'b00011,
    RdAny            = 'b00100,
    RdOwnNoData      = 'b00101,
    ItoMWr           = 'b00110,
    MemWrCch         = 'b00111,
    CLFlush          = 'b01000,
    CleanEvict       = 'b01001,
    DirtyEvict       = 'b01010,
    CleanEvictNoData = 'b01011,
    WOWrInv          = 'b01100,
    WOWrInvF         = 'b01101,
    WrInv            = 'b01110,
    CacheFlushed     = 'b10000
  } d2hreq_opcode_t;
  typedef enum logic [1:0] {
    CacheMiss2LocalCPU = 'b00,
    CacheHit           = 'b01,
    CacheMiss2RemotCPU = 'b10
  } rsp_pre_t;
  // CXL.mem TL field enums
  typedef enum logic [2:0] {
    Cmp           = 'b000,
    CmpS          = 'b001,
    CmpE          = 'b010,
    CmpM          = 'b011,
    BIConflictAck = 'b100,
    CmpTEE        = 'b101
  } s2mndr_opcode_t;
  typedef enum logic [1:0] {
    Meta0State   = 'b00,
    ExtMetaState = 'b01,
    NoOp         = 'b11
  } mem_metafield_t;
  typedef enum logic [1:0] {
    Light    = 'b00,
    Optimal  = 'b01,
    Moderate = 'b10,
    Severe   = 'b11
  } mem_devload_t;
  typedef enum logic [1:0] {
    Invalid = 'b00,
    ExpNoOp = 'b01,
    Any     = 'b10,
    Shared  = 'b11
  } mem_metavalue_t;
  typedef enum logic [2:0] {
    MemData    = 'b000,
    MemDataNXM = 'b001,
    MemDataTEE = 'b010
  } s2mdrs_opcode_t;
  typedef enum logic [3:0] {
    MemWrMem     = 'b0001,
    MemWrPtl     = 'b0010,
    BIConflict   = 'b0100,
    MemRdFill    = 'b0101,
    MemWrTEE     = 'b1001,
    MemWrPtlTEE  = 'b1010,
    MemRdFillTEE = 'b1101
  } m2srwd_opcode_t;
  typedef enum logic [3:0] {
    MemInv       = 'b0000,
    MemRd        = 'b0001,
    MemRdData    = 'b0010,
    MemRdFwd     = 'b0011,
    MemWrFwd     = 'b0100,
    MemRdTEE     = 'b0101,
    MemRdDataTEE = 'b0110,
    MemSpecRd    = 'b1000,
    MemInvNT     = 'b1001,
    MemClnEvct   = 'b1010,
    MemSpecRdTEE = 'b1100,
    TEUpdate     = 'b1101
  } m2sreq_opcode_t;
  typedef enum logic [2:0] {
    M2SSnpNoOp   = 'b000, 
    M2SSnpData   = 'b001, 
    M2SSnpCur    = 'b010, 
    M2SSnpInv    = 'b011 
  } mem_snptype_t;
  typedef enum logic [3:0] {
    BIRspI       = 'b0000,
    BIRspS       = 'b0001,
    BIRspE       = 'b0010,
    BIRspIBlk    = 'b0100,
    BIRspSBlk    = 'b0101,
    BIRspEBlk    = 'b0110
  } m2sbirsp_opcode_t;
  typedef enum logic [3:0] {
    BISnpCur     = 'b0000,
    BISnpData    = 'b0001,
    BISnpInv     = 'b0010,
    BISnpCurBlk  = 'b0100,
    BISnpDataBlk = 'b0101,
    BISnpInvBlk  = 'b0110
  } s2mbisnp_opcode_t;

  /* CXL 68B TL Txns ; generic and randomized */
  // CXL.cache : H2D
  typedef struct packed {
    logic [ 1:0]    rsvd;
    logic [11:0]    uqid;
    logic [51:6]    addr;
    h2dreq_opcode_t opcode;
    logic           val;
  } h2dreq68_t;
  typedef struct {
         bit [ 1:0]      rsvd = '0;
    rand bit [11:0]      uqid;
    rand bit [51:6]      addr;
    rand h2dreq_opcode_t opcode;
    rand bit             val;
  } r_h2dreq68_t;
  typedef struct packed {
    logic [ 7:0]    rsvd;
    logic           go_e;
    logic           poi;
    logic           ch;
    logic [11:0]    cqid;
    logic           val;
  } h2ddat68_hdr_t;
  typedef struct {
         bit [ 7:0] rsvd = '0;
    rand bit        go_e;
    rand bit        poi;
    rand bit        ch;
    rand bit [11:0] cqid;
    rand bit        val;
  } r_h2ddat68_hdr_t;
  typedef struct packed {
    logic           rsvd;
    logic [11:0]    cqid;
    rsp_pre_t       rsp_pre;
    logic [11:0]    rspdata;
    h2drsp_opcode_t opcode;
    logic           val;
  } h2drsp68_t;
  typedef struct {
         bit             rsvd = '0;
    rand bit [11:0]      cqid;
    rand rsp_pre_t       rsp_pre;
    rand bit [11:0]      rspdata;
    rand h2drsp_opcode_t opcode;
    rand bit             val;
  } r_h2drsp68_t;
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
  typedef struct {
         bit   [ 6:0]    rsvd1 = '0;
    rand bit   [51:6]    addr;
         bit   [ 5:0]    rsvd0 = '0;
    rand bit             nt;
    rand bit   [11:0]    cqid;
    rand d2hreq_opcode_t opcode;
    rand bit             val;
  } r_d2hreq68_t;
  typedef struct packed {
    logic           rsvd;
    logic           poi;
    logic           bg;
    logic           ch;
    logic [11:0]    uqid;
    logic           val;
  } d2hdat68_hdr_t;
  typedef struct {
         bit        rsvd = '0;
    rand bit        poi;
    rand bit        bg;
    rand bit        ch;
    rand bit [11:0] uqid;
    rand bit        val;
  } r_d2hdat68_hdr_t;
  typedef struct packed {
    logic [ 1:0]    rsvd;
    logic [11:0]    uqid;
    d2hrsp_opcode_t opcode;
    logic           val;
  } d2hrsp68_t;
  typedef struct {
         bit [ 1:0]      rsvd = '0;
    rand bit [11:0]      uqid;
    rand d2hrsp_opcode_t opcode;
    rand bit             val;
  } r_d2hrsp68_t;
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
  typedef struct {
         bit [ 5:0]      rsvd = '0;
    rand bit [ 3:0]      ldid;
    rand bit [ 1:0]      tc;
    rand bit             poi;
    rand bit [51:6]      addr;
    rand bit [15:0]      tag;
    rand mem_metavalue_t metavalue;
    rand mem_metafield_t metafield;
    rand mem_snptype_t   snptype;
    rand m2srwd_opcode_t memop; 
    rand bit             val;
  } r_m2srwd68_hdr_t;
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
  typedef struct {
         bit   [ 5:0]    rsvd = '0;
    rand bit   [ 3:0]    ldid;
    rand bit   [ 1:0]    tc;
    rand bit   [51:5]    addr;
    rand bit   [15:0]    tag;
    rand mem_metavalue_t metavalue;
    rand mem_metafield_t metafield;
    rand mem_snptype_t   snptype;
    rand m2sreq_opcode_t memop; 
    rand bit             val;
  } r_m2sreq68_t;
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
  typedef struct {
    rand mem_devload_t   devload;
    rand bit [ 3:0]      ldid;
    rand bit [15:0]      tag;
    rand mem_metavalue_t metavalue;
    rand mem_metafield_t metafield;
    rand s2mndr_opcode_t opcode;
    rand bit             val;
  } r_s2mndr68_t;
  typedef struct packed {
  //mem_devload_t   devload;
    logic [ 3:0]    ldid;
    logic [15:0]    tag;
    mem_metavalue_t metavalue;
    mem_metafield_t metafield;
    s2mndr_opcode_t memop;
    logic           val;
  } s2mndr68_frac_t; //for C2H H4/G4/G5; frac := "fractured"
  typedef struct {
  //rand mem_devload_t   devload;
    rand bit [ 3:0]      ldid;
    rand bit [15:0]      tag;
    rand mem_metavalue_t metavalue;
    rand mem_metafield_t metafield;
    rand s2mndr_opcode_t opcode;
    rand bit             val;
  } r_s2mndr68_frac_t; //for C2H H4/G4/G5; frac := "fractured"
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
  typedef struct {
         bit   [ 8:0]    rsvd = '0;
    rand mem_devload_t   devload;
    rand bit [ 3:0]      ldid;
    rand bit             poi;
    rand bit [15:0]      tag;
    rand mem_metavalue_t metavalue;
    rand mem_metafield_t metafield;
    rand s2mdrs_opcode_t opcode;
    rand bit             val;
  } r_s2mdrs68_hdr_t;

  /* CXL 256B TL Txns ; generic and randomized */
  // CXL.cache : H2D
  typedef struct packed {
    logic [ 5:0]    rsvd;
    logic [ 3:0]    cacheid;
    logic [11:0]    uqid;
    logic [51:6]    addr;
    h2dreq_opcode_t opcode;
    logic           val;
  } h2dreq256_t;
  typedef struct {
         bit [ 5:0]      rsvd = '0;
    rand bit [ 3:0]      cacheid;
    rand bit [11:0]      uqid;
    rand bit [51:6]      addr;
    rand h2dreq_opcode_t opcode;
    rand bit             val;
  } r_h2dreq256_t;
  typedef struct packed {
    logic [ 8:0]    rsvd;
    logic [ 3:0]    cacheid;
    logic           go_e;
    logic           poi;
    logic [11:0]    cqid;
    logic           val;
  } h2ddat256_hdr_t;
  typedef struct {
         bit [ 8:0]  rsvd = '0;
    rand bit [ 3:0]  cacheid;
    rand bit         go_e;
    rand bit         poi;
    rand bit [11:0]  cqid;
    rand bit         val;
  } r_h2ddat256_hdr_t;
  typedef struct packed {
    logic [ 4:0]    rsvd;
    logic [ 3:0]    cacheid;
    logic [11:0]    cqid;
    rsp_pre_t       rsp_pre;
    logic [11:0]    rspdata;
    h2drsp_opcode_t opcode;
    logic           val;
  } h2drsp256_t;
  typedef struct {
         bit [ 4:0]      rsvd = '0;
    rand bit [ 3:0]      cacheid;
    rand bit [11:0]      cqid;
    rand rsp_pre_t       rsp_pre;
    rand bit [11:0]      rspdata;
    rand h2drsp_opcode_t opcode;
    rand bit             val;
  } r_h2drsp256_t;
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
  typedef struct {
         bit [ 3:0]      rsvd1 = '0;
    rand bit [51:6]      addr;
         bit [ 2:0]      rsvd0 = '0;
    rand bit [ 3:0]      cacheid;
    rand bit             nt;
    rand bit [11:0]      cqid;
    rand d2hreq_opcode_t opcode;
    rand bit             val;
  } r_d2hreq256_t;
  typedef struct packed {
    logic [ 7:0]    rsvd;
    logic           bep;
    logic           poi;
    logic           bg;
    logic [11:0]    uqid;
    logic           val;
  } d2hdat256_hdr_t;
  typedef struct {
         bit [ 7:0]    rsvd = '0;
    rand bit           bep;
    rand bit           poi;
    rand bit           bg;
    rand bit [11:0]    uqid;
    rand bit           val;
  } r_d2hdat256_hdr_t;
  typedef struct packed {
    logic [ 5:0]    rsvd;
    logic [11:0]    uqid;
    d2hrsp_opcode_t opcode;
    logic           val;
  } d2hrsp256_t;
  typedef struct {
         bit [ 5:0]      rsvd = '0;
    rand bit [11:0]      uqid;
    rand d2hrsp_opcode_t opcode;
    rand bit             val;
  } r_d2hrsp256_t;
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
  typedef struct {
    rand bit [ 1:0]      tc;
         bit [ 8:0]      rsvd = '0;
    rand bit [12:0]      ckid;
    rand bit [ 3:0]      ldid;
    rand bit             trp;
    rand bit             poi;
    rand bit [51:6]      addr;
    rand bit [15:0]      tag;
    rand mem_metavalue_t metavalue;
    rand mem_metafield_t metafield;
    rand mem_snptype_t   snptype;
    rand m2srwd_opcode_t memop;
    rand bit             val;
  } r_m2srwd256_hdr_t;
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
  typedef struct {
    rand bit [ 1:0]      tc;
         bit [ 6:0]      rsvd = '0;
    rand bit [12:0]      ckid;
    rand bit [ 3:0]      ldid;
    rand bit [51:6]      addr;
    rand bit [15:0]      tag;
    rand mem_metavalue_t metavalue;
    rand mem_metafield_t metafield;
    rand mem_snptype_t   snptype;
    rand m2sreq_opcode_t memop;
    rand bit             val;
  } r_m2sreq256_t;
  typedef struct packed {
    logic [ 8:0]      rsvd;
    logic [ 1:0]      lowaddr;
    logic [11:0]      bitag;
    logic [11:0]      biid;
    m2sbirsp_opcode_t opcode;
    logic             val;
  } m2sbirsp256_t;
  typedef struct {
         bit [ 8:0]        rsvd = '0;
    rand bit [ 1:0]        lowaddr;
    rand bit [11:0]        bitag;
    rand bit [11:0]        biid;
    rand m2sbirsp_opcode_t opcode;
    rand bit               val;
  } r_m2sbirsp256_t;
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
  typedef struct {
         bit [ 9:0]      rsvd = '0;
    rand mem_devload_t   devload;
    rand bit [ 3:0]      ldid;
    rand bit [15:0]      tag;
    rand mem_metavalue_t metavalue;
    rand mem_metafield_t metafield;
    rand s2mndr_opcode_t opcode;
    rand bit             val;
  } r_s2mndr256_t;
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
  typedef struct {
         bit [ 7:0]      rsvd = '0;
    rand bit             trp;
    rand bit [ 3:0]      ldid;
    rand mem_devload_t   devload;
    rand bit             poi;
    rand bit [15:0]      tag;
    rand mem_metavalue_t metavalue;
    rand mem_metafield_t metafield;
    rand s2mdrs_opcode_t opcode;
    rand bit             val;
  } r_s2mdrs256_hdr_t;
  typedef struct packed {
    logic [ 8:0]      rsvd;
    logic [51:6]      addr;
    logic [11:0]      bitag;
    logic [11:0]      biid;
    s2mbisnp_opcode_t opcode;
    logic             val;
  } s2mbisnp256_t;
  typedef struct {
         bit [ 8:0]        rsvd = '0;
    rand bit [51:6]        addr;
    rand bit [11:0]        bitag;
    rand bit [11:0]        biid;
    rand s2mbisnp_opcode_t opcode;
    rand bit               val;
  } r_s2mbisnp256_t;

endpackage
