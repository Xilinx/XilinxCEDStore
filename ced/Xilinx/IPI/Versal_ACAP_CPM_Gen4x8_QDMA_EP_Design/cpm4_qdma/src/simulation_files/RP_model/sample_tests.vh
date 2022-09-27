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

else if(testname =="dma_stream0")
begin

   //----------------------------------------------------------------------------------------
   // XDMA H2C Test Starts
   //----------------------------------------------------------------------------------------

    $display(" **** XDMA AXI-ST *** \n");
    $display(" **** read Address at BAR0  = %h\n", board.RP.tx_usrapp.BAR_INIT_P_BAR[0][31:0]);
    $display(" **** read Address at BAR1  = %h\n", board.RP.tx_usrapp.BAR_INIT_P_BAR[1][31:0]);

    //-------------- Load DATA in Buffer ----------------------------------------------------
    board.RP.tx_usrapp.TSK_INIT_DATA_H2C;
    board.RP.tx_usrapp.TSK_INIT_DATA_C2H;

    board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h00);
      
    //-------------- Descriptor start address for both H2C and C2H --------------------------
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h4080, 32'h00000100, 4'hF);
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h5080, 32'h00000300, 4'hF);
    
    // completion count writeback addresses
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h0088, 32'h00000000, 4'hF);
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h008C, 32'h0, 4'hF);
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h1088, 32'h00000080, 4'hF);
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h108C, 32'h0, 4'hF);
      
    //-------------- Start DMA tranfer ------------------------------------------------------
    $display(" **** Start DMA Stream for both H2C and C2H transfer ***\n");    
    
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h1004, 32'h2fffe7f, 4'hF);   // Enable C2H DMA
    fork
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h0004, 32'h2fffe7f, 4'hF);   // Enable H2C DMA
    
    //compare C2H data
    $display("------Compare C2H Data--------\n");
    board.RP.tx_usrapp.COMPARE_DATA_C2H({16'h0,board.RP.tx_usrapp.DMA_BYTE_CNT}, 1024);
    join

    // Wait for data transfer complete.

    // For this example design there is 1 descriptor for H2c and 1 for C2H
    // Read C2H Descriptor count and wiat until it returns 1.
    // Becase it is a loopback, by reading C2H descriptor count to 1
    // it ensures H2C descriptor is also set to 1.
    loop_timeout = 0;
    desc_count = 0;
    while (desc_count == 0 && loop_timeout <= 10) begin
          board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h1040);
          $display ("**** C2H status = %h\n", P_READ_DATA);
          board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h0040);
          $display ("**** H2C status = %h\n", P_READ_DATA);
          board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h0048);
          $display ("**** H2C Decsriptor Count = %h\n", P_READ_DATA);
          board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h1048);
          $display ("**** C2H Decsriptor Count = %h\n", P_READ_DATA);
          if (P_READ_DATA == 32'h1) begin
            desc_count = 1;
          end else begin
            #10;
            loop_timeout = loop_timeout + 1;
          end
    end

        if (desc_count != 1) begin
            $display ("---***ERROR*** C2H Descriptor count mismatch,Loop Timeout occured ---\n");
        end
    // Read status of both H2C and C2H engines.
    board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h1040);
    c2h_status = P_READ_DATA;
    if (c2h_status != 32'h6) begin
        $display ("---***ERROR*** C2H status mismatch ---\n");
    end
    board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h0040);
    h2c_status = P_READ_DATA;
    if (h2c_status != 32'h6) begin
        $display ("---***ERROR*** H2C status mismatch ---\n");
    end
    // Disable run bit for H2C and C2H engine
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h1004, 32'h0, 4'hF);
    board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h0004, 32'h0, 4'hF);

    #100;  
   $finish;
end

