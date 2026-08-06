
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
// File       : BMD_AXIST_PM_CTRL.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

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
