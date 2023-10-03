`timescale 1 ps / 1 ps

module dsc_byp_c2h
  (
   
   input [1:0] c2h_dsc_bypass,
   input c2h_mm_marker_req,
   output c2h_mm_marker_rsp,
   output logic                                                           c2h_st_marker_rsp,
   input  logic [255:0]                                                   c2h_byp_out_dsc,
   input  logic                                                           c2h_byp_out_mrkr_rsp,
   input  logic                                                           c2h_byp_out_st_mm,
   input  logic [1:0]                                                     c2h_byp_out_dsc_sz,
   input  logic [10:0]                                                    c2h_byp_out_qid,
   input  logic                                                           c2h_byp_out_error,
   input  logic [7:0]                                                     c2h_byp_out_func,
   input  logic [15:0]                                                    c2h_byp_out_cidx,
   input  logic [2:0]                                                     c2h_byp_out_port_id,
   input  logic                                                           c2h_byp_out_vld,
   output logic                                                           c2h_byp_out_rdy,
   
   output   logic [63:0]                                                    c2h_byp_in_mm_radr,
   output   logic [63:0]                                                    c2h_byp_in_mm_wadr,
   output   logic [27:0]                                                    c2h_byp_in_mm_len,
   output   logic                                                           c2h_byp_in_mm_mrkr_req,
   output   logic                                                           c2h_byp_in_mm_sdi,
   output   logic [10:0]                                                    c2h_byp_in_mm_qid,
   output   logic                                                           c2h_byp_in_mm_error,
   output   logic [7:0]                                                     c2h_byp_in_mm_func,
   output   logic [15:0]                                                    c2h_byp_in_mm_cidx,
   output   logic [2:0]                                                     c2h_byp_in_mm_port_id,
   output   logic                                                           c2h_byp_in_mm_no_dma,
   output   logic                                                           c2h_byp_in_mm_vld,
   input    logic                                                           c2h_byp_in_mm_rdy,

   output   logic [63:0]                                                    c2h_byp_in_st_csh_addr,
   output   logic [10:0]                                                    c2h_byp_in_st_csh_qid,
   output   logic                                                           c2h_byp_in_st_csh_error,
   output   logic [7:0]                                                     c2h_byp_in_st_csh_func,
   output   logic [2:0]                                                     c2h_byp_in_st_csh_port_id,
   output   logic                                                           c2h_byp_in_st_csh_vld,
   input    logic                                                           c2h_byp_in_st_csh_rdy,

   output   logic [63:0]                                                    c2h_byp_in_st_sim_addr,
   output   logic [10:0]                                                    c2h_byp_in_st_sim_qid,
   output   logic                                                           c2h_byp_in_st_sim_error,
   output   logic [7:0]                                                     c2h_byp_in_st_sim_func,
   output   logic [2:0]                                                     c2h_byp_in_st_sim_port_id,
   output   logic                                                           c2h_byp_in_st_sim_vld,
   input    logic                                                           c2h_byp_in_st_sim_rdy

   );

   wire 								    c2h_csh_byp;
   wire 								    c2h_sim_byp;

   // c2h_csh_byp is used for C2H St Cash Bypass and also C2H MM bypass looback.
   assign c2h_csh_byp = (c2h_dsc_bypass == 2'b01) ? 1'b1 : 1'b0; // 2'b01 : Cache dsc bypass/MM
   assign c2h_sim_byp = (c2h_dsc_bypass == 2'b10) ? 1'b1 : 1'b0; // 2'b10 : Simple dsc_bypass
   
//   assign c2h_st_marker_rsp = c2h_byp_out_rdy & c2h_byp_out_mrkr_rsp & c2h_byp_out_vld;
   assign c2h_st_marker_rsp = c2h_byp_out_mrkr_rsp & c2h_byp_out_vld & ~c2h_byp_out_st_mm;
   assign c2h_mm_marker_rsp = c2h_byp_out_mrkr_rsp & c2h_byp_out_vld & c2h_byp_out_st_mm;

   assign c2h_byp_out_rdy        = c2h_byp_out_mrkr_rsp ? 1'b1 :
				   c2h_csh_byp & c2h_byp_out_st_mm ? c2h_byp_in_mm_rdy :
				   c2h_csh_byp & ~c2h_byp_out_st_mm ? c2h_byp_in_st_csh_rdy :
				   c2h_sim_byp ? c2h_byp_in_st_sim_rdy : 1'b1;

// MM
   assign c2h_byp_in_mm_mrkr_req = c2h_mm_marker_req;
   assign c2h_byp_in_mm_radr     = c2h_byp_out_dsc[63:0];
   assign c2h_byp_in_mm_wadr     = c2h_byp_out_dsc[191:128];
   assign c2h_byp_in_mm_len      = c2h_byp_out_dsc[91:64];
//   assign c2h_byp_in_mm_sdi      = 1'b1;
   assign c2h_byp_in_mm_sdi      = c2h_byp_out_dsc[94];  // eop. send sdi at last desciptor.
   assign c2h_byp_in_mm_qid      = c2h_byp_out_qid;
   assign c2h_byp_in_mm_error    = c2h_byp_out_error;
   assign c2h_byp_in_mm_func     = c2h_byp_out_func;
   assign c2h_byp_in_mm_cidx     = c2h_byp_out_cidx;
   assign c2h_byp_in_mm_port_id  = c2h_byp_out_port_id;
   assign c2h_byp_in_mm_no_dma   = 1'b0;
   assign c2h_byp_in_mm_vld      = c2h_dsc_bypass & ~c2h_byp_out_mrkr_rsp ? c2h_byp_out_st_mm & c2h_byp_out_vld : 1'b0;
//   assign c2h_byp_in_mm_vld      = c2h_mm_marker_req | (c2h_csh_byp & ~c2h_byp_out_mrkr_rsp ? c2h_byp_out_st_mm & c2h_byp_out_vld : 1'b0);

//ST Cache mode
   assign c2h_byp_in_st_csh_addr     = c2h_byp_out_dsc[63:0];
   assign c2h_byp_in_st_csh_qid      = c2h_byp_out_qid;
   assign c2h_byp_in_st_csh_error    = c2h_byp_out_error;
   assign c2h_byp_in_st_csh_func     = c2h_byp_out_func;
   assign c2h_byp_in_st_csh_port_id  = c2h_byp_out_port_id;
   assign c2h_byp_in_st_csh_vld      = c2h_csh_byp & ~c2h_byp_out_mrkr_rsp ? ~c2h_byp_out_st_mm & c2h_byp_out_vld : 1'b0;

//ST Simple mode
   assign c2h_byp_in_st_sim_addr     = c2h_byp_out_dsc[63:0];
   assign c2h_byp_in_st_sim_qid      = c2h_byp_out_qid;
   assign c2h_byp_in_st_sim_error    = c2h_byp_out_error;
   assign c2h_byp_in_st_sim_func     = c2h_byp_out_func;
   assign c2h_byp_in_st_sim_port_id  = c2h_byp_out_port_id;
   assign c2h_byp_in_st_sim_vld      = c2h_sim_byp & ~c2h_byp_out_mrkr_rsp ? ~c2h_byp_out_st_mm & c2h_byp_out_vld : 1'b0;

endmodule // dsc_bypass
