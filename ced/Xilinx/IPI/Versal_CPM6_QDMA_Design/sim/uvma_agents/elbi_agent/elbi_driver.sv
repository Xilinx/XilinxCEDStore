class elbi_driver#(type REQ, type RSP, type VIF, type CFG, type SHR) extends base_driver#(REQ,RSP,VIF,CFG,SHR);

  `uvm_component_param_utils(elbi_driver#(REQ,RSP,VIF,CFG,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"elbi_driver#(",
                                   REQ::type_name,",",
                                   RSP::type_name,",",
                                   "VIF,",
                                   CFG::type_name,",",
                                   SHR::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task drive_init;
    vif.agent_driven = 1;
    vif.i_ext_lbc_override_en <= '0;
    vif.i_ext_lbc_ack         <= '0;
    vif.i_ext_lbc_din         <= '0;
    vif.select                <= !cfg.shared_responder;
  endtask

  virtual task drive_item(REQ req);
    vif.dcb.i_ext_lbc_override_en <= req.ext_lbc_override_en;
    if (cfg.shared_responder) 
      vif.dcb.select <= 1'b1;
    repeat (req.rsp_delay) @(vif.dcb);
    vif.dcb.i_ext_lbc_ack <= req.ext_lbc_ack;
    vif.dcb.i_ext_lbc_din <= req.ext_lbc_din;
    @(vif.dcb);
    if (vif.mcb.ext_lbc_ack !== req.ext_lbc_ack) @(vif.dcb); //avoid race condition
    vif.dcb.i_ext_lbc_override_en <= 1'b0;
    vif.dcb.i_ext_lbc_ack         <= '0;
    if (cfg.shared_responder) 
      vif.dcb.select <= 1'b0;
  endtask

endclass
