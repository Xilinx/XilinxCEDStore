class rsp_slv_base_seq extends uvm_sequence#(rsp_txn);

  `uvm_object_utils(rsp_slv_base_seq)
  `uvm_declare_p_sequencer(base_sequencer#(rsp_txn, rsp_txn, rsp_txn, rsp_cfg, rsp_share))

  rsp_init_crd_slv_seq init_seq;

  rand byte unsigned crd_ret_dly;

  int unsigned       low_ratio;
  int unsigned       med_ratio;
  int unsigned       hi_ratio;
  int unsigned       vhi_ratio;

  function new(string name = "rsp_slv_base_seq");
    super.new(name);
    init_seq = rsp_init_crd_slv_seq::type_id::create("init_seq");
  endfunction

  // - Skew the credit return ; a user can choose the skew by preset 
  //   or custom (*_ratio). Anything with more control can use an extended
  //   sequence
  // - There will be buckets for credit return delay:
  //   LOW : 0-7 cycles
  //   MED : 8-32 cycles
  //   HI  : 33-64 cycles
  //   VHI : 65-255 cycles
  constraint delay_dist { 
    p_sequencer.cfg.crd_ret_ctl==ASAP -> crd_ret_dly==0;
    p_sequencer.cfg.crd_ret_ctl==LO ->
      crd_ret_dly dist { [0:7] :/ 90, [8:32] :/  8, [33:64] :/ 2};
    p_sequencer.cfg.crd_ret_ctl==MED ->
      crd_ret_dly dist { [0:7] :/ 24, [8:32] :/ 50, [33:64] :/ 24, [65:255] :/ 2 };
    p_sequencer.cfg.crd_ret_ctl==HI  ->
      crd_ret_dly dist { [0:7] :/  2, [8:32] :/ 20, [33:64] :/ 50, [65:255] :/ 28 };
    p_sequencer.cfg.crd_ret_ctl==CUSTOM ->
      crd_ret_dly dist { [ 0:  7] :/ low_ratio,
                         [ 8: 32] :/ med_ratio,
                         [33: 64] :/ hi_ratio,
                         [65:255] :/ vhi_ratio};
  }

  // Handle credit initialization here
  virtual task pre_body();
    wait(p_sequencer.shr.gshr.conn_state == CONNECTED);
    if (p_sequencer.cfg.skip_credit_returns) begin
      init_seq.init_crd_done.trigger;
    end
    else
      init_seq.start(m_sequencer, this);
  endtask

  virtual task body();
    rsp_txn mtxn; //monitored txn from fifo
    rsp_txn rtxn; //response txn
    rsp_txn btxn; //blocking txn

    fork
      if (!p_sequencer.cfg.skip_credit_returns) begin
        forever begin
          p_sequencer.analysis_fifo.get(mtxn);
          // Drop all monitored credit returns, since that's what we're initiating
          if (mtxn.credrtn)
            continue;
          rtxn = rsp_txn::type_id::create("rtxn");  
          start_item(rtxn);
          rtxn.credrtn = 1'b1;
          rtxn.rsp_block = 1'b0;
          void'(this.randomize());
          rtxn.crd_ret_dly = crd_ret_dly;
          rtxn.rsp_rxcrd_shared      = mtxn.rsp_shared_credit ? 1 : 0;
          rtxn.rsp_rxcrd_valid       = mtxn.rsp_shared_credit ? 0 : 1;
          rtxn.rsp_rxcrd_protocol_id = mtxn.rsp_protocol_id;
          rtxn.rsp_rxcrd_vc_id       = mtxn.rsp_vc_id;
          finish_item(rtxn);
        end
      end
      if (p_sequencer.cfg.blocking) begin
        btxn = rsp_txn::type_id::create("btxn");
        btxn.rsp_block        = 1'b1;
        btxn.rsp_rxcrd_shared = 1'b0;
        btxn.rsp_rxcrd_valid  = 1'b0;
        forever begin
          start_item(btxn);
          btxn.crd_ret_dly = $urandom_range(10,50); //improve later
          finish_item(btxn);
        end
      end
    join

  endtask

endclass
