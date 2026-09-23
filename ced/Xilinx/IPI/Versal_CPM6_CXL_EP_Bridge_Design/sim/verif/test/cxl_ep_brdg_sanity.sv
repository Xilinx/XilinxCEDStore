// ===========================================================================
// cxl_ep_brdg_sanity.sv - Versal CPM6 CXL EP Bridge Design
//
// Project-specific sanity test. Extends base_cxl_ep_type3_hdm1_fm (sim/tb/
// test/base_cxl_ep_type3_hdm1_fm.sv, itself extending base_cxl_ep_test):
// configures VIP as CXL RP / DUT as CXL EP, Type 3, flit mode, 1 HDM range
// advertised via DVSEC, links up in CXL mode, checks negotiated speed.
//
// Base class choice (base_cxl_ep_type3_hdm1_fm, not the plain
// base_cxl_ep_test used previously): this design's ctrl1/
// design_1_bd.tcl (CTRL1 build) and ctrl0/design_1_bd.tcl (CTRL0
// build) both wire ctrl_reg_ep_0's single cxl_mem_base0 output to ALL
// FOUR PA hierarchies via one shared net (cxl_mem_base1 absent in either
// variant - confirmed identical topology in both) - i.e. the whole design
// decodes CXL.mem against ONE combined HDM range regardless of which
// controller is CXL-active, which is exactly "1 HDM range" semantics, not
// a per-PA range each needing its own decoder commit.
//
// After enumeration and the base class's CXL-mode/speed check
// (post_enum_seq(), inherited via base_cxl_ep_test), this test:
//   1. Programs ctrl_reg_ep's EP_BASE_0 with the CXL-negotiated HDM base
//      (cseq_cfg_ctrl_reg_ep, on env.ps_vip_vsqr) - required because this
//      design's PAs decode against that CSR-broadcast base, unlike a design
//      that relies purely on standard CXL HDM decoder hardware.
//   2. Runs a CXL.mem write/readback sanity check across 4 consecutive
//      cacheline-aligned addresses within that HDM range
//      (cxl_mem_wr_rd_4consec_seq, on env.shim.vsqr).
// ===========================================================================
class cxl_ep_brdg_sanity extends base_cxl_ep_type3_hdm1_fm;

  `uvm_component_utils(cxl_ep_brdg_sanity)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Trains the CXL link to a fixed, deterministic speed (matching whichever
  // Gen5/Gen6 protocol the DUT was built for) instead of the base class's
  // usual per-run randomized Gen3-Gen6 speed, so pass/fail is reproducible.
  // Override via +CTRLR0_SPEED=5 / +CTRLR1_SPEED=5 plusarg (default Gen6) -
  // manual/deliberate, nothing here derives it from the Vivado build choice.
  //
  // Both rand_mode and the value must be set BEFORE calling super - the base
  // class randomizes and locks cxl_link_speed[] on its own
  // end_of_elaboration_phase() before any subclass body runs. rp_sls is
  // forced too, not just cxl_link_speed - otherwise a Gen6-capable RP just
  // down-trains instead of genuinely linking up at Gen5.
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    int unsigned target_speed = 6;  // default: Gen6 / CXL_3_1
`ifdef CXL_BRDG_CTRL0
    void'($value$plusargs("CTRLR0_SPEED=%d", target_speed));
