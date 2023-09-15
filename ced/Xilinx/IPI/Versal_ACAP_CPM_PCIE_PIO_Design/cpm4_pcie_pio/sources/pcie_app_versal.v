
//-----------------------------------------------------------------------------
//
// (c) Copyright 2017-2019 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : Versal PCI Express Integrated Block
// File       : pcie_app_versal.v
// Version    : 1.0 
//-----------------------------------------------------------------------------
//
// Description: PCI Express Endpoint example application design
//
//--------------------------------------------------------------------------------

`timescale 1ps / 1ps

`define PCI_EXP_EP_OUI   24'h000A35
`define PCI_EXP_EP_DSN_1 {{8'h1},`PCI_EXP_EP_OUI}
`define PCI_EXP_EP_DSN_2 32'h10EE0001

(* DowngradeIPIdentifiedWarnings = "yes" *)
module  pcie_app_versal #(
  parameter C_DATA_WIDTH = 512,  // RX/TX interface data width

  // Do not override parameters below this line
  parameter TCQ = 1,
  parameter KEEP_WIDTH = C_DATA_WIDTH / 32,
  parameter [1:0]  AXISTEN_IF_WIDTH = (C_DATA_WIDTH == 512) ? 2'b11:(C_DATA_WIDTH == 256) ? 2'b10 : (C_DATA_WIDTH == 128) ? 2'b01 : 2'b00,
  parameter        AXISTEN_IF_RQ_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_RC_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_CC_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_CQ_ALIGNMENT_MODE   = "FALSE",
  parameter        AXI4_CQ_TUSER_WIDTH = 88,
  parameter        AXI4_CC_TUSER_WIDTH = 33,
  parameter        AXI4_RQ_TUSER_WIDTH = 62,
  parameter        AXI4_RC_TUSER_WIDTH = 75,
  parameter        AXISTEN_IF_ENABLE_CLIENT_TAG   = 0,
  parameter        AXISTEN_IF_RQ_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_CC_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_RC_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_CQ_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_MC_RX_STRADDLE      = 1,
  parameter        AXISTEN_IF_ENABLE_RX_MSG_INTFC = 0,
  parameter [17:0] AXISTEN_IF_ENABLE_MSG_ROUTE    = 18'h2FFFF
)(


  //------------------------------------------------//
  //  AXI Interface                                 //
  //------------------------------------------------//

  output                           s_axis_rq_tlast,
  output        [C_DATA_WIDTH-1:0] s_axis_rq_tdata,
  output [AXI4_RQ_TUSER_WIDTH-1:0] s_axis_rq_tuser,
  output          [KEEP_WIDTH-1:0] s_axis_rq_tkeep,
  input                            s_axis_rq_tready,
  output                           s_axis_rq_tvalid,

  input         [C_DATA_WIDTH-1:0] m_axis_rc_tdata,
  input  [AXI4_RC_TUSER_WIDTH-1:0] m_axis_rc_tuser,
  input                            m_axis_rc_tlast,
  input           [KEEP_WIDTH-1:0] m_axis_rc_tkeep,
  input                            m_axis_rc_tvalid,
  output                           m_axis_rc_tready,

  input         [C_DATA_WIDTH-1:0] m_axis_cq_tdata,
  input  [AXI4_CQ_TUSER_WIDTH-1:0] m_axis_cq_tuser,
  input                            m_axis_cq_tlast,
  input           [KEEP_WIDTH-1:0] m_axis_cq_tkeep,
  input                            m_axis_cq_tvalid,
  output                           m_axis_cq_tready,

  output        [C_DATA_WIDTH-1:0] s_axis_cc_tdata,
  output [AXI4_CC_TUSER_WIDTH-1:0] s_axis_cc_tuser,
  output                           s_axis_cc_tlast,
  output          [KEEP_WIDTH-1:0] s_axis_cc_tkeep,
  output                           s_axis_cc_tvalid,
  input                            s_axis_cc_tready,

  input  [1:0] pcie_tfc_nph_av,
  input  [1:0] pcie_tfc_npd_av,
  //---------------------------------//
  //  Configuration (CFG) Interface  //
  //---------------------------------//

  input  [3:0] pcie_rq_seq_num,
  input        pcie_rq_seq_num_vld,
  input  [5:0] pcie_rq_tag,
  input        pcie_rq_tag_vld,
  output       pcie_cq_np_req,
  input  [5:0] pcie_cq_np_req_count,

  //----------------------------------//
  // EP and RP                        //
  //----------------------------------//

  input          cfg_phy_link_down,
  input   [2:0]  cfg_negotiated_width,
  input   [2:0]  cfg_current_speed,
  input   [1:0]  cfg_max_payload,
  input   [2:0]  cfg_max_read_req,
  input   [7:0]  cfg_function_status,
  input   [5:0]  cfg_function_power_state,
  input  [503:0] cfg_vf_status,
  input  [755:0] cfg_vf_power_state,
  input   [1:0]  cfg_link_power_state,

  // Error Reporting Interface
  input  cfg_err_cor_out,
  input  cfg_err_nonfatal_out,
  input  cfg_err_fatal_out,
//input  cfg_local_error,

  input          cfg_ltr_enable,
  input    [5:0] cfg_ltssm_state,
  input    [1:0] cfg_rcb_status,
  input    [1:0] cfg_obff_enable,
  input          cfg_pl_status_change,

  input    [1:0] cfg_tph_requester_enable,
  input   [11:0] cfg_tph_st_mode,
  input  [251:0] cfg_vf_tph_requester_enable,
  input  [755:0] cfg_vf_tph_st_mode,


  // Management Interface
  output  [9:0] cfg_mgmt_addr,
  output        cfg_mgmt_write,
  output [31:0] cfg_mgmt_write_data,
  output  [3:0] cfg_mgmt_byte_enable,
  output        cfg_mgmt_read,
  input  [31:0] cfg_mgmt_read_data,
  input         cfg_mgmt_read_write_done,
  output        cfg_mgmt_type1_cfg_reg_access,
  input         cfg_msg_received,
  input   [7:0] cfg_msg_received_data,
  input   [4:0] cfg_msg_received_type,
  output        cfg_msg_transmit,
  output  [2:0] cfg_msg_transmit_type,
  output [31:0] cfg_msg_transmit_data,
  input         cfg_msg_transmit_done,
  input   [7:0] cfg_fc_ph,
  input  [11:0] cfg_fc_pd,
  input   [7:0] cfg_fc_nph,
  input  [11:0] cfg_fc_npd,
  input   [7:0] cfg_fc_cplh,
  input  [11:0] cfg_fc_cpld,
  output  [2:0] cfg_fc_sel,

  output  [63:0] cfg_dsn,
  output         cfg_power_state_change_ack,
  input          cfg_power_state_change_interrupt,
  output         cfg_err_cor_in,
  output         cfg_err_uncor_in,

  input    [3:0] cfg_flr_in_process,
  output   [3:0] cfg_flr_done,
  input  [251:0] cfg_vf_flr_in_process,
  output         cfg_vf_flr_done,
  output   [7:0] cfg_vf_flr_func_num,

  output         cfg_link_training_enable,

  output [7:0]   cfg_ds_port_number,
  output [7:0]   cfg_ds_bus_number,
  output [4:0]   cfg_ds_device_number,
  output [2:0]   cfg_ds_function_number,
  
  //--------------------------------------//
  // EP Only                              //
  //--------------------------------------//
  // Interrupt Interface Signals
  output  [3:0] cfg_interrupt_int,
  output  [1:0] cfg_interrupt_pending,
  input         cfg_interrupt_sent,

  input   [3:0] cfg_interrupt_msi_enable,
  input   [5:0] cfg_interrupt_msi_mmenable,
  input         cfg_interrupt_msi_mask_update,
  input  [31:0] cfg_interrupt_msi_data,
  output  [1:0] cfg_interrupt_msi_select,
  output [31:0] cfg_interrupt_msi_int,
  output [63:0] cfg_interrupt_msi_pending_status,
  input         cfg_interrupt_msi_sent,
  input         cfg_interrupt_msi_fail,
  output  [2:0] cfg_interrupt_msi_attr,
  output        cfg_interrupt_msi_tph_present,
  output  [1:0] cfg_interrupt_msi_tph_type,
  output  [7:0] cfg_interrupt_msi_tph_st_tag,
  output  [7:0] cfg_interrupt_msi_function_number,

  input  [5:0]  cfg_interrupt_msi_vf_enable,
  input  [3:0]  cfg_interrupt_msix_enable,
  output        cfg_interrupt_msix_int,
  input  [1:0]  cfg_dpa_substate_change,

  // EP only
  input  cfg_hot_reset_in,
  output cfg_config_space_enable,
  output cfg_req_pm_transition_l23_ready,

  // RP only
  output cfg_hot_reset_out,

  input sys_rst,
  input user_clk,
  input user_reset,
  input user_lnk_up 
);


  wire     m_axis_cq_tready_bit;
  wire     m_axis_rc_tready_bit;


  //----------------------------------------------------------------------------------------------------------------//
  // PCIe Block EP Tieoffs - Example PIO doesn't support the following outputs                                      //
  //----------------------------------------------------------------------------------------------------------------//
  assign cfg_mgmt_addr        = 10'h0; // Zero out CFG MGMT 19-bit address port
  assign cfg_mgmt_write       = 1'b0;  // Do not write CFG space
  assign cfg_mgmt_write_data  = 32'h0; // Zero out CFG MGMT input data bus
  assign cfg_mgmt_byte_enable = 4'h0;  // Zero out CFG MGMT byte enables
  assign cfg_mgmt_read        = 1'b0;  // Do not read CFG space
  assign cfg_mgmt_type1_cfg_reg_access = 1'b0;
  
  assign cfg_dsn          = {`PCI_EXP_EP_DSN_2, `PCI_EXP_EP_DSN_1};  // Assign the input DSN
  assign cfg_err_cor_in   = 1'b0; // Never report Correctable Error
  assign cfg_err_uncor_in = 1'b0; // Never report UnCorrectable Error
//assign cfg_flr_done     = 1'b0; // FIXME : how to drive this?
//assign cfg_vf_flr_done  = 1'b0; // FIXME : how to drive this?

  assign cfg_link_training_enable = 1'b1; // Always enable LTSSM to bring up the Link
  assign cfg_config_space_enable  = 1'b1;
  assign cfg_req_pm_transition_l23_ready = 1'b0;

  assign cfg_hot_reset_out      = 1'b0;
  assign cfg_ds_port_number     = 8'h0;
  assign cfg_ds_bus_number      = 8'h0;
  assign cfg_ds_device_number   = 5'h0;
  assign cfg_ds_function_number = 3'h0;
  assign cfg_interrupt_pending  = 2'h0;
  assign cfg_interrupt_msi_select = 2'b00;
  assign cfg_interrupt_msi_pending_status = 64'h0;

  assign cfg_interrupt_msi_attr        = 3'h0;
  assign cfg_interrupt_msi_tph_present = 1'b0;
  assign cfg_interrupt_msi_tph_type    = 2'h0;
  assign cfg_interrupt_msi_tph_st_tag  = 8'h0;
  assign cfg_interrupt_msi_function_number   = 8'h0;

  assign m_axis_cq_tready = m_axis_cq_tready_bit;
  assign m_axis_rc_tready = m_axis_rc_tready_bit;	
	
  reg [3:0] cfg_flr_done_reg0;
  reg [5:0] cfg_vf_flr_done_reg0;
  reg [3:0] cfg_flr_done_reg1;
  reg [5:0] cfg_vf_flr_done_reg1;


  always @(posedge user_clk)
  begin
    if (user_reset) begin
      cfg_flr_done_reg0    <= 'd0;
      cfg_vf_flr_done_reg0 <= 'd0;
      cfg_flr_done_reg1    <= 'd0;
      cfg_vf_flr_done_reg1 <= 'd0;
    end
    else begin
      cfg_flr_done_reg0    <= cfg_flr_in_process;
      cfg_vf_flr_done_reg0 <= cfg_vf_flr_in_process;
      cfg_flr_done_reg1    <= cfg_flr_done_reg0;
      cfg_vf_flr_done_reg1 <= cfg_vf_flr_done_reg0;
    end
  end

  assign cfg_flr_done[0] = ~cfg_flr_done_reg1[0] && cfg_flr_done_reg0[0]; 
  assign cfg_flr_done[1] = ~cfg_flr_done_reg1[1] && cfg_flr_done_reg0[1];
  assign cfg_flr_done[2] = ~cfg_flr_done_reg1[2] && cfg_flr_done_reg0[2]; 
  assign cfg_flr_done[3] = ~cfg_flr_done_reg1[3] && cfg_flr_done_reg0[3];

  assign cfg_vf_flr_done = ~cfg_vf_flr_done_reg1[0] && cfg_vf_flr_done_reg0[0]; 
//assign cfg_vf_flr_done[1] = ~cfg_vf_flr_done_reg1[1] && cfg_vf_flr_done_reg0[1]; 
//assign cfg_vf_flr_done[2] = ~cfg_vf_flr_done_reg1[2] && cfg_vf_flr_done_reg0[2]; 
//assign cfg_vf_flr_done[3] = ~cfg_vf_flr_done_reg1[3] && cfg_vf_flr_done_reg0[3]; 
//assign cfg_vf_flr_done[4] = ~cfg_vf_flr_done_reg1[4] && cfg_vf_flr_done_reg0[4]; 
//assign cfg_vf_flr_done[5] = ~cfg_vf_flr_done_reg1[5] && cfg_vf_flr_done_reg0[5];

  // Register and cycle through the virtual fucntion function level reset.
  // This counter will just loop over the virtual functions. Ths should be
  // repliced by user logic to perform the actual function level reset as
  // needed.
  reg     [7:0]     cfg_vf_flr_func_num_reg;
  always @(posedge user_clk) begin
    if(user_reset) begin
      cfg_vf_flr_func_num_reg <= 8'd0;
    end else begin
      cfg_vf_flr_func_num_reg <= cfg_vf_flr_func_num_reg + 1'b1;
    end
  end
  assign cfg_vf_flr_func_num = cfg_vf_flr_func_num_reg;


  pio #(
    .TCQ(TCQ),
    .C_DATA_WIDTH(C_DATA_WIDTH),
    .AXISTEN_IF_WIDTH(AXISTEN_IF_WIDTH),
    
    .AXISTEN_IF_RQ_ALIGNMENT_MODE(AXISTEN_IF_RQ_ALIGNMENT_MODE),
    .AXISTEN_IF_CC_ALIGNMENT_MODE(AXISTEN_IF_CC_ALIGNMENT_MODE),
    .AXISTEN_IF_CQ_ALIGNMENT_MODE(AXISTEN_IF_CQ_ALIGNMENT_MODE),
    .AXISTEN_IF_RC_ALIGNMENT_MODE(AXISTEN_IF_RC_ALIGNMENT_MODE),
    
    .AXI4_CQ_TUSER_WIDTH(AXI4_CQ_TUSER_WIDTH),
    .AXI4_CC_TUSER_WIDTH(AXI4_CC_TUSER_WIDTH),
    .AXI4_RQ_TUSER_WIDTH(AXI4_RQ_TUSER_WIDTH),
    .AXI4_RC_TUSER_WIDTH(AXI4_RC_TUSER_WIDTH),
    
    .AXISTEN_IF_ENABLE_CLIENT_TAG(AXISTEN_IF_ENABLE_CLIENT_TAG),
    
    .AXISTEN_IF_RQ_PARITY_CHECK(AXISTEN_IF_RQ_PARITY_CHECK),
    .AXISTEN_IF_CC_PARITY_CHECK(AXISTEN_IF_CC_PARITY_CHECK),
    .AXISTEN_IF_RC_PARITY_CHECK(AXISTEN_IF_RC_PARITY_CHECK),
    .AXISTEN_IF_CQ_PARITY_CHECK(AXISTEN_IF_CQ_PARITY_CHECK),
    
    .AXISTEN_IF_MC_RX_STRADDLE(AXISTEN_IF_MC_RX_STRADDLE),
    .AXISTEN_IF_ENABLE_RX_MSG_INTFC(AXISTEN_IF_ENABLE_RX_MSG_INTFC),
    .AXISTEN_IF_ENABLE_MSG_ROUTE(AXISTEN_IF_ENABLE_MSG_ROUTE)

  ) PIO_i (
    .user_clk(user_clk),
    .reset_n (~user_reset),
    .user_lnk_up(user_lnk_up),

    .s_axis_cc_tdata (s_axis_cc_tdata),
    .s_axis_cc_tkeep (s_axis_cc_tkeep),
    .s_axis_cc_tlast (s_axis_cc_tlast),
    .s_axis_cc_tvalid(s_axis_cc_tvalid),
    .s_axis_cc_tuser (s_axis_cc_tuser),
    .s_axis_cc_tready(s_axis_cc_tready),

    .s_axis_rq_tdata  (s_axis_rq_tdata),
    .s_axis_rq_tkeep  (s_axis_rq_tkeep),
    .s_axis_rq_tlast  (s_axis_rq_tlast),
    .s_axis_rq_tvalid (s_axis_rq_tvalid),
    .s_axis_rq_tuser  (s_axis_rq_tuser),
    .s_axis_rq_tready (s_axis_rq_tready),

    .m_axis_cq_tdata  (m_axis_cq_tdata),
    .m_axis_cq_tlast  (m_axis_cq_tlast),
    .m_axis_cq_tvalid (m_axis_cq_tvalid),
    .m_axis_cq_tuser  (m_axis_cq_tuser),
    .m_axis_cq_tkeep  (m_axis_cq_tkeep),
    .m_axis_cq_tready (m_axis_cq_tready_bit),

    .m_axis_rc_tdata  (m_axis_rc_tdata),
    .m_axis_rc_tlast  (m_axis_rc_tlast),
    .m_axis_rc_tvalid (m_axis_rc_tvalid),
    .m_axis_rc_tuser  (m_axis_rc_tuser),
    .m_axis_rc_tkeep  (m_axis_rc_tkeep),
    .m_axis_rc_tready (m_axis_rc_tready_bit),

    .cfg_msg_transmit_done (cfg_msg_transmit_done),
    .cfg_msg_transmit      (cfg_msg_transmit),
    .cfg_msg_transmit_type (cfg_msg_transmit_type),
    .cfg_msg_transmit_data (cfg_msg_transmit_data),
    
    .pcie_tfc_nph_av (pcie_tfc_nph_av),
    .pcie_tfc_npd_av (pcie_tfc_npd_av),
    .pcie_rq_tag     (pcie_rq_tag),
    .pcie_rq_tag_vld (pcie_rq_tag_vld),
    
    .pcie_tfc_np_pl_empty ( 1'b0 ),
    .pcie_rq_seq_num      (pcie_rq_seq_num),
    .pcie_rq_seq_num_vld  (pcie_rq_seq_num_vld),
    .pcie_cq_np_req       (pcie_cq_np_req),
    .pcie_cq_np_req_count (pcie_cq_np_req_count),
    
    .cfg_fc_ph  (cfg_fc_ph),
    .cfg_fc_nph (cfg_fc_nph),
    .cfg_fc_cplh(cfg_fc_cplh),
    .cfg_fc_pd  (cfg_fc_pd),
    .cfg_fc_npd (cfg_fc_npd),
    .cfg_fc_cpld(cfg_fc_cpld),
    .cfg_fc_sel (cfg_fc_sel),

    .cfg_msg_received (cfg_msg_received),
    .cfg_msg_received_type (cfg_msg_received_type),
    .cfg_msg_data (cfg_msg_received_data),

    .cfg_interrupt_msi_enable ( cfg_interrupt_msi_enable[0] ),
    .cfg_interrupt_msi_sent   (cfg_interrupt_msi_sent),
    .cfg_interrupt_msi_fail   (cfg_interrupt_msi_fail),

    .cfg_interrupt_msi_int    (cfg_interrupt_msi_int),
    .cfg_interrupt_msix_enable( 1'b0 ),
    .cfg_interrupt_msix_sent  ( 1'b0 ),
    .cfg_interrupt_msix_fail  ( 1'b0 ),

    .cfg_interrupt_msix_int     (cfg_interrupt_msix_int),
    .cfg_interrupt_msix_address (  ),
    .cfg_interrupt_msix_data    (  ),

    .cfg_power_state_change_interrupt(cfg_power_state_change_interrupt),
    .cfg_power_state_change_ack (cfg_power_state_change_ack),

    .interrupt_done ( ),

    .cfg_interrupt_sent(cfg_interrupt_sent),
    .cfg_interrupt_int ( cfg_interrupt_int )
  );

endmodule

