class rsp_driver#(type REQ, type RSP, type VIF, type CFG, type SHR) extends base_driver#(REQ,RSP,VIF,CFG,SHR);

  `uvm_component_param_utils(rsp_driver#(REQ,RSP,VIF,CFG,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"rsp_driver#(",
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

  bit       snap_rsp_txblock_crd_flow;
  bit       snap_rsp_block;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task drive_init();
    vif.agent_driven = 1;
    // Active slave drives txn blocking and credit returns
    if (cfg.is_slave()) begin
      vif.i_rsp_block             <= '0;
      vif.i_rsp_rxcrd_shared      <= '0;
      vif.i_rsp_rxcrd_valid       <= '0;
      vif.i_rsp_rxcrd_protocol_id <= '0;
      vif.i_rsp_rxcrd_vc_id       <= '0;
    end
    // Master drives txns and credit return blocking
    else begin
      vif.i_rsp_is_valid         <= '0;
      vif.i_rsp_early_valid      <= '0;
      vif.i_rsp_protocol_id      <= '0;
      vif.i_rsp_vc_id            <= '0;
      vif.i_rsp_shared_credit    <= '0;
      vif.i_rsp_header           <= '0;
      vif.i_rsp_cmd_parity       <= '0;
      vif.i_rsp_spid             <= '0;
      vif.i_rsp_dpid             <= '0;
      vif.i_rsp_txblock_crd_flow <= '0;
    end
  endtask

  virtual task drive_item(REQ req);
    // Active slave drives txn blocking and credit returns
    if (cfg.is_slave()) begin
      repeat(req.crd_ret_dly) @(vif.dcb);
      wait(block_sampled.triggered);
      while (crd_block[cfg.blocking]) begin
        @(vif.dcb); //must take block into account
        wait(block_sampled.triggered);
      end
      vif.dcb.i_rsp_block               <= req.rsp_block;
      vif.dcb.i_rsp_rxcrd_shared        <= req.rsp_rxcrd_shared;
      vif.dcb.i_rsp_rxcrd_valid         <= req.rsp_rxcrd_valid;
      if (req.rsp_rxcrd_valid) begin
        vif.dcb.i_rsp_rxcrd_protocol_id <= req.rsp_rxcrd_protocol_id;
        vif.dcb.i_rsp_rxcrd_vc_id       <= req.rsp_rxcrd_vc_id;
      end
      if (!req.crd_ret_dly && 
          (&{!vif.mcb.rsp_rxcrd_shared, req.rsp_rxcrd_shared} ||
           &{!vif.mcb.rsp_rxcrd_valid,  req.rsp_rxcrd_valid}  ||
           &{!vif.mcb.rsp_block,        req.rsp_block})
      ) @(vif.dcb); //avoid race condition
      @(vif.dcb);
      vif.dcb.i_rsp_block        <= '0;
      vif.dcb.i_rsp_rxcrd_shared <= '0;
      vif.dcb.i_rsp_rxcrd_valid  <= '0;
    end 
    // Master drives txns and credit return blocking
    else begin
      wait(block_sampled.triggered);
      while (block[cfg.blocking]) begin
        @(vif.dcb); //must take block into account
        wait(block_sampled.triggered);
      end
      vif.dcb.i_rsp_is_valid <= req.rsp_is_valid;
      if (req.rsp_is_valid) begin
        vif.dcb.i_rsp_early_valid      <= req.rsp_early_valid;
        vif.dcb.i_rsp_protocol_id      <= req.rsp_protocol_id;
        vif.dcb.i_rsp_vc_id            <= req.rsp_vc_id;
        vif.dcb.i_rsp_shared_credit    <= req.rsp_shared_credit;
        vif.dcb.i_rsp_header           <= req.rsp_header;
        vif.dcb.i_rsp_cmd_parity       <= req.rsp_cmd_parity;
        vif.dcb.i_rsp_spid             <= req.rsp_spid;
        vif.dcb.i_rsp_dpid             <= req.rsp_dpid;
        vif.dcb.i_rsp_txblock_crd_flow <= req.rsp_txblock_crd_flow;
      end
      @(vif.dcb);
      if (!vif.mcb.rsp_is_valid && req.rsp_is_valid) @(vif.dcb); //avoid race condition
      vif.dcb.i_rsp_is_valid <= '0;
    end 
  endtask

  virtual task run_phase(uvm_phase phase);
    fork
      // Active slave needs to keep track of credit return blocking
      if (cfg.is_slave()) begin
        forever begin
          @(vif.mcb);
          snap_rsp_txblock_crd_flow = vif.mcb.rsp_txblock_crd_flow;
          crd_block = {crd_block, snap_rsp_txblock_crd_flow, 1'b0}; 
          ->block_sampled;
        end
      end
      // Master needs to keep track of delayed block
      if (cfg.is_master()) begin
        forever begin
          @(vif.mcb);
          snap_rsp_block= vif.mcb.rsp_block;
          block = {block, snap_rsp_block, 1'b0}; 
          ->block_sampled;
        end
      end
    join_none
    super.run_phase(phase);
  endtask

endclass
