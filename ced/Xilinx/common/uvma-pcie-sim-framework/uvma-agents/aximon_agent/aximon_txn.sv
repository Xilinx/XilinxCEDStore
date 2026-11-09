class aximon_txn extends base_txn;

  `uvm_object_utils(aximon_txn)

  typedef enum {
    AXI_ERR_NONE,
    AXI_ERR_BID_NO_AWID,
    AXI_ERR_BID_NO_W,
    AXI_ERR_RID_NO_ARID
  } aximon_err_t;

  aximon_err_t   err_type;

  int            addr_width;
  int            data_width;
  int            id_width;
  int            awuser_width;
  int            aruser_width;
  int            ruser_width;
  int            wuser_width;
  int            buser_width;

  logic [  63:0] araddr;
  logic [   1:0] arburst;
  logic [   3:0] arcache;
  logic [  31:0] arid;
  logic [   7:0] arlen;
  logic          arlock;
  logic [   2:0] arprot;
  logic [   3:0] arqos;
  logic [   2:0] arsize;
  logic [ 255:0] aruser;
  logic          arvalid;
  logic          arready;

  logic [  63:0] awaddr;
  logic [   1:0] awburst;
  logic [   3:0] awcache;
  logic [  31:0] awid;
  logic [   7:0] awlen;
  logic          awlock;
  logic [   2:0] awprot;
  logic [   3:0] awqos;
  logic [   2:0] awsize;
  logic [ 255:0] awuser;
  logic          awvalid;
  logic          awready;

  logic [1023:0] wdata[$];
  logic [ 127:0] wstrb[$];
  logic [ 255:0] wuser[$];
  logic          wlast;
  logic          wvalid;
  logic          wready;

  logic [   1:0] bresp;
  logic [  31:0] bid;
  logic [ 255:0] buser;
  logic          bvalid;
  logic          bready;

  logic [1023:0] rdata[$];
  logic [  31:0] rid;
  logic [   1:0] rresp;
  logic [ 255:0] ruser[$];
  logic          rlast;
  logic          rvalid;
  logic          rready;

  function new(string name = "aximon_txn");
    super.new(name);
    txn_type = "AXIMON_TXN";
  endfunction

  // A field whose width is 0 is unused, so it is neither printed nor compared
  protected function void print_fld(uvm_printer printer, string name,
                                    uvm_bitstream_t value, int size);
    if (size > 0)
      printer.print_field(name, value, size);
  endfunction

  // Prints a response as binary plus its AXI name, e.g. "'b00 (OKAY)"
  protected function void print_rsp(uvm_printer printer, string name,
                                    logic [1:0] resp);
    string resp_name;
    case (resp)
      2'b00   : resp_name = "OKAY";
      2'b01   : resp_name = "EXOKAY";
      2'b10   : resp_name = "SLVERR";
      2'b11   : resp_name = "DECERR";
      default : resp_name = "UNKNOWN";
    endcase
    printer.print_string(name, $sformatf("'b%02b (%s)", resp, resp_name));
  endfunction

  protected function bit compare_fld(uvm_comparer comparer, string name,
                                     uvm_bitstream_t lhs, uvm_bitstream_t rhs,
                                     int size);
    if (size <= 0)
      return 1;
    return comparer.compare_field_int(name, lhs, rhs, size);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    aximon_txn t; 
    super.do_copy(rhs);
    if (!$cast(t,rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't extended from aximon_txn")

    err_type = t.err_type;

    addr_width   = t.addr_width;
    data_width   = t.data_width;
    id_width     = t.id_width;
    awuser_width = t.awuser_width;
    aruser_width = t.aruser_width;
    ruser_width  = t.ruser_width;
    wuser_width  = t.wuser_width;
    buser_width  = t.buser_width;
    
    // Copy AXI AR channel signals
    araddr  = t.araddr;
    arburst = t.arburst;
    arcache = t.arcache;
    arid    = t.arid;
    arlen   = t.arlen;
    arlock  = t.arlock;
    arprot  = t.arprot;
    arqos   = t.arqos;
    arsize  = t.arsize;
    aruser  = t.aruser;
    arvalid = t.arvalid;
    arready = t.arready;
    
    // Copy AXI AW channel signals
    awaddr  = t.awaddr;
    awburst = t.awburst;
    awcache = t.awcache;
    awid    = t.awid;
    awlen   = t.awlen;
    awlock  = t.awlock;
    awprot  = t.awprot;
    awqos   = t.awqos;
    awsize  = t.awsize;
    awuser  = t.awuser;
    awvalid = t.awvalid;
    awready = t.awready;
    
    // Deep copy AXI W channel queues
    wdata.delete(); foreach(t.wdata[i]) wdata.push_back(t.wdata[i]);
    wstrb.delete(); foreach(t.wstrb[i]) wstrb.push_back(t.wstrb[i]);
    wuser.delete(); foreach(t.wuser[i]) wuser.push_back(t.wuser[i]);
    wlast  = t.wlast;
    wvalid = t.wvalid;
    wready = t.wready;
    
    // Copy AXI B channel signals
    bresp  = t.bresp;
    bid    = t.bid;
    buser  = t.buser;
    bvalid = t.bvalid;
    bready = t.bready;
    
    // Deep copy AXI R channel queues
    rdata.delete(); foreach(t.rdata[i]) rdata.push_back(t.rdata[i]);
    ruser.delete(); foreach(t.ruser[i]) ruser.push_back(t.ruser[i]);
    rid    = t.rid;
    rresp  = t.rresp;
    rlast  = t.rlast;
    rvalid = t.rvalid;
    rready = t.rready;
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    print_fld(printer, "err_type", err_type, $bits(aximon_err_t));

    // Skip detailed printing if there's an error
    if (err_type != AXI_ERR_NONE)
      return;
    // Print based on transaction type
    if (info2 inside {"READ", "AR"}) begin
      print_fld(printer, "araddr",  araddr,  addr_width);
      print_fld(printer, "arid",    arid,    id_width);
      print_fld(printer, "arlen",   arlen,   8);
      print_fld(printer, "arsize",  arsize,  3);
      print_fld(printer, "arburst", arburst, 2);
      print_fld(printer, "arlock",  arlock,  1);
      print_fld(printer, "arcache", arcache, 4);
      print_fld(printer, "arprot",  arprot,  3);
      print_fld(printer, "arqos",   arqos,   4);
      print_fld(printer, "aruser",  aruser,  aruser_width);
      print_fld(printer, "arvalid", arvalid, 1);
      print_fld(printer, "arready", arready, 1);
    end
    
    if (info2 inside {"READ", "R"}) begin
      print_fld(printer, "rid",    rid,    id_width);
      print_rsp(printer, "rresp",  rresp);
      print_fld(printer, "rlast",  rlast,  1);
      print_fld(printer, "rvalid", rvalid, 1);
      print_fld(printer, "rready", rready, 1);
      foreach(rdata[i]) print_fld(printer, $sformatf("rdata[%0d]", i), rdata[i], data_width);
      foreach(ruser[i]) print_fld(printer, $sformatf("ruser[%0d]", i), ruser[i], ruser_width);
    end
    
    if (info2 inside {"WRITE", "AW"}) begin
      print_fld(printer, "awaddr",  awaddr,  addr_width);
      print_fld(printer, "awid",    awid,    id_width);
      print_fld(printer, "awlen",   awlen,   8);
      print_fld(printer, "awsize",  awsize,  3);
      print_fld(printer, "awburst", awburst, 2);
      print_fld(printer, "awlock",  awlock,  1);
      print_fld(printer, "awcache", awcache, 4);
      print_fld(printer, "awprot",  awprot,  3);
      print_fld(printer, "awqos",   awqos,   4);
      print_fld(printer, "awuser",  awuser,  awuser_width);
      print_fld(printer, "awvalid", awvalid, 1);
      print_fld(printer, "awready", awready, 1);
    end
    
    if (info2 inside {"WRITE", "W"}) begin
      print_fld(printer, "wlast",  wlast,  1);
      print_fld(printer, "wvalid", wvalid, 1);
      print_fld(printer, "wready", wready, 1);
      foreach(wdata[i]) print_fld(printer, $sformatf("wdata[%0d]", i), wdata[i], data_width);
      foreach(wstrb[i]) print_fld(printer, $sformatf("wstrb[%0d]", i), wstrb[i], data_width/8);
      foreach(wuser[i]) print_fld(printer, $sformatf("wuser[%0d]", i), wuser[i], wuser_width);
    end
    
    if (info2 inside {"WRITE", "B"}) begin
      print_fld(printer, "bid",    bid,    id_width);
      print_rsp(printer, "bresp",  bresp);
      print_fld(printer, "bvalid", bvalid, 1);
      print_fld(printer, "bready", bready, 1);
      print_fld(printer, "buser",  buser,  buser_width);
    end
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    aximon_txn t;
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_compare got a txn that wasn't extended from aximon_txn")

    do_compare  = comparer.compare_string   ("txn_type", txn_type, t.txn_type);
    do_compare &= comparer.compare_string   ("info",     info,     t.info);
    do_compare &= comparer.compare_string   ("info2",    info2,    t.info2);
    do_compare &= comparer.compare_field_int("err_type", err_type, t.err_type, $bits(aximon_err_t));

    // Skip detailed comparison if there's an error
    if (err_type != AXI_ERR_NONE)
      return do_compare;
    
    // Compare based on transaction type
    if (info2 inside {"READ", "AR"}) begin
      do_compare &= compare_fld(comparer, "araddr",  araddr,  t.araddr,  addr_width);
      do_compare &= compare_fld(comparer, "arid",    arid,    t.arid,    id_width);
      do_compare &= compare_fld(comparer, "arlen",   arlen,   t.arlen,   8);
      do_compare &= compare_fld(comparer, "arsize",  arsize,  t.arsize,  3);
      do_compare &= compare_fld(comparer, "arburst", arburst, t.arburst, 2);
      do_compare &= compare_fld(comparer, "arlock",  arlock,  t.arlock,  1);
      do_compare &= compare_fld(comparer, "arcache", arcache, t.arcache, 4);
      do_compare &= compare_fld(comparer, "arprot",  arprot,  t.arprot,  3);
      do_compare &= compare_fld(comparer, "arqos",   arqos,   t.arqos,   4);
      do_compare &= compare_fld(comparer, "aruser",  aruser,  t.aruser,  aruser_width);
      do_compare &= compare_fld(comparer, "arvalid", arvalid, t.arvalid, 1);
      do_compare &= compare_fld(comparer, "arready", arready, t.arready, 1);
    end
    
    if (info2 inside {"READ", "R"}) begin
      do_compare &= compare_fld(comparer, "rlast",  rlast,  t.rlast,  1);
      do_compare &= compare_fld(comparer, "rvalid", rvalid, t.rvalid, 1);
      do_compare &= compare_fld(comparer, "rready", rready, t.rready, 1);
      do_compare &= compare_fld(comparer, "rid",    rid,    t.rid,    id_width);
      do_compare &= compare_fld(comparer, "rresp",  rresp,  t.rresp,  2);
      if (data_width > 0) begin
        do_compare &= (rdata.size() == t.rdata.size());
        foreach(rdata[i])
          do_compare &= compare_fld(comparer, $sformatf("rdata[%0d]", i), rdata[i], t.rdata[i], data_width);
      end
      if (ruser_width > 0) begin
        do_compare &= (ruser.size() == t.ruser.size());
        foreach(ruser[i])
          do_compare &= compare_fld(comparer, $sformatf("ruser[%0d]", i), ruser[i], t.ruser[i], ruser_width);
      end
    end
    
    if (info2 inside {"WRITE", "AW"}) begin
      do_compare &= compare_fld(comparer, "awaddr",  awaddr,  t.awaddr,  addr_width);
      do_compare &= compare_fld(comparer, "awid",    awid,    t.awid,    id_width);
      do_compare &= compare_fld(comparer, "awlen",   awlen,   t.awlen,   8);
      do_compare &= compare_fld(comparer, "awsize",  awsize,  t.awsize,  3);
      do_compare &= compare_fld(comparer, "awburst", awburst, t.awburst, 2);
      do_compare &= compare_fld(comparer, "awlock",  awlock,  t.awlock,  1);
      do_compare &= compare_fld(comparer, "awcache", awcache, t.awcache, 4);
      do_compare &= compare_fld(comparer, "awprot",  awprot,  t.awprot,  3);
      do_compare &= compare_fld(comparer, "awqos",   awqos,   t.awqos,   4);
      do_compare &= compare_fld(comparer, "awuser",  awuser,  t.awuser,  awuser_width);
      do_compare &= compare_fld(comparer, "awvalid", awvalid, t.awvalid, 1);
      do_compare &= compare_fld(comparer, "awready", awready, t.awready, 1);
    end
    
    if (info2 inside {"WRITE", "W"}) begin
      do_compare &= compare_fld(comparer, "wlast",  wlast,  t.wlast,  1);
      do_compare &= compare_fld(comparer, "wvalid", wvalid, t.wvalid, 1);
      do_compare &= compare_fld(comparer, "wready", wready, t.wready, 1);
      if (data_width > 0) begin
        do_compare &= (wdata.size() == t.wdata.size());
        foreach(wdata[i])
          do_compare &= compare_fld(comparer, $sformatf("wdata[%0d]", i), wdata[i], t.wdata[i], data_width);
      end
      if (data_width/8 > 0) begin
        do_compare &= (wstrb.size() == t.wstrb.size());
        foreach(wstrb[i])
          do_compare &= compare_fld(comparer, $sformatf("wstrb[%0d]", i), wstrb[i], t.wstrb[i], data_width/8);
      end
      if (wuser_width > 0) begin
        do_compare &= (wuser.size() == t.wuser.size());
        foreach(wuser[i])
          do_compare &= compare_fld(comparer, $sformatf("wuser[%0d]", i), wuser[i], t.wuser[i], wuser_width);
      end
    end
    
    if (info2 inside {"WRITE", "B"}) begin
      do_compare &= compare_fld(comparer, "bid",    bid,    t.bid,    id_width);
      do_compare &= compare_fld(comparer, "bresp",  bresp,  t.bresp,  2);
      do_compare &= compare_fld(comparer, "bvalid", bvalid, t.bvalid, 1);
      do_compare &= compare_fld(comparer, "bready", bready, t.bready, 1);
      do_compare &= compare_fld(comparer, "buser",  buser,  t.buser,  buser_width);
    end

    return do_compare;
  endfunction

endclass
