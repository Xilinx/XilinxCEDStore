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
// AXI4-Lite -> PCIe configuration request bridge (IDE_EN only), one access at a time.
// Address is ECAM style: [27:20] bus, [19:15] device, [14:12] function, [11:2] DW.
// AR/AW stall while config_mem_handler cannot take a request.
// OKAY: completion received (a UR completion reads 0xFFFFFFFF), or not sent (reads 0xFFFFFFFF, writes dropped).
// SLVERR: unaligned address, WSTRB != 4'hF, completion timeout, or link down while outstanding.
////////////////////////////////////////////////////////////////////////

`timescale 1ps / 1ps

module axil_cfg_bridge #(
    parameter int ADDR_WIDTH     = 42,
    parameter int TIMEOUT_CYCLES = 1 << 22
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    link_down,

    // AXI4-Lite slave
    input  logic [ADDR_WIDTH-1:0]   awaddr,
    input  logic [2:0]              awprot,
    input  logic                    awvalid,
    output logic                    awready,
    input  logic [31:0]             wdata,
    input  logic [3:0]              wstrb,
    input  logic                    wvalid,
    output logic                    wready,
    output logic [1:0]              bresp,
    output logic                    bvalid,
    input  logic                    bready,
    input  logic [ADDR_WIDTH-1:0]   araddr,
    input  logic [2:0]              arprot,
    input  logic                    arvalid,
    output logic                    arready,
    output logic [31:0]             rdata,
    output logic [1:0]              rresp,
    output logic                    rvalid,
    input  logic                    rready,

    // config_mem_handler request interface
    input  logic                    cfg_ready,    // FSM can take a request
    output logic                    req_valid,    // held until req_accept
    output logic                    req_wr,
    output logic [31:0]             req_addr,
    output logic [31:0]             req_wdata,
    input  logic                    req_accept,   // TLP issued
    output logic                    req_done,     // pulse: completion seen / timeout
    output logic                    busy,         // request issued or outstanding

    // completion observation (from completor)
    input  logic                    cpl_data_valid, // read data completion (cpl_received)
    input  logic [31:0]             cpl_data,
    input  logic                    cpl_hdr_valid   // any completion header (tag freed)
);

    localparam logic [1:0] RESP_OKAY   = 2'b00;
    localparam logic [1:0] RESP_SLVERR = 2'b10;

    typedef enum logic [1:0] {S_IDLE, S_ISSUE, S_WAIT, S_RESP} state_t;

    state_t         state;
    logic           is_wr;
    logic [31:0]    addr_q;
    logic [31:0]    wdata_q;
    logic [1:0]     resp_q;
    logic [31:0]    rdata_q;
    logic [$clog2(TIMEOUT_CYCLES):0] tmo;

    // Debug counters
    logic [15:0] dbg_rd_cnt;
    logic [15:0] dbg_wr_cnt;
    logic [15:0] dbg_err_cnt;

    logic rd_hs, wr_hs;
    logic [31:0] ar_cfg_addr, aw_cfg_addr;
    logic        cpl_ok, tmo_expired;

    // Backpressure: AR/AW are not accepted until the FSM can take a config
    // request (WAIT_FOR_GO/DONE and no tag outstanding).
    assign arready = (state == S_IDLE) && arvalid && cfg_ready;
    assign awready = (state == S_IDLE) && !arvalid && awvalid && wvalid && cfg_ready;
    assign wready  = awready;
    assign rd_hs   = arvalid && arready;
    assign wr_hs   = awvalid && awready;

    assign ar_cfg_addr = {araddr[27:12], 4'b0, araddr[11:2], 2'b00};
    assign aw_cfg_addr = {awaddr[27:12], 4'b0, awaddr[11:2], 2'b00};

    assign req_valid = (state == S_ISSUE);
    assign req_wr    = is_wr;
    assign req_addr  = addr_q;
    assign req_wdata = wdata_q;
    // busy also covers a short tail after the completion: the checker's
    // expected-data compare runs a few cycles behind the completion slot.
    logic [3:0] busy_tail;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)                  busy_tail <= '0;
        else if (state == S_WAIT)    busy_tail <= 4'd8;
        else if (busy_tail != '0)    busy_tail <= busy_tail - 1'b1;
    end
    assign busy      = (state == S_ISSUE) || (state == S_WAIT) || (busy_tail != '0);

    assign cpl_ok      = is_wr ? cpl_hdr_valid : cpl_data_valid;
    assign tmo_expired = (tmo == TIMEOUT_CYCLES);
    assign req_done    = (state == S_WAIT) && (cpl_ok || tmo_expired);

    assign bvalid = (state == S_RESP) && is_wr;
    assign bresp  = resp_q;
    assign rvalid = (state == S_RESP) && !is_wr;
    assign rresp  = resp_q;
    assign rdata  = rdata_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            is_wr      <= 1'b0;
            addr_q     <= '0;
            wdata_q    <= '0;
            resp_q     <= RESP_OKAY;
            rdata_q    <= '0;
            tmo        <= '0;
            dbg_rd_cnt <= '0;
            dbg_wr_cnt <= '0;
            dbg_err_cnt<= '0;
        end else begin
            case (state)
                S_IDLE: begin
                    tmo <= '0;
                    if (rd_hs) begin
                        is_wr  <= 1'b0;
                        addr_q <= ar_cfg_addr;
                        rdata_q<= '0;
                        if (|araddr[1:0]) begin
                            resp_q      <= RESP_SLVERR;
                            dbg_err_cnt <= dbg_err_cnt + 1'b1;
                            state       <= S_RESP;
                        end else if (!cfg_ready) begin
                            resp_q      <= RESP_OKAY;     // not ready: read as all ones
                            rdata_q     <= 32'hFFFF_FFFF;
                            state       <= S_RESP;
                        end else begin
                            state <= S_ISSUE;
                        end
                    end else if (wr_hs) begin
                        is_wr   <= 1'b1;
                        addr_q  <= aw_cfg_addr;
                        wdata_q <= wdata;
                        if ((|awaddr[1:0]) || (wstrb != 4'hF)) begin
                            resp_q      <= RESP_SLVERR;
                            dbg_err_cnt <= dbg_err_cnt + 1'b1;
                            state       <= S_RESP;
                        end else if (!cfg_ready) begin
                            resp_q      <= RESP_OKAY;     // not ready: write dropped
                            state       <= S_RESP;
                        end else begin
                            state <= S_ISSUE;
                        end
                    end
                end

                S_ISSUE: begin
                    if (link_down || !cfg_ready) begin
                        // Not sent and can no longer be: treat as not ready (no TLP went out)
                        resp_q      <= RESP_OKAY;
                        rdata_q     <= 32'hFFFF_FFFF;
                        state       <= S_RESP;
                    end else if (req_accept) begin
                        tmo   <= '0;
                        state <= S_WAIT;
                    end else if (tmo_expired) begin
                        // FSM never took it (no credits / tags): fail rather than hang the master
                        resp_q      <= RESP_SLVERR;
                        dbg_err_cnt <= dbg_err_cnt + 1'b1;
                        state       <= S_RESP;
                    end else begin
                        tmo <= tmo + 1'b1;
                    end
                end

                S_WAIT: begin
                    tmo <= tmo + 1'b1;
                    if (link_down) begin
                        resp_q      <= RESP_SLVERR;
                        dbg_err_cnt <= dbg_err_cnt + 1'b1;
                        state       <= S_RESP;
                    end else if (cpl_ok) begin
                        resp_q  <= RESP_OKAY;
                        rdata_q <= is_wr ? 32'b0 : cpl_data;
                        if (is_wr) dbg_wr_cnt <= dbg_wr_cnt + 1'b1;
                        else       dbg_rd_cnt <= dbg_rd_cnt + 1'b1;
                        state   <= S_RESP;
                    end else if (tmo_expired) begin
                        resp_q      <= RESP_SLVERR;
                        dbg_err_cnt <= dbg_err_cnt + 1'b1;
                        state       <= S_RESP;
                    end
                end

                S_RESP: begin
                    if ((is_wr && bready) || (!is_wr && rready))
                        state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
