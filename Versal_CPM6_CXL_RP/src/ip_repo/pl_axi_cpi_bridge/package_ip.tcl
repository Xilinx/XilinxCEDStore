##############################################################################
# package_ip.tcl
#
# Packages pl_axi_cpi_bridge as a standalone Vivado IP for use in an IP
# Integrator block design. The packaged top level is the pure-port wrapper
# rtl/pl_axi_cpi_bridge_ip.sv, which instantiates pl_axi_cpi_bridge and
# unrolls the CPI (cpi_req/cpi_data/cpi_rsp) and debug GPIO SystemVerilog
# interfaces it uses into flat vector ports (the IP Packager cannot expose
# custom SV interfaces on a packaged IP's boundary).
#
# Usage:
#   vivado -mode batch -source package_ip.tcl
#
# Re-running this script re-packages the IP in place. component.xml is
# regenerated from scratch each run (s_axi/s_axil are auto-detected as
# AXI4/AXI4-Lite interfaces during packaging -- no manual "Merge changes
# from File Sets" step needed), but xgui/<ip_name>_v1_0.tcl -- the hand-
# customized GUI layout (groups, static text, comboBox widgets, per-field
# validation, enablement dependencies) -- is preserved across re-runs; see
# the backup/restore step around ipx::create_xgui_files below.
##############################################################################

set script_dir [file normalize [file dirname [info script]]]
set part_name  xc2vp3602-vsvc3340-3HP-e-S
set ip_dir     $script_dir
set proj_dir   $script_dir/_pkg_proj
set ip_name    pl_axi_cpi_bridge
set top_module pl_axi_cpi_bridge_ip

# Dependency sources, in compile order: enum pkgs -> cpi pkg -> interfaces
# -> leaf modules -> DUT -> wrapper (packaged top)
set src_files [list \
  $script_dir/../../../../common/pkgs/pkg.cxl_tl_enum_pkg.sv \
  $script_dir/../../../../common/pkgs/pkg.cxl_ll_enum_pkg.sv \
  $script_dir/../../../../common/pkgs/pkg.cpi_pkg.sv \
  $script_dir/../../../../common/ifs/cpi_ifs.sv \
  $script_dir/../../rtl/debug_gpio_ifs.axi_cpi_bridge.sv \
  $script_dir/../../../../../common/lut_ram.sv \
  $script_dir/../../../../../common/bin2bcd_seq.sv \
  $script_dir/../../rtl/axi_cpi_bridge_reg_space.sv \
  $script_dir/../../rtl/pl_axi_cpi_bridge.sv \
  $script_dir/rtl/pl_axi_cpi_bridge_ip.sv \
]
set src_files [lmap f $src_files {file normalize $f}]

if {[file exists $proj_dir]} {
  file delete -force $proj_dir
}

create_project -force $ip_name $proj_dir -part $part_name

add_files -norecurse $src_files
set_property file_type SystemVerilog [get_files -of_objects [get_filesets sources_1]]
set_property top $top_module [current_fileset]
# Widen every CPI header (req/data/rsp) by IDE_ADDL=3+$clog2(CXL_ACTIVE_PORTS)
# bits (see cpi_pkg.sv) so this project's header widths (87/88/41) match the
# real CPM6 core's cpi_req/cpi_data/cpi_rsp bus interfaces exactly, enabling
# a direct interface connection to a real CPM6 instance in a block design.
# Scoped to this packaging project only -- cpi_pkg.sv, the DUT, and every
# other consumer (sim/, top_pl_bridge.sv OOC synth) compile separately and
# are unaffected. The DUT never references the portid/epochid/epochvalid
# fields this adds (it always does header='0 then assigns named sub-fields),
# so the extra bits are harmless, always-zero padding.
set_property verilog_define {CXL_IDE_EPOCH_SUPPORT CXL_ACTIVE_PORTS=2} [get_filesets sources_1]
update_compile_order -fileset sources_1

ipx::package_project -root_dir $ip_dir -vendor xilinx.com -library user \
  -taxonomy /UserIP -import_files -force
