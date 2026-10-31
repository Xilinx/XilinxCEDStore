// UVM verification agents (framework snapshot).
// base.F must come first - the others depend on it.
-F uvma_agents/base_agent/base.F
-F uvma_agents/reset_agent/reset.F
-F uvma_agents/gpmon_agent/gpmon.F
-F uvma_agents/gpdrv_agent/gpdrv.F
-F uvma_agents/elbi_agent/elbi.F
-F uvma_agents/aximon_agent/aximon.F
-F uvma_agents/cfg_ext_agent/cfg_ext.F
-F uvma_agents/cpi_agent/cpi.F
-F uvma_agents/msix_user_agent/msix_user.F
-F uvma_agents/cxl_credit_agent/cxl_credit.F
-F uvma_agents/cxl_nfi_agent/cxl_nfi.F
