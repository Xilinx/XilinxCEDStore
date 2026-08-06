
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
// File       : BMD_AXIST_TPH_CFG.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_TPH_CFG.sv
//--
//-- Description: Handles the extended configuration space requests that arrive
//--              over the ELBI interface for TPH configuration space.
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_TPH_CFG
  import pcie_intf_pkg::*;
#(
    // Offset of extended capability - first offset
    parameter logic [11:0]          EXT_CONFIG_BASE_ADDRESS = 12'hD00,
    // Terminate capability chain (h000) or address of next capability
    parameter logic [11:0]          EXT_CONFIG_NEXT_CAP     = 12'h000,

    // Capability Register
        // Indicates maximum number of ST Table entries - encoded as N-1
        // Max 64 entries when table is located in TPH Capability Structure
    parameter logic [10:0]          ST_TABLE_SIZE           = 11'h000,
        // Indicates where (and if) the ST table is located.
        // 00 - Not Present
        // 01 - In TPH Capability Structure
        // 10 - In MSI-X Table
        // 11 - Reserved
    parameter logic [1:0]           ST_TABLE_LOC            = 2'b00,
        // Indicates function is capable of generating requests with TPH Prefix.
    parameter logic                 EXT_TPH_REQ_SUP         = 1'b1,
        // Indicates Device Specific Mode of operation is supported.
    parameter logic                 DEV_SPEC_MODE_SUP       = 1'b1,
        // Indicates Interrupt Vector Mode is supported.
    parameter logic                 INT_VEC_MODE_SUP        = 1'b1,
        // Indicates No ST Mode is supported. Must be set to 1
    parameter logic                 NO_ST_MODE_SUP          = 1'b1
) (
    input  logic                    clk,
    input  logic                    rst_n,

    // Write address channel
    input  logic                    s_axi_awvalid,
    output logic                    s_axi_awready,
    input  logic [63:0]             s_axi_awaddr,
    input  logic [2:0]              s_axi_awprot,
    input  logic [7:0]              s_axi_awuser,

    // Write data channel
    input  logic                    s_axi_wvalid,
    output logic                    s_axi_wready,
    input  logic [63:0]             s_axi_wdata,
    input  logic [7:0]              s_axi_wstrb,
    input  logic [7:0]              s_axi_wuser,

    // Write response channel
    output logic                    s_axi_bvalid,
    input  logic                    s_axi_bready,
    output logic [1:0]              s_axi_bresp,
    output logic [7:0]              s_axi_buser,

    // Read address channel
    input  logic                    s_axi_arvalid,
    output logic                    s_axi_arready,
    input  logic [63:0]             s_axi_araddr,
    input  logic [2:0]              s_axi_arprot,
    input  logic [7:0]              s_axi_aruser,

    // Read data channel
    output logic                    s_axi_rvalid,
    input  logic                    s_axi_rready,
    output logic [63:0]             s_axi_rdata,
    output logic [1:0]              s_axi_rresp,
    output logic [7:0]              s_axi_ruser
);

// Register map for this PCIe extended capability
// PCIe extended capability addresses are given as the word offset from th
// EXT_CONFIG_BASE_ADDRESS (not byte offset)
//                  < Register Name >     < Register Offset >
localparam [9:0]    TPH_REQ_EXT_CAP_ADDR    = EXT_CONFIG_BASE_ADDRESS[11:2] + 0;
localparam [9:0]    TPH_REQ_CAP_REG_ADDR    = EXT_CONFIG_BASE_ADDRESS[11:2] + 1;
localparam [9:0]    TPH_REQ_CTRL_REG_ADDR   = EXT_CONFIG_BASE_ADDRESS[11:2] + 2;
localparam [9:0]    TPH_ST_TABLE_ADDR       = EXT_CONFIG_BASE_ADDRESS[11:2] + 3;


localparam [15:0]   TPH_CAP_ID              = 16'h0017;
localparam [3:0]    TPH_CAP_VER             = 4'h1;

