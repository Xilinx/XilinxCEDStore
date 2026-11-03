// (c) Copyright 2026 Advanced Micro Devices, Inc. All rights reserved.
//
// dsc_crdt_seq.sv — One-shot sequence for sending a single descriptor credit.
//
// Usage from test tasks:
//   dsc_crdt_seq seq = dsc_crdt_seq::type_id::create("seq");
//   seq.qid   = hw_qid;
//   seq.crdt  = pidx;
//   seq.dir   = 1'b0;  // H2C
//   seq.fence = 1'b0;
//   seq.start(dsc_crdt_agnt.seqr);

`ifndef __DSC_CRDT_SEQ__SV__
`define __DSC_CRDT_SEQ__SV__

class dsc_crdt_seq extends uvm_sequence#(dsc_crdt_seq_item);
   `uvm_object_utils(dsc_crdt_seq)

   logic [11:0] qid;
   logic [15:0] crdt;
   logic        dir;
   logic        fence;

   function new(string name = "dsc_crdt_seq");
      super.new(name);
   endfunction

   task body();
      dsc_crdt_seq_item txn = dsc_crdt_seq_item::type_id::create("txn");
      start_item(txn);
      txn.qid   = qid;
      txn.crdt  = crdt;
      txn.dir   = dir;
      txn.fence = fence;
      finish_item(txn);
   endtask : body

endclass : dsc_crdt_seq

`endif // __DSC_CRDT_SEQ__SV__
