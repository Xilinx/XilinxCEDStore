// test_qdma_h2c_c2h_mm_Mfnc_MQ -- multi-queue H2C+C2H MM DMA test, PF and VF.
// Default mode is POLL (+IRQ_EN=0): no MSI-X required, completion is
// bytes+writeback only. Pass +IRQ_EN=1 for interrupt mode.
// VF support (+NUM_VF_TEST) -- see qdma_base_test.sv's
// TSK_QDMA_VF_H2C_MM_TEST/TSK_QDMA_VF_C2H_MM_TEST.
class test_qdma_h2c_c2h_mm_Mfnc_MQ extends qdma_base_test;

  `uvm_component_utils(test_qdma_h2c_c2h_mm_Mfnc_MQ)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  qdma_mem_callback  host_mem_cb;
  int NUM_Q_TEST;
  int NUM_PF_TEST;
  int NUM_VF_TEST;

  integer num_qid_in_test;
  logic   irq_en;       // MSI-X enable: 1=enable interrupts, 0=suppress; overridden by +IRQ_EN=<0|1>
  string  direction;    // DMA direction: "BOTH" (default), "H2C", or "C2H"; overridden by +DIRECTION=

  time DMA_TIMEOUT = 200us;

  // Randomizable knobs -- overridden by plusargs when provided
  rand int unsigned r_num_pf;
  rand int unsigned r_num_vf;
  rand int unsigned r_num_q;
  rand int unsigned r_pidx;
  rand int unsigned r_dma_byte_cnt;

  // NUM_PF_TEST: 1..NUM_PF (design max from params pkg)
  constraint c_num_pf {
    r_num_pf inside {[1 : NUM_PF]};
  }
  // NUM_VF_TEST: 0..NUM_VF (0 = VF path skipped)
  constraint c_num_vf {
    r_num_vf inside {[0 : NUM_VF]};
  }
  // NUM_Q_TEST: 1..QUEUE_PER_PF
  constraint c_num_q {
    r_num_q inside {[1 : QUEUE_PER_PF]};
  }
  // pidx: 1..100 (hard limit -- applies to explicit +PIDX plusargs too)
  constraint c_pidx {
    r_pidx inside {[1 : 100]};
  }
  // DMA_BYTE_CNT: multiple of 64 bytes, bounded by the PL BRAM aperture
  // (get_dma_slot() divides PL_BRAM_APERTURE_SIZE by this value; anything
  // larger drives num_slots to 0, a division by zero).
  constraint c_dma_byte_cnt {
    r_dma_byte_cnt inside {[64 : PL_BRAM_APERTURE_SIZE]};
    r_dma_byte_cnt % 64 == 0;
  }

  virtual function void build_phase(uvm_phase phase);
    phase.raise_objection(this);
      super.build_phase(phase);
      // AXI-PL0 + AXI-PL1 by default; +NUM_DMA_PORTS=N overrides.
      if (!$value$plusargs("NUM_DMA_PORTS=%0d", num_dma_ports))
        num_dma_ports = 2;
    phase.drop_objection(this);
  endfunction

  // seq_enum's default enum_timeout (250us, uvma-pcie-sim-framework/cpm6/common/
  // test/seq/seq_enum.sv) is not enough once VFs are enumerated on this CED --
  // measured: 1PF+8VF enumeration runs at ~15.4us/VF, needing ~330-350us total
  // on this CED's link config. Override via pre_enum_seq(), outside the shared
  // framework file, rather than editing seq_enum.sv directly.
  virtual task pre_enum_seq();
    bus_enum.enum_timeout = 500us;
  endtask

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    for (int ii=0; ii<2; ii++) begin
      if (vip_cfg.ctrlr_en[ii]) begin
        vip_cfg.port_ctl[ii] = generic_config::PCIE;
        vip_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::RP;
        vip_cfg.pcie_cfg[ii].flit_mode_ctl = 1'b1;
      end
      if (dut_cfg.ctrlr_en[ii]) begin
        dut_cfg.base_cdo     = "cpm6_qdma_sim_text.cdo";
        dut_cfg.use_case[ii] = dut_config::PCIE_DMA;
        dut_cfg.port_ctl[ii] = generic_config::PCIE;
        dut_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::EP;
        dut_cfg.pcie_cfg[ii].flit_mode_ctl  = 1'b1;
      end
    end
    env.shim.vip.set("bus_enum_ari_forwarding", 1);
    use_vf_enum = 1; // signal start_of_simulation_phase to set bus_enum_skip_vf_enable=0 after setup_vip_defaults
  endfunction

  // vip_cfg.randomize() (test_base.sv's start_of_simulation_phase, via
  // super() below) drives vip.cfg_info's randomized capability-support
  // fields. Overrides here run AFTER super() so they are the last word
  // before configure_phase starts PCIe enumeration -- setting them earlier
  // (e.g. end_of_elaboration_phase) gets clobbered by setup_vip_defaults().
  //
  // DUT-specific capability facts belong in the test class, not
  // shim_layer.sv (shared VIP-setup infrastructure).
  //
  // Fields pinned to 0: the DUT's extended-capability chain (AER, Power
  // Budgeting, ARI, Secondary PCIe, PHY-speed, SR-IOV) never advertises
  // ATS/DSN/RC Link Declaration/RC Internal Link Control/MFVC/Multicast/
  // L1 PM Substates, so RP-side "support" for them is dead coverage space.
  // power_budget_sup is left randomized (Power Budgeting IS in the DUT's
  // chain). tx_loopbk_eq/link_err_to_recovery/use_sw_bar are Avery RP-model
  // behavioral toggles, not DUT-advertised capabilities.
  //
  // rand_mode(0) on the whole object (called before super()) additionally
  // blocks randomization of any field not explicitly listed. It only
  // prevents re-randomization from this point forward -- if cfg_info's
  // initial draw happens earlier (e.g. in vip's own build/connect_phase),
  // this cannot undo it. The explicit assignments below remain the actual
  // override mechanism.
  virtual function void start_of_simulation_phase(uvm_phase phase);
    env.shim.vip.cfg_info.rand_mode(0);
    super.start_of_simulation_phase(phase);
    env.shim.vip.cfg_info.ATS_sup              = 0;
    env.shim.vip.cfg_info.dsn_sup              = 0;
    env.shim.vip.cfg_info.rc_link_declar_sup   = 0;
    env.shim.vip.cfg_info.rc_int_link_ctrl_sup = 0;
    env.shim.vip.cfg_info.mfvc_sup             = 0;
    env.shim.vip.cfg_info.mc_sup               = 0;
    env.shim.vip.cfg_info.l1_pm_substates_sup  = 0;
    env.shim.vip.cfg_info.tx_loopbk_eq         = 0;
    env.shim.vip.cfg_info.link_err_to_recovery = 0;
    env.shim.vip.cfg_info.use_sw_bar           = 0;
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    phase.raise_objection(this);
    host_mem_cb = new(env.shim.vip, this);
    `uvm_info("QDMA_MEM_CALLBACK", $sformatf("Appending callback to host memory"), UVM_NONE)
    env.shim.vip.append_callback(host_mem_cb);
    phase.drop_objection(this);
  endfunction

  virtual task main_phase(uvm_phase phase);
    bit [10:0] qid;
    bit [7:0]  fnc;
    super.main_phase(phase);
    phase.raise_objection(this);

      // +NUM_PF_TEST=<0..NUM_PF>  (0 disables the PF loop)
      // +NUM_VF_TEST=<0..NUM_VF>  (0 or omitted disables the VF loop)
      // +NUM_Q_TEST=<1..QUEUE_PER_PF>
      // +PIDX=<1..256>
      // +DMA_BYTE_CNT=<multiple of 64, 64..PL_BRAM_APERTURE_SIZE>
      // +IRQ_EN=<0|1>       (default=0)
      // +DIRECTION=<BOTH|H2C|C2H>  (default=BOTH)
      // +NUM_DMA_PORTS=<1..4>  (default=2)
      begin
        int parg_num_pf, parg_num_vf, parg_num_q, parg_pidx, parg_dma_byte_cnt, parg_irq_en;
        parg_num_pf       = 0;
        parg_num_vf       = 0;
        parg_num_q        = 0;
        parg_pidx         = 0;
        parg_dma_byte_cnt = 0;
        parg_irq_en       = 0;
        direction         = "BOTH";
        void'($value$plusargs("NUM_PF_TEST=%0d",   parg_num_pf));
        void'($value$plusargs("NUM_VF_TEST=%0d",   parg_num_vf));
        void'($value$plusargs("NUM_Q_TEST=%0d",    parg_num_q));
        void'($value$plusargs("PIDX=%0d",          parg_pidx));
        void'($value$plusargs("DMA_BYTE_CNT=%0d",  parg_dma_byte_cnt));
        void'($value$plusargs("IRQ_EN=%0d",        parg_irq_en));
        void'($value$plusargs("DIRECTION=%s",      direction));
        irq_en = logic'(parg_irq_en);

        if (direction != "BOTH" && direction != "H2C" && direction != "C2H")
          `uvm_fatal("test_qdma_h2c_c2h_mm_Mfnc_MQ",
            $sformatf("+DIRECTION=%s invalid; must be BOTH, H2C, or C2H", direction))

        // Default (no plusarg) randomization is capped to a small range so an
        // unconstrained run can't drive an unbounded number/size of DMA
        // transfers -- NUM_Q_TEST=21 x PIDX=51 x DMA_BYTE_CNT=14208 (all
        // random) produced a single queue needing ~1.18ms and
        // 8255 TLPs just to complete, and other queues never even started.
        // An explicit +NUM_Q_TEST/+PIDX/+DMA_BYTE_CNT plusarg is NOT capped
        // by these and can still use the full c_num_q/c_pidx/c_dma_byte_cnt
        // range above. NUM_VF_TEST has no "no plusarg" random range -- unlike
        // PF, omitting +NUM_VF_TEST means VF-off (0), not a random VF count.
        if (!randomize(r_num_pf, r_num_vf, r_num_q, r_pidx, r_dma_byte_cnt) with {
              (parg_num_pf       > 0) -> r_num_pf       == parg_num_pf;
              r_num_vf == parg_num_vf;
              (parg_num_q        > 0) -> r_num_q        == parg_num_q;
              (parg_pidx         > 0) -> r_pidx         == parg_pidx;
              (parg_dma_byte_cnt > 0) -> r_dma_byte_cnt == parg_dma_byte_cnt;
              (parg_num_q        == 0) -> r_num_q        inside {[1  : 4]};
              (parg_pidx         == 0) -> r_pidx         inside {[1  : 50]};
              (parg_dma_byte_cnt == 0) -> r_dma_byte_cnt  inside {[64 : 4096]};
            })
          `uvm_fatal("test_qdma_h2c_c2h_mm_Mfnc_MQ", "randomize() failed  -  check plusarg values against constraints")

        NUM_PF_TEST  = r_num_pf;
        NUM_VF_TEST  = r_num_vf;
        NUM_Q_TEST   = r_num_q;
        pidx         = r_pidx[15:0];
        DMA_BYTE_CNT = r_dma_byte_cnt;

        // Constraint above is [1:NUM_PF]; +NUM_PF_TEST=0 cannot randomize to
        // 0, so apply the override post-randomize.
        begin
          int tmp;
          if ($value$plusargs("NUM_PF_TEST=%0d", tmp) && tmp == 0)
            NUM_PF_TEST = 0;
        end
      end

      num_qid_in_test = (NUM_PF_TEST + NUM_VF_TEST) * NUM_Q_TEST * ((direction == "BOTH") ? 2 : 1);
      dma_req_proc.qid_in_test  = num_qid_in_test;
      dma_req_proc.pidx         = pidx;
      dma_req_proc.DMA_BYTE_CNT = DMA_BYTE_CNT;

      `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", $sformatf("/****************/"), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", $sformatf("  Test Variables  "), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", $sformatf("/****************/"), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", $sformatf("NUM_PF_TEST   : %0d  %s", NUM_PF_TEST,  ($test$plusargs("NUM_PF_TEST")  ? "(plusarg)" : "(random)")), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", $sformatf("NUM_VF_TEST   : %0d  %s", NUM_VF_TEST,  ($test$plusargs("NUM_VF_TEST")  ? "(plusarg)" : "(default=0)")), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", $sformatf("NUM_Q_TEST    : %0d  %s", NUM_Q_TEST,   ($test$plusargs("NUM_Q_TEST")   ? "(plusarg)" : "(random)")), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", $sformatf("pidx          : %0d  %s", pidx,         ($test$plusargs("PIDX")         ? "(plusarg)" : "(random)")), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", $sformatf("DMA_BYTE_CNT  : %0d  %s", DMA_BYTE_CNT, ($test$plusargs("DMA_BYTE_CNT") ? "(plusarg)" : "(random)")), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", $sformatf("irq_en        : %0d  %s", irq_en,       ($test$plusargs("IRQ_EN")       ? "(plusarg)" : "(default=0)")), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ",
        $sformatf("TEST MODE     : %s  (set via +IRQ_EN=<0|1>)", irq_en ? "INTERRUPT" : "POLL"), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", $sformatf("direction     : %s  %s", direction,    ($test$plusargs("DIRECTION")    ? "(plusarg)" : "(default=BOTH)")), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", $sformatf("num_qid_in_test   : %0d",     num_qid_in_test), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", $sformatf("/****************/"), UVM_NONE)

      `uvm_info("TEST_IDENTITY", $sformatf(
        "contexts=%s pf=%0d vf=%0d q=%0d pidx=%0d dma_byte_cnt=%0d expect_cmp=%0d irq=%0d",
        direction, NUM_PF_TEST, NUM_VF_TEST, NUM_Q_TEST, pidx, DMA_BYTE_CNT, num_qid_in_test, irq_en), UVM_NONE)

      if (NUM_PF_TEST > 0) begin
        qid = 11'h1;
        fnc = 8'h0;
        for (int i = 0; i < NUM_PF_TEST; i++) begin
          pf_fnc = 4'(i);
          for (int j = 0; j < NUM_Q_TEST; j++) begin
            `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", $sformatf("Testing qid#%0d with PF function %0d direction=%s", qid+j, pf_fnc, direction), UVM_NONE)
            if (direction != "C2H")
              TSK_QDMA_MM_H2C_TEST(qid+j, 1'b0, irq_en);
            if (direction != "H2C")
              TSK_QDMA_MM_C2H_TEST(qid+j, 1'b0, irq_en);
          end
        end
      end

      // Test VFs (+NUM_VF_TEST=0 or omitted skips this block entirely: PF-only mode)
      if (NUM_VF_TEST > 0) begin
        qid = 11'h1;
        fnc = 8'(VF_OFFSET);
        for (int i = 0; i < NUM_VF_TEST; i++) begin
          for (int j = 0; j < NUM_Q_TEST; j++) begin
            `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", $sformatf("Testing qid#%0d with VF function %0d direction=%s", qid+j, fnc+i, direction), UVM_NONE)
            if (direction != "C2H") TSK_QDMA_VF_H2C_MM_TEST(fnc+i, qid+j, irq_en);
            if (direction != "H2C") TSK_QDMA_VF_C2H_MM_TEST(fnc+i, qid+j, irq_en);
          end
        end
      end

      `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", "Waiting for all DMA transfers to complete...", UVM_NONE)
      fork
        begin
          dma_req_proc.done_ev.wait_trigger();
          `uvm_info("test_qdma_h2c_c2h_mm_Mfnc_MQ", "*** TEST PASSED *** All DMA transfers completed successfully!", UVM_NONE)
        end
        begin
          #DMA_TIMEOUT;
          if (!dma_req_proc.test_done)
            `uvm_error("test_qdma_h2c_c2h_mm_Mfnc_MQ", $sformatf(
              "*** TEST FAILED *** Timeout waiting for DMA completion. qid_cmp_cnt=%0d/%0d",
              dma_req_proc.qid_cmp_cnt, num_qid_in_test))
        end
      join_any
      disable fork;

    phase.drop_objection(this);
  endtask

endclass
