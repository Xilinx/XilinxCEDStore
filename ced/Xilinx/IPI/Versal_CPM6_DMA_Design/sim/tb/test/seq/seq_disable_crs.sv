class seq_disable_crs extends seq_base_ps_axi32;

  `uvm_object_utils(seq_disable_crs)

  int               index;

  function new(string name = "seq_disable_crs");
    super.new(name);
    ps_vip_slv = R5_API;
    ps_vip_mst = PS_CPM_CFG;
  endfunction

  // Clears ATTR_REG_0.app_req_retry_en (bit 6) of the CPM6 PCIe core so the
  // controller stops answering config requests with CRS.
  //
  // The CDO can leave the core register block write-protected (WPROTS at
  // offset 0x0 and WPROTP at offset 0x4, bit 0: 0 = writes enabled, 1 = writes
  // disabled). A write to ATTR_REG_0 is then accepted with an OKAY response but
  // silently ignored. So: unlock, clear the bit, lock again.
  virtual task disable_crs(int index);
    bit [31:0] rd_data, chk;
    bit [47:0] base = 'hFC840000 | ((index) * 32'h100000);
    bit [47:0] attr = base + 'h100;

    // Unlock: WPROTS / WPROTP = 0
    axi_wr(base + 'h0, 32'h0);
    axi_wr(base + 'h4, 32'h0);

    // Write: clear app_req_retry_en (bit 6)
    axi_rd(attr, rd_data);
    axi_wr(attr, rd_data & 'hFFFFFFBF);
    axi_rd(attr, chk);
    if (chk[6])
      `uvm_error(get_type_name, $sformatf("ATTR_REG_0 (0x%h) app_req_retry_en still set after clear: 0x%08h", attr, chk))

    // Lock: WPROTS / WPROTP = 1
    axi_wr(base + 'h0, 32'h1);
    axi_wr(base + 'h4, 32'h1);
  endtask

  virtual task body();
    disable_crs(index);
  endtask
endclass
