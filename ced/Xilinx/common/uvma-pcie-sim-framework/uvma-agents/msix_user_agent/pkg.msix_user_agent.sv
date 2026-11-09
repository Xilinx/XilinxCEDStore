`include "msix_user_if.sv"

package msix_user_agent_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import base_agent_pkg::*;

  typedef enum bit [1:0] {
    SEND_IRQ, CHK_PEND, CLR_PEND
  } msix_op_e;

  `include "msix_user_cfg.sv"
  `include "msix_user_txn.sv"
  `include "msix_user_api_seq.sv"
  `include "msix_user_monitor.sv"
  `include "msix_user_api.sv"
  `include "msix_user_driver.sv"
  `include "msix_user_agent.sv"

endpackage
