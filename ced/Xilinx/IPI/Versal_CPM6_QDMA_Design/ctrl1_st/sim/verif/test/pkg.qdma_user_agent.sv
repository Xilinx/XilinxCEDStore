// pkg.qdma_user_agent.sv — Package for the QDMA user-side AXI4-Stream agent.
//
// The interface (qdma_user_if) is compiled at file scope before the package
// so it is visible to both the package classes and the bind module.

// ---- Interface (file scope — must precede the package) ------------------
`include "qdma_user_if.sv"

// ---- Package ------------------------------------------------------------
package qdma_user_agent_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "qdma_user_transaction.sv"
  `include "qdma_user_monitor.sv"
  `include "qdma_user_driver.sv"
  `include "c2h_prefill_sequence.sv"
  `include "qdma_user_scoreboard.sv"
  `include "qdma_user_agent.sv"

endpackage
