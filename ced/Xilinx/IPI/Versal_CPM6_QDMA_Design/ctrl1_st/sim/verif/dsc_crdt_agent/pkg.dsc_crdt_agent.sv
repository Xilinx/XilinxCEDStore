// (c) Copyright 2026 Advanced Micro Devices, Inc. All rights reserved.
//
// pkg.dsc_crdt_agent.sv — Package for DSC_CRDT descriptor credit agent.

`include "dsc_crdt_if.sv"

package dsc_crdt_agent_pkg;
   `include "uvm_macros.svh"
   import uvm_pkg::*;

   `include "dsc_crdt_seq_item.sv"
   `include "dsc_crdt_seq.sv"
   `include "dsc_crdt_driver.sv"
   `include "dsc_crdt_monitor.sv"
   `include "dsc_crdt_agent.sv"

endpackage : dsc_crdt_agent_pkg
