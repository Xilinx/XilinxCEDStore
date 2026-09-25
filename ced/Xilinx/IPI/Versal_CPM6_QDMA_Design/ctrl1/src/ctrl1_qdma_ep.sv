//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
// ctrl1_qdma_ep.sv -- CTRL1 top-level EP wrapper for Versal_CPM6_QDMA_Design.
//
// Directly instantiates the "cpm6_qdma" block design (see ../design_1_bd.tcl).
// The module name below ("cpm6_qdma") matches design.xml's <Name>cpm6_qdma</Name>
// -- the CED framework's instantiate_example_design flow creates an empty BD
// design under that name before sourcing design_1_bd.tcl, which reuses that
// same name.
//
// Port list confirmed directly from the actual Vivado-generated BD wrapper
// for this design (design_1_wrapper.v): only the GT quad + its reference
// clock cross the BD boundary.
// cpm6_qdma_0 is a fully self-contained IP within the BD -- QDMA's
// DMA/interrupt/register stack is entirely internal (routed to on-chip
// BRAM/NoC memory and ps_wizard's pcie1_msix inside the BD itself), so
// there is no separate external application logic to wire up here.
//--------------------------------------------------------------------------------
module ctrl1_qdma_ep
import qdma_link_pkg::*;
(
    CTRL1_GT_0_grx_n,
    CTRL1_GT_0_grx_p,
    CTRL1_GT_0_gtx_n,
    CTRL1_GT_0_gtx_p,
    ctrl1_gt_refclk_0_clk_n,
    ctrl1_gt_refclk_0_clk_p
);
    input  [LINK_WIDTH-1:0] CTRL1_GT_0_grx_n;
    input  [LINK_WIDTH-1:0] CTRL1_GT_0_grx_p;
    output [LINK_WIDTH-1:0] CTRL1_GT_0_gtx_n;
    output [LINK_WIDTH-1:0] CTRL1_GT_0_gtx_p;
    input                   ctrl1_gt_refclk_0_clk_n;
    input                   ctrl1_gt_refclk_0_clk_p;

    cpm6_qdma ctrl1_ep_i (
        .CTRL1_GT_0_grx_n        ( CTRL1_GT_0_grx_n ),
        .CTRL1_GT_0_grx_p        ( CTRL1_GT_0_grx_p ),
        .CTRL1_GT_0_gtx_n        ( CTRL1_GT_0_gtx_n ),
        .CTRL1_GT_0_gtx_p        ( CTRL1_GT_0_gtx_p ),
        .ctrl1_gt_refclk_0_clk_n ( ctrl1_gt_refclk_0_clk_n ),
        .ctrl1_gt_refclk_0_clk_p ( ctrl1_gt_refclk_0_clk_p )
    );

endmodule
