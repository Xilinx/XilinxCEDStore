class cxl_credit_share extends base_share;

  `uvm_object_utils(cxl_credit_share)

  function new(string name = "cxl_credit_share");
    super.new(name);
  endfunction    

  // If the agent is configured to use the pool sequence,
  // it will examine these members to see what credits can
  // be returned.
  int req_credit_pool[1:0];
  int dat_credit_pool[1:0];
  int rsp_credit_pool[1:0];

  virtual function bit any_credits;
    return (req_credit_pool.sum || dat_credit_pool.sum || rsp_credit_pool.sum);
  endfunction

endclass
