// Note: this file is `included inside proj_test_pkg -- don't import it separately.
//
// dma_req_processor tracks H2C/C2H DMA completion (qid_cmp_cnt), MSI-X TLP
// counts (h2c_msix_cnt/c2h_msix_cnt), and overall test completion
// (done_ev/test_done). It is driven entirely by dma_trfr_bus, populated by
// qdma_mem_callback watching PCIe MWr/MRd TLPs.
typedef class qdma_base_test;
typedef class dma_req_processor;

class dma_req_processor extends uvm_component;
  `uvm_component_utils(dma_req_processor)

  bit test_done;
  uvm_event done_ev;
  integer qid_in_test;
  bit [31:0] host_addr;
  bit [10:0] h2c_qid;
  bit [10:0] c2h_qid;
  int unsigned h2c_cnt[bit [10:0]];
  int unsigned c2h_cnt[bit [10:0]];
  int unsigned h2c_dsc_fetch_cnt[bit [10:0]];   // descriptors fetched, per qid (H2C ring MRDs)
  int unsigned c2h_dsc_fetch_cnt[bit [10:0]];   // descriptors fetched, per qid (C2H ring MRDs)
  integer qid_cmp_cnt = 0;
  host_req_bus dma_trfr_bus;
  bit [15:0]     pidx;
  bit [31:0] DMA_BYTE_CNT;
  bit h2c_trfr_done[bit [10:0]];
  bit c2h_trfr_done[bit [10:0]];
  bit h2c_host_done[bit [10:0]];  // host-side MRD byte-count complete (informational in ST mode)

  // Data integrity scoreboard
  // Handle to the owning test  - gives live access to host_mem after MWR writes.
  // Set by qdma_base_test in connect_phase.
  qdma_base_test test_ref;

  // Per-qid expected data snapshot registered before each C2H transfer.
  // Outer key: qid; inner key: byte offset (0..DMA_BYTE_CNT-1); value: expected byte
  byte c2h_expected[bit [10:0]][int];

  // Per-qid destination base address (host_mem key for byte 0 of the transfer)
  longint unsigned c2h_dst_base[bit [10:0]];

  // Error count accumulated across all C2H data integrity checks this simulation
  int unsigned c2h_err_cnt = 0;

  // Per-QID received H2C user-side data (from AXI4-Stream monitor)
  byte h2c_user_data[bit [10:0]][$];  // qid → queue of received bytes
  int unsigned h2c_user_pkt_cnt = 0;  // total H2C packets received from user monitor
  int unsigned h2c_integrity_err_cnt = 0; // total H2C data integrity mismatches

  // per-queue cap on logged mismatch DETAIL lines.
  // The aggregate count was always printed, but the detail list stopped at a
  // hardcoded 8 with no indication it had been truncated, so a 9-byte corruption
  // and a 9000-byte corruption produced an identical-looking detail block. The
  // first mismatches are also rarely the informative ones - a run of consecutive
  // bad bytes reads very differently from scattered single-bit flips, and 8
  // samples cannot distinguish them. Override with +MAX_MISMATCH_LOG=<n>.
  int unsigned max_mismatch_log = 64;

  // DMA mode flag: set to 1 by ST tests to enable user-side data checks.
  // When dma_st=1, H2C PASS requires data on the AXI4-Stream interface.
  // When dma_st=0 (MM mode), user-side checks are informational only.
  bit dma_st = 0;

  // Pass condition 3: WB packets received
  int wb_done_cnt = 0;   // total ISR_WB_DONE events received
  int wb_req_cnt  = 0;   // total WB_REQ (writeback pipeline push) events received
  int wb_pipeline_done_cnt = 0;  // drain-detection counter

  // Bound on the address-capture drain wait at test_done (see the
  // qid_cmp_cnt==qid_in_test block below) -- large relative to the observed
  // ~1-2us worst-case margin, small relative to the overall DMA_TIMEOUT.
  time WB_DRAIN_TIMEOUT = 20us;

  // One-shot guard: qid_cmp_cnt stays at qid_in_test permanently once reached,
  // so without this the qid_cmp_cnt==qid_in_test block below would re-fire
  // (and re-fork) on every subsequent mailbox item processed by the same loop.
  bit wb_drain_spawned = 0;

  // Descriptor-status writebacks seen (DSC_WB_MWR), independent of wb_done_cnt
  // (ISR-fed, needs irq_en) and wb_req_cnt (never incremented in this env).
  // Writebacks drain serially, so used by the completion watchdog to
  // distinguish a healthy drain from a genuine stall.
  int unsigned wb_mwr_count = 0;

  // Watchdog heartbeat: promoted to a class member (was a run_phase local) so
  // notify_wb_done() can also touch it -- a draining writeback backlog counts
  // as DMA progress just like a fresh TLP does (see notify_wb_done below).
  time last_tlp_time = 0;

  // -- Watchdog diagnostic enrichment (does NOT feed last_tlp_time and does
  // NOT gate/reset either watchdog's fire condition -- DMA_COMPLETION_WATCHDOG
  // is gated by qid_cmp_cnt and wb_mwr_count only). Purpose: when a watchdog fires,
  // dump_progress_snapshot() can report whether there was recent lower-level
  // bus/FSM activity within the stall window ("busy but stuck in a loop") or
  // genuinely none ("dead"), instead of qid_cmp_cnt alone.
  //   last_fsm_activity_time : not wired in this env (open item --
  //                            dump_progress_snapshot() skips printing it
  //                            while unfed, see below).
  //   last_axi_activity_time : not wired in this env (open item --
  //                            dump_progress_snapshot() skips printing it
  //                            while unfed, see below).
  time last_axi_activity_time = 0;
  time last_fsm_activity_time = 0;

  // Stall-detection threshold shared by dump_progress_snapshot()'s activity
  // comparison and the watchdogs below. Promoted to a class member (was a
  // run_phase local) for the same reason last_tlp_time was: a function
  // outside run_phase (dump_progress_snapshot) needs to read it. Set once at
  // the top of run_phase from +DMA_STALL_TIMEOUT (default 50us) and never
  // written anywhere else -- this is the SAME value driving both watchdogs,
  // not a second timeout knob.
  time STALL_LIMIT;

  // WB destination-address scoreboard (pass condition 3b).
  // Tracks the first PCIe MWr address seen for each QID's WB write into its
  // descriptor ring.  Expected address: dsc_base + (RING_SIZE-1)*QDMA_DSC_SZ
  // (the last slot of the ring, where the QDMA WBI status descriptor is placed).
  // A C2H WB landing at the H2C base is the confirmed DUT bug (reg_space.sv:1509).
  longint unsigned h2c_wb_mwr_addr[bit [10:0]]; // first H2C WB MWr addr per QID
  longint unsigned c2h_wb_mwr_addr[bit [10:0]]; // first C2H WB MWr addr per QID
  int              h2c_wb_addr_err_cnt = 0;      // H2C WB at wrong slot
  int              c2h_wb_addr_err_cnt = 0;      // C2H WB at wrong slot (the bug)

  // WB status PIDX/CIDX scoreboard (pass condition 7 — PG302 Table 10).
  // Captures pidx[47:32] and cidx[31:16] from MWr TLP payload (DWord 1 and DWord 0)
  // at the time the WB write arrives; compared against expected in report_phase.
  bit [15:0] h2c_wb_status_pidx[bit [10:0]];  // pidx captured from H2C WB TLP
  bit [15:0] h2c_wb_status_cidx[bit [10:0]];  // cidx captured from H2C WB TLP
  bit [15:0] c2h_wb_status_pidx[bit [10:0]];  // pidx captured from C2H WB TLP
  bit [15:0] c2h_wb_status_cidx[bit [10:0]];  // cidx captured from C2H WB TLP

  // Pass condition 4: MSI-X MWr received when irq_en is set
  int h2c_msix_cnt = 0;  // count of MSI-X MWr TLPs with vec=1 (H2C)
  int c2h_msix_cnt = 0;  // count of MSI-X MWr TLPs with vec=2 (C2H)
  bit irq_en       = 0;  // mirrored from +IRQ_EN plusarg; gates MSI-X pass check

  // PIDX refill support: continuous descriptor feeding for sustained throughput tests
  int total_dsc_cnt;                     // total descriptors per queue (0 = no refill)
  int refill_threshold;                  // remaining < this triggers refill
  int unsigned cidx_latest[bit [10:0]];  // per-QID latest CIDX from WB
  int unsigned pidx_current[bit [10:0]]; // per-QID current PIDX written to doorbell
  int unsigned total_submitted[bit [10:0]]; // per-QID total descriptors submitted so far
  bit refill_needed[bit [10:0]];         // per-QID flag: refill needed
  uvm_event refill_ev;                   // wakeup event (broadcast to all refill tasks)

  // Byte-count scoreboard: accumulated bytes per queue, compared to pidx*DMA_BYTE_CNT
  longint unsigned h2c_bytes[bit [10:0]]; // bytes read from host_mem (H2C MRD TLPs)
  longint unsigned c2h_bytes[bit [10:0]]; // bytes written to host_mem (C2H MWR TLPs)
  longint unsigned h2c_dsc_fetch_bytes[bit [10:0]]; // bytes fetched via H2C descriptor-ring MRDs
  longint unsigned c2h_dsc_fetch_bytes[bit [10:0]]; // bytes fetched via C2H descriptor-ring MRDs

  // Performance monitors: per-QID timing for throughput measurement
  time h2c_first_tlp_time[bit [10:0]]; // time of first H2C MRD TLP per QID
  time h2c_last_tlp_time[bit [10:0]];  // time of last H2C MRD TLP per QID
  time c2h_first_tlp_time[bit [10:0]]; // time of first C2H MWR TLP per QID
  time c2h_last_tlp_time[bit [10:0]];  // time of last C2H MWR TLP per QID
  time dma_first_tlp_time;             // time of the very first DMA TLP (any QID)
  time dma_last_done_time;             // time when last QID completed

  // Structured log file descriptor - shared across monitors via uvm_config_db
  // (see qdma_base_test.sv's global "log_fd" set).
  // Writes to the DMA_SCOREBOARD section of cpm6_qdma_dbg.log.
  // Zero means logging is disabled (config_db lookup failed).
  int log_fd = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    test_done = 0;
    done_ev = new("done_ev");
    refill_ev = new("refill_ev");

    // Retrieve the shared log file descriptor opened by qdma_base_test.build_phase.
    // The fd is already valid because UVM calls parent build_phase before child build_phase.
    if (!uvm_config_db#(int)::get(this, "", "log_fd", log_fd))
      `uvm_warning("DMA_SCOREBOARD", "log_fd not found in config_db  - file logging disabled")

    // Mirror the IRQ_EN plusarg so report_phase can gate the MSI-X check.
    // This scoreboard parses +IRQ_EN independently rather than reading the
    // test's resolved irq_en, so this default must be kept equal to
    // test_qdma_h2c_c2h_mm_Mfnc_MQ.sv's own parg_irq_en default (0, poll
    // mode) -- otherwise a run with no +IRQ_EN plusarg drives DMA traffic
    // in poll mode while this check still requires MSI-X.
    begin
      int parg_irq;
      irq_en = ($value$plusargs("IRQ_EN=%0d", parg_irq)) ? bit'(parg_irq) : 1'b0;
    end
    // per-queue mismatch DETAIL cap (aggregate counts are
    // always reported in full regardless of this value).
    begin
      int parg_mml;
      if ($value$plusargs("MAX_MISMATCH_LOG=%0d", parg_mml) && parg_mml > 0)
        max_mismatch_log = parg_mml;
    end
    if (log_fd != 0) begin
      $fdisplay(log_fd, "");
      $fdisplay(log_fd, "# ===================================================================================================================");
      $fdisplay(log_fd, "# DMA_SCOREBOARD  - per-TLP DMA event log");
      $fdisplay(log_fd, "# Event types:");
      $fdisplay(log_fd, "#   H2C_DSC_FETCH  - MRD in H2C descriptor ring region  (qid from ring offset)");
      $fdisplay(log_fd, "#   C2H_DSC_FETCH  - MRD in C2H descriptor ring region  (qid from ring offset)");
      $fdisplay(log_fd, "#   H2C_DMA        - MRD in H2C data source region      (qid from addr bits, shows progress)");
      $fdisplay(log_fd, "#   C2H_DMA        - MWR in C2H data dest region        (qid from addr bits, shows progress)");
      $fdisplay(log_fd, "#   H2C_DONE       - H2C byte count complete for a queue (source=host PCIe MRD accumulation)");
      $fdisplay(log_fd, "#   C2H_DONE       - C2H byte count complete for a queue (source=host PCIe MWR accumulation)");
      $fdisplay(log_fd, "#   C2H_MISMATCH   - data integrity byte mismatch");
      $fdisplay(log_fd, "#   H2C_USER_PKT   - H2C packet received at user-side AXI4-Stream monitor (independent of host byte-count)");
      $fdisplay(log_fd, "#   H2C_INTEG_PASS - H2C data integrity check passed for a queue");
      $fdisplay(log_fd, "#   H2C_INTEG_FAIL - H2C data integrity check failed for a queue");
      $fdisplay(log_fd, "#   H2C_MISMATCH   - H2C data integrity byte mismatch");
      $fdisplay(log_fd, "#   NOTE           - DMA_BYTE_CNT pass/fail in this scoreboard is host-side only; AXI-PL observations are reported separately by pswizard_monitor (PSW_PL_* events)");
      $fdisplay(log_fd, "#   MSIX_MWR       - MSI-X interrupt MWr to programmed vec table entry (expected)");
      $fdisplay(log_fd, "#   DSC_WB_MWR     - QDMA CIDX writeback into H2C/C2H descriptor ring  (expected)");
      $fdisplay(log_fd, "#   WB_CIDX        - writeback CIDX update (refill tracking)");
      $fdisplay(log_fd, "#   UNKNOWN_MRD    - MRD outside all known address regions (unexpected)");
      $fdisplay(log_fd, "#   UNKNOWN_MWR    - MWR outside all known host regions    (unexpected)");
      $fdisplay(log_fd, "#   SUMMARY        - end-of-simulation summary");
      $fdisplay(log_fd, "# -------------------------------------------------------------------------------------------------------------------");
      $fdisplay(log_fd, "# Column definitions:");
      $fdisplay(log_fd, "#   time(ps)   - simulation time in picoseconds when the TLP callback fired");
      $fdisplay(log_fd, "#   event      - TLP classification (see event types above)");
      $fdisplay(log_fd, "#   qid        - hardware queue ID extracted from the TLP address");
      $fdisplay(log_fd, "#               DSC_FETCH: derived from descriptor ring base offset (ring_addr - DSC_BASE) / (RING_SIZE*DSC_SZ)");
      $fdisplay(log_fd, "#               DMA events: extracted from addr bits [log2(DMA_BYTE_CNT)+10 : log2(DMA_BYTE_CNT)]");
      $fdisplay(log_fd, "#               UNKNOWN / DONE events: same qid as the preceding DMA event for that queue");
      $fdisplay(log_fd, "#   addr       - 64-bit host physical address carried in the PCIe TLP header");
      $fdisplay(log_fd, "#   bytes_tlp  - byte count of this individual TLP  (= length_dw * 4)");
      $fdisplay(log_fd, "#               zero for DONE, INTEG, MISMATCH, and SUMMARY event rows");
      $fdisplay(log_fd, "#   cum_bytes  - running total of bytes transferred for this qid in this direction");
      $fdisplay(log_fd, "#               H2C: sum of all MRD bytes seen for the queue so far");
      $fdisplay(log_fd, "#               C2H: sum of all MWR bytes seen for the queue so far");
      $fdisplay(log_fd, "#   exp_bytes  - expected total bytes for a complete transfer: pidx x DMA_BYTE_CNT");
      $fdisplay(log_fd, "#               set once pidx and DMA_BYTE_CNT are known; zero for DSC_FETCH rows");
      $fdisplay(log_fd, "#   rem_bytes  - bytes still outstanding: exp_bytes - cum_bytes (saturates at 0)");
      $fdisplay(log_fd, "#               reaches 0 exactly when the DONE event fires");
      $fdisplay(log_fd, "#   tlp_cnt    - number of TLPs received for this qid in this direction up to and");
      $fdisplay(log_fd, "#               including this event; increments with each MRD (H2C) or MWR (C2H)");
      $fdisplay(log_fd, "#               zero for DSC_FETCH, INTEG, MISMATCH, and SUMMARY rows");
      $fdisplay(log_fd, "#   extra      - free-form annotation: progress markers, PASS/FAIL verdict,");
      $fdisplay(log_fd, "#               mismatch details (offset / exp byte / got byte), or blank");
      $fdisplay(log_fd, "# -------------------------------------------------------------------------------------------------------------------");
      $fdisplay(log_fd, "# %-16s  %-18s  %-6s  %-18s  %-10s  %-10s  %-10s  %-10s  %-8s  %s",
                "time(ps)", "event", "qid", "addr", "bytes_tlp", "cum_bytes", "exp_bytes", "rem_bytes", "tlp_cnt", "extra");
      $fdisplay(log_fd, "# -------------------------------------------------------------------------------------------------------------------");
      $fflush(log_fd);
    end
  endfunction

  // --- Log helper -------------------------------------------------------------
  // Write one structured line to cpm6_qdma_dbg.log.
  // For DSC_FETCH and DONE events pass bytes_tlp/cum/exp/rem/tlp_cnt=0 where not applicable.
  // The extra string carries any free-form annotation (PASS/FAIL, mismatch details, etc.).
  function void log_event(string event_str,
                           int            qid,
                           bit [63:0]     addr,
                           longint unsigned bytes_tlp,
                           longint unsigned cum_bytes,
                           longint unsigned exp_bytes,
                           int            tlp_cnt,
                           string         extra = "");
    longint unsigned rem;
    string dir_str, short_event;
    if (log_fd == 0) return;
    rem = (exp_bytes > cum_bytes) ? (exp_bytes - cum_bytes) : 0;
    // Extract H2C/C2H prefix for the dir column; strip it from the event name
    if (event_str.substr(0,2) == "H2C") begin
      dir_str = "H2C"; short_event = event_str.substr(4, event_str.len()-1);
    end else if (event_str.substr(0,2) == "C2H") begin
      dir_str = "C2H"; short_event = event_str.substr(4, event_str.len()-1);
    end else begin
      dir_str = "---"; short_event = event_str;
    end
    if (bytes_tlp > 0)
      // Print the FULL address, not addr[39:0]. The PL BRAM apertures are flagged
      // by address bit[48] (see pkg.cpm6_qdma_params.sv H2C_DAT_DST_ADDR1 /
      // C2H_DAT_SRC_ADDR0..3), so a [39:0] mask makes a misrouted PL-aperture
      // access print as a benign low host address. That masking hid 78 upstream
      // MRDs to 0x1_0000_0000_0000 and sent a debug arc after the interrupt path
      // instead of the address decode.
      $fdisplay(log_fd, "%9t ns  DMA   %-14s  qid=%2d  %s  addr=0x%016h  %0dB  cum=%0d/%0d (rem=%0d)  tlp#%0d  %s",
                $time, short_event, qid, dir_str, addr,
                bytes_tlp, cum_bytes, exp_bytes, rem, tlp_cnt, extra);
    else
      $fdisplay(log_fd, "%9t ns  DMA   %-14s  qid=%2d  %s  %s",
                $time, short_event, qid, dir_str, extra);
    $fflush(log_fd);
  endfunction

  function void dump_progress_snapshot(string reason);
    bit [10:0] qid;
    if (log_fd == 0)
      return;
    $fdisplay(log_fd, "");
    $fdisplay(log_fd, "# ===================================================================================================================");
    $fdisplay(log_fd, "# DMA_PROGRESS SNAPSHOT  at %0t  reason=%s", $time, reason);
    $fdisplay(log_fd, "#   qid_cmp_cnt=%0d/%0d  wb_done_cnt=%0d  h2c_msix_cnt=%0d  c2h_msix_cnt=%0d",
              qid_cmp_cnt, qid_in_test, wb_done_cnt, h2c_msix_cnt, c2h_msix_cnt);
    $fdisplay(log_fd, "#   wb_mwr_count=%0d  (descriptor-status writebacks seen; watchdog treats a rising count as pending transfer work and HOLDS OFF the fatal)",
              wb_mwr_count);

    // -- Lower-level activity cross-check --------------------------------------
    // Answers "was there recent AXI/FSM activity within the stall window, or
    // genuinely none" -- compared against the SAME STALL_LIMIT driving
    // DMA_COMPLETION_WATCHDOG (no second timeout knob). This is diagnostic
    // context only; it never changes whether/when the watchdog fires.
    // last_axi_activity_time: not printed here for now -- open item, tracked
    // outside this file, to wire a real activity feed for it.
    if (last_axi_activity_time != 0) begin
      $fdisplay(log_fd,
        "#   last_axi_activity_time=%0t  (%0t ago vs STALL_LIMIT=%0t)  %s",
        last_axi_activity_time, $time - last_axi_activity_time, STALL_LIMIT,
        (($time - last_axi_activity_time) >= STALL_LIMIT) ? "STALE (>= STALL_LIMIT, no recent AXI activity)"
                                                            : "recent AXI activity within stall window");
    end
    // last_fsm_activity_time: not printed here for now -- open item, tracked
    // outside this file, to wire a real activity feed for it.
    if (last_fsm_activity_time != 0) begin
      $fdisplay(log_fd,
        "#   last_fsm_activity_time=%0t  (%0t ago vs STALL_LIMIT=%0t)  %s",
        last_fsm_activity_time, $time - last_fsm_activity_time, STALL_LIMIT,
        (($time - last_fsm_activity_time) >= STALL_LIMIT) ? "STALE (>= STALL_LIMIT, no recent FSM activity -- likely genuinely stalled)"
                                                            : "recent FSM activity within stall window (busy but stuck, not dead)");
    end

    if (h2c_bytes.first(qid)) begin
      do begin
        $fdisplay(log_fd,
          "#   H2C qid=%0d bytes=%0d done=%0b pidx_cur=%0d cidx_latest=%0d submitted=%0d refill=%0b",
          qid, h2c_bytes[qid], h2c_trfr_done.exists(qid) ? h2c_trfr_done[qid] : 1'b0,
          pidx_current.exists(qid) ? pidx_current[qid] : 0,
          cidx_latest.exists(qid) ? cidx_latest[qid] : 0,
          total_submitted.exists(qid) ? total_submitted[qid] : 0,
          refill_needed.exists(qid) ? refill_needed[qid] : 1'b0);
      end while (h2c_bytes.next(qid));
    end
    if (c2h_bytes.first(qid)) begin
      do begin
        $fdisplay(log_fd,
          "#   C2H qid=%0d bytes=%0d done=%0b pidx_cur=%0d cidx_latest=%0d submitted=%0d refill=%0b",
          qid, c2h_bytes[qid], c2h_trfr_done.exists(qid) ? c2h_trfr_done[qid] : 1'b0,
          pidx_current.exists(qid) ? pidx_current[qid] : 0,
          cidx_latest.exists(qid) ? cidx_latest[qid] : 0,
          total_submitted.exists(qid) ? total_submitted[qid] : 0,
          refill_needed.exists(qid) ? refill_needed[qid] : 1'b0);
      end while (c2h_bytes.next(qid));
    end
    $fdisplay(log_fd, "# ===================================================================================================================");
    $fflush(log_fd);
  endfunction

  // --- register_c2h_expected --------------------------------------------------
  // Register expected C2H data for one queue before DMA starts.
  // dst_addr : where the DMA engine writes C2H data (checked after DMA).
  // byte_cnt : transfer size.
  // ref_addr : optional reference buffer address for expected-data snapshot.
  //            When non-zero, the expected pattern is read from ref_addr
  //            (typically the H2C source buffer) rather than from dst_addr.
  //            When zero (default), dst_addr is used as both reference and dest.
  function void register_c2h_expected(bit [10:0] qid, longint unsigned dst_addr,
                                       int unsigned byte_cnt,
                                       longint unsigned ref_addr = 0);
    longint unsigned snap_addr;
    c2h_expected[qid].delete();
    c2h_dst_base[qid] = dst_addr;
    snap_addr = (ref_addr != 0) ? ref_addr : dst_addr;
    for (int k = 0; k < byte_cnt; k++) begin
      int addr_key = int'(snap_addr + k);
      if (test_ref != null && test_ref.host_mem.exists(addr_key))
        c2h_expected[qid][k] = test_ref.host_mem[addr_key];
      else
        c2h_expected[qid][k] = 8'h00;
    end
  endfunction

  // --- register_c2h_expected_pattern -------------------------------------------
  // Register expected C2H data using the deterministic pattern generated by
  // c2h_source_ctrl + c2h_source RTL (not from host_mem, which is zeroed for
  // C2H targets).
  //
  // c2h_source pattern:
  //   seed = {448'd0, qid[10:0], 21'd0, global_beat_idx[31:0]}
  //   where global_beat_idx = desc_start * beats_per_desc (reset per tm_dsc_sts)
  //   Each beat: data_reg = seed + beat_within_desc (512-bit increment)
  //
  // desc_start : starting descriptor index for global_beat_idx calculation
  //              (e.g., pidx-1 when only the last descriptor's data persists)
  function void register_c2h_expected_pattern(bit [10:0] qid,
                                               longint unsigned dst_addr,
                                               int unsigned byte_cnt,
                                               int unsigned num_desc,
                                               int unsigned beats_per_desc,
                                               int unsigned desc_start = 0);
    c2h_expected[qid].delete();
    c2h_dst_base[qid] = dst_addr;
    for (int d = 0; d < num_desc; d++) begin
      for (int b = 0; b < beats_per_desc; b++) begin
        bit [511:0] w;
        int unsigned global_beat = (desc_start + d) * beats_per_desc;
        // Replicate c2h_source_ctrl seed + c2h_source increment pattern
        // seed = {448'd0, qid[10:0], 21'd0, global_beat[31:0]}
        // data = seed + b (512-bit add; for small b, only lower 32 bits change)
        w = '0;
        w[31:0]  = 32'(global_beat + b);
        w[63:53] = qid;
        for (int i = 0; i < 64; i++) begin
          int byte_off = (d * beats_per_desc + b) * 64 + i;
          if (byte_off < byte_cnt)
            c2h_expected[qid][byte_off] = w[i*8 +: 8];
        end
      end
    end
    `uvm_info("DMA_SCOREBOARD",
      $sformatf("C2H expected pattern registered qid=%0d dst=0x%0h bytes=%0d desc=%0d beats/desc=%0d desc_start=%0d",
                 qid, dst_addr, byte_cnt, num_desc, beats_per_desc, desc_start), UVM_MEDIUM)
  endfunction

  // --- check_h2c_integrity ---------------------------------------------------
  // Check H2C data integrity for one completed queue by comparing user-side
  // AXI4-Stream data against the expected source data in host_mem.
  // Called after H2C byte-count PASS for each queue.
  function void check_h2c_integrity(bit [10:0] qid);
    int unsigned mismatches = 0;
    int unsigned total_bytes;
    longint unsigned src_addr;
    int unsigned chunk_size;

    if (!h2c_user_data.exists(qid)) begin
      `uvm_warning("DMA_SCOREBOARD",
        $sformatf("H2C qid=%0d: no user-side data received - skipping integrity check", qid))
      return;
    end

    total_bytes = h2c_user_data[qid].size();
    // Compute source address: H2C_DAT_SRC_ADDR with QID encoded
    src_addr = H2C_DAT_SRC_ADDR;
    src_addr[$clog2(DMA_BYTE_CNT)+:11] = qid;
    chunk_size = int'(DMA_BYTE_CNT);

    for (int k = 0; k < total_bytes; k++) begin
      byte got, exp;
      int src_offset;
      int addr_key;
      // Each descriptor reads the same DMA_BYTE_CNT from src_addr,
      // so the expected pattern repeats every DMA_BYTE_CNT bytes.
      src_offset = k % chunk_size;
      addr_key = int'(src_addr) + src_offset;
      got = h2c_user_data[qid][k];
      exp = (test_ref != null && test_ref.host_mem.exists(addr_key)) ?
             test_ref.host_mem[addr_key] : 8'h00;
      if (got !== exp) begin
        if (mismatches < max_mismatch_log) begin
          `uvm_error("DMA_SCOREBOARD",
            $sformatf("H2C data mismatch qid=%0d offset=%0d src_addr=0x%0h exp=0x%0h got=0x%0h",
                       qid, k, longint'(addr_key), exp, got))
          log_event("H2C_MISMATCH", int'(qid), longint'(addr_key), 1,
                    0, 0, 0,
                    $sformatf("offset=%0d exp=0x%02h got=0x%02h", k, exp, got));
        end else if (mismatches == max_mismatch_log) begin
          // See the C2H path - announce truncation once.
          log_event("H2C_MISMATCH", int'(qid), longint'(addr_key), 1, 0, 0, 0,
                    $sformatf("DETAIL LOG TRUNCATED at %0d entries - further mismatches counted but not listed (raise with +MAX_MISMATCH_LOG=<n>)",
                              max_mismatch_log));
        end
        mismatches++;
      end
    end
    h2c_integrity_err_cnt += mismatches;
    if (mismatches == 0) begin
      `uvm_info("DMA_SCOREBOARD",
        $sformatf("H2C data integrity PASS qid=%0d bytes_checked=%0d", qid, total_bytes), UVM_NONE)
      log_event("H2C_INTEG_PASS", int'(qid), src_addr, 0,
                longint'(total_bytes), longint'(total_bytes), 0,
                $sformatf("bytes_checked=%0d PASS", total_bytes));
    end else begin
      `uvm_error("DMA_SCOREBOARD",
        $sformatf("H2C data integrity FAIL qid=%0d mismatches=%0d/%0d",
                   qid, mismatches, total_bytes))
      log_event("H2C_INTEG_FAIL", int'(qid), src_addr, 0,
                longint'(total_bytes), longint'(total_bytes), 0,
                $sformatf("mismatches=%0d/%0d FAIL", mismatches, total_bytes));
    end
  endfunction

  // --- notify_wb_done ---------------------------------------------------------
  // Counts an ISR_WB_DONE event (pass condition 3).
  function void notify_wb_done(bit [1:0] sts);
    wb_done_cnt++;
  endfunction

  // --- notify_wb_pipeline_done -------------------------------------------------
  // Counts a WB_DONE event, used to detect when the writeback backlog has
  // actually drained (wb_req_cnt == wb_pipeline_done_cnt) at the test_done
  // trigger site. Also refreshes last_tlp_time so DMA_PROGRESS_WATCHDOG
  // doesn't misfire on a healthy drain that outlasts STALL_LIMIT once
  // data-TLP traffic has already ended.
  function void notify_wb_pipeline_done();
    wb_pipeline_done_cnt++;
    last_tlp_time = $time;
  endfunction

  // --- notify_fsm_activity -----------------------------------------------------
  // Diagnostic timestamp only -- does not gate or reset either watchdog.
  function void notify_fsm_activity();
    last_fsm_activity_time = $time;
  endfunction

  // --- notify_wb_cidx ---------------------------------------------------------
  // Updates per-QID CIDX and checks whether the remaining descriptors have
  // fallen below the refill threshold, signalling the refill task to submit
  // more descriptors.
  function void notify_wb_cidx(int qid, int cidx);
    bit [10:0] q;
    int remaining;
    wb_req_cnt++;
    q = qid[10:0];
    cidx_latest[q] = cidx;
    if (total_dsc_cnt > 0 && pidx_current.exists(q)) begin
      remaining = int'(pidx_current[q]) - cidx;
      if (remaining < 0) remaining += int'(RING_SIZE) - 1;
      if (remaining < refill_threshold && total_submitted.exists(q) &&
          int'(total_submitted[q]) < total_dsc_cnt) begin
        refill_needed[q] = 1;
        refill_ev.trigger();
      end
    end
    if (log_fd != 0) begin
      $fdisplay(log_fd, "%9t ns  DMA   WB_CIDX         qid=%2d  cidx=%0d  pidx=%0d  rem=%0d  sub=%0d/%0d",
                $time, qid, cidx,
                pidx_current.exists(q) ? int'(pidx_current[q]) : 0,
                (pidx_current.exists(q) ? int'(pidx_current[q]) - cidx : 0),
                total_submitted.exists(q) ? int'(total_submitted[q]) : 0, total_dsc_cnt);
      $fflush(log_fd);
    end
  endfunction

  // --- run_phase --------------------------------------------------------------
  task run_phase(uvm_phase phase);
  host_req_tr tr;
  longint unsigned exp_bytes;
  longint unsigned bytes_this_tlp;
  // Watchdog state: updated on every TLP; watchdog thread monitors for stalls.
  bit           dma_started  = 0;     // set on first TLP  - gates the watchdog
  // STALL_LIMIT is now a class member (see declaration near last_tlp_time) so
  // dump_progress_snapshot() can read the same value driving these watchdogs.
  string        stall_str;
  time          PROGRESS_INTERVAL;
  if (!$value$plusargs("DMA_STALL_TIMEOUT=%s", stall_str))
    STALL_LIMIT = 50us;
  else
    STALL_LIMIT = stall_str.atoreal() * 1us; // accepts "50" -> 50us
  PROGRESS_INTERVAL = 25us;

  h2c_cnt.delete();
  c2h_cnt.delete();
  h2c_trfr_done.delete();
  c2h_trfr_done.delete();
  h2c_host_done.delete();
  h2c_bytes.delete();
  c2h_bytes.delete();
  h2c_user_data.delete();

  // -- Progress watchdog ------------------------------------------------------
  // Fires if no DMA TLP arrives for STALL_LIMIT after DMA has started.
  // Intended to catch DUT stalls mid-transfer without waiting for SIM_TIMEOUT.
  fork
    begin : DMA_PROGRESS_WATCHDOG
      wait (dma_started);          // idle until first TLP  - don't fire during CDO/link phase
      forever begin
        #(STALL_LIMIT);
        if (!test_done && ($time - last_tlp_time) >= STALL_LIMIT) begin
          dump_progress_snapshot("DMA_WATCHDOG");
          `uvm_fatal("DMA_WATCHDOG",
            $sformatf("No DMA TLP progress for %0t (last TLP at %0t, now %0t). qid_cmp_cnt=%0d/%0d. DUT stalled  - check descriptor fetch, credits, or irq_en.",
                      STALL_LIMIT, last_tlp_time, $time, qid_cmp_cnt, qid_in_test))
        end
      end
    end
  join_none

  // -- Completion progress watchdog -------------------------------------------
  // Catches stalls where TLPs are still flowing (error writebacks, descriptor
  // re-reads) but no queue is making forward progress (qid_cmp_cnt frozen).
  // Without this, a DUT error loop can spin for the full SIM_TIMEOUT.
  fork
    begin : DMA_COMPLETION_WATCHDOG
      integer      last_cmp_cnt;
      int unsigned last_wb_cnt;
      time         last_cmp_time;
      time         last_wb_time;
      wait (dma_started);
      last_cmp_cnt  = qid_cmp_cnt;
      last_wb_cnt   = wb_mwr_count;
      last_cmp_time = $time;
      last_wb_time  = $time;
      forever begin
        #(STALL_LIMIT);
        if (test_done) break;
        // Writebacks drain serially, so a run can legitimately go longer
        // than STALL_LIMIT between QUEUE completions while they still
        // advance steadily -- track that separately from qid_cmp_cnt.
        if (wb_mwr_count != last_wb_cnt) begin
          last_wb_cnt  = wb_mwr_count;
          last_wb_time = $time;
        end
        if (qid_cmp_cnt != last_cmp_cnt) begin
          last_cmp_cnt  = qid_cmp_cnt;
          last_cmp_time = $time;
        end else if (qid_cmp_cnt > 0 && qid_cmp_cnt < qid_in_test &&
                     ($time - last_cmp_time) >= STALL_LIMIT &&
                     ($time - last_wb_time)  >= STALL_LIMIT) begin
          // Only fatal when BOTH are static: no queue completed AND no
          // writeback landed for a full window. That is a genuine stall,
          // not a slow drain.
          dump_progress_snapshot("DMA_CMP_WATCHDOG");
          `uvm_fatal("DMA_CMP_WATCHDOG",
            $sformatf("No DMA completion progress for %0t AND no descriptor writeback for %0t. qid_cmp_cnt=%0d/%0d (last advance at %0t), wb_mwr_count=%0d (last at %0t). Error loop or descriptor stall suspected.",
                      STALL_LIMIT, STALL_LIMIT, qid_cmp_cnt, qid_in_test,
                      last_cmp_time, wb_mwr_count, last_wb_time))
        end else if (qid_cmp_cnt > 0 && qid_cmp_cnt < qid_in_test &&
                     ($time - last_cmp_time) >= STALL_LIMIT) begin
          // Held off ONLY because writebacks are still landing. Say so
          // loudly -- a silent hold-off would turn a real hang into an
          // unexplained timeout at SIM_TIMEOUT with no breadcrumb.
          `uvm_warning("DMA_CMP_WATCHDOG",
            $sformatf("No QUEUE completion for %0t (qid_cmp_cnt=%0d/%0d, last advance at %0t), but descriptor writebacks ARE still advancing (wb_mwr_count=%0d, last at %0t) - watchdog HELD OFF, transfer still pending. Raise +DMA_STALL_TIMEOUT if the drain needs longer than SIM_TIMEOUT allows.",
                      STALL_LIMIT, qid_cmp_cnt, qid_in_test, last_cmp_time,
                      wb_mwr_count, last_wb_time))
        end
      end
    end
    begin : DMA_PROGRESS_CHECKPOINT
      wait (dma_started);
      forever begin
        #(PROGRESS_INTERVAL);
        if (test_done) break;
        dump_progress_snapshot($sformatf("periodic_%0t", $time));
      end
    end
  join_none

  forever begin
    // Wake up when at least one request arrives
    dma_trfr_bus.req_ev.wait_trigger();
    // Drain all queued requests (handles back-to-back arrivals)
    while (dma_trfr_bus.req_mbx.try_get(tr)) begin
      host_addr     = tr.addr[31:0];
      bytes_this_tlp = longint'(tr.length_dw) * 4;
      exp_bytes      = (total_dsc_cnt > 0) ? longint'(total_dsc_cnt) * DMA_BYTE_CNT
                                           : longint'(pidx) * DMA_BYTE_CNT;
      // Update watchdog state on every TLP
      if (!dma_started)
        dma_first_tlp_time = $time;
      dma_started  = 1;
      last_tlp_time = $time;

      case (tr.dma_pkt_type)

        // -- MRD: H2C descriptor fetch or H2C data DMA ----------------------
        host_req_tr::MRD: begin

          // -- H2C descriptor fetch -----------------------------------------
          if (tr.addr >= H2C_DSC_ADDR &&
              tr.addr <  H2C_DSC_ADDR + HOST_DSC_MEM_SIZE) begin
            // Derive qid from descriptor ring offset:
            // each queue occupies RING_SIZE * QDMA_DSC_SZ bytes in the ring area
            int dsc_qid = int'((tr.addr - H2C_DSC_ADDR) /
                               (longint'(RING_SIZE) * QDMA_DSC_SZ));
            int unsigned dsc_this_tlp = (QDMA_DSC_SZ > 0) ? (bytes_this_tlp / QDMA_DSC_SZ) : 0;
            h2c_dsc_fetch_bytes[dsc_qid] += bytes_this_tlp;
            h2c_dsc_fetch_cnt[dsc_qid]   += dsc_this_tlp;
            log_event("H2C_DSC_FETCH", dsc_qid, tr.addr,
                      bytes_this_tlp, 0, 0, 0, "");
            `uvm_info("DMA_SCOREBOARD",
              $sformatf("dsc fetch detected for qid=%0d, number of bytes=%0d, number of descripters fetched=%0d",
                         dsc_qid, h2c_dsc_fetch_bytes[dsc_qid], h2c_dsc_fetch_cnt[dsc_qid]), UVM_MEDIUM)

          // -- C2H descriptor fetch -----------------------------------------
          end else if (tr.addr >= C2H_DSC_ADDR &&
                       tr.addr <  C2H_DSC_ADDR + HOST_DSC_MEM_SIZE) begin
            int dsc_qid = int'((tr.addr - C2H_DSC_ADDR) /
                               (longint'(RING_SIZE) * QDMA_DSC_SZ));
            int unsigned dsc_this_tlp = (QDMA_DSC_SZ > 0) ? (bytes_this_tlp / QDMA_DSC_SZ) : 0;
            c2h_dsc_fetch_bytes[dsc_qid] += bytes_this_tlp;
            c2h_dsc_fetch_cnt[dsc_qid]   += dsc_this_tlp;
            log_event("C2H_DSC_FETCH", dsc_qid, tr.addr,
                      bytes_this_tlp, 0, 0, 0, "");
            `uvm_info("DMA_SCOREBOARD",
              $sformatf("dsc fetch detected for qid=%0d, number of bytes=%0d, number of descripters fetched=%0d",
                         dsc_qid, c2h_dsc_fetch_bytes[dsc_qid], c2h_dsc_fetch_cnt[dsc_qid]), UVM_MEDIUM)

          // -- H2C data DMA read --------------------------------------------
          end else if (tr.addr >= H2C_DAT_SRC_ADDR &&
                       tr.addr <  H2C_DAT_SRC_ADDR + H2C_DAT_SIZE) begin
            h2c_qid = host_addr[$clog2(DMA_BYTE_CNT)+:$bits(h2c_qid)];
            if (!h2c_cnt.exists(h2c_qid) || h2c_cnt[h2c_qid] == 0)
              h2c_first_tlp_time[h2c_qid] = $time;
            h2c_last_tlp_time[h2c_qid] = $time;
            h2c_cnt[h2c_qid]++;
            h2c_bytes[h2c_qid] += bytes_this_tlp;

            log_event("H2C_DMA", int'(h2c_qid), tr.addr,
                      bytes_this_tlp, h2c_bytes[h2c_qid], exp_bytes,
                      h2c_cnt[h2c_qid], "");
            `uvm_info("DMA_SCOREBOARD",
              $sformatf("H2C DMA RD detected for qid=%0d, number of bytes=%0d",
                         h2c_qid, h2c_bytes[h2c_qid]), UVM_MEDIUM)

            // Completion: all pidx*DMA_BYTE_CNT bytes read from host memory
            // drives qid_cmp_cnt.
            if (h2c_bytes[h2c_qid] == exp_bytes && !h2c_host_done.exists(h2c_qid)) begin
              h2c_host_done[h2c_qid] = 1'b1;
              if (!dma_st) begin
                // MM mode: no PL-side AXI-Stream  -- complete on host-side MRD byte-count
                qid_cmp_cnt++;
                h2c_trfr_done[h2c_qid] = 1'b1;
                `uvm_info("DMA_SCOREBOARD",
                  $sformatf("H2C byte-count PASS qid=%0d bytes=%0d (TLPs=%0d) source=host PCIe MRD accumulation qid_cmp_cnt=%0d/%0d",
                             h2c_qid, h2c_bytes[h2c_qid], h2c_cnt[h2c_qid],
                             qid_cmp_cnt, qid_in_test), UVM_NONE)
                log_event("H2C_DONE", int'(h2c_qid), tr.addr,
                          0, h2c_bytes[h2c_qid], exp_bytes, h2c_cnt[h2c_qid],
                          $sformatf("source=host_PCIe_MRD qid_cmp_cnt=%0d/%0d PASS", qid_cmp_cnt, qid_in_test));
              end else begin
                // ST mode: host-side bytes complete  -- PL-side AXI-Stream drives qid_cmp_cnt
                `uvm_info("DMA_SCOREBOARD",
                  $sformatf("H2C host-side MRD done qid=%0d bytes=%0d (TLPs=%0d)  -- awaiting PL-side AXI-Stream data for qid_cmp_cnt",
                             h2c_qid, h2c_bytes[h2c_qid], h2c_cnt[h2c_qid]), UVM_NONE)
                log_event("H2C_HOST_DONE", int'(h2c_qid), tr.addr,
                          0, h2c_bytes[h2c_qid], exp_bytes, h2c_cnt[h2c_qid],
                          "host-side MRD bytes complete, PL-side pending");
              end
            end

          // -- Unknown MRD --------------------------------------------------
          end else begin
            log_event("UNKNOWN_MRD", -1, tr.addr,
                      bytes_this_tlp, 0, 0, 0,
                      "address outside all known host regions");
          end
        end

        // -- MWR: C2H data DMA write -----------------------------------------
        host_req_tr::MWR: begin
          // Identify the destination queue by matching tr.addr against every
          // registered per-queue base address.  This is correct for multi-queue
          // and multi-function tests where each queue has a distinct C2H dest
          // window computed at runtime by the test (C2H_DAT_DST_ADDR with qid
          // encoded in bits [$clog2(DMA_BYTE_CNT)+10 : $clog2(DMA_BYTE_CNT)]).
          // The package-level C2H_DAT_DST_ADDR constant is a single-queue base
          // and does NOT cover all queues, so we do not use it here.
          begin
            bit matched;
            bit [10:0] matched_qid;
            matched = 0;
            foreach (c2h_dst_base[q]) begin
              if (tr.addr >= c2h_dst_base[q] &&
                  tr.addr <  c2h_dst_base[q] + DMA_BYTE_CNT) begin
                matched     = 1;
                matched_qid = q;
                break;
              end
            end

            if (matched) begin
              c2h_qid = matched_qid;
              if (!c2h_cnt.exists(c2h_qid) || c2h_cnt[c2h_qid] == 0)
                c2h_first_tlp_time[c2h_qid] = $time;
              c2h_last_tlp_time[c2h_qid] = $time;
              c2h_cnt[c2h_qid]++;
              c2h_bytes[c2h_qid] += bytes_this_tlp;

              log_event("C2H_DMA", int'(c2h_qid), tr.addr,
                        bytes_this_tlp, c2h_bytes[c2h_qid], exp_bytes,
                        c2h_cnt[c2h_qid], "");
              `uvm_info("DMA_SCOREBOARD",
                $sformatf("C2H DMA write detected for qid=%0d, number of bytes=%0d",
                           c2h_qid, c2h_bytes[c2h_qid]), UVM_MEDIUM)

              // Completion: all pidx*DMA_BYTE_CNT bytes written
              if (c2h_bytes[c2h_qid] == exp_bytes && !c2h_trfr_done[c2h_qid]) begin
                qid_cmp_cnt++;
                c2h_trfr_done[c2h_qid] = 1'b1;
                `uvm_info("DMA_SCOREBOARD",
                  $sformatf("C2H byte-count PASS qid=%0d bytes=%0d (TLPs=%0d) source=host PCIe MWR accumulation qid_cmp_cnt=%0d/%0d",
                             c2h_qid, c2h_bytes[c2h_qid], c2h_cnt[c2h_qid],
                             qid_cmp_cnt, qid_in_test), UVM_NONE)
                log_event("C2H_DONE", int'(c2h_qid), tr.addr,
                          0, c2h_bytes[c2h_qid], exp_bytes, c2h_cnt[c2h_qid],
                          $sformatf("source=host_PCIe_MWR qid_cmp_cnt=%0d/%0d PASS", qid_cmp_cnt, qid_in_test));
              end

            // -- MSI-X interrupt MWR ---------------------------------------
            // The DUT sends a PCIe MWr to the host MSI-X vector table entry
            // after each queue completion.  Address format programmed by
            // TSK_PROGRAM_MSIX_VEC_TABLE:
            //   msix_host_base = H2C_DAT_SRC_ADDR + H2C_DAT_SIZE  (= 0x000B_1000)
            //   addr[31:0]  = msix_host_base + vec*4  (vec = 1 for H2C, 2 for C2H)
            //   addr[63:32] = 0 (fixed; addr_hi is always 0 for 32-bit MSI-X)
            //   data[31:0]  = 0xFACE0000 + vec  (programmed by TSK_PROGRAM_MSIX_VEC_TABLE line: data = 32'hFACE0000 + i)
            // MSI-X address verified (vec from addr offset); data matches programmed vector table value.
            end else if (tr.addr >= (H2C_DAT_SRC_ADDR + H2C_DAT_SIZE) &&
                         tr.addr <  (H2C_DAT_SRC_ADDR + H2C_DAT_SIZE + 7*4)) begin
              int msix_vec;
              bit [31:0] exp_data, got_data;
              msix_vec = int'((tr.addr[31:0] - (H2C_DAT_SRC_ADDR[31:0] + H2C_DAT_SIZE)) >> 2);
              if      (msix_vec == 1) h2c_msix_cnt++;
              else if (msix_vec == 2) c2h_msix_cnt++;
              // Verify MSI-X data payload matches value programmed by TSK_PROGRAM_MSIX_VEC_TABLE.
              exp_data = 32'hFACE0000 + msix_vec;
              got_data = (tr.data.size() > 0) ? tr.data[0] : 32'hDEAD_BEEF;
              if (got_data !== exp_data)
                `uvm_error("DMA_SCOREBOARD",
                  $sformatf("MSI-X DATA MISMATCH: vec=%0d addr=0x%0h got=0x%08h exp=0x%08h",
                            msix_vec, tr.addr, got_data, exp_data))
              else
                `uvm_info("DMA_SCOREBOARD",
                  $sformatf("MSI-X PASS: vec=%0d addr=0x%0h data=0x%08h (correct)",
                            msix_vec, tr.addr, got_data), UVM_HIGH)
              log_event("MSIX_MWR", -1, tr.addr,
                        bytes_this_tlp, 0, 0, 0,
                        $sformatf("MSI-X interrupt MWr vec=%0d data=0x%08h exp=0x%08h %s",
                                  msix_vec, got_data, exp_data,
                                  (got_data === exp_data) ? "(PASS)" : "(DATA MISMATCH)"));

            // -- Descriptor ring writeback MWR -----------------------------
            // QDMA DMA engine writes CIDX/status back into the H2C or C2H
            // descriptor ring in host memory after completing descriptors.
            // Per-slot address check: the WBI status descriptor must land at
            // dsc_base + (RING_SIZE-1)*QDMA_DSC_SZ (the last slot of the ring).
            // A C2H WB at the H2C base is the reg_space.sv:1509 read-mux bug.
            end else if (tr.addr >= H2C_DSC_ADDR &&
                         tr.addr <  H2C_DSC_ADDR + HOST_DSC_MEM_SIZE) begin
              begin
                // Derive H2C QID from address offset in the ring array
                int wb_dsc_qid;
                longint unsigned wb_dsc_base;
                longint unsigned wb_exp_addr;
                string wb_extra;
                wb_dsc_qid  = int'((tr.addr - H2C_DSC_ADDR) /
                                   (longint'(RING_SIZE) * QDMA_DSC_SZ));
                wb_dsc_base = H2C_DSC_ADDR + longint'(wb_dsc_qid) *
                              longint'(RING_SIZE) * QDMA_DSC_SZ;
                wb_exp_addr = wb_dsc_base + longint'(RING_SIZE - 1) * QDMA_DSC_SZ;
                // Record first WB MWr address for this H2C QID
                if (!h2c_wb_mwr_addr.exists(11'(wb_dsc_qid)))
                  h2c_wb_mwr_addr[11'(wb_dsc_qid)] = tr.addr;
                // Capture WB status PIDX/CIDX from TLP payload (PG302 Table 10):
                //   DWord 0 bits[31:16] = cidx, DWord 1 bits[15:0] = pidx
                if (tr.data.size() >= 2) begin
                  h2c_wb_status_cidx[11'(wb_dsc_qid)] = tr.data[0][31:16];
                  h2c_wb_status_pidx[11'(wb_dsc_qid)] = tr.data[1][15:0];
                end
                if (tr.addr == wb_exp_addr) begin
                  wb_extra = $sformatf("H2C WB_SLOT OK qid=%0d addr=0x%0h == exp=0x%0h",
                                       wb_dsc_qid, tr.addr, wb_exp_addr);
                end else begin
                  h2c_wb_addr_err_cnt++;
                  wb_extra = $sformatf("H2C WB_SLOT ERR qid=%0d addr=0x%0h exp=0x%0h",
                                       wb_dsc_qid, tr.addr, wb_exp_addr);
                  `uvm_error("DMA_SCOREBOARD",
                    $sformatf("H2C WB address mismatch: qid=%0d got=0x%0h exp=0x%0h (dsc_base=0x%0h + (RING_SIZE-1)*DSC_SZ=0x%0h) -- WB landed at wrong slot",
                              wb_dsc_qid, tr.addr, wb_exp_addr,
                              wb_dsc_base, longint'(RING_SIZE-1)*QDMA_DSC_SZ))
                end
                wb_mwr_count++;   // watchdog: writeback IS pending transfer work
                log_event("DSC_WB_MWR", wb_dsc_qid, tr.addr,
                          bytes_this_tlp, 0, 0, 0, wb_extra);
              end
            end else if (tr.addr >= C2H_DSC_ADDR &&
                         tr.addr <  C2H_DSC_ADDR + HOST_DSC_MEM_SIZE) begin
              begin
                // Derive C2H QID from address offset in the ring array
                int wb_dsc_qid;
                longint unsigned wb_dsc_base;
                longint unsigned wb_exp_addr;
                string wb_extra;
                wb_dsc_qid  = int'((tr.addr - C2H_DSC_ADDR) /
                                   (longint'(RING_SIZE) * QDMA_DSC_SZ));
                wb_dsc_base = C2H_DSC_ADDR + longint'(wb_dsc_qid) *
                              longint'(RING_SIZE) * QDMA_DSC_SZ;
                wb_exp_addr = wb_dsc_base + longint'(RING_SIZE - 1) * QDMA_DSC_SZ;
                // Record first WB MWr address for this C2H QID
                if (!c2h_wb_mwr_addr.exists(11'(wb_dsc_qid)))
                  c2h_wb_mwr_addr[11'(wb_dsc_qid)] = tr.addr;
                // Capture WB status PIDX/CIDX from TLP payload (PG302 Table 10):
                //   DWord 0 bits[31:16] = cidx, DWord 1 bits[15:0] = pidx
                if (tr.data.size() >= 2) begin
                  c2h_wb_status_cidx[11'(wb_dsc_qid)] = tr.data[0][31:16];
                  c2h_wb_status_pidx[11'(wb_dsc_qid)] = tr.data[1][15:0];
                end
                if (tr.addr == wb_exp_addr) begin
                  wb_extra = $sformatf("C2H WB_SLOT OK qid=%0d addr=0x%0h == exp=0x%0h",
                                       wb_dsc_qid, tr.addr, wb_exp_addr);
                end else begin
                  c2h_wb_addr_err_cnt++;
                  wb_extra = $sformatf("C2H WB_SLOT ERR qid=%0d addr=0x%0h exp=0x%0h",
                                       wb_dsc_qid, tr.addr, wb_exp_addr);
                  `uvm_error("DMA_SCOREBOARD",
                    $sformatf("C2H WB address mismatch: qid=%0d got=0x%0h exp=0x%0h (C2H dsc_base=0x%0h + (RING_SIZE-1)*DSC_SZ=0x%0h) -- C2H WB may have used H2C dsc_base",
                              wb_dsc_qid, tr.addr, wb_exp_addr,
                              wb_dsc_base, longint'(RING_SIZE-1)*QDMA_DSC_SZ))
                end
                wb_mwr_count++;   // watchdog: writeback IS pending transfer work
                log_event("DSC_WB_MWR", wb_dsc_qid, tr.addr,
                          bytes_this_tlp, 0, 0, 0, wb_extra);
              end

            // -- Unknown MWR ------------------------------------------------
            end else begin
              log_event("UNKNOWN_MWR", -1, tr.addr,
                        bytes_this_tlp, 0, 0, 0,
                        "address not registered in any known host region");
            end
          end
        end

      endcase

      if ((qid_cmp_cnt > 0) && (qid_cmp_cnt == qid_in_test) && !wb_drain_spawned) begin
        wb_drain_spawned = 1;
        dma_last_done_time = $time;
        // wb_req_cnt/wb_pipeline_done_cnt never get incremented in this env
        // (no RTL-signal monitor feeds them): both counters stay at 0 for
        // the whole run, so the drain-wait this replaces was a silent
        // no-op, and only a
        // fixed #1us margin ever ran. The writeback TLP for a given qid trails
        // that qid's own data completion by the DMA engine's internal
        // completion-sequencing latency. Because this check fires once,
        // globally, when the LAST qid's byte count completes, whichever qid
        // happens to finish last has the least margin before this point -- if
        // that margin is under the WB's own trailing latency, its WB address
        // has not landed yet and is misreported as missing.
        //
        // Use the PCIe-TLP-level WB capture (h2c/c2h_wb_mwr_addr, populated
        // directly from observed MWr TLPs and already relied on elsewhere in
        // this file) as the real drain-detection signal: wait until every qid
        // counted as byte-count-complete also has its WB address captured,
        // bounded so a genuine RTL/DUT WB failure still reports as a real
        // error below instead of hanging.
        //
        // Forked with join_none: h2c/c2h_wb_mwr_addr are populated by this SAME
        // while(try_get(tr)) loop's case-statement body above, so a blocking
        // wait here would stall the only process draining dma_trfr_bus.req_mbx,
        // causing a false "MISSING" for any WB MWr TLP arriving while waiting.
        // Forking lets
        // this loop keep draining the mailbox concurrently with the wait.
        fork
          begin
            time wb_drain_start = $time;
            bit  wb_drain_done;
            do begin
              wb_drain_done = 1;
              if (h2c_trfr_done.size() > 0) begin
                bit [10:0] wq;
                if (h2c_trfr_done.first(wq)) do
                  if (!h2c_wb_mwr_addr.exists(wq)) wb_drain_done = 0;
                while (h2c_trfr_done.next(wq));
              end
              if (c2h_trfr_done.size() > 0) begin
                bit [10:0] wq;
                if (c2h_trfr_done.first(wq)) do
                  if (!c2h_wb_mwr_addr.exists(wq)) wb_drain_done = 0;
                while (c2h_trfr_done.next(wq));
              end
              if (!wb_drain_done) begin
                if (($time - wb_drain_start) > WB_DRAIN_TIMEOUT) begin
                  `uvm_warning("dma_req_processor",
                    "WB drain wait exceeded WB_DRAIN_TIMEOUT -- proceeding; any qid still missing its WB capture will report as a genuine WB address/status MISSING error below.")
                  break;
                end
                #100ns;
              end
            end while (!wb_drain_done);
            #1us; // settle margin, unchanged
            `uvm_info("dma_req_processor",
              $sformatf("qid_cmp_cnt:%0d, qid_in_test:%0d, wb_req_cnt:%0d, wb_pipeline_done_cnt:%0d",
                         qid_cmp_cnt, qid_in_test, wb_req_cnt, wb_pipeline_done_cnt), UVM_NONE)
            test_done = 1;
            done_ev.trigger();
          end
        join_none
      end
    end
  end
  endtask

  // --- report_phase -----------------------------------------------------------
  function void report_phase(uvm_phase phase);
    bit [10:0] qid;
    int h2c_pf, h2c_vf, c2h_pf, c2h_vf;
    longint unsigned exp_bytes;
    h2c_pf = 0; h2c_vf = 0; c2h_pf = 0; c2h_vf = 0;
    exp_bytes = (total_dsc_cnt > 0) ? longint'(total_dsc_cnt) * DMA_BYTE_CNT
                                    : longint'(pidx) * DMA_BYTE_CNT;

    if (h2c_trfr_done.first(qid)) begin
      do begin
        if (qid < 32) h2c_pf++;
        else          h2c_vf++;
      end while (h2c_trfr_done.next(qid));
    end
    if (c2h_trfr_done.first(qid)) begin
      do begin
        if (qid < 32) c2h_pf++;
        else          c2h_vf++;
      end while (c2h_trfr_done.next(qid));
    end

    // -- Console summary -------------------------------------------------------
    `uvm_info("dma_req_processor", $sformatf(
      "DMA completion summary: H2C PF=%0d VF=%0d | C2H PF=%0d VF=%0d | total=%0d/%0d pidx=%0d DMA_BYTE_CNT=%0d exp_bytes_per_q=%0d",
      h2c_pf, h2c_vf, c2h_pf, c2h_vf, qid_cmp_cnt, qid_in_test,
      pidx, DMA_BYTE_CNT, exp_bytes), UVM_NONE)

    if (h2c_trfr_done.size() > 0)
      `uvm_info("DMA_SCOREBOARD",
        $sformatf("H2C byte-count: all %0d queue(s) PASSED (%0d bytes/queue, source=%s)",
                   h2c_trfr_done.size(), exp_bytes,
                   dma_st ? "PL-side AXI-Stream" : "host PCIe MRD accumulation"), UVM_NONE)

    if (c2h_trfr_done.size() > 0)
      `uvm_info("DMA_SCOREBOARD",
        $sformatf("C2H byte-count: all %0d queue(s) PASSED (%0d bytes/queue, source=host PCIe MWR accumulation; AXI-PL reported separately)",
                   c2h_trfr_done.size(), exp_bytes), UVM_NONE)

    // Condition 2b: H2C user-side data integrity
    // In ST mode (dma_st=1), H2C data MUST appear on the AXI4-Stream interface.
    // In MM mode (dma_st=0), user-side data is not expected (no ST output port).
    if (h2c_integrity_err_cnt > 0)
      `uvm_error("DMA_SCOREBOARD",
        $sformatf("H2C data integrity: TOTAL FAILURES = %0d byte mismatches", h2c_integrity_err_cnt))
    else if (h2c_user_pkt_cnt > 0)
      `uvm_info("DMA_SCOREBOARD",
        $sformatf("H2C data integrity: all %0d queue(s) PASSED (%0d packets received)",
                   h2c_trfr_done.size(), h2c_user_pkt_cnt), UVM_NONE)
    else if (dma_st && h2c_host_done.size() > 0)
      `uvm_error("DMA_SCOREBOARD",
        $sformatf("H2C ST data FAIL: %0d queue(s) completed host-side MRD but 0 packets received on PL-side AXI-Stream interface",
                   h2c_host_done.size()))

    // Condition 3b: Per-slot WB destination-address check.
    // Verifies that each WB MWr TLP landed at the correct last-slot address
    // (dsc_base + (RING_SIZE-1)*QDMA_DSC_SZ) for each completed queue.
    // Detects the reg_space.sv:1509 C2H WB→H2C_base bug: a C2H WB will
    // be decoded as landing inside the H2C ring and will produce a UVM_ERROR
    // at the slot-address check above (c2h_wb_addr_err_cnt > 0).
    begin
      bit wb_addr_pass;
      wb_addr_pass = (h2c_wb_addr_err_cnt == 0) && (c2h_wb_addr_err_cnt == 0);

      // Per-QID H2C WB address summary
      if (h2c_trfr_done.size() > 0) begin
        bit [10:0] wq;
        if (h2c_trfr_done.first(wq)) begin
          do begin
            longint unsigned wb_dsc_base, wb_exp;
            wb_dsc_base = H2C_DSC_ADDR + longint'(wq) * RING_SIZE * QDMA_DSC_SZ;
            wb_exp      = wb_dsc_base + longint'(RING_SIZE - 1) * QDMA_DSC_SZ;
            if (!h2c_wb_mwr_addr.exists(wq)) begin
              `uvm_error("DMA_SCOREBOARD",
                $sformatf("H2C WB address MISSING: qid=%0d no WB MWr TLP seen in H2C ring (exp=0x%0h) -- WB write may have been directed to wrong address",
                           wq, wb_exp))
              wb_addr_pass = 0;
            end else if (h2c_wb_mwr_addr[wq] != wb_exp) begin
              // Already emitted UVM_ERROR inline; just count here
              wb_addr_pass = 0;
            end else begin
              `uvm_info("DMA_SCOREBOARD",
                $sformatf("H2C WB address PASS: qid=%0d addr=0x%0h == exp=0x%0h",
                           wq, h2c_wb_mwr_addr[wq], wb_exp), UVM_NONE)
            end
          end while (h2c_trfr_done.next(wq));
        end
      end

      // Per-QID C2H WB address summary
      if (c2h_trfr_done.size() > 0) begin
        bit [10:0] wq;
        if (c2h_trfr_done.first(wq)) begin
          do begin
            longint unsigned wb_dsc_base, wb_exp;
            wb_dsc_base = C2H_DSC_ADDR + longint'(wq) * RING_SIZE * QDMA_DSC_SZ;
            wb_exp      = wb_dsc_base + longint'(RING_SIZE - 1) * QDMA_DSC_SZ;
            if (!c2h_wb_mwr_addr.exists(wq)) begin
              `uvm_error("DMA_SCOREBOARD",
                $sformatf("C2H WB address MISSING: qid=%0d no WB MWr TLP seen in C2H ring (exp=0x%0h) -- C2H WB may have been routed to H2C base by incorrect reg_space read-mux selection",
                           wq, wb_exp))
              wb_addr_pass = 0;
            end else if (c2h_wb_mwr_addr[wq] != wb_exp) begin
              // Already emitted UVM_ERROR inline; just count here
              wb_addr_pass = 0;
            end else begin
              `uvm_info("DMA_SCOREBOARD",
                $sformatf("C2H WB address PASS: qid=%0d addr=0x%0h == exp=0x%0h",
                           wq, c2h_wb_mwr_addr[wq], wb_exp), UVM_NONE)
            end
          end while (c2h_trfr_done.next(wq));
        end
      end

      if (wb_addr_pass && (h2c_trfr_done.size() + c2h_trfr_done.size() > 0))
        `uvm_info("DMA_SCOREBOARD",
          $sformatf("WB address PASS: all WB MWr TLPs landed at correct last-slot addresses (H2C_errs=%0d C2H_errs=%0d)",
                    h2c_wb_addr_err_cnt, c2h_wb_addr_err_cnt), UVM_NONE)
      else if (h2c_wb_addr_err_cnt > 0 || c2h_wb_addr_err_cnt > 0)
        `uvm_error("DMA_SCOREBOARD",
          $sformatf("WB address FAIL: H2C_slot_errs=%0d C2H_slot_errs=%0d -- see inline UVM_ERROR above",
                    h2c_wb_addr_err_cnt, c2h_wb_addr_err_cnt))
    end

    // Condition 7: WB status PIDX and CIDX.
    // Reads the values the MWr-detection callback above already captured from
    // the writeback TLP payload into h2c_wb_status_cidx/pidx (h2c/c2h), and
    // requires cidx == pidx from that same captured event.
    begin
      bit wb_sts_pass;
      wb_sts_pass = 1;
      if (h2c_trfr_done.size() > 0) begin
        bit [10:0] wq;
        if (h2c_trfr_done.first(wq)) begin
          do begin
            if (!h2c_wb_status_pidx.exists(wq) || !h2c_wb_status_cidx.exists(wq)) begin
              `uvm_error("DMA_SCOREBOARD",
                $sformatf("H2C WB status MISSING: qid=%0d -- no writeback TLP payload captured for this qid",
                          wq))
              wb_sts_pass = 0;
            end else if (h2c_wb_status_cidx[wq] !== h2c_wb_status_pidx[wq]) begin
              `uvm_error("DMA_SCOREBOARD",
                $sformatf("H2C WB status CIDX MISMATCH: qid=%0d cidx=0x%04h pidx=0x%04h",
                          wq, h2c_wb_status_cidx[wq], h2c_wb_status_pidx[wq]))
              wb_sts_pass = 0;
            end else
              `uvm_info("DMA_SCOREBOARD",
                $sformatf("H2C WB status PASS: qid=%0d cidx=0x%04h == pidx=0x%04h",
                          wq, h2c_wb_status_cidx[wq], h2c_wb_status_pidx[wq]), UVM_NONE)
          end while (h2c_trfr_done.next(wq));
        end
      end
      if (c2h_trfr_done.size() > 0) begin
        bit [10:0] wq;
        if (c2h_trfr_done.first(wq)) begin
          do begin
            if (!c2h_wb_status_pidx.exists(wq) || !c2h_wb_status_cidx.exists(wq)) begin
              `uvm_error("DMA_SCOREBOARD",
                $sformatf("C2H WB status MISSING: qid=%0d -- no writeback TLP payload captured for this qid",
                          wq))
              wb_sts_pass = 0;
            end else if (c2h_wb_status_cidx[wq] !== c2h_wb_status_pidx[wq]) begin
              `uvm_error("DMA_SCOREBOARD",
                $sformatf("C2H WB status CIDX MISMATCH: qid=%0d cidx=0x%04h pidx=0x%04h",
                          wq, c2h_wb_status_cidx[wq], c2h_wb_status_pidx[wq]))
              wb_sts_pass = 0;
            end else
              `uvm_info("DMA_SCOREBOARD",
                $sformatf("C2H WB status PASS: qid=%0d cidx=0x%04h == pidx=0x%04h",
                          wq, c2h_wb_status_cidx[wq], c2h_wb_status_pidx[wq]), UVM_NONE)
          end while (c2h_trfr_done.next(wq));
        end
      end
      if (wb_sts_pass && (h2c_trfr_done.size() + c2h_trfr_done.size() > 0))
        `uvm_info("DMA_SCOREBOARD",
          "WB status PIDX/CIDX PASS: all queues verified via captured writeback TLP payload", UVM_NONE)
    end

    // Condition 4: MSI-X MWr received for every completed queue when irq_en=1
    if (irq_en) begin
      int exp_h2c, exp_c2h;
      exp_h2c = h2c_trfr_done.size();
      exp_c2h = c2h_trfr_done.size();
      // Multi-round dispatch (PIDX > DSC_FETCH_MAX_QID=49) generates multiple
      // ISR cycles per QID, each producing an MSI-X TLP.  Therefore the count
      // can exceed the number of completed queues.  Use >= instead of ==.
      if (h2c_msix_cnt >= exp_h2c && c2h_msix_cnt >= exp_c2h)
        `uvm_info("DMA_SCOREBOARD",
          $sformatf("MSI-X PASS: H2C=%0d/>=%0d  C2H=%0d/>=%0d",
                     h2c_msix_cnt, exp_h2c, c2h_msix_cnt, exp_c2h), UVM_NONE)
      else
        `uvm_error("DMA_SCOREBOARD",
          $sformatf("MSI-X FAIL: H2C=%0d/>=%0d  C2H=%0d/>=%0d",
                     h2c_msix_cnt, exp_h2c, c2h_msix_cnt, exp_c2h))
    end else begin
      `uvm_info("DMA_SCOREBOARD",
        "MSI-X check SKIPPED: irq_en=0", UVM_NONE)
    end

    // -- Log file summary ------------------------------------------------------
    if (log_fd != 0) begin
      $fdisplay(log_fd, "");
      $fdisplay(log_fd, "# -------------------------------------------------------------------------------------------------------------------");
      $fdisplay(log_fd, "# DMA_SCOREBOARD SUMMARY  at %0t", $time);
      $fdisplay(log_fd, "# -------------------------------------------------------------------------------------------------------------------");
      if (total_dsc_cnt > 0)
        $fdisplay(log_fd, "#   pidx=%0d  total_dsc_cnt=%0d  refill_threshold=%0d  DMA_BYTE_CNT=%0d  exp_bytes_per_queue=%0d",
                  pidx, total_dsc_cnt, refill_threshold, DMA_BYTE_CNT, exp_bytes);
      else
        $fdisplay(log_fd, "#   pidx=%0d  DMA_BYTE_CNT=%0d  exp_bytes_per_queue=%0d",
                  pidx, DMA_BYTE_CNT, exp_bytes);
      $fdisplay(log_fd, "#   Queues completed : %0d / %0d", qid_cmp_cnt, qid_in_test);
      $fdisplay(log_fd, "#   H2C queues done  : PF=%0d  VF=%0d  (total=%0d)",
                h2c_pf, h2c_vf, h2c_trfr_done.size());
      $fdisplay(log_fd, "#   C2H queues done  : PF=%0d  VF=%0d  (total=%0d)",
                c2h_pf, c2h_vf, c2h_trfr_done.size());

      // Per-queue H2C byte tally
      if (h2c_bytes.first(qid)) begin
        $fdisplay(log_fd, "#   H2C per-queue bytes:");
        do begin
          string status;
          status = h2c_trfr_done.exists(qid) ? "DONE" : "INCOMPLETE";
          $fdisplay(log_fd, "#     qid=%-4d  bytes=%-10d  tlps=%-4d  exp=%-10d  %s",
                    qid, h2c_bytes[qid], h2c_cnt[qid], exp_bytes, status);
        end while (h2c_bytes.next(qid));
      end

      // Per-queue C2H byte tally
      if (c2h_bytes.first(qid)) begin
        $fdisplay(log_fd, "#   C2H per-queue bytes:");
        do begin
          string status;
          status = c2h_trfr_done.exists(qid) ? "DONE" : "INCOMPLETE";
          $fdisplay(log_fd, "#     qid=%-4d  bytes=%-10d  tlps=%-4d  exp=%-10d  %s",
                    qid, c2h_bytes[qid], c2h_cnt[qid], exp_bytes, status);
        end while (c2h_bytes.next(qid));
      end

      if (h2c_integrity_err_cnt > 0)
        $fdisplay(log_fd, "#   H2C data integrity : FAIL  total_mismatches=%0d", h2c_integrity_err_cnt);
      else if (h2c_user_pkt_cnt > 0)
        $fdisplay(log_fd, "#   H2C data integrity : PASS  all %0d queue(s) clean (%0d pkts)",
                  h2c_trfr_done.size(), h2c_user_pkt_cnt);
      else if (dma_st && h2c_host_done.size() > 0)
        $fdisplay(log_fd, "#   H2C data integrity : FAIL  0 packets on PL-side AXI-Stream (ST mode, %0d host-side done)",
                  h2c_host_done.size());

      // Condition 4: MSI-X. Same >= comparison as the console check above
      // (Condition 4 earlier in this function) -- multi-round dispatch can
      // legitimately produce more MSI-X TLPs than completed queues.
      if (irq_en)
        $fdisplay(log_fd, "#   MSI-X MWr         : %s  H2C=%0d/>=%0d  C2H=%0d/>=%0d",
                  (h2c_msix_cnt >= h2c_trfr_done.size() && c2h_msix_cnt >= c2h_trfr_done.size())
                    ? "PASS" : "FAIL",
                  h2c_msix_cnt, h2c_trfr_done.size(),
                  c2h_msix_cnt, c2h_trfr_done.size());
      else
        $fdisplay(log_fd, "#   MSI-X MWr         : SKIPPED (irq_en=0)");

      $fdisplay(log_fd, "# ===================================================================================================================");
      $fflush(log_fd);
    end

  endfunction

endclass
