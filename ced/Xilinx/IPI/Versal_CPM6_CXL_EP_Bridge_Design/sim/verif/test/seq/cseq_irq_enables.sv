// ===========================================================================
// cseq_irq_enables.sv - Versal CPM6 CXL EP Bridge Design
//
// Sets 3 interrupt-enable bits that the CDO correctly leaves untouched -
// on real silicon these are programmed by device firmware during bring-up,
// not by the boot CDO. The simulation environment has no firmware model
// running, so this sequence applies the same enables directly, purely to
// let sim proceed the way a real firmware-initialized device would (same
// pattern as cseq_app_req_retry_en.sv/cseq_cxl_dvsec_next_cap.sv):
//
//   CPM6_SLCR.PS_CORR_IR_ENABLE          (0xfcdd0308) bit[21] merged_interrupts_0
//   CPM6_SLCR.MERGED_INTERRUPTS_0_ENABLE (0xfcdd0650) bits[5,2]
//   CPM6_PCIE_CORE.IR_ENABLE             (active ctrl) bits[27:26]
//
// IR_ENABLE lives at the active controller's own PCIe Core base (same
// 0xFC84_0000/0xFC94_0000 `ifdef CXL_BRDG_CTRL0 split already used by
// cseq_app_req_retry_en.sv); the two CPM6_SLCR registers are global
// and not per-controller.
//
// Uses axi_rd_mod_wr (seq_base_ps_axi32) so only the named bits are
// touched - every other bit keeps whatever value the CDO already wrote.
// ===========================================================================
class cseq_irq_enables extends seq_base_ps_axi32;
  `uvm_object_utils(cseq_irq_enables)

  localparam bit [47:0] PS_CORR_IR_ENABLE          = 48'hfcdd_0308;
  localparam bit [47:0] MERGED_INTERRUPTS_0_ENABLE = 48'hfcdd_0650;
`ifdef CXL_BRDG_CTRL0
  localparam bit [47:0] IR_ENABLE                  = 48'hfc84_0014;
`else
  localparam bit [47:0] IR_ENABLE                  = 48'hfc94_0014;
`endif

  function new(string name = "cseq_irq_enables");
    super.new(name);
  endfunction

  virtual task body();
    logic [31:0] mod_data;

    mod_data = 'x;
    mod_data[21] = 1'b1; // merged_interrupts_0
    axi_rd_mod_wr(PS_CORR_IR_ENABLE, mod_data);
    `uvm_info(get_type_name(), $sformatf(
      "Set merged_interrupts_0 (bit[21]) at PS_CORR_IR_ENABLE [0x%h]",
      PS_CORR_IR_ENABLE), UVM_LOW)

    mod_data = 'x;
    mod_data[5] = 1'b1;
    mod_data[2] = 1'b1;
    axi_rd_mod_wr(MERGED_INTERRUPTS_0_ENABLE, mod_data);
    `uvm_info(get_type_name(), $sformatf(
      "Set bits[5,2] at MERGED_INTERRUPTS_0_ENABLE [0x%h]",
      MERGED_INTERRUPTS_0_ENABLE), UVM_LOW)

    mod_data = 'x;
    mod_data[27] = 1'b1;
    mod_data[26] = 1'b1;
    axi_rd_mod_wr(IR_ENABLE, mod_data);
    `uvm_info(get_type_name(), $sformatf(
      "Set bits[27,26] at IR_ENABLE [0x%h]",
      IR_ENABLE), UVM_LOW)
  endtask

endclass
