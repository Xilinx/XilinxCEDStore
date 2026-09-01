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

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    check_config();
  endfunction

  function void check_config();
    if (cfg.addr_width <= 0)
      `uvm_fatal(get_type_name(), $sformatf("addr_width (%0d) must be greater than 0", cfg.addr_width))
    if (cfg.addr_width > mon.vif.ADDR_WIDTH)
      `uvm_fatal(get_type_name(), $sformatf("addr_width (%0d) cannot be greater than %0d", cfg.addr_width, mon.vif.ADDR_WIDTH))
    if (cfg.data_width <= 0)
      `uvm_fatal(get_type_name(), $sformatf("data_width (%0d) must be greater than 0", cfg.data_width))
    if (cfg.data_width > mon.vif.DATA_WIDTH)
      `uvm_fatal(get_type_name(), $sformatf("data_width (%0d) cannot be greater than %0d", cfg.data_width, mon.vif.DATA_WIDTH))
    if (cfg.id_width <= 0)
      `uvm_fatal(get_type_name(), $sformatf("id_width (%0d) must be greater than 0", cfg.id_width))
    if (cfg.id_width > mon.vif.ID_WIDTH)
      `uvm_fatal(get_type_name(), $sformatf("id_width (%0d) cannot be greater than %0d", cfg.id_width, mon.vif.ID_WIDTH))
    if (cfg.awuser_width < 0)
      `uvm_fatal(get_type_name(), $sformatf("awuser_width (%0d) cannot be negative", cfg.awuser_width))
    if (cfg.awuser_width > mon.vif.AWUSER_WIDTH)
      `uvm_fatal(get_type_name(), $sformatf("awuser_width (%0d) cannot be greater than %0d", cfg.awuser_width, mon.vif.AWUSER_WIDTH))
    if (cfg.aruser_width < 0)
      `uvm_fatal(get_type_name(), $sformatf("aruser_width (%0d) cannot be negative", cfg.aruser_width))
    if (cfg.aruser_width > mon.vif.ARUSER_WIDTH)
      `uvm_fatal(get_type_name(), $sformatf("aruser_width (%0d) cannot be greater than %0d", cfg.aruser_width, mon.vif.ARUSER_WIDTH))
    if (cfg.ruser_width < 0)
      `uvm_fatal(get_type_name(), $sformatf("ruser_width (%0d) cannot be negative", cfg.ruser_width))
    if (cfg.ruser_width > mon.vif.RUSER_WIDTH)
      `uvm_fatal(get_type_name(), $sformatf("ruser_width (%0d) cannot be greater than %0d", cfg.ruser_width, mon.vif.RUSER_WIDTH))
    if (cfg.wuser_width < 0)
      `uvm_fatal(get_type_name(), $sformatf("wuser_width (%0d) cannot be negative", cfg.wuser_width))
    if (cfg.wuser_width > mon.vif.WUSER_WIDTH)
      `uvm_fatal(get_type_name(), $sformatf("wuser_width (%0d) cannot be greater than %0d", cfg.wuser_width, mon.vif.WUSER_WIDTH))
    if (cfg.buser_width < 0)
      `uvm_fatal(get_type_name(), $sformatf("buser_width (%0d) cannot be negative", cfg.buser_width))
    if (cfg.buser_width > mon.vif.BUSER_WIDTH)
      `uvm_fatal(get_type_name(), $sformatf("buser_width (%0d) cannot be greater than %0d", cfg.buser_width, mon.vif.BUSER_WIDTH))
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
