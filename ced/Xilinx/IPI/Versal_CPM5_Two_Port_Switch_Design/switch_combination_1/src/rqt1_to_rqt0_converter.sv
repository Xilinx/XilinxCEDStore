`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AMD 
// Engineer: Agastya Sampath 
// 
// Create Date: 10/11/2023 03:09:24 PM
// Design Name: RQ Type 1 to Type 0 Converter 
// Module Name: rqt1_to_rqt0_converter
// Project Name: Two Port Switch (CPM5 USP, PL-PCIe5 DSP) 
// Target Devices: xcvp1202-vsva2785-2MHP-e-S 
// Tool Versions: 2023.2 
// Description: Converts RQ Type 1 packet to Type 0 packet 
// 
// Dependencies: - 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rqt1_to_rqt0_converter #(
    parameter IF_WIDTH = 512,
    parameter TKEEP_WIDTH = 16,
    parameter RQ_TUSER_WIDTH = 183
) (
    input logic [1:0] select,

    input logic [IF_WIDTH-1 : 0] s_axis_rq_tdata,
    input logic [TKEEP_WIDTH - 1 : 0] s_axis_rq_tkeep,
    input logic s_axis_rq_tlast,
    output logic s_axis_rq_tready,
    input logic [RQ_TUSER_WIDTH-1 : 0] s_axis_rq_tuser,
    input logic s_axis_rq_tvalid,

    output logic [IF_WIDTH-1 : 0] s_axis_rq_tdata_new,
    output logic [TKEEP_WIDTH - 1 : 0] s_axis_rq_tkeep_new,
    output logic s_axis_rq_tlast_new,
    input logic s_axis_rq_tready_new,
    output logic [RQ_TUSER_WIDTH-1 : 0] s_axis_rq_tuser_new,
    output logic s_axis_rq_tvalid_new
);

  always_comb begin
    s_axis_rq_tready = s_axis_rq_tready_new;
    s_axis_rq_tkeep_new = s_axis_rq_tkeep;
    s_axis_rq_tlast_new = s_axis_rq_tlast;
    s_axis_rq_tuser_new = s_axis_rq_tuser;
    s_axis_rq_tvalid_new = s_axis_rq_tvalid;
    s_axis_rq_tdata_new = s_axis_rq_tdata;
    s_axis_rq_tdata_new[75] = 1'b0;  // Change type 1 to type 0
  end

endmodule
