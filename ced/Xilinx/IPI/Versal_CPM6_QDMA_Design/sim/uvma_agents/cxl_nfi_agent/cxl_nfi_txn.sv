// The AMD CXL interface to the PL is a set of N 64B chunks, where N=[1:3]. 
// A CXL link that has trained to 68B flit mode will issue multiple flits on 
// this interface, while a 256B flit mode link will issue flit-chunks. The 
// generic term used for each chunk is also known as a slot-set.
//
// The agent driver uses this transaction type because it connects directly
// to the DUT, while pretty much everything else internal to the agent is
// built upon a flit txn (either 68B or 256B).
class cxl_nfi_txn#(parameter NFI_W=3) extends base_txn;

  `uvm_object_param_utils(cxl_nfi_txn#(NFI_W))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("cxl_nfi_txn#(%0d)",NFI_W);
  virtual function string get_type_name(); return type_name; endfunction

  // Fields of the if
  logic [NFI_W-1:0][511:0] data;
  logic [NFI_W-1:0][  7:0] parity;
  logic [NFI_W-1:0]        viral;
  logic [NFI_W-1:0]        valid;
  logic [NFI_W-1:0]        ready;
  logic [NFI_W-1:0]        adf;
  logic [NFI_W-1:0]        last;
  logic [NFI_W-1:0][  3:0] dec_sop;
  logic [NFI_W-1:0][  3:0] dec_eop;
  logic [NFI_W-1:0][  3:0] dec_be;
  logic [NFI_W-1:0][  3:0] dec_mem;

  // Sideband
  int req_consumed[NFI_W-1:0][1:0]; 
  int dat_consumed[NFI_W-1:0][1:0]; 
  int rsp_consumed[NFI_W-1:0][1:0]; 

  function new(string name = "cxl_nfi_txn");
    super.new(name);
    txn_type = "CXL_NFI_TXN";
  endfunction

endclass
