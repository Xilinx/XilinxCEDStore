// Simulation-only AXI4 insertion point for the CXL datapaths. In this file:
//
//   axi4_sim_pkg          types for commands, waits and per-command summaries
//   axi4_sim_if           command queues, the engines that run them onto AXI,
//                         and monitors that record how the bridge responds
//   bind_axi_tg_override  bound into each custom_axi_tg_ip by
//                         byoc_int_insert.sv. It owns an axi4_sim_if and, while
//                         axi4_sim_if.force_en is set, forces the interface's
//                         AXI signals onto the traffic generator's m_axi_*
//                         outputs, which drive the pl_axi_cpi_bridge_<N>
//                         s_axi port. Clearing force_en releases them and the
//                         traffic generator resumes control. The bridge's
//                         responses are always mirrored onto the interface.

//----------------------------------------------------------------------------
// Types
//----------------------------------------------------------------------------

// Commands cover only what this CED's bridge supports: single-beat, 64-byte,
// 64-byte-aligned transfers on a 512-bit bus with 2-bit IDs. The fixed AXI
// fields (len, size, burst, lock, cache, prot, wlast) are tied off inside
// axi4_sim_if, and the user sidebands are not used.
package axi4_sim_pkg;

  // Read command: one AR beat, one R beat back
  typedef struct {
    bit [47:0]   addr;       // 64B aligned
    bit [ 1:0]   id;
    int unsigned pre_delay;  // idle cycles before ARVALID is presented
  } axi_rd_cmd_t;

  // Write command: one AW beat and one W beat. A strb that is not all ones
  // becomes a partial write.
  typedef struct {
    bit [ 47:0]  addr;       // 64B aligned
    bit [  1:0]  id;
    bit [511:0]  data;
    bit [ 63:0]  strb;
    int unsigned pre_delay;  // idle cycles before AWVALID is presented
    int unsigned aw_w_delay; // cycles from AWVALID to WVALID assertion
  } axi_wr_cmd_t;

  // A wait blocks the queue it was pushed into (reads and writes have
  // separate queues) until its condition is met. Commands are numbered
  // 0,1,2... in the order they were pushed to their own queue (across all
  // IDs); waits do not consume a number. A command that has run more than
  // once is judged by its most recent run.
  typedef enum {
    AXI_WAIT_ALL_WR_DONE,  // every write pushed before the wait is done
    AXI_WAIT_ALL_RD_DONE,  // every read pushed before the wait is done
    AXI_WAIT_IND_WR_DONE,  // write #num has received its B response
    AXI_WAIT_IND_RD_DONE,  // read #num has received its R response
    AXI_WAIT_OTHER_ISSUED  // command #num of the opposite queue is issued
  } axi_wait_e;

  typedef struct {
    axi_wait_e   kind;
    int unsigned num;      // command waited on (IND_* and OTHER_ISSUED)
    int unsigned n_cmds;   // commands pushed before the wait (ALL_*)
    bit          src_wr;   // wait sits in the write queue
  } axi_wait_cmd_t;

  // Which queue(s) start(), stop() and the clear functions apply to
  typedef enum {
    AXI_Q_BOTH,
    AXI_Q_RD,
    AXI_Q_WR
  } axi_q_e;

  // How far start() runs a queue, from wherever its pointer is
  typedef enum {
    AXI_RUN_ALL,    // to the end of the queue, then stop
    AXI_RUN_LOOP,   // to the end, back to the top, and so on until stop()
    AXI_RUN_UNTIL   // through command #num, then stop
  } axi_run_e;

  // Queue entries: either a command or a wait
  typedef struct {
    bit            is_wait;
    int unsigned   num;     // command number (commands only)
    axi_rd_cmd_t   cmd;
    axi_wait_cmd_t wt;
  } axi_rd_qe_t;

  typedef struct {
    bit            is_wait;
    int unsigned   num;     // command number (commands only)
    axi_wr_cmd_t   cmd;
    axi_wait_cmd_t wt;
  } axi_wr_qe_t;

  // How far the most recent run of a command has got
  typedef enum {
    AXI_CMD_PENDING,  // not issued yet, or still being issued
    AXI_CMD_ISSUED,   // sent and accepted; response not back yet
    AXI_CMD_DONE      // response received
  } axi_cmd_state_e;

  // Summaries: one is created each time a command is issued, in one queue
  // per ID. Responses may return out of order between IDs but are in order
  // within an ID, so each ID's queue is completed front to back. A time is
  // only meaningful once its flag has been set.
  typedef struct {
    int unsigned num;           // command number
    int unsigned iter;          // 0 the first time the command ran
    bit [ 47:0]  addr;
    bit [  1:0]  id;
    time         arvalid_time;  // ARVALID first asserted
    time         ar_acc_time;   // AR accepted (ARVALID && ARREADY)
    time         r_acc_time;    // R accepted (RVALID && RREADY)
    bit          issued;        // AR accepted
    bit          done;          // R received
    bit [511:0]  rdata;
    bit [  1:0]  rresp;
  } axi_rd_sum_t;

  typedef struct {
    int unsigned num;           // command number
    int unsigned iter;          // 0 the first time the command ran
    bit [ 47:0]  addr;
    bit [  1:0]  id;
    bit [511:0]  wdata;
    bit [ 63:0]  wstrb;
    time         awvalid_time;  // AWVALID first asserted
    time         aw_acc_time;   // AW accepted
    time         wvalid_time;   // WVALID first asserted
    time         w_acc_time;    // W accepted
    time         b_acc_time;    // B accepted (BVALID && BREADY)
    bit          issued;        // both AW and W accepted
    bit          done;          // B received
    bit [  1:0]  bresp;
  } axi_wr_sum_t;

