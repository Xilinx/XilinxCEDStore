// Per-ID command FIFOs and an eight-command completion ring.
//
// Each ID FIFO contains only commands that have accepted a request with that
// ID. AXI ordering makes its head the owner of every returning response: no
// circular search, nonzero priority encoder, or shared-head dependency exists.
// Entries remain open across temporary zero outstanding counts. issuing_done
// closes the currently issuing command on its LAST acceptance (combinational,
// like inc); req_quiesced closes an interrupted command after STOP has drained
// its offered requests. The final response can pop a closed head at the same
// edge, allowing the following cycle's response to belong to the next command.
//
// The shared ring preserves command concurrency, in-order retirement and CSR
// debug semantics. pending[x][e] records an unfinished ID-X FIFO entry for
// shared command slot e. FIFO completion clears that bit independently of
// shared retirement. Only this small completion ring has a shared head.
//
// alloc loads a NEW command; concurrent inc/issuing_done apply to the OLD
// command. Each ID entry is allocated on first acceptance, not command load.
// dec/dec_oh are registered by the dispatcher. Attribution outputs retain
// their original one-cycle latency relative to dec. Ordinals are per ID and
// command, zero based, and reset when the ID head advances.
module custom_axi_tg_ring #(
  parameter int RING_DEPTH = 8,
  parameter int NUM_IDS = 2,
  parameter int CNT_W = 13,
  localparam int PTR_W = $clog2(RING_DEPTH)
)(
  input                         clk,
  input                         rstn,
  input                         flush,
  input                         alloc,
  input        [           8:0] alloc_cmd_idx,
  output logic                  full,
  output logic                  empty,
  input                         inc,
  input        [   NUM_IDS-1:0] inc_oh,
  input                         issuing_done,
  input                         dec,
  input        [   NUM_IDS-1:0] dec_oh,
  output logic                  dec_vld,
  output logic                  dec_hit,
  output logic [           8:0] dec_cmd_idx,
  output logic [          11:0] dec_rsp_ord,
  output logic [           3:0] dec_axiid,
  input                         req_quiesced,
  output logic                  retire,
  output logic [           8:0] retire_cmd_idx,
  output logic [RING_DEPTH-1:0] vld_vec,
  output logic [           2:0] head,
  output logic [           2:0] tail,
  output logic [           3:0] count,
  output logic                  orphan_sticky,
  output logic [           3:0] orphan_axiid,
  input                         orphan_clr
);
  logic [RING_DEPTH-1:0] vld, cur_e_oh, head_oh, tail_oh;
  logic [RING_DEPTH-1:0] cmd_done, ent_busy, ent_busy_n;
  logic [8:0] cmd_idx [RING_DEPTH];
  logic [8:0] current_cmd_idx;
  logic [PTR_W-1:0] head_r, tail_r;
  logic [PTR_W:0] count_r;
  logic close_current;

  // All FIFO state is independent for each ID. One-hot pointers avoid a
  // binary decode on counter enables and on the response owner selection.
  logic [NUM_IDS-1:0] used, push, pop, hit_id;
  logic [RING_DEPTH-1:0] q_head [NUM_IDS], q_tail [NUM_IDS];
  logic [RING_DEPTH-1:0] q_current [NUM_IDS], q_vld [NUM_IDS];
  logic [RING_DEPTH-1:0] q_done [NUM_IDS], nz [NUM_IDS];
  logic [RING_DEPTH-1:0] cnt_is_one [NUM_IDS];
  logic [CNT_W-1:0] cnt [NUM_IDS][RING_DEPTH];
  logic [8:0] q_cmd_idx [NUM_IDS][RING_DEPTH];
  logic [RING_DEPTH-1:0] q_tag [NUM_IDS][RING_DEPTH];
  logic [11:0] rsp_ord [NUM_IDS];
  logic [RING_DEPTH-1:0] pending [NUM_IDS], pending_n [NUM_IDS];

  logic [RING_DEPTH-1:0] push_oh [NUM_IDS], pop_oh [NUM_IDS];
  logic [RING_DEPTH-1:0] up [NUM_IDS], dn [NUM_IDS];
  logic [RING_DEPTH-1:0] nz_n [NUM_IDS], done_n [NUM_IDS];
  logic [CNT_W-1:0] cnt_n [NUM_IDS][RING_DEPTH];
  logic [RING_DEPTH-1:0] head_tag [NUM_IDS];
  logic [8:0] head_cmd [NUM_IDS];
  logic [RING_DEPTH-1:0] sel_oh;
  logic [8:0] cmd_idx_sel;
  logic [11:0] rsp_ord_sel;
  logic [3:0] dec_axiid_c;

  assign close_current = issuing_done || req_quiesced;
  assign full = count_r == (PTR_W+1)'(RING_DEPTH);
  assign empty = count_r == '0;
  assign vld_vec = vld;
  assign head = 3'(head_r);
  assign tail = 3'(tail_r);
  assign count = 4'(count_r);
  assign retire_cmd_idx = cmd_idx[head_r];
  assign retire = (|(vld & head_oh)) && !(|(ent_busy & head_oh)) &&
                  (|(cmd_done & head_oh));

  always_comb begin
    ent_busy_n = '0;
    for (int x = 0; x < NUM_IDS; x++) begin
      push[x] = inc && inc_oh[x] && !used[x];
      push_oh[x] = push[x] ? q_tail[x] : '0;
      hit_id[x] = |(q_head[x] & q_vld[x] & nz[x]);
      up[x] = {RING_DEPTH{inc && inc_oh[x] && used[x]}} & q_current[x];
      dn[x] = {RING_DEPTH{dec && dec_oh[x] && hit_id[x]}} & q_head[x];

      for (int e = 0; e < RING_DEPTH; e++) begin
        cnt_n[x][e] = push_oh[x][e] ? CNT_W'(1)
                    : (up[x][e] == dn[x][e]) ? cnt[x][e]
                    : up[x][e] ? cnt[x][e] + CNT_W'(1)
                    : cnt[x][e] - CNT_W'(1);
        nz_n[x][e] = push_oh[x][e] ? 1'b1
                   : (up[x][e] && !dn[x][e]) ? 1'b1
                   : (!up[x][e] && dn[x][e]) ? !cnt_is_one[x][e]
                   : nz[x][e];
        done_n[x][e] = push_oh[x][e] ? close_current
                     : q_done[x][e] ||
                       (close_current && used[x] && q_current[x][e]);
      end

      // Consume the last response and advance ownership at the SAME edge.
      // Empty-but-open heads stay in place until close_current arrives.
      pop[x] = |(q_head[x] & q_vld[x] & done_n[x] & ~nz_n[x]);
      pop_oh[x] = pop[x] ? q_head[x] : '0;
      head_tag[x] = '0;
      head_cmd[x] = '0;
      for (int e = 0; e < RING_DEPTH; e++) begin
        head_tag[x] |= q_tag[x][e] & {RING_DEPTH{q_head[x][e]}};
        head_cmd[x] |= q_cmd_idx[x][e] & {9{q_head[x][e]}};
      end
      pending_n[x] = (pending[x] | (push[x] ? cur_e_oh : '0)) &
                     ~(pop[x] ? head_tag[x] : '0);
      ent_busy_n |= pending_n[x];
    end
  end

  always_comb begin
    sel_oh = '0;
    cmd_idx_sel = '0;
    rsp_ord_sel = '0;
    dec_axiid_c = '0;
    for (int x = 0; x < NUM_IDS; x++) begin
      if (dec_oh[x]) begin
        dec_axiid_c = 4'(x);
        if (hit_id[x]) begin
          sel_oh |= head_tag[x];
          cmd_idx_sel |= head_cmd[x];
          rsp_ord_sel |= rsp_ord[x];
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    if (!rstn || flush) begin
      vld <= '0;
      cmd_done <= '0;
      ent_busy <= '0;
      head_r <= '0;
      tail_r <= '0;
      head_oh <= RING_DEPTH'(1);
      tail_oh <= RING_DEPTH'(1);
      count_r <= '0;
      cur_e_oh <= '0;
      used <= '0;
      for (int x = 0; x < NUM_IDS; x++) begin
        q_head[x] <= RING_DEPTH'(1);
        q_tail[x] <= RING_DEPTH'(1);
        q_vld[x] <= '0;
        pending[x] <= '0;
        rsp_ord[x] <= '0;
      end
    end else begin
      vld <= (vld | (alloc ? tail_oh : '0)) & ~(retire ? head_oh : '0);
      cmd_done <= (cmd_done | (close_current ? cur_e_oh : '0)) &
                  ~(alloc ? tail_oh : '0);
      ent_busy <= ent_busy_n;
      if (retire) begin
        head_r <= head_r + 1'b1;
        head_oh <= {head_oh[RING_DEPTH-2:0], head_oh[RING_DEPTH-1]};
      end
      if (alloc) begin
        cmd_idx[tail_r] <= alloc_cmd_idx;
        current_cmd_idx <= alloc_cmd_idx;
        cur_e_oh <= tail_oh;
        tail_r <= tail_r + 1'b1;
        tail_oh <= {tail_oh[RING_DEPTH-2:0], tail_oh[RING_DEPTH-1]};
      end
      case ({alloc, retire})
        2'b10: count_r <= count_r + 1'b1;
        2'b01: count_r <= count_r - 1'b1;
        default: ;
      endcase
      // alloc may accompany the old command's last inc: clear has priority.
      used <= alloc ? '0 : used | push;
      for (int x = 0; x < NUM_IDS; x++) begin
        pending[x] <= pending_n[x];
        q_vld[x] <= (q_vld[x] | push_oh[x]) & ~pop_oh[x];
        q_done[x] <= done_n[x];
        nz[x] <= nz_n[x];
        if (push[x]) begin
          q_current[x] <= q_tail[x];
          q_tail[x] <= {q_tail[x][RING_DEPTH-2:0], q_tail[x][RING_DEPTH-1]};
        end
        if (pop[x]) begin
          q_head[x] <= {q_head[x][RING_DEPTH-2:0], q_head[x][RING_DEPTH-1]};
          rsp_ord[x] <= '0;
        end else if (dec && dec_oh[x] && hit_id[x])
          rsp_ord[x] <= rsp_ord[x] + 12'd1;
        for (int e = 0; e < RING_DEPTH; e++) begin
          cnt[x][e] <= cnt_n[x][e];
          cnt_is_one[x][e] <= cnt_n[x][e] == CNT_W'(1);
          if (push_oh[x][e]) begin
            q_cmd_idx[x][e] <= current_cmd_idx;
            q_tag[x][e] <= cur_e_oh;
          end
        end
      end
    end
  end

  // Metadata accompanies the response being processed, before any head pop
  // or ordinal reset at this edge. Clear wins over a simultaneous orphan.
  always_ff @(posedge clk) begin
    if (!rstn) begin
      dec_vld <= 1'b0;
      orphan_sticky <= 1'b0;
    end else begin
      dec_vld <= dec;
      dec_hit <= dec && (|sel_oh);
      dec_cmd_idx <= cmd_idx_sel;
      dec_rsp_ord <= rsp_ord_sel;
      dec_axiid <= dec_axiid_c;
      if (orphan_clr) begin
        orphan_sticky <= 1'b0;
        orphan_axiid <= '0;
      end else if (dec && !(|sel_oh) && !orphan_sticky) begin
        orphan_sticky <= 1'b1;
        orphan_axiid <= dec_axiid_c;
      end
    end
  end

  // synthesis translate_off
  initial begin
    if (RING_DEPTH < 2 || RING_DEPTH > 8 || (RING_DEPTH & (RING_DEPTH-1)))
      $fatal(1, "RING_DEPTH must be a power of two in 2..8");
  end
  // synthesis translate_on
endmodule
