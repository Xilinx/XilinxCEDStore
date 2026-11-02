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

module rx_credit_handler #(
    parameter NUM_SLOTS = 3
)
(
    input logic                             clk,
    input logic                             rst_n,  
    input logic                             link_down, // Link down signal to reset credit handling

    input logic  [(NUM_SLOTS)-1:0]    credits_to_return,
    input logic                             rx_credit_active,

    output logic                            rx_credit_valid,
    output logic [2:0]                      rx_credit
);

    logic [6:0] credit_accumulator;      // Accumulate up to 64 credits
    logic [2:0] encoded_credit, initial_encoded_credit;          // Encoded credit value to be sent
    logic [6:0] buffer_depth_credits;    // Buffer depth credits to be sent initially


    localparam logic [6:0] BUFFER_DEPTH = (NUM_SLOTS == 3) ? 7'd48 : 
                                      (NUM_SLOTS == 2) ? 7'd32 : 7'd16;
    localparam logic [6:0] BUFFER_CREDITS_ONE = (NUM_SLOTS == 3) ? 7'd32 : 
                                           (NUM_SLOTS == 2) ? 7'd16 : 7'd16;
    localparam logic [6:0] BUFFER_CREDITS_TWO = (NUM_SLOTS == 3) ? 7'd16 : 
                                           (NUM_SLOTS == 2) ? 7'd16 : 7'd0;

    typedef enum logic [2:0] {
        IDLE,
        INITIAL_CR_SEND,
        INITIAL_CR_SEND_TWO,
        NORMAL_OPERATION
    } state_t;

    state_t current_state, next_state;

    function automatic logic [2:0] encode_credit(input logic [6:0] credits);
            logic [2:0] encoded;
            if (credits >= 64)      encoded = 3'b111;  // 64
            else if (credits >= 32) encoded = 3'b110;  // 32
            else if (credits >= 16) encoded = 3'b101;  // 16
            else if (credits >= 8)  encoded = 3'b100;  // 8
            else if (credits >= 4)  encoded = 3'b011;  // 4
            else if (credits >= 2)  encoded = 3'b010;  // 2
            else if (credits >= 1)  encoded = 3'b001;  // 1
            else                    encoded = 3'b000;  // 0
            return encoded;
        endfunction

    function automatic logic [6:0] decode_credit(input logic [2:0] encoded);
            case (encoded)
                3'b111:  return 7'd64;
                3'b110:  return 7'd32;
                3'b101:  return 7'd16;
                3'b100:  return 7'd8;
                3'b011:  return 7'd4;
                3'b010:  return 7'd2;
                3'b001:  return 7'd1;
                default: return 7'd0;
            endcase
        endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            credit_accumulator <= '0; // Reset credit count on reset
            buffer_depth_credits <= '0; // Reset buffer depth credits
        end else if (link_down) begin
            credit_accumulator <= '0; // Reset credit count on link down
            buffer_depth_credits <= '0; // Reset buffer depth credits
        end else begin
            credit_accumulator <= credit_accumulator + credits_to_return - 
                                    (rx_credit_valid ? decode_credit(encoded_credit) : '0); // Update credit count
            if(current_state == IDLE) begin
                if(NUM_SLOTS < 3) begin
                    buffer_depth_credits <= BUFFER_DEPTH;
                end else begin
                    buffer_depth_credits <= BUFFER_CREDITS_ONE;
                end
            end else if (current_state == INITIAL_CR_SEND) begin
                buffer_depth_credits <= BUFFER_CREDITS_TWO;
            end
        end
    end


    // rst and link down credit intf inactive
    // after rst Initial state - Send Buffer depth credit to cpm6
    // then in normal state - send credits_to_return in the encoded format to cpm6

    // State machine for credit handling

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || link_down) begin
            current_state <= IDLE; // Reset to IDLE state
        end else begin
            current_state <= next_state; // Update state
        end
    end

    always_comb begin
        next_state = current_state; // Default to current state
        encoded_credit = '0; 
        initial_encoded_credit = '0;
        rx_credit_valid = 1'b0; 
        rx_credit = '0; 

        case (current_state)
            IDLE: begin
                encoded_credit = '0; // No credit encoding in IDLE state
                initial_encoded_credit = '0; // No initial credit encoding in IDLE state
                rx_credit_valid = 1'b0; // No credit valid signal in IDLE state
                rx_credit = '0; // No credit value in IDLE state
                if(rx_credit_active) begin
                    // If credit handling is active, move to INITIAL_CR_SEND state
                    next_state = INITIAL_CR_SEND;
                end else begin
                    // Stay in IDLE state if not active
                    next_state = IDLE;
                end
            end
            INITIAL_CR_SEND: begin
                initial_encoded_credit = encode_credit(buffer_depth_credits); // Encode initial buffer depth credits
                rx_credit_valid = 1'b1; // Send initial credits
                rx_credit = initial_encoded_credit; // Assign initial credits to rx_credit
                if(NUM_SLOTS < 3) begin
                    next_state = NORMAL_OPERATION; // Move to NORMAL_OPERATION after sending initial credits
                end else begin
                    next_state = INITIAL_CR_SEND_TWO; // Move to next initial credit send state for NUM_SLOTS == 3
                end
            end
            INITIAL_CR_SEND_TWO: begin
                initial_encoded_credit = encode_credit(buffer_depth_credits); // Encode initial buffer depth credits
                rx_credit_valid = 1'b1; // Send initial credits
                rx_credit = initial_encoded_credit; // Assign initial credits to rx_credit
                next_state = NORMAL_OPERATION; // Move to NORMAL_OPERATION after sending second initial credits
            end
            NORMAL_OPERATION: begin
                encoded_credit = encode_credit(credit_accumulator); // Encode the current credit accumulator
                rx_credit_valid = (credit_accumulator > 0); // Valid if there are credits available
                rx_credit = encoded_credit; // Assign encoded credit value if valid
                next_state = NORMAL_OPERATION; // Stay in NORMAL_OPERATION
            end
            default: begin
                encoded_credit = '0; // Default case to handle unexpected states
                initial_encoded_credit = '0; // Default case to handle unexpected states
                rx_credit_valid = 1'b0; // Default case to handle unexpected states
                rx_credit = '0; // Default case to handle unexpected states
                next_state = IDLE; // Default case to handle unexpected states
            end
        endcase
    end


endmodule