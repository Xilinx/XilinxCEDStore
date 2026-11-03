// pkg.axi_pl_agent.sv — UVM package for CPM6 AXI-PL passive performance monitoring
//
// Compilation order (tb_files.f):
//   1. verif/axi_pl_agent/axi_if.sv        — parameterized AXI4 interface
//                                            (file-scope, not in a package)
//   2. This file (pkg.axi_pl_agent.sv)     — package cpm_axi_env_pkg
//   3. pkg.proj_test_pkg.sv                — imports cpm_axi_env_pkg
//   4. verif/axi_pl_agent/bind.axi_pl.sv   — bind module using axi_if
//
// Included source files:
//   cpm_axi_perf_monitor.sv  — bandwidth + latency measurement per-port
//   cpm_axi_coverage.sv      — functional coverage (burst len/type/size/QoS)
//   cpm_axi_scoreboard.sv    — 4-port aggregator; writes CSV/JSON reports
//
// Environment:
//   cpm_axi_pl_vnc_env.sv    — 3-port env for PL0/PL1/PL3 (PL2 absent)

`ifndef CPM_AXI_ENV_PKG_SV
`define CPM_AXI_ENV_PKG_SV

package cpm_axi_env_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Performance monitor, coverage and scoreboard
  `include "cpm_axi_perf_monitor.sv"
  `include "cpm_axi_coverage.sv"
  `include "cpm_axi_scoreboard.sv"

  // Protocol/error checker
  `include "axi_pl_protocol_monitor.sv"

  // 3-port environment
  `include "cpm_axi_pl_vnc_env.sv"

endpackage : cpm_axi_env_pkg

`endif // CPM_AXI_ENV_PKG_SV
