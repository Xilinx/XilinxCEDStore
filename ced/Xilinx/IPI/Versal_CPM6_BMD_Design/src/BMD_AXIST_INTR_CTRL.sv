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
//-- Filename: BMD_AXIST_INTR_CTRL.sv
//--
//-- Description: Sends interrupts to MSI-X based on mrd done and mwr done signals
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_INTR_CTRL
  import pcie_intf_pkg::*;
  import bmd_cfg_pkg::*;
(
    input  logic            clk,
    input  logic            rst_n,
    input  logic            init_rst_i,

    input  logic            cfg_int_disable,
    input  logic            cfg_msix_en,
    input  logic            cfg_msi_en,
    input  logic            wr_fifo_empty,

    // EP MEM interrupt configuration
    input  logic            wr_int_en, // Interrupt enable from EP MEM
    input  logic            rd_int_en, // Interrupt enable from EP MEM
    input  logic            rd_done, // Read done signal from EP MEM
    input  logic            wr_done, // Write done signal from EP MEM
    input  logic [1:0]      mrd_int_select, // 00: MSI-X, 01: MSI, 10: INTx
    input  logic [1:0]      mwr_int_select, // 00: MSI-X, 01: MSI, 10: INTx

    // MSI-X Control
    output logic [2:0]      user_func_num,
    output logic [7:0]      user_vfunc_num,
    output logic            user_vfunc_active,
    output logic            user_req,
    output logic [10:0]     user_vector_num,
    input  logic            user_grant,
    output logic [1:0]      user_operation,
    input  logic            user_error,

    input  logic [10:0]     mwr_msix_vec, // From EP MEM
    input  logic [10:0]     mrd_msix_vec, // From EP MEM

    // MSI Control
    output logic [2:0]      pl_msi_func_num,
    output logic [7:0]      pl_msi_vfunc_num,
    output logic            pl_msi_vfunc_active,
    output logic [2:0]      pl_msi_tc,
    output logic [4:0]      pl_msi_vector,
    output logic            pl_issue_msi_req,
    output logic            select_pl,
    input  logic            pl_done,

    // INTx Control
    output tx_intf          tx_intx,
    input  logic            tx_intx_grant,
    input  logic [1:0]      mwr_intx_vec,
    input  logic [1:0]      mrd_intx_vec,

    output logic [31:0]     debug
);

logic comb_reset;
assign comb_reset = ~rst_n | init_rst_i;

logic wr_done_r, wr_done_r2, wr_done_r3, wr_done_r4,
      wr_done_r5, wr_done_r6, wr_done_r7, wr_done_r8,
      wr_done_r9, wr_done_r10;

localparam logic [3:0]      IDLE                = 4'b0000;
localparam logic [3:0]      RD_GRANT            = 4'b0001;
localparam logic [3:0]      WR_GRANT            = 4'b0010;
localparam logic [3:0]      WAIT_INTX_RD_GRANT  = 4'b0011;
localparam logic [3:0]      WAIT_INTX_WR_GRANT  = 4'b0100;
localparam logic [3:0]      WAIT_FOR_GRANT_LOW  = 4'b0101;
localparam logic [3:0]      RD_DONE             = 4'b0110;
localparam logic [3:0]      WR_DONE             = 4'b0111;
localparam logic [3:0]      WAIT_FOR_DONE_LOW   = 4'b1000;

tx_intf next_tx_intx;
tx_data_p intx_hdr;
assign intx_hdr.fmt            = 2'b01;
assign intx_hdr.ttype          = 5'b10100; // See table 2-3 in PCIe Spec 6.2
assign intx_hdr.tc             = '0;
assign intx_hdr.attr           = '0;
assign intx_hdr.remote_req_id  = '0;
assign intx_hdr.tid            = '0; // Tag
assign intx_hdr.t_bit          = '0; // T bit in IDE prefix
assign intx_hdr.func_num       = FUNC_NUM;
assign intx_hdr.vfunc_num      = VFUNC_NUM;
assign intx_hdr.vfunc_active   = VFUNC_ACTIVE;
assign intx_hdr.td             = '0; // TLP Digest
assign intx_hdr.byte_len       = '0;
assign intx_hdr.byte_en        = '0; // Message code
assign intx_hdr.ats            = '0;
assign intx_hdr.nw             = '0; // no-write
assign intx_hdr.th             = '0;
assign intx_hdr.ph             = '0;
assign intx_hdr.st             = '0;
assign intx_hdr.ep             = '0;
assign intx_hdr.bad_eot        = 1'b0; // Bad packet
assign intx_hdr.atu_bypass     = 1'b1;
assign intx_hdr.addr_align_en  = 1'b0;
assign intx_hdr.prfx           = '0;
assign intx_hdr.segment        = '0;
assign intx_hdr.dst_segment    = '0;
assign intx_hdr.hdr_prot       = '0;
assign intx_hdr.reserved       = '0;
assign intx_hdr.addr           = '0;

