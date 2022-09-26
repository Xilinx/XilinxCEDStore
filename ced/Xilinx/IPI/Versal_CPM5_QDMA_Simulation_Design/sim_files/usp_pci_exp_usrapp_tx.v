// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
//  http://www.apache.org/licenses/LICENSE-2.0
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
  parameter        AXI4_CQ_TUSER_WIDTH            = 465,
  parameter        AXI4_CC_TUSER_WIDTH            = 165,
  parameter        AXI4_RQ_TUSER_WIDTH            = 373,
  parameter        AXI4_RC_TUSER_WIDTH            = 337,
  parameter        KEEP_WIDTH                        = C_DATA_WIDTH / 32,
  parameter        PARITY_WIDTH                      = C_DATA_WIDTH / 8,
  parameter        STRB_WIDTH                        = C_DATA_WIDTH / 8,
  parameter        EP_DEV_ID                         = 16'h7700,
  parameter        REM_WIDTH                         = 4,
  parameter  [5:0] RP_BAR_SIZE                       = 6'd11                  // Number of RP BAR's Address Bit - 1
)
(
  output reg                                 s_axis_rq_tlast,
  output reg      [C_DATA_WIDTH-1:0]         s_axis_rq_tdata,
  output          [AXI4_RQ_TUSER_WIDTH-1:0]                    s_axis_rq_tuser,
  output reg      [KEEP_WIDTH-1:0]           s_axis_rq_tkeep,
  input                                      s_axis_rq_tready,
  output reg                                 s_axis_rq_tvalid,

  output reg      [C_DATA_WIDTH-1:0]         s_axis_cc_tdata,
  output reg      [AXI4_CC_TUSER_WIDTH:0]                     s_axis_cc_tuser,
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
localparam  [11:0] VC_EXT_CAP_OFFSET       = 12'h1F0;
localparam   [15:0] DMA_BYTE_CNT = 16'h0080;

localparam   [4:0] LINK_CAP_MAX_LINK_WIDTH = 5'h8;
localparam   [4:0] LINK_CAP_MAX_LINK_SPEED = 5'h10;
localparam   [3:0] MAX_LINK_SPEED          = (LINK_CAP_MAX_LINK_SPEED==5'h10) ? 4'h5 : (LINK_CAP_MAX_LINK_SPEED==5'h8) ? 4'h4 : (LINK_CAP_MAX_LINK_SPEED==5'h4) ? 4'h3 : ((LINK_CAP_MAX_LINK_SPEED==5'h2) ? 4'h2 : 4'h1);
localparam   [5:0] BAR_ENABLED             = 6'b1;
localparam  [11:0] LINK_CTRL_REG_ADDR = 12'h080;
localparam  [11:0] PCIE_DEV_CAP_ADDR  = 12'h074;
localparam  [11:0] DEV_CTRL_REG_ADDR  = 12'h078;
localparam  NUMBER_OF_PFS = 1; //1;
localparam  NUM_FN=9'h1;
localparam  QUEUE_PER_PF     = 32;
reg        [31:0] MSIX_VEC_OFFSET [NUM_FN-1:0];
reg        [31:0] MSIX_PBA_OFFSET [NUM_FN-1:0];
reg        [2:0] MSIX_VEC_BAR [NUM_FN-1:0];
reg        [2:0] MSIX_PBA_BAR [NUM_FN-1:0];
reg        [10:0] MSIX_TABLE_SIZE [NUM_FN-1:0];
reg        [(C_DATA_WIDTH - 1):0]            pcie_tlp_data;
reg        [(REM_WIDTH - 1):0]               pcie_tlp_rem;
integer                                      xdma_bar = 0;
integer                                      user_bar = 0;

localparam C_NUM_USR_IRQ       = 16;
localparam MSIX_CTRL_REG_ADDR  = 12'h060;
localparam MSIX_VEC_TABLE_A    = 12'h64;
localparam MSIX_PBA_TABLE_A    = 12'h68;
localparam QUEUE_PTR_PF_ADDR   = 32'h00018000;
localparam CMPT_ADDR           = 32'h3000;
localparam H2C_ADDR            = 32'h1000;
localparam C2H_ADDR            = 32'h2000;

/* Local Variables */
integer                         i, j, k;
reg     [7:0]                   DATA_STORE   [16383:0]; // For Downstream Direction Data Storage
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
wire    [PARITY_WIDTH-1:0]      s_axis_cc_tparity;
wire    [PARITY_WIDTH-1:0]      s_axis_rq_tparity;

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
reg     [AXI4_RQ_TUSER_WIDTH-1:0]                 s_axis_rq_tuser_wo_parity;
reg     [16:0]                  MM_wb_sts_pidx;
reg     [16:0]                  MM_wb_sts_cidx;
reg     [10:0] 			axi_mm_q;
reg     [10:0] 			axi_st_q;
reg     [10:0] 			axi_st_q_phy;
reg     [10:0] 			pf0_qmax;
reg     [10:0] 			pf1_qmax;
reg     [255:0] 		wr_dat;
reg     [31:0] 			wr_add;
reg [15:0] 			data_tmp = 0;
reg                             test_state =0;
reg [10:0]                      qid;
reg [7:0] 			fnc = 8'h0;
   
//assign s_axis_rq_tuser = {(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0),s_axis_rq_tuser_wo_parity[72:0]};
assign s_axis_rq_tuser = s_axis_rq_tuser_wo_parity;

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
  EP_DEV_ID1 = 16'hB03F;
  if ( pfIndex == 1)
  EP_DEV_ID1 = 16'hB13F;
  if ( pfIndex == 2)
  EP_DEV_ID1 = 16'hB23F;
  if ( pfIndex == 3)
  EP_DEV_ID1 = 16'hB33F;

  DEV_VEN_ID                = (EP_DEV_ID1 << 16) | (32'h10EE);
  EP_BUS_DEV_FNS      = {EP_BUS_DEV_FNS_INIT[15:2], pfIndex[1:0]};

  board.RP.tx_usrapp.TSK_SYSTEM_INITIALIZATION;
  board.RP.tx_usrapp.TSK_BAR_INIT;

  // Find which BAR is XDMA BAR and assign 'xdma_bar' variable
  board.RP.tx_usrapp.TSK_XDMA_FIND_BAR;

  // Find which BAR is USR BAR and assign 'user_bar' variable
      board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h00);
      if (P_READ_DATA[31:16] == 16'h1fd3) begin    // QDMA
           board.RP.tx_usrapp.TSK_FIND_USR_BAR;
      end

  if ($value$plusargs("TESTNAME=%s", testname))
      $display("Running test {%0s}......", testname);
  else begin

     //decide if QDMA or XDMA
      board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h00);
      if (P_READ_DATA[31:16] == 16'h1fd3) begin    // QDMA
         testname = "qdma_mm_test0";
         $display("*** Running QDMA AXI-MM test for PF{%d}, test_name = {%0s}......", pfIndex, testname);
      end
      else begin     // XDMA
        // decide if AXI-MM or AXI-ST
        board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h00);
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
   // logic to store received data

   reg [15:0] rcv_data[0:16384];
   reg 	       cq_wr;
   reg [3:0]   count;
   wire [15:0] tmp_data_0;
   wire [15:0] tmp_data_1;
   wire [15:0] tmp_data_2;
   wire [15:0] tmp_data_0_1;
   wire [15:0] tmp_data_1_1;
   wire [15:0] tmp_data_2_1;
   reg [15:0] 	cq_addr;
   reg 		tvalid_d;
   wire [15:0] 	cq_addr_fst;
   wire [7:0] 	xfr_len;
   
   always @(posedge user_clk) begin
	tvalid_d <= board.RP.m_axis_cq_tvalid & board.RP.m_axis_cq_tready;
   end
   assign cq_addr_fst = (board.RP.m_axis_cq_tvalid & board.RP.m_axis_cq_tready & ~tvalid_d) ? board.RP.m_axis_cq_tdata[15:0] : 16'h0;
   assign xfr_len = (board.RP.m_axis_cq_tvalid & board.RP.m_axis_cq_tready & ~tvalid_d) ? board.RP.m_axis_cq_tdata[71:64] : 8'h0;
   
   
   always @(posedge user_clk) begin
      if (reset) begin
	 cq_wr <= 0;
	 count <= 0;
	 cq_addr <= 0;
      end
      else if (board.RP.m_axis_cq_tvalid & board.RP.m_axis_cq_tready & (cq_wr | board.RP.m_axis_cq_tdata[75])) begin
	 cq_wr <= 1'b1;
	 
	 count <= count+1;
	 if (count == 0) begin
	    for (i = 8; i < 32; i= i+1) begin
	       rcv_data[cq_addr_fst + (i-8)] <=  board.RP.m_axis_cq_tdata[i*16 +: 16];
	       if (i == 31)
		 cq_addr <= cq_addr_fst + 24;
	       //$display ("addr = %d, data 0 %h\n", (cq_addr_fst+ (i-8)), board.RP.m_axis_cq_tdata[i*16 +: 16]);
	    end
	 end
	 else begin
	    for (i = 0; i < 32; i= i+1) begin
	       rcv_data[cq_addr + i] <=  board.RP.m_axis_cq_tdata[i*16 +: 16];
	       if (i == 31)
		 cq_addr <= cq_addr + 32;
	       //$display ("addr = %d, data %h\n", (cq_addr+i), board.RP.m_axis_cq_tdata[i*16 +: 16]);
	    end
	 end
      end
      else begin
	 cq_wr <= 0;
	 count <= 0;
      end
   end
   
   assign   tmp_data_0 = rcv_data[2048];
   assign   tmp_data_1 = rcv_data[2049];
   assign   tmp_data_2 = rcv_data[2050];
   assign   tmp_data_0_1 = rcv_data[2051];
   assign   tmp_data_1_1 = rcv_data[2052];
   assign   tmp_data_2_1 = rcv_data[2053];

//--------------------------------------------------------------------------------------------------------

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


task TSK_QDMA_MM_H2C_TEST;
   input [10:0] qid;
   input dsc_bypass;
   input irq_en;

   reg [11:0] q_count;
   reg [10:0] q_base;
   reg [15:0] pidx;
   localparam NUM_ITER = 1; // Max 8
   integer    iter;
begin

	//----------------------------------------------------------------------------------------
	// QDMA AXI-MM H2C Test Starts
	//----------------------------------------------------------------------------------------
    $display("------AXI-MM H2C Tests start--------\n");

    $display(" **** read Address at BAR0  = %h\n", board.RP.tx_usrapp.BAR_INIT_P_BAR[0][31:0]);
    $display(" **** read Address at BAR1  = %h\n", board.RP.tx_usrapp.BAR_INIT_P_BAR[1][31:0]);

    // Global programming
    //
    // Assign Q 0 for AXI-MM
    axi_mm_q = qid;
    q_base   = QUEUE_PER_PF * fnc;
    q_count  = QUEUE_PER_PF;
    EP_BUS_DEV_FNS      = {EP_BUS_DEV_FNS_INIT[15:2], fnc};
    pidx = 0;

    //-------------- Load DATA in Buffer ----------------------------------------------------
    // H2C DSC start at 0x0100 (256)
    // H2C data start at 0x0300 (768)
      board.RP.tx_usrapp.TSK_INIT_QDMA_MM_DATA_H2C;

	//-------------- DMA Engine ID Read -----------------------------------------------------
      board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h00);
      
    // enable dsc bypass loopback
    if (dsc_bypass)
       board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h90, 32'h3, 4'hF);

   // initilize all ring size to some value.
    //-------------- Global Ring Size for Queue 0  0x204  : num of dsc 16 ------------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h204, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h208, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h20C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h210, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h214, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h218, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h21C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h220, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h224, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h228, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h22C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h230, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h234, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h238, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h23C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h240, 32'h00000010, 4'hF);

    //-------------- Ind Dire CTXT MASK 0x814  0xffffffff for all 128 bits -------------------
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h824, 32'hffffffff, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h828, 32'hffffffff, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h82C, 32'hffffffff, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h830, 32'hffffffff, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h834, 32'hffffffff, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h838, 32'hffffffff, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h83C, 32'hffffffff, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h840, 32'hffffffff, 4'hF);

    //-------------- Clear HW CXTX for H2C for Qid -----------------------------------------
    wr_dat[31:18] = 'h0; // reserved
    wr_dat[17:7]  = axi_mm_q[10:0]; // qid
    wr_dat[6:5]   = 2'h0; // MDMA_CTXT_CMD_CLR
    wr_dat[4:1]   = 4'h3; // MDMA_CTXT_SELC_DSC_HW_H2C
    wr_dat[0]     = 'h0;
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

    //-------------- Global Function MAP 0x400  : Func0 22:11 Qnumber ( 16 Queue ) : 10:0 Qid_base for this Func
     wr_dat[31:0]   = 32'h0 | q_base;
     wr_dat[63:32]  = 32'h0 | q_count;
     wr_dat[255:64] = 'h0;

    TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0 ], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

    wr_dat[31:18] = 'h0; // reserved
    wr_dat[17:7]  = 11'h0 | fnc[7:0]; // fnc
    wr_dat[6:5]   = 2'h1; // MDMA_CTXT_CMD_WR
    wr_dat[4:1]   = 4'hC; // QDMA_CTXT_SELC_FMAP
    wr_dat[0]     = 'h0;
    TSK_REG_WRITE(xdma_bar, 32'h844, wr_dat[31:0], 4'hF);

    if (irq_en == 1'b1) begin
       TSK_PROGRAM_MSIX_VEC_TABLE (0); 
    end

    // AXI-MM Transfer start
    $display(" *** QDMA H2C *** \n");

    //-------------- Ind Direct AXI-MM H2C CTXT DATA -------------------
    wr_dat[255:140] = 'd0;
    wr_dat[139]     = 'd0;    // int_aggr
    wr_dat[138:128] = 'd1;    // vec MSI-X Vector
    wr_dat[127:64]  =  (64'h0 | H2C_ADDR); // dsc base
    wr_dat[63]      =  1'b1;  // is_mm
    wr_dat[62]      =  1'b0;  // mrkr_dis
    wr_dat[61]      =  1'b0;  // irq_req
    wr_dat[60]      =  1'b0;  // err_wb_sent
    wr_dat[59:58]   =  2'b0;  // err        
    wr_dat[57]      =  1'b0;  // irq_no_last
    wr_dat[56:54]   =  3'h0;  // port_id
    wr_dat[53]      =  irq_en;  // irq_en     
    wr_dat[52]      =  1'b1;  // wbk_en     
    wr_dat[51]      =  1'b0;  // mm_chn     
    wr_dat[50]      =  dsc_bypass ? 1'b1 : 1'b0;  // bypass     
    wr_dat[49:48]   =  2'b10; // dsc_sz, 32bytes     
    wr_dat[47:44]   =  4'h1;  // rng_sz     
    wr_dat[43:41]   =  3'h0;  // reserved
    wr_dat[40:37]   =  4'h0;  // fetch_max
    wr_dat[36]      =  1'b0;  // atc
    wr_dat[35]      =  1'b0;  // wbi_intvl_en
    wr_dat[34]      =  1'b1;  // wbi_chk    
    wr_dat[33]      =  1'b0;  // fcrd_en    
    wr_dat[32]      =  1'b1;  // qen        
    wr_dat[31:25]   =  7'h0;  // reserved
    wr_dat[24:17]   =  {4'h0,pfTestIteration[3:0]}; // func_id        
    wr_dat[16]      =  1'b0;  // irq_arm    
    wr_dat[15:0]    =  16'b0; // pidx

    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0 ], 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32], 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64], 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

     //board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h804);  //Read
     //board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h808);  //Read
     //board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h80C);  //Read
     //board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h810);  //Read

     //board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h6404);  //Read

    //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------	
    // [17:7] QID   00
    // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
    // [4:1]  MDMA_CTXT_SELC_DSC_SW_H2C = 1 : 0001
    // 0      BUSY : 0 
    //        00000000000_01_0001_0 : 0x22
    wr_dat = {14'h0,axi_mm_q[10:0],7'b0100010};
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

    //-------------- ARM H2C transfer 0x1204 MDMA_H2C_MM0_CONTROL set to run--------
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h1204, 32'h00000001, 4'hF);
      
    //-------------- Start DMA tranfer ------------------------------------------------------
      $display(" **** Start AXI-MM H2C transfer ***\n");

    for (iter=0; iter < NUM_ITER; iter=iter+1) begin
      fork
        //-------------- Writ PIDX to 1 to transfer 1 descriptor ----------------
        //write address
        pidx = pidx +1;

        wr_add = QUEUE_PTR_PF_ADDR + (axi_mm_q* 16) + 4;  // 32'h00006404
        board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], {irq_en, pidx[15:0]} | 32'h0, 4'hF);   // Write 1 PIDX 

        //-------------- compare H2C data -------------------------------------------------------
        $display("------Compare H2C AXI-MM Data--------\n");
        board.RP.tx_usrapp.COMPARE_DATA_H2C({16'h0,board.RP.tx_usrapp.DMA_BYTE_CNT},768);    //input payload bytes
      join
    
      board.RP.tx_usrapp.COMPARE_TRANS_STATUS(32'h000011E0, pidx[15:0]); 

      board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h1248);
      $display ("**** H2C Decsriptor Count = %h\n", P_READ_DATA);
    end 
    
    $display("------AXI-MM H2C Completed--------\n");
    #1000;
end
endtask

task TSK_QDMA_MM_C2H_TEST;
   input [10:0] qid;
   input dsc_bypass;
   input irq_en;

   reg [11:0] q_count;
   reg [10:0] q_base;
   reg [15:0] pidx;
   localparam NUM_ITER = 1; // Max 8
   integer    iter;
begin

    //------------- This test performs a 32 bit write to a 32 bit Memory space and performs a read back

	//----------------------------------------------------------------------------------------
	// QDMA AXI-MM C2H Test Starts
	//----------------------------------------------------------------------------------------
    $display("------AXI-MM C2H Tests start--------\n");

    $display(" **** read Address at BAR0  = %h\n", board.RP.tx_usrapp.BAR_INIT_P_BAR[0][31:0]);
    $display(" **** read Address at BAR1  = %h\n", board.RP.tx_usrapp.BAR_INIT_P_BAR[1][31:0]);

    // Global programming
    //
    // Assign Q 0 for AXI-MM
    axi_mm_q = qid;
    q_base   = QUEUE_PER_PF * fnc;
    q_count  = QUEUE_PER_PF;
    pidx = 0;

    //-------------- Load DATA in Buffer ----------------------------------------------------
    // H2C DSC start at 0x0100 (256)
    // H2C data start at 0x0300 (768)
//      board.RP.tx_usrapp.TSK_INIT_QDMA_MM_DATA_H2C;

	//-------------- DMA Engine ID Read -----------------------------------------------------
      board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h00);
      
    // enable dsc bypass loopback
    if (dsc_bypass)
       board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h90, 32'h3, 4'hF);

   // initilize all ring size to some value.
    //-------------- Global Ring Size for Queue 0  0x204  : num of dsc 16 ------------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h204, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h208, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h20C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h210, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h214, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h218, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h21C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h220, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h224, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h228, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h22C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h230, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h234, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h238, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h23C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h240, 32'h00000010, 4'hF);

    //-------------- Clear HW CXTX for C2H for Qid -----------------------------------------
    wr_dat[31:18] = 'h0; // reserved
    wr_dat[17:7]  = axi_mm_q[10:0]; // qid
    wr_dat[6:5]   = 2'h0; // MDMA_CTXT_CMD_CLR
    wr_dat[4:1]   = 4'h2; // MDMA_CTXT_SELC_DSC_HW_C2H
    wr_dat[0]     = 'h0;
   
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

    // FMAP programing. set up 16Queues
     wr_dat[31:0]   = 32'h0 | q_base;
     wr_dat[63:32]  = 32'h0 | q_count;
     wr_dat[255:64] = 'h0;

    TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0 ], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

    wr_dat[31:18] = 'h0; // reserved
    wr_dat[17:7]  = 11'h0 | fnc[7:0]; // fnc
    wr_dat[6:5]   = 2'h1; // MDMA_CTXT_CMD_WR
    wr_dat[4:1]   = 4'hC; // QDMA_CTXT_SELC_FMAP
    wr_dat[0]     = 'h0;
    TSK_REG_WRITE(xdma_bar, 32'h844, wr_dat[31:0], 4'hF);

    //	  for(pf_loop_index=0; pf_loop_index <= pfTestIteration; pf_loop_index = pf_loop_index + 1)
    //	  begin
    //	     if(pf_loop_index == pfTestIteration) begin
    //	        board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), 32'h00008000, 4'hF);
    //		 end else begin 
    //		    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), 32'h00000000, 4'hF);
    //		 end
    //    end
    if (irq_en == 1'b1) begin
       TSK_PROGRAM_MSIX_VEC_TABLE (0); 
    end

    //-------------- Ind Dire CTXT MASK 0x814  0xffffffff for all 128 bits -------------------
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h824, 32'hffffffff, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h828, 32'hffffffff, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h82C, 32'hffffffff, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h830, 32'hffffffff, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h834, 32'hffffffff, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h838, 32'hffffffff, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h83C, 32'hffffffff, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h840, 32'hffffffff, 4'hF);

    //-------------- Load DATA in Buffer ----------------------------------------------------
    // C2H DSC starts at 0x0800 (2048)
    // C2H data starts at 0x0A00 (2560)
      board.RP.tx_usrapp.TSK_INIT_QDMA_MM_DATA_C2H;

    //-------------- Ind Direer AXI-MM C2H CTXT DATA -------------------
    wr_dat[255:140] = 'd0;
    wr_dat[139]     = 'd0;    // int_aggr
    wr_dat[138:128] = 'd2;    // vec MSI-X Vector
    wr_dat[127:64]  =  (64'h0 | C2H_ADDR); // dsc base
    wr_dat[63]      =  1'b1;  // is_mm
    wr_dat[62]      =  1'b0;  // mrkr_dis
    wr_dat[61]      =  1'b0;  // irq_req
    wr_dat[60]      =  1'b0;  // err_wb_sent
    wr_dat[59:58]   =  2'b0;  // err        
    wr_dat[57]      =  1'b0;  // irq_no_last
    wr_dat[56:54]   =  3'h0;  // port_id
    wr_dat[53]      =  irq_en;  // irq_en     
    wr_dat[52]      =  1'b1;  // wbk_en     
    wr_dat[51]      =  1'b0;  // mm_chn     
    wr_dat[50]      =  dsc_bypass ? 1'b1 : 1'b0;  // bypass     
    wr_dat[49:48]   =  2'b10; // dsc_sz, 32bytes     
    wr_dat[47:44]   =  4'h1;  // rng_sz     
    wr_dat[43:40]   =  4'h0;  // reserved
    wr_dat[39:37]   =  3'h0;  // fetch_max
    wr_dat[36]      =  1'b0;  // atc
    wr_dat[35]      =  1'b0;  // wbi_intvl_en
    wr_dat[34]      =  1'b1;  // wbi_chk    
    wr_dat[33]      =  1'b0;  // fcrd_en    
    wr_dat[32]      =  1'b1;  // qen        
    wr_dat[31:25]   =  7'h0;  // reserved
    wr_dat[24:17]   =  {4'h0,pfTestIteration[3:0]}; // func_id        
    wr_dat[16]      =  1'b0;  // irq_arm    
    wr_dat[15:0]    =  16'b0; // pidx

    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0] , 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32], 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64], 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

    //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 1 [17:7] : CMD MDMA_CTXT_CMD_WR=1 ---------	
    // [17:7] QID   00
    // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
    // [4:1]  MDMA_CTXT_SELC_DSC_SW_C2H = 0 : 0000
    // 0      BUSY : 0 
    //        00000000000_01_0000_0 : 0010_0000 : 0x20
    wr_dat = {14'h0,axi_mm_q[10:0],7'b0100000};
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

    //-------------- ARM C2H transfer 0x1004 MDMA_C2H_MM0_CONTROL set to run--------
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h1004, 32'h00000001, 4'hF);
      
    //-------------- Start DMA tranfer ------------------------------------------------------
      $display(" **** Start DMA C2H transfer ***\n");

    for (iter=0; iter < NUM_ITER; iter=iter+1) begin
      fork
        //-------------- Write PIDX to 1 to transfer 1 descriptor in C2H ----------------
        pidx = pidx + 1;
        wr_add = QUEUE_PTR_PF_ADDR + (axi_mm_q* 16) + 8;  // 32'h00006408    
        board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], {irq_en, pidx[15:0]} | 32'h0, 4'hF); // Write 1 PIDX 

        //compare C2H data
        $display("------Compare C2H AXI-MM Data--------\n");
        // for coparision H2C data is stored in 768
        board.RP.tx_usrapp.COMPARE_DATA_C2H({16'h0,board.RP.tx_usrapp.DMA_BYTE_CNT},768);
      join

      board.RP.tx_usrapp.COMPARE_TRANS_STATUS(32'h000021E0, pidx[15:0]); 

      board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h1048);
      $display ("**** C2H Decsriptor Count = %h\n", P_READ_DATA);
    end

    $display("------AXI-MM C2H Completed--------\n");
end
endtask

task TSK_USR_IRQ_TEST;
begin

board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h98,32'h1 , 4'hF);   
board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h9C,32'hFFFFFFFF , 4'hF);   
board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h94,32'h1 , 4'hF);   
 
end
endtask

/*
// AXI-St C2H test
*/
task TSK_QDMA_ST_C2H_TEST;
   input [10:0] qid;
   input dsc_bypass;

   reg [11:0] q_count;
   reg [10:0] q_base;
