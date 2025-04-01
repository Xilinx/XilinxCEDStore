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
// Project    : The Xilinx PCI Express DMA 
// File       : PS2PL_ctrl.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

`timescale 1ps / 1ps

module PS2PL_ctrl #(
)
(

  input                        user_clk,
  input                        user_reset_n,
  input                        ps_pl_axil_wvalid,
  input wire                   ps_pl_axil_wready,  
  input                 [31:0] ps_pl_axil_awaddr,
  input                 [31:0] ps_pl_axil_wdata,
  output logic          [31:0] ps_pl_axil_rdata,
  input                 [31:0] ps_pl_axil_araddr,
  output logic          [31:0] qdma_c2h_dsc_byp_ctrl,
  output logic          [63:0] pl_to_ddr_axi4_awaddr,
  output logic			[31:0] BTT,
  output logic			[31:0] cdma_trfr_sz

);

reg [31:0]		fifo_2_ddr_addr_0;
reg [31:0]		fifo_2_ddr_addr_1;

always @(posedge user_clk) begin
    if (!user_reset_n) begin
		fifo_2_ddr_addr_0		<= 32'h0;
		fifo_2_ddr_addr_1		<= 32'h0;
		qdma_c2h_dsc_byp_ctrl	<= 32'h0;
		BTT						<= 32'h0;
		cdma_trfr_sz			<= 32'h0;
	end
	else begin
		if (ps_pl_axil_wvalid && ps_pl_axil_wready ) begin
			case (ps_pl_axil_awaddr[15:0])
				16'h00 : fifo_2_ddr_addr_0 	    <= ps_pl_axil_wdata;
				16'h04 : fifo_2_ddr_addr_1 	    <= ps_pl_axil_wdata;				
				16'h08 : qdma_c2h_dsc_byp_ctrl	<= ps_pl_axil_wdata;//[15:0] = dma0_dsc_crdt_in_0_crdt, [16]= dsc_crdt_in_vld, [17] = c2h_channel (CPM_PCIE_NOC_0 or CPM_PCIE_NOC_1), [18] = dsc_crdt_in_fence, [31:20] = c2h_byp_qid
				16'h0C : BTT					<= ps_pl_axil_wdata;
				16'h10: cdma_trfr_sz			<= ps_pl_axil_wdata;
			endcase
		end	
	end
end

always_comb begin 
		case (ps_pl_axil_araddr[15:0])
			16'h00 : ps_pl_axil_rdata   <= fifo_2_ddr_addr_0;
			16'h04 : ps_pl_axil_rdata   <= fifo_2_ddr_addr_1;
			16'h08 : ps_pl_axil_rdata   <= qdma_c2h_dsc_byp_ctrl;		
			16'h0C : ps_pl_axil_rdata   <= BTT;		
			16'h10: ps_pl_axil_rdata    <= cdma_trfr_sz;
			default : ps_pl_axil_rdata  <= 32'h0;
		endcase
end


assign pl_to_ddr_axi4_awaddr = {fifo_2_ddr_addr_1,fifo_2_ddr_addr_0};

endmodule