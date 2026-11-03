package cpm6_qdma_params_pkg;
  localparam NUM_QIDS = 4096;
  localparam RING_SIZE = 4096;
  localparam DATA_WIDTH = 256;
  localparam C_ECC_ENABLE = 0;
  localparam MULTQ_EN = 0;
  localparam NUM_PF = 1;
  // MAX_PF is the QDMA's PF capacity, independent of how many PFs this design
  // enables (NUM_PF). Do not derive one from the other.
  localparam MAX_PF = 4;
  // VF_OFFSET is VF0's absolute function number. In this design the VFs start
  // right after the enabled PFs, so VF_OFFSET equals NUM_PF. Every place that
  // needs VF0's function number uses VF_OFFSET, never MAX_PF.
  // +define+VF_OFFSET_OVERRIDE=<n> sets a different first-VF function number for
  // a block design that places VF0 elsewhere (CPM6 VFG0_FIRST_VF_OFFSET).
  localparam VF_OFFSET = `ifdef VF_OFFSET_OVERRIDE `VF_OFFSET_OVERRIDE `else NUM_PF `endif;
  localparam NUM_VF = 8;
  localparam NUM_CHN = 128;
  localparam NUM_FNCS = NUM_PF + NUM_VF;
  localparam VIRTIO_EN = 0;
  localparam C_MHOST_EN = "FALSE";
  // DMA mode — set by the Makefile via +define+QDMA_DMA_ST=<0|1> +define+QDMA_DMA_MM=<0|1>
  // (streaming: QDMA_DMA_ST=1, QDMA_DMA_MM=0). Without the defines: memory-mapped.
  localparam DMA_ST = `ifdef QDMA_DMA_ST `QDMA_DMA_ST `else 0 `endif;
  localparam DMA_MM = `ifdef QDMA_DMA_MM `QDMA_DMA_MM `else 1 `endif;
  localparam DMA_CMPT = DMA_ST;
  localparam MDMA_C2H_PFCH_EN = 0;
  localparam DSC_FETCH_MAX_QID = 7;
  localparam DSC_SLOT_SIZE = (DSC_FETCH_MAX_QID +1) * 24;
  localparam QDMA_TRQ_SEL_QUEUE_PF = 20'h18000;
  localparam QDMA_TRQ_SEL_QUEUE_PF_RANGE = 16'h8000;
  localparam QDMA_TRQ_SEL_QUEUE_VF = 16'h3000;
  localparam QDMA_TRQ_SEL_QUEUE_VF_RANGE = 16'd4096;
  localparam QDMA_CSR = 16'h0;
  localparam QDMA_CSR_RANGE = 16'h2000;
  bit  [11:0] MAX_QID            = 12'h800;//d'2048
  parameter int QDMA_DSC_SZ = 'd32; //Size in number of bytes
  bit  [31:0] HOST_DSC_MEM_SIZE  = RING_SIZE * QDMA_DSC_SZ * MAX_QID; //Host memory size to hold descriptors for all QIDs in one direction (H2C or C2H).
  bit  [63:0] H2C_DAT_SRC_ADDR   = 64'h0;      //H2C DATA Buffer between 32'h0 to 32'hFFFF
  // Memory-mapped transfer addresses on the CPM AXI-PL ports, used by the base
  // test's memory-mapped tasks only; the streaming test does not transfer to or
  // from these addresses. Only 48 bits are needed for AXI-PL port addresses; for
  // CPM-PL-AXI1 and CPM-PL-AXI3, address bit [48] is set to 1.
  // +define+AXI_PL0_ADDR_OVERRIDE=<addr> moves the AXI-PL0 target address.
  bit  [63:0] H2C_DAT_DST_ADDR0  = `ifdef AXI_PL0_ADDR_OVERRIDE `AXI_PL0_ADDR_OVERRIDE `else 64'hC0000000 `endif;  //CPM-PL-AXI0 port Address assigned in PL address editor
  bit  [63:0] H2C_DAT_DST_ADDR1  = 64'h1_0000_0000_0000;  //CPM-PL-AXI1 port Address assigned in PL address editor
  bit  [63:0] H2C_DAT_DST_ADDR2  = 64'h02040000;  //CPM-PL-AXI2 port Address assigned in PL address editor
  bit  [63:0] H2C_DAT_DST_ADDR3  = 64'h04040000;  //CPM-PL-AXI3 port Address assigned in PL address editor
  // Size of the memory behind each AXI-PL data port in a memory-mapped design.
  // Each QID gets a wrapped slot index so its offset never exceeds that memory,
  // whatever QIDs are tested.
  localparam longint unsigned PL_BRAM_APERTURE_SIZE = 64'h0001_0000; // 64 KB
  bit  [31:0] H2C_DAT_SIZE       = {$clog2(MAX_QID),16'h1000};   //To generate 4K size packet
  bit  [63:0] H2C_DSC_ADDR       = H2C_DAT_SRC_ADDR + H2C_DAT_SIZE + 64'h1000;  //H2C DSC rings between 32'h1_0000 to 32'h1_FFFF
  bit  [63:0] C2H_DSC_ADDR       = H2C_DSC_ADDR + HOST_DSC_MEM_SIZE; //C2H DSC rings between 32'h10_0000 to 32'h1F_FFFF 
  bit  [31:0] DSC_MEM_SIZE       = 32'h100000; //DSC BRAM is 1M size  
  // Memory-mapped C2H reads all come from the AXI-PL1 memory, which is pre-loaded
  // with the H2C data pattern before the C2H PIDX update. Keeping each memory
  // single-direction (H2C writes PL0, C2H reads PL1) also removes any H2C-before-C2H
  // ordering dependency when both directions run together.
  bit  [63:0] C2H_DAT_SRC_ADDR0  = H2C_DAT_DST_ADDR1;  // PL1 memory
  bit  [63:0] C2H_DAT_SRC_ADDR1  = H2C_DAT_DST_ADDR1;  // PL1 memory
  bit  [63:0] C2H_DAT_SRC_ADDR2  = H2C_DAT_DST_ADDR1;  // PL1 memory
  bit  [63:0] C2H_DAT_SRC_ADDR3  = H2C_DAT_DST_ADDR1;  // PL1 memory
  bit  [63:0] C2H_DAT_DST_ADDR   = C2H_DSC_ADDR + HOST_DSC_MEM_SIZE + 64'h1000; //H2C DATA Buffer between 32'h20_0000 to 32'h2F_FFFF
  bit  [31:0] C2H_DAT_SIZE       = H2C_DAT_SIZE;
  bit  [63:0] CMPT_RING_BASE     = C2H_DAT_DST_ADDR + C2H_DAT_SIZE + 64'h1000;
  bit  [31:0] PF_MB_MSIX_OFFSET  = 32'h40000;  //512K BAR size, 256K window size.
  bit  [31:0] VF_MB_MSIX_OFFSET = 32'h4000;
  integer     QUEUE_PER_VF     = 8;
  localparam TCQ = 1;
endpackage
