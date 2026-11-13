class flit_base_txn extends base_txn;

  `uvm_object_utils(flit_base_txn)

  dir_t dir; 

  bit   empty_flit;
  bit   gap;

  // Only used by 256B flits
  flit_mode_t flitmode;

  // Txn credits consumed by the flit
  int   req_consumed[1:0] = '{0, 0}; //[protocol]
  int   dat_consumed[1:0] = '{0, 0}; //[protocol]
  int   rsp_consumed[1:0] = '{0, 0}; //[protocol]

  // Txn credits returned by the flit
  int   req_returned[1:0] = '{0, 0}; //[protocol]
  int   dat_returned[1:0] = '{0, 0}; //[protocol]
  int   rsp_returned[1:0] = '{0, 0}; //[protocol]

  // Control
  bit   disable_tight_pack_check;

  function new(string name = "flit_base_txn");
    super.new(name);
    txn_type = "FLIT_BASE_TXN";
  endfunction

endclass
