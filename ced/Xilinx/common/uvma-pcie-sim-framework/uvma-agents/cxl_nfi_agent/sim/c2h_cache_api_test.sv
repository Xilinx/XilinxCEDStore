class c2h_cache_api_test extends base_test;

  `uvm_component_utils(c2h_cache_api_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    d2hreq_c d2hreq = d2hreq_c::type_id::create("d2hreq");
    d2hdat_c d2hdat = d2hdat_c::type_id::create("d2hdat");
    d2hrsp_c d2hrsp = d2hrsp_c::type_id::create("d2hrsp");
    super.run_phase(phase);
    phase.raise_objection(this);
    #20;
    /* 68B FLIT MODE */
    if (MODE == F68) begin
      // Send some D2H_Req txns in each slot of each flit (N*4 total txns in N*4 flits)
      `uvm_info("TSTINFO", "Sending D2H_Req txns", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.c2h_mst.api68.issue_msg(d2hreq,, 0, ii);
        env.c2h_mst.api68.issue_msg(d2hreq,, 1, ii);
        env.c2h_mst.api68.issue_msg(d2hreq,, 2, ii);
        env.c2h_mst.api68.issue_msg(d2hreq,, 3, ii);
      end
      // Send some D2H_Dat txns in each slot of each flit (64B, no BE) (N*4 txns in N*4*2 flits)
      d2hdat.txfer_64B = 1'b1;
      d2hdat.be = '1;
      `uvm_info("TSTINFO", "Sending D2H_Dat txns (64B, no BE)", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.c2h_mst.api68.issue_msg(d2hdat,, 0, ii);
        env.c2h_mst.api68.issue_msg(d2hdat,, 1, ii);
        env.c2h_mst.api68.issue_msg(d2hdat,, 2, ii);
        env.c2h_mst.api68.issue_msg(d2hdat,, 3, ii);
      end
      // Send some D2H_Dat txns in each slot of each flit (64B, BE)
      d2hdat.txfer_64B = 1'b1;
      d2hdat.be = '0;
      `uvm_info("TSTINFO", "Sending D2H_Dat txns (64B, BE)", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.c2h_mst.api68.issue_msg(d2hdat,, 0, ii);
        env.c2h_mst.api68.issue_msg(d2hdat,, 1, ii);
        env.c2h_mst.api68.issue_msg(d2hdat,, 2, ii);
        env.c2h_mst.api68.issue_msg(d2hdat,, 3, ii);
      end
      // Send some D2H_Dat txns in each slot of each flit (32B, no BE) (N*4 txns in N*4*2 flits)
      d2hdat.txfer_64B = 1'b0;
      d2hdat.be = '1;
      `uvm_info("TSTINFO", "Sending D2H_Dat txns (32B, no BE)", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.c2h_mst.api68.issue_msg(d2hdat,, 0, ii);
        env.c2h_mst.api68.issue_msg(d2hdat,, 1, ii);
        env.c2h_mst.api68.issue_msg(d2hdat,, 2, ii);
        env.c2h_mst.api68.issue_msg(d2hdat,, 3, ii);
      end
      // Send some D2H_Dat txns in each slot of each flit (32B, BE)
      d2hdat.txfer_64B = 1'b0;
      d2hdat.be = '0;
      `uvm_info("TSTINFO", "Sending D2H_Dat txns (32B, BE)", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.c2h_mst.api68.issue_msg(d2hdat,, 0, ii);
        env.c2h_mst.api68.issue_msg(d2hdat,, 1, ii);
        env.c2h_mst.api68.issue_msg(d2hdat,, 2, ii);
        env.c2h_mst.api68.issue_msg(d2hdat,, 3, ii);
      end
      // Send some D2H_Rsp txns in each slot of each flit
      for (int ii=0; ii<N; ii++) begin
      `uvm_info("TSTINFO", "Sending D2H_Rsp txns", UVM_LOW)
        env.c2h_mst.api68.issue_msg(d2hrsp,, 0, ii);
        env.c2h_mst.api68.issue_msg(d2hrsp,, 1, ii);
        env.c2h_mst.api68.issue_msg(d2hrsp,, 2, ii);
        env.c2h_mst.api68.issue_msg(d2hrsp,, 3, ii);
      end
    end
    /* 256B FLIT MODE */
    else if (MODE == F256) begin
      // Use the api to pack a transaction in any slot
      repeat (32) env.c2h_mst.api256.issue_msg(d2hreq, -2);
      repeat (32) env.c2h_mst.api256.issue_msg(d2hdat, -2);
      repeat (32) env.c2h_mst.api256.issue_msg(d2hrsp, -2);
    end
    #20;
    phase.drop_objection(this);
  endtask

endclass
