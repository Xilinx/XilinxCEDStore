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

module tag_manager #(
    parameter TAG_COUNT = 256
)(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // Allocation interface
    input  wire                                 req_valid,
    input  wire [1:0]                           req_count,  
    output wire                                 req_ready,
    output reg                                  tag_valid,
    output reg  [$clog2(TAG_COUNT)-1:0]         tag_id,
    
    // Free interface (single tag or multiple tags)
    input  wire                                 free_valid,
    input  wire [$clog2(TAG_COUNT)-1:0]         free_tag_1,  // First tag to free
    
    // Status 
    output wire [$clog2(TAG_COUNT):0]           free_tag_count
);

    localparam TAG_COUNT_WIDTH = $clog2(TAG_COUNT);
    // Tag usage bitmap (1=in use, 0=free)
    logic [TAG_COUNT-1:0] tag_inuse;

    logic tag_handling_started;
    
    //=============================================
    // FIFO FOR FREE TAGS
    //=============================================
    logic [TAG_COUNT-1:0][$clog2(TAG_COUNT)-1:0]    free_tag_fifo ;
    logic [$clog2(TAG_COUNT)-1:0]                   fifo_wr_ptr;
    logic [$clog2(TAG_COUNT)-1:0]                   fifo_rd_ptr;
    logic                                           read_wrap;
    logic                                           write_wrap;
    logic                                           req_ready_reg;
    logic                                           tag_buffer_empty;
    logic                                           tag_buffer_full;

    // Combinational signals
    logic [TAG_COUNT-1:0]                           tag_inuse_comb;
    logic                                           insert_free_tag;
    logic [$clog2(TAG_COUNT)-1:0]                   fifo_wr_ptr_comb;
    logic [$clog2(TAG_COUNT)-1:0]                   fifo_rd_ptr_comb;
    logic                                           read_wrap_comb;
    logic                                           write_wrap_comb;
    logic [$clog2(TAG_COUNT)-1:0]                   tag_id_comb;
    logic                                           tag_valid_comb;
    logic                                           err_tag_not_inuse;
    logic [15:0]                                    err_count;    


    // FIFO count - how many free tags we have  
    assign free_tag_count = read_wrap == write_wrap ? (TAG_COUNT - (fifo_rd_ptr - fifo_wr_ptr)) : (fifo_wr_ptr - fifo_rd_ptr);
    assign tag_buffer_empty = (fifo_rd_ptr == fifo_wr_ptr) && (read_wrap == write_wrap);
    assign tag_buffer_full  = (fifo_rd_ptr == fifo_wr_ptr+1) && (read_wrap != write_wrap);

    assign  req_ready = req_ready_reg;
    assign  req_ready_wire = free_tag_count >= 1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_ready_reg <= '0;
        end else begin
            req_ready_reg <= req_ready_wire;
        end
    end
    

    // FIFO and tag management
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize all tags as free
            tag_inuse <= {TAG_COUNT{1'b0}};
            fifo_rd_ptr <= '0;
            fifo_wr_ptr <= '0;
            read_wrap  <= '0;
            write_wrap <= '0;
            tag_valid <= 2'b00;
            tag_id <= '0;

            tag_handling_started <= 1'b0;
            
            // Fill FIFO with all tags with 0
            for (int i = 0; i < TAG_COUNT; i = i + 1) begin
                free_tag_fifo[i] <= '0;
            end

            err_count <= 16'b0;

        end else if(!tag_handling_started) begin
            tag_handling_started <= 1'b1;
            // Initialize FIFO with all tags
            for (int i = 0; i < TAG_COUNT; i = i + 1) begin
                free_tag_fifo[i] <= TAG_COUNT_WIDTH'(i[$clog2(TAG_COUNT)-1:0]);
            end
            err_count <= 16'b0;
        end else begin

            //// Handle new tag request and free tag logic
            tag_inuse <= tag_inuse_comb;
            if(insert_free_tag) free_tag_fifo[fifo_wr_ptr] <= free_tag_1;
            fifo_rd_ptr <= fifo_rd_ptr_comb;
            fifo_wr_ptr <= fifo_wr_ptr_comb;
            read_wrap <= read_wrap_comb;
            write_wrap <= write_wrap_comb;
            tag_id <= tag_id_comb;
            tag_valid <= tag_valid_comb;
            err_count <= err_count + (err_tag_not_inuse ? 16'b1 : 16'b0);
        end
    end

    always_comb begin
        tag_inuse_comb = tag_inuse;
        insert_free_tag = '0;
        fifo_rd_ptr_comb = fifo_rd_ptr;
        fifo_wr_ptr_comb = fifo_wr_ptr;
        read_wrap_comb = read_wrap;
        write_wrap_comb = write_wrap;
        tag_id_comb = tag_id;
        tag_valid_comb = '0;
        err_tag_not_inuse = 1'b0;

        if (req_valid && req_ready) begin
            tag_id_comb = free_tag_fifo[fifo_rd_ptr];
            tag_valid_comb = 1'b1;
            tag_inuse_comb = tag_inuse_comb | (1'b1 << free_tag_fifo[fifo_rd_ptr]);
            fifo_rd_ptr_comb = fifo_rd_ptr + 1;
            read_wrap_comb = (fifo_rd_ptr == TAG_COUNT-1) ? ~read_wrap : read_wrap;
        end

        if (free_valid) begin
            insert_free_tag = 1'b1;
            tag_inuse_comb = tag_inuse_comb & ~(1'b1 << free_tag_1);
            fifo_wr_ptr_comb = fifo_wr_ptr + 1;
            write_wrap_comb = (fifo_wr_ptr == TAG_COUNT-1) ? ~write_wrap : write_wrap;
            err_tag_not_inuse = ~tag_inuse[free_tag_1];
        end

    end
    
endmodule
