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
`ifdef CDM_ONLY
else if(testname == "st2m_m2st_m2m_test")
begin  
   
	repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);

	$display("[%t] : Loading CMD BRAMs for ST2M/M2ST interface on top FSR ", $realtime);
	
	//st2m_ctrl_reg_2 register details
	//st2m_num_of_CMD 		= st2m_ctrl_reg_2[6:0]
	//st2m_cmd_fill_bram 	= st2m_ctrl_reg_2[7]
	
	$display("[%t] : Loading ST2M CMD BRAMs on Top FSR -Start ",$realtime);	
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `ST2M_M2ST_M2M_top.st2m_ctrl_reg_2 = 32'h0;
	repeat (5) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `ST2M_M2ST_M2M_top.st2m_ctrl_reg_2 = 32'h86;
	repeat (300) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `ST2M_M2ST_M2M_top.st2m_ctrl_reg_2 = 32'h06;
	
	wait(`cDM_PL_TOP.st2m_m2st_m2m_tg_top_inst.num_st2m_cmd_loaded == `cDM_PL_TOP.st2m_top_num_of_CMD); 
	
	$display("[%t] : Loading ST2M CMD BRAMs on Top FSR -Finish ",$realtime);

	//m2st_ctrl_reg_1 register details
	//m2st_num_of_CMD 		= m2st_ctrl_reg_1[6:0]
	//m2st_cmd_fill_bram 	= m2st_ctrl_reg_1[7]
	
	$display("[%t] : Loading M2ST CMD BRAMs on Top FSR -Start ",$realtime);	
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `ST2M_M2ST_M2M_top.m2st_ctrl_reg_1 = 32'h0;
	repeat (5) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `ST2M_M2ST_M2M_top.m2st_ctrl_reg_1 = 32'h86;
	repeat (300) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `ST2M_M2ST_M2M_top.m2st_ctrl_reg_1 = 32'h06;
	
	wait(`cDM_PL_TOP.st2m_m2st_m2m_tg_top_inst.num_m2st_cmd_loaded == `cDM_PL_TOP.m2st_top_num_of_CMD); 
	
	$display("[%t] : Loading M2ST CMD BRAMs on Top FSR -Finish ",$realtime);
	
	$display("[%t] : Loading ST2M CMD BRAMs on Bot FSR -Start ",$realtime);	
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `ST2M_M2ST_M2M_bot.st2m_ctrl_reg_2 = 32'h0;
	repeat (5) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `ST2M_M2ST_M2M_bot.st2m_ctrl_reg_2 = 32'h86;
	repeat (300) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `ST2M_M2ST_M2M_bot.st2m_ctrl_reg_2 = 32'h06;
	
	wait(`cDM_PL_TOP.st2m_m2st_m2m_tg_bot_inst.num_st2m_cmd_loaded == `cDM_PL_TOP.st2m_bot_num_of_CMD);  
	
	$display("[%t] : Loading ST2M CMD BRAMs on Bot FSR -Finish ",$realtime);
	
	$display("[%t] : Loading M2ST CMD BRAMs on Bot FSR -Start ",$realtime);	
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `ST2M_M2ST_M2M_bot.m2st_ctrl_reg_1 = 32'h0;
	repeat (5) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `ST2M_M2ST_M2M_bot.m2st_ctrl_reg_1 = 32'h86;
	repeat (300) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `ST2M_M2ST_M2M_bot.m2st_ctrl_reg_1 = 32'h06;
	
	wait(`cDM_PL_TOP.st2m_m2st_m2m_tg_bot_inst.num_m2st_cmd_loaded == `cDM_PL_TOP.m2st_bot_num_of_CMD); 
	
	$display("[%t] : Loading M2ST CMD BRAMs on Bot FSR -Finish ",$realtime);
	
	TSK_SIMULATION_TIMEOUT(5050);
	//System Initialization
    TSK_SYSTEM_INITIALIZATION;

    //--------------------------------------------------------------------------
    // Direct Root Port to allow upstream traffic by enabling Mem, I/O and
    // BusMstr in the command register
    //--------------------------------------------------------------------------

    board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b1110);
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    
    //BAR Init
    
    board.RP.tx_usrapp.TSK_BAR_INIT;   
	  
    force `ST2M_M2ST_M2M_top.soft_rst_n = 1'b1;    
    
	repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	
    $display("[%t] : Initiating ST2M transfer from Top FSR", $realtime);
	force `ST2M_M2ST_M2M_top.st2m_ctrl_reg = 32'h6;
	repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
    force `ST2M_M2ST_M2M_top.st2m_ctrl_reg = 32'h7;
	
	repeat (300) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	$display("[%t] : Initiating M2ST transfer from Top FSR", $realtime);
    force `ST2M_M2ST_M2M_top.m2st_ctrl_reg = 32'h6;
	repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
    force `ST2M_M2ST_M2M_top.m2st_ctrl_reg = 32'h7;
	
	repeat (1000) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	force `ST2M_M2ST_M2M_bot.soft_rst_n = 1'b1;
	
	$display("[%t] : Initiating ST2M transfer from Bot FSR", $realtime);
    force `ST2M_M2ST_M2M_bot.st2m_ctrl_reg = 32'h6;
	repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
    force `ST2M_M2ST_M2M_bot.st2m_ctrl_reg = 32'h7;
	
	$display("[%t] : Initiating M2ST transfer from Bot FSR", $realtime);
    force `ST2M_M2ST_M2M_bot.m2st_ctrl_reg = 32'h6;
	repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
    force `ST2M_M2ST_M2M_bot.m2st_ctrl_reg = 32'h7;
	
end

else if (testname == "verify_msgld_msgst_updates")
begin

	wait (`cDM_PL_TOP.msgst_ld_tg_top_inst.fabric_rst_n);
	$display("[%t] : NOTE: Do not load MSGST/MSGLD CMD BRAMs at the same time ",$realtime);
    $display("[%t] : Loading MSGST CMD BRAMs-Start ",$realtime);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.msgst_ld_tg_top_inst.msgstld_pld_length = 9'h20;
	repeat (5) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h106;
	
	wait(`cDM_PL_TOP.msgst_ld_tg_top_inst.num_msgst_cmd_loaded == `MSGSTLD_top.msgst_num_of_CMD);
	$display("[%t] : Loading MSGST CMD BRAMs-Finished ",$realtime);
	
	
	 $display("[%t] : Loading MSGLD CMD BRAMs-Start ",$realtime);

	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h10607;
	wait(`cDM_PL_TOP.msgst_ld_tg_top_inst.num_msgld_cmd_loaded == `MSGSTLD_top.msgld_num_of_CMD);
	repeat (5) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h607;
	
	wait(`cDM_PL_TOP.msgst_ld_tg_top_inst.num_msgld_cmd_loaded == `MSGSTLD_top.msgld_num_of_CMD);
	
	$display("[%t] : Loading MSGLD CMD BRAMs-Finished ",$realtime);
    TSK_SIMULATION_TIMEOUT(5050);
	
	$display("[%t] : Test -MSGST/MSGLD updates ",$realtime);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;		
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgst.num_of_reqs = 15'd1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b1;	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgst.pld_cmd_req = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgst.pld_cmd_req = 1'b1; 
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b0;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);	
		
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b0;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgld.num_of_reqs = 15'd1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgld.cmd_rd_start = 1'b0; 
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgld.cmd_rd_start = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	
	repeat (5000) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b0;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b0;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b1;	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgst.num_of_reqs = 15'd1000;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgst.pld_cmd_req = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgst.pld_cmd_req = 1'b1; 
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b0;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);	
		
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b0;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgld.num_of_reqs = 15'd1000;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgld.cmd_rd_start = 1'b0; 
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgld.cmd_rd_start = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	
	repeat (5000) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b0;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b0;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	$finish;