begin

 axi_st_q = qid;
 q_base   = QUEUE_PER_PF * fnc;
 q_count  = QUEUE_PER_PF;

 // Write Q number for AXI-ST C2H transfer
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h0, {21'h0,axi_st_q[10:0]}, 4'hF);   // Write Q num to user side 

 $display ("\n");
 $display ("******* AXI-ST C2H transfer START ******** \n");
 $display ("\n");
 //-------------- Load DATA in Buffer for aXI-ST H2C----------------------------------------------------
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_H2C_NEW;

 //-------------- Load DATA in Buffer for AXI-ST C2H ----------------------------------------------------
 // AXI-St C2H Descriptor is at address 0x0800 (2048)
 // AXI-St C2H Data       is at address 0x0A00 (2560)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_C2H;
 // AXI-St C2H CMPT Data   is at address 0x1000 (2048)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_CMPT_C2H;     // addrss 0x1000 (2048)

   // enable dsc bypass loopback
   if (dsc_bypass)
     board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h90, 32'h3, 4'hF);

    // initilize all ring size to some value.
    //-------------- Global Ring Size for Queue 0  0x204  : num of dsc 16 ------------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h204, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h208, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h20C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h210, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h214, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h218, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h21C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h220, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h224, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h228, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h22C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h230, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h234, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h238, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h23C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h240, 32'h00000010, 4'hF);

  // FMAP programing. set up 16Queues
     wr_dat[31:0]   = 32'h0 | q_base;
     wr_dat[63:32]  = 32'h0 | q_count;
     wr_dat[255:64] = 'h0;

    TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0 ], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

    wr_dat[31:18] = 'h0; // reserved
    wr_dat[17:7]  = 11'h0 | fnc[7:0]; // fnc
    wr_dat[6:5]   = 2'h1; // MDMA_CTXT_CMD_WR
    wr_dat[4:1]   = 4'hC; // QDMA_CTXT_SELC_FMAP
    wr_dat[0]     = 'h0;
    TSK_REG_WRITE(xdma_bar, 32'h844, wr_dat[31:0], 4'hF);

 //-------------- Clear HW CXTX for H2C and C2H first for Q1 ------------------------------------
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_H2C = 3 : 0011
 // 0      BUSY : 0 
 //        00000000001_00_0011_0 : _1000_0110 : 0x86
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000110};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_C2H = 2 : 0010
 // 0      BUSY : 0 
 //        00000000001_00_0010_0 : _1000_0100 : 0x84
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 $display ("******* Program C2H Global and Context values ******** \n");
 // Setup Stream H2C context 
 //-------------- Ind Dire CTXT MASK 0xffffffff for all 256 bits -------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h824, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h828, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h82C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h830, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h834, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h838, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h83C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h840, 32'hffffffff, 4'hF);

 // Program AXI-ST C2H 
 //-------------- Program C2H CMPT timer Trigger to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA00, 32'h00000001, 4'hF);

 //-------------- Program C2H CMPT Counter Threshold to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA40, 32'h00000001, 4'hF);

 //-------------- Program C2H DSC buffer size to 4K ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hAB0, 32'h00001000, 4'hF);

 // setup Stream C2H context
 //-------------- C2H CTXT DATA -------------------
 // ring size index is at 1
 // 
   wr_dat[255:128] = 'd0;
   wr_dat[127:64]  =  (64'h0 | C2H_ADDR); // dsc base
   wr_dat[63]      =  1'b0;  // is_mm
   wr_dat[62]      =  1'b0;  // mrkr_dis
   wr_dat[61]      =  1'b0;  // irq_req
   wr_dat[60]      =  1'b0;  // err_wb_sent
   wr_dat[59:58]   =  2'b0;  // err        
   wr_dat[57]      =  1'b0;  // irq_no_last
   wr_dat[56:54]   =  3'h0;  // port_id
   wr_dat[53]      =  1'b0;  // irq_en     
   wr_dat[52]      =  1'b1;  // wbk_en     
   wr_dat[51]      =  1'b0;  // mm_chn     
   wr_dat[50]      =  dsc_bypass ? 1'b1 : 1'b0;  // bypass     
   wr_dat[49:48]   =  2'b00; // dsc_sz, 8bytes     
   wr_dat[47:44]   =  4'h1;  // rng_sz     
   wr_dat[43:41]   =  3'h0;  // reserved
   wr_dat[40:37]   =  4'h0;  // fetch_max
   wr_dat[36]      =  1'b0;  // atc
   wr_dat[35]      =  1'b0;  // wbi_intvl_en
   wr_dat[34]      =  1'b1;  // wbi_chk    
   wr_dat[33]      =  1'b1;  // fcrd_en    
   wr_dat[32]      =  1'b1;  // qen        
   wr_dat[31:25]   =  7'h0;  // reserved
   wr_dat[24:17]   =  {4'h0,pfTestIteration[3:0]}; // func_id        
   wr_dat[16]      =  1'b0;  // irq_arm    
   wr_dat[15:0]    =  16'b0; // pidx

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID : 2
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_DSC_SW_C2H = 0 : 0000
 // 0      BUSY : 0 
 //        00000000001_01_0000_0 : 1010_0000 : 0xA0
 wr_dat = {14'h0,axi_st_q[10:0],7'b0100000};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 //-------------- Completion  CTXT DATA -------------------
   wr_dat[0]      = 1;      // en_stat_desc = 1
   wr_dat[1]      = 0;      // en_int = 0
   wr_dat[4:2]    = 3'h1;   // trig_mode = 3'b001
   wr_dat[12:5]   = {4'h0,pfTestIteration[3:0]};   // function ID
   wr_dat[16:13]  = 4'h0;   // reserved
   wr_dat[20:17]  = 4'h0;   // countr_idx  = 4'b0000 
   wr_dat[24:21]  = 4'h0;   // timer_idx = 4'b0000  
   wr_dat[26:25]  = 2'h0;   // int_st = 2'b00       
   wr_dat[27]     = 1'h1;   // color = 1            
   wr_dat[31:28]  = 4'h0;   // size_64 = 4'h0       
   wr_dat[89:32]  = (58'h0 | CMPT_ADDR[31:6]);  // baddr_64 = [63:6]only 
   wr_dat[91:90]  = 2'h0;   // desc_size = 2'b00    
   wr_dat[107:92] = 16'h0;  // pidx 16              
   wr_dat[123:108]= 16'h0;  // Cidx 16              
   wr_dat[124]    = 1'h1;   // valid = 1            
   wr_dat[126:125]= 2'h0;   // err
   wr_dat[127]    = 'h0;    // user_trig_pend
   wr_dat[128]    = 'h0;    // timer_running
   wr_dat[129]    = 'h0;    // full_upd
   wr_dat[130]    = 'h0;    // ovf_chk_dis
   wr_dat[131]    = 'h0;    // at
   wr_dat[142:132]= 'd4;   // vec MSI-X Vector
   wr_dat[143]     = 'd0;   // int_aggr
   wr_dat[144]     = 'h0;   // dis_intr_on_vf
   wr_dat[145]     = 'h0;   // vio
   wr_dat[146]     = 'h1;   // dir_c2h ; 1 = C2H, 0 = H2C direction
   wr_dat[150:147] = 'h0;   // reserved
   wr_dat[173:151] = 'h0;   // reserved
   wr_dat[174]     = 'h0;   // reserved
   wr_dat[178:175] = 'h0 | CMPT_ADDR[5:2];   // reserved
   wr_dat[179]     = 'h0 ;  // sh_cmpt 
   wr_dat[255:180] = 'h0;   // reserved

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31:0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63:32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95:64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_CMPT = 6 : 0110
 // 0      BUSY : 0 
 //        00000000001_01_0110_0 : 1010_1100 : 0xAC
 wr_dat = {14'h0,axi_st_q[10:0],7'b0101100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

  //Also update CIDX 0x00 for CMPT context 
   wr_dat[31:29] = 4'h0;   // reserver = 0
   wr_dat[28]    = 4'h0;   // irq_en_wrb = 0
   wr_dat[27]    = 1'b1;   // en_stat_desc = 1
   wr_dat[26:24] = 3'h1;   // trig_mode = 3'001 (every)
   wr_dat[23:20] = 4'h0;   // timer_idx = 4'h0
   wr_dat[19:16] = 4'h0;   // counter_idx = 4'h0
   wr_dat[15:0]  = 16'h0;  //sw_cidx = 16'h0000

   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 12;  // 32'h0000641C
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], wr_dat[31:0], 4'hF);

 //-------------- PreFetch CTXT DATA -------------------
 // valid = 1
 // all 0's
 // 0010_0000_0000_0000 => 2000
   wr_dat[0]      = 1'b0;  // bypass
   wr_dat[4:1]    = 4'h0;  // buf_size_idx
   wr_dat[7 :5]   = 3'h0;  // port_id
   wr_dat[8]      = 1'h0;  // var_desc. set to 0.
   wr_dat[9]      = 1'h0;  // virtio 
   wr_dat[15:10]  = 5'h0;  // num_pfch
   wr_dat[21:16]  = 5'h0;  // pfch_need
   wr_dat[25:22]  = 4'h0;  // reserverd
   wr_dat[26]     = 1'h0;  // error
   wr_dat[27]     = 1'h0;  // prefetch enable
   wr_dat[28]     = 1'b0;  // prefetch (Q is in prefetch)
   wr_dat[44 :29] = 16'h0; // sw_crdt
   wr_dat[45]     = 1'b1;  // valid
   wr_dat[245:46] = 'h0;

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31:0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63:32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95:64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_PFTCH = 7 : 0111
 // 0      BUSY : 0 
 //        00000000001_01_0111_0 : 1010_1110 : 0xAE
 wr_dat = {14'h0,axi_st_q[10:0],7'b0101110};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // Transfer C2H for 1 dsc

 //-------------- Write PIDX to 1 to transfer 1 descriptor in C2H ----------------
 //  There is no run bit for AXI-Stream, no need to arm them.
   $display(" **** Enable PIDX for C2H first ***\n");
   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 8;  // 32'h00006418
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], 32'h0a, 4'hF);   // Write 0x0a PIDX 

///
 // Initiate C2H tranfer on user side.
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h20, 32'h1, 4'hF);   // send 1 packets 

 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h04, {16'h0,board.RP.tx_usrapp.DMA_BYTE_CNT}, 4'hF);   // C2H length 128 bytes //

 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h30, 32'ha4a3a2a1, 4'hF);   // Write back data 
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h34, 32'hb4b3b2b1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h38, 32'hc4c3c2c1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h3C, 32'hd4d3d2d1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h40, 32'he4e3e2e1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h44, 32'hf4f3f2f1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h48, 32'h14131211, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h4C, 32'h24232221, 4'hF);   // Write back data

//    board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h50, 32'h2, 4'hF);   // writeback data control to set 8B, 16B or 32B

//    board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h08, 32'h06, 4'hF);   // Start C2H tranfer and immediate data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h08, 32'h02, 4'hF);   // Start C2H tranfer

 //compare C2H data
   $display("------Compare C2H AXI-ST 1st Data--------\n");
   // compare data with H2C data in 768
   board.RP.tx_usrapp.COMPARE_DATA_C2H({16'h0,board.RP.tx_usrapp.DMA_BYTE_CNT},768);

   // Compare status writes
   board.RP.tx_usrapp.COMPARE_TRANS_C2H_ST_STATUS(0, 16'h1, 1, 8); //Write back entry and write back status
   
   // uptate CIDX for Write back 
   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 12;  // 32'h0000641C
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], 32'h09000001, 4'hF);

   $display("------AXI-ST C2H Completed--------\n");
 end
 endtask

task TSK_QDMA_ST_H2C_TEST;
   input [10:0] qid;
   input dsc_bypass;

   reg [11:0] q_count;
   reg [10:0] q_base;
begin
   //
// now doing AXI-Stream Test for QDMA
//
// Assign Q 2 for AXI-ST
 pf0_qmax = 11'h200;
// axi_st_q = 11'h2;
 axi_st_q = qid;
 q_base   = QUEUE_PER_PF * fnc;
 q_count  = QUEUE_PER_PF;

 // Write Q number for AXI-ST C2H transfer
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h0, {21'h0,axi_st_q[10:0]}, 4'hF);   // Write Q num to user side 

 $display ("\n");
 $display ("******* AXI-ST H2C transfer START ******** \n");
 $display ("\n");
 //-------------- Load DATA in Buffer for aXI-ST H2C----------------------------------------------------
 // AXI-St H2C Descriptor is at address 0x0100 (256)
 // AXI-St H2c Data       is at address 0x0300 (768)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_H2C_NEW;

 //-------------- Load DATA in Buffer for AXI-ST C2H ----------------------------------------------------
 // AXI-St C2H Descriptor is at address 0x0800 (2048)
 // AXI-St C2H Data       is at address 0x0A00 (2560)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_C2H;
 // AXI-St C2H CMPT Data   is at address 0x1000 (2048)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_CMPT_C2H;     // addrss 0x1000 (2048)

   // enable dsc bypass loopback
   if (dsc_bypass)
     board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h90, 32'h3, 4'hF);

    // initilize all ring size to some value.
    //-------------- Global Ring Size for Queue 0  0x204  : num of dsc 16 ------------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h204, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h208, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h20C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h210, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h214, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h218, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h21C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h220, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h224, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h228, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h22C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h230, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h234, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h238, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h23C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h240, 32'h00000010, 4'hF);

 // set up 16Queues
     wr_dat[31:0]   = 32'h0 | q_base;
     wr_dat[63:32]  = 32'h0 | q_count;
     wr_dat[255:64] = 'h0;

    TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0 ], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
    TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

    wr_dat[31:18] = 'h0; // reserved
    wr_dat[17:7]  = 11'h0 | fnc[7:0]; // fnc
    wr_dat[6:5]   = 2'h1; // MDMA_CTXT_CMD_WR
    wr_dat[4:1]   = 4'hC; // QDMA_CTXT_SELC_FMAP
    wr_dat[0]     = 'h0;
    TSK_REG_WRITE(xdma_bar, 32'h844, wr_dat[31:0], 4'hF);

 //-------------- Clear HW CXTX for H2C and C2H first for Q1 ------------------------------------
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_H2C = 3 : 0011
 // 0      BUSY : 0 
 //        00000000001_00_0011_0 : _1000_0110 : 0x86
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000110};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_C2H = 2 : 0010
 // 0      BUSY : 0 
 //        00000000001_00_0010_0 : _1000_0100 : 0x84
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 $display ("******* Program C2H Global and Context values ******** \n");
 // Setup Stream H2C context 
 //-------------- Ind Dire CTXT MASK 0xffffffff for all 256 bits -------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h824, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h828, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h82C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h830, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h834, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h838, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h83C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h840, 32'hffffffff, 4'hF);

 //-------------- Ind Dire CTXT AXI-ST H2C -------------------
 // ring size index is at 1
 // 
   wr_dat[255:140] = 'd0;
   wr_dat[139]     = 'd0;    // int_aggr
   wr_dat[138:128] = 'd3;    // vec MSI-X Vector
   wr_dat[127:64]  =  (64'h0 | H2C_ADDR); // dsc base
   wr_dat[63]      =  1'b0;  // is_mm
   wr_dat[62]      =  1'b0;  // mrkr_dis
   wr_dat[61]      =  1'b0;  // irq_req
   wr_dat[60]      =  1'b0;  // err_wb_sent
   wr_dat[59:58]   =  2'b0;  // err        
   wr_dat[57]      =  1'b0;  // irq_no_last
   wr_dat[56:54]   =  3'h0;  // port_id
   wr_dat[53]      =  1'b0;  // irq_en     
   wr_dat[52]      =  1'b1;  // wbk_en     
   wr_dat[51]      =  1'b0;  // mm_chn     
   wr_dat[50]      =  dsc_bypass ? 1'b1 : 1'b0;  // bypass     
   wr_dat[49:48]   =  2'b01; // dsc_sz, 16bytes     
   wr_dat[47:44]   =  4'h1;  // rng_sz     
   wr_dat[43:41]   =  3'h0;  // reserved
   wr_dat[40:37]   =  4'h0;  // fetch_max
   wr_dat[36]      =  1'b0;  // atc
   wr_dat[35]      =  1'b0;  // wbi_intvl_en
   wr_dat[34]      =  1'b1;  // wbi_chk    
   wr_dat[33]      =  1'b0;  // fcrd_en    
   wr_dat[32]      =  1'b1;  // qen        
   wr_dat[31:25]   =  7'h0;  // reserved
   wr_dat[24:17]   =  {4'h0,pfTestIteration[3:0]}; // func_id        
   wr_dat[16]      =  1'b0;  // irq_arm    
   wr_dat[15:0]    =  16'b0; // pidx

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID : 2
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_DSC_SW_H2C = 1 : 0001
 // 0      BUSY : 0 
 //        00000000001_01_0001_0 : 1010_0010 : 0xA2
 wr_dat = {14'h0,axi_st_q[10:0],7'b0100010};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // Program AXI-ST C2H 
 //-------------- Program C2H CMPT timer Trigger to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA00, 32'h00000001, 4'hF);

 //-------------- Program C2H CMPT Counter Threshold to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA40, 32'h00000001, 4'hF);

 //-------------- Program C2H DSC buffer size to 4K ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hAB0, 32'h00001000, 4'hF);
 // AXI-ST H2C transfer
 //
 // dummy clear H2c match
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h0C, 32'h01, 4'hF);   // Dummy clear H2C match
 //-------------- Start DMA H2C tranfer ------------------------------------------------------
   $display(" **** Start DMA H2C AXI-ST transfer ***\n");

 fork
 //-------------- Write Queue 1 of PIDX to 1 to transfer 1 descriptor in H2C ----------------
   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 4;  // 32'h00006414
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], 32'h1, 4'hF);   // Write 1 PIDX 

 //compare H2C data
   $display("------Compare H2C AXI-ST Data--------\n");
   board.RP.tx_usrapp.COMPARE_TRANS_STATUS(32'h000010F0, 16'h1); 
 join

 // check for if data on user side matched what was expected.
 board.RP.tx_usrapp.TSK_REG_READ(user_bar, 32'h10);   // Read H2C status and Queue info.
 $display ("**** H2C Data Match Status = %h\n", P_READ_DATA);
 if (P_READ_DATA[0] == 1'b1) begin
    $display ("[%t] : TEST PASSED ---**** H2C Data Matches and H2C Q number = %h\n",$realtime, P_READ_DATA[10:4]);
    $display("[%t] : Test Completed Successfully for PF{%d}",$realtime,pfTestIteration);
 end else begin
    $display ("ERROR: [%t] : TEST FAILED ---****ERROR**** H2C Data Mis-Matches and H2C Q number = %h\n",$realtime, P_READ_DATA[10:4]);
    board.RP.tx_usrapp.test_state =1;
 end
   $display("------AXI-ST H2C Completed--------\n");
 end

 endtask

/*
// ST C2H Streaming data with Completion data
*/
task TSK_QDMA_ST_C2H_CMPT_TEST;
input dsc_bypass;
begin
   //
// now doing AXI-Stream Test for QDMA
//
// Assign Q 2 for AXI-ST
 pf0_qmax = 11'h200;
 axi_st_q = 11'h2;

 // Write Q number for AXI-ST C2H transfer
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h0, {21'h0,axi_st_q[10:0]}, 4'hF);   // Write Q num to user side 

 $display ("******* AXI-ST H2C/C2H transfer START ******** \n");
 $display ("\n");
 $display ("\n");
 //-------------- Load DATA in Buffer for aXI-ST H2C----------------------------------------------------
 // AXI-St H2C Descriptor is at address 0x0100 (256)
 // AXI-St H2c Data       is at address 0x0300 (768)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_H2C_NEW;

 //-------------- Load DATA in Buffer for AXI-ST C2H ----------------------------------------------------
 // AXI-St C2H Descriptor is at address 0x0800 (2048)
 // AXI-St C2H Data       is at address 0x0A00 (2560)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_C2H;
 // AXI-St C2H CMPT Data   is at address 0x1000 (2048)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_CMPT_C2H;     // addrss 0x1000 (2048)

   // enable dsc bypass loopback
   if (dsc_bypass)
     board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h90, 32'h3, 4'hF);

    // initilize all ring size to some value.
    //-------------- Global Ring Size for Queue 0  0x204  : num of dsc 16 ------------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h204, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h208, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h20C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h210, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h214, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h218, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h21C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h220, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h224, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h228, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h22C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h230, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h234, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h238, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h23C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h240, 32'h00000010, 4'hF);

 //-------------- Global Function MAP 0x400  : Func0 22:11 Qnumber ( 16 Queue ) : 10:0 Qid_base for this Func
 // set up 16Queues
 // Func number is 0 : 0*4 = 0: address 0x400+ Fnum*4 = 0x400
 // 22:11 : 1_0000 : number of queues for this function. 
 // 10:0  : 000_0000_0000 : Queue off set 
 // 1000_0000_0000_0000 : 0x8000
	for(pf_loop_index=0; pf_loop_index <= pfTestIteration; pf_loop_index = pf_loop_index + 1)
	begin
	 if(pf_loop_index == pfTestIteration) begin
		wr_dat = {14'h0,pf0_qmax[10:0],12'h00};
		board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), wr_dat[31:0], 4'hF);
	 end else begin
	    wr_dat = 32'h00000000;
		board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), wr_dat[31:0], 4'hF);
	 end
	end

 //-------------- Clear HW CXTX for H2C and C2H first for Q1 ------------------------------------
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_H2C = 3 : 0011
 // 0      BUSY : 0 
 //        00000000001_00_0011_0 : _1000_0110 : 0x86
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000110};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_C2H = 2 : 0010
 // 0      BUSY : 0 
 //        00000000001_00_0010_0 : _1000_0100 : 0x84
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 $display ("******* Program C2H Global and Context values ******** \n");
 // Setup Stream H2C context 
 //-------------- Ind Dire CTXT MASK 0xffffffff for all 256 bits -------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h824, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h828, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h82C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h830, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h834, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h838, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h83C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h840, 32'hffffffff, 4'hF);


 // Program AXI-ST C2H 
 //-------------- Program C2H CMPT timer Trigger to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA00, 32'h00000001, 4'hF);

 //-------------- Program C2H CMPT Counter Threshold to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA40, 32'h00000001, 4'hF);

 //-------------- Program C2H DSC buffer size to 4K ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hAB0, 32'h00001000, 4'hF);

 // setup Stream C2H context
 //-------------- C2H CTXT DATA -------------------
 // ring size index is at 1
 // 
   wr_dat[255:128] = 'd0;
   wr_dat[127:64]  =  (64'h0 | C2H_ADDR); // dsc base
   wr_dat[63]      =  1'b0;  // is_mm
   wr_dat[62]      =  1'b0;  // mrkr_dis
   wr_dat[61]      =  1'b0;  // irq_req
   wr_dat[60]      =  1'b0;  // err_wb_sent
   wr_dat[59:58]   =  2'b0;  // err        
   wr_dat[57]      =  1'b0;  // irq_no_last
   wr_dat[56:54]   =  3'h0;  // port_id
   wr_dat[53]      =  1'b0;  // irq_en     
   wr_dat[52]      =  1'b1;  // wbk_en     
   wr_dat[51]      =  1'b0;  // mm_chn     
   wr_dat[50]      =  dsc_bypass ? 1'b1 : 1'b0;  // bypass     
   wr_dat[49:48]   =  2'b00; // dsc_sz, 8bytes     
   wr_dat[47:44]   =  4'h1;  // rng_sz     
   wr_dat[43:41]   =  3'h0;  // reserved
   wr_dat[40:37]   =  4'h0;  // fetch_max
   wr_dat[36]      =  1'b0;  // atc
   wr_dat[35]      =  1'b0;  // wbi_intvl_en
   wr_dat[34]      =  1'b1;  // wbi_chk    
   wr_dat[33]      =  1'b1;  // fcrd_en    
   wr_dat[32]      =  1'b1;  // qen        
   wr_dat[31:25]   =  7'h0;  // reserved
   wr_dat[24:17]   =  {4'h0,pfTestIteration[3:0]}; // func_id        
   wr_dat[16]      =  1'b0;  // irq_arm    
   wr_dat[15:0]    =  16'b0; // pidx

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID : 2
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_DSC_SW_C2H = 0 : 0000
 // 0      BUSY : 0 
 //        00000000001_01_0000_0 : 1010_0000 : 0xA0
 wr_dat = {14'h0,axi_st_q[10:0],7'b0100000};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 //-------------- Completion  CTXT DATA -------------------
   wr_dat[0]      = 1;      // en_stat_desc = 1
   wr_dat[1]      = 0;      // en_int = 0
   wr_dat[4:2]    = 3'h1;   // trig_mode = 3'b001
   wr_dat[12:5]   = {4'h0,pfTestIteration[3:0]};   // function ID
   wr_dat[16:13]  = 4'h0;   // reserved
   wr_dat[20:17]  = 4'h0;   // countr_idx  = 4'b0000 
   wr_dat[24:21]  = 4'h0;   // timer_idx = 4'b0000  
   wr_dat[26:25]  = 2'h0;   // int_st = 2'b00       
   wr_dat[27]     = 1'h1;   // color = 1            
   wr_dat[31:28]  = 4'h0;   // size_64 = 4'h0       
   wr_dat[89:32]  = (58'h0 | CMPT_ADDR[31:6]);  // baddr_64 = [63:6]only 
   wr_dat[91:90]  = 2'h0;   // desc_size = 2'b00    
   wr_dat[107:92] = 16'h0;  // pidx 16              
   wr_dat[123:108]= 16'h0;  // Cidx 16              
   wr_dat[124]    = 1'h1;   // valid = 1            
   wr_dat[126:125]= 2'h0;   // err
   wr_dat[127]    = 'h0;    // user_trig_pend
   wr_dat[128]    = 'h0;    // timer_running
   wr_dat[129]    = 'h0;    // full_upd
   wr_dat[130]    = 'h0;    // ovf_chk_dis
   wr_dat[131]    = 'h0;    // at
   wr_dat[142:132]= 'd4;   // vec MSI-X Vector
   wr_dat[143]     = 'd0;   // int_aggr
   wr_dat[144]     = 'h0;   // dis_intr_on_vf
   wr_dat[145]     = 'h0;   // vio
   wr_dat[146]     = 'h1;   // dir_c2h ; 1 = C2H, 0 = H2C direction
   wr_dat[150:147] = 'h0;   // reserved
   wr_dat[173:151] = 'h0;   // reserved
   wr_dat[174]     = 'h0;   // reserved
   wr_dat[178:175] = 'h0 | CMPT_ADDR[5:2];   // reserved
   wr_dat[179]     = 'h0 ;  // sh_cmpt 
   wr_dat[255:180] = 'h0;   // reserved

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31:0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63:32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95:64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_CMPT = 6 : 0110
 // 0      BUSY : 0 
 //        00000000001_01_0110_0 : 1010_1100 : 0xAC
 wr_dat = {14'h0,axi_st_q[10:0],7'b0101100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

  //Also update CIDX 0x00 for CMPT context 
   wr_dat[31:29] = 4'h0;   // reserver = 0
   wr_dat[28]    = 4'h0;   // irq_en_wrb = 0
   wr_dat[27]    = 1'b1;   // en_stat_desc = 1
   wr_dat[26:24] = 3'h1;   // trig_mode = 3'001 (every)
   wr_dat[23:20] = 4'h0;   // timer_idx = 4'h0
   wr_dat[19:16] = 4'h0;   // counter_idx = 4'h0
   wr_dat[15:0]  = 16'h0;  //sw_cidx = 16'h0000

   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 12;  // 32'h0000641C
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], wr_dat[31:0], 4'hF);

 //-------------- PreFetch CTXT DATA -------------------
 // valid = 1
 // all 0's
 // 0010_0000_0000_0000 => 2000
   wr_dat[0]      = 1'b0;  // bypass
   wr_dat[4:1]    = 4'h0;  // buf_size_idx
   wr_dat[7 :5]   = 3'h0;  // port_id
   wr_dat[15:8]   = 8'h0;  // function id
   wr_dat[19:16]  = 4'h0;  // reserverd
   wr_dat[25:20]  = 5'h0;  // reserverd
   wr_dat[26]     = 1'h0;  // error
   wr_dat[27]     = 1'h0;  // prefetch enable
   wr_dat[28]     = 1'b0;  // prefetch (Q is in prefetch)
   wr_dat[44 :29] = 16'h0; // sw_crdt
   wr_dat[45]     = 1'b1;  // valid
   wr_dat[127:46] = 'h0;

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31:0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63:32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95:64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_PFTCH = 7 : 0111
 // 0      BUSY : 0 
 //        00000000001_01_0111_0 : 1010_1110 : 0xAE
 wr_dat = {14'h0,axi_st_q[10:0],7'b0101110};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // Transfer C2H for 1 dsc

 //-------------- Write PIDX to 1 to transfer 1 descriptor in C2H ----------------
 //  There is no run bit for AXI-Stream, no need to arm them.
   $display(" **** Enable PIDX for C2H first ***\n");
   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 8;  // 32'h00006418
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], 32'h0a, 4'hF);   // Write 0x0a PIDX 

///
 // Initiate C2H tranfer on user side.
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h20, 32'h1, 4'hF);   // send 1 packets 

 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h04, 32'h80, 4'hF);   // C2H length 128 bytes //

 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h30, 32'ha4a3a2a1, 4'hF);   // Write back data 
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h34, 32'hb4b3b2b1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h38, 32'hc4c3c2c1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h3C, 32'hd4d3d2d1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h40, 32'he4e3e2e1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h44, 32'hf4f3f2f1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h48, 32'h14131211, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h4C, 32'h24232221, 4'hF);   // Write back data

//    board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h50, 32'h2, 4'hF);   // writeback data control to set 8B, 16B or 32B

