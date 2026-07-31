`include "cxl_nfi_agent_if.sv"

package cxl_nfi_agent_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import base_agent_pkg::*;

  import cxl31_tl_pkg::*;
  import cxl31_ll_pkg::*;
  import cxl_nfi_other_pkg::*;

  export cxl_nfi_other_pkg::MEM;
  export cxl_nfi_other_pkg::CCH;

  `include "cache_txns.sv"
  `include "mem_txns.sv"
  `include "slot_base.sv"

  `include "cxl_nfi_credit_txn.sv"
  `include "flit_base_txn.sv"
  `include "cxl_nfi_txn.sv"

  // 68B flit specific
  `include "hslots_f68.sv"
  `include "gslots_f68.sv"
  `include "llslots_f68.sv"
  `include "flit68_txn.sv"
  `include "flit68_tl_assembler.sv"
  `include "flit68_api.sv"

  // 256B flit specific
  `include "slot_base_f256.sv"
  `include "slots_f256.sv"
  `include "slotset_txn.sv"
  `include "flit256_txn.sv"
  `include "flit256_tl_assembler.sv"
  `include "flit256_api.sv"

  // Primary components
  `include "cxl_nfi_cfg.sv"
  `include "cxl_nfi_share.sv"
  `include "cxl_nfi_driver.sv"
  `include "cxl_nfi_monitor.sv"
  `include "cxl_nfi_sequencer.sv"
  `include "cxl_nfi_agent.sv"

  // Sequences
  `include "seq/cxl_nfi_base_seq.sv"
  `include "seq/cxl_nfi_slv_seq.sv"
  `include "seq/cxl_nfi_mst_base_seq.sv"
  `include "seq/cxl_nfi_mst_in_order_seq.sv"
  `include "seq/cxl_nfi_mst_init_seq.sv"
  `include "seq/cxl_nfi_mst_crd_give_seq.sv"
  `include "seq/flit68_mst_rand_seq.sv"
  `include "seq/flit256_mst_rand_seq.sv"

endpackage

