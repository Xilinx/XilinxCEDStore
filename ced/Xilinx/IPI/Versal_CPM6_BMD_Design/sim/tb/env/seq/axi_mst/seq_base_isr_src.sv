typedef class cseq_base_isr_src; //forward typedef

class seq_base_isr_src extends seq_base_ps_axi32;

  `uvm_object_utils(seq_base_isr_src)

  event seq_done;
  event sub_seqs_done;
  bit   print_irqs = 1;

  // Status and Mask are captured here
  irq_s irqs[bit [7:0]];

  // child sequences can be added by tests
  seq_base_ps_axi32 c_seq[$];

  function new(string name = "seq_base_isr_src");
    super.new(name);
  endfunction

  virtual task body();
    // Get status and mask
    get_status_and_mask;
    // pre-action print
    pre_print;
    // Do some action
    do_action;
    // Do some post-action
    post_action;
    // post-action print
    post_print;
    // Trigger event
    ->seq_done;
    // Run sub-sequence(s)
    run_sub_seqs;
    // Trigger event
    ->sub_seqs_done;
  endtask

  virtual task get_status_and_mask;
    foreach (irqs[idx]) begin
      read_status(idx);
      read_mask(idx);
    end
  endtask

  virtual function void pre_print;
    if (print_irqs) 
      `uvm_info(get_type_name, {"Printing sequence IRQs:\n", sprint_irqs()}, UVM_LOW);
  endfunction

  // callbacks
  virtual task          do_action;   endtask
  virtual task          post_action; endtask
  virtual function void post_print;  endfunction

  virtual task run_sub_seqs;
    cseq_base_isr_src cseq;
    // Check if there are any child sequences and run them
    foreach (c_seq[ii]) begin
      // If this type, run based on knobs (reg_trigger+bit_trigger or always_run)
      if ($cast(cseq, c_seq[ii])) begin
        cseq.bit_triggered = irqs[cseq.reg_trigger].sts&cseq.bit_trigger;
        if (cseq.always_run || cseq.bit_triggered) begin
          cseq.parent = this;
          `uvm_info(get_type_name, $sformatf("Running child sequence %0s",cseq.get_type_name), UVM_LOW);
          cseq.start(m_sequencer);
        end
      end
    end
  endtask

  // Read an IRQ STATUS register
  //  - idx = 0-255
  virtual task read_status(bit [7:0] idx);
    /* Update latest time for initiated read */
    irqs[idx].latest = $time;
    // Send it
    axi_rd(irqs[idx].addr, irqs[idx].sts);
  endtask

  // Read an IRQ MASK register
  //  - idx = 0-255
  virtual task read_mask(bit [7:0] idx);
    // Send it
    axi_rd(irqs[idx].addr+4, irqs[idx].mask);
  endtask

  virtual function string sprint_irqs();
    string msg;
    msg = {msg, {70{"-"}}, "\n"};
    msg = {msg, $sformatf("%20s | %11s | %10s | %10s\n", 
                "NAME", "READ @ TIME", "STATUS", "MASK")};
    msg = {msg, {70{"-"}}, "\n"};
    foreach (irqs[idx]) begin
      if (!irqs[idx].latest) //never been read
        msg = {msg, $sformatf("%20s | %11s | 0x%0s | 0x%0s\n",
                    irqs[idx].name, "Unread", {8{"?"}}, {8{"?"}}) };
      else
        msg = {msg, $sformatf("%20s | %11d | 0x%h | 0x%h\n",
                    irqs[idx].name, irqs[idx].latest, irqs[idx].sts, irqs[idx].mask)};
    end
    msg = {msg, {70{"-"}} };
    return msg;
  endfunction

endclass
