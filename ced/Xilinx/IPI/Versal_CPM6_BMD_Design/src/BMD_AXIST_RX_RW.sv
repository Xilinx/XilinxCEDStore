
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
// File       : BMD_AXIST_RX_RW.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_RX_RW.sv
//--
//-- Description: Handles incoming reads and writes from the RX MUX.
//--              Performs writes and reads on the EP MEM and will communicate
//--              relevant information to the TX CPL component to return
//--              completions for received reads.
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_RX_RW
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
  import bmd_mem_pkg::*;
  import bmd_cfg_pkg::*;
#(
    parameter logic             IF_CMP_PARITY_CHECK   = 1'b0
) (
    input  logic                        clk,
    input  logic                        rst_n,
    // From RX MUX
    input  logic                        mmio_valid,
    input  rx_fifo_intf                 mmio_slot,
    // To RX MUX
    output logic                        mmio_rd_en,

    // To TX CPL
    output logic                        req_compl,              // Send completion
    output logic                        req_compl_wd,           // Send completion w/ data
    output logic                        req_compl_ur,           // Send UR completion
    output logic [2:0]                  req_tc,                 // Request TC
    output logic [9:0]                  req_len,                // Request Length
    output logic [13:0]                 req_lookup_id,

    // To EP MEM
    output logic [10:0]                 addr,
    output logic [3:0]                  wr_be,
    output logic [3:0]                  rd_be,
    output logic [31:0]                 wr_data,
    output logic                        wr_en,
    input  logic                        wr_busy,

    output logic [31:0]                 debug
);

localparam logic [1:0]          RX_IDLE_STATE       = 2'b00;
localparam logic [1:0]          RX_DATA_STATE       = 2'b01;
localparam logic [1:0]          RX_NP_STATE         = 2'b10;
localparam logic [1:0]          RX_NP_DATA_STATE    = 2'b11;

localparam logic [5:0]          RX_MEM_RD_FMT_TYPE      = 6'b0_00000;  // Memory Read - NPR
localparam logic [5:0]          RX_MEM_WR_FMT_TYPE      = 6'b1_00000;  // Memory Write - PR
localparam logic [5:0]          RX_MEM_RD_LK_FMT_TYPE   = 6'b0_00001;  // Memory Read Locked - NPR
localparam logic [5:0]          RX_IO_RD_FMT_TYPE       = 6'b0_00010;  // IO Read - NPR
localparam logic [5:0]          RX_IO_WR_FMT_TYPE       = 6'b1_00010;  // IO Write - PR
localparam logic [5:0]          RX_DMWR_FMT_TYPE        = 6'b1_11011;  // DMWr - NPR
localparam logic [5:0]          RX_MSG_FMT_TYPE         = 6'b0_10???;  // Msg - NPR
localparam logic [5:0]          RX_MSGD_FMT_TYPE        = 6'b1_10???;  // MsgD - PR
localparam logic [5:0]          RX_FETCH_ADD_FMT_TYPE   = 6'b1_01100;  // FetchAdd - NPR
localparam logic [5:0]          RX_SWAP_FMT_TYPE        = 6'b1_01101;  // Swap - NPR
localparam logic [5:0]          RX_CAS_FMT_TYPE         = 6'b1_01110;  // CAS - NPR

// Register signals
logic [1:0]                     state_r, next_state;
logic [6:0]                     addr_r, next_addr;
logic [7:0]                     wr_be_r, next_wr_be;
logic [10:0]                    dw_len_r, next_dw_len;
logic [10:0]                    dw_len_r_m1;
logic [10:0]                    data_cnt_r, next_data_cnt;
logic [1:0]                     np_cnt_r, next_np_cnt;
logic [1:0]                     total_np_r, next_total_np;

logic [6:0]                     wr_addr_r;
logic [3:0]                     xwr_be_r;
logic [3:0]                     xrd_be_r;
logic [31:0]                    wr_data_r;
logic                           wr_en_r;

logic [6:0]                     _addr;
logic [3:0]                     _wr_be;
logic [3:0]                     _rd_be;
logic [31:0]                    _wr_data;
logic                           _wr_en;

logic                           i_mmio_rd_en;
logic                           i_mmio_valid;
rx_fifo_intf                    i_mmio_slot;

assign debug = {
    wr_busy,
    wr_en,
    rd_be,
    wr_be,
    addr,
    mmio_slot.pnp_info,
    mmio_rd_en,
    np_cnt_r,
    mmio_slot.ptype,
    mmio_valid,
    state_r
};

