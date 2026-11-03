class seq_disable_crs extends seq_base_ps_axi32;

  `uvm_object_utils(seq_disable_crs)

  int               index;

  function new(string name = "seq_disable_crs");
    super.new(name);
    ps_vip_slv = R5_API;
    ps_vip_mst = PS_CPM_CFG;
  endfunction

  virtual task disable_crs(int index);
    bit [31:0] base = 'hFC840000 | ((index) * 32'h100000);
    bit [31:0] rd_data;

    axi_wr(base + 'h0, 'h0);
    axi_wr(base + 'h4, 'h0);
    axi_rd(base + 'h100, rd_data);
    axi_wr(base + 'h100, rd_data & 'hFFFFFFBF);
    axi_wr(base + 'h4, 'h1);
    axi_wr(base + 'h0, 'h1);
  endtask

  virtual task body();
    disable_crs(index);
  endtask
endclass