// Full AXI4 register slave for PS-to-PL FLR (Function-Level Reset) communication, reached via
// CPM6's ps_wizard LPD_AXI_PL port (R5/RPU-driven), wired directly to M_LPD_AXI_0 — no interconnect
// IP in between (see hdma_ddr_top.sv). Independent of, and unrelated to, the PCIe-side AXI-Lite
// interface (axil_slave.sv) reached via cpm_axi_pl0/BAR1.
//
// AWADDR/ARADDR and AWID/ARID/BID/RID are sized to match ps_wizard_0/LPD_AXI_PL's real native
// widths (44-bit address, 16-bit ID) directly, since there's no SmartConnect here to narrow/adapt
// them. Only the low 6 bits of address are ever decoded (this slave's whole aperture is 64KB, and
// bit width beyond that is meaningless address-decode-wise); AWID/ARID are simply latched and
// echoed back on BID/RID — this slave never reorders across IDs, so echo-back is all AXI4 ID
// matching requires.
//
// Full AXI4 per requirement, but only ever a single 32-bit beat at a time is expected — AWLEN/ARLEN
// beyond 0 are not supported (this slave always completes exactly one data beat per transaction,
// asserting WLAST/RLAST on it regardless of what was requested).
//
// Register map (byte offsets from FLR_BASE_OFFSET = 0xC00 by default, all 32-bit; e.g. VERSION is at
// 0xC00, FLR_START at 0xC0C, FLR_DONE at 0xC10, FLR_ERROR at 0xC14 from the aperture base):
//   0x00  VERSION     RO  - same value as axil_slave.sv's VERSION register (both driven by the
//                    VERSION_VALUE parameter from pl_example: [31:16]=0xAA00, [15]=multi-function)
//   0x04  SCRATCH0    RW  - scratch
//   0x08  SCRATCH1    RW  - scratch
//   0x0C  FLR_START   RW  - bit[0] = FLR start, bits[31:16] = function number to FLR. Self-clearing:
//                           this slave resets the whole register to 0 one cycle after a write commits
//                           with bit[0]=1, so a readback can never observe stale start=1/old-function
//                           data from a previous request (host/R5 never needs to clear it themselves).
//   0x10  FLR_DONE    RW  - bit[0] = FLR done, bits[31:16] = function number that completed FLR.
//                           Clear-on-read: an AXI read of this register returns the current value,
//                           then atomically clears it to 0 the same cycle -- firmware does not need
//                           to explicitly write 0 before polling again (an explicit write still
//                           works too, but is redundant). A same-cycle flr_done_wr or AXI write
//                           still takes priority over the read-clear (see always_ff below).
//   0x14  FLR_ERROR   RW  - bit[0] = error/timeout occurred, bits[15:1] = reserved/detail bits
//                           (currently: which of the PF's VFs never responded, packed by
//                           pl_example's controller), bits[31:16] = the PF function number the
//                           error occurred on. Sticky like FLR_DONE — host/R5 clears by writing 0.
//
// FLR_START/FLR_DONE/FLR_ERROR remain plain AXI-visible read/write storage (host/R5 can always
// read the last-seen value of any of them), but this slave has no PF/VF awareness of its own —
// that decode lives in pl_example's FLR controller, which is why the actual FLR_START/FLR_DONE
// *behavior* (deciding what a given function number means, and when to auto-complete vs. really
// act) is exposed here only as generic event ports:
//   - flr_start_pulse/flr_start_func_num: 1-cycle strobe + captured bits[31:16] the cycle an AXI
//     write commits FLR_START with bit[0]=1 set.
//   - flr_done_wr/flr_done_func_num: pl_example's FLR controller pulses this to make this slave
//     set FLR_DONE = {func_num, bit[0]=1} on its own (e.g. auto-echoing a VF-originated FLR_START
//     with nothing else for PL to do, or completing a PF-broadcast sequence) — this takes
//     priority over a same-cycle AXI write to FLR_DONE, since it reflects real completion state.
//   - flr_error_wr/flr_error_data: same idea for FLR_ERROR — pl_example's controller passes the
//     fully-packed 32-bit value (this slave doesn't interpret the field layout, just latches it).
//
// FIRMWARE PROTOCOL: FLR_START commit -> FLR_DONE update is a multi-cycle pipeline (write commits
// here -> flr_start_pulse -> pl_example's controller sets flr_done_wr -> FLR_DONE updates here).
// FLR_DONE is clear-on-read, so firmware's own prior poll (the read that observed the PREVIOUS
// request's bit[0]=1) already left FLR_DONE at 0 -- just write FLR_START, then poll-read FLR_DONE
// until bit[0]=1; that is always the fresh completion. Firmware no longer needs to explicitly
// write FLR_DONE=0 before starting a new poll. The one case this doesn't cover: if firmware abandons
// a poll loop without ever reading a stale bit[0]=1 back out, that value stays until some later read
// of this register (for any reason) clears it -- same caveat the old write-0 protocol had.

