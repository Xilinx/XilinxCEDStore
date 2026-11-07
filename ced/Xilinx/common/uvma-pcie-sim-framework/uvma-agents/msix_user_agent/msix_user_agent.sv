// MSI-X User (msix_user) Agent
// - Description 
//   - This agent can be used to drive the CPM6 MSI-X module that is is delivered
//     within CPM6.
class msix_user_agent extends base_agent#(
  .VIF (virtual msix_user_if),
  .CFG (msix_user_cfg),
  .REQ (msix_user_txn),
  .DRV (msix_user_driver#(msix_user_txn,msix_user_txn,virtual msix_user_if,msix_user_cfg,base_share)),
  .MON (msix_user_monitor#(msix_user_cfg,virtual msix_user_if,msix_user_txn)),
  .API (msix_user_api#(base_sequencer#(msix_user_txn,msix_user_txn,msix_user_txn,msix_user_cfg,base_share)))
);

  `uvm_component_utils(msix_user_agent)

  // Output ports
  uvm_analysis_port #(msix_user_txn) req_ap; 
  uvm_analysis_port #(msix_user_txn) gnt_ap; 

  function new(string name, uvm_component parent);
    super.new(name, parent);
    req_ap = new("req_ap", this);
    gnt_ap = new("gnt_ap", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    cfg.disable_mon_ap_connect = 1; //won't use this port
    super.connect_phase(phase);
  endfunction

  // Overwrite this to steer txn to correct analysis port
  virtual function void steer_txn(msix_user_txn t);
    case (t.info)
      "REQ" : req_ap.write(t);
      "GNT" : gnt_ap.write(t);
    endcase
  endfunction

endclass

class msix_user_agent_creator;

  static function msix_user_agent spawn(string name, uvm_component parent, virtual msix_user_if vif, msix_user_cfg cfg = null);
    
    // Create agent
    msix_user_agent agent = msix_user_agent::type_id::create(name, parent);  

    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(virtual msix_user_if)::set(agent, "*", "vif", vif);

    if (cfg == null) begin
      cfg = msix_user_cfg::type_id::create("cfg", parent);
      agent.cfg = cfg;
    end

    // Pass to lower objects, which will grab in their build phase
    // set(agent, "*"...) sets search path as "agent.*.cfg"
    // agent itself needs cfg visibility, so this sets path as "parent.agent*cfg"
    uvm_config_db#(msix_user_cfg)::set(parent, $sformatf("%s*",name), "cfg", cfg);

    return agent;
 
  endfunction
  
endclass
