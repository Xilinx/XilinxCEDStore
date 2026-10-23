class elbi_agent extends base_agent #(
  .VIF (virtual elbi_if),
  .CFG (elbi_cfg),
  .REQ (elbi_txn),
  .TXN (elbi_txn),
  .SHR (elbi_share),
  .DRV (elbi_driver#(elbi_txn, elbi_txn, virtual elbi_if, elbi_cfg, elbi_share)),
  .MON (elbi_monitor#(elbi_cfg, virtual elbi_if, elbi_txn, elbi_share)) 
);

  `uvm_component_utils(elbi_agent)

  // Output ports
  uvm_analysis_port #(elbi_txn) req_ap;    //ALL requests
  uvm_analysis_port #(elbi_txn) reqext_ap; //ONLY external requests
  uvm_analysis_port #(elbi_txn) reqint_ap; //ONLY internal requests
  uvm_analysis_port #(elbi_txn) rsp_ap;
  uvm_analysis_port #(elbi_txn) cmb_ap;    //combined: reqext+rsp

  function new(string name, uvm_component parent);
    super.new(name, parent);
    req_ap    = new("req_ap", this); 
    reqext_ap = new("reqext_ap", this); 
    reqint_ap = new("reqint_ap", this); 
    rsp_ap    = new("rsp_ap", this); 
    cmb_ap    = new("cmb_ap", this); 
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    cfg.disable_mon_ap_connect = 1; //won't use this port
    super.connect_phase(phase);
    // Need to steer requests to sequencer FIFO
    if (is_slave && is_active)
      req_ap.connect(sqr.analysis_export);
  endfunction

  // Overwrite this to steer txn to correct analysis port(s)
  virtual function void steer_txn(elbi_txn t);
    case ({t.req, t.rsp})
      2'b10 : begin
                req_ap.write(t);
                if (t.lbc_ext_cs) reqext_ap.write(t);
                else              reqint_ap.write(t);
              end
      2'b01 : rsp_ap.write(t);
      2'b11 : cmb_ap.write(t);
    endcase
  endfunction

  // User can stop this sequence or replace with their own through factory,
  // this is the selected default sequence for responders
  virtual function void start_of_simulation_phase(uvm_phase phase);
    elbi_slv_base_seq seq = elbi_slv_base_seq::type_id::create("seq");
    if (is_slave && is_active) begin
      fork
        seq.start(sqr);
      join_none
    end
  endfunction

endclass

// Static function in class to enable agent creation
class elbi_agent_creator;

  static function elbi_agent spawn(string name, uvm_component parent, virtual elbi_if vif, elbi_cfg cfg = null);

    elbi_agent agent;

    // Create agent
    agent = elbi_agent::type_id::create(name, parent);

    // Create cfg object if not passed to function
    if (cfg == null) begin
      cfg = elbi_cfg::type_id::create("cfg");
      agent.cfg = cfg;
    end

    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(virtual elbi_if)::set(agent, "*", "vif", vif);
    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(elbi_cfg)::set(parent, $sformatf("%0s*",name), "cfg", cfg);

    return agent;
     
  endfunction

endclass
