class full_test extends uvm_test;

  `uvm_component_utils(full_test)

          cxl_credit_agent agnt;
  virtual cxl_credit_agent_if    vif;

  print_sb printer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    printer = print_sb#()::type_id::create("printer", this);
    if (!uvm_config_db#(virtual cxl_credit_agent_if)::get(this, "", "vif", vif))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'vif' from cfg db") 
    agnt = cxl_credit_agent_creator::spawn("agnt", this, vif); 
    agnt.cfg.component           = UVM_MASTER;
    agnt.cfg.activity            = UVM_ACTIVE;
    agnt.cfg.mst_use_credit_pool = 1'b1;
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agnt.base_ap.connect(printer.analysis_export);
  endfunction

  virtual task main_phase(uvm_phase phase);
    int mem[0:2];
    int cch[0:2];
    int exp_sum_req[1:0];
    int exp_sum_dat[1:0];
    int exp_sum_rsp[1:0];
    phase.raise_objection(this);
    // Use API
    `uvm_info("TSTINFO", "Sending 64/32/16 CXL.mem req/dat/rsp credits from API", UVM_NONE)
    agnt.api.issue_mem_txns(64, 32, 16);
    #10ns;
    `uvm_info("TSTINFO", "Sending 2/4/8 CXL.cache req/dat/rsp credits from API", UVM_NONE)
    agnt.api.issue_cch_txns( 2,  4,  8);
    #10ns;
    mem = '{$urandom_range(1,64), $urandom_range(1,64), $urandom_range(1,64)};
    cch = '{$urandom_range(1,64), $urandom_range(1,64), $urandom_range(1,64)};
    `uvm_info("TSTINFO", $sformatf("Sending %0d/%0d/%0d CXL.mem and %0d/%0d/%0d CXL.cache req/dat/rsp credits from API",mem[0],mem[1],mem[2],cch[0],cch[1],cch[2]), UVM_NONE)
    agnt.api.issue_txns(
      mem[0], mem[1], mem[2],  //req/dat/rsp
      cch[0], cch[1], cch[2]); //req/dat/rsp
    #10ns;
    exp_sum_req = '{64+mem[0], 2+cch[0]};
    exp_sum_dat = '{32+mem[1], 4+cch[1]};
    exp_sum_rsp = '{16+mem[2], 8+cch[2]};
    // Use pool seq
    mem = '{$urandom_range(65,96), $urandom_range(65,96), $urandom_range(65,96)};
    cch = '{$urandom_range(65,96), $urandom_range(65,96), $urandom_range(65,96)};
    `uvm_info("TSTINFO", $sformatf("Sending %0d/%0d/%0d CXL.mem and %0d/%0d/%0d CXL.cache req/dat/rsp credits from pool sequence",mem[0],mem[1],mem[2],cch[0],cch[1],cch[2]), UVM_NONE)
    agnt.shr.req_credit_pool = '{mem[0], cch[0]};
    agnt.shr.dat_credit_pool = '{mem[1], cch[1]};
    agnt.shr.rsp_credit_pool = '{mem[2], cch[2]};
    exp_sum_req = '{exp_sum_req[1]+mem[0], exp_sum_req[0]+cch[0]};
    exp_sum_dat = '{exp_sum_dat[1]+mem[1], exp_sum_dat[0]+cch[1]};
    exp_sum_rsp = '{exp_sum_rsp[1]+mem[2], exp_sum_rsp[0]+cch[2]};
    while(agnt.shr.any_credits) #10ns;
    #10ns;
    `uvm_info("TSTINFO", $sformatf("Total Sent CXL.mem REQ/DAT/RSP: %0d/%0d/%0d",exp_sum_req[1],exp_sum_dat[1],exp_sum_rsp[1]), UVM_NONE)
    `uvm_info("TSTINFO", $sformatf("Total Sent CXL.cch REQ/DAT/RSP: %0d/%0d/%0d",exp_sum_req[0],exp_sum_dat[0],exp_sum_rsp[0]), UVM_NONE)
    phase.drop_objection(this);
  endtask

endclass
