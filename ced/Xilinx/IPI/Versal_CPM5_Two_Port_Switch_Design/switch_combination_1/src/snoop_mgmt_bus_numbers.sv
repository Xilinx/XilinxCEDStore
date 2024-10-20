`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AMD 
// Engineer: Agastya Sampath 
// 
// Create Date: 10/18/2023 04:25:17 PM
// Design Name: Snoop Management Interface for Bus Numbers 
// Module Name: snoop_mgmt_bus_numbers
// Project Name: Two Port Switch (CPM5 USP, PL-PCIe5 DSP) 
// Target Devices: xcvp1202-vsva2785-2MHP-e-S 
// Tool Versions: 2023.2 
// Description: Snoops the bus numbers from the DSP for routing in the Switch 
// 
// Dependencies: - 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module snoop_mgmt_bus_numbers (
    input wire dsp_user_clk,
    input wire dsp_user_reset,
input wire sys_reset_n,

    input wire        dsp_cfg_mgmt_write,
    input wire        dsp_cfg_mgmt_read_write_done,
    input wire [ 9:0] dsp_cfg_mgmt_addr,
    input wire [ 7:0] dsp_cfg_mgmt_function_number,
    input wire [31:0] dsp_cfg_mgmt_write_data,
    input wire [ 3:0] dsp_cfg_mgmt_byte_enable,
    input wire        usp_bus_num_rdy_dsp_domain,

    output wire [7:0] dsp_pri_bus,
    output wire [7:0] dsp_sec_bus,
    output wire [7:0] dsp_sub_bus,
    output wire all_bus_numbers_ready
);
  localparam PRI_BUS_NUM_REG_ADDR = 10'h6;
  logic pri_bus_rdy;
  logic sec_bus_rdy;
  logic sub_bus_rdy;
  logic [7:0] dsp_pri_bus_reg;
  logic [7:0] dsp_sec_bus_reg;
  logic [7:0] dsp_sub_bus_reg;
  assign dsp_pri_bus = dsp_pri_bus_reg;
  assign dsp_sec_bus = dsp_sec_bus_reg;
  assign dsp_sub_bus = dsp_sub_bus_reg;
  assign all_bus_numbers_ready = usp_bus_num_rdy_dsp_domain & sec_bus_rdy & sub_bus_rdy; // Primary bus ignored for DSP (equal to USP secondary), but maintained in case writeback is needed

  always_ff @(posedge dsp_user_clk or negedge sys_reset_n) begin
        if (~sys_reset_n) begin
      dsp_pri_bus_reg <= 'b0;
      dsp_sec_bus_reg <= 'b0;
      dsp_sub_bus_reg <= 'b0;
      pri_bus_rdy <= 0;
      sec_bus_rdy <= 0;
      sub_bus_rdy <= 0;
    end 
    else if (dsp_cfg_mgmt_write && dsp_cfg_mgmt_read_write_done && (dsp_cfg_mgmt_function_number == 8'd0) && (dsp_cfg_mgmt_addr == PRI_BUS_NUM_REG_ADDR)) begin // Assign if write to bus numbers
      if (dsp_cfg_mgmt_byte_enable[0]) begin
        dsp_pri_bus_reg <= dsp_cfg_mgmt_write_data[7:0];
        pri_bus_rdy <= 1;
      end
      if (dsp_cfg_mgmt_byte_enable[1]) begin
        dsp_sec_bus_reg <= dsp_cfg_mgmt_write_data[15:8];
        sec_bus_rdy <= 1;
      end
      if (dsp_cfg_mgmt_byte_enable[2]) begin
        dsp_sub_bus_reg <= dsp_cfg_mgmt_write_data[23:16];
        sub_bus_rdy <= 1;
      end
    end
  end
endmodule
