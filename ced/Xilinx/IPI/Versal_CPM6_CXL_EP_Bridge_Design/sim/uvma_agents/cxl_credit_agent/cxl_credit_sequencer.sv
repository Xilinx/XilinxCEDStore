class cxl_credit_sequencer extends base_sequencer#(cxl_credit_bus_txn,
                                                   cxl_credit_bus_txn,
                                                   cxl_credit_bus_txn,
                                                   cxl_credit_cfg,
                                                   cxl_credit_share);
  `uvm_component_utils(cxl_credit_sequencer)

  virtual cxl_credit_agent_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual cxl_credit_agent_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name, "Failed to get 'vif' from config db")
  endfunction

  virtual task wait_cycles(int n);
    repeat(n) @(vif.mcb);
  endtask

endclass