end

else if(testname == "msgld_msgst_test_top")
begin		
	
    wait (`cDM_PL_TOP.msgst_ld_tg_top_inst.fabric_rst_n);
	$display("[%t] : NOTE: Do not load MSGST/MSGLD CMD BRAMs at the same time ",$realtime);
	
	$display("#msg_ctrl_reg_1:								");
	$display("#start_pkt_count 		= msg_ctrl_reg_1[0]     ");
	$display("#msgst_num_of_CMD 	= msg_ctrl_reg_1[7:1]   ");
	$display("#msgst_cmd_fill_bram 	= msg_ctrl_reg_1[8]     ");
	$display("#msgld_num_of_CMD 	= msg_ctrl_reg_1[15:9]  ");
	$display("#msgld_cmd_fill_bram 	= msg_ctrl_reg_1[16]    ");
	
    $display("[%t] : Loading MSGST CMD BRAMs-Start ",$realtime);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h0;
	repeat (5) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h106;
	
	wait(`cDM_PL_TOP.msgst_ld_tg_top_inst.num_msgst_cmd_loaded == `MSGSTLD_top.msgst_num_of_CMD);
	$display("[%t] : Loading MSGST CMD BRAMs-Finished ",$realtime);	
	
	$display("[%t] : Loading MSGLD CMD BRAMs-Start ",$realtime);

	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h10607;
	wait(`cDM_PL_TOP.msgst_ld_tg_top_inst.num_msgld_cmd_loaded == `MSGSTLD_top.msgld_num_of_CMD);
	repeat (5) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h607;
	
	wait(`cDM_PL_TOP.msgst_ld_tg_top_inst.num_msgld_cmd_loaded == `MSGSTLD_top.msgld_num_of_CMD);	
	
	$display("[%t] : Loading MSGLD CMD BRAMs-Finished ",$realtime);
    TSK_SIMULATION_TIMEOUT(5050);	
	
    //System Initialization
    TSK_SYSTEM_INITIALIZATION;
    
    $display("[%t] : Expected Device/Vendor ID = %x", $realtime, DEV_VEN_ID); 
    
    //------------------------------/--------------------------------------------
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
    force `MSGSTLD_top.soft_rst_n = 1'b1;
    
	repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	$display("==============MSGST-MSGLD Test variables =====================");
	$display("msgst_only_test = %d",msgst_only_test);	
	$display("msgld_only_test = %d",msgld_only_test);
	$display("msgst_msgld_test_seqential = %d",msgst_msgld_test_seqential);
	$display("msgst_msgld_test_simultaneous = %d",msgst_msgld_test_simultaneous);
	
	$display("msgst_infinite_pkt_run_start = %d",msgst_infinite_pkt_run_start);
	$display("msgst_use_same_cmd = %d",msgst_use_same_cmd);
	$display("msgst_num_of_req = %d",msgst_num_of_req);
	
	$display("msgld_use_same_cmd = %d",msgld_use_same_cmd);
	$display("msgld_infinite_pkt_run_start = %d",msgld_infinite_pkt_run_start);
	$display("msgld_num_of_req = %d",msgld_num_of_req);
	$display("msgst_throttle = %d",msgst_throttle);
	$display("msgld_throttle = %d",msgld_throttle);
	$display("msgld_dat_throttle = %d",msgld_dat_throttle);
	
	$display("===============================================================");
	
	$display( "====pci0_host_ctrl_reg - Register details===="     );
	$display( "pci0_host_ctrl_reg[0] = Send packets to PCIe host" );
	$display( "Setting pci0_host_ctrl_reg to send packets to host" );
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.pci0_host_ctrl_reg[0] = 32'h1;
	
	$display("[%t] : msgst_use_same_cmd = %d, msgst_infinite_pkt_run_start = %d, msgld_use_same_cmd = %d, msgld_infinite_pkt_run_start = %d ",$realtime,msgst_use_same_cmd,msgst_infinite_pkt_run_start,msgld_use_same_cmd,msgld_infinite_pkt_run_start);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = msgst_use_same_cmd;		
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = msgst_infinite_pkt_run_start;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = msgld_use_same_cmd;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = msgld_infinite_pkt_run_start;
	
	force `MSGSTLD_top.pci0_msgst_host_addr_0 = 32'h5000_0000;	
	force `MSGSTLD_top.pci0_msgld_host_addr_0 = 32'h5000_0000; 	
	force `MSGSTLD_top.CDM_throttle_inst.back_pres = {msgld_dat_throttle,msgld_throttle,msgst_throttle};
	
	
	$display("====msg_ctrl_reg_0 - Register details===="    );
	$display("MSGST -- pld_cmd_req 	= msg_ctrl_reg_1[0]"    );
	$display("msgst_num_of_req 		= msg_ctrl_reg_1[15:1]" );
	$display("MSGLD -- cmd_rd_start = msg_ctrl_reg_1[16]"   );
	$display("msgld_num_of_req 		= msg_ctrl_reg_1[31:17]");
	$display("NOTE: pld_cmd_req and cmd_rd_start inputs need to have a positive edge to send MSGST/MSGLD packets" );	
	
	if(msgst_only_test || msgst_msgld_test_seqential) begin
		
		$display("[%t] : Driving MSGST interface", $realtime);	
		
		$display("[%t] : Initializing the register - msg_ctrl_reg_0",$realtime);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
		
		repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);		
		$display("[%t] : Writing pld_cmd_req=1,msgst_num_of_req = %d",$realtime,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b1};	
		wait(`cDM_PL_TOP.design_ep_wrapper_i.design_1_i.psx_wizard_0.cdm1_msgld_dat_vld);
		repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
		
		$display("[%t] : Writing pld_cmd_req=0,msgst_num_of_req = %d",$realtime,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
		
	end
	
	if(msgld_only_test || msgst_msgld_test_seqential) begin
	
		$display("[%t] : Driving MSGLD REQ interface", $realtime);		   
		
		$display("[%t] : Initializing the register - msg_ctrl_reg_0",$realtime);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
		repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);		
		
		$display("[%t] : Writing cmd_rd_start=1,msgld_num_of_req=%d, pld_cmd_req=0,msgst_num_of_req = %d",$realtime, msgld_num_of_req,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b1,msgst_num_of_req,1'b0};	
		wait(`cDM_PL_TOP.design_ep_wrapper_i.design_1_i.psx_wizard_0.cdm1_msgld_dat_vld);
		repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
		
		$display("[%t] : Writing cmd_rd_start=0,msgld_num_of_req=%d, pld_cmd_req=0,msgst_num_of_req = %d",$realtime, msgld_num_of_req,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
	
	end
	
	if(msgst_msgld_test_simultaneous) begin
		$display("[%t] : Driving MSGLD/MSGST REQ interface", $realtime);
		force `MSGSTLD_top.pci0_msgst_host_addr_0 = 32'h5000_0000;
		force `MSGSTLD_top.pci0_msgld_host_addr_0 = 32'h5000_0000;   
		
		$display("[%t] : Initializing the register - msg_ctrl_reg_0",$realtime);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
		repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
		
		$display("[%t] : Writing cmd_rd_start=1,msgld_num_of_req=%d, pld_cmd_req=1,msgst_num_of_req = %d",$realtime, msgld_num_of_req,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b1,msgst_num_of_req,1'b1};
		
		wait(`cDM_PL_TOP.design_ep_wrapper_i.design_1_i.psx_wizard_0.cdm1_msgld_dat_vld);
		repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
		
		$display("[%t] : Writing cmd_rd_start=0,msgld_num_of_req=%d, pld_cmd_req=0,msgst_num_of_req = %d",$realtime, msgld_num_of_req,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
		
	end
	
	wait(`MSGSTLD_top.msgld_rsp_status[0]);
	#10000000;
	$display("[%t] : msgst_req_pkt_sent = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgst_req_pkt_sent);
	$display("[%t] : msgld_req_pkt_sent = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgld_req_pkt_sent);
	$display("[%t] : msgst_rsp_pkt_rcvd = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgst_rsp_pkt_rcvd);
	$display("[%t] : msgld_rsp_pkt_rcvd = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgld_rsp_pkt_rcvd);
	$display("[%t] : msgst_pass_count = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgst_pass_cnt[31:0]);
	$display("[%t] : msgld_pass_count = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgld_pass_cnt[31:0]);
	$display("[%t] : msgst_fail_count = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgst_fail_cnt[31:0]);
	$display("[%t] : msgld_fail_count = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgld_fail_cnt[31:0]);	
end

else if(testname == "msgld_msgst_test_bot")
begin		
	
    wait (`cDM_PL_TOP.msgst_ld_tg_top_inst.fabric_rst_n);
	$display("[%t] : NOTE: Do not load MSGST/MSGLD CMD BRAMs at the same time ",$realtime);
	
	$display("#msg_ctrl_reg_1:								");
	$display("#start_pkt_count 		= msg_ctrl_reg_1[0]     ");
	$display("#msgst_num_of_CMD 	= msg_ctrl_reg_1[7:1]   ");
	$display("#msgst_cmd_fill_bram 	= msg_ctrl_reg_1[8]     ");
	$display("#msgld_num_of_CMD 	= msg_ctrl_reg_1[15:9]  ");
	$display("#msgld_cmd_fill_bram 	= msg_ctrl_reg_1[16]    ");
	
    $display("[%t] : Loading MSGST CMD BRAMs-Start ",$realtime);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msg_ctrl_reg_1 = 32'h0;
	repeat (5) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msg_ctrl_reg_1 = 32'h106;
	
	wait(`cDM_PL_TOP.msgst_ld_tg_top_inst.num_msgst_cmd_loaded == `MSGSTLD_bot.msgst_num_of_CMD);
	$display("[%t] : Loading MSGST CMD BRAMs-Finished ",$realtime);	
	
	$display("[%t] : Loading MSGLD CMD BRAMs-Start ",$realtime);

	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msg_ctrl_reg_1 = 32'h10607;
	wait(`cDM_PL_TOP.msgst_ld_tg_top_inst.num_msgld_cmd_loaded == `MSGSTLD_bot.msgld_num_of_CMD);
	repeat (5) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msg_ctrl_reg_1 = 32'h607;
	
	wait(`cDM_PL_TOP.msgst_ld_tg_top_inst.num_msgld_cmd_loaded == `MSGSTLD_bot.msgld_num_of_CMD);	
	
	$display("[%t] : Loading MSGLD CMD BRAMs-Finished ",$realtime);
    TSK_SIMULATION_TIMEOUT(5050);	
	
    //System Initialization
    TSK_SYSTEM_INITIALIZATION;
    
    $display("[%t] : Expected Device/Vendor ID = %x", $realtime, DEV_VEN_ID); 
    
    //------------------------------/--------------------------------------------
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
    force `MSGSTLD_bot.soft_rst_n = 1'b1;
    
	repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	$display("==============MSGST-MSGLD Test variables =====================");
	$display("msgst_only_test = %d",msgst_only_test);	
	$display("msgld_only_test = %d",msgld_only_test);
	$display("msgst_msgld_test_seqential = %d",msgst_msgld_test_seqential);
	$display("msgst_msgld_test_simultaneous = %d",msgst_msgld_test_simultaneous);
	
	$display("msgst_infinite_pkt_run_start = %d",msgst_infinite_pkt_run_start);
	$display("msgst_use_same_cmd = %d",msgst_use_same_cmd);
	$display("msgst_num_of_req = %d",msgst_num_of_req);
	
	$display("msgld_use_same_cmd = %d",msgld_use_same_cmd);
	$display("msgld_infinite_pkt_run_start = %d",msgld_infinite_pkt_run_start);
	$display("msgld_num_of_req = %d",msgld_num_of_req);
	$display("msgst_throttle = %d",msgst_throttle);
	$display("msgld_throttle = %d",msgld_throttle);
	$display("msgld_dat_throttle = %d",msgld_dat_throttle);
	
	$display("===============================================================");
	
	$display( "====pci0_host_ctrl_reg - Register details===="     );
	$display( "pci0_host_ctrl_reg[0] = Send packets to PCIe host" );
	$display( "Setting pci0_host_ctrl_reg to send packets to host" );
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.pci0_host_ctrl_reg[0] = 32'h1;
	
	$display("[%t] : msgst_use_same_cmd = %d, msgst_infinite_pkt_run_start = %d, msgld_use_same_cmd = %d, msgld_infinite_pkt_run_start = %d ",$realtime,msgst_use_same_cmd,msgst_infinite_pkt_run_start,msgld_use_same_cmd,msgld_infinite_pkt_run_start);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msgst_use_same_cmd = msgst_use_same_cmd;		
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msgst_infinite_pkt_run_start = msgst_infinite_pkt_run_start;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msgld_use_same_cmd = msgld_use_same_cmd;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msgld_infinite_pkt_run_start = msgld_infinite_pkt_run_start;
	
	force `MSGSTLD_bot.pci0_msgst_host_addr_0 = 32'h5000_0000;	
	force `MSGSTLD_bot.pci0_msgld_host_addr_0 = 32'h5000_0000; 	
	force `MSGSTLD_bot.CDM_throttle_inst.back_pres = {msgld_dat_throttle,msgld_throttle,msgst_throttle};
	
	
	$display("====msg_ctrl_reg_0 - Register details===="    );
	$display("MSGST -- pld_cmd_req 	= msg_ctrl_reg_1[0]"    );
	$display("msgst_num_of_req 		= msg_ctrl_reg_1[15:1]" );
	$display("MSGLD -- cmd_rd_start = msg_ctrl_reg_1[16]"   );
	$display("msgld_num_of_req 		= msg_ctrl_reg_1[31:17]");
	$display("NOTE: pld_cmd_req and cmd_rd_start inputs need to have a positive edge to send MSGST/MSGLD packets" );	
	
	if(msgst_only_test || msgst_msgld_test_seqential) begin
		
		$display("[%t] : Driving MSGST interface", $realtime);	
		
		$display("[%t] : Initializing the register - msg_ctrl_reg_0",$realtime);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
		
		repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);		
		$display("[%t] : Writing pld_cmd_req=1,msgst_num_of_req = %d",$realtime,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b1};	
		wait(`cDM_PL_TOP.design_ep_wrapper_i.design_1_i.psx_wizard_0.cdm1_msgld_dat_vld);
		repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
		
		$display("[%t] : Writing pld_cmd_req=0,msgst_num_of_req = %d",$realtime,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
		
	end
	
	if(msgld_only_test || msgst_msgld_test_seqential) begin
	
		$display("[%t] : Driving MSGLD REQ interface", $realtime);		   
		
		$display("[%t] : Initializing the register - msg_ctrl_reg_0",$realtime);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
		repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);		
		
		$display("[%t] : Writing cmd_rd_start=1,msgld_num_of_req=%d, pld_cmd_req=0,msgst_num_of_req = %d",$realtime, msgld_num_of_req,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msg_ctrl_reg_0 = {msgld_num_of_req,1'b1,msgst_num_of_req,1'b0};	
		wait(`cDM_PL_TOP.design_ep_wrapper_i.design_1_i.psx_wizard_0.cdm1_msgld_dat_vld);
		repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
		
		$display("[%t] : Writing cmd_rd_start=0,msgld_num_of_req=%d, pld_cmd_req=0,msgst_num_of_req = %d",$realtime, msgld_num_of_req,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
	
	end
	
	if(msgst_msgld_test_simultaneous) begin
		$display("[%t] : Driving MSGLD/MSGST REQ interface", $realtime);
		force `MSGSTLD_bot.pci0_msgst_host_addr_0 = 32'h5000_0000;
		force `MSGSTLD_bot.pci0_msgld_host_addr_0 = 32'h5000_0000;   
		
		$display("[%t] : Initializing the register - msg_ctrl_reg_0",$realtime);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
		repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
		
		$display("[%t] : Writing cmd_rd_start=1,msgld_num_of_req=%d, pld_cmd_req=1,msgst_num_of_req = %d",$realtime, msgld_num_of_req,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msg_ctrl_reg_0 = {msgld_num_of_req,1'b1,msgst_num_of_req,1'b1};
		
		wait(`cDM_PL_TOP.design_ep_wrapper_i.design_1_i.psx_wizard_0.cdm1_msgld_dat_vld);
		repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
		
		$display("[%t] : Writing cmd_rd_start=0,msgld_num_of_req=%d, pld_cmd_req=0,msgst_num_of_req = %d",$realtime, msgld_num_of_req,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_bot.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
		
	end
	
	wait(`MSGSTLD_bot.msgld_rsp_status[0]);
	#10000000;
	$display("[%t] : msgst_req_pkt_sent = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgst_req_pkt_sent);
	$display("[%t] : msgld_req_pkt_sent = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgld_req_pkt_sent);
	$display("[%t] : msgst_rsp_pkt_rcvd = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgst_rsp_pkt_rcvd);
	$display("[%t] : msgld_rsp_pkt_rcvd = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgld_rsp_pkt_rcvd);
	$display("[%t] : msgst_pass_count = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgst_pass_cnt[31:0]);
	$display("[%t] : msgld_pass_count = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgld_pass_cnt[31:0]);
	$display("[%t] : msgst_fail_count = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgst_fail_cnt[31:0]);
	$display("[%t] : msgld_fail_count = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgld_fail_cnt[31:0]);	
end
`else
else if(testname == "msgld_msgst_test")
begin		
	
    wait (`cDM_PL_TOP.msgst_ld_tg_inst.fabric_rst_n);
	$display("[%t] : NOTE: Do not load MSGST/MSGLD CMD BRAMs at the same time ",$realtime);
	
	$display("#msg_ctrl_reg_1:								");
	$display("#start_pkt_count 		= msg_ctrl_reg_1[0]     ");
	$display("#msgst_num_of_CMD 	= msg_ctrl_reg_1[7:1]   ");
	$display("#msgst_cmd_fill_bram 	= msg_ctrl_reg_1[8]     ");
	$display("#msgld_num_of_CMD 	= msg_ctrl_reg_1[15:9]  ");
	$display("#msgld_cmd_fill_bram 	= msg_ctrl_reg_1[16]    ");
	
    $display("[%t] : Loading MSGST CMD BRAMs-Start ",$realtime);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h0;
	repeat (5) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h106;
	
	wait(`cDM_PL_TOP.msgst_ld_tg_inst.num_msgst_cmd_loaded == `MSGSTLD_top.msgst_num_of_CMD);
	$display("[%t] : Loading MSGST CMD BRAMs-Finished ",$realtime);	
	
	$display("[%t] : Loading MSGLD CMD BRAMs-Start ",$realtime);

	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h10607;
	wait(`cDM_PL_TOP.msgst_ld_tg_inst.num_msgld_cmd_loaded == `MSGSTLD_top.msgld_num_of_CMD);
	repeat (5) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h607;
	
	wait(`cDM_PL_TOP.msgst_ld_tg_inst.num_msgld_cmd_loaded == `MSGSTLD_top.msgld_num_of_CMD);	
	
	$display("[%t] : Loading MSGLD CMD BRAMs-Finished ",$realtime);
    TSK_SIMULATION_TIMEOUT(5050);	
	
    //System Initialization
    TSK_SYSTEM_INITIALIZATION;
    
    $display("[%t] : Expected Device/Vendor ID = %x", $realtime, DEV_VEN_ID); 
    
    //------------------------------/--------------------------------------------
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
    force `MSGSTLD_top.soft_rst_n = 1'b1;
    
	repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	$display("==============MSGST-MSGLD Test variables =====================");
	$display("msgst_only_test = %d",msgst_only_test);	
	$display("msgld_only_test = %d",msgld_only_test);
	$display("msgst_msgld_test_seqential = %d",msgst_msgld_test_seqential);
	$display("msgst_msgld_test_simultaneous = %d",msgst_msgld_test_simultaneous);
	
	$display("msgst_infinite_pkt_run_start = %d",msgst_infinite_pkt_run_start);
	$display("msgst_use_same_cmd = %d",msgst_use_same_cmd);
	$display("msgst_num_of_req = %d",msgst_num_of_req);
	
	$display("msgld_use_same_cmd = %d",msgld_use_same_cmd);
	$display("msgld_infinite_pkt_run_start = %d",msgld_infinite_pkt_run_start);
	$display("msgld_num_of_req = %d",msgld_num_of_req);
	$display("msgst_throttle = %d",msgst_throttle);
	$display("msgld_throttle = %d",msgld_throttle);
	$display("msgld_dat_throttle = %d",msgld_dat_throttle);
	
	$display("===============================================================");
	
	$display( "====pci0_host_ctrl_reg - Register details===="     );
	$display( "pci0_host_ctrl_reg[0] = Send packets to PCIe host" );
	$display( "Setting pci0_host_ctrl_reg to send packets to host" );
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.pci0_host_ctrl_reg[0] = 32'h1;
	
	$display("[%t] : msgst_use_same_cmd = %d, msgst_infinite_pkt_run_start = %d, msgld_use_same_cmd = %d, msgld_infinite_pkt_run_start = %d ",$realtime,msgst_use_same_cmd,msgst_infinite_pkt_run_start,msgld_use_same_cmd,msgld_infinite_pkt_run_start);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = msgst_use_same_cmd;		
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = msgst_infinite_pkt_run_start;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = msgld_use_same_cmd;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = msgld_infinite_pkt_run_start;
	
	force `MSGSTLD_top.pci0_msgst_host_addr_0 = 32'h5000_0000;	
	force `MSGSTLD_top.pci0_msgld_host_addr_0 = 32'h5000_0000; 	
	force `MSGSTLD_top.CDM_throttle_inst.back_pres = {msgld_dat_throttle,msgld_throttle,msgst_throttle};
	
	
	$display("====msg_ctrl_reg_0 - Register details===="    );
	$display("MSGST -- pld_cmd_req 	= msg_ctrl_reg_1[0]"    );
	$display("msgst_num_of_req 		= msg_ctrl_reg_1[15:1]" );
	$display("MSGLD -- cmd_rd_start = msg_ctrl_reg_1[16]"   );
	$display("msgld_num_of_req 		= msg_ctrl_reg_1[31:17]");
	$display("NOTE: pld_cmd_req and cmd_rd_start inputs need to have a positive edge to send MSGST/MSGLD packets" );	
	
	if(msgst_only_test || msgst_msgld_test_seqential) begin
		
		$display("[%t] : Driving MSGST interface", $realtime);	
		
		$display("[%t] : Initializing the register - msg_ctrl_reg_0",$realtime);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
		
		repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);		
		$display("[%t] : Writing pld_cmd_req=1,msgst_num_of_req = %d",$realtime,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b1};	
		wait(`cDM_PL_TOP.design_ep_wrapper_i.design_1_i.psx_wizard_0.cdm1_msgld_dat_vld);
		repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
		
		$display("[%t] : Writing pld_cmd_req=0,msgst_num_of_req = %d",$realtime,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
		
	end
	
	if(msgld_only_test || msgst_msgld_test_seqential) begin
	
		$display("[%t] : Driving MSGLD REQ interface", $realtime);		   
		
		$display("[%t] : Initializing the register - msg_ctrl_reg_0",$realtime);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
		repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);		
		
		$display("[%t] : Writing cmd_rd_start=1,msgld_num_of_req=%d, pld_cmd_req=0,msgst_num_of_req = %d",$realtime, msgld_num_of_req,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b1,msgst_num_of_req,1'b0};	
		wait(`cDM_PL_TOP.design_ep_wrapper_i.design_1_i.psx_wizard_0.cdm1_msgld_dat_vld);
		repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
		
		$display("[%t] : Writing cmd_rd_start=0,msgld_num_of_req=%d, pld_cmd_req=0,msgst_num_of_req = %d",$realtime, msgld_num_of_req,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
	
	end
	
	if(msgst_msgld_test_simultaneous) begin
		$display("[%t] : Driving MSGLD/MSGST REQ interface", $realtime);
		force `MSGSTLD_top.pci0_msgst_host_addr_0 = 32'h5000_0000;
		force `MSGSTLD_top.pci0_msgld_host_addr_0 = 32'h5000_0000;   
		
		$display("[%t] : Initializing the register - msg_ctrl_reg_0",$realtime);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
		repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
		
		$display("[%t] : Writing cmd_rd_start=1,msgld_num_of_req=%d, pld_cmd_req=1,msgst_num_of_req = %d",$realtime, msgld_num_of_req,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b1,msgst_num_of_req,1'b1};
		
		wait(`cDM_PL_TOP.design_ep_wrapper_i.design_1_i.psx_wizard_0.cdm1_msgld_dat_vld);
		repeat (20) @(posedge `cDM_PL_TOP.cpm_user_clk);
		
		$display("[%t] : Writing cmd_rd_start=0,msgld_num_of_req=%d, pld_cmd_req=0,msgst_num_of_req = %d",$realtime, msgld_num_of_req,msgst_num_of_req);
		@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_0 = {msgld_num_of_req,1'b0,msgst_num_of_req,1'b0};
		
	end
	
	wait(`MSGSTLD_top.msgld_rsp_status[0]);
	#10000000;
	$display("[%t] : msgst_req_pkt_sent = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgst_req_pkt_sent);
	$display("[%t] : msgld_req_pkt_sent = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgld_req_pkt_sent);
	$display("[%t] : msgst_rsp_pkt_rcvd = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgst_rsp_pkt_rcvd);
	$display("[%t] : msgld_rsp_pkt_rcvd = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgld_rsp_pkt_rcvd);
	$display("[%t] : msgst_pass_count = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgst_pass_cnt[31:0]);
	$display("[%t] : msgld_pass_count = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgld_pass_cnt[31:0]);
	$display("[%t] : msgst_fail_count = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgst_fail_cnt[31:0]);
	$display("[%t] : msgld_fail_count = %d",$realtime,`cDM_PL_TOP.msgstld_perf_inst.msgld_fail_cnt[31:0]);	
end

else if (testname == "verify_msgld_msgst_updates")
begin

	wait (`cDM_PL_TOP.msgst_ld_tg_inst.fabric_rst_n);
	$display("[%t] : NOTE: Do not load MSGST/MSGLD CMD BRAMs at the same time ",$realtime);
    $display("[%t] : Loading MSGST CMD BRAMs-Start ",$realtime);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.msgst_ld_tg_inst.msgstld_pld_length = 9'h20;
	repeat (5) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h106;
	
	wait(`cDM_PL_TOP.msgst_ld_tg_inst.num_msgst_cmd_loaded == `MSGSTLD_top.msgst_num_of_CMD);
	$display("[%t] : Loading MSGST CMD BRAMs-Finished ",$realtime);
	
	
	 $display("[%t] : Loading MSGLD CMD BRAMs-Start ",$realtime);

	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h10607;
	wait(`cDM_PL_TOP.msgst_ld_tg_inst.num_msgld_cmd_loaded == `MSGSTLD_top.msgld_num_of_CMD);
	repeat (5) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msg_ctrl_reg_1 = 32'h607;
	
	wait(`cDM_PL_TOP.msgst_ld_tg_inst.num_msgld_cmd_loaded == `MSGSTLD_top.msgld_num_of_CMD);
	
	$display("[%t] : Loading MSGLD CMD BRAMs-Finished ",$realtime);
    TSK_SIMULATION_TIMEOUT(5050);
	
	$display("[%t] : Test -MSGST/MSGLD updates ",$realtime);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;		
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgst.num_of_reqs = 15'd1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b1;	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgst.pld_cmd_req = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgst.pld_cmd_req = 1'b1; 
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b0;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);	
		
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b0;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgld.num_of_reqs = 15'd1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgld.cmd_rd_start = 1'b0; 
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgld.cmd_rd_start = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	
	repeat (5000) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b0;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b0;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b1;	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgst.num_of_reqs = 15'd1000;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgst.pld_cmd_req = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgst.pld_cmd_req = 1'b1; 
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgst_tready = 1'b1;
	
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b0;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);	
		
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b0;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_infinite_pkt_run_start = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgst_use_same_cmd = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgld.num_of_reqs = 15'd1000;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgld.cmd_rd_start = 1'b0; 
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.CDM_adapter_msgld.cmd_rd_start = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b0;
	repeat (2) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `cDM_PL_TOP.cdm_top_msgld_req_tready = 1'b1;
	
	repeat (5000) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b1;
	repeat (100) @(posedge `cDM_PL_TOP.cpm_user_clk);	
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b0;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b0;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_use_same_cmd = 1'b1;
	@(posedge `cDM_PL_TOP.cpm_user_clk) force `MSGSTLD_top.msgld_infinite_pkt_run_start = 1'b0;
	repeat (10) @(posedge `cDM_PL_TOP.cpm_user_clk);
	
	$finish;

end
`endif

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
