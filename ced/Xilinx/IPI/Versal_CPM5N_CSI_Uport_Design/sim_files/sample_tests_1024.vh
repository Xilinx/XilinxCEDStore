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

else if(testname == "sample_smoke_test0")
begin


    TSK_SIMULATION_TIMEOUT(5050);
    board.RP.trig_uport_gen = 'h0; 

    //System Initialization
    TSK_SYSTEM_INITIALIZATION;




    
    $display("[%t] : Expected Device/Vendor ID = %x", $realtime, DEV_VEN_ID); 
    
    //--------------------------------------------------------------------------
    // Read core configuration space via PCIe fabric interface
    //--------------------------------------------------------------------------

    $display("[%t] : Reading from PCI/PCI-Express Configuration Register 0x00", $realtime);

    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h0, 4'hF);
    TSK_WAIT_FOR_READ_DATA;
    if  (P_READ_DATA != DEV_VEN_ID) begin
        $display("[%t] : TEST FAILED --- Data Error Mismatch, Write Data %x != Read Data %x", $realtime, 
                                    DEV_VEN_ID, P_READ_DATA);
    end
    else begin
        $display("[%t] : TEST PASSED --- Device/Vendor ID %x successfully received", $realtime, P_READ_DATA);
        //$display("[%t] : Test Completed Successfully",$realtime);
    end

    //--------------------------------------------------------------------------
    // Direct Root Port to allow upstream traffic by enabling Mem, I/O and
    // BusMstr in the command register
    //--------------------------------------------------------------------------

    board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b1110);
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    
    //BAR Init
    
    //$system("date +'Enum done : date %X--%x'");
    board.RP.tx_usrapp.TSK_BAR_INIT;
      
    // PIO Byte enable tests
    $system("date +'PIO Access: System Time %X--%x'"); 
    
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h10, 32'h12345678,4'hf);
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h14, 32'hAA5555AA,4'hf);
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h18, 32'hC6C6C6C6,4'hf);
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h1C, 32'h11111111,4'hf);
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h20, 32'h22222222,4'hf);
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h24, 32'h33333333,4'hf);
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h28, 32'h44444444,4'hf);
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h2C, 32'h55555555,4'hf);
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h30, 32'h66666666,4'hf);
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h34, 32'h77777777,4'hf);
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h38, 32'h88888888,4'hf);
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h3C, 32'h99999999,4'hf);
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h40, 32'hAAAAAAAA,4'hf);
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h44, 32'hBBBBBBBB,4'hf);
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h48, 32'hCCCCCCCC,4'hf);
    board.RP.tx_usrapp.TSK_MEM32_WR(32'h4C, 32'hDDDDDDDD,4'hf);
    
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h110);
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h114);
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h118);
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h11C);
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h120);
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h124);
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h128);
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h12C);
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h130);
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h134);
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h138);
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h13C);
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h140);
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h144);
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h148);
    board.RP.tx_usrapp.TSK_MEM32_RD(32'h14C);
    
    $system("date +'Trigger UPort Gen : System Time %X--%x'"); 
    board.RP.trig_uport_gen = 'h1; 
    
    board.RP.tx_usrapp.TSK_TX_CLK_EAT(5000);
    $display("[%t] : CSI User Port Capsule Counts", $realtime);
    $display("PR Received   = %d", {board.EP.csi_uport_inst.csi_uport_axil_reg_1.pr_sop_received_count_i[31:0]});
    $display("NPR Received  = %d", {board.EP.csi_uport_inst.csi_uport_axil_reg_1.npr_sop_received_count_i[31:0]}); 
    $display("CMPL Sent     = %d", {board.EP.csi_uport_inst.csi_uport_axil_reg_1.cmpl_sop_sent_cnt_i[31:0]}); 
    
    $display("PR Sent       = %d", {board.EP.csi_uport_inst.csi_uport_axil_reg_1.pr_sop_sent_cnt_i[31:0]}); 
    $display("NPR Sent      = %d", {board.EP.csi_uport_inst.csi_uport_axil_reg_1.npr_sop_sent_cnt_i[31:0]}); 
    $display("CMPL Received = %d", {board.EP.csi_uport_inst.csi_uport_axil_reg_1.cmpl_sop_received_count_i[31:0]}); 
    
    $display("[%t] : CSI Test Completed", $realtime);
    $system("date +'Test Completed : System Time %X--%x'"); 

    $finish;
end


else if(testname == "sample_smoke_test1")
begin

    // This test use tlp expectation tasks.

    TSK_SIMULATION_TIMEOUT(5050);

    // System Initialization
    TSK_SYSTEM_INITIALIZATION;
    // Program BARs (Required so Completer ID at the Endpoint is updated)
    TSK_BAR_INIT;

fork
  begin
    //--------------------------------------------------------------------------
    // Read core configuration space via PCIe fabric interface
    //--------------------------------------------------------------------------

    $display("[%t] : Reading from PCI/PCI-Express Configuration Register 0x00", $realtime);

    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h0, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);
  end
    //---------------------------------------------------------------------------
    // List Rx TLP expections
    //---------------------------------------------------------------------------
  begin
    test_vars[0] = 0;                                                                                                                         
                                          
    $display("[%t] : Expected Device/Vendor ID = %x", $realtime, DEV_VEN_ID);                                              

    expect_cpld_payload[0] = DEV_VEN_ID[31:24];
    expect_cpld_payload[1] = DEV_VEN_ID[23:16];
    expect_cpld_payload[2] = DEV_VEN_ID[15:8];
    expect_cpld_payload[3] = DEV_VEN_ID[7:0];
    @(posedge pcie_rq_tag_vld);
    exp_tag = pcie_rq_tag;

    board.RP.com_usrapp.TSK_EXPECT_CPLD(
      3'h0, //traffic_class;
      1'b0, //td;
      1'b0, //ep;
      2'h0, //attr;
      10'h1, //length;
      board.RP.tx_usrapp.EP_BUS_DEV_FNS, //completer_id;
      3'h0, //completion_status;
      1'b0, //bcm;
      12'h4, //byte_count;
      board.RP.tx_usrapp.RP_BUS_DEV_FNS, //requester_id;
      exp_tag ,
      7'b0, //address_low;
      expect_status //expect_status;
    );

    if (expect_status) 
      test_vars[0] = test_vars[0] + 1;      
  end
