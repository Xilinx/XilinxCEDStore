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

  // These queues allow for the basepacker sequence to monitor which transactions to
  // send, adjusting for any biases or odds for certain types, before converting to
  // packed flits.
  // CXL.cache Queues
  h2dreq_c    h2dreq_q[$];
  h2ddat_c    h2ddat_q[$];
  h2drsp_c    h2drsp_q[$];
  d2hreq_c    d2hreq_q[$];
  d2hdat_c    d2hdat_q[$];
  d2hrsp_c    d2hrsp_q[$];
  // CXL.mem Queues
  m2sreq_c    m2sreq_q[$];
  m2srwd_c    m2srwd_q[$];
  m2sbirsp_c  m2sbirsp_q[$];
  s2mndr_c    s2mndr_q[$];
  s2mdrs_c    s2mdrs_q[$];
  s2mbisnp_c  s2mbisnp_q[$];

  function new(string name = "cxl_nfi_share");
    super.new(name);
  endfunction

  virtual function bit any_init_credits(prot_t prot);
    return (init_req_credit[prot] || init_dat_credit[prot] || init_rsp_credit[prot]);
  endfunction

  /*****************************************/
  // Popper : Potentially used by sequence //
  /*****************************************/

  virtual function h2dreq_c pop_h2dreq();
    return h2dreq_q.pop_front();
  endfunction

  virtual function h2ddat_c pop_h2ddat();
    return h2ddat_q.pop_front();
  endfunction

  virtual function h2drsp_c pop_h2drsp();
    return h2drsp_q.pop_front();
  endfunction

  virtual function d2hreq_c pop_d2hreq();
    return d2hreq_q.pop_front();
  endfunction

  virtual function d2hdat_c pop_d2hdat();
    return d2hdat_q.pop_front();
  endfunction

  virtual function d2hrsp_c pop_d2hrsp();
    return d2hrsp_q.pop_front();
  endfunction

  virtual function m2sreq_c pop_m2sreq();
    return m2sreq_q.pop_front();
  endfunction

  virtual function m2srwd_c pop_m2srwd();
    return m2srwd_q.pop_front();
  endfunction

  virtual function m2sbirsp_c pop_m2sbirsp();
    return m2sbirsp_q.pop_front();
  endfunction

  virtual function s2mndr_c pop_s2mndr();
    return s2mndr_q.pop_front();
  endfunction

  virtual function s2mdrs_c pop_s2mdrs();
    return s2mdrs_q.pop_front();
  endfunction

  virtual function s2mbisnp_c pop_s2mbisnp();
    return s2mbisnp_q.pop_front();
  endfunction

  /*****************************************/
  // Pusher : Potentially used by sequence //
  /*****************************************/
  virtual function void push_txn_q(base_txn txn);
    h2dreq_c    h2dreq;     d2hreq_c    d2hreq;
    h2ddat_c    h2ddat;     d2hdat_c    d2hdat;
    h2drsp_c    h2drsp;     d2hrsp_c    d2hrsp;
    m2sreq_c    m2sreq;     s2mndr_c    s2mndr;
    m2srwd_c    m2srwd;     s2mdrs_c    s2mdrs;
    m2sbirsp_c  m2sbirsp;   s2mbisnp_c  s2mbisnp;

    case (1'b1)
      $cast(h2dreq,   txn) : h2dreq_q.push_back(h2dreq);
      $cast(h2ddat,   txn) : h2ddat_q.push_back(h2ddat);
      $cast(h2drsp,   txn) : h2drsp_q.push_back(h2drsp);
      $cast(d2hreq,   txn) : d2hreq_q.push_back(d2hreq);
      $cast(d2hdat,   txn) : d2hdat_q.push_back(d2hdat);
      $cast(d2hrsp,   txn) : d2hrsp_q.push_back(d2hrsp);
      // -- //
      $cast(m2sreq,   txn) : m2sreq_q  .push_back(m2sreq  );
      $cast(m2srwd,   txn) : m2srwd_q  .push_back(m2srwd  );
      $cast(m2sbirsp, txn) : m2sbirsp_q.push_back(m2sbirsp);
      $cast(s2mndr,   txn) : s2mndr_q  .push_back(s2mndr  );
      $cast(s2mdrs,   txn) : s2mdrs_q  .push_back(s2mdrs  );
      $cast(s2mbisnp, txn) : s2mbisnp_q.push_back(s2mbisnp);
      default : `uvm_fatal(get_type_name(), "An unsupported TXN was pushed into the share object.")
    endcase
  endfunction

  // Convenience method
  virtual function bit qs_empty();
    return (!m2sreq_q.size && !m2srwd_q.size && !m2sbirsp_q.size &&
            !s2mndr_q.size && !s2mdrs_q.size && !s2mbisnp_q.size &&
            !h2ddat_q.size && !h2dreq_q.size && !h2drsp_q.size &&
            !d2hdat_q.size && !d2hreq_q.size && !d2hrsp_q.size);
  endfunction

endclass
