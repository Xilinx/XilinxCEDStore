class elbi_slv_base_seq extends uvm_sequence#(elbi_txn);

  `uvm_object_utils(elbi_slv_base_seq)
  `uvm_declare_p_sequencer(base_sequencer#(elbi_txn, elbi_txn, elbi_txn, elbi_cfg, elbi_share))

  elbi_share shr;

  function new(string name = "elbi_slv_base_seq");
    super.new(name);
  endfunction

  virtual task body;
    elbi_txn   mtxn; //monitored txn 
    elbi_txn   rtxn; //response txn
    // easy handle assignment
    shr = p_sequencer.shr;
    forever begin
      p_sequencer.analysis_fifo.get(mtxn); //blocking
      // Check if request hits an aperture
      if (shr.match(mtxn)==-1) 
        continue; 
      // Return response if match
      rtxn = shr.get_response(mtxn);
      // Send it
      start_item(rtxn);
      finish_item(rtxn);
    end
  endtask

endclass
