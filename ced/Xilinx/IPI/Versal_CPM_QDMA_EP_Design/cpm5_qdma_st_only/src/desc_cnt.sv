// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////
`timescale 1ps / 1ps

// calculate the available descriptors for a queue
module desc_cnt #(
  parameter DESC_CNT_WIDTH = 16,
  parameter DESC_AVAIL_WIDTH = 8
) (
  input  wire user_clk,
  input  wire user_reset_n,
  input  wire desc_cnt_inc,
  input  wire [DESC_AVAIL_WIDTH-1:0] desc_inc_val,
  input  wire desc_cnt_dec,
  input  wire desc_cnt_clr,
  output wire [DESC_CNT_WIDTH-1:0] desc_cnt,
  output wire desc_rdy
);

  // register declaration
  reg [DESC_CNT_WIDTH-1:0] descriptor_count;
  reg descriptor_ready;

  // assign outputs
  assign desc_cnt = descriptor_count;
// Timing opt. This is putting a lot of strain in timing
//  assign desc_rdy = descriptor_ready & (~((descriptor_count == 1) & desc_cnt_dec));
// Replacing with this. It will create bubbles if we constantly running low on credits, but we suspect that event is rare enough that this is an acceptable cost
  assign desc_rdy = descriptor_ready;

  // Register if the queue is enabled or disabled
  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      descriptor_ready <= 'h0;
    end else begin
      // if the queue is cleared it is no longer ready.
      if (desc_cnt_clr || (descriptor_count == 'h0))
        // descriptor is cleared or descriptor is zero
        descriptor_ready <= 'h0;
      else if ((descriptor_count == 'h1) && !desc_cnt_inc && desc_cnt_dec)
        // descriptor is decrementing to zero
        descriptor_ready <= 1'b0;
      else
        // enable the descriptor
        descriptor_ready <= 1'b1;
    end
  end
  
  // Register the descriptor availability for each queue
  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      descriptor_count <= 'h0;
    end else begin
      // increment the credit count
      if (desc_cnt_clr) 
        descriptor_count <= 'h0;
      else if (desc_cnt_inc && (desc_cnt_dec && (descriptor_count != 0)))
        descriptor_count <= descriptor_count + desc_inc_val - 1;
      else if (desc_cnt_inc)
        descriptor_count <= descriptor_count + desc_inc_val;      
      else if (desc_cnt_dec && (descriptor_count != 0))
        descriptor_count <= descriptor_count - 1;
      else
        descriptor_count <= descriptor_count;
    end
  end

endmodule 
