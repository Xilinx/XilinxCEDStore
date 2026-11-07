// CPI GLOBAL channel agent
// Conforms to CPI Spec Rev1.0 02/2023
// - Restrictions
//   -
// - Not supported
//   - IDE Containment Mode ; epoch_id, epoch_commit, epoch_reject not present
class global_agent#(parameter P=1) extends base_agent#(
  .VIF(virtual global_if#(P)),
  .CFG(global_cfg),
  .SHR(global_share),
  .REQ(global_txn),
  .DRV(global_driver#(global_txn, global_txn, virtual global_if#(P), global_cfg, global_share)),
  .MON(global_monitor#(global_cfg, virtual global_if#(P), global_txn, global_share)),
  .API(global_api#(base_sequencer#(global_txn, global_txn, global_txn, global_cfg, global_share)))
);

  `uvm_component_param_utils(global_agent#(P))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("global_agent#(%0d)",P);
  virtual function string get_type_name(); return type_name; endfunction
 
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (is_slave_agent() && is_active_agent())
      mon.empty_ap.connect(sqr.analysis_export);
  endfunction

  // User can stop this sequence or replace with their own through factory,
  // this is the selected default sequence for responders
  virtual function void start_of_simulation_phase(uvm_phase phase);
    global_slv_base_seq seq = global_slv_base_seq::type_id::create("seq");
    if (is_slave_agent() && is_active_agent()) begin
      fork
        seq.start(sqr);
      join_none
    end
  endfunction

endclass

class global_agent_creator#(parameter P=1);

  static function global_agent spawn(string name, uvm_component parent, virtual global_if#(P) vif, global_cfg cfg = null);

    global_agent#(P) agent;

    // Create agent
    agent = global_agent#(P)::type_id::create(name, parent);

    // Create cfg object if not passed to function
    if (cfg == null) begin
      cfg = global_cfg::type_id::create("cfg");
      agent.cfg = cfg;
    end

    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(virtual global_if#(P))::set(agent, "*", "vif", vif);
    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(global_cfg)::set(parent, $sformatf("%0s*",name), "cfg", cfg);

    return agent;

  endfunction

endclass
