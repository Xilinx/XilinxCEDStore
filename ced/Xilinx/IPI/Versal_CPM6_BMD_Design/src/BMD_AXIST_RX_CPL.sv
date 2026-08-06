
//-----------------------------------------------------------------------------
//
// (c) Copyright 1995, 2007, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : Versal PCI Express Integrated Block
// File       : BMD_AXIST_RX_CPL.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_RX_CPL.sv
//--
//-- Description: Handles returned completions and stores relevant information
//--              in EP MEM. This informs user when reads are complete (once all
//--              completions are returned for all reads)
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_RX_CPL
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
(
    input  logic            clk,
    input  logic            rst_n,
    input  logic            init_rst_i,

    // From RX MUX
    input  rx_intf          rx_cpl,

    // Tag mgmt
    output logic [($clog2(NUM_SLOTS)>>1):0]           tag_valid,
    output logic [($clog2(NUM_SLOTS)>>1):0][9:0]      tag_released,

    // Stats
    output logic            read_done, // all reads received
    input  logic [31:0]     cpld_data, // compare to received completions
    input  logic [15:0]     mrd_count, // total number of memory reads
    output logic [31:0]     cpl_count, // total number of completions received
    output logic [31:0]     cpl_data_dw_count, // count of completion dwords received

    // Error signaling
    output logic            read_dma_err, // error flag for exp != act
    output logic [15:0]     cpl_ur_count, // number of UR completions received
    output logic [9:0]      cpl_ur_tag, // tag of last UR received

    output logic [31:0]     debug
);

logic   comb_reset;
assign  comb_reset = !rst_n || init_rst_i;

// Labels for cpl vs data
logic [NUM_SLOTS-1:0][2:0]     labels_r, labels_r_r; // 111 = invalid; 100 = cpl hdr; 101 = first data, 011 = last data, 001 = data; 000 = empty
logic [NUM_SLOTS-1:0][2:0]     next_labels;
logic [NUM_SLOTS-1:0][1:0]     addr_offset_r, next_addr_offset;
logic [NUM_SLOTS-1:0][1:0]     bc_dw_diff_r, next_bc_dw_diff;
logic [1:0]     curr_addr_offset, last_addr_offset;
logic [1:0]     curr_bc_dw_diff,  last_bc_dw_diff;

// Registers for output
logic [($clog2(NUM_SLOTS)>>1):0]        next_tag_valid;
logic [($clog2(NUM_SLOTS)>>1):0][9:0]   next_tag_released;
logic                                   next_read_done;
logic [31:0]                            next_cpl_count;
logic [31:0]    cpl_data_dw_count_r, next_cpl_data_dw_count;
logic [17:0]    cpl_data_dw_r, cpl_data_dw_this;
logic           read_dma_err_r, next_read_dma_err;
logic [15:0]    cpl_ur_count_r, next_cpl_ur_count;
logic [9:0]     cpl_ur_tag_r, next_cpl_ur_tag;

rx_intf         rx_cpl_r, rx_cpl_r_r, rx_cpl_r_r_r, next_cpl_r_r_r; // Register for incoming rx from mux

logic [NUM_SLOTS-1:0]       next_is_end, is_end_r, is_end_r_r;
logic [NUM_SLOTS-1:0][3:0]  next_dptr, dptr_r, dptr_r_r;
logic [NUM_SLOTS-1:0][3:0][$clog2(DATA_SLOT_WIDTH)-1:0] dptr_offset;

logic           first_data_r, first_data;

// Helpers for decoding
logic                           pkt_in_prg_r, pkt_in_prg;
logic [$clog2(NUM_SLOTS)-1:0]   used_start, used_end;

// Helpers for conditionals
logic [NUM_SLOTS-1:0]           byte_cnt_lt_dw_len;

assign cpl_data_dw_count    = cpl_data_dw_count_r;
assign read_dma_err         = read_dma_err_r;
assign cpl_ur_count         = cpl_ur_count_r;
assign cpl_ur_tag           = cpl_ur_tag_r;

always_comb begin
    debug = '0;
    case (NUM_SLOTS)
        1 : begin
            debug = {
                read_dma_err_r,
                read_done,
                tag_released[0],
                tag_valid[0],
                labels_r[0]
            };
        end

        2 : begin
            debug = {
                read_dma_err_r,
                read_done,
                tag_released[0],
                tag_valid[0],
                labels_r[1],
                labels_r[0]
            };
        end

        default : begin
            debug = {
                read_dma_err_r,
                read_done,
                tag_released[1],
                tag_released[0],
                tag_valid[1],
                tag_valid[0],
                labels_r[2],
                labels_r[1],
                labels_r[0]
            };
        end
    endcase
end

// Register rx input
always @(posedge clk) begin
    if(comb_reset) begin
        rx_cpl_r <= '0;
    end else begin
        rx_cpl_r <= rx_cpl;
    end
