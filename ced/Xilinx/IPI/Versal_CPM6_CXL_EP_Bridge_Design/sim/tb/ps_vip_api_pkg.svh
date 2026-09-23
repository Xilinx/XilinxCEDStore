package ps_vip_api_pkg;
  // The only valid inputs to ps_gen_clock
  typedef enum bit [4:0] {
    PSCLK__NOC_PMC_AXI0,
    PSCLK__NOC_PS_CCI_AXI0,
    PSCLK__NOC_PS_CCI_AXI1,
    PSCLK__NOC_PS_NCI_AXI0,
    PSCLK__NOC_PS_NCI_AXI1,
    PSCLK__NOC_PS_PCI_AXI0,
    PSCLK__PMC_NOC_AXI0,
    PSCLK__PS_NOC_CCI_AXI0,
    PSCLK__PS_NOC_CCI_AXI1,
    PSCLK__PS_NOC_CCI_AXI2,
    PSCLK__PS_NOC_CCI_AXI3,
    PSCLK__PS_NOC_NCI_AXI0,
    PSCLK__PS_NOC_NCI_AXI1,
    PSCLK__PS_NOC_PCI_AXI0,
    PSCLK__PS_NOC_PCI_AXI1,
    PSCLK__PS_NOC_RPU_AXI0,
    PSCLK__LPD_CPM_TOP_SW_CLK 
  } ps_vip_clk_e;
  
  // The only valid inputs to set_routing_config(<slv>,...
  typedef enum bit [3:0] {
    S_AXI_FPD,
    S_AXI_GP2,
    S_AXI_LPD,
    NOC_FPD_CCI_0,  
    NOC_FPD_CCI_1,  
    NOC_FPD_AXI_0,  
    NOC_FPD_AXI_1,  
    S_ACP_FPD,
    S_ACE_FPD,
    NOC_PMC_AXI_0,
    NOC_PS_PCI_AXI_0, //different
    A72_API,
    NOC_API,
    R5_API,
    CPM_PS_AXI_0, //different
    CPM_PS_AXI_1  //different
  } ps_route_slv_e;
  
  // The only valid inputs to set_routing_config(...,<mst>,...)
  typedef enum bit [3:0] {
    FPD_CCI_NOC,
    M_AXI_FPD,
    M_AXI_LPD,
    FPD_AXI_NOC_0,  
    FPD_AXI_NOC_1,  
    PS_NOC_PCI_AXI_0, //different
    PS_NOC_PCI_AXI_1, //different
    PMC_NOC_AXI_0,
    NOC_LPD_AXI_0,
    PS_CPM_PCIE_AXI, //different
    PS_SLAVE,
    XRAM_APB,
    XRAM_AXI,
    // Others
    OCM,
    REG,
    PS_CPM_CFG //different
  } ps_route_mst_e;

endpackage;