//    board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h08, 32'h06, 4'hF);   // Start C2H tranfer and immediate data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h08, 32'h02, 4'hF);   // Start C2H tranfer

 //compare C2H data
   $display("------Compare C2H AXI-ST 1st Data--------\n");
   // compare data with H2C data in 512
   board.RP.tx_usrapp.COMPARE_DATA_C2H({16'h0,board.RP.tx_usrapp.DMA_BYTE_CNT},512);

   // Compare status writes
   board.RP.tx_usrapp.COMPARE_TRANS_C2H_ST_STATUS(0, 16'h1, 1, 8); //Write back entry and write back status
   
   // uptate CIDX for Write back 
   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 12;  // 32'h0000641C
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], 32'h09000001, 4'hF);

 end
 endtask

/*
// AXI-ST C2H Streaming data with Marker data
*/
task TSK_QDMA_ST_C2H_MRK_TEST;
input dsc_bypass;
begin
   //
// now doing AXI-Stream Test for QDMA
//
// Assign Q 2 for AXI-ST
 pf0_qmax = 11'h200;
 axi_st_q = 11'h2;

 // Write Q number for AXI-ST C2H transfer
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h0, {21'h0,axi_st_q[10:0]}, 4'hF);   // Write Q num to user side 

 $display ("******* AXI-ST H2C/C2H transfer START ******** \n");
 $display ("\n");
 $display ("\n");
 //-------------- Load DATA in Buffer for aXI-ST H2C----------------------------------------------------
 // AXI-St H2C Descriptor is at address 0x0100 (256)
 // AXI-St H2c Data       is at address 0x0300 (768)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_H2C_NEW;

 //-------------- Load DATA in Buffer for AXI-ST C2H ----------------------------------------------------
 // AXI-St C2H Descriptor is at address 0x0800 (2048)
 // AXI-St C2H Data       is at address 0x0A00 (2560)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_C2H;
 // AXI-St C2H CMPT Data   is at address 0x1000 (2048)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_CMPT_C2H;     // addrss 0x1000 (2048)

   // enable dsc bypass loopback
   if (dsc_bypass)
     board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h90, 32'h3, 4'hF);

    // initilize all ring size to some value.
    //-------------- Global Ring Size for Queue 0  0x204  : num of dsc 16 ------------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h204, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h208, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h20C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h210, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h214, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h218, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h21C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h220, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h224, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h228, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h22C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h230, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h234, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h238, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h23C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h240, 32'h00000010, 4'hF);

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
		board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), wr_dat[31:0], 4'hF);
	 end else begin
	    wr_dat = 32'h00000000;
		board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), wr_dat[31:0], 4'hF);
	 end
	end

 //-------------- Clear HW CXTX for H2C and C2H first for Q1 ------------------------------------
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_H2C = 3 : 0011
 // 0      BUSY : 0 
 //        00000000001_00_0011_0 : _1000_0110 : 0x86
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000110};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_C2H = 2 : 0010
 // 0      BUSY : 0 
 //        00000000001_00_0010_0 : _1000_0100 : 0x84
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 $display ("******* Program C2H Global and Context values ******** \n");
 // Setup Stream H2C context 
 //-------------- Ind Dire CTXT MASK 0xffffffff for all 256 bits -------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h824, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h828, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h82C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h830, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h834, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h838, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h83C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h840, 32'hffffffff, 4'hF);


 // Program AXI-ST C2H 
 //-------------- Program C2H CMPT timer Trigger to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA00, 32'h00000001, 4'hF);

 //-------------- Program C2H CMPT Counter Threshold to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA40, 32'h00000001, 4'hF);

 //-------------- Program C2H DSC buffer size to 4K ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hAB0, 32'h00001000, 4'hF);

 // setup Stream C2H context
 //-------------- C2H CTXT DATA -------------------
 // ring size index is at 1
 // 
   wr_dat[255:128] = 'd0;
   wr_dat[127:64]  =  (64'h0 | C2H_ADDR); // dsc base
   wr_dat[63]      =  1'b0;  // is_mm
   wr_dat[62]      =  1'b0;  // mrkr_dis
   wr_dat[61]      =  1'b0;  // irq_req
   wr_dat[60]      =  1'b0;  // err_wb_sent
   wr_dat[59:58]   =  2'b0;  // err        
   wr_dat[57]      =  1'b0;  // irq_no_last
   wr_dat[56:54]   =  3'h0;  // port_id
   wr_dat[53]      =  1'b0;  // irq_en     
   wr_dat[52]      =  1'b1;  // wbk_en     
   wr_dat[51]      =  1'b0;  // mm_chn     
   wr_dat[50]      =  dsc_bypass ? 1'b1 : 1'b0;  // bypass     
   wr_dat[49:48]   =  2'b00; // dsc_sz, 8bytes     
   wr_dat[47:44]   =  4'h1;  // rng_sz     
   wr_dat[43:40]   =  4'h0;  // reserved
   wr_dat[39:37]   =  3'h0;  // fetch_max
   wr_dat[36]      =  1'b0;  // atc
   wr_dat[35]      =  1'b0;  // wbi_intvl_en
   wr_dat[34]      =  1'b1;  // wbi_chk    
   wr_dat[33]      =  1'b1;  // fcrd_en    
   wr_dat[32]      =  1'b1;  // qen        
   wr_dat[31:25]   =  7'h0;  // reserved
   wr_dat[24:17]   =  {4'h0,pfTestIteration[3:0]}; // func_id        
   wr_dat[16]      =  1'b0;  // irq_arm    
   wr_dat[15:0]    =  16'b0; // pidx

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID : 2
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_DSC_SW_C2H = 0 : 0000
 // 0      BUSY : 0 
 //        00000000001_01_0000_0 : 1010_0000 : 0xA0
 wr_dat = {14'h0,axi_st_q[10:0],7'b0100000};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 //-------------- Completion  CTXT DATA -------------------
   wr_dat[0]      = 1;      // en_stat_desc = 1
   wr_dat[1]      = 0;      // en_int = 0
   wr_dat[4:2]    = 3'h1;   // trig_mode = 3'b001
   wr_dat[12:5]   = {4'h0,pfTestIteration[3:0]};   // function ID
   wr_dat[16:13]  = 4'h0;   // reserved
   wr_dat[20:17]  = 4'h0;   // countr_idx  = 4'b0000 
   wr_dat[24:21]  = 4'h0;   // timer_idx = 4'b0000  
   wr_dat[26:25]  = 2'h0;   // int_st = 2'b00       
   wr_dat[27]     = 1'h1;   // color = 1            
   wr_dat[31:28]  = 4'h0;   // size_64 = 4'h0       
   wr_dat[89:32]  = (58'h0 | CMPT_ADDR[31:6]);  // baddr_64 = [63:6]only 
   wr_dat[91:90]  = 2'h0;   // desc_size = 2'b00    
   wr_dat[107:92] = 16'h0;  // pidx 16              
   wr_dat[123:108]= 16'h0;  // Cidx 16              
   wr_dat[124]    = 1'h1;   // valid = 1            
   wr_dat[126:125]= 2'h0;   // err
   wr_dat[127]    = 'h0;    // user_trig_pend
   wr_dat[128]    = 'h0;    // timer_running
   wr_dat[129]    = 'h0;    // full_upd
   wr_dat[130]    = 'h0;    // ovf_chk_dis
   wr_dat[131]    = 'h0;    // at
   wr_dat[142:132]= 'd4;   // vec MSI-X Vector
   wr_dat[143]     = 'd0;   // int_aggr
   wr_dat[144]     = 'h0;   // dis_intr_on_vf
   wr_dat[145]     = 'h0;   // vio
   wr_dat[146]     = 'h1;   // dir_c2h ; 1 = C2H, 0 = H2C direction
   wr_dat[150:147] = 'h0;   // reserved
   wr_dat[173:151] = 'h0;   // reserved
   wr_dat[174]     = 'h0;   // reserved
   wr_dat[178:175] = 'h0 | CMPT_ADDR[5:2];   // reserved
   wr_dat[179]     = 'h0 ;  // sh_cmpt 
   wr_dat[255:180] = 'h0;   // reserved

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31:0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63:32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95:64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_CMPT = 6 : 0110
 // 0      BUSY : 0 
 //        00000000001_01_0110_0 : 1010_1100 : 0xAC
 wr_dat = {14'h0,axi_st_q[10:0],7'b0101100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

  //Also update CIDX 0x00 for CMPT context 
   wr_dat[31:29] = 4'h0;   // reserver = 0
   wr_dat[28]    = 4'h0;   // irq_en_wrb = 0
   wr_dat[27]    = 1'b1;   // en_stat_desc = 1
   wr_dat[26:24] = 3'h1;   // trig_mode = 3'001 (every)
   wr_dat[23:20] = 4'h0;   // timer_idx = 4'h0
   wr_dat[19:16] = 4'h0;   // counter_idx = 4'h0
   wr_dat[15:0]  = 16'h0;  //sw_cidx = 16'h0000

   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 12;  // 32'h0000641C
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], wr_dat[31:0], 4'hF);

 //-------------- PreFetch CTXT DATA -------------------
 // valid = 1
 // all 0's
 // 0010_0000_0000_0000 => 2000
   wr_dat[0]      = 1'b0;  // bypass
   wr_dat[4:1]    = 4'h0;  // buf_size_idx
   wr_dat[7 :5]   = 3'h0;  // port_id
   wr_dat[15:8]   = 8'h0;  // function id
   wr_dat[19:16]  = 4'h0;  // reserverd
   wr_dat[25:20]  = 5'h0;  // reserverd
   wr_dat[26]     = 1'h0;  // error
   wr_dat[27]     = 1'h0;  // prefetch enable
   wr_dat[28]     = 1'b0;  // prefetch (Q is in prefetch)
   wr_dat[44 :29] = 16'h0; // sw_crdt
   wr_dat[45]     = 1'b1;  // valid
   wr_dat[127:46] = 'h0;

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31:0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63:32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95:64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_PFTCH = 7 : 0111
 // 0      BUSY : 0 
 //        00000000001_01_0111_0 : 1010_1110 : 0xAE
 wr_dat = {14'h0,axi_st_q[10:0],7'b0101110};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // Transfer C2H for 1 dsc

 //-------------- Write PIDX to 1 to transfer 1 descriptor in C2H ----------------
 //  There is no run bit for AXI-Stream, no need to arm them.
   $display(" **** Enable PIDX for C2H first ***\n");
   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 8;  // 32'h00006418
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], 32'h0a, 4'hF);   // Write 0x0a PIDX 

///
 // Initiate C2H tranfer on user side.
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h20, 32'h1, 4'hF);   // send 1 packets 

 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h04, 32'h80, 4'hF);   // C2H length 128 bytes //

 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h30, 32'ha4a3a2a1, 4'hF);   // Write back data 
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h34, 32'hb4b3b2b1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h38, 32'hc4c3c2c1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h3C, 32'hd4d3d2d1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h40, 32'he4e3e2e1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h44, 32'hf4f3f2f1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h48, 32'h14131211, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h4C, 32'h24232221, 4'hF);   // Write back data

//    board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h50, 32'h2, 4'hF);   // writeback data control to set 8B, 16B or 32B

 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h08, 32'h02, 4'hF);   // Start C2H tranfer

 //compare C2H data
   $display("------Compare C2H AXI-ST 1st Data--------\n");
   // compare data with H2C data in 512
   board.RP.tx_usrapp.COMPARE_DATA_C2H({16'h0,board.RP.tx_usrapp.DMA_BYTE_CNT},512);

   // Compare status writes
   board.RP.tx_usrapp.COMPARE_TRANS_C2H_ST_STATUS(0, 16'h1, 1, 8); //Write back entry and write back status
   
   // uptate CIDX for Write back 
   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 12;  // 32'h0000641C
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], 32'h09000001, 4'hF);

   $display("------Send C2H AXI-ST Marker Data--------\n");
   board.RP.tx_usrapp.TSK_REG_READ(user_bar, 32'h18);   // Read C2H status and bit [0] for marker responce
   board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h00);
   board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h08, 32'h22, 4'hF);   // Send C2H Marker
   
   // Compare status writes
   board.RP.tx_usrapp.COMPARE_TRANS_C2H_ST_STATUS(1, 16'h2, 1, 8); //Write back entry and write back status
   board.RP.tx_usrapp.TSK_REG_READ(user_bar, 32'h18);   // Read C2H status and bit [0] for marker responce
   if (P_READ_DATA[15:0] == 16'h1) begin
      $display(" AXI-ST C2H Marker responce revived\n");
      board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h08, 32'h00, 4'hF);   // Clear Marker request
   end
   else begin
      $display(" -- ERROR AXI-ST C2H DID not receive Marker responce \n");
      board.RP.tx_usrapp.test_state =1;
   end
   #1000;
 end
 endtask

/*
// Task to test C2H Stream Immediate data only
*/
task TSK_QDMA_IMM_TEST;
   input [10:0] qid;
begin
   //
// now doing AXI-Stream Test for QDMA
//
// Assign Q 2 for AXI-ST
 pf0_qmax = 11'h200;
 axi_st_q = qid;

 // Write Q number for AXI-ST C2H transfer
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h0, {21'h0,axi_st_q[10:0]}, 4'hF);   // Write Q num to user side 

 $display ("******* AXI-ST H2C DSC bypass to C2H IMM data START ******** \n");
 $display ("\n");
 $display ("\n");
 //-------------- Load DATA in Buffer for aXI-ST H2C----------------------------------------------------
 // AXI-St H2C Descriptor is at address 0x0100 (256)
 // AXI-St H2c Data       is at address 0x0300 (768)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_H2C_NEW;

 //-------------- Load DATA in Buffer for AXI-ST C2H ----------------------------------------------------
 // AXI-St C2H Descriptor is at address 0x0800 (2048)
 // AXI-St C2H Data       is at address 0x0A00 (2560)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_C2H;
 // AXI-St C2H CMPT Data   is at address 0x1000 (4096)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_CMPT_C2H;     // addrss 0x1000 (4096)

    // initilize all ring size to some value.
    //-------------- Global Ring Size for Queue 0  0x204  : num of dsc 16 ------------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h204, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h208, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h20C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h210, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h214, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h218, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h21C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h220, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h224, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h228, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h22C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h230, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h234, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h238, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h23C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h240, 32'h00000010, 4'hF);

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
		board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), wr_dat[31:0], 4'hF);
	 end else begin
	    wr_dat = 32'h00000000;
		board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), wr_dat[31:0], 4'hF);
	 end
	end

 //-------------- Clear HW CXTX for H2C and C2H first for Q1 ------------------------------------
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_H2C = 3 : 0011
 // 0      BUSY : 0 
 //        00000000001_00_0011_0 : _1000_0110 : 0x86
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000110};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_C2H = 2 : 0010
 // 0      BUSY : 0 
 //        00000000001_00_0010_0 : _1000_0100 : 0x84
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 $display ("******* Program C2H Global and Context values ******** \n");
 // Setup Stream H2C context 
 //-------------- Ind Dire CTXT MASK 0xffffffff for all 256 bits -------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h824, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h828, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h82C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h830, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h834, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h838, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h83C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h840, 32'hffffffff, 4'hF);

 // Program AXI-ST C2H 
 //-------------- Program C2H CMPT timer Trigger to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA00, 32'h00000001, 4'hF);

 //-------------- Program C2H CMPT Counter Threshold to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA40, 32'h00000001, 4'hF);

 //-------------- Program C2H DSC buffer size to 4K ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hAB0, 32'h00001000, 4'hF);

 //-------------- Completion  CTXT DATA -------------------
   wr_dat[0]      = 1;      // en_stat_desc = 1
   wr_dat[1]      = 0;      // en_int = 0
   wr_dat[4:2]    = 3'h1;   // trig_mode = 3'b001
   wr_dat[12:5]   = {4'h0,pfTestIteration[3:0]};   // function ID
   wr_dat[16:13]  = 4'h0;   // reserved
   wr_dat[20:17]  = 4'h0;   // countr_idx  = 4'b0000 
   wr_dat[24:21]  = 4'h0;   // timer_idx = 4'b0000  
   wr_dat[26:25]  = 2'h0;   // int_st = 2'b00       
   wr_dat[27]     = 1'h1;   // color = 1            
   wr_dat[31:28]  = 4'h0;   // size_64 = 4'h0       
   wr_dat[89:32]  = (58'h0 | CMPT_ADDR[31:6]);  // baddr_64 = [63:6]only 
   wr_dat[91:90]  = 2'h0;   // desc_size = 2'b00    
   wr_dat[107:92] = 16'h0;  // pidx 16              
   wr_dat[123:108]= 16'h0;  // Cidx 16              
   wr_dat[124]    = 1'h1;   // valid = 1            
   wr_dat[126:125]= 2'h0;   // err
   wr_dat[127]    = 'h0;    // user_trig_pend
   wr_dat[128]    = 'h0;    // timer_running
   wr_dat[129]    = 'h0;    // full_upd
   wr_dat[130]    = 'h0;    // ovf_chk_dis
   wr_dat[131]    = 'h0;    // at
   wr_dat[142:132]= 'd4;   // vec MSI-X Vector
   wr_dat[143]     = 'd0;   // int_aggr
   wr_dat[144]     = 'h0;   // dis_intr_on_vf
   wr_dat[145]     = 'h0;   // vio
   wr_dat[146]     = 'h1;   // dir_c2h ; 1 = C2H, 0 = H2C direction
   wr_dat[150:147] = 'h0;   // reserved
   wr_dat[173:151] = 'h0;   // reserved
   wr_dat[174]     = 'h0;   // reserved
   wr_dat[178:175] = 'h0 | CMPT_ADDR[5:2];   // reserved
   wr_dat[179]     = 'h0 ;  // sh_cmpt 
   wr_dat[255:180] = 'h0;   // reserved

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31:0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63:32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95:64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_CMPT = 6 : 0110
 // 0      BUSY : 0 
 //        00000000001_01_0110_0 : 1010_1100 : 0xAC
 wr_dat = {14'h0,axi_st_q[10:0],7'b0101100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

  //Also update CIDX 0x00 for CMPT context 
   wr_dat[31:29] = 4'h0;   // reserver = 0
   wr_dat[28]    = 4'h0;   // irq_en_wrb = 0
   wr_dat[27]    = 1'b1;   // en_stat_desc = 1
   wr_dat[26:24] = 3'h1;   // trig_mode = 3'001 (every)
   wr_dat[23:20] = 4'h0;   // timer_idx = 4'h0
   wr_dat[19:16] = 4'h0;   // counter_idx = 4'h0
   wr_dat[15:0]  = 16'h0;  //sw_cidx = 16'h0000

   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 12;  // 32'h0000641C
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], wr_dat[31:0], 4'hF);

 // Initiate C2H tranfer on user side.
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h20, 32'h1, 4'hF);   // send 1 packets 

 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h30, 32'ha4a3a2a1, 4'hF);   // Write back data 
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h34, 32'hb4b3b2b1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h38, 32'hc4c3c2c1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h3C, 32'hd4d3d2d1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h40, 32'he4e3e2e1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h44, 32'hf4f3f2f1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h48, 32'h14131211, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h4C, 32'h24232221, 4'hF);   // Write back data


// Start H2C transfer first
   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 4;  // 32'h00006414
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], 32'h1, 4'hF);   // Write 1 PIDX 

   // insert some time to dalay DSC bypass to settel.
    board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h00);
   
    board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h50, 32'h2, 4'hF);   // writeback data control to set 8B, 16B or 32B

    board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h08, 32'h04, 4'hF);   // Start C2H tranfer and immediate data

   // Compare status writes
   board.RP.tx_usrapp.COMPARE_TRANS_C2H_ST_STATUS(0, 16'h1, 0, 8 ); //Write back entry and write back status

 end
 endtask

task TSK_QDMA_ST_C2H_SIMBYP_TEST;
   input [10:0] qid;
   input dsc_bypass;
begin
   //
// now doing AXI-Stream Test for QDMA
//
// Assign Q 2 for AXI-ST
 pf0_qmax = 11'h200;
 axi_st_q = qid;

 // Write Q number for AXI-ST C2H transfer
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h0, {21'h0,axi_st_q[10:0]}, 4'hF);   // Write Q num to user side 

 $display ("******* AXI-ST C2H SIMPLE Byp transfer START ******** \n");
 $display ("\n");
 $display ("\n");
 //-------------- Load DATA in Buffer for aXI-ST H2C----------------------------------------------------
 // AXI-St H2C Descriptor is at address 0x0100 (256)
 // AXI-St H2c Data       is at address 0x0300 (768)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_H2C_NEW;

 //-------------- Load DATA in Buffer for AXI-ST C2H ----------------------------------------------------
 // AXI-St C2H Descriptor is at address 0x0800 (2048)
 // AXI-St C2H Data       is at address 0x0A00 (2560)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_C2H;
 // AXI-St C2H CMPT Data   is at address 0x1000 (4096)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_CMPT_C2H;     // addrss 0x1000 (4096)

   // enable Simple bypass mode for C2H Stream loopback
   if (dsc_bypass)
     board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h90, 32'h4, 4'hF);

    // initilize all ring size to some value.
    //-------------- Global Ring Size for Queue 0  0x204  : num of dsc 16 ------------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h204, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h208, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h20C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h210, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h214, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h218, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h21C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h220, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h224, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h228, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h22C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h230, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h234, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h238, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h23C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h240, 32'h00000010, 4'hF);

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
		board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), wr_dat[31:0], 4'hF);
	 end else begin
	    wr_dat = 32'h00000000;
		board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), wr_dat[31:0], 4'hF);
	 end
	end

 //-------------- Clear HW CXTX for H2C and C2H first for Q1 ------------------------------------
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_H2C = 3 : 0011
 // 0      BUSY : 0 
 //        00000000001_00_0011_0 : _1000_0110 : 0x86
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000110};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_C2H = 2 : 0010
 // 0      BUSY : 0 
 //        00000000001_00_0010_0 : _1000_0100 : 0x84
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 $display ("******* Program C2H Global and Context values ******** \n");
 // Setup Stream H2C context 
 //-------------- Ind Dire CTXT MASK 0xffffffff for all 256 bits -------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h824, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h828, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h82C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h830, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h834, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h838, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h83C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h840, 32'hffffffff, 4'hF);


 // Program AXI-ST C2H 
 //-------------- Program C2H CMPT timer Trigger to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA00, 32'h00000001, 4'hF);

 //-------------- Program C2H CMPT Counter Threshold to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA40, 32'h00000001, 4'hF);

 //-------------- Program C2H DSC buffer size to 4K ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hAB0, 32'h00001000, 4'hF);

 // setup Stream C2H context
 //-------------- C2H CTXT DATA  -------------------
 // ring size index is at 1
 // 
   wr_dat[255:128] = 'd0;
   wr_dat[127:64]  =  (64'h0 | C2H_ADDR); // dsc base
   wr_dat[63]      =  1'b0;  // is_mm
   wr_dat[62]      =  1'b0;  // mrkr_dis
   wr_dat[61]      =  1'b0;  // irq_req
   wr_dat[60]      =  1'b0;  // err_wb_sent
   wr_dat[59:58]   =  2'b0;  // err        
   wr_dat[57]      =  1'b0;  // irq_no_last
   wr_dat[56:54]   =  3'h0;  // port_id
   wr_dat[53]      =  1'b0;  // irq_en     
   wr_dat[52]      =  1'b1;  // wbk_en     
   wr_dat[51]      =  1'b0;  // mm_chn     
   wr_dat[50]      =  dsc_bypass ? 1'b1 : 1'b0;  // bypass     
   wr_dat[49:48]   =  2'b00; // dsc_sz, 8bytes     
   wr_dat[47:44]   =  4'h1;  // rng_sz     
   wr_dat[43:41]   =  3'h0;  // reserved
   wr_dat[40:37]   =  4'h0;  // fetch_max
   wr_dat[36]      =  1'b0;  // atc
   wr_dat[35]      =  1'b0;  // wbi_intvl_en
   wr_dat[34]      =  1'b1;  // wbi_chk    
   wr_dat[33]      =  1'b1;  // fcrd_en    
   wr_dat[32]      =  1'b1;  // qen        
   wr_dat[31:25]   =  7'h0;  // reserved
   wr_dat[24:17]   =  {4'h0,pfTestIteration[3:0]}; // func_id        
   wr_dat[16]      =  1'b0;  // irq_arm    
   wr_dat[15:0]    =  16'b0; // pidx

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0]  , 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32] , 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64] , 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96] , 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);


 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID : 2
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_DSC_SW_C2H = 0 : 0000
 // 0      BUSY : 0 
 //        00000000001_01_0000_0 : 1010_0000 : 0xA0
 wr_dat = {14'h0,axi_st_q[10:0],7'b0100000};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 //-------------- Completion  CTXT DATA -------------------
   wr_dat[0]      = 1;      // en_stat_desc = 1
   wr_dat[1]      = 0;      // en_int = 0
   wr_dat[4:2]    = 3'h1;   // trig_mode = 3'b001
   wr_dat[12:5]   = {4'h0,pfTestIteration[3:0]};   // function ID
   wr_dat[16:13]  = 4'h0;   // reserved
   wr_dat[20:17]  = 4'h0;   // countr_idx  = 4'b0000 
   wr_dat[24:21]  = 4'h0;   // timer_idx = 4'b0000  
   wr_dat[26:25]  = 2'h0;   // int_st = 2'b00       
   wr_dat[27]     = 1'h1;   // color = 1            
   wr_dat[31:28]  = 4'h0;   // size_64 = 4'h0       
   wr_dat[89:32]  = (58'h0 | CMPT_ADDR[31:6]);  // baddr_64 = [63:6]only 
   wr_dat[91:90]  = 2'h0;   // desc_size = 2'b00    
   wr_dat[107:92] = 16'h0;  // pidx 16              
   wr_dat[123:108]= 16'h0;  // Cidx 16              
   wr_dat[124]    = 1'h1;   // valid = 1            
   wr_dat[126:125]= 2'h0;   // err
   wr_dat[127]    = 'h0;    // user_trig_pend
   wr_dat[128]    = 'h0;    // timer_running
   wr_dat[129]    = 'h0;    // full_upd
   wr_dat[130]    = 'h0;    // ovf_chk_dis
   wr_dat[131]    = 'h0;    // at
   wr_dat[142:132]= 'd4;   // vec MSI-X Vector
   wr_dat[143]     = 'd0;   // int_aggr
   wr_dat[144]     = 'h0;   // dis_intr_on_vf
   wr_dat[145]     = 'h0;   // vio
   wr_dat[146]     = 'h1;   // dir_c2h ; 1 = C2H, 0 = H2C direction
   wr_dat[150:147] = 'h0;   // reserved
   wr_dat[173:151] = 'h0;   // reserved
   wr_dat[174]     = 'h0;   // reserved
   wr_dat[178:175] = 'h0 | CMPT_ADDR[5:2];   // reserved
   wr_dat[179]     = 'h0 ;  // sh_cmpt 
   wr_dat[255:180] = 'h0;   // reserved

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31:0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63:32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95:64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_CMPT = 6 : 0110
 // 0      BUSY : 0 
 //        00000000001_01_0110_0 : 1010_1100 : 0xAC
 wr_dat = {14'h0,axi_st_q[10:0],7'b0101100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

  //Also update CIDX 0x00 for CMPT context 
   wr_dat[31:29] = 4'h0;   // reserver = 0
   wr_dat[28]    = 4'h0;   // irq_en_wrb = 0
   wr_dat[27]    = 1'b1;   // en_stat_desc = 1
   wr_dat[26:24] = 3'h1;   // trig_mode = 3'001 (every)
   wr_dat[23:20] = 4'h0;   // timer_idx = 4'h0
   wr_dat[19:16] = 4'h0;   // counter_idx = 4'h0
   wr_dat[15:0]  = 16'h0;  //sw_cidx = 16'h0000

   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 12;  // 32'h0000641C
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], wr_dat[31:0], 4'hF);

 //-------------- PreFetch CTXT DATA -------------------
   wr_dat[0]      = dsc_bypass ? 1'b1 : 1'b0;  // bypass to 1 for simple bypass
   wr_dat[4:1]    = 4'h0;  // buf_size_idx
   wr_dat[7 :5]   = 3'h0;  // port_id
   wr_dat[15:8]   = 8'h0;  // function id
   wr_dat[19:16]  = 4'h0;  // reserverd
   wr_dat[25:20]  = 5'h0;  // reserverd
   wr_dat[26]     = 1'h0;  // error
   wr_dat[27]     = 1'h0;  // prefetch enable
   wr_dat[28]     = 1'b0;  // prefetch (Q is in prefetch)
   wr_dat[44 :29] = 16'h0; // sw_crdt
   wr_dat[45]     = 1'b1;  // valid
   wr_dat[127:46] = 'h0;

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31:0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63:32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95:64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_PFTCH = 7 : 0111
 // 0      BUSY : 0 
 //        00000000001_01_0111_0 : 1010_1110 : 0xAE
 wr_dat = {14'h0,axi_st_q[10:0],7'b0101110};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // Transfer C2H for 10 dsc

 //-------------- Write PIDX to 1 to transfer 1 descriptor in C2H ----------------
 //  There is no run bit for AXI-Stream, no need to arm them.
   $display(" **** Enable PIDX for C2H first ***\n");
   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 8;  // 32'h00006418
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], 32'h0a, 4'hF);   // Write 0x0a PIDX 

