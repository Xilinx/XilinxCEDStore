class gpdrv_driver#(type REQ,
                    type RSP,
                    type VIF,
                    type CFG,
                    type SHR) extends base_driver#(REQ,RSP,VIF,CFG,SHR);

  `uvm_component_param_utils(gpdrv_driver#(REQ,RSP,VIF,CFG,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"gpdrv_driver#(", 
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
    vif.i_sig <= cfg.init_val;
  endtask

  virtual task drive_item(REQ req);
    if (cfg.sync_control == SYNC)
      vif.cb.i_sig <= req.sig;
    else
      vif.i_sig <= req.sig;
  endtask

endclass

