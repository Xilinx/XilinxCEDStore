
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
// File       : BMD_AXIST_RX_PACKER.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_RX_PACKER.sv
//--
//-- Description: Takes per slot buffer output and reforms RX interface (by
//--                generating sidebands)
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_RX_PACKER
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
(
    input  logic                                            clk,
    input  logic                                            rst_n,
    input  logic                                            packer_rd_en, // only assert when credits avail
    input  logic [NUM_SLOTS-1:0][ENCODING_WIDTH_RX-1:0]     slots,
    input  logic [NUM_SLOTS-1:0]                            valid,
    output rx_intf                                          rx,

    output logic [31:0]                                     debug
);

// Register content from arbiter
logic [NUM_SLOTS-1:0][ENCODING_WIDTH_RX-1:0]   slots_r;
logic [NUM_SLOTS-1:0]                          valid_r;
logic [NUM_SLOTS-1:0][ENCODING_WIDTH_RX-1:0]   next_slots;
logic [NUM_SLOTS-1:0]                          next_valid;

logic [$clog2(NUM_SLOTS):0]                    read_ptr_r, next_read_ptr;
logic [NUM_SLOTS-1:0][$clog2(NUM_SLOTS):0]     read_ptrs;

// Start and end pointer counts
logic [$clog2(NUM_SLOTS)-1:0]   used_start;
logic [$clog2(NUM_SLOTS)-1:0]   used_end;
logic [$clog2(NUM_SLOTS)-1:0]   vld_cnt;

rx_fifo_intf [NUM_SLOTS-1:0]    fifo_slots_r;
always_comb begin
    for (int i = 0; i < NUM_SLOTS; i++) begin
        fifo_slots_r[i] = slots_r[i];
    end
end

always_comb begin
    debug = '0;
    case (NUM_SLOTS)
        1 : begin
            debug = {
                fifo_slots_r[0].pnp_info,
                fifo_slots_r[0].pend,
                fifo_slots_r[0].ptype,
                fifo_slots_r[0].pstart,
                valid_r[0],
                read_ptr_r
            };
        end

        2 : begin
            debug = {
                fifo_slots_r[1].pnp_info,
                fifo_slots_r[0].pnp_info,
                fifo_slots_r[1].pend,
                fifo_slots_r[0].pend,
                fifo_slots_r[1].ptype,
                fifo_slots_r[0].ptype,
                fifo_slots_r[1].pstart,
                fifo_slots_r[0].pstart,
                valid_r[1],
                valid_r[0],
                read_ptr_r
            };
        end

        default : begin
            debug = {
                fifo_slots_r[2].pnp_info,
                fifo_slots_r[1].pnp_info,
                fifo_slots_r[0].pnp_info,
                fifo_slots_r[2].pend,
                fifo_slots_r[1].pend,
                fifo_slots_r[0].pend,
                fifo_slots_r[2].ptype,
                fifo_slots_r[1].ptype,
                fifo_slots_r[0].ptype,
                fifo_slots_r[2].pstart,
                fifo_slots_r[1].pstart,
                fifo_slots_r[0].pstart,
                valid_r[2],
                valid_r[1],
                valid_r[0],
                read_ptr_r
            };
        end
    endcase
end

always_comb begin
    next_slots = '0;
    next_valid = '0;
    next_read_ptr = read_ptr_r;
    for (int i = 0; i < NUM_SLOTS; i++) begin
        if (valid[read_ptrs[i]]) begin
            next_valid[i] = 1'b1;
            next_slots[i] = slots[read_ptrs[i]];
            next_read_ptr = next_read_ptr + 1;
        end else begin
            break;
        end
    end
    next_read_ptr = next_read_ptr % NUM_SLOTS;
end

always_comb begin
    for (int unsigned i = 0; i < NUM_SLOTS; i++) begin
        read_ptrs[i] = (read_ptr_r + i) % NUM_SLOTS;
    end
end

// Pipeline slots/valid content due to arb logic
always @(posedge clk) begin
    if (!rst_n) begin
        slots_r <= '0;
        valid_r <= '0;
        read_ptr_r <= '0;
    end else begin
        if (packer_rd_en) begin
            slots_r <= next_slots;
            valid_r <= next_valid;
            read_ptr_r <= next_read_ptr;
        end
    end
end

always_comb begin
    // Defaults
    rx = '0;
    // Helper
    used_start      = '0;
    used_end        = '0;
    vld_cnt         = '0;

    for (int i = 0; i < NUM_SLOTS; i++) begin
        if (valid_r[i] == 1'b1) begin
            rx.rx_valid = 1'b1;

            if (fifo_slots_r[i].pstart) begin
                rx.rx_start[used_start] = 1'b1;
                rx.rx_startptr[used_start] = vld_cnt;
                rx.rx_starttype[used_start] = fifo_slots_r[i].ptype;
                rx.rx_startnpinfo[used_start] = fifo_slots_r[i].pnp_info;

                used_start = used_start + 1;
            end

            if (fifo_slots_r[i].pend) begin
                rx.rx_end[used_end] = 1'b1;
                rx.rx_endptr[used_end].ptr = vld_cnt;
                rx.rx_endptr[used_end].dptr = fifo_slots_r[i].pd_ptr;

                used_end = used_end + 1;
            end

            rx.rx_data[vld_cnt] = fifo_slots_r[i].pdata;
            vld_cnt = vld_cnt + 1;
        end
    end
end

endmodule // BMD_AXIST_RX_PACKER
