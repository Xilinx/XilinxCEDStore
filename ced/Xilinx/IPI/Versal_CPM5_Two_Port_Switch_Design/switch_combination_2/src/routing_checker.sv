`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AMD
// Engineer: Agastya Sampath
// 
// Create Date: 10/11/2023 10:20:30 AM
// Design Name: Routing Checker on DSP end
// Module Name: routing_checker
// Project Name: Two Port Switch (CPM5 DSP, PL-PCIe5 USP)
// Target Devices: xcvp1202-vsva2785-2MHP-e-S
// Tool Versions: 2023.2
// Description: Assigns routing information for the DSP end of the switch
// 
// Dependencies: -
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module routing_checker #(
    parameter DSP_IF_WIDTH = 512,
    parameter DSP_CQ_TUSER_WIDTH = 231,
    parameter DSP_TKEEP_WIDTH = 16
) (
    // Inputs
    input logic [DSP_IF_WIDTH-1 : 0] m_axis_cq_tdata,
    input logic [DSP_TKEEP_WIDTH - 1 : 0] m_axis_cq_tkeep,
    input logic m_axis_cq_tlast,
    output logic m_axis_cq_tready,
    input logic [DSP_CQ_TUSER_WIDTH-1 : 0] m_axis_cq_tuser,
    input logic m_axis_cq_tvalid,
    input logic dsp_user_lnk_up,

    // DSP Bus Numbers
    input logic [7:0] dsp_pri_bus,
    input logic [7:0] dsp_sec_bus,
    input logic [7:0] dsp_sub_bus,
    input logic [3:0] req_type,

    // Bus Number Ready signals
    input logic usp_bus_num_rdy,
    input logic dsp_bus_num_rdy,

    // USP Routing Info
    input logic usp_unsupported_req,

    // Outputs
    output logic [DSP_IF_WIDTH-1 : 0] m_axis_cq_tdata_new,
    output logic [DSP_TKEEP_WIDTH - 1 : 0] m_axis_cq_tkeep_new,
    output logic m_axis_cq_tlast_new,
    input logic m_axis_cq_tready_new,
    output logic [DSP_CQ_TUSER_WIDTH-1 : 0] m_axis_cq_tuser_new,
    output logic m_axis_cq_tvalid_new,
    output logic [1:0] select,
    output logic unsupported_req_out
);
  localparam CQ_BUS_BIT_SELECT_OFFSET = 112;
  localparam CQ_DF_BIT_SELECT_OFFSET = 104;

  logic unsupported_req;

  assign unsupported_req_out = (~dsp_user_lnk_up & dsp_bus_num_rdy & ~unsupported_req & (select[0] == 1'b0)) ? 1'b1 : unsupported_req;

  wire [7:0] cq_tgt_bus;
  assign cq_tgt_bus = m_axis_cq_tdata[CQ_BUS_BIT_SELECT_OFFSET+:8]; // Straddle off, only one header

  wire [7:0] cq_tgt_dev_fn;
  assign cq_tgt_dev_fn = m_axis_cq_tdata[CQ_DF_BIT_SELECT_OFFSET+:8]; // Straddle off, only one header

  function routing_select_1;
    input [7:0] pri_bus;
    input [7:0] tgt_bus;
    begin
      routing_select_1 = &(pri_bus == tgt_bus);
    end
  endfunction

  function routing_select_2;
    input [7:0] sec_bus;
    input [7:0] sub_bus;
    input [7:0] tgt_bus;
    begin
      routing_select_2 = &((sub_bus >= tgt_bus) & (tgt_bus >= sec_bus));
    end
  endfunction

  // TODO: Check message handling behavior
  always_comb begin
    m_axis_cq_tdata_new  = m_axis_cq_tdata;
    m_axis_cq_tkeep_new  = m_axis_cq_tkeep;
    m_axis_cq_tlast_new  = m_axis_cq_tlast;
    m_axis_cq_tuser_new  = m_axis_cq_tuser;
    m_axis_cq_tvalid_new = m_axis_cq_tvalid;
    if (m_axis_cq_tvalid) begin

      // Assign unsupported_req
      if (~dsp_bus_num_rdy & usp_bus_num_rdy) begin
        unsupported_req = usp_unsupported_req;
      end else if ((dsp_bus_num_rdy & (&(req_type[3:2] == 2'b10)) & ((routing_select_1(
              dsp_pri_bus, cq_tgt_bus
          ) & &(cq_tgt_dev_fn == 8'b0)) | routing_select_2(
              dsp_sec_bus, dsp_sub_bus, cq_tgt_bus
          ))) | (dsp_bus_num_rdy & ~(&(req_type[3:2] == 2'b10)))) begin  // routing check
        unsupported_req = 1'b0;
      end else begin
        unsupported_req = 1'b1;
      end

      // Assign select
      if (~dsp_bus_num_rdy & ~usp_unsupported_req) select = 2'd1;
      else if (dsp_bus_num_rdy & &(req_type[3:2] == 2'b10) & routing_select_1(
              dsp_pri_bus, cq_tgt_bus
          ))
        select = 2'd1;
      else if (dsp_bus_num_rdy & &(req_type[3:2] == 2'b10) & routing_select_2(
              dsp_sec_bus, dsp_sub_bus, cq_tgt_bus
          ))
        select = 2'd0;
      else select = 2'd2;
    end else begin
      unsupported_req = 1'b0;
      select = 2'd3;
    end
  end

  assign m_axis_cq_tready = m_axis_cq_tready_new;

endmodule

