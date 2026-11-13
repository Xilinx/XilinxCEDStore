// This sequence sends the same transaction one or more times.
// To perform one outstanding transaction at a time, set block_each.
// To complete the sequence when the final transaction is done, set
// block_last.
class vseq_loop extends vseq_base;

  `uvm_object_utils(vseq_loop)

  amd_base_tlp tlp;

  int unsigned loop_cnt;
  bit          block_each;
  bit          block_last = 1;

  function new(string name = "vseq_loop");
    super.new(name);
  endfunction

  // For convenience, set blocking if a Mem TLP
  virtual task pre_body;
    amd_mem_tlp mtlp;
    if (!loop_cnt)
      `uvm_error(get_type_name, "loop_cnt should not be 0")
    if ($cast(mtlp, tlp)) begin
      mtlp.blocking = block_each;
      tlp = mtlp;
    end
  endtask

  virtual task body;
    amd_mem_tlp mtlp;
    while (loop_cnt--) begin
      if (!loop_cnt && $cast(mtlp, tlp)) begin
        mtlp.blocking = block_last;
        tlp = mtlp;
      end
      p_sequencer.api.send_txn(tlp);
    end
  endtask

endclass
