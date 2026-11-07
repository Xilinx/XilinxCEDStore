class rsp_txn extends base_txn;

  `uvm_object_utils(rsp_txn)

  // Control printing 
  bit rsp_cmd_parity_en;
  bit pbr_flit_mode_en;
  bit flit_mode_enc_en;

  // Mutually exclusive; type of txn
  bit txfer;
  bit credrtn;

  // If slave receives a txn when it has sent zero credits, mark
  bit credit_underflow;

  // Responders need to return credits when they're consumed, a 
  // sequence can randomize and constrain this as it sees fit 
  byte unsigned crd_ret_dly;

  // VALID
  logic        rsp_is_valid;
  logic        rsp_block;
  logic        rsp_early_valid;
  // FLOW_C
  logic  [3:0] rsp_protocol_id;
  logic  [3:0] rsp_vc_id;
  logic        rsp_shared_credit;
  // HDR
  hdr_u        rsp_header;
  logic        rsp_cmd_parity;
  logic [11:0] rsp_spid;
  logic [11:0] rsp_dpid;
  // CREDIT
  logic        rsp_rxcrd_valid;
  logic  [3:0] rsp_rxcrd_protocol_id;
  logic  [3:0] rsp_rxcrd_vc_id;
  logic        rsp_rxcrd_shared;
  logic        rsp_txblock_crd_flow;

  function new(string name = "rsp_txn");
    super.new(name);
    txn_type = "RSP_TXN";
  endfunction

  // -----------------------------------------------------
  // calc_<method> = calculate and return that field
  // -----------------------------------------------------
  virtual function logic calc_cmd_parity();
    return(^{rsp_header, rsp_spid, rsp_dpid});
  endfunction
  // -----------------------------------------------------

  // -----------------------------------------------------
  // set_<method> = set the internal field
  // -----------------------------------------------------
  virtual function void set_cmd_parity(bit err = 1'b0);
    rsp_cmd_parity = (err ^ calc_cmd_parity);
  endfunction
  // -----------------------------------------------------

  virtual function void do_print(uvm_printer printer);
    string val;
    super.do_print(printer);
    if ({txfer, credrtn} == 2'b10) begin
      printer.print_int   ("rsp_is_valid",       rsp_is_valid,    1);
      printer.print_int   ("rsp_block",          rsp_block,       1);
      printer.print_int   ("rsp_early_valid",    rsp_early_valid, 1);
      case (rsp_protocol_id)
        4'b1000 : val = "'b1000 (US Port CXL.cache)";
        4'b1001 : val = "'b1001 (US Port CXL.mem)";
        4'b1010 : val = "'b1010 (DS Port CXL.cache)";
        4'b1011 : val = "'b1011 (DS Port CXL.mem)";
        default : val = "INVALID";
      endcase
      printer.print_string("rsp_protocol_id",   val                  );
      printer.print_int   ("rsp_vc_id",         rsp_vc_id,          4);
      printer.print_int   ("rsp_shared_credit", rsp_shared_credit,  1);
      if (!rsp_cmd_parity_en) val = $sformatf("'%0b (DISABLED)",rsp_cmd_parity);
      else                    val = $sformatf("'%0b",           rsp_cmd_parity);
      printer.print_string("rsp_cmd_parity",    val                  );
      if (pbr_flit_mode_en) begin
        printer.print_int ("rsp_spid",          rsp_spid,          12);
        printer.print_int ("rsp_dpid",          rsp_dpid,          12);
      end
      printer.print_int   ("rsp_header",        rsp_header,        $size(rsp_header));
      printer.m_scope.down(""); //increase indentation
      case (rsp_protocol_id)
/*USP $*/  4'b1000 : begin
                       if (info2 == "A2F") begin
                         printer.print_int("opcode",    rsp_header.usp.a2fc.opcode,   4);
                         printer.print_int("cqid",      rsp_header.usp.a2fc.cqid,     12);
                         printer.print_int("rsp_pre",   rsp_header.usp.a2fc.rsp_pre,  2);
                         printer.print_int("rsvd",      rsp_header.usp.a2fc.rsvd18,   1);
                         printer.print_int("rspdata",   rsp_header.usp.a2fc.rspdata,  12);
                         printer.print_int("cacheid",   rsp_header.usp.a2fc.cacheid,  4);
                         if (flit_mode_enc_en) begin
                           case(rsp_header.usp.a2fc.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",rsp_header.usp.a2fc.flitmode));
                         end
                         if (pbr_flit_mode_en) begin
                           printer.print_int("epochvalid", rsp_header.usp.a2fc.epochvalid, 1);
                           printer.print_int("epochid",    rsp_header.usp.a2fc.epochid,    1);
                           printer.print_int("portid",     rsp_header.usp.a2fc.portid,     $size(rsp_header.usp.a2fc.portid));
                         end
                       end
                       else if (info2 == "F2A") begin
                         printer.print_int("opcode",  rsp_header.usp.f2ac.opcode,   5);
                         printer.print_int("rsvd",    rsp_header.usp.f2ac.rsvd6to5, 2);
                         printer.print_int("uqid",    rsp_header.usp.f2ac.uqid,     12);
                         if (flit_mode_enc_en) begin
                           case(rsp_header.usp.f2ac.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",rsp_header.usp.f2ac.flitmode));
                         end
                       end
                       else
                         `uvm_error(get_type_name, "Couldn't determine the type of txn this was; set info2 to 'A2F' or 'F2A'")
                     end
