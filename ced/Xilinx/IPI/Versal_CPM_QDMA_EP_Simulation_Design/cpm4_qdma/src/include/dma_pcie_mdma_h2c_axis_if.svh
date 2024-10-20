`ifndef IF_PCIE_MDMA_H2C_AXIS_SV
`define IF_PCIE_MDMA_H2C_AXIS_SV
interface dma_pcie_mdma_h2c_axis_if#()();
logic  [511:0]       tdata;
logic  [512/8-1:0]   tparity;
logic                tlast;
logic                tvalid;
logic  [512/8-1:0]   tkeep;
logic                tready;
logic  [63:0]        tusr;

modport m (
output     tdata,
output     tparity,
output     tlast,
output     tvalid,
output     tkeep,
output     tusr,
input      tready
);

modport s (
input       tdata,
input       tparity,
input       tlast,
input       tvalid,
input       tkeep,
input       tusr,
output      tready
);
endinterface : dma_pcie_mdma_h2c_axis_if
`endif
