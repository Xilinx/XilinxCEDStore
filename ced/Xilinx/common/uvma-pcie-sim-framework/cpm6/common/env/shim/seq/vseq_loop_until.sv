// This sequence assumes that the user wants the same read to be performed 
// until some data matches the first DW of the response. Building the 
// transaction is left to the parent object.
class vseq_loop_until extends vseq_base;

  `uvm_object_utils(vseq_loop_until)

  logic [31:0] match;

  amd_base_tlp tlp;

  int          loop_cnt = -1; //-1=loop forever, else exit when 0

  function new(string name = "vseq_loop_until");
    super.new(name);
  endfunction

  // For convenience, set blocking if a Mem TLP
  virtual task pre_body;
    string      msg;
    amd_cfg_tlp ctlp;
    amd_mem_tlp mtlp;
    msg = "Sequence assumes user wants to perform a repeated read";
    case (1'b1)
      $cast(ctlp, tlp) : if (!ctlp.rd) `uvm_fatal(get_type_name, msg)
      $cast(mtlp, tlp) : begin
                           if (!mtlp.rd) `uvm_fatal(get_type_name, msg)
                           // Cover the user's base if they forgot to set this
                           mtlp.blocking = 1;
                           tlp = mtlp;
                         end
    endcase
    if (match==='x) 
      `uvm_warning(get_type_name, "Data to match is all don't care")
  endtask

  virtual task body;
    bit got_match;
    do begin
      p_sequencer.api.send_txn(tlp);
      got_match = is_match(tlp.data[0]);
      // Decrement if not looping indefinitely
      if (loop_cnt>0) loop_cnt--;
    end while (!got_match && loop_cnt!=0);
    // Notify if exit condition hit
    if (!got_match)
      `uvm_error(get_type_name, "Hit loop iteration exit condition")
  endtask

  // An x in 'match' is treated as a don't care, else do a bitwise compare
  virtual function bit is_match(bit [31:0] data);
    is_match = 1;
    foreach (match[ii])
      if (match[ii]!=='x && match[ii]!=data[ii])
        return 0;
  endfunction

endclass
