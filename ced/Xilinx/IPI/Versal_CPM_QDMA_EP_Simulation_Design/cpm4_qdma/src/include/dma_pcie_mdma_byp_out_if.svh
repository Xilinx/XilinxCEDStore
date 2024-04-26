`ifndef DMA_PCIE_MDMA_BYP_OUT_IF_SV
`define DMA_PCIE_MDMA_BYP_OUT_IF_SV
    interface dma_pcie_mdma_byp_out_if;
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
