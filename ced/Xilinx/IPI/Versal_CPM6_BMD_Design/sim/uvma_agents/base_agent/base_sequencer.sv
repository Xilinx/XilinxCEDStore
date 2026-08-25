// - Base Sequencer Class
// - Active slave agents will have their monitors connect to the analysis FIFO, users will
//   then do a blocking get on the FIFO in their sequence with a `uvm_declare_p_sequencer 
//   in it and that can be used to control how the slave will respond to a request
// - Masters can just use this like a generic uvm_sequencer
class base_sequencer #(type REQ, type RSP, type TXN, type CFG, type SHR) extends uvm_sequencer#(REQ, RSP);

  `uvm_component_param_utils(base_sequencer#(REQ,RSP,TXN,CFG,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"base_sequencer#(", 
                                   REQ::type_name,",",
                                   RSP::type_name,",",
                                   TXN::type_name,",",
                                   CFG::type_name,",",
                                   SHR::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  SHR shr;
  CFG cfg;

  uvm_analysis_export   #(TXN) analysis_export;
  uvm_tlm_analysis_fifo #(TXN) analysis_fifo;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_export = new("analysis_export", this);
    analysis_fifo = new("analysis_fifo", this);
    if (!uvm_config_db#(SHR)::get(this, "", "shr", shr))
      `uvm_fatal(get_type_name, "Failed to get shr object from config_db")
    if (!uvm_config_db#(CFG)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name, "Failed to get cfg object from config_db")
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    analysis_export.connect(analysis_fifo.analysis_export);
  endfunction

endclass
