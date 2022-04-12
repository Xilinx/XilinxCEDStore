//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : The Xilinx PCI Express DMA 
// File       : usp_pci_exp_usrapp_tx_sriov.sv
// Version    : 5.0
//-----------------------------------------------------------------------------
//--------------------------------------------------------------------------------
`include "board_common.vh"

module pci_exp_usrapp_tx_sriov #(
  parameter        ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG = 0,
  parameter        AXISTEN_IF_RQ_PARITY_CHECK   = 0,
  parameter        AXISTEN_IF_CC_PARITY_CHECK   = 0,
  parameter        AXISTEN_IF_RQ_ALIGNMENT_MODE      = "FALSE",
  parameter        AXISTEN_IF_CC_ALIGNMENT_MODE      = "FALSE",
  parameter        AXISTEN_IF_CQ_ALIGNMENT_MODE      = "FALSE",
  parameter        AXISTEN_IF_RC_ALIGNMENT_MODE      = "FALSE",
  parameter        DEV_CAP_MAX_PAYLOAD_SUPPORTED     = 1,
  parameter        EP_DEV_ID                         =7000,
  parameter        C_DATA_WIDTH                      = 512,
  parameter        KEEP_WIDTH                        = C_DATA_WIDTH / 32,
  parameter        STRB_WIDTH                        = C_DATA_WIDTH / 8,
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
localparam VF_DMA_BAR_INDEX = 7; //VF DMA BAR is 7 (VF BAR0)
localparam PF_DMA_BAR_INDEX = 0; //PF DMA BAR is 0 (PF BAR0)
localparam PF_USR_BAR_INDEX = 1;
localparam VF_USR_BAR_INDEX = 8; //VF DMA BAR is 7 (VF BAR0)
localparam NUM_PFS = 3'h1 ; // starting form 0
localparam NUM_BAR_PER_FN = 13;
localparam QUEUE_PER_VF = 8;
localparam QUEUE_PER_PF = 32;

typedef enum logic [11:0] {
  PCIE_CFG_PF_BAR_0_A = 12'h10,
  PCIE_CFG_PF_BAR_1_A = 12'h14,  
  PCIE_CFG_PF_BAR_2_A = 12'h18,  
  PCIE_CFG_PF_BAR_3_A = 12'h1C,  
  PCIE_CFG_PF_BAR_4_A = 12'h20,  
  PCIE_CFG_PF_BAR_5_A = 12'h24,  
  PCIE_CFG_EROM_BAR_A = 12'h30,  
  PCIE_CFG_VF_BAR_0_A = 12'h164,  
  PCIE_CFG_VF_BAR_1_A = 12'h168,  
  PCIE_CFG_VF_BAR_2_A = 12'h16C,  
  PCIE_CFG_VF_BAR_3_A = 12'h170,  
  PCIE_CFG_VF_BAR_4_A = 12'h174,  
  PCIE_CFG_VF_BAR_5_A = 12'h178
} pcie_bar_addr_e;

localparam PCIE_CFG_CMD_A        = 12'h4;
localparam PCIE_DEV_CAP_A        = 12'h074;
localparam DEV_CTRL_REG_A        = 12'h078;
localparam LINK_CTRL_REG_A       = 12'h080;

localparam PCIE_CFG_SRIOV_CAP_A  = 12'h140;
localparam PCIE_CFG_SRIOV_CTRL_A = 12'h148;
localparam PCIE_CFG_TOTAL_VFS_A  = 12'h14C;
localparam PCIE_CFG_NUM_VFS_A    = 12'h150;
localparam PCIE_CFG_1ST_VF_OFST_A= 12'h154;
localparam MDMA_VF_EXT_START_A   = 32'h1000;
localparam MDMA_PF_EXT_START_A   = 32'h2400;

reg        [(C_DATA_WIDTH - 1):0]            pcie_tlp_data;
reg        [(REM_WIDTH - 1):0]               pcie_tlp_rem;


reg  [15:0] TOTAL_VFS [NUM_PFS-1:0];
reg  [15:0] NUM_VFS [NUM_PFS-1:0];
reg  [15:0] FIRST_VF_OFFSET [NUM_PFS-1:0];
reg [7:0] pfn;
reg [7:0] vfn;
/* Local Variables */
integer                         i, j, k;
reg     [7:0]                   DATA_STORE   [8192:0]; // For Downstream Direction Data Storage
reg     [7:0]                   DATA_STORE_2 [(2**(RP_BAR_SIZE+1))-1:0]; // For Upstream Direction Data Storage
reg     [31:0]                  ADDRESS_32_L;
reg     [31:0]                  ADDRESS_32_H;
reg     [63:0]                  ADDRESS_64;
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
reg     [32:0]                  BAR_INIT_P_BAR[NUM_PFS-1:0][NUM_BAR_PER_FN-1:0]; // 6 corresponds to Expansion ROM                                                              // note that bit 32 is for overflow checking
reg     [31:0]                  BAR_INIT_P_BAR_RANGE[NUM_PFS-1:0][NUM_BAR_PER_FN-1:0];          // 6 corresponds to Expansion ROM
reg     [31:0]                  BAR_INIT_P_BAR_SIZE[NUM_PFS-1:0][NUM_BAR_PER_FN-1:0];
reg     [1:0]                   BAR_INIT_P_BAR_ENABLED[NUM_PFS-1:0][NUM_BAR_PER_FN-1:0];         // 6 corresponds to Expansion ROM
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


reg     [3:0]                   ii;
integer                         jj;
reg     [3:0]                   pfIndex = 0;
reg     [3:0]                   pfTestIteration = 0;
reg                             dmaTestDone;

integer                         PIO_MAX_NUM_BLOCK_RAMS;        // holds the max number of block RAMS
reg     [31:0]                  PIO_MAX_MEMORY;

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
reg     [10:0]                  axi_mm_q;
reg     [10:0]                  axi_st_q;
reg     [127:0]                 wr_dat;
reg     [31:0]                  wr_add;
reg     [15:0] 			data_tmp = 0;
   
assign s_axis_rq_tuser = {(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0),s_axis_rq_tuser_wo_parity[72:0]};

assign user_lnk_up_n = ~user_lnk_up;

integer desc_count = 0;
integer loop_timeout = 0;
reg [31:0] h2c_status = 32'h0;
reg [31:0] c2h_status = 32'h0;
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
  for (int i=0; i< NUM_PFS;i++) begin
    for (int j = 0; j < NUM_BAR_PER_FN; j++) begin
      BAR_INIT_P_BAR[i][j]         = 33'h00000_0000;
      BAR_INIT_P_BAR_RANGE[i][j]   = 32'h0000_0000;
      BAR_INIT_P_BAR_SIZE[i][j]    = 32'h0000_0000;
      BAR_INIT_P_BAR_ENABLED[i][j] = 2'b00;
    end //end jj
  end //end i

  BAR_INIT_P_MEM64_HI_START =  32'h0000_0001;  // hi 32 bit start of 64bit memory
  BAR_INIT_P_MEM64_LO_START =  32'h0000_0000;  // low 32 bit start of 64bit memory
  BAR_INIT_P_MEM32_START    =  33'h00000_0000; // start of 32bit memory
  BAR_INIT_P_IO_START       =  33'h00000_0000; // start of 32bit io

  PIO_MAX_MEMORY            = 8192;            // PIO has max of 8Kbytes of memory
  PIO_MAX_NUM_BLOCK_RAMS    = 4;               // PIO has four block RAMS to test
  PIO_MAX_MEMORY            = 2048;            // PIO has 4 memory regions with 2 Kbytes of memory per region, ie 8 Kbytes
  PIO_MAX_NUM_BLOCK_RAMS    = 4;               // PIO has four block RAMS to test

  cpld_to                   = 0;               // By default time out has not occured
  cpld_to_finish            = 1;               // By default end simulation on time out

  verbose                   = 0;               // turned off by default


end
//-----------------------------------------------------------------------\\
initial begin
  dmaTestDone         = 0;
  pfIndex             = 0;
  pfTestIteration     = 0;

  expect_status       = 0;
  expect_finish_check = 0;
  testError           = 1'b0;
  // Tx transaction interface signal initialization.
  pcie_tlp_data       = 0;
  pcie_tlp_rem        = 0;

  // Payload data initialization.
  TSK_USR_DATA_SETUP_SEQ;

  TSK_SIMULATION_TIMEOUT(10050);
  TSK_SYSTEM_INITIALIZATION;
  TSK_SYSTEM_CONFIGURATION_CHECK;
  TSK_BAR_INIT;

  if ($value$plusargs("TESTNAME=%s", testname))
      $display("Running test {%0s}......", testname);
  else begin	
//      testname = "qdma_flr_test_0";
//      testname = "qdma_c2h_st";
//      testname = "qdma_h2c_st";
        testname = "qdma_sriov_all";
      $display("***********       Running QDMA test {%0s}    *******************", testname);
  end

  //Test starts here
  if (testname == "dummy_test") begin
      $display("[%t] %m: Invalid TESTNAME: %0s", $realtime, testname);
      $finish(2);
  end
  `include "sample_tests_sriov.vh"
  else begin
    $display("[%t] %m: Error: Unrecognized TESTNAME: %0s", $realtime, testname);
    $finish(2);
  end

end

/************************************************************
    Logic to Compute the Parity of the CC and the RQ Channel
*************************************************************/generate
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
                                        ^ s_axis_cc_tdata[(8*a)+ 6] ^ s_axis_cc_tdata[(8*a)+ 7]);        end
    end
endgenerate
/************************************************************
Task : TSK_SYSTEM_INITIALIZATION
Inputs : None
Outputs : None
Description : Waits for Transaction Interface Reset and Link-Up
*************************************************************/
task TSK_SYSTEM_INITIALIZATION;
  logic [7:0] pf_i;
  logic [7:0] vf_i;
  logic [7:0] fnc_i;
