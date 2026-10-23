class elbi_txn extends base_txn;

  `uvm_object_utils(elbi_txn)

  // metadata for this agent
  bit req, rsp;

  int          rsp_delay;

  logic        ext_lbc_override_en;
  logic [ 7:0] ext_lbc_ack;
  logic [63:0] ext_lbc_din;
  logic [31:0] lbc_ext_addr;
  logic [63:0] lbc_ext_dout;
  logic [ 7:0] lbc_ext_valid;
  logic [ 7:0] lbc_ext_cs;
  logic [ 7:0] lbc_ext_wr;
  logic [ 7:0] lbc_ext_rd;
  logic        lbc_ext_dbi_access;
  logic        lbc_ext_cxl_mbar0_access;
  logic        lbc_ext_rom_access;
  logic        lbc_ext_io_access;
  logic [ 2:0] lbc_ext_bar_num;
  logic [ 7:0] lbc_ext_vfunc_num;
  logic        lbc_ext_vfunc_active;

  function new(string name = "elbi_txn");
    super.new(name);
    txn_type = "ELBI_TXN";
  endfunction

  virtual function void do_print(uvm_printer printer);
    string msg;
    super.do_print(printer);
    if (req) begin
      msg = lbc_ext_cs ? "EXTERNAL REQUEST" : "INTERNAL REQUEST";
      printer.print_string("info",  msg);
      printer.m_scope.down(""); //increase indentation
      printer.print_int("lbc_ext_valid",            lbc_ext_valid,            8);
      printer.print_int("lbc_ext_cs",               lbc_ext_cs,               8);
      printer.print_int("lbc_ext_wr",               lbc_ext_wr,               8);
      printer.print_int("lbc_ext_rd",               lbc_ext_rd,               8);
      printer.print_int("lbc_ext_addr",             lbc_ext_addr,             32);
      printer.print_int("lbc_ext_dout",             lbc_ext_dout,             64);
      printer.print_int("lbc_ext_bar_num",          lbc_ext_bar_num,          3);
      printer.print_int("lbc_ext_vfunc_active",     lbc_ext_vfunc_active,     1);
      printer.print_int("lbc_ext_vfunc_num",        lbc_ext_vfunc_num,        8);
      printer.print_int("lbc_ext_dbi_access",       lbc_ext_dbi_access,       1);
      printer.print_int("lbc_ext_cxl_mbar0_access", lbc_ext_cxl_mbar0_access, 1);
      printer.print_int("lbc_ext_rom_access",       lbc_ext_rom_access,       1);
      printer.print_int("lbc_ext_io_access",        lbc_ext_io_access,        1);
      printer.m_scope.up(); //increase indentation
    end
    if (rsp) begin
      printer.print_string("info", "RESPONSE");
      printer.m_scope.down(""); //increase indentation
      printer.print_int("ext_lbc_ack",         ext_lbc_ack,          8);
      printer.print_int("ext_lbc_din",         ext_lbc_din,          64);
      printer.print_int("ext_lbc_override_en", ext_lbc_override_en,  1);
      printer.m_scope.up(); //increase indentation
    end
  endfunction

  virtual function void do_copy(uvm_object rhs);
    elbi_txn t;
    super.do_copy(rhs);
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't extended from elbi_txn")
    {req, rsp}               = {t.req, t.rsp};
    ext_lbc_override_en      = t.ext_lbc_override_en;
    ext_lbc_ack              = t.ext_lbc_ack;
    ext_lbc_din              = t.ext_lbc_din;
    lbc_ext_addr             = t.lbc_ext_addr;
    lbc_ext_dout             = t.lbc_ext_dout;
    lbc_ext_valid            = t.lbc_ext_valid;
    lbc_ext_cs               = t.lbc_ext_cs;
    lbc_ext_wr               = t.lbc_ext_wr;
    lbc_ext_rd               = t.lbc_ext_rd;
    lbc_ext_dbi_access       = t.lbc_ext_dbi_access;
    lbc_ext_cxl_mbar0_access = t.lbc_ext_cxl_mbar0_access;
    lbc_ext_rom_access       = t.lbc_ext_rom_access;
    lbc_ext_io_access        = t.lbc_ext_io_access;
    lbc_ext_bar_num          = t.lbc_ext_bar_num;
    lbc_ext_vfunc_num        = t.lbc_ext_vfunc_num;
    lbc_ext_vfunc_active     = t.lbc_ext_vfunc_active;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    elbi_txn t;
    do_compare = super.do_compare(rhs, comparer);
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_compare got a txn that wasn't extended from elbi_txn")
    // Check some error conditions
    if (!req && !rsp)
      `uvm_error(get_type_name, "this txn should have req or rsp set")
    if (!t.req && !t.rsp)
      `uvm_error(get_type_name, "argument txn should have req or rsp set")
    // Request
    if (req^t.req)
      `uvm_warning(get_type_name, "Comparing txns that both don't have matching req fields")
    if (req) begin
      do_compare &= comparer.compare_field_int("lbc_ext_valid",     lbc_ext_valid,     t.lbc_ext_valid,     8);
      do_compare &= comparer.compare_field_int("lbc_ext_cs",        lbc_ext_cs,        t.lbc_ext_cs,        8);
      do_compare &= comparer.compare_field_int("lbc_ext_wr",        lbc_ext_wr,        t.lbc_ext_wr,        8);
      do_compare &= comparer.compare_field_int("lbc_ext_rd",        lbc_ext_rd,        t.lbc_ext_rd,        8);
      do_compare &= comparer.compare_field_int("lbc_ext_addr",      lbc_ext_addr,      t.lbc_ext_addr,     32);
      do_compare &= comparer.compare_field_int("lbc_ext_dout",      lbc_ext_dout,      t.lbc_ext_dout,     64);
      do_compare &= comparer.compare_field_int("lbc_ext_bar_num",   lbc_ext_bar_num,   t.lbc_ext_bar_num,   3);
      do_compare &= comparer.compare_field_int("lbc_ext_vfunc_num", lbc_ext_vfunc_num, t.lbc_ext_vfunc_num, 8);
      do_compare &= comparer.compare_field_int(
        "lbc_ext_vfunc_active", lbc_ext_vfunc_active, t.lbc_ext_vfunc_active, 1);
      do_compare &= comparer.compare_field_int(
        "lbc_ext_dbi_access", lbc_ext_dbi_access, t.lbc_ext_dbi_access, 1);
      do_compare &= comparer.compare_field_int(
        "lbc_ext_cxl_mbar0_access", lbc_ext_cxl_mbar0_access, t.lbc_ext_cxl_mbar0_access, 1);
      do_compare &= comparer.compare_field_int(
        "lbc_ext_rom_access", lbc_ext_rom_access, t.lbc_ext_rom_access, 1);
      do_compare &= comparer.compare_field_int(
        "lbc_ext_io_access",  lbc_ext_io_access, t.lbc_ext_io_access, 1);
    end
    // Response
    if (rsp^t.rsp)
      `uvm_warning(get_type_name, "Comparing txns that both don't have matching rsp fields")
    if (rsp) begin
      do_compare &= comparer.compare_field_int("ext_lbc_ack", ext_lbc_ack, t.ext_lbc_ack,  8);
      do_compare &= comparer.compare_field_int("ext_lbc_din", ext_lbc_din, t.ext_lbc_din, 64);
      do_compare &= comparer.compare_field_int(
        "ext_lbc_override_en", ext_lbc_override_en, t.ext_lbc_override_en, 1);
    end
  endfunction

endclass
