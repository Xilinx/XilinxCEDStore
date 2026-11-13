class req_driver#(type REQ, type RSP, type VIF, type CFG, type SHR) extends base_driver#(REQ,RSP,VIF,CFG,SHR);

  `uvm_component_param_utils(req_driver#(REQ,RSP,VIF,CFG,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"req_driver#(",
                                   REQ::type_name,",",
                                   RSP::type_name,",",
                                   "VIF,",
                                   CFG::type_name,",",
                                   SHR::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  event     block_sampled; //enforce an ordering in driver to sample block first 
  
  bit [3:0] block;     //delayed block signal
  bit [3:0] crd_block; //delayed block signal

  bit       snap_req_txblock_crd_flow;
  bit       snap_req_block;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task drive_init();
    vif.agent_driven = 1;
    // Active slave drives txn blocking and credit returns
    if (cfg.is_slave) begin
      vif.i_req_block             <= '0;
      vif.i_req_rxcrd_shared      <= '0;
      vif.i_req_rxcrd_valid       <= '0;
      vif.i_req_rxcrd_protocol_id <= '0;
      vif.i_req_rxcrd_vc_id       <= '0;
    end
    // Master drives txns and credit return blocking
    else begin
      vif.i_req_is_valid         <= '0;
      vif.i_req_early_valid      <= '0;
      vif.i_req_protocol_id      <= '0;
      vif.i_req_vc_id            <= '0;
      vif.i_req_shared_credit    <= '0;
      vif.i_req_header           <= '0;
      vif.i_req_cmd_parity       <= '0;
      vif.i_req_spid             <= '0;
      vif.i_req_dpid             <= '0;
      vif.i_req_txblock_crd_flow <= '0;
    end
  endtask

  virtual task drive_item(REQ req);
    // Active slave drives txn blocking and credit returns
    if (cfg.is_slave) begin
      repeat(req.crd_ret_dly) @(vif.dcb);
      wait(block_sampled.triggered);
      while (crd_block[cfg.blocking]) begin
        @(vif.dcb); //must take block into account
        wait(block_sampled.triggered);
      end
      vif.dcb.i_req_block               <= req.req_block;
      vif.dcb.i_req_rxcrd_shared        <= req.req_rxcrd_shared;
      vif.dcb.i_req_rxcrd_valid         <= req.req_rxcrd_valid;
      if (req.req_rxcrd_valid) begin
        vif.dcb.i_req_rxcrd_protocol_id <= req.req_rxcrd_protocol_id;
        vif.dcb.i_req_rxcrd_vc_id       <= req.req_rxcrd_vc_id;
      end
      if (!req.crd_ret_dly && 
          (&{!vif.mcb.req_rxcrd_shared, req.req_rxcrd_shared} ||
           &{!vif.mcb.req_rxcrd_valid,  req.req_rxcrd_valid}  ||
           &{!vif.mcb.req_block,        req.req_block})
      ) @(vif.dcb); //avoid race condition
      @(vif.dcb);
      vif.dcb.i_req_block        <= 1'b0;
      vif.dcb.i_req_rxcrd_shared <= 1'b0;
      vif.dcb.i_req_rxcrd_valid  <= 1'b0;
    end 
    // Master drives txns and credit return blocking
    else begin
      wait(block_sampled.triggered);
      while (block[cfg.blocking]) begin
        @(vif.dcb); //must take block into account
        wait(block_sampled.triggered);
      end
      vif.dcb.i_req_is_valid <= req.req_is_valid;
      if (req.req_is_valid) begin
        vif.dcb.i_req_early_valid      <= req.req_early_valid;
        vif.dcb.i_req_protocol_id      <= req.req_protocol_id;
        vif.dcb.i_req_vc_id            <= req.req_vc_id;
        vif.dcb.i_req_shared_credit    <= req.req_shared_credit;
        vif.dcb.i_req_header           <= req.req_header;
        vif.dcb.i_req_cmd_parity       <= req.req_cmd_parity;
        vif.dcb.i_req_spid             <= req.req_spid;
        vif.dcb.i_req_dpid             <= req.req_dpid;
        vif.dcb.i_req_txblock_crd_flow <= req.req_txblock_crd_flow;
      end
      @(vif.dcb);
      if (!vif.mcb.req_is_valid && req.req_is_valid) @(vif.dcb); //avoid race condition
      vif.dcb.i_req_is_valid <= 1'b0;
    end 
  endtask

  virtual task run_phase(uvm_phase phase);
    fork
      // Active slave needs to keep track of credit return blocking
      if (cfg.is_slave) begin
        forever begin
          @(vif.mcb);
          snap_req_txblock_crd_flow = vif.mcb.req_txblock_crd_flow;
          crd_block = {crd_block[2:1], snap_req_txblock_crd_flow, 1'b0}; 
          ->block_sampled;
        end
      end
      // Master needs to keep track of delayed block
      if (cfg.is_master) begin
        forever begin
          @(vif.mcb);
          snap_req_block= vif.mcb.req_block;
          block = {block[2:1], snap_req_block, 1'b0}; 
          ->block_sampled;
        end
      end
    join_none
    super.run_phase(phase);
  endtask

endclass
