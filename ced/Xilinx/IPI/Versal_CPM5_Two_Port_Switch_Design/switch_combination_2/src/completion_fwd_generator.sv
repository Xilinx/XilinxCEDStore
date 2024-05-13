`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AMD
// Engineer: Agastya Sampath
// 
// Create Date: 10/11/2023 10:20:30 AM
// Design Name: To-be-Forwarded Completion Generator
// Module Name: completion_fwd_generator
// Project Name: Two Port Switch (CPM5 DSP, PL-PCIe5 USP)
// Target Devices: xcvp1202-vsva2785-2MHP-e-S
// Tool Versions: 2023.2
// Description: Generates completion packet to be forwarded to the completion queue (one-wide)
// 
// Dependencies: -
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module completion_fwd_generator #(
    parameter DSP_IF_WIDTH = 512,
    parameter DSP_TKEEP_WIDTH = 16,
    parameter DSP_CQ_TUSER_WIDTH = 231,
    parameter DSP_RC_TUSER_WIDTH = 161
) (
    input logic [1:0] select,
    input logic unsupported_req,
    input logic [3:0] req_type,

    input logic [DSP_IF_WIDTH-1 : 0] dsp_m_axis_cq_tdata,
    input logic [DSP_TKEEP_WIDTH - 1 : 0] dsp_m_axis_cq_tkeep,
    input logic dsp_m_axis_cq_tlast,
    input logic [DSP_CQ_TUSER_WIDTH-1 : 0] dsp_m_axis_cq_tuser,
    input logic dsp_m_axis_cq_tvalid,

    output logic [DSP_IF_WIDTH-1 : 0] dsp_m_axis_rc_tdata,
    output logic [DSP_TKEEP_WIDTH-1 : 0] dsp_m_axis_rc_tkeep,
    output logic dsp_m_axis_rc_tlast,
    output logic [DSP_RC_TUSER_WIDTH-1 : 0] dsp_m_axis_rc_tuser,
    output logic dsp_m_axis_rc_tvalid
);
  always_comb begin
    if (dsp_m_axis_cq_tvalid & unsupported_req) begin
      // Unsupported Completion case
      dsp_m_axis_rc_tvalid = dsp_m_axis_cq_tvalid;
      dsp_m_axis_rc_tkeep = 'hFF;  // 256-bits of valid data,
      dsp_m_axis_rc_tuser = {
        64'b0,  // parity
        1'b0,  // discontinue
        4'b0000,  // is_eop_ptr3 
        4'b0000,  // is_eop_ptr2 
        4'b0000,  // is_eop_ptr1 
        4'b0000,  // is_eop_ptr0 
        4'b1,  // is_eop 
        2'b00,  // is_sop_ptr3 
        2'b00,  // is_sop_ptr2 
        2'b00,  // is_sop_ptr1 
        2'b00,  // is_sop_ptr0 
        4'b1,  // is_sop
        32'b0,
        {32{1'b1}}  // byte_en
      };
      dsp_m_axis_rc_tlast = 1'b1;
      dsp_m_axis_rc_tdata = {
        {(DSP_IF_WIDTH - 256) {1'b0}},
        dsp_m_axis_cq_tdata[127:0],  // 4 DW of request descriptor.
        {24'b0, dsp_m_axis_cq_tdata[135:128]},  // lastBE, firstBE.
        1'b0,  // Force ECRC
        dsp_m_axis_cq_tdata[126:124],  // Attr
        dsp_m_axis_cq_tdata[123:121],  // TC
        1'b0,  // Completer ID Enable in CC, Reserved in RC.
        dsp_m_axis_cq_tdata[119:104],  // Completer ID
        dsp_m_axis_cq_tdata[103:96],  // Tag
        dsp_m_axis_cq_tdata[95:80],  // Requester ID
        dsp_m_axis_cq_tdata[127],  // T9
        1'b0,  // Poisoned Completion
        3'b001,  // UR Completion Status
        11'b0,  // DW count for UR
        dsp_m_axis_cq_tdata[79],  // T8
        1'b0,  // Req Completed
        1'b0,  // Locked Read Completion
        13'h4,  // Byte count 0 for UR
        4'b0,  // Error code
        12'b0  // Address
      };
    end else if (dsp_m_axis_cq_tvalid & ~unsupported_req & &(select[1:0] == 2'b01)) begin
      // Config Completion
      dsp_m_axis_rc_tvalid = dsp_m_axis_cq_tvalid;
      dsp_m_axis_rc_tkeep = (req_type == 4'b1011) ? 'h07 : 'h0F;
      dsp_m_axis_rc_tuser = {
        32'h0,  // upper odd parity
        32'h0,  // lower odd parity 
        1'b0,  // discontinue
        16'b0000_0000_0000_0011,  // is_eop_ptr
        4'b0001,  // is_eop
        8'b00000000,  // is_sop_ptr
        4'b0001,  // is_sop
        32'd0,  // upper BE
        {16'h0, dsp_m_axis_cq_tuser[3:0], 12'h0}  // lower BE
      };
      dsp_m_axis_rc_tlast = 1'b1;
      dsp_m_axis_rc_tdata = {
        {(DSP_IF_WIDTH - 128) {1'b0}},
        32'b0,  // Insert Completion Data Here before sending
        1'b0,  // Force ECRC
        dsp_m_axis_cq_tdata[126:124],  // Attr
        dsp_m_axis_cq_tdata[123:121],  // TC
        1'b1,  // Completer ID Enable in CC, Reserved in RC.
        dsp_m_axis_cq_tdata[119:104],  // Completer ID
        dsp_m_axis_cq_tdata[103:96],  // Tag
        dsp_m_axis_cq_tdata[95:80],  // Requester ID
        dsp_m_axis_cq_tdata[127],  // T9
        1'b0,  // Poisoned Completion
        3'b000,  // Successful Completion Status
        (req_type == 4'b1011) ? 11'b0 : 11'b1,  // DW count for UR
        dsp_m_axis_cq_tdata[79],  // T8
        1'b1,  // Req Completed
        1'b0,  // Locked Read Completion
        13'h4,  // Byte count 4 for CFG completion
        4'b0,  // Error code
        12'b0  // Address
      };
    end else begin
      // Garbage
      dsp_m_axis_rc_tvalid = 'b0;
      dsp_m_axis_rc_tuser  = 'b0;
      dsp_m_axis_rc_tkeep  = 'b0;
      dsp_m_axis_rc_tlast  = 'b0;
      dsp_m_axis_rc_tdata  = 'b0;
    end
  end
endmodule
