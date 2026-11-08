// AXI-Lite Slave Interface
// Address width : 64-bit
// Data width    : 32-bit  (wstrb = 4-bit byte enables)
//
// Register map (byte offset):
//   0x00         version           read-only constant = 32'hA400_0001
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
//   0x4C         dbg_pf_trigger    read-only: last accepted AW/trigger metadata
//                                             [2:0]=last_aw_pf_num [3]=last_aw_vfunc_active
//                                             [11:4]=last_aw_vfunc_num [16:12]=last_aw_word_idx
//                                             [17]=last_wr_bank_is_c2h [18]=last_wr_bank_is_h2c
//                                             [19]=last_trig_is_c2h [20]=last_trig_is_h2c
//   0x50-0x5C    dma_irq[127:0]    read-only status (4 x 32-bit)
//   0x60         chn_num status    read-only: [5:0]=h2c_chn_num, [21:16]=c2h_chn_num
//   0x64         irq_status        read-only: [0]=dma_irq_any [1]=msix_req [2]=msix_grant
//                                             [5:3]=sm_int [8:6]=sm_dbi [9]=start_int
//                                             [10]=grant_vld [11]=msix_error [17:12]=chn_num
//   0x68         msix_dbg_snapshot read-only: latched at req pulse
//                                             [10:0]=vector [13:11]=func [14]=vfunc_active
//                                             [22:15]=vfunc_num [24:23]=operation [25]=req
//                                             [28:26]=sm_dbi [31:29]=sm_int
//   0x6C         msix_dbg_events   read-only: [2:0] sticky req/grant/error pulses
//                                             [5:3]=sm_axilm [8:6]=sm_int [11:9]=sm_dbi
//   0x70         dma_irq_eligible0 read-only: dma_irq[31:0] (eligible channels)
//   0x74         dbg_ctx_addr      read-only: live aw_addr_lat[31:0]
//   0x78         dbg_ctx_data      read-only: live w_data_lat[31:0]
//   0x7C         dbi_status        read-only: [2:0]=sm_dbi [5:3]=sm_axilm [6]=st_dbi_wr
//                                            [7]=write_done [8]=aw_done [9]=w_done
//                                            [10]=pending_any_ack [11]=write_commit
//                                            [16:12]=wr_count [17]=is_c2h_lat
//                                            [18]=pending_c2h_ack [19]=pending_h2c_ack
//
// write_req / write_ack handshake:
//   write_req pulses HIGH for exactly one clock cycle when dst_hi is written in
//   either C2H bank (0x20) or H2C bank (0x40). Direction is inferred from bank.
//   The slave stalls further writes to the triggered bank only; the other bank
//   remains accessible while the DMA is in flight.
//
// Write channel:
//   AW and W channels accepted independently (either order).
//   Write commits and B response issues when both have been received.
//   Byte strobes (wstrb) are honoured per byte lane.
//
// Read channel:
//   AR accepted, register value returned the following cycle.

