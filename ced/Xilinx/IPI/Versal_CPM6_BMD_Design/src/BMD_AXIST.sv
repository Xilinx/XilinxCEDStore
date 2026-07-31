
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
// File       : BMD_AXIST.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST.sv
//--
//-- Description: Instantiates BMD AXIST EP (BMD user design), config logic
//-- (handle config status interface), and extended configuration logic
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST
  import pcie_intf_pkg::*;
  import bmd_cfg_pkg::*;
  import ext_cfg_pkg::*;
  import cpm6_v1_0_pkg::*;
#(
    // Control FIFO depth and (consequently) credits given to core
    parameter int               FIFO_DEPTH      = 16,
    // Traffic generation options
    parameter logic             IF_VFUNC_ACTIVE     = 1'b0,
    parameter logic             IF_HDR_PROT_CHECK   = 1'b0,
    parameter logic             IF_CMP_PARITY_CHECK = 1'b0
) (
    input  logic                clk,
    input  logic                rst_n,

    output tx_intf              tx,
    input  rx_intf              rx,

    tx_credit_if.slave          tx_crd,
    rx_credit_if.master         rx_crd,

    input  pf_cfg_intf          pf_cfg,
    input  vf_cfg_intf          vf_cfg,

    input logic [5:0]           ltssm_state,
    input logic                 link_up,

    msix_user_intf.master       msix,
    pcie6_msix_pl_if.s          msi,

    axil_intf_defs_cpm6.slave   axil_tph,
    axil_intf_defs_cpm6.slave   axil_vsec,

    output logic                app_ready_entr_l23,

    output logic [31:0]         debug_bmd,
    input  logic [4:0]          debug_bmd_sel
);

// Config Status Info
pf_cfg_t [NUM_PFS-1:0]                          pf_cfg_regs;
vf_cfg_t [NUM_VFS-1:0]                          vf_cfg_regs;

// CFG EXT IO User Logic
logic [31:0]         status_reg_in;
logic [31:0]         control_reg_out;

assign status_reg_in = debug_bmd;

///////////////////////////////////////////////////////////////////////
//                      Extended Configuration
///////////////////////////////////////////////////////////////////////
BMD_AXIST_EXT_CFG #(
    .EXT_CONFIG_BASE_ADDRESS    ( VSEC_BASE_ADDRESS ),
    .EXT_CONFIG_CAP_LENGTH      ( VSEC_CAP_LENGTH ),
    .EXT_CONFIG_NEXT_CAP        ( VSEC_NEXT_CAP ),
    .PCIE_VSEC_ID               ( PCIE_VSEC_ID ),
    .PCIE_VSEC_REV              ( PCIE_VSEC_REV )
) BMD_AXIST_VSEC (
    .clk                        ( clk ),
    .rst_n                      ( rst_n ),

    .s_axi_awvalid              ( axil_vsec.awvalid ),
    .s_axi_awready              ( axil_vsec.awready ),
    .s_axi_awaddr               ( axil_vsec.awaddr ),
    .s_axi_awprot               ( axil_vsec.awprot ),
    .s_axi_awuser               ( axil_vsec.awuser ),

    .s_axi_wvalid               ( axil_vsec.wvalid ),
    .s_axi_wready               ( axil_vsec.wready ),
    .s_axi_wdata                ( axil_vsec.wdata ),
    .s_axi_wstrb                ( axil_vsec.wstrb ),
    .s_axi_wuser                ( axil_vsec.wuser ),

    .s_axi_bvalid               ( axil_vsec.bvalid ),
    .s_axi_bready               ( axil_vsec.bready ),
    .s_axi_bresp                ( axil_vsec.bresp ),
    .s_axi_buser                ( axil_vsec.buser ),

    .s_axi_arvalid              ( axil_vsec.arvalid ),
    .s_axi_arready              ( axil_vsec.arready ),
    .s_axi_araddr               ( axil_vsec.araddr ),
    .s_axi_arprot               ( axil_vsec.arprot ),
    .s_axi_aruser               ( axil_vsec.aruser ),

    .s_axi_rvalid               ( axil_vsec.rvalid ),
    .s_axi_rready               ( axil_vsec.rready ),
    .s_axi_rdata                ( axil_vsec.rdata ),
    .s_axi_rresp                ( axil_vsec.rresp ),
    .s_axi_ruser                ( axil_vsec.ruser ),

    .status_reg_in              ( status_reg_in ),
    .control_reg_out            ( control_reg_out )
);