join
  
  expect_finish_check = 1;

  if (test_vars[0] == 1) begin
    $display("[%t] : TEST PASSED --- Finished transmission of PCI-Express TLPs", $realtime);
    $display("[%t] : Test Completed Successfully",$realtime);
  end else begin
    $display("[%t] : TEST FAILED --- Haven't Received All Expected TLPs", $realtime);

    //--------------------------------------------------------------------------
    // Direct Root Port to allow upstream traffic by enabling Mem, I/O and
    // BusMstr in the command register
    //--------------------------------------------------------------------------

    board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b1110);
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);

  end

  $finish;
end
// BMD Specific 
else if(testname == "msi_smoke_test")
begin
     $display("[%t] : Start MSI-/MSIX Simulation",$realtime);
    TSK_SIMULATION_TIMEOUT(5050);

    // System Initialization
    TSK_SYSTEM_INITIALIZATION;
    // Program BARs (Required so Completer ID at the Endpoint is updated)
    TSK_BAR_INIT;


    // Enable MSI
    // Can be commented out to test Legacy interrupt

    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h48, 32'h00A0_7005, 4'b0100);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);
    
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h48, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    $display("[%t] : Config Addr = %x ; Data = %x", $realtime, 32'h48, P_READ_DATA);
    
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h4C, 32'h7654_3210, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);
    
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h4C, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    $display("[%t] : Config Addr = %x ; Data = %x", $realtime, 32'h4C, P_READ_DATA);
 
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h54, 32'hABCD_EF00, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);
        
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h54, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    $display("[%t] : Config Addr = %x ; Data =%x", $realtime, 32'h54, P_READ_DATA);  
    
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h48, 32'h00A1_7005, 4'b0100);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);
    
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h48, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    $display("[%t] : Config Addr = %x ; Data = %x", $realtime, 32'h48, P_READ_DATA);
         
    //DCSR - Assert Initiator Reset
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h0, 32'h00000001,4'hf);
                  //DCSR - De-assert Initiator Reset
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h0, 32'h00000000,4'hf);


    // Start BMD Traffic Iter 1 /////////////////////

    //WDMATLPS
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h0c, 32'h00000001,4'hf); // 32DW
    //Write DMA TLP Count
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h10, 32'h000C,4'hf);  // 1MB Transfer
    // Read DMA TLP Count
   //   board.RP.tx_usrapp.TSK_MEM32_RD(32'h10);  // 1MB Transfer
    //Write DMA Pattern
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h14, 32'h54535251,4'hf);
    //RDMATLPS
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h20, 32'h00000001,4'hf);
    //RDMATPC
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h24, 32'h01,4'hf);
    //DCSR2- Start Writes
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h4, 32'h00010001,4'hf);

      $display("[%t] : Start BMD Iterations ",$realtime);
      //wait(board.EP.pcie_app_versal_i.BMD_AXIST_1024.BMD_AXIST_EP_1024.mwr_done);
      $display("[%t] : BMD Iteration Complete ",$realtime);

     #50000 $finish;
