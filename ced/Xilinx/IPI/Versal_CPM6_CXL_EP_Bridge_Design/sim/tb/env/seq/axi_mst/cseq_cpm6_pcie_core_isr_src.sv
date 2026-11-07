class cseq_cpm6_pcie_core_isr_src extends cseq_base_isr_src;

  `uvm_object_utils(cseq_cpm6_pcie_core_isr_src)

  protected logic ctrlr; //must be set through method

  // CPM6_PCIE_CORE0, CPM6_PCIE_CORE1 registers
  typedef enum bit [2:0] {
    IR_STATUS, 
    PCIE_ERR_STATUS, 
    MISC_EVENT0_STATUS, 
    MISC_EVENT1_STATUS
  } core_regs_e;

  function new(string name = "cseq_cpm6_pcie_core_isr_src");
    super.new(name);
  endfunction

  virtual task pre_body();
    if (ctrlr===1'bx)
      `uvm_fatal(get_type_name, "Must call method 'set_ctrlr(<n>)' before sequence is ran")
  endtask

  // CPM6_PCIE_CORE0 Base = 'hFC84_0000
  // CPM6_PCIE_CORE1 Base = 'hFC94_0000
  virtual function void set_ctrlr(bit c);
    ctrlr = c;
    // 'reg_trigger' can be from CPM6_SLCR.[MERGED_0,MERGED_1,MERGED_2]; parent obj must set
    bit_trigger = (1'b1 << (15+(c*3))) | //CPM6_PCIE_CORE.MISC_EVENT1_STATUS
                  (1'b1 << (14+(c*3))) | //CPM6_PCIE_CORE.MISC_EVENT0_STATUS
                  (1'b1 << (13+(c*3))) | //CPM6_PCIE_CORE.PCIE_ERR_STATUS
                  (1'b1 << ( 2+(c*3)));  //CPM6_PCIE_CORE.IR_STATUS
    // build the array
    irqs[IR_STATUS]          = '{"IR_STATUS",          32'hFC84_000C+(c*'h10_0000), 1'b1, 64'h0, 32'h0, 32'h0};
    irqs[PCIE_ERR_STATUS]    = '{"PCIE_ERR_STATUS",    32'hFC84_0500+(c*'h10_0000), 1'b1, 64'h0, 32'h0, 32'h0};
    irqs[MISC_EVENT0_STATUS] = '{"MISC_EVENT0_STATUS", 32'hFC84_0514+(c*'h10_0000), 1'b1, 64'h0, 32'h0, 32'h0};
    irqs[MISC_EVENT1_STATUS] = '{"MISC_EVENT1_STATUS", 32'hFC84_0528+(c*'h10_0000), 1'b1, 64'h0, 32'h0, 32'h0};
  endfunction

  virtual task register_isr(seq_base_isr_src parent_isr);
    if (p_sequencer == null) begin
      p_sequencer = parent_isr.p_sequencer;
    end
    axi_wr('hFCDD0000, 'h0); //Disable WPROTS on CPM6_SLCR for IRQ setup
    super.register_isr(parent_isr);
    axi_wr('hFCDD0000, 'h1); //Enable WPROTS on CPM6_SLCR for IRQ setup
  endtask

endclass
