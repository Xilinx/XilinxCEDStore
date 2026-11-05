`include "reset_if.sv"

package reset_agent_pkg;

  timeunit 1ns;
  timeprecision 1ns;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  typedef enum bit {ACTIVE_LO=0, ACTIVE_HI=1} active_hi_lo_enum; 
  typedef enum bit {ASYNC=0, SYNC=1} sync_async_type_enum; 
  typedef enum {ASSERT, 
                DEASSERT, 
                ASSERT_PULSE, 
                DEASSERT_PULSE,
                WENT_X,
                WENT_Z} reset_txn_type_enum;

  import base_agent_pkg::*;

  `include "reset_cfg.sv"
  `include "reset_txn.sv"
  `include "reset_driver.sv"
  `include "reset_monitor.sv"
  `include "reset_api_seq.sv"
  `include "reset_api.sv"
  `include "reset_agent.sv"

endpackage

