// DESCRIPTION
// This sequence is designed to read the entire Configuration Space 
// Header, DWORD by DWORD. The results are in each txn's payload
// in the txn queue i.e. q[0].payload[0].
class seq_cfg_spc_header extends vseq_in_order;

  `uvm_object_utils(seq_cfg_spc_header)

  // Knobs to set before calling 'start'
  logic [15:0] dst_bdf;

  function new(string name = "seq_cfg_spc_header");
    super.new(name);
  endfunction

  // Fill the queue
  virtual task pre_body(); 
    amd_cfg_tlp tlp;
    if (dst_bdf==='x)
      `uvm_fatal(get_type_name, "dst_bdf member must be set before running sequence")
    for (bit [11:0] addr=0; addr<'h40; addr+=4) begin
      tlp = amd_cfg_tlp::type_id::create("tlp");
      tlp.build_rd(addr, .bdf(dst_bdf));
      add_txn(tlp);
    end
  endtask

endclass
