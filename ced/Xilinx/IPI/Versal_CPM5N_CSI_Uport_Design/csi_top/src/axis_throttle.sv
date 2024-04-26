`timescale 1ps / 1ps

module axis_throttle #(
  parameter SEED        = 32'hb105f00d,         // rand_num seed
  parameter NUM_INTFC   = 32'h4,
  parameter TCQ         = 1
)(
  // Global
  input logic                       user_clk,
  input logic                       user_reset_n,
  
  // Control
  input logic [NUM_INTFC-1:0]       back_pres,  // Bit[0] = BP ctrl msgst. Bit[1] = BP ctrl msgld. Bit[2] = BP ctrl rsp.
                                                // Value 1= randomly deasserts valid/ready to create backpressure. 0= Normal operation (bypass)
  input logic [NUM_INTFC-1:0]       halt,       // Bit[0] = BP ctrl msgst. Bit[1] = BP ctrl msgld. Bit[2] = BP ctrl rsp.
                                                // Value 1= Stops Transfer Immediately. 0= Normal operation (bypass)
  
  ////// Traffic Generator Side
  ////cdx5n_cmpt_msgst_if.s             fab0_cmpt_msgst_fab_int_tg,
  ////cdx5n_mm_byp_out_rsp_if.m         fab0_byp_out_msgld_dat_fab_int_tg,
  ////cdx5n_dsc_crd_in_msgld_req_if.s   fab0_dsc_crd_msgld_req_fab_int_tg,
  ////
  ////// CPM5N Side
  ////cdx5n_cmpt_msgst_if.m             fab0_cmpt_msgst_fab_int,
  ////cdx5n_mm_byp_out_rsp_if.s         fab0_byp_out_msgld_dat_fab_int,
  ////cdx5n_dsc_crd_in_msgld_req_if.m   fab0_dsc_crd_msgld_req_fab_int

  input  logic [NUM_INTFC-1:0]      valid_i,
  input  logic [NUM_INTFC-1:0]      ready_i,
  output logic [NUM_INTFC-1:0]      valid_o,
  output logic [NUM_INTFC-1:0]      ready_o
);

logic  [31:0]               rand_num = SEED; // Random Number
logic  [31:0]               counter  = 32'b0;

always @(posedge user_clk) begin
  counter <= counter + 1'b1;
end
// Random Number Generator
always @(posedge user_clk) begin
  rand_num[0] <= #TCQ rand_num[31];
  rand_num[1] <= #TCQ rand_num[0] ^ rand_num[0];
  rand_num[2] <= #TCQ rand_num[1] ^ rand_num[0];
  rand_num[3] <= #TCQ rand_num[2] ^ rand_num[0];
  rand_num[4] <= #TCQ rand_num[3] ^ rand_num[0];
  rand_num[5] <= #TCQ rand_num[4] ^ rand_num[0];
  rand_num[6] <= #TCQ rand_num[5] ^ rand_num[0];
  rand_num[7]  <= #TCQ rand_num[6];
  rand_num[8]  <= #TCQ rand_num[7];
  rand_num[9]  <= #TCQ rand_num[8];
  rand_num[10] <= #TCQ rand_num[9];
  rand_num[11] <= #TCQ rand_num[10];
  rand_num[12] <= #TCQ rand_num[11];
  rand_num[13] <= #TCQ rand_num[12];
  rand_num[14] <= #TCQ rand_num[13];
  rand_num[15] <= #TCQ rand_num[14];
  rand_num[16] <= #TCQ rand_num[15] ^ rand_num[1];
  rand_num[17] <= #TCQ rand_num[16] ^ rand_num[1];
  rand_num[18] <= #TCQ rand_num[17] ^ rand_num[1];
  rand_num[19] <= #TCQ rand_num[18] ^ rand_num[1];
  rand_num[20] <= #TCQ rand_num[19] ^ rand_num[1];
  rand_num[21] <= #TCQ rand_num[20] ^ rand_num[1];
  rand_num[22] <= #TCQ rand_num[21] ^ rand_num[1];
  rand_num[23] <= #TCQ rand_num[22] ^ rand_num[1];
  rand_num[24]  <= #TCQ rand_num[23];
  rand_num[25]  <= #TCQ rand_num[24];
  rand_num[26]  <= #TCQ ~rand_num[25];
  rand_num[27]  <= #TCQ ~rand_num[26];
  rand_num[28]  <= #TCQ ~rand_num[27];
  rand_num[29]  <= #TCQ ~rand_num[28];
  rand_num[30]  <= #TCQ ~rand_num[29];
  rand_num[31]  <= #TCQ ~rand_num[30];
end

////// MSGST Backpressure
////assign fab0_cmpt_msgst_fab_int.vld            = (halt[0] | (back_pres[0] & rand_num[8]))  ? 1'b0 : fab0_cmpt_msgst_fab_int_tg.vld;
////assign fab0_cmpt_msgst_fab_int_tg.rdy         = (halt[0] | (back_pres[0] & rand_num[8]))  ? 1'b0 : fab0_cmpt_msgst_fab_int.rdy;
////
////// MSGLD Backpressure
////assign fab0_dsc_crd_msgld_req_fab_int.vld     = (halt[1] | (back_pres[1] & rand_num[15])) ? 1'b0 : fab0_dsc_crd_msgld_req_fab_int_tg.vld;
////assign fab0_dsc_crd_msgld_req_fab_int_tg.rdy  = (halt[1] | (back_pres[1] & rand_num[15])) ? 1'b0 : fab0_dsc_crd_msgld_req_fab_int.rdy;
////
////// RSP Backpressure
////assign fab0_byp_out_msgld_dat_fab_int_tg.vld  = (halt[2] | (back_pres[2] & rand_num[25])) ? 1'b0 : fab0_byp_out_msgld_dat_fab_int.vld;
////assign fab0_byp_out_msgld_dat_fab_int.rdy     = (halt[2] | (back_pres[2] & rand_num[25])) ? 1'b0 : fab0_byp_out_msgld_dat_fab_int_tg.rdy;
////
////// Pass-through the rest of the interface
////assign fab0_cmpt_msgst_fab_int.intf           = fab0_cmpt_msgst_fab_int_tg.intf;
////assign fab0_byp_out_msgld_dat_fab_int_tg.intf = fab0_byp_out_msgld_dat_fab_int.intf;
////assign fab0_dsc_crd_msgld_req_fab_int.intf    = fab0_dsc_crd_msgld_req_fab_int_tg.intf;

assign valid_o[0]            = (halt[0] | ((back_pres[0]) & ( rand_num[0] | counter[12]))) ? 1'b0 : valid_i[0];
assign valid_o[1]            = (halt[0] | ((back_pres[0]) & ( rand_num[0] | counter[12]))) ? 1'b0 : valid_i[1];
assign valid_o[2]            = (halt[2] | ((back_pres[2]) & ( rand_num[2] | counter[12]))) ? 1'b0 : valid_i[2];
assign valid_o[3]            = (halt[3] | ((back_pres[3]) & ( rand_num[3] | counter[12]))) ? 1'b0 : valid_i[3];
assign valid_o[4]            = (halt[3] | ((back_pres[3]) & ( rand_num[3] | counter[12]))) ? 1'b0 : valid_i[4];
assign valid_o[5]            = (halt[5] | ((back_pres[5]) & ( rand_num[5] | counter[12]))) ? 1'b0 : valid_i[5];
assign valid_o[6]            = (halt[6] | ((back_pres[6]) & ( rand_num[6] | counter[12]))) ? 1'b0 : valid_i[6];

assign ready_o[0]            = (halt[0] | ((back_pres[0]) & ( rand_num[0] | counter[12]))) ? 1'b0 : ready_i[0];
assign ready_o[1]            = (halt[0] | ((back_pres[0]) & ( rand_num[0] | counter[12]))) ? 1'b0 : ready_i[1];
assign ready_o[2]            = (halt[2] | ((back_pres[2]) & ( rand_num[2] | counter[12]))) ? 1'b0 : ready_i[2];
assign ready_o[3]            = (halt[3] | ((back_pres[3]) & ( rand_num[3] | counter[12]))) ? 1'b0 : ready_i[3];
assign ready_o[4]            = (halt[3] | ((back_pres[3]) & ( rand_num[3] | counter[12]))) ? 1'b0 : ready_i[4];
assign ready_o[5]            = (halt[5] | ((back_pres[5]) & ( rand_num[5] | counter[12]))) ? 1'b0 : ready_i[5];
assign ready_o[6]            = (halt[6] | ((back_pres[6]) & ( rand_num[6] | counter[12]))) ? 1'b0 : ready_i[6];

endmodule
