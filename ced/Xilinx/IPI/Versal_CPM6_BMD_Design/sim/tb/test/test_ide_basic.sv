//=============================================================================
// IDE Fail Callback - Monitors received TLPs for IDE fail messages
//=============================================================================
class ide_fail_cb extends apci_callbacks;
  const string id = "IDE_FAIL_CB";
  
  function new();
  endfunction

  virtual function void rx_pkt_enter_tl(apci_device bfm, apci_tlp tlp);
    if (tlp.kind inside {APCI_TLP_msg, APCI_TLP_msgd}) begin
      bit [7:0] msg_code = tlp.is_flit_mode ? tlp.u.fm_msg.msg_code : tlp.u.msg.msg_code;
      if (msg_code == 8'h55) begin  // IDE Fail message code per PCIe 6.0 spec
        `uvm_fatal(id, $sformatf("IDE Fail message received! TLP: %s", tlp.sprint()))
      end
    end
  endfunction
endclass

//=============================================================================
// IDE Stream Configuration Container
//=============================================================================
class ide_stream_cfg;
  bit          enable;
  bit          pcrc_enable;
  bit   [2:0]  tc;
  bit   [7:0]  stream_id;
  bit   [3:0]  partial_header_encryption_mode;
  
  // Selective IDE specific
  bit          default_stream;
  bit          for_configuration_requests;
  bit   [15:0] rid_limit;
  bit   [15:0] rid_base;
  bit          rid_valid;
  bit   [63:0] addr_limit[2];
  bit   [63:0] addr_base[2];
  bit          addr_valid[2];

  function new();
    enable = 0;
    pcrc_enable = 0;
    tc = 0;
    stream_id = 0;
    partial_header_encryption_mode = 0;
    default_stream = 0;
    for_configuration_requests = 0;
    rid_limit = 0;
    rid_base = 0;
    rid_valid = 0;
    addr_limit = '{default: 0};
    addr_base = '{default: 0};
    addr_valid = '{default: 0};
  endfunction
endclass

//=============================================================================
// Test: IDE Basic
//=============================================================================
class test_ide_basic extends base_ep_test;
  `uvm_component_utils(test_ide_basic)

  //--- Key Constants ---
  localparam int NUM_SUBSTREAMS      = 3;   // PR, NPR, CPL
  localparam int NUM_DIRECTIONS      = 2;   // TX, RX
  localparam int NUM_KEY_SETS        = 2;   // K=0, K=1
  localparam int KEYS_PER_STREAM     = NUM_SUBSTREAMS * NUM_DIRECTIONS * NUM_KEY_SETS;  // 12
  localparam int LINK_KEY_START      = 0;
  localparam int LINK_KEY_END        = 12;
  localparam int SEL_KEY_START       = 12;
  localparam int SEL_KEY_END         = 24;

  //--- Handles ---
  pcie_device     pdev_rp;
  pcie_device     pdev_ep;
  ide_fail_cb     ide_fail_callback;
  ecap_s          doe_cap_info;  // Capability location info from pdev
  ecap_s          ide_cap_info;  // Capability location info from pdev
  
  //--- Extended Capability Objects (with DW offsets and helper functions) ---
  ecap_doe        doe_ecap;      // DOE capability object
  ecap_ide        ide_ecap;      // IDE capability object

  //--- Configuration ---
  ide_stream_cfg  link_ide_cfg;
  ide_stream_cfg  sel_ide_cfg;
  
  logic           bypass_doe_discovery;
  logic           bypass_spdm_flow;
  logic           fw_available;
  bit             ide_fail_monitor_en;

  //--- IDE Keys (12 for Link + 12 for Selective) ---
  apci_ide_key_iv_t ide_key[24];

  //===========================================================================
  // Constructor
  //===========================================================================
  function new(string name, uvm_component parent);
    super.new(name, parent);
    
    // Create config objects
    link_ide_cfg = new();
    sel_ide_cfg = new();
    
    // Create capability objects
    doe_ecap = ecap_doe::type_id::create("doe_ecap");
    ide_ecap = ecap_ide::type_id::create("ide_ecap");
    
    // Initialize random keys
    init_ide_keys();
    
    // Default configuration
    bypass_spdm_flow     = 1'b1;
    bypass_doe_discovery = 1'b1;
    fw_available         = 1'b0;
    ide_fail_monitor_en  = 1'b1;
  endfunction

  //===========================================================================
  // Key Initialization
  //===========================================================================
  function void init_ide_keys();
    foreach (ide_key[i]) begin
      for (int j = 0; j < 8; j++) begin
        logic [31:0] key = $urandom;
        ide_key[i].key[j*4 + 0] = key[7:0];
        ide_key[i].key[j*4 + 1] = key[15:8];
        ide_key[i].key[j*4 + 2] = key[23:16];
        ide_key[i].key[j*4 + 3] = key[31:24];
      end
      ide_key[i].iv    = 96'b1;
      ide_key[i].valid = 1'b1;
    end
  endfunction

  function string ide_substream_name_from_idx(int idx);
    case (idx % 3)
      0: return "PR";
      1: return "NPR";
      2: return "CPL";
      default: return "UNK";
    endcase
  endfunction

  function string ide_substream_name(apci_ide_sub_stream_e substream);
    case (substream)
      APCI_IDE_SUB_STREAM_post_req     : return "PR";
      APCI_IDE_SUB_STREAM_non_post_req : return "NPR";
      APCI_IDE_SUB_STREAM_cpl          : return "CPL";
      default                          : return "UNK";
    endcase
  endfunction

  function string ide_dir_name(bit tx);
    return tx ? "TX" : "RX";
  endfunction

  function string ide_key_summary(apci_ide_key_iv_t key);
    return $sformatf("valid=%0b iv=%024h key[0+:8]=%02x_%02x_%02x_%02x_%02x_%02x_%02x_%02x",
                     key.valid, key.iv,
                     key.key[0], key.key[1], key.key[2], key.key[3],
                     key.key[4], key.key[5], key.key[6], key.key[7]);
  endfunction

  //===========================================================================
  // Post CDO Load Phase
  //===========================================================================
  virtual task post_cdo_load();
    super.post_cdo_load();

    if (!fw_available) begin
      setup_doe_interrupt_handlers();
    end

    env.shim.vip.cfg_info.bypass_spdm_flow = bypass_spdm_flow;
  endtask

  task setup_doe_interrupt_handlers();
    cseq_core_doe_discovery_cfg_mb doe_isr[2];
    cseq_cpm6_pcie_core_isr_src    core_isr[2];
    
    for (int i = 0; i < 2; i++) begin
      if (dut_ctrlr_en[i]) begin
        core_isr[i] = cseq_cpm6_pcie_core_isr_src::type_id::create($sformatf("core_isr_%0d", i));
        core_isr[i].set_ctrlr(i);
        core_isr[i].reg_trigger = CORR;
        core_isr[i].bit_trigger = 'h6 << (i * 6);
        core_isr[i].register_isr(env.ps_isr_seq);
        
        doe_isr[i] = cseq_core_doe_discovery_cfg_mb::type_id::create($sformatf("doe_isr_%0d", i));
        doe_isr[i].set_ctrlr(i);
        doe_isr[i].register_isr(core_isr[i]);
      end
    end
  endtask

  //===========================================================================
  // DOE Helper Tasks
  //===========================================================================
  task wait_doe_ready();
    bit [31:0] status;
    bit err;
    do begin
      env.shim.api.read_cap_dw(pdev_ep.bdf, .ecap(ECAP_DOE), .offset(ecap_doe::DW_STATUS), .data(status), .err(err));
      doe_ecap.set_dw(ecap_doe::DW_STATUS, status);
      `uvm_info(get_type_name, $sformatf("DOE status = %0h (busy=%0b)", status, doe_ecap.is_busy()), UVM_LOW)
      #(1us);
    end while (doe_ecap.is_busy());
  endtask

  task send_doe_abort();
    bit err;
    doe_ecap.set_abort();
    env.shim.api.write_cap_dw(pdev_ep.bdf, .ecap(ECAP_DOE), .offset(ecap_doe::DW_CTRL), 
                               .data(doe_ecap.get_dw(ecap_doe::DW_CTRL)), .err(err));
  endtask

  //===========================================================================
  // IDE Register Access Tasks (using config TLPs for extended registers)
  //===========================================================================
  
  // Write IDE register using config TLP (avoids VIP capability size limitation)
  task write_ide_reg(bit [15:0] bdf, int dw_offset, bit [31:0] data);
    amd_cfg_tlp tlp;
    ecap_s cap_info;
    pcie_device pdev;
    bit [11:0] cap_base;
    
    // Get the target device and IDE cap base
    pdev = (bdf == pdev_rp.bdf) ? pdev_rp : pdev_ep;
    if (!pdev.get_ecap(ECAP_IDE, cap_info)) begin
      `uvm_fatal(get_type_name, $sformatf("IDE capability not found for BDF %04h", bdf))
    end
    cap_base = cap_info.base;
    
    // Send config write TLP
    tlp = amd_cfg_tlp::type_id::create("ide_cfg_wr");
    tlp.build_wr(cap_base + (dw_offset * 4), data, .bdf(bdf));
    env.shim.api.send_cfg(tlp);
  endtask

  // Read IDE register using config TLP
  task read_ide_reg(bit [15:0] bdf, int dw_offset, output bit [31:0] data);
    amd_cfg_tlp tlp;
    ecap_s cap_info;
    pcie_device pdev;
    bit [11:0] cap_base;
    
    // Get the target device and IDE cap base
    pdev = (bdf == pdev_rp.bdf) ? pdev_rp : pdev_ep;
    if (!pdev.get_ecap(ECAP_IDE, cap_info)) begin
      `uvm_fatal(get_type_name, $sformatf("IDE capability not found for BDF %04h", bdf))
    end
    cap_base = cap_info.base;
    
    // Send config read TLP
    tlp = amd_cfg_tlp::type_id::create("ide_cfg_rd");
    tlp.build_rd(cap_base + (dw_offset * 4), .bdf(bdf));
    env.shim.api.send_cfg(tlp);
    data = tlp.data[0];
  endtask

  //===========================================================================
  // IDE Stream Configuration Tasks
  //===========================================================================
  
  // Configure Link IDE stream on ecap_ide from ide_stream_cfg and write to target BDF
  task configure_link_ide_stream(bit [15:0] bdf);
    // Configure ecap_ide internal data from cfg
    ide_ecap.configure_link_from_cfg(
      .stream_id(link_ide_cfg.stream_id),
      .tc(link_ide_cfg.tc),
      .pcrc_en(link_ide_cfg.pcrc_enable),
      .partial_header_enc_mode(link_ide_cfg.partial_header_encryption_mode),
      .enable(1'b0)  // Enable=0 initially
    );
    
    // Write to target BDF using config TLP
    write_ide_reg(bdf, ecap_ide::DW_LINK_CTRL, ide_ecap.get_dw(ecap_ide::DW_LINK_CTRL));
  endtask

  // Configure Selective IDE stream on ecap_ide from ide_stream_cfg and write to target BDF
  task configure_selective_ide_stream(bit [15:0] bdf);
    // Configure ecap_ide internal data from cfg
    ide_ecap.configure_sel_from_cfg(
      .stream_id(sel_ide_cfg.stream_id),
      .tc(sel_ide_cfg.tc),
      .pcrc_en(sel_ide_cfg.pcrc_enable),
      .partial_header_enc_mode(sel_ide_cfg.partial_header_encryption_mode),
      .default_stream(sel_ide_cfg.default_stream),
      .sel_ide_for_cfg_req(sel_ide_cfg.for_configuration_requests),
      .enable(1'b0),  // Enable=0 initially
      .rid_base(sel_ide_cfg.rid_base),
      .rid_limit(sel_ide_cfg.rid_limit),
      .rid_valid(sel_ide_cfg.rid_valid)
    );
    
    // Set address associations
    for (int i = 0; i < 2; i++) begin
      ide_ecap.set_addr_assoc(i, sel_ide_cfg.addr_base[i], sel_ide_cfg.addr_limit[i], sel_ide_cfg.addr_valid[i]);
    end
    
    // Write control register to target BDF using config TLP
    write_ide_reg(bdf, ecap_ide::DW_SEL_CTRL, ide_ecap.get_dw(ecap_ide::DW_SEL_CTRL));
    
    // Write RID association registers
    write_ide_reg(bdf, ecap_ide::DW_SEL_RID_ASSOC1, ide_ecap.get_dw(ecap_ide::DW_SEL_RID_ASSOC1));
    write_ide_reg(bdf, ecap_ide::DW_SEL_RID_ASSOC2, ide_ecap.get_dw(ecap_ide::DW_SEL_RID_ASSOC2));
    
    // Write address association registers
    for (int i = 0; i < 2; i++) begin
      int dw_offset = ide_ecap.get_addr_assoc_dw_offset(i);
      write_ide_reg(bdf, dw_offset,     ide_ecap.get_dw(dw_offset));
      write_ide_reg(bdf, dw_offset + 1, ide_ecap.get_dw(dw_offset + 1));
      write_ide_reg(bdf, dw_offset + 2, ide_ecap.get_dw(dw_offset + 2));
    end

    `uvm_info(get_type_name,
              $sformatf({"Selective IDE cfg for bdf %04h: CTRL=%08h RID1=%08h RID2=%08h ",
                         "ADDR0={%08h,%08h,%08h} ADDR1={%08h,%08h,%08h}"},
                        bdf,
                        ide_ecap.get_dw(ecap_ide::DW_SEL_CTRL),
                        ide_ecap.get_dw(ecap_ide::DW_SEL_RID_ASSOC1),
                        ide_ecap.get_dw(ecap_ide::DW_SEL_RID_ASSOC2),
                        ide_ecap.get_dw(ecap_ide::DW_SEL_ADDR_ASSOC0 + 0),
                        ide_ecap.get_dw(ecap_ide::DW_SEL_ADDR_ASSOC0 + 1),
                        ide_ecap.get_dw(ecap_ide::DW_SEL_ADDR_ASSOC0 + 2),
                        ide_ecap.get_dw(ecap_ide::DW_SEL_ADDR_ASSOC0 + 3),
                        ide_ecap.get_dw(ecap_ide::DW_SEL_ADDR_ASSOC0 + 4),
                        ide_ecap.get_dw(ecap_ide::DW_SEL_ADDR_ASSOC0 + 5)),
              UVM_NONE)
  endtask

  //===========================================================================
  // IDE Stream State Wait Tasks
  //===========================================================================
  task wait_ide_stream_secure(bit is_link_ide);
    bit [31:0] status;
    bit is_secure;
    int ctrl_dw   = is_link_ide ? ecap_ide::DW_LINK_CTRL   : ecap_ide::DW_SEL_CTRL;
    int status_dw = is_link_ide ? ecap_ide::DW_LINK_STATUS : ecap_ide::DW_SEL_STATUS;
    ide_stream_cfg cfg = is_link_ide ? link_ide_cfg : sel_ide_cfg;
    string stream_name = is_link_ide ? "Link" : "Selective";
    
    // Build control value with enable=1
    logic [31:0] ctrl_val;
    if (is_link_ide) begin
      ctrl_val = ide_ecap.build_link_ctrl(cfg.stream_id, cfg.tc, cfg.pcrc_enable, 1'b1);
    end else begin
      ctrl_val = ide_ecap.build_sel_ctrl(cfg.stream_id, cfg.tc, cfg.partial_header_encryption_mode,
                                          cfg.for_configuration_requests, cfg.default_stream, 
                                          cfg.pcrc_enable, 1'b1);
    end
    
    // Enable IDE Stream using config TLP
    write_ide_reg(pdev_ep.bdf, ctrl_dw, ctrl_val);
    
    // Poll for secure state (bit 1 = secure)
    do begin
      read_ide_reg(pdev_ep.bdf, status_dw, status);
      ide_ecap.set_dw(status_dw, status);
      is_secure = is_link_ide ? ide_ecap.is_link_secure() : ide_ecap.is_sel_secure();
      `uvm_info(get_type_name, $sformatf("IDE %s status = %0h (secure=%0b)", stream_name, status, is_secure), UVM_LOW)
      #(1us);
    end while ((status & 'h2) != 2);
  endtask

  //===========================================================================
  // IDE Key Programming
  //===========================================================================
  
  // Set all IDE keys on VIP for a given stream
  task set_vip_ide_keys(bit [7:0] stream_id, int key_start);
    apci_ide_sub_stream_e substreams[3] = '{
      APCI_IDE_SUB_STREAM_post_req,
      APCI_IDE_SUB_STREAM_non_post_req,
      APCI_IDE_SUB_STREAM_cpl
    };
    
    int key_idx = key_start;
    for (int k = 0; k < NUM_KEY_SETS; k++) begin        // K=0, K=1
      for (int dir = 0; dir < NUM_DIRECTIONS; dir++) begin  // TX=1, RX=0
        for (int ss = 0; ss < NUM_SUBSTREAMS; ss++) begin   // PR, NPR, CPL
          env.shim.vip.port_set_ide_key(0, stream_id, substreams[ss], 
                                         (dir == 0), k, ide_key[key_idx]);
          `uvm_info(get_type_name,
                    $sformatf("VIP IDE key stream=%0d substream=%s dir=%s k=%0d key_idx=%0d %s",
                              stream_id, ide_substream_name(substreams[ss]),
                              ide_dir_name(dir == 0), k, key_idx,
                              ide_key_summary(ide_key[key_idx])),
                    UVM_NONE)
          key_idx++;
        end
      end
    end
  endtask

  // Program IDE keys via sequence
  task prg_ide_keys(int idx_offset, int key_start, int key_end);
    seq_program_ide_key ide_seq = seq_program_ide_key::type_id::create("ide_prg_seq");
    
    env.ps_sem.get(1);
    for (int i = key_start; i < key_end; i++) begin
      bit rp_rx_key = (i / 3) % 2;     // First 3 keys are one direction, next 3 are the other
      bit is_k      = (i / 6) % 2;     // First 6 keys are K=0, last 6 keys are K=1
      // Slot map:
      //   Selective K0 -> 0,1,2
      //   Link      K0 -> 3,4,5
      //   Selective K1 -> 6,7,8
      //   Link      K1 -> 9,10,11
      int idx       = (i % 3) + idx_offset + (is_k * 6);

      `uvm_info(get_type_name,
                $sformatf("DUT IDE key index=%0d substream=%s dir=%s k=%0d hw_idx=%0d %s",
                          i, ide_substream_name_from_idx(i), ide_dir_name(rp_rx_key),
                          is_k, idx, ide_key_summary(ide_key[i])),
                UVM_NONE)
      ide_seq.index   = idx;
      ide_seq.tx      = rp_rx_key;
      ide_seq.ide_key = ide_key[i];
      ide_seq.start(env.ps_vip_vsqr);
    end
    env.ps_sem.put(1);
  endtask

  task prg_link_ide_keys();
    prg_ide_keys(3, LINK_KEY_START, LINK_KEY_END);
  endtask

  task prg_sel_ide_keys();
    prg_ide_keys(0, SEL_KEY_START, SEL_KEY_END);
  endtask

  //===========================================================================
  // IDE Fail Monitoring
  //===========================================================================
  task register_ide_fail_callback();
    ide_fail_callback = new();
    env.shim.vip.append_callback(ide_fail_callback);
    `uvm_info(get_type_name, "IDE Fail callback registered - will fatal on IDE fail message", UVM_LOW)
  endtask

  //===========================================================================
  // Populate apci_cap_ide from ecap_ide - Link IDE
  //===========================================================================
  function void populate_apci_cap_ide_link(apci_cap_ide ide, int stream_idx = 0);
    ide.link_ide_stream_id[stream_idx].set_v(ide_ecap.data.cap.link_ctrl.stream_id);
    ide.link_ide_tc[stream_idx].set_v(ide_ecap.data.cap.link_ctrl.tc);
    ide.link_ide_pcrc_enable[stream_idx].set_v(ide_ecap.data.cap.link_ctrl.pcrc_en);
    ide.link_ide_partial_header_encryption_mode[stream_idx].set_v(ide_ecap.data.cap.link_ctrl.partial_header_enc_mode);
    ide.link_ide_stream_enable[stream_idx].set_v(ide_ecap.data.cap.link_ctrl.en);
  endfunction

  //===========================================================================
  // Populate apci_cap_ide from ecap_ide - Selective IDE
  //===========================================================================
  function void populate_apci_cap_ide_sel(apci_cap_ide ide, int stream_idx = 0, int num_addr_blocks = 2);
    // Control fields
    ide.sel_ide_stream_id[stream_idx].set_v(ide_ecap.data.cap.sel_ctrl.stream_id);
    ide.sel_ide_tc[stream_idx].set_v(ide_ecap.data.cap.sel_ctrl.tc);
    ide.sel_ide_pcrc_enable[stream_idx].set_v(ide_ecap.data.cap.sel_ctrl.pcrc_en);
    ide.sel_ide_default_stream[stream_idx].set_v(ide_ecap.data.cap.sel_ctrl.default_stream);
    ide.sel_ide_for_cfg_req_enable[stream_idx].set_v(ide_ecap.data.cap.sel_ctrl.sel_ide_for_cfg_req_en);
    ide.sel_ide_partial_header_encryption_mode[stream_idx].set_v(ide_ecap.data.cap.sel_ctrl.partial_header_enc_mode);
    ide.sel_ide_stream_enable[stream_idx].set_v(ide_ecap.data.cap.sel_ctrl.en);

    
    // RID association
    ide.rid_valid[stream_idx].set_v(ide_ecap.data.cap.sel_rid_assoc2.valid);
    ide.rid_limit[stream_idx].set_v(ide_ecap.data.cap.sel_rid_assoc1.rid_limit);
    ide.rid_base[stream_idx].set_v(ide_ecap.data.cap.sel_rid_assoc2.rid_base);
    
    // Address associations - now using sel_addr[] array
    for (int addr_idx = 0; addr_idx < num_addr_blocks; addr_idx++) begin
      ide.mem_base_lo[stream_idx][addr_idx].set_v(ide_ecap.data.cap.sel_addr[addr_idx].lo.mem_base_lo);
      ide.mem_base_hi[stream_idx][addr_idx].set_v(ide_ecap.data.cap.sel_addr[addr_idx].base_hi.mem_base_hi);
      ide.mem_limit_lo[stream_idx][addr_idx].set_v(ide_ecap.data.cap.sel_addr[addr_idx].lo.mem_limit_lo);
      ide.mem_limit_hi[stream_idx][addr_idx].set_v(ide_ecap.data.cap.sel_addr[addr_idx].limit_hi.mem_limit_hi);
      ide.addr_valid[stream_idx][addr_idx].set_v(ide_ecap.data.cap.sel_addr[addr_idx].lo.valid);
    end
  endfunction

  //===========================================================================
  // VIP IDE Capability Setup - Build apci_cap_ide from ecap_ide
  // For Link IDE: read/populate/write through VIP capability interface
  // For Selective IDE: only populate VIP's internal apci_cap_ide (so VIP knows 
  //                    about the stream) - actual device registers are written 
  //                    via config TLPs
  //===========================================================================
  task setup_vip_ide_capability(apci_cap_ide ide, bit is_link_ide);
    bit err;
    
    if (is_link_ide) begin
      env.shim.vip.read_capability(pdev_rp.bdf, ide, ide.link_ide_stream_enable[0].get_offset_dw, err);
      ide.reconfig();
      populate_apci_cap_ide_link(ide, 0);
      env.shim.vip.write_capability(pdev_rp.bdf, ide, ide.link_ide_stream_enable[0].get_offset_dw, err);
    end else begin
      env.shim.vip.read_capability(pdev_rp.bdf, ide, ide.sel_ide_stream_enable[0].get_offset_dw, err);
      ide.reconfig();
      ide.num_of_addr_associate_reg_blk[0].set_v(ecap_ide::NUM_ADDR_ASSOC_BLOCKS);
      ide.reconfig_sec();
      populate_apci_cap_ide_sel(ide, 0, ecap_ide::NUM_ADDR_ASSOC_BLOCKS);
      env.shim.vip.write_capability(pdev_rp.bdf, ide, ide.sel_ide_stream_enable[0].get_offset_dw, err);
    end
  endtask

  //===========================================================================
  // IDE Stream Enable Flow
  //===========================================================================
  task enable_ide_stream(
    apci_cap_ide       ide,
    apci_device_util   util,
    apci_cap_doe       doe_a[],
    apci_func_info     tgt_finf,
    bit                is_link_ide
  );
    bit err;
    ide_stream_cfg cfg = is_link_ide ? link_ide_cfg : sel_ide_cfg;
    string stream_name = is_link_ide ? "Link" : "Selective";
    
    // Set VIP IDE keys
    set_vip_ide_keys(cfg.stream_id, is_link_ide ? LINK_KEY_START : SEL_KEY_START);
    
    // Configure stream on EP using ecap_ide
    if (is_link_ide) begin
      configure_link_ide_stream(pdev_ep.bdf);
    end else begin
      configure_selective_ide_stream(pdev_ep.bdf);
    end
    
    // Configure stream on RP using ecap_ide (write to RP BDF)
    if (is_link_ide) begin
      configure_link_ide_stream(pdev_rp.bdf);
    end else begin
      configure_selective_ide_stream(pdev_rp.bdf);
    end
    
    // Configure VIP capability (populates apci_cap_ide from ecap_ide)
    setup_vip_ide_capability(ide, is_link_ide);
    
    // Enable stream via SPDM or backdoor
    if (!bypass_spdm_flow) begin
      util.init_ide_by_km(0, tgt_finf, doe_a, cfg.stream_id, 0, err);
      if (!fw_available) begin
        if (is_link_ide) prg_link_ide_keys();
        else             prg_sel_ide_keys();
      end
      wait_ide_stream_secure(is_link_ide);
    end else begin
      if (is_link_ide) prg_link_ide_keys();
      else             prg_sel_ide_keys();
      wait_ide_stream_secure(is_link_ide);
      
      // Enable stream on RP using ecap_ide - set enable bit and write
      if (is_link_ide) begin
        ide_ecap.data.cap.link_ctrl.en = 1'b1;
        write_ide_reg(pdev_rp.bdf, ecap_ide::DW_LINK_CTRL, ide_ecap.get_dw(ecap_ide::DW_LINK_CTRL));
        // Also update VIP's apci_cap_ide with enable bit and write to VIP
        populate_apci_cap_ide_link(ide, 0);
        env.shim.vip.write_capability(pdev_rp.bdf, ide, ide.link_ide_stream_enable[0].get_offset_dw, err);
      end else begin
        ide_ecap.data.cap.sel_ctrl.en = 1'b1;
        write_ide_reg(pdev_rp.bdf, ecap_ide::DW_SEL_CTRL, ide_ecap.get_dw(ecap_ide::DW_SEL_CTRL));
        // Also update VIP's apci_cap_ide with enable bit and write to VIP
        populate_apci_cap_ide_sel(ide, 0, ecap_ide::NUM_ADDR_ASSOC_BLOCKS);
        env.shim.vip.write_capability(pdev_rp.bdf, ide, ide.sel_ide_stream_enable[0].get_offset_dw, err);
      end
    end
    
    // Wait for VIP to enter secure state
    env.shim.vip.port_set(0, "ide_stream_secure_state", cfg.stream_id, 1);
    env.shim.vip.port_wait_ide_state(0, cfg.stream_id, APCI_IDE_secure, 100ns, 
                                      $sformatf("Wait for RC to enter %s IDE secure state", stream_name));
  endtask

  //===========================================================================
  // Main Phase
  //===========================================================================
  virtual task main_phase(uvm_phase phase);
    apci_device_util   util;
    apci_cap_doe       doe_a[];
    bit                ok, err;
    apci_func_info     tgt_finf;
    apci_cap_ide       ide;
    apci_seq_util      seq;
    apci_security_util sec_util;

    super.main_phase(phase);
    phase.raise_objection(this);
    
    //--- Initialize handles ---
    ide     = new();
    seq     = new(env.shim.vip, env.shim.vip);
    util    = new(env.shim.vip);
    pdev_rp = env.shim.container.get_pdev_RP; 
    pdev_ep = env.shim.container.get_pdev_EP;
    
    if (!bypass_spdm_flow) begin
      sec_util = new(env.shim.vip);
    end
    
    //--- Configure VIP security settings ---
    env.shim.vip.security_set("MinDataTransferSize", 32'h0FB0);
    env.shim.vip.security_set("doe_response_timeout_us", 1000000);
    env.shim.vip.security_set("base_asym_algo", APCI_SPDM_tpm_alg_ecdsa_ecc_nist_p384);
    env.shim.vip.security_set("base_hash_algo", APCI_SPDM_tpm_alg_sha_384);
    env.shim.vip.security_set("dhe_supported_algo", APCI_SPDM_DHE_secp384r1);
    env.shim.vip.set_dut_pre_shared_key(256'h0, pdev_ep.bdf);

    //--- Register IDE fail callback ---
    if (ide_fail_monitor_en) begin
      register_ide_fail_callback();
    end

    //--- Verify IDE capability support ---
    ide.configure();
    env.shim.vip.read_capability(pdev_rp.bdf, ide, ide.link_ide_stream_sup.get_offset_dw, err);
    if (err) begin
      `uvm_fatal(get_type_name, "Failed to read IDE capability - aborting")
    end
    if (link_ide_cfg.enable && !ide.link_ide_stream_sup.v) begin
      `uvm_fatal(get_type_name, "Link IDE stream not supported - aborting")
    end
    if (sel_ide_cfg.enable && !ide.sel_ide_stream_sup.v) begin
      `uvm_fatal(get_type_name, "Selective IDE stream not supported - aborting")
    end
    ide.reconfig();

    //--- Verify DOE and IDE extended capabilities ---
    seq.get_link_partner_info(env.shim.vip, 0, tgt_finf);

    if (!pdev_ep.get_ecap(ECAP_DOE, doe_cap_info)) begin
      `uvm_fatal(get_type_name, "Device does not support DOE capability - aborting")
    end
    if (!pdev_ep.get_ecap(ECAP_IDE, ide_cap_info)) begin
      `uvm_fatal(get_type_name, "Device does not support IDE capability - aborting")
    end

    //--- DOE Discovery ---
    if (!bypass_doe_discovery) begin
      send_doe_abort();
      wait_doe_ready();
      
      util.init_doe(tgt_finf, {APCI_DOE_spdm, APCI_DOE_secured_spdm}, doe_a, ok);
      if (!ok) begin
        `uvm_error(get_type_name, "Device does not support required DOE protocols (SPDM and Secure SPDM)")
      end
    end

    //--- SPDM Session Establishment ---
    if (!bypass_spdm_flow) begin
      sec_util.check_and_establish_spdm_secure_session(0, err);
    end

    //--- Enable IDE Streams ---
    if (link_ide_cfg.enable) begin
      enable_ide_stream(ide, util, doe_a, tgt_finf, .is_link_ide(1));
    end

    if (sel_ide_cfg.enable) begin
      enable_ide_stream(ide, util, doe_a, tgt_finf, .is_link_ide(0));
    end
    
    phase.drop_objection(this);
  endtask 

endclass
