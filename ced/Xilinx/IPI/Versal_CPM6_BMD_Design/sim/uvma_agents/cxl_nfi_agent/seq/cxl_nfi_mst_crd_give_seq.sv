// This sequence is designed to periodically evaluate when the other side of 
// the link can be given credits by US as the master. If flitmode==F68, then
// it will be returned as LLCRD flits (controlled by cfg.return_crds_in_flit), or
// a cxl_nfi_credit_txn will be sent out the ap for another agent to handle it in
// some undescribed manner. This sequence looks at what is possible to give by 
// examining the share object and also has a fixed time interval. It operates
// by grabbing the sequencer handle and sends a flit.
class cxl_nfi_mst_crd_give_seq#(parameter NFI_W=3) extends cxl_nfi_mst_in_order_seq#(NFI_W);

  `uvm_object_param_utils(cxl_nfi_mst_crd_give_seq#(NFI_W))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("cxl_nfi_mst_crd_give_seq#(%0d)",NFI_W);
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name = "cxl_nfi_mst_crd_give_seq");
    super.new(name);
  endfunction

  rand prot_t r_req_prot; rand int r_req_credit; 
  rand prot_t r_dat_prot; rand int r_dat_credit; 
  rand prot_t r_rsp_prot; rand int r_rsp_credit; 

  constraint c_credits {
    /* Only return credits for the protocol that has them remaining */
    if (p_sequencer.shr.give_req_credit[MEM] && !p_sequencer.shr.give_req_credit[CCH]) { 
      r_req_prot == MEM;
    } else if (!p_sequencer.shr.give_req_credit[MEM] && p_sequencer.shr.give_req_credit[CCH]) { 
      r_req_prot == CCH;
    }
    if (p_sequencer.shr.give_dat_credit[MEM] && !p_sequencer.shr.give_dat_credit[CCH]) { 
      r_dat_prot == MEM;
    } else if (!p_sequencer.shr.give_dat_credit[MEM] && p_sequencer.shr.give_dat_credit[CCH]) { 
      r_dat_prot == CCH;
    }
    if (p_sequencer.shr.give_rsp_credit[MEM] && !p_sequencer.shr.give_rsp_credit[CCH]) { 
      r_rsp_prot == MEM;
    } else if (!p_sequencer.shr.give_rsp_credit[MEM] && p_sequencer.shr.give_rsp_credit[CCH]) { 
      r_rsp_prot == CCH;
    }
    // Send credits whenever possible
    r_req_credit <= p_sequencer.shr.give_req_credit[r_req_prot];
    r_dat_credit <= p_sequencer.shr.give_dat_credit[r_dat_prot];
    r_rsp_credit <= p_sequencer.shr.give_rsp_credit[r_rsp_prot];
    p_sequencer.shr.give_req_credit[r_req_prot]>0 -> r_req_credit>0;
    p_sequencer.shr.give_dat_credit[r_dat_prot]>0 -> r_dat_credit>0;
    p_sequencer.shr.give_rsp_credit[r_rsp_prot]>0 -> r_rsp_credit>0;
  }

  // F68 credit return possibilities
  constraint c_count_f68 {
    r_req_credit inside {0, 1, 2, 4, 8, 16, 32, 64};
    r_dat_credit inside {0, 1, 2, 4, 8, 16, 32, 64};
    r_rsp_credit inside {0, 1, 2, 4, 8, 16, 32, 64};
  }

  // F256 credit return possibilities
  constraint c_count_f256 {
    r_req_credit inside {0, 1, 4, 8, 12, 16};
    r_dat_credit inside {0, 1, 4, 8, 12, 16};
    r_rsp_credit inside {0, 1, 4, 8, 12, 16};
  }

  virtual task body();
    bit [2:0][4:0]     crd;
    cxl_nfi_credit_txn t;
    // F68
    flit68_txn   f68;
    llcrd_f68    llcrd;
    // F256
    flit256_txn  f256;
    s15_phy      s15;

    forever begin

      fork
        // Other link is 100% starved at this point
        begin
          wait(p_sequencer.shr.init_req_credit[MEM] && 
            (p_sequencer.shr.init_req_credit[MEM]==p_sequencer.shr.give_req_credit[MEM]));
          p_sequencer.wait_cycles($urandom_range(1,6));
        end
        begin
          wait(p_sequencer.shr.init_dat_credit[MEM] && 
            (p_sequencer.shr.init_dat_credit[MEM]==p_sequencer.shr.give_dat_credit[MEM]));
          p_sequencer.wait_cycles($urandom_range(1,6));
        end
        begin
          wait(p_sequencer.shr.init_rsp_credit[MEM] && 
            (p_sequencer.shr.init_rsp_credit[MEM]==p_sequencer.shr.give_rsp_credit[MEM]));
          p_sequencer.wait_cycles($urandom_range(1,6));
        end
        begin
          wait(p_sequencer.shr.init_req_credit[CCH] && 
            (p_sequencer.shr.init_req_credit[CCH]==p_sequencer.shr.give_req_credit[CCH]));
          p_sequencer.wait_cycles($urandom_range(1,6));
        end
        begin
          wait(p_sequencer.shr.init_dat_credit[CCH] && 
            (p_sequencer.shr.init_dat_credit[CCH]==p_sequencer.shr.give_dat_credit[CCH]));
          p_sequencer.wait_cycles($urandom_range(1,6));
        end
        begin
          wait(p_sequencer.shr.init_rsp_credit[CCH] && 
            (p_sequencer.shr.init_rsp_credit[CCH]==p_sequencer.shr.give_rsp_credit[CCH]));
          p_sequencer.wait_cycles($urandom_range(1,6));
        end
        // Wait some interval, check if credits
        forever begin
          p_sequencer.wait_cycles($urandom_range(1,250));
          if(p_sequencer.shr.give_req_credit.sum || 
             p_sequencer.shr.give_dat_credit.sum ||
             p_sequencer.shr.give_rsp_credit.sum)
          begin
            break;
          end
        end
      join_any
      disable fork;

      // Send credits out the analysis port as a block (to the credit agent and/or some tracker)
      if (!p_sequencer.cfg.return_crds_in_flit) begin
        t = cxl_nfi_credit_txn::type_id::create("t");
        t.req_cred = p_sequencer.shr.give_req_credit;
        t.dat_cred = p_sequencer.shr.give_dat_credit;
        t.rsp_cred = p_sequencer.shr.give_rsp_credit;
        p_sequencer.cred_ret_ap.write(t);
        // The other agent will handle when/what to send, we sent the whole block
        p_sequencer.shr.give_req_credit = '{default: 0};
        p_sequencer.shr.give_dat_credit = '{default: 0};
        p_sequencer.shr.give_rsp_credit = '{default: 0};
      end 
      else if (p_sequencer.cfg.flitmode==UNSPEC) begin
        `uvm_fatal(get_type_name, "cfg.flitmode has not been specified")
      end
      // Config has said to return credits in flits
      else begin

        // Randomize what credits to send
        void'(this.randomize);

        // F68 will send as LLCRD flit
        if (p_sequencer.cfg.flitmode==F68) begin 
          f68   = flit68_txn::type_id::create("f68");
          llcrd = llcrd_f68::type_id::create("llcrd");

          llcrd.reqcrd = {r_req_prot, (!r_req_credit ? 3'h0 : 3'($clog2(r_req_credit)+1))};
          llcrd.datcrd = {r_dat_prot, (!r_dat_credit ? 3'h0 : 3'($clog2(r_dat_credit)+1))};
          llcrd.rspcrd = {r_rsp_prot, (!r_rsp_credit ? 3'h0 : 3'($clog2(r_rsp_credit)+1))};
          llcrd.pack_slot();
          f68.pack_flit(llcrd);
          flit_q.push_back(f68);
          
        end
        // F256 will send an empty flit with only credits
        else begin
          f256 = flit256_txn::type_id::create("f256");
          {f256.dir, f256.flitmode} = {p_sequencer.cfg.dir, p_sequencer.cfg.flitmode};
          s15  = s15_phy::type_id::create("s15");
          // Build credits
          crd[0] = '0;
          if (r_req_credit) begin
            crd[0][4] = r_req_prot;
            case (r_req_credit)
              1  : crd[0][3:0] = 4'h4+(f256.dir==H2C*4'h5);
              4  : crd[0][3:0] = 4'h5+(f256.dir==H2C*4'h5);
              8  : crd[0][3:0] = 4'h6+(f256.dir==H2C*4'h5);
              12 : crd[0][3:0] = 4'h7+(f256.dir==H2C*4'h5);
              16 : crd[0][3:0] = 4'h8+(f256.dir==H2C*4'h5);
            endcase
          end
          crd[1] = '0;
          if (r_dat_credit) begin
            crd[1][4] = r_dat_prot;
            case (r_dat_credit)
              1  : crd[1][3:0] = 4'h4+(f256.dir==H2C*4'h5);
              4  : crd[1][3:0] = 4'h5+(f256.dir==H2C*4'h5);
              8  : crd[1][3:0] = 4'h6+(f256.dir==H2C*4'h5);
              12 : crd[1][3:0] = 4'h7+(f256.dir==H2C*4'h5);
              16 : crd[1][3:0] = 4'h8+(f256.dir==H2C*4'h5);
            endcase
          end
                  crd[2] = '0;
          if (r_rsp_credit) begin
            crd[2][4] = r_rsp_prot;
            case (r_rsp_credit)
              1  : crd[2][3:0] = 4'h4+(f256.dir==H2C*4'h5);
              4  : crd[2][3:0] = 4'h5+(f256.dir==H2C*4'h5);
              8  : crd[2][3:0] = 4'h6+(f256.dir==H2C*4'h5);
              12 : crd[2][3:0] = 4'h7+(f256.dir==H2C*4'h5);
              16 : crd[2][3:0] = 4'h8+(f256.dir==H2C*4'h5);
            endcase
          end
          void'(s15.pack_phy(f256.flitmode, {1'b0, crd}));
          f256.pack(.s15(s15));
          flit_q.push_back(f256);
        end

        // Actually send the txn
        p_sequencer.grab(this);
        super.body();
        p_sequencer.ungrab(this);
        
        // Make sure we decrement the count
        p_sequencer.shr.give_req_credit[r_req_prot] -= r_req_credit;
        p_sequencer.shr.give_dat_credit[r_dat_prot] -= r_dat_credit;
        p_sequencer.shr.give_rsp_credit[r_rsp_prot] -= r_rsp_credit;
      end

    end
  
  endtask

endclass
