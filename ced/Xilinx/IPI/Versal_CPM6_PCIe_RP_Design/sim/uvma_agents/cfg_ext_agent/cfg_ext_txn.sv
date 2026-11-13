class cfg_ext_txn extends base_txn;

  `uvm_object_utils(cfg_ext_txn)

  bit        cfg_ext_read_received;
  bit        cfg_ext_write_received;
  bit [ 9:0] cfg_ext_register_number;
  bit [ 7:0] cfg_ext_function_number;
  bit [31:0] cfg_ext_write_data;
  bit [ 3:0] cfg_ext_write_byte_enable;
  bit [31:0] cfg_ext_read_data;
  bit        cfg_ext_read_data_valid;

  int unsigned rd_rsp_delay; //cycles

  function new(string name = "cfg_ext_txn");
    super.new(name);
    txn_type = "CFG_EXT_TXN";
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    if (info == "WRITE")
      print_write(printer);
    else if (info == "READ_REQ")
      print_read_req(printer);
    else if (info == "READ_RSP")
      print_read_rsp(printer);
    else
      `uvm_fatal(get_type_name, $sformatf("info of '%0s' is invalid", info))
  endfunction

  virtual function void print_write(uvm_printer printer);
    printer.print_int("cfg_ext_write_received",    cfg_ext_write_received,     1);
    printer.print_int("cfg_ext_register_number",   cfg_ext_register_number,   10);
    printer.print_int("cfg_ext_function_number",   cfg_ext_function_number,    8);
    printer.print_int("cfg_ext_write_data",        cfg_ext_write_data,        32);
    printer.print_int("cfg_ext_write_byte_enable", cfg_ext_write_byte_enable, 32);
  endfunction

  virtual function void print_read_req(uvm_printer printer);
    printer.print_int("cfg_ext_read_received",   cfg_ext_read_received,    1);
    printer.print_int("cfg_ext_register_number", cfg_ext_register_number, 10);
    printer.print_int("cfg_ext_function_number", cfg_ext_function_number,  8);
  endfunction

  virtual function void print_read_rsp(uvm_printer printer);
    printer.print_int("cfg_ext_read_data_valid", cfg_ext_read_data_valid,  1);
    printer.print_int("cfg_ext_read_data",       cfg_ext_read_data,       32);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    cfg_ext_txn t;
    super.do_copy(rhs);
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't extended from cfg_ext_txn")
    cfg_ext_read_received     = t.cfg_ext_read_received;
    cfg_ext_write_received    = t.cfg_ext_write_received;
    cfg_ext_register_number   = t.cfg_ext_register_number;
    cfg_ext_function_number   = t.cfg_ext_function_number;
    cfg_ext_write_data        = t.cfg_ext_write_data;
    cfg_ext_write_byte_enable = t.cfg_ext_write_byte_enable;
    cfg_ext_read_data         = t.cfg_ext_read_data;
    cfg_ext_read_data_valid   = t.cfg_ext_read_data_valid;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    cfg_ext_txn t;
    do_compare = super.do_compare(rhs, comparer);
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_compare got a txn that wasn't extended from cfg_ext_txn")
    do_compare &= comparer.compare_field_int("cfg_ext_read_received", 
                                             cfg_ext_read_received, 
                                             t.cfg_ext_read_received, 
                                             $bits(cfg_ext_read_received));
    do_compare &= comparer.compare_field_int("cfg_ext_write_received", 
                                             cfg_ext_write_received, 
                                             t.cfg_ext_write_received, 
                                             $bits(cfg_ext_write_received));
    do_compare &= comparer.compare_field_int("cfg_ext_register_number", 
                                             cfg_ext_register_number, 
                                             t.cfg_ext_register_number, 
                                             $bits(cfg_ext_register_number));
    do_compare &= comparer.compare_field_int("cfg_ext_function_number", 
                                             cfg_ext_function_number, 
                                             t.cfg_ext_function_number, 
                                             $bits(cfg_ext_function_number));
    do_compare &= comparer.compare_field_int("cfg_ext_write_data", 
                                             cfg_ext_write_data, 
                                             t.cfg_ext_write_data, 
                                             $bits(cfg_ext_write_data));
    do_compare &= comparer.compare_field_int("cfg_ext_write_byte_enable", 
                                             cfg_ext_write_byte_enable, 
                                             t.cfg_ext_write_byte_enable, 
                                             $bits(cfg_ext_write_byte_enable));
    do_compare &= comparer.compare_field_int("cfg_ext_read_data", 
                                             cfg_ext_read_data, 
                                             t.cfg_ext_read_data, 
                                             $bits(cfg_ext_read_data));
    do_compare &= comparer.compare_field_int("cfg_ext_read_data_valid", 
                                             cfg_ext_read_data_valid, 
                                             t.cfg_ext_read_data_valid, 
                                             $bits(cfg_ext_read_data_valid));
  endfunction

endclass
