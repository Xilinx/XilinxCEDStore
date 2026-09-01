package cxl31_ll_pkg;

  import cxl31_tl_pkg::*;

  typedef enum bit [2:0] {UNSPEC, F68, F256, F256_LOPT, FPBR} flit_mode_t;

  /* 68B Flit Header */
  typedef enum logic       {PROTOCOL, CONTROL}          flit68_t;
  typedef enum logic [2:0] {H0, H1, H2, H3, H4, H5, H6} hslot_fmt_t; 
  typedef enum logic [2:0] {G0, G1, G2, G3, G4, G5, G6} gslot_fmt_t; 

  // 68B Link Layer Control Flit :: LLCTRL
  typedef enum logic [3:0] {LLCRD=4'h0, RETRY=4'h1, IDE=4'h2, INIT=4'hC}     llctrl_t;
  typedef enum logic [3:0] {_ACK=4'h1}                                       llcrd_subtype_t;
  typedef enum logic [3:0] {_RIDLE=4'h0, _REQ=4'h1, _RACK=4'h2, _FRAME=4'h3} retry_subtype_t;
  typedef enum logic [3:0] {_IDLE=4'h0, _START=4'h1, _TMAC=4'h2}             ide_subtype_t;
  typedef enum logic [3:0] {_PARAM=4'h8}                                     init_subtype_t;

  // 256B Link Layer Control Flit :: LLCTRL 
  typedef enum logic [3:0] {IDE_F256=4'h2, IBE_F256=4'h3, INIT_F256=4'hC} llctrl_f256_t;
  
  /* 68B Flit Header */
  typedef struct packed {
    logic [  3: 0] datcrd;
    logic [  3: 0] reqcrd;
    logic [  3: 0] rspcrd;
    logic [  2: 0] rsvd1;
    struct packed {
      gslot_fmt_t slot3;
      gslot_fmt_t slot2;
      gslot_fmt_t slot1;
      hslot_fmt_t slot0;
    } fmt;
    logic          sz;
    logic          be;
    logic          ak;
    logic          rsvd0;
    flit68_t       Type;
  } flit68_hdr_t;
  
  /* Unpacked; can be randomized */
  typedef struct {
    rand bit [  3: 0] datcrd;
    rand bit [  3: 0] reqcrd;
    rand bit [  3: 0] rspcrd;
         bit [  2: 0] rsvd1 = '0;
         rand struct {
           rand gslot_fmt_t slot3;
           rand gslot_fmt_t slot2;
           rand gslot_fmt_t slot1;
           rand hslot_fmt_t slot0;
         } fmt;
    rand bit          sz;
    rand bit          be;
    rand bit          ak;
         bit          rsvd0 = '0;
         flit68_t     Type;
  } r_flit68_hdr_t;

endpackage