always @(posedge clk) begin
    if(!rst_n) begin
        state_r     <= RX_IDLE_STATE;
        addr_r      <= '0;
        wr_be_r     <= '0;
        dw_len_r    <= '0;
        data_cnt_r  <= '0;
        wr_addr_r   <= '0;
        xwr_be_r    <= '0;
        xrd_be_r    <= '0;
        wr_data_r   <= '0;
        wr_en_r     <= '0;
        np_cnt_r    <= '0;
        total_np_r  <= '0;
    end else begin
        state_r     <= next_state;
        addr_r      <= next_addr;
        wr_be_r     <= next_wr_be;
        dw_len_r    <= next_dw_len;
        dw_len_r_m1 <= next_dw_len - 1;
        data_cnt_r  <= next_data_cnt;
        np_cnt_r    <= next_np_cnt;
        total_np_r  <= next_total_np;
        wr_addr_r   <= _addr;    // used to preserve value for multicycle writes
        xwr_be_r    <= _wr_be;   // used to preserve value for multicycle writes
        xrd_be_r    <= _rd_be;   // used to preserve value for multicycle writes
        wr_data_r   <= _wr_data; // used to preserve value for multicycle writes
        wr_en_r     <= _wr_en;   // used to preserve value for multicycle writes
    end
end

assign addr = wr_addr_r;
assign wr_be = xwr_be_r;
assign rd_be = xrd_be_r;
assign wr_data = wr_data_r;
assign wr_en = wr_en_r;

