class msix_user_monitor#(type CFG, type VIF, type TXN) extends base_monitor#(CFG,VIF,TXN,base_share);

  `uvm_component_param_utils(msix_user_monitor#(CFG,VIF,TXN))

  typedef msix_user_monitor#(CFG,VIF,TXN) this_type;

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"msix_user_monitor#(",
                                   CFG::type_name,",",
                                   "VIF,",
                                   TXN::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    base_txn     bt[0:1];
    TXN          req = TXN::type_id::create("req");
    TXN          gnt = TXN::type_id::create("gnt");

    // Get config from object
    {req.print_vf_always, gnt.print_vf_always} = {2{cfg.print_vf_always}};

    req.info = "REQ";    
    gnt.info = "GNT";
  
    // Assign to base handles
    bt = {req, gnt};
    
    fork
      // req-only txn
      forever begin
        @(vif.mcb iff vif.mcb.user_req);
        req.user_func_num     = vif.mcb.user_func_num;
        req.user_vfunc_num    = vif.mcb.user_vfunc_num;
        req.user_vfunc_active = vif.mcb.user_vfunc_active;
        req.user_req          = vif.mcb.user_req;
        req.user_vector_num   = vif.mcb.user_vector_num;
        req.user_operation    = vif.mcb.user_operation;
        req.user_grant        = vif.mcb.user_grant;
        req.user_error        = vif.mcb.user_error;
        // Broadcast
        ap.write(req);
        base_ap.write(bt[0]);
        // Wait until txn completes before another txn can be sent
        @(vif.mcb iff vif.mcb.user_grant);
      end
      // gnt txn
      forever begin
        @(vif.mcb iff vif.mcb.user_grant);
        gnt.user_func_num     = vif.mcb.user_func_num;
        gnt.user_vfunc_num    = vif.mcb.user_vfunc_num;
        gnt.user_vfunc_active = vif.mcb.user_vfunc_active;
        gnt.user_req          = vif.mcb.user_req;
        gnt.user_vector_num   = vif.mcb.user_vector_num;
        gnt.user_operation    = vif.mcb.user_operation;
        gnt.user_grant        = vif.mcb.user_grant;
        gnt.user_error        = vif.mcb.user_error;
        // Broadcast
        ap.write(gnt);
        base_ap.write(bt[1]);
      end
    join_none
  endtask

endclass
