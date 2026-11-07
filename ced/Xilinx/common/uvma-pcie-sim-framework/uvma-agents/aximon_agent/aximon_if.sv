interface aximon_if;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  wire           clk;
  wire           aresetn;

  // Set to 0 to disable all assertions and width checks in this interface,
  // e.g. when no agent is attached to the bus.
  bit            assertion_enable = 1;

  // Bus widths in bits, set by the monitor from aximon_cfg so the interface
  // checks agree with the agent. A width of 0 means the field is unused and
  // is not checked.
  int            addr_width   = 0;
  int            data_width   = 0;
  int            id_width     = 0;
  int            awuser_width = 0;
  int            aruser_width = 0;
  int            ruser_width  = 0;
  int            wuser_width  = 0;
  int            buser_width  = 0;

  // Address Read           // Read Data 
  logic [  63:0] araddr;    logic          rready;
  logic [   1:0] arburst;   logic [1023:0] rdata;
  logic [   3:0] arcache;   logic [  31:0] rid;
  logic [  31:0] arid;      logic          rlast;
  logic [   7:0] arlen;     logic [   1:0] rresp;
  logic          arlock;    logic          rvalid;
  logic [   2:0] arprot;    logic [ 255:0] ruser;
  logic [   3:0] arqos;
  logic [   2:0] arsize;
  logic [ 255:0] aruser;
  logic          arvalid;
  logic          arready;

  // Address Write          // Write Data            // Write Response 
  logic [  63:0] awaddr;    logic [1023:0] wdata;    logic          bready;
  logic [   1:0] awburst;   logic          wlast;    logic          bvalid;
  logic [   3:0] awcache;   logic [ 127:0] wstrb;    logic [ 255:0] buser;
  logic [  31:0] awid;      logic          wvalid;   logic [   1:0] bresp;
  logic [   7:0] awlen;     logic [ 255:0] wuser;    logic [  31:0] bid;
  logic          awlock;    logic          wready;
  logic [   2:0] awprot;
  logic [   3:0] awqos;
  logic [   2:0] awsize;
  logic [ 255:0] awuser;
  logic          awvalid;
  logic          awready;

  // mcb = "monitor clocking block" ; not qualified by anything
  clocking mcb @(posedge clk);
    input aresetn,
          araddr,   rready,  awaddr,   wdata,   bready,
          arburst,  rdata,   awburst,  wlast,   bvalid,
          arcache,  rid,     awcache,  wstrb,   bresp,
          arid,     rlast,   awid,     wvalid,  bid,
          arlen,    rresp,   awlen,    wuser,   buser,
          arlock,   rvalid,  awlock,   wready,
          arprot,   ruser,   awprot,
          arqos,             awqos,
          arsize,            awsize,
          aruser,            awuser,
          arvalid,           awvalid,
          arready,           awready;
  endclocking

  // Sanity check of the configured widths, run each time aresetn deasserts.
  // addr_width and data_width must be set; id and user widths may be 0
  // (unused). data_width must be a power of 2 of at least 8 bits.
  function automatic void check_width_range(string name, int val,
                                            int lo, int hi);
    if (val < lo || val > hi)
      `uvm_fatal("aximon_if",
        $sformatf("%m: %s=%0d is out of range, must be in [%0d:%0d]",
                  name, val, lo, hi))
  endfunction

  function automatic void check_widths();
    check_width_range("addr_width",   addr_width,    1,   64);
    check_width_range("data_width",   data_width,    8, 1024);
    if ((data_width & (data_width - 1)) != 0)
      `uvm_fatal("aximon_if",
        $sformatf("%m: data_width=%0d is not a power of 2", data_width))
    check_width_range("id_width",     id_width,      0,   32);
    check_width_range("awuser_width", awuser_width,  0,  256);
    check_width_range("aruser_width", aruser_width,  0,  256);
    check_width_range("wuser_width",  wuser_width,   0,  256);
    check_width_range("ruser_width",  ruser_width,   0,  256);
    check_width_range("buser_width",  buser_width,   0,  256);
  endfunction

  logic aresetn_q;

  always @(posedge clk) begin
    aresetn_q <= aresetn;
    if (assertion_enable && aresetn === 1'b1 && aresetn_q !== 1'b1)
      check_widths();
  end

  // No VALID signal may be high while aresetn is asserted. X is tolerated,
  // since models may not drive their outputs until reset is released;
  // p_handshake_known catches X once reset is deasserted.
  // The check starts on the second consecutive cycle of reset, which allows
  // a registered VALID one cycle to clear after reset is first sampled low.
  property p_valid_low_in_reset(valid);
    @(posedge clk) disable iff (!assertion_enable)
      (!aresetn && !$past(aresetn)) |-> valid !== 1'b1;
  endproperty

  a_arvalid_in_reset : assert property (p_valid_low_in_reset(arvalid))
    else `uvm_error("aximon_if", "ARVALID asserted while ARESETn is asserted")
  a_awvalid_in_reset : assert property (p_valid_low_in_reset(awvalid))
    else `uvm_error("aximon_if", "AWVALID asserted while ARESETn is asserted")
  a_wvalid_in_reset  : assert property (p_valid_low_in_reset(wvalid))
    else `uvm_error("aximon_if", "WVALID asserted while ARESETn is asserted")
  a_rvalid_in_reset  : assert property (p_valid_low_in_reset(rvalid))
    else `uvm_error("aximon_if", "RVALID asserted while ARESETn is asserted")
  a_bvalid_in_reset  : assert property (p_valid_low_in_reset(bvalid))
    else `uvm_error("aximon_if", "BVALID asserted while ARESETn is asserted")

  // Checks below are only active once aresetn is known to be deasserted.

  // Once VALID is asserted it must remain asserted until READY.
  property p_valid_hold(valid, ready);
    @(posedge clk) disable iff (!assertion_enable || aresetn !== 1'b1)
      (valid && !ready) |=> valid;
  endproperty

  // Payload must be stable while VALID is asserted and READY is not.
  property p_payload_hold(valid, ready, payload);
    @(posedge clk) disable iff (!assertion_enable || aresetn !== 1'b1)
      (valid && !ready) |=> $stable(payload);
  endproperty

  // VALID and READY must never be X/Z.
  property p_handshake_known(valid, ready);
    @(posedge clk) disable iff (!assertion_enable || aresetn !== 1'b1)
      !$isunknown({valid, ready});
  endproperty

  // Control fields must not be X/Z while VALID is asserted. User and data
  // signals are checked separately, limited to their configured widths.
  property p_payload_known(valid, payload);
    @(posedge clk) disable iff (!assertion_enable || aresetn !== 1'b1)
      valid |-> !$isunknown(payload);
  endproperty

  // 1 if none of the lowest 'width' bits of v are X/Z
  function automatic bit lsbs_known(logic [1023:0] v, int width);
    logic [1023:0] mask;
    mask = (width >= 1024) ? '1 : ((1024'(1) << width) - 1024'(1));
    return !$isunknown(v & mask);
  endfunction

  // 1 if every byte lane enabled by strb is free of X/Z. Disabled lanes may
  // legitimately carry X.
  function automatic bit wdata_known(logic [1023:0] data, logic [127:0] strb,
                                     int width);
    for (int i = 0; i < width/8 && i < 128; i++)
      if (strb[i] && $isunknown(data[8*i +: 8]))
        return 0;
    return 1;
  endfunction

  // Width-limited X/Z checks. A DUT may drive only the bits it uses, so bits
  // above the configured width are never checked. Write data is checked on
  // enabled byte lanes only; read data is checked on OKAY/EXOKAY responses
  // only, since data accompanying an error response is not meaningful. A
  // width of 0 means the field is unused, so the property does not run.
  property p_lsbs_known(valid, sig, width);
    @(posedge clk) disable iff (!assertion_enable || aresetn !== 1'b1 || width <= 0)
      valid |-> lsbs_known(1024'(sig), width);
  endproperty

  // WSTRB bits above the configured data width must not be set. X is
  // tolerated since those lanes may be undriven.
  property p_wstrb_upper_clear;
    @(posedge clk) disable iff (!assertion_enable || aresetn !== 1'b1 || data_width <= 0)
      wvalid |-> ((|(wstrb >> (data_width/8))) !== 1'b1);
  endproperty

  // SIZE must not exceed the data bus width: 8 * 2**size <= data_width
  property p_size_legal(valid, size);
    @(posedge clk) disable iff (!assertion_enable || aresetn !== 1'b1 || data_width <= 0)
      valid |-> ((32'd8 << size) <= data_width);
  endproperty

  property p_wdata_known;
    @(posedge clk) disable iff (!assertion_enable || aresetn !== 1'b1 || data_width <= 0)
      wvalid |-> wdata_known(wdata, wstrb, data_width);
  endproperty

  property p_rdata_known;
    @(posedge clk) disable iff (!assertion_enable || aresetn !== 1'b1 || data_width <= 0)
      (rvalid && !rresp[1]) |-> lsbs_known(rdata, data_width);
  endproperty

  // 4KB crossing is checked from the aligned start address, so an
  // unaligned first beat is not falsely flagged.
  function automatic bit crosses_4kb(
    bit [63:0] addr,
    bit [ 7:0] len,
    bit [ 2:0] size
  );
    bit [19:0] start;
    start = 20'(addr[11:0] >> size) << size;
    return (start + ((20'(len) + 20'd1) << size)) > 20'd4096;
  endfunction

  property p_burst_legal(valid, burst);
    @(posedge clk) disable iff (!assertion_enable || aresetn !== 1'b1)
      valid |-> (burst !== 2'b11);
  endproperty

  property p_wrap_len(valid, burst, len);
    @(posedge clk) disable iff (!assertion_enable || aresetn !== 1'b1)
      (valid && burst == 2'b10) |-> (len inside {8'd1, 8'd3, 8'd7, 8'd15});
  endproperty

  property p_fixed_len(valid, burst, len);
    @(posedge clk) disable iff (!assertion_enable || aresetn !== 1'b1)
      (valid && burst == 2'b00) |-> (len <= 8'd15);
  endproperty

  property p_incr_4kb(valid, burst, addr, len, size);
    @(posedge clk) disable iff (!assertion_enable || aresetn !== 1'b1)
      (valid && burst == 2'b01) |-> !crosses_4kb(addr, len, size);
  endproperty

  // VALID stability
  a_arvalid_hold : assert property (p_valid_hold(arvalid, arready))
    else `uvm_error("aximon_if", "ARVALID deasserted before ARREADY")
  a_awvalid_hold : assert property (p_valid_hold(awvalid, awready))
    else `uvm_error("aximon_if", "AWVALID deasserted before AWREADY")
  a_wvalid_hold  : assert property (p_valid_hold(wvalid,  wready))
    else `uvm_error("aximon_if", "WVALID deasserted before WREADY")
  a_rvalid_hold  : assert property (p_valid_hold(rvalid,  rready))
    else `uvm_error("aximon_if", "RVALID deasserted before RREADY")
  a_bvalid_hold  : assert property (p_valid_hold(bvalid,  bready))
    else `uvm_error("aximon_if", "BVALID deasserted before BREADY")

  // Payload stability
  a_ar_payload_hold : assert property (p_payload_hold(arvalid, arready,
    {araddr, arburst, arcache, arid, arlen, arlock, arprot, arqos, arsize,
     aruser}))
    else `uvm_error("aximon_if", "AR payload changed before ARREADY")
  a_aw_payload_hold : assert property (p_payload_hold(awvalid, awready,
    {awaddr, awburst, awcache, awid, awlen, awlock, awprot, awqos, awsize,
     awuser}))
    else `uvm_error("aximon_if", "AW payload changed before AWREADY")
  a_w_payload_hold  : assert property (p_payload_hold(wvalid, wready,
    {wdata, wlast, wstrb, wuser}))
    else `uvm_error("aximon_if", "W payload changed before WREADY")
  a_r_payload_hold  : assert property (p_payload_hold(rvalid, rready,
    {rdata, rid, rlast, rresp, ruser}))
    else `uvm_error("aximon_if", "R payload changed before RREADY")
  a_b_payload_hold  : assert property (p_payload_hold(bvalid, bready,
    {bid, bresp, buser}))
    else `uvm_error("aximon_if", "B payload changed before BREADY")

  // X/Z checks
  a_ar_hs_known : assert property (p_handshake_known(arvalid, arready))
    else `uvm_error("aximon_if", "ARVALID/ARREADY is X/Z")
  a_aw_hs_known : assert property (p_handshake_known(awvalid, awready))
    else `uvm_error("aximon_if", "AWVALID/AWREADY is X/Z")
  a_w_hs_known  : assert property (p_handshake_known(wvalid,  wready))
    else `uvm_error("aximon_if", "WVALID/WREADY is X/Z")
  a_r_hs_known  : assert property (p_handshake_known(rvalid,  rready))
    else `uvm_error("aximon_if", "RVALID/RREADY is X/Z")
  a_b_hs_known  : assert property (p_handshake_known(bvalid,  bready))
    else `uvm_error("aximon_if", "BVALID/BREADY is X/Z")

  a_ar_ctl_known : assert property (p_payload_known(arvalid,
    {arburst, arlen, arsize}))
    else `uvm_error("aximon_if", "AR control signal is X/Z with ARVALID")
  a_aw_ctl_known : assert property (p_payload_known(awvalid,
    {awburst, awlen, awsize}))
    else `uvm_error("aximon_if", "AW control signal is X/Z with AWVALID")
  a_w_ctl_known  : assert property (p_payload_known(wvalid, wlast))
    else `uvm_error("aximon_if", "WLAST is X/Z with WVALID")
  a_r_ctl_known  : assert property (p_payload_known(rvalid, {rlast, rresp}))
    else `uvm_error("aximon_if", "R control signal is X/Z with RVALID")
  a_b_ctl_known  : assert property (p_payload_known(bvalid, bresp))
    else `uvm_error("aximon_if", "BRESP is X/Z with BVALID")

  // Width-limited fields
  a_araddr_known : assert property (
    p_lsbs_known(arvalid, araddr, addr_width))
    else `uvm_error("aximon_if", "ARADDR is X/Z with ARVALID")
  a_awaddr_known : assert property (
    p_lsbs_known(awvalid, awaddr, addr_width))
    else `uvm_error("aximon_if", "AWADDR is X/Z with AWVALID")
  a_arid_known   : assert property (p_lsbs_known(arvalid, arid, id_width))
    else `uvm_error("aximon_if", "ARID is X/Z with ARVALID")
  a_awid_known   : assert property (p_lsbs_known(awvalid, awid, id_width))
    else `uvm_error("aximon_if", "AWID is X/Z with AWVALID")
  a_rid_known    : assert property (p_lsbs_known(rvalid, rid, id_width))
    else `uvm_error("aximon_if", "RID is X/Z with RVALID")
  a_bid_known    : assert property (p_lsbs_known(bvalid, bid, id_width))
    else `uvm_error("aximon_if", "BID is X/Z with BVALID")
  a_wstrb_known  : assert property (
    p_lsbs_known(wvalid, wstrb, data_width/8))
    else `uvm_error("aximon_if", "WSTRB is X/Z with WVALID")
  a_wstrb_upper_clear : assert property (p_wstrb_upper_clear)
    else `uvm_error("aximon_if", "WSTRB set above the configured data width")
  a_arsize_legal : assert property (p_size_legal(arvalid, arsize))
    else `uvm_error("aximon_if", "ARSIZE exceeds the configured data width")
  a_awsize_legal : assert property (p_size_legal(awvalid, awsize))
    else `uvm_error("aximon_if", "AWSIZE exceeds the configured data width")

  a_awuser_known : assert property (
    p_lsbs_known(awvalid, awuser, awuser_width))
    else `uvm_error("aximon_if", "AWUSER is X/Z with AWVALID")
  a_aruser_known : assert property (
    p_lsbs_known(arvalid, aruser, aruser_width))
    else `uvm_error("aximon_if", "ARUSER is X/Z with ARVALID")
  a_wuser_known  : assert property (
    p_lsbs_known(wvalid, wuser, wuser_width))
    else `uvm_error("aximon_if", "WUSER is X/Z with WVALID")
  a_ruser_known  : assert property (
    p_lsbs_known(rvalid, ruser, ruser_width))
    else `uvm_error("aximon_if", "RUSER is X/Z with RVALID")
  a_buser_known  : assert property (
    p_lsbs_known(bvalid, buser, buser_width))
    else `uvm_error("aximon_if", "BUSER is X/Z with BVALID")
  a_wdata_known  : assert property (p_wdata_known)
    else `uvm_error("aximon_if", "WDATA is X/Z on an enabled byte lane")
  a_rdata_known  : assert property (p_rdata_known)
    else `uvm_error("aximon_if", "RDATA is X/Z on a non-error response")

  // Burst legality
  a_arburst_legal : assert property (p_burst_legal(arvalid, arburst))
    else `uvm_error("aximon_if", "ARBURST uses reserved encoding 2'b11")
  a_awburst_legal : assert property (p_burst_legal(awvalid, awburst))
    else `uvm_error("aximon_if", "AWBURST uses reserved encoding 2'b11")
  a_arwrap_len : assert property (p_wrap_len(arvalid, arburst, arlen))
    else `uvm_error("aximon_if", "WRAP read burst ARLEN not 1, 3, 7 or 15")
  a_awwrap_len : assert property (p_wrap_len(awvalid, awburst, awlen))
    else `uvm_error("aximon_if", "WRAP write burst AWLEN not 1, 3, 7 or 15")
  a_arfixed_len : assert property (p_fixed_len(arvalid, arburst, arlen))
    else `uvm_error("aximon_if", "FIXED read burst ARLEN exceeds 15")
  a_awfixed_len : assert property (p_fixed_len(awvalid, awburst, awlen))
    else `uvm_error("aximon_if", "FIXED write burst AWLEN exceeds 15")
  a_arincr_4kb : assert property (
    p_incr_4kb(arvalid, arburst, araddr, arlen, arsize))
    else `uvm_error("aximon_if", "INCR read burst crosses a 4KB boundary")
  a_awincr_4kb : assert property (
    p_incr_4kb(awvalid, awburst, awaddr, awlen, awsize))
    else `uvm_error("aximon_if", "INCR write burst crosses a 4KB boundary")

endinterface
