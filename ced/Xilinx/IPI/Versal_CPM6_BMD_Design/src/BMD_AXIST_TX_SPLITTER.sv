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
// File       : BMD_AXIST_TX_SPLITTER.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_TX_SPLITTER.sv
//--
//-- Description: Takes single TX stream and writes in-order to per-slot buffers.
//--              Encodes necessary information within each slots buffer (described
//--              in comments below)
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_TX_SPLITTER
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
(
    input  logic                                        clk,
    input  logic                                        rst_n,
    // From core
    input  tx_intf                                      tx,
    input  logic                                        halt,
    // To FIFOs
    output logic [NUM_SLOTS-1:0]                        wr_en,
    output tx_fifo_intf [NUM_SLOTS-1:0]                 wr_data,

    output logic [8:0]                                  debug
);

localparam int                  NUM_SLOTS_m1 = NUM_SLOTS - 1;

// we will use type value of 11 to mean data slot
// start [1 bit] + type [2 bits] + end [1 bit] + np_info [3 bits] + end_data_ptr [4 bits] + data [651 bits]
// total : 692 bits
tx_intf                         tx_r, tx_r2;
logic [$clog2(NUM_SLOTS)-1:0]   ptr_r, next_ptr;
// NOTE: these pointers are not FOR their respective slots.
// Instead they should be used for each valid slot.
// For example: if only slots 2/3 are valid then pointers
// at index 0 and 1 will be used for the FIFO's to add these
// slots to.
logic [NUM_SLOTS-1:0][$clog2(NUM_SLOTS)-1:0]   ptr;
logic [NUM_SLOTS-1:0][$clog2(NUM_SLOTS)-1:0]   ptr_reg;

// Used to track if there is "rollover" from one clk beat to the next
// This used to track implied valid slots between clk cycles.
logic                                           pkt_in_prg_r, pkt_in_prg;
logic [NUM_SLOTS-1:0]                           pkt_in_prg_slot;
logic [NUM_SLOTS-1:0]                           pkt_in_prg_slot_reg;

// Helper for tracking which start/end indexes have been used
// and tracking which FIFOs have been written to
logic                           set_end;
logic [$clog2(NUM_SLOTS)-1:0]   used_start, used_end, used_wr;

logic [NUM_SLOTS-1:0]                          set_end_w;
logic [NUM_SLOTS-1:0][$clog2(NUM_SLOTS)-1:0]   used_start_w;
logic [NUM_SLOTS-1:0][$clog2(NUM_SLOTS)-1:0]   used_end_w;
logic [NUM_SLOTS-1:0][$clog2(NUM_SLOTS)-1:0]   used_wr_w;

logic [NUM_SLOTS-1:0]                          set_end_r;
logic [NUM_SLOTS-1:0][$clog2(NUM_SLOTS)-1:0]   used_start_r;
logic [NUM_SLOTS-1:0][$clog2(NUM_SLOTS)-1:0]   used_end_r;
logic [NUM_SLOTS-1:0][$clog2(NUM_SLOTS)-1:0]   used_wr_r;

logic [NUM_SLOTS-1:0]                          wr_en_wire;
tx_fifo_intf [NUM_SLOTS-1:0]                   wr_data_wire;

always_comb begin
    debug = '0;
    case (NUM_SLOTS)
        1 : begin
            debug = {
                wr_en[0],
                wr_data[0].ptype
            };
        end

        2 : begin
            debug = {
                wr_en[1],
                wr_en[0],
                wr_data[1].ptype,
                wr_data[0].ptype
            };
        end

        default : begin
            debug = {
                wr_en[2],
                wr_en[1],
                wr_en[0],
                wr_data[2].ptype,
                wr_data[1].ptype,
                wr_data[0].ptype
            };
        end
    endcase
end


always_ff @(posedge clk) begin
    if (!rst_n) begin
        ptr_r           <= '0;
        tx_r.tx_valid   <= '0;
        tx_r2.tx_valid  <= '0;
        pkt_in_prg_r    <= '0;
        wr_en           <= '0;
        set_end_r       <= '0;
        used_start_r    <= '0;
        used_end_r      <= '0;
        used_wr_r       <= '0;
        ptr_reg         <= '0;
        pkt_in_prg_slot_reg <= '0;
    end else begin
        if (!halt) begin
            ptr_r           <= next_ptr;
            tx_r            <= tx;
            tx_r2           <= tx_r;
            pkt_in_prg_r    <= pkt_in_prg;
            wr_en           <= wr_en_wire;
            wr_data         <= wr_data_wire;
            set_end_r       <= set_end_w;
            used_start_r    <= used_start_w;
            used_end_r      <= used_end_w;
            used_wr_r       <= used_wr_w;
            ptr_reg         <= ptr;
            pkt_in_prg_slot_reg <= pkt_in_prg_slot;
        end
    end
