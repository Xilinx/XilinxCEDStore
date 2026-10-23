`include "elbi_if.sv"

package elbi_agent_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import base_agent_pkg::*;

  typedef enum bit [3:0] {APP, MBAR0, IO, EROM=4, DBI=8} acc_t;

  `include "elbi_cfg.sv"
  `include "elbi_txn.sv"
  `include "elbi_share.sv"
  `include "elbi_driver.sv"
  `include "elbi_monitor.sv"
//`include "elbi_api_seq.sv" //enhancement
//`include "elbi_api.sv"     //enhancement
  `include "elbi_slv_base_seq.sv"
  `include "elbi_agent.sv"

endpackage
