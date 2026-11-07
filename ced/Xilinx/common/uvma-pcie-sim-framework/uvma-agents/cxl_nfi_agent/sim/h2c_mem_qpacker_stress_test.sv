class h2c_mem_qpacker_stress_test extends base_test;

  `uvm_component_utils(h2c_mem_qpacker_stress_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  rand int unsigned cnt_m2sreq;
  rand int unsigned cnt_m2srwd;
  rand int unsigned cnt_m2sbirsp;

  constraint c {
    cnt_m2sreq  inside {[30:70]};
    cnt_m2srwd  inside {[30:70]};
    MODE==F68  -> cnt_m2sbirsp==0;
    MODE==F256 -> cnt_m2sbirsp inside {[30:70]};
  }

  function void start_of_simulation_phase(uvm_phase phase);
    // Disable split 32B transactions, which the below
    // sequence does not support
    env.h2c_mst_cfg.split_32B_disable = 1'b1;
  endfunction

  virtual task run_phase(uvm_phase phase);

    // CXL.mem transactions (M2S = Master-to-Subordinate)
    m2sreq_c    m2sreq;
    m2srwd_c    m2srwd;
    m2sbirsp_c  m2sbirsp;

    super.run_phase(phase);
    phase.raise_objection(this);

    #20;

    // Jam a bunch of transactions into the queues 20x
    for (int ii=0; ii<20; ii++) begin

      void'(this.randomize);

      fork
        // CXL.mem: REQ
        for (int aa=0; aa<cnt_m2sreq; aa++) begin
          m2sreq = m2sreq_c::type_id::create("m2sreq");
          m2sreq.flitmode    = MODE;
          if (MODE == F256) m2sreq.req256.val = 1'b1;
          else              m2sreq.req68.val  = 1'b1;
          env.h2c_mst.write_txn_q(m2sreq);
        end
        // CXL.mem: DAT
        for (int bb=0; bb<cnt_m2srwd; bb++) begin
          m2srwd = m2srwd_c::type_id::create("m2srwd");
          m2srwd.flitmode = MODE;
          m2srwd.c_noemd.constraint_mode(1);
          if (MODE == F256) m2srwd.hdr256.val = 1'b1;
          else              m2srwd.hdr68.val  = 1'b1;
          env.h2c_mst.write_txn_q(m2srwd);
        end
        // CXL.mem: RSP (F256 only — M2SBIRSP has no F68 equivalent)
        for (int cc=0; cc<cnt_m2sbirsp; cc++) begin
          m2sbirsp = m2sbirsp_c::type_id::create("m2sbirsp");
          m2sbirsp.flitmode     = MODE;
          m2sbirsp.birsp256.val = 1'b1;
          env.h2c_mst.write_txn_q(m2sbirsp);
        end
      join

      if (MODE==F256)
        `uvm_info(get_type_name, $sformatf("Iteration %0d | queues full with: M2SBIRSP=%0d, M2SRWD=%0d, M2SREQ=%0d", ii, cnt_m2sbirsp, cnt_m2srwd, cnt_m2sreq), UVM_NONE)
      else
        `uvm_info(get_type_name, $sformatf("Iteration %0d | queues full with: M2SRWD=%0d, M2SREQ=%0d", ii, cnt_m2srwd, cnt_m2sreq), UVM_NONE)

      `uvm_info(get_type_name, "Waiting until queues are all empty", UVM_NONE)

      while (1) begin
        env.h2c_mst.sqr.wait_cycles(5);
        if (env.h2c_mst.shr.qs_empty) break;
      end

    end

    phase.drop_objection(this);
  endtask

endclass
