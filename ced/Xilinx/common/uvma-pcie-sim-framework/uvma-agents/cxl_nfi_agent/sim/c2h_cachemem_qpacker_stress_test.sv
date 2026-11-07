class c2h_cachemem_qpacker_stress_test extends base_test;

  `uvm_component_utils(c2h_cachemem_qpacker_stress_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  rand int unsigned cnt_d2hreq;
  rand int unsigned cnt_d2hrsp;
  rand int unsigned cnt_d2hdat;
  rand int unsigned cnt_s2mndr;
  rand int unsigned cnt_s2mdrs;
  rand int unsigned cnt_s2mbisnp;

  rand bit [1:0] d2hdat_be_sel;

  constraint c {
    cnt_d2hreq inside {[30:70]};
    cnt_d2hrsp inside {[30:70]};
    cnt_d2hdat inside {[30:70]};
    cnt_s2mndr inside {[30:70]};
    cnt_s2mdrs inside {[30:70]};
    MODE==F68  -> cnt_s2mbisnp==0;
    MODE==F256 -> cnt_s2mbisnp inside {[30:70]};
  }

  function void start_of_simulation_phase(uvm_phase phase);
    // Disable split 32B transactions, which the below
    // sequence does not support
    env.c2h_mst_cfg.split_32B_disable = 1'b1;
  endfunction

  virtual task run_phase(uvm_phase phase);

    // Command Line Arguments
    bit EN_SPECIFIED_D2HDAT_BE;
    bit EN_FORCE_D2HDAT_NO_BE;
    bit EN_FORCE_D2HDAT_BE;

    // CXL.cache transactions (D2H = Device-to-Host)
    d2hreq_c    d2hreq; 
    d2hrsp_c    d2hrsp;
    d2hdat_c    d2hdat;

    // CXL.mem transactions (S2M = Subordinate-to-Master)
    s2mndr_c    s2mndr;
    s2mdrs_c    s2mdrs;
    s2mbisnp_c  s2mbisnp;

    super.run_phase(phase);
    phase.raise_objection(this);

    #20;

    // Jam a bunch of transactions into the queues 20x
    for (int ii=0; ii<20; ii++) begin

      cnt_d2hreq.rand_mode(1);
      cnt_d2hrsp.rand_mode(1);
      cnt_d2hdat.rand_mode(1);
      cnt_s2mndr.rand_mode(1);
      cnt_s2mdrs.rand_mode(1);
      cnt_s2mbisnp.rand_mode(1);

      void'(this.randomize);

      cnt_d2hreq.rand_mode(0);
      cnt_d2hrsp.rand_mode(0);
      cnt_d2hdat.rand_mode(0);
      cnt_s2mndr.rand_mode(0);
      cnt_s2mdrs.rand_mode(0);
      cnt_s2mbisnp.rand_mode(0);

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
        // CXL.mem: REQ
        for (int dd=0; dd<cnt_s2mbisnp; dd++) begin
          s2mbisnp = s2mbisnp_c::type_id::create("s2mbisnp");
          s2mbisnp.flitmode     = MODE;
          s2mbisnp.bisnp256.val = 1'b1;
          env.c2h_mst.write_txn_q(s2mbisnp);
        end
        // CXL.mem: DAT
        for (int ee=0; ee<cnt_s2mdrs; ee++) begin
          s2mdrs = s2mdrs_c::type_id::create("s2mdrs");
          s2mdrs.flitmode = MODE;
          s2mdrs.c_noemd.constraint_mode(1);
          if (MODE == F256) s2mdrs.hdr256.val = 1'b1;
          else              s2mdrs.hdr68.val  = 1'b1;
          env.c2h_mst.write_txn_q(s2mdrs);
        end
        // CXL.mem: RSP
        for (int ff=0; ff<cnt_s2mndr; ff++) begin
          s2mndr = s2mndr_c::type_id::create("s2mndr");
          s2mndr.flitmode = MODE;
          if (MODE == F256) s2mndr.ndr256.val = 1'b1;
          else              s2mndr.ndr68.val  = 1'b1;
          env.c2h_mst.write_txn_q(s2mndr);
        end
      join

      if (MODE==F256)
        `uvm_info(get_type_name, $sformatf("Iteration %0d | queues full with: D2HREQ=%0d, D2HDAT=%0d, D2HRSP=%0d, S2MBISNP=%0d, S2MDRS=%0d, S2MNDR=%0d",ii, cnt_d2hreq, cnt_d2hdat, cnt_d2hrsp, cnt_s2mbisnp, cnt_s2mdrs, cnt_s2mndr), UVM_NONE)
      else
        `uvm_info(get_type_name, $sformatf("Iteration %0d | queues full with: D2HREQ=%0d, D2HDAT=%0d, D2HRSP=%0d, S2MDRS=%0d, S2MNDR=%0d",ii, cnt_d2hreq, cnt_d2hdat, cnt_d2hrsp, cnt_s2mdrs, cnt_s2mndr), UVM_NONE)

      `uvm_info(get_type_name, "Waiting until queues are all empty", UVM_NONE)

      while (1) begin
        env.c2h_mst.sqr.wait_cycles(5);
        if (env.c2h_mst.shr.qs_empty) break;
      end

    end

    phase.drop_objection(this);
  endtask

endclass
