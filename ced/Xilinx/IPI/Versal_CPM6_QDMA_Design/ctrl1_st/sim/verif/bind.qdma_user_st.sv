// bind.qdma_user_st.sv — Wire native QDMA H2C/C2H ST ports to qdma_user_if.
//
// In streaming mode the block design exposes the QDMA streaming ports
// (H2C_ST_PORT0_0, C2H_ST_PORT0_0, ...) directly.
//
// This module:
//   1. Creates one qdma_user_if per port (0..3).
//   2. Wires the H2C stream outputs of the block design to the interfaces for
//      UVM monitoring (the example design's h2c_sink instances consume them).
//   3. Wires the C2H stream inputs of the block design (driven by the example
//      design's c2h_source_ctrl instances) to the interfaces.
//   4. Registers the interfaces in uvm_config_db as qdma_user_vif0..3.
//   5. Keeps qdma_user_vif as an alias for port 0.
//
// Clock:  ps_wizard_0_pl0_ref_clk  (same as axi_aclk on cpm6_qdma_0)
// Reset:  ps_wizard_0_pl0_resetn   (active-low)
//
// Signal naming: the block design names its ports H2C_ST_PORTn_0_h2c_<signal>
// and C2H_ST_PORTn_0_c2h_<signal>.
//
// IMPORTANT: All block design wires are declared as input ports so that the
// bind statement's (.*) connects them via standard port resolution (IEEE
// 1800-2017 section 23.3.2).  Using local wire declarations would shadow the
// parent's signals and break connectivity.

`include "qdma_bd_names.svh"
`default_nettype wire
module bind_qdma_user_st
  import uvm_pkg::*;
