class host_req_tr extends uvm_object;
`uvm_object_utils(host_req_tr)

  typedef enum {MRD, MWR} tlp_type;
  tlp_type dma_pkt_type;
  bit [63:0] addr;
  int unsigned length_dw;
  int unsigned data[]; // valid only for MWR; one element per DWord (32 bits)
  
  function new(string name="host_req_tr");
  super.new(name);
  endfunction
  
endclass