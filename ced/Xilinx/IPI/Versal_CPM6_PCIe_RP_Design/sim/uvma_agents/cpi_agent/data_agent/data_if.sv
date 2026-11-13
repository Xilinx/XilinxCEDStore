// This interface conforms to CPI Spec Rev1.0, 02/2023
interface data_if#(parameter NP=0);

  localparam MAX_HDR_W    = 87+NP;
//localparam USP_A2FM     = 87+NP; //max width
  localparam USP_F2AM_EXT = 47+NP; 
  localparam USP_A2FC_EXT = 57; 
  localparam USP_F2AC_EXT = 70+NP; 
  localparam DSP_A2FM_EXT = 44;
  localparam DSP_F2AM_EXT = 3+NP;
  localparam DSP_A2FC_EXT = 67;
  localparam DSP_F2AC_EXT = 60+NP;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  bit agent_driven; 

  wire clk;

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

  // VALID
  wire         data_is_valid;
  wire         data_block;
  wire         data_early_valid;
  // FLOW_C
  wire   [3:0] data_protocol_id;
  wire   [3:0] data_vc_id;
  wire         data_shared_credit;
  // HDR
  wire   hdr_u data_header;
  wire         data_sz;
  wire         data_cmd_parity;
  wire [11:0]  data_spid;
  wire [11:0]  data_dpid;
  // PAYLOAD
  wire [511:0] data_body; 
  wire [ 63:0] data_byte_enable;
  wire         data_byte_enable_parity;
  wire         data_poison;
  wire [  7:0] data_parity;
  // EOP
  wire         data_eop;
  // CREDIT
  wire         data_rxcrd_valid;
  wire   [1:0] data_rxcrd_protocol_id;
  wire   [3:0] data_rxcrd_vc_id;
  wire         data_rxcrd_shared;
  wire         data_txblock_crd_flow;
  // EMD (not part of CPI spec)
  wire [ 31:0] data_emd;

  // Parity word
  wire [MAX_HDR_W+12*2-1:0] parity_word; 
  assign parity_word = {data_header, data_spid, data_dpid};

  // Don't touch
  logic         i_data_is_valid          = 'z;
  logic         i_data_block             = 'z;
  logic         i_data_early_valid       = 'z;
  logic  [3:0]  i_data_protocol_id       = 'z;
  logic  [3:0]  i_data_vc_id             = 'z;
  logic         i_data_shared_credit     = 'z;
  hdr_u         i_data_header            = 'z;
  logic         i_data_sz                = 'z;
  logic         i_data_cmd_parity        = 'z;
  logic  [11:0] i_data_spid              = 'z;
  logic  [11:0] i_data_dpid              = 'z;
  logic [511:0] i_data_body              = 'z; 
  logic  [63:0] i_data_byte_enable       = 'z;
  logic         i_data_byte_enable_parity= 'z;
  logic         i_data_poison            = 'z;
  logic   [7:0] i_data_parity            = 'z;
  logic         i_data_eop               = 'z;
  logic         i_data_rxcrd_valid       = 'z;
  logic   [1:0] i_data_rxcrd_protocol_id = 'z;
  logic   [3:0] i_data_rxcrd_vc_id       = 'z;
  logic         i_data_rxcrd_shared      = 'z;
  logic         i_data_txblock_crd_flow  = 'z;
  logic [ 31:0] i_data_emd               = 'z;

  // Need to make this assign so the driver of block level TBs can drive
  // the i_* nets directly via the agent configured as a master, then
  // can move to top level TB and switch to an agent configured as a
  // passive slave and not have to worry about changing the interface,
  // only the configuration object
  assign data_is_valid          = i_data_is_valid;
  assign data_block             = i_data_block;
  assign data_early_valid       = i_data_early_valid;
  assign data_protocol_id       = i_data_protocol_id;
  assign data_vc_id             = i_data_vc_id;
  assign data_shared_credit     = i_data_shared_credit;
  assign data_header            = i_data_header;
  assign data_sz                = i_data_sz;
  assign data_cmd_parity        = i_data_cmd_parity;
  assign data_spid              = i_data_spid;
  assign data_dpid              = i_data_dpid;
  assign data_body              = i_data_body; 
  assign data_byte_enable       = i_data_byte_enable;
  assign data_byte_enable_parity= i_data_byte_enable_parity;
  assign data_poison            = i_data_poison;
  assign data_parity            = i_data_parity;
  assign data_eop               = i_data_eop;
  assign data_rxcrd_valid       = i_data_rxcrd_valid;
  assign data_rxcrd_protocol_id = i_data_rxcrd_protocol_id;
  assign data_rxcrd_vc_id       = i_data_rxcrd_vc_id;
  assign data_rxcrd_shared      = i_data_rxcrd_shared;
  assign data_txblock_crd_flow  = i_data_txblock_crd_flow;
  assign data_emd               = i_data_emd;

  // Master agent will drive transactions using is_valid
  // Active slave agent will drive credit returns using rxcrd_valid and/or rxcrd_shared
  // dcb = "driver cb"
  clocking dcb @(posedge clk);
    // Transaction
    output i_data_is_valid,
           i_data_block,
           i_data_early_valid,
           i_data_protocol_id,
           i_data_vc_id,
           i_data_shared_credit,
           i_data_header,
           i_data_sz,
           i_data_cmd_parity,
           i_data_spid,
           i_data_dpid,
           i_data_body,
           i_data_byte_enable,
           i_data_byte_enable_parity,
           i_data_poison,
           i_data_parity,
           i_data_eop,
           i_data_emd,
    // Credit return transaction
           i_data_rxcrd_valid,
           i_data_rxcrd_shared,
           i_data_rxcrd_protocol_id,
           i_data_rxcrd_vc_id,
           i_data_txblock_crd_flow;
  endclocking

  // mcb = "monitor cb" ; not qualified by anything
  clocking mcb @(posedge clk);
    // Transaction
    input  data_is_valid,
           data_block,
           data_early_valid,
           data_protocol_id,
           data_vc_id,
           data_shared_credit,
           data_header,
           data_sz,
           data_cmd_parity,
           data_spid,
           data_dpid,
           data_body,
           data_byte_enable,
           data_byte_enable_parity,
           data_poison,
           data_parity,
           data_eop,
           data_emd,
    // Credit return transaction
           data_rxcrd_valid,
           data_rxcrd_protocol_id,
           data_rxcrd_vc_id,
           data_rxcrd_shared,
           data_txblock_crd_flow;
  endclocking

  /* ASSERTIONS */
  logic     en_assert = 1'bx;
  // Assertions check blocking; can't use variable delay, so we'll cover all cases
  // then just enable the one that's valid 
  bit       a2f; 
  bit [1:0] blocking;
  bit       txfer_32b_en;  
  bit       data_cmd_parity_en;
  bit       data_be_parity_en;

  // Auto-enable assertions unless overridden
  initial begin
    wait({data_block,data_txblock_crd_flow} === 2'h0);
    en_assert = (en_assert === 1'bx) ? 1'b1 : en_assert;
  end

  property block_check(ante, cons, dly); //antecedent, consequent, delay
     @(posedge clk) ante |-> ##dly cons; 
  endproperty

  property block_data(dly);
    disable iff ((blocking!=dly) || !en_assert) 
      block_check(data_block, !data_is_valid, dly);
  endproperty

  property block_crd(dly);
    disable iff ((blocking!=dly) || !en_assert) 
      block_check(data_txblock_crd_flow, !data_rxcrd_valid && !data_rxcrd_shared, dly);
  endproperty

  assert property( 
    @(posedge clk iff data_is_valid)
    disable iff (!en_assert || !txfer_32b_en ) 
    data_sz != 1'b0
  ) else 
    `uvm_error("interface_check", "data_sz cannot be 0 if 32B txfer not supported")

  assert property( 
    @(posedge clk iff data_is_valid)
    disable iff (!en_assert || !data_cmd_parity_en) 
    data_cmd_parity === ^{data_header, data_spid, data_dpid}
  ) else 
    `uvm_error("interface_check", $sformatf("Calculated cmd header parity does not match parity transmitted: %0b",data_cmd_parity))

  assert property( 
    @(posedge clk iff data_is_valid)
    disable iff (!en_assert || !data_be_parity_en) 
    data_byte_enable_parity === ^(data_byte_enable)
  ) else 
    `uvm_error("interface_check", $sformatf("Calculated byte enable parity does not match parity transmitted: %0b",data_byte_enable_parity))

  for (genvar ii=0; ii<8; ii++) begin : gen_data_parity_check
    assert property( 
    @(posedge clk iff data_is_valid)
      disable iff (!en_assert)
      data_parity[ii] === ^(data_body[ii*64+:64])
    ) else
      `uvm_error("interface_check", $sformatf("body=0x%h Calculated data body parity (bit %0d) does not match parity transmitted: %0b",data_body[ii*64+:64],ii,data_parity[ii]))
  end

  always@(posedge data_block iff (blocking==0))
    `uvm_error("interface_check", "data_if noticed a data_block assertion that shouldn't occur")
  aprop_blockmsg_1 : assert property(block_data(1)) else `uvm_error("data_if", "aprop_blockmsg_1 assertion failure");
  aprop_blockmsg_2 : assert property(block_data(2)) else `uvm_error("data_if", "aprop_blockmsg_2 assertion failure");
  aprop_blockmsg_3 : assert property(block_data(3)) else `uvm_error("data_if", "aprop_blockmsg_3 assertion failure");

  always@(posedge data_txblock_crd_flow iff (blocking==0))
    `uvm_error("interface_check", "data_if noticed a data_txblock_crd_flow assertion that shouldn't occur")
  aprop_blockcrd_1 : assert property(block_crd(1)) else `uvm_error("data_if", "aprop_blockcrd_1 assertion failure");
  aprop_blockcrd_2 : assert property(block_crd(2)) else `uvm_error("data_if", "aprop_blockcrd_2 assertion failure");
  aprop_blockcrd_3 : assert property(block_crd(3)) else `uvm_error("data_if", "aprop_blockcrd_3 assertion failure");

endinterface
