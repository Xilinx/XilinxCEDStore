`ifndef DMA_PCIE_H2C_BYP_IN_IF_SV
`define DMA_PCIE_H2C_BYP_IN_IF_SV
    interface dma_pcie_h2c_byp_in_if;
        logic [63 :0]                   dsc;
        logic [`QID_WIDTH-1:0]          qid;
        logic                           wbi;
        logic                           wbi_chk;
        logic [15:0]                    cidx;
        logic [15:0]                    len;
        logic                           last;
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
            input           wbi,
            input           wbi_chk,
            input           cidx,
            input           len,
            input           last,
            input           chn,
            input           vld,
            output          crdt_chn,
            output          crdt
        );
    endinterface
`endif
