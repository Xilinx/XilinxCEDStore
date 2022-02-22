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
// File       : sample_tests_sriov.vh
// Version    : 5.0
//-----------------------------------------------------------------------------
//
//------------------------------------------------------------------------------

else if (testname == "qdma_mailbox")
begin
  byte src_fnc = 8'h4;
  byte dst_fnc = 8'h0;
  board.RP.tx_usrapp.TSK_QDMA_MB_VF2PF (src_fnc, dst_fnc);
  #100;
  src_fnc = 8'h0; dst_fnc = 8'h4;
  board.RP.tx_usrapp.TSK_QDMA_MB_PF2VF (src_fnc, dst_fnc);
  #100;
  $finish;
end
else if (testname == "qdma_sriov_all")
begin
  byte fnc = 8'h4;
  logic [10:0] qid = 11'h7;  
//  board.RP.tx_usrapp.TSK_QDMA_H2C_MM (fnc[7:0], qid); 
  #100;
//  board.RP.tx_usrapp.TSK_QDMA_C2H_MM (fnc[7:0], qid); 
  #100;
  board.RP.tx_usrapp.TSK_QDMA_H2C_ST (fnc[7:0], qid); 
  #100;
  board.RP.tx_usrapp.TSK_QDMA_C2H_ST (fnc[7:0], qid); 
  $finish; 
end
else if(testname =="qdma_h2c_mm")
begin
  byte fnc = 8'h4;
  logic [10:0] qid = 11'h7;  
  board.RP.tx_usrapp.TSK_QDMA_H2C_MM (fnc[7:0], qid); 
  $finish(2);
end
else if(testname =="qdma_mm")
begin
  byte fnc = 8'h4;
  logic [10:0] qid = 11'h7;  
  board.RP.tx_usrapp.TSK_QDMA_H2C_MM (fnc[7:0], qid); 
  #100;
  board.RP.tx_usrapp.TSK_QDMA_C2H_MM (fnc[7:0], qid); 
  $finish(2);
end
else if(testname =="qdma_h2c_st")
begin
  byte fnc = 8'h4;
  logic [10:0] qid = 11'h4;  
  board.RP.tx_usrapp.TSK_QDMA_H2C_ST (fnc[7:0], qid); 
  board.RP.tx_usrapp.TSK_QDMA_H2C_ST (fnc[7:0], qid+1'b1); 
  $finish(2);
end
else if(testname =="qdma_c2h_st")
begin
  byte fnc = 8'h4;
  logic [10:0] qid = 11'h7;  
  board.RP.tx_usrapp.TSK_QDMA_C2H_ST (fnc[7:0], qid); 
  $finish(2);
end
else if(testname =="qdma_flr_test_0")
begin
  byte fnc = 8'h4;
  logic [10:0] qid = 11'h7;  
  logic [3:0] wait_50us_cnt=0;

  board.RP.tx_usrapp.TSK_QDMA_H2C_MM (fnc, qid); 

  board.RP.tx_usrapp.TSK_SW_FLR(fnc);

  board.RP.tx_usrapp.TSK_TEST_TO_FINISH(fnc);
  while (P_READ_DATA[0] && (wait_50us_cnt < 5))
  begin
    // wait 50us
    $display ("[%t] : Polling on FLR Status Reg every 50us ...", $realtime);
    #50000000;
    wait_50us_cnt = wait_50us_cnt +1 ;
    board.RP.tx_usrapp.TSK_TEST_TO_FINISH(fnc);
  end

  if (~P_READ_DATA[0])  $display ("[%t] : ******* PASS - Pre-FLR complete successfully *************", $realtime);
  else                  $display ("[%t] : ************* ERROR - FLR may not complete *************", $realtime);

  board.RP.tx_usrapp.TSK_PCIE_FLR(fnc);

  $finish;
end
