
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
// File       : BMD_AXIST_EP.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_EP.sv
//--
//-- Description: BMD Endpoint module. Initializes main TX and RX logic.
//--              Additionally, the module will initialize the TX MUX, RX MUX
//--              and the EP MEM logic.
//--              RX logic handles the MemRd/MemWr and completions from RP
//--              TX logic handles generating MemRd and MemWr traffic and sends
//--              completions back to RP
//--              RX MUX handles credits, buffering, and serialization of the
//--              slots of incoming TLPs
//--              TX MUX handles credits and arbitration of Read, Write, and
//--              Completion streams.
//--              EP MEM houses the control status registers (CSRs) for
//--              controlling the BMD design behavior and monitoring status
//--              of traffic.
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_EP
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
  import bmd_cfg_pkg::*;
  import cpm6_v1_0_pkg::*;
#(
    parameter int           NUM_TX_STREAMS      = 3,
    parameter int           PATTERN_WIDTH       = 32
)(
    input  logic                        clk,
    input  logic                        rst_n,

    output tx_intf                      tx,
    input  rx_intf                      rx,

    tx_credit_if.slave                  tx_crd,
    rx_credit_if.master                 rx_crd,

    input  pf_cfg_t [NUM_PFS - 1 : 0]   pf_cfg,
    input  vf_cfg_t [NUM_VFS - 1 : 0]   vf_cfg,

    // LTSSM state
    input  logic [5:0]                  ltssm_state,
    input  logic                        link_up,

    // PME
    output logic            app_ready_entr_l23,

    // MSI-X
    msix_user_intf.master   msix,
    pcie6_msix_pl_if.s      msi,

    output logic [31:0]     debug_bmd,
    input  logic [4:0]      debug_bmd_sel
);

///////////////////////////////////////////////////////////////////
//
//          Debug Signals
//
///////////////////////////////////////////////////////////////////

// 4'b0000
logic   [31:0]              debug_bmd_mem;
// 4'b0001
logic   [31:0]              debug_bmd_rx_cpl;
// 4'b0010
logic   [31:0]              debug_bmd_rx_rw;
// 4'b0011
logic   [31:0]              debug_bmd_intr;
// 4'b0100
logic   [31:0]              debug_bmd_tx_cpl;
// 4'b0101
logic   [31:0]              debug_bmd_tx_write;
// 4'b0110
logic   [31:0]              debug_bmd_tx_read;
// 4'b0111
logic   [31:0]              debug_bmd_rx_cpl_filter;
// 4'b1000
logic   [31:0]              debug_bmd_rx_fifo;
// 4'b1001

// 4'b1010
logic   [31:0]              debug_bmd_rx_packer;
// 4'b1011
logic   [31:0]              debug_bmd_tx_fifo;
// 4'b1100
logic   [31:0]              debug_bmd_tx_splitter;
// 4'b1101
logic   [31:0]              debug_bmd_tx_arbitration;
// 4'b1110
logic   [31:0]              debug_bmd_credits;
// 4'b1111
logic   [31:0]              debug_bmd_cfg_status;

always_comb begin
    case(debug_bmd_sel)
        4'b0000 : debug_bmd = debug_bmd_mem;
        4'b0001 : debug_bmd = debug_bmd_rx_cpl;
        4'b0010 : debug_bmd = debug_bmd_rx_rw;
        4'b0011 : debug_bmd = debug_bmd_intr;
        4'b0100 : debug_bmd = debug_bmd_tx_cpl;
        4'b0101 : debug_bmd = debug_bmd_tx_write;
        4'b0110 : debug_bmd = debug_bmd_tx_read;
        4'b0111 : debug_bmd = debug_bmd_rx_cpl_filter;
        4'b1000 : debug_bmd = debug_bmd_rx_fifo;
        4'b1001 : debug_bmd = '0;
        4'b1010 : debug_bmd = debug_bmd_rx_packer;
        4'b1011 : debug_bmd = debug_bmd_tx_fifo;
        4'b1100 : debug_bmd = debug_bmd_tx_splitter;
        4'b1101 : debug_bmd = debug_bmd_tx_arbitration;
        4'b1110 : debug_bmd = debug_bmd_credits;
        4'b1111 : debug_bmd = debug_bmd_cfg_status;
        default : debug_bmd = '0;
    endcase
