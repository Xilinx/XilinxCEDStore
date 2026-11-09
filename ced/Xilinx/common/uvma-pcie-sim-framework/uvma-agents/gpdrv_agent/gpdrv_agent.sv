// General Purpose Driver (gpdrv) Agent
// - Description 
//   - This agent can be used to drive any generic bus or wire. To print 
//     transactions in a human-readable form, extend the gpdrv_mon_cb class and
//     override the make_specific function such that it enumerates the 
//     txn.sig_enum member.
class gpdrv_agent#(type VIF=virtual gpdrv_if, type TXN=gpdrv_txn) extends base_agent#(
  .VIF (VIF),
  .CFG (gpdrv_cfg),
  .REQ (TXN),
  .DRV (gpdrv_driver#(TXN,TXN,VIF,gpdrv_cfg,base_share)),
  .MON (gpdrv_monitor#(gpdrv_cfg,VIF,TXN)),
  .API (gpdrv_api#(base_sequencer#(TXN,TXN,TXN,gpdrv_cfg,base_share)))
);

  `uvm_component_param_utils(gpdrv_agent#(VIF, TXN))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"gpdrv_agent#(VIF, ",
                                    TXN::type_name, 
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

class gpdrv_agent_creator#(type VIF=virtual gpdrv_if, type TXN=gpdrv_txn);

  static function gpdrv_agent#(VIF,TXN) spawn(string name, uvm_component parent, VIF vif, gpdrv_cfg cfg = null);
    
    // Create agent
    gpdrv_agent#(VIF,TXN) agent = gpdrv_agent#(VIF,TXN)::type_id::create(name, parent);  

    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(VIF)::set(agent, "*", "vif", vif);

    if (cfg == null) begin
      cfg = gpdrv_cfg::type_id::create("cfg", parent);
      agent.cfg = cfg;
    end

    // Pass to lower objects, which will grab in their build phase
    // set(agent, "*"...) sets search path as "agent.*.cfg"
    // agent itself needs cfg visibility, so this sets path as "parent.agent*cfg"
    uvm_config_db#(gpdrv_cfg)::set(parent, $sformatf("%s*",name), "cfg", cfg);

    return agent;
 
  endfunction
  
endclass