module flr_slave #(
    parameter logic [31:0] VERSION_VALUE = 32'hAA00_0003,
    // Offset of this register block inside the slave's address space (the PS LPD_AXI_PL aperture).
    // Only addr[15:6] is compared against this; addr[5:0] selects the register. Accesses outside the
    // block read 0 / ignore writes (still OKAY) instead of aliasing onto the registers.
    parameter logic [15:0] FLR_BASE_OFFSET = 16'h0C00
) (
    input  logic        clk,
    input  logic        reset_n,

    (* mark_debug = "true" *)output logic        flr_start_pulse,
    (* mark_debug = "true" *)output logic [15:0] flr_start_func_num,
    (* mark_debug = "true" *)input  logic        flr_done_wr,
    (* mark_debug = "true" *)input  logic [15:0] flr_done_func_num,
    (* mark_debug = "true" *)input  logic        flr_error_wr,
    (* mark_debug = "true" *)input  logic [31:0] flr_error_data,

    (* mark_debug = "true" *)input  logic [43:0] s_axi_awaddr,
    (* mark_debug = "true" *)input  logic [15:0] s_axi_awid,
    (* mark_debug = "true" *)input  logic [2:0]  s_axi_awprot,
    (* mark_debug = "true" *)input  logic [7:0]  s_axi_awlen,
    (* mark_debug = "true" *)input  logic [2:0]  s_axi_awsize,
    (* mark_debug = "true" *)input  logic [1:0]  s_axi_awburst,
    (* mark_debug = "true" *)input  logic        s_axi_awlock,
    (* mark_debug = "true" *)input  logic [3:0]  s_axi_awcache,
    (* mark_debug = "true" *)input  logic [3:0]  s_axi_awqos,
    (* mark_debug = "true" *)input  logic        s_axi_awvalid,
    (* mark_debug = "true" *)output logic        s_axi_awready,

    (* mark_debug = "true" *)input  logic [31:0] s_axi_wdata,
    (* mark_debug = "true" *)input  logic [3:0]  s_axi_wstrb,
    (* mark_debug = "true" *)input  logic        s_axi_wlast,
    (* mark_debug = "true" *)input  logic        s_axi_wvalid,
    (* mark_debug = "true" *)output logic        s_axi_wready,

    (* mark_debug = "true" *)output logic [15:0] s_axi_bid,
    (* mark_debug = "true" *)output logic [1:0]  s_axi_bresp,
    (* mark_debug = "true" *)output logic        s_axi_bvalid,
    (* mark_debug = "true" *)input  logic        s_axi_bready,

    (* mark_debug = "true" *)input  logic [43:0] s_axi_araddr,
    (* mark_debug = "true" *)input  logic [15:0] s_axi_arid,
    (* mark_debug = "true" *)input  logic [2:0]  s_axi_arprot,
    (* mark_debug = "true" *)input  logic [7:0]  s_axi_arlen,
    (* mark_debug = "true" *)input  logic [2:0]  s_axi_arsize,
    (* mark_debug = "true" *)input  logic [1:0]  s_axi_arburst,
    (* mark_debug = "true" *)input  logic        s_axi_arlock,
    (* mark_debug = "true" *)input  logic [3:0]  s_axi_arcache,
    (* mark_debug = "true" *)input  logic [3:0]  s_axi_arqos,
    (* mark_debug = "true" *)input  logic        s_axi_arvalid,
    (* mark_debug = "true" *)output logic        s_axi_arready,

    (* mark_debug = "true" *)output logic [31:0] s_axi_rdata,
    (* mark_debug = "true" *)output logic [15:0] s_axi_rid,
    (* mark_debug = "true" *)output logic [1:0]  s_axi_rresp,
    (* mark_debug = "true" *)output logic        s_axi_rlast,
    (* mark_debug = "true" *)output logic        s_axi_rvalid,
    (* mark_debug = "true" *)input  logic        s_axi_rready
);

