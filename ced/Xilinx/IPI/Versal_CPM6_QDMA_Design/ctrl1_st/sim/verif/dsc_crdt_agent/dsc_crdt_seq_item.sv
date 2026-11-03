// (c) Copyright 2026 Advanced Micro Devices, Inc. All rights reserved.
//
// dsc_crdt_seq_item.sv — Transaction for descriptor credit interface.
//
// Fields map 1:1 to the DSC_CRDT_IN_0 port signals.
// No randomization — test sets values directly.

`ifndef __DSC_CRDT_SEQ_ITEM__SV__
`define __DSC_CRDT_SEQ_ITEM__SV__

class dsc_crdt_seq_item extends uvm_sequence_item;
   `uvm_object_utils(dsc_crdt_seq_item)

   logic [11:0] qid;
   logic [15:0] crdt;
   logic        dir;    // 0=H2C, 1=C2H
   logic        fence;

   function new(string name = "dsc_crdt_seq_item");
      super.new(name);
   endfunction

   function string convert2string();
      return $sformatf("qid=%0d crdt=%0d dir=%s fence=%0b",
                       qid, crdt, dir ? "C2H" : "H2C", fence);
   endfunction

   function void do_copy(uvm_object rhs);
      dsc_crdt_seq_item rhs_;
      super.do_copy(rhs);
      $cast(rhs_, rhs);
      qid   = rhs_.qid;
      crdt  = rhs_.crdt;
      dir   = rhs_.dir;
      fence = rhs_.fence;
   endfunction

endclass : dsc_crdt_seq_item

`endif // __DSC_CRDT_SEQ_ITEM__SV__
