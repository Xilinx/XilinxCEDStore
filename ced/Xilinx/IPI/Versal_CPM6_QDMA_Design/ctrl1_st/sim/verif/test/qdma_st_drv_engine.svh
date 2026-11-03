// qdma_st_drv_engine.svh - stream DMA driven the way the Linux QDMA driver
// drives it (included inside qdma_base_test).
//
// Selected by +TEST_MODE=DRV_SEQ. Covers PF and VF queues, H2C and C2H,
// prefetch, and both driver notify modes:
//   POLL   - no interrupts; completions found by polling host memory
//   DIRECT - per-function MSI-X; an interrupt on a vector services every queue
//            on that vector (the driver's direct-interrupt mode)
//
// Sequence, as the driver does it:
//   load     : global ring-size, C2H timer, counter, buffer-size tables, C2H
//              interrupt timer tick and completion coalesce config, then the
//              tables are read back
//   q start  : contexts cleared (SW, HW, credit; prefetch and completion for
//              C2H), then SW, prefetch, completion contexts written with the
//              driver's values (its context writer never sets mrkr_dis or
//              port_id, so both stay 0 unless ports are spread on purpose);
//              C2H: completion CIDX register, then the C2H PIDX posting ring
//              size - 1 buffers
//   H2C      : one doorbell per request (descriptors page-split), status
//              writeback polled or interrupt-driven, then the same PIDX
//              rewritten to re-arm
//   C2H      : a completion pass consumes every entry the status pidx covers
//              and writes the completion CIDX; each read then takes one
//              packet, hands its buffers back and writes the C2H PIDX
// C2H buffers are scattered pages at a fixed address per ring index, as the
// driver allocates them. A VF whose version register decodes as a hard IP is
// run in poll mode, as the driver forces it.
//
// Two orders:
//   CONCURRENT - every queue and direction in its own thread; the C2H PIDX is
//                written as the first action of the queue's thread, so no
//                DUT-visible doorbell happens during the serial setup
//   BOARD      - the board procedure, one queue at a time: q start h2c, q start
//                c2h (PIDX written inside start), context dump, the H2C writes,
//                the generator started with the host's register writes and
//                read-backs, the C2H reads, context dump
//
// Judging: the scoreboard checks host writes in arrival order (labelled and
// counted, see drv_chk in dma_req_processor); the engine judges entries and
// payload from the status pidx the scoreboard has processed. After the summary
// the IP error registers and every queue's SW-context error bits are read.
// Register reads not completed within +DRV_MMIO_CTO_NS are completion
// timeouts (the host would hang); register traffic stops at the first one.
// The host commands for the same procedure go to drv_board_cmds.sh and every
// register access to drv_reg_trace.log, for comparison with the board.
//
// Plusargs (defaults in brackets):
//   +DRV_NOTIFY=POLL|DIRECT      [DIRECT if +IRQ_EN=1, else POLL]
//   +DRV_ORDER=CONCURRENT|BOARD  [CONCURRENT]
//   +DRV_QID_BASE=<n>            [0]      first queue index in each function
//   +DRV_STEP_NS=<ns>            [40000]  longest wait for one completion
//   +DRV_IRQ_WAIT_NS=<ns>        [20000]  longest wait for an interrupt
//   +DRV_MMIO_CTO_NS=<ns>        [50000]  register read completion timeout
//   +DRV_RING_IDX=<0..9>         [9]      ring-size table entry (1537, the
//                                          dma-ctl default)
//   +DRV_CMPT_RING_IDX=<0..15>   [next larger entry than the ring]
//   +DRV_H2C_DSC_BYTES=<n>       [4096]   H2C page split
//   +DRV_H2C_DSC_FMT=DRIVER|TB   [DRIVER] H2C descriptor metadata format
//   +DRV_PORT_MODE=SPREAD|DRIVER [SPREAD] DRIVER: every queue on port 0, the
//                                          only port the driver can set
//   +DRV_C2H_POST=<n>            [ring size - 1] buffers posted at start
//   +DRV_C2H_RET_BATCH=<n>       [1]      buffers handed back per PIDX write
//   +DRV_C2H_CONSUME_DELAY_NS=<n>[0]      delay before each completion pass
//   +DRV_DUP_PIDX                         every H2C doorbell written twice
//   +DRV_REARM=REQUEST|ADVANCE   [REQUEST] H2C re-arm doorbell: once per
//                                          request after it retires, or (as the
//                                          driver's poll thread does) the same
//                                          PIDX rewritten at once on every
//                                          status-cidx advance
//   +DRV_BOARD_LOOP                       BOARD order run as the host's repeat
//                                          loop: per iteration one H2C write,
//                                          the generator started for one
//                                          packet, one C2H read (PIDX
//                                          iterations on the same queue)
//   +DRV_ITER_GAP_NS=<n>         [0]      idle time before each loop iteration
//   +DRV_NUM_REQ=<n>             [+PIDX]  requests per queue (read by the test,
//                                          which resolves +PIDX from it)
//   +DRV_H2C_SIZES=<a,b,...>     [DMA_BYTE_CNT] H2C request sizes in bytes,
//                                          used in turn (each <= DMA_BYTE_CNT,
//                                          the source buffer size)
//   +DRV_GEN_READS=<0|1>         [1 in BOARD order, else 0] generator
//                                          read-backs of the board procedure
//   +DRV_GLBL_TBL_SKIP=<mask>    [0]      skip global writes: 1 ring sizes,
//                                         2 counters, 4 timers, 8 buffer
//                                         sizes, 16 tick + coalesce
//   +C2H_PFCH_EN=<0|1>           [1]      prefetch context pfch_en
//   +DRV_CHK_WARN, +DRV_TEST_INJECT       see dma_req_processor

typedef enum int { DRV_POLL = 1, DRV_DIRECT = 2 } drv_notify_e;

typedef struct {
  drv_notify_e notify;
  bit          board;
  int          qid_base;
  int          step_ns;
  int          hang_ns;
  int          irq_wait_ns;
  int          mmio_cto_ns;
  int          ring_idx;
  int          cmpt_ring_idx;
  int          h2c_dsc_bytes;
  bit          h2c_fmt_tb;
  bit          port_driver;
  int          c2h_post;
  int          ret_batch;
  int          consume_delay_ns;
  bit          dup_pidx;
  bit          gen_reads;
  int          glbl_skip;
  bit          pfch_en;
  int          n_req;
  bit          rearm_adv;
  bit          board_loop;
  int          iter_gap_ns;
  bit          loop_continue;
  bit          dbg_snap;
} drv_cfg_t;

typedef struct {
  int           fnc;
  bit           is_pf;
  bit [7:0]     pfn;
  bit [7:0]     vfn;
  int           rel_qid;
  bit [10:0]    hw_qid;
  int           q_base;
  int           q_count;
  int           bar;
  bit [31:0]    qreg;           // queue doorbell block base (PF 0x18000, VF 0x3000)
  int           port;
  bit           dir_c2h;
  int           vec;
  drv_notify_e  notify;
  bit [63:0]    dsc_base;
  bit [63:0]    wb_addr;        // H2C status writeback
  int           dpr;            // H2C descriptors per request (largest request)
  int           h2c_pidx;       // H2C: last PIDX written
  int           h2c_cum;        // H2C: descriptors submitted
  bit [15:0]    h2c_last_cidx;  // H2C: status cidx at the last re-arm
  int           h2c_req;        // H2C: next request
  bit [63:0]    cmpt_base;
  int           rngsz;          // usable descriptor entries
  int           cmpt_ents;      // completion ring entries incl. status
  int           bufsz;
  int           pkt_bytes;
  int           dpp;            // C2H buffers per packet
  int           posted;         // buffers posted at queue start
  int           n_items;        // requests (H2C) or packets (C2H)
  int           n_ok;           // retired by the driver's rules
  int           n_full;         // retired and every stricter check passed
  int           irq_seen;
  int unsigned  irq_base;       // MSI-X count of the queue's vector at its last serviced wake
  bit           irq_gap;
  string        gap_tag;
  // C2H run state
  int           pidx_c2h;       // last PIDX written
  int           cidx_c2h;       // next buffer the DMA fills
  int           cidx_cmpt;      // next completion entry
  bit           exp_col;
  int           n_cons;         // completion entries consumed
  int           n_read;         // packets read
  int           ret_pend;       // buffers returned, not yet posted
  int           gen_ptr;        // buffers committed to generator bursts
  int           pkts_req;       // packets requested from the generator
  bit           dead;           // queue stopped (driver would stop it)
  bit           hung;           // stopped by a hang (no new completion), not by an entry error
} drv_q_t;

typedef struct {
  int pkt;
  int buf0;
  int nd;
  int len;
  bit ok;                       // completion entry acceptable to the driver
  bit full;                     // and length / qid as expected
} drv_rd_t;

localparam int DRV_RNG_TBL [16] = '{2049, 65, 129, 193, 257, 385, 513, 769,
                                    1025, 1537, 3073, 4097, 6145, 8193, 12289, 16385};
localparam int DRV_TMR_TBL [16] = '{1, 2, 4, 5, 8, 10, 15, 20, 25, 30, 50, 75, 100, 125, 150, 200};
localparam int DRV_CNT_TBL [16] = '{2, 4, 8, 16, 24, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192};
localparam int DRV_BUF_TBL [16] = '{4096, 256, 512, 1024, 2048, 3968, 4096, 4096,
                                    4096, 4096, 4096, 4096, 4096, 8192, 9018, 16384};
localparam bit [63:0] DRV_C2H_BUF_REGION = 64'h3000_0000;
localparam bit [7:0]  DRV_POISON         = 8'hA5;
localparam bit [31:0] DRV_UNMAPPED       = 32'hBAD_ACCE5;   // read value of an unimplemented register

drv_cfg_t        drv_cfg;
drv_q_t          drv_qs [$];
int              drv_n_live;
int              drv_pl_live;              // H2C PL-side byte checks still running
int              drv_h2c_sizes  [$];        // H2C request sizes, used in turn
bit              drv_glbl_done;
bit              drv_fnc_done   [int];
drv_notify_e     drv_fnc_notify [int];
int              drv_fnc_dvec0  [int];      // first data vector
int              drv_fnc_dvecn  [int];      // number of data vectors
int              drv_vec_load   [int][int];
bit              drv_vec_h2c    [int][int]; // vector carries an H2C queue
longint          drv_c2h_qidx;              // C2H buffer-region index
longint unsigned drv_buf_addr   [int][$];   // per queue: address of buffer i
drv_rd_t         drv_rd_q       [int][$];   // per queue: packets completed, not yet read
int              drv_seg_first  [int][$];   // per queue: first packet of each burst
int              drv_seg_seq    [int][$];   // per queue: burst sequence of each burst
string           drv_q_cmds     [int][$];   // per queue: host commands (generator)
string           drv_pre_cmds   [$];        // host commands before any queue
bit              drv_probe_done [int];      // generator ports already identified
bit              drv_msix_inj_armed;
// Register access (issue_reg_read / issue_reg_write): completion timeout,
// trace; both off (0) outside driver-sequence runs.
int              drv_mmio_cto_ns   = 0;
int              drv_mmio_cto_once = 0;     // one-shot budget for the next read
bit              drv_mmio_dead     = 1'b0;
int              drv_trace_fd      = 0;
int unsigned     drv_trace_seq     = 0;

// One line per register access, in the format of the board capture
function void drv_trace(string rw, bit [31:0] off, bit [31:0] val, bit is_pf, bit [7:0] vfn);
  if (drv_trace_fd == 0) return;
  drv_trace_seq++;
  $fdisplay(drv_trace_fd, "%0d,%0t,%s,%s,0x%08h,0x%08h", drv_trace_seq, $time, rw,
            is_pf ? "PF" : $sformatf("VF%0d", vfn), off, val);
endfunction

