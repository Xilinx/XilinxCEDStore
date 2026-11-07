class msix_user_txn extends base_txn;

  `uvm_object_utils(msix_user_txn)

  bit          print_vf_always;

  logic [ 2:0] user_func_num;
  logic [ 7:0] user_vfunc_num;
  logic        user_vfunc_active;
  logic        user_req;
  logic [10:0] user_vector_num;
  logic        user_grant;
  logic [ 1:0] user_operation;
  logic        user_error;

  function new(string name = "msix_user_txn");
    super.new(name);
    txn_type = "MSIX_USER_TXN";
  endfunction 

  virtual function void do_copy(uvm_object rhs);
    msix_user_txn t; 
    super.do_copy(rhs);
    if (!$cast(t,rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't extended from msix_user_txn")
    this.user_func_num     = t.user_func_num;
    this.user_vfunc_num    = t.user_vfunc_num;
    this.user_vfunc_active = t.user_vfunc_active;
    this.user_req          = t.user_req;
    this.user_vector_num   = t.user_vector_num;
    this.user_grant        = t.user_grant;
    this.user_operation    = t.user_operation;
    this.user_error        = t.user_error;
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("user_func_num",     user_func_num,     3,  UVM_DEC);
    if (user_vfunc_active || print_vf_always) begin
    printer.print_field("user_vfunc_num",    user_vfunc_num,    8,  UVM_DEC);
    printer.print_field("user_vfunc_active", user_vfunc_active, 1          );
    end
    printer.print_field("user_vector_num",   user_vector_num,   11, UVM_DEC);
    printer.print_field("user_req",          user_req,          1          );
    printer.print_field("user_grant",        user_grant,        1          );
    case (user_operation)
      2'b00 : printer.print_string("user_operation",  "'h0 (SEND_IRQ)");
      2'b01 : printer.print_string("user_operation",  "'h1 (CHK_PEND)");
      2'b10 : printer.print_string("user_operation",  "'h2 (CLR_PEND)");
    endcase
    printer.print_field("user_error",        user_error,        1          );
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    msix_user_txn t;
    do_compare = super.do_compare(rhs, comparer);
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_compare got a txn that wasn't extended from msix_user_txn")
    do_compare &= comparer.compare_field_int("user_func_num",     user_func_num,     t.user_func_num,     3);
    if (user_vfunc_active || t.user_vfunc_active) begin
    do_compare &= comparer.compare_field_int("user_vfunc_num",    user_vfunc_num,    t.user_vfunc_num,    8);
    do_compare &= comparer.compare_field_int("user_vfunc_active", user_vfunc_active, t.user_vfunc_active, 1);
    end
    do_compare &= comparer.compare_field_int("user_req",          user_req,          t.user_req,          1);
    do_compare &= comparer.compare_field_int("user_vector_num",   user_vector_num,   t.user_vector_num,   11);
    do_compare &= comparer.compare_field_int("user_grant",        user_grant,        t.user_grant,        1);
    do_compare &= comparer.compare_field_int("user_operation",    user_operation,    t.user_operation,    2);
    do_compare &= comparer.compare_field_int("user_error",        user_error,        t.user_error,        1);
  endfunction

endclass
