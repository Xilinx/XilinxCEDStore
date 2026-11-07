class c2h_mem_api_test extends base_test;

  `uvm_component_utils(c2h_mem_api_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    s2mdrs_c s2mdrs = s2mdrs_c::type_id::create("s2mdrs");
    s2mndr_c s2mndr = s2mndr_c::type_id::create("s2mndr");
    super.run_phase(phase);
    phase.raise_objection(this);
    #20;
    /* 68B FLIT MODE */
    if (MODE == F68) begin
      // Send some S2M_DRS txns in each slot of each flit (64B)
      s2mdrs.txfer_64B = 1'b1;
      `uvm_info("TSTINFO", "Sending S2M_Dat txns (64B)", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.c2h_mst.api68.issue_msg(s2mdrs,, 0, ii);
        env.c2h_mst.api68.issue_msg(s2mdrs,, 1, ii);
        env.c2h_mst.api68.issue_msg(s2mdrs,, 2, ii);
        env.c2h_mst.api68.issue_msg(s2mdrs,, 3, ii);
      end
      // Send some S2M_DRS txns in each slot of each flit (32B)
      s2mdrs.txfer_64B = 1'b0;
      `uvm_info("TSTINFO", "Sending S2M_Dat txns (32B)", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.c2h_mst.api68.issue_msg(s2mdrs,, 0, ii);
        env.c2h_mst.api68.issue_msg(s2mdrs,, 1, ii);
        env.c2h_mst.api68.issue_msg(s2mdrs,, 2, ii);
        env.c2h_mst.api68.issue_msg(s2mdrs,, 3, ii);
      end
      // Send some S2M_NDR txns in each slot of each flit
      `uvm_info("TSTINFO", "Sending S2M_Rsp txns", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.c2h_mst.api68.issue_msg(s2mndr,, 0, ii);
        env.c2h_mst.api68.issue_msg(s2mndr,, 1, ii);
        env.c2h_mst.api68.issue_msg(s2mndr,, 2, ii);
        env.c2h_mst.api68.issue_msg(s2mndr,, 3, ii);
      end
    end
    /* 256B FLIT MODE */
    else if (MODE == F256) begin
      // Use the api to pack a transaction in any slot
      repeat (32) env.c2h_mst.api256.issue_msg(s2mndr, -2);
      repeat (32) env.c2h_mst.api256.issue_msg(s2mdrs, -2);
    end
    #20;
    phase.drop_objection(this);
  endtask

endclass
