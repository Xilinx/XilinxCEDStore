////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
////////////////////////////////////////////////////////////////////////

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_TX_PACKER.sv
//--
//-- Description: Takes per slot buffer output and reforms TX interface (by
//--                generating sidebands)
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_TX_PACKER
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
(
    input  logic                                           clk,
    input  logic                                           rst_n,
    input  logic                                           link_down_reset,

    output logic                                           inp,

    input  logic                                           packer_rd_en, // only assert when credits avail
    input  logic [NUM_SLOTS-1:0][ENCODING_WIDTH_TX-1:0]    slots,
    input  logic [NUM_SLOTS-1:0]                           valid,

    output tx_intf                                         tx,
    output logic [$clog2(NUM_SLOTS)-1:0]                   tx_credits_consumed
);

logic [$clog2(NUM_SLOTS)-1:0]    next_tx_credits_consumed;

// Register content from arbiter
logic [NUM_SLOTS-1:0][ENCODING_WIDTH_TX-1:0]   slots_r;
logic [NUM_SLOTS-1:0]                          valid_r;

// Start and end pointer counts
logic [$clog2(NUM_SLOTS)-1:0]       used_start;
logic [$clog2(NUM_SLOTS)-1:0]       used_end;
logic [$clog2(NUM_SLOTS)-1:0]       vld_cnt;

logic                               next_inp;

tx_fifo_intf [NUM_SLOTS-1:0]        fifo_slots_r;
always_comb begin
    for (int i = 0; i < NUM_SLOTS; i++) begin
        fifo_slots_r[i] = slots_r[i];
    end
end

// Pipeline slots/valid content due to arb logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n | link_down_reset) begin
        slots_r <= '0;
        valid_r <= '0;
        tx_credits_consumed <= '0;
        inp <= '0;
    end else begin
        if (packer_rd_en) begin
            tx_credits_consumed <= next_tx_credits_consumed;
            slots_r <= slots;
            valid_r <= valid;
            inp <= next_inp;
        end
    end
end

always_comb begin
    // Defaults
    tx              = '0;
    // Helper
    used_start      = '0;
    used_end        = '0;
    vld_cnt         = '0;

    next_inp        = 1'b0;

    // packer_rd_en = 1'b1; // use this for credit backpressure - NOTE: Changed to input, credit module associated with packer will set

    for (int i = 0; i < NUM_SLOTS; i++) begin
        if (valid_r[i] == 1'b1) begin
            tx.tx_valid = packer_rd_en;

            if (fifo_slots_r[i].pstart) begin
                tx.tx_start[used_start] = 1'b1;
                tx.tx_startptr[used_start] = vld_cnt;
                tx.tx_starttype[used_start] = fifo_slots_r[i].ptype;
                tx.tx_startnpinfo[used_start] = fifo_slots_r[i].pnp_info;
                used_start = used_start + 1;
            end

            if (fifo_slots_r[i].pend) begin
                tx.tx_end[used_end] = 1'b1;
                tx.tx_endptr[used_end].ptr = vld_cnt;
                tx.tx_endptr[used_end].dptr = fifo_slots_r[i].pd_ptr;

                used_end = used_end + 1;
            end

            tx.tx_data[vld_cnt] = fifo_slots_r[i].pdata;
            vld_cnt = vld_cnt + 1;
        end
    end

    if (used_start > used_end || (used_start == used_end && inp)) begin
        next_inp = 1'b1;
    end
end

always_comb begin
    next_tx_credits_consumed = '0;
    for (int i = 0; i < NUM_SLOTS; i++)
        next_tx_credits_consumed += valid[i];
end

endmodule // BMD_AXIST_TX_PACKER
