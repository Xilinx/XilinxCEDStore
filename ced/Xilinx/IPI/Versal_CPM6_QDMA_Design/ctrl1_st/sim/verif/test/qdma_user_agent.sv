// qdma_user_agent.sv — UVM agent for QDMA user-side AXI4-Stream.
//
// UVM_PASSIVE (default):
//   Creates monitor + scoreboard only.  No C2H data is injected.
//   Safe to instantiate in any test without changing DUT behaviour.
//
// UVM_ACTIVE:
//   Additionally creates driver + sequencer.

class qdma_user_agent extends uvm_agent;
  `uvm_component_utils(qdma_user_agent)

  qdma_user_monitor                         mon;
  qdma_user_scoreboard                      sb;
  qdma_user_driver                          drv;   // active mode only
  uvm_sequencer#(qdma_user_transaction)     seqr;  // active mode only

  uvm_analysis_port#(qdma_user_transaction) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    virtual qdma_user_if vif;
    super.build_phase(phase);
    ap = new("ap", this);

    // Retrieve VIF from global config_db (set by bind_qdma_user_st initial block)
    // and re-publish it scoped to sub-components so they can find it.
    if (uvm_config_db#(virtual qdma_user_if)::get(this, "", "qdma_user_vif", vif)) begin
      uvm_config_db#(virtual qdma_user_if)::set(this, "mon", "vif", vif);
      if (is_active == UVM_ACTIVE)
        uvm_config_db#(virtual qdma_user_if)::set(this, "drv", "vif", vif);
    end else begin
      `uvm_warning("qdma_user_agent",
        "qdma_user_vif not found in config_db  -  bind.qdma_user_st.sv may not have run")
    end

    mon  = qdma_user_monitor::type_id::create("mon", this);
    sb   = qdma_user_scoreboard::type_id::create("sb",  this);

    if (is_active == UVM_ACTIVE) begin
      drv  = qdma_user_driver::type_id::create("drv",  this);
      seqr = uvm_sequencer#(qdma_user_transaction)::type_id::create("seqr", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    mon.ap.connect(sb.analysis_export);
    mon.ap.connect(ap);
    if (is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction

endclass
