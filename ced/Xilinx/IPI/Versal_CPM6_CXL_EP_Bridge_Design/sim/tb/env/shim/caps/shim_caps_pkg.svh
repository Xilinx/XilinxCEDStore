package shim_caps_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import shim_register_pkg::*;

  // PCIe Capability Structures
  typedef enum bit [7:0] {
    //'h0-'hF
    CAP_NULL,     CAP_PCI_PM, CAP_AGP,    CAP_VPD,     CAP_SLOT_ID,  CAP_MSI, 
    CAP_HOT_SWAP, CAP_PCIX,   CAP_HYPERT, CAP_VENDOR,  CAP_DBG_PORT, CAP_CRC,
    CAP_HOT_PLUG, CAP_SS_ID,  CAP_AGP8X,  CAP_SEC_DEV, 
    //'h10-'h15
    CAP_PCI_EXP, CAP_MSI_X, CAP_SATA_CFG, CAP_ADV_FEAT, CAP_EALLOC, CAP_FPB
  } pcie_capid_e;

  // Base object
  `include "cap_foundation.sv"
  `include "cap_base.sv"
  // Capability objects
  `include "cap_pci_pm.sv"

endpackage
