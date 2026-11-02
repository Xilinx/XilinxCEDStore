class global_txn extends base_txn;

  `uvm_object_utils(global_txn)

  logic txcon_req;
  logic rxcon_ack;
  logic rxdiscon_nack;
  logic rx_empty;
  logic fatal;
  logic viral;

  bit [4:0]     rsp_delay;
  conn_state_t  conn_state;
  // Mutually exclusive; type of txn
  bit           init;
  bit           ras;
  bit           empty;

  function new(string name = "global_txn");
    super.new(name);
    txn_type = "GLOBAL_TXN";
  endfunction

  virtual function void do_copy(uvm_object rhs);
    global_txn t;
    super.do_copy(rhs);
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't extended from global_txn")
    txcon_req     = t.txcon_req;
    rxcon_ack     = t.rxcon_ack;
    rxdiscon_nack = t.rxdiscon_nack;
    rx_empty      = t.rx_empty;
    fatal         = t.fatal;
    viral         = t.viral;
    rsp_delay     = t.rsp_delay;
    conn_state    = t.conn_state;
    init          = t.init;
    ras           = t.ras;
    empty         = t.empty;
  endfunction

  function void do_print(uvm_printer printer);
    super.do_print(printer);
    if ({init, ras} == 2'b10) begin
      printer.print_int    ("txcon_req",     txcon_req, 1);
      printer.print_int    ("rxcon_ack",     rxcon_ack, 1);
      printer.print_int    ("rxdiscon_nack", rxdiscon_nack, 1);
      printer.print_int    ("rx_empty",      rx_empty, 1);
      printer.print_string ("conn_state",    conn_state.name);
    end
    else if ({init, ras} == 2'b01) begin
      printer.print_int ("fatal", fatal, 1);
      printer.print_int ("viral", viral, 1);
    end
    else
      `uvm_fatal(get_type_name, "Invalid txn setting, must have exclusively init or ras set")
  endfunction

endclass