end

/////////////////////////////////////////////////////////////////////////////////////////
// Label rx slots as cpl headers or data
// Register again
/////////////////////////////////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (comb_reset) begin
        rx_cpl_r_r      <= '0;

        labels_r        <= '0;
        pkt_in_prg_r    <= '0;
        first_data_r    <= '0;
        bc_dw_diff_r    <= '0;

        last_bc_dw_diff     <= '0;
        last_addr_offset    <= '0;

        is_end_r            <= '0;
        dptr_r              <= '0;

        is_end_r_r          <= '0;
        dptr_r_r            <= '0;

        dptr_offset         <= '0;
        addr_offset_r       <= '0;
    end else begin
        rx_cpl_r_r          <= rx_cpl_r;
        for (int i = 0; i < NUM_SLOTS; i++) begin
            byte_cnt_lt_dw_len[i]  <= (rx_cpl_r_r.rx_data[i].cpl.byte_cnt
                                        <= ((rx_cpl_r_r.rx_data[i].cpl.dw_len << 2)
                                            - rx_cpl_r_r.rx_data[i].cpl.addr[1:0]));
        end
        labels_r            <= next_labels;
        pkt_in_prg_r        <= pkt_in_prg;
        first_data_r        <= first_data;
        bc_dw_diff_r        <= next_bc_dw_diff;
        last_addr_offset    <= curr_addr_offset;
        last_bc_dw_diff     <= curr_bc_dw_diff;

        is_end_r            <= next_is_end;
        dptr_r              <= next_dptr;

        is_end_r_r          <= is_end_r;
        dptr_r_r            <= dptr_r;

        for (int i = 0; i < NUM_SLOTS; i++) begin
            for (int k = 0; k < 4; k++) begin
                dptr_offset[i][k] <= (dptr_r[i] << 5) + (k << 3);
            end
        end

        addr_offset_r       <= next_addr_offset;
    end
end

