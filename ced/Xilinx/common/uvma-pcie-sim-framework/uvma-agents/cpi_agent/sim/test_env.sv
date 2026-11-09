class test_env extends uvm_env;

  `uvm_component_utils(test_env)

  // Number of CPI channels
  localparam REQ = `NREQ;
  localparam DAT = `NDAT;
  localparam RSP = `NRSP;

  typedef virtual cpi_if #(REQ,DAT,RSP) vif_t;

  vif_t mst_vif, slv_vif;

  cpi_cfg mst_cfg, slv_cfg;

  cpi_agent #(REQ,DAT,RSP) mst, slv;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    /* CFG creation : default to A2F USP, change with macro F2A and/or DSP */
    // USP A2F and DSP F2A : mst=agent,  slv=fabric
    // USP F2A and DSP A2F : mst=fabric, slv=agent
    mst_cfg = cpi_cfg::type_id::create("mst_cfg");
    mst_cfg.uid               = "MST";
    mst_cfg.a2f               = `ifdef F2A 0   `else 1   `endif;
    mst_cfg.port              = `ifdef DSP DSP `else USP `endif; 
    mst_cfg.cxl_mem_sup       = 1;
    mst_cfg.cxl_cch_sup       = 1;
    // REQ
    mst_cfg.req_cmd_parity_en = 1;
    // DATA
    mst_cfg.data_cmd_parity_en = 1;
    mst_cfg.data_be_parity_en  = 1;
    // RSP
    mst_cfg.rsp_cmd_parity_en  = 1;
    $cast(slv_cfg, mst_cfg.clone);
    slv_cfg.component          = UVM_SLAVE;
    slv_cfg.uid                = "SLV";
    /* VIF handle */ 
    if (!uvm_config_db#(vif_t)::get(this, "", "v_mst_if", mst_vif))
      `uvm_fatal(get_type_name, "Couldn't get 'v_mst_vif' from cfg db")
    if (!uvm_config_db#(vif_t)::get(this, "", "v_slv_if", slv_vif))
      `uvm_fatal(get_type_name, "Couldn't get 'v_slv_if' from cfg db")
    /* AGENT creation */
    mst = cpi_agent_creator#(REQ,DAT,RSP)::spawn("mst", this, mst_vif, mst_cfg);
    slv = cpi_agent_creator#(REQ,DAT,RSP)::spawn("slv", this, slv_vif, slv_cfg);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    int shr     = 128;
    int mem_vc0 = 64;
    int cch_vc0 = 64;
    super.end_of_elaboration_phase(phase);
    // Allocate each interface 128 shared and 64 VC0 MEM/CACHE credits at init
    foreach (slv.req[ii])  if (slv.req[ii] != null) begin
      slv.req[ii].cfg.init_credit_shr       = shr;
      slv.req[ii].cfg.init_credit_ded[1][0] = mem_vc0;
      slv.req[ii].cfg.init_credit_ded[0][0] = cch_vc0;
    end
    foreach (slv.data[ii]) if (slv.data[ii] != null) begin
      slv.data[ii].cfg.init_credit_shr       = shr;
      slv.data[ii].cfg.init_credit_ded[1][0] = mem_vc0;
      slv.data[ii].cfg.init_credit_ded[0][0] = cch_vc0;
    end
    foreach (slv.rsp[ii]) if (slv.rsp[ii] != null) begin
      slv.rsp[ii].cfg.init_credit_shr       = shr;
      slv.rsp[ii].cfg.init_credit_ded[1][0] = mem_vc0;
      slv.rsp[ii].cfg.init_credit_ded[0][0] = cch_vc0;
    end
  endfunction


endclass