//------------------------------------------------------------------------------
// Configuration
//------------------------------------------------------------------------------
task TSK_DRV_CFG_PARSE();
  string s;
  int    v;
  int    irq;
  begin
    irq = 0;
    void'($value$plusargs("IRQ_EN=%d", irq));
    drv_cfg.notify        = (irq != 0) ? DRV_DIRECT : DRV_POLL;
    if ($value$plusargs("DRV_NOTIFY=%s", s)) begin
      if (s == "POLL")        drv_cfg.notify = DRV_POLL;
      else if (s == "DIRECT") drv_cfg.notify = DRV_DIRECT;
      else `uvm_fatal("DRV_SEQ", $sformatf("+DRV_NOTIFY=%s: only POLL and DIRECT exist (no interrupt aggregation in this IP)", s))
    end
    drv_cfg.board            = 1'b0;
    if ($value$plusargs("DRV_ORDER=%s", s)) begin
      if (s == "BOARD")           drv_cfg.board = 1'b1;
      else if (s != "CONCURRENT") `uvm_fatal("DRV_SEQ", $sformatf("+DRV_ORDER=%s: CONCURRENT or BOARD", s))
    end
    drv_cfg.qid_base         = 0;
    drv_cfg.step_ns          = 40000;
    drv_cfg.hang_ns          = 1000000;
    drv_cfg.irq_wait_ns      = 20000;
    drv_cfg.mmio_cto_ns      = 50000;
    drv_cfg.ring_idx         = 9;
    drv_cfg.h2c_dsc_bytes    = 4096;
    drv_cfg.h2c_fmt_tb       = 1'b0;
    drv_cfg.port_driver      = 1'b0;
    drv_cfg.c2h_post         = -1;
    drv_cfg.ret_batch        = 1;
    drv_cfg.consume_delay_ns = 0;
    drv_cfg.dup_pidx         = $test$plusargs("DRV_DUP_PIDX");
    drv_cfg.gen_reads        = drv_cfg.board;
    drv_cfg.glbl_skip        = 0;
    drv_cfg.pfch_en          = 1'b1;
    drv_cfg.n_req            = int'(pidx);
    void'($value$plusargs("DRV_QID_BASE=%d", drv_cfg.qid_base));
    void'($value$plusargs("DRV_STEP_NS=%d", drv_cfg.step_ns));
    void'($value$plusargs("DRV_HANG_NS=%d", drv_cfg.hang_ns));
    if (drv_cfg.hang_ns < drv_cfg.step_ns) drv_cfg.hang_ns = drv_cfg.step_ns;
    void'($value$plusargs("DRV_IRQ_WAIT_NS=%d", drv_cfg.irq_wait_ns));
    void'($value$plusargs("DRV_MMIO_CTO_NS=%d", drv_cfg.mmio_cto_ns));
    void'($value$plusargs("DRV_RING_IDX=%d", drv_cfg.ring_idx));
    void'($value$plusargs("DRV_H2C_DSC_BYTES=%d", drv_cfg.h2c_dsc_bytes));
    void'($value$plusargs("DRV_C2H_POST=%d", drv_cfg.c2h_post));
    void'($value$plusargs("DRV_C2H_RET_BATCH=%d", drv_cfg.ret_batch));
    void'($value$plusargs("DRV_C2H_CONSUME_DELAY_NS=%d", drv_cfg.consume_delay_ns));
    void'($value$plusargs("DRV_GLBL_TBL_SKIP=%d", drv_cfg.glbl_skip));
    if ($value$plusargs("DRV_GEN_READS=%d", v)) drv_cfg.gen_reads = 1'(v);
    if ($value$plusargs("C2H_PFCH_EN=%d", v)) drv_cfg.pfch_en = 1'(v);
    if ($value$plusargs("DRV_H2C_DSC_FMT=%s", s)) drv_cfg.h2c_fmt_tb = (s == "TB");
    if ($value$plusargs("DRV_PORT_MODE=%s", s))   drv_cfg.port_driver = (s == "DRIVER");
    drv_cfg.rearm_adv   = 1'b0;
    if ($value$plusargs("DRV_REARM=%s", s)) begin
      if (s == "ADVANCE")      drv_cfg.rearm_adv = 1'b1;
      else if (s != "REQUEST") `uvm_fatal("DRV_SEQ", $sformatf("+DRV_REARM=%s: REQUEST or ADVANCE", s))
    end
    drv_cfg.board_loop  = $test$plusargs("DRV_BOARD_LOOP");
    if (drv_cfg.board_loop && !drv_cfg.board)
      `uvm_fatal("DRV_SEQ", "+DRV_BOARD_LOOP needs +DRV_ORDER=BOARD")
    drv_cfg.iter_gap_ns = 0;
    void'($value$plusargs("DRV_ITER_GAP_NS=%d", drv_cfg.iter_gap_ns));
    drv_cfg.loop_continue = $test$plusargs("DRV_LOOP_CONTINUE");
    drv_cfg.dbg_snap      = 1'b0;
    if ($value$plusargs("DRV_DBG_SNAP=%d", v)) drv_cfg.dbg_snap = 1'(v);
    drv_h2c_sizes.delete();
    if ($value$plusargs("DRV_H2C_SIZES=%s", s)) begin
      string cur;
      cur = "";
      for (int i = 0; i <= s.len(); i++) begin
        if (i == s.len() || s[i] == ",") begin
          if (cur.len() > 0) drv_h2c_sizes.push_back(cur.atoi());
          cur = "";
        end else cur = {cur, s.substr(i, i)};
      end
      foreach (drv_h2c_sizes[i])
        if (drv_h2c_sizes[i] <= 0 || drv_h2c_sizes[i] > int'(DMA_BYTE_CNT))
          `uvm_fatal("DRV_SEQ", $sformatf("+DRV_H2C_SIZES entry %0d = %0d: each size must be 1..DMA_BYTE_CNT (%0d), the source buffer",
                                           i, drv_h2c_sizes[i], DMA_BYTE_CNT))
        else if (drv_h2c_sizes[i] % 64 != 0)
          `uvm_warning("DRV_SEQ", $sformatf("+DRV_H2C_SIZES entry %0d = %0d is not a multiple of 64 B; the stream length field counts 64 B units",
                                             i, drv_h2c_sizes[i]))
    end
    if (drv_cfg.ret_batch < 1) drv_cfg.ret_batch = 1;
    if (drv_cfg.ring_idx < 0 || drv_cfg.ring_idx > 9)
      `uvm_fatal("DRV_SEQ", $sformatf("+DRV_RING_IDX=%0d: allowed 0..9 (a larger ring's completion ring overruns the per-queue completion-ring spacing)",
                                       drv_cfg.ring_idx))
    // The driver sizes the completion ring with the next larger table entry.
    drv_cfg.cmpt_ring_idx = -1;
    for (int i = 0; i < 16; i++)
      if (DRV_RNG_TBL[i] > DRV_RNG_TBL[drv_cfg.ring_idx] &&
          (drv_cfg.cmpt_ring_idx < 0 || DRV_RNG_TBL[i] < DRV_RNG_TBL[drv_cfg.cmpt_ring_idx]))
        drv_cfg.cmpt_ring_idx = i;
    void'($value$plusargs("DRV_CMPT_RING_IDX=%d", drv_cfg.cmpt_ring_idx));
    if (drv_cfg.cmpt_ring_idx < 0 || drv_cfg.cmpt_ring_idx > 15)
      `uvm_fatal("DRV_SEQ", $sformatf("completion ring index %0d out of range", drv_cfg.cmpt_ring_idx))
    if (DRV_RNG_TBL[drv_cfg.cmpt_ring_idx] * 8 > RING_SIZE * 8)
      `uvm_fatal("DRV_SEQ", $sformatf("completion ring of %0d entries does not fit the per-queue completion-ring spacing (%0d)",
                                       DRV_RNG_TBL[drv_cfg.cmpt_ring_idx], RING_SIZE))
    drv_mmio_cto_ns = drv_cfg.mmio_cto_ns;
    drv_trace_fd    = $fopen("drv_reg_trace.log", "w");
    if (drv_trace_fd != 0)
      $fdisplay(drv_trace_fd, "# seq,time,R|W,function,offset,value -- every register access of the driver-sequence run");
    `uvm_info("DRV_SEQ", $sformatf(
      "config: notify %s, order %s%s, queue index from %0d, ring idx %0d (%0d entries), completion ring idx %0d (%0d entries), %0d requests/packets per queue, H2C page %0d B (%s descriptors), H2C sizes %s, re-arm %s, iteration gap %0d ns%s%s, C2H prefetch %0d, ports %s, return batch %0d, step %0d ns, interrupt wait %0d ns, register completion timeout %0d ns",
      drv_cfg.notify.name(), drv_cfg.board ? "BOARD" : "CONCURRENT", drv_cfg.board_loop ? " (loop)" : "", drv_cfg.qid_base, drv_cfg.ring_idx,
      DRV_RNG_TBL[drv_cfg.ring_idx], drv_cfg.cmpt_ring_idx, DRV_RNG_TBL[drv_cfg.cmpt_ring_idx], drv_cfg.n_req,
      drv_cfg.h2c_dsc_bytes, drv_cfg.h2c_fmt_tb ? "TB" : "driver",
      (drv_h2c_sizes.size() > 0) ? $sformatf("%p", drv_h2c_sizes) : $sformatf("%0d", DMA_BYTE_CNT),
      drv_cfg.rearm_adv ? "on every status advance" : "once per request", drv_cfg.iter_gap_ns,
      drv_cfg.loop_continue ? ", loop continues after a failure" : "", drv_cfg.dbg_snap ? ", debug-bank snapshots" : "", drv_cfg.pfch_en,
      drv_cfg.port_driver ? "all 0" : "spread", drv_cfg.ret_batch, drv_cfg.step_ns, drv_cfg.irq_wait_ns,
      drv_cfg.mmio_cto_ns), UVM_NONE)
  end
endtask

//------------------------------------------------------------------------------
// Driver load: global tables, then read back
//------------------------------------------------------------------------------
task TSK_DRV_GLBL_INIT();
  bit [31:0] rd, depth, coal;
  int        bad;
  begin
    if (drv_glbl_done) return;
    bad = 0;
    // Indirect-context masks all ones, as the driver writes them with every
    // indirect write: function-map writes that follow rely on them.
    for (int i = 0; i < 8; i++) issue_reg_write(PF_DMA_BAR_INDEX, 32'h824 + 4 * i, 32'hFFFF_FFFF);
    if (!drv_cfg.glbl_skip[0])
      for (int i = 0; i < 16; i++) issue_reg_write(PF_DMA_BAR_INDEX, 32'h204 + 4 * i, DRV_RNG_TBL[i]);
    if (!drv_cfg.glbl_skip[1])
      for (int i = 0; i < 16; i++) issue_reg_write(PF_DMA_BAR_INDEX, 32'hA40 + 4 * i, DRV_CNT_TBL[i]);
    if (!drv_cfg.glbl_skip[2])
      for (int i = 0; i < 16; i++) issue_reg_write(PF_DMA_BAR_INDEX, 32'hA00 + 4 * i, DRV_TMR_TBL[i]);
    if (!drv_cfg.glbl_skip[3])
      for (int i = 0; i < 16; i++) issue_reg_write(PF_DMA_BAR_INDEX, 32'hAB0 + 4 * i, DRV_BUF_TBL[i]);
    if (!drv_cfg.glbl_skip[4]) begin
      issue_reg_write(PF_DMA_BAR_INDEX, 32'hB0C, 32'd25);                 // C2H interrupt timer tick
      issue_reg_read(PF_DMA_BAR_INDEX, 32'hBE4, , , , depth);             // coalesce buffer depth
      coal = '0;
      coal[31:26] = depth[5:0];                                            // max buffer size
      coal[25:14] = 12'd25;                                                // tick value
      coal[13:2]  = 12'd5;                                                 // tick count
      issue_reg_write(PF_DMA_BAR_INDEX, 32'hB50, coal);
    end
    // Read the four tables back, as the driver does after writing them
    for (int i = 0; i < 16; i++) begin
      issue_reg_read(PF_DMA_BAR_INDEX, 32'h204 + 4 * i, , , , rd);
      if (!drv_cfg.glbl_skip[0] && rd[15:0] != 16'(DRV_RNG_TBL[i])) bad++;
      issue_reg_read(PF_DMA_BAR_INDEX, 32'hA40 + 4 * i, , , , rd);
      if (!drv_cfg.glbl_skip[1] && rd[15:0] != 16'(DRV_CNT_TBL[i])) bad++;
      issue_reg_read(PF_DMA_BAR_INDEX, 32'hA00 + 4 * i, , , , rd);
      if (!drv_cfg.glbl_skip[2] && rd[15:0] != 16'(DRV_TMR_TBL[i])) bad++;
      issue_reg_read(PF_DMA_BAR_INDEX, 32'hAB0 + 4 * i, , , , rd);
      if (!drv_cfg.glbl_skip[3] && rd[15:0] != 16'(DRV_BUF_TBL[i])) bad++;
    end
    void'(dma_req_proc.drv_chk("DRV_GLBL", bad == 0,
          $sformatf("%0d global table entries read back different from what was written", bad)));
    `uvm_info("DRV_GLBL", $sformatf("global tables written and read back (skip mask 0x%0h, %0d mismatches)",
                                    drv_cfg.glbl_skip, bad), UVM_NONE)
    // The rings now follow the driver's table entry.
    ring_entries               = 32'(DRV_RNG_TBL[drv_cfg.ring_idx]);
    dma_req_proc.ring_entries  = DRV_RNG_TBL[drv_cfg.ring_idx];
    glbl_pgm_done              = 1;
    drv_glbl_done              = 1'b1;
  end
endtask

//------------------------------------------------------------------------------
// Per function: function map, device decode (notify mode, data vectors),
// MSI-X table in DIRECT mode
//------------------------------------------------------------------------------
task TSK_DRV_FNC_INIT(input int fnc, input bit is_pf, input bit [7:0] pfn, input bit [7:0] vfn,
                      input int q_base, input int q_count);
  bit [31:0]   rd;
  drv_notify_e nt;
  int          dvec0;
  begin
    if (drv_fnc_done.exists(fnc)) return;
    if (!fnc_map_pgm_done[8'(fnc)])
      TSK_FNC_MAP_PGM(8'(fnc), 11'(q_base), 12'(q_count));
    nt    = drv_cfg.notify;
    dvec0 = 0;
    if (is_pf) begin
      // GLBL2_MISC_CAP: [31:28] device, [27:24] release, [23:20] IP, [0] mailbox
      issue_reg_read(PF_DMA_BAR_INDEX, 32'h134, , , , rd);
      // Vectors: mailbox (when the mailbox and its interrupt exist), user,
      // error (master PF), then data.
      dvec0 = ((rd[0] && rd[31:28] == 4'd0) ? 1 : 0) + 1 + ((fnc == 0) ? 1 : 0);
      `uvm_info("DRV_SEQ", $sformatf("fnc %0d (PF): misc_cap 0x%08h -> data vectors from %0d", fnc, rd, dvec0), UVM_NONE)
    end else begin
      // The VF identifies itself through 0x1014, or 0x5014 when 0x1014 does not
      // carry the 0x1fd4 identifier: [15:12] device, [11:8] release, [7:4] IP.
      issue_reg_read(VF_DMA_BAR_INDEX, 32'h1014, 1'b0, pfn, vfn, rd);
      if (rd[31:16] != 16'h1fd4)
        issue_reg_read(VF_DMA_BAR_INDEX, 32'h5014, 1'b0, pfn, vfn, rd);
      if (rd[15:12] != 4'd0 && rd[7:4] == 4'd0) begin
        // Versal hard IP: the driver runs this VF in poll mode
        nt = DRV_POLL;
        `uvm_info("DRV_SEQ", $sformatf("fnc %0d (VF): version 0x%08h decodes as a hard IP -> poll mode (as the driver forces it)", fnc, rd), UVM_NONE)
      end else begin
        // Soft device: vectors are mailbox (when its interrupt exists), user,
        // then data. The mailbox interrupt is missing only on a soft QDMA
        // (IP type 0) of release 0; for IP type 4 (CPM6) release 0 decodes
        // as a release that has it. A VF has no error vector.
        dvec0 = ((rd[7:4] == 4'd0 && rd[11:8] == 4'd0) ? 0 : 1) + 1;
        `uvm_info("DRV_SEQ", $sformatf("fnc %0d (VF): version 0x%08h -> data vectors from %0d", fnc, rd, dvec0), UVM_NONE)
      end
    end
    drv_fnc_notify[fnc] = nt;
    drv_fnc_dvec0[fnc]  = dvec0;
    drv_fnc_dvecn[fnc]  = MSIX_VEC_PER_FNC - dvec0;
    if (nt == DRV_DIRECT) begin
      if (drv_fnc_dvecn[fnc] < 1)
        `uvm_fatal("DRV_SEQ", $sformatf("fnc %0d has no data vector", fnc))
      TSK_PROGRAM_MSIX_VEC_TABLE(8'(fnc));
    end
    drv_fnc_done[fnc] = 1'b1;
  end
endtask

// Least-loaded data vector of the function, in queue-start order
function automatic int drv_alloc_vec(int fnc);
  int best, best_load;
  best = drv_fnc_dvec0[fnc];
  best_load = 32'h7fff_ffff;
  for (int v = drv_fnc_dvec0[fnc]; v < drv_fnc_dvec0[fnc] + drv_fnc_dvecn[fnc]; v++) begin
    int l;
    l = (drv_vec_load.exists(fnc) && drv_vec_load[fnc].exists(v)) ? drv_vec_load[fnc][v] : 0;
    if (l < best_load) begin best = v; best_load = l; end
  end
  drv_vec_load[fnc][best] = best_load + 1;
  return best;
endfunction

//------------------------------------------------------------------------------
// Context helpers
//------------------------------------------------------------------------------
task TSK_DRV_CTXT_CLR(input bit [10:0] hw_qid, input bit [3:0] sel);
  bit ok;
  begin
    issue_reg_write(PF_DMA_BAR_INDEX, DRV_BIND_IND_CTXT_CMD_OFFSET, build_ind_ctxt_cmd(hw_qid, sel, DRV_BIND_OP_CLR));
    TSK_IND_CTXT_POLL(PF_DMA_BAR_INDEX, ok);
    void'(dma_req_proc.drv_chk("DRV_CTXT", ok, $sformatf("qid %0d clear of context %0d did not complete", hw_qid, sel)));
  end
endtask

task TSK_DRV_CTXT_WR(input bit [10:0] hw_qid, input bit [3:0] sel, input bit [255:0] dat,
                     input bit [255:0] mask, input string what);
  bit ok;
  begin
    TSK_IND_CTXT_WRITE(PF_DMA_BAR_INDEX, hw_qid, sel, dat, what, ok);
    TSK_IND_CTXT_READBACK(PF_DMA_BAR_INDEX, hw_qid, sel, dat, mask, what, ok);
    void'(dma_req_proc.drv_chk("DRV_CTXT", ok, $sformatf("qid %0d %s context read back different from what was written", hw_qid, what)));
  end
endtask

task TSK_DRV_CTXT_RD(input bit [10:0] hw_qid, input bit [3:0] sel, output bit [255:0] dat, output bit ok);
  int polls;
  begin
    dat = '0;
    issue_ind_ctxt_op_nf(hw_qid, sel, DRV_BIND_OP_RD, ok, polls);
    if (ok) read_ind_ctxt_data(dat);
  end
endtask

// q dump of a C2H queue: SW, HW, credit, prefetch and completion contexts
task TSK_DRV_CTXT_DUMP(input int k, input string when);
  bit [255:0] w;
  bit         ok;
  bit [3:0]   sels [5] = '{4'h0, 4'h2, 4'h4, 4'h7, 4'h6};
  string      nm   [5] = '{"SW", "HW", "credit", "prefetch", "completion"};
  begin
    foreach (sels[i]) begin
      TSK_DRV_CTXT_RD(drv_qs[k].hw_qid, sels[i], w, ok);
      `uvm_info("DRV_DUMP", $sformatf("qid %0d %s, %s context: %s 0x%064h", drv_qs[k].hw_qid, when, nm[i],
                                      ok ? "" : "READ FAILED", w), UVM_NONE)
    end
  end
endtask

function automatic bit [255:0] drv_sw_mask();
  bit [255:0] m;
  m = '0;
  m[24:0] = '1; m[35:32] = '1; m[40:37] = '1; m[50:44] = '1; m[53:52] = '1;
  m[56:54] = '1; m[63:62] = '1; m[139:64] = '1;
  return m;
endfunction

//------------------------------------------------------------------------------
// Queue resolution
//------------------------------------------------------------------------------
task TSK_DRV_Q_RESOLVE(input int fnc, input int rel_qid, input bit dir_c2h, input int port,
                       output drv_q_t q);
  bit [7:0] pfn, vfn;
  begin
    TOTAL_VFS[0]       = 16'h20;
    NUM_VFS[0]         = NUM_VF;
    FIRST_VF_OFFSET[0] = VF_OFFSET;
    TSK_FIND_PF_VF_NUM(8'(fnc), pfn, vfn);
    q.fnc     = fnc;
    q.is_pf   = (fnc < NUM_PFS);
    q.pfn     = pfn;
    q.vfn     = vfn;
    q.rel_qid = rel_qid;
    if (q.is_pf) begin
      q.q_base  = QUEUE_PER_PF * fnc;
      q.q_count = QUEUE_PER_PF;
      q.bar     = PF_DMA_BAR_INDEX;
      q.qreg    = QUEUE_PTR_PF_ADDR;
    end else begin
      q.q_base  = QUEUE_PER_PF * NUM_PFS + (fnc - VF_OFFSET) * QUEUE_PER_VF;
      q.q_count = QUEUE_PER_VF;
      q.bar     = VF_DMA_BAR_INDEX;
      q.qreg    = 32'h3000;
    end
    if (rel_qid < 0 || rel_qid >= q.q_count)
      `uvm_fatal("DRV_SEQ", $sformatf("fnc %0d queue index %0d outside its %0d queues (+DRV_QID_BASE)", fnc, rel_qid, q.q_count))
    q.hw_qid  = 11'(rel_qid + q.q_base);
    q.dir_c2h = dir_c2h;
    q.port    = port;
    q.notify  = DRV_POLL;
    q.gap_tag = "";
  end
endtask

// Doorbell / queue register write on the queue's own function
task TSK_DRV_QREG_WR(input int k, input bit [3:0] off, input bit [31:0] val);
  begin
    issue_reg_write(drv_qs[k].bar, drv_qs[k].qreg + drv_qs[k].rel_qid * 16 + off, val,
                    drv_qs[k].is_pf, drv_qs[k].pfn, drv_qs[k].vfn);
  end
endtask

//------------------------------------------------------------------------------
// C2H buffers: one page per ring index at a fixed address, scattered (ring
// order permuted, a gap page after every buffer), all below 4 GB and clear of
// every other host region the testbench uses
//------------------------------------------------------------------------------
function automatic int drv_gcd(int a, int b);
  while (b != 0) begin
    int t;
    t = a % b; a = b; b = t;
  end
  return a;
endfunction

function automatic int drv_perm_step(int n);
  int primes [8] = '{7, 11, 13, 17, 19, 23, 29, 31};
  foreach (primes[i]) if (drv_gcd(primes[i], n) == 1) return primes[i];
  return 1;
endfunction

task TSK_DRV_ADDR_MAP_CHECK(input int k);
  longint unsigned lo, hi, rlo [4], rhi [4];
  string           rn [4];
  begin
    lo = 64'hFFFF_FFFF_FFFF_FFFF; hi = 0;
    for (int i = 0; i < drv_buf_addr[k].size(); i++) begin
      if (drv_buf_addr[k][i] < lo) lo = drv_buf_addr[k][i];
      if (drv_buf_addr[k][i] + drv_qs[k].bufsz > hi) hi = drv_buf_addr[k][i] + drv_qs[k].bufsz;
    end
    rlo[0] = H2C_DAT_SRC_ADDR; rhi[0] = H2C_DSC_ADDR;                                    rn[0] = "H2C data and MSI-X window";
    rlo[1] = H2C_DSC_ADDR;     rhi[1] = C2H_DSC_ADDR + HOST_DSC_MEM_SIZE;                rn[1] = "descriptor rings";
    rlo[2] = C2H_DAT_DST_ADDR; rhi[2] = C2H_DAT_DST_ADDR + C2H_DAT_SIZE;                 rn[2] = "C2H data windows";
    rlo[3] = CMPT_RING_BASE;   rhi[3] = CMPT_RING_BASE + longint'(MAX_QID) * RING_SIZE * 8; rn[3] = "completion rings";
    for (int r = 0; r < 4; r++)
      if (lo < rhi[r] && hi > rlo[r])
        `uvm_fatal("DRV_SEQ", $sformatf("qid %0d C2H buffers 0x%0h..0x%0h overlap the %s 0x%0h..0x%0h",
                                         drv_qs[k].hw_qid, lo, hi, rn[r], rlo[r], rhi[r]))
    if (hi > 64'h1_0000_0000)
      `uvm_fatal("DRV_SEQ", $sformatf("qid %0d C2H buffers run to 0x%0h, past 4 GB (host memory is keyed by the low 32 address bits)",
                                       drv_qs[k].hw_qid, hi))
  end
endtask

task TSK_DRV_POISON_BUF(input int k, input int idx);
  bit [63:0] a;
  begin
    a = drv_buf_addr[k][idx];
    for (int b = 0; b < drv_qs[k].bufsz; b++) host_mem[int'(a + b)] = DRV_POISON;
  end
endtask

// Posting: the scoreboard learns the new window before the DMA does
task TSK_DRV_C2H_POST(input int k, input int new_pidx);
  begin
    dma_req_proc.drv_c2h_post(drv_qs[k].hw_qid, new_pidx);
    TSK_DRV_QREG_WR(k, 4'h8, 32'(new_pidx));
    drv_qs[k].pidx_c2h = new_pidx;
  end
endtask

// Bytes and descriptors of H2C request r (sizes used in turn, else DMA_BYTE_CNT)
function automatic int drv_req_bytes(int r);
  return (drv_h2c_sizes.size() > 0) ? drv_h2c_sizes[r % drv_h2c_sizes.size()] : int'(DMA_BYTE_CNT);
endfunction

function automatic int drv_req_dpr(int r);
  return (drv_req_bytes(r) + drv_cfg.h2c_dsc_bytes - 1) / drv_cfg.h2c_dsc_bytes;
endfunction

//------------------------------------------------------------------------------
// H2C queue start
//------------------------------------------------------------------------------
task TSK_DRV_H2C_SETUP(input int k);
  bit [255:0] w;
  bit [7:0]   fnc8;
  begin
    fnc8 = 8'(drv_qs[k].fnc);
    drv_qs[k].dsc_base = H2C_DSC_ADDR + longint'(drv_qs[k].hw_qid) * RING_SIZE * 16;
    drv_qs[k].wb_addr  = drv_qs[k].dsc_base + (longint'(ring_entries) - 1) * 16;
    drv_qs[k].rngsz    = int'(ring_entries) - 1;
    drv_qs[k].dpr      = (int'(DMA_BYTE_CNT) + drv_cfg.h2c_dsc_bytes - 1) / drv_cfg.h2c_dsc_bytes;
    drv_qs[k].n_items  = drv_cfg.n_req;
    // The per-queue source buffer must stay inside the H2C data window
    // (above it lie the MSI-X window and the descriptor rings)
    if ((longint'(drv_qs[k].hw_qid) + 1) << $clog2(DMA_BYTE_CNT) > longint'(H2C_DAT_SIZE))
      `uvm_fatal("DRV_SEQ", $sformatf("H2C qid %0d: source buffer of %0d B at qid << %0d ends past the H2C data window (0x%0h); lower DMA_BYTE_CNT or the qid",
                                      drv_qs[k].hw_qid, DMA_BYTE_CNT, $clog2(DMA_BYTE_CNT), H2C_DAT_SIZE))
    drv_qs[k].h2c_pidx      = 0;
    drv_qs[k].h2c_cum       = 0;
    drv_qs[k].h2c_last_cidx = '0;
    drv_qs[k].h2c_req       = 0;
    // Source data pattern and the scoreboard's H2C expectations (descriptors
    // are rewritten in the driver's format at run time).
    TSK_INIT_QDMA_ST_DATA_H2C(fnc8, drv_qs[k].hw_qid, drv_qs[k].dsc_base);
    for (int b = 0; b < 8; b++) host_mem[int'(drv_qs[k].wb_addr + b)] = 8'h00;

    TSK_DRV_CTXT_CLR(drv_qs[k].hw_qid, 4'h1);   // SW H2C
    TSK_DRV_CTXT_CLR(drv_qs[k].hw_qid, 4'h3);   // HW H2C
    TSK_DRV_CTXT_CLR(drv_qs[k].hw_qid, 4'h5);   // credit H2C

    w = '0;
    w[139]      = 1'b0;                                       // int_aggr
    w[138:128]  = 11'(drv_qs[k].notify == DRV_DIRECT ? drv_qs[k].vec : 0);
    w[127:64]   = {dsc_base_hi, drv_qs[k].dsc_base[31:0]};
    w[63]       = 1'b0;                                       // is_mm
    w[62]       = 1'b0;                                       // mrkr_dis (never written by the driver)
    w[56:54]    = 3'(drv_qs[k].port);
    w[53]       = (drv_qs[k].notify == DRV_DIRECT);           // irq_en
    w[52]       = 1'b1;                                       // wbk_en
    w[50]       = 1'b0;                                       // bypass
    w[49:48]    = 2'b01;                                      // 16-byte descriptors
    w[47:44]    = 4'(drv_cfg.ring_idx);                       // ring-size index
    w[40:37]    = drv_qs[k].is_pf ? 4'd7 : 4'd0;              // fetch_max (VF mailbox default 0)
    w[35]       = 1'b1;                                       // wbi_intvl_en
    w[34]       = 1'b1;                                       // wbi_chk
    w[33]       = 1'b0;                                       // fcrd_en
    w[32]       = 1'b1;                                       // qen
    w[24:17]    = fnc8;
    w[16]       = (drv_qs[k].notify == DRV_DIRECT);           // irq_arm
    w[15:0]     = 16'd0;
    TSK_DRV_CTXT_WR(drv_qs[k].hw_qid, 4'h1, w, drv_sw_mask(), "DRV H2C SW");

    dma_req_proc.drv_h2c_dsc_per_req = drv_qs[k].dpr;
    // Per-request sizes: the scoreboard's byte, data and writeback expectations
    // follow the size list instead of DMA_BYTE_CNT per request.
    if (drv_h2c_sizes.size() > 0) begin
      longint unsigned tb;
      int              td;
      tb = 0; td = 0;
      for (int r = 0; r < drv_qs[k].n_items; r++) begin
        tb += longint'(drv_req_bytes(r));
        td += drv_req_dpr(r);
      end
      dma_req_proc.drv_h2c_sizes     = drv_h2c_sizes;
      dma_req_proc.drv_h2c_total_dsc = td;
      dma_req_proc.xfer_bytes        = int'(tb);
    end
    if (drv_qs[k].notify == DRV_DIRECT)
      dma_req_proc.register_drv_vec(drv_qs[k].fnc, drv_qs[k].vec, drv_qs[k].hw_qid, "H2C");
    `uvm_info("DRV_SEQ", $sformatf(
      "H2C qid %0d (fnc %0d %s, rel %0d) port %0d: %0d requests x %s, ring %0d, vec %0d, %s",
      drv_qs[k].hw_qid, drv_qs[k].fnc, drv_qs[k].is_pf ? "PF" : "VF", drv_qs[k].rel_qid, drv_qs[k].port,
      drv_qs[k].n_items,
      (drv_h2c_sizes.size() > 0) ? $sformatf("sizes %p B (%0d descriptors in total)", drv_h2c_sizes, dma_req_proc.drv_h2c_total_dsc)
                                 : $sformatf("%0d B (%0d descriptors each)", DMA_BYTE_CNT, drv_qs[k].dpr),
      drv_qs[k].rngsz, drv_qs[k].vec, drv_qs[k].notify.name()), UVM_NONE)
  end
endtask

//------------------------------------------------------------------------------
// C2H queue start
//------------------------------------------------------------------------------
task TSK_DRV_C2H_SETUP(input int k);
  bit [255:0]      w;
  bit [31:0]       rd;
  bit [7:0]        fnc8;
  bit [63:0]       a;
  longint unsigned slot0;
  int              need, step;
  begin
    fnc8 = 8'(drv_qs[k].fnc);
    // The board's q start touches no generator register (its packet size is
    // set, if needed, when the burst is started)
    if (!drv_cfg.board) TSK_C2H_SRC_CFG(3'(drv_qs[k].port));
    issue_reg_read(PF_DMA_BAR_INDEX, 32'hAB0, , , , rd);
    drv_qs[k].bufsz     = int'(rd[15:0]);
    drv_qs[k].rngsz     = DRV_RNG_TBL[drv_cfg.ring_idx] - 1;
    drv_qs[k].cmpt_ents = DRV_RNG_TBL[drv_cfg.cmpt_ring_idx];
    drv_qs[k].pkt_bytes = int'(c2h_eff_pkt_bytes());
    if (drv_qs[k].pkt_bytes > 7 * 4096)
      `uvm_fatal("DRV_SEQ", $sformatf("C2H qid %0d: packet of %0d B needs more than 7 buffers; set +C2H_PKT_BYTES (a larger DMA_BYTE_CNT does not size C2H packets in this mode)",
                                      drv_qs[k].hw_qid, drv_qs[k].pkt_bytes))
    drv_qs[k].n_items   = drv_cfg.n_req;
    drv_qs[k].posted    = (drv_cfg.c2h_post > 0) ? drv_cfg.c2h_post : drv_qs[k].rngsz - 1;
    if (drv_qs[k].bufsz == 0 || drv_qs[k].posted >= drv_qs[k].rngsz)
      `uvm_fatal("DRV_SEQ", $sformatf("qid %0d: buffer size %0d / posted %0d of %0d entries cannot start",
                                       drv_qs[k].hw_qid, drv_qs[k].bufsz, drv_qs[k].posted, drv_qs[k].rngsz))
    // The driver counts buffers per packet its own way when the buffer size
    // is not a power of two; the generator splits packets at C2H_SRC_BUF_BYTES.
    if ((drv_qs[k].bufsz & (drv_qs[k].bufsz - 1)) != 0 && (drv_qs[k].pkt_bytes & (drv_qs[k].pkt_bytes - 1)) == 0)
      `uvm_fatal("DRV_SEQ", $sformatf("qid %0d: buffer size %0d is not a power of two while the packet size %0d is -- the driver's buffer count differs",
                                       drv_qs[k].hw_qid, drv_qs[k].bufsz, drv_qs[k].pkt_bytes))
    if (drv_qs[k].bufsz != int'(C2H_SRC_BUF_BYTES))
      `uvm_fatal("DRV_SEQ", $sformatf("qid %0d: driver buffer size %0d (0xAB0) differs from the generator's %0d-byte split",
                                       drv_qs[k].hw_qid, drv_qs[k].bufsz, C2H_SRC_BUF_BYTES))
    drv_qs[k].dpp       = (drv_qs[k].pkt_bytes + drv_qs[k].bufsz - 1) / drv_qs[k].bufsz;
    drv_qs[k].dsc_base  = C2H_DSC_ADDR + longint'(drv_qs[k].hw_qid) * RING_SIZE * 16;
    drv_qs[k].cmpt_base = CMPT_RING_BASE + longint'(drv_qs[k].hw_qid) * RING_SIZE * 8;
    c2h_qid_dsc_sz[int'(drv_qs[k].hw_qid)]   = 8;
    c2h_qid_dsc_base[int'(drv_qs[k].hw_qid)] = drv_qs[k].dsc_base;

    // Buffer addresses: index i -> slot 2*((i*step) mod n)+1 of the queue's area
    slot0 = DRV_C2H_BUF_REGION + longint'(drv_c2h_qidx) * 2 * drv_qs[k].rngsz * drv_qs[k].bufsz;
    drv_c2h_qidx++;
    step = drv_perm_step(drv_qs[k].rngsz);
    drv_buf_addr[k].delete();
    for (int i = 0; i < drv_qs[k].rngsz; i++)
      drv_buf_addr[k].push_back(slot0 + (2 * ((longint'(i) * step) % drv_qs[k].rngsz) + 1) * drv_qs[k].bufsz);
    TSK_DRV_ADDR_MAP_CHECK(k);

    // Free list: descriptor i points at buffer i (never rewritten);
    // completion ring zeroed; every buffer that can be consumed (plus one
    // guard) poisoned.
    for (int i = 0; i < drv_qs[k].rngsz; i++) begin
      a = drv_buf_addr[k][i];
      for (int b = 0; b < 8; b++) host_mem[int'(drv_qs[k].dsc_base + i * 8 + b)] = a[8 * b +: 8];
    end
    for (int i = 0; i < drv_qs[k].cmpt_ents * 8; i++) host_mem[int'(drv_qs[k].cmpt_base + i)] = 8'h00;
    dma_req_proc.register_drv_c2h_ring(drv_qs[k].hw_qid, drv_buf_addr[k], drv_qs[k].bufsz, drv_qs[k].n_items);
    need = drv_qs[k].n_items * drv_qs[k].dpp + 1;
    for (int i = 0; i < ((need < drv_qs[k].rngsz) ? need : drv_qs[k].rngsz); i++) TSK_DRV_POISON_BUF(k, i);

    TSK_DRV_CTXT_CLR(drv_qs[k].hw_qid, 4'h0);   // SW C2H
    TSK_DRV_CTXT_CLR(drv_qs[k].hw_qid, 4'h2);   // HW C2H
    TSK_DRV_CTXT_CLR(drv_qs[k].hw_qid, 4'h4);   // credit C2H
    TSK_DRV_CTXT_CLR(drv_qs[k].hw_qid, 4'h7);   // prefetch
    TSK_DRV_CTXT_CLR(drv_qs[k].hw_qid, 4'h6);   // completion

    // SW context (the driver keeps the C2H SW interrupt off in every mode)
    w = '0;
    w[139]      = 1'b0;                                       // int_aggr
    w[138:128]  = 11'(drv_qs[k].notify == DRV_DIRECT ? drv_qs[k].vec : 0);
    w[127:64]   = {dsc_base_hi, drv_qs[k].dsc_base[31:0]};
    w[62]       = 1'b0;                                       // mrkr_dis
    w[56:54]    = 3'(drv_qs[k].port);
    w[53]       = 1'b0;                                       // irq_en
    w[52]       = 1'b0;                                       // wbk_en
    w[49:48]    = 2'b00;                                      // 8-byte descriptors
    w[47:44]    = 4'(drv_cfg.ring_idx);
    w[40:37]    = drv_qs[k].is_pf ? 4'd7 : 4'd0;              // fetch_max (VF mailbox default 0)
    w[35]       = 1'b1;                                       // wbi_intvl_en
    w[34]       = 1'b0;                                       // wbi_chk
    w[33]       = 1'b1;                                       // fcrd_en
    w[32]       = 1'b1;                                       // qen
    w[24:17]    = fnc8;
    w[16]       = 1'b0;                                       // irq_arm
    w[15:0]     = 16'd0;
    TSK_DRV_CTXT_WR(drv_qs[k].hw_qid, 4'h0, w, drv_sw_mask(), "DRV C2H SW");

    // Prefetch context
    w = '0;
    w[45]   = 1'b1;                                           // valid
    w[27]   = drv_cfg.pfch_en;
    w[7:5]  = 3'(drv_qs[k].port);
    w[4:1]  = 4'h0;                                           // buffer-size index 0
    w[0]    = 1'b0;                                           // bypass off
    begin
      bit [255:0] m;
      m = '0; m[45] = 1'b1; m[27] = 1'b1; m[7:0] = '1;
      TSK_DRV_CTXT_WR(drv_qs[k].hw_qid, 4'h7, w, m, "DRV C2H prefetch");
    end

    // Completion context
    w = '0;
    w[0]       = 1'b1;                                        // en_stat_desc
    w[1]       = (drv_qs[k].notify == DRV_DIRECT);            // en_int
    w[4:2]     = 3'h1;                                        // trigger EVERY
    w[12:5]    = fnc8;
    w[27]      = 1'b1;                                        // colour
    w[31:28]   = 4'(drv_cfg.cmpt_ring_idx);                   // ring-size index
    w[89:32]   = drv_qs[k].cmpt_base[63:6];
    w[91:90]   = 2'h0;                                        // 8-byte entries
    w[124]     = 1'b1;                                        // valid
    w[129]     = 1'b0;                                        // full_upd
    w[142:132] = 11'(drv_qs[k].notify == DRV_DIRECT ? drv_qs[k].vec : 0);
    w[143]     = 1'b0;                                        // int_aggr
    w[146]     = 1'b1;                                        // dir_c2h
    TSK_DRV_CTXT_WR(drv_qs[k].hw_qid, 4'h6, w, IND_CTXT_200B_MASK, "DRV C2H completion");
    cmpt_ctxt_exp[drv_qs[k].hw_qid] = w;
    cmpt_ctxt_bar[drv_qs[k].hw_qid] = PF_DMA_BAR_INDEX;
    dma_req_proc.register_cmpt_ring(drv_qs[k].hw_qid, drv_qs[k].cmpt_base, drv_qs[k].cmpt_ents);
    dma_req_proc.c2h_pkt_bytes = drv_qs[k].pkt_bytes;
    if (drv_qs[k].notify == DRV_DIRECT)
      dma_req_proc.register_drv_vec(drv_qs[k].fnc, drv_qs[k].vec, drv_qs[k].hw_qid, "C2H");

    // Completion CIDX register: cidx 0, status entries on, trigger EVERY,
    // interrupt enable as the mode
    begin
      bit [31:0] c;
      c = '0;
      c[28]    = (drv_qs[k].notify == DRV_DIRECT);
      c[27]    = 1'b1;
      c[26:24] = 3'h1;
      TSK_DRV_QREG_WR(k, 4'hC, c);
    end
    drv_qs[k].pidx_c2h  = 0;
    drv_qs[k].cidx_c2h  = 0;
    drv_qs[k].cidx_cmpt = 0;
    drv_qs[k].exp_col   = 1'b1;
    drv_qs[k].irq_base  = dma_req_proc.msix_fnc_vec(drv_qs[k].fnc, drv_qs[k].vec);
    drv_rd_q[k].delete();
    drv_seg_first[k].delete();
    drv_seg_seq[k].delete();
    // The driver posts the free list inside q start
    if (drv_cfg.board) TSK_DRV_C2H_POST(k, drv_qs[k].posted);
    `uvm_info("DRV_SEQ", $sformatf(
      "C2H qid %0d (fnc %0d %s, rel %0d) port %0d: %0d packets x %0d B (%0d buffers of %0d B), ring %0d, completion ring %0d, posted %0d, buffers scattered from 0x%0h (step %0d), vec %0d, %s",
      drv_qs[k].hw_qid, drv_qs[k].fnc, drv_qs[k].is_pf ? "PF" : "VF", drv_qs[k].rel_qid, drv_qs[k].port,
      drv_qs[k].n_items, drv_qs[k].pkt_bytes, drv_qs[k].dpp, drv_qs[k].bufsz, drv_qs[k].rngsz,
      drv_qs[k].cmpt_ents, drv_qs[k].posted, slot0, step, drv_qs[k].vec, drv_qs[k].notify.name()), UVM_NONE)
  end
endtask

//------------------------------------------------------------------------------
// Example-design generator, driven the way the board host drives it
//------------------------------------------------------------------------------
task TSK_DRV_GEN_WR(input int k, input bit [31:0] off, input bit [31:0] val);
  begin
    issue_reg_write(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + off, val);
    drv_q_cmds[k].push_back($sformatf("dma-ctl $DEV reg write bar 2 0x%08h 0x%0h", C2H_SRC_CFG_OFF + off, val));
  end
endtask

task TSK_DRV_GEN_RD(input int k, input bit [31:0] off, output bit [31:0] rd);
  begin
    issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + off, , , , rd);
    drv_q_cmds[k].push_back($sformatf("dma-ctl $DEV reg read bar 2 0x%08h    # sim: 0x%08h", C2H_SRC_CFG_OFF + off, rd));
  end
endtask

// Board step: ID, VERSION, STATUS, PKT_BYTES of the port read before queues are added
task TSK_DRV_GEN_PROBE(input int port);
  bit [31:0] rd, off;
  begin
    TSK_C2H_SRC_CHECK_ID();
    if (drv_probe_done.exists(port)) return;
    drv_probe_done[port] = 1'b1;
    drv_pre_cmds.push_back($sformatf("# generator port %0d: ID, VERSION, STATUS, PKT_BYTES", port));
    for (int i = 0; i < 4; i++) begin
      off = (i == 0) ? C2H_SRC_A_ID : (i == 1) ? C2H_SRC_A_VERSION : (i == 2) ? C2H_SRC_A_STATUS : c2h_src_a_len(port);
      issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + off, , , , rd);
      drv_pre_cmds.push_back($sformatf("dma-ctl $DEV reg read bar 2 0x%08h    # sim: 0x%08h", C2H_SRC_CFG_OFF + off, rd));
    end
  end
endtask

// QID, NUM_PKT (read back), START, then -- once the burst is done -- CONTROL,
// PKT_CNT and STATUS, exactly the host's register accesses on the board
task TSK_DRV_GEN_BOARD(input int k, input int n, output int seq);
  bit [31:0] rd;
  int        port;
  time       t0;
  begin
    port = drv_qs[k].port;
    TSK_C2H_SRC_SCHED_INIT();
    TSK_C2H_SRC_CHECK_ID();
    c2h_src_port_lock[port].get(1);
    if ((c2h_src_pkt_bytes_q.exists(port) ? c2h_src_pkt_bytes_q[port] : C2H_SRC_RST_PKT_BYTES) != drv_qs[k].pkt_bytes)
      TSK_C2H_SRC_CFG_SET(port, drv_qs[k].pkt_bytes);
    TSK_DRV_GEN_WR(k, c2h_src_a_qid(port), 32'(drv_qs[k].hw_qid));
    TSK_DRV_GEN_WR(k, c2h_src_a_num(port), 32'(n));
    if (drv_cfg.gen_reads) begin
      TSK_DRV_GEN_RD(k, c2h_src_a_qid(port), rd);
      if (rd !== 32'(drv_qs[k].hw_qid))
        `uvm_error("C2H_SRC_CFG", $sformatf("port %0d QID %0d read back 0x%08h", port, drv_qs[k].hw_qid, rd))
      TSK_DRV_GEN_RD(k, c2h_src_a_num(port), rd);
      if (rd !== 32'(n))
        `uvm_error("C2H_SRC_CFG", $sformatf("port %0d NUM_PKT %0d read back 0x%08h", port, n, rd))
    end
    TSK_DRV_GEN_WR(k, c2h_src_a_start(port), c2h_src_start_bit(port));
    c2h_src_burst_seq[port]++;
    seq = c2h_src_burst_seq[port];
    c2h_src_pkts_started[port] += n;
    if (!c2h_src_dsc_committed.exists(drv_qs[k].hw_qid)) c2h_src_dsc_committed[drv_qs[k].hw_qid] = 0;
    c2h_src_dsc_committed[drv_qs[k].hw_qid] += longint'(n) * drv_qs[k].dpp;
    dma_req_proc.set_c2h_expected_burst(drv_qs[k].hw_qid, 16'(seq));
    if (drv_cfg.gen_reads) begin
      // The host sleeps ("sleep 1") and then reads CONTROL; here CONTROL is
      // read until BUSY clears, at most one step
      t0 = $time;
      do begin
        #1us;
        issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + c2h_src_a_status(port), , , , rd);
      end while (rd[0] && ($time - t0) < drv_cfg.step_ns * 1ns && !drv_mmio_dead);
      drv_q_cmds[k].push_back("sleep 1");
      drv_q_cmds[k].push_back($sformatf("dma-ctl $DEV reg read bar 2 0x%08h    # sim: 0x%08h", C2H_SRC_CFG_OFF + c2h_src_a_status(port), rd));
      if (rd[0])
        `uvm_error("C2H_SRC_BUSY", $sformatf("port %0d generator still busy %0d ns after START: CONTROL 0x%08h", port, drv_cfg.step_ns, rd))
      TSK_DRV_GEN_RD(k, c2h_src_a_pkt_cnt(port), rd);
      if (rd !== 32'(c2h_src_pkts_started[port]))
        `uvm_error("C2H_SRC_CFG", $sformatf("port %0d PKT_CNT 0x%08h after the burst, expected %0d", port, rd, c2h_src_pkts_started[port]))
      TSK_DRV_GEN_RD(k, C2H_SRC_A_STATUS, rd);
      if (rd[0])
        `uvm_error("C2H_SRC_CFG", $sformatf("port %0d STATUS 0x%08h after the burst: a write was rejected", port, rd))
    end
    c2h_src_port_lock[port].put(1);
    `uvm_info("C2H_SRC_BURST", $sformatf("port %0d qid %0d: START %0d packets of %0d B (burst %0d, board order)",
                                         port, drv_qs[k].hw_qid, n, drv_qs[k].pkt_bytes, seq), UVM_NONE)
  end
endtask

task TSK_DRV_GEN_START(input int k, input int n);
  int seq;
  begin
    if (n <= 0) return;
    if (drv_cfg.board) TSK_DRV_GEN_BOARD(k, n, seq);
    else               TSK_C2H_SRC_START_BURST(drv_qs[k].port, drv_qs[k].hw_qid, n, drv_qs[k].pkt_bytes, seq);
    drv_seg_first[k].push_back(drv_qs[k].pkts_req);
    drv_seg_seq[k].push_back(seq);
    drv_qs[k].pkts_req += n;
    drv_qs[k].gen_ptr   = (drv_qs[k].gen_ptr + n * drv_qs[k].dpp) % drv_qs[k].rngsz;
  end
endtask

// Packets the posted, not yet committed buffers can take
function automatic int drv_gen_room(int k);
  int free_b, n;
  free_b = (drv_qs[k].pidx_c2h - drv_qs[k].gen_ptr + drv_qs[k].rngsz) % drv_qs[k].rngsz;
  n = free_b / drv_qs[k].dpp;
  if (n > drv_qs[k].n_items - drv_qs[k].pkts_req) n = drv_qs[k].n_items - drv_qs[k].pkts_req;
  return n;
endfunction

//------------------------------------------------------------------------------
// Interrupt wait: MSI-X count of (function, vector) moving past base
//------------------------------------------------------------------------------
task TSK_DRV_WAIT_IRQ(input int fnc, input int vec, input int unsigned base, input int tmo_ns,
                      output bit got);
  time t0;
  begin
    t0  = $time;
    got = 1'b0;
    while (!got && ($time - t0) < tmo_ns * 1ns) begin
      #100ns;
      got = (dma_req_proc.msix_fnc_vec(fnc, vec) > base);
    end
  end
endtask

//------------------------------------------------------------------------------
// H2C traffic: one request at a time, as the synchronous write path does
//------------------------------------------------------------------------------
task TSK_DRV_H2C_DOORBELL(input int k, input int pidx_h2c);
  bit [31:0] db;
  begin
    db = {15'h0, 1'(drv_qs[k].notify == DRV_DIRECT), 16'(pidx_h2c)};
    dma_req_proc.drv_h2c_doorbell(drv_qs[k].hw_qid, pidx_h2c, drv_qs[k].rngsz);
    TSK_DRV_QREG_WR(k, 4'h4, db);
  end
endtask

// PL-side byte check of one H2C request: waits for the request's bytes at the
// PL sink (bounded by the hang cap) without holding up the host sequence; the
// count is taken the first time it reaches the request's size, before a later
// request's bytes can add to it
task automatic TSK_DRV_H2C_PL_CHK(input int k, input int r, input longint b0, input longint exp_b, input bit done);
  longint b1;
  time    t1;
  bit     pl_ok;
  begin
    t1 = $time;
    b1 = dma_req_proc.h2c_user_data.exists(drv_qs[k].hw_qid) ? dma_req_proc.h2c_user_data[drv_qs[k].hw_qid].size() : 0;
    while (b1 - b0 < exp_b && ($time - t1) < drv_cfg.hang_ns * 1ns) begin
      #10ns;
      b1 = dma_req_proc.h2c_user_data.exists(drv_qs[k].hw_qid) ? dma_req_proc.h2c_user_data[drv_qs[k].hw_qid].size() : 0;
    end
    pl_ok = dma_req_proc.drv_chk("DRV_H2C_PL", b1 - b0 == exp_b, $sformatf(
      "H2C qid %0d request %0d: PL bytes +%0d, expected %0d", drv_qs[k].hw_qid, r, b1 - b0, exp_b));
    if (done && pl_ok) drv_qs[k].n_full++;
    `uvm_info("DRV_SEQ", $sformatf("H2C qid %0d request %0d: PL bytes +%0d after %0d ns from retirement",
                                   drv_qs[k].hw_qid, r, b1 - b0, int'(($time - t1) / 1ns)), UVM_MEDIUM)
  end
endtask

// One H2C request: descriptors, doorbell, wait for the status writeback,
// checks, re-arm. ok = 0 when the request did not retire (the driver's
// request would time out).
task TSK_DRV_H2C_REQ(input int k, output bit ok);
  bit [63:0]   src;
  bit [63:0]   d;
  int          r, len, rb, dpr_r;
  bit [15:0]   cidx;
  longint      b0, exp_b;
  int unsigned base;
  bit          got, done;
  time         t0;
  int          lat_ns;
  begin
    r     = drv_qs[k].h2c_req;
    rb    = drv_req_bytes(r);
    dpr_r = drv_req_dpr(r);
    src = H2C_DAT_SRC_ADDR;
    src[$clog2(DMA_BYTE_CNT) +: 11] = drv_qs[k].hw_qid;
    // Descriptors for this request, page-split from the start of the buffer
    for (int i = 0; i < dpr_r; i++) begin
      d   = drv_qs[k].dsc_base + longint'((drv_qs[k].h2c_pidx + i) % drv_qs[k].rngsz) * 16;
      len = rb - i * drv_cfg.h2c_dsc_bytes;
      if (len > drv_cfg.h2c_dsc_bytes) len = drv_cfg.h2c_dsc_bytes;
      if (drv_cfg.h2c_fmt_tb) begin
        for (int b = 0; b < 4; b++) host_mem[int'(d + b)] = 8'h00;
      end else begin
        host_mem[int'(d + 0)] = 8'd13;                       // cdh_flags
        host_mem[int'(d + 1)] = 8'h00;
        host_mem[int'(d + 2)] = 8'(len);                     // pld_len
        host_mem[int'(d + 3)] = 8'(len >> 8);
      end
      host_mem[int'(d + 4)] = 8'(len);                       // len
      host_mem[int'(d + 5)] = 8'(len >> 8);
      host_mem[int'(d + 6)] = 8'h00;                         // flags
      host_mem[int'(d + 7)] = 8'h00;
      for (int b = 0; b < 8; b++)
        host_mem[int'(d + 8 + b)] = 8'((src + longint'(i) * drv_cfg.h2c_dsc_bytes) >> (8 * b));
    end
    drv_qs[k].h2c_pidx = (drv_qs[k].h2c_pidx + dpr_r) % drv_qs[k].rngsz;
    drv_qs[k].h2c_cum += dpr_r;
    exp_b = longint'(rb);
    b0 = dma_req_proc.h2c_user_data.exists(drv_qs[k].hw_qid) ? dma_req_proc.h2c_user_data[drv_qs[k].hw_qid].size() : 0;
    base = dma_req_proc.msix_fnc_vec(drv_qs[k].fnc, drv_qs[k].vec);
    // Self-test: the lost-wakeup check must see the last MSI-X of the queue
    // go missing (the engine itself still sees it)
    if (drv_qs[k].notify == DRV_DIRECT && r == drv_qs[k].n_items - 1 && !drv_msix_inj_armed &&
        dma_req_proc.drv_inj.exists("MSIX_LOST")) begin
      drv_msix_inj_armed = 1'b1;
      dma_req_proc.drv_msix_drop[drv_qs[k].fnc][drv_qs[k].vec] = 1'b1;
    end
    TSK_DRV_H2C_DOORBELL(k, drv_qs[k].h2c_pidx);
    if (drv_cfg.dup_pidx) TSK_DRV_H2C_DOORBELL(k, drv_qs[k].h2c_pidx);

    // Completion: status writeback cidx reaching the ring pidx. In ADVANCE
    // re-arm mode every observed cidx change is answered at once with the
    // same PIDX, as the driver's poll thread does on each serviced advance.
    t0   = $time;
    done = 1'b0;
    cidx = drv_qs[k].h2c_last_cidx;
    while (!done && ($time - t0) < drv_cfg.hang_ns * 1ns) begin
      if (drv_qs[k].notify == DRV_DIRECT && !drv_qs[k].irq_gap) begin
        TSK_DRV_WAIT_IRQ(drv_qs[k].fnc, drv_qs[k].vec, base, drv_cfg.irq_wait_ns, got);
        if (got) begin
          drv_qs[k].irq_seen++;
          base = dma_req_proc.msix_fnc_vec(drv_qs[k].fnc, drv_qs[k].vec);
        end
      end else begin
        #100ns;
        got = 1'b0;
      end
      if (host_mem.exists(int'(drv_qs[k].wb_addr + 2)) && host_mem.exists(int'(drv_qs[k].wb_addr + 3))) begin
        cidx = {host_mem[int'(drv_qs[k].wb_addr + 3)], host_mem[int'(drv_qs[k].wb_addr + 2)]};
        done = (cidx == 16'(drv_qs[k].h2c_pidx));
        if (drv_cfg.rearm_adv && cidx != drv_qs[k].h2c_last_cidx) begin
          drv_qs[k].h2c_last_cidx = cidx;
          TSK_DRV_H2C_DOORBELL(k, drv_qs[k].h2c_pidx);
        end
      end
      if (drv_qs[k].notify == DRV_DIRECT && !drv_qs[k].irq_gap && !got && done) begin
        drv_qs[k].irq_gap = 1'b1;
        void'(dma_req_proc.drv_chk("DRV_H2C_NO_MSIX", 1'b0, $sformatf(
          "H2C qid %0d (fnc %0d vec %0d): request %0d retired (status cidx %0d) but no MSI-X within %0d ns",
          drv_qs[k].hw_qid, drv_qs[k].fnc, drv_qs[k].vec, r, cidx, drv_cfg.irq_wait_ns)));
      end
    end
    lat_ns = ($time - t0) / 1ns;
    // The request closes on the status writeback alone, as the driver's write
    // does; the PL-side byte check runs beside the sequence and never delays
    // the next host action
    begin
      automatic int     ka = k, ra = r;
      automatic longint b0a = b0, expa = exp_b;
      automatic bit     donea = done;
      drv_pl_live++;
      fork
        begin
          TSK_DRV_H2C_PL_CHK(ka, ra, b0a, expa, donea);
          drv_pl_live--;
        end
      join_none
    end
    if (done)
      void'(dma_req_proc.drv_chk("DRV_STEP_TIMEOUT", lat_ns <= drv_cfg.step_ns, $sformatf(
        "H2C qid %0d request %0d (pidx %0d) retired after %0d ns, over the %0d ns step bound",
        drv_qs[k].hw_qid, r, drv_qs[k].h2c_pidx, lat_ns, drv_cfg.step_ns)));
    if (done) dma_req_proc.drv_note_latency("H2C", lat_ns);
    void'(dma_req_proc.drv_chk("DRV_HANG", done, $sformatf(
      "H2C qid %0d request %0d (pidx %0d, %0d B) not retired after %0d ns, status cidx %0d%s",
      drv_qs[k].hw_qid, r, drv_qs[k].h2c_pidx, rb, drv_cfg.hang_ns, cidx,
      host_mem.exists(int'(drv_qs[k].wb_addr + 2)) ? "" : " (no status write seen)")));
    drv_qs[k].h2c_req++;
    ok = done;
    if (!done) return;
    drv_qs[k].n_ok++;
    `uvm_info("DRV_SEQ", $sformatf("H2C qid %0d request %0d (%0d B, %0d descriptors): RETIRED, status cidx %0d",
                                   drv_qs[k].hw_qid, r, rb, dpr_r, cidx), UVM_MEDIUM)
    // Re-arm once per request (REQUEST mode): the same PIDX written again
    if (!drv_cfg.rearm_adv) begin
      drv_qs[k].h2c_last_cidx = cidx;
      TSK_DRV_H2C_DOORBELL(k, drv_qs[k].h2c_pidx);
    end
  end
endtask

task TSK_DRV_H2C_RUN(input int k);
  bit ok;
  begin
    while (drv_qs[k].h2c_req < drv_qs[k].n_items) begin
      TSK_DRV_H2C_REQ(k, ok);
      if (!ok) break;
    end
  end
endtask

//------------------------------------------------------------------------------
// C2H: completion pass (entries -> read list, completion CIDX) and reads
//------------------------------------------------------------------------------
task TSK_DRV_C2H_PASS(input int k);
  bit [31:0]   c;
  bit [63:0]   e;
  int          sts_pidx;
  int unsigned base;
  bit          got, pend;
  time         t0;
  int          lat_ns;
  begin
    if (drv_cfg.consume_delay_ns > 0) #(drv_cfg.consume_delay_ns * 1ns);
    t0   = $time;
    got  = 1'b0;
    base = drv_qs[k].irq_base;
    // Direct-interrupt mode: the driver services the queue only on an MSI-X
    // of its vector, even when completions have already landed. A wake with
    // nothing pending re-arms; completions pending and no MSI-X is the
    // interrupt gap (reported, then the queue is polled from here).
    if (drv_qs[k].notify == DRV_DIRECT) begin
      bit woke;
      woke = 1'b0;
      while (!woke && !drv_qs[k].irq_gap && ($time - t0) < drv_cfg.hang_ns * 1ns) begin
        TSK_DRV_WAIT_IRQ(drv_qs[k].fnc, drv_qs[k].vec, base, drv_cfg.irq_wait_ns, got);
        pend = (dma_req_proc.drv_c2h_sts_pidx(drv_qs[k].hw_qid) != drv_qs[k].cidx_cmpt);
        if (got) begin
          drv_qs[k].irq_seen++;
          base               = dma_req_proc.msix_fnc_vec(drv_qs[k].fnc, drv_qs[k].vec);
          drv_qs[k].irq_base = base;
          if (pend) woke = 1'b1;
          else begin
            c = '0; c[28] = 1'b1; c[27] = 1'b1; c[26:24] = 3'h1; c[15:0] = 16'(drv_qs[k].cidx_cmpt);
            TSK_DRV_QREG_WR(k, 4'hC, c);
          end
        end else if (pend) begin
          drv_qs[k].irq_gap = 1'b1;
          drv_qs[k].gap_tag = (drv_vec_h2c.exists(drv_qs[k].fnc) && drv_vec_h2c[drv_qs[k].fnc].exists(drv_qs[k].vec)) ?
                              "shared_vector_h2c_idle" : "c2h_only_vector";
          dma_req_proc.drv_note_c2h_gap(drv_qs[k].hw_qid);
          void'(dma_req_proc.drv_chk("DRV_C2H_NO_MSIX", 1'b0, $sformatf(
            "C2H qid %0d (fnc %0d vec %0d) [%s]: completions pending, no MSI-X within %0d ns -- a driver in direct-interrupt mode would not service this queue; polling from here",
            drv_qs[k].hw_qid, drv_qs[k].fnc, drv_qs[k].vec, drv_qs[k].gap_tag, drv_cfg.irq_wait_ns)));
        end
      end
    end
    // Poll mode (or after an interrupt gap): wait for the status pidx, as
    // the scoreboard processed it, to move past the consumer index
    sts_pidx = dma_req_proc.drv_c2h_sts_pidx(drv_qs[k].hw_qid);
    while (sts_pidx == drv_qs[k].cidx_cmpt && ($time - t0) < drv_cfg.hang_ns * 1ns) begin
      #200ns;
      sts_pidx = dma_req_proc.drv_c2h_sts_pidx(drv_qs[k].hw_qid);
    end
    lat_ns = ($time - t0) / 1ns;
    if (sts_pidx != drv_qs[k].cidx_cmpt) begin
      void'(dma_req_proc.drv_chk("DRV_STEP_TIMEOUT", lat_ns <= drv_cfg.step_ns, $sformatf(
        "C2H qid %0d: new completion after %0d ns, over the %0d ns step bound (%0d of %0d packets completed)",
        drv_qs[k].hw_qid, lat_ns, drv_cfg.step_ns, drv_qs[k].n_cons, drv_qs[k].n_items)));
      dma_req_proc.drv_note_latency("C2H", lat_ns);
    end
    if (!dma_req_proc.drv_chk("DRV_HANG", sts_pidx != drv_qs[k].cidx_cmpt, $sformatf(
          "C2H qid %0d: no new completion after %0d ns (status pidx %0d, consumer %0d, %0d of %0d packets completed)",
          drv_qs[k].hw_qid, drv_cfg.hang_ns, sts_pidx, drv_qs[k].cidx_cmpt, drv_qs[k].n_cons, drv_qs[k].n_items))) begin
      drv_qs[k].dead = 1'b1;
      drv_qs[k].hung = 1'b1;
      return;
    end

    // Consume every covered entry, as the driver's completion pass does
    while (drv_qs[k].cidx_cmpt != sts_pidx && drv_qs[k].n_cons < drv_qs[k].n_items) begin
      drv_rd_t r;
      int      len;
      bit      ok_f, ok_c, ok_l, ok_q;
      for (int b = 0; b < 8; b++)
        e[8 * b +: 8] = host_mem[int'(drv_qs[k].cmpt_base + drv_qs[k].cidx_cmpt * 8 + b)];
      if (dma_req_proc.drv_inject("ENTRY_FIELDS")) e[3] = 1'b0;      // checker's copy only
      len  = int'(e[19:4]);
      ok_f = dma_req_proc.drv_chk("DRV_ENTRY_FIELDS", !e[0] && !e[2] && e[3], $sformatf(
               "C2H qid %0d packet %0d: completion entry [%0d] = %h: format %0d error %0d desc_used %0d -- a permanent queue error in the driver",
               drv_qs[k].hw_qid, drv_qs[k].n_cons, drv_qs[k].cidx_cmpt, e, e[0], e[2], e[3]));
      ok_c = dma_req_proc.drv_chk("DRV_ENTRY_COLOUR", e[1] === drv_qs[k].exp_col, $sformatf(
               "C2H qid %0d packet %0d: completion entry [%0d] = %h colour %0d, expected %0d (status pidx %0d covers it) -- the driver stalls on it",
               drv_qs[k].hw_qid, drv_qs[k].n_cons, drv_qs[k].cidx_cmpt, e, e[1], drv_qs[k].exp_col, sts_pidx));
      if (!ok_c) begin
        drv_qs[k].dead = 1'b1;
        break;
      end
      ok_l = dma_req_proc.drv_chk("DRV_ENTRY_LEN", len == drv_qs[k].pkt_bytes, $sformatf(
               "C2H qid %0d packet %0d: completion entry [%0d] length %0d, expected %0d",
               drv_qs[k].hw_qid, drv_qs[k].n_cons, drv_qs[k].cidx_cmpt, len, drv_qs[k].pkt_bytes));
      ok_q = dma_req_proc.drv_chk("DRV_ENTRY_QID", e[30:20] == drv_qs[k].hw_qid, $sformatf(
               "C2H qid %0d packet %0d: completion entry [%0d] qid field %0d",
               drv_qs[k].hw_qid, drv_qs[k].n_cons, drv_qs[k].cidx_cmpt, e[30:20]));
      if (len == 0) len = drv_qs[k].pkt_bytes;
      r.pkt  = drv_qs[k].n_cons;
      r.buf0 = drv_qs[k].cidx_c2h;
      r.nd   = (len + drv_qs[k].bufsz - 1) / drv_qs[k].bufsz;
      r.len  = len;
      r.ok   = ok_f;
      r.full = ok_f && ok_l && ok_q;
      drv_rd_q[k].push_back(r);
      drv_qs[k].cidx_c2h = (drv_qs[k].cidx_c2h + r.nd) % drv_qs[k].rngsz;
      drv_qs[k].cidx_cmpt++;
      if (drv_qs[k].cidx_cmpt == drv_qs[k].cmpt_ents - 1) begin
        drv_qs[k].cidx_cmpt = 0;
        drv_qs[k].exp_col   = ~drv_qs[k].exp_col;
      end
      drv_qs[k].n_cons++;
    end

    // Hand the entries back
    c = '0;
    c[28]    = (drv_qs[k].notify == DRV_DIRECT);
    c[27]    = 1'b1;
    c[26:24] = 3'h1;
    c[15:0]  = 16'(drv_qs[k].cidx_cmpt);
    TSK_DRV_QREG_WR(k, 4'hC, c);
  end
endtask

// One read: one packet's buffers judged, handed back, posted again
task TSK_DRV_C2H_READ(input int k, input bit last);
  drv_rd_t r;
  int      sg, beats, mism, wrong;
  bit      pay_ok;
  begin
    r     = drv_rd_q[k].pop_front();
    beats = drv_qs[k].pkt_bytes / 64;
    sg    = 0;
    for (int i = 0; i < drv_seg_first[k].size(); i++) if (drv_seg_first[k][i] <= r.pkt) sg = i;
    mism  = 0;
    wrong = 0;
    for (int j = 0; j < r.nd; j++) begin
      int        bi, nb;
      longint    got_b;
      bit [63:0] a;
      bi    = (r.buf0 + j) % drv_qs[k].rngsz;
      a     = drv_buf_addr[k][bi];
      nb    = (r.len - j * drv_qs[k].bufsz > drv_qs[k].bufsz) ? drv_qs[k].bufsz : r.len - j * drv_qs[k].bufsz;
      got_b = dma_req_proc.drv_c2h_buf_got(drv_qs[k].hw_qid, bi);
      if (got_b != nb) wrong++;
      for (int b = 0; b < drv_qs[k].bufsz; b++) begin
        int         pb;
        bit [7:0]   hv, ev;
        bit [511:0] w;
        pb = j * drv_qs[k].bufsz + b;
        hv = host_mem.exists(int'(a + b)) ? host_mem[int'(a + b)] : 8'h00;
        if (pb < r.len) begin
          w = '0;
          w[31:0]  = 32'((r.pkt - drv_seg_first[k][sg]) * beats + pb / 64);
          w[47:32] = 16'(drv_seg_seq[k][sg]);
          w[63:53] = drv_qs[k].hw_qid;
          ev = w[(pb % 64) * 8 +: 8];
        end else
          ev = DRV_POISON;                                       // past the packet: untouched
        if (hv !== ev) mism++;
      end
    end
    pay_ok = dma_req_proc.drv_chk("DRV_PAYLOAD", mism == 0 && wrong == 0, $sformatf(
               "C2H qid %0d packet %0d: %0d of %0d buffer bytes wrong (incl. bytes past the packet), %0d buffer(s) with a byte count other than the packet's, first buffer %0d",
               drv_qs[k].hw_qid, r.pkt, mism, r.nd * drv_qs[k].bufsz, wrong, r.buf0));
    if (r.ok) drv_qs[k].n_ok++;
    if (r.full && pay_ok) drv_qs[k].n_full++;
    `uvm_info("DRV_SEQ", $sformatf("C2H qid %0d packet %0d: %0d B in buffer %0d: %s",
                                   drv_qs[k].hw_qid, r.pkt, r.len, r.buf0, (r.full && pay_ok) ? "OK" : "FAILED"), UVM_MEDIUM)
    // Buffers back to the host; re-poisoned when the ring will reuse them
    for (int j = 0; j < r.nd; j++) begin
      int bi;
      bi = (r.buf0 + j) % drv_qs[k].rngsz;
      dma_req_proc.drv_c2h_return(drv_qs[k].hw_qid, bi);
      if (drv_qs[k].n_items * drv_qs[k].dpp >= drv_qs[k].rngsz) TSK_DRV_POISON_BUF(k, bi);
    end
    drv_qs[k].ret_pend += r.nd;
    drv_qs[k].n_read++;
    if (drv_qs[k].ret_pend >= drv_cfg.ret_batch || last) begin
      TSK_DRV_C2H_POST(k, (drv_qs[k].pidx_c2h + drv_qs[k].ret_pend) % drv_qs[k].rngsz);
      drv_qs[k].ret_pend = 0;
    end
  end
endtask

task TSK_DRV_C2H_RUN(input int k);
  begin
    if (!drv_cfg.board) begin
      // Concurrent order: the free list is posted as the thread's first action
      TSK_DRV_C2H_POST(k, drv_qs[k].posted);
      TSK_DRV_GEN_START(k, drv_gen_room(k));
    end
    while (drv_qs[k].n_read < drv_qs[k].n_items && !drv_qs[k].dead) begin
      if (drv_rd_q[k].size() == 0) begin
        TSK_DRV_C2H_PASS(k);
        continue;
      end
      TSK_DRV_C2H_READ(k, drv_qs[k].n_read + 1 == drv_qs[k].n_items || drv_rd_q[k].size() == 1);
      if (drv_qs[k].pkts_req < drv_qs[k].n_items) TSK_DRV_GEN_START(k, drv_gen_room(k));
    end
    if (drv_qs[k].ret_pend > 0) begin
      TSK_DRV_C2H_POST(k, (drv_qs[k].pidx_c2h + drv_qs[k].ret_pend) % drv_qs[k].rngsz);
      drv_qs[k].ret_pend = 0;
    end
  end
endtask

// Reads until target packets have been read (board loop: one packet per
// iteration; the generator is started by the caller)
task TSK_DRV_C2H_READ_TO(input int k, input int target);
  begin
    while (drv_qs[k].n_read < target && !drv_qs[k].dead) begin
      if (drv_rd_q[k].size() == 0) begin
        TSK_DRV_C2H_PASS(k);
        continue;
      end
      TSK_DRV_C2H_READ(k, drv_qs[k].n_read + 1 == target || drv_rd_q[k].size() == 1);
    end
  end
endtask

// Debug-bank snapshot at an idle point, for a field-by-field comparison with
// the same registers read on hardware: the raw words 0x1000-0x1098, then the
// streaming words per port. Printed as "DBG_RAW <label> 0x<offset> 0x<value>"
// and the "DBG_DUMP" lines of TSK_QDMA_DBG_DUMP.
task TSK_DRV_DBG_SNAP(input string label);
  bit [31:0] rd;
  begin
    if (!drv_cfg.dbg_snap || drv_mmio_dead) return;
    `uvm_info("DRV_SEQ", $sformatf("debug-bank snapshot [%s] at %0t", label, $time), UVM_NONE)
    for (int off = 'h1000; off <= 'h1098; off += 4) begin
      issue_reg_read(PF_DMA_BAR_INDEX, 32'(off), , , , rd);
      `uvm_info("DBG_RAW", $sformatf("%s 0x%04h 0x%08h", label, off, rd), UVM_NONE)
    end
    TSK_QDMA_DBG_DUMP();
  end
endtask

// The host's repeat loop on one queue pair: per iteration one H2C write,
// the generator started for one packet, one C2H read. With
// +DRV_LOOP_CONTINUE a direction that fails does not stop the loop: the
// other direction and later iterations still run, as the host's script does.
task TSK_DRV_BOARD_LOOP(input int kh, input int kc);
  bit  ok;
  int  n;
  time t_it;
  int  lat_ns, lat0_ns;
  begin
    n = (kh >= 0) ? drv_qs[kh].n_items : drv_qs[kc].n_items;
    lat0_ns = 0;
    if (kc >= 0 && drv_gen_room(kc) < 1)
      `uvm_fatal("DRV_SEQ", $sformatf("board loop qid %0d: no posted C2H buffer for one packet (+DRV_C2H_POST too small)", drv_qs[kc].hw_qid))
    for (int it = 0; it < n; it++) begin
      if (drv_cfg.iter_gap_ns > 0) #(drv_cfg.iter_gap_ns * 1ns);
      t_it = $time;
      if (kh >= 0) begin
        if (kc >= 0)
          drv_q_cmds[kc].push_back($sformatf("dma-to-device -d /dev/${DEV}-ST-%0d -s %0d -c 1", drv_qs[kh].rel_qid, drv_req_bytes(it)));
        TSK_DRV_H2C_REQ(kh, ok);
        if (!ok) begin
          `uvm_info("DRV_SEQ", $sformatf("board loop qid %0d: iteration %0d H2C request did not retire; %s",
                                         drv_qs[kh].hw_qid, it, drv_cfg.loop_continue ? "continuing" : "loop stopped"), UVM_NONE)
          if (!drv_cfg.loop_continue) break;
        end
      end
      if (kc >= 0) begin
        // A hang is retried on the next read, as the host's next dma-from-device
        // would; an entry error stays fatal for the queue
        if (drv_cfg.loop_continue && drv_qs[kc].dead && drv_qs[kc].hung) begin
          drv_qs[kc].dead = 1'b0;
          drv_qs[kc].hung = 1'b0;
        end
        TSK_DRV_GEN_START(kc, 1);
        TSK_DRV_C2H_READ_TO(kc, it + 1);
        drv_q_cmds[kc].push_back($sformatf("dma-from-device -d /dev/${DEV}-ST-%0d -s %0d -c 1 -f c2h_q%0d_%0d.bin",
                                           drv_qs[kc].rel_qid, drv_qs[kc].pkt_bytes, drv_qs[kc].rel_qid, it));
        if (drv_qs[kc].dead) begin
          `uvm_info("DRV_SEQ", $sformatf("board loop qid %0d: iteration %0d C2H read did not complete; %s",
                                         drv_qs[kc].hw_qid, it, (drv_cfg.loop_continue && drv_qs[kc].hung) ? "continuing" : "loop stopped"), UVM_NONE)
          if (!(drv_cfg.loop_continue && drv_qs[kc].hung)) break;
        end
      end
      lat_ns = int'(($time - t_it) / 1ns);
      if (it == 0) lat0_ns = lat_ns;
      `uvm_info("DRV_SEQ", $sformatf("board loop qid %0d: iteration %0d took %0d ns%s", (kh >= 0) ? drv_qs[kh].hw_qid : drv_qs[kc].hw_qid,
                                     it, lat_ns, (it > 0 && lat_ns > 2 * lat0_ns) ? " -- SLOWER than twice iteration 0" : ""), UVM_NONE)
      if (it <= 1) TSK_DRV_DBG_SNAP($sformatf("after iteration %0d", it));
    end
    if (kc >= 0 && drv_qs[kc].ret_pend > 0) begin
      TSK_DRV_C2H_POST(kc, (drv_qs[kc].pidx_c2h + drv_qs[kc].ret_pend) % drv_qs[kc].rngsz);
      drv_qs[kc].ret_pend = 0;
    end
  end
endtask

//------------------------------------------------------------------------------
// End of run: IP error registers and per-queue SW-context error bits
//------------------------------------------------------------------------------
task TSK_DRV_ERR_SWEEP();
  bit [31:0]  rd;
  bit [255:0] w;
  bit         ok;
  bit [31:0]  impl_off [5] = '{32'hAF0, 32'hB10, 32'hB30, 32'h2180, 32'h2184};
  string      impl_nm  [5] = '{"C2H_ERR_STAT (bit 9: packet over 7 descriptors)",
                               "C2H descriptor-response drop count",
                               "C2H first error {type, qid}",
                               "C2HST_ERR_STAT (no descriptor / short / over-append / credit headroom / bypass)",
                               "C2HST first error"};
  bit [31:0]  unmap_off [4] = '{32'hAF8, 32'hE00, 32'hE08, 32'hBE4};
  begin
    // SW-context error bits of every queue (set by ECC, invalidate, bad PIDX)
    foreach (drv_qs[k]) begin
      TSK_DRV_CTXT_RD(drv_qs[k].hw_qid, drv_qs[k].dir_c2h ? 4'h0 : 4'h1, w, ok);
      void'(dma_req_proc.drv_chk("DRV_ERR_REG", ok && w[59:58] == 2'b00 && !w[60], $sformatf(
        "%s qid %0d SW context: %s err %0b err_wb_sent %0b", drv_qs[k].dir_c2h ? "C2H" : "H2C", drv_qs[k].hw_qid,
        ok ? "" : "read failed,", w[59:58], w[60])));
    end
    foreach (impl_off[i]) begin
      issue_reg_read(PF_DMA_BAR_INDEX, impl_off[i], , , , rd);
      if (i == 0 && dma_req_proc.drv_inject("ERR_REG")) rd = rd ^ 32'h1;   // checker's copy only
      void'(dma_req_proc.drv_chk("DRV_ERR_REG", rd == 32'h0, $sformatf("0x%0h %s = 0x%08h", impl_off[i], impl_nm[i], rd)));
    end
    issue_reg_read(PF_DMA_BAR_INDEX, 32'h248, , , , rd);
    void'(dma_req_proc.drv_chk("DRV_ERR_REG", rd == 32'h0, $sformatf("0x248 GLBL_ERR_STAT = 0x%08h (reads 0 in this IP)", rd)));
    foreach (unmap_off[i]) begin
      if (i == $size(unmap_off) - 1 && dma_req_proc.drv_inj.exists("MMIO_CTO")) begin
        void'(dma_req_proc.drv_inject("MMIO_CTO"));
        drv_mmio_cto_once = 1;                                          // 1 ns budget
      end
      issue_reg_read(PF_DMA_BAR_INDEX, unmap_off[i], , , , rd);
      if (!drv_mmio_dead)
        void'(dma_req_proc.drv_chk("DRV_ERR_REG", rd == DRV_UNMAPPED, $sformatf(
          "0x%0h reads 0x%08h, expected the unimplemented-register value 0x%08h (register map changed?)", unmap_off[i], rd, DRV_UNMAPPED)));
    end
  end
endtask

//------------------------------------------------------------------------------
// Host commands for the same procedure (the board runs these)
//------------------------------------------------------------------------------
task TSK_DRV_HOST_SCRIPT(input string direction);
  int    fd;
  bit    done_k [int];
  begin
    fd = $fopen("drv_board_cmds.sh", "w");
    if (fd == 0) begin
      `uvm_warning("DRV_SEQ", "drv_board_cmds.sh could not be written")
      return;
    end
    $fdisplay(fd, "#!/bin/bash");
    $fdisplay(fd, "# Host commands equivalent to this driver-sequence simulation (generated).");
    $fdisplay(fd, "# Order: %s. Notify: %s. Ring index %0d (%0d entries), completion ring index %0d.",
              drv_cfg.board ? "BOARD" : "CONCURRENT (queues below run one after another)", drv_cfg.notify.name(),
              drv_cfg.ring_idx, DRV_RNG_TBL[drv_cfg.ring_idx], drv_cfg.cmpt_ring_idx);
    $fdisplay(fd, "set -e");
    $fdisplay(fd, "DEV=qdma01000");
    $fdisplay(fd, "insmod qdma-pf.ko config_bar=0x01:0:1 mode=0x01:0:%0d", drv_cfg.notify == DRV_DIRECT ? 2 : 1);
    $fdisplay(fd, "echo %0d > /sys/bus/pci/devices/0000:01:00.0/qdma/qmax", QUEUE_PER_PF);
    foreach (drv_pre_cmds[i]) $fdisplay(fd, "%s", drv_pre_cmds[i]);
    foreach (drv_qs[k]) begin
      int kh, kc, rel;
      string d;
      if (done_k.exists(k)) continue;
      if (!drv_qs[k].is_pf) begin
        $fdisplay(fd, "# fnc %0d (VF) queue %0d: run from the VF driver, not covered here", drv_qs[k].fnc, drv_qs[k].rel_qid);
        done_k[k] = 1'b1;
        continue;
      end
      kh = -1; kc = -1; rel = drv_qs[k].rel_qid;
      foreach (drv_qs[j])
        if (drv_qs[j].fnc == drv_qs[k].fnc && drv_qs[j].rel_qid == rel) begin
          if (drv_qs[j].dir_c2h) kc = j; else kh = j;
          done_k[j] = 1'b1;
        end
      d = (kh >= 0 && kc >= 0) ? "bi" : (kc >= 0) ? "c2h" : "h2c";
      $fdisplay(fd, "dma-ctl $DEV q add idx %0d mode st dir %s", rel, d);
      if (drv_cfg.ring_idx != 9)
        $fdisplay(fd, "# ring index %0d: add the dma-ctl ring-size index argument to q start below", drv_cfg.ring_idx);
      if (kh >= 0) $fdisplay(fd, "dma-ctl $DEV q start idx %0d dir h2c", rel);
      if (kc >= 0) $fdisplay(fd, "dma-ctl $DEV q start idx %0d dir c2h %sfetch_credit c2h", rel, drv_cfg.pfch_en ? "pfetch_en " : "");
      if (kc >= 0) $fdisplay(fd, "dma-ctl $DEV q dump idx %0d dir c2h", rel);
      if (drv_cfg.board_loop) begin
        // Per iteration, in the order run: H2C write, generator, C2H read
        if (kc >= 0 && drv_q_cmds.exists(kc))
          for (int i = 0; i < drv_q_cmds[kc].size(); i++) $fdisplay(fd, "%s", drv_q_cmds[kc][i]);
        else if (kh >= 0)
          for (int i = 0; i < drv_qs[kh].n_items; i++)
            $fdisplay(fd, "dma-to-device -d /dev/${DEV}-ST-%0d -s %0d -c 1", rel, drv_req_bytes(i));
        if (kc >= 0) $fdisplay(fd, "dma-ctl $DEV q dump idx %0d dir c2h", rel);
      end else begin
      if (kh >= 0) $fdisplay(fd, "dma-to-device -d /dev/${DEV}-ST-%0d -s %0d -c %0d", rel, DMA_BYTE_CNT, drv_qs[kh].n_items);
      if (kc >= 0) begin
        if (drv_q_cmds.exists(kc))
          for (int i = 0; i < drv_q_cmds[kc].size(); i++) $fdisplay(fd, "%s", drv_q_cmds[kc][i]);
        $fdisplay(fd, "dma-from-device -d /dev/${DEV}-ST-%0d -s %0d -c %0d -f c2h_q%0d.bin",
                  rel, drv_qs[kc].pkt_bytes, drv_qs[kc].n_items, rel);
        $fdisplay(fd, "dma-ctl $DEV q dump idx %0d dir c2h", rel);
      end
      end
      if (kh >= 0) $fdisplay(fd, "dma-ctl $DEV q stop idx %0d dir h2c", rel);
      if (kc >= 0) $fdisplay(fd, "dma-ctl $DEV q stop idx %0d dir c2h", rel);
      $fdisplay(fd, "dma-ctl $DEV q del idx %0d dir %s", rel, d);
    end
    $fclose(fd);
    `uvm_info("DRV_SEQ", "host commands for this procedure written to drv_board_cmds.sh, register trace to drv_reg_trace.log", UVM_NONE)
  end
endtask

//------------------------------------------------------------------------------
// Top level
//------------------------------------------------------------------------------
task TSK_QDMA_ST_DRV_SEQ(input int npf, input int nvf, input int nq, input string direction);
  drv_q_t q;
  int     qcnt, port;
  int     h2c_ok, h2c_full, h2c_n, c2h_ok, c2h_full, c2h_n;
  begin
    TSK_DRV_CFG_PARSE();
    dma_req_proc.drv_begin();
    dma_req_proc.drv_c2h_irq_off = 1'b1;
    dma_req_proc.irq_en          = (drv_cfg.notify == DRV_DIRECT);
    TSK_C2H_SRC_SCHED_INIT();
    TSK_DRV_GLBL_INIT();

    // Queue list in start order: PFs, then VFs. Per queue, BOARD order starts
    // H2C then C2H (two q start commands); CONCURRENT order starts C2H then
    // H2C (the order "q start ... dir bi" uses).
    drv_qs.delete();
    qcnt = 0;
    for (int f = 0; f < npf + nvf; f++) begin
      int fnc;
      fnc = (f < npf) ? f : VF_OFFSET + (f - npf);
      for (int j = 0; j < nq; j++) begin
        port = drv_cfg.port_driver ? 0 : (qcnt % num_dma_ports) + dma_port_base;
        qcnt++;
        if (drv_cfg.board && direction != "C2H") begin
          TSK_DRV_Q_RESOLVE(fnc, drv_cfg.qid_base + j, 1'b0, port, q);
          drv_qs.push_back(q);
        end
        if (direction != "H2C") begin
          TSK_DRV_Q_RESOLVE(fnc, drv_cfg.qid_base + j, 1'b1, port, q);
          drv_qs.push_back(q);
        end
        if (!drv_cfg.board && direction != "C2H") begin
          TSK_DRV_Q_RESOLVE(fnc, drv_cfg.qid_base + j, 1'b0, port, q);
          drv_qs.push_back(q);
        end
      end
    end

    // Board: the generator is identified before any queue is added
    if (drv_cfg.board)
      foreach (drv_qs[k]) if (drv_qs[k].dir_c2h) TSK_DRV_GEN_PROBE(drv_qs[k].port);

    // Serial setup: function init, vectors, contexts
    foreach (drv_qs[k]) begin
      TSK_DRV_FNC_INIT(drv_qs[k].fnc, drv_qs[k].is_pf, drv_qs[k].pfn, drv_qs[k].vfn,
                       drv_qs[k].q_base, drv_qs[k].q_count);
      drv_qs[k].notify = drv_fnc_notify[drv_qs[k].fnc];
      drv_qs[k].vec    = (drv_qs[k].notify == DRV_DIRECT) ? drv_alloc_vec(drv_qs[k].fnc) : 0;
      // A queue polled inside an interrupt-mode run expects no interrupt
      if (drv_cfg.notify == DRV_DIRECT && drv_qs[k].notify == DRV_POLL) begin
        if (drv_qs[k].hw_qid < 64) dma_req_proc.poll_qid_mask[drv_qs[k].hw_qid] = 1'b1;
        else `uvm_warning("DRV_SEQ", $sformatf("qid %0d is polled but beyond the scoreboard's 64-queue poll mask", drv_qs[k].hw_qid))
      end
      if (!drv_qs[k].dir_c2h && drv_qs[k].notify == DRV_DIRECT) drv_vec_h2c[drv_qs[k].fnc][drv_qs[k].vec] = 1'b1;
      if (drv_qs[k].dir_c2h) begin
        TSK_DRV_C2H_SETUP(k);
        if (drv_cfg.board) TSK_DRV_CTXT_DUMP(k, "after q start");
      end else
        TSK_DRV_H2C_SETUP(k);
    end

    if (drv_cfg.board && drv_cfg.board_loop) begin
      // The host's repeat loop, one queue (H2C + C2H of the same index) at a time
      bit done_k [int];
      foreach (drv_qs[k]) begin
        int kh, kc;
        if (done_k.exists(k)) continue;
        kh = -1; kc = -1;
        foreach (drv_qs[j])
          if (drv_qs[j].fnc == drv_qs[k].fnc && drv_qs[j].rel_qid == drv_qs[k].rel_qid) begin
            if (drv_qs[j].dir_c2h) kc = j; else kh = j;
            done_k[j] = 1'b1;
          end
        TSK_DRV_BOARD_LOOP(kh, kc);
        if (kc >= 0) TSK_DRV_CTXT_DUMP(kc, "after the reads");
      end
    end else if (drv_cfg.board) begin
      // One queue after another: H2C writes, generator, C2H reads, dump
      foreach (drv_qs[k]) begin
        if (!drv_qs[k].dir_c2h) begin
          TSK_DRV_H2C_RUN(k);
          TSK_DRV_DBG_SNAP($sformatf("after the H2C writes, qid %0d", drv_qs[k].hw_qid));
        end else begin
          TSK_DRV_GEN_START(k, drv_gen_room(k));
          TSK_DRV_C2H_RUN(k);
          TSK_DRV_CTXT_DUMP(k, "after the reads");
        end
      end
    end else begin
      // Traffic: one thread per queue and direction
      drv_n_live = 0;
      foreach (drv_qs[i]) begin
        automatic int k = i;
        drv_n_live++;
        fork
          begin
            if (drv_qs[k].dir_c2h) TSK_DRV_C2H_RUN(k);
            else                   TSK_DRV_H2C_RUN(k);
            drv_n_live--;
          end
        join_none
      end
      wait (drv_n_live == 0);
    end

    wait (drv_pl_live == 0);
    TSK_DRV_DBG_SNAP("end of traffic");

    // Summary and cross-checks
    h2c_ok = 0; h2c_full = 0; h2c_n = 0; c2h_ok = 0; c2h_full = 0; c2h_n = 0;
    foreach (drv_qs[k]) begin
      if (drv_qs[k].dir_c2h) begin c2h_ok += drv_qs[k].n_ok; c2h_full += drv_qs[k].n_full; c2h_n += drv_qs[k].n_items; end
      else                   begin h2c_ok += drv_qs[k].n_ok; h2c_full += drv_qs[k].n_full; h2c_n += drv_qs[k].n_items; end
      `uvm_info("DRV_SEQ", $sformatf("  %s qid %0d fnc %0d %s vec %0d %s: %0d of %0d retired, %0d fully checked, %0d interrupt wake(s)%s",
        drv_qs[k].dir_c2h ? "C2H" : "H2C", drv_qs[k].hw_qid, drv_qs[k].fnc, drv_qs[k].is_pf ? "PF" : "VF",
        drv_qs[k].vec, drv_qs[k].notify.name(), drv_qs[k].n_ok, drv_qs[k].n_items, drv_qs[k].n_full, drv_qs[k].irq_seen,
        drv_qs[k].irq_gap ? $sformatf(", interrupt gap [%s]", drv_qs[k].gap_tag) : ""), UVM_NONE)
      // H2C: the PL side received exactly the bytes of every request issued
      if (!drv_qs[k].dir_c2h) begin
        longint unsigned exp_t, got_t;
        exp_t = 0;
        for (int r = 0; r < drv_qs[k].h2c_req; r++) exp_t += longint'(drv_req_bytes(r));
        got_t = dma_req_proc.h2c_user_data.exists(drv_qs[k].hw_qid) ? dma_req_proc.h2c_user_data[drv_qs[k].hw_qid].size() : 0;
        void'(dma_req_proc.drv_chk("DRV_H2C_PL", got_t == exp_t, $sformatf(
          "H2C qid %0d: PL side received %0d B in total, the %0d issued request(s) carry %0d B", drv_qs[k].hw_qid, got_t, drv_qs[k].h2c_req, exp_t)));
      end
      // Poll-mode queues must not raise interrupts. The per-queue interrupt
      // request count is not visible in this testbench, so this is reported only.
      if (drv_qs[k].notify == DRV_POLL)
        `uvm_info("DRV_SEQ", $sformatf("DRV_POLL_MSIX NOT OBSERVED: %s_%0d is in poll mode; per-queue interrupt requests are not monitored in this testbench",
          drv_qs[k].dir_c2h ? "C2H" : "H2C", drv_qs[k].hw_qid), UVM_LOW)
      // C2H: any byte left counted in a driver buffer was never consumed
      if (drv_qs[k].dir_c2h && dma_req_proc.drv_c2h_buf_bytes.exists(drv_qs[k].hw_qid)) begin
        longint unsigned left [int];
        left = dma_req_proc.drv_c2h_buf_bytes[drv_qs[k].hw_qid];
        foreach (left[bi])
          if (left[bi] != 0)
            void'(dma_req_proc.drv_chk("DRV_COUNT", 1'b0, $sformatf(
              "C2H qid %0d buffer %0d received %0d byte(s) no completion accounted for", drv_qs[k].hw_qid, bi, left[bi])));
      end
    end
    foreach (dma_req_proc.msix_fnc_vec_cnt[f, v])
      `uvm_info("DRV_SEQ", $sformatf("  MSI-X fnc %0d vec %0d: %0d", f, v, dma_req_proc.msix_fnc_vec_cnt[f][v]), UVM_NONE)
    `uvm_info("DRV_SEQ", $sformatf(
      "DRV_SEQ SUMMARY: H2C requests retired %0d/%0d (fully checked %0d), C2H packets retired %0d/%0d (fully checked %0d) (%s, %s order)",
      h2c_ok, h2c_n, h2c_full, c2h_ok, c2h_n, c2h_full, drv_cfg.notify.name(), drv_cfg.board ? "BOARD" : "CONCURRENT"), UVM_NONE)
    void'(dma_req_proc.drv_chk("DRV_COUNT", h2c_ok == h2c_n && c2h_ok == c2h_n, $sformatf(
      "DRV_SEQ incomplete by the driver's rules: H2C %0d/%0d, C2H %0d/%0d", h2c_ok, h2c_n, c2h_ok, c2h_n)));
    TSK_DRV_ERR_SWEEP();
    TSK_DRV_HOST_SCRIPT(direction);
    if (drv_trace_fd != 0) begin
      $fclose(drv_trace_fd);
      drv_trace_fd = 0;
    end
  end
endtask
