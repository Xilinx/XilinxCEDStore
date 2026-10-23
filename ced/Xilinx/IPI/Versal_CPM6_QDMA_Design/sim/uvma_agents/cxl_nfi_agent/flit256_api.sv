typedef class cxl_nfi_mst_in_order_seq;

class flit256_api#(type SQR, parameter NFI_W=3) extends base_api#(SQR);

  `uvm_component_param_utils(flit256_api#(SQR, NFI_W))

  const static string type_name = {"flit256_api#(",SQR::type_name,$sformatf(",%0d)",NFI_W)};
  virtual function string get_type_name(); return type_name; endfunction

  typedef enum {H2DREQ, H2DRSP, H2DDAT, D2HREQ, D2HRSP, D2HDAT,
                M2SRWD, M2SREQ, M2SBIRSP, S2MNDR, S2MDRS, S2MBISNP} msg_sel_t; 

  dir_t       dir;
  msg_sel_t   msg_sel;

  rand bit [3:0]  r_slot_num;
  rand slot_fmt_t r_slot_fmt;

  constraint c_slot_fmt {
    msg_sel == H2DREQ   -> r_slot_fmt==_HBR_M0;
    msg_sel == H2DDAT   -> r_slot_fmt==_HBR_M12;
    if (!r_slot_num || (r_slot_num==8&&sqr.cfg.flitmode==F256_LOPT)) { //H or HS
      msg_sel == H2DRSP -> r_slot_fmt==_HBR_M1;
    } else {
      msg_sel == H2DRSP -> r_slot_fmt inside {_HBR_M0, _HBR_M1};
    }
    msg_sel == D2HREQ   -> r_slot_fmt==_HBR_M2;
    msg_sel == D2HDAT   -> r_slot_fmt==_HBR_M13;
    if ((r_slot_num==8&&sqr.cfg.flitmode==F256_LOPT)) {  //HS
      msg_sel == D2HRSP -> r_slot_fmt==_HBR_M3;
    } else {
      msg_sel == D2HRSP -> r_slot_fmt inside {_HBR_M2, _HBR_M3};
    }
    msg_sel == M2SREQ   -> r_slot_fmt==_HBR_M4;
    msg_sel == M2SRWD   -> r_slot_fmt==_HBR_M14;
    msg_sel == M2SBIRSP -> r_slot_fmt==_HBR_M5;
    if (!r_slot_num || (r_slot_num==8&&sqr.cfg.flitmode==F256_LOPT)) {  //H or HS
      msg_sel == S2MNDR -> r_slot_fmt==_HBR_M7;
    } else {
      msg_sel == S2MNDR -> r_slot_fmt inside {_HBR_M6, _HBR_M7};
    }
    msg_sel == S2MDRS   -> r_slot_fmt==_HBR_M15;
    msg_sel == S2MBISNP -> r_slot_fmt==_HBR_M6;
  }

  constraint c_no_phy_slot { r_slot_num != 15; }

  constraint c_slot_num { r_slot_num inside {0, 4, 8, 12}; }
  
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
  //   - txn (reqd) : handle to object of type m2sreq_c, m2srwd_c, m2sbirsp_c, 
  //                  s2mndr_c, s2mdrs_c, s2mbisnp_c, h2dreq_c, h2drsp_c, 
  //                  h2ddat_c, d2hreq_c, d2hrsp_c, d2hdat_c
  //   - slot_fmt   : (_RSVD -> randomize), [_HBR_M0:_HBR_M15]; only 3 txn types
  //                  can use different slot types (fmts) (and typically only in
  //                  GSlots, so this should likely be unused by most callers
  //   - slot_num   : [0:14], (-1 -> tightly packed of any slotset, -2 -> any slot)
  virtual task issue_msg(
    base_txn   txn,
    int        slot_num  = -1,
    slot_fmt_t slot_fmt  = _RSVD
  );

    string msg;
    string str_fmt;
    slot_base_f256 slot_q[$:6];

    cxl_nfi_mst_in_order_seq#(NFI_W) seq = cxl_nfi_mst_in_order_seq#(NFI_W)::type_id::create("seq");
    flit256_txn flit                     = flit256_txn::type_id::create("flit");

    m2sreq_c m2sreq_h; m2srwd_c m2srwd_h; m2sbirsp_c m2sbirsp_h;
    s2mndr_c s2mndr_h; s2mdrs_c s2mdrs_h; s2mbisnp_c s2mbisnp_h;
    h2dreq_c h2dreq_h; h2ddat_c h2ddat_h; h2drsp_c h2drsp_h; 
    d2hreq_c d2hreq_h; d2hdat_c d2hdat_h; d2hrsp_c d2hrsp_h; 

    // Global setting to the flit(s) from cfg object
    flit.disable_tight_pack_check = sqr.cfg.disable_tight_pack_check;
    flit.flitmode                 = sqr.cfg.flitmode;
    flit.dir                      = sqr.cfg.dir;

    // Make sure user selected an available slot, else exit
    if (!(slot_num inside {[-2:14]})) begin
      msg = $sformatf("Invalid selection of %0d for slot_num argument; returning", slot_num);
      `uvm_error(get_type_name, msg)
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

    case (txn.txn_type)
      "M2S_REQ"   : msg_sel = M2SREQ;
      "M2S_RWD"   : msg_sel = M2SRWD;
      "M2S_BIRSP" : msg_sel = M2SBIRSP;
      "S2M_NDR"   : msg_sel = S2MNDR;
      "S2M_DRS"   : msg_sel = S2MDRS; 
      "S2M_BISNP" : msg_sel = S2MBISNP;
      "H2D_REQ"   : msg_sel = H2DREQ;
      "H2D_DAT"   : msg_sel = H2DDAT;
      "H2D_RSP"   : msg_sel = H2DRSP;
      "D2H_REQ"   : msg_sel = D2HREQ;
      "D2H_DAT"   : msg_sel = D2HDAT;
      "D2H_RSP"   : msg_sel = D2HRSP;
    endcase

    // Make sure user gave an acceptable slot fmt (and location if given)
    if (slot_fmt != _RSVD) begin
      str_fmt  = slot_fmt.name;
      // Make all fmts contain 2 digits and be of form "M\d\d"
      if (str_fmt.getc(str_fmt.len-2) == "M")
        str_fmt = string'({"M0",str_fmt.getc(str_fmt.len-1)});
      else
        str_fmt = str_fmt.substr(str_fmt.len-3, str_fmt.len-1);
      case (msg_sel)
        M2SREQ : if (str_fmt != "M04") begin
                   `uvm_error(get_type_name, "M2S_REQ txn must have fmt=4; returning")
                   return;
                 end
        M2SRWD : if (str_fmt != "M14; returning") begin
                   `uvm_error(get_type_name, "M2S_RWD txn must have fmt=14; returning")
                   return;
                 end
        M2SBIRSP:if (str_fmt != "M05; returning") begin
                   `uvm_error(get_type_name, "M2S_BIRSP txn must have fmt=5; returning")
                   return;
                 end
        S2MNDR : if (!slot_num || (slot_num==8&&sqr.cfg.flitmode==F256_LOPT)) begin
                   if (str_fmt != "M07; returning") begin
                     `uvm_error(get_type_name, "S2M_NDR txn must have fmt=7 if in H-Slot or HS-Slot position; returning")
                      return;
                   end
                 end
                 else if (!(str_fmt inside {"M06", "M07"})) begin
                   `uvm_error(get_type_name, "S2M_NDR txn must have fmt=6 or fmt=7; returning")
                   return;
                 end
        S2MDRS : if (str_fmt != "M15; returning") begin
                   `uvm_error(get_type_name, "S2M_DRS txn must have fmt=15; returning")
                   return;
                 end
        S2MBISNP:if (str_fmt != "M06; returning") begin
                   `uvm_error(get_type_name, "S2M_BISNP txn must have fmt=6; returning")
                   return;
                 end
        H2DREQ : if (str_fmt != "M00; returning") begin
                   `uvm_error(get_type_name, "H2D_REQ txn must have fmt=0; returning")
                   return;
                 end
        H2DDAT : if (str_fmt != "M12; returning") begin
                   `uvm_error(get_type_name, "H2D_DAT txn must have fmt=12; returning")
                   return;
                 end
        H2DRSP : if (!slot_num || (slot_num==8&&sqr.cfg.flitmode==F256_LOPT)) begin
                   if (str_fmt != "M01; returning") begin
                     `uvm_error(get_type_name, "H2D_RSP txn must have fmt=1 if in H-Slot or HS-Slot position; returning")
                      return;
                   end
                 end
                 else if (!(str_fmt inside {"M00", "M01"})) begin
                   `uvm_error(get_type_name, "H2D_RSP txn must have fmt=0 or fmt=1; returning")
                   return;
                 end
        D2HREQ : if (str_fmt != "M02; returning") begin
                   `uvm_error(get_type_name, "D2H_REQ txn must have fmt=2; returning")
                   return;
                 end
        D2HDAT : if (str_fmt != "M13; returning") begin
                   `uvm_error(get_type_name, "D2H_DAT txn must have fmt=13; returning")
                   return;
                 end
        D2HRSP : if (slot_num==8&&sqr.cfg.flitmode==F256_LOPT) begin
                   if (str_fmt != "M03; returning") begin
                     `uvm_error(get_type_name, "D2H_RSP txn must have fmt=3 if in HS-Slot position; returning")
                      return;
                   end
                 end
                 else if (!(str_fmt inside {"M02", "M03"})) begin
                   `uvm_error(get_type_name, "D2H_RSP txn must have fmt=2 or fmt=3; returning")
                   return;
                 end
        
      endcase
    end

    // Initialize : turn on all constraints and randomization
    // Then : selectively turn off based on args provided
    r_slot_num.rand_mode(1);
    c_slot_num.constraint_mode(1);
    r_slot_fmt.rand_mode(1);
    c_slot_fmt.constraint_mode(1);
    if (slot_num >= 0) begin
      r_slot_num = slot_num;
      r_slot_num.rand_mode(0);
      c_slot_num.constraint_mode(0);
    end
    else if (slot_num == -2) begin
      c_slot_num.constraint_mode(0);
    end
    if (slot_fmt != _RSVD) begin
      r_slot_fmt = slot_fmt;
      r_slot_fmt.rand_mode(0);
    //c_flot_fmt still applies
    end
    void'(this.randomize());
    // Assign to finalized values
    slot_fmt = r_slot_fmt;
    slot_num = r_slot_num;

    // Summarize what we're sending where
    str_fmt = slot_fmt.name;
    msg = $sformatf("Sending %0s via %0s slot in slot position %0d", 
                    txn.txn_type, 
                    str_fmt.substr(1,str_fmt.len-1), 
                    slot_num); 
    `uvm_info(":issue_msg", msg, UVM_MEDIUM)

    str_fmt = slot_fmt.name;
    // Make all fmts contain 2 digits and be of form "M\d\d"
    if (str_fmt.getc(str_fmt.len-2) == "M")
      str_fmt = string'({"M0",str_fmt.getc(str_fmt.len-1)});
    else
      str_fmt = str_fmt.substr(str_fmt.len-3, str_fmt.len-1);

    // Build the flit(s) to send
    case(txn.txn_type)
      "M2S_REQ" : 
        begin
          m4_hbr m4 = m4_hbr::type_id::create("m4_hbr");
          $cast(m2sreq_h, txn);
          m4.create_objects(sqr.cfg.flitmode, slot_num, 1'b1);
          m4.m2sreq_h.copy(m2sreq_h);
          void'(m4.randomize());
          void'(m4.pack_slot());
          slot_q.push_back(m4);
        end
      "M2S_RWD" : 
        begin
          m14_hbr      m14 = m14_hbr::type_id::create("m14_hbr");
          f256_data    dat[0:3];
          f256_trailer trp;
          $cast(m2srwd_h, txn);
          m14.create_objects(sqr.cfg.flitmode, slot_num, 1'b1);
          m14.m2srwd_h.copy(m2srwd_h);
          m14.m2srwd_h.c_noemd.constraint_mode(~|sqr.cfg.emd_bits);
          void'(m14.randomize());
          void'(m14.pack_slot());
          slot_q.push_back(m14);
          foreach (dat[ii]) begin 
            dat[ii]      = f256_data::type_id::create($sformatf("dat[%0d]",ii));
            dat[ii].data = m14.m2srwd_h.dat[ii*128+:128];
            slot_q.push_back(dat[ii]);
          end
          if (m14.m2srwd_hdr.trp) begin
            trp = f256_trailer::type_id::create("trp");
            case ({m14.m2srwd_hdr.metafield==ExtMetaState, m14.m2srwd_hdr.memop inside {MemWrPtl, MemWrPtlTEE}})
              2'b00 : `uvm_error(get_type_name, "Header's TRP field set without a need for trailer")
              2'b01 : trp.data = {64'h0, m14.m2srwd_h.be};
              2'b10 : trp.data = {96'h0, m14.m2srwd_h.emd};
              2'b11 : trp.data = {32'h0, m14.m2srwd_h.emd, m14.m2srwd_h.be};
            endcase
            slot_q.push_back(trp);
            if (m14.m2srwd_hdr.metafield==ExtMetaState && !sqr.cfg.emd_bits)
              `uvm_error(get_type_name, "cfg.emd_bits=0 but API is sending a transaction with EMD") 
          end
        end
      "M2S_BIRSP" : 
        begin
          m5_hbr m5 = m5_hbr::type_id::create("m5_hbr");
          $cast(m2sbirsp_h, txn);
          m5.create_objects(sqr.cfg.flitmode, slot_num, 3'b001);
          m5.m2sbirsp_h[0].copy(m2sbirsp_h);
          void'(m5.randomize());
          void'(m5.pack_slot());
          slot_q.push_back(m5);
        end
      "S2M_NDR" : 
        begin
          m6_hbr m6; 
          m7_hbr m7; 
          $cast(s2mndr_h, txn);
          if (r_slot_fmt == _HBR_M6) begin
            m6 = m6_hbr::type_id::create("m6_hbr");
            m6.create_objects(sqr.cfg.flitmode, slot_num, 2'b10);
            m6.s2mndr_h.copy(s2mndr_h);
            void'(m6.randomize());
            void'(m6.pack_slot());
            slot_q.push_back(m6);
          end
          else begin
            m7 = m7_hbr::type_id::create("m7_hbr");
            m7.create_objects(sqr.cfg.flitmode, slot_num, 3'b1);
            m7.s2mndr_h[0].copy(s2mndr_h);
            void'(m7.randomize());
            void'(m7.pack_slot());
            slot_q.push_back(m7);
          end
        end
      "S2M_DRS" : 
        begin
          m15_hbr      m15 = m15_hbr::type_id::create("m15_hbr");
          f256_data    dat[0:3];
          f256_trailer trp;
          $cast(s2mdrs_h, txn);
          m15.create_objects(sqr.cfg.flitmode, slot_num, 1'b1);
          m15.s2mdrs_h[0].copy(s2mdrs_h);
          m15.s2mdrs_h[0].c_noemd.constraint_mode(~|sqr.cfg.emd_bits);
          void'(m15.randomize());
          void'(m15.pack_slot());
          slot_q.push_back(m15);
          foreach (dat[ii]) begin 
            dat[ii]      = f256_data::type_id::create($sformatf("dat[%0d]",ii));
            dat[ii].data = m15.s2mdrs_h[0].dat[ii*128+:128];
            slot_q.push_back(dat[ii]);
          end
          if (m15.trp[0]) begin
            trp = f256_trailer::type_id::create("trp");
            trp.data = {96'h0, m15.s2mdrs_h[0].emd};
            slot_q.push_back(trp);
            if (!sqr.cfg.emd_bits)
              `uvm_error(get_type_name, "cfg.emd_bits=0 but API is sending a transaction with EMD") 
          end
        end
      "S2M_BISNP" : 
        begin
          m6_hbr m6 = m6_hbr::type_id::create("m6_hbr");
          $cast(s2mbisnp_h, txn);
          m6.create_objects(sqr.cfg.flitmode, slot_num, 'b1);
          m6.s2mbisnp_h.copy(s2mbisnp_h);
          void'(m6.randomize());
          void'(m6.pack_slot());
          slot_q.push_back(m6);
        end
      "H2D_REQ" : 
        begin
          m0_hbr m0 = m0_hbr::type_id::create("m0_hbr");
          $cast(h2dreq_h, txn);
          m0.create_objects(sqr.cfg.flitmode, slot_num, 'b1);
          m0.h2dreq_h.copy(h2dreq_h);
          void'(m0.randomize());
          void'(m0.pack_slot());
          slot_q.push_back(m0);
        end
      "H2D_DAT" : 
        begin
          m12_hbr      m12 = m12_hbr::type_id::create("m12_hbr");
          f256_data    dat[0:3];
          $cast(h2ddat_h, txn);
          m12.create_objects(sqr.cfg.flitmode, slot_num, 1'b1);
          m12.h2ddat_h[0].copy(h2ddat_h);
          void'(m12.randomize());
          void'(m12.pack_slot());
          slot_q.push_back(m12);
          foreach (dat[ii]) begin 
            dat[ii]      = f256_data::type_id::create($sformatf("dat[%0d]",ii));
            dat[ii].data = m12.h2ddat_h[0].dat[ii*128+:128];
            slot_q.push_back(dat[ii]);
          end
        end
      "H2D_RSP" : 
        begin
          m0_hbr m0; 
          m1_hbr m1; 
          $cast(h2drsp_h, txn);
          if (r_slot_fmt == _HBR_M6) begin
            m0 = m0_hbr::type_id::create("m0_hbr");
            m0.create_objects(sqr.cfg.flitmode, slot_num, 2'b10);
            m0.h2drsp_h.copy(h2drsp_h);
            void'(m0.randomize());
            void'(m0.pack_slot());
            slot_q.push_back(m0);
          end
          else begin
            m1 = m1_hbr::type_id::create("m1_hbr");
            m1.create_objects(sqr.cfg.flitmode, slot_num, 3'b1);
            m1.h2drsp_h[0].copy(h2drsp_h);
            void'(m1.randomize());
            void'(m1.pack_slot());
            slot_q.push_back(m1);
          end
        end
      "D2H_REQ" : 
        begin
          m2_hbr m2 = m2_hbr::type_id::create("m2_hbr");
          $cast(d2hreq_h, txn);
          m2.create_objects(sqr.cfg.flitmode, slot_num, 3'b1);
          m2.d2hreq_h.copy(d2hreq_h);
          void'(m2.randomize());
          void'(m2.pack_slot());
          slot_q.push_back(m2);
        end
      "D2H_DAT" : 
        begin
          m13_hbr      m13 = m13_hbr::type_id::create("m13_hbr");
          f256_data    dat[0:3];
          f256_trailer trp;
          $cast(d2hdat_h, txn);
          m13.create_objects(sqr.cfg.flitmode, slot_num, 1'b1);
          m13.d2hdat_h[0].copy(d2hdat_h);
          void'(m13.randomize());
          void'(m13.pack_slot());
          slot_q.push_back(m13);
          foreach (dat[ii]) begin 
            dat[ii]      = f256_data::type_id::create($sformatf("dat[%0d]",ii));
            dat[ii].data = m13.d2hdat_h[0].dat[ii*128+:128];
            slot_q.push_back(dat[ii]);
          end
          if (m13.bep[0]) begin
            trp = f256_trailer::type_id::create("trp");
            trp.data = {64'h0, m13.d2hdat_h[0].be};
            slot_q.push_back(trp);
          end
        end
      "D2H_RSP" : 
        begin
          m2_hbr m2; 
          m3_hbr m3; 
          $cast(d2hrsp_h, txn);
          if (r_slot_fmt == _HBR_M6) begin
            m2 = m2_hbr::type_id::create("m2_hbr");
            m2.create_objects(sqr.cfg.flitmode, slot_num, 2'b10);
            m2.d2hrsp_h[0].copy(d2hrsp_h);
            void'(m2.randomize());
            void'(m2.pack_slot());
            slot_q.push_back(m2);
          end
          else begin
            m3 = m3_hbr::type_id::create("m3_hbr");
            m3.create_objects(sqr.cfg.flitmode, slot_num, 3'b1);
            m3.d2hrsp_h[0].copy(d2hrsp_h);
            void'(m3.randomize());
            void'(m3.pack_slot());
            slot_q.push_back(m3);
          end
        end
      default : return;
    endcase

    // After building slots into queue, now pack them into a flit starting at an offset
    while (slot_q.size || slot_num==15) begin
      // Get the string name
      if (slot_q.size) str_fmt = slot_q[0]._fmt.name;
      // Skip PHY slot
      if (slot_num==15) begin
        flit.pack();
        seq.flit_q.push_back(flit);
        flit = flit.new_flit();
        slot_num = 0;
        if (!slot_q.size) break;
      end
      // Data can't be packed into H-Slots, so skip it
      if ((str_fmt.getc(1) inside {"D","T"}) && !slot_num) begin
        slot_num++;
      end
      // Pack the slot into the flit
      flit.slot[slot_num++] = slot_q.pop_front;
    end
    // Building terminated in the middle of a flit
    if (slot_num) begin
      flit.pack();
      seq.flit_q.push_back(flit);
    end

    // Run the sequence
    seq.start(sqr);

  endtask

  // Users can use this to easily send up to 4 transaction layer messages.
  // This task includes randomization and error checking to make sure something
  // something invalid isn't sent. It is required to pass >1 transaction 
  // handle to the txn array argument, but any argument inside the object's member
  // can be unspecified; it will just get randomized. Thus, the user gets any
  // amount of control they want over each txn.
  //   - txn[$:4] (reqd) : handle to objects of type s2mdrs_c (3 max; 2 for H/HS), 
  //                       h2ddat_c (4 max; 3 for H/HS), d2hdat_c (4 max; 3 for HS) 
  //   - slot_num   : [0:14], (-1 -> tightly packed of any slotset, -2 -> any slot)
  virtual task issue_msg_mdh(
    base_txn   txn[$:4],
    int        slot_num  = -1
  );

    bit            ret;
    bit [0:3]      not_null;
    string         msg;
    bit            no_rand_hslot;
    string         str_fmt;
    slot_fmt_t     slot_fmt;
    slot_base_f256 slot_q[$:21];

    cxl_nfi_mst_in_order_seq#(NFI_W) seq = cxl_nfi_mst_in_order_seq#(NFI_W)::type_id::create("seq");
    flit256_txn flit                     = flit256_txn::type_id::create("flit");

    s2mdrs_c s2mdrs_h[0:2];
    h2ddat_c h2ddat_h[0:3];
    d2hdat_c d2hdat_h[0:3];

    if (sqr.cfg.mdh_disable) begin
      `uvm_warning(get_type_name, "cfg.mdh_disable is set; returning");
      return; 
    end
    
    // Global setting to the flit(s) from cfg object
    flit.disable_tight_pack_check = sqr.cfg.disable_tight_pack_check;
    flit.dir                      = sqr.cfg.dir;
    flit.flitmode                 = sqr.cfg.flitmode;

    // Sum the valid number of handles and make sure >=1 is valid
    foreach (txn[ii]) not_null[ii] = (txn[ii] != null);
    if ($countones(not_null) == 1) begin
      `uvm_warning(get_type_name, "If sending only one valid txn, can use issue_msg instead of issue_msg_mdh")
    end
    else if ($countones(not_null) == 0) begin
      `uvm_warning(get_type_name, "issue_msg_mdh only given handles to null objects; returning")
      return;
    end
    // Make sure they're tightly packed as given to this function
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

    // Can never send 4 S2M_DRS, even though our max Q size is 4 
    if (txn[0].txn_type=="S2M_DRS" && $countones(not_null)==4) begin
      `uvm_error(get_type_name, "Cannot send 4 S2M_DRS txns from a single HDR slot; returning")
      return;
    end

    // Make sure a specified H-Slot does not exceed the max transactions for that slot
    if (txn[0].txn_type=="H2D_DAT" && $countones(not_null)==4) begin
      if (slot_num == 0) begin
        `uvm_error(get_type_name, "Cannot send 4 H2D_DAT txns in an H-Slot")
        return;
      end
      else if (slot_num inside {-2,-1}) 
        no_rand_hslot = 1;
    end
    else if (txn[0].txn_type=="S2M_DRS" && $countones(not_null)==3) begin
      if (slot_num == 0) begin
        `uvm_error(get_type_name, "Cannot send 3 S2M_DRS txns in an H-Slot") 
        return;
      end
      else if (slot_num inside {-2,-1}) 
        no_rand_hslot = 1;
    end

    // Make sure user gave data txns
    if (!(txn[0].txn_type.substr(4,6) inside {"DRS","DAT"})) begin
      `uvm_error(get_type_name, "Must pass S2M_DRS, H2D_DAT, or D2H_DAT txns to this method")
      return;
    end

    // Make sure user selected an available slot, else exit
    if (!(slot_num inside {[-2:14]})) begin
      msg = $sformatf("Invalid selection of %0d for slot_num argument; returning", slot_num);
      `uvm_error(get_type_name, msg)
      return;
    end

    // Make sure dir is correct, else exit
    dir = sqr.cfg.dir;
    if ((txn[0].txn_type.substr(0,2) inside {"H2D"      } && dir == C2H) || 
        (txn[0].txn_type.substr(0,2) inside {"D2H","S2M"} && dir == H2C))
    begin
      msg = $sformatf("Can't send %0s txn(s) when the agent dir is %0s; returning", txn[0].txn_type, dir);
      `uvm_error(get_type_name, msg)
      return;
    end

    // Initialize : turn on randomization of slot num and off for slot fmt
    // Then : selectively turn off based on args provided
    r_slot_num.rand_mode(1);
    c_slot_num.constraint_mode(1);
    r_slot_fmt.rand_mode(0);
    c_slot_fmt.constraint_mode(0);
    if (slot_num >= 0) begin
      r_slot_num = slot_num;
      r_slot_num.rand_mode(0);
      c_slot_num.constraint_mode(0);
    end
    else if (slot_num == -2) begin
      c_slot_num.constraint_mode(0);
    end
    if (no_rand_hslot) void'(this.randomize() with { r_slot_num != 0; });
    else               void'(this.randomize());
    // Assign to finalized values
    slot_num = r_slot_num;
    case (txn[0].txn_type)
      "H2D_DAT" : slot_fmt = _HBR_M12;
      "D2H_DAT" : slot_fmt = _HBR_M13;
      "S2M_DRS" : slot_fmt = _HBR_M15;
      default   : begin
                    `uvm_error(get_type_name, "Must pass S2M_DRS, H2D_DAT, or D2H_DAT txns to this method")
                    return;
                  end
    endcase

    // Summarize what we're sending where
    str_fmt = slot_fmt.name;
    msg = $sformatf("Sending %0d %0ss via %0s slot in slot position %0d", 
                    $countones(not_null),
                    txn[0].txn_type, 
                    str_fmt.substr(1,str_fmt.len-1), 
                    slot_num); 
    `uvm_info("::issue_msg_mdh", msg, UVM_MEDIUM)

    // Build the flit(s) to send
    case(txn[0].txn_type)
      "S2M_DRS" : 
        begin
          m15_hbr      m15 = m15_hbr::type_id::create("m15_hbr");
          f256_data    dat[0:3];
          f256_trailer trp;
          foreach (txn[ii]) $cast(s2mdrs_h[ii], txn[ii]);
          m15.create_objects(sqr.cfg.flitmode, slot_num, '0);
          foreach (txn[ii]) begin
            m15.s2mdrs_h[ii].copy(s2mdrs_h[ii]);
            m15.s2mdrs_h[ii].hdr256.val = 1'b1;
            m15.s2mdrs_h[ii].c_noemd.constraint_mode(~|sqr.cfg.emd_bits);
          end
          void'(m15.randomize());
          void'(m15.pack_slot());
          slot_q.push_back(m15);
          foreach (txn[ii]) begin
            foreach (dat[jj]) begin 
              dat[jj]      = f256_data::type_id::create($sformatf("dat[%0d]",jj));
              dat[jj].data = m15.s2mdrs_h[ii].dat[jj*128+:128];
              slot_q.push_back(dat[jj]);
            end
            if (|m15.trp && ii==0) begin
              trp = f256_trailer::type_id::create("trp");
              case (m15.trp)
                3'b001 : trp.data = {m15.s2mdrs_h[0].emd};
                3'b010 : trp.data = {m15.s2mdrs_h[1].emd};
                3'b100 : trp.data = {m15.s2mdrs_h[2].emd};
                3'b011 : trp.data = {m15.s2mdrs_h[1].emd, m15.s2mdrs_h[0].emd};
                3'b110 : trp.data = {m15.s2mdrs_h[2].emd, m15.s2mdrs_h[1].emd};
                3'b101 : trp.data = {m15.s2mdrs_h[2].emd, m15.s2mdrs_h[0].emd};
                3'b111 : trp.data = {m15.s2mdrs_h[2].emd, m15.s2mdrs_h[1].emd, m15.s2mdrs_h[0].emd};
              endcase
              slot_q.push_back(trp);
              if (!sqr.cfg.emd_bits)
                `uvm_error(get_type_name, "cfg.emd_bits=0 but API is sending a transaction with EMD") 
            end
          end
        end
      "H2D_DAT" : 
        begin
          m12_hbr      m12 = m12_hbr::type_id::create("m12_hbr");
          f256_data    dat[0:3];
          foreach (txn[ii]) $cast(h2ddat_h[ii], txn[ii]);
          m12.create_objects(sqr.cfg.flitmode, slot_num, '0);
          foreach (txn[ii]) begin
            m12.h2ddat_h[ii].copy(h2ddat_h[ii]);
            m12.h2ddat_h[ii].hdr256.val = 1'b1;
          end
          void'(m12.randomize());
          void'(m12.pack_slot());
          slot_q.push_back(m12);
          foreach (txn[ii]) begin
            foreach (dat[jj]) begin 
              dat[jj]      = f256_data::type_id::create($sformatf("dat[%0d]",jj));
              dat[jj].data = m12.h2ddat_h[ii].dat[jj*128+:128];
              slot_q.push_back(dat[ii]);
            end
          end
        end
      "D2H_DAT" : 
        begin
          m13_hbr      m13 = m13_hbr::type_id::create("m13_hbr");
          f256_data    dat[0:3];
          f256_trailer trp;
          foreach (txn[ii]) $cast(d2hdat_h[ii], txn[ii]);
          m13.create_objects(sqr.cfg.flitmode, slot_num, '0);
          foreach (txn[ii]) begin
            m13.d2hdat_h[ii].copy(d2hdat_h[ii]);
            m13.d2hdat_h[ii].hdr256.val = 1'b1;
          end
          void'(m13.randomize());
          void'(m13.pack_slot());
          slot_q.push_back(m13);
          foreach (txn[ii]) begin
            foreach (dat[jj]) begin 
              dat[jj]      = f256_data::type_id::create($sformatf("dat[%0d]",jj));
              dat[jj].data = m13.d2hdat_h[ii].dat[jj*128+:128];
              slot_q.push_back(dat[ii]);
            end
            if (m13.bep[ii]) begin
              trp = f256_trailer::type_id::create("trp");
              trp.data = {64'h0, m13.d2hdat_h[ii].be};
              slot_q.push_back(trp);
            end
          end
        end
    endcase

    // After building slots into queue, now pack them into a flit starting at an offset
    while (slot_q.size || slot_num==15) begin
      // Get the string name
      if (slot_q.size) str_fmt = slot_q[0]._fmt.name;
      // Skip PHY slot
      if (slot_num==15) begin
        flit.pack();
        seq.flit_q.push_back(flit);
        flit = flit.new_flit();
        slot_num = 0;
        if (!slot_q.size) break;
      end
      // Data can't be packed into H-Slots, so skip it
      if ((str_fmt.getc(1) inside {"D","T"}) && !slot_num) begin
        slot_num++;
      end
      // Pack the slot into the flit
      flit.slot[slot_num++] = slot_q.pop_front;
    end
    // Building terminated in the middle of a flit
    if (slot_num) begin
      flit.pack();
      seq.flit_q.push_back(flit);
    end

    // Run the sequence
    seq.start(sqr);
  endtask

endclass