always_comb begin
    // Defaults
    i_mmio_rd_en        = 1'b0;

    req_compl           = '0;
    req_compl_wd        = '0;
    req_compl_ur        = '0;
    req_tc              = '0;
    req_len             = '0;
    req_lookup_id       = '0;

    _addr                = wr_addr_r;
    _wr_be               = xwr_be_r;
    _rd_be               = xrd_be_r;
    _wr_data             = wr_data_r;
    _wr_en               = wr_en_r;

    next_state          = state_r;
    next_addr           = addr_r;
    next_wr_be          = wr_be_r;
    next_dw_len         = dw_len_r;
    next_data_cnt       = data_cnt_r;
    next_np_cnt         = np_cnt_r;
    next_total_np       = total_np_r;

    case (state_r)

        RX_IDLE_STATE : begin
            if (i_mmio_valid) begin
                case(i_mmio_slot.ptype)
                    2'b00 : begin   // Posted
                        case({i_mmio_slot.pdata.p.fmt[1], i_mmio_slot.pdata.p.ttype, i_mmio_slot.pdata.p.tlp_abort,
                                i_mmio_slot.pdata.p.in_membar_range, i_mmio_slot.pdata.p.func_num}) // fmt, ttype
                            {RX_MEM_WR_FMT_TYPE, 1'b0, BAR_NUM, FUNC_NUM} : begin
                                i_mmio_rd_en = 1'b1; // Pop FIFO
                                next_addr = i_mmio_slot.pdata.p.addr[6:0];
                                next_wr_be = {i_mmio_slot.pdata.p.last_be, i_mmio_slot.pdata.p.first_be};
                                next_dw_len = {1'b0, i_mmio_slot.pdata.p.dw_len};
                                next_data_cnt = '0; // Used to track current dw

                                if (i_mmio_slot.pdata.p.addr[$clog2(BAR_SIZE)-1:2] > MAX_CSR) next_state = RX_IDLE_STATE;
                                else next_state = RX_DATA_STATE;
                            end

                            default : begin
                                i_mmio_rd_en = 1'b1; // Pop FIFO
                            end
                        endcase
                    end

                    2'b01 : begin   // NonPosted
                        case({i_mmio_slot.pdata.np[0].fmt[1], i_mmio_slot.pdata.np[0].ttype, i_mmio_slot.pdata.np[0].tlp_abort,
                                    i_mmio_slot.pdata.np[0].in_membar_range, i_mmio_slot.pdata.np[0].func_num}) // fmt, ttype
                            {RX_MEM_RD_FMT_TYPE, 1'b0, BAR_NUM, FUNC_NUM} : begin

                                next_np_cnt = '0;
                                case (i_mmio_slot.pnp_info)
                                    3'b111, 3'b101, 3'b110, 3'b100 :
                                        next_total_np = 3;
                                    3'b010, 3'b011 :
                                        next_total_np = 2;
                                    3'b001 :
                                        next_total_np = 1;
                                    default :
                                        next_total_np = 1; // Error
                                endcase

                                // Mem signals
                                _addr = i_mmio_slot.pdata.np[0].addr[6:0];
                                _rd_be = i_mmio_slot.pdata.np[0].first_be;
                                _wr_en = 1'b0;

                                // Cpl signals
                                if (i_mmio_slot.pdata.np[0].addr[$clog2(BAR_SIZE)-1:2] <= MAX_CSR) begin
                                    req_compl_wd = 1'b1;
                                end else begin
                                    req_compl_ur = 1'b1;
                                end
                                req_tc = i_mmio_slot.pdata.np[0].tc;
                                req_len = i_mmio_slot.pdata.np[0].dw_len;
                                req_lookup_id = i_mmio_slot.pdata.np[0].lookup_id;

                                if (i_mmio_slot.pdata.np[0].dw_len == 1) begin
                                    if (next_total_np[1] == 0) begin // only 0 or 1 then we finish
                                        next_state = RX_IDLE_STATE;
                                        i_mmio_rd_en = 1'b1; // Pop FIFO
                                    end else begin
                                        next_state = RX_NP_STATE;
                                        next_np_cnt = 1;
                                    end
                                end else begin
                                    next_state = RX_NP_DATA_STATE;
                                    next_addr = {1'b0, i_mmio_slot.pdata.np[0].addr[6:0]} + 12'(4);
                                    next_data_cnt = 1;
                                end
                            end

                            default : begin // Discard
                                i_mmio_rd_en = 1'b1;
                            end
                        endcase
                    end

                    default : begin
                        // Invalid
                        i_mmio_rd_en = 1'b1;
                    end
                endcase
            end
        end

        RX_NP_STATE : begin // Handles sub-slot NPs (just reads for now)
            if (i_mmio_valid) begin
                // Mem signals
                _addr = i_mmio_slot.pdata.np[np_cnt_r].addr[6:0];
                _rd_be = i_mmio_slot.pdata.np[np_cnt_r].first_be;
                _wr_en = 1'b0;

                req_tc = i_mmio_slot.pdata.np[np_cnt_r].tc;
                req_len = i_mmio_slot.pdata.np[np_cnt_r].dw_len;
                req_lookup_id = i_mmio_slot.pdata.np[np_cnt_r].lookup_id;

                // Cpl signals
                if (i_mmio_slot.pdata.np[np_cnt_r].addr[6:2] <= MAX_CSR) begin
                    req_compl_wd = 1'b1;
                end else begin
                    req_compl_ur = 1'b1;
                end

                if (i_mmio_slot.pdata.np[np_cnt_r].dw_len == 1 && np_cnt_r + 1 == total_np_r) begin
                    next_state = RX_IDLE_STATE;
                    i_mmio_rd_en = 1'b1; // Pop FIFO
                end else begin
                    next_state = RX_NP_DATA_STATE;
                    next_addr = i_mmio_slot.pdata.np[np_cnt_r].addr[6:0] + 4;
                    next_data_cnt = 1;
                end
            end
        end

        RX_NP_DATA_STATE : begin
            next_data_cnt = data_cnt_r + 1;

            // Mem signals
            _addr = addr_r;
            _rd_be = '1;
            _wr_en = 1'b0;

            if (i_mmio_slot.pdata.np[np_cnt_r].dw_len == next_data_cnt) begin
                _rd_be = i_mmio_slot.pdata.np[np_cnt_r].last_be;
                next_np_cnt = np_cnt_r + 1;
                if (next_np_cnt == total_np_r) begin
                    next_state = RX_IDLE_STATE;
                    i_mmio_rd_en = 1'b1; // Pop FIFO
                end else begin
                    next_state = RX_NP_STATE;
                end
            end else begin
                next_state = RX_NP_DATA_STATE;
                next_addr = addr_r + 4;
            end
        end

        RX_DATA_STATE : begin // Handles data portion of writes
            if (!wr_busy) begin
                if (i_mmio_valid) begin
                    _addr = addr_r;
                    _wr_data = i_mmio_slot.pdata.data[{data_cnt_r[3:0], 5'b00000} +: 32];
                    _wr_en = 1'b1;

                    // Increment values for next cycle
                    next_data_cnt = data_cnt_r + 1;
                    next_addr = addr_r + 4;

                    // Edge conditions
                    if (data_cnt_r == 0)
                        _wr_be = wr_be_r[3:0];
                    else if (data_cnt_r == dw_len_r_m1) begin
                        _wr_be = wr_be_r[7:4];
                    end

                    if (data_cnt_r == dw_len_r_m1 || addr_r[6:2] > MAX_CSR) begin // done with data
                        next_state = RX_IDLE_STATE;
                        i_mmio_rd_en = 1'b1;
                    end else if (next_data_cnt[3:0] == 4'h0) // Inc packet
                        i_mmio_rd_en = 1'b1;
                end
            end
        end

        default : begin
            next_state = RX_IDLE_STATE;
        end

    endcase
end

logic mmio_rd_en_n;

// Buffering from FIFO
BMD_BACKPRESSURE_ARB #(
    .ARB_SLOTS(1),
    .ARB_WIDTH(ENCODING_WIDTH_RX)
) BMD_RX_RW_BACKPRESSURE (
    .clk                ( clk ),
    .rst_n              ( rst_n ),

    .dout_o             ( i_mmio_slot ),
    .valid_o            ( i_mmio_valid ),
    .rd_en_i            ( i_mmio_rd_en ),

    .valid_i            ( mmio_valid ),
    .slots_i            ( mmio_slot ),

    .halt_o             ( mmio_rd_en_n )
);

assign mmio_rd_en = !mmio_rd_en_n;

endmodule // BMD_AXIST_RX_RW