end

assign debug_bmd_cfg_status = {
    6'b0,
    vf_cfg[VFUNC_NUM].flr_vf_active,
    vf_cfg[VFUNC_NUM].vf_msix_func_mask,
    vf_cfg[VFUNC_NUM].vf_msix_en,
    vf_cfg[VFUNC_NUM].vf_msi_en,
    vf_cfg[VFUNC_NUM].vf_bme,
    pf_cfg[FUNC_NUM].c1.flit_mode,
    pf_cfg[FUNC_NUM].c1.pm_turnoff,
    pf_cfg[FUNC_NUM].c1.prs_en,
    pf_cfg[FUNC_NUM].c1.ats_cache_en,
    pf_cfg[FUNC_NUM].c1.pasid_priv_mode_en,
    pf_cfg[FUNC_NUM].c1.pasid_execute_perm_en,
    pf_cfg[FUNC_NUM].c1.io_space_en,
    pf_cfg[FUNC_NUM].c1.pm_status,
    pf_cfg[FUNC_NUM].c1.int_disable,
    pf_cfg[FUNC_NUM].c1.vf_en,
    pf_cfg[FUNC_NUM].c1.tenb_tag_req_en,
    pf_cfg[FUNC_NUM].c0.flr_pf_active,
    pf_cfg[FUNC_NUM].c0.rcb,
    pf_cfg[FUNC_NUM].c0.ext_tag_en,
    pf_cfg[FUNC_NUM].c0.max_payload_size,
    pf_cfg[FUNC_NUM].c0.max_rd_req_size,
    pf_cfg[FUNC_NUM].c0.atomic_req_en,
    pf_cfg[FUNC_NUM].c0.pf_pasid_en,
    pf_cfg[FUNC_NUM].c0.msix_func_mask,
    pf_cfg[FUNC_NUM].c0.msix_en,
    pf_cfg[FUNC_NUM].c0.msi_en,
    pf_cfg[FUNC_NUM].c0.mem_space_en,
    pf_cfg[FUNC_NUM].c0.bus_master_en
};

