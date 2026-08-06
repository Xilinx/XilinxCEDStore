
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
// File       : BMD_AXIST_RX_CPL_FILTER.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_RX_CPL_FILTER.sv
//--
//-- Description: Takes single RX stream and writes in-order to per-slot buffers.
//--              Encodes necessary information within each slots buffer (described
//--              in comments below)
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_RX_CPL_FILTER
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
(
    input  logic                                            clk,
    input  logic                                            rst_n,
    // From core
    input  rx_intf                                          rx,
    // To FIFOs (main)
    output logic [NUM_SLOTS-1:0]                            wr_en_main,
    output rx_fifo_intf [NUM_SLOTS-1:0]                     wr_data_main,
    // To FIFOs (cpl)
    output logic [NUM_SLOTS-1:0]                            wr_en_cpl,
    output rx_fifo_intf [NUM_SLOTS-1:0]                     wr_data_cpl,

    output logic [63:0]                                     rx_posted_header_count,
    output logic [63:0]                                     rx_nonposted_header_count,
    output logic [63:0]                                     rx_completion_header_count,
    output logic [63:0]                                     rx_data_count,

    output logic [31:0]                                     debug
);

// Helpers
localparam int                  NUM_SLOTS_m1 = NUM_SLOTS - 1;

rx_fifo_intf [NUM_SLOTS-1:0]    wr_data;
rx_fifo_intf [NUM_SLOTS-1:0]    wr_data_r;
logic [NUM_SLOTS-1:0]           wr_valid, wr_valid_r;

rx_intf                         rx_r, rx_r2;

// Used to track if there is "rollover" from one clk beat to the next
// This used to track implied valid slots between clk cycles.
logic [NUM_SLOTS-1:0]           is_start;
logic [NUM_SLOTS-1:0]           is_start_r;
logic                           pkt_in_prg;
logic                           pkt_in_prg_r;
logic [NUM_SLOTS-1:0]           pkt_in_prg_slot;
logic [NUM_SLOTS-1:0]           pkt_in_prg_slot_r;

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

