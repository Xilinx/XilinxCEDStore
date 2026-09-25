`include "aximon_if.sv"

package aximon_agent_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import base_agent_pkg::*;

  `include "aximon_cfg.sv"
  `include "aximon_txn.sv"
  `include "aximon_monitor.sv"
  `include "aximon_agent.sv"
endpackage
