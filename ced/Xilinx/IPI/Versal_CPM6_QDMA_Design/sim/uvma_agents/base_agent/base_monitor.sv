// - Base Monitor Class
// - Users should create a run_phase task that controls what the monitor will 
//   "see" from the interface and build a transaction
// - Can broadcast the txn out the base_ap, the ap, or both, then the agent can
//   connect to either or both analysis ports; the benefit of broadcasting out
//   the base_ap is that you can have multiple analysis ports broadcast to a
//   single implementation (imp) port and handle from there based on txn_type 
//   (N to 1 port connections)
class base_monitor #(type CFG, type VIF, type TXN, type SHR) extends uvm_monitor;

  `uvm_component_param_utils(base_monitor#(CFG,VIF,TXN,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"base_monitor#(", 
                                   CFG::type_name,",",
                                   "VIF,",
                                   TXN::type_name,",",
                                   SHR::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  CFG cfg;
  VIF vif;
  SHR shr;

  uvm_analysis_port#(TXN) ap;
  uvm_analysis_port#(base_txn) base_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
    base_ap = new("base_ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(CFG)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name, "Failed to get cfg object from config_db")
    if (!uvm_config_db#(SHR)::get(this, "", "shr", shr))
      `uvm_fatal(get_type_name, "Failed to get shr object from config_db")
    if (!uvm_config_db#(VIF)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name, "Failed to get vif from config_db")
  endfunction

endclass
