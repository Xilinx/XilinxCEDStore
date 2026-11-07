`include "gpmon_if.sv"

package gpmon_agent_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import base_agent_pkg::*;

  typedef enum {SYNC, ASYNC} sync_async_t;

  `include "gpmon_cfg.sv"
  `include "gpmon_txn.sv"
  `include "gpmon_mon_cb.sv"
  `include "gpmon_monitor.sv"
  `include "gpmon_agent.sv"

  // Common callbacks; these are part of the status interface
  // that go to the PL
  `include "cb/ltssm_cb.sv"
  `include "cb/current_speed_cb.sv"
  `include "cb/function_status_cb.sv"
  `include "cb/link_down_cb.sv"
  `include "cb/link_status_cb.sv"
  `include "cb/negotiated_width_cb.sv"

endpackage
