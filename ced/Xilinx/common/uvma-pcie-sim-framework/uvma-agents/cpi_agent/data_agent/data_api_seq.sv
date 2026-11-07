class data_api_seq extends uvm_sequence#(data_txn);

  `uvm_object_utils(data_api_seq)

  function new(string name = "data_api_seq");
    super.new(name);
  endfunction

  bit a2f;
  bit flit_mode_enc_en;
  bit ide_epoch_support;
  bit skip_credit_check;
  bit emd_sup;

  bit restrict_shared_credit    = 1'b0;
  bit restrict_data_vc_id[15:0] = '{16{1'b0}}; //per bit restriction of randomization to
                                               //resolve to that value (for crediting)
  bit insert_cmd_par_err  = 1'b0;
  bit insert_dat_par_err  = 1'b0;
  bit insert_addr_par_err = 1'b0;
  bit insert_be_par_err   = 1'b0;
  bit insert_poison       = 1'b0;

  local hdr_u pre_data_hdr; //pre-(randomization); allows per-field randomization

        bit   [  3:0] data_protocol_id;
  rand  logic [  3:0] data_vc_id = 'x;
  rand  logic         data_shared_credit = 'x;
  rand  hdr_u         data_header;
  rand  logic [511:0] data_body = 'x;
  rand  logic [ 63:0] data_byte_enable = 'x; 
  rand  logic [ 11:0] data_spid = 'x;
  rand  logic [ 11:0] data_dpid = 'x;
  rand  logic [ 31:0] data_emd  = 'x;

  rand  bit do_byte_enable;

  virtual task body;
    data_txn t = data_txn::type_id::create("t");
    void'(this.randomize());
    start_item(t);
    t.info2                 = a2f ? "A2F" : "F2A";
    t.txfer                 = 1'b1;
    t.data_is_valid         = 1'b1;
    t.data_early_valid      = 1'b0;
    t.data_protocol_id      = data_protocol_id;
    t.data_vc_id            = data_vc_id;
    t.data_shared_credit    = data_shared_credit;
    t.data_sz               = 1'b1;
    t.data_body             = data_body;
    t.data_spid             = data_spid;
    t.data_dpid             = data_dpid;
    t.data_poison           = insert_poison;
    t.data_eop              = 1'b1;
    t.data_emd              = data_emd;
    t.data_txblock_crd_flow = 1'b0;
    // Enforce BE restrictions of CXL Spec 3.1 Table 4-3 : "Legal values of Sz and BE Fields"
    if ({a2f,data_protocol_id} inside {5'b1_1001, 5'b0_1011, 5'b0_1000, 5'b1_1010})
      t.data_byte_enable = data_byte_enable;
    else
      t.data_byte_enable = '1;
    // 1. Allows for fine randomization of each field of the header by overriding the 
    //    randomized results with what was set by the user. 
    // 2. Make sure all reserved fields are zero of data_header after randomization
    case ({a2f, data_protocol_id})
/*USP $*/  5'b1_1000: begin
             if (pre_data_hdr.usp.a2fc.goerr         !== 'x) data_header.usp.a2fc.goerr      = pre_data_hdr.usp.a2fc.goerr;
             if (pre_data_hdr.usp.a2fc.cqid          !== 'x) data_header.usp.a2fc.cqid       = pre_data_hdr.usp.a2fc.cqid;
             if (pre_data_hdr.usp.a2fc.chunkvalid    !== 'x) data_header.usp.a2fc.chunkvalid = pre_data_hdr.usp.a2fc.chunkvalid;
             if (pre_data_hdr.usp.a2fc.cacheid       !== 'x) data_header.usp.a2fc.cacheid    = pre_data_hdr.usp.a2fc.cacheid;
             if (!flit_mode_enc_en)                          data_header.usp.a2fc.flitmode   = '0;
             else if (pre_data_hdr.usp.a2fc.flitmode !== 'x) data_header.usp.a2fc.flitmode   = pre_data_hdr.usp.a2fc.flitmode;
             if (ide_epoch_support) begin
               if (pre_data_hdr.usp.a2fc.epochvalid !== 'x) data_header.usp.a2fc.epochvalid = pre_data_hdr.usp.a2fc.epochvalid;
               if (pre_data_hdr.usp.a2fc.epochid    !== 'x) data_header.usp.a2fc.epochid    = pre_data_hdr.usp.a2fc.epochid;
               if (pre_data_hdr.usp.a2fc.portid     !== 'x) data_header.usp.a2fc.portid     = pre_data_hdr.usp.a2fc.portid;
             end
             else begin
               data_header.usp.a2fc.epochvalid = '0;
               data_header.usp.a2fc.epochid    = '0;
               data_header.usp.a2fc.portid     = '0;
             end
             data_header.usp.a2fc.rsvd7to1 = '0;
             data_header.usp.a2fc.rsvd_ext = '0;
           end
/*USP $*/  5'b0_1000: 
           begin
             if (pre_data_hdr.usp.f2ac.uqid          !== 'x) data_header.usp.f2ac.uqid       = pre_data_hdr.usp.f2ac.uqid;
             if (pre_data_hdr.usp.f2ac.bogus         !== 'x) data_header.usp.f2ac.bogus      = pre_data_hdr.usp.f2ac.bogus;
             if (pre_data_hdr.usp.f2ac.chunkvalid    !== 'x) data_header.usp.f2ac.chunkvalid = pre_data_hdr.usp.f2ac.chunkvalid;
             if (!flit_mode_enc_en)                          data_header.usp.f2ac.flitmode   = '0;
             else if (pre_data_hdr.usp.f2ac.flitmode !== 'x) data_header.usp.f2ac.flitmode   = pre_data_hdr.usp.f2ac.flitmode;
             data_header.usp.f2ac.rsvd12   = '0;
             data_header.usp.f2ac.rsvd_ext = '0;
           end
/*USP MEM*/5'b1_1001: 
           begin
             if (pre_data_hdr.usp.a2fm.memopcode        !== 'x) data_header.usp.a2fm.memopcode        = pre_data_hdr.usp.a2fm.memopcode;
             if (pre_data_hdr.usp.a2fm.metafield        !== 'x) data_header.usp.a2fm.metafield        = pre_data_hdr.usp.a2fm.metafield;
             if (pre_data_hdr.usp.a2fm.metavalue        !== 'x) data_header.usp.a2fm.metavalue        = pre_data_hdr.usp.a2fm.metavalue;
             if (pre_data_hdr.usp.a2fm.snptype          !== 'x) data_header.usp.a2fm.snptype          = pre_data_hdr.usp.a2fm.snptype;
             if (pre_data_hdr.usp.a2fm.tc               !== 'x) data_header.usp.a2fm.tc               = pre_data_hdr.usp.a2fm.tc;
             if (pre_data_hdr.usp.a2fm.address51to6_even!== 'x) data_header.usp.a2fm.address51to6_even= pre_data_hdr.usp.a2fm.address51to6_even;
             if (pre_data_hdr.usp.a2fm.tag              !== 'x) data_header.usp.a2fm.tag              = pre_data_hdr.usp.a2fm.tag;
             if (pre_data_hdr.usp.a2fm.address51to6_odd !== 'x) data_header.usp.a2fm.address51to6_odd = pre_data_hdr.usp.a2fm.address51to6_odd;
             if (pre_data_hdr.usp.a2fm.ldid             !== 'x) data_header.usp.a2fm.ldid             = pre_data_hdr.usp.a2fm.ldid;
             if (!flit_mode_enc_en)                             data_header.usp.a2fm.flitmode         = '0;
             else if (pre_data_hdr.usp.a2fm.flitmode !== 'x)    data_header.usp.a2fm.flitmode         = pre_data_hdr.usp.a2fm.flitmode;
             if (ide_epoch_support) begin                                                            
               if (pre_data_hdr.usp.a2fm.epochvalid !== 'x) data_header.usp.a2fm.epochvalid          = pre_data_hdr.usp.a2fm.epochvalid;
               if (pre_data_hdr.usp.a2fm.epochid    !== 'x) data_header.usp.a2fm.epochid             = pre_data_hdr.usp.a2fm.epochid;
               if (pre_data_hdr.usp.a2fm.portid     !== 'x) data_header.usp.a2fm.portid              = pre_data_hdr.usp.a2fm.portid;
             end
             else begin
               data_header.usp.a2fm.epochvalid = '0;
               data_header.usp.a2fm.epochid    = '0;
               data_header.usp.a2fm.portid     = '0;
             end
             data_header.usp.a2fm.rsvd14to13 = '0;
           end
/*USP MEM*/5'b0_1001:
           begin
             if (pre_data_hdr.usp.f2am.opcode    !== 'x)     data_header.usp.f2am.opcode   = pre_data_hdr.usp.f2am.opcode;
             if (pre_data_hdr.usp.f2am.metafield !== 'x)     data_header.usp.f2am.metafield= pre_data_hdr.usp.f2am.metafield;
             if (pre_data_hdr.usp.f2am.metavalue !== 'x)     data_header.usp.f2am.metavalue= pre_data_hdr.usp.f2am.metavalue;
             if (pre_data_hdr.usp.f2am.tag       !== 'x)     data_header.usp.f2am.tag      = pre_data_hdr.usp.f2am.tag;
             if (pre_data_hdr.usp.f2am.ldid      !== 'x)     data_header.usp.f2am.ldid     = pre_data_hdr.usp.f2am.ldid;
             if (pre_data_hdr.usp.f2am.devload   !== 'x)     data_header.usp.f2am.devload  = pre_data_hdr.usp.f2am.devload;
             if (!flit_mode_enc_en)                          data_header.usp.f2am.flitmode = '0;
             else if (pre_data_hdr.usp.f2am.flitmode !== 'x) data_header.usp.f2am.flitmode = pre_data_hdr.usp.f2am.flitmode;
             data_header.usp.f2am.rsvd15to8 = '0;
             data_header.usp.f2am.rsvd3     = '0;
             data_header.usp.f2am.rsvd_ext  = '0;
           end
/*DSP $*/  5'b1_1010:
           begin
             if (pre_data_hdr.dsp.a2fc.uqid          !== 'x) data_header.dsp.a2fc.uqid       = pre_data_hdr.dsp.a2fc.uqid;
             if (pre_data_hdr.dsp.a2fc.bogus         !== 'x) data_header.dsp.a2fc.bogus      = pre_data_hdr.dsp.a2fc.bogus;
             if (pre_data_hdr.dsp.a2fc.chunkvalid    !== 'x) data_header.dsp.a2fc.chunkvalid = pre_data_hdr.dsp.a2fc.chunkvalid;
             if (!flit_mode_enc_en)                          data_header.dsp.a2fc.flitmode   = '0;
             else if (pre_data_hdr.dsp.a2fc.flitmode !== 'x) data_header.dsp.a2fc.flitmode   = pre_data_hdr.dsp.a2fc.flitmode;
             if (ide_epoch_support) begin                                                            
               if (pre_data_hdr.dsp.a2fc.epochvalid !== 'x) data_header.dsp.a2fc.epochvalid          = pre_data_hdr.dsp.a2fc.epochvalid;
               if (pre_data_hdr.dsp.a2fc.epochid    !== 'x) data_header.dsp.a2fc.epochid             = pre_data_hdr.dsp.a2fc.epochid;
               if (pre_data_hdr.dsp.a2fc.portid     !== 'x) data_header.dsp.a2fc.portid              = pre_data_hdr.dsp.a2fc.portid;
             end
             else begin
               data_header.dsp.a2fc.epochvalid = '0;
               data_header.dsp.a2fc.epochid    = '0;
               data_header.dsp.a2fc.portid     = '0;
             end
             data_header.dsp.a2fc.rsvd12   = '0;
             data_header.dsp.a2fc.rsvd_ext = '0;
           end
/*DSP $*/  5'b0_1010:
           begin
             if (pre_data_hdr.dsp.f2ac.goerr         !== 'x) data_header.dsp.f2ac.goerr      = pre_data_hdr.dsp.f2ac.goerr;
             if (pre_data_hdr.dsp.f2ac.cqid          !== 'x) data_header.dsp.f2ac.cqid       = pre_data_hdr.dsp.f2ac.cqid;
             if (pre_data_hdr.dsp.f2ac.chunkvalid    !== 'x) data_header.dsp.f2ac.chunkvalid = pre_data_hdr.dsp.f2ac.chunkvalid;
             if (pre_data_hdr.dsp.f2ac.cacheid       !== 'x) data_header.dsp.f2ac.cacheid    = pre_data_hdr.dsp.f2ac.cacheid;
             if (!flit_mode_enc_en)                          data_header.dsp.f2ac.flitmode   = '0;
             else if (pre_data_hdr.dsp.f2ac.flitmode !== 'x) data_header.dsp.f2ac.flitmode   = pre_data_hdr.dsp.f2ac.flitmode;
             data_header.dsp.f2ac.rsvd7to1 = '0;
             data_header.dsp.f2ac.rsvd_ext = '0;
           end
/*DSP MEM*/5'b1_1011:
           begin
             if (pre_data_hdr.dsp.a2fm.opcode    !== 'x)     data_header.dsp.a2fm.opcode     = pre_data_hdr.dsp.a2fm.opcode;
             if (pre_data_hdr.dsp.a2fm.metafield !== 'x)     data_header.dsp.a2fm.metafield  = pre_data_hdr.dsp.a2fm.metafield;
             if (pre_data_hdr.dsp.a2fm.metavalue !== 'x)     data_header.dsp.a2fm.metavalue  = pre_data_hdr.dsp.a2fm.metavalue;
             if (pre_data_hdr.dsp.a2fm.tag       !== 'x)     data_header.dsp.a2fm.tag        = pre_data_hdr.dsp.a2fm.tag;
             if (pre_data_hdr.dsp.a2fm.ldid      !== 'x)     data_header.dsp.a2fm.ldid       = pre_data_hdr.dsp.a2fm.ldid;
             if (pre_data_hdr.dsp.a2fm.devload   !== 'x)     data_header.dsp.a2fm.devload    = pre_data_hdr.dsp.a2fm.devload;
             if (!flit_mode_enc_en)                          data_header.dsp.a2fm.flitmode   = '0;
             else if (pre_data_hdr.dsp.a2fm.flitmode !== 'x) data_header.dsp.a2fm.flitmode   = pre_data_hdr.dsp.a2fm.flitmode;
             if (ide_epoch_support) begin
               if (pre_data_hdr.dsp.a2fm.epochvalid !== 'x)  data_header.dsp.a2fm.epochvalid = pre_data_hdr.dsp.a2fm.epochvalid;
               if (pre_data_hdr.dsp.a2fm.epochid    !== 'x)  data_header.dsp.a2fm.epochid    = pre_data_hdr.dsp.a2fm.epochid;
               if (pre_data_hdr.dsp.a2fm.portid     !== 'x)  data_header.dsp.a2fm.portid     = pre_data_hdr.dsp.a2fm.portid;
             end
             data_header.dsp.a2fm.rsvd15to8 = '0;
             data_header.dsp.a2fm.rsvd3     = '0;
             data_header.dsp.a2fm.rsvd_ext  = '0;
           end
/*DSP MEM*/5'b0_1011:
           begin
             if (pre_data_hdr.dsp.f2am.memopcode        !== 'x) data_header.dsp.f2am.memopcode        = pre_data_hdr.dsp.f2am.memopcode;
             if (pre_data_hdr.dsp.f2am.metafield        !== 'x) data_header.dsp.f2am.metafield        = pre_data_hdr.dsp.f2am.metafield;
             if (pre_data_hdr.dsp.f2am.metavalue        !== 'x) data_header.dsp.f2am.metavalue        = pre_data_hdr.dsp.f2am.metavalue;
             if (pre_data_hdr.dsp.f2am.snptype          !== 'x) data_header.dsp.f2am.snptype          = pre_data_hdr.dsp.f2am.snptype;
             if (pre_data_hdr.dsp.f2am.tc               !== 'x) data_header.dsp.f2am.tc               = pre_data_hdr.dsp.f2am.tc;
             if (pre_data_hdr.dsp.f2am.address51to6_even!== 'x) data_header.dsp.f2am.address51to6_even= pre_data_hdr.dsp.f2am.address51to6_even;
             if (pre_data_hdr.dsp.f2am.tag              !== 'x) data_header.dsp.f2am.tag              = pre_data_hdr.dsp.f2am.tag;
             if (pre_data_hdr.dsp.f2am.address51to6_odd !== 'x) data_header.dsp.f2am.address51to6_odd = pre_data_hdr.dsp.f2am.address51to6_odd;
             if (pre_data_hdr.dsp.f2am.ldid             !== 'x) data_header.dsp.f2am.ldid             = pre_data_hdr.dsp.f2am.ldid;
             if (!flit_mode_enc_en)                             data_header.dsp.f2am.flitmode         = '0;
             else if (pre_data_hdr.dsp.f2am.flitmode !== 'x)    data_header.dsp.f2am.flitmode         = pre_data_hdr.dsp.f2am.flitmode;
             data_header.dsp.f2am.rsvd14to13 = '0;
             data_header.dsp.f2am.rsvd_ext   = '0;
           end
      default : `uvm_fatal("INVALID", "Invalid protocol id for data_agent")
    endcase
    // Set header after controlled randomization
    t.data_header = data_header;
    // Calculate parity; optionally insert error
    t.set_address_parity(insert_addr_par_err);
    t.set_cmd_parity(insert_cmd_par_err);
    t.set_data_parity(insert_dat_par_err);
    t.set_be_parity(insert_be_par_err);
    // Send it
    finish_item(t);
  endtask

  // If user has set a field, turn off randomization for it before this class 
  // gets randomized, which enables coarse randomization of a member.
  function void pre_randomize();
    pre_data_hdr = data_header;
    if (data_vc_id !== 'x)         data_vc_id.rand_mode(0);
    if (data_shared_credit !== 'x) data_shared_credit.rand_mode(0);
    if (data_body !== 'x)          data_body.rand_mode(0);
    if (data_spid !== 'x)          data_spid.rand_mode(0);
    if (data_dpid !== 'x)          data_dpid.rand_mode(0);
    if ((a2f && (data_protocol_id inside {4'b1001, 4'b1010})) || (!a2f && (data_protocol_id inside {4'b1011, 4'b1000}))) begin
      if (data_byte_enable !== 'x) data_byte_enable.rand_mode(0);
    end
    else begin
      do_byte_enable.rand_mode(0);
      do_byte_enable = 0;
    end
    if (data_protocol_id[0] && data_emd !== 'x) data_emd.rand_mode(0);
    if (skip_credit_check) constr_data_vc_id.constraint_mode(0);
  endfunction

  constraint constr_data_vc_id {
    restrict_shared_credit -> data_shared_credit == 1'b0;
    if (!data_shared_credit) {
      foreach (restrict_data_vc_id[ii]) { 
        if (restrict_data_vc_id[ii])
          data_vc_id != ii;
      }
    }
  } 

  constraint constr_data_be {
    // 75% of time, don't do byte enables
    do_byte_enable dist {0 := 75, 1 := 25};
    !do_byte_enable -> data_byte_enable == '1;
    do_byte_enable  -> data_byte_enable != '1;
  }

  constraint constr_no_emd {
    // Downstream CXL.mem (M2SRwD)
    if (!emd_sup) {
      { a2f, data_protocol_id} == {1'b1, 4'b1001} -> data_header.usp.a2fm.metafield != 2'h1;
      {!a2f, data_protocol_id} == {1'b1, 4'b1011} -> data_header.dsp.f2am.metafield != 2'h1;
    }
  }

  constraint constr_vld_opcode {
    // Downstream CXL.mem (M2SRwD)
    { a2f, data_protocol_id} == {1'b1, 4'b1001} -> data_header.usp.a2fm.memopcode inside {1, 2, 4, 5, 9, 10, 13};
    {!a2f, data_protocol_id} == {1'b1, 4'b1011} -> data_header.dsp.f2am.memopcode inside {1, 2, 4, 5, 9, 10, 13};
    if (do_byte_enable) {
      if ({ a2f, data_protocol_id} == {1'b1, 4'b1001}) data_header.usp.a2fm.memopcode inside {2, 10};
      if ({!a2f, data_protocol_id} == {1'b1, 4'b1011}) data_header.dsp.f2am.memopcode inside {2, 10};
    }
    // Upstream CXL.mem (S2MDRS)
    { a2f, data_protocol_id} == {1'b1, 4'b1011} -> data_header.dsp.a2fm.opcode inside {[0:2]};
    {!a2f, data_protocol_id} == {1'b1, 4'b1001} -> data_header.usp.f2am.opcode inside {[0:2]};
  }

endclass
