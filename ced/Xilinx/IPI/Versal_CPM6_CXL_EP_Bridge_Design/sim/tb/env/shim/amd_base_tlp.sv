// A PCIe TLP is a serialized set of bytes from 0-N consisting of:
//  a) (Opt.) TLP Prefix(es) (1 DW/prefix)
//  b) TLP Header (3 or 4 DW + (FM only) 0-7 DW of OHC)
//  c) Data Payload (1-1024 DW; when applicable)
//  d) (Opt.) TLP Digest (4 DW)  
class amd_base_tlp extends uvm_object;

  `uvm_object_utils(amd_base_tlp)

  function new(string name = "amd_base_tlp");
    super.new(name);
  endfunction

  // ----------------------------------- //
  // CONTROL 
  // ----------------------------------- //
  bit fm; //flit-mode

  // ----------------------------------- //
  // SUMMARY 
  // ----------------------------------- //
  cpl_sts_e        cpl_sts = NO_CPL;
  bit signed [2:0] cpl_sts_sev = UVM_FATAL; 

  virtual function bit got_SC(); return (cpl_sts==CPL_SC); endfunction

  // ----------------------------------- //
  // RAW TLPS
  // ----------------------------------- //

  bit [0:3][7:0] prefix[$:4];
  bit [0:3][7:0] header[$:11]; 
  bit [3:0][7:0] data  [$:1024]; //HW designer ordering
  bit [0:3][7:0] digest[$:1];
 
  // ----------------------------------- //
  // IDE     
  // ----------------------------------- //

  logic [7:0]    ide_stream_id;
  
endclass
