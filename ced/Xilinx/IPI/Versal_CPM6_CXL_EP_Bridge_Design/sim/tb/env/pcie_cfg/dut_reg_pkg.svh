package dut_reg_pkg;

  // Register block offsets
  localparam CPM6_BASE      = 32'hFC00_0000;
  localparam PCIE0_CFG_BASE = CPM6_BASE;
  localparam PCIE1_CFG_BASE = CPM6_BASE+'h40_0000;

  // Register address offset and default of a single register
  typedef struct packed {
    bit [31:0] addr;
    bit [31:0] dfault;
  } pair;

  `define CFG0(O) PCIE0_CFG_BASE+O
  `define CFG1(O) PCIE1_CFG_BASE+O

  /* Register address and dfault of a set of registers in a reg block */
  typedef struct {
    // MSI Cap
    pair PF0_MSI_CAP_PCI_MSI_CAP_ID_NEXT_CTRL_REG                 = {`CFG0('h50), 32'h038A_7005}; 
    // PCIe Cap
    pair PF0_PCIE_CAP_PCIE_CAP_ID_PCIE_NEXT_CAP_PTR_PCIE_CAP_REG  = {`CFG0('h70), 32'h8102_B010}; 
    pair PF0_PCIE_CAP_DEVICE_CAPABILITIES_REG                     = {`CFG0('h74), 32'h1002_8FE3}; 
    pair PF0_PCIE_CAP_DEVICE_CONTROL_DEVICE_STATUS                = {`CFG0('h78), 32'h0010_2910}; 
    pair PF0_PCIE_CAP_LINK_CAPABILITIES_REG                       = {`CFG0('h7C), 32'h0043_7886}; 
    pair PF0_PCIE_CAP_LINK_CONTROL_LINK_STATUS_REG                = {`CFG0('h80), 32'h1011_0000};
    pair PF0_PCIE_CAP_DEVICE_CAPABILITIES2_REG                    = {`CFG0('h94), 32'hB6FF_3B9F}; 
    pair PF0_PCIE_CAP_DEVICE_CONTROL2_DEVICE_STATUS2_REG          = {`CFG0('h98), 32'h0000_0000}; 
    pair PF0_PCIE_CAP_LINK_CAPABILITIES2_REG                      = {`CFG0('h9C), 32'h8180_017E}; 
    pair PF0_PCIE_CAP_LINK_CONTROL2_LINK_STATUS2_REG              = {`CFG0('hA0), 32'h0301_0006};
    // ARI ExtCap
    pair PF0_ARI_CAP_CAP_REG                                      = {`CFG0('h16C), 32'h0000_0102};
    // PL64G ExtCap
    pair PF0_PL64G_CAP_PL64G_EXT_CAP_HDR_REG                      = {`CFG0('h210), 32'h2281_0031};
    // Device 3 ExtCap
    pair PF0_DEV3_EXT_CAP_DEVICE_CAPABILITIES_REG                 = {`CFG0('h580), 32'h0000_000A};
    // PCIe DVSEC for CXL Devices
    pair PF0_CXL_DEVICE_CAP_CXL_RCIEP_DVSEC_HDR_2_FLEXBUS_CAP_OFF = {`CFG0('h620), 32'hE9DF_0000};
    pair PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEX_BUS_LOCK_OFF           = {`CFG0('h62C), 32'h0000_0000};
    pair PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEXBUS_R1_SIZE_HIGH_OFF    = {`CFG0('h630), 32'h0000_0000};
    pair PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEXBUS_R1_SIZE_LOW_OFF     = {`CFG0('h634), 32'h0000_0048};
    pair PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEXBUS_R2_SIZE_HIGH_OFF    = {`CFG0('h640), 32'h0000_0000};
    pair PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEXBUS_R2_SIZE_LOW_OFF     = {`CFG0('h644), 32'h0000_0048};
    // Other
    pair PF0_PORT_LOGIC_TIMER_CTRL_MAX_FUNC_NUM_OFF               = {`CFG0('h718), 32'h4001_8007}; 
  } PCIE0_CFG_block;

  typedef struct {
    // MSI Cap
    pair PF0_MSI_CAP_PCI_MSI_CAP_ID_NEXT_CTRL_REG                 = {`CFG1('h50), 32'h038A_7005}; 
    // PCIe Cap
    pair PF0_PCIE_CAP_PCIE_CAP_ID_PCIE_NEXT_CAP_PTR_PCIE_CAP_REG  = {`CFG1('h70), 32'h8102_B010}; 
    pair PF0_PCIE_CAP_DEVICE_CAPABILITIES_REG                     = {`CFG1('h74), 32'h1002_8FE3}; 
    pair PF0_PCIE_CAP_DEVICE_CONTROL_DEVICE_STATUS                = {`CFG1('h78), 32'h0010_2910}; 
    pair PF0_PCIE_CAP_LINK_CAPABILITIES_REG                       = {`CFG1('h7C), 32'h0043_7886}; 
    pair PF0_PCIE_CAP_LINK_CONTROL_LINK_STATUS_REG                = {`CFG1('h80), 32'h1011_0000};
    pair PF0_PCIE_CAP_DEVICE_CAPABILITIES2_REG                    = {`CFG1('h94), 32'hB6FF_3B9F}; 
    pair PF0_PCIE_CAP_DEVICE_CONTROL2_DEVICE_STATUS2_REG          = {`CFG1('h98), 32'h0000_0000}; 
    pair PF0_PCIE_CAP_LINK_CAPABILITIES2_REG                      = {`CFG1('h9C), 32'h8180_017E}; 
    pair PF0_PCIE_CAP_LINK_CONTROL2_LINK_STATUS2_REG              = {`CFG1('hA0), 32'h0301_0006};
    // ARI ExtCap
    pair PF0_ARI_CAP_CAP_REG                                      = {`CFG1('h16C), 32'h0000_0102};
    // PL64G ExtCap
    pair PF0_PL64G_CAP_PL64G_EXT_CAP_HDR_REG                      = {`CFG1('h210), 32'h2281_0031};
    // Device 3 ExtCap
    pair PF0_DEV3_EXT_CAP_DEVICE_CAPABILITIES_REG                 = {`CFG1('h580), 32'h0000_000A};
    // PCIe DVSEC for CXL Devices
    pair PF0_CXL_DEVICE_CAP_CXL_RCIEP_DVSEC_HDR_2_FLEXBUS_CAP_OFF = {`CFG1('h620), 32'hE9DF_0000};
    pair PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEX_BUS_LOCK_OFF           = {`CFG1('h62C), 32'h0000_0000};
    pair PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEXBUS_R1_SIZE_HIGH_OFF    = {`CFG1('h630), 32'h0000_0000};
    pair PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEXBUS_R1_SIZE_LOW_OFF     = {`CFG1('h634), 32'h0000_0048};
    pair PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEXBUS_R2_SIZE_HIGH_OFF    = {`CFG1('h640), 32'h0000_0000};
    pair PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEXBUS_R2_SIZE_LOW_OFF     = {`CFG1('h644), 32'h0000_0048};
    // Other
    pair PF0_PORT_LOGIC_TIMER_CTRL_MAX_FUNC_NUM_OFF               = {`CFG1('h718), 32'h4001_8007}; 
  } PCIE1_CFG_block;

  // A struct of register blocks that can now refer to a single register as such:
  // rr = "reg root"
  // rr.<block>.<register>.addr or rr.<block>.<register>.dfault
  const struct {
     PCIE0_CFG_block              PCIE0_CFG;
     PCIE1_CFG_block              PCIE1_CFG;
/*   Add the below as needed
     CPM6_INT_WRAP_BOT_CSR_block  CPM6_INT_WRAP_BOT_CSR;  
     CPM6_PCIE_CORE0_block        CPM6_PCIE_CORE0;        
     CPM6_PCIE_DOE_RAM0_block     CPM6_PCIE_DOE_RAM0;     
     CPM6_PCIE_IDE0_IO_AES_block  CPM6_PCIE_IDE0_IO_AES;  
     CPM6_PCIE_IDE0_IO_CSR_block  CPM6_PCIE_IDE0_IO_CSR;  
     CPM6_PCIE_IDE0_INT_CSR_block CPM6_PCIE_IDE0_INT_CSR; 
     CPM6_PCIE_APP0_block         CPM6_PCIE_APP0;         
     CPM6_PL_BOT_CSR_block        CPM6_PL_BOT_CSR;        
     CPM6_DMANOC_CSR_block        CPM6_DMANOC_CSR;        
     CPM6_CLK_CORE0_block         CPM6_CLK_CORE0;         
     CPM6_INT_WRAP_TOP_CSR_block  CPM6_INT_WRAP_TOP_CSR;  
     CPM6_PCIE_CORE1_block        CPM6_PCIE_CORE1;        
     CPM6_PCIE_DOE_RAM1_block     CPM6_PCIE_DOE_RAM1;     
     CPM6_PCIE_IDE1_IO_AES_block  CPM6_PCIE_IDE1_IO_AES;  
     CPM6_PCIE_IDE1_IO_CSR_block  CPM6_PCIE_IDE1_IO_CSR;  
     CPM6_PCIE_IDE1_INT_CSR_block CPM6_PCIE_IDE1_INT_CSR; 
     CPM6_PCIE_APP1_block         CPM6_PCIE_APP1;         
     CPM6_PL_TOP_CSR_block        CPM6_PL_TOP_CSR;        
     CPM6_CLK_CORE1_block         CPM6_CLK_CORE1;         
     CPM6_CONFIG_BRIDGE_block     CPM6_CONFIG_BRIDGE;     
     CPM6_CRX_block               CPM6_CRX;               
     CPM6_SLCR_block              CPM6_SLCR;              
     CPM6_SLCR_SECURE_block       CPM6_SLCR_SECURE;       
     CPM6_SYSMON_block            CPM6_SYSMON;            
     CPM6_INT_GPV_block           CPM6_INT_GPV;           
     CPM6_PCSR_block              CPM6_PCSR;              
*/
  } rr;

  `undef CFG0
  `undef CFG1

endpackage
