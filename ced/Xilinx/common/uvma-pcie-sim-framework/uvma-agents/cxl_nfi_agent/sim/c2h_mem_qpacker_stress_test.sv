class c2h_mem_qpacker_stress_test extends base_test;

  `uvm_component_utils(c2h_mem_qpacker_stress_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  rand int unsigned cnt_s2mndr;
  rand int unsigned cnt_s2mdrs;
  rand int unsigned cnt_s2mbisnp;

  constraint c {
    cnt_s2mndr  inside {[30:70]};
    cnt_s2mdrs  inside {[30:70]};
    MODE==F68  -> cnt_s2mbisnp==0;
    MODE==F256 -> cnt_s2mbisnp inside {[30:70]};
  }

  function void start_of_simulation_phase(uvm_phase phase);
    // Disable split 32B transactions, which the below
    // sequence does not support
    env.c2h_mst_cfg.split_32B_disable = 1'b1;
  endfunction

  virtual task run_phase(uvm_phase phase);

    // CXL.mem transactions (S2M = Subordinate-to-Master)
    s2mndr_c    s2mndr;
    s2mdrs_c    s2mdrs;
    s2mbisnp_c  s2mbisnp;

    super.run_phase(phase);
    phase.raise_objection(this);

    #20;

    // Jam a bunch of transactions into the queues 20x
    for (int ii=0; ii<20; ii++) begin

      void'(this.randomize);

      fork
        // CXL.mem: REQ 
        for (int aa=0; aa<cnt_s2mbisnp; aa++) begin
          s2mbisnp = s2mbisnp_c::type_id::create("s2mbisnp");
          s2mbisnp.flitmode     = MODE;
          s2mbisnp.bisnp256.val = 1'b1;
          env.c2h_mst.write_txn_q(s2mbisnp);
        end
        // CXL.mem: DAT
        for (int bb=0; bb<cnt_s2mdrs; bb++) begin
          s2mdrs = s2mdrs_c::type_id::create("s2mdrs");
          s2mdrs.flitmode = MODE;
          s2mdrs.c_noemd.constraint_mode(1);
          if (MODE == F256) s2mdrs.hdr256.val = 1'b1;
          else              s2mdrs.hdr68.val  = 1'b1;
          env.c2h_mst.write_txn_q(s2mdrs);
        end
        // CXL.mem: RSP
        for (int cc=0; cc<cnt_s2mndr; cc++) begin
          s2mndr = s2mndr_c::type_id::create("s2mndr");
          s2mndr.flitmode = MODE;
          if (MODE == F256) s2mndr.ndr256.val = 1'b1;
          else              s2mndr.ndr68.val  = 1'b1;
          env.c2h_mst.write_txn_q(s2mndr);
        end
      join

      if (MODE==F256)
        `uvm_info(get_type_name, $sformatf("Iteration %0d | queues full with: S2MBISNP=%0d, S2MDRS=%0d, S2MNDR=%0d", ii, cnt_s2mbisnp, cnt_s2mdrs, cnt_s2mndr), UVM_NONE)
      else
        `uvm_info(get_type_name, $sformatf("Iteration %0d | queues full with: S2MDRS=%0d, S2MNDR=%0d", ii, cnt_s2mdrs, cnt_s2mndr), UVM_NONE)

      `uvm_info(get_type_name, "Waiting until queues are all empty", UVM_NONE)

      while (1) begin
        env.c2h_mst.sqr.wait_cycles(5);
        if (env.c2h_mst.shr.qs_empty) break;
      end

    end

    phase.drop_objection(this);
  endtask

endclass
