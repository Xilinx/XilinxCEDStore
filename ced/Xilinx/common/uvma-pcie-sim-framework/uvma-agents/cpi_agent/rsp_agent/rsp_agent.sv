// CPI RSP channel agent
// Conforms to CPI Spec Rev1.0 02/2023
// - Restrictions
//   - This agent acts as if transfers are processed in order, meaning that credits will
//     be returned in order; a set of SHR-DED transfers will return the credits in SHR-DED 
//     order, never DED-SHR as if there was a credit pool to return from
// - Not supported
//   - Blocking ; rsp_txblock_crd_flow and rsp_block tied low
//     - master will deassert is_valid in response to rsp_block assertion
//     - slave will deassert rxcrd_valid/rxcrd_shared in response to txblock_crd_flow assertion
//   - Early Valid ; rsp_early_valid tied low
class rsp_agent#(parameter NP=0) extends base_agent#(
  .VIF(virtual rsp_if#(NP)),
  .CFG(rsp_cfg),
  .SHR(rsp_share),
  .REQ(rsp_txn),
  .DRV(rsp_driver#(rsp_txn, rsp_txn, virtual rsp_if#(NP), rsp_cfg, rsp_share)),
  .MON(rsp_monitor#(rsp_cfg, virtual rsp_if#(NP), rsp_txn, rsp_share)),
  .API(rsp_api#(base_sequencer#(rsp_txn, rsp_txn, rsp_txn, rsp_cfg, rsp_share)))
);

  `uvm_component_param_utils(rsp_agent#(NP))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("rsp_agent#(%0d)",NP);
  virtual function string get_type_name(); return type_name; endfunction

  uvm_event init_crd_done;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    init_crd_done = new("init_crd_done");
  endfunction

  // User can stop this sequence or replace with their own through factory,
  // this is the selected default sequence for responders
  virtual function void start_of_simulation_phase(uvm_phase phase);
    bit mem_crd_present, cch_crd_present;
    rsp_slv_base_seq seq = rsp_slv_base_seq::type_id::create("seq");
    /* Initialize credits here from cfg object to the dut on the interface */
    if (is_slave_agent() && is_active_agent()) begin
      // Make sure user has allocated some credits for the initial handshake or die
      foreach(cfg.init_credit_ded[1][ii]) begin 
        if (cfg.init_credit_ded[1][ii]) begin
          mem_crd_present = 1'b1;
          break;
        end
      end
      foreach(cfg.init_credit_ded[0][ii]) begin 
        if (cfg.init_credit_ded[0][ii]) begin
          cch_crd_present = 1'b1;
          break;
        end
      end
      if (!cfg.skip_credit_returns &&
          ((cfg.cxl_mem_sup && !mem_crd_present) || (cfg.cxl_cch_sup && !cch_crd_present)) && 
          !cfg.init_credit_shr)
      begin
        `uvm_fatal(get_type_name, {"Need to configure the initial credits for this agent by ",phase.get_name,"_phase"})
      end
      // Let global know about init credits to generate empty
      shr.gshr.total_credits_mark_rsp = cfg.init_credit_shr+
                                        cfg.init_credit_ded[0].sum+
                                        cfg.init_credit_ded[1].sum;
      // Configure the initial sequence and start it
      seq.init_seq.init_crd_done   = init_crd_done;
      seq.init_seq.init_credit_ded = cfg.init_credit_ded;
      seq.init_seq.init_credit_shr = cfg.init_credit_shr;
      fork
        seq.start(sqr);
      join_none
    end
  endfunction

endclass

class rsp_agent_creator#(parameter NP=0);

  static function rsp_agent spawn(string name, uvm_component parent, virtual rsp_if#(NP) vif, rsp_cfg cfg = null);

    rsp_agent#(NP) agent;

    // Create agent
    agent = rsp_agent#(NP)::type_id::create(name, parent);

    // Create cfg object if not passed to function
    if (cfg == null) begin
      cfg = rsp_cfg::type_id::create("cfg");
      agent.cfg = cfg;
    end

    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(virtual rsp_if#(NP))::set(agent, "*", "vif", vif);
    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(rsp_cfg)::set(parent, $sformatf("%0s*",name), "cfg", cfg);

    return agent;

  endfunction

endclass
