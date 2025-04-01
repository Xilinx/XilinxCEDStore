`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AMD
// Engineer: Agastya Sampath
// 
// Create Date: 10/17/2023 05:17:09 PM
// Design Name: Snoop Extended Interface for Bus Numbers
// Module Name: snoop_ext_bus_numbers
// Project Name: Two Port Switch (CPM5 DSP, PL-PCIe5 USP)
// Target Devices: xcvp1202-vsva2785-2MHP-e-S
// Tool Versions: 2023.2
// Description: Stores the bus numbers from USP for routing in the Switch
// 
// Dependencies: -
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module snoop_ext_bus_numbers (
    input wire usp_user_clk,
    input wire usp_user_reset,
    input wire sys_reset_n,

    input wire        usp_cfg_ext_write_received,
    input wire [ 9:0] usp_cfg_ext_register_number,   // Extended Space register number
    input wire [ 7:0] usp_cfg_ext_function_number,   // Extended Space Function number
    input wire [31:0] usp_cfg_ext_write_data,        // Extended Space write data
    input wire [ 3:0] usp_cfg_ext_write_byte_enable, // Byte enables for write

    output wire [7:0] usp_pri_bus,
    output wire [7:0] usp_sec_bus,
    output wire [7:0] usp_sub_bus,
    output wire all_bus_numbers_ready
);
  localparam PRI_BUS_NUM_REG_ADDR = 10'h6;
  logic pri_bus_rdy;
  logic sec_bus_rdy;
  logic sub_bus_rdy;
  logic [7:0] usp_pri_bus_reg;
  logic [7:0] usp_sec_bus_reg;
  logic [7:0] usp_sub_bus_reg;
  assign usp_pri_bus = usp_pri_bus_reg;
  assign usp_sec_bus = usp_sec_bus_reg;
  assign usp_sub_bus = usp_sub_bus_reg;
  assign all_bus_numbers_ready = pri_bus_rdy & sec_bus_rdy & sub_bus_rdy;
  always_ff @(posedge usp_user_clk or negedge sys_reset_n) begin
    if (~sys_reset_n) begin
      usp_pri_bus_reg <= 'b0;
      usp_sec_bus_reg <= 'b0;
      usp_sub_bus_reg <= 'b0;
      pri_bus_rdy <= 0;
      sec_bus_rdy <= 0;
      sub_bus_rdy <= 0;
    end else 
    if (usp_cfg_ext_write_received && (usp_cfg_ext_function_number == 8'd0) && (usp_cfg_ext_register_number == PRI_BUS_NUM_REG_ADDR)) begin // Assign if write to bus numbers
      if (usp_cfg_ext_write_byte_enable[0]) begin
        usp_pri_bus_reg <= usp_cfg_ext_write_data[7:0];
        pri_bus_rdy <= 1;
      end
      if (usp_cfg_ext_write_byte_enable[1]) begin
        usp_sec_bus_reg <= usp_cfg_ext_write_data[15:8];
        sec_bus_rdy <= 1;
      end
      if (usp_cfg_ext_write_byte_enable[2]) begin
        usp_sub_bus_reg <= usp_cfg_ext_write_data[23:16];
        sub_bus_rdy <= 1;
      end
    end
  end
endmodule
