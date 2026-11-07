// ===========================================================================
// cseq_cfg_ctrl_reg_ep.sv - Versal CPM6 CXL EP Bridge Design
//
// Programs ctrl_reg_ep.v with the CXL-negotiated HDM base address via
// EP_BASE_0_LO/HI (offsets 0x404/0x408). Required for this design: the
// ctrl0_cpi/ and ctrl1_cpi/ design_1_bd.tcl wire ctrl_reg_ep_0's
// cxl_mem_base0 output to all four PA hierarchies (PA_0..PA_3), so every PA
// decodes CXL.mem against this CSR-broadcast base.
//
// Route: R5_API -> M_AXI_LPD -> LPD_AXI_PL -> smartconnect_0 ->
// ctrl_reg_ep.s_axil. CTRL_REG_EP_BASE (0x8000_0000) is the ctrl_reg_ep_0
// address assignment in both design_1_bd.tcl files; register offsets match
// src/ctrl_reg_ep.v. select_pl_datawidth(2'b00, "M_AXI_LPD") is required
// before any 32-bit R5_API access on this route (the PS VIP's internal BFM
// otherwise defaults to 128-bit).
//
// Extends seq_base_ps_axi32 only for its p_sequencer scaffolding, so this
// runs on env.ps_vip_vsqr; body() talks to ctrl_reg_ep directly via
// p_sequencer.ps_vip_api.
//
// env.ps_sem is held across the M_AXI_LPD-routed section: the PS VIP's R5_API
// master port supports one active destination route at a time, and tb_env.sv
// forks a background PS-IRQ recheck task that routes R5_API to PS_CPM_CFG on
// its own timer.
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
