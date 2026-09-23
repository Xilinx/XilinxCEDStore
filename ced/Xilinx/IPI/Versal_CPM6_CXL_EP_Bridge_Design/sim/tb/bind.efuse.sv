module bind_efuse
 import uvm_pkg::*;
();

  `include "uvm_macros.svh"

  initial begin
    force CPM_INST.EFUSECPMCCIXDIS = 1'b0;
    `uvm_info("EFUSE_FORCE", "Driving CPM_INST.EFUSECPMCCIXDIS = 1'b0 (CCIX is not modeled in this simulation)", UVM_NONE)
  end

endmodule
