`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AMD 
// Engineer: Agastya Sampath 
// 
// Create Date: 10/11/2023 10:20:30 AM
// Design Name: CQ to RQ Converter 
// Module Name: cq_to_rq_converter
// Project Name: Two Port Switch (CPM5 USP, PL-PCIe5 DSP) 
// Target Devices: xcvp1202-vsva2785-2MHP-e-S 
// Tool Versions: 2023.2 
// Description: Converts CQ packet to RQ packet 
// 
// Dependencies: - 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cq_to_rq_converter #(
    parameter IF_WIDTH = 512,
    parameter TKEEP_WIDTH = 16,
    parameter CQ_TUSER_WIDTH = 231,
    parameter RQ_TUSER_WIDTH = 183
) (
    input logic user_clk,
    input logic user_rst,
    input logic sys_reset_n,

    input logic [IF_WIDTH-1 : 0] m_axis_cq_tdata,
    input logic [TKEEP_WIDTH - 1 : 0] m_axis_cq_tkeep,
    input logic m_axis_cq_tlast,
    output logic m_axis_cq_tready,
    input logic [CQ_TUSER_WIDTH-1 : 0] m_axis_cq_tuser,
    input logic m_axis_cq_tvalid,

    output logic [IF_WIDTH-1 : 0] s_axis_rq_tdata,
    output logic [TKEEP_WIDTH - 1 : 0] s_axis_rq_tkeep,
    output logic s_axis_rq_tlast,
    input logic s_axis_rq_tready,
    output logic [RQ_TUSER_WIDTH-1 : 0] s_axis_rq_tuser,
    output logic s_axis_rq_tvalid
);
  localparam CQ_IF_WIDTH = IF_WIDTH;
  localparam RQ_IF_WIDTH = IF_WIDTH;
  logic is_sop;

  // Header beat
  always @(posedge user_clk or negedge sys_reset_n) begin
    if (user_rst | ~sys_reset_n) begin
      is_sop <= 1'b1;
    end else begin
      is_sop <= m_axis_cq_tvalid ? m_axis_cq_tlast : is_sop;
    end
  end

  always_comb begin
    m_axis_cq_tready = s_axis_rq_tready;
    s_axis_rq_tkeep  = m_axis_cq_tkeep;
    s_axis_rq_tlast  = m_axis_cq_tlast;
    s_axis_rq_tvalid = m_axis_cq_tvalid;
    unique case (CQ_IF_WIDTH)
      64, 128, 256: begin
        s_axis_rq_tuser = (RQ_IF_WIDTH == 512) ? {1'b0, m_axis_cq_tuser[107], 1'b0, m_axis_cq_tuser[106], 20'd0, m_axis_cq_tuser[105:86], {1'b0, m_axis_cq_tuser[85]}, 100'd0, m_axis_cq_tuser[41], 10'd0, 4'b1000, {1'd0, m_axis_cq_tuser[40]}, 4'd0, {4'd0, m_axis_cq_tuser[7:4]}, {4'd0,m_axis_cq_tuser[3:0]} } //FIXME
                            : { m_axis_cq_tuser[107:85], 38'd0, m_axis_cq_tuser[41], 3'd0, m_axis_cq_tuser[7:0]}; //FIXME : Untested
      end
      512: begin
        s_axis_rq_tuser = (RQ_IF_WIDTH == 512) ? { m_axis_cq_tuser[228:183], 100'd0, m_axis_cq_tuser[96:80], 4'd0, m_axis_cq_tuser[15:0]}
                            : {m_axis_cq_tuser[227], m_axis_cq_tuser[225], m_axis_cq_tuser[204:185], m_axis_cq_tuser[183], 38'd0, m_axis_cq_tuser[96], 3'd0, m_axis_cq_tuser[11:8], m_axis_cq_tuser[3:0]};
      end
    endcase
    s_axis_rq_tdata = {
      m_axis_cq_tdata[IF_WIDTH-1:121],
      (&(m_axis_cq_tdata[78:77] == 2'b11) | &(m_axis_cq_tdata[78:75] == 4'b0001)) ? ((m_axis_cq_tvalid & is_sop) | m_axis_cq_tdata[120]) : ((m_axis_cq_tvalid & is_sop) ? m_axis_cq_tdata[79] : m_axis_cq_tdata[120]),  // Only change in header beat
      m_axis_cq_tdata[119:80],
      (m_axis_cq_tvalid & is_sop) ? ((&(m_axis_cq_tdata[78:77] == 2'b11) | &(m_axis_cq_tdata[78:75] == 4'b0001)) ? m_axis_cq_tdata[79] : 1'b0) : m_axis_cq_tdata[79],  // Only change in header beat
      m_axis_cq_tdata[78:0]
    };
  end

endmodule
