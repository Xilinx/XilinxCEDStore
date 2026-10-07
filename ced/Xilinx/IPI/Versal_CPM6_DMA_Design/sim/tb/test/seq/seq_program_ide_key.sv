class seq_program_ide_key extends seq_base_ps_axi32;

  `uvm_object_utils(seq_program_ide_key)

  int               index;
  bit               tx;
  apci_ide_key_iv_t ide_key;
  int               ctrlr;  // 0 or 1 - selects which controller's IDE key RAM window is targeted

  function new(string name = "seq_program_ide_key");
    super.new(name);
    ps_vip_slv = R5_API;
    ps_vip_mst = PS_CPM_CFG;
    ctrlr = 0;
  endfunction

  virtual task program_key(int index, bit tx, apci_ide_key_iv_t ide_key);
    bit [31:0] rd_data;
    bit [63:0] base = 'hFC860020 + (ctrlr * 'h10_0000);
    for (int j = 0; j < 8; j++) begin
      axi_wr((base | ((1-tx) * 32'h800)) + j*4, {ide_key.key[(7-j)*4 + 3], ide_key.key[(7-j)*4 + 2], ide_key.key[(7-j)*4 + 1], ide_key.key[(7-j)*4 + 0]});
    end
    axi_wr((base + 'h20) | ((1-tx) * 32'h800), ide_key.iv[31:0]);
    axi_wr((base + 'h24) | ((1-tx) * 32'h800), ide_key.iv[63:32]);

    axi_wr((base - 'hC) | ((1-tx) * 32'h800), ((32'h00040000 * tx) | (32'h00010000) | (index & 32'hF)));

    axi_rd((base - 'h8) | ((1-tx) * 32'h800), rd_data);
    while (rd_data[0]) begin
      axi_rd((base - 'h8) | ((1-tx) * 32'h800), rd_data);
    end
  endtask

  virtual task body();
    program_key(index, tx, ide_key);
  endtask
endclass