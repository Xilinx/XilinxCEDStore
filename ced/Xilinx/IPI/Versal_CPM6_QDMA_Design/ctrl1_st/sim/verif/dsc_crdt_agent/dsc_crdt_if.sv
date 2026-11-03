// (c) Copyright 2026 Advanced Micro Devices, Inc. All rights reserved.
//
// dsc_crdt_if.sv — Interface for DSC_CRDT (descriptor credit) handshake.
//
// Signals mirror the BD DSC_CRDT_IN_0_* port group:
//   vld/rdy handshake + qid[11:0] + crdt[15:0] + dir + fence.
//
// Clock domain: axi_aclk (ps_wizard_0_pl0_ref_clk, ~250 MHz).

`ifndef __DSC_CRDT_IF__SV__
`define __DSC_CRDT_IF__SV__

interface dsc_crdt_if (input logic clk, input logic rst_n);

   logic        vld;
   logic        rdy;
   logic        dir;    // 0=H2C, 1=C2H
   logic        fence;
   logic [11:0] qid;
   logic [15:0] crdt;

   // Default idle state — prevents X on DUT inputs before driver starts
   initial begin
      vld   = 1'b0;
      dir   = 1'b0;
      fence = 1'b0;
      qid   = '0;
      crdt  = '0;
   end

   clocking drv_cb @(posedge clk);
      default input #1step output #0;
      output vld, dir, fence, qid, crdt;
      input  rdy;
   endclocking

   clocking mon_cb @(posedge clk);
      default input #1step;
      input vld, rdy, dir, fence, qid, crdt;
   endclocking

endinterface : dsc_crdt_if

`endif // __DSC_CRDT_IF__SV__
