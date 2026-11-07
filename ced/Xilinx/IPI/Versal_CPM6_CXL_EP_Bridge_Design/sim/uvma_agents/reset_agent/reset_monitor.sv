class reset_monitor#(type CFG, type VIF, type TXN, type SHR) extends base_monitor#(CFG,VIF,TXN,SHR);

  `uvm_component_param_utils(reset_monitor#(CFG,VIF,TXN,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"reset_monitor#(", 
                                    CFG::type_name,",",
                                    "VIF,",
                                    TXN::type_name,",",
                                    SHR::type_name,
                                    ")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    reset_txn txn = reset_txn::type_id::create("txn");
    base_txn  bt;
    txn.uid = cfg.uid;
    txn.from_monitor = 1;
    
    forever begin
      @(vif.reset);
      if (vif.reset === 1'bx)
        txn.action = WENT_X;
      else if (vif.reset === 1'bz)
        txn.action = WENT_Z;
      else
        txn.action = (vif.reset == cfg.active_val) ? ASSERT : DEASSERT;
      ap.write(txn);
      bt = txn;
      base_ap.write(bt);
    end

  endtask

endclass