// This header field and values are defined from the PCIe specification for TPH
logic [31:0]    tph_ext_cap_header      = {EXT_CONFIG_NEXT_CAP, TPH_CAP_VER, TPH_CAP_ID};
logic [31:0]    tph_cap_reg             = {5'h0, ST_TABLE_SIZE, 5'h0, ST_TABLE_LOC, EXT_TPH_REQ_SUP, 5'h0, DEV_SPEC_MODE_SUP, INT_VEC_MODE_SUP, NO_ST_MODE_SUP};
logic [31:0]    tph_ctrl_reg;
logic [((ST_TABLE_SIZE + 1) >> 1)-1:0][31:0] tph_st_table;


logic           read_en, write_en;

logic           write_valid;
logic [3:0]     write_byte_enable;
logic [31:0]    write_data;
logic [9:0]     register_number_write;

logic [63:0]    read_data;
logic           read_valid;
logic [9:0]     register_number_read;

logic [11:0]    awaddr_r, next_awaddr;
logic [63:0]    wdata_r, next_wdata;
logic [7:0]     wstrb_r, next_wstrb;


// Register read logic and output registers
always @ (posedge clk) begin
    if (read_en) begin
        case (register_number_read)
            TPH_REQ_EXT_CAP_ADDR: begin
                read_data <= {32'd0, tph_ext_cap_header};
                read_valid <= 1'b1;
            end

            TPH_REQ_CAP_REG_ADDR: begin
                read_data <= {tph_cap_reg, 32'd0};
                read_valid <= 1'b1;
            end

            TPH_REQ_CTRL_REG_ADDR: begin
                read_data <= {32'd0, tph_ctrl_reg};
                read_valid <= 1'b1;
            end

            default: begin
                if (register_number_read <= TPH_ST_TABLE_ADDR + ((ST_TABLE_SIZE + 1) >> 1) &&
                    register_number_read >  TPH_REQ_CTRL_REG_ADDR) begin
                        if (register_number_read[0]) begin
                            read_data <= {tph_st_table[register_number_read - TPH_ST_TABLE_ADDR], 32'd0};
                        end else begin
                            read_data <= {32'd0, tph_st_table[register_number_read - TPH_ST_TABLE_ADDR]};
                        end
                        read_valid <= 1'b1;
                end else begin
                    read_data <= 64'h0000_0000;
                    read_valid <= 1'b0;
                end
            end
        endcase
    end else begin
        read_data <= read_data;
        read_valid <= read_valid;
    end
end

// Register write logic and output registers
always @ (posedge clk) begin
    if (!rst_n) begin
        tph_ctrl_reg <= '0;
        tph_st_table <= '0;
    end else if (write_en) begin
        case (register_number_write)
            // TPH_REQ_EXT_CAP_ADDR is not writable
            TPH_REQ_EXT_CAP_ADDR  : write_valid <= 1'b1;
            // TPH_REQ_CAP_REG_ADDR is not writable
            TPH_REQ_CAP_REG_ADDR  : write_valid <= 1'b1;

            TPH_REQ_CTRL_REG_ADDR : begin
                write_valid <= 1'b1;
                if (write_byte_enable[0]) begin
                    case (write_data[2:0])
                        3'b000  : tph_ctrl_reg[2:0] <= '0;
                        3'b001  : tph_ctrl_reg[2:0] <= INT_VEC_MODE_SUP ? write_data[2:0] : tph_ctrl_reg[2:0];
                        3'b010  : tph_ctrl_reg[2:0] <= DEV_SPEC_MODE_SUP ? write_data[2:0] : tph_ctrl_reg[2:0];
                        default : tph_ctrl_reg[2:0] <= tph_ctrl_reg[2:0];
                    endcase
                end

                if (write_byte_enable[1]) begin
                    case (write_data[9:8])
                        2'b00   : tph_ctrl_reg[9:8] <= '0;
                        2'b01   : tph_ctrl_reg[9:8] <= write_data[9:8];
                        2'b11   : tph_ctrl_reg[9:8] <= EXT_TPH_REQ_SUP ? write_data[9:8] : tph_ctrl_reg[9:8];
                        default : tph_ctrl_reg[9:8] <= tph_ctrl_reg[9:8];
                    endcase
                end
                tph_ctrl_reg[7:3]   <= '0;
                tph_ctrl_reg[31:10] <= '0;
            end

            default: begin
                if (register_number_write <= TPH_ST_TABLE_ADDR + ((ST_TABLE_SIZE + 1) >> 1) &&
                    register_number_write >  TPH_REQ_CTRL_REG_ADDR) begin
                        write_valid <= 1'b1;
                        tph_st_table[register_number_write - TPH_ST_TABLE_ADDR][7:0]   <= write_byte_enable[0] ?
                                                                                            write_data[7:0]   :
                                                                                            tph_st_table[register_number_write - TPH_ST_TABLE_ADDR][7:0];
                        tph_st_table[register_number_write - TPH_ST_TABLE_ADDR][15:8]  <= write_byte_enable[1] ?
                                                                                            write_data[15:8]  :
                                                                                            tph_st_table[register_number_write - TPH_ST_TABLE_ADDR][15:8];
                        tph_st_table[register_number_write - TPH_ST_TABLE_ADDR][23:16] <= write_byte_enable[2] ?
                                                                                            write_data[23:16] :
                                                                                            tph_st_table[register_number_write - TPH_ST_TABLE_ADDR][23:16];
                        tph_st_table[register_number_write - TPH_ST_TABLE_ADDR][31:24] <= write_byte_enable[3] ?
                                                                                            write_data[31:24] :
                                                                                            tph_st_table[register_number_write - TPH_ST_TABLE_ADDR][31:24];
                end else begin
                    write_valid  <= 1'b0;
                    tph_ctrl_reg <= tph_ctrl_reg;
                    tph_st_table <= tph_st_table;
                end
            end
        endcase
    end else begin
        tph_ctrl_reg <= tph_ctrl_reg;
        tph_st_table <= tph_st_table;
        write_valid  <= write_valid;
    end
end

// AXI-Lite interfacing logic
//////////////////////////////////////////////////////////////////////////////////
// Reads
typedef enum logic [1:0] {
    WAIT_FOR_ARVALID,
    WAIT_FOR_RREADY
} read_state_t;

read_state_t        read_state, next_read_state;

always @(posedge clk) begin
    if (!rst_n) begin
        read_state  <= WAIT_FOR_ARVALID;
    end else begin
        read_state  <= next_read_state;
    end
end
always_comb begin
    s_axi_arready = 1'b1;
    next_read_state = read_state;

    s_axi_rvalid = '0;
    s_axi_rdata = '0;
    s_axi_rresp = '0;
    s_axi_ruser = '0;

    read_en = '0;
    register_number_read = '0;

    case(read_state)
        WAIT_FOR_ARVALID : begin
            if (s_axi_arvalid && (s_axi_araddr[45:43] == 3'b111)) begin
                read_en = 1'b1;
                register_number_read = s_axi_araddr[11:2];
                next_read_state = WAIT_FOR_RREADY;
            end
        end

        WAIT_FOR_RREADY : begin
            s_axi_arready = 1'b0;
            if (!read_valid) begin // Read not for us
                next_read_state = WAIT_FOR_ARVALID;
            end else begin // Read for us, return data
                s_axi_rvalid = 1'b1;
                s_axi_rdata = read_data;
                if (s_axi_rready) begin
                    next_read_state = WAIT_FOR_ARVALID;
                end
            end
        end

        default : next_read_state = WAIT_FOR_ARVALID;
    endcase
end

//////////////////////////////////////////////////////////////////////////////////
// Writes
typedef enum logic [1:0] {
    WAIT_FOR_A_W_VALID,
    WAIT_FOR_WVALID,
    WAIT_FOR_AWVALID,
    WAIT_FOR_BREADY
} write_state_t;

write_state_t       write_state, next_write_state;

always @(posedge clk) begin
    if (!rst_n) begin
        write_state <= WAIT_FOR_A_W_VALID;

        awaddr_r    <= '0;
        wdata_r     <= '0;
        wstrb_r     <= '0;
    end else begin
        write_state <= next_write_state;

        awaddr_r    <= next_awaddr;
        wdata_r     <= next_wdata;
        wstrb_r     <= next_wstrb;
    end
end

always_comb begin
    s_axi_awready    = 1'b1;
    s_axi_wready     = 1'b1;

    next_write_state = write_state;

    s_axi_bvalid = '0;
    s_axi_bresp  = '0;
    s_axi_buser  = '0;

    write_en              = '0;
    write_data            = '0;
    write_byte_enable     = '0;
    register_number_write = '0;

    next_awaddr = awaddr_r;
    next_wdata  = wdata_r;
    next_wstrb  = wstrb_r;

    case(write_state)
        WAIT_FOR_A_W_VALID: begin
            if ((s_axi_awvalid && (s_axi_awaddr[45:43] == 3'b111)) && s_axi_wvalid) begin // Both valids
                next_write_state = WAIT_FOR_BREADY;

                register_number_write = s_axi_awaddr[11:2];
                write_data            = s_axi_awaddr[2] ? s_axi_wdata[63:32] : s_axi_wdata[31:0];
                write_byte_enable     = s_axi_awaddr[2] ? s_axi_wstrb[7:4]   : s_axi_wstrb[3:0];
                write_en              = 1'b1;
            end else if ((s_axi_awvalid && (s_axi_awaddr[45:43] == 3'b111))) begin // Only awvalid, wait for wvalid
                next_write_state = WAIT_FOR_WVALID;

                next_awaddr = s_axi_awaddr[11:0];
            end else if (s_axi_wvalid && !s_axi_awvalid) begin // Only wvalid, wait for awvalid
                next_write_state = WAIT_FOR_AWVALID;

                next_wdata = s_axi_wdata[63:0];
                next_wstrb = s_axi_wstrb[7:0];
            end
        end

        WAIT_FOR_WVALID : begin
            s_axi_awready    = 1'b0;

            if (s_axi_wvalid) begin
                next_write_state = WAIT_FOR_BREADY;

                register_number_write = awaddr_r[11:2];
                write_data            = awaddr_r[2] ? s_axi_wdata[63:32] : s_axi_wdata[31:0];
                write_byte_enable     = awaddr_r[2] ? s_axi_wstrb[7:4]   : s_axi_wstrb[3:0];
                write_en              = 1'b1;
            end
        end

        WAIT_FOR_AWVALID : begin
            s_axi_wready     = 1'b0;

            if ((s_axi_awvalid && (s_axi_awaddr[45:43] == 3'b111))) begin
                next_write_state = WAIT_FOR_BREADY;

                register_number_write = s_axi_awaddr[11:2];
                write_data            = s_axi_awaddr[2] ? wdata_r[63:32] : wdata_r[31:0];
                write_byte_enable     = s_axi_awaddr[2] ? wstrb_r[7:4]   : wstrb_r[3:0];
                write_en              = 1'b1;
            end else if (s_axi_awvalid) begin
                next_write_state = WAIT_FOR_A_W_VALID;
            end
        end

        WAIT_FOR_BREADY : begin
            s_axi_awready = 1'b0;
            s_axi_wready  = 1'b0;

            if (write_valid) begin // write for us
                s_axi_bvalid  = 1'b1;
                if (s_axi_bready) begin
                    next_write_state = WAIT_FOR_A_W_VALID;
                end
            end else begin // write not for us
                next_write_state = WAIT_FOR_A_W_VALID;
            end
        end

        default : next_write_state = WAIT_FOR_A_W_VALID;
    endcase
end

endmodule // BMD_AXIST_EXT_CFG