localparam logic [1:0] AXI_OKAY = 2'b00;

localparam int REG_VERSION   = 6'h00;
localparam int REG_SCRATCH0  = 6'h04;
localparam int REG_SCRATCH1  = 6'h08;
localparam int REG_FLR_START = 6'h0C;
localparam int REG_FLR_DONE  = 6'h10;
localparam int REG_FLR_ERROR = 6'h14;
localparam logic [5:0] REG_NONE = 6'h3F; // not a register: decodes to the default (no-op / reads 0)

// Block decode: register offset when addr[15:6] hits FLR_BASE_OFFSET's block, else REG_NONE.
function automatic logic [5:0] reg_dec(input logic [43:0] a);
    return (a[15:6] == FLR_BASE_OFFSET[15:6]) ? a[5:0] : REG_NONE;
endfunction


logic [31:0] scratch0_r, scratch1_r;
logic [31:0] flr_start_r, flr_done_r, flr_error_r;
logic        flr_start_clr_r; // 1-cycle-delayed self-clear of flr_start_r after a start-write commits

// Write address/data channels may handshake on independent cycles (legal AXI4 master behavior,
// especially through a SmartConnect) — each is latched as soon as it arrives, and the register
// write commits once both halves of the same transaction are available. Same pattern as
// axil_slave.sv's AW/W independence fix.
logic [5:0]  awaddr_r;
logic [15:0] awid_r;
logic [31:0] wdata_r;
logic        aw_pending, w_pending;

assign s_axi_awready = !s_axi_bvalid && !aw_pending;
assign s_axi_wready  = !s_axi_bvalid && !w_pending;

(* mark_debug = "true" *)wire aw_hs   = s_axi_awvalid && s_axi_awready;
(* mark_debug = "true" *)wire w_hs    = s_axi_wvalid && s_axi_wready;
wire [31:0] flr_wdata_commit = w_hs ? s_axi_wdata : wdata_r;
wire aw_have = aw_pending || aw_hs;
// Gate commit on WLAST, not just "a W beat is available": a master that (illegally, since this
// slave only supports single-beat bursts) sends AWLEN>0 would otherwise have its first beat
// mistaken for transaction-complete, leaving later beats to orphan into w_pending and corrupt a
// later, unrelated transaction's commit. Beats before WLAST are silently drained (WREADY stays
// asserted so the master's burst doesn't stall) without being treated as a complete write.
wire w_have_final = w_pending || (w_hs && s_axi_wlast);

// Clear-on-read for FLR_DONE: any accepted AR hitting this register clears it the same cycle,
// using the pre-edge value the read-data path (below) is simultaneously capturing for RDATA.
wire flr_done_rd_clr = s_axi_arvalid && s_axi_arready && (reg_dec(s_axi_araddr) == REG_FLR_DONE);