BMD_AXIST_TPH_CFG #(
    .EXT_CONFIG_BASE_ADDRESS    ( TPH_BASE_ADDRESS ),
    .EXT_CONFIG_NEXT_CAP        ( TPH_NEXT_CAP ),
    .ST_TABLE_SIZE              ( ST_TABLE_SIZE ),
    .ST_TABLE_LOC               ( ST_TABLE_LOC ),
    .EXT_TPH_REQ_SUP            ( EXT_TPH_REQ_SUP ),
    .DEV_SPEC_MODE_SUP          ( DEV_SPEC_MODE_SUP ),
    .INT_VEC_MODE_SUP           ( INT_VEC_MODE_SUP ),
    .NO_ST_MODE_SUP             ( NO_ST_MODE_SUP )
) BMD_AXIST_TPH (
    .clk                        ( clk ),
    .rst_n                      ( rst_n ),

    // Write address channel
    .s_axi_awvalid              ( axil_tph.awvalid ),
    .s_axi_awready              ( axil_tph.awready ),
    .s_axi_awaddr               ( axil_tph.awaddr ),
    .s_axi_awprot               ( axil_tph.awprot ),
    .s_axi_awuser               ( axil_tph.awuser ),

    // Write data channel
    .s_axi_wvalid               ( axil_tph.wvalid ),
    .s_axi_wready               ( axil_tph.wready ),
    .s_axi_wdata                ( axil_tph.wdata ),
    .s_axi_wstrb                ( axil_tph.wstrb ),
    .s_axi_wuser                ( axil_tph.wuser ),

    // Write response channel
    .s_axi_bvalid               ( axil_tph.bvalid ),
    .s_axi_bready               ( axil_tph.bready ),
    .s_axi_bresp                ( axil_tph.bresp ),
    .s_axi_buser                ( axil_tph.buser ),

    // Read address channel
    .s_axi_arvalid              ( axil_tph.arvalid ),
    .s_axi_arready              ( axil_tph.arready ),
    .s_axi_araddr               ( axil_tph.araddr ),
    .s_axi_arprot               ( axil_tph.arprot ),
    .s_axi_aruser               ( axil_tph.aruser ),

    // Read data channel
    .s_axi_rvalid               ( axil_tph.rvalid ),
    .s_axi_rready               ( axil_tph.rready ),
    .s_axi_rdata                ( axil_tph.rdata ),
    .s_axi_rresp                ( axil_tph.rresp ),
    .s_axi_ruser                ( axil_tph.ruser )
);

///////////////////////////////////////////////////////////////////////
//                        Config Status
///////////////////////////////////////////////////////////////////////
BMD_AXIST_CFG BMD_AXIST_CFG (
    .clk                        ( clk ),
    .rst_n                      ( rst_n ),

    .pf_cfg                     ( pf_cfg ),
    .vf_cfg                     ( vf_cfg ),

    .pf_cfg_regs                ( pf_cfg_regs ),
    .vf_cfg_regs                ( vf_cfg_regs )
);

///////////////////////////////////////////////////////////////////////
//                          BMD Core
///////////////////////////////////////////////////////////////////////
BMD_AXIST_EP BMD_AXIST_EP (
    .clk                        ( clk ),
    .rst_n                      ( rst_n ),

    .tx                         ( tx ),
    .rx                         ( rx ),

    .tx_crd                     ( tx_crd ),
    .rx_crd                     ( rx_crd ),

    .pf_cfg                     ( pf_cfg_regs ),
    .vf_cfg                     ( vf_cfg_regs ),

    .ltssm_state                ( ltssm_state ),
    .link_up                    ( link_up ),

    .app_ready_entr_l23         ( app_ready_entr_l23 ),

    .msix                       ( msix ),
    .msi                        ( msi ),

    .debug_bmd                  ( debug_bmd ),
    .debug_bmd_sel              ( debug_bmd_sel )
);

endmodule // BMD_AXIST
