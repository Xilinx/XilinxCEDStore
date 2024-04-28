`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AMD
// Engineer: Agastya Sampath
// 
// Create Date: 10/18/2023 03:35:38 PM
// Design Name: CDC Module for Individual Signals
// Module Name: one_signal_cdc
// Project Name: Two Port Switch (CPM5 DSP, PL-PCIe5 USP)
// Target Devices: xcvp1202-vsva2785-2MHP-e-S
// Tool Versions: 2023.2
// Description: Converts one packed signal from one clock domain to another with 8 flops
// 
// Dependencies: -
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module one_signal_cdc #(
    parameter SIGNAL_WIDTH = 1
) (
    src_clk,
    dst_clk,
    sys_rst,
    sig_in,
    sig_out
);
  input wire src_clk;
  input wire dst_clk;
  input wire sys_rst;
  input wire [SIGNAL_WIDTH-1:0] sig_in;
  output wire [SIGNAL_WIDTH-1:0] sig_out;

  logic [SIGNAL_WIDTH-1:0] reg1;
  logic [SIGNAL_WIDTH-1:0] reg2;
  logic [SIGNAL_WIDTH-1:0] reg3;
  logic [SIGNAL_WIDTH-1:0] reg4;
  logic [SIGNAL_WIDTH-1:0] reg5;
  logic [SIGNAL_WIDTH-1:0] reg6;
  logic [SIGNAL_WIDTH-1:0] reg7;
  logic [SIGNAL_WIDTH-1:0] reg8;

  assign sig_out = reg8;

  // 8 flops to match CDC using the AXI4-ST Clock Converter IP's settings
  always @(posedge dst_clk or negedge sys_rst) begin
    if (~sys_rst) begin
      reg1 <= 'b0;
      reg2 <= 'b0;
      reg3 <= 'b0;
      reg4 <= 'b0;
      reg5 <= 'b0;
      reg6 <= 'b0;
      reg7 <= 'b0;
      reg8 <= 'b0;
    end else begin
      reg1 <= sig_in;
      reg2 <= reg1;
      reg3 <= reg2;
      reg4 <= reg3;
      reg5 <= reg4;
      reg6 <= reg5;
      reg7 <= reg6;
      reg8 <= reg7;
    end
  end
endmodule
