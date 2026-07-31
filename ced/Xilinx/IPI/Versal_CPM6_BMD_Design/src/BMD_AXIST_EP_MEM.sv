//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : Everest FPGA PCI Express Integrated Block
// File       : BMD_AXIST_EP_MEM.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_EP_MEM.sv
//--
//-- Description: Endpoint control and status registers
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_EP_MEM
  import pcie_intf_pkg::*;
  import bmd_mem_pkg::*;
(
    input  logic         clk,
    input  logic         rst_n,

    // PIO Signals
    input  logic [6:0]   a_i,
    input  logic         wr_en_i,
    output logic [31:0]  rd_d_o,
    input  logic [31:0]  wr_d_i,

    // DCSR1
    output logic         init_rst_o,

    // DCSR2
    input  logic         cpld_data_err_i,
    input  logic         mrd_done_i,
    output logic         mrd_int_dis_o,
    output logic         mrd_nosnoop_o,
    output logic         mrd_relaxed_order_o,
    output logic         mrd_start_o,
    input  logic         mwr_done_i,
    output logic         mwr_int_dis_o,
    output logic         mwr_nosnoop_o,
    output logic         mwr_relaxed_order_o,
    output logic         mwr_start_o,
    input  logic [2:0]   cfg_max_payload_size,
    input  logic [2:0]   cfg_max_rd_req_size,

    output logic [1:0]   mwr_int_select_o,
    output logic [1:0]   mrd_int_select_o,

    // WDMATLPA
    output logic         mwr_inc_o,
    output logic [9:0]   mwr_tid_o,
    output logic [31:0]  mwr_addr_o,

    // WDMATLPS
    output logic [7:0]   mwr_steering_tag_o,
    output logic         mwr_tph_en_o,
    output logic [1:0]   mwr_phint_o,
    output logic         mwr_td_o,
    output logic         mwr_64b_en_o,
    output logic [2:0]   mwr_tlp_tc_o,
    output logic         mwr_poisoned_o,
    output logic [1:0]   mwr_ats_o,
    output logic         mwr_nw_o,
    output logic         mwr_tbit_o,
    output logic [10:0]  mwr_len_o,

    // WDMATLPUA
    output logic [31:0]  mwr_up_addr_o,

    // WDMATLPC
    output logic [15:0]  mwr_count_o,

    // WDMATLPP
    output logic [31:0]  mwr_data_o,

    // RDMATLPP
    output logic [31:0]  cpld_data_o,

    // RDMATLPA
    output logic         mrd_inc_o,
    output logic [31:0]  mrd_addr_o,

    // RDMATLPS
    output logic [7:0]   mrd_steering_tag_o,
    output logic         mrd_tph_en_o,
    output logic [1:0]   mrd_phint_o,
    output logic         mrd_td_o,
    output logic         mrd_64b_en_o,
    output logic [2:0]   mrd_tlp_tc_o,
    output logic         mrd_poisoned_o,
    output logic [1:0]   mrd_ats_o,
    output logic         mrd_nw_o,
    output logic         mrd_tbit_o,
    output logic [10:0]  mrd_len_o,

    // RDMATLPUA
    output logic [31:0]  mrd_up_addr_o,

    // RDMATLPC
    output logic [15:0]  mrd_count_o,

    // DMATLPTYPE
    output logic [4:0]   mrd_type_o,
    output logic         mrd_fmt_o,
    output logic [4:0]   mwr_type_o,
    output logic         mwr_fmt_o,

    // DMATLPEC
    output logic [11:0]  mwr_tph_o,
    output logic         mwr_tph_vld_o,
    output logic         mrd_tph_vld_o,
    output logic [11:0]  mrd_tph_o,

    // WDMAIDE
    output logic         mwr_ide_vld_o,
    output logic [23:0]  mwr_ide_o,

    // RDMAIDE
    output logic [23:0]  mrd_ide_o,
    output logic         mrd_ide_vld_o,

    // WDMAPASID
    output logic [23:0]  mwr_pasid_o,
    output logic         mwr_pasid_vld_o,

    // RDMAPASID
    output logic [23:0]  mrd_pasid_o,
    output logic         mrd_pasid_vld_o,

    // DMAEXT
    output logic [3:0]   mrd_upper_be_o,
    output logic [3:0]   mrd_lower_be_o,
    output logic [3:0]   mwr_upper_be_o,
    output logic [3:0]   mwr_lower_be_o,

    // DMAEXT2
    output logic [15:0]  mrd_rrid_o,
    output logic [15:0]  mwr_rrid_o,

    // RDMASTAT1
    input  logic [15:0]  cpl_ur_found_i,
    input  logic [9:0]   cpl_ur_tag_i,

    // RDMASTAT2
    input  logic [31:0]  cpld_found_i,

    // RDMASTAT3
    input  logic [31:0]  cpld_data_size_i,

    // DMAMSIX
    output logic [10:0]  mwr_msix_vec_o,
    output logic [10:0]  mrd_msix_vec_o,
    output logic [1:0]   mwr_intx_vec_o,
    output logic [1:0]   mrd_intx_vec_o,

    input  logic         cfg_atomic_req_en,
    input  logic         cfg_pf_pasid_en
);

