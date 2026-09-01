class aximon_txn #(
  parameter ADDR_WIDTH   = 64,
  parameter DATA_WIDTH   = 1024,
  parameter ID_WIDTH     = 16,
  parameter AWUSER_WIDTH = 512,
  parameter ARUSER_WIDTH = 512,
  parameter RUSER_WIDTH  = 512,
  parameter WUSER_WIDTH  = 512,
  parameter BUSER_WIDTH  = 512
) extends base_txn;

  `uvm_object_utils(aximon_txn)

  typedef enum {
    // Grouped TXN for easy access
    AXI_READ,
    AXI_WRITE,

    // Single Channel TXN for granularity
    AXI_ARADDR,
    AXI_AWADDR,
    AXI_BRESP,
    AXI_RDATA,
    AXI_WDATA
  } aximon_txn_t;

  typedef enum {
    AXI_ERR_NONE,
    AXI_ERR_AWID_REUSE,
    AXI_ERR_ARID_REUSE,
    AXI_ERR_BID_NO_AWID,
    AXI_ERR_RID_NO_ARID
  } aximon_err_t;

  aximon_txn_t               txn_type;
  aximon_err_t               err_type;

  int                        addr_width;
  int                        data_width;
  int                        id_width;
  int                        awuser_width;
  int                        aruser_width;
  int                        ruser_width;
  int                        wuser_width;
  int                        buser_width;

  logic [ADDR_WIDTH-1:0]     araddr;
  logic [1:0]                arburst;
  logic [3:0]                arcache;
  logic [ID_WIDTH-1:0]       arid;
  logic [7:0]                arlen;
  logic                      arlock;
  logic [2:0]                arprot;
  logic [3:0]                arqos;
  logic [2:0]                arsize;
  logic [ARUSER_WIDTH-1:0]   aruser;

  logic [ADDR_WIDTH-1:0]     awaddr;
  logic [1:0]                awburst;
  logic [3:0]                awcache;
  logic [ID_WIDTH-1:0]       awid;
  logic [7:0]                awlen;
  logic                      awlock;
  logic [2:0]                awprot;
  logic [3:0]                awqos;
  logic [2:0]                awsize;
  logic [AWUSER_WIDTH-1:0]   awuser;

  logic [DATA_WIDTH-1:0]     wdata[$];
  logic [DATA_WIDTH/8-1:0]   wstrb[$];
  logic [WUSER_WIDTH-1:0]    wuser[$];
  logic                      wlast;

  logic [1:0]                bresp;
  logic [ID_WIDTH-1:0]       bid;
  logic                      bvalid;

  logic [DATA_WIDTH-1:0]     rdata[$];
  logic [ID_WIDTH-1:0]       rid;
  logic [1:0]                rresp;
  logic [RUSER_WIDTH-1:0]    ruser[$];
  logic                      rlast;

  function new(string name = "aximon_txn");
    super.new(name);
    err_type = AXI_ERR_NONE;

    bvalid = 1;
    rlast  = 1;
    wlast  = 1;
  endfunction 

  virtual function void do_copy(uvm_object rhs);
    aximon_txn t; 
    super.do_copy(rhs);
    if (!$cast(t,rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't extended from aximon_txn")

    txn_type = t.txn_type;
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
    
    // Deep copy AXI W channel queues
    foreach(t.wdata[i]) wdata.push_back(t.wdata[i]);
    foreach(t.wstrb[i]) wstrb.push_back(t.wstrb[i]);
    foreach(t.wuser[i]) wuser.push_back(t.wuser[i]);
    wlast = t.wlast;
    
    // Copy AXI B channel signals
    bresp = t.bresp;
    bid   = t.bid;
    bvalid = t.bvalid;
    
    // Deep copy AXI R channel queues
    foreach(t.rdata[i]) rdata.push_back(t.rdata[i]);
    rid   = t.rid;
    rresp = t.rresp;
    foreach(t.ruser[i]) ruser.push_back(t.ruser[i]);
    rlast = t.rlast;
  endfunction

  virtual function void do_print(uvm_printer printer);
    printer.print_field("txn_type", txn_type, $bits(aximon_txn_t));
    printer.print_field("err_type", err_type, $bits(aximon_err_t));

    // Skip detailed printing if there's an error
    if (err_type != AXI_ERR_NONE)
      return;
    // Print based on transaction type
    if (txn_type == AXI_READ || txn_type == AXI_ARADDR) begin
      printer.print_field("araddr", araddr, addr_width);
      printer.print_field("arid", arid, id_width);
      printer.print_field("arlen", arlen, 8);
      printer.print_field("arsize", arsize, 3);
      printer.print_field("arburst", arburst, 2);
      printer.print_field("arlock", arlock, 1);
      printer.print_field("arcache", arcache, 4);
      printer.print_field("arprot", arprot, 3);
      printer.print_field("arqos", arqos, 4);
      printer.print_field("aruser", aruser, aruser_width);
    end
    
    if (txn_type == AXI_READ || txn_type == AXI_RDATA) begin
      printer.print_field("rid", rid, id_width);
      printer.print_field("rresp", rresp, 2);
      printer.print_field("rlast", rlast, 1);
      foreach(rdata[i]) printer.print_field($sformatf("rdata[%0d]", i), rdata[i], data_width);
      foreach(ruser[i]) printer.print_field($sformatf("ruser[%0d]", i), ruser[i], ruser_width);
    end
    
    if (txn_type == AXI_WRITE || txn_type == AXI_AWADDR) begin
      printer.print_field("awaddr", awaddr, addr_width);
      printer.print_field("awid", awid, id_width);
      printer.print_field("awlen", awlen, 8);
      printer.print_field("awsize", awsize, 3);
      printer.print_field("awburst", awburst, 2);
      printer.print_field("awlock", awlock, 1);
      printer.print_field("awcache", awcache, 4);
      printer.print_field("awprot", awprot, 3);
      printer.print_field("awqos", awqos, 4);
      printer.print_field("awuser", awuser, awuser_width);
    end
    
    if (txn_type == AXI_WRITE || txn_type == AXI_WDATA) begin
      printer.print_field("wlast", wlast, 1);
      foreach(wdata[i]) printer.print_field($sformatf("wdata[%0d]", i), wdata[i], data_width);
      foreach(wstrb[i]) printer.print_field($sformatf("wstrb[%0d]", i), wstrb[i], data_width/8);
      foreach(wuser[i]) printer.print_field($sformatf("wuser[%0d]", i), wuser[i], wuser_width);
    end
    
    if (txn_type == AXI_WRITE || txn_type == AXI_BRESP) begin
      printer.print_field("bid", bid, id_width);
      printer.print_field("bresp", bresp, 2);
      printer.print_field("bvalid", bvalid, 1);
    end
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    aximon_txn t;
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_compare got a txn that wasn't extended from aximon_txn")

    do_compare = comparer.compare_field_int("txn_type", txn_type, t.txn_type, $bits(aximon_txn_t));
    do_compare &= comparer.compare_field_int("err_type", err_type, t.err_type, $bits(aximon_err_t));

    // Skip detailed comparison if there's an error
    if (err_type != AXI_ERR_NONE)
      return do_compare;
    
    // Compare based on transaction type
    if (txn_type == AXI_READ || txn_type == AXI_ARADDR) begin
      do_compare &= comparer.compare_field_int("araddr", araddr, t.araddr, addr_width);
      do_compare &= comparer.compare_field_int("arid", arid, t.arid, id_width);
      do_compare &= comparer.compare_field_int("arlen", arlen, t.arlen, 8);
      do_compare &= comparer.compare_field_int("arsize", arsize, t.arsize, 3);
      do_compare &= comparer.compare_field_int("arburst", arburst, t.arburst, 2);
      do_compare &= comparer.compare_field_int("arlock", arlock, t.arlock, 1);
      do_compare &= comparer.compare_field_int("arcache", arcache, t.arcache, 4);
      do_compare &= comparer.compare_field_int("arprot", arprot, t.arprot, 3);
      do_compare &= comparer.compare_field_int("arqos", arqos, t.arqos, 4);
      do_compare &= comparer.compare_field_int("aruser", aruser, t.aruser, aruser_width);
    end
    
    if (txn_type == AXI_READ || txn_type == AXI_RDATA) begin
      do_compare &= comparer.compare_field_int("rlast", rlast, t.rlast, 1);
      do_compare &= comparer.compare_field_int("rid", rid, t.rid, id_width);
      do_compare &= comparer.compare_field_int("rresp", rresp, t.rresp, 2);
      do_compare &= (rdata.size() == t.rdata.size());
      foreach(rdata[i]) 
        do_compare &= comparer.compare_field_int($sformatf("rdata[%0d]", i), rdata[i], t.rdata[i], data_width);
      do_compare &= (ruser.size() == t.ruser.size());
      foreach(ruser[i]) 
        do_compare &= comparer.compare_field_int($sformatf("ruser[%0d]", i), ruser[i], t.ruser[i], ruser_width);
    end
    
    if (txn_type == AXI_WRITE || txn_type == AXI_AWADDR) begin
      do_compare &= comparer.compare_field_int("awaddr", awaddr, t.awaddr, addr_width);
      do_compare &= comparer.compare_field_int("awid", awid, t.awid, id_width);
      do_compare &= comparer.compare_field_int("awlen", awlen, t.awlen, 8);
      do_compare &= comparer.compare_field_int("awsize", awsize, t.awsize, 3);
      do_compare &= comparer.compare_field_int("awburst", awburst, t.awburst, 2);
      do_compare &= comparer.compare_field_int("awlock", awlock, t.awlock, 1);
      do_compare &= comparer.compare_field_int("awcache", awcache, t.awcache, 4);
      do_compare &= comparer.compare_field_int("awprot", awprot, t.awprot, 3);
      do_compare &= comparer.compare_field_int("awqos", awqos, t.awqos, 4);
      do_compare &= comparer.compare_field_int("awuser", awuser, t.awuser, awuser_width);
    end
    
    if (txn_type == AXI_WRITE || txn_type == AXI_WDATA) begin
      do_compare &= comparer.compare_field_int("wlast", wlast, t.wlast, 1);
      do_compare &= (wdata.size() == t.wdata.size());
      foreach(wdata[i]) 
        do_compare &= comparer.compare_field_int($sformatf("wdata[%0d]", i), wdata[i], t.wdata[i], data_width);
      do_compare &= (wstrb.size() == t.wstrb.size());
      foreach(wstrb[i]) 
        do_compare &= comparer.compare_field_int($sformatf("wstrb[%0d]", i), wstrb[i], t.wstrb[i], data_width/8);
      do_compare &= (wuser.size() == t.wuser.size());
      foreach(wuser[i]) 
        do_compare &= comparer.compare_field_int($sformatf("wuser[%0d]", i), wuser[i], t.wuser[i], wuser_width);
    end
    
    if (txn_type == AXI_WRITE || txn_type == AXI_BRESP) begin
      do_compare &= comparer.compare_field_int("bid", bid, t.bid, id_width);
      do_compare &= comparer.compare_field_int("bresp", bresp, t.bresp, 2);
      do_compare &= comparer.compare_field_int("bvalid", bvalid, t.bvalid, 1);
    end

    return do_compare;
  endfunction

endclass
