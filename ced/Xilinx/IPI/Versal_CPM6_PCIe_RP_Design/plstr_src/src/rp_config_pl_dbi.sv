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

import pcie_str_pkg::*;
import pcie_intf_pkg::*;

module rp_config_pl_dbi #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter AUSER = 11,
    parameter RESP_USER = 4
)
(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    link_down, 

    input  rp_cfg_intf              rp_cfg, // Config interface

    pl_dbi_axil_if.master           pl_dbi_axil_if,

    output logic                    cfg_cpl_valid,
    output logic [31:0]             cfg_cpl_data
);

    localparam RESP_SUCCESS = 2'b00;

    typedef enum logic [2:0] {
    IDLE,
    W_RESP,
    R_RESP
    } axi_fsm_state_e;

    axi_fsm_state_e current_state, next_state;

    logic [ADDR_WIDTH -1:0]         awaddr_wire, awaddr_reg;
    logic                           awvalid_wire, awvalid_reg;
    logic [AUSER -1:0]              awuser_wire, awuser_reg;
    logic [2:0]                     awprot_wire, awprot_reg;
    logic [DATA_WIDTH -1:0]         wdata_wire, wdata_reg;
    logic [DATA_WIDTH -1:0]         rdata_wire, rdata_reg;
    logic [DATA_WIDTH/8 -1:0]       wstrb_wire, wstrb_reg;
    logic [DATA_WIDTH/8 -1:0]       wuser_wire, wuser_reg;
    logic                           wvalid_wire, wvalid_reg;
    logic                           bready_wire, bready_reg;
    logic [ADDR_WIDTH -1:0]         araddr_wire, araddr_reg;
    logic                           arvalid_wire, arvalid_reg;
    logic [AUSER -1:0]              aruser_wire, aruser_reg;
    logic [2:0]                     arprot_wire, arprot_reg;
    logic                           rready_wire, rready_reg;
    logic                           ack_err_aximm_wire;
    logic                           ack_success_aximm_wire;


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            awaddr_reg <= '0;
            awvalid_reg <= 1'b0;
            awuser_reg <= '0;
            awprot_reg <= '0;
            wdata_reg <= '0;
            wstrb_reg <= '0;
            wuser_reg <= '0;
            wvalid_reg <= 1'b0;
            bready_reg <= 1'b0;
            araddr_reg <= '0;
            arvalid_reg <= 1'b0;
            aruser_reg <= '0;
            arprot_reg <= '0;
            rready_reg <= 1'b0;
            rdata_reg <= '0;
        end else if (link_down) begin
            current_state <= IDLE; // Reset state on link down
            awaddr_reg <= '0;
            awvalid_reg <= 1'b0;
            awuser_reg <= '0;
            awprot_reg <= '0;
            wdata_reg <= '0;
            wstrb_reg <= '0;
            wuser_reg <= '0;
            wvalid_reg <= 1'b0;
            bready_reg <= 1'b0;
            araddr_reg <= '0;
            arvalid_reg <= 1'b0;
            aruser_reg <= '0;
            arprot_reg <= '0;
            rready_reg <= 1'b0;
            rdata_reg <= '0;
        end else begin
            current_state <= next_state; // Update state
            awaddr_reg <= awaddr_wire;
            awvalid_reg <= awvalid_wire;
            awuser_reg <= awuser_wire;
            awprot_reg <= awprot_wire;
            wdata_reg <= wdata_wire;
            wstrb_reg <= wstrb_wire;
            wuser_reg <= wuser_wire;
            wvalid_reg <= wvalid_wire;
            bready_reg <= bready_wire;
            araddr_reg <= araddr_wire;
            arvalid_reg <= arvalid_wire;
            aruser_reg <= aruser_wire;
            arprot_reg <= arprot_wire;
            rready_reg <= rready_wire;
            rdata_reg <= rdata_wire;
        end
    end

    always_comb begin
        next_state = IDLE; // Default state
        awaddr_wire = awaddr_reg;
        awprot_wire = awprot_reg;
        awuser_wire = awuser_reg;
        awvalid_wire = awvalid_reg;
        wdata_wire = wdata_reg;
        wstrb_wire = wstrb_reg;
        wuser_wire = wuser_reg;
        wvalid_wire = wvalid_reg;
        araddr_wire = araddr_reg;
        arprot_wire = arprot_reg;
        aruser_wire = aruser_reg;
        arvalid_wire = arvalid_reg;
        rdata_wire = rdata_reg;
        cfg_cpl_valid = 1'b0; // Default valid signal
        ack_success_aximm_wire = 'd0;
        ack_err_aximm_wire = 'd0;
            
        case(current_state)   
            IDLE: begin
                if (rp_cfg.valid) begin
                    if (rp_cfg.cfg_type) begin // Read operation
                        if (pl_dbi_axil_if.arready) begin
                            next_state = R_RESP;
                        end
                        araddr_wire = rp_cfg.addr;
                        arvalid_wire = 1'b1;
                    end else begin // Write operation
                        if (pl_dbi_axil_if.awready && pl_dbi_axil_if.wready) begin
                            next_state = W_RESP;
                        end
                        awaddr_wire = rp_cfg.addr;
                        awvalid_wire = 1'b1;
                        wvalid_wire = 1'b1;
                        wdata_wire = rp_cfg.data;
                        wstrb_wire = {(DATA_WIDTH/8){1'b1}};
                    end
                end else begin
                    next_state = IDLE;
                end
            end

            W_RESP: begin
                if(pl_dbi_axil_if.bvalid) begin
                    next_state = IDLE; // If write response is valid, go back to IDLE
                    cfg_cpl_valid = 1'b1; // Indicate write response valid
                    if(pl_dbi_axil_if.bresp==RESP_SUCCESS) begin
                        ack_success_aximm_wire = 1'b1; // Indicate success
                    end else begin
                        ack_err_aximm_wire = 1'b1; // Indicate error
                    end
                end else begin
                    next_state = W_RESP; // Stay in W_RESP until write response is valid
                end
                awvalid_wire = 1'b0;
                wvalid_wire = 1'b0;
            end

            R_RESP: begin
                arvalid_wire = 'd0;
                aruser_wire = 'd0;
                if(pl_dbi_axil_if.rvalid) begin
                    next_state = IDLE; 
                    cfg_cpl_valid = 1'b1; // Indicate read response valid
                    rdata_wire = pl_dbi_axil_if.rdata; // Read data from AXI interface
                    if(pl_dbi_axil_if.rresp==RESP_SUCCESS) begin
                        ack_success_aximm_wire = 1'b1; // Indicate success
                    end else begin
                        ack_err_aximm_wire = 1'b1; // Indicate error
                    end
                end else begin
                    next_state = R_RESP; 
                end
            end

            default: begin
                next_state = IDLE; // Default case to handle unexpected states
            end
        endcase
    end

    assign pl_dbi_axil_if.awaddr = awaddr_wire;
    assign pl_dbi_axil_if.awprot = awprot_wire;
    assign pl_dbi_axil_if.awuser = awuser_wire;
    assign pl_dbi_axil_if.awvalid = awvalid_wire;
    assign pl_dbi_axil_if.bready = bready_wire;
    assign pl_dbi_axil_if.wdata = wdata_wire;
    assign pl_dbi_axil_if.wstrb = wstrb_wire;
    assign pl_dbi_axil_if.wuser = wuser_wire;
    assign pl_dbi_axil_if.wvalid = wvalid_wire;
    assign pl_dbi_axil_if.araddr = araddr_wire;
    assign pl_dbi_axil_if.arprot = arprot_wire;
    assign pl_dbi_axil_if.aruser = aruser_wire;
    assign pl_dbi_axil_if.arvalid = arvalid_wire;
    assign pl_dbi_axil_if.rready = rready_wire;

    assign bready_wire = (current_state==W_RESP);
    assign rready_wire = (current_state==R_RESP);

    assign cfg_cpl_data = rdata_wire; // Assign read data to output

endmodule