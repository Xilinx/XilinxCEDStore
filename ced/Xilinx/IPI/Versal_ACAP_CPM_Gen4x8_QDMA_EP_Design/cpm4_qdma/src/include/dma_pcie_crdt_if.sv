`ifndef IF_PCIE_DMA_CRDT_SV
`define IF_PCIE_DMA_CRDT_SV
interface dma_pcie_crdt_if #(
    parameter DATA_BITS=512,
    parameter CH_BITS=2
);
logic   [DATA_BITS-1:0]     tl_tdata;
logic                       tl_tvld;
logic   [CH_BITS-1:0]       tl_tch;

logic                       tl_crdt;
logic   [CH_BITS-1:0]       tl_crdt_ch;

    modport m (
        output  tl_tdata,
        output  tl_tvld,
        output  tl_tch,

        input   tl_cvld,
        input   tl_cch
    );

    modport s (
        input   tl_tdata,
        input   tl_tvld,
        input   tl_tch,

        output  tl_cvld,
        output  tl_cch
    );

endinterface : dma_pcie_crdt_if
`endif
