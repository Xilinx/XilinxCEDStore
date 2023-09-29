
`ifndef IF_PCIE_MDMA_C2H_AXIS_SV
`define IF_PCIE_MDMA_C2H_AXIS_SV

`include "cpm_mdma_defines.svh"

interface dma_pcie_mdma_c2h_axis_if#()();
mdma_c2h_axis_data_t    data;  
mdma_c2h_axis_ctrl_t    ctrl;
logic                   tlast;
logic [5:0]             mty; 
logic                   tvalid;
logic                   tready;

modport m (
output    data,    
output    ctrl,
output    tlast,   
output    mty, 
output    tvalid,  
input     tready  
);

modport s (
input     data,    
input     ctrl,
input     tlast,   
input     mty, 
input     tvalid,  
output    tready  
);
endinterface : dma_pcie_mdma_c2h_axis_if
`endif
