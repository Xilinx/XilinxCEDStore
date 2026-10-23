class seq_ps_isr_src extends seq_base_isr_src;

  `uvm_object_utils(seq_ps_isr_src)

  // Determine what to read
  bit [2:0] irq; //{corr, uncorr, misc}

  function new(string name = "seq_ps_isr_src");
    super.new(name);
    // Build the array 
    irqs[MISC]     = '{"PS_MISC",   32'hFCDD_0340, 1'b1, 64'h0, 32'h0, 32'h0};
    irqs[UNCORR]   = '{"PS_UNCORR", 32'hFCDD_0320, 1'b1, 64'h0, 32'h0, 32'h0};
    irqs[CORR]     = '{"PS_CORR",   32'hFCDD_0300, 1'b1, 64'h0, 32'h0, 32'h0};
    irqs[MERGED_0] = '{"MERGED_0",  32'hFCDD_0648, 1'b0, 64'h0, 32'h0, 32'h0};
    irqs[MERGED_1] = '{"MERGED_1",  32'hFCDD_065C, 1'b0, 64'h0, 32'h0, 32'h0};
    irqs[MERGED_2] = '{"MERGED_2",  32'hFCDD_0670, 1'b0, 64'h0, 32'h0, 32'h0};
  endfunction

  virtual task get_status_and_mask;
    // should always read merged registers if they WERE last asserted
    // else, by default, don't read them
    irqs[MERGED_0].enable = |irqs[MERGED_0].sts;
    irqs[MERGED_1].enable = |irqs[MERGED_1].sts;
    irqs[MERGED_2].enable = |irqs[MERGED_2].sts;
    // Create and set up transactions
    foreach (irqs[idx]) begin
      if ((idx<=CORR     && irq[idx]) ||       //if DUT signal is high
          (idx>=MERGED_0 && irqs[idx].enable)) //if any merge IRQ is OR was asserted
      begin 
        read_status(idx);
        // selectively read merged registers if irq asserted
        if (idx<=CORR) begin
          irqs[MERGED_0].enable |= irqs[idx].sts[21]; 
          irqs[MERGED_1].enable |= irqs[idx].sts[22]; 
          irqs[MERGED_2].enable |= irqs[idx].sts[23]; 
        end
        read_mask(idx);
      end
    end
  endtask

endclass
