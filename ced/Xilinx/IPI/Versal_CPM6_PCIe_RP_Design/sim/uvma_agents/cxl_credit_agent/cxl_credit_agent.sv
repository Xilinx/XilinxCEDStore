// CXL Credit Agent 
// - Description
//   - This agent is intended as a companion agent to drive or monitor the
//     the credit interface as described of CPM6 for CXL.
class cxl_credit_agent extends base_agent #(
  .VIF (virtual cxl_credit_agent_if),
  .CFG (cxl_credit_cfg),
  .SHR (cxl_credit_share),
  .REQ (cxl_credit_bus_txn),
  .SQR (cxl_credit_sequencer),
  .DRV (cxl_credit_driver#(cxl_credit_bus_txn, cxl_credit_bus_txn, virtual cxl_credit_agent_if, cxl_credit_cfg, cxl_credit_share)),

  .MON (cxl_credit_monitor#(cxl_credit_cfg, virtual cxl_credit_agent_if, cxl_credit_bus_txn, cxl_credit_share)),
  .API (cxl_credit_api#(cxl_credit_sequencer))
);

  `uvm_component_utils(cxl_credit_agent)

  `uvm_analysis_imp_decl(_pool)
  `uvm_analysis_imp_decl(_pool_bus)

  // Users can use either port
  uvm_analysis_imp_pool     #(cxl_credit_txn,     cxl_credit_agent) impl_pool;
  uvm_analysis_imp_pool_bus #(cxl_credit_bus_txn, cxl_credit_agent) impl_pool_bus;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    impl_pool     = new("impl_pool",     this);
    impl_pool_bus = new("impl_pool_bus", this);
  endfunction 

  virtual task run_phase(uvm_phase phase);
    cxl_credit_pool_seq pool_seq;
    if (is_master && is_active) begin
      if (cfg.mst_use_credit_pool) begin
        pool_seq = cxl_credit_pool_seq::type_id::create("pool_seq");
        pool_seq.start(sqr);
      end
    end
  endtask

  function void write_pool(cxl_credit_txn t);
    case(t.info)
      "REQ"  : shr.req_credit_pool[t.credit[3]]+=t.convert2dec;
      "DATA" : shr.dat_credit_pool[t.credit[3]]+=t.convert2dec;
      "RSP"  : shr.rsp_credit_pool[t.credit[3]]+=t.convert2dec;
      default: `uvm_fatal(get_type_name(), $sformatf("Invalid t.info=%0s",t.info))
    endcase
  endfunction

  function void write_pool_bus(cxl_credit_bus_txn t);
    int req, dat, rsp;
    if (t.vld) begin
      // Option 1
      if (t.use_sideband) begin
        for (int ii=0; ii<2; ii++) begin
          shr.req_credit_pool[ii] += t.req_cred[ii];
          shr.dat_credit_pool[ii] += t.dat_cred[ii];
          shr.rsp_credit_pool[ii] += t.rsp_cred[ii];
        end
      end
      // Option 2
      else begin
        if (t.get_mem_credits(req, dat, rsp)) begin
          shr.req_credit_pool[1]+=req;
          shr.dat_credit_pool[1]+=dat;
          shr.rsp_credit_pool[1]+=rsp;
        end
        if (t.get_cch_credits(req, dat, rsp)) begin
          shr.req_credit_pool[0]+=req;
          shr.dat_credit_pool[0]+=dat;
          shr.rsp_credit_pool[0]+=rsp;
        end
      end
    end
  endfunction

endclass

// Static function in class to enable agent creation
class cxl_credit_agent_creator;

  static function cxl_credit_agent spawn(string name, uvm_component parent, virtual cxl_credit_agent_if vif, cxl_credit_cfg cfg = null);

    cxl_credit_agent agent;

    // Create agent
    agent = cxl_credit_agent::type_id::create(name, parent);

    // Create cfg object if not passed to function
    if (cfg == null) begin
      cfg = cxl_credit_cfg::type_id::create("cfg");
      agent.cfg = cfg;
    end

    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(virtual cxl_credit_agent_if)::set(agent, "*", "vif", vif);
    // Pass to lower objects, which will grab in their build phase
    uvm_config_db#(cxl_credit_cfg)::set(parent, $sformatf("%0s*",name), "cfg", cfg);

    return agent;
     
  endfunction

endclass
