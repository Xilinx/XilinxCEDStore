class cfg_ext_agent#(type VIF) extends base_agent #(
  .VIF (VIF),
  .SHR (cfg_ext_share),
  .REQ (cfg_ext_txn),
  .TXN (cfg_ext_txn),
  .DRV (cfg_ext_driver#(cfg_ext_txn, cfg_ext_txn, VIF, base_cfg, cfg_ext_share)),
  .MON (cfg_ext_monitor#(base_cfg, VIF, cfg_ext_txn, cfg_ext_share)),
  .API (cfg_ext_api#(base_sequencer#(cfg_ext_txn, cfg_ext_txn, cfg_ext_txn, base_cfg, cfg_ext_share)))
);

  `uvm_component_param_utils(cfg_ext_agent#(VIF))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"cfg_ext_agent#(VIF)"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // User can stop this sequence or replace with their own through factory,
  // this is the selected default sequence for responders
  virtual function void start_of_simulation_phase(uvm_phase phase);
    cfg_ext_slv_base_seq seq = cfg_ext_slv_base_seq::type_id::create("seq");
    if (is_slave && is_active) begin
      fork
        seq.start(sqr);
      join_none
    end
  endfunction

endclass

// Static function in class to enable agent creation
class cfg_ext_agent_creator#(type VIF);

  static function cfg_ext_agent#(VIF) spawn(string name, uvm_component parent, VIF vif, base_cfg cfg = null);

    cfg_ext_agent#(VIF) agent;

    // Create agent
    agent = cfg_ext_agent#(VIF)::type_id::create(name, parent);

    // Create cfg object if not passed to function
    if (cfg == null) begin
      cfg = base_cfg::type_id::create("cfg");
      agent.cfg = cfg;
    end

    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(VIF)::set(agent, "*", "vif", vif);
    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(base_cfg)::set(parent, $sformatf("%0s*",name), "cfg", cfg);

    return agent;
     
  endfunction

endclass
