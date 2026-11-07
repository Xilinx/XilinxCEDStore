class aximon_agent#(type VIF=virtual aximon_if, type TXN=aximon_txn) extends base_agent#(
  .VIF (VIF),
  .CFG (aximon_cfg),
  .TXN (TXN),
  .MON (aximon_monitor#(aximon_cfg,VIF,TXN))
);

  `uvm_component_param_utils(aximon_agent#(VIF, TXN))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"aximon_agent#(VIF, ",
                                    TXN::type_name, 
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

class aximon_agent_creator#(type VIF=virtual aximon_if, type TXN=aximon_txn);

  static function aximon_agent#(VIF,TXN) spawn(string name, uvm_component parent, VIF vif, aximon_cfg cfg = null);
    
    // Create agent
    aximon_agent#(VIF,TXN) agent = aximon_agent#(VIF,TXN)::type_id::create(name, parent);  

    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(VIF)::set(agent, "*", "vif", vif);

    if (cfg == null) begin
      cfg = aximon_cfg::type_id::create("cfg", parent);
      agent.cfg = cfg;
    end

    // Pass to lower objects, which will grab in their build phase
    // set(agent, "*"...) sets search path as "agent.*.cfg"
    // agent itself needs cfg visibility, so this sets path as "parent.agent*cfg"
    uvm_config_db#(aximon_cfg)::set(parent, $sformatf("%s*",name), "cfg", cfg);

    return agent;
 
  endfunction
  
endclass