///////////////////////////////////////////////////////////////////
//
//          Internal Signals
//
///////////////////////////////////////////////////////////////////
logic                           init_rst;
// EP MEM Read/Write
logic [10:0]                    addr;
logic [3:0]                     rd_be;
logic [31:0]                    rd_data;
logic [3:0]                     wr_be;
logic [31:0]                    wr_data;
logic                           wr_en;
logic                           wr_busy;
// Generated Memory Read / Read Characteristics (from EP MEM)
logic [4:0]                     mrd_type;
logic                           mrd_fmt;
logic [4:0]                     mwr_type;
logic                           mwr_fmt;
logic                           mrd_start;
logic                           mrd_inc;
logic [31:0]                    mrd_addr;
logic [31:0]                    mrd_up_addr;
logic [10:0]                    mrd_len;
logic [15:0]                    mrd_count;
logic                           mrd_int_dis;
logic                           mrd_nosnoop;
logic                           mrd_relaxed_order;
logic                           mrd_64b_en;
logic [2:0]                     mrd_tlp_tc;
logic [11:0]                    mrd_tph;
logic                           mrd_tph_vld;
logic [23:0]                    mrd_ide;
logic                           mrd_ide_vld;
logic [23:0]                    mrd_pasid;
logic                           mrd_pasid_vld;
logic [1:0]                     mrd_ats;
logic                           mrd_nw;
logic                           mrd_poisoned;
logic [7:0]                     mrd_steering_tag;
logic [1:0]                     mrd_phint;
logic                           mrd_tph_en;
logic [3:0]                     mrd_upper_be;
logic [3:0]                     mrd_lower_be;
logic [15:0]                    mrd_rrid;
logic                           mrd_td;
logic                           mrd_tbit;
// Generated Memory Write / Write Characteristics (from EP MEM)
logic                           mwr_start;
logic                           mwr_inc;
logic [9:0]                     mwr_tid;
logic [31:0]                    mwr_addr;
logic [31:0]                    mwr_up_addr;
logic [31:0]                    mwr_data;
logic [10:0]                    mwr_len;
logic [15:0]                    mwr_count;
logic                           mwr_done;
logic                           mwr_int_dis;
logic                           mwr_nosnoop;
logic                           mwr_relaxed_order;
logic                           mwr_64b_en;
logic [2:0]                     mwr_tlp_tc;
logic                           mwr_poisoned;
logic [11:0]                    mwr_tph;
logic                           mwr_tph_vld;
logic [23:0]                    mwr_ide;
logic                           mwr_ide_vld;
logic [23:0]                    mwr_pasid;
logic                           mwr_pasid_vld;
logic [1:0]                     mwr_ats;
logic                           mwr_nw;
logic                           mwr_tph_en;
logic [7:0]                     mwr_steering_tag;
logic [1:0]                     mwr_phint;
logic [3:0]                     mwr_upper_be;
logic [3:0]                     mwr_lower_be;
logic [15:0]                    mwr_rrid;
logic                           mwr_td;
logic                           mwr_tbit;
// Interrupt control
logic [10:0]                    mwr_msix_vec;
logic [10:0]                    mrd_msix_vec;
logic [1:0]                     mwr_intx_vec;
logic [1:0]                     mrd_intx_vec;
logic [1:0]                     mwr_int_select;
logic [1:0]                     mrd_int_select;
// Completion/Config Signals  (from EP MEM)
logic                           cpld_data_err;
logic [31:0]                    cpld_data;
logic [15:0]                    cpl_ur_found;
logic [9:0]                     cpl_ur_tag;
logic [31:0]                    cpld_found;
logic [31:0]                    cpld_data_size;
// TX MUX producer interfaces
tx_intf                         main_tx;
tx_intf                         read_tx;
tx_intf                         write_tx;
tx_intf                         cpl_tx;
// INTx
tx_intf                         tx_intx;
logic                           tx_intx_grant;
// RX MUX consumer interfaces
logic                           mmio_valid;
rx_fifo_intf                    mmio_slot;
logic                           mmio_rd_en;
rx_intf                         rx_cpl;
// RX RW -> TX CPL
logic                           cpl_done;
logic                           req_compl;
logic                           req_compl_wd;
logic                           req_compl_ur;
logic [2:0]                     req_tc;
logic [9:0]                     req_len;
logic [13:0]                    req_lookup_id;
// RX CPL -> TX READ
logic [($clog2(NUM_SLOTS)>>1):0]        tag_valid;
logic [($clog2(NUM_SLOTS)>>1):0][9:0]   tag_released;
// Credits
logic [NUM_SLOTS-1:0][1:0]              fifo_rd_en;
logic [NUM_SLOTS-1:0][1:0]              fifo_empty;
logic [$clog2(NUM_SLOTS)-1:0]           tx_credits_consumed;
logic                                   tx_slot_consumed;
logic                                   tx_credits_available;
logic                                   tx_slot_available;

logic [1:0][NUM_SLOTS-1:0]              tx_fifo_full;
logic                                   wr_fifo_empty;

// PME Signals
logic                                   pme_turnoff;
logic [NUM_SLOTS-1:0]                   empty_cpl;
logic                                   int_cpl_done;

logic                                   txn_inp;

logic [63:0] rx_nonposted_header_count;
logic [63:0] tx_completion_header_count;

///////////////////////////////////////////////////////////////////
//
//          TX Module Instantiation
//
///////////////////////////////////////////////////////////////////

BMD_AXIST_TX_MUX #(
    .NUM_STREAMS                        ( NUM_TX_STREAMS ),
    .FIFO_DEPTH                         ( FIFO_DEPTH )
) EP_TX_MUX (
    .clk                                ( clk ),
    .rst_n                              ( rst_n ),
    // Credits
    .tx_credits_consumed                ( tx_credits_consumed ),
    .tx_credits_available               ( tx_credits_available ),

    .fifo_full                          ( tx_fifo_full ),
    .wr_fifo_empty                      ( wr_fifo_empty ),

    // TX interfaces
    .sub_tx                             ( {cpl_tx,     read_tx,     write_tx} ),
    .main_tx                            ( main_tx ),

    .empty_cpl                          ( empty_cpl ),

    .inp                                ( txn_inp ),

    .tx_posted_header_count             (  ),
    .tx_nonposted_header_count          (  ),
    .tx_completion_header_count         ( tx_completion_header_count ),
    .tx_data_count                      (  ),

    .debug_fifo                         ( debug_bmd_tx_fifo ),
    .debug_splitter                     ( debug_bmd_tx_splitter ),
    .debug_arbitration                  ( debug_bmd_tx_arbitration )
);

