class cxl_credit_bus_txn extends base_txn;

  `uvm_object_utils(cxl_credit_bus_txn)

  logic       vld; 
  logic [3:0] req;
  logic [3:0] dat;
  logic [3:0] rsp;

  bit cmp_zero; //compare even if credit is zero

  // Sideband, to insert into pool sequence as a block of credits
  // potentially containing >64 and/or CXL.cache AND CXL.mem credits
  bit use_sideband;
  int req_cred[1:0];
  int dat_cred[1:0];
  int rsp_cred[1:0];

  function new(string name = "cxl_credit_bus_txn");
    super.new(name);
    txn_type = "CXL_CREDIT_BUS_TXN";
  endfunction

  // Decodes the lookup
  virtual function int convert2dec(bit [2:0] inp);
    return (!inp ? 0 : 2**(inp-1));
  endfunction

  virtual function bit [2:0] convert2enc(int inp);
    if (inp>=64) return 3'b111;
    else      
      // inp is <64
      case (inp[5:0]) inside
        6'b1????? : return 3'b110;
        6'b01???? : return 3'b101;
        6'b001??? : return 3'b100;
        6'b0001?? : return 3'b011;
        6'b00001? : return 3'b010;
        6'b000001 : return 3'b001;
        6'b000000 : return 3'b000;
      endcase
  endfunction

  virtual function bit get_mem_credits(output int req, dat, rsp);
    req = this.req[3] ? convert2dec(this.req[2:0]) : 0;
    dat = this.dat[3] ? convert2dec(this.dat[2:0]) : 0;
    rsp = this.rsp[3] ? convert2dec(this.rsp[2:0]) : 0;
    return (req || dat || rsp);
  endfunction

  virtual function bit get_cch_credits(output int req, dat, rsp);
    req = this.req[3] ? 0 : convert2dec(this.req[2:0]);
    dat = this.dat[3] ? 0 : convert2dec(this.dat[2:0]);
    rsp = this.rsp[3] ? 0 : convert2dec(this.rsp[2:0]);
    return (req || dat || rsp);
  endfunction

  virtual function bit has_mem_credits();
    int req, dat, rsp;
    return (get_mem_credits(req,dat,rsp));
  endfunction

  virtual function bit has_cch_credits();
    int req, dat, rsp;
    return (get_cch_credits(req,dat,rsp));
  endfunction

  function void do_print(uvm_printer printer);
    int crdreq, crddat, crdrsp;
    bit hadmem, hadcch;
    super.do_print(printer);
    printer.print_int("vld", vld, 1);
    if (use_sideband) begin
      printer.print_string("protocol", "CXL.mem");
      printer.m_scope.down(""); //increase indentation
      printer.print_int("req_cred[1]", req_cred[1], 32, UVM_UNSIGNED);
      printer.print_int("dat_cred[1]", dat_cred[1], 32, UVM_UNSIGNED);
      printer.print_int("rsp_cred[1]", rsp_cred[1], 32, UVM_UNSIGNED);
      printer.m_scope.up(); //decrease indentation
      printer.print_string("protocol", "CXL.cache");
      printer.m_scope.down(""); //increase indentation
      printer.print_int("req_cred[0]", req_cred[0], 32, UVM_UNSIGNED);
      printer.print_int("dat_cred[0]", dat_cred[0], 32, UVM_UNSIGNED);
      printer.print_int("rsp_cred[0]", rsp_cred[0], 32, UVM_UNSIGNED);
      printer.m_scope.up(); //decrease indentation
      if (!req_cred.sum() && !dat_cred.sum() && !rsp_cred.sum()) begin
        `uvm_warning(get_type_name, "Printed a txn that didn't return any credits")
      end
    end
    else begin
      hadmem = get_mem_credits(crdreq, crddat, crdrsp);
      if (hadmem) begin
        printer.print_string("protocol", "CXL.mem");
        printer.m_scope.down(""); //increase indentation
        if (crdreq) printer.print_string("req", $sformatf("'h%h (%0d)", this.req[2:0], crdreq));
        if (crddat) printer.print_string("dat", $sformatf("'h%h (%0d)", this.dat[2:0], crddat));
        if (crdrsp) printer.print_string("rsp", $sformatf("'h%h (%0d)", this.rsp[2:0], crdrsp));
        printer.m_scope.up(); //decrease indentation
      end
      hadcch = get_cch_credits(crdreq, crddat, crdrsp);
      if (hadcch) begin
        printer.print_string("protocol", "CXL.cache");
        printer.m_scope.down(""); //increase indentation
        if (crdreq) printer.print_string("req", $sformatf("'h%h (%0d)", this.req[2:0], crdreq));
        if (crddat) printer.print_string("dat", $sformatf("'h%h (%0d)", this.dat[2:0], crddat));
        if (crdrsp) printer.print_string("rsp", $sformatf("'h%h (%0d)", this.rsp[2:0], crdrsp));
        printer.m_scope.up(); //decrease indentation
      end
      if (!hadmem && !hadcch) begin
        printer.print_string("credits", "None");
        `uvm_warning(get_type_name, "Printed a txn that didn't return any credits")
      end
    end
  endfunction 

  virtual function void do_copy(uvm_object rhs);
    cxl_credit_bus_txn t;
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't a child of cxl_credit_bus_txn")
    super.do_copy(rhs);
    use_sideband = t.use_sideband;
    vld          = t.vld;
    req          = t.req;
    dat          = t.dat;
    rsp          = t.rsp;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    cxl_credit_bus_txn _rhs;
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "do_compare got a txn that wasn't a base class of cxl_credit_bus_txn")
    do_compare  = comparer.compare_string   ("txn_type", txn_type, _rhs.txn_type);
    do_compare &= comparer.compare_string   ("info",     info,     _rhs.info);
    do_compare &= comparer.compare_string   ("uid",      uid,      _rhs.uid);
    do_compare &= comparer.compare_field_int("vld",      vld,      _rhs.vld,       1);
    if (use_sideband) begin
      if (cmp_zero || req_cred[1]) 
        do_compare &= comparer.compare_field_int("req_cred[1]", req_cred[1], _rhs.req_cred[1], 32);
      if (cmp_zero || dat_cred[1]) 
        do_compare &= comparer.compare_field_int("dat_cred[1]", dat_cred[1], _rhs.dat_cred[1], 32);
      if (cmp_zero || rsp_cred[1]) 
        do_compare &= comparer.compare_field_int("rsp_cred[1]", rsp_cred[1], _rhs.rsp_cred[1], 32);
      if (cmp_zero || req_cred[0]) 
        do_compare &= comparer.compare_field_int("req_cred[0]", req_cred[0], _rhs.req_cred[0], 32);
      if (cmp_zero || dat_cred[0]) 
        do_compare &= comparer.compare_field_int("dat_cred[0]", dat_cred[0], _rhs.dat_cred[0], 32);
      if (cmp_zero || rsp_cred[0]) 
        do_compare &= comparer.compare_field_int("rsp_cred[0]", rsp_cred[0], _rhs.rsp_cred[0], 32);
    end
    else begin
      if (cmp_zero || convert2dec(req[2:0])) do_compare &= comparer.compare_field_int("req", req, _rhs.req, 4);
      if (cmp_zero || convert2dec(dat[2:0])) do_compare &= comparer.compare_field_int("dat", dat, _rhs.dat, 4);
      if (cmp_zero || convert2dec(rsp[2:0])) do_compare &= comparer.compare_field_int("rsp", rsp, _rhs.rsp, 4);
    end
  endfunction

endclass
