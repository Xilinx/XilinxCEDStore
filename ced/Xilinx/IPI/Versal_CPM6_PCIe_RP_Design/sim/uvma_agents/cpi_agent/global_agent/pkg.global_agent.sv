`include "global_if.sv"

package global_agent_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import base_agent_pkg::*;
  import cpi_common_pkg::*;

  `include "global_txn.sv"
  `include "global_cfg.sv"
  `include "global_share.sv"
  `include "global_slv_base_seq.sv"
  `include "global_monitor.sv"
  `include "global_driver.sv"
  `include "global_api_seq.sv"
  `include "global_api.sv"
  `include "global_agent.sv"

endpackage
