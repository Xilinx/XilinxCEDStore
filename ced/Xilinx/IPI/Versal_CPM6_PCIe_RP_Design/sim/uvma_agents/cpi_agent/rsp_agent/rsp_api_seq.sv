class rsp_api_seq extends uvm_sequence#(rsp_txn);

  `uvm_object_utils(rsp_api_seq)

  function new(string name = "rsp_api_seq");
    super.new(name);
  endfunction

  bit a2f;
  bit flit_mode_enc_en;
  bit ide_epoch_support; 
  bit skip_credit_check;

  bit restrict_shared_credit   = 1'b0;
  bit restrict_rsp_vc_id[15:0] = '{16{1'b0}}; //per bit restriction of randomization to
                                              //resolve to that value (for crediting)
  bit insert_cmd_par_err = 1'b0;

  local hdr_u pre_rsp_hdr; //pre-(randomization); allows per-field randomization

        bit   [  3:0] rsp_protocol_id;
  rand  logic [  3:0] rsp_vc_id = 'x;
  rand  logic         rsp_shared_credit = 'x;
  rand  hdr_u         rsp_header;
  rand  logic [ 11:0] rsp_spid = 'x;
  rand  logic [ 11:0] rsp_dpid = 'x;

  virtual task body;
    rsp_txn t = rsp_txn::type_id::create("t");
    void'(this.randomize());
    start_item(t);
    t.info2                = a2f ? "A2F" : "F2A";
    t.txfer                = 1'b1;
    t.rsp_is_valid         = 1'b1;
    t.rsp_early_valid      = 1'b0;
    t.rsp_protocol_id      = rsp_protocol_id;
    t.rsp_vc_id            = rsp_vc_id;
    t.rsp_shared_credit    = rsp_shared_credit;
    t.rsp_spid             = rsp_spid;
    t.rsp_dpid             = rsp_dpid;
    t.rsp_txblock_crd_flow = 1'b0;
    // 1. Allows for fine randomization of each field of the header by overriding the 
    //    randomized results with what was set by the user. 
    // 2. Make sure all reserved fields are zero of rsp_header after randomization
    case ({a2f,rsp_protocol_id})
/*USP $*/  5'b1_1000 :
           begin
             if (pre_rsp_hdr.usp.a2fc.opcode  !== 'x)       rsp_header.usp.a2fc.opcode   = pre_rsp_hdr.usp.a2fc.opcode;
             if (pre_rsp_hdr.usp.a2fc.cqid    !== 'x)       rsp_header.usp.a2fc.cqid     = pre_rsp_hdr.usp.a2fc.cqid;
             if (pre_rsp_hdr.usp.a2fc.rsp_pre !== 'x)       rsp_header.usp.a2fc.rsp_pre  = pre_rsp_hdr.usp.a2fc.rsp_pre;
             if (pre_rsp_hdr.usp.a2fc.rspdata !== 'x)       rsp_header.usp.a2fc.rspdata  = pre_rsp_hdr.usp.a2fc.rspdata;
             if (pre_rsp_hdr.usp.a2fc.cacheid !== 'x)       rsp_header.usp.a2fc.cacheid  = pre_rsp_hdr.usp.a2fc.cacheid;
             if (!flit_mode_enc_en)                         rsp_header.usp.a2fc.flitmode = '0;
             else if (pre_rsp_hdr.usp.a2fc.flitmode !== 'x) rsp_header.usp.a2fc.flitmode = pre_rsp_hdr.usp.a2fc.flitmode;
             if (ide_epoch_support) begin
               if (pre_rsp_hdr.usp.a2fc.epochvalid !== 'x)  rsp_header.usp.a2fc.epochvalid = pre_rsp_hdr.usp.a2fc.epochvalid;
               if (pre_rsp_hdr.usp.a2fc.epochid    !== 'x)  rsp_header.usp.a2fc.epochid    = pre_rsp_hdr.usp.a2fc.epochid;
               if (pre_rsp_hdr.usp.a2fc.portid     !== 'x)  rsp_header.usp.a2fc.portid     = pre_rsp_hdr.usp.a2fc.portid;
             end
             else begin
               rsp_header.usp.a2fc.epochvalid = '0;
               rsp_header.usp.a2fc.epochid    = '0;
               rsp_header.usp.a2fc.portid     = '0;
             end
             rsp_header.usp.a2fc.rsvd18 = '0;
           end
/*USP $*/  5'b0_1000 :
           begin
             if (pre_rsp_hdr.usp.f2ac.opcode !== 'x)        rsp_header.usp.f2ac.opcode   = pre_rsp_hdr.usp.f2ac.opcode;
             if (pre_rsp_hdr.usp.f2ac.uqid   !== 'x)        rsp_header.usp.f2ac.uqid     = pre_rsp_hdr.usp.f2ac.uqid;
             if (!flit_mode_enc_en)                         rsp_header.usp.f2ac.flitmode = '0;
             else if (pre_rsp_hdr.usp.f2ac.flitmode !== 'x) rsp_header.usp.f2ac.flitmode = pre_rsp_hdr.usp.f2ac.flitmode;
             rsp_header.usp.f2ac.rsvd6to5 = '0;
             rsp_header.usp.f2ac.rsvd_ext = '0;
           end
/*USP MEM*/5'b1_1001 :
           begin
             if (pre_rsp_hdr.usp.a2fm.opcode  !== 'x)       rsp_header.usp.a2fm.opcode   = pre_rsp_hdr.usp.a2fm.opcode;
             if (pre_rsp_hdr.usp.a2fm.biid    !== 'x)       rsp_header.usp.a2fm.biid     = pre_rsp_hdr.usp.a2fm.biid;
             if (pre_rsp_hdr.usp.a2fm.bitag   !== 'x)       rsp_header.usp.a2fm.bitag    = pre_rsp_hdr.usp.a2fm.bitag;
             if (pre_rsp_hdr.usp.a2fm.lowaddr !== 'x)       rsp_header.usp.a2fm.lowaddr  = pre_rsp_hdr.usp.a2fm.lowaddr;
             if (!flit_mode_enc_en)                         rsp_header.usp.a2fm.flitmode = '0;
             else if (pre_rsp_hdr.usp.a2fm.flitmode !== 'x) rsp_header.usp.a2fm.flitmode = pre_rsp_hdr.usp.a2fm.flitmode;
             if (ide_epoch_support) begin
               if (pre_rsp_hdr.usp.a2fm.epochvalid !== 'x)  rsp_header.usp.a2fm.epochvalid = pre_rsp_hdr.usp.a2fm.epochvalid;
               if (pre_rsp_hdr.usp.a2fm.epochid    !== 'x)  rsp_header.usp.a2fm.epochid    = pre_rsp_hdr.usp.a2fm.epochid;
               if (pre_rsp_hdr.usp.a2fm.portid     !== 'x)  rsp_header.usp.a2fm.portid     = pre_rsp_hdr.usp.a2fm.portid;
             end
             else begin
               rsp_header.usp.a2fm.epochvalid = '0;
               rsp_header.usp.a2fm.epochid    = '0;
               rsp_header.usp.a2fm.portid     = '0;
             end
             rsp_header.usp.a2fm.rsvd_ext = '0;
           end
/*USP MEM*/5'b0_1001 :
           begin
             if (pre_rsp_hdr.usp.f2am.opcode    !== 'x)     rsp_header.usp.f2am.opcode   = pre_rsp_hdr.usp.f2am.opcode;
             if (pre_rsp_hdr.usp.f2am.metafield !== 'x)     rsp_header.usp.f2am.metafield= pre_rsp_hdr.usp.f2am.metafield;
             if (pre_rsp_hdr.usp.f2am.metavalue !== 'x)     rsp_header.usp.f2am.metavalue= pre_rsp_hdr.usp.f2am.metavalue;
             if (pre_rsp_hdr.usp.f2am.tag       !== 'x)     rsp_header.usp.f2am.tag      = pre_rsp_hdr.usp.f2am.tag;
             if (pre_rsp_hdr.usp.f2am.ldid      !== 'x)     rsp_header.usp.f2am.ldid     = pre_rsp_hdr.usp.f2am.ldid;
             if (pre_rsp_hdr.usp.f2am.devload   !== 'x)     rsp_header.usp.f2am.devload  = pre_rsp_hdr.usp.f2am.devload;
             if (!flit_mode_enc_en)                         rsp_header.usp.f2am.flitmode = '0;
             else if (pre_rsp_hdr.usp.f2am.flitmode !== 'x) rsp_header.usp.f2am.flitmode = pre_rsp_hdr.usp.f2am.flitmode;
             rsp_header.usp.f2am.rsvd_ext = '0;
           end
/*DSP $*/  5'b1_1010 :
           begin
             if (pre_rsp_hdr.dsp.a2fc.opcode !== 'x)        rsp_header.dsp.a2fc.opcode   = pre_rsp_hdr.dsp.a2fc.opcode;
             if (pre_rsp_hdr.dsp.a2fc.uqid   !== 'x)        rsp_header.dsp.a2fc.uqid     = pre_rsp_hdr.dsp.a2fc.uqid;
             if (!flit_mode_enc_en)                         rsp_header.dsp.a2fc.flitmode = '0;
             else if (pre_rsp_hdr.dsp.a2fc.flitmode !== 'x) rsp_header.dsp.a2fc.flitmode = pre_rsp_hdr.dsp.a2fc.flitmode;
             if (ide_epoch_support) begin
               if (pre_rsp_hdr.dsp.a2fc.epochvalid !== 'x)  rsp_header.dsp.a2fc.epochvalid = pre_rsp_hdr.dsp.a2fc.epochvalid;
               if (pre_rsp_hdr.dsp.a2fc.epochid    !== 'x)  rsp_header.dsp.a2fc.epochid    = pre_rsp_hdr.dsp.a2fc.epochid;
               if (pre_rsp_hdr.dsp.a2fc.portid     !== 'x)  rsp_header.dsp.a2fc.portid     = pre_rsp_hdr.dsp.a2fc.portid;
             end
             else begin
               rsp_header.dsp.a2fc.epochvalid = '0;
               rsp_header.dsp.a2fc.epochid    = '0;
               rsp_header.dsp.a2fc.portid     = '0;
             end
             rsp_header.dsp.a2fc.rsvd6to5 = '0;
             rsp_header.dsp.a2fc.rsvd_ext = '0;
           end
/*DSP $*/  5'b0_1010 :
           begin
             if (pre_rsp_hdr.dsp.f2ac.opcode  !== 'x)       rsp_header.dsp.f2ac.opcode   = pre_rsp_hdr.dsp.f2ac.opcode;
             if (pre_rsp_hdr.dsp.f2ac.cqid    !== 'x)       rsp_header.dsp.f2ac.cqid     = pre_rsp_hdr.dsp.f2ac.cqid;
             if (pre_rsp_hdr.dsp.f2ac.rsp_pre !== 'x)       rsp_header.dsp.f2ac.rsp_pre  = pre_rsp_hdr.dsp.f2ac.rsp_pre;
             if (pre_rsp_hdr.dsp.f2ac.rspdata !== 'x)       rsp_header.dsp.f2ac.rspdata  = pre_rsp_hdr.dsp.f2ac.rspdata;
             if (pre_rsp_hdr.dsp.f2ac.cacheid !== 'x)       rsp_header.dsp.f2ac.cacheid  = pre_rsp_hdr.dsp.f2ac.cacheid;
             if (!flit_mode_enc_en)                         rsp_header.dsp.f2ac.flitmode = '0;
             else if (pre_rsp_hdr.dsp.f2ac.flitmode !== 'x) rsp_header.dsp.f2ac.flitmode = pre_rsp_hdr.dsp.f2ac.flitmode;
             rsp_header.dsp.f2ac.rsvd_ext = '0;
           end
/*DSP MEM*/5'b1_1011 :
           begin
             if (pre_rsp_hdr.dsp.a2fm.opcode    !== 'x)     rsp_header.dsp.a2fm.opcode   = pre_rsp_hdr.dsp.a2fm.opcode;
             if (pre_rsp_hdr.dsp.a2fm.metafield !== 'x)     rsp_header.dsp.a2fm.metafield= pre_rsp_hdr.dsp.a2fm.metafield;
             if (pre_rsp_hdr.dsp.a2fm.metavalue !== 'x)     rsp_header.dsp.a2fm.metavalue= pre_rsp_hdr.dsp.a2fm.metavalue;
             if (pre_rsp_hdr.dsp.a2fm.tag       !== 'x)     rsp_header.dsp.a2fm.tag      = pre_rsp_hdr.dsp.a2fm.tag;
             if (pre_rsp_hdr.dsp.a2fm.ldid      !== 'x)     rsp_header.dsp.a2fm.ldid     = pre_rsp_hdr.dsp.a2fm.ldid;
             if (pre_rsp_hdr.dsp.a2fm.devload   !== 'x)     rsp_header.dsp.a2fm.devload  = pre_rsp_hdr.dsp.a2fm.devload;
             if (!flit_mode_enc_en)                         rsp_header.dsp.a2fm.flitmode = '0;
             else if (pre_rsp_hdr.dsp.a2fm.flitmode !== 'x) rsp_header.dsp.a2fm.flitmode = pre_rsp_hdr.dsp.a2fm.flitmode;
             if (ide_epoch_support) begin
               if (pre_rsp_hdr.dsp.a2fm.epochvalid !== 'x)  rsp_header.dsp.a2fm.epochvalid = pre_rsp_hdr.dsp.a2fm.epochvalid;
               if (pre_rsp_hdr.dsp.a2fm.epochid    !== 'x)  rsp_header.dsp.a2fm.epochid    = pre_rsp_hdr.dsp.a2fm.epochid;
               if (pre_rsp_hdr.dsp.a2fm.portid     !== 'x)  rsp_header.dsp.a2fm.portid     = pre_rsp_hdr.dsp.a2fm.portid;
             end
             else begin
               rsp_header.dsp.a2fm.epochvalid = '0;
               rsp_header.dsp.a2fm.epochid    = '0;
               rsp_header.dsp.a2fm.portid     = '0;
             end
             rsp_header.dsp.a2fm.rsvd_ext = '0;
           end
/*DSP MEM*/5'b0_1011 :
           begin
             if (pre_rsp_hdr.dsp.f2am.opcode  !== 'x)       rsp_header.dsp.f2am.opcode   = pre_rsp_hdr.dsp.f2am.opcode;
             if (pre_rsp_hdr.dsp.f2am.biid    !== 'x)       rsp_header.dsp.f2am.biid     = pre_rsp_hdr.dsp.f2am.biid;
             if (pre_rsp_hdr.dsp.f2am.bitag   !== 'x)       rsp_header.dsp.f2am.bitag    = pre_rsp_hdr.dsp.f2am.bitag;
             if (pre_rsp_hdr.dsp.f2am.lowaddr !== 'x)       rsp_header.dsp.f2am.lowaddr  = pre_rsp_hdr.dsp.f2am.lowaddr;
             if (!flit_mode_enc_en)                         rsp_header.dsp.f2am.flitmode = '0;
             else if (pre_rsp_hdr.dsp.f2am.flitmode !== 'x) rsp_header.dsp.f2am.flitmode = pre_rsp_hdr.dsp.f2am.flitmode;
             rsp_header.dsp.f2am.rsvd_ext = '0;
           end
      default : `uvm_fatal("INVALID", "Invalid protocol id for rsp_agent")
    endcase
    // Set header after controlled randomization
    t.rsp_header = rsp_header;
    // Calculate parity; optionally insert error 
    t.set_cmd_parity(insert_cmd_par_err);
    // Send it
    finish_item(t);
  endtask

  // If user has set a field, turn off randomization for it before this class 
  // gets randomized, which enables coarse randomization of a member.
  function void pre_randomize();
    pre_rsp_hdr = rsp_header;
    if (rsp_vc_id !== 'x)         rsp_vc_id.rand_mode(0);
    if (rsp_shared_credit !== 'x) rsp_shared_credit.rand_mode(0);
    if (skip_credit_check) constr_rsp_vc_id.constraint_mode(0);
  endfunction

  constraint constr_rsp_vc_id {
    restrict_shared_credit -> rsp_shared_credit == 1'b0; 
    if (!rsp_shared_credit) {   
      foreach (restrict_rsp_vc_id[ii]) { 
        if (restrict_rsp_vc_id[ii])
          rsp_vc_id != ii;
      }
    }
  } 

  constraint constr_vld_opcode {
    // Downstream CXL.mem (BIRsp)
    { a2f, rsp_protocol_id} == {1'b1, 4'b1001} -> rsp_header.usp.a2fm.opcode inside {[0:2], [4:6]};
    {!a2f, rsp_protocol_id} == {1'b1, 4'b1011} -> rsp_header.dsp.f2am.opcode inside {[0:2], [4:6]};
    // Upstream CXL.mem (S2MNDR
    { a2f, rsp_protocol_id} == {1'b1, 4'b1011} -> rsp_header.dsp.a2fm.opcode inside {[0:5]};
    {!a2f, rsp_protocol_id} == {1'b1, 4'b1001} -> rsp_header.usp.f2am.opcode inside {[0:5]};
  }

endclass