set_property name $ip_name [ipx::current_core]
set_property display_name $ip_name [ipx::current_core]
set_property description \
  "AXI-to-CPI bridge for a PL master reaching a CXL.mem Type 3 device directly (no NOC)." \
  [ipx::current_core]

# Clock/reset inference: ipx::package_project already auto-detects s_axi_aclk/
# s_axi_aresetn/s_axil_aclk/s_axil_aresetn from naming convention and wires up
# each clock's ASSOCIATED_RESET (visible in the log as "Added interface
# parameter 'ASSOCIATED_RESET'"). Re-asserting it explicitly here is
# redundant and harmless for the clocks, but reset interfaces have no
# ASSOCIATED_CLOCK bus parameter of their own to set, so that half is skipped.
ipx::infer_bus_interface s_axi_aclk  xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface s_axi_aresetn xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface s_axil_aclk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface s_axil_aresetn xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]

# DEBUG_IF_EN is presented as a None/GPIO/AXI-Lite/Both combo box (see
# xgui.tcl's -widget comboBox) while the underlying value stays the
# [1]=AXI-L,[0]=GPIO bit-encoded 0-3 the HDL expects. value_validation_pairs
# is what lets the displayed label differ from the stored value.
set debug_if_en_param \
  [ipx::get_user_parameters DEBUG_IF_EN -of_objects [ipx::current_core]]
set_property value_format long $debug_if_en_param
set_property value_validation_type pairs $debug_if_en_param
set_property value_validation_pairs {None 0 GPIO 1 AXI-Lite 2 Both 3} $debug_if_en_param

# USER_METAD_MODE is presented as a None/2 bit MetaData/Extended MetaData
# combo box; EMD_BITS (a plain integer parameter, validated 1-32 in
# xgui.tcl) supplies the actual width when Extended MetaData is selected.
set user_metad_mode_param \
  [ipx::get_user_parameters USER_METAD_MODE -of_objects [ipx::current_core]]
set_property value_format long $user_metad_mode_param
set_property value_validation_type pairs $user_metad_mode_param
set_property value_validation_pairs \
  {None 0 {2 bit MetaData} 1 {Extended MetaData} 2} $user_metad_mode_param

# Condense the CPI REQ/DATA/RSP channels into real CPM6 bus interfaces
# (xilinx.com:display_cpm6:cpi_req/cpi_data/cpi_rsp:1.0) instead of ~20 flat
# ports each. These are the exact bus/abstraction definitions the real CPM6
# core uses (shipped as part of Vivado's own IP catalog, in cpm6_v1_0's
# interfaces/ fileset -- no custom bus definitions or ip_repo_paths needed),
# so this IP can be wired directly to a real CPM6 instance's CPI ports via
# interface auto-connect in a block design. The header widths above
# (REQ/DAT/RSP_HDR_WIDTH = 87/88/41) were chosen to match these interfaces
# exactly.
proc add_cpi_bus_interface {name bus_name mode port_map} {
  set busif [ipx::add_bus_interface $name [ipx::current_core]]
  set_property abstraction_type_vlnv xilinx.com:display_cpm6:${bus_name}_rtl:1.0 $busif
  set_property bus_type_vlnv xilinx.com:display_cpm6:${bus_name}:1.0 $busif
  set_property interface_mode $mode $busif
  foreach {logical physical} $port_map {
    set pm [ipx::add_port_map $logical $busif]
    set_property physical_name $physical $pm
  }
}

add_cpi_bus_interface f2a_req cpi_req master {
  is_valid            f2a_req_is_valid
  early_valid         f2a_req_early_valid
  shared_credit       f2a_req_shared_credit
  cmd_parity          f2a_req_cmd_parity
  txblock_crd_flow    f2a_req_txblock_crd_flow
  protocol_id         f2a_req_protocol_id
  vc_id               f2a_req_vc_id
  header              f2a_req_header
  spid                f2a_req_spid
  dpid                f2a_req_dpid
  block               f2a_req_block
  rxcrd_valid         f2a_req_rxcrd_valid
  rxcrd_shared        f2a_req_rxcrd_shared
  rxcrd_protocol_id   f2a_req_rxcrd_protocol_id
  rxcrd_vc_id         f2a_req_rxcrd_vc_id
}

