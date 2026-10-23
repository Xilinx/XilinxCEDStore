// pkg.pswizard_agent.sv — Package for the pswizard UVM agent
//
// pswizard_if.sv is included at file scope (outside the package) so that the
// interface is available as a standalone design unit.
//
// Compilation order (see ctrl1/sim/tb_files.f):
//   1. This file (pkg.pswizard_agent.sv)     — compiled before tb/tb_top.sv
//   2. verif/pswizard_agent/bind.pswizard.sv — compiled with the other bind
//      modules (order relative to tb_top.sv does not matter for bind files)
`include "pswizard_if.sv"
// pswizard_msix_if.sv is included unconditionally even though its bind
// (bind.pswizard_msix.sv, not present in this project) would be gated on
// MSIX_CTRL_MON. The monitor declares a `virtual pswizard_msix_if` member,
// so the type must always exist; the monitor's config_db get is soft and
// simply reports "NOT MONITORED" when no bind drives it.
`include "pswizard_msix_if.sv"

package pswizard_agent_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;
  // dsc_slot_params_pkg compiled ahead of this file — see ctrl1/sim/tb_files.f.
  // Needed by pswizard_monitor.sv's decode_noc_channel() (cpm_noc0 channel
  // decode).
  import dsc_slot_params_pkg::*;

  `include "pswizard_cfg.sv"
  `include "pswizard_txn.sv"
  `include "pswizard_monitor.sv"
  `include "pswizard_agent.sv"

endpackage : pswizard_agent_pkg