always_ff @(posedge clk) begin
    if (!reset_n) begin
        scratch0_r    <= '0;
        scratch1_r    <= '0;
        flr_start_r   <= '0;
        flr_done_r    <= '0;
        flr_error_r   <= '0;
        s_axi_bvalid  <= 1'b0;
        s_axi_bresp   <= AXI_OKAY;
        s_axi_bid     <= '0;
        awaddr_r      <= '0;
        awid_r        <= '0;
        wdata_r       <= '0;
        aw_pending    <= 1'b0;
        w_pending     <= 1'b0;
        flr_start_pulse    <= 1'b0;
        flr_start_func_num <= '0;
        flr_start_clr_r    <= 1'b0;
    end else begin
        if (aw_hs) begin
            awaddr_r <= reg_dec(s_axi_awaddr);
            awid_r   <= s_axi_awid;
        end
        if (w_hs) wdata_r <= s_axi_wdata;

        flr_start_pulse <= 1'b0; // default: 1-cycle pulse, deasserts unless re-asserted below
        flr_start_clr_r <= 1'b0; // default: deasserts unless re-scheduled below

        if (flr_start_clr_r) begin
            // Self-clear scheduled by last cycle's start-write commit. Placed ahead of the
            // write-commit case below so a genuinely new same-cycle write to FLR_START (last
            // assignment wins) still overrides this stale-data cleanup.
            flr_start_r <= '0;
        end

        if (flr_done_wr) begin
            // Controller-driven completion takes priority over a same-cycle AXI write to FLR_DONE
            // or a same-cycle clear-on-read (below).
            flr_done_r <= {flr_done_func_num, 15'b0, 1'b1};
        end else if (flr_done_rd_clr) begin
            // An AXI write that also hits FLR_DONE this cycle still wins over this: its case in
            // the commit block below executes later in program order, so last-assignment-wins
            // gives it priority (same pattern flr_start_clr_r below relies on).
            flr_done_r <= '0;
        end
        if (flr_error_wr) begin
            // Controller-driven error report takes priority over a same-cycle AXI write to FLR_ERROR.
            flr_error_r <= flr_error_data;
        end

        if (aw_have && w_have_final) begin
            aw_pending <= 1'b0;
            w_pending  <= 1'b0;
            case (aw_hs ? reg_dec(s_axi_awaddr) : awaddr_r)
                REG_SCRATCH0:  scratch0_r  <= w_hs ? s_axi_wdata : wdata_r;
                REG_SCRATCH1:  scratch1_r  <= w_hs ? s_axi_wdata : wdata_r;
                REG_FLR_START: begin
                    flr_start_r <= flr_wdata_commit;
                    if (flr_wdata_commit[0]) begin
                        flr_start_pulse    <= 1'b1;
                        flr_start_func_num <= flr_wdata_commit[31:16];
                        flr_start_clr_r    <= 1'b1; // self-clear FLR_START one cycle from now
                    end
                end
                REG_FLR_DONE:  if (!flr_done_wr) flr_done_r <= flr_wdata_commit;
                REG_FLR_ERROR: if (!flr_error_wr) flr_error_r <= flr_wdata_commit;
                default: ; // VERSION is RO, unmapped offsets are no-ops
            endcase
            s_axi_bvalid <= 1'b1;
            s_axi_bresp  <= AXI_OKAY;
            s_axi_bid    <= aw_hs ? s_axi_awid : awid_r;
        end else begin
            if (aw_hs && !w_have_final) aw_pending <= 1'b1;
            if (w_hs && s_axi_wlast && !aw_have) w_pending <= 1'b1;

            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
        end
    end
end

assign s_axi_arready = !s_axi_rvalid;

always_ff @(posedge clk) begin
    if (!reset_n) begin
        s_axi_rvalid <= 1'b0;
        s_axi_rresp  <= AXI_OKAY;
        s_axi_rdata  <= '0;
        s_axi_rid    <= '0;
        s_axi_rlast  <= 1'b0;
    end else begin
        if (s_axi_arvalid && s_axi_arready) begin
            case (reg_dec(s_axi_araddr))
                REG_VERSION:   s_axi_rdata <= VERSION_VALUE;
                REG_SCRATCH0:  s_axi_rdata <= scratch0_r;
                REG_SCRATCH1:  s_axi_rdata <= scratch1_r;
                REG_FLR_START: s_axi_rdata <= flr_start_r;
                REG_FLR_DONE:  s_axi_rdata <= flr_done_r;
                REG_FLR_ERROR: s_axi_rdata <= flr_error_r;
                default:       s_axi_rdata <= 32'h0;
            endcase
            s_axi_rvalid <= 1'b1;
            s_axi_rresp  <= AXI_OKAY;
            s_axi_rid    <= s_axi_arid;
            s_axi_rlast  <= 1'b1; // single beat only
        end else if (s_axi_rvalid && s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
        end
    end
end

endmodule