add_cpi_bus_interface f2a_dat cpi_data master {
  is_valid            f2a_dat_is_valid
  early_valid         f2a_dat_early_valid
  shared_credit       f2a_dat_shared_credit
  sz                  f2a_dat_sz
  byte_enable_parity  f2a_dat_byte_enable_parity
  poison              f2a_dat_poison
  eop                 f2a_dat_eop
  cmd_parity          f2a_dat_cmd_parity
  txblock_crd_flow    f2a_dat_txblock_crd_flow
  protocol_id         f2a_dat_protocol_id
  vc_id               f2a_dat_vc_id
  header              f2a_dat_header
  spid                f2a_dat_spid
  dpid                f2a_dat_dpid
  body                f2a_dat_body
  byte_enable         f2a_dat_byte_enable
  parity              f2a_dat_parity
  data_emd            f2a_dat_emd
  block               f2a_dat_block
  rxcrd_valid         f2a_dat_rxcrd_valid
  rxcrd_shared        f2a_dat_rxcrd_shared
  rxcrd_protocol_id   f2a_dat_rxcrd_protocol_id
  rxcrd_vc_id         f2a_dat_rxcrd_vc_id
}

add_cpi_bus_interface a2f_rsp cpi_rsp slave {
  is_valid            a2f_rsp_is_valid
  early_valid         a2f_rsp_early_valid
  shared_credit       a2f_rsp_shared_credit
  cmd_parity          a2f_rsp_cmd_parity
  txblock_crd_flow    a2f_rsp_txblock_crd_flow
  protocol_id         a2f_rsp_protocol_id
  vc_id               a2f_rsp_vc_id
  header              a2f_rsp_header
  spid                a2f_rsp_spid
  dpid                a2f_rsp_dpid
  block               a2f_rsp_block
  rxcrd_valid         a2f_rsp_rxcrd_valid
  rxcrd_shared        a2f_rsp_rxcrd_shared
  rxcrd_protocol_id   a2f_rsp_rxcrd_protocol_id
  rxcrd_vc_id         a2f_rsp_rxcrd_vc_id
}

add_cpi_bus_interface a2f_dat cpi_data slave {
  is_valid            a2f_dat_is_valid
  early_valid         a2f_dat_early_valid
  shared_credit       a2f_dat_shared_credit
  sz                  a2f_dat_sz
  byte_enable_parity  a2f_dat_byte_enable_parity
  poison              a2f_dat_poison
  eop                 a2f_dat_eop
  cmd_parity          a2f_dat_cmd_parity
  txblock_crd_flow    a2f_dat_txblock_crd_flow
  protocol_id         a2f_dat_protocol_id
  vc_id               a2f_dat_vc_id
  header              a2f_dat_header
  spid                a2f_dat_spid
  dpid                a2f_dat_dpid
  body                a2f_dat_body
  byte_enable         a2f_dat_byte_enable
  parity              a2f_dat_parity
  data_emd            a2f_dat_emd
  block               a2f_dat_block
  rxcrd_valid         a2f_dat_rxcrd_valid
  rxcrd_shared        a2f_dat_rxcrd_shared
  rxcrd_protocol_id   a2f_dat_rxcrd_protocol_id
  rxcrd_vc_id         a2f_dat_rxcrd_vc_id
}

