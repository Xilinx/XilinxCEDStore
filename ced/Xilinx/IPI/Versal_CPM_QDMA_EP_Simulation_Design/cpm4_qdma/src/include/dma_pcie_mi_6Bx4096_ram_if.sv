`ifndef DMA_PCIE_MI_6BX4096_RAM_IF_SV
`define DMA_PCIE_MI_6BX4096_RAM_IF_SV

interface dma_pcie_mi_6Bx4096_ram_if();
        logic   [11:0]  wadr;
        logic           wen;
        logic   [47:0]  wdat;   //  39:32 = writeback accumulation count, 31:16 = used credits,  15:0= consumer index
        logic           ren;
        logic   [11:0]  radr;
        logic   [47:0]  rdat;
        logic           rsbe;
        logic           rdbe;

        modport  m (
                output  wadr,
                output  wen,
                output  wdat,
                output  ren,
                output  radr,
                input   rdat,
                input   rsbe,
                input   rdbe
         );
        modport  s (
                input   wadr,
                input   wen,
                input   wdat,
                input   ren,
                input   radr,
                output  rdat,
                output  rsbe,
                output  rdbe
         );
endinterface
`endif
