class req_txn extends base_txn;

  `uvm_object_utils(req_txn)

  // Control printing
  bit req_cmd_parity_en;
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
  logic       req_is_valid;
  logic       req_block;
  logic       req_early_valid;
  // FLOW_C
  logic [3:0] req_protocol_id;
  logic [3:0] req_vc_id;
  logic       req_shared_credit;
  // HDR
  hdr_u       req_header;
  logic       req_cmd_parity;
  logic [11:0]req_spid;
  logic [11:0]req_dpid;
  // CREDIT
  logic       req_rxcrd_valid;
  logic [3:0] req_rxcrd_protocol_id;
  logic [3:0] req_rxcrd_vc_id;
  logic       req_rxcrd_shared;
  logic       req_txblock_crd_flow;

  function new(string name = "req_txn");
    super.new(name);
    txn_type = "REQ_TXN";
  endfunction

  // -----------------------------------------------------
  // calc_<method> = calculate and return the field
  // -----------------------------------------------------
  virtual function logic calc_address_parity();
    case (req_protocol_id)
/*USP $*/  4'b1000 : if(info2=="A2F") return(^req_header.usp.a2fc.address51to6);
                     else             return(^req_header.usp.f2ac.address51to6); 
/*USP MEM*/4'b1001 : if(info2=="A2F") return(^{req_header.usp.a2fm.address51to6,req_header.usp.a2fm.address5});
                     else             return(^req_header.usp.f2am.address51to6);
/*DSP $*/  4'b1010 : if(info2=="A2F") return(^req_header.dsp.a2fc.address51to6);
                     else             return(^req_header.dsp.f2ac.address51to6); 
/*DSP MEM*/4'b1011 : if(info2=="A2F") return(^req_header.dsp.a2fm.address51to6);
                     else             return(^{req_header.dsp.f2am.address51to6,req_header.dsp.f2am.address5});
           default : `uvm_fatal(get_type_name, "Invalid protocol id set for this req_agent txn") 
    endcase
  endfunction

  virtual function logic calc_cmd_parity();
    return (^{req_header,req_spid,req_dpid});
  endfunction
  // -----------------------------------------------------

  // -----------------------------------------------------
  // set_<method> = set the internal field
  // -----------------------------------------------------
  virtual function void set_address_parity(bit err = 1'b0);
    case (req_protocol_id)
/*USP $*/  4'b1000 : if (info2=="A2F")
                       req_header.usp.a2fc.addressparity = (err ^ calc_address_parity);
                     else
                       req_header.usp.f2ac.addressparity = (err ^ calc_address_parity);
/*USP MEM*/4'b1001 : if (info2=="A2F")
                       req_header.usp.a2fm.addressparity = (err ^ calc_address_parity);
                     else
                       req_header.usp.f2am.addressparity = (err ^ calc_address_parity);
/*DSP $*/  4'b1010 : if (info2=="A2F")
                       req_header.dsp.a2fc.addressparity = (err ^ calc_address_parity);
                     else
                       req_header.dsp.f2ac.addressparity = (err ^ calc_address_parity);
/*DSP MEM*/4'b1011 : if (info2=="A2F")
                       req_header.dsp.a2fm.addressparity = (err ^ calc_address_parity);
                     else
                       req_header.dsp.f2am.addressparity = (err ^ calc_address_parity);
           default : `uvm_fatal(get_type_name, "Invalid protocol id set for this req_agent txn") 
    endcase
  endfunction

  virtual function void set_cmd_parity(bit err = 1'b0);
    req_cmd_parity = (err ^ calc_cmd_parity);
  endfunction
  // -----------------------------------------------------

  virtual function void do_print(uvm_printer printer);
    string val;
    logic [51:5] tmpaddr;
    super.do_print(printer);
    if ({txfer, credrtn} == 2'b10) begin
      printer.print_int   ("req_is_valid",       req_is_valid,    1);
      printer.print_int   ("req_block",          req_block,       1);
      printer.print_int   ("req_early_valid",    req_early_valid, 1);
      case (req_protocol_id)
        4'b1000 : val = "'b1000 (US Port CXL.cache)";
        4'b1001 : val = "'b1001 (US Port CXL.mem)";
        4'b1010 : val = "'b1010 (DS Port CXL.cache)";
        4'b1011 : val = "'b1011 (DS Port CXL.mem)";
        default : val = "INVALID";
      endcase
      printer.print_string("req_protocol_id",   val                 );
      printer.print_int   ("req_vc_id",         req_vc_id,          4);
      printer.print_int   ("req_shared_credit", req_shared_credit,  1);
      if (!req_cmd_parity_en) val = $sformatf("'%0b (DISABLED)",req_cmd_parity);
      else                    val = $sformatf("'%0b",           req_cmd_parity);
      printer.print_string("req_cmd_parity",    val                  );
      if (pbr_flit_mode_en) begin
        printer.print_int ("req_spid",          req_spid,          12);
        printer.print_int ("req_dpid",          req_dpid,          12);
      end
      printer.print_int   ("req_header",        req_header,         $size(req_header));
      printer.m_scope.down(""); //increase indentation
      case (req_protocol_id)
/*USP $*/  4'b1000 : begin
                       if (info2 == "A2F") begin
                         printer.print_int("opcode",        req_header.usp.a2fc.opcode,         3);
                         printer.print_int("uqid",          req_header.usp.a2fc.uqid,          12);
                         printer.print_int("addressparity", req_header.usp.a2fc.addressparity,  1);
                         printer.print_int("addr",          req_header.usp.a2fc.address51to6,  46);
                         printer.print_int("cacheid",       req_header.usp.a2fc.cacheid,        4);
                         if (flit_mode_enc_en) begin
                           case(req_header.usp.a2fc.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end 
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",req_header.usp.a2fc.flitmode));
                         end
                         if (pbr_flit_mode_en) begin
                           printer.print_int("epochvalid", req_header.usp.a2fc.epochvalid, 1);
                           printer.print_int("epochid",    req_header.usp.a2fc.epochid,    1);
                           printer.print_int("portid",     req_header.usp.a2fc.portid,     $size(req_header.usp.a2fc.portid));
                         end
                       end
                       else if (info2 == "F2A") begin
                         printer.print_int("opcode",        req_header.usp.f2ac.opcode,         5);
                         printer.print_int("cqid",          req_header.usp.f2ac.cqid,          12);
                         printer.print_int("nt",            req_header.usp.f2ac.nt,             1);
                         printer.print_int("rsvd",          req_header.usp.f2ac.rsvd19to18,     2);
                         printer.print_int("addressparity", req_header.usp.f2ac.addressparity,  1);
                         printer.print_int("addr",          req_header.usp.f2ac.address51to6,  46);
                         printer.print_int("cacheid",       req_header.usp.f2ac.cacheid,        4);
                         if (flit_mode_enc_en) begin
                           case(req_header.usp.f2ac.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end 
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",req_header.usp.f2ac.flitmode));
                         end
                       end
                       else
                         `uvm_error(get_type_name, "Couldn't determine the type of txn this was; set info2 to 'A2F' or 'F2A'")
                     end
/*USP MEM*/4'b1001 : begin
                       if (info2 == "A2F") begin
                         printer.print_int("memopcode",     req_header.usp.a2fm.memopcode,          4);
                         printer.print_int("tag",           req_header.usp.a2fm.tag,               16);
                         printer.print_int("tc",            req_header.usp.a2fm.tc,                 2);
                         printer.print_int("snptype",       req_header.usp.a2fm.snptype,            3);
                         tmpaddr = {req_header.usp.a2fm.address51to6, req_header.usp.a2fm.address5};
                         printer.print_int("addr",          tmpaddr,                               47);
                         printer.print_int("metafield",     req_header.usp.a2fm.metafield,          2);
                         printer.print_int("metavalue",     req_header.usp.a2fm.metavalue,          2);
                         printer.print_int("addressparity", req_header.usp.a2fm.addressparity,      1);
                         printer.print_int("ldid",          req_header.usp.a2fm.ldid,               4);
                         if (flit_mode_enc_en) begin
                           case(req_header.usp.a2fm.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end 
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",req_header.usp.a2fm.flitmode));
                         end
                         if (pbr_flit_mode_en) begin
                           printer.print_int("epochvalid", req_header.usp.a2fm.epochvalid, 1);
                           printer.print_int("epochid",    req_header.usp.a2fm.epochid,    1);
                           printer.print_int("portid",     req_header.usp.a2fm.portid,     $size(req_header.usp.a2fm.portid));
                         end
                       end
                       else if (info2 == "F2A") begin
                         printer.print_int("opcode",        req_header.usp.f2am.opcode,         4);
                         printer.print_int("biid",          req_header.usp.f2am.biid,          12);
                         printer.print_int("bitag",         req_header.usp.f2am.bitag,         12);
                         printer.print_int("addressparity", req_header.usp.f2am.addressparity,  1);
                         printer.print_int("addr",          req_header.usp.f2am.address51to6,  46);
                         if (flit_mode_enc_en) begin
                           case(req_header.usp.f2am.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end 
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",req_header.usp.f2am.flitmode));
                         end
                       end
                       else
                         `uvm_error(get_type_name, "Couldn't determine the type of txn this was; set info2 to 'A2F' or 'F2A'")
                     end
/*DSP $*/  4'b1010 : begin
                       if (info2 == "A2F") begin
                         printer.print_int("opcode",        req_header.dsp.a2fc.opcode,         5);
                         printer.print_int("cqid",          req_header.dsp.a2fc.cqid,          12);
                         printer.print_int("nt",            req_header.dsp.a2fc.nt,             1);
                         printer.print_int("dev_trust_lvl", req_header.dsp.a2fc.dev_trust_lvl,  2);
                         printer.print_int("addressparity", req_header.dsp.a2fc.addressparity,  1);
                         printer.print_int("addr",          req_header.dsp.a2fc.address51to6,  46);
                         printer.print_int("cacheid",       req_header.dsp.a2fc.cacheid,        4);
                         if (flit_mode_enc_en) begin
                           case(req_header.dsp.a2fc.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end 
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",req_header.dsp.a2fc.flitmode));
                         end
                         if (pbr_flit_mode_en) begin
                           printer.print_int("epochvalid", req_header.dsp.a2fc.epochvalid, 1);
                           printer.print_int("epochid",    req_header.dsp.a2fc.epochid,    1);
                           printer.print_int("portid",     req_header.dsp.a2fc.portid,     $size(req_header.dsp.a2fc.portid));
                         end
                       end
                       else if (info2 == "F2A") begin
                         printer.print_int("opcode",        req_header.dsp.f2ac.opcode,         3);
                         printer.print_int("uqid",          req_header.dsp.f2ac.uqid,          12);
                         printer.print_int("addressparity", req_header.dsp.f2ac.addressparity,  1);
                         printer.print_int("addr",          req_header.dsp.f2ac.address51to6,  46);
                         printer.print_int("cacheid",       req_header.dsp.f2ac.cacheid,        4);
                         if (flit_mode_enc_en) begin
                           case(req_header.dsp.f2ac.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end 
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",req_header.dsp.f2ac.flitmode));
                         end
                       end
                       else
                         `uvm_error(get_type_name, "Couldn't determine the type of txn this was; set info2 to 'A2F' or 'F2A'")
                     end
/*DSP MEM*/4'b1011 : begin
                       if (info2 == "A2F") begin
                         printer.print_int("opcode",        req_header.dsp.a2fm.opcode,         4);
                         printer.print_int("biid",          req_header.dsp.a2fm.biid,          12);
                         printer.print_int("bitag",         req_header.dsp.a2fm.bitag,         12);
                         printer.print_int("addressparity", req_header.dsp.a2fm.addressparity,  1);
                         printer.print_int("addr",          req_header.dsp.a2fm.address51to6,  46);
                         if (flit_mode_enc_en) begin
                           case(req_header.dsp.a2fm.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end 
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",req_header.dsp.a2fm.flitmode));
                         end
                         if (pbr_flit_mode_en) begin
                           printer.print_int("epochvalid", req_header.dsp.a2fm.epochvalid, 1);
                           printer.print_int("epochid",    req_header.dsp.a2fm.epochid,    1);
                           printer.print_int("portid",     req_header.dsp.a2fm.portid,     $size(req_header.dsp.a2fm.portid));
                         end
                       end
                       else if (info2 == "F2A") begin
                         printer.print_int("memopcode",     req_header.dsp.f2am.memopcode,          4);
                         printer.print_int("tag",           req_header.dsp.f2am.tag,               16);
                         printer.print_int("tc",            req_header.dsp.f2am.tc,                 2);
                         printer.print_int("snptype",       req_header.dsp.f2am.snptype,            3);
                         tmpaddr = {req_header.dsp.f2am.address51to6, req_header.dsp.f2am.address5};
                         printer.print_int("addr",          tmpaddr,                               47);
                         printer.print_int("metafield",     req_header.dsp.f2am.metafield,          2);
                         printer.print_int("metavalue",     req_header.dsp.f2am.metavalue,          2);
                         printer.print_int("addressparity", req_header.dsp.f2am.addressparity,      1);
                         printer.print_int("ldid",          req_header.dsp.f2am.ldid,               4);
                         if (flit_mode_enc_en) begin
                           case(req_header.dsp.f2am.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",req_header.dsp.f2am.flitmode));
                         end
                       end
                       else
                         `uvm_error(get_type_name, "Couldn't determine the type of txn this was; set info2 to 'A2F' or 'F2A'")
                     end
           default : `uvm_fatal(get_type_name, "Invalid protocol id set for this req_agent txn") 
      endcase
      printer.m_scope.up(); //decrease indentation        
      if (credit_underflow)
        printer.print_int ("credit_underflow",  credit_underflow,   1);
    end
    else if ({txfer, credrtn} == 2'b01) begin 
      // Dedicated Credit 
      if (req_rxcrd_valid) begin
        case (req_rxcrd_protocol_id)
          4'b1000 : val = "'b1000 (US Port CXL.cache)";
          4'b1001 : val = "'b1001 (US Port CXL.mem)";
          4'b1010 : val = "'b1010 (DS Port CXL.cache)";
          4'b1011 : val = "'b1011 (DS Port CXL.mem)";
          default : val = "INVALID";
        endcase
        printer.print_int   ("req_rxcrd_valid",       req_rxcrd_valid,      1);
        printer.print_string("req_rxcrd_protocol_id", val                   );
        printer.print_int   ("req_rxcrd_vc_id",       req_rxcrd_vc_id,      4);
      end
      // Shared Credit
      if (req_rxcrd_shared) begin
        printer.print_int   ("req_rxcrd_shared",      req_rxcrd_shared,     1);
      end
      printer.print_int     ("req_txblock_crd_flow",  req_txblock_crd_flow, 1);
    end
    else
      `uvm_fatal(get_type_name, "Invalid txn setting, must have exclusively txfer or credrtn set")
  endfunction

  virtual function void do_copy(uvm_object rhs);
    req_txn t;
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't extended from req_txn")
    super.do_copy(rhs);
    txfer                 = t.txfer;
    credrtn               = t.credrtn;
    credit_underflow      = t.credit_underflow;
    req_is_valid          = t.req_is_valid;
    req_block             = t.req_block;
    req_early_valid       = t.req_early_valid;
    req_protocol_id       = t.req_protocol_id;
    req_vc_id             = t.req_vc_id;
    req_shared_credit     = t.req_shared_credit;
    req_header            = t.req_header;
    req_cmd_parity        = t.req_cmd_parity;
    req_spid              = t.req_spid;
    req_dpid              = t.req_dpid;
    req_rxcrd_valid       = t.req_rxcrd_valid;
    req_rxcrd_protocol_id = t.req_rxcrd_protocol_id;
    req_rxcrd_vc_id       = t.req_rxcrd_vc_id;
    req_rxcrd_shared      = t.req_rxcrd_shared;
    req_txblock_crd_flow  = t.req_txblock_crd_flow;
    req_cmd_parity_en     = t.req_cmd_parity_en;
    pbr_flit_mode_en      = t.pbr_flit_mode_en;
    flit_mode_enc_en      = t.flit_mode_enc_en;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    req_txn _rhs;
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "do_compare got a txn that wasn't extended from req_txn")
    do_compare = super.do_compare(rhs, comparer);
    if ({txfer, credrtn} == 2'b10) begin
      do_compare &= comparer.compare_field_int("req_is_valid",      req_is_valid,      _rhs.req_is_valid,      1);
      do_compare &= comparer.compare_field_int("req_early_valid",   req_early_valid,   _rhs.req_early_valid,   1);
      do_compare &= comparer.compare_field_int("req_protocol_id",   req_protocol_id,   _rhs.req_protocol_id,   4);
      do_compare &= comparer.compare_field_int("req_vc_id",         req_vc_id,         _rhs.req_vc_id,         4);
      do_compare &= comparer.compare_field_int("req_shared_credit", req_shared_credit, _rhs.req_shared_credit, 1);
      do_compare &= comparer.compare_field    ("req_header",        req_header,        _rhs.req_header,        $size(req_header));
      if (req_cmd_parity_en)
        do_compare &= comparer.compare_field  ("req_cmd_parity",    req_cmd_parity,    _rhs.req_cmd_parity,    1); 
      if (pbr_flit_mode_en) begin
        do_compare &= comparer.compare_field  ("req_spid",          req_spid,          _rhs.req_spid,         12); 
        do_compare &= comparer.compare_field  ("req_dpid",          req_dpid,          _rhs.req_dpid,         12); 
      end
    end
    else if ({txfer, credrtn} == 2'b01) begin 
      // Dedicated Credit 
      do_compare &= comparer.compare_field_int("req_rxcrd_valid", req_rxcrd_valid, _rhs.req_rxcrd_valid, 1);
      if (req_rxcrd_valid || _rhs.req_rxcrd_valid) begin
        do_compare &= comparer.compare_field_int("req_rxcrd_protocol_id", req_rxcrd_protocol_id, _rhs.req_rxcrd_protocol_id, 4);
        do_compare &= comparer.compare_field_int("req_rxcrd_vc_id",       req_rxcrd_vc_id,       _rhs.req_rxcrd_vc_id,       4);
      end
      // Shared Credit
      do_compare &= comparer.compare_field_int  ("req_rxcrd_shared",      req_rxcrd_shared,      _rhs.req_rxcrd_shared,      1);
    end
    else
      `uvm_fatal(get_type_name, "Invalid txn setting, must have exclusively txfer or credrtn set")
  endfunction

endclass