# Hide the debug sub-interfaces from the packaged IP's symbol entirely
# unless the matching half of Debug Interface Enable is selected, mirroring
# what the DUT does internally (the AXI-Lite debug register space is only
# instantiated under a "DEBUG_IF_EN[1]" generate guard; the dbg_gpio_if
# counters only update under DEBUG_IF_EN[0]; the *_bcd counters additionally
# require DEBUG_EN_BCD). enablement_dependency is applied to both each
# individual port and every bus interface wrapping one (the auto-detected
# s_axil AXI4-Lite interface itself, plus s_axil_aclk/aresetn and
# dbg_gpio_cnt_reset), so every representation of the signal -- including
# the interface pin drawn on the packaged IP's block design symbol -- is
# hidden consistently.
proc set_enablement {names expr core} {
  foreach name $names {
    set port [ipx::get_ports $name -of_objects $core]
    if {$port ne ""} { set_property enablement_dependency $expr $port }
    set busif [ipx::get_bus_interfaces $name -of_objects $core]
    if {$busif ne ""} { set_property enablement_dependency $expr $busif }
  }
}

set axil_expr {DEBUG_IF_EN == 2 || DEBUG_IF_EN == 3}
set_enablement {
  s_axil
  s_axil_aclk    s_axil_aresetn
  s_axil_awvalid s_axil_awready s_axil_awaddr s_axil_awprot
  s_axil_wvalid  s_axil_wready  s_axil_wdata   s_axil_wstrb
  s_axil_bvalid  s_axil_bready  s_axil_bresp
  s_axil_arvalid s_axil_arready s_axil_araddr  s_axil_arprot
  s_axil_rvalid  s_axil_rready  s_axil_rresp   s_axil_rdata
} $axil_expr [ipx::current_core]

set gpio_expr {DEBUG_IF_EN == 1 || DEBUG_IF_EN == 3}
set_enablement {
  dbg_gpio_cnt_reset dbg_gpio_cnt_enable dbg_gpio_cnt_freerun
  dbg_gpio_axi_wr_start_cnt dbg_gpio_axi_wr_compl_cnt
  dbg_gpio_axi_rd_start_cnt dbg_gpio_axi_rd_compl_cnt
  dbg_gpio_f2a_req_cnt      dbg_gpio_f2a_dat_cnt
  dbg_gpio_a2f_rsp_cnt      dbg_gpio_a2f_dat_cnt
  dbg_gpio_f2a_dat_emd_cnt  dbg_gpio_a2f_dat_emd_cnt
} $gpio_expr [ipx::current_core]

set gpio_bcd_expr {(DEBUG_IF_EN == 1 || DEBUG_IF_EN == 3) && DEBUG_EN_BCD}
set_enablement {
  dbg_gpio_axi_wr_start_bcd dbg_gpio_axi_wr_compl_bcd
  dbg_gpio_axi_rd_start_bcd dbg_gpio_axi_rd_compl_bcd
  dbg_gpio_f2a_req_bcd      dbg_gpio_f2a_dat_bcd
  dbg_gpio_a2f_rsp_bcd      dbg_gpio_a2f_dat_bcd
  dbg_gpio_f2a_dat_emd_bcd  dbg_gpio_a2f_dat_emd_bcd
} $gpio_bcd_expr [ipx::current_core]

# ipx::create_xgui_files always overwrites xgui/<ip_name>_v1_0.tcl with a
# fresh, default-layout script, which would discard every hand-made GUI
# customization (groups, static text, comboBox/checkBox widgets, per-field
# validation, enablement dependencies like EMD_BITS graying out). Back the
# existing file up and restore it afterward so re-running this script
# reproduces the current, hand-tuned GUI exactly; a brand-new checkout with
# no xgui.tcl yet still gets a sensible auto-generated default.
set xgui_file "$ip_dir/xgui/${ip_name}_v1_0.tcl"
set xgui_backup ""
if {[file exists $xgui_file]} {
  set fh [open $xgui_file r]
  set xgui_backup [read $fh]
  close $fh
}

ipx::create_xgui_files [ipx::current_core]

if {$xgui_backup ne ""} {
  set fh [open $xgui_file w]
  puts -nonewline $fh $xgui_backup
  close $fh
  puts "INFO: Restored hand-customized $xgui_file (ipx::create_xgui_files would have reset it to its default layout)"
}

ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

close_project
puts "INFO: $ip_name packaged in $ip_dir (component.xml/xgui updated)"
