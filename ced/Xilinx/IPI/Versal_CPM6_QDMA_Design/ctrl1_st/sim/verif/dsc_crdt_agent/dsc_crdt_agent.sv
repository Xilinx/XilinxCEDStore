// (c) Copyright 2026 Advanced Micro Devices, Inc. All rights reserved.
//
// dsc_crdt_agent.sv — UVM agent for DSC_CRDT descriptor credit interface.
//
// UVM_ACTIVE (default):
//   Creates driver + sequencer + monitor.  Tests send dsc_crdt_seq
//   transactions to inject credits as an alternative to PIDX doorbells.
//
// UVM_PASSIVE:
//   Creates monitor only.  Observes credit handshakes without driving.

`ifndef __DSC_CRDT_AGENT__SV__
`define __DSC_CRDT_AGENT__SV__

class dsc_crdt_agent extends uvm_agent;
   `uvm_component_utils(dsc_crdt_agent)

   dsc_crdt_driver                       drv;
   dsc_crdt_monitor                      mon;
   uvm_sequencer#(dsc_crdt_seq_item)     seqr;
   uvm_analysis_port#(dsc_crdt_seq_item) ap;

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      virtual dsc_crdt_if vif;
      super.build_phase(phase);
      ap = new("ap", this);

      // Retrieve VIF from global config_db and re-publish to sub-components
      if (uvm_config_db#(virtual dsc_crdt_if)::get(this, "", "vif", vif)) begin
         uvm_config_db#(virtual dsc_crdt_if)::set(this, "mon", "vif", vif);
         if (is_active == UVM_ACTIVE)
            uvm_config_db#(virtual dsc_crdt_if)::set(this, "drv", "vif", vif);
      end else begin
         `uvm_warning("dsc_crdt_agent",
            "dsc_crdt vif not found in config_db  -  bind.dsc_crdt.sv may not have run")
      end

      mon = dsc_crdt_monitor::type_id::create("mon", this);

      if (is_active == UVM_ACTIVE) begin
         drv  = dsc_crdt_driver::type_id::create("drv", this);
         seqr = uvm_sequencer#(dsc_crdt_seq_item)::type_id::create("seqr", this);
      end
   endfunction

   function void connect_phase(uvm_phase phase);
      mon.ap.connect(ap);
      if (is_active == UVM_ACTIVE)
         drv.seq_item_port.connect(seqr.seq_item_export);
   endfunction

endclass : dsc_crdt_agent

`endif // __DSC_CRDT_AGENT__SV__
