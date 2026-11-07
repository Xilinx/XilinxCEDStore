class c2h_mem_mdh_api_test extends base_test;

  `uvm_component_utils(c2h_mem_mdh_api_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    s2mdrs_c s2mdrs[0:2]; 
    foreach (s2mdrs[ii]) begin
      s2mdrs[ii] = s2mdrs_c::type_id::create($sformatf("s2mdrs[%0d]",ii));
    end
    super.run_phase(phase);
    phase.raise_objection(this);
    #20;
    /* 68B FLIT MODE */
    if (MODE == F68) begin
      // Send an MDH with 2 S2M_DRS txns in each slot of each flit
      `uvm_info("TSTINFO", "Sending MDH with 2 S2M_Dat txns in each slot of each flit", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.c2h_mst.api68.issue_msg_mdh(s2mdrs[0:1], 0, ii);
        env.c2h_mst.api68.issue_msg_mdh(s2mdrs[0:1], 1, ii);
        env.c2h_mst.api68.issue_msg_mdh(s2mdrs[0:1], 2, ii);
        env.c2h_mst.api68.issue_msg_mdh(s2mdrs[0:1], 3, ii);
      end
      // Send an MDH with 3 S2M_DRS txns in each generic slot of each flit
      `uvm_info("TSTINFO", "Sending MDH with 3 S2M_Dat txns in each Gslot of each flit", UVM_LOW)
      for (int ii=0; ii<N; ii++) begin
        env.c2h_mst.api68.issue_msg_mdh(s2mdrs, 1, ii);
        env.c2h_mst.api68.issue_msg_mdh(s2mdrs, 2, ii);
        env.c2h_mst.api68.issue_msg_mdh(s2mdrs, 3, ii);
      end
    end
    /* 256B FLIT MODE */
    else if (MODE == F256) begin
      repeat (16) env.c2h_mst.api256.issue_msg_mdh(s2mdrs[0:1], -2);
      repeat (16) env.c2h_mst.api256.issue_msg_mdh(s2mdrs[0:2], -2);
    end
    #20;
    phase.drop_objection(this);
  endtask

  // Make sure driver sent what we think we sent
  virtual function void check_phase(uvm_phase phase);
    int exp = MODE==F68 ? (2*4*N)+(3*3*N) : 16*(2+3);
    int act = env.c2h_mst.drv.total_dat_driven[1];
    if (act != exp)
      `uvm_error(get_type_name, $sformatf("Potential API error; expected driver to drive %0d txns but drove %0d txns",exp,act))
  endfunction

endclass
