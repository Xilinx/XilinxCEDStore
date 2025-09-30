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
// Project    : UltraScale+ FPGA PCI Express v4.0 Integrated Block
// File       : sample_tests.vh
// Version    : 1.1 
//-----------------------------------------------------------------------------
//
//------------------------------------------------------------------------------

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

    cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b1110);
    cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    
    //BAR Init
    
    tx_usrapp.TSK_BAR_INIT;
    

    //DCSR - Assert Initiator Reset
      tx_usrapp.TSK_MEM64_WR(32'h0, 32'h00000001,4'hf); 
		  //DCSR - De-assert Initiator Reset
      tx_usrapp.TSK_MEM64_WR(32'h0, 32'h00000000,4'hf);
      
    
    // Start BMD Traffic Iter 1 /////////////////////

    //WDMATLPS
      tx_usrapp.TSK_MEM64_WR(32'h0c, 32'h00000001,4'hf); // 32DW
    //Write DMA TLP Count 
      tx_usrapp.TSK_MEM64_WR(32'h10, 32'h000C,4'hf);  // 1MB Transfer 
    // Read DMA TLP Count
   //   tx_usrapp.TSK_MEM64_RD(32'h10);  // 1MB Transfer 
    //Write DMA Pattern
      tx_usrapp.TSK_MEM64_WR(32'h14, 32'h54535251,4'hf);                                 
    //RDMATLPS
      tx_usrapp.TSK_MEM64_WR(32'h20, 32'h00000001,4'hf);
    //RDMATPC
      tx_usrapp.TSK_MEM64_WR(32'h24, 32'h01,4'hf);  
    //DCSR2- Start Writes
      tx_usrapp.TSK_MEM64_WR(32'h4, 32'h00000001,4'hf);
      
      $display("[%t] : Start BMD Iterations at Gen4",$realtime);
    //  wait(board.EP.pcie_app_uscale_i.BMD_AXIST.BMD_AXIST_EP.mwr_done);
      #50000;
      $display("[%t] : BMD Iteration Complete at Gen4 ",$realtime);
      
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

    com_usrapp.TSK_EXPECT_CPLD(
      3'h0, //traffic_class;
      1'b0, //td;
      1'b0, //ep;
      2'h0, //attr;
      10'h1, //length;
      tx_usrapp.EP_BUS_DEV_FNS, //completer_id;
      3'h0, //completion_status;
      1'b0, //bcm;
      12'h4, //byte_count;
      tx_usrapp.RP_BUS_DEV_FNS, //requester_id;
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

    cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b1110);
    cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);

  end

  $finish;
end

else if(testname == "pio_writeReadBack_test0")
begin

    // This test performs a 32 bit write to a 32 bit Memory space and performs a read back

    tx_usrapp.TSK_SIMULATION_TIMEOUT(10050);

    tx_usrapp.TSK_SYSTEM_INITIALIZATION;

    tx_usrapp.TSK_BAR_INIT;
        
    //--------------------------------------------------------------------------
    // Direct Root Port to allow upstream traffic by enabling Mem, I/O and
    // BusMstr in the command register
    //--------------------------------------------------------------------------

    cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b1110);
    cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);

//--------------------------------------------------------------------------
// Event : Testing BARs
//--------------------------------------------------------------------------

        for (tx_usrapp.ii = 0; tx_usrapp.ii <= 6; tx_usrapp.ii =
            tx_usrapp.ii + 1) begin
            if (tx_usrapp.BAR_INIT_P_BAR_ENABLED[tx_usrapp.ii] > 2'b00) // bar is enabled
               case(tx_usrapp.BAR_INIT_P_BAR_ENABLED[tx_usrapp.ii])
                   2'b01 : // IO SPACE
                        begin

                          $display("[%t] : Transmitting TLPs to IO Space BAR %x", $realtime, tx_usrapp.ii);

                          //--------------------------------------------------------------------------
                          // Event : IO Write bit TLP
                          //--------------------------------------------------------------------------


                          tx_usrapp.TSK_TX_IO_WRITE(tx_usrapp.DEFAULT_TAG,
                             tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii][31:0], 4'hF, 32'hdead_beef);
                             @(posedge pcie_rq_tag_vld);
                             exp_tag = pcie_rq_tag;


                          com_usrapp.TSK_EXPECT_CPL(3'h0, 1'b0, 1'b0, 2'b0,
                             tx_usrapp.EP_BUS_DEV_FNS, 3'h0, 1'b0, 12'h4,
                             tx_usrapp.RP_BUS_DEV_FNS, exp_tag,
                             tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii][31:0], test_vars[0]);

                          tx_usrapp.TSK_TX_CLK_EAT(10);
                          tx_usrapp.DEFAULT_TAG = tx_usrapp.DEFAULT_TAG + 1;

                          //--------------------------------------------------------------------------
                          // Event : IO Read bit TLP
                          //--------------------------------------------------------------------------


                          // make sure P_READ_DATA has known initial value
                          tx_usrapp.P_READ_DATA = 32'hffff_ffff;
                          fork
                             tx_usrapp.TSK_TX_IO_READ(tx_usrapp.DEFAULT_TAG,
                                tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii][31:0], 4'hF);
                             tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                          join
                          if  (tx_usrapp.P_READ_DATA != 32'hdead_beef)
                             begin
                               testError=1'b1;
                               $display("[%t] : Test FAILED --- Data Error Mismatch, Write Data %x != Read Data %x",
                                   $realtime, 32'hdead_beef, tx_usrapp.P_READ_DATA);
                             end
                          else
                             begin
                               $display("[%t] : Test PASSED --- Write Data: %x successfully received",
                                   $realtime, tx_usrapp.P_READ_DATA);
                             end


                          tx_usrapp.TSK_TX_CLK_EAT(10);
                          tx_usrapp.DEFAULT_TAG = tx_usrapp.DEFAULT_TAG + 1;


                        end

                   2'b10 : // MEM 32 SPACE
                        begin


                          //$display("[%t] : Transmitting TLPs to Memory 32 Space BAR %x at address %x", $realtime,
                          //    tx_usrapp.ii, tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii][31:0]+8'h10+(tx_usrapp.ii*8'h20));
                          $display("[%t] : Transmitting TLPs to Memory 32 Space BAR %x", $realtime,
                              tx_usrapp.ii);

                          //--------------------------------------------------------------------------
                          // Event : Memory Write 32 bit TLP
                          //--------------------------------------------------------------------------


                          tx_usrapp.DATA_STORE[0] = {tx_usrapp.ii,4'h4};//8'h04;
                          tx_usrapp.DATA_STORE[1] = {tx_usrapp.ii,4'h3};//8'h03;
                          tx_usrapp.DATA_STORE[2] = {tx_usrapp.ii,4'h2};//8'h02;
                          tx_usrapp.DATA_STORE[3] = {tx_usrapp.ii,4'h1};//8'h01;
                          tx_usrapp.DATA_STORE[4] = {tx_usrapp.ii,4'h8};//8'h14;
                          tx_usrapp.DATA_STORE[5] = {tx_usrapp.ii,4'h7};//8'h13;
                          tx_usrapp.DATA_STORE[6] = {tx_usrapp.ii,4'h6};//8'h12;
                          tx_usrapp.DATA_STORE[7] = {tx_usrapp.ii,4'h5};//8'h11;

                          // Default 1DW PIO
                          tx_usrapp.TSK_TX_MEMORY_WRITE_32(tx_usrapp.DEFAULT_TAG,
                                                                    tx_usrapp.DEFAULT_TC, 11'd1,
                                                                    tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii][31:0]+8'h14+(tx_usrapp.ii*8'h20),
                                                                    4'h0, 4'hF, 1'b0);
                          tx_usrapp.TSK_TX_CLK_EAT(100);
                          tx_usrapp.DEFAULT_TAG = tx_usrapp.DEFAULT_TAG + 1;

                          //--------------------------------------------------------------------------
                          // Event : Memory Read 32 bit TLP
                          //--------------------------------------------------------------------------


                          // make sure P_READ_DATA has known initial value
                          tx_usrapp.P_READ_DATA = 32'hffff_ffff;
                          
                          // Default 1DW PIO
                          fork
                             tx_usrapp.TSK_TX_MEMORY_READ_32(tx_usrapp.DEFAULT_TAG,
                                                                      tx_usrapp.DEFAULT_TC, 11'd1,
                                                                      tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii][31:0]+8'h14+(tx_usrapp.ii*8'h20),
                                                                      4'h0, 4'hF);
                             tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                          join

                          if  (tx_usrapp.P_READ_DATA != {tx_usrapp.DATA_STORE[3],
                                                                  tx_usrapp.DATA_STORE[2],
                                                                  tx_usrapp.DATA_STORE[1],
                                                                  tx_usrapp.DATA_STORE[0] })
                          begin
                             testError=1'b1;
                             $display("[%t] : Test FAILED --- Data Error Mismatch, Write Data %x != Read Data %x",
                                      $realtime, {tx_usrapp.DATA_STORE[3],tx_usrapp.DATA_STORE[2],
                                                  tx_usrapp.DATA_STORE[1],tx_usrapp.DATA_STORE[0]},
                                      tx_usrapp.P_READ_DATA);

                          end
                          else begin
                             $display("[%t] : Test PASSED --- 1DW Write Data: %x successfully received",
                                      $realtime, tx_usrapp.P_READ_DATA);
                          end

                          tx_usrapp.TSK_TX_CLK_EAT(10);
                          tx_usrapp.DEFAULT_TAG = tx_usrapp.DEFAULT_TAG + 1;

                          // Optional 2DW PIO
                          tx_usrapp.DATA_STORE[0] = {tx_usrapp.ii+4'hA,4'h4};//8'h04;
                          tx_usrapp.DATA_STORE[1] = {tx_usrapp.ii+4'hA,4'h3};//8'h03;
                          tx_usrapp.DATA_STORE[2] = {tx_usrapp.ii+4'hA,4'h2};//8'h02;
                          tx_usrapp.DATA_STORE[3] = {tx_usrapp.ii+4'hA,4'h1};//8'h01;
                          tx_usrapp.DATA_STORE[4] = {tx_usrapp.ii+4'hA,4'h8};//8'h14;
                          tx_usrapp.DATA_STORE[5] = {tx_usrapp.ii+4'hA,4'h7};//8'h13;
                          tx_usrapp.DATA_STORE[6] = {tx_usrapp.ii+4'hA,4'h6};//8'h12;
                          tx_usrapp.DATA_STORE[7] = {tx_usrapp.ii+4'hA,4'h5};//8'h11;
                                                    
                          tx_usrapp.TSK_TX_MEMORY_WRITE_32(tx_usrapp.DEFAULT_TAG,
                                                                    tx_usrapp.DEFAULT_TC, 11'd2,
                                                                    tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii][31:0]+8'h14+(tx_usrapp.ii*8'h20),
                                                                    4'hF, 4'hF, 1'b0);
                          tx_usrapp.TSK_TX_CLK_EAT(100);
                          tx_usrapp.DEFAULT_TAG = tx_usrapp.DEFAULT_TAG + 1;                   
                          
 
                          fork
                             tx_usrapp.TSK_TX_MEMORY_READ_32(tx_usrapp.DEFAULT_TAG,
                                                                      tx_usrapp.DEFAULT_TC, 11'd2,
                                                                      tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii][31:0]+8'h14+(tx_usrapp.ii*8'h20),
                                                                      4'hF, 4'hF);
                             tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                          join
                          if  ( (tx_usrapp.P_READ_DATA   != {tx_usrapp.DATA_STORE[7],
                                                                      tx_usrapp.DATA_STORE[6],
                                                                      tx_usrapp.DATA_STORE[5],
                                                                      tx_usrapp.DATA_STORE[4] })
                                 ||
                                (tx_usrapp.P_READ_DATA_2 != {tx_usrapp.DATA_STORE[3],
                                                                      tx_usrapp.DATA_STORE[2],
                                                                      tx_usrapp.DATA_STORE[1],
                                                                      tx_usrapp.DATA_STORE[0] }) )
                          begin
                             testError=1'b1;
                             $display("[%t] : Test FAILED --- Data Error Mismatch, Write Data %x != Read Data %x",
                                       $realtime, {tx_usrapp.DATA_STORE[7],tx_usrapp.DATA_STORE[6],
                                                   tx_usrapp.DATA_STORE[5],tx_usrapp.DATA_STORE[4],
                                                   tx_usrapp.DATA_STORE[3],tx_usrapp.DATA_STORE[2],
                                                   tx_usrapp.DATA_STORE[1],tx_usrapp.DATA_STORE[0]},
                                                   {tx_usrapp.P_READ_DATA,tx_usrapp.P_READ_DATA_2});

                          end
                          else begin
                             $display("[%t] : Test PASSED --- 2DW Write Data: %x successfully received",
                                      $realtime, {tx_usrapp.P_READ_DATA,tx_usrapp.P_READ_DATA_2});
                          end

                          tx_usrapp.TSK_TX_CLK_EAT(10);
                          tx_usrapp.DEFAULT_TAG = tx_usrapp.DEFAULT_TAG + 1;
                          

                     end
                2'b11 : // MEM 64 SPACE
                     begin


                          //$display("[%t] : Transmitting TLPs to Memory 64 Space BAR %x at address %x", $realtime,
                          //    tx_usrapp.ii, tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii][31:0]+8'h20+(tx_usrapp.ii*8'h20));
                          $display("[%t] : Transmitting TLPs to Memory 64 Space BAR %x", $realtime,
                              tx_usrapp.ii);


                          //--------------------------------------------------------------------------
                          // Event : Memory Write 64 bit TLP
                          //--------------------------------------------------------------------------


                          tx_usrapp.DATA_STORE[0] = {tx_usrapp.ii+6,4'h4};//8'h64;
                          tx_usrapp.DATA_STORE[1] = {tx_usrapp.ii+6,4'h3};//8'h63;
                          tx_usrapp.DATA_STORE[2] = {tx_usrapp.ii+6,4'h2};//8'h62;
                          tx_usrapp.DATA_STORE[3] = {tx_usrapp.ii+6,4'h1};//8'h61;
                          tx_usrapp.DATA_STORE[4] = {tx_usrapp.ii+6,4'h8};//8'h74;
                          tx_usrapp.DATA_STORE[5] = {tx_usrapp.ii+6,4'h7};//8'h73;
                          tx_usrapp.DATA_STORE[6] = {tx_usrapp.ii+6,4'h6};//8'h72;
                          tx_usrapp.DATA_STORE[7] = {tx_usrapp.ii+6,4'h5};//8'h71;

                          // Default 1DW PIO
                          tx_usrapp.TSK_TX_MEMORY_WRITE_64(tx_usrapp.DEFAULT_TAG,
                                                                    tx_usrapp.DEFAULT_TC, 10'd1,
                                                                   {tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii+1][31:0],
                                                                    tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii][31:0]+8'h20+(tx_usrapp.ii*8'h20)},
                                                                    4'h0, 4'hF, 1'b0);
                          tx_usrapp.TSK_TX_CLK_EAT(10);
                          tx_usrapp.DEFAULT_TAG = tx_usrapp.DEFAULT_TAG + 1;

                          //--------------------------------------------------------------------------
                          // Event : Memory Read 64 bit TLP
                          //--------------------------------------------------------------------------


                          // make sure P_READ_DATA has known initial value
                          tx_usrapp.P_READ_DATA = 32'hffff_ffff;

                          // Default 1DW PIO
                          fork
                             tx_usrapp.TSK_TX_MEMORY_READ_64(tx_usrapp.DEFAULT_TAG,
                                                                      tx_usrapp.DEFAULT_TC, 10'd1,
                                                                     {tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii+1][31:0],
                                                                      tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii][31:0]+8'h20+(tx_usrapp.ii*8'h20)},
                                                                      4'h0, 4'hF);
                             tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                          join

                          if  (tx_usrapp.P_READ_DATA != {tx_usrapp.DATA_STORE[3],
                                                                  tx_usrapp.DATA_STORE[2],
                                                                  tx_usrapp.DATA_STORE[1],
                                                                  tx_usrapp.DATA_STORE[0] })
                          begin
                              testError=1'b1;
                              $display("[%t] : Test FAILED --- Data Error Mismatch, Write Data %x != Read Data %x",
                                       $realtime, {tx_usrapp.DATA_STORE[3],
                                                   tx_usrapp.DATA_STORE[2], tx_usrapp.DATA_STORE[1],
                                                   tx_usrapp.DATA_STORE[0]},tx_usrapp.P_READ_DATA);

                          end
                          else begin
                              $display("[%t] : Test PASSED --- 1DW Write Data: %x successfully received",
                                       $realtime, tx_usrapp.P_READ_DATA);
                          end

                          tx_usrapp.TSK_TX_CLK_EAT(10);
                          tx_usrapp.DEFAULT_TAG = tx_usrapp.DEFAULT_TAG + 1;

                          // Optional 2DW PIO
                          tx_usrapp.DATA_STORE[0] = {tx_usrapp.ii+4'hA,4'h4};//8'h04;
                          tx_usrapp.DATA_STORE[1] = {tx_usrapp.ii+4'hA,4'h3};//8'h03;
                          tx_usrapp.DATA_STORE[2] = {tx_usrapp.ii+4'hA,4'h2};//8'h02;
                          tx_usrapp.DATA_STORE[3] = {tx_usrapp.ii+4'hA,4'h1};//8'h01;
                          tx_usrapp.DATA_STORE[4] = {tx_usrapp.ii+4'hA,4'h8};//8'h14;
                          tx_usrapp.DATA_STORE[5] = {tx_usrapp.ii+4'hA,4'h7};//8'h13;
                          tx_usrapp.DATA_STORE[6] = {tx_usrapp.ii+4'hA,4'h6};//8'h12;
                          tx_usrapp.DATA_STORE[7] = {tx_usrapp.ii+4'hA,4'h5};//8'h11;
 
                          tx_usrapp.TSK_TX_MEMORY_WRITE_64(tx_usrapp.DEFAULT_TAG,
                                                                    tx_usrapp.DEFAULT_TC, 10'd2,
                                                                   {tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii+1][31:0],
                                                                    tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii][31:0]+8'h24+(tx_usrapp.ii*8'h20)},
                                                                    4'hF, 4'hF, 1'b0);
                          tx_usrapp.TSK_TX_CLK_EAT(10);
                          tx_usrapp.DEFAULT_TAG = tx_usrapp.DEFAULT_TAG + 1;
 
                          fork
                             tx_usrapp.TSK_TX_MEMORY_READ_64(tx_usrapp.DEFAULT_TAG,
                                                                      tx_usrapp.DEFAULT_TC, 10'd2,
                                                                     {tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii+1][31:0],
                                                                      tx_usrapp.BAR_INIT_P_BAR[tx_usrapp.ii][31:0]+8'h24+(tx_usrapp.ii*8'h20)},
                                                                      4'hF, 4'hF);
                             tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                          join

                          if  ( (tx_usrapp.P_READ_DATA   != {tx_usrapp.DATA_STORE[7],
                                                                      tx_usrapp.DATA_STORE[6],
                                                                      tx_usrapp.DATA_STORE[5],
                                                                      tx_usrapp.DATA_STORE[4] })
                                 ||
                                (tx_usrapp.P_READ_DATA_2 != {tx_usrapp.DATA_STORE[3],
                                                                      tx_usrapp.DATA_STORE[2],
                                                                      tx_usrapp.DATA_STORE[1],
                                                                      tx_usrapp.DATA_STORE[0] }) )
                          begin
                             testError=1'b1;
                             $display("[%t] : Test FAILED --- Data Error Mismatch, Write Data %x != Read Data %x",
                                       $realtime, {tx_usrapp.DATA_STORE[7],tx_usrapp.DATA_STORE[6],
                                                   tx_usrapp.DATA_STORE[5],tx_usrapp.DATA_STORE[4],
                                                   tx_usrapp.DATA_STORE[3],tx_usrapp.DATA_STORE[2],
                                                   tx_usrapp.DATA_STORE[1],tx_usrapp.DATA_STORE[0]},
                                                   {tx_usrapp.P_READ_DATA,tx_usrapp.P_READ_DATA_2});

                          end
                          else begin
                             $display("[%t] : Test PASSED --- 2DW Write Data: %x successfully received",
                                      $realtime, {tx_usrapp.P_READ_DATA,tx_usrapp.P_READ_DATA_2});
                          end

                          tx_usrapp.TSK_TX_CLK_EAT(10);
                          tx_usrapp.DEFAULT_TAG = tx_usrapp.DEFAULT_TAG + 1;

                     end
                default : $display("Error case in usrapp_tx\n");
            endcase

         end

    if(testError==1'b0)
    $display("[%t] : Test Completed Successfully",$realtime);

#10000  

    $display("[%t] : Finished transmission of PCI-Express TLPs", $realtime);
  $finish;
end

else if(testname == "bmd_test0")
begin

    // This test performs a 32 bit write to a 32 bit Memory space and performs a read back

    tx_usrapp.TSK_SIMULATION_TIMEOUT(10050);

    tx_usrapp.TSK_SYSTEM_INITIALIZATION;

    tx_usrapp.TSK_BAR_INIT;
        
    //--------------------------------------------------------------------------
    // Direct Root Port to allow upstream traffic by enabling Mem, I/O and
    // BusMstr in the command register
    //--------------------------------------------------------------------------

    cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b1110);
    cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);

//--------------------------------------------------------------------------
// Event : BMD
//--------------------------------------------------------------------------

 $display("AttempT BMD\n");
    //DCSR - Assert Initiator Reset
      tx_usrapp.TSK_MEM64_WR(32'h0, 32'h00000001,4'hf); 
		  //DCSR - De-assert Initiator Reset
      tx_usrapp.TSK_MEM64_WR(32'h0, 32'h00000000,4'hf);
      
    
    // Start BMD Traffic Iter 1 /////////////////////

    //WDMATLPS
      tx_usrapp.TSK_MEM64_WR(32'h0c, 32'h00000001,4'hf); // 32DW
      tx_usrapp.TSK_MEM64_RD(32'h0c);
    //Write DMA TLP Count 
      tx_usrapp.TSK_MEM64_WR(32'h10, 32'h000C,4'hf);  // 1MB Transfer 
      tx_usrapp.TSK_MEM64_RD(32'h10);
    // Read DMA TLP Count
   //   tx_usrapp.TSK_MEM32_RD(32'h10);  // 1MB Transfer 
    //Write DMA Pattern
      tx_usrapp.TSK_MEM64_WR(32'h14, 32'h54535251,4'hf);                                 
      tx_usrapp.TSK_MEM64_RD(32'h14);
    //Read DMA Expected Data Pattern
      tx_usrapp.TSK_MEM64_WR(32'h18, 32'h03020100,4'hf);       
      tx_usrapp.TSK_MEM64_RD(32'h18);
    //RDMATLPS
      tx_usrapp.TSK_MEM64_WR(32'h20, 32'h00000001,4'hf);
      tx_usrapp.TSK_MEM64_RD(32'h20);
    //RDMATPC
      tx_usrapp.TSK_MEM64_WR(32'h24, 32'h000C,4'hf);  
      tx_usrapp.TSK_MEM64_RD(32'h24);
    //DCSR2- Start Writes and Reads
      tx_usrapp.TSK_MEM64_WR(32'h4, 32'h00010001,4'hf);
      
      $display("[%t] : Start BMD Iterations at Gen4",$realtime);
      
     // #1000000
     tx_usrapp.TSK_TX_CLK_EAT(10000);
  
    //  wait(board.EP.pcie_app_uscale_i.BMD_AXIST.BMD_AXIST_EP.mwr_done);
      $display("[%t] : BMD Iteration Complete at Gen4 ",$realtime);
      tx_usrapp.TSK_MEM64_RD(32'h4);

if  (P_READ_DATA[31]) begin
        $display("[%t] : TEST FAILED --- Completion data error", $realtime);
   end
   if (P_READ_DATA[8] == 1'b0) begin
        $display("[%t] : TEST FAILED --- Write failed to complete", $realtime);
   end
   if (P_READ_DATA[24] == 1'b0) begin
        $display("[%t] : TEST FAILED --- Read failed to complete", $realtime);
   end
   if  ((!P_READ_DATA[31]) && P_READ_DATA[8] && P_READ_DATA[24]) begin
        $display("[%t] : TEST Passed Successfully", $realtime);
   end


      $finish;

end
