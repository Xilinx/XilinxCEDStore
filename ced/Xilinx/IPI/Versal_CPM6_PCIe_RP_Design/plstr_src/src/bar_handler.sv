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

module bar_handler #(
    parameter NUM_BAR = 6,
    parameter ADDR_WIDTH = 64,
    parameter DATA_WIDTH = 32
)
(
    input  logic                                clk,
    input  logic                                rst_n,
    input  logic                                link_down, 
    input  logic                                start_processing,
    input  logic [NUM_BAR-1:0][DATA_WIDTH-1:0]  bar_values,
    output logic [NUM_BAR-1:0][DATA_WIDTH-1:0]  bar_sizes,
    output logic [NUM_BAR-1:0][DATA_WIDTH-1:0]  bar_bases,
    output logic                                processing_done, 
    output logic                                is_all_64bit_bar, 
    output logic [NUM_BAR-1:0]                  is_64bit_bar // 1 for 64-bit BAR, 0 for 32-bit BAR
);

    // State machine states
    typedef enum logic [4:0] {
        IDLE,
        BAR_SIZE,
        CALC_SIZES_32,
        CALC_SIZES_32_2,
        CALC_SIZES_64,
        CALC_SIZES_64_1,
        CALC_SIZES_64_2,
        CALC_SIZES_64_3,
        ASSIGN_BASES,
        ASSIGN_32_BAR,
        ASSIGN_64_BAR,
        ASSIGN_64_BAR_2,
        ASSIGN_64_BAR_3,
        SORT_32_BAR_1,
        SORT_32_BAR_2,
        SORT_32_BAR_3,
        ASSIGN_32_BAR_2,
        ASSIGN_32_BAR_3,
        ASSIGN_32_BAR_LAST,
        SORT_64_BAR_1,
        SORT_64_BAR_2,
        SORT_64_BAR_3,
        ASSIGN_64_BAR_4,
        ASSIGN_64_BAR_LAST,
        DONE
    } state_t;
    
    // State registers and control signals
    state_t                 current_state, next_state;
    logic [31:0]            next_mem_addr, next_mem_addr_comb;
    logic [63:0]            next_mem_addr_2, next_mem_addr_comb_2;
    logic [31:0]            next_mem_addr_comb_2_low, next_mem_addr_comb_2_low_reg;
    logic [31:0]            next_mem_addr_comb_2_high, next_mem_addr_comb_2_high_reg;
    logic                   next_mem_addr_carry_low, next_mem_addr_carry_low_reg;
    logic [2:0]             current_bar, current_bar_comb, current_bar_2, current_bar_comb_2;
    logic [NUM_BAR-1:0]     is_64bit_bar_comb;
    logic                   processing_done_comb;
    logic [DATA_WIDTH-1:0]  bar_sizes_comb[6];
    logic [31:0]            bar_bases_comb[6];
    logic [31:0]            aligned_addr;
    logic [63:0]            aligned_addr_2, aligned_addr_2_reg;
    logic [63:0]            bar_size_64, bar_size_64_reg;
    logic                   is_all_64bit_bar_wire;
    logic [63:0]            bar64;
    logic [31:0]            size64_low, size64_low_reg;
    logic [31:0]            size64_high, size64_high_reg;
    logic                   carry_low, carry_low_reg;
    logic [63:0]            size64_neg;
    logic [63:0]            size_mask64;
    logic [63:0]            size64, size64_reg, size64_reg_reg;
    logic [31:0]            size32, size32_reg;

    logic [1:0][DATA_WIDTH-1:0]  sort_32bar_arr12, sort_32bar_arr34, sort_32bar_arr56; 
    logic [1:0][DATA_WIDTH-1:0]  sort_32bar_arr12_reg, sort_32bar_arr34_reg, sort_32bar_arr56_reg;

    logic [3:0][DATA_WIDTH-1:0]  sort_32bar_arr1234, sort_32bar_arr1234_reg;
    logic [5:0][DATA_WIDTH-1:0]  sort_32bar_final, sort_32bar_final_reg;

    logic [1:0][2:0]          bar_num_arr1, bar_num_arr2, bar_num_arr3;   
    logic [1:0][2:0]          bar_num_arr1_reg, bar_num_arr2_reg, bar_num_arr3_reg;
    logic [3:0][2:0]          bar_num_nxt_arr1, bar_num_nxt_arr1_reg;  
    logic [5:0][2:0]          bar_num_final, bar_num_final_reg;
    logic [2:0]               i, j, k;
    logic [2:0]               i_r, j_r, k_r;
    logic [2:0]               l, m, n;
    logic [2:0]               l_r, m_r, n_r;

    logic [2:0]               next_sort_val, next_sort_val_reg;

    logic                    upper_0_gtr_1, upper_0_eq_1, upper_0_gtr_1_reg, upper_0_eq_1_reg;
    logic                    lower_0_gtr_1, lower_0_eq_1, lower_0_gtr_1_reg, lower_0_eq_1_reg;
    logic                    upper_0_gtr_2, upper_0_eq_2, upper_0_gtr_2_reg, upper_0_eq_2_reg;
    logic                    lower_0_gtr_2, lower_0_eq_2, lower_0_gtr_2_reg, lower_0_eq_2_reg;
    logic                    upper_1_gtr_2, upper_1_eq_2, upper_1_gtr_2_reg, upper_1_eq_2_reg;
    logic                    lower_1_gtr_2, lower_1_eq_2, lower_1_gtr_2_reg, lower_1_eq_2_reg;

    logic                    first_sort_comb, second_sort_comb, third_sort_comb;
    logic                    first_sort, second_sort, third_sort;

    logic [2:0][63:0]        sorted_arr_64, sorted_arr_64_reg;
    logic [2:0][2:0]         bar_num_arr_64, bar_num_arr_64_reg;

    logic                    borrow_high, borrow_high_reg;
    logic  [2:0]             next_sort_val_64, next_sort_val_64_reg;

    logic [31:0]             next_bar_base_64_low, next_bar_base_64_high, next_bar_base_64_low_reg, next_bar_base_64_high_reg;
    logic [31:0]             two_compl_32bar, two_compl_32bar_reg;
    logic [31:0]             twos_compl_64_low, twos_compl_64_high, twos_compl_64_low_reg, twos_compl_64_high_reg;

    // Sequential logic for state and registers
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            current_bar <= 0;
            current_bar_2 <= '0;
            next_mem_addr <= 64'h0000_0000;
            next_mem_addr_2 <= 64'h0000_0000;
            next_mem_addr_comb_2_low_reg <= 32'h0000_0000;
            next_mem_addr_comb_2_high_reg <= 32'h0000_0000;
            next_mem_addr_carry_low_reg <= '0;
            is_64bit_bar <= 6'b0;
            processing_done <= '0;
            aligned_addr_2_reg <= 64'h0000_0000;
            bar_size_64_reg <= 64'h0000_0000;
            size64_reg <= 64'h0000_0000;
            size64_reg_reg <= 64'h0000_0000;
            size32_reg <= 32'h0000_0000;
            size64_low_reg <= 32'h0000_0000;
            size64_high_reg <= 32'h0000_0000;
            carry_low_reg <= '0;

            // Initialize outputs
            for (int i = 0; i < 6; i++) begin
                bar_sizes[i] <= '0;
                bar_bases[i] <= '0;
            end
            is_all_64bit_bar <= '0;
        end else if (link_down) begin
            current_state <= IDLE;
            current_bar <= '0;
            current_bar_2 <= '0;
            next_mem_addr <= 64'h0000_0000;
            next_mem_addr_2 <= 64'h0000_0000;
            next_mem_addr_comb_2_low_reg <= 32'h0000_0000;
            next_mem_addr_comb_2_high_reg <= 32'h0000_0000;
            next_mem_addr_carry_low_reg <= '0;
            is_64bit_bar <= 6'b0;
            processing_done <= '0;
            aligned_addr_2_reg <= 64'h0000_0000;
            bar_size_64_reg <= 64'h0000_0000;
            size64_reg <= 64'h0000_0000;
            size64_reg_reg <= 64'h0000_0000;
            size32_reg <= 32'h0000_0000;
            size64_low_reg <= 32'h0000_0000;
            size64_high_reg <= 32'h0000_0000;
            carry_low_reg <= '0;

            // Initialize outputs
            for (int i = 0; i < 6; i++) begin
                bar_sizes[i] <= '0;
                bar_bases[i] <= '0;
            end
            is_all_64bit_bar <= '0;
        end else begin
            current_state <= next_state;
            current_bar <= current_bar_comb;
            current_bar_2 <= current_bar_comb_2;
            next_mem_addr <= next_mem_addr_comb;
            next_mem_addr_2 <= next_mem_addr_comb_2;
            next_mem_addr_comb_2_low_reg <= next_mem_addr_comb_2_low;
            next_mem_addr_comb_2_high_reg <= next_mem_addr_comb_2_high;
            next_mem_addr_carry_low_reg <= next_mem_addr_carry_low;
            is_64bit_bar <= is_64bit_bar_comb;
            processing_done <= processing_done_comb;
            aligned_addr_2_reg <= aligned_addr_2;
            bar_size_64_reg <= bar_size_64;
            size64_reg <= size64;
            size64_reg_reg <= size64_reg;
            size32_reg <= size32;
            size64_low_reg <= size64_low;
            size64_high_reg <= size64_high;
            carry_low_reg <= carry_low;
            
            for (int i = 0; i < 6; i++) begin
                bar_sizes[i] <= bar_sizes_comb[i];
                bar_bases[i] <= bar_bases_comb[i];
            end
            is_all_64bit_bar <= is_all_64bit_bar_wire;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registered signals
            sort_32bar_arr12_reg <= '0;
            sort_32bar_arr34_reg <= '0;
            sort_32bar_arr56_reg <= '0;
            sort_32bar_arr1234_reg <= '0;
            sort_32bar_final_reg <= '0;
            bar_num_arr1_reg <= '0;
            bar_num_arr2_reg <= '0;
            bar_num_arr3_reg <= '0;
            bar_num_nxt_arr1_reg <= '0;
            bar_num_final_reg <= '0;
            i_r <= '0; 
            j_r <= '0; 
            k_r <= '0;
            l_r <= '0; 
            m_r <= '0; 
            n_r <= '0;
            next_sort_val_reg <= '0;
            upper_0_gtr_1_reg <= '0; 
            lower_0_gtr_1_reg <= '0; 
            upper_0_gtr_2_reg <= '0; 
            upper_0_eq_1_reg <= '0;
            lower_0_eq_1_reg <= '0;
            upper_0_eq_2_reg <= '0;
            lower_0_gtr_2_reg <= '0;
            lower_0_eq_2_reg <= '0;
            upper_1_gtr_2_reg <= '0;
            upper_1_eq_2_reg <= '0;
            lower_1_gtr_2_reg <= '0;
            lower_1_eq_2_reg <= '0;
            first_sort <= '0;
            second_sort <= '0;
            third_sort <= '0;
            sorted_arr_64_reg <= '0;
            bar_num_arr_64_reg <= '0;
            borrow_high_reg <= '0;
            next_sort_val_64_reg <= '0;
            next_bar_base_64_low_reg <= 32'h0000_0000;
            next_bar_base_64_high_reg <= 32'h0000_0000;
            two_compl_32bar_reg <= 32'h0000_0000;
            twos_compl_64_low_reg <= '0;
            twos_compl_64_high_reg <= '0;
        end else if (link_down) begin
            // Reset all registered signals on link down
            sort_32bar_arr12_reg <= '0;
            sort_32bar_arr34_reg <= '0;
            sort_32bar_arr56_reg <= '0;
            sort_32bar_arr1234_reg <= '0;
            sort_32bar_final_reg <= '0;
            bar_num_arr1_reg <= '0;
            bar_num_arr2_reg <= '0;
            bar_num_arr3_reg <= '0;
            bar_num_nxt_arr1_reg <= '0;
            bar_num_final_reg <= '0;
            i_r <= '0; 
            j_r <= '0; 
            k_r <= '0;
            l_r <= '0; 
            m_r <= '0; 
            n_r <= '0;
            next_sort_val_reg <= '0;
            upper_0_gtr_1_reg <= '0;
            lower_0_gtr_1_reg <= '0;
            upper_0_gtr_2_reg <= '0;
            upper_0_eq_1_reg <= '0;
            lower_0_eq_1_reg <= '0;
            upper_0_eq_2_reg <= '0;
            lower_0_gtr_2_reg <= '0;
            lower_0_eq_2_reg <= '0;
            upper_1_gtr_2_reg <= '0;
            upper_1_eq_2_reg <= '0;
            lower_1_gtr_2_reg <= '0;
            lower_1_eq_2_reg <= '0;
            first_sort <= '0;
            second_sort <= '0;
            third_sort <= '0;
            sorted_arr_64_reg <= '0;
            bar_num_arr_64_reg <= '0;
            borrow_high_reg <= '0;
            next_sort_val_64_reg <= '0;
            next_bar_base_64_low_reg <= 32'h0000_0000;
            next_bar_base_64_high_reg <= 32'h0000_0000;
            two_compl_32bar_reg <= 32'h0000_0000;
            twos_compl_64_low_reg <= '0;
            twos_compl_64_high_reg <= '0;
        end else begin
            // Update registered signals
            sort_32bar_arr12_reg <= sort_32bar_arr12;
            sort_32bar_arr34_reg <= sort_32bar_arr34;
            sort_32bar_arr56_reg <= sort_32bar_arr56;
            sort_32bar_arr1234_reg <= sort_32bar_arr1234;
            sort_32bar_final_reg <= sort_32bar_final;
            bar_num_arr1_reg <= bar_num_arr1;
            bar_num_arr2_reg <= bar_num_arr2;
            bar_num_arr3_reg <= bar_num_arr3;
            bar_num_nxt_arr1_reg <= bar_num_nxt_arr1;
            bar_num_final_reg <= bar_num_final;
            i_r <= i; 
            j_r <= j; 
            k_r <= k; 
            l_r <= l; 
            m_r <= m; 
            n_r <= n;
            next_sort_val_reg <= next_sort_val;
            next_sort_val_64_reg <= next_sort_val_64;
            upper_0_gtr_1_reg <= upper_0_gtr_1; 
            upper_0_eq_1_reg <= upper_0_eq_1;
            lower_0_gtr_1_reg <= lower_0_gtr_1; 
            lower_0_eq_1_reg <= lower_0_eq_1;
            upper_0_gtr_2_reg <= upper_0_gtr_2; 
            upper_0_eq_2_reg <= upper_0_eq_2;
            lower_0_gtr_2_reg <= lower_0_gtr_2; 
            lower_0_eq_2_reg <= lower_0_eq_2;
            upper_1_gtr_2_reg <= upper_1_gtr_2;
            upper_1_eq_2_reg <= upper_1_eq_2;
            lower_1_gtr_2_reg <= lower_1_gtr_2;
            lower_1_eq_2_reg <= lower_1_eq_2;
            first_sort <= first_sort_comb;
            second_sort <= second_sort_comb;
            third_sort <= third_sort_comb;
            sorted_arr_64_reg <= sorted_arr_64;
            bar_num_arr_64_reg <= bar_num_arr_64;
            borrow_high_reg <= borrow_high;
            next_bar_base_64_low_reg <= next_bar_base_64_low;
            next_bar_base_64_high_reg <= next_bar_base_64_high;
            two_compl_32bar_reg <= two_compl_32bar;
            twos_compl_64_low_reg <= twos_compl_64_low;
            twos_compl_64_high_reg <= twos_compl_64_high;
        end
    end


    // Calculate the size of a BAR based on the all-ones write response
    function automatic logic [31:0] calculate_bar_size(input logic [31:0] bar_data);
        logic [31:0] mask;
        logic [31:0] size_mask;
        logic [31:0] size;
        
        // For memory BAR, mask bits 0-3
        mask = 32'hFFFFFFF0;
        size_mask = bar_data & mask;
        size = ~size_mask + 1;
        
        return size;
    endfunction
    
    // Combinational logic for next state and register values
    always_comb begin
        // Default: maintain current values
        next_state = current_state;
        current_bar_comb = current_bar;
        current_bar_comb_2 = current_bar_2;
        next_mem_addr_comb = next_mem_addr;
        next_mem_addr_comb_2 = next_mem_addr_2;
        is_64bit_bar_comb = is_64bit_bar;
        processing_done_comb = '0;
        aligned_addr = 32'h0000_0000;
        aligned_addr_2 = 64'h0000_0000_0000_0000;
        is_all_64bit_bar_wire = is_all_64bit_bar;
        bar_size_64 = bar_size_64_reg;
        bar64 = 64'h0000_0000_0000_0000;
        size_mask64 = 64'h0000_0000_0000_0000;
        size64 = 64'h0000_0000_0000_0000;
        size32 = 32'h0000_0000;
        size64_low = 32'h0000_0000;
        size64_high = 32'h0000_0000;
        carry_low = '0;
        next_mem_addr_comb_2_low = 32'h0000_0000;
        next_mem_addr_comb_2_high = 32'h0000_0000;
        next_mem_addr_carry_low = '0;
        // Copy current values to combinational outputs
        for (int i = 0; i < 6; i++) begin
            bar_sizes_comb[i] = bar_sizes[i];
            bar_bases_comb[i] = bar_bases[i];
        end

        sort_32bar_arr12 = sort_32bar_arr12_reg;
        sort_32bar_arr34 = sort_32bar_arr34_reg;
        sort_32bar_arr56 = sort_32bar_arr56_reg;
        sort_32bar_arr1234 = sort_32bar_arr1234_reg;
        sort_32bar_final = sort_32bar_final_reg;

        bar_num_arr1 = bar_num_arr1_reg;
        bar_num_arr2 = bar_num_arr2_reg;
        bar_num_arr3 = bar_num_arr3_reg;
        bar_num_nxt_arr1 = bar_num_nxt_arr1_reg;
        bar_num_final = bar_num_final_reg;

        i = i_r;
        j = j_r;
        k = k_r;
        l = l_r;
        m = m_r;
        n = n_r;

        next_sort_val = next_sort_val_reg;

        upper_0_gtr_1 = upper_0_gtr_1_reg;
        upper_0_eq_1 = upper_0_eq_1_reg;
        lower_0_gtr_1 = lower_0_gtr_1_reg;
        lower_0_eq_1 = lower_0_eq_1_reg;
        upper_0_gtr_2 = upper_0_gtr_2_reg;
        upper_0_eq_2 = upper_0_eq_2_reg;
        lower_0_gtr_2 = lower_0_gtr_2_reg;
        lower_0_eq_2 = lower_0_eq_2_reg;
        upper_1_gtr_2 = upper_1_gtr_2_reg;
        upper_1_eq_2 = upper_1_eq_2_reg;
        lower_1_gtr_2 = lower_1_gtr_2_reg;
        lower_1_eq_2 = lower_1_eq_2_reg;

        first_sort_comb = first_sort;
        second_sort_comb = second_sort;
        third_sort_comb = third_sort;

        sorted_arr_64 = sorted_arr_64_reg;
        bar_num_arr_64 = bar_num_arr_64_reg;
        borrow_high = borrow_high_reg;
        next_sort_val_64 = next_sort_val_64_reg;
        next_bar_base_64_low = next_bar_base_64_low_reg;
        next_bar_base_64_high = next_bar_base_64_high_reg;        
        two_compl_32bar = '0;
        twos_compl_64_low = '0;
        twos_compl_64_high = '0;

        case (current_state)
            IDLE: begin
                if (start_processing) begin
                    next_state = BAR_SIZE;
                    current_bar_comb = '0;
                    current_bar_comb_2 = '0;
                    next_mem_addr_comb = 32'h0000_0000;
                    next_mem_addr_comb_2 = 64'h0000_0001_0000_0000;
                    aligned_addr = 32'h0000_0000;
                    aligned_addr_2 = 64'h0000_0000_0000_0000;
                    is_64bit_bar_comb = 6'b0;
                    processing_done_comb = '0;
                    is_all_64bit_bar_wire = '0;
                    bar_size_64 = 64'h0000_0000_0000_0000;
                    bar64 = 64'h0000_0000_0000_0000;
                    size_mask64 = 64'h0000_0000_0000_0000;
                    size64 = 64'h0000_0000_0000_0000;
                    
                    for (int i = 0; i < 6; i++) begin
                        bar_sizes_comb[i] = '0;
                        bar_bases_comb[i] = '0;
                    end
                end
            end

            BAR_SIZE: begin
                next_state = CALC_SIZES_32;
                for(int i = 0; i < NUM_BAR; i++) begin
                    if(bar_values[i][2:0] == 3'b100) begin
                        is_all_64bit_bar_wire = 1;
                        next_state = CALC_SIZES_64;
                    end
                end
                current_bar_comb = '0;
            end

            CALC_SIZES_32: begin
                // Skip BAR if it's all zeros or I/O BAR
                if (!(|bar_values[current_bar]) || bar_values[current_bar][0] == 1) begin
                    is_64bit_bar_comb[current_bar] = '0;
                    current_bar_comb = current_bar + 1;
                    next_state = current_bar == 5 ? ASSIGN_BASES : CALC_SIZES_32;
                end else begin
                    // 32-bit Memory BAR processing
                    size32 = calculate_bar_size(bar_values[current_bar]);
                    is_64bit_bar_comb[current_bar] = '0;
                    next_state = CALC_SIZES_32_2;
                end
            end

            CALC_SIZES_32_2: begin
                bar_sizes_comb[current_bar] = size32_reg;
                current_bar_comb = current_bar + 1;
                if (current_bar == 5) begin
                    next_state = ASSIGN_BASES;
                end else begin
                    next_state = CALC_SIZES_32;
                end
            end

            CALC_SIZES_64: begin
                // Skip BAR if it's all zeros or I/O BAR
                if (!(|bar_values[current_bar]) || bar_values[current_bar][0] == 1) begin
                    is_64bit_bar_comb[current_bar] = '0;
                    current_bar_comb = current_bar + 1;
                    next_state = current_bar >= 4 ? ASSIGN_BASES : CALC_SIZES_64;
                end
                // Check if this is a 64-bit BAR
                else begin
                    // 64-bit BAR processing
                    bar64 = {bar_values[current_bar+1], bar_values[current_bar]};
                    size_mask64 = bar64 & 64'hFFFFFFFFFFFFFFF0;
                    size64_neg = ~size_mask64;
                    size64_low = size64_neg[31:0] + 1;
                    carry_low  = size_mask64[31:0] == 32'h0000_0000;
                    size64_high = size64_neg[63:32];
                    // Mark these as 64-bit BARs
                    is_64bit_bar_comb[current_bar] = 1;
                    is_64bit_bar_comb[current_bar+1] = 1;
                    next_state = CALC_SIZES_64_1;
                end
            end

            CALC_SIZES_64_1: begin
                size64 = {size64_high_reg + carry_low_reg, size64_low_reg};
                next_state = CALC_SIZES_64_2;
            end

            CALC_SIZES_64_2: begin
                bar_sizes_comb[current_bar] = size64_reg[31:0];
                current_bar_comb = current_bar + 1;
                next_state = CALC_SIZES_64_3;
            end
            
            CALC_SIZES_64_3: begin
                bar_sizes_comb[current_bar] = size64_reg_reg[63:32];
                current_bar_comb = current_bar + 1;
                next_state = current_bar >= 4 ? ASSIGN_BASES : CALC_SIZES_64;
            end
            
            ASSIGN_BASES: begin
                if(is_all_64bit_bar == '0) begin
                    next_state = SORT_32_BAR_1;
                end
                else begin
                    next_state = SORT_64_BAR_1;
                end
            end

            SORT_32_BAR_1: begin
                if(bar_sizes[0] <= bar_sizes[1]) begin
                    sort_32bar_arr12[0] = bar_sizes_comb[1];
                    sort_32bar_arr12[1] = bar_sizes_comb[0];

                    bar_num_arr1[0] = 1;
                    bar_num_arr1[1] = 0;
                end
                else begin
                    sort_32bar_arr12[0] = bar_sizes_comb[0];
                    sort_32bar_arr12[1] = bar_sizes_comb[1];

                    bar_num_arr1[0] = 0;
                    bar_num_arr1[1] = 1;
                end

                if(bar_sizes[2] <= bar_sizes[3]) begin
                    sort_32bar_arr34[0] = bar_sizes_comb[3];
                    sort_32bar_arr34[1] = bar_sizes_comb[2];

                    bar_num_arr2[0] = 3;
                    bar_num_arr2[1] = 2;
                end
                else begin
                    sort_32bar_arr34[0] = bar_sizes_comb[2];
                    sort_32bar_arr34[1] = bar_sizes_comb[3];

                    bar_num_arr2[0] = 2;
                    bar_num_arr2[1] = 3;
                end

                if(bar_sizes[4] <= bar_sizes[5]) begin
                    sort_32bar_arr56[0] = bar_sizes_comb[5];
                    sort_32bar_arr56[1] = bar_sizes_comb[4];

                    bar_num_arr3[0] = 5;
                    bar_num_arr3[1] = 4;
                end
                else begin
                    sort_32bar_arr56[0] = bar_sizes_comb[4];
                    sort_32bar_arr56[1] = bar_sizes_comb[5];

                    bar_num_arr3[0] = 4;
                    bar_num_arr3[1] = 5;
                end
                next_state = SORT_32_BAR_2;
            end
            SORT_32_BAR_2: begin
                if(i == 2) begin
                    sort_32bar_arr1234[k] = sort_32bar_arr34_reg[j];
                    bar_num_nxt_arr1[k] = bar_num_arr2_reg[j];
                    j = j + 1;
                    k = k + 1;
                end
                else if(j == 2) begin
                    sort_32bar_arr1234[k] = sort_32bar_arr12_reg[i];
                    bar_num_nxt_arr1[k] = bar_num_arr1_reg[i];
                    i = i + 1;
                    k = k + 1;
                end
                else if(sort_32bar_arr12_reg[i] > sort_32bar_arr34_reg[j] ) begin
                    sort_32bar_arr1234[k] = sort_32bar_arr12_reg[i];
                    bar_num_nxt_arr1[k] = bar_num_arr1_reg[i];
                    i = i + 1;
                    k = k + 1;
                end
                else begin
                    sort_32bar_arr1234[k] = sort_32bar_arr34_reg[j];
                    bar_num_nxt_arr1[k] = bar_num_arr2_reg[j];
                    j = j + 1;
                    k = k + 1;
                end
                next_state = k==4 ?  SORT_32_BAR_3 : SORT_32_BAR_2;
            end
            SORT_32_BAR_3: begin
                if(l == 4) begin
                    sort_32bar_final[n] = sort_32bar_arr56_reg[m];
                    bar_num_final[n] = bar_num_arr3_reg[m];
                    m = m + 1;
                    n = n + 1;
                end
                else if(m == 2) begin
                    sort_32bar_final[n] = sort_32bar_arr1234_reg[l];
                    bar_num_final[n] = bar_num_nxt_arr1_reg[l];
                    l = l + 1;
                    n = n + 1;
                end
                else if(sort_32bar_arr1234_reg[l] > sort_32bar_arr56_reg[m] ) begin
                    sort_32bar_final[n] = sort_32bar_arr1234_reg[l];
                    bar_num_final[n] = bar_num_nxt_arr1_reg[l];
                    l = l + 1;
                    n = n + 1;
                end
                else begin
                    sort_32bar_final[n] = sort_32bar_arr56_reg[m];
                    bar_num_final[n] = bar_num_arr3_reg[m];
                    m = m + 1;
                    n = n + 1;
                end
                next_state = n==6 ? ASSIGN_32_BAR : SORT_32_BAR_3;
            end

            ASSIGN_32_BAR: begin
                current_bar_comb_2 = bar_num_final_reg[0];
                next_mem_addr_comb = 32'b0 - sort_32bar_final_reg[0]; 
                next_state = ASSIGN_32_BAR_2;
                next_sort_val = 1;
            end
        
            ASSIGN_32_BAR_2: begin
                bar_bases_comb[current_bar_2] = next_mem_addr & 32'hFFFF_FFF0;
                two_compl_32bar = (~sort_32bar_final_reg[next_sort_val_reg]) + 1;     
                next_state = ASSIGN_32_BAR_3;
            end

            ASSIGN_32_BAR_3: begin
                next_mem_addr_comb = next_mem_addr + two_compl_32bar_reg;
                current_bar_comb_2 = bar_num_final_reg[next_sort_val_reg];
                next_sort_val = next_sort_val_reg + 1;
                if(next_sort_val_reg == 5) begin
                    next_state = ASSIGN_32_BAR_LAST;
                end else begin
                    next_state = ASSIGN_32_BAR_2;
                end
            end

            ASSIGN_32_BAR_LAST: begin
                bar_bases_comb[current_bar_2] = next_mem_addr & 32'hFFFF_FFF0;
                next_state = DONE;
            end

            SORT_64_BAR_1: begin
                upper_0_gtr_1 = bar_sizes[1][31:0] > bar_sizes[3][31:0];
                upper_0_eq_1 = bar_sizes[1][31:0] == bar_sizes[3][31:0];

                lower_0_gtr_1 = bar_sizes[0][31:0] > bar_sizes[2][31:0];
                lower_0_eq_1 = bar_sizes[0][31:0] == bar_sizes[2][31:0];

                upper_0_gtr_2 = bar_sizes[1][31:0] > bar_sizes[5][31:0];
                upper_0_eq_2 = bar_sizes[1][31:0] == bar_sizes[5][31:0];

                lower_0_gtr_2 = bar_sizes[0][31:0] > bar_sizes[4][31:0];
                lower_0_eq_2 = bar_sizes[0][31:0] == bar_sizes[4][31:0];

                upper_1_gtr_2 = bar_sizes[3][31:0] > bar_sizes[5][31:0];
                upper_1_eq_2 = bar_sizes[3][31:0] == bar_sizes[5][31:0];

                lower_1_gtr_2 = bar_sizes[2][31:0] > bar_sizes[4][31:0];
                lower_1_eq_2 = bar_sizes[2][31:0] == bar_sizes[4][31:0];
                next_state = SORT_64_BAR_2;
            end

            SORT_64_BAR_2: begin
                first_sort_comb = upper_0_gtr_1_reg ? '0 : upper_0_eq_1_reg ? (lower_0_gtr_1_reg ? '0 : '1) : '1;

                second_sort_comb = upper_0_gtr_2_reg ? '0 : upper_0_eq_2_reg ? (lower_0_gtr_2_reg ? '0 : '1) : '1;

                third_sort_comb = upper_1_gtr_2_reg ? '0 : upper_1_eq_2_reg ? (lower_1_gtr_2_reg ? '0 : '1) : '1;
                next_state = SORT_64_BAR_3;
            end

            SORT_64_BAR_3: begin
                case({first_sort,second_sort,third_sort})
                    3'b000: begin
                        sorted_arr_64[0] = {bar_sizes_comb[1], bar_sizes_comb[0]};
                        sorted_arr_64[1] = {bar_sizes_comb[3], bar_sizes_comb[2]};
                        sorted_arr_64[2] = {bar_sizes_comb[5], bar_sizes_comb[4]};
                        
                        bar_num_arr_64[0] = 0;
                        bar_num_arr_64[1] = 1;
                        bar_num_arr_64[2] = 2;
                    end
                    3'b001: begin
                        sorted_arr_64[0] = {bar_sizes_comb[1], bar_sizes_comb[0]};
                        sorted_arr_64[1] = {bar_sizes_comb[5], bar_sizes_comb[4]};
                        sorted_arr_64[2] = {bar_sizes_comb[3], bar_sizes_comb[2]};
                        
                        bar_num_arr_64[0] = 0;
                        bar_num_arr_64[1] = 2;
                        bar_num_arr_64[2] = 1;
                    end
                    3'b011: begin
                        sorted_arr_64[0] = {bar_sizes_comb[5], bar_sizes_comb[4]};
                        sorted_arr_64[1] = {bar_sizes_comb[1], bar_sizes_comb[0]};
                        sorted_arr_64[2] = {bar_sizes_comb[3], bar_sizes_comb[2]};
                        
                        bar_num_arr_64[0] = 2;
                        bar_num_arr_64[1] = 0;
                        bar_num_arr_64[2] = 1;
                    end
                    3'b111: begin
                        sorted_arr_64[0] = {bar_sizes_comb[5], bar_sizes_comb[4]};
                        sorted_arr_64[1] = {bar_sizes_comb[3], bar_sizes_comb[2]};
                        sorted_arr_64[2] = {bar_sizes_comb[1], bar_sizes_comb[0]};
                        
                        bar_num_arr_64[0] = 2;
                        bar_num_arr_64[1] = 1;
                        bar_num_arr_64[2] = 0;
                    end
                    3'b110: begin
                        sorted_arr_64[0] = {bar_sizes_comb[3], bar_sizes_comb[2]};
                        sorted_arr_64[1] = {bar_sizes_comb[5], bar_sizes_comb[4]};
                        sorted_arr_64[2] = {bar_sizes_comb[1], bar_sizes_comb[0]};
                        
                        bar_num_arr_64[0] = 1;
                        bar_num_arr_64[1] = 2;
                        bar_num_arr_64[2] = 0;
                    end
                    3'b100: begin
                        sorted_arr_64[0] = {bar_sizes_comb[3], bar_sizes_comb[2]};
                        sorted_arr_64[1] = {bar_sizes_comb[1], bar_sizes_comb[0]};
                        sorted_arr_64[2] = {bar_sizes_comb[5], bar_sizes_comb[4]};
                        
                        bar_num_arr_64[0] = 1;
                        bar_num_arr_64[1] = 0;
                        bar_num_arr_64[2] = 2;
                    end
                    default : begin
                        sorted_arr_64[0] = 64'h0000_0000_0000_0000;
                        sorted_arr_64[1] = 64'h0000_0000_0000_0000;
                        sorted_arr_64[2] = 64'h0000_0000_0000_0000;
                        
                        bar_num_arr_64[0] = 3'b111;
                        bar_num_arr_64[1] = 3'b111;
                        bar_num_arr_64[2] = 3'b111;
                    end
                endcase
                next_state = ASSIGN_64_BAR;
            end

            ASSIGN_64_BAR: begin
                current_bar_comb_2 = bar_num_arr_64_reg[0]<<1;
                next_mem_addr_comb_2_low = (~sorted_arr_64_reg[0][31:0]) + 1; 
                next_mem_addr_comb_2_high = (~sorted_arr_64_reg[0][63:32]) + 1;
                borrow_high = |sorted_arr_64_reg[0][31:0];
                next_state = ASSIGN_64_BAR_2;    
                next_sort_val_64 = 1;           
            end

            ASSIGN_64_BAR_2: begin
                next_bar_base_64_low = next_mem_addr_comb_2_low_reg & 32'hFFFF_FFF0;
                next_bar_base_64_high = next_mem_addr_comb_2_high_reg - borrow_high_reg; 
                next_state = next_sort_val_64_reg == 3 ? ASSIGN_64_BAR_LAST : ASSIGN_64_BAR_3;
            end
            ASSIGN_64_BAR_3: begin
                bar_bases_comb[current_bar_2] = next_bar_base_64_low_reg;
                bar_bases_comb[current_bar_2 + 1] = next_bar_base_64_high_reg;

                twos_compl_64_low = (~sorted_arr_64_reg[next_sort_val_64_reg][31:0]) + 1;
                twos_compl_64_high = (~sorted_arr_64_reg[next_sort_val_64_reg][63:32]) + 1;
                next_state = ASSIGN_64_BAR_4;
            end
            ASSIGN_64_BAR_4: begin
                current_bar_comb_2 = bar_num_arr_64_reg[next_sort_val_64_reg]<<1;
                next_mem_addr_comb_2_low = next_bar_base_64_low_reg + twos_compl_64_low_reg;
                next_mem_addr_comb_2_high = next_bar_base_64_high_reg + twos_compl_64_high_reg;
                borrow_high = (sorted_arr_64_reg[next_sort_val_64_reg][31:0] > next_bar_base_64_low_reg) ? 1'b1 : 1'b0;
                next_sort_val_64 = next_sort_val_64_reg + 1;
                next_state = ASSIGN_64_BAR_2;
            end
            ASSIGN_64_BAR_LAST: begin
                bar_bases_comb[current_bar_2] = next_bar_base_64_low_reg;
                bar_bases_comb[current_bar_2 + 1] = next_bar_base_64_high_reg;
                next_state = DONE;
            end
            DONE: begin
                processing_done_comb = 1; // Indicate processing is done
            end
            default: begin
                next_state = IDLE; // Fallback to IDLE state
            end

        endcase
    end

endmodule