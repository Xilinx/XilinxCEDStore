### Compiles all agents contained here

# Base Agent classes
-F base_agent/base.F

# General Purpose Monitor Agent classes
-F gpmon_agent/gpmon.F

# General Purpose Driver agent classes
-F gpdrv_agent/gpdrv.F

# Reset Agent classes
-F reset_agent/reset.F

# [CPM6] CXL NFI (Native Flit Interface) classes (CXL Link Layer)
-F cxl_nfi_agent/cxl_nfi.F

# [CPM6] CXL Credit Agent classes (CXL credit return)
-F cxl_credit_agent/cxl_credit.F

# [CPM6] ELBI Agent classes
-F elbi_agent/elbi.F

# [CPM6] MSIX User Agent classes
-F msix_user_agent/msix_user.F

# Config Extended agent classes (PCIe CfgWr/CfgRd TLP passthrough)
-F cfg_ext_agent/cfg_ext.F

# CPI Agent (CXL.cachemem Protocol Interface)
-F cpi_agent/cpi.F
