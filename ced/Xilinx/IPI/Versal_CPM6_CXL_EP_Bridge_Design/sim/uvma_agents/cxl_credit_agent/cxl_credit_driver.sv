class cxl_credit_driver#(type REQ, type RSP, type VIF, type CFG, type SHR) extends base_driver#(REQ,RSP,VIF,CFG,SHR);

  `uvm_component_param_utils(cxl_credit_driver#(REQ,RSP,VIF,CFG,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"cxl_credit_driver#(",
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

  virtual task drive_init();
    vif.agent_driven = 1;
    vif.i_vld <= '0;
    vif.i_req <= '0;
    vif.i_dat <= '0;
    vif.i_rsp <= '0;
  endtask

  virtual task drive_item(REQ req);
    vif.dcb.i_vld <= req.vld;
    vif.dcb.i_req <= req.req;
    vif.dcb.i_dat <= req.dat;
    vif.dcb.i_rsp <= req.rsp;
    @(vif.dcb);
    if (vif.mcb.vld != req.vld) @(vif.dcb); //avoid race condition
    vif.dcb.i_vld <= 1'b0;
  endtask

endclass
