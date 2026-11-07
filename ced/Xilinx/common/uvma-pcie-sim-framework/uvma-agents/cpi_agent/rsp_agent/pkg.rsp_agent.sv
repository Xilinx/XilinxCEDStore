`include "rsp_if.sv"

package rsp_agent_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import base_agent_pkg::*;
  import global_agent_pkg::global_share;
  import cpi_common_pkg::*;

  // Cannot have parameters in packages, so we just 
  // define a small NP for the hdr_u
  localparam NP=3;
  localparam USP_A2FM_EXT = 5; 
  localparam USP_F2AM_EXT = 9+NP;
  localparam USP_F2AC_EXT = 19+NP;
  localparam DSP_A2FM_EXT = 6;
  localparam DSP_F2AM_EXT = 8+NP;
  localparam DSP_A2FC_EXT = 16;
  localparam DSP_F2AC_EXT = 3+NP;

  typedef union packed {
    union packed {
      /* CXL.mem upstream port */
      struct packed {
        // +USP_A2FM_EXT bits ; make union same width
        logic [USP_A2FM_EXT:1] rsvd_ext;
        // 35+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
        logic [ 1: 0] flitmode;
        logic [ 1: 0] lowaddr;
        logic [11: 0] bitag;
        logic [11: 0] biid;
        logic [ 3: 0] opcode;
      } a2fm;
      struct packed {
        // +USP_F2AM_EXT bits ; make union same width
        logic [USP_F2AM_EXT:1] rsvd_ext;
        // 31 bits
        logic [ 1: 0] flitmode;
        logic [ 1: 0] devload;
        logic [ 3: 0] ldid;
        logic [15: 0] tag;
        logic [ 1: 0] metavalue;
        logic [ 1: 0] metafield;
        logic [ 2: 0] opcode;
      } f2am;
      /* CXL.cache upstream port */
      struct packed {
        // 40+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
        logic [ 1: 0] flitmode;
        logic [ 3: 0] cacheid;
        logic [11: 0] rspdata;
        logic         rsvd18;
        logic [ 1: 0] rsp_pre;
        logic [11: 0] cqid;
        logic [ 3: 0] opcode;
      } a2fc;
      struct packed {
        // +USP_F2AC_EXT bits ; make union same width
        logic [USP_F2AC_EXT:1] rsvd_ext;
        // 21 bits
        logic [ 1: 0] flitmode;
        logic [11: 0] uqid;
        logic [ 1: 0] rsvd6to5;
        logic [ 4: 0] opcode;
      } f2ac;
    } usp;
    union packed {
      /* CXL.mem downstream port */
      struct packed {
        // +DSP_A2FM_EXT bits ; make union same width
        logic [DSP_A2FM_EXT:1] rsvd_ext;
        // 34+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
        logic [ 1: 0] flitmode;
        logic [ 1: 0] devload;
        logic [ 3: 0] ldid;
        logic [15: 0] tag;
        logic [ 1: 0] metavalue;
        logic [ 1: 0] metafield;
        logic [ 2: 0] opcode;
      } a2fm;
      struct packed {
        // +DSP_F2AM_EXT bits ; make union same width
        logic [DSP_F2AM_EXT:1] rsvd_ext;
        // 32 bits
        logic [ 1: 0] flitmode;
        logic [ 1: 0] lowaddr;
        logic [11: 0] bitag;
        logic [11: 0] biid;
        logic [ 3: 0] opcode;
      } f2am;
      /* CXL.cache downstream port */
      struct packed {
        // +DSP_A2FC_EXT bits ; make union same width
        logic [DSP_A2FC_EXT:1] rsvd_ext;
        // 24+NP bits
        logic [NP: 0] portid;
        logic         epochid;
        logic         epochvalid;
        logic [ 1: 0] flitmode;
        logic [11: 0] uqid;
        logic [ 1: 0] rsvd6to5;
        logic [ 4: 0] opcode;
      } a2fc;
      struct packed {
        // +DSP_F2AC_EXT bits ; make union same width
        logic [DSP_F2AC_EXT:1] rsvd_ext;
        // 37 bits
        logic [ 1: 0] flitmode;
        logic [ 3: 0] cacheid;
        logic [11: 0] rspdata;
        logic         rsvd18;
        logic [ 1: 0] rsp_pre;
        logic [11: 0] cqid;
        logic [ 3: 0] opcode;
      } f2ac;
    } dsp;
  } hdr_u;

  `include "rsp_txn.sv"
  `include "rsp_cfg.sv"
  `include "rsp_share.sv"
  `include "rsp_init_crd_slv_seq.sv"
  `include "rsp_slv_base_seq.sv"
  `include "rsp_monitor.sv"
  `include "rsp_driver.sv"
  `include "rsp_api_seq.sv"
  `include "rsp_api.sv"
  `include "rsp_agent.sv"

endpackage