///
 // Initiate C2H tranfer on user side.
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h20, 32'h1, 4'hF);   // send 1 packets 

 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h04, 32'h80, 4'hF);   // C2H length 128 bytes //

 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h30, 32'ha4a3a2a1, 4'hF);   // Write back data 
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h34, 32'hb4b3b2b1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h38, 32'hc4c3c2c1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h3C, 32'hd4d3d2d1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h40, 32'he4e3e2e1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h44, 32'hf4f3f2f1, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h48, 32'h14131211, 4'hF);   // Write back data
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h4C, 32'h24232221, 4'hF);   // Write back data

   // Get Prefetch tag for QID
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 32'h1408, axi_st_q, 4'hF); 
   // Read Prefetch tag for QID
    board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 32'h140C);
   // Write Prefetch tag to AXI side register
    board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h24, 32'h0 | {axi_st_q[10:0],9'h0, P_READ_DATA[6:0]}, 4'hF);

   board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h08, 32'h02, 4'hF);   // Start C2H tranfer

 //compare C2H data
   $display("------Compare C2H AXI-ST 1st Data--------\n");
   // compare data with H2C data in 512
   board.RP.tx_usrapp.COMPARE_DATA_C2H({16'h0,board.RP.tx_usrapp.DMA_BYTE_CNT},512);

   // Compare status writes
   board.RP.tx_usrapp.COMPARE_TRANS_C2H_ST_STATUS(0, 16'h1, 1, 8); //Write back entry and write back status
   
   // uptate CIDX for Write back 
   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 12;  // 32'h0000641C
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], 32'h09000001, 4'hF);
   
 end
 endtask

//   
/* ATC test to test translation table request */
//   
task TSK_QDMA_ATC_TEST;
   input dsc_bypass;
begin
   //
// now doing AXI-Stream Test for QDMA
//
// Assign Q 2 for AXI-ST
 pf0_qmax = 11'h200;
 axi_st_q = 11'h2;

 // Write Q number for AXI-ST C2H transfer
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h0, {21'h0,axi_st_q[10:0]}, 4'hF);   // Write Q num to user side 

 $display ("******* AXI-ST H2C/C2H transfer START ******** \n");
 $display ("\n");
 $display ("\n");
 //-------------- Load DATA in Buffer for aXI-ST H2C----------------------------------------------------
 // AXI-St H2C Descriptor is at address 0x0100 (256)
 // AXI-St H2c Data       is at address 0x0300 (768)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_H2C_NEW;

 //-------------- Load DATA in Buffer for AXI-ST C2H ----------------------------------------------------
 // AXI-St C2H Descriptor is at address 0x0800 (2048)
 // AXI-St C2H Data       is at address 0x0A00 (2560)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_C2H;
 // AXI-St C2H CMPT Data   is at address 0x1000 (4096)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_CMPT_C2H;     // addrss 0x1000 (4096)

   board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h3000);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h3000, 32'h12345678, 4'hF);
   board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h3000);
   
   // enable dsc bypass loopback
   if (dsc_bypass)
     board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h90, 32'h3, 4'hF);

    // initilize all ring size to some value.
    //-------------- Global Ring Size for Queue 0  0x204  : num of dsc 16 ------------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h204, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h208, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h20C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h210, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h214, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h218, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h21C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h220, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h224, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h228, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h22C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h230, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h234, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h238, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h23C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h240, 32'h00000010, 4'hF);

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
		board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), wr_dat[31:0], 4'hF);
	 end else begin
	    wr_dat = 32'h00000000;
		board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), wr_dat[31:0], 4'hF);
	 end
	end

 //-------------- Clear HW CXTX for H2C and C2H first for Q1 ------------------------------------
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_H2C = 3 : 0011
 // 0      BUSY : 0 
 //        00000000001_00_0011_0 : _1000_0110 : 0x86
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000110};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_C2H = 2 : 0010
 // 0      BUSY : 0 
 //        00000000001_00_0010_0 : _1000_0100 : 0x84
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 $display ("******* Program C2H Global and Context values ******** \n");
 // Setup Stream H2C context 
 //-------------- Ind Dire CTXT MASK 0xffffffff for all 256 bits -------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h824, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h828, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h82C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h830, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h834, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h838, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h83C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h840, 32'hffffffff, 4'hF);

 //-------------- Ind Dire CTXT AXI-ST H2C DATA -------------------
 // ring size index is at 1
 // 
   wr_dat[255:140] = 'd0;
   wr_dat[139]     = 'd0;    // int_aggr
   wr_dat[138:128] = 'd3;    // vec MSI-X Vector
   wr_dat[127:64]  =  (64'h0 | H2C_ADDR); // dsc base
   wr_dat[63]      =  1'b0;  // is_mm
   wr_dat[62]      =  1'b0;  // mrkr_dis
   wr_dat[61]      =  1'b0;  // irq_req
   wr_dat[60]      =  1'b0;  // err_wb_sent
   wr_dat[59:58]   =  2'b0;  // err        
   wr_dat[57]      =  1'b0;  // irq_no_last
   wr_dat[56:54]   =  3'h0;  // port_id
   wr_dat[53]      =  1'b0;  // irq_en     
   wr_dat[52]      =  1'b1;  // wbk_en     
   wr_dat[51]      =  1'b0;  // mm_chn     
   wr_dat[50]      =  dsc_bypass ? 1'b1 : 1'b0;  // bypass     
   wr_dat[49:48]   =  2'b01; // dsc_sz, 16bytes     
   wr_dat[47:44]   =  4'h1;  // rng_sz     
   wr_dat[43:40]   =  4'h0;  // reserved
   wr_dat[39:37]   =  3'h0;  // fetch_max
   wr_dat[36]      =  1'b0;  // atc
   wr_dat[35]      =  1'b0;  // wbi_intvl_en
   wr_dat[34]      =  1'b1;  // wbi_chk    
   wr_dat[33]      =  1'b0;  // fcrd_en    
   wr_dat[32]      =  1'b1;  // qen        
   wr_dat[31:25]   =  7'h0;  // reserved
   wr_dat[24:17]   =  {4'h0,pfTestIteration[3:0]}; // func_id        
   wr_dat[16]      =  1'b0;  // irq_arm    
   wr_dat[15:0]    =  16'b0; // pidx

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID : 2
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_DSC_SW_H2C = 1 : 0001
 // 0      BUSY : 0 
 //        00000000001_01_0001_0 : 1010_0010 : 0xA2
 wr_dat = {14'h0,axi_st_q[10:0],7'b0100010};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // Program AXI-ST C2H 
 //-------------- Program C2H CMPT timer Trigger to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA00, 32'h00000001, 4'hF);

 //-------------- Program C2H CMPT Counter Threshold to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA40, 32'h00000001, 4'hF);

 //-------------- Program C2H DSC buffer size to 4K ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hAB0, 32'h00001000, 4'hF);

   fork
      //-------------- Write Queue 1 of PIDX to 1 to transfer 1 descriptor in H2C ----------------
      wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 4;  // 32'h00006414
      board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], 32'h1, 4'hF);   // Write 1 PIDX 
      
      //compare H2C data
      $display("------Compare H2C AXI-ST Data--------\n");
      board.RP.tx_usrapp.COMPARE_TRANS_STATUS(32'h000010F0, 16'h1); 
   join
   #10000
     board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h00);

   //ATC testing start here
   
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h3000, 32'h0200, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h3004, 32'h0000, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h3008, 32'h0001, 4'hF);
   board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h3008);
   board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h3008);
   board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h300C);
   board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h3010);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h3000, 32'h0208, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h3004, 32'h0000, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h3008, 32'h0001, 4'hF);
   board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h3008);
   board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h3008);
   board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h300C);
   board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h3010);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h3000, 32'h0210, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h3004, 32'h0000, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h3008, 32'h0001, 4'hF);
   board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h3008);
   board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h3008);
   board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h300C);
   board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h3010);

 end
 endtask


/*
// Task to loopback Descriptor bypass out from H2C stream to C2H Stream Immediate data
*/
task TSK_QDMA_H2C_LP_C2H_IMM_TEST;
   input [10:0] qid;
   input dsc_bypass;
begin
   //
// now doing AXI-Stream Test for QDMA
//
// Assign Q 2 for AXI-ST
 pf0_qmax = 11'h200;
 axi_st_q = qid;

 // Write Q number for AXI-ST C2H transfer
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h0, {21'h0,axi_st_q[10:0]}, 4'hF);   // Write Q num to user side 

 $display ("\n");
 $display ("******* AXI-ST H2C DSC bypass to C2H IMM data START ******** \n");
 $display ("\n");
 //-------------- Load DATA in Buffer for aXI-ST H2C----------------------------------------------------
 // AXI-St H2C Descriptor is at address 0x0100 (256)
 // AXI-St H2c Data       is at address 0x0200 (512)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_H2C_64B;

 //-------------- Load DATA in Buffer for AXI-ST C2H ----------------------------------------------------
 // AXI-St C2H Descriptor is at address 0x0800 (2048)
 // AXI-St C2H Data       is at address 0x0A00 (2560)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_C2H;
 // AXI-St C2H CMPT Data   is at address 0x1000 (4096)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_CMPT_C2H;     // addrss 0x1000 (4096)

   // enable dsc bypass loopback
   if (dsc_bypass)
     board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h90, 32'h6, 4'hF);

    // initilize all ring size to some value.
    //-------------- Global Ring Size for Queue 0  0x204  : num of dsc 16 ------------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h204, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h208, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h20C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h210, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h214, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h218, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h21C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h220, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h224, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h228, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h22C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h230, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h234, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h238, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h23C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h240, 32'h00000010, 4'hF);

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
		board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), wr_dat[31:0], 4'hF);
	 end else begin
	    wr_dat = 32'h00000000;
		board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), wr_dat[31:0], 4'hF);
	 end
	end

 //-------------- Clear HW CXTX for H2C and C2H first for Q1 ------------------------------------
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_H2C = 3 : 0011
 // 0      BUSY : 0 
 //        00000000001_00_0011_0 : _1000_0110 : 0x86
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000110};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_C2H = 2 : 0010
 // 0      BUSY : 0 
 //        00000000001_00_0010_0 : _1000_0100 : 0x84
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 $display ("******* Program C2H Global and Context values ******** \n");
 // Setup Stream H2C context 
 //-------------- Ind Dire CTXT MASK 0xffffffff for all 256 bits -------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h824, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h828, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h82C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h830, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h834, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h838, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h83C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h840, 32'hffffffff, 4'hF);

 //-------------- Ind Dire CTXT AXI-ST H2C DATA -------------------
 // ring size index is at 1
 // 
   wr_dat[255:140] = 'd0;
   wr_dat[139]     = 'd0;    // int_aggr
   wr_dat[138:128] = 'd3;    // vec MSI-X Vector
   wr_dat[127:64]  =  (64'h0 | H2C_ADDR); // dsc base
   wr_dat[63]      =  1'b0;  // is_mm
   wr_dat[62]      =  1'b0;  // mrkr_dis
   wr_dat[61]      =  1'b0;  // irq_req
   wr_dat[60]      =  1'b0;  // err_wb_sent
   wr_dat[59:58]   =  2'b0;  // err        
   wr_dat[57]      =  1'b0;  // irq_no_last
   wr_dat[56:54]   =  3'h0;  // port_id
   wr_dat[53]      =  1'b0;  // irq_en     
   wr_dat[52]      =  1'b1;  // wbk_en     
   wr_dat[51]      =  1'b0;  // mm_chn     
   wr_dat[50]      =  dsc_bypass ? 1'b1 : 1'b0;  // bypass     
   wr_dat[49:48]   =  2'b11; // dsc_sz, 16bytes     
   wr_dat[47:44]   =  4'h1;  // rng_sz     
   wr_dat[43:40]   =  4'h0;  // reserved
   wr_dat[39:37]   =  3'h0;  // fetch_max
   wr_dat[36]      =  1'b0;  // atc
   wr_dat[35]      =  1'b0;  // wbi_intvl_en
   wr_dat[34]      =  1'b1;  // wbi_chk    
   wr_dat[33]      =  1'b0;  // fcrd_en    
   wr_dat[32]      =  1'b1;  // qen        
   wr_dat[31:25]   =  7'h0;  // reserved
   wr_dat[24:17]   =  {4'h0,pfTestIteration[3:0]}; // func_id        
   wr_dat[16]      =  1'b0;  // irq_arm    
   wr_dat[15:0]    =  16'b0; // pidx

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID : 2
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_DSC_SW_H2C = 1 : 0001
 // 0      BUSY : 0 
 //        00000000001_01_0001_0 : 1010_0010 : 0xA2
 wr_dat = {14'h0,axi_st_q[10:0],7'b0100010};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // Program AXI-ST C2H 
 //-------------- Program C2H CMPT timer Trigger to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA00, 32'h00000001, 4'hF);

 //-------------- Program C2H CMPT Counter Threshold to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA40, 32'h00000001, 4'hF);

 //-------------- Program C2H DSC buffer size to 4K ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hAB0, 32'h00001000, 4'hF);

 //-------------- Completion  CTXT DATA -------------------
   wr_dat[0]      = 1;      // en_stat_desc = 1
   wr_dat[1]      = 0;      // en_int = 0
   wr_dat[4:2]    = 3'h1;   // trig_mode = 3'b001
   wr_dat[12:5]   = {4'h0,pfTestIteration[3:0]};   // function ID
   wr_dat[16:13]  = 4'h0;   // reserved
   wr_dat[20:17]  = 4'h0;   // countr_idx  = 4'b0000 
   wr_dat[24:21]  = 4'h0;   // timer_idx = 4'b0000  
   wr_dat[26:25]  = 2'h0;   // int_st = 2'b00       
   wr_dat[27]     = 1'h1;   // color = 1            
   wr_dat[31:28]  = 4'h0;   // size_64 = 4'h0       
   wr_dat[89:32]  = (58'h0 | CMPT_ADDR[31:6]);  // baddr_64 = [63:6]only 
   wr_dat[91:90]  = 2'b11;   // desc_size = 2'b00    
   wr_dat[107:92] = 16'h0;  // pidx 16              
   wr_dat[123:108]= 16'h0;  // Cidx 16              
   wr_dat[124]    = 1'h1;   // valid = 1            
   wr_dat[126:125]= 2'h0;   // err
   wr_dat[127]    = 'h0;    // user_trig_pend
   wr_dat[128]    = 'h0;    // timer_running
   wr_dat[129]    = 'h0;    // full_upd
   wr_dat[130]    = 'h0;    // ovf_chk_dis
   wr_dat[131]    = 'h0;    // at
   wr_dat[142:132]= 'd4;   // vec MSI-X Vector
   wr_dat[143]     = 'd0;   // int_aggr
   wr_dat[144]     = 'h0;   // dis_intr_on_vf
   wr_dat[145]     = 'h0;   // vio
   wr_dat[146]     = 'h1;   // dir_c2h ; 1 = C2H, 0 = H2C direction
   wr_dat[150:147] = 'h0;   // reserved
   wr_dat[173:151] = 'h0;   // reserved
   wr_dat[174]     = 'h0;   // reserved
   wr_dat[178:175] = 'h0 | CMPT_ADDR[5:2];   // reserved
   wr_dat[179]     = 'h0 ;  // sh_cmpt 
   wr_dat[255:180] = 'h0;   // reserved

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31:0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63:32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95:64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_CMPT = 6 : 0110
 // 0      BUSY : 0 
 //        00000000001_01_0110_0 : 1010_1100 : 0xAC
 wr_dat = {14'h0,axi_st_q[10:0],7'b0101100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

  //Also update CIDX 0x00 for CMPT context 
   wr_dat[31:29] = 4'h0;   // reserver = 0
   wr_dat[28]    = 4'h0;   // irq_en_wrb = 0
   wr_dat[27]    = 1'b1;   // en_stat_desc = 1
   wr_dat[26:24] = 3'h1;   // trig_mode = 3'001 (every)
   wr_dat[23:20] = 4'h0;   // timer_idx = 4'h0
   wr_dat[19:16] = 4'h0;   // counter_idx = 4'h0
   wr_dat[15:0]  = 16'h0;  //sw_cidx = 16'h0000

   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 12;  // 32'h0000641C
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], wr_dat[31:0], 4'hF);

 // Initiate C2H tranfer on user side.
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h20, 32'h1, 4'hF);   // send 1 packets 

 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h04, 32'h80, 4'hF);   // C2H length 128 bytes //

// Start H2C transfer first
   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 4;  // 32'h00006414
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], 32'h1, 4'hF);   // Write 1 PIDX 

   // insert some time to dalay DSC bypass to settel.
    board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h00);
   
    board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h08, 32'h04, 4'hF);   // Start C2H immediate data

    board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h00);
    board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h00);

   // Compare status writes
//   board.RP.tx_usrapp.COMPARE_TRANS_C2H_ST_STATUS(0, 16'h1, 0, 8 ); //Write back entry and write back status
   #10000;

 end
 endtask

task TSK_QDMA_ST_LOOPBACK_TEST;
   input dsc_bypass;
begin
   //
