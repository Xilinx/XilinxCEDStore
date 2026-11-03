// qdma_user_if.sv — AXI4-Stream interface for the QDMA user-side agent.
//
// Provides two clocking blocks:
//   h2c_cb : samples H2C (host→card) stream outputs;
//            monitor also drives h2c_tready through this block.
//   c2h_cb : driver pushes C2H (card→host) data;
//            samples c2h_tready.

`timescale 1ps/1ps

interface qdma_user_if (input logic aclk, input logic aresetn);

  // -------------------------------------------------------------------------
  // H2C (host→card): monitor receives; monitor drives tready
  // -------------------------------------------------------------------------
  logic [511:0] h2c_tdata;
  logic [63:0]  h2c_tkeep;
  logic         h2c_tlast;
  logic         h2c_tvalid;
  logic         h2c_tready;     // driven by monitor (always 1 in passive mode)
  logic [11:0]  h2c_tuser_qid;
  logic [2:0]   h2c_tuser_port_id;
  logic [2:0]   h2c_tuser_zero_byte;
  logic [5:0]   h2c_tuser_mty;
  logic [2:0]   h2c_tuser_err;

  // -------------------------------------------------------------------------
  // C2H (card→host): driver pushes data; c2h_tready is an input
  // -------------------------------------------------------------------------
  logic [511:0] c2h_tdata;
  logic [63:0]  c2h_tkeep;
  logic         c2h_tlast;
  logic         c2h_tvalid;
  logic         c2h_tready;
  logic [11:0]  c2h_ctrl_qid;
  logic [5:0]   c2h_mty;
  logic [2:0]   c2h_ctrl_port_id;
  logic         c2h_ctrl_marker;
  logic         c2h_ctrl_has_cmpt;
  logic [15:0]  c2h_ctrl_len;

  // -------------------------------------------------------------------------
  // H2C clocking block — monitor samples H2C, drives h2c_tready
  // -------------------------------------------------------------------------
  clocking h2c_cb @(posedge aclk);
    input  h2c_tdata;
    input  h2c_tkeep;
    input  h2c_tlast;
    input  h2c_tvalid;
    output h2c_tready;
    input  h2c_tuser_qid;
    input  h2c_tuser_port_id;
    input  h2c_tuser_zero_byte;
    input  h2c_tuser_mty;
    input  h2c_tuser_err;
  endclocking

  // -------------------------------------------------------------------------
  // C2H clocking block — driver pushes C2H data; samples c2h_tready
  // -------------------------------------------------------------------------
  clocking c2h_cb @(posedge aclk);
    output c2h_tdata;
    output c2h_tkeep;
    output c2h_tlast;
    output c2h_tvalid;
    input  c2h_tready;
    output c2h_ctrl_qid;
    output c2h_mty;
    output c2h_ctrl_port_id;
    output c2h_ctrl_marker;
    output c2h_ctrl_has_cmpt;
    output c2h_ctrl_len;
  endclocking

  modport monitor_mp (clocking h2c_cb, input aclk, input aresetn);
  modport driver_mp  (clocking c2h_cb, input aclk, input aresetn);

endinterface
