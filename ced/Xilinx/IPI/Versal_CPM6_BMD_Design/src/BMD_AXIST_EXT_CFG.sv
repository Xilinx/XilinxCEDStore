
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
// File       : BMD_AXIST_EXT_CFG.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_EXT_CFG.sv
//--
//-- Description: Handles the extended configuration space requests that arrive
//--              over the ELBI interface with example VSEC space.
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_EXT_CFG
  import pcie_intf_pkg::*;
#(
    // Offset of extended capability - first offset should be hD00
    parameter logic [11:0]          EXT_CONFIG_BASE_ADDRESS = 12'hD00,
    // Byte-length of the PCIe extended capability (including header regs)
    parameter logic [11:0]          EXT_CONFIG_CAP_LENGTH   = 12'h010,
    // Terminate capability chain (h000) or address of next capability
    parameter logic [11:0]          EXT_CONFIG_NEXT_CAP     = 12'h000,
    // Defined by the vendor
    parameter logic [15:0]          PCIE_VSEC_ID            = 16'hBEEF,
    parameter logic [3:0]           PCIE_VSEC_REV           = 4'h0
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
    output logic [7:0]              s_axi_ruser,

    // IO to/from user design
    input  logic [31:0]             status_reg_in,
    output logic [31:0]             control_reg_out
);

// Register map for this PCIe extended capability
// PCIe extended capability addresses are given as the word offset from th
// EXT_CONFIG_BASE_ADDRESS (not byte offset)
//                  < Register Name >     < Register Offset >
localparam [9:0]    PCIE_EXT_CAP_ADDR   = EXT_CONFIG_BASE_ADDRESS[11:2] + 0;  // 0x00
localparam [9:0]    PCIE_VSEC_ADDR      = EXT_CONFIG_BASE_ADDRESS[11:2] + 1;  // 0x04
localparam [9:0]    VSEC_STATUS_ADDR    = EXT_CONFIG_BASE_ADDRESS[11:2] + 2;  // 0x08
localparam [9:0]    VSEC_CONTROL_ADDR   = EXT_CONFIG_BASE_ADDRESS[11:2] + 3;  // 0x0C

// Fields for the PCIE_EXT_CAP_ADDR register. A PCIe VSEC is specified with an
// PCIE_EXP_CAP_ID=16'h000B and PCIE_EXT_CAP_VER=4'h0 as per the PCIe specification
localparam [15:0]   PCIE_EXP_CAP_ID     = 16'h000B;
localparam [3:0]    PCIE_EXT_CAP_VER    = 4'h0;

// This header field and values are defined from the PCIe specification for a VSEC
logic [31:0]    pcie_ext_cap_header     = {EXT_CONFIG_NEXT_CAP, PCIE_EXT_CAP_VER, PCIE_EXP_CAP_ID};
// This header field is defined by the PCIe specification, but values are defined by vendor
logic [31:0]    pcie_vsec_header        = {EXT_CONFIG_CAP_LENGTH, PCIE_VSEC_REV, PCIE_VSEC_ID};
// This register will be read-only and can be used to report system status
// For this example, the register reports the value present in the control register
logic [31:0]    pcie_status_reg         = 32'h0000_0000;
// This register is read-write and can be used for controlling the system or status
logic [31:0]    pcie_control_reg        = 32'h0403_0201;

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

assign control_reg_out = pcie_control_reg;
// register data on the status register input
always @(posedge clk) begin
    pcie_status_reg <= status_reg_in;
end

// Register read logic and output registers
always @ (posedge clk) begin
    if (read_en) begin
        case (register_number_read)
            PCIE_EXT_CAP_ADDR: begin
                read_data <= {32'd0, pcie_ext_cap_header};
                read_valid <= 1'b1;
            end

            PCIE_VSEC_ADDR: begin
                read_data <= {pcie_vsec_header, 32'd0};
                read_valid <= 1'b1;
            end

            VSEC_STATUS_ADDR: begin
                read_data <= {32'd0, pcie_status_reg};
                read_valid <= 1'b1;
            end

            VSEC_CONTROL_ADDR: begin
                read_data <= {pcie_control_reg, 32'd0};
                read_valid <= 1'b1;
            end

            default: begin
                read_data <= 64'h0000_0000;
                read_valid <= 1'b0;
            end
        endcase
    end else begin
        read_data <= read_data;
        read_valid <= read_valid;
    end
    end

// Register write logic and output registers
always @ (posedge clk) begin
    if (write_en) begin
        case (register_number_write)
        // PCIE_EXT_CAP_ADDR is not writable
        PCIE_EXT_CAP_ADDR : write_valid <= 1'b1;
        // PCIE_VSEC_ADDR is not writable
        PCIE_VSEC_ADDR    : write_valid <= 1'b1;
        // VSEC_STATUS_ADDR is not writable
        VSEC_STATUS_ADDR  : write_valid <= 1'b1;

        VSEC_CONTROL_ADDR : begin
            pcie_control_reg[7:0]   <= write_byte_enable[0] ? write_data[7:0]   : pcie_control_reg[7:0];
            pcie_control_reg[15:8]  <= write_byte_enable[1] ? write_data[15:8]  : pcie_control_reg[15:8];
            pcie_control_reg[23:16] <= write_byte_enable[2] ? write_data[23:16] : pcie_control_reg[23:16];
            pcie_control_reg[31:24] <= write_byte_enable[3] ? write_data[31:24] : pcie_control_reg[31:24];
            write_valid <= 1'b1;
        end

        default : begin
            pcie_control_reg <= pcie_control_reg;
            write_valid <= 1'b0;
        end
        endcase
    end else begin
        pcie_control_reg <= pcie_control_reg;
        write_valid <= write_valid;
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
