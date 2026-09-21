// - Reset Agent
// - Used to drive or monitor reset lines
// - This agent abstracts away the difficulties of binary values and prints
//   clear and obvious transaction values like "ASSERT", "DEASSERT", etc.
//   while also giving the option to do the action either asynchronously or
//   synchronously
// - The API class gives the option to set, clear, or pulse resets 
class reset_agent#(type VIF=virtual reset_if) extends base_agent#(
  .VIF(VIF), 
  .CFG(reset_cfg), 
  .REQ(reset_txn),
  .TXN(reset_txn),
  .DRV(reset_driver#(reset_txn,reset_txn,VIF,reset_cfg,base_share)),
  .MON(reset_monitor#(reset_cfg,VIF,reset_txn,base_share)),
  .API(reset_api#(base_sequencer#(reset_txn,reset_txn,reset_txn,reset_cfg,base_share)))
);

  `uvm_component_param_utils(reset_agent#(VIF))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = "reset_agent#(VIF)";
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction 

endclass

class reset_agent_creator#(type VIF=virtual reset_if);

  static function reset_agent#(VIF) spawn(string name, uvm_component parent, VIF vif, reset_cfg cfg = null);
 
    // Create agent
    reset_agent#(VIF) agent = reset_agent#(VIF)::type_id::create(name, parent); 

    // Create cfg object if not passed to function
    if (cfg == null) begin
      cfg = reset_cfg::type_id::create("cfg");
      agent.cfg = cfg;
    end

    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(reset_cfg)::set(parent, $sformatf("%0s*",name), "cfg", cfg);
    uvm_config_db#(VIF)::set(agent, "*", "vif", vif);

    return agent;
 
  endfunction 

endclass
