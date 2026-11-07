class data_driver#(type REQ, type RSP, type VIF, type CFG, type SHR) extends base_driver#(REQ,RSP,VIF,CFG,SHR);

  `uvm_component_param_utils(data_driver#(REQ,RSP,VIF,CFG,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"data_driver#(",
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

  bit       snap_data_txblock_crd_flow;
  bit       snap_data_block;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task drive_init();
    vif.agent_driven = 1;
    // Active slave drives txn blocking and credit returns
    if (cfg.is_slave()) begin
      vif.i_data_block             <= '0;
      vif.i_data_rxcrd_shared      <= '0;
      vif.i_data_rxcrd_valid       <= '0;
      vif.i_data_rxcrd_protocol_id <= '0;
      vif.i_data_rxcrd_vc_id       <= '0;
    end
    // Master drives txn and credit return blocking
    else begin
      vif.i_data_is_valid           <= '0;
      vif.i_data_early_valid        <= '0;
      vif.i_data_protocol_id        <= '0;
      vif.i_data_vc_id              <= '0;
      vif.i_data_shared_credit      <= '0;
      vif.i_data_header             <= '0;
      vif.i_data_sz                 <= '0;
      vif.i_data_cmd_parity         <= '0;
      vif.i_data_spid               <= '0;
      vif.i_data_dpid               <= '0;
      vif.i_data_body               <= '0;
      vif.i_data_byte_enable        <= '0;
      vif.i_data_byte_enable_parity <= '0;
      vif.i_data_poison             <= '0;
      vif.i_data_parity             <= '0;
      vif.i_data_eop                <= '0;
      vif.i_data_txblock_crd_flow   <= '0;
      vif.i_data_emd                <= '0;
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
      vif.dcb.i_data_block               <= req.data_block;
      vif.dcb.i_data_rxcrd_shared        <= req.data_rxcrd_shared;
      vif.dcb.i_data_rxcrd_valid         <= req.data_rxcrd_valid;
      if (req.data_rxcrd_valid) begin
        vif.dcb.i_data_rxcrd_protocol_id <= req.data_rxcrd_protocol_id;
        vif.dcb.i_data_rxcrd_vc_id       <= req.data_rxcrd_vc_id;
      end
      if (!req.crd_ret_dly && 
          (&{!vif.mcb.data_rxcrd_shared, req.data_rxcrd_shared} ||
           &{!vif.mcb.data_rxcrd_valid,  req.data_rxcrd_valid}  ||
           &{!vif.mcb.data_block,        req.data_block})
      ) @(vif.dcb); //avoid race condition
      @(vif.dcb);
      vif.dcb.i_data_block        <= 1'b0;
      vif.dcb.i_data_rxcrd_shared <= 1'b0;
      vif.dcb.i_data_rxcrd_valid  <= 1'b0;
    end 
    // Master drives txn and credit return blocking
    else begin
      wait(block_sampled.triggered);
      while (block[cfg.blocking]) begin
        @(vif.dcb); //must take block into account
        wait(block_sampled.triggered);
      end
      vif.dcb.i_data_is_valid <= req.data_is_valid;
      if (req.data_is_valid) begin
        vif.dcb.i_data_early_valid        <= req.data_early_valid;
        vif.dcb.i_data_protocol_id        <= req.data_protocol_id;
        vif.dcb.i_data_vc_id              <= req.data_vc_id;
        vif.dcb.i_data_shared_credit      <= req.data_shared_credit;
        vif.dcb.i_data_header             <= req.data_header;
        vif.dcb.i_data_sz                 <= req.data_sz;
        vif.dcb.i_data_cmd_parity         <= req.data_cmd_parity;
        vif.dcb.i_data_spid               <= req.data_spid;
        vif.dcb.i_data_dpid               <= req.data_dpid;
        vif.dcb.i_data_body               <= req.data_body;
        vif.dcb.i_data_byte_enable        <= req.data_byte_enable;
        vif.dcb.i_data_byte_enable_parity <= req.data_byte_enable_parity;
        vif.dcb.i_data_poison             <= req.data_poison;
        vif.dcb.i_data_parity             <= req.data_parity;
        vif.dcb.i_data_eop                <= req.data_eop;
        vif.dcb.i_data_txblock_crd_flow   <= req.data_txblock_crd_flow;
        for (int ii=0; ii<cfg.emd_bits; ii++)
          vif.dcb.i_data_emd[ii]          <= req.data_emd[ii];
      end
      @(vif.dcb);
      if (!vif.mcb.data_is_valid && req.data_is_valid) @(vif.dcb); //avoid race condition
      vif.dcb.i_data_is_valid <= 1'b0;
    end 
  endtask

  virtual task run_phase(uvm_phase phase);
    fork
      // Active slave needs to keep track of credit return blocking
      if (cfg.is_slave()) begin
        forever begin
          @(vif.mcb);
          snap_data_txblock_crd_flow = vif.mcb.data_txblock_crd_flow;
          crd_block = {crd_block[2:1], snap_data_txblock_crd_flow, 1'b0}; 
          ->block_sampled;
        end
      end
      // Master needs to keep track of delayed block
      if (cfg.is_master()) begin
        forever begin
          @(vif.mcb);
          snap_data_block = vif.mcb.data_block;
          block = {block[2:1], snap_data_block, 1'b0}; 
          ->block_sampled;
        end
      end
    join_none
    super.run_phase(phase);
  endtask


endclass