BMD_AXIST_TX #(
    .PATTERN_WIDTH                      ( PATTERN_WIDTH )
) EP_TX (
    .clk                                ( clk ),
    .rst_n                              ( rst_n ),
    .init_rst_i                         ( init_rst ),
    // Memory Read
    .mrd_start_i                        ( mrd_start ),
    .mrd_inc_i                          ( mrd_inc ),
    .mrd_addr_i                         ( mrd_addr ),
    .mrd_up_addr_i                      ( mrd_up_addr ),
    .mrd_len_i                          ( mrd_len ),
    .mrd_count_i                        ( mrd_count ),
    // Read Characteristics
    .mrd_nosnoop_i                      ( mrd_nosnoop ),
    .mrd_relaxed_order_i                ( mrd_relaxed_order ),
    .mrd_64b_en_i                       ( mrd_64b_en ),
    .mrd_tlp_tc_i                       ( mrd_tlp_tc ),
    .mrd_tph_i                          ( mrd_tph ),
    .mrd_tph_vld_i                      ( mrd_tph_vld ),
    .mrd_ide_i                          ( mrd_ide ),
    .mrd_ide_vld_i                      ( mrd_ide_vld ),
    .mrd_pasid_i                        ( mrd_pasid ),
    .mrd_pasid_vld_i                    ( mrd_pasid_vld ),
    .mrd_ats_i                          ( mrd_ats ),
    .mrd_nw_i                           ( mrd_nw ),
    .mrd_poisoned_i                     ( mrd_poisoned ),
    .mrd_steering_tag_i                 ( mrd_steering_tag ),
    .mrd_phint_i                        ( mrd_phint ),
    .mrd_tph_en_i                       ( mrd_tph_en ),
    .mrd_type_i                         ( mrd_type ),
    .mrd_fmt_i                          ( mrd_fmt ),
    .mrd_upper_be_i                     ( mrd_upper_be ),
    .mrd_lower_be_i                     ( mrd_lower_be ),
    .mrd_rrid_i                         ( mrd_rrid ),
    .mrd_td_i                           ( mrd_td ),
    .mrd_tbit_i                         ( mrd_tbit ),

    // Memory Write
    .mwr_start_i                        ( mwr_start ),
    .mwr_inc_i                          ( mwr_inc ),
    .mwr_tid_i                          ( mwr_tid ),
    .mwr_addr_i                         ( mwr_addr ),
    .mwr_up_addr_i                      ( mwr_up_addr ),
    .mwr_data_i                         ( mwr_data ),
    .mwr_len_i                          ( mwr_len ),
    .mwr_count_i                        ( mwr_count ),
    .mwr_done_o                         ( mwr_done ),
    // Write Characteristics
    .mwr_nosnoop_i                      ( mwr_nosnoop ),
    .mwr_relaxed_order_i                ( mwr_relaxed_order ),
    .mwr_64b_en_i                       ( mwr_64b_en ),
    .mwr_tlp_tc_i                       ( mwr_tlp_tc ),
    .mwr_poisoned_i                     ( mwr_poisoned ),
    .mwr_ats_i                          ( mwr_ats ),
    .mwr_nw_i                           ( mwr_nw ),
    .mwr_tph_en_i                       ( mwr_tph_en ),
    .mwr_steering_tag_i                 ( mwr_steering_tag ),
    .mwr_phint_i                        ( mwr_phint ),
    .mwr_tph_i                          ( mwr_tph ),
    .mwr_tph_vld_i                      ( mwr_tph_vld ),
    .mwr_ide_i                          ( mwr_ide ),
    .mwr_ide_vld_i                      ( mwr_ide_vld ),
    .mwr_pasid_i                        ( mwr_pasid ),
    .mwr_pasid_vld_i                    ( mwr_pasid_vld ),
    .mwr_type_i                         ( mwr_type ),
    .mwr_fmt_i                          ( mwr_fmt ),
    .mwr_upper_be_i                     ( mwr_upper_be ),
    .mwr_lower_be_i                     ( mwr_lower_be ),
    .mwr_rrid_i                         ( mwr_rrid ),
    .mwr_td_i                           ( mwr_td ),
    .mwr_tbit_i                         ( mwr_tbit ),
    // Completion information
    .cpl_done                           ( cpl_done ),
    .req_compl                          ( req_compl ),
    .req_compl_wd                       ( req_compl_wd ),
    .req_compl_ur                       ( req_compl_ur ),
    .req_tc                             ( req_tc ),
    .req_len                            ( req_len ),
    .req_lookup_id                      ( req_lookup_id ),
    // Memory data
    .mem_read_data                      ( rd_data ),
    // TX
    .cpl_tx                             ( cpl_tx ),
    .read_tx                            ( read_tx ),
    .write_tx                           ( write_tx ),
    // TX Read Tags
    .tag_valid                          ( tag_valid ),
    .tag_released                       ( tag_released ),
    // Backpressure
    .fifo_full                          ( tx_fifo_full ),
    // Config
    .cfg_10b_tag_req_en                 ( pf_cfg[FUNC_NUM].c1.tenb_tag_req_en ),
    .cfg_ext_tag_en                     ( pf_cfg[FUNC_NUM].c0.ext_tag_en ),

    .debug_cpl                          ( debug_bmd_tx_cpl ),
    .debug_write                        ( debug_bmd_tx_write ),
    .debug_read                         ( debug_bmd_tx_read )
);