// now doing AXI-Stream Test for QDMA
//
// Assign Q 2 for AXI-ST
 pf0_qmax = 11'h200;
 axi_st_q = 11'h2;

 // Write Q number for AXI-ST C2H transfer
 board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h0, {21'h0,axi_st_q[10:0]}, 4'hF);   // Write Q num to user side 

 $display ("******* AXI-ST H2C/C2H loopback test START ******** \n");
 $display ("\n");
 $display ("\n");
 //-------------- Load DATA in Buffer for aXI-ST H2C----------------------------------------------------
 // AXI-St H2C Descriptor is at address 0x0100 (256)
 // AXI-St H2c Data       is at address 0x0300 (768)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_H2C_NEW;

 //-------------- Load DATA in Buffer for AXI-ST C2H ----------------------------------------------------
 // AXI-St C2H Descriptor is at address 0x0800 (2048)
 // AXI-St C2H Data       is at address 0x0A00 (2560)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_DATA_C2H;
 // AXI-St C2H CMPT Data   is at address 0x1000 (4096)
   board.RP.tx_usrapp.TSK_INIT_QDMA_ST_CMPT_C2H;     // addrss 0x1000 (4096)

   board.RP.tx_usrapp.TSK_REG_WRITE(user_bar, 32'h08, 32'h1, 4'hF); //Enable loopback

    // initilize all ring size to some value.
    //-------------- Global Ring Size for Queue 0  0x204  : num of dsc 16 ------------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h204, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h208, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h20C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h210, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h214, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h218, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h21C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h220, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h224, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h228, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h22C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h230, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h234, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h238, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h23C, 32'h00000010, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h240, 32'h00000010, 4'hF);

 //
 // Global programming
 //
 //-------------- Clear HW CXTX for H2C and C2H first for Q1 ------------------------------------
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_H2C = 3 : 0011
 // 0      BUSY : 0 
 //        00000000001_00_0011_0 : _1000_0110 : 0x86
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000110};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
 // [4:1]  MDMA_CTXT_SELC_DSC_HW_C2H = 2 : 0010
 // 0      BUSY : 0 
 //        00000000001_00_0010_0 : _1000_0100 : 0x84
 wr_dat = {14'h0,axi_st_q[10:0],7'b0000100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);
 
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, 32'h0000008E, 4'hF); //clear C2H prefetch context fro Queue 1

 // Clear HW CTX for Q2
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, 32'h00000106, 4'hF);
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, 32'h00000104, 4'hF); 
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, 32'h0000010E, 4'hF); //clear C2H prefetch context fro Queue 2

 //-------------- Global Function MAP 0x400  : Func0 22:11 Qnumber ( 16 Queue ) : 10:0 Qid_base for this Func
 // set up 16Queues
 // Func number is 0 : 0*4 = 0: address 0x400+ Fnum*4 = 0x400
 // 22:11 : 1_0000 : number of queues for this function. 
 // 10:0  : 000_0000_0000 : Queue off set 
 // 1000_0000_0000_0000 : 0x8000
 	for(pf_loop_index=0; pf_loop_index <= pfTestIteration; pf_loop_index = pf_loop_index + 1)
	begin
	 if(pf_loop_index == pfTestIteration) begin
       board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), 32'h00008000, 4'hF);
	 end else begin
       board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h400+(pf_loop_index*4), 32'h00000000, 4'hF);
	 end
	end


 $display ("******* Program C2H Global and Context values ******** \n");

 // Setup Stream H2C context 
 //-------------- Ind Dire CTXT MASK 0xffffffff for all 256 bits -------------------
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h824, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h828, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h82C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h830, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h834, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h838, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h83C, 32'hffffffff, 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h840, 32'hffffffff, 4'hF);

 //-------------- Ind Dire CTXT AXI-ST H2C DATA -------------------
 // ring size index is at 1
 // 
   wr_dat[255:140] = 'd0;
   wr_dat[139]     = 'd0;    // int_aggr
   wr_dat[138:128] = 'd3;    // vec MSI-X Vector
   wr_dat[127:64]  =  (64'h0 | H2C_ADDR); // dsc base
   wr_dat[63]      =  1'b0;  // is_mm
   wr_dat[62]      =  1'b0;  // mrkr_dis
   wr_dat[61]      =  1'b0;  // irq_req
   wr_dat[60]      =  1'b0;  // err_wb_sent
   wr_dat[59:58]   =  2'b0;  // err        
   wr_dat[57]      =  1'b0;  // irq_no_last
   wr_dat[56:54]   =  3'h0;  // port_id
   wr_dat[53]      =  1'b0;  // irq_en     
   wr_dat[52]      =  1'b1;  // wbk_en     
   wr_dat[51]      =  1'b0;  // mm_chn     
   wr_dat[50]      =  dsc_bypass ? 1'b1 : 1'b0;  // bypass     
   wr_dat[49:48]   =  2'b01; // dsc_sz, 16bytes     
   wr_dat[47:44]   =  4'h1;  // rng_sz     
   wr_dat[43:40]   =  4'h0;  // reserved
   wr_dat[39:37]   =  3'h0;  // fetch_max
   wr_dat[36]      =  1'b0;  // atc
   wr_dat[35]      =  1'b0;  // wbi_intvl_en
   wr_dat[34]      =  1'b1;  // wbi_chk    
   wr_dat[33]      =  1'b0;  // fcrd_en    
   wr_dat[32]      =  1'b1;  // qen        
   wr_dat[31:25]   =  7'h0;  // reserved
   wr_dat[24:17]   =  {4'h0,pfTestIteration[3:0]}; // func_id        
   wr_dat[16]      =  1'b0;  // irq_arm    
   wr_dat[15:0]    =  16'b0; // pidx

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID : 2
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_DSC_SW_H2C = 1 : 0001
 // 0      BUSY : 0 
 //        00000000001_01_0001_0 : 1010_0010 : 0xA2
 wr_dat = {14'h0,axi_st_q[10:0],7'b0100010};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);
 
 // Program AXI-ST C2H 
 //-------------- Program C2H CMPT timer Trigger to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA00, 32'h00000001, 4'hF);

 //-------------- Program C2H CMPT Counter Threshold to 1 ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hA40, 32'h00000001, 4'hF);

 //-------------- Program C2H DSC buffer size to 4K ----------------------------------------------
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'hAB0, 32'h00001000, 4'hF);

 // setup Stream C2H context
 //-------------- C2H CTXT DATA -------------------
 // ring size index is at 1
 // 
   wr_dat[255:128] = 'd0;
   wr_dat[127:64]  =  (64'h0 | C2H_ADDR); // dsc base
   wr_dat[63]      =  1'b0;  // is_mm
   wr_dat[62]      =  1'b0;  // mrkr_dis
   wr_dat[61]      =  1'b0;  // irq_req
   wr_dat[60]      =  1'b0;  // err_wb_sent
   wr_dat[59:58]   =  2'b0;  // err        
   wr_dat[57]      =  1'b0;  // irq_no_last
   wr_dat[56:54]   =  3'h0;  // port_id
   wr_dat[53]      =  1'b0;  // irq_en     
   wr_dat[52]      =  1'b1;  // wbk_en     
   wr_dat[51]      =  1'b0;  // mm_chn     
   wr_dat[50]      =  dsc_bypass ? 1'b1 : 1'b0;  // bypass     
   wr_dat[49:48]   =  2'b00; // dsc_sz, 8bytes     
   wr_dat[47:44]   =  4'h1;  // rng_sz     
   wr_dat[43:40]   =  4'h0;  // reserved
   wr_dat[39:37]   =  3'h0;  // fetch_max
   wr_dat[36]      =  1'b0;  // atc
   wr_dat[35]      =  1'b0;  // wbi_intvl_en
   wr_dat[34]      =  1'b1;  // wbi_chk    
   wr_dat[33]      =  1'b1;  // fcrd_en    
   wr_dat[32]      =  1'b1;  // qen        
   wr_dat[31:25]   =  7'h0;  // reserved
   wr_dat[24:17]   =  {4'h0,pfTestIteration[3:0]}; // func_id        
   wr_dat[16]      =  1'b0;  // irq_arm    
   wr_dat[15:0]    =  16'b0; // pidx

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID : 2
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_DSC_SW_C2H = 0 : 0000
 // 0      BUSY : 0 
 //        00000000001_01_0000_0 : 1010_0000 : 0xA0
 wr_dat = {14'h0,axi_st_q[10:0],7'b0100000};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 //-------------- Completion  CTXT DATA -------------------
   wr_dat[0]      = 1;      // en_stat_desc = 1
   wr_dat[1]      = 0;      // en_int = 0
   wr_dat[4:2]    = 3'h1;   // trig_mode = 3'b001
   wr_dat[12:5]   = {4'h0,pfTestIteration[3:0]};   // function ID
   wr_dat[16:13]  = 4'h0;   // reserved
   wr_dat[20:17]  = 4'h0;   // countr_idx  = 4'b0000 
   wr_dat[24:21]  = 4'h0;   // timer_idx = 4'b0000  
   wr_dat[26:25]  = 2'h0;   // int_st = 2'b00       
   wr_dat[27]     = 1'h1;   // color = 1            
   wr_dat[31:28]  = 4'h0;   // size_64 = 4'h0       
   wr_dat[37:32]  = 6'h0;   // reserved       
   wr_dat[89:38]  = (52'h0 | CMPT_ADDR[31:12]);  // baddr_64 = [63:12]only 
   wr_dat[91:90]  = 2'h0;   // desc_size = 2'b00    
   wr_dat[107:92] = 16'h0;  // pidx 16              
   wr_dat[123:108]= 16'h0;  // Cidx 16              
   wr_dat[124]    = 1'h1;   // valid = 1            
   wr_dat[126:125]= 2'h0;   // err
   wr_dat[127]    = 'h0;    // user_trig_pend
   wr_dat[128]    = 'h0;    // timer_running
   wr_dat[129]    = 'h0;    // full_upd
   wr_dat[130]    = 'h0;    // ovf_chk_dis
   wr_dat[131]    = 'h0;    // at
   wr_dat[142:132] = 'd4;    // vec MSI-X Vector
   wr_dat[143]     = 'd0;    // int_aggr
   wr_dat[159:144] = 'h0;    // reserved

   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31:0], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63:32], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95:64], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, wr_dat[159:128], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, wr_dat[191:160], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, wr_dat[223:192], 4'hF);
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, wr_dat[255:224], 4'hF);

 //-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
 // [17:7] QID   01
 // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
 // [4:1]  MDMA_CTXT_SELC_CMPT = 6 : 0110
 // 0      BUSY : 0 
 //        00000000001_01_0110_0 : 1010_1100 : 0xAC
 wr_dat = {14'h0,axi_st_q[10:0],7'b0101100};
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

  //Also update CIDX 0x00 for CMPT context 
   wr_dat[31:29] = 4'h0;   // reserver = 0
   wr_dat[28]    = 4'h0;   // irq_en_wrb = 0
   wr_dat[27]    = 1'b1;   // en_stat_desc = 1
   wr_dat[26:24] = 3'h1;   // trig_mode = 3'001 (every)
   wr_dat[23:20] = 4'h0;   // timer_idx = 4'h0
   wr_dat[19:16] = 4'h0;   // counter_idx = 4'h0
   wr_dat[15:0]  = 16'h0;  //sw_cidx = 16'h0000

   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 12;  // 32'h0000641C
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], wr_dat[31:0], 4'hF);

 //-------------- PreFetch CTXT DATA all 128 bits -------------------
   wr_dat[0]      = 1'b0;  // bypass
   wr_dat[4:1]    = 4'h0;  // buf_size_idx
   wr_dat[7 :5]   = 3'h0;  // port_id
   wr_dat[15:8]   = 8'h0;  // function id
   wr_dat[19:16]  = 4'h0;  // reserverd
   wr_dat[25:20]  = 5'h0;  // reserverd
   wr_dat[26]     = 1'h0;  // error
   wr_dat[27]     = 1'h0;  // prefetch enable
   wr_dat[28]     = 1'b0;  // prefetch (Q is in prefetch)
   wr_dat[44 :29] = 16'h0; // sw_crdt
   wr_dat[45]     = 1'b1;  // valid
   wr_dat[127:46] = 'h0;
 
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, wr_dat[31 :0], 4'hF);
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, wr_dat[63 :32], 4'hF);
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, wr_dat[95 :64], 4'hF);
 board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, wr_dat[127:96], 4'hF);

//-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : 0 [17:7} : CMD MDMA_CTXT_CMD_WR=1 ---------    
// [17:7] QID : 2
// [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
// [4:1]  MDMA_CTXT_SELC_C2H_PFCH = 7 : 0111
// 0      BUSY : 0 
//        00000000001_01_0001_0 : 1010_0010 : 0xA2
wr_dat = {14'h0,axi_st_q[10:0],7'b0101110};
board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, wr_dat[31:0], 4'hF);

 // Transfer C2H for 1 dsc

 //-------------- Write PIDX to 1 to transfer 1 descriptor in C2H ----------------
 //  There is no run bit for AXI-Stream, no need to arm them.
   $display(" **** Enable PIDX for C2H first ***\n");
   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 8;  // 32'h00006418
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], 32'h0a, 4'hF);   // Write 0x0a PIDX 
   
    // ACI-ST H2C transfer

   //-------------- Start DMA H2C tranfer ------------------------------------------------------
     $display(" **** Start DMA H2C AXI-ST transfer ***\n");
  
   fork
   //-------------- Write Queue 1 of PIDX to 1 to transfer 1 descriptor in H2C ----------------
     wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 4;  // 32'h00006414
     board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], 32'h1, 4'hF);   // Write 1 PIDX 
  
   //compare H2C data
     $display("------Compare H2C AXI-ST Data--------\n");
     board.RP.tx_usrapp.COMPARE_TRANS_STATUS(32'h000010F0, 16'h1); 
   join

 //compare C2H data
   $display("------Compare C2H AXI-ST 1st Data--------\n");
   // compare data with H2C data in 512
   board.RP.tx_usrapp.COMPARE_DATA_C2H({16'h0,board.RP.tx_usrapp.DMA_BYTE_CNT},512);

   // Compare status writes
   board.RP.tx_usrapp.COMPARE_TRANS_C2H_ST_STATUS(0, 16'h1, 1, 8); //Write back entry and write back status
   
   // uptate CIDX for Write back 
   wr_add = QUEUE_PTR_PF_ADDR + (axi_st_q* 16) + 12;  // 32'h0000641C
   board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, wr_add[31:0], 32'h09000001, 4'hF);

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
        wait (board.RP.user_lnk_up == 1);
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
            else if(P_READ_DATA[19:16] == 5)
                $display("[%t] :    Check Max Link Speed = 32.0GT/s - PASSED", $realtime);
        end else begin
            $display("ERROR: [%t] :    Check Max Link Speed - FAILED", $realtime);
            $display("[%t] :    Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime, MAX_LINK_SPEED, P_READ_DATA[19:16]);
            //board.RP.tx_usrapp.test_state =1; // Bypass this test due to H10 RP model set to Gen3
        end

        if  (P_READ_DATA[24:20] == LINK_CAP_MAX_LINK_WIDTH)
              $display("[%t] :    Check Negotiated Link Width = 5'h%x - PASSED", $realtime, LINK_CAP_MAX_LINK_WIDTH);
        else
              $display("[%t] :    Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime, LINK_CAP_MAX_LINK_WIDTH, P_READ_DATA[24:20]);

        // Check Device/Vendor ID
        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h0, 4'hF);
        TSK_WAIT_FOR_READ_DATA;

        if  (P_READ_DATA[31:16] != EP_DEV_ID1) begin
            $display("ERROR: [%t] :    Check Device/Vendor ID - FAILED", $realtime);
            $display("[%t] :    Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime, EP_DEV_ID1, P_READ_DATA);
            board.RP.tx_usrapp.test_state =1;

        //    error_check = 1;
        end else begin
            $display("[%t] :    Check Device/Vendor ID - PASSED", $realtime);
        end

        // Check CMPS
        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, PCIE_DEV_CAP_ADDR, 4'hF); //12'hC4
        TSK_WAIT_FOR_READ_DATA;

        if (P_READ_DATA[2:0] != DEV_CAP_MAX_PAYLOAD_SUPPORTED) begin
            $display("ERROR: [%t] :    Check CMPS ID - FAILED", $realtime);
            $display("[%t] :    Data Error Mismatch, Parameter Data %x != Read data %x", $realtime, DEV_CAP_MAX_PAYLOAD_SUPPORTED, P_READ_DATA[2:0]);
            board.RP.tx_usrapp.test_state =1;
        //    error_check = 1;
        end else begin
            $display("[%t] :    Check CMPS ID - PASSED", $realtime);
        end


        if (error_check == 0) begin
            $display("[%t] :    SYSTEM CHECK PASSED", $realtime);
        end else begin
            $display("ERROR: [%t] :    SYSTEM CHECK FAILED", $realtime);
            board.RP.tx_usrapp.test_state =1;
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

    task TSK_TX_TYPE0_CONFIGURATION_READ; //task_1024
        input    [7:0]    tag_;         // Tag
        input    [11:0]   reg_addr_;    // Register Number
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $system("date +'%X--%x : interface is MIA' >> time.log");
               // $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //--------- CFG TYPE-0 Read Transaction :                     -----------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 32'h0F;            // 2DW Descriptor
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                4'b0,                    // PASID
                                                4'b0,                    // PASID
                                                80'b0,                   // PASID
                                                4'b0,                    // PASID
                                                128'b0,                  // Parity Bit slot - 128 bit
                                                32'b00,                  // TPH ST Tag  - 32 bit
                                                8'b0,                    // TPH Type    - 8 bit
                                                4'b0,                    // TPH Present - 4 bit
                                                1'b0,                    // Discontinue                                   
                                                5'b0000,                 // is_eop3_ptr
                                                5'b0000,                 // is_eop2_ptr
                                                5'b0000,                 // is_eop1_ptr
                                                5'b0000,                 // is_eop0_ptr
                                                4'b0001,                 // is_eop[1:0]
                                                2'b00,                   // is_sop3_ptr[1:0]
                                                2'b00,                   // is_sop2_ptr[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                4'b0001,                   // is_sop[1:0]
                                                16'b0,                // Addr offset
                                                16'b0,                // Last BE of the Write Data -  16 bit
                                                12'b0,first_dw_be_    // First BE of the Write Data - 16 bit
                                               };
 
                                                 
            s_axis_rq_tdata          <= #(Tcq) {768'b0,128'b0,          // 4DW unused             //256
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
                                                128'b0,          // *unused*               //256
                                                768'b0
                                               };

            pcie_tlp_rem             <= #(Tcq)  5'b101;
            set_malformed            <= #(Tcq)  1'b0;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 'b0;
            s_axis_rq_tdata          <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_TYPE0_CONFIGURATION_READ

    /************************************************************
    Task : TSK_TX_TYPE1_CONFIGURATION_READ
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 1 Configuration Read TLP
    *************************************************************/

    task TSK_TX_TYPE1_CONFIGURATION_READ; //task_1024
        input    [7:0]    tag_;         // Tag
        input    [11:0]   reg_addr_;    // Register Number
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $system("date +'%X--%x : interface is MIA' >> time.log");
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //--------- CFG TYPE-0 Read Transaction :                     -----------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 32'h0F;            // 2DW Descriptor
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                4'b0,                    // PASID
                                                4'b0,                    // PASID
                                                80'b0,                   // PASID
                                                4'b0,                    // PASID
                                                128'b0,                  // Parity Bit slot - 128 bit
                                                32'b00,                  // TPH ST Tag  - 32 bit
                                                8'b0,                    // TPH Type    - 8 bit
                                                4'b0,                    // TPH Present - 4 bit
                                                1'b0,                    // Discontinue                                   
                                                5'b0000,                 // is_eop3_ptr
                                                5'b0000,                 // is_eop2_ptr
                                                5'b0000,                 // is_eop1_ptr
                                                5'b0001,                 // is_eop0_ptr
                                                4'b0001,                 // is_eop[1:0]
                                                2'b00,                   // is_sop3_ptr[1:0]
                                                2'b00,                   // is_sop2_ptr[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                4'b0001,                   // is_sop[1:0]
                                                16'b0,                // Addr offset
                                                16'b0,                // Last BE of the Write Data -  16 bit
                                                12'b0,first_dw_be_    // First BE of the Write Data - 16 bit
                                               };
 
                                                
            s_axis_rq_tdata          <= #(Tcq) {768'b0,128'b0,          // 4DW unused             //256
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
                                                896'b0           // *unused*               //256
                                               };
                                               
            pcie_tlp_rem             <= #(Tcq)  5'b101;
            set_malformed            <= #(Tcq)  1'b0;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 'b0;
            s_axis_rq_tdata          <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_TYPE1_CONFIGURATION_READ

    /************************************************************
    Task : TSK_TX_TYPE0_CONFIGURATION_WRITE
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 0 Configuration Write TLP
    *************************************************************/

    task TSK_TX_TYPE0_CONFIGURATION_WRITE; //task_1024
        input    [7:0]    tag_;         // Tag
        input    [11:0]   reg_addr_;    // Register Number
        input    [31:0]   reg_data_;    // Data
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $system("date +'%X--%x : interface is MIA' >> time.log");
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //--------- TYPE-0 CFG Write Transaction :                     -----------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) (AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") ?  1'b0 : 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) (AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") ?  32'hFF : 32'h1F;       // 2DW Descriptor
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                4'b0,                    // PASID
                                                4'b0,                    // PASID
                                                80'b0,                   // PASID
                                                4'b0,                    // PASID
                                                128'b0,                  // Parity Bit slot - 128 bit
                                                32'b00,                  // TPH ST Tag  - 32 bit
                                                8'b0,                    // TPH Type    - 8 bit
                                                4'b0,                    // TPH Present - 4 bit
                                                1'b0,                    // Discontinue                                   
                                                5'b0000,                 // is_eop3_ptr
                                                5'b0000,                 // is_eop2_ptr
                                                5'b0000,                 // is_eop1_ptr
                                                5'b0000,                 // is_eop0_ptr
                                                4'b0001,                 // is_eop[1:0]
                                                2'b00,                   // is_sop3_ptr[1:0]
                                                2'b00,                   // is_sop2_ptr[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                4'b0001,                   // is_sop[1:0]
                                                16'b0,                // Addr offset
                                                16'b0,                // Last BE of the Write Data -  16 bit
                                                12'b0,first_dw_be_    // First BE of the Write Data - 16 bit
                                               };
 
                                                
            s_axis_rq_tdata          <= #(Tcq) {768'b0,96'b0,           // 3 DW unused            //256
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
                                                896'b0            // *unused*              //256
                                               };
                                               
            pcie_tlp_rem             <= #(Tcq)  5'b100;
            set_malformed            <= #(Tcq)  1'b0;

            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            if(AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
               s_axis_rq_tvalid      <= #(Tcq) 1'b1;
               s_axis_rq_tlast       <= #(Tcq) 1'b1;
               s_axis_rq_tkeep       <= #(Tcq) 32'h01;             // 2DW Descriptor

               s_axis_rq_tdata       <= #(Tcq) {768'b0,128'b0,
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
            s_axis_rq_tkeep          <= #(Tcq) 'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 'b0;
            s_axis_rq_tdata          <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_TYPE0_CONFIGURATION_WRITE

    /************************************************************
    Task : TSK_TX_TYPE1_CONFIGURATION_WRITE
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 1 Configuration Write TLP
    *************************************************************/

    task TSK_TX_TYPE1_CONFIGURATION_WRITE; //task_1024
        input    [7:0]    tag_;         // Tag
        input    [11:0]   reg_addr_;    // Register Number
        input    [31:0]   reg_data_;    // Data
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $system("date +'%X--%x : interface is MIA' >> time.log");
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //--------- TYPE-0 CFG Write Transaction :                     -----------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) (AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") ?  1'b0 : 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) (AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") ?  32'hFF : 32'h1F;       // 2DW Descriptor
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                4'b0,                    // PASID
                                                4'b0,                    // PASID
                                                80'b0,                   // PASID
                                                4'b0,                    // PASID
                                                128'b0,                  // Parity Bit slot - 128 bit
                                                32'b00,                  // TPH ST Tag  - 32 bit
                                                8'b0,                    // TPH Type    - 8 bit
                                                4'b0,                    // TPH Present - 4 bit
                                                1'b0,                    // Discontinue                                   
                                                5'b0000,                 // is_eop3_ptr
                                                5'b0000,                 // is_eop2_ptr
                                                5'b0000,                 // is_eop1_ptr
                                                5'b0000,                 // is_eop0_ptr
                                                4'b0001,                 // is_eop[1:0]
                                                2'b00,                   // is_sop3_ptr[1:0]
                                                2'b00,                   // is_sop2_ptr[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                4'b0001,                   // is_sop[1:0]
                                                16'b0,                // Addr offset
                                                16'b0,                // Last BE of the Write Data -  16 bit
                                                12'b0,first_dw_be_    // First BE of the Write Data - 16 bit
                                               };
 
                                                
            s_axis_rq_tdata          <= #(Tcq) {768'b0,96'b0,            // 3 DW unused            //256
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
                                                896'b0            // *unused*              //256
                                               };
                                               
            pcie_tlp_rem             <= #(Tcq)  5'b100;
            set_malformed            <= #(Tcq)  1'b0;

            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            if(AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
               s_axis_rq_tvalid      <= #(Tcq) 1'b1;
               s_axis_rq_tlast       <= #(Tcq) 1'b1;
               s_axis_rq_tkeep       <= #(Tcq) 32'h01;             // 2DW Descriptor

               s_axis_rq_tdata       <= #(Tcq) {768'b0,128'b0,
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
            s_axis_rq_tkeep          <= #(Tcq) 'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 'b0;
            s_axis_rq_tdata          <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_TYPE1_CONFIGURATION_WRITE

    /************************************************************
    Task : TSK_TX_MEMORY_READ_32
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Read 32 TLP
    *************************************************************/

    task TSK_TX_MEMORY_READ_32; //task_1024
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
                $system("date +'%X--%x : interface is MIA' >> time.log");
                $finish(1);
            end
            $display("[%t] : Mem32 Read Req @address %x", $realtime,addr_);
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 32'h0F;             // 2DW Descriptor for Memory Transactions alone
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                4'b0,                    // PASID
                                                4'b0,                    // PASID
                                                80'b0,                   // PASID
                                                4'b0,                    // PASID
                                                128'b0,                  // Parity Bit slot - 128 bit
                                                32'b00,                  // TPH ST Tag  - 32 bit
                                                8'b0,                    // TPH Type    - 8 bit
                                                4'b0,                    // TPH Present - 4 bit
                                                1'b0,                    // Discontinue                                   
                                                5'b0000,                 // is_eop3_ptr
                                                5'b0000,                 // is_eop2_ptr
                                                5'b0000,                 // is_eop1_ptr
                                                5'b0000,                 // is_eop0_ptr
                                                4'b0001,                 // is_eop[1:0]
                                                2'b00,                   // is_sop3_ptr[1:0]
                                                2'b00,                   // is_sop2_ptr[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                4'b0001,                   // is_sop[1:0]
                                                16'b0,                // Addr offset
                                                12'b0,last_dw_be_,     // Last BE of the Write Data -  8 bit
                                                12'b0,first_dw_be_    // First BE of the Write Data - 16 bit
                                               };
         
            s_axis_rq_tdata          <= #(Tcq) {768'b0,128'b0,           // 4 DW unused                                    //256
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
                                                896'b0            // *unused*                                       //256
                                               };

            pcie_tlp_rem             <= #(Tcq)  5'b100;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 'b0;
            s_axis_rq_tdata          <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MEMORY_READ_32

    /************************************************************
    Task : TSK_TX_MEMORY_READ_64
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Read 64 TLP
    *************************************************************/

    task TSK_TX_MEMORY_READ_64; //task_1024
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
                $system("date +'%X--%x : interface is MIA' >> time.log");
                $finish(1);
            end
            $display("[%t] : Mem64 Read Req @address %x", $realtime,addr_[31:0]);
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 32'h0F;             // 2DW Descriptor for Memory Transactions alone
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                4'b0,                    // PASID
                                                4'b0,                    // PASID
                                                80'b0,                   // PASID
                                                4'b0,                    // PASID
                                                128'b0,                  // Parity Bit slot - 128 bit
                                                32'b00,                  // TPH ST Tag  - 32 bit
                                                8'b0,                    // TPH Type    - 8 bit
                                                4'b0,                    // TPH Present - 4 bit
                                                1'b0,                    // Discontinue                                   
                                                5'b0000,                 // is_eop3_ptr
                                                5'b0000,                 // is_eop2_ptr
                                                5'b0000,                 // is_eop1_ptr
                                                5'b0000,                 // is_eop0_ptr
                                                4'b0001,                 // is_eop[1:0]
                                                2'b00,                   // is_sop3_ptr[1:0]
                                                2'b00,                   // is_sop2_ptr[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                4'b0001,                   // is_sop[1:0]
                                                16'b0,                // Addr offset
                                                12'b0,last_dw_be_,     // Last BE of the Write Data -  8 bit
                                                12'b0,first_dw_be_    // First BE of the Write Data - 16 bit
                                               };
                                                  
            s_axis_rq_tdata          <= #(Tcq) {768'b0,128'b0,           // 4 DW unused                                    //256
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
                                                896'b0            // *unused*                                       //256
                                               };
                                                
            pcie_tlp_rem             <= #(Tcq)  5'b100;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 'b0;
            s_axis_rq_tdata          <= #(Tcq) 'b0;
            //----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MEMORY_READ_64

    /************************************************************
    Task : TSK_TX_MEMORY_WRITE_32
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Write 32 TLP
    *************************************************************/

    task TSK_TX_MEMORY_WRITE_32; //task_1024
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
                $system("date +'%X--%x : interface is MIA' >> time.log");
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
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                4'b0,                    // PASID
                                                4'b0,                    // PASID
                                                80'b0,                   // PASID
                                                4'b0,                    // PASID
                                                128'b0,                  // Parity Bit slot - 128 bit
                                                32'b00,                  // TPH ST Tag  - 32 bit
                                                8'b0,                    // TPH Type    - 8 bit
                                                4'b0,                    // TPH Present - 4 bit
                                                1'b0,                    // Discontinue                                   
                                                5'b0,                 // is_eop3_ptr
                                                5'b0,                 // is_eop2_ptr
                                                5'b0,                 // is_eop1_ptr
                                                5'b01111,                 // is_eop0_ptr
                                                4'b0001,                 // is_eop[1:0]
                                                2'b00,                   // is_sop3_ptr[1:0]
                                                2'b00,                   // is_sop2_ptr[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                4'b0001,                   // is_sop[1:0]
                                                16'b0,                // Addr offset
                                                12'b0,last_dw_be_,     // Last BE of the Write Data -  8 bit
                                                12'b0,first_dw_be_    // First BE of the Write Data - 16 bit
                                               };

            s_axis_rq_tdata   <= #(Tcq) { 768'b0, //256
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
                                         data_pcie_i,   // Payload Data
                                          //256
                                         768'b0
                                        };
                                          
            pcie_tlp_rem      <= #(Tcq) (_len > 4) ? 5'b0 : (5-_len);
            set_malformed     <= #(Tcq) 1'b0;
            _len               = (_len > 4) ? (_len - 11'h5) : 11'b0;
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid  <= #(Tcq) 1'b1;

            if (len_i > 4 || AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
                s_axis_rq_tlast          <= #(Tcq) 1'b0;
                s_axis_rq_tkeep          <= #(Tcq) 32'hFF;

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
                    s_axis_rq_tkeep      <= #(Tcq) 32'h1F;
                else if (len_i == 2)
                    s_axis_rq_tkeep      <= #(Tcq) 32'h3F;
                else if (len_i == 3)
                    s_axis_rq_tkeep      <= #(Tcq) 32'h7F;
                else // len_i == 4
                    s_axis_rq_tkeep      <= #(Tcq) 32'hFF;

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
                                1 : begin _len = _len - 1; pcie_tlp_rem  <= #(Tcq) 5'b111; end  // D0---------------------
                                2 : begin _len = _len - 2; pcie_tlp_rem  <= #(Tcq) 5'b110; end  // D0-D1------------------
                                3 : begin _len = _len - 3; pcie_tlp_rem  <= #(Tcq) 5'b101; end  // D0-D1-D2---------------
                                4 : begin _len = _len - 4; pcie_tlp_rem  <= #(Tcq) 5'b100; end  // D0-D1-D2-D3------------
                                5 : begin _len = _len - 5; pcie_tlp_rem  <= #(Tcq) 5'b011; end  // D0-D1-D2-D3-D4---------
                                6 : begin _len = _len - 6; pcie_tlp_rem  <= #(Tcq) 5'b010; end  // D0-D1-D2-D3-D4-D5------
                                7 : begin _len = _len - 7; pcie_tlp_rem  <= #(Tcq) 5'b001; end  // D0-D1-D2-D3-D4-D5-D6---
                                0 : begin _len = _len - 8; pcie_tlp_rem  <= #(Tcq) 5'b000; end  // D0-D1-D2-D3-D4-D5-D6-D7
                            endcase 
                        end else begin
                            _len               = _len - 8; pcie_tlp_rem   <= #(Tcq) 5'b000;     // D0-D1-D2-D3-D4-D5-D6-D7
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
            s_axis_rq_tkeep          <= #(Tcq) 'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 'b0;
            s_axis_rq_tdata          <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MEMORY_WRITE_32

    /************************************************************
    Task : TSK_TX_MEMORY_WRITE_64
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Write 64 TLP
    *************************************************************/

    task TSK_TX_MEMORY_WRITE_64; //task_1024
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
                $system("date +'%X--%x : interface is MIA' >> time.log");
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
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                4'b0,                    // PASID
                                                4'b0,                    // PASID
                                                80'b0,                   // PASID
                                                4'b0,                    // PASID
                                                128'b0,                  // Parity Bit slot - 128 bit
                                                32'b00,                  // TPH ST Tag  - 32 bit
                                                8'b0,                    // TPH Type    - 8 bit
                                                4'b0,                    // TPH Present - 4 bit
                                                1'b0,                    // Discontinue                                   
                                                5'b0,                 // is_eop3_ptr
                                                5'b0,                 // is_eop2_ptr
                                                5'b0,                 // is_eop1_ptr
                                                5'b01111,                 // is_eop0_ptr
                                                4'b0001,                 // is_eop[1:0]
                                                2'b00,                   // is_sop3_ptr[1:0]
                                                2'b00,                   // is_sop2_ptr[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                4'b0001,                   // is_sop[1:0]
                                                16'b0,                // Addr offset
                                                12'b0,last_dw_be_,     // Last BE of the Write Data -  8 bit
                                                12'b0,first_dw_be_    // First BE of the Write Data - 16 bit
                                               };

            s_axis_rq_tdata   <= #(Tcq) { 768'b0,//256
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
                                         , 768'b0
                                        };
                                         
            pcie_tlp_rem      <= #(Tcq) (_len > 3) ? 5'b000 : (4-_len);
            set_malformed     <= #(Tcq) 1'b0;
            _len               = (_len > 3) ? (_len - 11'h4) : 11'h0;
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid  <= #(Tcq) 1'b1;

            if (len_i > 4 || AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
                s_axis_rq_tlast          <= #(Tcq) 1'b0;
                s_axis_rq_tkeep          <= #(Tcq) 32'hFF;

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
                    s_axis_rq_tkeep      <= #(Tcq) 32'h1F;
                else if (len_i == 2)
                    s_axis_rq_tkeep      <= #(Tcq) 32'h3F;
                else if (len_i == 3)
                    s_axis_rq_tkeep      <= #(Tcq) 32'h7F;
                else // len_i == 4
                    s_axis_rq_tkeep      <= #(Tcq) 32'hFF;
                
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
                                1 : begin len_i = len_i - 1; s_axis_rq_tkeep <= #(Tcq) 32'h01; end  // D0---------------------
                                2 : begin len_i = len_i - 2; s_axis_rq_tkeep <= #(Tcq) 32'h03; end  // D0-D1------------------
                                3 : begin len_i = len_i - 3; s_axis_rq_tkeep <= #(Tcq) 32'h07; end  // D0-D1-D2---------------
                                4 : begin len_i = len_i - 4; s_axis_rq_tkeep <= #(Tcq) 32'h0F; end  // D0-D1-D2-D3------------
                                5 : begin len_i = len_i - 5; s_axis_rq_tkeep <= #(Tcq) 32'h1F; end  // D0-D1-D2-D3-D4---------
                                6 : begin len_i = len_i - 6; s_axis_rq_tkeep <= #(Tcq) 32'h3F; end  // D0-D1-D2-D3-D4-D5------
                                7 : begin len_i = len_i - 7; s_axis_rq_tkeep <= #(Tcq) 32'h7F; end  // D0-D1-D2-D3-D4-D5-D6---
                                0 : begin len_i = len_i - 8; s_axis_rq_tkeep <= #(Tcq) 32'hFF; end  // D0-D1-D2-D3-D4-D5-D6-D7
                            endcase 
                        end else begin
                            len_i               = len_i - 8; s_axis_rq_tkeep <= #(Tcq) 32'hFF;      // D0-D1-D2-D3-D4-D5-D6-D7
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
                                1 : begin _len = _len - 1; pcie_tlp_rem <= #(Tcq) 5'b111; end  // D0---------------------
                                2 : begin _len = _len - 2; pcie_tlp_rem <= #(Tcq) 5'b110; end  // D0-D1------------------
                                3 : begin _len = _len - 3; pcie_tlp_rem <= #(Tcq) 5'b101; end  // D0-D1-D2---------------
                                4 : begin _len = _len - 4; pcie_tlp_rem <= #(Tcq) 5'b100; end  // D0-D1-D2-D3------------
                                5 : begin _len = _len - 5; pcie_tlp_rem <= #(Tcq) 5'b011; end  // D0-D1-D2-D3-D4---------
                                6 : begin _len = _len - 6; pcie_tlp_rem <= #(Tcq) 5'b010; end  // D0-D1-D2-D3-D4-D5------
                                7 : begin _len = _len - 7; pcie_tlp_rem <= #(Tcq) 5'b001; end  // D0-D1-D2-D3-D4-D5-D6---
                                0 : begin _len = _len - 8; pcie_tlp_rem <= #(Tcq) 5'b000; end  // D0-D1-D2-D3-D4-D5-D6-D7
                            endcase
                        end else begin
                            _len               = _len - 8; pcie_tlp_rem <= #(Tcq) 5'b000; // D0-D1-D2-D3-D4-D5-D6-D7
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
            s_axis_rq_tkeep          <= #(Tcq) 'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 'b0;
            s_axis_rq_tdata          <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 'b000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MEMORY_WRITE_64

    /************************************************************
    Task : TSK_TX_COMPLETION
    Inputs : Tag, TC, Length, Completion ID
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Completion TLP
    *************************************************************/

    task TSK_TX_COMPLETION; //task_1024
        input    [15:0]   req_id_;      // Requester ID
        input    [7:0]    tag_;         // Tag
        input    [2:0]    tc_;          // Traffic Class
        input    [10:0]   len_;         // Length (in DW)
        input    [11:0]   byte_count_;  // Length (in bytes)
        input    [6:0]    lower_addr_;  // Lower 7-bits of Address of first valid data
        input    [2:0]    comp_status_; // Completion Status. 'b000: Success; 'b001: Unsupported Request; 'b010: Config Request Retry Status;'b100: Completer Abort
        input             ep_;          // Poisoned Data: Payload is invalid if set
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $system("date +'%X--%x : interface is MIA' >> time.log");
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_CC_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_cc_tvalid         <= #(Tcq) 1'b1;
            s_axis_cc_tlast          <= #(Tcq) 1'b1;
            s_axis_cc_tkeep          <= #(Tcq) 32'h0007;
            s_axis_cc_tuser          <= #(Tcq) {(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity : {PARITY_WIDTH{1'b0}}), {(AXI4_CC_TUSER_WIDTH-PARITY_WIDTH){1'b0}}};

            s_axis_cc_tdata          <= #(Tcq) {512'b0, 256'b0, 128'b0, // *unused*
                                                 //128
                                                32'b0,          // *unused*
                                                 //96
                                                1'b0,           // Force ECRC
                                                3'b0,           // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
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
                                                1'b0,           // Attributes {ID Based Ordering}
                                                1'b0,           // *reserved*
                                                1'b0,           // TLP Processing Hints
                                                1'b0,           // TLP Digest Present
                                                ep_,            // Poisoned Req
                                                2'b00,          // Attributes {Relaxed Ordering, No Snoop}
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
                                                 //256
                                                , 768'h0
                                               };
                                               
            pcie_tlp_rem             <= #(Tcq)  5'b1101;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_CC_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_cc_tvalid         <= #(Tcq) 1'b0;
            s_axis_cc_tlast          <= #(Tcq) 1'b0;
            s_axis_cc_tkeep          <= #(Tcq) 32'h0000;
            s_axis_cc_tuser          <= #(Tcq) 'b0;
            s_axis_cc_tdata          <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 5'b0000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_COMPLETION

    /************************************************************
    Task : TSK_TX_COMPLETION_DATA
    Inputs : Tag, TC, Length, Completion ID
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Completion TLP
    *************************************************************/

    task TSK_TX_COMPLETION_DATA; //task_1024
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
        reg     [927:0]  data_axis_i;  // Data Info for s_axis_rq_tdata
        reg     [927:0]  data_pcie_i;  // Data Info for pcie_tlp_data
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
                $system("date +'%X--%x : interface is MIA' >> time.log");
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_CC_RDY);
            //-----------------------------------------------------------------------\\
            // Start of First Data Beat
              data_axis_i        = {29{32'h54535251}};
              data_pcie_i        = {29{32'h51525354}};
          /*  data_axis_i        =  {
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
                                  };*/

            //s_axis_cc_tuser   <= #(Tcq) {(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity : 32'b0),1'b0};
            s_axis_cc_tuser          <= #(Tcq) {(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity : {PARITY_WIDTH{1'b0}}), // parity 64 bit -[80:17]
                                                1'b0,                    // Discontinue          
                                                5'b0000,                 // is_eop3_ptr
                                                5'b0000,                 // is_eop2_ptr  
                                                5'b0000,                 // is_eop1_ptr
                                                (len_i > 29 ? 5'b0 : 5'b0011),                 // is_eop0_ptr  There are 11 Dwords 0-10, 0xA
                                                (len_i > 29 ? 4'b0 : 4'b01),                   // is_eop[1:0]
                                                2'b00,                   // is_sop3_ptr[1:0]
                                                2'b00,                   // is_sop2_ptr[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                4'b01};                  // is_sop[1:0]


            s_axis_cc_tdata   <= #(Tcq) {
                                         ((AXISTEN_IF_CC_ALIGNMENT_MODE == "FALSE" ) ? data_axis_i : 928'h0), // 416-bit completion data
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
                                         
            pcie_tlp_rem      <= #(Tcq) (_len > 12) ? 5'b0000 : (13-_len);
            _len               = (_len > 12) ? (_len - 11'hD) : 11'h0;
            //-----------------------------------------------------------------------\\
            s_axis_cc_tvalid  <= #(Tcq) 1'b1;
            
            if (len_i > 29 || AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE") begin
                s_axis_cc_tlast          <= #(Tcq) 1'b0;
                s_axis_cc_tkeep          <= #(Tcq) 32'hFFFFFFFF;
                
                len_i = (AXISTEN_IF_CC_ALIGNMENT_MODE == "FALSE") ? (len_i - 11'd29) : len_i; // Don't subtract 13 in Address Aligned because
                                                                                             // it's always padded with zeros on first beat
                
                // pcie_tlp_data doesn't append zero even in Address Aligned mode, so it should mark this cycle as the last beat if it has no more payload to log.
                // The AXIS CC interface will need to execute the next cycle, but we're just not going to log that data beat in pcie_tlp_data
                if (_len == 0)
                    TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_CC_RDY);
                else
                    TSK_TX_SYNCHRONIZE(1, 1, 0, `SYNC_CC_RDY);
                
            end else begin
                case (len_i)
                  1 :      begin s_axis_cc_tkeep <= #(Tcq) 32'h0000000F; end
                  2 :      begin s_axis_cc_tkeep <= #(Tcq) 32'h0000001F; end
                  3 :      begin s_axis_cc_tkeep <= #(Tcq) 32'h0000003F; end
                  4 :      begin s_axis_cc_tkeep <= #(Tcq) 32'h0000007F; end
                  5 :      begin s_axis_cc_tkeep <= #(Tcq) 32'h000000FF; end
                  6 :      begin s_axis_cc_tkeep <= #(Tcq) 32'h000001FF; end
                  7 :      begin s_axis_cc_tkeep <= #(Tcq) 32'h000003FF; end
                  8 :      begin s_axis_cc_tkeep <= #(Tcq) 32'h000007FF; end
                  9 :      begin s_axis_cc_tkeep <= #(Tcq) 32'h00000FFF; end
                  10 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h00001FFF; end
                  11 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h00003FFF; end
                  12 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h00007FFF; end
                  13 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h0000FFFF; end
                  14 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h0001FFFF; end
                  15 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h0003FFFF; end
                  16 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h0007FFFF; end
                  17 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h000FFFFF; end
                  18 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h001FFFFF; end
                  19 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h003FFFFF; end
                  20 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h007FFFFF; end
                  21 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h00FFFFFF; end
                  22 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h01FFFFFF; end
                  23 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h03FFFFFF; end
                  24 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h07FFFFFF; end
                  25 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h0FFFFFFF; end
                  26 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h1FFFFFFF; end
                  27 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h3FFFFFFF; end
                  28 :     begin s_axis_cc_tkeep <= #(Tcq) 32'h7FFFFFFF; end
                  default: begin s_axis_cc_tkeep <= #(Tcq) 32'hFFFFFFFF; end
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
                                       DATA_STORE_2[ram_ptr + _j + 63], DATA_STORE_2[ram_ptr + _j + 62], DATA_STORE_2[ram_ptr + _j + 61],
                                       DATA_STORE_2[ram_ptr + _j + 60], DATA_STORE_2[ram_ptr + _j + 59], DATA_STORE_2[ram_ptr + _j + 58],
                                       DATA_STORE_2[ram_ptr + _j + 57], DATA_STORE_2[ram_ptr + _j + 56], DATA_STORE_2[ram_ptr + _j + 55],
                                       DATA_STORE_2[ram_ptr + _j + 54], DATA_STORE_2[ram_ptr + _j + 53], DATA_STORE_2[ram_ptr + _j + 52],
                                       DATA_STORE_2[ram_ptr + _j + 51], DATA_STORE_2[ram_ptr + _j + 50], DATA_STORE_2[ram_ptr + _j + 49],
                                       DATA_STORE_2[ram_ptr + _j + 48], DATA_STORE_2[ram_ptr + _j + 47], DATA_STORE_2[ram_ptr + _j + 46],
                                       DATA_STORE_2[ram_ptr + _j + 45], DATA_STORE_2[ram_ptr + _j + 44], DATA_STORE_2[ram_ptr + _j + 43],
                                       DATA_STORE_2[ram_ptr + _j + 42], DATA_STORE_2[ram_ptr + _j + 41], DATA_STORE_2[ram_ptr + _j + 40],
                                       DATA_STORE_2[ram_ptr + _j + 39], DATA_STORE_2[ram_ptr + _j + 38], DATA_STORE_2[ram_ptr + _j + 37],
                                       DATA_STORE_2[ram_ptr + _j + 36], DATA_STORE_2[ram_ptr + _j + 35], DATA_STORE_2[ram_ptr + _j + 34],
                                       DATA_STORE_2[ram_ptr + _j + 33], DATA_STORE_2[ram_ptr + _j + 32], DATA_STORE_2[ram_ptr + _j + 31],
                                       DATA_STORE_2[ram_ptr + _j + 30], DATA_STORE_2[ram_ptr + _j + 29], DATA_STORE_2[ram_ptr + _j + 28],
                                       DATA_STORE_2[ram_ptr + _j + 27], DATA_STORE_2[ram_ptr + _j + 26], DATA_STORE_2[ram_ptr + _j + 25],
                                       DATA_STORE_2[ram_ptr + _j + 24], DATA_STORE_2[ram_ptr + _j + 23], DATA_STORE_2[ram_ptr + _j + 22],
                                       DATA_STORE_2[ram_ptr + _j + 21], DATA_STORE_2[ram_ptr + _j + 20], DATA_STORE_2[ram_ptr + _j + 19],
                                       DATA_STORE_2[ram_ptr + _j + 18], DATA_STORE_2[ram_ptr + _j + 17], DATA_STORE_2[ram_ptr + _j + 16],
                                       DATA_STORE_2[ram_ptr + _j + 15], DATA_STORE_2[ram_ptr + _j + 14], DATA_STORE_2[ram_ptr + _j + 13],
                                       DATA_STORE_2[ram_ptr + _j + 12], DATA_STORE_2[ram_ptr + _j + 11], DATA_STORE_2[ram_ptr + _j + 10],
                                       DATA_STORE_2[ram_ptr + _j +  9], DATA_STORE_2[ram_ptr + _j +  8], DATA_STORE_2[ram_ptr + _j +  7],
                                       DATA_STORE_2[ram_ptr + _j +  6], DATA_STORE_2[ram_ptr + _j +  5], DATA_STORE_2[ram_ptr + _j +  4],
                                       DATA_STORE_2[ram_ptr + _j +  3], DATA_STORE_2[ram_ptr + _j +  2], DATA_STORE_2[ram_ptr + _j +  1],
                                       DATA_STORE_2[ram_ptr + _j +  0]
                                      } << (aa_dw*4*8);
                        end else begin
                            aa_data = {
                                       DATA_STORE_2[ram_ptr + _j + 63 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 62 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 61 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 60 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 59 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 58 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 57 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 56 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 55 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 54 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 53 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 52 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 51 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 50 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 49 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 48 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 47 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 46 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 45 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 44 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 43 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 42 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 41 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 40 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 39 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 38 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 37 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 36 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 35 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 34 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 33 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 32 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 31 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 30 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 29 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 28 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 27 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 26 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 25 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 24 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 23 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 22 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 21 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 20 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 19 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 18 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 17 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 16 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 15 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 14 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 13 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j + 12 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 11 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j + 10 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j +  9 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j +  8 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j +  7 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j +  6 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j +  5 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j +  4 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j +  3 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j +  2 - (aa_dw*4)], DATA_STORE_2[ram_ptr + _j +  1 - (aa_dw*4)],
                                       DATA_STORE_2[ram_ptr + _j +  0 - (aa_dw*4)]
                                      };
                        end
                                               
                        s_axis_cc_tdata           <= #(Tcq) {32{32'h54535251}};//aa_data;
                        s_axis_cc_tuser          <= #(Tcq) {(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity : {PARITY_WIDTH{1'b0}}), // parity 64 bit -[80:17]
                                                            1'b0,                    // Discontinue          
                                                            5'b0000,                 // is_eop3_ptr
                                                            5'b0000,                 // is_eop2_ptr  
                                                            5'b0000,                 // is_eop1_ptr
                                                            (len_i > 29 ? 5'b0 : 5'b0011),                 // is_eop0_ptr  There are 11 Dwords 0-10, 0xA
                                                            (len_i > 29 ? 4'b0 : 4'b01),                   // is_eop[1:0]
                                                            2'b00,                   // is_sop3_ptr[1:0]
                                                            2'b00,                   // is_sop2_ptr[1:0]
                                                            2'b00,                   // is_sop1_ptr[1:0]
                                                            2'b00,                   // is_sop0_ptr[1:0]
                                                            4'b00};                  // is_sop[1:0]

                        if ((len_i)/32 == 0) begin
                            case (len_i % 32)
                              1 :  begin len_i = len_i - 1;  s_axis_cc_tkeep <= #(Tcq) 32'h00000001; end // D0---------------------------------------------------
                              2 :  begin len_i = len_i - 2;  s_axis_cc_tkeep <= #(Tcq) 32'h00000003; end // D0-D1------------------------------------------------
                              3 :  begin len_i = len_i - 3;  s_axis_cc_tkeep <= #(Tcq) 32'h00000007; end // D0-D1-D2---------------------------------------------
                              4 :  begin len_i = len_i - 4;  s_axis_cc_tkeep <= #(Tcq) 32'h0000000F; end // D0-D1-D2-D3------------------------------------------
                              5 :  begin len_i = len_i - 5;  s_axis_cc_tkeep <= #(Tcq) 32'h0000001F; end // D0-D1-D2-D3-D4---------------------------------------
                              6 :  begin len_i = len_i - 6;  s_axis_cc_tkeep <= #(Tcq) 32'h0000003F; end // D0-D1-D2-D3-D4-D5------------------------------------
                              7 :  begin len_i = len_i - 7;  s_axis_cc_tkeep <= #(Tcq) 32'h0000007F; end // D0-D1-D2-D3-D4-D5-D6---------------------------------
                              8 :  begin len_i = len_i - 8;  s_axis_cc_tkeep <= #(Tcq) 32'h000000FF; end // D0-D1-D2-D3-D4-D5-D6-D7------------------------------
                              9 :  begin len_i = len_i - 9;  s_axis_cc_tkeep <= #(Tcq) 32'h000001FF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8---------------------------
                              10 : begin len_i = len_i - 10; s_axis_cc_tkeep <= #(Tcq) 32'h000003FF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9------------------------
                              11 : begin len_i = len_i - 11; s_axis_cc_tkeep <= #(Tcq) 32'h000007FF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10--------------------
                              12 : begin len_i = len_i - 12; s_axis_cc_tkeep <= #(Tcq) 32'h00000FFF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11----------------
                              13 : begin len_i = len_i - 13; s_axis_cc_tkeep <= #(Tcq) 32'h00001FFF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12------------
                              14 : begin len_i = len_i - 14; s_axis_cc_tkeep <= #(Tcq) 32'h00003FFF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13--------
                              15 : begin len_i = len_i - 15; s_axis_cc_tkeep <= #(Tcq) 32'h00007FFF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13-D14----
                              16 : begin len_i = len_i - 16; s_axis_cc_tkeep <= #(Tcq) 32'h0000FFFF; end
                              17 : begin len_i = len_i - 17; s_axis_cc_tkeep <= #(Tcq) 32'h0001FFFF; end
                              18 : begin len_i = len_i - 18; s_axis_cc_tkeep <= #(Tcq) 32'h0003FFFF; end
                              19 : begin len_i = len_i - 19; s_axis_cc_tkeep <= #(Tcq) 32'h0007FFFF; end
                              20 : begin len_i = len_i - 20; s_axis_cc_tkeep <= #(Tcq) 32'h000FFFFF; end
                              21 : begin len_i = len_i - 21; s_axis_cc_tkeep <= #(Tcq) 32'h001FFFFF; end
                              22 : begin len_i = len_i - 22; s_axis_cc_tkeep <= #(Tcq) 32'h003FFFFF; end
                              23 : begin len_i = len_i - 23; s_axis_cc_tkeep <= #(Tcq) 32'h007FFFFF; end
                              24 : begin len_i = len_i - 24; s_axis_cc_tkeep <= #(Tcq) 32'h00FFFFFF; end
                              25 : begin len_i = len_i - 25; s_axis_cc_tkeep <= #(Tcq) 32'h01FFFFFF; end
                              26 : begin len_i = len_i - 26; s_axis_cc_tkeep <= #(Tcq) 32'h03FFFFFF; end
                              27 : begin len_i = len_i - 27; s_axis_cc_tkeep <= #(Tcq) 32'h07FFFFFF; end
                              28 : begin len_i = len_i - 28; s_axis_cc_tkeep <= #(Tcq) 32'h0FFFFFFF; end
                              29 : begin len_i = len_i - 29; s_axis_cc_tkeep <= #(Tcq) 32'h1FFFFFFF; end
                              30 : begin len_i = len_i - 30; s_axis_cc_tkeep <= #(Tcq) 32'h3FFFFFFF; end
                              31 : begin len_i = len_i - 31; s_axis_cc_tkeep <= #(Tcq) 32'h7FFFFFFF; end
                              0  : begin len_i = len_i - 32; s_axis_cc_tkeep <= #(Tcq) 32'hFFFFFFFF; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13-D14-D15
                            endcase
                        end else begin
                            len_i = len_i - 32; s_axis_cc_tkeep <= #(Tcq) 32'hFFFFFFFF; // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13-D14-D15
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
                    for (_jj = 52; _len != 0; _jj = _jj + 128) begin
                        pcie_tlp_data <= #(Tcq)    {
                                                    DATA_STORE_2[ram_ptr + _jj +  0],  DATA_STORE_2[ram_ptr + _jj +  1],  DATA_STORE_2[ram_ptr + _jj +  2],
                                                    DATA_STORE_2[ram_ptr + _jj +  3],  DATA_STORE_2[ram_ptr + _jj +  4],  DATA_STORE_2[ram_ptr + _jj +  5],
                                                    DATA_STORE_2[ram_ptr + _jj +  6],  DATA_STORE_2[ram_ptr + _jj +  7],  DATA_STORE_2[ram_ptr + _jj +  8],
                                                    DATA_STORE_2[ram_ptr + _jj +  9],  DATA_STORE_2[ram_ptr + _jj + 10],  DATA_STORE_2[ram_ptr + _jj + 11],
                                                    DATA_STORE_2[ram_ptr + _jj + 12],  DATA_STORE_2[ram_ptr + _jj + 13],  DATA_STORE_2[ram_ptr + _jj + 14],
                                                    DATA_STORE_2[ram_ptr + _jj + 15],  DATA_STORE_2[ram_ptr + _jj + 16],  DATA_STORE_2[ram_ptr + _jj + 17],
                                                    DATA_STORE_2[ram_ptr + _jj + 18],  DATA_STORE_2[ram_ptr + _jj + 19],  DATA_STORE_2[ram_ptr + _jj + 20],
                                                    DATA_STORE_2[ram_ptr + _jj + 21],  DATA_STORE_2[ram_ptr + _jj + 22],  DATA_STORE_2[ram_ptr + _jj + 23],
                                                    DATA_STORE_2[ram_ptr + _jj + 24],  DATA_STORE_2[ram_ptr + _jj + 25],  DATA_STORE_2[ram_ptr + _jj + 26],
                                                    DATA_STORE_2[ram_ptr + _jj + 27],  DATA_STORE_2[ram_ptr + _jj + 28],  DATA_STORE_2[ram_ptr + _jj + 29],
                                                    DATA_STORE_2[ram_ptr + _jj + 30],  DATA_STORE_2[ram_ptr + _jj + 31],  DATA_STORE_2[ram_ptr + _jj + 32],
                                                    DATA_STORE_2[ram_ptr + _jj + 33],  DATA_STORE_2[ram_ptr + _jj + 34],  DATA_STORE_2[ram_ptr + _jj + 35],
                                                    DATA_STORE_2[ram_ptr + _jj + 36],  DATA_STORE_2[ram_ptr + _jj + 37],  DATA_STORE_2[ram_ptr + _jj + 38],
                                                    DATA_STORE_2[ram_ptr + _jj + 39],  DATA_STORE_2[ram_ptr + _jj + 40],  DATA_STORE_2[ram_ptr + _jj + 41],
                                                    DATA_STORE_2[ram_ptr + _jj + 42],  DATA_STORE_2[ram_ptr + _jj + 43],  DATA_STORE_2[ram_ptr + _jj + 44],
                                                    DATA_STORE_2[ram_ptr + _jj + 45],  DATA_STORE_2[ram_ptr + _jj + 46],  DATA_STORE_2[ram_ptr + _jj + 47],
                                                    DATA_STORE_2[ram_ptr + _jj + 48],  DATA_STORE_2[ram_ptr + _jj + 49],  DATA_STORE_2[ram_ptr + _jj + 50],
                                                    DATA_STORE_2[ram_ptr + _jj + 51],  DATA_STORE_2[ram_ptr + _jj + 52],  DATA_STORE_2[ram_ptr + _jj + 53],
                                                    DATA_STORE_2[ram_ptr + _jj + 54],  DATA_STORE_2[ram_ptr + _jj + 55],  DATA_STORE_2[ram_ptr + _jj + 56],
                                                    DATA_STORE_2[ram_ptr + _jj + 57],  DATA_STORE_2[ram_ptr + _jj + 58],  DATA_STORE_2[ram_ptr + _jj + 59],
                                                    DATA_STORE_2[ram_ptr + _jj + 60],  DATA_STORE_2[ram_ptr + _jj + 61],  DATA_STORE_2[ram_ptr + _jj + 62],
                                                    DATA_STORE_2[ram_ptr + _jj + 63],  DATA_STORE_2[ram_ptr + _jj + 64],  DATA_STORE_2[ram_ptr + _jj + 65],
                                                    DATA_STORE_2[ram_ptr + _jj + 66],  DATA_STORE_2[ram_ptr + _jj + 67],  DATA_STORE_2[ram_ptr + _jj + 68],
                                                    DATA_STORE_2[ram_ptr + _jj + 69],  DATA_STORE_2[ram_ptr + _jj + 70],  DATA_STORE_2[ram_ptr + _jj + 71],
                                                    DATA_STORE_2[ram_ptr + _jj + 72],  DATA_STORE_2[ram_ptr + _jj + 73],  DATA_STORE_2[ram_ptr + _jj + 74],
                                                    DATA_STORE_2[ram_ptr + _jj + 75],  DATA_STORE_2[ram_ptr + _jj + 76],  DATA_STORE_2[ram_ptr + _jj + 77],
                                                    DATA_STORE_2[ram_ptr + _jj + 78],  DATA_STORE_2[ram_ptr + _jj + 79],  DATA_STORE_2[ram_ptr + _jj + 80],
                                                    DATA_STORE_2[ram_ptr + _jj + 81],  DATA_STORE_2[ram_ptr + _jj + 82],  DATA_STORE_2[ram_ptr + _jj + 83],
                                                    DATA_STORE_2[ram_ptr + _jj + 84],  DATA_STORE_2[ram_ptr + _jj + 85],  DATA_STORE_2[ram_ptr + _jj + 86],
                                                    DATA_STORE_2[ram_ptr + _jj + 87],  DATA_STORE_2[ram_ptr + _jj + 88],  DATA_STORE_2[ram_ptr + _jj + 89],
                                                    DATA_STORE_2[ram_ptr + _jj + 90],  DATA_STORE_2[ram_ptr + _jj + 91],  DATA_STORE_2[ram_ptr + _jj + 92],
                                                    DATA_STORE_2[ram_ptr + _jj + 93],  DATA_STORE_2[ram_ptr + _jj + 94],  DATA_STORE_2[ram_ptr + _jj + 95],
                                                    DATA_STORE_2[ram_ptr + _jj + 96],  DATA_STORE_2[ram_ptr + _jj + 97],  DATA_STORE_2[ram_ptr + _jj + 98],
                                                    DATA_STORE_2[ram_ptr + _jj + 99],  DATA_STORE_2[ram_ptr + _jj + 100], DATA_STORE_2[ram_ptr + _jj + 101],
                                                    DATA_STORE_2[ram_ptr + _jj + 102], DATA_STORE_2[ram_ptr + _jj + 103], DATA_STORE_2[ram_ptr + _jj + 104],
                                                    DATA_STORE_2[ram_ptr + _jj + 105], DATA_STORE_2[ram_ptr + _jj + 106], DATA_STORE_2[ram_ptr + _jj + 107],
                                                    DATA_STORE_2[ram_ptr + _jj + 108], DATA_STORE_2[ram_ptr + _jj + 109], DATA_STORE_2[ram_ptr + _jj + 110],
                                                    DATA_STORE_2[ram_ptr + _jj + 111], DATA_STORE_2[ram_ptr + _jj + 112], DATA_STORE_2[ram_ptr + _jj + 113],
                                                    DATA_STORE_2[ram_ptr + _jj + 114], DATA_STORE_2[ram_ptr + _jj + 115], DATA_STORE_2[ram_ptr + _jj + 116],
                                                    DATA_STORE_2[ram_ptr + _jj + 117], DATA_STORE_2[ram_ptr + _jj + 118], DATA_STORE_2[ram_ptr + _jj + 119],
                                                    DATA_STORE_2[ram_ptr + _jj + 120], DATA_STORE_2[ram_ptr + _jj + 121], DATA_STORE_2[ram_ptr + _jj + 122],
                                                    DATA_STORE_2[ram_ptr + _jj + 123], DATA_STORE_2[ram_ptr + _jj + 124], DATA_STORE_2[ram_ptr + _jj + 125],
                                                    DATA_STORE_2[ram_ptr + _jj + 126], DATA_STORE_2[ram_ptr + _jj + 127]
                                                   };
                                                   
                        if ((_len/32) == 0) begin
                            case (_len % 32)
                                1 :  begin _len = _len - 1;  pcie_tlp_rem  <= #(Tcq) 5'd31; end // D0---------------------------------------------------
                                2 :  begin _len = _len - 2;  pcie_tlp_rem  <= #(Tcq) 5'd30; end // D0-D1------------------------------------------------
                                3 :  begin _len = _len - 3;  pcie_tlp_rem  <= #(Tcq) 5'd29; end // D0-D1-D2---------------------------------------------
                                4 :  begin _len = _len - 4;  pcie_tlp_rem  <= #(Tcq) 5'd28; end // D0-D1-D2-D3------------------------------------------
                                5 :  begin _len = _len - 5;  pcie_tlp_rem  <= #(Tcq) 5'd27; end // D0-D1-D2-D3-D4---------------------------------------
                                6 :  begin _len = _len - 6;  pcie_tlp_rem  <= #(Tcq) 5'd26; end // D0-D1-D2-D3-D4-D5------------------------------------
                                7 :  begin _len = _len - 7;  pcie_tlp_rem  <= #(Tcq) 5'd25; end // D0-D1-D2-D3-D4-D5-D6---------------------------------
                                8 :  begin _len = _len - 8;  pcie_tlp_rem  <= #(Tcq) 5'd24; end // D0-D1-D2-D3-D4-D5-D6-D7------------------------------
                                9 :  begin _len = _len - 9;  pcie_tlp_rem  <= #(Tcq) 5'd23; end // D0-D1-D2-D3-D4-D5-D6-D7-D8---------------------------
                                10 : begin _len = _len - 10; pcie_tlp_rem  <= #(Tcq) 5'd22; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9------------------------
                                11 : begin _len = _len - 11; pcie_tlp_rem  <= #(Tcq) 5'd21; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10--------------------
                                12 : begin _len = _len - 12; pcie_tlp_rem  <= #(Tcq) 5'd20; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11----------------
                                13 : begin _len = _len - 13; pcie_tlp_rem  <= #(Tcq) 5'd19; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12------------
                                14 : begin _len = _len - 14; pcie_tlp_rem  <= #(Tcq) 5'd18; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13--------
                                15 : begin _len = _len - 15; pcie_tlp_rem  <= #(Tcq) 5'd17; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13-D14----
                                16 : begin _len = _len - 16; pcie_tlp_rem <= #(Tcq)  5'd16; end
                                17 : begin _len = _len - 17; pcie_tlp_rem <= #(Tcq)  5'd15; end
                                18 : begin _len = _len - 18; pcie_tlp_rem <= #(Tcq)  5'd14; end
                                19 : begin _len = _len - 19; pcie_tlp_rem <= #(Tcq)  5'd13; end
                                20 : begin _len = _len - 20; pcie_tlp_rem <= #(Tcq)  5'd12; end
                                21 : begin _len = _len - 21; pcie_tlp_rem <= #(Tcq)  5'd11; end
                                22 : begin _len = _len - 22; pcie_tlp_rem <= #(Tcq)  5'd10; end
                                23 : begin _len = _len - 23; pcie_tlp_rem <= #(Tcq)  5'd09; end
                                24 : begin _len = _len - 24; pcie_tlp_rem <= #(Tcq)  5'd08; end
                                25 : begin _len = _len - 25; pcie_tlp_rem <= #(Tcq)  5'd07; end
                                26 : begin _len = _len - 26; pcie_tlp_rem <= #(Tcq)  5'd06; end
                                27 : begin _len = _len - 27; pcie_tlp_rem <= #(Tcq)  5'd05; end
                                28 : begin _len = _len - 28; pcie_tlp_rem <= #(Tcq)  5'd04; end
                                29 : begin _len = _len - 29; pcie_tlp_rem <= #(Tcq)  5'd03; end
                                30 : begin _len = _len - 30; pcie_tlp_rem <= #(Tcq)  5'd02; end
                                31 : begin _len = _len - 31; pcie_tlp_rem <= #(Tcq)  5'd01; end
                                0  : begin _len = _len - 32; pcie_tlp_rem  <= #(Tcq) 5'd00; end // D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13-D14-D15
                            endcase 
                        end else begin
                            _len = _len - 32; pcie_tlp_rem  <= #(Tcq) 5'd00;// D0-D1-D2-D3-D4-D5-D6-D7-D8-D9-D10-D11-D12-D13-D14-D15
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
            s_axis_cc_tkeep          <= #(Tcq) 'h00;
            s_axis_cc_tuser          <= #(Tcq) 'b0;
            s_axis_cc_tdata          <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 5'b0000;
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
                $system("date +'%X--%x : interface is MIA' >> time.log");
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
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                4'b0,                    // PASID
                                                4'b0,                    // PASID
                                                80'b0,                   // PASID
                                                4'b0,                    // PASID
                                                128'b0,                  // Parity Bit slot - 128 bit
                                                32'b00,                  // TPH ST Tag  - 32 bit
                                                8'b0,                    // TPH Type    - 8 bit
                                                4'b0,                    // TPH Present - 4 bit
                                                1'b0,                    // Discontinue                                   
                                                5'b0,                 // is_eop3_ptr
                                                5'b0,                 // is_eop2_ptr
                                                5'b0,                 // is_eop1_ptr
                                                5'b00001,                // is_eop0_ptr
                                                4'b0001,                 // is_eop[1:0]
                                                2'b00,                   // is_sop3_ptr[1:0]
                                                2'b00,                   // is_sop2_ptr[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                4'b0001,                   // is_sop[1:0]
                                                16'b0,                // Addr offset
                                                16'b0,     // Last BE of the Write Data -  8 bit
                                                16'b0    // First BE of the Write Data - 16 bit
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
            s_axis_rq_tkeep          <= #(Tcq) 'h0;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 'b0;
            s_axis_rq_tdata          <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 'b000;
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
                $system("date +'%X--%x : interface is MIA' >> time.log");
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
            s_axis_rq_tuser_wo_parity<= #(Tcq) {
                                                //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                6'b101010,               // Seq Number - 6bit
                                                4'b0,                    // PASID
                                                4'b0,                    // PASID
                                                80'b0,                   // PASID
                                                4'b0,                    // PASID
                                                128'b0,                  // Parity Bit slot - 128 bit
                                                32'b00,                  // TPH ST Tag  - 32 bit
                                                8'b0,                    // TPH Type    - 8 bit
                                                4'b0,                    // TPH Present - 4 bit
                                                1'b0,                    // Discontinue                                   
                                                5'b0,                 // is_eop3_ptr
                                                5'b0,                 // is_eop2_ptr
                                                5'b0,                 // is_eop1_ptr
                                                5'b0,                // is_eop0_ptr
                                                4'b0001,                 // is_eop[1:0]
                                                2'b00,                   // is_sop3_ptr[1:0]
                                                2'b00,                   // is_sop2_ptr[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                4'b0001,                   // is_sop[1:0]
                                                16'b0,                // Addr offset
                                                16'b0,     // Last BE of the Write Data -  8 bit
                                                16'b0    // First BE of the Write Data - 16 bit
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
            s_axis_rq_tkeep          <= #(Tcq) 'h00;
            s_axis_rq_tuser_wo_parity<= #(Tcq) 'b0;
            s_axis_rq_tdata          <= #(Tcq) 'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 'b000;
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
                $system("date +'%X--%x : interface is MIA' >> time.log");
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
                $system("date +'%X--%x : interface is MIA' >> time.log");
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
              //  $finish(1);
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
                board.RP.com_usrapp.TSK_READ_DATA_1024(first_, last_call_,`TX_LOG,pcie_tlp_data,pcie_tlp_rem);
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
                            $display("TIMEOUT ERROR in usrapp_tx:TSK_WAIT_FOR_READ_DATA. Completion data never received.");
                            $system("date +'%X--%x : TIMEOUT ERROR in usrapp_tx:TSK_WAIT_FOR_READ_DATA. Completion data never received.' >> time.log");
                            $finish;
                          end
                        else
                            $display("TIMEOUT WARNING in usrapp_tx:TSK_WAIT_FOR_READ_DATA. Completion data never received.");

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

  task TSK_MSIX_EN;
     reg [31:0] msix_vec_offset;
     reg [2:0] msix_vec_bar;
     
    begin   
            $display("[%t] :MSIX eanable task.", $realtime);
        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, MSIX_CTRL_REG_ADDR[11:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
  
        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, MSIX_CTRL_REG_ADDR[11:0], (32'h80000000 | P_READ_DATA), 4'hC);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(1000);

      // Get the offset of MSIX vector table 
      TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, MSIX_VEC_TABLE_A[11:0], 4'hF);
      DEFAULT_TAG = DEFAULT_TAG + 1;
      TSK_WAIT_FOR_READ_DATA;
      msix_vec_offset = {P_READ_DATA[31:3], 3'b0};
      msix_vec_bar = P_READ_DATA[2:0];
      $display("[%t] :   MSIX Vector table offset is %x on BAR %0d", $realtime, msix_vec_offset, msix_vec_bar); 

//       MSIX_VEC_OFFSET[0] = msix_vec_offset;
       MSIX_VEC_OFFSET[pfTestIteration] = 32'h0003_0000;
       MSIX_VEC_BAR[pfTestIteration] = msix_vec_bar;
       
    end
    endtask

   /************************************************************
   Task : TSK_PROGRAM_MSIX_VEC_TABLE
   Inputs : function number
   Outputs : None
   Description : Program the MSIX vector table
   *************************************************************/	
   task TSK_PROGRAM_MSIX_VEC_TABLE;

     input [7:0] fnc_i;
     integer    i;
     begin
     EP_BUS_DEV_FNS = {8'b0000_0001, fnc_i};     

     for (i=0; i<7; i=i+1) begin
        TSK_REG_WRITE(xdma_bar, MSIX_VEC_OFFSET[fnc_i]+16*i+0*4, 32'hADD00000 + i*4, 4'hF);
    	TSK_REG_WRITE(xdma_bar, MSIX_VEC_OFFSET[fnc_i]+16*i+1*4, 32'h00000000 + i,   4'hF);
    	TSK_REG_WRITE(xdma_bar, MSIX_VEC_OFFSET[fnc_i]+16*i+2*4, 32'hDEAD0000 + i,   4'hF);
    	TSK_REG_WRITE(xdma_bar, MSIX_VEC_OFFSET[fnc_i]+16*i+3*4, 32'h00000000,       4'hF);
     end
     end
   endtask // TSK_PROGRAM_MSIX_VEC_TABLE

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
	
	TSK_MSIX_EN;

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
    else begin
        $display("[%t] : Error: Stuck Hi Address Test failed", $realtime);
        board.RP.tx_usrapp.test_state =1;
    end    


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
    else begin
        $display("[%t] : Error: Stuck Low Address Test failed", $realtime);
        board.RP.tx_usrapp.test_state =1;
     end   


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
       wait(board.RP.cfg_ltssm_state == 6'h0B);
       wait(board.RP.cfg_ltssm_state == 6'h10);
       wait (board.RP.user_lnk_up == 1);
       board.RP.tx_usrapp.TSK_TX_CLK_EAT(100);
       //TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'hD0, 4'hF);
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
        end else begin
          $display("[%t] : Data Error Mismatch -Speed Test Failed", $realtime);
          board.RP.tx_usrapp.test_state =1;
        end  

   end
endtask // TSK_SPEED_CHANGE

/************************************************************
Task : TSK_REG_WRITE
Input : BAR Number
Input : Register Address
Input : data value
Input : byte_en
Outputs : None
Description : Register Writes to any BAR
*************************************************************/
task TSK_REG_WRITE;

  input integer bar_num;
  input [31:0] addr;
  input [31:0] data;
  input [3:0] byte_en;

   begin 

        DATA_STORE[0] = data[7:0];
        DATA_STORE[1] = data[15:8];
        DATA_STORE[2] = data[23:16];
        DATA_STORE[3] = data[31:24];

  $display("[%t] : Sending Data write task at address %h with data %h" ,$realtime, addr, data);

        if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[bar_num] == 2'b10) begin
          board.RP.tx_usrapp.TSK_TX_MEMORY_WRITE_32(board.RP.tx_usrapp.DEFAULT_TAG,
              board.RP.tx_usrapp.DEFAULT_TC, 11'd1,
              board.RP.tx_usrapp.BAR_INIT_P_BAR[bar_num][31:0]+addr[20:0], 4'h0, byte_en, 1'b0);
        end else if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[bar_num] == 2'b11) begin                  
          board.RP.tx_usrapp.TSK_TX_MEMORY_WRITE_64(board.RP.tx_usrapp.DEFAULT_TAG,
              board.RP.tx_usrapp.DEFAULT_TC, 11'd1,{board.RP.tx_usrapp.BAR_INIT_P_BAR[bar_num+1][31:0],
              board.RP.tx_usrapp.BAR_INIT_P_BAR[bar_num][31:0]+addr[20:0]}, 4'h0, byte_en, 1'b0);
        end
        board.RP.tx_usrapp.TSK_TX_CLK_EAT(100);
        board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;

  $display("[%t] : Done register write!!" ,$realtime);  

end

endtask
/************************************************************
Task : TSK_REG_READ
Input : BAR number
Input : Register address
Outputs : None
Description : Register Reads to any bar 
*************************************************************/
   
task TSK_REG_READ;
  input integer bar_num;
  input [15:0] read_addr;

  begin	
     board.RP.tx_usrapp.P_READ_DATA = 32'hffff_ffff;
     fork
        if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[bar_num] == 2'b10) begin
            board.RP.tx_usrapp.TSK_TX_MEMORY_READ_32(board.RP.tx_usrapp.DEFAULT_TAG,
                  board.RP.tx_usrapp.DEFAULT_TC, 11'd1,
                  board.RP.tx_usrapp.BAR_INIT_P_BAR[bar_num][31:0]+read_addr[15:0], 4'h0, 4'hF);
        end else if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[bar_num] == 2'b11) begin                  
            board.RP.tx_usrapp.TSK_TX_MEMORY_READ_64(board.RP.tx_usrapp.DEFAULT_TAG,
                 board.RP.tx_usrapp.DEFAULT_TC, 11'd1,{board.RP.tx_usrapp.BAR_INIT_P_BAR[bar_num+1][31:0],
                 board.RP.tx_usrapp.BAR_INIT_P_BAR[bar_num][31:0]+read_addr[15:0]}, 4'h0, 4'hF);
     $display ("[%t] : Target Address %h",$realtime , {board.RP.tx_usrapp.BAR_INIT_P_BAR[bar_num+1][31:0],
                 board.RP.tx_usrapp.BAR_INIT_P_BAR[bar_num][31:0]+read_addr[15:0]});
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
                    board.RP.tx_usrapp.DEFAULT_TC, 11'd1,
                   {board.RP.tx_usrapp.BAR_INIT_P_BAR[jj+1][31:0],
                    board.RP.tx_usrapp.BAR_INIT_P_BAR[jj][31:0]+16'h0}, 4'h0, 4'hF);
                board.RP.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
          end
       join
       board.RP.tx_usrapp.TSK_TX_CLK_EAT(10);
      
    if((board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[jj] == 2'b10) || (board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[jj] == 2'b11)) begin
        board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;

        $display ("[%t] : Data read %h from Address 0x0000",$realtime , board.RP.tx_usrapp.P_READ_DATA);
        if (board.RP.tx_usrapp.P_READ_DATA[31:16] == 16'h1FD3 ) begin  //Mask [15:0] which will have revision number.
               xdma_bar = jj;
               xdma_bar_found = 1;
               $display (" QDMA BAR found : BAR %d is QDMA BAR\n", xdma_bar);
               end
        else if (board.RP.tx_usrapp.P_READ_DATA[31:16] == 16'h1FC0) begin  // XDMA Mask [15:0] which will have revision number.
               xdma_bar = jj;
               xdma_bar_found = 1;
               $display (" XDMA BAR found : BAR %d is XDMA BAR\n", xdma_bar);
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
    DATA_STORE[256+0] = 8'h13; // -- Magic
    DATA_STORE[256+1] = 8'h00;
    DATA_STORE[256+2] = 8'h4b;
    DATA_STORE[256+3] = 8'had;
    DATA_STORE[256+4] = DMA_BYTE_CNT[7:0]; //-- Length lsb
    DATA_STORE[256+5] = DMA_BYTE_CNT[15:8];//-- Length msb
    DATA_STORE[256+6] = 8'h00;
    DATA_STORE[256+7] = 8'h00;
    DATA_STORE[256+8] = 8'h00; //-- Src_add [31:0] x0400
    DATA_STORE[256+9] = 8'h04;
    DATA_STORE[256+10] = 8'h00;
    DATA_STORE[256+11] = 8'h00;
    DATA_STORE[256+12] = 8'h00; //-- Src add [63:32]
    DATA_STORE[256+13] = 8'h00;
    DATA_STORE[256+14] = 8'h00;
    DATA_STORE[256+15] = 8'h00;
    DATA_STORE[256+16] = 8'h00; //-- Dst add [31:0] x0000
    DATA_STORE[256+17] = 8'h00;
    DATA_STORE[256+18] = 8'h00;
    DATA_STORE[256+19] = 8'h00;
    DATA_STORE[256+20] = 8'h00; //-- Dst add [63:32]
    DATA_STORE[256+21] = 8'h00;
    DATA_STORE[256+22] = 8'h00;
    DATA_STORE[256+23] = 8'h00;
    DATA_STORE[256+24] = 8'h00; //-- Nxt add [31:0]
    DATA_STORE[256+25] = 8'h00;
    DATA_STORE[256+26] = 8'h00;
    DATA_STORE[256+27] = 8'h00;
    DATA_STORE[256+28] = 8'h00; //-- Nxt add [63:32]
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
    $display(" **** TASK QDMA MM H2C DSC at address 0x%h ***\n", H2C_ADDR);

    $display(" **** Initilize Descriptor data ***\n");
    for (k=0;k<8;k=k+1) begin
       DATA_STORE[H2C_ADDR+(k*32)+0] = 8'h00; //-- Src_add [31:0] x300
       DATA_STORE[H2C_ADDR+(k*32)+1] = 8'h03;
       DATA_STORE[H2C_ADDR+(k*32)+2] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+3] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+4] = 8'h00; //-- Src add [63:32]
       DATA_STORE[H2C_ADDR+(k*32)+5] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+6] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+7] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+8] = DMA_BYTE_CNT[7:0]; // [71:64] len [7:0] 28bits
       DATA_STORE[H2C_ADDR+(k*32)+9] = DMA_BYTE_CNT[15:8];// [79:72] len [15:8]  
       DATA_STORE[H2C_ADDR+(k*32)+10] = 8'h00;            // [87:80] len [23:16]
       DATA_STORE[H2C_ADDR+(k*32)+11] = 8'h40;            // [96:88] {Rsvd, SDI, EOP, SOP, len[27:24]}. last dsc send SDI to make DMA send completion
       DATA_STORE[H2C_ADDR+(k*32)+12] = 8'h00; // [104:97] Reserved 32bits
       DATA_STORE[H2C_ADDR+(k*32)+13] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+14] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+15] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+16] = 8'h00; // Dst add 64bits [31:0] 0x0000
       DATA_STORE[H2C_ADDR+(k*32)+17] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+18] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+19] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+20] = 8'h01; // Dst add 64 bits [63:32]
       DATA_STORE[H2C_ADDR+(k*32)+21] = 8'h02;
       DATA_STORE[H2C_ADDR+(k*32)+22] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+23] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+24] = 8'h00; // 64 bits Reserved [31:0]
       DATA_STORE[H2C_ADDR+(k*32)+25] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+26] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+27] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+28] = 8'h00; // Reserved [63:32]
       DATA_STORE[H2C_ADDR+(k*32)+29] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+30] = 8'h00;
       DATA_STORE[H2C_ADDR+(k*32)+31] = 8'h00;
    end // for (k=0;k<8;k=k+1)
      
    //Intilize Status write back location to 0's  
    DATA_STORE[H2C_ADDR + (32*15) +0] = 8'h00;
    DATA_STORE[H2C_ADDR + (32*15) +1] = 8'h00;
    DATA_STORE[H2C_ADDR + (32*15) +2] = 8'h00;
    DATA_STORE[H2C_ADDR + (32*15) +3] = 8'h00;

