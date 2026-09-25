module bind_efuse
 import uvm_pkg::*;
();

  `include "uvm_macros.svh"

  initial begin
    force CPM_INST.EFUSECPMCCIXDIS = 1'b0;
    `uvm_info("FIXME::PORT_DRIVE", "Driving CPM_INST.EFUSECPMCCIXDIS = 1'b0", UVM_NONE)
  end

endmodule
