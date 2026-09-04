##############################################################################
# custom_axi_tg_cdc.xdc
#
# CDC constraints for the AXI4-Lite (s_axil_aclk) <-> AXI master (m_axi_aclk)
# clock domain crossing implemented in custom_axi_tg_reg_space.sv.  Every
# crossing uses a synchronized req/ack handshake:
#   - Single-bit req/ack toggles are synchronized through ASYNC_REG-marked
#     flop chains (a2d_*_sync_0/1[/2]).
#   - The address/data/response buses are quasi-static: written once per
#     transaction and held constant for the full multi-cycle handshake, so
#     they are qualified by the synchronized req/ack, not by clock timing.
# None of these paths should be analyzed against the opposite clock's period.
#
# Scope this file to the custom_axi_tg_reg_space module reference so it
# re-anchors to wherever the instance ends up:
#
#   add_files -fileset constrs_1 -norecurse constr/custom_axi_tg_cdc.xdc
#   set_property SCOPED_TO_REF custom_axi_tg_reg_space \
#                              [get_files custom_axi_tg_cdc.xdc]
#   set_property USED_IN       {synthesis implementation} \
#                              [get_files custom_axi_tg_cdc.xdc]
#
# IMPORTANT - XDC IS NOT FULL TCL.  Vivado parses a constraint file with a
# restricted command set: proc, if and other control flow are rejected with
# "Command '<x>' is not supported in the xdc constraint file", and every
# command after the failure is skipped, which silently leaves the design
# completely unconstrained.  Everything below therefore uses only plain
# commands plus -quiet.
#
# ORDERING MATTERS.  The set_max_delay commands below take their bound from
# get_clocks, so this file must be processed AFTER the consuming design has
# created its clocks.  If it runs first, the period lookup returns empty and
# -quiet silently drops those commands - the crossing keeps its false_paths but
# loses its datapath bounds, with no warning.  The packaged IP sets
# PROCESSING_ORDER LATE on this file for exactly that reason; preserve it if you
# add the file to a project by hand.
#
# When AXI_AXIL_SYNC == 1 the synchronizer generate block does not exist, so
# every get_cells lookup returns an empty collection and -quiet turns each
# command into a no-op.  That is the correct behaviour: the two clock pins are
# then driven from the same net and there is no crossing to constrain.  The
# synchronizer flops live inside a generate block, so the lookups use
# -hierarchical -filter rather than a flat get_cells.
##############################################################################

set rreq_sync_0 [get_cells -quiet -hierarchical -filter {NAME =~ *a2d_rreq_sync_0_reg*}]
set rack_sync_0 [get_cells -quiet -hierarchical -filter {NAME =~ *a2d_rack_sync_0_reg*}]
set wreq_sync_0 [get_cells -quiet -hierarchical -filter {NAME =~ *a2d_wreq_sync_0_reg*}]
set wack_sync_0 [get_cells -quiet -hierarchical -filter {NAME =~ *a2d_wack_sync_0_reg*}]

# -----------------------------------------------------------------------------
# 1. Single-bit request/acknowledge synchronizer chains.
#    False-path the destination-side D input of the first synchronizer stage;
#    only the metastability settling of that flop matters, not a delay-vs-clock
#    relationship.
# -----------------------------------------------------------------------------
set_false_path -quiet -to $rreq_sync_0
set_false_path -quiet -to $rack_sync_0
set_false_path -quiet -to $wreq_sync_0
set_false_path -quiet -to $wack_sync_0

# -----------------------------------------------------------------------------
# 2. Quasi-static buses qualified by the handshakes above.  They are written in
#    one domain and only sampled in the other after the req/ack handshake has
#    declared them stable, so only the datapath delay needs bounding.
#
#    The period references are taken from the synchronizer flops themselves, so
#    this file tracks whatever clocks are actually constrained upstream instead
#    of hardcoding a frequency.  Both resolve to an empty string when the
#    generate block is absent, which is harmless because the -from/-to
#    collections are empty in exactly the same case and -quiet drops the
#    command.
# -----------------------------------------------------------------------------
set dest_clk_period [get_property -quiet PERIOD [get_clocks -quiet -of_objects $rreq_sync_0]]
set axil_clk_period [get_property -quiet PERIOD [get_clocks -quiet -of_objects $rack_sync_0]]

# s_axil_aclk -> m_axi_aclk
set_max_delay -quiet -datapath_only $dest_clk_period \
  -from [get_cells -quiet -hierarchical -filter {NAME =~ *captured_araddr_a_reg*}] \
  -to   [get_cells -quiet -hierarchical -filter {NAME =~ *captured_araddr_d_reg*}]
set_max_delay -quiet -datapath_only $dest_clk_period \
  -from [get_cells -quiet -hierarchical -filter {NAME =~ *captured_awaddr_a_reg*}] \
  -to   [get_cells -quiet -hierarchical -filter {NAME =~ *captured_awaddr_d_reg*}]
set_max_delay -quiet -datapath_only $dest_clk_period \
  -from [get_cells -quiet -hierarchical -filter {NAME =~ *captured_wdata_a_reg*}] \
  -to   [get_cells -quiet -hierarchical -filter {NAME =~ *captured_wdata_d_reg*}]
set_max_delay -quiet -datapath_only $dest_clk_period \
  -from [get_cells -quiet -hierarchical -filter {NAME =~ *captured_wstrb_a_reg*}] \
  -to   [get_cells -quiet -hierarchical -filter {NAME =~ *captured_wstrb_d_reg*}]

# m_axi_aclk -> s_axil_aclk
set_max_delay -quiet -datapath_only $axil_clk_period \
  -from [get_cells -quiet -hierarchical -filter {NAME =~ *capture_rdata_reg*}] \
  -to   [get_cells -quiet -hierarchical -filter {NAME =~ *s_axil_rdata_reg*}]
set_max_delay -quiet -datapath_only $axil_clk_period \
  -from [get_cells -quiet -hierarchical -filter {NAME =~ *capture_rresp_reg*}] \
  -to   [get_cells -quiet -hierarchical -filter {NAME =~ *s_axil_rresp_reg*}]
set_max_delay -quiet -datapath_only $axil_clk_period \
  -from [get_cells -quiet -hierarchical -filter {NAME =~ *capture_bresp_reg*}] \
  -to   [get_cells -quiet -hierarchical -filter {NAME =~ *s_axil_bresp_reg*}]
