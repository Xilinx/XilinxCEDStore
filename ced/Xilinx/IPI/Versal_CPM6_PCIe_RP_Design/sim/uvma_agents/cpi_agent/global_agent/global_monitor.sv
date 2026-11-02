class global_monitor#(type CFG, type VIF, type TXN, type SHR) extends base_monitor#(CFG,VIF,TXN,SHR);

  `uvm_component_param_utils(global_monitor#(CFG,VIF,TXN,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"global_monitor#(",
                                   CFG::type_name,",",
                                   "VIF,",
                                   TXN::type_name,",",
                                   SHR::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  uvm_analysis_port #(TXN) empty_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    empty_ap = new("empty_ap", this);
  endfunction

  virtual task run_phase(uvm_phase phase); 

    TXN itxn, rtxn, etxn; //init txn, ras txn, empty txn
    base_txn btxn[2]; 
    bit last_fatal, last_viral, last_rx_empty;
    bit broadcast_txn;
    bit rx_empty_met;

    vif.viral_en = cfg.viral_en;
    vif.fatal_en = cfg.fatal_en;

    fork 
      begin : init_txn_mon
        itxn = TXN::type_id::create("itxn");
        btxn[0] = itxn;
        itxn.uid = cfg.uid;
        itxn.append_uid = cfg.append_uid;
        itxn.info = "INIT";
        itxn.info2 = cfg.a2f ? "A2F" : "F2A";
        itxn.init = 1'b1;
        if (cfg.skip_glbl_connection)
          shr.conn_state = CONNECTED;
        else begin
          forever begin 
            @(vif.cb);
            // Detect any state changes
            if (shr.conn_state == DISCONNECTED && vif.txcon_req) begin
              broadcast_txn = 1'b1; 
              {itxn.conn_state, shr.conn_state} = {2{CONNECTING}};
              sample_vif(itxn);
            end
            else if (shr.conn_state == CONNECTING && vif.rxcon_ack) begin
              broadcast_txn = 1'b1; 
              {itxn.conn_state, shr.conn_state} = {2{CONNECTED}};
              sample_vif(itxn);
            end
            else if (shr.conn_state == CONNECTED && !vif.txcon_req) begin
              broadcast_txn = 1'b1; 
              {itxn.conn_state, shr.conn_state} = !vif.rxdiscon_nack ? {2{DISCONNECTING}} : {2{ILLEGAL}};
              sample_vif(itxn);
            end
            else if (shr.conn_state == DISCONNECTING && vif.rxdiscon_nack) begin
              broadcast_txn = 1'b1; 
              {itxn.conn_state, shr.conn_state} = {2{DENY}};
              sample_vif(itxn);
            end
            else if (shr.conn_state == DENY && vif.txcon_req) begin
              broadcast_txn = 1'b1; 
              {itxn.conn_state, shr.conn_state} = {2{CONNECTED}};
              sample_vif(itxn);
            end
            else if (shr.conn_state == DISCONNECTING && !vif.rxcon_ack) begin
              broadcast_txn = 1'b1; 
              {itxn.conn_state, shr.conn_state} = {2{DISCONNECTED}};
              sample_vif(itxn);
            end
            if (broadcast_txn) begin
              ap.write(itxn);
              base_ap.write(btxn[0]);
              broadcast_txn = 1'b0;
              sample_vif(itxn);
            end
          end
        end
      end
      begin : ras_txn_mon
        wait(vif.fatal === 1'b0 && vif.viral === 1'b0);
        rtxn = TXN::type_id::create("rtxn");
        btxn[1] = rtxn;
        rtxn.uid = cfg.uid;
        rtxn.append_uid = cfg.append_uid;
        rtxn.info = "RAS";
        rtxn.info2 = cfg.a2f ? "A2F" : "F2A";
        rtxn.ras = 1'b1;
        forever begin 
          // Detect ANY viral change and POSEDGE fatal
          @(vif.cb iff (^{last_viral, vif.viral} || {!last_fatal && vif.fatal}));
          rtxn.viral = vif.viral;
          rtxn.fatal = vif.fatal;
          ap.write(rtxn);
          base_ap.write(btxn[1]);
          last_viral = vif.viral;
          last_fatal = vif.fatal;
        end
      end
      if (cfg.is_active && cfg.is_slave) begin : empty_txn_mon
        wait(vif.rx_empty === 1'b0);
        etxn = TXN::type_id::create("etxn");
        etxn.uid = cfg.uid;
        etxn.append_uid = cfg.append_uid;
        etxn.info = "INIT";
        etxn.info2 = cfg.a2f ? "A2F" : "F2A";
        {etxn.init, etxn.empty} = 2'b11;
        forever begin
          @(vif.cb);
          if (!shr.total_credits_mark_req && !shr.total_credits_mark_rsp && !shr.total_credits_mark_data) begin
            `uvm_error(get_type_name, "No credit qualifications for rx_empty have been provided")
            break;
          end
          rx_empty_met = (shr.total_credits_mark_req  == shr.total_credits_cnt_req ) &&
                         (shr.total_credits_mark_rsp  == shr.total_credits_cnt_rsp ) &&
                         (shr.total_credits_mark_data == shr.total_credits_cnt_data);
          if (last_rx_empty^rx_empty_met) begin
            etxn.rx_empty = rx_empty_met;
            empty_ap.write(etxn);
          end
        end 
      end
    join

  endtask

  virtual function void sample_vif(TXN t);
    t.txcon_req     = vif.txcon_req;
    t.rxcon_ack     = vif.rxcon_ack;
    t.rxdiscon_nack = vif.rxdiscon_nack;
    t.rx_empty      = vif.rx_empty;
  endfunction

endclass