`timescale 1 ps / 1 ps

import axil_slave_pkg::*;

module axil_slave (
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

    // ---------- User-side outputs ----------
    output axil_regs_t  regs_out,   // 5 registers of the triggered set
    output logic        write_req,  // 1-cycle pulse when dst_hi (reg4) is written
    output logic        is_c2h,     // latched transfer direction from triggered bank (0=H2C, 1=C2H)
    input  logic        write_ack,  // release stall; allow next AXI write

    // ---------- AW user bits (sideband from cpm_user_aligner) ----------
    // Packed as: [0]=vfunc_active, [8:1]=vfunc_num[7:0], [11:9]=pf_num[2:0]
    input  logic [11:0] s_axil_awuser,
    output logic        vfunc_active,   // latched at AW accept
    output logic [7:0]  vfunc_num,
    output logic [2:0]  pf_num,

    // ---------- AR user bits (sideband from cpm_user_aligner) ----------
    input  logic [11:0] s_axil_aruser,
    output logic        ar_vfunc_active,   // latched at AR accept
    output logic [7:0]  ar_vfunc_num,
    output logic [2:0]  ar_pf_num,

    // ---------- Interrupt status store (driven by pl_example after DBI read) ----------
    input  logic        irq_status_wr,      // 1-cycle pulse: store irq_status_data in selected bank
    input  logic        irq_status_is_c2h,  // 1=C2H bank (0x24), 0=H2C bank (0x44)
    input  logic [31:0] irq_status_data,    // channel interrupt status value
    // ---------- Interrupt clear handshake ----------
    output logic        irq_clr_req_c2h,    // set when host writes 0x2C; cleared by irq_clr_done_c2h
    output logic        irq_clr_req_h2c,    // set when host writes 0x4C; cleared by irq_clr_done_h2c
    input  logic        irq_clr_done_c2h,   // 1-cycle pulse from pl_example: C2H clear sequence done
    input  logic        irq_clr_done_h2c,   // 1-cycle pulse from pl_example: H2C clear sequence done

    // ---------- Read-only debug status inputs ----------
    input  logic [127:0] dma_irq,           // reads at 0x50-0x5C
    input  logic [6:0]   h2c_chn_num,       // reads at 0x60 [5:0]
    input  logic [6:0]   c2h_chn_num,       // reads at 0x60 [21:16]
    input  logic [31:0]  irq_status,        // reads at 0x64
    input  logic [31:0]  msix_dbg_snapshot, // reads at 0x68
    input  logic [31:0]  msix_dbg_events,   // reads at 0x6C
    input  logic [31:0]  dma_irq_eligible0, // reads at 0x70
    // DBI status inputs from pl_example (for 0x7C dbi_status)
    input  logic [2:0]   sm_dbi,
    input  logic [2:0]   sm_axilm,
    input  logic         st_dbi_wr,
    input  logic         write_done,
    input  logic [4:0]   wr_count
);

    localparam logic [31:0] VERSION_REG = 32'hAA00_0002;

    // ----------------------------------------------------------------
    // Address decoding
    //   ADDR_LSB = 2  (divide byte addr by 4 to get word index)
    //   C2H context regs occupy word indices 4..8   (byte offsets 0x10..0x20)
    //   H2C context regs occupy word indices 12..16 (byte offsets 0x30..0x40)
    //   is_c2h is derived from trigger bank: 1=C2H, 0=H2C
    //   Debug status occupies word indices 20..31 (byte offsets 0x50..0x7C) — read-only
    // ----------------------------------------------------------------
    localparam int ADDR_LSB  = 2;
    localparam int NUM_REGS  = 5;
    localparam int REG_IDX_W = 3;   // ceil(log2(5)) = 3
    localparam int C2H_BASE_WI = 5'd4;
    localparam int H2C_BASE_WI = 5'd12;
    localparam int C2H_IRQ_STATUS_WI = 5'd9;
    localparam int C2H_IRQ_CLR_WI    = 5'd10;
    localparam int H2C_IRQ_STATUS_WI = 5'd17;
    localparam int H2C_IRQ_CLR_WI    = 5'd18;

    function automatic logic addr_valid (input logic [63:0] addr);
        addr_valid = (addr[1:0] == 2'b00);
    endfunction

    function automatic logic [REG_IDX_W-1:0] addr_idx (input logic [63:0] addr);
        addr_idx = addr[ADDR_LSB + REG_IDX_W - 1 : ADDR_LSB];
    endfunction

    // ----------------------------------------------------------------
    // Register file
    // ----------------------------------------------------------------
    logic [31:0] regs_c2h     [0 : NUM_REGS-1];
    logic [31:0] regs_h2c     [0 : NUM_REGS-1];
    logic        h2c_reg_written_sticky; // sticky: set on first H2C register write, cleared by reset
    logic [31:0] irq_status_reg_c2h;   // 0x24: C2H int-status (written by FPGA)
    logic [31:0] irq_status_reg_h2c;   // 0x44: H2C int-status (written by FPGA)
    logic [31:0] dbg_pf_trigger;       // 0x4C: last AW/trigger metadata
    logic        is_c2h_lat;       // latched from trigger bank at write_req time

    assign regs_out.reg0 = is_c2h_lat ? regs_c2h[0] : regs_h2c[0];
    assign regs_out.reg1 = is_c2h_lat ? regs_c2h[1] : regs_h2c[1];
    assign regs_out.reg2 = is_c2h_lat ? regs_c2h[2] : regs_h2c[2];
    assign regs_out.reg3 = is_c2h_lat ? regs_c2h[3] : regs_h2c[3];
    assign regs_out.reg4 = is_c2h_lat ? regs_c2h[4] : regs_h2c[4];
    assign is_c2h        = is_c2h_lat;

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

    assign vfunc_active = aw_user_lat[0];
    assign vfunc_num    = aw_user_lat[8:1];
    assign pf_num       = aw_user_lat[11:9];

    // ----------------------------------------------------------------
    // reg4_written: combinatorial — true when write_commit fires on dst_hi in
    //   either bank (C2H 0x20 or H2C 0x40).
    // ----------------------------------------------------------------
    logic reg4_written;
    logic c2h_reg4_written;
    logic h2c_reg4_written;
    logic write_commit;
    logic [4:0] aw_word_idx;

    assign aw_word_idx = aw_addr_lat[6:2];
    assign c2h_reg4_written = write_commit && (aw_word_idx == (C2H_BASE_WI + NUM_REGS - 1));
    assign h2c_reg4_written = write_commit && (aw_word_idx == (H2C_BASE_WI + NUM_REGS - 1));
    assign reg4_written = c2h_reg4_written || h2c_reg4_written;

    // ----------------------------------------------------------------
    // write_ack stall gate (bank-specific)
    //   pending_c2h_ack: set when C2H dst_hi (0x20) is written; cleared by
    //     write_ack when is_c2h_lat=1.
    //   pending_h2c_ack: set when H2C dst_hi (0x40) is written; cleared by
    //     write_ack when is_c2h_lat=0.
    //   Each pending only stalls writes that target its own bank, so the
    //   other bank's registers can be programmed while a DMA is in flight.
    // ----------------------------------------------------------------
    logic pending_c2h_ack;
    logic pending_h2c_ack;

    // Bank classification of incoming AW address (combinatorial from bus)
    logic incoming_is_c2h_bank;
    logic incoming_is_h2c_bank;
    assign incoming_is_c2h_bank = (s_axil_awaddr[6:2] >= C2H_BASE_WI) &&
                                   (s_axil_awaddr[6:2] <= C2H_IRQ_CLR_WI);
    assign incoming_is_h2c_bank = (s_axil_awaddr[6:2] >= H2C_BASE_WI) &&
                                   (s_axil_awaddr[6:2] <= H2C_IRQ_CLR_WI);

    // Bank classification of latched AW address (used to gate W channel)
    logic aw_lat_is_c2h_bank;
    logic aw_lat_is_h2c_bank;
    assign aw_lat_is_c2h_bank = (aw_word_idx >= C2H_BASE_WI) &&
                                 (aw_word_idx <= C2H_IRQ_CLR_WI);
    assign aw_lat_is_h2c_bank = (aw_word_idx >= H2C_BASE_WI) &&
                                 (aw_word_idx <= H2C_IRQ_CLR_WI);

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            pending_c2h_ack <= 1'b0;
            pending_h2c_ack <= 1'b0;
            is_c2h_lat      <= 1'b0;
        end else begin
            if (c2h_reg4_written)
                is_c2h_lat <= 1'b1;
            else if (h2c_reg4_written)
                is_c2h_lat <= 1'b0;
            else if (write_ack && is_c2h_lat)    // C2H DMA done → return to idle
                is_c2h_lat <= 1'b0;

            if (c2h_reg4_written && !write_ack)
                pending_c2h_ack <= 1'b1;
            else if (write_ack && is_c2h_lat)
                pending_c2h_ack <= 1'b0;

            if (h2c_reg4_written && !write_ack)
                pending_h2c_ack <= 1'b1;
            else if (write_ack && !is_c2h_lat)
                pending_h2c_ack <= 1'b0;
        end
    end

    // AW: stall only if the incoming address targets a bank with a pending ack
    assign s_axil_awready = ~aw_done
                          && ~(incoming_is_c2h_bank && pending_c2h_ack)
                          && ~(incoming_is_h2c_bank && pending_h2c_ack);

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

    // W: stall based on the latched AW bank (when aw_done); no stall before AW is captured
    assign s_axil_wready = ~w_done
                         && ~(aw_done && aw_lat_is_c2h_bank && pending_c2h_ack)
                         && ~(aw_done && aw_lat_is_h2c_bank && pending_h2c_ack);

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
            h2c_reg_written_sticky <= 1'b0;
            for (int i = 0; i < NUM_REGS; i++)
                regs_c2h[i] <= '0;
            for (int i = 0; i < NUM_REGS; i++)
                regs_h2c[i] <= '0;
        end else begin
            if (write_commit) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp  <= 2'b00;
                unique case (aw_word_idx)
                    5'd4:  regs_c2h[0] <= w_data_lat;                                            // 0x10 C2H size
                    5'd5:  regs_c2h[1] <= w_data_lat;                                            // 0x14 C2H src_lo
                    5'd6:  regs_c2h[2] <= w_data_lat;                                            // 0x18 C2H src_hi
                    5'd7:  regs_c2h[3] <= w_data_lat;                                            // 0x1C C2H dst_lo
                    5'd8:  regs_c2h[4] <= w_data_lat;                                            // 0x20 C2H dst_hi (trigger)
                    5'd12: begin h2c_reg_written_sticky <= 1'b1; regs_h2c[0] <= w_data_lat; end  // 0x30 H2C size
                    5'd13: begin h2c_reg_written_sticky <= 1'b1; regs_h2c[1] <= w_data_lat; end  // 0x34 H2C src_lo
                    5'd14: begin h2c_reg_written_sticky <= 1'b1; regs_h2c[2] <= w_data_lat; end  // 0x38 H2C src_hi
                    5'd15: begin h2c_reg_written_sticky <= 1'b1; regs_h2c[3] <= w_data_lat; end  // 0x3C H2C dst_lo
                    5'd16: begin h2c_reg_written_sticky <= 1'b1; regs_h2c[4] <= w_data_lat; end  // 0x40 H2C dst_hi (trigger)
                    default: ; // 0x28/0x48 IRQ clear handled in separate always_ff; others no-op
                endcase
            end else if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end

    // ----------------------------------------------------------------
    // write_req: 1-cycle pulse, registered from reg4_written
    //   Asserts in the same cycle as pending_ack goes high.
    // ----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!reset_n)
            write_req <= 1'b0;
        else
            write_req <= reg4_written;
    end

    // ----------------------------------------------------------------
    // irq_status_reg (0x24/0x44): written by FPGA via irq_status_wr pulse
    // ----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            irq_status_reg_c2h <= '0;
            irq_status_reg_h2c <= '0;
        end else if (irq_status_wr) begin
            if (irq_status_is_c2h)
                irq_status_reg_c2h <= irq_status_data;
            else
                irq_status_reg_h2c <= irq_status_data;
        end
    end

    // ----------------------------------------------------------------
    // irq_clr_req_c2h (0x28) / irq_clr_req_h2c (0x48)
    //   set when host writes corresponding offset; cleared by matching done pulse.
    // ----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!reset_n)
            irq_clr_req_c2h <= 1'b0;
        else if (irq_clr_done_c2h)
            irq_clr_req_c2h <= 1'b0;
        else if (write_commit && (aw_word_idx == C2H_IRQ_CLR_WI))
            irq_clr_req_c2h <= 1'b1;
    end

    // ----------------------------------------------------------------
    // dbg_pf_trigger (0x4C): captures AW sideband and trigger source context.
    // ----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            dbg_pf_trigger <= '0;
        end else begin
            if (write_commit) begin
                dbg_pf_trigger[2:0]   <= aw_user_lat[11:9]; // PF number from AW sideband
                dbg_pf_trigger[3]     <= aw_user_lat[0];    // vfunc_active
                dbg_pf_trigger[11:4]  <= aw_user_lat[8:1];  // vfunc_num
                dbg_pf_trigger[16:12] <= aw_word_idx;       // accepted word index
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

    always_ff @(posedge clk) begin
        if (!reset_n)
            irq_clr_req_h2c <= 1'b0;
        else if (irq_clr_done_h2c)
            irq_clr_req_h2c <= 1'b0;
        else if (write_commit && (aw_word_idx == H2C_IRQ_CLR_WI))
            irq_clr_req_h2c <= 1'b1;
    end

    // ----------------------------------------------------------------
    // Read path
    // ----------------------------------------------------------------
    logic [63:0] ar_addr_lat;
    logic [11:0] ar_user_lat;
    logic        ar_pending;

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
                unique case (ar_addr_lat[6:2])  // 5-bit word index
                    5'd0:  s_axil_rdata <= VERSION_REG;      // 0x00 version
                    5'd4:  s_axil_rdata <= regs_c2h[0];       // 0x10 C2H size
                    5'd5:  s_axil_rdata <= regs_c2h[1];       // 0x14 C2H src_lo
                    5'd6:  s_axil_rdata <= regs_c2h[2];       // 0x18 C2H src_hi
                    5'd7:  s_axil_rdata <= regs_c2h[3];       // 0x1C C2H dst_lo
                    5'd8:  s_axil_rdata <= regs_c2h[4];       // 0x20 C2H dst_hi
                    5'd9:  s_axil_rdata <= irq_status_reg_c2h;       // 0x24 C2H IRQ status
                    5'd10: s_axil_rdata <= {31'b0, irq_clr_req_c2h}; // 0x28 C2H IRQ clear pending
                    5'd12: s_axil_rdata <= regs_h2c[0];       // 0x30 H2C size
                    5'd13: s_axil_rdata <= regs_h2c[1];       // 0x34 H2C src_lo
                    5'd14: s_axil_rdata <= regs_h2c[2];       // 0x38 H2C src_hi
                    5'd15: s_axil_rdata <= regs_h2c[3];       // 0x3C H2C dst_lo
                    5'd16: s_axil_rdata <= regs_h2c[4];       // 0x40 H2C dst_hi
                    5'd17: s_axil_rdata <= irq_status_reg_h2c;       // 0x44 H2C IRQ status
                    5'd18: s_axil_rdata <= {31'b0, irq_clr_req_h2c}; // 0x48 H2C IRQ clear pending
                    5'd19: s_axil_rdata <= dbg_pf_trigger;            // 0x4C PF/trigger debug
                    5'd20: s_axil_rdata <= dma_irq[31:0];     // 0x50
                    5'd21: s_axil_rdata <= dma_irq[63:32];    // 0x54
                    5'd22: s_axil_rdata <= dma_irq[95:64];    // 0x58
                    5'd23: s_axil_rdata <= dma_irq[127:96];   // 0x5C
                    5'd24: s_axil_rdata <= {10'b0, c2h_chn_num[5:0], 10'b0, h2c_chn_num[5:0]}; // 0x60
                    5'd25: s_axil_rdata <= irq_status;         // 0x64
                    5'd26: s_axil_rdata <= msix_dbg_snapshot;  // 0x68
                    5'd27: s_axil_rdata <= msix_dbg_events;    // 0x6C
                    5'd28: s_axil_rdata <= dma_irq_eligible0;  // 0x70
                    5'd29: s_axil_rdata <= aw_addr_lat[31:0];  // 0x74 live context write address
                    5'd30: s_axil_rdata <= w_data_lat;         // 0x78 live context write data
                    5'd31: s_axil_rdata <= {7'b0,
                                            h2c_reg_written_sticky,    // [24] sticky: H2C else-if branch fired
                                            w_strb_lat,                // [23:20] byte enables of last write
                                            pending_h2c_ack,           // [19]
                                            pending_c2h_ack,           // [18]
                                            is_c2h_lat,                // [17]
                                            wr_count[4:0],             // [16:12]
                                            write_commit,              // [11]
                                            pending_c2h_ack | pending_h2c_ack, // [10]
                                            w_done,                    // [9]
                                            aw_done,                   // [8]
                                            write_done,                // [7]
                                            st_dbi_wr,                 // [6]
                                            sm_axilm,                  // [5:3]
                                            sm_dbi};                   // [2:0] 0x7C DBI status
                    default: s_axil_rdata <= 32'h0;
                endcase
            end else if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end

endmodule
