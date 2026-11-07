class cseq_core_bd_ide_cfg_mb extends cseq_core_doe_discovery_cfg_mb;

  `uvm_object_utils(cseq_core_bd_ide_cfg_mb)

  function new(string name = "cseq_core_bd_ide_cfg_mb");
    super.new(name);
  endfunction

  task bd_program_ide_key();
    // doe_data[2]: bit 31 = TX path, bits 3:0 = IDE key index
    bit        tx   = doe_data[2][31];
    // IDE AES block of this controller; its RX registers are 'h800 above the TX ones
    bit [31:0] base = 'hFC860000 + (ctrlr * 'h10_0000) + ((1-tx) * 'h800);
    logic [31:0] rd_data;

    if (doe_data[1] == 'hc) begin
      for (int j = 0; j < 8; j++) begin
        axi_wr(base + 'h20 + j*4, doe_data[3+j]);
      end
      axi_wr(base + 'h40, doe_data[11]);
      axi_wr(base + 'h44, doe_data[12]);

      axi_wr(base + 'h14, ((32'h00040000 * tx) | (32'h00010000) | doe_data[2][3:0]));

      //Poll for IDE Key Op complete
      axi_rd(base + 'h18, rd_data);
      while (rd_data[0]) begin
        axi_rd(base + 'h18, rd_data);
      end
    end else begin
      `uvm_error(get_type_name, $sformatf("BD IDE Invalid Length: %0h", doe_data[1]))
    end
  endtask

  task generate_response(output bit err);
    super.generate_response(err);
    if (err) begin
      if (doe_data[0] == 32'hFFE00000) begin
        err = 0;
        doe_data_rd.push_back(32'hFFE00000);
        doe_data_rd.push_back(32'h00000002);
        bd_program_ide_key();
      end 
    end
  endtask
endclass