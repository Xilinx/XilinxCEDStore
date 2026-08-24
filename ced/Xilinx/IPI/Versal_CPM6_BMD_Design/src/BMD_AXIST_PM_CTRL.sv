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
//-- Filename: BMD_AXIST_PM_CTRL.sv
//--
//-- Description: Controls PME handshake for transition to L2/3 states.
//--              Ensures no traffic is in progress before granting ACK.
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_PM_CTRL #(
    parameter int           TRAFFIC_WAIT_CYCLES = 5
)(
    input  logic            clk,
    input  logic            rst_n,

    // Completion progress
    input  logic            cpl_done,
    input  logic            rd_done,
    input  logic [63:0]     rx_nonposted_header_count,
    input  logic [63:0]     tx_completion_header_count,

    // LTSSM state
    input  logic [5:0]      ltssm_state,

    // Handshake signals
    input  logic            cfg_pm_turnoff,
    output logic            app_ready_entr_l23
);

logic next_app_ready;
logic [5:0] ltssm_state_r;

logic [$clog2(TRAFFIC_WAIT_CYCLES):0] wait_cnt, next_wait_cnt;

typedef enum logic [1:0] {
    IDLE,
    WAITING_FOR_CPL_DONE,
    WAITING_FOR_LTSSM_TO_GO_OUT_OF_L0,
    UNUSED
} app_ready_state_t; // 0: idle, 1: waiting for cpl_done, 2: waiting for ltssm to go out of L0
app_ready_state_t app_ready_state, next_app_ready_state;

assign next_app_ready = (app_ready_state == WAITING_FOR_LTSSM_TO_GO_OUT_OF_L0) ? 1'b1 : 1'b0;

always @(posedge clk) begin
    if(!rst_n) begin
        app_ready_entr_l23  <= '0;
        app_ready_state     <= IDLE;
        ltssm_state_r       <= '0;
        wait_cnt            <= '0;
    end else begin
        app_ready_entr_l23  <= next_app_ready;
        app_ready_state     <= next_app_ready_state;
        ltssm_state_r       <= ltssm_state;
        wait_cnt            <= next_wait_cnt;
    end
end

always_comb begin
    next_app_ready_state = app_ready_state;
    next_wait_cnt = wait_cnt;

    case(app_ready_state)
        IDLE: begin
            if(cfg_pm_turnoff) begin
                next_app_ready_state = WAITING_FOR_CPL_DONE;
            end
        end
        WAITING_FOR_CPL_DONE: begin
            if (rx_nonposted_header_count == tx_completion_header_count) begin
                next_wait_cnt = wait_cnt + 1;
            end else begin
                next_wait_cnt = '0;
            end

            if(cpl_done && rd_done && wait_cnt == TRAFFIC_WAIT_CYCLES) begin
                next_app_ready_state = WAITING_FOR_LTSSM_TO_GO_OUT_OF_L0;
            end
        end
        WAITING_FOR_LTSSM_TO_GO_OUT_OF_L0: begin
            if(ltssm_state_r != 6'h11) begin // Not L0
                next_app_ready_state = IDLE;
            end
        end
        default: begin
            next_app_ready_state = IDLE;
        end
    endcase
end

endmodule
