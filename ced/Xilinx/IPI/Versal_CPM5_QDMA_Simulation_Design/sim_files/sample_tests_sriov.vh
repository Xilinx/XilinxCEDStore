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
