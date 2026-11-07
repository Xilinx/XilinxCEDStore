class c2h_cache_qpacker_stress_test extends base_test;

  `uvm_component_utils(c2h_cache_qpacker_stress_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  rand int unsigned cnt_d2hreq;
  rand int unsigned cnt_d2hrsp;
  rand int unsigned cnt_d2hdat;

  rand bit [1:0] d2hdat_be_sel;

  constraint c {
    cnt_d2hreq inside {[30:70]};
    cnt_d2hrsp inside {[30:70]};
    cnt_d2hdat inside {[30:70]};
    d2hdat_be_sel != 3;
  }

  function void start_of_simulation_phase(uvm_phase phase);
    // Disable split 32B transactions, which the below
    // sequence does not support
    env.c2h_mst_cfg.split_32B_disable = 1'b1;
  endfunction

  virtual task run_phase(uvm_phase phase);

    // CXL.cache transactions (D2H = Device-to-Host)
    d2hreq_c    d2hreq;
    d2hrsp_c    d2hrsp;
    d2hdat_c    d2hdat;

    super.run_phase(phase);
    phase.raise_objection(this);

    #20;

    // Jam a bunch of transactions into the queues 20x
    for (int ii=0; ii<20; ii++) begin

      cnt_d2hreq.rand_mode(1);
      cnt_d2hrsp.rand_mode(1);
      cnt_d2hdat.rand_mode(1);

      void'(this.randomize);

      cnt_d2hreq.rand_mode(0);
      cnt_d2hrsp.rand_mode(0);
      cnt_d2hdat.rand_mode(0);

      fork
        // CXL.cache: REQ
        for (int aa=0; aa<cnt_d2hreq; aa++) begin
          d2hreq = d2hreq_c::type_id::create("d2hreq");
          d2hreq.flitmode    = MODE;
          if (MODE == F256) d2hreq.req256.val = 1'b1;
          else              d2hreq.req68.val  = 1'b1;
          env.c2h_mst.write_txn_q(d2hreq);
        end
        // CXL.cache: DAT
        for (int bb=0; bb<cnt_d2hdat; bb++) begin
          d2hdat = d2hdat_c::type_id::create("d2hdat");
          d2hdat.flitmode   = MODE;
          // Randomly select BE presence before putting in queue
          void'(this.randomize);
          case (d2hdat_be_sel)
            0 : d2hdat.be = '1; //no BE necessary 
            1 : d2hdat.be = '0; //BE necessary 
            2 : /*qpacker will randomize*/ ;
          endcase
          if (MODE == F256) d2hdat.hdr256.val = 1'b1;
          else              d2hdat.hdr68.val  = 1'b1;
          env.c2h_mst.write_txn_q(d2hdat);
        end
        // CXL.cache: RSP
        for (int cc=0; cc<cnt_d2hrsp; cc++) begin
          d2hrsp = d2hrsp_c::type_id::create("d2hrsp");
          d2hrsp.flitmode   = MODE;
          if (MODE == F256) d2hrsp.rsp256.val = 1'b1;
          else              d2hrsp.rsp68.val  = 1'b1;
          env.c2h_mst.write_txn_q(d2hrsp);
        end
      join

      `uvm_info(get_type_name, $sformatf("Iteration %0d | queues full with: D2HREQ=%0d, D2HDAT=%0d, D2HRSP=%0d", ii, cnt_d2hreq, cnt_d2hdat, cnt_d2hrsp), UVM_NONE)

      `uvm_info(get_type_name, "Waiting until queues are all empty", UVM_NONE)

      while (1) begin
        env.c2h_mst.sqr.wait_cycles(5);
        if (env.c2h_mst.shr.qs_empty) break;
      end

    end

    phase.drop_objection(this);
  endtask

endclass
