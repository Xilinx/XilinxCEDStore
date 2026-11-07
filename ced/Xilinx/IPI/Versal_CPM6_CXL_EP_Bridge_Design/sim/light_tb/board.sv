// ===========================================================================
// board.sv - Path 2: Avery-VIP-free simulation harness for the CXL Bridge
// design's EP side.
//
// Reusing bind_ps_vip/ps_vip_api_if pulls in UVM, which ships with VCS. Not
// needed: Avery VIP ($AVERY_PCIE/$AVERY_SIM), the uvma_agents packages and
// the Makefile flow of sim/standalone/.
//
// SCOPE: instantiates only the EP (design_1_wrapper), drives the CPM6 resets,
// waits for the PS-VIP reset/clock sequence and the CPM6 CDO load, then
// exercises ctrl_reg_ep's AXI-Lite CSR map (SCRATCH loopback, EP_CTRL_STS
// read) - see csr_sanity_test.vh. No CXL.mem traffic, no link training.
// ===========================================================================

`timescale 1ps/1ps
`define SIMULATION
`define XIL_TIMING

// Order matters: the package must be compiled before anything imports it.
`include "../tb/ps_vip_api_pkg.svh"   // package ps_vip_api_pkg (defines R5_API, PS_CPM_CFG, etc.)
`include "../tb/bind.ps_vip.sv"       // interface ps_vip_api_if + module bind_ps_vip (self-contained: imports uvm_pkg/ps_vip_api_pkg in its own headers)
`include "../tb/bind.cdo_load.sv"     // module bind_cdo_load (uvm_event cdo_load_done)

// Same binds as ../tb/cpm6_vivado_binds.sv; its other binds need uvma_agents
// interfaces, which are not compiled here.
`ifndef QEMU_PS
bind versal_cips_ps_vip_0 bind_ps_vip bind_ps_vip();
`endif
bind SIP_CPM6 bind_cdo_load#(SIM_CPM_CDO_FILE_NAME) bind_cdo_load();

// CPM6 resets, driven like ../tb/bind.lpd_por_n.sv and ../tb/bind.perstn.sv
// do from their UVM reset agents.
module bind_cpm6_resets;
  reg por_n = 1'b0, perst_n = 1'b0;

  assign inst.lpd_cpm6_por_n = por_n;
  initial begin
    force inst.perst0n = perst_n;
    force inst.perst1n = perst_n;
    #100ns;
    por_n = 1'b1;
    #1us;
    perst_n = 1'b1;
  end
endmodule
bind CPM6 bind_cpm6_resets bind_cpm6_resets();

module board;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import ps_vip_api_pkg::*;

  // CTRL1 (default) build - matches ../verif/dut_inst.sv's default branch.
  // Build the CTRL0 variant by swapping the port names below to match
  // ctrl0_cpi/design_1_bd.tcl.
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
    // cxl1_pm_0, C{0,1,4,5}_CH0_LPDDR5_0, sys_clk{0,4}_0 unconnected.
  );

  // The DDR PHY models check that their sys_clk_i toggles; drive it as
  // ../verif/dut_inst.sv does (320 MHz).
  logic ddr_sys_clk = 1'b0;
  always #1564 ddr_sys_clk = ~ddr_sys_clk;
  initial begin
    force EP.design_1_i.axi_noc2_c0.inst.MC0_ddrc.inst.noc_ddr5_phy.inst.sys_clk_i = ddr_sys_clk;
    force EP.design_1_i.axi_noc2_c1.inst.MC0_ddrc.inst.noc_ddr5_phy.inst.sys_clk_i = ddr_sys_clk;
    force EP.design_1_i.axi_noc2_c4.inst.MC0_ddrc.inst.noc_ddr5_phy.inst.sys_clk_i = ddr_sys_clk;
    force EP.design_1_i.axi_noc2_c5.inst.MC0_ddrc.inst.noc_ddr5_phy.inst.sys_clk_i = ddr_sys_clk;
  end

  // bind_ps_vip publishes ps_vip_api at time 0 and then runs its own PL reset
  // and clock sequence. The CPM6 CDO loader shares the PS-VIP master, so CSR
  // access has to wait until the CDO load is done.
  virtual ps_vip_api_if ps_vip_api;
  uvm_event             cdo_load_done;

  initial begin
    fork
      begin
        while (!uvm_config_db#(virtual ps_vip_api_if)::get(null, "", "ps_vip_api", ps_vip_api))
          #100ns;
      end
      begin
        #10us;
        `uvm_fatal("BOARD", "Timed out waiting for 'ps_vip_api' in config_db - bind_ps_vip did not run, or module name 'versal_cips_ps_vip_0' did not resolve")
      end
    join_any
    disable fork;
    `uvm_info("BOARD", "ps_vip_api acquired from config_db", UVM_NONE)

    fork
      begin
        while (!uvm_config_db#(uvm_event)::get(null, "", "cdo_load_done", cdo_load_done))
          #100ns;
        cdo_load_done.wait_trigger;
      end
      begin
        #200us;
        `uvm_fatal("BOARD", "Timed out waiting for the CPM6 CDO load")
      end
    join_any
    disable fork;
    `uvm_info("BOARD", "CPM6 CDO load done", UVM_NONE)

    `uvm_info("BOARD", "Running CSR sanity check", UVM_NONE)
    // csr_sanity_test.vh declares locals, so it gets its own block scope.
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
