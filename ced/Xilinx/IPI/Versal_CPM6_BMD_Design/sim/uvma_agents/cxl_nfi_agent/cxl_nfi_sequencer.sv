// Note : analysis_fifo txns must extend from base_txn, then if one wants to get
//        one out of the FIFO, they will have to cast it
class cxl_nfi_sequencer#(parameter NFI_W) extends base_sequencer#(cxl_nfi_txn#(NFI_W), 
                                                                  cxl_nfi_txn#(NFI_W), 
                                                                  base_txn,
                                                                  cxl_nfi_cfg, 
                                                                  cxl_nfi_share);

  `uvm_component_param_utils(cxl_nfi_sequencer#(NFI_W))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("cxl_nfi_sequencer#(%0d)",NFI_W);
  virtual function string get_type_name(); return type_name; endfunction

  virtual cxl_nfi_agent_if#(NFI_W) vif;

  uvm_analysis_port#(cxl_nfi_credit_txn) cred_ret_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cred_ret_ap = new("cred_ret_ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual cxl_nfi_agent_if#(NFI_W))::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name, "Failed to get 'vif' from config db")
  endfunction

  virtual task wait_cycles(int n);
    repeat(n) @(vif.mcb);
  endtask

  // Check if there are ANY credits
  virtual function bit check_any_credits();
    return (check_cch_credits(ANYC) || 
            check_mem_credits(ANYC, cfg.dir, cfg.flitmode inside {[F256:FPBR]} && cfg.cxl_membi_sup));
  endfunction

  // Check if there are cache credits of any or a specific type
  virtual function bit check_cch_credits(credit_op_t op);
    case (op)
      ANYC : return (shr.avl_req_credit[CCH] || 
                     shr.avl_dat_credit[CCH] || 
                     shr.avl_rsp_credit[CCH]);
      REQC : return (|shr.avl_req_credit[CCH]);
      DATC : return (|shr.avl_dat_credit[CCH]);
      RSPC : return (|shr.avl_rsp_credit[CCH]);
    endcase
  endfunction

  // Check if there are mem credits of any or a specific type
  virtual function bit check_mem_credits(credit_op_t op, dir_t dir, bit bi_sup);
    case (op)
      ANYC : if (dir==H2C)
               return (shr.avl_req_credit[MEM] || 
                       shr.avl_dat_credit[MEM] || 
                       (bi_sup && shr.avl_rsp_credit[MEM]));
             else
               return ((bi_sup && shr.avl_req_credit[MEM]) || 
                       shr.avl_dat_credit[MEM] || 
                       shr.avl_rsp_credit[MEM]);
      REQC : return ((dir==H2C || bi_sup) && shr.avl_req_credit[MEM]);
      DATC : return (|shr.avl_dat_credit[MEM]);
      RSPC : return ((dir==C2H || bi_sup) && shr.avl_rsp_credit[MEM]);
    endcase
  endfunction

endclass
