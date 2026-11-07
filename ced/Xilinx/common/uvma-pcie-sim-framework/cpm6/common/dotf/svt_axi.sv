// This will set pull in the svt_axi_user_defines.svi file's defines
`define SVT_AXI_INCLUDE_USER_DEFINES

// This must be defined or else: failure
`define UVM_PACKER_MAX_BYTES 4096

`include "svt_axi.uvm.pkg"