///////////////////////////////////////////////////////////////////
//
//          Memory Module Instantiation
//
///////////////////////////////////////////////////////////////////

BMD_AXIST_EP_MEM_ACCESS EP_MEM_ACCESS (
    .clk                                ( clk ),
    .rst_n                              ( rst_n ),
    // PIO Signals
    .addr_i                             ( addr[8:2] ),
    .rd_be_i                            ( rd_be ),
    .rd_data_o                          ( rd_data ),
    .wr_be_i                            ( wr_be ),
    .wr_data_i                          ( wr_data ),
    .wr_en_i                            ( wr_en ),
    .wr_busy_o                          ( wr_busy ),
    // DCSR1
    .init_rst_o                         ( init_rst ),
    // DCSR2
    .cpld_data_err_i                    ( cpld_data_err ),
    .mrd_done_i                         ( mrd_done ),
    .mrd_int_dis_o                      ( mrd_int_dis ),
    .mrd_nosnoop_o                      ( mrd_nosnoop ),
    .mrd_relaxed_order_o                ( mrd_relaxed_order ),
    .mrd_start_o                        ( mrd_start ),
    .mwr_done_i                         ( mwr_done ),
    .mwr_int_dis_o                      ( mwr_int_dis ),
    .mwr_nosnoop_o                      ( mwr_nosnoop ),
    .mwr_relaxed_order_o                ( mwr_relaxed_order ),
    .mwr_start_o                        ( mwr_start ),
    .cfg_max_payload_size               ( pf_cfg[FUNC_NUM].c0.max_payload_size ),
    .cfg_max_rd_req_size                ( pf_cfg[FUNC_NUM].c0.max_rd_req_size ),
    .mwr_int_select_o                   ( mwr_int_select ),
    .mrd_int_select_o                   ( mrd_int_select ),
    // WDMATLPA
    .mwr_inc_o                          ( mwr_inc ),
    .mwr_tid_o                          ( mwr_tid ),
    .mwr_addr_o                         ( mwr_addr ),
    // WDMATLPS
    .mwr_steering_tag_o                 ( mwr_steering_tag ),
    .mwr_tph_en_o                       ( mwr_tph_en ),
    .mwr_phint_o                        ( mwr_phint ),
    .mwr_64b_en_o                       ( mwr_64b_en ),
    .mwr_tlp_tc_o                       ( mwr_tlp_tc ),
    .mwr_poisoned_o                     ( mwr_poisoned ),
    .mwr_ats_o                          ( mwr_ats ),
    .mwr_nw_o                           ( mwr_nw ),
    .mwr_len_o                          ( mwr_len ),
    .mwr_td_o                           ( mwr_td ),
    .mwr_tbit_o                         ( mwr_tbit ),
    // WDMATLPUA
    .mwr_up_addr_o                      ( mwr_up_addr ),
    // WDMATLPC
    .mwr_count_o                        ( mwr_count ),
    // WDMATLPP
    .mwr_data_o                         ( mwr_data ),
    // RDMATLPP
    .cpld_data_o                        ( cpld_data ),
    // RDMATLPA
    .mrd_inc_o                          ( mrd_inc ),
    .mrd_addr_o                         ( mrd_addr ),
    // RDMATLPS
    .mrd_steering_tag_o                 ( mrd_steering_tag ),
    .mrd_tph_en_o                       ( mrd_tph_en ),
    .mrd_phint_o                        ( mrd_phint ),
    .mrd_64b_en_o                       ( mrd_64b_en ),
    .mrd_tlp_tc_o                       ( mrd_tlp_tc ),
    .mrd_poisoned_o                     ( mrd_poisoned ),
    .mrd_ats_o                          ( mrd_ats ),
    .mrd_nw_o                           ( mrd_nw ),
    .mrd_len_o                          ( mrd_len ),
    .mrd_td_o                           ( mrd_td ),
    .mrd_tbit_o                         ( mrd_tbit ),
    // RDMATLPUA
    .mrd_up_addr_o                      ( mrd_up_addr ),
    // RDMATLPC
    .mrd_count_o                        ( mrd_count ),
    // DMATLPTYPE
    .mrd_type_o                         ( mrd_type ),
    .mrd_fmt_o                          ( mrd_fmt ),
    .mwr_type_o                         ( mwr_type ),
    .mwr_fmt_o                          ( mwr_fmt ),
    // DMATPH
    .mwr_tph_vld_o                      ( mwr_tph_vld ),
    .mwr_tph_o                          ( mwr_tph ),
    .mrd_tph_vld_o                      ( mrd_tph_vld ),
    .mrd_tph_o                          ( mrd_tph ),
    // WDMAIDE
    .mwr_ide_o                          ( mwr_ide ),
    .mwr_ide_vld_o                      ( mwr_ide_vld ),
    // RDMAIDE
    .mrd_ide_o                          ( mrd_ide ),
    .mrd_ide_vld_o                      ( mrd_ide_vld ),
    // WDMAPASID
    .mwr_pasid_o                        ( mwr_pasid ),
    .mwr_pasid_vld_o                    ( mwr_pasid_vld ),
    // RDMAPASID
    .mrd_pasid_o                        ( mrd_pasid ),
    .mrd_pasid_vld_o                    ( mrd_pasid_vld ),
    // DMAEXT
    .mrd_upper_be_o                     ( mrd_upper_be ),
    .mrd_lower_be_o                     ( mrd_lower_be ),
    .mwr_upper_be_o                     ( mwr_upper_be ),
    .mwr_lower_be_o                     ( mwr_lower_be ),
    // DMAEXT2
    .mrd_rrid_o                         ( mrd_rrid ),
    .mwr_rrid_o                         ( mwr_rrid ),
    // RDMASTAT1
    .cpl_ur_found_i                     ( cpl_ur_found ),
    .cpl_ur_tag_i                       ( cpl_ur_tag ),
    // RDMASTAT2
    .cpld_found_i                       ( cpld_found ),
    // RDMASTAT3
    .cpld_data_size_i                   ( cpld_data_size ),
    // DMAMSIX
    .mwr_msix_vec_o                     ( mwr_msix_vec ),
    .mrd_msix_vec_o                     ( mrd_msix_vec ),
    .mwr_intx_vec_o                     ( mwr_intx_vec ),
    .mrd_intx_vec_o                     ( mrd_intx_vec ),

    .cfg_atomic_req_en                  ( pf_cfg[FUNC_NUM].c0.atomic_req_en ),
    .cfg_pf_pasid_en                    ( pf_cfg[FUNC_NUM].c0.pf_pasid_en ),
    .debug                              ( debug_bmd_mem )
);

