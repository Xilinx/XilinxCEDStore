class flit256_mst_rand_seq#(parameter NFI_W=3) extends cxl_nfi_mst_in_order_seq#(NFI_W);

  `uvm_object_param_utils(flit256_mst_rand_seq#(NFI_W))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("flit256_mst_rand_seq#(%0d)",NFI_W);
  virtual function string get_type_name(); return type_name; endfunction

  int          flit_to_send; //-1=run forever, else decrement until 0
  int unsigned total_flit_count;
  int unsigned valid_flit_count;
  int unsigned empty_flit_count;
  int unsigned txn_count[1:0][2:0]; //[1:0] = MEM/CCH, [2:0] = REQ/DAT/RSP

  // constants for enum 
  const int cREQ = 0, cDAT = 1, cRSP = 2;

  function new(string name = "flit256_mst_rand_seq");
    super.new(name);
  endfunction

  // Only relevant for NFI_W=3, when we only have 3
  // slotsets and a flit takes 4 slotsets. 
  bit [1:0] flit_in_set;
  bit [1:0] r_flits_in_set;
  int set_odds[1:3] = '{1, 1, 1}; 

  typedef enum {H2DREQ, H2DRSP, H2DDAT, D2HREQ, D2HRSP, D2HDAT, 
                M2SREQ, M2SRWD, M2SBIRSP, S2MNDR, S2MDRS, S2MBISNP,
                NONE, DATA} e_txn_type; 

  rand e_txn_type r_tt;  //r_tt = "randomized txn type"
  rand bit [2:0]  r_nt;  //r_nt = "randomized number of txns"
  rand bit        r_lo;  //r_lo = "randomized low" (if a txn type fits in either msg type, choose lower or higher)
  rand bit        r_rpk; //r_rpk = "randomized repack" (into a previous slot if possible)

  bit [1:0] r_fgap; //r_fgap = "randomized valid flit to flit gap"

  bit [ 3:0]  sptr;  //sptr = "slot ptr"
  bit [0:15]  smpty; //smpty = "slot empty"
  int         cntFLIT[1:0][2:0];  //cntFLIT = "count (of each) txn type in the flit"
  int         cntFLITS[1:0][2:0]; //cntFLITS = "count (of each) txn type in the flit SET"

  // Default valid flit to flit odds
  int gap_odds[0:3] = '{10,3,2,1};
  
  constraint c_txn_type {
    // Randomize fully or only allow what link partner has credits for
    if (!ignore_avail_credits) {
      // When we get down to or at zero credits, must make sure we don't set the
      // number of txns to exceed the available credits  
      r_tt inside {M2SREQ,  S2MBISNP} -> 
        (r_nt+cntFLIT[MEM][cREQ]+cntFLITS[MEM][cREQ])<=p_sequencer.shr.avl_req_credit[MEM];
      r_tt inside {M2SRWD,  S2MDRS}   -> 
        (r_nt+cntFLIT[MEM][cDAT]+cntFLITS[MEM][cDAT])<=p_sequencer.shr.avl_dat_credit[MEM];
      r_tt inside {M2SBIRSP,S2MNDR}   -> 
        (r_nt+cntFLIT[MEM][cRSP]+cntFLITS[MEM][cRSP])<=p_sequencer.shr.avl_rsp_credit[MEM];
      r_tt inside {H2DREQ,  D2HREQ}   -> 
        (r_nt+cntFLIT[CCH][cREQ]+cntFLITS[CCH][cREQ])<=p_sequencer.shr.avl_req_credit[CCH];
      r_tt inside {H2DDAT,  D2HDAT}   -> 
        (r_nt+cntFLIT[CCH][cDAT]+cntFLITS[CCH][cDAT])<=p_sequencer.shr.avl_dat_credit[CCH];
      r_tt inside {H2DRSP,  D2HRSP}   -> 
        (r_nt+cntFLIT[CCH][cRSP]+cntFLITS[CCH][cRSP])<=p_sequencer.shr.avl_rsp_credit[CCH];
    }
    // Don't include txn types if not supported 
    !p_sequencer.cfg.cxl_cch_sup   -> !(r_tt inside {[H2DREQ:D2HDAT]});
    !p_sequencer.cfg.cxl_mem_sup   -> !(r_tt inside {[M2SREQ:S2MBISNP]});
    !p_sequencer.cfg.cxl_membi_sup -> !(r_tt inside {M2SBIRSP,S2MBISNP});
    // Must match direction
    p_sequencer.cfg.dir==H2C -> r_tt inside {[H2DREQ:H2DDAT],[M2SREQ:M2SBIRSP], NONE};
    p_sequencer.cfg.dir==C2H -> r_tt inside {[D2HREQ:D2HDAT],[S2MNDR:S2MBISNP], NONE};
    // For the last txn
    !flit_to_send -> r_tt==NONE;
    // We never randomize to a data chunk, this is for internal tracking
    r_tt != DATA;
    // Solve the txn_type first
    solve r_tt before r_nt;
    solve r_tt before r_lo; 
    solve r_tt before r_rpk;
    // general
    if (r_tt==NONE) r_nt==0;
    else            r_nt!=0;
    // H-Slot/G-Slot max txn limitations
    r_tt==M2SREQ   -> r_nt == 1;
    r_tt==M2SRWD   -> r_nt == 1;
    r_tt==M2SBIRSP -> r_nt <= (!sptr ? 2 : 3);
    r_tt==S2MBISNP -> r_nt == 1;
    r_tt==S2MDRS   -> r_nt <= (p_sequencer.cfg.mdh_disable ? 1 : (!sptr ? 2 : 3));
    r_tt==S2MNDR   -> r_nt <= (!sptr ? 2 : 3);
    r_tt==H2DREQ   -> r_nt == 1;
    r_tt==H2DDAT   -> r_nt <= (p_sequencer.cfg.mdh_disable ? 1 : (!sptr ? 3 : 4));
    r_tt==H2DRSP   -> r_nt <= (!sptr ? 2 : 3);
    r_tt==D2HREQ   -> r_nt == 1;
    r_tt==D2HDAT   -> r_nt <= (p_sequencer.cfg.mdh_disable ? 1 : 4);
    r_tt==D2HRSP   -> r_nt <= 4;
  }

  // This task will build one flit (equiv. to four slotsets) at a time and send it
  virtual task body();

    string      msg;
    string      sptr_str;
    bit         has_trp;
    bit [1:0]   s2mdrs_trp_q[$:5]; //must keep track when to insert trp
    bit [0:2]   s2mdrs_trp;
    int         ii;
    int         dd;
    int         may_repack;  
    bit         did_repack;
    int         max_msg_128B[1:0][2:0];
    int         cntSS[1:0][2:0];  //cntSS  = "count (of) slotset (txns)"
    int         pcntSS[1:0][2:0]; //pcntSS = "previous count (of) slotset (txns)"
    base_txn    dat_q[$:7];
    flit256_txn fgap;
    // Transactions we will randomize to
    h2dreq_c    h2dreq;   d2hreq_c    d2hreq;
    h2ddat_c    h2ddat;   d2hdat_c    d2hdat;
    h2drsp_c    h2drsp;   d2hrsp_c    d2hrsp;
    m2sreq_c    m2sreq;   s2mndr_c    s2mndr;
    m2srwd_c    m2srwd;   s2mdrs_c    s2mdrs;
    m2sbirsp_c  m2sbirsp; s2mbisnp_c  s2mbisnp; 
    // Transactions will pack into slots
    m0_hbr      m0;     /*m8_hbr       m8; */ //all these reserved slots 
    m1_hbr      m1;     /*m9_hbr       m9; */ 
    m2_hbr      m2;     /*m10_hbr      m10;*/  
    m3_hbr      m3;     /*m11_hbr      m11;*/ 
    m4_hbr      m4;       m12_hbr      m12;
    m5_hbr      m5;       m13_hbr      m13;
    m6_hbr      m6;       m14_hbr      m14;
    m7_hbr      m7;       m15_hbr      m15;
    f256_data   dat;      f256_trailer trlr;

    // Flit that we'll pack into
    flit256_txn flit = flit256_txn::type_id::create("flit");

    // constant
    max_msg_128B[MEM][cREQ] = p_sequencer.cfg.dir==H2C ? 4 : 2; 
    max_msg_128B[MEM][cDAT] = p_sequencer.cfg.dir==H2C ? 2 : 3; 
    max_msg_128B[MEM][cRSP] = p_sequencer.cfg.dir==H2C ? 3 : 6; 
    max_msg_128B[CCH][cREQ] = p_sequencer.cfg.dir==H2C ? 4 : 4; 
    max_msg_128B[CCH][cDAT] = p_sequencer.cfg.dir==H2C ? 2 : 4; 
    max_msg_128B[CCH][cRSP] = p_sequencer.cfg.dir==H2C ? 6 : 4; 

    // empty NFI interface
    fgap = flit256_txn::type_id::create("fgap");
    fgap.gap = 1'b1;
  
    // Initial setup (once)
    flit.flitmode = F256;
    flit.dir      = p_sequencer.cfg.dir;

    // Control run length
    while (flit_to_send || flit_to_send==-1 || flit.slotset[3].rollover) begin

      // Initialize each flit
      sptr  = 0;
      smpty = '1;
      flit = flit.new_flit;
      cntFLIT = '{default: 0};

      `uvm_info(get_type_name, $sformatf("Building Flit %0d", total_flit_count), UVM_INFO)

      // Randomize txns and pack them until a whole flit is packed
      // Must be careful to pack txns tightly and not violate max messages rules
      while (sptr<15) begin
        did_repack = 1'b0;
        // max message tracking
        if (!(sptr%4)) begin
          pcntSS = cntSS;
          cntSS  = '{default: 0};
        end
        // start new txn(s)
        if (!sptr || !dat_q.size) begin
          // randomize first
          void'(this.randomize);
          // create objects
          case (r_tt) inside 
            M2SREQ   : if ((pcntSS[MEM][cREQ]+cntSS[MEM][cREQ])<max_msg_128B[MEM][cREQ]) begin
                         // r_nt + current count could exceed max; cap it at max
                         if ((pcntSS[MEM][cREQ]+cntSS[MEM][cREQ]+r_nt)>max_msg_128B[MEM][cREQ])
                           r_nt = max_msg_128B[MEM][cREQ]-pcntSS[MEM][cREQ]-cntSS[MEM][cREQ];
                         // build it
                         m2sreq = m2sreq_c::type_id::create("m2sreq");
                         m2sreq.flitmode = F256;
                         m2sreq.req256.val = 1'b1;
                         void'(m2sreq.randomize);
                         // ensure tightly packed slotset 
                         attempt_tight_pack;
                         // pack it
                         m4 = m4_hbr::type_id::create("m4");
                         {m4.flitmode, m4.slot_num} = {F256, sptr};
                         m4.m2sreq = m2sreq.req256;
                         void'(m4.pack_slot);
                         // final assign
                         flit.slot[sptr] = m4;
                         // flit tracking
                         smpty[sptr] = 1'b0;
                         cntSS[MEM][cREQ] += r_nt;
                         cntFLIT[MEM][cREQ] += r_nt;
                         // sequence tracking
                         txn_count[MEM][cREQ] += r_nt;
                       end
                       else r_tt = NONE;
            S2MBISNP : if ((pcntSS[MEM][cREQ]+cntSS[MEM][cREQ])<max_msg_128B[MEM][cREQ]) begin
                         // r_nt + current count could exceed max; cap it at max
                         if ((pcntSS[MEM][cREQ]+cntSS[MEM][cREQ]+r_nt)>max_msg_128B[MEM][cREQ])
                           r_nt = max_msg_128B[MEM][cREQ]-pcntSS[MEM][cREQ]-cntSS[MEM][cREQ];
                         // build it
                         s2mbisnp = s2mbisnp_c::type_id::create("s2mbisnp");
                         s2mbisnp.flitmode = F256;
                         s2mbisnp.bisnp256.val = 1'b1;
                         void'(s2mbisnp.randomize);
                         // ensure tightly packed slotset 
                         attempt_tight_pack;
                         // pack it
                         m6 = m6_hbr::type_id::create("m6");
                         {m6.flitmode, m6.slot_num} = {F256, sptr};
                         m6.s2mbisnp = s2mbisnp.bisnp256;
                         m6.s2mndr   = '0;
                         void'(m6.pack_slot);
                         // final assign
                         flit.slot[sptr] = m6;
                         // flit tracking
                         smpty[sptr] = 1'b0;
                         cntSS[MEM][cREQ] += r_nt;
                         cntFLIT[MEM][cREQ] += r_nt;
                         // sequence tracking
                         txn_count[MEM][cREQ] += r_nt;
                       end 
                       else r_tt = NONE;
            M2SBIRSP : if ((pcntSS[MEM][cRSP]+cntSS[MEM][cRSP])<max_msg_128B[MEM][cRSP]) begin
                         // r_nt + current count could exceed max; cap it at max
                         if ((pcntSS[MEM][cRSP]+cntSS[MEM][cRSP]+r_nt)>max_msg_128B[MEM][cRSP])
                           r_nt = max_msg_128B[MEM][cRSP]-pcntSS[MEM][cRSP]-cntSS[MEM][cRSP];
                         // ensure tightly packed slotset 
                         attempt_tight_pack;
                         // build it
                         m5 = m5_hbr::type_id::create("m5");
                         {m5.flitmode, m5.slot_num} = {F256, sptr};
                         for (ii=0; ii<(sptr?3:2); ii++) begin
                           m2sbirsp = m2sbirsp_c::type_id::create("m2sbirsp");
                           m2sbirsp.flitmode = F256;
                           m2sbirsp.birsp256.val = 1'b1;
                           void'(m2sbirsp.randomize);
                           // pack it
                           m5.m2sbirsp[ii] = ii<r_nt ? m2sbirsp.birsp256 : '0;
                         end
                         void'(m5.pack_slot);
                         // final assign
                         flit.slot[sptr] = m5;
                         // flit tracking
                         smpty[sptr] = 1'b0;
                         cntSS[MEM][cRSP] += r_nt;
                         cntFLIT[MEM][cRSP] += r_nt;
                         // sequence tracking
                         txn_count[MEM][cRSP] += r_nt;
                       end 
                       else r_tt = NONE;
            S2MNDR   : if ((pcntSS[MEM][cRSP]+cntSS[MEM][cRSP])<max_msg_128B[MEM][cRSP]) begin
                         // r_nt + current count could exceed max; cap it at max
                         if ((pcntSS[MEM][cRSP]+cntSS[MEM][cRSP]+r_nt)>max_msg_128B[MEM][cRSP])
                           r_nt = max_msg_128B[MEM][cRSP]-pcntSS[MEM][cRSP]-cntSS[MEM][cRSP];
                         // build it
                         s2mndr = s2mndr_c::type_id::create("s2mndr");
                         s2mndr.flitmode = F256;
                         s2mndr.ndr256.val = 1'b1;
                         void'(s2mndr.randomize);
                         // - r_nt and r_lo control whether to pack in slot fmt 6 or 7
                         // - we also can re-pack into a previous slot fmt 6 if it's
                         //   not already occupied, this controlled by r_rpk
                         may_repack = 0;
                         // Step 1: let's see if we even CAN repack
                         if (r_nt==1 && r_lo && (sptr%4) && (sptr!=1)) begin
                           // 3 looks back at 2 1
                           // 7 looks back at 6 5 4 
                           for (ii=sptr-1; ii>=((sptr/4)*4)+(sptr<4); ii--) begin 
                             // found last slot with something there
                             if (!smpty[ii]) begin
                               if (flit.slot[ii]._fmt==_HBR_M6) begin
                                 $cast(m6, flit.slot[ii]); 
                                 // previous slot is G6, see if S2MNDR is open
                                 may_repack = (!m6.s2mndr.val);
                               end
                             end
                           end
                         end
                         // Step 2: if we can repack and that's selected, do that
                         if (may_repack && r_rpk) begin
                           did_repack = 1'b1;
                           m6.s2mndr = s2mndr.ndr256;
                           // going back to repack
                           sptr = ii;
                           void'(m6.pack_slot);
                           // final assign
                           flit.slot[sptr] = m6;
                         end
                         // Step 3: if we can't/don't want to repack, but still 
                         // want to pack lo, create a new slot
                         else if (r_nt==1 && r_lo && sptr) begin
                           // ensure tightly packed slotset 
                           attempt_tight_pack;
                           // build it
                           m6 = m6_hbr::type_id::create("m6");
                           {m6.flitmode, m6.slot_num} = {F256, sptr};
                           m6.s2mbisnp = '0;
                           m6.s2mndr = s2mndr.ndr256;
                           void'(m6.pack_slot);
                           // final assign
                           flit.slot[sptr] = m6;
                         end
                         // Step 4: else, we have to pack high 
                         else begin
                           // ensure tightly packed slotset 
                           attempt_tight_pack;
                           // build it
                           m7 = m7_hbr::type_id::create("m7");
                           {m7.flitmode, m7.slot_num} = {F256, sptr};
                           for (ii=0; ii<(sptr?3:2); ii++) begin
                             s2mndr = s2mndr_c::type_id::create("s2mndr");
                             s2mndr.flitmode = F256;
                             s2mndr.ndr256.val = 1'b1;
                             void'(s2mndr.randomize);
                             // pack it
                             m7.s2mndr[ii] = ii<r_nt ? s2mndr.ndr256 : '0;
                           end
                           void'(m7.pack_slot);
                           // final assign
                           flit.slot[sptr] = m7;
                         end
                         // flit tracking
                         smpty[sptr] = 1'b0;
                         cntSS[MEM][cRSP] += r_nt;
                         cntFLIT[MEM][cRSP] += r_nt;
                         // sequence tracking
                         txn_count[MEM][cRSP] += r_nt;
                       end 
                       else r_tt = NONE;
            H2DREQ   : if ((pcntSS[CCH][cREQ]+cntSS[CCH][cREQ])<max_msg_128B[CCH][cREQ]) begin
                         // r_nt + current count could exceed max; cap it at max
                         if ((pcntSS[CCH][cREQ]+cntSS[CCH][cREQ]+r_nt)>max_msg_128B[CCH][cREQ])
                           r_nt = max_msg_128B[CCH][cREQ]-pcntSS[CCH][cREQ]-cntSS[CCH][cREQ];
                         // build it
                         h2dreq = h2dreq_c::type_id::create("h2dreq");
                         h2dreq.flitmode = F256;
                         h2dreq.req256.val = 1'b1;
                         void'(h2dreq.randomize);
                         // ensure tightly packed slotset 
                         attempt_tight_pack;
                         // pack it
                         m0 = m0_hbr::type_id::create("m0");
                         {m0.flitmode, m0.slot_num} = {F256, sptr};
                         m0.h2dreq = h2dreq.req256;
                         m0.h2drsp = '0;
                         void'(m0.pack_slot);
                         // final assign
                         flit.slot[sptr] = m0;
                         // flit tracking
                         smpty[sptr] = 1'b0;
                         cntSS[CCH][cREQ] += r_nt;
                         cntFLIT[CCH][cREQ] += r_nt;
                         // sequence tracking
                         txn_count[CCH][cREQ] += r_nt;
                       end 
                       else r_tt = NONE;
            D2HREQ   : if ((pcntSS[CCH][cREQ]+cntSS[CCH][cREQ])<max_msg_128B[CCH][cREQ]) begin
                         // r_nt + current count could exceed max; cap it at max
                         if ((pcntSS[CCH][cREQ]+cntSS[CCH][cREQ]+r_nt)>max_msg_128B[CCH][cREQ])
                           r_nt = max_msg_128B[CCH][cREQ]-pcntSS[CCH][cREQ]-cntSS[CCH][cREQ];
                         // build it
                         d2hreq = d2hreq_c::type_id::create("d2hreq");
                         d2hreq.flitmode = F256;
                         d2hreq.req256.val = 1'b1;
                         void'(d2hreq.randomize);
                         // ensure tightly packed slotset 
                         attempt_tight_pack;
                         // pack it
                         m2 = m2_hbr::type_id::create("m2");
                         {m2.flitmode, m2.slot_num} = {F256, sptr};
                         m2.d2hreq = d2hreq.req256;
                         m2.d2hrsp[0] = '0;
                         m2.d2hrsp[1] = '0;
                         void'(m2.pack_slot);
                         // final assign
                         flit.slot[sptr] = m2;
                         // flit tracking
                         smpty[sptr] = 1'b0;
                         cntSS[CCH][cREQ] += r_nt;
                         cntFLIT[CCH][cREQ] += r_nt;
                         // sequence tracking
                         txn_count[CCH][cREQ] += r_nt;
                       end 
                       else r_tt = NONE;
            H2DDAT   : if ((pcntSS[CCH][cDAT]+cntSS[CCH][cDAT])<max_msg_128B[CCH][cDAT]) begin
                         // r_nt + current count could exceed max; cap it at max
                         if ((pcntSS[CCH][cDAT]+cntSS[CCH][cDAT]+r_nt)>max_msg_128B[CCH][cDAT])
                           r_nt = max_msg_128B[CCH][cDAT]-pcntSS[CCH][cDAT]-cntSS[CCH][cDAT];
                         // ensure tightly packed slotset 
                         attempt_tight_pack;
                         // build it
                         m12 = m12_hbr::type_id::create("m12");
                         {m12.flitmode, m12.slot_num} = {F256, sptr};
                         for (ii=0; ii<(sptr?4:3); ii++) begin
                           if (ii<r_nt) begin
                             h2ddat = h2ddat_c::type_id::create("h2ddat");
                             h2ddat.flitmode = F256;
                             h2ddat.hdr256.val = 1'b1;
                             void'(h2ddat.randomize);
                             dat_q.push_back(h2ddat);
                             // pack it
                             m12.h2ddat_hdr[ii] = h2ddat.hdr256;
                           end
                           else m12.h2ddat_hdr[ii] = '0;
                         end
                         void'(m12.pack_slot);
                         // final assign
                         flit.slot[sptr] = m12;
                         // flit tracking
                         smpty[sptr] = 1'b0;
                         cntSS[CCH][cDAT] += r_nt;
                         cntFLIT[CCH][cDAT] += r_nt;
                         // sequence tracking
                         txn_count[CCH][cDAT] += r_nt;
                       end 
                       else r_tt = NONE;
            D2HDAT   : if ((pcntSS[CCH][cDAT]+cntSS[CCH][cDAT])<max_msg_128B[CCH][cDAT]) begin
                         // r_nt + current count could exceed max; cap it at max
                         if ((pcntSS[CCH][cDAT]+cntSS[CCH][cDAT]+r_nt)>max_msg_128B[CCH][cDAT])
                           r_nt = max_msg_128B[CCH][cDAT]-pcntSS[CCH][cDAT]-cntSS[CCH][cDAT];
                         // ensure tightly packed slotset 
                         attempt_tight_pack;
                         // build it
                         m13 = m13_hbr::type_id::create("m13");
                         {m13.flitmode, m13.slot_num} = {F256, sptr};
                         for (ii=0; ii<4; ii++) begin
                           if (ii<r_nt) begin
                             d2hdat = d2hdat_c::type_id::create("d2hdat");
                             d2hdat.flitmode = F256;
                             d2hdat.hdr256.val = 1'b1;
                             void'(d2hdat.randomize);
                             dat_q.push_back(d2hdat);
                             // pack it
                             m13.d2hdat_hdr[ii] = d2hdat.hdr256;
                           end
                           else m13.d2hdat_hdr[ii] = '0;
                         end
                         void'(m13.pack_slot);
                         // final assign
                         flit.slot[sptr] = m13;
                         // flit tracking
                         smpty[sptr] = 1'b0;
                         cntSS[CCH][cDAT] += r_nt;
                         cntFLIT[CCH][cDAT] += r_nt;
                         // sequence tracking
                         txn_count[CCH][cDAT] += r_nt;
                       end 
                       else r_tt = NONE;
            M2SRWD   : if ((pcntSS[MEM][cDAT]+cntSS[MEM][cDAT])<max_msg_128B[MEM][cDAT]) begin
                         // build it
                         m2srwd = m2srwd_c::type_id::create("m2srwd");
                         m2srwd.flitmode = F256;
                         m2srwd.hdr256.val = 1'b1;
                         m2srwd.c_noemd.constraint_mode(~|p_sequencer.cfg.emd_bits);
                         void'(m2srwd.randomize);
                         dat_q.push_back(m2srwd);
                         // ensure tightly packed slotset 
                         attempt_tight_pack;
                         // pack it
                         m14 = m14_hbr::type_id::create("m14");
                         {m14.flitmode, m14.slot_num} = {F256, sptr};
                         m14.m2srwd_hdr = m2srwd.hdr256;
                         void'(m14.pack_slot);
                         // final assign
                         flit.slot[sptr] = m14;
                         // flit tracking
                         smpty[sptr] = 1'b0;
                         cntSS[MEM][cDAT] += r_nt;
                         cntFLIT[MEM][cDAT] += r_nt;
                         // sequence tracking
                         txn_count[MEM][cDAT] += r_nt;
                       end 
                       else r_tt = NONE;
            S2MDRS   : if ((pcntSS[MEM][cDAT]+cntSS[MEM][cDAT])<max_msg_128B[MEM][cDAT]) begin
                         // r_nt + current count could exceed max; cap it at max
                         if ((pcntSS[MEM][cDAT]+cntSS[MEM][cDAT]+r_nt)>max_msg_128B[MEM][cDAT])
                           r_nt = max_msg_128B[MEM][cDAT]-pcntSS[MEM][cDAT]-cntSS[MEM][cDAT];
                         // ensure tightly packed slotset 
                         attempt_tight_pack;
                         // build it
                         m15 = m15_hbr::type_id::create("m15");
                         {m15.flitmode, m15.slot_num} = {F256, sptr};
                         has_trp = 1'b0;
                         for (ii=0; ii<(sptr?3:2); ii++) begin
                           if (ii<r_nt) begin
                             s2mdrs = s2mdrs_c::type_id::create("s2mdrs");
                             s2mdrs.flitmode = F256;
                             s2mdrs.hdr256.val = 1'b1;
                             s2mdrs.c_noemd.constraint_mode(~|p_sequencer.cfg.emd_bits);
                             void'(s2mdrs.randomize);
                             has_trp |= s2mdrs.hdr256.trp;
                             dat_q.push_back(s2mdrs);
                             // pack it
                             m15.s2mdrs_hdr[ii] = s2mdrs.hdr256;
                           end
                           else m15.s2mdrs_hdr[ii] = '0;
                         end
                         void'(m15.pack_slot);
                         // for trailer packing later
                         for (ii=0; ii<r_nt; ii++) begin
                           if (!ii && has_trp)
                             s2mdrs_trp_q.push_back(r_nt);
                           else
                             s2mdrs_trp_q.push_back(0);
                         end
                         // final assign
                         flit.slot[sptr] = m15;
                         // flit tracking
                         smpty[sptr] = 1'b0;
                         cntSS[MEM][cDAT] += r_nt;
                         cntFLIT[MEM][cDAT] += r_nt;
                         // sequence tracking
                         txn_count[MEM][cDAT] += r_nt;
                       end 
                       else r_tt = NONE;
            H2DRSP   : if ((pcntSS[CCH][cRSP]+cntSS[CCH][cRSP])<max_msg_128B[CCH][cRSP]) begin
                         // r_nt + current count could exceed max; cap it at max
                         if ((pcntSS[CCH][cRSP]+cntSS[CCH][cRSP]+r_nt)>max_msg_128B[CCH][cRSP])
                           r_nt = max_msg_128B[CCH][cRSP]-pcntSS[CCH][cRSP]-cntSS[CCH][cRSP];
                         // build it
                         h2drsp = h2drsp_c::type_id::create("h2drsp");
                         h2drsp.flitmode = F256;
                         h2drsp.rsp256.val = 1'b1;
                         void'(h2drsp.randomize);
                         // - r_nt and r_lo control whether to pack in slot fmt 0 or 1
                         // - we also can re-pack into a previous slot fmt 0 if it's
                         //   not already occupied, this controlled by r_rpk
                         may_repack = 0;
                         // Step 1: let's see if we even CAN repack
                         if (r_nt==1 && r_lo && (sptr%4) && (sptr!=1)) begin
                           // 3 looks back at 2 1
                           // 7 looks back at 6 5 4 
                           for (ii=sptr-1; ii>=((sptr/4)*4)+(sptr<4); ii--) begin 
                             // found last slot with something there
                             if (!smpty[ii]) begin
                               if (flit.slot[ii]._fmt==_HBR_M0) begin
                                 $cast(m0, flit.slot[ii]); 
                                 // previous slot is G0, see if H2DRSP is open
                                 may_repack = (!m0.h2drsp.val);
                               end
                             end
                           end
                         end
                         // Step 2: if we can repack and that's selected, do that
                         if (may_repack && r_rpk) begin
                           did_repack = 1'b1;
                           m0.h2drsp = h2drsp.rsp256;
                           // going back to repack
                           sptr = ii;
                           void'(m0.pack_slot);
                           // final assign
                           flit.slot[sptr] = m0;
                         end
                         // Step 3: if we can't/don't want to repack, but still 
                         // want to pack lo, create a new slot
                         else if (r_nt==1 && r_lo && sptr) begin
                           // ensure tightly packed slotset 
                           attempt_tight_pack;
                           // build it
                           m0 = m0_hbr::type_id::create("m0");
                           {m0.flitmode, m0.slot_num} = {F256, sptr};
                           m0.h2drsp = h2drsp.rsp256;
                           void'(m0.pack_slot);
                           // final assign
                           flit.slot[sptr] = m0;
                         end
                         // Step 4: else, we have to pack high 
                         else begin
                           // ensure tightly packed slotset 
                           attempt_tight_pack;
                           // build it
                           m1 = m1_hbr::type_id::create("m1");
                           {m1.flitmode, m1.slot_num} = {F256, sptr};
                           for (ii=0; ii<(sptr?3:2); ii++) begin
                             h2drsp = h2drsp_c::type_id::create("h2drsp");
                             h2drsp.flitmode = F256;
                             h2drsp.rsp256.val = 1'b1;
                             void'(h2drsp.randomize);
                             // pack it
                             m1.h2drsp[ii] = ii<r_nt ? h2drsp.rsp256 : '0;
                           end
                           void'(m1.pack_slot);
                           // final assign
                           flit.slot[sptr] = m1;
                         end
                         // flit tracking
                         smpty[sptr] = 1'b0;
                         cntSS[CCH][cRSP] += r_nt;
                         cntFLIT[CCH][cRSP] += r_nt;
                         // sequence tracking
                         txn_count[CCH][cRSP] += r_nt;
                       end 
                       else r_tt = NONE;
            D2HRSP   : if ((pcntSS[CCH][cRSP]+cntSS[CCH][cRSP])<max_msg_128B[CCH][cRSP]) begin
                         // r_nt + current count could exceed max; cap it at max
                         if ((pcntSS[CCH][cRSP]+cntSS[CCH][cRSP]+r_nt)>max_msg_128B[CCH][cRSP])
                           r_nt = max_msg_128B[CCH][cRSP]-pcntSS[CCH][cRSP]-cntSS[CCH][cRSP];
                         // - r_nt and r_lo control whether to pack in slot fmt 2 or 3
                         // - we also can re-pack into a previous slot fmt 2 if it's
                         //   not already occupied, this controlled by r_rpk
                         may_repack = 0;
                         // Step 1: let's see if we even CAN repack
                         if (r_nt inside {1,2} && r_lo && (sptr%4)) begin
                           // 3 looks back at 2 1 0
                           // 7 looks back at 6 5 4 
                           for (ii=sptr-1; ii>=((sptr/4)*4); ii--) begin 
                             // found last slot with something there
                             if (!smpty[ii]) begin
                               if (flit.slot[ii]._fmt==_HBR_M2) begin
                                 $cast(m2, flit.slot[ii]); 
                                 // previous slot is M2, see if D2HRSP[0] is open
                                 may_repack = (!m2.d2hrsp[0].val);
                                 // if a G-Slot, then the next location is open
                                 if (ii && may_repack) may_repack++;
                               end
                             end
                           end
                         end
                         // Step 2: if we can repack and that's selected, do that
                         if (may_repack==r_nt && r_rpk) begin
                           did_repack = 1'b1;
                           // going back to repack
                           sptr = ii;
                           for (int kk=0; kk<(sptr?2:1); kk++) begin 
                             // build it
                             d2hrsp = d2hrsp_c::type_id::create("d2hrsp");
                             d2hrsp.flitmode = F256;
                             d2hrsp.rsp256.val = 1'b1;
                             void'(d2hrsp.randomize);
                             m2.d2hrsp[kk] = kk<r_nt ? d2hrsp.rsp256 : '0;
                           end
                           void'(m2.pack_slot);
                           // final assign
                           flit.slot[sptr] = m2;
                         end
                         // Step 3: if we can't/don't want to repack, but still 
                         // want to pack lo, create a new slot
                         else if (r_lo && (r_nt==1 || (r_nt==2 && sptr))) begin
                           // ensure tightly packed slotset 
                           attempt_tight_pack;
                           m2 = m2_hbr::type_id::create("m2");
                           {m2.flitmode, m2.slot_num} = {F256, sptr};
                           for (ii=0; ii<(sptr?2:1); ii++) begin 
                             // build it
                             d2hrsp = d2hrsp_c::type_id::create("d2hrsp");
                             d2hrsp.flitmode = F256;
                             d2hrsp.rsp256.val = 1'b1;
                             void'(d2hrsp.randomize);
                             m2.d2hrsp[ii] = ii<r_nt ? d2hrsp.rsp256 : '0;
                           end
                           void'(m2.pack_slot);
                           // final assign
                           flit.slot[sptr] = m2;
                         end
                         // Step 4: else, we have to pack high 
                         else begin
                           // ensure tightly packed slotset 
                           attempt_tight_pack;
                           // build it
                           m3 = m3_hbr::type_id::create("m3");
                           {m3.flitmode, m3.slot_num} = {F256, sptr};
                           for (ii=0; ii<4; ii++) begin
                             d2hrsp = d2hrsp_c::type_id::create("d2hrsp");
                             d2hrsp.flitmode = F256;
                             d2hrsp.rsp256.val = 1'b1;
                             void'(d2hrsp.randomize);
                             // pack it
                             m3.d2hrsp[ii] = ii<r_nt ? d2hrsp.rsp256 : '0;
                           end
                           void'(m3.pack_slot);
                           // final assign
                           flit.slot[sptr] = m3;
                         end
                         // flit tracking
                         smpty[sptr] = 1'b0;
                         cntSS[CCH][cRSP] += r_nt;
                         cntFLIT[CCH][cRSP] += r_nt;
                         // sequence tracking
                         txn_count[CCH][cRSP] += r_nt;
                       end 
                       else r_tt = NONE;
          endcase
        end
        else if (dat_q.size) begin
          r_tt = DATA;
          if (dat_q[0].txn_type == "H2D_DAT") begin
            sptr_str.itoa(sptr);
            `uvm_info(get_type_name, $sformatf("sptr=%2s -> DATA (%0d)",sptr_str,dd), UVM_DEBUG)
            $cast(h2ddat, dat_q[0]);
            dat = f256_data::type_id::create("dat");
            dat.data = h2ddat.dat[128*dd+:128];
            // final assign
            flit.slot[sptr] = dat;
            // flit tracking
            smpty[sptr] = 1'b0;
            // pop it
            if (dd==3) begin
              void'(dat_q.pop_front);
              dd = 0;
            end
            else
              dd++;
          end
          else if (dat_q[0].txn_type == "D2H_DAT") begin
            $cast(d2hdat, dat_q[0]);
            // trailer
            if (dd == 4) begin
              sptr_str.itoa(sptr);
              `uvm_info(get_type_name, $sformatf("sptr=%2s -> TRAILER",sptr_str), UVM_DEBUG)
              trlr = f256_trailer::type_id::create("trlr");
              trlr.data = d2hdat.be;
              // final assign
              flit.slot[sptr] = trlr;
              // flit tracking
              smpty[sptr] = 1'b0;
              // pop it
              void'(dat_q.pop_front);
              dd = 0;
            end
            // data chunk
            else begin
              sptr_str.itoa(sptr);
              `uvm_info(get_type_name, $sformatf("sptr=%2s -> DATA (%0d)",sptr_str,dd), UVM_DEBUG)
              dat = f256_data::type_id::create("dat");
              dat.data = d2hdat.dat[128*dd+:128];
              // final assign
              flit.slot[sptr] = dat;
              // flit tracking
              smpty[sptr] = 1'b0;
              // pop it
              if (dd==3 && !d2hdat.hdr256.bep) begin
                void'(dat_q.pop_front);
                dd = 0;
              end
              else
                dd++;
            end
          end
          else if (dat_q[0].txn_type == "M2S_RWD") begin
            $cast(m2srwd, dat_q[0]);
            // trailer
            if (dd == 4) begin
               sptr_str.itoa(sptr);
              `uvm_info(get_type_name, $sformatf("sptr=%2s -> TRAILER",sptr_str), UVM_DEBUG)
              trlr = f256_trailer::type_id::create("trlr");
              if (m2srwd.hdr256.memop inside {MemWrPtl, MemWrPtlTEE}) begin
                trlr.data[0 +:64] = m2srwd.be;
                trlr.data[64+:32] = {32{m2srwd.hdr256.metafield==ExtMetaState}}&m2srwd.emd;
                trlr.data[96+:32] = '0;                                     
              end
              else 
                trlr.data = m2srwd.emd;
              // final assign
              flit.slot[sptr] = trlr;
              // flit tracking
              smpty[sptr] = 1'b0;
              // pop it
              void'(dat_q.pop_front);
              dd = 0;
            end
            // data chunk
            else begin
              sptr_str.itoa(sptr);
              `uvm_info(get_type_name, $sformatf("sptr=%2s -> DATA (%0d)",sptr_str,dd), UVM_DEBUG)
              dat = f256_data::type_id::create("dat");
              dat.data = m2srwd.dat[128*dd+:128];
              // final assign
              flit.slot[sptr] = dat;
              // flit tracking
              smpty[sptr] = 1'b0;
              // pop it
              if (dd==3 && !m2srwd.hdr256.trp) begin
                void'(dat_q.pop_front);
                dd = 0;
              end
              else
                dd++;
            end
          end
          else if (dat_q[0].txn_type == "S2M_DRS") begin
            $cast(s2mdrs, dat_q[0]);
            // trailer
            if (dd == 4) begin
              sptr_str.itoa(sptr);
              `uvm_info(get_type_name, $sformatf("sptr=%2s -> TRAILER",sptr_str), UVM_DEBUG)
              trlr = f256_trailer::type_id::create("trlr");
              trlr.data = '0;
              s2mdrs_trp = 3'b0;
              for (ii=0; ii<s2mdrs_trp_q[0]; ii++) begin
                $cast(s2mdrs, dat_q[ii]);
                s2mdrs_trp[ii] = s2mdrs.hdr256.trp; 
              end
              if (s2mdrs_trp[0]) begin //1 x x
                $cast(s2mdrs, dat_q[0]);
                trlr.data[0 +:32] = s2mdrs.emd;
                if (s2mdrs_trp[1]) begin //1 1 x
                  $cast(s2mdrs, dat_q[1]);
                  trlr.data[32+:32] = s2mdrs.emd;
                  if (s2mdrs_trp[2]) begin //1 1 1 
                    $cast(s2mdrs, dat_q[2]);
                    trlr.data[64+:32] = s2mdrs.emd;
                  end
                end
                else if (s2mdrs_trp[2]) begin //1 0 1
                  $cast(s2mdrs, dat_q[2]);
                  trlr.data[32+:32] = s2mdrs.emd;
                end
              end
              else if (s2mdrs_trp[1]) begin //0 1 x
                $cast(s2mdrs, dat_q[1]);
                trlr.data[0 +:32] = s2mdrs.emd;
                if (s2mdrs_trp[2]) begin //0 1 1
                  $cast(s2mdrs, dat_q[2]);
                  trlr.data[32+:32] = s2mdrs.emd;
                end
              end
              else begin //0 0 1
                $cast(s2mdrs, dat_q[2]);
                trlr.data[0 +:32] = s2mdrs.emd;
              end
              // final assign
              flit.slot[sptr] = trlr;
              // flit tracking
              smpty[sptr] = 1'b0;
              // pop it
              void'(dat_q.pop_front);
              void'(s2mdrs_trp_q.pop_front);
              dd = 0;
            end
            // data chunk
            else begin
              sptr_str.itoa(sptr);
              `uvm_info(get_type_name, $sformatf("sptr=%2s -> DATA (%0d)",sptr_str,dd), UVM_DEBUG)
              dat = f256_data::type_id::create("dat");
              dat.data = s2mdrs.dat[128*dd+:128];
              // final assign
              flit.slot[sptr] = dat;
              // flit tracking
              smpty[sptr] = 1'b0;
              // pop it
              if (dd==3 && !s2mdrs_trp_q[0]) begin
                void'(dat_q.pop_front);
                void'(s2mdrs_trp_q.pop_front);
                dd = 0;
              end
              else
                dd++;
            end
          end
        end
        // helpful print
        if (did_repack) begin
          `uvm_info(get_type_name, $sformatf("REPACKED: sptr=%0d, txntype=%0s, txn#=%0d", 
                                              sptr, r_tt.name, r_nt), UVM_DEBUG)
        end
        else if (r_tt == NONE) begin
          sptr_str.itoa(sptr);
          `uvm_info(get_type_name, $sformatf("sptr=%2s -> NONE",sptr_str), UVM_DEBUG)
        end
        else if (r_tt != DATA) begin
          msg = flit.slot[sptr]._fmt.name;
          msg = msg.len==8 ? msg.substr(msg.len-2, msg.len-1) : 
                             msg.substr(msg.len-1, msg.len-1);
          msg = !sptr ? {"H", msg} : {"G", msg};
          sptr_str.itoa(sptr);
          `uvm_info(get_type_name, $sformatf("sptr=%2s, slotfmt=%3s, txntype=%0s, txn#=%0d",
                                              sptr_str, msg, r_tt.name, r_nt), UVM_DEBUG)
        end
        // go to next slot
        sptr++;
      end

      // give extended sequences a callback
      pre_pack_flit(flit);

      // now pack it
      flit.pack;
    
      /* Tracking */
      total_flit_count++;
      if (flit.empty_flit)
        empty_flit_count++;
      else
        valid_flit_count++;

      // Decrement total, down to 0
      if (flit_to_send) flit_to_send--;

      // and push it on the q
      flit_q.push_back(flit);

      // If NFI_W==3, send contiguous back to back flits so they are
      // striped across the entire interface: the interface consumes 
      // 12 slots but a flit takes 16 slots.
      if (NFI_W==3) begin
        // Only rand at first flit
        if (flit_in_set++==0)
          void'(std::randomize(r_flits_in_set) with { 
            r_flits_in_set dist {1:=set_odds[1], 2:=set_odds[2], 3:=set_odds[3] };
          });
        // Build out this set of flits more...
        if (flit_to_send!=0 && flit_in_set<r_flits_in_set) begin
          foreach (cntFLIT[ii,jj])
            cntFLITS[ii][jj] += cntFLIT[ii][jj];
          continue;   
        end
        //...or send and start a new set
        else begin 
          flit_in_set = 0;
          cntFLITS = '{default: 0};
        end
      end

      // Call base sequence to actually send the flit(s)
      super.body();

      // Randomize sending some empty cycles
      void'(std::randomize(r_fgap) with {
        r_fgap dist { 0:=gap_odds[0], 1:=gap_odds[1], 2:=gap_odds[2], 3:=gap_odds[3] };
      });
      repeat (r_fgap) begin
        flit_q.push_back(fgap);
        super.body();
      end

    end

  endtask

  // Callback
  virtual function void pre_pack_flit(flit256_txn flit); endfunction

  virtual task post_body();
    `uvm_info(get_type_name, $sformatf("Sequence Summary: %0d Empty Flits + %0d Valid Flits = %0d Total Flits",
                               empty_flit_count, valid_flit_count, total_flit_count), UVM_NONE)
  endtask

  // Try to "shift left" AKA tightly pack transactions. This is required because
  // randomization of r_tt might equal NONE or r_tt might randomize to a txn
  // type that cannot be packed (ergo, same as NONE). NONE as a txn type is 
  // required because we DO want empty slots in the stream for testing.
  virtual function void attempt_tight_pack();
    if ((sptr/4)==0) begin //slotset 0: (exception:0+1 can be not tight)
      if ((sptr%4)==2) begin
        if (smpty[1])
          sptr -= 1;
      end
      else if ((sptr%4)==3) begin
        case (smpty[0:2]) inside
          3'b?11 : sptr -= 2;
          3'b??1 : sptr -= 1;
        endcase
      end
    end
    else if (sptr%4) begin //slotsets 1-3
      if ((sptr%4)==1) begin
        if (smpty[(sptr/4)*4])
          sptr -= 1;
      end
      else if ((sptr%4)==2) begin
        case (smpty[((sptr/4)*4)+:2])
          2'b11 : sptr -= 2;
          2'b01 : sptr -= 1;
        endcase
      end
      else if ((sptr%4)==3) begin
        case (smpty[((sptr/4)*4)+:3])
          3'b111 : sptr -= 3;
          3'b011 : sptr -= 2;
          3'b001 : sptr -= 1;
        endcase
      end
    end
  endfunction

endclass
