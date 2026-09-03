// MODULE : custom_axi_tg_csr
//
// DESCRIPTION:
// Destination-domain address decode for the whole 16-bit AXI-Lite map.  It owns
// the 192-bit iRAM assembly shadow register and its commit logic (including
// the addr_k clamp and the reserved-opcode check), the done_ptr CSR, the
// TG_BRESP_ERROR sticky log, the START/STOP pulse generation, the START_BUSY_ERR
// W1C decode and the read multiplexer (including the two-cycle iRAM read path).
// Splitting it out of custom_axi_tg_reg_space keeps every CDC flop inside one
// module so that a single SCOPED_TO_REF constraint file covers them.
//
// DETAILS:
//  0x0000 - 0x3FFF   iRAM window   (512 commands x 32 bytes)
//  0x4000 - 0x7FFF   unmapped      -> SLVERR, ERR_UNMAPPED
//  0x8000 - 0x80FF   control / status CSRs
//  0x8100 - 0x8FFF   unmapped      -> SLVERR, ERR_UNMAPPED
//  0x9000 - 0x97FF   per-command status readback (512 x 4 bytes)
//  0x9800 - 0xFFFF   unmapped      -> SLVERR, ERR_UNMAPPED
//
//  - Inside the iRAM window, cmd_idx = addr[13:5] and slice = addr[4:2].  A
//    command is assembled from slices 0..5 into a shadow register and COMMITS on
//    the write of slice 5 (+0x14), which carries data_stride.  Software must
//    therefore write +0x14 last, for EVERY command, including WAIT.  The
//    192-bit instruction word is six 32-bit slices, so slices 6 (+0x18) and 7
//    (+0x1C) are reserved and return SLVERR.  The per-command AXI-Lite stride
//    stays 32 bytes even though only 24 are used, so the decode remains a wire
//    split.
//  - addr_k values 27..31 are SILENTLY CLAMPED TO 26 AT COMMIT TIME, so the
//    value physically stored in the BRAM is 26 and a later iRAM read of the
//    entry shows the saturation.  This is NOT a programming error - no SLVERR
//    is raised - because the clamp is visible on readback, so software can see
//    exactly what it will execute.
//  - opcode 2'b11 is RESERVED: committing it returns SLVERR and sets
//    ERR_RSVD_OPCODE.
//  - While run_state != IDLE, EVERY access in 0x0000-0x3FFF returns SLVERR and
//    sets ERR_BUSY_IRAM; reads additionally return ASCII "BUSY".  Note that
//    writing TG_CTRL.START = 0 no longer returns the state to IDLE immediately
//    it moves to STOPPING, which is still "not IDLE", so the iRAM
//    stays blocked until the drain completes.  Software that wants to reprogram
//    after a stop must poll TG_STATUS.STATE until it reads IDLE.
//  - The CSR space and the per-command status window stay fully accessible while
//    running so that software can poll.
//  - Port B of the SDPRAM is borrowed for AXI-Lite readback only while the TG is
//    IDLE, i.e. only when the sequencer is not fetching.  The read address is
//    driven for one cycle and the data is captured two cycles later
//    (READ_LATENCY_B = 2).
//  - 0x8010 is RESERVED rather than reused, so the CSR offsets above it stay
//    where they are: it reads zero and writes to it are accepted with
//    BRESP = OKAY.
//
// RESTRICTIONS:
//  - The regbus is strictly single-outstanding: regbus_req is a level held until
//    the single-cycle regbus_done pulse.
//  - The assembly shadow is a single register, so two commands cannot be
//    programmed interleaved.  Crossing commands mid-assembly is caught by
//    ERR_ASSY_IDX; writing the slices of ONE command out of order is not
//    detected, because the shadow register has no per-slice written flags.
//
// ACRONYMS:
//  - assy = assembly (the multi-slice iRAM shadow register)
//  - CSR  = control / status register
//  - iRAM = instruction RAM

