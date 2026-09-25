// This sequence is designed to replicate the CXL link initialization sequence as described
// by the CXL spec sections "Link Layer Initialization" or by simply broadcasting a txn out 
// the analysis port.
class cxl_nfi_mst_init_seq#(parameter NFI_W=3) extends cxl_nfi_mst_in_order_seq#(NFI_W);

  `uvm_object_param_utils(cxl_nfi_mst_init_seq#(NFI_W))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("cxl_nfi_mst_init_seq#(%0d)",NFI_W);
  virtual function string get_type_name(); return type_name; endfunction

  uvm_event link_init_done, init_param_rcvd;

  function new(string name = "cxl_nfi_mst_init_seq");
    super.new(name);
  endfunction

  rand prot_t r_req_prot; rand int r_req_credit; 
  rand prot_t r_dat_prot; rand int r_dat_credit; 
  rand prot_t r_rsp_prot; rand int r_rsp_credit; 

  int init_req_credit[1:0];
  int init_dat_credit[1:0];
  int init_rsp_credit[1:0];

  constraint c_credits {
    /* Only return credits for the protocol that has them remaining */
    if (init_req_credit[MEM] != 0 && init_req_credit[CCH] == 0) { 
      r_req_prot == MEM;
    } else if (init_req_credit[MEM] == 0 && init_req_credit[CCH] != 0) { 
      r_req_prot == CCH;
    }
    if (init_dat_credit[MEM] != 0 && init_dat_credit[CCH] == 0) { 
      r_dat_prot == MEM;
    } else if (init_dat_credit[MEM] == 0 && init_dat_credit[CCH] != 0) { 
      r_dat_prot == CCH;
    }
    if (init_rsp_credit[MEM] != 0 && init_rsp_credit[CCH] == 0) { 
      r_rsp_prot == MEM;
    } else if (init_rsp_credit[MEM] == 0 && init_rsp_credit[CCH] != 0) { 
      r_rsp_prot == CCH;
    }
    // Send credits whenever possible
    r_req_credit <= init_req_credit[r_req_prot];
    r_dat_credit <= init_dat_credit[r_dat_prot];
    r_rsp_credit <= init_rsp_credit[r_rsp_prot];
    init_req_credit[r_req_prot]>0 -> r_req_credit>0;
    init_dat_credit[r_dat_prot]>0 -> r_dat_credit>0;
    init_rsp_credit[r_rsp_prot]>0 -> r_rsp_credit>0;
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
    string         msg;
    bit [2:0][4:0] crd; //F256 only
    /* Objects */
    // F68 
    flit68_txn         f68;
    cxl_nfi_credit_txn crd_txn;
    retry_f68          retry;
    init_f68           init;
    llcrd_f68          llcrd;
    // F256
    flit256_txn  f256;
    m8_hbr       m8;
    s15_phy      s15;

    // Send initial credits out the analysis port (to the credit agent and/or some tracker)
    if (!p_sequencer.cfg.return_crds_in_flit) begin
      crd_txn = cxl_nfi_credit_txn::type_id::create("crd_txn");
      crd_txn.req_cred = p_sequencer.shr.init_req_credit;
      crd_txn.dat_cred = p_sequencer.shr.init_dat_credit;
      crd_txn.rsp_cred = p_sequencer.shr.init_rsp_credit;
      p_sequencer.cred_ret_ap.write(crd_txn);
    end
    else if (p_sequencer.cfg.flitmode==UNSPEC) begin
      `uvm_fatal(get_type_name, "cfg.flitmode has not been specified")
    end
    // Config has said to return credits in flits
    else begin
      /* F68: has a very specific link init sequence */
      if (p_sequencer.cfg.flitmode==F68) begin
        // Send Control-Retry.Idle ten times
        f68 = flit68_txn::type_id::create("f68");
        f68.dir = p_sequencer.cfg.dir;
        retry = retry_f68::type_id::create("retry");
        init  = init_f68::type_id::create("init");
        llcrd = llcrd_f68::type_id::create("llcrd");
        retry.subtype = _RIDLE;
        retry.pack_slot();
        f68.pack_flit(retry);
        repeat (10) flit_q.push_back(f68);
        // Send Control-Init.Param one time (spec: only one)
        f68 = flit68_txn::type_id::create("f68");
        f68.dir = p_sequencer.cfg.dir;
        init.pack_slot();
        f68.pack_flit(init);
        flit_q.push_back(f68);
        // Send these txns
        super.body();
        // Wait until Control-Init.Param received (agent is unidirectional, 
        // so receive agent will trigger us)
        init_param_rcvd.wait_on();
        // Initialize from the share object
        init_req_credit = p_sequencer.shr.init_req_credit;
        init_dat_credit = p_sequencer.shr.init_dat_credit;
        init_rsp_credit = p_sequencer.shr.init_rsp_credit;
        // Let users know what we're sending
        msg = "Initial credits for transmit given as LLCRD flits:\n";
        msg = {msg, $sformatf("  --> CXL.MEM : REQ=%0d, DAT=%0d, RSP=%0d\n",init_req_credit[MEM],init_dat_credit[MEM],init_rsp_credit[MEM])};
        msg = {msg, $sformatf("  --> CXL.CCH : REQ=%0d, DAT=%0d, RSP=%0d"  ,init_req_credit[CCH],init_dat_credit[CCH],init_rsp_credit[CCH])};
        `uvm_info(get_type_name, msg, UVM_LOW)
        // Send Control-LLCRD to initialize credits
        c_count_f68 .constraint_mode(1);
        c_count_f256.constraint_mode(0);
        while ((init_req_credit.sum+init_dat_credit.sum+init_rsp_credit.sum) != 0) begin
          f68 = flit68_txn::type_id::create("f68");
          f68.dir = p_sequencer.cfg.dir;
          void'(this.randomize);
          llcrd.reqcrd = {r_req_prot, (!r_req_credit ? 3'h0 : 3'($clog2(r_req_credit)+1))};
          llcrd.datcrd = {r_dat_prot, (!r_dat_credit ? 3'h0 : 3'($clog2(r_dat_credit)+1))};
          llcrd.rspcrd = {r_rsp_prot, (!r_rsp_credit ? 3'h0 : 3'($clog2(r_rsp_credit)+1))};
          llcrd.pack_slot();
          f68.pack_flit(llcrd);
          flit_q.push_back(f68);
          // Now decrement 
          init_req_credit[r_req_prot] -= r_req_credit;
          init_dat_credit[r_dat_prot] -= r_dat_credit;
          init_rsp_credit[r_rsp_prot] -= r_rsp_credit;
        end
        // Send a single Control-LLCRD with all credits=0 to denote initialization is done
        f68 = flit68_txn::type_id::create("f68");
        f68.dir = p_sequencer.cfg.dir;
        void'(this.randomize);
        llcrd.reqcrd = {r_req_prot, 3'h0};
        llcrd.datcrd = {r_dat_prot, 3'h0}; 
        llcrd.rspcrd = {r_rsp_prot, 3'h0};
        llcrd.pack_slot();
        f68.pack_flit(llcrd);
        flit_q.push_back(f68);
        // Actually send all these txns
        super.body();
        // Trigger event if anyone is listening
        link_init_done.trigger();
      end
      /* F256 link init just sends credits */
      else begin
        // Send Control-Init.Param one time (spec: only one)
        m8   = m8_hbr::type_id::create("m8");
        m8.create_objects(p_sequencer.cfg.flitmode, 0);
        m8.set_details(INIT_F256, 4'h8, 1'b0);
        void'(m8.pack_slot());
        f256 = flit256_txn::type_id::create("f256");
        {f256.dir, f256.flitmode} = {p_sequencer.cfg.dir, p_sequencer.cfg.flitmode};
        f256.pack(m8);
        flit_q.push_back(f256);
        // Actually send the txn
        super.body();
        // Wait until Control-Init.Param received (agent is unidirectional, 
        // so receive agent will trigger us)
        init_param_rcvd.wait_on();
        // Initialize from the share object
        init_req_credit = p_sequencer.shr.init_req_credit;
        init_dat_credit = p_sequencer.shr.init_dat_credit;
        init_rsp_credit = p_sequencer.shr.init_rsp_credit;
        // Let users know what we're sending
        msg = "Initial credits for transmit given as empty flits with valid credits:\n";
        msg = {msg, $sformatf("  --> CXL.MEM : REQ=%0d, DAT=%0d, RSP=%0d\n",init_req_credit[MEM],init_dat_credit[MEM],init_rsp_credit[MEM])};
        msg = {msg, $sformatf("  --> CXL.CCH : REQ=%0d, DAT=%0d, RSP=%0d"  ,init_req_credit[CCH],init_dat_credit[CCH],init_rsp_credit[CCH])};
        `uvm_info(get_type_name, msg, UVM_LOW)
        // Send normal flits to initialize credits
        c_count_f68 .constraint_mode(0);
        c_count_f256.constraint_mode(1);
        while ((init_req_credit.sum+init_dat_credit.sum+init_rsp_credit.sum) != 0) begin
          f256 = flit256_txn::type_id::create("f256");
          {f256.dir, f256.flitmode} = {p_sequencer.cfg.dir, p_sequencer.cfg.flitmode};
          void'(this.randomize);
          s15 = s15_phy::type_id::create("s15");
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
          // Now decrement 
          init_req_credit[r_req_prot] -= r_req_credit;
          init_dat_credit[r_dat_prot] -= r_dat_credit;
          init_rsp_credit[r_rsp_prot] -= r_rsp_credit;
        end
        // Actually send the txns
        super.body();
        // Trigger event if anyone is listening
        link_init_done.trigger();
      end
    end
  endtask

endclass
