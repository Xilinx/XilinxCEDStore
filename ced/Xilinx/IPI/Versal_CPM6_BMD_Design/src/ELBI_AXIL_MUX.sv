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
//-- Filename: ELBI_AXIL_MUX.sv
//--
//-- Description: Handles multiple consumers of ELBI AXIL interface
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module ELBI_AXIL_MUX #(
    parameter int                       CONSUMERS = 2
)(
    input  logic                        clk,
    input  logic                        rst_n,

    axil_intf_defs_cpm6.slave           elbi_axil,

    output logic [CONSUMERS-1:0][63:0]  consumer_araddr,
    output logic [CONSUMERS-1:0][2:0]   consumer_arprot,
    input  logic [CONSUMERS-1:0]        consumer_arready,
    output logic [CONSUMERS-1:0][7:0]   consumer_aruser,
    output logic [CONSUMERS-1:0]        consumer_arvalid,
    input  logic [CONSUMERS-1:0][63:0]  consumer_rdata,
    output logic [CONSUMERS-1:0]        consumer_rready,
    input  logic [CONSUMERS-1:0][1:0]   consumer_rresp,
    input  logic [CONSUMERS-1:0][7:0]   consumer_ruser,
    input  logic [CONSUMERS-1:0]        consumer_rvalid,
    output logic [CONSUMERS-1:0][63:0]  consumer_awaddr,
    output logic [CONSUMERS-1:0][2:0]   consumer_awprot,
    input  logic [CONSUMERS-1:0]        consumer_awready,
    output logic [CONSUMERS-1:0][7:0]   consumer_awuser,
    output logic [CONSUMERS-1:0]        consumer_awvalid,
    output logic [CONSUMERS-1:0]        consumer_bready,
    input  logic [CONSUMERS-1:0][1:0]   consumer_bresp,
    input  logic [CONSUMERS-1:0][7:0]   consumer_buser,
    input  logic [CONSUMERS-1:0]        consumer_bvalid,
    output logic [CONSUMERS-1:0][63:0]  consumer_wdata,
    output logic [CONSUMERS-1:0][7:0]   consumer_wuser,
    input  logic [CONSUMERS-1:0]        consumer_wready,
    output logic [CONSUMERS-1:0][7:0]   consumer_wstrb,
    output logic [CONSUMERS-1:0]        consumer_wvalid
);

logic [CONSUMERS-1:0] ar_handshake_done, next_ar_handshake_done;
logic [CONSUMERS-1:0] aw_handshake_done, next_aw_handshake_done;
logic [CONSUMERS-1:0] w_handshake_done,  next_w_handshake_done;

typedef enum logic [1:0] {
    WAIT_FOR_ARVALID,
    WAIT_FOR_CONSUMERS_RVALID,
    WAIT_FOR_RREADY
} read_state_t;
read_state_t read_state, next_read_state;

typedef enum logic [2:0] {
    WAIT_FOR_A_W_VALID,
    WAIT_FOR_WVALID,
    WAIT_FOR_AWVALID,
    WAIT_FOR_CONSUMER_BVALID,
    WAIT_FOR_BREADY
} write_state_t;
write_state_t write_state, next_write_state;

always @(posedge clk) begin
    if (!rst_n) begin
        read_state  <= WAIT_FOR_ARVALID;
        write_state <= WAIT_FOR_A_W_VALID;

        ar_handshake_done   <= '0;
        aw_handshake_done   <= '0;
        w_handshake_done    <= '0;
    end else begin
        read_state <= next_read_state;
        write_state <= next_write_state;

        ar_handshake_done   <= next_ar_handshake_done;
        aw_handshake_done   <= next_aw_handshake_done;
        w_handshake_done    <= next_w_handshake_done;
    end
end

