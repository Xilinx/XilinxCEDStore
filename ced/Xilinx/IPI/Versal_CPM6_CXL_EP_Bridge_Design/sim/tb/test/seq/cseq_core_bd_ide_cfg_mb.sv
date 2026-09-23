class cseq_core_bd_ide_cfg_mb extends cseq_core_doe_discovery_cfg_mb;

  `uvm_object_utils(cseq_core_bd_ide_cfg_mb)

  function new(string name = "cseq_core_bd_ide_cfg_mb");
    super.new(name);
  endfunction

  task bd_program_ide_key();
    logic [31:0] rd_data;
  
    if (doe_data[1] == 'hc) begin
      axi_wr('hFC860020+(ctrlr*'h10_0000), doe_data[3]);
      axi_wr('hFC860024+(ctrlr*'h10_0000), doe_data[4]);
      axi_wr('hFC860028+(ctrlr*'h10_0000), doe_data[5]);
      axi_wr('hFC86002C+(ctrlr*'h10_0000), doe_data[6]);
      axi_wr('hFC860030+(ctrlr*'h10_0000), doe_data[7]);
      axi_wr('hFC860034+(ctrlr*'h10_0000), doe_data[8]);
      axi_wr('hFC860038+(ctrlr*'h10_0000), doe_data[9]);
      axi_wr('hFC86003C+(ctrlr*'h10_0000), doe_data[10]);
      axi_wr('hFC860040+(ctrlr*'h10_0000), doe_data[11]);
      axi_wr('hFC860044+(ctrlr*'h10_0000), doe_data[12]);
      
      //Bit 31 set is for TX path
      //Bit 3:0 is for IDE Key index
      axi_wr('hFC860814+(ctrlr*'h10_0000), (32'h00010000<<doe_data[2][31]) | doe_data[2][3:0]);

      //Poll for IDE Key Op complete
      axi_rd('hFC860018+(ctrlr*'h10_0000), rd_data);
      while (rd_data[0]) begin
        axi_rd('hFC860018+(ctrlr*'h10_0000), rd_data);
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