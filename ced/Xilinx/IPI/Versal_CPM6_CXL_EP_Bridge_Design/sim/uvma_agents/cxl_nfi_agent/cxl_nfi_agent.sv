// Forward typedef some sequences
typedef class cxl_nfi_mst_init_seq;
typedef class cxl_nfi_mst_crd_give_seq;
typedef class cxl_nfi_slv_seq;
typedef class flit68_mst_qpacker_seq;
typedef class flit256_mst_qpacker_seq;

class cxl_nfi_agent#(parameter NFI_W=3) extends base_agent#(
  .VIF (virtual cxl_nfi_agent_if#(NFI_W)),
  .CFG (cxl_nfi_cfg),
  .SHR (cxl_nfi_share),
  .DRV (cxl_nfi_driver#(cxl_nfi_txn#(NFI_W), cxl_nfi_txn#(NFI_W), virtual cxl_nfi_agent_if#(NFI_W), cxl_nfi_cfg, cxl_nfi_share)),
  .SQR (cxl_nfi_sequencer#(NFI_W)),
  .MON (cxl_nfi_monitor#(cxl_nfi_cfg, virtual cxl_nfi_agent_if#(NFI_W), base_txn, cxl_nfi_share))
);

  `uvm_component_param_utils(cxl_nfi_agent#(NFI_W))

  `uvm_analysis_imp_decl(_avl)
  `uvm_analysis_imp_decl(_give)
   uvm_analysis_imp_avl  #(cxl_nfi_credit_txn, cxl_nfi_agent#(NFI_W)) impl_avl;
   uvm_analysis_imp_give #(cxl_nfi_credit_txn, cxl_nfi_agent#(NFI_W)) impl_give;

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("cxl_nfi_agent#(%0d)",NFI_W);
  virtual function string get_type_name(); return type_name; endfunction

  // Output ports
  uvm_analysis_port#(base_txn)           base_llc_ap;
  uvm_analysis_port#(base_txn)           base_tl_ap;
  uvm_analysis_port#(flit68_txn)         ap68;
  uvm_analysis_port#(flit256_txn)        ap256;
  uvm_analysis_port#(flit_base_txn)      ap_fb;
  uvm_analysis_port#(cxl_nfi_credit_txn) cred_ret_ap;
  uvm_analysis_port#(cxl_nfi_credit_txn) cred_give_ap;

  // Supporting components
  flit68_tl_assembler#(flit68_txn)               flit68_to_tl;
  flit256_tl_assembler#(slotset_txn)             flit256_to_tl;
  flit68_api#(cxl_nfi_sequencer#(NFI_W), NFI_W)  api68;
  flit256_api#(cxl_nfi_sequencer#(NFI_W), NFI_W) api256;

  // Master agent will trigger link_init_done, waits on link_init_start/init_param_rcvd
  // External assignment from slave agent to master's init_param_rcvd must be done
  // -> mst.init_param_rcvd = slv.init_param_rcvd;
  // Receiving initial credits via impl_give port triggers the link_init_start event, or
  // an external caller may trigger it as below.
  //  -> mst.link_init_start.trigger 
  uvm_event link_init_start, link_init_done, init_param_rcvd;
  // External force calls txfer_init_credits on a slave, which broadcasts them to master agent

  // Sequences that may need to be accessed later
  cxl_nfi_slv_seq#(NFI_W) slv_seq;
  flit68_mst_qpacker_seq#(NFI_W)  mst_f68_qpacker;
  flit256_mst_qpacker_seq#(NFI_W) mst_f256_qpacker;

  // The input analysis port for capturing the received transactions
  `uvm_analysis_imp_decl(_txn_q)
  // UVM Implementation Ports require two template parameters:
  // 1) the transaction type
  // 2) the class type that implements the write funciton
  uvm_analysis_imp_txn_q#(base_txn, cxl_nfi_agent#(NFI_W)) txn_q_imp;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    base_tl_ap      = new("base_tl_ap", this);
    base_llc_ap     = new("base_llc_ap", this);
    ap68            = new("ap68", this);
    ap256           = new("ap256", this);
    ap_fb           = new("ap_fb", this);
    cred_ret_ap     = new("cred_ret_ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Get rid of standard API handle
    cfg.disable_api = 1'b1; api = null;
    impl_avl = new("impl_avl", this);
    case (cfg.flitmode) inside
      F68, F256, UNSPEC: ;
      default : `uvm_fatal(get_type_name(), $sformatf("Agent does not support %0s flitmode",cfg.flitmode.name))
    endcase
    if (cfg.flitmode inside {F68, UNSPEC}) begin
      flit68_to_tl = flit68_tl_assembler #(flit68_txn) ::type_id::create("flit68_to_tl",  this);
      if (is_active)
        api68 = flit68_api#(cxl_nfi_sequencer#(NFI_W), NFI_W)::type_id::create("api68", this);
    end
    if (cfg.flitmode inside {F256, UNSPEC}) begin
      flit256_to_tl = flit256_tl_assembler#(slotset_txn)::type_id::create("flit256_to_tl", this);
      flit256_to_tl.flitmode = F256;
      if (is_active)
        api256 = flit256_api#(cxl_nfi_sequencer#(NFI_W), NFI_W)::type_id::create("api256", this);
    end
    // A master or slave agent only triggers certain events - only create 
    // those objects. Also only create components/ports we need.
    if (is_slave) begin
      init_param_rcvd = new("init_param_rcvd");
      cred_give_ap    = new("cred_give_ap", this);
      if (is_active)
        slv_seq = cxl_nfi_slv_seq#(NFI_W)::type_id::create("slv_seq");
    end
    else begin
      link_init_start = new("link_init_start");
      link_init_done  = new("link_init_done");
      // Only a master gives credits across link, so only a master will
      // need to be informed of the "give" credits from a slave agent 
      impl_give = new("impl_give", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    // Hardcoded base class cfg settings
    cfg.disable_mon_ap_connect = 1'b1;
    super.connect_phase(phase);
    if (is_master && is_active) begin
      // Give api the handle to sqr
      if (cfg.flitmode inside {F68, UNSPEC})  api68.sqr  = sqr; 
      if (cfg.flitmode inside {F256, UNSPEC}) api256.sqr = sqr; 
      // Master agent will broadcast credit returns via the cred_ret_ap
      // directly or through flits, which will in turn send out the cred_ret_ap
      // from the tl assembler.
      sqr.cred_ret_ap.connect(cred_ret_ap);
    end
    // Monitor connections always present
    mon.ap68 .connect(ap68);
    mon.ap256.connect(ap256);
    mon.ap_fb.connect(ap_fb);
    // Monitor connects to TL assembler block; converts from link layer
    // flits to separate txns for transaction layer, link layer control,
    // and credit returns. 
    if (!cfg.remove_tl_assembler_comp) begin
      if (cfg.flitmode inside {F68, UNSPEC}) begin
        mon.ap68.connect(flit68_to_tl.analysis_export);
        flit68_to_tl.base_tl_ap .connect(base_tl_ap);
        flit68_to_tl.base_llc_ap.connect(base_llc_ap);
        flit68_to_tl.cred_ret_ap.connect(cred_ret_ap);
        flit68_to_tl.init_param_rcvd = init_param_rcvd;
        // Slave must be able to tell master what it swallowed so master
        // can return those credits 
        if (is_slave) begin
          flit68_to_tl.is_slave = 1'b1;
          flit68_to_tl.cred_give_ap.connect(cred_give_ap);
        end
      end
      if (cfg.flitmode inside {F256, UNSPEC}) begin
        mon.apSS.connect(flit256_to_tl.analysis_export);
        flit256_to_tl.base_tl_ap .connect(base_tl_ap);
        flit256_to_tl.base_llc_ap.connect(base_llc_ap);
        flit256_to_tl.cred_ret_ap.connect(cred_ret_ap);
        flit256_to_tl.init_param_rcvd = init_param_rcvd;
        // Slave must be able to tell master what it swallowed so master
        // can return those credits 
        if (is_slave) begin
          flit256_to_tl.is_slave = 1'b1;
          flit256_to_tl.cred_give_ap.connect(cred_give_ap);
        end
      end
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit cch_crd_present, mem_crd_present;
    cxl_nfi_mst_init_seq#(NFI_W)     init_seq;
    cxl_nfi_mst_crd_give_seq#(NFI_W) give_seq;
    // Seq: Active slave agents may need to backpressure master with ready signal
    if (is_active) begin
      if (is_slave)
        slv_seq.start(sqr);
      else if (is_master) begin
        // Seq: Master agents must send initial credits (unique in F68 mode)
        if (!cfg.skip_link_init) begin
          if (!{cfg.cxl_mem_sup, cfg.cxl_cch_sup})
            `uvm_fatal(get_type_name(), "Agent's cfg object member(s) cxl_mem_sup and/or cxl_cch_sup not set")
          // Must be given initial credits before starting sequence
          link_init_start.wait_trigger;
          mem_crd_present = (cfg.cxl_mem_sup && shr.any_init_credits(MEM));
          cch_crd_present = (cfg.cxl_cch_sup && shr.any_init_credits(CCH));
          if (!mem_crd_present && !cch_crd_present)
            `uvm_fatal(get_type_name(), "Need to configure initial credits for this agent")
          init_seq = cxl_nfi_mst_init_seq#(NFI_W)::type_id::create("init_seq");
          init_seq.init_param_rcvd = init_param_rcvd;
          init_seq.link_init_done  = link_init_done;
          init_seq.start(sqr);
        end
        fork
          begin
            // Seq: Master agents must return credits either across the link or
            //      sent as a txn out an ap to be handled in some other manner.
            if (cfg.return_crds) begin
              give_seq = cxl_nfi_mst_crd_give_seq#(NFI_W)::type_id::create("give_seq");
              give_seq.start(sqr);
            end
          end
          begin
            // Flit68 Mode
            if (cfg.flitmode inside {F68, UNSPEC}) begin
              mst_f68_qpacker = flit68_mst_qpacker_seq#(NFI_W)::type_id::create("mst_f68_qpacker");
              mst_f68_qpacker.start(sqr);
            end
            // Flit256 Mode
            if (cfg.flitmode inside {F256, UNSPEC}) begin
              mst_f256_qpacker = flit256_mst_qpacker_seq#(NFI_W)::type_id::create("mst_f256_qpacker");
              mst_f256_qpacker.start(sqr);
            end
          end
        join
      end
    end
  endtask

  // This function will broadcast the init credits out the cred_give_ap 
  virtual function void txfer_init_credits();
    cxl_nfi_credit_txn t = cxl_nfi_credit_txn::type_id::create("t");
    if (is_slave) begin
      t.info = "init";
      t.req_cred = cfg.init_req_credit;
      t.dat_cred = cfg.init_dat_credit;
      t.rsp_cred = cfg.init_rsp_credit;
      cred_give_ap.write(t);
    end
    else
      `uvm_fatal(get_type_name(), "::txfer_init_credits should only be called on a slave")
  endfunction

  // The share object will have members of the number of available credits.
  // For a master, this is what can be sent. For a slave, this is what can be
  // received.
  function void write_avl(cxl_nfi_credit_txn t);
    for (int ii=0; ii<2; ii++) begin
      shr.avl_req_credit[ii] += t.req_cred[ii];
      shr.avl_dat_credit[ii] += t.dat_cred[ii];
      shr.avl_rsp_credit[ii] += t.rsp_cred[ii];
    end
  endfunction

  // The share object will have members of the number of available credits.
  // The "give" credits are only applicable to a master, and they are used to
  // return credits across the link.
  function void write_give(cxl_nfi_credit_txn t);
    if (t.info == "init") begin
      shr.init_req_credit = t.req_cred;
      shr.init_dat_credit = t.dat_cred;
      shr.init_rsp_credit = t.rsp_cred;
      link_init_start.trigger;
    end
    else begin
      for (int ii=0; ii<2; ii++) begin
        shr.give_req_credit[ii] += t.req_cred[ii];
        shr.give_dat_credit[ii] += t.dat_cred[ii];
        shr.give_rsp_credit[ii] += t.rsp_cred[ii];
      end
    end
  endfunction

  // This is the UVM-specific write function called to implement the analysis port connect from outside this class.
  // The declarations are defined with `uvm_analysis_imp_decl, defining the suffix which UVM uses to define this
  // specific write function, tied to the specific uvm_analysis_imp port.
  function void write_txn_q(base_txn txn);

    shr.push_txn_q(txn);

  endfunction

endclass

// Static function in class to enable agent creation
// cfg object required to pass in because the build_phase depends on flitmode field
class cxl_nfi_agent_creator#(parameter NFI_W=3);

  static function cxl_nfi_agent#(NFI_W) spawn(string name, uvm_component parent, virtual cxl_nfi_agent_if#(NFI_W) vif, cxl_nfi_cfg cfg);

    cxl_nfi_agent#(NFI_W) agent;

    // Create agent
    agent = cxl_nfi_agent#(NFI_W)::type_id::create(name, parent);

    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(virtual cxl_nfi_agent_if#(NFI_W))::set(agent, "*", "vif", vif);
    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(cxl_nfi_cfg)::set(parent, $sformatf("%0s*",name), "cfg", cfg);

    return agent;

  endfunction

endclass

