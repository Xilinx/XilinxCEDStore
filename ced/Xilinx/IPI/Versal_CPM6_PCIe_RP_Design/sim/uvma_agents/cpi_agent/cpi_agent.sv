// CPI agent 
// - Description
//   - Serves as a wrapper agent for REQ/DATA/RSP sub-agents, with the number of
//     each sub-agents specified as the parameters in the agent definition. This
//     agent implements the specific CPI functionality of a port (upstream or
//     downstream) and a direction (A2F or F2A). Therefore, to fully implement a 
//     CPI interface, you will need to create two of these agents: one for A2F 
//     and one for F2A. Parameter P is described in the CPI Spec Rev1.0, 02/2023
//     and is only relevant when cfg.ide_epoch_support=1. Each sub-agent conforms
//     to CPI Spec Rev1.0, 02/2023. 
// - Restrictions
//   - Maximum of 8 sub-agents
// - Not supported
//   - See each sub-agent
class cpi_agent#(parameter bit [3:0] REQ, parameter bit [3:0] DATA, parameter bit [3:0] RSP, parameter P=1) extends uvm_agent;

  `uvm_component_param_utils(cpi_agent#(REQ,DATA,RSP,P))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("cpi_agent#(%0d,%0d,%0d,%0d)",REQ,DATA,RSP,P);
  virtual function string get_type_name(); return type_name; endfunction

  typedef virtual cpi_if#(REQ, DATA, RSP, P) cpi_vif_t;
  typedef cpi_vsequencer#(REQ, DATA, RSP)    cpi_vsqr_t;

  cpi_cfg    cfg;
  cpi_vif_t  vif;
  cpi_vsqr_t vsqr;

  uvm_event init_crd_done;

  /***** Child Agents *****/
  global_agent glbl;
  // - Cannot have a zero sized array, so can either have [-1:SZ-1] or [0:SZ] to
  //   enable SZ=0. VCS won't elaborate in the former, so must use the latter. 
  //   The upper index will always point to null.
  req_agent#($clog2(P))  req [0:REQ ];
  data_agent#($clog2(P)) data[0:DATA];
  rsp_agent#($clog2(P))  rsp [0:RSP ];

  uvm_analysis_port #(req_txn)  req_ap;
  uvm_analysis_port #(data_txn) data_ap;
  uvm_analysis_port #(rsp_txn)  rsp_ap;
  uvm_analysis_port #(base_txn) base_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    req_ap  = new("req_ap", this);
    data_ap = new("data_ap", this);
    rsp_ap  = new("rsp_ap", this);
    base_ap = new("base_ap", this);
    init_crd_done = new("init_crd_done");
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (cfg == null) begin
      if (!uvm_config_db#(cpi_cfg)::get(this, "", "cfg", cfg))
        `uvm_fatal(get_type_name, "Failed to get cfg object from config_db")
    end
    vsqr = cpi_vsqr_t::type_id::create("vsqr", this);
    glbl = global_agent_creator#(P)::spawn("glbl", this, vif.glbl); 
    glbl.cfg.activity             = cfg.activity;
    glbl.cfg.component            = cfg.component;
    glbl.cfg.a2f                  = cfg.a2f;
    glbl.cfg.viral_en             = cfg.viral_en;
    glbl.cfg.fatal_en             = cfg.fatal_en;
    glbl.cfg.skip_glbl_connection = cfg.skip_glbl_connection;
    for (int ii=0; ii<REQ; ii++) begin
      // Indexes into interface arrays must be constant; because it's a vif.if index, 
      // VCS will fatal, although Questa does not
      case (ii) 
        0 : req[ii] = req_agent_creator#($clog2(P))::spawn("req[0]", this, vif.req[0]);
        1 : req[ii] = req_agent_creator#($clog2(P))::spawn("req[1]", this, vif.req[1]);
        2 : req[ii] = req_agent_creator#($clog2(P))::spawn("req[2]", this, vif.req[2]);
        3 : req[ii] = req_agent_creator#($clog2(P))::spawn("req[3]", this, vif.req[3]);
        4 : req[ii] = req_agent_creator#($clog2(P))::spawn("req[4]", this, vif.req[4]);
        5 : req[ii] = req_agent_creator#($clog2(P))::spawn("req[5]", this, vif.req[5]);
        6 : req[ii] = req_agent_creator#($clog2(P))::spawn("req[6]", this, vif.req[6]);
        7 : req[ii] = req_agent_creator#($clog2(P))::spawn("req[7]", this, vif.req[7]);
      endcase
      // Copy settings to child agents
      req[ii].cfg.activity              = cfg.activity;
      req[ii].cfg.component             = cfg.component;
      req[ii].cfg.a2f                   = cfg.a2f;
      req[ii].cfg.port                  = cfg.port;
      req[ii].cfg.uid                   = $sformatf("CHANNEL_%0d",ii);
      req[ii].cfg.cxl_mem_sup           = cfg.cxl_mem_sup;
      req[ii].cfg.cxl_cch_sup           = cfg.cxl_cch_sup;
      req[ii].cfg.cxl_mem_emd_sup       = cfg.cxl_mem_emd_sup;
      req[ii].cfg.blocking              = cfg.blocking;
      req[ii].cfg.pbr_flit_mode_en      = cfg.pbr_flit_mode_en;
      req[ii].cfg.flit_mode_enc_en      = cfg.flit_mode_enc_en;
      req[ii].cfg.ide_epoch_support     = cfg.ide_epoch_support;
      req[ii].cfg.skip_credit_returns   = cfg.skip_credit_returns;
      req[ii].cfg.skip_credit_check     = cfg.skip_credit_check;
      req[ii].cfg.req_cmd_parity_en     = cfg.req_cmd_parity_en;
      req[ii].cfg.crd_ret_ctl           = cfg.req_crd_ret_ctl;
      req[ii].cfg.addl_txn_info         = cfg.req_addl_txn_info;
      req[ii].cfg.compare_addl_txn_info = cfg.req_compare_addl_txn_info;
    end
    for (int ii=0; ii<DATA; ii++) begin
      // Indexes into interface arrays must be constant; because it's a vif.if index, 
      // VCS will fatal, although Questa does not
      case (ii) 
        0 : data[ii] = data_agent_creator#($clog2(P))::spawn("data[0]", this, vif.data[0]);
        1 : data[ii] = data_agent_creator#($clog2(P))::spawn("data[1]", this, vif.data[1]);
        2 : data[ii] = data_agent_creator#($clog2(P))::spawn("data[2]", this, vif.data[2]);
        3 : data[ii] = data_agent_creator#($clog2(P))::spawn("data[3]", this, vif.data[3]);
        4 : data[ii] = data_agent_creator#($clog2(P))::spawn("data[4]", this, vif.data[4]);
        5 : data[ii] = data_agent_creator#($clog2(P))::spawn("data[5]", this, vif.data[5]);
        6 : data[ii] = data_agent_creator#($clog2(P))::spawn("data[6]", this, vif.data[6]);
        7 : data[ii] = data_agent_creator#($clog2(P))::spawn("data[7]", this, vif.data[7]);
      endcase
      // Copy settings to child agents
      data[ii].cfg.activity              = cfg.activity;
      data[ii].cfg.component             = cfg.component;
      data[ii].cfg.a2f                   = cfg.a2f;
      data[ii].cfg.port                  = cfg.port;
      data[ii].cfg.uid                   = $sformatf("CHANNEL_%0d",ii);
      data[ii].cfg.cxl_mem_sup           = cfg.cxl_mem_sup;
      data[ii].cfg.cxl_cch_sup           = cfg.cxl_cch_sup;
      data[ii].cfg.cxl_mem_emd_sup       = cfg.cxl_mem_emd_sup;
      data[ii].cfg.blocking              = cfg.blocking;
      data[ii].cfg.pbr_flit_mode_en      = cfg.pbr_flit_mode_en;
      data[ii].cfg.flit_mode_enc_en      = cfg.flit_mode_enc_en;
      data[ii].cfg.ide_epoch_support     = cfg.ide_epoch_support;
      data[ii].cfg.skip_credit_returns   = cfg.skip_credit_returns;
      data[ii].cfg.skip_credit_check     = cfg.skip_credit_check;
      data[ii].cfg.data_hdr_sep          = cfg.data_hdr_sep;
      data[ii].cfg.data_cmd_parity_en    = cfg.data_cmd_parity_en;
      data[ii].cfg.data_be_parity_en     = cfg.data_be_parity_en;
      data[ii].cfg.emd_bits              = cfg.emd_bits;
      data[ii].cfg.txfer_32b_en          = cfg.txfer_32b_en;
      data[ii].cfg.mem_dathdr_split      = cfg.mem_dathdr_split;
      data[ii].cfg.crd_ret_ctl           = cfg.dat_crd_ret_ctl;
      data[ii].cfg.addl_txn_info         = cfg.dat_addl_txn_info;
      data[ii].cfg.compare_addl_txn_info = cfg.dat_compare_addl_txn_info;
    end
    for (int ii=0; ii<RSP; ii++) begin
      // Indexes into interface arrays must be constant; because it's a vif.if index, 
      // VCS will fatal, although Questa does not
      case (ii) 
        0 : rsp[ii] = rsp_agent_creator#($clog2(P))::spawn("rsp[0]", this, vif.rsp[0]);
        1 : rsp[ii] = rsp_agent_creator#($clog2(P))::spawn("rsp[1]", this, vif.rsp[1]);
        2 : rsp[ii] = rsp_agent_creator#($clog2(P))::spawn("rsp[2]", this, vif.rsp[2]);
        3 : rsp[ii] = rsp_agent_creator#($clog2(P))::spawn("rsp[3]", this, vif.rsp[3]);
        4 : rsp[ii] = rsp_agent_creator#($clog2(P))::spawn("rsp[4]", this, vif.rsp[4]);
        5 : rsp[ii] = rsp_agent_creator#($clog2(P))::spawn("rsp[5]", this, vif.rsp[5]);
        6 : rsp[ii] = rsp_agent_creator#($clog2(P))::spawn("rsp[6]", this, vif.rsp[6]);
        7 : rsp[ii] = rsp_agent_creator#($clog2(P))::spawn("rsp[7]", this, vif.rsp[7]);
      endcase
      // Copy settings to child agents
      rsp[ii].cfg.activity              = cfg.activity;
      rsp[ii].cfg.component             = cfg.component;
      rsp[ii].cfg.a2f                   = cfg.a2f;
      rsp[ii].cfg.port                  = cfg.port;
      rsp[ii].cfg.uid                   = $sformatf("CHANNEL_%0d",ii);
      rsp[ii].cfg.cxl_mem_sup           = cfg.cxl_mem_sup;
      rsp[ii].cfg.cxl_cch_sup           = cfg.cxl_cch_sup;
      rsp[ii].cfg.blocking              = cfg.blocking;
      rsp[ii].cfg.pbr_flit_mode_en      = cfg.pbr_flit_mode_en;
      rsp[ii].cfg.flit_mode_enc_en      = cfg.flit_mode_enc_en;
      rsp[ii].cfg.ide_epoch_support     = cfg.ide_epoch_support;
      rsp[ii].cfg.skip_credit_returns   = cfg.skip_credit_returns;
      rsp[ii].cfg.skip_credit_check     = cfg.skip_credit_check;
      rsp[ii].cfg.rsp_cmd_parity_en     = cfg.rsp_cmd_parity_en;
      rsp[ii].cfg.crd_ret_ctl           = cfg.rsp_crd_ret_ctl;
      rsp[ii].cfg.addl_txn_info         = cfg.rsp_addl_txn_info;
      rsp[ii].cfg.compare_addl_txn_info = cfg.rsp_compare_addl_txn_info;
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    vsqr.glbl_sqr = glbl.sqr;
    for (int ii=0; ii<REQ; ii++) begin
      vsqr.req_sqr[ii] = req[ii].sqr;
      req[ii].shr.gshr = glbl.shr;
      req[ii].ap.connect(req_ap); 
      req[ii].base_ap.connect(base_ap);
    end
    for (int ii=0; ii<DATA; ii++) begin
      vsqr.data_sqr[ii] = data[ii].sqr;
      data[ii].shr.gshr = glbl.shr;
      data[ii].ap.connect(data_ap); 
      data[ii].base_ap.connect(base_ap);
    end
    for (int ii=0; ii<RSP; ii++) begin
      vsqr.rsp_sqr[ii] = rsp[ii].sqr;
      rsp[ii].shr.gshr = glbl.shr;
      rsp[ii].ap.connect(rsp_ap); 
      rsp[ii].base_ap.connect(base_ap);
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    if (cfg.is_slave && cfg.is_active) begin
      if (cfg.skip_credit_returns) begin
        `uvm_info(get_type_name, {"Initial credits have been configured to be skipped on CPI's ",cfg.a2f?"A2F":"F2A"," interface"}, UVM_LOW)
        return;
      end
      for (int aa=0; aa<REQ; aa++) begin
        fork
          automatic int xx = aa;
          req[xx].init_crd_done.wait_trigger();
        join_none
      end
      for (int bb=0; bb<DATA; bb++) begin
        fork
          automatic int yy = bb;
          data[yy].init_crd_done.wait_trigger();
        join_none
      end
      for (int cc=0; cc<RSP; cc++) begin
        fork
          automatic int zz = cc;
          rsp[zz].init_crd_done.wait_trigger();
        join_none
      end
      wait fork;
      `uvm_info(get_type_name, {"All credits have been returned on CPI's ",cfg.a2f?"A2F":"F2A"," interface"}, UVM_LOW)
      init_crd_done.trigger();
    end
  endtask

endclass

// Static class to enable agent creation
class cpi_agent_creator#(parameter bit [3:0] REQ, parameter bit [3:0] DATA, parameter bit [3:0] RSP, parameter P=1);

  static function cpi_agent#(REQ,DATA,RSP) spawn(string name, 
                                                 uvm_component parent, 
                                                 virtual cpi_if#(REQ,DATA,RSP,P) vif,
                                                 cpi_cfg cfg = null);
    cpi_agent#(REQ,DATA,RSP,P) agent;

    // Create agent
    agent = cpi_agent#(REQ,DATA,RSP,P)::type_id::create(name, parent);

    // Create cfg object if not passed to function
    if (cfg == null) begin
      cfg = cpi_cfg::type_id::create("cfg");
    end

    // Pass vif and cfg to agent
    agent.cfg = cfg;
    agent.vif = vif;

    return agent;
     
  endfunction

endclass
