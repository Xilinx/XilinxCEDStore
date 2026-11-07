class cpi_vsequencer#(parameter bit [3:0] REQ, parameter bit [3:0] DATA, parameter bit [3:0] RSP) extends uvm_sequencer;

  `uvm_component_param_utils(cpi_vsequencer#(REQ,DATA,RSP))

  typedef base_sequencer#(global_txn, global_txn, global_txn, global_cfg, global_share) glbl_sqr_t;
  typedef base_sequencer#(req_txn, req_txn, req_txn, req_cfg, req_share)                req_sqr_t;
  typedef base_sequencer#(data_txn, data_txn, data_txn, data_cfg, data_share)           data_sqr_t;
  typedef base_sequencer#(rsp_txn, rsp_txn, rsp_txn, rsp_cfg, rsp_share)                rsp_sqr_t;

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("cpi_vsequencer#(%0d,%0d,%0d)",REQ,DATA,RSP);
  virtual function string get_type_name(); return type_name; endfunction

  cpi_cfg cfg;

  glbl_sqr_t glbl_sqr;
  // - Cannot have a zero sized array, so can either have [-1:SZ-1] or [0:SZ] to
  //   enable SZ=0 case. VCS won't elaborate in the former, so must use the 
  //   latter. The upper index will always point to null.
  req_sqr_t  req_sqr [0:REQ ]; 
  data_sqr_t data_sqr[0:DATA]; 
  rsp_sqr_t  rsp_sqr [0:RSP ]; 

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass
