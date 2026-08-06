class ps_vip_vsequencer extends uvm_sequencer;

  `uvm_component_utils(ps_vip_vsequencer)

  virtual ps_vip_api_if ps_vip_api;
    
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual ps_vip_api_if)::get(this, "", "ps_vip_api", ps_vip_api))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'ps_vip_api' from cfg db")
  endfunction

endclass
