class req_api_seq extends uvm_sequence#(req_txn);

  `uvm_object_utils(req_api_seq)

  function new(string name = "req_api_seq");
    super.new(name);
  endfunction

  bit a2f;
  bit flit_mode_enc_en;
  bit ide_epoch_support;
  bit skip_credit_check;
  bit emd_sup;

  bit restrict_shared_credit   = 1'b0;
  bit restrict_req_vc_id[15:0] = '{16{1'b0}}; //per bit restriction of randomization to
                                              //resolve to that value (for crediting)
  bit insert_cmd_par_err = 1'b0;
  bit insert_addr_par_err = 1'b0;

  local hdr_u pre_req_hdr; //pre-(randomization); allows per-field randomization

        bit   [  3:0] req_protocol_id;
  rand  logic [  3:0] req_vc_id = 'x;
  rand  logic         req_shared_credit = 'x;
  rand  hdr_u         req_header;
  rand  logic [ 11:0] req_spid = 'x;
  rand  logic [ 11:0] req_dpid = 'x;

  virtual task body;
    req_txn t = req_txn::type_id::create("t");
    void'(this.randomize());
    start_item(t);
    t.info2                = a2f ? "A2F" : "F2A";
    t.txfer                = 1'b1;
    t.req_is_valid         = 1'b1;
    t.req_early_valid      = 1'b0;
    t.req_protocol_id      = req_protocol_id;
    t.req_vc_id            = req_vc_id;
    t.req_shared_credit    = req_shared_credit;
    t.req_spid             = req_spid;
    t.req_dpid             = req_dpid;
    t.req_txblock_crd_flow = 1'b0;
    // 1. Allows for fine randomization of each field of the header by overriding the 
    //    randomized results with what was set by the user. 
    // 2. Make sure all reserved fields are zero of req_header after randomization
    case ({a2f,req_protocol_id})
/*USP $*/  5'b1_1000 : 
           begin
             if (pre_req_hdr.usp.a2fc.opcode       !== 'x)  req_header.usp.a2fc.opcode       = pre_req_hdr.usp.a2fc.opcode;
             if (pre_req_hdr.usp.a2fc.uqid         !== 'x)  req_header.usp.a2fc.uqid         = pre_req_hdr.usp.a2fc.uqid;
             if (pre_req_hdr.usp.a2fc.address51to6 !== 'x)  req_header.usp.a2fc.address51to6 = pre_req_hdr.usp.a2fc.address51to6;
             if (pre_req_hdr.usp.a2fc.cacheid      !== 'x)  req_header.usp.a2fc.cacheid      = pre_req_hdr.usp.a2fc.cacheid;
             if (!flit_mode_enc_en)                         req_header.usp.a2fc.flitmode     = '0;
             else if (pre_req_hdr.usp.a2fc.flitmode !== 'x) req_header.usp.a2fc.flitmode     = pre_req_hdr.usp.a2fc.flitmode;
             if (ide_epoch_support) begin
               if (pre_req_hdr.usp.a2fc.epochvalid !== 'x)  req_header.usp.a2fc.epochvalid   = pre_req_hdr.usp.a2fc.epochvalid;
               if (pre_req_hdr.usp.a2fc.epochid    !== 'x)  req_header.usp.a2fc.epochid      = pre_req_hdr.usp.a2fc.epochid;
               if (pre_req_hdr.usp.a2fc.portid     !== 'x)  req_header.usp.a2fc.portid       = pre_req_hdr.usp.a2fc.portid;
             end
             else begin
               req_header.usp.a2fc.epochvalid = '0;
               req_header.usp.a2fc.epochid    = '0;
               req_header.usp.a2fc.portid     = '0;
             end
             req_header.usp.a2fc.rsvd_ext = '0;
           end
/*USP $*/  5'b0_1000 : 
           begin
             if (pre_req_hdr.usp.f2ac.opcode       !== 'x)  req_header.usp.f2ac.opcode       = pre_req_hdr.usp.f2ac.opcode;
             if (pre_req_hdr.usp.f2ac.cqid         !== 'x)  req_header.usp.f2ac.cqid         = pre_req_hdr.usp.f2ac.cqid;
             if (pre_req_hdr.usp.f2ac.nt           !== 'x)  req_header.usp.f2ac.nt           = pre_req_hdr.usp.f2ac.nt;
             if (pre_req_hdr.usp.f2ac.address51to6 !== 'x)  req_header.usp.f2ac.address51to6 = pre_req_hdr.usp.f2ac.address51to6;
             if (pre_req_hdr.usp.f2ac.cacheid      !== 'x)  req_header.usp.f2ac.cacheid      = pre_req_hdr.usp.f2ac.cacheid;
             if (!flit_mode_enc_en)                         req_header.usp.f2ac.flitmode     = '0;
             else if (pre_req_hdr.usp.f2ac.flitmode !== 'x) req_header.usp.f2ac.flitmode     = pre_req_hdr.usp.f2ac.flitmode;
             req_header.usp.f2ac.rsvd19to18 = '0;
             req_header.usp.f2ac.rsvd_ext   = '0;
           end
/*USP MEM*/5'b1_1001 : 
           begin
             if (pre_req_hdr.usp.a2fm.memopcode    !== 'x)  req_header.usp.a2fm.memopcode    = pre_req_hdr.usp.a2fm.memopcode;
             if (pre_req_hdr.usp.a2fm.tag          !== 'x)  req_header.usp.a2fm.tag          = pre_req_hdr.usp.a2fm.tag;
             if (pre_req_hdr.usp.a2fm.tc           !== 'x)  req_header.usp.a2fm.tc           = pre_req_hdr.usp.a2fm.tc;
             if (pre_req_hdr.usp.a2fm.snptype      !== 'x)  req_header.usp.a2fm.snptype      = pre_req_hdr.usp.a2fm.snptype;
             if (pre_req_hdr.usp.a2fm.address5     !== 'x)  req_header.usp.a2fm.address5     = pre_req_hdr.usp.a2fm.address5;
             if (pre_req_hdr.usp.a2fm.metafield    !== 'x)  req_header.usp.a2fm.metafield    = pre_req_hdr.usp.a2fm.metafield;
             if (pre_req_hdr.usp.a2fm.metavalue    !== 'x)  req_header.usp.a2fm.metavalue    = pre_req_hdr.usp.a2fm.metavalue;
             if (pre_req_hdr.usp.a2fm.address51to6 !== 'x)  req_header.usp.a2fm.address51to6 = pre_req_hdr.usp.a2fm.address51to6;
             if (pre_req_hdr.usp.a2fm.ldid         !== 'x)  req_header.usp.a2fm.ldid         = pre_req_hdr.usp.a2fm.ldid;
             if (!flit_mode_enc_en)                         req_header.usp.a2fm.flitmode     = '0;
             else if (pre_req_hdr.usp.a2fm.flitmode !== 'x) req_header.usp.a2fm.flitmode     = pre_req_hdr.usp.a2fm.flitmode;
             if (ide_epoch_support) begin
               if (pre_req_hdr.usp.a2fm.epochvalid !== 'x)  req_header.usp.a2fm.epochvalid   = pre_req_hdr.usp.a2fm.epochvalid;
               if (pre_req_hdr.usp.a2fm.epochid    !== 'x)  req_header.usp.a2fm.epochid      = pre_req_hdr.usp.a2fm.epochid;
               if (pre_req_hdr.usp.a2fm.portid     !== 'x)  req_header.usp.a2fm.portid       = pre_req_hdr.usp.a2fm.portid;
             end
             else begin
               req_header.usp.a2fm.epochvalid = '0;
               req_header.usp.a2fm.epochid    = '0;
               req_header.usp.a2fm.portid     = '0;
             end
           end
/*USP MEM*/5'b0_1001 : 
           begin
             if (pre_req_hdr.usp.f2am.opcode       !== 'x)  req_header.usp.f2am.opcode       = pre_req_hdr.usp.f2am.opcode;
             if (pre_req_hdr.usp.f2am.biid         !== 'x)  req_header.usp.f2am.biid         = pre_req_hdr.usp.f2am.biid;
             if (pre_req_hdr.usp.f2am.bitag        !== 'x)  req_header.usp.f2am.bitag        = pre_req_hdr.usp.f2am.bitag;
             if (pre_req_hdr.usp.f2am.address51to6 !== 'x)  req_header.usp.f2am.address51to6 = pre_req_hdr.usp.f2am.address51to6;
             if (!flit_mode_enc_en)                         req_header.usp.f2am.flitmode     = '0;
             else if (pre_req_hdr.usp.f2am.flitmode !== 'x) req_header.usp.f2am.flitmode     = pre_req_hdr.usp.f2am.flitmode;
             req_header.usp.f2am.rsvd_ext = '0;
           end
/*DSP $*/  5'b1_1010 : 
           begin
             if (pre_req_hdr.dsp.a2fc.opcode       !== 'x)  req_header.dsp.a2fc.opcode       = pre_req_hdr.dsp.a2fc.opcode;
             if (pre_req_hdr.dsp.a2fc.cqid         !== 'x)  req_header.dsp.a2fc.cqid         = pre_req_hdr.dsp.a2fc.cqid;
             if (pre_req_hdr.dsp.a2fc.nt           !== 'x)  req_header.dsp.a2fc.nt           = pre_req_hdr.dsp.a2fc.nt;
             if (pre_req_hdr.dsp.a2fc.dev_trust_lvl!== 'x)  req_header.dsp.a2fc.dev_trust_lvl= pre_req_hdr.dsp.a2fc.dev_trust_lvl;
             if (pre_req_hdr.dsp.a2fc.address51to6 !== 'x)  req_header.dsp.a2fc.address51to6 = pre_req_hdr.dsp.a2fc.address51to6;
             if (pre_req_hdr.dsp.a2fc.cacheid      !== 'x)  req_header.dsp.a2fc.cacheid      = pre_req_hdr.dsp.a2fc.cacheid;
             if (!flit_mode_enc_en)                         req_header.dsp.a2fc.flitmode     = '0;
             else if (pre_req_hdr.dsp.a2fc.flitmode !== 'x) req_header.dsp.a2fc.flitmode     = pre_req_hdr.dsp.a2fc.flitmode;
             if (ide_epoch_support) begin
               if (pre_req_hdr.dsp.a2fc.epochvalid !== 'x)  req_header.dsp.a2fc.epochvalid   = pre_req_hdr.dsp.a2fc.epochvalid;
               if (pre_req_hdr.dsp.a2fc.epochid    !== 'x)  req_header.dsp.a2fc.epochid      = pre_req_hdr.dsp.a2fc.epochid;
               if (pre_req_hdr.dsp.a2fc.portid     !== 'x)  req_header.dsp.a2fc.portid       = pre_req_hdr.dsp.a2fc.portid;
             end
             else begin
               req_header.dsp.a2fc.epochvalid = '0;
               req_header.dsp.a2fc.epochid    = '0;
               req_header.dsp.a2fc.portid     = '0;
             end
             req_header.dsp.a2fc.rsvd_ext = '0;
           end
/*DSP $*/  5'b0_1010 : 
           begin
             if (pre_req_hdr.dsp.f2ac.opcode       !== 'x)  req_header.dsp.f2ac.opcode       = pre_req_hdr.dsp.f2ac.opcode;
             if (pre_req_hdr.dsp.f2ac.uqid         !== 'x)  req_header.dsp.f2ac.uqid         = pre_req_hdr.dsp.f2ac.uqid;
             if (pre_req_hdr.dsp.f2ac.address51to6 !== 'x)  req_header.dsp.f2ac.address51to6 = pre_req_hdr.dsp.f2ac.address51to6;
             if (pre_req_hdr.dsp.f2ac.cacheid      !== 'x)  req_header.dsp.f2ac.cacheid      = pre_req_hdr.dsp.f2ac.cacheid;
             if (!flit_mode_enc_en)                         req_header.dsp.f2ac.flitmode     = '0;
             else if (pre_req_hdr.dsp.f2ac.flitmode !== 'x) req_header.dsp.f2ac.flitmode     = pre_req_hdr.dsp.f2ac.flitmode;
             req_header.dsp.f2ac.rsvd_ext = '0;
           end
/*DSP MEM*/5'b1_1011 : 
           begin
             if (pre_req_hdr.dsp.a2fm.opcode       !== 'x)  req_header.dsp.a2fm.opcode       = pre_req_hdr.dsp.a2fm.opcode;
             if (pre_req_hdr.dsp.a2fm.biid         !== 'x)  req_header.dsp.a2fm.biid         = pre_req_hdr.dsp.a2fm.biid;
             if (pre_req_hdr.dsp.a2fm.bitag        !== 'x)  req_header.dsp.a2fm.bitag        = pre_req_hdr.dsp.a2fm.bitag;
             if (pre_req_hdr.dsp.a2fm.address51to6 !== 'x)  req_header.dsp.a2fm.address51to6 = pre_req_hdr.dsp.a2fm.address51to6;
             if (!flit_mode_enc_en)                         req_header.dsp.a2fm.flitmode     = '0;
             else if (pre_req_hdr.dsp.a2fm.flitmode !== 'x) req_header.dsp.a2fm.flitmode     = pre_req_hdr.dsp.a2fm.flitmode;
             if (ide_epoch_support) begin
               if (pre_req_hdr.dsp.a2fm.epochvalid !== 'x)  req_header.dsp.a2fm.epochvalid   = pre_req_hdr.dsp.a2fm.epochvalid;
               if (pre_req_hdr.dsp.a2fm.epochid    !== 'x)  req_header.dsp.a2fm.epochid      = pre_req_hdr.dsp.a2fm.epochid;
               if (pre_req_hdr.dsp.a2fm.portid     !== 'x)  req_header.dsp.a2fm.portid       = pre_req_hdr.dsp.a2fm.portid;
             end
             else begin
               req_header.dsp.a2fm.epochvalid = '0;
               req_header.dsp.a2fm.epochid    = '0;
               req_header.dsp.a2fm.portid     = '0;
             end
             req_header.dsp.a2fm.rsvd_ext = '0;
           end
/*DSP MEM*/5'b0_1011 : 
           begin
             if (pre_req_hdr.dsp.f2am.memopcode    !== 'x)  req_header.dsp.f2am.memopcode    = pre_req_hdr.dsp.f2am.memopcode;
             if (pre_req_hdr.dsp.f2am.tag          !== 'x)  req_header.dsp.f2am.tag          = pre_req_hdr.dsp.f2am.tag;
             if (pre_req_hdr.dsp.f2am.tc           !== 'x)  req_header.dsp.f2am.tc           = pre_req_hdr.dsp.f2am.tc;
             if (pre_req_hdr.dsp.f2am.snptype      !== 'x)  req_header.dsp.f2am.snptype      = pre_req_hdr.dsp.f2am.snptype;
             if (pre_req_hdr.dsp.f2am.address5     !== 'x)  req_header.dsp.f2am.address5     = pre_req_hdr.dsp.f2am.address5;
             if (pre_req_hdr.dsp.f2am.metafield    !== 'x)  req_header.dsp.f2am.metafield    = pre_req_hdr.dsp.f2am.metafield;
             if (pre_req_hdr.dsp.f2am.metavalue    !== 'x)  req_header.dsp.f2am.metavalue    = pre_req_hdr.dsp.f2am.metavalue;
             if (pre_req_hdr.dsp.f2am.address51to6 !== 'x)  req_header.dsp.f2am.address51to6 = pre_req_hdr.dsp.f2am.address51to6;
             if (!flit_mode_enc_en)                         req_header.dsp.f2am.flitmode     = '0;
             else if (pre_req_hdr.dsp.f2am.flitmode !== 'x) req_header.dsp.f2am.flitmode     = pre_req_hdr.dsp.f2am.flitmode;
             req_header.dsp.f2am.rsvd_ext = '0;
           end
      default : `uvm_fatal("INVALID", "Invalid protocol id for req_agent")
    endcase
    // Set header after controlled randomization
    t.req_header = req_header;
    // Calculate parity; optionally insert error 
    t.set_address_parity(insert_addr_par_err);
    t.set_cmd_parity(insert_cmd_par_err);
    // Send it
    finish_item(t);
  endtask

  // If user has set a field, turn off randomization for it before this class 
  // gets randomized, which enables coarse randomization of a member.
  function void pre_randomize();
    pre_req_hdr = req_header;
    if (req_vc_id !== 'x)         req_vc_id.rand_mode(0);
    if (req_shared_credit !== 'x) req_shared_credit.rand_mode(0);
    if (req_spid !== 'x)          req_spid.rand_mode(0);
    if (req_dpid !== 'x)          req_dpid.rand_mode(0);
    if (skip_credit_check)        constr_req_vc_id.constraint_mode(0);
  endfunction

  constraint constr_req_vc_id {
    restrict_shared_credit -> req_shared_credit == 1'b0;
    if (!req_shared_credit) {
      foreach (restrict_req_vc_id[ii]) { 
        if (restrict_req_vc_id[ii])
          req_vc_id != ii;
      }
    }
  } 

  constraint constr_no_emd {
    if (!emd_sup) {
      // Downstream CXL.mem (M2SReq)
      { a2f, req_protocol_id} == {1'b1, 4'b1001} -> req_header.usp.a2fm.metafield != 2'h1;
      {!a2f, req_protocol_id} == {1'b1, 4'b1011} -> req_header.dsp.f2am.metafield != 2'h1;
    }
  }

  constraint constr_vld_opcode {
    // Downstream CXL.mem (M2SReq)
    { a2f, req_protocol_id} == {1'b1, 4'b1001} -> req_header.usp.a2fm.memopcode inside {[0:6], [8:10], 12, 13};
    {!a2f, req_protocol_id} == {1'b1, 4'b1011} -> req_header.dsp.f2am.memopcode inside {[0:6], [8:10], 12, 13};
    // Upstream CXL.mem (BISnp)
    { a2f, req_protocol_id} == {1'b1, 4'b1011} -> req_header.dsp.a2fm.opcode inside {[0:2], [4:6]};
    {!a2f, req_protocol_id} == {1'b1, 4'b1001} -> req_header.usp.f2am.opcode inside {[0:2], [4:6]};
  }

endclass