end


else if(testname == "msix_smoke_test")
begin
     $display("[%t] : Start MSI-/MSIX Simulation",$realtime);
    TSK_SIMULATION_TIMEOUT(5050);

    // System Initialization
    TSK_SYSTEM_INITIALIZATION;
    // Program BARs (Required so Completer ID at the Endpoint is updated)
    TSK_BAR_INIT;


    // Enable MSI

    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h60, 32'h8008_7011, 4'b1000);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);
    
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h60, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    $display("[%t] : Config Addr = %x ; Data = %x", $realtime, 12'h60, P_READ_DATA);
    
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h64, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    $display("[%t] : Config Addr = %x ; Data = %x", $realtime, 12'h64, P_READ_DATA);
 
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h68, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    $display("[%t] : Config Addr = %x ; Data =%x", $realtime, 12'h68, P_READ_DATA);  
    
    //DCSR - Assert Initiator Reset
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h0, 32'h00000001,4'hf);
                  //DCSR - De-assert Initiator Reset
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h0, 32'h00000000,4'hf);


    // Start BMD Traffic Iter 1 /////////////////////

    //WDMATLPS
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h0c, 32'h00000001,4'hf); // 32DW
    //Write DMA TLP Count
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h10, 32'h000C,4'hf);  // 1MB Transfer
    // Read DMA TLP Count
   //   board.RP.tx_usrapp.TSK_MEM32_RD(32'h10);  // 1MB Transfer
    //Write DMA Pattern
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h14, 32'h54535251,4'hf);
    //RDMATLPS
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h20, 32'h00000001,4'hf);
    //RDMATPC
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h24, 32'h01,4'hf);
    //DCSR2- Start Writes
      board.RP.tx_usrapp.TSK_MEM32_WR(32'h4, 32'h00010001,4'hf);

      $display("[%t] : Start BMD Iterations ",$realtime);
      //wait(board.EP.pcie_app_versal_i.BMD_AXIST_1024.BMD_AXIST_EP_1024.mwr_done);
      $display("[%t] : BMD Iteration Complete ",$realtime);

     #50000 $finish;
end

// BMD Specific 

else if(testname == "pio_writeReadBack_test0")
begin

    // This test performs a 32 bit write to a 32 bit Memory space and performs a read back

    board.RP.tx_usrapp.TSK_SIMULATION_TIMEOUT(10050);

    board.RP.tx_usrapp.TSK_SYSTEM_INITIALIZATION;

    board.RP.tx_usrapp.TSK_BAR_INIT;
        
    //--------------------------------------------------------------------------
    // Direct Root Port to allow upstream traffic by enabling Mem, I/O and
    // BusMstr in the command register
    //--------------------------------------------------------------------------

    board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b1110);
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);