// Drive signals going to consumers
always_comb begin
    for (int i = 0; i < CONSUMERS; i++) begin
        consumer_araddr[i]   = elbi_axil.araddr;
        consumer_arprot[i]   = elbi_axil.arprot;
        consumer_aruser[i]   = elbi_axil.aruser;
        consumer_awaddr[i]   = elbi_axil.awaddr;
        consumer_awprot[i]   = elbi_axil.awprot;
        consumer_awuser[i]   = elbi_axil.awuser;
        consumer_wdata[i]    = elbi_axil.wdata;
        consumer_wuser[i]    = elbi_axil.wuser;
        consumer_wstrb[i]    = elbi_axil.wstrb;
    end
end

// Read
always_comb begin
    next_read_state = read_state;

    elbi_axil.arready   = 1'b0;
    elbi_axil.rvalid    = 1'b0;

    elbi_axil.rdata     = 64'h0;
    elbi_axil.rresp     = 2'b00;
    elbi_axil.ruser     = 8'h00;

    consumer_rready     = '0;
    consumer_arvalid    = '0;

    next_ar_handshake_done = ar_handshake_done;

    case (read_state)
        WAIT_FOR_ARVALID : begin
            for (int i = 0; i < CONSUMERS; i++) begin
                if (!ar_handshake_done[i]) begin // If handshake isn't done, pass valid
                    consumer_arvalid[i] = elbi_axil.arvalid;
                end

                if (elbi_axil.arvalid && consumer_arready[i]) begin
                    next_ar_handshake_done[i] = 1'b1;
                end
            end

            if (&next_ar_handshake_done) begin // All handshakes done on consumer side
                next_read_state = WAIT_FOR_CONSUMERS_RVALID;
            end else begin
                for (int i = 0; i < CONSUMERS; i++) begin
                    if (next_ar_handshake_done[i] && consumer_rvalid[i]) begin // Some consumer already completed their handshake and is responding
                        elbi_axil.arready = 1'b1; // Finish handshake on producer side once we have valid response
                        next_read_state = WAIT_FOR_RREADY;
                        break;
                    end
                end
            end
        end

        WAIT_FOR_CONSUMERS_RVALID : begin
            if (|consumer_rvalid) begin
                elbi_axil.arready = 1'b1; // Finish handshake on producer side once we have valid response
                next_read_state = WAIT_FOR_RREADY;
            end
        end

        WAIT_FOR_RREADY : begin
            next_ar_handshake_done = '0;
            consumer_rready = {CONSUMERS{elbi_axil.rready}};
            for (int i = 0; i < CONSUMERS; i++) begin
                if (consumer_rvalid[i]) begin
                    elbi_axil.rdata = consumer_rdata[i];
                    elbi_axil.rresp = consumer_rresp[i];
                    elbi_axil.ruser = consumer_ruser[i];
                    elbi_axil.rvalid = 1'b1;

                    if (elbi_axil.rready) next_read_state = WAIT_FOR_ARVALID;
                    break;
                end
            end
        end

        default : next_read_state = WAIT_FOR_ARVALID;
    endcase
end