//    for (k = 0; k < 32; k = k + 1)  begin
//        $display(" **** Descriptor data *** data = %h, addr= %d\n", DATA_STORE[H2C_ADDR+k], H2C_ADDR+k);
//        #(Tcq);
//    end
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

    $display(" **** TASK QDMA MM C2H DSC at address 0x0800 ***\n");

    $display(" **** Initilize Descriptor data ***\n");
    for (k=0;k<8;k=k+1) begin
      DATA_STORE[C2H_ADDR+(k*32)+0] = 8'h00; //-- Src_add [31:0]
      DATA_STORE[C2H_ADDR+(k*32)+1] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+2] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+3] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+4] = 8'h01; //-- Src add [63:32]
      DATA_STORE[C2H_ADDR+(k*32)+5] = 8'h02;
      DATA_STORE[C2H_ADDR+(k*32)+6] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+7] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+8] = DMA_BYTE_CNT[7:0]; // [71:64] len [7:0] 28bits
      DATA_STORE[C2H_ADDR+(k*32)+9] = DMA_BYTE_CNT[15:8];// [79:72] len [15:8]  
      DATA_STORE[C2H_ADDR+(k*32)+10] = 8'h00;            // [87:80] len [23:16]
      DATA_STORE[C2H_ADDR+(k*32)+11] = 8'h40;            // [96:88] {Rsvd, SDI, EOP, SOP, len[27:24]}. last dsc send SDI to make DMA send comnpletion
      DATA_STORE[C2H_ADDR+(k*32)+12] = 8'h00; // [104:97] Reserved 32bits
      DATA_STORE[C2H_ADDR+(k*32)+13] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+14] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+15] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+16] = 8'h00; // Dst add 64bits [31:0] 0x1600
      DATA_STORE[C2H_ADDR+(k*32)+17] = 8'h0A;
      DATA_STORE[C2H_ADDR+(k*32)+18] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+19] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+20] = 8'h00; // Dst add 64 bits [63:32]
      DATA_STORE[C2H_ADDR+(k*32)+21] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+22] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+23] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+24] = 8'h00; // 64 bits Reserved [31:0]
      DATA_STORE[C2H_ADDR+(k*32)+25] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+26] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+27] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+28] = 8'h00; // Reserved [63:32]
      DATA_STORE[C2H_ADDR+(k*32)+29] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+30] = 8'h00;
      DATA_STORE[C2H_ADDR+(k*32)+31] = 8'h00;
    end

    //Intilize Status write back location to 0's  
    DATA_STORE[C2H_ADDR + (32*15) +0] = 8'h00;
    DATA_STORE[C2H_ADDR + (32*15) +1] = 8'h00;
    DATA_STORE[C2H_ADDR + (32*15) +2] = 8'h00;
    DATA_STORE[C2H_ADDR + (32*15) +3] = 8'h00;
      
