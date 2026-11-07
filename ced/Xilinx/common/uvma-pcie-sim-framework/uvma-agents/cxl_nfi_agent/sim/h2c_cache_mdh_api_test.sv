class h2c_cache_mdh_api_test extends base_test;

  `uvm_component_utils(h2c_cache_mdh_api_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    h2ddat_c h2ddat[0:3];
    foreach (h2ddat[ii]) begin 
      h2ddat[ii] = h2ddat_c::type_id::create($sformatf("h2ddat[%0d]",ii));
    end
    super.run_phase(phase);
    phase.raise_objection(this);
    #20;
    /* 68B FLIT MODE */
    if (MODE == F68) begin
      // Send an MDH with 2 H2D_Dat txns in each slot of each flit 
      `uvm_info("TSTINFO", "Sending MDH with 2 H2D_Dat txns in each slot of each flit", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.h2c_mst.api68.issue_msg_mdh(h2ddat[0:1], 0, ii);
        env.h2c_mst.api68.issue_msg_mdh(h2ddat[0:1], 1, ii);
        env.h2c_mst.api68.issue_msg_mdh(h2ddat[0:1], 2, ii);
        env.h2c_mst.api68.issue_msg_mdh(h2ddat[0:1], 3, ii);
      end
      // Send an MDH with 3 H2D_Dat txns in each slot of each flit 
      `uvm_info("TSTINFO", "Sending MDH with 3 H2D_Dat txns in each slot of each flit", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.h2c_mst.api68.issue_msg_mdh(h2ddat[0:2], 0, ii);
        env.h2c_mst.api68.issue_msg_mdh(h2ddat[0:2], 1, ii);
        env.h2c_mst.api68.issue_msg_mdh(h2ddat[0:2], 2, ii);
        env.h2c_mst.api68.issue_msg_mdh(h2ddat[0:2], 3, ii);
      end
      // Send an MDH with 4 H2D_Dat txns in each slot of each flit 
      `uvm_info("TSTINFO", "Sending MDH with 4 H2D_Dat txns in each slot of each flit", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.h2c_mst.api68.issue_msg_mdh(h2ddat, 0, ii);
        env.h2c_mst.api68.issue_msg_mdh(h2ddat, 1, ii);
        env.h2c_mst.api68.issue_msg_mdh(h2ddat, 2, ii);
        env.h2c_mst.api68.issue_msg_mdh(h2ddat, 3, ii);
      end
    end
    /* 256B FLIT MODE */
    else if (MODE == F256) begin
      // Use the api to pack a transaction in any slot
      repeat(16) env.h2c_mst.api256.issue_msg_mdh(h2ddat[0:1], -2);
      repeat(16) env.h2c_mst.api256.issue_msg_mdh(h2ddat[0:2], -2);
      repeat(16) env.h2c_mst.api256.issue_msg_mdh(h2ddat[0:3], -2);
    end
    #20;
    phase.drop_objection(this);
  endtask

  // Make sure driver sent what we think we sent
  virtual function void check_phase(uvm_phase phase);
    int exp = MODE==F68 ? (2+3+4)*4*N : 16*(2+3+4); 
    int act = env.h2c_mst.drv.total_dat_driven[0];
    if (act != exp)
      `uvm_error(get_type_name, $sformatf("Potential API error; expected driver to drive %0d txns but only drove %0d txns",exp,act))
  endfunction

endclass