///////////////////////////////////////////////////////////////////
//
//          RX Module Instantiation
//
///////////////////////////////////////////////////////////////////
BMD_AXIST_RX_MUX EP_RX_MUX (
    .clk                                ( clk ),
    .rst_n                              ( rst_n ),
    // From Core
    .rx                                 ( rx ),
    // For credits
    .rd_en                              ( fifo_rd_en),
    .empty                              ( fifo_empty ),
    // To BMD_AXIST_RX Main
    .mmio_valid                         ( mmio_valid ),
    .mmio_slot                          ( mmio_slot ),
    .mmio_rd_en                         ( mmio_rd_en ),
    // To BMD_AXIST_RX Completions
    .rx_cpl                             ( rx_cpl ),

    .rx_posted_header_count             (  ),
    .rx_nonposted_header_count          ( rx_nonposted_header_count ),
    .rx_completion_header_count         (  ),
    .rx_data_count                      (  ),

    .debug_cpl_filter                   ( debug_bmd_rx_cpl_filter ),
    .debug_fifo                         ( debug_bmd_rx_fifo ),
    .debug_packer                       ( debug_bmd_rx_packer )
);

BMD_AXIST_RX EP_RX (
    .clk                                ( clk ),
    .rst_n                              ( rst_n ),
    .init_rst_i                         ( init_rst ),

    // From BMD_AXIST_RX_MUX
    .mmio_valid                         ( mmio_valid ),
    .mmio_slot                          ( mmio_slot ),
    .mmio_rd_en                         ( mmio_rd_en ),

    // From EP MEM
    .wr_busy                            ( wr_busy ),

    // To EP MEM
    .addr                               ( addr ),
    .wr_be                              ( wr_be ),
    .rd_be                              ( rd_be ),
    .wr_data                            ( wr_data ),
    .wr_en                              ( wr_en ),

    // To RX RW
    .req_compl                          ( req_compl ),
    .req_compl_wd                       ( req_compl_wd ),
    .req_compl_ur                       ( req_compl_ur ),
    .req_tc                             ( req_tc ),
    .req_len                            ( req_len ),
    .req_lookup_id                      ( req_lookup_id ),

    // From BMD_AXIST_TX_CPL
    .rx_cpl                             ( rx_cpl ),
    .tag_valid                          ( tag_valid ),
    .tag_released                       ( tag_released ),
    .read_done                          ( mrd_done ),
    .cpld_data                          ( cpld_data ),
    .mrd_count                          ( mrd_count ),
    .cpl_count                          ( cpld_found ),
    .cpl_data_dw_count                  ( cpld_data_size ),
    .read_dma_err                       ( cpld_data_err ),
    .cpl_ur_count                       ( cpl_ur_found ),
    .cpl_ur_tag                         ( cpl_ur_tag ),

    .debug_cpl                          ( debug_bmd_rx_cpl ),
    .debug_rw                           ( debug_bmd_rx_rw )
);

