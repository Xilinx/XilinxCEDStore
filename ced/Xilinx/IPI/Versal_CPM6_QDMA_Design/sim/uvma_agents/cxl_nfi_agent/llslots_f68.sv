class llcrd_f68 extends slot_base;

  `uvm_object_utils(llcrd_f68)

  rand logic [7:0] full_ack = 'x; //{ack7to4, ak, ack2to0};

  typedef union packed {
    logic [63:0] payload;
    struct packed {
      logic [63:8] rsvd1;
      logic [ 7:4] ak7to4;
      logic        rsvd0;
      logic [ 2:0] ak2to0;
    } acknowledge;
  } payload_t;

  payload_t       payload = '0;
  logic [23:0]    rsvd3 = '0;
  llcrd_subtype_t subtype = _ACK;
  llctrl_t        llctrl = LLCRD;
  logic [ 3:0]    datcrd;
  logic [ 3:0]    reqcrd;
  logic [ 3:0]    rspcrd;
  logic [11:0]    rsvd2 = '0;
  logic [ 2:0]    ctl_fmt = '0;
  logic [ 1:0]    rsvd1 = '0;
  logic           ak; 
  logic           rsvd0 = '0;
  flit68_t        Type = CONTROL; 

  function new(string name = "llcrd_f68");
    super.new(name);
    _fmt = _LLCRD;
    txn_type = "LLCRD_F68";
  endfunction

  virtual function void do_print(uvm_printer printer);
    string       prot;
    int unsigned credits;
    super.do_print(printer);
    printer.print_string ("dir",               dir.name);
    printer.print_string ("subtype",           subtype.name);
    printer.print_int    ("Full_Ack ",         full_ack, 8, UVM_DEC);
    prot    = reqcrd[3]   ? "CXL.mem  "   : "CXL.cache";
    credits = reqcrd[2:0] ? 2**(reqcrd[2:0]-1) : 0;
    printer.print_string ("ReqCrd",            $sformatf("%0s : %0d", prot, credits));
    prot    = datcrd[3]   ? "CXL.mem  "   : "CXL.cache";
    credits = datcrd[2:0] ? 2**(datcrd[2:0]-1) : 0;
    printer.print_string ("DatCrd",            $sformatf("%0s : %0d", prot, credits));
    prot    = rspcrd[3]   ? "CXL.mem  "   : "CXL.cache";
    credits = rspcrd[2:0] ? 2**(rspcrd[2:0]-1) : 0;
    printer.print_string ("RspCrd",            $sformatf("%0s : %0d", prot, credits));
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void check_rsvd();
    if (subtype.name == "")
      `uvm_error(get_type_name, $sformatf("Subtype 'b%b of LLCRD flit is invalid", subtype))
    else if (|{payload.acknowledge.rsvd1, payload.acknowledge.rsvd0})
      `uvm_error(get_type_name, "Reserved bits of LLCRD.Acknowledge flit's payload are not 0; see CXL spec")
    if (|{rsvd3, rsvd2, rsvd1, rsvd0})
      `uvm_error(get_type_name, "Reserved bits of slot are not 0, see CXL spec")
    if (ctl_fmt != '0)
      `uvm_error(get_type_name, "ctl_fmt of LLCRD flit must be 0, see CXL spec")
  endfunction

  // Parent classes will call these
  virtual function void pack_slot();
    if (full_ack === 'x) void'(this.randomize());
    {payload.acknowledge.ak7to4, ak, payload.acknowledge.ak2to0} = full_ack;
    data = {payload, rsvd3, subtype, llctrl, datcrd, reqcrd, rspcrd, rsvd2, ctl_fmt, rsvd1, ak, rsvd0, Type};
    check_rsvd();
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    this.dir = dir;
    if (dat !== 'x) data = dat;
    {payload, rsvd3, subtype, llctrl, datcrd, reqcrd, rspcrd, rsvd2, ctl_fmt, rsvd1, ak, rsvd0, Type} = data;
    full_ack = {payload.acknowledge.ak7to4, ak, payload.acknowledge.ak2to0};
    check_rsvd();
  endfunction

endclass

class retry_f68 extends slot_base;

  `uvm_object_utils(retry_f68)

  typedef union packed {
    logic [63:0] payload;
    struct packed {
      logic [63:0] rsvd;
    } idle;
    struct packed {
      logic [63:26] rsvd1;
      logic [ 4: 0] num_phy_reinit;
      logic [ 4: 0] num_retry;
      logic [15: 8] rsvd0;
      logic [ 7: 0] eseq;
    } req;
    struct packed {
      logic [63:48] rsvd1;
      logic [15: 0] viral_ldid;
      logic [ 7: 0] retry_numfreebuf;
      logic [ 7: 0] eseq_echo;
      logic [ 7: 0] retry_wrptr;
      logic [ 4: 0] num_retry_echo;
      logic         rsvd0;
      logic         viral;
      logic         empty;
    } ack;
    struct packed {
      logic [63:0] rsvd;
    } frame;
  } payload_t;

  payload_t       payload = '0;
  logic [23:0]    rsvd2 = '0;
  retry_subtype_t subtype;
  llctrl_t        llctrl = RETRY;
  logic [23:0]    rsvd1 = '0;
  logic [ 2:0]    ctl_fmt = '0;
  logic [ 3:0]    rsvd0 = '0;
  flit68_t        Type = CONTROL; 

  function new(string name = "retry_f68");
    super.new(name);
    _fmt = _RETRY;
    txn_type = "RETRY_F68";
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_string ("dir",      dir.name);
    printer.print_string ("subtype",  subtype.name);
    case (subtype)
      _REQ  : print_req(printer);
      _RACK : print_ack(printer);
    endcase
  endfunction

  virtual function void print_req(uvm_printer printer);
    printer.print_int ("payload::eseq",           payload.req.eseq,           8);
    printer.print_int ("payload::num_retry",      payload.req.num_retry,      5);
    printer.print_int ("payload::num_phy_reinit", payload.req.num_phy_reinit, 5);
  endfunction

  virtual function void print_ack(uvm_printer printer);
    printer.print_int ("payload::empty",            payload.ack.empty,            1);
    printer.print_int ("payload::viral",            payload.ack.viral,            1);
    printer.print_int ("payload::num_retry_echo",   payload.ack.num_retry_echo,   5);
    printer.print_int ("payload::retry_wrptr",      payload.ack.retry_wrptr,      8);
    printer.print_int ("payload::eseq_echo",        payload.ack.eseq_echo,        8);
    printer.print_int ("payload::retry_numfreebuf", payload.ack.retry_numfreebuf, 8);
    printer.print_int ("payload::viral_ldid",       payload.ack.viral_ldid,       16);
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void check_rsvd();
    bit rsvd;
    if (subtype.name == "")
      `uvm_error(get_type_name, $sformatf("Subtype 'b%b of RETRY flit is invalid", subtype))
    else begin 
      case (subtype)
        _RIDLE  : rsvd = |payload.idle.rsvd;
        _REQ    : rsvd = |{payload.req.rsvd1, payload.req.rsvd0};
        _RACK   : rsvd = |{payload.ack.rsvd1, payload.req.rsvd0};
        _FRAME  : rsvd = |payload.frame.rsvd;
      endcase
      if (rsvd)
        `uvm_error(get_type_name, $sformatf("Reserved bits of Retry.%0s flit's payload are not 0; see CXL spec",subtype.name))
    end
    if (|{rsvd2, rsvd1, rsvd0})
      `uvm_error(get_type_name, "Reserved bits of slot are not 0, see CXL spec")
    if (ctl_fmt != '0)
      `uvm_error(get_type_name, "ctl_fmt of RETRY flit must be 0, see CXL spec")
  endfunction

  // Parent classes will call these
  virtual function void pack_slot();
    data = {payload, rsvd2, subtype, llctrl, rsvd1, ctl_fmt, rsvd0, Type};
    check_rsvd();
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    this.dir = dir;
    if (dat !== 'x) data = dat;
    {payload, rsvd2, subtype, llctrl, rsvd1, ctl_fmt, rsvd0, Type} = data;
    check_rsvd();
  endfunction

endclass

class ide_f68 extends slot_base;

  `uvm_object_utils(ide_f68)

  typedef union packed {
    logic [95:0] payload;
    struct packed {
      logic [95:0] rsvd;
    } idle;
    struct packed {
      logic [95:0] rsvd;
    } start;
    struct packed {
      logic [95:0] msg;
    } tmac;
  } payload_t;

  payload_t     payload = '0;
  ide_subtype_t subtype;
  llctrl_t      llctrl = IDE;
  logic [15:0]  rsvd1 = '0;
  logic [ 2:0]  ctl_fmt = 3'h1;
  logic [ 3:0]  rsvd0 = '0;
  flit68_t      Type = CONTROL; 

  function new(string name = "ide_f68");
    super.new(name);
    _fmt = _IDE;
    txn_type = "IDE_F68";
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_string ("dir",      dir.name);
    printer.print_string ("subtype",  subtype.name);
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void check_rsvd();
    bit rsvd;
    if (subtype.name == "")
      `uvm_error(get_type_name, $sformatf("Subtype 'b%b of IDE flit is invalid", subtype))
    else begin 
      case (subtype)
        _IDLE  : rsvd = |payload.idle.rsvd;
        _START : rsvd = |payload.start.rsvd;
      endcase
      if (rsvd)
        `uvm_error(get_type_name, $sformatf("Reserved bits of IDE.%0s flit's payload are not 0; see CXL spec",subtype.name))
    end
    if (|{rsvd1, rsvd0})
      `uvm_error(get_type_name, "Reserved bits of slot are not 0, see CXL spec")
    if (ctl_fmt != 'd1)
      `uvm_error(get_type_name, "ctl_fmt of IDE flit must be 1, see CXL spec")
  endfunction

  // Parent classes will call these
  virtual function void pack_slot();
    data = {payload, subtype, llctrl, rsvd1, ctl_fmt, rsvd0, Type};
    check_rsvd();
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    this.dir = dir;
    if (dat !== 'x) data = dat;
    {payload, subtype, llctrl, rsvd1, ctl_fmt, rsvd0, Type} = data;
    check_rsvd();
  endfunction

endclass

class init_f68 extends slot_base;

  `uvm_object_utils(init_f68)

  typedef enum logic [3:0] {CXL1 = 'b0001, CXL2 = 'b0010} version_t;

  rand bit [7:0] r_llr_wrap;
  rand version_t r_version;

  typedef union packed {
    logic [63:0] payload;
    struct packed {
      logic [63:32] rsvd1;
      logic [ 7: 0] llr_wrap;
      logic [23: 4] rsvd0;
      version_t     version;
    } param;
  } payload_t;

  payload_t      payload = '0;
  logic [23:0]   rsvd2 = '0;
  init_subtype_t subtype = _PARAM;
  llctrl_t       llctrl = INIT;
  logic [23:0]   rsvd1 = '0;
  logic [ 2:0]   ctl_fmt = '0;
  logic [ 3:0]   rsvd0 = '0;
  flit68_t       Type = CONTROL; 

  function new(string name = "init_f68");
    super.new(name);
    _fmt = _INIT;
    txn_type = "INIT_F68";
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_string ("dir",               dir.name);
    printer.print_string ("subtype",           subtype.name);
    printer.print_int    ("payload::version",  payload.param.version,  4, UVM_DEC);
    printer.print_int    ("payload::llr_wrap", payload.param.llr_wrap, 8, UVM_DEC);
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void check_rsvd();
    if (subtype.name == "")
      `uvm_error(get_type_name, $sformatf("Subtype 'b%b of INIT flit is invalid", subtype))
    else if (|{payload.param.rsvd1, payload.param.rsvd0})
      `uvm_error(get_type_name, "Reserved bits of INIT.Param flit's payload are not 0; see CXL spec")
    if (|{rsvd2, rsvd1, rsvd0})
      `uvm_error(get_type_name, "Reserved bits of slot are not 0, see CXL spec")
    if (ctl_fmt != 'd0)
      `uvm_error(get_type_name, "ctl_fmt of INIT flit must be 0, see CXL spec")
  endfunction

  // Parent classes will call these
  virtual function void pack_slot();
    void'(this.randomize());
    payload.param.version  = r_version;
    payload.param.llr_wrap = r_llr_wrap;
    data = {payload, rsvd2, subtype, llctrl, rsvd1, ctl_fmt, rsvd0, Type};
    check_rsvd();
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    this.dir = dir;
    if (dat !== 'x) data = dat;
    {payload, rsvd2, subtype, llctrl, rsvd1, ctl_fmt, rsvd0, Type} = data;
    check_rsvd();
  endfunction

endclass
