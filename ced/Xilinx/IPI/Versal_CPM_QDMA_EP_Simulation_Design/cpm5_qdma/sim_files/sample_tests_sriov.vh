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
// File       : sample_tests_sriov.vh
// Version    : 5.0
//-----------------------------------------------------------------------------
//
//------------------------------------------------------------------------------

else if (testname == "qdma_mailbox")
begin
  byte src_fnc = 8'h11;
  byte dst_fnc = 8'h0;
  board.RP.tx_usrapp.TSK_QDMA_MB_VF2PF (src_fnc, dst_fnc);
  #100;
  src_fnc = 8'h0; dst_fnc = 8'h11;
  // board.RP.tx_usrapp.TSK_QDMA_MB_PF2VF (src_fnc, dst_fnc);
  #100;
  $finish;
end
else if (testname == "qdma_sriov_all")
begin
  byte fnc = 8'h10;
  logic [10:0] qid = 11'h7;  
  board.RP.tx_usrapp.TSK_QDMA_H2C_MM (fnc[7:0], qid); 
  #100;
  board.RP.tx_usrapp.TSK_QDMA_C2H_MM (fnc[7:0], qid); 
  #100;
  board.RP.tx_usrapp.TSK_QDMA_H2C_ST (fnc[7:0], qid); 
  #100;
  board.RP.tx_usrapp.TSK_QDMA_C2H_ST (fnc[7:0], qid); 
  $finish; 
end
else if (testname == "qdma_msix_test")
begin

   reg usr_irq = 1'b1;  
   reg [4:0] usr_irq_in_vec = 5'd0;  
   reg [7:0] fnc;
   integer pf_i;
   integer vf_i;

   for(fnc=0; fnc < NUM_PFS; fnc = fnc + 1)
	begin
	$display ("###################################################################");
	 TSK_FIND_PF_VF_NUM(fnc);
	 TSK_ENABLE_MSIX (fnc);
	 TSK_PROGRAM_MSIX_VEC_TABLE (fnc);	 
	 board.RP.tx_usrapp.TSK_USR_IRQ_TEST(fnc, usr_irq_in_vec, usr_irq); 
	end
	
	for(pf_i=0; pf_i < NUM_PFS; pf_i = pf_i + 1)
	begin				
		for(vf_i=0; vf_i < NUM_VFS[pf_i]; vf_i = vf_i + 1)
		begin
		fnc = pf_i + FIRST_VF_OFFSET[pf_i] + vf_i;		
		TSK_FIND_PF_VF_NUM(fnc);
		TSK_ENABLE_MSIX (fnc);			
		TSK_PROGRAM_MSIX_VEC_TABLE(fnc);		
		board.RP.tx_usrapp.TSK_USR_IRQ_TEST(fnc, usr_irq_in_vec, usr_irq); 		
		end
	end   
   #10000;
  $finish; 
end
/*
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
 */
else if(testname =="qdma_h2c_st")
begin
   byte fnc = 8'h10;
   logic [10:0] qid = 11'h4;
   
//   board.RP.tx_usrapp.TSK_QDMA_H2C_ST_CISCO (fnc[7:0], qid); 
  board.RP.tx_usrapp.TSK_QDMA_H2C_ST (fnc[7:0], qid+1'b1); 
  $finish(2);
end
else if(testname =="qdma_c2h_st")
begin
  byte fnc = 8'h10;
  logic [10:0] qid = 11'h7;  
  board.RP.tx_usrapp.TSK_QDMA_C2H_ST (fnc[7:0], qid); 
  $finish(2);
end
else if(testname =="qdma_flr_test_0")
begin
  byte fnc = 8'h10;
  logic [10:0] qid = 11'h7;  
  logic [3:0] wait_50us_cnt=0;

  board.RP.tx_usrapp.TSK_QDMA_H2C_ST (fnc, qid); 

  board.RP.tx_usrapp.TSK_SW_FLR(fnc);

  board.RP.tx_usrapp.TSK_TEST_TO_FINISH(fnc);
  while (P_READ_DATA[0] && (wait_50us_cnt < 5))
  begin
    // wait 50us
    $display ("[%t] : Polling on FLR Status Reg every 50us ...", $realtime);
    #10000000;
    wait_50us_cnt = wait_50us_cnt +1 ;
    board.RP.tx_usrapp.TSK_TEST_TO_FINISH(fnc);
  end

  if (~P_READ_DATA[0])  $display ("[%t] : ******* PASS - Pre-FLR complete successfully *************", $realtime);
  else                  $display ("[%t] : ************* ERROR - FLR may not complete *************", $realtime);

  board.RP.tx_usrapp.TSK_PCIE_FLR(fnc);

  $finish;
end
