// Bound INSIDE PSX VIP
`ifndef QEMU_PS
bind versal_cips_ps_vip_0  bind_ps_vip                           bind_ps_vip();
`endif
// Bound INSIDE CPM6
`ifdef PCIE_LINK_PIPE
bind SIP_CPM6              bind_pipe_translate                   bind_pipe_translate();
`endif
bind SIP_CPM6              bind_fast_sim                         bind_fast_sim();
bind SIP_CPM6              bind_cdo_load#(SIM_CPM_CDO_FILE_NAME) bind_cdo_load();
// Bound at CPM6 PL ports
bind CPM6                  bind_efuse                            bind_efuse();
bind CPM6                  bind_isr                              bind_isr();
bind CPM6                  bind_perstn                           bind_perstn();
bind CPM6                  bind_elbi                             bind_elbi();
bind CPM6                  bind_lpd_por_n                        bind_lpd_por_n();
bind CPM6                  bind_cxl#(CONTROLLER_0_CXL_MODE, 
                                     BOT_PL_MUX_MODE,
                                     CONTROLLER_1_CXL_MODE, 
                                     TOP_PL_MUX_MODE)            bind_cxl();
bind CPM6                  bind_cpm_pl_axi                       bind_cpm_pl_axi();
bind CPM6                  bind_cpm_noc_axi                      bind_cpm_noc_axi();