// Performance tracking
reg [31:0]      mrd_perf;
reg [31:0]      mwr_perf;

// Device information
wire [7:0]      version_number;

assign version_number = 8'h04;

always @(posedge clk ) begin
    if ( !rst_n ) begin
        init_rst_o              <= 1'b1;

        // DDMACR
        mrd_int_dis_o           <= '0;
        mrd_nosnoop_o           <= '0;
        mrd_relaxed_order_o     <= '0;
        mrd_start_o             <= '0;
        mwr_int_dis_o           <= '0;
        mwr_nosnoop_o           <= '0;
        mwr_relaxed_order_o     <= '0;
        mwr_start_o             <= '0;
        mwr_int_select_o        <= '0;
        mrd_int_select_o        <= '0;
        // WDMATLPA
        mwr_addr_o              <= '0;
        // WDMATLPS
        mwr_steering_tag_o      <= '0;
        mwr_tph_en_o            <= '0;
        mwr_phint_o             <= '0;
        mwr_td_o                <= '0;
        mwr_64b_en_o            <= '0;
        mwr_tlp_tc_o            <= '0;
        mwr_poisoned_o          <= '0;
        mwr_ats_o               <= '0;
        mwr_nw_o                <= '0;
        mwr_tbit_o              <= '0;
        mwr_len_o               <= 'd1;
        // WDMATLPUA
        mwr_up_addr_o           <= '0;
        // WDMATLPC
        mwr_count_o             <= 'd1;
        mwr_tid_o               <= '0;
        mwr_inc_o               <= 1'b0;
        // WDMATLPP
        mwr_data_o              <= '0;
        // RDMATLPP
        cpld_data_o             <= '0;
        // RDMATLPA
        mrd_addr_o              <= '0;
        // RDMATLPS
        mrd_steering_tag_o      <= '0;
        mrd_tph_en_o            <= '0;
        mrd_phint_o             <= '0;
        mrd_td_o                <= '0;
        mrd_64b_en_o            <= '0;
        mrd_tlp_tc_o            <= '0;
        mrd_poisoned_o          <= '0;
        mrd_ats_o               <= '0;
        mrd_nw_o                <= '0;
        mrd_tbit_o              <= '0;
        mrd_len_o               <= 'd1;
        // RDMATLPUA
        mrd_up_addr_o           <= '0;
        // DMATLPEC
        mwr_tph_o               <= '0;
        mwr_tph_vld_o           <= '0;
        mrd_tph_vld_o           <= '0;
        mrd_tph_o               <= '0;
        // WDMAIDE
        mwr_ide_vld_o           <= '0;
        mwr_ide_o               <= '0;
        // RDMAIDE
        mrd_ide_o               <= '0;
        mrd_ide_vld_o           <= '0;
        // WDMAPASID
        mwr_pasid_o             <= '0;
        mwr_pasid_vld_o         <= '0;
        // RDMAPASID
        mrd_pasid_o             <= '0;
        mrd_pasid_vld_o         <= '0;
        // DMAEXT
        mrd_upper_be_o          <= '1;
        mrd_lower_be_o          <= '1;
        mwr_upper_be_o          <= '1;
        mwr_lower_be_o          <= '1;
        // DMAEXT2
        mrd_rrid_o              <= '0;
        mwr_rrid_o              <= '0;
        // RDMATLPC
        mrd_count_o             <= 'd1;
        mrd_inc_o               <= 1'b0;
        // DMATLPTYPE
        mrd_type_o              <= 5'b0_0000;
        mrd_fmt_o               <= 1'b0;
        mwr_type_o              <= 5'b0_0000;
        mwr_fmt_o               <= 1'b1;
        // DMAMSIX
        mwr_msix_vec_o          <= 11'd0;
        mrd_msix_vec_o          <= 11'd1;
        mwr_intx_vec_o          <= 2'd0;
        mrd_intx_vec_o          <= 2'd1;

    end else begin
        // Constraints
        mwr_count_o     <= mwr_count_o == '0 ? 16'd1 : mwr_count_o;
        mrd_count_o     <= mrd_count_o == '0 ? 16'd1 : mrd_count_o;

        if (mwr_type_o == 5'b0_0000 && mwr_fmt_o == 1'b1)
            mwr_len_o       <= mwr_len_o   == '0 ? 16'd1 : mwr_len_o;
        mrd_len_o       <= mrd_len_o   == '0 ? 16'd1 : mrd_len_o;

        case(cfg_max_payload_size)
            3'b000 : mwr_len_o       <= mwr_len_o < 9'h100 ? mwr_len_o : 9'h020;
            3'b001 : mwr_len_o       <= mwr_len_o < 9'h100 ? mwr_len_o : 9'h040;
            3'b010 : mwr_len_o       <= mwr_len_o < 9'h100 ? mwr_len_o : 9'h080;
            3'b011 : mwr_len_o       <= mwr_len_o < 9'h100 ? mwr_len_o : 9'h100;
            3'b100 : mwr_len_o       <= mwr_len_o < 9'h100 ? mwr_len_o : 9'h100;
            3'b101 : mwr_len_o       <= mwr_len_o < 9'h100 ? mwr_len_o : 9'h100;
            default: mwr_len_o       <= mwr_len_o < 9'h100 ? mwr_len_o : 9'h100;
        endcase

        case(cfg_max_rd_req_size)
            3'b000 : mrd_len_o       <= mrd_len_o > 11'h400 ? 11'h020 : mrd_len_o;
            3'b001 : mrd_len_o       <= mrd_len_o > 11'h400 ? 11'h040 : mrd_len_o;
            3'b010 : mrd_len_o       <= mrd_len_o > 11'h400 ? 11'h080 : mrd_len_o;
            3'b011 : mrd_len_o       <= mrd_len_o > 11'h400 ? 11'h100 : mrd_len_o;
            3'b100 : mrd_len_o       <= mrd_len_o > 11'h400 ? 11'h200 : mrd_len_o;
            3'b101 : mrd_len_o       <= mrd_len_o > 11'h400 ? 11'h400 : mrd_len_o;
            default: mrd_len_o       <= mrd_len_o > 11'h400 ? 11'h400 : mrd_len_o;
        endcase

        // PASID config enable
        mrd_pasid_vld_o <= cfg_pf_pasid_en == 1'b1 ? mrd_pasid_vld_o : '0;
        mwr_pasid_vld_o <= cfg_pf_pasid_en == 1'b1 ? mwr_pasid_vld_o : '0;

        // Atomics config enable
        if (mrd_type_o == 5'b01100 || mrd_type_o == 5'b01101 || mrd_type_o == 5'b01110) begin
            mrd_type_o <= cfg_atomic_req_en ? mrd_type_o : 5'b00000;
            mrd_fmt_o <= cfg_atomic_req_en ? mrd_fmt_o : 1'b0;
        end

        mrd_upper_be_o <= mrd_len_o == 1 ? '0 :
                          mrd_upper_be_o == '0 ? '1 :
                          mrd_upper_be_o;
        if (mwr_type_o == 5'b0_0000 && mwr_fmt_o == 1'b1)
            mwr_upper_be_o <= mwr_len_o == 1 ? '0 :
                              mwr_upper_be_o == '0 ? '1 :
                              mwr_upper_be_o;

        case (a_i[6:0])

            // Device Control Status Register (DCSR1)
            // -----------------------------------------------------
            //   [0]:        Initiator Reset                 (RW) 0=no reset 1=reset.
            //   [7:1]:      Reserved
            //   [15:8]:     Version Number                  (RO)
            //   [31:16]:    Reserved
            DCSR1: begin
                // Writable
                if (wr_en_i)
                    init_rst_o  <= wr_d_i[0];
                // Readable
                rd_d_o <= { {16'b0}, version_number, {7'b0}, init_rst_o};

                if (init_rst_o) begin
                    mwr_start_o <= 1'b0;
                    mrd_start_o <= 1'b0;
                end
            end

            // Device DMA Control Status Register (DCSR2)
            // -----------------------------------------------------
            //   [0]:        Memory Write Start              (RW) 0=no start, 1=start
            //   [3:1]:      Max Payload Size                (RO) Device max payload size
            //   [4]:        Reserved
            //   [5]:        Write DMA Relaxed Ordering      (RW) 1=sets relaxed ordering
            //   [6]:        Write DMA No Snoop              (RW) 1=sets no-snoop attribute
            //   [7]:        Write DMA Interrupt Disable     (RW) 1=disable
            //   [8]:        Write DMA Done                  (RO) 1=Write operation done
            //   [10:9]:     Write Interrupt Select          (RW) 00: MSIX, 01: MSI, 10: INTx
            //   [13:11]:    Reserved
            //   [15:14]:    Read Interrupt Select           (RW) 00: MSIX, 01: MSI, 10: INTx
            //   [16]:       Read DMA Start                  (RW) 0=no start, 1=start
            //   [19:17]:    Max Read Req Size               (RO) Device max read request size
            //   [20]:       Reserved
            //   [21]:       Read DMA Relaxed Ordering       (RW) 1=sets relaxed ordering
            //   [22]:       Read DMA No Snoop               (RW) 1=sets no-snoop attribute
            //   [23]:       Read DMA Interrupt Disable      (RW) 1=disable
            //   [24]:       Read DMA Done                   (RO) 1=Read operation done
            //   [30:25]:    Reserved
            //   [31]:       Read DMA Operation Data Error   (RO) 1=Actual isnt expected
            DCSR2: begin
                // Writable
                if (wr_en_i) begin
                    mwr_start_o            <= wr_d_i[0];
                    mwr_relaxed_order_o    <= wr_d_i[5];
                    mwr_nosnoop_o          <= wr_d_i[6];
                    mwr_int_dis_o          <= wr_d_i[7];
                    mwr_int_select_o       <= wr_d_i[10:9];
                    mrd_int_select_o       <= wr_d_i[15:14];
                    mrd_start_o            <= wr_d_i[16];
                    mrd_relaxed_order_o    <= wr_d_i[21];
                    mrd_nosnoop_o          <= wr_d_i[22];
                    mrd_int_dis_o          <= wr_d_i[23];
                end
                // Readable
                rd_d_o <= {cpld_data_err_i /*[31]*/, 6'b0, mrd_done_i /*[24]*/,
                            mrd_int_dis_o /*[23]*/,  mrd_nosnoop_o /*[22]*/,
                            mrd_relaxed_order_o /*[21]*/, 1'b0, cfg_max_rd_req_size, mrd_start_o /*[16]*/,
                            mrd_int_select_o /*[15:14]*/, 3'd0, mwr_int_select_o /*[10:9]*/,
                            mwr_done_i /*[8]*/, mwr_int_dis_o /*[7]*/,
                            mwr_nosnoop_o /*[6]*/, mwr_relaxed_order_o /*[5]*/,
                            1'b0, cfg_max_payload_size /*[3:1]*/, mwr_start_o /*[0]*/};
            end

            // Write DMA TLP Address (WDMATLPA)
            // -----------------------------------------------------
            //   [31:0]:     Write DMA Lower TLP Address     (RW) Initial Lower TLP Address
            WDMATLPA: begin
                // Writable
                if (wr_en_i) begin
                    mwr_addr_o  <= wr_d_i[31:0];
                end
                // Readable
                rd_d_o <= mwr_addr_o;
            end

            // Write DMA TLP Size (WDMATLPS)
            // -----------------------------------------------------
            //   [10:0]:     Write DMA TLP Size              (RW) Payload length in DWORDS (4 bytes)
            //   [11]:       Write DMA T-bit                 (RW) Memory Write TLP T-bit field (IDE)
            //   [12]:       Write DMA No-Write              (RW) Memory Write TLP No-Write bit
            //   [14:13]:    Write DMA ATS                   (RW) Memory Write ATS field
            //   [15]:       Write DMA Poisoned              (RW) Memory Write Poisoned TLP field
            //   [18:16]:    Write DMA TLP TC                (RW) Memory Write TLP Traffic Class
            //   [19]:       64bit Write Enable              (RW) Enables 64-bit write generation
            //   [20]:       Write DMA TD                    (RW) Memory Write TLP Digest Field
            //   [22:21]:    Write DMA Processing Hints      (RW) Memory Write PH field
            //   [23]:       Write DMA TPH Enable            (RW) Memory Write TPH Enable field
            //   [31:24]:    Write DMA Steering Tag          (RW) Memory Write Steering Tag field
            WDMATLPS: begin
                // Writable
                if (wr_en_i) begin
                    mwr_len_o              <= wr_d_i[10:0];
                    mwr_tbit_o             <= wr_d_i[11];
                    mwr_nw_o               <= wr_d_i[12];
                    mwr_ats_o              <= wr_d_i[14:13];
                    mwr_poisoned_o         <= wr_d_i[15];
                    mwr_tlp_tc_o           <= wr_d_i[18:16];
                    mwr_64b_en_o           <= wr_d_i[19];
                    mwr_td_o               <= wr_d_i[20];
                    mwr_phint_o            <= wr_d_i[22:21];
                    mwr_tph_en_o           <= wr_d_i[23];
                    mwr_steering_tag_o     <= wr_d_i[31:24];
                end
                // Readable
                rd_d_o <= {mwr_steering_tag_o, mwr_tph_en_o, mwr_phint_o, mwr_td_o,
                            mwr_64b_en_o, mwr_tlp_tc_o, mwr_poisoned_o, mwr_ats_o,
                            mwr_nw_o, mwr_tbit_o, mwr_len_o};
            end

            // Write DMA TLP Upper Address (WDMATLPUA)
            // -----------------------------------------------------
            //   [31:0]:     Write DMA Upper TLP Address    (RW) Memory Write TLP upper address
            WDMATLPUA: begin
                // Writable
                if (wr_en_i) begin
                    mwr_up_addr_o           <= wr_d_i;
                end
                // Readable
                rd_d_o <= {mwr_up_addr_o};
            end

            // Write DMA TLP Count (WDMATLPC)
            // -----------------------------------------------------
            //   [15:0]:     Write DMA TLP Count             (RW) Number of write TLPs to generate
            //   [20:16]:    Reserved                        (RO)
            //   [30:21]:    Write DMA TID                   (RW) Controls TID field
            //   [31]:       Write DMA Address Increment     (RW) Controls if address increases
            WDMATLPC: begin
                // Writable
                if (wr_en_i) begin
                    mwr_count_o  <= wr_d_i[15:0];
                    mwr_tid_o    <= wr_d_i[30:21];
                    mwr_inc_o    <= wr_d_i[31];
                end
                // Readable
                rd_d_o <= {mwr_inc_o, mwr_tid_o, 5'd0, mwr_count_o};
            end

            // Write DMA Data Pattern (WDMATLPP)
            // -----------------------------------------------------
            //   [31:0]:     Write DMA Data Pattern          (RW) Data pattern to write
            WDMATLPP: begin
                // Writable
                if (wr_en_i)
                    mwr_data_o  <= wr_d_i;
                // Readable
                rd_d_o <= mwr_data_o;
            end

            // Read DMA Expected Data Pattern (RDMATLPP)
            // -----------------------------------------------------
            //  [31:0]:     Read DMA Expected Data Pattern   (RW) Expected data pattern
            RDMATLPP: begin
                // Writable
                if (wr_en_i)
                    cpld_data_o  <= wr_d_i;
                // Readable
                rd_d_o <= cpld_data_o;
            end

            // Read DMA TLP Address (RDMATLPA)
            // -----------------------------------------------------
            //   [31:0]:     Read DMA Lower TLP Address      (RW) Initial Lower TLP Address
            RDMATLPA: begin
                // Writable
                if (wr_en_i) begin
                    mrd_addr_o  <= wr_d_i[31:0];
                end
                // Readable
                rd_d_o <= mrd_addr_o;
            end

            // Read DMA TLP Size (RDMATLPS)
            // -----------------------------------------------------
            //   [10:0]:     Read DMA TLP Size               (RW) Read length in DWORDS (4 bytes)
            //   [11]:       Read DMA T-bit                  (RW) Memory Read T-bit field (IDE)
            //   [12]:       Read DMA No-Write               (RW) Memory Read No-Write field
            //   [14:13]:    Read DMA ATS                    (RW) Memory Read ATS field
            //   [15]:       Read DMA Poisoned TLP           (RW) Memory Read poisoned TLP field
            //   [18:16]:    Read DMA TLP TC                 (RW) Memory Read TLP Traffic Class
            //   [19]:       64bit Read TLP Enable           (RW) Enables 64-bit read generation
            //   [20]:       Read DMA TD                     (RW) Memory Read TLP Digest field
            //   [22:21]:    Read DMA Processing Hints       (RW) Memory Read PH field
            //   [23]:       Read DMA TPH Enable             (RW) Memory Read TPH enable field
            //   [31:24]:    Read DMA Steering Tag           (RW) Memory Read ST field
            RDMATLPS: begin
                // Writable
                if (wr_en_i) begin
                    mrd_len_o           <= wr_d_i[10:0];
                    mrd_tbit_o          <= wr_d_i[11];
                    mrd_nw_o            <= wr_d_i[12];
                    mrd_ats_o           <= wr_d_i[14:13];
                    mrd_poisoned_o      <= wr_d_i[15];
                    mrd_tlp_tc_o        <= wr_d_i[18:16];
                    mrd_64b_en_o        <= wr_d_i[19];
                    mrd_td_o            <= wr_d_i[20];
                    mrd_phint_o         <= wr_d_i[22:21];
                    mrd_tph_en_o        <= wr_d_i[23];
                    mrd_steering_tag_o  <= wr_d_i[31:24];
                end
                // Readable
                rd_d_o <= {mrd_steering_tag_o, mrd_tph_en_o, mrd_phint_o,
                            mrd_td_o, mrd_64b_en_o, mrd_tlp_tc_o, mrd_poisoned_o,
                            mrd_ats_o, mrd_nw_o, mrd_tbit_o, mrd_len_o};
            end

            // Read DMA TLP Upper Address (RDMATLPUA)
            // -----------------------------------------------------
            //   [31:0]:     Read DMA Upper TLP Address         (RW)
            RDMATLPUA: begin
                // Writable
                if (wr_en_i) begin
                    mrd_up_addr_o       <= wr_d_i;
                end
                // Readable
                rd_d_o <= mrd_up_addr_o;
            end

            // Read DMA TLP Count (RDMATLPC)
            // -----------------------------------------------------
            //   [15:0]:     Read DMA TLP Count              (RW) Number of read TLPs to generate
            //   [30:16]:    Reserved
            //   [31]:       Read DMA Address Increment      (RW) Controls if address increases
            RDMATLPC: begin
                // Writable
                if (wr_en_i) begin
                    mrd_count_o  <= wr_d_i[15:0];
                    mrd_inc_o    <= wr_d_i[31];
                end
                // Readable
                rd_d_o <= {mrd_inc_o, 15'h0, mrd_count_o};
            end

            // DMA TLP Type Control (DMATLPTYPE)
            // -----------------------------------------------------
            //   [4:0]:      Read TLP Type                   (RW) Override type field for reads
            //   [5]:        Read TLP Fmt[1]                 (RW) Override fmt[1] field for reads
            //   [10:6]:     Write TLP Type                  (RW) Override type field for writes
            //   [11]:       Write TLP Fmt[1]                (RW) Override fmt[1] field for writes
            //   [31:12]:    Reserved
            DMATLPTYPE : begin
                // Writeable
                if (wr_en_i) begin
                    mrd_type_o <= wr_d_i[4:0];
                    mrd_fmt_o  <= wr_d_i[5];
                    mwr_type_o <= wr_d_i[10:6];
                    mwr_fmt_o  <= wr_d_i[11];
                end
                // Readable
                rd_d_o <= {20'h00000, mwr_fmt_o, mwr_type_o, mrd_fmt_o, mrd_type_o};
            end


            // DMA Extended Control (DMAEXT)
            // -----------------------------------------------------
            //   [3:0]:      Read DMA Byte Enable [3:0]      (RW) Memory Read lower byte enable
            //   [7:4]:      Read DMA Byte Enable [7:4]      (RW) Memory Read upper byte enable
            //   [11:8]:     Write DMA Byte Enable [3:0]     (RW) Memory Write lower byte enable
            //   [15:12]:    Write DMA Byte Enable [7:4]     (RW) Memory Write upper byte enable
            //   [31:16]:    Reserved
            DMAEXT : begin
                // Writeable
                if (wr_en_i) begin
                    mrd_lower_be_o <= wr_d_i[3:0];
                    mrd_upper_be_o <= wr_d_i[7:4];
                    mwr_lower_be_o <= wr_d_i[11:8];
                    mwr_upper_be_o <= wr_d_i[15:12];
                end
                // Readable
                rd_d_o <= {16'h0000, mwr_upper_be_o, mwr_lower_be_o, mrd_upper_be_o, mrd_lower_be_o};
            end

            // DMA Extended Control 2 (DMAEXT2)
            // -----------------------------------------------------
            //   [15:0]:     Read DMA Remote Req ID          (RW) Read DMA remote request ID
            //   [31:16]:    Write DMA Remote Req ID         (RW) Write DMA remote request ID
            DMAEXT2 : begin
                // Writeable
                if (wr_en_i) begin
                    mrd_rrid_o <= wr_d_i[15:0];
                    mwr_rrid_o <= wr_d_i[31:16];
                end
                // Readable
                rd_d_o <= {mwr_rrid_o, mrd_rrid_o};
            end

            // DMA MSIX Vector Control (DMAMSIX)
            // -----------------------------------------------------
            //   [10:0]:     Write Vector                    (RW) MSIX Write Done Vector
            //   [21:11]:    Read Vector                     (RW) MSIX Read Done Vector
            //   [23:22]:    Write INTx Wire                 (RW) INTx Write Wire
            //   [25:24]:    Read INTx Wire                  (RW) INTx Read Wire
            //   [31:26]:    Reserved
            DMAMSIX : begin
                // Writable
                if (wr_en_i) begin
                    mwr_msix_vec_o <= wr_d_i[10:0];
                    mrd_msix_vec_o <= wr_d_i[21:11];
                    mwr_intx_vec_o <= wr_d_i[23:22];
                    mrd_intx_vec_o <= wr_d_i[25:24];
                end
                // Readable
                rd_d_o <= {6'd0, mrd_intx_vec_o, mwr_intx_vec_o, mrd_msix_vec_o, mwr_msix_vec_o};
            end

            // DMA TLP TPH Control (DMATPH)
            // -----------------------------------------------------
            //   [11:0]:     Write DMA TPH                      (RW)
            //   [12]:       Write DMA TPH Valid                (RW)
            //   [24:13]:    Read DMA TPH                       (RW)
            //   [25]:       Read DMA TPH Valid                 (RW)
            //   [31:26]:    Reserved
            DMATPH: begin
                // Writable
                if (wr_en_i) begin
                    mwr_tph_o               <= wr_d_i[11:0];
                    mwr_tph_vld_o           <= wr_d_i[12];
                    mrd_tph_o               <= wr_d_i[24:13];
                    mrd_tph_vld_o           <= wr_d_i[25];
                end
                // Readable
                rd_d_o <= { 6'd0, mrd_tph_vld_o, mrd_tph_o, mwr_tph_vld_o, mwr_tph_o };
            end

            // Write DMA TLP IDE Control (WDMAIDE)
            // -----------------------------------------------------
            //   [0]:       Write DMA IDE Valid          (RW)
            //   [24:1]:    Write DMA IDE                (RW)
            //   [31:25]:   Reserved
            WDMAIDE: begin
                // Writable
                if (wr_en_i) begin
                    mwr_ide_vld_o       <= wr_d_i[0];
                    mwr_ide_o           <= wr_d_i[24:1];
                end
                // Readable
                rd_d_o <= { 7'd0, mwr_ide_o, mwr_ide_vld_o };
            end

            // Read DMA TLP IDE Control (RDMAIDE)
            // -----------------------------------------------------
            //   [0]:       Read DMA IDE Valid          (RW)
            //   [24:1]:    Read DMA IDE                (RW)
            //   [31:25]:   Reserved
            RDMAIDE: begin
                // Writable
                if (wr_en_i) begin
                    mrd_ide_vld_o       <= wr_d_i[0];
                    mrd_ide_o           <= wr_d_i[24:1];
                end
                // Readable
                rd_d_o <= { 7'd0, mrd_ide_o, mrd_ide_vld_o };
            end

            // Write DMA TLP PASID Control (WDMAPASID)
            // -----------------------------------------------------
            //   [0]:       Write DMA PASID Valid        (RW)
            //   [24:1]:    Write DMA PASID              (RW)
            //   [31:25]:   Reserved
            WDMAPASID: begin
                // Writable
                if (wr_en_i) begin
                    mwr_pasid_vld_o     <= wr_d_i[0];
                    mwr_pasid_o         <= wr_d_i[24:1];
                end
                // Readable
                rd_d_o <= { 7'd0, mwr_pasid_o, mwr_pasid_vld_o };
            end

            // Read DMA TLP PASID Control (RDMAPASID)
            // -----------------------------------------------------
            //   [0]:       Read DMA PASID Valid        (RW)
            //   [24:1]:    Read DMA PASID              (RW)
            //   [31:25]:   Reserved
            RDMAPASID: begin
                // Writable
                if (wr_en_i) begin
                    mrd_pasid_vld_o     <= wr_d_i[0];
                    mrd_pasid_o         <= wr_d_i[24:1];
                end
                // Readable
                rd_d_o <= { 7'd0, mrd_pasid_o, mrd_pasid_vld_o };
            end

            // Write DMA Performance (WDMAPERF)
            // -----------------------------------------------------
            //   [31:0]:     Write DMA Performance Counter   (RO) Number of clock cycles for write DMA transfer
            WDMAPERF: begin
                // Readable
                rd_d_o <= mwr_perf;
            end

            // Read DMA Performance (RDMAPERF)
            // -----------------------------------------------------
            //   [31:0]:     Read DMA Performance Counter    (RO) Number of clock cycles for read DMA transfer
            RDMAPERF: begin
                // Readable
                rd_d_o <= mrd_perf;
            end

            // Read DMA Status (RDMASTAT1)
            // -----------------------------------------------------
            //   [15:0]:      Completions w/ UR Received     (RO) Number of completion w/ UR received
            //   [25:16]:     Tag received on last UR        (RO) Tag received on last completion w/ UR
            //   [31:26]:     Reserved
            RDMASTAT1: begin
                // Readable
                rd_d_o <= {6'b0, cpl_ur_tag_i, cpl_ur_found_i};
            end

            // Number of Read Completion w/ Data (RDMASTAT2)
            // -----------------------------------------------------
            //   [31:0]:     Number of Completions w/ Data   (RO) Number of completions w/ data received
            RDMASTAT2: begin
                // Readable
                rd_d_o <= {cpld_found_i};
            end

            // Read Completion Data Size (RDMASTAT3)
            // -----------------------------------------------------
            //   [31:0]:     Completion w/ data total size   (RO) Completion w/ data total size
            RDMASTAT3: begin
                // Readable
                rd_d_o <= {cpld_data_size_i};
            end

            // Reserved
            default: begin
                rd_d_o <= 32'b0;
            end
        endcase
    end
end


/*
* Memory Write Performance Instrumentation
*/
always @(posedge clk ) begin
    if ( !rst_n ) begin
        mwr_perf <= 32'b0;
    end else begin
        if (init_rst_o)
            mwr_perf <= 32'b0;
        // Count clock cycles
        else if (mwr_start_o && !mwr_done_i)
            mwr_perf <= mwr_perf + 1'b1;
    end
end

/*
* Memory Read Performance Instrumentation
*/
always @(posedge clk ) begin
    if ( !rst_n ) begin
        mrd_perf <= 32'b0;
    end else begin
        if (init_rst_o)
            mrd_perf <= 32'b0;
        // Count clock cycles
        else if (mrd_start_o && !mrd_done_i)
            mrd_perf <= mrd_perf + 1'b1;
    end
end

endmodule  // BMD_AXIST_EP_MEM
