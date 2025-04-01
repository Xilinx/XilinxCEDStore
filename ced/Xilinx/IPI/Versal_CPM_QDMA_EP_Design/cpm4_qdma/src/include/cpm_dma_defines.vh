`ifndef DMA_DEFINES_VH
`define DMA_DEFINES_VH

`define CPLI_WIDTH 80

`define DAT_WIDTH 512
`define CHN_WIDTH 4
`define ADR_WIDTH 64
`define ALN_WIDTH 4	// Bits used for subbeat dword alignment 
`define LEN_WIDTH 28
`define RID_WIDTH 8 
`define DID_WIDTH 10 
`define QID_WIDTH 12	// Support for 128 H2C and 128 C2H queues
`define DSC_RID_WIDTH 16
`define DSC_DID_WIDTH 16
`define MSIX_WIDTH    5

`define H2C_TAR_ID 4'd0
`define C2H_TAR_ID 4'd1
`define IRQ_TAR_ID 4'd2
`define CFG_TAR_ID 4'd3
`define DSC_H2C_TAR_ID 4'd4
`define DSC_C2H_TAR_ID 4'd5
`define DSC_TAR_ID 4'd6
`define CFG_TAR2_ID 4'd7
`define MSIX_TAR_ID 4'd8
`define MSIX_ENC_VEC0_TAR_ID 4'd8
`define MSIX_ENC_VEC1_TAR_ID 4'd9
`define MSIX_ENC_VEC2_TAR_ID 4'd10
`define MSIX_ENC_VEC3_TAR_ID 4'd11 
`define MSIX_ENC_PBA_TAR_ID  4'd11 
`define IND_BUS_TAR_ID       4'd12 

`define MSIX_PBA_OFFSET 12'hfe0
`define MSIX_ENC_PBA_OFFSET 12'h0
`define MSIX_ENC_VEC_OFFSET 12'h0

`define XDMA_C2H_TUSER_WIDTH   64
`define XDMA_H2C_TUSER_WIDTH   32

`define MULTQ_EN 1 

`define DMA_PCIE_RST 0
`define XDMA_H2C_RST 1
`define XDMA_C2H_RST 2
`define MDMA_H2C_RST 3
`define MDMA_C2H_RST 4
`define DMA_AXI_RST  5
`define DMA_MISC_RST 6

`define UNC_ERR_HDR_POISON        1
`define UNC_ERR_HDR_UR_CA         2
`define UNC_ERR_HDR_BCNT          3
`define UNC_ERR_HDR_PARAM         4
`define UNC_ERR_HDR_ADDR          5
`define UNC_ERR_HDR_TAG           6
`define UNC_ERR_HDR_FLR           8
`define UNC_ERR_HDR_TIMEOUT       9
`define UNC_ERR_DAT_POISON       16 
`define UNC_ERR_DAT_PARITY       17
`define UNC_ERR_WR_UR            18 
`define UNC_ERR_WR_FLR           19
`define UNC_ERR_DMA              20    // Error signalled by dma engine
`define UNC_ERR_SLV_REQ          21    // Error signalled by Slave Port (like Invalid Burst)
`define UNC_ERR_DSC              21    // Error in use case of dsc engine
`define UNC_ERR_MISC_FAT         22
`define UNC_ERR_RAM_DBE          23
`define COR_ERR_RAM_SBE          24

`define DSC_PIDX_UPD_ERR          1    // PIDX update with more than 255 descriptors
`define DSC_PIDX_OVF_ERR          2    // PIDX update passed CIDX
`define DSC_RCV_CRD_ERR           3    // Received or subtracted too many credits

`endif
