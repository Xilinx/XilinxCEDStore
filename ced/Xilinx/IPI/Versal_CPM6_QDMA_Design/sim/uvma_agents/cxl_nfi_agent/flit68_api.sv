typedef class cxl_nfi_mst_in_order_seq;

class flit68_api#(type SQR, parameter NFI_W=3) extends base_api#(SQR);

  `uvm_component_param_utils(flit68_api#(SQR, NFI_W))

  const static string type_name = {"flit68_api#(",SQR::type_name,$sformatf(",%0d)",NFI_W)};
  virtual function string get_type_name(); return type_name; endfunction

  typedef enum {H2DREQ, H2DRSP, H2DDAT, D2HREQ, D2HRSP, D2HDAT,
                M2SRWD, M2SREQ, S2MNDR, S2MDRS} msg_sel_t; 

  dir_t       dir;
  int         nfi_width;
  msg_sel_t   msg_sel;

  rand bit [1:0]  r_slot_num;
  rand bit [1:0]  r_flit_num;
  rand slot_fmt_t r_slot_type;

  // Because Slot 0 and Slot 1 are different, the first
  // valid message being in either slot is still tight 
  constraint c_tight_flit {
    r_slot_type inside {[_G1:_G6]} -> r_slot_num==1; 
  }

  constraint c_1msg_loc {
    r_flit_num inside {[0:nfi_width-1]};
    r_slot_num == 0           -> r_slot_type inside {[_H0:_H5]};
    r_slot_num inside {[1:3]} -> r_slot_type inside {[_G1:_G6]};
    // Note that these are for one message only in a flit, which means no MDH
    if (sqr.cfg.dir == H2C) {
      msg_sel == H2DREQ -> r_slot_type inside {_H0, _H2, _G2};
      msg_sel == H2DDAT -> r_slot_type inside {_H1, _H2, _G2, _G4};
      msg_sel == H2DRSP -> r_slot_type inside {_H0, _H1, _G1, _G2, _G5};
      msg_sel == M2SRWD -> r_slot_type inside {_H4, _G5};
      msg_sel == M2SREQ -> r_slot_type inside {_H5, _G4};
    } else {
      msg_sel == D2HREQ -> r_slot_type inside {_H1, _G1, _G2};
      msg_sel == D2HDAT -> r_slot_type inside {_H0, _H1, _G2};
      msg_sel == D2HRSP -> r_slot_type inside {_H0, _G1, _G2};
      msg_sel == S2MNDR -> r_slot_type inside {_H0, _H3, _H4, _G4, _G5};
      msg_sel == S2MDRS -> r_slot_type inside {_H3, _G4};
    }
  }
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Users can use this to easily send a specific single transaction layer 
  // message. This task includes randomization and error checking to make 
  // sure something invalid isn't sent. It is required to pass a transaction 
  // handle to the txn argument, but any argument inside the object's member
  // can be unspecified; it will just get randomized. Thus, the user gets any
  // amount of control they want. Scroll down to see the table in this method 
  // to see all the valid and invalid combinations of arguments.
  //   - txn (reqd) : handle to object of type m2sreq_c, m2srwd_c, s2mndr_c, s2mdrs_c,
  //                  h2dreq_c, h2drsp_c, h2ddat_c, d2hreq_c, d2hrsp_c, d2hdat_c
  //   - slot_type  : [_H0:_H5], [_G1:_G6], (_RSVD -> randomize)
  //   - slot_num   : [0:3], (-1 -> tightly packed)
  //   - flit_num   : [0:sqr.cfg.nfi_width-1], (-1 -> tightly packed; -2 -> randomize)
  virtual task issue_msg(
    base_txn   txn,
    slot_fmt_t slot_type = _RSVD,
    int        slot_num  = -1,
    int        flit_num  = -1
  );

    string msg;

    cxl_nfi_mst_in_order_seq#(NFI_W) seq = cxl_nfi_mst_in_order_seq#(NFI_W)::type_id::create("seq");
    flit68_txn flit                      = flit68_txn::type_id::create("flit");

    m2sreq_c m2sreq_h; m2srwd_c m2srwd_h;
    s2mndr_c s2mndr_h; s2mdrs_c s2mdrs_h;
    h2dreq_c h2dreq_h; h2ddat_c h2ddat_h; h2drsp_c h2drsp_h; 
    d2hreq_c d2hreq_h; d2hdat_c d2hdat_h; d2hrsp_c d2hrsp_h; 

    // Copy global setting here
    flit.disable_tight_pack_check = sqr.cfg.disable_tight_pack_check;
    flit.dir                      = sqr.cfg.dir;

    // Make sure user selected an available slot, else exit
    if (!(slot_num inside {[-1:3]})) begin
      msg = $sformatf("Invalid selection of %0d for slot_num argument; returning", slot_num);
      `uvm_error(get_type_name, msg)
      return;
    end

    // Make sure user selected an available flit, else exit
    nfi_width = sqr.cfg.nfi_width;
    if (!(flit_num inside {[-2:nfi_width-1]})) begin
      msg = $sformatf("Invalid selection of %0d for flit_num argument; returning", flit_num);
      `uvm_error(get_type_name, msg);
      return;
    end

    // Make sure dir is correct, else exit
    dir = sqr.cfg.dir;
    if ((txn.txn_type.substr(0,2) inside {"H2D","M2S"} && dir == C2H) || 
        (txn.txn_type.substr(0,2) inside {"D2H","S2M"} && dir == H2C))
    begin
      msg = $sformatf("Can't send a %0s txn when the agent dir is %0s; returning", txn.txn_type, dir);
      `uvm_error(get_type_name, msg)
      return;
    end

    // Table : Randomize and set where messages will land
    // There are 8 cases of input arguments for slot_type(H,G,R) and slot_num(R,0:3)
    //   Case | slot_type | slot_num | Outcome
    //   1.   | R         | R        | If slot_type=H, slot_num=0. If slot_type=G, slot_num=1.
    //   2.   | R         | 0        | slot_type=H
    //   3.   | R         | 1:3      | slot_type=G
    //   4.   | H         | 0/R      | Valid, set slot_num=0
    //   5.   | H         | 1:3      | Invalid, error
    //   6.   | G         | R/1      | Valid, set slot_num=1 (tightly packed)
    //   7.   | G         | 2:3      | Valid, set slot_num=arg (not tightly packed)
    //   8.   | G         | 0        | Invalid, error
    case (txn.txn_type)
      "M2S_REQ" : msg_sel = M2SREQ;
      "M2S_RWD" : msg_sel = M2SRWD;
      "S2M_NDR" : msg_sel = S2MNDR;
      "S2M_DRS" : msg_sel = S2MDRS; 
      "H2D_REQ" : msg_sel = H2DREQ;
      "H2D_DAT" : msg_sel = H2DDAT;
      "H2D_RSP" : msg_sel = H2DRSP;
      "D2H_REQ" : msg_sel = D2HREQ;
      "D2H_DAT" : msg_sel = D2HDAT;
      "D2H_RSP" : msg_sel = D2HRSP;
    endcase
    // Check Case 5,8; if true, exit
    if ((slot_type inside {[_H0:_H5]} && slot_num inside {[1:3]}) ||
        (slot_type inside {[_G1:_G6]} && slot_num == 0))
    begin
      msg = $sformatf("Slot type %0s cannot go in slot %0d; returning",slot_type.name,slot_num);
      `uvm_error(get_type_name, msg);
      return;
    end
    // Initialize randomization to on
    r_slot_num.rand_mode(1);
    r_slot_type.rand_mode(1);
    r_flit_num.rand_mode(1);
    // Accounts for all cases
    c_tight_flit.constraint_mode(slot_num<=1);
    if (slot_num != -1) begin
      r_slot_num = slot_num;
      r_slot_num.rand_mode(0);
    end
    if (slot_type != _RSVD) begin
      r_slot_type = slot_type;
      r_slot_type.rand_mode(0);
    end
    if (flit_num >= -1) begin
      r_flit_num = flit_num==-1 ? 0 : flit_num;
      r_flit_num.rand_mode(0);
    end
    // Do randomization
    void'(this.randomize());
    // Assign to finalized values
    slot_type = r_slot_type;
    slot_num  = r_slot_num;
    flit_num  = r_flit_num;

     msg = slot_type.name;
    `uvm_info("::issue_msg", $sformatf("Sending %0s via %0s slot in slot position %0d and flit position %0d", txn.txn_type, msg.substr(1,2), slot_num, flit_num), UVM_MEDIUM)

    // Build the flit(s) to send
    case(txn.txn_type)
      "M2S_REQ" : 
        begin
          if (!(slot_type inside {_H5, _G4})) begin
            msg = $sformatf("Invalid slot_type of %0s for %0s message; returning", slot_type.name, txn.txn_type);
            `uvm_error(get_type_name, msg)
            return;
          end
          $cast(m2sreq_h, txn);
          case(slot_type)
            _H5 : begin
                    h5_f68 h5 = h5_f68::type_id::create("h5");
                    h5.create_objects(dir, 2'b01);
                    h5.m2sreq_h.copy(m2sreq_h);
                    void'(h5.randomize());
                    void'(h5.pack_slot());
                    flit.pack_flit(h5);
                    seq.flit_q.push_back(flit);
                  end
            _G4 : begin
                    g4_f68 g4 = g4_f68::type_id::create("g4");
                    g4.create_objects(dir, 3'b001);
                    g4.m2sreq_h.copy(m2sreq_h);
                    void'(g4.randomize());
                    void'(g4.pack_slot());
                    case (slot_num)
                      1 : flit.pack_flit(,g4,,);
                      2 : flit.pack_flit(,,g4,);
                      3 : flit.pack_flit(,,,g4);
                    endcase
                    seq.flit_q.push_back(flit);
                  end
          endcase
        end
      "M2S_RWD" : 
        begin
          if (!(slot_type inside {_H4, _G5})) begin
            msg = $sformatf("Invalid slot_type of %0s for %0s message; returning", slot_type.name, txn.txn_type);
            `uvm_error(get_type_name, msg)
            return;
          end
          $cast(m2srwd_h, txn);
          case(slot_type)
            _H4 : begin
                    g0_f68    g0[0:3];
                    g0be_f68  g0_be;
                    h4_f68    h4 = h4_f68::type_id::create("h4");
                    h4.create_objects(dir, 2'b01);  
                    h4.m2srwd_h.copy(m2srwd_h);
                    void'(h4.randomize());
                    void'(h4.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = h4.m2srwd_h.dat[ii*128+:128]; 
                    end
                    if (h4.m2srwd_h.be != '1) begin
                      g0_be     = g0be_f68::type_id::create("g0_be");
                      g0_be.dir = dir;
                      g0_be.be  = h4.m2srwd_h.be;
                      void'(g0_be.pack_slot());
                    end
                    flit.pack_flit(h4, g0[0], g0[1], g0[2]);
                    seq.flit_q.push_back(flit);
                    flit = flit.new_flit();
                    flit.pack_flit(, g0[3], g0_be,);
                    seq.flit_q.push_back(flit);
                  end
            _G5 : begin
                    g0_f68    g0[0:3];
                    g0be_f68  g0_be;
                    g5_f68    g5 = g5_f68::type_id::create("g5");
                    g5.create_objects(dir, 2'b01);
                    g5.m2srwd_h.copy(m2srwd_h);
                    void'(g5.randomize);
                    void'(g5.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = g5.m2srwd_h.dat[ii*128+:128]; 
                    end
                    if (g5.m2srwd_h.be != '1) begin
                      g0_be     = g0be_f68::type_id::create("g0_be");
                      g0_be.dir = dir;
                      g0_be.be  = g5.m2srwd_h.be;
                      void'(g0_be.pack_slot());
                    end
                    case (slot_num)
                      1 : flit.pack_flit(,g5, g0[0], g0[1]);
                      2 : flit.pack_flit(,,   g5,    g0[0]);
                      3 : flit.pack_flit(,,,         g5);
                    endcase
                    seq.flit_q.push_back(flit);
                    flit = flit.new_flit();
                    case (slot_num)
                      1 : flit.pack_flit(     , g0[2], g0[3], g0_be);
                      2 : 
                      begin
                        if (g0_be != null)
                          flit.pack_flit(g0[1], g0[2], g0[3], g0_be);
                        else
                          flit.pack_flit(     , g0[1], g0[2], g0[3]);
                      end
                      3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]);
                    endcase
                    seq.flit_q.push_back(flit);
                    if (g0_be != null && (slot_num == 3)) begin
                      flit = flit.new_flit();
                      flit.pack_flit(,g0_be,,);
                      seq.flit_q.push_back(flit);
                    end
                  end
          endcase
        end
      "S2M_NDR" : 
        begin
          if (!(slot_type inside {_H0, _H3, _H4, _G4, _G5})) begin
            msg = $sformatf("Invalid slot_type of %0s for %0s message; returning", slot_type.name, txn.txn_type);
            `uvm_error(get_type_name, msg)
            return;
          end
          $cast(s2mndr_h, txn);
          case(slot_type)
            _H0 : begin
                    h0_f68 h0 = h0_f68::type_id::create("h0");
                    h0.create_objects(dir, 4'b1000);
                    h0.s2mndr_h.copy(s2mndr_h);
                    void'(h0.randomize());
                    void'(h0.pack_slot());
                    flit.pack_flit(h0);
                    seq.flit_q.push_back(flit);
                  end
            _H3 : begin
                    h3_f68 h3 = h3_f68::type_id::create("h3");
                    h3.create_objects(dir, 4'b0010);
                    h3.s2mndr_h.copy(s2mndr_h);
                    void'(h3.randomize());
                    void'(h3.pack_slot());
                    flit.pack_flit(h3);
                    seq.flit_q.push_back(flit);
                  end
            _H4 : begin
                    h4_f68 h4 = h4_f68::type_id::create("h4");
                    h4.create_objects(dir, 2'b01);
                    h4.s2mndr_h[0].copy(s2mndr_h);
                    void'(h4.randomize());
                    void'(h4.pack_slot());
                    flit.pack_flit(h4);
                    seq.flit_q.push_back(flit);
                  end
            _G4 : begin
                    g4_f68 g4 = g4_f68::type_id::create("g4");
                    g4.create_objects(dir, 3'b010);
                    g4.s2mndr_h[0].copy(s2mndr_h);
                    void'(g4.randomize);
                    void'(g4.pack_slot());
                    case (slot_num)
                      1 : flit.pack_flit(,g4,,);
                      2 : flit.pack_flit(,,g4,);
                      3 : flit.pack_flit(,,,g4);
                    endcase
                    seq.flit_q.push_back(flit);
                  end
            _G5 : begin
                    g5_f68 g5 = g5_f68::type_id::create("g5");
                    g5.create_objects(dir, 2'b01);
                    g5.s2mndr_h[0].copy(s2mndr_h);
                    void'(g5.randomize);
                    void'(g5.pack_slot());
                    case (slot_num)
                      1 : flit.pack_flit(,g5,,);
                      2 : flit.pack_flit(,,g5,);
                      3 : flit.pack_flit(,,,g5);
                    endcase
                    seq.flit_q.push_back(flit);
                  end
          endcase
        end
      "S2M_DRS" : 
        begin
          if (!(slot_type inside {_H3, _G4})) begin
            msg = $sformatf("Invalid slot_type of %0s for %0s message; returning", slot_type.name, txn.txn_type);
            `uvm_error(get_type_name, msg)
            return;
          end
          $cast(s2mdrs_h, txn);
          case(slot_type)
            _H3 : begin
                    g0_f68    g0[0:3];
                    h3_f68    h3 = h3_f68::type_id::create("h3");
                    h3.create_objects(dir, 4'b0001); 
                    h3.s2mdrs_h.copy(s2mdrs_h);
                    if (sqr.cfg.split_32B_disable) h3.s2mdrs_h.txfer_64B = 1;
                    void'(h3.randomize());
                    void'(h3.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = h3.s2mdrs_h.dat[ii*128+:128]; 
                    end
                    if (h3.s2mdrs_h.txfer_64B) begin
                      flit.pack_flit(h3, g0[0], g0[1], g0[2]);
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      flit.pack_flit(, g0[3],,);
                      seq.flit_q.push_back(flit);
                    end
                    else begin
                      flit.pack_flit(h3, g0[0], g0[1],);
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      flit.pack_flit(h3, g0[2], g0[3],);
                      seq.flit_q.push_back(flit);
                    end
                  end
            _G4 : begin
                    h3_f68    h3;
                    g0_f68    g0[0:3];
                    g4_f68    g4 = g4_f68::type_id::create("g4");
                    g4.create_objects(dir, 3'b001);
                    g4.s2mdrs_h.copy(s2mdrs_h);
                    if (sqr.cfg.split_32B_disable) g4.s2mdrs_h.txfer_64B = 1;
                    void'(g4.randomize());
                    void'(g4.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = g4.s2mdrs_h.dat[ii*128+:128]; 
                    end
                    if (g4.s2mdrs_h.txfer_64B) begin
                      case (slot_num)
                        1 : flit.pack_flit(,g4, g0[0], g0[1]);
                        2 : flit.pack_flit(,,   g4,    g0[0]);
                        3 : flit.pack_flit(,,,         g4);
                      endcase
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      case (slot_num)
                        1 : flit.pack_flit(     , g0[2], g0[3],);
                        2 : flit.pack_flit(     , g0[1], g0[2], g0[3]);
                        3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]);
                      endcase
                      seq.flit_q.push_back(flit);
                    end
                    else begin //two 32B transfers
                      h3 = h3_f68::type_id::create("h3");
                      h3.create_objects(dir, 4'b0001); 
                      h3.s2mdrs_h.copy(s2mdrs_h);
                      h3.s2mdrs_h.txfer_64B = 1'b0;
                      void'(h3.randomize());
                      void'(h3.pack_slot());
                      case (slot_num)
                        1 : flit.pack_flit(,g4, g0[0], g0[1]);
                        2 : flit.pack_flit(,,   g4,    g0[0]);
                        3 : flit.pack_flit(,,,         g4);
                      endcase
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      case (slot_num)
                        1 : flit.pack_flit(h3, g0[2], g0[3],);
                        2 : flit.pack_flit(h3, g0[1], g0[2], g0[3]);
                        3 : flit.pack_flit(h3, g0[0], g0[1], g0[2]);
                      endcase
                      seq.flit_q.push_back(flit);
                      if (slot_num == 3) begin
                        flit = flit.new_flit();
                        flit.pack_flit(,g0[3],,);
                        seq.flit_q.push_back(flit);
                      end
                    end
                  end
          endcase
        end
      "H2D_REQ" : 
        begin
          if (!(slot_type inside {_H0, _H2, _G2})) begin
            msg = $sformatf("Invalid slot_type of %0s for %0s message; returning", slot_type.name, txn.txn_type);
            `uvm_error(get_type_name, msg)
            return;
          end
          $cast(h2dreq_h, txn);
          case(slot_type)
            _H0 : begin
                    h0_f68 h0 = h0_f68::type_id::create("h0");
                    h0.create_objects(dir, 4'b0001);
                    h0.h2dreq_h.copy(h2dreq_h);
                    void'(h0.randomize());
                    void'(h0.pack_slot());
                    flit.pack_flit(h0);
                    seq.flit_q.push_back(flit);
                  end
            _H2 : begin
                    h2_f68 h2 = h2_f68::type_id::create("h2");
                    h2.create_objects(dir, 5'b00001);
                    h2.h2dreq_h.copy(h2dreq_h);
                    void'(h2.randomize());
                    void'(h2.pack_slot());
                    flit.pack_flit(h2);
                    seq.flit_q.push_back(flit);
                  end
            _G2 : begin
                    g2_f68 g2 = g2_f68::type_id::create("g2");
                    g2.create_objects(dir, 3'b001);
                    g2.h2dreq_h.copy(h2dreq_h);
                    void'(g2.randomize);
                    void'(g2.pack_slot());
                    case (slot_num)
                      1 : flit.pack_flit(,g2,,);
                      2 : flit.pack_flit(,,g2,);
                      3 : flit.pack_flit(,,,g2);
                    endcase
                    seq.flit_q.push_back(flit);
                  end
          endcase
        end
      "H2D_DAT" : 
        begin
          if (!(slot_type inside {_H1, _H2, _G2, _G4})) begin
            msg = $sformatf("Invalid slot_type of %0s for %0s message; returning", slot_type.name, txn.txn_type);
            `uvm_error(get_type_name, msg)
            return;
          end
          $cast(h2ddat_h, txn);
          case(slot_type)
            _H1 : begin
                    g0_f68    g0[0:3];
                    h1_f68    h1 = h1_f68::type_id::create("h1");
                    h1.create_objects(dir, 3'b001);
                    h1.h2ddat_h.copy(h2ddat_h);
                    if (sqr.cfg.split_32B_disable) h1.h2ddat_h.txfer_64B = 1;
                    void'(h1.randomize() with {h1.h2ddat_h.rand_hdr68.ch == 1'b0;});
                    void'(h1.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = h1.h2ddat_h.dat[ii*128+:128]; 
                    end
                    if (h1.h2ddat_h.txfer_64B) begin
                      flit.pack_flit(h1, g0[0], g0[1], g0[2]);
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      flit.pack_flit(,g0[3],,);
                      seq.flit_q.push_back(flit);
                    end
                    else begin //two 32B transfers
                      flit.pack_flit(h1, g0[0], g0[1],);
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      h1.h2ddat_h.hdr68.ch = 1'b1;
                      void'(h1.pack_slot());
                      flit.pack_flit(h1, g0[2], g0[3],);
                      seq.flit_q.push_back(flit);
                    end
                  end
            _H2 : begin
                    g0_f68    g0[0:3];
                    h2_f68    h2 = h2_f68::type_id::create("h2");
                    h2.create_objects(dir, 5'b00010);
                    h2.h2ddat_h.copy(h2ddat_h);
                    if (sqr.cfg.split_32B_disable) h2.h2ddat_h.txfer_64B = 1;
                    void'(h2.randomize() with {h2.h2ddat_h.rand_hdr68.ch == 1'b0;});
                    void'(h2.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = h2.h2ddat_h.dat[ii*128+:128]; 
                    end
                    if (h2.h2ddat_h.txfer_64B) begin
                      flit.pack_flit(h2, g0[0], g0[1], g0[2]);
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      flit.pack_flit(,g0[3],,);
                      seq.flit_q.push_back(flit);
                    end
                    else begin //two 32B transfers
                      flit.pack_flit(h2, g0[0], g0[1],);
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      h2.h2ddat_h.hdr68.ch = 1'b1;
                      void'(h2.pack_slot());
                      flit.pack_flit(h2, g0[2], g0[3],);
                      seq.flit_q.push_back(flit);
                    end
                  end
            _G2 : begin
                    hslot_fmt_t hfmt;
                    g0_f68      g0[0:3];
                    g2_f68      g2 = g2_f68::type_id::create("g2");
                    g2.create_objects(dir, 3'b010);
                    g2.h2ddat_h.copy(h2ddat_h);
                    if (sqr.cfg.split_32B_disable) g2.h2ddat_h.txfer_64B = 1;
                    void'(g2.randomize() with {g2.h2ddat_h.rand_hdr68.ch == 1'b0;});
                    void'(g2.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = g2.h2ddat_h.dat[ii*128+:128]; 
                    end
                    if (g2.h2ddat_h.txfer_64B) begin
                      case (slot_num)
                        1 : flit.pack_flit(,g2, g0[0], g0[1]);
                        2 : flit.pack_flit(,,   g2,    g0[0]);
                        3 : flit.pack_flit(,,,         g2);
                      endcase
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      case (slot_num)
                        1 : flit.pack_flit(     , g0[2], g0[3],);
                        2 : flit.pack_flit(     , g0[1], g0[2], g0[3]);
                        3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]);
                      endcase
                      seq.flit_q.push_back(flit);
                    end
                    else begin
                      slot_base hb;
                      h1_f68   h1;
                      h2_f68   h2;
                      void'(std::randomize(hfmt) with {hfmt inside {H1, H2};});
                      case (hfmt)
                        H1 : begin 
                               h1 = h1_f68::type_id::create("h1");  
                               h1.create_objects(dir, 3'b001);
                               h1.h2ddat_h.copy(h2ddat_h);
                               h1.h2ddat_h.hdr68.ch = 1'b1;
                               void'(h1.randomize());
                               void'(h1.pack_slot());
                               hb = h1;
                             end
                        H2 : begin 
                               h2 = h2_f68::type_id::create("h2");  
                               h2.create_objects(dir, 2'b10);
                               h2.h2ddat_h.copy(h2ddat_h);
                               h2.h2ddat_h.hdr68.ch = 1'b1;
                               void'(h2.randomize());
                               void'(h2.pack_slot());
                               hb = h2;
                             end
                      endcase
                      void'(g2.pack_slot());
                      case (slot_num)
                        1 : flit.pack_flit(,g2, g0[0], g0[1]);
                        2 : flit.pack_flit(,,   g2,    g0[0]);
                        3 : flit.pack_flit(,,,         g2);
                      endcase
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      case (slot_num)
                        1 : flit.pack_flit(hb, g0[2], g0[3],);
                        2 : flit.pack_flit(hb, g0[1], g0[2], g0[3]);
                        3 : flit.pack_flit(hb, g0[0], g0[1], g0[2]);
                      endcase
                      seq.flit_q.push_back(flit);
                      if (slot_num == 3) begin
                        flit = flit.new_flit();
                        flit.pack_flit(,g0[3],,);
                        seq.flit_q.push_back(flit);
                      end
                    end
                  end
            _G4 : begin
                    hslot_fmt_t hfmt;
                    g0_f68      g0[0:3];
                    g4_f68      g4 = g4_f68::type_id::create("g4");
                    g4.create_objects(dir, 3'b010);
                    g4.h2ddat_h.copy(h2ddat_h);
                    if (sqr.cfg.split_32B_disable) g4.h2ddat_h.txfer_64B = 1;
                    void'(g4.randomize() with {g4.h2ddat_h.rand_hdr68.ch == 1'b0;});
                    void'(g4.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = g4.h2ddat_h.dat[ii*128+:128]; 
                    end
                    if (g4.h2ddat_h.txfer_64B) begin
                      case (slot_num)
                        1 : flit.pack_flit(,g4, g0[0], g0[1]);
                        2 : flit.pack_flit(,,   g4,    g0[0]);
                        3 : flit.pack_flit(,,,         g4);
                      endcase
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      case (slot_num)
                        1 : flit.pack_flit(     , g0[2], g0[3],);
                        2 : flit.pack_flit(     , g0[1], g0[2], g0[3]);
                        3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]);
                      endcase
                      seq.flit_q.push_back(flit);
                    end
                    else begin
                      slot_base hb;
                      h1_f68   h1;
                      h2_f68   h2;
                      void'(std::randomize(hfmt) with {hfmt inside {H1, H2};});
                      case (hfmt)
                        H1 : begin 
                               h1 = h1_f68::type_id::create("h1");  
                               h1.create_objects(dir, 3'b001);
                               h1.h2ddat_h.copy(h2ddat_h);
                               h1.h2ddat_h.hdr68.ch = 1'b1;
                               void'(h1.randomize());
                               void'(h1.pack_slot());
                               hb = h1;
                             end
                        H2 : begin 
                               h2 = h2_f68::type_id::create("h2");  
                               h2.create_objects(dir, 2'b10);
                               h2.h2ddat_h.copy(h2ddat_h);
                               h2.h2ddat_h.hdr68.ch = 1'b1;
                               void'(h2.randomize());
                               void'(h2.pack_slot());
                               hb = h2;
                             end
                      endcase
                      case (slot_num)
                        1 : flit.pack_flit(,g4, g0[0], g0[1]);
                        2 : flit.pack_flit(,,   g4,    g0[0]);
                        3 : flit.pack_flit(,,,         g4);
                      endcase
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      case (slot_num)
                        1 : flit.pack_flit(hb, g0[2], g0[3],);
                        2 : flit.pack_flit(hb, g0[1], g0[2], g0[3]);
                        3 : flit.pack_flit(hb, g0[0], g0[1], g0[2]);
                      endcase
                      seq.flit_q.push_back(flit);
                      if (slot_num == 3) begin
                        flit = flit.new_flit();
                        flit.pack_flit(,g0[3],,);
                        seq.flit_q.push_back(flit);
                      end
                    end
                  end
          endcase
        end
      "H2D_RSP" : 
        begin
          if (!(slot_type inside {_H0, _H1, _G1, _G2, _G5})) begin
            msg = $sformatf("Invalid slot_type of %0s for %0s message; returning", slot_type.name, txn.txn_type);
            `uvm_error(get_type_name, msg)
            return;
          end
          $cast(h2drsp_h, txn);
          case(slot_type)
            _H0 : begin
                    h0_f68 h0 = h0_f68::type_id::create("h0");
                    h0.create_objects(dir, 4'b0010);
                    h0.h2drsp_h.copy(h2drsp_h);
                    void'(h0.randomize());
                    void'(h0.pack_slot());
                    flit.pack_flit(h0);
                    seq.flit_q.push_back(flit);
                  end
            _H1 : begin
                    h1_f68 h1 = h1_f68::type_id::create("h1");
                    h1.create_objects(dir, 3'b010);
                    h1.h2drsp_h[0].copy(h2drsp_h);
                    void'(h1.randomize());
                    void'(h1.pack_slot());
                    flit.pack_flit(h1);
                    seq.flit_q.push_back(flit);
                  end
            _G1 : begin
                    g1_f68 g1 = g1_f68::type_id::create("g1");
                    g1.create_objects(dir, 4'b0001);
                    g1.h2drsp_h[0].copy(h2drsp_h);
                    void'(g1.randomize);
                    void'(g1.pack_slot());
                    case (slot_num)
                      1 : flit.pack_flit(,g1,,);
                      2 : flit.pack_flit(,,g1,);
                      3 : flit.pack_flit(,,,g1);
                    endcase
                    seq.flit_q.push_back(flit);
                  end
            _G2 : begin
                    g2_f68 g2 = g2_f68::type_id::create("g2");
                    g2.create_objects(dir, 3'b100);
                    g2.h2drsp_h.copy(h2drsp_h);
                    void'(g2.randomize);
                    void'(g2.pack_slot());
                    case (slot_num)
                      1 : flit.pack_flit(,g2,,);
                      2 : flit.pack_flit(,,g2,);
                      3 : flit.pack_flit(,,,g2);
                    endcase
                    seq.flit_q.push_back(flit);
                  end
            _G5 : begin
                    g5_f68 g5 = g5_f68::type_id::create("g5");
                    g5.create_objects(dir, 2'b10);
                    g5.h2drsp_h.copy(h2drsp_h);
                    void'(g5.randomize);
                    void'(g5.pack_slot());
                    case (slot_num)
                      1 : flit.pack_flit(,g5,,);
                      2 : flit.pack_flit(,,g5,);
                      3 : flit.pack_flit(,,,g5);
                    endcase
                    seq.flit_q.push_back(flit);
                  end
          endcase
        end
      "D2H_REQ" : 
        begin
          if (!(slot_type inside {_H1, _G1, _G2})) begin
            msg = $sformatf("Invalid slot_type of %0s for %0s message; returning", slot_type.name, txn.txn_type);
            `uvm_error(get_type_name, msg)
            return;
          end
          $cast(d2hreq_h, txn);
          case(slot_type)
            _H1 : begin
                    h1_f68 h1 = h1_f68::type_id::create("h1");
                    h1.create_objects(dir, 3'b001);
                    h1.d2hreq_h.copy(d2hreq_h);
                    void'(h1.randomize());
                    void'(h1.pack_slot());
                    flit.pack_flit(h1);
                    seq.flit_q.push_back(flit);
                  end
            _G1 : begin
                    g1_f68 g1 = g1_f68::type_id::create("g1");
                    g1.create_objects(dir, 4'b0001);
                    g1.d2hreq_h.copy(d2hreq_h);
                    void'(g1.randomize);
                    void'(g1.pack_slot());
                    case (slot_num)
                      1 : flit.pack_flit(,g1,,);
                      2 : flit.pack_flit(,,g1,);
                      3 : flit.pack_flit(,,,g1);
                    endcase
                    seq.flit_q.push_back(flit);
                  end
            _G2 : begin
                    g2_f68 g2 = g2_f68::type_id::create("g2");
                    g2.create_objects(dir, 3'b001);
                    g2.d2hreq_h.copy(d2hreq_h);
                    void'(g2.randomize);
                    void'(g2.pack_slot());
                    case (slot_num)
                      1 : flit.pack_flit(,g2,,);
                      2 : flit.pack_flit(,,g2,);
                      3 : flit.pack_flit(,,,g2);
                    endcase
                    seq.flit_q.push_back(flit);
                  end
          endcase
        end
      "D2H_DAT" : 
        begin
          if (!(slot_type inside {_H0, _H1, _G2})) begin
            msg = $sformatf("Invalid slot_type of %0s for %0s message; returning", slot_type.name, txn.txn_type);
            `uvm_error(get_type_name, msg)
            return;
          end
          $cast(d2hdat_h, txn);
          case(slot_type)
            _H0 : begin
                    g0be_f68  g0_be;
                    g0_f68    g0[0:3];
                    h0_f68    h0 = h0_f68::type_id::create("h0");
                    h0.create_objects(dir, 3'b001);
                    h0.d2hdat_h.copy(d2hdat_h);
                    if (sqr.cfg.split_32B_disable) h0.d2hdat_h.txfer_64B = 1;
                    void'(h0.randomize() with {h0.d2hdat_h.rand_hdr68.ch == 1'b0;});
                    void'(h0.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = h0.d2hdat_h.dat[ii*128+:128]; 
                    end
                    if (h0.d2hdat_h.be != '1) begin
                      g0_be     = g0be_f68::type_id::create("g0_be");
                      g0_be.dir = dir;
                      g0_be.be  = h0.d2hdat_h.be;
                      void'(g0_be.pack_slot());
                    end
                    if (h0.d2hdat_h.txfer_64B) begin
                      flit.pack_flit(h0, g0[0], g0[1], g0[2]);
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      flit.pack_flit(, g0[3], g0_be,);
                      seq.flit_q.push_back(flit);
                    end
                    else begin
                      // Split 32B w/ or wo/BE are handled  
                      flit.pack_flit(h0, g0[0], g0[1], g0_be);
                      seq.flit_q.push_back(flit);
                      h0.d2hdat_h.hdr68.ch = 1'b1;
                      void'(h0.pack_slot());
                      flit = flit.new_flit();
                      flit.pack_flit(h0, g0[2], g0[3], g0_be);
                      seq.flit_q.push_back(flit);
                    end
                  end
            _H1 : begin
                    g0be_f68  g0_be;
                    g0_f68    g0[0:3];
                    h1_f68    h1 = h1_f68::type_id::create("h1");
                    h1.create_objects(dir, 3'b010);
                    h1.d2hdat_h.copy(d2hdat_h);
                    if (sqr.cfg.split_32B_disable) h1.d2hdat_h.txfer_64B = 1;
                    void'(h1.randomize() with {h1.d2hdat_h.rand_hdr68.ch == 1'b0;});
                    void'(h1.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = h1.d2hdat_h.dat[ii*128+:128]; 
                    end
                    if (h1.d2hdat_h.be != '1) begin
                      g0_be     = g0be_f68::type_id::create("g0_be");
                      g0_be.dir = dir;
                      g0_be.be  = d2hdat_h.be;
                      void'(g0_be.pack_slot());
                    end
                    if (h1.d2hdat_h.txfer_64B) begin
                      flit.pack_flit(h1, g0[0], g0[1], g0[2]);
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      flit.pack_flit(, g0[3], g0_be,);
                      seq.flit_q.push_back(flit);
                    end
                    else begin
                      // Split 32B w/ or wo/BE are handled  
                      flit.pack_flit(h1, g0[0], g0[1], g0_be);
                      seq.flit_q.push_back(flit);
                      h1.d2hdat_h.hdr68.ch = 1'b1;
                      void'(h1.pack_slot());
                      flit = flit.new_flit();
                      flit.pack_flit(h1, g0[2], g0[3], g0_be);
                      seq.flit_q.push_back(flit);
                    end
                  end
            _G2 : begin
                    hslot_fmt_t hfmt;
                    g0be_f68    g0_be;
                    g0_f68      g0[0:3];
                    g2_f68      g2 = g2_f68::type_id::create("g2");
                    g2.create_objects(dir, 3'b010);
                    g2.d2hdat_h.copy(d2hdat_h);
                    if (sqr.cfg.split_32B_disable) g2.d2hdat_h.txfer_64B = 1;
                    void'(g2.randomize() with {g2.d2hdat_h.rand_hdr68.ch == 1'b0;});
                    void'(g2.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = g2.d2hdat_h.dat[ii*128+:128]; 
                    end
                    if (g2.d2hdat_h.be != '1) begin
                      g0_be     = g0be_f68::type_id::create("g0_be");
                      g0_be.dir = dir;
                      g0_be.be  = g2.d2hdat_h.be;
                      void'(g0_be.pack_slot());
                    end
                    if (g2.d2hdat_h.txfer_64B) begin
                      case (slot_num)
                        1 : flit.pack_flit(,g2, g0[0], g0[1]);
                        2 : flit.pack_flit(,,   g2,    g0[0]);
                        3 : flit.pack_flit(,,,         g2);
                      endcase
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      case (slot_num)
                        1 : flit.pack_flit(,g0[2], g0[3], g0_be);
                        2 : begin 
                              if (g2.d2hdat_h.be != '1)
                                flit.pack_flit(g0[1], g0[2], g0[3], g0_be);
                              else
                                flit.pack_flit(,      g0[1], g0[2], g0[3]);
                            end
                        3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]);
                      endcase
                      seq.flit_q.push_back(flit);
                      if (g2.d2hdat_h.be != '1 && slot_num == 3) begin
                        flit = flit.new_flit();
                        flit.pack_flit(,g0_be,,);
                        seq.flit_q.push_back(flit);
                      end
                    end
                    else begin 
                      slot_base hb;
                      h0_f68   h0;
                      h1_f68   h1;
                      void'(std::randomize(hfmt) with {hfmt inside {H0, H1};});
                      case (hfmt)
                        H0 : begin 
                               h0 = h0_f68::type_id::create("h0");  
                               h0.create_objects(dir, 1'b1);
                               h0.d2hdat_h.copy(d2hdat_h);
                               h0.d2hdat_h.hdr68.ch = 1'b1;
                               void'(h0.randomize());
                               void'(h0.pack_slot());
                               hb = h0;
                             end
                        H1 : begin 
                               h1 = h1_f68::type_id::create("h1");  
                               h1.create_objects(dir, 2'b10);
                               h1.d2hdat_h.copy(d2hdat_h);
                               h1.d2hdat_h.hdr68.ch = 1'b1;
                               void'(h1.randomize());
                               void'(h1.pack_slot());
                               hb = h1;
                             end
                      endcase
                      // Split 32B w/BE
                      if (g2.d2hdat_h.be != '1) begin
                        case (slot_num)
                          1 : flit.pack_flit(,g2, g0[0], g0[1]);
                          2 : flit.pack_flit(,,   g2,    g0[0]);
                          3 : flit.pack_flit(,,,         g2);
                        endcase
                        seq.flit_q.push_back(flit);
                        flit = flit.new_flit();
                        case (slot_num)
                          1 : flit.pack_flit(hb, g0_be, g0[2], g0[3]);
                          2 : flit.pack_flit(hb, g0[1], g0_be, g0[2]);
                          3 : flit.pack_flit(hb, g0[0], g0[1], g0_be);
                        endcase
                        seq.flit_q.push_back(flit);
                        flit = flit.new_flit();
                        case (slot_num)
                          1 : flit.pack_flit(,g0_be,      ,      );
                          2 : flit.pack_flit(,g0[3], g0_be,      );
                          3 : flit.pack_flit(,g0[2], g0[3], g0_be);
                        endcase
                        seq.flit_q.push_back(flit);
                      end
                      // Split 32B wo/BE
                      else begin
                        case (slot_num)
                          1 : flit.pack_flit(,g2, g0[0], g0[1]);
                          2 : flit.pack_flit(,,   g2,    g0[0]);
                          3 : flit.pack_flit(,,,         g2);
                        endcase
                        seq.flit_q.push_back(flit);
                        flit = flit.new_flit();
                        case (slot_num)
                          1 : flit.pack_flit(hb, g0[2], g0[3],      );
                          2 : flit.pack_flit(hb, g0[1], g0[2], g0[3]);
                          3 : flit.pack_flit(hb, g0[0], g0[1], g0[2]);
                        endcase
                        seq.flit_q.push_back(flit);
                        if (slot_num == 3) begin
                          flit = flit.new_flit();
                          flit.pack_flit(,g0[3],,);
                          seq.flit_q.push_back(flit);
                        end
                      end
                    end
                  end
          endcase
        end
      "D2H_RSP" : 
        begin
          if (!(slot_type inside {_H0, _G1, _G2})) begin
            msg = $sformatf("Invalid slot_type of %0s for %0s message; returning", slot_type.name, txn.txn_type);
            `uvm_error(get_type_name, msg)
            return;
          end
          $cast(d2hrsp_h, txn);
          case(slot_type)
            _H0 : begin
                    h0_f68 h0 = h0_f68::type_id::create("h0");
                    h0.create_objects(dir, 4'b0010);
                    h0.d2hrsp_h[0].copy(d2hrsp_h);
                    void'(h0.randomize());
                    void'(h0.pack_slot());
                    flit.pack_flit(h0);
                    seq.flit_q.push_back(flit);
                  end
            _G1 : begin
                    g1_f68 g1 = g1_f68::type_id::create("g1");
                    g1.create_objects(dir, 4'b0010);
                    g1.d2hrsp_h[0].copy(d2hrsp_h);
                    void'(g1.randomize);
                    void'(g1.pack_slot());
                    case (slot_num)
                      1 : flit.pack_flit(,g1,,);
                      2 : flit.pack_flit(,,g1,);
                      3 : flit.pack_flit(,,,g1);
                    endcase
                    seq.flit_q.push_back(flit);
                  end
            _G2 : begin
                    g2_f68 g2 = g2_f68::type_id::create("g2");
                    g2.create_objects(dir, 3'b100);
                    g2.d2hrsp_h.copy(d2hrsp_h);
                    void'(g2.randomize);
                    void'(g2.pack_slot());
                    case (slot_num)
                      1 : flit.pack_flit(,g2,,);
                      2 : flit.pack_flit(,,g2,);
                      3 : flit.pack_flit(,,,g2);
                    endcase
                    seq.flit_q.push_back(flit);
                  end
          endcase
        end
      default : return;
    endcase

    // Insert invalid flits ahead of actual flit to shift it. Note this only
    // works if the flit_q was empty before this API was called.
    if (flit_num) begin
      flit = flit68_txn::type_id::create("flit");
      flit.dir = dir;
      flit.pack_flit();
      repeat(flit_num) seq.flit_q.push_front(flit);
    end

    // Run the sequence
    seq.start(sqr);

  endtask

  // Users can use this to easily send up to 4 transaction layer messages.
  // This task includes randomization and error checking to make sure something
  // something invalid isn't sent. It is required to pass >1 transaction 
  // handle to the txn array argument, but any argument inside the object's member
  // can be unspecified; it will just get randomized. Thus, the user gets any
  // amount of control they want. There are a limited number of MDH flits, so this
  // only has limited randomization potential. Scroll down to see the table in this method 
  // to see all the valid and invalid combinations of arguments.
  //   - txn[$:4] (reqd) : handle to objects of type s2mdrs_c (3 max), h2ddat_c (4 max),
  //                       d2hdat_c (4 max)
  //   - slot_num   : [0:3], (-1 -> randomized)
  //   - flit_num   : [0:sqr.cfg.nfi_width-1], (-1 -> tightly packed; -2 -> randomize)
  //   Slot type is inferred from the slot_num given because there is only one slot format for MDH
  //     - (h2ddat_c -> {_H3(4),_G3(4)}
  //     - (d2hdat_c -> {_H2(4),_G3(4)}, 
  //     - (s2mdrs_c -> {_H5(2),_G6(3)})
  virtual task issue_msg_mdh(
    base_txn   txn[$:4],
    int        slot_num  = -1,
    int        flit_num  = -1
  );

    bit        ret;
    slot_fmt_t slot_type;
    string     msg;
    bit [0:3]  not_null;

    cxl_nfi_mst_in_order_seq#(NFI_W) seq = cxl_nfi_mst_in_order_seq#(NFI_W)::type_id::create("seq");
    flit68_txn flit                      = flit68_txn::type_id::create("flit");

    s2mdrs_c s2mdrs_h[0:2];
    h2ddat_c h2ddat_h[0:3];
    d2hdat_c d2hdat_h[0:3];

    if (sqr.cfg.mdh_disable) begin
      `uvm_warning(get_type_name, "cfg.mdh_disable is set; returning");
      return; 
    end

    // Copy global setting here
    flit.disable_tight_pack_check = sqr.cfg.disable_tight_pack_check;
    flit.dir                      = sqr.cfg.dir;

    // Sum the valid number of handles and make sure >1
    foreach (txn[ii]) not_null[ii] = (txn[ii] != null);
    if ($countones(not_null)<2) begin
      `uvm_error(get_type_name, "issue_msg_mdh must receive more than 1 valid txn handle to be an MDH flit")
      return;
    end

    // Make sure txn has all object handles tightly packed 
    case (not_null) inside
      4'b01?? : ret=1'b1;
      4'b?01? : ret=1'b1;
      4'b??01 : ret=1'b1;
    endcase
    if (ret) begin
      `uvm_error(get_type_name, "Tightly pack (left align) the transactions in txn argument; returning")
      return;
    end

    // Make sure all object handles are same type
    foreach (txn[ii]) begin
      if (not_null[ii])
        if (txn[0].txn_type != txn[ii].txn_type) begin
          `uvm_error(get_type_name, "All txns are not of same type; returning")
          return;
        end
    end

    // Make sure 4 S2M_DRS txns are not given or 3 S2M_DRS txns and a header slot specified
    if (txn[0].txn_type=="S2M_DRS") begin
      if ($countones(not_null)==4) begin
        `uvm_error(get_type_name, "Cannot transmit 4 S2M_DRS txns in a single MDH header slot")
        return;
      end
      else if ($countones(not_null)==4 && slot_num==0) begin
        `uvm_error(get_type_name, "Cannot transmit 3 S2M_DRS txns in a header slot")
        return;
      end
    end

    // Make sure user gave data txns
    if (!(txn[0].txn_type.substr(4,6) inside {"DRS","DAT"})) begin
      `uvm_error(get_type_name, "Must pass S2M_DRS, H2D_DAT, or D2H_DAT txns to this method")
      return;
    end

    // Make sure user selected an available slot, else exit
    if (!(slot_num inside {[-1:3]})) begin
      msg = $sformatf("Invalid selection of %0d for slot_num argument; returning", slot_num);
      `uvm_error(get_type_name, msg)
      return;
    end

    // Make sure user selected an available flit, else exit
    nfi_width = sqr.cfg.nfi_width;
    if (!(flit_num inside {[-2:nfi_width-1]})) begin
      msg = $sformatf("Invalid selection of %0d for flit_num argument; returning", flit_num);
      `uvm_error(get_type_name, msg);
      return;
    end

    // Make sure dir is correct, else exit
    dir = sqr.cfg.dir;
    if ((txn[0].txn_type.substr(0,2) inside {"H2D"      } && dir == C2H) || 
        (txn[0].txn_type.substr(0,2) inside {"D2H","S2M"} && dir == H2C))
    begin
      msg = $sformatf("Can't send a %0s txn when the agent dir is %0s; returning", txn[0].txn_type, dir);
      `uvm_error(get_type_name, msg)
      return;
    end

    // Initialize randomization to on
    r_slot_num.rand_mode(1);
    r_flit_num.rand_mode(1);
    // Perform randomization after setup
    if (slot_num != -1) begin
      r_slot_num = slot_num;
      r_slot_num.rand_mode(0);
    end
    if (flit_num >= -1) begin
      r_flit_num = flit_num==-1 ? 0 : flit_num;
      r_flit_num.rand_mode(0);
    end
    // Do randomization
    void'(this.randomize());
    // Assign to finalized values
    slot_num = r_slot_num;
    flit_num = r_flit_num;
    
    // Make sure slot_type is correct
    if (txn[0].txn_type=="S2M_DRS")
      slot_type = slot_num==0 ? _H5 : _G6;
    else if (txn[0].txn_type=="H2D_DAT")
      slot_type = slot_num==0 ? _H3 : _G3;
    else //D2H_DAT
      slot_type = slot_num==0 ? _H2 : _G3;

     msg = slot_type.name;
    `uvm_info("::issue_msg_mdh", $sformatf("Sending %0d %0ss via %0s slot (MDH) in slot position %0d and flit position %0d", $countones(not_null), txn[0].txn_type, msg.substr(1,2), slot_num, flit_num), UVM_MEDIUM)

    // Build the flit(s) to send
    case(txn[0].txn_type)
      "S2M_DRS" :
        begin
          // Cast to specific txn
          foreach (txn[ii]) $cast(s2mdrs_h[ii], txn[ii]); 
          case(slot_type)
            _H5 : begin
                    g0_f68    g0[0:3];
                    h5_f68    h5 = h5_f68::type_id::create("h5");
                    h5.create_objects(dir, 2'b11); 
                    h5.s2mdrs_h[0].copy(s2mdrs_h[0]);
                    h5.s2mdrs_h[1].copy(s2mdrs_h[1]);
                    void'(h5.randomize());
                    void'(h5.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = h5.s2mdrs_h[0].dat[ii*128+:128]; 
                    end
                    flit.pack_flit(h5, g0[0], g0[1], g0[2]); //Txn0(3)
                    seq.flit_q.push_back(flit);
                    flit = flit.new_flit();
                    foreach (g0[ii]) begin 
                      if (ii<3) g0[ii].data = h5.s2mdrs_h[1].dat[ii*128+:128]; 
                    end
                    flit.pack_flit(g0[3], g0[0], g0[1], g0[2]); //Txn0(1), Txn1(3)
                    seq.flit_q.push_back(flit);
                    flit = flit.new_flit();
                    g0[3].data = h5.s2mdrs_h[1].dat[3*128+:128];
                    flit.pack_flit(,g0[3],,); //Txn1(1)
                    seq.flit_q.push_back(flit);
                  end
            _G6 : begin
                    g6_f68    g6 = g6_f68::type_id::create("g6");
                    g0_f68    g0[0:3];
                    g6.create_objects(dir, '0);
                    foreach (txn[ii]) begin
                      g6.s2mdrs_h[ii].copy(s2mdrs_h[ii]);
                      g6.s2mdrs_h[ii].hdr68.val = 1'b1;
                    end
                    void'(g6.randomize());
                    void'(g6.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = g6.s2mdrs_h[0].dat[ii*128+:128]; 
                    end
                    case (slot_num)
                      1 : flit.pack_flit(, g6, g0[0], g0[1]);
                      2 : flit.pack_flit(,,    g6,    g0[0]);
                      3 : flit.pack_flit(,,,          g6);
                    endcase
                    seq.flit_q.push_back(flit);
                    flit = flit.new_flit();
                    // Txn1 assignment
                    for (int ii=0; ii<(4-slot_num-1); ii++) g0[ii].data = g6.s2mdrs_h[1].dat[ii*128+:128];
                    case (slot_num)
                      1 : flit.pack_flit(g0[2], g0[3], g0[0], g0[1]); //Txn0(2), Txn1(2)
                      2 : flit.pack_flit(g0[1], g0[2], g0[3], g0[0]); //Txn0(3), Txn1(1)
                      3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn0(4)
                    endcase
                    seq.flit_q.push_back(flit);
                    flit = flit.new_flit();
                    /* Txn2 not present */
                    if (s2mdrs_h[2] == null) begin
                      case (slot_num)
                        1 : flit.pack_flit(,      g0[2], g0[3]);        //Txn1(2)
                        2 : flit.pack_flit(,      g0[1], g0[2], g0[3]); //Txn1(3)
                        3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn1(4)
                      endcase
                      seq.flit_q.push_back(flit);
                    end
                    /* Txn2 present */
                    else begin
                      // Txn2 assignment
                      for (int ii=0; ii<(4-slot_num-1); ii++) g0[ii].data = g6.s2mdrs_h[2].dat[ii*128+:128];
                      case (slot_num)
                        1 : flit.pack_flit(g0[2], g0[3], g0[0], g0[1]); //Txn1(2), Txn2(2)
                        2 : flit.pack_flit(g0[1], g0[2], g0[3], g0[0]); //Txn1(3), Txn2(1)
                        3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn1(4)
                      endcase
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      for (int ii=4-slot_num-1; ii<4; ii++) g0[ii].data = g6.s2mdrs_h[2].dat[ii*128+:128];
                      case (slot_num)
                        1 : flit.pack_flit(,      g0[2], g0[3]);        //Txn2(2)
                        2 : flit.pack_flit(,      g0[1], g0[2], g0[3]); //Txn2(3)
                        3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn2(4)
                      endcase
                      seq.flit_q.push_back(flit);
                    end
                  end
          endcase
        end //"S2M_DRS"
      "D2H_DAT" :
        begin
          // Cast to specific txn
          foreach (txn[ii]) $cast(d2hdat_h[ii], txn[ii]); 
          case(slot_type)
            _H2 : begin
                    g0_f68    g0[0:3];
                    h2_f68    h2 = h2_f68::type_id::create("h2");
                    h2.create_objects(dir, '0);
                    foreach (txn[ii]) begin
                      h2.d2hdat_h[ii].copy(d2hdat_h[ii]);
                      h2.d2hdat_h[ii].hdr68.val = 1'b1;
                    end
                    void'(h2.randomize());
                    void'(h2.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = h2.d2hdat_h[0].dat[ii*128+:128]; 
                    end
                    flit.pack_flit(h2, g0[0], g0[1], g0[2]); //Txn0(3)
                    seq.flit_q.push_back(flit);
                    flit = flit.new_flit();
                    foreach (g0[ii]) begin 
                      if (ii<3) g0[ii].data = h2.d2hdat_h[1].dat[ii*128+:128]; 
                    end
                    flit.pack_flit(g0[3], g0[0], g0[1], g0[2]); //Txn0(1), Txn1(3)
                    seq.flit_q.push_back(flit);
                    flit = flit.new_flit();
                    g0[3].data = h2.d2hdat_h[1].dat[3*128+:128];
                    if (d2hdat_h[2] == null) begin
                      flit.pack_flit(,g0[3],,); //Txn1(1)
                      seq.flit_q.push_back(flit);
                    end
                    else begin
                      // Txn2 assignment
                      foreach (g0[ii]) begin 
                        if (ii<3) g0[ii].data = h2.d2hdat_h[2].dat[ii*128+:128];
                      end
                      flit.pack_flit(g0[3], g0[0], g0[1], g0[2]); //Txn1(1), Txn2(3)
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      g0[3].data = h2.d2hdat_h[2].dat[3*128+:128];
                      if (d2hdat_h[3] == null) begin
                        flit.pack_flit(,g0[3],,); //Txn2(1)
                        seq.flit_q.push_back(flit);
                      end
                      else begin
                        // Txn3 assignment
                        foreach (g0[ii]) begin 
                          if (ii<3) g0[ii].data = h2.d2hdat_h[3].dat[ii*128+:128];
                        end
                        flit.pack_flit(g0[3], g0[0], g0[1], g0[2]); //Txn2(1), Txn3(3)
                        seq.flit_q.push_back(flit);
                        flit = flit.new_flit();
                        g0[3].data = h2.d2hdat_h[3].dat[3*128+:128];
                        flit.pack_flit(,g0[3],,); //Txn3(1)
                        seq.flit_q.push_back(flit);
                      end
                    end
                  end
            _G3 : begin
                    g3_f68    g3 = g3_f68::type_id::create("g3");
                    g0_f68    g0[0:3];
                    g3.create_objects(dir, '0);
                    foreach (txn[ii]) begin
                      g3.d2hdat_h[ii].copy(d2hdat_h[ii]);
                      g3.d2hdat_h[ii].hdr68.val = 1'b1;
                    end
                    void'(g3.randomize());
                    void'(g3.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = g3.d2hdat_h[0].dat[ii*128+:128]; 
                    end
                    case (slot_num)
                      1 : flit.pack_flit(, g3, g0[0], g0[1]);
                      2 : flit.pack_flit(,,    g3,    g0[0]);
                      3 : flit.pack_flit(,,,          g3);
                    endcase
                    seq.flit_q.push_back(flit);
                    flit = flit.new_flit();
                    // Txn1 assignment
                    for (int ii=0; ii<(4-slot_num-1); ii++) g0[ii].data = g3.d2hdat_h[1].dat[ii*128+:128];
                    case (slot_num)
                      1 : flit.pack_flit(g0[2], g0[3], g0[0], g0[1]); //Txn0(2), Txn1(2)
                      2 : flit.pack_flit(g0[1], g0[2], g0[3], g0[0]); //Txn0(3), Txn1(1)
                      3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn0(4)
                    endcase
                    seq.flit_q.push_back(flit);
                    flit = flit.new_flit();
                    for (int ii=(4-slot_num-1); ii<4; ii++) g0[ii].data = g3.d2hdat_h[1].dat[ii*128+:128];
                    /* Txn2 not present */
                    if (d2hdat_h[2] == null) begin
                      case (slot_num)
                        1 : flit.pack_flit(,      g0[2], g0[3]);        //Txn1(2)
                        2 : flit.pack_flit(,      g0[1], g0[2], g0[3]); //Txn1(3)
                        3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn1(4)
                      endcase
                      seq.flit_q.push_back(flit);
                    end
                    /* Txn2 present */
                    else begin
                      for (int ii=0; ii<(4-slot_num-1); ii++) g0[ii].data = g3.d2hdat_h[2].dat[ii*128+:128];
                      case (slot_num)
                        1 : flit.pack_flit(g0[2], g0[3], g0[0], g0[1]); //Txn1(2), Txn2(2)
                        2 : flit.pack_flit(g0[1], g0[2], g0[3], g0[0]); //Txn1(3), Txn2(1)
                        3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn1(4)
                      endcase
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      for (int ii=(4-slot_num-1); ii<4; ii++) g0[ii].data = g3.d2hdat_h[2].dat[ii*128+:128];
                      /* Txn3 not present */
                      if (d2hdat_h[3] == null) begin
                        case (slot_num)
                          1 : flit.pack_flit(,      g0[2], g0[3]);        //Txn2(2)
                          2 : flit.pack_flit(,      g0[1], g0[2], g0[3]); //Txn2(3)
                          3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn2(4)
                        endcase
                        seq.flit_q.push_back(flit);
                      end
                      /* Txn3 present */
                      else begin
                        for (int ii=0; ii<(4-slot_num-1); ii++) g0[ii].data = g3.d2hdat_h[3].dat[ii*128+:128];
                        case (slot_num)
                          1 : flit.pack_flit(g0[2], g0[3], g0[0], g0[1]); //Txn2(2), Txn3(2)
                          2 : flit.pack_flit(g0[1], g0[2], g0[3], g0[0]); //Txn2(3), Txn3(1)
                          3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn2(4)
                        endcase
                        seq.flit_q.push_back(flit);
                        flit = flit.new_flit();
                        for (int ii=(4-slot_num-1); ii<4; ii++) g0[ii].data = g3.d2hdat_h[3].dat[ii*128+:128];
                        case (slot_num)
                          1 : flit.pack_flit(,      g0[2], g0[3]);        //Txn3(2)
                          2 : flit.pack_flit(,      g0[1], g0[2], g0[3]); //Txn3(3)
                          3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn3(4)
                        endcase
                        seq.flit_q.push_back(flit);
                      end
                    end
                  end
          endcase
        end //"D2H_DAT"
      "H2D_DAT" :
        begin
          // Cast to specific txn
          foreach (txn[ii]) $cast(h2ddat_h[ii], txn[ii]); 
          case(slot_type)
            _H3 : begin
                    g0_f68    g0[0:3];
                    h3_f68    h3 = h3_f68::type_id::create("h3");
                    h3.create_objects(dir, '0);
                    foreach (txn[ii]) begin
                      h3.h2ddat_h[ii].copy(h2ddat_h[ii]);
                      h3.h2ddat_h[ii].hdr68.val = 1'b1;
                    end
                    void'(h3.randomize());
                    void'(h3.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = h3.h2ddat_h[0].dat[ii*128+:128]; 
                    end
                    flit.pack_flit(h3, g0[0], g0[1], g0[2]); //Txn0(3)
                    seq.flit_q.push_back(flit);
                    flit = flit.new_flit();
                    foreach (g0[ii]) begin 
                      if (ii<3) g0[ii].data = h3.h2ddat_h[1].dat[ii*128+:128]; 
                    end
                    flit.pack_flit(g0[3], g0[0], g0[1], g0[2]); //Txn0(1), Txn1(3)
                    seq.flit_q.push_back(flit);
                    flit = flit.new_flit();
                    g0[3].data = h3.h2ddat_h[1].dat[3*128+:128];
                    if (h2ddat_h[2] == null) begin
                      flit.pack_flit(,g0[3],,); //Txn1(1)
                      seq.flit_q.push_back(flit);
                    end
                    else begin
                      // Txn2 assignment
                      foreach (g0[ii]) begin 
                        if (ii<3) g0[ii].data = h3.h2ddat_h[2].dat[ii*128+:128];
                      end
                      flit.pack_flit(g0[3], g0[0], g0[1], g0[2]); //Txn1(1), Txn2(3)
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      g0[3].data = h3.h2ddat_h[2].dat[3*128+:128];
                      if (h2ddat_h[3] == null) begin
                        flit.pack_flit(,g0[3],,); //Txn2(1)
                        seq.flit_q.push_back(flit);
                      end
                      else begin
                        // Txn3 assignment
                        foreach (g0[ii]) begin 
                          if (ii<3) g0[ii].data = h3.h2ddat_h[3].dat[ii*128+:128];
                        end
                        flit.pack_flit(g0[3], g0[0], g0[1], g0[2]); //Txn2(1), Txn3(3)
                        seq.flit_q.push_back(flit);
                        flit = flit.new_flit();
                        g0[3].data = h3.h2ddat_h[3].dat[3*128+:128];
                        flit.pack_flit(,g0[3],,); //Txn3(1)
                        seq.flit_q.push_back(flit);
                      end
                    end
                  end
            _G3 : begin
                    g3_f68    g3 = g3_f68::type_id::create("g3");
                    g0_f68    g0[0:3];
                    g3.create_objects(dir, '0);
                    foreach (txn[ii]) begin
                      g3.h2ddat_h[ii].copy(h2ddat_h[ii]);
                      g3.h2ddat_h[ii].hdr68.val = 1'b1;
                    end
                    void'(g3.randomize());
                    void'(g3.pack_slot());
                    foreach (g0[ii]) begin 
                      g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
                      g0[ii].dir  = dir;
                      g0[ii].data = g3.h2ddat_h[0].dat[ii*128+:128]; 
                    end
                    case (slot_num)
                      1 : flit.pack_flit(, g3, g0[0], g0[1]);
                      2 : flit.pack_flit(,,    g3,    g0[0]);
                      3 : flit.pack_flit(,,,          g3);
                    endcase
                    seq.flit_q.push_back(flit);
                    flit = flit.new_flit();
                    // Txn1 assignment
                    for (int ii=0; ii<(4-slot_num-1); ii++) g0[ii].data = g3.h2ddat_h[1].dat[ii*128+:128];
                    case (slot_num)
                      1 : flit.pack_flit(g0[2], g0[3], g0[0], g0[1]); //Txn0(2), Txn1(2)
                      2 : flit.pack_flit(g0[1], g0[2], g0[3], g0[0]); //Txn0(3), Txn1(1)
                      3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn0(4)
                    endcase
                    seq.flit_q.push_back(flit);
                    flit = flit.new_flit();
                    for (int ii=(4-slot_num-1); ii<4; ii++) g0[ii].data = g3.h2ddat_h[1].dat[ii*128+:128];
                    /* Txn2 not present */
                    if (h2ddat_h[2] == null) begin
                      case (slot_num)
                        1 : flit.pack_flit(,      g0[2], g0[3]);        //Txn1(2)
                        2 : flit.pack_flit(,      g0[1], g0[2], g0[3]); //Txn1(3)
                        3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn1(4)
                      endcase
                      seq.flit_q.push_back(flit);
                    end
                    /* Txn2 present */
                    else begin
                      for (int ii=0; ii<(4-slot_num-1); ii++) g0[ii].data = g3.h2ddat_h[2].dat[ii*128+:128];
                      case (slot_num)
                        1 : flit.pack_flit(g0[2], g0[3], g0[0], g0[1]); //Txn1(2), Txn2(2)
                        2 : flit.pack_flit(g0[1], g0[2], g0[3], g0[0]); //Txn1(3), Txn2(1)
                        3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn1(4)
                      endcase
                      seq.flit_q.push_back(flit);
                      flit = flit.new_flit();
                      for (int ii=(4-slot_num-1); ii<4; ii++) g0[ii].data = g3.h2ddat_h[2].dat[ii*128+:128];
                      /* Txn3 not present */
                      if (h2ddat_h[3] == null) begin
                        case (slot_num)
                          1 : flit.pack_flit(,      g0[2], g0[3]);        //Txn2(2)
                          2 : flit.pack_flit(,      g0[1], g0[2], g0[3]); //Txn2(3)
                          3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn2(4)
                        endcase
                        seq.flit_q.push_back(flit);
                      end
                      /* Txn3 present */
                      else begin
                        for (int ii=0; ii<(4-slot_num-1); ii++) g0[ii].data = g3.h2ddat_h[3].dat[ii*128+:128];
                        case (slot_num)
                          1 : flit.pack_flit(g0[2], g0[3], g0[0], g0[1]); //Txn2(2), Txn3(2)
                          2 : flit.pack_flit(g0[1], g0[2], g0[3], g0[0]); //Txn2(3), Txn3(1)
                          3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn2(4)
                        endcase
                        seq.flit_q.push_back(flit);
                        flit = flit.new_flit();
                        for (int ii=(4-slot_num-1); ii<4; ii++) g0[ii].data = g3.h2ddat_h[3].dat[ii*128+:128];
                        case (slot_num)
                          1 : flit.pack_flit(,      g0[2], g0[3]);        //Txn3(2)
                          2 : flit.pack_flit(,      g0[1], g0[2], g0[3]); //Txn3(3)
                          3 : flit.pack_flit(g0[0], g0[1], g0[2], g0[3]); //Txn3(4)
                        endcase
                        seq.flit_q.push_back(flit);
                      end
                    end
                  end
          endcase
        end //"H2D_DAT"
      default : return;
    endcase

    // Insert invalid flits ahead of actual flit to shift it. Note this only
    // works if the flit_q was empty before this API was called.
    if (flit_num) begin
      flit = flit68_txn::type_id::create("flit");
      flit.dir = dir;
      flit.pack_flit();
      repeat(flit_num) seq.flit_q.push_front(flit);
    end

    // Run the sequence
    seq.start(sqr);
  endtask

endclass
