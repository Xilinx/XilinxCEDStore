class cfg_ext_monitor#(type CFG, type VIF, type TXN, type SHR) extends base_monitor#(CFG,VIF,TXN,SHR);

  `uvm_component_param_utils(cfg_ext_monitor#(CFG,VIF,TXN,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"cfg_ext_monitor#(",
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
    TXN txn;
    base_txn btxn;
    process p1;
    forever begin
      txn = TXN::type_id::create("txn");
      @(vif.cb iff (vif.cfg_ext_read_received==1 || vif.cfg_ext_write_received==1)); 
      txn.cfg_ext_read_received     = vif.cfg_ext_read_received;
      txn.cfg_ext_write_received    = vif.cfg_ext_write_received;
      txn.cfg_ext_register_number   = vif.cfg_ext_register_number;
      txn.cfg_ext_function_number   = vif.cfg_ext_function_number;
      txn.cfg_ext_write_data        = vif.cfg_ext_write_data;
      txn.cfg_ext_write_byte_enable = vif.cfg_ext_write_byte_enable;
      txn.info = vif.cfg_ext_write_received ? "WRITE" : "READ_REQ"; 
      btxn = txn;
      ap.write(txn);
      base_ap.write(btxn);
      // Get read response
      if (vif.cfg_ext_read_received) begin
        txn.info = "READ_RSP";
        fork 
          begin
            @(vif.cb iff vif.cfg_ext_read_data_valid==1);
            txn.cfg_ext_read_data_valid = vif.cfg_ext_read_data_valid;
          end
          begin : timeout
            p1 = process::self;
            repeat('h4_0000) @(vif.cb);
            txn.info2 = "TIMEOUT";
          end
        join_any
        if (p1.status == process::WAITING) p1.kill;
        txn.cfg_ext_read_data = vif.cfg_ext_read_data;
        ap.write(txn);
        base_ap.write(btxn);
      end
    end
  endtask

endclass