/*USP MEM*/4'b1001 : begin
                       if (info2 == "A2F") begin
                         printer.print_int("opcode",  rsp_header.usp.a2fm.opcode,  4);
                         printer.print_int("biid",    rsp_header.usp.a2fm.biid,    12);
                         printer.print_int("bitag",   rsp_header.usp.a2fm.bitag,   12);
                         printer.print_int("lowaddr", rsp_header.usp.a2fm.lowaddr, 2);
                         if (flit_mode_enc_en) begin
                           case(rsp_header.usp.a2fm.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",rsp_header.usp.a2fm.flitmode));
                         end
                         if (pbr_flit_mode_en) begin
                           printer.print_int("epochvalid", rsp_header.usp.a2fm.epochvalid, 1);
                           printer.print_int("epochid",    rsp_header.usp.a2fm.epochid,    1);
                           printer.print_int("portid",     rsp_header.usp.a2fm.portid,     $size(rsp_header.usp.a2fm.portid));
                         end
                       end
                       else if (info2 == "F2A") begin
                         printer.print_int("opcode",     rsp_header.usp.f2am.opcode,     3);
                         printer.print_int("metafield",  rsp_header.usp.f2am.metafield,  2);
                         printer.print_int("metavalue",  rsp_header.usp.f2am.metavalue,  2);
                         printer.print_int("tag",        rsp_header.usp.f2am.tag,        16);
                         printer.print_int("ldid",       rsp_header.usp.f2am.ldid,       4);
                         printer.print_int("devload",    rsp_header.usp.f2am.devload,    2);
                         if (flit_mode_enc_en) begin
                           case(rsp_header.usp.f2am.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",rsp_header.usp.f2am.flitmode));
                         end
                       end
                       else
                         `uvm_error(get_type_name, "Couldn't determine the type of txn this was; set info2 to 'A2F' or 'F2A'")
                     end
/*DSP $*/  4'b1010 : begin
                       if (info2 == "A2F") begin
                         printer.print_int("opcode",  rsp_header.dsp.a2fc.opcode,   5);
                         printer.print_int("rsvd",    rsp_header.dsp.a2fc.rsvd6to5, 2);
                         printer.print_int("uqid",    rsp_header.dsp.a2fc.uqid,     12);
                         if (flit_mode_enc_en) begin
                           case(rsp_header.dsp.a2fc.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",rsp_header.dsp.a2fc.flitmode));
                         end
                         if (pbr_flit_mode_en) begin
                           printer.print_int("epochvalid", rsp_header.dsp.a2fc.epochvalid, 1);
                           printer.print_int("epochid",    rsp_header.dsp.a2fc.epochid,    1);
                           printer.print_int("portid",     rsp_header.dsp.a2fc.portid,     $size(rsp_header.dsp.a2fc.portid));
                         end
                       end
                       else if (info2 == "F2A") begin
                         printer.print_int("opcode",    rsp_header.dsp.f2ac.opcode,   4);
                         printer.print_int("cqid",      rsp_header.dsp.f2ac.cqid,     12);
                         printer.print_int("rsp_pre",   rsp_header.dsp.f2ac.rsp_pre,  2);
                         printer.print_int("rsvd",      rsp_header.dsp.f2ac.rsvd18,   1);
                         printer.print_int("rspdata",   rsp_header.dsp.f2ac.rspdata,  12);
                         printer.print_int("cacheid",   rsp_header.dsp.f2ac.cacheid,  4);
                         if (flit_mode_enc_en) begin
                           case(rsp_header.dsp.f2ac.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",rsp_header.dsp.f2ac.flitmode));
                         end
                       end
                       else
                         `uvm_error(get_type_name, "Couldn't determine the type of txn this was; set info2 to 'A2F' or 'F2A'")
                     end
/*DSP MEM*/4'b1011 : begin
                       if (info2 == "A2F") begin
                         printer.print_int("opcode",     rsp_header.dsp.a2fm.opcode,     3);
                         printer.print_int("metafield",  rsp_header.dsp.a2fm.metafield,  2);
                         printer.print_int("metavalue",  rsp_header.dsp.a2fm.metavalue,  2);
                         printer.print_int("tag",        rsp_header.dsp.a2fm.tag,        16);
                         printer.print_int("ldid",       rsp_header.dsp.a2fm.ldid,       4);
                         printer.print_int("devload",    rsp_header.dsp.a2fm.devload,    2);
                         if (flit_mode_enc_en) begin
                           case(rsp_header.dsp.a2fm.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",rsp_header.dsp.a2fm.flitmode));
                         end
                         if (pbr_flit_mode_en) begin
                           printer.print_int("epochvalid", rsp_header.dsp.a2fm.epochvalid, 1);
                           printer.print_int("epochid",    rsp_header.dsp.a2fm.epochid,    1);
                           printer.print_int("portid",     rsp_header.dsp.a2fm.portid,     $size(rsp_header.dsp.a2fm.portid));
                         end
                       end
                       else if (info2 == "F2A") begin
                         printer.print_int("opcode",  rsp_header.dsp.f2am.opcode,  4);
                         printer.print_int("biid",    rsp_header.dsp.f2am.biid,    12);
                         printer.print_int("bitag",   rsp_header.dsp.f2am.bitag,   12);
                         printer.print_int("lowaddr", rsp_header.dsp.f2am.lowaddr, 2);
                         if (flit_mode_enc_en) begin
                           case(rsp_header.dsp.f2am.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",rsp_header.dsp.f2am.flitmode));
                         end
                       end
                       else
                         `uvm_error(get_type_name, "Couldn't determine the type of txn this was; set info2 to 'A2F' or 'F2A'")
                     end
           default : `uvm_fatal(get_type_name, "Invalid protocol id set for this rsp_agent txn")
      endcase
      printer.m_scope.up(); //decrease indentation        
      if (credit_underflow)
        printer.print_int ("credit_underflow",  credit_underflow,   1);
    end
    else if ({txfer, credrtn} == 2'b01) begin
      // Dedicated Credit
      if (rsp_rxcrd_valid) begin
        case (rsp_rxcrd_protocol_id)
          4'b1000 : val = "'b1000 (US Port CXL.cache)";
          4'b1001 : val = "'b1001 (US Port CXL.mem)";
          4'b1010 : val = "'b1010 (DS Port CXL.cache)";
          4'b1011 : val = "'b1011 (DS Port CXL.mem)";
          default : val = "INVALID";
        endcase
        printer.print_int   ("rsp_rxcrd_valid",       rsp_rxcrd_valid,      1);
        printer.print_string("rsp_rxcrd_protocol_id", val                   );
        printer.print_int   ("rsp_rxcrd_vc_id",       rsp_rxcrd_vc_id,      4);
      end
      // Shared Credit
      if (rsp_rxcrd_shared) begin
        printer.print_int   ("rsp_rxcrd_shared",      rsp_rxcrd_shared,     1);
      end
      printer.print_int     ("rsp_txblock_crd_flow",  rsp_txblock_crd_flow, 1);
    end
    else
      `uvm_fatal(get_type_name, "Invalid txn setting, must have exclusively txfer or credrtn set")
  endfunction

  virtual function void do_copy(uvm_object rhs);
    rsp_txn t;
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't extended from rsp_txn")
    super.do_copy(rhs);
    txfer                 = t.txfer;     
    credrtn               = t.credrtn;
    credit_underflow      = t.credit_underflow;
    rsp_is_valid          = t.rsp_is_valid;
    rsp_block             = t.rsp_block;
    rsp_early_valid       = t.rsp_early_valid;
    rsp_protocol_id       = t.rsp_protocol_id;
    rsp_vc_id             = t.rsp_vc_id;
    rsp_shared_credit     = t.rsp_shared_credit;
    rsp_header            = t.rsp_header;
    rsp_cmd_parity        = t.rsp_cmd_parity;
    rsp_spid              = t.rsp_spid;
    rsp_dpid              = t.rsp_dpid;
    rsp_rxcrd_valid       = t.rsp_rxcrd_valid;
    rsp_rxcrd_protocol_id = t.rsp_rxcrd_protocol_id;
    rsp_rxcrd_vc_id       = t.rsp_rxcrd_vc_id;
    rsp_rxcrd_shared      = t.rsp_rxcrd_shared;
    rsp_txblock_crd_flow  = t.rsp_txblock_crd_flow;
    rsp_cmd_parity_en     = t.rsp_cmd_parity_en;
    pbr_flit_mode_en      = t.pbr_flit_mode_en;
    flit_mode_enc_en      = t.flit_mode_enc_en;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    rsp_txn _rhs;
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "do_compare got a txn that wasn't extended from rsp_txn")
    do_compare = super.do_compare(rhs, comparer);
    if ({txfer, credrtn} == 2'b10) begin
      do_compare &= comparer.compare_field_int("rsp_is_valid",      rsp_is_valid,      _rhs.rsp_is_valid,      1);
      do_compare &= comparer.compare_field_int("rsp_early_valid",   rsp_early_valid,   _rhs.rsp_early_valid,   1);
      do_compare &= comparer.compare_field_int("rsp_protocol_id",   rsp_protocol_id,   _rhs.rsp_protocol_id,   4);
      do_compare &= comparer.compare_field_int("rsp_vc_id",         rsp_vc_id,         _rhs.rsp_vc_id,         4);
      do_compare &= comparer.compare_field_int("rsp_shared_credit", rsp_shared_credit, _rhs.rsp_shared_credit, 1);
      do_compare &= comparer.compare_field    ("rsp_header",        rsp_header,        _rhs.rsp_header,        $size(rsp_header));
      if (rsp_cmd_parity_en)
        do_compare &= comparer.compare_field_int("rsp_cmd_parity",  rsp_cmd_parity,    _rhs.rsp_cmd_parity,    1);
      if (pbr_flit_mode_en) begin
        do_compare &= comparer.compare_field  ("rsp_spid",          rsp_spid,          _rhs.rsp_spid,          12);
        do_compare &= comparer.compare_field  ("rsp_dpid",          rsp_dpid,          _rhs.rsp_dpid,          12);
      end
    end
    else if ({txfer, credrtn} == 2'b01) begin 
      // Dedicated Credit 
      do_compare &= comparer.compare_field_int("rsp_rxcrd_valid", rsp_rxcrd_valid, _rhs.rsp_rxcrd_valid, 1);
      if (rsp_rxcrd_valid || _rhs.rsp_rxcrd_valid) begin
        do_compare &= comparer.compare_field_int("rsp_rxcrd_protocol_id", rsp_rxcrd_protocol_id, _rhs.rsp_rxcrd_protocol_id, 4);
        do_compare &= comparer.compare_field_int("rsp_rxcrd_vc_id",       rsp_rxcrd_vc_id,       _rhs.rsp_rxcrd_vc_id,       4);
      end
      // Shared Credit
      do_compare &= comparer.compare_field_int("rsp_rxcrd_shared", rsp_rxcrd_shared, _rhs.rsp_rxcrd_shared, 1);
    end
    else
      `uvm_fatal(get_type_name, "Invalid txn setting, must have exclusively txfer or credrtn set")
  endfunction

endclass
