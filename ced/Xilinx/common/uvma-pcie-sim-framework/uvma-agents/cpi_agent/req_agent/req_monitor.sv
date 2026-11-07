class req_monitor#(type CFG, type VIF, type TXN, type SHR) extends base_monitor#(CFG,VIF,TXN,SHR);

  `uvm_component_param_utils(req_monitor#(CFG,VIF,TXN,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"req_monitor#(",
                                   CFG::type_name,",",
                                   "VIF,",
                                   TXN::type_name,",",
                                   SHR::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void connect_phase(uvm_phase phase);
    vif.a2f               = cfg.a2f;
    vif.blocking          = cfg.blocking;
    vif.req_cmd_parity_en = cfg.req_cmd_parity_en;
  endfunction

  virtual task run_phase(uvm_phase phase);
    TXN      ttxn, ctxn; //txfer txn, credit ret txn
    base_txn btxn[2];
    fork
      forever begin : txfer_txn_mon
        ttxn = req_txn::type_id::create("ttxn");
        btxn[0] = ttxn;
        ttxn.txfer = 1'b1;
        ttxn.uid = cfg.uid;
        ttxn.info = "TXFER";
        ttxn.info2 = cfg.a2f ? "A2F" : "F2A";
        ttxn.append_uid = cfg.append_uid;
        ttxn.req_cmd_parity_en = cfg.req_cmd_parity_en;
        ttxn.pbr_flit_mode_en  = cfg.pbr_flit_mode_en;
        ttxn.flit_mode_enc_en  = cfg.flit_mode_enc_en;
        @(vif.mcb iff vif.mcb.req_is_valid);
        ttxn.req_is_valid       = vif.mcb.req_is_valid; 
        ttxn.req_block          = vif.mcb.req_block; 
        ttxn.req_early_valid    = vif.mcb.req_early_valid;
        ttxn.req_protocol_id    = vif.mcb.req_protocol_id;
        ttxn.req_vc_id          = vif.mcb.req_vc_id;
        ttxn.req_shared_credit  = vif.mcb.req_shared_credit;
        ttxn.req_header         = vif.mcb.req_header;
        ttxn.req_cmd_parity     = vif.mcb.req_cmd_parity;
        ttxn.req_spid           = vif.mcb.req_spid;
        ttxn.req_dpid           = vif.mcb.req_dpid;
        // Credit decrementing here
        shr.gshr.total_credits_cnt_req--;
        if (vif.mcb.req_shared_credit) begin
          ttxn.credit_underflow = (shr.credit_cnt_shr == 0);
          if(shr.credit_cnt_shr)
            shr.credit_cnt_shr--;
        end
        else begin 
          ttxn.credit_underflow = (shr.credit_cnt_ded[vif.mcb.req_protocol_id[0]][vif.mcb.req_vc_id] == 0);
          if (shr.credit_cnt_ded[vif.mcb.req_protocol_id[0]][vif.mcb.req_vc_id])
            shr.credit_cnt_ded[vif.mcb.req_protocol_id[0]][vif.mcb.req_vc_id]--;
        end
        ap.write(ttxn);
        base_ap.write(btxn[0]);
      end
      forever begin : credrtn_txn_mon
        ctxn = req_txn::type_id::create("ctxn");
        btxn[1] = ctxn;
        ctxn.credrtn = 1'b1;
        ctxn.uid = cfg.uid;
        ctxn.info = "CREDIT_RETURN";
        ctxn.info2 = cfg.a2f ? "A2F" : "F2A";
        ctxn.append_uid = cfg.append_uid;
        @(vif.mcb iff (vif.mcb.req_rxcrd_valid || vif.mcb.req_rxcrd_shared));
        ctxn.req_rxcrd_valid       = vif.mcb.req_rxcrd_valid;
        ctxn.req_rxcrd_protocol_id = vif.mcb.req_rxcrd_protocol_id;
        ctxn.req_rxcrd_shared      = vif.mcb.req_rxcrd_shared;
        ctxn.req_rxcrd_vc_id       = vif.mcb.req_rxcrd_vc_id;
        ctxn.req_txblock_crd_flow  = vif.mcb.req_txblock_crd_flow;
        // Credit incrementing here
        #1; //trying to avoid race condition to detect underflow
        if (vif.mcb.req_rxcrd_shared) begin
          shr.credit_cnt_shr++;
          shr.gshr.total_credits_cnt_req++;
        end
        if (vif.mcb.req_rxcrd_valid) begin
          shr.credit_cnt_ded[vif.mcb.req_rxcrd_protocol_id[0]][vif.mcb.req_rxcrd_vc_id]++;
          shr.gshr.total_credits_cnt_req++;
        end
        ap.write(ctxn);
        base_ap.write(btxn[1]);
      end
    join_none
  endtask

endclass
