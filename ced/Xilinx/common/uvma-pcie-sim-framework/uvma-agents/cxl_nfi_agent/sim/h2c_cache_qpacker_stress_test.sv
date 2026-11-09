class h2c_cache_qpacker_stress_test extends base_test;

  `uvm_component_utils(h2c_cache_qpacker_stress_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  rand int unsigned cnt_h2dreq;
  rand int unsigned cnt_h2drsp;
  rand int unsigned cnt_h2ddat;

  constraint c {
    cnt_h2dreq inside {[30:70]};
    cnt_h2drsp inside {[30:70]};
    cnt_h2ddat inside {[30:70]};
  }

  function void start_of_simulation_phase(uvm_phase phase);
    // Disable split 32B transactions, which the below
    // sequence does not support
    env.h2c_mst_cfg.split_32B_disable = 1'b1;
  endfunction

  virtual task run_phase(uvm_phase phase);

    // CXL.cache transactions (H2D = Host-to-Device)
    h2dreq_c    h2dreq;
    h2drsp_c    h2drsp;
    h2ddat_c    h2ddat;

    super.run_phase(phase);
    phase.raise_objection(this);

    #20;

    // Jam a bunch of transactions into the queues 20x
    for (int ii=0; ii<20; ii++) begin

      void'(this.randomize);

      fork
        // CXL.cache: REQ
        for (int aa=0; aa<cnt_h2dreq; aa++) begin
          h2dreq = h2dreq_c::type_id::create("h2dreq");
          h2dreq.flitmode   = MODE;
          if (MODE == F256) h2dreq.req256.val = 1'b1;
          else              h2dreq.req68.val  = 1'b1;
          env.h2c_mst.write_txn_q(h2dreq);
        end
        // CXL.cache: DAT
        for (int bb=0; bb<cnt_h2ddat; bb++) begin
          h2ddat = h2ddat_c::type_id::create("h2ddat");
          h2ddat.flitmode   = MODE;
          if (MODE == F256) h2ddat.hdr256.val = 1'b1;
          else              h2ddat.hdr68.val  = 1'b1;
          env.h2c_mst.write_txn_q(h2ddat);
        end
        // CXL.cache: RSP
        for (int cc=0; cc<cnt_h2drsp; cc++) begin
          h2drsp = h2drsp_c::type_id::create("h2drsp");
          h2drsp.flitmode   = MODE;
          if (MODE == F256) h2drsp.rsp256.val = 1'b1;
          else              h2drsp.rsp68.val  = 1'b1;
          env.h2c_mst.write_txn_q(h2drsp);
        end
      join

      `uvm_info(get_type_name, $sformatf("Iteration %0d | queues full with: H2DREQ=%0d, H2DDAT=%0d, H2DRSP=%0d", ii, cnt_h2dreq, cnt_h2ddat, cnt_h2drsp), UVM_NONE)

      `uvm_info(get_type_name, "Waiting until queues are all empty", UVM_NONE)

      while (1) begin
        env.h2c_mst.sqr.wait_cycles(5);
        if (env.h2c_mst.shr.qs_empty) break;
      end

    end

    phase.drop_objection(this);
  endtask

endclass
