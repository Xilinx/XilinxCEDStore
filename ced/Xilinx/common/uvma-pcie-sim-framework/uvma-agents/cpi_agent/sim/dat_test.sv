class dat_test extends base_test;

  `uvm_component_utils(dat_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    data_agent_pkg::hdr_u hdr;
    super.run_phase(phase);
    phase.raise_objection(this);
    // Drive a mem transaction on each CPI DATA channel using a shared credit
    foreach (env.mst.data[ii]) begin
      if (env.mst.data[ii] == null) break;
      env.mst.data[ii].api.issue_msg(MEM, .shared_credit(1));
    end
    // Drive a mem transaction on each CPI DATA channel using a dedicated credit
    foreach (env.mst.data[ii]) begin
      if (env.mst.data[ii] == null) break;
      env.mst.data[ii].api.issue_msg(MEM, .shared_credit(0));
    end
    // Drive a cache transaction on each CPI DATA channel using a shared credit
    foreach (env.mst.data[ii]) begin
      if (env.mst.data[ii] == null) break;
      env.mst.data[ii].api.issue_msg(CACHE, .shared_credit(1));
    end
    // Drive a cache transaction on each CPI DATA channel using a dedicated credit
    foreach (env.mst.data[ii]) begin
      if (env.mst.data[ii] == null) break;
      env.mst.data[ii].api.issue_msg(CACHE, .shared_credit(0));
    end

    // Show how to specify a specific field of a header
    case ({env.mst_cfg.port, env.mst_cfg.a2f})
      {USP, 1'b1} : hdr.usp.a2fm.tag = 'hABCD;
      {DSP, 1'b0} : hdr.dsp.f2am.tag = 'hABCD;
      {DSP, 1'b1} : hdr.dsp.a2fm.tag = 'h4321;
      {USP, 1'b0} : hdr.usp.f2am.tag = 'h4321;
    endcase
    env.mst.data[0].api.issue_msg(MEM, .header(hdr), .shared_credit(1), .body('h9999777788886666), .byte_enable({8{8'h10}}));

    // cleanup
    wait_cycles(4);

    phase.drop_objection(this);
  endtask

endclass
