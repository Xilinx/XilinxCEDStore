class cxl_nfi_share extends base_share;
  
  `uvm_object_utils(cxl_nfi_share)

  // Agent will use these to determine if it's possible to send or receive 
  // a transaction; for a master, these are the counts of credits AVAILABLE
  // as given FROM the remote partner and for a slave, these are the counts 
  // of credits we've given TO the remote partner
  int avl_req_credit[1:0];
  int avl_dat_credit[1:0];
  int avl_rsp_credit[1:0];

  // Master agent will use these as a pool to return credits back to the remote parter
  // so it can send the local partner (us) flits. The give and init credits will be 
  // sent from the slave agent to the master agent. The ret*credit and the 
  // init*credit are different so we know the other side of the link is out of credits 
  // entirely.
  int give_req_credit[1:0]; int init_req_credit[1:0];
  int give_dat_credit[1:0]; int init_dat_credit[1:0];
  int give_rsp_credit[1:0]; int init_rsp_credit[1:0];

  function new(string name = "cxl_nfi_share");
    super.new(name);
  endfunction

  virtual function bit any_init_credits(prot_t prot);
    return (init_req_credit[prot] || init_dat_credit[prot] || init_rsp_credit[prot]);
  endfunction

endclass
