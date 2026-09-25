/* DESCRIPTION
 * This class configures the number of PFs to 1 and VFs to 0 for enumeration
 * and the HDM to the smallest size (256 MB). Exercises CPM6 Controller 0.
 * EXTENDS
 * base_cxl_ep_type3_hdm1_fm 
 * ACRONYMS
 * hdm = "host managed device memory"
 * fm  = "flit mode"
|*/

class basic_cxl0_ep_type3_hdm1_fm extends base_cxl_ep_type3_hdm1_fm;

  `uvm_component_utils(basic_cxl0_ep_type3_hdm1_fm)

  rand bit [63:0] hdm_addr;

  constraint c_full_cl { hdm_addr[5:0]=='0; }; //cl = "cache line"

  cxl_basic_responder cxl_mem_rsp;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    timeout = $test$plusargs("AVERY_CPM6_COSIM") ? 999s : 200us;
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cxl_mem_rsp = cxl_basic_responder#()::type_id::create("cxl_mem_rsp", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Set up the responder
    env.cxl_nfi_agnt_rx[0].base_tl_ap.connect(cxl_mem_rsp.fifo.analysis_export);
    cxl_mem_rsp.api68  = env.cxl_nfi_agnt_tx[0].api68;
    cxl_mem_rsp.api256 = env.cxl_nfi_agnt_tx[0].api256;
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    // Does most of the configuration
    super.end_of_elaboration_phase(phase);
    /* General configuration */
    env.cfg.pl_isr_recheck_time = 3us;
    env.cfg.ps_isr_recheck_time = 3us;
    /* Test specific configuration */
    {vip_cfg.ctrlr_en[1], dut_cfg.ctrlr_en[1]} = 2'b0; //Ctrlr1 disabled
    // VIP as RP
    // ---
    // DUT as EP
    //  - Functions
    dut_cfg.pcie_cfg[0].num_pfs = 1;
    dut_cfg.pcie_cfg[0].num_vfs = 0;
    //  - HDM Ranges
    dut_cfg.cxl_cfg[0].dvsec_cxl_cap.hdm_range[1].hi = '0;
    dut_cfg.cxl_cfg[0].dvsec_cxl_cap.hdm_range[1].lo = 1'b1; //256 MB
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
    cxl_mbox[0].load_mmio_mbox(0, 0, cxl_dev_reg_if_base, mbox, 'h3_FFFF);
    // Create mailbox capabilities for DSR
    mbox = new[2];
    // -> DSR+0x0 : Event Status Register 
    // -- all zeroes, so nothing to assign
    // Provide the virtual FW mailbox sequence to what we just built
    cxl_mbox[0].load_mmio_mbox(0, 0, cxl_dev_sts_reg_base, mbox, 'h3_FFFF);
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
    cxl_mbox[0].load_mmio_mbox(0, 0, cxl_prim_mbox_base, mbox, 'h3_FFFF);
    // Create mailbox capabilities for MDSR
    mbox = new[2];
    // -> MDSR+0x0 : Memory Device Status Register
    mbox[0] = (1'b1 << 4) | //Mailbox Interfaces Ready 
              (2'h1 << 2);  //Media Status (Ready)
    // Provide the virtual FW mailbox sequence to what we just built
    cxl_mbox[0].load_mmio_mbox(0, 0, cxl_mem_dev_sts_reg_base, mbox, 'h3_FFFF);
    /* Set up the CXL Primary Mailbox Registers part of the sequence, which
     * must support several 'commands' which we implement as objects
     */
    cxl_mbox[0].cxl_mbox_pf        = 0;
    cxl_mbox[0].cxl_mbox_bar       = 0;
    cxl_mbox[0].cxl_mbox_base_addr = cxl_prim_mbox_base;
    // Add the command objects 
    // - Default set
    cxl_mbox[0].add_cmd_obj(cmd_0100h);
    cxl_mbox[0].add_cmd_obj(cmd_0101h);
    cxl_mbox[0].add_cmd_obj(cmd_0102h);
    cxl_mbox[0].add_cmd_obj(cmd_0103h);
    cxl_mbox[0].add_cmd_obj(cmd_0300h);
    cxl_mbox[0].add_cmd_obj(cmd_0301h);
    cxl_mbox[0].add_cmd_obj(cmd_0400h);
    cxl_mbox[0].add_cmd_obj(cmd_0401h);
    // - Modified set
    cmd_4000h.opayload.vol_only_cap = 1; //multiple of 256MB
    cmd_4000h.opayload.total_cap    = 1; //multiple of 256MB
    cxl_mbox[0].add_cmd_obj(cmd_4000h);
  endtask

  // Do actual work
  virtual task main_phase(uvm_phase phase);
    string              msg;
    bit [63:0]          hdm_base;
    bit [63:0]          hdm_size;
    bit [63:0]          hdm_end;
    pcie_device         ep_dev;
    amd_cxlmem_tlp      cxltlp;
    bit [63:0][7:0]     wdat;
    cxl_comp_mbox_cmd_s cmd;

    super.main_phase(phase);
    phase.raise_objection(this);

    // Co-Sim just waits forever
    if ($test$plusargs("AVERY_CPM6_COSIM"))
      `uvm_info(get_type_name, "Running a co-sim, waiting forever", UVM_NONE)
    wait($test$plusargs("AVERY_CPM6_COSIM")==0); 

    // Get status object of CXL EP
    ep_dev = env.shim.container.get_pdev_EP;

    // Print the CXL reg blocks and device capabilities
    ep_dev.print_cxl_reg_blks;
    ep_dev.print_cxl_dev_caps;

    // Show some example mailbox commands
    if (0) begin
      cmd.opcode   = TIMESTAMP_SetTimestamp;
      cmd.ipayload = '{8'h11, 8'h22, 8'h33, 8'h44, 8'h55, 8'h66, 8'h77, 8'h88};
      env.shim.api.send_cxl_mbox_cmd(ep_dev, cmd);
      
      cmd.opcode = TIMESTAMP_GetTimestamp;
      cmd.ipayload.delete;
      env.shim.api.send_cxl_mbox_cmd(ep_dev, cmd);
    end

    // Configure and send a full cacheline CXL.mem write and read to HDM0
    hdm_base = ep_dev.cxl_hdm[0].base;
    hdm_size = ep_dev.cxl_hdm[0].sz;
    hdm_end  = hdm_base+hdm_size;

    cxltlp = amd_cxlmem_tlp::type_id::create("cxltlp");
    void'(this.randomize with { hdm_addr inside {[hdm_base:hdm_end]}; });
    // - WR 
    foreach (wdat[ii]) wdat[ii] = ii;
    cxltlp.build_wr(hdm_addr, '{wdat}, .coh(BYPASS_AGENT), .blocking(DONE)); 

    msg = $sformatf("Sending HDM WR 0x%h:\n", hdm_addr);
    foreach (cxltlp.data[0][ii])
      msg = {msg, $sformatf("\t%0sDW_%0d = 0x%h\n",
                  ii<10?" ":"",
                  ii,
                  cxltlp.data[0][ii])};
    `uvm_info(get_type_name, msg, UVM_NONE)

    env.shim.api.send_cxl_txn(cxltlp);
    `uvm_info(get_type_name, "HDM WR Done", UVM_NONE)
    // - RD 
    cxltlp.build_rd(hdm_addr, .coh(BYPASS_AGENT), .blocking(DONE)); 
    `uvm_info(get_type_name, $sformatf("Sending HDM RD 0x%h", hdm_addr), UVM_NONE)
    env.shim.api.send_cxl_txn(cxltlp);

    msg = "HDM RD Done:\n";
    foreach (cxltlp.data[0][ii])
      msg = {msg, $sformatf("\t%0sDW_%0d = 0x%h\n",
                  ii<10?" ":"",
                  ii,
                  cxltlp.data[0][ii])};
    `uvm_info(get_type_name, msg, UVM_NONE)

    // Configure and send a partial cacheline CXL.mem write and read to HDM0
    cxltlp = amd_cxlmem_tlp::type_id::create("cxltlp");
    void'(this.randomize with { hdm_addr inside {[hdm_base:hdm_end]}; });
    // - WR 
    foreach (wdat[ii]) wdat[ii] = 'h40+ii;
    cxltlp.build_wr(hdm_addr, '{wdat}, '{{32{1'b1}}}, .coh(BYPASS_AGENT), .blocking(DONE)); 
    
    msg = $sformatf("Sending partial HDM WR 0x%h:\n", hdm_addr);
    foreach (cxltlp.data[0][ii])
      msg = {msg, $sformatf("\t%0sDW_%0d = 0x%h, BE=0x%h\n",
                  ii<10?" ":"",
                  ii,
                  cxltlp.data[0][ii],
                  cxltlp.be[0][ii*4+:4])};
    `uvm_info(get_type_name, msg, UVM_NONE)

    env.shim.api.send_cxl_txn(cxltlp);
    `uvm_info(get_type_name, "Partial HDM WR Done", UVM_NONE)
    // - RD 
    cxltlp.build_rd(hdm_addr, .coh(BYPASS_AGENT), .blocking(DONE)); 
    `uvm_info(get_type_name, $sformatf("Sending HDM RD 0x%h", hdm_addr), UVM_NONE)
    env.shim.api.send_cxl_txn(cxltlp);

    msg = "HDM RD Done:\n";
    foreach (cxltlp.data[0][ii])
      msg = {msg, $sformatf("\t%0sDW_%0d = 0x%h\n",
                  ii<10?" ":"",
                  ii,
                  cxltlp.data[0][ii])};
    `uvm_info(get_type_name, msg, UVM_NONE)

    phase.drop_objection(this);
  endtask

endclass
