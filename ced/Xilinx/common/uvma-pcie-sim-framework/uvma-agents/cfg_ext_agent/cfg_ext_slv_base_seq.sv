class cfg_ext_slv_base_seq extends uvm_sequence#(cfg_ext_txn);

  `uvm_object_utils(cfg_ext_slv_base_seq)
  `uvm_declare_p_sequencer(base_sequencer#(cfg_ext_txn, cfg_ext_txn, cfg_ext_txn, base_cfg, cfg_ext_share))

  function new(string name = "cfg_ext_slv_base_seq");
    super.new(name);
  endfunction

  virtual task body;
    bit [11:0] addr;
    cfg_ext_txn mtxn; //monitored txn 
    cfg_ext_txn rtxn; //response txn (read)
    forever begin
      p_sequencer.analysis_fifo.get(mtxn); //blocking
      addr = mtxn.cfg_ext_register_number<<2;
      if (mtxn.cfg_ext_write_received) begin
        if (mtxn.cfg_ext_write_byte_enable[0]) void'(p_sequencer.shr.poke_byte(addr,   mtxn.cfg_ext_write_data[ 0+:8]));
        if (mtxn.cfg_ext_write_byte_enable[1]) void'(p_sequencer.shr.poke_byte(addr+1, mtxn.cfg_ext_write_data[ 8+:8]));
        if (mtxn.cfg_ext_write_byte_enable[2]) void'(p_sequencer.shr.poke_byte(addr+2, mtxn.cfg_ext_write_data[16+:8]));
        if (mtxn.cfg_ext_write_byte_enable[3]) void'(p_sequencer.shr.poke_byte(addr+3, mtxn.cfg_ext_write_data[24+:8]));
      end
      else if (mtxn.cfg_ext_read_received) begin
        rtxn = cfg_ext_txn::type_id::create("rtxn");
        start_item(rtxn);
        rtxn.rd_rsp_delay = $urandom(9);
        rtxn.cfg_ext_read_data = p_sequencer.shr.peek_dword(addr);
        rtxn.cfg_ext_read_data_valid = 1'b1;
        finish_item(rtxn);
      end
    end
  endtask

endclass