`else
    void'($value$plusargs("CTRLR1_SPEED=%d", target_speed));
`endif
    if (target_speed < 5 || target_speed > 6) begin
      `uvm_fatal(get_name(), $sformatf(
        "Illegal SPEED=%0d for cxl_ep_brdg_sanity; only 5 (Gen5/CXL_2_0) or 6 (Gen6/CXL_3_1) supported",
        target_speed))
    end
    rp_sls[CXL_ACTIVE_CTRL].rand_mode(0);
    rp_sls[CXL_ACTIVE_CTRL] = (target_speed == 5) ? pcie_config::GEN5 : pcie_config::GEN6;
    cxl_link_speed[CXL_ACTIVE_CTRL].rand_mode(0);
    cxl_link_speed[CXL_ACTIVE_CTRL] = target_speed[2:0];
    super.end_of_elaboration_phase(phase);
  endfunction

  // Clears app_req_retry_en immediately after CDO load completes, before
  // PERSTN/link training proceeds, so bus enumeration isn't held off with
  // Configuration Request Retry Status - see cseq_app_req_retry_en.sv.
  virtual task post_cdo_load();
    cseq_app_req_retry_en fix_seq;
    cseq_cxl_dvsec_next_cap fix_dvsec_seq;
    // Sets 3 interrupt-enable bits (PS_CORR_IR_ENABLE, MERGED_INTERRUPTS_0_
    // ENABLE, IR_ENABLE) that device firmware programs on real silicon -
    // see cseq_irq_enables.sv for details/addresses.
    cseq_irq_enables fix_irq_seq;
    // Programs CXL Extended Capability Header registers - see cseq_fix_cxl_hdm_dec_caps.sv.
    cseq_fix_cxl_hdm_dec_caps fix_hdm_dec_seq;
    super.post_cdo_load();
    fix_seq = cseq_app_req_retry_en::type_id::create("fix_seq");
    fix_seq.start(env.ps_vip_vsqr);
    fix_dvsec_seq = cseq_cxl_dvsec_next_cap::type_id::create("fix_dvsec_seq");
    fix_dvsec_seq.start(env.ps_vip_vsqr);
    fix_irq_seq = cseq_irq_enables::type_id::create("fix_irq_seq");
    fix_irq_seq.start(env.ps_vip_vsqr);
    fix_hdm_dec_seq = cseq_fix_cxl_hdm_dec_caps::type_id::create("fix_hdm_dec_seq");
    fix_hdm_dec_seq.start(env.ps_vip_vsqr);
  endtask

  // cxl_mbox[0]/[1] (base_cxl_ep_type3_hdm1_fm.pre_reset_phase()) are
  // virtual-firmware ELBI mailbox models whose mbox[] array must be
  // explicitly seeded via load_mmio_mbox() below - unseeded reads default to
  // 0, and the Mailbox Capabilities Register's PayloadSize field reading
  // back 0 fatals ("PayloadSize must be [8:20]") the first time bring-up
  // touches the mailbox, regardless of whether this test issues a mailbox
  // command itself.
  //
  // cxl_dev_reg_if_base ('h1_0000, PF0/BAR0) is this CXL core's fixed Device
  // Register Interface base, same across every sibling test - only
  // cxl_mbox[CXL_ACTIVE_CTRL] is seeded here since this design only uses one
  // controller at a time.

  // CXL.mem credit seed value used below (comfortably more than this
  // test's own 8 total CXL.mem transactions - 4 writes + 4 reads - ever
  // needs; see the credit-seeding block inside pre_reset_phase()).
  localparam int unsigned CXL_MEM_CREDIT_SEED = 100;

  // Which controller-indexed array slot is the CXL-active one for this
  // build: 0=Controller_0, 1=Controller_1 (confirmed via
  // base_cxl_ep_type3_hdm1_fm.sv's pre_reset_phase(), which does
  // `cxl_mbox[0].set_ctrlr(0)` / `cxl_mbox[1].set_ctrlr(1)`, and
  // tb_env_cfg.sv's do_print() labels). Every `cxl_mbox[...]`/
  // `cxl_link_speed[...]`/`env.cxl_nfi_agnt_rx[...]` OUTER index below must
  // use this, not a hardcoded controller number.
`ifdef CXL_BRDG_CTRL0
  localparam int unsigned CXL_ACTIVE_CTRL = 0;
