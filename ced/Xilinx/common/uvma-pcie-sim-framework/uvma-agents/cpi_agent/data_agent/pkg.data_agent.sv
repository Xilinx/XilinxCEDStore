`include "data_if.sv"

package data_agent_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import base_agent_pkg::*;
  import global_agent_pkg::global_share;
  import cpi_common_pkg::*;

  // Cannot have parameters in packages, so we just 
  // define a small NP for the hdr_u
  localparam NP           = 3;
  localparam USP_F2AM_EXT = 47+NP; 
  localparam USP_A2FC_EXT = 57; 
  localparam USP_F2AC_EXT = 70+NP; 
  localparam DSP_A2FM_EXT = 44;
  localparam DSP_F2AM_EXT = 3+NP;
  localparam DSP_A2FC_EXT = 67;
  localparam DSP_F2AC_EXT = 60+NP;

  typedef union packed { 
    union packed {
      /* CXL.mem upstream port */
      struct packed {
        // 87+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
        logic [ 1: 0] flitmode;
        logic [ 3: 0] ldid;
        logic [22: 0] address51to6_odd;
        logic [15: 0] tag;
        logic [22: 0] address51to6_even;
        logic         addressparity;
        logic [ 1: 0] rsvd14to13;
        logic [ 1: 0] tc;
        logic [ 2: 0] snptype;
        logic [ 1: 0] metavalue;
        logic [ 1: 0] metafield;
        logic [ 3: 0] memopcode;
      } a2fm;
      struct packed {
        // +USP_F2AM_EXT bits ; make union same width
        logic [USP_F2AM_EXT:1] rsvd_ext;
        // 40 bits
        logic [ 1: 0] flitmode;
        logic [ 1: 0] devload;
        logic [ 3: 0] ldid;
        logic [15: 0] tag;
        logic [ 7: 0] rsvd15to8;
        logic [ 1: 0] metavalue;
        logic [ 1: 0] metafield;
        logic         rsvd3;
        logic [ 2: 0] opcode;
      } f2am;
      /* CXL.cache upstream port */
      struct packed {
        // +USP_A2FC_EXT bits ; make union same width
        logic [USP_A2FC_EXT:1] rsvd_ext;
        // 30+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
        logic [ 1: 0] flitmode;
        logic [ 3: 0] cacheid;
        logic         chunkvalid;
        logic [11: 0] cqid;
        logic [ 6: 0] rsvd7to1;
        logic         goerr;
      } a2fc;
      struct packed {
        // +USP_F2AC_EXT bits ; make union same width
        logic [USP_F2AC_EXT:1] rsvd_ext;
        // 17 bits
        logic [ 1: 0] flitmode;
        logic         chunkvalid;
        logic         bogus;
        logic         rsvd12;
        logic [11: 0] uqid;
      } f2ac;
    } usp;
    union packed {
      /* CXL.mem downstream port */
      struct packed {
        // +DSP_A2FM_EXT bits ; make union same width
        logic [DSP_A2FM_EXT:1] rsvd_ext;
        // 43+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
        logic [ 1: 0] flitmode;
        logic [ 1: 0] devload;
        logic [ 3: 0] ldid;
        logic [15: 0] tag;
        logic [ 7: 0] rsvd15to8;
        logic [ 1: 0] metavalue;
        logic [ 1: 0] metafield;
        logic         rsvd3;
        logic [ 2: 0] opcode;
      } a2fm;
      struct packed {
        // +DSP_F2AM_EXT bits ; make union same width
        logic [DSP_F2AM_EXT:1] rsvd_ext;
        // 84 bits
        logic [ 1: 0] flitmode;
        logic [ 3: 0] ldid;
        logic [22: 0] address51to6_odd;
        logic [15: 0] tag;
        logic [22: 0] address51to6_even;
        logic         addressparity;
        logic [ 1: 0] rsvd14to13;
        logic [ 1: 0] tc;
        logic [ 2: 0] snptype;
        logic [ 1: 0] metavalue;
        logic [ 1: 0] metafield;
        logic [ 3: 0] memopcode;
      } f2am;
      /* CXL.cache downstream port */
      struct packed {
        // +DSP_A2FC_EXT bits ; make union same width
        logic [DSP_A2FC_EXT:1] rsvd_ext;
        // 20+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
        logic [ 1: 0] flitmode;
        logic         chunkvalid;
        logic         bogus;
        logic         rsvd12;
        logic [11: 0] uqid;
      } a2fc;
      struct packed {
        // +DSP_F2AC_EXT bits ; make union same width
        logic [DSP_F2AC_EXT:1] rsvd_ext;
        // 27 bits
        logic [ 1: 0] flitmode;
        logic [ 3: 0] cacheid;
        logic         chunkvalid;
        logic [11: 0] cqid;
        logic [ 6: 0] rsvd7to1;
        logic         goerr;
      } f2ac;
    } dsp;
  } hdr_u;

  `include "data_txn.sv"
  `include "data_cfg.sv"
  `include "data_share.sv"
  `include "data_init_crd_slv_seq.sv"
  `include "data_slv_base_seq.sv"
  `include "data_monitor.sv"
  `include "data_driver.sv"
  `include "data_api_seq.sv"
  `include "data_api.sv"
  `include "data_agent.sv"

endpackage
