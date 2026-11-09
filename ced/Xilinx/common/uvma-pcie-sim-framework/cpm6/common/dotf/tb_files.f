// When performing an RTL sim, all relevant files from here
+incdir+../rtl_only
// When performing a Vivado sim, all relevant files from here
+incdir+../vivado_only
// for print_framework_repo_info.sv
+incdir+../../../sim_common
+incdir+../tb

// Compile packages first, which will `include their files within
// There may be some package files that `include other packages
+incdir+../env/seq/axi_mst/cxl_mbox
../env/seq/axi_mst/cxl_mbox/cxl_mbox_pkg.svh
+incdir+../env/pcie_cfg
../env/pcie_cfg/pcie_cfg_pkg.svh
+incdir+../env/shim+../env/shim/seq+../env/shim/caps+../env/shim/ecaps
../env/shim/shim_register_pkg.svh
../env/shim/caps/shim_caps_pkg.svh
../env/shim/ecaps/shim_ecaps_pkg.svh
../env/shim/shim_enum_pkg.svh
../env/shim/shim_device_pkg.svh
+incdir+../env/seq/axi_mst
../env/seq/axi_mst/axi_mst_seq_pkg.svh
../env/shim/shim_pkg.svh
+incdir+../env
../env/env_pkg.svh
../test/other/socket_dpi_pkg.sv
+incdir+../test+../test/env
../test/test_pkg.svh

# VIP-specific
+incdir+../../avery
+incdir+../../synopsys

# Framework common
../../../common/generic_pipe621_if.sv
// Bind modules (always present)
../tb/bind.pipe_translate.sv
// Top level
+incdir+$VERSION_PRINT_PATH
../tb/tb_top.sv

