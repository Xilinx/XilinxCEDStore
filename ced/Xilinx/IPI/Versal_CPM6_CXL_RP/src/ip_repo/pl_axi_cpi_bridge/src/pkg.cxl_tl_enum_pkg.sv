package cxl_tl_enum_pkg;

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
    Invalid  = 'b00,
    ExplNoOp = 'b01,
    Any      = 'b10,
    Shared   = 'b11
  } mem_metavalue_t;
  typedef enum logic [2:0] {
    MemData    = 'b000,
    MemDataNXM = 'b001
  } s2mdrs_opcode_t;
  typedef enum logic [3:0] {
    BISnpCur     = 'b0000,
    BISnpData    = 'b0001,
    BISnpInv     = 'b0010,
    BISnpCurBlk  = 'b0100,
    BISnpDataBlk = 'b0101,
    BISnpInvBlk  = 'b0110
  } s2mbisnp_opcode_t;
  typedef enum logic [3:0] {
    MemWrMem   = 'b0001,
    MemWrPtl   = 'b0010
  } m2srwd_opcode_t;
  typedef enum logic [3:0] {
    MemInv    = 'b0000,
    MemRd     = 'b0001,
    MemRdData = 'b0010,
    MemRdFwd  = 'b0011,
    MemWrFwd  = 'b0100,
    MemSpecRd = 'b1000,
    MemInvNT  = 'b1001
  } m2sreq_opcode_t;
  typedef enum logic [3:0] {
    BIRspI    = 'b0000,
    BIRspS    = 'b0001,
    BIRspE    = 'b0010,
    BIRspIBlk = 'b0100,
    BIRspSBlk = 'b0101,
    BIRspEBlk = 'b0110
  } m2sbirsp_opcode_t;
  typedef enum logic [2:0] {
    SnpNoOp   = 'b000, 
    SnpData   = 'b001, 
    SnpCur    = 'b010, 
    SnpInv    = 'b011 
  } mem_snptype_t;
  typedef enum logic [1:0] {
    CacheMiss2LocalCPU = 'b00,
    CacheHit           = 'b01,
    CacheMiss2RemotCPU = 'b10
  } rsp_pre_t;

endpackage
