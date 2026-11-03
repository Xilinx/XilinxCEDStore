// qdma_periph_agent.sv — Passive UVM agent for QDMA periphery monitoring
//
// Contains only a monitor (UVM_PASSIVE). The analysis port is forwarded
// from the monitor so subscribers can connect directly to the agent.
class qdma_periph_agent extends uvm_agent;

   `uvm_component_utils(qdma_periph_agent)

   qdma_periph_monitor                 mon;
   qdma_periph_cfg                     cfg;
   uvm_analysis_port#(qdma_periph_txn) ap;

   function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(qdma_periph_cfg)::get(this, "", "cfg", cfg)) begin
         cfg = qdma_periph_cfg::type_id::create("cfg", this);
         `uvm_info("qdma_periph_agent", "cfg not found in config_db; using defaults", UVM_LOW)
      end

      // Forward vif and cfg down to the monitor
      uvm_config_db#(virtual qdma_periph_if)::set(this, "mon", "vif", get_vif());
      uvm_config_db#(qdma_periph_cfg)::set(this, "mon", "cfg", cfg);

      mon = qdma_periph_monitor::type_id::create("mon", this);
   endfunction

   virtual function void connect_phase(uvm_phase phase);
      mon.ap.connect(ap);
   endfunction

   local function virtual qdma_periph_if get_vif();
      virtual qdma_periph_if vif;
      if (!uvm_config_db#(virtual qdma_periph_if)::get(this, "", "vif", vif))
         `uvm_fatal("qdma_periph_agent", "Failed to get virtual qdma_periph_if from config_db")
      return vif;
   endfunction

endclass