//    for (k = 0; k < 32; k = k + 1)  begin
//        $display(" **** Descriptor data *** data = %h, addr= %d\n", DATA_STORE[C2H_ADDR+k], C2H_ADDR+k);
//        #(Tcq);
//    end
    for (k = 0; k < DMA_BYTE_CNT; k = k + 1)  begin
        #(Tcq) DATA_STORE[2560+k] = 8'h00;  
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
    $display(" **** TASK QDMA ST H2C DSC at address 0x%h ***\n", H2C_ADDR);

    $display(" **** Initilize Descriptor data ***\n");
    DATA_STORE[H2C_ADDR+0] = 8'h00; //-- Src_add [31:0] x0200
    DATA_STORE[H2C_ADDR+1] = 8'h02;
    DATA_STORE[H2C_ADDR+2] = 8'h00;
    DATA_STORE[H2C_ADDR+3] = 8'h00;
    DATA_STORE[H2C_ADDR+4] = 8'h00; //-- Src add [63:32]
    DATA_STORE[H2C_ADDR+5] = 8'h00;
    DATA_STORE[H2C_ADDR+6] = 8'h00;
    DATA_STORE[H2C_ADDR+7] = 8'h00;
    DATA_STORE[H2C_ADDR+8] = DMA_BYTE_CNT[7:0]; // [71:64] len [7:0] 28bits
    DATA_STORE[H2C_ADDR+9] = DMA_BYTE_CNT[15:8];// [79:72] len [15:8]  
    DATA_STORE[H2C_ADDR+10] = 8'h00;            // [87:80] len [23:16]
    DATA_STORE[H2C_ADDR+11] = 8'h70;            // [96:88] {Reserved, EOP, SOP, Dsc vld, len[27:24]}
    DATA_STORE[H2C_ADDR+12] = 8'h00; // [104:97] Reserved 32bits
    DATA_STORE[H2C_ADDR+13] = 8'h00;
    DATA_STORE[H2C_ADDR+14] = 8'h00;
    DATA_STORE[H2C_ADDR+15] = 8'h00;

    //Intilize Status write back location to 0's  
    DATA_STORE[496+0] = 8'h00;
    DATA_STORE[496+1] = 8'h00;
    DATA_STORE[496+2] = 8'h00;
    DATA_STORE[496+3] = 8'h00;
      
//    for (k = 0; k < 16; k = k + 1)  begin
//        $display(" **** Descriptor data *** data = %h, addr= %d\n", DATA_STORE[H2C_ADDR+k], H2C_ADDR+k);
//        #(Tcq);
//    end
      data_tmp = 0;
    for (k = 0; k < 256; k = k + 2)  begin
        DATA_STORE[512+k]   = data_tmp[7:0];
        DATA_STORE[512+k+1] = data_tmp[15:8];
        data_tmp[15:0] = data_tmp[15:0]+1;
   //     $display(" ****initial data data_tmp = %h addr 512+k = %d\n", data_tmp[15:0], 512+k);
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
   integer dsc_num;
   begin
    $display(" **** TASK QDMA ST H2C DSC at address 0x%h ***\n", H2C_ADDR);
    $display(" **** Initilize Descriptor data ***\n");
    dsc_num = 16;

    DATA_STORE[H2C_ADDR+0]  = 8'h00; // 32Bits Reserved 
    DATA_STORE[H2C_ADDR+1]  = 8'h00;
    DATA_STORE[H2C_ADDR+2]  = DMA_BYTE_CNT[7:0]; // Packet length for ST loopback desin
    DATA_STORE[H2C_ADDR+3]  = DMA_BYTE_CNT[15:8];
    DATA_STORE[H2C_ADDR+4]  = DMA_BYTE_CNT[7:0];  // Packet length 16 bits [7:0]
    DATA_STORE[H2C_ADDR+5]  = DMA_BYTE_CNT[15:8]; // Packet length 16 bits [15:8]
    DATA_STORE[H2C_ADDR+6]  = 8'h03; // Reserved // bot EOP and SOP is set for Dsc bypass to work.
    DATA_STORE[H2C_ADDR+7]  = 8'h00;
    DATA_STORE[H2C_ADDR+8]  = 8'h00; //-- Src_add [31:0] x0300
    DATA_STORE[H2C_ADDR+9]  = 8'h03;
    DATA_STORE[H2C_ADDR+10] = 8'h00;
    DATA_STORE[H2C_ADDR+11] = 8'h00;
    DATA_STORE[H2C_ADDR+12] = 8'h00; //-- Src_add [63:32] x0000
    DATA_STORE[H2C_ADDR+13] = 8'h00;
    DATA_STORE[H2C_ADDR+14] = 8'h00;
    DATA_STORE[H2C_ADDR+15] = 8'h00;

    //Intilize Status write back location to 0's  
    DATA_STORE[H2C_ADDR + ((dsc_num-1)*16) +0] = 8'h00;
    DATA_STORE[H2C_ADDR + ((dsc_num-1)*16) +1] = 8'h00;
    DATA_STORE[H2C_ADDR + ((dsc_num-1)*16) +2] = 8'h00;
    DATA_STORE[H2C_ADDR + ((dsc_num-1)*16) +3] = 8'h00;
    data_tmp = 0;
    for (k = 0; k < 1024; k = k + 2)  begin
        DATA_STORE[768+k]   = data_tmp[7:0];
        DATA_STORE[768+k+1] = data_tmp[15:8];
        data_tmp[15:0] = data_tmp[15:0]+1;
  //      $display(" ****initial data data_tmp = %h addr 768+k = %d\n", data_tmp[15:0], 768+k);
    end

   end
endtask

/************************************************************
Task : TSK_INIT_QDMA_ST_DATA_H2C_64B
Inputs : None
Outputs : None
Description : Initialize Descriptor and Data 
*************************************************************/

task TSK_INIT_QDMA_ST_DATA_H2C_64B;
   integer k;
   begin
    $display(" **** TASK QDMA ST H2C DSC at address 0x%h ***\n", H2C_ADDR);

    $display(" **** Initilize Descriptor data ***\n");
    data_tmp = 0;
    for (k=0;k<8;k=k+1) begin
    DATA_STORE[H2C_ADDR+(k*64)+0]  = 8'h00; // 32Bits Reserved 
    DATA_STORE[H2C_ADDR+(k*64)+1]  = data_tmp[7:0]; // data_tmp[7:0];
    DATA_STORE[H2C_ADDR+(k*64)+2]  = DMA_BYTE_CNT[7:0]; // Packet length for ST loopback desin
    DATA_STORE[H2C_ADDR+(k*64)+3]  = DMA_BYTE_CNT[15:8];
    DATA_STORE[H2C_ADDR+(k*64)+4]  = DMA_BYTE_CNT[7:0];  // Packet length 16 bits [7:0]
    DATA_STORE[H2C_ADDR+(k*64)+5]  = DMA_BYTE_CNT[15:8]; // Packet length 16 bits [15:8]
    DATA_STORE[H2C_ADDR+(k*64)+6]  = 8'h01; // Reserved // bot EOP and SOP is set for Dsc bypass to work.
    DATA_STORE[H2C_ADDR+(k*64)+7]  = 8'h02;
    DATA_STORE[H2C_ADDR+(k*64)+8]  = 8'h03; //-- Src_add [31:0] x0200
    DATA_STORE[H2C_ADDR+(k*64)+9]  = 8'h04;
    DATA_STORE[H2C_ADDR+(k*64)+10] = 8'h05;
    DATA_STORE[H2C_ADDR+(k*64)+11] = 8'h06;
    DATA_STORE[H2C_ADDR+(k*64)+12] = 8'h07; //-- Src_add [63:32] x0000
    DATA_STORE[H2C_ADDR+(k*64)+13] = 8'h08;
    DATA_STORE[H2C_ADDR+(k*64)+14] = 8'h09;
    DATA_STORE[H2C_ADDR+(k*64)+15] = 8'h0a;

    DATA_STORE[H2C_ADDR+(k*64)+16]  = 8'h0b; // 32Bits Reserved 
    DATA_STORE[H2C_ADDR+(k*64)+17]  = 8'h0c;
    DATA_STORE[H2C_ADDR+(k*64)+18]  = 8'h0d; // Packet length for ST loopback desin
    DATA_STORE[H2C_ADDR+(k*64)+19]  = 8'h0e;
    DATA_STORE[H2C_ADDR+(k*64)+20]  = 8'h0f;  // Packet length 16 bits [7:0]
    DATA_STORE[H2C_ADDR+(k*64)+21]  = 8'h10; // Packet length 16 bits [15:8]
    DATA_STORE[H2C_ADDR+(k*64)+22]  = 8'h12; // Reserved // bot EOP and SOP is set for Dsc bypass to work.
    DATA_STORE[H2C_ADDR+(k*64)+23]  = 8'h13;
    DATA_STORE[H2C_ADDR+(k*64)+24]  = 8'h14; //-- Src_add [31:0] x0200
    DATA_STORE[H2C_ADDR+(k*64)+25]  = 8'h15;
    DATA_STORE[H2C_ADDR+(k*64)+26] = 8'h16;
    DATA_STORE[H2C_ADDR+(k*64)+27] = 8'h17;
    DATA_STORE[H2C_ADDR+(k*64)+28] = 8'h18; //-- Src_add [63:32] x0000
    DATA_STORE[H2C_ADDR+(k*64)+29] = 8'h19;
    DATA_STORE[H2C_ADDR+(k*64)+30] = 8'h1a;
    DATA_STORE[H2C_ADDR+(k*64)+31] = 8'h1b;

    DATA_STORE[H2C_ADDR+(k*64)+32]  = 8'h1c; // 32Bits Reserved 
    DATA_STORE[H2C_ADDR+(k*64)+33]  = 8'h1e;
    DATA_STORE[H2C_ADDR+(k*64)+34]  = 8'h1f; // Packet length for ST loopback desin
    DATA_STORE[H2C_ADDR+(k*64)+35]  = 8'h20;
    DATA_STORE[H2C_ADDR+(k*64)+36]  = 8'h21;  // Packet length 16 bits [7:0]
    DATA_STORE[H2C_ADDR+(k*64)+37]  = 8'h22; // Packet length 16 bits [15:8]
    DATA_STORE[H2C_ADDR+(k*64)+38]  = 8'h23; // Reserved // bot EOP and SOP is set for Dsc bypass to work.
    DATA_STORE[H2C_ADDR+(k*64)+39]  = 8'h24;
    DATA_STORE[H2C_ADDR+(k*64)+40]  = 8'h25; //-- Src_add [31:0] x0200
    DATA_STORE[H2C_ADDR+(k*64)+41]  = 8'h26;
    DATA_STORE[H2C_ADDR+(k*64)+42] = 8'h27;
    DATA_STORE[H2C_ADDR+(k*64)+43] = 8'h28;
    DATA_STORE[H2C_ADDR+(k*64)+44] = 8'h29; //-- Src_add [63:32] x0000
    DATA_STORE[H2C_ADDR+(k*64)+45] = 8'h2a;
    DATA_STORE[H2C_ADDR+(k*64)+46] = 8'h2b;
    DATA_STORE[H2C_ADDR+(k*64)+47] = 8'h2c;

    DATA_STORE[H2C_ADDR+(k*64)+48]  = 8'h2d; // 32Bits Reserved 
    DATA_STORE[H2C_ADDR+(k*64)+49]  = 8'h2e;
    DATA_STORE[H2C_ADDR+(k*64)+50]  = 8'h2f; // Packet length for ST loopback desin
    DATA_STORE[H2C_ADDR+(k*64)+51]  = 8'h30;
    DATA_STORE[H2C_ADDR+(k*64)+52]  = 8'h31;  // Packet length 16 bits [7:0]
    DATA_STORE[H2C_ADDR+(k*64)+53]  = 8'h32; // Packet length 16 bits [15:8]
    DATA_STORE[H2C_ADDR+(k*64)+54]  = 8'h33; // Reserved // bot EOP and SOP is set for Dsc bypass to work.
    DATA_STORE[H2C_ADDR+(k*64)+55]  = 8'h34;
    DATA_STORE[H2C_ADDR+(k*64)+56]  = 8'h35; //-- Src_add [31:0] x0200
    DATA_STORE[H2C_ADDR+(k*64)+57]  = 8'h36;
    DATA_STORE[H2C_ADDR+(k*64)+58] = 8'h37;
    DATA_STORE[H2C_ADDR+(k*64)+59] = 8'h38;
    DATA_STORE[H2C_ADDR+(k*64)+60] = 8'h39; //-- Src_add [63:32] x0000
    DATA_STORE[H2C_ADDR+(k*64)+61] = 8'h3a;
    DATA_STORE[H2C_ADDR+(k*64)+62] = 8'h3b;
    DATA_STORE[H2C_ADDR+(k*64)+63] = 8'h3c;

    data_tmp[15:0] = data_tmp[15:0]+1;
    end // for (k=0;k<8;k=k+1)
      
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
   integer dsc_num;
   begin
    $display(" **** TASK QDMA ST DATA C2H. DSC at address 0x%h ****\n", C2H_ADDR);
    $display(" **** Initilize Descriptor data #1 ***\n"); 
    dsc_num = 16;

    for (k=0;k<dsc_num-1;k=k+1) begin
    	DATA_STORE[C2H_ADDR+(k*8)+0] = 8'h00; //-- Src_add [31:0] xA00
    	DATA_STORE[C2H_ADDR+(k*8)+1] = 8'h0A;
    	DATA_STORE[C2H_ADDR+(k*8)+2] = 8'h00;
    	DATA_STORE[C2H_ADDR+(k*8)+3] = 8'h00;
    	DATA_STORE[C2H_ADDR+(k*8)+4] = 8'h00; //-- Src add [63:32]
    	DATA_STORE[C2H_ADDR+(k*8)+5] = 8'h00;
    	DATA_STORE[C2H_ADDR+(k*8)+6] = 8'h00;
    	DATA_STORE[C2H_ADDR+(k*8)+7] = 8'h00;
    end

    //Intilize Status write back location to 0's  
    DATA_STORE[C2H_ADDR+ ((dsc_num-1)*8) +0] = 8'h00;
    DATA_STORE[C2H_ADDR+ ((dsc_num-1)*8) +1] = 8'h00;
    DATA_STORE[C2H_ADDR+ ((dsc_num-1)*8) +2] = 8'h00;
    DATA_STORE[C2H_ADDR+ ((dsc_num-1)*8) +3] = 8'h00;
      
    for (k = 0; k < 8; k = k + 1)  begin
        $display(" **** Descriptor data *** data = %h, addr= %d\n", DATA_STORE[C2H_ADDR+k], C2H_ADDR+k);
        #(Tcq);
    end
    for (k = 0; k < (DMA_BYTE_CNT*2); k = k + 1)  begin
       #(Tcq) DATA_STORE[2560+k] = 8'h00;  //0xA00
    end
   end