begin
  //--------------------------------------------------------------------------
  // Event # 1: Wait for Transaction reset to be de-asserted...
  //--------------------------------------------------------------------------
  wait (reset == 0);
  $display("[%t] : Transaction Reset Is De-asserted...", $realtime);
  //--------------------------------------------------------------------------
  // Event # 2: Wait for Transaction link to be asserted...
  //--------------------------------------------------------------------------
  wait (board.RP.pcie_4_0_rport.user_lnk_up == 1);
  TSK_TX_CLK_EAT(100);
  $display("[%t] : Transaction Link Is Up...", $realtime);

  for(pf_i=0; pf_i<NUM_PFS; pf_i++) begin

    $display("[%t] : Initialize PF%0d", $realtime, pf_i);

    EP_BUS_DEV_FNS = {8'b0000_0001, pf_i};     // ARI Enabled, Bus 1 Function 8'Bfn_num

    // Set BME of PF
    $display("[%t] :   Set BME", $realtime);
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, PCIE_CFG_CMD_A, 32'h07, 4'h1);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Set Device Control Register of PF
    $display("[%t] :   Set Device Control Register", $realtime);
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, DEV_CTRL_REG_A[11:0], 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;

    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, DEV_CTRL_REG_A[11:0], P_READ_DATA | (DEV_CAP_MAX_PAYLOAD_SUPPORTED * 32), 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Check if SR-IOV exist
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, PCIE_CFG_SRIOV_CAP_A, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    if (P_READ_DATA[15:0] != 16'h0010) begin
      $display("[%t] :   PF %0d does not support SRIOV (cap_id = %h)", $realtime, pf_i, P_READ_DATA[15:0]);
      continue; 
    end

    // Determine Number of VFs of PF#fn_num                
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, PCIE_CFG_TOTAL_VFS_A, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;

    TOTAL_VFS[pf_i] = P_READ_DATA[31:16];

    $display("[%t] :   Enable %0d VFs for PF%0d", $realtime, TOTAL_VFS[pf_i], pf_i);

    // Program Number VF of PF#fn_num
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, PCIE_CFG_NUM_VFS_A, {16'h0000, TOTAL_VFS[pf_i]}, 4'h3);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Set PF PCIe SRIOV Control register
    //   [4]: 1 // ARI Capable
    //   [3]: 1 // VF MSE
    //   [0]: 1 // VF enable
    $display("[%t] :   Set SRIOV Control Register (ARI Cap, VF MSE, VF enable)", $realtime);
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, PCIE_CFG_SRIOV_CTRL_A, 32'h00000019, 4'h1);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(1000);

    // Get NUM_VFs enabled per PF
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, PCIE_CFG_NUM_VFS_A, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    NUM_VFS[pf_i] = P_READ_DATA[15:0];

    // Check First VF Offset
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, PCIE_CFG_1ST_VF_OFST_A, 4'h3);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    FIRST_VF_OFFSET[pf_i] = P_READ_DATA[15:0]; 
    $display("[%t] :   PF%0d FIRST_VF_OFFSET = %0d", $realtime, pf_i, FIRST_VF_OFFSET[pf_i]);

    for (vf_i=0; vf_i<NUM_VFS[pf_i]; vf_i=vf_i+1) begin
      fnc_i = pf_i + FIRST_VF_OFFSET[pf_i] + vf_i;
      EP_BUS_DEV_FNS = {8'b0000_0001, fnc_i};     
      // Set BME of VF
      TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, PCIE_CFG_CMD_A, 32'h04, 4'h1);
      DEFAULT_TAG = DEFAULT_TAG + 1;
      TSK_TX_CLK_EAT(100);       
    end

  end

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
  logic [7:0] pf_i;
  logic [7:0] vf_i;
  logic [7:0] fnc_i;
  begin

    for(pf_i=0; pf_i<NUM_PFS; pf_i++) begin
      EP_BUS_DEV_FNS = {8'b0000_0001, pf_i};     // ARI Enabled, Bus 1 Function 8'Bfn_num
      error_check = 0;

      $display("[%t] : Perform configuration check for PF%0d", $realtime, pf_i);

      // Check Link Speed/Width
      TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, LINK_CTRL_REG_A, 4'hF); // 12'hD0
      TSK_WAIT_FOR_READ_DATA;
      if  (P_READ_DATA[19:16] == MAX_LINK_SPEED) begin
        if (P_READ_DATA[19:16] == 1)
          $display("[%t] :   Check Max Link Speed = 2.5GT/s - PASSED", $realtime);
        else if(P_READ_DATA[19:16] == 2)
          $display("[%t] :   Check Max Link Speed = 5.0GT/s - PASSED", $realtime);
        else if(P_READ_DATA[19:16] == 3)
          $display("[%t] :   Check Max Link Speed = 8.0GT/s - PASSED", $realtime);
        else if(P_READ_DATA[19:16] == 4)
          $display("[%t] :   Check Max Link Speed = 16.0GT/s - PASSED", $realtime);
      end else begin // if (P_READ_DATA[19:16] == MAX_LINK_SPEED)
        $display("[%t] :   Check Max Link Speed - FAILED", $realtime);
        $display("[%t] :   Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime, MAX_LINK_SPEED, P_READ_DATA[19:16]);
      end

      if  (P_READ_DATA[24:20] == LINK_CAP_MAX_LINK_WIDTH)
        $display("[%t] :   Check Negotiated Link Width = 5'h%x - PASSED", $realtime, LINK_CAP_MAX_LINK_WIDTH);
      else
        $display("[%t] :   Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime, LINK_CAP_MAX_LINK_WIDTH, P_READ_DATA[24:20]);

      // Check Device/Vendor ID
      TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h0, 4'hF);
      TSK_WAIT_FOR_READ_DATA;

      if  (P_READ_DATA != {4'h9, pf_i[3:0], 8'h3F, 16'h10ee} ) begin
        $display("[%t] :   Check Device/Vendor ID - FAILED", $realtime);
        $display("[%t] :   Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime, {4'h9, pf_i[3:0], 8'h3F, 16'h10ee}, P_READ_DATA);
        error_check = 1;
      end else begin
        $display("[%t] :   Check Device/Vendor ID - PASSED", $realtime);
      end

      // Check MPS
      TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, PCIE_DEV_CAP_A, 4'hF); //12'hC4
      TSK_WAIT_FOR_READ_DATA;

      if (P_READ_DATA[2:0] != DEV_CAP_MAX_PAYLOAD_SUPPORTED) begin
        $display("[%t] :   Check CMPS ID - FAILED", $realtime);
        $display("[%t] :   Data Error Mismatch, Parameter Data %x != Read data %x", $realtime, DEV_CAP_MAX_PAYLOAD_SUPPORTED, P_READ_DATA[2:0]);
        error_check = 1;
      end else begin
        $display("[%t] :   Check CMPS ID - PASSED", $realtime);
      end

      // Check number of VF enabled
      if (TOTAL_VFS[pf_i] == NUM_VFS[pf_i])
        $display("[%t] :   Enabling all VFS of PF%0d - PASSED", $realtime, pf_i);
      else begin
        $display("[%t] :   ERROR - PF%0d only enable %0d out %0d VFS", $realtime, pf_i, NUM_VFS[pf_i], TOTAL_VFS[pf_i]);
        error_check = 1;
      end

      // Check SRIOV CTRL REG
      TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, PCIE_CFG_SRIOV_CTRL_A, 4'hF);
      DEFAULT_TAG = DEFAULT_TAG + 1;
      TSK_WAIT_FOR_READ_DATA;
         
      if ((P_READ_DATA[15:0] != 16'h19 && (pf_i == 0)) || 
          (P_READ_DATA[15:0] != 16'h09 && (pf_i != 0))) 
      begin
        $display("[%t] :   ERROR - PF%0d SRIOV CRTL REG is wrong (value = 0x%h)\n", $realtime, pf_i, P_READ_DATA[15:0]);
        error_check = 1;
      end
      else
        $display("[%t] :   SRIOV CRTL REG value check - PASSED", $realtime);
      
      for (vf_i=0; vf_i < NUM_VFS[pf_i]; vf_i=vf_i+1) begin
        fnc_i = pf_i + FIRST_VF_OFFSET[pf_i] + vf_i;
        EP_BUS_DEV_FNS = {8'b0000_0001, fnc_i};     // ARI Enabled, Bus 1 Function 8'Bfn_num

        // Check Bus Master Enable of VFs
        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, PCIE_CFG_CMD_A, 4'h1);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
 
        if (P_READ_DATA[2] != 1'b1) 
        begin
          $display("[%t] :   ERROR - PF%0d VF%0d Bus Master Enable is 0", $realtime, pf_i, vf_i);
          error_check = 1;
        end
        else
          $display("[%t] :   Bus Master Enable is set for PF%0d VF%0d - PASSED", $realtime, pf_i, vf_i);
        
      end
    end 
 
    if (error_check == 0) begin
      $display("[%t] : SYSTEM CHECK PASSED", $realtime);
    end else begin
      $display("[%t] : SYSTEM CHECK FAILED", $realtime);
      $finish;
    end
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

    if (user_lnk_up_n) begin
      $display("[%t] :  interface is MIA", $realtime);
      $finish;
    end

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
    pcie_tlp_rem             <= #(Tcq) 3'b000;

  end
endtask // TSK_TX_TYPE0_CONFIGURATION_READ


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
    $display("[%t] : Mem32 Read Req @address 0x%0x", $realtime,addr_);
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
            $display("[%t] : Mem32 Write Req @address 0x%0x with data 0x%0x", $realtime, addr_, {DATA_STORE[3], DATA_STORE[2], DATA_STORE[1], DATA_STORE[0]});
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            // Start of First Data Beat
            data_axis_i      =  {
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

            $display("[%t] : CC Data Completion Task Begin", $realtime);
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
  Task : TSK_TX_BAR_READ
  Inputs : Tag, Length, Address, Last Byte En, First Byte En
  Outputs : Transaction Tx Interface Signaling
  Description : Generates a Memory Read 32,64 or IO Read TLP
                requesting 1 dword
*************************************************************/

task TSK_TX_BAR_READ;
      
  input    integer  func;
  input    [2:0]    bar_index;
  input    [31:0]   byte_offset;
  input    [7:0]    tag_;
  input    [2:0]    tc_;

  begin
    case(BAR_INIT_P_BAR_ENABLED[func][bar_index])
      2'b01 : // IO SPACE
      begin
        if (verbose) $display("[%t] : IOREAD, address = %x", $realtime, BAR_INIT_P_BAR[func][bar_index][31:0]+(byte_offset));
        TSK_TX_IO_READ(tag_, BAR_INIT_P_BAR[func][bar_index][31:0]+(byte_offset), 4'hF);
      end

      2'b10 : // MEM 32 SPACE
      begin
        if (verbose) $display("[%t] : MEMREAD32, address = %x", $realtime, BAR_INIT_P_BAR[func][bar_index][31:0]+(byte_offset));
        TSK_TX_MEMORY_READ_32(tag_, tc_, 10'd1, BAR_INIT_P_BAR[func][bar_index][31:0]+(byte_offset), 4'h0, 4'hF);
      end

      2'b11 : // MEM 64 SPACE
      begin
        if (verbose) $display("[%t] : MEMREAD64, address = %x", $realtime, BAR_INIT_P_BAR[func][bar_index][31:0]+(byte_offset));
          TSK_TX_MEMORY_READ_64(tag_, tc_, 10'd1, {BAR_INIT_P_BAR[func][ii+1][31:0], BAR_INIT_P_BAR[func][bar_index][31:0]+(byte_offset)}, 4'h0, 4'hF);
      end

      default : $display("Error case in task TSK_TX_BAR_READ");
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
  input     integer func;
  input    [2:0]    bar_index;
  input    [31:0]   byte_offset;
  input    [7:0]    tag_;
  input    [2:0]    tc_;
  input    [31:0]   data_;

  begin
    case(BAR_INIT_P_BAR_ENABLED[func][bar_index])
      2'b01 : // IO SPACE
      begin
        if (verbose) $display("[%t] : IOWRITE, address = %x, Write Data %x", $realtime, BAR_INIT_P_BAR[func][bar_index][31:0]+(byte_offset), data_);
        TSK_TX_IO_WRITE(tag_, BAR_INIT_P_BAR[func][bar_index][31:0]+(byte_offset), 4'hF, data_);
      end

      2'b10 : // MEM 32 SPACE
      begin
        DATA_STORE[0] = data_[7:0];
        DATA_STORE[1] = data_[15:8];
        DATA_STORE[2] = data_[23:16];
        DATA_STORE[3] = data_[31:24];
        if (verbose) $display("[%t] : MEMWRITE32, address = %x, Write Data %x", $realtime, BAR_INIT_P_BAR[func][bar_index][31:0]+(byte_offset), data_);
        TSK_TX_MEMORY_WRITE_32(tag_, tc_, 10'd1, BAR_INIT_P_BAR[func][bar_index][31:0]+(byte_offset), 4'h0, 4'hF, 1'b0);
      end
      2'b11 : // MEM 64 SPACE
      begin
        DATA_STORE[0] = data_[7:0];
        DATA_STORE[1] = data_[15:8];
        DATA_STORE[2] = data_[23:16];
        DATA_STORE[3] = data_[31:24];
        if (verbose) $display("[%t] : MEMWRITE64, address = %x, Write Data %x", $realtime, BAR_INIT_P_BAR[func][bar_index][31:0]+(byte_offset), data_);
        TSK_TX_MEMORY_WRITE_64(tag_, tc_, 10'd1, {BAR_INIT_P_BAR[func][bar_index+1][31:0], BAR_INIT_P_BAR[func][bar_index][31:0]+(byte_offset)}, 4'h0, 4'hF, 1'b0);
      end
      default :  $display("Error case in task TSK_TX_BAR_WRITE");
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
    for (i_ = 0; i_ <= 4095; i_ = i_ + 1) 
      DATA_STORE[i_] = i_;
            
    for (i_ = 0; i_ <= (2**(RP_BAR_SIZE+1))-1; i_ = i_ + 1) 
      DATA_STORE_2[i_] = i_;            
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
    for (i_ = 0; i_ < clock_count; i_ = i_ + 1) 
      @(posedge user_clk);
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
  begin
    for (int pf_i=0; pf_i<NUM_PFS; pf_i++) begin
      for (int bar_i=0; bar_i < NUM_BAR_PER_FN; bar_i++) begin
        if (bar_i < 6) 
          $display("[%t] :   PF %0d,   PF BAR %0d : START = %x SIZE = %x RANGE = %x TYPE = %s", $realtime, 
                       pf_i,bar_i, BAR_INIT_P_BAR[pf_i][bar_i][31:0], BAR_INIT_P_BAR_SIZE[pf_i][bar_i], BAR_INIT_P_BAR_RANGE[pf_i][bar_i], BAR_INIT_MESSAGE[BAR_INIT_P_BAR_ENABLED[pf_i][bar_i]]);
        else if (bar_i == 6) 
          $display("[%t] :   PF %0d,   EROM BAR : START = %x SIZE = %x RANGE = %x TYPE = %s", $realtime,
                       pf_i, BAR_INIT_P_BAR[pf_i][bar_i][31:0], BAR_INIT_P_BAR_SIZE[pf_i][bar_i], BAR_INIT_P_BAR_RANGE[pf_i][bar_i], BAR_INIT_MESSAGE[BAR_INIT_P_BAR_ENABLED[pf_i][bar_i]]);
        else
          $display("[%t] :   PF %0d,   VF BAR %0d : START = %x SIZE = %x RANGE = %x TYPE = %s", $realtime,
                       pf_i, bar_i-7, BAR_INIT_P_BAR[pf_i][bar_i][31:0], BAR_INIT_P_BAR_SIZE[pf_i][bar_i], BAR_INIT_P_BAR_RANGE[pf_i][bar_i], BAR_INIT_MESSAGE[BAR_INIT_P_BAR_ENABLED[pf_i][bar_i]]);
      end //for bar_i
    end // for pf_i 
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
  begin

    for (int pf_i = 0; pf_i < NUM_PFS; pf_i++) begin
      $display("[%t] : Map BAR range to BAR size for PF%0d",$realtime, pf_i);
      EP_BUS_DEV_FNS = {8'b0000_0001, pf_i};     // ARI Enabled, Bus 1 Function 8'Bfn_num

      // handle bars 0-6 (including erom)
      for (int bar_i = 0; bar_i < NUM_BAR_PER_FN; bar_i++) begin
        // If bar size is not zero
        if ((BAR_INIT_P_BAR_RANGE[pf_i][bar_i] & 32'hFFFF_F000) == 32'h0000_0000) 
          continue;
  
        // if not erom and io bit set, check if this is a IO bar
        if (BAR_INIT_P_BAR_RANGE[pf_i][bar_i] & 32'h0000_0001)
          TSK_BUILD_IO_BAR(pf_i, bar_i);
        else if ((BAR_INIT_P_BAR_RANGE[pf_i][bar_i] & 32'h0000_0007) == 32'h0000_0004)
          TSK_BUILD_MEM64_BAR(pf_i, bar_i);
        else if ((BAR_INIT_P_BAR_RANGE[pf_i][bar_i] & 32'h0000_0007) == 32'h0000_0000)
          TSK_BUILD_MEM32_BAR(pf_i, bar_i);
        else begin
          $display ("ERROR : Undefined BAR type (BAR_RANGE[%h][%h] = %x)", pf_i, bar_i, BAR_INIT_P_BAR_RANGE[pf_i][bar_i]);
          $finish;
        end
      end // end of looping j

      if ( (OUT_OF_IO) | (OUT_OF_LO_MEM) | (OUT_OF_HI_MEM)) begin
        TSK_DISPLAY_PCIE_MAP;
        $display("ERROR: Ending simulation: Memory Manager is out of memory/IO to allocate to PCI Express device");
        $finish;
      end

    end // Function number for loop pf_i
  end // task
endtask // TSK_BUILD_PCIE_MAP

/************************************************************
  Task : TSK_BUILD_IO_BAR
  Inputs :
  Outputs :
  Description : 
*************************************************************/
task TSK_BUILD_IO_BAR;

  input [31:0] pf_i;
  input [31:0] bar_i;

  begin 
    if (bar_i>=6) begin // VF or EROM Bar
      $display("\tERROR: VF BAR %x can't be IO or EROM BAR", (bar_i-7));
      error_check = 1;
    end else begin
      // bar is io mapped
      BAR_INIT_P_BAR_ENABLED[pf_i][bar_i] = 2'h1; 
  
      // We need to calculate where the next BAR should start based on the BAR's range
      BAR_INIT_TEMP = BAR_INIT_P_IO_START & {1'b1,(BAR_INIT_P_BAR_RANGE[pf_i][bar_i] & 32'hffff_fff0)};
      BAR_INIT_P_BAR_SIZE[pf_i][bar_i] = FNC_CONVERT_RANGE_TO_SIZE_32(pf_i,bar_i);
      if (BAR_INIT_TEMP < BAR_INIT_P_IO_START) begin
        // Current BAR_INIT_P_IO_START is NOT correct start for new base
        BAR_INIT_P_BAR[pf_i][bar_i] = BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_32(pf_i,bar_i);
        BAR_INIT_P_IO_START = BAR_INIT_P_BAR[pf_i][bar_i] + FNC_CONVERT_RANGE_TO_SIZE_32(pf_i,bar_i);
      end
      else begin
        // Initial BAR case and Current BAR_INIT_P_IO_START is correct start for new base
        BAR_INIT_P_BAR[pf_i][bar_i] = BAR_INIT_P_IO_START;
        BAR_INIT_P_IO_START = BAR_INIT_P_IO_START + FNC_CONVERT_RANGE_TO_SIZE_32(pf_i,bar_i);
      end
      OUT_OF_IO = BAR_INIT_P_BAR[pf_i][bar_i][32];         

      if (OUT_OF_IO) $display("\tOut of PCI EXPRESS IO SPACE due to BAR %x", bar_i);
    end // if (bar_i >= 6)
  end
endtask

/************************************************************
  Task : TSK_BUILD_MEM64_BAR
  Inputs :
  Outputs :
  Description : 
*************************************************************/
task TSK_BUILD_MEM64_BAR;

  input [31:0] pf_i;
  input [31:0] bar_i;

  begin  
    // bar is mem64 mapped
    if ((bar_i == 5) || (bar_i == 3) || (bar_i == 1)) return;
    
    BAR_INIT_P_BAR_ENABLED[pf_i][bar_i] = 2'h3; // bar is mem64 mapped

    if ( (BAR_INIT_P_BAR_RANGE[pf_i][bar_i] & 32'hFFFF_FFF0) == 32'h0000_0000) begin
      // Mem64 space has range larger than 2 Gigabytes
      // calculate where the next BAR should start based on the BAR's range
      BAR_INIT_TEMP = BAR_INIT_P_MEM64_HI_START & BAR_INIT_P_BAR_RANGE[pf_i][bar_i+1];
      BAR_INIT_P_BAR_SIZE[pf_i][bar_i] = FNC_CONVERT_RANGE_TO_SIZE_HI32(pf_i,bar_i);
      if (BAR_INIT_TEMP < BAR_INIT_P_MEM64_HI_START) begin
        // Current MEM32_START is NOT correct start for new base
        BAR_INIT_P_BAR[pf_i][bar_i+1]    = BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_HI32(pf_i,bar_i+1);
        BAR_INIT_P_BAR[pf_i][bar_i]      = 32'h0000_0000;
        BAR_INIT_P_MEM64_HI_START        = BAR_INIT_P_BAR[pf_i][bar_i+1] + FNC_CONVERT_RANGE_TO_SIZE_HI32(pf_i,bar_i+1);
        BAR_INIT_P_MEM64_LO_START        = 32'h0000_0000;
      end
      else begin
        // Initial BAR case and Current MEM32_START is correct start for new base
        BAR_INIT_P_BAR[pf_i][bar_i]      = 32'h0000_0000;
        BAR_INIT_P_BAR[pf_i][bar_i+1]    = BAR_INIT_P_MEM64_HI_START;
        BAR_INIT_P_MEM64_HI_START        = BAR_INIT_P_MEM64_HI_START + FNC_CONVERT_RANGE_TO_SIZE_HI32(pf_i,bar_i+1);
      end
    end
    else begin
      // Mem64 space has range less than/equal 2 Gigabytes
      // calculate where the next BAR should start based on the BAR's range
      BAR_INIT_TEMP = BAR_INIT_P_MEM64_LO_START & (BAR_INIT_P_BAR_RANGE[pf_i][bar_i] & 32'hffff_fff0);
      BAR_INIT_P_BAR_SIZE[pf_i][bar_i] = FNC_CONVERT_RANGE_TO_SIZE_32(pf_i,bar_i);
      if (BAR_INIT_TEMP < BAR_INIT_P_MEM64_LO_START) begin
        // Current MEM32_START is NOT correct start for new base
        BAR_INIT_P_BAR[pf_i][bar_i]   = BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_32(pf_i,bar_i);
        BAR_INIT_P_BAR[pf_i][bar_i+1] = BAR_INIT_P_MEM64_HI_START;
        BAR_INIT_P_MEM64_LO_START     = BAR_INIT_P_BAR[pf_i][bar_i] + FNC_CONVERT_RANGE_TO_SIZE_32(pf_i,bar_i);
      end
      else begin
        // Initial BAR case and Current MEM32_START is correct start for new base
        BAR_INIT_P_BAR[pf_i][bar_i]   = BAR_INIT_P_MEM64_LO_START;
        BAR_INIT_P_BAR[pf_i][bar_i+1] = BAR_INIT_P_MEM64_HI_START;
        BAR_INIT_P_MEM64_LO_START     = BAR_INIT_P_MEM64_LO_START + FNC_CONVERT_RANGE_TO_SIZE_32(pf_i,bar_i);
      end
    end

  end
endtask

/************************************************************
  Task : TSK_BUILD_MEM32_BAR
  Inputs :
  Outputs :
  Description : 
*************************************************************/
task TSK_BUILD_MEM32_BAR;

  input [31:0] pf_i;
  input [31:0] bar_i;

  begin
    BAR_INIT_P_BAR_ENABLED[pf_i][bar_i] = 2'h2; // PF bar is mem32 mapped

    // We need to calculate where the next BAR should start based on the BAR's range
    BAR_INIT_TEMP = BAR_INIT_P_MEM32_START & {1'b1,(BAR_INIT_P_BAR_RANGE[pf_i][bar_i] & 32'hffff_fff0)};
    BAR_INIT_P_BAR_SIZE[pf_i][bar_i] = FNC_CONVERT_RANGE_TO_SIZE_32(pf_i,bar_i);
    // Initial BAR and Current MEM32_START is incorrect for new BAR, use whichever is smaller
    if (BAR_INIT_TEMP < BAR_INIT_P_MEM32_START) begin 
      if (bar_i < 7) begin // PF BAR
        BAR_INIT_P_BAR[pf_i][bar_i] = BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_32(pf_i,bar_i);
        BAR_INIT_P_MEM32_START      = BAR_INIT_P_BAR[pf_i][bar_i] + FNC_CONVERT_RANGE_TO_SIZE_32(pf_i,bar_i);                    
      end 
      else begin // VF BAR
        // Multiply by NUM_VFS[pf_i] to offset the collection of BARs on each VF
        BAR_INIT_P_BAR[pf_i][bar_i] = BAR_INIT_TEMP + (NUM_VFS[pf_i] * FNC_CONVERT_RANGE_TO_SIZE_32(pf_i,bar_i));
        BAR_INIT_P_MEM32_START      = BAR_INIT_P_BAR[pf_i][bar_i] + (NUM_VFS[pf_i] * FNC_CONVERT_RANGE_TO_SIZE_32(pf_i,bar_i));    
      end
    end
    // Initial BAR case and Current MEM32_START is correct start for new base
    else begin
      if (bar_i < 7) begin
        BAR_INIT_P_BAR[pf_i][bar_i] = BAR_INIT_P_MEM32_START;
        BAR_INIT_P_MEM32_START      = BAR_INIT_P_MEM32_START + FNC_CONVERT_RANGE_TO_SIZE_32(pf_i,bar_i);                     
      end
      else begin
        // Multiply by NUM_VFS[pf_i] to offset the collection of BARs on each VF
        BAR_INIT_P_BAR[pf_i][bar_i] = BAR_INIT_P_MEM32_START;
        BAR_INIT_P_MEM32_START      = BAR_INIT_P_MEM32_START + (NUM_VFS[pf_i] * FNC_CONVERT_RANGE_TO_SIZE_32(pf_i,bar_i));
      end
    end
                
    // make sure to set enable bit if we are mapping the erom space
    if (bar_i == 6) BAR_INIT_P_BAR[pf_i][bar_i] = BAR_INIT_P_BAR[pf_i][bar_i] | 33'h1;
    OUT_OF_LO_MEM = BAR_INIT_P_BAR[pf_i][bar_i][32];
  
    if (OUT_OF_LO_MEM) $display("\tOut of PCI EXPRESS MEMORY 32 SPACE due to BAR %x", bar_i);

  end
endtask

/************************************************************
  Task : TSK_BAR_SCAN
  Inputs : None
  Outputs : None
  Description : Scans PCI core's configuration registers.
*************************************************************/

task TSK_BAR_SCAN;
  pcie_bar_addr_e pcie_bar_addr_t;
  begin
    //--------------------------------------------------------------------------
    // Write PCI_MASK to bar's space via PCIe fabric interface to find range
    //--------------------------------------------------------------------------

    P_ADDRESS_MASK      = 32'hffff_ffff;
    DEFAULT_TAG         = 0;
    DEFAULT_TC          = 0;
 
    for(int pf_i=0; pf_i<NUM_PFS; pf_i++) begin
      $display("[%t] : Perform BAR range scan for PF%0d", $realtime, pf_i);
      EP_BUS_DEV_FNS = {8'b0000_0001, pf_i};     // ARI Enabled, Bus 1 Function 8'Bfn_num
    
      pcie_bar_addr_t = pcie_bar_addr_t.first; 
      for (int bar_i=0; bar_i < NUM_BAR_PER_FN; bar_i = bar_i + 1) begin

        // Determine Range for bar_i
        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, pcie_bar_addr_t, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);
  
        // Read bar_i Range
        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, pcie_bar_addr_t, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
       
        BAR_INIT_P_BAR_RANGE[pf_i][bar_i] = P_READ_DATA;

        pcie_bar_addr_t = pcie_bar_addr_t.next;
       
      end // for bar_i
    end //for pf_i
  end
endtask // TSK_BAR_SCAN


/************************************************************
  Task : TSK_BAR_PROGRAM
  Inputs : None
  Outputs : None
  Description : Program's PCI core's configuration registers.
*************************************************************/

task TSK_BAR_PROGRAM;
  pcie_bar_addr_e pcie_bar_addr_t;
  begin
    DEFAULT_TAG     = 0;
    //--------------------------------------------------------------------------
    // Write core configuration space via PCIe fabric interface
    //--------------------------------------------------------------------------

    for(int pf_i=0; pf_i<NUM_PFS; pf_i++) begin

      $display("[%t] : Set BAR for PF%0d", $realtime, pf_i);
      EP_BUS_DEV_FNS = {8'b0000_0001, pf_i};     // ARI Enabled, Bus 1 Function 8'Bfn_num

      pcie_bar_addr_t = pcie_bar_addr_t.first; 
      for (int bar_i=0; bar_i<NUM_BAR_PER_FN; bar_i++) begin
        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, pcie_bar_addr_t, BAR_INIT_P_BAR[pf_i][bar_i][31:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);
        pcie_bar_addr_t = pcie_bar_addr_t.next;
      end

    end //for pf_i
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

  TSK_BAR_PROGRAM;
 
  TSK_DISPLAY_PCIE_MAP;

  end
endtask // TSK_BAR_INIT

/************************************************************
  Function : FNC_CONVERT_RANGE_TO_SIZE_32
  Inputs : BAR index for 32 bit BAR
  Outputs : 32 bit BAR size
  Description : Called from tx app. Note that the smallest range
                supported by this function is 16 bytes.
*************************************************************/

function [31:0] FNC_CONVERT_RANGE_TO_SIZE_32;
  input integer func;
  input [31:0] bar_index;
  reg   [32:0] return_value;
  begin
    case (BAR_INIT_P_BAR_RANGE[func][bar_index] & 32'hFFFF_FFF0) // AND off control bits
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
  input integer func;
  input [31:0] bar_index;
  reg   [32:0] return_value;
  begin
    case (BAR_INIT_P_BAR_RANGE[func][bar_index])
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
      default :       return_value = 33'h00000_0000;
    endcase
    FNC_CONVERT_RANGE_TO_SIZE_HI32 = return_value;
  end
endfunction // FNC_CONVERT_RANGE_TO_SIZE_HI32

/************************************************************
Task : TSK_QDMA_READ
Inputs : function number, BAR address, read address
Outputs : None
Description : Read XDMA configuration register
*************************************************************/
task TSK_QDMA_READ;

  input integer func;
  input integer bar_id;
  input [31:0] read_addr;
  logic [31:0] addr_offset ;

  begin
    if (func >= 4) begin
      addr_offset = vfn * BAR_INIT_P_BAR_SIZE[pfn][bar_id];
    end
    else begin
      addr_offset = 'h0;
    end

    P_READ_DATA = 32'hffff_ffff;
    fork
      if(BAR_INIT_P_BAR_ENABLED[pfn][bar_id] == 2'b10) 
        TSK_TX_MEMORY_READ_32(DEFAULT_TAG, DEFAULT_TC, 11'd1, BAR_INIT_P_BAR[pfn][bar_id][31:0]+read_addr[20:0]+addr_offset, 4'h0, 4'hF);
      else if(BAR_INIT_P_BAR_ENABLED[pfn][bar_id] == 2'b11)                   
        TSK_TX_MEMORY_READ_64(DEFAULT_TAG, DEFAULT_TC, 11'd1,{BAR_INIT_P_BAR[pfn][bar_id][31:0], BAR_INIT_P_BAR[pfn][bar_id]+read_addr[20:0]+addr_offset}, 4'h0, 4'hF);
      TSK_WAIT_FOR_READ_DATA;
    join
    TSK_TX_CLK_EAT(10);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    $display ("[%t] :   DMA register read %0h @ address %0h",$realtime , P_READ_DATA, read_addr);
  end
endtask

/************************************************************
Task : TSK_QDMA_WRITE
Inputs : input BAR1 address, data, byte_en
Outputs : None
Description : Write XDMA configuration register
*************************************************************/

task TSK_QDMA_WRITE;

  input integer func;
  input integer bar_id;
  input [31:0] addr;
  input [31:0] data;
  input [3:0] byte_en;

  logic [31:0] addr_offset ;
  begin 
    DATA_STORE[0] = data[7:0];
    DATA_STORE[1] = data[15:8];
    DATA_STORE[2] = data[23:16];
    DATA_STORE[3] = data[31:24];

    if (func >= 4) begin
      addr_offset  = vfn * BAR_INIT_P_BAR_SIZE[pfn][bar_id];
    end
    else begin
      addr_offset = 'h0;
    end

    if(BAR_INIT_P_BAR_ENABLED[pfn][bar_id] == 2'b10) begin
      TSK_TX_MEMORY_WRITE_32(DEFAULT_TAG, DEFAULT_TC, 11'd1, BAR_INIT_P_BAR[pfn][bar_id][31:0]+addr[20:0] + addr_offset, 4'h0, byte_en, 1'b0);
    end else if(BAR_INIT_P_BAR_ENABLED[pfn][bar_id] == 2'b11) begin                  
      TSK_TX_MEMORY_WRITE_64(DEFAULT_TAG, DEFAULT_TC, 11'd1,{BAR_INIT_P_BAR[pfn][bar_id+1][31:0],
      BAR_INIT_P_BAR[pfn][bar_id][31:0]+addr[20:0]} + addr_offset, 4'h0, byte_en, 1'b0);
    end
    TSK_TX_CLK_EAT(100);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    $display("[%t] :   Done register write!!" ,$realtime);  

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


    $display(" **** Initialize Descriptor data ***\n");
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

    $display(" **** Initialize Descriptor data ***\n");
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
    $display("[%t] : TASK QDMA MM H2C DSC at address 0x100", $realtime);
    $display("[%t] : Initialize Descriptor data", $realtime);
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

    $display(" **** Initialize Descriptor data ***\n");
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
    $display("[%t] : Initialize H2C ST DSC @ 0x0100 (256)", $realtime);
    DATA_STORE[256+0]  = 8'h00; // 32Bits Reserved 
    DATA_STORE[256+1]  = 8'h00;
    DATA_STORE[256+2]  = 8'h00;
    DATA_STORE[256+3]  = 8'h00;
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

    //Intialize Status write back location to 0's  
    $display("[%t] : Initialize H2C ST status writeback @ 0x01F0 (496)", $realtime);
    DATA_STORE[496+0] = 8'h00;
    DATA_STORE[496+1] = 8'h00;
    DATA_STORE[496+2] = 8'h00;
    DATA_STORE[496+3] = 8'h00;

    // Initiailize the expected data      
    $display("[%t] : Initialize data @ RP to be sent/checked @ 0x0200 (512)", $realtime);
    data_tmp = 0;
    for (k = 0; k < 256; k = k + 2)  begin
        DATA_STORE[512+k]   = data_tmp[7:0];
        DATA_STORE[512+k+1] = data_tmp[15:8];
        data_tmp[15:0] = data_tmp[15:0]+1;
    end

//    for (k = 0; k < 128; k = k + 1) 
//        $display("[%t] :   H2C data = 0x%h, addr= %0d", $realtime, DATA_STORE[512+k], 512+k);
      
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
   integer num_desc; 
   logic [63:0] dst_addr;   

   begin

    $display("[%t] : Initialize C2H ST DSC @ 0x400 (1024)", $realtime);

    DATA_STORE[1024+0] = 8'h00; //-- dst_add [31:0] x500
    DATA_STORE[1024+1] = 8'h05;
    DATA_STORE[1024+2] = 8'h00;
    DATA_STORE[1024+3] = 8'h00;
    DATA_STORE[1024+4] = 8'h00; //-- dst add [63:32]
    DATA_STORE[1024+5] = 8'h00;
    DATA_STORE[1024+6] = 8'h00;
    DATA_STORE[1024+7] = 8'h00;
    DATA_STORE[1032+0] = 8'h80; //-- Src_add [31:0] x580
    DATA_STORE[1032+1] = 8'h05;
    DATA_STORE[1032+2] = 8'h00;
    DATA_STORE[1032+3] = 8'h00;
    DATA_STORE[1032+4] = 8'h00; //-- Src add [63:32]
    DATA_STORE[1032+5] = 8'h00;
    DATA_STORE[1032+6] = 8'h00;
    DATA_STORE[1032+7] = 8'h00;

    //Intilize Status write back location to 0's  
    $display("[%t] : Initialize C2H ST status writeback buffer @ 0x478 (1144)", $realtime);
    DATA_STORE[1144+0] = 8'h00;
    DATA_STORE[1144+1] = 8'h00;
    DATA_STORE[1144+2] = 8'h00;
    DATA_STORE[1144+3] = 8'h00;
      
//    for (k = 0; k < 8; k = k + 1)  begin
//        $display("[%t] :   Descriptor data = 0x%h, addr= %0d", $realtime, DATA_STORE[1024+k], 1024+k);
//        #(Tcq);
//    end
    $display("[%t] : Initialize C2H ST completion buffer @ 0x500 (1280)", $realtime);
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
   integer num_desc; 

   begin
    $display("[%t] : TASK QDMA ST WBK DATA for C2H ST at address 0x800 (2048)", $realtime);

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

  reg [511:0] READ_DATA [(DMA_BYTE_CNT/8):0];
  reg [511:0] DATA_STORE_512 [(DMA_BYTE_CNT/8):0];

  integer matched_data_counter;
  integer i, j, k;
  integer data_beat_count;

  begin
   
    matched_data_counter = 0;	

        //Calculate number of beats for payload on XDMA
    
    case (board.EP.C_DATA_WIDTH)    
    64:		data_beat_count = ((payload_bytes % 32'h8) == 0) ? (payload_bytes/32'h8) : ((payload_bytes/32'h8)+32'h1); 
    128:	data_beat_count = ((payload_bytes % 32'h10) == 0) ? (payload_bytes/32'h10) : ((payload_bytes/32'h10)+32'h1); 
    256:	data_beat_count = ((payload_bytes % 32'h20) == 0) ? (payload_bytes/32'h20) : ((payload_bytes/32'h20)+32'h1); 
    512:	data_beat_count = ((payload_bytes % 32'h40) == 0) ? (payload_bytes/32'h40) : ((payload_bytes/32'h40)+32'h1); 
    endcase

    $display ("[%t] :   payload bytes=%0d, data_beat_count =%0d", $realtime, payload_bytes, data_beat_count);
    
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
               $display ("[%t] : Beat %0d H2C data in HW = 0x%h ", $realtime, i, READ_DATA[i]);

            end
      end



      //Sampling stored data from User TB in reg

      k = 0;

      case (board.EP.C_DATA_WIDTH)

            64: 
                begin
                  for (i = 0; i < data_beat_count; i = i + 1)   begin
                    for (j=7; j>=0; j=j-1) begin
                      DATA_STORE_512[i] = {DATA_STORE_512[i], DATA_STORE[1024+k+j]};
                    end
                    k=k+8;

                    $display ("[%t] : Beat %0d, H2C data sent = %h ", $realtime, i, DATA_STORE_512[i]);
                  end
                end

           128: 
                begin
                for (i = 0; i < data_beat_count; i = i + 1)   begin
                    for (j=15; j>=0; j=j-1) begin
                    DATA_STORE_512[i] = {DATA_STORE_512[i], DATA_STORE[1024+k+j]};
                    end

                    k=k+16;

                    $display ("[%t] : Beat %0d H2C data sent = 0x%h", $realtime, i, DATA_STORE_512[i]);
                  end
                end
                
           256: 
                begin
                  for (i = 0; i < data_beat_count; i = i + 1)   begin
                    for (j=31; j>=0; j=j-1) begin 
                      DATA_STORE_512[i] = {DATA_STORE_512[i], DATA_STORE[1024+k+j]};
                    end
                  
                    k=k+32;
                  
                    $display ("[%t] : Beat %0d H2C data sent = 0x%h", $realtime, i, DATA_STORE_512[i]);
                  end
                end
            512: 
                begin
                  for (i = 0; i < data_beat_count; i = i + 1)   begin
                    for (j=63; j>=0; j=j-1) begin 
                      DATA_STORE_512[i] = {DATA_STORE_512[i], DATA_STORE[1024+k+j]};
                    end
             
                    k=k+64;
             
                    $display ("[%t] : Beat %0d H2C data sent = 0x%h", $realtime, i, DATA_STORE_512[i]);
                  end
                end



      endcase

      //Compare sampled data from XDMA with stored TB data
      
      for (i=0; i<data_beat_count; i=i+1)   begin
      
        if (READ_DATA[i] == DATA_STORE_512[i]) begin
          matched_data_counter = matched_data_counter + 1;
        end else
          matched_data_counter = matched_data_counter;
      end
      
      if (matched_data_counter == data_beat_count)
        $display ("[%t] : H2C Transfer Data MATCHES", $realtime);
      else begin
        $display ("---***ERROR*** H2C Transfer Data MISMATCH ---\n");
        $finish;
      end 
  end
           
endtask

/************************************************************
Task : COMPARE_DATA_C2H
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

    //Calculate number of beats for payload sent
    // data_beat_count stripes off the header and only fill in the payload portion to READ_DATA_C2H_512
    data_beat_count = ((payload_bytes % 32'h40) == 0) ? (payload_bytes/32'h40) : ((payload_bytes/32'h40)+32'h1);
    cq_data_beat_count = ((((payload_bytes-32'h30) % 32'h40) == 0) ? ((payload_bytes-32'h30)/32'h40) : (((payload_bytes-32'h30)/32'h40)+32'h1)) + 32'h1;
    
    //Sampling CQ data payload on RP	
    if(testname =="dma_stream0") begin
        cq_valid_wait_cnt = 3;
    end else begin
        cq_valid_wait_cnt = 1;
    end
 
    for (i=0; i<cq_valid_wait_cnt; i=i+1)   begin
      @ (posedge board.RP.m_axis_cq_tvalid) ;              //1st tvalid - Descriptor Read Request
    end
    
    @ (posedge board.RP.m_axis_cq_tvalid) ;                //2nd tvalid - CQ on RP receives Data from XDMA
      for (i=0; i<cq_data_beat_count; i=i+1)   begin
        @ (negedge user_clk);				   //Samples data at negedge of user_clk
          if ( board.RP.m_axis_cq_tready ) begin	//Samples data when tready is high
            //$display ("--m_axis_cq_tvalid = %d, m_axis_cq_tready = %d, i = %d--\n", board.RP.m_axis_cq_tvalid, board.RP.m_axis_cq_tready, i);
            $display ("[%t] : RP receives C2H data of #%0d beat", $realtime, i);
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

        k = 0;
        for (i = 0; i < data_beat_count; i = i + 1)   begin
          //Sampling stored data from User TB in 256 bit reg
          $display ("[%t] : beat #%0d C2H data received = 0x%h",$realtime, i, READ_DATA_C2H_512[i]);

          //Compare sampled data from CQ with stored TB data
          for (j=63; j>=0; j=j-1) begin
              DATA_STORE_512[i] = {DATA_STORE_512[i], DATA_STORE[address+k+j]};
          end
          k=k+64;
          $display ("[%t] : beat $%0d data expected = 0x%h", $realtime, i, DATA_STORE_512[i]);
        end
        

        for (i=0; i<data_beat_count; i=i+1)   begin
          if (READ_DATA_C2H_512[i] == DATA_STORE_512[i])
            matched_data_counter = matched_data_counter + 1;
          else
            matched_data_counter = matched_data_counter;
        end

        if (matched_data_counter == data_beat_count) begin
            $display ("[%t] : C2H Transfer Data MATCHES", $realtime);
            $display ("[%t] : XDMA C2H Test Completed Successfully", $realtime);
        end else begin
            $display ("---***ERROR*** C2H Transfer Data MISMATCH ---\n");
            $finish;
        end
  end

endtask


/************************************************************
Task : COMPARE_TRNS_STATUS
Inputs : Number of Payload Bytes
Outputs : None
Description : Check the expected CIDX
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
	 @ (posedge board.RP.m_axis_cq_tvalid) ;             //1st tvalid - Descriptor Read Request
	
	 @ (negedge user_clk);						//Samples data at negedge of user_clk
	 
	 if ( board.RP.m_axis_cq_tready ) begin
	    
	    if (board.RP.m_axis_cq_tdata [31:0] == status_addr[31:0]) begin  // Address match
               cidx = cidx + board.RP.m_axis_cq_tdata [159:144];
	    end
	 end
      end
      
      if (exp_cidx == cidx ) 
        $display ("[%t] : Write Back Status matches expected value : %h", $realtime, cidx);
      else
        $display ("---***ERROR*** Write Back Status NO matches expected value : %h, got %h \n", exp_cidx, cidx);
      
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

    // get transfere length
    @ (posedge board.RP.m_axis_cq_tvalid) ;             //1st tvalid - Descriptor Read Request
    @ (negedge user_clk);						//Samples data at negedge of user_clk
    if ( board.RP.m_axis_cq_tready ) begin
      if (board.RP.m_axis_cq_tdata [31:0] == status_addr[31:0]) begin  // Address match
        len = board.RP.m_axis_cq_tdata [147:132];
      end
    end
     
    if (len[15:0] == DMA_BYTE_CNT[15:0] ) 
      $display ("[%t] : C2H transfer Length matches with expected value : 0x%h", $realtime, len);
    else begin
      $display ("---***ERROR*** C2H transfer length does not matche expected value : %h, got %h \n", DMA_BYTE_CNT[15:0], len);
      $finish;
    end
    // get writeback Pidx
 
    wrb_status_addr = status_addr[31:0] +(15*8);
    status_found = 0;
    loop_count = 0;
    pidx = 0;
    while  ((exp_pidx != pidx) && (loop_count < 10))begin
      loop_count = loop_count +1;
      @ (posedge board.RP.m_axis_cq_tvalid) ;             //1st tvalid - Descriptor Read Request
      @ (negedge user_clk);						//Samples data at negedge of user_clk
	 
      if ( board.RP.m_axis_cq_tready ) begin
        if (board.RP.m_axis_cq_tdata [31:0] == wrb_status_addr[31:0]) begin  // Address match
          pidx = pidx + board.RP.m_axis_cq_tdata [143:128];
        end
      end
    end
      
    if (exp_pidx == pidx ) 
      $display ("[%t] : Write Back Status matches expected value : %0d", $realtime, pidx);
    else begin
      $display ("---***ERROR*** Write Back Status NO matches expected value : %h, got %h \n", exp_pidx, pidx);
      $finish;
    end
  end

endtask

/************************************************************
Task : TSK_TEST_TO_FINISH
Inputs : busy bit to be examed
Outputs : None
Description : 
*************************************************************/

task TSK_TEST_TO_FINISH;

  input [7:0]  fnc;
  logic [31:0] addr;

  begin

    // Just Check FMAP to make sure global space registers have been cleaned up
    EP_BUS_DEV_FNS = {8'b0000_0001, pfn};     // ARI Enabled, Bus 1 Function 8'Bfn_num
    addr = 32'h400 + fnc * 4;
    TSK_QDMA_READ(pfn, PF_DMA_BAR_INDEX, addr[31:0]);
    $display ("[%t] : FMAP of func %0d is %h", $realtime, fnc, P_READ_DATA);

    EP_BUS_DEV_FNS = {8'b0000_0001, fnc};     // ARI Enabled, Bus 1 Function 8'Bfn_num
    if (fnc < NUM_PFS) 
      TSK_QDMA_READ(pfn, PF_DMA_BAR_INDEX,{32'h0,11'd64,2'b0} + MDMA_PF_EXT_START_A);
    else
      TSK_QDMA_READ(pfn,VF_DMA_BAR_INDEX,{32'h0,11'd64,2'b0} + (BAR_INIT_P_BAR_SIZE[pfn][VF_DMA_BAR_INDEX] * vfn) + MDMA_VF_EXT_START_A);

  end
endtask
  

/************************************************************
Task : TSK_SW_FLR
Inputs : function number
Outputs : None
Description : Pre-FLR issued by driver
*************************************************************/

task TSK_SW_FLR;

  input [7:0] fnc;
  logic [31:0] addr;

  begin

    $display ("[%t] : Lauch SW FLR to func %0d", $realtime, fnc);
    TSK_FIND_PF_VF_NUM(fnc);
    TSK_QDMA_H2C_MM (fnc, 11'h7);

    // Read FMAP to make sure it is programmed
    EP_BUS_DEV_FNS = {8'b0000_0001, pfn};     // ARI Enabled, Bus 1 Function 8'Bfn_num
    addr = 32'h400 + fnc * 4;
    TSK_QDMA_READ(pfn, PF_DMA_BAR_INDEX, addr[31:0]);
    $display ("[%t] : FMAP of func %0d is %h", $realtime, fnc, P_READ_DATA);

    $display ("[%t] : Pre-FLR starts", $realtime);

    EP_BUS_DEV_FNS = {8'b0000_0001, fnc};     // ARI Enabled, Bus 1 Function 8'Bfn_num
    if (fnc < NUM_PFS)   
      TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, {32'h0,11'd64,2'b0} + MDMA_PF_EXT_START_A, 32'h1, 4'hF);
    else      
      TSK_QDMA_WRITE(pfn,VF_DMA_BAR_INDEX,{32'h0,11'd64,2'b0} + (BAR_INIT_P_BAR_SIZE[pfn][VF_DMA_BAR_INDEX] * vfn) + MDMA_VF_EXT_START_A, 32'h1, 4'hF);   

  end
endtask


/************************************************************
Task : TSK_PCIE_FLR
Inputs : function number 
Outputs : None
Description : Pre-FLR issued by driver
*************************************************************/

task TSK_PCIE_FLR;

  input [7:0] fnc;

  begin

    $display ("[%t] : PCIE FLR start ...", $realtime);

    TSK_FIND_PF_VF_NUM(fnc);

    EP_BUS_DEV_FNS = {8'b0000_0001, fnc};    

    // Check FLR Capability (Offset = 0x4, Bit[28] of PCIE Cap Structure)
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, PCIE_DEV_CAP_A, 4'hF); // 12'hD0
    TSK_WAIT_FOR_READ_DATA;  
    if (P_READ_DATA[28] == 1'b0) begin
      $display("[%t] : Warning: Function %d does NOT support FLR\n", $realtime, fnc);
      $finish;
    end

    // READ to Device Control Register (Offset = 0x8, Bit[15]) should be always 0
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, DEV_CTRL_REG_A, 4'hF); // 12'hD0
    TSK_WAIT_FOR_READ_DATA;  
    if (P_READ_DATA[15] != 1'b0) begin
      $display("[%t] : Warning: Function %d Initiate FLR Bit is not 0\n", $realtime, fnc);
      $finish;
    end

    // Write 1 to Device_Control_Register[15] to initiate FLR
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, DEV_CTRL_REG_A, 32'h0000_8000, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Wait for 1000us
    $display("[%t] : Wait for 1000us ...", $realtime);
    #1000000000;

    // Verify FLR by reading BME of the targeted function
    // We don't differentiate VF or PF. Nor we don't perform any test afterward
    // This merely a simple test. NOT a full-fledged FLR functionality test
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, PCIE_CFG_CMD_A, 4'h1);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);
    if (P_READ_DATA[2] == 1'b1)
      $display("[%t] : ******************  ERROR: PCIE FLR FAILED - BME is not cleared  ******************", $realtime);
    else 
      $display("[%t] : ******************  PASS: PCIE FLR PASSED  *******************", $realtime);
  
  end
endtask

/************************************************************
Task : TSK_FIND_PF_VF_NUM
Inputs : function number 
Outputs : None
Description : Find out the associated PF# of a VF
*************************************************************/

task TSK_FIND_PF_VF_NUM;
  input [7:0] fnc;

  begin

    if (fnc < NUM_PFS) begin
      pfn = fnc;
      vfn = 'h0;
    end
    else begin
      for (int pf_i=0; pf_i<NUM_PFS; pf_i=pf_i+1) begin
        if (
            (fnc >= FIRST_VF_OFFSET[pf_i] + pf_i) && 
            (fnc < FIRST_VF_OFFSET[pf_i] + NUM_VFS[pf_i] + pf_i - 1'b1)
           ) begin
          pfn = pf_i[7:0];
          vfn = fnc - FIRST_VF_OFFSET[pf_i] - pf_i;
        end  
      end
    end

    $display("[%t] : fnc %0d Translates to pfn%0d and vfn%0d", $realtime, fnc, pfn, vfn);

  end
endtask

/************************************************************
Task : TSK_QDMA_H2C_MM
Inputs : function number 
Outputs : None
Description : Set up QDMA config space & run H2C memory mapped test
*************************************************************/

task TSK_QDMA_H2C_MM;

  input [7:0] fnc;
  input [10:0] qid;    // relative qid; use for perform pointer update

  logic [11:0] q_count;
  logic [10:0] q_base;
  logic [10:0] hw_qid; // hw qid: use for global space reg access and user logic.
  logic [15:0] pidx ;
  logic [31:0] trq_sel_queue_addr;
  integer ptr_upt_dma_bar_idx;
  integer usr_bar_idx ;
  logic [31:0] addr;
  localparam NUM_ITER = 1;

  begin
  pidx =0;
  usr_bar_idx= 1;
    TSK_FIND_PF_VF_NUM(fnc);

    if (fnc < 4) begin
      $display ("\n[%t] : ************* Launching H2C MM for PF%0d ***************\n", $realtime, pfn);
      trq_sel_queue_addr = 32'h6400;
      q_base = QUEUE_PER_PF * fnc;
      q_count = QUEUE_PER_PF;
      ptr_upt_dma_bar_idx = PF_DMA_BAR_INDEX;
      usr_bar_idx = PF_USR_BAR_INDEX;
    end
    else begin
      $display ("\n[%t] : ************** Launching H2C MM for PF%0d, VF%0d ****************\n", $realtime, pfn, vfn);
      trq_sel_queue_addr = 32'h3000;
      q_base = QUEUE_PER_PF * NUM_PFS + (fnc-4) * QUEUE_PER_VF;
      q_count = QUEUE_PER_VF;
      ptr_upt_dma_bar_idx = VF_DMA_BAR_INDEX;
      usr_bar_idx = VF_USR_BAR_INDEX;
      if (qid > 11'h8) begin
        $display ("ERROR: VF QID Shoud not exceed 8. Please change the test input QID");
        $finish;
      end
    end

    hw_qid = qid + q_base;
    EP_BUS_DEV_FNS = {8'b0000_0001, pfn};     // ARI Enabled, Bus 1 Function 8'Bfn_num

    // Load DATA in Buffer 
    //   H2C DSC start at 0x0100 (256)
    //   H2C data start at 0x0300 (768)
    TSK_INIT_QDMA_MM_DATA_H2C;

    // DMA Engine ID Read 
    TSK_QDMA_READ(pfn, PF_DMA_BAR_INDEX, 32'h00);

    // Clear HW CXTX for H2C 
    //   [17:7] QID  
    //   [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
    //   [4:1]  MDMA_CTXT_SELC_DSC_HW_H2C = 3 : 0011
    //   0      BUSY : 0 
    wr_dat[31:0] = {hw_qid, 2'h0, 4'b0011, 1'b0} | 32'h0;
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h824, wr_dat[31:0], 4'hF);

    // Global Ring Size for Queue 0  0x204  : num of dsc 16 
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h204, 32'h00000010, 4'hF);

    // Global Function MAP  
    //   [22:11] Qcout for this fnc 
    //   [10:0]  Qid_base for this Fnc
    //   Address = 0x400+ fnc*4
    addr = 32'h400 + fnc * 4;
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, addr[31:0], {q_count, q_base}|32'b0, 4'hF);

    // Ind Dire CTXT MASK
    //   0xffffffff for all 128 bits
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h814, 32'hffffffff, 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h818, 32'hffffffff, 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h81C, 32'hffffffff, 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h820, 32'hffffffff, 4'hF);

    // Set up H2C SW CTXT 
    wr_dat[127:64] =  64'h100;  //  dsc_base
    wr_dat[63:61]  =  'h0;      //  rsv
    wr_dat[60]     =  'b0;      //  err_wb_sent
    wr_dat[59:58]  =  'h0;      //  err        
    wr_dat[57]     =  'b0;      //  irq_no_last
    wr_dat[56]     =  'b0;      //  irq_pnd    
    wr_dat[55:54]  =  'b0;      //  rsv0       
    wr_dat[53]     =  'b0;      //  irq_en     
    wr_dat[52]     =  1'b1;     //  wbk_en     
    wr_dat[51]     =  'b0;      //  mm_chn     
    wr_dat[50]     =  'b0;      //  byp        
    wr_dat[49:48]  =  2'b10;    //  dsc_sz     
    wr_dat[47:44]  =  'b0;      //  rng_sz     
    wr_dat[43:36]  =  fnc;      //  fnc_id     
    wr_dat[35]     =  'b0;      //  wbi_acc_en 
    wr_dat[34]     =  1'b1;     //  wbi_chk    
    wr_dat[33]     =  'b0;      //  fcrd_en    
    wr_dat[32]     =  1'b1;     //  qen        
    wr_dat[31:17]  =  'b0;      //  rsv        
    wr_dat[16]     =  'b0;      //  irq_ack    
    wr_dat[15:0]   =  pidx;     //  pidx       

    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h804, wr_dat[31:0], 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h808, wr_dat[63:32], 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h80C, wr_dat[95:64], 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h810, wr_dat[127:96], 4'hF);

    // Program SW H2C CTXT	
    // [17:7] QID   
    // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
    // [4:1]  MDMA_CTXT_SELC_DSC_SW_H2C = 1 : 0001
    // 0      BUSY : 0 
    wr_dat[31:0] = {hw_qid[10:0],2'b01, 4'b0001, 1'b0} | 32'h0;
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h824, wr_dat[31:0], 4'hF);
    TSK_QDMA_READ(pfn, PF_DMA_BAR_INDEX, 32'h824);  //Read PIDX pointer

    // ARM H2C transfer 0x1204 MDMA_H2C_MM0_CONTROL set to run
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h1204, 32'h00000001, 4'hF);

    // Start DMA tranfer
    for (int iter=0; iter < NUM_ITER; iter=iter+1) begin
      
      $display("\n[%t] : Start H2C MM Iteration %0d for fnc %0d\n", $realtime, iter, fnc);
      pidx = pidx + 1;
      wr_add = trq_sel_queue_addr + (qid* 16) + 4; 
      EP_BUS_DEV_FNS = {8'b0000_0001, fnc};     // ARI Enabled, Bus 1 Function 8'Bfn_num

      fork
        // Write PIDX to transfer 1 descriptor
        $display("[%t] : Enabling PIDX %0d for H2C", $realtime, pidx);
        TSK_QDMA_WRITE(fnc, ptr_upt_dma_bar_idx, wr_add[31:0], pidx, 4'hF);  

        TSK_QDMA_READ(fnc, PF_DMA_BAR_INDEX, wr_add);  //Read PIDX pointer

        $display("[%t] : Comparing received H2C data", $realtime);
        COMPARE_DATA_H2C({16'h0,DMA_BYTE_CNT});    //input payload bytes

        $display("[%t] : Checking writeback CIDX", $realtime);
        COMPARE_TRANS_STATUS(32'h000002E0, pidx); 
      join   


      EP_BUS_DEV_FNS = {8'b0000_0001, pfn};     // ARI Enabled, Bus 1 Function 8'Bfn_num
      TSK_QDMA_READ(pfn, PF_DMA_BAR_INDEX, 32'h1248);
      $display ("[%t] : H2C Completed Descriptor Count = %h", $realtime, P_READ_DATA);
      $display ("[%t] : Iteration %0d --- H2C MM TEST PASSED ---\n",$realtime, iter);
    end
    $display ("[%t] : *********************** H2C MM TEST PASSED *********************** \n",$realtime);
  end
endtask


/************************************************************
Task : TSK_QDMA_C2H_MM
Inputs : function number 
Outputs : None
Description : Set up QDMA config space and run C2H memory mapped test
*************************************************************/

task TSK_QDMA_C2H_MM;

  input [7:0] fnc;
  input [10:0] qid;    // relative qid; use for perform pointer update

  logic [11:0] q_count;
  logic [10:0] q_base;
  logic [10:0] hw_qid; // hw qid: use for global space reg access and user logic.
  logic [15:0] pidx;
  logic [31:0] trq_sel_queue_addr;
  integer ptr_upt_dma_bar_idx;
  integer usr_bar_idx ;
  logic [31:0] addr;
  localparam NUM_ITER = 1;

  begin
  pidx =0;
  ptr_upt_dma_bar_idx=0;
  usr_bar_idx =1;
    TSK_FIND_PF_VF_NUM(fnc);

    if (fnc < 4) begin
      $display ("\n[%t] : ****************** Lauching C2H MM for PF%0d ***********************\n", $realtime, pfn);
      trq_sel_queue_addr = 32'h6400;
      q_base = QUEUE_PER_PF * fnc;
      q_count = QUEUE_PER_PF;
      ptr_upt_dma_bar_idx = PF_DMA_BAR_INDEX;
      usr_bar_idx = PF_USR_BAR_INDEX;
    end
    else begin
      $display ("\n[%t] : ****************** Launching C2H MM for PF%0d, VF%0d *********************\n", $realtime, pfn, vfn);
      trq_sel_queue_addr = 32'h3000;
      q_base = QUEUE_PER_PF * NUM_PFS + (fnc-4) * QUEUE_PER_VF;
      q_count = QUEUE_PER_VF;
      ptr_upt_dma_bar_idx = VF_DMA_BAR_INDEX;
      usr_bar_idx = VF_USR_BAR_INDEX;
      if (qid > 11'h8) begin
        $display ("ERROR: VF QID Shoud not exceed 8. Please change the test input QID");
        $finish;
      end
    end

    $display ("[%t] : Warning - Must run H2C MM before C2H MM", $realtime);

    hw_qid = qid + q_base;
    EP_BUS_DEV_FNS = {8'b0000_0001, pfn};     // ARI Enabled, Bus 1 Function 8'Bfn_num

    // Load DATA in Buffer 
    //   C2H DSC starts at 0x0400 (1024)
    //   C2H data starts at 0x0600 (1536)
    TSK_INIT_QDMA_MM_DATA_C2H;

    // DMA Engine ID Read 
    TSK_QDMA_READ(pfn, PF_DMA_BAR_INDEX, 32'h00);

    // Clear HW CXTX for C2H 
    //   [17:7] QID  
    //   [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
    //   [4:1]  MDMA_CTXT_SELC_DSC_HW_C2H = 2 : 0010
    //   0      BUSY : 0 
    wr_dat[31:0] = {hw_qid, 2'h0, 4'b0010, 1'b0} | 32'h0;
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h824, wr_dat[31:0], 4'hF);

    // Global Ring entry 0  0x204  : num of dsc 16 
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h204, 32'h00000010, 4'hF);

    // Global Function MAP 0x400
    //   [22:11] Qcout 
    //   [10:0]  Qid_base for this Func
    //   Address: 0x400+ Fnum*4
    addr = 32'h400 + fnc * 4;
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, addr[31:0], {q_count, q_base}|32'b0, 4'hF);

    // Ind Dire CTXT MASK 0x814  
    //   0xffffffff for all 128 bits 
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h814, 32'hffffffff, 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h818, 32'hffffffff, 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h81C, 32'hffffffff, 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h820, 32'hffffffff, 4'hF);

    // Set up C2H SW CTXT 
    wr_dat[127:64] =  64'h400;  //  dsc_base
    wr_dat[63:61]  =  'h0;      //  rsv
    wr_dat[60]     =  'b0;      //  err_wb_sent
    wr_dat[59:58]  =  'h0;      //  err        
    wr_dat[57]     =  'b0;      //  irq_no_last
    wr_dat[56]     =  'b0;      //  irq_pnd    
    wr_dat[55:54]  =  'b0;      //  rsv0       
    wr_dat[53]     =  'b0;      //  irq_en     
    wr_dat[52]     =  1'b1;     //  wbk_en     
    wr_dat[51]     =  'b0;      //  mm_chn     
    wr_dat[50]     =  'b0;      //  byp        
    wr_dat[49:48]  =  2'b10;    //  dsc_sz     
    wr_dat[47:44]  =  'b0;      //  rng_sz     
    wr_dat[43:36]  =  fnc;      //  fnc_id     
    wr_dat[35]     =  'b0;      //  wbi_acc_en 
    wr_dat[34]     =  1'b1;     //  wbi_chk    
    wr_dat[33]     =  'b0;      //  fcrd_en    
    wr_dat[32]     =  1'b1;     //  qen        
    wr_dat[31:17]  =  'b0;      //  rsv        
    wr_dat[16]     =  'b0;      //  irq_ack    
    wr_dat[15:0]   =  pidx;     //  pidx       

    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h804, wr_dat[31:0], 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h808, wr_dat[63:32], 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h80C, wr_dat[95:64], 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h810, wr_dat[127:96], 4'hF);

    // Program SW C2H CTXT	
    //   [17:7] QID   
    //   [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
    //   [4:1]  MDMA_CTXT_SELC_DSC_SW_C2H = 0 : 0000
    //   0      BUSY : 0 
    wr_dat[31:0] = {hw_qid[10:0],2'b01, 4'b0000, 1'b0} | 32'h0;
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h824, wr_dat[31:0], 4'hF);
    TSK_QDMA_READ(pfn, PF_DMA_BAR_INDEX, 32'h824);  //Read PIDX pointer

    // ARM H2C transfer 0x1004 MDMA_C2H_MM0_CONTROL to start DMA
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h1004, 32'h00000001, 4'hF);

    // Start DMA tranfer
    for (int iter=0; iter < NUM_ITER; iter=iter+1) begin

      EP_BUS_DEV_FNS = {8'b0000_0001, fnc[7:0]};     
 
      $display("\n[%t] : Start C2H Iteration %0d for fnc %0d\n", $realtime, iter, fnc);
      fork
        // Writ PIDX to transfer 1 descriptor 
        pidx = pidx + 1;
        wr_add = trq_sel_queue_addr + (qid* 16) + 8; 
        $display("[%t] : Enabling PIDX %0d for C2H", $realtime, pidx);
        TSK_QDMA_WRITE(fnc, ptr_upt_dma_bar_idx, wr_add[31:0], pidx, 4'hF);  

        TSK_QDMA_READ(fnc, PF_DMA_BAR_INDEX, wr_add);  //Read PIDX pointer

        $display("[%t] : Comparing received C2H data ...", $realtime);
        COMPARE_DATA_C2H({16'h0,DMA_BYTE_CNT},768);

        $display("[%t] : Checking completion CIDX ...", $realtime);
        COMPARE_TRANS_STATUS(32'h000005E0, pidx); 
      join   

      EP_BUS_DEV_FNS = {8'b0000_0001, pfn};     // ARI Enabled, Bus 1 Function 8'Bfn_num
      TSK_QDMA_READ(pfn, PF_DMA_BAR_INDEX, 32'h1048);
      $display ("[%t] : C2H Completed Descriptor Count = %h", $realtime, P_READ_DATA);
      $display ("[%t] : Iteration %0d --- C2H MM TEST PASSED ---\n",$realtime, iter);
    end
    $display ("[%t] : ******************** C2H MM TEST PASSED ********************* \n",$realtime);
  end
endtask  // TSK_QDMA_C2H_MM


/************************************************************
Task : TSK_QDMA_H2C_ST
Inputs : function number 
Outputs : None
Description : Set up QDMA config space & run H2C streaming test
*************************************************************/
task TSK_QDMA_H2C_ST;

  input [7:0] fnc;
  input [10:0] qid;    // relative qid; use for perform pointer update

  logic [11:0] q_count;
  logic [10:0] q_base;
  logic [10:0] hw_qid; // hw qid: use for global space reg access and user logic.
  logic [15:0] pidx;
  logic [31:0] trq_sel_queue_addr;
  integer ptr_upt_dma_bar_idx ;
  integer usr_bar_idx ;
  localparam NUM_ITER = 1;

  begin
  usr_bar_idx =1;
  ptr_upt_dma_bar_idx =0;
    TSK_FIND_PF_VF_NUM(fnc);

    if (fnc < 4) begin
      $display ("\n[%t] : ***************** Launching H2C ST for PF%0d, Q%0d ********************\n", $realtime, pfn, qid);
      trq_sel_queue_addr = 32'h6400;
      q_base = QUEUE_PER_PF * fnc;
      q_count = QUEUE_PER_PF;
      ptr_upt_dma_bar_idx = PF_DMA_BAR_INDEX;
      usr_bar_idx = PF_USR_BAR_INDEX;
    end
    else begin
      $display ("\n[%t] : ****************** Launching H2C ST for PF%0d, VF%0d, Q%0d ***********************\n", $realtime, pfn, vfn, qid);
      trq_sel_queue_addr = 32'h3000;
      q_base = QUEUE_PER_PF * NUM_PFS + (fnc-4) * QUEUE_PER_VF;
      q_count = QUEUE_PER_VF;
      ptr_upt_dma_bar_idx = VF_DMA_BAR_INDEX;
      usr_bar_idx = VF_USR_BAR_INDEX;
      if (qid > 11'h8) begin
        $display ("ERROR: VF QID Shoud not exceed 8. Please change the test input QID");
        $finish;
      end
    end
    //qid = 11'd7;
    hw_qid = qid + q_base;
    pidx = 'h0;

    TSK_INIT_QDMA_ST_DATA_H2C;

    // Global programming through PF
    EP_BUS_DEV_FNS = {8'b0000_0001, pfn[7:0]};     // ARI Enabled, Bus 1 Function 8'Bfn_num

    // Clear the H2C HW CTXT
    wr_dat[31:0] = {hw_qid, 2'b00, 4'b0011, 1'b0} | 32'h0;
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h824, wr_dat[31:0], 4'hF); 

    // Global Ring Size for entry 0 0x204  : num of dsc 15+1 
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h204, 32'h00000010, 4'hF);

    // Ind Dire CTXT MASK 0x814  0xffffffff for all 128 bits
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h814, 32'hffffffff, 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h818, 32'hffffffff, 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h81C, 32'hffffffff, 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h820, 32'hffffffff, 4'hF);

    // Global Function MAP 0x400 
    //   22:11 Q_count 
    //   10:0  Qid_base 
    wr_add = 16'h400 + fnc * 4;
    wr_dat[31:0] = {q_count, q_base} | 32'h0;
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, wr_add, wr_dat[31:0], 4'hF);

    // Set up H2C SW CTX

    wr_dat[127:64] =  64'h0000000000000100; // dsc base
    wr_dat[63:61]  =  3'h0; // rsv
    wr_dat[60]     =  1'b0; // err_wb_sent 0x0
    wr_dat[59:58]  =  2'b0; // err         0x0
    wr_dat[57]     =  1'b0; // irq_no_last 0x0
    wr_dat[56]     =  1'b0; // irq_pnd     0x0
    wr_dat[55:54]  =  2'b0; // rsv0        0x0
    wr_dat[53]     =  1'b0; // irq_en      0x0
    wr_dat[52]     =  1'b1; // wbk_en      0x1
    wr_dat[51]     =  1'b0; // mm_chn      0x0
    wr_dat[50]     =  1'b0; // byp         0x0
    wr_dat[49:48]  =  2'b1; // dsc_sz      0x1
    wr_dat[47:44]  =  4'h0; // rng_sz      0x0
    wr_dat[43:36]  =  fnc;  // fnc_id     
    wr_dat[35]     =  1'b0; // wbi_acc_en  0x0
    wr_dat[34]     =  1'b1; // wbi_chk     0x1
    wr_dat[33]     =  1'b0; // fcrd_en     0x0
    wr_dat[32]     =  1'b1; // qen         0x1
    wr_dat[31:17]  =  'h0;  // rsv         0x0
    wr_dat[16]     =  1'b0; // irq_ack     0x0
    wr_dat[15:0]   = pidx;  // pidx

    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h804, wr_dat[31:0], 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h808, wr_dat[63:32], 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h80C, wr_dat[95:64], 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h810, wr_dat[127:96], 4'hF);

    wr_dat[31:0] = {hw_qid[10:0], 2'b01, 4'b0001, 1'b0} | 32'h0;
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h824, wr_dat[31:0], 4'hF);

    // Post PIDX to initiate transfer
    for (int iter=0; iter < NUM_ITER; iter=iter+1) begin

      EP_BUS_DEV_FNS = {8'b0000_0001, fnc[7:0]};     
 
      $display("\n[%t] : Start H2C Iteration %0d for fnc %0d\n", $realtime, iter, fnc);

      // Clear match bit before each H2C ST transfer
      TSK_QDMA_WRITE(fnc, usr_bar_idx, 32'h0C, 32'h1, 4'hF); 

      fork 
        // Transfer H2C for 1 dsc
        //  Update PIDX in H2C SW CTXT 
        //  There is no run bit for AXI-Stream, no need to arm them.
        pidx = pidx + 1;
        wr_add = trq_sel_queue_addr + (qid* 16) + 4; 
        $display("[%t] : Enabling PIDX %0d for H2C...", $realtime, pidx);
        TSK_QDMA_WRITE(fnc, ptr_upt_dma_bar_idx, wr_add[31:0], pidx, 4'hF);   
      
        $display("[%t] : Checking completion CIDX...", $realtime);
        COMPARE_TRANS_STATUS(32'h000001F0, pidx); 
      join

      // check for if data on user side matched what was expected.
      TSK_QDMA_READ (fnc, usr_bar_idx, 32'h10); 
      if (P_READ_DATA[0] == 1'b1) begin
        $display ("[%t] : Iteration %0d --- H2C ST TEST PASSED ---\n",$realtime, iter);
      end else begin
        $display ("[%t] : Iteration %0d --- H2C ST TEST FAILED --- ERROR: H2C ST Data Mis-Matches on Q number = %h\n",$realtime, iter, P_READ_DATA[10:4]);
        $finish;
      end
    end
    $display ("[%t] : *********************** H2C ST TEST PASSED ************************** \n",$realtime);
  end
endtask // TSK_QDMA_H2C_ST

/************************************************************
Task : TSK_QDMA_C2H_ST
Inputs : function number 
Outputs : None
Description : Set up QDMA config space & run C2H streaming test
*************************************************************/

task TSK_QDMA_C2H_ST;

  input [7:0] fnc;
  input [10:0] qid;    // relative qid; use for perform pointer update

  logic [11:0] q_count;
  logic [10:0] q_base;
  logic [10:0] hw_qid; // hw qid: use for global space reg access and user logic.
  logic [15:0] pidx ;
  logic [31:0] trq_sel_queue_addr;
  integer ptr_upt_dma_bar_idx ;
  integer usr_bar_idx;
  localparam NUM_ITER = 1;

  begin
  pidx =0;
  ptr_upt_dma_bar_idx =0;
  usr_bar_idx =1;
    TSK_FIND_PF_VF_NUM(fnc);

    if (fnc < 4) begin
      $display ("\n[%t] : ************************ Launching C2H ST for PF%0d **************************\n", $realtime, pfn);
      trq_sel_queue_addr = 32'h6400;
      q_base = QUEUE_PER_PF * fnc;
      q_count = QUEUE_PER_PF;
      ptr_upt_dma_bar_idx = PF_DMA_BAR_INDEX;
      usr_bar_idx = PF_USR_BAR_INDEX;
    end
    else begin
      $display ("\n[%t] : ************************* Launching C2H ST for PF%0d, VF%0d ******************************\n", $realtime, pfn, vfn);
      trq_sel_queue_addr = 32'h3000;
      q_base = QUEUE_PER_PF * NUM_PFS + (fnc-4) * QUEUE_PER_VF;
      q_count = QUEUE_PER_VF;
      ptr_upt_dma_bar_idx = VF_DMA_BAR_INDEX;
      usr_bar_idx = VF_USR_BAR_INDEX;
      if (qid > 11'h8) begin
        $display ("ERROR: VF QID Shoud not exceed 8. Please change the test input QID");
        $finish;
      end
    end

    // Assign Q for AXI-ST
    hw_qid = qid + q_base;

    // TSK_INIT_QDMA_ST_DATA_H2C needs to be called for C2H, as we will compared with the data pattern at 
    //   DATA_STORE[512], which is set up here.
    TSK_INIT_QDMA_ST_DATA_H2C;
    TSK_INIT_QDMA_ST_DATA_C2H;
    TSK_INIT_QDMA_ST_WBK_C2H;

    // Global programming through PF
    EP_BUS_DEV_FNS = {8'b0000_0001, pfn[7:0]};     // ARI Enabled, Bus 1 Function 8'Bfn_num

    // Clear HW CXTX for  C2H 
    // [17:7] QID   01
    // [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
    // [4:1]  MDMA_CTXT_SELC_DSC_HW_C2H = 2 : 0010
    // 0      BUSY : 0 
    wr_dat[31:0] = {hw_qid[10:0], 2'b00, 4'b0010, 1'b0} | 32'h0;
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h824, wr_dat[31:0], 4'hF);

    // Global Ring Size for entry 0 0x204  : num of dsc 15+1 
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h204, 32'h00000010, 4'hF);

    // Global Ring Size for entry 1 0x208  : num of dsc 15+1 
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h208, 32'h00000010, 4'hF);

    // Ind Dire CTXT MASK 0x814  0xffffffff for all 128 bits
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h814, 32'hffffffff, 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h818, 32'hffffffff, 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h81C, 32'hffffffff, 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h820, 32'hffffffff, 4'hF);

    // Global Function MAP 0x400 
    //   22:11 Q_count 
    //   10:0  Qid_base 
    wr_add = 16'h400 + fnc * 4;
    wr_dat[31:0] = {q_count, q_base} | 32'h0;
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, wr_add, wr_dat[31:0], 4'hF);

    // Program C2H WBK timer Trigger to 1
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'hA00, 32'h00000001, 4'hF);

    // Program C2H WBK Counter Threshold to 1 
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'hA40, 32'h00000001, 4'hF);

    // Program C2H DSC buffer size to 4K 
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'hAB0, 32'h00001000, 4'hF);

    // Setup C2H SW context
    wr_dat [127:64] = 64'h400; // dsc_base
    wr_dat [63:61]  = '0;      // rsv
    wr_dat [60]     = '0;      // err_wb_sent
    wr_dat [59:58]  = '0;      // err
    wr_dat [57]     = '0;      // irq_no_last
    wr_dat [56]     = '0;      // irq_pnd
    wr_dat [55:54]  = '0;      // rsv0
    wr_dat [53]     = '0;      // irq_en
    wr_dat [52]     = '1;      // wbk_en
    wr_dat [51]     = '0;      // mm_chn
    wr_dat [50]     = '0;      // byp
    wr_dat [49:48]  = '0;      // dsc_sz - 0 : 8B; 1 : 16B; 2 : 32B
    wr_dat [47:44]  = '0;      // rng_sz
    wr_dat [43:36]  = fnc[7:0];// fnc_id
    wr_dat [35]     = '0;      // wbi_acc_en
    wr_dat [34]     = '1;      // wbi_chk
    wr_dat [33]     = '1;      // fcrd_en
    wr_dat [32]     = '1;      // qen
    wr_dat [31:17]  = '0;      // rsv
    wr_dat [16]     = '0;      // irq_ack  
    wr_dat [15:0]   = '0;      // pidx
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h804, wr_dat[31:0], 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h808, wr_dat[63:32], 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h80C, wr_dat[95:64], 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h810, wr_dat[127:96], 4'hF);

    // [17:7] QID  
    // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
    // [4:1]  MDMA_CTXT_SELC_DSC_SW_C2H = 0 : 0000
    // 0      BUSY : 0 
    wr_dat[31:0] = {hw_qid[10:0], 2'b01, 4'b0000, 1'b0} | 32'h0;
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h824, wr_dat[31:0], 4'hF);

    // Set up Writeback Ctxt 
    wr_dat[0]      = 1;        // en_stat_desc
    wr_dat[1]      = 0;        // en_int
    wr_dat[4:2]    = 3'h1;     // trig_mode
    wr_dat[12:5]   = fnc[7:0]; // func_id       
    wr_dat[16:13]  = 4'h0;     // countr_idx 
    wr_dat[20:17]  = 4'h0;     // timer_idx 
    wr_dat[22:21]  = 2'h0;     // int_st 
    wr_dat[23]     = 1'h1;     // color 
    wr_dat[27:24]  = '0;       // qsize_idx
    wr_dat[85:27]  = 58'h20;   // baddr_64 = [63:6]only (baddr=0x800)
    wr_dat[87:86]  = 2'h0;     // desc_size 
    wr_dat[103:88] = 16'h0;    // pidx        
    wr_dat[119:104]= 16'h0;    // Cidx  
    wr_dat[120]    = 1'h1;     // valid
    wr_dat[122:121]= '0;       // err
    wr_dat[127:123]= 'h0;      // reserved 
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h804, wr_dat[31:0], 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h808, wr_dat[63:32], 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h80C, wr_dat[95:64], 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h810, wr_dat[127:96], 4'hF);

    // [17:7] QID  
    // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
    // [4:1]  MDMA_CTXT_SELC_WBK = 6 : 0110
    // 0      BUSY : 0 
    wr_dat[31:0] = {hw_qid[10:0], 2'b01, 4'b0110, 1'b0} | 32'h0;
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h824, wr_dat[31:0], 4'hF);

    //Set up PreFetch CTXT 
    // valid = 1
    // all 0's
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h804, 32'h00000000, 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h808, 32'h00000000, 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h80C, 32'h00000000, 4'hF);
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h810, 32'h00000000, 4'hF);

    // [17:7] QID 
    // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
    // [4:1]  MDMA_CTXT_SELC_PFTCH = 7 : 0111
    // [0]    BUSY : 0 
    wr_dat[31:0] = {hw_qid[10:0], 2'b01, 4'b0111, 1'b0}| 32'h0;
    TSK_QDMA_WRITE(pfn, PF_DMA_BAR_INDEX, 32'h824, wr_dat[31:0], 4'hF);

    for (int iter=0; iter < NUM_ITER; iter=iter+1) begin

      EP_BUS_DEV_FNS = {8'b0000_0001, fnc[7:0]};     
 
      $display("\n[%t] : Start C2H Iteration %0d for fnc %0d\n", $realtime, iter, fnc);

      // Update CIDX 0x00 for WBK context
      wr_dat [31:29] = '0;     // rsv
      wr_dat [28]    = '0;     // enable interrupt for wrb
      wr_dat [27]    = '1;     // enbale status descriptor
      wr_dat [26:24] = 3'b001; // trigger mode
      wr_dat [23:20] = '0;     // idx to QDMA_C2H_TIMER_CNT
      wr_dat [19:16] = '0;     // idx to QDMA_C2H_CNT_TH
      wr_dat [15:0]  = '0;     // wb CIDX 
      wr_add = trq_sel_queue_addr + (qid*16) + 12;  
      TSK_QDMA_WRITE(fnc, ptr_upt_dma_bar_idx, wr_add[31:0], wr_dat[31:0], 4'hF);

      // Transfer C2H for 1 dsc
      //  Update PIDX in C2H SW CTXT 
      //  There is no run bit for AXI-Stream, no need to arm them.
      pidx = pidx + 1;
      wr_add = trq_sel_queue_addr + (qid* 16) + 8; 
      $display("[%t] : Enabling PIDX %0d for C2H", $realtime, pidx);
      TSK_QDMA_WRITE(fnc, ptr_upt_dma_bar_idx, wr_add[31:0], pidx, 4'hF);  

      // Write HW Q number on user side for AXI-ST C2H transfer 
      TSK_QDMA_WRITE(fnc, usr_bar_idx, 32'h00, {21'h0, hw_qid[10:0]}, 4'hF);  

      // Set number of packet = 1
      TSK_QDMA_WRITE(fnc, usr_bar_idx, 32'h20, 32'h1, 4'hF);  

      // Set transfer length = 128 bytes
      TSK_QDMA_WRITE(fnc, usr_bar_idx, 32'h04, 32'h80, 4'hF);

      // Set Writeback data
      TSK_QDMA_WRITE(fnc, usr_bar_idx, 32'h30, 32'ha4a3a2a1, 4'hF);    
      TSK_QDMA_WRITE(fnc, usr_bar_idx, 32'h34, 32'hb4b3b2b1, 4'hF);   
      TSK_QDMA_WRITE(fnc, usr_bar_idx, 32'h38, 32'hc4c3c2c1, 4'hF);   
      TSK_QDMA_WRITE(fnc, usr_bar_idx, 32'h3C, 32'hd4d3d2d1, 4'hF);   
      TSK_QDMA_WRITE(fnc, usr_bar_idx, 32'h40, 32'he4e3e2e1, 4'hF);   
      TSK_QDMA_WRITE(fnc, usr_bar_idx, 32'h44, 32'hf4f3f2f1, 4'hF);   
      TSK_QDMA_WRITE(fnc, usr_bar_idx, 32'h48, 32'h14131211, 4'hF);   
      TSK_QDMA_WRITE(fnc, usr_bar_idx, 32'h4C, 32'h24232221, 4'hF);   
      fork
        // Start C2H tranfer
        TSK_QDMA_WRITE(fnc, usr_bar_idx, 32'h08, 32'h02, 4'hF);   

        // Compare data with H2C data @ addr=512
        COMPARE_DATA_C2H({16'h0,DMA_BYTE_CNT},512);
      join

      // Compare status writes
      COMPARE_TRANS_C2H_ST_STATUS(32'h00000400, pidx); //Write back status

      // Update CIDX in WB CTXT
      wr_dat [31:29] = '0;     // rsv
      wr_dat [28]    = '0;     // enable interrupt for wrb
      wr_dat [27]    = '1;     // enbale status descriptor
      wr_dat [26:24] = 3'b001; // trigger mode
      wr_dat [23:20] = '0;     // idx to QDMA_C2H_TIMER_CNT
      wr_dat [19:16] = '0;     // idx to QDMA_C2H_CNT_TH
      wr_dat [15:0]  = pidx;   // wb CIDX 
      wr_add[31:0] = trq_sel_queue_addr + (qid*16) + 12;  
      TSK_QDMA_WRITE(fnc, ptr_upt_dma_bar_idx, wr_add[31:0], wr_dat[31:0], 4'hF); 

      $display ("[%t] : Iteration %0d --- C2H ST TEST PASSED ---\n",$realtime, iter);
    end
    $display ("[%t] : ***************** C2H ST TEST PASSED ******************** \n",$realtime);
  end
endtask

endmodule // pci_exp_usrapp_tx