(
  // -------------------------------------------------------------------------
  // Clock / Reset
  // -------------------------------------------------------------------------
  input wire          ps_wizard_0_pl0_ref_clk,
  input wire          ps_wizard_0_pl0_resetn,

  // -------------------------------------------------------------------------
  // H2C ST PORT0 — native QDMA streaming output (all outputs from the block design)
  // -------------------------------------------------------------------------
  input wire [511:0]  H2C_ST_PORT0_0_h2c_tdata,
  input wire [63:0]   H2C_ST_PORT0_0_h2c_tkeep,
  input wire          H2C_ST_PORT0_0_h2c_tlast,
  input wire          H2C_ST_PORT0_0_h2c_tready,
  input wire          H2C_ST_PORT0_0_h2c_tvalid,
  input wire [10:0]   H2C_ST_PORT0_0_h2c_tuser_qid,
  input wire [2:0]    H2C_ST_PORT0_0_h2c_tuser_port_id,
  input wire [5:0]    H2C_ST_PORT0_0_h2c_tuser_mty,
  input wire          H2C_ST_PORT0_0_h2c_tuser_err,

  // H2C ST PORT1
  input wire [511:0]  H2C_ST_PORT1_0_h2c_tdata,
  input wire [63:0]   H2C_ST_PORT1_0_h2c_tkeep,
  input wire          H2C_ST_PORT1_0_h2c_tlast,
  input wire          H2C_ST_PORT1_0_h2c_tready,
  input wire          H2C_ST_PORT1_0_h2c_tvalid,
  input wire [10:0]   H2C_ST_PORT1_0_h2c_tuser_qid,
  input wire [2:0]    H2C_ST_PORT1_0_h2c_tuser_port_id,
  input wire [5:0]    H2C_ST_PORT1_0_h2c_tuser_mty,
  input wire          H2C_ST_PORT1_0_h2c_tuser_err,

  // H2C ST PORT2
  input wire [511:0]  H2C_ST_PORT2_0_h2c_tdata,
  input wire [63:0]   H2C_ST_PORT2_0_h2c_tkeep,
  input wire          H2C_ST_PORT2_0_h2c_tlast,
  input wire          H2C_ST_PORT2_0_h2c_tready,
  input wire          H2C_ST_PORT2_0_h2c_tvalid,
  input wire [10:0]   H2C_ST_PORT2_0_h2c_tuser_qid,
  input wire [2:0]    H2C_ST_PORT2_0_h2c_tuser_port_id,
  input wire [5:0]    H2C_ST_PORT2_0_h2c_tuser_mty,
  input wire          H2C_ST_PORT2_0_h2c_tuser_err,

  // H2C ST PORT3
  input wire [511:0]  H2C_ST_PORT3_0_h2c_tdata,
  input wire [63:0]   H2C_ST_PORT3_0_h2c_tkeep,
  input wire          H2C_ST_PORT3_0_h2c_tlast,
  input wire          H2C_ST_PORT3_0_h2c_tready,
  input wire          H2C_ST_PORT3_0_h2c_tvalid,
  input wire [10:0]   H2C_ST_PORT3_0_h2c_tuser_qid,
  input wire [2:0]    H2C_ST_PORT3_0_h2c_tuser_port_id,
  input wire [5:0]    H2C_ST_PORT3_0_h2c_tuser_mty,
  input wire          H2C_ST_PORT3_0_h2c_tuser_err,

  // -------------------------------------------------------------------------
  // C2H ST PORT0 — native QDMA streaming input (user → QDMA)
  // -------------------------------------------------------------------------
  input wire [511:0]  C2H_ST_PORT0_0_c2h_tdata,
  input wire [63:0]   C2H_ST_PORT0_0_c2h_tkeep,
  input wire          C2H_ST_PORT0_0_c2h_tlast,
  input wire          C2H_ST_PORT0_0_c2h_tready,   // OUTPUT from the block design
  input wire          C2H_ST_PORT0_0_c2h_tvalid,
  input wire          C2H_ST_PORT0_0_c2h_ctrl_has_cmpt,
  input wire [15:0]   C2H_ST_PORT0_0_c2h_ctrl_len,
  input wire          C2H_ST_PORT0_0_c2h_ctrl_marker,
  input wire [2:0]    C2H_ST_PORT0_0_c2h_ctrl_port_id,
  input wire [10:0]   C2H_ST_PORT0_0_c2h_ctrl_qid,
  input wire [5:0]    C2H_ST_PORT0_0_c2h_mty,

  // C2H ST PORT1
  input wire [511:0]  C2H_ST_PORT1_0_c2h_tdata,
  input wire [63:0]   C2H_ST_PORT1_0_c2h_tkeep,
  input wire          C2H_ST_PORT1_0_c2h_tlast,
  input wire          C2H_ST_PORT1_0_c2h_tready,
  input wire          C2H_ST_PORT1_0_c2h_tvalid,
  input wire          C2H_ST_PORT1_0_c2h_ctrl_has_cmpt,
  input wire [15:0]   C2H_ST_PORT1_0_c2h_ctrl_len,
  input wire          C2H_ST_PORT1_0_c2h_ctrl_marker,
  input wire [2:0]    C2H_ST_PORT1_0_c2h_ctrl_port_id,
  input wire [10:0]   C2H_ST_PORT1_0_c2h_ctrl_qid,
  input wire [5:0]    C2H_ST_PORT1_0_c2h_mty,

  // C2H ST PORT2
  input wire [511:0]  C2H_ST_PORT2_0_c2h_tdata,
  input wire [63:0]   C2H_ST_PORT2_0_c2h_tkeep,
  input wire          C2H_ST_PORT2_0_c2h_tlast,
  input wire          C2H_ST_PORT2_0_c2h_tready,
  input wire          C2H_ST_PORT2_0_c2h_tvalid,
  input wire          C2H_ST_PORT2_0_c2h_ctrl_has_cmpt,
  input wire [15:0]   C2H_ST_PORT2_0_c2h_ctrl_len,
  input wire          C2H_ST_PORT2_0_c2h_ctrl_marker,
  input wire [2:0]    C2H_ST_PORT2_0_c2h_ctrl_port_id,
  input wire [10:0]   C2H_ST_PORT2_0_c2h_ctrl_qid,
  input wire [5:0]    C2H_ST_PORT2_0_c2h_mty,

  // C2H ST PORT3
  input wire [511:0]  C2H_ST_PORT3_0_c2h_tdata,
  input wire [63:0]   C2H_ST_PORT3_0_c2h_tkeep,
  input wire          C2H_ST_PORT3_0_c2h_tlast,
  input wire          C2H_ST_PORT3_0_c2h_tready,
  input wire          C2H_ST_PORT3_0_c2h_tvalid,
  input wire          C2H_ST_PORT3_0_c2h_ctrl_has_cmpt,
  input wire [15:0]   C2H_ST_PORT3_0_c2h_ctrl_len,
  input wire          C2H_ST_PORT3_0_c2h_ctrl_marker,
  input wire [2:0]    C2H_ST_PORT3_0_c2h_ctrl_port_id,
  input wire [10:0]   C2H_ST_PORT3_0_c2h_ctrl_qid,
  input wire [5:0]    C2H_ST_PORT3_0_c2h_mty
);
  `include "uvm_macros.svh"

  // -------------------------------------------------------------------------
  // AXI4-Stream user interface instance
  // -------------------------------------------------------------------------
  qdma_user_if vif_inst0 (
    .aclk    (ps_wizard_0_pl0_ref_clk),
    .aresetn (ps_wizard_0_pl0_resetn)
  );

  qdma_user_if vif_inst1 (
    .aclk    (ps_wizard_0_pl0_ref_clk),
    .aresetn (ps_wizard_0_pl0_resetn)
  );

  qdma_user_if vif_inst2 (
    .aclk    (ps_wizard_0_pl0_ref_clk),
    .aresetn (ps_wizard_0_pl0_resetn)
  );

  qdma_user_if vif_inst3 (
    .aclk    (ps_wizard_0_pl0_ref_clk),
    .aresetn (ps_wizard_0_pl0_resetn)
  );

  // -------------------------------------------------------------------------
  // H2C: Wire native PORT outputs directly to VIF
  // -------------------------------------------------------------------------
  assign vif_inst0.h2c_tdata           = H2C_ST_PORT0_0_h2c_tdata;
  assign vif_inst0.h2c_tkeep           = H2C_ST_PORT0_0_h2c_tkeep;
  assign vif_inst0.h2c_tlast           = H2C_ST_PORT0_0_h2c_tlast;
  assign vif_inst0.h2c_tvalid          = H2C_ST_PORT0_0_h2c_tvalid;
  assign vif_inst0.h2c_tuser_qid       = {1'b0, H2C_ST_PORT0_0_h2c_tuser_qid};
  assign vif_inst0.h2c_tuser_port_id   = H2C_ST_PORT0_0_h2c_tuser_port_id;
  assign vif_inst0.h2c_tuser_mty       = H2C_ST_PORT0_0_h2c_tuser_mty;
  assign vif_inst0.h2c_tuser_err       = {2'b0, H2C_ST_PORT0_0_h2c_tuser_err};
  assign vif_inst0.h2c_tuser_zero_byte = 3'b0;

  assign vif_inst1.h2c_tdata           = H2C_ST_PORT1_0_h2c_tdata;
  assign vif_inst1.h2c_tkeep           = H2C_ST_PORT1_0_h2c_tkeep;
  assign vif_inst1.h2c_tlast           = H2C_ST_PORT1_0_h2c_tlast;
  assign vif_inst1.h2c_tvalid          = H2C_ST_PORT1_0_h2c_tvalid;
  assign vif_inst1.h2c_tuser_qid       = {1'b0, H2C_ST_PORT1_0_h2c_tuser_qid};
  assign vif_inst1.h2c_tuser_port_id   = H2C_ST_PORT1_0_h2c_tuser_port_id;
  assign vif_inst1.h2c_tuser_mty       = H2C_ST_PORT1_0_h2c_tuser_mty;
  assign vif_inst1.h2c_tuser_err       = {2'b0, H2C_ST_PORT1_0_h2c_tuser_err};
  assign vif_inst1.h2c_tuser_zero_byte = 3'b0;

  assign vif_inst2.h2c_tdata           = H2C_ST_PORT2_0_h2c_tdata;
  assign vif_inst2.h2c_tkeep           = H2C_ST_PORT2_0_h2c_tkeep;
  assign vif_inst2.h2c_tlast           = H2C_ST_PORT2_0_h2c_tlast;
  assign vif_inst2.h2c_tvalid          = H2C_ST_PORT2_0_h2c_tvalid;
  assign vif_inst2.h2c_tuser_qid       = {1'b0, H2C_ST_PORT2_0_h2c_tuser_qid};
  assign vif_inst2.h2c_tuser_port_id   = H2C_ST_PORT2_0_h2c_tuser_port_id;
  assign vif_inst2.h2c_tuser_mty       = H2C_ST_PORT2_0_h2c_tuser_mty;
  assign vif_inst2.h2c_tuser_err       = {2'b0, H2C_ST_PORT2_0_h2c_tuser_err};
  assign vif_inst2.h2c_tuser_zero_byte = 3'b0;

  assign vif_inst3.h2c_tdata           = H2C_ST_PORT3_0_h2c_tdata;
  assign vif_inst3.h2c_tkeep           = H2C_ST_PORT3_0_h2c_tkeep;
  assign vif_inst3.h2c_tlast           = H2C_ST_PORT3_0_h2c_tlast;
  assign vif_inst3.h2c_tvalid          = H2C_ST_PORT3_0_h2c_tvalid;
  assign vif_inst3.h2c_tuser_qid       = {1'b0, H2C_ST_PORT3_0_h2c_tuser_qid};
  assign vif_inst3.h2c_tuser_port_id   = H2C_ST_PORT3_0_h2c_tuser_port_id;
  assign vif_inst3.h2c_tuser_mty       = H2C_ST_PORT3_0_h2c_tuser_mty;
  assign vif_inst3.h2c_tuser_err       = {2'b0, H2C_ST_PORT3_0_h2c_tuser_err};
  assign vif_inst3.h2c_tuser_zero_byte = 3'b0;

  // C2H: wire tready (output from the block design) to the VIF
  assign vif_inst0.c2h_tready         = C2H_ST_PORT0_0_c2h_tready;
  assign vif_inst1.c2h_tready         = C2H_ST_PORT1_0_c2h_tready;
  assign vif_inst2.c2h_tready         = C2H_ST_PORT2_0_c2h_tready;
  assign vif_inst3.c2h_tready         = C2H_ST_PORT3_0_c2h_tready;

  // -------------------------------------------------------------------------
  // H2C tready: driven by h2c_sink in the example-design wrapper; not
  // connected to the VIF.
  // -------------------------------------------------------------------------

  // -------------------------------------------------------------------------
  // C2H: wire c2h_source_ctrl outputs (via block design ports) to VIF for monitoring.
  // c2h_source_ctrl drives these structurally from the wrapper.
  // -------------------------------------------------------------------------
  assign vif_inst0.c2h_tdata           = C2H_ST_PORT0_0_c2h_tdata;
  assign vif_inst0.c2h_tkeep           = C2H_ST_PORT0_0_c2h_tkeep;
  assign vif_inst0.c2h_tlast           = C2H_ST_PORT0_0_c2h_tlast;
  assign vif_inst0.c2h_tvalid          = C2H_ST_PORT0_0_c2h_tvalid;
  assign vif_inst0.c2h_ctrl_qid        = {1'b0, C2H_ST_PORT0_0_c2h_ctrl_qid};
  assign vif_inst0.c2h_mty             = C2H_ST_PORT0_0_c2h_mty;
  assign vif_inst0.c2h_ctrl_port_id    = C2H_ST_PORT0_0_c2h_ctrl_port_id;
  assign vif_inst0.c2h_ctrl_marker     = C2H_ST_PORT0_0_c2h_ctrl_marker;
  assign vif_inst0.c2h_ctrl_has_cmpt   = C2H_ST_PORT0_0_c2h_ctrl_has_cmpt;
  assign vif_inst0.c2h_ctrl_len        = C2H_ST_PORT0_0_c2h_ctrl_len;

  assign vif_inst1.c2h_tdata           = C2H_ST_PORT1_0_c2h_tdata;
  assign vif_inst1.c2h_tkeep           = C2H_ST_PORT1_0_c2h_tkeep;
  assign vif_inst1.c2h_tlast           = C2H_ST_PORT1_0_c2h_tlast;
  assign vif_inst1.c2h_tvalid          = C2H_ST_PORT1_0_c2h_tvalid;
  assign vif_inst1.c2h_ctrl_qid        = {1'b0, C2H_ST_PORT1_0_c2h_ctrl_qid};
  assign vif_inst1.c2h_mty             = C2H_ST_PORT1_0_c2h_mty;
  assign vif_inst1.c2h_ctrl_port_id    = C2H_ST_PORT1_0_c2h_ctrl_port_id;
  assign vif_inst1.c2h_ctrl_marker     = C2H_ST_PORT1_0_c2h_ctrl_marker;
  assign vif_inst1.c2h_ctrl_has_cmpt   = C2H_ST_PORT1_0_c2h_ctrl_has_cmpt;
  assign vif_inst1.c2h_ctrl_len        = C2H_ST_PORT1_0_c2h_ctrl_len;

  assign vif_inst2.c2h_tdata           = C2H_ST_PORT2_0_c2h_tdata;
  assign vif_inst2.c2h_tkeep           = C2H_ST_PORT2_0_c2h_tkeep;
  assign vif_inst2.c2h_tlast           = C2H_ST_PORT2_0_c2h_tlast;
  assign vif_inst2.c2h_tvalid          = C2H_ST_PORT2_0_c2h_tvalid;
  assign vif_inst2.c2h_ctrl_qid        = {1'b0, C2H_ST_PORT2_0_c2h_ctrl_qid};
  assign vif_inst2.c2h_mty             = C2H_ST_PORT2_0_c2h_mty;
  assign vif_inst2.c2h_ctrl_port_id    = C2H_ST_PORT2_0_c2h_ctrl_port_id;
  assign vif_inst2.c2h_ctrl_marker     = C2H_ST_PORT2_0_c2h_ctrl_marker;
  assign vif_inst2.c2h_ctrl_has_cmpt   = C2H_ST_PORT2_0_c2h_ctrl_has_cmpt;
  assign vif_inst2.c2h_ctrl_len        = C2H_ST_PORT2_0_c2h_ctrl_len;

  assign vif_inst3.c2h_tdata           = C2H_ST_PORT3_0_c2h_tdata;
  assign vif_inst3.c2h_tkeep           = C2H_ST_PORT3_0_c2h_tkeep;
  assign vif_inst3.c2h_tlast           = C2H_ST_PORT3_0_c2h_tlast;
  assign vif_inst3.c2h_tvalid          = C2H_ST_PORT3_0_c2h_tvalid;
  assign vif_inst3.c2h_ctrl_qid        = {1'b0, C2H_ST_PORT3_0_c2h_ctrl_qid};
  assign vif_inst3.c2h_mty             = C2H_ST_PORT3_0_c2h_mty;
  assign vif_inst3.c2h_ctrl_port_id    = C2H_ST_PORT3_0_c2h_ctrl_port_id;
  assign vif_inst3.c2h_ctrl_marker     = C2H_ST_PORT3_0_c2h_ctrl_marker;
  assign vif_inst3.c2h_ctrl_has_cmpt   = C2H_ST_PORT3_0_c2h_ctrl_has_cmpt;
  assign vif_inst3.c2h_ctrl_len        = C2H_ST_PORT3_0_c2h_ctrl_len;

  // -------------------------------------------------------------------------
  // Register VIF in UVM config_db
  // -------------------------------------------------------------------------
  initial begin
    uvm_pkg::uvm_config_db#(virtual qdma_user_if)::set(
      null, "*", "qdma_user_vif", vif_inst0);
    uvm_pkg::uvm_config_db#(virtual qdma_user_if)::set(
      null, "*", "qdma_user_vif0", vif_inst0);
    uvm_pkg::uvm_config_db#(virtual qdma_user_if)::set(
      null, "*", "qdma_user_vif1", vif_inst1);
    uvm_pkg::uvm_config_db#(virtual qdma_user_if)::set(
      null, "*", "qdma_user_vif2", vif_inst2);
    uvm_pkg::uvm_config_db#(virtual qdma_user_if)::set(
      null, "*", "qdma_user_vif3", vif_inst3);
  end



endmodule : bind_qdma_user_st
`default_nettype none

bind `CPM6_BD_TOP_MODULE bind_qdma_user_st bind_qdma_user_st_inst (.*);
`default_nettype wire
