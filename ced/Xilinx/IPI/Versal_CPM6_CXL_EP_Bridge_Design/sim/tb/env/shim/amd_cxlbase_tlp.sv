// A CXL TLP is a generic transaction that defines a specific 
// type of transaction, where extended objects will define a
// message class within CXL.mem or CXL.cache, and may contain
// data and trailers (if present).

class amd_cxlbase_tlp extends uvm_object;

  `uvm_object_utils(amd_cxlbase_tlp)

  function new(string name = "amd_cxlbase_tlp");
    super.new(name);
  endfunction

  // ----------------------------------- //
  // CONTROL 
  // ----------------------------------- //
  coh_e coh = USE_AGENT;

  // ----------------------------------- //
  // SUMMARY 
  // ----------------------------------- //
  cpl_sts_e        cpl_sts     = NO_CPL;
  bit signed [2:0] cpl_sts_sev = UVM_FATAL; 

  virtual function bit got_SC(); return (cpl_sts==CPL_SC); endfunction

  // ----------------------------------- //
  // MEMBERS
  // ----------------------------------- //

  bit [15:0][31:0] data[$:256]; //max: 16kB
  bit [63:0]       be  [$:256];

endclass
