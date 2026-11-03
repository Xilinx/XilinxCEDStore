// (c) Copyright 2026 Advanced Micro Devices, Inc. All rights reserved.
//
// bind.dsc_crdt.sv — Bind DSC_CRDT interface to the BD module (`CPM6_BD_TOP_MODULE).
//
// The dsc_crdt_in interface is exposed as an external BD port (dsc_crdt_in_0).
//
// Drive signals (vld, dir, fence, qid, crdt) are driven FROM the UVM agent's
// VIF clocking block through inout ports.
//
// rdy is an OUTPUT from the DUT, monitored via input port → VIF assign.
//
// Port names match the BD module's dsc_crdt_in_0_* ports.
// Clock: ps_wizard_0_pl0_ref_clk (~250 MHz, axi_aclk domain)

`include "qdma_bd_names.svh"
`default_nettype wire

module bind_dsc_crdt
   import uvm_pkg::*;
(
   // Clock / Reset
   input wire          ps_wizard_0_pl0_ref_clk,
   input wire          ps_wizard_0_pl0_resetn,

   // dsc_crdt_in_0 — drive signals are inout (VIF → DUT)
   inout wire [15:0]   dsc_crdt_in_0_crdt,
   inout wire          dsc_crdt_in_0_dir,
   inout wire          dsc_crdt_in_0_fence,
   inout wire [10:0]   dsc_crdt_in_0_qid,
   input wire          dsc_crdt_in_0_rdy,    // DUT output → VIF (monitor)
   inout wire          dsc_crdt_in_0_vld      // VIF → DUT (drive)
);
   `include "uvm_macros.svh"

   // -------------------------------------------------------------------------
   // Interface instance
   // -------------------------------------------------------------------------
   dsc_crdt_if vif_inst (.clk(ps_wizard_0_pl0_ref_clk), .rst_n(ps_wizard_0_pl0_resetn));

   // -------------------------------------------------------------------------
   // Drive signals: VIF → DUT (UVM driver controls these via drv_cb)
   // Use procedural force to override dsc_crdt_exerciser's structural drive
   // (exerciser drives vld=0 by default; force from bind wins over it).
   // -------------------------------------------------------------------------
   always @(*) begin
      force dsc_crdt_in_0_vld   = vif_inst.vld;
      force dsc_crdt_in_0_dir   = vif_inst.dir;
      force dsc_crdt_in_0_fence = vif_inst.fence;
      force dsc_crdt_in_0_qid   = vif_inst.qid[10:0];
      force dsc_crdt_in_0_crdt  = vif_inst.crdt;
   end

   // -------------------------------------------------------------------------
   // Monitor signal: DUT → VIF (rdy is an output from the IP)
   // -------------------------------------------------------------------------
   assign vif_inst.rdy = dsc_crdt_in_0_rdy;

   // -------------------------------------------------------------------------
   // Register VIF in UVM config_db (global scope)
   // -------------------------------------------------------------------------
   initial begin
      uvm_pkg::uvm_config_db#(virtual dsc_crdt_if)::set(
         null, "*", "vif_dsc_crdt", vif_inst);
   end

endmodule : bind_dsc_crdt

`default_nettype none

bind `CPM6_BD_TOP_MODULE bind_dsc_crdt bind_dsc_crdt_inst (.*);

`default_nettype wire  // restore for subsequent compilation units
