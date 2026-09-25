// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
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
//
// Project    : The PCI Express DMA 
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