class rand_traffic_cxl_mem_hdm1 extends base_cxl_ep_type3_hdm1_fm;

  `uvm_component_utils(rand_traffic_cxl_mem_hdm1)

  int this_idx;

  int default_this_idx = 0;

  // Create a local copy of the memory responder
  cxl_basic_responder cxl_mem_rsp;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    timeout = 1ms;
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Build with the default index number if one hasn't been specified...
    if(!this_idx) begin
      this_idx = default_this_idx;
    end

    // Create a memory responder to sit on the other side of the NFI interface
    cxl_mem_rsp = cxl_basic_responder#()::type_id::create("cxl_mem_rsp", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect the memory responder
    env.cxl_nfi_agnt_rx[this_idx].base_tl_ap.connect(cxl_mem_rsp.fifo.analysis_export);
    cxl_mem_rsp.api68  = env.cxl_nfi_agnt_tx[this_idx].api68;
    cxl_mem_rsp.api256 = env.cxl_nfi_agnt_tx[this_idx].api256;
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    // Does most of the configuration
    super.end_of_elaboration_phase(phase);
    /* General configuration */
    env.cfg.pl_isr_recheck_time = 3us;
    env.cfg.ps_isr_recheck_time = 3us;
    /* Test specific configuration */
    vip_cfg.ctrlr_en = '0; // Disable by default
    dut_cfg.ctrlr_en = '0; // Disable by default

    vip_cfg.ctrlr_en[this_idx] = 1; // Enable this test controller
    dut_cfg.ctrlr_en[this_idx] = 1; // Enable this test controller
    // VIP as RP
    // ---
    // DUT as EP
    //  - Functions
    dut_cfg.pcie_cfg[this_idx].num_pfs = 1;
    dut_cfg.pcie_cfg[this_idx].num_vfs = 0;
    //  - HDM Ranges
    dut_cfg.cxl_cfg[this_idx].dvsec_cxl_cap.hdm_range[1].hi = '0;
    dut_cfg.cxl_cfg[this_idx].dvsec_cxl_cap.hdm_range[1].lo = 1'b1; //256 MB
  endfunction

  virtual task pre_reset_phase(uvm_phase phase);
    bit [31:0]      cxl_dev_reg_if_base;
    bit [31:0]      cxl_dev_sts_reg_base;
    bit [31:0]      cxl_prim_mbox_base;
    bit [31:0]      cxl_mem_dev_sts_reg_base;
    bit [31:0]      mbox[];
    cmd_obj_0100h   cmd_0100h = cmd_obj_0100h::type_id::create("cmd_0100h");
    cmd_obj_0101h   cmd_0101h = cmd_obj_0101h::type_id::create("cmd_0101h");
    cmd_obj_0102h   cmd_0102h = cmd_obj_0102h::type_id::create("cmd_0102h");
    cmd_obj_0103h   cmd_0103h = cmd_obj_0103h::type_id::create("cmd_0103h");
    cmd_obj_0300h   cmd_0300h = cmd_obj_0300h::type_id::create("cmd_0300h");
    cmd_obj_0301h   cmd_0301h = cmd_obj_0301h::type_id::create("cmd_0301h");
    cmd_obj_0400h   cmd_0400h = cmd_obj_0400h::type_id::create("cmd_0400h");
    cmd_obj_0401h   cmd_0401h = cmd_obj_0401h::type_id::create("cmd_0401h");
    cmd_obj_4000h   cmd_4000h = cmd_obj_4000h::type_id::create("cmd_4000h");
    super.pre_reset_phase(phase);
    /* Build the MMIO Mailbox "firmware" for the "CXL Device Register Interface"
     * - This will be dependent on BAR number and offset provided via attributes 
     *   (i.e. from the CDO so this is hardcoded to the current CDO of this test)
     * - Note: BAR0 is 256K, so mask needs to be 18 bits
     */
    // Create the mailbox header array
    mbox = new[16];
    // -> CXL Device Capabilities Array Register
    cxl_dev_reg_if_base = 'h1_0000;
    mbox[ 0] = ( 4'h1 << 24) | //Type
               ( 8'h1 << 16);  //Version
    mbox[ 1] = (16'd3 <<  0);  //Capabilities Count
    // -> CXL Device Capability Header Register : Device Status Registers (DSR)
    mbox[ 4] = ( 8'd2 << 16) | //Version
               (16'h1 <<  0);  //Capability ID
    mbox[ 5] = (    1 << 12);  //Offset (4k : 0x1000)
    mbox[ 6] =             8;  //Length (bytes)
    cxl_dev_sts_reg_base = cxl_dev_reg_if_base + mbox[5];
    // -> CXL Device Capability Header Register : Primary Mailbox Registers (PMBOXR)
    mbox[ 8] = ( 8'd1 << 16) | //Version
               (16'h2 <<  0);  //Capability ID
    mbox[ 9] = (    2 << 12);  //Offset (8k : 0x2000)
    mbox[10] =        32+256;  //Length (bytes)
    cxl_prim_mbox_base = cxl_dev_reg_if_base + mbox[9];
    // -> CXL Device Capability Header Register : Memory Device Status Registers (MDSR)
    mbox[12] = (    8'd1 << 16) | //Version
               (16'h4000 <<  0);  //Capability ID
    mbox[13] = (       3 << 12);  //Offset (12k : 0x3000)
    mbox[14] =               8;   //Length (bytes)
    cxl_mem_dev_sts_reg_base = cxl_dev_reg_if_base + mbox[13];
    // Provide the virtual FW mailbox sequence to what we just built
    cxl_mbox[this_idx].load_mmio_mbox(0, 0, cxl_dev_reg_if_base, mbox, 'h3_FFFF);
    // Create mailbox capabilities for DSR
    mbox = new[2];
    // -> DSR+0x0 : Event Status Register 
    // -- all zeroes, so nothing to assign
    // Provide the virtual FW mailbox sequence to what we just built
    cxl_mbox[this_idx].load_mmio_mbox(0, 0, cxl_dev_sts_reg_base, mbox, 'h3_FFFF);
    // Create mailbox capabilities for PMBOXR
    mbox = new[72];
    // -> PMBOXR+0x0 : Mailbox Capabilities Register
    mbox[0] = (4'h1 << 19) | //Type
              (5'd8 <<  0);  //Payload Size (2**val)
    // -> PMBOXR+0x4 : Mailbox Control Register
    // -> PMBOXR+0x8 : Command Register
    // -> PMBOXR+0x10: Mailbox Status Register
    // -> PMBOXR+0x18: Background Command Status Register
    // -> PMBOXR+0x20: Command Payload Registers
    // -- all zeroes, so nothing to assign
    // Provide the virtual FW mailbox sequence to what we just built
    cxl_mbox[this_idx].load_mmio_mbox(0, 0, cxl_prim_mbox_base, mbox, 'h3_FFFF);
    // Create mailbox capabilities for MDSR
    mbox = new[2];
    // -> MDSR+0x0 : Memory Device Status Register
    mbox[0] = (1'b1 << 4) | //Mailbox Interfaces Ready 
              (2'h1 << 2);  //Media Status (Ready)
    // Provide the virtual FW mailbox sequence to what we just built
    cxl_mbox[this_idx].load_mmio_mbox(0, 0, cxl_mem_dev_sts_reg_base, mbox, 'h3_FFFF);
    /* Set up the CXL Primary Mailbox Registers part of the sequence, which
     * must support several 'commands' which we implement as objects
     */
    cxl_mbox[this_idx].cxl_mbox_pf        = 0;
    cxl_mbox[this_idx].cxl_mbox_bar       = 0;
    cxl_mbox[this_idx].cxl_mbox_base_addr = cxl_prim_mbox_base;
    // Add the command objects 
    // - Default set
    cxl_mbox[this_idx].add_cmd_obj(cmd_0100h);
    cxl_mbox[this_idx].add_cmd_obj(cmd_0101h);
    cxl_mbox[this_idx].add_cmd_obj(cmd_0102h);
    cxl_mbox[this_idx].add_cmd_obj(cmd_0103h);
    cxl_mbox[this_idx].add_cmd_obj(cmd_0300h);
    cxl_mbox[this_idx].add_cmd_obj(cmd_0301h);
    cxl_mbox[this_idx].add_cmd_obj(cmd_0400h);
    cxl_mbox[this_idx].add_cmd_obj(cmd_0401h);
    // - Modified set
    cmd_4000h.opayload.vol_only_cap = 1; //multiple of 256MB
    cmd_4000h.opayload.total_cap    = 1; //multiple of 256MB
    cxl_mbox[this_idx].add_cmd_obj(cmd_4000h);
  endtask

  virtual task main_phase(uvm_phase phase);
    seq_cxl_cachemem_reqrwd_avery_rand seq;

    super.main_phase(phase);
    phase.raise_objection(this);

    // Create the sequence
    seq = seq_cxl_cachemem_reqrwd_avery_rand::type_id::create("seq");

    seq.txn_total = 1;
    seq.watchdog_timeout = timeout - 1ns;
    seq.dis_ops_flags = {$bits(seq.dis_ops_flags){1'b1}}; // Disable all ops
    seq.dis_ops_flags.mem = 1'b0; // Only use the basic mem ops
    // HDM information is pulled from the EP pdev, within the sequence itself
    seq.pdev = env.shim.container.get_pdev_EP;

    // Start the sequence on the sequencer...
    seq.start(env.shim.vsqr);

    phase.drop_objection(this);

  endtask

endclass