///////////////////////////////////////////////////////////////////
//
//                           Credits
//
///////////////////////////////////////////////////////////////////
BMD_AXIST_RX_CREDITS #(
    .NUM_CONSUMERS                      ( 2 )
) EP_RX_CREDITS (
    .clk                                ( clk ),
    .rst_n                              ( rst_n ),
    .link_down_reset                    ( link_up ),

    .fifo_rd_en                         ( fifo_rd_en ),
    .fifo_empty                         ( fifo_empty ),

    .cr_active                          ( rx_crd.cr_active ),
    .cr_valid                           ( rx_crd.cr_valid ),
    .cr                                 ( rx_crd.cr ),

    .debug                              ( debug_bmd_credits[31:16] )
);

BMD_AXIST_TX_CREDITS EP_TX_CREDITS (
    .clk                                ( clk ),
    .rst_n                              ( rst_n ),
    .link_down_reset                    ( link_up ),

    .tx_credits_consumed                ( tx_credits_consumed ),
    .tx_slot_consumed                   ( tx_slot_consumed ),
    .tx_credits_available               ( tx_credits_available ),
    .tx_slot_available                  ( tx_slot_available ),

    .cr_active                          ( tx_crd.cr_active ),
    .cr_valid                           ( tx_crd.cr_valid ),
    .cr                                 ( tx_crd.cr ),

    .debug                              ( debug_bmd_credits[15:0] )
);

