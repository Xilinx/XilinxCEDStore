/* DESCRIPTION
 * This class configures the VIP as CXL RP and DUT as CXL EP (Type 3 device),
 * and instructs both to link up in CXL mode. The link should come up in
 * flit mode and the EP advertises 1 HDM range.
 * EXTENDS
 * base_cxl_ep_test
 * ACRONYMS
 * hdm = "host managed device memory"
 * fm  = "flit mode"
|*/

class base_cxl_ep_type3_hdm1_fm extends base_cxl_ep_test;

  `uvm_component_utils(base_cxl_ep_type3_hdm1_fm)

  // CXL-specific mailbox
  cseq_cxl_mbox cxl_mbox[0:1];

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (env_cfg == null) begin
      env_cfg = tb_env_cfg::type_id::create("env_cfg");
    end
    env_cfg.ps_isr_agnt = ACTIVE_AGNT; 
    env_cfg.pl_isr_agnt = UNUSED_AGNT; 
`ifdef CPM6_DUT_AGENTS_ONLY
    // All agents are set to passive by default
    env_cfg.axi_mst_agnt = '{default: ACTIVE_AGNT};
    env_cfg.axi_slv_agnt = '{default: ACTIVE_AGNT};
    for (int ii=0; ii<2; ii++) begin
      env_cfg.cxl_nfi_agnt_tx[ii]    = ACTIVE_AGNT;
      env_cfg.cxl_credit_agnt_tx[ii] = ACTIVE_AGNT;
    end
`endif
    // Put in cfg db
    uvm_config_db#(tb_env_cfg)::set(this, "env", "env_cfg", env_cfg);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    // Default : skip parsing all the DSP caps into the RP pdev
    env.shim.skip_dsp_caps = 1;
    // Configure DUT as EP
    for (int ii=0; ii<2; ii++) begin
      /********************************************************/
      /* ONLY APPLICABLE TO RTL SIMS USING BASE+APPENDED CDOs */
      /********************************************************/
      dut_cfg.pcie_cfg[ii].flit_mode_ctl  = 1'b1;
      dut_cfg.cxl_cfg[ii].cxl_device_type = 3;
      // PCIe DVSEC for CXL Devices (set 1 HDM range)
      dut_cfg.cxl_cfg[ii].dvsec_cxl_cap.cxl_cap.hdm_count = 1; 
      // CXL HDM Decoder Capability (via ELBI) ; offset at 0x200
      dut_cfg.cxl_cfg[ii].hdm_dec_cap.en = 1'b1;
      dut_cfg.cxl_cfg[ii].hdm_dec_cap.cap.decoder_cnt          = 0;     //1 Decoder
      dut_cfg.cxl_cfg[ii].hdm_dec_cap.cap.coherency_model_supp = 2'b10; //HDM-H
      dut_cfg.cxl_cfg[ii].hdm_dec_cap.decoder = new[1];
      // CXL EMD Capability (via ELBI) ; offset at 0x250 
      dut_cfg.cxl_cfg[ii].emd_cap.en = 1'b1;
      dut_cfg.cxl_cfg[ii].emd_cap.cap.max_nbits_emd = 32;
      /********************************************************/
    end
    // Rand the rest of the settings
    void'(this.randomize);
  endfunction

  virtual task pre_reset_phase(uvm_phase phase);
    cseq_core_cxl_decoder_commit cxl_dec_isr[0:1];
    super.pre_reset_phase(phase);
`ifdef CPM6_RTL
    // Set demux 
    demux_sel_vif.set_use_case(CXL);
`endif
    /* Set up PS interrupt sequences : MUST match attribute programming */
    // - Enabling logic to set "Committed" after "Commit" is set by host
    //   - Controller 0
    cxl_dec_isr[0] = cseq_core_cxl_decoder_commit::type_id::create("cxl_dec_isr[0]");
    cxl_dec_isr[0].reg_trigger = MERGED_0;
    cxl_dec_isr[0].set_ctrlr(0);
    env.ps_isr_seq.c_seq.push_back(cxl_dec_isr[0]);
    //   - Controller 1
    cxl_dec_isr[1] = cseq_core_cxl_decoder_commit::type_id::create("cxl_dec_isr[1]");
    cxl_dec_isr[1].reg_trigger = MERGED_0;
    cxl_dec_isr[1].set_ctrlr(1);
    env.ps_isr_seq.c_seq.push_back(cxl_dec_isr[1]);
    // - Creating mailbox handling
    //   - Controller 0
    cxl_mbox[0] = cseq_cxl_mbox::type_id::create("cxl_mbox[0]");
    cxl_mbox[0].set_ctrlr(0);
    cxl_mbox[0].set_trigger_mmio(CORR); 
    env.ps_isr_seq.c_seq.push_back(cxl_mbox[0]);
    //   - Controller 1
    cxl_mbox[1] = cseq_cxl_mbox::type_id::create("cxl_mbox[1]");
    cxl_mbox[1].set_ctrlr(1);
    cxl_mbox[1].set_trigger_mmio(CORR); 
    env.ps_isr_seq.c_seq.push_back(cxl_mbox[1]);
    /* Set up PL interrupt sequences */
    // -- None --
  endtask

endclass
