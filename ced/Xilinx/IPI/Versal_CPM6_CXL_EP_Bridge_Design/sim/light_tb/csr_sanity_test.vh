// ===========================================================================
// csr_sanity_test.vh - `include`-d from board.sv's initial block, after the
// `ps_vip_api` virtual interface has been fetched from config_db and the
// bind_ps_vip reset/clock sequence has been given time to settle.
//
// Uses the ps_vip_api_if API (../tb/ps_vip_api_pkg.svh - copied verbatim
// from BMD) exactly the way base_cxl_ep_test.sv's cdo_write()/
// cdo_mask_write() tasks do (see ../tb/test/base_cxl_ep_test.sv lines
// ~204-230): set_routing_config(...,1) -> write/read_data_32 ->
// set_routing_config(...,0).
//
// Register offsets:
//   0x000/0x004  SCRATCH_LO/HI          (RW)
//   0x400        EP_CTRL_STS            (RO, mirrors `ep_status` input -
//                                         UNCONNECTED in this BD (open
//                                         item), so expect a read-back of 0)
//
// ROUTING/ADDRESS/DATAWIDTH:
//   - Route is M_AXI_LPD (NOT PS_CPM_CFG - that is the CPM6 PCIe config/ELBI
//     path, a different physical route than this LPD_AXI_PL-routed CSR
//     block).
//   - Every address must be offset by CTRL_REG_EP_BASE (0x8000_0000) - this
//     design's own ctrl1/design_1_bd.tcl assigns ctrl_reg_ep_0 at this
//     exact offset (`assign_bd_address -offset 0x80000000 ... -target_
//     address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0]
//     [get_bd_addr_segs ctrl_reg_ep_0/s_axil/reg0]`).
//   - select_pl_datawidth(2'b00, "M_AXI_LPD") must be called before any
//     32-bit access on this route: the PS VIP's internal BFM defaults to a
//     128-bit data width, and without this call a 32-bit write/read can
//     land on the wrong byte lane.
// ===========================================================================

localparam bit [43:0] CTRL_REG_EP_BASE = 44'h8000_0000;
localparam bit [11:0] SCRATCH_LO       = 12'h000;
localparam bit [11:0] EP_CTRL_STS      = 12'h400;

logic [1:0]  rsp;
logic [31:0] rdata;
logic [31:0] scratch_pattern = 32'hA5A5_1234;

ps_vip_api.set_routing_config(R5_API, M_AXI_LPD, 1'b1);
ps_vip_api.select_pl_datawidth(2'b00, "M_AXI_LPD"); // 2'b00 = 32-bit

ps_vip_api.write_data_32(R5_API, CTRL_REG_EP_BASE + SCRATCH_LO, scratch_pattern, rsp);
if (rsp !== 2'b00)
  `uvm_error("CSR_SANITY", $sformatf("SCRATCH_LO write BRESP=%0b (expected OKAY)", rsp))
else
  `uvm_info("CSR_SANITY", $sformatf("SCRATCH_LO write OK (0x%h)", scratch_pattern), UVM_NONE)

ps_vip_api.read_data_32(R5_API, CTRL_REG_EP_BASE + SCRATCH_LO, rdata, rsp);
if (rsp !== 2'b00 || rdata !== scratch_pattern)
  `uvm_error("CSR_SANITY", $sformatf("SCRATCH_LO readback = 0x%h (expected 0x%h), RRESP=%0b", rdata, scratch_pattern, rsp))
else
  `uvm_info("CSR_SANITY", $sformatf("PASS: SCRATCH_LO loopback OK (0x%h) via M_AXI_LPD", rdata), UVM_NONE)

ps_vip_api.read_data_32(R5_API, CTRL_REG_EP_BASE + EP_CTRL_STS, rdata, rsp);
`uvm_info("CSR_SANITY", $sformatf("INFO: EP_CTRL_STS = 0x%h (ep_status input unconnected in this BD - expect 0), RRESP=%0b", rdata, rsp), UVM_NONE)

ps_vip_api.set_routing_config(R5_API, M_AXI_LPD, 1'b0);
