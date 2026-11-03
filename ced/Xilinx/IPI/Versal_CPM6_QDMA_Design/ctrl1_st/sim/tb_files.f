// ============================================================
// tb_files.f - File list for top-level TB + UVM tests (streaming)
// All paths are relative to sim/ directory
// NOTE: RTL files are NOT listed here — compile.sh from the
//       Vivado project handles RTL compilation automatically
//
// The tb/env/* includes below are the shared, IP-agnostic PCIe/CXL UVM
// environment and are reused as-is.
//
// tb/test/ holds the generic UVM test framework chain
// (test_base/test_init/test_enum/base_ep_test); sim/verif/test/ holds this
// design's QDMA-specific content (params, dma_req_processor, qdma_mem_callback,
// qdma_base_test with the driver-sequence engine, and the streaming test).
//
// +incdir+verif/test must appear BEFORE +incdir+tb/test so tb_top.sv's
// `include "pkg.proj_test_pkg.sv"` resolves to the QDMA one in
// sim/verif/test/.
// ============================================================

// ============================================================
// Block design names used by the BD-level monitors and binds
// (see verif/qdma_bd_names.svh)
// ============================================================
+define+CPM6_BD_TOP_MODULE=cpm6_qdma
+define+CPM6_BD_TOP_WRAPPER=ctrl1_qdma_st_ep
+define+CPM6_BD_TOP_SIM_WRAPPER=ctrl1_qdma_st_ep_sim_wrapper
+define+CPM6_BD_PERIPH_RESETN=axi_rst_n

// ============================================================
// FRAMEWORK - Include paths and packages
// ============================================================
+incdir+tb
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

// ============================================================
// Generic UVM test framework
// ============================================================
+incdir+verif/test
+incdir+tb/test+tb/test/seq+tb/test/other
tb/test/other/socket_dpi_pkg.sv
tb/test/test_pkg.svh

// ============================================================
// QDMA params package -- standalone package, compiled ahead of
// proj_test_pkg.sv since a `package` cannot be `included inside another.
// QDMA_DMA_ST=1 / QDMA_DMA_MM=0 (Makefile CDEF) select the streaming values.
// ============================================================
+incdir+verif/test/params
verif/test/params/pkg.cpm6_qdma_params.sv

// dsc_slot_params_pkg -- descriptor-slot geometry constants. Must precede
// pkg.pswizard_agent.sv, which imports it for the cpm_noc0 channel decode.
verif/test/params/pkg.dsc_slot_params.sv

// ============================================================
// Agent packages. Each must be compiled before tb/tb_top.sv, since
// pkg.proj_test_pkg.sv (included by tb_top.sv) imports them.
// ============================================================
// axi_pl_agent -- AXI-PL port monitors (cpm_axi_pl0..3) at the BD scope.
// axi_if is an interface, compiled at file scope ahead of the package.
+incdir+verif/axi_pl_agent
verif/axi_pl_agent/axi_if.sv
verif/axi_pl_agent/pkg.axi_pl_agent.sv

// pswizard_agent -- passive monitor on ps_wizard_0's NOC AXI + DMA IRQ
// signals at the BD top-level scope.
+incdir+verif/pswizard_agent
verif/pswizard_agent/pkg.pswizard_agent.sv

// qdma_periph_agent -- passive monitor on s_axi_mem/s_axi_reg/m_axil_dbi/msix
// at the cpm6_qdma BD wrapper scope.
+incdir+verif/qdma_periph_agent
verif/qdma_periph_agent/pkg.qdma_periph_agent.sv

// qdma_user_agent -- H2C/C2H stream user-port monitor and scoreboard
// (qdma_user_if is compiled at file scope inside the package file).
verif/test/pkg.qdma_user_agent.sv

// dsc_crdt_agent -- drives C2H descriptor credits on dsc_crdt_in
// (Makefile CDEF USE_DSC_CRDT).
+incdir+verif/dsc_crdt_agent
verif/dsc_crdt_agent/pkg.dsc_crdt_agent.sv

// ============================================================
// QDMA UVM test package
// NOTE: pkg.proj_test_pkg.sv is NOT listed here -- tb_top.sv already
// `includes it, found through +incdir+verif/test above.
// ============================================================

// ============================================================
// DUT Instance (connects DUT ports to testbench)
// NOTE: dut_inst.sv is `included inside tb_top.sv
// ============================================================
+incdir+verif

// ============================================================
// Framework common interface
// ============================================================
tb/generic_pipe621_if.sv

// ============================================================
// Bind modules
// ============================================================
tb/bind.pipe_translate.sv
verif/axi_pl_agent/bind.axi_pl.sv
verif/pswizard_agent/bind.pswizard.sv
// QDMA_PERIPH_AXI_BIND connects bind.qdma_periph.sv's s_axi_mem/s_axi_reg/
// m_axil_dbi fields to the BD wires; without it they tie to 0.
+define+QDMA_PERIPH_AXI_BIND
verif/qdma_periph_agent/bind.qdma_periph.sv
// qdma_boundary_probe -- cpm6_qdma_0 interface-boundary log (single file).
verif/qdma_boundary_probe/bind.qdma_boundary_probe.sv
// Streaming user ports (H2C/C2H stream and completion ports at the BD boundary)
verif/bind.qdma_user_st.sv
// Descriptor credits into cpm6_qdma_0 dsc_crdt_in
verif/dsc_crdt_agent/bind.dsc_crdt.sv
// Example-design C2H source observer (Makefile CDEF C2H_SRC_MON)
verif/c2h_src_agent/bind.c2h_src.sv

// ============================================================
// Top level testbench
// ============================================================
tb/tb_top.sv
