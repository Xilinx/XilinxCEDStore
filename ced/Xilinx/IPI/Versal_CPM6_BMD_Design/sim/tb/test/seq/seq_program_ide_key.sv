class seq_program_ide_key extends seq_base_ps_axi32;

  `uvm_object_utils(seq_program_ide_key)

  int               index;
  bit               tx;
  apci_ide_key_iv_t ide_key;

  function new(string name = "seq_program_ide_key");
    super.new(name);
    ps_vip_slv = R5_API;
    ps_vip_mst = PS_CPM_CFG;
  endfunction

  virtual task program_key(int index, bit tx, apci_ide_key_iv_t ide_key);
    bit [31:0] rd_data;
    for (int j = 0; j < 8; j++) begin
      axi_wr(('hFC960020 | ((1-tx) * 32'h800)) + j*4, {ide_key.key[(7-j)*4 + 3], ide_key.key[(7-j)*4 + 2], ide_key.key[(7-j)*4 + 1], ide_key.key[(7-j)*4 + 0]});
    end
    axi_wr('hFC960040 | ((1-tx) * 32'h800), ide_key.iv[31:0]);
    axi_wr('hFC960044 | ((1-tx) * 32'h800), ide_key.iv[63:32]);

    axi_wr('hFC960014 | ((1-tx) * 32'h800), ((32'h00040000 * tx) | (32'h00010000) | (index & 32'hF)));

    axi_rd('hFC960018 | ((1-tx) * 32'h800), rd_data);
    while (rd_data[0]) begin
      axi_rd('hFC960018 | ((1-tx) * 32'h800), rd_data);
    end
  endtask

  virtual task body();
    program_key(index, tx, ide_key);
  endtask
endclass