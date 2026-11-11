// AXI-Lite Slave Interface
// Address width : 64-bit
// Data width    : 32-bit  (wstrb = 4-bit byte enables)
//
// Register map (byte offset):
//   0x00         version           read-only; value supplied by pl_example (same value as flr_slave):
//                                  [31:16]=0xAA00 magic, [15]=multi-function design (1=multi PF/VF,
//                                  0=single function), [7:0]=version number
//   0x04         scratch0          R/W global: general-purpose scratch register 0
//   0x08         scratch1          R/W global: general-purpose scratch register 1
//   0x0C         dma_mode          R/W per-function: [1:0]=dma_mode
//                                  0b00=Simple DMA, 0b01=H2C LL (Ph1 H2C→Ph2 H2C LL)
//                                  0b11=C2H LL (Ph1 H2C→Ph2 C2H LL); default 0
//                                  (bit[0]=LL enable, bit[1]=C2H sub-mode)
//   0x10-0x20    C2H context regs  R/W: reg0=size, reg1=src_lo, reg2=src_hi,
//                                       reg3=dst_lo, reg4=dst_hi (trigger)
//   0x24         c2h_irq_status    read-only (FPGA-written): C2H interrupt status
//   0x28         c2h_irq_clr_trig  write-only (host-written): any write sets C2H clr req
//                                  to pl_example; reads back {31'b0, irq_clr_req_c2h}
//   0x30-0x40    H2C context regs  R/W: reg0=size, reg1=src_lo, reg2=src_hi,
//                                       reg3=dst_lo, reg4=dst_hi (trigger)
//   0x44         h2c_irq_status    read-only (FPGA-written): H2C interrupt status
//   0x48         h2c_irq_clr_trig  write-only (host-written): any write sets H2C clr req
//                                  to pl_example; reads back {31'b0, irq_clr_req_h2c}
//   0x4C         flr_done_trig     write-only (host-written, PF or VF): any write sets this
//                                  function's own FLR-done request flag to pl_example's FLR
//                                  controller (see flr_slave.sv/pl_example.sv); reads back
//                                  {31'b0, vf_flr_done_req} for the requesting function's channel
//   0x50         chn_local_num     read-only: {25'b0, ar_chn} - the reading function's own
//                                  local channel number (channel = vf_slot*NUM_PFS + pf_num,
//                                  see axil_slave_pkg::pf_vf_to_channel; PF=vf_slot 0, VFs are
//                                  vf_slot 1..NUM_VFS_PER_PF). Lets a PF/VF driver discover its
//                                  own fixed channel assignment without hardcoding it.
//   0x54-0x5C    reserved for future functional registers (unimplemented; reads 0, writes no-op)
//
// Debug registers moved to 0x60+ (was 0x4C+) on 2026-09-24 to free up 0x4C-0x5C above for
// functional registers like flr_done_trig — every debug register kept its relative order and
// spacing, just shifted +0x14 bytes (+5 word-index) as a block:
//   0x60         dbg_pf_trigger    read-only: last accepted AW/trigger metadata
//                                             [2:0]=last_aw_pf_num [3]=last_aw_vfunc_active
//                                             [11:4]=last_aw_vfunc_num [16:12]=last_aw_word_idx
//                                             [17]=last_wr_bank_is_c2h [18]=last_wr_bank_is_h2c
//                                             [19]=last_trig_is_c2h [20]=last_trig_is_h2c
//   0x64-0x70    dma_irq[127:0]    read-only status (4 x 32-bit)
//   0x74         chn_num status    read-only: [5:0]=h2c_chn_num, [21:16]=c2h_chn_num
//   0x78         irq_status        read-only: [0]=dma_irq_any [1]=msix_req [2]=msix_grant
//                                             [5:3]=sm_int [8:6]=sm_dbi [9]=start_int
//                                             [10]=grant_vld [11]=msix_error [18:12]=chn_num(bit[6]=H2C)
//   0x7C         msix_dbg_snapshot read-only: latched at req pulse
//                                             [10:0]=vector [13:11]=func [14]=vfunc_active
//                                             [22:15]=vfunc_num [24:23]=operation [25]=req
//                                             [28:26]=sm_dbi [31:29]=sm_int
//   0x80         msix_dbg_events   read-only: [2:0] sticky req/grant/error pulses
//                                             [5:3]=sm_axilm [8:6]=sm_int [11:9]=sm_dbi
//   0x84         dma_irq_eligible0 read-only: dma_irq[31:0] (eligible channels)
//   0x88         dbg_ctx_addr      read-only: live aw_addr_lat[31:0]
//   0x8C         dbg_ctx_data      read-only: live w_data_lat[31:0]
//   0x90         dbi_status        read-only: [2:0]=sm_dbi [5:3]=sm_axilm [6]=st_dbi_wr
//                                            [7]=write_done [8]=aw_done [9]=w_done
//                                            [10]=pending_any_ack [11]=write_commit
//                                            [16:12]=wr_count [17]=any C2H chn pending
//                                            [18]=any H2C chn pending [19]=reserved
//
// LL mode debug registers (read-only, added for two-phase LL DMA visibility):
//   0x94-0xA0    ll_pending[127:0]   4×32-bit: per-global-channel Phase 2 trigger pending
//                                    [63:0]=C2H chn 0-63, [127:64]=H2C chn 0-63
//                                    Bit set = channel awaiting FPGA LL DBI write sequence
//   0xA4-0xB0    ll_phase1_done[127:0] 4×32-bit: channels between Phase 1 IRQ and Phase 2 MSI-X
//                                    Bit set = channel's Phase 1 Simple DMA done, Phase 2 in flight
//   0xB4         ll_status           read-only: live LL SM control signals
//                                    [6:0]=ll_chn_lat (channel in DBI_LL_WR)
//                                    [16:10]=ll_grant_chn (next LL arbiter grant)
//                                    [17]=ll_rr_advance (LL write done pulse)
//                                    [18]=ll_grant_vld (LL arbiter has pending grant)
//                                    [19]=ll_p1_arm (Phase 2 arm pulse)
//                                    [20]=phase1_clr_r (Phase 1 CPM6 irq clear in progress)
//   0xB8-0xC4    phase1_in_progress[127:0] 4×32-bit: channels where Phase 1 irq-clear DBI write
//                                    has been issued but dma_irq has not yet deasserted.
//                                    Bit set = Phase 1 clear write landed in CPM6, FPGA
//                                    is waiting for CPM6 to drop dma_irq before arming Phase 2.
//                                    Key debug: if bit stays set for long, CPM6 is slow to
//                                    deassert dma_irq after the +0x8C write for that channel.
//   0xC8         run_status        read-only: live LL DMA status diagnostic register
//                                  Live fields updated every clock; [5:4] are sticky errors.
//                                  [2:0]=phase: 0=idle 1=Ph1-running 2=Ph2-LL-DBI
//                                               3=Ph2-DMA-running 4=MSI-X-inflight
//                                               5=done/waiting-host-clear
//                                  [3]=trigger_pending  [4]=MSI-X-err(sticky)
//                                  [5]=Guard2-fired(sticky)  [6]=start_int  [7]=grant_vld
//                                  [14:8]=chn_num  [16]=ll_pending  [17]=ll_phase1_done
//                                  [20:18]=sm_int  [23:21]=sm_dbi
//                                  Sticky bits cleared by host write to 0xCC.
//   0xCC         run_status_clr    write-only: any host write clears run_status; reads 0x0
//   0xD0         dbg_last_int_read_data  read-only: last raw value read from CPM6 INT_STATUS
//                                  (+0x84) via DBI, for either the Phase 1 clear-write or the
//                                  Phase 2/Simple completion path. Held (not zeroed later) so
//                                  it survives past the host ack, unlike 0x24/0x44.
//   0xD4         dbg_last_clr_wdata  read-only: last write-data value the host driver actually
//                                  wrote to 0x28 (c2h_irq_clr_trig) or 0x48 (h2c_irq_clr_trig),
//                                  captured only for channel DBG_CHN (default: local channel 1 /
//                                  PF1). Cross-check against 0xD0: if the driver's own value and
//                                  the FPGA's captured status don't match, that's the ack-clear bug.
//   0xD8         dbg_h2c_access_seen read-only, sticky: [0]=driver has read 0x44 (h2c_irq_status)
//                                  at least once, [1]=driver has written 0x48 (h2c_irq_clr_trig)
//                                  at least once — both scoped to channel DBG_CHN only.
//                                  [2]=dma_irq[DBG_H2C_GLB_CHN] was observed to rise (0->1) while
//                                  ll_phase1_done was already 1 for that channel — i.e. this
//                                  specific interrupt assertion is confirmed to be Phase 2's own
//                                  completion, not a re-presentation of Phase 1's own irq.
//                                  [3]=reserved (formerly the Phase 1->Phase 2 handoff delay
//                                  countdown-done flag; the delay was removed — proved unnecessary
//                                  once the actual PCIe-wedge root cause, a spurious duplicate DBI
//                                  doorbell, was fixed — and always reads 0 now).
//                                  Cleared by the same host write to 0xCC that clears run_status's
//                                  other sticky bits.
//   0xDC         reserved, unimplemented (formerly ph1_ph2_delay_cfg — removed, see 0xD8 [3]).
//                                  Reads 0; writes are a no-op.
//
// Per-channel context storage:
//   regs_c2h/regs_h2c are indexed by DMA channel (0-63), derived from the AW/AR
//   sideband (pf_num/vfunc_num/vfunc_active) via axil_slave_pkg::pf_vf_to_channel.
//   Each of the 64 PF/VF functions gets its own isolated 5-register bank per
//   direction, so concurrent setup from different functions can't alias.
//   Channel layout: channel = vf_slot*8 + pf_num (channels 0-7 = PF0-PF7).
//   See ../docs/hdma_ddr_top_description.md for the full mapping table.
//
// IMPORTANT: this register file has no bearing on CPM6's own internal HDMA
//   FUNC_NUM register (which sets the Requester-ID on that channel's actual
//   DMA data-movement TLPs). That register is programmed separately by PF0's
//   driver via PF0's BAR0 (not through this AXI-Lite slave) and must be set
//   up before a channel's first use — see docs/hdma_ddr_top_description.md,
//   "CPM6 HDMA FUNC_NUM Programming".
//
// trigger_pending / stall gate:
//   trigger_pending[127:0] (dma_irq-style: [63:0]=C2H channel, [127:64]=H2C channel)
//   is the single source of truth for both (a) the request vector pl_example's
//   round-robin arbiter consumes to pick which channel's context to flush next, and
//   (b) the AW/W stall gate here: a channel's own 5 context registers are blocked
//   from new writes only while that channel's bit is set. A channel's IRQ status/
//   clear registers are never gated by its own pending trigger.
//   Set per-channel when that channel's dst_hi (reg4) commits; cleared when
//   pl_example pulses trigger_clear_vld with that channel's global index (once its
//   6-word DBI flush completes).
//
// Write channel:
//   AW and W channels accepted independently (either order).
//   Write commits and B response issues when both have been received.
//   Byte strobes (wstrb) are captured for debug (0x7C[23:20]) but not
//   applied — all writes are expected to be full 32-bit (wstrb=4'hF).
//
// Read channel:
//   AR accepted, register value returned the following cycle. Context register
//   reads are indexed by the READING function's own channel (ar_pf_num/
//   ar_vfunc_num/ar_vfunc_active), so each function reads back its own context.

