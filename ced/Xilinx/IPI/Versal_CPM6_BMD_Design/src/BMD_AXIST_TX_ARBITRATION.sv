
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
// File       : BMD_AXIST_TX_ARBITRATION.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_TX_ARBITRATION.sv
//--
//-- Description: Uses priority to select between different TX streams and
//--            tracks pointers for each streams per slot FIFOs
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_TX_ARBITRATION
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
#(
    parameter int                       NUM_STREAMS = 3
) (
    input  logic                        clk,
    input  logic                        rst_n,

    output logic [NUM_STREAMS-1:0][NUM_SLOTS-1:0]                           rd_en,
    input  tx_fifo_intf [NUM_STREAMS-1:0][NUM_SLOTS-1:0]                    dout,
    input  logic [NUM_STREAMS-1:0][NUM_SLOTS-1:0]                           empty,

    input  logic                                                            packer_rd_en,
    output logic [NUM_SLOTS-1:0][ENCODING_WIDTH_TX-1:0]                     slots,
    output logic [NUM_SLOTS-1:0]                                            valid,

    output logic [31:0]                                                     debug
);

localparam int NUM_SLOTS_m1 = NUM_SLOTS - 1;

logic [$clog2(NUM_STREAMS)-1:0]         last_sent, last_sent_r;

logic [NUM_STREAMS-1:0][$clog2(NUM_SLOTS)-1:0]                          ptr_r; // Base pointer to fifo
logic [NUM_STREAMS-1:0][$clog2(NUM_SLOTS)-1:0]                          next_ptr;
logic [NUM_STREAMS-1:0][NUM_SLOTS-1:0][$clog2(NUM_SLOTS)-1:0]           ptr; // offset ptr

logic [NUM_STREAMS-1:0][$clog2(NUM_SLOTS)-1:0]          used_wr;
logic                                                   inp_r, next_inp; // Track if we have rollover
logic [$clog2(NUM_STREAMS)-1:0]                         to_send, to_send_r, to_send_r_r; // Which stream to send next

logic [$clog2(NUM_SLOTS)-1:0]                           starts, ends; // used to compare if rollover

logic [NUM_STREAMS-1:0][NUM_SLOTS-1:0]                  empty_unpacked;
// Unpack part of empty for cleaner conditions
logic [NUM_STREAMS-1:0][NUM_SLOTS-1:0]                  rd_en_reg;
tx_fifo_intf [NUM_SLOTS-1:0]                            dout_r;
logic [NUM_SLOTS-1:0][$clog2(NUM_SLOTS)-1:0]            ptr_to_send_r;

logic [NUM_SLOTS-1:0][ENCODING_WIDTH_TX-1:0]            slots_w;
logic [NUM_SLOTS-1:0]                                   valid_w;

always_comb begin
    debug = '0;
    case (NUM_SLOTS)
        1 : begin
            debug = {
                to_send_r_r,
                ptr_to_send_r[0],
                rd_en_reg[to_send_r][0],
                dout_r[0].ptype
            };
        end

        2 : begin
            debug = {
                to_send_r_r,
                ptr_to_send_r[0],
                rd_en_reg[to_send_r][1],
                rd_en_reg[to_send_r][0],
                dout_r[1].ptype,
                dout_r[0].ptype
            };
        end

        default : begin
            debug = {
                to_send_r_r,
                ptr_to_send_r[0],
                rd_en_reg[to_send_r][2],
                rd_en_reg[to_send_r][1],
                rd_en_reg[to_send_r][0],
                dout_r[2].ptype,
                dout_r[1].ptype,
                dout_r[0].ptype
            };
        end
    endcase
end


// Unpack part of empty for cleaner conditions
always_comb begin
    empty_unpacked = '1;
    for (int i = 0; i < NUM_STREAMS; i++)
        for (int j = 0; j < NUM_SLOTS; j++)
            empty_unpacked[i][j] = empty[i][j];
end