//--------------------------------------------------------------------------
// Event : Testing BARs
//--------------------------------------------------------------------------

        for (board.RP.tx_usrapp.ii = 0; board.RP.tx_usrapp.ii <= 6; board.RP.tx_usrapp.ii =
            board.RP.tx_usrapp.ii + 1) begin
            if (board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[board.RP.tx_usrapp.ii] > 2'b00) // bar is enabled
               case(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[board.RP.tx_usrapp.ii])
                   2'b01 : // IO SPACE
                        begin

                          $display("[%t] : Transmitting TLPs to IO Space BAR %x", $realtime, board.RP.tx_usrapp.ii);

                          //--------------------------------------------------------------------------
                          // Event : IO Write bit TLP
                          //--------------------------------------------------------------------------


                          board.RP.tx_usrapp.TSK_TX_IO_WRITE(board.RP.tx_usrapp.DEFAULT_TAG,
                             board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0], 4'hF, 32'hdead_beef);
                             @(posedge pcie_rq_tag_vld);
                             exp_tag = pcie_rq_tag;


                          board.RP.com_usrapp.TSK_EXPECT_CPL(3'h0, 1'b0, 1'b0, 2'b0,
                             board.RP.tx_usrapp.EP_BUS_DEV_FNS, 3'h0, 1'b0, 12'h4,
                             board.RP.tx_usrapp.RP_BUS_DEV_FNS, exp_tag,
                             board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0], test_vars[0]);

                          board.RP.tx_usrapp.TSK_TX_CLK_EAT(10);
                          board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;

                          //--------------------------------------------------------------------------
                          // Event : IO Read bit TLP
                          //--------------------------------------------------------------------------


                          // make sure P_READ_DATA has known initial value
                          board.RP.tx_usrapp.P_READ_DATA = 32'hffff_ffff;
                          fork
                             board.RP.tx_usrapp.TSK_TX_IO_READ(board.RP.tx_usrapp.DEFAULT_TAG,
                                board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0], 4'hF);
                             board.RP.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                          join
                          if  (board.RP.tx_usrapp.P_READ_DATA != 32'hdead_beef)
                             begin
                               testError=1'b1;
                               $display("[%t] : Test FAILED --- Data Error Mismatch, Write Data %x != Read Data %x",
                                   $realtime, 32'hdead_beef, board.RP.tx_usrapp.P_READ_DATA);
                             end
                          else
                             begin
                               $display("[%t] : Test PASS --- Write Data: %x successfully received",
                                   $realtime, board.RP.tx_usrapp.P_READ_DATA);
                             end


                          board.RP.tx_usrapp.TSK_TX_CLK_EAT(10);
                          board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;


                        end

                   2'b10 : // MEM 32 SPACE
                        begin


// PIO_READWRITE_TEST CASE for C_AXIS_WIDTH == 512

//$display("[%t] : Transmitting TLPs to Memory 32 Space BAR %x at address %x", $realtime,
                          //    board.RP.tx_usrapp.ii, board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0]+8'h10+(board.RP.tx_usrapp.ii*8'h20));
                          $display("[%t] : Transmitting TLPs to Memory 32 Space BAR %x", $realtime,
                              board.RP.tx_usrapp.ii);

                          //--------------------------------------------------------------------------
                          // Event : Memory Write 32 bit TLP
                          //--------------------------------------------------------------------------


                          board.RP.tx_usrapp.DATA_STORE[0] = {board.RP.tx_usrapp.ii,4'h4};//8'h04;
                          board.RP.tx_usrapp.DATA_STORE[1] = {board.RP.tx_usrapp.ii,4'h3};//8'h03;
                          board.RP.tx_usrapp.DATA_STORE[2] = {board.RP.tx_usrapp.ii,4'h2};//8'h02;
                          board.RP.tx_usrapp.DATA_STORE[3] = {board.RP.tx_usrapp.ii,4'h1};//8'h01;
                          
                          // Default 1DW PIO
                          board.RP.tx_usrapp.TSK_TX_MEMORY_WRITE_32(board.RP.tx_usrapp.DEFAULT_TAG,
                                                                    board.RP.tx_usrapp.DEFAULT_TC, 11'd1,
                                                                    board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0]+8'h14+(board.RP.tx_usrapp.ii*8'h20),
                                                                    4'h0, 4'hF, 1'b0);
                          board.RP.tx_usrapp.TSK_TX_CLK_EAT(100);
                          board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;

                          //--------------------------------------------------------------------------
                          // Event : Memory Read 32 bit TLP
                          //--------------------------------------------------------------------------


                          // make sure P_READ_DATA has known initial value
                          board.RP.tx_usrapp.P_READ_DATA = 32'hffff_ffff;
                          
                          // Default 1DW PIO
                          fork
                             board.RP.tx_usrapp.TSK_TX_MEMORY_READ_32(board.RP.tx_usrapp.DEFAULT_TAG,
                                                                      board.RP.tx_usrapp.DEFAULT_TC, 11'd1,
                                                                      board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0]+8'h14+(board.RP.tx_usrapp.ii*8'h20),
                                                                      4'h0, 4'hF);
                             board.RP.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                          join

                          if  (board.RP.tx_usrapp.P_READ_DATA != {board.RP.tx_usrapp.DATA_STORE[3],
                                                                  board.RP.tx_usrapp.DATA_STORE[2],
                                                                  board.RP.tx_usrapp.DATA_STORE[1],
                                                                  board.RP.tx_usrapp.DATA_STORE[0] })
                          begin
                             testError=1'b1;
                             $display("[%t] : Test FAIL --- Data Error Mismatch, Write Data %x != Read Data %x",
                                      $realtime, {board.RP.tx_usrapp.DATA_STORE[3],board.RP.tx_usrapp.DATA_STORE[2],
                                                  board.RP.tx_usrapp.DATA_STORE[1],board.RP.tx_usrapp.DATA_STORE[0]},
                                      board.RP.tx_usrapp.P_READ_DATA);

                          end
                          else begin
                             $display("[%t] : Test PASS --- 1DW Write Data: %x successfully received",
                                      $realtime, board.RP.tx_usrapp.P_READ_DATA);
                          end

                          board.RP.tx_usrapp.TSK_TX_CLK_EAT(10);
                          board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;


	



                          
	   

                     end
                2'b11 : // MEM 64 SPACE
                     begin


                          //$display("[%t] : Transmitting TLPs to Memory 64 Space BAR %x at address %x", $realtime,
                          //    board.RP.tx_usrapp.ii, board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0]+8'h20+(board.RP.tx_usrapp.ii*8'h20));
                          $display("[%t] : Transmitting TLPs to Memory 64 Space BAR %x", $realtime,
                              board.RP.tx_usrapp.ii);


                          //--------------------------------------------------------------------------
                          // Event : Memory Write 64 bit TLP
                          //--------------------------------------------------------------------------


                          board.RP.tx_usrapp.DATA_STORE[0] = {board.RP.tx_usrapp.ii+6,4'h4};//8'h64;
                          board.RP.tx_usrapp.DATA_STORE[1] = {board.RP.tx_usrapp.ii+6,4'h3};//8'h63;
                          board.RP.tx_usrapp.DATA_STORE[2] = {board.RP.tx_usrapp.ii+6,4'h2};//8'h62;
                          board.RP.tx_usrapp.DATA_STORE[3] = {board.RP.tx_usrapp.ii+6,4'h1};//8'h61;
                          board.RP.tx_usrapp.DATA_STORE[4] = {board.RP.tx_usrapp.ii+6,4'h8};//8'h74;
                          board.RP.tx_usrapp.DATA_STORE[5] = {board.RP.tx_usrapp.ii+6,4'h7};//8'h73;
                          board.RP.tx_usrapp.DATA_STORE[6] = {board.RP.tx_usrapp.ii+6,4'h6};//8'h72;
                          board.RP.tx_usrapp.DATA_STORE[7] = {board.RP.tx_usrapp.ii+6,4'h5};//8'h71;

                          // Default 1DW PIO
                          board.RP.tx_usrapp.TSK_TX_MEMORY_WRITE_64(board.RP.tx_usrapp.DEFAULT_TAG,
                                                                    board.RP.tx_usrapp.DEFAULT_TC, 10'd1,
                                                                   {board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii+1][31:0],
                                                                    board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0]+8'h20+(board.RP.tx_usrapp.ii*8'h20)},
                                                                    4'h0, 4'hF, 1'b0);
                          board.RP.tx_usrapp.TSK_TX_CLK_EAT(10);
                          board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;

                          //--------------------------------------------------------------------------
                          // Event : Memory Read 64 bit TLP
                          //--------------------------------------------------------------------------


                          // make sure P_READ_DATA has known initial value
                          board.RP.tx_usrapp.P_READ_DATA = 32'hffff_ffff;

                          // Default 1DW PIO
                          fork
                             board.RP.tx_usrapp.TSK_TX_MEMORY_READ_64(board.RP.tx_usrapp.DEFAULT_TAG,
                                                                      board.RP.tx_usrapp.DEFAULT_TC, 10'd1,
                                                                     {board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii+1][31:0],
                                                                      board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0]+8'h20+(board.RP.tx_usrapp.ii*8'h20)},
                                                                      4'h0, 4'hF);
                             board.RP.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                          join

                          if  (board.RP.tx_usrapp.P_READ_DATA != {board.RP.tx_usrapp.DATA_STORE[3],
                                                                  board.RP.tx_usrapp.DATA_STORE[2],
                                                                  board.RP.tx_usrapp.DATA_STORE[1],
                                                                  board.RP.tx_usrapp.DATA_STORE[0] })
                          begin
                              testError=1'b1;
                              $display("[%t] : Test FAILED --- Data Error Mismatch, Write Data %x != Read Data %x",
                                       $realtime, {board.RP.tx_usrapp.DATA_STORE[3],
                                                   board.RP.tx_usrapp.DATA_STORE[2], board.RP.tx_usrapp.DATA_STORE[1],
                                                   board.RP.tx_usrapp.DATA_STORE[0]},board.RP.tx_usrapp.P_READ_DATA);

                          end
                          else begin
                              $display("[%t] : Test PASS --- 1DW Write Data: %x successfully received",
                                       $realtime, board.RP.tx_usrapp.P_READ_DATA);
                          end

                          board.RP.tx_usrapp.TSK_TX_CLK_EAT(10);
                          board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;


                     end
                default : $display("Error case in usrapp_tx\n");
            endcase

         end


    if(testError==1'b0)
    $display("[%t] : PASS - Test Completed Successfully",$realtime);

    if(testError==1'b1)
    $display("[%t] : FAIL - Test FAILED due to previous error ",$realtime);


    


    $display("[%t] : Finished transmission of PCI-Express TLPs", $realtime);
    $finish;
end
