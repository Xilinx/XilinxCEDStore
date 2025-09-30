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
// File       : sample_tests.vh
// Version    : 5.0
//-----------------------------------------------------------------------------
//
//------------------------------------------------------------------------------


else if(testname =="irq_test0")
begin
   // Program Host Profile to use both AXI MM Port
   board.RP.tx_usrapp.TSK_PROG_HOST_PROFILE;
   qid = 11'h0;
   board.RP.tx_usrapp.TSK_QDMA_MM_H2C_TEST(qid, 0, 0);
   #1000;
   board.RP.tx_usrapp.TSK_USR_IRQ_TEST;   

end
else if(testname =="qdma_mm_test0")
begin
   // Program Host Profile to use both AXI MM Port
   board.RP.tx_usrapp.TSK_PROG_HOST_PROFILE;
   qid = 11'h1;
   board.RP.tx_usrapp.TSK_QDMA_MM_H2C_TEST(qid, 0, 1);
   board.RP.tx_usrapp.TSK_QDMA_MM_C2H_TEST(qid, 0, 1);
   #1000;
   board.RP.tx_usrapp.pfTestIteration = board.RP.tx_usrapp.pfTestIteration + 1;
   if (board.RP.tx_usrapp.test_state == 1 )
     $display ("ERROR: TEST FAILED \n");
   #1000;
   $finish;
end
else if(testname =="qdma_mm_cmpt_test0")
begin
   // Program Host Profile to use both AXI MM Port
   board.RP.tx_usrapp.TSK_PROG_HOST_PROFILE;
   qid = 11'h0;
   board.RP.tx_usrapp.TSK_QDMA_MM_H2C_TEST(qid, 0, 0);
   board.RP.tx_usrapp.TSK_QDMA_MM_C2H_TEST(qid, 0, 0);
   board.RP.tx_usrapp.TSK_QDMA_IMM_TEST(qid);
   #1000;
   board.RP.tx_usrapp.pfTestIteration = board.RP.tx_usrapp.pfTestIteration + 1;
   if (board.RP.tx_usrapp.test_state == 1 )
     $display ("ERROR: TEST FAILED \n");
   #1000;
   $finish;
end

else if(testname == "qdma_st_test0")
begin
   qid = 11'h3;
   board.RP.tx_usrapp.TSK_QDMA_ST_C2H_TEST(qid, 0);
   board.RP.tx_usrapp.TSK_QDMA_ST_H2C_TEST(qid, 0);
   #1000;
   board.RP.tx_usrapp.pfTestIteration = board.RP.tx_usrapp.pfTestIteration + 1;
    if (board.RP.tx_usrapp.test_state == 1 )
     $display ("ERROR: TEST FAILED \n");
   #1000;
   $finish;
end
else if(testname == "qdma_st_h2c_test0")
begin
   qid = 11'h3;
   board.RP.tx_usrapp.TSK_QDMA_ST_H2C_TEST(qid, 0);
   #1000;
   board.RP.tx_usrapp.pfTestIteration = board.RP.tx_usrapp.pfTestIteration + 1;
    if (board.RP.tx_usrapp.test_state == 1 )
     $display ("ERROR: TEST FAILED \n");
   #1000;
   $finish;
end
else if(testname == "qdma_mm_st_test0")
begin
   qid = 11'h3;
   board.RP.tx_usrapp.TSK_QDMA_ST_C2H_TEST(qid, 0);
   board.RP.tx_usrapp.TSK_QDMA_ST_H2C_TEST(qid, 0);
   #1000;

   // Program Host Profile to use both AXI MM Port
   board.RP.tx_usrapp.TSK_PROG_HOST_PROFILE;
   qid = 11'h1;
   board.RP.tx_usrapp.TSK_QDMA_MM_H2C_TEST(qid, 0, 1);
   board.RP.tx_usrapp.TSK_QDMA_MM_C2H_TEST(qid, 0, 1);
   #1000;

   board.RP.tx_usrapp.pfTestIteration = board.RP.tx_usrapp.pfTestIteration + 1;
    if (board.RP.tx_usrapp.test_state == 1 )
     $display ("ERROR: TEST FAILED \n");
   #1000;
   $finish;
end
else if(testname == "qdma_st_c2h_simbyp_test0")
begin
   qid = 11'h3;
   board.RP.tx_usrapp.TSK_QDMA_ST_C2H_SIMBYP_TEST(qid, 1);
   #1000;
   board.RP.tx_usrapp.pfTestIteration = board.RP.tx_usrapp.pfTestIteration + 1;
    if (board.RP.tx_usrapp.test_state == 1 )
     $display ("ERROR: TEST FAILED \n");
   #1000;
   $finish;
end
else if(testname == "qdma_imm_test0")
begin
   qid = 11'h2;
   board.RP.tx_usrapp.TSK_QDMA_IMM_TEST(qid);
   #1000;
   board.RP.tx_usrapp.pfTestIteration = board.RP.tx_usrapp.pfTestIteration + 1;
    if (board.RP.tx_usrapp.test_state == 1 )
     $display ("ERROR: TEST FAILED \n");
   #1000;
   $finish;
end

else if(testname == "qdma_h2c_lp_c2h_imm_test0")
begin
   qid = 11'h1;
   board.RP.tx_usrapp.TSK_QDMA_H2C_LP_C2H_IMM_TEST(qid, 0);
   #1000;
   board.RP.tx_usrapp.pfTestIteration = board.RP.tx_usrapp.pfTestIteration + 1;
    if (board.RP.tx_usrapp.test_state == 1 )
     $display ("ERROR: TEST FAILED \n");
   #1000;
   $finish;
end

