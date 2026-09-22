class seq_disable_crs extends seq_base_ps_axi32;

  `uvm_object_utils(seq_disable_crs)

  int               index;

  function new(string name = "seq_disable_crs");
    super.new(name);
    ps_vip_slv = R5_API;
    ps_vip_mst = PS_CPM_CFG;
  endfunction

  virtual task disable_crs(int index);
    bit [31:0] rd_data;

    axi_rd('hFC840100 | ((index) * 32'h100000), rd_data);
    axi_wr('hFC840100 | ((index) * 32'h100000), rd_data & 'hFFFFFFBF);
  endtask

  virtual task body();
    disable_crs(index);
  endtask
endclass
