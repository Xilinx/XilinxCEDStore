class cxl_credit_monitor #(type CFG, type VIF, type TXN, type SHR) extends base_monitor#(CFG,VIF,TXN,SHR);

  `uvm_component_param_utils(cxl_credit_monitor#(CFG,VIF,TXN,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"cxl_credit_monitor#(",
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
    cxl_credit_txn     data_txn;
    cxl_credit_txn      req_txn;
    cxl_credit_txn      rsp_txn;
    cxl_credit_bus_txn  bus_txn;
    base_txn            dbt, rbt, sbt, bbt;
   
    // Individual Txns, per channel
    if (cfg.mon_indi) begin
      data_txn = cxl_credit_txn::type_id::create("data_txn");
      req_txn  = cxl_credit_txn::type_id::create("req_txn");
      rsp_txn  = cxl_credit_txn::type_id::create("rsp_txn");
    
      dbt = data_txn;
      rbt = req_txn;
      sbt = rsp_txn;
      
      data_txn.info = "DATA";
      req_txn.info  = "REQ";
      rsp_txn.info  = "RSP";
      
      data_txn.uid = cfg.uid;
      req_txn.uid  = cfg.uid;
      rsp_txn.uid  = cfg.uid;
    end
    // OR Bus Txn
    else begin
      bus_txn = cxl_credit_bus_txn::type_id::create("bus_txn");

      bbt = bus_txn;
      
      bus_txn.uid      = cfg.uid;
      bus_txn.cmp_zero = cfg.cmp_zero;
    end

    forever begin 
      @(vif.mcb iff vif.mcb.vld);
      if (cfg.mon_indi) begin
        if (vif.mcb.dat[2:0] || cfg.broadcast_all) begin
          data_txn.credit = vif.mcb.dat;
          base_ap.write(dbt);
        end
        if (vif.mcb.req[2:0] || cfg.broadcast_all) begin
          req_txn.credit = vif.mcb.req;
          base_ap.write(rbt);
        end
        if (vif.mcb.rsp[2:0] || cfg.broadcast_all) begin
          rsp_txn.credit = vif.mcb.rsp;
          base_ap.write(sbt);
        end
      end
      else begin
        bus_txn.vld = 1'b1;
        bus_txn.req = vif.mcb.req;
        bus_txn.dat = vif.mcb.dat;
        bus_txn.rsp = vif.mcb.rsp;
        if (cfg.broadcast_all || bus_txn.has_mem_credits || bus_txn.has_cch_credits) begin
          ap.write(bus_txn);
          base_ap.write(bbt);
        end
      end
    end
  endtask 

endclass