// Registers
always_ff @(posedge clk) begin
    if (!rst_n) begin
        last_sent_r     <= '0;
        inp_r           <= '0;
        to_send_r       <= '0;
        to_send_r_r     <= '0;
        ptr_r           <= '0;
        rd_en_reg       <= '0;
        ptr_to_send_r   <= '0;
        valid           <= '0;
    end else begin
        if (packer_rd_en) begin
            dout_r <= dout[to_send_r];
            slots <= slots_w;
            valid <= valid_w;
            rd_en_reg <= rd_en;
            ptr_r <= next_ptr;
            ptr_to_send_r <= ptr[to_send_r];
            inp_r <= next_inp;
            to_send_r_r <= to_send_r;
            last_sent_r <= last_sent;
            to_send_r <= to_send;
        end
    end
end

// FIFO read control
always_comb begin
    // Default
    rd_en = '0;
    if (packer_rd_en) begin
        for (int i = 0; i < NUM_SLOTS; i++) begin
            if (empty_unpacked[to_send_r][i] == 1'b0) begin
                // Pop fifo
                rd_en[to_send_r][i] = 1'b1;
            end
        end
    end
end

always_comb begin
    valid_w = '0;
    slots_w = '0;
    for (int i = 0; i < NUM_SLOTS; i++) begin
        if (rd_en_reg[to_send_r_r][ptr_to_send_r[i]] == 1'b1) begin
            slots_w[i] = dout_r[ptr_to_send_r[i]];
            valid_w[i] = 1'b1;
        end
    end
end

// Select who to read from
always_comb begin
    // Default
    to_send = 'X;
    last_sent = last_sent_r;
    // only choose new if we dont have rollover
    if (!next_inp) begin
        if (empty_unpacked[0] != 3'b111) begin
            to_send = 0;
        end else begin
        // no priority was ready, look for any stream that has slot
        // ready to send
            for (int i = 1; i < NUM_STREAMS; i++) begin
                if (empty_unpacked[i] != 3'b111) begin
                    to_send = i;
                    last_sent = i;
                    if (i != last_sent_r)
                        break;
                end
            end
        end
    end else
        to_send = to_send_r;
end

always_comb begin
    // Defaults
    next_inp = inp_r;
    starts = '0;
    ends = '0;

    for (int i = 0; i < NUM_SLOTS; i++) begin
        if (empty_unpacked[to_send_r][i] == 1'b0) begin
            starts = packer_rd_en ? starts + dout[to_send_r][i].pstart : starts;
            ends = packer_rd_en ? ends + dout[to_send_r][i].pend : ends;
        end
    end

    // Assume no errors...
    // More ends than starts so our rollover should be gone
    if (ends > starts)
        next_inp = 1'b0;
    // More starts than ends then we have new rollover
    if (starts > ends)
        next_inp = 1'b1;
    // If starts == ends we keep our state
end

// Count used writes
always_comb begin
    // Default
    used_wr = '0;
    // Count rd en per stream
    for (int i = 0; i < NUM_STREAMS; i++) begin
        for (int j = 0; j < NUM_SLOTS; j++) begin
            if (rd_en[i][j] == 1'b1)
                used_wr[i] = used_wr[i] + 1;
        end
    end
end

// Pointer offset logic
always_comb begin
    for (int j = 0; j < NUM_STREAMS; j++) begin
        for (int i = 0; i < NUM_SLOTS; i++) begin
            if (i == 0) begin
                ptr[j][i] = ptr_r[j];
            end else begin
                if (ptr[j][i-1] == NUM_SLOTS_m1)
                    ptr[j][i] = '0;
                else
                    ptr[j][i] = ptr[j][i-1] + 1;
            end
        end
    end
end

// Pointer incrementing logic
always_comb begin
    // Default
    for (int i=0; i < NUM_STREAMS; i++)
        next_ptr[i] = ptr_r[i];
    // Increment pointers by amount read
    for (int i=0; i < NUM_STREAMS; i++)
        next_ptr[i] = (ptr_r[i] + used_wr[i]) % NUM_SLOTS;
end

endmodule // BMD_AXIST_TX_ARBITRATION
