// ===========================================================================
// board.sv - Path 2: standalone, Avery-VIP-free simulation harness for the
// CXL Bridge design's EP side.
//
// Modeled directly on the sibling CED design
// Versal_CPM_PCIE_BMD_EP_Simulation_Design/cpm5_bmd/sim_files/board.v
// (renamed to .sv here since this file needs SystemVerilog-only constructs -
// see build_project_light.tcl's comment on file-type auto-detection)
// and tests.vh (both read in full): same sys_clk_gen_ds instantiation
// pattern, same `` `define SIMULATION``/`` `define XIL_TIMING`` (Xilinx
// UNISIM simulation-only-path guards), same $test$plusargs("dump_all")
// waveform-dump block.
//
// DEPENDENCY NOTE: this harness is NOT fully dependency-free. Reusing
// bind_ps_vip/ps_vip_api_if (see below) pulls in `uvm_pkg`/`uvm_macros.svh`
// - UVM itself, which ships bundled with VCS/Questa and is a far lower bar
// than Avery's separately-licensed PCIe/CXL VIP. What this harness avoids:
// Avery VIP ($AVERY_PCIE/$AVERY_SIM), the uvma_agents packages, and the
// external Makefile machinery Path 1 (sim/standalone/) still needs all
// three for. $CPM6_SECUREIP remains required either way - that is the
// DUT's own netlist dependency, unavoidable in any path.
//
// SCOPE (deliberately limited): this harness does NOT attempt CXL.mem traffic generation or
// link training - it instantiates ONLY the EP (design_1_wrapper), sequences
// PS-VIP reset/clock via the confirmed bind_ps_vip mechanism, and exercises
// ctrl_reg_ep's AXI-Lite CSR map (SCRATCH loopback, EP_CTRL_STS read) - see
// csr_sanity_test.vh.
//
// UNRESOLVED (flagged, not silently assumed away - confirm once elaborated
// in a real Vivado/VCS session, none available in this pass):
//   1. The `bind versal_cips_ps_vip_0 ...` target below is a MODULE NAME
//      (SystemVerilog `bind <module_name>` matches every instance of that
//      module anywhere in the design, so it is depth/hierarchy-agnostic by
//      construction). What's NOT confirmed: whether Vivado's `ps_wizard_0`
//      IP actually generates a simulation companion module with this exact
//      name for its internal CIPS-class block. If the fatal below fires,
//      search the elaborated design for any module matching `*_ps_vip*`
//      and adjust the bind target/module reference accordingly.
//   2. csr_sanity_test.vh's routing choice (see that file's own header).
// ===========================================================================

`timescale 1ps/1ps
`define SIMULATION
`define XIL_TIMING

// Order matters: the package must be compiled before anything imports it.
`include "../tb/ps_vip_api_pkg.svh"   // package ps_vip_api_pkg (defines R5_API, PS_CPM_CFG, etc.)
`include "../tb/bind.ps_vip.sv"       // interface ps_vip_api_if + module bind_ps_vip (self-contained: imports uvm_pkg/ps_vip_api_pkg in its own headers)

// Activates the module `` `include``-d above. NOT present in bind.ps_vip.sv
// itself - this exact line is copied from ../tb/cpm6_vivado_binds.sv line 3
// (that aggregator is not `` `include``-d here in full since its other 11
// binds reference uvma_agents interface types not compiled in this
// dependency-free path).
`ifndef QEMU_PS
bind versal_cips_ps_vip_0 bind_ps_vip bind_ps_vip();
`endif

