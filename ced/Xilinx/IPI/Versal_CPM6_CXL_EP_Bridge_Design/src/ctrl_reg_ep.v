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
`timescale 1ps/1ps

module ctrl_reg_ep
#(
  // Number of Protocol Agent instances physically present in this build
  // (legal values 1/2/4, matching cxl_mem_wrapper's own C_NUM_PA). Drives
  // the width of the raw per-PA counter-source ports below and how many
  // PA slots the counting logic actually processes; the AXI-Lite register
  // map (pa_cxl_cntrs/Per-PA CPI Counters) always exposes exactly 4 PA
  // slots regardless, with inactive slots (PA index >= NUM_PA) permanently
  // reading 0 - the register map itself does not shrink.
  parameter integer NUM_PA = 4
)
(
  // ---------------------------------------------------------------------
  // CXL memory-range outputs, to cxl_mem_wrapper
  // ---------------------------------------------------------------------
  output reg  [63:0] cxl_mem_base0,
  // cxl_mem_base1 (second HDM range base) is currently unused - this design
  // only supports a single combined HDM range, broadcast to all 4 PAs via
  // cxl_mem_base0 (see the cxl_mem_base0/cxl_mem_base1 always block below).
  // Reserved for future use if/when a second HDM range is enabled;
  // uncomment this port together with every other cxl_mem_base1/
  // ep_base1_*/EP_BASE_1_* reference in this file to re-enable.
  // output reg  [63:0] cxl_mem_base1,

  // ---------------------------------------------------------------------
  // AXI4-Lite slave interface (register access)
  // ---------------------------------------------------------------------
  input  [31:0]      s_axil_araddr,
  input  [2:0]        s_axil_arprot,
  output              s_axil_arready,
  input               s_axil_arvalid,
  input  [31:0]       s_axil_awaddr,
  input  [2:0]        s_axil_awprot,
  output              s_axil_awready,
  input               s_axil_awvalid,
  input               s_axil_bready,
  output [1:0]        s_axil_bresp,
  output              s_axil_bvalid,
  output [31:0]       s_axil_rdata,
  input               s_axil_rready,
  output [1:0]        s_axil_rresp,
  output              s_axil_rvalid,
  input  [31:0]       s_axil_wdata,
  output              s_axil_wready,
  input  [3:0]        s_axil_wstrb,
  input               s_axil_wvalid,
  input               s_axil_aclk,
  input               s_axil_aresetn,

  // ---------------------------------------------------------------------
  // CXL power-management interface
  // ---------------------------------------------------------------------
  input  [32:0]       cxl_pm_out,
  output [33:0]       cxl_pm_in,
  output              irq_out,

  // ---------------------------------------------------------------------
  // Debug / status inputs
  // ---------------------------------------------------------------------
  // Packed CXL controller status bits, built combinationally in the BD by
  // ep_status_concat_0 (an ilconcat) directly from ps_wizard_0's
  // cxl{0,1}_status_* pins - registered once here (see the always block
  // below: `ep_ctrl_sts <= ep_status;`) into EP_CTRL_STS @ 0x400, so a
  // read of EP_CTRL_STS lags the live hardware status by 1 clock (both
  // this register and ep_status_concat_0's source pins share the same
  // pl0_ref_clk domain - see design_1_bd.tcl - so no CDC synchronizer is
  // needed). Bit layout (previously documented in the now-retired
  // src/ep_status_reg.v, which this replaced):
  //   [0]      link_up
  //   [1]      io_en
  //   [2]      mem_en
  //   [3]      cache_en
  //   [5:4]    flit_mode[1:0]
  //   [6]      bi_enable
  //   [7]      emd_enable
  //   [8]      disable_caching
  //   [9]      mdh_disable
  //   [10]     cxl_reset
  //   [11]     initiate_cxl_rst
  //   [12]     initiate_cache_wr_invld
  //   [13]     reserved (was mld_hot_rst_active - ps_wizard will not
  //            expose this pin in a future release, dropped here first)
  //   [14]     dev_rst_mem_clr_enable
  //   [15]     reserved
  //   [19:16]  vlsm_mc_state[3:0]  - nibble-aligned, reads as a single hex digit
  //   [23:20]  reserved
  //   [31:24]  error[7:0]          - byte-aligned in the top byte
  input  [31:0]       ep_status,
  input  [1:0]        num_pa,

  // Raw per-PA counter source, one 16-bit slice per PA (PA_i occupies
  // bits [i*16 +: 16]): this is each PA's own cxl_mem_wrapper.v
  // cxl_debug_bus output, brought out through the PA_N hierarchy and
  // concatenated across all instantiated PAs in the BD (same
  // pl0_ref_clk domain as s_axil_aclk — no CDC needed). Per-PA bit
  // layout (matches cxl_mem_wrapper.v's own cxl_debug_bus comment):
  //   [i*16+0] a2f_req_is_valid   [i*16+1] a2f_data_is_valid
  //   [i*16+2] a2f_req_block      [i*16+3] a2f_data_block
  //   [i*16+4] f2a_rsp_is_valid   [i*16+5] f2a_data_is_valid
  //   [i*16+6] f2a_rsp_block      [i*16+7] f2a_data_block
  //   [i*16+8] awvalid  [i*16+9] awready  [i*16+10] arvalid [i*16+11] arready
  //   [i*16+12] bvalid  [i*16+13] bready  [i*16+14] rvalid  [i*16+15] rready
  // Only NUM_PA of the possible 4 slices carry a real PA; unused slices
  // (index >= NUM_PA) are simply never read by the counting logic below.
  // Populates pa_cxl_cntrs (20 x 32-bit: PA0-3 AW/AR/B/R + TOT_AW/AR/B/R)
  // and ep_cpa_debug (EP-level AW/B/AR/R totals - the same TOT_* values)
  // and the Per-PA CPI Counters table (REQ/RWD/RSP/DAT x4 PA), all
  // computed internally now - see "Per-PA + EP counters" below.
  input  [NUM_PA*16-1:0] pa_dbg_cxl_bus,

  // cxl1_status_dev_mem_en from CPM6 — now registered directly in cxl_mem_wrapper
  // (see cxl_mem_wrapper.v); ctrl_reg_ep no longer drives the PA enable pins.
  input               cxl1_status_dev_mem_en
);

  // =======================================================================
  // Internal signals
  // =======================================================================

  // ---- AXI4-Lite protocol state ----
  wire                slv_reg_rden;
  wire                slv_reg_wren;
  integer             byte_index;
  reg                 aw_en;

  // One-cycle counter clear — write any value to CNT_CLR (0x550) to zero all
  // counters. Not exposed as a module output port (unconnected in the BD -
  // this design consumes it only internally, in the same reset condition as
  // the counter registers below).
  reg                 cntrs_clr;

  reg  [32-1:0]       axi_awaddr;
  reg                 axi_awready;
  reg                 axi_wready;
  reg  [1:0]          axi_bresp;
  reg                 axi_bvalid;
  reg  [32-1:0]       axi_araddr;
  reg                 axi_arready;
  reg  [32-1:0]       axi_rdata;
  reg  [1:0]          axi_rresp;
  reg                 axi_rvalid;

  // ---- Register file storage ----
  reg  [63:0]         scratchpad_reg;
  reg  [31:0]         ep_ctrl_sts;
  reg  [31:0]         ep_base0_lo;
  reg  [31:0]         ep_base0_hi;
  // reg  [31:0]         ep_base1_lo;  // see cxl_mem_base1 note near the port list above
  // reg  [31:0]         ep_base1_hi;

  // ---- CXL power-management state ----
  reg  [32:0]         cxl_pm_out_reg;
  reg  [32:0]         cxl_pm_out_reg_del;
  reg  [33:0]         cxl_pm_in_reg;
  wire                auto_respond;
  reg                 gpf_phase1;
  reg                 gpf_phase2;
  reg                 powerfail_imminent;
  reg                 cache_flush;
  reg                 cache_flush_err_in;
  reg                 resetprep_rcvd;
  reg  [15:0]         resetprep_resettype;
  reg                 rcvd_pmrsp;
  reg                 rcvd_pmgo;
  reg                 cxl_pm_in_req_ack;
  reg                 send_pmreq;
  reg                 gpf_p1_rsp;
  reg                 gpf_p2_rsp;
  reg                 cache_flush_err_out;
  reg                 resetprep_rsp;
  reg                 gen_err_vdm;
  reg  [3:0]          fw_intr_vec;
  reg                 L1_entry;

  // ---- Interrupt state ----
  reg  [31:0]         interrupt_mask_reg;
  reg  [31:0]         interrupt_en_reg;
  reg  [31:0]         interrupt_status_reg;
  reg  [31:0]         interrupt_status_clr;
  reg                 irq_out_reg;
  reg  [31:0]         fw_inter_vec_reg;
  reg  [31:0]         ltr_value_reg;

  // =======================================================================
  // Per-PA + EP AXI/CPI counters
  // =======================================================================
  // Raw per-PA source, registered once (1-clock delay) before use for
  // counting - see pa_dbg_cxl_bus port comment above for the per-PA bit
  // layout. Slices at index >= NUM_PA are simply never read below (no PA
  // physically present there).
  reg [NUM_PA*16-1:0] pa_dbg_cxl_bus_q;
  always @(posedge s_axil_aclk) begin
    pa_dbg_cxl_bus_q <= pa_dbg_cxl_bus;
  end

  // Per-PA counter storage - always sized for 4 PA slots (matching the
  // static AXI-Lite register map), regardless of NUM_PA. Slots at index
  // >= NUM_PA are held at 0 by the generate block below.
  reg [31:0] cnt_pa_aw  [0:3];  // AW handshake (write-start)
  reg [31:0] cnt_pa_ar  [0:3];  // AR handshake (read-start)
  reg [31:0] cnt_pa_b   [0:3];  // B handshake  (write-compl)
  reg [31:0] cnt_pa_r   [0:3];  // R handshake  (read-compl)
  // Per-PA CPI counters - valid-only (NOT qualified by block, per explicit
  // instruction). CPM6/ps_wizard_0 correctly drives all four of these CPI
  // valids (a2f_req/a2f_dat/f2a_rsp/f2a_dat) for real transaction traffic -
  // confirmed by a passing simulation - so all four are expected to
  // increment under real traffic, not just f2a_rsp/f2a_dat.
  reg [31:0] cnt_pa_req [0:3];  // a2f_req_is_valid
  reg [31:0] cnt_pa_rwd [0:3];  // a2f_data_is_valid
  reg [31:0] cnt_pa_rsp [0:3];  // f2a_rsp_is_valid
  reg [31:0] cnt_pa_dat [0:3];  // f2a_data_is_valid

  reg [31:0] cnt_tot_aw, cnt_tot_ar, cnt_tot_b, cnt_tot_r;
  // EP-level CPI totals (sum of the per-PA CPI counts above across all 4
  // PAs) - replaces the former cxl_debug_bus-fed cnt_m2s_req/cnt_m2s_dat/
  // cnt_s2m_rsp/cnt_s2m_dat, which read a ctrl_reg_ep_0/cxl_debug_bus port
  // that was never wired to anything in the BD (confirmed unconnected /
  // tied to 0 in both ctrl0 and ctrl1) and so always read
  // 0. Computed the same way as cnt_tot_aw/ar/b/r above: summed directly
  // from the per-PA pulses, not from the (now-removed) per-PA counters.
  reg [31:0] cnt_tot_req, cnt_tot_rwd, cnt_tot_rsp, cnt_tot_dat;

  // Per-PA-slot qualified pulses this cycle (combinational; forced to 0
  // for any slot with index >= NUM_PA). AXI pulses require the real
  // handshake (valid && ready); CPI pulses are valid-only.
  wire pa_aw_pulse  [0:3];
  wire pa_ar_pulse  [0:3];
  wire pa_b_pulse   [0:3];
  wire pa_r_pulse   [0:3];
  wire pa_req_pulse [0:3];
  wire pa_rwd_pulse [0:3];
  wire pa_rsp_pulse [0:3];
  wire pa_dat_pulse [0:3];

  genvar gi;
  generate
    for (gi = 0; gi < 4; gi = gi + 1) begin : g_pa_pulse
      if (gi < NUM_PA) begin : g_active
        assign pa_aw_pulse[gi]  = pa_dbg_cxl_bus_q[gi*16+8]  & pa_dbg_cxl_bus_q[gi*16+9];
        assign pa_ar_pulse[gi]  = pa_dbg_cxl_bus_q[gi*16+10] & pa_dbg_cxl_bus_q[gi*16+11];
        assign pa_b_pulse[gi]   = pa_dbg_cxl_bus_q[gi*16+12] & pa_dbg_cxl_bus_q[gi*16+13];
        assign pa_r_pulse[gi]   = pa_dbg_cxl_bus_q[gi*16+14] & pa_dbg_cxl_bus_q[gi*16+15];
        assign pa_req_pulse[gi] = pa_dbg_cxl_bus_q[gi*16+0];
        assign pa_rwd_pulse[gi] = pa_dbg_cxl_bus_q[gi*16+1];
        assign pa_rsp_pulse[gi] = pa_dbg_cxl_bus_q[gi*16+4];
        assign pa_dat_pulse[gi] = pa_dbg_cxl_bus_q[gi*16+5];
      end else begin : g_inactive
        assign pa_aw_pulse[gi]  = 1'b0;
        assign pa_ar_pulse[gi]  = 1'b0;
        assign pa_b_pulse[gi]   = 1'b0;
        assign pa_r_pulse[gi]   = 1'b0;
        assign pa_req_pulse[gi] = 1'b0;
        assign pa_rwd_pulse[gi] = 1'b0;
        assign pa_rsp_pulse[gi] = 1'b0;
        assign pa_dat_pulse[gi] = 1'b0;
      end
    end
  endgenerate

  integer pi;
  always @(posedge s_axil_aclk) begin
    if (!s_axil_aresetn || cntrs_clr) begin
      for (pi = 0; pi < 4; pi = pi + 1) begin
        cnt_pa_aw[pi]  <= 32'd0;
        cnt_pa_ar[pi]  <= 32'd0;
        cnt_pa_b[pi]   <= 32'd0;
        cnt_pa_r[pi]   <= 32'd0;
        cnt_pa_req[pi] <= 32'd0;
        cnt_pa_rwd[pi] <= 32'd0;
        cnt_pa_rsp[pi] <= 32'd0;
        cnt_pa_dat[pi] <= 32'd0;
      end
      cnt_tot_aw  <= 32'd0;
      cnt_tot_ar  <= 32'd0;
      cnt_tot_b   <= 32'd0;
      cnt_tot_r   <= 32'd0;
      cnt_tot_req <= 32'd0;
      cnt_tot_rwd <= 32'd0;
      cnt_tot_rsp <= 32'd0;
      cnt_tot_dat <= 32'd0;
    end else begin
      for (pi = 0; pi < 4; pi = pi + 1) begin
        if (pa_aw_pulse[pi])  cnt_pa_aw[pi]  <= cnt_pa_aw[pi]  + 1'b1;
        if (pa_ar_pulse[pi])  cnt_pa_ar[pi]  <= cnt_pa_ar[pi]  + 1'b1;
        if (pa_b_pulse[pi])   cnt_pa_b[pi]   <= cnt_pa_b[pi]   + 1'b1;
        if (pa_r_pulse[pi])   cnt_pa_r[pi]   <= cnt_pa_r[pi]   + 1'b1;
        if (pa_req_pulse[pi]) cnt_pa_req[pi] <= cnt_pa_req[pi] + 1'b1;
        if (pa_rwd_pulse[pi]) cnt_pa_rwd[pi] <= cnt_pa_rwd[pi] + 1'b1;
        if (pa_rsp_pulse[pi]) cnt_pa_rsp[pi] <= cnt_pa_rsp[pi] + 1'b1;
        if (pa_dat_pulse[pi]) cnt_pa_dat[pi] <= cnt_pa_dat[pi] + 1'b1;
      end
      // EP-level totals: sum the qualified pulses across all 4 slots in
      // the same cycle (inactive slots contribute 0), so simultaneous
      // handshakes on multiple PAs are all counted, not just the first.
      cnt_tot_aw  <= cnt_tot_aw  + (pa_aw_pulse[0] +pa_aw_pulse[1] +pa_aw_pulse[2] +pa_aw_pulse[3]);
      cnt_tot_ar  <= cnt_tot_ar  + (pa_ar_pulse[0] +pa_ar_pulse[1] +pa_ar_pulse[2] +pa_ar_pulse[3]);
      cnt_tot_b   <= cnt_tot_b   + (pa_b_pulse[0]  +pa_b_pulse[1]  +pa_b_pulse[2]  +pa_b_pulse[3]);
      cnt_tot_r   <= cnt_tot_r   + (pa_r_pulse[0]  +pa_r_pulse[1]  +pa_r_pulse[2]  +pa_r_pulse[3]);
      cnt_tot_req <= cnt_tot_req + (pa_req_pulse[0]+pa_req_pulse[1]+pa_req_pulse[2]+pa_req_pulse[3]);
      cnt_tot_rwd <= cnt_tot_rwd + (pa_rwd_pulse[0]+pa_rwd_pulse[1]+pa_rwd_pulse[2]+pa_rwd_pulse[3]);
      cnt_tot_rsp <= cnt_tot_rsp + (pa_rsp_pulse[0]+pa_rsp_pulse[1]+pa_rsp_pulse[2]+pa_rsp_pulse[3]);
      cnt_tot_dat <= cnt_tot_dat + (pa_dat_pulse[0]+pa_dat_pulse[1]+pa_dat_pulse[2]+pa_dat_pulse[3]);
    end
  end

  // ---- EP AXI counters (EP-level totals - identical values to TOT_* below) ----
  wire [31:0] ep_axi_wr_start_cnt = cnt_tot_aw;
  wire [31:0] ep_axi_wr_compl_cnt = cnt_tot_b;
  wire [31:0] ep_axi_rd_start_cnt = cnt_tot_ar;
  wire [31:0] ep_axi_rd_compl_cnt = cnt_tot_r;

  // ---- PA counter bus breakout (register-file-facing names, unchanged) ----
  wire [31:0] pa0_aw = cnt_pa_aw[0];  wire [31:0] pa0_ar = cnt_pa_ar[0];
  wire [31:0] pa0_b  = cnt_pa_b[0];   wire [31:0] pa0_r  = cnt_pa_r[0];
  wire [31:0] pa1_aw = cnt_pa_aw[1];  wire [31:0] pa1_ar = cnt_pa_ar[1];
  wire [31:0] pa1_b  = cnt_pa_b[1];   wire [31:0] pa1_r  = cnt_pa_r[1];
  wire [31:0] pa2_aw = cnt_pa_aw[2];  wire [31:0] pa2_ar = cnt_pa_ar[2];
  wire [31:0] pa2_b  = cnt_pa_b[2];   wire [31:0] pa2_r  = cnt_pa_r[2];
  wire [31:0] pa3_aw = cnt_pa_aw[3];  wire [31:0] pa3_ar = cnt_pa_ar[3];
  wire [31:0] pa3_b  = cnt_pa_b[3];   wire [31:0] pa3_r  = cnt_pa_r[3];
  wire [31:0] tot_aw = cnt_tot_aw;    wire [31:0] tot_ar = cnt_tot_ar;
  wire [31:0] tot_b  = cnt_tot_b;     wire [31:0] tot_r  = cnt_tot_r;

  // ---- EP-level CPI totals (register-file-facing names) ----
  wire [31:0] tot_req = cnt_tot_req;  wire [31:0] tot_rwd = cnt_tot_rwd;
  wire [31:0] tot_rsp = cnt_tot_rsp;  wire [31:0] tot_dat = cnt_tot_dat;

  // ---- Per-PA CPI counters (register-file-facing names, new) ----
  wire [31:0] pa0_req = cnt_pa_req[0]; wire [31:0] pa0_rwd = cnt_pa_rwd[0];
  wire [31:0] pa0_rsp = cnt_pa_rsp[0]; wire [31:0] pa0_dat = cnt_pa_dat[0];
  wire [31:0] pa1_req = cnt_pa_req[1]; wire [31:0] pa1_rwd = cnt_pa_rwd[1];
  wire [31:0] pa1_rsp = cnt_pa_rsp[1]; wire [31:0] pa1_dat = cnt_pa_dat[1];
  wire [31:0] pa2_req = cnt_pa_req[2]; wire [31:0] pa2_rwd = cnt_pa_rwd[2];
  wire [31:0] pa2_rsp = cnt_pa_rsp[2]; wire [31:0] pa2_dat = cnt_pa_dat[2];
  wire [31:0] pa3_req = cnt_pa_req[3]; wire [31:0] pa3_rwd = cnt_pa_rwd[3];
  wire [31:0] pa3_rsp = cnt_pa_rsp[3]; wire [31:0] pa3_dat = cnt_pa_dat[3];

  // =======================================================================
  // Register offsets
  // =======================================================================
  localparam SCRATCH_REG_LO   = 12'h000;
  localparam SCRATCH_REG_HI   = 12'h004;
  localparam INTERRUPT_MASK   = 12'h100;
  localparam INTERRUPT_EN     = 12'h104;
  localparam INTERRUPT_STATUS = 12'h108;
  localparam FW_INTR_VEC      = 12'h10C;
  localparam LTR_VALUE        = 12'h110;
  localparam EP_CTRL_STS      = 12'h400;
  localparam EP_BASE_0_LO     = 12'h404;
  localparam EP_BASE_0_HI     = 12'h408;
  // localparam EP_BASE_1_LO     = 12'h40C;  // see cxl_mem_base1 note near the port list above
  // localparam EP_BASE_1_HI     = 12'h410;

  localparam EP_AXI_WR_START  = 12'h424;
  localparam EP_AXI_WR_CP     = 12'h428;
  localparam EP_AXI_RD_START  = 12'h42C;
  localparam EP_AXI_RD_CP     = 12'h430;

  // EP-level CPI totals (sum of the per-PA CPI counts across all 4 PAs -
  // see cnt_tot_req/rwd/rsp/dat above). These addresses previously read a
  // cxl_debug_bus port that was never wired to anything in the BD and so
  // always returned 0; repointed to the verified-correct per-PA-derived
  // totals instead, same register map, same addresses.
  localparam CPI_M2S_REQ_CNT  = 12'h448;
  localparam CPI_M2S_DAT_CNT  = 12'h44C;
  localparam CPI_S2M_RSP_CNT  = 12'h450;
  localparam CPI_S2M_DAT_CNT  = 12'h454;

  // Per-PA CPI counters (RO, same pl0_ref_clk domain). RWD=a2f_data_is_valid,
  // REQ=a2f_req_is_valid, RSP=f2a_rsp_is_valid, DAT=f2a_data_is_valid.
  localparam PA0_RWD_CNT      = 12'h460;
  localparam PA0_REQ_CNT      = 12'h464;
  localparam PA0_RSP_CNT      = 12'h468;
  localparam PA0_DAT_CNT      = 12'h46C;
  localparam PA1_RWD_CNT      = 12'h470;
  localparam PA1_REQ_CNT      = 12'h474;
  localparam PA1_RSP_CNT      = 12'h478;
  localparam PA1_DAT_CNT      = 12'h47C;
  localparam PA2_RWD_CNT      = 12'h480;
  localparam PA2_REQ_CNT      = 12'h484;
  localparam PA2_RSP_CNT      = 12'h488;
  localparam PA2_DAT_CNT      = 12'h48C;
  localparam PA3_RWD_CNT      = 12'h490;
  localparam PA3_REQ_CNT      = 12'h494;
  localparam PA3_RSP_CNT      = 12'h498;
  localparam PA3_DAT_CNT      = 12'h49C;

  // AXI transaction counters from debug_cxl_0 (RO, same pl0_ref_clk domain)
  // Per-PA: aw=write-start, ar=read-start, b=write-compl, r=read-compl
  localparam PA0_AW_CNT       = 12'h500;
  localparam PA0_AR_CNT       = 12'h504;
  localparam PA0_B_CNT        = 12'h508;
  localparam PA0_R_CNT        = 12'h50C;
  localparam PA1_AW_CNT       = 12'h510;
  localparam PA1_AR_CNT       = 12'h514;
  localparam PA1_B_CNT        = 12'h518;
  localparam PA1_R_CNT        = 12'h51C;
  localparam PA2_AW_CNT       = 12'h520;
  localparam PA2_AR_CNT       = 12'h524;
  localparam PA2_B_CNT        = 12'h528;
  localparam PA2_R_CNT        = 12'h52C;
  localparam PA3_AW_CNT       = 12'h530;
  localparam PA3_AR_CNT       = 12'h534;
  localparam PA3_B_CNT        = 12'h538;
  localparam PA3_R_CNT        = 12'h53C;
  localparam TOT_AW_CNT       = 12'h540;
  localparam TOT_AR_CNT       = 12'h544;
  localparam TOT_B_CNT        = 12'h548;
  localparam TOT_R_CNT        = 12'h54C;
  localparam CNT_CLR          = 12'h550;

  localparam ADDR_MASK        = 12'hfff;
  localparam ADDR_MASK_WIDTH  = $clog2(ADDR_MASK);

  // HDM decode register offsets (lower 16 bits)
  localparam [15:0] HDM_BASE_LOW_OFFSET  = 16'h1210; // bits [31:28] of low 32 bits
  localparam [15:0] HDM_BASE_HIGH_OFFSET = 16'h1214; // full upper 32 bits

  // =======================================================================
  // Combinational output assigns
  // =======================================================================
  assign s_axil_awready = axi_awready;
  assign s_axil_wready  = axi_wready;
  assign s_axil_arready = axi_arready;
  assign s_axil_bresp   = axi_bresp;
  assign s_axil_bvalid  = axi_bvalid;
  assign s_axil_rdata   = axi_rdata;
  assign s_axil_rresp   = axi_rresp;
  assign s_axil_rvalid  = axi_rvalid;

  assign auto_respond = interrupt_en_reg[31];
  assign irq_out       = irq_out_reg;
  assign cxl_pm_in     = cxl_pm_in_reg;

  // =======================================================================
  // AXI4-Lite protocol state machine
  // =======================================================================

  // Implement axi_awready generation for PLMB
  always @(posedge s_axil_aclk) begin
    if (s_axil_aresetn == 1'b0) begin
      axi_awready <= 1'b0;
      aw_en       <= 1'b1;
    end else begin
      if (~axi_awready && s_axil_awvalid && s_axil_wvalid && aw_en) begin
        axi_awready <= 1'b1;
        aw_en       <= 1'b0;
      end else if (s_axil_bready && axi_bvalid) begin
        aw_en       <= 1'b1;
        axi_awready <= 1'b0;
      end else begin
        axi_awready <= 1'b0;
      end
    end
  end

  // Implement axi_wready generation for PLMB
  always @(posedge s_axil_aclk) begin
    if (s_axil_aresetn == 1'b0) begin
      axi_wready <= 1'b0;
    end else begin
      if (~axi_wready && s_axil_wvalid && s_axil_awvalid && aw_en) begin
        axi_wready <= 1'b1;
      end else begin
        axi_wready <= 1'b0;
      end
    end
  end

  // Implement write response logic generation for PLMB
  always @(posedge s_axil_aclk) begin
    if (s_axil_aresetn == 1'b0) begin
      axi_bvalid <= 0;
      axi_bresp  <= 2'b0;
    end else begin
      if (axi_awready && s_axil_awvalid && ~axi_bvalid && axi_wready && s_axil_wvalid) begin
        // indicates a valid write response is available
        axi_bvalid <= 1'b1;
        axi_bresp  <= 2'b0; // 'OKAY' response
      end                   // work error responses in future
      else begin
        if (s_axil_bready && axi_bvalid)
          // check if bready is asserted while bvalid is high
          // (there is a possibility that bready is always asserted high)
          begin
            axi_bvalid <= 1'b0;
          end
      end
    end
  end

  // Implement axi_awaddr latching for PLMB
  always @(posedge s_axil_aclk) begin
    if (s_axil_aresetn == 1'b0) begin
      axi_awaddr <= 0;
    end else begin
      if (~axi_awready && s_axil_awvalid && s_axil_wvalid && aw_en) begin
        // Write address latching
        axi_awaddr <= s_axil_awaddr;
      end
    end
  end

  // Implement axi_arready generation for PLMB
  always @(posedge s_axil_aclk) begin
    if (s_axil_aresetn == 1'b0) begin
      axi_arready <= 1'b0;
      axi_araddr  <= 32'b0;
    end else begin
      if (~axi_arready && s_axil_arvalid) begin
        // indicates that the slave has accepted the valid read address
        axi_arready <= 1'b1;
        // Read address latching
        axi_araddr  <= s_axil_araddr;
      end else begin
        axi_arready <= 1'b0;
      end
    end
  end

  // Implement axi_arvalid generation for PLMB
  always @(posedge s_axil_aclk) begin
    if (s_axil_aresetn == 1'b0) begin
      axi_rvalid <= 0;
      axi_rresp  <= 0;
    end else begin
      if (axi_arready && s_axil_arvalid && ~axi_rvalid) begin
        // Valid read data is available at the read data bus
        axi_rvalid <= 1'b1;
        axi_rresp  <= 2'b0; // 'OKAY' response
      end else if (axi_rvalid && s_axil_rready) begin
        // Read data is accepted by the master
        axi_rvalid <= 1'b0;
      end
    end
  end

  // Implement memory mapped register select and write logic generation of PLMB
  assign slv_reg_wren = axi_wready && s_axil_wvalid &&
                        axi_awready && s_axil_awvalid;
  // Implement memory mapped register select and read logic generation
  assign slv_reg_rden = axi_arready & s_axil_arvalid & ~axi_rvalid;

  // =======================================================================
  // Register file: reset, CPI counters, PM pulse generation, interrupts,
  // and AXI4-Lite read/write address decode
  // =======================================================================
  always @(posedge s_axil_aclk) begin
    if (!s_axil_aresetn) begin
      scratchpad_reg       <= 64'hAABBCCDD11223344;
      ep_base0_lo          <= 32'b0;
      ep_base0_hi          <= 32'b0;
      // ep_base1_lo          <= 32'b0;  // see cxl_mem_base1 note near the port list above
      // ep_base1_hi          <= 32'b0;
      ep_ctrl_sts          <= 'b0;
      axi_rdata            <= 32'b0;
      cxl_pm_out_reg       <= 'b0;
      cxl_pm_out_reg_del   <= 'b0;
      cxl_pm_in_reg        <= 'b0;
      cntrs_clr            <= 1'b0;
      interrupt_mask_reg   <= 32'h03F;
      interrupt_en_reg     <= 32'h80000000;
      interrupt_status_reg <= 'b0;
      interrupt_status_clr <= 'b0;
      irq_out_reg          <= 'b0;
      fw_inter_vec_reg     <= 'b0;
      ltr_value_reg        <= 'b0;
      gpf_phase1           <= 'b0;
      gpf_phase2           <= 'b0;
      powerfail_imminent   <= 'b0;
      cache_flush          <= 'b0;
      cache_flush_err_in   <= 'b0;
      resetprep_rcvd       <= 'b0;
      resetprep_resettype  <= 'b0;
      rcvd_pmrsp           <= 'b0;
      rcvd_pmgo            <= 'b0;
      cxl_pm_in_req_ack    <= 'b0;
      send_pmreq           <= 'b0;
      gpf_p1_rsp           <= 'b0;
      gpf_p2_rsp           <= 'b0;
      cache_flush_err_out  <= 'b0;
      resetprep_rsp        <= 'b0;
      gen_err_vdm          <= 'b0;
      fw_intr_vec          <= 'b0;
      L1_entry             <= 'b0;
    end else begin
      cxl_pm_out_reg     <= cxl_pm_out;
      cxl_pm_out_reg_del <= cxl_pm_out_reg;
      cxl_pm_in_reg      <= 'b0;
      ep_ctrl_sts        <= ep_status;

      // ---- Generate a pulse for each PM incident ----
      gpf_phase1           <= ~cxl_pm_out_reg_del[0] & cxl_pm_out_reg[0];
      gpf_phase2           <= ~cxl_pm_out_reg_del[1] & cxl_pm_out_reg[1];
      powerfail_imminent   <= cxl_pm_out_reg[2];
      cache_flush          <= cxl_pm_out_reg[3];
      cache_flush_err_in   <= cxl_pm_out_reg[4];
      resetprep_rcvd       <= ~cxl_pm_out_reg_del[5] & cxl_pm_out_reg[5];
      resetprep_resettype  <= cxl_pm_out_reg[21:6];
      rcvd_pmrsp           <= ~cxl_pm_out_reg_del[22] & cxl_pm_out_reg[22];
      rcvd_pmgo            <= ~cxl_pm_out_reg_del[23] & cxl_pm_out_reg[23];
      cxl_pm_in_req_ack    <= ~cxl_pm_out_reg_del[24] & cxl_pm_out_reg[24];

      // ---- Interrupt-out aggregation ----
      if (  (~interrupt_mask_reg[0] & interrupt_en_reg[0] & interrupt_status_reg[0]) |
            (~interrupt_mask_reg[1] & interrupt_en_reg[1] & interrupt_status_reg[1]) |
            (~interrupt_mask_reg[2] & interrupt_en_reg[2] & interrupt_status_reg[2]) |
            (~interrupt_mask_reg[3] & interrupt_en_reg[3] & interrupt_status_reg[3]) |
            (~interrupt_mask_reg[4] & interrupt_en_reg[4] & interrupt_status_reg[4]) |
            (~interrupt_mask_reg[5] & interrupt_en_reg[5] & interrupt_status_reg[5])
         ) begin
        irq_out_reg <= 1'b1;
      end else begin
        irq_out_reg <= 1'b0;
      end

      // ---- cxl_pm_in response mux: auto-response vs firmware-controlled ----
      if (auto_respond == 1'b1) begin
        cxl_pm_in_reg <= {
                           24'b0          // 33:9
                          , 4'b0          // 8:5
                          , resetprep_rsp // 4
                          , 1'b0          // 3
                          , gpf_p2_rsp    // 2
                          , gpf_p1_rsp    // 1
                          , 1'b0          // 0
                          };
      end else begin
        if (send_pmreq) begin
          cxl_pm_in_reg <= {ltr_value_reg[31:0], send_pmreq};
          send_pmreq    <= 'b0;
        end else begin
          cxl_pm_in_reg <= {
                            21'b0                // 31:11
                            , L1_entry           // 10
                            , fw_intr_vec[3:0]    // 9:6
                            , gen_err_vdm         // 5
                            , resetprep_rsp       // 4
                            , cache_flush_err_out // 3
                            , gpf_p2_rsp          // 2
                            , gpf_p1_rsp          // 1
                            , send_pmreq          // 0
                            };
        end
      end

      // ---- PM incident -> response/interrupt-status handling ----
      if (auto_respond == 1'b1) begin
        gpf_p1_rsp          <= 'b0;
        gpf_p2_rsp          <= 'b0;
        cache_flush_err_out <= 'b0;
        resetprep_rsp       <= 'b0;
        if (gpf_phase1) begin
          gpf_p1_rsp          <= 1'b1;
          cache_flush_err_out <= 'b0;
        end
        if (gpf_phase2) begin
          gpf_p2_rsp <= 1'b1;
        end
        if (resetprep_rcvd) begin
          resetprep_rsp <= 1'b1;
        end
      end else begin
        // FW-controlled interrupt
        gpf_p1_rsp          <= 'b0;
        gpf_p2_rsp          <= 'b0;
        cache_flush_err_out <= 'b0;
        resetprep_rsp       <= 'b0;
        send_pmreq          <= 'b0;
        gen_err_vdm         <= 'b0;
        fw_intr_vec         <= 'b0;
        L1_entry            <= 'b0;

        if (gpf_phase1) begin
          interrupt_status_reg[0] <= 1'b1;
          interrupt_status_reg[8] <= powerfail_imminent;
          interrupt_status_reg[9] <= cache_flush;
        end else begin
          if ((interrupt_status_clr[0] == 1'b1) && (interrupt_status_reg[0] == 1'b1)) begin
            interrupt_status_reg[0]  <= 1'b0;
            interrupt_status_clr[0]  <= 1'b0;
            interrupt_status_clr[11] <= 1'b0;
            gpf_p1_rsp               <= 1'b1;
            cache_flush_err_out      <= interrupt_status_clr[11];
          end
        end

        if (gpf_phase2) begin
          interrupt_status_reg[1]  <= 1'b1;
          interrupt_status_reg[10] <= cache_flush_err_in;
        end else begin
          if ((interrupt_status_clr[1] == 1'b1) && (interrupt_status_reg[1] == 1'b1)) begin
            interrupt_status_reg[1]  <= 1'b0;
            interrupt_status_clr[1]  <= 1'b0;
            interrupt_status_clr[10] <= 1'b0;
            gpf_p2_rsp               <= 1'b1;
          end
        end

        if (resetprep_rcvd) begin
          interrupt_status_reg[2]     <= 1'b1;
          interrupt_status_reg[31:16] <= resetprep_resettype;
        end else begin
          if ((interrupt_status_clr[2] == 1'b1) && (interrupt_status_reg[2] == 1'b1)) begin
            interrupt_status_reg[2] <= 1'b0;
            interrupt_status_clr[2] <= 1'b0;
            resetprep_rsp           <= 1'b1;
          end
        end

        if (rcvd_pmrsp) begin
          interrupt_status_reg[3] <= 1'b1;
        end else begin
          if ((interrupt_status_clr[3] == 1'b1) && (interrupt_status_reg[3] == 1'b1)) begin
            interrupt_status_reg[3] <= 1'b0;
            interrupt_status_clr[3] <= 1'b0;
          end
        end

        if (rcvd_pmgo) begin
          interrupt_status_reg[4] <= 1'b1;
        end else begin
          if ((interrupt_status_clr[4] == 1'b1) && (interrupt_status_reg[4] == 1'b1)) begin
            interrupt_status_reg[4] <= 1'b0;
            interrupt_status_clr[4] <= 1'b0;
          end
        end

        if (cxl_pm_in_req_ack) begin
          interrupt_status_reg[5] <= 1'b1;
        end else begin
          if ((interrupt_status_clr[5] == 1'b1) && (interrupt_status_reg[5] == 1'b1)) begin
            interrupt_status_reg[5] <= 1'b0;
            interrupt_status_clr[5] <= 1'b0;
          end
        end

        if (interrupt_status_clr[6] == 1'b1) begin
          interrupt_status_reg[6] <= 1'b0;
          interrupt_status_clr[6] <= 1'b0;
          gen_err_vdm              <= 1'b1;
          fw_intr_vec               <= fw_inter_vec_reg[3:0];
        end

        if (interrupt_status_clr[7] == 1'b1) begin
          interrupt_status_reg[7] <= 1'b0;
          interrupt_status_clr[7] <= 1'b0;
          send_pmreq               <= 1'b1;
        end

        if (interrupt_status_clr[8] == 1'b1) begin
          interrupt_status_reg[8] <= 1'b0;
          interrupt_status_clr[8] <= 1'b0;
          L1_entry                 <= 1'b1;
        end
      end

      // ---- AXI4-Lite register write decode ----
      if (slv_reg_wren) begin
        case (axi_awaddr[ADDR_MASK_WIDTH-1:0])
          SCRATCH_REG_LO   : scratchpad_reg[31:0]  <= s_axil_wdata;
          SCRATCH_REG_HI   : scratchpad_reg[63:32] <= s_axil_wdata;
          EP_BASE_0_LO     : ep_base0_lo           <= s_axil_wdata;
          EP_BASE_0_HI     : ep_base0_hi           <= s_axil_wdata;
          // EP_BASE_1_LO     : ep_base1_lo           <= s_axil_wdata;  // see cxl_mem_base1 note near the port list above
          // EP_BASE_1_HI     : ep_base1_hi           <= s_axil_wdata;
          INTERRUPT_MASK   : interrupt_mask_reg    <= s_axil_wdata;
          INTERRUPT_EN     : interrupt_en_reg      <= s_axil_wdata;
          INTERRUPT_STATUS : interrupt_status_clr  <= s_axil_wdata;
          FW_INTR_VEC      : fw_inter_vec_reg      <= s_axil_wdata;
          LTR_VALUE        : ltr_value_reg         <= s_axil_wdata;
          default          : ;
        endcase
        cntrs_clr <= (axi_awaddr[ADDR_MASK_WIDTH-1:0] == CNT_CLR) ? 1'b1 : 1'b0;

      // ---- AXI4-Lite register read decode ----
      end else if (slv_reg_rden) begin
        cntrs_clr <= 1'b0;
        case (axi_araddr[ADDR_MASK_WIDTH-1:0])
          SCRATCH_REG_LO   : axi_rdata <= scratchpad_reg[31:0];
          SCRATCH_REG_HI   : axi_rdata <= scratchpad_reg[63:32];

          EP_CTRL_STS      : axi_rdata <= ep_ctrl_sts[31:0];
          EP_BASE_0_LO     : axi_rdata <= ep_base0_lo;
          EP_BASE_0_HI     : axi_rdata <= ep_base0_hi;
          // EP_BASE_1_LO     : axi_rdata <= ep_base1_lo;  // see cxl_mem_base1 note near the port list above
          // EP_BASE_1_HI     : axi_rdata <= ep_base1_hi;
          EP_AXI_WR_START  : axi_rdata <= ep_axi_wr_start_cnt;
          EP_AXI_WR_CP     : axi_rdata <= ep_axi_wr_compl_cnt;
          EP_AXI_RD_START  : axi_rdata <= ep_axi_rd_start_cnt;
          EP_AXI_RD_CP     : axi_rdata <= ep_axi_rd_compl_cnt;

          // EP-level CPI totals (sum of per-PA CPI counts, see above)
          CPI_M2S_REQ_CNT  : axi_rdata <= tot_req;
          CPI_M2S_DAT_CNT  : axi_rdata <= tot_rwd;
          CPI_S2M_RSP_CNT  : axi_rdata <= tot_rsp;
          CPI_S2M_DAT_CNT  : axi_rdata <= tot_dat;

          // Per-PA CPI counters
          PA0_RWD_CNT      : axi_rdata <= pa0_rwd;
          PA0_REQ_CNT      : axi_rdata <= pa0_req;
          PA0_RSP_CNT      : axi_rdata <= pa0_rsp;
          PA0_DAT_CNT      : axi_rdata <= pa0_dat;
          PA1_RWD_CNT      : axi_rdata <= pa1_rwd;
          PA1_REQ_CNT      : axi_rdata <= pa1_req;
          PA1_RSP_CNT      : axi_rdata <= pa1_rsp;
          PA1_DAT_CNT      : axi_rdata <= pa1_dat;
          PA2_RWD_CNT      : axi_rdata <= pa2_rwd;
          PA2_REQ_CNT      : axi_rdata <= pa2_req;
          PA2_RSP_CNT      : axi_rdata <= pa2_rsp;
          PA2_DAT_CNT      : axi_rdata <= pa2_dat;
          PA3_RWD_CNT      : axi_rdata <= pa3_rwd;
          PA3_REQ_CNT      : axi_rdata <= pa3_req;
          PA3_RSP_CNT      : axi_rdata <= pa3_rsp;
          PA3_DAT_CNT      : axi_rdata <= pa3_dat;

          // AXI transaction counters from debug_cxl_0 (same clock — direct read)
          PA0_AW_CNT       : axi_rdata <= pa0_aw;
          PA0_AR_CNT       : axi_rdata <= pa0_ar;
          PA0_B_CNT        : axi_rdata <= pa0_b;
          PA0_R_CNT        : axi_rdata <= pa0_r;
          PA1_AW_CNT       : axi_rdata <= pa1_aw;
          PA1_AR_CNT       : axi_rdata <= pa1_ar;
          PA1_B_CNT        : axi_rdata <= pa1_b;
          PA1_R_CNT        : axi_rdata <= pa1_r;
          PA2_AW_CNT       : axi_rdata <= pa2_aw;
          PA2_AR_CNT       : axi_rdata <= pa2_ar;
          PA2_B_CNT        : axi_rdata <= pa2_b;
          PA2_R_CNT        : axi_rdata <= pa2_r;
          PA3_AW_CNT       : axi_rdata <= pa3_aw;
          PA3_AR_CNT       : axi_rdata <= pa3_ar;
          PA3_B_CNT        : axi_rdata <= pa3_b;
          PA3_R_CNT        : axi_rdata <= pa3_r;
          TOT_AW_CNT       : axi_rdata <= tot_aw;
          TOT_AR_CNT       : axi_rdata <= tot_ar;
          TOT_B_CNT        : axi_rdata <= tot_b;
          TOT_R_CNT        : axi_rdata <= tot_r;

          INTERRUPT_MASK   : axi_rdata <= interrupt_mask_reg;
          INTERRUPT_EN     : axi_rdata <= interrupt_en_reg;
          INTERRUPT_STATUS : axi_rdata <= interrupt_status_reg;
          FW_INTR_VEC      : axi_rdata <= fw_inter_vec_reg;
          LTR_VALUE        : axi_rdata <= ltr_value_reg;
          default          : axi_rdata <= 32'd0;
        endcase
      end else begin
        cntrs_clr <= 1'b0;
      end
    end
  end

  // =======================================================================
  // cxl_mem_base0 / cxl_mem_base1: registered EP_BASE_* -> cxl_mem_wrapper
  // =======================================================================
  wire [63:0] ep_base0_full = {ep_base0_hi, ep_base0_lo};
  // wire [63:0] ep_base1_full = {ep_base1_hi, ep_base1_lo};  // see cxl_mem_base1 note near the port list above

  always @(posedge s_axil_aclk) begin
    if (!s_axil_aresetn) begin
      cxl_mem_base0 <= 64'h0;
      // cxl_mem_base1 <= 64'h0;
    end else begin
      // cxl_mem_wrapper uses cxl_mem0_base as a range-check filter against the
      // 52-bit CXL byte address (zero-padded to 64-bit). No shift needed —
      // the programmed value matches the CPI address format directly.
      cxl_mem_base0 <= ep_base0_full;
      // cxl_mem_base1 <= ep_base1_full;

      // NOTE: num_pa-controlled PA-interleave shift — retained for future use.
      // The cxl_mem_wrapper receives the full 52-bit CXL byte address and uses
      // cxl_mem0_base only for range-checking, not address subtraction.
      // If a shift is needed in future (e.g. for a different IP), enable below:
      // case (num_pa)
      //     2'b11: begin  // 4 PAs, shift 2
      //         cxl_mem_base0 <= {2'b00, ep_base0_full[63:8], ep_base0_full[5:0]};
      //         cxl_mem_base1 <= {2'b00, ep_base1_full[63:8], ep_base1_full[5:0]};
      //     end
      //     2'b10: begin  // 2 PAs, shift 1
      //         cxl_mem_base0 <= {1'b0, ep_base0_full[63:7], ep_base0_full[5:0]};
      //         cxl_mem_base1 <= {1'b0, ep_base1_full[63:7], ep_base1_full[5:0]};
      //     end
      //     default: begin  // 1 PA, no shift
      //         cxl_mem_base0 <= ep_base0_full;
      //         cxl_mem_base1 <= ep_base1_full;
      //     end
      // endcase
    end
  end

  // =======================================================================
  // Register bit details for software
  // =======================================================================
  // +------------------------+-------------------------------------------------+
  // |  Register              | Bit description                                 |
  // +------------------------+-------------------------------------------------+
  // | INTERRUPT_MASK [31:0]  | [31:6]unused,cxl_pm_in_req_ack[5],rcvd_pmgo[4], |
  // | (RW) 1= EN default0    | rcvd_pmrsp[3],resetprep_rcvd[2],gpf_phase2[1],  |
  // |                        | gpf_phase1[0]                                   |
  // +------------------------+-------------------------------------------------+
  // | INTERRUPT_EN [31:0]    | auto_respond[31],[30:6]rsvd,cxl_pm_in_req_ack[5]|
  // | (RW)                   | rcvd_pmgo[4],rcvd_pmrsp[3],resetprep_rcvd[2],   |
  // |                        | gpf_phase2[1],gpf_phase1[0]                     |
  // +------------------------+-------------------------------------------------+
  // | INTERRUPT_STATUS [31:0]| [31:9]unused L1_entry[8],send_pmreq[7],         |
  // | (W1C)                  | gen_err_vdm[6],cxl_pm_in_req_ack[5],            |
  // |                        | rcvd_pmgo[4],rcvd_pmrsp[3],resetprep_rcvd[2],   |
  // |                        | gpf_phase2[1],gpf_phase1[0]                     |
  // +------------------------+-------------------------------------------------+
  // | FW_INTR_VEC    [31:0]  | [31:4]unused, fw_inter_vec[3:0]                 |
  // | (RW)                   |                                                 |
  // +------------------------+-------------------------------------------------+
  // | LTR_VALUE      [31:0]  | ltr_value[31:0]                                 |
  // | (RW)                   |                                                 |
  // +------------------------+-------------------------------------------------+

endmodule
