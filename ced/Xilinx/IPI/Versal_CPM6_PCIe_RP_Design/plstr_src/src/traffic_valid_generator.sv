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

`timescale 1ps / 1ps

module traffic_valid_generator #(
    parameter MAX_PAYLOAD_SIZE = 128, // Default payload size
    parameter NUM_SLOTS = 3,
    parameter TAG_COUNT = 256,
    parameter TRAFFIC_COUNT = 1024, // Number of traffic transactions to generate
    parameter ACTUAL_PAYLOAD_SIZE_BYTE = 128 // Maximum payload size in bytes
) (
    input  logic                            clk,
    input  logic                            rst_n,
    input  logic                            link_down, 
    input  logic                            halt, 
    input  logic [$clog2(TAG_COUNT):0]      free_tag_count, // Input signal to determine if a tag is free
    input  logic                            traffic_enable, // Enable signal for traffic generation
    input  logic [$clog2(TRAFFIC_COUNT):0]  traffic_count, // Traffic count input

    output logic [NUM_SLOTS-1:0]            hdr_p_valid,
    output logic [NUM_SLOTS-1:0]            end_data_valid,
    output logic [NUM_SLOTS-1:0]            data_valid,
    output logic [NUM_SLOTS-1:0]            hdr_np_valid
);

    localparam MAX_SLOT_PAYLOAD_SIZE = 4;

    logic [$clog2(MAX_PAYLOAD_SIZE)-1:0]    payload_size_reg; // Current payload size register
    logic [NUM_SLOTS-1:0]                   hdr_p_valid_wire;
    logic [NUM_SLOTS-1:0]                   end_data_valid_wire;
    logic [NUM_SLOTS-1:0]                   data_valid_wire;
    logic [NUM_SLOTS-1:0]                   hdr_np_valid_wire;
    logic [NUM_SLOTS-1:0]                   data_valid_mid;

    logic                                   rcvd_np;

    logic [MAX_SLOT_PAYLOAD_SIZE-1:0]       rollover;
    logic [MAX_SLOT_PAYLOAD_SIZE-1:0]       next_rollover;

    logic [MAX_SLOT_PAYLOAD_SIZE-1:0]       rollover_reg;
    logic [MAX_SLOT_PAYLOAD_SIZE-1:0]       next_rollover_reg;

    logic                                   insert_next_hdr;  
    logic                                   insert_p_hdr, insert_np_hdr;
    logic                                   insert_end_data, insert_end_data_2;

    logic                                   traffic_enable_reg;
    logic                                   traffic_done;

    logic [$clog2(TRAFFIC_COUNT):0]         traffic_count_reg;

    assign payload_size_reg = (ACTUAL_PAYLOAD_SIZE_BYTE <= 64) ? 'b1 : 'b10; // SLOT based payload size

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            traffic_enable_reg <= 1'b0; // Reset traffic enable register
            traffic_count_reg <= '0; // Reset traffic count register
        end else if (link_down) begin
            traffic_enable_reg <= 1'b0; // Reset on link down
            traffic_count_reg <= '0; // Reset traffic count on link down
        end else if (halt) begin
            traffic_enable_reg <= traffic_enable_reg; // Maintain state on halt
            traffic_count_reg <= traffic_count_reg; // Maintain traffic count on halt
        end else begin
            traffic_enable_reg <= traffic_enable; // Update with current traffic enable signal
            if(!traffic_enable) begin
                traffic_count_reg <= traffic_count;
            end else begin
                if(NUM_SLOTS > 1) begin
                    traffic_count_reg <= traffic_count_reg - (|hdr_p_valid_wire); // Decrement traffic count based on header valid signals
                end
                else begin
                    traffic_count_reg <= traffic_count_reg - (hdr_p_valid_wire[0] ? 'b1 : 'b0); 
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset logic
            rollover_reg <= '0;
            next_rollover_reg <= '0; // Reset next rollover on reset
        end else if (link_down) begin
            // Handle link down condition
            rollover_reg <= '0; // Reset rollover on link down
            next_rollover_reg <= '0; // Reset next rollover on link down
        end
        else if (halt) begin
            // Handle halt condition
            rollover_reg <= rollover_reg; // Keep rollover unchanged on halt
            next_rollover_reg <= next_rollover_reg; // Keep next rollover unchanged on halt
        end else if (traffic_enable) begin
            if (~(free_tag_count > 2) ) begin
                rollover_reg <= next_rollover < payload_size_reg + 2 ? (next_rollover > NUM_SLOTS ? NUM_SLOTS : next_rollover) : '0; // Reset rollover if no free tags
                next_rollover_reg <= payload_size_reg + 2; // Reset next rollover
            end
            else if (insert_p_hdr) begin
                rollover_reg <= next_rollover;
                next_rollover_reg <= payload_size_reg + 2;
            end else begin
                rollover_reg <= rollover;
                next_rollover_reg <= next_rollover;
            end
        end
        else begin
            rollover_reg <= '0; // Set rollover to 0 when traffic is not enabled
            next_rollover_reg <= payload_size_reg + 2; // Set next rollover to payload size + 2 when traffic is not enabled
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            traffic_done <= '0;
        end else if (link_down) begin
            traffic_done <= '0; // Reset on link down
        end else if (halt) begin
            traffic_done <= traffic_done; // Maintain state on halt
        end else if (traffic_enable) begin
            if(NUM_SLOTS > 1) begin
                traffic_done <= (traffic_count_reg == 0 && next_rollover <= NUM_SLOTS) ? 1'b1 : traffic_done;
            end
            else begin
                traffic_done <= (traffic_count_reg == 0 && hdr_np_valid_wire[0]) ? 1'b1 : traffic_done;
            end
        end
    end

    assign insert_p_hdr = (rollover_reg < NUM_SLOTS && free_tag_count > 2);
    assign insert_np_hdr = (rollover_reg < (NUM_SLOTS+1) && |rollover_reg);
    assign insert_next_hdr = (next_rollover_reg < (NUM_SLOTS+1) && rollover_reg == '0);
    assign insert_end_data = (|(rollover_reg >> 1) && (rollover_reg < NUM_SLOTS+2));
    assign insert_end_data_2 = (rollover_reg == 0) && (payload_size_reg < NUM_SLOTS);
    always_comb begin
        // Combinational logic for rollover and next_rollover
        if(traffic_enable) begin
            if(insert_p_hdr) begin
                rollover = '0;
                next_rollover = next_rollover_reg + rollover_reg - NUM_SLOTS;
            end else begin
                rollover = rollover_reg - NUM_SLOTS;
                next_rollover = rollover_reg > NUM_SLOTS ? rollover_reg - NUM_SLOTS : payload_size_reg + 2;
            end
        end else begin
            rollover = '0;
            next_rollover = payload_size_reg + 2;
        end

    end

    always_comb begin
        end_data_valid_wire = '0; // Initialize end_data_valid_wire to zero
        data_valid_wire = '0; // Initialize data_valid_wire to zero
        hdr_p_valid_wire = '0; // Initialize hdr_p_valid_wire to zero
        hdr_np_valid_wire = '0; // Initialize hdr_np_valid_wire to zero
        // Assign header valid signals based on rollover and next_rollover
        for (int i = 0; i < NUM_SLOTS; i++) begin
            if(NUM_SLOTS > 1) begin
                if(insert_p_hdr && rollover_reg == i) begin 
                    hdr_p_valid_wire[i] = free_tag_count > 2 && traffic_count_reg > 0; // Header valid for this slot
                end
            end
            else begin
                if(insert_p_hdr) begin
                    hdr_p_valid_wire[0] = free_tag_count > 2 && traffic_count_reg > 0;
                end
            end

            if (!(insert_next_hdr) && ((i > rollover_reg && free_tag_count>2) || (|rollover_reg && i < rollover_reg-1))) begin
                data_valid_wire[i] = 1'b1; // Data valid for this slot
            end

            if(insert_next_hdr && (i > 0) && (i == (next_rollover_reg-1))) begin
                if(NUM_SLOTS == 3 && ACTUAL_PAYLOAD_SIZE_BYTE <= 64) begin
                    hdr_np_valid_wire[i] = free_tag_count > 2;
                    data_valid_wire[i-1] = free_tag_count > 2; // End data valid for this slot
                end else begin
                    hdr_np_valid_wire[i] = free_tag_count > 1;
                    data_valid_wire[i-1] = free_tag_count > 1; // End data valid for this slot
                end
            end
            else if(insert_np_hdr) begin 
                if(rollover_reg-1 == i) begin
                    hdr_np_valid_wire[i] = free_tag_count > 1; // Header valid for this slot
                end
            end

            if(insert_end_data) begin
                if(i == rollover_reg-2) begin
                    end_data_valid_wire[i] = 1'b1; // End data valid for this slot
                end else begin
                    end_data_valid_wire[i] = 1'b0; // No end data valid for this slot
                end
            end else if (insert_end_data_2) begin
                if(i == payload_size_reg) begin
                    end_data_valid_wire[i] = 1'b1; // End data valid for this slot
                end else begin
                    end_data_valid_wire[i] = 1'b0; // No end data valid for this slot
                end       
            end else if(!traffic_enable) begin
                if(i == payload_size_reg) begin
                    end_data_valid_wire[i] = 1'b1; // End data valid for this slot
                end else begin
                    end_data_valid_wire[i] = 1'b0; // No end data valid for this slot
                end
            end else begin
                end_data_valid_wire[i] = 1'b0; // No end data valid for this slot
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n ) begin
        if (!rst_n) begin
            // Reset output signals
            hdr_p_valid <= '0;
            end_data_valid <= '0;
            data_valid_mid <= '0;
            hdr_np_valid <= '0;
        end else if (link_down) begin
            // Handle link down condition
            hdr_p_valid <= '0; // Reset header valid on link down
            end_data_valid <= '0; // Reset end data valid on link down
            data_valid_mid <= '0; // Reset data valid on link down
            hdr_np_valid <= '0; // Reset non-posted header valid on link down
        end else if (halt) begin
            // Handle halt condition
            hdr_p_valid <= hdr_p_valid; // Keep header valid unchanged on halt
            end_data_valid <= end_data_valid; // Keep end data valid unchanged on halt
            data_valid_mid <= data_valid_mid; // Keep data valid unchanged on halt
            hdr_np_valid <= hdr_np_valid; // Keep non-posted header valid unchanged on halt
        end else if(!traffic_done) begin
            // Normal operation logic
            hdr_p_valid <= hdr_p_valid_wire;
            end_data_valid <= end_data_valid_wire;
            data_valid_mid <= data_valid_wire;
            hdr_np_valid <= hdr_np_valid_wire;
        end else begin
            hdr_p_valid <= '0;
            end_data_valid <= '0;
            data_valid_mid <= '0;
            hdr_np_valid <= '0;
        end
    end

    always_comb begin
        data_valid = data_valid_mid;
        rcvd_np = 1'b0;
        if(traffic_done && |hdr_np_valid) begin
            for(int i = 0; i < NUM_SLOTS; i++) begin
                data_valid[i] = rcvd_np ? 1'b0 : data_valid[i];
                rcvd_np = hdr_np_valid[i] ? 1'b1 : 1'b0;
            end
        end
        else begin
            data_valid = data_valid_mid;
        end
    end

endmodule