# =============================================================================
# custom_axi_tg_start_cdc.xdc
#
# Constraint for the external start pin, which is asynchronous to everything and
# is edge-detected behind a 2FF metastability synchroniser in the m_axi_aclk
# domain.  The user must hold i_start high for at least two m_axi_aclk periods.
#
# This file is scoped to the TOP of the IP, not to the reg_space:
#   add_files -fileset constrs_1 -norecurse constr/custom_axi_tg_start_cdc.xdc
#   set_property SCOPED_TO_REF   custom_axi_tg \
#                                [get_files custom_axi_tg_start_cdc.xdc]
#   set_property USED_IN         {synthesis implementation} \
#                                [get_files custom_axi_tg_start_cdc.xdc]
#
# IMPORTANT - XDC IS NOT FULL TCL.  Vivado's constraint parser accepts only a
# restricted command set: proc, if and other control flow are rejected with
# "Command '<x>' is not supported in the xdc constraint file", and every command
# after the failure is skipped, silently leaving the crossing unconstrained.
# The lookup below therefore relies on -quiet rather than guarding with if - an
# empty collection makes the command a no-op instead of an error.
# =============================================================================

set_false_path -quiet \
  -to [get_cells -quiet -hierarchical -filter {NAME =~ *start_ext_sync_0_reg*}]
