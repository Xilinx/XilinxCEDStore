// This class is used only for Mem Space Read Requests and Write Requests for
// either non-flit mode or flit mode. Iff it is a Read Request, data returned
// will be in the payload field and iff expected was given, there will be a
// comparison to the payload and the match field will be set. The previous 
// sentence is true iff you use the accompanying API methods. There are two
// ways to use this object: the basic and raw mode. Most users will want to 
// use the basic mode, which simply requires addr/lenth/data/be to issue one
// or more transactions. If more control is required, then the raw mode will need to
// be used.

class amd_mem_tlp extends amd_base_tlp;

  `uvm_object_utils(amd_mem_tlp)

  function new(string name = "amd_mem_tlp");
    super.new(name);
  endfunction

  typedef int unsigned uint;

  // -------------------------------------
  // SUMMARY DATA
  // -------------------------------------
  logic  [0:3][7:0] expected_q[$];  //for read request, ordered data to match
  bit               match;          //for read request, match result
  uint              mismatch_cnt;   //number of DWs that mismatch
  uint              mismatch_first; //first DW that mismatches
  bit signed [ 2:0] mismatch_sev;   //neg=no print, pos=uvm_severity

  // -------------------------------------
  // BASIC IMPLEMENTATION
  //  . Assign by calling 'build_[wr,rd]'
  // -------------------------------------
  protected bit          basic = 1;
            bit          rd;
            uint         length; //in DW
            bit   [63:0] addr;
            bit   [ 3:0] f_be;
            bit   [ 3:0] l_be;
            bit   [ 1:0] blocking; //NP: get completion(s), P:LL ACKs

  // -------------------------------------
  // RAW IMPLEMENTATION
  // -------------------------------------
  //  . HEADER: 3 or 4 DW (union is 4)
  // -------------------------------------
  mem_hdr_u      hdr;
  // -------------------------------------
  // FLIT MODE ONLY
  // . Required Conditions
  //   1. Memory Requests with BEs and/or PASID
  //   2. Address routed Messages and Route to 
  //      Root Complex Messages with PASID
  //   3. Translation Requests
  // -------------------------------------
  ohc_a1_s       ohc_a1;
  // -------------------------------------
  // PAYLOAD : VARIABLE SIZE
  // . Uses base class's member 'data' up 
  //   to 1024 DW
  // . Little endian!
  // -------------------------------------

  // -------------------------------------
  // METHODS
  // -------------------------------------
  virtual function void build_rd(bit   [63:0] addr,
                                 uint         length,
                                 bit   [ 3:0] f_be     = '1,
                                 bit   [ 3:0] l_be     = '1,
                                 bit   [ 1:0] blocking = NONBLOCK);
    // Reset prev. txn
    {cpl_sts, match} = {NO_CPL, 1'bx};
    this.data.delete;
    // Constant
    rd    = 1;
    basic = 1; 
    // Args
    this.addr     = addr;
    this.length   = length;
    this.f_be     = f_be;
    this.l_be     = l_be;
    this.blocking = blocking;
  endfunction

  // if data given -> length set to match
  // else length given -> data randomized
  virtual function void build_wr(bit   [63:0] addr,
                                 uint         length       = 0,
                                 bit   [31:0] data[]       = {},
                                 bit   [ 3:0] f_be         = '1,
                                 bit   [ 3:0] l_be         = '1,
                                 bit   [ 1:0] blocking     = NONBLOCK,
                                 string       default_data = "RANDOM");
    // Fatal error
    if (!length && !data.size)
      `uvm_fatal(get_type_name, "Can't have length=0 and no data")
    // Reset prev. txn
    {cpl_sts, match} = {NO_CPL, 1'bx};
    this.data.delete;
    // Constant
    rd    = 0;
    basic = 1; 
    // Args
    this.addr     = addr;
    this.f_be     = f_be;
    this.l_be     = l_be;
    this.blocking = blocking;
    if (data.size) begin
      this.data   = data;
      this.length = data.size;
    end
    else begin
      this.length = length;
      case (default_data)
        "RANDOM" : void'(std::randomize(this.data) with {
                         this.data.size==length;
                   });
        "ZEROES" : repeat (length) this.data.push_back('0); 
        "ONES"   : repeat (length) this.data.push_back('1); 
        default  : `uvm_fatal(get_type_name, "Unsupported value for 'default_data'")
      endcase
    end
  endfunction

  virtual function bit expected_match;
    return 1'b1;
  endfunction

  virtual function bit is_basic(); return basic; endfunction

endclass