///////////////////////////////////////////////////////////////////
//
//                           Interrupts
//
///////////////////////////////////////////////////////////////////
BMD_AXIST_INTR_CTRL EP_INTR_CTRL (
    .clk                                ( clk ),
    .rst_n                              ( rst_n ),
    .init_rst_i                         ( init_rst ),

    .cfg_int_disable                    ( pf_cfg[FUNC_NUM].c1.int_disable ),
    .cfg_msix_en                        ( pf_cfg[FUNC_NUM].c0.msix_en ),
    .cfg_msi_en                         ( pf_cfg[FUNC_NUM].c0.msi_en ),
    .wr_fifo_empty                      ( wr_fifo_empty ),

    // EP MEM interrupt configuration
    .wr_int_en                          ( !mwr_int_dis ),
    .rd_int_en                          ( !mrd_int_dis ),
    .rd_done                            ( mrd_done ),
    .wr_done                            ( mwr_done ),
    .mwr_int_select                     ( mwr_int_select ),
    .mrd_int_select                     ( mrd_int_select ),

    // MSI-X Control
    .user_error                         ( msix.user_error ),
    .user_func_num                      ( msix.user_func_num ),
    .user_vfunc_num                     ( msix.user_vfunc_num ),
    .user_vfunc_active                  ( msix.user_vfunc_active ),
    .user_req                           ( msix.user_req ),
    .user_vector_num                    ( msix.user_vector_num ),
    .user_grant                         ( msix.user_grant ),
    .user_operation                     ( msix.user_operation ),
    .mwr_msix_vec                       ( mwr_msix_vec ),
    .mrd_msix_vec                       ( mrd_msix_vec ),

    // MSI Control
    .pl_msi_func_num                    ( msi.pl_msi_func_num ),
    .pl_msi_vfunc_num                   ( msi.pl_msi_vfunc_num ),
    .pl_msi_vfunc_active                ( msi.pl_msi_vfunc_active ),
    .pl_msi_tc                          ( msi.pl_msi_tc ),
    .pl_msi_vector                      ( msi.pl_msi_vector ),
    .pl_issue_msi_req                   ( msi.pl_issue_msi_req ),
    .select_pl                          ( msi.select_pl ),
    .pl_done                            ( msi.pl_done ),

    // MSI-X address/data fields not driven by INTR_CTRL (pcie6_msix_pl_if extras)
    // INTx Control
    .tx_intx                            ( tx_intx ),
    .tx_intx_grant                      ( tx_intx_grant ),
    .mwr_intx_vec                       ( mwr_intx_vec ),
    .mrd_intx_vec                       ( mrd_intx_vec ),

    .debug                              ( debug_bmd_intr )
);

// pcie6_msix_pl_if signals not driven by BMD_AXIST_INTR_CTRL
assign msi.pl_msi_addr_lo   = '0;
assign msi.pl_msi_addr_hi   = '0;
assign msi.pl_msi_data      = '0;
assign msi.pl_issue_msix_req = '0;

///////////////////////////////////////////////////////////////////
//
//                          INTx Inject
//
///////////////////////////////////////////////////////////////////
always_comb begin
    tx_slot_consumed = 1'b0;
    tx_intx_grant = 1'b0;
    tx = main_tx;
    if(tx_intx.tx_valid && !main_tx.tx_valid &&
                !txn_inp && tx_slot_available) begin
        tx_slot_consumed = 1;
        tx = tx_intx;
        tx_intx_grant = 1'b1;
    end
end

///////////////////////////////////////////////////////////////////
//
//                        Power Management
//
///////////////////////////////////////////////////////////////////
always_comb begin
    pme_turnoff = 1'b0;
    int_cpl_done = 1'b0;

    for (int i = 0; i < NUM_PFS; i++) begin
        pme_turnoff = pme_turnoff | pf_cfg[i].c1.pm_turnoff;
    end

    int_cpl_done = (&empty_cpl) && cpl_done;
end

BMD_AXIST_PM_CTRL EP_PM_CTRL (
    .clk                                ( clk ),
    .rst_n                              ( rst_n ),

    .cpl_done                           ( int_cpl_done ),
    .rd_done                            ( mrd_done || !mrd_start),
    .rx_nonposted_header_count          ( rx_nonposted_header_count ),
    .tx_completion_header_count         ( tx_completion_header_count ),
    .ltssm_state                        ( ltssm_state ),

    .cfg_pm_turnoff                     ( pme_turnoff ),
    .app_ready_entr_l23                 ( app_ready_entr_l23 )
);

endmodule // BMD_AXIST_EP