`timescale 1 ps / 1 ps

import axil_slave_pkg::*;

module axil_slave #(
    parameter int NUM_PFS        = 8,
    parameter int NUM_VFS_PER_PF = 7,
    parameter logic [31:0] VERSION_VALUE = 32'hAA00_0003,
    // Function-index -> DMA-channel table (see axil_slave_pkg / top of pl_example.sv). Default = identity.
    parameter chn_map_t FUNC_TO_CHN_MAP = identity_map(),
    // Exposed as a parameter so it can be used in port width declarations
    parameter int NUM_CHN        = NUM_PFS * (NUM_VFS_PER_PF + 1)
) (
    input  logic        clk,
    input  logic        reset_n,

    // ---------- Write Address Channel ----------
    input  logic [63:0] s_axil_awaddr,
    input  logic [2:0]  s_axil_awprot,
    input  logic        s_axil_awvalid,
    output logic        s_axil_awready,

    // ---------- Write Data Channel ----------
    input  logic [31:0] s_axil_wdata,
    input  logic [3:0]  s_axil_wstrb,
    input  logic        s_axil_wvalid,
    output logic        s_axil_wready,

    // ---------- Write Response Channel ----------
    output logic [1:0]  s_axil_bresp,
    output logic        s_axil_bvalid,
    input  logic        s_axil_bready,

    // ---------- Read Address Channel ----------
    input  logic [63:0] s_axil_araddr,
    input  logic [2:0]  s_axil_arprot,
    input  logic        s_axil_arvalid,
    output logic        s_axil_arready,

    // ---------- Read Data Channel ----------
    output logic [31:0] s_axil_rdata,
    output logic [1:0]  s_axil_rresp,
    output logic        s_axil_rvalid,
    input  logic        s_axil_rready,

    // ---------- Context trigger / arbitration interface ----------
    output logic [127:0] trigger_pending,   // level vector: [63:0]=C2H chn, [127:64]=H2C chn
    input  logic          trigger_clear_vld, // 1-cycle pulse: trigger_clear_chn's flush committed
    input  logic [6:0]    trigger_clear_chn, // global-channel index being cleared
    input  logic [6:0]    ctxt_rd_chn,       // global-channel pl_example wants a snapshot of
    output axil_regs_t    ctxt_rd_regs,      // combinational per-channel snapshot for ctxt_rd_chn
    output logic [1:0]    ctxt_rd_dma_mode,   // combinational: dma_mode_reg[ctxt_rd_chn] (00=Simple,01=H2C LL,11=C2H LL)

    // ---------- AW user bits (sideband from cpm_user_aligner) ----------
    // Packed as: [0]=vfunc_active, [8:1]=vfunc_num[7:0], [11:9]=pf_num[2:0]
    input  logic [11:0] s_axil_awuser,

    // ---------- AR user bits (sideband from cpm_user_aligner) ----------
    input  logic [11:0] s_axil_aruser,

    // ---------- Interrupt status store (driven by pl_example after DBI read) ----------
    input  logic        irq_status_wr,      // 1-cycle pulse: store irq_status_data in selected bank
    input  logic        irq_status_is_c2h,  // 1=C2H bank (0x24), 0=H2C bank (0x44)
    input  logic [5:0]  irq_status_chn,     // local channel index for irq_status_wr
    input  logic [31:0] irq_status_data,    // channel interrupt status value
    // ---------- Interrupt clear handshake ----------
    output logic [NUM_CHN-1:0] irq_clr_req_c2h,  // per-channel: set when host writes 0x28 for that channel
    output logic [NUM_CHN-1:0] irq_clr_req_h2c,  // per-channel: set when host writes 0x48 for that channel
    input  logic        irq_clr_done,        // 1-cycle pulse from pl_example: clear sequence done
    input  logic        irq_clr_done_is_c2h, // 1=C2H direction, 0=H2C direction
    input  logic [5:0]  irq_clr_done_chn,    // local channel index that was cleared
    // ---------- IRQ status read port for pl_example clear path ----------
    input  logic [5:0]  irq_clr_rd_chn,          // local channel to read status for
    output logic [31:0] irq_clr_rd_c2h_status,   // combinatorial: irq_status_reg_c2h[irq_clr_rd_chn]
    output logic [31:0] irq_clr_rd_h2c_status,   // combinatorial: irq_status_reg_h2c[irq_clr_rd_chn]
    // ---------- FLR-done handshake (0x4C flr_done_trig) ----------
    output logic [NUM_CHN-1:0] vf_flr_done_req,  // per-channel: set when that function writes 0x4C
    input  logic         flr_done_req_clr,       // 1-cycle pulse from pl_example: consumed, clear it
    input  logic [5:0]  flr_done_req_clr_chn,   // local channel index that was consumed

    // ---------- Read-only debug status inputs ----------
    input  logic [127:0] dma_irq,           // reads at 0x64-0x70
    input  logic [6:0]   h2c_chn_num,       // reads at 0x74 [5:0]
    input  logic [6:0]   c2h_chn_num,       // reads at 0x74 [21:16]
    input  logic [31:0]  irq_status,        // reads at 0x78
    input  logic [31:0]  msix_dbg_snapshot, // reads at 0x7C
    input  logic [31:0]  msix_dbg_events,   // reads at 0x80
    input  logic [31:0]  dma_irq_eligible0, // reads at 0x84
    // DBI status inputs from pl_example (for 0x7C dbi_status)
    input  logic [2:0]   sm_dbi,
    input  logic [2:0]   sm_axilm,
    input  logic         st_dbi_wr,
    input  logic         write_done,
    input  logic [4:0]   wr_count,
    // ---------- DMA-mode query port (used by pl_example interrupt SM) ----------
    input  logic [5:0]   irq_dma_mode_rd_chn,  // local channel to query
    output logic [1:0]   irq_dma_mode_out,       // dma_mode_reg[irq_dma_mode_rd_chn]
    // ---------- LL mode debug status inputs (from pl_example) ----------
    input  logic [127:0] ll_pending,            // ll_pending_r: channels awaiting Ph2 LL DBI write
    input  logic [127:0] ll_phase1_done,        // ll_phase1_done_r: channels between Ph1 done and Ph2 MSI-X
    input  logic [6:0]   ll_chn_lat,            // channel currently being LL-programmed via DBI
    input  logic [6:0]   ll_grant_chn,          // next channel from LL RR arbiter
    input  logic         ll_grant_vld,           // LL RR arbiter has valid grant
    input  logic         ll_p1_arm,              // Phase 2 arm pulse (set by sm_int)
    input  logic         phase1_clr_r,           // sm_int executing Phase 1 CPM6 irq clear
    input  logic         ll_rr_advance,           // LL DBI write sequence complete (from sm_dbi)
    // ---------- phase1_in_progress debug (Phase 1 deassert-wait tracking) ----------
    input  logic [127:0] ll_p1_deassert_seen,     // phase1_in_progress_r from pl_example
    // ---------- LL DMA run status dashboard ----------
    input  logic [31:0]  run_status,              // sticky run health register driven by pl_example
    output logic         run_status_clr,          // 1-cycle pulse: host wrote BAR1+0xB8
    // ---------- Ack-path cross-check debug (added to chase the host-ack clear-write bug) ----------
    input  logic [31:0]  dbg_last_int_read_data   // last raw value read from CPM6 INT_STATUS via DBI
);

    localparam logic [31:0] VERSION_REG = VERSION_VALUE;

    // Derived from module parameters
    localparam int PF_W      = $clog2(NUM_PFS);
    localparam int VF_SLOT_W = $clog2(NUM_VFS_PER_PF + 1);
    localparam int CHN_W     = PF_W + VF_SLOT_W;

    // ----------------------------------------------------------------
    // Address decoding
    //   ADDR_LSB = 2  (divide byte addr by 4 to get word index)
    //   C2H context regs occupy word indices 4..8   (byte offsets 0x10..0x20)
    //   H2C context regs occupy word indices 12..16 (byte offsets 0x30..0x40)
    //   Direction (C2H/H2C) is derived per-access from which bank's address
    //   range a given transaction falls in, not a single latched flag.
    //   flr_done_trig occupies word index 19 (byte offset 0x4C)
    //   Debug status occupies word indices 24..54 (byte offsets 0x60..0xD8) — read-only
    //   (moved from 20..31/0x50..0x7C on 2026-09-24 to make room for flr_done_trig and future
    //   functional registers at 0x50-0x5C)
    // ----------------------------------------------------------------
    localparam int ADDR_LSB          = 2;
    localparam int NUM_REGS          = 5;
    localparam int C2H_BASE_WI       = 5'd4;
    localparam int H2C_BASE_WI       = 5'd12;
    localparam int C2H_IRQ_STATUS_WI = 5'd9;
    localparam int C2H_IRQ_CLR_WI    = 5'd10;
    localparam int H2C_IRQ_STATUS_WI = 5'd17;
    localparam int H2C_IRQ_CLR_WI    = 5'd18;
    localparam int FLR_DONE_TRIG_WI  = 6'd19;  // 0x4C: flr_done_trig register
    localparam int DMA_MODE_WI       = 5'd3;   // 0x0C: dma_mode register
    localparam int DBG_CHN           = 1;      // channel of interest for ack-path debug capture (PF1, local chn 1)
    // H2C_GLB_BASE: CPM6's fixed per-direction slot count (silicon-fixed, NOT derived from
    // NUM_CHN/NUM_VFS_PER_PF) — must match pl_example.sv's H2C_GLB_BASE.
    localparam int H2C_GLB_BASE      = 64;
    localparam int DBG_H2C_GLB_CHN   = H2C_GLB_BASE + DBG_CHN;  // H2C global index of DBG_CHN (65)

    // ----------------------------------------------------------------
    // Register file — per-channel (0-63), one 5-register bank per direction
    // per channel. Indexed via axil_slave_pkg::pf_vf_to_channel on the AW/AR
    // sideband so each of the 64 PF/VF functions has isolated storage.
    // ----------------------------------------------------------------
    logic [31:0] regs_c2h     [0:NUM_CHN-1][0:NUM_REGS-1];
    logic [31:0] regs_h2c     [0:NUM_CHN-1][0:NUM_REGS-1];
    logic [31:0] irq_status_reg_c2h [0:NUM_CHN-1];   // 0x24: per-channel C2H int-status
    logic [31:0] irq_status_reg_h2c [0:NUM_CHN-1];   // 0x44: per-channel H2C int-status
    logic [1:0] dma_mode_reg       [0:NUM_CHN-1];    // 0x0C: per-channel DMA mode
    logic [31:0] scratch0_reg;                         // 0x04: global scratch register 0
    logic [31:0] scratch1_reg;                         // 0x08: global scratch register 1
    logic [31:0] dbg_pf_trigger;       // 0x4C: last AW/trigger metadata
    logic [31:0] dbg_last_clr_wdata;   // last write-data value the driver wrote to 0x28/0x48 irq_clr_trig
    logic dbg_h2c_status_rd_seen;      // sticky: driver has read 0x44 (h2c_irq_status) at least once
    logic dbg_h2c_clr_wr_seen;         // sticky: driver has written 0x48 (h2c_irq_clr_trig) at least once
    logic dbg_irq_rose_after_ph1;      // sticky: dma_irq[DBG_H2C_GLB_CHN] rose while ll_phase1_done
                                       // was already 1 — confirms this assertion is Phase 2's own
                                       // completion, not a re-presentation of Phase 1's own irq.
    logic [127:0] dma_irq_d;           // 1-cycle-delayed dma_irq, for rising-edge detection above

    // ----------------------------------------------------------------
    // Write path
    //   Latch AW and W independently; commit when both received.
    // ----------------------------------------------------------------
    logic        aw_done;
    logic        w_done;
    logic [63:0] aw_addr_lat;
    logic [11:0] aw_user_lat;
    logic [31:0] w_data_lat;
    logic [3:0]  w_strb_lat;

    logic [63:0] ar_addr_lat;
    logic [11:0] ar_user_lat;
    logic        ar_pending;
    logic        ar_vfunc_active;
    logic [7:0]  ar_vfunc_num;
    logic [2:0]  ar_pf_num;

    // ----------------------------------------------------------------
    // Channel derivation (single source of truth: axil_slave_pkg)
    //   incoming_chn/glb : from the LIVE bus (s_axil_awuser), used to gate
    //                       s_axil_awready before AW is even latched.
    //   aw_chn/glb       : from the LATCHED aw_user_lat, stable across the
    //                       AW+W handshake, used at commit time and to gate
    //                       s_axil_wready.
    //   ar_chn           : from the LATCHED ar_user_lat, for read-path indexing.
    // ----------------------------------------------------------------
    logic [6:0] incoming_chn, aw_chn, ar_chn;
    // With the default identity table the lookup is bypassed at elaboration, so the logic is exactly
    // the original formula (no ROM, no extra depth on the awready path).
    localparam bit MAP_IS_IDENTITY = (FUNC_TO_CHN_MAP == identity_map());
    logic [6:0] incoming_glb_c2h, incoming_glb_h2c, aw_glb_c2h, aw_glb_h2c;

    wire [6:0] incoming_fi = func_index(s_axil_awuser[11:9], s_axil_awuser[8:1], s_axil_awuser[0], PF_W, VF_SLOT_W);
    wire [6:0] aw_fi       = func_index(aw_user_lat[11:9],   aw_user_lat[8:1],   aw_user_lat[0],   PF_W, VF_SLOT_W);
    wire [6:0] ar_fi       = func_index(ar_pf_num, ar_vfunc_num, ar_vfunc_active,                  PF_W, VF_SLOT_W);
    assign incoming_chn = MAP_IS_IDENTITY ? incoming_fi : func_to_chn(incoming_fi, FUNC_TO_CHN_MAP);
    assign aw_chn       = MAP_IS_IDENTITY ? aw_fi       : func_to_chn(aw_fi,       FUNC_TO_CHN_MAP);
    assign ar_chn       = MAP_IS_IDENTITY ? ar_fi       : func_to_chn(ar_fi,       FUNC_TO_CHN_MAP);

    assign incoming_glb_c2h = glb_chn_calc(1'b1, incoming_chn);
    assign incoming_glb_h2c = glb_chn_calc(1'b0, incoming_chn);
    assign aw_glb_c2h       = glb_chn_calc(1'b1, aw_chn);
    assign aw_glb_h2c       = glb_chn_calc(1'b0, aw_chn);

    // ----------------------------------------------------------------
    // c2h/h2c_reg4_written: combinatorial — true when write_commit fires
    //   on dst_hi (reg4) of the respective bank.
    // ----------------------------------------------------------------
    logic c2h_reg4_written;
    logic h2c_reg4_written;
    logic write_commit;
    logic [5:0] aw_word_idx;   // widened from [4:0] so debug registers beyond word idx 31 (e.g. 0xBC/0xC0/0xC4) are reachable

    assign aw_word_idx      = aw_addr_lat[7:2];
    assign c2h_reg4_written = write_commit && (aw_word_idx == (C2H_BASE_WI + NUM_REGS - 1));
    assign h2c_reg4_written = write_commit && (aw_word_idx == (H2C_BASE_WI + NUM_REGS - 1));

    // ----------------------------------------------------------------
    // trigger_pending: single source of truth for both the arbiter request
    //   vector (pl_example) and the per-channel AW/W stall gate (here).
    //   Set on the target channel's global-channel bit when its dst_hi
    //   commits; cleared when trigger_clear_vld pulses with that channel's
    //   global index (once pl_example's DBI flush for it completes).
    // ----------------------------------------------------------------
    logic [127:0] trigger_pending_r;
    assign trigger_pending = trigger_pending_r;

    logic [127:0] tp_set_mask, tp_clear_mask;
    always_comb begin
        tp_set_mask = '0;
        if (c2h_reg4_written) tp_set_mask[aw_glb_c2h] = 1'b1;
        if (h2c_reg4_written) tp_set_mask[aw_glb_h2c] = 1'b1;
        tp_clear_mask = '0;
        if (trigger_clear_vld) tp_clear_mask[trigger_clear_chn] = 1'b1;
    end

    always_ff @(posedge clk) begin
        if (!reset_n) trigger_pending_r <= '0;
        else          trigger_pending_r <= (trigger_pending_r & ~tp_clear_mask) | tp_set_mask;
    end

    // ----------------------------------------------------------------
    // AW/W stall gate — per-channel, context registers only.
    //   A channel's 5 context-register word indices are blocked from new
    //   writes only while that channel's trigger_pending bit is set. IRQ
    //   status/clear word indices for the same channel are never gated by
    //   its own pending trigger (narrower than the old whole-bank stall).
    // ----------------------------------------------------------------
    logic incoming_is_ctxt_c2h, incoming_is_ctxt_h2c;
    assign incoming_is_ctxt_c2h = (s_axil_awaddr[6:2] >= C2H_BASE_WI) &&
                                  (s_axil_awaddr[6:2] < (C2H_BASE_WI + NUM_REGS));
    assign incoming_is_ctxt_h2c = (s_axil_awaddr[6:2] >= H2C_BASE_WI) &&
                                  (s_axil_awaddr[6:2] < (H2C_BASE_WI + NUM_REGS));

    logic aw_lat_is_ctxt_c2h, aw_lat_is_ctxt_h2c;
    assign aw_lat_is_ctxt_c2h = (aw_word_idx >= C2H_BASE_WI) && (aw_word_idx < (C2H_BASE_WI + NUM_REGS));
    assign aw_lat_is_ctxt_h2c = (aw_word_idx >= H2C_BASE_WI) && (aw_word_idx < (H2C_BASE_WI + NUM_REGS));

    // AW: stall only if the incoming address targets a channel/bank with a pending trigger
    assign s_axil_awready = ~aw_done
                          && ~(incoming_is_ctxt_c2h && trigger_pending_r[incoming_glb_c2h])
                          && ~(incoming_is_ctxt_h2c && trigger_pending_r[incoming_glb_h2c]);

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            aw_done     <= 1'b0;
            aw_addr_lat <= '0;
            aw_user_lat <= '0;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                aw_done     <= 1'b1;
                aw_addr_lat <= s_axil_awaddr;
                aw_user_lat <= s_axil_awuser;
            end else if (aw_done && w_done) begin
                aw_done <= 1'b0;   // both captured; will commit this cycle
            end
        end
    end

    // W: stall based on the latched AW channel/bank (when aw_done); no stall before AW is captured
    assign s_axil_wready = ~w_done
                         && ~(aw_done && aw_lat_is_ctxt_c2h && trigger_pending_r[aw_glb_c2h])
                         && ~(aw_done && aw_lat_is_ctxt_h2c && trigger_pending_r[aw_glb_h2c]);

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            w_done     <= 1'b0;
            w_data_lat <= '0;
            w_strb_lat <= '0;
        end else begin
            if (s_axil_wvalid && s_axil_wready) begin
                w_done     <= 1'b1;
                w_data_lat <= s_axil_wdata;
                w_strb_lat <= s_axil_wstrb;
            end else if (aw_done && w_done) begin
                w_done <= 1'b0;
            end
        end
    end

    // Commit: fire when both AW and W are latched and B channel is free

    assign write_commit = aw_done && w_done && !s_axil_bvalid;

    // Register file update + B response
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            s_axil_bvalid        <= 1'b0;
            s_axil_bresp         <= 2'b00;
            for (int c = 0; c < NUM_CHN; c++) begin
                for (int i = 0; i < NUM_REGS; i++) begin
                    regs_c2h[c][i] <= '0;
                    regs_h2c[c][i] <= '0;
                end
                dma_mode_reg[c] <= 2'b0;  // default: Simple DMA
            end
            scratch0_reg <= '0;
            scratch1_reg <= '0;
        end else begin
            if (write_commit) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp  <= 2'b00;
                unique case (aw_word_idx)
                    6'd1:  scratch0_reg <= w_data_lat;                                  // 0x04 scratch0
                    6'd2:  scratch1_reg <= w_data_lat;                                  // 0x08 scratch1
                    6'd3:  dma_mode_reg[aw_chn[CHN_W-1:0]] <= w_data_lat[1:0];          // 0x0C DMA mode (0=Simple,1=H2C LL,3=C2H LL)
                    6'd4:  regs_c2h[aw_chn[CHN_W-1:0]][0] <= w_data_lat;                // 0x10 C2H size
                    6'd5:  regs_c2h[aw_chn[CHN_W-1:0]][1] <= w_data_lat;                // 0x14 C2H src_lo
                    6'd6:  regs_c2h[aw_chn[CHN_W-1:0]][2] <= w_data_lat;                // 0x18 C2H src_hi
                    6'd7:  regs_c2h[aw_chn[CHN_W-1:0]][3] <= w_data_lat;                // 0x1C C2H dst_lo
                    6'd8:  regs_c2h[aw_chn[CHN_W-1:0]][4] <= w_data_lat;                // 0x20 C2H dst_hi (trigger)
                    6'd12: regs_h2c[aw_chn[CHN_W-1:0]][0] <= w_data_lat;                // 0x30 H2C size
                    6'd13: regs_h2c[aw_chn[CHN_W-1:0]][1] <= w_data_lat;                // 0x34 H2C src_lo
                    6'd14: regs_h2c[aw_chn[CHN_W-1:0]][2] <= w_data_lat;                // 0x38 H2C src_hi
                    6'd15: regs_h2c[aw_chn[CHN_W-1:0]][3] <= w_data_lat;                // 0x3C H2C dst_lo
                    6'd16: regs_h2c[aw_chn[CHN_W-1:0]][4] <= w_data_lat;                // 0x40 H2C dst_hi (trigger)
                    default: ; // 0x28/0x48 IRQ clear and 0x4C flr_done_trig handled in separate always_ff
                               // blocks; 0xDC reserved (removed Ph1->Ph2 delay); others no-op
                endcase
            end else if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end

    // ----------------------------------------------------------------
    // ctxt_rd_regs: combinational per-channel snapshot for whichever
    //   channel pl_example is currently flushing (ctxt_rd_chn). Safe to
    //   read live: that channel's registers are frozen by the stall gate
    //   above for exactly as long as its trigger_pending bit is set.
    // ----------------------------------------------------------------
    logic       ctxt_rd_is_c2h;
    logic [5:0] ctxt_rd_local_chn;
    assign ctxt_rd_is_c2h    = glb_chn_is_c2h(ctxt_rd_chn);
    assign ctxt_rd_local_chn = glb_chn_local(ctxt_rd_chn)[5:0];

    assign ctxt_rd_regs.reg0 = ctxt_rd_is_c2h ? regs_c2h[ctxt_rd_local_chn][0] : regs_h2c[ctxt_rd_local_chn][0];
    assign ctxt_rd_regs.reg1 = ctxt_rd_is_c2h ? regs_c2h[ctxt_rd_local_chn][1] : regs_h2c[ctxt_rd_local_chn][1];
    assign ctxt_rd_regs.reg2 = ctxt_rd_is_c2h ? regs_c2h[ctxt_rd_local_chn][2] : regs_h2c[ctxt_rd_local_chn][2];
    assign ctxt_rd_regs.reg3 = ctxt_rd_is_c2h ? regs_c2h[ctxt_rd_local_chn][3] : regs_h2c[ctxt_rd_local_chn][3];
    assign ctxt_rd_regs.reg4 = ctxt_rd_is_c2h ? regs_c2h[ctxt_rd_local_chn][4] : regs_h2c[ctxt_rd_local_chn][4];
    assign ctxt_rd_dma_mode  = dma_mode_reg[ctxt_rd_local_chn];
    assign irq_dma_mode_out  = dma_mode_reg[irq_dma_mode_rd_chn];

    // ----------------------------------------------------------------
    // irq_status_reg (0x24/0x44): per-channel, written by FPGA via irq_status_wr pulse.
    //   irq_status_chn selects which local channel's bank to update.
    // ----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            for (int c = 0; c < NUM_CHN; c++) begin
                irq_status_reg_c2h[c] <= '0;
                irq_status_reg_h2c[c] <= '0;
            end
        end else if (irq_status_wr) begin
            if (irq_status_is_c2h)
                irq_status_reg_c2h[irq_status_chn] <= irq_status_data;
            else
                irq_status_reg_h2c[irq_status_chn] <= irq_status_data;
        end
    end

    // Combinatorial per-channel IRQ status read port for pl_example's clear path.
    assign irq_clr_rd_c2h_status = irq_status_reg_c2h[irq_clr_rd_chn];
    assign irq_clr_rd_h2c_status = irq_status_reg_h2c[irq_clr_rd_chn];

    // ----------------------------------------------------------------
    // irq_clr_req_c2h/h2c (0x28/0x48): per-channel vectors.
    //   Set when host writes 0x28/0x48 (indexed by aw_chn — the requesting function's channel).
    //   Cleared when pl_example pulses irq_clr_done with the completed channel.
    //   Last assignment wins: if set and clear fire for the same channel in one cycle, clear wins.
    // ----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            irq_clr_req_c2h <= '0;
            irq_clr_req_h2c <= '0;
            dbg_last_clr_wdata <= '0;
        end else begin
            if (write_commit && (aw_word_idx == C2H_IRQ_CLR_WI)) begin
                irq_clr_req_c2h[aw_chn[CHN_W-1:0]] <= 1'b1;
                if (aw_chn[CHN_W-1:0] == DBG_CHN)
                    dbg_last_clr_wdata <= w_data_lat;  // capture what the driver actually wrote (chn 1 only)
            end
            if (write_commit && (aw_word_idx == H2C_IRQ_CLR_WI)) begin
                irq_clr_req_h2c[aw_chn[CHN_W-1:0]] <= 1'b1;
                if (aw_chn[CHN_W-1:0] == DBG_CHN)
                    dbg_last_clr_wdata <= w_data_lat;  // capture what the driver actually wrote (chn 1 only)
            end
            if (irq_clr_done &&  irq_clr_done_is_c2h)
                irq_clr_req_c2h[irq_clr_done_chn] <= 1'b0;
            if (irq_clr_done && !irq_clr_done_is_c2h)
                irq_clr_req_h2c[irq_clr_done_chn] <= 1'b0;
        end
    end

    // ----------------------------------------------------------------
    // vf_flr_done_req (0x4C flr_done_trig): per-channel vector, same set/clear pattern as
    //   irq_clr_req_c2h/h2c above, minus the C2H/H2C direction split (FLR is direction-agnostic).
    //   Set when a function (PF or VF) writes 0x4C (indexed by aw_chn — the requesting
    //   function's own channel). Cleared when pl_example's FLR controller pulses
    //   flr_done_req_clr with the channel it just consumed into its ack bitmap.
    // ----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            vf_flr_done_req <= '0;
        end else begin
            if (write_commit && (aw_word_idx == FLR_DONE_TRIG_WI))
                vf_flr_done_req[aw_chn[CHN_W-1:0]] <= 1'b1;
            if (flr_done_req_clr)
                vf_flr_done_req[flr_done_req_clr_chn[CHN_W-1:0]] <= 1'b0;
        end
    end

    // ----------------------------------------------------------------
    // dbg_pf_trigger (0x60): captures AW sideband and trigger source context.
    // ----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            dbg_pf_trigger <= '0;
        end else begin
            if (write_commit) begin
                dbg_pf_trigger[2:0]   <= aw_user_lat[11:9]; // PF number from AW sideband
                dbg_pf_trigger[3]     <= aw_user_lat[0];    // vfunc_active
                dbg_pf_trigger[11:4]  <= aw_user_lat[8:1];  // vfunc_num
                dbg_pf_trigger[16:12] <= aw_word_idx[4:0];  // accepted word index (low 5 bits; this
                                                             // debug field predates word indices >31)
                dbg_pf_trigger[17]    <= (aw_word_idx >= C2H_BASE_WI) &&
                                         (aw_word_idx < (C2H_BASE_WI + NUM_REGS));
                dbg_pf_trigger[18]    <= (aw_word_idx >= H2C_BASE_WI) &&
                                         (aw_word_idx < (H2C_BASE_WI + NUM_REGS));
            end
            if (c2h_reg4_written) begin
                dbg_pf_trigger[19] <= 1'b1; // last trigger from C2H bank
                dbg_pf_trigger[20] <= 1'b0;
            end else if (h2c_reg4_written) begin
                dbg_pf_trigger[19] <= 1'b0;
                dbg_pf_trigger[20] <= 1'b1; // last trigger from H2C bank
            end
        end
    end

    // ----------------------------------------------------------------
    // run_status_clr: 1-cycle pulse when host writes to BAR1+0xB8
    // ----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!reset_n)
            run_status_clr <= 1'b0;
        else
            run_status_clr <= write_commit && (aw_addr_lat[7:0] == 8'hCC);
    end

    // ----------------------------------------------------------------
    // Read path
    // ----------------------------------------------------------------
    
    assign ar_vfunc_active = ar_user_lat[0];
    assign ar_vfunc_num    = ar_user_lat[8:1];
    assign ar_pf_num       = ar_user_lat[11:9];

    assign s_axil_arready = ~ar_pending;

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            ar_pending  <= 1'b0;
            ar_addr_lat <= '0;
            ar_user_lat <= '0;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                ar_pending  <= 1'b1;
                ar_addr_lat <= s_axil_araddr;
                ar_user_lat <= s_axil_aruser;
            end else if (s_axil_rvalid && s_axil_rready) begin
                ar_pending <= 1'b0;
            end
        end
    end

    // Return register value one cycle after AR accepted
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rdata  <= '0;
            s_axil_rresp  <= 2'b00;
        end else begin
            if (ar_pending && !s_axil_rvalid) begin
                s_axil_rvalid <= 1'b1;
                s_axil_rresp  <= 2'b00;
                unique case (ar_addr_lat[7:2])  // 6-bit word index (0x00-0xFC)
                    0:  s_axil_rdata <= VERSION_REG;                                          // 0x00 version
                    1:  s_axil_rdata <= scratch0_reg;                                          // 0x04 scratch0
                    2:  s_axil_rdata <= scratch1_reg;                                          // 0x08 scratch1
                    3:  s_axil_rdata <= {30'b0, dma_mode_reg[ar_chn[CHN_W-1:0]]};             // 0x0C DMA mode
                    4:  s_axil_rdata <= regs_c2h[ar_chn[CHN_W-1:0]][0];       // 0x10 C2H size
                    5:  s_axil_rdata <= regs_c2h[ar_chn[CHN_W-1:0]][1];       // 0x14 C2H src_lo
                    6:  s_axil_rdata <= regs_c2h[ar_chn[CHN_W-1:0]][2];       // 0x18 C2H src_hi
                    7:  s_axil_rdata <= regs_c2h[ar_chn[CHN_W-1:0]][3];       // 0x1C C2H dst_lo
                    8:  s_axil_rdata <= regs_c2h[ar_chn[CHN_W-1:0]][4];       // 0x20 C2H dst_hi
                    9:  s_axil_rdata <= irq_status_reg_c2h[ar_chn[CHN_W-1:0]];       // 0x24 C2H IRQ status
                    10: s_axil_rdata <= {31'b0, irq_clr_req_c2h[ar_chn[CHN_W-1:0]]}; // 0x28 C2H IRQ clr pending
                    12: s_axil_rdata <= regs_h2c[ar_chn[CHN_W-1:0]][0];       // 0x30 H2C size
                    13: s_axil_rdata <= regs_h2c[ar_chn[CHN_W-1:0]][1];       // 0x34 H2C src_lo
                    14: s_axil_rdata <= regs_h2c[ar_chn[CHN_W-1:0]][2];       // 0x38 H2C src_hi
                    15: s_axil_rdata <= regs_h2c[ar_chn[CHN_W-1:0]][3];       // 0x3C H2C dst_lo
                    16: s_axil_rdata <= regs_h2c[ar_chn[CHN_W-1:0]][4];       // 0x40 H2C dst_hi
                    17: s_axil_rdata <= irq_status_reg_h2c[ar_chn[CHN_W-1:0]];       // 0x44 H2C IRQ status
                    18: s_axil_rdata <= {31'b0, irq_clr_req_h2c[ar_chn[CHN_W-1:0]]}; // 0x48 H2C IRQ clr pending
                    19: s_axil_rdata <= {31'b0, vf_flr_done_req[ar_chn[CHN_W-1:0]]}; // 0x4C flr_done_trig pending
                    20: s_axil_rdata <= {25'b0, ar_chn};            // 0x50 chn_local_num: reading function's own local channel number
                    // 0x54-0x5C reserved for future functional registers -- falls to default (reads 0)
                    24: s_axil_rdata <= dbg_pf_trigger;            // 0x60 PF/trigger debug
                    25: s_axil_rdata <= dma_irq[31:0];     // 0x64
                    26: s_axil_rdata <= dma_irq[63:32];    // 0x68
                    27: s_axil_rdata <= dma_irq[95:64];    // 0x6C
                    28: s_axil_rdata <= dma_irq[127:96];   // 0x70
                    29: s_axil_rdata <= {10'b0, c2h_chn_num[5:0], 10'b0, h2c_chn_num[5:0]}; // 0x74
                    30: s_axil_rdata <= irq_status;         // 0x78
                    31: s_axil_rdata <= msix_dbg_snapshot;  // 0x7C
                    32: s_axil_rdata <= msix_dbg_events;    // 0x80
                    33: s_axil_rdata <= dma_irq_eligible0;  // 0x84
                    34: s_axil_rdata <= aw_addr_lat[31:0];  // 0x88 live context write address
                    35: s_axil_rdata <= w_data_lat;         // 0x8C live context write data
                    36: s_axil_rdata <= {8'b0,
                                            w_strb_lat,                 // [23:20] byte enables of last write
                                            1'b0,                       // [19] reserved
                                            |trigger_pending_r[127:64], // [18] any H2C channel pending
                                            |trigger_pending_r[63:0],   // [17] any C2H channel pending
                                            wr_count[4:0],              // [16:12]
                                            write_commit,               // [11]
                                            |trigger_pending_r,         // [10] any channel pending
                                            w_done,                     // [9]
                                            aw_done,                    // [8]
                                            write_done,                 // [7]
                                            st_dbi_wr,                  // [6]
                                            sm_axilm,                   // [5:3]
                                            sm_dbi};                    // [2:0] 0x90 DBI status
                    // ---- LL mode debug registers (0x94-0xB4) ----
                    37: s_axil_rdata <= ll_pending[31:0];   // 0x94 ll_pending C2H chn 0-31
                    38: s_axil_rdata <= ll_pending[63:32];  // 0x98 ll_pending C2H chn 32-63
                    39: s_axil_rdata <= ll_pending[95:64];  // 0x9C ll_pending H2C chn 0-31
                    40: s_axil_rdata <= ll_pending[127:96]; // 0xA0 ll_pending H2C chn 32-63
                    41: s_axil_rdata <= ll_phase1_done[31:0];   // 0xA4 ll_phase1_done C2H 0-31
                    42: s_axil_rdata <= ll_phase1_done[63:32];  // 0xA8 ll_phase1_done C2H 32-63
                    43: s_axil_rdata <= ll_phase1_done[95:64];  // 0xAC ll_phase1_done H2C 0-31
                    44: s_axil_rdata <= ll_phase1_done[127:96]; // 0xB0 ll_phase1_done H2C 32-63
                    45: s_axil_rdata <= {11'b0,               // 0xB4 ll_status
                                            phase1_clr_r,       // [20] Phase 1 CPM6 irq clear in progress
                                            ll_p1_arm,          // [19] Phase 2 arm pulse
                                            ll_grant_vld,       // [18] LL arbiter has pending grant
                                            ll_rr_advance,      // [17] LL write sequence complete
                                            ll_grant_chn,       // [16:10] next LL arbiter channel
                                            3'b0,               // [9:7]  reserved
                                            ll_chn_lat};        // [6:0]  channel in DBI_LL_WR
                    46: s_axil_rdata <= ll_p1_deassert_seen[31:0];   // 0xB8 phase1_in_progress C2H 0-31
                    47: s_axil_rdata <= ll_p1_deassert_seen[63:32];  // 0xBC phase1_in_progress C2H 32-63
                    48: s_axil_rdata <= ll_p1_deassert_seen[95:64];  // 0xC0 phase1_in_progress H2C 0-31
                    49: s_axil_rdata <= ll_p1_deassert_seen[127:96]; // 0xC4 phase1_in_progress H2C 32-63
                    50: s_axil_rdata <= run_status;                  // 0xC8 LL DMA run status dashboard
                    52: s_axil_rdata <= dbg_last_int_read_data;       // 0xD0 last raw CPM6 INT_STATUS read via DBI
                    53: s_axil_rdata <= dbg_last_clr_wdata;           // 0xD4 last driver write-data to irq_clr_trig (0x28/0x48)
                    54: s_axil_rdata <= {28'b0, 1'b0, dbg_irq_rose_after_ph1, dbg_h2c_clr_wr_seen, dbg_h2c_status_rd_seen}; // 0xD8 [3]=reserved (was Ph1->Ph2 delay ran) [2]=irq rose after Ph1 done [1]=0x48 write seen [0]=0x44 read seen
                    default: s_axil_rdata <= 32'h0;
                endcase
            end else if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end

    // ----------------------------------------------------------------
    // dbg_h2c_status_rd_seen / dbg_h2c_clr_wr_seen: sticky "driver touched
    // this register" flags for the H2C ack path, scoped to a single debug
    // channel (DBG_CHN) so activity on other channels doesn't mask the one
    // actually under test. Cleared by the same host write to 0xB8 that
    // clears run_status's other sticky bits.
    // ----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!reset_n || run_status_clr) begin
            dbg_h2c_status_rd_seen <= 1'b0;
            dbg_h2c_clr_wr_seen    <= 1'b0;
        end else begin
            if (ar_pending && !s_axil_rvalid && ar_addr_lat[7:2] == H2C_IRQ_STATUS_WI &&
                ar_chn[CHN_W-1:0] == DBG_CHN)
                dbg_h2c_status_rd_seen <= 1'b1;
            if (write_commit && (aw_word_idx == H2C_IRQ_CLR_WI) &&
                aw_chn[CHN_W-1:0] == DBG_CHN)
                dbg_h2c_clr_wr_seen <= 1'b1;
        end
    end

    // ----------------------------------------------------------------
    // dbg_irq_rose_after_ph1: rising-edge detector on dma_irq[DBG_H2C_GLB_CHN]
    // qualified by ll_phase1_done at the same cycle. Only sets if the edge
    // is observed while ll_phase1_done is already 1 — i.e. Phase 1 has
    // already been confirmed done for this channel, so this specific
    // dma_irq assertion can only be Phase 2's own completion, not a
    // re-presentation of Phase 1's own (already-serviced) interrupt.
    // Cleared by the same host write to 0xB8 that clears other stickies.
    // ----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            dma_irq_d <= '0;
        end else begin
            dma_irq_d <= dma_irq;
        end
    end

    always_ff @(posedge clk) begin
        if (!reset_n || run_status_clr) begin
            dbg_irq_rose_after_ph1 <= 1'b0;
        end else begin
            if (dma_irq[DBG_H2C_GLB_CHN] && !dma_irq_d[DBG_H2C_GLB_CHN] &&
                ll_phase1_done[DBG_H2C_GLB_CHN])
                dbg_irq_rose_after_ph1 <= 1'b1;
        end
    end

endmodule
