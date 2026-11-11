class cfg_ext_driver#(type REQ, type RSP, type VIF, type CFG, type SHR) extends base_driver#(REQ,RSP,VIF,CFG,SHR);

  `uvm_component_param_utils(cfg_ext_driver#(REQ,RSP,VIF,CFG,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"cfg_ext_driver#(",
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

  virtual task drive_init;
    vif.cb.i_cfg_ext_read_received     <= '0;
    vif.cb.i_cfg_ext_write_received    <= '0;
    vif.cb.i_cfg_ext_register_number   <= '0;
    vif.cb.i_cfg_ext_function_number   <= '0;
    vif.cb.i_cfg_ext_write_data        <= '0;
    vif.cb.i_cfg_ext_write_byte_enable <= '0;
  endtask

  virtual task drive_item(REQ req);
    case(req.info)
      "WRITE"    : drive_write(req);
      "READ_REQ" : drive_read_req(req);
      "READ_RSP" : drive_read_rsp(req);
      default    : `uvm_fatal(get_type_name, $sformatf("req.info of '%0s' is invalid",req.info))
    endcase
  endtask

  // Master agent only
  virtual task drive_write(REQ req);
    @(vif.cb);
    vif.cb.i_cfg_ext_write_received    <= 1'b1;
    vif.cb.i_cfg_ext_register_number   <= req.cfg_ext_register_number;
    vif.cb.i_cfg_ext_function_number   <= req.cfg_ext_function_number;
    vif.cb.i_cfg_ext_write_data        <= req.cfg_ext_write_data;
    vif.cb.i_cfg_ext_write_byte_enable <= req.cfg_ext_write_byte_enable;
    @(vif.cb);
    vif.cb.i_cfg_ext_write_received    <= 1'b0;
  endtask

  // Master agent only
  virtual task drive_read_req(REQ req);
    @(vif.cb);
    vif.cb.i_cfg_ext_read_received   <= 1'b1;
    vif.cb.i_cfg_ext_register_number <= req.cfg_ext_register_number;
    vif.cb.i_cfg_ext_function_number <= req.cfg_ext_function_number;
    @(vif.cb);
    vif.cb.i_cfg_ext_read_received   <= 1'b0;
  endtask

  // Active slave agent only
  virtual task drive_read_rsp(REQ req);
    repeat(req.rd_rsp_delay) @(vif.cb);
    vif.cb.i_cfg_ext_read_data_valid <= 1'b1;
    vif.cb.i_cfg_ext_read_data       <= req.cfg_ext_read_data;
    @(vif.cb);
    vif.cb.i_cfg_ext_read_data_valid <= 1'b0;
  endtask

endclass
