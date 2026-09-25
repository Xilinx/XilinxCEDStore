package tb_params_pkg;

  // These are the different agent config options
  typedef enum {
    PASSIVE_AGNT, ACTIVE_AGNT, UNUSED_AGNT
  } agent_mode_t;

  typedef enum {
    UNSPEC,
    // Same use case for each FSR
    PCIE_STR,
    PCIE_DMA,
    CXL,
    CXL_DMA,
    GT_BYPASS,
    // Different use case per FSR
    DMA_TOP__STR_BOT,
    STR_TOP__DMA_BOT,
    DMA_TOP__GT_BYP_BOT,
    CXL_DMA_TOP__GT_BYP_BOT
  } top_use_case_t;

  // Use these to index into the AXI VIP array
  // Note these master/slave terms are from the PoV of the VIP, not CPM6
  typedef enum {
    M_AXIMM_PS_CFG,
    M_AXIMM_PS_128,
    M_AXIL_PL_DBI0,
    M_AXIL_PL_DBI1,
    M_AXIMM_PL_512} m_axi_idx_t;

  typedef enum {
    S_AXIMM_PS0_128,
    S_AXIMM_PS1_128,
    S_AXIMM_PL0_512,
    S_AXIMM_PL1_512,
    S_AXIMM_PL2_512,
    S_AXIMM_PL3_512} s_axi_idx_t;

endpackage