`else
  localparam int unsigned CXL_ACTIVE_CTRL = 1;
`endif

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

    // cxl_nfi_monitor.sv's check_rcvd_have_credits() fatals if CXL.mem DAT
    // credits (shr.avl_dat_credit[1], MEM per cxl_nfi_other_pkg's prot_t)
    // are ever consumed while still 0. That counter is normally topped up by
    // an ACTIVE cxl_nfi_agnt_tx's init sequence, but this design's
    // setup_env_cfg.sv correctly leaves the active controller's nfi agents
    // PASSIVE (CXL.mem traffic here goes through env.shim.api.send_cxl_txn()
    // via the Avery VIP, not this agent pair), so that init sequence never
    // runs and the counter never becomes non-zero on its own - seed it
    // directly here instead. Inner [1] selects the MEM protocol entry
    // (cxl_nfi_other_pkg's `typedef enum bit {CCH, MEM} prot_t`).
    env.cxl_nfi_agnt_rx[CXL_ACTIVE_CTRL].shr.avl_dat_credit[1] = CXL_MEM_CREDIT_SEED;

    // The same PASSIVE-agent gap applies to the separate REQ credit pool:
    // cxl_nfi_monitor.sv's check_rcvd_have_credits() also tracks
    // shr.avl_req_credit[1] (MEM), decremented on every CXL.mem request
    // flit. It is never topped up for the same reason avl_dat_credit[1]
    // isn't (see comment above), so seed it directly here too.
    env.cxl_nfi_agnt_rx[CXL_ACTIVE_CTRL].shr.avl_req_credit[1] = CXL_MEM_CREDIT_SEED;

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
    cxl_mbox[CXL_ACTIVE_CTRL].load_mmio_mbox(0, 0, cxl_dev_reg_if_base, mbox, 'h3_FFFF);

    // Create mailbox capabilities for DSR (all zeroes - Event Status Register)
    mbox = new[2];
    cxl_mbox[CXL_ACTIVE_CTRL].load_mmio_mbox(0, 0, cxl_dev_sts_reg_base, mbox, 'h3_FFFF);

    // Create mailbox capabilities for PMBOXR
    mbox = new[72];
    // -> PMBOXR+0x0 : Mailbox Capabilities Register
    mbox[0] = (4'h1 << 19) | //Type
              (5'd8 <<  0);  //Payload Size (2**val) = 256B, valid [8:20]
    cxl_mbox[CXL_ACTIVE_CTRL].load_mmio_mbox(0, 0, cxl_prim_mbox_base, mbox, 'h3_FFFF);

    // Create mailbox capabilities for MDSR
    mbox = new[2];
    mbox[0] = (1'b1 << 4) | //Mailbox Interfaces Ready
              (2'h1 << 2);  //Media Status (Ready)
    cxl_mbox[CXL_ACTIVE_CTRL].load_mmio_mbox(0, 0, cxl_mem_dev_sts_reg_base, mbox, 'h3_FFFF);

    // Wire the Primary Mailbox Registers so cseq_cxl_mbox knows which
    // PF/BAR/offset to service, then register the command handlers it
    // must support.
    cxl_mbox[CXL_ACTIVE_CTRL].cxl_mbox_pf        = 0;
    cxl_mbox[CXL_ACTIVE_CTRL].cxl_mbox_bar       = 0;
    cxl_mbox[CXL_ACTIVE_CTRL].cxl_mbox_base_addr = cxl_prim_mbox_base;
    cxl_mbox[CXL_ACTIVE_CTRL].add_cmd_obj(cmd_0100h);
    cxl_mbox[CXL_ACTIVE_CTRL].add_cmd_obj(cmd_0101h);
    cxl_mbox[CXL_ACTIVE_CTRL].add_cmd_obj(cmd_0102h);
    cxl_mbox[CXL_ACTIVE_CTRL].add_cmd_obj(cmd_0103h);
    cxl_mbox[CXL_ACTIVE_CTRL].add_cmd_obj(cmd_0300h);
    cxl_mbox[CXL_ACTIVE_CTRL].add_cmd_obj(cmd_0301h);
    cxl_mbox[CXL_ACTIVE_CTRL].add_cmd_obj(cmd_0400h);
    cxl_mbox[CXL_ACTIVE_CTRL].add_cmd_obj(cmd_0401h);
    cmd_4000h.opayload.vol_only_cap = 1; //multiple of 256MB
    cmd_4000h.opayload.total_cap    = 1; //multiple of 256MB
    cxl_mbox[CXL_ACTIVE_CTRL].add_cmd_obj(cmd_4000h);
  endtask

  virtual task post_enum_seq();
    cseq_cfg_ctrl_reg_ep      cfg_reg_seq;
    cxl_mem_wr_rd_4consec_seq wr_rd_seq;
    pcie_device               ep_dev;

    super.post_enum_seq();

    // Make env visible to sequences that fetch it via config_db in
    // pre_body() (cxl_mem_wr_rd_4consec_seq) - mirrors this project's own
    // shim/tb_env plumbing pattern of publishing handles through config_db
    // rather than threading them through every sequence's constructor.
    uvm_config_db#(tb_env)::set(null, "base_sequence", "env", env);

    ep_dev = env.shim.container.get_pdev_EP();
    if (ep_dev == null)
      `uvm_fatal(get_type_name(), "Failed to get endpoint device handle after enumeration")

    // 1. Program ctrl_reg_ep's HDM base (broadcast to PA_0..PA_3) with the
    //    CXL-negotiated HDM base address.
    cfg_reg_seq = cseq_cfg_ctrl_reg_ep::type_id::create("cfg_reg_seq");
    cfg_reg_seq.hdm_base_addr = ep_dev.cxl_hdm[0].base;
    cfg_reg_seq.start(env.ps_vip_vsqr);

    // 2. CXL.mem write/readback sanity check across 4 consecutive addresses.
    wr_rd_seq = cxl_mem_wr_rd_4consec_seq::type_id::create("wr_rd_seq");
    wr_rd_seq.start(env.shim.vsqr);
  endtask

endclass
