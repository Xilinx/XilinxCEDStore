// pswizard_agent.sv — Passive UVM agent for the pswizard interface monitor
//
// Contains only a monitor (UVM_PASSIVE).  The analysis port is forwarded
// from the monitor so subscribers can connect directly to the agent.
class pswizard_agent extends uvm_agent;

  `uvm_component_utils(pswizard_agent)

  pswizard_monitor                 mon;
  pswizard_cfg                     cfg;
  uvm_analysis_port#(pswizard_txn) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(pswizard_cfg)::get(this, "", "cfg", cfg)) begin
      cfg = pswizard_cfg::type_id::create("cfg", this);
      `uvm_info("pswizard_agent", "cfg not found in config_db; using defaults", UVM_LOW)
    end

    // Forward vif and cfg down to the monitor
    uvm_config_db#(virtual pswizard_if)::set(this, "mon", "vif", get_vif());
    uvm_config_db#(pswizard_cfg)::set(this, "mon", "cfg", cfg);

    mon = pswizard_monitor::type_id::create("mon", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    mon.ap.connect(ap);
  endfunction

  local function virtual pswizard_if get_vif();
    virtual pswizard_if vif;
    if (!uvm_config_db#(virtual pswizard_if)::get(this, "", "vif", vif))
      `uvm_fatal("pswizard_agent", "Failed to get virtual pswizard_if from config_db")
    return vif;
  endfunction

endclass