module board;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import ps_vip_api_pkg::*;

  // CTRL1 (default) build - matches ../verif/dut_inst.sv's default branch.
  // Build the CTRL0 variant by swapping the port names below to match
  // ctrl0/design_1_bd.tcl (unconfirmed - same open item as
  // ../verif/dut_inst.sv item 1).
  wire gt_refclk_p, gt_refclk_n;

  sys_clk_gen_ds #(.halfcycle(5000), .offset(0)) CLK_GEN_CTRL1 (
    .sys_clk_p (gt_refclk_p),
    .sys_clk_n (gt_refclk_n)
  );

  // GT lanes tied to a static level - no link partner in this harness (see
  // SCOPE above); this exercises PS-VIP + CSR access only, not link
  // training/CXL.mem. LTSSM will simply never train, which is expected.
  wire [7:0] ep_grx_n = 8'h00, ep_grx_p = 8'h00;
  wire [7:0] ep_gtx_n, ep_gtx_p;

  design_1_wrapper EP (
    .CTRL1_GT_0_grx_n        ( ep_grx_n ),
    .CTRL1_GT_0_grx_p        ( ep_grx_p ),
    .CTRL1_GT_0_gtx_n        ( ep_gtx_n ),
    .CTRL1_GT_0_gtx_p        ( ep_gtx_p ),
    .ctrl1_gt_refclk_0_clk_n ( gt_refclk_n ),
    .ctrl1_gt_refclk_0_clk_p ( gt_refclk_p )
    // cxl1_pm_0, C{0,1,4,5}_CH0_LPDDR5_0, sys_clk{0,4}_0 unconnected -
    // same open items as ../verif/dut_inst.sv.
  );

  // ------------------------------------------------------------------
  // bind_ps_vip (pulled in above) runs its OWN full reset/clock sequence
  // in its own `initial` blocks the instant it binds: one block publishes
  // `ps_vip_api` into config_db immediately (time 0, no delay); two other
  // blocks separately drive pl_gen_reset(0)->#1us->pl_gen_reset(1) and
  // set_debug_level_info/por_reset(0)->#1us->por_reset(1)/clock-gen calls
  // (see ../tb/bind.ps_vip.sv lines ~140-174). So the vif is available
  // almost immediately, but the PS side isn't actually usable until those
  // ~1us reset sequences complete. We therefore (a) poll for the vif with
  // a timeout, then (b) wait an additional settling margin before issuing
  // any CSR transaction - this two-step ordering is the fix for an
  // earlier draft that read/wrote CSRs before deassertion completed.
  // ------------------------------------------------------------------
  virtual ps_vip_api_if ps_vip_api;

  initial begin
    fork
      begin
        while (!uvm_config_db#(virtual ps_vip_api_if)::get(null, "", "ps_vip_api", ps_vip_api))
          #100ns;
      end
      begin
        #10us;
        `uvm_fatal("BOARD", "Timed out waiting for 'ps_vip_api' in config_db - bind_ps_vip did not run, or module name 'versal_cips_ps_vip_0' did not resolve for this design's ps_wizard-based hierarchy (see UNRESOLVED item 1 above)")
      end
    join_any
    disable fork;
    `uvm_info("BOARD", "ps_vip_api acquired from config_db", UVM_NONE)

    // Settling margin past bind_ps_vip's own ~1-2us internal reset/clock
    // sequence (2 x #1us delays plus clock-gen calls) before touching CSRs.
    #3us;

    `uvm_info("BOARD", "Running CSR sanity check", UVM_NONE)
    // SystemVerilog requires all block-item declarations to precede
    // statements within the same seq_block. csr_sanity_test.vh declares
    // local variables at its own top, so it's wrapped in its own nested
    // begin/end to give its declarations a fresh block scope, since this
    // outer `initial begin` already has statements above it.
    begin
      `include "csr_sanity_test.vh"
    end

    `uvm_info("BOARD", "CSR sanity check complete", UVM_NONE)
    $finish;
  end

  initial begin
    if ($test$plusargs("dump_all")) begin
`ifdef VCS
      $vcdplusfile("board.vpd"); $vcdpluson; $vcdplusflush;
`else
      $dumpfile("board.vcd"); $dumpvars(0, board);
`endif
    end
  end

endmodule
