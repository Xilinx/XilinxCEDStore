/* # ########################################################################
# Copyright (C) 2019, Xilinx Inc - All rights reserved

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ######################################################################## */

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
        tb.mpsoc_sys.Base_Zynq_MPSoC_i.zynq_ultra_ps_e_0.inst.write_data(32'hA0010000,4, 32'hDEADBEEF, resp);
        tb.mpsoc_sys.Base_Zynq_MPSoC_i.zynq_ultra_ps_e_0.inst.read_data(32'hA0010000,4,read_data,resp);
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

