package shim_ecaps_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import shim_register_pkg::*;

  // PCIe Extended Capability Structures
  typedef enum bit [15:0] {
    //'h0-'hF
    ECAP_NULL,       ECAP_AER,         ECAP_VC_N_MFVC,      ECAP_DSN, 
    ECAP_PWR_BDGT,   ECAP_RC_LNK_DECL, ECAP_RC_INT_LNK_CTL, ECAP_RCEC_EA,    
    ECAP_MFVC,       ECAP_VC_Y_MFVC,   ECAP_RCRB_HDR,       ECAP_VENDOR,
    ECAP_DEPRECATED, ECAP_ACS,         ECAP_ARI,            ECAP_ATS,
    //'h10-'h1F
    ECAP_SRIOV, ECAP_MRIOV,   ECAP_MCAST, ECAP_PRI,      ECAP_AMD_RSVD, ECAP_RSZ_BAR, 
    ECAP_DPA,   ECAP_TPH_REQ, ECAP_LTR,   ECAP_SEC_PCIE, ECAP_PMUX,
    ECAP_PASID, ECAP_LN_REQ,  ECAP_DPC,   ECAP_L1_PM_SS, ECAP_PTM,
    //'h20-'h2F
    ECAP_MPHY_PCIE, ECAP_FRS_Q,    ECAP_RTR,     ECAP_DVSEC,    ECAP_VF_RSZ_BAR, 
    ECAP_DL_FEAT,   ECAP_PL_16GTS, ECAP_LN_MRGN, ECAP_HIER_ID,  ECAP_NPEM,
    ECAP_PL_32GTS,  ECAP_ALT_PROT, ECAP_SFI,     ECAP_DOE='h2E, ECAP_DEV3,
    //'h30-'h3F
    ECAP_IDE,          ECAP_PL_64GTS, ECAP_FLIT_LOG, ECAP_FLIT_PERF_MEAS, 
    ECAP_FLIT_ERR_INJ, ECAP_STRMLN_VC
  } pcie_ecapid_e;

  typedef struct packed {
    logic [11:0] next_cap_offset;
    logic [ 3:0] cap_version;
    logic [15:0] cap_id;
  } ecap_hdr_s;

  // Base object
  import shim_caps_pkg::cap_foundation;
  `include "ecap_base.sv"
  // Extended Capability objects
  `include "ecap_doe.sv"
  `include "ecap_ide.sv"
  `include "ecap_pl_64gts.sv"

endpackage
