// CPI DATA channel agent
// Conforms to CPI Spec Rev1.0 02/2023
// - Restrictions
//   - This agent acts as if transfers are processed in order, meaning that credits will
//     be returned in order; a set of SHR-DED transfers will return the credits in SHR-DED 
//     order, never DED-SHR as if there was a credit pool to return from
// - Not supported
//   - Blocking ; data_txblock_crd_flow and data_block tied low
//     - master will deassert is_valid in response to data_block assertion
//     - slave will deassert rxcrd_valid/rxcrd_shared in response to txblock_crd_flow assertion
//   - Early Valid ; data_early_valid tied low
//   - Data Header Separation ; agent currently only supports DataHdrSep=0 
//       (data_cfg.data_hdr_sep is not used i.e. multi-beat transfers not supported)
//   - 64B Transfers Only : agent currently only supports TXFER_32B_EN=0 
//       (data_cfg.txfer_32b_en is not used)
class data_agent#(parameter NP=0) extends base_agent#(
  .VIF(virtual data_if#(NP)),
  .CFG(data_cfg),
  .SHR(data_share),
  .REQ(data_txn),
  .DRV(data_driver#(data_txn, data_txn, virtual data_if#(NP), data_cfg, data_share)),
  .MON(data_monitor#(data_cfg, virtual data_if#(NP), data_txn, data_share)),
  .API(data_api#(base_sequencer#(data_txn, data_txn, data_txn, data_cfg, data_share)))
);

  `uvm_component_param_utils(data_agent#(NP))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("data_agent#(%0d)",NP);
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
    data_slv_base_seq seq = data_slv_base_seq::type_id::create("seq");
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
      shr.gshr.total_credits_mark_data = cfg.init_credit_shr+
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

class data_agent_creator#(parameter NP=0);

  static function data_agent spawn(string name, uvm_component parent, virtual data_if#(NP) vif, data_cfg cfg = null);

    data_agent#(NP) agent;

    // Create agent
    agent = data_agent#(NP)::type_id::create(name, parent);

    // Create cfg object if not passed to function
    if (cfg == null) begin
      cfg = data_cfg::type_id::create("cfg");
      agent.cfg = cfg;
    end

    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(virtual data_if#(NP))::set(agent, "*", "vif", vif);
    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(data_cfg)::set(parent, $sformatf("%0s*",name), "cfg", cfg);

    return agent;

  endfunction

endclass
