class cseq_core_cxl_decoder_commit extends cseq_cpm6_pcie_core_isr_src;

  `uvm_object_utils(cseq_core_cxl_decoder_commit)

  protected string str;

  typedef enum bit [31:0] {
    // PCIE0_CFG Base = 'hFC00_0000
    CXL0_HDM_DEC_0_CNTRL_REG = 'hFC24_1220,
    CXL0_HDM_DEC_1_CNTRL_REG = 'hFC24_1240,
    CXL0_BI_DEC_CTRL         = 'hFC24_1254,
    // PCIE1_CFG Base = 'hFC40_0000
    CXL1_HDM_DEC_0_CNTRL_REG = 'hFC64_1220,
    CXL1_HDM_DEC_1_CNTRL_REG = 'hFC64_1240,
    CXL1_BI_DEC_CTRL         = 'hFC64_1254 
  } local_reg_e;

  protected bit [31:0] CXL_HDM_DEC_0_CTRL_REG; 
  protected bit [31:0] CXL_HDM_DEC_1_CTRL_REG; 
  protected bit [31:0] CXL_BI_DEC_CTRL;

  function new(string name = "cseq_core_cxl_decoder_commit");
    super.new(name);
    // we only care about IR_STATUS, so delete the other entries
    irqs.delete(PCIE_ERR_STATUS);
    irqs.delete(MISC_EVENT0_STATUS);
    irqs.delete(MISC_EVENT1_STATUS);
  endfunction

  virtual function void set_ctrlr(bit c);
    super.set_ctrlr(c);
    // reg_trigger can be from CPM6_SLCR.[MERGED_0,MERGED_1,MERGED_2]; parent obj must set
    bit_trigger = (1'b1 << (2+(c*3))); //CPM6_PCIE_CORE.IR_STATUS
    // set up print string
    str = c ? "PCIE_CORE1" : "PCIE_CORE0";
    // set up regs
    CXL_HDM_DEC_0_CTRL_REG = c ? CXL1_HDM_DEC_0_CNTRL_REG : CXL0_HDM_DEC_0_CNTRL_REG;
    CXL_HDM_DEC_1_CTRL_REG = c ? CXL1_HDM_DEC_1_CNTRL_REG : CXL0_HDM_DEC_1_CNTRL_REG;
    CXL_BI_DEC_CTRL        = c ? CXL1_BI_DEC_CTRL         : CXL0_BI_DEC_CTRL;       
  endfunction

  virtual task do_action();
    bit        clr_parent;
    // handle the initiated
    for (int ii=26; ii<29; ii++) begin
      if (!irqs[IR_STATUS].sts[ii]) continue;
      case (1'b1)
        // hdm_dec_commit_0
        ii==26 :
        begin
          `uvm_info(get_type_name, {str,"'s hdm_dec_commit_0 IRQ bit set"}, UVM_LOW)
          `uvm_info(get_type_name, {"Setting committed for ",str,"'s HDM Decoder 0"}, UVM_LOW)
          axi_rd_mod_wr(CXL_HDM_DEC_0_CTRL_REG, 'x | (1'b1<<10) );
          // Clear from upstream to downstream
          `uvm_info(get_type_name, "Clearing IR_STATUS[26] IRQ: hdm_dec_commit_0", UVM_LOW)
          axi_wr(irqs[IR_STATUS].addr, 1'b1<<ii);
          clr_parent = 1'b1;
        end
        // hdm_dec_commit_1
        ii==27 :
        begin
          `uvm_info(get_type_name, {str,"'s hdm_dec_commit_1 IRQ bit set"}, UVM_LOW)
          `uvm_info(get_type_name, {"Setting committed for ",str,"'s HDM Decoder 1"}, UVM_LOW)
          axi_rd_mod_wr(CXL_HDM_DEC_1_CTRL_REG, 'x | (1'b1<<10) );
          // Clear from upstream to downstream
          `uvm_info(get_type_name, "Clearing IR_STATUS[27] IRQ: hdm_dec_commit_1", UVM_LOW)
          axi_wr(irqs[IR_STATUS].addr, 1'b1<<ii);
          clr_parent = 1'b1;
        end
        // bi_dec_commit
        ii==28 :
        begin
          `uvm_info(get_type_name, {str,"'s bi_dec_commit IRQ bit set"}, UVM_LOW)
          `uvm_info(get_type_name, {"Setting committed for ",str,"'s BI Decoder"}, UVM_LOW)
          axi_rd_mod_wr(CXL_BI_DEC_CTRL, 'x | (1'b1<< 2) );
          // Clear from upstream to downstream
          `uvm_info(get_type_name, "Clearing IR_STATUS[28] IRQ: bi_dec_commit", UVM_LOW)
          axi_wr(irqs[IR_STATUS].addr, 1'b1<<ii);
          clr_parent = 1'b1;
        end
      endcase
    end
    // Clear parent 
    if (clr_parent)
      clear_parent_irq;
  endtask

  virtual task clear_parent_irq;
    print_clr_irq(parent.irqs[reg_trigger].name, 2+(3*ctrlr));
    axi_wr(parent.irqs[reg_trigger].addr, bit_trigger);
    case (reg_trigger) 
      MERGED_0 : 
      begin 
        if (parent.irqs[CORR].sts[21]) begin
          print_clr_irq(parent.irqs[CORR].name, 21);
          axi_wr       (parent.irqs[CORR].addr, 1'b1<<21);
        end
        if (parent.irqs[UNCORR].sts[21]) begin
          print_clr_irq(parent.irqs[UNCORR].name, 21);
          axi_wr       (parent.irqs[UNCORR].addr, 1'b1<<21);
        end
        if (parent.irqs[MISC].sts[21]) begin
          print_clr_irq(parent.irqs[MISC].name, 21);
          axi_wr       (parent.irqs[MISC].addr, 1'b1<<21);
        end
      end
      MERGED_1 : 
      begin 
        if (parent.irqs[CORR].sts[22]) begin
          print_clr_irq(parent.irqs[CORR].name, 22);
          axi_wr       (parent.irqs[CORR].addr, 1'b1<<22);
        end
        if (parent.irqs[UNCORR].sts[22]) begin
          print_clr_irq(parent.irqs[UNCORR].name, 22);
          axi_wr       (parent.irqs[UNCORR].addr, 1'b1<<22);
        end
        if (parent.irqs[MISC].sts[22]) begin
          print_clr_irq(parent.irqs[MISC].name, 22);
          axi_wr       (parent.irqs[MISC].addr, 1'b1<<22);
        end
      end
      MERGED_2 : 
      begin 
        if (parent.irqs[CORR].sts[23]) begin
          print_clr_irq(parent.irqs[CORR].name, 23);
          axi_wr       (parent.irqs[CORR].addr, 1'b1<<23);
        end
        if (parent.irqs[UNCORR].sts[23]) begin
          print_clr_irq(parent.irqs[UNCORR].name, 23);
          axi_wr       (parent.irqs[UNCORR].addr, 1'b1<<23);
        end
        if (parent.irqs[MISC].sts[23]) begin
          print_clr_irq(parent.irqs[MISC].name, 23);
          axi_wr       (parent.irqs[MISC].addr, 1'b1<<23);
        end
      end
    endcase
  endtask

  virtual function void print_clr_irq(string name, int b);
    `uvm_info(get_type_name, $sformatf("Clearing %0s[%0d] IRQ",name,b), UVM_LOW)
  endfunction

endclass
