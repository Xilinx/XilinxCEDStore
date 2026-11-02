// tb_files.f - top-level TB + UVM test filelist (PL_STR mode).
// Paths are relative to the sim/ directory. RTL is not listed here; the
// Vivado-generated compile.sh handles DUT compilation.

+incdir+tb

// verif/ holds dut_inst.sv and nothing else. tb/tb_top.sv does
// `include "dut_inst.sv", so this MUST be on the include path.
+incdir+verif

// test/interfaces/ is reached by bare name from pkg.proj_test_pkg.sv, so the
// interfaces are NOT listed below - listing them would define each twice.
+incdir+test/interfaces

// When performing a Vivado sim, all relevant files from here
+incdir+tb/vivado_only

// Compile-time TB parameters. Must precede tb_top.sv.
test/pkg.test_param_pkg.sv

// Compile packages first, which will `include their files within
// There may be some package files that `include other packages
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
// test/ must precede tb/test so it shadows the empty stub there.
+incdir+test+tb/test+tb/test/env
tb/test/test_pkg.svh

# Common testbench files
tb/generic_pipe621_if.sv
// Bind modules (always present)
tb/bind.pipe_translate.sv

// Top level
tb/tb_top.sv
