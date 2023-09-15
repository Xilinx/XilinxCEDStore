//-----------------------------------------------------------------------------
//
// (c) Copyright 2020-2024 Xilinx, Inc. All rights reserved.
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
// Project    : Versal CPM5N BMD Test bench 
// File       : sample_tests.vh
// Version    : 1.3 
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

    board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b1110);
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    
    //BAR Init
    
    board.RP.tx_usrapp.TSK_BAR_INIT;
      
    // PIO Byte enable tests
    
   board.RP.tx_usrapp.TSK_MEM64_WR(32'h10, 32'h12345678,4'hf);
   board.RP.tx_usrapp.TSK_MEM64_RD(32'h10);
   
   board.RP.tx_usrapp.TSK_MEM64_WR(32'h10, 32'hAB000000,4'h8);
   board.RP.tx_usrapp.TSK_MEM64_RD(32'h10);
   
   board.RP.tx_usrapp.TSK_MEM64_WR(32'h10, 32'h00CD0000,4'h4);
   board.RP.tx_usrapp.TSK_MEM64_RD(32'h10);
   
   board.RP.tx_usrapp.TSK_MEM64_WR(32'h10, 32'h00001200,4'h2);
   board.RP.tx_usrapp.TSK_MEM64_RD(32'h10);
   
   board.RP.tx_usrapp.TSK_MEM64_WR(32'h10, 32'h00000034,4'h1);
   board.RP.tx_usrapp.TSK_MEM64_RD(32'h10);
   
    
    // Speed Change
   $display("[%t] : Start Speed Change Tests", $realtime);
    
    //TSK_SPEED_CHANGE(1);
    //TSK_SPEED_CHANGE(3);
    //TSK_SPEED_CHANGE(2);
    //TSK_SPEED_CHANGE(3);
    
    
   
 // BMD Setup for Traffic
  // releasing init_rst_o
  board.RP.tx_usrapp.TSK_MEM64_WR(32'h200, 32'hABCD0000,4'hf);
  board.RP.tx_usrapp.TSK_MEM64_RD(32'h200);

  // TLP Write Address
   board.RP.tx_usrapp.TSK_MEM64_WR(32'h208, 32'hABCDFFF0,4'hf);
   board.RP.tx_usrapp.TSK_MEM64_RD(32'h208);
                      
  //TLP WR Size
   board.RP.tx_usrapp.TSK_MEM64_WR(32'h20c, 32'h00000001,4'hf);//20
   board.RP.tx_usrapp.TSK_MEM64_RD(32'h20c);

  //TLP Write Count 
   board.RP.tx_usrapp.TSK_MEM64_WR(32'h210, 32'h10,4'hf);  //08, 0c
   board.RP.tx_usrapp.TSK_MEM64_RD(32'h210);
                                     
   //TLP Write Pattern
   board.RP.tx_usrapp.TSK_MEM64_WR(32'h214, 32'hDBDBAAAA,4'hf);
   board.RP.tx_usrapp.TSK_MEM64_RD(32'h214);
                          
   //TLP RD Pattern
   board.RP.tx_usrapp.TSK_MEM64_WR(32'h218, 32'h54535251,4'hf);
   board.RP.tx_usrapp.TSK_MEM64_RD(32'h218);

   //TLP RD Address
   board.RP.tx_usrapp.TSK_MEM64_WR(32'h21c, 32'h00000008,4'hf);
   board.RP.tx_usrapp.TSK_MEM64_RD(32'h21c);
                          
   //TLP RD Size
   board.RP.tx_usrapp.TSK_MEM64_WR(32'h220, 32'h00000001,4'hf);//40
   board.RP.tx_usrapp.TSK_MEM64_RD(32'h220);

   //TLP RD Count 
   board.RP.tx_usrapp.TSK_MEM64_WR(32'h224, 32'h10,4'hf);  // 0000000d
   board.RP.tx_usrapp.TSK_MEM64_RD(32'h224);

   //board.RP.tx_usrapp.TSK_MEM64_WR(32'h238, 32'h00,4'hf);  // 0000000d
   board.RP.tx_usrapp.TSK_MEM64_RD(32'h238);
   
   // TLP RD_WR BURST COUNT
   board.RP.tx_usrapp.TSK_MEM64_WR(32'h244, 32'h02040000,4'hf);
   //board.RP.tx_usrapp.TSK_MEM64_WR(32'h244, 32'h00000000,4'hf);
   board.RP.tx_usrapp.TSK_MEM64_RD(32'h244);

   //TLP RD WR Start 32'h000<RD>000<WR>
   board.RP.tx_usrapp.TSK_MEM64_WR(32'h204, 32'h00010001,4'hf);

   board.RP.tx_usrapp.TSK_TX_CLK_EAT(50000);


  $finish;
end

else if(testname == "msgld_msgst_test")
begin

    force board.EP.cdm_msgld_msgst_inst.CDM_adapter_msgst.pld_cmd_req = 1'b0;
    force board.EP.cdm_msgld_msgst_inst.CDM_adapter_msgld.cmd_rd_start = 1'b0;
    force board.EP.msgst_cmd_fill_bram = 1'b0;
    force board.EP.msgld_cmd_fill_bram = 1'b0;
    force board.EP.msgst_payload_fill_bram = 1'b0;

    wait (board.EP.msgst_ld_tg_inst.fabric_rst_n);
    
    @(posedge board.EP.cpm_bot_user_clk) force board.EP.msgst_payload_fill_bram = 1'b1;
	repeat (300) @(posedge board.EP.cpm_bot_user_clk);
    @(posedge board.EP.cpm_bot_user_clk) force board.EP.msgst_payload_fill_bram = 1'b0;
    wait(~(board.EP.msgst_ld_tg_inst.msgst_payload_fill_start));
    
	@(posedge board.EP.cpm_bot_user_clk) force board.EP.msgst_cmd_fill_bram = 1'b1;
	repeat (300) @(posedge board.EP.cpm_bot_user_clk);
    @(posedge board.EP.cpm_bot_user_clk) force board.EP.msgst_cmd_fill_bram = 1'b0;
    
    wait(~(board.EP.msgst_ld_tg_inst.msgst_req_fill_start));
    
    repeat (5) @(posedge board.EP.cpm_bot_user_clk);
    @(posedge board.EP.cpm_bot_user_clk) force board.EP.msgld_cmd_fill_bram = 1'b1;
	repeat (300) @(posedge board.EP.cpm_bot_user_clk);
    @(posedge board.EP.cpm_bot_user_clk) force board.EP.msgld_cmd_fill_bram = 1'b0;
    
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
    board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b1110);
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    
    //BAR Init
    
    board.RP.tx_usrapp.TSK_BAR_INIT;   
    force board.EP.cdm_msgld_msgst_inst.soft_rst_n = 1'b1;
    
	repeat (20) @(posedge board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.cpm_bot_user_clk);
	$display("[%t] : Driving MSGST interface", $realtime);
	
	force board.EP.cdm_msgld_msgst_inst.CDM_adapter_msgst.num_of_reqs = 15'h2;
	force board.EP.cdm_msgld_msgst_inst.pci0_msgst_host_addr_0 = 32'h5000_0000;
	
    force board.EP.cdm_msgld_msgst_inst.CDM_adapter_msgst.pld_cmd_req = 1'b1;    
    
	repeat (10) @(posedge board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.cpm_bot_user_clk);
    force board.EP.cdm_msgld_msgst_inst.CDM_adapter_msgst.pld_cmd_req = 1'b0;
	
	wait(board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.cdm0_msgld_dat_vld);
	repeat (20) @(posedge board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.cpm_bot_user_clk);
	
	$display("[%t] : Driving MSGLD REQ interface", $realtime);
    force board.EP.cdm_msgld_msgst_inst.CDM_adapter_msgld.num_of_reqs = 15'h2;
    
	force board.EP.cdm_msgld_msgst_inst.pci0_msgld_host_addr_0 = 32'h5000_0000;
    
    force board.EP.cdm_msgld_msgst_inst.CDM_adapter_msgld.cmd_rd_start = 1'b1;
	repeat (10) @(posedge board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.cpm_bot_user_clk);

    force board.EP.cdm_msgld_msgst_inst.CDM_adapter_msgld.cmd_rd_start = 1'b0;
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
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h0, 32'h00000001,4'hf);
                  //DCSR - De-assert Initiator Reset
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h0, 32'h00000000,4'hf);


    // Start BMD Traffic Iter 1 /////////////////////

    //WDMATLPS
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h0c, 32'h00000001,4'hf); // 32DW
    //Write DMA TLP Count
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h10, 32'h000C,4'hf);  // 1MB Transfer
    // Read DMA TLP Count
   //   board.RP.tx_usrapp.TSK_MEM64_RD(32'h10);  // 1MB Transfer
    //Write DMA Pattern
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h14, 32'h54535251,4'hf);
    //RDMATLPS
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h20, 32'h00000001,4'hf);
    //RDMATPC
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h24, 32'h01,4'hf);
    //DCSR2- Start Writes
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h4, 32'h00010001,4'hf);

      $display("[%t] : Start BMD Iterations ",$realtime);
//      wait(board.EP.pcie_app_versal_i.BMD_AXIST_1024.BMD_AXIST_EP_1024.mwr_done);
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
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h0, 32'h00000001,4'hf);
                  //DCSR - De-assert Initiator Reset
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h0, 32'h00000000,4'hf);


    // Start BMD Traffic Iter 1 /////////////////////

    //WDMATLPS
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h0c, 32'h00000001,4'hf); // 32DW
    //Write DMA TLP Count
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h10, 32'h000C,4'hf);  // 1MB Transfer
    // Read DMA TLP Count
   //   board.RP.tx_usrapp.TSK_MEM64_RD(32'h10);  // 1MB Transfer
    //Write DMA Pattern
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h14, 32'h54535251,4'hf);
    //RDMATLPS
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h20, 32'h00000001,4'hf);
    //RDMATPC
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h24, 32'h01,4'hf);
    //DCSR2- Start Writes
      board.RP.tx_usrapp.TSK_MEM64_WR(32'h4, 32'h00010001,4'hf);

      $display("[%t] : Start BMD Iterations ",$realtime);
//      wait(board.EP.pcie_app_versal_i.BMD_AXIST_1024.BMD_AXIST_EP_1024.mwr_done);
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
