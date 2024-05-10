`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AMD
// Engineer: Agastya Sampath
// 
// Create Date: 10/17/2023 10:38:33 AM
// Design Name: Switch State Machine
// Module Name: switch_state_machine
// Project Name: Two Port Switch (CPM5 DSP, PL-PCIe5 USP)
// Target Devices: xcvp1202-vsva2785-2MHP-e-S
// Tool Versions: 2023.2
// Description: State Machine on DSP for Switch
// 
// Dependencies: -
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module switch_state_machine (
    // Input - clock, reset and status signals
    input wire dsp_user_clk,
    input wire dsp_user_reset,
    input wire sys_reset_n,
    // Input - RQ converted to mgmt
    input logic [9 : 0] rq_cfg_mgmt_addr,
    input logic [15 : 0] rq_cfg_mgmt_function_number,
    input logic rq_cfg_mgmt_write,
    input logic [31 : 0] rq_cfg_mgmt_write_data,
    input logic [3 : 0] rq_cfg_mgmt_byte_enable,
    input logic rq_cfg_mgmt_read,
    input logic rq_cfg_mgmt_debug_access,
    // Input - USP Reset
    input wire usp_user_reset_dsp_domain,
    // Input - Bus numbers read
    input wire dsp_bus_num_rdy,
    input wire usp_bus_num_rdy,
    // Input - Routing select
    input wire [1:0] routing_select,
    // Input - Routing unsupported request
    input wire routing_unsupported_req,
    // Input - Routing request type
    input wire [3:0] routing_req_type,
    // Input - USP CC Tready at DSP RC (for combined MUX output)
    input wire dsp_m_axis_rc_tready_combined,
    // Output - Read Data for Completion to RQ CFG request
    output wire [31:0] cpl_data_DW_cfgrd_t1,
    // IO - Configuration Management (DSP)
    output wire [9 : 0] cfg_mgmt_addr,
    output wire [15 : 0] cfg_mgmt_function_number,
    output wire cfg_mgmt_write,
    output wire [31 : 0] cfg_mgmt_write_data,
    output wire [3 : 0] cfg_mgmt_byte_enable,
    output wire cfg_mgmt_read,
    input wire [31 : 0] cfg_mgmt_read_data,
    input wire cfg_mgmt_read_write_done,
    output wire cfg_mgmt_debug_access,
    // Output - Switch accept signals (pass to tready)
    output wire switch_usp_cq_accept,
    output wire switch_dsp_rc_accept,
    output wire switch_send_cfg_completion
);
  logic bus_numbers_read;

  logic [7:0] dsp_pri_bus_reg;  // For Bus REQ
  logic [7:0] dsp_sec_bus_reg;  // For Bus REQ
  logic [7:0] dsp_sub_bus_reg;  // For Bus REQ

  logic [31:0] cpl_data_reg;  // For MGMT CFG
  logic [31:0] next_cpl_data_reg;  // For MGMT CFG
  logic cpl_unsent;  // For MGMT CFG
  logic next_cpl_unsent;

  typedef enum logic [1:0] {
    IDLE = 2'd0,
    SWITCHING = 2'd1,
    // DSP_ROUTED_SWITCHING = 2'd2, // Will need to extend for multiple DSPs
    WAIT_CFG_DATA = 2'd2
  } switch_state_t;

  switch_state_t next_switch_state;
  switch_state_t switch_state;

  wire state_is_switching;
  assign state_is_switching = (switch_state == SWITCHING);

  // Only send in WAIT_CFG_DATA state
  assign cfg_mgmt_addr = (switch_state == WAIT_CFG_DATA) ? rq_cfg_mgmt_addr : 'd0;
  assign cfg_mgmt_function_number = (switch_state == WAIT_CFG_DATA) ? rq_cfg_mgmt_function_number : 'd0;
  assign cfg_mgmt_write = (switch_state == WAIT_CFG_DATA) ? rq_cfg_mgmt_write : 'd0;
  assign cfg_mgmt_write_data = (switch_state == WAIT_CFG_DATA) ? rq_cfg_mgmt_write_data : 'd0;
  assign cfg_mgmt_byte_enable = (switch_state == WAIT_CFG_DATA) ? rq_cfg_mgmt_byte_enable : 'd0;
  assign cfg_mgmt_read = (switch_state == WAIT_CFG_DATA) ? rq_cfg_mgmt_read : 'd0;
  assign cfg_mgmt_debug_access = (switch_state == WAIT_CFG_DATA) ? rq_cfg_mgmt_debug_access : 'd0;

  assign cpl_data_DW_cfgrd_t1 = cpl_data_reg;

  // Switch disabling and completion delivering logic
  assign switch_usp_cq_accept = ~next_cpl_unsent;
  assign switch_dsp_rc_accept = state_is_switching ? (~cpl_unsent & dsp_m_axis_rc_tready_combined) : dsp_m_axis_rc_tready_combined;
  assign switch_send_cfg_completion = state_is_switching ? ((cpl_unsent & dsp_m_axis_rc_tready_combined) | (routing_unsupported_req & &(routing_req_type != 4'b0001) & &(routing_req_type <= 4'b1011))) : 1'b0;


  always_comb begin
    next_cpl_unsent   = 'd0;
    next_cpl_data_reg = 'd0;
    next_switch_state = IDLE;

    // Assign next_switch_state
    if (usp_user_reset_dsp_domain) begin
      next_switch_state = IDLE;
    end else begin
      unique case (switch_state)
        IDLE: begin
          if (usp_bus_num_rdy) next_switch_state = SWITCHING;
          else next_switch_state = IDLE;
        end
        SWITCHING: begin
          if (routing_select == 2'd1 && ~cpl_unsent && ~routing_unsupported_req)
            next_switch_state = WAIT_CFG_DATA;
          else next_switch_state = SWITCHING;
        end
        WAIT_CFG_DATA: begin
          if (cfg_mgmt_read_write_done) next_switch_state = SWITCHING;
          else next_switch_state = WAIT_CFG_DATA;
        end
      endcase
    end

    // Assign next_cpl_unsent
    if (usp_user_reset_dsp_domain) begin
      next_cpl_unsent = 0;
    end else begin
      unique case (switch_state)
        IDLE: begin
          next_cpl_unsent = 0;
        end
        SWITCHING: begin
          if (routing_select == 2'd1 && ~cpl_unsent && ~routing_unsupported_req)
            next_cpl_unsent = 1'b1;
          else next_cpl_unsent = cpl_unsent & ~dsp_m_axis_rc_tready_combined;
        end
        WAIT_CFG_DATA: begin
          next_cpl_unsent = 1'b1;
        end
      endcase
    end

    // Assign next_cpl_data_reg
    if (usp_user_reset_dsp_domain) begin
      next_cpl_data_reg = 'b0;
    end else begin
      unique case (switch_state)
        IDLE: begin
          next_cpl_data_reg = 'b0;
        end
        SWITCHING: begin
          if (cpl_unsent & ~dsp_m_axis_rc_tready_combined) next_cpl_data_reg = 'b0;
          else next_cpl_data_reg = cpl_data_reg;
        end
        WAIT_CFG_DATA: begin
          if (cfg_mgmt_read_write_done) next_cpl_data_reg = cfg_mgmt_read_data;
          else next_cpl_data_reg = 'b0;
        end
      endcase
    end
  end

  // Sequential Logic
  always_ff @(posedge dsp_user_clk or negedge sys_reset_n) begin
    if (~sys_reset_n) begin
      switch_state <= IDLE;
      cpl_unsent   <= 0;
      cpl_data_reg <= 'b0;
    end else begin
      switch_state <= next_switch_state;
      cpl_unsent   <= next_cpl_unsent;
      cpl_data_reg <= next_cpl_data_reg;
    end
  end
endmodule
