class data_txn extends base_txn;

  `uvm_object_utils(data_txn)

  // Control printing
  bit data_cmd_parity_en;
  bit data_be_parity_en;
  bit pbr_flit_mode_en;
  bit flit_mode_enc_en;
  int emd_bits;

  // Mutually exclusive; type of txn
  bit txfer;
  bit credrtn;

  // If slave receives a txn when it has sent zero credits, mark
  bit credit_underflow;

  // Responders need to return credits when they're consumed, a 
  // sequence can randomize and constrain this as it sees fit 
  byte unsigned crd_ret_dly;

  // VALID
  logic        data_is_valid;
  logic        data_block;
  logic        data_early_valid;
  // FLOW_C
  logic  [3:0] data_protocol_id;
  logic  [3:0] data_vc_id;
  logic        data_shared_credit;
  // HDR
  hdr_u        data_header;
  logic        data_sz;
  logic        data_cmd_parity;
  logic [11:0] data_spid;
  logic [11:0] data_dpid;
  // PAYLOAD
  logic [511:0] data_body;
  logic [ 63:0] data_byte_enable;
  logic         data_byte_enable_parity;
  logic         data_poison;
  logic [  7:0] data_parity;
  // EOP
  logic         data_eop;
  // CREDIT
  logic         data_rxcrd_valid;
  logic   [1:0] data_rxcrd_protocol_id;
  logic   [3:0] data_rxcrd_vc_id;
  logic         data_rxcrd_shared;
  logic         data_txblock_crd_flow;
  // EMD (not part of CPI spec)
  logic [ 31:0] data_emd;

  function new(string name = "data_txn");
    super.new(name);
    txn_type = "DATA_TXN";
  endfunction

  // -----------------------------------------------------
  // calc_<method> = calculate and return that field
  // -----------------------------------------------------
  virtual function logic calc_address_parity();
    case (data_protocol_id)
/*USP $*/  4'b1000: return 0; //no address parity
/*USP MEM*/4'b1001: if (info2=="A2F") return(^{data_header.usp.a2fm.address51to6_even, data_header.usp.a2fm.address51to6_odd});
                    else              return 0; //no address parity
/*DSP $*/  4'b1010: return 0; //no address parity
/*DSP MEM*/4'b1011: if (info2=="A2F") return 0; //no address parity
                    else              return(^{data_header.dsp.f2am.address51to6_even, data_header.dsp.f2am.address51to6_odd});
           default: `uvm_fatal(get_type_name, "Invalid protocol id set for this data_agent tx") 
    endcase
  endfunction

  virtual function logic calc_cmd_parity();
    return(^{data_header, data_spid, data_dpid});
  endfunction

  virtual function logic [7:0] calc_data_parity();
    for (int ii=0; ii<8; ii++)
      calc_data_parity[ii] = (^data_body[ii*64+:64]);
  endfunction

  virtual function logic calc_be_parity();
    return(^data_byte_enable);
  endfunction
  // -----------------------------------------------------

  // -----------------------------------------------------
  // set_<method> = set the internal field
  // -----------------------------------------------------
  virtual function void set_address_parity(bit err = 1'b0);
    case (data_protocol_id)
/*USP $*/  4'b1000: ;
/*USP MEM*/4'b1001: if (info2=="A2F") data_header.usp.a2fm.addressparity = (err ^ calc_address_parity);
/*DSP $*/  4'b1010: ;
/*DSP MEM*/4'b1011: if (info2=="F2A") data_header.dsp.f2am.addressparity = (err ^ calc_address_parity);
           default: `uvm_fatal(get_type_name, "Invalid protocol id set for this data_agent tx") 
    endcase
  endfunction

  virtual function void set_cmd_parity(bit err = 1'b0);
    data_cmd_parity = (err ^ calc_cmd_parity);
  endfunction

  // When injecting an error, flip the parity of one random 64b chunk
  virtual function void set_data_parity(bit err = 1'b0);
    int err_ptr = $urandom_range(0,7);
    data_parity = calc_data_parity ^ (8'(err) << err_ptr);
  endfunction

  virtual function void set_be_parity(bit err = 1'b0);
    data_byte_enable_parity = (err ^ calc_be_parity);
  endfunction
  // -----------------------------------------------------

  virtual function void do_print(uvm_printer printer);
    string val;
    logic [51:6] addr;
    logic [511:0] masked_data;
    for (int ii=0; ii<64; ii++) 
      masked_data[ii*8+:8] = data_body[ii*8+:8] & {8{data_byte_enable[ii]}};
    super.do_print(printer);
    if ({txfer, credrtn} == 2'b10) begin
      printer.print_int   ("data_is_valid",       data_is_valid,    1);
      printer.print_int   ("data_block",          data_block,       1);
      printer.print_int   ("data_early_valid",    data_early_valid, 1);
      case (data_protocol_id)
        4'b1000 : val = "'b1000 (US Port CXL.cache)";
        4'b1001 : val = "'b1001 (US Port CXL.mem)";
        4'b1010 : val = "'b1010 (DS Port CXL.cache)";
        4'b1011 : val = "'b1011 (DS Port CXL.mem)";
        default : val = "INVALID";
      endcase
      printer.print_string("data_protocol_id",   val                   );
      printer.print_int   ("data_vc_id",         data_vc_id,          4);
      printer.print_int   ("data_shared_credit", data_shared_credit,  1);
      if (!data_cmd_parity_en) val = $sformatf("'%0b (DISABLED)", data_cmd_parity);
      else                     val = $sformatf("'%0b",            data_cmd_parity);
      printer.print_string("data_cmd_parity",    val                   );
      if (pbr_flit_mode_en) begin
        printer.print_int ("data_spid",          data_spid,          12);
        printer.print_int ("data_dpid",          data_dpid,          12);
      end
      printer.print_int   ("data_header",        data_header,        $size(data_header));
      printer.m_scope.down(""); //increase indentation
      case (data_protocol_id)
/*USP $*/  4'b1000 : begin
                       if (info2 == "A2F") begin
                         printer.print_int   ("goerr",       data_header.usp.a2fc.goerr,      1);
                         printer.print_int   ("rsvd",        data_header.usp.a2fc.rsvd7to1,   7);
                         printer.print_int   ("cqid",        data_header.usp.a2fc.cqid,       12);
                         printer.print_int   ("chunkvalid",  data_header.usp.a2fc.chunkvalid, 1);
                         printer.print_int   ("cacheid",     data_header.usp.a2fc.cacheid,    4);
                         if (flit_mode_enc_en) begin
                           case(data_header.usp.a2fc.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",data_header.usp.a2fc.flitmode));
                         end
                         if (pbr_flit_mode_en) begin
                           printer.print_int("epochvalid", data_header.usp.a2fc.epochvalid, 1);
                           printer.print_int("epochid",    data_header.usp.a2fc.epochid,    1);
                           printer.print_int("portid",     data_header.usp.a2fc.portid,     $size(data_header.usp.a2fc.portid));
                         end
                       end
                       else if (info2 == "F2A") begin
                         printer.print_int   ("uqid",       data_header.usp.f2ac.uqid,       12);
                         printer.print_int   ("rsvd",       data_header.usp.f2ac.rsvd12,     1);
                         printer.print_int   ("bogus",      data_header.usp.f2ac.bogus,      1);
                         printer.print_int   ("chunkvalid", data_header.usp.f2ac.chunkvalid, 1);
                         if (flit_mode_enc_en) begin
                           case(data_header.usp.f2ac.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",data_header.usp.f2ac.flitmode));
                         end
                       end
                       else
                         `uvm_error(get_type_name, "Couldn't determine the type of txn this was; set info2 to 'A2F' or 'F2A'")
                     end
/*USP MEM*/4'b1001 : begin
                       if (info2 == "A2F") begin
                         printer.print_int   ("memopcode",     data_header.usp.a2fm.memopcode,     4);
                         printer.print_int   ("metafield",     data_header.usp.a2fm.metafield,     2);
                         printer.print_int   ("metavalue",     data_header.usp.a2fm.metavalue,     2);
                         printer.print_int   ("snptype",       data_header.usp.a2fm.snptype,       3);
                         printer.print_int   ("tc",            data_header.usp.a2fm.tc,            2);
                         printer.print_int   ("rsvd",          data_header.usp.a2fm.rsvd14to13,    2);
                         printer.print_int   ("addressparity", data_header.usp.a2fm.addressparity, 1);
                         foreach(addr[ii]) begin
                           if ((ii-6)%2)
                             addr[ii] = data_header.usp.a2fm.address51to6_odd[(ii-6)/2];
                           else
                             addr[ii] = data_header.usp.a2fm.address51to6_even[(ii-6)/2];
                         end
                         printer.print_int   ("addr",          addr,                              46);
                         printer.print_int   ("tag",           data_header.usp.a2fm.tag,          16);
                         printer.print_int   ("ldid",          data_header.usp.a2fm.ldid,          4);
                         if (flit_mode_enc_en) begin
                           case(data_header.usp.a2fm.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",data_header.usp.a2fm.flitmode));
                         end
                         if (pbr_flit_mode_en) begin
                           printer.print_int("epochvalid", data_header.usp.a2fm.epochvalid, 1);
                           printer.print_int("epochid",    data_header.usp.a2fm.epochid,    1);
                           printer.print_int("portid",     data_header.usp.a2fm.portid,     $size(data_header.usp.a2fm.portid));
                         end
                       end
                       else if (info2 == "F2A") begin
                         printer.print_int   ("opcode",    data_header.usp.f2am.opcode,    3);
                         printer.print_int   ("rsvd",      data_header.usp.f2am.rsvd3,     1);
                         printer.print_int   ("metafield", data_header.usp.f2am.metafield, 2);
                         printer.print_int   ("metavalue", data_header.usp.f2am.metavalue, 2);
                         printer.print_int   ("rsvd",      data_header.usp.f2am.rsvd15to8, 8);
                         printer.print_int   ("tag",       data_header.usp.f2am.tag,       16);
                         printer.print_int   ("ldid",      data_header.usp.f2am.ldid,      4);
                         printer.print_int   ("devload",   data_header.usp.f2am.devload,   2);
                         if (flit_mode_enc_en) begin
                           case(data_header.usp.f2am.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",data_header.usp.f2am.flitmode));
                         end
                       end
                       else
                         `uvm_error(get_type_name, "Couldn't determine the type of txn this was; set info2 to 'A2F' or 'F2A'")
                     end 
/*DSP $*/  4'b1010 : begin
                       if (info2 == "A2F") begin
                         printer.print_int   ("uqid",       data_header.dsp.a2fc.uqid,       12);
                         printer.print_int   ("rsvd",       data_header.dsp.a2fc.rsvd12,     1);
                         printer.print_int   ("bogus",      data_header.dsp.a2fc.bogus,      1);
                         printer.print_int   ("chunkvalid", data_header.dsp.a2fc.chunkvalid, 1);
                         if (flit_mode_enc_en) begin
                           case(data_header.dsp.a2fc.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",data_header.dsp.a2fc.flitmode));
                         end
                         if (pbr_flit_mode_en) begin
                           printer.print_int("epochvalid", data_header.dsp.a2fc.epochvalid, 1);
                           printer.print_int("epochid",    data_header.dsp.a2fc.epochid,    1);
                           printer.print_int("portid",     data_header.dsp.a2fc.portid,     $size(data_header.dsp.a2fc.portid));
                         end
                       end
                       else if (info2 == "F2A") begin
                         printer.print_int   ("goerr",       data_header.dsp.f2ac.goerr,      1);
                         printer.print_int   ("rsvd",        data_header.dsp.f2ac.rsvd7to1,   7);
                         printer.print_int   ("cqid",        data_header.dsp.f2ac.cqid,       12);
                         printer.print_int   ("chunkvalid",  data_header.dsp.f2ac.chunkvalid, 1);
                         printer.print_int   ("cacheid",     data_header.dsp.f2ac.cacheid,    4);
                         if (flit_mode_enc_en) begin
                           case(data_header.dsp.f2ac.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",data_header.dsp.f2ac.flitmode));
                         end
                       end
                       else
                         `uvm_error(get_type_name, "Couldn't determine the type of txn this was; set info2 to 'A2F' or 'F2A'")
                     end 
/*DSP MEM*/4'b1011 : begin
                       if (info2 == "A2F") begin
                         printer.print_int   ("opcode",    data_header.dsp.a2fm.opcode,    3);
                         printer.print_int   ("rsvd",      data_header.dsp.a2fm.rsvd3,     1);
                         printer.print_int   ("metafield", data_header.dsp.a2fm.metafield, 2);
                         printer.print_int   ("metavalue", data_header.dsp.a2fm.metavalue, 2);
                         printer.print_int   ("rsvd",      data_header.dsp.a2fm.rsvd15to8, 8);
                         printer.print_int   ("tag",       data_header.dsp.a2fm.tag,       16);
                         printer.print_int   ("ldid",      data_header.dsp.a2fm.ldid,      4);
                         printer.print_int   ("devload",   data_header.dsp.a2fm.devload,   2);
                         if (flit_mode_enc_en) begin
                           case(data_header.dsp.a2fm.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",data_header.dsp.a2fm.flitmode));
                         end
                         if (pbr_flit_mode_en) begin
                           printer.print_int("epochvalid", data_header.dsp.a2fm.epochvalid, 1);
                           printer.print_int("epochid",    data_header.dsp.a2fm.epochid,    1);
                           printer.print_int("portid",     data_header.dsp.a2fm.portid,     $size(data_header.dsp.a2fm.portid));
                         end
                       end
                       else if (info2 == "F2A") begin
                         printer.print_int   ("memopcode",     data_header.dsp.f2am.memopcode,     4);
                         printer.print_int   ("metafield",     data_header.dsp.f2am.metafield,     2);
                         printer.print_int   ("metavalue",     data_header.dsp.f2am.metavalue,     2);
                         printer.print_int   ("snptype",       data_header.dsp.f2am.snptype,       3);
                         printer.print_int   ("tc",            data_header.dsp.f2am.tc,            2);
                         printer.print_int   ("rsvd",          data_header.dsp.f2am.rsvd14to13,    2);
                         printer.print_int   ("addressparity", data_header.dsp.f2am.addressparity, 1);
                         foreach(addr[ii]) begin
                           if ((ii-6)%2)
                             addr[ii] = data_header.dsp.f2am.address51to6_odd[(ii-6)/2];
                           else
                             addr[ii] = data_header.dsp.f2am.address51to6_even[(ii-6)/2];
                         end
                         printer.print_int   ("addr",          addr,                              46);
                         printer.print_int   ("tag",           data_header.dsp.f2am.tag,          16);
                         printer.print_int   ("ldid",          data_header.dsp.f2am.ldid,          4);
                         if (flit_mode_enc_en) begin
                           case(data_header.dsp.f2am.flitmode)
                             2'b00 : val = "'b00 (68B flit)";
                             2'b01 : val = "'b01 (256B flit)";
                             2'b10 : val = "'b10 (PBR flit)";
                             2'b11 : val = "Reserved";
                           endcase
                           printer.print_string("flitmode", val);
                         end
                         else begin
                           printer.print_string("flitmode", $sformatf("'%b (UNUSED)",data_header.dsp.f2am.flitmode));
                         end
                       end
                       else
                         `uvm_error(get_type_name, "Couldn't determine the type of txn this was; set info2 to 'A2F' or 'F2A'")
                     end 
           default : `uvm_fatal(get_type_name, "Invalid protocol id set for this data_agent txn") 
      endcase
      printer.m_scope.up(); //decrease indentation        
      printer.print_int   ("data_sz",            data_sz,               1);
      printer.print_int   ("data_body[0]",       data_body[0*128+:128], 128); 
      printer.print_int   ("data_body[1]",       data_body[1*128+:128], 128); 
      printer.print_int   ("data_body[2]",       data_body[2*128+:128], 128); 
      printer.print_int   ("data_body[3]",       data_body[3*128+:128], 128); 
      if (data_byte_enable != '1) begin
        printer.print_int   ("data_be[0]",       data_byte_enable[0*16+:16], 16); 
        printer.print_int   ("data_be[1]",       data_byte_enable[1*16+:16], 16); 
        printer.print_int   ("data_be[2]",       data_byte_enable[2*16+:16], 16); 
        printer.print_int   ("data_be[3]",       data_byte_enable[3*16+:16], 16); 
        printer.print_int   ("(resultant_data[0])", masked_data[0*128+:128], 128); 
        printer.print_int   ("(resultant_data[1])", masked_data[1*128+:128], 128); 
        printer.print_int   ("(resultant_data[2])", masked_data[2*128+:128], 128); 
        printer.print_int   ("(resultant_data[3])", masked_data[3*128+:128], 128); 
      end
      if (emd_bits) begin
        /* M2S */
        if (info2=="F2A" && data_protocol_id==4'b1011) begin //DSP
          if (data_header.dsp.f2am.metafield==2'b01) // ==ExtMetaState
            printer.print_int ("data_emd",           data_emd,            emd_bits);
        end
        else if (info2=="A2F" && data_protocol_id==4'b1000) begin //USP
          if (data_header.usp.a2fm.metafield==2'b01) // ==ExtMetaState
            printer.print_int ("data_emd",           data_emd,            emd_bits);
        end
        /* S2M */
        else if (info2=="F2A" && data_protocol_id==4'b1000) begin //USP
          if (data_header.usp.f2am.metafield==2'b01) // ==ExtMetaState
            printer.print_int ("data_emd",           data_emd,            emd_bits);
        end
        else if (info2=="A2F" && data_protocol_id==4'b1011) begin //DSP
          if (data_header.dsp.a2fm.metafield==2'b01) // ==ExtMetaState
            printer.print_int ("data_emd",           data_emd,            emd_bits);
        end
      end
      printer.print_int   ("data_poison",        data_poison,         1);
      printer.print_int   ("data_parity",        data_parity,         8);
      printer.print_int   ("data_eop",           data_eop,            1);
      if (credit_underflow)
        printer.print_int ("credit_underflow",  credit_underflow,     1);
    end
    else if ({txfer, credrtn} == 2'b01) begin
      // Dedicated Credit
      if (data_rxcrd_valid) begin
        case (data_rxcrd_protocol_id)
          2'b00   : val = "'b00 (US Port CXL.cache)";
          2'b01   : val = "'b01 (US Port CXL.mem)";
          2'b10   : val = "'b10 (DS Port CXL.cache)";
          2'b11   : val = "'b11 (DS Port CXL.mem)";
          default : val = "INVALID";
        endcase
        printer.print_int   ("data_rxcrd_valid",       data_rxcrd_valid,      1);
        printer.print_string("data_rxcrd_protocol_id", val                     );
        printer.print_int   ("data_rxcrd_vc_id",       data_rxcrd_vc_id,      4);
      end
      if (data_rxcrd_shared) begin
        printer.print_int   ("data_rxcrd_shared",      data_rxcrd_shared,     1);
      end
      printer.print_int     ("data_txblock_crd_flow",  data_txblock_crd_flow, 1);
    end
    else
      `uvm_fatal(get_type_name, "Invalid txn setting, must have exclusively txfer or credrtn set")
  endfunction

  virtual function void do_copy(uvm_object rhs);
    data_txn t;
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't extended from data_txn")
    super.do_copy(rhs);
    txfer                  = t.txfer;
    credrtn                = t.credrtn;
    credit_underflow       = t.credit_underflow;
    data_is_valid          = t.data_is_valid;
    data_block             = t.data_block;
    data_early_valid       = t.data_early_valid;
    data_protocol_id       = t.data_protocol_id;
    data_vc_id             = t.data_vc_id;
    data_shared_credit     = t.data_shared_credit;
    data_header            = t.data_header;
    data_sz                = t.data_sz;
    data_spid              = t.data_spid;
    data_dpid              = t.data_dpid;
    data_cmd_parity        = t.data_cmd_parity;
    data_body              = t.data_body;
    data_byte_enable       = t.data_byte_enable;
    data_byte_enable_parity= t.data_byte_enable_parity;
    data_poison            = t.data_poison;
    data_parity            = t.data_parity;
    data_eop               = t.data_eop;
    data_emd               = t.data_emd;
    data_rxcrd_valid       = t.data_rxcrd_valid;
    data_rxcrd_protocol_id = t.data_rxcrd_protocol_id;
    data_rxcrd_vc_id       = t.data_rxcrd_vc_id;
    data_rxcrd_shared      = t.data_rxcrd_shared;
    data_txblock_crd_flow  = t.data_txblock_crd_flow;
    data_cmd_parity_en     = t.data_cmd_parity_en;
    data_be_parity_en      = t.data_be_parity_en;
    pbr_flit_mode_en       = t.pbr_flit_mode_en;
    flit_mode_enc_en       = t.flit_mode_enc_en;
    emd_bits               = t.emd_bits;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    data_txn _rhs;
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "do_compare got a txn that wasn't extended from data_txn")
    do_compare  = comparer.compare_string("txn_type", txn_type, _rhs.txn_type);
    do_compare &= comparer.compare_string("uid",      uid,      _rhs.uid); 
    if ({txfer, credrtn} == 2'b10) begin
      do_compare &= comparer.compare_field_int  ("data_is_valid",           data_is_valid,           _rhs.data_is_valid,           1);
      do_compare &= comparer.compare_field_int  ("data_early_valid",        data_early_valid,        _rhs.data_early_valid,        1);
      do_compare &= comparer.compare_field_int  ("data_protocol_id",        data_protocol_id,        _rhs.data_protocol_id,        4);
      do_compare &= comparer.compare_field_int  ("data_vc_id",              data_vc_id,              _rhs.data_vc_id,              4);
      do_compare &= comparer.compare_field_int  ("data_shared_credit",      data_shared_credit,      _rhs.data_shared_credit,      1);
      do_compare &= comparer.compare_field      ("data_header",             data_header,             _rhs.data_header,             $size(data_header));
      do_compare &= comparer.compare_field_int  ("data_sz",                 data_sz,                 _rhs.data_sz,                 1);
      if (data_cmd_parity_en)                                                                                                      
        do_compare &= comparer.compare_field_int("data_cmd_parity",         data_cmd_parity,         _rhs.data_cmd_parity,         1);
      do_compare &= comparer.compare_field      ("data_body",               data_body,               _rhs.data_body,               512);
      do_compare &= comparer.compare_field_int  ("data_byte_enable",        data_byte_enable,        _rhs.data_byte_enable,        64);
      if (data_be_parity_en)
        do_compare &= comparer.compare_field_int("data_byte_enable_parity", data_byte_enable_parity, _rhs.data_byte_enable_parity, 1);
      if (pbr_flit_mode_en) begin
        do_compare &= comparer.compare_field    ("data_spid",               data_spid,               _rhs.data_spid,               12);
        do_compare &= comparer.compare_field    ("data_dpid",               data_dpid,               _rhs.data_dpid,               12);
      end
      do_compare &= comparer.compare_field_int  ("data_poison",             data_poison,             _rhs.data_poison,             1);
      do_compare &= comparer.compare_field_int  ("data_parity",             data_parity,             _rhs.data_parity,             8);
      do_compare &= comparer.compare_field_int  ("data_eop",                data_eop,                _rhs.data_eop,                1);
      if (emd_bits) begin 
        /* M2S */
        if (info2=="F2A" && data_protocol_id==4'b1011) begin //DSP
          if (data_header.dsp.f2am.metafield==2'b01) // ==ExtMetaState
            do_compare &= comparer.compare_field("data_emd",                data_emd,                _rhs.data_emd,                emd_bits);
        end
        else if (info2=="A2F" && data_protocol_id==4'b1000) begin //USP
          if (data_header.usp.a2fm.metafield==2'b01) // ==ExtMetaState
            do_compare &= comparer.compare_field("data_emd",                data_emd,                _rhs.data_emd,                emd_bits);
        end
        /* S2M */
        else if (info2=="F2A" && data_protocol_id==4'b1000) begin //USP
          if (data_header.usp.f2am.metafield==2'b01) // ==ExtMetaState
            do_compare &= comparer.compare_field("data_emd",                data_emd,                _rhs.data_emd,                emd_bits);
        end
        else if (info2=="A2F" && data_protocol_id==4'b1011) begin //DSP
          if (data_header.dsp.a2fm.metafield==2'b01) // ==ExtMetaState
            do_compare &= comparer.compare_field("data_emd",                data_emd,                _rhs.data_emd,                emd_bits);
        end
      end
    end
    else if ({txfer, credrtn} == 2'b01) begin 
      // Dedicated Credit 
      do_compare &= comparer.compare_field_int("data_rxcrd_valid", data_rxcrd_valid, _rhs.data_rxcrd_valid, 1);
      if (data_rxcrd_valid || _rhs.data_rxcrd_valid) begin
        do_compare &= comparer.compare_field_int("data_rxcrd_protocol_id", data_rxcrd_protocol_id, _rhs.data_rxcrd_protocol_id, 2);
        do_compare &= comparer.compare_field_int("data_rxcrd_vc_id",       data_rxcrd_vc_id,       _rhs.data_rxcrd_vc_id,       4);
      end
      // Shared Credit
      do_compare &= comparer.compare_field_int("data_rxcrd_shared", data_rxcrd_shared, _rhs.data_rxcrd_shared, 1);
    end
    else
      `uvm_fatal(get_type_name, "Invalid txn setting, must have exclusively txfer or credrtn set")
  endfunction

endclass
