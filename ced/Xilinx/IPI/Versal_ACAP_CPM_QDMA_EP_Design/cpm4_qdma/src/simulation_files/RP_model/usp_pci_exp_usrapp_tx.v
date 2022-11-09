// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////
`include "board_common.vh"

module pci_exp_usrapp_tx #(
  parameter        ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG = 0,
  parameter        AXISTEN_IF_RQ_PARITY_CHECK   = 0,
  parameter        AXISTEN_IF_CC_PARITY_CHECK   = 0,
  parameter        AXISTEN_IF_RQ_ALIGNMENT_MODE      = "FALSE",
  parameter        AXISTEN_IF_CC_ALIGNMENT_MODE      = "FALSE",
  parameter        AXISTEN_IF_CQ_ALIGNMENT_MODE      = "FALSE",
  parameter        AXISTEN_IF_RC_ALIGNMENT_MODE      = "FALSE",
  parameter        DEV_CAP_MAX_PAYLOAD_SUPPORTED     = 1,
  parameter        C_DATA_WIDTH                      = 512,
  parameter        KEEP_WIDTH                        = C_DATA_WIDTH / 32,
  parameter        STRB_WIDTH                        = C_DATA_WIDTH / 8,
  parameter        EP_DEV_ID                         = 16'h7700,
  parameter        REM_WIDTH                         = C_DATA_WIDTH == 512,
  parameter  [5:0] RP_BAR_SIZE                       = 6'd11                  // Number of RP BAR's Address Bit - 1
)
(
  output reg                                 s_axis_rq_tlast,
  output reg      [C_DATA_WIDTH-1:0]         s_axis_rq_tdata,
  output          [136:0]                    s_axis_rq_tuser,
  output reg      [KEEP_WIDTH-1:0]           s_axis_rq_tkeep,
  input                                      s_axis_rq_tready,
  output reg                                 s_axis_rq_tvalid,

  output reg      [C_DATA_WIDTH-1:0]         s_axis_cc_tdata,
  output reg      [82:0]                     s_axis_cc_tuser,
  output reg                                 s_axis_cc_tlast,
  output reg      [KEEP_WIDTH-1:0]           s_axis_cc_tkeep,
  output reg                                 s_axis_cc_tvalid,
  input                                      s_axis_cc_tready,

  input           [3:0]                      pcie_rq_seq_num,
  input                                      pcie_rq_seq_num_vld,
  input           [5:0]                      pcie_rq_tag,
  input                                      pcie_rq_tag_vld,

  input           [1:0]                      pcie_tfc_nph_av,
  input           [1:0]                      pcie_tfc_npd_av,
//\\------------------------------------------------------
  input                                      speed_change_done_n,
//\\------------------------------------------------------
  input                                      user_clk,
  input                                      reset,
  input                                      user_lnk_up
);

parameter    Tcq = 1;
localparam   [15:0] DMA_BYTE_CNT = 16'h0080;

localparam   [4:0] LINK_CAP_MAX_LINK_WIDTH = 5'd4;
localparam   [3:0] LINK_CAP_MAX_LINK_SPEED = 4'd4;
localparam   [3:0] MAX_LINK_SPEED          = (LINK_CAP_MAX_LINK_SPEED==4'h8) ? 4'h4 : (LINK_CAP_MAX_LINK_SPEED==3'h4) ? 4'h3 : ((LINK_CAP_MAX_LINK_SPEED==3'h2) ? 4'h2 : 4'h1);
localparam   [5:0] BAR_ENABLED             = 6'b1;
localparam  [11:0] LINK_CTRL_REG_ADDR = 12'h080;
localparam  [11:0] PCIE_DEV_CAP_ADDR  = 12'h074;
localparam  [11:0] DEV_CTRL_REG_ADDR  = 12'h078;
localparam   NUMBER_OF_PFS = 1; //1;
reg        [(C_DATA_WIDTH - 1):0]            pcie_tlp_data;
reg        [(REM_WIDTH - 1):0]               pcie_tlp_rem;
integer                                      xdma_bar = 0;
integer                                      user_bar = 0;

localparam C_NUM_USR_IRQ	 = 16;

/* Local Variables */
integer                         i, j, k;
reg     [7:0]                   DATA_STORE   [8192:0]; // For Downstream Direction Data Storage
reg     [7:0]                   DATA_STORE_2 [(2**(RP_BAR_SIZE+1))-1:0]; // For Upstream Direction Data Storage
reg     [31:0]                  ADDRESS_32_L;
reg     [31:0]                  ADDRESS_32_H;
reg     [63:0]                  ADDRESS_64;
reg     [15:0]                  EP_BUS_DEV_FNS_INIT;
reg     [15:0]                  EP_BUS_DEV_FNS;
reg     [15:0]                  RP_BUS_DEV_FNS;
reg     [2:0]                   DEFAULT_TC;
reg     [9:0]                   DEFAULT_LENGTH;
reg     [3:0]                   DEFAULT_BE_LAST_DW;
reg     [3:0]                   DEFAULT_BE_FIRST_DW;
reg     [1:0]                   DEFAULT_ATTR;
reg     [7:0]                   DEFAULT_TAG;
reg     [3:0]                   DEFAULT_COMP;
reg     [11:0]                  EXT_REG_ADDR;
reg                             TD;
reg                             EP;
reg     [15:0]                  VENDOR_ID;
reg     [9:0]                   LENGTH;         // For 1DW config and IO transactions
reg     [9:0]                   CFG_DWADDR;

event                           test_begin;

reg     [31:0]                  P_ADDRESS_MASK;
reg     [31:0]                  P_READ_DATA;      // will store the 1st DW (lo) of a PCIE read completion
reg     [31:0]                  P_READ_DATA_2;    // will store the 2nd DW (hi) of a PCIE read completion
reg                             P_READ_DATA_VALID;
reg     [31:0]                  P_WRITE_DATA;
reg     [31:0]                  data;

reg                             error_check;
reg                             set_malformed;

// BAR Init variables
reg     [32:0]                  BAR_INIT_P_BAR[6:0];           // 6 corresponds to Expansion ROM
                                                               // note that bit 32 is for overflow checking
reg     [31:0]                  BAR_INIT_P_BAR_RANGE[6:0];     // 6 corresponds to Expansion ROM
reg     [1:0]                   BAR_INIT_P_BAR_ENABLED[6:0];   // 6 corresponds to Expansion ROM
//                              0 = disabled;  1 = io mapped;  2 = mem32 mapped;  3 = mem64 mapped

reg     [31:0]                  BAR_INIT_P_MEM64_HI_START;     // start address for hi memory space
reg     [31:0]                  BAR_INIT_P_MEM64_LO_START;     // start address for hi memory space
reg     [32:0]                  BAR_INIT_P_MEM32_START;        // start address for low memory space
                                                               // top bit used for overflow indicator
reg     [32:0]                  BAR_INIT_P_IO_START;           // start address for io space
reg     [100:0]                 BAR_INIT_MESSAGE[3:0];         // to be used to display info to user

reg     [32:0]                  BAR_INIT_TEMP;

reg                             OUT_OF_LO_MEM;                 // flags to indicate out of mem, mem64, and io
reg                             OUT_OF_IO;
reg                             OUT_OF_HI_MEM;

integer                         NUMBER_OF_IO_BARS;
integer                         NUMBER_OF_MEM32_BARS;          // Not counting the Mem32 EROM space
integer                         NUMBER_OF_MEM64_BARS;

reg     [3:0]                   ii;
integer                         jj;
integer                         kk;
reg     [3:0]                   pfIndex = 0;
reg     [3:0]                   pfTestIteration = 0;
reg     [3:0]                   pf_loop_index = 0;
reg                             dmaTestDone;

reg     [31:0]                  DEV_VEN_ID;                    // holds device and vendor id
integer                         PIO_MAX_NUM_BLOCK_RAMS;        // holds the max number of block RAMS
reg     [31:0]                  PIO_MAX_MEMORY;

reg                             pio_check_design; // boolean value to check PCI Express BAR configuration against
                                                  // limitations of PIO design. Setting this to true will cause the
                                                  // testbench to check if the core has been configured for more than
                                                  // one IO space, one general purpose Mem32 space (not counting
                                                  // the Mem32 EROM space), and one Mem64 space.

reg                             cpld_to;          // boolean value to indicate if time out has occured while waiting for cpld
reg                             cpld_to_finish;   // boolean value to indicate to $finish on cpld_to

reg                             verbose;          // boolean value to display additional info to stdout

wire                            user_lnk_up_n;
wire    [63:0]                  s_axis_cc_tparity;
wire    [63:0]                  s_axis_rq_tparity;

reg     [255:0]                 testname;
integer                         test_vars [31:0];
reg     [7:0]                   exp_tag;
reg     [7:0]                   expect_cpld_payload [4095:0];
reg     [7:0]                   expect_msgd_payload [4095:0];
reg     [7:0]                   expect_memwr_payload [4095:0];
reg     [7:0]                   expect_memwr64_payload [4095:0];
reg     [7:0]                   expect_cfgwr_payload [3:0];
reg                             expect_status;
reg                             expect_finish_check;
reg                             testError;
reg     [136:0]                 s_axis_rq_tuser_wo_parity;
reg     [16:0]                  MM_wb_sts_pidx;
reg     [16:0]                  MM_wb_sts_cidx;
reg     [10:0] 			axi_mm_q;
reg     [10:0] 			axi_st_q;
reg     [10:0] 			axi_st_q_phy;
reg     [10:0] 			pf0_qmax;
reg     [10:0] 			pf1_qmax;
reg     [127:0] 		wr_dat;
reg     [31:0] 			wr_add;
reg [15:0] 			data_tmp = 0;
   
assign s_axis_rq_tuser = {(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0),s_axis_rq_tuser_wo_parity[72:0]};

assign user_lnk_up_n = ~user_lnk_up;

integer desc_count = 0;
integer loop_timeout = 0;
reg [15:0] EP_DEV_ID1;
reg [31:0] h2c_status = 32'h0;
reg [31:0] c2h_status = 32'h0;
reg [31:0] int_req_reg;
/************************************************************
 Initial Statements
*************************************************************/
initial begin

  s_axis_rq_tlast   = 0;
  s_axis_rq_tdata   = 0;
  s_axis_rq_tuser_wo_parity = 0;
  s_axis_rq_tkeep   = 0;
  s_axis_rq_tvalid  = 0;

  s_axis_cc_tdata   = 0;
  s_axis_cc_tuser   = 0;
  s_axis_cc_tlast   = 0;
  s_axis_cc_tkeep   = 0;
  s_axis_cc_tvalid  = 0;

  ADDRESS_32_L         = 32'b1011_1110_1110_1111_1100_1010_1111_1110;
  ADDRESS_32_H         = 32'b1011_1110_1110_1111_1100_1010_1111_1110;
  ADDRESS_64           = { ADDRESS_32_H, ADDRESS_32_L };
  //EP_BUS_DEV_FNS       = 16'b0000_0001_0000_0000;
  //RP_BUS_DEV_FNS       = 16'b0000_0000_0000_0000;
  EP_BUS_DEV_FNS_INIT  = 16'b0000_0001_0000_0000;
  EP_BUS_DEV_FNS       = 16'b0000_0001_0000_0000;
  RP_BUS_DEV_FNS       = 16'b0000_0000_0000_0000;
  DEFAULT_TC           = 3'b000;
  DEFAULT_LENGTH       = 10'h000;
  DEFAULT_BE_LAST_DW   = 4'h0;
  DEFAULT_BE_FIRST_DW  = 4'h0;
  DEFAULT_ATTR         = 2'b01;
  DEFAULT_TAG          = 8'h00;
  DEFAULT_COMP         = 4'h0;
  EXT_REG_ADDR         = 12'h000;
  TD                   = 0;
  EP                   = 0;
  VENDOR_ID            = 16'h10ee;
  LENGTH               = 10'b00_0000_0001;

  set_malformed        = 1'b0;

end
//-----------------------------------------------------------------------\\
// Pre-BAR initialization
initial begin

  BAR_INIT_MESSAGE[0] = "DISABLED";
  BAR_INIT_MESSAGE[1] = "IO MAPPED";
  BAR_INIT_MESSAGE[2] = "MEM32 MAPPED";
  BAR_INIT_MESSAGE[3] = "MEM64 MAPPED";

  OUT_OF_LO_MEM       = 1'b0;
  OUT_OF_IO           = 1'b0;
  OUT_OF_HI_MEM       = 1'b0;

  // Disable variables to start
  for (ii = 0; ii <= 6; ii = ii + 1) begin

      BAR_INIT_P_BAR[ii]         = 33'h00000_0000;
      BAR_INIT_P_BAR_RANGE[ii]   = 32'h0000_0000;
      BAR_INIT_P_BAR_ENABLED[ii] = 2'b00;

  end

  BAR_INIT_P_MEM64_HI_START =  32'h0000_0001;  // hi 32 bit start of 64bit memory
  BAR_INIT_P_MEM64_LO_START =  32'h0000_0000;  // low 32 bit start of 64bit memory
  BAR_INIT_P_MEM32_START    =  33'h00000_0000; // start of 32bit memory
  BAR_INIT_P_IO_START       =  33'h00000_0000; // start of 32bit io

  DEV_VEN_ID                = (EP_DEV_ID1 << 16) | (32'h10EE);
  PIO_MAX_MEMORY            = 8192;            // PIO has max of 8Kbytes of memory
  PIO_MAX_NUM_BLOCK_RAMS    = 4;               // PIO has four block RAMS to test
  PIO_MAX_MEMORY            = 2048;            // PIO has 4 memory regions with 2 Kbytes of memory per region, ie 8 Kbytes
  PIO_MAX_NUM_BLOCK_RAMS    = 4;               // PIO has four block RAMS to test

  pio_check_design          = 1;               // By default check to make sure the core has been configured
                                               // appropriately for the PIO design
  cpld_to                   = 0;               // By default time out has not occured
  cpld_to_finish            = 1;               // By default end simulation on time out

  verbose                   = 0;               // turned off by default

  NUMBER_OF_IO_BARS         = 0;
  NUMBER_OF_MEM32_BARS      = 0;
  NUMBER_OF_MEM64_BARS      = 0;

end
//-----------------------------------------------------------------------\\
initial begin
//  if ($value$plusargs("TESTNAME=%s", testname))
//      $display("Running test {%0s}......", testname);
//  else begin
//      // $display("[%t] %m: No TESTNAME specified!", $realtime);
//      // $finish(2);
//      testname = "pio_writeReadBack_test0";
//      //testname = "sample_smoke_test0";
//      $display("Running default test {%0s}......", testname);
//  end
  dmaTestDone         = 0;
  pfIndex             = 0;
  pfTestIteration     = 0;
  pf_loop_index       = 0;
  expect_status       = 0;
  expect_finish_check = 0;
  testError           = 1'b0;
  // Tx transaction interface signal initialization.
  pcie_tlp_data       = 0;
  pcie_tlp_rem        = 0;

  // Payload data initialization.
  TSK_USR_DATA_SETUP_SEQ;

  board.RP.tx_usrapp.TSK_SIMULATION_TIMEOUT(10050);
  for (pfIndex = 0; pfIndex < NUMBER_OF_PFS; pfIndex = pfIndex + 1) 
  begin
  pfTestIteration = pfIndex;
  if ( pfIndex == 0) 
  EP_DEV_ID1 = 16'h9034;
  if ( pfIndex == 1)
  EP_DEV_ID1 = 16'h913F;
  if ( pfIndex == 2)
  EP_DEV_ID1 = 16'h9234;
  if ( pfIndex == 3)
  EP_DEV_ID1 = 16'h9334;

  DEV_VEN_ID                = (EP_DEV_ID1 << 16) | (32'h10EE);
  EP_BUS_DEV_FNS      = {EP_BUS_DEV_FNS_INIT[15:2], pfIndex[1:0]};
  board.RP.tx_usrapp.TSK_SYSTEM_INITIALIZATION;
  board.RP.tx_usrapp.TSK_BAR_INIT;

  // Find which BAR is XDMA BAR and assign 'xdma_bar' variable
  board.RP.tx_usrapp.TSK_XDMA_FIND_BAR;

  // Find which BAR is USR BAR and assign 'user_bar' variable
  board.RP.tx_usrapp.TSK_FIND_USR_BAR;

  if ($value$plusargs("TESTNAME=%s", testname))
      $display("Running test {%0s}......", testname);
  else begin

     //decide if QDMA or XDMA
      board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h00);
      if (P_READ_DATA[31:16] == 16'h1fd3) begin    // QDMA
         testname = "qdma_st_test0";
         $display("*** Running QDMA AXI-ST test for PF{%d}, test_name = {%0s}......", pfIndex, testname);
      end
      else begin     // XDMA
        // decide if AXI-MM or AXI-ST
        board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h00);
        if (P_READ_DATA[15] == 1'b1) begin
	    testname = "dma_stream0";
            $display("*** Running XDMA AXI-Stream test {%0s}......", testname);
        end
        else begin
            testname = "dma_test0";
            $display("*** Running XDMA AXI-MM test {%0s}......", testname);
      end
      end // else: !if(P_READ_DATA[15:8] == 8'h1fd3)
  end // else: !if($value$plusargs("TESTNAME=%s", testname))
    //Test starts here
  if (testname == "dummy_test") begin
      $display("[%t] %m: Invalid TESTNAME: %0s", $realtime, testname);
      $finish(2);
  end
  `include "tests.vh"
  else begin
      $display("[%t] %m: Error: Unrecognized TESTNAME: %0s", $realtime, testname);
      $finish(2);
  end
    wait (pfTestIteration == (pfIndex +1));
    
      #100
      OUT_OF_LO_MEM       = 1'b0;
      OUT_OF_IO           = 1'b0;
      OUT_OF_HI_MEM       = 1'b0;
      // Disable variables to start
      for (ii = 0; ii <= 6; ii = ii + 1) begin
          BAR_INIT_P_BAR[ii]         = 33'h00000_0000;
          BAR_INIT_P_BAR_RANGE[ii]   = 32'h0000_0000;
          BAR_INIT_P_BAR_ENABLED[ii] = 2'b00;
      end
  
      BAR_INIT_P_MEM64_HI_START =  32'h0000_0001;  // hi 32 bit start of 64bit memory
      BAR_INIT_P_MEM64_LO_START =  32'h0000_0000;  // low 32 bit start of 64bit memory
      BAR_INIT_P_MEM32_START    =  33'h00000_0000; // start of 32bit memory
      BAR_INIT_P_IO_START       =  33'h00000_0000; // start of 32bit io
      NUMBER_OF_IO_BARS         = 0;
      NUMBER_OF_MEM32_BARS      = 0;
      NUMBER_OF_MEM64_BARS      = 0;
  
      cpld_to                   = 0;               // By default time out has not occured
      cpld_to_finish            = 1;               // By default end simulation on time out
      verbose                   = 0;               // turned off by default
  end

  $finish;
end
//-----------------------------------------------------------------------\\

    /************************************************************
      Logic to Compute the Parity of the CC and the RQ Channel
    *************************************************************/

    generate
      if(AXISTEN_IF_RQ_PARITY_CHECK == 1) begin

          genvar a;

          for(a=0; a< STRB_WIDTH; a = a + 1) // Parity needs to be computed for every byte of data
          begin : parity_assign
              assign s_axis_rq_tparity[a] = !(  s_axis_rq_tdata[(8*a)+ 0] ^ s_axis_rq_tdata[(8*a)+ 1]
                                              ^ s_axis_rq_tdata[(8*a)+ 2] ^ s_axis_rq_tdata[(8*a)+ 3]
                                              ^ s_axis_rq_tdata[(8*a)+ 4] ^ s_axis_rq_tdata[(8*a)+ 5]
                                              ^ s_axis_rq_tdata[(8*a)+ 6] ^ s_axis_rq_tdata[(8*a)+ 7]);

              assign s_axis_cc_tparity[a] = !(  s_axis_cc_tdata[(8*a)+ 0] ^ s_axis_cc_tdata[(8*a)+ 1]
                                              ^ s_axis_cc_tdata[(8*a)+ 2] ^ s_axis_cc_tdata[(8*a)+ 3]
                                              ^ s_axis_cc_tdata[(8*a)+ 4] ^ s_axis_cc_tdata[(8*a)+ 5]
                                              ^ s_axis_cc_tdata[(8*a)+ 6] ^ s_axis_cc_tdata[(8*a)+ 7]);
          end
      end
    endgenerate


task TSK_QDMA_MM_TEST;
   input dsc_bypass;
begin

    //------------- This test performs a 32 bit write to a 32 bit Memory space and performs a read back

	//----------------------------------------------------------------------------------------
	// QDMA H2C Test Starts
	//----------------------------------------------------------------------------------------

    $display(" **** read Address at BAR0  = %h\n", board.RP.tx_usrapp.BAR_INIT_P_BAR[0][31:0]);
    $display(" **** read Address at BAR1  = %h\n", board.RP.tx_usrapp.BAR_INIT_P_BAR[1][31:0]);

    // Global programming
    //
    // Assign Q 0 for AXI-MM
    axi_mm_q = 11'h0;

    //-------------- Load DATA in Buffer ----------------------------------------------------
    // H2C DSC start at 0x0100 (256)
    // H2C data start at 0x0300 (768)
      board.RP.tx_usrapp.TSK_INIT_QDMA_MM_DATA_H2C;

	//-------------- DMA Engine ID Read -----------------------------------------------------
      board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h00);
      
    // enable dsc bypass loopback
    if (dsc_bypass)
       board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h90, 32'h3, 4'hF);

    //-------------- Clear HW CXTX for H2C and C2H for Q0 -----------------------------------------
    // [17:7] QID   00
    // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
    // [4:1]  MDMA_CTXT_SELC_DSC_HW_H2C = 3 : 0011
    // 0      BUSY : 0 
    //        00000000000_00_0011_0 : 0x06
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, 32'h00000006, 4'hF);
    // [17:7] QID   00
    // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
    // [4:1]  MDMA_CTXT_SELC_DSC_HW_C2H = 2 : 0010
    // 0      BUSY : 0 
    //        00000000000_00_0010_0 : 0x04
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, 32'h00000004, 4'hF);


    //-------------- Global Ring Size for Queue 0  0x204  : num of dsc 16 ------------------------
	  board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h204, 32'h00000010, 4'hF);

    //-------------- Global Function MAP 0x400  : Func0 22:11 Qnumber ( 16 Queue ) : 10:0 Qid_base for this Func
    // set up 16Queues
    // Func number is 0 : 0*4 = 0: address 0x400+ Fnum*4 = 0x400
    // 22:11 : 1_0000 : number of queues for this function. 
    // 10:0  : 000_0000_0000 : Queue off set 
    // 1000_0000_0000_0000 : 0x8000
	  for(pf_loop_index=0; pf_loop_index <= pfTestIteration; pf_loop_index = pf_loop_index + 1)
	  begin
	     if(pf_loop_index == pfTestIteration) begin
	        board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h400+(pf_loop_index*4), 32'h00008000, 4'hF);
		 end else begin
		    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h400+(pf_loop_index*4), 32'h00000000, 4'hF);
		 end
      end
    // AXI-MM Transfer start
    $display(" *** QDMA H2C *** \n");

    //-------------- Ind Dire CTXT MASK 0x814  0xffffffff for all 128 bits -------------------
	  board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h814, 32'hffffffff, 4'hF);
	  board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h818, 32'hffffffff, 4'hF);
	  board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h81C, 32'hffffffff, 4'hF);
	  board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h820, 32'hffffffff, 4'hF);

    //-------------- Ind Dire CTXT DATA 0x00000000_00000100_00120005_00000000 all 128 bits -------------------
      wr_dat[31 :0]  = 32'h00000000;
      wr_dat[35 :32] = 4'h5;
      wr_dat[43 :36] = {4'h0,pfTestIteration[3:0]};   // function ID
      wr_dat[63 :44] = dsc_bypass ? 20'h00160 : 20'h00120;
      wr_dat[95 :64] = 32'h00000100;
      wr_dat[127:96] = 32'h00000000;

	  board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h804, wr_dat[31 :0 ], 4'hF);
	  board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h808, wr_dat[63 :32], 4'hF);
	  board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h80C, wr_dat[95 :64], 4'hF);
	  board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h810, wr_dat[127:96], 4'hF);

     //board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h804);  //Read
     //board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h808);  //Read
     //board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h80C);  //Read
     //board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h810);  //Read

     //board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h6404);  //Read

    //-------------- Ind Dire CTXT CMD 0x824 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------	
    // [17:7] QID   00
    // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
    // [4:1]  MDMA_CTXT_SELC_DSC_SW_H2C = 1 : 0001
    // 0      BUSY : 0 
    //        00000000000_01_0001_0 : 0x22
    wr_dat = {14'h0,axi_mm_q[10:0],7'b0100010};
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, wr_dat[31:0], 4'hF);

    //-------------- ARM H2C transfer 0x1204 MDMA_H2C_MM0_CONTROL set to run--------
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h1204, 32'h00000001, 4'hF);
      
    //-------------- Start DMA tranfer ------------------------------------------------------
      $display(" **** Start AXI-MM H2C transfer ***\n");

 
    fork
    //-------------- Writ PIDX to 1 to transfer 1 descriptor ----------------
    //write address
    wr_add = 32'h00006400 + (axi_mm_q* 16) + 4;  // 32'h00006404
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(wr_add[31:0], 32'h1, 4'hF);   // Write 1 PIDX 


//     board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h6404);  //Read PIDX pointer

     // // Read SW CTXT values
     // // [17:7] QID   00
     // // [6:5 ] MDMA_CTXT_CMD_RD=2 : 10
     // // [4:1]  MDMA_CTXT_SELC_DSC_SW_H2C = 1 : 0001
     // // 0      BUSY : 0 
     // //        0000000000_0100_0010 : 0x42
     // board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, 32'h00000042, 4'hF);

     // board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h804);  //Read SW CTXT DATA
     // board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h808);  //Read SW CTXT DATA
     // board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h80C);  //Read SW CTXT DATA
     // board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h810);  //Read SW CTXT DATA
     // board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h1404);  //Read PIDX pointer

    //-------------- compare H2C data -------------------------------------------------------
      $display("------Compare H2C AXI-MM Data--------\n");
      board.RP.tx_usrapp.COMPARE_DATA_H2C({16'h0,board.RP.tx_usrapp.DMA_BYTE_CNT},768);    //input payload bytes
    join
    
    board.RP.tx_usrapp.COMPARE_TRANS_STATUS(32'h000002E0, 16'h1); 

    board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h1248);
    $display ("**** H2C Decsriptor Count = %h\n", P_READ_DATA);

    $display ("AXI-MM H2C completed \n");

    //-------------- XDMA H2C and C2H Transfer separated by 1000ns --------------------------
      #1000;

    //----------------------------------------------------------------------------------------
    // XDMA AXI-MM C2H Test Starts
    //----------------------------------------------------------------------------------------
	
      $display(" *** QDMA AXI-MM C2H *** \n");

      desc_count = 0;
      loop_timeout = 0;
    //-------------- Load DATA in Buffer ----------------------------------------------------
    // C2H DSC starts at 0x0400 (1024)
    // C2H data starts at 0x0600 (1536)
      board.RP.tx_usrapp.TSK_INIT_QDMA_MM_DATA_C2H;

    //-------------- Ind Direct CTXT MASK is already set -------------------
    //-------------- Ind Dire CTXT DATA 0x00000000_00000400_00120005_00000000 all 128 bits -------------------
      wr_dat[31 :0]  = 32'h00000000;
      wr_dat[35 :32] = 4'h5;
      wr_dat[43 :36] = {4'h0,pfTestIteration[3:0]};   // function ID
      wr_dat[63 :44] = dsc_bypass ? 20'h00160 : 20'h00120;
      wr_dat[95 :64] = 32'h00000400;
      wr_dat[127:96] = 32'h00000000;

	  board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h804, wr_dat[31 :0] , 4'hF);
	  board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h808, wr_dat[63 :32], 4'hF);
	  board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h80C, wr_dat[95 :64], 4'hF);
	  board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h810, wr_dat[127:96], 4'hF);

    //-------------- Ind Dire CTXT CMD 0x824 [17:7] Qid : 1 [17:7] : CMD MDMA_CTXT_CMD_WR=1 ---------	
    // [17:7] QID   00
    // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
    // [4:1]  MDMA_CTXT_SELC_DSC_SW_C2H = 0 : 0000
    // 0      BUSY : 0 
    //        00000000000_01_0000_0 : 0010_0000 : 0x20
    wr_dat = {14'h0,axi_mm_q[10:0],7'b0100000};
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, wr_dat[31:0], 4'hF);

    //-------------- ARM C2H transfer 0x1004 MDMA_C2H_MM0_CONTROL set to run--------
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h1004, 32'h00000001, 4'hF);
      
    //-------------- Start DMA tranfer ------------------------------------------------------
      $display(" **** Start DMA C2H transfer ***\n");

    fork
    //-------------- Write PIDX to 1 to transfer 1 descriptor in C2H ----------------
     wr_add = 32'h00006400 + (axi_mm_q* 16) + 8;  // 32'h00006408    
      board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(wr_add[31:0], 32'h1, 4'hF); // Write 1 PIDX 

    //compare C2H data
      $display("------Compare C2H AXI-MM Data--------\n");
      // for coparision H2C data is stored in 768
      board.RP.tx_usrapp.COMPARE_DATA_C2H({16'h0,board.RP.tx_usrapp.DMA_BYTE_CNT},768);
    join

    board.RP.tx_usrapp.COMPARE_TRANS_STATUS(32'h000005E0, 16'h1); 

    board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h1048);
    $display ("**** C2H Decsriptor Count = %h\n", P_READ_DATA);

    $display ("AXI-MM C2H completed \n");


end
endtask


task TSK_QDMA_ST_TEST;
   input dsc_bypass;
begin
   //
// now doing AXI-Stream Test for QDMA
//
// Assign Q 2 for AXI-ST
 pf0_qmax = 11'h200;
 axi_st_q = 11'h2;

 // Write Q number for AXI-ST C2H transfer
 board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h0, {21'h0,axi_st_q[10:0]}, 4'hF);   // Write Q num to user side 
// IMPL SIM board.EP.user_control_i.c2h_st_qid = {21'h0,axi_st_q[10:0]};

 $display ("******* AXI-ST H2C/C2H transfer START ******** \n");
 $display ("\n");
 $display ("\n");
 //-------------- Load DATA in Buffer for aXI-ST H2C----------------------------------------------------
 // AXI-St H2C Descriptor is at address 0x0100 (256)
 // AXI-St H2c Data       is at address 0x0200 (512)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_H2C_NEW;

 //-------------- Load DATA in Buffer for AXI-ST C2H ----------------------------------------------------
 // AXI-St C2H Descriptor is at address 0x0400 (1024)
 // AXI-St C2H Data       is at address 0x0500 (1280)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_C2H;
 // AXI-St C2H WBK Data   is at address 0x0800 (2048)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_WBK_C2H;     // addrss 0x800 (2048)

   // enable dsc bypass loopback
   if (dsc_bypass)
     board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h90, 32'h3, 4'hF);
// IMPL SIM     board.EP.user_control_i.dsc_bypass[1:0] = 2'h3;


    
 // Test Mailbox
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h2400, 32'hdeadbeef, 4'hF);

 //
 // Global programming
 //
 //-------------- Global Ring Size for entry 0 0x204  : num of dsc 15+1 ------------------------
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h204, 32'h00000010, 4'hF);
 //-------------- Global Ring Size for entry 1 0x208  : num of dsc 15+1 ------------------------
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h208, 32'h00000010, 4'hF);

 //-------------- Global Function MAP 0x400  : Func0 22:11 Qnumber ( 1 Queue ) : 10:0 Qid_base for this Func
 //-------------- Global Function MAP 0x400  : Func0 22:11 Qnumber ( 16 Queue ) : 10:0 Qid_base for this Func
 // set up 16Queues
 // Func number is 0 : 0*4 = 0: address 0x400+ Fnum*4 = 0x400
 // 22:11 : 1_0000 : number of queues for this function. 
 // 10:0  : 000_0000_0000 : Queue off set 
 // 1000_0000_0000_0000 : 0x8000
	for(pf_loop_index=0; pf_loop_index <= pfTestIteration; pf_loop_index = pf_loop_index + 1)
	begin
	 if(pf_loop_index == pfTestIteration) begin
		wr_dat = {14'h0,pf0_qmax[10:0],11'h00};
		board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h400+(pf_loop_index*4), wr_dat[31:0], 4'hF);
	 end else begin
	    wr_dat = 32'h00000000;
		board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h400+(pf_loop_index*4), wr_dat[31:0], 4'hF);
	 end
	end

 //-------------- Clear HW CXTX for H2C and C2H first for Q1 ------------------------------------
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_H2C = 3 : 0011
 // 0      BUSY : 0 
 //        00000000001_00_0011_0 : _1000_0110 : 0x86
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000110};
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, wr_dat[31:0], 4'hF);

 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_C2H = 2 : 0010
 // 0      BUSY : 0 
 //        00000000001_00_0010_0 : _1000_0100 : 0x84
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000100};
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, wr_dat[31:0], 4'hF);

 $display ("******* Program C2H Global and Context values ******** \n");
 // Setup Stream H2C context 
 //-------------- Ind Dire CTXT MASK 0x814  0xffffffff for all 128 bits -------------------
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h814, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h818, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h81C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h820, 32'hffffffff, 4'hF);

 //-------------- Ind Dire CTXT AXI-ST H2C DATA 0x00000000_00000100_00111005_00000000 all 128 bits -------------------
 // ring size index is at 1
 // 
   wr_dat[31 :0]  = 32'h00000000;
   wr_dat[35 :32] = 4'h5;
   wr_dat[43 :36] = {4'h0,pfTestIteration[3:0]};   // function ID
   wr_dat[63 :44] = dsc_bypass ? 20'h00151 : 20'h00111;
   wr_dat[95 :64] = 32'h00000100;
   wr_dat[127:96] = 32'h00000000;
   
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h804, wr_dat[31 :0], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h808, wr_dat[63 :32], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h80C, wr_dat[95 :64], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h810, wr_dat[127:96], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x824 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID : 2
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_DSC_SW_H2C = 1 : 0001
 // 0      BUSY : 0 
 //        00000000001_01_0001_0 : 1010_0010 : 0xA2
 wr_dat = {14'h0,axi_st_q[10:0],7'b0100010};
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, wr_dat[31:0], 4'hF);

 // Program AXI-ST C2H 
 //-------------- Program C2H WBK timer Trigger to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'hA00, 32'h00000001, 4'hF);

 //-------------- Program C2H WBK Counter Threshold to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'hA40, 32'h00000001, 4'hF);

 //-------------- Program C2H DSC buffer size to 4K ----------------------------------------------
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'hAB0, 32'h00001000, 4'hF);

 // setup Stream C2H context
 //-------------- C2H CTXT DATA 0x00000000_00000400_00111005_00000000 all 128 bits -------------------
 // ring size index is at 1
 // 
 // wbi_acc_en = 0, wbi_chk = 1, fcrd_en = 1, qen = 1  ==> 4'h7  
 // fun_id = 8'h00
 // rng_sz = 4'h0 (ring index = 0 for 16 dsc)
 // mm_chn = 0, byp = 0, dsc_sz = 0 (8Bytes) ==> 4'0
 // rsv0 = 00, irq_en = 0, wbk_en = 1  ==> 4'h1
 // ring addres = 0x400 (1024) ==> 0x400

   wr_dat[31 :0]  = 32'h00000000;
   wr_dat[35 :32] = 4'h7;
   wr_dat[43 :36] = {4'h0,pfTestIteration[3:0]};   // function ID
   wr_dat[63 :44] = dsc_bypass ? 20'h00140 : 20'h00100;
   wr_dat[95 :64] = 32'h00000400;
   wr_dat[127:96] = 32'h00000000;

   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h804, wr_dat[31 :0], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h808, wr_dat[63 :32], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h80C, wr_dat[95 :64], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h810, wr_dat[127:96], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x824 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID : 2
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_DSC_SW_C2H = 0 : 0000
 // 0      BUSY : 0 
 //        00000000001_01_0000_0 : 1010_0000 : 0xA0
 wr_dat = {14'h0,axi_st_q[10:0],7'b0100000};
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, wr_dat[31:0], 4'hF);

 //-------------- WriteBACK CTXT DATA 0x00000000_00000400_00111005_00000000 all 128 bits -------------------
 wr_dat[0]      = 1;      // en_stat_desc = 1
 wr_dat[1]      = 0;      // en_int = 0
 wr_dat[4:2]    = 3'h1;   // trig_mode = 3'b001   : 0_0101 0x05
 wr_dat[12:5]   = {4'h0,pfTestIteration[3:0]};   // function ID
 wr_dat[16:13]  = 4'h0;   // countr_idx  = 4'b0000 : 0 0000_0000_0000_0101 0x0005
 wr_dat[20:17]  = 4'h0;   // timer_idx = 4'b0000  : 0_0000 0000_0000_0000_0101 0x00005
 wr_dat[22:21]  = 2'h0;   // int_st = 2'b00       : 000_0000 0000_0000_0000_0101 
 wr_dat[23]     = 1'h1;   // color = 1            : 1000_0000 0000_0000_0000_0101  0x800004
 wr_dat[27:24]  = 4'h0;   // size_64 = 4'h0       : 0x0800005 
 wr_dat[85:28]  = 58'h20; // baddr_64 = [63:6]only :  20   : 00000 0x0000_0002 0x0080_0005
 wr_dat[87:86]  = 2'h0;   // desc_size = 2'b00    : x00_0000 0x0000_0002 0x0080_0005
 wr_dat[103:88] = 16'h0;  // pidx 16              : 0x00 x0000_0000 0x0000_0002 0x0080_0005
 wr_dat[119:104]= 16'h0;  // Cidx 16              : 0x00_0000 x0000_0000 0x0000_0002 0x0080_0005
 wr_dat[120]    = 1'h1;   // valid = 1            : 0x100_0000 x0000_0000 0x0000_0002 0x0080_0005
 wr_dat[127:121]= 'h0;    // reserved

   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h804, wr_dat[31:0], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h808, wr_dat[63:32], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h80C, wr_dat[95:64], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h810, wr_dat[127:96], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x824 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_WBK = 6 : 0110
 // 0      BUSY : 0 
 //        00000000001_01_0110_0 : 1010_1100 : 0xAC
 wr_dat = {14'h0,axi_st_q[10:0],7'b0101100};
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, wr_dat[31:0], 4'hF);

 //Also update CIDX 0x00 for WBK context 
 // sw_cidx = 16'h0000
 // counter_idx = 4'h0
 // timer_idx = 4'h0
 // trig_mode = 3'001
 // en_stat_desc = 1
 // en_int = 0
 // pad = 3'b0
 // 0900_0000
 wr_add = 32'h00006400 + (axi_st_q* 16) + 12;  // 32'h0000641C
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(wr_add[31:0], 32'h09000000, 4'hF);

 //-------------- PreFetch CTXT DATA 0x00000000_00000400_00111005_00000000 all 128 bits -------------------
 // valid = 1
 // all 0's
 // 0010_0000_0000_0000 => 2000
   wr_dat[4 :0]   = 5'h00;
   wr_dat[7 :5]   = 3'h0;
   wr_dat[25 :8]  = 18'h0; // reserverd
   wr_dat[26]     = 1'h0;  // error
   wr_dat[27]     = 1'h0;  // prefetch enable
   wr_dat[31 :28] = 4'h0;
   wr_dat[63 :32] = 32'h00002000;
   wr_dat[95 :64] = 32'h00000000;
   wr_dat[127:96] = 32'h00000000;

   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h804, wr_dat[31:0], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h808, wr_dat[63:32], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h80C, wr_dat[95:64], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h810, wr_dat[127:96], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x824 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_PFTCH = 7 : 0111
 // 0      BUSY : 0 
 //        00000000001_01_0111_0 : 1010_1110 : 0xAE
 wr_dat = {14'h0,axi_st_q[10:0],7'b0101110};
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, wr_dat[31:0], 4'hF);

 // Transfer C2H for 1 dsc

 //-------------- Write PIDX to 1 to transfer 1 descriptor in C2H ----------------
 //  There is no run bit for AXI-Stream, no need to arm them.
   $display(" **** Enable PIDX for C2H first ***\n");
   wr_add = 32'h00006400 + (axi_st_q* 16) + 8;  // 32'h00006418
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(wr_add[31:0], 32'h0a, 4'hF);   // Write 0x0a PIDX 

///
 // Initiate C2H tranfer on user side.
 board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h20, 32'h1, 4'hF);   // send 1 packets 
// IMPL SIM board.EP.user_control_i.c2h_num_pkt = 11'h1;

 board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h04, 32'h80, 4'hF);   // C2H length 128 bytes //
// IMPL SIM board.EP.user_control_i.c2h_st_len = 16'h80;

 board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h30, 32'ha4a3a2a1, 4'hF);   // Write back data 
 board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h34, 32'hb4b3b2b1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h38, 32'hc4c3c2c1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h3C, 32'hd4d3d2d1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h40, 32'he4e3e2e1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h44, 32'hf4f3f2f1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h48, 32'h14131211, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h4C, 32'h24232221, 4'hF);   // Write back data
 
