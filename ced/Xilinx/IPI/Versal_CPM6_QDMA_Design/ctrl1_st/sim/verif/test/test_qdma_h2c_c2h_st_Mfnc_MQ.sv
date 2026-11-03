// Parametric H2C/C2H Streaming test — runs multiple PFs + VFs × QIDs with port_id cycling.
//
// Supports both H2C-ST and C2H-ST directions via +DIRECTION plusarg.
// Structure mirrors test_qdma_h2c_c2h_mm_Mfnc_MQ for consistency.
//
// Plusargs:
//   +NUM_PF_TEST=<0..NUM_PF>      PFs to test (0=skip)  (default: random [1:NUM_PF])
//   +NUM_VF_TEST=<0..NUM_VF>      VFs to test (0=skip)  (default: random [0:NUM_VF])
//   +C2H_PKT_BYTES=<64..61440>    C2H packet size, multiple of 64 (default: DMA_BYTE_CNT).
//                                 Programmed into the example-design C2H source; a
//                                 packet longer than 4096 B takes several descriptors.
//   +C2H_EXPECT_PFCH_DROP         C2H packets need more than 7 descriptors and are
//                                 dropped by the DMA: C2H queues are not counted for
//                                 completion; the run ends +C2H_DROP_WAIT_NS after start.
//   +NUM_Q_TEST=<1..QUEUE_PER_VF> Queues per function    (default: random [1:QUEUE_PER_VF])
//   +PIDX=<1..256>                Descriptor ring depth  (default: random [1:256])
//   +DMA_BYTE_CNT=<64..8192>      Transfer size          (default: random power-of-two;
//                                 up to 65536 with TEST_MODE=DRV_SEQ)
//   +IRQ_EN=<0|1>                 MSI-X enable           (default: 0)
//   +DIRECTION=<BOTH|H2C|C2H>    DMA direction          (default: H2C)
//   +TEST_MODE=H2C_DRV_SEQ       driver-style H2C-ST request sequence
//                                (+H2C_DRV_FRCD=<0|1>, +H2C_DRV_STEP_NS=<ns>)
//   +TEST_MODE=C2H_DRV_SEQ       driver-style C2H-ST receive on one queue
//                                (+C2H_DRV_PKTS=<n>, +C2H_DRV_FRCD, +C2H_DRV_PFCH_EN,
//                                 +C2H_DRV_PIDX_DB=<0|1>, +C2H_DRV_STEP_NS=<ns>)
//   +TEST_MODE=DRV_SEQ           every queue (PF and VF, DIRECTION) driven the way the
//                                Linux driver drives it, poll or direct-interrupt mode
//                                (+DRV_NOTIFY=POLL|DIRECT, other +DRV_* knobs in
//                                 qdma_st_drv_engine.svh); +PIDX = requests/packets per queue
//   +DRV_NUM_REQ=<1..256>        DRV_SEQ only: requests per queue (each H2C write and
//                                each C2H read, the apps' -c count); takes precedence
//                                over +PIDX
//   +NUM_DMA_PORTS=<1..4>         Ports for round-robin  (default: 2)
//
// Example invocations:
//   make s TEST=test_qdma_h2c_c2h_st_Mfnc_MQ                              # random H2C-only
//   make s TEST=test_qdma_h2c_c2h_st_Mfnc_MQ DIRECTION=BOTH               # H2C + C2H
//   make s TEST=test_qdma_h2c_c2h_st_Mfnc_MQ NUM_PF_TEST=2 NUM_Q_TEST=4 IRQ_EN=1
//   make s TEST=test_qdma_h2c_c2h_st_Mfnc_MQ NUM_VF_TEST=0 PIDX=7 DMA_BYTE_CNT=4096
//   make s TEST=test_qdma_h2c_c2h_st_Mfnc_MQ NUM_PF_TEST=1 NUM_VF_TEST=4 NUM_Q_TEST=1 DIRECTION=H2C

