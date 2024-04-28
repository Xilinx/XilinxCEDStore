`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AMD 
// Engineer: Agastya Sampath 
// 
// Create Date: 10/16/2023 11:56:32 AM
// Design Name: Type 1 CQ to CFG MGMT Converter 
// Module Name: cqt1_to_cfg_mgmt_converter
// Project Name: Two Port Switch (CPM5 USP, PL-PCIe5 DSP) 
// Target Devices: xcvp1202-vsva2785-2MHP-e-S 
// Tool Versions: 2023.2 
// Description: Converts CQ Type 1 packet to CFG MGMT packet 
// 
// Dependencies: - 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cqt1_to_cfg_mgmt_converter #(
    parameter DSP_IF_WIDTH = 512,
    parameter DSP_TKEEP_WIDTH = 16,
    parameter DSP_CQ_TUSER_WIDTH = 231
) (
    input logic [DSP_IF_WIDTH-1 : 0] dsp_m_axis_cq_tdata,
    input logic [DSP_TKEEP_WIDTH - 1 : 0] dsp_m_axis_cq_tkeep,
    input logic dsp_m_axis_cq_tlast,
    input logic [DSP_CQ_TUSER_WIDTH-1 : 0] dsp_m_axis_cq_tuser,
    input logic dsp_m_axis_cq_tvalid,

    input logic [1:0] select,
    input logic [3:0] req_type,

    output logic [9 : 0] cfg_mgmt_addr,
    output logic [7 : 0] cfg_mgmt_function_number,
    output logic cfg_mgmt_write,
    output logic [31 : 0] cfg_mgmt_write_data,
    output logic [3 : 0] cfg_mgmt_byte_enable,
    output logic cfg_mgmt_read,
    input logic [31 : 0] cfg_mgmt_read_data,
    input logic cfg_mgmt_read_write_done,
    output logic cfg_mgmt_debug_access
);
  always_comb begin
    if (dsp_m_axis_cq_tvalid & (&(req_type[3:2] == 2'b10)) & (&(select == 2'b01)) & &(dsp_m_axis_cq_tdata[111:104] == 8'b0)) begin
      cfg_mgmt_addr = dsp_m_axis_cq_tdata[11:2];
      cfg_mgmt_function_number = 8'b0;
      cfg_mgmt_write = req_type[1];
      cfg_mgmt_write_data = dsp_m_axis_cq_tdata[159:128]; // First 32 bits - configs always fit in one beat
      cfg_mgmt_byte_enable = dsp_m_axis_cq_tuser[3:0];
      cfg_mgmt_read = ~req_type[1];
      cfg_mgmt_debug_access = 1'b0;
    end else begin
      cfg_mgmt_addr = 'b0;
      cfg_mgmt_function_number = 'b0;
      cfg_mgmt_write = 'b0;
      cfg_mgmt_write_data = 'b0;  // First 32 bits
      cfg_mgmt_byte_enable = 'b0;
      cfg_mgmt_read = 'b0;
      cfg_mgmt_debug_access = 'b0;
    end
  end
endmodule
