class reset_txn extends base_txn;

  `uvm_object_utils(reset_txn)

  reset_txn_type_enum  action;
  sync_async_type_enum assert_type;     //does it sync assert or no? 
  sync_async_type_enum deassert_type;   //does it sync deassert or no?
  int unsigned         hold_cycles = 0; //if it's a pulse, min cycles to hold (precedence)
  time                 hold_time = 0;   //if it's a pulse, min time to hold
  bit                  from_monitor = 0;

  function new(string name = "reset_txn");
    super.new(name);
    txn_type = "RESET_TXN";
  endfunction

  virtual function void do_copy(uvm_object rhs);
    reset_txn t;
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't extended from reset_txn")
    super.do_copy(rhs);
    assert_type   = t.assert_type; 
    deassert_type = t.deassert_type; 
    hold_cycles   = t.hold_cycles;
    hold_time     = t.hold_time;
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_string("action",   action.name);
    if (!from_monitor) begin
      case (action)
        ASSERT   : printer.print_string("assert_type",   assert_type.name);
        DEASSERT : printer.print_string("deassert_type", deassert_type.name);
        ASSERT_PULSE, DEASSERT_PULSE : begin
          printer.print_string("assert_type",   assert_type.name);
          printer.print_string("deassert_type", deassert_type.name);
          printer.print_int   ("hold_cycles",   hold_cycles, 32);
          printer.print_time  ("hold_time",     hold_time);
        end
      endcase
    end
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    reset_txn t;
    do_compare = super.do_compare(rhs, comparer);
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't extended from reset_txn")
    do_compare &= comparer.compare_field_int("action", action, t.action, $bits(action));  
  endfunction

endclass
