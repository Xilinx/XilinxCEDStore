// ===========================================================================
// dut_inst.sv - Versal CPM6 CXL EP Bridge Design
//
// `include`-d by sim/tb/tb_top.sv (see sim/tb/tb_top.sv line ~344):
//   `include "cpm6_vivado_binds.sv"
//   `include "dut_inst.sv"
//
// PURPOSE
//   Instantiate this design's top-level Vivado-generated wrapper as
//   `dut_inst`, wiring only the physical GT lanes + refclk to tb_top's
//   generic vip2dut_N_p/n / dut2vip_N_p/n / refclk_N_p/n arrays.
//
// CTRL0 vs CTRL1 SELECTION
//   This design is CTRL0-or-CTRL1-selectable at CED-generation time
//   (init.tcl CTRL_CONFIG option -> run.tcl ctrl_dir_map -> ctrl0_cpi/
//   design_1_bd.tcl or ctrl1_cpi/design_1_bd.tcl). The two BD flavors expose
//   DIFFERENT top-level port name sets (CTRL0_GT_0/ctrl0_gt_refclk_0/
//   cxl0_pm_0 vs CTRL1_GT_0/ctrl1_gt_refclk_0/cxl1_pm_0), so a single
//   instantiation cannot serve both without a `define guard. Default here
//   is CTRL1 (matches init.tcl's default value_list entry "Controller_1"
//   and the `ctrl1_cpi/` BD, i.e. the same one this file's port names were
//   read from). Build with +define+CXL_BRDG_CTRL0 to switch to the CTRL0
//   variant.
//
//   CTRL1_GT_0            xilinx.com:interface:gt_rtl:1.0        (Master, x4 or x8)
//   ctrl1_gt_refclk_0     xilinx.com:interface:diff_clock_rtl:1.0 (Subordinate)
//   cxl1_pm_0             xilinx.com:display_cpm6:cxl_pm_rtl:1.0  (Subordinate)
//   C0_CH0_LPDDR5_0       xilinx.com:interface:lpddr5_rtl:1.0     (Master)
//   C1_CH0_LPDDR5_0       xilinx.com:interface:lpddr5_rtl:1.0     (Master)
//   C4_CH0_LPDDR5_0       xilinx.com:interface:lpddr5_rtl:1.0     (Master)
//   C5_CH0_LPDDR5_0       xilinx.com:interface:lpddr5_rtl:1.0     (Master)
//   sys_clk0_0, sys_clk4_0 xilinx.com:interface:diff_clock_rtl:1.0 (Subordinate, 320MHz)
// ===========================================================================

`ifdef CXL_BRDG_CTRL0

  design_1_wrapper dut_inst (
    .CTRL0_GT_0_grx_n        ( vip2dut_0_n ),
    .CTRL0_GT_0_grx_p        ( vip2dut_0_p ),
    .CTRL0_GT_0_gtx_n        ( dut2vip_0_n ),
    .CTRL0_GT_0_gtx_p        ( dut2vip_0_p ),

    .ctrl0_gt_refclk_0_clk_n ( refclk_0_n ),
    .ctrl0_gt_refclk_0_clk_p ( refclk_0_p )

    // cxl0_pm_0            - left unconnected
    // C{0,1,4,5}_CH0_LPDDR5_0, sys_clk{0,4}_0 - left unconnected
  );

`else // default: CTRL1 (matches ctrl1_cpi/ BD, init.tcl default "Controller_1")

  design_1_wrapper dut_inst (
    .CTRL1_GT_0_grx_n        ( vip2dut_1_n ),
    .CTRL1_GT_0_grx_p        ( vip2dut_1_p ),
    .CTRL1_GT_0_gtx_n        ( dut2vip_1_n ),
    .CTRL1_GT_0_gtx_p        ( dut2vip_1_p ),

    .ctrl1_gt_refclk_0_clk_n ( refclk_1_n ),
    .ctrl1_gt_refclk_0_clk_p ( refclk_1_p )

    // cxl1_pm_0            - left unconnected
    // C{0,1,4,5}_CH0_LPDDR5_0, sys_clk{0,4}_0 - left unconnected
  );

