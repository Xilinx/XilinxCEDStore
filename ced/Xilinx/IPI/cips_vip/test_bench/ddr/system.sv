`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2020 04:59:00 PM
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
`timescale 1ns/1ps
`define CIPS_VIP tb.DUT.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst
`default_nettype wire
module tb( );
  bit sysclk_p;
  bit sysclk_n;
  
  wire pl0_ref_clk;
  wire pl_gen_reset;
  reg tb_ACLK;
  reg tb_ARESETn;
  reg[1:0] resp;
  reg[31:0] read_data;
  reg[511:0] write_ddr_data;
  reg[511:0] read_ddr_data;
  reg[43:0] addr;
//  reg[1:0] resp;
  reg[15:0] irq_status;
  bit success = 1;

  reg [127:0] read_data0;
  reg [127:0] read_data1;
  reg [127:0] read_data2;
  reg [127:0] read_data3;
  
//  int addr;
  int i;

  always begin
    sysclk_p = 1;
    sysclk_n = 0;
    #2;
    sysclk_p = 0;
    sysclk_n = 1;
    #2;  
  end
  
  initial begin
    tb_ACLK = 1'b0;
  end
  always #5ns tb_ACLK = !tb_ACLK;
  
  initial begin
    $display("Running the testbench");
    @(posedge tb_ACLK);
    
    // Provide the clock to CIPS PS
    `CIPS_VIP.pl_gen_clock(0,333);     
    force `CIPS_VIP.versal_cips_ps_vip_clk = pl0_ref_clk;
    
    // Apply reset to the CIPs PS VIP
    `CIPS_VIP.pl_gen_reset(4'b0001);
    `CIPS_VIP.por_reset(1);
    repeat(20)@(posedge tb_ACLK);
    `CIPS_VIP.por_reset(0);
    `CIPS_VIP.pl_gen_reset(4'b0000);
    repeat(20)@(posedge tb_ACLK);
    `CIPS_VIP.pl_gen_reset(4'b0001);
	`CIPS_VIP.por_reset(1);
	
    // Set routing configuration from MicroBlaze to AXI_BRAM
	`CIPS_VIP.set_routing_config("S_AXI_LPD","M_AXI_LPD",1);
	`CIPS_VIP.get_routing_config();
	
	#30us; // wait for MicroBlaze writes to AXI_BRAM.
	
	`CIPS_VIP.set_routing_config("S_AXI_LPD","M_AXI_LPD",0);
	`CIPS_VIP.set_routing_config("R5_API","M_AXI_LPD",1);

	`CIPS_VIP.read_data("R5_API",44'h00080000000,16, read_data0, resp);
	`CIPS_VIP.read_data("R5_API",44'h00080000010,16, read_data1, resp);
	`CIPS_VIP.read_data("R5_API",44'h00080000020,16, read_data2, resp);
	`CIPS_VIP.read_data("R5_API",44'h00080000030,16, read_data3, resp);

	$display ("%t, running the testbench, data read was 32'h%x",$time, read_data0);
	$display ("%t, running the testbench, data read was 32'h%x",$time, read_data1);
	$display ("%t, running the testbench, data read was 32'h%x",$time, read_data2);
	$display ("%t, running the testbench, data read was 32'h%x",$time, read_data3);

	if(read_data0 == 128'hDEADBEAF12345678AABBCCDD11223344 && read_data1 == 128'hDEADBEAF12345678AABBCCDD11223344 && read_data2 == 128'hDEADBEAF12345678AABBCCDD11223344 &&  read_data3 == 128'hDEADBEAF12345678AABBCCDD11223344) begin
		$display ("CIPS VIP BRAM Test PASSED");
		end
		else begin
		$display ("CIPS VIP BRAM Test FAILED");
		end
	
    // Write 8kB to DDR
    // Set routing configuration
    `CIPS_VIP.set_routing_config("A72_API","FPD_CCI_NOC",1);
	`CIPS_VIP.select_cci_boundary(2);
    `CIPS_VIP.get_routing_config();
    
    // Write cache lines from A72
    for(addr = 0; addr < 44'h00000002000; addr = addr + 64) begin
        // address as data pattern
        write_ddr_data[511:0] = 512'h0000000000000000000000000000000000000000000000000000000000000000;
        for(i=addr; i < addr + 64; i=i+4) begin
          write_ddr_data = write_ddr_data | (i << ((i - addr) * 8));
        end
        //$display("Addr: 0x%010X Data: 0x%0128X", addr, write_data);
        `CIPS_VIP.write_burst(.master_name("A72_API"),.start_addr(addr),.len(8'h03),.siz(3'h4),.burst(2'b01),.lck(0),.cache(4'hF),.prot(0),.data(write_ddr_data),.datasize(64),.response (resp));
    end  
     
    // Set up AXI CDMA to transfer data
    `CIPS_VIP.set_routing_config("A72_API","FPD_CCI_NOC",0);
    `CIPS_VIP.set_routing_config("A72_API","M_AXI_FPD",1);
    `CIPS_VIP.get_routing_config();
    
    // Enable interrupts in control register
    `CIPS_VIP.write_data_32(.master_name("A72_API"), .start_addr(32'hA4000000), .w_data (32'h00017000), .response (resp));
    // Set source address
    `CIPS_VIP.write_data_32(.master_name("A72_API"), .start_addr(32'hA4000018), .w_data (32'h00000000), .response (resp));
    `CIPS_VIP.write_data_32(.master_name("A72_API"), .start_addr(32'hA400001C), .w_data (32'h00000000), .response (resp));
    // Set destination address
    `CIPS_VIP.write_data_32(.master_name("A72_API"), .start_addr(32'hA4000020), .w_data (32'h10000000), .response (resp));
    `CIPS_VIP.write_data_32(.master_name("A72_API"), .start_addr(32'hA4000024), .w_data (32'h00000000), .response (resp));
    // Set bytes to transfer
    `CIPS_VIP.write_data_32(.master_name("A72_API"), .start_addr(32'hA4000028), .w_data (32'h00002000), .response (resp));
     
    // Wait for interrupt
    `CIPS_VIP.wait_interrupt(.irq(4'h8), .irq_status(irq_status));
    
    $display("Interrupt received");
    // Check status
    `CIPS_VIP.read_data_32(.master_name("A72_API"), .start_addr(32'hA4000004), .rd_data_32(read_data), .response (resp));
    if(read_data & 32'h00004000) begin
      $display("FAILURE Err_Irq detected: 0x%08X", read_data);
    end
    else begin
      $display("CDMA PASS Status: 0x%08X", read_data); 
    end
    
    // Check data
    `CIPS_VIP.set_routing_config("A72_API","M_AXI_FPD",0);
    `CIPS_VIP.set_routing_config("R5_API","M_AXI_LPD",0);
    
    `CIPS_VIP.set_routing_config("A72_API","PMC_NOC_AXI_0",1);      
    `CIPS_VIP.set_routing_config("R5_API","NOC_LPD_AXI_0",1);
    `CIPS_VIP.get_routing_config();

    for(addr = 44'h00000000000; addr < 44'h00000002000; addr = addr + 64) begin
       `CIPS_VIP.read_burst(.master_name("A72_API"),.start_addr(addr),.len(8'h03),.siz(3'h4),.burst(2'b01),.lck(0),.cache(4'hF),.prot(0),.data(write_ddr_data),.response (resp));
       `CIPS_VIP.read_burst(.master_name("R5_API"),.start_addr(addr + 32'h10000000),.len(8'h03),.siz(3'h4),.burst(2'b01),.lck(0),.cache(4'hF),.prot(0),.data(read_ddr_data),.response (resp));
       if(read_ddr_data != write_ddr_data) begin
          $display("FAIL Data miscompare addr 0x%011X", addr);
          $display("\tExpected 0x%0128X", write_ddr_data);
          $display("\tRead     0x%0128X", read_ddr_data);
          success = 0;
       end
    end 
    
    if(success == 1) begin
        $display("CDMA data compare PASS");
    end 
    
    $display("Testbench complete");
    $finish;
   
  end

  design_1_wrapper_sim_wrapper DUT (
    .ddr4_dimm1_act_n (),
    .ddr4_dimm1_adr (),
    .ddr4_dimm1_ba (),
    .ddr4_dimm1_bg (),
    .ddr4_dimm1_ck_c (),
    .ddr4_dimm1_ck_t (),
    .ddr4_dimm1_cke (),
    .ddr4_dimm1_cs_n (),
    .ddr4_dimm1_dm_n (),
    .ddr4_dimm1_dq (),
    .ddr4_dimm1_dqs_c (),
    .ddr4_dimm1_dqs_t (),
    .ddr4_dimm1_odt (),
    .ddr4_dimm1_reset_n (),
    .ddr4_dimm1_sma_clk_clk_n (sysclk_n),
    .ddr4_dimm1_sma_clk_clk_p (sysclk_p),
    .pl0_ref_clk(pl0_ref_clk),
    .pl_gen_reset(pl_gen_reset)
  );

endmodule
