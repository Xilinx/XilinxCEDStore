// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
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

//
// Project    : The PCI Express DMA 
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
   board.RP.tx_usrapp.TSK_QDMA_MM_H2C_TEST(qid, 0, 0, 0);
   #1000;
   board.RP.tx_usrapp.TSK_USR_IRQ_TEST;   

end
else if(testname =="qdma_mm_test0")
begin
   // Program Host Profile to use both AXI MM Port
   board.RP.tx_usrapp.TSK_PROG_HOST_PROFILE;
   qid = 11'h1;
   dsc_bypass = 1'b0;
   mm_chn = 1'b0; 
   
   board.RP.tx_usrapp.TSK_QDMA_MM_H2C_TEST(qid, dsc_bypass, 1'b1, mm_chn);
   board.RP.tx_usrapp.TSK_QDMA_MM_C2H_TEST(qid, dsc_bypass, 1'b1, mm_chn);
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
   board.RP.tx_usrapp.TSK_QDMA_MM_H2C_TEST(qid, 0, 0, 0);
   board.RP.tx_usrapp.TSK_QDMA_MM_C2H_TEST(qid, 0, 0, 0);
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
   board.RP.tx_usrapp.TSK_QDMA_MM_H2C_TEST(qid, 0, 1, 1);
   board.RP.tx_usrapp.TSK_QDMA_MM_C2H_TEST(qid, 0, 1, 1);
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

