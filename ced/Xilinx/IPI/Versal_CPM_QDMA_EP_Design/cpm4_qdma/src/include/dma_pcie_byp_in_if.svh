`ifndef DMA_PCIE_BYP_IN_IF_SV
`define DMA_PCIE_BYP_IN_IF_SV
`timescale 1 ps / 1 ps
    interface dma_pcie_byp_in_if;
        logic [255 :0]                   dsc;
        logic [15:0]                    cidx;        
        logic                           vld;
        logic                           rdy;
        modport m (
            output          dsc,
            output          cidx,
            output          vld,
            input           rdy
        );
        modport s (
            input           dsc,
            input           cidx,
            input           vld,
            output          rdy
        );
    endinterface
`endif
