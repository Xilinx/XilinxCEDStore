//---------------------------------------------------------------------------
// Testbench  
//---------------------------------------------------------------------------
//
//***************************************************************************
// DISCLAIMER OF LIABILITY
//
// This file contains proprietary and confidential information of
// Xilinx, Inc. ("Xilinx"), that is distributed under a license
// from Xilinx, and may be used, copied and/or disclosed only
// pursuant to the terms of a valid license agreement with Xilinx.
//
// XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
// ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
// LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
// MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
// does not warrant that functions included in the Materials will
// meet the requirements of Licensee, or that the operation of the
// Materials will be uninterrupted or error-free, or that defects
// in the Materials will be corrected. Furthermore, Xilinx does
// not warrant or make any representations regarding use, or the
// results of the use, of the Materials in terms of correctness,
// accuracy, reliability or otherwise.
//
// Xilinx products are not designed or intended to be fail-safe,
// or for use in any application requiring fail-safe performance,
// such as life-support or safety devices or systems, Class III
// medical devices, nuclear facilities, applications related to
// the deployment of airbags, or any other applications that could
// lead to death, personal injury or severe property or
// environmental damage (individually and collectively, "critical
// applications"). Customer assumes the sole risk and liability
// of any use of Xilinx products in critical applications,
// subject only to applicable laws and regulations governing
// limitations on product liability.
//
// Copyright 2009 Xilinx, Inc.
// All rights reserved.
//
// This disclaimer and copyright notice must be retained as part
// of this file at all times.
//***************************************************************************
//

`timescale 1ns / 1ps

module tb;
    reg tb_ACLK;
    reg tb_ARESETn;
   
    wire temp_clk;
    wire temp_rstn; 
  
    reg [31:0] read_data;
    wire [7:0] leds;
    reg resp;
    

    initial 
    begin       
        tb_ACLK = 1'b0;
    end
    
    //------------------------------------------------------------------------
    // Simple Clock Generator
    //------------------------------------------------------------------------
    
    always #10 tb_ACLK = !tb_ACLK;
       
    initial
    begin
    
        $display ("running the tb");
        
        tb_ARESETn = 1'b0;
        repeat(20)@(posedge tb_ACLK);        
        tb_ARESETn = 1'b1;
        @(posedge tb_ACLK);
        
        repeat(5) @(posedge tb_ACLK);
          

  	tb.mpsoc_sys.Base_Zynq_MPSoC_i.zynq_ultra_ps_e_0.inst.por_srstb_reset(1'b1);
        #200;
        tb.mpsoc_sys.Base_Zynq_MPSoC_i.zynq_ultra_ps_e_0.inst.por_srstb_reset(1'b0);
        tb.mpsoc_sys.Base_Zynq_MPSoC_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(32'h1);
        #2000 ;  // This delay depends on your clock frequency. It should be at least 16 clock cycles. 
        tb.mpsoc_sys.Base_Zynq_MPSoC_i.zynq_ultra_ps_e_0.inst.por_srstb_reset(1'b1);
        tb.mpsoc_sys.Base_Zynq_MPSoC_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(32'h0);
	#2000 ; 
		
		
        //This drives the LEDs on the GPIO output
        tb.mpsoc_sys.Base_Zynq_MPSoC_i.zynq_ultra_ps_e_0.inst.write_data(32'hA0000000,4, 32'hFFFFFFFF, resp);
        tb.mpsoc_sys.Base_Zynq_MPSoC_i.zynq_ultra_ps_e_0.inst.read_data(32'hA0000000,4, read_data, resp);
        
        
        $display ("LEDs are toggled, observe the waveform");
        
        //Write into the BRAM through GP0 and read back
        tb.mpsoc_sys.Base_Zynq_MPSoC_i.zynq_ultra_ps_e_0.inst.write_data(32'hB0000000,4, 32'hDEADBEEF, resp);
        tb.mpsoc_sys.Base_Zynq_MPSoC_i.zynq_ultra_ps_e_0.inst.read_data(32'hB0000000,4,read_data,resp);
        $display ("%t, running the testbench, data read from BRAM was 32'h%x",$time, read_data);

    if(read_data == 32'hDEADBEEF) begin
           $display ("AXI VIP Test PASSED");
        end
        else begin
           $display ("AXI VIP Test FAILED");
        end
        $display ("Simulation completed");
        $stop;
    end

    assign temp_clk = tb_ACLK;
    assign temp_rstn = tb_ARESETn;
	
	
Base_Zynq_MPSoC_wrapper mpsoc_sys
 (
 .led_8bits_tri_o(leds)    
);

  


endmodule

