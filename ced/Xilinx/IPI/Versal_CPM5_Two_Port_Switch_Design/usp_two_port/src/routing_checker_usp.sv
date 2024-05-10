`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AMD 
// Engineer: Agastya Sampath 
// 
// Create Date: 10/18/2023 11:33:50 AM
// Design Name: Routing Checker on USP end 
// Module Name: routing_checker_usp
// Project Name: Two Port Switch (CPM5 USP, PL-PCIe5 DSP) 
// Target Devices: xcvp1202-vsva2785-2MHP-e-S 
// Tool Versions: 2023.2 
// Description: Assigns routing information for the USP end of the switch 
// 
// Dependencies: - 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module routing_checker_usp #(
    parameter USP_IF_WIDTH = 512,
    parameter USP_CQ_TUSER_WIDTH = 232,
    parameter USP_TKEEP_WIDTH = 16
) (
    input wire [7:0] usp_pri_bus,
    input wire [7:0] usp_sec_bus,
    input wire [7:0] usp_sub_bus,
    input wire all_bus_numbers_ready,

    input logic [USP_IF_WIDTH-1 : 0] m_axis_cq_tdata,
    input logic [USP_TKEEP_WIDTH - 1 : 0] m_axis_cq_tkeep,
    input logic m_axis_cq_tlast,
    output logic m_axis_cq_tready,
    input logic [USP_CQ_TUSER_WIDTH-1 : 0] m_axis_cq_tuser,
    input logic m_axis_cq_tvalid,

    // Outputs
    output logic [USP_IF_WIDTH-1 : 0] m_axis_cq_tdata_new,
    output logic [USP_TKEEP_WIDTH - 1 : 0] m_axis_cq_tkeep_new,
    output logic m_axis_cq_tlast_new,
    input logic m_axis_cq_tready_new,
    output logic [USP_CQ_TUSER_WIDTH-1 : 0] m_axis_cq_tuser_new,
    output logic m_axis_cq_tvalid_new,
    output logic unsupported_req
);

  always_comb begin
    m_axis_cq_tdata_new = m_axis_cq_tdata;
    m_axis_cq_tkeep_new = m_axis_cq_tkeep;
    m_axis_cq_tlast_new = m_axis_cq_tlast;
    m_axis_cq_tready = m_axis_cq_tready_new;
    m_axis_cq_tuser_new = m_axis_cq_tuser;
    m_axis_cq_tvalid_new = m_axis_cq_tvalid;
    if (m_axis_cq_tvalid) begin
      if (all_bus_numbers_ready & (m_axis_cq_tdata[78:77] == 2'b10) & (m_axis_cq_tdata[75] == 1'b1) & (m_axis_cq_tdata[119:112] == usp_sec_bus) & (m_axis_cq_tdata[111:104] == 8'b0)) begin // Type 1 Config Allowed, block other requests
        unsupported_req = 1'b0;
      end else begin
        unsupported_req = 1'b1;
      end
    end else begin
      unsupported_req = 1'b0;
    end
  end
endmodule