// IMPL SIM board.EP.user_control_i.wb_dat[31:0]    = 32'ha4a3a2a1;
// IMPL SIM board.EP.user_control_i.wb_dat[63:32]   = 32'hb4b3b2b1;
// IMPL SIM board.EP.user_control_i.wb_dat[95:64]   = 32'hc4c3c2c1;
// IMPL SIM board.EP.user_control_i.wb_dat[127:96]  = 32'hd4d3d2d1;
// IMPL SIM board.EP.user_control_i.wb_dat[159:128] = 32'he4e3e2e1;
// IMPL SIM board.EP.user_control_i.wb_dat[191:160] = 32'hf4f3f2f1;
// IMPL SIM board.EP.user_control_i.wb_dat[223:192] = 32'h14131211;
// IMPL SIM board.EP.user_control_i.wb_dat[255:224] = 32'h24232221;
 

//    board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h50, 32'h2, 4'hF);   // writeback data control to set 8B, 16B or 32B

//    board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h08, 32'h06, 4'hF);   // Start C2H tranfer and immediate data
 board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h08, 32'h02, 4'hF);   // Start C2H tranfer
// IMPL SIM board.EP.user_control_i.control_reg_c2h = 32'h02;

 //compare C2H data
   $display("------Compare C2H AXI-ST 1st Data--------\n");
   // compare data with H2C data in 512
   board.RP.tx_usrapp.COMPARE_DATA_C2H({16'h0,board.RP.tx_usrapp.DMA_BYTE_CNT},512);

   // Compare status writes
   board.RP.tx_usrapp.COMPARE_TRANS_C2H_ST_STATUS(32'h00000800, 16'h1); //Write back entry and write back status
   
   // uptate CIDX for Write back 
   wr_add = 32'h00006400 + (axi_st_q* 16) + 12;  // 32'h0000641C
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(wr_add[31:0], 32'h09000001, 4'hF);

 // ACI-ST H2C transfer
 //
 // dummy clear H2c match
 board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h0C, 32'h01, 4'hF);   // Dummy clear H2C match
// IMPL SIM board.EP.user_control_i.control_reg_h2c = 32'h01;
 //-------------- Start DMA H2C tranfer ------------------------------------------------------
   $display(" **** Start DMA H2C AXI-ST transfer ***\n");

 fork
 //-------------- Write Queue 1 of PIDX to 1 to transfer 1 descriptor in H2C ----------------
   wr_add = 32'h00006400 + (axi_st_q* 16) + 4;  // 32'h00006414
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(wr_add[31:0], 32'h1, 4'hF);   // Write 1 PIDX 

 //compare H2C data
   $display("------Compare H2C AXI-ST Data--------\n");
   board.RP.tx_usrapp.COMPARE_TRANS_STATUS(32'h000001F0, 16'h1); 
 join

 // check for if data on user side matched what was expected.
 board.RP.tx_usrapp.TSK_USR_BAR_REG_READ(32'h10);   // Read H2C status and Queue info.
 $display ("**** H2C Data Match Status = %h\n", P_READ_DATA);
 if (P_READ_DATA[0] == 1'b1) begin
    $display ("[%t] : TEST PASSED ---**** H2C Data Matches and H2C Q number = %h\n",$realtime, P_READ_DATA[10:4]);
    $display("[%t] : Test Completed Successfully for PF{%d}",$realtime,pfTestIteration);
 end else begin
    $display ("[%t] : TEST FAILED ---****ERROR**** H2C Data Mis-Matches and H2C Q number = %h\n",$realtime, P_READ_DATA[10:4]);
 end
 end
 endtask

task TSK_QDMA_ST_LOOPBACK_TEST;
   input dsc_bypass;
begin
   //
// now doing AXI-Stream Test for QDMA
//
// Assign Q 2 for AXI-ST
 axi_st_q = 11'h2;

 // Write Q number for AXI-ST C2H transfer
 board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h0, {21'h0,axi_st_q[10:0]}, 4'hF);   // Write Q num to user side 

 $display ("******* AXI-ST H2C/C2H loopback test START ******** \n");
 $display ("\n");
 $display ("\n");
 //-------------- Load DATA in Buffer for aXI-ST H2C----------------------------------------------------
 // AXI-St H2C Descriptor is at address 0x0100 (256)
 // AXI-St H2c Data       is at address 0x0200 (512)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_H2C_NEW;

 //-------------- Load DATA in Buffer for AXI-ST C2H ----------------------------------------------------
 // AXI-St C2H Descriptor is at address 0x0400 (1024)
 // AXI-St C2H Data       is at address 0x0500 (1280)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_C2H;
 // AXI-St C2H WBK Data   is at address 0x0800 (2048)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_WBK_C2H;     // addrss 0x800 (2048)

   board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h08, 32'h1, 4'hF); //Enable loopback

 //
 // Global programming
 //
 //-------------- Clear HW CXTX for H2C and C2H first for Q1 ------------------------------------
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_H2C = 3 : 0011
 // 0      BUSY : 0 
 //        00000000001_00_0011_0 : _1000_0110 : 0x86
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, 32'h00000086, 4'hF);
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_C2H = 2 : 0010
 // 0      BUSY : 0 
 //        00000000001_00_0010_0 : _1000_0100 : 0x84
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, 32'h00000084, 4'hF);
 
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, 32'h0000008E, 4'hF); //clear C2H prefetch context fro Queue 1

 // Clear HW CTX for Q2
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, 32'h00000106, 4'hF);
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, 32'h00000104, 4'hF); 
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, 32'h0000010E, 4'hF); //clear C2H prefetch context fro Queue 2

 //-------------- Global Ring Size for entry 0 0x204  : num of dsc 15+1 ------------------------
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h204, 32'h00000010, 4'hF);
 //-------------- Global Ring Size for entry 1 0x208  : num of dsc 15+1 ------------------------
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h208, 32'h00000010, 4'hF);

 //-------------- Global Function MAP 0x400  : Func0 22:11 Qnumber ( 1 Queue ) : 10:0 Qid_base for this Func
 //-------------- Global Function MAP 0x400  : Func0 22:11 Qnumber ( 16 Queue ) : 10:0 Qid_base for this Func
 // set up 16Queues
 // Func number is 0 : 0*4 = 0: address 0x400+ Fnum*4 = 0x400
 // 22:11 : 1_0000 : number of queues for this function. 
 // 10:0  : 000_0000_0000 : Queue off set 
 // 1000_0000_0000_0000 : 0x8000
 	for(pf_loop_index=0; pf_loop_index <= pfTestIteration; pf_loop_index = pf_loop_index + 1)
	begin
	 if(pf_loop_index == pfTestIteration) begin
       board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h400+(pf_loop_index*4), 32'h00008000, 4'hF);
	 end else begin
       board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h400+(pf_loop_index*4), 32'h00000000, 4'hF);
	 end
	end


 $display ("******* Program C2H Global and Context values ******** \n");
 // Setup Stream H2C context 
 //-------------- Ind Dire CTXT MASK 0x814  0xffffffff for all 128 bits -------------------
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h814, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h818, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h81C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h820, 32'hffffffff, 4'hF);

 //-------------- Ind Dire CTXT AXI-ST H2C DATA 0x00000000_00000100_00111005_00000000 all 128 bits -------------------
 // ring size index is at 1
 // 
   wr_dat[31 :0]  = 32'h00000000;
   wr_dat[35 :32] = 4'h5;
   wr_dat[43 :36] = {4'h0,pfTestIteration[3:0]};   // function ID
   wr_dat[63 :44] = dsc_bypass ? 20'h00151 : 20'h00111;
   wr_dat[95 :64] = 32'h00000100;
   wr_dat[127:96] = 32'h00000000;

   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h804, wr_dat[31 :0], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h808, wr_dat[63 :32], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h80C, wr_dat[95 :64], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h810, wr_dat[127:96], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x824 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID : 2
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_DSC_SW_H2C = 1 : 0001
 // 0      BUSY : 0 
 //        00000000001_01_0001_0 : 1010_0010 : 0xA2
 wr_dat = {14'h0,axi_st_q[10:0],7'b0100010};
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, wr_dat[31:0], 4'hF);
 
 // Program AXI-ST C2H 
 //-------------- Program C2H WBK timer Trigger to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'hA00, 32'h00000001, 4'hF);

 //-------------- Program C2H WBK Counter Threshold to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'hA40, 32'h00000001, 4'hF);

 //-------------- Program C2H DSC buffer size to 4K ----------------------------------------------
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'hAB0, 32'h00001000, 4'hF);

 // setup Stream C2H context
 //-------------- C2H CTXT DATA 0x00000000_00000400_00111005_00000000 all 128 bits -------------------
 // ring size index is at 1
 // 
 // wbi_acc_en = 0, wbi_chk = 1, fcrd_en = 1, qen = 1  ==> 4'h7  
 // fun_id = 8'h00
 // rng_sz = 4'h0 (ring index = 0 for 16 dsc)
 // mm_chn = 0, byp = 0, dsc_sz = 0 (8Bytes) ==> 4'0
 // rsv0 = 00, irq_en = 0, wbk_en = 1  ==> 4'h1
 // ring addres = 0x400 (1024) ==> 0x400

   wr_dat[31 :0]  = 32'h00000000;
   wr_dat[35 :32] = 4'h7;
   wr_dat[43 :36] = {4'h0,pfTestIteration[3:0]};   // function ID
   wr_dat[63 :44] = dsc_bypass ? 20'h00140 : 20'h00100;
   wr_dat[95 :64] = 32'h00000400;
   wr_dat[127:96] = 32'h00000000;
   
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h804, wr_dat[31 :0], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h808, wr_dat[63 :32], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h80C, wr_dat[95 :64], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h810, wr_dat[127:96], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x824 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID : 2
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_DSC_SW_C2H = 0 : 0000
 // 0      BUSY : 0 
 //        00000000001_01_0000_0 : 1010_0000 : 0xA0
 wr_dat = {14'h0,axi_st_q[10:0],7'b0100000};
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, wr_dat[31:0], 4'hF);

 //-------------- WriteBACK CTXT DATA 0x00000000_00000400_00111005_00000000 all 128 bits -------------------
 wr_dat[0]      = 1;      // en_stat_desc = 1
 wr_dat[1]      = 0;      // en_int = 0
 wr_dat[4:2]    = 3'h1;   // trig_mode = 3'b001   : 0_0101 0x05
 wr_dat[12:5]   = {4'h0,pfTestIteration[3:0]};   // function ID     : 0_0000_0000_0101 0x005
 wr_dat[16:13]  = 4'h0;   // countr_idx  = 4'b0000 : 0 0000_0000_0000_0101 0x0005
 wr_dat[20:17]  = 4'h0;   // timer_idx = 4'b0000  : 0_0000 0000_0000_0000_0101 0x00005
 wr_dat[22:21]  = 2'h0;   // int_st = 2'b00       : 000_0000 0000_0000_0000_0101 
 wr_dat[23]     = 1'h1;   // color = 1            : 1000_0000 0000_0000_0000_0101  0x800004
 wr_dat[27:24]  = 4'h0;   // size_64 = 4'h0       : 0x0800005 
 wr_dat[85:28]  = 58'h20; // baddr_64 = [63:6]only :  20   : 00000 0x0000_0002 0x0080_0005
 wr_dat[87:86]  = 2'h0;   // desc_size = 2'b00    : x00_0000 0x0000_0002 0x0080_0005
 wr_dat[103:88] = 16'h0;  // pidx 16              : 0x00 x0000_0000 0x0000_0002 0x0080_0005
 wr_dat[119:104]= 16'h0;  // Cidx 16              : 0x00_0000 x0000_0000 0x0000_0002 0x0080_0005
 wr_dat[120]    = 1'h1;   // valid = 1            : 0x100_0000 x0000_0000 0x0000_0002 0x0080_0005
 wr_dat[127:121]= 'h0;    // reserved

   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h804, wr_dat[31:0], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h808, wr_dat[63:32], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h80C, wr_dat[95:64], 4'hF);
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h810, wr_dat[127:96], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x824 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_WBK = 6 : 0110
 // 0      BUSY : 0 
 //        00000000001_01_0110_0 : 1010_1100 : 0xAC
 wr_dat = {14'h0,axi_st_q[10:0],7'b0101100};
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, wr_dat[31:0], 4'hF);

 //Also update CIDX 0x00 for WBK context 
 // sw_cidx = 16'h0000
 // counter_idx = 4'h0
 // timer_idx = 4'h0
 // trig_mode = 3'001
 // en_stat_desc = 1
 // en_int = 0
 // pad = 3'b0
 // 0900_0000
 wr_add = 32'h00006400 + (axi_st_q* 16) + 12;  // 32'h0000641C
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(wr_add[31:0], 32'h09000000, 4'hF);

 //-------------- PreFetch CTXT DATA all 128 bits -------------------
 wr_dat[31 :0]  = 32'h18000000;
 wr_dat[63 :32] = 32'h00002000;
 wr_dat[95 :64] = 32'h00000000;
 wr_dat[127:96] = 32'h00000000;
 
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h804, wr_dat[31 :0], 4'hF);
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h808, wr_dat[63 :32], 4'hF);
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h80C, wr_dat[95 :64], 4'hF);
 board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h810, wr_dat[127:96], 4'hF);

//-------------- Ind Dire CTXT CMD 0x824 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
// [17:7] QID : 2
// [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
// [4:1]  MDMA_CTXT_SELC_C2H_PFCH = 7 : 0111
// 0      BUSY : 0 
//        00000000001_01_0001_0 : 1010_0010 : 0xA2
wr_dat = {14'h0,axi_st_q[10:0],7'b0101110};
board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h824, wr_dat[31:0], 4'hF);

 // Transfer C2H for 1 dsc

 //-------------- Write PIDX to 1 to transfer 1 descriptor in C2H ----------------
 //  There is no run bit for AXI-Stream, no need to arm them.
   $display(" **** Enable PIDX for C2H first ***\n");
   wr_add = 32'h00006400 + (axi_st_q* 16) + 8;  // 32'h00006418
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(wr_add[31:0], 32'h0a, 4'hF);   // Write 0x0a PIDX 
   
    // ACI-ST H2C transfer
   //
   // dummy clear H2c match
   board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h0C, 32'h01, 4'hF);   // Dummy clear H2C match
   //-------------- Start DMA H2C tranfer ------------------------------------------------------
     $display(" **** Start DMA H2C AXI-ST transfer ***\n");
  
   fork
   //-------------- Write Queue 1 of PIDX to 1 to transfer 1 descriptor in H2C ----------------
     wr_add = 32'h00006400 + (axi_st_q* 16) + 4;  // 32'h00006414
     board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(wr_add[31:0], 32'h1, 4'hF);   // Write 1 PIDX 
  
   //compare H2C data
     $display("------Compare H2C AXI-ST Data--------\n");
     board.RP.tx_usrapp.COMPARE_TRANS_STATUS(32'h000001F0, 16'h1); 
   join

 //compare C2H data
   $display("------Compare C2H AXI-ST 1st Data--------\n");
   // compare data with H2C data in 512
   board.RP.tx_usrapp.COMPARE_DATA_C2H({16'h0,board.RP.tx_usrapp.DMA_BYTE_CNT},512);

   // Compare status writes
   board.RP.tx_usrapp.COMPARE_TRANS_C2H_ST_STATUS(32'h00000800, 16'h1); //Write back entry and write back status
   
   // uptate CIDX for Write back 
   wr_add = 32'h00006400 + (axi_st_q* 16) + 12;  // 32'h0000641C
   board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(wr_add[31:0], 32'h09000001, 4'hF);

end
endtask

    /************************************************************
    Task : TSK_SYSTEM_INITIALIZATION
    Inputs : None
    Outputs : None
    Description : Waits for Transaction Interface Reset and Link-Up
    *************************************************************/

    task TSK_SYSTEM_INITIALIZATION;
        begin

        //--------------------------------------------------------------------------
        // Event # 1: Wait for Transaction reset to be de-asserted...
        //--------------------------------------------------------------------------
        wait (reset == 0);
        $display("[%t] : Transaction Reset Is De-asserted...", $realtime);

        //--------------------------------------------------------------------------
        // Event # 2: Wait for Transaction link to be asserted...
        //--------------------------------------------------------------------------
        board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(32'h01, 32'h00000007, 4'h1);
        board.RP.cfg_usrapp.TSK_READ_CFG_DW(DEV_CTRL_REG_ADDR/4);	
        board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(DEV_CTRL_REG_ADDR/4,( board.RP.cfg_usrapp.cfg_rd_data | (DEV_CAP_MAX_PAYLOAD_SUPPORTED * 32)) , 4'h1);	
	

        board.RP.tx_usrapp.TSK_TX_CLK_EAT(100);
        wait (board.RP.pcie_4_0_rport.user_lnk_up == 1);
        board.RP.tx_usrapp.TSK_TX_CLK_EAT(100);

        $display("[%t] : Transaction Link Is Up...", $realtime);

        TSK_SYSTEM_CONFIGURATION_CHECK;

        end
    endtask

    /************************************************************
    Task : TSK_SYSTEM_CONFIGURATION_CHECK
    Inputs : None
    Outputs : None
    Description : Check that options selected from Coregen GUI are
                  set correctly.
                  Checks - Max Link Speed/Width, Device/Vendor ID, CMPS
    *************************************************************/

    task TSK_SYSTEM_CONFIGURATION_CHECK;
        begin

        error_check = 0;

        // Check Link Speed/Width
        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, LINK_CTRL_REG_ADDR, 4'hF); // 12'hD0
        TSK_WAIT_FOR_READ_DATA;

        if  (P_READ_DATA[19:16] == MAX_LINK_SPEED) begin
            if (P_READ_DATA[19:16] == 1)
                $display("[%t] :    Check Max Link Speed = 2.5GT/s - PASSED", $realtime);
            else if(P_READ_DATA[19:16] == 2)
                $display("[%t] :    Check Max Link Speed = 5.0GT/s - PASSED", $realtime);
            else if(P_READ_DATA[19:16] == 3)
                $display("[%t] :    Check Max Link Speed = 8.0GT/s - PASSED", $realtime);
            else if(P_READ_DATA[19:16] == 4)
                $display("[%t] :    Check Max Link Speed = 16.0GT/s - PASSED", $realtime);
        end else begin
            $display("[%t] :    Check Max Link Speed - FAILED", $realtime);
            $display("[%t] :    Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime, MAX_LINK_SPEED, P_READ_DATA[19:16]);
        end

        if  (P_READ_DATA[24:20] == LINK_CAP_MAX_LINK_WIDTH)
              $display("[%t] :    Check Negotiated Link Width = 5'h%x - PASSED", $realtime, LINK_CAP_MAX_LINK_WIDTH);
        else
              $display("[%t] :    Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime, LINK_CAP_MAX_LINK_WIDTH, P_READ_DATA[24:20]);

        // Check Device/Vendor ID
        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h0, 4'hF);
        TSK_WAIT_FOR_READ_DATA;

        if  (P_READ_DATA[31:16] != EP_DEV_ID1) begin
            $display("[%t] :    Check Device/Vendor ID - FAILED", $realtime);
            $display("[%t] :    Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime, EP_DEV_ID1, P_READ_DATA);

        //    error_check = 1;
        end else begin
            $display("[%t] :    Check Device/Vendor ID - PASSED", $realtime);
        end

        // Check CMPS
        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, PCIE_DEV_CAP_ADDR, 4'hF); //12'hC4
        TSK_WAIT_FOR_READ_DATA;

        if (P_READ_DATA[2:0] != DEV_CAP_MAX_PAYLOAD_SUPPORTED) begin
            $display("[%t] :    Check CMPS ID - FAILED", $realtime);
            $display("[%t] :    Data Error Mismatch, Parameter Data %x != Read data %x", $realtime, DEV_CAP_MAX_PAYLOAD_SUPPORTED, P_READ_DATA[2:0]);

        //    error_check = 1;
        end else begin
            $display("[%t] :    Check CMPS ID - PASSED", $realtime);
        end


        if (error_check == 0) begin
            $display("[%t] :    SYSTEM CHECK PASSED", $realtime);
        end else begin
            $display("[%t] :    SYSTEM CHECK FAILED", $realtime);
            $finish;
        end

        end
    endtask

    /************************************************************
    Task : TSK_RESET
    Inputs : Reset
    Outputs : PERSTn
    Description : Initiates PERSTn
    *************************************************************/

    task TSK_RESET;
        input reset_;

        board.sys_rst_n = reset_;

    endtask

    /************************************************************
    Task : TSK_MALFORMED
    Inputs : Malformed Type
    Outputs : Transaction Tx Interface Signaling
    Description : Generates Malformed TLPs
    *************************************************************/

    task TSK_MALFORMED;
        input type_;
        reg [31:0] mem32_base;
        reg        mem32_base_enabled;
        reg [63:0] mem64_base;
        reg        mem64_base_enabled;
        reg [31:0] io_base;
        reg        io_base_enabled;
        
        begin

            for (board.RP.tx_usrapp.ii = 0; board.RP.tx_usrapp.ii <= 6; board.RP.tx_usrapp.ii =
                board.RP.tx_usrapp.ii + 1) begin
                if (board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[board.RP.tx_usrapp.ii] == 2'b10) begin
                    mem32_base = board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0];
                    mem32_base_enabled = 1'b1; end

                else if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[board.RP.tx_usrapp.ii] == 2'b11) begin
                    mem64_base =  {board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii+1][31:0],
                                   board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0]};
                    mem64_base_enabled = 1'b1; end

                else if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[board.RP.tx_usrapp.ii] == 2'b01) begin
                    io_base =  board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0];
                    io_base_enabled = 1'b1; end

            end

            set_malformed = 1'b1;

            case(type_)
            8'h01: begin
                if(mem32_base_enabled) begin
                    board.RP.tx_usrapp.TSK_TX_MEMORY_WRITE_32(board.RP.tx_usrapp.DEFAULT_TAG,
                                                              board.RP.tx_usrapp.DEFAULT_TC, 10'd1,
                                                              mem32_base+8'h10, 4'h0, 4'hF, set_malformed);
                end
                else if(mem64_base_enabled) begin
                    board.RP.tx_usrapp.TSK_TX_MEMORY_WRITE_64(board.RP.tx_usrapp.DEFAULT_TAG,
                                                              board.RP.tx_usrapp.DEFAULT_TC, 10'd1,
                                                              mem64_base+8'h10, 4'h0, 4'hF, set_malformed);
                end
            end
            8'h02: begin
                if(mem32_base_enabled) begin
                    board.RP.tx_usrapp.TSK_TX_MEMORY_READ_32(board.RP.tx_usrapp.DEFAULT_TAG,
                                                             board.RP.tx_usrapp.DEFAULT_TC, 10'd1,
                                                             mem32_base+8'h10, 4'h0, 4'h0);
                 end
                 else if(mem64_base_enabled) begin
                    board.RP.tx_usrapp.TSK_TX_MEMORY_READ_64(board.RP.tx_usrapp.DEFAULT_TAG,
                                                             board.RP.tx_usrapp.DEFAULT_TC, 10'd1,
                                                             mem64_base+8'h10, 4'h0, 4'h0);
                end
            end
            8'h04: begin
                if(io_base_enabled) begin
                    board.RP.tx_usrapp.TSK_TX_IO_WRITE(board.RP.tx_usrapp.DEFAULT_TAG,
                                                       io_base, 4'hF, 32'hdead_beef);
                end
            end
            8'h08: begin
                if(io_base_enabled) begin
                    board.RP.tx_usrapp.TSK_TX_IO_READ(board.RP.tx_usrapp.DEFAULT_TAG,
                                                      io_base, 4'hF);
                end
            end
            8'h10: begin
                TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, PCIE_DEV_CAP_ADDR, 32'h0, 4'hF);
            end
            8'h20: begin
                TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, PCIE_DEV_CAP_ADDR, 4'hF);
            end
            8'h40: begin
                TSK_TX_MESSAGE(DEFAULT_TAG,3'b0,11'b0,64'b0, 3'b011,8'h0);
            end
            endcase
            
        end
    endtask

    /************************************************************
    Task : TSK_TX_TYPE0_CONFIGURATION_READ
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 0 Configuration Read TLP
    *************************************************************/

    task TSK_TX_TYPE0_CONFIGURATION_READ;
        input    [7:0]    tag_;         // Tag
        input    [11:0]   reg_addr_;    // Register Number
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //--------- CFG TYPE-0 Read Transaction :                     -----------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 8'h0F;            // 2DW Descriptor
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                64'b0,                   // Parity Bit slot - 64bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                16'h0000,                // TPH Steering Tag - 16 bit
                                                2'b00,                   // TPH indirect Tag Enable - 2bit
                                                4'b0000,                 // TPH Type - 4 bit
                                                2'b00,                   // TPH Present - 2 bit
                                                1'b0,                    // Discontinue                                   
                                                4'b0000,                 // is_eop1_ptr
                                                4'b0000,                 // is_eop0_ptr
                                                2'b01,                   // is_eop[1:0]
                                                2'b10,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b01,                   // is_sop[1:0]
                                                2'b00,2'b00,             // Byte Lane number in case of Address Aligned mode - 4 bit
                                                4'b0000,4'b0000,     // Last BE of the Write Data -  8 bit
                                                4'b0000,first_dw_be_     // First BE of the Write Data - 8 bit
                                               };
 
                                                 
            s_axis_rq_tdata          <= #(Tcq) {256'b0,128'b0,          // 4DW unused             //256
                                                1'b0,            // Force ECRC             //128
                                                3'b000,          // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                3'b000,          // Traffic Class
                                                1'b1,            // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS,  // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                RP_BUS_DEV_FNS,  // Requester ID  //96
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b1000,         // Req Type for TYPE0 CFG READ Req
                                                11'b00000000001, // DWORD Count
                                                32'b0,           // Address *unused*       // 64
                                                16'b0,           // Address *unused*       // 32
                                                4'b0,            // Address *unused*
                                                reg_addr_[11:2], // Extended + Base Register Number
                                                2'b00};          // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b000,          // Fmt for Type 0 Configuration Read Req 
                                                5'b00100,        // Type for Type 0 Configuration Read Req
                                                1'b0,            // *reserved*
                                                3'b000,          // Traffic Class
                                                1'b0,            // *reserved*
                                                1'b0,            // Attributes {ID Based Ordering}
                                                1'b0,            // *reserved*
                                                1'b0,            // TLP Processing Hints
                                                1'b0,            // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,           // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,           // Address Translation
                                                10'b0000000001,  // DWORD Count            //32
                                                RP_BUS_DEV_FNS,  // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                4'b0000,         // Last DW Byte Enable
                                                first_dw_be_,    // First DW Byte Enable   //64
                                                EP_BUS_DEV_FNS,  // Completer ID
                                                4'b0000,         // *reserved*
                                                reg_addr_[11:2], // Extended + Base Register Number
                                                2'b00,           // *reserved*             //96
                                                32'b0 ,          // *unused*               //128
                                                128'b0           // *unused*               //256
                                               };

            pcie_tlp_rem             <= #(Tcq)  3'b101;
            set_malformed            <= #(Tcq)  1'b0;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 137'b0;
            s_axis_rq_tdata          <= #(Tcq) 512'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_TYPE0_CONFIGURATION_READ

    /************************************************************
    Task : TSK_TX_TYPE1_CONFIGURATION_READ
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 1 Configuration Read TLP
    *************************************************************/

    task TSK_TX_TYPE1_CONFIGURATION_READ;
        input    [7:0]    tag_;         // Tag
        input    [11:0]   reg_addr_;    // Register Number
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //--------- CFG TYPE-0 Read Transaction :                     -----------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 8'h0F;            // 2DW Descriptor
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                64'b0,                   // Parity Bit slot - 64bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                16'h0000,                // TPH Steering Tag - 16 bit
                                                2'b00,                   // TPH indirect Tag Enable - 2bit
                                                4'b0000,                 // TPH Type - 4 bit
                                                2'b00,                   // TPH Present - 2 bit
                                                1'b0,                    // Discontinue                                   
                                                4'b0000,                 // is_eop1_ptr
                                                4'b0000,                 // is_eop0_ptr
                                                2'b01,                   // is_eop[1:0]
                                                2'b10,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b01,                   // is_sop[1:0]
                                                2'b00,2'b00,             // Byte Lane number in case of Address Aligned mode - 4 bit
                                                4'b0000,4'b0000,     // Last BE of the Write Data -  8 bit
                                                4'b0000,first_dw_be_     // First BE of the Write Data - 8 bit
                                               };
 
                                                
            s_axis_rq_tdata          <= #(Tcq) {256'b0,128'b0,          // 4DW unused             //256
                                                1'b0,            // Force ECRC             //128
                                                3'b000,          // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                3'b000,          // Traffic Class
                                                1'b1,            // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS,  // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                RP_BUS_DEV_FNS,  // Requester ID           //96
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b1001,         // Req Type for TYPE1 CFG READ Req
                                                11'b00000000001, // DWORD Count
                                                32'b0,           // Address *unused*       //64
                                                16'b0,           // Address *unused*       //32
                                                4'b0,            // Address *unused*
                                                reg_addr_[11:2], // Extended + Base Register Number
                                                2'b00};          // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b000,          // Fmt for Type 1 Configuration Read Req
                                                5'b00101,        // Type for Type 1 Configuration Read Req
                                                1'b0,            // *reserved*
                                                3'b000,          // Traffic Class
                                                1'b0,            // *reserved*
                                                1'b0,            // Attributes {ID Based Ordering}
                                                1'b0,            // *reserved*
                                                1'b0,            // TLP Processing Hints
                                                1'b0,            // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,           // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,           // Address Translation
                                                10'b0000000001,  // DWORD Count            //32
                                                RP_BUS_DEV_FNS,  // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                4'b0000,         // Last DW Byte Enable
                                                first_dw_be_,    // First DW Byte Enable   //64
                                                EP_BUS_DEV_FNS,  // Completer ID
                                                4'b0000,         // *reserved*
                                                reg_addr_[11:2], // Extended + Base Register Number
                                                2'b00,           // *reserved*             //96
                                                32'b0,           // *unused*               //128
                                                128'b0           // *unused*               //256
                                               };
                                               
            pcie_tlp_rem             <= #(Tcq)  3'b101;
            set_malformed            <= #(Tcq)  1'b0;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 137'b0;
            s_axis_rq_tdata          <= #(Tcq) 512'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_TYPE1_CONFIGURATION_READ

    /************************************************************
    Task : TSK_TX_TYPE0_CONFIGURATION_WRITE
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 0 Configuration Write TLP
    *************************************************************/

    task TSK_TX_TYPE0_CONFIGURATION_WRITE;
        input    [7:0]    tag_;         // Tag
        input    [11:0]   reg_addr_;    // Register Number
        input    [31:0]   reg_data_;    // Data
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //--------- TYPE-0 CFG Write Transaction :                     -----------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) (AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") ?  1'b0 : 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) (AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") ?  8'hFF : 8'h1F;       // 2DW Descriptor
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                64'b0,                   // Parity Bit slot - 64bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                16'h0000,                // TPH Steering Tag - 16 bit
                                                2'b00,                   // TPH indirect Tag Enable - 2bit
                                                4'b0000,                 // TPH Type - 4 bit
                                                2'b00,                   // TPH Present - 2 bit
                                                1'b0,                    // Discontinue                                   
                                                4'b0000,                 // is_eop1_ptr
                                                4'b0000,                 // is_eop0_ptr
                                                2'b01,                   // is_eop[1:0]
                                                2'b10,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b01,                   // is_sop[1:0]
                                                2'b00,2'b00,             // Byte Lane number in case of Address Aligned mode - 4 bit
                                                4'b0000,4'b0000,     // Last BE of the Write Data -  8 bit
                                                4'b0000,first_dw_be_     // First BE of the Write Data - 8 bit
                                               };
 
                                                
            s_axis_rq_tdata          <= #(Tcq) {256'b0,96'b0,           // 3 DW unused            //256
                                                ((AXISTEN_IF_RQ_ALIGNMENT_MODE=="FALSE")? {reg_data_[31:24], reg_data_[23:16], reg_data_[15:8], reg_data_[7:0]} : 32'h0), // Data
                                                1'b0,            // Force ECRC             //128
                                                3'b000,          // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                3'b000,          // Traffic Class
                                                1'b1,            // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS,  // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                RP_BUS_DEV_FNS,  // Requester ID           //96
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b1010,         // Req Type for TYPE0 CFG Write Req
                                                11'b00000000001, // DWORD Count
                                                32'b0,           // Address *unused*       //64
                                                16'b0,           // Address *unused*       //32
                                                4'b0,            // Address *unused*
                                                reg_addr_[11:2], // Extended + Base Register Number
                                                2'b00};          // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b010,           // Fmt for Type 0 Configuration Write Req
                                                5'b00100,         // Type for Type 0 Configuration Write Req
                                                1'b0,             // *reserved*
                                                3'b000,           // Traffic Class
                                                1'b0,             // *reserved*
                                                1'b0,             // Attributes {ID Based Ordering}
                                                1'b0,             // *reserved*
                                                1'b0,             // TLP Processing Hints
                                                1'b0,             // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,            // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,            // Address Translation
                                                10'b0000000001,   // DWORD Count           //32
                                                RP_BUS_DEV_FNS,   // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                4'b0000,          // Last DW Byte Enable
                                                first_dw_be_,     // First DW Byte Enable  //64
                                                EP_BUS_DEV_FNS,   // Completer ID
                                                4'b0000,          // *reserved*
                                                reg_addr_[11:2],  // Extended + Base Register Number
                                                2'b00,            // *reserved*            //96
                                                reg_data_[7:0],   // Data
                                                reg_data_[15:8],  // Data
                                                reg_data_[23:16], // Data
                                                reg_data_[31:24], // Data                  //128
                                                128'b0            // *unused*              //256
                                               };
                                               
            pcie_tlp_rem             <= #(Tcq)  3'b100;
            set_malformed            <= #(Tcq)  1'b0;

            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            if(AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
               s_axis_rq_tvalid      <= #(Tcq) 1'b1;
               s_axis_rq_tlast       <= #(Tcq) 1'b1;
               s_axis_rq_tkeep       <= #(Tcq) 8'h01;             // 2DW Descriptor

               s_axis_rq_tdata       <= #(Tcq) {256'b0,128'b0,
                                                32'b0,            // *unused* //128
                                                32'b0,            // *unused* //96
                                                32'b0,            // *unused* //64
                                                reg_data_[31:24],             //32
                                                reg_data_[23:16],
                                                reg_data_[15:8],
                                                reg_data_[7:0]
                                               };

               // Just call TSK_TX_SYNCHRONIZE to wait for tready but don't log anything, because
               // the pcie_tlp_data has complete in the previous clock cycle
               TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            end
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 137'b0;
            s_axis_rq_tdata          <= #(Tcq) 512'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_TYPE0_CONFIGURATION_WRITE

    /************************************************************
    Task : TSK_TX_TYPE1_CONFIGURATION_WRITE
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 1 Configuration Write TLP
    *************************************************************/

    task TSK_TX_TYPE1_CONFIGURATION_WRITE;
        input    [7:0]    tag_;         // Tag
        input    [11:0]   reg_addr_;    // Register Number
        input    [31:0]   reg_data_;    // Data
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //--------- TYPE-0 CFG Write Transaction :                     -----------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) (AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") ?  1'b0 : 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) (AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") ?  8'hFF : 8'h1F;       // 2DW Descriptor
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                64'b0,                   // Parity Bit slot - 64bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                16'h0000,                // TPH Steering Tag - 16 bit
                                                2'b00,                   // TPH indirect Tag Enable - 2bit
                                                4'b0000,                 // TPH Type - 4 bit
                                                2'b00,                   // TPH Present - 2 bit
                                                1'b0,                    // Discontinue                                   
                                                4'b0000,                 // is_eop1_ptr
                                                4'b0000,                 // is_eop0_ptr
                                                2'b01,                   // is_eop[1:0]
                                                2'b10,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b01,                   // is_sop[1:0]
                                                2'b00,2'b00,             // Byte Lane number in case of Address Aligned mode - 4 bit
                                                4'b0000,4'b0000,     // Last BE of the Write Data -  8 bit
                                                4'b0000,first_dw_be_     // First BE of the Write Data - 8 bit
                                               };
 
                                                
            s_axis_rq_tdata          <= #(Tcq) {256'b0,96'b0,            // 3 DW unused            //256
                                                ((AXISTEN_IF_RQ_ALIGNMENT_MODE=="FALSE")? {reg_data_[31:24], reg_data_[23:16], reg_data_[15:8], reg_data_[7:0]} : 32'h0), // Data
                                                1'b0,             // Force ECRC            //128
                                                3'b000,           // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                3'b000,           // Traffic Class
                                                1'b1,             // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS,   // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                RP_BUS_DEV_FNS,   // Requester ID          //96
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b1011,          // Req Type for TYPE0 CFG Write Req
                                                11'b00000000001,  // DWORD Count
                                                32'b0,            // Address *unused*      //64
                                                16'b0,            // Address *unused*      //32
                                                4'b0,             // Address *unused*
                                                reg_addr_[11:2],  // Extended + Base Register Number
                                                2'b00 };          // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b010,           // Fmt for Type 1 Configuration Write Req
                                                5'b00101,         // Type for Type 1 Configuration Write Req
                                                1'b0,             // *reserved*
                                                3'b000,           // Traffic Class
                                                1'b0,             // *reserved*
                                                1'b0,             // Attributes {ID Based Ordering}
                                                1'b0,             // *reserved*
                                                1'b0,             // TLP Processing Hints
                                                1'b0,             // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,            // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,            // Address Translation
                                                10'b0000000001,   // DWORD Count           // 32
                                                RP_BUS_DEV_FNS,   // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                4'b0000,          // Last DW Byte Enable
                                                first_dw_be_,     // First DW Byte Enable  //64
                                                EP_BUS_DEV_FNS,   // Completer ID
                                                4'b0000,          // *reserved*
                                                reg_addr_[11:2],  // Extended + Base Register Number
                                                2'b00,            // *reserved*            //96
                                                reg_data_[7:0],   // Data
                                                reg_data_[15:8],  // Data
                                                reg_data_[23:16], // Data
                                                reg_data_[31:24], // Data                  //128
                                                128'b0            // *unused*              //256
                                               };
                                               
            pcie_tlp_rem             <= #(Tcq)  3'b100;
            set_malformed            <= #(Tcq)  1'b0;

            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            if(AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
               s_axis_rq_tvalid      <= #(Tcq) 1'b1;
               s_axis_rq_tlast       <= #(Tcq) 1'b1;
               s_axis_rq_tkeep       <= #(Tcq) 8'h01;             // 2DW Descriptor

               s_axis_rq_tdata       <= #(Tcq) {256'b0,128'b0,
                                                32'b0,            // *unused* //128
                                                32'b0,            // *unused* //96
                                                32'b0,            // *unused* //64
                                                reg_data_[31:24],             //32
                                                reg_data_[23:16],
                                                reg_data_[15:8],
                                                reg_data_[7:0]
                                               };

               // Just call TSK_TX_SYNCHRONIZE to wait for tready but don't log anything, because
               // the pcie_tlp_data has complete in the previous clock cycle
               TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            end
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 137'b0;
            s_axis_rq_tdata          <= #(Tcq) 512'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_TYPE1_CONFIGURATION_WRITE

    /************************************************************
    Task : TSK_TX_MEMORY_READ_32
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Read 32 TLP
    *************************************************************/

    task TSK_TX_MEMORY_READ_32;
        input    [7:0]    tag_;         // Tag
        input    [2:0]    tc_;          // Traffic Class
        input    [10:0]   len_;         // Length (in DW)
        input    [31:0]   addr_;        // Address
        input    [3:0]    last_dw_be_;  // Last DW Byte Enable
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            $display("[%t] : Mem32 Read Req @address %x", $realtime,addr_);
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 8'h0F;             // 2DW Descriptor for Memory Transactions alone
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                64'b0,                   // Parity Bit slot - 64bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                16'h0000,                // TPH Steering Tag - 16 bit
                                                2'b00,                   // TPH indirect Tag Enable - 2bit
                                                4'b0000,                 // TPH Type - 4 bit
                                                2'b00,                   // TPH Present - 2 bit
                                                1'b0,                    // Discontinue                                   
                                                4'b0000,                 // is_eop1_ptr
                                                4'b0000,                 // is_eop0_ptr
                                                2'b01,                   // is_eop[1:0]
                                                2'b10,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b01,                   // is_sop[1:0]
                                                2'b00,2'b00,             // Byte Lane number in case of Address Aligned mode - 4 bit
                                                4'b0000,last_dw_be_,     // Last BE of the Write Data -  8 bit
                                                4'b0000,first_dw_be_     // First BE of the Write Data - 8 bit
                                               };
         
            s_axis_rq_tdata          <= #(Tcq) {256'b0,128'b0,           // 4 DW unused                                    //256
                                                1'b0,             // Force ECRC                                     //128
                                                3'b000,           // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                tc_,              // Traffic Class
                                                1'b1,             // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS,   // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                RP_BUS_DEV_FNS,   // Requester ID -- Used only when RID enable = 1  //96
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b0000,          // Req Type for MRd Req
                                                len_ ,            // DWORD Count
                                                32'b0,            // 32-bit Addressing. So, bits[63:32] = 0         //64
                                                addr_[31:2],      // Memory read address 32-bits                    //32
                                                2'b00};           // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b000,           // Fmt for 32-bit MRd Req
                                                5'b00000,         // Type for 32-bit Mrd Req
                                                1'b0,             // *reserved*
                                                tc_,              // 3-bit Traffic Class
                                                1'b0,             // *reserved*
                                                1'b0,             // Attributes {ID Based Ordering}
                                                1'b0,             // *reserved*
                                                1'b0,             // TLP Processing Hints
                                                1'b0,             // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,            // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,            // Address Translation
                                                len_[9:0],        // DWORD Count                                    //32
                                                RP_BUS_DEV_FNS,   // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                last_dw_be_,      // Last DW Byte Enable
                                                first_dw_be_,     // First DW Byte Enable                           //64
                                                addr_[31:2],      // Address
                                                2'b00,            // *reserved*                                     //96
                                                32'b0,            // *unused*                                       //128
                                                128'b0            // *unused*                                       //256
                                               };

            pcie_tlp_rem             <= #(Tcq)  3'b100;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 137'b0;
            s_axis_rq_tdata          <= #(Tcq) 512'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MEMORY_READ_32

    /************************************************************
    Task : TSK_TX_MEMORY_READ_64
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Read 64 TLP
    *************************************************************/

    task TSK_TX_MEMORY_READ_64;
        input    [7:0]    tag_;         // Tag
        input    [2:0]    tc_;          // Traffic Class
        input    [10:0]   len_;         // Length (in DW)
        input    [63:0]   addr_;        // Address
        input    [3:0]    last_dw_be_;  // Last DW Byte Enable
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            $display("[%t] : Mem64 Read Req @address %x", $realtime,addr_[31:0]);
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 8'h0F;             // 2DW Descriptor for Memory Transactions alone
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                64'b0,                   // Parity Bit slot - 64bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                16'h0000,                // TPH Steering Tag - 16 bit
                                                2'b00,                   // TPH indirect Tag Enable - 2bit
                                                4'b0000,                 // TPH Type - 4 bit
                                                2'b00,                   // TPH Present - 2 bit
                                                1'b0,                    // Discontinue                                   
                                                4'b0000,                 // is_eop1_ptr
                                                4'b0000,                 // is_eop0_ptr
                                                2'b01,                   //is_eop[1:0]
                                                2'b10,                   //is_sop1_ptr[1:0]
                                                2'b00,                   //is_sop0_ptr[1:0]
                                                2'b01,                   //is_sop[1:0]
                                                2'b00,2'b00,             // Byte Lane number in case of Address Aligned mode - 4 bit
                                                4'b0000,last_dw_be_,     // Last BE of the Write Data -  8 bit
                                                4'b0000,first_dw_be_     // First BE of the Write Data - 8 bit
                                               };
                                                  
            s_axis_rq_tdata          <= #(Tcq) {256'b0,128'b0,           // 4 DW unused                                    //256
                                                1'b0,             // Force ECRC                                     //128
                                                3'b000,           // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                tc_,              // Traffic Class
                                                1'b1,             // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS,   // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                RP_BUS_DEV_FNS,   // Requester ID -- Used only when RID enable = 1  //96
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b0000,          // Req Type for MRd Req
                                                len_ ,            // DWORD Count
                                                addr_[63:2],      // Memory read address 64-bits                    //64
                                                2'b00};           // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b001,           // Fmt for 64-bit MRd Req
                                                5'b00000,         // Type for 64-bit Mrd Req
                                                1'b0,             // *reserved*
                                                tc_,              // 3-bit Traffic Class
                                                1'b0,             // *reserved*
                                                1'b0,             // Attributes {ID Based Ordering}
                                                1'b0,             // *reserved*
                                                1'b0,             // TLP Processing Hints
                                                1'b0,             // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,            // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,            // Address Translation
                                                len_[9:0],        // DWORD Count                                    //32
                                                RP_BUS_DEV_FNS,   // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                last_dw_be_,      // Last DW Byte Enable
                                                first_dw_be_,     // First DW Byte Enable                           //64
                                                addr_[63:2],      // Address
                                                2'b00,            // *reserved*                                     //128
                                                128'b0            // *unused*                                       //256
                                               };
                                                
            pcie_tlp_rem             <= #(Tcq)  3'b100;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 137'b0;
            s_axis_rq_tdata          <= #(Tcq) 512'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MEMORY_READ_64

    /************************************************************
    Task : TSK_TX_MEMORY_WRITE_32
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Write 32 TLP
    *************************************************************/

    task TSK_TX_MEMORY_WRITE_32;
        input  [7:0]    tag_;         // Tag
        input  [2:0]    tc_;          // Traffic Class
        input  [10:0]   len_;         // Length (in DW)
        input  [31:0]   addr_;        // Address
        input  [3:0]    last_dw_be_;  // Last DW Byte Enable
        input  [3:0]    first_dw_be_; // First DW Byte Enable
        input           ep_;          // Poisoned Data: Payload is invalid if set
        reg    [10:0]   _len;         // Length Info on pcie_tlp_data -- Used to count how many times to loop
        reg    [10:0]   len_i;        // Length Info on s_axis_rq_tdata -- Used to count how many times to loop
        reg    [2:0]    aa_dw;        // Adjusted DW Count for Address Aligned Mode
        reg    [255:0]  aa_data;      // Adjusted Data for Address Aligned Mode
        reg    [127:0]  data_axis_i;  // Data Info for s_axis_rq_tdata
        reg    [159:0]  data_pcie_i;  // Data Info for pcie_tlp_data
        integer         _j;           // Byte Index
        integer         start_addr;   // Start Location for Payload DW0

        begin
            //-----------------------------------------------------------------------\\            
            if(AXISTEN_IF_RQ_ALIGNMENT_MODE=="TRUE")begin
                start_addr  = 0;
                aa_dw       = addr_[4:2];
            end else begin
                start_addr  = 48;
                aa_dw       = 3'b000;
            end
            
            len_i           = len_ + aa_dw;
            _len            = len_;
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            $display("[%t] : Mem32 Write Req @address %x", $realtime,addr_);
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            // Start of First Data Beat
            data_axis_i        =  {
                                   DATA_STORE[15],
                                   DATA_STORE[14],
                                   DATA_STORE[13],
                                   DATA_STORE[12],
                                   DATA_STORE[11],
                                   DATA_STORE[10],
                                   DATA_STORE[9],
                                   DATA_STORE[8],
                                   DATA_STORE[7],
                                   DATA_STORE[6],
                                   DATA_STORE[5],
                                   DATA_STORE[4],
                                   DATA_STORE[3],
                                   DATA_STORE[2],
                                   DATA_STORE[1],
                                   DATA_STORE[0]
                                  };
            s_axis_rq_tuser_wo_parity <= #(Tcq) {
                                         //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                         64'b0,                   // Parity Bit slot - 64bit
                                         6'b101010,               // Seq Number - 6bit
                                         6'b101010,               // Seq Number - 6bit
                                         16'h0000,                // TPH Steering Tag - 16 bit
                                         2'b00,                   // TPH indirect Tag Enable - 2bit
                                         4'b0000,                 // TPH Type - 4 bit
                                         2'b00,                   // TPH Present - 2 bit
                                         1'b0,                    // Discontinue                                   
                                         4'b0000,                 // is_eop1_ptr
                                         4'b1111,                 // is_eop0_ptr
                                         2'b01,                   // is_eop[1:0]
                                         2'b00,                   // is_sop1_ptr[1:0]
                                         2'b00,                   // is_sop0_ptr[1:0]
                                         2'b01,                   // is_sop[1:0]
                                         2'b0,aa_dw[1:0],         // Byte Lane number in case of Address Aligned mode - 4 bit
                                         4'b0000,last_dw_be_,     // Last BE of the Write Data 8 bit
                                         4'b0000,first_dw_be_     // First BE of the Write Data 8 bit
                                        };

            s_axis_rq_tdata   <= #(Tcq) { 256'b0, //256
                                         ((AXISTEN_IF_RQ_ALIGNMENT_MODE == "FALSE" ) ?  data_axis_i : 128'h0), // 128-bit write data
                                          //128
                                         1'b0,          // Force ECRC
                                         3'b000,        // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                         tc_,           // Traffic Class
                                         1'b1,          // RID Enable to use the Client supplied Bus/Device/Func No
                                         EP_BUS_DEV_FNS,   // Completer ID
                                         (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                          //96
                                         RP_BUS_DEV_FNS,   // Requester ID -- Used only when RID enable = 1
                                         ep_,           // Poisoned Req
                                         4'b0001,       // Req Type for MWr Req
                                         (set_malformed ? (len_ + 11'h4) : len_), // DWORD Count - length does not include padded zeros
                                          //64
                                         32'b0,         // High Address *unused*
                                         addr_[31:2],   // Memory Write address 32-bits
                                         2'b00          // AT -> 00 : Untranslated Address
                                        };
            //-----------------------------------------------------------------------\\
            data_pcie_i        =  {
                                   DATA_STORE[0],
                                   DATA_STORE[1],
                                   DATA_STORE[2],
                                   DATA_STORE[3],
                                   DATA_STORE[4],
                                   DATA_STORE[5],
                                   DATA_STORE[6],
                                   DATA_STORE[7],
                                   DATA_STORE[8],
                                   DATA_STORE[9],
                                   DATA_STORE[10],
                                   DATA_STORE[11],
                                   DATA_STORE[12],
                                   DATA_STORE[13],
                                   DATA_STORE[14],
                                   DATA_STORE[15],
                                   DATA_STORE[16],
                                   DATA_STORE[17],
                                   DATA_STORE[18],
                                   DATA_STORE[19]
                                  };

            pcie_tlp_data     <= #(Tcq) {
                                         3'b010,        // Fmt for 32-bit MWr Req
                                         5'b00000,      // Type for 32-bit MWr Req
                                         1'b0,          // *reserved*
                                         tc_,           // 3-bit Traffic Class
                                         1'b0,          // *reserved*
                                         1'b0,          // Attributes {ID Based Ordering}
                                         1'b0,          // *reserved*
                                         1'b0,          // TLP Processing Hints
                                         1'b0,          // TLP Digest Present
                                         ep_,           // Poisoned Req
                                         2'b00,         // Attributes {Relaxed Ordering, No Snoop}
                                         2'b00,         // Address Translation
                                         (set_malformed ? (len_[9:0] + 10'h4) : len_[9:0]),  // DWORD Count
                                          //32
                                         RP_BUS_DEV_FNS,   // Requester ID
                                         (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                         last_dw_be_,   // Last DW Byte Enable
                                         first_dw_be_,  // First DW Byte Enable
                                          //64
                                         addr_[31:2],   // Memory Write address 32-bits
                                         2'b00,         // *reserved* or Processing Hint
                                          //96
                                         data_pcie_i    // Payload Data
                                          //256
                                        };
                                          
            pcie_tlp_rem      <= #(Tcq) (_len > 4) ? 3'b000 : (5-_len);
            set_malformed     <= #(Tcq) 1'b0;
            _len               = (_len > 4) ? (_len - 11'h5) : 11'b0;
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid  <= #(Tcq) 1'b1;

            if (len_i > 4 || AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
                s_axis_rq_tlast          <= #(Tcq) 1'b0;
                s_axis_rq_tkeep          <= #(Tcq) 8'hFF;

                len_i                     = (AXISTEN_IF_RQ_ALIGNMENT_MODE == "FALSE") ? (len_i - 4) : len_i; // Don't subtract 4 in Address Aligned because
                                                                                                             // it's always padded with zeros on first beat

                // pcie_tlp_data doesn't append zero even in Address Aligned mode, so it should mark this cycle as the last beat if it has no more payload to log.
                // The AXIS RQ interface will need to execute the next cycle, but we're just not going to log that data beat in pcie_tlp_data
                if (_len == 0)
                    TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
                else
                    TSK_TX_SYNCHRONIZE(1, 1, 0, `SYNC_RQ_RDY);

            end else begin
                if (len_i == 1)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h1F;
                else if (len_i == 2)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h3F;
                else if (len_i == 3)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h7F;
                else // len_i == 4
                    s_axis_rq_tkeep      <= #(Tcq) 8'hFF;

                s_axis_rq_tlast          <= #(Tcq) 1'b1;

                len_i                     = 0;
                TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            end
            // End of First Data Beat
            //-----------------------------------------------------------------------\\
            // Start of Second and Subsequent Data Beat
            if (len_i != 0 || AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
                fork

                begin // Sequential group 1 - AXIS RQ
                    for (_j = start_addr; len_i != 0; _j = _j + 32) begin
                        if(_j==start_addr) begin 
                            aa_data = {
                                       DATA_STORE[_j + 31],
                                       DATA_STORE[_j + 30],
                                       DATA_STORE[_j + 29],
                                       DATA_STORE[_j + 28],
                                       DATA_STORE[_j + 27],
                                       DATA_STORE[_j + 26],
                                       DATA_STORE[_j + 25],
                                       DATA_STORE[_j + 24],
                                       DATA_STORE[_j + 23],
                                       DATA_STORE[_j + 22],
                                       DATA_STORE[_j + 21],
                                       DATA_STORE[_j + 20],
                                       DATA_STORE[_j + 19],
                                       DATA_STORE[_j + 18],
                                       DATA_STORE[_j + 17],
                                       DATA_STORE[_j + 16],
                                       DATA_STORE[_j + 15],
                                       DATA_STORE[_j + 14],
                                       DATA_STORE[_j + 13],
                                       DATA_STORE[_j + 12],
                                       DATA_STORE[_j + 11],
                                       DATA_STORE[_j + 10],
                                       DATA_STORE[_j +  9],
                                       DATA_STORE[_j +  8],
                                       DATA_STORE[_j +  7],
                                       DATA_STORE[_j +  6],
                                       DATA_STORE[_j +  5],
                                       DATA_STORE[_j +  4],
                                       DATA_STORE[_j +  3],
                                       DATA_STORE[_j +  2],
                                       DATA_STORE[_j +  1],
                                       DATA_STORE[_j +  0]
                                      } << (aa_dw*4*8);
                        end else begin 
                            aa_data = {
                                       DATA_STORE[_j + 31 - (aa_dw*4)],
                                       DATA_STORE[_j + 30 - (aa_dw*4)],
                                       DATA_STORE[_j + 29 - (aa_dw*4)],
                                       DATA_STORE[_j + 28 - (aa_dw*4)],
                                       DATA_STORE[_j + 27 - (aa_dw*4)],
                                       DATA_STORE[_j + 26 - (aa_dw*4)],
                                       DATA_STORE[_j + 25 - (aa_dw*4)],
                                       DATA_STORE[_j + 24 - (aa_dw*4)],
                                       DATA_STORE[_j + 23 - (aa_dw*4)],
                                       DATA_STORE[_j + 22 - (aa_dw*4)],
                                       DATA_STORE[_j + 21 - (aa_dw*4)],
                                       DATA_STORE[_j + 20 - (aa_dw*4)],
                                       DATA_STORE[_j + 19 - (aa_dw*4)],
                                       DATA_STORE[_j + 18 - (aa_dw*4)],
                                       DATA_STORE[_j + 17 - (aa_dw*4)],
                                       DATA_STORE[_j + 16 - (aa_dw*4)],
                                       DATA_STORE[_j + 15 - (aa_dw*4)],
                                       DATA_STORE[_j + 14 - (aa_dw*4)],
                                       DATA_STORE[_j + 13 - (aa_dw*4)],
                                       DATA_STORE[_j + 12 - (aa_dw*4)],
                                       DATA_STORE[_j + 11 - (aa_dw*4)],
                                       DATA_STORE[_j + 10 - (aa_dw*4)],
                                       DATA_STORE[_j +  9 - (aa_dw*4)],
                                       DATA_STORE[_j +  8 - (aa_dw*4)],
                                       DATA_STORE[_j +  7 - (aa_dw*4)],
                                       DATA_STORE[_j +  6 - (aa_dw*4)],
                                       DATA_STORE[_j +  5 - (aa_dw*4)],
                                       DATA_STORE[_j +  4 - (aa_dw*4)],
                                       DATA_STORE[_j +  3 - (aa_dw*4)],
                                       DATA_STORE[_j +  2 - (aa_dw*4)],
                                       DATA_STORE[_j +  1 - (aa_dw*4)],
                                       DATA_STORE[_j +  0 - (aa_dw*4)]
                                      };
                        end

                        s_axis_rq_tdata   <= #(Tcq) aa_data;

                        if((len_i/8) == 0) begin
                            case (len_i % 8)
                                1 : begin len_i = len_i - 1; s_axis_rq_tkeep <= #(Tcq) 8'h01; end  // D0---------------------
                                2 : begin len_i = len_i - 2; s_axis_rq_tkeep <= #(Tcq) 8'h03; end  // D0-D1------------------
                                3 : begin len_i = len_i - 3; s_axis_rq_tkeep <= #(Tcq) 8'h07; end  // D0-D1-D2---------------
                                4 : begin len_i = len_i - 4; s_axis_rq_tkeep <= #(Tcq) 8'h0F; end  // D0-D1-D2-D3------------
                                5 : begin len_i = len_i - 5; s_axis_rq_tkeep <= #(Tcq) 8'h1F; end  // D0-D1-D2-D3-D4---------
                                6 : begin len_i = len_i - 6; s_axis_rq_tkeep <= #(Tcq) 8'h3F; end  // D0-D1-D2-D3-D4-D5------
                                7 : begin len_i = len_i - 7; s_axis_rq_tkeep <= #(Tcq) 8'h7F; end  // D0-D1-D2-D3-D4-D5-D6---
                                0 : begin len_i = len_i - 8; s_axis_rq_tkeep <= #(Tcq) 8'hFF; end  // D0-D1-D2-D3-D4-D5-D6-D7
                            endcase 
                        end else begin
                            len_i               = len_i - 8; s_axis_rq_tkeep <= #(Tcq) 8'hFF;      // D0-D1-D2-D3-D4-D5-D6-D7
                        end

                        if (len_i == 0)
                            s_axis_rq_tlast        <= #(Tcq) 1'b1;
                        else
                            s_axis_rq_tlast        <= #(Tcq) 1'b0;

                        // Call this just to check for the tready, but don't log anything. That's the job for pcie_tlp_data
                        // The reason for splitting the TSK_TX_SYNCHRONIZE task and distribute them in both sequential group
                        // is that in address aligned mode, it's possible that the additional padded zeros cause the AXIS RQ
                        // to be one beat longer than the actual PCIe TLP. When it happens do not log the last clock beat
                        // but just send the packet on AXIS RQ interface
                        TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);

                    end // for loop
                end // End sequential group 1 - AXIS RQ

                begin // Sequential group 2 - pcie_tlp
                    for (_j = 20; _len != 0; _j = _j + 32) begin
                        pcie_tlp_data <= #(Tcq)    {
                                                    DATA_STORE[_j + 0],
                                                    DATA_STORE[_j + 1],
                                                    DATA_STORE[_j + 2],
                                                    DATA_STORE[_j + 3],
                                                    DATA_STORE[_j + 4],
                                                    DATA_STORE[_j + 5],
                                                    DATA_STORE[_j + 6],
                                                    DATA_STORE[_j + 7],
                                                    DATA_STORE[_j + 8],
                                                    DATA_STORE[_j + 9],
                                                    DATA_STORE[_j + 10],
                                                    DATA_STORE[_j + 11],
                                                    DATA_STORE[_j + 12],
                                                    DATA_STORE[_j + 13],
                                                    DATA_STORE[_j + 14],
                                                    DATA_STORE[_j + 15],
                                                    DATA_STORE[_j + 16],
                                                    DATA_STORE[_j + 17],
                                                    DATA_STORE[_j + 18],
                                                    DATA_STORE[_j + 19],
                                                    DATA_STORE[_j + 20],
                                                    DATA_STORE[_j + 21],
                                                    DATA_STORE[_j + 22],
                                                    DATA_STORE[_j + 23],
                                                    DATA_STORE[_j + 24],
                                                    DATA_STORE[_j + 25],
                                                    DATA_STORE[_j + 26],
                                                    DATA_STORE[_j + 27],
                                                    DATA_STORE[_j + 28],
                                                    DATA_STORE[_j + 29],
                                                    DATA_STORE[_j + 30],
                                                    DATA_STORE[_j + 31]
                                                   };

                        if ((_len/8) == 0) begin
                            case (_len % 8)
                                1 : begin _len = _len - 1; pcie_tlp_rem  <= #(Tcq) 3'b111; end  // D0---------------------
                                2 : begin _len = _len - 2; pcie_tlp_rem  <= #(Tcq) 3'b110; end  // D0-D1------------------
                                3 : begin _len = _len - 3; pcie_tlp_rem  <= #(Tcq) 3'b101; end  // D0-D1-D2---------------
                                4 : begin _len = _len - 4; pcie_tlp_rem  <= #(Tcq) 3'b100; end  // D0-D1-D2-D3------------
                                5 : begin _len = _len - 5; pcie_tlp_rem  <= #(Tcq) 3'b011; end  // D0-D1-D2-D3-D4---------
                                6 : begin _len = _len - 6; pcie_tlp_rem  <= #(Tcq) 3'b010; end  // D0-D1-D2-D3-D4-D5------
                                7 : begin _len = _len - 7; pcie_tlp_rem  <= #(Tcq) 3'b001; end  // D0-D1-D2-D3-D4-D5-D6---
                                0 : begin _len = _len - 8; pcie_tlp_rem  <= #(Tcq) 3'b000; end  // D0-D1-D2-D3-D4-D5-D6-D7
                            endcase 
                        end else begin
                            _len               = _len - 8; pcie_tlp_rem   <= #(Tcq) 3'b000;     // D0-D1-D2-D3-D4-D5-D6-D7
                        end

                        if (_len == 0)
                            TSK_TX_SYNCHRONIZE(0, 1, 1, `SYNC_RQ_RDY);
                        else
                            TSK_TX_SYNCHRONIZE(0, 1, 0, `SYNC_RQ_RDY);
                    end // for loop
                end // End sequential group 2 - pcie_tlp

                join
            end  // if
            // End of Second and Subsequent Data Beat
            //-----------------------------------------------------------------------\\
            // Packet Complete - Drive 0s
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 137'b0;
            s_axis_rq_tdata          <= #(Tcq) 512'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MEMORY_WRITE_32

    /************************************************************
    Task : TSK_TX_MEMORY_WRITE_64
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Write 64 TLP
    *************************************************************/

    task TSK_TX_MEMORY_WRITE_64;
        input  [7:0]    tag_;         // Tag
        input  [2:0]    tc_;          // Traffic Class
        input  [10:0]   len_;         // Length (in DW)
        input  [63:0]   addr_;        // Address
        input  [3:0]    last_dw_be_;  // Last DW Byte Enable
        input  [3:0]    first_dw_be_; // First DW Byte Enable
        input           ep_;          // Poisoned Data: Payload is invalid if set
        reg    [10:0]   _len;         // Length Info on pcie_tlp_data -- Used to count how many times to loop
        reg    [10:0]   len_i;        // Length Info on s_axis_rq_tdata -- Used to count how many times to loop
        reg    [2:0]    aa_dw;        // Adjusted DW Count for Address Aligned Mode
        reg    [255:0]  aa_data;      // Adjusted Data for Address Aligned Mode
        reg    [127:0]  data_axis_i;  // Data Info for s_axis_rq_tdata
        reg    [127:0]  data_pcie_i;  // Data Info for pcie_tlp_data
        integer         _j;           // Byte Index
        integer         start_addr;   // Start Location for Payload DW0

        begin
            //-----------------------------------------------------------------------\\
            if (AXISTEN_IF_RQ_ALIGNMENT_MODE=="TRUE") begin
                start_addr  = 0;
                aa_dw       = addr_[4:2];
            end else begin
                start_addr  = 48;
                aa_dw       = 3'b000;
            end
            
            len_i           = len_ + aa_dw;
            _len            = len_;
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            $display("[%t] : Mem64 Write Req @address %x", $realtime,addr_[31:0]);
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            // Start of First Data Beat
            data_axis_i        =  {
                                   DATA_STORE[15],
                                   DATA_STORE[14],
                                   DATA_STORE[13],
                                   DATA_STORE[12],
                                   DATA_STORE[11],
                                   DATA_STORE[10],
                                   DATA_STORE[9],
                                   DATA_STORE[8],
                                   DATA_STORE[7],
                                   DATA_STORE[6],
                                   DATA_STORE[5],
                                   DATA_STORE[4],
                                   DATA_STORE[3],
                                   DATA_STORE[2],
                                   DATA_STORE[1],
                                   DATA_STORE[0]
                                  };

            s_axis_rq_tuser_wo_parity <= #(Tcq) {
                                         //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                         64'b0,                   // Parity Bit slot - 64bit
                                         6'b101010,               // Seq Number - 6bit
                                         6'b101010,               // Seq Number - 6bit
                                         16'h0000,                // TPH Steering Tag - 16 bit
                                         2'b00,                   // TPH indirect Tag Enable - 2bit
                                         4'b0000,                 // TPH Type - 4 bit
                                         2'b00,                   // TPH Present - 2 bit
                                         1'b0,                    // Discontinue                                   
                                         4'b0000,                 // is_eop1_ptr
                                         4'b1111,                 // is_eop0_ptr
                                         2'b01,                   // is_eop[1:0]
                                         2'b00,                   // is_sop1_ptr[1:0]
                                         2'b00,                   // is_sop0_ptr[1:0]
                                         2'b01,                   // is_sop[1:0]
                                         2'b0,aa_dw[1:0],         // Byte Lane number in case of Address Aligned mode - 4 bit
                                         4'b0000,last_dw_be_,     // Last BE of the Write Data 8 bit
                                         4'b0000,first_dw_be_     // First BE of the Write Data 8 bit
                                        };

            s_axis_rq_tdata   <= #(Tcq) { 256'b0,//256
                                         ((AXISTEN_IF_RQ_ALIGNMENT_MODE == "FALSE" ) ?  data_axis_i : 128'h0), // 128-bit write data
                                          //128
                                         1'b0,        // Force ECRC
                                         3'b000,      // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                         tc_,         // Traffic Class
                                         1'b1,        // RID Enable to use the Client supplied Bus/Device/Func No
                                         EP_BUS_DEV_FNS,   // Completer ID
                                         (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                          //96
                                         RP_BUS_DEV_FNS,   // Requester ID -- Used only when RID enable = 1
                                         ep_,         // Poisoned Req
                                         4'b0001,     // Req Type for MWr Req
                                         (set_malformed ? (len_ + 11'h4) : len_),  // DWORD Count
                                          //64
                                         addr_[63:2], // Memory Write address 64-bits
                                         2'b00        // AT -> 00 : Untranslated Address
                                        };
            //-----------------------------------------------------------------------\\
            data_pcie_i        =  {
                                   DATA_STORE[0],
                                   DATA_STORE[1],
                                   DATA_STORE[2],
                                   DATA_STORE[3],
                                   DATA_STORE[4],
                                   DATA_STORE[5],
                                   DATA_STORE[6],
                                   DATA_STORE[7],
                                   DATA_STORE[8],
                                   DATA_STORE[9],
                                   DATA_STORE[10],
                                   DATA_STORE[11],
                                   DATA_STORE[12],
                                   DATA_STORE[13],
                                   DATA_STORE[14],
                                   DATA_STORE[15]
                                  };

            pcie_tlp_data     <= #(Tcq) {
                                         3'b011,      // Fmt for 64-bit MWr Req
                                         5'b00000,    // Type for 64-bit MWr Req
                                         1'b0,        // *reserved*
                                         tc_,         // 3-bit Traffic Class
                                         1'b0,        // *reserved*
                                         1'b0,        // Attributes {ID Based Ordering}
                                         1'b0,        // *reserved*
                                         1'b0,        // TLP Processing Hints
                                         1'b0,        // TLP Digest Present
                                         ep_,         // Poisoned Req
                                         2'b00,       // Attributes {Relaxed Ordering, No Snoop}
                                         2'b00,       // Address Translation
                                         (set_malformed ? (len_[9:0] + 10'h4) : len_[9:0]),  // DWORD Count
                                         RP_BUS_DEV_FNS,   // Requester ID
                                         (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                         last_dw_be_,   // Last DW Byte Enable
                                         first_dw_be_,  // First DW Byte Enable
                                          //64
                                         addr_[63:2],   // Memory Write address 64-bits
                                         2'b00,         // *reserved*
                                          //128
                                         data_pcie_i    // Payload Data
                                          //256
                                        };
                                         
            pcie_tlp_rem      <= #(Tcq) (_len > 3) ? 3'b000 : (4-_len);
            set_malformed     <= #(Tcq) 1'b0;
            _len               = (_len > 3) ? (_len - 11'h4) : 11'h0;
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid  <= #(Tcq) 1'b1;

            if (len_i > 4 || AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
                s_axis_rq_tlast          <= #(Tcq) 1'b0;
                s_axis_rq_tkeep          <= #(Tcq) 8'hFF;

                len_i                     = (AXISTEN_IF_RQ_ALIGNMENT_MODE == "FALSE") ? (len_i - 4) : len_i; // Don't subtract 4 in Address Aligned because
                                                                                                             // it's always padded with zeros on first beat

                // pcie_tlp_data doesn't append zero even in Address Aligned mode, so it should mark this cycle as the last beat if it has no more payload to log.
                // The AXIS RQ interface will need to execute the next cycle, but we're just not going to log that data beat in pcie_tlp_data
                if (_len == 0)
                    TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
                else
                    TSK_TX_SYNCHRONIZE(1, 1, 0, `SYNC_RQ_RDY);

            end else begin
                if (len_i == 1)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h1F;
                else if (len_i == 2)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h3F;
                else if (len_i == 3)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h7F;
                else // len_i == 4
                    s_axis_rq_tkeep      <= #(Tcq) 8'hFF;
                
                s_axis_rq_tlast          <= #(Tcq) 1'b1;
                
                len_i                     = 0;

                TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            end
            // End of First Data Beat
            //-----------------------------------------------------------------------\\
            // Start of Second and Subsequent Data Beat
            if (len_i != 0 || AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
                fork 
                
                begin // Sequential group 1 - AXIS RQ
                    for (_j = start_addr; len_i != 0; _j = _j + 32) begin
                        if(_j == start_addr) begin 
                            aa_data = {
                                       DATA_STORE[_j + 31],
                                       DATA_STORE[_j + 30],
                                       DATA_STORE[_j + 29],
                                       DATA_STORE[_j + 28],
                                       DATA_STORE[_j + 27],
                                       DATA_STORE[_j + 26],
                                       DATA_STORE[_j + 25],
                                       DATA_STORE[_j + 24],
                                       DATA_STORE[_j + 23],
                                       DATA_STORE[_j + 22],
                                       DATA_STORE[_j + 21],
                                       DATA_STORE[_j + 20],
                                       DATA_STORE[_j + 19],
                                       DATA_STORE[_j + 18],
                                       DATA_STORE[_j + 17],
                                       DATA_STORE[_j + 16],
                                       DATA_STORE[_j + 15],
                                       DATA_STORE[_j + 14],
                                       DATA_STORE[_j + 13],
                                       DATA_STORE[_j + 12],
                                       DATA_STORE[_j + 11],
                                       DATA_STORE[_j + 10],
                                       DATA_STORE[_j +  9],
                                       DATA_STORE[_j +  8],
                                       DATA_STORE[_j +  7],
                                       DATA_STORE[_j +  6],
                                       DATA_STORE[_j +  5],
                                       DATA_STORE[_j +  4],
                                       DATA_STORE[_j +  3],
                                       DATA_STORE[_j +  2],
                                       DATA_STORE[_j +  1],
                                       DATA_STORE[_j +  0]
                                       } << (aa_dw*4*8);
                        end else begin 
                            aa_data = {
                                       DATA_STORE[_j + 31 - (aa_dw*4)],
                                       DATA_STORE[_j + 30 - (aa_dw*4)],
                                       DATA_STORE[_j + 29 - (aa_dw*4)],
                                       DATA_STORE[_j + 28 - (aa_dw*4)],
                                       DATA_STORE[_j + 27 - (aa_dw*4)],
                                       DATA_STORE[_j + 26 - (aa_dw*4)],
                                       DATA_STORE[_j + 25 - (aa_dw*4)],
                                       DATA_STORE[_j + 24 - (aa_dw*4)],
                                       DATA_STORE[_j + 23 - (aa_dw*4)],
                                       DATA_STORE[_j + 22 - (aa_dw*4)],
                                       DATA_STORE[_j + 21 - (aa_dw*4)],
                                       DATA_STORE[_j + 20 - (aa_dw*4)],
                                       DATA_STORE[_j + 19 - (aa_dw*4)],
                                       DATA_STORE[_j + 18 - (aa_dw*4)],
                                       DATA_STORE[_j + 17 - (aa_dw*4)],
                                       DATA_STORE[_j + 16 - (aa_dw*4)],
                                       DATA_STORE[_j + 15 - (aa_dw*4)],
                                       DATA_STORE[_j + 14 - (aa_dw*4)],
                                       DATA_STORE[_j + 13 - (aa_dw*4)],
                                       DATA_STORE[_j + 12 - (aa_dw*4)],
                                       DATA_STORE[_j + 11 - (aa_dw*4)],
                                       DATA_STORE[_j + 10 - (aa_dw*4)],
                                       DATA_STORE[_j +  9 - (aa_dw*4)],
                                       DATA_STORE[_j +  8 - (aa_dw*4)],
                                       DATA_STORE[_j +  7 - (aa_dw*4)],
                                       DATA_STORE[_j +  6 - (aa_dw*4)],
                                       DATA_STORE[_j +  5 - (aa_dw*4)],
                                       DATA_STORE[_j +  4 - (aa_dw*4)],
                                       DATA_STORE[_j +  3 - (aa_dw*4)],
                                       DATA_STORE[_j +  2 - (aa_dw*4)],
                                       DATA_STORE[_j +  1 - (aa_dw*4)],
                                       DATA_STORE[_j +  0 - (aa_dw*4)]
                                       };
                        end

                        s_axis_rq_tdata           <= #(Tcq) aa_data;
                        
                        if((len_i)/8 == 0) begin
                            case ((len_i) % 8)
                                1 : begin len_i = len_i - 1; s_axis_rq_tkeep <= #(Tcq) 8'h01; end  // D0---------------------
                                2 : begin len_i = len_i - 2; s_axis_rq_tkeep <= #(Tcq) 8'h03; end  // D0-D1------------------
                                3 : begin len_i = len_i - 3; s_axis_rq_tkeep <= #(Tcq) 8'h07; end  // D0-D1-D2---------------
                                4 : begin len_i = len_i - 4; s_axis_rq_tkeep <= #(Tcq) 8'h0F; end  // D0-D1-D2-D3------------
                                5 : begin len_i = len_i - 5; s_axis_rq_tkeep <= #(Tcq) 8'h1F; end  // D0-D1-D2-D3-D4---------
                                6 : begin len_i = len_i - 6; s_axis_rq_tkeep <= #(Tcq) 8'h3F; end  // D0-D1-D2-D3-D4-D5------
                                7 : begin len_i = len_i - 7; s_axis_rq_tkeep <= #(Tcq) 8'h7F; end  // D0-D1-D2-D3-D4-D5-D6---
                                0 : begin len_i = len_i - 8; s_axis_rq_tkeep <= #(Tcq) 8'hFF; end  // D0-D1-D2-D3-D4-D5-D6-D7
                            endcase 
                        end else begin
                            len_i               = len_i - 8; s_axis_rq_tkeep <= #(Tcq) 8'hFF;      // D0-D1-D2-D3-D4-D5-D6-D7
                        end
                        
                        if (len_i == 0)
                            s_axis_rq_tlast        <= #(Tcq) 1'b1;
                        else
                            s_axis_rq_tlast        <= #(Tcq) 1'b0;

                        // Call this just to check for the tready, but don't log anything. That's the job for pcie_tlp_data
                        // The reason for splitting the TSK_TX_SYNCHRONIZE task and distribute them in both sequential group
                        // is that in address aligned mode, it's possible that the additional padded zeros cause the AXIS RQ
                        // to be one beat longer than the actual PCIe TLP. When it happens do not log the last clock beat
                        // but just send the packet on AXIS RQ interface
                        TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
                            
                    end // for loop
                end // End sequential group 1 - AXIS RQ
                
                begin // Sequential group 2 - pcie_tlp
                    for (_j = 16; _len != 0; _j = _j + 32) begin
                        pcie_tlp_data <= #(Tcq) {
                                                DATA_STORE[_j + 0],
                                                DATA_STORE[_j + 1],
                                                DATA_STORE[_j + 2],
                                                DATA_STORE[_j + 3],
                                                DATA_STORE[_j + 4],
                                                DATA_STORE[_j + 5],
                                                DATA_STORE[_j + 6],
                                                DATA_STORE[_j + 7],
                                                DATA_STORE[_j + 8],
                                                DATA_STORE[_j + 9],
                                                DATA_STORE[_j + 10],
                                                DATA_STORE[_j + 11],
                                                DATA_STORE[_j + 12],
                                                DATA_STORE[_j + 13],
                                                DATA_STORE[_j + 14],
                                                DATA_STORE[_j + 15],
                                                DATA_STORE[_j + 16],
                                                DATA_STORE[_j + 17],
                                                DATA_STORE[_j + 18],
                                                DATA_STORE[_j + 19],
                                                DATA_STORE[_j + 20],
                                                DATA_STORE[_j + 21],
                                                DATA_STORE[_j + 22],
                                                DATA_STORE[_j + 23],
                                                DATA_STORE[_j + 24],
                                                DATA_STORE[_j + 25],
                                                DATA_STORE[_j + 26],
                                                DATA_STORE[_j + 27],
                                                DATA_STORE[_j + 28],
                                                DATA_STORE[_j + 29],
                                                DATA_STORE[_j + 30],
                                                DATA_STORE[_j + 31]
                                                };
                        
                        if ((_len)/8 == 0) begin
                            case ((_len) % 8)
                                1 : begin _len = _len - 1; pcie_tlp_rem <= #(Tcq) 3'b111; end  // D0---------------------
                                2 : begin _len = _len - 2; pcie_tlp_rem <= #(Tcq) 3'b110; end  // D0-D1------------------
                                3 : begin _len = _len - 3; pcie_tlp_rem <= #(Tcq) 3'b101; end  // D0-D1-D2---------------
                                4 : begin _len = _len - 4; pcie_tlp_rem <= #(Tcq) 3'b100; end  // D0-D1-D2-D3------------
                                5 : begin _len = _len - 5; pcie_tlp_rem <= #(Tcq) 3'b011; end  // D0-D1-D2-D3-D4---------
                                6 : begin _len = _len - 6; pcie_tlp_rem <= #(Tcq) 3'b010; end  // D0-D1-D2-D3-D4-D5------
                                7 : begin _len = _len - 7; pcie_tlp_rem <= #(Tcq) 3'b001; end  // D0-D1-D2-D3-D4-D5-D6---
                                0 : begin _len = _len - 8; pcie_tlp_rem <= #(Tcq) 3'b000; end  // D0-D1-D2-D3-D4-D5-D6-D7
                            endcase
                        end else begin
                            _len               = _len - 8; pcie_tlp_rem <= #(Tcq) 3'b000; // D0-D1-D2-D3-D4-D5-D6-D7
                        end
                        
                        if (_len == 0)
                            TSK_TX_SYNCHRONIZE(0, 1, 1, `SYNC_RQ_RDY);
                        else
                            TSK_TX_SYNCHRONIZE(0, 1, 0, `SYNC_RQ_RDY);
                    end // for loop
                end // End sequential group 2 - pcie_tlp
                             
                join
            end // if
            // End of Second and Subsequent Data Beat
            //-----------------------------------------------------------------------\\
            // Packet Complete - Drive 0s
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 137'b0;
            s_axis_rq_tdata          <= #(Tcq) 512'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MEMORY_WRITE_64

    /************************************************************
    Task : TSK_TX_COMPLETION
    Inputs : Tag, TC, Length, Completion ID
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Completion TLP
    *************************************************************/

    task TSK_TX_COMPLETION;
        input    [15:0]   req_id_;      // Requester ID
        input    [7:0]    tag_;         // Tag
        input    [2:0]    tc_;          // Traffic Class
        input    [10:0]   len_;         // Length (in DW)
        input    [11:0]   byte_count_;  // Length (in bytes)
        input    [6:0]    lower_addr_;  // Lower 7-bits of Address of first valid data
        input    [2:0]    comp_status_; // Completion Status. 'b000: Success; 'b001: Unsupported Request; 'b010: Config Request Retry Status;'b100: Completer Abort
        input             ep_;          // Poisoned Data: Payload is invalid if set
        input    [2:0]    attr_;        // Attributes. {ID Based Ordering, Relaxed Ordering, No Snoop}
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_CC_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_cc_tvalid         <= #(Tcq) 1'b1;
            s_axis_cc_tlast          <= #(Tcq) 1'b1;
            s_axis_cc_tkeep          <= #(Tcq) 16'h0007;
            //s_axis_cc_tuser          <= #(Tcq) {(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity : 32'b0),1'b0};
            s_axis_cc_tuser          <= #(Tcq) {/*(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity :*/ 64'b0, // parity 64 bit -[80:17]
                                                1'b0,                    // Discontinue          
                                                4'b0000,                 // is_eop1_ptr
                                                4'b1010,                 // is_eop0_ptr   There are 11 Dwords 0-10. 0xA.
                                                2'b00,                   // is_eop[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b01};                  // is_sop[1:0]


            s_axis_cc_tdata          <= #(Tcq) {256'b0, 128'b0, // *unused*
                                                 //128
                                                32'b0,          // *unused*
                                                 //96
                                                1'b0,           // Force ECRC
                                                attr_,          // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                tc_,            // 3-bit Traffic Class
                                                1'b1,           // Completer ID to Control Selection of Client
                                                RP_BUS_DEV_FNS, // Completer ID
                                                tag_,           // Tag
                                                 //64
                                                req_id_,        // Requester ID
                                                1'b0,           // *reserved*
                                                ep_,            // Poisoned Completion
                                                comp_status_,   // Completion Status {0= SC, 1= UR, 2= CRS, 4= CA}
                                                len_,           // DWORD Count
                                                 //32
                                                2'b0,           // *reserved*
                                                1'b0,           // Locked Read Completion
                                                1'b0,           // Byte Count MSB
                                                byte_count_,    // Byte Count
                                                6'b0,           // *reserved*
                                                2'b0,           // Address Type
                                                1'b0,           // *reserved*
                                                lower_addr_     // Starting Address of the Completion Data Byte *not used*
                                               };
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b000,         // Fmt for Completion w/o Data
                                                5'b01010,       // Type for Completion w/o Data
                                                1'b0,           // *reserved*
                                                tc_,            // 3-bit Traffic Class
                                                1'b0,           // *reserved*
                                                attr_[2],           // Attributes {ID Based Ordering}
                                                1'b0,           // *reserved*
                                                1'b0,           // TLP Processing Hints
                                                1'b0,           // TLP Digest Present
                                                ep_,            // Poisoned Req
                                                attr_[1:0],     // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,          // Address Translation
                                                len_[9:0],      // DWORD Count
                                                 //32
                                                RP_BUS_DEV_FNS, // Completer ID
                                                comp_status_,   // Completion Status {0= SC, 1= UR, 2= CRS, 4= CA}
                                                1'b0,           // Byte Count Modified (only used in PCI-X)
                                                byte_count_,    // Byte Count
                                                 //64
                                                req_id_,        // Requester ID
                                                tag_,           // Tag
                                                1'b0,           // *reserved
                                                lower_addr_,    // Starting Address of the Completion Data Byte *not used*
                                                32'b0,          // *unused*
                                                 //128
                                                128'b0          // *unused*
                                                 //512
                                               };
                                               
            pcie_tlp_rem             <= #(Tcq)  4'b1101;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_CC_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_cc_tvalid         <= #(Tcq) 1'b0;
            s_axis_cc_tlast          <= #(Tcq) 1'b0;
            s_axis_cc_tkeep          <= #(Tcq) 16'h0000;
            s_axis_cc_tuser          <= #(Tcq) 83'b0;
            s_axis_cc_tdata          <= #(Tcq) 512'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 4'b0000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_COMPLETION

    /************************************************************
    Task : TSK_TX_COMPLETION_DATA
    Inputs : Tag, TC, Length, Completion ID
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Completion TLP
    *************************************************************/

    task TSK_TX_COMPLETION_DATA;
        input   [15:0]   req_id_;      // Requester ID
        input   [7:0]    tag_;         // Tag
        input   [2:0]    tc_;          // Traffic Class
        input   [10:0]   len_;         // Length (in DW)
        input   [11:0]   byte_count_;  // Length (in bytes)
        input   [10:0]   lower_addr_;  // Lower 7-bits of Address of first valid data
        input [RP_BAR_SIZE:0] ram_ptr; // RP RAM Read Offset
        input   [2:0]    comp_status_; // Completion Status. 'b000: Success; 'b001: Unsupported Request; 'b010: Config Request Retry Status;'b100: Completer Abort
        input            ep_;          // Poisoned Data: Payload is invalid if set
        input   [2:0]    attr_;        // Attributes. {ID Based Ordering, Relaxed Ordering, No Snoop}
        reg     [10:0]   _len;         // Length Info on pcie_tlp_data -- Used to count how many times to loop
        reg     [10:0]   len_i;        // Length Info on s_axis_rq_tdata -- Used to count how many times to loop
        reg     [2:0]    aa_dw;        // Adjusted DW Count for Address Aligned Mode
        reg     [511:0]  aa_data;      // Adjusted Data for Address Aligned Mode
        reg     [415:0]  data_axis_i;  // Data Info for s_axis_rq_tdata
        reg     [415:0]  data_pcie_i;  // Data Info for pcie_tlp_data
        reg     [RP_BAR_SIZE:0]   _j;  // Byte Index for aa_data
        reg     [RP_BAR_SIZE:0]  _jj;  // Byte Index pcie_tlp_data
        integer          start_addr;   // Start Location for Payload DW0
        
        begin
            //-----------------------------------------------------------------------\\

            $display(" ***** TSK_TX_COMPLETION_DATA ****** addr = %d., byte_count =%d, len = %d, comp_status = %d\n", lower_addr_, byte_count_, len_, comp_status_ ) ;
            //$display("[%t] : CC Data Completion Task Begin", $realtime);
            if (AXISTEN_IF_CC_ALIGNMENT_MODE=="TRUE") begin
                start_addr  = 0;
                aa_dw       = lower_addr_[4:2];
            end else begin
                start_addr  = 52;
                aa_dw       = 3'b000;
            end
            
            len_i           = len_ + aa_dw;
            _len            = len_;
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_CC_RDY);
            //-----------------------------------------------------------------------\\
            // Start of First Data Beat
            data_axis_i        =  {
                                   DATA_STORE[lower_addr_ +51], DATA_STORE[lower_addr_ +50], DATA_STORE[lower_addr_ +49],
                                   DATA_STORE[lower_addr_ +48], DATA_STORE[lower_addr_ +47], DATA_STORE[lower_addr_ +46],
                                   DATA_STORE[lower_addr_ +45], DATA_STORE[lower_addr_ +44], DATA_STORE[lower_addr_ +43],
                                   DATA_STORE[lower_addr_ +42], DATA_STORE[lower_addr_ +41], DATA_STORE[lower_addr_ +40],
                                   DATA_STORE[lower_addr_ +39], DATA_STORE[lower_addr_ +38], DATA_STORE[lower_addr_ +37],
                                   DATA_STORE[lower_addr_ +36], DATA_STORE[lower_addr_ +35], DATA_STORE[lower_addr_ +34],
                                   DATA_STORE[lower_addr_ +33], DATA_STORE[lower_addr_ +32], DATA_STORE[lower_addr_ +31],
                                   DATA_STORE[lower_addr_ +30], DATA_STORE[lower_addr_ +29], DATA_STORE[lower_addr_ +28],
                                   DATA_STORE[lower_addr_ +27], DATA_STORE[lower_addr_ +26], DATA_STORE[lower_addr_ +25],
                                   DATA_STORE[lower_addr_ +24], DATA_STORE[lower_addr_ +23], DATA_STORE[lower_addr_ +22],
                                   DATA_STORE[lower_addr_ +21], DATA_STORE[lower_addr_ +20], DATA_STORE[lower_addr_ +19],
                                   DATA_STORE[lower_addr_ +18], DATA_STORE[lower_addr_ +17], DATA_STORE[lower_addr_ +16],
                                   DATA_STORE[lower_addr_ +15], DATA_STORE[lower_addr_ +14], DATA_STORE[lower_addr_ +13],
                                   DATA_STORE[lower_addr_ +12], DATA_STORE[lower_addr_ +11], DATA_STORE[lower_addr_ +10],
                                   DATA_STORE[lower_addr_ + 9], DATA_STORE[lower_addr_ + 8], DATA_STORE[lower_addr_ + 7],
                                   DATA_STORE[lower_addr_ + 6], DATA_STORE[lower_addr_ + 5], DATA_STORE[lower_addr_ + 4],
                                   DATA_STORE[lower_addr_ + 3], DATA_STORE[lower_addr_ + 2], DATA_STORE[lower_addr_ + 1],
                                   DATA_STORE[lower_addr_ + 0]
                                  };

            data_pcie_i        =  {
                                   DATA_STORE[lower_addr_ + 0], DATA_STORE[lower_addr_ + 1], DATA_STORE[lower_addr_ + 2],
                                   DATA_STORE[lower_addr_ + 3], DATA_STORE[lower_addr_ + 4], DATA_STORE[lower_addr_ + 5],
                                   DATA_STORE[lower_addr_ + 6], DATA_STORE[lower_addr_ + 7], DATA_STORE[lower_addr_ + 8],
                                   DATA_STORE[lower_addr_ + 9], DATA_STORE[lower_addr_ +10], DATA_STORE[lower_addr_ +11],
                                   DATA_STORE[lower_addr_ +12], DATA_STORE[lower_addr_ +13], DATA_STORE[lower_addr_ +14],
                                   DATA_STORE[lower_addr_ +15], DATA_STORE[lower_addr_ +16], DATA_STORE[lower_addr_ +17],
                                   DATA_STORE[lower_addr_ +18], DATA_STORE[lower_addr_ +19], DATA_STORE[lower_addr_ +20],
                                   DATA_STORE[lower_addr_ +21], DATA_STORE[lower_addr_ +22], DATA_STORE[lower_addr_ +23],
                                   DATA_STORE[lower_addr_ +24], DATA_STORE[lower_addr_ +25], DATA_STORE[lower_addr_ +26],
                                   DATA_STORE[lower_addr_ +27], DATA_STORE[lower_addr_ +28], DATA_STORE[lower_addr_ +29],
                                   DATA_STORE[lower_addr_ +30], DATA_STORE[lower_addr_ +31], DATA_STORE[lower_addr_ +32],
                                   DATA_STORE[lower_addr_ +33], DATA_STORE[lower_addr_ +34], DATA_STORE[lower_addr_ +35],
                                   DATA_STORE[lower_addr_ +36], DATA_STORE[lower_addr_ +37], DATA_STORE[lower_addr_ +38],
                                   DATA_STORE[lower_addr_ +39], DATA_STORE[lower_addr_ +40], DATA_STORE[lower_addr_ +41],
                                   DATA_STORE[lower_addr_ +42], DATA_STORE[lower_addr_ +43], DATA_STORE[lower_addr_ +44],
                                   DATA_STORE[lower_addr_ +45], DATA_STORE[lower_addr_ +46], DATA_STORE[lower_addr_ +47],
                                   DATA_STORE[lower_addr_ +48], DATA_STORE[lower_addr_ +49], DATA_STORE[lower_addr_ +50],
                                   DATA_STORE[lower_addr_ +51]
                                  };

            //s_axis_cc_tuser   <= #(Tcq) {(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity : 32'b0),1'b0};
            s_axis_cc_tuser          <= #(Tcq) {/*(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity :*/ 64'b0, // parity 64 bit -[80:17]
                                                1'b0,                    // Discontinue          
                                                4'b0000,                 // is_eop1_ptr
                                                4'b1010,                 // is_eop0_ptr  There are 11 Dwords 0-10, 0xA
                                                2'b01,                   // is_eop[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b01};                  // is_sop[1:0]


            s_axis_cc_tdata   <= #(Tcq) {
                                         ((AXISTEN_IF_CC_ALIGNMENT_MODE == "FALSE" ) ? data_axis_i : 416'h0), // 416-bit completion data
                                         1'b0,        // Force ECRC                                  //96
                                         attr_,      // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                         tc_,         // Traffic Class
                                         1'b1,        // Completer ID to Control Selection of Client
                                         RP_BUS_DEV_FNS, // Completer ID
                                         tag_ ,          // Tag
                                         req_id_,        // Requester ID                             //64
                                         1'b0,           // *reserved*
                                         ep_,            // Poisoned Completion
                                         comp_status_,   // Completion Status {0= SC, 1= UR, 2= CRS, 4= CA}
                                         len_,           // DWORD Count
                                         2'b0,           // *reserved*                               //32
                                         1'b0,           // Locked Read Completion
                                         1'b0,           // Byte Count MSB
                                         byte_count_,    // Byte Count
                                         6'b0,           // *reserved*
                                         2'b0,           // Address Type
                                         1'b0,           // *reserved*
                                         lower_addr_[6:0] };  // Starting Address of the Completion Data Byte
            //-----------------------------------------------------------------------\\
            pcie_tlp_data     <= #(Tcq) {
                                         3'b010,         // Fmt for Completion with Data
                                         5'b01010,       // Type for Completion with Data
                                         1'b0,           // *reserved*
                                         tc_,            // 3-bit Traffic Class
                                         1'b0,           // *reserved*
                                         attr_[2],           // Attributes {ID Based Ordering}
                                         1'b0,           // *reserved*
                                         1'b0,           // TLP Processing Hints
                                         1'b0,           // TLP Digest Present
                                         ep_,            // Poisoned Req
                                         attr_[1:0],          // Attributes {Relaxed Ordering, No Snoop}
                                         2'b00,          // Address Translation
                                         len_[9:0],      // DWORD Count                                            //32
                                         RP_BUS_DEV_FNS, // Completer ID
                                         comp_status_,   // Completion Status {0= SC, 1= UR, 2= CRS, 4= CA}
                                         1'b0,           // Byte Count Modified (only used in PCI-X)
                                         byte_count_,    // Byte Count                                             //64
                                         req_id_,        // Requester ID
                                         tag_,           // Tag
                                         1'b0,           // *reserved
                                         lower_addr_[6:0],    // Starting Address of the Completion Data Byte           //96
                                         data_pcie_i };  // 416-bit completion data                                //512
                                         
            pcie_tlp_rem      <= #(Tcq) (_len > 12) ? 4'b0000 : (13-_len);
            _len               = (_len > 12) ? (_len - 11'hD) : 11'h0;
            //-----------------------------------------------------------------------\\
            s_axis_cc_tvalid  <= #(Tcq) 1'b1;
            
            if (len_i > 13 || AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE") begin
                s_axis_cc_tlast          <= #(Tcq) 1'b0;
                s_axis_cc_tkeep          <= #(Tcq) 16'hFFFF;
                
                len_i = (AXISTEN_IF_CC_ALIGNMENT_MODE == "FALSE") ? (len_i - 11'hD) : len_i; // Don't subtract 13 in Address Aligned because
                                                                                             // it's always padded with zeros on first beat
                
                // pcie_tlp_data doesn't append zero even in Address Aligned mode, so it should mark this cycle as the last beat if it has no more payload to log.
                // The AXIS CC interface will need to execute the next cycle, but we're just not going to log that data beat in pcie_tlp_data
                if (_len == 0)
                    TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_CC_RDY);
                else
                    TSK_TX_SYNCHRONIZE(1, 1, 0, `SYNC_CC_RDY);
                
            end else begin
                case (len_i)
                  1 :      begin s_axis_cc_tkeep <= #(Tcq) 16'h000F; end
                  2 :      begin s_axis_cc_tkeep <= #(Tcq) 16'h001F; end
                  3 :      begin s_axis_cc_tkeep <= #(Tcq) 16'h003F; end
                  4 :      begin s_axis_cc_tkeep <= #(Tcq) 16'h007F; end
                  5 :      begin s_axis_cc_tkeep <= #(Tcq) 16'h00FF; end
                  6 :      begin s_axis_cc_tkeep <= #(Tcq) 16'h01FF; end
                  7 :      begin s_axis_cc_tkeep <= #(Tcq) 16'h03FF; end
                  8 :      begin s_axis_cc_tkeep <= #(Tcq) 16'h07FF; end
                  9 :      begin s_axis_cc_tkeep <= #(Tcq) 16'h0FFF; end
                  10 :     begin s_axis_cc_tkeep <= #(Tcq) 16'h1FFF; end
                  11 :     begin s_axis_cc_tkeep <= #(Tcq) 16'h3FFF; end
                  12 :     begin s_axis_cc_tkeep <= #(Tcq) 16'h7FFF; end
                  default: begin s_axis_cc_tkeep <= #(Tcq) 16'hFFFF; end
                endcase
                    
                s_axis_cc_tlast          <= #(Tcq) 1'b1;
                    
                len_i                    = 0;

                TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_CC_RDY);
            end
            // End of First Data Beat
            //-----------------------------------------------------------------------\\
            // Start of Second and Subsequent Data Beat
            if (len_i != 0 || AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE") begin
                fork 
                
                begin // Sequential group 1 - AXIS CC
                    for (_j = start_addr; len_i != 0; _j = _j + 64) begin
                        if(_j == start_addr) begin 
                            aa_data = {
                                       DATA_STORE[lower_addr_ + _j + 63], DATA_STORE[lower_addr_ + _j + 62], DATA_STORE[lower_addr_ + _j + 61],
                                       DATA_STORE[lower_addr_ + _j + 60], DATA_STORE[lower_addr_ + _j + 59], DATA_STORE[lower_addr_ + _j + 58],
                                       DATA_STORE[lower_addr_ + _j + 57], DATA_STORE[lower_addr_ + _j + 56], DATA_STORE[lower_addr_ + _j + 55],
                                       DATA_STORE[lower_addr_ + _j + 54], DATA_STORE[lower_addr_ + _j + 53], DATA_STORE[lower_addr_ + _j + 52],
                                       DATA_STORE[lower_addr_ + _j + 51], DATA_STORE[lower_addr_ + _j + 50], DATA_STORE[lower_addr_ + _j + 49],
                                       DATA_STORE[lower_addr_ + _j + 48], DATA_STORE[lower_addr_ + _j + 47], DATA_STORE[lower_addr_ + _j + 46],
                                       DATA_STORE[lower_addr_ + _j + 45], DATA_STORE[lower_addr_ + _j + 44], DATA_STORE[lower_addr_ + _j + 43],
                                       DATA_STORE[lower_addr_ + _j + 42], DATA_STORE[lower_addr_ + _j + 41], DATA_STORE[lower_addr_ + _j + 40],
                                       DATA_STORE[lower_addr_ + _j + 39], DATA_STORE[lower_addr_ + _j + 38], DATA_STORE[lower_addr_ + _j + 37],
                                       DATA_STORE[lower_addr_ + _j + 36], DATA_STORE[lower_addr_ + _j + 35], DATA_STORE[lower_addr_ + _j + 34],
                                       DATA_STORE[lower_addr_ + _j + 33], DATA_STORE[lower_addr_ + _j + 32], DATA_STORE[lower_addr_ + _j + 31],
                                       DATA_STORE[lower_addr_ + _j + 30], DATA_STORE[lower_addr_ + _j + 29], DATA_STORE[lower_addr_ + _j + 28],
                                       DATA_STORE[lower_addr_ + _j + 27], DATA_STORE[lower_addr_ + _j + 26], DATA_STORE[lower_addr_ + _j + 25],
                                       DATA_STORE[lower_addr_ + _j + 24], DATA_STORE[lower_addr_ + _j + 23], DATA_STORE[lower_addr_ + _j + 22],
                                       DATA_STORE[lower_addr_ + _j + 21], DATA_STORE[lower_addr_ + _j + 20], DATA_STORE[lower_addr_ + _j + 19],
                                       DATA_STORE[lower_addr_ + _j + 18], DATA_STORE[lower_addr_ + _j + 17], DATA_STORE[lower_addr_ + _j + 16],
                                       DATA_STORE[lower_addr_ + _j + 15], DATA_STORE[lower_addr_ + _j + 14], DATA_STORE[lower_addr_ + _j + 13],
                                       DATA_STORE[lower_addr_ + _j + 12], DATA_STORE[lower_addr_ + _j + 11], DATA_STORE[lower_addr_ + _j + 10],
                                       DATA_STORE[lower_addr_ + _j +  9], DATA_STORE[lower_addr_ + _j +  8], DATA_STORE[lower_addr_ + _j +  7],
                                       DATA_STORE[lower_addr_ + _j +  6], DATA_STORE[lower_addr_ + _j +  5], DATA_STORE[lower_addr_ + _j +  4],
                                       DATA_STORE[lower_addr_ + _j +  3], DATA_STORE[lower_addr_ + _j +  2], DATA_STORE[lower_addr_ + _j +  1],
                                       DATA_STORE[lower_addr_ + _j +  0]
                                      } << (aa_dw*4*8);
                        end else begin
                            aa_data = {
                                       DATA_STORE[lower_addr_ + _j + 63 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 62 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 61 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 60 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 59 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 58 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 57 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 56 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 55 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 54 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 53 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 52 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 51 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 50 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 49 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 48 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 47 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 46 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 45 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 44 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 43 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 42 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 41 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 40 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 39 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 38 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 37 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 36 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 35 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 34 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 33 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 32 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 31 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 30 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 29 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 28 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 27 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 26 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 25 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 24 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 23 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 22 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 21 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 20 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 19 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 18 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 17 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 16 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 15 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 14 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 13 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j + 12 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 11 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j + 10 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j +  9 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j +  8 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j +  7 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j +  6 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j +  5 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j +  4 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j +  3 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j +  2 - (aa_dw*4)], DATA_STORE[lower_addr_ + _j +  1 - (aa_dw*4)],
                                       DATA_STORE[lower_addr_ + _j +  0 - (aa_dw*4)]
                                      };
                        end
                                               
                        s_axis_cc_tdata           <= #(Tcq) aa_data;

                        if ((len_i)/16 == 0) begin
                            case (len_i % 16)
                              1 :  begin len_i = len_i - 1;  s_axis_cc_tkeep <= #(Tcq) 16'h0001; end // D0---------------------------------------------------
                              2 :  begin len_i = len_i - 2;  s_axis_cc_tkeep <= #(Tcq) 16'h0003; end // D0-D1------------------------------------------------
                              3 :  begin len_i = len_i - 3;  s_axis_cc_tkeep <= #(Tcq) 16'h0007; end // D0-D1-D2---------------------------------------------
                              4 :  begin len_i = len_i - 4;  s_axis_cc_tkeep <= #(Tcq) 16'h000F; end // D0-D1-D2-D3------------------------------------------
                              5 :  begin len_i = len_i - 5;  s_axis_cc_tkeep <= #(Tcq) 16'h001F; end // D0-D1-D2-D3-D4---------------------------------------
                              6 :  begin len_i = len_i - 6;  s_axis_cc_tkeep <= #(Tcq) 16'h003F; end // D0-D1-D2-D3-D4-D5------------------------------------
                              7 :  begin len_i = len_i - 7;  s_axis_cc_tkeep <= #(Tcq) 16'h007F; end // D0-D1-D2-D3-D4-D5-D6---------------------------------
                              8 :  begin len_i = len_i - 8;  s_axis_cc_tkeep <= #(Tcq) 16'h00FF; end // D0-D1-D2-D3-D4-D5-D6-D7------------------------------
                              9 :  begin len_i = len_i - 9;  s_axis_cc_tkeep <= #(Tcq) 16'h01FF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8---------------------------
                              10 : begin len_i = len_i - 10; s_axis_cc_tkeep <= #(Tcq) 16'h03FF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9------------------------
                              11 : begin len_i = len_i - 11; s_axis_cc_tkeep <= #(Tcq) 16'h07FF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10--------------------
                              12 : begin len_i = len_i - 12; s_axis_cc_tkeep <= #(Tcq) 16'h0FFF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11----------------
                              13 : begin len_i = len_i - 13; s_axis_cc_tkeep <= #(Tcq) 16'h1FFF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12------------
                              14 : begin len_i = len_i - 14; s_axis_cc_tkeep <= #(Tcq) 16'h3FFF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13--------
                              15 : begin len_i = len_i - 15; s_axis_cc_tkeep <= #(Tcq) 16'h7FFF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13-D14----
                              0  : begin len_i = len_i - 16; s_axis_cc_tkeep <= #(Tcq) 16'hFFFF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13-D14-D15
                            endcase
                        end else begin
                            len_i              = len_i - 16; s_axis_cc_tkeep <= #(Tcq) 16'hFFFF;     // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13-D14-D15
                        end

                        if (len_i == 0)
                            s_axis_cc_tlast          <= #(Tcq) 1'b1;
                        else
                            s_axis_cc_tlast          <= #(Tcq) 1'b0;
                            
                        // Call this just to check for the tready, but don't log anything. That's the job for pcie_tlp_data
                        // The reason for splitting the TSK_TX_SYNCHRONIZE task and distribute them in both sequential group
                        // is that in address aligned mode, it's possible that the additional padded zeros cause the AXIS CC
                        // to be one beat longer than the actual PCIe TLP. When it happens do not log the last clock beat
                        // but just send the packet on AXIS CC interface
                        TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_CC_RDY);
                    
                    end // for loop
                end // End sequential group 1 - AXIS CC
                
                begin // Sequential group 2 - pcie_tlp
                    for (_jj = 52; _len != 0; _jj = _jj + 64) begin
                        pcie_tlp_data <= #(Tcq)    {
                                                    DATA_STORE[lower_addr_ + _jj +  0], DATA_STORE[lower_addr_ + _jj +  1], DATA_STORE[lower_addr_ + _jj +  2],
                                                    DATA_STORE[lower_addr_ + _jj +  3], DATA_STORE[lower_addr_ + _jj +  4], DATA_STORE[lower_addr_ + _jj +  5],
                                                    DATA_STORE[lower_addr_ + _jj +  6], DATA_STORE[lower_addr_ + _jj +  7], DATA_STORE[lower_addr_ + _jj +  8],
                                                    DATA_STORE[lower_addr_ + _jj +  9], DATA_STORE[lower_addr_ + _jj + 10], DATA_STORE[lower_addr_ + _jj + 11],
                                                    DATA_STORE[lower_addr_ + _jj + 12], DATA_STORE[lower_addr_ + _jj + 13], DATA_STORE[lower_addr_ + _jj + 14],
                                                    DATA_STORE[lower_addr_ + _jj + 15], DATA_STORE[lower_addr_ + _jj + 16], DATA_STORE[lower_addr_ + _jj + 17],
                                                    DATA_STORE[lower_addr_ + _jj + 18], DATA_STORE[lower_addr_ + _jj + 19], DATA_STORE[lower_addr_ + _jj + 20],
                                                    DATA_STORE[lower_addr_ + _jj + 21], DATA_STORE[lower_addr_ + _jj + 22], DATA_STORE[lower_addr_ + _jj + 23],
                                                    DATA_STORE[lower_addr_ + _jj + 24], DATA_STORE[lower_addr_ + _jj + 25], DATA_STORE[lower_addr_ + _jj + 26],
                                                    DATA_STORE[lower_addr_ + _jj + 27], DATA_STORE[lower_addr_ + _jj + 28], DATA_STORE[lower_addr_ + _jj + 29],
                                                    DATA_STORE[lower_addr_ + _jj + 30], DATA_STORE[lower_addr_ + _jj + 31], DATA_STORE[lower_addr_ + _jj + 32],
                                                    DATA_STORE[lower_addr_ + _jj + 33], DATA_STORE[lower_addr_ + _jj + 34], DATA_STORE[lower_addr_ + _jj + 35],
                                                    DATA_STORE[lower_addr_ + _jj + 36], DATA_STORE[lower_addr_ + _jj + 37], DATA_STORE[lower_addr_ + _jj + 38],
                                                    DATA_STORE[lower_addr_ + _jj + 39], DATA_STORE[lower_addr_ + _jj + 40], DATA_STORE[lower_addr_ + _jj + 41],
                                                    DATA_STORE[lower_addr_ + _jj + 42], DATA_STORE[lower_addr_ + _jj + 43], DATA_STORE[lower_addr_ + _jj + 44],
                                                    DATA_STORE[lower_addr_ + _jj + 45], DATA_STORE[lower_addr_ + _jj + 46], DATA_STORE[lower_addr_ + _jj + 47],
                                                    DATA_STORE[lower_addr_ + _jj + 48], DATA_STORE[lower_addr_ + _jj + 49], DATA_STORE[lower_addr_ + _jj + 50],
                                                    DATA_STORE[lower_addr_ + _jj + 51], DATA_STORE[lower_addr_ + _jj + 52], DATA_STORE[lower_addr_ + _jj + 53],
                                                    DATA_STORE[lower_addr_ + _jj + 54], DATA_STORE[lower_addr_ + _jj + 55], DATA_STORE[lower_addr_ + _jj + 56],
                                                    DATA_STORE[lower_addr_ + _jj + 57], DATA_STORE[lower_addr_ + _jj + 58], DATA_STORE[lower_addr_ + _jj + 59],
                                                    DATA_STORE[lower_addr_ + _jj + 60], DATA_STORE[lower_addr_ + _jj + 61], DATA_STORE[lower_addr_ + _jj + 62],
                                                    DATA_STORE[lower_addr_ + _jj + 63]
                                                   };
                                                   
                        if ((_len/16) == 0) begin
                            case (_len % 16)
                                1 :  begin _len = _len - 1;  pcie_tlp_rem  <= #(Tcq) 4'b1111; end // D0---------------------------------------------------
                                2 :  begin _len = _len - 2;  pcie_tlp_rem  <= #(Tcq) 4'b1110; end // D0-D1------------------------------------------------
                                3 :  begin _len = _len - 3;  pcie_tlp_rem  <= #(Tcq) 4'b1101; end // D0-D1-D2---------------------------------------------
                                4 :  begin _len = _len - 4;  pcie_tlp_rem  <= #(Tcq) 4'b1100; end // D0-D1-D2-D3------------------------------------------
                                5 :  begin _len = _len - 5;  pcie_tlp_rem  <= #(Tcq) 4'b1011; end // D0-D1-D2-D3-D4---------------------------------------
                                6 :  begin _len = _len - 6;  pcie_tlp_rem  <= #(Tcq) 4'b1010; end // D0-D1-D2-D3-D4-D5------------------------------------
                                7 :  begin _len = _len - 7;  pcie_tlp_rem  <= #(Tcq) 4'b1001; end // D0-D1-D2-D3-D4-D5-D6---------------------------------
                                8 :  begin _len = _len - 8;  pcie_tlp_rem  <= #(Tcq) 4'b1000; end // D0-D1-D2-D3-D4-D5-D6-D7------------------------------
                                9 :  begin _len = _len - 9;  pcie_tlp_rem  <= #(Tcq) 4'b0111; end // D0-D1-D2-D3-D4-D5-D6-D7-D8---------------------------
                                10 : begin _len = _len - 10; pcie_tlp_rem  <= #(Tcq) 4'b0110; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9------------------------
                                11 : begin _len = _len - 11; pcie_tlp_rem  <= #(Tcq) 4'b0101; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10--------------------
                                12 : begin _len = _len - 12; pcie_tlp_rem  <= #(Tcq) 4'b0100; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11----------------
                                13 : begin _len = _len - 13; pcie_tlp_rem  <= #(Tcq) 4'b0011; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12------------
                                14 : begin _len = _len - 14; pcie_tlp_rem  <= #(Tcq) 4'b0010; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13--------
                                15 : begin _len = _len - 15; pcie_tlp_rem  <= #(Tcq) 4'b0001; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13-D14----
                                0  : begin _len = _len - 16; pcie_tlp_rem  <= #(Tcq) 4'b0000; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13-D14-D15
                            endcase 
                        end else begin
                            _len                = _len - 16; pcie_tlp_rem  <= #(Tcq) 4'b0000;     // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13-D14-D15
                        end
                        
                        if (_len == 0)
                            TSK_TX_SYNCHRONIZE(0, 1, 1, `SYNC_CC_RDY);
                        else
                            TSK_TX_SYNCHRONIZE(0, 1, 0, `SYNC_CC_RDY);
                    end // for loop
                end // End sequential group 2 - pcie_tlp

                join
            end  // if
            // End of Second and Subsequent Data Beat
            //-----------------------------------------------------------------------\\
            // Packet Complete - Drive 0s
            s_axis_cc_tvalid         <= #(Tcq) 1'b0;
            s_axis_cc_tlast          <= #(Tcq) 1'b0;
            s_axis_cc_tkeep          <= #(Tcq) 8'h00;
            s_axis_cc_tuser          <= #(Tcq) 83'b0;
            s_axis_cc_tdata          <= #(Tcq) 512'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 4'b0000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_COMPLETION_DATA

    /************************************************************
    Task : TSK_TX_MESSAGE
    Inputs : Tag, TC, Address, Message Routing, Message Code
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Message TLP
    *************************************************************/

    task TSK_TX_MESSAGE;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [10:0]   len_;
        input    [63:0]   data_;
        input    [2:0]    message_rtg_;
        input    [7:0]    message_code_;
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //--------- Tx Message Transaction :                          -----------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 8'h0F;          // 2DW Descriptor
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                64'b0,                   // Parity Bit slot - 64bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                16'h0000,                // TPH Steering Tag - 16 bit
                                                2'b00,                   // TPH indirect Tag Enable - 2bit
                                                4'b0000,                 // TPH Type - 4 bit
                                                2'b00,                   // TPH Present - 2 bit
                                                1'b0,                    // Discontinue                                   
                                                4'b0000,                 // is_eop1_ptr
                                                4'b0000,                 // is_eop0_ptr
                                                2'b01,                   // is_eop[1:0]
                                                2'b10,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b01,                   // is_sop[1:0]
                                                2'b00,2'b00,             // Byte Lane number in case of Address Aligned mode - 4 bit
                                                4'b0000,4'b0000,         // Last BE of the Write Data -  8 bit
                                                4'b0000,4'b0000          // First BE of the Write Data - 8 bit
                                               };
 

            s_axis_rq_tdata          <= #(Tcq) {256'b0,128'b0,        // 4DW unused
                                                1'b0,          // Force ECRC
                                                3'b000,        // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                tc_,           // Traffic Class
                                                1'b1,          // RID Enable to use the Client supplied Bus/Device/Func No
                                                5'b0,          // *reserved*
                                                message_rtg_,  // Message Routing
                                                message_code_, // Message Code
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                RP_BUS_DEV_FNS, // Requester ID
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b1100,       // Request Type for Message
                                                len_ ,         // DWORD Count
                                                data_[63:32],  // Vendor Defined Header Bytes
                                                data_[15: 0],  // Vendor ID
                                                data_[31:16]   // Destination ID
                                               };
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b001,         // Fmt for Message w/o Data
                                                {{2'b10}, {message_rtg_}}, // Type for Message w/o Data
                                                1'b0,           // *reserved*
                                                tc_,            // 3-bit Traffic Class
                                                1'b0,           // *reserved*
                                                1'b0,           // Attributes {ID Based Ordering}
                                                1'b0,           // *reserved*
                                                1'b0,           // TLP Processing Hints
                                                1'b0,           // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,          // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,          // Address Translation
                                                10'b0,          // DWORD Count                                     //32
                                                RP_BUS_DEV_FNS, // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                message_code_,  // Message Code                                    //64
                                                data_[63:32],   // Vendor Defined Header Bytes
                                                data_[31:16],   // Destination ID
                                                data_[15: 0],   // Vendor ID
                                                128'b0          // *unused*
                                               };

            pcie_tlp_rem             <= #(Tcq)  3'b100;
            set_malformed            <= #(Tcq)  1'b0;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h0;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 137'b0;
            s_axis_rq_tdata          <= #(Tcq) 512'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MESSAGE

    /************************************************************
    Task : TSK_TX_MESSAGE_DATA
    Inputs : Tag, TC, Address, Message Routing, Message Code
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Message Data TLP
    *************************************************************/

    task TSK_TX_MESSAGE_DATA;
        input  [7:0]    tag_;
        input  [2:0]    tc_;
        input  [10:0]   len_;
        input  [63:0]   data_;
        input  [2:0]    message_rtg_;
        input  [7:0]    message_code_;
        reg    [127:0]  data_axis_i;
        reg    [127:0]  data_pcie_i;
        reg    [10:0]   _len;
        reg    [10:0]   len_i;
        integer         _j;
        begin
            //-----------------------------------------------------------------------\\
            data_axis_i = 0;
            data_pcie_i = 0;
            _len = len_;
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid  <= #(Tcq) 1'b1;

            data_axis_i        =  {
                                   DATA_STORE[15],
                                   DATA_STORE[14],
                                   DATA_STORE[13],
                                   DATA_STORE[12],
                                   DATA_STORE[11],
                                   DATA_STORE[10],
                                   DATA_STORE[9],
                                   DATA_STORE[8],
                                   data_
                                  };

            data_pcie_i        =  {
                                   DATA_STORE[0],
                                   DATA_STORE[1],
                                   DATA_STORE[2],
                                   DATA_STORE[3],
                                   DATA_STORE[4],
                                   DATA_STORE[5],
                                   DATA_STORE[6],
                                   DATA_STORE[7],
                                   DATA_STORE[8],
                                   DATA_STORE[9],
                                   DATA_STORE[10],
                                   DATA_STORE[11],
                                   DATA_STORE[12],
                                   DATA_STORE[13],
                                   DATA_STORE[14],
                                   DATA_STORE[15]
                                  };
            s_axis_rq_tuser_wo_parity <= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                64'b0,                   // Parity Bit slot - 64bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                16'h0000,                // TPH Steering Tag - 16 bit
                                                2'b00,                   // TPH indirect Tag Enable - 2bit
                                                4'b0000,                 // TPH Type - 4 bit
                                                2'b00,                   // TPH Present - 2 bit
                                                1'b0,                    // Discontinue                                   
                                                4'b0000,                 // is_eop1_ptr
                                                4'b0000,                 // is_eop0_ptr
                                                2'b01,                   // is_eop[1:0]
                                                2'b10,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b01,                   // is_sop[1:0]
                                                2'b00,2'b00,             // Byte Lane number in case of Address Aligned mode - 4 bit
                                                4'b0000,4'b0000,         // Last BE of the Write Data -  8 bit
                                                4'b0000,4'b0000          // First BE of the Write Data - 8 bit
                                               };
 

            s_axis_rq_tdata   <= #(Tcq) {256'b0,data_axis_i,
                                         1'b0,          // Force ECRC
                                         3'b000,        // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                         tc_,           // Traffic Class
                                         1'b1,          // RID Enable to use the Client supplied Bus/Device/Func No
                                         5'b0,          // *reserved*
                                         message_rtg_,  // Message Routing
                                         message_code_, // Message Code
                                         (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                         RP_BUS_DEV_FNS, // Requester ID
                                         (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                         4'b1100,       // Request Type for Message
                                         len_ ,         // DWORD Count
                                         64'h0          // *unused*
                                        };
            //-----------------------------------------------------------------------\\
            pcie_tlp_data     <= #(Tcq) {
                                         3'b011,        // Fmt for Message with Data
                                         {{2'b10}, {message_rtg_}}, // Type for Message with Data
                                         1'b0,          // *reserved*
                                         tc_,           // 3-bit Traffic Class
                                         1'b0,           // *reserved*
                                         1'b0,           // Attributes {ID Based Ordering}
                                         1'b0,           // *reserved*
                                         1'b0,           // TLP Processing Hints
                                         1'b0,           // TLP Digest Present
                                         (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                         2'b00,          // Attributes {Relaxed Ordering, No Snoop}
                                         2'b00,          // Address Translation
                                         len_[9:0],      // DWORD Count                                            //32
                                         RP_BUS_DEV_FNS, // Requester ID
                                         (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                         message_code_,  // Message Code                                           //64
                                         data_,          // Message Data
                                         data_pcie_i
                                        };
            pcie_tlp_rem      <= #(Tcq)  3'b000;
            set_malformed     <= #(Tcq)  1'b0;
            //-----------------------------------------------------------------------\\
            if (_len > 4)
            begin
                len_i = len_ - 11'h4;
                s_axis_rq_tlast          <= #(Tcq) 1'b0;
                s_axis_rq_tkeep          <= #(Tcq) 8'hFF;
                TSK_TX_SYNCHRONIZE(1, 1, 0, `SYNC_RQ_RDY);
            end
            else
            begin
                len_i = len_;
                s_axis_rq_tlast          <= #(Tcq) 1'b1;

                if (_len == 1)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h1F;
                else if (_len == 2)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h3F;
                else if (_len == 3)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h7F;
                else
                    s_axis_rq_tkeep      <= #(Tcq) 8'hFF;

                TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            end
            //-----------------------------------------------------------------------\\
            if (_len > 4) begin
                for (_j = 16; _j < (_len * 4); _j = _j + 32) begin

                    s_axis_rq_tdata   <= #(Tcq){
                                                DATA_STORE[_j + 31],
                                                DATA_STORE[_j + 30],
                                                DATA_STORE[_j + 29],
                                                DATA_STORE[_j + 28],
                                                DATA_STORE[_j + 27],
                                                DATA_STORE[_j + 26],
                                                DATA_STORE[_j + 25],
                                                DATA_STORE[_j + 24],
                                                DATA_STORE[_j + 23],
                                                DATA_STORE[_j + 22],
                                                DATA_STORE[_j + 21],
                                                DATA_STORE[_j + 20],
                                                DATA_STORE[_j + 19],
                                                DATA_STORE[_j + 18],
                                                DATA_STORE[_j + 17],
                                                DATA_STORE[_j + 16],
                                                DATA_STORE[_j + 15],
                                                DATA_STORE[_j + 14],
                                                DATA_STORE[_j + 13],
                                                DATA_STORE[_j + 12],
                                                DATA_STORE[_j + 11],
                                                DATA_STORE[_j + 10],
                                                DATA_STORE[_j + 9],
                                                DATA_STORE[_j + 8],
                                                DATA_STORE[_j + 7],
                                                DATA_STORE[_j + 6],
                                                DATA_STORE[_j + 5],
                                                DATA_STORE[_j + 4],
                                                DATA_STORE[_j + 3],
                                                DATA_STORE[_j + 2],
                                                DATA_STORE[_j + 1],
                                                DATA_STORE[_j + 0]
                                               };

                    pcie_tlp_data <= #(Tcq)    {
                                                DATA_STORE[_j + 0],
                                                DATA_STORE[_j + 1],
                                                DATA_STORE[_j + 2],
                                                DATA_STORE[_j + 3],
                                                DATA_STORE[_j + 4],
                                                DATA_STORE[_j + 5],
                                                DATA_STORE[_j + 6],
                                                DATA_STORE[_j + 7],
                                                DATA_STORE[_j + 8],
                                                DATA_STORE[_j + 9],
                                                DATA_STORE[_j + 10],
                                                DATA_STORE[_j + 11],
                                                DATA_STORE[_j + 12],
                                                DATA_STORE[_j + 13],
                                                DATA_STORE[_j + 14],
                                                DATA_STORE[_j + 15],
                                                DATA_STORE[_j + 16],
                                                DATA_STORE[_j + 17],
                                                DATA_STORE[_j + 18],
                                                DATA_STORE[_j + 19],
                                                DATA_STORE[_j + 20],
                                                DATA_STORE[_j + 21],
                                                DATA_STORE[_j + 22],
                                                DATA_STORE[_j + 23],
                                                DATA_STORE[_j + 24],
                                                DATA_STORE[_j + 25],
                                                DATA_STORE[_j + 26],
                                                DATA_STORE[_j + 27],
                                                DATA_STORE[_j + 28],
                                                DATA_STORE[_j + 29],
                                                DATA_STORE[_j + 30],
                                                DATA_STORE[_j + 31]
                                               };

                    if ((_j + 31)  >=  (_len * 4 - 1)) begin
                        case (((_len - 11'h4)) % 8)
                          1 : begin len_i = len_i - 1; pcie_tlp_rem  <= #(Tcq) 3'b111; s_axis_rq_tkeep <= #(Tcq) 8'h01; end  // D0---------
                          2 : begin len_i = len_i - 2; pcie_tlp_rem  <= #(Tcq) 3'b110; s_axis_rq_tkeep <= #(Tcq) 8'h03; end  // D0-D1--------
                          3 : begin len_i = len_i - 3; pcie_tlp_rem  <= #(Tcq) 3'b101; s_axis_rq_tkeep <= #(Tcq) 8'h07; end  // D0-D1-D2-------
                          4 : begin len_i = len_i - 4; pcie_tlp_rem  <= #(Tcq) 3'b100; s_axis_rq_tkeep <= #(Tcq) 8'h0F; end  // D0-D1-D2-D3------
                          5 : begin len_i = len_i - 5; pcie_tlp_rem  <= #(Tcq) 3'b011; s_axis_rq_tkeep <= #(Tcq) 8'h1F; end  // D0-D1-D2-D3-D4-----
                          6 : begin len_i = len_i - 6; pcie_tlp_rem  <= #(Tcq) 3'b010; s_axis_rq_tkeep <= #(Tcq) 8'h3F; end  // D0-D1-D2-D3-D4-D5--
                          7 : begin len_i = len_i - 7; pcie_tlp_rem  <= #(Tcq) 3'b001; s_axis_rq_tkeep <= #(Tcq) 8'h7F; end  // D0-D1-D2-D3-D4-D5-D6
                          0 : begin len_i = len_i - 8; pcie_tlp_rem  <= #(Tcq) 3'b000; s_axis_rq_tkeep <= #(Tcq) 8'hFF; end  // D0-D1-D2-D3-D4-D5-D6-D7----
                        endcase end
                    else begin len_i = len_i - 8; pcie_tlp_rem   <= #(Tcq) 3'b000; s_axis_rq_tkeep <= #(Tcq) 8'hFF; end  // D0-D1-D2-D3-D4-D5-D6-D7--

                    if (len_i == 0) begin
                        s_axis_rq_tlast          <= #(Tcq) 1'b1;
                        TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY); end
                    else
                        TSK_TX_SYNCHRONIZE(0, 1, 0, `SYNC_RQ_RDY);
                end // for
            end  // if
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 137'b0;
            s_axis_rq_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MESSAGE_DATA


    /************************************************************
    Task : TSK_TX_IO_READ
    Inputs : Tag, Address
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a IO Read TLP
    *************************************************************/

    task TSK_TX_IO_READ;
        input    [7:0]    tag_;
        input    [31:0]   addr_;
        input    [3:0]    first_dw_be_;
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 8'h0F;
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                64'b0,                   // Parity Bit slot - 64bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                16'h0000,                // TPH Steering Tag - 16 bit
                                                2'b00,                   // TPH indirect Tag Enable - 2bit
                                                4'b0000,                 // TPH Type - 4 bit
                                                2'b00,                   // TPH Present - 2 bit
                                                1'b0,                    // Discontinue                                   
                                                4'b0000,                 // is_eop1_ptr
                                                4'b0000,                 // is_eop0_ptr
                                                2'b01,                   // is_eop[1:0]
                                                2'b10,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b01,                   // is_sop[1:0]
                                                2'b00,2'b00,             // Byte Lane number in case of Address Aligned mode - 4 bit
                                                4'b0000,4'b0000,     // Last BE of the Write Data -  8 bit
                                                4'b0000,first_dw_be_     // First BE of the Write Data - 8 bit
                                               };
 

            s_axis_rq_tdata          <= #(Tcq) {128'b0,         // *unused*                                           //256
                                                1'b0,           // Force ECRC                                         //128
                                                3'b000,         // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                3'b000,         // Traffic Class
                                                1'b1,           // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS,   // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                RP_BUS_DEV_FNS,   // Requester ID -- Used only when RID enable = 1    //96
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b0010,        // Req Type for IORd Req
                                                11'b1,          // DWORD Count
                                                32'b0,          // 32-bit Addressing. So, bits[63:32] = 0             //64
                                                addr_[31:2],    // IO read address 32-bits                            //32
                                                2'b00};         // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b000,         // Fmt for IO Read Req
                                                5'b00010,       // Type for IO Read Req
                                                1'b0,           // *reserved*
                                                3'b000,         // 3-bit Traffic Class
                                                1'b0,           // *reserved*
                                                1'b0,           // Attributes {ID Based Ordering}
                                                1'b0,           // *reserved*
                                                1'b0,           // TLP Processing Hints
                                                1'b0,           // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,          // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,          // Address Translation
                                                10'b1,          // DWORD Count                                        //32
                                                RP_BUS_DEV_FNS, // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                4'b0,           // Last DW Byte Enable
                                                first_dw_be_,   // First DW Byte Enable                               //64
                                                addr_[31:2],    // Address
                                                2'b00,          // *reserved*                                         //96
                                                32'b0,          // *unused*                                           //128
                                                128'b0          // *unused*                                           //256
                                               };
                                               
            pcie_tlp_rem             <= #(Tcq)  3'b101;
            set_malformed            <= #(Tcq)  1'b0;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 137'b0;
            s_axis_rq_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_IO_READ

    /************************************************************
    Task : TSK_TX_IO_WRITE
    Inputs : Tag, Address, Data
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a IO Write TLP
    *************************************************************/

    task TSK_TX_IO_WRITE;
        input    [7:0]    tag_;
        input    [31:0]   addr_;
        input    [3:0]    first_dw_be_;
        input    [31:0]   data_;
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 8'h1F;           // 2DW Descriptor for Memory Transactions alone
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                64'b0,                   // Parity Bit slot - 64bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                16'h0000,                // TPH Steering Tag - 16 bit
                                                2'b00,                   // TPH indirect Tag Enable - 2bit
                                                4'b0000,                 // TPH Type - 4 bit
                                                2'b00,                   // TPH Present - 2 bit
                                                1'b0,                    // Discontinue                                   
                                                4'b0000,                 // is_eop1_ptr
                                                4'b0000,                 // is_eop0_ptr
                                                2'b01,                   // is_eop[1:0]
                                                2'b10,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b01,                   // is_sop[1:0]
                                                2'b00,2'b00,             // Byte Lane number in case of Address Aligned mode - 4 bit
                                                4'b0000,4'b0000,     // Last BE of the Write Data -  8 bit
                                                4'b0000,first_dw_be_     // First BE of the Write Data - 8 bit
                                               };
 

            s_axis_rq_tdata          <= #(Tcq) {32'b0,          // *unused*
                                                32'b0,          // *unused*
                                                32'b0,          // *unused*
                                                data_,          // IO Write data on 5th DW
                                                1'b0,           // Force ECRC                                         //128
                                                3'b000,         // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                3'b000,         // Traffic Class
                                                1'b1,           // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS, // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                RP_BUS_DEV_FNS, // Requester ID -- Used only when RID enable = 1      //96
                                                (set_malformed ? 1'b1 : 1'b0),       // Poisoned Req
                                                4'b0011,        // Req Type for IOWr Req
                                                11'b1 ,         // DWORD Count
                                                32'b0,          // 32-bit Addressing. So, bits[63:32] = 0             //64
                                                addr_[31:2],    // IO Write address 32-bits                           //32
                                                2'b00};         // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b010,         // Fmt for IO Write Req
                                                5'b00010,       // Type for IO Write Req
                                                1'b0,           // *reserved*
                                                3'b000,         // 3-bit Traffic Class
                                                1'b0,           // *reserved*
                                                1'b0,           // Attributes {ID Based Ordering}
                                                1'b0,           // *reserved*
                                                1'b0,           // TLP Processing Hints
                                                1'b0,           // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,          // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,          // Address Translation
                                                10'b1,          // DWORD Count                                        //32
                                                RP_BUS_DEV_FNS, // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tag_), // Tag
                                                4'b0,           // last DW Byte Enable
                                                first_dw_be_,   // First DW Byte Enable                               //64
                                                addr_[31:2],    // Address
                                                2'b00,          // *reserved*                                         //96
                                                data_[7:0],     // IO Write Data
                                                data_[15:8],    // IO Write Data
                                                data_[23:16],   // IO Write Data
                                                data_[31:24],   // IO Write Data                                      //128
                                                128'b0          // *unused*                                           //256
                                               };

            pcie_tlp_rem             <= #(Tcq)  3'b100;
            set_malformed            <= #(Tcq)  1'b0;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 137'b0;
            s_axis_rq_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_IO_WRITE

    /************************************************************
    Task : TSK_TX_SYNCHRONIZE
    Inputs : None
    Outputs : None
    Description : Synchronize with tx clock and handshake signals
    *************************************************************/

    task TSK_TX_SYNCHRONIZE;
        input        first_;        // effectively sof
        input        active_;       // in pkt -- for pcie_tlp_data signaling only
        input        last_call_;    // eof
        input        tready_sw_;    // A switch to select CC or RQ tready

        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\

            @(posedge user_clk);
            if (tready_sw_ == `SYNC_CC_RDY) begin
                while (s_axis_cc_tready == 1'b0) begin
                    @(posedge user_clk);
                end
            end else begin // tready_sw_ == `SYNC_RQ_RDY
                while (s_axis_rq_tready == 1'b0) begin
                    @(posedge user_clk);
                end
            end
            //-----------------------------------------------------------------------\\
            if (active_ == 1'b1) begin
                // read data driven into memory
                board.RP.com_usrapp.TSK_READ_DATA_512(first_, last_call_,`TX_LOG,pcie_tlp_data,pcie_tlp_rem);
            end
            //-----------------------------------------------------------------------\\
            if (last_call_)
                 board.RP.com_usrapp.TSK_PARSE_FRAME(`TX_LOG);
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_SYNCHRONIZE

    /************************************************************
    Task : TSK_TX_BAR_READ
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Read 32,64 or IO Read TLP
                  requesting 1 dword
    *************************************************************/

    task TSK_TX_BAR_READ;

        input    [2:0]    bar_index;
        input    [31:0]   byte_offset;
        input    [7:0]    tag_;
        input    [2:0]    tc_;


        begin


          case(BAR_INIT_P_BAR_ENABLED[bar_index])
        2'b01 : // IO SPACE
            begin
              if (verbose) $display("[%t] : IOREAD, address = %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset));

                          TSK_TX_IO_READ(tag_, BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), 4'hF);
                end

        2'b10 : // MEM 32 SPACE
            begin

  if (verbose) $display("[%t] : MEMREAD32, address = %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset));
                           TSK_TX_MEMORY_READ_32(tag_, tc_, 10'd1,
                                                  BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), 4'h0, 4'hF);
                end
        2'b11 : // MEM 64 SPACE
                begin
                   if (verbose) $display("[%t] : MEMREAD64, address = %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset));
               TSK_TX_MEMORY_READ_64(tag_, tc_, 10'd1, {BAR_INIT_P_BAR[ii+1][31:0],
                                    BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset)}, 4'h0, 4'hF);


                    end
        default : begin
                    $display("Error case in task TSK_TX_BAR_READ");
                  end
      endcase

        end
    endtask // TSK_TX_BAR_READ



    /************************************************************
    Task : TSK_TX_BAR_WRITE
    Inputs : Bar Index, Byte Offset, Tag, Tc, 32 bit Data
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Write 32, 64, IO TLP with
                  32 bit data
    *************************************************************/

    task TSK_TX_BAR_WRITE;

        input    [2:0]    bar_index;
        input    [31:0]   byte_offset;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [31:0]   data_;

        begin

        case(BAR_INIT_P_BAR_ENABLED[bar_index])
        2'b01 : // IO SPACE
            begin

              if (verbose) $display("[%t] : IOWRITE, address = %x, Write Data %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), data_);
                          TSK_TX_IO_WRITE(tag_, BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), 4'hF, data_);

                end

        2'b10 : // MEM 32 SPACE
            begin

               DATA_STORE[0] = data_[7:0];
                           DATA_STORE[1] = data_[15:8];
                           DATA_STORE[2] = data_[23:16];
                           DATA_STORE[3] = data_[31:24];
               if (verbose) $display("[%t] : MEMWRITE32, address = %x, Write Data %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), data_);
                   TSK_TX_MEMORY_WRITE_32(tag_, tc_, 10'd1,
                                                  BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), 4'h0, 4'hF, 1'b0);

                end
        2'b11 : // MEM 64 SPACE
                begin

                   DATA_STORE[0] = data_[7:0];
                           DATA_STORE[1] = data_[15:8];
                           DATA_STORE[2] = data_[23:16];
                           DATA_STORE[3] = data_[31:24];
                   if (verbose) $display("[%t] : MEMWRITE64, address = %x, Write Data %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), data_);
                   TSK_TX_MEMORY_WRITE_64(tag_, tc_, 10'd1, {BAR_INIT_P_BAR[bar_index+1][31:0],
                                      BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset)}, 4'h0, 4'hF, 1'b0);



                    end
        default : begin
                    $display("Error case in task TSK_TX_BAR_WRITE");
                  end
    endcase


        end
    endtask // TSK_TX_BAR_WRITE

    /************************************************************
    Task : TSK_USR_DATA_SETUP_SEQ
    Inputs : None
    Outputs : None
    Description : Populates scratch pad data area with known good data.
    *************************************************************/

    task TSK_USR_DATA_SETUP_SEQ;
        integer        i_;
        begin
            for (i_ = 0; i_ <= 4095; i_ = i_ + 1) begin
                DATA_STORE[i_] = i_;
            end
            
            for (i_ = 0; i_ <= (2**(RP_BAR_SIZE+1))-1; i_ = i_ + 1) begin
                DATA_STORE_2[i_] = i_;
            end
            
        end
    endtask // TSK_USR_DATA_SETUP_SEQ

    /************************************************************
    Task : TSK_TX_CLK_EAT
    Inputs : None
    Outputs : None
    Description : Consume clocks.
    *************************************************************/

    task TSK_TX_CLK_EAT;
        input    [31:0]            clock_count;
        integer            i_;
        begin
            for (i_ = 0; i_ < clock_count; i_ = i_ + 1) begin

                @(posedge user_clk);

            end
        end
    endtask // TSK_TX_CLK_EAT

  /************************************************************
  Task: TSK_SIMULATION_TIMEOUT
  Description: Set simulation timeout value
  *************************************************************/
  task TSK_SIMULATION_TIMEOUT;
    input [31:0] timeout;
    begin
      force board.RP.rx_usrapp.sim_timeout = timeout;
    end
  endtask

    /************************************************************
    Task : TSK_SET_READ_DATA
    Inputs : Data
    Outputs : None
    Description : Called from common app. Common app hands read
                  data to usrapp_tx.
    *************************************************************/

    task TSK_SET_READ_DATA;

        input   [3:0]   be_;   // not implementing be's yet
        input   [63:0]  data_; // might need to change this to byte
        begin

          P_READ_DATA   = data_[31:0];
          P_READ_DATA_2 = data_[63:32];
          P_READ_DATA_VALID = 1;

        end
    endtask // TSK_SET_READ_DATA

    /************************************************************
    Task : TSK_WAIT_FOR_READ_DATA
    Inputs : None
    Outputs : Read data P_READ_DATA will be valid
    Description : Called from tx app. Common app hands read
                  data to usrapp_tx. This task must be executed
                  immediately following a call to
                  TSK_TX_TYPE0_CONFIGURATION_READ in order for the
                  read process to function correctly. Otherwise
                  there is a potential race condition with
                  P_READ_DATA_VALID.
    *************************************************************/

    task TSK_WAIT_FOR_READ_DATA;

                integer j;

        begin
                  j = 30;
                  P_READ_DATA_VALID = 0;
                  fork
                   while ((!P_READ_DATA_VALID) && (cpld_to == 0)) @(posedge user_clk);
                   begin // second process
                     while ((j > 0) && (!P_READ_DATA_VALID))
                       begin
                         TSK_TX_CLK_EAT(500);
                         j = j - 1;
                       end
                       if (!P_READ_DATA_VALID) begin
                        cpld_to = 1;
                        if (cpld_to_finish == 1) begin
                            $display("TEST FAIL: TIMEOUT ERROR in usrapp_tx:TSK_WAIT_FOR_READ_DATA. Completion data never received.");
                            $finish;
                          end
                        else
                            $display("TEST FAIL: TIMEOUT WARNING in usrapp_tx:TSK_WAIT_FOR_READ_DATA. Completion data never received.");

                     end
                   end

          join

        end
    endtask // TSK_WAIT_FOR_READ_DATA

    /************************************************************
    Function : TSK_DISPLAY_PCIE_MAP
    Inputs : none
    Outputs : none
    Description : Displays the Memory Manager's P_MAP calculations
                  based on range values read from PCI_E device.
    *************************************************************/

        task TSK_DISPLAY_PCIE_MAP;

           reg[2:0] ii;

           begin

             for (ii=0; ii <= 6; ii = ii + 1) begin
                 if (ii !=6) begin

                   $display("\tBAR %x: VALUE = %x RANGE = %x TYPE = %s", ii, BAR_INIT_P_BAR[ii][31:0],
                     BAR_INIT_P_BAR_RANGE[ii], BAR_INIT_MESSAGE[BAR_INIT_P_BAR_ENABLED[ii]]);

                 end
                 else begin

                   $display("\tEROM : VALUE = %x RANGE = %x TYPE = %s", BAR_INIT_P_BAR[6][31:0],
                     BAR_INIT_P_BAR_RANGE[6], BAR_INIT_MESSAGE[BAR_INIT_P_BAR_ENABLED[6]]);

                 end
             end

           end

        endtask

    /************************************************************
    Task : TSK_BUILD_PCIE_MAP
    Inputs :
    Outputs :
    Description : Looks at range values read from config space and
                  builds corresponding mem/io map
    *************************************************************/

    task TSK_BUILD_PCIE_MAP;

        reg[2:0] ii;

        begin

                  $display("[%t] PCI EXPRESS BAR MEMORY/IO MAPPING PROCESS BEGUN...",$realtime);

              // handle bars 0-6 (including erom)
              for (ii = 0; ii <= 6; ii = ii + 1) begin

                  if (BAR_INIT_P_BAR_RANGE[ii] != 32'h0000_0000) begin

                     if ((ii != 6) && (BAR_INIT_P_BAR_RANGE[ii] & 32'h0000_0001)) begin // if not erom and io bit set

                        // bar is io mapped
                        NUMBER_OF_IO_BARS = NUMBER_OF_IO_BARS + 1;

                        //if (pio_check_design && (~BAR_ENABLED[ii])) begin
                        if (pio_check_design && (NUMBER_OF_IO_BARS > 6)) begin
                           $display("[%t] Testbench will disable BAR %x",$realtime, ii);
                           BAR_INIT_P_BAR_ENABLED[ii] = 2'h0; // disable BAR
                        end
                        else begin
                           BAR_INIT_P_BAR_ENABLED[ii] = 2'h1;
                           $display("[%t] Testbench is enabling IO BAR %x",$realtime, ii);
                        end //BAR_INIT_P_BAR_ENABLED[ii] = 2'h1;

                        if (!OUT_OF_IO) begin

                           // We need to calculate where the next BAR should start based on the BAR's range
                                  BAR_INIT_TEMP = BAR_INIT_P_IO_START & {1'b1,(BAR_INIT_P_BAR_RANGE[ii] & 32'hffff_fff0)};

                                  if (BAR_INIT_TEMP < BAR_INIT_P_IO_START) begin
                                     // Current BAR_INIT_P_IO_START is NOT correct start for new base
                                      BAR_INIT_P_BAR[ii] = BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_32(ii);
                                      BAR_INIT_P_IO_START = BAR_INIT_P_BAR[ii] + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                  end
                                  else begin

                                     // Initial BAR case and Current BAR_INIT_P_IO_START is correct start for new base
                                      BAR_INIT_P_BAR[ii] = BAR_INIT_P_IO_START;
                                      BAR_INIT_P_IO_START = BAR_INIT_P_IO_START + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                  end

                                  OUT_OF_IO = BAR_INIT_P_BAR[ii][32];

                              if (OUT_OF_IO) begin

                                 $display("\tOut of PCI EXPRESS IO SPACE due to BAR %x", ii);

                              end

                        end
                          else begin

                               $display("\tOut of PCI EXPRESS IO SPACE due to BAR %x", ii);

                          end



                     end // bar is io mapped

                     else begin

                        // bar is mem mapped
                        if ((ii != 5) && (BAR_INIT_P_BAR_RANGE[ii] & 32'h0000_0004)) begin

                           // bar is mem64 mapped - memManager is not handling out of 64bit memory
                               NUMBER_OF_MEM64_BARS = NUMBER_OF_MEM64_BARS + 1;

                           //if (pio_check_design && (~BAR_ENABLED[ii])) begin
                           if (pio_check_design && (NUMBER_OF_MEM64_BARS > 6)) begin
                              $display("[%t] Testbench will disable BAR %x",$realtime, ii);
                              BAR_INIT_P_BAR_ENABLED[ii] = 2'h0; // disable BAR
                           end
                           else begin
                              BAR_INIT_P_BAR_ENABLED[ii] = 2'h3; // bar is mem64 mapped
                              $display("[%t] Testbench is enabling MEM64 BAR %x",$realtime, ii);
                           end 


                           if ( (BAR_INIT_P_BAR_RANGE[ii] & 32'hFFFF_FFF0) == 32'h0000_0000) begin

                              // Mem64 space has range larger than 2 Gigabytes

                              // calculate where the next BAR should start based on the BAR's range
                                  BAR_INIT_TEMP = BAR_INIT_P_MEM64_HI_START & BAR_INIT_P_BAR_RANGE[ii+1];

                                  if (BAR_INIT_TEMP < BAR_INIT_P_MEM64_HI_START) begin

                                     // Current MEM32_START is NOT correct start for new base
                                     BAR_INIT_P_BAR[ii+1] =      BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_HI32(ii+1);
                                     BAR_INIT_P_BAR[ii] =        32'h0000_0000;
                                     BAR_INIT_P_MEM64_HI_START = BAR_INIT_P_BAR[ii+1] + FNC_CONVERT_RANGE_TO_SIZE_HI32(ii+1);
                                     BAR_INIT_P_MEM64_LO_START = 32'h0000_0000;

                                  end
                                  else begin

                                     // Initial BAR case and Current MEM32_START is correct start for new base
                                     BAR_INIT_P_BAR[ii] =        32'h0000_0000;
                                     BAR_INIT_P_BAR[ii+1] =      BAR_INIT_P_MEM64_HI_START;
                                     BAR_INIT_P_MEM64_HI_START = BAR_INIT_P_MEM64_HI_START + FNC_CONVERT_RANGE_TO_SIZE_HI32(ii+1);

                                  end

                           end
                           else begin

                              // Mem64 space has range less than/equal 2 Gigabytes

                              // calculate where the next BAR should start based on the BAR's range
                                  BAR_INIT_TEMP = BAR_INIT_P_MEM64_LO_START & (BAR_INIT_P_BAR_RANGE[ii] & 32'hffff_fff0);

                                  if (BAR_INIT_TEMP < BAR_INIT_P_MEM64_LO_START) begin

                                     // Current MEM32_START is NOT correct start for new base
                                     BAR_INIT_P_BAR[ii] =        BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_32(ii);
                                     BAR_INIT_P_BAR[ii+1] =      BAR_INIT_P_MEM64_HI_START;
                                     BAR_INIT_P_MEM64_LO_START = BAR_INIT_P_BAR[ii] + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                  end
                                  else begin

                                     // Initial BAR case and Current MEM32_START is correct start for new base
                                     BAR_INIT_P_BAR[ii] =        BAR_INIT_P_MEM64_LO_START;
                                     BAR_INIT_P_BAR[ii+1] =      BAR_INIT_P_MEM64_HI_START;
                                     BAR_INIT_P_MEM64_LO_START = BAR_INIT_P_MEM64_LO_START + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                  end

                           end

                              // skip over the next bar since it is being used by the 64bit bar
                              ii = ii + 1;

                        end
                        else begin

                           if ( (ii != 6) || ((ii == 6) && (BAR_INIT_P_BAR_RANGE[ii] & 32'h0000_0001)) ) begin
                              // handling general mem32 case and erom case

                              // bar is mem32 mapped
                              if (ii != 6) begin

                                 NUMBER_OF_MEM32_BARS = NUMBER_OF_MEM32_BARS + 1; // not counting erom space

                                 //if (pio_check_design && (~BAR_ENABLED[ii])) begin
                                 if (pio_check_design && (NUMBER_OF_MEM32_BARS > 6)) begin
                                    $display("[%t] Testbench will disable BAR %x",$realtime, ii);
                                    BAR_INIT_P_BAR_ENABLED[ii] = 2'h0; // disable BAR
                                 end
                                 else  begin
                                    BAR_INIT_P_BAR_ENABLED[ii] = 2'h2; // bar is mem32 mapped
                                    $display("[%t] Testbench is enabling MEM32 BAR %x",$realtime, ii);
                                 end
                              end

                              else BAR_INIT_P_BAR_ENABLED[ii] = 2'h2; // erom bar is mem32 mapped

                              if (!OUT_OF_LO_MEM) begin

                                     // We need to calculate where the next BAR should start based on the BAR's range
                                     BAR_INIT_TEMP = BAR_INIT_P_MEM32_START & {1'b1,(BAR_INIT_P_BAR_RANGE[ii] & 32'hffff_fff0)};

                                     if (BAR_INIT_TEMP < BAR_INIT_P_MEM32_START) begin

                                         // Current MEM32_START is NOT correct start for new base
                                         BAR_INIT_P_BAR[ii] =     BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_32(ii);
                                         BAR_INIT_P_MEM32_START = BAR_INIT_P_BAR[ii] + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                     end
                                     else begin

                                         // Initial BAR case and Current MEM32_START is correct start for new base
                                         BAR_INIT_P_BAR[ii] =     BAR_INIT_P_MEM32_START;
                                         BAR_INIT_P_MEM32_START = BAR_INIT_P_MEM32_START + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                     end


     if (ii == 6) begin

        // make sure to set enable bit if we are mapping the erom space

        BAR_INIT_P_BAR[ii] = BAR_INIT_P_BAR[ii] | 33'h1;


     end


                                 OUT_OF_LO_MEM = BAR_INIT_P_BAR[ii][32];

                                 if (OUT_OF_LO_MEM) begin

                                    $display("\tOut of PCI EXPRESS MEMORY 32 SPACE due to BAR %x", ii);

                                 end

                              end
                              else begin

                                     $display("\tOut of PCI EXPRESS MEMORY 32 SPACE due to BAR %x", ii);

                              end

                           end

                        end

                     end

                  end

              end


                  if ( (OUT_OF_IO) | (OUT_OF_LO_MEM) | (OUT_OF_HI_MEM)) begin
                     TSK_DISPLAY_PCIE_MAP;
                     $display("ERROR: Ending simulation: Memory Manager is out of memory/IO to allocate to PCI Express device");
                     $finish;

                  end


        end

    endtask // TSK_BUILD_PCIE_MAP


   /************************************************************
        Task : TSK_BAR_SCAN
        Inputs : None
        Outputs : None
        Description : Scans PCI core's configuration registers.
   *************************************************************/

    task TSK_BAR_SCAN;
       begin

        //--------------------------------------------------------------------------
        // Write PCI_MASK to bar's space via PCIe fabric interface to find range
        //--------------------------------------------------------------------------

        P_ADDRESS_MASK          = 32'hffff_ffff;
    DEFAULT_TAG         = 0;
    DEFAULT_TC          = 0;


        $display("[%t] : Inspecting Core Configuration Space...", $realtime);

    // Determine Range for BAR0

    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h10, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR0 Range

    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h10, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
        BAR_INIT_P_BAR_RANGE[0] = P_READ_DATA;


    // Determine Range for BAR1

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h14, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR1 Range

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h14, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
        BAR_INIT_P_BAR_RANGE[1] = P_READ_DATA;


    // Determine Range for BAR2

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h18, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);


    // Read BAR2 Range

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h18, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
        BAR_INIT_P_BAR_RANGE[2] = P_READ_DATA;


    // Determine Range for BAR3

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h1C, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR3 Range

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h1C, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
        BAR_INIT_P_BAR_RANGE[3] = P_READ_DATA;


    // Determine Range for BAR4

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h20, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR4 Range

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h20, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
        BAR_INIT_P_BAR_RANGE[4] = P_READ_DATA;


    // Determine Range for BAR5

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h24, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR5 Range

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h24, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
        BAR_INIT_P_BAR_RANGE[5] = P_READ_DATA;


    // Determine Range for Expansion ROM BAR

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h30, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read Expansion ROM BAR Range

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h30, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
        BAR_INIT_P_BAR_RANGE[6] = P_READ_DATA;

       end
    endtask // TSK_BAR_SCAN


   /************************************************************
        Task : TSK_BAR_PROGRAM
        Inputs : None
        Outputs : None
        Description : Program's PCI core's configuration registers.
   *************************************************************/

    task TSK_BAR_PROGRAM;
       begin

        //--------------------------------------------------------------------------
        // Write core configuration space via PCIe fabric interface
        //--------------------------------------------------------------------------

        DEFAULT_TAG     = 0;

        $display("[%t] : Setting Core Configuration Space...", $realtime);

    // Program BAR0

    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h10, BAR_INIT_P_BAR[0][31:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program BAR1

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h14, BAR_INIT_P_BAR[1][31:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program BAR2

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h18, BAR_INIT_P_BAR[2][31:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program BAR3

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h1C, BAR_INIT_P_BAR[3][31:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program BAR4

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h20, BAR_INIT_P_BAR[4][31:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program BAR5

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h24, BAR_INIT_P_BAR[5][31:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program Expansion ROM BAR

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h30, BAR_INIT_P_BAR[6][31:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program PCI Command Register

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h04, 32'h00000007, 4'h1);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program PCIe Device Control Register

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, DEV_CTRL_REG_ADDR, 32'h0000005f, 4'h1);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(1000);

       end
    endtask // TSK_BAR_PROGRAM


   /************************************************************
        Task : TSK_BAR_INIT
        Inputs : None
        Outputs : None
        Description : Initialize PCI core based on core's configuration.
   *************************************************************/

    task TSK_BAR_INIT;
       begin

        TSK_BAR_SCAN;

        TSK_BUILD_PCIE_MAP;

        TSK_DISPLAY_PCIE_MAP;

        TSK_BAR_PROGRAM;

       end
    endtask // TSK_BAR_INIT



   /************************************************************
        Task : TSK_TX_READBACK_CONFIG
        Inputs : None
        Outputs : None
        Description : Read core configuration space via PCIe fabric interface
   *************************************************************/

    task TSK_TX_READBACK_CONFIG;
       begin


        //--------------------------------------------------------------------------
        // Read core configuration space via PCIe fabric interface
        //--------------------------------------------------------------------------

        $display("[%t] : Reading Core Configuration Space...", $realtime);

    // Read BAR0

    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h10, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR1

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h14, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR2

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h18, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR3

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h1C, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR4

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h20, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR5

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h24, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read Expansion ROM BAR

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h30, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read PCI Command Register

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h04, 4'h1);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read PCIe Device Control Register

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, DEV_CTRL_REG_ADDR, 4'h1);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(1000);

      end
    endtask // TSK_TX_READBACK_CONFIG


   /************************************************************
        Task : TSK_CFG_READBACK_CONFIG
        Inputs : None
        Outputs : None
        Description : Read core configuration space via CFG interface
   *************************************************************/

    task TSK_CFG_READBACK_CONFIG;
       begin


    //--------------------------------------------------------------------------
    // Read core configuration space via configuration (host) interface
    //--------------------------------------------------------------------------

    $display("[%t] : Reading Local Configuration Space via CFG interface...", $realtime);

    CFG_DWADDR = 10'h0;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h4;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h5;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h6;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h7;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h8;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h9;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'hc;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h17;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h18;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h19;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h1a;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

      end
    endtask // TSK_CFG_READBACK_CONFIG



/************************************************************
        Task : TSK_MEM_TEST_DATA_BUS
        Inputs : bar_index
        Outputs : None
        Description : Test the data bus wiring in a specific memory
               by executing a walking 1's test at a set address
               within that region.
*************************************************************/

task TSK_MEM_TEST_DATA_BUS;
   input [2:0]  bar_index;
   reg [31:0] pattern;
   reg success;
   begin

    $display("[%t] : Performing Memory data test to address %x", $realtime, BAR_INIT_P_BAR[bar_index][31:0]);
    success = 1; // assume success
    // Perform a walking 1's test at the given address.
    for (pattern = 1; pattern != 0; pattern = pattern << 1)
      begin
        // Write the test pattern. *address = pattern;pio_memTestAddrBus_test1

        TSK_TX_BAR_WRITE(bar_index, 32'h0, DEFAULT_TAG, DEFAULT_TC, pattern);
        TSK_TX_CLK_EAT(10);
    DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_BAR_READ(bar_index, 32'h0, DEFAULT_TAG, DEFAULT_TC);


        TSK_WAIT_FOR_READ_DATA;
        if  (P_READ_DATA != pattern)
           begin
             $display("[%t] : Data Error Mismatch, Address: %x Write Data %x != Read Data %x", $realtime,
                              BAR_INIT_P_BAR[bar_index][31:0], pattern, P_READ_DATA);
             success = 0;
             $finish;
           end
        else
           begin
             $display("[%t] : Address: %x Write Data: %x successfully received", $realtime,
                              BAR_INIT_P_BAR[bar_index][31:0], P_READ_DATA);
           end
        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;

      end  // for loop
    if (success == 1)
        $display("[%t] : TSK_MEM_TEST_DATA_BUS successfully completed", $realtime);
    else
        $display("[%t] : TSK_MEM_TEST_DATA_BUS completed with errors", $realtime);

   end

endtask   // TSK_MEM_TEST_DATA_BUS



/************************************************************
        Task : TSK_MEM_TEST_ADDR_BUS
        Inputs : bar_index, nBytes
        Outputs : None
        Description : Test the address bus wiring in a specific memory by
               performing a walking 1's test on the relevant bits
               of the address and checking for multiple writes/aliasing.
               This test will find single-bit address failures such as stuck
               -high, stuck-low, and shorted pins.

*************************************************************/

task TSK_MEM_TEST_ADDR_BUS;
   input [2:0] bar_index;
   input [31:0] nBytes;
   reg [31:0] pattern;
   reg [31:0] antipattern;
   reg [31:0] addressMask;
   reg [31:0] offset;
   reg [31:0] testOffset;
   reg success;
   reg stuckHi_success;
   reg stuckLo_success;
   begin

    $display("[%t] : Performing Memory address test to address %x", $realtime, BAR_INIT_P_BAR[bar_index][31:0]);
    success = 1; // assume success
    stuckHi_success = 1;
    stuckLo_success = 1;

    pattern =     32'hAAAAAAAA;
    antipattern = 32'h55555555;

    // divide by 4 because the block RAMS we are testing are 32bit wide
    // and therefore the low two bits are not meaningful for addressing purposes
    // for this test.
    addressMask = (nBytes/4 - 1);

    $display("[%t] : Checking for address bits stuck high", $realtime);
    // Write the default pattern at each of the power-of-two offsets.
    for (offset = 1; (offset & addressMask) != 0; offset = offset << 1)
      begin

        verbose = 1;

        // baseAddress[offset] = pattern
        TSK_TX_BAR_WRITE(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC, pattern);

    TSK_TX_CLK_EAT(10);
    DEFAULT_TAG = DEFAULT_TAG + 1;
      end



    // Check for address bits stuck high.
    // It should be noted that since the write address and read address pins are different
    // for the block RAMs used in the PIO design, the stuck high test will only catch an error if both
    // read and write addresses are both stuck hi. Otherwise the remaining portion of the tests
    // will catch if only one of the addresses are stuck hi.

    testOffset = 0;

    // baseAddress[testOffset] = antipattern;
    TSK_TX_BAR_WRITE(bar_index, 4*testOffset, DEFAULT_TAG, DEFAULT_TC, antipattern);


    TSK_TX_CLK_EAT(10);
    DEFAULT_TAG = DEFAULT_TAG + 1;


    for (offset = 1; (offset & addressMask) != 0; offset = offset << 1)
      begin


        TSK_TX_BAR_READ(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC);

        TSK_WAIT_FOR_READ_DATA;
        if  (P_READ_DATA != pattern)
           begin
             $display("[%t] : Error: Pattern Mismatch, Address = %x, Write Data %x != Read Data %x",
                     $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*offset), pattern, P_READ_DATA);
             stuckHi_success = 0;
             success = 0;
             $finish;
           end
        else
           begin
             $display("[%t] : Pattern Match: Address %x Data: %x successfully received",
                      $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*offset), P_READ_DATA);
           end
        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;

     end


    if (stuckHi_success == 1)
        $display("[%t] : Stuck Hi Address Test successfully completed", $realtime);
    else
        $display("[%t] : Error: Stuck Hi Address Test failed", $realtime);


    $display("[%t] : Checking for address bits stuck low or shorted", $realtime);

    //baseAddress[testOffset] = pattern;

    TSK_TX_BAR_WRITE(bar_index, 4*testOffset, DEFAULT_TAG, DEFAULT_TC, pattern);


    TSK_TX_CLK_EAT(10);
    DEFAULT_TAG = DEFAULT_TAG + 1;

    // Check for address bits stuck low or shorted.
    for (testOffset = 1; (testOffset & addressMask) != 0; testOffset = testOffset << 1)
      begin

        //baseAddress[testOffset] = antipattern;
        TSK_TX_BAR_WRITE(bar_index, 4*testOffset, DEFAULT_TAG, DEFAULT_TC, antipattern);

        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;

        TSK_TX_BAR_READ(bar_index, 32'h0, DEFAULT_TAG, DEFAULT_TC);

        TSK_WAIT_FOR_READ_DATA;
        if  (P_READ_DATA != pattern)      // if (baseAddress[0] != pattern)

           begin
             $display("[%t] : Error: Pattern Mismatch, Address = %x, Write Data %x != Read Data %x",
                                                 $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*0), pattern, P_READ_DATA);
             stuckLo_success = 0;
             success = 0;
             $finish;
           end
        else
           begin
             $display("[%t] : Pattern Match: Address %x Data: %x successfully received",
                      $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*offset), P_READ_DATA);
           end
        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;


        for (offset = 1; (offset & addressMask) != 0; offset = offset << 1)
           begin

             TSK_TX_BAR_READ(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC);

             TSK_WAIT_FOR_READ_DATA;
             // if ((baseAddress[offset] != pattern) && (offset != testOffset))
             if  ((P_READ_DATA != pattern) && (offset != testOffset))
                begin
                  $display("[%t] : Error: Pattern Mismatch, Address = %x, Write Data %x != Read Data %x",
                                                 $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*offset),
                                                 pattern, P_READ_DATA);
                  stuckLo_success = 0;
                  success = 0;
                  $finish;
                end
             else
                begin
                  $display("[%t] : Pattern Match: Address %x Data: %x successfully received",
                                              $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*offset),
                                              P_READ_DATA);
                end
             TSK_TX_CLK_EAT(10);
             DEFAULT_TAG = DEFAULT_TAG + 1;

          end

        // baseAddress[testOffset] = pattern;


        TSK_TX_BAR_WRITE(bar_index, 4*testOffset, DEFAULT_TAG, DEFAULT_TC, pattern);


        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;

      end

    if (stuckLo_success == 1)
        $display("[%t] : Stuck Low Address Test successfully completed", $realtime);
    else
        $display("[%t] : Error: Stuck Low Address Test failed", $realtime);


    if (success == 1)
        $display("[%t] : TSK_MEM_TEST_ADDR_BUS successfully completed", $realtime);
    else
        $display("[%t] : TSK_MEM_TEST_ADDR_BUS completed with errors", $realtime);

   end

endtask   // TSK_MEM_TEST_ADDR_BUS



/************************************************************
        Task : TSK_MEM_TEST_DEVICE
        Inputs : bar_index, nBytes
        Outputs : None
 *      Description: Test the integrity of a physical memory device by
 *              performing an increment/decrement test over the
 *              entire region.  In the process every storage bit
 *              in the device is tested as a zero and a one.  The
 *              bar_index and the size of the region are
 *              selected by the caller.
*************************************************************/

task TSK_MEM_TEST_DEVICE;
   input [2:0] bar_index;
   input [31:0] nBytes;
   reg [31:0] pattern;
   reg [31:0] antipattern;
   reg [31:0] offset;
   reg [31:0] nWords;
   reg success;
   begin

    $display("[%t] : Performing Memory device test to address %x", $realtime, BAR_INIT_P_BAR[bar_index][31:0]);
    success = 1; // assume success

    nWords = nBytes / 4;

    pattern = 1;
    // Fill memory with a known pattern.
    for (offset = 0; offset < nWords; offset = offset + 1)
    begin

        verbose = 1;

        //baseAddress[offset] = pattern;
        TSK_TX_BAR_WRITE(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC, pattern);

        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        pattern = pattern + 1;
    end


   pattern = 1;
    // Check each location and invert it for the second pass.
    for (offset = 0; offset < nWords; offset = offset + 1)
    begin


        TSK_TX_BAR_READ(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC);

        TSK_WAIT_FOR_READ_DATA;
        DEFAULT_TAG = DEFAULT_TAG + 1;
        //if (baseAddress[offset] != pattern)
        if  (P_READ_DATA != pattern)
        begin
           $display("[%t] : Error: Pattern Mismatch, Address = %x, Write Data %x != Read Data %x", $realtime,
                            BAR_INIT_P_BAR[bar_index][31:0]+(4*offset), pattern, P_READ_DATA);
           success = 0;
           $finish;
        end


        antipattern = ~pattern;

        //baseAddress[offset] = antipattern;
        TSK_TX_BAR_WRITE(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC, antipattern);

        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;


       pattern = pattern + 1;
    end

    pattern = 1;
    // Check each location for the inverted pattern
    for (offset = 0; offset < nWords; offset = offset + 1)
    begin
        antipattern = ~pattern;

        TSK_TX_BAR_READ(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC);

        TSK_WAIT_FOR_READ_DATA;
        DEFAULT_TAG = DEFAULT_TAG + 1;
        //if (baseAddress[offset] != pattern)
        if  (P_READ_DATA != antipattern)

        begin
           $display("[%t] : Error: Pattern Mismatch, Address = %x, Write Data %x != Read Data %x", $realtime,
                            BAR_INIT_P_BAR[bar_index][31:0]+(4*offset), pattern, P_READ_DATA);
           success = 0;
           $finish;
        end
        pattern = pattern + 1;
    end

     if (success == 1)
        $display("[%t] : TSK_MEM_TEST_DEVICE successfully completed", $realtime);
    else
        $display("[%t] : TSK_MEM_TEST_DEVICE completed with errors", $realtime);

   end

endtask   // TSK_MEM_TEST_DEVICE




        /************************************************************
    Function : FNC_CONVERT_RANGE_TO_SIZE_32
    Inputs : BAR index for 32 bit BAR
    Outputs : 32 bit BAR size
    Description : Called from tx app. Note that the smallest range
                  supported by this function is 16 bytes.
    *************************************************************/

    function [31:0] FNC_CONVERT_RANGE_TO_SIZE_32;
                input [31:0] bar_index;
                reg   [32:0] return_value;
        begin
                  case (BAR_INIT_P_BAR_RANGE[bar_index] & 32'hFFFF_FFF0) // AND off control bits
                    32'hFFFF_FFF0 : return_value = 33'h0000_0010;
                    32'hFFFF_FFE0 : return_value = 33'h0000_0020;
                    32'hFFFF_FFC0 : return_value = 33'h0000_0040;
                    32'hFFFF_FF80 : return_value = 33'h0000_0080;
                    32'hFFFF_FF00 : return_value = 33'h0000_0100;
                    32'hFFFF_FE00 : return_value = 33'h0000_0200;
                    32'hFFFF_FC00 : return_value = 33'h0000_0400;
                    32'hFFFF_F800 : return_value = 33'h0000_0800;
                    32'hFFFF_F000 : return_value = 33'h0000_1000;
                    32'hFFFF_E000 : return_value = 33'h0000_2000;
                    32'hFFFF_C000 : return_value = 33'h0000_4000;
                    32'hFFFF_8000 : return_value = 33'h0000_8000;
                    32'hFFFF_0000 : return_value = 33'h0001_0000;
                    32'hFFFE_0000 : return_value = 33'h0002_0000;
                    32'hFFFC_0000 : return_value = 33'h0004_0000;
                    32'hFFF8_0000 : return_value = 33'h0008_0000;
                    32'hFFF0_0000 : return_value = 33'h0010_0000;
                    32'hFFE0_0000 : return_value = 33'h0020_0000;
                    32'hFFC0_0000 : return_value = 33'h0040_0000;
                    32'hFF80_0000 : return_value = 33'h0080_0000;
                    32'hFF00_0000 : return_value = 33'h0100_0000;
                    32'hFE00_0000 : return_value = 33'h0200_0000;
                    32'hFC00_0000 : return_value = 33'h0400_0000;
                    32'hF800_0000 : return_value = 33'h0800_0000;
                    32'hF000_0000 : return_value = 33'h1000_0000;
                    32'hE000_0000 : return_value = 33'h2000_0000;
                    32'hC000_0000 : return_value = 33'h4000_0000;
                    32'h8000_0000 : return_value = 33'h8000_0000;
                    default :      return_value = 33'h0000_0000;
                  endcase

                  FNC_CONVERT_RANGE_TO_SIZE_32 = return_value;
        end
    endfunction // FNC_CONVERT_RANGE_TO_SIZE_32



    /************************************************************
    Function : FNC_CONVERT_RANGE_TO_SIZE_HI32
    Inputs : BAR index for upper 32 bit BAR of 64 bit address
    Outputs : upper 32 bit BAR size
    Description : Called from tx app.
    *************************************************************/

    function [31:0] FNC_CONVERT_RANGE_TO_SIZE_HI32;
                input [31:0] bar_index;
                reg   [32:0] return_value;
        begin
                  case (BAR_INIT_P_BAR_RANGE[bar_index])
                    32'hFFFF_FFFF : return_value = 33'h00000_0001;
                    32'hFFFF_FFFE : return_value = 33'h00000_0002;
                    32'hFFFF_FFFC : return_value = 33'h00000_0004;
                    32'hFFFF_FFF8 : return_value = 33'h00000_0008;
                    32'hFFFF_FFF0 : return_value = 33'h00000_0010;
                    32'hFFFF_FFE0 : return_value = 33'h00000_0020;
                    32'hFFFF_FFC0 : return_value = 33'h00000_0040;
                    32'hFFFF_FF80 : return_value = 33'h00000_0080;
                    32'hFFFF_FF00 : return_value = 33'h00000_0100;
                    32'hFFFF_FE00 : return_value = 33'h00000_0200;
                    32'hFFFF_FC00 : return_value = 33'h00000_0400;
                    32'hFFFF_F800 : return_value = 33'h00000_0800;
                    32'hFFFF_F000 : return_value = 33'h00000_1000;
                    32'hFFFF_E000 : return_value = 33'h00000_2000;
                    32'hFFFF_C000 : return_value = 33'h00000_4000;
                    32'hFFFF_8000 : return_value = 33'h00000_8000;
                    32'hFFFF_0000 : return_value = 33'h00001_0000;
                    32'hFFFE_0000 : return_value = 33'h00002_0000;
                    32'hFFFC_0000 : return_value = 33'h00004_0000;
                    32'hFFF8_0000 : return_value = 33'h00008_0000;
                    32'hFFF0_0000 : return_value = 33'h00010_0000;
                    32'hFFE0_0000 : return_value = 33'h00020_0000;
                    32'hFFC0_0000 : return_value = 33'h00040_0000;
                    32'hFF80_0000 : return_value = 33'h00080_0000;
                    32'hFF00_0000 : return_value = 33'h00100_0000;
                    32'hFE00_0000 : return_value = 33'h00200_0000;
                    32'hFC00_0000 : return_value = 33'h00400_0000;
                    32'hF800_0000 : return_value = 33'h00800_0000;
                    32'hF000_0000 : return_value = 33'h01000_0000;
                    32'hE000_0000 : return_value = 33'h02000_0000;
                    32'hC000_0000 : return_value = 33'h04000_0000;
                    32'h8000_0000 : return_value = 33'h08000_0000;
                    default :      return_value = 33'h00000_0000;
                  endcase

                  FNC_CONVERT_RANGE_TO_SIZE_HI32 = return_value;
        end
    endfunction // FNC_CONVERT_RANGE_TO_SIZE_HI32


/************************************************************
Task : TSK_SPEED_CHANGE
Inputs : 4 bits Link Control 2 Register Target Link Speed value
Outputs : None
Description : Change Link Speed amd Retrain Link
*************************************************************/

task TSK_SPEED_CHANGE;

   input    [3:0]    target_link_speed;

   begin
       board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(32'h3c, {28'h0,target_link_speed}, 4'h1);
       board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(32'h34, 32'h00810020, 4'hF);
       wait(board.RP.pcie_4_0_rport.cfg_ltssm_state == 6'h0B);
       wait(board.RP.pcie_4_0_rport.cfg_ltssm_state == 6'h10);
       wait (board.RP.pcie_4_0_rport.user_lnk_up == 1);
       board.RP.tx_usrapp.TSK_TX_CLK_EAT(100);
       TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, LINK_CTRL_REG_ADDR, 4'hF);
       DEFAULT_TAG = DEFAULT_TAG + 1;
       TSK_WAIT_FOR_READ_DATA;
     
       if  (P_READ_DATA[19:16] == target_link_speed) begin
          if (P_READ_DATA[19:16] == 1)
             $display("[%t] :    Check Max Link Speed = 2.5GT/s", $realtime);
          else if(P_READ_DATA[19:16] == 2)
             $display("[%t] :    Check Max Link Speed = 5.0GT/s", $realtime);
          else if(P_READ_DATA[19:16] == 3)
             $display("[%t] :    Check Max Link Speed = 8.0GT/s", $realtime);
        end else
          $display("[%t] : Data Error Mismatch -Speed Test Failed", $realtime);

   end
endtask // TSK_SPEED_CHANGE

/************************************************************
Task : TSK_XDMA_REG_READ
Inputs : input BAR1 address
Outputs : None
Description : Read XDMA configuration register
*************************************************************/
task TSK_XDMA_REG_READ;
  input [15:0] read_addr;

begin
                        board.RP.tx_usrapp.P_READ_DATA = 32'hffff_ffff;
                          fork
                             if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[board.RP.tx_usrapp.xdma_bar] == 2'b10) begin
                                board.RP.tx_usrapp.TSK_TX_MEMORY_READ_32(board.RP.tx_usrapp.DEFAULT_TAG,
                                    board.RP.tx_usrapp.DEFAULT_TC, 11'd1,
                                    board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.xdma_bar][31:0]+read_addr[15:0], 4'h0, 4'hF);
                             end else if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[board.RP.tx_usrapp.xdma_bar] == 2'b11) begin                  
                                board.RP.tx_usrapp.TSK_TX_MEMORY_READ_64(board.RP.tx_usrapp.DEFAULT_TAG,
                                    board.RP.tx_usrapp.DEFAULT_TC, 11'd1,{board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.xdma_bar+1][31:0],
                                    board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.xdma_bar][31:0]+read_addr[15:0]}, 4'h0, 4'hF);
                             end
                             board.RP.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                          join

                          board.RP.tx_usrapp.TSK_TX_CLK_EAT(10);
                          board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;
  $display ("[%t] : Data read %h from Address %h",$realtime , board.RP.tx_usrapp.P_READ_DATA, read_addr);

end

endtask

/************************************************************
Task : TSK_USR_BAR_REG_READ
Inputs : input BAR1 address
Outputs : None
Description : Read XDMA configuration register
*************************************************************/
   
task TSK_USR_BAR_REG_READ;
  input [15:0] read_addr;

begin
                        board.RP.tx_usrapp.P_READ_DATA = 32'hffff_ffff;
                          fork
                             if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[user_bar] == 2'b10) begin
                                board.RP.tx_usrapp.TSK_TX_MEMORY_READ_32(board.RP.tx_usrapp.DEFAULT_TAG,
                                    board.RP.tx_usrapp.DEFAULT_TC, 11'd1,
                                    board.RP.tx_usrapp.BAR_INIT_P_BAR[user_bar][31:0]+read_addr[15:0], 4'h0, 4'hF);
                             end else if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[user_bar] == 2'b11) begin                  
                                board.RP.tx_usrapp.TSK_TX_MEMORY_READ_64(board.RP.tx_usrapp.DEFAULT_TAG,
                                    board.RP.tx_usrapp.DEFAULT_TC, 11'd1,{board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.xdma_bar+1][31:0],
                                    board.RP.tx_usrapp.BAR_INIT_P_BAR[user_bar][31:0]+read_addr[15:0]}, 4'h0, 4'hF);
                             end
                             board.RP.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                          join

                          board.RP.tx_usrapp.TSK_TX_CLK_EAT(10);
                          board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;
  $display ("[%t] : Data read %h from Address %h",$realtime , board.RP.tx_usrapp.P_READ_DATA, read_addr);

end

endtask

/************************************************************
Task : TSK_XDMA_FIND_BAR
Inputs : input BAR1 address
Outputs : None
Description : Read XDMA configuration register
*************************************************************/
task TSK_XDMA_FIND_BAR;
integer jj;
integer xdma_bar_found;
begin
  jj = 0;
  xdma_bar_found = 0;
  while (xdma_bar_found == 0 && (jj < 6)) begin   // search QDMA bar from 0 to 5 only
       board.RP.tx_usrapp.P_READ_DATA = 32'hffff_ffff;
       fork
          if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[jj] == 2'b10) begin
                board.RP.tx_usrapp.TSK_TX_MEMORY_READ_32(board.RP.tx_usrapp.DEFAULT_TAG,
                    board.RP.tx_usrapp.DEFAULT_TC, 11'd1,
                    board.RP.tx_usrapp.BAR_INIT_P_BAR[jj][31:0]+16'h0, 4'h0, 4'hF);
                board.RP.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
          end else if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[jj] == 2'b11) begin                  
                board.RP.tx_usrapp.TSK_TX_MEMORY_READ_64(board.RP.tx_usrapp.DEFAULT_TAG,
                    board.RP.tx_usrapp.DEFAULT_TC, 11'd1,{board.RP.tx_usrapp.BAR_INIT_P_BAR[jj+1][31:0],
                    board.RP.tx_usrapp.BAR_INIT_P_BAR[jj][31:0]+16'h0}, 4'h0, 4'hF);
                board.RP.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
          end
       join
       board.RP.tx_usrapp.TSK_TX_CLK_EAT(10);
      
    if((board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[jj] == 2'b10) || (board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[jj] == 2'b11)) begin
        board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;

        $display ("[%t] : Data read %h from Address 0x0000",$realtime , board.RP.tx_usrapp.P_READ_DATA);
        if (board.RP.tx_usrapp.P_READ_DATA[31:16] == 16'h1FD3) begin  //Mask [15:0] which will have revision number.
               xdma_bar = jj;
               xdma_bar_found = 1;
               $display (" QDMA BAR found : BAR %d is QDMA BAR\n", xdma_bar);
               end
        else begin
               $display (" QDMA BAR : BAR %d is NOT QDMA BAR\n", jj);
               end
    end
    jj = jj + 1;
  end
  if (xdma_bar_found == 0) begin
     $display (" Not able to find QDMA BAR **ERROR** \n");
     end
end

endtask

/************************************************************
Task : TSK_XDMA_REG_WRITE
Inputs : input BAR1 address, data, byte_en
Outputs : None
Description : Write XDMA configuration register
*************************************************************/
task TSK_XDMA_REG_WRITE;

  input [31:0] addr;
  input [31:0] data;
  input [3:0] byte_en;

   begin 

        DATA_STORE[0] = data[7:0];
        DATA_STORE[1] = data[15:8];
        DATA_STORE[2] = data[23:16];
        DATA_STORE[3] = data[31:24];

  $display("[%t] : Sending Data write task at address %h with data %h" ,$realtime, addr, data);

        if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[board.RP.tx_usrapp.xdma_bar] == 2'b10) begin
          board.RP.tx_usrapp.TSK_TX_MEMORY_WRITE_32(board.RP.tx_usrapp.DEFAULT_TAG,
              board.RP.tx_usrapp.DEFAULT_TC, 11'd1,
              board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.xdma_bar][31:0]+addr[20:0], 4'h0, byte_en, 1'b0);
        end else if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[board.RP.tx_usrapp.xdma_bar] == 2'b11) begin                  
          board.RP.tx_usrapp.TSK_TX_MEMORY_WRITE_64(board.RP.tx_usrapp.DEFAULT_TAG,
              board.RP.tx_usrapp.DEFAULT_TC, 11'd1,{board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.xdma_bar+1][31:0],
              board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.xdma_bar][31:0]+addr[20:0]}, 4'h0, byte_en, 1'b0);
        end
        board.RP.tx_usrapp.TSK_TX_CLK_EAT(100);
        board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;

  $display("[%t] : Done register write!!" ,$realtime);  

end

endtask

/************************************************************
Task : TSK_USR_BAR_REG_WRITE
Inputs : input BAR1 address, data, byte_en
Outputs : None
Description : Write XDMA configuration register
*************************************************************/
task TSK_USR_BAR_REG_WRITE;

  input [31:0] addr;
  input [31:0] data;
  input [3:0] byte_en;

   begin 

        DATA_STORE[0] = data[7:0];
        DATA_STORE[1] = data[15:8];
        DATA_STORE[2] = data[23:16];
        DATA_STORE[3] = data[31:24];

  $display("[%t] : Sending Data write task at address %h with data %h" ,$realtime, addr, data);

        if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[user_bar] == 2'b10) begin
          board.RP.tx_usrapp.TSK_TX_MEMORY_WRITE_32(board.RP.tx_usrapp.DEFAULT_TAG,
              board.RP.tx_usrapp.DEFAULT_TC, 11'd1,
              board.RP.tx_usrapp.BAR_INIT_P_BAR[user_bar][31:0]+addr[20:0], 4'h0, byte_en, 1'b0);
        end else if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[user_bar] == 2'b11) begin                  
          board.RP.tx_usrapp.TSK_TX_MEMORY_WRITE_64(board.RP.tx_usrapp.DEFAULT_TAG,
              board.RP.tx_usrapp.DEFAULT_TC, 11'd1,{board.RP.tx_usrapp.BAR_INIT_P_BAR[0+1][31:0],
              board.RP.tx_usrapp.BAR_INIT_P_BAR[user_bar][31:0]+addr[20:0]}, 4'h0, byte_en, 1'b0);
        end
        board.RP.tx_usrapp.TSK_TX_CLK_EAT(100);
        board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;

  $display("[%t] : Done register write!!" ,$realtime);  

end

endtask
   
/************************************************************
Task : TSK_INIT_DATA_H2C
Inputs : None
Outputs : None
Description : Initialize Descriptor and Data 
*************************************************************/

task TSK_INIT_DATA_H2C;
   integer k;

   begin
// Descriptor Start address 0x100 = 256;
// Data start address = 0x400 = 1024
// 0x3786b000/0x00: 0xad4b0003 0xad4b0003 magic|extra_adjacent|control
// 0x3786b004/0x04: 0x00000080 0x00000080 bytes
// 0x3786b008/0x08: 0x00000400 0x00000400 src_addr_lo
// 0x3786b00c/0x0c: 0x00000000 0x00000000 src_addr_hi
// 0x3786b010/0x00: 0x00000000 0x00000000 dst_addr_lo
// 0x3786b014/0x04: 0x00000000 0x00000000 dst_addr_hi
// 0x3786b018/0x08: 0x00000000 0x00000000 next_addr
// 0x3786b01c/0x0c: 0x00000000 0x00000000 next_addr_pad

    $display(" **** TASK DATA H2C ***\n");


    $display(" **** Initilize Descriptor data ***\n");
    DATA_STORE[256+0] = 8'h00; //-- Src_add [31:0] x0400
    DATA_STORE[256+1] = 8'h04;
    DATA_STORE[256+2] = 8'h00;
    DATA_STORE[256+3] = 8'h00;
    DATA_STORE[256+4] = 8'h00; //-- Src add [63:32]
    DATA_STORE[256+5] = 8'h00;
    DATA_STORE[256+6] = 8'h00;
    DATA_STORE[256+7] = 8'h00;
    DATA_STORE[256+8] = DMA_BYTE_CNT[7:0]; // [71:64] len [7:0] 28bits
    DATA_STORE[256+9] = DMA_BYTE_CNT[15:8];// [79:72] len [15:8]  
    DATA_STORE[256+10] = 8'h00;            // [87:80] len [23:16]
    DATA_STORE[256+11] = 8'h00;            // [96:88] {Reserved, EOP, SOP, Dsc vld, len[27:24]}
    DATA_STORE[256+12] = 8'h00; // [104:97] Reserved 32bits
    DATA_STORE[256+13] = 8'h00;
    DATA_STORE[256+14] = 8'h00;
    DATA_STORE[256+15] = 8'h00;
    DATA_STORE[256+16] = 8'h00; // Dst add 64bits [31:0] 0x0000
    DATA_STORE[256+17] = 8'h00;
    DATA_STORE[256+18] = 8'h00;
    DATA_STORE[256+19] = 8'h00;
    DATA_STORE[256+20] = 8'h00; // Dst add 64 bits [63:32]
    DATA_STORE[256+21] = 8'h00;
    DATA_STORE[256+22] = 8'h00;
    DATA_STORE[256+23] = 8'h00;
    DATA_STORE[256+24] = 8'h00; // 64 bits Reserved [31:0]
    DATA_STORE[256+25] = 8'h00;
    DATA_STORE[256+26] = 8'h00;
    DATA_STORE[256+27] = 8'h00;
    DATA_STORE[256+28] = 8'h00; // Reserved [63:32]
    DATA_STORE[256+29] = 8'h00;
    DATA_STORE[256+30] = 8'h00;
    DATA_STORE[256+31] = 8'h00;


    for (k = 0; k < 32; k = k + 1)  begin
        $display(" **** Descriptor data *** data = %h, addr= %d\n", DATA_STORE[256+k], 256+k);
        #(Tcq);
    end
    for (k = 0; k < DMA_BYTE_CNT+64; k = k + 1)  begin
       if( k < DMA_BYTE_CNT) begin
        #(Tcq) DATA_STORE[1024+k] = k;
       end else begin
        #(Tcq) DATA_STORE[1024+k] = 8'h00;
       end
    end

   end
endtask

/************************************************************
Task : TSK_INIT_DATA_C2H
Inputs : None
Outputs : None
Description : Initialize Descriptor 
*************************************************************/

task TSK_INIT_DATA_C2H;

   integer k;

   begin

    $display(" **** TASK DATA C2H ***\n");

    $display(" **** Initilize Descriptor data ***\n");
    DATA_STORE[768+0] = 8'h13; // -- Magic
    DATA_STORE[768+1] = 8'h00;
    DATA_STORE[768+2] = 8'h4b;
    DATA_STORE[768+3] = 8'had;
    DATA_STORE[768+4] = DMA_BYTE_CNT[7:0]; //-- Length lsb
    DATA_STORE[768+5] = DMA_BYTE_CNT[15:8]; //-- Length msb
    DATA_STORE[768+6] = 8'h00;
    DATA_STORE[768+7] = 8'h00;
    DATA_STORE[768+8] = 8'h00; //-- Src_add [31:0] x0000
    DATA_STORE[768+9] = 8'h00;
    DATA_STORE[768+10] = 8'h00;
    DATA_STORE[768+11] = 8'h00;
    DATA_STORE[768+12] = 8'h00; //-- Src add [63:32]
    DATA_STORE[768+13] = 8'h00;
    DATA_STORE[768+14] = 8'h00;
    DATA_STORE[768+15] = 8'h00;
    DATA_STORE[768+16] = 8'h00; //-- Dst add [31:0] x0800
    DATA_STORE[768+17] = 8'h08;
    DATA_STORE[768+18] = 8'h00;
    DATA_STORE[768+19] = 8'h00;
    DATA_STORE[768+20] = 8'h00; //-- Dst add [63:32]
    DATA_STORE[768+21] = 8'h00;
    DATA_STORE[768+22] = 8'h00;
    DATA_STORE[768+23] = 8'h00;
    DATA_STORE[768+24] = 8'h00; //-- Nxt add [31:0]
    DATA_STORE[768+25] = 8'h00;
    DATA_STORE[768+26] = 8'h00;
    DATA_STORE[768+27] = 8'h00;
    DATA_STORE[768+28] = 8'h00; //-- Nxt add [63:32]
    DATA_STORE[768+29] = 8'h00;
    DATA_STORE[768+30] = 8'h00;
    DATA_STORE[768+31] = 8'h00;

    for (k = 0; k < 32; k = k + 1)  begin
        $display(" **** Descriptor data *** data = %h, addr= %d\n", DATA_STORE[768+k], 768+k);
        #(Tcq);
    end
    for (k = 0; k < DMA_BYTE_CNT+64; k = k + 1)  begin
        #(Tcq) DATA_STORE[2048+k] = 8'h00;
    end
   end
endtask

/************************************************************
Task : TSK_INIT_QDMA_MM_DATA_H2C
Inputs : None
Outputs : None
Description : Initialize Descriptor and Data 
*************************************************************/

task TSK_INIT_QDMA_MM_DATA_H2C;
   integer k;

   begin
    $display(" **** TASK QDMA MM H2C DSC at address 0x100 ***\n");

    $display(" **** Initilize Descriptor data ***\n");
    DATA_STORE[256+0] = 8'h00; //-- Src_add [31:0] x300
    DATA_STORE[256+1] = 8'h03;
    DATA_STORE[256+2] = 8'h00;
    DATA_STORE[256+3] = 8'h00;
    DATA_STORE[256+4] = 8'h00; //-- Src add [63:32]
    DATA_STORE[256+5] = 8'h00;
    DATA_STORE[256+6] = 8'h00;
    DATA_STORE[256+7] = 8'h00;
    DATA_STORE[256+8] = DMA_BYTE_CNT[7:0]; // [71:64] len [7:0] 28bits
    DATA_STORE[256+9] = DMA_BYTE_CNT[15:8];// [79:72] len [15:8]  
    DATA_STORE[256+10] = 8'h00;            // [87:80] len [23:16]
    DATA_STORE[256+11] = 8'h00;            // [96:88] {Reserved, EOP, SOP, Dsc vld, len[27:24]}
    DATA_STORE[256+12] = 8'h00; // [104:97] Reserved 32bits
    DATA_STORE[256+13] = 8'h00;
    DATA_STORE[256+14] = 8'h00;
    DATA_STORE[256+15] = 8'h00;
    DATA_STORE[256+16] = 8'h00; // Dst add 64bits [31:0] 0x0000
    DATA_STORE[256+17] = 8'h00;
    DATA_STORE[256+18] = 8'h00;
    DATA_STORE[256+19] = 8'h00;
    DATA_STORE[256+20] = 8'h00; // Dst add 64 bits [63:32]
    DATA_STORE[256+21] = 8'h00;
    DATA_STORE[256+22] = 8'h00;
    DATA_STORE[256+23] = 8'h00;
    DATA_STORE[256+24] = 8'h00; // 64 bits Reserved [31:0]
    DATA_STORE[256+25] = 8'h00;
    DATA_STORE[256+26] = 8'h00;
    DATA_STORE[256+27] = 8'h00;
    DATA_STORE[256+28] = 8'h00; // Reserved [63:32]
    DATA_STORE[256+29] = 8'h00;
    DATA_STORE[256+30] = 8'h00;
    DATA_STORE[256+31] = 8'h00;

    //Intilize Status write back location to 0's  
    DATA_STORE[736+0] = 8'h00;
    DATA_STORE[736+1] = 8'h00;
    DATA_STORE[736+2] = 8'h00;
    DATA_STORE[736+3] = 8'h00;

    for (k = 0; k < 32; k = k + 1)  begin
        $display(" **** Descriptor data *** data = %h, addr= %d\n", DATA_STORE[256+k], 256+k);
        #(Tcq);
    end
    for (k = 0; k < DMA_BYTE_CNT; k = k + 1)  begin
        #(Tcq) DATA_STORE[768+k] = k;  // 0x1200
    end

   end
endtask

/************************************************************
Task : TSK_INIT_QDMA_MM_DATA_C2H
Inputs : None
Outputs : None
Description : Initialize Descriptor 
*************************************************************/

task TSK_INIT_QDMA_MM_DATA_C2H;

   integer k;

   begin

    $display(" **** TASK QDMA MM C2H DSC at address 0x0400 ***\n");

    $display(" **** Initilize Descriptor data ***\n");
    DATA_STORE[1024+0] = 8'h00; //-- Src_add [31:0]
    DATA_STORE[1024+1] = 8'h00;
    DATA_STORE[1024+2] = 8'h00;
    DATA_STORE[1024+3] = 8'h00;
    DATA_STORE[1024+4] = 8'h00; //-- Src add [63:32]
    DATA_STORE[1024+5] = 8'h00;
    DATA_STORE[1024+6] = 8'h00;
    DATA_STORE[1024+7] = 8'h00;
    DATA_STORE[1024+8] = DMA_BYTE_CNT[7:0]; // [71:64] len [7:0] 28bits
    DATA_STORE[1024+9] = DMA_BYTE_CNT[15:8];// [79:72] len [15:8]  
    DATA_STORE[1024+10] = 8'h00;            // [87:80] len [23:16]
    DATA_STORE[1024+11] = 8'h00;            // [96:88] {Reserved, EOP, SOP, Dsc vld, len[27:24]}
    DATA_STORE[1024+12] = 8'h00; // [104:97] Reserved 32bits
    DATA_STORE[1024+13] = 8'h00;
    DATA_STORE[1024+14] = 8'h00;
    DATA_STORE[1024+15] = 8'h00;
    DATA_STORE[1024+16] = 8'h00; // Dst add 64bits [31:0] 0x1600
    DATA_STORE[1024+17] = 8'h06;
    DATA_STORE[1024+18] = 8'h00;
    DATA_STORE[1024+19] = 8'h00;
    DATA_STORE[1024+20] = 8'h00; // Dst add 64 bits [63:32]
    DATA_STORE[1024+21] = 8'h00;
    DATA_STORE[1024+22] = 8'h00;
    DATA_STORE[1024+23] = 8'h00;
    DATA_STORE[1024+24] = 8'h00; // 64 bits Reserved [31:0]
    DATA_STORE[1024+25] = 8'h00;
    DATA_STORE[1024+26] = 8'h00;
    DATA_STORE[1024+27] = 8'h00;
    DATA_STORE[1024+28] = 8'h00; // Reserved [63:32]
    DATA_STORE[1024+29] = 8'h00;
    DATA_STORE[1024+30] = 8'h00;
    DATA_STORE[1024+31] = 8'h00;

    //Intilize Status write back location to 0's  
    DATA_STORE[1504+0] = 8'h00;
    DATA_STORE[1504+1] = 8'h00;
    DATA_STORE[1504+2] = 8'h00;
    DATA_STORE[1504+3] = 8'h00;
      
//    for (k = 0; k < 32; k = k + 1)  begin
//        $display(" **** Descriptor data *** data = %h, addr= %d\n", DATA_STORE[1024+k], 1024+k);
//        #(Tcq);
//    end
    for (k = 0; k < DMA_BYTE_CNT; k = k + 1)  begin
        #(Tcq) DATA_STORE[1536+k] = 8'h00;  
    end
  end
endtask

/************************************************************
Task : TSK_INIT_QDMA_ST_DATA_H2C
Inputs : None
Outputs : None
Description : Initialize Descriptor and Data 
*************************************************************/

task TSK_INIT_QDMA_ST_DATA_H2C;
   integer k;

   begin
    $display(" **** TASK QDMA ST H2C DSC at address 0x0100 (1048) ***\n");

    $display(" **** Initilize Descriptor data ***\n");
    DATA_STORE[256+0] = 8'h00; //-- Src_add [31:0] x0200
    DATA_STORE[256+1] = 8'h02;
    DATA_STORE[256+2] = 8'h00;
    DATA_STORE[256+3] = 8'h00;
    DATA_STORE[256+4] = 8'h00; //-- Src add [63:32]
    DATA_STORE[256+5] = 8'h00;
    DATA_STORE[256+6] = 8'h00;
    DATA_STORE[256+7] = 8'h00;
    DATA_STORE[256+8] = DMA_BYTE_CNT[7:0]; // [71:64] len [7:0] 28bits
    DATA_STORE[256+9] = DMA_BYTE_CNT[15:8];// [79:72] len [15:8]  
    DATA_STORE[256+10] = 8'h00;            // [87:80] len [23:16]
    DATA_STORE[256+11] = 8'h70;            // [96:88] {Reserved, EOP, SOP, Dsc vld, len[27:24]}
    DATA_STORE[256+12] = 8'h00; // [104:97] Reserved 32bits
    DATA_STORE[256+13] = 8'h00;
    DATA_STORE[256+14] = 8'h00;
    DATA_STORE[256+15] = 8'h00;

    //Intilize Status write back location to 0's  
    DATA_STORE[496+0] = 8'h00;
    DATA_STORE[496+1] = 8'h00;
    DATA_STORE[496+2] = 8'h00;
    DATA_STORE[496+3] = 8'h00;
      
//    for (k = 0; k < 16; k = k + 1)  begin
//        $display(" **** Descriptor data *** data = %h, addr= %d\n", DATA_STORE[256+k], 256+k);
//        #(Tcq);
//    end
      data_tmp = 0;
    for (k = 0; k < 256; k = k + 2)  begin
        DATA_STORE[512+k]   = data_tmp[7:0];
        DATA_STORE[512+k+1] = data_tmp[15:8];
        data_tmp[15:0] = data_tmp[15:0]+1;
//        #(Tcq) 
    end

//    for (k = 0; k < 256; k = k + 1)  begin
//        $display(" **** H2C data *** data = %h, addr= %d\n", DATA_STORE[512+k], 512+k);
//    end
      
   end
endtask

/************************************************************
Task : TSK_INIT_QDMA_ST_DATA_H2C_NEW
Inputs : None
Outputs : None
Description : Initialize Descriptor and Data 
*************************************************************/

task TSK_INIT_QDMA_ST_DATA_H2C_NEW;
   integer k;

   begin
    $display(" **** TASK QDMA ST H2C DSC at address 0x0100 (1048) ***\n");

    $display(" **** Initilize Descriptor data ***\n");
    DATA_STORE[256+0]  = 8'h00; // 32Bits Reserved 
    DATA_STORE[256+1]  = 8'h00;
    DATA_STORE[256+2]  = DMA_BYTE_CNT[7:0]; // Packet length for ST loopback desin
    DATA_STORE[256+3]  = DMA_BYTE_CNT[15:8];
    DATA_STORE[256+4]  = DMA_BYTE_CNT[7:0];  // Packet length 16 bits [7:0]
    DATA_STORE[256+5]  = DMA_BYTE_CNT[15:8]; // Packet length 16 bits [15:8]
    DATA_STORE[256+6]  = 8'h00; // Reserved
    DATA_STORE[256+7]  = 8'h00;
    DATA_STORE[256+8]  = 8'h00; //-- Src_add [31:0] x0200
    DATA_STORE[256+9]  = 8'h02;
    DATA_STORE[256+10] = 8'h00;
    DATA_STORE[256+11] = 8'h00;
    DATA_STORE[256+12] = 8'h00; //-- Src_add [63:32] x0000
    DATA_STORE[256+13] = 8'h00;
    DATA_STORE[256+14] = 8'h00;
    DATA_STORE[256+15] = 8'h00;

    //Intilize Status write back location to 0's  
    DATA_STORE[496+0] = 8'h00;
    DATA_STORE[496+1] = 8'h00;
    DATA_STORE[496+2] = 8'h00;
    DATA_STORE[496+3] = 8'h00;
    data_tmp = 0;
    for (k = 0; k < 256; k = k + 2)  begin
        DATA_STORE[512+k]   = data_tmp[7:0];
        DATA_STORE[512+k+1] = data_tmp[15:8];
        data_tmp[15:0] = data_tmp[15:0]+1;
    end

   end
endtask

/************************************************************
Task : TSK_INIT_QDMA_ST_DATA_C2H
Inputs : None
Outputs : None
Description : Initialize Descriptor and Data 
*************************************************************/

task TSK_INIT_QDMA_ST_DATA_C2H;
   integer k;

   begin
    $display(" **** TASK QDMA ST DATA C2H. DSC at address 0x400 (1024) ***\n");

    $display(" **** Initilize Descriptor data #1 ***\n");
    DATA_STORE[1024+0] = 8'h00; //-- Src_add [31:0] x500
    DATA_STORE[1024+1] = 8'h05;
    DATA_STORE[1024+2] = 8'h00;
    DATA_STORE[1024+3] = 8'h00;
    DATA_STORE[1024+4] = 8'h00; //-- Src add [63:32]
    DATA_STORE[1024+5] = 8'h00;
    DATA_STORE[1024+6] = 8'h00;
    DATA_STORE[1024+7] = 8'h00;
    $display(" **** Initilize Descriptor data #2 ***\n");
    DATA_STORE[1032+0] = 8'h80; //-- Src_add [31:0] x500
    DATA_STORE[1032+1] = 8'h05;
    DATA_STORE[1032+2] = 8'h00;
    DATA_STORE[1032+3] = 8'h00;
    DATA_STORE[1032+4] = 8'h00; //-- Src add [63:32]
    DATA_STORE[1032+5] = 8'h00;
    DATA_STORE[1032+6] = 8'h00;
    DATA_STORE[1032+7] = 8'h00;

    //Intilize Status write back location to 0's  
    DATA_STORE[1144+0] = 8'h00;
    DATA_STORE[1144+1] = 8'h00;
    DATA_STORE[1144+2] = 8'h00;
    DATA_STORE[1144+3] = 8'h00;
      
    for (k = 0; k < 8; k = k + 1)  begin
        $display(" **** Descriptor data *** data = %h, addr= %d\n", DATA_STORE[1024+k], 1024+k);
        #(Tcq);
    end
    for (k = 0; k < (DMA_BYTE_CNT*2); k = k + 1)  begin
       #(Tcq) DATA_STORE[1280+k] = 8'h00;  //0x500
    end
   end
endtask

/************************************************************
Task : TSK_INIT_QDMA_ST_WBK_C2H
Inputs : None
Outputs : None
Description : Initialize Descriptor and Data 
*************************************************************/

task TSK_INIT_QDMA_ST_WBK_C2H;
   integer k;

   begin
    $display(" **** TASK QDMA ST WBK DATA for C2H at address 0x800 (2048) ***\n");

    // initilize WBK data for two entries 64bits each  
    for (k = 0; k < 32; k = k + 1)  begin
       #(Tcq) DATA_STORE[2048+k] = 8'h00;
    end
   end
endtask
   

/************************************************************
Task : COMPARE_DATA_H2C 
Inputs : Number of Payload Bytes 
Outputs : None
Description : Compare Data received at XDMA with data sent from RP - user TB
*************************************************************/

task COMPARE_DATA_H2C;
   input [31:0]payload_bytes ;
   input integer address;

  reg [511:0] READ_DATA [(DMA_BYTE_CNT/8):0];
  reg [511:0] DATA_STORE_512 [(DMA_BYTE_CNT/8):0];

  integer matched_data_counter;
  integer i, j, k;
  integer data_beat_count;

  begin
   
    matched_data_counter = 0;	

        //Calculate number of beats for payload on XDMA
/*    
    case (board.EP.C_DATA_WIDTH)    
    64:		data_beat_count = ((payload_bytes % 32'h8) == 0) ? (payload_bytes/32'h8) : ((payload_bytes/32'h8)+32'h1); 
    128:	data_beat_count = ((payload_bytes % 32'h10) == 0) ? (payload_bytes/32'h10) : ((payload_bytes/32'h10)+32'h1); 
    256:	data_beat_count = ((payload_bytes % 32'h20) == 0) ? (payload_bytes/32'h20) : ((payload_bytes/32'h20)+32'h1); 
    512:	data_beat_count = ((payload_bytes % 32'h40) == 0) ? (payload_bytes/32'h40) : ((payload_bytes/32'h40)+32'h1); 
    endcase

    $display ("Enters into compare read data task at %gns\n", $realtime);
    $display ("payload bytes=%h, data_beat_count =%d\n", payload_bytes, data_beat_count);
    
    for (i=0; i<data_beat_count; i=i+1)   begin
    
      DATA_STORE_512[i] = 512'b0;
    
    end
    
    
    
    //Sampling data payload on XDMA
    
    @ (posedge board.EP.m_axi_wvalid) ;		  			//valid data comes at wvalid
      for (i=0; i<data_beat_count; i=i+1)   begin
        @ (negedge board.EP.user_clk);							//samples data wvalid and negedge of user_clk

            if ( board.EP.m_axi_wready ) begin			//check for wready is high before sampling data
               case (board.EP.C_DATA_WIDTH)
                64: READ_DATA[i] = {((board.EP.m_axi_wstrb[7] == 1'b1) ? board.EP.m_axi_wdata[63:56] : 8'h00),
                                    ((board.EP.m_axi_wstrb[6] == 1'b1) ? board.EP.m_axi_wdata[55:48] : 8'h00),
                                    ((board.EP.m_axi_wstrb[5] == 1'b1) ? board.EP.m_axi_wdata[47:40] : 8'h00),
                                    ((board.EP.m_axi_wstrb[4] == 1'b1) ? board.EP.m_axi_wdata[39:32] : 8'h00),
                                    ((board.EP.m_axi_wstrb[3] == 1'b1) ? board.EP.m_axi_wdata[31:24] : 8'h00),
                                    ((board.EP.m_axi_wstrb[2] == 1'b1) ? board.EP.m_axi_wdata[23:16] : 8'h00),
                                    ((board.EP.m_axi_wstrb[1] == 1'b1) ? board.EP.m_axi_wdata[15:8] : 8'h00),
                                    ((board.EP.m_axi_wstrb[0] == 1'b1) ? board.EP.m_axi_wdata[7:0] : 8'h00)};
                128: READ_DATA[i] = {((board.EP.m_axi_wstrb[15] == 1'b1) ? board.EP.m_axi_wdata[127:120] : 8'h00),
                                        ((board.EP.m_axi_wstrb[14] == 1'b1) ? board.EP.m_axi_wdata[119:112] : 8'h00),
                                        ((board.EP.m_axi_wstrb[13] == 1'b1) ? board.EP.m_axi_wdata[111:104] : 8'h00),
                                        ((board.EP.m_axi_wstrb[12] == 1'b1) ? board.EP.m_axi_wdata[103:96] : 8'h00),
                                        ((board.EP.m_axi_wstrb[11] == 1'b1) ? board.EP.m_axi_wdata[95:88] : 8'h00),
                                        ((board.EP.m_axi_wstrb[10] == 1'b1) ? board.EP.m_axi_wdata[87:80] : 8'h00),
                                        ((board.EP.m_axi_wstrb[9] == 1'b1) ? board.EP.m_axi_wdata[79:72] : 8'h00),
                                        ((board.EP.m_axi_wstrb[8] == 1'b1) ? board.EP.m_axi_wdata[71:64] : 8'h00),
                                        ((board.EP.m_axi_wstrb[7] == 1'b1) ? board.EP.m_axi_wdata[63:56] : 8'h00),
                                        ((board.EP.m_axi_wstrb[6] == 1'b1) ? board.EP.m_axi_wdata[55:48] : 8'h00),
                                        ((board.EP.m_axi_wstrb[5] == 1'b1) ? board.EP.m_axi_wdata[47:40] : 8'h00),
                                        ((board.EP.m_axi_wstrb[4] == 1'b1) ? board.EP.m_axi_wdata[39:32] : 8'h00),
                                        ((board.EP.m_axi_wstrb[3] == 1'b1) ? board.EP.m_axi_wdata[31:24] : 8'h00),
                                        ((board.EP.m_axi_wstrb[2] == 1'b1) ? board.EP.m_axi_wdata[23:16] : 8'h00),
                                        ((board.EP.m_axi_wstrb[1] == 1'b1) ? board.EP.m_axi_wdata[15:8] : 8'h00),
                                        ((board.EP.m_axi_wstrb[0] == 1'b1) ? board.EP.m_axi_wdata[7:0] : 8'h00)};
                256: READ_DATA[i] = {((board.EP.m_axi_wstrb[31] == 1'b1) ? board.EP.m_axi_wdata[255:248] : 8'h00),
                                        ((board.EP.m_axi_wstrb[30] == 1'b1) ? board.EP.m_axi_wdata[247:240] : 8'h00),
                                        ((board.EP.m_axi_wstrb[29] == 1'b1) ? board.EP.m_axi_wdata[239:232] : 8'h00),
                                        ((board.EP.m_axi_wstrb[28] == 1'b1) ? board.EP.m_axi_wdata[231:224] : 8'h00),
                                        ((board.EP.m_axi_wstrb[27] == 1'b1) ? board.EP.m_axi_wdata[223:216] : 8'h00),
                                        ((board.EP.m_axi_wstrb[26] == 1'b1) ? board.EP.m_axi_wdata[215:208] : 8'h00),
                                        ((board.EP.m_axi_wstrb[25] == 1'b1) ? board.EP.m_axi_wdata[207:200] : 8'h00),
                                        ((board.EP.m_axi_wstrb[24] == 1'b1) ? board.EP.m_axi_wdata[199:192] : 8'h00),
                                        ((board.EP.m_axi_wstrb[23] == 1'b1) ? board.EP.m_axi_wdata[191:184] : 8'h00),
                                        ((board.EP.m_axi_wstrb[22] == 1'b1) ? board.EP.m_axi_wdata[183:176] : 8'h00),
                                        ((board.EP.m_axi_wstrb[21] == 1'b1) ? board.EP.m_axi_wdata[175:168] : 8'h00),
                                        ((board.EP.m_axi_wstrb[20] == 1'b1) ? board.EP.m_axi_wdata[167:160] : 8'h00),
                                        ((board.EP.m_axi_wstrb[19] == 1'b1) ? board.EP.m_axi_wdata[159:152] : 8'h00),
                                        ((board.EP.m_axi_wstrb[18] == 1'b1) ? board.EP.m_axi_wdata[151:144] : 8'h00),
                                        ((board.EP.m_axi_wstrb[17] == 1'b1) ? board.EP.m_axi_wdata[143:136] : 8'h00),
                                        ((board.EP.m_axi_wstrb[16] == 1'b1) ? board.EP.m_axi_wdata[135:128] : 8'h00),
                                        ((board.EP.m_axi_wstrb[15] == 1'b1) ? board.EP.m_axi_wdata[127:120] : 8'h00),
                                        ((board.EP.m_axi_wstrb[14] == 1'b1) ? board.EP.m_axi_wdata[119:112] : 8'h00),
                                        ((board.EP.m_axi_wstrb[13] == 1'b1) ? board.EP.m_axi_wdata[111:104] : 8'h00),
                                        ((board.EP.m_axi_wstrb[12] == 1'b1) ? board.EP.m_axi_wdata[103:96] : 8'h00),
                                        ((board.EP.m_axi_wstrb[11] == 1'b1) ? board.EP.m_axi_wdata[95:88] : 8'h00),
                                        ((board.EP.m_axi_wstrb[10] == 1'b1) ? board.EP.m_axi_wdata[87:80] : 8'h00),
                                        ((board.EP.m_axi_wstrb[9] == 1'b1) ? board.EP.m_axi_wdata[79:72] : 8'h00),
                                        ((board.EP.m_axi_wstrb[8] == 1'b1) ? board.EP.m_axi_wdata[71:64] : 8'h00),
                                        ((board.EP.m_axi_wstrb[7] == 1'b1) ? board.EP.m_axi_wdata[63:56] : 8'h00),
                                        ((board.EP.m_axi_wstrb[6] == 1'b1) ? board.EP.m_axi_wdata[55:48] : 8'h00),
                                        ((board.EP.m_axi_wstrb[5] == 1'b1) ? board.EP.m_axi_wdata[47:40] : 8'h00),
                                        ((board.EP.m_axi_wstrb[4] == 1'b1) ? board.EP.m_axi_wdata[39:32] : 8'h00),
                                        ((board.EP.m_axi_wstrb[3] == 1'b1) ? board.EP.m_axi_wdata[31:24] : 8'h00),
                                        ((board.EP.m_axi_wstrb[2] == 1'b1) ? board.EP.m_axi_wdata[23:16] : 8'h00),
                                        ((board.EP.m_axi_wstrb[1] == 1'b1) ? board.EP.m_axi_wdata[15:8] : 8'h00),
                                        ((board.EP.m_axi_wstrb[0] == 1'b1) ? board.EP.m_axi_wdata[7:0] : 8'h00)};
                512: READ_DATA[i] = {((board.EP.m_axi_wstrb[63] == 1'b1) ? board.EP.m_axi_wdata[511:504] : 8'h00),
                                        ((board.EP.m_axi_wstrb[62] == 1'b1) ? board.EP.m_axi_wdata[503:496] : 8'h00),
                                        ((board.EP.m_axi_wstrb[61] == 1'b1) ? board.EP.m_axi_wdata[495:488] : 8'h00),
                                        ((board.EP.m_axi_wstrb[60] == 1'b1) ? board.EP.m_axi_wdata[487:480] : 8'h00),
                                        ((board.EP.m_axi_wstrb[59] == 1'b1) ? board.EP.m_axi_wdata[479:472] : 8'h00),
                                        ((board.EP.m_axi_wstrb[58] == 1'b1) ? board.EP.m_axi_wdata[471:464] : 8'h00),
                                        ((board.EP.m_axi_wstrb[57] == 1'b1) ? board.EP.m_axi_wdata[463:456] : 8'h00),
                                        ((board.EP.m_axi_wstrb[56] == 1'b1) ? board.EP.m_axi_wdata[455:448] : 8'h00),
                                        ((board.EP.m_axi_wstrb[55] == 1'b1) ? board.EP.m_axi_wdata[447:440] : 8'h00),
                                        ((board.EP.m_axi_wstrb[54] == 1'b1) ? board.EP.m_axi_wdata[439:432] : 8'h00),
                                        ((board.EP.m_axi_wstrb[53] == 1'b1) ? board.EP.m_axi_wdata[431:424] : 8'h00),
                                        ((board.EP.m_axi_wstrb[52] == 1'b1) ? board.EP.m_axi_wdata[423:416] : 8'h00),
                                        ((board.EP.m_axi_wstrb[51] == 1'b1) ? board.EP.m_axi_wdata[415:408] : 8'h00),
                                        ((board.EP.m_axi_wstrb[50] == 1'b1) ? board.EP.m_axi_wdata[407:400] : 8'h00),
                                        ((board.EP.m_axi_wstrb[49] == 1'b1) ? board.EP.m_axi_wdata[399:392] : 8'h00),
                                        ((board.EP.m_axi_wstrb[48] == 1'b1) ? board.EP.m_axi_wdata[391:384] : 8'h00),
                                        ((board.EP.m_axi_wstrb[47] == 1'b1) ? board.EP.m_axi_wdata[383:376] : 8'h00),
                                        ((board.EP.m_axi_wstrb[46] == 1'b1) ? board.EP.m_axi_wdata[375:368] : 8'h00),
                                        ((board.EP.m_axi_wstrb[45] == 1'b1) ? board.EP.m_axi_wdata[367:360] : 8'h00),
                                        ((board.EP.m_axi_wstrb[44] == 1'b1) ? board.EP.m_axi_wdata[359:352] : 8'h00),
                                        ((board.EP.m_axi_wstrb[43] == 1'b1) ? board.EP.m_axi_wdata[351:344] : 8'h00),
                                        ((board.EP.m_axi_wstrb[42] == 1'b1) ? board.EP.m_axi_wdata[343:336] : 8'h00),
                                        ((board.EP.m_axi_wstrb[41] == 1'b1) ? board.EP.m_axi_wdata[335:328] : 8'h00),
                                        ((board.EP.m_axi_wstrb[40] == 1'b1) ? board.EP.m_axi_wdata[327:320] : 8'h00),
                                        ((board.EP.m_axi_wstrb[39] == 1'b1) ? board.EP.m_axi_wdata[319:312] : 8'h00),
                                        ((board.EP.m_axi_wstrb[38] == 1'b1) ? board.EP.m_axi_wdata[311:304] : 8'h00),
                                        ((board.EP.m_axi_wstrb[37] == 1'b1) ? board.EP.m_axi_wdata[303:296] : 8'h00),
                                        ((board.EP.m_axi_wstrb[36] == 1'b1) ? board.EP.m_axi_wdata[295:288] : 8'h00),
                                        ((board.EP.m_axi_wstrb[35] == 1'b1) ? board.EP.m_axi_wdata[287:280] : 8'h00),
                                        ((board.EP.m_axi_wstrb[34] == 1'b1) ? board.EP.m_axi_wdata[279:272] : 8'h00),
                                        ((board.EP.m_axi_wstrb[33] == 1'b1) ? board.EP.m_axi_wdata[271:264] : 8'h00),
                                        ((board.EP.m_axi_wstrb[32] == 1'b1) ? board.EP.m_axi_wdata[263:256] : 8'h00),
                                        ((board.EP.m_axi_wstrb[31] == 1'b1) ? board.EP.m_axi_wdata[255:248] : 8'h00),
                                        ((board.EP.m_axi_wstrb[30] == 1'b1) ? board.EP.m_axi_wdata[247:240] : 8'h00),
                                        ((board.EP.m_axi_wstrb[29] == 1'b1) ? board.EP.m_axi_wdata[239:232] : 8'h00),
                                        ((board.EP.m_axi_wstrb[28] == 1'b1) ? board.EP.m_axi_wdata[231:224] : 8'h00),
                                        ((board.EP.m_axi_wstrb[27] == 1'b1) ? board.EP.m_axi_wdata[223:216] : 8'h00),
                                        ((board.EP.m_axi_wstrb[26] == 1'b1) ? board.EP.m_axi_wdata[215:208] : 8'h00),
                                        ((board.EP.m_axi_wstrb[25] == 1'b1) ? board.EP.m_axi_wdata[207:200] : 8'h00),
                                        ((board.EP.m_axi_wstrb[24] == 1'b1) ? board.EP.m_axi_wdata[199:192] : 8'h00),
                                        ((board.EP.m_axi_wstrb[23] == 1'b1) ? board.EP.m_axi_wdata[191:184] : 8'h00),
                                        ((board.EP.m_axi_wstrb[22] == 1'b1) ? board.EP.m_axi_wdata[183:176] : 8'h00),
                                        ((board.EP.m_axi_wstrb[21] == 1'b1) ? board.EP.m_axi_wdata[175:168] : 8'h00),
                                        ((board.EP.m_axi_wstrb[20] == 1'b1) ? board.EP.m_axi_wdata[167:160] : 8'h00),
                                        ((board.EP.m_axi_wstrb[19] == 1'b1) ? board.EP.m_axi_wdata[159:152] : 8'h00),
                                        ((board.EP.m_axi_wstrb[18] == 1'b1) ? board.EP.m_axi_wdata[151:144] : 8'h00),
                                        ((board.EP.m_axi_wstrb[17] == 1'b1) ? board.EP.m_axi_wdata[143:136] : 8'h00),
                                        ((board.EP.m_axi_wstrb[16] == 1'b1) ? board.EP.m_axi_wdata[135:128] : 8'h00),
                                        ((board.EP.m_axi_wstrb[15] == 1'b1) ? board.EP.m_axi_wdata[127:120] : 8'h00),
                                        ((board.EP.m_axi_wstrb[14] == 1'b1) ? board.EP.m_axi_wdata[119:112] : 8'h00),
                                        ((board.EP.m_axi_wstrb[13] == 1'b1) ? board.EP.m_axi_wdata[111:104] : 8'h00),
                                        ((board.EP.m_axi_wstrb[12] == 1'b1) ? board.EP.m_axi_wdata[103:96] : 8'h00),
                                        ((board.EP.m_axi_wstrb[11] == 1'b1) ? board.EP.m_axi_wdata[95:88] : 8'h00),
                                        ((board.EP.m_axi_wstrb[10] == 1'b1) ? board.EP.m_axi_wdata[87:80] : 8'h00),
                                        ((board.EP.m_axi_wstrb[9] == 1'b1) ? board.EP.m_axi_wdata[79:72] : 8'h00),
                                        ((board.EP.m_axi_wstrb[8] == 1'b1) ? board.EP.m_axi_wdata[71:64] : 8'h00),
                                        ((board.EP.m_axi_wstrb[7] == 1'b1) ? board.EP.m_axi_wdata[63:56] : 8'h00),
                                        ((board.EP.m_axi_wstrb[6] == 1'b1) ? board.EP.m_axi_wdata[55:48] : 8'h00),
                                        ((board.EP.m_axi_wstrb[5] == 1'b1) ? board.EP.m_axi_wdata[47:40] : 8'h00),
                                        ((board.EP.m_axi_wstrb[4] == 1'b1) ? board.EP.m_axi_wdata[39:32] : 8'h00),
                                        ((board.EP.m_axi_wstrb[3] == 1'b1) ? board.EP.m_axi_wdata[31:24] : 8'h00),
                                        ((board.EP.m_axi_wstrb[2] == 1'b1) ? board.EP.m_axi_wdata[23:16] : 8'h00),
                                        ((board.EP.m_axi_wstrb[1] == 1'b1) ? board.EP.m_axi_wdata[15:8] : 8'h00),
                                        ((board.EP.m_axi_wstrb[0] == 1'b1) ? board.EP.m_axi_wdata[7:0] : 8'h00)};
               endcase
               $display ("--- H2C data at QDMA = %h ---\n", READ_DATA[i]);

            end
      end
*/


      //Sampling stored data from User TB in reg

      k = 0;
/* IMPL SIM
      case (board.EP.C_DATA_WIDTH)

            64: 
                begin
                  for (i = 0; i < data_beat_count; i = i + 1)   begin
                    for (j=7; j>=0; j=j-1) begin
                      DATA_STORE_512[i] = {DATA_STORE_512[i], DATA_STORE[address+k+j]};
                    end
                    k=k+8;

                    $display ("--- Data Stored in TB for H2C Transfer = %h ---\n", DATA_STORE_512[i]);
                  end
                end

           128: 
                begin
                for (i = 0; i < data_beat_count; i = i + 1)   begin
                    for (j=15; j>=0; j=j-1) begin
                    DATA_STORE_512[i] = {DATA_STORE_512[i], DATA_STORE[address+k+j]};
                    end

                    k=k+16;

                    $display ("-- Data Stored in TB for H2C Transfer = %h--\n", DATA_STORE_512[i]);
                  end
                end
                
           256: 
                begin
                  for (i = 0; i < data_beat_count; i = i + 1)   begin
                    for (j=31; j>=0; j=j-1) begin 
                      DATA_STORE_512[i] = {DATA_STORE_512[i], DATA_STORE[address+k+j]};
                    end
                  
                    k=k+32;
                  
                    $display ("-- Data Stored in TB for H2C Transfer = %h--\n", DATA_STORE_512[i]);
                  end
                end
            512: 
                begin
                  for (i = 0; i < data_beat_count; i = i + 1)   begin
                    for (j=63; j>=0; j=j-1) begin 
                      DATA_STORE_512[i] = {DATA_STORE_512[i], DATA_STORE[address+k+j]};
                    end
             
                    k=k+64;
             
                    $display ("-- Data Stored in TB for H2C Transfer = %h--\n", DATA_STORE_512[i]);
                  end
                end



      endcase
*/
      //Compare sampled data from QDMA with stored TB data
      
      for (i=0; i<data_beat_count; i=i+1)   begin
      
        if (READ_DATA[i] == DATA_STORE_512[i]) begin
          matched_data_counter = matched_data_counter + 1;
        end else
          matched_data_counter = matched_data_counter;
      end
      
      if (matched_data_counter == data_beat_count) begin
        $display ("*** H2C Transfer Data MATCHES ***\n");
        $display("[%t] : QDMA H2C Test Completed Successfully",$realtime);
      end else
        $display ("[%t] : TEST FAILED ---***ERROR*** H2C Transfer Data MISMATCH ---\n",$realtime);
    
  end
           
endtask

/************************************************************
Task : COMPARE_DATA_C2H_
Inputs : Number of Payload Bytes
Outputs : None
Description : Compare Data received and stored at RP - user TB with the data sent for H2C transfer from RP - user TB
*************************************************************/

task COMPARE_DATA_C2H;

  input [31:0] payload_bytes ;
  input integer  address;
  
  reg [511:0] READ_DATA_C2H_512 [(DMA_BYTE_CNT/8):0];
  reg [511:0] DATA_STORE_512 [(DMA_BYTE_CNT/8):0];

  integer matched_data_counter;
  integer i, j, k;
  integer data_beat_count;
  integer cq_data_beat_count;
  integer cq_valid_wait_cnt;
  begin

    matched_data_counter = 0;

//    for (k = 0; k < DMA_BYTE_CNT; k = k + 1)  begin
//        $display(" **** H2C data *** data = %h, addr= %d\n", DATA_STORE[address+k], address+k);
//    end
    //Calculate number of beats for payload sent

    data_beat_count = ((payload_bytes % 32'h40) == 0) ? (payload_bytes/32'h40) : ((payload_bytes/32'h40)+32'h1);
    cq_data_beat_count = ((((payload_bytes-32'h30) % 32'h40) == 0) ? ((payload_bytes-32'h30)/32'h40) : (((payload_bytes-32'h30)/32'h40)+32'h1)) + 32'h1;
    $display ("payload_bytes = %h, data_beat_count = %h\n", payload_bytes, data_beat_count);
    
    //Sampling CQ data payload on RP	
    if(testname =="dma_stream0") begin
        cq_valid_wait_cnt = 3;
    end else begin
        cq_valid_wait_cnt = 1;
    end
        for (i=0; i<cq_valid_wait_cnt; i=i+1)   begin
            @ (posedge board.RP.m_axis_cq_tvalid) ;             //1st tvalid - Descriptor Read Request
        end
            @ (posedge board.RP.m_axis_cq_tvalid) ;         //2nd tvalid - CQ on RP receives Data from QDMA

               for (i=0; i<cq_data_beat_count; i=i+1)   begin

                 @ (negedge user_clk);						//Samples data at negedge of user_clk

                    if ( board.RP.m_axis_cq_tready ) begin	//Samples data when tready is high
                      //$display ("--m_axis_cq_tvalid = %d, m_axis_cq_tready = %d, i = %d--\n", board.RP.m_axis_cq_tvalid, board.RP.m_axis_cq_tready, i);

                      if ( i == 0) begin					//First Data Beat

                        READ_DATA_C2H_512[i][511:0]   = board.RP.m_axis_cq_tdata [511:128];

                      end else begin						//Second and Subsequent Data Beat

                         //$display ("m_axis_cq_tkeep = %h\n", board.RP.m_axis_cq_tkeep);

                        case (board.RP.m_axis_cq_tkeep)
                             16'h0001: begin READ_DATA_C2H_512[i-1][511:384] = {96'b0,board.RP.m_axis_cq_tdata [31:0]};   /*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[2*i-1]);*/ end
                             16'h0003: begin READ_DATA_C2H_512[i-1][511:384] = {64'b0,board.RP.m_axis_cq_tdata [63:0]};   /*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[2*i-1]);*/ end
                             16'h0007: begin READ_DATA_C2H_512[i-1][511:384] = {32'b0,board.RP.m_axis_cq_tdata [95:0]};   /*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[2*i-1]);*/ end
                             16'h000F: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0];  /*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[2*i-1]);*/ end
                             16'h001F: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {480'b0,board.RP.m_axis_cq_tdata [159:128]};/*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[i-1]);*/ end
                             16'h003F: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {448'b0,board.RP.m_axis_cq_tdata [191:128]};/*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[i-1]);*/ end
                             16'h007F: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {416'b0,board.RP.m_axis_cq_tdata [223:128]};/*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[i-1]);*/ end
                             16'h00FF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {384'b0,board.RP.m_axis_cq_tdata [255:128]};/*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[i-1]);*/ end
                             16'h01FF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {352'b0,board.RP.m_axis_cq_tdata [287:128]};/*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[i-1]);*/ end
                             16'h03FF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {320'b0,board.RP.m_axis_cq_tdata [319:128]};/*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[i-1]);*/ end
                             16'h07FF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {288'b0,board.RP.m_axis_cq_tdata [351:128]};/*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[i-1]);*/ end
                             16'h0FFF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {256'b0,board.RP.m_axis_cq_tdata [383:128]};/*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[i-1]);*/ end
                             16'h1FFF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {224'b0,board.RP.m_axis_cq_tdata [415:128]};/*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[i-1]);*/ end
                             16'h3FFF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {192'b0,board.RP.m_axis_cq_tdata [447:128]};/*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[i-1]);*/ end
                             16'h7FFF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {160'b0,board.RP.m_axis_cq_tdata [479:128]};/*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[i-1]);*/ end
                             16'hFFFF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {128'b0,board.RP.m_axis_cq_tdata [511:128]};/*$display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[i-1]);*/ end
                             default: begin READ_DATA_C2H_512[i] = 512'b0;/* $display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[2*i]);*/ end
                        endcase

                      end

                    end

               end

        //Sampling stored data from User TB in 256 bit reg
        k = 0;
        for (i = 0; i < data_beat_count; i = i + 1)   begin
          $display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[i]);
        end
        
        for (i = 0; i < data_beat_count; i = i + 1)   begin
            for (j=63; j>=0; j=j-1) begin
                DATA_STORE_512[i] = {DATA_STORE_512[i], DATA_STORE[address+k+j]};
            end
            k=k+64;
            $display ("-- Data Stored in TB = %h--\n", DATA_STORE_512[i]);
        end

        //Compare sampled data from CQ with stored TB data

        for (i=0; i<data_beat_count; i=i+1)   begin
          if (READ_DATA_C2H_512[i] == DATA_STORE_512[i]) begin
            matched_data_counter = matched_data_counter + 1;
          end else
            matched_data_counter = matched_data_counter;
        end

        if (matched_data_counter == data_beat_count) begin
            $display ("*** C2H Transfer Data MATCHES ***\n");
            $display("[%t] : QDMA C2H Test Completed Successfully",$realtime);
        end else begin
            $display ("[%t] : TEST FAILED ---***ERROR*** C2H Transfer Data MISMATCH ---\n",$realtime);
        end

  end

endtask

/************************************************************
Task : COMPARE_TRNS_STATUS
Inputs : Number of Payload Bytes
Outputs : None
Description : Compare Data received and stored at RP - user TB with the data sent for H2C transfer from RP - user TB
*************************************************************/

task COMPARE_TRANS_STATUS;

   input [31:0] status_addr ;
   input [16:0] exp_cidx;
  
   integer 	i, j, k;
   integer 	status_found;
   integer 	loop_count;
   reg [15:0] 	cidx;
   
   
   begin
      
//    for (k = 0; k < DMA_BYTE_CNT; k = k + 1)  begin
//        $display(" **** H2C data *** addr = %d, data= %h\n", 512+k, DATA_STORE[512+k]);
//    end

      status_found = 0;
      loop_count = 0;
      cidx = 0;
      while  ((exp_cidx != cidx) && (loop_count < 10))begin
	 loop_count = loop_count +1;
	 wait (board.RP.m_axis_cq_tvalid == 1'b1) ;          //1st tvalid after data	 
	
	 @ (negedge user_clk);						//Samples data at negedge of user_clk
	 
	 if ( board.RP.m_axis_cq_tready ) begin
	    
	    if (board.RP.m_axis_cq_tdata [31:0] == status_addr[31:0]) begin  // Address match
               cidx = cidx + board.RP.m_axis_cq_tdata [159:144];
	    end
	 end
      end
      
      if (exp_cidx == cidx ) 
        $display ("*** Write Back Status matches expected value : %h\n", cidx);
      else
        $display ("[%t] : TEST FAILED ---***ERROR*** Write Back Status NO matches expected value : %h, got %h \n",$realtime, exp_cidx, cidx);
      
   end

endtask

/************************************************************
Task : COMPARE_TRNS_C2H_ST_STATUS
Inputs : Number of Payload Bytes
Outputs : None
Description : Compare Data received and stored at RP - user TB with the data sent for H2C transfer from RP - user TB
*************************************************************/

task COMPARE_TRANS_C2H_ST_STATUS;

   input [31:0] status_addr ;
   input [16:0] exp_pidx;
  
   integer 	i, j, k;
   integer 	status_found;
   integer 	loop_count;
   reg [15:0] 	pidx;
   reg [21:0] 	len;
   reg [31:0]   wrb_status_addr ;
   
   begin
     len = board.RP.m_axis_cq_tdata [147:132];
      // get transfere length
     while(board.RP.m_axis_cq_tdata [31:0] != status_addr[31:0]) begin
	 wait (board.RP.m_axis_cq_tvalid == 1'b1) ;          //1st tvalid after data	 
	 @ (negedge user_clk);	 						//Samples data at negedge of user_clk
	 if ( board.RP.m_axis_cq_tready ) begin
	    if (board.RP.m_axis_cq_tdata [31:0] == status_addr[31:0]) begin  // Address match
               len = board.RP.m_axis_cq_tdata [147:132];
	    end
	 end
     end
      
      if (len[15:0] == DMA_BYTE_CNT[15:0] ) 
        $display ("*** C2H transfer Length matches with expected value : %h\n", len);
      else
        $display ("[%t] : TEST FAILED ---***ERROR*** C2H transfer length does not matche expected value : %h, got %h \n",$realtime, DMA_BYTE_CNT[15:0], len);
      // get writeback Pidx
      //
      wrb_status_addr = status_addr[31:0] +(15*8);
      status_found = 0;
      loop_count = 0;
      pidx = 0;
      while  ((exp_pidx != pidx) && (loop_count < 10))begin
	 loop_count = loop_count +1;
	 wait (board.RP.m_axis_cq_tvalid == 1'b1) ;             //1st tvalid - Descriptor Read Request
	
	 @ (negedge user_clk);						//Samples data at negedge of user_clk
	 
	 if ( board.RP.m_axis_cq_tready ) begin
	    if (board.RP.m_axis_cq_tdata [31:0] == wrb_status_addr[31:0]) begin  // Address match
               pidx = pidx + board.RP.m_axis_cq_tdata [143:128];
	    end
	 end
      end
      
      if (exp_pidx == pidx ) 
        $display ("*** Write Back Status matches expected value : %h\n", pidx);
      else
        $display ("[%t] : TEST FAILED ---***ERROR*** Write Back Status NO matches expected value : %h, got %h \n",$realtime, exp_pidx, pidx);
      
   end

endtask
/************************************************************
Task : TSK_FIND_USR_BAR
Description : Find User BAR 
*************************************************************/

task TSK_FIND_USR_BAR;
   begin
      
   user_bar =2;   
//      board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h10C);
//      case (P_READ_DATA[5:0])
//	6'b000001 : user_bar =0;
//	6'b000010 : user_bar =1;
//	6'b000100 : user_bar =2;
//	default : user_bar = 0;
//      endcase // case (P_READ_DATA[5:0])
   end
endtask // TSK_FIND_USR_BAR

endmodule // pci_exp_usrapp_tx
