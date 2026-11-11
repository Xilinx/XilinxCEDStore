class rsp_api#(type SQR) extends base_api#(SQR);

  `uvm_component_param_utils(rsp_api#(SQR))

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // USP A2F/DSP F2A : H2D Rsp/M2S BIRsp
  // USP F2A/DSP A2F : D2H Rsp/S2M NDR
  virtual task issue_msg(
    api_msg_t   msg_type,
    logic [3:0] vc_id = 'x,
    logic       shared_credit = 'x,
    hdr_u       header = 'x,
    // PBR flit only - off by default, set 'x to randomize
    logic [7:0] spid = '0,
    logic [7:0] dpid = '0,
    // Error injection
    bit         insert_cmd_par_err = 1'b0
  );

    // VCS won't elaborate unless assigning to temporary queue
    bit [7:0] vc_ids_w_credits[$] = sqr.shr.credit_cnt_ded[msg_type].find with (item!=0);

    rsp_api_seq seq = rsp_api_seq::type_id::create("seq");

    if (sqr.shr.gshr.conn_state != CONNECTED) begin
      `uvm_error("rsp_api::issue_msg", "CPI has not reached a CONNECTED state using global channel, cannot run sequence")
      return;
    end

    if ((!sqr.cfg.cxl_mem_sup && msg_type == MEM) || (!sqr.cfg.cxl_cch_sup && msg_type == CACHE)) begin
      `uvm_warning("rsp_api::issue_msg", $sformatf("Agent was not configured to support %0s messages; not issuing", msg_type.name))
      return;
    end

    if (!sqr.cfg.skip_credit_check) begin
      if (shared_credit === '1 && !sqr.shr.credit_cnt_shr) begin
        `uvm_warning("rsp_api::issue_msg", "Can't issue a message via shared credit, no shared credits are available")
        return;
      end
      else if (shared_credit === '0 && vc_ids_w_credits.size == 0) begin
        `uvm_warning("rsp_api::issue_msg", $sformatf("Can't issue a %0s message via dedicated credit, no dedicated credits are available",msg_type.name))
        return;
      end
      else if (shared_credit === '0 && vc_id !== 'x) begin 
        if (sqr.shr.credit_cnt_ded[msg_type][vc_id] == 0) begin
          `uvm_warning("rsp_api::issue_msg", $sformatf("Can't issue a %0s message via dedicated credit, no dedicated credits are available on vc_id %0d",msg_type.name, vc_id))
          return;
        end
      end
      else if (shared_credit === 'x && !sqr.shr.credit_cnt_shr && vc_ids_w_credits.size == 0) begin
        `uvm_warning("rsp_api::issue_msg", "Can't issue a message, no credits are available")
        return;
      end
    end

    seq.restrict_shared_credit = !sqr.shr.credit_cnt_shr;
    foreach (seq.restrict_rsp_vc_id[ii])
      seq.restrict_rsp_vc_id[ii] = !sqr.shr.credit_cnt_ded[msg_type][ii]; 
    
    // Data
    seq.rsp_protocol_id   = {2'b10, sqr.cfg.port, msg_type};
    seq.rsp_vc_id         = vc_id;
    seq.rsp_shared_credit = shared_credit;
    seq.rsp_header        = header;
    seq.rsp_spid          = spid;
    seq.rsp_dpid          = dpid;
    // Control
    seq.insert_cmd_par_err = insert_cmd_par_err;
    seq.flit_mode_enc_en   = sqr.cfg.flit_mode_enc_en;
    seq.a2f                = sqr.cfg.a2f;
    seq.ide_epoch_support  = sqr.cfg.ide_epoch_support;
    seq.skip_credit_check  = sqr.cfg.skip_credit_check;
    // Start
    seq.start(sqr);

  endtask

endclass
