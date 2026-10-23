// DUT Instantiation for Controller 1 (CTRL1_GT_0 is X2 -- 2 lanes, matching
// ctrl1/design_1_bd.tcl's fixed CPM6_CTRL1_LINK_WIDTH=X2 configuration; see
// init.tcl/run.tcl's CTRL_LINK_WIDTH notes).
//
// Connects to this CED's own tb_top.sv (ported from Versal_CPM6_BMD_Design),
// which declares scalar-suffixed vip2dut_1_p/n, dut2vip_1_p/n, refclk_1_p/n
// signals (see tb_top.sv lines ~81-84, ~307-341).
//
// Instantiates ctrl1_qdma_ep_sim_wrapper (Vivado-auto-generated at
// launch_simulation time under qdma_ced_test.srcs/sources_1/common/hdl/),
// NOT ctrl1_qdma_ep directly. Without the sim_wrapper's xlnoc instance and
// its hierarchical npp_in/npp_out cross-wiring into axi_noc2_0, the NoC
// Packet Protocol ports are left floating and the axi_noc2_0 NMU's own
// protection checker fires a hard Fatal at time ~19ns ("noc_valid on npp_in
// interface should not be unconnected / unknown"), confirmed by simulation.
// The sim_wrapper has the IDENTICAL external port list as ctrl1_qdma_ep
// (same 6 ports) since it only adds internal NoC wiring, so instantiating
// it in place of the bare BD wrapper is a drop-in swap -- no port changes.
//
// All C2H/H2C/tm_dsc_sts PL user logic lives inside the BD itself -- only
// the GT quad and its reference clock cross the BD boundary, confirmed
// against the real generated design_1_wrapper.v (only 6 top-level ports).

generate
  if (tb_top.LINK1_WIDTH != 0) begin : ctrl_inst
    ctrl1_qdma_ep_sim_wrapper dut_inst (
        .CTRL1_GT_0_grx_n        ( vip2dut_1_n[1:0] ),
        .CTRL1_GT_0_grx_p        ( vip2dut_1_p[1:0] ),
        .CTRL1_GT_0_gtx_n        ( dut2vip_1_n[1:0] ),
        .CTRL1_GT_0_gtx_p        ( dut2vip_1_p[1:0] ),

        .ctrl1_gt_refclk_0_clk_n ( refclk_1_n ),
        .ctrl1_gt_refclk_0_clk_p ( refclk_1_p )
    );
  end
endgenerate
