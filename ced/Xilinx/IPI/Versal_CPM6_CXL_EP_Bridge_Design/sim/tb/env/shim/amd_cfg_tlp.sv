// This class is used only for Cfg Space Read Requests and Write Requests for
// either non-flit mode or flit mode. Iff it is a Read Request, data returned
// will be in the payload field and iff expected was given, there will be a
// comparison to the payload and the match field will be set. The previous
// sentence is true iff you use the accompanying API methods. Only basic mode
// is currently implemented (build_rd/build_wr below), which simply requires
// bdf/addr/data/be to issue a transaction. A raw mode (for finer control
// over individual header fields) is planned but not yet implemented - see
// the note above expected_match() below.

class amd_cfg_tlp extends amd_base_tlp;

  `uvm_object_utils(amd_cfg_tlp)

  function new(string name = "amd_cfg_tlp");
    super.new(name);
  endfunction

  // -------------------------------------
  // SUMMARY DATA
  // -------------------------------------
  logic  [3:0][7:0] expected; //for read request, data to match (bit-by-bit)
  logic             match;    //for read request, match result
  bit signed [ 2:0] mismatch_sev; //neg=no print, pos=uvm_severity

  // -------------------------------------
  // BASIC IMPLEMENTATION
  //  . Assign by calling 'build_[wr,rd]'
  // -------------------------------------
  protected bit          basic = 1;
            bit          rd;       
            logic [15:0] dst_bdf; 
            bit   [11:0] addr;
            bit   [ 3:0] be;

  // -------------------------------------
  // RAW IMPLEMENTATION
  // -------------------------------------
  //  . HEADER: 3 DW
  // -------------------------------------
  cfg_hdr_u      hdr; 
  // -------------------------------------
  //  . FLIT MODE ONLY 
  //   -> Cfg Requests: OHC-A3 is required
  // -------------------------------------
  ohc_a3_s       ohc_a3;
  // -------------------------------------
  // PAYLOAD : 1 DW (WRITE) or 0 DW (READ)
  // . Big endian!
  // -------------------------------------
  bit [3:0][7:0] payload[$:1];

  // -------------------------------------
  // METHODS
  // -------------------------------------

  virtual function void build_rd(bit        [11:0] addr, 
                                 logic      [31:0] data         = 'x, 
                                 bit        [ 3:0] be           = '1, 
                                 logic      [15:0] bdf          = 'x,
                                 bit signed [ 2:0] mismatch_sev = UVM_ERROR); 
    // Reset prev. txn
    {cpl_sts, match} = {NO_CPL, 1'bx};
    payload.delete;
    // Constant
    rd    = 1;
    basic = 1;
    // Args
    this.addr         = addr;
    this.expected     = data;
    this.be           = be;
    this.mismatch_sev = mismatch_sev;
    // Error check
    if (bdf==='x && dst_bdf==='x)
      `uvm_fatal(get_type_name, "txn must have a dest. BDF specified")
    // Routing
    else if (bdf!=='x)
      this.dst_bdf = bdf;
  endfunction

  virtual function void build_wr(bit        [11:0] addr, 
                                 bit        [31:0] data,      
                                 bit        [ 3:0] be   = '1, 
                                 logic      [15:0] bdf  = 'x);
    // Reset prev. txn
    {cpl_sts, match, expected} = {NO_CPL, 1'bx, {32{1'bx}}};
    // Constant
    rd    = 0;
    basic = 1;
    // Args
    this.addr    = addr;
    this.payload = '{data};
    this.be      = be;
    // Error check
    if (bdf==='x && dst_bdf==='x)
      `uvm_fatal(get_type_name, "txn must have a dest. BDF specified")
    // Routing
    else if (bdf!=='x)
      this.dst_bdf = bdf;
  endfunction

  // Raw-mode build methods (build_rd_raw/build_wr_raw/build_rd_raw_fm/
  // build_wr_raw_fm) are not yet implemented - only basic mode (build_rd/
  // build_wr above) is currently usable. The hdr/ohc_a3 fields above exist
  // for a planned raw-mode implementation.

  virtual function bit expected_match();
    bit [3:0][7:0] rcvd = payload[0];
    // already been matched
    if (this.match!=='x) return this.match;
    // need to be compared
    if (expected==='x) begin  
      this.match = 1;
      return 1;
    end
    else begin
      foreach (rcvd[ii,jj]) begin
        if (expected[ii][jj]!==1'bx && (expected[ii][jj]!=rcvd[ii][jj])) begin
          this.match = 0;
          return 0;
        end
      end
      this.match = 1;
      return 1;
    end
  endfunction

  virtual function bit is_basic(); return basic; endfunction

endclass
