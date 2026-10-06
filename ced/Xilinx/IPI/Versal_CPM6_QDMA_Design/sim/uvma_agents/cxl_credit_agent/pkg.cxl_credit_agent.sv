`include "cxl_credit_agent_if.sv"

package cxl_credit_agent_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import base_agent_pkg::*;

  `include "cxl_credit_txn.sv"  
  `include "cxl_credit_bus_txn.sv"  
  `include "cxl_credit_cfg.sv"  
  `include "cxl_credit_share.sv"  
  `include "cxl_credit_sequencer.sv"  
  `include "cxl_credit_monitor.sv"  
  `include "cxl_credit_driver.sv"  
  `include "cxl_credit_api_seq.sv"  
  `include "cxl_credit_pool_seq.sv"  
  `include "cxl_credit_api.sv"  
  `include "cxl_credit_agent.sv"  

endpackage
