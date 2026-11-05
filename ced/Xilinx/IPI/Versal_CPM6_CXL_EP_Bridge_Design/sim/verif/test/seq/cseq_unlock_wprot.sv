// ===========================================================================
// cseq_unlock_wprot.sv - Versal CPM6 CXL EP Bridge Design
//
// Unlocks the CPM6 write-protect registers after CDO load, as device firmware
// does. The CDO locks them again at its end, so the fix-ups that follow
// (cseq_app_req_retry_en, cseq_irq_enables) would otherwise be dropped:
//
//   CPM6_PCIE_CORE WPROTS/WPROTP (Ctrl0 0xfc840000/04, Ctrl1 0xfc940000/04)
//   CPM6_SLCR      WPROTS/WPROTP (0xfcdd0000/04)
//   CPM6_CRX       WPROTS/WPROTP (0xfcdc0030/34)
// ===========================================================================
class cseq_unlock_wprot extends seq_base_ps_axi32;
  `uvm_object_utils(cseq_unlock_wprot)

`ifdef CXL_BRDG_CTRL0
  localparam bit [47:0] CORE_WPROTS = 48'hfc84_0000;
  localparam bit [47:0] CORE_WPROTP = 48'hfc84_0004;
`else
  localparam bit [47:0] CORE_WPROTS = 48'hfc94_0000;
  localparam bit [47:0] CORE_WPROTP = 48'hfc94_0004;
`endif

  function new(string name = "cseq_unlock_wprot");
    super.new(name);
  endfunction

  virtual task body();
    bit [47:0] wprot[$] = '{CORE_WPROTS, CORE_WPROTP,
                            48'hfcdd_0000, 48'hfcdd_0004,   // SLCR
                            48'hfcdc_0030, 48'hfcdc_0034};  // CRX
    foreach (wprot[i]) axi_wr(wprot[i], 32'h0);
    `uvm_info(get_type_name(), "Unlocked PCIE_CORE, SLCR and CRX write-protect registers", UVM_LOW)
  endtask

endclass
