`include "req_if.sv"

package req_agent_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import base_agent_pkg::*;
  import global_agent_pkg::global_share;
  import cpi_common_pkg::*;

  // Cannot have parameters in packages, so we just 
  // define a small NP for the hdr_u
  localparam NP=3;
  localparam USP_A2FC_EXT = 15;
  localparam USP_F2AC_EXT = 13+NP;
  localparam USP_F2AM_EXT = 9+NP;
  localparam DSP_A2FC_EXT = 10;
  localparam DSP_F2AC_EXT = 18+NP;
  localparam DSP_A2FM_EXT = 6;
  localparam DSP_F2AM_EXT = 3+NP;

  typedef union packed { 
    union packed {
      /* CXL.mem upstream port */
      struct packed {
        // 86+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
        logic [ 1: 0] flitmode;
        logic [ 3: 0] ldid;
        logic [45: 0] address51to6;
        logic         addressparity;
        logic [ 1: 0] metavalue;
        logic [ 1: 0] metafield;
        logic         address5;
        logic [ 2: 0] snptype;
        logic [ 1: 0] tc;
        logic [15: 0] tag;
        logic [ 3: 0] memopcode;
      } a2fm;
      struct packed {
        // +USP_F2AM_EXT bits ; make union same width
        logic [USP_F2AM_EXT:1] rsvd_ext;
        // 77 bits
        logic [ 1: 0] flitmode;
        logic [45: 0] address51to6;
        logic         addressparity;
        logic [11: 0] bitag;
        logic [11: 0] biid; 
        logic [ 3: 0] opcode;
      } f2am;
      /* CXL.cache upstream port */
      struct packed {  //71+NP+USP_A2F_EXT bits
        // +USP_A2FC_EXT bits ; make union same width
        logic [USP_A2FC_EXT:1] rsvd_ext;
        // 71+NP bits
        logic [NP: 0] portid; 
        logic         epochid;
        logic         epochvalid;
        logic [ 1: 0] flitmode; 
        logic [ 3: 0] cacheid; 
        logic [45: 0] address51to6;
        logic         addressparity;
        logic [11: 0] uqid;
        logic [ 2: 0] opcode;
      } a2fc;
      struct packed { //73+USP_F2AC_EXT bits
        // +USP_F2AC_EXT bits ; make union same width
        logic [USP_F2AC_EXT:1] rsvd_ext;
        // 73 bits
        logic [ 1: 0] flitmode; 
        logic [ 3: 0] cacheid;
        logic [45: 0] address51to6;
        logic         addressparity;
        logic [ 1: 0] rsvd19to18;
        logic         nt;
        logic [11: 0] cqid;
        logic [ 4: 0] opcode;
      } f2ac;
    } usp;
    union packed {
      /* CXL.mem downstream port */
      struct packed {
        // +DSP_A2FM_EXT bits ; make union same width
        logic [DSP_A2FM_EXT:1] rsvd_ext;
        // 80+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
        logic [ 1: 0] flitmode; 
        logic [45: 0] address51to6;
        logic         addressparity;
        logic [11: 0] bitag;
        logic [11: 0] biid;
        logic [ 3: 0] opcode;
      } a2fm;
      struct packed {
        // +DSP_F2AM_EXT bits ; make union same width
        logic [DSP_F2AM_EXT:1] rsvd_ext;
        // 83 bits
        logic [ 1: 0] flitmode; 
        logic [ 3: 0] ldid;
        logic [45: 0] address51to6;
        logic         addressparity;
        logic [ 1: 0] metavalue;
        logic [ 1: 0] metafield;
        logic         address5;
        logic [ 2: 0] snptype;
        logic [ 1: 0] tc;
        logic [15: 0] tag;
        logic [ 3: 0] memopcode;
      } f2am;
      /* CXL.cache downstream port */
      struct packed { 
        // +DSP_A2FC_EXT bits ; make union same width
        logic [DSP_A2FC_EXT:1] rsvd_ext;
        // 76+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
        logic [ 1: 0] flitmode;
        logic [ 3: 0] cacheid;
        logic [45: 0] address51to6;
        logic         addressparity;
        logic [ 1: 0] dev_trust_lvl;
        logic         nt;
        logic [11: 0] cqid;
        logic [ 4: 0] opcode;
      } a2fc;
      struct packed { 
        // +DSP_F2AC_EXT bits ; make union same width
        logic [DSP_F2AC_EXT:1] rsvd_ext;
        // 68 bits
        logic [ 1: 0] flitmode;
        logic [ 3: 0] cacheid;
        logic [45: 0] address51to6;
        logic         addressparity;
        logic [11: 0] uqid;
        logic [ 2: 0] opcode;
      } f2ac;
    } dsp;
  } hdr_u;

  `include "req_txn.sv"
  `include "req_cfg.sv"
  `include "req_share.sv"
  `include "req_init_crd_slv_seq.sv"
  `include "req_slv_base_seq.sv"
  `include "req_monitor.sv"
  `include "req_driver.sv"
  `include "req_api_seq.sv"
  `include "req_api.sv"
  `include "req_agent.sv"

endpackage
