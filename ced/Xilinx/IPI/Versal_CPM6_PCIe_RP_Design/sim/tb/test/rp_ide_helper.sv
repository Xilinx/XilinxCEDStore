//=============================================================================
// Counts the TLPs that actually go through the VIP's IDE engine (proof that traffic is secured):
// rx_pkt_before_decrypt fires for every IDE-protected TLP the VIP receives from the DUT,
// tx_pkt_after_encrypt for every TLP the VIP encrypts toward the DUT.
//=============================================================================
class ide_traffic_cb extends apci_callbacks;
  const string id = "IDE_TRAFFIC_CB";
  int unsigned dut_to_vip;      // protected TLPs received from the DUT
  int unsigned vip_to_dut;      // protected TLPs sent to the DUT
  int unsigned dut_to_vip_mem;  // ... of which memory requests (the RP's own traffic)
  int unsigned dut_to_vip_cpl;  // ... of which completions (answers to the Endpoint's requests)
  int unsigned vip_to_dut_cpl;  // ... of which completions
  int unsigned vip_to_dut_mem;  // ... of which memory requests (the Endpoint's own traffic)
  int unsigned samples;

  function new();
  endfunction

  virtual function void rx_pkt_before_decrypt(apci_device bfm, apci_tlp tlp);
    dut_to_vip++;
    if (tlp.kind inside {APCI_TLP_mrd, APCI_TLP_mwr}) dut_to_vip_mem++;
    if (tlp.kind inside {APCI_TLP_cpl, APCI_TLP_cpld}) dut_to_vip_cpl++;
    if (samples < 4) begin
      samples++;
      `uvm_info(id, $sformatf("IDE-protected TLP from the DUT: kind=%s", tlp.kind.name()), UVM_LOW)
    end
  endfunction

  virtual function void tx_pkt_after_encrypt(apci_device bfm, apci_tlp tlp);
    vip_to_dut++;
    if (tlp.kind inside {APCI_TLP_cpl, APCI_TLP_cpld}) vip_to_dut_cpl++;
    if (tlp.kind inside {APCI_TLP_mrd, APCI_TLP_mwr}) vip_to_dut_mem++;
  endfunction
endclass

//=============================================================================
// IDE bring-up for the Root Port CEDs (AXI_Bridge and PL_Streaming).
//
// Derived from test_ide_basic (the Endpoint CED test) with the roles swapped:
// the DUT is the Root Port and the VIP is the Endpoint.
//   - DUT (RP) IDE registers: written/read through the CPM6 DBI window over the
//     PS AXI (seq_rp_ide_dbi); the DUT IDE keys through seq_program_ide_key.
//   - VIP (EP) IDE registers: written by the RP, as the SEC firmware does: config accesses over the PS AXI
//     (ECAM for AXI_Bridge, the PL config bridge M00_AXI_0 for PL_Streaming). Keys: through the VIP key API.
// Only the backdoor (non-SPDM) flow of test_ide_basic is kept: keys are
// programmed on both sides directly, as the SEC firmware would after SPDM/IDE-KM.
//
// Plusargs: +IDE_LINK=<0|1> (default 1), +IDE_SEL=<0|1> (default 0).
//=============================================================================
class rp_ide_helper extends uvm_component;
  `uvm_component_utils(rp_ide_helper)

  localparam int NUM_SUBSTREAMS  = 3;   // PR, NPR, CPL
  localparam int NUM_DIRECTIONS  = 2;   // TX, RX
  localparam int NUM_KEY_SETS    = 2;   // K=0, K=1
  localparam int LINK_KEY_START  = 0;
  localparam int LINK_KEY_END    = 12;
  localparam int SEL_KEY_START   = 12;
  localparam int SEL_KEY_END     = 24;

  // Set while the RP's config traffic toward the EP is the bridge's (PL_Streaming): the PL streaming
  // scoreboards only know the RTL's ROM-driven enumeration traffic and ignore it meanwhile.
  static bit       bridge_cfg_active = 1'b0;
  // Set once the IDE test is running: the VIP-side TLP taps see protected payloads, so the PL streaming
  // scoreboards stop comparing payload data (the RTL checkers still do).
  static bit       ide_active        = 1'b0;

  tb_env           env;
  bit              ctrlr;                 // controller the RP DUT uses
  bit [15:0]       ep_bdf;                // VIP Endpoint
  bit [47:0]       ep_cfg_addr;           // PS AXI address of the EP's config space (ECAM base + bdf<<12)
  ps_route_mst_e   ep_cfg_mst = PS_CPM_CFG; // PS VIP route toward it
  bit              rp_first;              // RP to Secure first, then ONE unencrypted enable to the EP (PL_Streaming)
  bit              use_selective;         // default stream: Selective IDE (does not cover config requests) instead of Link IDE
  bit              vip_force_secure;      // mark the VIP's stream Secure as soon as both sides are enabled
  int              sel_shift[2];          // Selective block DW offset vs ecap_ide's (1 Link TC) layout, per device [0]=RP [1]=EP
  bit [11:0]       ep_ide_base;           // EP IDE extended capability offset (found by walking the list)
  bit [11:0]       rp_ide_base = 12'hCB0; // RP IDE extended capability offset (rp_top IDE_CAP_OFFSET)

  ide_stream_cfg   link_ide_cfg;
  ide_stream_cfg   sel_ide_cfg;
  ecap_ide         ide_ecap;
  ide_fail_cb      ide_fail_callback;
  ide_traffic_cb   traffic_cb;
  apci_ide_key_iv_t ide_key[24];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    link_ide_cfg = new();
    sel_ide_cfg  = new();
    ide_ecap     = ecap_ide::type_id::create("ide_ecap");
    init_ide_keys();
  endfunction

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

  // Stream selection: Link IDE by default, Selective IDE on request
  function void configure_streams();
    bit en;
    link_ide_cfg.enable    = !use_selective;
    link_ide_cfg.stream_id = 8'h01;
    sel_ide_cfg.enable     = use_selective;
    sel_ide_cfg.stream_id  = 8'h02;
    sel_ide_cfg.rid_valid  = 1'b1;
    sel_ide_cfg.rid_base   = 16'h0000;
    sel_ide_cfg.rid_limit  = 16'hFFFF;
    sel_ide_cfg.addr_valid[0] = 1'b1;
    sel_ide_cfg.addr_base[0]  = 64'h0;
    sel_ide_cfg.addr_limit[0] = 64'hFFFF_FFFF_FFFF_FFFF;
    if ($value$plusargs("IDE_LINK=%b", en)) link_ide_cfg.enable = en;
    if ($value$plusargs("IDE_SEL=%b",  en)) sel_ide_cfg.enable  = en;
  endfunction

  // The env only creates ps_sem when its PS ISR agent is active (the Endpoint tests); the RP
  // tests have no ISR sequence to arbitrate with, so a private semaphore will do.
  semaphore local_sem;
  function semaphore get_ps_sem();
    if (env.ps_sem != null) return env.ps_sem;
    if (local_sem == null) local_sem = new(1);
    return local_sem;
  endfunction

  function string ide_substream_name(apci_ide_sub_stream_e substream);
    case (substream)
      APCI_IDE_SUB_STREAM_post_req     : return "PR";
      APCI_IDE_SUB_STREAM_non_post_req : return "NPR";
      APCI_IDE_SUB_STREAM_cpl          : return "CPL";
      default                          : return "UNK";
    endcase
  endfunction

  //===========================================================================
  // RP (DUT) register access: DBI window over the PS AXI
  //===========================================================================
  // ecap_ide's Selective register DWs assume 1 Link TC (Selective block at DW 5); the block really starts
  // after the Link blocks: DW 3 + 2 * (Link TCs), or DW 3 when Link IDE is not supported
  function int sel_dw(bit ep, int dw_offset);
    return (dw_offset >= ecap_ide::DW_SEL_CAP) ? dw_offset + sel_shift[ep] : dw_offset;
  endfunction

  function bit [47:0] ide_reg_addr(bit ep, int dw_offset);
    int dw = sel_dw(ep, dw_offset);
    if (ep) return ep_cfg_addr + ep_ide_base + dw * 4;
    return (ctrlr ? 48'hFC40_0000 : 48'hFC00_0000) + rp_ide_base + dw * 4;
  endfunction

  task ps_access(bit wr, bit [47:0] addr, ps_route_mst_e mst, ref bit [31:0] data);
    seq_rp_ide_dbi s = seq_rp_ide_dbi::type_id::create("rp_ide_dbi");
    semaphore sem;
    s.wr         = wr;
    s.addr       = addr;
    s.data       = data;
    s.ps_vip_mst = mst;
    sem = get_ps_sem();
    sem.get(1);
    s.start(env.ps_vip_vsqr);
    sem.put(1);
    data = s.data;
  endtask

  // ep=0: the RP's own IDE capability (DBI); ep=1: the Endpoint's (config access through the RP)
  task write_ide_reg(bit ep, int dw_offset, bit [31:0] data);
    ps_access(1'b1, ide_reg_addr(ep, dw_offset), ep ? ep_cfg_mst : PS_CPM_CFG, data);
  endtask

  task read_ide_reg(bit ep, int dw_offset, output bit [31:0] data);
    data = '0;
    ps_access(1'b0, ide_reg_addr(ep, dw_offset), ep ? ep_cfg_mst : PS_CPM_CFG, data);
  endtask

  // Walk the EP extended capability list (from 0x100) for the IDE capability (ID 0x30)
  task find_ep_ide_cap();
    bit [31:0] hdr;
    bit [11:0] off = 12'h100;
    for (int n = 0; n < 64; n++) begin
      hdr = '0;
      ps_access(1'b0, ep_cfg_addr + off, ep_cfg_mst, hdr);
      `uvm_info(get_type_name, $sformatf("EP ext cap @0x%03h (addr 0x%012h): header 0x%08h", off, ep_cfg_addr + off, hdr), UVM_LOW)
      if (hdr[15:0] == 16'h0030) begin
        ep_ide_base = off;
        `uvm_info(get_type_name, $sformatf("EP IDE capability at config offset 0x%03h", off), UVM_LOW)
        return;
      end
      off = hdr[31:20];
      if (off == 0) break;
    end
    `uvm_fatal(get_type_name, "The Endpoint has no IDE extended capability")
  endtask

  //===========================================================================
  // Stream configuration (enable=0), from ide_stream_cfg, on the RP (ep=0) or the Endpoint (ep=1)
  //===========================================================================
  task configure_stream(bit ep, bit is_link_ide);
    if (is_link_ide) begin
      ide_ecap.configure_link_from_cfg(
        .stream_id(link_ide_cfg.stream_id), .tc(link_ide_cfg.tc),
        .pcrc_en(link_ide_cfg.pcrc_enable),
        .partial_header_enc_mode(link_ide_cfg.partial_header_encryption_mode),
        .enable(1'b0));
      write_ide_reg(ep, ecap_ide::DW_LINK_CTRL, ide_ecap.get_dw(ecap_ide::DW_LINK_CTRL));
    end else begin
      ide_ecap.configure_sel_from_cfg(
        .stream_id(sel_ide_cfg.stream_id), .tc(sel_ide_cfg.tc),
        .pcrc_en(sel_ide_cfg.pcrc_enable),
        .partial_header_enc_mode(sel_ide_cfg.partial_header_encryption_mode),
        .default_stream(sel_ide_cfg.default_stream),
        .sel_ide_for_cfg_req(sel_ide_cfg.for_configuration_requests),
        .enable(1'b0),
        .rid_base(sel_ide_cfg.rid_base), .rid_limit(sel_ide_cfg.rid_limit),
        .rid_valid(sel_ide_cfg.rid_valid));
      for (int i = 0; i < 2; i++)
        ide_ecap.set_addr_assoc(i, sel_ide_cfg.addr_base[i], sel_ide_cfg.addr_limit[i], sel_ide_cfg.addr_valid[i]);
      write_ide_reg(ep, ecap_ide::DW_SEL_CTRL,       ide_ecap.get_dw(ecap_ide::DW_SEL_CTRL));
      write_ide_reg(ep, ecap_ide::DW_SEL_RID_ASSOC1, ide_ecap.get_dw(ecap_ide::DW_SEL_RID_ASSOC1));
      write_ide_reg(ep, ecap_ide::DW_SEL_RID_ASSOC2, ide_ecap.get_dw(ecap_ide::DW_SEL_RID_ASSOC2));
      for (int i = 0; i < 2; i++) begin
        int dw_offset = ide_ecap.get_addr_assoc_dw_offset(i);
        write_ide_reg(ep, dw_offset,     ide_ecap.get_dw(dw_offset));
        write_ide_reg(ep, dw_offset + 1, ide_ecap.get_dw(dw_offset + 1));
        write_ide_reg(ep, dw_offset + 2, ide_ecap.get_dw(dw_offset + 2));
      end
    end
  endtask

  // Set the stream's enable bit
  task enable_stream(bit ep, bit is_link_ide);
    int ctrl_dw = is_link_ide ? ecap_ide::DW_LINK_CTRL : ecap_ide::DW_SEL_CTRL;
    ide_stream_cfg cfg = is_link_ide ? link_ide_cfg : sel_ide_cfg;
    logic [31:0] ctrl_val;
    if (is_link_ide)
      ctrl_val = ide_ecap.build_link_ctrl(cfg.stream_id, cfg.tc, cfg.pcrc_enable, 1'b1);
    else
      ctrl_val = ide_ecap.build_sel_ctrl(cfg.stream_id, cfg.tc, cfg.partial_header_encryption_mode,
                                         cfg.for_configuration_requests, cfg.default_stream,
                                         cfg.pcrc_enable, 1'b1);
    write_ide_reg(ep, ctrl_dw, ctrl_val);
    begin
      bit [31:0] rb;
      read_ide_reg(ep, ctrl_dw, rb);
      `uvm_info(get_type_name, $sformatf("%s IDE %s control: wrote 0x%08h, read back 0x%08h", ep ? "EP" : "RP", is_link_ide ? "Link" : "Selective", ctrl_val, rb), UVM_LOW)
    end
  endtask

  // Wait for the stream to report Secure (state [3:0] == 2)
  task wait_stream_secure(bit ep, bit is_link_ide);
    bit [31:0] status;
    int status_dw = is_link_ide ? ecap_ide::DW_LINK_STATUS : ecap_ide::DW_SEL_STATUS;
    do begin
      read_ide_reg(ep, status_dw, status);
      `uvm_info(get_type_name, $sformatf("%s IDE %s status = %0h", ep ? "EP" : "RP", is_link_ide ? "Link" : "Selective", status), UVM_LOW)
      #(1us);
    end while (status[3:0] != 4'h2);
  endtask

  //===========================================================================
  // Keys: VIP (EP) through the VIP API, DUT (RP) through seq_program_ide_key
  //===========================================================================
  task set_vip_ide_keys(bit [7:0] stream_id, int key_start);
    apci_ide_sub_stream_e substreams[3] = '{
      APCI_IDE_SUB_STREAM_post_req, APCI_IDE_SUB_STREAM_non_post_req, APCI_IDE_SUB_STREAM_cpl};
    int key_idx = key_start;
    for (int k = 0; k < NUM_KEY_SETS; k++)
      for (int dir = 0; dir < NUM_DIRECTIONS; dir++)
        for (int ss = 0; ss < NUM_SUBSTREAMS; ss++) begin
          env.shim.vip.port_set_ide_key(0, stream_id, substreams[ss], (dir == 0), k, ide_key[key_idx]);
          `uvm_info(get_type_name, $sformatf("VIP IDE key stream=%0d substream=%s dir=%s k=%0d key_idx=%0d",
                    stream_id, ide_substream_name(substreams[ss]), (dir == 0) ? "TX" : "RX", k, key_idx), UVM_LOW)
          key_idx++;
        end
  endtask

  task prg_ide_keys(int idx_offset, int key_start, int key_end);
    seq_program_ide_key ide_seq = seq_program_ide_key::type_id::create("ide_prg_seq");
    semaphore sem = get_ps_sem();
    ide_seq.ctrlr = ctrlr;
    sem.get(1);
    for (int i = key_start; i < key_end; i++) begin
      bit rp_rx_key = (i / 3) % 2;
      bit is_k      = (i / 6) % 2;
      // Slot map: Selective K0 -> 0,1,2   Link K0 -> 3,4,5   Selective K1 -> 6,7,8   Link K1 -> 9,10,11
      int idx       = (i % 3) + idx_offset + (is_k * 6);
      `uvm_info(get_type_name, $sformatf("DUT IDE key index=%0d dir=%s k=%0d hw_idx=%0d",
                i, rp_rx_key ? "TX" : "RX", is_k, idx), UVM_LOW)
      ide_seq.index   = idx;
      ide_seq.tx      = rp_rx_key;
      ide_seq.ide_key = ide_key[i];
      ide_seq.start(env.ps_vip_vsqr);
    end
    sem.put(1);
  endtask

  //===========================================================================
  // One stream: keys on both sides, then enable the RP and the Endpoint
  //===========================================================================
  task enable_ide_stream(bit is_link_ide);
    ide_stream_cfg cfg = is_link_ide ? link_ide_cfg : sel_ide_cfg;

    set_vip_ide_keys(cfg.stream_id, is_link_ide ? LINK_KEY_START : SEL_KEY_START);
    configure_stream(1'b0, is_link_ide);   // RP
    configure_stream(1'b1, is_link_ide);   // Endpoint

    if (is_link_ide) prg_ide_keys(3, LINK_KEY_START, LINK_KEY_END);
    else             prg_ide_keys(0, SEL_KEY_START,  SEL_KEY_END);

    if (rp_first) begin
      // RP to Secure first, then ONE enable write to the Endpoint, which goes out unencrypted: a Selective
      // IDE stream does not cover configuration requests
      enable_stream(1'b0, is_link_ide);
      wait_stream_secure(1'b0, is_link_ide);
      enable_stream(1'b1, is_link_ide);
      if (vip_force_secure) env.shim.vip.port_set(0, "ide_stream_secure_state", cfg.stream_id, 1);
      wait_stream_secure(1'b1, is_link_ide);
    end else begin
      // The RP writes the Endpoint's registers: enable the Endpoint first, while the config writes still go
      // out in the clear, then the RP
      enable_stream(1'b1, is_link_ide);
      enable_stream(1'b0, is_link_ide);
      if (vip_force_secure) env.shim.vip.port_set(0, "ide_stream_secure_state", cfg.stream_id, 1);
      wait_stream_secure(1'b0, is_link_ide);
      wait_stream_secure(1'b1, is_link_ide);
    end
  endtask

  //===========================================================================
  // Entry point: call once the link is up (and, for AXI_Bridge, enumerated)
  //===========================================================================
  task run_ide_bringup();
    bit [31:0] hdr;

    // The RP IDE extended capability must be where rp_top expects it (ID 0x30 at rp_ide_base)
    read_ide_reg(1'b0, ecap_ide::DW_HDR, hdr);
    if (hdr[15:0] != 16'h0030)
      `uvm_fatal(get_type_name, $sformatf("No IDE extended capability at RP config offset 0x%03h (header 0x%08h) - is IDE enabled in the DUT?", rp_ide_base, hdr))

    ide_active        = 1'b1;
    bridge_cfg_active = (ep_cfg_mst != PS_CPM_CFG);
    find_ep_ide_cap();
    begin
      bit [31:0] cap;
      read_ide_reg(1'b0, ecap_ide::DW_CAP, cap);
      sel_shift[0] = (cap[0] ? 3 + 2*(cap[15:13] + 1) : 3) - ecap_ide::DW_SEL_CAP;
      `uvm_info(get_type_name, $sformatf("RP IDE capability register = 0x%08h (link=%0b selective=%0b, link TCs-1=%0d, selective streams-1=%0d)",
                cap, cap[0], cap[1], cap[15:13], cap[23:16]), UVM_LOW)
      read_ide_reg(1'b1, ecap_ide::DW_CAP, cap);
      sel_shift[1] = (cap[0] ? 3 + 2*(cap[15:13] + 1) : 3) - ecap_ide::DW_SEL_CAP;
      `uvm_info(get_type_name, $sformatf("EP IDE capability register = 0x%08h (link=%0b selective=%0b, link TCs-1=%0d, selective streams-1=%0d)",
                cap, cap[0], cap[1], cap[15:13], cap[23:16]), UVM_LOW)
    end
    configure_streams();

    ide_fail_callback = new();
    env.shim.vip.append_callback(ide_fail_callback);
    traffic_cb = new();
    env.shim.vip.append_callback(traffic_cb);

    if (link_ide_cfg.enable) enable_ide_stream(1'b1);
    if (sel_ide_cfg.enable)  enable_ide_stream(1'b0);
    #5us;
    bridge_cfg_active = 1'b0;
    `uvm_info(get_type_name, "IDE bring-up complete", UVM_LOW)
  endtask


  // Call from the test's report_phase: the traffic of the base test, run after IDE comes up, must really
  // have been secured.
  //   PL_Streaming (the RTL's traffic generator): protected memory requests RP->EP and completions EP->RP.
  //   AXI_Bridge (test_ps_transactions): the Endpoint's inbound accesses are answered by the RP, so the
  //   RP's completions must be protected (min_cpl = the number of reads).
  function void check_ide_traffic(bit rp_issues_requests, int unsigned min_cpl = 1, int unsigned min_ep_req = 0);
    `uvm_info(get_type_name, $sformatf("IDE traffic: %0d protected TLPs DUT->VIP (%0d memory requests, %0d completions), %0d VIP->DUT (%0d completions)",
              traffic_cb.dut_to_vip, traffic_cb.dut_to_vip_mem, traffic_cb.dut_to_vip_cpl, traffic_cb.vip_to_dut, traffic_cb.vip_to_dut_cpl), UVM_NONE)
    `uvm_info(get_type_name, $sformatf("IDE traffic: %0d of the VIP->DUT protected TLPs are memory requests", traffic_cb.vip_to_dut_mem), UVM_NONE)
    if (rp_issues_requests) begin
      if (traffic_cb.dut_to_vip_mem == 0)
        `uvm_error(get_type_name, "No IDE-protected memory request went from the RP to the Endpoint: the traffic is not secured")
      if (traffic_cb.vip_to_dut_cpl == 0)
        `uvm_error(get_type_name, "No IDE-protected completion went from the Endpoint to the RP: the traffic is not secured")
    end else begin
      if (traffic_cb.dut_to_vip_cpl < min_cpl)
        `uvm_error(get_type_name, $sformatf("Only %0d IDE-protected completions went from the RP to the Endpoint (expected at least %0d): the traffic is not secured",
                   traffic_cb.dut_to_vip_cpl, min_cpl))
      if (traffic_cb.vip_to_dut_mem < min_ep_req)
        `uvm_error(get_type_name, $sformatf("Only %0d IDE-protected memory requests went from the Endpoint to the RP (expected at least %0d): the traffic is not secured",
                   traffic_cb.vip_to_dut_mem, min_ep_req))
    end
  endfunction

endclass
