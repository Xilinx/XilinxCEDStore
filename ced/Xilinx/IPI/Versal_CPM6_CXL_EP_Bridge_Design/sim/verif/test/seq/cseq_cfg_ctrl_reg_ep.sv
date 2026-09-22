// ===========================================================================
// cseq_cfg_ctrl_reg_ep.sv - Versal CPM6 CXL EP Bridge Design
//
// Programs this design's ctrl_reg_ep.v with the CXL-negotiated HDM base
// address, via EP_BASE_0_LO/HI (offsets 0x404/0x408). This is REQUIRED for
// this design specifically (unlike a single-PA CXL EP that can rely purely
// on the standard CXL DVSEC HDM decoder hardware): direct read of
// ctrl1/design_1_bd.tcl confirms ctrl_reg_ep_0's `cxl_mem_base0` output is
// wired to ALL FOUR PA hierarchies simultaneously
// (`connect_bd_net -net ctrl_reg_ep_0_cxl_mem_base0 [get_bd_pins
// ctrl_reg_ep_0/cxl_mem_base0] [get_bd_pins PA_0/cxl_mem0_base] [get_bd_pins
// PA_1/cxl_mem0_base] [get_bd_pins PA_2/cxl_mem0_base] [get_bd_pins
// PA_3/cxl_mem0_base]` - one shared net, `cxl_mem_base1` unused/unconnected
// anywhere in this BD) - i.e. every PA needs this CSR programmed with the
// actual negotiated HDM base before any of them can correctly decode
// CXL.mem traffic.
//
// Route: R5_API -> M_AXI_LPD -> LPD_AXI_PL -> smartconnect_0 ->
// ctrl_reg_ep.s_axil. CTRL_REG_EP_BASE (0x8000_0000) matches this design's
// own ctrl1/design_1_bd.tcl (`assign_bd_address -offset 0x80000000 ...
// [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs
// ctrl_reg_ep_0/s_axil/reg0]`). select_pl_datawidth(2'b00, "M_AXI_LPD") is
// required before any 32-bit R5_API access on this route - the PS VIP's
// internal BFM otherwise defaults to 128-bit. Register offsets (0x400/
// 0x404/0x408) match this design's own ../../../src/ctrl_reg_ep.v.
//
// Extends seq_base_ps_axi32 purely for its `p_sequencer`
// (`` `uvm_declare_p_sequencer(ps_vip_vsequencer)``) scaffolding so this can
// run on env.ps_vip_vsqr - its own axi_wr/axi_rd helpers (CPM6 config-space
// routes only) are NOT used here; this sequence's body() talks to
// ctrl_reg_ep directly via p_sequencer.ps_vip_api, same as the reference.
//
// env.ps_sem locking: the PS VIP's R5_API master port only supports one
// active destination route at a time - tb_env.sv also runs a background,
// independently-forked periodic PS-IRQ recheck task that routes R5_API to
// PS_CPM_CFG on its own timer, with no coordination with whatever route a
// test sequence currently holds. env.ps_sem is held across the
// M_AXI_LPD-routed section below to prevent that background task from
// switching routes while this sequence's route is still open, same
// env.ps_sem.get(1)/.put(1) bracketing pattern as test_ide_basic.sv.
// ===========================================================================
class cseq_cfg_ctrl_reg_ep extends seq_base_ps_axi32;
  `uvm_object_utils(cseq_cfg_ctrl_reg_ep)

  localparam bit [43:0] CTRL_REG_EP_BASE = 44'h8000_0000;
  localparam bit [11:0] EP_BASE_0_LO     = 12'h404;
  localparam bit [11:0] EP_BASE_0_HI     = 12'h408;

  // Set by the test before calling start()
  bit [63:0] hdm_base_addr;

  // Framework environment handle (for env.ps_sem)
  tb_env env;

  function new(string name = "cseq_cfg_ctrl_reg_ep");
    super.new(name);
  endfunction

  virtual task pre_body();
    super.pre_body();
    if (!uvm_config_db#(tb_env)::get(null, "base_sequence", "env", env))
      `uvm_fatal(get_name(), "Failed to get framework environment handle from config_db")
  endtask

  virtual task body();
    logic [1:0] bresp;

    env.ps_sem.get(1);

    // Clear any routing left active from other concurrently-running
    // sequences (PS VIP only allows one destination per source at a time).
    p_sequencer.ps_vip_api.set_routing_config(R5_API, PS_CPM_CFG,      1'b0);
    p_sequencer.ps_vip_api.set_routing_config(R5_API, PS_CPM_PCIE_AXI, 1'b0);

    // R5 -> M_AXI_LPD -> LPD_AXI_PL -> smartconnect_0 -> ctrl_reg_ep.s_axil
    p_sequencer.ps_vip_api.set_routing_config(R5_API, M_AXI_LPD, 1'b1);
    p_sequencer.ps_vip_api.select_pl_datawidth(2'b00, "M_AXI_LPD"); // 2'b00 = 32-bit

    p_sequencer.ps_vip_api.write_data_32(
      R5_API, CTRL_REG_EP_BASE + EP_BASE_0_LO, hdm_base_addr[31:0], bresp);
    `uvm_info(get_type_name(), $sformatf(
      "ctrl_reg_ep EP_BASE_0_LO [0x%h] = 0x%08h (bresp=%0b)",
      CTRL_REG_EP_BASE + EP_BASE_0_LO, hdm_base_addr[31:0], bresp), UVM_LOW)

    p_sequencer.ps_vip_api.write_data_32(
      R5_API, CTRL_REG_EP_BASE + EP_BASE_0_HI, hdm_base_addr[63:32], bresp);
    `uvm_info(get_type_name(), $sformatf(
      "ctrl_reg_ep EP_BASE_0_HI [0x%h] = 0x%08h (bresp=%0b)",
      CTRL_REG_EP_BASE + EP_BASE_0_HI, hdm_base_addr[63:32], bresp), UVM_LOW)

    p_sequencer.ps_vip_api.set_routing_config(R5_API, M_AXI_LPD, 1'b0);

    env.ps_sem.put(1);

    `uvm_info(get_type_name(), $sformatf(
      "Programmed ctrl_reg_ep cxl_mem_base0 (broadcast to PA_0..PA_3) = 0x%016h",
      hdm_base_addr), UVM_LOW)
  endtask

endclass
