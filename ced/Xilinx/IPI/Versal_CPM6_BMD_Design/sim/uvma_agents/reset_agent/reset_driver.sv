class reset_driver#(type REQ,
                    type RSP,
                    type VIF,
                    type CFG,
                    type SHR) extends base_driver#(REQ,RSP,VIF,CFG,SHR);

  `uvm_component_param_utils(reset_driver#(REQ,RSP,VIF,CFG,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"reset_driver#(", 
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
    vif.i_reset <= cfg.active_val;
  endtask

  virtual task drive_item(REQ req);
    case (req.action)
      ASSERT : begin
        if (vif.reset == cfg.active_val) begin
          `uvm_warning("DRV_SAME_DIR", $sformatf("reset_driver is being requested to drive %0s to %0b when it already is %0b",cfg.uid, cfg.active_val, vif.reset))
        end 
        else begin
          if (!cfg.has_clk && (req.assert_type == SYNC))
            `uvm_fatal("RST_NO_CLK", $sformatf("reset %0s has been specified as having no clock but has been requested to assert synchronously", cfg.uid))
          if (req.assert_type == SYNC)
            vif.cb.i_reset <= cfg.active_val;
          else
            vif.i_reset <= cfg.active_val;
        end
      end
      DEASSERT : begin
        if (vif.reset != cfg.active_val) begin
          `uvm_warning("DRV_SAME_DIR", $sformatf("reset_driver is being requested to drive %0s to %0b when it already is %0b",cfg.uid, cfg.active_val, vif.reset))
        end 
        else begin
          if (!cfg.has_clk && (req.deassert_type == SYNC))
            `uvm_fatal("RST_NO_CLK", $sformatf("reset %0s has been specified as having no clock but has been requested to deassert synchronously", cfg.uid))
          if (req.deassert_type == SYNC)
            vif.cb.i_reset <= !cfg.active_val;
          else
            vif.i_reset <= !cfg.active_val;
        end
      end
      ASSERT_PULSE : begin
        if (vif.reset == cfg.active_val)
          `uvm_warning("DRV_PULSE_SAME_DIR", $sformatf("reset_driver is being requested to create an assert pulse for %0s when it is already asserted, this will now function as a deassert command",cfg.uid))
        else begin
          if (!cfg.has_clk && ((req.assert_type == SYNC) || (req.deassert_type == SYNC)))
            `uvm_fatal("RST_NO_CLK", $sformatf("reset %0s has been specified as having no clock but has been requested to either assert or deasert synchronously", cfg.uid))
          if (req.assert_type == SYNC)
            vif.cb.i_reset <= cfg.active_val;
          else
            vif.i_reset <= cfg.active_val;
          check_pulse_and_wait(req);
          if (req.deassert_type == SYNC)
            vif.cb.i_reset <= !cfg.active_val;
          else
            vif.i_reset <= !cfg.active_val;
        end
      end
      DEASSERT_PULSE : begin
        if (vif.reset != cfg.active_val)
          `uvm_warning("DRV_PULSE_SAME_DIR", $sformatf("reset_driver is being requested to create an deassert pulse for %0s when it is already deasserted, this will now function as a assert command",cfg.uid))
        else begin
          if (!cfg.has_clk && ((req.assert_type == SYNC) || (req.deassert_type == SYNC)))
            `uvm_fatal("RST_NO_CLK", $sformatf("reset %0s has been specified as having no clock but has been requested to either assert or deasert synchronously", cfg.uid))
          if (req.deassert_type == SYNC)
            vif.cb.i_reset <= !cfg.active_val;
          else
            vif.i_reset <= !cfg.active_val;
          check_pulse_and_wait(req);
          if (req.assert_type == SYNC)
            vif.cb.i_reset <= cfg.active_val;
          else
            vif.i_reset <= cfg.active_val;
        end
      end
      WENT_X, WENT_Z : `uvm_fatal("RST_BAD_DRV", $sformatf("reset %0s has been requested to go to %0s",cfg.uid, req.action.name))
    endcase 
  endtask

  virtual task check_pulse_and_wait(REQ req);
    if ((req.hold_cycles == 0) && (req.hold_time == 0))
      `uvm_fatal("RST_PULSE_NO_LEN", $sformatf("reset %0s has been directed to pulse, but no cycles or time have been specified", cfg.uid))
    else if (req.hold_cycles) 
      repeat(req.hold_cycles) @vif.cb;
    else
      #req.hold_time;
  endtask

endclass

