`ifndef DMA_PCIE_H2C_BYP_OUT_IF_SV
`define DMA_PCIE_H2C_BYP_OUT_IF_SV
    interface dma_pcie_h2c_byp_out_if;
        logic [127:0]                   dsc;
        logic [`QID_WIDTH-1:0]          qid;
        logic                           wbi;
        logic                           wbi_chk;
        logic [15:0]                    cidx;
        logic                           last;
        logic                           lsiz;
        logic  [1:0]                    chn;
        logic                           vld;
        logic  [1:0]                    crdt_chn;
        logic                           crdt;
        modport m (
            output          dsc,
            output          qid,
            output          wbi,
            output          wbi_chk,
            output          cidx,
            output          last,
            output          lsiz,
            output          chn,
            output          vld,
            input           crdt_chn,
            input           crdt
        );
        modport s (
            input           dsc,
            input           qid,
            input           wbi,
            input           wbi_chk,
            input           cidx,
            input           last,
            input           lsiz,
            input           chn,
            input           vld,
            output          crdt_chn,
            output          crdt
        );
    endinterface
`endif