module custom_axi_tg_csr
  import custom_axi_tg_pkg::*;
#(
  parameter int  AXI_ADDRESS_WIDTH = 48,
  parameter int  AXI_ID_WIDTH      = 1,
  parameter bit  AXI_AXIL_SYNC     = 1'b0,
  parameter int  MAX_COMMANDS      = 32,
  parameter int  IRAM_WIDTH        = 192,
  parameter int  RING_DEPTH        = 8,
  parameter int  CPQ_DEPTH         = 2,
  localparam int IDX_W             = $clog2(MAX_COMMANDS),
  // Matches custom_axi_tg's CMD_PTR_W: fetch_ptr settles AT done_ptr (which
  // can legally equal MAX_COMMANDS) once a program finishes fetching, so
  // cur_cmd_ptr needs one bit more than IDX_W or that terminal value aliases
  // to 0. The TG_STATUS field itself stays a fixed 9 bits (see the read mux)
  // so the CSR map does not move if MAX_COMMANDS changes.
  localparam int CMD_PTR_W         = IDX_W + 1
)(
  input                         clk,                 // dest_clk
  input                         rstn,                // dest_rstn, active-low sync
  // dest-domain register bus from custom_axi_tg_reg_space
  input                         regbus_req,
  input                         regbus_we,
  input        [          15:0] regbus_addr,
  input        [          31:0] regbus_wdata,
  input        [           3:0] regbus_wstrb,
  output logic                  regbus_done,
  output logic [          31:0] regbus_rdata,
  output logic [           1:0] regbus_resp,
  // iRAM write port (port A of the SDPRAM)
  output logic                  iram_wen,
  output logic [           8:0] iram_waddr,
  output logic [IRAM_WIDTH-1:0] iram_wdata,
  // iRAM read port (port B) - borrowed only while run_state == IDLE
  output logic                  iram_csr_rd_req,
  output logic [           8:0] iram_csr_raddr,
  input        [IRAM_WIDTH-1:0] iram_rdata,          // valid 2 clks after raddr
  // control
  output logic                  start_pulse_int,
  output logic                  stop_pulse,
  output logic [           9:0] done_ptr,
  output logic                  prog_valid_set,
  output logic [           8:0] prog_valid_idx,
  // TG_CTRL.SOFT_RESET: one-cycle pulse clearing every programmed_valid bit
  // in custom_axi_tg_status (content and iRAM writes/reads are untouched)
  output logic                  prog_valid_clr_all,
  output logic                  start_busy_err_clr,  // W1C from TG_STATUS[22]
  // status inputs (all dest domain, no CDC)
  input        [           2:0] run_state,           // see ST_* in the package
  input        [ CMD_PTR_W-1:0] cur_cmd_ptr,
  input                         wr_disp_busy,
  input                         rd_disp_busy,
  input                         wr_ring_empty,
  input                         rd_ring_empty,
  input                         wr_ring_full,
  input                         rd_ring_full,
  input        [           1:0] wr_cpq_cnt,
  input        [           1:0] rd_cpq_cnt,
  input                         start_busy_err,      // sticky bit from the seq
  input                         wr_orphan_sticky,    // sticky W1C, TG_ORPHAN_RSP
  input        [           3:0] wr_orphan_axiid,
  output logic                  wr_orphan_clr,
  input                         rd_orphan_sticky,
  input        [           3:0] rd_orphan_axiid,
  output logic                  rd_orphan_clr,
  input        [           7:0] wr_ring_vld_vec,
  input        [           7:0] rd_ring_vld_vec,
  input        [           2:0] wr_ring_head,
  input        [           2:0] wr_ring_tail,
  input        [           3:0] wr_ring_count,
  input        [           2:0] rd_ring_head,
  input        [           2:0] rd_ring_tail,
  input        [           3:0] rd_ring_count,
  input        [           8:0] wr_cur_cmd_idx,
  input                         wr_cur_active,
  input        [           8:0] rd_cur_cmd_idx,
  input                         rd_cur_active,
  // per-command status readback
  output logic [           8:0] stat_rd_idx,
  input        [          20:0] stat_rd_data,        // 21 bits per command
  input                         any_cmd_err
);

  typedef enum logic [2:0] {
    C_IDLE, C_IRAM_L1, C_IRAM_L2, C_IRAM_L3, C_RESP, C_WAIT
  } cstate_e;
  cstate_e cstate;

  //--- address decode -------------------------------------------------------
  logic [8:0] a_cmd_idx;
  logic [2:0] a_slice;
  logic [8:0] a_stat_idx;
  logic       a_aligned;
  logic       in_iram, in_csr, in_stat;
  logic       running, start_busy;

  assign a_cmd_idx  = regbus_addr[13:5];
  assign a_slice    = regbus_addr[ 4:2];
  assign a_stat_idx = regbus_addr[10:2];
  assign a_aligned  = (regbus_addr[1:0] == 2'b00);
  assign in_iram    = (regbus_addr[15:14] == 2'b00);              // 0x0000-0x3FFF
  assign in_csr     = (regbus_addr[15:8]  == 8'h80);              // 0x8000-0x80FF
  assign in_stat    = (regbus_addr[15:11] == 5'b1001_0);          // 0x9000-0x97FF
  assign running    = (run_state != ST_IDLE);
  assign start_busy = (run_state != ST_IDLE) && (run_state != ST_ALL_RESPONDED);

  assign stat_rd_idx = a_stat_idx;

  //--- assembly shadow ------------------------------------------------------
  logic [IRAM_WIDTH-1:0] assy_shadow;
  logic [           8:0] assy_idx;
  logic [           5:0] assy_seen;    // one bit per 32-bit slice

  //--- CSR state ------------------------------------------------------------
  logic [ERR_BITS-1:0] bresp_err;
  logic [         8:0] first_err_idx;
  logic [         3:0] first_err_code;  // 4 bits now (0..8)

  //--- "highest contiguous programmed entry + 1", for the TG_DONE_PTR check --
  // This is a MONOTONIC HIGH-WATER MARK, deliberately NOT a run-time search of
  // the programmed_valid vector.  Two invariants make the register exact:
  //   1. programmed_valid[] bits are only ever SET; they are cleared only by
  //      aresetn, so shortening done_ptr is non-destructive.
  //   2. ERR_GAP forbids committing entry N unless N==0 or N-1 is already
  //      valid, so the valid vector is a CONTIGUOUS PREFIX at all times and
  //      can never contain a hole.
  // Therefore a successful commit of entry N can only ever be:
  //   N == prog_prefix -> extends the prefix by exactly one
  //   N <  prog_prefix -> re-writes an existing entry, prefix unchanged
  //   N >  prog_prefix -> impossible; ERR_GAP already rejected it
  // so the whole thing reduces to a conditional increment.  The old form was a
  // 32-deep serial ripple (each iteration depended on the previous compare and
  // increment) that fed the 10-bit TG_DONE_PTR comparator and gated iram_wen /
  // done_ptr, and it was the 333 MHz critical path at AXI_ID_WIDTH=4.
  // prog_prefix cannot run away past MAX_COMMANDS because a_cmd_idx >=
  // MAX_COMMANDS is already rejected with ERR_IDX_RANGE.
  logic [9:0] prog_prefix;

  //--- decoded read data for the iRAM slice mux -----------------------------
  // Six 32-bit slices with no ragged final word.  Slices 6 and 7 are
  // reserved and have already been rejected with ERR_RSVD_SLICE.
  logic [31:0] iram_slice_rd;
  always_comb begin
    case (a_slice)
      3'd0    : iram_slice_rd = iram_rdata[  0 +: 32];
      3'd1    : iram_slice_rd = iram_rdata[ 32 +: 32];
      3'd2    : iram_slice_rd = iram_rdata[ 64 +: 32];
      3'd3    : iram_slice_rd = iram_rdata[ 96 +: 32];
      3'd4    : iram_slice_rd = iram_rdata[128 +: 32];
      3'd5    : iram_slice_rd = iram_rdata[160 +: 32];
      default : iram_slice_rd = 32'h0000_0000;   // slices 6 and 7 are reserved
    endcase
  end

  //--- CSR read multiplexer -------------------------------------------------
  logic [31:0] csr_rd;
  logic        csr_hit;
  always_comb begin
    csr_rd  = 32'h0000_0000;
    csr_hit = 1'b1;
    case (regbus_addr[7:0])
      8'h00 : csr_rd = {31'h0, running};                       // TG_CTRL
      8'h04 : csr_rd = {22'h0, done_ptr};                      // TG_DONE_PTR
      8'h08 : csr_rd = {4'h0,                                  // TG_STATUS
                        rd_cpq_cnt,       //27:26
                        wr_cpq_cnt,       //25:24
                        any_cmd_err,      //23
                        start_busy_err,   //22  W1C
                        rd_ring_full,     //21
                        wr_ring_full,     //20
                        rd_ring_empty,    //19
                        wr_ring_empty,    //18
                        rd_disp_busy,     //17
                        wr_disp_busy,     //16
                        3'h0,             //15:13
                        9'(cur_cmd_ptr),  //12: 4 zero-extended; see CMD_PTR_W
                        1'b0,             //3
                        run_state};       //2: 0
      8'h0C : csr_rd = {7'h0,                                  // TG_BRESP_ERROR
                        first_err_code,   //24:21
                        first_err_idx,    //20:12
                        2'h0,             //11:10
                        bresp_err};       // 9: 0 (ERR_BITS=10)
      8'h10 : csr_rd = 32'h0000_0000;                          // reserved (was
                                                               // TG_LOOP_STATUS)
      8'h14 : csr_rd = TG_ID_VALUE;                            // TG_ID
      8'h18 : csr_rd = {2'(CPQ_DEPTH),                         // TG_CFG
                        4'(RING_DEPTH),             //29:26
                        10'(MAX_COMMANDS),          //25:16
                        3'h0,                       //15:13
                        AXI_AXIL_SYNC,              //12
                        4'(AXI_ID_WIDTH),           //11: 8
                        8'(AXI_ADDRESS_WIDTH)};     // 7: 0
      8'h1C : csr_rd = {8'h0,                                  // TG_ORPHAN_RSP
                        rd_orphan_axiid,  //23:20 nibble-aligned
                        3'h0,
                        rd_orphan_sticky, //16    RW1C
                        8'h0,
                        wr_orphan_axiid,  // 7: 4 nibble-aligned
                        3'h0,
                        wr_orphan_sticky};// 0    RW1C
      8'h20 : csr_rd = {8'h0,                                  // TG_RING_WR_STATUS
                        wr_ring_vld_vec,  //23:16
                        4'h0,             //15:12
                        wr_ring_count,    //11: 8
                        1'b0,             //7
                        wr_ring_tail,     //6: 4
                        1'b0,             //3
                        wr_ring_head};    //2: 0
      8'h24 : csr_rd = {8'h0,                                  // TG_RING_RD_STATUS
                        rd_ring_vld_vec,  //23:16
                        4'h0,             //15:12
                        rd_ring_count,    //11: 8
                        1'b0,             //7
                        rd_ring_tail,     //6: 4
                        1'b0,             //3
                        rd_ring_head};    //2: 0
      8'h28 : csr_rd = {10'h0,                                 // TG_CUR_CMD
                        rd_cur_active,    //21
                        rd_cur_cmd_idx,   //20:12
                        2'h0,             //11:10
                        wr_cur_active,    //9
                        wr_cur_cmd_idx};  // 8: 0
      default : csr_hit = 1'b0;
    endcase
  end

  //--------------------------------------------------------------------------
  // Access classification.  Evaluated combinationally from the held regbus
  // request; consumed once, in C_IDLE.
  //--------------------------------------------------------------------------
  logic       err_any;
  logic [3:0] err_code;
  logic [8:0] err_idx_val;
  logic       do_commit;

  logic       commit_gap, commit_rsvd_op;
  logic [1:0] shadow_opcode;

  assign shadow_opcode  = assy_shadow[IW_OPCODE_LSB +: 2];
  // By the contiguity invariant above, valid[N-1] is exactly N <= prog_prefix,
  // so the gap check is a compare against the high-water mark rather than an
  // indexed read of prog_valid_vec.  This removes the 32:1 index mux (and the
  // prog_valid_vec port itself) from this module.
  assign commit_gap     = ({1'b0, a_cmd_idx} > prog_prefix);
  assign commit_rsvd_op = (shadow_opcode == OP_RSVD);

  always_comb begin
    err_any     = 1'b0;
    err_code    = 4'(ERR_UNMAPPED);
    err_idx_val = 9'h000;
    do_commit   = 1'b0;

    if (!a_aligned) begin
      err_any  = 1'b1;
      err_code = 4'(ERR_UNMAPPED);
    end
    else if (in_iram) begin
      err_idx_val = a_cmd_idx;
      if (running) begin
        err_any  = 1'b1;
        err_code = 4'(ERR_BUSY_IRAM);
      end
      else if (a_slice >= 3'd6) begin
        err_any  = 1'b1;
        err_code = 4'(ERR_RSVD_SLICE);
      end
      else if (a_cmd_idx >= 9'(MAX_COMMANDS)) begin
        err_any  = 1'b1;
        err_code = 4'(ERR_IDX_RANGE);
      end
      else if (regbus_we && (a_slice != 3'd0) && (a_cmd_idx != assy_idx)) begin
        err_any  = 1'b1;
        err_code = 4'(ERR_ASSY_IDX);
      end
      else if (regbus_we && (a_slice == 3'd5) && commit_gap) begin
        err_any  = 1'b1;
        err_code = 4'(ERR_GAP);
      end
      else if (regbus_we && (a_slice == 3'd5) && commit_rsvd_op) begin
        err_any  = 1'b1;
        err_code = 4'(ERR_RSVD_OPCODE);
      end
      else if (regbus_we && (a_slice == 3'd5)) begin
        do_commit = 1'b1;
      end
    end
    else if (in_csr) begin
      if (!csr_hit) begin
        err_any  = 1'b1;
        err_code = 4'(ERR_UNMAPPED);
      end
      else if (regbus_we && (regbus_addr[7:0] == 8'h00) &&
               regbus_wdata[0] && start_busy) begin
        // Start while busy from the AXI-Lite side reports on the response
        // channel; the external pin sets TG_STATUS.START_BUSY_ERR instead.
        err_any  = 1'b1;
        err_code = 4'(ERR_START_BUSY);
      end
      else if (regbus_we && (regbus_addr[7:0] == 8'h00) &&
               !regbus_wdata[0] && regbus_wdata[1] && start_busy) begin
        // Soft reset (clears done_ptr / prog_prefix / every programmed_valid
        // bit, content untouched) is only meaningful from IDLE or
        // ALL_RESPONDED - the same states a fresh start is accepted from -
        // so it uses the same start_busy gate, not the stricter `running`.
        err_any  = 1'b1;
        err_code = 4'(ERR_SOFT_RST_BUSY);
      end
      else if (regbus_we && (regbus_addr[7:0] == 8'h04) && running) begin
        err_any  = 1'b1;
        err_code = 4'(ERR_BUSY_IRAM);
      end
      else if (regbus_we && (regbus_addr[7:0] == 8'h04) &&
               (regbus_wdata[9:0] > prog_prefix)) begin
        err_any  = 1'b1;
        err_code = 4'(ERR_DONE_PTR_RANGE);
      end
    end
    else if (in_stat) begin
      err_idx_val = a_stat_idx;
      if (a_stat_idx >= 9'(MAX_COMMANDS)) begin
        err_any  = 1'b1;
        err_code = 4'(ERR_IDX_RANGE);
      end
      else if (regbus_we) begin
        err_any  = 1'b1;                          // the window is read-only
        err_code = 4'(ERR_UNMAPPED);
      end
    end
    else begin
      err_any  = 1'b1;
      err_code = 4'(ERR_UNMAPPED);
    end
  end

  //--------------------------------------------------------------------------
  // addr_k clamp.  Values 27..31 are silently corrected to 26 AT COMMIT
  // TIME, so the value physically stored in the BRAM is 26 and
  // a later iRAM read of this entry shows the saturation.  This is NOT a
  // programming error -- no SLVERR is raised.  The clamp is unconditional on
  // the field (for WAIT the bits are reserved-zero, so 0 <= 26 and the clamp is
  // a no-op).
  //--------------------------------------------------------------------------
  logic [IRAM_WIDTH-1:0] commit_word;
  logic [           4:0] shadow_addr_k;
  assign shadow_addr_k = assy_shadow[IW_ADDR_K_LSB +: 5];

  always_comb begin
    commit_word = assy_shadow;
    commit_word[IW_ADDR_K_LSB +: 5] = (shadow_addr_k > 5'(ADDR_K_MAX))
                                        ? 5'(ADDR_K_MAX)
                                        : shadow_addr_k;
  end

  //--------------------------------------------------------------------------
  // Regbus handler
  //--------------------------------------------------------------------------
  logic bresp_err_clr;
  assign bresp_err_clr = regbus_we && a_aligned && in_csr &&
                         (regbus_addr[7:0] == 8'h0C) &&
                         (|regbus_wdata[ERR_BITS-1:0]);

  // TG_STATUS[22] is a W1C bit inside an otherwise read-only register.  The
  // clear is a single-cycle pulse to the sequencer, which owns the sticky
  // flop.
  assign start_busy_err_clr = (cstate == C_IDLE) && regbus_req &&
                              regbus_we && a_aligned && in_csr &&
                              (regbus_addr[7:0] == 8'h08) && regbus_wdata[22];

  // TG_ORPHAN_RSP[0] / [16] are RW1C, one per side, each clearing only its own
  // {sticky, axiid} pair.  The sticky flops live in each ring, not in this
  // module, so the pulse must be self-contained (qualified by cstate here)
  // rather than relying on a consumer-side gate.
  assign wr_orphan_clr = (cstate == C_IDLE) && regbus_req &&
                         regbus_we && a_aligned && in_csr &&
                         (regbus_addr[7:0] == 8'h1C) && regbus_wdata[0];
  assign rd_orphan_clr = (cstate == C_IDLE) && regbus_req &&
                         regbus_we && a_aligned && in_csr &&
                         (regbus_addr[7:0] == 8'h1C) && regbus_wdata[16];

  always_ff @(posedge clk) begin
    if (!rstn) begin
      cstate             <= C_IDLE;
      regbus_done        <= 1'b0;
      regbus_rdata       <= 32'h0000_0000;
      regbus_resp        <= RESP_OKAY;
      iram_wen           <= 1'b0;
      iram_waddr         <= 9'h000;
      iram_wdata         <= '0;
      iram_csr_rd_req    <= 1'b0;
      iram_csr_raddr     <= 9'h000;
      start_pulse_int    <= 1'b0;
      stop_pulse         <= 1'b0;
      done_ptr           <= 10'h000;
      prog_prefix        <= 10'h000;
      prog_valid_set     <= 1'b0;
      prog_valid_idx     <= 9'h000;
      prog_valid_clr_all <= 1'b0;
      assy_shadow        <= '0;
      assy_idx           <= 9'h000;
      assy_seen          <= 6'h00;
      bresp_err          <= '0;
      first_err_idx      <= 9'h000;
      first_err_code     <= 4'h0;
    end
    else begin
      regbus_done        <= 1'b0;
      iram_wen           <= 1'b0;
      iram_csr_rd_req    <= 1'b0;
      start_pulse_int    <= 1'b0;
      stop_pulse         <= 1'b0;
      prog_valid_set     <= 1'b0;
      prog_valid_clr_all <= 1'b0;

      case (cstate)
        //--------------------------------------------------------------------
        C_IDLE : begin
          if (regbus_req) begin
            regbus_resp  <= err_any ? RESP_SLVERR : RESP_OKAY;
            regbus_rdata <= 32'h0000_0000;

            //--- sticky error log ------------------------------------------
            if (err_any) begin
              bresp_err[err_code] <= 1'b1;
              if (bresp_err == '0) begin
                first_err_idx  <= err_idx_val;
                first_err_code <= err_code;
              end
            end

            //--- iRAM window -----------------------------------------------
            if (in_iram && a_aligned) begin
              if (running) begin
                // Reads return ASCII "BUSY" ('B' in [31:24]) rather than
                // whatever the iRAM happens to hold, so a readback while
                // running is unmistakable in a trace.
                regbus_rdata <= TG_BUSY_RDATA;
              end
              else if (regbus_we && !err_any) begin
                case (a_slice)
                  3'd0 : begin
                           assy_idx             <= a_cmd_idx;
                           assy_seen            <= 6'h01;
                           assy_shadow[  0+:32] <= regbus_wdata;
                         end
                  3'd1 : begin
                           assy_shadow[ 32+:32] <= regbus_wdata;
                           assy_seen[1]         <= 1'b1;
                         end
                  3'd2 : begin
                           assy_shadow[ 64+:32] <= regbus_wdata;
                           assy_seen[2]         <= 1'b1;
                         end
                  3'd3 : begin
                           assy_shadow[ 96+:32] <= regbus_wdata;
                           assy_seen[3]         <= 1'b1;
                         end
                  3'd4 : begin
                           assy_shadow[128+:32] <= regbus_wdata;
                           assy_seen[4]         <= 1'b1;
                         end
                  3'd5 : begin
                           // COMMIT.  shadow[191:160] comes from this wdata,
                           // and the addr_k clamp is applied on the way into
                           // the BRAM.
                           assy_shadow[160+:32] <= regbus_wdata;
                           assy_seen            <= 6'h00;
                           iram_wen             <= 1'b1;
                           iram_waddr           <= a_cmd_idx;
                           iram_wdata           <= {regbus_wdata,
                                                    commit_word[159:0]};
                           prog_valid_set       <= 1'b1;
                           prog_valid_idx       <= a_cmd_idx;
                           // max(), so programming commands out of order
                           // still extends done_ptr correctly.
                           if (({1'b0, a_cmd_idx} + 10'h001) > done_ptr)
                             done_ptr <= {1'b0, a_cmd_idx} + 10'h001;
                           // High-water mark: commit_gap already guarantees
                           // a_cmd_idx <= prog_prefix, so the only case that
                           // extends the contiguous prefix is equality.
                           if ({1'b0, a_cmd_idx} == prog_prefix)
                             prog_prefix <= prog_prefix + 10'h001;
                         end
                  default : ;                       // slices 6/7 already errored
                endcase
              end
              else if (!regbus_we && !err_any) begin
                iram_csr_rd_req <= 1'b1;
                iram_csr_raddr  <= a_cmd_idx;
              end
            end

            //--- CSR space ---------------------------------------------------
            if (in_csr && a_aligned && csr_hit) begin
              if (regbus_we) begin
                case (regbus_addr[7:0])
                  8'h00 : begin                             // TG_CTRL
                            if (regbus_wdata[0]) begin
                              // A start while busy has already been turned into
                              // SLVERR + ERR_START_BUSY above and must not run.
                              // done_ptr == 0 means "no program": accepted, but
                              // nothing runs and the state stays IDLE.
                              if (!start_busy && (done_ptr != 10'h000))
                                start_pulse_int <= 1'b1;
                            end
                            else begin
                              // A plain stop (wdata[1]=0) is unconditional,
                              // as always: err_any is guaranteed false here
                              // in that case, so this changes nothing for it.
                              // But wdata={1,0} while busy is REJECTED above
                              // (ERR_SOFT_RST_BUSY, err_any=1), and unlike the
                              // iRAM window nothing upstream of this case
                              // statement gates the action code on err_any
                              // (see the TG_DONE_PTR arm below, which
                              // re-checks it explicitly for the same reason)
                              // -- so without this guard a rejected soft
                              // reset would still stop the run it was
                              // supposed to leave untouched.
                              if (!err_any)
                                stop_pulse <= 1'b1;
                              // Soft reset: bit[0] must be 0 (never combined
                              // with a same-write start, which would race
                              // against the done_ptr!=0 check above).
                              // Content is untouched; only the bookkeeping
                              // that says what is programmed is cleared.
                              if (regbus_wdata[1] && !start_busy) begin
                                done_ptr           <= 10'h000;
                                prog_prefix        <= 10'h000;
                                prog_valid_clr_all <= 1'b1;
                              end
                            end
                          end
                  8'h04 : if (!err_any)                     // TG_DONE_PTR
                            done_ptr <= regbus_wdata[9:0];
                  default : ;                               // RO / W1C registers
                endcase
              end
              else begin
                regbus_rdata <= csr_rd;
              end
            end

            //--- per-command status window -----------------------------------
            // Layout: [0] freq, [1] fresp, [2] invalid, [3] is_slverr,
            // [4] programmed_valid, [7:5] rsvd, [19:8] first_invalid_number,
            // [23:20] first_invalid_axiid.
            if (in_stat && a_aligned && !regbus_we && !err_any)
              regbus_rdata <= {8'h00,
                               stat_rd_data[20:17],     // first_invalid_axiid
                               stat_rd_data[16: 5],     // first_invalid_number
                               3'h0,
                               stat_rd_data[ 4: 0]};    // pv/slverr/inv/fr/fq

            //--- next state --------------------------------------------------
            if (in_iram && a_aligned && !regbus_we && !err_any)
              cstate <= C_IRAM_L1;                          // 2-cycle BRAM read
            else
              cstate <= C_RESP;
          end
        end

        //--------------------------------------------------------------------
        // iram_csr_rd_req / iram_csr_raddr are REGISTERED, so the address is
        // presented on port B during C_IRAM_L1 and doutb is valid two clocks
        // later, i.e. during C_IRAM_L3.
        C_IRAM_L1 : cstate <= C_IRAM_L2;
        C_IRAM_L2 : cstate <= C_IRAM_L3;

        C_IRAM_L3 : begin
          regbus_rdata <= iram_slice_rd;                    // doutb is valid now
          cstate       <= C_RESP;
        end

        //--------------------------------------------------------------------
        C_RESP : begin
          regbus_done <= 1'b1;
          cstate      <= C_WAIT;
        end

        C_WAIT : begin
          if (!regbus_req)
            cstate <= C_IDLE;
        end

        default : cstate <= C_IDLE;
      endcase

      //--- TG_BRESP_ERROR is RW1C on [8:0]; writing a 1 to any of [8:0] clears
      //    the ENTIRE register, including the FIRST_* fields.  Applied after the
      //    case so it wins over a same-cycle error log.
      if ((cstate == C_IDLE) && regbus_req && bresp_err_clr) begin
        bresp_err      <= '0;
        first_err_idx  <= 9'h000;
        first_err_code <= 4'h0;
      end
    end
  end

endmodule
