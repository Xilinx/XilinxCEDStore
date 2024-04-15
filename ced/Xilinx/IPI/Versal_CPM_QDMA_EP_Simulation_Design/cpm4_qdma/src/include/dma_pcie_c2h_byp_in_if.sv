`ifndef DMA_PCIE_C2H_BYP_IN_IF_SV
`define DMA_PCIE_C2H_BYP_IN_IF_SV
    interface dma_pcie_c2h_byp_in_if;
        logic [63 :0]                   dsc;
        logic [`QID_WIDTH-1:0]          qid;
        logic [21:0]                    len;
        logic                           last;
        logic  [1:0]                    chn;
        logic                           vld;
        logic  [1:0]                    crdt_chn;
        logic                           crdt;
        modport m (
            output          dsc,
            output          qid,
            output          len,
            output          last,
            output          chn,
            output          vld,
            input           crdt_chn,
            input           crdt
        );
        modport s (
            input           dsc,
            input           qid,
            input           len,
            input           last,
            input           chn,
            input           vld,
            output          crdt_chn,
            output          crdt
        );
    endinterface
`endif
