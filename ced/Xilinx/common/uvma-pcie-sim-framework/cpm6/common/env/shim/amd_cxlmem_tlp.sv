class amd_cxlmem_tlp extends amd_cxlbase_tlp;

  `uvm_object_utils(amd_cxlmem_tlp)

  function new(string name = "amd_cxlmem_tlp");
    super.new(name);
  endfunction

  typedef int unsigned uint;

  // -------------------------------------
  // SUMMARY DATA
  // -------------------------------------
  logic  [15:0][31:0] expected_q[$:256]; //for read request, ordered data to match
  bit                match;              //for read request, match result
  uint               mismatch_cnt;       //number of cachelines that mismatch
  uint               mismatch_first;     //first cacheline that mismatches
  bit  signed [ 2:0] mismatch_sev;       //neg=no print, pos=uvm_severity

  // -------------------------------------
  // BASIC IMPLEMENTATION
  //  . Assign by calling 'build_[wr,rd]'
  // -------------------------------------
  protected bit         basic = 1;
            bit         rd;
            uint        length; //in cachelines
            bit  [51:0] addr;
            bit  [ 1:0] blocking; 

  // -------------------------------------
  // RAW IMPLEMENTATION
  //  . To be added later
  // -------------------------------------

  // -------------------------------------
  // METHODS
  // -------------------------------------
  virtual function void build_rd(bit  [51:0] addr,
                                 uint        length   = 1,
                                 coh_e       coh      = USE_AGENT,
                                 bit  [ 1:0] blocking = NONBLOCK);
    // Reset prev. txn
    {cpl_sts, match} = {NO_CPL, 1'bx};
    this.data.delete;
    // Constant
    rd    = 1;
    basic = 1;
    // Args
    this.addr     = addr;
    this.length   = length;
    this.coh      = coh;
    this.blocking = blocking;
  endfunction

  // if data given -> length set to match
  // else length given -> data randomized
  virtual function void build_wr(bit  [ 51:0] addr,
                                 bit  [511:0] data[]       = {},
                                 bit  [ 63:0] be[]         = {},
                                 uint         length       = 1,
                                 coh_e        coh          = USE_AGENT,
                                 bit  [  1:0] blocking     = NONBLOCK,
                                 string       default_data = "RANDOM",
                                 string       default_be   = "ONES");
    uint be_size;
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
    this.coh      = coh;
    this.blocking = blocking;
    if (data.size) begin
      this.data   = data;
      this.length = data.size;
      // if be size == data size -> pass directly
      // else if be size < data size -> extend be to match data size with '1
      // else if be size > data size -> flag warning and truncate be size
      case (1'b1)
        be.size==data.size : this.be = be;
        be.size<=data.size : 
        begin 
          be_size = be.size;
          be = new[data.size](be);
          for (int ii=be_size; ii<data.size; ii++) be[ii] = '1;
          this.be = be;
        end
        be.size>=data.size : 
        begin
          `uvm_warning(get_type_name, "Array be[] bigger than data[]; truncating BE")
          be = new[data.size](be);
          this.be = be;
        end
      endcase
    end
    else begin
      this.length = length;
      case (default_data)
        "RANDOM" : void'(std::randomize(this.data) with { this.data.size==length; });
        "ZEROES" : repeat (length) this.data.push_back('0);
        "ONES"   : repeat (length) this.data.push_back('1);
        default  : `uvm_fatal(get_type_name, "Unsupported value for 'default_data'")
      endcase
      case (default_be)
        "ONES"   : repeat (length) this.be.push_back('1);
        "RANDOM" : void'(std::randomize(this.be) with { this.be.size==length; });
        "RANDOM_NOZERO" : void'(std::randomize(this.be) with 
                                  { this.be.size==length; 
                                    foreach (this.be[ii]) this.be[ii]!='0; });
        default  : `uvm_fatal(get_type_name, "Unsupported value for 'default_be'")
      endcase
    end
  endfunction

  virtual function bit expected_match;
    return 1'b1;
  endfunction

  virtual function bit is_basic(); return basic; endfunction

endclass
