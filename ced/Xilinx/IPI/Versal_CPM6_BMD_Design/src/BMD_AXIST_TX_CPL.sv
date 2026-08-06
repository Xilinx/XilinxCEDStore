
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
// File       : BMD_AXIST_TX_CPL.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_TX_CPL.sv
//--
//-- Description: Sends completions back for reads received from RP.
//--              Uses information provided from the BMD_AXIST_RX_RW module.
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_TX_CPL
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
  import bmd_cfg_pkg::*;
(
    input  logic                clk,
    input  logic                rst_n,
    // From RX RW
    output logic                cpl_done,
    input  logic                req_compl,
    input  logic                req_compl_wd,
    input  logic                req_compl_ur,
    input  logic [2:0]          req_tc,
    input  logic [9:0]          req_len,
    input  logic [13:0]         req_lookup_id,

    output logic [255:0]        app_hdr_log, // The header of the TLP that contained the error
    output logic                app_hdr_flitmode, // One-clock-cycle pulse indicating that the data app_hdr_log is on flit mode
    output logic [4:0]          app_hdr_log_size, // Indicates the Header Log Size in Dwords.
    output logic [27:0]         app_err_bus, // The type of error that your application detected.
    output logic                app_err_advisory, // Indicates that your application error is an advisory error.
    output logic                app_poisoned_tlp_type, // 0b: The received poisoned TLP is a write request.
                                                       // 1b: The received poisoned TLP is a completion TLP.
    output logic [2:0]          app_err_func_num, // The number of the function that is reporting the error indicated app_err_bus

    // From EP MEM
    input  logic [31:0]         rd_data,

    output tx_intf              cpl_tx,

    output logic [31:0]         debug
);

assign app_hdr_log              = '0;
assign app_hdr_flitmode         = '0;
assign app_hdr_log_size         = '0;
assign app_err_bus              = '0;
assign app_err_advisory         = '0;
assign app_poisoned_tlp_type    = '0;
assign app_err_func_num         = '0;

tx_intf cpl_tx_r, next_cpl_tx;
assign cpl_tx = cpl_tx_r;

localparam logic [1:0]      IDLE     = 2'b00;
localparam logic [1:0]      CPL_DATA = 2'b01;
localparam logic [1:0]      CPL_UR   = 2'b10;

logic [1:0]         state_r, next_state;

logic [2:0]          req_tc_r, req_tc_r_r;
logic [9:0]          req_len_r, req_len_r_r;
logic [13:0]         req_lookup_id_r, req_lookup_id_r_r;

logic                req_compl_wd_r;
logic                req_compl_ur_r;
logic                req_compl_r;

logic                req_compl_wd_r_r;
logic                req_compl_ur_r_r;
logic                req_compl_r_r;

logic [9:0]          len_cnt_r, next_len_cnt;
logic [9:0]          data_ind;
logic                done, next_done;

logic [$clog2(NUM_SLOTS):0]          curr_slot, next_slot;

assign cpl_done = done;

tx_data_cpl cpl_hdr;

assign debug = {
    5'h00,
    done,
    req_compl_wd_r,
    req_compl_ur_r,
    req_compl_r
};

