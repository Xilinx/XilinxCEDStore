`include "cfg_ext_if.sv"
`include "cfg_ext_rsp_if.sv"

package cfg_ext_agent_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import base_agent_pkg::*;

  `include "cfg_ext_share.sv"
  `include "cfg_ext_txn.sv"
  `include "cfg_ext_driver.sv"
  `include "cfg_ext_monitor.sv"
  `include "cfg_ext_api_seq.sv"
  `include "cfg_ext_api.sv"
  `include "cfg_ext_slv_base_seq.sv"
  `include "cfg_ext_agent.sv"

endpackage