end

always_comb begin
    // Defaults

    pkt_in_prg          = pkt_in_prg_r;

    used_start          = '0; // used to track how many starts of the 3 bit start have been used
    used_end            = '0; // used to track how many ends of the 3 bit end has been used
    used_wr             = '0; // used to track how much offset we need for wr signals

    set_end_w           = set_end_r;
    used_start_w        = used_start_r;
    used_end_w          = used_end_r;
    used_wr_w           = used_wr_r;
    pkt_in_prg_slot     = pkt_in_prg_slot_reg;

    if (tx_r.tx_valid) begin
        for (int i = 0; i < NUM_SLOTS; i++) begin
            set_end = 1'b0;
            // Packet ends in this slot
            if (tx_r.tx_end[used_end] && tx_r.tx_endptr[used_end].ptr == i) begin
                set_end = 1'b1;
            end

            used_start_w[i] = used_start;
            set_end_w[i] = set_end;
            used_end_w[i] = used_end;
            used_wr_w[i] = used_wr;

            // Packet starts in this slot
            if (tx_r.tx_start[used_start] && tx_r.tx_startptr[used_start] == i) begin
                pkt_in_prg = 1'b1;
                // What type of packet?
                pkt_in_prg_slot[i] = pkt_in_prg;
                if (tx_r.tx_starttype[used_start] != 2'b11) begin
                    used_wr = used_wr + 1;
                end
                used_start = used_start + 1;
            end else begin // Nothing started here; check for in prg
                pkt_in_prg_slot[i] = pkt_in_prg;
                if (pkt_in_prg) begin // Data packet
                    used_wr = used_wr + 1;
                end // else - Not valid packet
            end

            // If something ended in this slot, increment used_end and clear packet in progress
            if (tx_r.tx_end[used_end] && tx_r.tx_endptr[used_end].ptr == i) begin
                used_end = used_end + 1;
                pkt_in_prg = 1'b0;
            end
        end
    end
end

always_comb begin
    wr_en_wire               = '0;
    wr_data_wire             = '0;

    if (tx_r2.tx_valid) begin
        for (int j = 0; j < NUM_SLOTS; j++) begin
            if (tx_r2.tx_start[used_start_r[j]] && tx_r2.tx_startptr[used_start_r[j]] == j) begin
                wr_en_wire[ptr_reg[used_wr_r[j]]]               = 1'b1;
                wr_data_wire[ptr_reg[used_wr_r[j]]].pstart      = 1'b1;
                wr_data_wire[ptr_reg[used_wr_r[j]]].ptype       = tx_r2.tx_starttype[used_start_r[j]];
                wr_data_wire[ptr_reg[used_wr_r[j]]].pend        = set_end_r[j];
                wr_data_wire[ptr_reg[used_wr_r[j]]].pnp_info    = tx_r2.tx_startnpinfo[used_start_r[j]];
                wr_data_wire[ptr_reg[used_wr_r[j]]].pd_ptr      = set_end_r[j] ? tx_r2.tx_endptr[used_end_r[j]].dptr : 4'b0000;
                wr_data_wire[ptr_reg[used_wr_r[j]]].pdata       = tx_r2.tx_data[j];
            end else begin
                if (pkt_in_prg_slot_reg[j]) begin // Data packet
                    wr_en_wire[ptr_reg[used_wr_r[j]]]               = 1'b1;
                    wr_data_wire[ptr_reg[used_wr_r[j]]].pstart      = 1'b0;
                    wr_data_wire[ptr_reg[used_wr_r[j]]].ptype       = 2'b11;
                    wr_data_wire[ptr_reg[used_wr_r[j]]].pend        = set_end_r[j];
                    wr_data_wire[ptr_reg[used_wr_r[j]]].pnp_info    = 3'b000;
                    wr_data_wire[ptr_reg[used_wr_r[j]]].pd_ptr      = set_end_r[j] ? tx_r2.tx_endptr[used_end_r[j]].dptr : 4'b0000;
                    wr_data_wire[ptr_reg[used_wr_r[j]]].pdata       = tx_r2.tx_data[j];
                end // else - Not valid packet
            end
        end
    end
end

// Pointer offset logic
always_comb begin
    for (int i = 0; i < NUM_SLOTS; i++) begin
        if (i == 0) begin
            ptr[i] = ptr_r;
        end else begin
            if (ptr[i-1] == NUM_SLOTS_m1)
                ptr[i] = '0;
            else
                ptr[i] = ptr[i-1] + 1;
        end
    end
end

// Pointer incrementing logic
always_comb begin
    next_ptr = (ptr_r + used_wr) % NUM_SLOTS;
end

endmodule // BMD_AXIST_TX_SPLITTER
