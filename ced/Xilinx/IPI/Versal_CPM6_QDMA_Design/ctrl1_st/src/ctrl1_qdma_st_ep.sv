//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
// ctrl1_qdma_st_ep.sv -- CTRL1 top-level EP wrapper for the streaming (ST)
// configuration of Versal_CPM6_QDMA_Design.
//
// Instantiates the "cpm6_qdma" block design (see ../design_1_bd.tcl). As in
// the memory-mapped configuration, the CED framework creates the block design
// under the name in design.xml before sourcing design_1_bd.tcl.
//
// Only the GT lanes and their reference clock leave the device. The QDMA
// streaming interfaces are terminated by the example design in this module:
//   - H2C stream ports 0-3      -> h2c_sink (one per port)
//   - C2H stream ports 0-3      <- c2h_source_ctrl (one per port)
//   - C2H completion ports 0-3  <- c2h_cmpt_gen (one per port)
//   - descriptor credits / tm_dsc_sts <-> dsc_crdt_exerciser
//   - M_AXIL_C2H_CFG (host register window) -> c2h_source_cfg
// The example logic runs on the block design's axi_clk (PL0 reference clock)
// and the matching active-low axi_rst_n, both exported as block design ports.
//--------------------------------------------------------------------------------

`timescale 1ps/1ps

module ctrl1_qdma_st_ep
import qdma_link_pkg::*;
(
    input  [LINK_WIDTH-1:0] CTRL1_GT_0_grx_n,
    input  [LINK_WIDTH-1:0] CTRL1_GT_0_grx_p,
    output [LINK_WIDTH-1:0] CTRL1_GT_0_gtx_n,
    output [LINK_WIDTH-1:0] CTRL1_GT_0_gtx_p,
    input                   ctrl1_gt_refclk_0_clk_n,
    input                   ctrl1_gt_refclk_0_clk_p
);

    // =========================================================================
    // Internal wires — H2C ST (output from QDMA)
    // =========================================================================
    wire [511:0] h2c_st_port0_tdata,  h2c_st_port1_tdata,  h2c_st_port2_tdata,  h2c_st_port3_tdata;
    wire [63:0]  h2c_st_port0_tkeep,  h2c_st_port1_tkeep,  h2c_st_port2_tkeep,  h2c_st_port3_tkeep;
    wire         h2c_st_port0_tlast,  h2c_st_port1_tlast,  h2c_st_port2_tlast,  h2c_st_port3_tlast;
    wire         h2c_st_port0_tvalid, h2c_st_port1_tvalid, h2c_st_port2_tvalid, h2c_st_port3_tvalid;
    wire         h2c_st_port0_tready, h2c_st_port1_tready, h2c_st_port2_tready, h2c_st_port3_tready;
    wire         h2c_st_port0_tuser_err,  h2c_st_port1_tuser_err,  h2c_st_port2_tuser_err,  h2c_st_port3_tuser_err;
    wire [5:0]   h2c_st_port0_tuser_mty,  h2c_st_port1_tuser_mty,  h2c_st_port2_tuser_mty,  h2c_st_port3_tuser_mty;
    wire [2:0]   h2c_st_port0_tuser_port_id, h2c_st_port1_tuser_port_id, h2c_st_port2_tuser_port_id, h2c_st_port3_tuser_port_id;
    wire [11:0]  h2c_st_port0_tuser_qid, h2c_st_port1_tuser_qid, h2c_st_port2_tuser_qid, h2c_st_port3_tuser_qid;

    // =========================================================================
    // Internal wires — C2H ST (input to QDMA)
    // =========================================================================
    wire [511:0] c2h_st_port0_tdata,  c2h_st_port1_tdata,  c2h_st_port2_tdata,  c2h_st_port3_tdata;
    wire [63:0]  c2h_st_port0_tkeep,  c2h_st_port1_tkeep,  c2h_st_port2_tkeep,  c2h_st_port3_tkeep;
    wire         c2h_st_port0_tlast,  c2h_st_port1_tlast,  c2h_st_port2_tlast,  c2h_st_port3_tlast;
    wire         c2h_st_port0_tvalid, c2h_st_port1_tvalid, c2h_st_port2_tvalid, c2h_st_port3_tvalid;
    wire         c2h_st_port0_tready, c2h_st_port1_tready, c2h_st_port2_tready, c2h_st_port3_tready;
    wire [11:0]  c2h_st_port0_ctrl_qid, c2h_st_port1_ctrl_qid, c2h_st_port2_ctrl_qid, c2h_st_port3_ctrl_qid;
    wire [5:0]   c2h_st_port0_mty,  c2h_st_port1_mty,  c2h_st_port2_mty,  c2h_st_port3_mty;
    wire [2:0]   c2h_st_port0_ctrl_port_id, c2h_st_port1_ctrl_port_id, c2h_st_port2_ctrl_port_id, c2h_st_port3_ctrl_port_id;
    wire         c2h_st_port0_ctrl_marker,  c2h_st_port1_ctrl_marker,  c2h_st_port2_ctrl_marker,  c2h_st_port3_ctrl_marker;
    wire         c2h_st_port0_ctrl_has_cmpt, c2h_st_port1_ctrl_has_cmpt, c2h_st_port2_ctrl_has_cmpt, c2h_st_port3_ctrl_has_cmpt;
    wire [15:0]  c2h_st_port0_ctrl_len, c2h_st_port1_ctrl_len, c2h_st_port2_ctrl_len, c2h_st_port3_ctrl_len;

    // =========================================================================
    // Internal wires — C2H CMPT (completion ports 0-3)
    // =========================================================================
    wire [511:0] c2h_cmpt_port0_tdata,  c2h_cmpt_port1_tdata,  c2h_cmpt_port2_tdata,  c2h_cmpt_port3_tdata;
    wire [1:0]   c2h_cmpt_port0_size,   c2h_cmpt_port1_size,   c2h_cmpt_port2_size,   c2h_cmpt_port3_size;
    wire [15:0]  c2h_cmpt_port0_dpar,   c2h_cmpt_port1_dpar,   c2h_cmpt_port2_dpar,   c2h_cmpt_port3_dpar;
    wire [10:0]  c2h_cmpt_port0_ctrl_qid, c2h_cmpt_port1_ctrl_qid, c2h_cmpt_port2_ctrl_qid, c2h_cmpt_port3_ctrl_qid;
    wire [2:0]   c2h_cmpt_port0_ctrl_port_id, c2h_cmpt_port1_ctrl_port_id, c2h_cmpt_port2_ctrl_port_id, c2h_cmpt_port3_ctrl_port_id;
    wire [1:0]   c2h_cmpt_port0_ctrl_cmpt_type, c2h_cmpt_port1_ctrl_cmpt_type, c2h_cmpt_port2_ctrl_cmpt_type, c2h_cmpt_port3_ctrl_cmpt_type;
    wire [15:0]  c2h_cmpt_port0_ctrl_wait_pld_pkt_id, c2h_cmpt_port1_ctrl_wait_pld_pkt_id, c2h_cmpt_port2_ctrl_wait_pld_pkt_id, c2h_cmpt_port3_ctrl_wait_pld_pkt_id;
    wire         c2h_cmpt_port0_ctrl_user_trig, c2h_cmpt_port1_ctrl_user_trig, c2h_cmpt_port2_ctrl_user_trig, c2h_cmpt_port3_ctrl_user_trig;
    wire [2:0]   c2h_cmpt_port0_ctrl_col_idx, c2h_cmpt_port1_ctrl_col_idx, c2h_cmpt_port2_ctrl_col_idx, c2h_cmpt_port3_ctrl_col_idx;
    wire         c2h_cmpt_port0_ctrl_no_wrb_marker, c2h_cmpt_port1_ctrl_no_wrb_marker, c2h_cmpt_port2_ctrl_no_wrb_marker, c2h_cmpt_port3_ctrl_no_wrb_marker;
    wire         c2h_cmpt_port0_tvalid, c2h_cmpt_port1_tvalid, c2h_cmpt_port2_tvalid, c2h_cmpt_port3_tvalid;
    wire         c2h_cmpt_port0_tready, c2h_cmpt_port1_tready, c2h_cmpt_port2_tready, c2h_cmpt_port3_tready;

    // CMPT trigger wires (from c2h_source_ctrl ports 0-3)
    wire         cmpt_trigger_0,     cmpt_trigger_1,     cmpt_trigger_2,     cmpt_trigger_3;
    wire [10:0]  cmpt_trigger_qid_0, cmpt_trigger_qid_1, cmpt_trigger_qid_2, cmpt_trigger_qid_3;
    wire [2:0]   cmpt_trigger_port_id_0, cmpt_trigger_port_id_1, cmpt_trigger_port_id_2, cmpt_trigger_port_id_3;
    wire [15:0]  cmpt_trigger_len_0, cmpt_trigger_len_1, cmpt_trigger_len_2, cmpt_trigger_len_3;
    wire         cmpt_trigger_rdy_0, cmpt_trigger_rdy_1, cmpt_trigger_rdy_2, cmpt_trigger_rdy_3;

    // C2H packet-size configuration (host AXI-Lite -> c2h_source_cfg -> c2h_source_ctrl)
    wire [48:0]  c2h_cfg_axil_awaddr, c2h_cfg_axil_araddr;   // M_AXIL_C2H_CFG is 49-bit (CPM_AXI_PL3 addresses carry bit 48)
    wire [2:0]   c2h_cfg_axil_awprot, c2h_cfg_axil_arprot;
    wire         c2h_cfg_axil_awvalid, c2h_cfg_axil_awready, c2h_cfg_axil_arvalid, c2h_cfg_axil_arready;
    wire [31:0]  c2h_cfg_axil_wdata, c2h_cfg_axil_rdata;
    wire [3:0]   c2h_cfg_axil_wstrb;
    wire         c2h_cfg_axil_wvalid, c2h_cfg_axil_wready;
    wire [1:0]   c2h_cfg_axil_bresp, c2h_cfg_axil_rresp;
    wire         c2h_cfg_axil_bvalid, c2h_cfg_axil_bready, c2h_cfg_axil_rvalid, c2h_cfg_axil_rready;
    wire [3:0][9:0] c2h_cfg_pkt_beats;
    wire [3:0][3:0] c2h_cfg_pkt_dsc;
    wire [3:0][10:0] c2h_cfg_qid;
    wire [3:0][15:0] c2h_cfg_num_pkt;
    wire [3:0]   c2h_cfg_start, c2h_cfg_stop;
    wire [3:0]   c2h_sts_pkt_start, c2h_sts_busy;
    wire [3:0][15:0] c2h_sts_left, c2h_sts_burst_seq;

    // =========================================================================
    // Internal wires — DSC_CRDT_IN
    // =========================================================================
    wire [15:0] dsc_crdt_in_crdt;
    wire        dsc_crdt_in_dir, dsc_crdt_in_fence, dsc_crdt_in_vld, dsc_crdt_in_rdy;
    wire [11:0] dsc_crdt_in_qid;

    // =========================================================================
    // Internal wires — tm_dsc_sts
    // =========================================================================
    wire [15:0] tm_dsc_sts_avl;
    wire        tm_dsc_sts_byp, tm_dsc_sts_dir, tm_dsc_sts_error;
    wire [11:0] tm_dsc_sts_func;
    wire        tm_dsc_sts_irq_arm, tm_dsc_sts_mm;
    wire [15:0] tm_dsc_sts_pidx;
    wire [2:0]  tm_dsc_sts_port_id;
    wire        tm_dsc_sts_qen, tm_dsc_sts_qinv, tm_dsc_sts_valid, tm_dsc_sts_rdy;
    wire [12:0] tm_dsc_sts_qid;

    // Example-design clock and reset, from the block design ports
    wire        axi_clk;
    wire        axi_rst_n;

    // =========================================================================
    // Block Design instantiation
    // =========================================================================
    cpm6_qdma ctrl1_ep_i (
        // GT lanes
        .CTRL1_GT_0_grx_n           (CTRL1_GT_0_grx_n),
        .CTRL1_GT_0_grx_p           (CTRL1_GT_0_grx_p),
        .CTRL1_GT_0_gtx_n           (CTRL1_GT_0_gtx_n),
        .CTRL1_GT_0_gtx_p           (CTRL1_GT_0_gtx_p),
        .ctrl1_gt_refclk_0_clk_n    (ctrl1_gt_refclk_0_clk_n),
        .ctrl1_gt_refclk_0_clk_p    (ctrl1_gt_refclk_0_clk_p),

        // Example-design clock and reset
        .axi_clk                    (axi_clk),
        .axi_rst_n                  (axi_rst_n),

        // H2C ST ports (master — from QDMA)
        .H2C_ST_PORT0_0_h2c_tdata       (h2c_st_port0_tdata),
        .H2C_ST_PORT0_0_h2c_tkeep       (h2c_st_port0_tkeep),
        .H2C_ST_PORT0_0_h2c_tlast       (h2c_st_port0_tlast),
        .H2C_ST_PORT0_0_h2c_tvalid      (h2c_st_port0_tvalid),
        .H2C_ST_PORT0_0_h2c_tready      (h2c_st_port0_tready),
        .H2C_ST_PORT0_0_h2c_tuser_err   (h2c_st_port0_tuser_err),
        .H2C_ST_PORT0_0_h2c_tuser_mty   (h2c_st_port0_tuser_mty),
        .H2C_ST_PORT0_0_h2c_tuser_port_id(h2c_st_port0_tuser_port_id),
        .H2C_ST_PORT0_0_h2c_tuser_qid   (h2c_st_port0_tuser_qid),

        .H2C_ST_PORT1_0_h2c_tdata       (h2c_st_port1_tdata),
        .H2C_ST_PORT1_0_h2c_tkeep       (h2c_st_port1_tkeep),
        .H2C_ST_PORT1_0_h2c_tlast       (h2c_st_port1_tlast),
        .H2C_ST_PORT1_0_h2c_tvalid      (h2c_st_port1_tvalid),
        .H2C_ST_PORT1_0_h2c_tready      (h2c_st_port1_tready),
        .H2C_ST_PORT1_0_h2c_tuser_err   (h2c_st_port1_tuser_err),
        .H2C_ST_PORT1_0_h2c_tuser_mty   (h2c_st_port1_tuser_mty),
        .H2C_ST_PORT1_0_h2c_tuser_port_id(h2c_st_port1_tuser_port_id),
        .H2C_ST_PORT1_0_h2c_tuser_qid   (h2c_st_port1_tuser_qid),

        .H2C_ST_PORT2_0_h2c_tdata       (h2c_st_port2_tdata),
        .H2C_ST_PORT2_0_h2c_tkeep       (h2c_st_port2_tkeep),
        .H2C_ST_PORT2_0_h2c_tlast       (h2c_st_port2_tlast),
        .H2C_ST_PORT2_0_h2c_tvalid      (h2c_st_port2_tvalid),
        .H2C_ST_PORT2_0_h2c_tready      (h2c_st_port2_tready),
        .H2C_ST_PORT2_0_h2c_tuser_err   (h2c_st_port2_tuser_err),
        .H2C_ST_PORT2_0_h2c_tuser_mty   (h2c_st_port2_tuser_mty),
        .H2C_ST_PORT2_0_h2c_tuser_port_id(h2c_st_port2_tuser_port_id),
        .H2C_ST_PORT2_0_h2c_tuser_qid   (h2c_st_port2_tuser_qid),

        .H2C_ST_PORT3_0_h2c_tdata       (h2c_st_port3_tdata),
        .H2C_ST_PORT3_0_h2c_tkeep       (h2c_st_port3_tkeep),
        .H2C_ST_PORT3_0_h2c_tlast       (h2c_st_port3_tlast),
        .H2C_ST_PORT3_0_h2c_tvalid      (h2c_st_port3_tvalid),
        .H2C_ST_PORT3_0_h2c_tready      (h2c_st_port3_tready),
        .H2C_ST_PORT3_0_h2c_tuser_err   (h2c_st_port3_tuser_err),
        .H2C_ST_PORT3_0_h2c_tuser_mty   (h2c_st_port3_tuser_mty),
        .H2C_ST_PORT3_0_h2c_tuser_port_id(h2c_st_port3_tuser_port_id),
        .H2C_ST_PORT3_0_h2c_tuser_qid   (h2c_st_port3_tuser_qid),

        // C2H ST ports (slave — to QDMA)
        .C2H_ST_PORT0_0_c2h_tdata       (c2h_st_port0_tdata),
        .C2H_ST_PORT0_0_c2h_tkeep       (c2h_st_port0_tkeep),
        .C2H_ST_PORT0_0_c2h_tlast       (c2h_st_port0_tlast),
        .C2H_ST_PORT0_0_c2h_tvalid      (c2h_st_port0_tvalid),
        .C2H_ST_PORT0_0_c2h_tready      (c2h_st_port0_tready),
        .C2H_ST_PORT0_0_c2h_ctrl_qid    (c2h_st_port0_ctrl_qid),
        .C2H_ST_PORT0_0_c2h_mty         (c2h_st_port0_mty),
        .C2H_ST_PORT0_0_c2h_ctrl_port_id(c2h_st_port0_ctrl_port_id),
        .C2H_ST_PORT0_0_c2h_ctrl_marker (c2h_st_port0_ctrl_marker),
        .C2H_ST_PORT0_0_c2h_ctrl_has_cmpt(c2h_st_port0_ctrl_has_cmpt),
        .C2H_ST_PORT0_0_c2h_ctrl_len    (c2h_st_port0_ctrl_len),

        .C2H_ST_PORT1_0_c2h_tdata       (c2h_st_port1_tdata),
        .C2H_ST_PORT1_0_c2h_tkeep       (c2h_st_port1_tkeep),
        .C2H_ST_PORT1_0_c2h_tlast       (c2h_st_port1_tlast),
        .C2H_ST_PORT1_0_c2h_tvalid      (c2h_st_port1_tvalid),
        .C2H_ST_PORT1_0_c2h_tready      (c2h_st_port1_tready),
        .C2H_ST_PORT1_0_c2h_ctrl_qid    (c2h_st_port1_ctrl_qid),
        .C2H_ST_PORT1_0_c2h_mty         (c2h_st_port1_mty),
        .C2H_ST_PORT1_0_c2h_ctrl_port_id(c2h_st_port1_ctrl_port_id),
        .C2H_ST_PORT1_0_c2h_ctrl_marker (c2h_st_port1_ctrl_marker),
        .C2H_ST_PORT1_0_c2h_ctrl_has_cmpt(c2h_st_port1_ctrl_has_cmpt),
        .C2H_ST_PORT1_0_c2h_ctrl_len    (c2h_st_port1_ctrl_len),

        .C2H_ST_PORT2_0_c2h_tdata       (c2h_st_port2_tdata),
        .C2H_ST_PORT2_0_c2h_tkeep       (c2h_st_port2_tkeep),
        .C2H_ST_PORT2_0_c2h_tlast       (c2h_st_port2_tlast),
        .C2H_ST_PORT2_0_c2h_tvalid      (c2h_st_port2_tvalid),
        .C2H_ST_PORT2_0_c2h_tready      (c2h_st_port2_tready),
        .C2H_ST_PORT2_0_c2h_ctrl_qid    (c2h_st_port2_ctrl_qid),
        .C2H_ST_PORT2_0_c2h_mty         (c2h_st_port2_mty),
        .C2H_ST_PORT2_0_c2h_ctrl_port_id(c2h_st_port2_ctrl_port_id),
        .C2H_ST_PORT2_0_c2h_ctrl_marker (c2h_st_port2_ctrl_marker),
        .C2H_ST_PORT2_0_c2h_ctrl_has_cmpt(c2h_st_port2_ctrl_has_cmpt),
        .C2H_ST_PORT2_0_c2h_ctrl_len    (c2h_st_port2_ctrl_len),

        .C2H_ST_PORT3_0_c2h_tdata       (c2h_st_port3_tdata),
        .C2H_ST_PORT3_0_c2h_tkeep       (c2h_st_port3_tkeep),
        .C2H_ST_PORT3_0_c2h_tlast       (c2h_st_port3_tlast),
        .C2H_ST_PORT3_0_c2h_tvalid      (c2h_st_port3_tvalid),
        .C2H_ST_PORT3_0_c2h_tready      (c2h_st_port3_tready),
        .C2H_ST_PORT3_0_c2h_ctrl_qid    (c2h_st_port3_ctrl_qid),
        .C2H_ST_PORT3_0_c2h_mty         (c2h_st_port3_mty),
        .C2H_ST_PORT3_0_c2h_ctrl_port_id(c2h_st_port3_ctrl_port_id),
        .C2H_ST_PORT3_0_c2h_ctrl_marker (c2h_st_port3_ctrl_marker),
        .C2H_ST_PORT3_0_c2h_ctrl_has_cmpt(c2h_st_port3_ctrl_has_cmpt),
        .C2H_ST_PORT3_0_c2h_ctrl_len    (c2h_st_port3_ctrl_len),

        // C2H Completion port 1 — driven by c2h_cmpt_gen
        .C2H_CMPT_PORT1_0_c2h_cmpt_tdata                 (c2h_cmpt_port1_tdata),
        .C2H_CMPT_PORT1_0_c2h_cmpt_size                  (c2h_cmpt_port1_size),
        .C2H_CMPT_PORT1_0_c2h_cmpt_dpar                  (c2h_cmpt_port1_dpar),
        .C2H_CMPT_PORT1_0_c2h_cmpt_ctrl_qid              (c2h_cmpt_port1_ctrl_qid),
        .C2H_CMPT_PORT1_0_c2h_cmpt_ctrl_port_id          (c2h_cmpt_port1_ctrl_port_id),
        .C2H_CMPT_PORT1_0_c2h_cmpt_ctrl_cmpt_type        (c2h_cmpt_port1_ctrl_cmpt_type),
        .C2H_CMPT_PORT1_0_c2h_cmpt_ctrl_wait_pld_pkt_id  (c2h_cmpt_port1_ctrl_wait_pld_pkt_id),
        .C2H_CMPT_PORT1_0_c2h_cmpt_ctrl_user_trig        (c2h_cmpt_port1_ctrl_user_trig),
        .C2H_CMPT_PORT1_0_c2h_cmpt_ctrl_col_idx          (c2h_cmpt_port1_ctrl_col_idx),
        .C2H_CMPT_PORT1_0_c2h_cmpt_ctrl_no_wrb_marker    (c2h_cmpt_port1_ctrl_no_wrb_marker),
        .C2H_CMPT_PORT1_0_c2h_cmpt_tvalid                (c2h_cmpt_port1_tvalid),
        .C2H_CMPT_PORT1_0_c2h_cmpt_tready                (c2h_cmpt_port1_tready),
        // C2H Completion port 2 — driven by c2h_cmpt_gen
        .C2H_CMPT_PORT2_0_c2h_cmpt_tdata                 (c2h_cmpt_port2_tdata),
        .C2H_CMPT_PORT2_0_c2h_cmpt_size                  (c2h_cmpt_port2_size),
        .C2H_CMPT_PORT2_0_c2h_cmpt_dpar                  (c2h_cmpt_port2_dpar),
        .C2H_CMPT_PORT2_0_c2h_cmpt_ctrl_qid              (c2h_cmpt_port2_ctrl_qid),
        .C2H_CMPT_PORT2_0_c2h_cmpt_ctrl_port_id          (c2h_cmpt_port2_ctrl_port_id),
        .C2H_CMPT_PORT2_0_c2h_cmpt_ctrl_cmpt_type        (c2h_cmpt_port2_ctrl_cmpt_type),
        .C2H_CMPT_PORT2_0_c2h_cmpt_ctrl_wait_pld_pkt_id  (c2h_cmpt_port2_ctrl_wait_pld_pkt_id),
        .C2H_CMPT_PORT2_0_c2h_cmpt_ctrl_user_trig        (c2h_cmpt_port2_ctrl_user_trig),
        .C2H_CMPT_PORT2_0_c2h_cmpt_ctrl_col_idx          (c2h_cmpt_port2_ctrl_col_idx),
        .C2H_CMPT_PORT2_0_c2h_cmpt_ctrl_no_wrb_marker    (c2h_cmpt_port2_ctrl_no_wrb_marker),
        .C2H_CMPT_PORT2_0_c2h_cmpt_tvalid                (c2h_cmpt_port2_tvalid),
        .C2H_CMPT_PORT2_0_c2h_cmpt_tready                (c2h_cmpt_port2_tready),
        // C2H Completion port 3 — driven by c2h_cmpt_gen
        .C2H_CMPT_PORT3_0_c2h_cmpt_tdata                 (c2h_cmpt_port3_tdata),
        .C2H_CMPT_PORT3_0_c2h_cmpt_size                  (c2h_cmpt_port3_size),
        .C2H_CMPT_PORT3_0_c2h_cmpt_dpar                  (c2h_cmpt_port3_dpar),
        .C2H_CMPT_PORT3_0_c2h_cmpt_ctrl_qid              (c2h_cmpt_port3_ctrl_qid),
        .C2H_CMPT_PORT3_0_c2h_cmpt_ctrl_port_id          (c2h_cmpt_port3_ctrl_port_id),
        .C2H_CMPT_PORT3_0_c2h_cmpt_ctrl_cmpt_type        (c2h_cmpt_port3_ctrl_cmpt_type),
        .C2H_CMPT_PORT3_0_c2h_cmpt_ctrl_wait_pld_pkt_id  (c2h_cmpt_port3_ctrl_wait_pld_pkt_id),
        .C2H_CMPT_PORT3_0_c2h_cmpt_ctrl_user_trig        (c2h_cmpt_port3_ctrl_user_trig),
        .C2H_CMPT_PORT3_0_c2h_cmpt_ctrl_col_idx          (c2h_cmpt_port3_ctrl_col_idx),
        .C2H_CMPT_PORT3_0_c2h_cmpt_ctrl_no_wrb_marker    (c2h_cmpt_port3_ctrl_no_wrb_marker),
        .C2H_CMPT_PORT3_0_c2h_cmpt_tvalid                (c2h_cmpt_port3_tvalid),
        .C2H_CMPT_PORT3_0_c2h_cmpt_tready                (c2h_cmpt_port3_tready),

        // tm_dsc_sts — driven to dsc_crdt_exerciser
        .tm_dsc_sts_0_avl           (tm_dsc_sts_avl),
        .tm_dsc_sts_0_byp           (tm_dsc_sts_byp),
        .tm_dsc_sts_0_dir           (tm_dsc_sts_dir),
        .tm_dsc_sts_0_error         (tm_dsc_sts_error),
        .tm_dsc_sts_0_func          (tm_dsc_sts_func),
        .tm_dsc_sts_0_irq_arm       (tm_dsc_sts_irq_arm),
        .tm_dsc_sts_0_mm            (tm_dsc_sts_mm),
        .tm_dsc_sts_0_pidx          (tm_dsc_sts_pidx),
        .tm_dsc_sts_0_port_id       (tm_dsc_sts_port_id),
        .tm_dsc_sts_0_qen           (tm_dsc_sts_qen),
        .tm_dsc_sts_0_qid           (tm_dsc_sts_qid),
        .tm_dsc_sts_0_qinv          (tm_dsc_sts_qinv),
        .tm_dsc_sts_0_rdy           (tm_dsc_sts_rdy),
        .tm_dsc_sts_0_valid         (tm_dsc_sts_valid),
        // DSC_CRDT_IN — driven by dsc_crdt_exerciser
        .dsc_crdt_in_0_vld          (dsc_crdt_in_vld),
        .dsc_crdt_in_0_rdy          (dsc_crdt_in_rdy),
        .dsc_crdt_in_0_dir          (dsc_crdt_in_dir),
        .dsc_crdt_in_0_fence        (dsc_crdt_in_fence),
        .dsc_crdt_in_0_qid          (dsc_crdt_in_qid[10:0]),
        .dsc_crdt_in_0_crdt         (dsc_crdt_in_crdt),

        // C2H packet-size configuration — AXI-Lite master from the host MMIO path
        .M_AXIL_C2H_CFG_awaddr      (c2h_cfg_axil_awaddr),
        .M_AXIL_C2H_CFG_awprot      (c2h_cfg_axil_awprot),
        .M_AXIL_C2H_CFG_awvalid     (c2h_cfg_axil_awvalid),
        .M_AXIL_C2H_CFG_awready     (c2h_cfg_axil_awready),
        .M_AXIL_C2H_CFG_wdata       (c2h_cfg_axil_wdata),
        .M_AXIL_C2H_CFG_wstrb       (c2h_cfg_axil_wstrb),
        .M_AXIL_C2H_CFG_wvalid      (c2h_cfg_axil_wvalid),
        .M_AXIL_C2H_CFG_wready      (c2h_cfg_axil_wready),
        .M_AXIL_C2H_CFG_bresp       (c2h_cfg_axil_bresp),
        .M_AXIL_C2H_CFG_bvalid      (c2h_cfg_axil_bvalid),
        .M_AXIL_C2H_CFG_bready      (c2h_cfg_axil_bready),
        .M_AXIL_C2H_CFG_araddr      (c2h_cfg_axil_araddr),
        .M_AXIL_C2H_CFG_arprot      (c2h_cfg_axil_arprot),
        .M_AXIL_C2H_CFG_arvalid     (c2h_cfg_axil_arvalid),
        .M_AXIL_C2H_CFG_arready     (c2h_cfg_axil_arready),
        .M_AXIL_C2H_CFG_rdata       (c2h_cfg_axil_rdata),
        .M_AXIL_C2H_CFG_rresp       (c2h_cfg_axil_rresp),
        .M_AXIL_C2H_CFG_rvalid      (c2h_cfg_axil_rvalid),
        .M_AXIL_C2H_CFG_rready      (c2h_cfg_axil_rready),

        // C2H Completion port 0 — driven by c2h_cmpt_gen
        .C2H_CMPT_PORT0_0_c2h_cmpt_tdata                 (c2h_cmpt_port0_tdata),
        .C2H_CMPT_PORT0_0_c2h_cmpt_size                  (c2h_cmpt_port0_size),
        .C2H_CMPT_PORT0_0_c2h_cmpt_dpar                  (c2h_cmpt_port0_dpar),
        .C2H_CMPT_PORT0_0_c2h_cmpt_ctrl_qid              (c2h_cmpt_port0_ctrl_qid),
        .C2H_CMPT_PORT0_0_c2h_cmpt_ctrl_port_id          (c2h_cmpt_port0_ctrl_port_id),
        .C2H_CMPT_PORT0_0_c2h_cmpt_ctrl_cmpt_type        (c2h_cmpt_port0_ctrl_cmpt_type),
        .C2H_CMPT_PORT0_0_c2h_cmpt_ctrl_wait_pld_pkt_id  (c2h_cmpt_port0_ctrl_wait_pld_pkt_id),
        .C2H_CMPT_PORT0_0_c2h_cmpt_ctrl_user_trig        (c2h_cmpt_port0_ctrl_user_trig),
        .C2H_CMPT_PORT0_0_c2h_cmpt_ctrl_col_idx          (c2h_cmpt_port0_ctrl_col_idx),
        .C2H_CMPT_PORT0_0_c2h_cmpt_ctrl_no_wrb_marker    (c2h_cmpt_port0_ctrl_no_wrb_marker),
        .C2H_CMPT_PORT0_0_c2h_cmpt_tvalid                (c2h_cmpt_port0_tvalid),
        .C2H_CMPT_PORT0_0_c2h_cmpt_tready                (c2h_cmpt_port0_tready)
    );

    // =========================================================================
    // Descriptor Credit Exerciser
    // Drives dsc_crdt_in and monitors tm_dsc_sts.
    // Its AXI-Lite programming port is tied idle in this design.
    // =========================================================================
    dsc_crdt_exerciser u_dsc_crdt (
        .aclk                (axi_clk),
        .aresetn             (axi_rst_n),
        // AXI-Lite slave — idle (no programming)
        .s_axil_awaddr       ('0),  .s_axil_awprot  ('0),  .s_axil_awvalid (1'b0), .s_axil_awready (),
        .s_axil_wdata        ('0),  .s_axil_wstrb   ('0),  .s_axil_wvalid  (1'b0), .s_axil_wready  (),
        .s_axil_bresp        (),    .s_axil_bvalid   (),    .s_axil_bready  (1'b1),
        .s_axil_araddr       ('0),  .s_axil_arprot  ('0),  .s_axil_arvalid (1'b0), .s_axil_arready (),
        .s_axil_rdata        (),    .s_axil_rresp    (),    .s_axil_rvalid  (),     .s_axil_rready  (1'b1),
        // dsc_crdt_in master
        .dsc_crdt_in_vld     (dsc_crdt_in_vld),
        .dsc_crdt_in_rdy     (dsc_crdt_in_rdy),
        .dsc_crdt_in_dir     (dsc_crdt_in_dir),
        .dsc_crdt_in_fence   (dsc_crdt_in_fence),
        .dsc_crdt_in_qid     (dsc_crdt_in_qid),
        .dsc_crdt_in_crdt    (dsc_crdt_in_crdt),
        // tm_dsc_sts monitor
        .tm_dsc_sts_vld      (tm_dsc_sts_valid),
        .tm_dsc_sts_rdy      (tm_dsc_sts_rdy),
        .tm_dsc_sts_qid      (tm_dsc_sts_qid),
        .tm_dsc_sts_dir      (tm_dsc_sts_dir),
        .tm_dsc_sts_avl      (tm_dsc_sts_avl),
        .tm_dsc_sts_error    (tm_dsc_sts_error),
        .tm_dsc_sts_qen      (tm_dsc_sts_qen),
        .tm_dsc_sts_byp      (tm_dsc_sts_byp),
        .tm_dsc_sts_mm       (tm_dsc_sts_mm),
        .tm_dsc_sts_qinv     (tm_dsc_sts_qinv),
        .tm_dsc_sts_irq_arm  (tm_dsc_sts_irq_arm),
        .tm_dsc_sts_port_id  (tm_dsc_sts_port_id),
        .tm_dsc_sts_pidx     (tm_dsc_sts_pidx),
        .tm_dsc_sts_func     (tm_dsc_sts_func),
        // Interrupt
        .irq_out             ()
    );

    // =========================================================================
    // C2H generator control
    // Per C2H port: packet length, queue, packet count and START/STOP, written
    // by the host through the M_AXIL_C2H_CFG window.
    // The window is 64 KB aligned, so the low address bits are the offset.
    // =========================================================================
    c2h_source_cfg #(.P_NUM_PORTS(4), .P_ADDR_WIDTH(16)) u_c2h_src_cfg (
        .aclk                (axi_clk),
        .aresetn             (axi_rst_n),
        .s_axil_awaddr       (c2h_cfg_axil_awaddr[15:0]),
        .s_axil_awprot       (c2h_cfg_axil_awprot),
        .s_axil_awvalid      (c2h_cfg_axil_awvalid),
        .s_axil_awready      (c2h_cfg_axil_awready),
        .s_axil_wdata        (c2h_cfg_axil_wdata),
        .s_axil_wstrb        (c2h_cfg_axil_wstrb),
        .s_axil_wvalid       (c2h_cfg_axil_wvalid),
        .s_axil_wready       (c2h_cfg_axil_wready),
        .s_axil_bresp        (c2h_cfg_axil_bresp),
        .s_axil_bvalid       (c2h_cfg_axil_bvalid),
        .s_axil_bready       (c2h_cfg_axil_bready),
        .s_axil_araddr       (c2h_cfg_axil_araddr[15:0]),
        .s_axil_arprot       (c2h_cfg_axil_arprot),
        .s_axil_arvalid      (c2h_cfg_axil_arvalid),
        .s_axil_arready      (c2h_cfg_axil_arready),
        .s_axil_rdata        (c2h_cfg_axil_rdata),
        .s_axil_rresp        (c2h_cfg_axil_rresp),
        .s_axil_rvalid       (c2h_cfg_axil_rvalid),
        .s_axil_rready       (c2h_cfg_axil_rready),
        .cfg_pkt_beats       (c2h_cfg_pkt_beats),
        .cfg_pkt_dsc         (c2h_cfg_pkt_dsc),
        .cfg_qid             (c2h_cfg_qid),
        .cfg_num_pkt         (c2h_cfg_num_pkt),
        .cfg_start           (c2h_cfg_start),
        .cfg_stop            (c2h_cfg_stop),
        .sts_pkt_start       (c2h_sts_pkt_start),
        .sts_busy            (c2h_sts_busy),
        .sts_left            (c2h_sts_left),
        .sts_burst_seq       (c2h_sts_burst_seq)
    );

    // =========================================================================
    // H2C Sink instances (one per DMA port) — accept H2C stream data
    // =========================================================================
    h2c_sink u_h2c_sink_0 (
        .clk              (axi_clk),
        .rst_n            (axi_rst_n),
        .h2c_tdata        (h2c_st_port0_tdata),
        .h2c_tkeep        (h2c_st_port0_tkeep),
        .h2c_tlast        (h2c_st_port0_tlast),
        .h2c_tvalid       (h2c_st_port0_tvalid),
        .h2c_tready       (h2c_st_port0_tready),
        .h2c_tuser_qid    (h2c_st_port0_tuser_qid),
        .h2c_tuser_port_id(h2c_st_port0_tuser_port_id[2:0]),
        .h2c_tuser_mty    (h2c_st_port0_tuser_mty),
        .h2c_tuser_err    (h2c_st_port0_tuser_err),
        .sink_enable      (1'b1),
        .beat_count       (), .pkt_count  (), .byte_count (),
        .beat_accepted    (), .pkt_done   (),
        .last_data        (), .last_keep  (),
        .last_qid         (), .last_port_id(), .last_mty  ()
    );

    h2c_sink u_h2c_sink_1 (
        .clk              (axi_clk),
        .rst_n            (axi_rst_n),
        .h2c_tdata        (h2c_st_port1_tdata),
        .h2c_tkeep        (h2c_st_port1_tkeep),
        .h2c_tlast        (h2c_st_port1_tlast),
        .h2c_tvalid       (h2c_st_port1_tvalid),
        .h2c_tready       (h2c_st_port1_tready),
        .h2c_tuser_qid    (h2c_st_port1_tuser_qid),
        .h2c_tuser_port_id(h2c_st_port1_tuser_port_id[2:0]),
        .h2c_tuser_mty    (h2c_st_port1_tuser_mty),
        .h2c_tuser_err    (h2c_st_port1_tuser_err),
        .sink_enable      (1'b1),
        .beat_count       (), .pkt_count  (), .byte_count (),
        .beat_accepted    (), .pkt_done   (),
        .last_data        (), .last_keep  (),
        .last_qid         (), .last_port_id(), .last_mty  ()
    );

    h2c_sink u_h2c_sink_2 (
        .clk              (axi_clk),
        .rst_n            (axi_rst_n),
        .h2c_tdata        (h2c_st_port2_tdata),
        .h2c_tkeep        (h2c_st_port2_tkeep),
        .h2c_tlast        (h2c_st_port2_tlast),
        .h2c_tvalid       (h2c_st_port2_tvalid),
        .h2c_tready       (h2c_st_port2_tready),
        .h2c_tuser_qid    (h2c_st_port2_tuser_qid),
        .h2c_tuser_port_id(h2c_st_port2_tuser_port_id[2:0]),
        .h2c_tuser_mty    (h2c_st_port2_tuser_mty),
        .h2c_tuser_err    (h2c_st_port2_tuser_err),
        .sink_enable      (1'b1),
        .beat_count       (), .pkt_count  (), .byte_count (),
        .beat_accepted    (), .pkt_done   (),
        .last_data        (), .last_keep  (),
        .last_qid         (), .last_port_id(), .last_mty  ()
    );

    h2c_sink u_h2c_sink_3 (
        .clk              (axi_clk),
        .rst_n            (axi_rst_n),
        .h2c_tdata        (h2c_st_port3_tdata),
        .h2c_tkeep        (h2c_st_port3_tkeep),
        .h2c_tlast        (h2c_st_port3_tlast),
        .h2c_tvalid       (h2c_st_port3_tvalid),
        .h2c_tready       (h2c_st_port3_tready),
        .h2c_tuser_qid    (h2c_st_port3_tuser_qid),
        .h2c_tuser_port_id(h2c_st_port3_tuser_port_id[2:0]),
        .h2c_tuser_mty    (h2c_st_port3_tuser_mty),
        .h2c_tuser_err    (h2c_st_port3_tuser_err),
        .sink_enable      (1'b1),
        .beat_count       (), .pkt_count  (), .byte_count (),
        .beat_accepted    (), .pkt_done   (),
        .last_data        (), .last_keep  (),
        .last_qid         (), .last_port_id(), .last_mty  ()
    );

    // =========================================================================
    // C2H Source instances (one per DMA port) — send a burst of packets to one
    // queue when the host writes START in u_c2h_src_cfg (queue, packet count
    // and packet length from the same block; reset: queue 1, 1 packet, 512 B).
    // =========================================================================
    c2h_source_ctrl #(.PORT_ID(0)) u_c2h_ctrl_0 (
        .clk              (axi_clk),
        .rst_n            (axi_rst_n),
        .c2h_tdata        (c2h_st_port0_tdata),
        .c2h_tkeep        (c2h_st_port0_tkeep),
        .c2h_tlast        (c2h_st_port0_tlast),
        .c2h_tvalid       (c2h_st_port0_tvalid),
        .c2h_tready       (c2h_st_port0_tready),
        .c2h_ctrl_qid     (c2h_st_port0_ctrl_qid),
        .c2h_mty          (c2h_st_port0_mty),
        .c2h_ctrl_port_id (c2h_st_port0_ctrl_port_id),
        .c2h_ctrl_marker  (c2h_st_port0_ctrl_marker),
        .c2h_ctrl_has_cmpt(c2h_st_port0_ctrl_has_cmpt),
        .c2h_ctrl_len     (c2h_st_port0_ctrl_len),
        .cmpt_trigger     (cmpt_trigger_0),
        .cmpt_trigger_qid (cmpt_trigger_qid_0),
        .cmpt_trigger_port_id(cmpt_trigger_port_id_0),
        .cmpt_trigger_len (cmpt_trigger_len_0),
        .cmpt_trigger_rdy (cmpt_trigger_rdy_0),
        .cfg_pkt_beats    (c2h_cfg_pkt_beats[0]),
        .cfg_pkt_dsc      (c2h_cfg_pkt_dsc[0]),
        .cfg_qid          (c2h_cfg_qid[0]),
        .cfg_num_pkt      (c2h_cfg_num_pkt[0]),
        .cfg_start        (c2h_cfg_start[0]),
        .cfg_stop         (c2h_cfg_stop[0]),
        .sts_pkt_start    (c2h_sts_pkt_start[0]),
        .sts_busy         (c2h_sts_busy[0]),
        .sts_left         (c2h_sts_left[0]),
        .sts_burst_seq    (c2h_sts_burst_seq[0])
    );

    c2h_source_ctrl #(.PORT_ID(1)) u_c2h_ctrl_1 (
        .clk              (axi_clk),
        .rst_n            (axi_rst_n),
        .c2h_tdata        (c2h_st_port1_tdata),
        .c2h_tkeep        (c2h_st_port1_tkeep),
        .c2h_tlast        (c2h_st_port1_tlast),
        .c2h_tvalid       (c2h_st_port1_tvalid),
        .c2h_tready       (c2h_st_port1_tready),
        .c2h_ctrl_qid     (c2h_st_port1_ctrl_qid),
        .c2h_mty          (c2h_st_port1_mty),
        .c2h_ctrl_port_id (c2h_st_port1_ctrl_port_id),
        .c2h_ctrl_marker  (c2h_st_port1_ctrl_marker),
        .c2h_ctrl_has_cmpt(c2h_st_port1_ctrl_has_cmpt),
        .c2h_ctrl_len     (c2h_st_port1_ctrl_len),
        .cmpt_trigger     (cmpt_trigger_1),
        .cmpt_trigger_qid (cmpt_trigger_qid_1),
        .cmpt_trigger_port_id(cmpt_trigger_port_id_1),
        .cmpt_trigger_len (cmpt_trigger_len_1),
        .cmpt_trigger_rdy (cmpt_trigger_rdy_1),
        .cfg_pkt_beats    (c2h_cfg_pkt_beats[1]),
        .cfg_pkt_dsc      (c2h_cfg_pkt_dsc[1]),
        .cfg_qid          (c2h_cfg_qid[1]),
        .cfg_num_pkt      (c2h_cfg_num_pkt[1]),
        .cfg_start        (c2h_cfg_start[1]),
        .cfg_stop         (c2h_cfg_stop[1]),
        .sts_pkt_start    (c2h_sts_pkt_start[1]),
        .sts_busy         (c2h_sts_busy[1]),
        .sts_left         (c2h_sts_left[1]),
        .sts_burst_seq    (c2h_sts_burst_seq[1])
    );

    c2h_source_ctrl #(.PORT_ID(2)) u_c2h_ctrl_2 (
        .clk              (axi_clk),
        .rst_n            (axi_rst_n),
        .c2h_tdata        (c2h_st_port2_tdata),
        .c2h_tkeep        (c2h_st_port2_tkeep),
        .c2h_tlast        (c2h_st_port2_tlast),
        .c2h_tvalid       (c2h_st_port2_tvalid),
        .c2h_tready       (c2h_st_port2_tready),
        .c2h_ctrl_qid     (c2h_st_port2_ctrl_qid),
        .c2h_mty          (c2h_st_port2_mty),
        .c2h_ctrl_port_id (c2h_st_port2_ctrl_port_id),
        .c2h_ctrl_marker  (c2h_st_port2_ctrl_marker),
        .c2h_ctrl_has_cmpt(c2h_st_port2_ctrl_has_cmpt),
        .c2h_ctrl_len     (c2h_st_port2_ctrl_len),
        .cmpt_trigger     (cmpt_trigger_2),
        .cmpt_trigger_qid (cmpt_trigger_qid_2),
        .cmpt_trigger_port_id(cmpt_trigger_port_id_2),
        .cmpt_trigger_len (cmpt_trigger_len_2),
        .cmpt_trigger_rdy (cmpt_trigger_rdy_2),
        .cfg_pkt_beats    (c2h_cfg_pkt_beats[2]),
        .cfg_pkt_dsc      (c2h_cfg_pkt_dsc[2]),
        .cfg_qid          (c2h_cfg_qid[2]),
        .cfg_num_pkt      (c2h_cfg_num_pkt[2]),
        .cfg_start        (c2h_cfg_start[2]),
        .cfg_stop         (c2h_cfg_stop[2]),
        .sts_pkt_start    (c2h_sts_pkt_start[2]),
        .sts_busy         (c2h_sts_busy[2]),
        .sts_left         (c2h_sts_left[2]),
        .sts_burst_seq    (c2h_sts_burst_seq[2])
    );

    c2h_source_ctrl #(.PORT_ID(3)) u_c2h_ctrl_3 (
        .clk              (axi_clk),
        .rst_n            (axi_rst_n),
        .c2h_tdata        (c2h_st_port3_tdata),
        .c2h_tkeep        (c2h_st_port3_tkeep),
        .c2h_tlast        (c2h_st_port3_tlast),
        .c2h_tvalid       (c2h_st_port3_tvalid),
        .c2h_tready       (c2h_st_port3_tready),
        .c2h_ctrl_qid     (c2h_st_port3_ctrl_qid),
        .c2h_mty          (c2h_st_port3_mty),
        .c2h_ctrl_port_id (c2h_st_port3_ctrl_port_id),
        .c2h_ctrl_marker  (c2h_st_port3_ctrl_marker),
        .c2h_ctrl_has_cmpt(c2h_st_port3_ctrl_has_cmpt),
        .c2h_ctrl_len     (c2h_st_port3_ctrl_len),
        .cmpt_trigger     (cmpt_trigger_3),
        .cmpt_trigger_qid (cmpt_trigger_qid_3),
        .cmpt_trigger_port_id(cmpt_trigger_port_id_3),
        .cmpt_trigger_len (cmpt_trigger_len_3),
        .cmpt_trigger_rdy (cmpt_trigger_rdy_3),
        .cfg_pkt_beats    (c2h_cfg_pkt_beats[3]),
        .cfg_pkt_dsc      (c2h_cfg_pkt_dsc[3]),
        .cfg_qid          (c2h_cfg_qid[3]),
        .cfg_num_pkt      (c2h_cfg_num_pkt[3]),
        .cfg_start        (c2h_cfg_start[3]),
        .cfg_stop         (c2h_cfg_stop[3]),
        .sts_pkt_start    (c2h_sts_pkt_start[3]),
        .sts_busy         (c2h_sts_busy[3]),
        .sts_left         (c2h_sts_left[3]),
        .sts_burst_seq    (c2h_sts_burst_seq[3])
    );

    // =========================================================================
    // C2H Completion Generators — one per port, triggered by c2h_source_ctrl
    // =========================================================================
    c2h_cmpt_gen u_c2h_cmpt_gen_0 (
        .clk                              (axi_clk),
        .rst_n                            (axi_rst_n),
        .c2h_cmpt_tdata                   (c2h_cmpt_port0_tdata),
        .c2h_cmpt_size                    (c2h_cmpt_port0_size),
        .c2h_cmpt_dpar                    (c2h_cmpt_port0_dpar),
        .c2h_cmpt_ctrl_qid                (c2h_cmpt_port0_ctrl_qid),
        .c2h_cmpt_ctrl_port_id            (c2h_cmpt_port0_ctrl_port_id),
        .c2h_cmpt_ctrl_cmpt_type          (c2h_cmpt_port0_ctrl_cmpt_type),
        .c2h_cmpt_ctrl_wait_pld_pkt_id    (c2h_cmpt_port0_ctrl_wait_pld_pkt_id),
        .c2h_cmpt_ctrl_user_trig          (c2h_cmpt_port0_ctrl_user_trig),
        .c2h_cmpt_ctrl_col_idx            (c2h_cmpt_port0_ctrl_col_idx),
        .c2h_cmpt_ctrl_no_wrb_marker      (c2h_cmpt_port0_ctrl_no_wrb_marker),
        .c2h_cmpt_tvalid                  (c2h_cmpt_port0_tvalid),
        .c2h_cmpt_tready                  (c2h_cmpt_port0_tready),
        .cmpt_trigger                     (cmpt_trigger_0),
        .cmpt_trigger_qid                 (cmpt_trigger_qid_0),
        .cmpt_trigger_port_id             (cmpt_trigger_port_id_0),
        .cmpt_trigger_len                 (cmpt_trigger_len_0),
        .cmpt_trigger_rdy                 (cmpt_trigger_rdy_0)
    );

    c2h_cmpt_gen u_c2h_cmpt_gen_1 (
        .clk                              (axi_clk),
        .rst_n                            (axi_rst_n),
        .c2h_cmpt_tdata                   (c2h_cmpt_port1_tdata),
        .c2h_cmpt_size                    (c2h_cmpt_port1_size),
        .c2h_cmpt_dpar                    (c2h_cmpt_port1_dpar),
        .c2h_cmpt_ctrl_qid                (c2h_cmpt_port1_ctrl_qid),
        .c2h_cmpt_ctrl_port_id            (c2h_cmpt_port1_ctrl_port_id),
        .c2h_cmpt_ctrl_cmpt_type          (c2h_cmpt_port1_ctrl_cmpt_type),
        .c2h_cmpt_ctrl_wait_pld_pkt_id    (c2h_cmpt_port1_ctrl_wait_pld_pkt_id),
        .c2h_cmpt_ctrl_user_trig          (c2h_cmpt_port1_ctrl_user_trig),
        .c2h_cmpt_ctrl_col_idx            (c2h_cmpt_port1_ctrl_col_idx),
        .c2h_cmpt_ctrl_no_wrb_marker      (c2h_cmpt_port1_ctrl_no_wrb_marker),
        .c2h_cmpt_tvalid                  (c2h_cmpt_port1_tvalid),
        .c2h_cmpt_tready                  (c2h_cmpt_port1_tready),
        .cmpt_trigger                     (cmpt_trigger_1),
        .cmpt_trigger_qid                 (cmpt_trigger_qid_1),
        .cmpt_trigger_port_id             (cmpt_trigger_port_id_1),
        .cmpt_trigger_len                 (cmpt_trigger_len_1),
        .cmpt_trigger_rdy                 (cmpt_trigger_rdy_1)
    );

    c2h_cmpt_gen u_c2h_cmpt_gen_2 (
        .clk                              (axi_clk),
        .rst_n                            (axi_rst_n),
        .c2h_cmpt_tdata                   (c2h_cmpt_port2_tdata),
        .c2h_cmpt_size                    (c2h_cmpt_port2_size),
        .c2h_cmpt_dpar                    (c2h_cmpt_port2_dpar),
        .c2h_cmpt_ctrl_qid                (c2h_cmpt_port2_ctrl_qid),
        .c2h_cmpt_ctrl_port_id            (c2h_cmpt_port2_ctrl_port_id),
        .c2h_cmpt_ctrl_cmpt_type          (c2h_cmpt_port2_ctrl_cmpt_type),
        .c2h_cmpt_ctrl_wait_pld_pkt_id    (c2h_cmpt_port2_ctrl_wait_pld_pkt_id),
        .c2h_cmpt_ctrl_user_trig          (c2h_cmpt_port2_ctrl_user_trig),
        .c2h_cmpt_ctrl_col_idx            (c2h_cmpt_port2_ctrl_col_idx),
        .c2h_cmpt_ctrl_no_wrb_marker      (c2h_cmpt_port2_ctrl_no_wrb_marker),
        .c2h_cmpt_tvalid                  (c2h_cmpt_port2_tvalid),
        .c2h_cmpt_tready                  (c2h_cmpt_port2_tready),
        .cmpt_trigger                     (cmpt_trigger_2),
        .cmpt_trigger_qid                 (cmpt_trigger_qid_2),
        .cmpt_trigger_port_id             (cmpt_trigger_port_id_2),
        .cmpt_trigger_len                 (cmpt_trigger_len_2),
        .cmpt_trigger_rdy                 (cmpt_trigger_rdy_2)
    );

    c2h_cmpt_gen u_c2h_cmpt_gen_3 (
        .clk                              (axi_clk),
        .rst_n                            (axi_rst_n),
        .c2h_cmpt_tdata                   (c2h_cmpt_port3_tdata),
        .c2h_cmpt_size                    (c2h_cmpt_port3_size),
        .c2h_cmpt_dpar                    (c2h_cmpt_port3_dpar),
        .c2h_cmpt_ctrl_qid                (c2h_cmpt_port3_ctrl_qid),
        .c2h_cmpt_ctrl_port_id            (c2h_cmpt_port3_ctrl_port_id),
        .c2h_cmpt_ctrl_cmpt_type          (c2h_cmpt_port3_ctrl_cmpt_type),
        .c2h_cmpt_ctrl_wait_pld_pkt_id    (c2h_cmpt_port3_ctrl_wait_pld_pkt_id),
        .c2h_cmpt_ctrl_user_trig          (c2h_cmpt_port3_ctrl_user_trig),
        .c2h_cmpt_ctrl_col_idx            (c2h_cmpt_port3_ctrl_col_idx),
        .c2h_cmpt_ctrl_no_wrb_marker      (c2h_cmpt_port3_ctrl_no_wrb_marker),
        .c2h_cmpt_tvalid                  (c2h_cmpt_port3_tvalid),
        .c2h_cmpt_tready                  (c2h_cmpt_port3_tready),
        .cmpt_trigger                     (cmpt_trigger_3),
        .cmpt_trigger_qid                 (cmpt_trigger_qid_3),
        .cmpt_trigger_port_id             (cmpt_trigger_port_id_3),
        .cmpt_trigger_len                 (cmpt_trigger_len_3),
        .cmpt_trigger_rdy                 (cmpt_trigger_rdy_3)
    );

endmodule
