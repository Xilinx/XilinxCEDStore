class global_driver#(type REQ, type RSP, type VIF, type CFG, type SHR) extends base_driver#(REQ,RSP,VIF,CFG,SHR);

  `uvm_component_param_utils(global_driver#(REQ,RSP,VIF,CFG,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"global_driver#(",
                                   REQ::type_name,",",
                                   RSP::type_name,",",
                                   "VIF,",
                                   CFG::type_name,",",
                                   SHR::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task drive_init();
    if (cfg.is_slave) begin
      vif.i_rxcon_ack     <= 1'b0;
      vif.i_rxdiscon_nack <= 1'b0;
      vif.i_rx_empty      <= 1'b0;
    end
    else begin
      vif.i_txcon_req <= 1'b0;
      vif.i_fatal     <= 1'b0;
      vif.i_viral     <= 1'b0;
    end
  endtask

  virtual task drive_item(REQ req);
    if (cfg.is_slave) begin
      if (req.empty)
        vif.cb.i_rx_empty <= req.rx_empty;
      else begin
        repeat (req.rsp_delay) @vif.cb;
        vif.cb.i_rxcon_ack     <= req.rxcon_ack;
        vif.cb.i_rxdiscon_nack <= req.rxdiscon_nack;
      end
    end
    else begin
      if ({req.init, req.ras} == 2'b10)
        vif.cb.i_txcon_req <= req.txcon_req;
      else if ({req.init, req.ras} == 2'b01) begin
        vif.cb.i_fatal <= req.fatal;
        vif.cb.i_viral <= req.viral;
      end
      else
        `uvm_fatal(get_type_name, "Request to drive an invalid class of txn occurred")
    end 
  endtask

endclass