logic [7:0] msg_code_read;
logic [7:0] msg_code_write;
assign msg_code_read = {6'b001000, mrd_intx_vec};
assign msg_code_write = {6'b001000, mwr_intx_vec};


logic [3:0] state, next_state;
logic rd_int_done, wr_int_done;
logic rd_int_done_r, wr_int_done_r;

// MSI
assign pl_msi_func_num      = FUNC_NUM;
assign pl_msi_vfunc_num     = VFUNC_NUM;
assign pl_msi_vfunc_active  = VFUNC_ACTIVE;
assign pl_msi_tc            = '0;
assign select_pl            = 1'b1;

// MSI-X
assign user_func_num        = FUNC_NUM;
assign user_vfunc_num       = VFUNC_NUM;
assign user_vfunc_active    = VFUNC_ACTIVE;

assign debug = {
    8'h000,
    user_error,
    wr_int_done_r,
    rd_int_done_r,
    state,
    user_operation,
    user_grant,
    user_vector_num,
    user_req,
    wr_done,
    rd_done,
    rd_int_en,
    wr_int_en
};

always @(posedge clk) begin
    if (comb_reset) begin
        state = IDLE;
        rd_int_done_r <= '0;
        wr_int_done_r <= '0;
        tx_intx <= '0;

        wr_done_r <= '0;
        wr_done_r2 <= '0;
        wr_done_r3 <= '0;
        wr_done_r4 <= '0;
        wr_done_r5 <= '0;
        wr_done_r6 <= '0;
        wr_done_r7 <= '0;
        wr_done_r8 <= '0;
        wr_done_r9 <= '0;
        wr_done_r10 <= '0;
    end else begin
        state = next_state;
        rd_int_done_r <= rd_int_done;
        wr_int_done_r <= wr_int_done;
        tx_intx <= next_tx_intx;

        // Delay wr done signal to give writes
        // time to finish sending
        wr_done_r <= wr_done;
        wr_done_r2 <= wr_done_r;
        wr_done_r3 <= wr_done_r2;
        wr_done_r4 <= wr_done_r3;
        wr_done_r5 <= wr_done_r4;
        wr_done_r6 <= wr_done_r5;
        wr_done_r7 <= wr_done_r6;
        wr_done_r8 <= wr_done_r7;
        wr_done_r9 <= wr_done_r8;
        wr_done_r10 <= wr_done_r9;
    end
end
always_comb begin
    next_state          = state;
    wr_int_done         = wr_int_done_r;
    rd_int_done         = rd_int_done_r;

    // INTx
    next_tx_intx        = tx_intx;

    // MSI
    pl_msi_vector       = '0;
    pl_issue_msi_req    = '0;

    // MSI-X
    user_req = '0;
    user_vector_num = '0;
    user_operation = '0;

    case (state)
        IDLE : begin
            // Try to send read interrupt
            if (!rd_int_done_r && rd_done && rd_int_en) begin
                case(mrd_int_select)

                    // Send MSI-X intterupt
                    2'b00 : begin
                        if(cfg_msix_en) begin
                            user_req        = 1'b1;
                            user_vector_num = mrd_msix_vec;
                            user_operation  = 2'b00;
                            next_state      = RD_GRANT;
                        end else begin
                            rd_int_done = 1'b1;
                        end
                    end

                    // Send MSI Interrupt
                    2'b01 : begin
                        if (cfg_msi_en) begin
                            pl_msi_vector       = mrd_msix_vec[4:0];
                            pl_issue_msi_req    = 1'b1;
                            next_state          = RD_DONE;
                        end else begin
                            rd_int_done = 1'b1;
                        end
                    end

                    // Send INTx interrupt
                    2'b10 : begin
                        if (!cfg_int_disable) begin
                            next_tx_intx.tx_valid               = 1'b1;
                            next_tx_intx.tx_data[0]             = intx_hdr;
                            next_tx_intx.tx_data[0].p.byte_en   = msg_code_read;
                            next_tx_intx.tx_start[0]            = 1'b1;
                            next_tx_intx.tx_end[0]              = 1'b1;
                            next_state                          = WAIT_INTX_RD_GRANT;
                        end else begin
                            rd_int_done = 1'b1;
                        end
                    end

                    default : begin
                        rd_int_done = 1'b1;
                    end

                endcase
            // Try to send write interrupt
            end else if (!wr_int_done_r && wr_done_r10 && wr_int_en && wr_fifo_empty) begin
                case(mwr_int_select)

                    // Send MSI-X interrupt
                    2'b00 : begin
                        if (cfg_msix_en) begin
                            user_req        = 1'b1;
                            user_vector_num = mwr_msix_vec;
                            user_operation  = 2'b00;
                            next_state      = WR_GRANT;
                        end else begin
                            wr_int_done = 1'b1;
                        end
                    end

                    // Send MSI Interrupt
                    2'b01 : begin
                        if (cfg_msi_en) begin
                            pl_msi_vector       = mwr_msix_vec[4:0];
                            pl_issue_msi_req    = 1'b1;
                            next_state          = WR_DONE;
                        end else begin
                            wr_int_done = 1'b1;
                        end
                    end

                    // Send INTx interrupt
                    2'b10 : begin
                        if (!cfg_int_disable) begin
                            next_tx_intx.tx_valid               = 1'b1;
                            next_tx_intx.tx_data[0]             = intx_hdr;
                            next_tx_intx.tx_data[0].p.byte_en   = msg_code_write;
                            next_tx_intx.tx_start[0]            = 1'b1;
                            next_tx_intx.tx_end[0]              = 1'b1;
                            next_state                          = WAIT_INTX_WR_GRANT;
                        end else begin
                            wr_int_done = 1'b1;
                        end
                    end

                    default : begin
                        wr_int_done = 1'b1;
                    end

                endcase

            end
        end

        ////////////////////////////////////////////////////////////////
        // MSI States
        ////////////////////////////////////////////////////////////////
        RD_DONE : begin
            if (pl_done) begin
                next_state  = WAIT_FOR_DONE_LOW;
                rd_int_done = 1'b1;
            end else begin
                pl_msi_vector       = mrd_msix_vec[4:0];
                pl_issue_msi_req    = 1'b1;
            end
        end

        WR_DONE : begin
            if (pl_done) begin
                next_state  = WAIT_FOR_DONE_LOW;
                wr_int_done = 1'b1;
            end else begin
                pl_msi_vector       = mwr_msix_vec[4:0];
                pl_issue_msi_req    = 1'b1;
            end
        end

        WAIT_FOR_DONE_LOW : begin
            if (!pl_done) begin
                next_state = IDLE;
            end
        end

        ////////////////////////////////////////////////////////////////
        // MSI-X States
        ////////////////////////////////////////////////////////////////
        RD_GRANT : begin // MSI-X : Wait for grant before de-asserting
            if (user_grant) begin
                next_state  = WAIT_FOR_GRANT_LOW;
                rd_int_done = 1'b1;
            end else begin
                user_req        = 1'b1;
                user_vector_num = mrd_msix_vec;
                user_operation  = 2'b00;
            end
        end

        WR_GRANT : begin // MSI-X : Wait for grant before de-asserting
            if (user_grant) begin
                next_state  = WAIT_FOR_GRANT_LOW;
                wr_int_done = 1'b1;
            end else begin
                user_req        = 1'b1;
                user_vector_num = mwr_msix_vec;
                user_operation  = 2'b00;
            end
        end

        ////////////////////////////////////////////////////////////////
        // INTx States
        ////////////////////////////////////////////////////////////////
        WAIT_INTX_RD_GRANT : begin
            if (tx_intx_grant) begin
                rd_int_done     = 1'b1;
                next_tx_intx    = '0;
                next_state      = IDLE;
            end
        end

        WAIT_INTX_WR_GRANT : begin
            if (tx_intx_grant) begin
                wr_int_done     = 1'b1;
                next_tx_intx    = '0;
                next_state      = IDLE;
            end
        end

        WAIT_FOR_GRANT_LOW : begin
            if (!user_grant) begin
                next_state = IDLE;
            end
        end

        default : begin
            next_state = IDLE;
        end
    endcase
end

endmodule // BMD_AXIST_INTR_CTRL