endpackage

//----------------------------------------------------------------------------
// Interface
//----------------------------------------------------------------------------

// Hardcoded to the CED's AXI4 widths (ID=2, ADDR=48, DATA=512).
//
// Usage: queue commands with push_rd()/push_wr() (and push_*_wait()), then
// call start(). Nothing is driven until a queue is started. start() also
// sets force_en, which makes bind_axi_tg_override force the engines' AXI
// signals onto the bridge in place of the traffic generator's; clear
// force_en yourself (after wait_idle()) to hand the bus back.
//   start()                            run both queues to the end
//   start(AXI_Q_RD)                    run only the read queue
//   start(AXI_Q_WR, AXI_RUN_LOOP)      loop the write queue until stop()
//   start(AXI_Q_WR, AXI_RUN_UNTIL, n)  run through write command #n, then stop
//
// Commands stay in their queue after they run. Each queue has a pointer to
// the next entry to run: start() continues from it, stop() leaves it where
// it is (the command in flight finishes), and a queue that reaches its end
// stops until more is pushed or rewind() sends the pointer back to the top.
// Every time a command is issued a fresh summary is appended. clear_q()
// empties the queues, and clear_summary() empties the summaries.
interface axi4_sim_if (
  input aclk,
  input aresetn
);

  timeunit      1ns;
  timeprecision 1ps;

  import axi4_sim_pkg::*;

  localparam int NUM_IDS = 4;   // 2-bit AXI ID

  //--------------------------------------------------------------------------
  // AXI signals
  //--------------------------------------------------------------------------
  // `bit` signals are driven by this interface and can never be X. `logic`
  // signals come from the bridge, so an X from it stays visible.

  // Set to take over the bridge's AXI inputs from the traffic generator
  bit           force_en;

  // Write address
  bit   [ 47:0] awaddr;
  bit   [  1:0] awid;
  bit   [  2:0] awprot;
  bit   [  1:0] awburst;
  bit   [  2:0] awsize;
  bit   [  3:0] awcache;
  bit   [  7:0] awlen;
  bit           awlock;
  bit           awvalid;
  logic         awready;
  // Write data
  bit   [ 32:0] wuser;
  bit   [511:0] wdata;
  bit   [ 63:0] wstrb;
  bit           wlast;
  bit           wvalid;
  logic         wready;
  // Write response (always ready for it)
  logic [  1:0] buser;
  logic         bvalid;
  bit           bready  = 1'b1;
  logic [  1:0] bid;
  logic [  1:0] bresp;
  // Read address
  bit   [ 34:0] aruser;
  bit   [ 47:0] araddr;
  bit   [  1:0] arid;
  bit   [  2:0] arprot;
  bit   [  1:0] arburst;
  bit   [  2:0] arsize;
  bit   [  3:0] arcache;
  bit   [  7:0] arlen;
  bit           arlock;
  bit           arvalid;
  logic         arready;
  // Read data (always ready for it)
  logic [ 33:0] ruser;
  logic [  1:0] rid;
  logic [511:0] rdata;
  logic [  1:0] rresp;
  logic         rvalid;
  logic         rlast;
  bit           rready  = 1'b1;

  // Fixed AXI fields: single beat, 64B, no narrow/unaligned transfers.
  // The bridge ignores prot/cache/lock, and none of the user sidebands are
  // enabled in this CED.
  assign awlen   = 8'h00;
  assign awsize  = 3'b110;
  assign awburst = 2'b00;
  assign wlast   = 1'b1;
  assign arlen   = 8'h00;
  assign arsize  = 3'b110;
  assign arburst = 2'b00;

  //--------------------------------------------------------------------------
  // State
  //--------------------------------------------------------------------------

  // Command queues. Commands stay queued after they run: each engine walks
  // its queue with a pointer, so the same list can be run again (rewind(),
  // or AXI_RUN_LOOP). clear_q() empties a queue.
  axi_rd_qe_t  rd_q[$];
  axi_wr_qe_t  wr_q[$];
  int unsigned rd_ptr, wr_ptr;       // next entry each engine will run

  // Next command number, i.e. how many commands have been pushed. Numbers
  // are never reused, even after clear_q().
  int unsigned rd_cmd_cnt, wr_cmd_cnt;

  // One summary is appended, to its ID's queue, every time a command is
  // issued, so a command that runs again gets a fresh one. clear_summary()
  // empties them.
  axi_rd_sum_t rd_sum_q[NUM_IDS][$];
  axi_wr_sum_t wr_sum_q[NUM_IDS][$];

  // Where a command's summaries are, indexed [command number][run], run 0
  // being the first
  typedef struct { bit [1:0] id; int unsigned idx; } sum_loc_t;
  sum_loc_t    rd_sum_loc[$][$];
  sum_loc_t    wr_sum_loc[$][$];

  // How many times each command has been issued. Unlike the summaries this
  // survives clear_summary(), so a cleared command is not mistaken for one
  // that never ran.
  int unsigned rd_issue_cnt[$];
  int unsigned wr_issue_cnt[$];

  // Per ID, the next summary awaiting its response. Every summary before
  // it is done.
  int unsigned rd_rsp_ptr[NUM_IDS];
  int unsigned wr_rsp_ptr[NUM_IDS];

  // Run control (see start()/stop())
  bit          rd_run, wr_run;       // started
  bit          rd_busy, wr_busy;     // an entry was taken and is unfinished
  axi_run_e    rd_mode, wr_mode;
  int unsigned rd_until, wr_until;   // AXI_RUN_UNTIL: command to stop after

  //--------------------------------------------------------------------------
  // Pushing commands and waits
  //--------------------------------------------------------------------------

  // Each push_rd()/push_wr() returns the command's number, or -1 if the
  // command was rejected
  function automatic int push_rd(axi_rd_cmd_t cmd);
    axi_rd_qe_t qe;
    sum_loc_t   no_runs[$];
    if (cmd.addr[5:0] != '0) begin
      $error("%m: read addr=0x%0h is not 64B aligned", cmd.addr);
      return -1;
    end
    qe.is_wait = 1'b0;
    qe.num     = rd_cmd_cnt;
    qe.cmd     = cmd;
    rd_q.push_back(qe);
    rd_sum_loc.push_back(no_runs);
    rd_issue_cnt.push_back(0);
    rd_cmd_cnt++;
    return qe.num;
  endfunction

  function automatic int push_wr(axi_wr_cmd_t cmd);
    axi_wr_qe_t qe;
    sum_loc_t   no_runs[$];
    if (cmd.addr[5:0] != '0) begin
      $error("%m: write addr=0x%0h is not 64B aligned", cmd.addr);
      return -1;
    end
    qe.is_wait = 1'b0;
    qe.num     = wr_cmd_cnt;
    qe.cmd     = cmd;
    wr_q.push_back(qe);
    wr_sum_loc.push_back(no_runs);
    wr_issue_cnt.push_back(0);
    wr_cmd_cnt++;
    return qe.num;
  endfunction

  // Fills in a wait, returning 0 if it is invalid: a command it refers to
  // must already have been pushed
  function automatic bit build_wait(bit src_wr, axi_wait_e kind,
                                    int unsigned num,
                                    ref axi_wait_cmd_t wt);
    int unsigned pushed;   // commands in the queue that `num` refers to
    wt.kind   = kind;
    wt.num    = num;
    wt.src_wr = src_wr;
    wt.n_cmds = '0;
    case (kind)
      AXI_WAIT_ALL_WR_DONE  : begin wt.n_cmds = wr_cmd_cnt; return 1'b1; end
      AXI_WAIT_ALL_RD_DONE  : begin wt.n_cmds = rd_cmd_cnt; return 1'b1; end
      AXI_WAIT_IND_WR_DONE  : pushed = wr_cmd_cnt;
      AXI_WAIT_IND_RD_DONE  : pushed = rd_cmd_cnt;
      AXI_WAIT_OTHER_ISSUED : pushed = src_wr ? rd_cmd_cnt : wr_cmd_cnt;
    endcase
    if (num >= pushed) begin
      $error("%m: wait on command #%0d, but only %0d are pushed there",
             num, pushed);
      return 1'b0;
    end
    return 1'b1;
  endfunction

  function automatic bit push_wr_wait(axi_wait_e kind, int unsigned num = 0);
    axi_wr_qe_t qe;
    if (!build_wait(1'b1, kind, num, qe.wt))
      return 1'b0;
    qe.is_wait = 1'b1;
    wr_q.push_back(qe);
    return 1'b1;
  endfunction

  function automatic bit push_rd_wait(axi_wait_e kind, int unsigned num = 0);
    axi_rd_qe_t qe;
    if (!build_wait(1'b0, kind, num, qe.wt))
      return 1'b0;
    qe.is_wait = 1'b1;
    rd_q.push_back(qe);
    return 1'b1;
  endfunction

  //--------------------------------------------------------------------------
  // Evaluating waits
  //--------------------------------------------------------------------------

  // Progress of a command's most recent run. A command that was issued but
  // whose summaries have since been cleared counts as done, because
  // clear_summary() only runs with nothing outstanding.
  function automatic axi_cmd_state_e rd_cmd_state(int unsigned num);
    int unsigned runs = rd_sum_loc[num].size();
    sum_loc_t    lc;
    if (rd_issue_cnt[num] == 0) return AXI_CMD_PENDING;
    if (runs == 0)              return AXI_CMD_DONE;
    lc = rd_sum_loc[num][runs-1];
    if (rd_sum_q[lc.id][lc.idx].done)   return AXI_CMD_DONE;
    if (rd_sum_q[lc.id][lc.idx].issued) return AXI_CMD_ISSUED;
    return AXI_CMD_PENDING;
  endfunction

  function automatic axi_cmd_state_e wr_cmd_state(int unsigned num);
    int unsigned runs = wr_sum_loc[num].size();
    sum_loc_t    lc;
    if (wr_issue_cnt[num] == 0) return AXI_CMD_PENDING;
    if (runs == 0)              return AXI_CMD_DONE;
    lc = wr_sum_loc[num][runs-1];
    if (wr_sum_q[lc.id][lc.idx].done)   return AXI_CMD_DONE;
    if (wr_sum_q[lc.id][lc.idx].issued) return AXI_CMD_ISSUED;
    return AXI_CMD_PENDING;
  endfunction

  function automatic bit wait_met(axi_wait_cmd_t wt);
    axi_cmd_state_e other;
    case (wt.kind)
      AXI_WAIT_ALL_WR_DONE : begin
        for (int unsigned c = 0; c < wt.n_cmds; c++)
          if (wr_cmd_state(c) != AXI_CMD_DONE) return 1'b0;
        return 1'b1;
      end
      AXI_WAIT_ALL_RD_DONE : begin
        for (int unsigned c = 0; c < wt.n_cmds; c++)
          if (rd_cmd_state(c) != AXI_CMD_DONE) return 1'b0;
        return 1'b1;
      end
      AXI_WAIT_IND_WR_DONE : return wr_cmd_state(wt.num) == AXI_CMD_DONE;
      AXI_WAIT_IND_RD_DONE : return rd_cmd_state(wt.num) == AXI_CMD_DONE;
      AXI_WAIT_OTHER_ISSUED : begin
        other = wt.src_wr ? rd_cmd_state(wt.num) : wr_cmd_state(wt.num);
        return other != AXI_CMD_PENDING;
      end
    endcase
    return 1'b1;
  endfunction

  //--------------------------------------------------------------------------
  // Run control
  //--------------------------------------------------------------------------

  // Does `q` include the read / write queue?
  function automatic bit sel_rd(axi_q_e q);
    return q != AXI_Q_WR;
  endfunction

  function automatic bit sel_wr(axi_q_e q);
    return q != AXI_Q_RD;
  endfunction

  // Has a selected queue been started (and not yet stopped or run dry)?
  function automatic bit started(axi_q_e q);
    return (sel_rd(q) && rd_run) || (sel_wr(q) && wr_run);
  endfunction

  // Is a selected queue started, or still finishing a command?
  function automatic bit running(axi_q_e q);
    return (sel_rd(q) && (rd_run || rd_busy)) ||
           (sel_wr(q) && (wr_run || wr_busy));
  endfunction

  function automatic bit has_cmd_rd();
    foreach (rd_q[i]) if (!rd_q[i].is_wait) return 1'b1;
    return 1'b0;
  endfunction

  function automatic bit has_cmd_wr();
    foreach (wr_q[i]) if (!wr_q[i].is_wait) return 1'b1;
    return 1'b0;
  endfunction

  // Is command `num` queued at or after the queue's pointer?
  function automatic bit rd_queued_ahead(int unsigned num);
    for (int i = rd_ptr; i < rd_q.size(); i++)
      if (!rd_q[i].is_wait && rd_q[i].num == num) return 1'b1;
    return 1'b0;
  endfunction

  function automatic bit wr_queued_ahead(int unsigned num);
    for (int i = wr_ptr; i < wr_q.size(); i++)
      if (!wr_q[i].is_wait && wr_q[i].num == num) return 1'b1;
    return 1'b0;
  endfunction

  // Releases the selected queue(s) from their pointers and sets force_en.
  // Returns 0 (and starts nothing) if the request is invalid:
  //  - a selected queue is already running
  //  - AXI_RUN_UNTIL with AXI_Q_BOTH, or with a command that is not queued
  //    at or after the pointer
  //  - AXI_RUN_LOOP on a queue with no commands
  // Both queues are released in the same time step, so they start on the
  // same clock edge.
  function automatic bit start(axi_q_e q = AXI_Q_BOTH,
                               axi_run_e run = AXI_RUN_ALL,
                               int unsigned num = 0);
    if (run == AXI_RUN_UNTIL && q == AXI_Q_BOTH) begin
      $error("%m: AXI_RUN_UNTIL needs a single queue (AXI_Q_RD or AXI_Q_WR)");
      return 1'b0;
    end
    if (started(q)) begin
      $error("%m: queue already running; stop() it first");
      return 1'b0;
    end
    if (run == AXI_RUN_UNTIL &&
        !(sel_rd(q) ? rd_queued_ahead(num) : wr_queued_ahead(num))) begin
      $error("%m: command #%0d is not queued at or after the pointer", num);
      return 1'b0;
    end
    if (run == AXI_RUN_LOOP &&
        ((sel_rd(q) && !has_cmd_rd()) || (sel_wr(q) && !has_cmd_wr()))) begin
      $error("%m: loop needs at least one queued command");
      return 1'b0;
    end
    force_en = 1'b1;
    if (sel_rd(q)) begin
      rd_mode  = run;
      rd_until = num;
      rd_run   = 1'b1;
    end
    if (sel_wr(q)) begin
      wr_mode  = run;
      wr_until = num;
      wr_run   = 1'b1;
    end
    return 1'b1;
  endfunction

  // The command in flight finishes; the pointer stays where it is
  function automatic void stop(axi_q_e q = AXI_Q_BOTH);
    if (sel_rd(q)) rd_run = 1'b0;
    if (sel_wr(q)) wr_run = 1'b0;
  endfunction

  // Sends the pointer back to the top so the queue can be run again.
  // Returns 0 if a selected queue is running or still finishing a command.
  function automatic bit rewind(axi_q_e q = AXI_Q_BOTH);
    if (running(q)) begin
      $error("%m: cannot rewind a running queue");
      return 1'b0;
    end
    if (sel_rd(q)) rd_ptr = 0;
    if (sel_wr(q)) wr_ptr = 0;
    return 1'b1;
  endfunction

  // Has any issued command not had its response yet?
  function automatic bit rd_outstanding();
    foreach (rd_sum_q[i])
      if (rd_rsp_ptr[i] != rd_sum_q[i].size()) return 1'b1;
    return 1'b0;
  endfunction

  function automatic bit wr_outstanding();
    foreach (wr_sum_q[i])
      if (wr_rsp_ptr[i] != wr_sum_q[i].size()) return 1'b1;
    return 1'b0;
  endfunction

  // Block until nothing is running or in flight and every issued command
  // has completed. Queues that have not been started do not hold this up.
  task automatic wait_idle();
    while (running(AXI_Q_BOTH) || rd_outstanding() || wr_outstanding())
      @(posedge aclk);
  endtask

  //--------------------------------------------------------------------------
  // Clearing
  //--------------------------------------------------------------------------

  // Empties the queue(s) and sends the pointer to the top. Command numbers
  // keep counting. Returns 0 if a selected queue is running.
  function automatic bit clear_q(axi_q_e q = AXI_Q_BOTH);
    if (running(q)) begin
      $error("%m: cannot clear a running queue");
      return 1'b0;
    end
    if (sel_rd(q)) begin
      rd_q.delete();
      rd_ptr = 0;
    end
    if (sel_wr(q)) begin
      wr_q.delete();
      wr_ptr = 0;
    end
    return 1'b1;
  endfunction

  // Empties the summaries of the selected direction(s). Returns 0 if that
  // queue is running or any of its responses is still outstanding. Waits keep
  // working: a command that was issued before the clear counts as complete.
  function automatic bit clear_summary(axi_q_e q = AXI_Q_BOTH);
    if (running(q) || (sel_rd(q) && rd_outstanding()) ||
                      (sel_wr(q) && wr_outstanding())) begin
      $error("%m: cannot clear summaries while running or outstanding");
      return 1'b0;
    end
    if (sel_rd(q)) begin
      foreach (rd_sum_q[i]) begin
        rd_sum_q[i].delete();
        rd_rsp_ptr[i] = 0;
      end
      foreach (rd_sum_loc[c]) rd_sum_loc[c].delete();
    end
    if (sel_wr(q)) begin
      foreach (wr_sum_q[i]) begin
        wr_sum_q[i].delete();
        wr_rsp_ptr[i] = 0;
      end
      foreach (wr_sum_loc[c]) wr_sum_loc[c].delete();
    end
    return 1'b1;
  endfunction

  //--------------------------------------------------------------------------
  // Engines
  //--------------------------------------------------------------------------
  // Each engine takes entries from its queue in order, while started. It
  // drives its AXI channel(s) with nonblocking assignments on clock edges
  // and records the edge on which each VALID was first presented and the
  // edge on which it was accepted.

  task automatic clk_wait(int unsigned n);
    repeat (n) @(posedge aclk);
  endtask

  // Takes the entry at the read/write pointer for the engine and advances the
  // pointer. At the end of the queue the engine stops, or wraps to the top
  // if it is looping. Returns 0 when there is nothing to run.
  function automatic bit rd_take(output axi_rd_qe_t qe);
    if (rd_ptr >= rd_q.size()) begin
      if (rd_mode == AXI_RUN_LOOP && has_cmd_rd())
        rd_ptr = 0;
      else begin
        rd_run = 1'b0;
        return 1'b0;
      end
    end
    rd_busy = 1'b1;
    qe      = rd_q[rd_ptr];
    rd_ptr++;
    return 1'b1;
  endfunction

  function automatic bit wr_take(output axi_wr_qe_t qe);
    if (wr_ptr >= wr_q.size()) begin
      if (wr_mode == AXI_RUN_LOOP && has_cmd_wr())
        wr_ptr = 0;
      else begin
        wr_run = 1'b0;
        return 1'b0;
      end
    end
    wr_busy = 1'b1;
    qe      = wr_q[wr_ptr];
    wr_ptr++;
    return 1'b1;
  endfunction

  // Creates the summary for a command that is about to be issued
  function automatic sum_loc_t rd_new_summary(axi_rd_qe_t qe);
    axi_rd_sum_t sm = '{default: '0};
    sum_loc_t    lc;
    sm.num  = qe.num;
    sm.iter = rd_issue_cnt[qe.num];
    sm.addr = qe.cmd.addr;
    sm.id   = qe.cmd.id;
    lc.id   = qe.cmd.id;
    lc.idx  = rd_sum_q[qe.cmd.id].size();
    rd_sum_q[qe.cmd.id].push_back(sm);
    rd_sum_loc[qe.num].push_back(lc);
    rd_issue_cnt[qe.num]++;
    return lc;
  endfunction

  function automatic sum_loc_t wr_new_summary(axi_wr_qe_t qe);
    axi_wr_sum_t sm = '{default: '0};
    sum_loc_t    lc;
    sm.num   = qe.num;
    sm.iter  = wr_issue_cnt[qe.num];
    sm.addr  = qe.cmd.addr;
    sm.id    = qe.cmd.id;
    sm.wdata = qe.cmd.data;
    sm.wstrb = qe.cmd.strb;
    lc.id    = qe.cmd.id;
    lc.idx   = wr_sum_q[qe.cmd.id].size();
    wr_sum_q[qe.cmd.id].push_back(sm);
    wr_sum_loc[qe.num].push_back(lc);
    wr_issue_cnt[qe.num]++;
    return lc;
  endfunction

  // Read engine: presents one AR at a time and holds ARVALID until it is
  // accepted
  initial begin
    forever begin
      axi_rd_qe_t qe;
      sum_loc_t   lc;
      while (!(aresetn && rd_run)) @(posedge aclk);
      if (!rd_take(qe)) continue;
      if (qe.is_wait) begin
        while (!wait_met(qe.wt)) @(posedge aclk);
      end
      else begin
        clk_wait(qe.cmd.pre_delay);
        lc = rd_new_summary(qe);
        araddr  <= qe.cmd.addr;
        arid    <= qe.cmd.id;
        arvalid <= 1'b1;
        rd_sum_q[lc.id][lc.idx].arvalid_time = $time;
        do @(posedge aclk); while (!arready);
        arvalid <= 1'b0;
        rd_sum_q[lc.id][lc.idx].ar_acc_time = $time;
        rd_sum_q[lc.id][lc.idx].issued      = 1'b1;
        if (rd_mode == AXI_RUN_UNTIL && qe.num == rd_until)
          rd_run = 1'b0;
      end
      rd_busy = 1'b0;
    end
  end

  // Write engine: presents AW and W in parallel for each command, each held
  // until it is accepted. W is presented aw_w_delay cycles after AW; the
  // bridge cannot take W ahead of AW. The command is issued once both are
  // accepted.
  initial begin
    forever begin
      axi_wr_qe_t qe;
      sum_loc_t   lc;
      while (!(aresetn && wr_run)) @(posedge aclk);
      if (!wr_take(qe)) continue;
      if (qe.is_wait) begin
        while (!wait_met(qe.wt)) @(posedge aclk);
      end
      else begin
        clk_wait(qe.cmd.pre_delay);
        lc = wr_new_summary(qe);
        fork
          begin  // AW
            awaddr  <= qe.cmd.addr;
            awid    <= qe.cmd.id;
            awvalid <= 1'b1;
            wr_sum_q[lc.id][lc.idx].awvalid_time = $time;
            do @(posedge aclk); while (!awready);
            awvalid <= 1'b0;
            wr_sum_q[lc.id][lc.idx].aw_acc_time = $time;
          end
          begin  // W
            clk_wait(qe.cmd.aw_w_delay);
            wdata   <= qe.cmd.data;
            wstrb   <= qe.cmd.strb;
            wvalid  <= 1'b1;
            wr_sum_q[lc.id][lc.idx].wvalid_time = $time;
            do @(posedge aclk); while (!wready);
            wvalid  <= 1'b0;
            wr_sum_q[lc.id][lc.idx].w_acc_time = $time;
          end
        join
        wr_sum_q[lc.id][lc.idx].issued = 1'b1;
        if (wr_mode == AXI_RUN_UNTIL && qe.num == wr_until)
          wr_run = 1'b0;
      end
      wr_busy = 1'b0;
    end
  end

  //--------------------------------------------------------------------------
  // Response monitors
  //--------------------------------------------------------------------------
  // Responses are ordered per ID only, so a response belongs to the oldest
  // incomplete summary of its ID. Responses to the traffic generator's own
  // traffic are expected while force_en is clear and are ignored.

  // Write responses (B)
  initial begin
    forever begin
      @(posedge aclk);
      if (bvalid && bready) begin
        automatic int unsigned p = wr_rsp_ptr[bid];
        if (p >= wr_sum_q[bid].size() || !wr_sum_q[bid][p].issued) begin
          if (force_en)
            $error("%m: B response id=%0d with no matching issued write", bid);
        end
        else begin
          wr_sum_q[bid][p].b_acc_time = $time;
          wr_sum_q[bid][p].bresp      = bresp;
          wr_sum_q[bid][p].done       = 1'b1;
          wr_rsp_ptr[bid]++;
        end
      end
    end
  end

  // Read responses (R)
  initial begin
    forever begin
      @(posedge aclk);
      if (rvalid && rready) begin
        automatic int unsigned p = rd_rsp_ptr[rid];
        if (p >= rd_sum_q[rid].size() || !rd_sum_q[rid][p].issued) begin
          if (force_en)
            $error("%m: R response id=%0d with no matching issued read", rid);
        end
        else begin
          rd_sum_q[rid][p].r_acc_time = $time;
          rd_sum_q[rid][p].rdata      = rdata;
          rd_sum_q[rid][p].rresp      = rresp;
          rd_sum_q[rid][p].done       = 1'b1;
          rd_rsp_ptr[rid]++;
        end
      end
    end
  end

endinterface

//----------------------------------------------------------------------------
// Bind module
//----------------------------------------------------------------------------

// Bound into one custom_axi_tg_ip instance by byoc_int_insert.sv, which gives
// each datapath its own INST_ID. The names `custom_axi_tg_ip.<port>` below
// refer upward to the instance it is bound into.
module bind_axi_tg_override #(
 parameter INST_ID
)(
  input aclk,
  input arstn
);

  axi4_sim_if axi4 (
    .aclk   (aclk ),
    .aresetn(arstn)
  );

  // Hand the interface to UVM, keyed by instance ID. A test gets it with
  //   uvm_config_db#(virtual axi4_sim_if)::get(this, "",
  //     $sformatf("axi4_sim_vif[%0d]", id), vif);
  initial
    uvm_pkg::uvm_config_db#(virtual axi4_sim_if)::set(
      null, "*", $sformatf("axi4_sim_vif[%0d]", INST_ID), axi4);

  // Bridge responses -> interface (observe only)
  assign axi4.awready = custom_axi_tg_ip.m_axi_awready;
  assign axi4.wready  = custom_axi_tg_ip.m_axi_wready;
  assign axi4.buser   = custom_axi_tg_ip.m_axi_buser;
  assign axi4.bvalid  = custom_axi_tg_ip.m_axi_bvalid;
  assign axi4.bid     = custom_axi_tg_ip.m_axi_bid;
  assign axi4.bresp   = custom_axi_tg_ip.m_axi_bresp;
  assign axi4.arready = custom_axi_tg_ip.m_axi_arready;
  assign axi4.ruser   = custom_axi_tg_ip.m_axi_ruser;
  assign axi4.rid     = custom_axi_tg_ip.m_axi_rid;
  assign axi4.rdata   = custom_axi_tg_ip.m_axi_rdata;
  assign axi4.rresp   = custom_axi_tg_ip.m_axi_rresp;
  assign axi4.rvalid  = custom_axi_tg_ip.m_axi_rvalid;
  assign axi4.rlast   = custom_axi_tg_ip.m_axi_rlast;

  // Interface -> bridge inputs. A force with an expression on the right
  // is continuously re-evaluated, so it only needs to be applied once.
  task automatic force_outputs();
    // Write address
    force custom_axi_tg_ip.m_axi_awaddr  = axi4.awaddr;
    force custom_axi_tg_ip.m_axi_awid    = axi4.awid;
    force custom_axi_tg_ip.m_axi_awprot  = axi4.awprot;
    force custom_axi_tg_ip.m_axi_awburst = axi4.awburst;
    force custom_axi_tg_ip.m_axi_awsize  = axi4.awsize;
    force custom_axi_tg_ip.m_axi_awcache = axi4.awcache;
    force custom_axi_tg_ip.m_axi_awlen   = axi4.awlen;
    force custom_axi_tg_ip.m_axi_awlock  = axi4.awlock;
    force custom_axi_tg_ip.m_axi_awvalid = axi4.awvalid;
    // Write data
    force custom_axi_tg_ip.m_axi_wuser   = axi4.wuser;
    force custom_axi_tg_ip.m_axi_wdata   = axi4.wdata;
    force custom_axi_tg_ip.m_axi_wstrb   = axi4.wstrb;
    force custom_axi_tg_ip.m_axi_wlast   = axi4.wlast;
    force custom_axi_tg_ip.m_axi_wvalid  = axi4.wvalid;
    // Write response
    force custom_axi_tg_ip.m_axi_bready  = axi4.bready;
    // Read address
    force custom_axi_tg_ip.m_axi_aruser  = axi4.aruser;
    force custom_axi_tg_ip.m_axi_araddr  = axi4.araddr;
    force custom_axi_tg_ip.m_axi_arid    = axi4.arid;
    force custom_axi_tg_ip.m_axi_arprot  = axi4.arprot;
    force custom_axi_tg_ip.m_axi_arburst = axi4.arburst;
    force custom_axi_tg_ip.m_axi_arsize  = axi4.arsize;
    force custom_axi_tg_ip.m_axi_arcache = axi4.arcache;
    force custom_axi_tg_ip.m_axi_arlen   = axi4.arlen;
    force custom_axi_tg_ip.m_axi_arlock  = axi4.arlock;
    force custom_axi_tg_ip.m_axi_arvalid = axi4.arvalid;
    // Read data
    force custom_axi_tg_ip.m_axi_rready  = axi4.rready;
  endtask

  task automatic release_outputs();
    // Write address
    release custom_axi_tg_ip.m_axi_awaddr;
    release custom_axi_tg_ip.m_axi_awid;
    release custom_axi_tg_ip.m_axi_awprot;
    release custom_axi_tg_ip.m_axi_awburst;
    release custom_axi_tg_ip.m_axi_awsize;
    release custom_axi_tg_ip.m_axi_awcache;
    release custom_axi_tg_ip.m_axi_awlen;
    release custom_axi_tg_ip.m_axi_awlock;
    release custom_axi_tg_ip.m_axi_awvalid;
    // Write data
    release custom_axi_tg_ip.m_axi_wuser;
    release custom_axi_tg_ip.m_axi_wdata;
    release custom_axi_tg_ip.m_axi_wstrb;
    release custom_axi_tg_ip.m_axi_wlast;
    release custom_axi_tg_ip.m_axi_wvalid;
    // Write response
    release custom_axi_tg_ip.m_axi_bready;
    // Read address
    release custom_axi_tg_ip.m_axi_aruser;
    release custom_axi_tg_ip.m_axi_araddr;
    release custom_axi_tg_ip.m_axi_arid;
    release custom_axi_tg_ip.m_axi_arprot;
    release custom_axi_tg_ip.m_axi_arburst;
    release custom_axi_tg_ip.m_axi_arsize;
    release custom_axi_tg_ip.m_axi_arcache;
    release custom_axi_tg_ip.m_axi_arlen;
    release custom_axi_tg_ip.m_axi_arlock;
    release custom_axi_tg_ip.m_axi_arvalid;
    // Read data
    release custom_axi_tg_ip.m_axi_rready;
  endtask

  always @(axi4.force_en) begin
    if (axi4.force_en === 1'b1) begin
      $display("[%0t] %m: forcing AXI TG %0d outputs", $time, INST_ID);
      force_outputs();
    end
    else begin
      $display("[%0t] %m: releasing AXI TG %0d outputs", $time, INST_ID);
      release_outputs();
    end
  end

endmodule
