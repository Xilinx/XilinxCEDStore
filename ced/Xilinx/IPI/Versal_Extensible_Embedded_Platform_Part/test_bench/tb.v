    `timescale 1ns / 1ps
    //////////////////////////////////////////////////////////////////////////////////
    // Company: 
    // Engineer: 
    // 
    // Create Date: 01/06/2023 12:08:36 PM
    // Design Name: 
    // Module Name: tb
    // Project Name: 
    // Target Devices: 
    // Tool Versions: 
    // Description: 
    // 
    // Dependencies: 
    // 
    // Revision:
    // Revision 0.01 - File Created
    // Additional Comments:

    // 

    //////////////////////////////////////////////////////////////////////////////////

module tb();

    integer CIPS_0_pl_clk0_cnt=0;
    integer reset_cnt=0;
    integer clk_wiz_out1_cnt=0;
    ext_platform_part_wrapper_sim_wrapper DUT ();
    // Cross Language Boundary interaction is not supported in Questa.
    // Therefore, using Veilog Signals in the testbench
     // process  to poll the pl_resetn
      always @ (posedge DUT.ext_platform_part_wrapper_i.ext_platform_part_i.CIPS_0_pl_clk0) begin
      CIPS_0_pl_clk0_cnt = CIPS_0_pl_clk0_cnt + 1;
        if (DUT.ext_platform_part_wrapper_i.ext_platform_part_i.CIPS_0_pl_resetn1) 
        begin 
          if(reset_cnt < 10)
          begin
            $display("CIPS pl_clk0 count: %0d ,CIPS pl0_resetn: De-asserted",CIPS_0_pl_clk0_cnt);
            reset_cnt = reset_cnt+1;
          end
        end
        else $display("CIPS pl_clk0 count: %0d ,CIPS pl0_resetn: Asserted",CIPS_0_pl_clk0_cnt);
      end

      // process  to poll the clock_wiz output 1
      always @ (posedge DUT.ext_platform_part_wrapper_i.ext_platform_part_i.clk_wizard_0_clk_out1) begin
          if(clk_wiz_out1_cnt<10)
         begin
            $display("clk_wiz_out1 count: %0d ,CIPS pl0_resetn: De-asserted",clk_wiz_out1_cnt);
            clk_wiz_out1_cnt = clk_wiz_out1_cnt + 1;
         end
      end

endmodule

