class h2c_mem_api_test extends base_test;

  `uvm_component_utils(h2c_mem_api_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m2srwd_c m2srwd = m2srwd_c::type_id::create("m2srwd");
    m2sreq_c m2sreq = m2sreq_c::type_id::create("m2sreq");
    cxl_nfi_mst_in_order_seq#(N) seq = cxl_nfi_mst_in_order_seq#(N)::type_id::create("seq");
    super.run_phase(phase);
    phase.raise_objection(this);
    #20;
    /* 68B FLIT MODE */
    if (MODE == F68) begin
      // Send some M2S_RwD txns that are tightly packed
      `uvm_info("TSTINFO", "Sending M2S_Dat txns that should be tightly packed (NFI0:Slot 0,1)", UVM_LOW)
      repeat (10) begin
        env.h2c_mst.api68.issue_msg(m2srwd);
      end
      // Send some M2S_RwD txns that are tightly packed, but any NFI
      `uvm_info("TSTINFO", "Sending M2S_Dat txns that should be any NFI, but tightly packed (Slot 0,1)", UVM_LOW)
      repeat (10) begin
        env.h2c_mst.api68.issue_msg(m2srwd,,,-2);
      end
      // Send some M2S_RwD txns in each slot of each flit (No BE)
      m2srwd.be = '1;
      `uvm_info("TSTINFO", "Sending M2S_Dat txns (no BE)", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.h2c_mst.api68.issue_msg(m2srwd,, 0, ii);
        env.h2c_mst.api68.issue_msg(m2srwd,, 1, ii);
        env.h2c_mst.api68.issue_msg(m2srwd,, 2, ii);
        env.h2c_mst.api68.issue_msg(m2srwd,, 3, ii);
      end
      // Send some M2S_RwD txns in each slot of each flit (BE)
      m2srwd.hdr68.memop = MemWrPtl;
      `uvm_info("TSTINFO", "Sending M2S_Dat txns (BE)", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.h2c_mst.api68.issue_msg(m2srwd,, 0, ii);
        env.h2c_mst.api68.issue_msg(m2srwd,, 1, ii);
        env.h2c_mst.api68.issue_msg(m2srwd,, 2, ii);
        env.h2c_mst.api68.issue_msg(m2srwd,, 3, ii);
      end
      // Send some M2S_Req txns that are tightly packed
      `uvm_info("TSTINFO", "Sending M2S_Req txns that should be tightly packed (NFI0:Slot 0,1)", UVM_LOW)
      repeat (10) begin
        env.h2c_mst.api68.issue_msg(m2sreq);
      end
      // Send some M2S_Req txns that are tightly packed, but any NFI
      `uvm_info("TSTINFO", "Sending M2S_Req txns that should be any NFI, but tightly packed (Slot 0,1)", UVM_LOW)
      repeat (10) begin
        env.h2c_mst.api68.issue_msg(m2sreq,,,-2);
      end
      // Send some M2S_Req txns in each slot of each flit
      `uvm_info("TSTINFO", "Sending M2S_Req txns", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.h2c_mst.api68.issue_msg(m2sreq,, 0, ii);
        env.h2c_mst.api68.issue_msg(m2sreq,, 1, ii);
        env.h2c_mst.api68.issue_msg(m2sreq,, 2, ii);
        env.h2c_mst.api68.issue_msg(m2sreq,, 3, ii);
      end
    end
    /* 256B FLIT MODE */
    else if (MODE == F256) begin
      // Use the api to pack a transaction in any slot
      repeat (32) env.h2c_mst.api256.issue_msg(m2sreq, -2);
      repeat (32) env.h2c_mst.api256.issue_msg(m2srwd, -2);
    end
    #20;
    phase.drop_objection(this);
  endtask

endclass