// PME
BMD_PME_COUNTERS #(
    .IS_TX                  ( 1'b0 )
) EP_RX_PME_COUNTER (
    .clk                                ( clk ),
    .rst_n                              ( rst_n ),

    .rx_slots                           ( wr_data_r ),
    .tx_slots                           ( '0 ),
    .valid                              ( wr_valid_r ),

    .posted_header_count                ( rx_posted_header_count ),
    .nonposted_header_count             ( rx_nonposted_header_count ),
    .completion_header_count            ( rx_completion_header_count ),
    .data_count                         ( rx_data_count ),

    .debug                              ()
);


///////////////////////////////////////////////////////////////////
//
//            Encoding into FIFO format
//
///////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Filter
        wr_data_r           <= '0;
        wr_valid_r          <= '0;
        // Splitter
        rx_r                <= '0;
        rx_r2               <= '0;
        pkt_in_prg_r        <= '0;
        pkt_in_prg_slot_r   <= '0;
        set_end_r           <= '0;
        used_start_r        <= '0;
        used_end_r          <= '0;
        used_wr_r           <= '0;
        is_start_r          <= '0;
    end else begin
        // Filter
        wr_valid_r          <= wr_valid;
        wr_data_r           <= wr_data;
        // Splitter
        rx_r                <= rx;
        rx_r2               <= rx_r;
        pkt_in_prg_r        <= pkt_in_prg;
        pkt_in_prg_slot_r   <= pkt_in_prg_slot;
        set_end_r           <= set_end_w;
        used_start_r        <= used_start_w;
        used_end_r          <= used_end_w;
        used_wr_r           <= used_wr_w;
        is_start_r          <= is_start;
    end
end

// 1st pipeline - find which slots are start/end/in progress
always_comb begin
    // Defaults
    pkt_in_prg          = pkt_in_prg_r;

    used_start          = '0; // used to track how many starts of the 3 bit start have been used
    used_end            = '0; // used to track how many ends of the 3 bit end has been used
    used_wr             = '0; // used to track how much offset we need for wr signals

    set_end_w           = '0;
    used_start_w        = '0;
    used_end_w          = '0;
    used_wr_w           = '0;
    is_start            = '0;

    pkt_in_prg_slot     = pkt_in_prg_slot_r;

    if (rx_r.rx_valid) begin
        for (int i = 0; i < NUM_SLOTS; i++) begin
            set_end = 1'b0;
            // Packet ends in this slot
            if (rx_r.rx_end[used_end] && rx_r.rx_endptr[used_end].ptr == i) begin
                set_end = 1'b1;
            end

            used_start_w[i] = used_start;
            set_end_w[i] = set_end;
            used_end_w[i] = used_end;
            used_wr_w[i] = used_wr;
            pkt_in_prg_slot[i] = pkt_in_prg;

            // Packet starts in this slot
            if (rx_r.rx_start[used_start] && rx_r.rx_startptr[used_start] == i) begin
                is_start[i] = 1'b1;
                pkt_in_prg = 1'b1;
                if (rx_r.rx_starttype[used_start] != 2'b11) begin
                    used_wr = used_wr + 1;
                end
                used_start = used_start + 1;
            end else begin // Nothing started here; check for in prg
                if (pkt_in_prg) begin // Data packet
                    used_wr = used_wr + 1;
                end // else - Not valid packet
            end
            // If something ended in this slot, increment used_end and clear packet in progress
            if (rx_r.rx_end[used_end] && rx_r.rx_endptr[used_end].ptr == i) begin
                used_end = used_end + 1;
                pkt_in_prg = 1'b0;
            end
        end
    end
end

// 2nd pipeline - performs encoding of data
always_comb begin
    // Defaults
    wr_data             = '0;
    wr_valid            = '0;

    if (rx_r2.rx_valid) begin
        for (int j = 0; j < NUM_SLOTS; j++) begin
            // Packet starts in this slot
            if (is_start_r[j]) begin
                wr_valid[used_wr_r[j]]   = 1'b1;

                wr_data[used_wr_r[j]].pstart    = 1'b1;
                wr_data[used_wr_r[j]].ptype     = rx_r2.rx_starttype[used_start_r[j]];
                wr_data[used_wr_r[j]].pend      = set_end_r[j];
                wr_data[used_wr_r[j]].pnp_info  = rx_r2.rx_startnpinfo[used_start_r[j]];
                wr_data[used_wr_r[j]].pd_ptr    = set_end_r[j] ? rx_r2.rx_endptr[used_end_r[j]].dptr : 4'b0000;
                wr_data[used_wr_r[j]].pdata     = rx_r2.rx_data[j];
            end else begin // Nothing started here; check for in prg
                if (pkt_in_prg_slot_r[j]) begin // Data packet
                    wr_valid[used_wr_r[j]]   = 1'b1;

                    wr_data[used_wr_r[j]].pstart    = 1'b0;
                    wr_data[used_wr_r[j]].ptype     = 2'b11;
                    wr_data[used_wr_r[j]].pend      = set_end_r[j];
                    wr_data[used_wr_r[j]].pnp_info  = 3'b000;
                    wr_data[used_wr_r[j]].pd_ptr    = set_end_r[j] ? rx_r2.rx_endptr[used_end_r[j]].dptr : 4'b0000;
                    wr_data[used_wr_r[j]].pdata     = rx_r2.rx_data[j];
                end // else - Not valid packet
            end
        end
    end
end


///////////////////////////////////////////////////////////////////
//
//            Stream Preparation
//
///////////////////////////////////////////////////////////////////

logic               cpl_in_prog, cpl_in_prog_r;

rx_fifo_intf [NUM_SLOTS-1:0]       filter_data;
logic        [NUM_SLOTS-1:0]       filter_valid;
logic        [NUM_SLOTS-1:0]       filter; // 1 = cpl, 0 = other

rx_fifo_intf [NUM_SLOTS-1:0]       filter_data_r;
logic        [NUM_SLOTS-1:0]       filter_valid_r;
logic        [NUM_SLOTS-1:0]       filter_r; // 1 = cpl, 0 = other

// Create registers
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cpl_in_prog_r <= '0;
        filter_data_r <= '0;
        filter_valid_r <= '0;
        filter_r <= '0;
    end else begin
        cpl_in_prog_r <= cpl_in_prog;
        filter_data_r <= filter_data;
        filter_valid_r <= filter_valid;
        filter_r <= filter;
    end
end

// Label data cpl or main
always_comb begin
    cpl_in_prog = cpl_in_prog_r;
    filter_data = '0;
    filter_valid = '0;
    filter = '0;

    for (int i = 0; i < NUM_SLOTS; i++) begin // Look at each slot
        if (cpl_in_prog) begin // If cpl is in progress (from rollover or prev slot)
            if (wr_valid_r[i]) begin // packet is valid
                case(wr_data_r[i].ptype)
                    2'b11 : begin// Data
                        filter[i] = 1'b1;
                        filter_valid[i] = 1'b1;
                        filter_data[i] = wr_data_r[i];

                        if (wr_data_r[i].pend)
                            cpl_in_prog = 1'b0;
                    end

                    default : begin
                        filter[i] = '0;
                        filter_valid[i] = '0;
                        filter_data[i] = '0;
                        cpl_in_prog = 1'b0;
                    end
                endcase
            end
        end else begin  // Cpl not in progress
            if (wr_valid_r[i]) begin // packet is valid
                case(wr_data_r[i].ptype)
                    2'b00 : begin// Posted
                        filter[i] = 1'b0;
                        filter_valid[i] = 1'b1;
                        filter_data[i] = wr_data_r[i];
                    end

                    2'b01 : begin// NonPosted
                        filter[i] = 1'b0;
                        filter_valid[i] = 1'b1;
                        filter_data[i] = wr_data_r[i];
                    end

                    2'b10 : begin// Completion
                        filter[i] = 1'b1;
                        filter_valid[i] = 1'b1;
                        filter_data[i] = wr_data_r[i];

                        if (!wr_data_r[i].pend)
                            cpl_in_prog = 1'b1;
                    end

                    2'b11 : begin// Data
                        filter[i] = 1'b0;
                        filter_valid[i] = 1'b1;
                        filter_data[i] = wr_data_r[i];
                    end

                    default : begin
                        filter[i] = '0;
                        filter_valid[i] = '0;
                        filter_data[i] = '0;
                    end
                endcase
            end
        end
    end
end


///////////////////////////////////////////////////////////////////
//
//            Write to correct set of FIFOs
//
///////////////////////////////////////////////////////////////////
logic [NUM_SLOTS-1:0]                          next_wr_en_main;
logic [NUM_SLOTS-1:0][ENCODING_WIDTH_RX-1:0]   next_wr_data_main;

logic [NUM_SLOTS-1:0]                          next_wr_en_cpl;
logic [NUM_SLOTS-1:0][ENCODING_WIDTH_RX-1:0]   next_wr_data_cpl;

logic [$clog2(NUM_SLOTS)-1:0]                  used_write_cpl, used_write_main;

logic [$clog2(NUM_SLOTS)-1:0]                  ptr_main_r, next_ptr_main;
logic [NUM_SLOTS-1:0][$clog2(NUM_SLOTS)-1:0]   ptr_main ;

logic [$clog2(NUM_SLOTS)-1:0]                  ptr_cpl_r, next_ptr_cpl;
logic [NUM_SLOTS-1:0][$clog2(NUM_SLOTS)-1:0]   ptr_cpl ;

// Create registers
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_en_cpl <= '0;
        wr_data_cpl <= '0;
        wr_en_main <= '0;
        wr_data_main <= '0;

        ptr_main_r <= '0;
        ptr_cpl_r <= '0;
    end else begin
        wr_en_cpl <= next_wr_en_cpl;
        wr_data_cpl <= next_wr_data_cpl;
        wr_en_main <= next_wr_en_main;
        wr_data_main <= next_wr_data_main;

        ptr_main_r <= next_ptr_main;
        ptr_cpl_r <= next_ptr_cpl;
    end
end

// Assign data to corresponding fifo signals
always_comb begin
    used_write_cpl = '0;
    used_write_main = '0;

    next_wr_en_cpl = '0;
    next_wr_data_cpl = '0;
    next_wr_en_main = '0;
    next_wr_data_main = '0;

    for (int i = 0; i < NUM_SLOTS; i++) begin
        if (filter_valid_r[i]) begin
            case (filter_r[i])
                1'b0 : begin // Main
                    next_wr_data_main[ptr_main[used_write_main]] = filter_data_r[i];
                    next_wr_en_main[ptr_main[used_write_main]] = filter_valid_r[i];
                    used_write_main = used_write_main + 1;
                end

                1'b1 : begin // Completion
                    next_wr_data_cpl[ptr_cpl[used_write_cpl]] = filter_data_r[i];
                    next_wr_en_cpl[ptr_cpl[used_write_cpl]] = filter_valid_r[i];
                    used_write_cpl = used_write_cpl + 1;
                end

                default : begin
                    next_wr_data_cpl[ptr_cpl[used_write_cpl]] = '0;
                    next_wr_en_cpl[ptr_cpl[used_write_cpl]] = '0;
                    used_write_cpl = '0;
                end
            endcase
        end
    end
end

// Pointer offset logic (main)
always_comb begin
    for (int i = 0; i < NUM_SLOTS; i++) begin
        if (i == 0) begin
            ptr_main[i] = ptr_main_r;
        end else begin
            if (ptr_main[i-1] == NUM_SLOTS_m1)
                ptr_main[i] = '0;
            else
                ptr_main[i] = ptr_main[i-1] + 1;
        end
    end
end

// Pointer incrementing logic (main)
always_comb begin
    next_ptr_main = (ptr_main_r + used_write_main) % NUM_SLOTS;
end

// Pointer offset logic (cpl)
always_comb begin
    for (int i = 0; i < NUM_SLOTS; i++) begin
        if (i == 0) begin
            ptr_cpl[i] = ptr_cpl_r;
        end else begin
            if (ptr_cpl[i-1] == NUM_SLOTS_m1)
                ptr_cpl[i] = '0;
            else
                ptr_cpl[i] = ptr_cpl[i-1] + 1;
        end
    end
end

// Pointer incrementing logic (cpl)
always_comb begin
    next_ptr_cpl = (ptr_cpl_r + used_write_cpl) % NUM_SLOTS;
end

always_comb begin
    debug = '0;
    case (NUM_SLOTS)
        1 : begin
            debug = {
                wr_en_cpl[0],
                wr_en_main[0],
                wr_data_cpl[0].ptype,
                wr_data_main[0].ptype,
                ptr_cpl_r,
                ptr_main_r
            };
        end

        2 : begin
            debug = {
                wr_en_cpl[1],
                wr_en_cpl[0],
                wr_en_main[1],
                wr_en_main[0],
                wr_data_cpl[1].ptype,
                wr_data_cpl[0].ptype,
                wr_data_main[1].ptype,
                wr_data_main[0].ptype,
                ptr_cpl_r,
                ptr_main_r
            };
        end

        default : begin
            debug = {
                wr_en_cpl[2],
                wr_en_cpl[1],
                wr_en_cpl[0],
                wr_en_main[2],
                wr_en_main[1],
                wr_en_main[0],
                wr_data_cpl[2].ptype,
                wr_data_cpl[1].ptype,
                wr_data_cpl[0].ptype,
                wr_data_main[2].ptype,
                wr_data_main[1].ptype,
                wr_data_main[0].ptype,
                ptr_cpl_r,
                ptr_main_r
            };
        end
    endcase
end

endmodule // BMD_AXIST_RX_CPL_FILTER
