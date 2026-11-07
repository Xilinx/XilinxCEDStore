class cseq_cpm6_pcie_core_mbox extends cseq_base_isr_src;

  `uvm_object_utils(cseq_cpm6_pcie_core_mbox)

  protected logic ctrlr; //must be set through method

  typedef enum bit {CFG, MMIO} src_e;
  typedef      bit [ 2:0]      pf_t;
  typedef      bit [ 2:0]      bar_t;
  typedef      bit [31:0]      addr_t; 
  typedef      bit [31:0]      data_t; 

  bit   pretty_print = 1'b1; // print txn raw or formatted

  typedef enum bit [31:0] {
    // CPM6_PCIE_CORE0 Base = 'hFC84_0000
    C0_IR_STATUS            = 'hFC84_000C,
    C0_ELBI_MBOX_CTRL       = 'hFC84_0400,
    C0_ELBI_MBOX_ADDR       = 'hFC84_0404,
    C0_ELBI_MBOX_WRDATA_DW0 = 'hFC84_0408,
    C0_ELBI_MBOX_WRDATA_DW1 = 'hFC84_040C,
    C0_ELBI_MBOX_RDDATA_DW0 = 'hFC84_0410,
    C0_ELBI_MBOX_RDDATA_DW1 = 'hFC84_0414,
    C0_ELBI_MBOX_STATUS     = 'hFC84_041C,
    // CPM6_PCIE_CORE1 Base = 'hFC94_0000
    C1_IR_STATUS            = 'hFC94_000C,
    C1_ELBI_MBOX_CTRL       = 'hFC94_0400,
    C1_ELBI_MBOX_ADDR       = 'hFC94_0404,
    C1_ELBI_MBOX_WRDATA_DW0 = 'hFC94_0408,
    C1_ELBI_MBOX_WRDATA_DW1 = 'hFC94_040C,
    C1_ELBI_MBOX_RDDATA_DW0 = 'hFC94_0410,
    C1_ELBI_MBOX_RDDATA_DW1 = 'hFC94_0414,
    C1_ELBI_MBOX_STATUS     = 'hFC94_041C
  } local_reg_e;

  protected bit [31:0] IR_STATUS;
  protected bit [31:0] ELBI_MBOX_CTRL;
  protected bit [31:0] ELBI_MBOX_ADDR;
  protected bit [31:0] ELBI_MBOX_WRDATA_DW0;
  protected bit [31:0] ELBI_MBOX_WRDATA_DW1;
  protected bit [31:0] ELBI_MBOX_RDDATA_DW0;
  protected bit [31:0] ELBI_MBOX_RDDATA_DW1;
  protected bit [31:0] ELBI_MBOX_STATUS;   

  struct packed {
    bit      [ 2:0] pf;
    bit      [ 7:0] vf;
    bit             is_vf;
    bit      [ 2:0] bar; 
    addr_t          addr;
    addr_t          masked_addr;
    bit      [ 1:0] len;
    bit             mmio;
    bit             rd;
    bit             erom;
    bit      [ 7:0] wr_be; 
    data_t          data_1; 
    data_t          data_0; 
    // sideband
    bit             u_txfer; //"upper txfer'
  } txn;

  typedef struct {
    bit    on  =  1;
    addr_t cmp = 32'hFFFF_FFFF;
  } mask_s;

  // mailbox
  // - [src_e][pf_t][bar_t]
  data_t mbox[0:1][0:7][0:5][addr_t];
  // mask (per bit; 1=compare, 0=no compare)
  // - [src_e][pf_t][bar_t]
  mask_s mask[0:1][0:7][0:5];

  function new(string name = "cseq_cpm6_pcie_core_mbox");
    super.new(name);
  endfunction

  virtual task pre_body();
    if (ctrlr===1'bx)
      `uvm_fatal(get_type_name, "Must call method 'set_ctrlr(<n>)' before sequence is ran")
  endtask

  virtual function void set_ctrlr(bit c);
    ctrlr = c;
    // set up registers
    IR_STATUS            = c ? C1_IR_STATUS            : C0_IR_STATUS;
    ELBI_MBOX_CTRL       = c ? C1_ELBI_MBOX_CTRL       : C0_ELBI_MBOX_CTRL;
    ELBI_MBOX_ADDR       = c ? C1_ELBI_MBOX_ADDR       : C0_ELBI_MBOX_ADDR;      
    ELBI_MBOX_WRDATA_DW0 = c ? C1_ELBI_MBOX_WRDATA_DW0 : C0_ELBI_MBOX_WRDATA_DW0;
    ELBI_MBOX_WRDATA_DW1 = c ? C1_ELBI_MBOX_WRDATA_DW1 : C0_ELBI_MBOX_WRDATA_DW1;
    ELBI_MBOX_RDDATA_DW0 = c ? C1_ELBI_MBOX_RDDATA_DW0 : C0_ELBI_MBOX_RDDATA_DW0;
    ELBI_MBOX_RDDATA_DW1 = c ? C1_ELBI_MBOX_RDDATA_DW1 : C0_ELBI_MBOX_RDDATA_DW1;
    ELBI_MBOX_STATUS     = c ? C1_ELBI_MBOX_STATUS     : C0_ELBI_MBOX_STATUS;
    
  endfunction

  // 'reg_trigger' can be from CORR, UNCORR, or MISC; parent must set
  virtual function void set_trigger_mmio_cfg(bit [7:0] rtrig);
    if (ctrlr===1'bx)
      `uvm_fatal(get_type_name, "Must call method 'set_ctrlr(<n>)' before this method is called")
    reg_trigger = rtrig;
    bit_trigger = (1'b1 << (4+(6*ctrlr))) | //mbox_mmiowr_int_pcie0,1
                  (1'b1 << (3+(6*ctrlr))) | //mbox_mmiord_int_pcie0,1
                  (1'b1 << (2+(6*ctrlr))) | //mbox_cfgwr_int_pcie0,1
                  (1'b1 << (1+(6*ctrlr)));  //mbox_cfgrd_int_pcie0,1
  endfunction

  // 'reg_trigger' can be from CORR, UNCORR, or MISC; parent must set
  virtual function void set_trigger_mmio(bit [7:0] rtrig);
    if (ctrlr===1'bx)
      `uvm_fatal(get_type_name, "Must call method 'set_ctrlr(<n>)' before this method is called")
    reg_trigger = rtrig;
    bit_trigger = (1'b1 << (4+(6*ctrlr))) | //mbox_mmiowr_int_pcie0,1
                  (1'b1 << (3+(6*ctrlr)));  //mbox_mmiord_int_pcie0,1
  endfunction

  // 'reg_trigger' can be from CORR, UNCORR, or MISC; parent must set
  virtual function void set_trigger_cfg(bit [7:0] rtrig);
    if (ctrlr===1'bx)
      `uvm_fatal(get_type_name, "Must call method 'set_ctrlr(<n>)' before this method is called")
    reg_trigger = rtrig;
    bit_trigger = (1'b1 << (2+(6*ctrlr))) | //mbox_cfgwr_int_pcie0,1
                  (1'b1 << (1+(6*ctrlr)));  //mbox_cfgrd_int_pcie0,1
  endfunction

  // Load DWs sequentially into Cfg Mailbox
  // - If mask is provided, this will set the mask as well
  virtual function void load_cfg_mbox(
    pf_t pf, bar_t bar, addr_t addr, data_t data[], logic [31:0] mask = 'x
  ); 
    foreach (data[ii]) begin
      this.mbox[CFG][pf][bar][addr] = data[ii];
      addr+=4;
    end
    if (mask!=='x)
      this.mask[CFG][pf][bar] = '{1'b1, mask};
  endfunction

  // Set the mask for the CFG mailbox for a pf and bar
  virtual function void set_cfg_mask(pf_t pf, bar_t bar, addr_t mask, bit on = 1);
    this.mask[CFG][pf][bar] = '{on, mask};
  endfunction

  // Disable the mask for the CFG mailbox for a pf and bar
  virtual function void disable_cfg_mask(pf_t pf, bar_t bar);
    this.mask[CFG][pf][bar].on = 1'b0;
  endfunction

  // Enable the mask for the CFG mailbox for a pf and bar
  virtual function void enable_cfg_mask(pf_t pf, bar_t bar);
    this.mask[CFG][pf][bar].on = 1'b1;
  endfunction

  // Load DWs sequentially into MMIO Mailbox
  // - If mask is provided, this will set the mask as well
  virtual function void load_mmio_mbox(
    pf_t pf, bar_t bar, addr_t addr, data_t data[], logic [31:0] mask = 'x
  );
    foreach (data[ii]) begin
      this.mbox[MMIO][pf][bar][addr] = data[ii];
      addr+=4;
    end
    if (mask!=='x)
      this.mask[MMIO][pf][bar] = '{1'b1, mask};
  endfunction

  // Set the mask for the MMIO mailbox for a pf and bar
  virtual function void set_mmio_mask(pf_t pf, bar_t bar, addr_t mask, bit on = 1);
    this.mask[MMIO][pf][bar] = '{on, mask};
  endfunction

  // Disable the mask for the MMIO mailbox for a pf and bar
  virtual function void disable_mmio_mask(pf_t pf, bar_t bar);
    this.mask[MMIO][pf][bar].on = 1'b0;
  endfunction

  // Enable the mask for the MMIO mailbox for a pf and bar
  virtual function void enable_mmio_mask(pf_t pf, bar_t bar);
    this.mask[MMIO][pf][bar].on = 1'b1;
  endfunction

  virtual task do_action;
    string       msg;
    bit   [ 1:0] found;
    logic [31:0] rdat;
    // First, clear the IRQ
    clear_irqs; 
    // Reg: Control
    axi_rd(ELBI_MBOX_CTRL, rdat);
    txn.len   = rdat[28]+1;
    txn.erom  = rdat[27];
    txn.bar   = rdat[26:24];
    txn.wr_be = rdat[23:16];
    txn.is_vf = rdat[15];
    txn.vf    = rdat[14:7];
    txn.pf    = rdat[ 6:4];
    txn.mmio  = |rdat[3:2]; 
    txn.rd    = txn.mmio ? rdat[2] : rdat[0];
    // Reg: Address
    axi_rd(ELBI_MBOX_ADDR, txn.addr);
    // Check if doing an unaligned 2 DW transfer, which CPM6 does not support 
    txn.u_txfer = (txn.addr[2:0]==3'b100);
    if (txn.u_txfer && txn.len==2) begin
      msg = $sformatf("txn.addr=0x%h, txn.len=%0d", txn.addr, txn.len); 
      `uvm_fatal(get_type_name, {"ELBI Mailbox Txn cannot support unaligned 2 DW transfer: ",msg})
    end
    // Mask turned on
    if (mask[txn.mmio][txn.pf][txn.bar].on)
      txn.masked_addr = txn.addr & mask[txn.mmio][txn.pf][txn.bar].cmp;
    else
      txn.masked_addr = txn.addr;
    // -- READ -- //
    if (txn.rd) begin
      // Found an address match for first DW
      if (mbox[txn.mmio][txn.pf][txn.bar].exists(txn.masked_addr)) begin
        if (txn.u_txfer) begin
          txn.data_1 = mbox[txn.mmio][txn.pf][txn.bar][mask[txn.mmio][txn.pf][txn.bar].cmp&txn.addr];
          found[1]   = 1'b1;
        end
        else begin
          txn.data_0 = mbox[txn.mmio][txn.pf][txn.bar][mask[txn.mmio][txn.pf][txn.bar].cmp&txn.addr];
          found[0]   = 1'b1;
        end
      end
      // Found an address match for second DW 
      if (txn.len==2 && mbox[txn.mmio][txn.pf][txn.bar].exists(txn.masked_addr+4)) begin
        txn.data_1 = mbox[txn.mmio][txn.pf][txn.bar][txn.masked_addr+4];
        found[1]   = 1'b1;
      end
      if (!txn.u_txfer && !found[0]) 
        `uvm_warning(get_type_name, "Read targeted at ELBI Mailbox Txn had no lower DW match, returning '0")
      if ((txn.len==2 || txn.u_txfer) && !found[1])
        `uvm_warning(get_type_name, "Read targeted at ELBI Mailbox Txn had no upper DW match, returning '0")
      // Complete the RD
      if (!txn.u_txfer) begin 
        axi_wr(ELBI_MBOX_RDDATA_DW0, txn.data_0);
        if (txn.len==2) 
          axi_wr(ELBI_MBOX_RDDATA_DW1, txn.data_1);
      end
      else
        axi_wr(ELBI_MBOX_RDDATA_DW1, txn.data_1);
    end
    // -- WRITE -- //
    else begin
      // Get the write data
      if (!txn.u_txfer) begin
        axi_rd(ELBI_MBOX_WRDATA_DW0, txn.data_0);
        if (txn.len==2) 
          axi_rd(ELBI_MBOX_WRDATA_DW1, txn.data_1);
      end
      else
        axi_rd(ELBI_MBOX_WRDATA_DW1, txn.data_1);
      // Write the mailbox (depending on BE)
      if (txn.u_txfer) begin
        for (int ii=0; ii<4; ii++) 
          if (txn.wr_be[ii+4]) 
            mbox[txn.mmio][txn.pf][txn.bar][txn.masked_addr][(ii*8)+:8] = txn.data_1[(ii*8)+:8];
      end
      else begin
        // Lower DW
        for (int ii=0; ii<4; ii++) 
          if (txn.wr_be[ii]) 
            mbox[txn.mmio][txn.pf][txn.bar][txn.masked_addr][(ii*8)+:8] = txn.data_0[(ii*8)+:8];
        // Upper DW
        if (txn.len==2) begin 
          for (int ii=0; ii<4; ii++) 
            if (txn.wr_be[ii+4]) 
              mbox[txn.mmio][txn.pf][txn.bar][txn.masked_addr+4][(ii*8)+:8] = txn.data_1[(ii*8)+:8];
        end
      end
    end
  endtask

  virtual task post_action;
    // trigger completion to host for the read or write
    axi_wr(ELBI_MBOX_STATUS, 1'b1<<txn.rd);
  endtask

  // Clear upstream to downstream
  virtual task clear_irqs;
   // CPM6_PCIE_CORE.IR_STATUS uses [5:2] for mbox* IRQs
   axi_wr(                    IR_STATUS, (ctrlr ? bit_triggered>>5 : bit_triggered<<1));
   // CPM6_SLCR.[PL,PS]_[CORR,UNCORR,MISC] uses [10:7] or [4:1] for mbox* IRQs
   axi_wr(parent.irqs[reg_trigger].addr, bit_triggered);
   /* Must also clear the |CPM6_PCIE_CORE.IR_STATUS in MERGED_[0:2] */
   // - MERGED_0
   if (parent.irqs[MERGED_0].sts[2+(3*ctrlr)]) begin
     axi_wr(parent.irqs[MERGED_0].addr, 1'b1<<(2+(3*ctrlr)));
      // Must then clear |MERGED_0 in [CORR,UNCORR,MISC]
     if (parent.irqs[CORR].sts[21])
       axi_wr(parent.irqs[  CORR].addr, 1'b1<<21);
     if (parent.irqs[UNCORR].sts[21])
       axi_wr(parent.irqs[UNCORR].addr, 1'b1<<21);
     if (parent.irqs[MISC].sts[21])
       axi_wr(parent.irqs[  MISC].addr, 1'b1<<21);
   end
   // - MERGED_1
   if (parent.irqs[MERGED_1].sts[2+(3*ctrlr)]) begin
     axi_wr(parent.irqs[MERGED_1].addr, 1'b1<<(2+(3*ctrlr)));
      // Must then clear |MERGED_1 in [CORR,UNCORR,MISC]
     if (parent.irqs[CORR].sts[22])
       axi_wr(parent.irqs[  CORR].addr, 1'b1<<22);
     if (parent.irqs[UNCORR].sts[22])
       axi_wr(parent.irqs[UNCORR].addr, 1'b1<<22);
     if (parent.irqs[MISC].sts[22])
       axi_wr(parent.irqs[  MISC].addr, 1'b1<<22);
   end
   // - MERGED_2
   if (parent.irqs[MERGED_2].sts[2+(3*ctrlr)]) begin
     axi_wr(parent.irqs[MERGED_2].addr, 1'b1<<(2+(3*ctrlr)));
      // Must then clear |MERGED_2 in [CORR,UNCORR,MISC]
     if (parent.irqs[CORR].sts[23])
       axi_wr(parent.irqs[  CORR].addr, 1'b1<<23);
     if (parent.irqs[UNCORR].sts[23])
       axi_wr(parent.irqs[UNCORR].addr, 1'b1<<23);
     if (parent.irqs[MISC].sts[23])
       axi_wr(parent.irqs[  MISC].addr, 1'b1<<23);
   end
  endtask

  virtual function void post_print;
    if (pretty_print) print_formatted;
    else              print_raw;
  endfunction

  virtual function void print_formatted;
    string msg;
    string pre = "  - ";
    string nlp = {"\n",pre}; //"newline and pre"
    if (txn.is_vf) begin
      msg = {pre,$sformatf("PF   = %0d", txn.pf)};
      msg = {msg,nlp,$sformatf("VF   = %0d", txn.vf)};
    end
    else begin
      msg = {pre,$sformatf("PF   = %0d", txn.pf)};
    end
    msg = {msg,nlp,$sformatf("READ = %0b", txn.rd)};
    msg = {msg,nlp,$sformatf("BAR  = %0d", txn.bar)};
    msg = {msg,nlp,$sformatf("ADDR = 0x%h | MASKED_ADDR = 0x%h", txn.addr, txn.masked_addr)};
    msg = {msg,nlp,$sformatf("LEN  = %0d", txn.len)};
    msg = {msg,nlp,$sformatf("MMIO = %0d%0s", txn.mmio, txn.mmio?"":" (CFG)")};
    if (txn.erom)
      msg = {msg,nlp,"EROM = 1"};
    if (txn.rd) begin
      msg = {msg,nlp,$sformatf("DAT1 = 0x%h%0s", txn.data_1, !txn.u_txfer&&txn.len==1?" (UNUSED)":"")};
      msg = {msg,nlp,$sformatf("DAT0 = 0x%h%0s", txn.data_0, txn.u_txfer?" (UNUSED)":"")};
    end 
    else begin
      if (txn.u_txfer) begin
        msg = {msg,nlp,$sformatf("DAT1 = 0x%h | BE = 0b%b", txn.data_1, txn.wr_be[7:4])};
        msg = {msg,nlp,$sformatf("DAT0 = 0x%h (UNUSED)", txn.data_0)};
      end
      else if (txn.len==1) begin
        msg = {msg,nlp,$sformatf("DAT1 = 0x%h (UNUSED)", txn.data_1)};
        msg = {msg,nlp,$sformatf("DAT0 = 0x%h | BE = 0b%b", txn.data_0, txn.wr_be[3:0])};
      end
      else begin //txn.len==2
        msg = {msg,nlp,$sformatf("DAT1 = 0x%h | BE = 0b%b", txn.data_1, txn.wr_be[7:4])};
        msg = {msg,nlp,$sformatf("DAT0 = 0x%h | BE = 0b%b", txn.data_0, txn.wr_be[3:0])};
      end
    end
    `uvm_info(get_type_name, {"ELBI Mailbox Txn : \n", msg}, UVM_LOW)
  endfunction

  virtual function void print_raw;
    `uvm_info(get_type_name, $sformatf("ELBI Mailbox Txn : %p",txn), UVM_LOW)
  endfunction

endclass
