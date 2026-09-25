// This class is used only for Cfg Space Read Requests and Write Requests for
// either non-flit mode or flit mode. Iff it is a Read Request, data returned
// will be in the payload field and iff expected was given, there will be a
// comparison to the payload and the match field will be set. The previous 
// sentence is true iff you use the accompanying API methods. There are two
// ways to use this object: the basic and raw mode. Most users will want to 
// use the basic mode, which simply requires bdf/addr/data/be to issue a 
// transaction. If more control is required, then the raw mode will need to
// be used.

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

//  . build_rd_raw
//  . build_wr_raw
//  . build_rd_raw_fm
//  . build_wr_raw_fm

//  virtual function void build_write(bit [15:0] bdf, bit [11:0] addr, bit [31:0] data, 
//                                    bit [ 3:0] be = '1);
//    // Reset summary
//    {match, sc, rd} = 3'b000;
//    // Non-flit mode
//    if (!fm) begin
//      /* 3 DW Header */
//      // DW0
//      hdr.nfm.dw0.fmt   = 3'b010;
//    //hdr.nfm.dw0.type_ = 5'b0_010x; //automatic: Type0 or Type1 
//    //hdr.nfm.dw0.t9    = 1'b0;      //automatic: tag
//      hdr.nfm.dw0.tc    = 3'b0;
//    //hdr.nfm.dw0.t8    = 1'b0;      //automatic: tag
//      hdr.nfm.dw0.a2    = 1'b0;
//      hdr.nfm.dw0.RSVD0 = 1'b0;
//      hdr.nfm.dw0.th    = 1'b0; 
//      hdr.nfm.dw0.td    = 1'b0;
//      hdr.nfm.dw0.ep    = 1'b0;
//      hdr.nfm.dw0.attr  = 2'b0;
//      hdr.nfm.dw0.at    = 2'b0;
//      hdr.nfm.dw0.len   = 'd1;
//      // DW1
//    //hdr.nfm.dw1.req_id             //automatic: requester id
//    //hdr.nfm.dw1.tag                //automatic: tag
//      hdr.nfm.dw1.l_be   = 4'b0;
//      hdr.nfm.dw1.f_be   = be;
//      // DW2
//      hdr.nfm.dw2.dst_id = bdf;
//      hdr.nfm.dw2.RSVD1  = 4'b0;
//      hdr.nfm.dw2.regnum = (addr>>2);
//      hdr.nfm.dw2.RSVD2  = 2'b0;
//      /* 1 DW Payload */
//      payload = '{data};
//    end
//    // Flit mode
//    else begin
//      /* 3 DW Header */
//      // DW0
//    //hdr.fm.dw0.type_   = 8'b0100_010x; //automatic: Type0 or Type 1
//      hdr.fm.dw0.tc      = 3'b0;
//      hdr.fm.dw0.ohc     = 5'b0_0001;
//      hdr.fm.dw0.ts      = 3'b0;
//      hdr.fm.dw0.attr    = 3'b0;
//      hdr.fm.dw0.len     = 'd1;
//      // DW1
//    //hdr.fm.dw1.req_id          //automatic: requester id
//      hdr.fm.dw1.ep      = 1'b0;
//      hdr.fm.dw1.RSVD0   = 1'b0;
//    //hdr.fm.dw1.tag             //automatic: tag
//      // DW2
//      hdr.fm.dw2.dst_bdf = bdf;
//      hdr.fm.dw2.RSVD1   = 4'b0;
//      hdr.fm.dw2.regnum  = (addr>>2);
//      hdr.fm.dw2.RSVD2   = 2'b0;
//      // OHC-A3 (reqd.)
//    //ohc_a3.dst_seg       //automatic: dest. segment
//      ohc_a3.RSVD0 = 8'b0;
//    //ohc_a3.dsv           //automatic: dest. segment valid
//      ohc_a3.RSVD1 = 6'b0;
//      ohc_a3.l_be  = 4'b0;
//      ohc_a3.f_be  = be;
//      /* 1 DW Payload */
//      payload = '{data};
//    end
//  endfunction
//
//  virtual function void build_read(bit [15:0] bdf,     bit   [11:0] addr, 
//                                   bit [ 3:0] be = '1, logic [31:0] expected = 'x, bit [2:0] severity = UVM_ERROR);
//    // Reset summary
//    {match, sc, rd} = 3'b001;
//    payload.delete;
//    this.expected = expected;
//    mismatch_severity = severity;
//    // Non-flit mode
//    if (!fm) begin
//      /* 3 DW Header */
//      // DW0
//      hdr.nfm.dw0.fmt   = 3'b000;
//    //hdr.nfm.dw0.type_ = 5'b0_010x; //automatic: Type0 or Type1 
//    //hdr.nfm.dw0.t9    = 1'b0;      //automatic: tag
//      hdr.nfm.dw0.tc    = 3'b0;
//    //hdr.nfm.dw0.t8    = 1'b0;      //automatic: tag
//      hdr.nfm.dw0.a2    = 1'b0;
//      hdr.nfm.dw0.RSVD0 = 1'b0;
//      hdr.nfm.dw0.th    = 1'b0; 
//      hdr.nfm.dw0.td    = 1'b0;
//      hdr.nfm.dw0.ep    = 1'b0;
//      hdr.nfm.dw0.attr  = 2'b0;
//      hdr.nfm.dw0.at    = 2'b0;
//      hdr.nfm.dw0.len   = 'd1;
//      // DW1
//    //hdr.nfm.dw1.req_id             //automatic: requester id
//    //hdr.nfm.dw1.tag                //automatic: tag
//      hdr.nfm.dw1.l_be   = 4'b0;
//      hdr.nfm.dw1.f_be   = be;
//      // DW2
//      hdr.nfm.dw2.dst_id = bdf;
//      hdr.nfm.dw2.RSVD1  = 4'b0;
//      hdr.nfm.dw2.regnum = (addr>>2);
//      hdr.nfm.dw2.RSVD2  = 2'b0;
//    end
//    // Flit mode
//    else begin
//      /* 3 DW Header */
//      // DW0
//    //hdr.fm.dw0.type_   = 8'b0000_010x; //automatic: Type0 or Type 1
//      hdr.fm.dw0.tc      = 3'b0;
//      hdr.fm.dw0.ohc     = 5'b0_0001;
//      hdr.fm.dw0.ts      = 3'b0;
//      hdr.fm.dw0.attr    = 3'b0;
//      hdr.fm.dw0.len     = 'd1;
//      // DW1
//    //hdr.fm.dw1.req_id          //automatic: requester id
//      hdr.fm.dw1.ep      = 1'b0;
//      hdr.fm.dw1.RSVD0   = 1'b0;
//    //hdr.fm.dw1.tag             //automatic: tag
//      // DW2
//      hdr.fm.dw2.dst_bdf = bdf;
//      hdr.fm.dw2.RSVD1   = 4'b0;
//      hdr.fm.dw2.regnum  = (addr>>2);
//      hdr.fm.dw2.RSVD2   = 2'b0;
//      // OHC-A3 (reqd.)
//    //ohc_a3.dst_seg       //automatic: dest. segment
//      ohc_a3.RSVD0 = 8'b0;
//    //ohc_a3.dsv           //automatic: dest. segment valid
//      ohc_a3.RSVD1 = 6'b0;
//      ohc_a3.l_be  = 4'b0;
//      ohc_a3.f_be  = be;
//    end
//  endfunction

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
