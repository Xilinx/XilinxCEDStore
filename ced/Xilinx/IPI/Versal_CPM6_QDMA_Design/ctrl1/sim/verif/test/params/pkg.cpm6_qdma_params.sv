package cpm6_qdma_params_pkg;
  localparam NUM_QIDS = 4096;
  localparam RING_SIZE = 4096;
  localparam DATA_WIDTH = 256;
  localparam C_ECC_ENABLE = 0;
  localparam MULTQ_EN = 0;
  localparam NUM_PF = 1;
  localparam NUM_VF = 8;
  localparam NUM_CHN = 128;
  // VF_OFFSET is VF0's absolute PCIe function number. CPM6's mailbox_fsm.sv
  // sets it to NUM_PFS by default, but this IP build's actual generated
  // VFGX_FIRST_VF_OFFSET (see genBd/msix_params.vh) is 4, not NUM_PF -- a
  // pre-S4 mailbox convention this build predates. +define+VF_OFFSET_OVERRIDE=4
  // forces the value this IP build actually uses; omit it once a build with
  // VF_OFFSET == NUM_PFS is used instead.
  localparam VF_OFFSET = `ifdef VF_OFFSET_OVERRIDE `VF_OFFSET_OVERRIDE `else NUM_PF `endif;
  localparam NUM_FNCS = NUM_PF + NUM_VF;
  localparam VIRTIO_EN = 0;
  localparam C_MHOST_EN = "FALSE";
  // DMA mode — set by Makefile via +define+QDMA_DMA_ST=<0|1> +define+QDMA_DMA_MM=<0|1>.
  // Auto-detected from Vivado IP wrapper (design_1_cpm6_qdma_0_0.sv).
  // Fallback: DMA_ST=0, DMA_MM=1 (memory-mapped) if defines are absent.
  localparam DMA_ST = `ifdef QDMA_DMA_ST `QDMA_DMA_ST `else 0 `endif;
  localparam DMA_MM = `ifdef QDMA_DMA_MM `QDMA_DMA_MM `else 1 `endif;
  localparam DMA_CMPT = DMA_ST;
  localparam MDMA_C2H_PFCH_EN = 0;
  localparam DSC_FETCH_MAX_QID = 7;
  // 24 = bytes per descriptor element in the host DMA descriptor ring (fixed AMD
  // QDMA descriptor format width); (DSC_FETCH_MAX_QID+1) = 8 elements per
  // fetch-engine slot (7 data descriptors + 1 LINK descriptor) -- same 8x24=192B
  // slot geometry as NUM_DE_PER_SLOT/NUM_LINK_PER_SLOT/DSC_ELEMENT_BYTES in
  // pkg.dsc_slot_params.sv.
  localparam DSC_SLOT_SIZE = (DSC_FETCH_MAX_QID +1) * 24;
  // PF/VF queue-space register windows within the QDMA ELBI/TRQ address map.
  // PF window: base 0x18000, span 0x8000 (i.e. 0x18000-0x20000, the "Queue"
  // region in the CPM6 QDMA register map). VF window: base 0x3000, span
  // 0x1000 (4KB, one page) -- VFs get a much smaller BAR-mapped queue-space
  // than PF.
  localparam QDMA_TRQ_SEL_QUEUE_PF = 20'h18000;
  localparam QDMA_TRQ_SEL_QUEUE_PF_RANGE = 16'h8000;
  localparam QDMA_TRQ_SEL_QUEUE_VF = 16'h3000;
  localparam QDMA_TRQ_SEL_QUEUE_VF_RANGE = 16'd4096;
  localparam QDMA_CSR = 16'h0;
  // CSR region span 0x2000 (i.e. 0x0-0x2000), matching the "CSR" region in the
  // CPM6 QDMA register map.
  localparam QDMA_CSR_RANGE = 16'h2000;
  bit  [11:0] MAX_QID            = 12'h800;//d'2048
  parameter int QDMA_DSC_SZ = 'd32; //Size in number of bytes
  bit  [31:0] HOST_DSC_MEM_SIZE  = RING_SIZE * QDMA_DSC_SZ * MAX_QID; //Host memory size to hold descriptors for all QIDs in one direction (H2C or C2H).
  bit  [63:0] H2C_DAT_SRC_ADDR   = 64'h0;      //H2C DATA Buffer between 32'h0 to 32'hFFFF
  //Only 48-bits are needed for AXI-PL port addresses. For CPM-PL-AXI1 and CPM-PL-AXI3, address bit [48] is set to 1.
  // These MUST match the DMA aperture BASEADDR the BD's Address Editor assigns to each
  // CPM_AXI_PLn port (ps_wizard_0's CPM6_CONFIG: CPM6_CTRL1_DMA_APERTUREn_BASEADDR/LIMITADDR,
  // e.g. via `get_bd_cells ps_wizard_0` + inspect CPM6_CONFIG, or Vivado's Address Editor tab) --
  // bit [48] selects the PL0/PL2 vs PL1/PL3 port group, and the remaining bits are the offset
  // checked against that port's aperture BASEADDR/LIMITADDR. This BD's DMA_APERTURE0/1 are both
  // BASEADDR=0x0/LIMITADDR=0xFFFF (64KB, matches PL_BRAM_APERTURE_SIZE) -- ADDR0 below was
  // 0xC0000000 (an offset far outside that 64KB window; happened to collide numerically with
  // the unrelated CPM6 DBI1 register segment on a different address map, not this BD's PL0
  // aperture) and caused H2C writes on port 0 to target an unmapped offset, stalling the
  // transfer after partial host-side read progress.
  bit  [63:0] H2C_DAT_DST_ADDR0  = 64'h0;  //CPM-PL-AXI0 port Address assigned in PL address editor
  bit  [63:0] H2C_DAT_DST_ADDR1  = 64'h1_0000_0000_0000;  //CPM-PL-AXI1 port Address assigned in PL address editor -
  bit  [63:0] H2C_DAT_DST_ADDR2  = 64'h02040000;  //CPM-PL-AXI2 port Address assigned in PL address editor -- UNVERIFIED: this BD's DMA_APERTURE2 destination is PCIE_AXI_NOC0 (CSR/register space), not a 3rd BRAM port; only reachable via +NUM_DMA_PORTS>2 (default 2), do not use without re-checking the Address Editor first
  bit  [63:0] H2C_DAT_DST_ADDR3  = 64'h04040000;  //CPM-PL-AXI3 port Address assigned in PL address editor -- UNVERIFIED, same caveat as ADDR2 (this BD only defines 3 DMA apertures total)
  // Size of the AXI-PL0/PL1 BRAM apertures backing H2C_DAT_DST_ADDR0/1 and
  // C2H_DAT_SRC_ADDR0/1 (axi_bram_ctrl_0/_1 in genBd_cpm6_qdma_ip_2026_2_072026.tcl).
  // Used to assign each QID a wrapped slot index so its destination/source offset
  // never exceeds the real backing memory, regardless of how many QIDs are tested
  // or their numeric values.
  localparam longint unsigned PL_BRAM_APERTURE_SIZE = 64'h0001_0000; // 64 KB
  bit  [31:0] H2C_DAT_SIZE       = {$clog2(MAX_QID),16'h1000};   //To generate 4K size packet
  bit  [63:0] H2C_DSC_ADDR       = H2C_DAT_SRC_ADDR + H2C_DAT_SIZE + 64'h1000;  //H2C DSC rings between 32'h1_0000 to 32'h1_FFFF
  bit  [63:0] C2H_DSC_ADDR       = H2C_DSC_ADDR + HOST_DSC_MEM_SIZE; //C2H DSC rings between 32'h10_0000 to 32'h1F_FFFF 
  bit  [31:0] DSC_MEM_SIZE       = 32'h100000; //DSC BRAM is 1M size  
  // C2H reads from PL1 BRAM (independent of H2C which uses PL0 BRAM).
  // PL1 BRAM is pre-loaded with the H2C data pattern before C2H PIDX is issued,
  // eliminating the ordering dependency between H2C and C2H in DIRECTION=BOTH.
  bit  [63:0] C2H_DAT_SRC_ADDR0  = H2C_DAT_DST_ADDR1;  // PL1 BRAM (was PL0)
  bit  [63:0] C2H_DAT_SRC_ADDR1  = H2C_DAT_DST_ADDR1;  // PL1 BRAM
  bit  [63:0] C2H_DAT_SRC_ADDR2  = H2C_DAT_DST_ADDR1;  // PL1 BRAM
  bit  [63:0] C2H_DAT_SRC_ADDR3  = H2C_DAT_DST_ADDR1;  // PL1 BRAM
  bit  [63:0] C2H_DAT_DST_ADDR   = C2H_DSC_ADDR + HOST_DSC_MEM_SIZE + 64'h1000; //H2C DATA Buffer between 32'h20_0000 to 32'h2F_FFFF
  bit  [31:0] C2H_DAT_SIZE       = H2C_DAT_SIZE;
  bit  [63:0] CMPT_RING_BASE     = C2H_DAT_DST_ADDR + C2H_DAT_SIZE + 64'h1000;
  bit  [31:0] PF_MB_MSIX_OFFSET  = 32'h40000;  //512K BAR size, 256K window size.
  bit  [31:0] VF_MB_MSIX_OFFSET = 32'h4000;
  integer     QUEUE_PER_VF     = 8;
  localparam TCQ = 1;
endpackage