`endif

// ---------------------------------------------------------------------
// sys_clk0_0/sys_clk4_0 XMR force: axi_noc2_cN's own sys_clk0 pin is
// correctly driven at the BD level, but a runtime self-check deep inside
// the auto-generated MC0_ddrc/noc_ddr5_phy sub-hierarchy requires its
// internal sys_clk_i net to be toggling - not brought out to a normal
// port by the auto-generated sim wrapper, so it's forced directly here
// from a free-running testbench clock generator.
//
// Half-period 1563.5ps matches this design's own declared DDR reference
// clock: ctrl1_cpi/design_1_bd.tcl sys_clk0_0/sys_clk4_0 ports (CONFIG.
// FREQ_HZ 320000000) and axi_noc2_cN's own CONFIG.DDRMC5_CONFIG(
// DDRMC5_INPUTCLK0_PERIOD) {3127} (ps) - 3127/2 = 1563.5.
//
// One shared generator drives all 4 channels since this force stands in
// for "the reference clock is toggling," not a phase-accurate board-clock
// model - the PHY only needs its own sys_clk_i to toggle.
// ---------------------------------------------------------------------
logic cxl_brdg_ddr_sys_clk_int = 1'b0;
always #1563.5ps cxl_brdg_ddr_sys_clk_int = ~cxl_brdg_ddr_sys_clk_int;

initial begin
  force tb_top.dut_inst.design_1_i.axi_noc2_c0.inst.MC0_ddrc.inst.noc_ddr5_phy.inst.sys_clk_i = cxl_brdg_ddr_sys_clk_int;
  force tb_top.dut_inst.design_1_i.axi_noc2_c1.inst.MC0_ddrc.inst.noc_ddr5_phy.inst.sys_clk_i = cxl_brdg_ddr_sys_clk_int;
  force tb_top.dut_inst.design_1_i.axi_noc2_c4.inst.MC0_ddrc.inst.noc_ddr5_phy.inst.sys_clk_i = cxl_brdg_ddr_sys_clk_int;
  force tb_top.dut_inst.design_1_i.axi_noc2_c5.inst.MC0_ddrc.inst.noc_ddr5_phy.inst.sys_clk_i = cxl_brdg_ddr_sys_clk_int;
end

`ifndef CXL_BRDG_CTRL0
// AXI_PROBE (AW/W/B/AR/R handshake tracing on PA_1_M_AXI_* into
// axi_noc2_c1's S00_AXI subordinate port) intentionally left disabled -
// each of the 5 handshakes fires on essentially every beat of real
// traffic, which floods the sim log. Uncomment only the specific
// handshake(s) needed for a given debug session; example (AW handshake):
//
// always @(posedge tb_top.dut_inst.design_1_i.PA_1_M_AXI_AWVALID) begin
//   if (tb_top.dut_inst.design_1_i.PA_1_M_AXI_AWVALID && tb_top.dut_inst.design_1_i.PA_1_M_AXI_AWREADY)
//     $display("[AXI_PROBE] @ %0t: axi_noc2_c1 S00_AXI AW handshake (write address accepted)", $time);
// end
`endif

`ifndef CXL_BRDG_CTRL0
logic ps_wizard_0_cxl1_status_dev_mem_en_last = 1'b0;
always @(tb_top.dut_inst.design_1_i.ps_wizard_0_cxl1_status_dev_mem_en) begin
  if (tb_top.dut_inst.design_1_i.ps_wizard_0_cxl1_status_dev_mem_en !== ps_wizard_0_cxl1_status_dev_mem_en_last) begin
    $display("[STATUS_PROBE] @ %0t: ps_wizard_0_cxl1_status_dev_mem_en changed %0b -> %0b",
             $time, ps_wizard_0_cxl1_status_dev_mem_en_last,
             tb_top.dut_inst.design_1_i.ps_wizard_0_cxl1_status_dev_mem_en);
    ps_wizard_0_cxl1_status_dev_mem_en_last = tb_top.dut_inst.design_1_i.ps_wizard_0_cxl1_status_dev_mem_en;
  end
end
`endif

// CREDIT/CHANNEL-CONNECT PROBES: traces PA_1's credit-grant back to CPM6
// (cpi_a2f_req_rxcrd_valid, required nonzero before cpi_a2f_req_is_valid
// can assert) and the is_chl_connected = (txcon_req & rxcon_ack) handshake
// that gates it - if CPM6 never asserts txcon_req toward PA_1, the whole
// chain never has a chance to fire. Read-only (no force) - safe to
// add/remove freely. CTRL1-only.
//
// Left disabled by default (each of these 4 signals can toggle often
// enough to flood the sim log); uncomment only the specific signal(s)
// needed for a given debug session. Example (txcon_req):
//
// logic cpi_a2f_txcon_req_last = 1'b0;
// always @(tb_top.dut_inst.design_1_i.PA_1.cpi_a2f_global_init_txcon_req) begin
//   if (tb_top.dut_inst.design_1_i.PA_1.cpi_a2f_global_init_txcon_req !== cpi_a2f_txcon_req_last) begin
//     $display("[CREDIT_PROBE] @ %0t: cpi_a2f txcon_req (CPM6 -> PA_1 channel-connect request) changed %0b -> %0b",
//              $time, cpi_a2f_txcon_req_last, tb_top.dut_inst.design_1_i.PA_1.cpi_a2f_global_init_txcon_req);
//     cpi_a2f_txcon_req_last = tb_top.dut_inst.design_1_i.PA_1.cpi_a2f_global_init_txcon_req;
//   end
// end

// ---------------------------------------------------------------------
// WAVE DUMP (optional, off by default). Full-depth VCD capture of the
// entire design_1_i hierarchy - all PAs, ps_wizard_0, the DDR
// controllers, ctrl_reg_ep, axi_memory_init, smartconnect, etc. Full-
// hierarchy dumps for this design run into the hundreds of MB to
// multiple GB, so this is opt-in via a runtime plusarg rather than
// generated on every run:
//   make simulate ... PLUSARGS=+dump_vcd
// When enabled, dump start is delayed to 70000ns via $dumpoff/$dumpon
// to keep the file size bounded.
// ---------------------------------------------------------------------
initial begin
  if ($test$plusargs("dump_vcd")) begin
    $dumpfile("cxl_ep_brdg_sanity.vcd");
    $dumpvars(0, tb_top.dut_inst.design_1_i);
    $dumpoff;
    #70000ns;
    $dumpon;
  end
end
