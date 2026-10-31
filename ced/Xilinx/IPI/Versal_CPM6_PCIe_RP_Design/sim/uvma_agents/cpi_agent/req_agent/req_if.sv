// This interface conforms to CPI Spec Rev1.0, 02/2023
interface req_if#(parameter NP=0);

  localparam MAX_HDR_W    = 86+NP;
//localparam USP_A2FM     = 86+NP; //max width
  localparam USP_F2AM_EXT = 9+NP;
  localparam USP_A2FC_EXT = 15;
  localparam USP_F2AC_EXT = 13+NP;
  localparam DSP_A2FM_EXT = 6;
  localparam DSP_F2AM_EXT = 3+NP;
  localparam DSP_A2FC_EXT = 10;
  localparam DSP_F2AC_EXT = 18+NP;
 
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  bit agent_driven;

  wire clk;

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
      struct packed {  
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
      struct packed { 
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

  // VALID
  wire        req_is_valid;
  wire        req_block;
  wire        req_early_valid;
  // FLOW_C
  wire [3:0]  req_protocol_id;
  wire [3:0]  req_vc_id;
  wire        req_shared_credit;
  // HDR
  wire hdr_u  req_header;
  wire        req_cmd_parity;
  wire [11:0] req_spid;
  wire [11:0] req_dpid;
  // CREDIT
  wire        req_rxcrd_valid;
  wire [3:0]  req_rxcrd_protocol_id;
  wire [3:0]  req_rxcrd_vc_id;
  wire        req_rxcrd_shared;
  wire        req_txblock_crd_flow;

  // Parity word
  wire [MAX_HDR_W+12*2-1:0] parity_word;
  assign parity_word = {req_header, req_spid, req_dpid};

  // Don't touch
  logic        i_req_is_valid          = 'z;
  logic        i_req_block             = 'z;
  logic        i_req_early_valid       = 'z;
  logic [3:0]  i_req_protocol_id       = 'z;
  logic [3:0]  i_req_vc_id             = 'z;
  logic        i_req_shared_credit     = 'z;
  hdr_u        i_req_header            = 'z;
  logic        i_req_cmd_parity        = 'z;
  logic [11:0] i_req_spid              = 'z;
  logic [11:0] i_req_dpid              = 'z;
  logic        i_req_rxcrd_valid       = 'z;
  logic  [3:0] i_req_rxcrd_protocol_id = 'z;
  logic  [3:0] i_req_rxcrd_vc_id       = 'z;
  logic        i_req_rxcrd_shared      = 'z;
  logic        i_req_txblock_crd_flow  = 'z;

  // Need to make this assign so the driver of block level TBs can drive
  // the i_* nets directly via the agent configured as a master, then
  // can move to top level TB and switch to an agent configured as a
  // passive slave and not have to worry about changing the interface,
  // only the configuration object
  assign req_is_valid          = i_req_is_valid;
  assign req_block             = i_req_block;
  assign req_early_valid       = i_req_early_valid;
  assign req_protocol_id       = i_req_protocol_id;
  assign req_vc_id             = i_req_vc_id;
  assign req_shared_credit     = i_req_shared_credit;
  assign req_header            = i_req_header;
  assign req_cmd_parity        = i_req_cmd_parity;
  assign req_spid              = i_req_spid;
  assign req_dpid              = i_req_dpid;
  assign req_rxcrd_valid       = i_req_rxcrd_valid;
  assign req_rxcrd_protocol_id = i_req_rxcrd_protocol_id;
  assign req_rxcrd_vc_id       = i_req_rxcrd_vc_id;
  assign req_rxcrd_shared      = i_req_rxcrd_shared;
  assign req_txblock_crd_flow  = i_req_txblock_crd_flow;

  // Master agent will drive transactions using is_valid
  // Active slave agent will drive credit returns using rxcrd_valid and/or rxcrd_shared
  // dcb = "driver cb"
  clocking dcb @(posedge clk); 
    // Transaction
    output i_req_is_valid,
           i_req_block,
           i_req_early_valid,
           i_req_protocol_id,
           i_req_vc_id,
           i_req_shared_credit,
           i_req_header,
           i_req_cmd_parity,
           i_req_spid,
           i_req_dpid,
    // Credit return transaction
           i_req_rxcrd_valid,
           i_req_rxcrd_shared,
           i_req_rxcrd_protocol_id,
           i_req_rxcrd_vc_id,
           i_req_txblock_crd_flow;
  endclocking

  // mcb = "monitor cb" ; not qualified by anything
  clocking mcb @(posedge clk); 
    input  req_is_valid,
           req_block,
           req_early_valid,
           req_protocol_id,
           req_vc_id,
           req_shared_credit,
           req_header,
           req_cmd_parity,
           req_spid,
           req_dpid,
           req_rxcrd_valid,
           req_rxcrd_protocol_id,
           req_rxcrd_vc_id,
           req_rxcrd_shared,
           req_txblock_crd_flow;
  endclocking

  /* ASSERTIONS */
  logic     en_assert = 1'bx;
  // Assertions check blocking; can't use variable delay, so we'll cover all cases
  // then just enable the one that's valid 
  bit       a2f; 
  bit [1:0] blocking;
  bit       req_cmd_parity_en;

  // Auto-enable assertions unless overridden
  initial begin
    wait({req_block,req_txblock_crd_flow} === 2'h0);
    en_assert = (en_assert === 1'bx) ? 1'b1 : en_assert;
  end

  property block_check(ante, cons, dly); //antecedent, consequent, delay
     @(posedge clk) ante |-> ##dly cons; 
  endproperty

  property block_req(dly);
    disable iff ((blocking!=dly) || !en_assert) 
      block_check(req_block, !req_is_valid, dly);
  endproperty

  property block_crd(dly);
    disable iff ((blocking!=dly) || !en_assert) 
      block_check(req_txblock_crd_flow, !req_rxcrd_valid && !req_rxcrd_shared, dly);
  endproperty

  assert property(
    @(posedge clk iff req_is_valid)
    disable iff (!en_assert || !req_cmd_parity_en)
    req_cmd_parity === ^{req_header, req_spid, req_dpid}
  ) else
    `uvm_error("interface_check", $sformatf("Calculated cmd parity does not match parity transmitted: %0b",req_cmd_parity))

  always@(posedge req_block iff (blocking == 0))
    `uvm_error("interface_check", "req_if noticed a req_block assertion that shouldn't occur")
  aprop_blockmsg_1 : assert property(block_req(1)) else `uvm_error("req_if", "aprop_blockmsg_1 assertion failure");
  aprop_blockmsg_2 : assert property(block_req(2)) else `uvm_error("req_if", "aprop_blockmsg_2 assertion failure");
  aprop_blockmsg_3 : assert property(block_req(3)) else `uvm_error("req_if", "aprop_blockmsg_3 assertion failure");

  always@(posedge req_txblock_crd_flow iff (blocking == 0))
    `uvm_error("interface_check", "req_if noticed a req_txblock_crd_flow assertion that shouldn't occur")
  aprop_blockcrd_1 : assert property(block_crd(1)) else `uvm_error("req_if", "aprop_blockcrd_1 assertion failure");
  aprop_blockcrd_2 : assert property(block_crd(2)) else `uvm_error("req_if", "aprop_blockcrd_2 assertion failure");
  aprop_blockcrd_3 : assert property(block_crd(3)) else `uvm_error("req_if", "aprop_blockcrd_3 assertion failure");

endinterface
