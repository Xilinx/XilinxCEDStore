class h2c_cache_api_test extends base_test;

  `uvm_component_utils(h2c_cache_api_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    h2dreq_c h2dreq = h2dreq_c::type_id::create("h2dreq");
    h2ddat_c h2ddat = h2ddat_c::type_id::create("h2ddat");
    h2drsp_c h2drsp = h2drsp_c::type_id::create("h2drsp");
    super.run_phase(phase);
    phase.raise_objection(this);
    #20;
    /* 68B FLIT MODE */
    if (MODE == F68) begin 
      // Send some H2D_Req txns in each slot of each flit (N*4 total txns in N*4 flits)
      `uvm_info("TSTINFO", "Sending H2D_Req txns", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.h2c_mst.api68.issue_msg(h2dreq,, 0, ii);
        env.h2c_mst.api68.issue_msg(h2dreq,, 1, ii);
        env.h2c_mst.api68.issue_msg(h2dreq,, 2, ii);
        env.h2c_mst.api68.issue_msg(h2dreq,, 3, ii);
      end
      // Send some H2D_Dat txns in each slot of each flit (64B) (N*4 txns in N*4*2 flits)
      h2ddat.txfer_64B = 1'b1;
      `uvm_info("TSTINFO", "Sending H2D_Dat txns (64B)", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.h2c_mst.api68.issue_msg(h2ddat,, 0, ii);
        env.h2c_mst.api68.issue_msg(h2ddat,, 1, ii);
        env.h2c_mst.api68.issue_msg(h2ddat,, 2, ii);
        env.h2c_mst.api68.issue_msg(h2ddat,, 3, ii);
      end
      // Send some H2D_Dat txns in each slot of each flit (32B)
      h2ddat.txfer_64B = 1'b0;
      `uvm_info("TSTINFO", "Sending H2D_Dat txns (32B)", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.h2c_mst.api68.issue_msg(h2ddat,, 0, ii);
        env.h2c_mst.api68.issue_msg(h2ddat,, 1, ii);
        env.h2c_mst.api68.issue_msg(h2ddat,, 2, ii);
        env.h2c_mst.api68.issue_msg(h2ddat,, 3, ii);
      end
      // Send some H2D_Rsp txns in each slot of each flit
      for (int ii=0; ii<N; ii++) begin
      `uvm_info("TSTINFO", "Sending H2D_Rsp txns", UVM_LOW)
        env.h2c_mst.api68.issue_msg(h2drsp,, 0, ii);
        env.h2c_mst.api68.issue_msg(h2drsp,, 1, ii);
        env.h2c_mst.api68.issue_msg(h2drsp,, 2, ii);
        env.h2c_mst.api68.issue_msg(h2drsp,, 3, ii);
      end
    end
    /* 256B FLIT MODE */
    else if (MODE == F256) begin
      // Use the api to pack a transaction in any slot
      repeat (32) env.h2c_mst.api256.issue_msg(h2dreq, -2);
      repeat (32) env.h2c_mst.api256.issue_msg(h2ddat, -2);
      repeat (32) env.h2c_mst.api256.issue_msg(h2drsp, -2);
    end
    #20;
    phase.drop_objection(this);
  endtask

endclass
