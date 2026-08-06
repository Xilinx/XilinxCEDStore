`include "gpdrv_if.sv"

package gpdrv_agent_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import base_agent_pkg::*;

  typedef enum {SYNC, ASYNC} sync_async_t;

  `include "gpdrv_cfg.sv"
  `include "gpdrv_txn.sv"
  `include "gpdrv_api_seq.sv"
  `include "gpdrv_mon_cb.sv"
  `include "gpdrv_monitor.sv"
  `include "gpdrv_api.sv"
  `include "gpdrv_driver.sv"
  `include "gpdrv_agent.sv"

  // Common callbacks

endpackage
