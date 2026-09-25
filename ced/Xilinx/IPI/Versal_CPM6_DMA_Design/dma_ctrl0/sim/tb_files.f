// ============================================================
// tb_files.f - File list for top-level TB + UVM tests
// All paths are relative to sim/ directory
// NOTE: RTL files are NOT listed here — compile.sh from the
//       Vivado project handles RTL compilation automatically
// ============================================================

// ============================================================
// FRAMEWORK - Include paths and packages
// ============================================================
+incdir+tb  
+incdir+tb/vivado_only
+incdir+tb/env/seq/axi_mst/cxl_mbox
tb/env/seq/axi_mst/cxl_mbox/cxl_mbox_pkg.svh
+incdir+tb/env/pcie_cfg
tb/env/pcie_cfg/pcie_cfg_pkg.svh
+incdir+tb/env/shim+tb/env/shim/seq+tb/env/shim/caps+tb/env/shim/ecaps
tb/env/shim/shim_register_pkg.svh
tb/env/shim/caps/shim_caps_pkg.svh
tb/env/shim/ecaps/shim_ecaps_pkg.svh
tb/env/shim/shim_enum_pkg.svh
tb/env/shim/shim_device_pkg.svh
+incdir+tb/env/seq/axi_mst
tb/env/seq/axi_mst/axi_mst_seq_pkg.svh
tb/env/shim/shim_pkg.svh
+incdir+tb/env
tb/env/env_pkg.svh
tb/test/other/socket_dpi_pkg.sv
+incdir+test+tb/test+tb/test/env
tb/test/test_pkg.svh

// ============================================================
// Project-specific test package
// NOTE: pkg.proj_test_pkg.sv is NOT listed here -- tb_top.sv
// already `includes it. +incdir+test lets tb_top.sv find it.
// No DMA-specific test package exists yet, so this resolves to
// the empty tb/test/pkg.proj_test_pkg.sv stub (see reference/
// bmd_test_example/ for the BMD test package this design was
// originally bootstrapped from -- it no longer applies to DMA).
// +incdir+test/interfaces lets a future pkg.proj_test_pkg.sv find
// any project-specific interface files.
// ============================================================
+incdir+test/interfaces

// ============================================================
// DUT Instance (connects DUT ports to testbench)
// NOTE: dut_inst.sv is `included inside tb_top.sv
+incdir+verif

// ============================================================
// Framework common interface
// ============================================================
tb/generic_pipe621_if.sv

// ============================================================
// Bind modules
// ============================================================
tb/bind.pipe_translate.sv
tb/bind.fast_sim.sv

// ============================================================
// Top level testbench
// ============================================================
tb/tb_top.sv