else if(testname =="dma_test0")
begin

    //------------- This test performs a 32 bit write to a 32 bit Memory space and performs a read back

	//----------------------------------------------------------------------------------------
	// XDMA H2C Test Starts
	//----------------------------------------------------------------------------------------

    $display(" *** XDMA H2C *** \n");

    $display(" **** read Address at BAR0  = %h\n", board.RP.tx_usrapp.BAR_INIT_P_BAR[0][31:0]);
    $display(" **** read Address at BAR1  = %h\n", board.RP.tx_usrapp.BAR_INIT_P_BAR[1][31:0]);

    //-------------- Load DATA in Buffer ----------------------------------------------------
      board.RP.tx_usrapp.TSK_INIT_DATA_H2C;

	//-------------- DMA Engine ID Read -----------------------------------------------------
      board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h00);
      
    //-------------- Descriptor start address x0100 -----------------------------------------
	  board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h4080, 32'h00000100, 4'hF);
      
    //-------------- Start DMA tranfer ------------------------------------------------------
      $display(" **** Start DMA H2C transfer ***\n");

    fork
    //-------------- Writing XDMA CFG Register to start DMA Transfer for H2C ----------------
      board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h0004, 32'hfffe7f, 4'hF);   // Enable H2C DMA

    //-------------- compare H2C data -------------------------------------------------------
      $display("------Compare H2C Data--------\n");
      board.RP.tx_usrapp.COMPARE_DATA_H2C({16'h0,board.RP.tx_usrapp.DMA_BYTE_CNT},1024);    //input payload bytes
    join
    loop_timeout = 0;
    desc_count = 0;
    //For this Example Design there is only one Descriptor used, so Descriptor Count would be 1
      while (desc_count == 0 && loop_timeout <= 10) begin
          board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h0040);
          $display ("**** H2C status = %h\n", P_READ_DATA);
          board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h48);
          $display ("**** H2C Decsriptor Count = %h\n", P_READ_DATA);
          if (P_READ_DATA == 32'h1) begin
            desc_count = 1;
          end else begin
            #10;
            loop_timeout = loop_timeout + 1;
          end

      end
      if (desc_count != 1) begin
          $display ("---***ERROR*** H2C Descriptor count mismatch,Loop Timeout occured ---\n");
      end
      board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h40);
      $display ("H2C DMA_STATUS  = %h\n", P_READ_DATA); // bit2 : Descriptor completed; bit1: Descriptor end; bit0: DMA Stopped
      h2c_status = P_READ_DATA;
      if (h2c_status != 32'h6) begin
        $display ("---***ERROR*** H2C status mismatch ---\n");
      end
	  $display ("bit2 : Descriptor completed; bit1: Descriptor end; bit0: DMA Stopped\n");

    //-------------- XDMA H2C and C2H Transfer separated by 1000ns --------------------------
      #1000;

    //----------------------------------------------------------------------------------------
    // XDMA C2H Test Starts
    //----------------------------------------------------------------------------------------
	
      $display(" *** XDMA C2H *** \n");

      desc_count = 0;
      loop_timeout = 0;
    //-------------- Load DATA in Buffer ----------------------------------------------------
      board.RP.tx_usrapp.TSK_INIT_DATA_C2H;

    //-------------- Descriptor start address x0300 -----------------------------------------
      board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h5080, 32'h00000300, 4'hF);

    // Start DMA transfer
      $display(" **** Start DMA C2H transfer ***\n");

    fork
    //-------------- Writing XDMA CFG Register to start DMA Transfer for C2H ----------------
      board.RP.tx_usrapp.TSK_XDMA_REG_WRITE(16'h1004, 32'hfffe7f, 4'hF);   // Enable C2H DMA

    //compare C2H data
      $display("------Compare C2H Data--------\n");
      board.RP.tx_usrapp.COMPARE_DATA_C2H({16'h0,board.RP.tx_usrapp.DMA_BYTE_CNT}, 1024);
    join

    //For this Example Design there is only one Descriptor used, so Descriptor Count would be 1

      while (desc_count == 0 && loop_timeout <= 10) begin
          board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h1040);
          $display ("**** C2H status = %h\n", P_READ_DATA);
          board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h1048);
          $display ("**** C2H Decsriptor Count = %h\n", P_READ_DATA);
          if (P_READ_DATA == 32'h1) begin
            desc_count = 1;
          end else begin
            #10;
            loop_timeout = loop_timeout + 1;
          end
      end
      if (desc_count != 1) begin
          $display ("---***ERROR*** C2H Descriptor count mismatch,Loop Timeout occured ---\n");
      end
      board.RP.tx_usrapp.TSK_XDMA_REG_READ(16'h1040);
      $display ("C2H DMA_STATUS  = %h\n", P_READ_DATA); // bit2 : Descriptor completed; bit1: Descriptor end; bit0: DMA Stopped
      c2h_status = P_READ_DATA;
      if (c2h_status != 32'h6) begin
        $display ("---***ERROR*** C2H status mismatch ---\n");
      end
      $display ("bit2 : Descriptor completed; bit1: Descriptor end; bit0: DMA Stopped\n");



      #100;

    #1000;

   $finish;
end
else if(testname =="qdma_mm_test0")
begin
   board.RP.tx_usrapp.TSK_QDMA_MM_TEST(0);
   #1000;
   board.RP.tx_usrapp.pfTestIteration = board.RP.tx_usrapp.pfTestIteration + 1;
   #1000;
   //$finish;
end

else if(testname == "qdma_st_test0")
begin
   board.RP.tx_usrapp.TSK_QDMA_ST_TEST(0);
   #1000;
   board.RP.tx_usrapp.pfTestIteration = board.RP.tx_usrapp.pfTestIteration + 1;
   #1000;
   //$finish;
end

else if(testname == "qdma_mm_st_test0")
begin
   board.RP.tx_usrapp.TSK_QDMA_MM_TEST(0);
   board.RP.tx_usrapp.TSK_QDMA_ST_TEST(0);
   #1000;
   board.RP.tx_usrapp.pfTestIteration = board.RP.tx_usrapp.pfTestIteration + 1;
   #1000;
   //$finish;
end

else if(testname == "qdma_mm_st_dsc_byp_test0")
begin
   board.RP.tx_usrapp.TSK_QDMA_MM_TEST(1);
   board.RP.tx_usrapp.TSK_QDMA_ST_TEST(1);
   #1000;
   board.RP.tx_usrapp.pfTestIteration = board.RP.tx_usrapp.pfTestIteration + 1;
   #1000;
   //$finish;
end
else if(testname =="qdma_mm_user_reset_test0")
begin
   board.RP.tx_usrapp.TSK_QDMA_MM_TEST(0);
    #1000;
    board.RP.tx_usrapp.TSK_USR_BAR_REG_WRITE(32'h98, 32'h640001, 4'hF);
    #30000000  
    board.RP.tx_usrapp.TSK_QDMA_MM_TEST(0);

   $finish;
end



else if(testname == "sample_smoke_test0")
begin


    TSK_SIMULATION_TIMEOUT(5050);

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
        $display("[%t] : Test Completed Successfully",$realtime);
    end

    //--------------------------------------------------------------------------
    // Direct Root Port to allow upstream traffic by enabling Mem, I/O and
    // BusMstr in the command register
    //--------------------------------------------------------------------------

    board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b0001);
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);

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
    board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b0001);
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);

  end

  $finish;
end

else if(testname == "pio_writeReadBack_test0")
begin

    // This test performs a 32 bit write to a 32 bit Memory space and performs a read back

    board.RP.tx_usrapp.TSK_SIMULATION_TIMEOUT(10050);

    board.RP.tx_usrapp.TSK_SYSTEM_INITIALIZATION;

    board.RP.tx_usrapp.TSK_BAR_INIT;

//--------------------------------------------------------------------------
// Event : Testing BARs
//--------------------------------------------------------------------------

        for (board.RP.tx_usrapp.ii = 0; board.RP.tx_usrapp.ii <= 6; board.RP.tx_usrapp.ii =
            board.RP.tx_usrapp.ii + 1) begin
            if ((board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[board.RP.tx_usrapp.ii] > 2'b00)) // bar is enabled
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
                               $display("[%t] : Test PASSED --- Write Data: %x successfully received",
                                   $realtime, board.RP.tx_usrapp.P_READ_DATA);
                             end


                          board.RP.tx_usrapp.TSK_TX_CLK_EAT(10);
                          board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;


                        end

                   2'b10 : // MEM 32 SPACE
                        begin


                          $display("[%t] : Transmitting TLPs to Memory 32 Space BAR %x", $realtime,
                              board.RP.tx_usrapp.ii);

                          //--------------------------------------------------------------------------
                          // Event : Memory Write 32 bit TLP
                          //--------------------------------------------------------------------------

                          board.RP.tx_usrapp.DATA_STORE[0] = 8'h04;
                          board.RP.tx_usrapp.DATA_STORE[1] = 8'h03;
                          board.RP.tx_usrapp.DATA_STORE[2] = 8'h02;
                          board.RP.tx_usrapp.DATA_STORE[3] = 8'h01;

                          board.RP.tx_usrapp.TSK_TX_MEMORY_WRITE_32(board.RP.tx_usrapp.DEFAULT_TAG,
                              board.RP.tx_usrapp.DEFAULT_TC, 11'd1,
                              board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0]+8'h10, 4'h0, 4'hF, 1'b0);
                          board.RP.tx_usrapp.TSK_TX_CLK_EAT(100);
                          board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;

                          //--------------------------------------------------------------------------
                          // Event : Memory Read 32 bit TLP
                          //--------------------------------------------------------------------------


                         // make sure P_READ_DATA has known initial value
                         board.RP.tx_usrapp.P_READ_DATA = 32'hffff_ffff;
                          fork
                             board.RP.tx_usrapp.TSK_TX_MEMORY_READ_32(board.RP.tx_usrapp.DEFAULT_TAG,
                                 board.RP.tx_usrapp.DEFAULT_TC, 11'd1,
                                 board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0]+8'h10, 4'h0, 4'hF);
                             board.RP.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                          join
                          if  (board.RP.tx_usrapp.P_READ_DATA != {board.RP.tx_usrapp.DATA_STORE[3],
                             board.RP.tx_usrapp.DATA_STORE[2], board.RP.tx_usrapp.DATA_STORE[1],
                             board.RP.tx_usrapp.DATA_STORE[0] })
                             begin
			       testError=1'b1;
                               $display("[%t] : Test FAILED --- Data Error Mismatch, Write Data %x != Read Data %x",
                                    $realtime, {board.RP.tx_usrapp.DATA_STORE[3],board.RP.tx_usrapp.DATA_STORE[2],
                                     board.RP.tx_usrapp.DATA_STORE[1],board.RP.tx_usrapp.DATA_STORE[0]},
                                     board.RP.tx_usrapp.P_READ_DATA);

                             end
                          else
                             begin
                               $display("[%t] : Test PASSED --- Write Data: %x successfully received",
                                   $realtime, board.RP.tx_usrapp.P_READ_DATA);
                             end


                          board.RP.tx_usrapp.TSK_TX_CLK_EAT(10);
                          board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;

                     end
                2'b11 : // MEM 64 SPACE
                     begin


                          $display("[%t] : Transmitting TLPs to Memory 64 Space BAR %x", $realtime,
                              board.RP.tx_usrapp.ii);


                          //--------------------------------------------------------------------------
                          // Event : Memory Write 64 bit TLP
                          //--------------------------------------------------------------------------

                          board.RP.tx_usrapp.DATA_STORE[0] = 8'h64;
                          board.RP.tx_usrapp.DATA_STORE[1] = 8'h63;
                          board.RP.tx_usrapp.DATA_STORE[2] = 8'h62;
                          board.RP.tx_usrapp.DATA_STORE[3] = 8'h61;

                          board.RP.tx_usrapp.TSK_TX_MEMORY_WRITE_64(board.RP.tx_usrapp.DEFAULT_TAG,
                              board.RP.tx_usrapp.DEFAULT_TC, 10'd1,
                              {board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii+1][31:0],
                              board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0]+8'h20}, 4'h0, 4'hF, 1'b0);
                          board.RP.tx_usrapp.TSK_TX_CLK_EAT(10);
                          board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;

                          //--------------------------------------------------------------------------
                          // Event : Memory Read 64 bit TLP
                          //--------------------------------------------------------------------------


                          // make sure P_READ_DATA has known initial value
                          board.RP.tx_usrapp.P_READ_DATA = 32'hffff_ffff;
                          fork
                             board.RP.tx_usrapp.TSK_TX_MEMORY_READ_64(board.RP.tx_usrapp.DEFAULT_TAG,
                                 board.RP.tx_usrapp.DEFAULT_TC, 10'd1,
                                 {board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii+1][31:0],
                                 board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0]+8'h20}, 4'h0, 4'hF);
                             board.RP.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                          join
                          if  (board.RP.tx_usrapp.P_READ_DATA != {board.RP.tx_usrapp.DATA_STORE[3],
                             board.RP.tx_usrapp.DATA_STORE[2], board.RP.tx_usrapp.DATA_STORE[1],
                             board.RP.tx_usrapp.DATA_STORE[0] })

                             begin
			       testError=1'b1;
                               $display("[%t] : Test FAILED --- Data Error Mismatch, Write Data %x != Read Data %x",
                                   $realtime, {board.RP.tx_usrapp.DATA_STORE[3],
                                   board.RP.tx_usrapp.DATA_STORE[2], board.RP.tx_usrapp.DATA_STORE[1],
                                   board.RP.tx_usrapp.DATA_STORE[0]}, board.RP.tx_usrapp.P_READ_DATA);

                             end
                          else
                             begin
                               $display("[%t] : Test PASSED --- Write Data: %x successfully received",
                                   $realtime, board.RP.tx_usrapp.P_READ_DATA);
                             end


                          board.RP.tx_usrapp.TSK_TX_CLK_EAT(10);
                          board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;


                     end
                default : $display("Error case in usrapp_tx\n");
            endcase

         end
    if(testError==1'b0)
      $display("[%t] : Test Completed Successfully",$realtime);

    $display("[%t] : Finished transmission of PCI-Express TLPs", $realtime);
    $finish;
end
