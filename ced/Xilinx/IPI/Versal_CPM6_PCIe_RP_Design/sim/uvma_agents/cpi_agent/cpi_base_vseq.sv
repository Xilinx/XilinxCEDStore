class cpi_base_vseq#(parameter bit [3:0] REQ, parameter bit [3:0] DATA, parameter bit [3:0] RSP) extends uvm_sequence;

  `uvm_object_param_utils(cpi_base_vseq#(REQ,DATA,RSP))
  `uvm_declare_p_sequencer(cpi_vsequencer#(REQ,DATA,RSP))

  typedef base_sequencer#(req_txn, req_txn, req_txn, req_cfg, req_share)      req_sqr_t; 
  typedef base_sequencer#(data_txn, data_txn, data_txn, data_cfg, data_share) data_sqr_t; 
  typedef base_sequencer#(rsp_txn, rsp_txn, rsp_txn, rsp_cfg, rsp_share)      rsp_sqr_t; 

  // cpi_agent restricts to a maximum of 8 channels of each
  req_sqr_t  req_sqr [0:REQ];
  data_sqr_t data_sqr[0:DATA];
  rsp_sqr_t  rsp_sqr [0:RSP];

  function new(string name = "cpi_base_vseq");
    super.new(name);
  endfunction

  //call_pre_post must equal 1 and must execute sequence via start method
  virtual task pre_body();
    foreach(p_sequencer.req_sqr[ii]) begin
      if (p_sequencer.req_sqr[ii] != null)
        req_sqr[ii] = p_sequencer.req_sqr[ii]; 
    end
    foreach(p_sequencer.data_sqr[ii]) begin
      if (p_sequencer.data_sqr[ii] != null)
        data_sqr[ii] = p_sequencer.data_sqr[ii]; 
    end
    foreach(p_sequencer.rsp_sqr[ii]) begin
      if (p_sequencer.rsp_sqr[ii] != null)
        rsp_sqr[ii] = p_sequencer.rsp_sqr[ii]; 
    end
  endtask

  virtual task body();
    if (p_sequencer.glbl_sqr.shr.conn_state != CONNECTED) begin
      `uvm_error(get_type_name, "CPI has not reached a CONNECTED state using global channel, cannot run sequence")
      return;
    end
  endtask

endclass
