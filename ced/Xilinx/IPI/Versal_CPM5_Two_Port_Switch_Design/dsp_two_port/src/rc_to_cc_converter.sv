`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AMD
// Engineer: Agastya Sampath
// 
// Create Date: 10/11/2023 04:57:06 PM
// Design Name: RC to CC Converter
// Module Name: rc_to_cc_converter
// Project Name: Two Port Switch (CPM5 DSP, PL-PCIe5 USP)
// Target Devices: xcvp1202-vsva2785-2MHP-e-S
// Tool Versions: 2023.2
// Description: Converts RC packet to CC packet
// 
// Dependencies: -
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rc_to_cc_converter #(
    parameter IF_WIDTH = 512,
    parameter TKEEP_WIDTH = 16,
    parameter RC_TUSER_WIDTH = 161,
    parameter CC_TUSER_WIDTH = 81
) (
    input logic user_clk,
    input logic user_rst,
    input logic sys_reset_n,

    input logic s_axis_cc_tready,
    output logic [IF_WIDTH-1 : 0] s_axis_cc_tdata,
    output logic [TKEEP_WIDTH-1 : 0] s_axis_cc_tkeep,
    output logic s_axis_cc_tlast,
    output logic [CC_TUSER_WIDTH-1 : 0] s_axis_cc_tuser,
    output logic s_axis_cc_tvalid,

    input logic [IF_WIDTH-1 : 0] m_axis_rc_tdata,
    input logic [TKEEP_WIDTH-1 : 0] m_axis_rc_tkeep,
    input logic m_axis_rc_tlast,
    output logic m_axis_rc_tready,
    input logic [RC_TUSER_WIDTH-1 : 0] m_axis_rc_tuser,
    input logic m_axis_rc_tvalid
);
  localparam RC_IF_WIDTH = IF_WIDTH;
  localparam CC_IF_WIDTH = IF_WIDTH;

  logic is_sop;

  // Identify header beat
  always @(posedge user_clk or negedge sys_reset_n) begin
    if (user_rst | ~sys_reset_n) begin
      is_sop <= 1'b1;
    end else begin
      is_sop <= m_axis_rc_tvalid ? m_axis_rc_tlast : is_sop;
    end
  end

  always_comb begin
    m_axis_rc_tready = s_axis_cc_tready;
    s_axis_cc_tvalid = m_axis_rc_tvalid;
    s_axis_cc_tlast  = m_axis_rc_tlast;
    s_axis_cc_tkeep  = m_axis_rc_tkeep;
    unique case (RC_IF_WIDTH)
      64, 128, 256: begin
        s_axis_cc_tuser = (CC_IF_WIDTH == 512) ? {64'b0, m_axis_rc_tuser[42], {1'b0,m_axis_rc_tuser[41:39]}, {1'b0,m_axis_rc_tuser[37:35]}, m_axis_rc_tuser[38], m_axis_rc_tuser[34], 2'b10, 2'b00, m_axis_rc_tuser[33:32]} //FIXME : Untested
                            : {32'b0, m_axis_rc_tuser[42]};
      end
      512: begin
        s_axis_cc_tuser = (CC_IF_WIDTH == 512) ? {64'b0, m_axis_rc_tuser[96], m_axis_rc_tuser[87:80], m_axis_rc_tuser[77:76], m_axis_rc_tuser[71:68], m_axis_rc_tuser[65:64]}
                            : {32'b0, m_axis_rc_tuser[96]};
      end
    endcase
    s_axis_cc_tdata = {
      m_axis_rc_tdata[IF_WIDTH-1:96],
      m_axis_rc_tdata[95], 
      m_axis_rc_tdata[94:89],
      m_axis_rc_tdata[88] | (m_axis_rc_tvalid & is_sop),  // Only change data in header beat
      m_axis_rc_tdata[87:10],
      m_axis_rc_tdata[9:8], 
      m_axis_rc_tdata[7:0]
    };
  end

endmodule
