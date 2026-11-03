// Note: this file is included within proj_test_pkg; do not import that package here
typedef class qdma_base_test;
typedef class dma_req_processor;


// --- h2c_user_subscriber ---------------------------------------------------
// Subscribes to qdma_user_agent.ap and forwards H2C AXI4-Stream packets
// to dma_req_processor so it can perform data integrity checking.
class h2c_user_subscriber extends uvm_subscriber#(qdma_user_transaction);
  `uvm_component_utils(h2c_user_subscriber)
  dma_req_processor proc_ref;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void write(qdma_user_transaction txn);
    if (txn.is_h2c && proc_ref != null)
      proc_ref.receive_h2c_user_pkt(txn);
  endfunction
endclass

class dma_req_processor extends uvm_component;
  `uvm_component_utils(dma_req_processor)

  // qid -> owning-function range, registered from the FMAP programming. Declared
  // at the top of the class because SystemVerilog requires a type to be visible
  // before use, and register_fnc_qrange() below is declared ahead of the
  // MSI-X counters where the map itself lives.
  typedef struct { int q_base; int q_count; } fnc_qrange_s;

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

  // ===================================================================
  // PER-QID HETEROGENEITY
  //
  // qid_addr_shift() is the single host-address stride used by BOTH the qid
  // encode and decode; qid_byte_cnt() is the per-queue length. With no pattern
  // selected, qid_byte_cnt() == DMA_BYTE_CNT for every qid and
  // qid_addr_shift() == $clog2(DMA_BYTE_CNT).
  // ===================================================================
  typedef enum {QBP_NONE, QBP_RAMP, QBP_ALT} qid_byte_pattern_e;
  qid_byte_pattern_e qid_byte_pattern = QBP_NONE;
  // Largest per-qid byte multiplier (1 unless QID_BYTE_PATTERN widens it). Set in
  // build_phase from the plusarg; safe there because it does not read DMA_BYTE_CNT.
  int unsigned qid_max_mult = 1;
  // Host-address stride shift, computed LAZILY AT USE. It must NOT be a variable
  // assigned in build_phase: DMA_BYTE_CNT (declared above with no initialiser) is
  // still 0 at that point -- the owning test assigns it later via
  // `dma_req_proc.DMA_BYTE_CNT = ...`.
  // Stride = DMA_BYTE_CNT * qid_max_mult. The qid is ENCODED into the host
  // address at this shift and DECODED back out of it, so the per-qid base is
  // qid<<shift and each qid owns exactly one stride-sized, stride-aligned region.
  //
  // A test whose per-qid transfer EXCEEDS DMA_BYTE_CNT therefore runs off the
  // end of its own region into the next qid's, and the scoreboard splits one
  // queue's traffic across several synthetic qids. That is a TEST CONFIG error,
  // not a decode bug: set DMA_BYTE_CNT to the per-qid transfer size.
  //
  // Do not derive the shift from xfer_bytes here: the qid is encoded before
  // the xfer_bytes plusarg is applied, so the encode and the decode would use
  // different shifts.
  function int unsigned qid_addr_shift();
    return $clog2(int'(DMA_BYTE_CNT) * qid_max_mult);
  endfunction
  int unsigned byte_cnt_q[bit [10:0]];         // explicit per-qid override (unused by default)
  bit [63:0]   poll_qid_mask = 64'h0;          // bit q set => qid q POLLS (no interrupt expected)
  // Absolute qids are function-derived (hw_qid = qid + q_base; VF0 is qid 33), so a
  // fixed bitmask cannot be written without knowing the base -- and a mask that
  // matches nothing is a test that silently exercises nothing. poll_every_n selects
  // by POSITION instead: qids where (q % n) != 0 poll. Robust to any base.
  int unsigned poll_every_n = 0;               // 0 = disabled

  // Per-qid transfer size. Generated rather than list-driven: an explicit list
  // has to be kept in step with NUM_Q_TEST x function count by hand.
  function int unsigned qid_byte_cnt(bit [10:0] q);
    if (byte_cnt_q.exists(q)) return byte_cnt_q[q];
    case (qid_byte_pattern)
      QBP_RAMP: return int'(DMA_BYTE_CNT) << (q % 4);            // x1 x2 x4 x8
      QBP_ALT : return (q % 2) ? int'(DMA_BYTE_CNT) * 2 : int'(DMA_BYTE_CNT);
      default : return int'(DMA_BYTE_CNT);
    endcase
  endfunction

  // Per-qid interrupt enable. A polled qid expects NO MSI-X; its completion is
  // still observed host-side by the byte-count scoreboard, which does not depend
  // on interrupts.
  function bit qid_irq_en(bit [10:0] q);
    if (q < 64 && poll_qid_mask[q])                return 1'b0;
    if (poll_every_n > 1 && (q % poll_every_n))    return 1'b0;
    return irq_en;
  endfunction

  // Register one function's queue range. Called from TSK_FNC_MAP_PGM, which is
  // the single place the FMAP q_base/q_count are programmed, so the map here
  // cannot drift from what the DUT was told.
  function void register_fnc_qrange(int fnc, int q_base, int q_count);
    fnc_qrange_s r;
    r.q_base  = q_base;
    r.q_count = q_count;
    fnc_qrange[fnc] = r;
    `uvm_info("DMA_SCOREBOARD", $sformatf(
      "QID_FNC_MAP: fnc=%0d owns qid %0d..%0d", fnc, q_base, q_base + q_count - 1), UVM_MEDIUM)
  endfunction

  // Owning function for a qid, or -1 if no range covers it. -1 is handled
  // explicitly at the call site rather than defaulting to function 0, which
  // would silently reintroduce cross-function credit.
  function int qid_fnc(bit [10:0] q);
    foreach (fnc_qrange[f])
      if (int'(q) >= fnc_qrange[f].q_base &&
          int'(q) <  fnc_qrange[f].q_base + fnc_qrange[f].q_count)
        return f;
    return -1;
  endfunction

  // Expected total bytes for one queue.
  function longint unsigned qid_exp_bytes(bit [10:0] q);
    longint unsigned t;
    // +XFER_LIST mode: the queue's expected
    // total is the SUM across all sequential packets, not any single packet's
    // xfer_bytes -- otherwise this check would be satisfied after packet 0
    // alone and the test would (wrongly) call the queue complete before the
    // later packets ever ran.
    // Null-guarded: this function is also called from report_phase (for the
    // summary's expected byte count), which runs even after a UVM_FATAL.
    if (test_ref != null && test_ref.xfer_list.size() > 0) begin
      t = 0;
      foreach (test_ref.xfer_list[i]) t += longint'(test_ref.xfer_list[i]);
      return t;
    end
    else if (xfer_bytes > 0)         return longint'(xfer_bytes);
    else if (total_dsc_cnt > 0) return longint'(total_dsc_cnt) * qid_byte_cnt(q);
    else                        return longint'(pidx) * qid_byte_cnt(q);
  endfunction
  // C2H-ST packet size and descriptors per packet, set by the test when the
  // example-design C2H source is programmed to a size other than
  // DMA_BYTE_CNT (+C2H_PKT_BYTES). 0 keeps every C2H rule on DMA_BYTE_CNT.
  // Each queue's packets all land in one window of c2h_pkt_bytes, pidx counts
  // packets, and the C2H ring advances c2h_dsc_per_pkt descriptors per packet.
  int unsigned c2h_pkt_bytes   = 0;
  int unsigned c2h_dsc_per_pkt = 1;

  // C2H destination window of one queue
  function int unsigned c2h_win_bytes(bit [10:0] q);
    return (c2h_pkt_bytes != 0) ? c2h_pkt_bytes : qid_byte_cnt(q);
  endfunction

  // Expected C2H bytes for one queue: pidx packets
  function longint unsigned c2h_exp_bytes(bit [10:0] q);
    return (c2h_pkt_bytes != 0) ? longint'(pidx) * c2h_pkt_bytes : qid_exp_bytes(q);
  endfunction

  // Completion (CMPT) rings of C2H-ST queues, registered by the test at queue
  // setup. Every 8-byte data entry the DMA writes into a registered ring is
  // checked against the driver's standard C2H completion format -- the entry
  // the driver decodes to retire a packet:
  //   [0] format 0, [1] colour (1 on the first pass, flips per ring wrap),
  //   [2] error 0, [3] desc_used 1, [19:4] packet length, [30:20] qid.
  // The ring holds ring_entries-1 data entries; the last slot is the status
  // entry, which is not a packet completion and is not checked here.
  // An entry without desc_used or length is one a driver cannot retire: it
  // decodes as a zero-length packet that used no descriptors.
  longint unsigned cmpt_ring_base [bit [10:0]];
  int unsigned     cmpt_ring_ents [bit [10:0]];   // ring size incl. the status entry
  int unsigned     cmpt_entry_cnt [bit [10:0]];   // data entries written per queue
  int unsigned     cmpt_entry_ok = 0, cmpt_entry_err = 0, cmpt_status_wr = 0;

  // ents: completion-ring size including the status entry; 0 = same as the
  // descriptor ring (ring_entries). The driver sizes the completion ring from
  // its own ring-size table entry, which can differ from the descriptor ring.
  function void register_cmpt_ring(bit [10:0] qid, longint unsigned base, int unsigned ents = 0);
    cmpt_ring_base[qid] = base;
    cmpt_ring_ents[qid] = (ents != 0) ? ents : ring_entries;
    cmpt_entry_cnt[qid] = 0;
  endfunction

  //----------------------------------------------------------------------------
  // Driver-sequence checks (active only while drv_mode is set)
  //
  // Each check has an ID, a label and an evaluation count:
  //   driver-equivalent    - a failure is a transfer the Linux driver fails on
  //                          the board (queue error, hang, wrong credit)
  //   stricter-than-driver - the driver would not notice (payload, length,
  //                          timing windows); a latent defect
  //   IP error flag        - an IP error register the driver never reads
  // +DRV_CHK_WARN=<id,...> demotes checks to warnings without a rebuild; a
  // demoted driver-equivalent check is reported in the summary.
  // +DRV_TEST_INJECT=<name,...> perturbs the checker's own copy of one value
  // (never the DUT, never what the engine sees) so each check is shown able to
  // fail; injection and demotion cannot be combined.
  //----------------------------------------------------------------------------
  int unsigned drv_chk_eval   [string];
  int unsigned drv_chk_nfail  [string];
  bit          drv_chk_demote [string];
  bit          drv_inj        [string];
  bit          drv_inj_used   [string];
  // Completion latency per direction (engine wait from doorbell/consume to completion)
  int          drv_lat_n      [string];
  longint      drv_lat_sum    [string];
  int          drv_lat_max    [string];

  function void drv_note_latency(string dir, int ns);
    if (!drv_lat_n.exists(dir)) begin
      drv_lat_n[dir] = 0; drv_lat_sum[dir] = 0; drv_lat_max[dir] = 0;
    end
    drv_lat_n[dir]++;
    drv_lat_sum[dir] += ns;
    if (ns > drv_lat_max[dir]) drv_lat_max[dir] = ns;
  endfunction

  function string drv_chk_label(string id);
    case (id)
      "DRV_STS_BEFORE_ENTRY", "DRV_BUF_NOT_POSTED", "DRV_MSIX_LOST", "DRV_C2H_NO_MSIX",
      "DRV_ENTRY_FIELDS", "DRV_UNKNOWN_MWR", "DRV_COUNT", "DRV_RANGE", "DRV_MMIO_CTO", "DRV_HANG",
      "DRV_GLBL", "DRV_CTXT":
        return "driver-equivalent";
      "DRV_ERR_REG":
        return "IP error flag";
      default:
        return "stricter-than-driver";
    endcase
  endfunction

  function bit drv_chk(string id, bit ok, string msg);
    drv_chk_eval[id] = (drv_chk_eval.exists(id) ? drv_chk_eval[id] : 0) + 1;
    if (!drv_chk_nfail.exists(id)) drv_chk_nfail[id] = 0;
    if (!ok) begin
      drv_chk_nfail[id]++;
      if (drv_chk_demote.exists(id))
        `uvm_warning(id, $sformatf("%s [%s, demoted]", msg, drv_chk_label(id)))
      else
        `uvm_error(id, $sformatf("%s [%s]", msg, drv_chk_label(id)))
    end
    return ok;
  endfunction

  // One-shot injection: true the first time it is asked for, if requested
  function bit drv_inject(string name);
    if (!drv_inj.exists(name) || drv_inj_used.exists(name)) return 1'b0;
    drv_inj_used[name] = 1'b1;
    `uvm_info("DRV_INJECT", $sformatf("injection %s applied at %0t", name, $time), UVM_NONE)
    return 1'b1;
  endfunction

  function void drv_split(string s, ref string out [$]);
    int st;
    st = 0;
    for (int i = 0; i <= s.len(); i++)
      if (i == s.len() || s.getc(i) == 8'h2C) begin   // ','
        if (i > st) out.push_back(s.substr(st, i - 1));
        st = i + 1;
      end
  endfunction

  // Called by the driver-sequence engine before any traffic
  function void drv_begin();
    string s;
    string l [$];
    drv_mode = 1'b1;
    if ($value$plusargs("DRV_CHK_WARN=%s", s)) begin
      drv_split(s, l);
      foreach (l[i]) drv_chk_demote[l[i]] = 1'b1;
    end
    l.delete();
    if ($value$plusargs("DRV_TEST_INJECT=%s", s)) begin
      drv_split(s, l);
      foreach (l[i]) drv_inj[l[i]] = 1'b1;
    end
    if (drv_inj.size() != 0 && drv_chk_demote.size() != 0)
      `uvm_fatal("DRV_INJECT", "+DRV_TEST_INJECT cannot be combined with +DRV_CHK_WARN: an injection run must see every check at full severity")
  endfunction

  // Driver-posted C2H buffers. Each buffer sits at its own fixed address
  // (scattered pages, as the driver allocates them; descriptors are never
  // rewritten). A host write is mapped to (queue, buffer index) through the
  // start address of the buffer it falls in, and counted per buffer, so the
  // engine can require exactly the expected bytes in the buffers it consumed
  // and none in any other (packets of one burst carry the same payload, so a
  // packet in the wrong buffer is otherwise invisible).
  typedef struct {
    int unsigned n;          // buffers in the ring
    int unsigned bufsz;
  } drv_c2h_ring_s;
  typedef struct {
    int q;
    int idx;
  } drv_buf_loc_s;
  drv_c2h_ring_s   drv_c2h_ring      [bit [10:0]];
  drv_buf_loc_s    drv_buf_at        [longint unsigned];    // buffer start address -> owner
  int unsigned     drv_buf_sz        = 0;                   // one buffer size for every queue
  longint unsigned drv_c2h_buf_bytes [bit [10:0]][int];     // bytes landed, as the engine sees them
  longint unsigned drv_chk_buf_bytes [bit [10:0]][int];     // the ordering check's own copy
  // Ownership: 1 from the PIDX write that posts a buffer until the engine
  // returns it after reading it. The DMA may write only owned buffers.
  bit              drv_buf_posted    [bit [10:0]][int];
  int unsigned     drv_post_pidx     [bit [10:0]];
  bit              drv_bnp_seen      [bit [10:0]][int];     // buffer already reported as written unposted
  int unsigned     drv_entry_buf_ptr [bit [10:0]];          // first buffer of the next entry
  int unsigned     drv_exp_pkts      [bit [10:0]];

  function void register_drv_c2h_ring(bit [10:0] q, longint unsigned addrs [$], int unsigned bufsz,
                                      int unsigned n_pkts);
    if (bufsz == 0 || (drv_buf_sz != 0 && drv_buf_sz != bufsz))
      `uvm_fatal("DRV_SEQ", $sformatf("qid %0d: buffer size %0d (every queue must use one buffer size, %0d registered)",
                                      q, bufsz, drv_buf_sz))
    drv_buf_sz      = bufsz;
    drv_c2h_ring[q] = '{n: addrs.size(), bufsz: bufsz};
    foreach (addrs[i]) begin
      if (addrs[i] % bufsz != 0)
        `uvm_fatal("DRV_SEQ", $sformatf("qid %0d buffer %0d at 0x%0h is not %0d-byte aligned", q, i, addrs[i], bufsz))
      if (drv_buf_at.exists(addrs[i]))
        `uvm_fatal("DRV_SEQ", $sformatf("qid %0d buffer %0d at 0x%0h already belongs to qid %0d buffer %0d",
                                        q, i, addrs[i], drv_buf_at[addrs[i]].q, drv_buf_at[addrs[i]].idx))
      drv_buf_at[addrs[i]] = '{q: int'(q), idx: i};
    end
    drv_c2h_buf_bytes.delete(q);
    drv_chk_buf_bytes.delete(q);
    drv_buf_posted.delete(q);
    drv_post_pidx[q]     = 0;
    drv_entry_buf_ptr[q] = 0;
    drv_exp_pkts[q]      = n_pkts;
  endfunction

  // (queue, buffer index) of the driver buffer holding addr
  function bit drv_buf_lookup(longint unsigned addr, output int q, output int idx);
    longint unsigned start;
    q = -1; idx = -1;
    if (drv_buf_sz == 0) return 1'b0;
    start = addr - (addr % drv_buf_sz);
    if (!drv_buf_at.exists(start)) return 1'b0;
    q   = drv_buf_at[start].q;
    idx = drv_buf_at[start].idx;
    return 1'b1;
  endfunction

  function longint unsigned drv_c2h_buf_got(bit [10:0] q, int idx);
    if (!drv_c2h_buf_bytes.exists(q) || !drv_c2h_buf_bytes[q].exists(idx)) return 0;
    return drv_c2h_buf_bytes[q][idx];
  endfunction

  // Called by the engine BEFORE each C2H PIDX write: buffers [previous pidx,
  // pidx) are handed to the DMA.
  function void drv_c2h_post(bit [10:0] q, int unsigned pidx);
    int unsigned i;
    i = drv_post_pidx[q];
    while (i != pidx) begin
      void'(drv_chk("DRV_REPOST", drv_c2h_buf_got(q, int'(i)) == 0,
                    $sformatf("qid %0d buffer %0d reposted while holding %0d byte(s) never consumed",
                              q, i, drv_c2h_buf_got(q, int'(i)))));
      if (drv_bnp_seen.exists(q) && drv_bnp_seen[q].exists(int'(i))) drv_bnp_seen[q].delete(int'(i));
      if (!(i == 0 && drv_inject("BUF_NOT_POSTED")))
        drv_buf_posted[q][int'(i)] = 1'b1;
      i = (i + 1) % drv_c2h_ring[q].n;
    end
    drv_post_pidx[q] = pidx;
  endfunction

  // Called by the engine once it has read a buffer: ownership back to the host
  function void drv_c2h_return(bit [10:0] q, int idx);
    if (drv_buf_posted.exists(q) && drv_buf_posted[q].exists(idx)) drv_buf_posted[q].delete(idx);
    if (drv_c2h_buf_bytes.exists(q) && drv_c2h_buf_bytes[q].exists(idx)) drv_c2h_buf_bytes[q].delete(idx);
    if (drv_chk_buf_bytes.exists(q) && drv_chk_buf_bytes[q].exists(idx)) drv_chk_buf_bytes[q].delete(idx);
  endfunction

  // Completion-ring status as processed here, in host-write order. The
  // engine judges from this value rather than raw host memory, so it never
  // reads entries the checks below have not seen yet.
  int          drv_sts_pidx  [bit [10:0]];
  int unsigned drv_sts_pass  [bit [10:0]];
  int unsigned drv_slot_pass [bit [10:0]][int];   // ring pass (+1) in which each slot was written

  function int drv_c2h_sts_pidx(bit [10:0] q);
    return drv_sts_pidx.exists(q) ? drv_sts_pidx[q] : 0;
  endfunction

  // H2C: last doorbell and ring size per queue, for the writeback range check
  int unsigned drv_h2c_db     [bit [10:0]];
  int unsigned drv_h2c_rngsz  [bit [10:0]];
  function void drv_h2c_doorbell(bit [10:0] q, int unsigned pidx, int unsigned rngsz);
    drv_h2c_db[q]    = pidx;
    drv_h2c_rngsz[q] = rngsz;
  endfunction

  // Lost wakeup (direct interrupt mode): every status advance of a queue on a
  // vector must be followed by an MSI-X on that vector, or the driver sleeps
  // on it. Queues in poll mode are not registered.
  typedef struct {
    int fnc;
    int vec;
  } drv_vec_s;
  drv_vec_s    drv_q_vec      [string];           // "H2C_<q>" / "C2H_<q>"
  bit          drv_vec_pend   [int][int][string]; // (fnc, vec) -> queues advanced since its last MSI-X
  bit          drv_c2h_gap_q  [bit [10:0]];       // C2H queues already reported as DRV_C2H_NO_MSIX
  bit          drv_msix_drop  [int][int];         // injection: next MSI-X on the vector not counted here
  int unsigned drv_msix_stale = 0;
  int          drv_q0, drv_i0;                    // MWr classification scratch
  bit          drv_mwr_unknown;

  function void register_drv_vec(int fnc, int vec, bit [10:0] q, string dir);
    drv_q_vec[$sformatf("%s_%0d", dir, q)] = '{fnc: fnc, vec: vec};
  endfunction

  function void drv_note_c2h_gap(bit [10:0] q);
    drv_c2h_gap_q[q] = 1'b1;
  endfunction

  function void drv_irq_advance(string dir, bit [10:0] q);
    string key;
    key = $sformatf("%s_%0d", dir, q);
    if (!drv_mode || !drv_q_vec.exists(key)) return;
    drv_vec_pend[drv_q_vec[key].fnc][drv_q_vec[key].vec][key] = 1'b1;
  endfunction

  function void drv_irq_msix(int fnc, int vec);
    if (!drv_mode) return;
    if (drv_msix_drop.exists(fnc) && drv_msix_drop[fnc].exists(vec)) begin
      drv_msix_drop[fnc].delete(vec);
      void'(drv_inject("MSIX_LOST"));
      return;
    end
    if (!drv_vec_pend.exists(fnc) || !drv_vec_pend[fnc].exists(vec) || drv_vec_pend[fnc][vec].size() == 0) begin
      drv_msix_stale++;
      return;
    end
    repeat (drv_vec_pend[fnc][vec].size()) void'(drv_chk("DRV_MSIX_LOST", 1'b1, ""));
    drv_vec_pend[fnc].delete(vec);
  endfunction

  // Completion-ring write in driver mode: entry order, pass, data-before-entry
  function void drv_cmpt_entry(bit [10:0] q, int unsigned idx, int unsigned n1, bit [63:0] e);
    int unsigned pass, slot, len, nd, ptr, bufsz;
    bit          ok;
    string       why;
    pass = cmpt_entry_cnt[q] / n1;
    slot = cmpt_entry_cnt[q] % n1;
    void'(drv_chk("DRV_RANGE", idx == slot,
                  $sformatf("qid %0d completion entry written at slot %0d, expected slot %0d (entry %0d)",
                            q, idx, slot, cmpt_entry_cnt[q])));
    if (!(cmpt_entry_cnt[q] == 0 && drv_inject("STS_BEFORE_ENTRY")))
      drv_slot_pass[q][int'(idx)] = pass + 1;
    if (!drv_c2h_ring.exists(q)) return;
    // The packet's buffers must hold all of its bytes before its entry lands
    bufsz = drv_c2h_ring[q].bufsz;
    len   = (e[3] && e[19:4] != 0) ? int'(e[19:4]) : int'(c2h_win_bytes(q));
    nd    = (len + bufsz - 1) / bufsz;
    ptr   = drv_entry_buf_ptr[q];
    ok    = 1'b1;
    why   = "";
    for (int unsigned j = 0; j < nd; j++) begin
      int unsigned bi, need;
      longint unsigned got;
      bi   = (ptr + j) % drv_c2h_ring[q].n;
      need = (len - j * bufsz > bufsz) ? bufsz : len - j * bufsz;
      got  = (drv_chk_buf_bytes.exists(q) && drv_chk_buf_bytes[q].exists(int'(bi))) ? drv_chk_buf_bytes[q][int'(bi)] : 0;
      if (got != need) begin
        ok  = 1'b0;
        why = {why, $sformatf(" buffer %0d holds %0d of %0d B;", bi, got, need)};
      end
    end
    void'(drv_chk("DRV_ENTRY_BEFORE_DATA", ok,
                  $sformatf("qid %0d completion entry %0d (%0d B) written before its data:%s the driver would hand stale buffer contents to the application",
                            q, cmpt_entry_cnt[q], len, why)));
    drv_entry_buf_ptr[q] = (ptr + nd) % drv_c2h_ring[q].n;
  endfunction

  // Completion-ring status write in driver mode: the status pidx may cover
  // only slots written in the current ring pass
  function void drv_cmpt_status(bit [10:0] q, int unsigned n1, bit [63:0] e);
    int unsigned p, pchk, p0, s, ep, first_bad, nbad;
    p    = int'(e[15:0]);
    pchk = p;
    if (drv_inject("STS_RANGE")) pchk = n1;                 // checker's copy only
    p0 = drv_c2h_sts_pidx(q);
    ep = drv_sts_pass.exists(q) ? drv_sts_pass[q] : 0;
    if (!drv_chk("DRV_RANGE", pchk < n1,
                 $sformatf("qid %0d completion status pidx %0d is not below the %0d-entry ring", q, pchk, n1)) && p >= n1)
      return;
    s = p0; nbad = 0; first_bad = 0;
    while (s != p) begin
      if (!drv_slot_pass.exists(q) || !drv_slot_pass[q].exists(int'(s)) || drv_slot_pass[q][int'(s)] != ep + 1) begin
        if (nbad == 0) first_bad = s;
        nbad++;
      end
      s++;
      if (s == n1) begin s = 0; ep++; end
    end
    void'(drv_chk("DRV_STS_BEFORE_ENTRY", nbad == 0,
                  $sformatf("qid %0d completion status pidx %0d -> %0d covers %0d slot(s) not yet written in this ring pass (first: slot %0d) -- the driver reads that entry: on the first pass a permanent queue error, later a colour stall",
                            q, p0, p, nbad, first_bad)));
    if (p != p0) drv_irq_advance("C2H", q);
    drv_sts_pidx[q] = int'(p);
    drv_sts_pass[q] = ep;
  endfunction

  // End of a driver-sequence run: counts, lost wakeups, check summary
  function void drv_final();
    int unsigned n1;
    foreach (drv_exp_pkts[q]) begin
      n1 = (cmpt_ring_ents.exists(q) ? cmpt_ring_ents[q] : ring_entries) - 1;
      void'(drv_chk("DRV_COUNT", cmpt_entry_cnt.exists(q) && cmpt_entry_cnt[q] == drv_exp_pkts[q],
                    $sformatf("qid %0d: %0d completion entries for %0d packets", q,
                              cmpt_entry_cnt.exists(q) ? cmpt_entry_cnt[q] : 0, drv_exp_pkts[q])));
      void'(drv_chk("DRV_COUNT", drv_c2h_sts_pidx(q) == int'(drv_exp_pkts[q] % n1),
                    $sformatf("qid %0d: final completion status pidx %0d, expected %0d", q,
                              drv_c2h_sts_pidx(q), drv_exp_pkts[q] % n1)));
    end
    foreach (drv_h2c_db[q])
      void'(drv_chk("DRV_COUNT", h2c_wb_status_cidx.exists(q) && h2c_wb_status_cidx[q] == 16'(drv_h2c_db[q]),
                    $sformatf("qid %0d: final H2C status cidx %0d, last doorbell pidx %0d", q,
                              h2c_wb_status_cidx.exists(q) ? int'(h2c_wb_status_cidx[q]) : -1, drv_h2c_db[q])));
    foreach (drv_vec_pend[f, v, key]) begin
      bit [10:0] cq;
      bit        exempt;
      exempt = 1'b0;
      if (key.substr(0, 3) == "C2H_") begin
        cq = 11'(key.substr(4, key.len() - 1).atoi());
        exempt = drv_c2h_gap_q.exists(cq);
      end
      if (!exempt)
        void'(drv_chk("DRV_MSIX_LOST", 1'b0,
                      $sformatf("%s advanced on fnc %0d vec %0d with no MSI-X after it -- a driver in direct-interrupt mode sleeps on this queue",
                                key, f, v)));
    end
    `uvm_info("DRV_CHK", $sformatf("stale MSI-X (no new status since the previous one): %0d", drv_msix_stale), UVM_NONE)
    foreach (drv_lat_n[dir])
      `uvm_info("DRV_CHK", $sformatf("DRV_LATENCY %s: %0d completions, mean %0d ns, max %0d ns", dir, drv_lat_n[dir],
                                     int'(drv_lat_sum[dir] / drv_lat_n[dir]), drv_lat_max[dir]), UVM_NONE)
    foreach (drv_chk_eval[id]) begin
      `uvm_info("DRV_CHK", $sformatf("DRV_CHK SUMMARY: %s (%s) evaluated %0d failed %0d%s",
                                     id, drv_chk_label(id), drv_chk_eval[id], drv_chk_nfail[id],
                                     drv_chk_demote.exists(id) ? " DEMOTED" : ""), UVM_NONE)
      if (drv_chk_demote.exists(id) && drv_chk_nfail[id] != 0 && drv_chk_label(id) == "driver-equivalent")
        `uvm_warning("DRV_CHK_DEMOTED", $sformatf(
          "%s is driver-equivalent and failed %0d time(s) while demoted: verdict at best PASS with demoted check",
          id, drv_chk_nfail[id]))
    end
    foreach (drv_inj[name])
      if (!drv_inj_used.exists(name))
        `uvm_error("DRV_INJECT", $sformatf("injection %s was requested but never applied", name))
  endfunction

  // qid of the registered completion ring holding addr, or -1
  function int cmpt_ring_qid(longint unsigned addr);
    foreach (cmpt_ring_base[q])
      if (addr >= cmpt_ring_base[q] && addr < cmpt_ring_base[q] + longint'(RING_SIZE) * 8)
        return int'(q);
    return -1;
  endfunction

  function void check_cmpt_entry(bit [10:0] q, longint unsigned addr, bit [63:0] e);
    int unsigned idx;
    bit          exp_col;
    int unsigned exp_len;
    int unsigned ents;
    string       why;
    ents = cmpt_ring_ents.exists(q) ? cmpt_ring_ents[q] : ring_entries;
    idx = int'((addr - cmpt_ring_base[q]) / 8);
    if (idx == ents - 1) begin
      cmpt_status_wr++;
      log_event("CMPT_STS_WR", int'(q), addr, 8, 0, 0, 0, $sformatf("status entry 0x%016h", e));
      if (drv_mode) drv_cmpt_status(q, ents - 1, e);
      return;
    end
    if (drv_mode && idx >= ents) begin
      cmpt_entry_err++;
      `uvm_error("CMPT_ENTRY", $sformatf(
        "qid %0d completion write at 0x%0h is entry %0d, past the %0d-entry ring (status entry %0d)",
        q, addr, idx, ents, ents - 1))
      return;
    end
    exp_col = 1'b1 ^ 1'((cmpt_entry_cnt[q] / (ents - 1)) & 1);
    exp_len = c2h_win_bytes(q);
    if (drv_mode) drv_cmpt_entry(q, idx, ents - 1, e);
    cmpt_entry_cnt[q]++;
    why = "";
    if (e[0])                   why = {why, " format!=0"};
    if (e[1] !== exp_col)       why = {why, $sformatf(" colour=%0d expected %0d", e[1], exp_col)};
    if (e[2])                   why = {why, " error set"};
    if (!e[3])                  why = {why, " desc_used=0"};
    if (e[19:4] != 16'(exp_len)) why = {why, $sformatf(" length=%0d expected %0d", e[19:4], exp_len)};
    if (e[30:20] != q)          why = {why, $sformatf(" qid field=%0d", e[30:20])};
    if (why == "") begin
      cmpt_entry_ok++;
      log_event("CMPT_ENTRY", int'(q), addr, 8, 0, 0, int'(cmpt_entry_cnt[q]),
                $sformatf("entry %0d = 0x%016h OK (colour %0d, desc_used 1, len %0d)", idx, e, e[1], e[19:4]));
    end else begin
      cmpt_entry_err++;
      `uvm_error("CMPT_ENTRY", $sformatf(
        "qid %0d completion entry %0d at 0x%0h = 0x%016h:%s (driver decodes format %0d colour %0d err %0d desc_used %0d len %0d)",
        q, idx, addr, e, why, e[0], e[1], e[2], e[3], e[19:4]))
    end
  endfunction

  bit h2c_trfr_done[bit [10:0]];
  bit c2h_trfr_done[bit [10:0]];
  // Set when this QID's C2H SOURCE is known to hold real data by some route other
  // than an H2C loopback pass (e.g. the c2h_source RTL pattern in ST mode). Consumed
  // by check_c2h_integrity together with h2c_trfr_done — see the guard there.
  bit c2h_src_primed[bit [10:0]];
  bit h2c_host_done[bit [10:0]];  // host-side MRD byte-count complete (informational in ST mode)
  // +C2H_SRC_OFFSET (see qdma_base_test): a non-zero offset moves the MM C2H
  // source off the H2C destination bytes, so an H2C pass no longer fills it.
  bit [31:0] c2h_src_offset = 32'h0;

  // Data integrity scoreboard
  // Handle to the owning test  - gives live access to host_mem after MWR writes.
  // Set by qdma_base_test in connect_phase.
  qdma_base_test test_ref;

  // Per-qid expected data snapshot registered before each C2H transfer.
  // Outer key: qid; inner key: byte offset (0..DMA_BYTE_CNT-1); value: expected byte
  byte c2h_expected[bit [10:0]][int];

  // Per-qid destination base address (host_mem key for byte 0 of the transfer)
  longint unsigned c2h_dst_base[bit [10:0]];
  // Whether the registered expectation for this qid is trustworthy. The loopback
  // path below snapshots a reference buffer; if that buffer was never populated
  // (a C2H-only run has no prior H2C pass to fill it) the snapshot is all-zero
  // and comparing against it manufactures one mismatch per byte. Track it so the
  // checker can say 'not checked, and why' instead of reporting 4096 failures.
  bit              c2h_exp_valid[bit [10:0]];

  // Error count accumulated across all C2H data integrity checks this simulation
  int unsigned c2h_err_cnt = 0;
  bit c2h_not_checked_q[bit [10:0]];  // C2H queues whose payload was not compared

  // Per-QID received H2C user-side data (from AXI4-Stream monitor)
  byte h2c_user_data[bit [10:0]][$];  // qid → queue of received bytes
  int unsigned h2c_user_pkt_cnt = 0;  // total H2C packets received from user monitor
  int unsigned h2c_integrity_err_cnt = 0; // total H2C data integrity mismatches

  // per-queue cap on logged mismatch DETAIL lines (the aggregate count is
  // always printed). Override with +MAX_MISMATCH_LOG=<n>.
  int unsigned max_mismatch_log = 64;

  // DMA mode flag: set to 1 by ST tests to enable user-side data checks.
  // When dma_st=1, H2C PASS requires data on the AXI4-Stream interface.
  // When dma_st=0 (MM mode), user-side checks are informational only.
  bit dma_st = 0;

  // Pass condition 3: WB packets received
  // wb_done_cnt, wb_req_cnt and wb_pipeline_done_cnt are not fed in this
  // testbench; they stay 0.
  int wb_done_cnt = 0;
  int wb_req_cnt  = 0;
  int wb_pipeline_done_cnt = 0;
  // End-of-test writeback drain: started once (wb_drain_spawned) in its own thread so the
  // request-mailbox loop keeps processing trailing writeback TLPs while it waits, and bounded
  // by WB_DRAIN_TIMEOUT so a request with no matching done cannot hang the run.
  time WB_DRAIN_TIMEOUT = 20us;
  bit  wb_drain_spawned = 0;

  // Watchdog heartbeat: time of the last DUT TLP.
  time last_tlp_time = 0;

  // -- DMA activity timestamps. Both stall watchdogs treat ANY of these as
  // DMA-related work in progress: a stall means nothing related to a DMA
  // transfer happened for a full STALL_LIMIT window, not merely that no queue
  // completed. See last_dma_activity_time(). dump_progress_snapshot() also
  // prints them, so a fired watchdog shows which sources went quiet.
  //   last_fsm_activity_time : not fed in this testbench; stays 0.
  //   last_axi_activity_time : NOT wired -- cpm_axi_perf_monitor.sv's only
  //                            analysis port (metrics_ap) broadcasts a single
  //                            aggregate perf_metrics_t struct at report_phase
  //                            (end of sim only, not per-transaction), and
  //                            axi_pl_protocol_monitor.sv exposes no analysis
  //                            port at all. Declared for structural symmetry;
  //                            dump_progress_snapshot() prints it as UNWIRED
  //                            rather than a numeric 0 that could be misread
  //                            as "confirmed no AXI activity."
  time last_axi_activity_time = 0;
  time last_fsm_activity_time = 0;
  //   last_mmio_time         : fed by qdma_base_test::issue_reg_write and
  //                            issue_reg_read (on completion). Host register
  //                            accesses -- doorbells, indirect context commands,
  //                            mailbox and interrupt registers -- are the
  //                            driver's side of a DMA flow. Between the queues of
  //                            a driver-sequence test only these and the MSI-X
  //                            writes of the mailbox run, for hundreds of us.
  time last_mmio_time = 0;
  //   last_flr_activity_time : not fed in this testbench; stays 0.
  time last_flr_activity_time = 0;

  // Stall-detection threshold shared by dump_progress_snapshot()'s activity
  // comparison and the watchdogs below. Set once at the top of run_phase from
  // +DMA_STALL_TIMEOUT (default 50us).
  time STALL_LIMIT;

  // Descriptor-status writeback progress counter, read by DMA_COMPLETION_WATCHDOG.
  // Incremented on every DSC_WB_MWR (both directions). A writeback in flight IS
  // pending data-transfer work: the QDMA writeback path serialises every queue's
  // descriptor status through ONE dedicated HDMA channel, so a doorbell +
  // poll-for-done round trip per 8-byte MWR means a full drain can exceed
  // STALL_LIMIT while the DUT is healthy and making steady forward progress.
  int unsigned wb_mwr_count = 0;

  // WB destination-address scoreboard (pass condition 3b).
  // Tracks the first PCIe MWr address seen for each QID's WB write into its
  // descriptor ring.  Expected address: dsc_base + (RING_SIZE-1)*dsc_sz, where
  // dsc_sz is the QUEUE'S OWN descriptor size (16B ST / 32B MM) -- see
  // resolve_h2c_qid_and_sz / resolve_c2h_qid_and_sz -- the last slot of the
  // ring, where the QDMA WBI status descriptor is placed.
  // A C2H WB landing at the H2C base is a DUT defect this check catches.
  longint unsigned h2c_wb_mwr_addr[bit [10:0]]; // first H2C WB MWr addr per QID
  longint unsigned c2h_wb_mwr_addr[bit [10:0]]; // first C2H WB MWr addr per QID
  int              h2c_wb_addr_err_cnt = 0;      // H2C WB at wrong slot
  int              c2h_wb_addr_err_cnt = 0;      // C2H WB at wrong slot
  // PER-QID slot-address correctness, so completion condition 2 can require the
  // writeback landed at the right place and not merely that it carried the right
  // value. The counters above are whole-run totals.
  int              h2c_wb_addr_err_q[bit [10:0]];   // wrong-slot WBs, per qid (sticky)
  int              c2h_wb_addr_err_q[bit [10:0]];
  bit              h2c_wb_addr_ok_q [bit [10:0]];   // at least one correctly-addressed WB
  bit              c2h_wb_addr_ok_q [bit [10:0]];
  // ORDERING: the writeback that certifies a queue must arrive AFTER its byte
  // count passed. A writeback seen earlier describes a previous state of the
  // ring and cannot certify this transfer. Snapshot the per-qid WB event count
  // at byte-completion, then require the count to have advanced past it.
  int              h2c_wb_evt_cnt   [bit [10:0]];   // WB TLPs seen for this qid
  int              c2h_wb_evt_cnt   [bit [10:0]];
  int              h2c_wb_at_bytes  [bit [10:0]];   // snapshot taken at byte-done
  int              c2h_wb_at_bytes  [bit [10:0]];
  // ST mode: all expected bytes for this qid have left the user-side
  // AXI-Stream H2C interface. An extra completion condition in ST, on top of
  // the host-side bytes / writeback / MSI-X conditions shared with MM.
  bit              h2c_pl_done      [bit [10:0]];
  // Host-visible CIDX monotonicity. A cidx writeback asserts "everything below
  // this is consumed", so a backward step hands the driver descriptors that are
  // still live. Counted per direction; reported in the end-of-sim summary.
  int              h2c_wb_cidx_regress_cnt = 0;
  int              c2h_wb_cidx_regress_cnt = 0;

  // Driver-accurate scatter-gather mode (+XFER_BYTES). When non-zero, the
  // expected per-queue byte count is the transfer size ITSELF, not
  // pidx * DMA_BYTE_CNT: the driver's descriptors are page-sized with a SHORT
  // final one, so pidx * page over-counts by the remainder (e.g. 40000 B ->
  // 10 descriptors, but 10 * 4096 = 40960, not 40000).
  int              xfer_bytes = 0;

  // Runtime descriptor-ring size (+RING_ENTRIES), for rollover testing.
  // IMPORTANT: this is the ring's DEPTH, not its address spacing. Per-queue
  // ring base addresses stay on a RING_SIZE stride so the address->qid
  // derivation below is unaffected; only the offset of the writeback status
  // descriptor WITHIN a ring moves. Defaults to RING_SIZE.
  int              ring_entries = RING_SIZE;

  // WB status PIDX/CIDX scoreboard (pass condition 7 — PG302 Table 10).
  // Captures pidx[47:32] and cidx[31:16] from MWr TLP payload (DWord 1 and DWord 0)
  // at the time the WB write arrives; compared against expected in report_phase.
  bit [15:0] h2c_wb_status_pidx[bit [10:0]];  // pidx captured from H2C WB TLP
  bit [15:0] h2c_wb_status_cidx[bit [10:0]];  // cidx captured from H2C WB TLP
  bit [15:0] c2h_wb_status_pidx[bit [10:0]];  // pidx captured from C2H WB TLP
  bit [15:0] c2h_wb_status_cidx[bit [10:0]];  // cidx captured from C2H WB TLP

  // Pass condition 4: MSI-X MWr received when irq_en is set
  int h2c_msix_cnt = 0;  // count of MSI-X MWr TLPs with vec=1 (H2C), ALL functions
  int c2h_msix_cnt = 0;  // count of MSI-X MWr TLPs with vec=2 (C2H), ALL functions

  // PER-FUNCTION MSI-X counts. The direction totals above cannot attribute an
  // interrupt to a function. The owning function is recoverable: the MSI-X host
  // window is per-function (msix_off / MSIX_FNC_STRIDE, decoded at the TLP site),
  // and the qid->function map is registered from the FMAP programming.
  int h2c_msix_fnc_cnt[int];   // [fnc] -> vec=1 MWr count for that function
  int c2h_msix_fnc_cnt[int];   // [fnc] -> vec=2 MWr count for that function

  // Interrupts already spent retiring a queue of that function. A completing
  // queue must CONSUME one, so N queues on one function need N delivered
  // interrupts -- counting one interrupt once.
  //
  // Counting, not identity, because an MSI-X message carries a VECTOR and not a
  // QID: with vec 1/2 being per-DIRECTION, the owning queue is unknowable from
  // the message and no amount of decoding recovers it. A per-function total
  // alone is still too weak -- with several queues on one function a single
  // interrupt advances the count past every queue's snapshot and retires all of
  // them. Consuming a credit is what makes "one interrupt, one queue" hold for
  // any queues-per-function.
  int h2c_msix_used[int];      // [fnc] -> vec=1 interrupts already consumed
  int c2h_msix_used[int];      // [fnc] -> vec=2 interrupts already consumed

  // qid -> owning function, registered per function from TSK_FNC_MAP_PGM as
  // {q_base, q_count} ranges rather than per-qid, so it stays correct for any
  // queue count without the test enumerating queues twice.
  fnc_qrange_s fnc_qrange[int];
  // Per-vector MSI-X MWr counts for the whole 7-entry table programmed by
  // TSK_PROGRAM_MSIX_VEC_TABLE. h2c/c2h above are vec 1/2; this array also
  // covers vectors that are not queue completions -- e.g. the mailbox vector.
  int msix_vec_cnt[0:7] = '{default:0};
  // MSI-X MWr counts per (function, vector), for consumers that wait on one
  // function's vector (driver-style interrupt service) and for the per-vector
  // histogram in the summary. Read through msix_fnc_vec().
  int unsigned msix_fnc_vec_cnt[int][int];
  function automatic int unsigned msix_fnc_vec(int f, int v);
    if (!msix_fnc_vec_cnt.exists(f) || !msix_fnc_vec_cnt[f].exists(v)) return 0;
    return msix_fnc_vec_cnt[f][v];
  endfunction
  // Driver-sequence mode. Set by the driver-sequence engine; all default to the
  // behaviour of the other flows.
  //   drv_mode            : a host write outside every registered region is an error
  //                         (the engine registers every ring and buffer it posts)
  //   drv_c2h_irq_off     : C2H queues run with the SW-context interrupt off (as the
  //                         driver programs them), so check 4b expects 0 C2H grants
  //   drv_h2c_dsc_per_req : descriptors per H2C request (page split); scales the
  //                         final H2C status pidx expected in condition 7
  bit          drv_mode            = 1'b0;
  bit          drv_c2h_irq_off     = 1'b0;
  int unsigned drv_h2c_dsc_per_req = 1;
  // Driver-sequence runs with per-request H2C sizes (+DRV_H2C_SIZES): sizes
  // used in turn, each request read from the start of the source buffer;
  // total descriptors over the run (0 = sizes not in use).
  int          drv_h2c_sizes [$];
  int unsigned drv_h2c_total_dsc = 0;
  // MSI-X host-region geometry, must track TSK_PROGRAM_MSIX_VEC_TABLE.
  localparam int MSIX_VEC_PER_FNC_SB = 8;                       // vectors per function
  localparam int MSIX_FNC_STRIDE     = MSIX_VEC_PER_FNC_SB * 4; // bytes per function
  localparam int MSIX_MAX_FNCS       = 12;                      // MAX_PF(4) + 8 VFs
  bit irq_en       = 0;  // mirrored from +IRQ_EN plusarg; gates MSI-X pass check

  // PIDX refill state. Not set in this testbench; total_dsc_cnt = 0 means no refill.
  int total_dsc_cnt;                     // total descriptors per queue (0 = no refill)
  int refill_threshold;                  // remaining < this triggers refill
  int unsigned cidx_latest[bit [10:0]];  // per-QID latest CIDX from WB
  int unsigned h2c_cidx_latest[bit [10:0]]; // per-QID latest H2C CIDX from WB
  int unsigned c2h_cidx_latest[bit [10:0]]; // per-QID latest C2H CIDX from WB
  bit          c2h_host_done[bit [10:0]];   // C2H bytes complete, awaiting writeback
  // MSI-X-at-byte-completion snapshot, per QID and direction. Completion
  // requires an MSI-X MWr to arrive AFTER the bytes finished, so the count at
  // that moment is recorded and the gate waits for it to advance.
  //
  // LIMITATION: h2c_msix_cnt/c2h_msix_cnt are
  // PER-DIRECTION totals (vec=1 H2C, vec=2 C2H), not per-QID -- the vector does
  // not encode a queue. With several queues live in one direction, another
  // queue's interrupt can satisfy this gate. It is exact for a single queue per
  // direction and approximate beyond that. Per-QID attribution needs a vector
  // per queue, which the MSI-X table programming does not currently do.
  int          h2c_msix_at_bytes[bit [10:0]];
  int          c2h_msix_at_bytes[bit [10:0]];
  int unsigned pidx_current[bit [10:0]]; // per-QID current PIDX written to doorbell
  int unsigned total_submitted[bit [10:0]]; // per-QID total descriptors submitted so far
  bit refill_needed[bit [10:0]];         // per-QID flag: refill needed

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

  // Structured log file descriptor  - shared with the other monitors via uvm_config_db.
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

    // Retrieve the shared log file descriptor opened by qdma_base_test.build_phase.
    // The fd is already valid because UVM calls parent build_phase before child build_phase.
    if (!uvm_config_db#(int)::get(this, "", "log_fd", log_fd))
      `uvm_warning("DMA_SCOREBOARD", "log_fd not found in config_db  - file logging disabled")

    // The test resolves the effective C2H source offset (explicit plusarg, or
    // the DIRECTION=BOTH default) and publishes it here; the plusarg is only
    // a fallback for environments that do not set it.
    if (!uvm_config_db#(bit [31:0])::get(this, "", "c2h_src_offset", c2h_src_offset))
      if (!$value$plusargs("C2H_SRC_OFFSET=%h", c2h_src_offset))
        c2h_src_offset = 32'h0;

    // Mirror the IRQ_EN plusarg so report_phase can gate the MSI-X check.
    // TEST MODE, driven 1:1 from this same plusarg:
    //   POLL      (IRQ_EN=0): qid_irq_en() returns 0 for every qid -- both
    //              try_complete_h2c/c2h skip the MSI-X gate and qid_cmp_cnt
    //              advances on bytes+writeback alone.
    //   INTERRUPT (IRQ_EN=1, default): qid_irq_en() returns 1 -- MSI-X must be
    //              observed (per owning function) before qid_cmp_cnt advances.
    begin
      int parg_irq;
      irq_en = ($value$plusargs("IRQ_EN=%0d", parg_irq)) ? bit'(parg_irq) : 1'b1;
      `uvm_info("DMA_SCOREBOARD", $sformatf(
        "TEST MODE: %s (IRQ_EN=%0d)", irq_en ? "INTERRUPT" : "POLL", irq_en), UVM_NONE)
    end

    // ---- Per-QID heterogeneity plusargs ----
    // +QID_BYTE_PATTERN=ramp|alternate   different transfer size per queue
    // +POLL_QID_MASK=<hex>               bit q set => qid q polls (expects no MSI-X)
    begin
      string parg_pat;
      int unsigned max_mult;
      longint unsigned parg_mask;
      max_mult = 1;
      if ($value$plusargs("QID_BYTE_PATTERN=%s", parg_pat)) begin
        case (parg_pat)
          "ramp"      : begin qid_byte_pattern = QBP_RAMP; max_mult = 8; end
          "alternate" : begin qid_byte_pattern = QBP_ALT;  max_mult = 2; end
          "none"      : begin qid_byte_pattern = QBP_NONE; max_mult = 1; end
          default     : `uvm_fatal("DMA_SCOREBOARD",
                          $sformatf("Unknown +QID_BYTE_PATTERN=%s (ramp|alternate|none)", parg_pat))
        endcase
      end
      // The stride must cover the LARGEST queue, or a big queue's data would run
      // into the next queue's address window and be decoded as the wrong qid.
      //
      // +QID_STRIDE_MULT lets a test widen the stride when its PER-QID TRANSFER
      // exceeds DMA_BYTE_CNT. That happens in driver-SG mode (+XFER_BYTES),
      // where DMA_BYTE_CNT is the per-slot PL-BRAM footprint -- constrained to
      // [64 : 0x10000] and %64==0 -- and is deliberately SMALLER than the total
      // transfer.
      //
      // Why a plusarg rather than deriving it from xfer_bytes here: xfer_bytes
      // is assigned by the test AFTER build_phase, and the qid is encoded into
      // the address before that. A plusarg is available here and yields ONE
      // stride for both encode and decode.
      begin
        int unsigned parg_mult;
        if ($value$plusargs("QID_STRIDE_MULT=%0d", parg_mult)) begin
          if (parg_mult < 1 || (parg_mult & (parg_mult-1)) != 0)
            `uvm_fatal("DMA_SCOREBOARD", $sformatf(
              "+QID_STRIDE_MULT=%0d must be a power of two >= 1 (it multiplies a $clog2 stride)",
              parg_mult))
          if (parg_mult > max_mult) max_mult = parg_mult;
        end
      end
      qid_max_mult = max_mult;   // shift itself is computed lazily -- see qid_addr_shift()
      if ($value$plusargs("POLL_QID_MASK=%h", parg_mask))
        poll_qid_mask = parg_mask[63:0];
      void'($value$plusargs("POLL_EVERY_N=%0d", poll_every_n));
      if (qid_byte_pattern != QBP_NONE || poll_qid_mask != 0 || poll_every_n > 1)
        `uvm_info("DMA_SCOREBOARD",
          $sformatf("PER-QID MODE: byte_pattern=%s addr_shift=%0d poll_qid_mask=0x%016h poll_every_n=%0d",
                    qid_byte_pattern.name(), qid_addr_shift(), poll_qid_mask, poll_every_n), UVM_NONE)
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
      $fdisplay(log_fd, "#   NOTE           - DMA_BYTE_CNT pass/fail in this scoreboard is host-side only; AXI-PL observations are reported separately by cpm_axi_scoreboard");
      $fdisplay(log_fd, "#   MSIX_MWR       - MSI-X interrupt MWr to programmed vec table entry (expected)");
      $fdisplay(log_fd, "#   DSC_WB_MWR     - QDMA CIDX writeback into H2C/C2H descriptor ring  (expected).");
      $fdisplay(log_fd, "#                    Logs the decoded TLP payload cidx/pidx (PG302 Table 10: DW0[31:16]=cidx,");
      $fdisplay(log_fd, "#                    DW1[15:0]=pidx) -- this is the HOST-VISIBLE cidx, the value a real driver");
      $fdisplay(log_fd, "#                    acts on. Flags *** CIDX_REGRESSION *** and raises UVM_ERROR if cidx moves");
      $fdisplay(log_fd, "#                    backward for a qid (wrap-guarded), since that tells the driver that still-live");
      $fdisplay(log_fd, "#                    descriptors are consumable.");
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
      // access print as a benign low host address and hide a misrouted access.
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

    // -- Lower-level activity cross-check --------------------------------------
    // Answers "was there recent AXI/register activity within the stall
    // window, or genuinely none" -- compared against the SAME STALL_LIMIT
    // driving both watchdogs. The register timestamp is part of the
    // watchdogs' activity test (last_dma_activity_time); AXI is not wired.
    if (last_axi_activity_time == 0) begin
      $fdisplay(log_fd,
        "#   last_axi_activity_time=UNWIRED  -- no real-time AXI analysis port available (cpm_axi_perf_monitor.metrics_ap only fires once at report_phase; axi_pl_protocol_monitor has no analysis port). Do NOT read this as \"no AXI activity\".");
    end else begin
      $fdisplay(log_fd,
        "#   last_axi_activity_time=%0t  (%0t ago vs STALL_LIMIT=%0t)  %s",
        last_axi_activity_time, $time - last_axi_activity_time, STALL_LIMIT,
        (($time - last_axi_activity_time) >= STALL_LIMIT) ? "STALE (>= STALL_LIMIT, no recent AXI activity)"
                                                            : "recent AXI activity within stall window");
    end
    $fdisplay(log_fd,
      "#   last_mmio_time=%0t  (%0t ago vs STALL_LIMIT=%0t)  %s",
      last_mmio_time, $time - last_mmio_time, STALL_LIMIT,
      (last_mmio_time == 0) ? "no host register access seen" :
      (($time - last_mmio_time) >= STALL_LIMIT) ? "STALE (>= STALL_LIMIT, no recent host register access)"
                                                  : "recent host register access within stall window");
    // Writeback progress. If this is non-zero and still climbing, the DUT is
    // draining, not hung -- the queue simply has not finished. All writebacks
    // serialise through one HDMA channel, so the drain is slow by construction.
    $fdisplay(log_fd,
      "#   wb_mwr_count=%0d  (descriptor-status writebacks seen; watchdog treats a rising count as pending transfer work and HOLDS OFF the fatal)",
      wb_mwr_count);

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

  // --- resolve_h2c_qid_and_sz / resolve_c2h_qid_and_sz -------------------------
  // A host-memory address inside the descriptor-ring region is attributed to a
  // qid by dividing its ring-relative offset by RING_SIZE*<stride>. The stride
  // is the QUEUE'S OWN per-descriptor byte size, not a fixed constant: MM rings
  // use a 32B (QDMA_DSC_SZ) stride, but ST tasks
  // (TSK_QDMA_(VF_)ST_H2C_TEST / TSK_QDMA_(VF_)ST_C2H_TEST) use ST_DSC_SZ=16.
  // Dividing by the wrong stride doesn't error out -- it silently produces a
  // different, wrong qid index (an ST ring divided by the MM stride resolves
  // to roughly half its real qid).
  //
  // Resolve by trying each known descriptor size and accepting the first
  // candidate whose OWN recorded per-qid size (h2c_qid_dsc_sz/c2h_qid_dsc_sz,
  // populated by the TSK_INIT_QDMA_*_DATA_* tasks at ring-init time) agrees
  // with the stride just used to derive it -- i.e. a self-consistency check,
  // not a guess. QDMA_DSC_SZ is tried first. If no candidate is
  // self-consistent (qid never registered in the dict), fall back to the
  // fixed-QDMA_DSC_SZ division.
  function automatic void resolve_h2c_qid_and_sz(input longint unsigned addr,
                                                  output int unsigned qid,
                                                  output int unsigned dsc_sz);
    int unsigned strides[4] = '{QDMA_DSC_SZ, 16, 32, 8};
    int unsigned cand;
    bit          resolved;
    resolved = 1'b0;
    foreach (strides[i]) begin
      if (strides[i] == 0) continue;
      cand = int'((addr - H2C_DSC_ADDR) / (longint'(RING_SIZE) * strides[i]));
      if (test_ref != null && test_ref.h2c_qid_dsc_sz.exists(cand) &&
          test_ref.h2c_qid_dsc_sz[cand] == strides[i]) begin
        qid = cand; dsc_sz = strides[i]; resolved = 1'b1;
        break;
      end
    end
    if (!resolved) begin
      qid    = int'((addr - H2C_DSC_ADDR) / (longint'(RING_SIZE) * QDMA_DSC_SZ));
      dsc_sz = QDMA_DSC_SZ;
    end
  endfunction

  // Ring base of a C2H queue: the base the test programmed when it recorded
  // one, otherwise the packed layout (base pitch = descriptor size).
  function automatic longint unsigned c2h_ring_base(input int unsigned qid,
                                                    input longint unsigned dsc_sz);
    if (test_ref != null && test_ref.c2h_qid_dsc_base.exists(int'(qid)))
      return test_ref.c2h_qid_dsc_base[int'(qid)];
    return C2H_DSC_ADDR + longint'(qid) * longint'(RING_SIZE) * dsc_sz;
  endfunction

  function automatic void resolve_c2h_qid_and_sz(input longint unsigned addr,
                                                  output int unsigned qid,
                                                  output int unsigned dsc_sz);
    int unsigned strides[4] = '{QDMA_DSC_SZ, 16, 32, 8};
    int unsigned cand;
    bit          resolved;
    longint unsigned rb, rsz;
    resolved = 1'b0;
    // A recorded ring that contains the address identifies the queue directly.
    if (test_ref != null) begin
      foreach (test_ref.c2h_qid_dsc_base[q]) begin
        rb  = test_ref.c2h_qid_dsc_base[q];
        rsz = test_ref.c2h_qid_dsc_sz.exists(q) ? longint'(test_ref.c2h_qid_dsc_sz[q])
                                                : longint'(QDMA_DSC_SZ);
        if (!resolved && addr >= rb && addr < rb + longint'(RING_SIZE) * rsz) begin
          qid = int'(q); dsc_sz = int'(rsz); resolved = 1'b1;
        end
      end
    end
    if (!resolved) foreach (strides[i]) begin
      if (strides[i] == 0) continue;
      cand = int'((addr - C2H_DSC_ADDR) / (longint'(RING_SIZE) * strides[i]));
      if (test_ref != null && test_ref.c2h_qid_dsc_sz.exists(cand) &&
          test_ref.c2h_qid_dsc_sz[cand] == strides[i]) begin
        qid = cand; dsc_sz = strides[i]; resolved = 1'b1;
        break;
      end
    end
    if (!resolved) begin
      qid    = int'((addr - C2H_DSC_ADDR) / (longint'(RING_SIZE) * QDMA_DSC_SZ));
      dsc_sz = QDMA_DSC_SZ;
    end
  endfunction

  // --- dump_hw_ctxt_cidx_snapshot ----------------------------------------------
  // Reads HW context (IND_CTXT_CMD) for every qid under test and logs cidx vs.
  // the test's expected pidx. This is a task (not the zero-time
  // dump_progress_snapshot function) so it can be called from the watchdog
  // itself, immediately before the uvm_fatal that ends the sim on a stall.
  task dump_hw_ctxt_cidx_snapshot(string reason);
    bit [10:0]  qid;
    bit         ok;
    int         polls;
    bit [255:0] ctxt_data;
    bit [15:0]  hw_cidx;
    bit [15:0]  exp_pidx;
    if (log_fd == 0 || test_ref == null)
      return;
    exp_pidx = test_ref.pidx;
    $fdisplay(log_fd, "# HW_CTXT_CIDX_SNAPSHOT reason=%s time=%0t exp_pidx=0x%04h", reason, $time, exp_pidx);
    if (h2c_trfr_done.first(qid)) begin
      do begin
        test_ref.issue_ind_ctxt_op_nf(qid, test_ref.DRV_BIND_SEL_HW_H2C, test_ref.DRV_BIND_OP_RD, ok, polls);
        if (!ok) begin
          $fdisplay(log_fd, "#   HW_CTXT_CIDX_SNAPSHOT qid=%0d dir=H2C: IND_CTXT_CMD BUSY stuck (%0d polls)", qid, polls);
        end else begin
          test_ref.read_ind_ctxt_data(ctxt_data);
          hw_cidx = ctxt_data[15:0];
          $fdisplay(log_fd, "#   HW_CTXT_CIDX_SNAPSHOT qid=%0d dir=H2C hw_cidx=0x%04h exp_pidx=0x%04h %s",
                    qid, hw_cidx, exp_pidx, (hw_cidx == exp_pidx) ? "MATCH" : "MISMATCH");
        end
      end while (h2c_trfr_done.next(qid));
    end
    if (c2h_trfr_done.first(qid)) begin
      do begin
        test_ref.issue_ind_ctxt_op_nf(qid, test_ref.DRV_BIND_SEL_HW_C2H, test_ref.DRV_BIND_OP_RD, ok, polls);
        if (!ok) begin
          $fdisplay(log_fd, "#   HW_CTXT_CIDX_SNAPSHOT qid=%0d dir=C2H: IND_CTXT_CMD BUSY stuck (%0d polls)", qid, polls);
        end else begin
          test_ref.read_ind_ctxt_data(ctxt_data);
          hw_cidx = ctxt_data[15:0];
          $fdisplay(log_fd, "#   HW_CTXT_CIDX_SNAPSHOT qid=%0d dir=C2H hw_cidx=0x%04h exp_pidx=0x%04h %s",
                    qid, hw_cidx, 16'(exp_pidx * c2h_dsc_per_pkt),
                    (hw_cidx == 16'(exp_pidx * c2h_dsc_per_pkt)) ? "MATCH" : "MISMATCH");
        end
      end while (c2h_trfr_done.next(qid));
    end
    $fflush(log_fd);
  endtask

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
    int unsigned snap_hits = 0;
    c2h_expected[qid].delete();
    c2h_dst_base[qid] = dst_addr;
    snap_addr = (ref_addr != 0) ? ref_addr : dst_addr;
    for (int k = 0; k < byte_cnt; k++) begin
      int addr_key = int'(snap_addr + k);
      if (test_ref != null && test_ref.host_mem.exists(addr_key)) begin
        c2h_expected[qid][k] = test_ref.host_mem[addr_key];
        snap_hits++;
      end
      else begin
        c2h_expected[qid][k] = 8'h00;
      end
    end
    c2h_exp_valid[qid] = (snap_hits != 0);
    if (snap_hits == 0)
      `uvm_warning("DMA_SCOREBOARD",
        $sformatf("C2H qid=%0d: loopback reference buffer at 0x%0h is empty in host_mem - no H2C pass populated it, so no valid expectation exists for this queue. Data integrity will be REPORTED AS NOT CHECKED rather than compared against zeros.", qid, snap_addr))
  endfunction

  // --- register_c2h_expected_pattern -------------------------------------------
  // Register expected C2H data using the deterministic pattern generated by
  // c2h_source_ctrl + c2h_source RTL (not from host_mem, which is zeroed for
  // C2H targets).
  //
  // c2h_source pattern:
  //   seed = {448'd0, qid[10:0], 5'd0, burst_seq[15:0], global_beat_idx[31:0]}
  //   where global_beat_idx = desc_start * beats_per_desc (restarts at 0 on each START)
  //   and burst_seq is the port's accepted-START count (set by set_c2h_expected_burst)
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
    c2h_exp_valid[qid] = 1'b1;
    // This expectation models the c2h_source RTL generator, which produces its own
    // data — there is no BRAM to fill, so the source-primed guard in
    // check_c2h_integrity must not gate it on an H2C pass.
    c2h_src_primed[qid] = 1'b1;
    for (int d = 0; d < num_desc; d++) begin
      for (int b = 0; b < beats_per_desc; b++) begin
        bit [511:0] w;
        int unsigned global_beat = (desc_start + d) * beats_per_desc;
        // Replicate c2h_source_ctrl seed + c2h_source increment pattern
        // seed = {448'd0, qid[10:0], 5'd0, burst_seq[15:0], global_beat[31:0]}
        // data = seed + b (512-bit add; for small b, only lower 32 bits change).
        // burst_seq (w[47:32]) is filled in at START by set_c2h_expected_burst.
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

  // Sets the burst-sequence field (seed bits [47:32], bytes 4-5 of every 64-byte
  // beat) of the registered C2H pattern for qid. The generator assigns the
  // sequence when the START is accepted, after the pattern was registered; the
  // last call before the check wins, matching the burst whose data is checked.
  function void set_c2h_expected_burst(bit [10:0] qid, bit [15:0] burst_seq);
    if (!c2h_expected.exists(qid) || !c2h_src_primed.exists(qid) || !c2h_src_primed[qid])
      return;
    for (int beat = 0; beat * 64 < c2h_expected[qid].size(); beat++) begin
      if (beat * 64 + 5 < c2h_expected[qid].size()) begin
        c2h_expected[qid][beat * 64 + 4] = burst_seq[7:0];
        c2h_expected[qid][beat * 64 + 5] = burst_seq[15:8];
      end
    end
    `uvm_info("DMA_SCOREBOARD",
      $sformatf("C2H expected pattern qid=%0d: burst sequence %0d", qid, burst_seq), UVM_MEDIUM)
  endfunction

  // --- check_c2h_integrity ----------------------------------------------------
  // Check C2H data integrity for one completed queue.
  // Uses the destination base address stored by register_c2h_expected.
  // Reports pass/fail via uvm_info/uvm_error and to the log file.
  function void check_c2h_integrity(bit [10:0] qid);
    int unsigned mismatches = 0;
    int unsigned byte_cnt;
    longint unsigned dst_addr;

    if (!c2h_expected.exists(qid)) begin
      `uvm_warning("DMA_SCOREBOARD",
        $sformatf("C2H qid=%0d: no expected data registered - skipping check", qid))
      c2h_not_checked_q[qid] = 1'b1;
      return;
    end

    if (c2h_exp_valid.exists(qid) && !c2h_exp_valid[qid]) begin
      `uvm_warning("DMA_SCOREBOARD",
        $sformatf("C2H qid=%0d: NOT CHECKED - no valid expected payload was registered (see the empty-reference warning at setup). This is a coverage gap, NOT a pass.", qid))
      c2h_not_checked_q[qid] = 1'b1;
      log_event("C2H_NOT_CHECKED", int'(qid), 0, 0, 0, 0, 0,
                "expectation unavailable: loopback reference buffer empty");
      return;
    end
    // --- C2H SOURCE-PRIMED GUARD ------------------------------------------------
    // In MM the C2H source is PL1 BRAM: pkg.cpm6_qdma_params.sv sets
    // C2H_DAT_SRC_ADDR1 == H2C_DAT_DST_ADDR1, and nothing fills that BRAM except an
    // H2C pass to the same slot.
    //
    // So on a C2H-only run the BRAM holds zeros, the DUT correctly moves zeros to the
    // correct addresses, and comparing against the loopback reference flags every
    // non-zero expected byte.
    //
    // Only compare payload when the source was really filled: either an H2C transfer
    // for this QID completed (loopback / DIRECTION=BOTH), or a test declared the
    // source primed by another route. An H2C pass
    // counts only while the C2H source is the H2C destination (C2H_SRC_OFFSET == 0).
    if (c2h_src_offset != 32'h0 &&
        !(c2h_src_primed.exists(qid) && c2h_src_primed[qid])) begin
      `uvm_info("DMA_SCOREBOARD",
        $sformatf({"C2H qid=%0d: NOT CHECKED - C2H_SRC_OFFSET=0x%0h moves the C2H source off ",
                   "the H2C destination bytes, so the payload is not loopback data. ",
                   "Byte count and completion are still checked."}, qid, c2h_src_offset), UVM_LOW)
      c2h_not_checked_q[qid] = 1'b1;
      log_event("C2H_NOT_CHECKED", int'(qid), c2h_dst_base[qid], 0, 0, 0, 0,
                "C2H_SRC_OFFSET set: C2H source is not the H2C destination");
      return;
    end
    if (!((h2c_trfr_done.exists(qid) && h2c_trfr_done[qid]) ||
          (c2h_src_primed.exists(qid) && c2h_src_primed[qid]))) begin
      `uvm_warning("DMA_SCOREBOARD",
        $sformatf({"C2H qid=%0d: NOT CHECKED - C2H source was never filled (no H2C pass ",
                   "for this QID and no explicit prime), so the DUT had only zeros to move. ",
                   "Payload comparison would report false mismatches. Run DIRECTION=BOTH ",
                   "to get real C2H payload coverage."}, qid))
      c2h_not_checked_q[qid] = 1'b1;
      log_event("C2H_NOT_CHECKED", int'(qid), c2h_dst_base[qid], 0, 0, 0, 0,
                "C2H source never filled: no h2c_trfr_done and not explicitly primed");
      return;
    end

    dst_addr = c2h_dst_base[qid];
    byte_cnt = c2h_expected[qid].size();
    for (int k = 0; k < byte_cnt; k++) begin
      byte got, exp;
      int  addr_key = int'(dst_addr + k);
      got = (test_ref != null && test_ref.host_mem.exists(addr_key)) ?
             test_ref.host_mem[addr_key] : 8'h00;
      exp = c2h_expected[qid][k];
      if (got !== exp) begin
        if (mismatches < max_mismatch_log) begin
          `uvm_error("DMA_SCOREBOARD",
            $sformatf("C2H data mismatch qid=%0d offset=%0d addr=0x%0h exp=0x%0h got=0x%0h",
                       qid, k, dst_addr + k, exp, got))
          log_event("C2H_MISMATCH", int'(qid), dst_addr + k, 1,
                    0, 0, 0,
                    $sformatf("offset=%0d exp=0x%02h got=0x%02h", k, exp, got));
        end else if (mismatches == max_mismatch_log) begin
          // Announce the truncation exactly once. Without this the detail block
          // just stops, and a reader cannot tell a short mismatch list from a
          // long one that was clipped.
          log_event("C2H_MISMATCH", int'(qid), dst_addr + k, 1, 0, 0, 0,
                    $sformatf("DETAIL LOG TRUNCATED at %0d entries - further mismatches counted but not listed (raise with +MAX_MISMATCH_LOG=<n>)",
                              max_mismatch_log));
        end
        mismatches++;
      end
    end
    c2h_err_cnt += mismatches;
    if (mismatches == 0) begin
      `uvm_info("DMA_SCOREBOARD",
        $sformatf("C2H data integrity PASS qid=%0d bytes_checked=%0d", qid, byte_cnt), UVM_NONE)
      log_event("C2H_INTEG_PASS", int'(qid), dst_addr, 0,
                longint'(byte_cnt), longint'(byte_cnt), 0,
                $sformatf("bytes_checked=%0d PASS", byte_cnt));
    end else begin
      `uvm_error("DMA_SCOREBOARD",
        $sformatf("C2H data integrity FAIL qid=%0d mismatches=%0d/%0d",
                   qid, mismatches, byte_cnt))
      log_event("C2H_INTEG_FAIL", int'(qid), dst_addr, 0,
                longint'(byte_cnt), longint'(byte_cnt), 0,
                $sformatf("mismatches=%0d/%0d FAIL", mismatches, byte_cnt));
    end
  endfunction

  // --- receive_h2c_user_pkt ---------------------------------------------------
  // Called by h2c_user_subscriber on each H2C packet from the AXI4-Stream monitor.
  // Extracts bytes from 512-bit beats and appends to per-QID received data.
  // Uses mty (empty byte count) on the last beat to exclude padding bytes.
  function void receive_h2c_user_pkt(qdma_user_transaction txn);
    bit [10:0] pkt_qid;
    int bytes_this_pkt;
    longint unsigned pl_exp_bytes;
    pkt_qid = txn.qid[10:0];
    h2c_user_pkt_cnt++;
    bytes_this_pkt = 0;
    for (int b = 0; b < txn.num_beats; b++) begin
      int bytes_in_beat;
      // Last beat: subtract mty (empty bytes) from 64-byte beat width.
      // Non-last beats always carry 64 valid bytes.
      if (b == txn.num_beats - 1 && txn.mty > 0)
        bytes_in_beat = 64 - int'(txn.mty);
      else
        bytes_in_beat = 64;
      for (int k = 0; k < bytes_in_beat; k++)
        h2c_user_data[pkt_qid].push_back(byte'(txn.data[b][(k*8) +: 8]));
      bytes_this_pkt += bytes_in_beat;
    end
    log_event("H2C_USER_PKT", int'(pkt_qid), 64'h0,
              longint'(bytes_this_pkt),
              longint'(h2c_user_data[pkt_qid].size()), 0, int'(h2c_user_pkt_cnt),
              $sformatf("beats=%0d mty=%0d", txn.num_beats, txn.mty));

    // ST mode: user-side AXI-Stream data is one of the completion conditions.
    // Reaching the expected byte count here marks the qid PL-side done; the
    // queue is counted by try_complete_h2c() only once the host-side bytes,
    // the status writeback and (interrupt mode) the MSI-X have also arrived.
    if (dma_st && !h2c_pl_done.exists(pkt_qid)) begin
      pl_exp_bytes = qid_exp_bytes(pkt_qid);
      if (longint'(h2c_user_data[pkt_qid].size()) >= pl_exp_bytes) begin
        h2c_pl_done[pkt_qid] = 1'b1;
        `uvm_info("DMA_SCOREBOARD",
          $sformatf("H2C PL-side bytes reached qid=%0d bytes=%0d (pkts=%0d) source=AXI-Stream user interface -- awaiting host-side bytes, writeback and interrupt before completion",
                     pkt_qid, h2c_user_data[pkt_qid].size(), h2c_user_pkt_cnt), UVM_NONE)
        log_event("H2C_PL_DONE", int'(pkt_qid), 64'h0,
                  0, longint'(h2c_user_data[pkt_qid].size()), pl_exp_bytes,
                  int'(h2c_user_pkt_cnt),
                  "source=PL_AXI_Stream user-side bytes complete");
        check_h2c_integrity(pkt_qid);
        try_complete_h2c(pkt_qid);
        // Trigger test completion if all queues done
        if (qid_cmp_cnt > 0 && qid_cmp_cnt == qid_in_test) begin
          dma_last_done_time = $time;
          `uvm_info("dma_req_processor",
            $sformatf("qid_cmp_cnt:%0d, qid_in_test : %0d", qid_cmp_cnt, qid_in_test), UVM_NONE)
          test_done = 1;
          done_ev.trigger();
        end
      end
    end
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
    src_addr[qid_addr_shift()+:11] = qid;
    chunk_size = int'(qid_byte_cnt(qid));

    begin : b_integ
    int req_r    = 0;   // per-request sizes: request holding byte k
    int req_base = 0;   //                    and its first byte
    for (int k = 0; k < total_bytes; k++) begin
      byte got, exp;
      int src_offset;
      int addr_key;
      // Each descriptor reads the same DMA_BYTE_CNT from src_addr,
      // so the expected pattern repeats every DMA_BYTE_CNT bytes. With
      // per-request sizes each request restarts at the buffer's first byte.
      if (drv_h2c_sizes.size() > 0) begin
        while (k >= req_base + drv_h2c_sizes[req_r % drv_h2c_sizes.size()]) begin
          req_base += drv_h2c_sizes[req_r % drv_h2c_sizes.size()];
          req_r++;
        end
        src_offset = k - req_base;
      end else
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
    end : b_integ
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

  // --- notify_mmio_activity ----------------------------------------------------
  // Called by qdma_base_test on every host register write and completed read.
  function void notify_mmio_activity();
    last_mmio_time = $time;
  endfunction

  // --- last_dma_activity_time --------------------------------------------------
  // Latest time anything related to a DMA transfer happened: a DUT TLP to host
  // memory (descriptor fetch, data, writeback, MSI-X) or a host register access.
  function time last_dma_activity_time();
    time t;
    t = last_tlp_time;
    if (last_fsm_activity_time  > t) t = last_fsm_activity_time;
    if (last_mmio_time          > t) t = last_mmio_time;
    if (last_flr_activity_time  > t) t = last_flr_activity_time;
    return t;
  endfunction

  // Declare H2C completion only when ALL THREE conditions hold:
  //   (1) BYTES     -- all expected bytes moved (host-side MRD accumulation)
  //   (2) WRITEBACK -- the IP wrote back CIDX == PIDX for this queue, both
  //                    values read from the SAME writeback TLP
  //   (3) MSI-X     -- an interrupt reached the host after (1), for queues
  //                    running in interrupt mode (qid_irq_en)
  //
  // Any one of these alone is a weaker statement than "the transfer completed".
  // Bytes alone says the data moved but not that the IP reported it -- the
  // driver polls CIDX, so a transfer whose CIDX never reaches PIDX wedges it
  // while byte count scores a PASS. Writeback alone does not prove the host was
  // notified. This is the full contract.
  //
  // Called from the byte-count site AND from the writeback decode, because either
  // can be the last to arrive -- the writeback normally trails the data, but a
  // short transfer can complete its writeback first. Idempotent: h2c_trfr_done
  // gates the increment so a queue is counted exactly once.
  //
  // There is no byte-count-only fallback: all three are hard gates. A queue that
  // never satisfies one stays uncounted and the DMA watchdog reports it, which
  // is the correct outcome -- a missing writeback or a missing interrupt IS a
  // failure, not a condition to be excused.
  //
  // ST mode applies the same three conditions, with (1) taken from the
  // host-side MRD accumulation as in MM, plus a fourth: (4) the user-side
  // AXI-Stream interface delivered all expected bytes (h2c_pl_done). The data
  // reaching the user is necessary but not sufficient -- the driver still needs
  // the writeback and, in interrupt mode, the MSI-X to retire the queue.
  // Called additionally from receive_h2c_user_pkt(), since the user-side data
  // can be the last of the four to arrive.
  function void try_complete_h2c(bit [10:0] q);
    bit have_pidx;
    bit wb_ok;
    if (h2c_trfr_done.exists(q)) return;          // already counted
    if (!h2c_host_done.exists(q)) return;         // bytes not done yet
    if (dma_st && !h2c_pl_done.exists(q)) return; // (4) ST: user-side data not complete
    // (2) WRITEBACK: cidx == pidx, both taken from the SAME writeback TLP
    //     (decoded in run_phase). Using the writeback's own pidx
    //     rather than an externally-tracked one means the comparison cannot be
    //     defeated by a stale or unpopulated copy.
    //     Three sub-conditions, ALL required. Value alone is not a completion.
    //       2a VALUE    - cidx == pidx from the same writeback TLP
    //       2b LOCATION - that TLP landed at this queue's status slot,
    //                     dsc_base + (RING_SIZE-1)*DSC_SZ. A correct payload
    //                     written to the WRONG slot never reaches the driver,
    //                     so it cannot certify the transfer.
    //       2c ORDERING - the writeback must arrive AFTER the byte count
    //                     passed. One seen earlier describes a previous state
    //                     of the ring. Same snapshot discipline as the MSI-X
    //                     ordering check below.
    have_pidx = h2c_wb_status_pidx.exists(q) && h2c_wb_status_cidx.exists(q);
    if (!have_pidx) return;                       // no writeback seen yet
    // 2c ORDERING
    if (!h2c_wb_at_bytes.exists(q)) return;       // bytes not marked done yet
    if (!h2c_wb_evt_cnt.exists(q)) return;
    if (h2c_wb_evt_cnt[q] <= h2c_wb_at_bytes[q]) return;  // no WB since bytes finished
    // 2b LOCATION
    if (!h2c_wb_addr_ok_q.exists(q) || !h2c_wb_addr_ok_q[q]) return;
    if (h2c_wb_addr_err_q.exists(q) && (h2c_wb_addr_err_q[q] > 0)) return;
    // 2a VALUE
    wb_ok = (h2c_wb_status_cidx[q] === h2c_wb_status_pidx[q]);
    if (!wb_ok) return;                           // cidx has not caught up to pidx

    // (3) MSI-X to host, only for queues that use interrupts.
    //     Counted for THIS QUEUE'S OWNING FUNCTION. A direction-wide total lets
    //     one function's interrupt retire another function's queue.
    if (qid_irq_en(q)) begin
      int f = qid_fnc(q);
      if (f < 0) begin
        `uvm_error("DMA_SCOREBOARD", $sformatf(
          "H2C qid=%0d has no registered owning function -- cannot attribute its MSI-X. Completion withheld rather than credited from the direction total.", q))
        return;
      end
      if (!h2c_msix_fnc_cnt.exists(f)) h2c_msix_fnc_cnt[f] = 0;
      if (!h2c_msix_used.exists(f))    h2c_msix_used[f]    = 0;
      // ORDERING: an interrupt must have arrived for this function AFTER this
      // queue's bytes finished (snapshot taken at byte completion).
      if (!h2c_msix_at_bytes.exists(q)) h2c_msix_at_bytes[q] = h2c_msix_fnc_cnt[f];
      if (h2c_msix_fnc_cnt[f] <= h2c_msix_at_bytes[q]) return;
      // COUNTING: and it must be one no other queue has already claimed.
      if (h2c_msix_fnc_cnt[f] - h2c_msix_used[f] <= 0) return;
      h2c_msix_used[f]++;   // consume it -- not reusable by a sibling queue
    end

    qid_cmp_cnt++;
    h2c_trfr_done[q] = 1'b1;
    // No byte-count-only fallback: all three conditions are hard gates above,
    // so reaching here means every one of them was satisfied.
    `uvm_info("DMA_SCOREBOARD", $sformatf(
      "H2C COMPLETE qid=%0d bytes=%0d cidx=0x%04h == pidx=0x%04h @slot msix=%s (bytes AND wb[value+slot+after-bytes] AND interrupt) qid_cmp_cnt=%0d/%0d",
      q, h2c_bytes[q], h2c_wb_status_cidx[q], h2c_wb_status_pidx[q],
      qid_irq_en(q) ? "seen" : "n/a-polling", qid_cmp_cnt, qid_in_test), UVM_NONE)
    log_event("H2C_DONE", int'(q), 0, 0, h2c_bytes[q], qid_exp_bytes(q), h2c_cnt[q],
              $sformatf("bytes+cidx qid_cmp_cnt=%0d/%0d PASS", qid_cmp_cnt, qid_in_test));
  endfunction

  // C2H counterpart of try_complete_h2c. Same THREE-condition rule: bytes,
  // writeback cidx == pidx, and MSI-X to host. Uses the C2H writeback's own
  // cidx/pidx, so a test cannot satisfy the C2H criterion with an H2C writeback.
  //
  // check_c2h_integrity() is invoked HERE rather than at the byte-count site so
  // the payload comparison still runs exactly once per queue, at the moment the
  // queue is actually declared complete.
  function void try_complete_c2h(bit [10:0] q);
    bit have_pidx;
    bit wb_ok;
    if (c2h_trfr_done.exists(q) && c2h_trfr_done[q]) return;  // already counted
    if (!c2h_host_done.exists(q)) return;                      // bytes not done yet
    // (2) WRITEBACK: cidx == pidx from the C2H writeback TLP.
    //     Three sub-conditions, ALL required -- see try_complete_h2c for the
    //     rationale.
    have_pidx = c2h_wb_status_pidx.exists(q) && c2h_wb_status_cidx.exists(q);
    if (!have_pidx) return;
    // 2c ORDERING - writeback must arrive after the byte count passed
    if (!c2h_wb_at_bytes.exists(q)) return;
    if (!c2h_wb_evt_cnt.exists(q)) return;
    if (c2h_wb_evt_cnt[q] <= c2h_wb_at_bytes[q]) return;
    // 2b LOCATION - landed at this queue's status slot
    if (!c2h_wb_addr_ok_q.exists(q) || !c2h_wb_addr_ok_q[q]) return;
    if (c2h_wb_addr_err_q.exists(q) && (c2h_wb_addr_err_q[q] > 0)) return;
    // 2a VALUE
    wb_ok = (c2h_wb_status_cidx[q] === c2h_wb_status_pidx[q]);
    if (!wb_ok) return;

    // (3) MSI-X to host, only for queues that use interrupts.
    //     Per owning function -- see the H2C gate above for why the direction
    //     total is not sufficient.
    if (qid_irq_en(q)) begin
      int f = qid_fnc(q);
      if (f < 0) begin
        `uvm_error("DMA_SCOREBOARD", $sformatf(
          "C2H qid=%0d has no registered owning function -- cannot attribute its MSI-X. Completion withheld rather than credited from the direction total.", q))
        return;
      end
      if (!c2h_msix_fnc_cnt.exists(f)) c2h_msix_fnc_cnt[f] = 0;
      if (!c2h_msix_used.exists(f))    c2h_msix_used[f]    = 0;
      // ORDERING, then COUNTING -- see the H2C gate above.
      if (!c2h_msix_at_bytes.exists(q)) c2h_msix_at_bytes[q] = c2h_msix_fnc_cnt[f];
      if (c2h_msix_fnc_cnt[f] <= c2h_msix_at_bytes[q]) return;
      if (c2h_msix_fnc_cnt[f] - c2h_msix_used[f] <= 0) return;
      c2h_msix_used[f]++;
    end

    qid_cmp_cnt++;
    c2h_trfr_done[q] = 1'b1;
    // No byte-count-only fallback: all three conditions are hard gates above,
    // so reaching here means every one of them was satisfied.
    `uvm_info("DMA_SCOREBOARD", $sformatf(
      "C2H COMPLETE qid=%0d bytes=%0d cidx=0x%04h == pidx=0x%04h @slot msix=%s (bytes AND wb[value+slot+after-bytes] AND interrupt) qid_cmp_cnt=%0d/%0d",
      q, c2h_bytes[q], c2h_wb_status_cidx[q], c2h_wb_status_pidx[q],
      qid_irq_en(q) ? "seen" : "n/a-polling", qid_cmp_cnt, qid_in_test), UVM_NONE)
    log_event("C2H_DONE", int'(q), 0, 0, c2h_bytes[q], c2h_exp_bytes(q), c2h_cnt[q],
              $sformatf("bytes+cidx qid_cmp_cnt=%0d/%0d PASS", qid_cmp_cnt, qid_in_test));
    check_c2h_integrity(q);
  endfunction

  // --- run_phase --------------------------------------------------------------
  task run_phase(uvm_phase phase);
  host_req_tr tr;
  longint unsigned exp_bytes;
  longint unsigned bytes_this_tlp;
  // Watchdog state: updated on every TLP; watchdog thread monitors for stalls.
  bit           dma_started  = 0;     // set on first TLP  - gates the watchdog
  // STALL_LIMIT is a class member (see declaration near last_tlp_time).
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
  c2h_host_done.delete();
  h2c_cidx_latest.delete();
  c2h_cidx_latest.delete();
  h2c_bytes.delete();
  c2h_bytes.delete();
  h2c_user_data.delete();

  // -- Progress watchdog ------------------------------------------------------
  // Fires only when NO DMA-related activity (DUT TLP, host register access --
  // see last_dma_activity_time) AND no descriptor-status writeback has happened
  // for STALL_LIMIT after DMA has started, and that condition survives a second
  // confirmation check one STALL_LIMIT/2 later. DMA_COMPLETION_WATCHDOG below
  // only engages once qid_cmp_cnt > 0, so this is the only watchdog active
  // while qid_cmp_cnt stays 0.
  fork
    begin : DMA_PROGRESS_WATCHDOG
      int unsigned last_progress_wb_cnt;
      time         last_progress_time;
      wait (dma_started);          // idle until first TLP  - don't fire during CDO/link phase
      last_progress_wb_cnt = wb_mwr_count;
      last_progress_time   = $time;
      forever begin
        #(STALL_LIMIT);
        if (test_done) break;
        if (wb_mwr_count != last_progress_wb_cnt) begin
          last_progress_wb_cnt = wb_mwr_count;
          last_progress_time   = $time;
        end
        if (($time - last_dma_activity_time()) >= STALL_LIMIT &&
            ($time - last_progress_time) >= STALL_LIMIT) begin
          // Additional check to correctly confirm a genuine stall: wait one
          // more half-window and re-sample both signals before fataling, so
          // a single-sample coincidence (e.g. a writeback landing just past
          // this window's boundary) cannot trip a false-positive fatal on a
          // DUT that is still actively working.
          #(STALL_LIMIT/2);
          if (test_done) break;
          if (wb_mwr_count != last_progress_wb_cnt) begin
            last_progress_wb_cnt = wb_mwr_count;
            last_progress_time   = $time;
          end
          if (!test_done && ($time - last_dma_activity_time()) >= STALL_LIMIT &&
              ($time - last_progress_time) >= STALL_LIMIT) begin
            dump_hw_ctxt_cidx_snapshot("DMA_WATCHDOG");
            dump_progress_snapshot("DMA_WATCHDOG");
            `uvm_fatal("DMA_WATCHDOG",
              $sformatf("No DMA activity for %0t (now %0t; last TLP %0t, last_fsm_activity_time %0t, last host register access %0t, last_flr_activity_time %0t) AND no descriptor writeback progress for the same window (wb_mwr_count=%0d, last advance at %0t) -- confirmed on a second check. qid_cmp_cnt=%0d/%0d. DUT stalled  - check descriptor fetch, credits, or irq_en.",
                        STALL_LIMIT, $time, last_tlp_time, last_fsm_activity_time,
                        last_mmio_time, last_flr_activity_time, wb_mwr_count, last_progress_time,
                        qid_cmp_cnt, qid_in_test))
          end
        end
      end
    end
  join_none

  // -- Completion progress watchdog -------------------------------------------
  // Fires when qid_cmp_cnt is frozen below its target AND nothing related to a
  // DMA transfer happens for a full STALL_LIMIT: no descriptor writeback, no
  // DUT TLP, no host register access. A test can legitimately go longer than
  // STALL_LIMIT between queue completions while it works through other steps
  // (a driver sequence spends
  // hundreds of us on mailbox exchanges and context commands between queues).
  // An error loop that keeps TLPs flowing is held off here and is caught by the
  // error checks, the per-transfer timeouts or SIM_TIMEOUT.
  fork
    begin : DMA_COMPLETION_WATCHDOG
      integer      last_cmp_cnt;
      int unsigned last_wb_cnt;
      time         last_cmp_time;
      time         last_wb_time;
      bit          hold_reported;
      wait (dma_started);
      last_cmp_cnt  = qid_cmp_cnt;
      last_wb_cnt   = wb_mwr_count;
      last_cmp_time = $time;
      last_wb_time  = $time;
      hold_reported = 1'b0;
      forever begin
        #(STALL_LIMIT);
        if (test_done) break;
        // Descriptor-status writeback counts as pending data-transfer work.
        // A queue is not complete until its writebacks land, and those drain
        // serially (see wb_mwr_count decl),
        // so a run can legitimately go longer than STALL_LIMIT between QUEUE
        // completions while writebacks advance steadily.
        if (wb_mwr_count != last_wb_cnt) begin
          last_wb_cnt  = wb_mwr_count;
          last_wb_time = $time;
        end
        if (qid_cmp_cnt != last_cmp_cnt) begin
          last_cmp_cnt  = qid_cmp_cnt;
          last_cmp_time = $time;
          hold_reported = 1'b0;
        end else if (qid_cmp_cnt > 0 && qid_cmp_cnt < qid_in_test &&
                     ($time - last_cmp_time)            >= STALL_LIMIT &&
                     ($time - last_wb_time)             >= STALL_LIMIT &&
                     ($time - last_dma_activity_time()) >= STALL_LIMIT) begin
          // Nothing related to a DMA transfer happened for a full window: no
          // completion, no writeback, no DUT TLP, no host register access.
          dump_progress_snapshot("DMA_CMP_WATCHDOG");
          `uvm_fatal("DMA_CMP_WATCHDOG",
            $sformatf("No DMA activity for %0t: qid_cmp_cnt=%0d/%0d (last advance at %0t), wb_mwr_count=%0d (last at %0t), last TLP %0t, last_fsm_activity_time %0t, last host register access %0t, last_flr_activity_time %0t. DMA stalled.",
                      STALL_LIMIT, qid_cmp_cnt, qid_in_test, last_cmp_time,
                      wb_mwr_count, last_wb_time, last_tlp_time,
                      last_fsm_activity_time, last_mmio_time, last_flr_activity_time))
        end else if (qid_cmp_cnt > 0 && qid_cmp_cnt < qid_in_test &&
                     ($time - last_cmp_time) >= STALL_LIMIT && !hold_reported) begin
          // Held off because DMA-related work is still happening. Reported once
          // per completion gap so a real hang that ends at SIM_TIMEOUT still
          // leaves a breadcrumb, without repeating the line every window.
          hold_reported = 1'b1;
          `uvm_info("DMA_CMP_WATCHDOG",
            $sformatf("No QUEUE completion for %0t (qid_cmp_cnt=%0d/%0d, last advance at %0t), but DMA-related activity continues (wb_mwr_count=%0d last at %0t, last TLP %0t, last_fsm_activity_time %0t, last host register access %0t, last_flr_activity_time %0t) - watchdog HELD OFF. Reported once per completion gap.",
                      STALL_LIMIT, qid_cmp_cnt, qid_in_test, last_cmp_time,
                      wb_mwr_count, last_wb_time, last_tlp_time,
                      last_fsm_activity_time, last_mmio_time, last_flr_activity_time), UVM_LOW)
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
      // Provisional: the qid is not decoded yet. Re-evaluated per qid below,
      // which matters once sizes differ per queue.
      exp_bytes      = qid_exp_bytes(11'd0);
      // Update watchdog state on every TLP
      if (!dma_started)
        dma_first_tlp_time = $time;
      dma_started  = 1;
      last_tlp_time = $time;

      case (tr.dma_pkt_type)

        // -- MRD: H2C descriptor fetch or H2C data DMA ----------------------
        host_req_tr::MRD: begin

          // -- H2C descriptor fetch -----------------------------------------
          //
          // ATTRIBUTION CAVEAT: the qid below is derived
          // PURELY from address arithmetic, and this ring-region test runs
          // BEFORE the data-region test, so any MRD landing in the ring range is
          // reported as a descriptor fetch for the ring that owns that address.
          // A data read whose source address lies in the ring region is therefore
          // reported as another queue's descriptor fetch.
          // Do NOT use per-qid H2C_DSC_FETCH counts to conclude "queue X did /
          // did not fetch its descriptors". The raw address is logged; re-derive from it.
          if (tr.addr >= H2C_DSC_ADDR &&
              tr.addr <  H2C_DSC_ADDR + HOST_DSC_MEM_SIZE) begin
            // Derive qid from descriptor ring offset (stride is the queue's
            // own descriptor size, not a fixed constant -- see
            // resolve_h2c_qid_and_sz).
            int unsigned dsc_qid, dsc_qid_sz, dsc_this_tlp;
            resolve_h2c_qid_and_sz(tr.addr, dsc_qid, dsc_qid_sz);
            dsc_this_tlp = (dsc_qid_sz > 0) ? (bytes_this_tlp / dsc_qid_sz) : 0;
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
            int unsigned dsc_qid, dsc_qid_sz, dsc_this_tlp;
            resolve_c2h_qid_and_sz(tr.addr, dsc_qid, dsc_qid_sz);
            dsc_this_tlp = (dsc_qid_sz > 0) ? (bytes_this_tlp / dsc_qid_sz) : 0;
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
            h2c_qid   = host_addr[qid_addr_shift()+:$bits(h2c_qid)];
            exp_bytes = qid_exp_bytes(h2c_qid);   // per-qid, now that qid is known
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

            // Completion: all pidx*DMA_BYTE_CNT bytes read from host memory.
            // Both modes: this is condition (1) of try_complete_h2c(). ST mode
            // additionally requires the user-side AXI-Stream data, recorded in
            // receive_h2c_user_pkt().
            if (h2c_bytes[h2c_qid] == exp_bytes && !h2c_host_done.exists(h2c_qid)) begin
              h2c_host_done[h2c_qid] = 1'b1;
              // Ordering snapshot: the certifying writeback must come AFTER this.
              if (!h2c_wb_at_bytes.exists(h2c_qid))
                h2c_wb_at_bytes[h2c_qid] = h2c_wb_evt_cnt.exists(h2c_qid) ? h2c_wb_evt_cnt[h2c_qid] : 0;
              // Snapshot the MSI-X count at the instant the BYTES completed. Arming this
              // lazily inside the completion gate would be wrong: if the interrupt had
              // already arrived before the gate first ran, the snapshot would capture it
              // and then wait for a SECOND one that never comes.
              // Snapshot the OWNING FUNCTION's count, matching the gate.
              // Snapshotting the direction total here and comparing a
              // per-function count later would mix two different quantities.
              begin
                int fsnap = qid_fnc(h2c_qid);
                if (fsnap < 0) h2c_msix_at_bytes[h2c_qid] = 0;
                else begin
                  if (!h2c_msix_fnc_cnt.exists(fsnap)) h2c_msix_fnc_cnt[fsnap] = 0;
                  h2c_msix_at_bytes[h2c_qid] = h2c_msix_fnc_cnt[fsnap];
                end
              end
              if (!dma_st) begin
                // MM mode: bytes are complete. Completion is NOT declared here.
                //
                // Byte count alone is the wrong pass criterion: it says the data
                // moved, not that the IP reported it. The driver polls CIDX, so a
                // transfer whose bytes all move but whose CIDX writeback never
                // reaches PIDX wedges the driver -- and a byte-count-only check
                // scores that as a PASS.
                //
                // try_complete_h2c() below declares completion only once BOTH the
                // bytes and the CIDX writeback have landed.
                `uvm_info("DMA_SCOREBOARD",
                  $sformatf("H2C byte-count reached qid=%0d bytes=%0d (TLPs=%0d) -- awaiting CIDX writeback before completion",
                             h2c_qid, h2c_bytes[h2c_qid], h2c_cnt[h2c_qid]), UVM_NONE)
                try_complete_h2c(h2c_qid);
              end else begin
                // ST mode: host-side bytes complete. Same gate as MM, plus the
                // user-side AXI-Stream data condition (see try_complete_h2c).
                `uvm_info("DMA_SCOREBOARD",
                  $sformatf("H2C host-side MRD done qid=%0d bytes=%0d (TLPs=%0d) -- awaiting PL-side data, CIDX writeback and interrupt before completion",
                             h2c_qid, h2c_bytes[h2c_qid], h2c_cnt[h2c_qid]), UVM_NONE)
                log_event("H2C_HOST_DONE", int'(h2c_qid), tr.addr,
                          0, h2c_bytes[h2c_qid], exp_bytes, h2c_cnt[h2c_qid],
                          "host-side MRD bytes complete, PL-side pending");
                try_complete_h2c(h2c_qid);
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
          drv_mwr_unknown = 1'b0;
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
                  tr.addr <  c2h_dst_base[q] + c2h_win_bytes(q)) begin
                matched     = 1;
                matched_qid = q;
                break;
              end
            end

            if (matched) begin
              c2h_qid = matched_qid;
              if (c2h_pkt_bytes != 0)
                exp_bytes = c2h_exp_bytes(c2h_qid);
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
              // Bytes complete. Completion is NOT declared here -- the C2H
              // CIDX writeback must land first, same rule as H2C. A
              // byte-count-only PASS reports success on a transfer whose
              // completion index never reaches pidx, which is exactly what
              // wedges the driver.
              if (c2h_bytes[c2h_qid] == exp_bytes && !c2h_host_done.exists(c2h_qid)) begin
                c2h_host_done[c2h_qid] = 1'b1;
                // Ordering snapshot: the certifying writeback must come AFTER this.
                if (!c2h_wb_at_bytes.exists(c2h_qid))
                  c2h_wb_at_bytes[c2h_qid] = c2h_wb_evt_cnt.exists(c2h_qid) ? c2h_wb_evt_cnt[c2h_qid] : 0;
                // Snapshot the MSI-X count at the instant the BYTES completed. Arming this
                // lazily inside the completion gate would be wrong: if the interrupt had
                // already arrived before the gate first ran, the snapshot would capture it
                // and then wait for a SECOND one that never comes.
                // Snapshot the OWNING FUNCTION's count, matching the gate.
                begin
                  int fsnap = qid_fnc(c2h_qid);
                  if (fsnap < 0) c2h_msix_at_bytes[c2h_qid] = 0;
                  else begin
                    if (!c2h_msix_fnc_cnt.exists(fsnap)) c2h_msix_fnc_cnt[fsnap] = 0;
                    c2h_msix_at_bytes[c2h_qid] = c2h_msix_fnc_cnt[fsnap];
                  end
                end
                `uvm_info("DMA_SCOREBOARD",
                  $sformatf("C2H byte-count reached qid=%0d bytes=%0d (TLPs=%0d) -- awaiting CIDX writeback before completion",
                             c2h_qid, c2h_bytes[c2h_qid], c2h_cnt[c2h_qid]), UVM_NONE)
                try_complete_c2h(c2h_qid);
              end

            // -- MSI-X interrupt MWR ---------------------------------------
            // The DUT sends a PCIe MWr to the host MSI-X vector table entry
            // after each queue completion.  Address format programmed by
            // TSK_PROGRAM_MSIX_VEC_TABLE:
            //   msix_host_base = H2C_DAT_SRC_ADDR + H2C_DAT_SIZE + fnc*32  (base 0x000B_1000)
            //   addr[31:0]  = msix_host_base + vec*4  (vec = 1 for H2C, 2 for C2H)
            //   addr[63:32] = 0 (fixed; addr_hi is always 0 for 32-bit MSI-X)
            //   data[31:0]  = 0xFACE0000 + vec  (programmed by TSK_PROGRAM_MSIX_VEC_TABLE line: data = 32'hFACE0000 + i)
            // MSI-X address verified (vec from addr offset); data matches programmed vector table value.
            end else if (tr.addr >= (H2C_DAT_SRC_ADDR + H2C_DAT_SIZE) &&
                         tr.addr <  (H2C_DAT_SRC_ADDR + H2C_DAT_SIZE + MSIX_FNC_STRIDE*MSIX_MAX_FNCS)) begin
              int msix_vec, msix_fnc, msix_off;
              bit [31:0] exp_data, got_data;
              // Per-function MSI-X regions (qdma_base_test.sv TSK_PROGRAM_MSIX_VEC_TABLE):
              //   addr = base + fnc*MSIX_FNC_STRIDE + vec*4
              // Decoding fnc here makes per-function attribution possible.
              msix_off = int'(tr.addr[31:0] - (H2C_DAT_SRC_ADDR[31:0] + H2C_DAT_SIZE));
              msix_fnc = msix_off / MSIX_FNC_STRIDE;
              msix_vec = (msix_off % MSIX_FNC_STRIDE) >> 2;
              // Direction totals (used by the end-of-test aggregate checks)
              // AND per-function counts, which are what the completion gate uses.
              if      (msix_vec == 1) begin
                h2c_msix_cnt++;
                if (!h2c_msix_fnc_cnt.exists(msix_fnc)) h2c_msix_fnc_cnt[msix_fnc] = 0;
                h2c_msix_fnc_cnt[msix_fnc]++;
              end
              else if (msix_vec == 2) begin
                c2h_msix_cnt++;
                if (!c2h_msix_fnc_cnt.exists(msix_fnc)) c2h_msix_fnc_cnt[msix_fnc] = 0;
                c2h_msix_fnc_cnt[msix_fnc]++;
              end
              // Re-evaluate completion for every queue still waiting. This path
              // is the ONLY place the msix counters move, and condition (3) of
              // try_complete_* reads them.
              //
              // Swept rather than targeted because an MSI-X message carries a
              // VECTOR, not a QID: vec 1/2 are per-DIRECTION, so the owning
              // queue cannot be identified from the message. The sweep is over
              // queues that have already finished their bytes, so it is short,
              // and try_complete_* is idempotent via *_trfr_done.
              if (msix_vec == 1)
                foreach (h2c_host_done[qq]) try_complete_h2c(qq);
              else if (msix_vec == 2)
                foreach (c2h_host_done[qq]) try_complete_c2h(qq);
              if (msix_vec >= 0 && msix_vec <= 7) msix_vec_cnt[msix_vec]++;
              msix_fnc_vec_cnt[msix_fnc][msix_vec] = msix_fnc_vec(msix_fnc, msix_vec) + 1;
              drv_irq_msix(msix_fnc, msix_vec);
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
                        $sformatf("MSI-X interrupt MWr fnc=%0d vec=%0d data=0x%08h exp=0x%08h %s",
                                  msix_fnc, msix_vec, got_data, exp_data,
                                  (got_data === exp_data) ? "(PASS)" : "(DATA MISMATCH)"));

            // -- Descriptor ring writeback MWR -----------------------------
            // QDMA DMA engine writes CIDX/status back into the H2C or C2H
            // descriptor ring in host memory after completing descriptors.
            // Per-slot address check: the WBI status descriptor must land at
            // dsc_base + (RING_SIZE-1)*dsc_sz (the last slot of the ring),
            // dsc_sz being the queue's own descriptor size.
            // A C2H WB at the H2C base is a DUT defect this check catches.
            end else if (tr.addr >= H2C_DSC_ADDR &&
                         tr.addr <  H2C_DSC_ADDR + HOST_DSC_MEM_SIZE) begin
              begin
                // Derive H2C QID from address offset in the ring array. The
                // ring base stride is the QUEUE'S OWN descriptor size (16B
                // ST / 32B MM), not a fixed QDMA_DSC_SZ -- see
                // resolve_h2c_qid_and_sz.
                int unsigned wb_dsc_qid;
                int unsigned wb_dsc_sz;
                longint unsigned wb_dsc_base;
                longint unsigned wb_exp_addr;
                string wb_extra;
                bit [15:0] wb_cidx_now, wb_pidx_now, wb_cidx_prev;
                bit        wb_cidx_regressed;
                resolve_h2c_qid_and_sz(tr.addr, wb_dsc_qid, wb_dsc_sz);
                wb_dsc_base = H2C_DSC_ADDR + longint'(wb_dsc_qid) *
                              longint'(RING_SIZE) * longint'(wb_dsc_sz);
                // WB status slot is the last entry of the ring, sized in
                // units of the queue's own descriptor size (32B MM, 16B ST).
                wb_exp_addr = wb_dsc_base +
                              (longint'(ring_entries) - 1) * longint'(wb_dsc_sz);
                // Record first WB MWr address for this H2C QID
                if (!h2c_wb_mwr_addr.exists(11'(wb_dsc_qid)))
                  h2c_wb_mwr_addr[11'(wb_dsc_qid)] = tr.addr;
                // Capture WB status PIDX/CIDX from TLP payload (PG302 Table 10):
                //   DWord 0 bits[31:16] = cidx, DWord 1 bits[15:0] = pidx
                // The payload carries the HOST-VISIBLE cidx, the only value a real
                // driver acts on. Log the decoded payload, and check monotonicity here: a cidx
                // writeback means "all descriptors below this are consumed", so a
                // backward step tells the driver live descriptors are free and is a
                // data-integrity hazard, not a cosmetic ordering issue.
                wb_cidx_now = 0; wb_pidx_now = 0; wb_cidx_regressed = 1'b0;
                if (tr.data.size() >= 2) begin
                  wb_cidx_now = tr.data[0][31:16];
                  wb_pidx_now = tr.data[1][15:0];
                  // Driver mode: the status cidx is the driver's credit -- it
                  // must stay inside the ring and never pass the last doorbell
                  if (drv_mode && drv_h2c_db.exists(11'(wb_dsc_qid))) begin
                    int unsigned rs, prev, adv, room;
                    rs   = drv_h2c_rngsz[11'(wb_dsc_qid)];
                    prev = h2c_wb_status_cidx.exists(11'(wb_dsc_qid)) ? h2c_wb_status_cidx[11'(wb_dsc_qid)] : 0;
                    adv  = (int'(wb_cidx_now) + rs - prev) % rs;
                    room = (drv_h2c_db[11'(wb_dsc_qid)] + rs - prev) % rs;
                    void'(drv_chk("DRV_RANGE", wb_cidx_now < rs && adv <= room,
                                  $sformatf("H2C qid %0d status cidx %0d -> %0d (ring %0d, last doorbell pidx %0d): credit past what the driver posted",
                                            wb_dsc_qid, prev, wb_cidx_now, rs, drv_h2c_db[11'(wb_dsc_qid)])));
                    void'(drv_chk("DRV_WB_ERR", tr.data[0][1:0] == 2'b00,
                                  $sformatf("H2C qid %0d status writeback error field %0b (bit 1: DMA abort)",
                                            wb_dsc_qid, tr.data[0][1:0])));
                    if (wb_cidx_now != 16'(prev)) drv_irq_advance("H2C", 11'(wb_dsc_qid));
                  end
                  if (h2c_wb_status_cidx.exists(11'(wb_dsc_qid))) begin
                    wb_cidx_prev = h2c_wb_status_cidx[11'(wb_dsc_qid)];
                    // Guard against a legitimate ring wrap: only a backward step
                    // smaller than half the ring is a genuine regression.
                    // Wrap-vs-regression discriminator must use the RUNTIME ring size
                    // (+RING_ENTRIES), not the compile-time RING_SIZE. With RING_SIZE=4096
                    // the half-ring threshold is 2048, so a legitimate wrap on a 64-entry
                    // ring (e.g. cidx 0x37 -> 0x00, a drop of 55) is mis-flagged as a
                    // backward jump. Against ring_entries=64 the threshold is 32 and the
                    // same transition is correctly read as a wrap.
                    if ((wb_cidx_now < wb_cidx_prev) &&
                        ((wb_cidx_prev - wb_cidx_now) < (ring_entries/2))) begin
                      wb_cidx_regressed = 1'b1;
                      h2c_wb_cidx_regress_cnt++;
                      `uvm_error("DMA_SCOREBOARD",
                        $sformatf("H2C WB CIDX REGRESSION: qid=%0d cidx 0x%04x -> 0x%04x (went BACKWARD by %0d) at addr=0x%0h -- host is told already-consumed descriptors are free",
                                  wb_dsc_qid, wb_cidx_prev, wb_cidx_now,
                                  wb_cidx_prev - wb_cidx_now, tr.addr))
                    end
                  end
                  h2c_wb_status_cidx[11'(wb_dsc_qid)] = wb_cidx_now;
                  h2c_wb_status_pidx[11'(wb_dsc_qid)] = wb_pidx_now;
                  // Re-evaluate completion HERE. try_complete_h2c() reads
                  // h2c_wb_status_cidx/pidx, and this is the only place they are
                  // written.
                  // Record slot-address correctness BEFORE try_complete, which
                  // reads it as condition 2b. The address check below runs AFTER
                  // this call, so gating on it there would always be one
                  // writeback behind.
                  if (!h2c_wb_evt_cnt.exists(11'(wb_dsc_qid)))
                    h2c_wb_evt_cnt[11'(wb_dsc_qid)] = 0;
                  h2c_wb_evt_cnt[11'(wb_dsc_qid)]++;
                  if (tr.addr == wb_exp_addr)
                    h2c_wb_addr_ok_q[11'(wb_dsc_qid)] = 1'b1;
                  else begin
                    if (!h2c_wb_addr_err_q.exists(11'(wb_dsc_qid)))
                      h2c_wb_addr_err_q[11'(wb_dsc_qid)] = 0;
                    h2c_wb_addr_err_q[11'(wb_dsc_qid)]++;   // sticky: never cleared
                  end
                  try_complete_h2c(11'(wb_dsc_qid));
                end
                if (tr.addr == wb_exp_addr) begin
                  wb_extra = $sformatf("H2C WB_SLOT OK qid=%0d addr=0x%0h == exp=0x%0h  cidx=0x%04x pidx=0x%04x%s",
                                       wb_dsc_qid, tr.addr, wb_exp_addr,
                                       wb_cidx_now, wb_pidx_now,
                                       wb_cidx_regressed ? "  *** CIDX_REGRESSION ***" : "");
                end else begin
                  h2c_wb_addr_err_cnt++;
                  wb_extra = $sformatf("H2C WB_SLOT ERR qid=%0d addr=0x%0h exp=0x%0h  cidx=0x%04x pidx=0x%04x%s",
                                       wb_dsc_qid, tr.addr, wb_exp_addr,
                                       wb_cidx_now, wb_pidx_now,
                                       wb_cidx_regressed ? "  *** CIDX_REGRESSION ***" : "");
                  `uvm_error("DMA_SCOREBOARD",
                    $sformatf("H2C WB address mismatch: qid=%0d got=0x%0h exp=0x%0h (dsc_base=0x%0h + (ring_entries-1)*dsc_sz(%0d)=0x%0h) -- WB landed at wrong slot",
                              wb_dsc_qid, tr.addr, wb_exp_addr,
                              wb_dsc_base, wb_dsc_sz, wb_exp_addr - wb_dsc_base))
                end
                wb_mwr_count++;   // watchdog: writeback IS pending transfer work
                log_event("DSC_WB_MWR", wb_dsc_qid, tr.addr,
                          bytes_this_tlp, 0, 0, 0, wb_extra);
              end
            end else if (tr.addr >= C2H_DSC_ADDR &&
                         tr.addr <  C2H_DSC_ADDR + HOST_DSC_MEM_SIZE) begin
              begin
                // Derive C2H QID from address offset in the ring array. See
                // resolve_c2h_qid_and_sz / the H2C counterpart above: the
                // ring stride is the queue's own descriptor size, not a
                // fixed QDMA_DSC_SZ.
                int unsigned wb_dsc_qid;
                int unsigned wb_dsc_sz;
                longint unsigned wb_dsc_base;
                longint unsigned wb_exp_addr;
                string wb_extra;
                bit [15:0] wb_cidx_now, wb_pidx_now, wb_cidx_prev;
                bit        wb_cidx_regressed;
                resolve_c2h_qid_and_sz(tr.addr, wb_dsc_qid, wb_dsc_sz);
                wb_dsc_base = c2h_ring_base(wb_dsc_qid, longint'(wb_dsc_sz));
                // WB status slot is the last entry of the ring, sized in
                // units of the queue's own descriptor size (32B MM, 16B ST).
                wb_exp_addr = wb_dsc_base +
                              (longint'(ring_entries) - 1) * longint'(wb_dsc_sz);
                // Record first WB MWr address for this C2H QID
                if (!c2h_wb_mwr_addr.exists(11'(wb_dsc_qid)))
                  c2h_wb_mwr_addr[11'(wb_dsc_qid)] = tr.addr;
                // Capture WB status PIDX/CIDX from TLP payload (PG302 Table 10):
                //   DWord 0 bits[31:16] = cidx, DWord 1 bits[15:0] = pidx
                // See the H2C branch above for why the payload is logged and
                // checked here.
                wb_cidx_now = 0; wb_pidx_now = 0; wb_cidx_regressed = 1'b0;
                if (tr.data.size() >= 2) begin
                  wb_cidx_now = tr.data[0][31:16];
                  wb_pidx_now = tr.data[1][15:0];
                  if (c2h_wb_status_cidx.exists(11'(wb_dsc_qid))) begin
                    wb_cidx_prev = c2h_wb_status_cidx[11'(wb_dsc_qid)];
                    // Wrap-vs-regression discriminator must use the RUNTIME ring size
                    // (+RING_ENTRIES), not the compile-time RING_SIZE. With RING_SIZE=4096
                    // the half-ring threshold is 2048, so a legitimate wrap on a 64-entry
                    // ring (e.g. cidx 0x37 -> 0x00, a drop of 55) is mis-flagged as a
                    // backward jump. Against ring_entries=64 the threshold is 32 and the
                    // same transition is correctly read as a wrap.
                    if ((wb_cidx_now < wb_cidx_prev) &&
                        ((wb_cidx_prev - wb_cidx_now) < (ring_entries/2))) begin
                      wb_cidx_regressed = 1'b1;
                      c2h_wb_cidx_regress_cnt++;
                      `uvm_error("DMA_SCOREBOARD",
                        $sformatf("C2H WB CIDX REGRESSION: qid=%0d cidx 0x%04x -> 0x%04x (went BACKWARD by %0d) at addr=0x%0h -- host is told already-consumed descriptors are free",
                                  wb_dsc_qid, wb_cidx_prev, wb_cidx_now,
                                  wb_cidx_prev - wb_cidx_now, tr.addr))
                    end
                  end
                  c2h_wb_status_cidx[11'(wb_dsc_qid)] = wb_cidx_now;
                  c2h_wb_status_pidx[11'(wb_dsc_qid)] = wb_pidx_now;
                  // Re-evaluate completion HERE. try_complete_c2h() reads
                  // c2h_wb_status_cidx/pidx, and this is the only place they are
                  // written.
                  // Slot-address correctness recorded before try_complete -- see
                  // the H2C site.
                  if (!c2h_wb_evt_cnt.exists(11'(wb_dsc_qid)))
                    c2h_wb_evt_cnt[11'(wb_dsc_qid)] = 0;
                  c2h_wb_evt_cnt[11'(wb_dsc_qid)]++;
                  if (tr.addr == wb_exp_addr)
                    c2h_wb_addr_ok_q[11'(wb_dsc_qid)] = 1'b1;
                  else begin
                    if (!c2h_wb_addr_err_q.exists(11'(wb_dsc_qid)))
                      c2h_wb_addr_err_q[11'(wb_dsc_qid)] = 0;
                    c2h_wb_addr_err_q[11'(wb_dsc_qid)]++;   // sticky: never cleared
                  end
                  try_complete_c2h(11'(wb_dsc_qid));
                end
                if (tr.addr == wb_exp_addr) begin
                  wb_extra = $sformatf("C2H WB_SLOT OK qid=%0d addr=0x%0h == exp=0x%0h  cidx=0x%04x pidx=0x%04x%s",
                                       wb_dsc_qid, tr.addr, wb_exp_addr,
                                       wb_cidx_now, wb_pidx_now,
                                       wb_cidx_regressed ? "  *** CIDX_REGRESSION ***" : "");
                end else begin
                  c2h_wb_addr_err_cnt++;
                  wb_extra = $sformatf("C2H WB_SLOT ERR qid=%0d addr=0x%0h exp=0x%0h  cidx=0x%04x pidx=0x%04x%s",
                                       wb_dsc_qid, tr.addr, wb_exp_addr,
                                       wb_cidx_now, wb_pidx_now,
                                       wb_cidx_regressed ? "  *** CIDX_REGRESSION ***" : "");
                  `uvm_error("DMA_SCOREBOARD",
                    $sformatf("C2H WB address mismatch: qid=%0d got=0x%0h exp=0x%0h (C2H dsc_base=0x%0h + (ring_entries-1)*dsc_sz(%0d)=0x%0h) -- C2H WB landed at wrong slot",
                              wb_dsc_qid, tr.addr, wb_exp_addr,
                              wb_dsc_base, wb_dsc_sz, wb_exp_addr - wb_dsc_base))
                end
                wb_mwr_count++;   // watchdog: writeback IS pending transfer work
                log_event("DSC_WB_MWR", wb_dsc_qid, tr.addr,
                          bytes_this_tlp, 0, 0, 0, wb_extra);
              end

            // -- Completion (CMPT) ring MWR --------------------------------
            // One or more 8-byte entries; each is checked on its own.
            end else if (cmpt_ring_qid(tr.addr) >= 0) begin
              begin
                int          cq;
                int unsigned ents, i0, i1;
                cq = cmpt_ring_qid(tr.addr);
                // Whole 8-byte entries only, and the status slot written on its
                // own (a write covering entries and the status slot, or a
                // trailing half entry, would hit another host object)
                if (drv_mode) begin
                  ents = cmpt_ring_ents.exists(11'(cq)) ? cmpt_ring_ents[11'(cq)] : ring_entries;
                  i0   = int'((tr.addr - cmpt_ring_base[11'(cq)]) / 8);
                  i1   = int'((tr.addr + bytes_this_tlp - 1 - cmpt_ring_base[11'(cq)]) / 8);
                  void'(drv_chk("DRV_TLP_SHAPE",
                                tr.addr % 8 == 0 && tr.data.size() % 2 == 0 && !(i0 != i1 && i1 >= ents - 1),
                                $sformatf("qid %0d completion-ring write at 0x%0h, %0d B (entries %0d..%0d of %0d, status slot %0d)",
                                          cq, tr.addr, bytes_this_tlp, i0, i1, ents, ents - 1)));
                end
                for (int k = 0; k + 1 < tr.data.size(); k += 2)
                  check_cmpt_entry(11'(cq), tr.addr + longint'(k) * 4, {tr.data[k+1], tr.data[k]});
              end

            // -- Driver-posted C2H buffer MWR -------------------------------
            // Bytes counted per buffer; a write crossing a buffer end is split
            // there (the next buffer is not adjacent, so the remainder lands
            // outside every buffer unless the ring happens to continue there).
            end else if (drv_buf_lookup(tr.addr, drv_q0, drv_i0)) begin
              begin
                longint unsigned a, left, chunk;
                int              dq, bi;
                bit              hide;
                a    = tr.addr;
                left = bytes_this_tlp;
                hide = drv_inject("ENTRY_BEFORE_DATA");
                while (left > 0) begin
                  chunk = drv_buf_sz - (a % drv_buf_sz);
                  if (chunk > left) chunk = left;
                  if (!drv_buf_lookup(a, dq, bi)) begin
                    void'(drv_chk("DRV_UNKNOWN_MWR", 1'b0,
                                  $sformatf("UNKNOWN_MWR: %0d B at 0x%0h (tail of a %0d-byte write at 0x%0h) runs past the end of a driver buffer",
                                            chunk, a, bytes_this_tlp, tr.addr)));
                  end else begin
                    if (!(drv_bnp_seen.exists(11'(dq)) && drv_bnp_seen[11'(dq)].exists(bi)))
                      if (!drv_chk("DRV_BUF_NOT_POSTED", drv_buf_posted.exists(11'(dq)) && drv_buf_posted[11'(dq)].exists(bi),
                                   $sformatf("qid %0d buffer %0d written (%0d B at 0x%0h) while the driver owns it (not posted, or already returned)",
                                             dq, bi, chunk, a)))
                        drv_bnp_seen[11'(dq)][bi] = 1'b1;   // one report per buffer until it is posted again
                    drv_c2h_buf_bytes[11'(dq)][bi] = drv_c2h_buf_got(11'(dq), bi) + chunk;
                    if (!hide)
                      drv_chk_buf_bytes[11'(dq)][bi] = ((drv_chk_buf_bytes.exists(11'(dq)) && drv_chk_buf_bytes[11'(dq)].exists(bi)) ?
                                                         drv_chk_buf_bytes[11'(dq)][bi] : 0) + chunk;
                  end
                  a    += chunk;
                  left -= chunk;
                end
                log_event("DRV_C2H_BUF", drv_q0, tr.addr, bytes_this_tlp, 0, 0, 0,
                          $sformatf("buffer %0d", drv_i0));
              end

            // -- Unknown MWR ------------------------------------------------
            end else begin
              log_event("UNKNOWN_MWR", -1, tr.addr,
                        bytes_this_tlp, 0, 0, 0,
                        "address not registered in any known host region");
              drv_mwr_unknown = 1'b1;
              if (drv_mode)
                void'(drv_chk("DRV_UNKNOWN_MWR", 1'b0, $sformatf(
                  "UNKNOWN_MWR: %0d-byte host write at 0x%0h outside every ring and buffer the driver sequence posted",
                  bytes_this_tlp, tr.addr)));
            end
            if (drv_mode && !drv_mwr_unknown) void'(drv_chk("DRV_UNKNOWN_MWR", 1'b1, ""));
          end
        end

      endcase

      if ((qid_cmp_cnt > 0) && (qid_cmp_cnt == qid_in_test) && !wb_drain_spawned) begin
        wb_drain_spawned   = 1;
        dma_last_done_time = $time;
        // Byte-count completion (PCIe MWR data arrival) fires independently of
        // the writeback status (host_mem cidx/pidx) landing, so a multi-QID run
        // can still have writebacks in flight here. wb_req_cnt and
        // wb_pipeline_done_cnt are not fed in this testbench, so the drain wait
        // below is skipped.
        fork
          begin
            time wb_drain_start = $time;
            while (wb_req_cnt != wb_pipeline_done_cnt) begin
              if (($time - wb_drain_start) > WB_DRAIN_TIMEOUT) begin
                `uvm_warning("dma_req_processor", $sformatf(
                  "WB drain wait exceeded WB_DRAIN_TIMEOUT (%0t): wb_req_cnt=%0d wb_pipeline_done_cnt=%0d -- proceeding; check the writeback report for missing entries",
                  WB_DRAIN_TIMEOUT, wb_req_cnt, wb_pipeline_done_cnt))
                break;
              end
              #100ns;
            end
            #1us; // settle margin after drain
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
    if (drv_mode) drv_final();
    // Expected bytes for the summary MUST come from qid_exp_bytes(), not from a
    // second copy of the ladder.
    // Use a representative completed qid; qid_exp_bytes is per-queue and the
    // summary line is explicitly labelled "bytes/queue".
    begin : b_exp_bytes
      bit [10:0] rep_q;
      if      (h2c_trfr_done.first(rep_q)) exp_bytes = qid_exp_bytes(rep_q);
      else if (c2h_trfr_done.first(rep_q)) exp_bytes = qid_exp_bytes(rep_q);
      else                                 exp_bytes = qid_exp_bytes(11'h1);
    end : b_exp_bytes

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

    if (c2h_trfr_done.size() > 0) begin
      bit [10:0] c2h_rep_q;
      void'(c2h_trfr_done.first(c2h_rep_q));
      `uvm_info("DMA_SCOREBOARD",
        $sformatf("C2H byte-count: all %0d queue(s) PASSED (%0d bytes/queue, source=host PCIe MWR accumulation; AXI-PL reported separately)",
                   c2h_trfr_done.size(), (c2h_pkt_bytes != 0) ? c2h_exp_bytes(c2h_rep_q) : exp_bytes), UVM_NONE)
    end

    // Condition 2a: no C2H data errors
    if (c2h_err_cnt > 0)
      `uvm_error("DMA_SCOREBOARD",
        $sformatf("C2H data integrity: TOTAL FAILURES = %0d byte mismatches", c2h_err_cnt))
    else if (c2h_trfr_done.size() > 0 && c2h_not_checked_q.size() == 0)
      `uvm_info("DMA_SCOREBOARD",
        $sformatf("C2H data integrity: all %0d queue(s) PASSED", c2h_trfr_done.size()), UVM_NONE)
    else if (c2h_trfr_done.size() > 0)
      `uvm_info("DMA_SCOREBOARD",
        $sformatf("C2H data integrity: %0d of %0d queue(s) compared and PASSED, %0d NOT CHECKED (payload not compared; see the per-queue NOT CHECKED lines)",
                   c2h_trfr_done.size() - c2h_not_checked_q.size(), c2h_trfr_done.size(), c2h_not_checked_q.size()), UVM_NONE)

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

    // Condition 3: writeback-engine completion events come from a monitor that
    // is not part of this testbench. The host-visible writeback checks (3b, 7)
    // below still cover every completed queue.
    if (qid_cmp_cnt > 0)
      `uvm_info("DMA_SCOREBOARD",
        $sformatf("WB packets NOT OBSERVED: writeback-engine completion events are not monitored in this testbench (%0d completed queues)",
                   qid_cmp_cnt), UVM_NONE)

    // Condition 3b: Per-slot WB destination-address check.
    // Verifies that each WB MWr TLP landed at the correct last-slot address
    // (dsc_base + (RING_SIZE-1)*dsc_sz, dsc_sz per-queue) for each completed queue.
    // Detects a C2H WB that lands at the H2C ring base: such a WB will
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
            longint unsigned wq_dsc_sz;
            // Base/stride and last-slot offset must use the SAME per-queue
            // descriptor size (16B ST / 32B MM) -- see resolve_h2c_qid_and_sz.
            wq_dsc_sz   = (test_ref != null && test_ref.h2c_qid_dsc_sz.exists(int'(wq))) ?
                          longint'(test_ref.h2c_qid_dsc_sz[int'(wq)]) : longint'(QDMA_DSC_SZ);
            wb_dsc_base = H2C_DSC_ADDR + longint'(wq) * RING_SIZE * wq_dsc_sz;
            wb_exp      = wb_dsc_base + (longint'(ring_entries) - 1) * wq_dsc_sz;
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
            longint unsigned wq_dsc_sz;
            wq_dsc_sz   = (test_ref != null && test_ref.c2h_qid_dsc_sz.exists(int'(wq))) ?
                          longint'(test_ref.c2h_qid_dsc_sz[int'(wq)]) : longint'(QDMA_DSC_SZ);
            wb_dsc_base = c2h_ring_base(int'(wq), wq_dsc_sz);
            wb_exp      = wb_dsc_base + (longint'(ring_entries) - 1) * wq_dsc_sz;
            if (!c2h_wb_mwr_addr.exists(wq)) begin
              `uvm_error("DMA_SCOREBOARD",
                $sformatf("C2H WB address MISSING: qid=%0d no WB MWr TLP seen in C2H ring (exp=0x%0h) -- WB write may have been directed to wrong address",
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

      // Host-visible CIDX monotonicity verdict. Reported unconditionally so a
      // clean run states it positively rather than leaving it inferred from the
      // absence of errors.
      if (h2c_wb_cidx_regress_cnt == 0 && c2h_wb_cidx_regress_cnt == 0)
        `uvm_info("DMA_SCOREBOARD",
          "WB CIDX monotonic PASS: no writeback reported a decreasing CIDX to the host", UVM_NONE)
      else
        `uvm_error("DMA_SCOREBOARD",
          $sformatf("WB CIDX monotonic FAIL: H2C_regressions=%0d C2H_regressions=%0d -- a backward CIDX tells the driver live descriptors are consumable",
                    h2c_wb_cidx_regress_cnt, c2h_wb_cidx_regress_cnt))
    end

    // Condition 7: WB status PIDX and CIDX in host memory (PG302 Table 10).
    // Explicit host_mem readback at the expected WB ring address (last descriptor slot).
    // Layout: DWord0[31:16]=cidx (bytes+2,+3), DWord1[15:0]=pidx (bytes+4,+5), little-endian.
    // Iterate h2c_bytes/c2h_bytes, NOT h2c_trfr_done/c2h_trfr_done. The done-sets hold
    // only queues that COMPLETED; the bytes-maps are keyed by every QID that moved a
    // single TLP, so a queue that started and stalled is also checked and reports
    // with did_complete=0.
    begin
      bit wb_sts_pass;
      bit [15:0] wb_exp_pidx;
      int unsigned ring_mod;
      wb_sts_pass = 1;
      // Expected FINAL host-visible PIDX: total_dsc_cnt mod ring_usable() when
      // total_dsc_cnt is set (ring_entries - 1, since the last ring entry is
      // reserved for the WB status descriptor), otherwise `pidx`.
      ring_mod    = (ring_entries > 1) ? (ring_entries - 1) : 1;
      // +XFER_LIST mode: the ring advances CUMULATIVELY across packets, so the
      // final pidx the host sees is the total descriptor count over ALL packets
      // -- not `pidx`, which here is the raw +PIDX plusarg and has nothing to do
      // with an xfer_list run.
      if (test_ref.xfer_list.size() > 0)
        wb_exp_pidx = 16'(test_ref.xfer_list_total_desc() % ring_mod);
      else
        wb_exp_pidx = (total_dsc_cnt > 0) ? 16'(total_dsc_cnt % ring_mod) : 16'(pidx);
      if (h2c_bytes.size() > 0) begin
        bit [10:0] wq;
        bit [15:0] wb_exp_pidx_h2c;
        // A page-split H2C request advances the ring by more than one descriptor.
        wb_exp_pidx_h2c = (drv_h2c_dsc_per_req > 1 && test_ref.xfer_list.size() == 0 && total_dsc_cnt == 0) ?
                          16'((longint'(pidx) * drv_h2c_dsc_per_req) % ring_mod) : wb_exp_pidx;
        if (drv_h2c_total_dsc > 0) wb_exp_pidx_h2c = 16'(drv_h2c_total_dsc % ring_mod);
        if (h2c_bytes.first(wq)) begin
          do begin
            longint unsigned wb_dsc_base, wb_exp, wq_dsc_sz;
            bit [15:0] hm_cidx, hm_pidx;
            bit        wq_done;
            wq_done     = h2c_trfr_done.exists(wq) && h2c_trfr_done[wq];
            wq_dsc_sz   = (test_ref != null && test_ref.h2c_qid_dsc_sz.exists(int'(wq))) ?
                          longint'(test_ref.h2c_qid_dsc_sz[int'(wq)]) : longint'(QDMA_DSC_SZ);
            wb_dsc_base = H2C_DSC_ADDR + longint'(wq) * RING_SIZE * wq_dsc_sz;
            wb_exp      = wb_dsc_base + (longint'(ring_entries) - 1) * wq_dsc_sz;
            if (test_ref == null || !test_ref.host_mem.exists(int'(wb_exp + 2))) begin
              `uvm_error("DMA_SCOREBOARD",
                $sformatf("H2C WB status MISSING: qid=%0d host_mem[0x%0h] empty -- WB never landed at expected address",
                          wq, wb_exp))
              wb_sts_pass = 0;
            end else begin
              hm_cidx = {test_ref.host_mem[int'(wb_exp + 3)], test_ref.host_mem[int'(wb_exp + 2)]};
              hm_pidx = {test_ref.host_mem[int'(wb_exp + 5)], test_ref.host_mem[int'(wb_exp + 4)]};
              if (hm_pidx != wb_exp_pidx_h2c) begin
                `uvm_error("DMA_SCOREBOARD",
                  $sformatf("H2C WB status PIDX MISMATCH: qid=%0d host_mem[0x%0h] pidx=0x%04h exp=0x%04h",
                            wq, wb_exp, hm_pidx, wb_exp_pidx_h2c))
                wb_sts_pass = 0;
              // CIDX check: after all DMA rounds complete, CIDX must equal PIDX.
              end else if (hm_cidx != wb_exp_pidx_h2c) begin
                `uvm_error("DMA_SCOREBOARD",
                  $sformatf("H2C WB status CIDX MISMATCH: qid=%0d host_mem[0x%0h] cidx=0x%04h exp=0x%04h did_complete=%0d",
                            wq, wb_exp, hm_cidx, wb_exp_pidx_h2c, wq_done))
                wb_sts_pass = 0;
              end else
                `uvm_info("DMA_SCOREBOARD",
                  $sformatf("H2C WB status PASS: qid=%0d host_mem[0x%0h] pidx=0x%04h cidx=0x%04h did_complete=%0d",
                            wq, wb_exp, hm_pidx, hm_cidx, wq_done), UVM_NONE)
            end
          end while (h2c_bytes.next(wq));
        end
      end
      if (c2h_bytes.size() > 0) begin
        bit [10:0] wq;
        // The C2H ring advances c2h_dsc_per_pkt descriptors per packet.
        if (c2h_dsc_per_pkt > 1)
          wb_exp_pidx = 16'((longint'(pidx) * c2h_dsc_per_pkt) % ring_mod);
        if (c2h_bytes.first(wq)) begin
          do begin
            longint unsigned wb_dsc_base, wb_exp, wq_dsc_sz;
            bit [15:0] hm_cidx, hm_pidx;
            bit        wq_done;
            wq_done     = c2h_trfr_done.exists(wq) && c2h_trfr_done[wq];
            wq_dsc_sz   = (test_ref != null && test_ref.c2h_qid_dsc_sz.exists(int'(wq))) ?
                          longint'(test_ref.c2h_qid_dsc_sz[int'(wq)]) : longint'(QDMA_DSC_SZ);
            wb_dsc_base = c2h_ring_base(int'(wq), wq_dsc_sz);
            wb_exp      = wb_dsc_base + (longint'(ring_entries) - 1) * wq_dsc_sz;
            if (test_ref == null || !test_ref.host_mem.exists(int'(wb_exp + 2))) begin
              `uvm_error("DMA_SCOREBOARD",
                $sformatf("C2H WB status MISSING: qid=%0d host_mem[0x%0h] empty -- WB never landed at expected address",
                          wq, wb_exp))
              wb_sts_pass = 0;
            end else begin
              hm_cidx = {test_ref.host_mem[int'(wb_exp + 3)], test_ref.host_mem[int'(wb_exp + 2)]};
              hm_pidx = {test_ref.host_mem[int'(wb_exp + 5)], test_ref.host_mem[int'(wb_exp + 4)]};
              if (hm_pidx != wb_exp_pidx) begin
                `uvm_error("DMA_SCOREBOARD",
                  $sformatf("C2H WB status PIDX MISMATCH: qid=%0d host_mem[0x%0h] pidx=0x%04h exp=0x%04h",
                            wq, wb_exp, hm_pidx, wb_exp_pidx))
                wb_sts_pass = 0;
              // CIDX check: after all DMA rounds complete, CIDX must equal PIDX.
              end else if (hm_cidx != wb_exp_pidx) begin
                `uvm_error("DMA_SCOREBOARD",
                  $sformatf("C2H WB status CIDX MISMATCH: qid=%0d host_mem[0x%0h] cidx=0x%04h exp=0x%04h did_complete=%0d",
                            wq, wb_exp, hm_cidx, wb_exp_pidx, wq_done))
                wb_sts_pass = 0;
              end else
                `uvm_info("DMA_SCOREBOARD",
                  $sformatf("C2H WB status PASS: qid=%0d host_mem[0x%0h] pidx=0x%04h cidx=0x%04h did_complete=%0d",
                            wq, wb_exp, hm_pidx, hm_cidx, wq_done), UVM_NONE)
            end
          end while (c2h_bytes.next(wq));
        end
      end
      if (wb_sts_pass && (h2c_bytes.size() + c2h_bytes.size() > 0))
        `uvm_info("DMA_SCOREBOARD",
          "WB status PIDX/CIDX PASS: all queues verified via host_mem explicit readback", UVM_NONE)
    end

    // Completion (CMPT) ring entries of the C2H-ST queues: every data entry
    // checked in check_cmpt_entry(); one entry per C2H packet must have been
    // written for every registered queue that moved data.
    if (cmpt_ring_base.size() > 0) begin
      int unsigned n_short = 0;
      foreach (cmpt_ring_base[q])
        if (c2h_bytes.exists(q) && cmpt_entry_cnt[q] == 0) begin
          n_short++;
          `uvm_error("CMPT_ENTRY", $sformatf(
            "qid %0d moved %0d C2H bytes but no completion entry was written to its ring", q, c2h_bytes[q]))
        end
      if (cmpt_entry_err == 0 && n_short == 0)
        `uvm_info("DMA_SCOREBOARD", $sformatf(
          "CMPT entries PASS: %0d entries in driver standard format (desc_used, length, colour) over %0d rings, %0d status writes",
          cmpt_entry_ok, cmpt_ring_base.size(), cmpt_status_wr), UVM_NONE)
      else
        `uvm_error("DMA_SCOREBOARD", $sformatf(
          "CMPT entries FAIL: %0d bad entries, %0d good, %0d queues with data but no entry",
          cmpt_entry_err, cmpt_entry_ok, n_short))
    end

    // Condition 4: MSI-X MWr received for every completed queue when irq_en=1
    begin
      int exp_h2c, exp_c2h, poll_h2c, poll_c2h;
      exp_h2c = 0; exp_c2h = 0; poll_h2c = 0; poll_c2h = 0;
      // Count only the queues that are expected to interrupt. A POLLED queue
      // completes via the host-side byte-count scoreboard, which does not depend
      // on MSI-X, so counting it here would demand an interrupt that must not come.
      foreach (h2c_trfr_done[q]) if (qid_irq_en(q)) exp_h2c++; else poll_h2c++;
      foreach (c2h_trfr_done[q]) if (qid_irq_en(q)) exp_c2h++; else poll_c2h++;

      if (exp_h2c == 0 && exp_c2h == 0) begin
        `uvm_info("DMA_SCOREBOARD",
          $sformatf("MSI-X check SKIPPED: no interrupting queues (irq_en=%0b polled H2C=%0d C2H=%0d)",
                    irq_en, poll_h2c, poll_c2h), UVM_NONE)
      end else begin
        // Multi-round dispatch (PIDX > DSC_FETCH_MAX_QID) generates multiple
        // MSI-X TLPs per QID.  Therefore the count
        // can exceed the number of completed queues.  Use >= instead of ==.
        if (h2c_msix_cnt >= exp_h2c && c2h_msix_cnt >= exp_c2h)
          `uvm_info("DMA_SCOREBOARD",
            $sformatf("MSI-X PASS: H2C=%0d/>=%0d  C2H=%0d/>=%0d  (polled H2C=%0d C2H=%0d)",
                       h2c_msix_cnt, exp_h2c, c2h_msix_cnt, exp_c2h, poll_h2c, poll_c2h), UVM_NONE)
        else
          `uvm_error("DMA_SCOREBOARD",
            $sformatf("MSI-X FAIL: H2C=%0d/>=%0d  C2H=%0d/>=%0d  (polled H2C=%0d C2H=%0d)",
                       h2c_msix_cnt, exp_h2c, c2h_msix_cnt, exp_c2h, poll_h2c, poll_c2h))
      end

      // MIXED-MODE UPPER BOUND. The MSI-X MWr address encodes only a DIRECTION
      // vector (1=H2C, 2=C2H) -- it does NOT carry a qid, so "which queue
      // interrupted" is not answerable here. What IS answerable: if some queues
      // are polled, the interrupt count must not look like every queue fired.
      // A per-qid form of this check needs the requesting qid, which is not
      // observed in this testbench.
      if (poll_h2c > 0 && h2c_msix_cnt >= (exp_h2c + poll_h2c))
        `uvm_error("DMA_SCOREBOARD",
          $sformatf("MSI-X POLLED-QUEUE LEAK (H2C): %0d MSI-X for %0d interrupting queues with %0d polled - a polled queue appears to have raised an interrupt",
                     h2c_msix_cnt, exp_h2c, poll_h2c))
      if (poll_c2h > 0 && c2h_msix_cnt >= (exp_c2h + poll_c2h))
        `uvm_error("DMA_SCOREBOARD",
          $sformatf("MSI-X POLLED-QUEUE LEAK (C2H): %0d MSI-X for %0d interrupting queues with %0d polled - a polled queue appears to have raised an interrupt",
                     c2h_msix_cnt, exp_c2h, poll_c2h))
    end

    // Condition 4b: per-queue MSI-X attribution needs internal monitors that are
    // not part of this testbench.
    `uvm_info("DMA_SCOREBOARD",
      "MSI-X QID check NOT OBSERVED: per-queue interrupt attribution is not monitored in this testbench", UVM_NONE)

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
                    qid, c2h_bytes[qid], c2h_cnt[qid],
                    (c2h_pkt_bytes != 0) ? c2h_exp_bytes(qid) : exp_bytes, status);
        end while (c2h_bytes.next(qid));
      end

      if (c2h_err_cnt > 0)
        $fdisplay(log_fd, "#   C2H data integrity : FAIL  total_mismatches=%0d", c2h_err_cnt);
      else if (c2h_trfr_done.size() > 0)
        $fdisplay(log_fd, "#   C2H data integrity : PASS  all %0d queue(s) clean",
                  c2h_trfr_done.size());

      if (h2c_integrity_err_cnt > 0)
        $fdisplay(log_fd, "#   H2C data integrity : FAIL  total_mismatches=%0d", h2c_integrity_err_cnt);
      else if (h2c_user_pkt_cnt > 0)
        $fdisplay(log_fd, "#   H2C data integrity : PASS  all %0d queue(s) clean (%0d pkts)",
                  h2c_trfr_done.size(), h2c_user_pkt_cnt);
      else if (dma_st && h2c_host_done.size() > 0)
        $fdisplay(log_fd, "#   H2C data integrity : FAIL  0 packets on PL-side AXI-Stream (ST mode, %0d host-side done)",
                  h2c_host_done.size());

      // Condition 3: WB (writeback-engine completions not monitored)
      if (qid_cmp_cnt > 0)
        $fdisplay(log_fd, "#   WB packets        : NOT OBSERVED  qid_cmp_cnt=%0d", qid_cmp_cnt);

      // Condition 4: MSI-X
      if (irq_en)
        $fdisplay(log_fd, "#   MSI-X MWr         : %s  H2C=%0d/%0d  C2H=%0d/%0d",
                  (h2c_msix_cnt == h2c_trfr_done.size() && c2h_msix_cnt == c2h_trfr_done.size())
                    ? "PASS" : "FAIL",
                  h2c_msix_cnt, h2c_trfr_done.size(),
                  c2h_msix_cnt, c2h_trfr_done.size());
      else
        $fdisplay(log_fd, "#   MSI-X MWr         : SKIPPED (irq_en=0)");

      $fdisplay(log_fd, "# ===================================================================================================================");
      $fflush(log_fd);
    end

    // -- Performance summary (console + log) -----------------------------------
    begin
      time total_dur;
      real total_bytes_all;
      real gbps;
      total_dur = dma_last_done_time - dma_first_tlp_time;
      total_bytes_all = 0;

      `uvm_info("DMA_PERF", "=== Per-QID Performance ===", UVM_NONE)
      if (log_fd != 0)
        $fdisplay(log_fd, "\n# === PERFORMANCE REPORT ===\n# %-6s  %-5s  %12s  %10s  %10s  %10s  %10s",
                  "qid", "dir", "bytes", "TLPs", "first(ns)", "last(ns)", "dur(ns)");

      // H2C per-QID
      if (h2c_bytes.first(qid)) begin
        do begin
          time dur;
          real qid_gbps;
          dur = h2c_last_tlp_time[qid] - h2c_first_tlp_time[qid];
          qid_gbps = (dur > 0) ? (real'(h2c_bytes[qid]) * 8.0) / (real'(dur) / 1000.0) : 0;
          total_bytes_all += real'(h2c_bytes[qid]);
          `uvm_info("DMA_PERF", $sformatf("  qid=%-4d H2C  %8d B  %4d TLPs  %0t-%0t  dur=%0t  %.2f Gbps",
            qid, h2c_bytes[qid], h2c_cnt[qid],
            h2c_first_tlp_time[qid], h2c_last_tlp_time[qid], dur, qid_gbps), UVM_NONE)
          if (log_fd != 0)
            $fdisplay(log_fd, "#   %-4d   H2C  %12d  %10d  %10d  %10d  %10d",
              qid, h2c_bytes[qid], h2c_cnt[qid],
              h2c_first_tlp_time[qid]/1000, h2c_last_tlp_time[qid]/1000, dur/1000);
        end while (h2c_bytes.next(qid));
      end

      // C2H per-QID
      if (c2h_bytes.first(qid)) begin
        do begin
          time dur;
          real qid_gbps;
          dur = c2h_last_tlp_time[qid] - c2h_first_tlp_time[qid];
          qid_gbps = (dur > 0) ? (real'(c2h_bytes[qid]) * 8.0) / (real'(dur) / 1000.0) : 0;
          total_bytes_all += real'(c2h_bytes[qid]);
          `uvm_info("DMA_PERF", $sformatf("  qid=%-4d C2H  %8d B  %4d TLPs  %0t-%0t  dur=%0t  %.2f Gbps",
            qid, c2h_bytes[qid], c2h_cnt[qid],
            c2h_first_tlp_time[qid], c2h_last_tlp_time[qid], dur, qid_gbps), UVM_NONE)
          if (log_fd != 0)
            $fdisplay(log_fd, "#   %-4d   C2H  %12d  %10d  %10d  %10d  %10d",
              qid, c2h_bytes[qid], c2h_cnt[qid],
              c2h_first_tlp_time[qid]/1000, c2h_last_tlp_time[qid]/1000, dur/1000);
        end while (c2h_bytes.next(qid));
      end

      // Aggregate
      gbps = (total_dur > 0) ? (total_bytes_all * 8.0) / (real'(total_dur) / 1000.0) : 0;
      `uvm_info("DMA_PERF", $sformatf("  AGGREGATE: %.0f B in %0t ns = %.2f Gbps  (%0d QIDs)",
        total_bytes_all, total_dur, gbps, qid_cmp_cnt), UVM_NONE)
      if (log_fd != 0) begin
        $fdisplay(log_fd, "# ---");
        $fdisplay(log_fd, "# AGGREGATE: %.0f B in %0d ns = %.2f Gbps  (%0d QIDs)",
          total_bytes_all, total_dur/1000, gbps, qid_cmp_cnt);
        $fdisplay(log_fd, "# ===================================================================================================================");
        $fflush(log_fd);
      end
    end
  endfunction

endclass
