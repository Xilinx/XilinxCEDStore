// Binds bind_axi_tg_override (byoc_ext_insert.sv) into each CXL datapath's
// AXI traffic generator core so that users can run a simulation and have an
// extremely customizable AXI traffic generator that far exceeds the
// capability of the actual one in the hardware design.
//
// This file is `included inside tb_top next to cpm6_vivado_binds.sv, so the
// DUT paths below are relative to that scope.
//
// custom_axi_tg_ip is shared by every datapath, so each bind targets one
// instance and gives it a distinct INST_ID. Only the datapaths that were
// generated may be bound, so each one is enabled with its own define:
//   CPI_INST_0, CPI_INST_1, CPI_INST_2, CPI_INST_3

`ifdef CPI_INST_0
bind DUT.Versal_CPM6_CXL_RP_i.cxl_datapath_0.custom_axi_tg_0.inst
  bind_axi_tg_override #(.INST_ID(0)) bind_axi_tg_override_0 (
    .aclk (m_axi_aclk   ),
    .arstn(m_axi_aresetn)
  );
`endif

`ifdef CPI_INST_1
bind DUT.Versal_CPM6_CXL_RP_i.cxl_datapath_1.custom_axi_tg_1.inst
  bind_axi_tg_override #(.INST_ID(1)) bind_axi_tg_override_1 (
    .aclk (m_axi_aclk   ),
    .arstn(m_axi_aresetn)
  );
`endif

`ifdef CPI_INST_2
bind DUT.Versal_CPM6_CXL_RP_i.cxl_datapath_2.custom_axi_tg_2.inst
  bind_axi_tg_override #(.INST_ID(2)) bind_axi_tg_override_2 (
    .aclk (m_axi_aclk   ),
    .arstn(m_axi_aresetn)
  );
`endif

`ifdef CPI_INST_3
bind DUT.Versal_CPM6_CXL_RP_i.cxl_datapath_3.custom_axi_tg_3.inst
  bind_axi_tg_override #(.INST_ID(3)) bind_axi_tg_override_3 (
    .aclk (m_axi_aclk   ),
    .arstn(m_axi_aresetn)
  );
`endif
