class global_slv_base_seq extends uvm_sequence#(global_txn);

  `uvm_object_utils(global_slv_base_seq)
  `uvm_declare_p_sequencer(base_sequencer#(global_txn, global_txn, global_txn, global_cfg, global_share))

  function new(string name = "global_slv_base_seq");
    super.new(name);
  endfunction

  virtual task body();

    global_txn mtxn; //monitored txn from fifo
    global_txn rtxn; //response txn
    global_txn etxn; //empty txn

    // - The monitor will coordinate with the shr handle to notify this sequence that
    //   an empty condition has been met and needs to be sent
    // - Empty and connect/disconnect are mutually exclusive: they cannot be controlled
    //   in the same cycle
    forever begin
      p_sequencer.analysis_fifo.get(mtxn);
      rtxn = global_txn::type_id::create("rtxn");
      rtxn.init = 1'b1;
      if (mtxn.empty) begin
        start_item(rtxn);
        rtxn.empty = 1'b1;
        rtxn.rx_empty = mtxn.rx_empty;
        finish_item(rtxn);
      end 
      else begin
        rtxn.rsp_delay = $urandom_range(31);
        // No action needed
        if (p_sequencer.shr.conn_state inside {CONNECTED, DISCONNECTED})
          continue;
        // Default will be to successfully connect and disconnect if requested 
        start_item(rtxn);
        if (p_sequencer.shr.conn_state == CONNECTING) begin
          rtxn.rxcon_ack = 1'b1;
          rtxn.rxdiscon_nack = 1'b0;
        end
        else if (p_sequencer.shr.conn_state == DISCONNECTING) begin
          rtxn.rxcon_ack = 1'b0;
          rtxn.rxdiscon_nack = 1'b0;
        end
        finish_item(rtxn);
      end
    end 
  endtask

endclass
