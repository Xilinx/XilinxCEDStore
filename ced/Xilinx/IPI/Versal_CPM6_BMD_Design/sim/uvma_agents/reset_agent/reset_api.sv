class reset_api#(type SQR) extends base_api#(SQR);

  `uvm_component_param_utils(reset_api#(SQR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"reset_api#(", SQR::type_name,")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task set_reset(reset_txn_type_enum action, sync_async_type_enum sync_control);

    reset_api_seq seq = reset_api_seq::type_id::create("seq");

    if (!(action inside {ASSERT, DEASSERT}))
      `uvm_fatal("BAD_API_ARG", $sformatf("invalid action %0s passed to set_reset, use ASSERT, DEASSERT, or call different API", action.name))
    else begin
      seq.action        = action;
      seq.assert_type   = sync_control;
      seq.deassert_type = sync_control;
    end

    seq.start(sqr);

  endtask

  virtual task set_reset_pulse_cycles(reset_txn_type_enum action, 
                                      sync_async_type_enum assert_type, 
                                      sync_async_type_enum deassert_type, 
                                      int unsigned cycles
  );

    reset_api_seq seq = reset_api_seq::type_id::create("seq");

    if (!(action inside {ASSERT_PULSE, DEASSERT_PULSE}))
      `uvm_fatal("BAD_API_ARG", $sformatf("invalid action %0s passed to set_reset_pulse_cycles, use ASSERT_PULSE, DEASSERT_PULSE, or call different API", action.name))
    else begin
      seq.action        = action;
      seq.assert_type   = assert_type;
      seq.deassert_type = deassert_type;
      seq.hold_cycles   = cycles;
      seq.start(sqr);
    end

  endtask

  virtual task set_reset_pulse_time(reset_txn_type_enum action, 
                                    sync_async_type_enum assert_type, 
                                    sync_async_type_enum deassert_type, 
                                    time t
  );

    reset_api_seq seq = reset_api_seq::type_id::create("seq");

    if (!(action inside {ASSERT_PULSE, DEASSERT_PULSE}))
      `uvm_fatal("BAD_API_ARG", $sformatf("invalid action %0s passed to set_reset_pulse_cycles, use ASSERT_PULSE, DEASSERT_PULSE, or call different API", action.name))
    else begin
      seq.action        = action;
      seq.assert_type   = assert_type;
      seq.deassert_type = deassert_type;
      seq.hold_time     = t;
      seq.start(sqr);
    end

  endtask

endclass
