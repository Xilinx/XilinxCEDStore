`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AMD 
// Engineer: Agastya Sampath 
// 
// Create Date: 10/10/2023 05:54:36 PM
// Design Name: Switch Logic 
// Module Name: switch_logic
// Project Name: Two Port Switch (CPM5 USP, PL-PCIe5 DSP) 
// Target Devices: xcvp1202-vsva2785-2MHP-e-S 
// Tool Versions: 2023.2 
// Description: USP CPM5, DSP PL-PCIe5 - Main Switch Logic
// 
// Dependencies: - 
// -
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module switch_logic #(
    // Parameters - Switch
    parameter TCQ = 1,
    // Parameters - DSP
    parameter DSP_IF_WIDTH = 512,
    parameter DSP_RQ_TUSER_WIDTH = 183, //<256b and 512b are the only supported IF widths for PL-PCIe5
    parameter DSP_RC_TUSER_WIDTH = 161,
    parameter DSP_CQ_TUSER_WIDTH = 231,
    parameter DSP_CC_TUSER_WIDTH = 81,
    parameter DSP_TKEEP_WIDTH = 16,
    
    // Parameters - USP
    parameter USP_IF_WIDTH = 512,
    parameter USP_RQ_TUSER_WIDTH = 183, //<256b, 512b and 1024b are the only supported IF widths for CPM5
    parameter USP_RC_TUSER_WIDTH = 161,
    parameter USP_CQ_TUSER_WIDTH = 232,
    parameter USP_CC_TUSER_WIDTH = 81,
    parameter USP_TKEEP_WIDTH = 16
    ) (
    // Downstream Port Connections
    dsp_s_axis_rq_tdata,
    dsp_s_axis_rq_tkeep,
    dsp_s_axis_rq_tlast,
    dsp_s_axis_rq_tready,
    dsp_s_axis_rq_tuser,
    dsp_s_axis_rq_tvalid,

    dsp_m_axis_rc_tdata,
    dsp_m_axis_rc_tkeep,
    dsp_m_axis_rc_tlast,
    dsp_m_axis_rc_tready,
    dsp_m_axis_rc_tuser,
    dsp_m_axis_rc_tvalid,

    dsp_m_axis_cq_tdata,
    dsp_m_axis_cq_tkeep,
    dsp_m_axis_cq_tlast,
    dsp_m_axis_cq_tready,
    dsp_m_axis_cq_tuser,
    dsp_m_axis_cq_tvalid,

    dsp_s_axis_cc_tdata,
    dsp_s_axis_cc_tkeep,
    dsp_s_axis_cc_tlast,
    dsp_s_axis_cc_tready,
    dsp_s_axis_cc_tuser,
    dsp_s_axis_cc_tvalid,

    // Upstream Port Connections
    usp_s_axis_rq_tready,
    usp_s_axis_rq_tdata,
    usp_s_axis_rq_tkeep,
    usp_s_axis_rq_tlast,
    usp_s_axis_rq_tuser,
    usp_s_axis_rq_tvalid,

    usp_s_axis_cc_tready,
    usp_s_axis_cc_tdata,
    usp_s_axis_cc_tkeep,
    usp_s_axis_cc_tlast,
    usp_s_axis_cc_tuser,
    usp_s_axis_cc_tvalid,

    usp_m_axis_rc_tdata,
    usp_m_axis_rc_tkeep,
    usp_m_axis_rc_tlast,
    usp_m_axis_rc_tready,
    usp_m_axis_rc_tuser,
    usp_m_axis_rc_tvalid,

    usp_m_axis_cq_tdata,
    usp_m_axis_cq_tkeep,
    usp_m_axis_cq_tlast,
    usp_m_axis_cq_tready,
    usp_m_axis_cq_tuser,
    usp_m_axis_cq_tvalid,

    // usp_pcie_cfg_status_cq_np_req,

    // Configuration Extended Interface (USP) (for snooping bus numbers)
    cfg_ext_write_received,
    cfg_ext_register_number,
    cfg_ext_function_number,
    cfg_ext_write_data,
    cfg_ext_write_byte_enable,

    // Configuration Management Interface (DSP) (for Config Requests)
    cfg_mgmt_addr,
    cfg_mgmt_function_number,
    cfg_mgmt_write,
    cfg_mgmt_write_data,
    cfg_mgmt_byte_enable,
    cfg_mgmt_read,
    cfg_mgmt_read_data,
    cfg_mgmt_read_write_done,
    cfg_mgmt_debug_access,

    // Clocks and Reset - Global
    sys_reset_n,

    // Clocks and Reset - USP
    usp_user_clk,
    usp_user_reset,

    // Clocks and Reset - DSP
    dsp_user_clk,
    dsp_user_reset,

    // Misc - DSP
    dsp_user_lnk_up  // Will need it to check if link is/was up, since Switch logic is sequential
);

  // IO Port declarations - DSP
  output wire [DSP_IF_WIDTH-1 : 0] dsp_s_axis_rq_tdata;
  output wire [DSP_TKEEP_WIDTH - 1 : 0] dsp_s_axis_rq_tkeep;
  output wire dsp_s_axis_rq_tlast;
  input wire [3 : 0] dsp_s_axis_rq_tready;
  output wire [DSP_RQ_TUSER_WIDTH-1 : 0] dsp_s_axis_rq_tuser;
  output wire dsp_s_axis_rq_tvalid;

  input wire [DSP_IF_WIDTH-1 : 0] dsp_m_axis_rc_tdata;
  input wire [DSP_TKEEP_WIDTH - 1 : 0] dsp_m_axis_rc_tkeep;
  input wire dsp_m_axis_rc_tlast;
  output wire dsp_m_axis_rc_tready;
  input wire [DSP_RC_TUSER_WIDTH-1 : 0] dsp_m_axis_rc_tuser;
  input wire dsp_m_axis_rc_tvalid;

  input wire [DSP_IF_WIDTH-1 : 0] dsp_m_axis_cq_tdata;
  input wire [DSP_TKEEP_WIDTH - 1 : 0] dsp_m_axis_cq_tkeep;
  input wire dsp_m_axis_cq_tlast;
  output wire dsp_m_axis_cq_tready;
  input wire [DSP_CQ_TUSER_WIDTH-1 : 0] dsp_m_axis_cq_tuser;
  input wire dsp_m_axis_cq_tvalid;

  output wire [DSP_IF_WIDTH-1 : 0] dsp_s_axis_cc_tdata;
  output wire [DSP_TKEEP_WIDTH - 1 : 0] dsp_s_axis_cc_tkeep;
  output wire dsp_s_axis_cc_tlast;
  input wire [3 : 0] dsp_s_axis_cc_tready;
  output wire [DSP_CC_TUSER_WIDTH-1 : 0] dsp_s_axis_cc_tuser;
  output wire dsp_s_axis_cc_tvalid;

  // IO Port declarations - USP
  input wire usp_s_axis_rq_tready;
  output wire [USP_IF_WIDTH-1 : 0] usp_s_axis_rq_tdata;
  output wire [USP_TKEEP_WIDTH-1 : 0] usp_s_axis_rq_tkeep;
  output wire usp_s_axis_rq_tlast;
  output wire [USP_RQ_TUSER_WIDTH-1 : 0] usp_s_axis_rq_tuser;
  output wire usp_s_axis_rq_tvalid;

  input wire usp_s_axis_cc_tready;
  output wire [USP_IF_WIDTH-1 : 0] usp_s_axis_cc_tdata;
  output wire [USP_TKEEP_WIDTH-1 : 0] usp_s_axis_cc_tkeep;
  output wire usp_s_axis_cc_tlast;
  output wire [USP_CC_TUSER_WIDTH-1 : 0] usp_s_axis_cc_tuser;
  output wire usp_s_axis_cc_tvalid;

  input wire [USP_IF_WIDTH-1 : 0] usp_m_axis_rc_tdata;
  input wire [USP_TKEEP_WIDTH-1 : 0] usp_m_axis_rc_tkeep;
  input wire usp_m_axis_rc_tlast;
  output wire usp_m_axis_rc_tready;
  input wire [USP_RC_TUSER_WIDTH-1 : 0] usp_m_axis_rc_tuser;
  input wire usp_m_axis_rc_tvalid;

  input wire [USP_IF_WIDTH-1 : 0] usp_m_axis_cq_tdata;
  input wire [USP_TKEEP_WIDTH-1 : 0] usp_m_axis_cq_tkeep;
  input wire usp_m_axis_cq_tlast;
  output wire usp_m_axis_cq_tready;
  input wire [USP_CQ_TUSER_WIDTH-1 : 0] usp_m_axis_cq_tuser;
  input wire usp_m_axis_cq_tvalid;

  //   output wire usp_pcie_cfg_status_cq_np_req;

  // IO Port declarations - Configuration Extended (USP)
  input wire cfg_ext_write_received;
  input wire [9:0] cfg_ext_register_number;
  input wire [15:0] cfg_ext_function_number;
  input wire [31:0] cfg_ext_write_data;
  input wire [3:0] cfg_ext_write_byte_enable;

  // IO Port declarations - Configuration Management (DSP)
  output wire [9 : 0] cfg_mgmt_addr;
  output wire [7 : 0] cfg_mgmt_function_number;
  output wire cfg_mgmt_write;
  output wire [31 : 0] cfg_mgmt_write_data;
  output wire [3 : 0] cfg_mgmt_byte_enable;
  output wire cfg_mgmt_read;
  input wire [31 : 0] cfg_mgmt_read_data;
  input wire cfg_mgmt_read_write_done;
  output wire cfg_mgmt_debug_access;

  // Clocks and Reset - Global
  input wire sys_reset_n;

  // Clocks and Reset - USP
  input wire usp_user_clk;
  input wire usp_user_reset;

  // Clocks and Reset - DSP
  input wire dsp_user_clk;
  input wire dsp_user_reset;

  // Misc - DSP
  input wire dsp_user_lnk_up;

  // Internal signals - USP CQ to DSP RQ line
  wire [7:0] usp_pri_bus;
  wire [7:0] usp_sec_bus;
  wire [7:0] usp_sub_bus;
  wire usp_bus_num_rdy;
  wire usp_unsupported_req;

  wire usp_user_reset_dsp_domain;

  wire [7:0] usp_sec_bus_dsp_domain;

  wire [USP_IF_WIDTH-1 : 0] usp_m_axis_cq_tdata_for_rq_post_routing;
  wire [USP_TKEEP_WIDTH-1 : 0] usp_m_axis_cq_tkeep_for_rq_post_routing;
  wire usp_m_axis_cq_tlast_for_rq_post_routing;
  wire usp_m_axis_cq_tready_for_rq_post_routing;
  wire usp_m_axis_cq_tvalid_for_rq_post_routing;
  wire [USP_CQ_TUSER_WIDTH-1:0] usp_m_axis_cq_tuser_for_rq_post_routing;

  wire [DSP_IF_WIDTH-1 : 0] dsp_m_axis_cq_tdata_for_rq_pre_routing;
  wire [DSP_TKEEP_WIDTH-1 : 0] dsp_m_axis_cq_tkeep_for_rq_pre_routing;
  wire dsp_m_axis_cq_tlast_for_rq_pre_routing;
  wire dsp_m_axis_cq_tready_for_rq_pre_routing;
  wire dsp_m_axis_cq_tvalid_for_rq_pre_routing;
  wire [DSP_CQ_TUSER_WIDTH-1:0] dsp_m_axis_cq_tuser_for_rq_pre_routing;

  wire [7:0] dsp_pri_bus;
  wire [7:0] dsp_sec_bus;
  wire [7:0] dsp_sub_bus;
  wire dsp_bus_num_rdy;

  wire [DSP_IF_WIDTH-1 : 0] dsp_m_axis_cq_tdata_for_rq_post_routing;
  wire [DSP_TKEEP_WIDTH-1 : 0] dsp_m_axis_cq_tkeep_for_rq_post_routing;
  wire dsp_m_axis_cq_tlast_for_rq_post_routing;
  wire dsp_m_axis_cq_tready_for_rq_post_routing;
  wire dsp_m_axis_cq_tvalid_for_rq_post_routing;
  wire [DSP_CQ_TUSER_WIDTH-1:0] dsp_m_axis_cq_tuser_for_rq_post_routing;

  wire [1:0] routing_select;
  wire routing_unsupported_req;
  wire [3:0] routing_req_type;

// Only allow requests to be checked for valid data
  assign routing_req_type = dsp_m_axis_cq_tvalid_for_rq_post_routing ? dsp_m_axis_cq_tdata_for_rq_post_routing[78:75] : 4'b1111;

  wire [DSP_IF_WIDTH-1 : 0] dsp_s_axis_rq_tdata_candidate_1;
  wire [DSP_TKEEP_WIDTH - 1 : 0] dsp_s_axis_rq_tkeep_candidate_1;
  wire dsp_s_axis_rq_tlast_candidate_1;
  wire [3 : 0] dsp_s_axis_rq_tready_candidate_1;
  wire [DSP_RQ_TUSER_WIDTH-1 : 0] dsp_s_axis_rq_tuser_candidate_1;
  wire dsp_s_axis_rq_tvalid_candidate_1;

  wire [DSP_IF_WIDTH-1 : 0] dsp_s_axis_rq_tdata_candidate_2;
  wire [DSP_TKEEP_WIDTH - 1 : 0] dsp_s_axis_rq_tkeep_candidate_2;
  wire dsp_s_axis_rq_tlast_candidate_2;
  wire [3 : 0] dsp_s_axis_rq_tready_candidate_2;
  wire [DSP_RQ_TUSER_WIDTH-1 : 0] dsp_s_axis_rq_tuser_candidate_2;
  wire dsp_s_axis_rq_tvalid_candidate_2;

  wire [9 : 0] dsp_rq_cfg_mgmt_addr;
  wire [7 : 0] dsp_rq_cfg_mgmt_function_number;
  wire dsp_rq_cfg_mgmt_write;
  wire [31 : 0] dsp_rq_cfg_mgmt_write_data;
  wire [3 : 0] dsp_rq_cfg_mgmt_byte_enable;
  wire dsp_rq_cfg_mgmt_read;
  wire [31 : 0] dsp_rq_cfg_mgmt_read_data;
  wire dsp_rq_cfg_mgmt_read_write_done;
  wire dsp_rq_cfg_mgmt_debug_access;

  wire switch_usp_cq_accept;

  // Internal signals - DSP RC to USP CC line
  wire [DSP_IF_WIDTH-1 : 0] dsp_m_axis_rc_tdata_combined;
  wire [DSP_TKEEP_WIDTH - 1 : 0] dsp_m_axis_rc_tkeep_combined;
  wire dsp_m_axis_rc_tlast_combined;
  wire dsp_m_axis_rc_tready_combined;
  wire [DSP_RC_TUSER_WIDTH-1 : 0] dsp_m_axis_rc_tuser_combined;
  wire dsp_m_axis_rc_tvalid_combined;

  wire [USP_IF_WIDTH-1 : 0] usp_m_axis_rc_tdata_for_cc;
  wire [USP_TKEEP_WIDTH-1 : 0] usp_m_axis_rc_tkeep_for_cc;
  wire usp_m_axis_rc_tlast_for_cc;
  wire usp_m_axis_rc_tready_for_cc;
  wire [USP_RC_TUSER_WIDTH-1 : 0] usp_m_axis_rc_tuser_for_cc;
  wire usp_m_axis_rc_tvalid_for_cc;

  wire [DSP_IF_WIDTH-1 : 0] dsp_m_axis_rc_tdata_from_completion_gen;
  wire [DSP_TKEEP_WIDTH - 1 : 0] dsp_m_axis_rc_tkeep_from_completion_gen;
  wire dsp_m_axis_rc_tlast_from_completion_gen;
  wire dsp_m_axis_rc_tready_from_completion_gen;
  wire [DSP_RC_TUSER_WIDTH-1 : 0] dsp_m_axis_rc_tuser_from_completion_gen;
  wire dsp_m_axis_rc_tvalid_from_completion_gen;

  wire [31:0] dsp_m_axis_rc_tdata_read_data_DW_from_mgmt;

  wire switch_send_cfg_completion;

  // Internal signals - USP RC to DSP CC line
  wire [DSP_IF_WIDTH-1 : 0] dsp_m_axis_rc_tdata_for_cc;
  wire [DSP_TKEEP_WIDTH - 1 : 0] dsp_m_axis_rc_tkeep_for_cc;
  wire dsp_m_axis_rc_tlast_for_cc;
  wire dsp_m_axis_rc_tready_for_cc;
  wire [DSP_RC_TUSER_WIDTH-1 : 0] dsp_m_axis_rc_tuser_for_cc;
  wire dsp_m_axis_rc_tvalid_for_cc;

  // Internal signals - DSP CQ to USP RQ line
  wire [USP_IF_WIDTH-1 : 0] usp_m_axis_cq_tdata_for_rq;
  wire [USP_TKEEP_WIDTH-1 : 0] usp_m_axis_cq_tkeep_for_rq;
  wire usp_m_axis_cq_tlast_for_rq;
  wire usp_m_axis_cq_tready_for_rq;
  wire [USP_CQ_TUSER_WIDTH-1 : 0] usp_m_axis_cq_tuser_for_rq;
  wire usp_m_axis_cq_tvalid_for_rq;

  /*
    Design Start
  */

  // ---- USP CQ to DSP RQ line ---
  // USP Bus Numbers Snooping
  snoop_ext_bus_numbers usp_bus_numbers_snooper (
      .usp_user_clk,
      .usp_user_reset,
      .sys_reset_n,

      .usp_cfg_ext_write_received(cfg_ext_write_received),
      .usp_cfg_ext_register_number(cfg_ext_register_number),
      .usp_cfg_ext_function_number(cfg_ext_function_number),
      .usp_cfg_ext_write_data(cfg_ext_write_data),
      .usp_cfg_ext_write_byte_enable(cfg_ext_write_byte_enable),

      .usp_pri_bus,
      .usp_sec_bus,
      .usp_sub_bus,
      .all_bus_numbers_ready(usp_bus_num_rdy)
  );

  // USP Routing Check
  routing_checker_usp #(
      .USP_IF_WIDTH(USP_IF_WIDTH),
      .USP_CQ_TUSER_WIDTH(USP_CQ_TUSER_WIDTH),
      .USP_TKEEP_WIDTH(USP_TKEEP_WIDTH)
  ) cq_to_rq_line_routing_check_usp (
      .usp_pri_bus,
      .usp_sec_bus,
      .usp_sub_bus,
      .all_bus_numbers_ready(usp_bus_num_rdy),

      .m_axis_cq_tdata (usp_m_axis_cq_tdata),
      .m_axis_cq_tkeep (usp_m_axis_cq_tkeep),
      .m_axis_cq_tlast (usp_m_axis_cq_tlast),
      .m_axis_cq_tready(usp_m_axis_cq_tready),
      .m_axis_cq_tuser (usp_m_axis_cq_tuser),
      .m_axis_cq_tvalid(usp_m_axis_cq_tvalid),

      // Outputs
      .m_axis_cq_tdata_new(usp_m_axis_cq_tdata_for_rq_post_routing),
      .m_axis_cq_tkeep_new(usp_m_axis_cq_tkeep_for_rq_post_routing),
      .m_axis_cq_tlast_new(usp_m_axis_cq_tlast_for_rq_post_routing),
      .m_axis_cq_tready_new(usp_m_axis_cq_tready_for_rq_post_routing),
      .m_axis_cq_tuser_new(usp_m_axis_cq_tuser_for_rq_post_routing),
      .m_axis_cq_tvalid_new(usp_m_axis_cq_tvalid_for_rq_post_routing),
      .unsupported_req(usp_unsupported_req)
  );

  // CDC Width USP CQ to DSP RQ
  clk_width_conv_usp_to_dsp usp_cq_to_dsp_clk_width_cq (
      .DST_M_AXIS_0_tdata(dsp_m_axis_cq_tdata_for_rq_pre_routing),
      .DST_M_AXIS_0_tkeep(dsp_m_axis_cq_tkeep_for_rq_pre_routing),
      .DST_M_AXIS_0_tlast(dsp_m_axis_cq_tlast_for_rq_pre_routing),
      .DST_M_AXIS_0_tready(dsp_m_axis_cq_tready_for_rq_pre_routing),
      .DST_M_AXIS_0_tuser(dsp_m_axis_cq_tuser_for_rq_pre_routing),
      .DST_M_AXIS_0_tvalid(dsp_m_axis_cq_tvalid_for_rq_pre_routing),
      .SRC_S_AXIS_0_tdata(usp_m_axis_cq_tdata_for_rq_post_routing),
      .SRC_S_AXIS_0_tkeep(usp_m_axis_cq_tkeep_for_rq_post_routing),
      .SRC_S_AXIS_0_tlast(usp_m_axis_cq_tlast_for_rq_post_routing),
      .SRC_S_AXIS_0_tready(usp_m_axis_cq_tready_for_rq_post_routing),
      .SRC_S_AXIS_0_tuser(usp_m_axis_cq_tuser_for_rq_post_routing),
      .SRC_S_AXIS_0_tvalid(usp_m_axis_cq_tvalid_for_rq_post_routing),
      .SRC_s_axis_aclk_0(usp_user_clk),
            .SRC_s_axis_aresetn_0(sys_reset_n),
      .dst_m_axis_aclk_0(dsp_user_clk),
            .dst_m_axis_aresetn_0(sys_reset_n),
      .dst_user_aresetn_0(dsp_user_reset)
  );

  //CDC for USP Reset, Unsupported Request and Bus Numbers Ready
  one_signal_cdc #(
      .SIGNAL_WIDTH(1)
  ) usp_user_reset_cdc (
      .src_clk(usp_user_clk),
      .dst_clk(dsp_user_clk),
            .sys_rst(sys_reset_n),
      .sig_in (usp_user_reset),
      .sig_out(usp_user_reset_dsp_domain)
  );
  one_signal_cdc #(
      .SIGNAL_WIDTH(1)
  ) usp_bus_num_rdy_cdc (
      .src_clk(usp_user_clk),
      .dst_clk(dsp_user_clk),
            .sys_rst(sys_reset_n),
      .sig_in (usp_bus_num_rdy),
      .sig_out(usp_bus_num_rdy_dsp_domain)
  );
  one_signal_cdc #(
      .SIGNAL_WIDTH(1)
  ) usp_unsupported_req_cdc (
      .src_clk(usp_user_clk),
      .dst_clk(dsp_user_clk),
            .sys_rst(sys_reset_n),
      .sig_in (usp_unsupported_req),
      .sig_out(usp_unsupported_req_dsp_domain)
  );
  one_signal_cdc #(
      .SIGNAL_WIDTH(8)
  ) usp_sec_bus_cdc (
      .src_clk(usp_user_clk),
      .dst_clk(dsp_user_clk),
            .sys_rst(sys_reset_n),
      .sig_in (usp_sec_bus),
      .sig_out(usp_sec_bus_dsp_domain)
  );

  // DSP Bus Numbers Snooping
  snoop_mgmt_bus_numbers dsp_bus_numbers_snooper (
      .dsp_user_clk,
      .dsp_user_reset,
      .sys_reset_n,

      .dsp_cfg_mgmt_write(cfg_mgmt_write),
      .dsp_cfg_mgmt_read_write_done(cfg_mgmt_read_write_done),
      .dsp_cfg_mgmt_addr(cfg_mgmt_addr),
      .dsp_cfg_mgmt_function_number(cfg_mgmt_function_number),
      .dsp_cfg_mgmt_write_data(cfg_mgmt_write_data),
      .dsp_cfg_mgmt_byte_enable(cfg_mgmt_byte_enable),
      .usp_bus_num_rdy_dsp_domain,

      .dsp_pri_bus,
      .dsp_sec_bus,
      .dsp_sub_bus,
      .all_bus_numbers_ready(dsp_bus_num_rdy)
  );

  // State Machine for sending requests (Operates on Downstream Clock)
  switch_state_machine switch_state_machine_dsp (
      // Input - clock, reset and status signals
      .dsp_user_clk,
      .dsp_user_reset,
      .sys_reset_n,
            // Input - RQ converted to mgmt
      .rq_cfg_mgmt_addr(dsp_rq_cfg_mgmt_addr),
      .rq_cfg_mgmt_function_number(dsp_rq_cfg_mgmt_function_number),
      .rq_cfg_mgmt_write(dsp_rq_cfg_mgmt_write),
      .rq_cfg_mgmt_write_data(dsp_rq_cfg_mgmt_write_data),
      .rq_cfg_mgmt_byte_enable(dsp_rq_cfg_mgmt_byte_enable),
      .rq_cfg_mgmt_read(dsp_rq_cfg_mgmt_read),
      .rq_cfg_mgmt_debug_access(dsp_rq_cfg_mgmt_debug_access),
      // Input - USP Reset
      .usp_user_reset_dsp_domain,
      //   Input - USP CQ NP Req
      // Input - Bus numbers read
      .dsp_bus_num_rdy,
      .usp_bus_num_rdy(usp_bus_num_rdy_dsp_domain),
      // Input - Routing select
      .routing_select,
      // Input - Unsupported Request
      .routing_unsupported_req,
      // Input - Routing request type
      .routing_req_type,
      // Input - USP CC Tready at DSP RC (for combined MUX output)
      .dsp_m_axis_rc_tready_combined,
      // Output - Read Data for Completion to RQ CFG request
      .cpl_data_DW_cfgrd_t1(dsp_m_axis_rc_tdata_read_data_DW_from_mgmt),
      // IO - Configuration Management (DSP)
      .cfg_mgmt_addr,
      .cfg_mgmt_function_number,
      .cfg_mgmt_write,
      .cfg_mgmt_write_data,
      .cfg_mgmt_byte_enable,
      .cfg_mgmt_read,
      .cfg_mgmt_read_data,
      .cfg_mgmt_read_write_done,
      .cfg_mgmt_debug_access,
      // Output - Switch accept signals (pass to tready)
      .switch_usp_cq_accept,
            .switch_dsp_rc_accept(dsp_m_axis_rc_tready),
      .switch_send_cfg_completion
  );

  // Routing Check
  routing_checker #(
      .DSP_IF_WIDTH(DSP_IF_WIDTH),
      .DSP_CQ_TUSER_WIDTH(DSP_CQ_TUSER_WIDTH),
      .DSP_TKEEP_WIDTH(DSP_TKEEP_WIDTH)
  ) cq_to_rq_line_routing_check_dsp (
      // Inputs
      .m_axis_cq_tdata (dsp_m_axis_cq_tdata_for_rq_pre_routing),
      .m_axis_cq_tkeep (dsp_m_axis_cq_tkeep_for_rq_pre_routing),
      .m_axis_cq_tlast (dsp_m_axis_cq_tlast_for_rq_pre_routing),
      .m_axis_cq_tready(dsp_m_axis_cq_tready_for_rq_pre_routing),
      .m_axis_cq_tuser (dsp_m_axis_cq_tuser_for_rq_pre_routing),
      .m_axis_cq_tvalid(dsp_m_axis_cq_tvalid_for_rq_pre_routing),
      .dsp_user_lnk_up,

      .dsp_pri_bus(usp_sec_bus_dsp_domain),
      .dsp_sec_bus,
      .dsp_sub_bus,
      .req_type(routing_req_type),

      .usp_bus_num_rdy(usp_bus_num_rdy_dsp_domain),
      .dsp_bus_num_rdy,
      .usp_unsupported_req(usp_unsupported_req_dsp_domain),

      // Outputs
      .m_axis_cq_tdata_new(dsp_m_axis_cq_tdata_for_rq_post_routing),
      .m_axis_cq_tkeep_new(dsp_m_axis_cq_tkeep_for_rq_post_routing),
      .m_axis_cq_tlast_new(dsp_m_axis_cq_tlast_for_rq_post_routing),
      .m_axis_cq_tready_new(dsp_m_axis_cq_tready_for_rq_post_routing & switch_usp_cq_accept), // Only receive on USP CQ if both DSP RQ ready to receive (assuming not CFG), and USP CC ready to receive (assuming CFG) but not receiving from DSP already.
      .m_axis_cq_tuser_new(dsp_m_axis_cq_tuser_for_rq_post_routing),
      .m_axis_cq_tvalid_new(dsp_m_axis_cq_tvalid_for_rq_post_routing),
      .select(routing_select),
      .unsupported_req_out(routing_unsupported_req)
  );

  // DSP CQ Type 1 CFG to MGMT Converter
  cqt1_to_cfg_mgmt_converter #(
      .DSP_IF_WIDTH(DSP_IF_WIDTH),
      .DSP_TKEEP_WIDTH(DSP_TKEEP_WIDTH),
      .DSP_CQ_TUSER_WIDTH(DSP_CQ_TUSER_WIDTH)
  ) usp_cqt1_to_cfg_mgmt_conv (
      .dsp_m_axis_cq_tdata (dsp_m_axis_cq_tdata_for_rq_post_routing),
      .dsp_m_axis_cq_tkeep (dsp_m_axis_cq_tkeep_for_rq_post_routing),
      .dsp_m_axis_cq_tlast (dsp_m_axis_cq_tlast_for_rq_post_routing),
      //   .dsp_m_axis_cq_tready(dsp_m_axis_cq_tready_for_rq_post_routing),
      .dsp_m_axis_cq_tuser (dsp_m_axis_cq_tuser_for_rq_post_routing),
      .dsp_m_axis_cq_tvalid(dsp_m_axis_cq_tvalid_for_rq_post_routing),

      .select  (routing_select),
      .req_type(routing_req_type),

      .cfg_mgmt_addr(dsp_rq_cfg_mgmt_addr),
      .cfg_mgmt_function_number(dsp_rq_cfg_mgmt_function_number),
      .cfg_mgmt_write(dsp_rq_cfg_mgmt_write),
      .cfg_mgmt_write_data(dsp_rq_cfg_mgmt_write_data),
      .cfg_mgmt_byte_enable(dsp_rq_cfg_mgmt_byte_enable),
      .cfg_mgmt_read(dsp_rq_cfg_mgmt_read),
      .cfg_mgmt_read_data(dsp_rq_cfg_mgmt_read_data),
      .cfg_mgmt_read_write_done(dsp_rq_cfg_mgmt_read_write_done),
      .cfg_mgmt_debug_access(dsp_rq_cfg_mgmt_debug_access)
  );

  // Convert DSP CQ to DSP RQ
  cq_to_rq_converter #(
      .IF_WIDTH(DSP_IF_WIDTH),
      .TKEEP_WIDTH(DSP_TKEEP_WIDTH),
      .CQ_TUSER_WIDTH(DSP_CQ_TUSER_WIDTH),
      .RQ_TUSER_WIDTH(DSP_RQ_TUSER_WIDTH)
  ) dsp_cq_to_dsp_rq_conv (
      .user_clk(dsp_user_clk),
      .user_rst(dsp_user_reset),
      .sys_reset_n,

      .m_axis_cq_tdata (dsp_m_axis_cq_tdata_for_rq_post_routing),
      .m_axis_cq_tkeep (dsp_m_axis_cq_tkeep_for_rq_post_routing),
      .m_axis_cq_tlast (dsp_m_axis_cq_tlast_for_rq_post_routing),
      .m_axis_cq_tready(dsp_m_axis_cq_tready_for_rq_post_routing),
      .m_axis_cq_tuser (dsp_m_axis_cq_tuser_for_rq_post_routing),
      .m_axis_cq_tvalid(dsp_m_axis_cq_tvalid_for_rq_post_routing),

      .s_axis_rq_tdata (dsp_s_axis_rq_tdata_candidate_1),
      .s_axis_rq_tkeep (dsp_s_axis_rq_tkeep_candidate_1),
      .s_axis_rq_tlast (dsp_s_axis_rq_tlast_candidate_1),
      .s_axis_rq_tready(dsp_s_axis_rq_tready_candidate_1),
      .s_axis_rq_tuser (dsp_s_axis_rq_tuser_candidate_1),
      .s_axis_rq_tvalid(dsp_s_axis_rq_tvalid_candidate_1)
  );

  // RQ Type 1 to Type 0 Converter 
  rqt1_to_rqt0_converter #(
      .IF_WIDTH(DSP_IF_WIDTH),
      .TKEEP_WIDTH(DSP_TKEEP_WIDTH),
      .RQ_TUSER_WIDTH(DSP_RQ_TUSER_WIDTH)
  ) usp_rq_type_conversion (
      .select(routing_select),

      .s_axis_rq_tdata (dsp_s_axis_rq_tdata_candidate_1),
      .s_axis_rq_tkeep (dsp_s_axis_rq_tkeep_candidate_1),
      .s_axis_rq_tlast (dsp_s_axis_rq_tlast_candidate_1),
      .s_axis_rq_tready(dsp_s_axis_rq_tready_candidate_1),
      .s_axis_rq_tuser (dsp_s_axis_rq_tuser_candidate_1),
      .s_axis_rq_tvalid(dsp_s_axis_rq_tvalid_candidate_1),

      .s_axis_rq_tdata_new (dsp_s_axis_rq_tdata_candidate_2),
      .s_axis_rq_tkeep_new (dsp_s_axis_rq_tkeep_candidate_2),
      .s_axis_rq_tlast_new (dsp_s_axis_rq_tlast_candidate_2),
      .s_axis_rq_tready_new(dsp_s_axis_rq_tready_candidate_2),
      .s_axis_rq_tuser_new (dsp_s_axis_rq_tuser_candidate_2),
      .s_axis_rq_tvalid_new(dsp_s_axis_rq_tvalid_candidate_2)
  );

  // RQ Candidate MUX
  assign dsp_s_axis_rq_tdata = (dsp_bus_num_rdy & ~routing_unsupported_req) ? ((&(routing_select == 0)) ? dsp_s_axis_rq_tdata_candidate_2 : ((&(routing_select == 2)) ? dsp_s_axis_rq_tdata_candidate_1 : 'b0)) : 'b0;
  assign dsp_s_axis_rq_tkeep = (dsp_bus_num_rdy & ~routing_unsupported_req) ? ((&(routing_select == 0)) ? dsp_s_axis_rq_tkeep_candidate_2 : ((&(routing_select == 2)) ? dsp_s_axis_rq_tkeep_candidate_1 : 'b0)) : 'b0;
  assign dsp_s_axis_rq_tlast = (dsp_bus_num_rdy & ~routing_unsupported_req) ? ((&(routing_select == 0)) ? dsp_s_axis_rq_tlast_candidate_2 : ((&(routing_select == 2)) ? dsp_s_axis_rq_tlast_candidate_1 : 'b0)) : 'b0;
  assign dsp_s_axis_rq_tuser = (dsp_bus_num_rdy & ~routing_unsupported_req) ? ((&(routing_select == 0)) ? dsp_s_axis_rq_tuser_candidate_2 : ((&(routing_select == 2)) ? dsp_s_axis_rq_tuser_candidate_1 : 'b0)) : 'b0;
  assign dsp_s_axis_rq_tvalid = (dsp_bus_num_rdy & ~routing_unsupported_req) ? ((&(routing_select == 0)) ? dsp_s_axis_rq_tvalid_candidate_2 : ((&(routing_select == 2)) ? dsp_s_axis_rq_tvalid_candidate_1 : 'b0)) : 'b0;
  assign dsp_s_axis_rq_tready_candidate_2 = dsp_s_axis_rq_tready;

  // Completion Generator (URs and Config Mgmt Completion)
  completion_fwd_generator #(
      .DSP_IF_WIDTH(DSP_IF_WIDTH),
      .DSP_TKEEP_WIDTH(DSP_TKEEP_WIDTH),
      .DSP_CQ_TUSER_WIDTH(DSP_CQ_TUSER_WIDTH),
      .DSP_RC_TUSER_WIDTH(DSP_RC_TUSER_WIDTH)
  ) usp_cq_dsp_rq_to_dsp_rc_completion_generator (
      .select(routing_select),
      .unsupported_req(routing_unsupported_req),
      .req_type(routing_req_type),

      .dsp_m_axis_cq_tdata (dsp_m_axis_cq_tdata_for_rq_post_routing),
      .dsp_m_axis_cq_tkeep (dsp_m_axis_cq_tkeep_for_rq_post_routing),
      .dsp_m_axis_cq_tlast (dsp_m_axis_cq_tlast_for_rq_post_routing),
            .dsp_m_axis_cq_tuser (dsp_m_axis_cq_tuser_for_rq_post_routing),
      .dsp_m_axis_cq_tvalid(dsp_m_axis_cq_tvalid_for_rq_post_routing),

      .dsp_m_axis_rc_tdata (dsp_m_axis_rc_tdata_from_completion_gen),
      .dsp_m_axis_rc_tkeep (dsp_m_axis_rc_tkeep_from_completion_gen),
      .dsp_m_axis_rc_tlast (dsp_m_axis_rc_tlast_from_completion_gen),
            .dsp_m_axis_rc_tuser (dsp_m_axis_rc_tuser_from_completion_gen),
      .dsp_m_axis_rc_tvalid(dsp_m_axis_rc_tvalid_from_completion_gen)
  );

  // ---- DSP RC to USP CC line ---
  // Completion Combiner
  assign dsp_m_axis_rc_tdata_combined = switch_send_cfg_completion ? (((routing_req_type[3:1] == 3'b100) && ~routing_unsupported_req) ? {dsp_m_axis_rc_tdata_from_completion_gen[DSP_IF_WIDTH-1:128], dsp_m_axis_rc_tdata_read_data_DW_from_mgmt, dsp_m_axis_rc_tdata_from_completion_gen[95:0]} : dsp_m_axis_rc_tdata_from_completion_gen) : dsp_m_axis_rc_tdata;
  assign dsp_m_axis_rc_tuser_combined = switch_send_cfg_completion ? dsp_m_axis_rc_tuser_from_completion_gen : dsp_m_axis_rc_tuser;
  assign dsp_m_axis_rc_tvalid_combined = switch_send_cfg_completion ? dsp_m_axis_rc_tvalid_from_completion_gen : dsp_m_axis_rc_tvalid;
  assign dsp_m_axis_rc_tkeep_combined = switch_send_cfg_completion ? dsp_m_axis_rc_tkeep_from_completion_gen : dsp_m_axis_rc_tkeep;
  assign dsp_m_axis_rc_tlast_combined = switch_send_cfg_completion ? dsp_m_axis_rc_tlast_from_completion_gen : dsp_m_axis_rc_tlast;


  // CDC Width DSP RC to USP RC
  clk_width_conv_dsp_to_usp dsp_rc_to_usp_clk_width_rc (
      .DST_M_AXIS_0_tdata(usp_m_axis_rc_tdata_for_cc),
      .DST_M_AXIS_0_tkeep(usp_m_axis_rc_tkeep_for_cc),
      .DST_M_AXIS_0_tlast(usp_m_axis_rc_tlast_for_cc),
      .DST_M_AXIS_0_tready(usp_m_axis_rc_tready_for_cc),
      .DST_M_AXIS_0_tuser(usp_m_axis_rc_tuser_for_cc),
      .DST_M_AXIS_0_tvalid(usp_m_axis_rc_tvalid_for_cc),
      .SRC_S_AXIS_0_tdata(dsp_m_axis_rc_tdata_combined),
      .SRC_S_AXIS_0_tkeep(dsp_m_axis_rc_tkeep_combined),
      .SRC_S_AXIS_0_tlast(dsp_m_axis_rc_tlast_combined),
      .SRC_S_AXIS_0_tready(dsp_m_axis_rc_tready_combined),
      .SRC_S_AXIS_0_tuser(dsp_m_axis_rc_tuser_combined),
      .SRC_S_AXIS_0_tvalid(dsp_m_axis_rc_tvalid_combined),
      .dst_m_axis_aclk_0(usp_user_clk),
            .dst_m_axis_aresetn_0(sys_reset_n),
      .src_s_axis_aclk_0(dsp_user_clk),
            .src_s_axis_aresetn_0(sys_reset_n),
      .src_user_aresetn_0(dsp_user_reset)
  );

  // Convert USP RC to USP CC
  rc_to_cc_converter #(
      .IF_WIDTH(USP_IF_WIDTH),
      .TKEEP_WIDTH(USP_TKEEP_WIDTH),
      .RC_TUSER_WIDTH(USP_RC_TUSER_WIDTH),
      .CC_TUSER_WIDTH(USP_CC_TUSER_WIDTH)
  ) usp_rc_to_usp_cc_conv (
      .user_clk(usp_user_clk),
      .user_rst(usp_user_reset),
      .sys_reset_n(sys_reset_n),

      .s_axis_cc_tdata (usp_s_axis_cc_tdata),
      .s_axis_cc_tkeep (usp_s_axis_cc_tkeep),
      .s_axis_cc_tlast (usp_s_axis_cc_tlast),
      .s_axis_cc_tready(usp_s_axis_cc_tready),
      .s_axis_cc_tuser (usp_s_axis_cc_tuser),
      .s_axis_cc_tvalid(usp_s_axis_cc_tvalid),

      .m_axis_rc_tdata (usp_m_axis_rc_tdata_for_cc),
      .m_axis_rc_tkeep (usp_m_axis_rc_tkeep_for_cc),
      .m_axis_rc_tlast (usp_m_axis_rc_tlast_for_cc),
      .m_axis_rc_tready(usp_m_axis_rc_tready_for_cc),
      .m_axis_rc_tuser (usp_m_axis_rc_tuser_for_cc),
      .m_axis_rc_tvalid(usp_m_axis_rc_tvalid_for_cc)
  );


  // ---- USP RC to DSP CC line ---
  // CDC Width USP RC to DSP RC
  clk_width_conv_usp_to_dsp usp_rc_to_dsp_clk_width_rc (
      .DST_M_AXIS_0_tdata(dsp_m_axis_rc_tdata_for_cc),
      .DST_M_AXIS_0_tkeep(dsp_m_axis_rc_tkeep_for_cc),
      .DST_M_AXIS_0_tlast(dsp_m_axis_rc_tlast_for_cc),
      .DST_M_AXIS_0_tready(dsp_m_axis_rc_tready_for_cc),
      .DST_M_AXIS_0_tuser(dsp_m_axis_rc_tuser_for_cc),
      .DST_M_AXIS_0_tvalid(dsp_m_axis_rc_tvalid_for_cc),
      .SRC_S_AXIS_0_tdata(usp_m_axis_rc_tdata),
      .SRC_S_AXIS_0_tkeep(usp_m_axis_rc_tkeep),
      .SRC_S_AXIS_0_tlast(usp_m_axis_rc_tlast),
      .SRC_S_AXIS_0_tready(usp_m_axis_rc_tready),
      .SRC_S_AXIS_0_tuser(usp_m_axis_rc_tuser),
      .SRC_S_AXIS_0_tvalid(usp_m_axis_rc_tvalid),
      .SRC_s_axis_aclk_0(usp_user_clk),
            .SRC_s_axis_aresetn_0(sys_reset_n),
      .dst_m_axis_aclk_0(dsp_user_clk),
            .dst_m_axis_aresetn_0(sys_reset_n),
      .dst_user_aresetn_0(dsp_user_reset)
  );


  // Convert DSP RC to DSP CC
  rc_to_cc_converter #(
      .IF_WIDTH(DSP_IF_WIDTH),
      .TKEEP_WIDTH(DSP_TKEEP_WIDTH),
      .RC_TUSER_WIDTH(DSP_RC_TUSER_WIDTH),
      .CC_TUSER_WIDTH(DSP_CC_TUSER_WIDTH)
  ) dsp_rc_to_dsp_cc_conv (
      .user_clk(dsp_user_clk),
      .user_rst(dsp_user_reset),
      .sys_reset_n(sys_reset_n),

      .s_axis_cc_tdata (dsp_s_axis_cc_tdata),
      .s_axis_cc_tkeep (dsp_s_axis_cc_tkeep),
      .s_axis_cc_tlast (dsp_s_axis_cc_tlast),
      .s_axis_cc_tready(dsp_s_axis_cc_tready),
      .s_axis_cc_tuser (dsp_s_axis_cc_tuser),
      .s_axis_cc_tvalid(dsp_s_axis_cc_tvalid),

      .m_axis_rc_tdata (dsp_m_axis_rc_tdata_for_cc),
      .m_axis_rc_tkeep (dsp_m_axis_rc_tkeep_for_cc),
      .m_axis_rc_tlast (dsp_m_axis_rc_tlast_for_cc),
      .m_axis_rc_tready(dsp_m_axis_rc_tready_for_cc),
      .m_axis_rc_tuser (dsp_m_axis_rc_tuser_for_cc),
      .m_axis_rc_tvalid(dsp_m_axis_rc_tvalid_for_cc)
  );


  // ---- DSP CQ to USP RQ line ---
  // CDC Width DSP CQ to USP CQ
  clk_width_conv_dsp_to_usp dsp_cq_to_usp_clk_width_cq (
      .DST_M_AXIS_0_tdata(usp_m_axis_cq_tdata_for_rq),
      .DST_M_AXIS_0_tkeep(usp_m_axis_cq_tkeep_for_rq),
      .DST_M_AXIS_0_tlast(usp_m_axis_cq_tlast_for_rq),
      .DST_M_AXIS_0_tready(usp_m_axis_cq_tready_for_rq),
      .DST_M_AXIS_0_tuser(usp_m_axis_cq_tuser_for_rq),
      .DST_M_AXIS_0_tvalid(usp_m_axis_cq_tvalid_for_rq),
      .SRC_S_AXIS_0_tdata(dsp_m_axis_cq_tdata),
      .SRC_S_AXIS_0_tkeep(dsp_m_axis_cq_tkeep),
      .SRC_S_AXIS_0_tlast(dsp_m_axis_cq_tlast),
      .SRC_S_AXIS_0_tready(dsp_m_axis_cq_tready),
      .SRC_S_AXIS_0_tuser(dsp_m_axis_cq_tuser),
      .SRC_S_AXIS_0_tvalid(dsp_m_axis_cq_tvalid),
      .dst_m_axis_aclk_0(usp_user_clk),
            .dst_m_axis_aresetn_0(sys_reset_n),
      .src_user_aresetn_0(dsp_user_reset),
      .src_s_axis_aclk_0(dsp_user_clk),
            .src_s_axis_aresetn_0(sys_reset_n)
  );

  // Convert USP CQ to USP RQ
  cq_to_rq_converter #(
      .IF_WIDTH(USP_IF_WIDTH),
      .TKEEP_WIDTH(USP_TKEEP_WIDTH),
      .CQ_TUSER_WIDTH(USP_CQ_TUSER_WIDTH),
      .RQ_TUSER_WIDTH(USP_RQ_TUSER_WIDTH)
  ) usp_cq_to_usp_rq_conv (
      .user_clk(usp_user_clk),
      .user_rst(usp_user_reset),
      .sys_reset_n,

      .m_axis_cq_tdata (usp_m_axis_cq_tdata_for_rq),
      .m_axis_cq_tkeep (usp_m_axis_cq_tkeep_for_rq),
      .m_axis_cq_tlast (usp_m_axis_cq_tlast_for_rq),
      .m_axis_cq_tready(usp_m_axis_cq_tready_for_rq),
      .m_axis_cq_tuser (usp_m_axis_cq_tuser_for_rq),
      .m_axis_cq_tvalid(usp_m_axis_cq_tvalid_for_rq),

      .s_axis_rq_tdata (usp_s_axis_rq_tdata),
      .s_axis_rq_tkeep (usp_s_axis_rq_tkeep),
      .s_axis_rq_tlast (usp_s_axis_rq_tlast),
      .s_axis_rq_tready(usp_s_axis_rq_tready),
      .s_axis_rq_tuser (usp_s_axis_rq_tuser),
      .s_axis_rq_tvalid(usp_s_axis_rq_tvalid)
  );

  /*
    Design End
  */

endmodule