endtask

/************************************************************
Task : TSK_INIT_QDMA_ST_CMPT_C2H
Inputs : None
Outputs : None
Description : Initialize Descriptor and Data 
*************************************************************/

task TSK_INIT_QDMA_ST_CMPT_C2H;
   integer k;

   begin
    $display(" **** TASK QDMA ST CMPT DATA for C2H at address 0x%h ***\n", CMPT_ADDR);

    // initilize CMPT data for two entries 64bits each  
    for (k = 0; k < 32; k = k + 1)  begin
       #(Tcq) DATA_STORE[CMPT_ADDR+k] = 8'h00;
    end
   end
endtask
   

/************************************************************
Task : COMPARE_DATA_H2C 
Inputs : Number of Payload Bytes 
Outputs : None
Description : Compare Data received at out of DMA with data sent from RP - user TB
*************************************************************/

task COMPARE_DATA_H2C;
   input [31:0]payload_bytes ;
   input integer address;

  reg [511:0] READ_DATA [(DMA_BYTE_CNT/8):0];
  reg [511:0] DATA_STORE_512 [(DMA_BYTE_CNT/8):0];
  reg         data_valid; // Asssert as long as no wlast
  reg [7:0]   burst_size; // Burst size in bytes
  reg [11:0]  bof; // Byte Offset

  integer matched_data_counter;
  integer i, j, k;
  integer data_beat_count; // Theoretical data beat count if full burst
  integer dbc;             // Actual data beat count based on received data including narrow burst

  begin
   
    matched_data_counter = 0;	

        //Calculate number of beats for payload to DMA
    
    case (board.EP_DATA_WIDTH)    
    64:		data_beat_count = ((payload_bytes % 32'h8) == 0) ? (payload_bytes/32'h8) : ((payload_bytes/32'h8)+32'h1); 
    128:	data_beat_count = ((payload_bytes % 32'h10) == 0) ? (payload_bytes/32'h10) : ((payload_bytes/32'h10)+32'h1); 
    256:	data_beat_count = ((payload_bytes % 32'h20) == 0) ? (payload_bytes/32'h20) : ((payload_bytes/32'h20)+32'h1); 
    512:	data_beat_count = ((payload_bytes % 32'h40) == 0) ? (payload_bytes/32'h40) : ((payload_bytes/32'h40)+32'h1); 
    endcase

    $display ("Enters into compare read data task at %gns\n", $realtime);
    $display ("payload bytes=%h, data_beat_count =%d\n", payload_bytes, data_beat_count);
    
//    for (i=0; i<data_beat_count; i=i+1)   begin
    for (i=0; i<(DMA_BYTE_CNT/8); i=i+1)   begin // Zero out all entries for Narrow Burst data checking support
    
      DATA_STORE_512[i] = 512'b0;
      READ_DATA[i]      = 512'b0;
    
    end
    
    //Sampling data payload 
    data_valid = 1'b1;
    dbc        = 0;
    
    fork
    
    begin // Fork 1
      @ (posedge board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_awvalid) ;
      burst_size = 2**(board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_awsize);
    end // Fork 1
    
    begin // Fork 2
    @ (posedge board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wvalid) ;		  			//valid data comes at wvalid
//      for (i=0; i<data_beat_count; i=i+1)   begin
      while (data_valid) begin // Get all beats till wlast for Narrow Burst data checking support
        @ (negedge board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_aclk);					//samples data at negedge of user_clk

            if ( board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wvalid &
                 board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wready ) begin			    //check for wvalid & wready is high before sampling data
              case (board.EP_DATA_WIDTH)
                64: READ_DATA[dbc] = {((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[7] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[63:56] : 8'h00),
                                    ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[6] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[55:48] : 8'h00),
                                    ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[5] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[47:40] : 8'h00),
                                    ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[4] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[39:32] : 8'h00),
                                    ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[3] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[31:24] : 8'h00),
                                    ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[2] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[23:16] : 8'h00),
                                    ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[1] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[15:8] : 8'h00),
                                    ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[0] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[7:0] : 8'h00)};
                128: READ_DATA[dbc] = {((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[15] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[127:120] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[14] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[119:112] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[13] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[111:104] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[12] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[103:96] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[11] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[95:88] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[10] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[87:80] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[9] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[79:72] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[8] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[71:64] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[7] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[63:56] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[6] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[55:48] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[5] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[47:40] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[4] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[39:32] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[3] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[31:24] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[2] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[23:16] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[1] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[15:8] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[0] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[7:0] : 8'h00)};
                256: READ_DATA[dbc] = {((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[31] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[255:248] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[30] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[247:240] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[29] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[239:232] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[28] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[231:224] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[27] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[223:216] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[26] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[215:208] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[25] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[207:200] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[24] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[199:192] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[23] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[191:184] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[22] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[183:176] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[21] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[175:168] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[20] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[167:160] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[19] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[159:152] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[18] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[151:144] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[17] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[143:136] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[16] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[135:128] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[15] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[127:120] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[14] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[119:112] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[13] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[111:104] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[12] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[103:96] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[11] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[95:88] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[10] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[87:80] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[9] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[79:72] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[8] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[71:64] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[7] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[63:56] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[6] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[55:48] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[5] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[47:40] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[4] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[39:32] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[3] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[31:24] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[2] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[23:16] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[1] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[15:8] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[0] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[7:0] : 8'h00)};
                512: READ_DATA[dbc] = {((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[63] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[511:504] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[62] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[503:496] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[61] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[495:488] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[60] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[487:480] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[59] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[479:472] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[58] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[471:464] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[57] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[463:456] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[56] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[455:448] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[55] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[447:440] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[54] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[439:432] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[53] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[431:424] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[52] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[423:416] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[51] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[415:408] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[50] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[407:400] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[49] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[399:392] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[48] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[391:384] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[47] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[383:376] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[46] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[375:368] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[45] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[367:360] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[44] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[359:352] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[43] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[351:344] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[42] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[343:336] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[41] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[335:328] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[40] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[327:320] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[39] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[319:312] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[38] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[311:304] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[37] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[303:296] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[36] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[295:288] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[35] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[287:280] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[34] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[279:272] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[33] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[271:264] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[32] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[263:256] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[31] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[255:248] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[30] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[247:240] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[29] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[239:232] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[28] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[231:224] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[27] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[223:216] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[26] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[215:208] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[25] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[207:200] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[24] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[199:192] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[23] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[191:184] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[22] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[183:176] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[21] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[175:168] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[20] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[167:160] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[19] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[159:152] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[18] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[151:144] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[17] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[143:136] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[16] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[135:128] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[15] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[127:120] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[14] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[119:112] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[13] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[111:104] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[12] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[103:96] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[11] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[95:88] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[10] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[87:80] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[9] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[79:72] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[8] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[71:64] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[7] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[63:56] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[6] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[55:48] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[5] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[47:40] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[4] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[39:32] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[3] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[31:24] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[2] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[23:16] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[1] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[15:8] : 8'h00),
                                        ((board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wstrb[0] == 1'b1) ? board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wdata[7:0] : 8'h00)};
               endcase
               $display ("--- H2C data at QDMA = %h ---\n", READ_DATA[dbc]);

               dbc        = dbc + 1;
               data_valid = (board.EP.design_1_wrapper_i.design_1_i.axi_bram_ctrl_0.s_axi_wlast == 1'b1) ? 1'b0 : 1'b1;

            end
            /* Remove when Narrow Burst data checking support is added - loop using wlast
            else begin
            i=i-1;
            end
            */
      end

      end // Fork 2

      join

      //Sampling stored data from User TB in reg
      k   = 0;
      bof = 0;
      case (board.EP_DATA_WIDTH)

            64: 
                begin
                  for (i = 0; i < dbc; i = i + 1)   begin
                    for (j=(burst_size-1); j>=0; j=j-1) begin
                      DATA_STORE_512[i] = {DATA_STORE_512[i], DATA_STORE[address+k+j]};
                    end
                    DATA_STORE_512[i] = DATA_STORE_512[i] << (bof*8);
                    k   = k + burst_size;
                    bof = ((bof + (burst_size * 8)) >= 64) ? 0 : (bof + burst_size);

                    $display ("--- Data Stored in TB for H2C Transfer = %h ---\n", DATA_STORE_512[i]);
                  end
                end

           128: 
                begin
                for (i = 0; i < dbc; i = i + 1)   begin
                    for (j=(burst_size-1); j>=0; j=j-1) begin
                      DATA_STORE_512[i] = {DATA_STORE_512[i], DATA_STORE[address+k+j]};
                    end
                    DATA_STORE_512[i] = DATA_STORE_512[i] << (bof*8);
                    k   = k + burst_size;
                    bof = ((bof + (burst_size * 8)) >= 128) ? 0 : (bof + burst_size);

                    $display ("-- Data Stored in TB for H2C Transfer = %h--\n", DATA_STORE_512[i]);
                  end
                end
                
           256: 
                begin
                  for (i = 0; i < dbc; i = i + 1)   begin
                    for (j=(burst_size-1); j>=0; j=j-1) begin 
                      DATA_STORE_512[i] = {DATA_STORE_512[i], DATA_STORE[address+k+j]};
                    end
                    DATA_STORE_512[i] = DATA_STORE_512[i] << (bof*8);
                    k   = k + burst_size;
                    bof = ((bof + (burst_size * 8)) >= 256) ? 0 : (bof + burst_size);
                  
                    $display ("-- Data Stored in TB for H2C Transfer = %h--\n", DATA_STORE_512[i]);
                  end
                end
            512: 
                begin
                  for (i = 0; i < dbc; i = i + 1)   begin
                    for (j=(burst_size-1); j>=0; j=j-1) begin 
                      DATA_STORE_512[i] = {DATA_STORE_512[i], DATA_STORE[address+k+j]};
                    end
                    DATA_STORE_512[i] = DATA_STORE_512[i] << (bof*8);
                    k   = k + burst_size;
                    bof = ((bof + (burst_size * 8)) >= 512) ? 0 : (bof + burst_size);
             
                    $display ("-- Data Stored in TB for H2C Transfer = %h--\n", DATA_STORE_512[i]);
                  end
                end

      endcase

      //Compare sampled data from QDMA with stored TB data
      for (i=0; i<dbc; i=i+1)   begin
      
        if (READ_DATA[i] == DATA_STORE_512[i]) begin
          matched_data_counter = matched_data_counter + 1;
        end else
          matched_data_counter = matched_data_counter;
      end
      
      if (matched_data_counter == dbc) begin
        $display ("*** H2C Transfer Data MATCHES ***\n");
        $display("[%t] : QDMA H2C Test Completed Successfully",$realtime);
      end else begin
        $display ("ERROR: [%t] : TEST FAILED ---***ERROR*** H2C Transfer Data MISMATCH ---\n",$realtime);
        board.RP.tx_usrapp.test_state =1;
      end  
    
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
  integer i, j, k,t;
  integer data_beat_count;
  integer cq_data_beat_count;
  integer cq_valid_wait_cnt;
  begin

    matched_data_counter = 0; t = 0;

//    for (k = 0; k < DMA_BYTE_CNT; k = k + 1)  begin
//        $display(" **** H2C data *** data = %h, addr= %d\n", DATA_STORE[address+k], address+k);
//    end
    //Calculate number of beats for payload sent

    data_beat_count = ((payload_bytes % 32'h40) == 0) ? (payload_bytes/32'h40) : ((payload_bytes/32'h40)+32'h1);
    cq_data_beat_count = ((((payload_bytes-32'h30) % 32'h40) == 0) ? ((payload_bytes-32'h30)/32'h40) : (((payload_bytes-32'h30)/32'h40)+32'h1)) + 32'h1;
    $display ("payload_bytes = %h, data_beat_count = %h  cq_data_beat_count = %h\n", payload_bytes, data_beat_count, cq_data_beat_count);
    
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

                              // $display ("-------------------------starting i = %d--------------------------------------------------------------\n", i);
                 @ (negedge user_clk);						//Samples data at negedge of user_clk

                    if ( board.RP.m_axis_cq_tready && board.RP.m_axis_cq_tvalid) begin	//Samples data when tready is high
                      //$display ("--m_axis_cq_tvalid = %d, m_axis_cq_tready = %d, i = %d--\n", board.RP.m_axis_cq_tvalid, board.RP.m_axis_cq_tready, i);

                      if ( i == 0 || t == 1) begin					//First Data Beat

                             if (i != 0 && t == 1)
                              begin	
                                  i=i-1;
                              end
                        t=0;
                        READ_DATA_C2H_512[i][511:0]   = board.RP.m_axis_cq_tdata [511:128];

                      end else begin						//Second and Subsequent Data Beat

                         //$display ("m_axis_cq_tkeep = %h\n", board.RP.m_axis_cq_tkeep);

                        case (board.RP.m_axis_cq_tkeep)
                             16'h0001: begin READ_DATA_C2H_512[i-1][511:384] = {96'b0,board.RP.m_axis_cq_tdata [31:0]};  /* $display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[2*i-1], i , t);*/ end
                             16'h0003: begin READ_DATA_C2H_512[i-1][511:384] = {64'b0,board.RP.m_axis_cq_tdata [63:0]};  /* $display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[2*i-1], i , t);*/ end
                             16'h0007: begin READ_DATA_C2H_512[i-1][511:384] = {32'b0,board.RP.m_axis_cq_tdata [95:0]};  /* $display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[2*i-1], i , t);*/ end
                             16'h000F: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0];         /* $display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[2*i-1], i , t);*/ end
                             16'h001F: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {480'b0,board.RP.m_axis_cq_tdata [159:128]}; /*$display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[i-1], i , t);*/ end
                             16'h003F: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {448'b0,board.RP.m_axis_cq_tdata [191:128]}; /*$display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[i-1], i , t);*/ end
                             16'h007F: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {416'b0,board.RP.m_axis_cq_tdata [223:128]}; /*$display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[i-1], i , t);*/ end
                             16'h00FF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {384'b0,board.RP.m_axis_cq_tdata [255:128]}; /*$display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[i-1], i , t);*/ end
                             16'h01FF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {352'b0,board.RP.m_axis_cq_tdata [287:128]}; /*$display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[i-1], i , t);*/ end
                             16'h03FF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {320'b0,board.RP.m_axis_cq_tdata [319:128]}; /*$display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[i-1], i , t);*/ end
                             16'h07FF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {288'b0,board.RP.m_axis_cq_tdata [351:128]}; /*$display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[i-1], i , t);*/ end
                             16'h0FFF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {256'b0,board.RP.m_axis_cq_tdata [383:128]}; /*$display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[i-1], i , t);*/ end
                             16'h1FFF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {224'b0,board.RP.m_axis_cq_tdata [415:128]}; /*$display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[i-1], i , t);*/ end
                             16'h3FFF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {192'b0,board.RP.m_axis_cq_tdata [447:128]}; /*$display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[i-1], i , t);*/ end
                             16'h7FFF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {160'b0,board.RP.m_axis_cq_tdata [479:128]}; /*$display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[i-1], i , t);*/ end
                             16'hFFFF: begin READ_DATA_C2H_512[i-1][511:384] = board.RP.m_axis_cq_tdata [127:0]; READ_DATA_C2H_512[i] = {128'b0,board.RP.m_axis_cq_tdata [511:128]}; /*$display ("-- CHECKING C2H data at RP = %h-- i = %d t = %d \n", READ_DATA_C2H_512[i-1], i , t);*/ end
                             default: begin READ_DATA_C2H_512[i] = 512'b0;/* $display ("-- C2H data at RP = %h--\n", READ_DATA_C2H_512[2*i]);*/ end
                        endcase

                            //  $display ("------------------------------------------------------------------------------------------");
                            //  $display ("-- CHECKING m_axis_cq_tdata = %h   and i = %d--\n", board.RP.m_axis_cq_tdata [511:0] , i);
                            //  $display ("-- CHECKING READ_DATA_C2H_512 = %h   and i = %d--\n", READ_DATA_C2H_512[i-1][511:384] , i);
                            //  $display ("-- CHECKING m_axis_cq_tkeep = %h   and i = %d--\n", board.RP.m_axis_cq_tkeep[15:0] , i);

                             if (board.RP.m_axis_cq_tlast)
                              begin	
                                  t=1;
                              end
                      end
                    end
                    else begin
                    i=i-1;
                        //      $display ("-------------------------ending i = %d--------------------------------------------------------------\n", i);
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
        //    $display ("-- DATA_STORE_512[i] = %h,-- DATA_STORE[address+k+j] = %h,  address = %h, i = %d, j = %d, k = %d\n", DATA_STORE_512[i],DATA_STORE[address+k+j], address+k+j,i,j,k);
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
            $display ("ERROR: [%t] : TEST FAILED ---***ERROR*** C2H Transfer Data MISMATCH ---\n",$realtime);
            board.RP.tx_usrapp.test_state =1;
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
      else begin
        $display ("ERROR: [%t] : TEST FAILED ---***ERROR*** Write Back Status NO matches expected value : %h, got %h \n",$realtime, exp_cidx, cidx);
        board.RP.tx_usrapp.test_state =1;
      end  
      
   end

endtask

/************************************************************
Task : COMPARE_TRANS_C2H_ST_STATUS
Inputs : Number of Payload Bytes
Outputs : None
Description : Compare Data received and stored at RP - user TB with the data sent for H2C transfer from RP - user TB
*************************************************************/

task COMPARE_TRANS_C2H_ST_STATUS;

   input integer indx ;
   input [16:0] exp_pidx;
   input 	pkt_type;  // 1 regular packet 0 immediate data
   input integer 	cmpt_size;
  
   integer 	i, j, k;
   integer 	status_found;
   integer 	loop_count;
   reg [15:0] 	pidx;
   reg [21:0] 	len;
   reg [31:0]   wrb_status_addr ;
   reg [3:0] 	cmpt_ctl;
   
   begin
     len = board.RP.m_axis_cq_tdata [147:132];
      cmpt_ctl =4'h0;
      
      // get transfere length
     while(board.RP.m_axis_cq_tdata[31:0] != (CMPT_ADDR+(indx*cmpt_size))) begin
	 wait (board.RP.m_axis_cq_tvalid == 1'b1) ;          //1st tvalid after data	 
	 @ (negedge user_clk);	 						//Samples data at negedge of user_clk
	 if ( board.RP.m_axis_cq_tready ) begin
	    if (board.RP.m_axis_cq_tdata[31:0] == (CMPT_ADDR+(indx*cmpt_size))) begin  // Address match
               len = board.RP.m_axis_cq_tdata[147:132];
	       cmpt_ctl = board.RP.m_axis_cq_tdata[131:128];
	    end
	 end
     end
      
      if (pkt_type ) begin  // regular packet
	 if (len[15:0] == DMA_BYTE_CNT[15:0] ) 
           $display ("*** C2H transfer Length matches with expected value : %h\n", len);
	 else begin
            $display ("ERROR: [%t] : TEST FAILED ---***ERROR*** C2H transfer length does not matche expected value : %h, got %h \n",$realtime, DMA_BYTE_CNT[15:0], len);
            board.RP.tx_usrapp.test_state =1;
	 end
	 if (cmpt_ctl[3] )  // desc_used bit
           $display ("*** C2H transfer is Regular packet and desc_used is set \n");
	 else begin
            $display ("ERROR: [%t] : TEST FAILED ---***ERROR*** C2H descriptor is not used in Regulart packet tranfer : %h\n",$realtime,cmpt_ctl[3:0]);
            board.RP.tx_usrapp.test_state =1;
	 end
      end
      else begin // immediate data
	if (~cmpt_ctl[3] ) 
          $display ("*** C2H transfer is Immediate data and desc_used is NOT set \n");
	else begin
           $display ("ERROR: [%t] : TEST FAILED ---***ERROR*** C2H descriptor is used for Immediate data : %h\n",$realtime,cmpt_ctl[3:0]);
           board.RP.tx_usrapp.test_state =1;
	end
      end
      if (~cmpt_ctl[2] ) // Err bit 
        $display ("*** C2H transfer erro bit is not set \n");
      else begin
         $display ("ERROR: [%t] : TEST FAILED ---***ERROR*** Completion Error bit is set \n",$realtime);
         board.RP.tx_usrapp.test_state =1;
      end
      
      // get writeback Pidx
      //
      wrb_status_addr = CMPT_ADDR +(15*cmpt_size);
//      wrb_status_addr = 32'h00001078;
      status_found = 0;
      loop_count = 0;
      pidx = 0;
      while  ((exp_pidx != pidx) && (loop_count < 10))begin
	 loop_count = loop_count +1;
	 wait (board.RP.m_axis_cq_tvalid == 1'b1) ;             //1st tvalid - Descriptor Read Request

	 if ( board.RP.m_axis_cq_tready ) begin
	    if (board.RP.m_axis_cq_tdata[31:0] == wrb_status_addr[31:0]) begin  // Address match
               pidx = pidx + board.RP.m_axis_cq_tdata[143:128];
	       $display("pidx = 0x%x, exp pidx = 0x%x\n", pidx, exp_pidx);
	    end
	 end
	 @ (negedge user_clk);						//Samples data at negedge of user_clk
      end
      
      if (exp_pidx == pidx ) begin
        $display ("*** Write Back Status matches expected value : %h and color bit is %h\n", pidx, cmpt_ctl[1]);
        $display ("*** Test Passed ***\n");
        end
      else begin
        $display ("ERROR: [%t] : TEST FAILED ---***ERROR*** Write Back Status NO matches expected value : %h, got %h \n",$realtime, exp_pidx, pidx);
        board.RP.tx_usrapp.test_state =1;
      end  
      
   end

endtask
/************************************************************
Task : TSK_FIND_USR_BAR
Description : Find User BAR 
*************************************************************/

task TSK_FIND_USR_BAR;
   begin
      
      board.RP.tx_usrapp.TSK_REG_READ(xdma_bar, 16'h10C);
      case (P_READ_DATA[5:0])
	6'b000001 : user_bar =0;
	6'b000010 : user_bar =1;
	6'b000100 : user_bar =2;
	6'b001000 : user_bar =3;
	6'b010000 : user_bar =4;
	6'b100000 : user_bar =5;
	default : user_bar = 0;
      endcase // case (P_READ_DATA[5:0])
      $display (" ***** User BAR = %d *****\n", user_bar);
   end
endtask // TSK_FIND_USR_BAR

/************************************************************
Task : TSK_PROG_HOST_PROFILE
Inputs : None
Outputs : None
Description : Program QDMA Host Profile to route
              MM_CHN=0 to CPM AXI-MM Master 0
              MM_CHN=1 to CPM AXI-MM Master 1
*************************************************************/
task TSK_PROG_HOST_PROFILE;
  begin
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h2C8, 32'h0, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h308, 32'h0, 4'hF);
    
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h824, 32'hFFFFFFFF, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h828, 32'hFFFFFFFF, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h82C, 32'hFFFFFFFF, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h830, 32'hFFFFFFFF, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h834, 32'hFFFFFFFF, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h838, 32'hFFFFFFFF, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h83C, 32'hFFFFFFFF, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h840, 32'hFFFFFFFF, 4'hF);
    
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, 32'h0, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, 32'h0, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, 32'h0, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, 32'h00000008, 4'hF); // ARcache='b10 (modifiable).
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, 32'h0, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, 32'h00800000, 4'hF); // AWcache='b10 (modifiable).
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, 32'h0, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, 32'h0, 4'hF);
    
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, 32'h34, 4'hF);
    
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h2C8, 32'h0, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h308, 32'h0, 4'hF);
    
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h804, 32'h0, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h808, 32'h0, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h80C, 32'h40000000, 4'hF); // ARsteering='b1 (MM Port 0).
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h810, 32'h00000008, 4'hF); // ARcache='b10 (modifiable).
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h814, 32'h0, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h818, 32'h00840000, 4'hF); // AWsteering='b1 (MM Port 1). AWcache='b10 (modifiable).
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h81C, 32'h0, 4'hF);
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h820, 32'h0, 4'hF);
    
    board.RP.tx_usrapp.TSK_REG_WRITE(xdma_bar, 16'h844, 32'hB4, 4'hF);
  end
endtask // TSK_PROG_HOST_PROFILE

endmodule // pci_exp_usrapp_tx
