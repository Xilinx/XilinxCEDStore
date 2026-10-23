// General Purpose Monitor (gpmon) Agent
// - Description
//   - This agent can be used to monitor and report changes on a bus or wire.
//     To print transactions in a human-readable form, extend the gpmon_mon_cb
//     class and override the make_specific function such that it enumerates the 
//     txn.sig_enum member.
class gpmon_agent#(type VIF=virtual gpmon_if, type TXN=gpmon_txn) extends base_agent#(
  .VIF (VIF),
  .CFG (gpmon_cfg),
  .TXN (TXN),
  .MON (gpmon_monitor#(gpmon_cfg,VIF,TXN))
);

  `uvm_component_param_utils(gpmon_agent#(VIF, TXN))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"gpmon_agent#(VIF, ",
                                    TXN::type_name, 
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

class gpmon_agent_creator#(type VIF=virtual gpmon_if, type TXN=gpmon_txn);

  static function gpmon_agent#(VIF,TXN) spawn(string name, uvm_component parent, VIF vif, gpmon_cfg cfg = null);
    
    // Create agent
    gpmon_agent#(VIF,TXN) agent = gpmon_agent#(VIF,TXN)::type_id::create(name, parent);  

    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(VIF)::set(agent, "*", "vif", vif);

    if (cfg == null) begin
      cfg = gpmon_cfg::type_id::create("cfg", parent);
      agent.cfg = cfg;
    end

    // Pass to lower objects, which will grab in their build phase
    // set(agent, "*"...) sets search path as "agent.*.cfg"
    // agent itself needs cfg visibility, so this sets path as "parent.agent*cfg"
    uvm_config_db#(gpmon_cfg)::set(parent, $sformatf("%s*",name), "cfg", cfg);

    return agent;
 
  endfunction
  
endclass
