class cxl_credit_api#(type SQR) extends base_api#(SQR);

  `uvm_component_param_utils(cxl_credit_api#(SQR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"cxl_credit_api#(",SQR::type_name,")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // This will send several valid txns on the bus until all credits are returned
  virtual task issue_mem_txns(int unsigned req = 0, dat = 0, rsp = 0);
    cxl_credit_api_seq seq = cxl_credit_api_seq::type_id::create("seq");
    if (!req && !dat && !rsp) begin
      `uvm_warning(get_type_name, "Trying to send a txn with no valid credits, returning");
      return;
    end
    // Control
    seq.mem_req = req; 
    seq.mem_dat = dat; 
    seq.mem_rsp = rsp; 
    // Start it
    seq.start(sqr);
  endtask

  // This will send several valid txns on the bus until all credits are returned
  virtual task issue_cch_txns(int unsigned req = 0, dat = 0, rsp = 0);
    cxl_credit_api_seq seq = cxl_credit_api_seq::type_id::create("seq");
    if (!req && !dat && !rsp) begin
      `uvm_warning(get_type_name, "Trying to send a txn with no valid credits, returning");
      return;
    end
    // Control
    seq.cch_req = req; 
    seq.cch_dat = dat; 
    seq.cch_rsp = rsp; 
    // Start it
    seq.start(sqr);
  endtask

  // This will send several valid txns on the bus until all credits are returned
  virtual task issue_txns(int unsigned mem_req = 0, mem_dat = 0, mem_rsp = 0,
                                       cch_req = 0, cch_dat = 0, cch_rsp = 0);
    cxl_credit_api_seq seq = cxl_credit_api_seq::type_id::create("seq");
    if (!mem_req && !mem_dat && !mem_rsp && !cch_req && !cch_dat && !cch_rsp) begin
      `uvm_warning(get_type_name, "Trying to send a txn with no valid credits, returning");
      return;
    end
    // Control
    seq.mem_req = mem_req; 
    seq.mem_dat = mem_dat; 
    seq.mem_rsp = mem_rsp; 
    seq.cch_req = cch_req; 
    seq.cch_dat = cch_dat; 
    seq.cch_rsp = cch_rsp; 
    // Start
    seq.start(sqr);
  endtask

endclass
