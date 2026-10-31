class msix_user_driver#(type REQ,
                    type RSP,
                    type VIF,
                    type CFG,
                    type SHR) extends base_driver#(REQ,RSP,VIF,CFG,SHR);

  `uvm_component_param_utils(msix_user_driver#(REQ,RSP,VIF,CFG,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"msix_user_driver#(", 
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
    vif.agent_driven         = 1;
    vif.i_user_func_num     <= '0;
    vif.i_user_vfunc_num    <= '0;
    vif.i_user_vfunc_active <= '0;
    vif.i_user_req          <= '0;
    vif.i_user_vector_num   <= '0;
    vif.i_user_operation    <= '0;
  endtask

  virtual task drive_item(REQ req);
    vif.dcb.i_user_func_num     <= req.user_func_num;
    vif.dcb.i_user_vfunc_num    <= req.user_vfunc_num;
    vif.dcb.i_user_vfunc_active <= req.user_vfunc_active;
    vif.dcb.i_user_req          <= req.user_req;
    vif.dcb.i_user_vector_num   <= req.user_vector_num;
    vif.dcb.i_user_operation    <= req.user_operation;
    @(vif.mcb iff (vif.mcb.user_grant)); //one outstanding a time
    vif.dcb.i_user_req          <= 1'b0; 
  endtask

endclass

