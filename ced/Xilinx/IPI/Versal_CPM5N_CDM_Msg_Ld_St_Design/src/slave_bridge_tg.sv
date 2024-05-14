///////////////////////////////////////////////////////////
// Simple Traffic Generators for debug purposes          //
// For full test, use the AXI TG in the BD Design        //
// Generates a full bus (one cycle) of Write and/or Read //
///////////////////////////////////////////////////////////

`timescale 1ps / 1ps

module slave_bridge_tg #
(
    parameter                       TCQ         = 1,
    parameter                       AXI_NUM_OUTSTANDING = 32,
    parameter                       DATA_WIDTH  = 512,
    parameter                       ADDR_WIDTH  = 64,
    parameter [ADDR_WIDTH-1:0]      AXIBAR_ADDR = 'h0
) (
	input				            fabric_clk,
	input				            fabric_rst_n,
	
	output wire [ADDR_WIDTH-1:0]    M_AXI_0_araddr,
    output wire [1:0]               M_AXI_0_arburst,
    output wire [3:0]               M_AXI_0_arcache,
    output wire [1:0]               M_AXI_0_arid,
    output wire [7:0]               M_AXI_0_arlen,
    output wire [0:0]               M_AXI_0_arlock,
    output wire [2:0]               M_AXI_0_arprot,
    output wire [3:0]               M_AXI_0_arqos,
    input  [0:0]                    M_AXI_0_arready,
    output wire [3:0]               M_AXI_0_arregion,
    output wire [2:0]               M_AXI_0_arsize,
	output wire [7:0]				M_AXI_0_aruser,
    output reg  [0:0]               M_AXI_0_arvalid,
    output wire [ADDR_WIDTH-1:0]    M_AXI_0_awaddr,
    output wire [1:0]               M_AXI_0_awburst,
    output wire [3:0]               M_AXI_0_awcache,
    output wire [1:0]               M_AXI_0_awid,
    output wire [7:0]               M_AXI_0_awlen,
    output wire [0:0]               M_AXI_0_awlock,
    output wire [2:0]               M_AXI_0_awprot,
    output wire [3:0]               M_AXI_0_awqos,
    input  [0:0]                    M_AXI_0_awready,
    output wire [3:0]               M_AXI_0_awregion,
    output wire [2:0]               M_AXI_0_awsize,
    output wire [7:0]               M_AXI_0_awuser,
    output reg  [0:0]               M_AXI_0_awvalid,
    input  [1:0]                    M_AXI_0_bid,
    output wire [0:0]               M_AXI_0_bready,
    input  [1:0]                    M_AXI_0_bresp,
    input  [0:0]                    M_AXI_0_bvalid,
    input  [DATA_WIDTH-1:0]         M_AXI_0_rdata,
    input  [1:0]                    M_AXI_0_rid,
    input  [0:0]                    M_AXI_0_rlast,
    output wire [0:0]               M_AXI_0_rready,
    input  [1:0]                    M_AXI_0_rresp,
    input  [0:0]                    M_AXI_0_rvalid,
    output wire [DATA_WIDTH-1:0]    M_AXI_0_wdata,
    output wire [0:0]               M_AXI_0_wlast,
    input  [0:0]                    M_AXI_0_wready,
    output wire [(DATA_WIDTH/8)-1:0] M_AXI_0_wstrb,
    output wire [0:0]               M_AXI_0_wvalid,
    
    input                           gen_wr,
    input                           gen_rd
);

reg  [$clog2(AXI_NUM_OUTSTANDING)-1:0] wr_data_req_cnt = 'd0; // Count the number of Write request that still need its paired data
reg  [7:0]                             counter         = 8'h00;
wire [31:0]                            data_dw;

// Write Data
always @(posedge fabric_clk) begin
  if (!fabric_rst_n)
    counter = #TCQ 8'h00;
  else
    counter = #TCQ counter + 1;
end
assign data_dw = {counter<<3,counter<<2,counter<<1,counter};

// Control Signals
always @(posedge fabric_clk) begin
  if (!fabric_rst_n) begin
    M_AXI_0_arvalid <= #TCQ 1'b0;
    M_AXI_0_awvalid <= #TCQ 1'b0;
    
    wr_data_req_cnt <= #TCQ 'd0;
  end else begin
    M_AXI_0_arvalid <= #TCQ gen_rd ? 1'b1: 
                            ((M_AXI_0_arvalid && !M_AXI_0_arready) ? 1'b1 : 1'b0);
                            
    M_AXI_0_awvalid <= #TCQ (gen_wr && !(wr_data_req_cnt > (AXI_NUM_OUTSTANDING - 3))) ? 1'b1: 
                            ((M_AXI_0_awvalid && !M_AXI_0_awready) ? 1'b1 : 1'b0);
                            
    wr_data_req_cnt <= #TCQ ((M_AXI_0_awvalid && M_AXI_0_awready) && (!(M_AXI_0_wvalid && M_AXI_0_wready && M_AXI_0_wlast))) ? wr_data_req_cnt + 1 :
                            ((!(M_AXI_0_awvalid && M_AXI_0_awready)) && (M_AXI_0_wvalid && M_AXI_0_wready && M_AXI_0_wlast)) ? wr_data_req_cnt - 1 :
                                                                                                                               wr_data_req_cnt;
  end
end
assign M_AXI_0_wvalid   = (|wr_data_req_cnt);

// Assign Static Values
assign M_AXI_0_araddr   = AXIBAR_ADDR + 'h40; // Offset 'h40;
assign M_AXI_0_arburst  = 2'b01;
assign M_AXI_0_arcache  = 4'h0;
assign M_AXI_0_arid     = 2'b00;
assign M_AXI_0_arlen    = 8'h0;
assign M_AXI_0_arlock   = 1'b0;
assign M_AXI_0_arprot   = 3'b000;
assign M_AXI_0_arqos    = 4'h0;
assign M_AXI_0_arregion = 4'h0;
assign M_AXI_0_arsize   = $clog2(DATA_WIDTH/8);

assign M_AXI_0_awaddr   = AXIBAR_ADDR + 'h40; // Offset 'h40;
assign M_AXI_0_awburst  = 2'b01;
assign M_AXI_0_awcache  = 4'h0;
assign M_AXI_0_awid     = 2'b00;
assign M_AXI_0_awlen    = 8'h0;
assign M_AXI_0_awlock   = 1'b0;
assign M_AXI_0_awprot   = 3'b000;
assign M_AXI_0_awqos    = 4'h0;
assign M_AXI_0_awregion = 4'h0;
assign M_AXI_0_awsize   = $clog2(DATA_WIDTH/8);

assign M_AXI_0_wdata    = {(DATA_WIDTH/32){data_dw}};
assign M_AXI_0_wlast    = 1'b1;
assign M_AXI_0_wstrb    = {(DATA_WIDTH/8){1'b1}};

assign M_AXI_0_bready   = 1'b1;
assign M_AXI_0_rready   = 1'b1;

endmodule