// Write
always_comb begin
    next_write_state = write_state;

    elbi_axil.awready   = 1'b0;
    elbi_axil.wready    = 1'b0;
    elbi_axil.bvalid    = 1'b0;

    elbi_axil.bresp   = 2'b00;
    elbi_axil.buser   = 8'h00;

    consumer_bready   = '0;
    consumer_awvalid  = '0;
    consumer_wvalid   = '0;

    next_aw_handshake_done  = aw_handshake_done;
    next_w_handshake_done   = w_handshake_done;

    case (write_state)
        WAIT_FOR_A_W_VALID : begin
            for (int i = 0; i < CONSUMERS; i++) begin
                if (!aw_handshake_done[i]) begin // If handshake isn't done, pass valid
                    consumer_awvalid[i] = elbi_axil.awvalid;
                end

                if (elbi_axil.awvalid && consumer_awready[i]) begin
                    next_aw_handshake_done[i] = 1'b1;
                end

                if (!w_handshake_done[i]) begin // If handshake isn't done, pass valid
                    consumer_wvalid[i] = elbi_axil.wvalid;
                end

                if (elbi_axil.wvalid && consumer_wready[i]) begin
                    next_w_handshake_done[i] = 1'b1;
                end
            end


            if ((&next_aw_handshake_done) && (&next_w_handshake_done)) begin
                next_write_state = WAIT_FOR_CONSUMER_BVALID;
            end else if (&next_aw_handshake_done) begin
                next_write_state = WAIT_FOR_WVALID;
            end else if (&next_w_handshake_done) begin
                next_write_state = WAIT_FOR_AWVALID;
            end else begin
                for (int i = 0; i < CONSUMERS; i++) begin // Some consumer already completed their handshake and is responding
                    if (next_aw_handshake_done[i] && next_w_handshake_done[i] && consumer_bvalid[i]) begin
                        elbi_axil.awready = 1'b1; // finish handshake
                        elbi_axil.wready  = 1'b1; // finish handshake
                        next_write_state = WAIT_FOR_BREADY;
                        break;
                    end
                end
            end
        end

        WAIT_FOR_WVALID : begin
            for (int i = 0; i < CONSUMERS; i++) begin
                if (!w_handshake_done[i]) begin // If handshake isn't done, pass valid
                    consumer_wvalid[i] = elbi_axil.wvalid;
                end

                if (elbi_axil.wvalid && consumer_wready[i]) begin
                    next_w_handshake_done[i] = 1'b1;
                end
            end

            if (&next_w_handshake_done) begin
                next_write_state = WAIT_FOR_CONSUMER_BVALID;
            end else begin
                for (int i = 0; i < CONSUMERS; i++) begin // Some consumer already completed their handshake and is responding
                    if (next_aw_handshake_done[i] && next_w_handshake_done[i] && consumer_bvalid[i]) begin
                        elbi_axil.awready = 1'b1; // finish handshake
                        elbi_axil.wready  = 1'b1; // finish handshake
                        next_write_state = WAIT_FOR_BREADY;
                        break;
                    end
                end
            end
        end

        WAIT_FOR_AWVALID : begin
            for (int i = 0; i < CONSUMERS; i++) begin
                if (!aw_handshake_done[i]) begin // If handshake isn't done, pass valid
                    consumer_awvalid[i] = elbi_axil.awvalid;
                end

                if (elbi_axil.awvalid && consumer_awready[i]) begin
                    next_aw_handshake_done[i] = 1'b1;
                end
            end

            if (&next_aw_handshake_done) begin
                next_write_state = WAIT_FOR_CONSUMER_BVALID;
            end else begin
                for (int i = 0; i < CONSUMERS; i++) begin // Some consumer already completed their handshake and is responding
                    if (next_aw_handshake_done[i] && next_w_handshake_done[i] && consumer_bvalid[i]) begin
                        elbi_axil.awready = 1'b1; // finish handshake
                        elbi_axil.wready  = 1'b1; // finish handshake
                        next_write_state = WAIT_FOR_BREADY;
                        break;
                    end
                end
            end
        end

        WAIT_FOR_CONSUMER_BVALID : begin
            if (|consumer_bvalid) begin
                elbi_axil.awready = 1'b1; // finish handshake
                elbi_axil.wready  = 1'b1; // finish handshake
                next_write_state = WAIT_FOR_BREADY;
            end
        end

        WAIT_FOR_BREADY : begin
            next_aw_handshake_done = '0;
            next_w_handshake_done = '0;
            consumer_bready = {CONSUMERS{elbi_axil.bready}};
            for (int i = 0; i < CONSUMERS; i++) begin
                if (consumer_bvalid[i]) begin
                    elbi_axil.bresp = consumer_bresp[i];
                    elbi_axil.buser = consumer_buser[i];
                    elbi_axil.bvalid = 1'b1;

                    if (elbi_axil.bready) next_write_state = WAIT_FOR_A_W_VALID;
                    break;
                end
            end
        end

        default : next_write_state = WAIT_FOR_A_W_VALID;
    endcase
end

endmodule