always_comb begin
    // Defaults
    pkt_in_prg          = pkt_in_prg_r;
    first_data          = first_data_r;

    next_bc_dw_diff     = '0;
    curr_bc_dw_diff     = last_bc_dw_diff;

    curr_addr_offset    = last_addr_offset;
    next_addr_offset    = '0;

    next_labels         = '0;

    used_start          = '0;
    used_end            = '0;

    next_is_end         = '0;
    next_dptr           = '0;

    if (rx_cpl_r.rx_valid) begin
        for (int i = 0; i < NUM_SLOTS; i++) begin
            // Packet starts in this slot
            if (rx_cpl_r.rx_start[used_start] && rx_cpl_r.rx_startptr[used_start] == i) begin
                pkt_in_prg = 1'b1;
                // What type of packet?
                case (rx_cpl_r.rx_starttype[used_start])
                    2'b10: begin // Completion
                        next_labels[i] = 3'b100;
                        curr_addr_offset = rx_cpl_r.rx_data[i].cpl.addr[1:0];
                        if ((rx_cpl_r.rx_data[i].cpl.dw_len << 2) > rx_cpl_r.rx_data[i].cpl.byte_cnt) begin
                            curr_bc_dw_diff = (rx_cpl_r.rx_data[i].cpl.dw_len << 2) - rx_cpl_r.rx_data[i].cpl.byte_cnt - rx_cpl_r.rx_data[i].cpl.addr[1:0];
                        end
                    end

                    default: begin
                        // Should only receive completions
                        next_labels[i] = 3'b111;
                    end
                endcase
                used_start = used_start + 1;
            end else begin // nothing started here; check for in prg
                if (pkt_in_prg) begin
                    next_addr_offset[i] = curr_addr_offset;
                    next_bc_dw_diff[i] = curr_bc_dw_diff;
                    if (first_data == 1'b0) begin
                        next_labels[i] = 3'b101;
                        first_data = 1'b1;
                    end else begin
                        next_labels[i] = 3'b001;
                    end
                end else begin
                    next_labels[i] = 3'b000; // empty slot
                end
            end
            // If something ended in this slot, increment used_end and clear in prg
            if (rx_cpl_r.rx_end[used_end] && rx_cpl_r.rx_endptr[used_end].ptr == i) begin
                if (next_labels[i] != 3'b101) begin
                    next_labels[i] = 3'b011;
                end

                next_is_end[i]  = 1'b1;
                next_dptr[i]    = rx_cpl_r.rx_endptr[used_end].dptr;

                used_end = used_end + 1;
                pkt_in_prg = 1'b0;
                first_data = 1'b0;
            end
        end
    end
end

// Handle Completions
// Use rx_cpl_r_r and labels_r
logic [$clog2($clog2(NUM_SLOTS)>>1):0] num_tags_released; // index tags released

/////////////////////////////////////////////////////////////////////////////////////////
//              Handle Byte Enables
/////////////////////////////////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (comb_reset) begin
        labels_r_r      <= '0;
        rx_cpl_r_r_r    <= '0;
    end else begin
        labels_r_r      <= labels_r;
        rx_cpl_r_r_r    <= next_cpl_r_r_r;
    end
end

always_comb begin
    next_cpl_r_r_r = rx_cpl_r_r;

    for (int i = 0; i < NUM_SLOTS; i++) begin
        for (int j = 0; j < (DATA_SLOT_WIDTH >> 3); j++) begin
            if (labels_r[i] == 3'b101 && j < 4) begin // first be
                if (j < addr_offset_r[i]) begin
                    next_cpl_r_r_r.rx_data[i][(j << 3) +: 8] = cpld_data[((j % 4) << 3) +: 8];
                end
            end
            if (is_end_r[i]) begin // last be
                if (j >= (((dptr_r[i] + 1) << 2) - bc_dw_diff_r[i])) begin
                    next_cpl_r_r_r.rx_data[i][(j << 3) +: 8] = cpld_data[((j % 4) << 3) +: 8];
                end
            end
        end
    end
end

/////////////////////////////////////////////////////////////////////////////////////////
//          Completion header handling
/////////////////////////////////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (comb_reset) begin
        cpl_data_dw_r   <= '0;
    end else begin
        cpl_data_dw_r   <= cpl_data_dw_this;
    end
end

always_comb begin
    // Defaults
    num_tags_released   = '0;
    next_tag_valid      = '0;
    next_tag_released   = '0;

    next_read_done          = read_done;
    next_cpl_count          = cpl_count;
    next_cpl_ur_count       = cpl_ur_count_r;
    next_cpl_ur_tag         = cpl_ur_tag_r;
    next_cpl_data_dw_count  = cpl_data_dw_count_r + cpl_data_dw_r;
    cpl_data_dw_this        = '0;

    for (int i = 0; i < NUM_SLOTS; i++) begin
        if (labels_r_r[i] == 3'b100) begin
            if (byte_cnt_lt_dw_len[i]) begin
                next_cpl_count  = next_cpl_count + 1;

                // Handle tags released by completion
                next_tag_valid[num_tags_released] = 1'b1;
                next_tag_released[num_tags_released] = rx_cpl_r_r_r.rx_data[i].cpl.tag[9:0];
                num_tags_released = num_tags_released + 1;
            end

            // Update total dw count
            cpl_data_dw_this = cpl_data_dw_this + rx_cpl_r_r_r.rx_data[i].cpl.dw_len;

            // check for UR and update ur tag and count
            if (rx_cpl_r_r_r.rx_data[i].cpl.status == 3'b001) begin
                next_cpl_ur_tag = rx_cpl_r_r_r.rx_data[i].cpl.tag[9:0];
                next_cpl_ur_count = next_cpl_ur_count + 1;
            end
        end
    end

    // Check for done
    if (mrd_count > 0 && cpl_count == mrd_count) begin
        next_read_done = 1'b1;
    end
end

/////////////////////////////////////////////////////////////////////////////////////////
//          Completion data handling
/////////////////////////////////////////////////////////////////////////////////////////
always_comb begin
    // Defaults
    next_read_dma_err = read_dma_err_r;

    for (int i = 0; i < NUM_SLOTS; i++) begin
        if (labels_r_r[i] == 3'b001 || labels_r_r[i] == 3'b101 || labels_r_r[i] == 3'b011) begin
            for (int j = 0; j < (DATA_SLOT_WIDTH >> 5); j++) begin
                if ((j <= dptr_r_r[i] && is_end_r_r[i]) || !is_end_r_r[i]) begin
                    if (rx_cpl_r_r_r.rx_data[i].data[(j<<5) +: 32] != cpld_data) begin
                        next_read_dma_err = 1'b1;
                    end
                end
            end
        end
    end
end

// Register outputs
always @(posedge clk) begin
    if (comb_reset) begin
        tag_valid           <= '0;
        tag_released        <= '0;

        read_done           <= '0;
        cpl_count           <= '0;
        cpl_data_dw_count_r <= '0;

        read_dma_err_r      <= '0;
        cpl_ur_count_r      <= '0;
        cpl_ur_tag_r        <= '0;
    end else begin
        tag_valid           <= next_tag_valid;
        tag_released        <= next_tag_released;

        read_done           <= next_read_done;
        cpl_count           <= next_cpl_count;
        cpl_data_dw_count_r <= next_cpl_data_dw_count;

        read_dma_err_r      <= next_read_dma_err;
        cpl_ur_count_r      <= next_cpl_ur_count;
        cpl_ur_tag_r        <= next_cpl_ur_tag;
    end
end

endmodule // BMD_AXIST_RX_CPL
