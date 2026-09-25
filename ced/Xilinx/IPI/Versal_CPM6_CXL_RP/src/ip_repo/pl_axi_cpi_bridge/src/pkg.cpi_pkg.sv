package cpi_pkg;

  import cxl_tl_enum_pkg::*;
  import cxl_ll_enum_pkg::*;

  typedef enum logic [1:0] {
    CPI_FLIT_68B  = 'b00,
    CPI_FLIT_256B = 'b01,
    CPI_FLIT_PBR  = 'b10,
    CPI_FLIT_RSVD = 'b11 
  } cpi_flitmode_t;

  // Cannot have parameters in packages so we must give user
  // some defines and they must compile them into the package
  `ifdef CXL_IDE_EPOCH_SUPPORT
    `ifndef CXL_ACTIVE_PORTS
      `define CXL_ACTIVE_PORTS 1
    `endif
    localparam NP=$clog2(`CXL_ACTIVE_PORTS);
    localparam IDE_ADDL=3+NP;
  `else
    localparam IDE_ADDL=0;
  `endif

  // REQ channel : 83+IDE_ADDL bits
  localparam REQ_USP_A2FC_EXT = 15;
  localparam REQ_USP_F2AC_EXT = 10+IDE_ADDL;
  localparam REQ_USP_F2AM_EXT = 6+IDE_ADDL;
  localparam REQ_DSP_A2FC_EXT = 10;
  localparam REQ_DSP_F2AC_EXT = 15+IDE_ADDL;
  localparam REQ_DSP_A2FM_EXT = 6;
  localparam REQ_DSP_F2AM_EXT = IDE_ADDL;
  typedef union packed {
    union packed {
      /* CXL.mem upstream port */
      struct packed {
      `ifdef CXL_IDE_EPOCH_SUPPORT
        // +3+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
      `endif
        // 83 bits
        cpi_flitmode_t  flitmode; //1:0
        logic   [ 3: 0] ldid;
        logic   [45: 0] address51to6;
        logic           addressparity;
        mem_metavalue_t metavalue; //1:0
        mem_metafield_t metafield; //1:0
        logic           address5;
        mem_snptype_t   snptype; //2:0
        logic   [ 1: 0] tc;
        logic   [15: 0] tag;
        m2sreq_opcode_t memopcode; //3:0
      } a2fm;
      struct packed {
        // +REQ_USP_F2AM_EXT bits ; make union same width
        logic [REQ_USP_F2AM_EXT:1] rsvd_ext;
        // 77 bits
        cpi_flitmode_t    flitmode; //1:0
        logic     [45: 0] address51to6;
        logic             addressparity;
        logic     [11: 0] bitag;
        logic     [11: 0] biid;
        s2mbisnp_opcode_t opcode; //3:0
      } f2am;
      /* CXL.cache upstream port */
      struct packed {  
        // +REQ_USP_A2FC_EXT bits ; make union same width
        logic [REQ_USP_A2FC_EXT:1] rsvd_ext;
      `ifdef CXL_IDE_EPOCH_SUPPORT
        // +3+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
      `endif
        // 68 bits
        cpi_flitmode_t  flitmode; //1:0
        logic   [ 3: 0] cacheid;
        logic   [45: 0] address51to6;
        logic           addressparity;
        logic   [11: 0] uqid;
        h2dreq_opcode_t opcode; //2:0
      } a2fc;
      struct packed { 
        // +REQ_USP_F2AC_EXT bits ; make union same width
        logic [REQ_USP_F2AC_EXT:1] rsvd_ext;
        // 73 bits
        cpi_flitmode_t  flitmode; //1:0
        logic   [ 3: 0] cacheid;
        logic   [45: 0] address51to6;
        logic           addressparity;
        logic   [ 1: 0] rsvd19to18;
        logic           nt;
        logic   [11: 0] cqid;
        d2hreq_opcode_t opcode; //4:0
      } f2ac;
    } usp;
    union packed {
      /* CXL.mem downstream port */
      struct packed {
        // +REQ_DSP_A2FM_EXT bits ; make union same width
        logic [REQ_DSP_A2FM_EXT:1] rsvd_ext;
        // +3+NP bits
      `ifdef CXL_IDE_EPOCH_SUPPORT
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
      `endif
        // 77 bits
        cpi_flitmode_t    flitmode; //1:0
        logic     [45: 0] address51to6;
        logic             addressparity;
        logic     [11: 0] bitag;
        logic     [11: 0] biid;
        s2mbisnp_opcode_t opcode; //3:0
      } a2fm;
      struct packed {
      `ifdef CXL_IDE_EPOCH_SUPPORT
        // +REQ_DSP_F2AM_EXT bits ; make union same width
        logic [REQ_DSP_F2AM_EXT:1] rsvd_ext;
      `endif
        // 83 bits
        cpi_flitmode_t  flitmode; //1:0
        logic   [ 3: 0] ldid;
        logic   [45: 0] address51to6;
        logic           addressparity;
        mem_metavalue_t metavalue; //1:0
        mem_metafield_t metafield; //1:0
        logic           address5;
        mem_snptype_t   snptype; //2:0
        logic   [ 1: 0] tc;
        logic   [15: 0] tag;
        m2sreq_opcode_t memopcode; //3:0
      } f2am;
      /* CXL.cache downstream port */
      struct packed {
        // +REQ_DSP_A2FC_EXT bits ; make union same width
        logic [REQ_DSP_A2FC_EXT:1] rsvd_ext;
        // +3+NP bits
      `ifdef CXL_IDE_EPOCH_SUPPORT
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
      `endif
        // 73 bits
        cpi_flitmode_t  flitmode; //1:0
        logic   [ 3: 0] cacheid;
        logic   [45: 0] address51to6;
        logic           addressparity;
        logic   [ 1: 0] dev_trust_lvl;
        logic           nt;
        logic   [11: 0] cqid;
        d2hreq_opcode_t opcode; //4:0
      } a2fc;
      struct packed {
        // +REQ_DSP_F2AC_EXT bits ; make union same width
        logic [REQ_DSP_F2AC_EXT:1] rsvd_ext;
        // 68 bits
        cpi_flitmode_t  flitmode; //1:0
        logic   [ 3: 0] cacheid;
        logic   [45: 0] address51to6;
        logic           addressparity;
        logic   [11: 0] uqid;
        h2dreq_opcode_t opcode; //2:0
      } f2ac;
    } dsp;
  } req_hdr_u;

  // DATA channel : 84+IDE_ADDL bits
  localparam DATA_USP_F2AM_EXT = 44+IDE_ADDL;
  localparam DATA_USP_A2FC_EXT = 57;
  localparam DATA_USP_F2AC_EXT = 67+IDE_ADDL;
  localparam DATA_DSP_A2FM_EXT = 44;
  localparam DATA_DSP_F2AM_EXT = IDE_ADDL;
  localparam DATA_DSP_A2FC_EXT = 67;
  localparam DATA_DSP_F2AC_EXT = 57+IDE_ADDL;

  typedef union packed {
    union packed {
      /* CXL.mem upstream port */
      struct packed {
      `ifdef CXL_IDE_EPOCH_SUPPORT
        // +3+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
      `endif
        // 84 bits
        cpi_flitmode_t  flitmode; //1:0
        logic   [ 3: 0] ldid;
        logic   [22: 0] address51to6_odd;
        logic   [15: 0] tag;
        logic   [22: 0] address51to6_even;
        logic           addressparity;
        logic   [ 1: 0] rsvd14to13;
        logic   [ 1: 0] tc;
        mem_snptype_t   snptype; //2:0
        mem_metavalue_t metavalue; //1:0
        mem_metafield_t metafield; //1:0
        m2srwd_opcode_t memopcode; //3:0
      } a2fm;
      struct packed {
        // +DATA_USP_F2AM_EXT bits ; make union same width
        logic [DATA_USP_F2AM_EXT:1] rsvd_ext;
        // 40 bits
        cpi_flitmode_t  flitmode; //1:0
        mem_devload_t   devload; //1:0
        logic   [ 3: 0] ldid;
        logic   [15: 0] tag;
        logic   [ 7: 0] rsvd15to8;
        mem_metavalue_t metavalue; //1:0
        mem_metafield_t metafield; //1:0
        logic           rsvd3;
        s2mdrs_opcode_t opcode; //2:0
      } f2am;
      /* CXL.cache upstream port */
      struct packed {
        // +DATA_USP_A2FC_EXT bits ; make union same width
        logic [DATA_USP_A2FC_EXT:1] rsvd_ext;
      `ifdef CXL_IDE_EPOCH_SUPPORT
        // +3+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
      `endif
        // 27 bits
        cpi_flitmode_t  flitmode; //1:0
        logic   [ 3: 0] cacheid;
        logic           chunkvalid;
        logic   [11: 0] cqid;
        logic   [ 6: 0] rsvd7to1;
        logic           goerr;
      } a2fc;
      struct packed {
        // +DATA_USP_F2AC_EXT bits ; make union same width
        logic [DATA_USP_F2AC_EXT:1] rsvd_ext;
        // 17 bits
        cpi_flitmode_t  flitmode; //1:0
        logic           chunkvalid;
        logic           bogus;
        logic           rsvd12;
        logic   [11: 0] uqid;
      } f2ac;
    } usp;
    union packed {
      /* CXL.mem downstream port */
      struct packed {
        // +DATA_DSP_A2FM_EXT bits ; make union same width
        logic [DATA_DSP_A2FM_EXT:1] rsvd_ext;
      `ifdef CXL_IDE_EPOCH_SUPPORT
        // +3+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
      `endif
        // 40 bits
        cpi_flitmode_t  flitmode; //1:0
        mem_devload_t   devload; //1:0
        logic   [ 3: 0] ldid;
        logic   [15: 0] tag;
        logic   [ 7: 0] rsvd15to8;
        mem_metavalue_t metavalue; //1:0
        mem_metafield_t metafield; //1:0
        logic           rsvd3;
        s2mdrs_opcode_t opcode; //2:0
      } a2fm;
      struct packed {
      `ifdef CXL_IDE_EPOCH_SUPPORT
        // +DATA_DSP_F2AM_EXT bits ; make union same width
        logic [DATA_DSP_F2AM_EXT:1] rsvd_ext;
      `endif
        // 84 bits
        cpi_flitmode_t  flitmode; //1:0
        logic   [ 3: 0] ldid;
        logic   [22: 0] address51to6_odd;
        logic   [15: 0] tag;
        logic   [22: 0] address51to6_even;
        logic           addressparity;
        logic   [ 1: 0] rsvd14to13;
        logic   [ 1: 0] tc;
        mem_snptype_t   snptype; //2:0
        mem_metavalue_t metavalue; //1:0
        mem_metafield_t metafield; //1:0
        m2srwd_opcode_t memopcode; //3:0
      } f2am;
      /* CXL.cache downstream port */
      struct packed {
        // +DATA_DSP_A2FC_EXT bits ; make union same width
        logic [DATA_DSP_A2FC_EXT:1] rsvd_ext;
      `ifdef CXL_IDE_EPOCH_SUPPORT
        // +3+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
      `endif
        // 17 bits
        cpi_flitmode_t  flitmode; //1:0
        logic           chunkvalid;
        logic           bogus;
        logic           rsvd12;
        logic   [11: 0] uqid;
      } a2fc;
      struct packed {
        // +DATA_DSP_F2AC_EXT bits ; make union same width
        logic [DATA_DSP_F2AC_EXT:1] rsvd_ext;
        // 27 bits
        cpi_flitmode_t  flitmode; //1:0
        logic   [ 3: 0] cacheid;
        logic           chunkvalid;
        logic   [11: 0] cqid;
        logic   [ 6: 0] rsvd7to1;
        logic           goerr;
      } f2ac;
    } dsp;
  } data_hdr_u;

  // RSP channel : 37+IDE_ADDL bits
  localparam RSP_USP_A2FM_EXT = 5;
  localparam RSP_USP_F2AM_EXT = 6+IDE_ADDL;
  localparam RSP_USP_F2AC_EXT = 16+IDE_ADDL;
  localparam RSP_DSP_A2FM_EXT = 6;
  localparam RSP_DSP_F2AM_EXT = 5+IDE_ADDL;
  localparam RSP_DSP_A2FC_EXT = 16;
  localparam RSP_DSP_F2AC_EXT = IDE_ADDL;

  typedef union packed {
    union packed {
      /* CXL.mem upstream port */
      struct packed {
        // +RSP_USP_A2FM_EXT bits ; make union same width
        logic [RSP_USP_A2FM_EXT:1] rsvd_ext;
      `ifdef CXL_IDE_EPOCH_SUPPORT
        // +3+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
      `endif
        // 32 bits
        cpi_flitmode_t    flitmode; //1:0
        logic     [ 1: 0] lowaddr;
        logic     [11: 0] bitag;
        logic     [11: 0] biid;
        m2sbirsp_opcode_t opcode; //3:0
      } a2fm;
      struct packed {
        // +RSP_USP_F2AM_EXT bits ; make union same width
        logic [RSP_USP_F2AM_EXT:1] rsvd_ext;
        // 31 bits
        cpi_flitmode_t  flitmode; //1:0
        mem_devload_t   devload; //1:0
        logic   [ 3: 0] ldid;
        logic   [15: 0] tag;
        mem_metavalue_t metavalue; //1:0
        mem_metafield_t metafield; //1:0
        s2mndr_opcode_t opcode; //2:0
      } f2am;
      /* CXL.cache upstream port */
      struct packed {
      `ifdef CXL_IDE_EPOCH_SUPPORT
        // +3+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
      `endif
        // 37 bits
        cpi_flitmode_t  flitmode; //1:0
        logic   [ 3: 0] cacheid;
        logic   [11: 0] rspdata;
        logic           rsvd18;
        logic   [ 1: 0] rsp_pre;
        logic   [11: 0] cqid;
        h2drsp_opcode_t opcode; //3:0
      } a2fc;
      struct packed {
        // +RSP_USP_F2AC_EXT bits ; make union same width
        logic [RSP_USP_F2AC_EXT:1] rsvd_ext;
        // 21 bits
        cpi_flitmode_t  flitmode; //1:0
        logic   [11: 0] uqid;
        logic   [ 1: 0] rsvd6to5;
        d2hrsp_opcode_t opcode; //4:0
      } f2ac;
    } usp;
    union packed {
      /* CXL.mem downstream port */
      struct packed {
        // +RSP_DSP_A2FM_EXT bits ; make union same width
        logic [RSP_DSP_A2FM_EXT:1] rsvd_ext;
      `ifdef CXL_IDE_EPOCH_SUPPORT
        // +3+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
      `endif
        // 31 bits
        cpi_flitmode_t  flitmode; //1:0
        mem_devload_t   devload; //1:0
        logic   [ 3: 0] ldid;
        logic   [15: 0] tag;
        mem_metavalue_t metavalue; //1:0
        mem_metafield_t metafield; //1:0
        s2mndr_opcode_t opcode; //2:0
      } a2fm;
      struct packed {
        // +RSP_DSP_F2AM_EXT bits ; make union same width
        logic [RSP_DSP_F2AM_EXT:1] rsvd_ext;
        // 32 bits
        cpi_flitmode_t   flitmode; //1:0
        logic     [ 1: 0] lowaddr;
        logic     [11: 0] bitag;
        logic     [11: 0] biid;
        m2sbirsp_opcode_t opcode; //3:0
      } f2am;
      /* CXL.cache downstream port */
      struct packed {
        // +RSP_DSP_A2FC_EXT bits ; make union same width
        logic [RSP_DSP_A2FC_EXT:1] rsvd_ext;
      `ifdef CXL_IDE_EPOCH_SUPPORT
        // +3+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
      `endif
        // 21 bits
        cpi_flitmode_t  flitmode; //1:0
        logic   [11: 0] uqid;
        logic   [ 1: 0] rsvd6to5;
        d2hrsp_opcode_t opcode; //4:0
      } a2fc;
      struct packed {
      `ifdef CXL_IDE_EPOCH_SUPPORT
        // +RSP_DSP_F2AC_EXT bits ; make union same width
        logic [RSP_DSP_F2AC_EXT:1] rsvd_ext;
      `endif
        // 37 bits
        cpi_flitmode_t  flitmode; //1:0
        logic   [ 3: 0] cacheid;
        logic   [11: 0] rspdata;
        logic           rsvd18;
        logic   [ 1: 0] rsp_pre;
        logic   [11: 0] cqid;
        h2drsp_opcode_t opcode; //3:0
      } f2ac;
    } dsp;
  } rsp_hdr_u;

endpackage