///////////////////////////////////////////////////////////////////
// Assign header content
///////////////////////////////////////////////////////////////////
assign cpl_hdr.status           = '0;
assign cpl_hdr.addr             = '0; // filled by lookup id
assign cpl_hdr.fmt              = 2'b10; // 3 DW w/ data
assign cpl_hdr.ttype            = 5'b01010;
assign cpl_hdr.tc               = req_tc_r_r;
assign cpl_hdr.attr             = '0; // filled by lookup id
assign cpl_hdr.remote_req_id    = '0; // filled by lookup id
assign cpl_hdr.tid              = '0; // filled by lookup id
assign cpl_hdr.t_bit            = '0;
assign cpl_hdr.func_num         = FUNC_NUM;
assign cpl_hdr.vfunc_num        = VFUNC_NUM;
assign cpl_hdr.vfunc_active     = VFUNC_ACTIVE;
assign cpl_hdr.td               = '0;
assign cpl_hdr.byte_len         = req_len_r_r << 2; // dword -> byte
assign cpl_hdr.byte_en          = '1;
assign cpl_hdr.ats              = '0;
assign cpl_hdr.nw               = '0;
assign cpl_hdr.th               = '0;
assign cpl_hdr.ph               = '0;
assign cpl_hdr.st               = '0;
assign cpl_hdr.ep               = '0;
assign cpl_hdr.bad_eot          = '0;
assign cpl_hdr.atu_bypass       = '1;
assign cpl_hdr.addr_align_en    = '0; // Always 0 for cmpl
assign cpl_hdr.bcm              = '0;
assign cpl_hdr.byte_cnt         = '0; // Remaining bytes to be sent
assign cpl_hdr.prfx             = '0;
assign cpl_hdr.segment          = '0;
assign cpl_hdr.dst_segment      = '0;
assign cpl_hdr.lookup_id        = req_lookup_id_r_r;
generate if (HDR_PROT_CHECK == 1'b1) begin : g_hdr_prot
    assign cpl_hdr.hdr_prot[0]    = ^cpl_hdr.th;
    assign cpl_hdr.hdr_prot[1]    = ^cpl_hdr.st;
    assign cpl_hdr.hdr_prot[2]    = ^cpl_hdr.ph;
    assign cpl_hdr.hdr_prot[3]    = ^cpl_hdr.vfunc_active;
    assign cpl_hdr.hdr_prot[4]    = ^cpl_hdr.vfunc_num;
    assign cpl_hdr.hdr_prot[5]    = '0; // tlp_ln unused
    assign cpl_hdr.hdr_prot[6]    = ^cpl_hdr.func_num;
    assign cpl_hdr.hdr_prot[7]    = ^cpl_hdr.attr;
    assign cpl_hdr.hdr_prot[8]    = ^cpl_hdr.addr_align_en;
    assign cpl_hdr.hdr_prot[9]    = ^cpl_hdr.byte_en;
    assign cpl_hdr.hdr_prot[10]   = ^cpl_hdr.remote_req_id;
    assign cpl_hdr.hdr_prot[11]   = ^cpl_hdr.status;
    assign cpl_hdr.hdr_prot[12]   = '0; // cpl_bcm unused
    assign cpl_hdr.hdr_prot[13]   = ^cpl_hdr.byte_cnt;
    assign cpl_hdr.hdr_prot[14]   = ^cpl_hdr.tid;
    assign cpl_hdr.hdr_prot[15]   = ^cpl_hdr.byte_len;
    assign cpl_hdr.hdr_prot[16]   = ^cpl_hdr.ep;
    assign cpl_hdr.hdr_prot[17]   = ^cpl_hdr.td;
    assign cpl_hdr.hdr_prot[18]   = ^cpl_hdr.tc;
    assign cpl_hdr.hdr_prot[19]   = ^cpl_hdr.ttype;
    assign cpl_hdr.hdr_prot[20]   = ^cpl_hdr.fmt;
    assign cpl_hdr.hdr_prot[21]   = ^cpl_hdr.addr;
end else begin : g_no_hdr_prot
    assign cpl_hdr.hdr_prot = '0;
end
endgenerate
assign cpl_hdr.reserved         = '0;

always @(posedge clk) begin
    if (!rst_n) begin
        req_tc_r                <= '0;
        req_len_r               <= '0;
        req_compl_wd_r          <= '0;
        req_compl_ur_r          <= '0;
        req_compl_r             <= '0;
        req_lookup_id_r         <= '0;

        done                    <= '1;
        cpl_tx_r                <= '0;
        state_r                 <= '0;
        len_cnt_r               <= '0;

        curr_slot               <= '0;
    end else begin
        cpl_tx_r                <= next_cpl_tx;
        state_r                 <= next_state;
        len_cnt_r               <= next_len_cnt;

        req_compl_wd_r          <= req_compl_wd;
        req_compl_ur_r          <= req_compl_ur;
        req_compl_r             <= req_compl;

        req_compl_wd_r_r        <= req_compl_wd_r;
        req_compl_ur_r_r        <= req_compl_ur_r;
        req_compl_r_r           <= req_compl_r;

        req_tc_r                <= req_tc;
        req_len_r               <= req_len;
        req_lookup_id_r         <= req_lookup_id;

        curr_slot               <= next_slot;

        if (req_compl_wd_r || req_compl_r || req_compl_ur_r) begin
            done                      <= 1'b0;
            req_tc_r_r                <= req_tc_r;
            req_len_r_r               <= req_len_r;
            req_lookup_id_r_r         <= req_lookup_id_r;
        end else begin
            done <= next_done;
        end
    end
end

always_comb begin
    data_ind = '0;
    next_cpl_tx = cpl_tx_r;
    next_cpl_tx.tx_valid = 1'b0;
    next_done = done;
    next_state = state_r;
    next_len_cnt = len_cnt_r;
    next_slot = curr_slot;

    case(state_r)
        IDLE : begin
            case ({req_compl_r_r, req_compl_ur_r_r, req_compl_wd_r_r, done})
                // Completion with data
                4'b0010 : begin
                    next_cpl_tx = '0;
                    next_cpl_tx.tx_data[0] = cpl_hdr;
                    next_cpl_tx.tx_data[1][31:0] = rd_data;
                    next_cpl_tx.tx_start = {1'b0, 1'b0, 1'b1};
                    next_cpl_tx.tx_starttype = {2'b00, 2'b00, 2'b10};

                    if (req_len_r_r == 1) begin
                        next_cpl_tx.tx_valid = 1'b1;
                        next_done = 1'b1;
                        // Set end pointer if we are done after this dw
                        next_cpl_tx.tx_end = {1'b0, 1'b0, 1'b1};
                        next_cpl_tx.tx_endptr = {6'b00_0000, 6'b00_0000, {2'b01, {req_len_r_r[1:0], 2'b00}}};
                    end else begin
                        next_state = CPL_DATA;
                        next_len_cnt = 1;
                        next_slot = 1;
                    end
                end

                // Completion
                4'b1000 : begin

                end

                // Completion UR
                4'b0100 : begin
                    next_cpl_tx = '0;
                    next_cpl_tx.tx_data[0] = cpl_hdr;
                    next_cpl_tx.tx_data[0].cpl.fmt = 2'b00;
                    next_cpl_tx.tx_data[0].cpl.status = 3'b001;
                    next_cpl_tx.tx_data[0].cpl.byte_len = '0;
                    next_cpl_tx.tx_data[0].cpl.byte_en = '0;
                    next_cpl_tx.tx_start = {1'b0, 1'b0, 1'b1};
                    next_cpl_tx.tx_starttype = {2'b00, 2'b00, 2'b10};
                    next_cpl_tx.tx_end = {1'b0, 1'b0, 1'b1};
                    next_cpl_tx.tx_valid = 1'b1;
                    next_state = CPL_UR;
                end

                default : begin end
            endcase
        end

        CPL_DATA : begin
            next_len_cnt = len_cnt_r + 1;
            data_ind = ((len_cnt_r % 16) << 5);

            next_cpl_tx.tx_data[curr_slot][data_ind +: 32] = rd_data;

            // Default tx signals if we are already in next cycle
            if (len_cnt_r >= 32) begin
                next_cpl_tx.tx_start = {1'b0, 1'b0, 1'b0};
                next_cpl_tx.tx_startptr = {2'b00, 2'b00, 2'b00};
                next_cpl_tx.tx_starttype = {2'b00, 2'b00, 2'b00};
                next_cpl_tx.tx_startnpinfo = {3'b000, 3'b000, 3'b000};
            end

            if (data_ind == 480) begin  // finished this slot
                next_slot = (curr_slot + 1) % NUM_SLOTS;
                if (curr_slot == (NUM_SLOTS-1)) begin // Done with cycle of tx
                    next_cpl_tx.tx_valid = 1'b1;
                end
            end

            if (next_len_cnt == req_len_r_r) begin // finished all data
                next_state = IDLE;
                next_done = 1'b1;
                next_cpl_tx.tx_valid = 1'b1;
                next_cpl_tx.tx_end = {1'b0, 1'b0, 1'b1};
                next_cpl_tx.tx_endptr = {6'b00_0000, 6'b00_0000, {curr_slot, {req_len_r_r[1:0], 2'b00}}};
            end
        end

        CPL_UR : begin
            next_state = IDLE;
            next_done = 1'b1;
        end

        default : next_state = IDLE;
    endcase
end

endmodule // BMD_AXIST_TX_CPL
