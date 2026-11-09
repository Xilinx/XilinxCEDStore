class data_monitor#(type CFG, type VIF, type TXN, type SHR) extends base_monitor#(CFG,VIF,TXN,SHR);

  `uvm_component_param_utils(data_monitor#(CFG,VIF,TXN,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"data_monitor#(",
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
    vif.blocking           = cfg.blocking;
    vif.a2f                = cfg.a2f;
    vif.txfer_32b_en       = cfg.txfer_32b_en;
    vif.data_cmd_parity_en = cfg.data_cmd_parity_en;
    vif.data_be_parity_en  = cfg.data_be_parity_en;
  endfunction

  virtual task run_phase(uvm_phase phase);
    TXN      ttxn, ctxn; //txfer txn, credit ret txn
    base_txn btxn[2];
    fork
      forever begin : txfer_txn_mon
        ttxn = data_txn::type_id::create("ttxn");
        btxn[0] = ttxn;
        ttxn.txfer = 1'b1; 
        ttxn.uid = cfg.uid;
        ttxn.info = "TXFER";
        ttxn.info2 = cfg.a2f ? "A2F" : "F2A";
        ttxn.append_uid = cfg.append_uid;
        ttxn.data_cmd_parity_en = cfg.data_cmd_parity_en;
        ttxn.data_be_parity_en  = cfg.data_be_parity_en;
        ttxn.pbr_flit_mode_en   = cfg.pbr_flit_mode_en;
        ttxn.flit_mode_enc_en   = cfg.flit_mode_enc_en;
        ttxn.emd_bits           = cfg.emd_bits;
        @(vif.mcb iff vif.mcb.data_is_valid);
        ttxn.data_is_valid           = vif.mcb.data_is_valid; 
        ttxn.data_block              = vif.mcb.data_block; 
        ttxn.data_early_valid        = vif.mcb.data_early_valid;
        ttxn.data_protocol_id        = vif.mcb.data_protocol_id;
        ttxn.data_vc_id              = vif.mcb.data_vc_id;
        ttxn.data_shared_credit      = vif.mcb.data_shared_credit;
        ttxn.data_header             = vif.mcb.data_header;
        ttxn.data_sz                 = vif.mcb.data_sz;
        ttxn.data_cmd_parity         = vif.mcb.data_cmd_parity;
        ttxn.data_spid               = vif.mcb.data_spid;
        ttxn.data_dpid               = vif.mcb.data_dpid;
        ttxn.data_body               = vif.mcb.data_body;
        ttxn.data_byte_enable        = vif.mcb.data_byte_enable;
        ttxn.data_byte_enable_parity = vif.mcb.data_byte_enable_parity;
        ttxn.data_poison             = vif.mcb.data_poison;
        ttxn.data_parity             = vif.mcb.data_parity;
        ttxn.data_eop                = vif.mcb.data_eop;
        ttxn.data_emd                = vif.mcb.data_emd;
        // Credit decrementing here
        shr.gshr.total_credits_cnt_data--;
        if (vif.mcb.data_shared_credit) begin
          ttxn.credit_underflow = (shr.credit_cnt_shr == 0);
          if (shr.credit_cnt_shr)
            shr.credit_cnt_shr--;
        end
        else begin
          ttxn.credit_underflow = (shr.credit_cnt_ded[vif.mcb.data_protocol_id[0]][vif.mcb.data_vc_id] == 0);
          if (shr.credit_cnt_ded[vif.mcb.data_protocol_id[0]][vif.mcb.data_vc_id])
            shr.credit_cnt_ded[vif.mcb.data_protocol_id[0]][vif.mcb.data_vc_id]--;
        end
        ap.write(ttxn);
        base_ap.write(btxn[0]);
      end
      forever begin : credrtn_txn_mon
        ctxn = data_txn::type_id::create("ctxn");
        btxn[1] = ctxn;
        ctxn.credrtn = 1'b1;
        ctxn.uid = cfg.uid;
        ctxn.info = "CREDIT_RETURN";
        ctxn.info2 = cfg.a2f ? "A2F" : "F2A";
        ctxn.append_uid = cfg.append_uid;
        @(vif.mcb iff (vif.mcb.data_rxcrd_valid || vif.mcb.data_rxcrd_shared));
        ctxn.data_rxcrd_valid       = vif.mcb.data_rxcrd_valid;
        ctxn.data_rxcrd_protocol_id = vif.mcb.data_rxcrd_protocol_id;
        ctxn.data_rxcrd_shared      = vif.mcb.data_rxcrd_shared;
        ctxn.data_rxcrd_vc_id       = vif.mcb.data_rxcrd_vc_id;
        ctxn.data_txblock_crd_flow  = vif.mcb.data_txblock_crd_flow;
        ap.write(ctxn);
        base_ap.write(btxn[1]);
        // Credit incrementing here
        #1; //trying to avoid race condition to detect underflow
        if (vif.mcb.data_rxcrd_shared) begin
          shr.credit_cnt_shr++;
          shr.gshr.total_credits_cnt_data++;
        end
        if (vif.mcb.data_rxcrd_valid) begin
          shr.credit_cnt_ded[vif.mcb.data_rxcrd_protocol_id[0]][vif.mcb.data_rxcrd_vc_id]++;
          shr.gshr.total_credits_cnt_data++;
        end
      end
    join
  endtask

endclass
