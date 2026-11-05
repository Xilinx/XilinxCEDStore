// ===========================================================================
// cseq_app_req_retry_en.sv - Versal CPM6 CXL EP Bridge Design
//
// Clears CPM6_PCIE_CORE.ATTR_REG_0 (Ctrl0 0xfc840100 / Ctrl1 0xfc940100)
// bit[6] (app_req_retry_en) after CDO load. Real hardware's PLM firmware
// clears this after device init; this sim has no PLM, so without this fix
// the core answers every incoming configuration request with a
// Configuration Request Retry Status forever and host bus enumeration
// never completes.
//
// ATTR_REG_0 lives at the active controller's own PCIe Core base
// (0xFC840000 for Ctrl0, 0xFC940000 for Ctrl1) - same `ifdef
// CXL_BRDG_CTRL0 already used by cxl_ep_brdg_sanity.sv to pick the
// controller-specific SPEED plusarg, reused here so the fix targets
// whichever controller CTRL_CONFIG actually made active.
//
// Uses axi_rd_mod_wr (seq_base_ps_axi32) so only bit[6] is touched; every
// other bit keeps whatever value the CDO already wrote.
// ===========================================================================
class cseq_app_req_retry_en extends seq_base_ps_axi32;
  `uvm_object_utils(cseq_app_req_retry_en)

`ifdef CXL_BRDG_CTRL0
  localparam bit [47:0] ATTR_REG_0       = 48'hfc84_0100;
`else
  localparam bit [47:0] ATTR_REG_0       = 48'hfc94_0100;
`endif
  localparam int        APP_REQ_RETRY_EN = 6;

  function new(string name = "cseq_app_req_retry_en");
    super.new(name);
  endfunction

  virtual task body();
    logic [31:0] mod_data;
    mod_data = 'x;
    mod_data[APP_REQ_RETRY_EN] = 1'b0;
    axi_rd_mod_wr(ATTR_REG_0, mod_data);
    `uvm_info(get_type_name(), $sformatf(
      "Cleared app_req_retry_en (bit[%0d]) at ATTR_REG_0 [0x%h]",
      APP_REQ_RETRY_EN, ATTR_REG_0), UVM_LOW)
  endtask

endclass
