// pkg.qdma_periph_agent.sv — Package for the QDMA periphery UVM agent
//
// qdma_periph_if.sv is included at file scope (outside the package) so that
// the interface is available as a standalone design unit, matching the pattern
// used by pswizard_agent and other monitor agents.
//
// Compilation order (both files are listed in tb_files.f in this order):
//   1. This file (pkg.qdma_periph_agent.sv)
//   2. verif/qdma_periph_agent/bind.qdma_periph.sv
`include "qdma_periph_if.sv"
// qdma_periph_tm_dsc_if.sv is included unconditionally
// for the same reason pswizard_msix_if.sv is in pswizard_agent's package:
// the monitor declares a `virtual qdma_periph_tm_dsc_if vif_tm` member, so
// the type must always exist even when bind.tm_dsc_sts.sv isn't compiled
// (e.g. CED, which has no `CPM6_TOP_WRAPPER macro infra for that bind) —
// the monitor's config_db get for it is soft/non-fatal.
`include "qdma_periph_tm_dsc_if.sv"

package qdma_periph_agent_pkg;

   `include "uvm_macros.svh"
   import uvm_pkg::*;

   `include "qdma_periph_cfg.sv"
   `include "qdma_periph_txn.sv"
   `include "qdma_periph_monitor.sv"
   `include "qdma_periph_agent.sv"

endpackage : qdma_periph_agent_pkg
