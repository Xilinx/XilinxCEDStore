// ===========================================================================
// setup_env_cfg.sv - Versal CPM6 CXL EP Bridge Design
//
// Project-specific override of the empty sim/tb/env/setup_env_cfg.sv
// placeholder ("env_cfg = null;"), `include`-d from test_base.sv::build_phase
// (see sim/tb/test/test_base.sv line ~45: `include "setup_env_cfg.sv"`).
// Picked up via the same verif/-before-tb/ +incdir precedence as
// pkg.proj_test_pkg.sv.
//
// This design's 4 CPI protocol agents/HDM ranges are DRIVEN BY the CPM6
// core's own CXL logic (CPI is an internal fabric protocol between
// ps_wizard_0 and the PA_0..PA_3 cxl_mem_wrapper hierarchies - there is no
// PL-side CPI bridge in this EP design for the testbench to drive), so those
// agents are left PASSIVE (monitor-only).
// ===========================================================================

// Whichever controller CTRL_CONFIG designates as the CXL EP under test
// (Controller 0 for CTRL=0 builds, Controller 1 for the default CTRL=1
// build) gets its CXL agent array slot configured here - array index is
// the controller number.
// PL-side ISR/AXI agents are not used by this design (no PL_STRM/HDMA path);
// leave those UNUSED_AGNT (env default) unless a future test needs them.

// cxl_nfi_agnt_tx[N] must be ACTIVE_AGNT (mode-independent): its driver is
// the only thing that ever sets nfi_tx_N.agent_driven, which bind.cxl.sv's
// `wait (nfi_tx_N.agent_driven)` gates before forcing inst.cxlN_pl_ready (a
// required early-defined sideband input to the CPM6 uni-sim model - see
// bind.cxl.sv). Left PASSIVE, that force never executes and CXL.mem writes
// never complete. (cxl_nfi_agent is this vendored library's generic agent
// name - unrelated to this design's transport choice.)
`ifdef CXL_BRDG_CTRL0
env_cfg.cxl_nfi_agnt_tx[0]    = ACTIVE_AGNT;
env_cfg.cxl_nfi_agnt_rx[0]    = PASSIVE_AGNT;
env_cfg.cxl_cfgsts_agnt[0]    = PASSIVE_AGNT;
env_cfg.cxl_pm_in_agnt[0]     = PASSIVE_AGNT;
env_cfg.cxl_pm_out_agnt[0]    = PASSIVE_AGNT;
env_cfg.cxl_credit_agnt_tx[0] = PASSIVE_AGNT;
env_cfg.cxl_credit_agnt_rx[0] = PASSIVE_AGNT;
env_cfg.elbi_agnt[0]          = PASSIVE_AGNT;
`else
env_cfg.cxl_nfi_agnt_tx[1]    = ACTIVE_AGNT;
env_cfg.cxl_nfi_agnt_rx[1]    = PASSIVE_AGNT;
env_cfg.cxl_cfgsts_agnt[1]    = PASSIVE_AGNT;
env_cfg.cxl_pm_in_agnt[1]     = PASSIVE_AGNT;
env_cfg.cxl_pm_out_agnt[1]    = PASSIVE_AGNT;
env_cfg.cxl_credit_agnt_tx[1] = PASSIVE_AGNT;
env_cfg.cxl_credit_agnt_rx[1] = PASSIVE_AGNT;
env_cfg.elbi_agnt[1]          = PASSIVE_AGNT;
`endif

// PS-side ISR agent active so post_enum_seq()/HDM-decoder-commit interrupt
// polling (base_cxl_ep_test / hdm-decoder callback machinery) can observe
// MSI/legacy interrupts if this design's cfg enables them.
env_cfg.ps_isr_agnt = ACTIVE_AGNT;
env_cfg.pl_isr_agnt = PASSIVE_AGNT;
