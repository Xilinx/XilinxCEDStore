// This interface conforms to CPI Spec Rev1.0, 02/2023
interface rsp_if#(parameter NP=0);

  localparam MAX_HDR_W    = 40+NP;
  localparam USP_A2FM_EXT = 5; 
  localparam USP_F2AM_EXT = 9+NP;
//localparam USP_A2FC     = 40+NP; //max width
  localparam USP_F2AC_EXT = 19+NP;
  localparam DSP_A2FM_EXT = 6;
  localparam DSP_F2AM_EXT = 8+NP;
  localparam DSP_A2FC_EXT = 16;
  localparam DSP_F2AC_EXT = 3+NP;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  bit agent_driven;

  wire clk;

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

  // VALID
  wire       rsp_is_valid;
  wire       rsp_block;
  wire       rsp_early_valid;
  // FLOW_C
  wire [3:0] rsp_protocol_id;
  wire [3:0] rsp_vc_id;
  wire       rsp_shared_credit;
  // HDR
  wire hdr_u rsp_header;
  wire       rsp_cmd_parity;
  wire [11:0]rsp_spid;
  wire [11:0]rsp_dpid;
  // CREDIT
  wire       rsp_rxcrd_valid;
  wire [1:0] rsp_rxcrd_protocol_id;
  wire [3:0] rsp_rxcrd_vc_id;
  wire       rsp_rxcrd_shared;
  wire       rsp_txblock_crd_flow;

  // Parity word
  wire [MAX_HDR_W+12*2-1:0] parity_word;
  assign parity_word = {rsp_header, rsp_spid, rsp_dpid};

  // Don't touch
  logic        i_rsp_is_valid          = 'z;
  logic        i_rsp_block             = 'z;
  logic        i_rsp_early_valid       = 'z;
  logic [3:0]  i_rsp_protocol_id       = 'z;
  logic [3:0]  i_rsp_vc_id             = 'z;
  logic        i_rsp_shared_credit     = 'z;
  hdr_u        i_rsp_header            = 'z;
  logic        i_rsp_cmd_parity        = 'z;
  logic [11:0] i_rsp_spid              = 'z;
  logic [11:0] i_rsp_dpid              = 'z;
  logic        i_rsp_rxcrd_valid       = 'z;
  logic  [1:0] i_rsp_rxcrd_protocol_id = 'z;
  logic  [3:0] i_rsp_rxcrd_vc_id       = 'z;
  logic        i_rsp_rxcrd_shared      = 'z;
  logic        i_rsp_txblock_crd_flow  = 'z;

  // Need to make this assign so the driver of block level TBs can drive
  // the i_* nets directly via the agent configured as a master, then
  // can move to top level TB and switch to an agent configured as a
  // passive slave and not have to worry about changing the interface,
  // only the configuration object
  assign rsp_is_valid          = i_rsp_is_valid;
  assign rsp_block             = i_rsp_block;
  assign rsp_early_valid       = i_rsp_early_valid;
  assign rsp_protocol_id       = i_rsp_protocol_id;
  assign rsp_vc_id             = i_rsp_vc_id;
  assign rsp_shared_credit     = i_rsp_shared_credit;
  assign rsp_header            = i_rsp_header;
  assign rsp_cmd_parity        = i_rsp_cmd_parity;
  assign rsp_spid              = i_rsp_spid;
  assign rsp_dpid              = i_rsp_dpid;
  assign rsp_rxcrd_valid       = i_rsp_rxcrd_valid;
  assign rsp_rxcrd_protocol_id = i_rsp_rxcrd_protocol_id;
  assign rsp_rxcrd_vc_id       = i_rsp_rxcrd_vc_id;
  assign rsp_rxcrd_shared      = i_rsp_rxcrd_shared;
  assign rsp_txblock_crd_flow  = i_rsp_txblock_crd_flow;

  // Master agent will drive transactions using is_valid
  // Active slave agent will drive credit returns using rxcrd_valid and/or rxcrd_shared
  // dcb = "driver cb"
  clocking dcb @(posedge clk);
    // Transaction
    output i_rsp_is_valid,
           i_rsp_block,
           i_rsp_early_valid,
           i_rsp_protocol_id,
           i_rsp_vc_id,
           i_rsp_shared_credit,
           i_rsp_header,
           i_rsp_cmd_parity,
           i_rsp_spid,
           i_rsp_dpid,
    // Credit return transaction
           i_rsp_rxcrd_valid,
           i_rsp_rxcrd_shared,
           i_rsp_rxcrd_protocol_id,
           i_rsp_rxcrd_vc_id,
           i_rsp_txblock_crd_flow;
  endclocking

  // mcb = "monitor cb" ; not qualified by anything
  clocking mcb @(posedge clk);
    input rsp_is_valid,
          rsp_block,
          rsp_early_valid,
          rsp_protocol_id,
          rsp_vc_id,
          rsp_shared_credit,
          rsp_header,
          rsp_cmd_parity,
          rsp_spid,
          rsp_dpid,
          rsp_rxcrd_valid,
          rsp_rxcrd_protocol_id,
          rsp_rxcrd_vc_id,
          rsp_rxcrd_shared,
          rsp_txblock_crd_flow;
  endclocking

  /* ASSERTIONS */
  bit       en_assert = 1'b0;
  // Assertions check blocking; can't use variable delay, so we'll cover all cases
  // then just enable the one that's valid 
  bit       a2f; 
  bit [1:0] blocking;
  bit       rsp_cmd_parity_en;

  // Auto-enable assertions unless overridden
  initial begin
    wait({rsp_block,rsp_txblock_crd_flow} === 2'h0);
    en_assert = (en_assert === 1'bx) ? 1'b1 : en_assert;
  end

  property block_check(ante, cons, dly); //antecedent, consequent, delay
     @(posedge clk) ante |-> ##dly cons; 
  endproperty

  assert property(
    @(posedge clk iff rsp_is_valid)
    disable iff (!en_assert || !rsp_cmd_parity_en)
    rsp_cmd_parity === ^{rsp_header, rsp_spid, rsp_dpid}
  ) else
    `uvm_error("interface_check", $sformatf("Calculated cmd parity does not match parity transmitted: %0b",rsp_cmd_parity))

  property block_rsp(dly);
    disable iff ((blocking!=dly) || !en_assert) 
      block_check(rsp_block, !rsp_is_valid, dly);
  endproperty

  property block_crd(dly);
    disable iff ((blocking!=dly) || !en_assert) 
      block_check(rsp_txblock_crd_flow, !rsp_rxcrd_valid && !rsp_rxcrd_shared, dly);
  endproperty
  
  assert property(
    @(posedge clk iff rsp_is_valid)
    disable iff (!en_assert)
    rsp_vc_id == '0
  ) else 
    `uvm_error("interface_check", "Reference CPI spec for valid rsp_vc_id values")

  assert property(
    @(posedge clk iff rsp_rxcrd_valid)
    disable iff (!en_assert)
    rsp_rxcrd_vc_id == '0
  ) else 
    `uvm_error("interface_check", "Reference CPI spec for valid rsp_rxcrd_vc_id values")

  always@(posedge rsp_block iff (blocking == 0))
    `uvm_error("interface_check", "rsp_if noticed a rsp_block assertion that shouldn't occur")
  aprop_blockmsg_1 : assert property(block_rsp(1)) else `uvm_error("rsp_if", "aprop_blockmsg_1 assertion failure");
  aprop_blockmsg_2 : assert property(block_rsp(2)) else `uvm_error("rsp_if", "aprop_blockmsg_2 assertion failure");
  aprop_blockmsg_3 : assert property(block_rsp(3)) else `uvm_error("rsp_if", "aprop_blockmsg_3 assertion failure");

  always@(posedge rsp_txblock_crd_flow iff (blocking == 0))
    `uvm_error("interface_check", "rsp_if noticed a rsp_txblock_crd_flow assertion that shouldn't occur")
  aprop_blockcrd_1 : assert property(block_crd(1)) else `uvm_error("rsp_if", "aprop_blockcrd_1 assertion failure");
  aprop_blockcrd_2 : assert property(block_crd(2)) else `uvm_error("rsp_if", "aprop_blockcrd_2 assertion failure");
  aprop_blockcrd_3 : assert property(block_crd(3)) else `uvm_error("rsp_if", "aprop_blockcrd_3 assertion failure");

endinterface
