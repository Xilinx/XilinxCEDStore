// ===========================================================================
// cseq_cxl_dvsec_next_cap.sv - Versal CPM6 CXL EP Bridge Design
//
// Clears the PCIe Extended Capability Header of the CXL Device DVSEC
// (PF0_CXL_DEVICE_CAP_CXL_RCIEP_PCIE_EXT_CAP_HDR_OFF, Ctrl0 0xfc000618 /
// Ctrl1 0xfc400618) bits[31:20] (Next Capability Offset) to 0x000
// (end-of-list). Without this fix, the host's DVSEC capability walk
// follows a dangling Next-Capability-Offset to an unmapped location,
// issues a CFGRD that never completes, and bus enumeration times out.
//
// PCIe Extended Capability Header layout (bits[31:20]=Next Cap Offset,
// bits[19:16]=Cap Version, bits[15:0]=Extended Cap ID) - only bits[31:20]
// are touched here; ID/Version are left as whatever the CDO already wrote
// via axi_rd_mod_wr's per-bit read-modify-write semantics ('x = unchanged).
//
// Register lives at the active controller's own DBI base (0xFC00_0000 for
// Ctrl0, 0xFC40_0000 for Ctrl1), selected by the same `ifdef CXL_BRDG_CTRL0
// cxl_ep_brdg_sanity.sv already uses for its SPEED plusarg.
// ===========================================================================
class cseq_cxl_dvsec_next_cap extends seq_base_ps_axi32;
  `uvm_object_utils(cseq_cxl_dvsec_next_cap)

`ifdef CXL_BRDG_CTRL0
  localparam bit [47:0] CXL_DEV_DVSEC_EXT_CAP_HDR = 48'hfc00_0618;
`else
  localparam bit [47:0] CXL_DEV_DVSEC_EXT_CAP_HDR = 48'hfc40_0618;
`endif

  function new(string name = "cseq_cxl_dvsec_next_cap");
    super.new(name);
  endfunction

  virtual task body();
    logic [31:0] mod_data;
    mod_data = 'x;
    mod_data[31:20] = 12'h000;
    axi_rd_mod_wr(CXL_DEV_DVSEC_EXT_CAP_HDR, mod_data);
    `uvm_info(get_type_name(), $sformatf(
      "Cleared Next Capability Offset (bits[31:20]) at CXL Device DVSEC ext-cap header [0x%h]",
      CXL_DEV_DVSEC_EXT_CAP_HDR), UVM_LOW)
  endtask

endclass
