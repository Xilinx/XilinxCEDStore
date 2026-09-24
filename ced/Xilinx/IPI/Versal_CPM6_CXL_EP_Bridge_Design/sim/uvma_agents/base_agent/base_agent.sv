// - Agent Base Class
// - Extended classes can simply pass the correct types (if needed) and extend
//   this class and get a functional agent
class base_agent #(
  type VIF,
  type CFG = base_cfg,
  type SHR = base_share,
  type REQ = base_txn,
  type RSP = REQ,
  type TXN = REQ,
  type DRV = base_driver#(REQ,RSP,VIF,CFG,SHR),
  type SQR = base_sequencer#(REQ,RSP,TXN,CFG,SHR),
  type MON = base_monitor#(CFG,VIF,TXN,SHR),
  type API = base_api#(SQR)
) extends uvm_agent;

  `uvm_component_param_utils(base_agent#(VIF,CFG,SHR,REQ,RSP,TXN,DRV,SQR,MON,API))
  
  typedef base_agent#(VIF,CFG,SHR,REQ,RSP,TXN,DRV,SQR,MON,API) this_type;

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"base_agent#(VIF,",
                                   CFG::type_name,",",
                                   SHR::type_name,",",
                                   REQ::type_name,",",
                                   RSP::type_name,",",
                                   TXN::type_name,",",
                                   DRV::type_name,",",
                                   SQR::type_name,",",
                                   MON::type_name,",",
                                   API::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  CFG  cfg;
  DRV  drv;
  SQR  sqr;
  MON  mon;
  SHR  shr;
  API  api;

  uvm_analysis_port#(TXN) ap;
  uvm_analysis_port#(base_txn) base_ap;

  // Appends config info to every txn, impl to ap act as passthrough
  `uvm_analysis_imp_decl(_append)
  `uvm_analysis_imp_decl(_base_append)
  uvm_analysis_imp_append      #(TXN, this_type)      impl_append;
  uvm_analysis_imp_base_append #(base_txn, this_type) impl_base_append;
  uvm_analysis_port#(TXN)      append_ap;
  uvm_analysis_port#(base_txn) base_append_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap               = new("ap", this);
    base_ap          = new("base_ap", this);
    impl_append      = new("impl_append", this); 
    impl_base_append = new("impl_base_append", this); 
    append_ap        = new("append_ap", this);
    base_append_ap   = new("base_append_ap", this);
  endfunction

  // Helper functions
  virtual function bit is_master (); return cfg.is_master;  endfunction
  virtual function bit is_slave  (); return cfg.is_slave;   endfunction
  virtual function bit is_active (); return cfg.is_active;  endfunction
  virtual function bit is_passive(); return cfg.is_passive; endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (cfg == null) begin
      if (!uvm_config_db#(CFG)::get(this, "", "cfg", cfg))
        `uvm_fatal(get_type_name(), "Failed to get cfg object from config_db")
    end

    mon = MON::type_id::create("mon", this);
    shr = SHR::type_id::create("shr", this);

    if (is_active) begin
      drv = DRV::type_id::create("drv", this);
      sqr = SQR::type_id::create("sqr", this);
    end

    if (is_master && !cfg.disable_api) begin
      api = API::type_id::create("api", this);
      api.sqr = sqr;
    end

    uvm_config_db#(SHR)::set(this, "*", "shr", shr);

  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Inline txn appending; always present
    mon.ap.connect(impl_append);
    mon.base_ap.connect(impl_base_append);

    // Connect to final ports
    if (!cfg.disable_mon_ap_connect)     append_ap.connect(ap);
    if (!cfg.disable_mon_baseap_connect) base_append_ap.connect(base_ap);

    if (is_active) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
      // "Active responder" (slave) agent will specify SQR as base_sqr
      // or an extended sqr and user will respond to requests 
      // in a specific manner as directed by the custom sequence,
      // likely with a fifo.get in the sequence that determines
      // the slave response.
      if (is_slave && !cfg.disable_mon_ap_connect) begin
        mon.ap.connect(sqr.analysis_export);  
      end
    end
  endfunction

  // Append info to every txn
  virtual function void write_base_append(base_txn t);
    t.addl_info         = cfg.addl_txn_info;
    t.compare_addl_info = cfg.compare_addl_txn_info;
    steer_base_txn(t);
  endfunction

  // Steer the base txn to an analysis port
  virtual function void steer_base_txn(base_txn t);
    base_append_ap.write(t);   
  endfunction

  // Append info to every txn
  virtual function void write_append(TXN t);
    t.addl_info         = cfg.addl_txn_info;
    t.compare_addl_info = cfg.compare_addl_txn_info;
    steer_txn(t);
  endfunction

  // Steer the txn to an analysis port
  virtual function void steer_txn(TXN t);
    append_ap.write(t);   
  endfunction

endclass
