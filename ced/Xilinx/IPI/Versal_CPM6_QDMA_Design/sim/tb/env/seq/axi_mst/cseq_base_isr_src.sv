class cseq_base_isr_src extends seq_base_isr_src;

  `uvm_object_utils(cseq_base_isr_src)

  seq_base_isr_src parent;

  // A child sequence needs a trigger register and trigger bit(s)
  // of the parent sequence.  For example, MISC.24 could cause   
  // a specific child sequence to run. Alternatively, could put
  // the trigger condition in here as a method then the child
  // sequence could be set up however.
  bit [ 7:0] reg_trigger;   // register (of parent)
  bit [31:0] bit_trigger;   // bit position(s) (of parent)
  bit [31:0] bit_triggered; // bit position(s) (so object knows source(s))
  bit        always_run;

  function new(string name = "cseq_base_isr_src");
    super.new(name);
  endfunction

  virtual task register_isr(seq_base_isr_src parent_isr);
    if (p_sequencer == null) begin
      p_sequencer = parent_isr.p_sequencer;
    end
    axi_wr(parent_isr.irqs[this.reg_trigger].addr + 8, this.bit_trigger); // unmask
    this.parent = parent_isr;
    this.parent.c_seq.push_back(this);
  endtask
endclass