class test_qdma_h2c_c2h_st_Mfnc_MQ extends qdma_base_test;

  `uvm_component_utils(test_qdma_h2c_c2h_st_Mfnc_MQ)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  qdma_mem_callback  host_mem_cb;
  int NUM_PF_TEST;
  int NUM_VF_TEST;
  int NUM_Q_TEST;

  integer num_qid_in_test;
  logic   irq_en;
  string  direction;    // DMA direction: "BOTH", "H2C", or "C2H"; overridden by +DIRECTION=

  // Randomizable knobs — overridden by plusargs when provided
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
  // NUM_Q_TEST: 1..min(QUEUE_PER_PF, QUEUE_PER_VF) so it is valid for both PF and VF loops
  constraint c_num_q {
    r_num_q inside {[1 : QUEUE_PER_VF]};
  }
  // pidx: 1..256 (keep descriptor ring bounded; override with +PIDX=<n>).
  // The driver-sequence flow sizes its rings from the driver's ring table and
  // wraps them, so its request count is not bounded by one ring: up to 4096.
  bit drv_seq_mode;
  constraint c_pidx {
    !drv_seq_mode -> r_pidx inside {[1 : 256]};
    drv_seq_mode  -> r_pidx inside {[1 : 4096]};
  }
  // DMA_BYTE_CNT: power-of-two between 64 and 8192 bytes.
  // The driver sequence splits each request into 4096 B descriptors, so its
  // source buffer may be larger (per-request sizes up to the buffer size);
  // random picks stay at 8192 or below.
  constraint c_dma_byte_cnt {
    !drv_seq_mode -> r_dma_byte_cnt inside {64, 128, 256, 512, 1024, 2048, 4096, 8192};
    drv_seq_mode  -> r_dma_byte_cnt inside {64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536};
    soft r_dma_byte_cnt <= 8192;
  }

  virtual function void build_phase(uvm_phase phase);
    string dir_early;
    phase.raise_objection(this);
    // Parse DIRECTION early so c2h_active is set before super.build_phase
    // creates user agents (UVM_ACTIVE when c2h_active=1).
    dir_early = "H2C";
    void'($value$plusargs("DIRECTION=%s", dir_early));
    if (dir_early != "H2C")
      c2h_active = 1;
    super.build_phase(phase);
    if (!$value$plusargs("NUM_DMA_PORTS=%d", num_dma_ports))
      num_dma_ports = 2;
    phase.drop_objection(this);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    for (int ii = 0; ii < 2; ii++) begin
      if (vip_cfg.ctrlr_en[ii]) begin
        vip_cfg.port_ctl[ii] = generic_config::PCIE;
        vip_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::RP;
        vip_cfg.pcie_cfg[ii].flit_mode_ctl = 1'b1;
      end
      if (dut_cfg.ctrlr_en[ii]) begin
        dut_cfg.base_cdo     = "bd_a238_cpm6_0_0_sim_text.cdo";
        dut_cfg.use_case[ii] = dut_config::PCIE_DMA;
        dut_cfg.port_ctl[ii] = generic_config::PCIE;
        dut_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::EP;
        dut_cfg.pcie_cfg[ii].flit_mode_ctl  = 1'b1;
      end
    end
    env.shim.vip.set("bus_enum_ari_forwarding", 1);
    use_vf_enum = 1;
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    phase.raise_objection(this);
    host_mem_cb = new(env.shim.vip, this);
    `uvm_info("QDMA_MEM_CALLBACK", "Appending callback to host memory", UVM_NONE)
    env.shim.vip.append_callback(host_mem_cb);
    phase.drop_objection(this);
  endfunction

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    phase.raise_objection(this);

      // ---------------------------------------------------------------
      // Step 1: Collect plusarg overrides (0 = not provided, except where noted)
      // Supported plusargs:
      //   +NUM_PF_TEST=<0..NUM_PF>  (0 = skip PF loop; VF-only mode)
      //   +NUM_VF_TEST=<0..NUM_VF>  (0 = skip VF loop)
      //   +NUM_Q_TEST=<1..QUEUE_PER_VF>
      //   +PIDX=<1..256>
      //   +DMA_BYTE_CNT=<64|128|...|8192> (up to 65536 with TEST_MODE=DRV_SEQ)
      //   +IRQ_EN=<0|1>       (default=0: disable MSI-X interrupts)
      //   +DIRECTION=<BOTH|H2C|C2H>  (default=H2C)
      //   +NUM_DMA_PORTS=<1..4>  (default=2; sequential assignment)
      // ---------------------------------------------------------------
      begin
        int parg_num_pf, parg_num_vf, parg_num_q, parg_pidx, parg_dma_byte_cnt, parg_irq_en;
        bit has_num_vf;
        int qid_counter;
        bit [2:0] port_id;

        parg_num_pf       = 0;
        parg_num_vf       = 0;
        parg_num_q        = 0;
        parg_pidx         = 0;
        parg_dma_byte_cnt = 0;
        parg_irq_en       = 0; // default: no interrupts for ST
        direction         = "H2C"; // default: H2C-only

        void'($value$plusargs("NUM_PF_TEST=%0d",   parg_num_pf));
        has_num_vf = $value$plusargs("NUM_VF_TEST=%0d", parg_num_vf);
        void'($value$plusargs("NUM_Q_TEST=%0d",    parg_num_q));
        void'($value$plusargs("PIDX=%0d",          parg_pidx));
        void'($value$plusargs("DMA_BYTE_CNT=%0d",  parg_dma_byte_cnt));
        void'($value$plusargs("IRQ_EN=%0d",        parg_irq_en));
        void'($value$plusargs("DIRECTION=%s",      direction));
        irq_en = logic'(parg_irq_en);
        begin
          string tm;
          drv_seq_mode = $value$plusargs("TEST_MODE=%s", tm) && (tm == "DRV_SEQ");
        end

        // +DRV_NUM_REQ: the driver sequence's request count per queue. It sets the
        // same value +PIDX would, so the engine and the scoreboard stay in step.
        begin
          int parg_num_req;
          parg_num_req = 0;
          if (drv_seq_mode && $value$plusargs("DRV_NUM_REQ=%0d", parg_num_req) && parg_num_req > 0) begin
            parg_pidx = parg_num_req;
            `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ",
              $sformatf("requests/queue: %0d  (+DRV_NUM_REQ, overrides +PIDX)", parg_num_req), UVM_NONE)
          end
        end

        // Validate DIRECTION plusarg
        if (direction != "BOTH" && direction != "H2C" && direction != "C2H")
          `uvm_fatal("test_qdma_h2c_c2h_st_Mfnc_MQ",
            $sformatf("+DIRECTION=%s invalid; must be BOTH, H2C, or C2H", direction))

        // Step 2: Lock constraints for any plusarg-supplied values, then randomize.
        if (!randomize(r_num_pf, r_num_vf, r_num_q, r_pidx, r_dma_byte_cnt) with {
              (parg_num_pf       > 0) -> r_num_pf       == parg_num_pf;
              has_num_vf                 -> r_num_vf       == parg_num_vf;
              (parg_num_q        > 0) -> r_num_q        == parg_num_q;
              (parg_pidx         > 0) -> r_pidx         == parg_pidx;
              (parg_dma_byte_cnt > 0) -> r_dma_byte_cnt == parg_dma_byte_cnt;
            })
          `uvm_fatal("test_qdma_h2c_c2h_st_Mfnc_MQ", "randomize() failed  -  check plusarg values against constraints")

        // Step 3: Assign resolved values
        NUM_PF_TEST  = r_num_pf;
        NUM_VF_TEST  = r_num_vf;
        NUM_Q_TEST   = r_num_q;
        pidx         = r_pidx[15:0];
        DMA_BYTE_CNT = r_dma_byte_cnt;

        // +NUM_PF_TEST=0 cannot be randomized to 0 (constraint is [1:NUM_PF]).
        // Apply post-randomize: explicit zero disables the PF loop (VF-only mode).
        begin
          int tmp;
          if ($value$plusargs("NUM_PF_TEST=%0d", tmp) && tmp == 0)
            NUM_PF_TEST = 0;
        end

        // +RING_ENTRIES: runtime descriptor/completion ring size (default
        // GLBL_RNG_SIZE). Only the ring SIZE changes; per-queue ring address
        // spacing stays at GLBL_RNG_SIZE, so address->qid decoding is unchanged.
        begin
          int parg_ring_entries;
          parg_ring_entries = 0;
          void'($value$plusargs("RING_ENTRIES=%0d", parg_ring_entries));
          if (parg_ring_entries > 0) begin
            if (parg_ring_entries < 4 || parg_ring_entries > GLBL_RNG_SIZE)
              `uvm_fatal("test_qdma_h2c_c2h_st_Mfnc_MQ",
                $sformatf("+RING_ENTRIES=%0d out of range 4..%0d (last slot is the status entry)",
                          parg_ring_entries, GLBL_RNG_SIZE))
            ring_entries = parg_ring_entries[31:0];
            dma_req_proc.ring_entries = parg_ring_entries;
            `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ",
              $sformatf("ring_entries  : %0d (%0d usable)  (plusarg)", ring_entries, ring_entries - 1), UVM_NONE)
          end
        end
      end

      TSK_PRINT_QDMA_ENV;

      // direction "BOTH" counts H2C + C2H per queue (x2); single direction = x1
      num_qid_in_test = (NUM_PF_TEST + NUM_VF_TEST) * NUM_Q_TEST *
                        ((direction == "BOTH") ? 2 : 1);
      dma_req_proc.qid_in_test  = num_qid_in_test;
      dma_req_proc.pidx         = pidx;
      dma_req_proc.DMA_BYTE_CNT = DMA_BYTE_CNT;
      dma_req_proc.dma_st       = 1;  // ST mode: require H2C data on AXI4-Stream

      // C2H packet size generated by the example-design C2H source
      begin
        int parg_c2h_pkt;
        if ($value$plusargs("C2H_PKT_BYTES=%0d", parg_c2h_pkt)) begin
          if (parg_c2h_pkt <= 0 || (parg_c2h_pkt % 64) != 0)
            `uvm_fatal("test_qdma_h2c_c2h_st_Mfnc_MQ",
              $sformatf("+C2H_PKT_BYTES=%0d invalid; must be a positive multiple of 64", parg_c2h_pkt))
          c2h_pkt_bytes = parg_c2h_pkt;
          dma_req_proc.c2h_pkt_bytes   = c2h_pkt_bytes;
        end
        // Also without the plusarg: a DMA_BYTE_CNT above one C2H buffer
        // already takes several descriptors per packet.
        dma_req_proc.c2h_dsc_per_pkt = c2h_dsc_per_pkt();
      end
      // Drop test: the C2H queues never complete, so only H2C counts.
      if ($test$plusargs("C2H_EXPECT_PFCH_DROP") && direction != "H2C") begin
        num_qid_in_test = (direction == "BOTH") ? num_qid_in_test / 2 : 0;
        dma_req_proc.qid_in_test = num_qid_in_test;
      end

      `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("/****************/"), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("  Test Variables  "), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("/****************/"), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("NUM_PF_TEST   : %0d  %s", NUM_PF_TEST,  ($test$plusargs("NUM_PF_TEST=")  ? "(plusarg)" : "(random)")), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("NUM_VF_TEST   : %0d  %s", NUM_VF_TEST,  ($test$plusargs("NUM_VF_TEST=")  ? "(plusarg)" : "(random)")), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("NUM_Q_TEST    : %0d  %s", NUM_Q_TEST,   ($test$plusargs("NUM_Q_TEST=")   ? "(plusarg)" : "(random)")), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("pidx          : %0d  %s", pidx,         ($test$plusargs("PIDX=")         ? "(plusarg)" : "(random)")), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("DMA_BYTE_CNT  : %0d  %s", DMA_BYTE_CNT, ($test$plusargs("DMA_BYTE_CNT=") ? "(plusarg)" : "(random)")), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("irq_en        : %0d  %s", irq_en,       ($test$plusargs("IRQ_EN=")       ? "(plusarg)" : "(default=0)")), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("direction     : %s  %s", direction,    ($test$plusargs("DIRECTION=")    ? "(plusarg)" : "(default=H2C)")), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("c2h_pkt_bytes : %0d  %0d descriptor(s)/packet, C2H ring pidx %0d  %s",
                c2h_eff_pkt_bytes(), c2h_dsc_per_pkt(), c2h_ring_pidx(),
                (c2h_pkt_bytes != 0) ? "(plusarg)" : "(DMA_BYTE_CNT)"), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("num_dma_ports : %0d",     num_dma_ports), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("num_qid_in_test   : %0d",     num_qid_in_test), UVM_NONE)
      `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("/****************/"), UVM_NONE)

      // ---------------------------------------------------------------
      // TEST_MODE dispatch: +TEST_MODE=<mode> selects SLT test scenario.
      // Default (no TEST_MODE) = ST bring-up flow.
      // ---------------------------------------------------------------
      begin
        string test_mode;
        if ($value$plusargs("TEST_MODE=%s", test_mode)) begin
          `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("TEST_MODE=%s selected", test_mode), UVM_NONE)
          case (test_mode)
            "PERF":    TSK_SLT_ST_PERF_TEST(NUM_PF_TEST, NUM_VF_TEST, NUM_Q_TEST, direction, irq_en);
            // H2C-ST requests issued the driver's way (poll mode), including
            // multi-descriptor requests under one doorbell; the sequence
            // judges each request itself, so the scoreboard does not end the
            // test early.
            "H2C_DRV_SEQ": begin
              dma_req_proc.qid_in_test = 0;
              TSK_QDMA_ST_H2C_DRV_SEQ(3'(dma_port_base));
              dma_req_proc.test_done = 1;
              dma_req_proc.done_ev.trigger();
            end
            // C2H-ST packets received the driver's way (poll mode): free list,
            // doorbells, and completions judged only from the completion
            // ring and its status entry in host memory.
            // Every queue driven the way the Linux driver drives it; the
            // engine judges each request and packet and ends the test.
            "DRV_SEQ": begin
              dma_req_proc.qid_in_test = 0;
              TSK_QDMA_ST_DRV_SEQ(NUM_PF_TEST, NUM_VF_TEST, NUM_Q_TEST, direction);
              if (direction != "H2C" && !drv_mmio_dead) begin
                TSK_C2H_SRC_JOIN();
                TSK_CMPT_CTXT_POST_CHECK();
              end else if (drv_mmio_dead)
                `uvm_info("DRV_SEQ", "register traffic stopped by DRV_MMIO_CTO: generator join and completion-context post check skipped", UVM_NONE)
              dma_req_proc.test_done = 1;
              dma_req_proc.done_ev.trigger();
            end
            "C2H_DRV_SEQ": begin
              dma_req_proc.qid_in_test = 0;
              TSK_QDMA_ST_C2H_DRV_SEQ(3'(dma_port_base));
              TSK_C2H_SRC_JOIN();
              TSK_CMPT_CTXT_POST_CHECK();
              dma_req_proc.test_done = 1;
              dma_req_proc.done_ev.trigger();
            end
            // Completion-context write/read-back through the indirect context
            // registers only: no queue setup, no traffic (+CMPT_RT_QID, default 1).
            "CMPT_CTXT_RT": begin
              int rt_qid = 1;
              void'($value$plusargs("CMPT_RT_QID=%0d", rt_qid));
              dma_req_proc.qid_in_test = 0;
              TSK_CMPT_CTXT_RT_TEST(11'(rt_qid));
              dma_req_proc.test_done = 1;
              dma_req_proc.done_ev.trigger();
            end
            default:   `uvm_fatal("TEST_MODE", $sformatf("Unknown TEST_MODE for ST test: %s", test_mode))
          endcase
        end else begin
          // ---------------------------------------------------------------
          // Default ST bring-up flow
          // ---------------------------------------------------------------
          // PF loop: each PF gets NUM_Q_TEST queues, port_id cycles round-robin
          // (+NUM_PF_TEST=0 skips this block entirely: VF-only mode)
          begin
            int qid_counter;
            bit [2:0] port_id;
            qid_counter = 0;

            if (NUM_PF_TEST > 0) begin
              qid = 11'h1;
              for (int i = 0; i < NUM_PF_TEST; i++) begin
                pf_fnc = 4'(i);
                for (int j = 0; j < NUM_Q_TEST; j++) begin
                  port_id = 3'((qid_counter % num_dma_ports) + dma_port_base);
                  `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("Testing qid#%0d with PF function %0d port=%0d direction=%s", qid+j, pf_fnc, port_id, direction), UVM_NONE)
                  if (direction != "C2H") TSK_QDMA_ST_H2C_TEST(qid + j, port_id, irq_en);
                  if (direction != "H2C") TSK_QDMA_ST_C2H_TEST(qid + j, port_id, irq_en);
                  qid_counter++;
                end
              end
            end

            // VF loop: each VF gets NUM_Q_TEST queues, port_id cycles round-robin
            // (+NUM_VF_TEST=0 skips this block entirely: PF-only mode)
            if (NUM_VF_TEST > 0) begin
              qid = 11'h1;
              fnc = VF_OFFSET;  // VF functions start right after the enabled PF count, not at MAX_PF (see pkg.cpm6_qdma_params.sv)
              for (int i = 0; i < NUM_VF_TEST; i++) begin
                for (int j = 0; j < NUM_Q_TEST; j++) begin
                  port_id = 3'((qid_counter % num_dma_ports) + dma_port_base);
                  `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("Testing qid#%0d with VF function %0d port=%0d direction=%s", qid+j, fnc+i, port_id, direction), UVM_NONE)
                  if (direction != "C2H") TSK_QDMA_VF_ST_H2C_TEST(fnc + i, qid + j, port_id, irq_en);
                  if (direction != "H2C") TSK_QDMA_VF_ST_C2H_TEST(fnc + i, qid + j, port_id, irq_en);
                  qid_counter++;
                end
              end
            end
          end

          // Drop test: give the dropped C2H packets time to show up, then
          // record what reached the host. Ends the run when no H2C queue is
          // left to complete. The default wait stays below the 50 us DMA
          // stall watchdog.
          if ($test$plusargs("C2H_EXPECT_PFCH_DROP") && direction != "H2C") begin
            int unsigned drop_wait_ns;
            bit [10:0]   dq;
            drop_wait_ns = 40000;
            void'($value$plusargs("C2H_DROP_WAIT_NS=%0d", drop_wait_ns));
            #(drop_wait_ns * 1ns);
            if (dma_req_proc.c2h_bytes.first(dq)) begin
              do begin
                `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf(
                  "C2H drop test: qid=%0d %0d bytes in %0d TLPs reached the host %0d ns after start",
                  dq, dma_req_proc.c2h_bytes[dq], dma_req_proc.c2h_cnt[dq], drop_wait_ns), UVM_NONE)
              end while (dma_req_proc.c2h_bytes.next(dq));
            end else
              `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf(
                "C2H drop test: no C2H bytes reached the host %0d ns after start", drop_wait_ns), UVM_NONE)
            if (num_qid_in_test == 0) begin
              dma_req_proc.test_done = 1;
              dma_req_proc.done_ev.trigger();
            end
          end

          // Wait for all DMA transfers to complete
          `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", "Waiting for all ST DMA transfers to complete...", UVM_NONE)
          // (a drop test may already have ended the run above)
          if (!($test$plusargs("C2H_EXPECT_PFCH_DROP") && dma_req_proc.test_done))
          fork
            begin
              dma_req_proc.done_ev.wait_trigger();
              `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", "*** TEST PASSED *** All ST DMA transfers completed successfully!", UVM_NONE)
            end
            begin
              #TIMEOUT;
              if (!dma_req_proc.test_done)
                `uvm_error("test_qdma_h2c_c2h_st_Mfnc_MQ", "*** TEST FAILED *** Timeout waiting for ST DMA completion")
            end
          join_any
          disable fork;
          // C2H generator bursts: all started and ended, PKT_CNT per port equal
          // to the packets the bursts asked for.
          if (direction != "H2C")
            TSK_C2H_SRC_JOIN();
          // Completion contexts after the transfers: the fields only software
          // writes must still read back as written at queue setup.
          if (direction != "H2C" && enable_c2h_cmpt)
            TSK_CMPT_CTXT_POST_CHECK();
          // +DBG_DUMP: print the streaming debug words at the end of the run
          if ($test$plusargs("DBG_DUMP")) begin
            int n_tags = 0;
            void'($value$plusargs("DBG_DUMP_TAGS=%0d", n_tags));
            TSK_QDMA_DBG_DUMP(n_tags);
          end
        end // default (no TEST_MODE)
      end // TEST_MODE dispatch

    phase.drop_objection(this);
  endtask

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    fork
      begin : WAIT_DONE
        wait (dma_req_proc.test_done);
        `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", "Test completed successfully", UVM_NONE)
      end
      begin : WAIT_TIMEOUT
        #TIMEOUT;
        `uvm_error("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("TIMEOUT after %0t", TIMEOUT))
        `uvm_info("test_qdma_h2c_c2h_st_Mfnc_MQ", $sformatf("qid_cmp_cnt:%0d, num_qid_in_test:%0d", dma_req_proc.qid_cmp_cnt, num_qid_in_test), UVM_NONE)
      end
    join_any
    disable fork;

    phase.drop_objection(this);
  endtask

  // ---------------------------------------------------------------
  // Report phase: verify H2C data reached the AXI4-Stream interface
  // Runs after all run-time phases complete, so pipeline has drained.
  // ---------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    if (direction != "C2H") begin
      if (dma_req_proc.h2c_user_pkt_cnt == 0) begin
        `uvm_error("ST_INTEGRITY",
          "H2C: 0 packets received on AXI4-Stream interface  -  data never reached user side")
      end else begin
        `uvm_info("ST_INTEGRITY", $sformatf(
          "H2C: %0d packets received on AXI4-Stream interface",
          dma_req_proc.h2c_user_pkt_cnt), UVM_NONE)
        foreach (dma_req_proc.h2c_user_data[qid])
          dma_req_proc.check_h2c_integrity(qid);
        if (dma_req_proc.h2c_integrity_err_cnt > 0)
          `uvm_error("ST_INTEGRITY", $sformatf(
            "H2C: %0d data integrity mismatches", dma_req_proc.h2c_integrity_err_cnt))
        else
          `uvm_info("ST_INTEGRITY", "H2C: all data integrity checks PASSED", UVM_NONE)
      end
    end

    if (direction != "H2C") begin
      // C2H integrity is checked inline at C2H_DONE (check_c2h_integrity called
      // from dma_req_processor).  Report summary here.
      if (dma_req_proc.c2h_err_cnt > 0)
        `uvm_error("ST_INTEGRITY", $sformatf(
          "C2H: %0d data integrity mismatches", dma_req_proc.c2h_err_cnt))
      else
        `uvm_info("ST_INTEGRITY", "C2H: all data integrity checks PASSED", UVM_NONE)
    end
  endfunction

endclass
