class slot_base extends base_txn;

  `uvm_object_utils(slot_base)

  dir_t         dir;
  slot_fmt_t    _fmt; 
  bit           empty_slot; 
  logic [127:0] data;

  /* 68B ONLY */
  // Slots will set these so flit header fields be set accordingly.
  // Only used for data transfers. x means hasn't been set, z means
  // don't care.
  logic         hdr_be = 1'bx;
  logic         hdr_sz = 1'bx;
 
  // Credits required to send a slot
  int req_consumed[1:0] = '{0, 0}; //[protocol]
  int dat_consumed[1:0] = '{0, 0}; //[protocol]
  int rsp_consumed[1:0] = '{0, 0}; //[protocol]

  function new(string name = "slot_base");
    super.new(name);
  endfunction

endclass

class slot_rsvd extends slot_base;

  `uvm_object_utils(slot_rsvd)

  function new(string name = "slot_rsvd");
    super.new(name);
    _fmt = _RSVD;
    txn_type = "RSVD";
    data = '0;
    empty_slot = 1;
  endfunction

  virtual function void check_rsvd();
    if (|data)
      `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
  endfunction

endclass

