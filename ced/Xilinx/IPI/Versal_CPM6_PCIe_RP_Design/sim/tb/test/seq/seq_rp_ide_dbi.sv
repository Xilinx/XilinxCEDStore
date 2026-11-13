// One 32-bit PS AXI access (R5_API), used by rp_ide_helper for the RP IDE registers (CPM6 DBI window)
// and the Endpoint IDE registers (config access through the ECAM / the PL config bridge).
class seq_rp_ide_dbi extends seq_base_ps_axi32;

  `uvm_object_utils(seq_rp_ide_dbi)

  bit        wr;
  bit [47:0] addr;
  bit [31:0] data;

  // mst: PS_CPM_CFG for the RP's own DBI window and the ECAM; a NoC master (FPD_AXI_NOC_1) for
  // the PL config bridge (PL_Streaming), as the firmware on R5_0 reaches it.
  function new(string name = "seq_rp_ide_dbi");
    super.new(name);
    ps_vip_slv = R5_API;
    ps_vip_mst = PS_CPM_CFG;
  endfunction

  virtual task body();
    logic [31:0] rd_data;
    logic [1:0]  rsp;
    if (ps_vip_mst inside {PS_CPM_CFG, PS_CPM_PCIE_AXI}) begin
      // axi_wr/axi_rd pick the route from the address: DBI window (0xFC..) or the CPM PCIe AXI (ECAM)
      if (wr) axi_wr(addr, data);
      else begin
        axi_rd(addr, rd_data);
        data = rd_data;
      end
    end else begin
      // Any other master (the NoC, toward the PL config bridge): route explicitly, as the R5 firmware reaches it
      p_sequencer.ps_vip_api.set_routing_config(R5_API, ps_vip_mst, 1'b1);
      if (wr) p_sequencer.ps_vip_api.write_data_32(R5_API, addr[43:0], data, rsp);
      else begin
        p_sequencer.ps_vip_api.read_data_32(R5_API, addr[43:0], rd_data, rsp);
        data = rd_data;
      end
      p_sequencer.ps_vip_api.set_routing_config(R5_API, ps_vip_mst, 1'b0);
      if (rsp !== 2'b00)
        `uvm_error(get_type_name, $sformatf("PS AXI %s 0x%h -> RESP=0x%0h", wr ? "write" : "read", addr, rsp))
    end
  endtask
endclass
