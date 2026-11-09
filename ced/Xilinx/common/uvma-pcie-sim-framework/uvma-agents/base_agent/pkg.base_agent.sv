package base_agent_pkg;

  `ifdef TIME_BASE_PKG
    timeunit      `TIMEUNIT_BASE_PKG;
    timeprecision `TIMEPREC_BASE_PKG;
  `endif 

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  typedef enum bit {UVM_SLAVE=0, UVM_MASTER=1} uvm_master_slave_enum;

  `include "base_cfg.sv"
  `include "base_share.sv"
  `include "base_txn.sv"
  `include "base_driver.sv"
  `include "base_monitor.sv"
  `include "base_sequencer.sv"
  `include "base_api.sv"
  `include "base_agent.sv"

endpackage
