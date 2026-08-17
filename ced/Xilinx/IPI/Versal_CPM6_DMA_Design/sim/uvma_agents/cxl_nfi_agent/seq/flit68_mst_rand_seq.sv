class flit68_mst_rand_seq#(parameter NFI_W=3) extends cxl_nfi_mst_in_order_seq#(NFI_W);

  `uvm_object_param_utils(flit68_mst_rand_seq#(NFI_W))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("flit68_mst_rand_seq#(%0d)",NFI_W);
  virtual function string get_type_name(); return type_name; endfunction

  int          flit_to_send; //-1=run forever, else decrement until 0
  int unsigned total_flit_count;
  int unsigned valid_flit_count;
  int unsigned empty_flit_count;
  int unsigned txn_count[1:0][2:0]; //[1:0] = MEM/CCH, [2:0] = REQ/DAT/RSP

  // constants for enum 
  const int cREQ = 0, cDAT = 1, cRSP = 2;

  function new(string name = "flit68_mst_rand_seq");
    super.new(name);
  endfunction

  typedef enum {H2DREQ, H2DRSP, H2DDAT, D2HREQ, D2HRSP, D2HDAT,
                M2SREQ, M2SRWD, S2MNDR, S2MDRS, 
                NONE, DATA} e_txn_type;

  typedef enum {__H0, __H1, __H2, __H3, __H4, __H5,
                      __G1, __G2, __G3, __G4, __G5, __G6} e_fmt_t;
           

  rand e_txn_type r_tt;  //r_tt = "randomized txn type"
  rand bit [2:0]  r_nt;  //r_nt = "randomized number of txns"
  rand e_fmt_t    r_fmt; //r_fmt = "randomized (slot) fmt"; some txns can be packed in several fmts
  rand bit        r_rpk; //r_rpk = "randomized repack" (into a previous slot if possible)

  bit [1:0] flit_in_cycle;    //when NFI_W>1, need to count which flit in cycle
  bit [1:0] r_flits_in_cycle; //when NFI_W>1, need to randomize how many flits in a cycle
  bit [1:0] r_fgap;           //r_fgap = "randomized valid flit to flit gap"

  bit [1:0] sptr;  //sptr = "slot ptr"
  bit [0:3] smpty; //smpty = "slot empty"
  int       cntFLIT[1:0][2:0]; //cntFLIT = "count (of each) txn type in the flit"

  // Default valid flit to flit odds (number of cycles 0-3)
  int gap_odds[0:3] = '{10,3,2,1};

  constraint c_txn_type {
    // Randomize fully or only allow what link partner has credits for
    if (!ignore_avail_credits) {
      // When we get down to or at zero credits, must make sure we don't set the
      // number of txns to exceed the available credits  
      r_tt inside {M2SREQ}        -> (r_nt+cntFLIT[MEM][cREQ])<=p_sequencer.shr.avl_req_credit[MEM];
      r_tt inside {M2SRWD,S2MDRS} -> (r_nt+cntFLIT[MEM][cDAT])<=p_sequencer.shr.avl_dat_credit[MEM];
      r_tt inside {S2MNDR}        -> (r_nt+cntFLIT[MEM][cRSP])<=p_sequencer.shr.avl_rsp_credit[MEM];
      r_tt inside {H2DREQ,D2HREQ} -> (r_nt+cntFLIT[CCH][cREQ])<=p_sequencer.shr.avl_req_credit[CCH];
      r_tt inside {H2DDAT,D2HDAT} -> (r_nt+cntFLIT[CCH][cDAT])<=p_sequencer.shr.avl_dat_credit[CCH];
      r_tt inside {H2DRSP,D2HRSP} -> (r_nt+cntFLIT[CCH][cRSP])<=p_sequencer.shr.avl_rsp_credit[CCH];
    }
    // Don't include txn types if not supported 
    !p_sequencer.cfg.cxl_cch_sup -> !(r_tt inside {[H2DREQ:D2HDAT]});
    !p_sequencer.cfg.cxl_mem_sup -> !(r_tt inside {[M2SREQ:S2MDRS]});
    // Must match direction
    p_sequencer.cfg.dir==H2C -> r_tt inside {[H2DREQ:H2DDAT],[M2SREQ:M2SRWD], NONE};
    p_sequencer.cfg.dir==C2H -> r_tt inside {[D2HREQ:D2HDAT],[S2MNDR:S2MDRS], NONE};
    // For the last txn
    !flit_to_send -> r_tt==NONE;
    // We never randomize to a data chunk, this is for internal tracking
    r_tt != DATA;
    // Solve the txn_type first
    solve r_tt before r_nt;
    solve r_tt before r_fmt;
    solve r_tt before r_rpk;
    solve r_nt before r_fmt;
    // general
    if (r_tt==NONE) r_nt==0;
    else            r_nt!=0;
    // H-Slot/G-Slot max txn limitations
    r_tt==M2SREQ -> r_nt == 1;
    r_tt==M2SRWD -> r_nt == 1;
    r_tt==S2MDRS -> r_nt <= (p_sequencer.cfg.mdh_disable ? 1 : (!sptr ? 2 : 3));
    r_tt==S2MNDR -> r_nt <= 2;
    r_tt==H2DREQ -> r_nt == 1;
    r_tt==H2DDAT -> r_nt <= (p_sequencer.cfg.mdh_disable ? 1 : 4);
    r_tt==H2DRSP -> r_nt <= (!sptr ? 2 : 4);
    r_tt==D2HREQ -> r_nt == 1;
    r_tt==D2HDAT -> r_nt <= (p_sequencer.cfg.mdh_disable ? 1 : 4);
    r_tt==D2HRSP -> r_nt <= 2;
    // Slot formats
    r_tt==M2SREQ -> r_fmt == (!sptr ? __H5 : __G4);
    r_tt==M2SRWD -> r_fmt == (!sptr ? __H4 : __G5);
    if (r_tt==S2MDRS) {
      if (!sptr && r_nt==2) r_fmt == __H5;
      else if (!sptr)       r_fmt == __H3;
      else if (r_nt>1)      r_fmt == __G6;
      else                  r_fmt == __G4;
    }
    if (r_tt==S2MNDR) {
      if (!sptr && r_nt==2) r_fmt == __H4;
      else if (!sptr)       r_fmt inside {__H0, __H3};
      else                  r_fmt inside {__G4, __G5};
    }
    if (r_tt==H2DREQ) {
      if (!sptr) r_fmt inside {__H0, __H2};
      else       r_fmt == __G2;
    }
    if (r_tt==H2DDAT) {
      if (!sptr && r_nt==1) r_fmt inside {__H1, __H2};
      else if (!sptr)       r_fmt == __H3;
      else if (r_nt==1)     r_fmt inside {__G2, __G4};
      else                  r_fmt == __G3;
    }
    if (r_tt==H2DRSP) {
      if (!sptr && r_nt==2) r_fmt == __H1;
      else if (!sptr)       r_fmt == __H0;
      else if (r_nt>1)      r_fmt == __G1;
      else                  r_fmt inside {__G1, __G2, __G3, __G5};
    }
    if (r_tt==D2HREQ) {
      if (!sptr) r_fmt == __H1;
      else       r_fmt inside {__G1, __G2};
    }
    if (r_tt==D2HDAT) {
      if (!sptr && r_nt==1) r_fmt inside {__H0, __H1};
      else if (!sptr)       r_fmt == __H2;
      else if (r_nt==1)     r_fmt == __G2;
      else                  r_fmt == __G3;
    }
    if (r_tt==D2HRSP) {
      if (!sptr && r_nt==2) r_fmt == __H0;
      else if (!sptr)       r_fmt inside {__H0, __H2};
      else if (r_nt>1)      r_fmt == __G1;
      else                  r_fmt inside {__G1, __G2};
    }
  }

  // This task will build one flit (equiv. to one slotset) at a time and send it 
  virtual task body();
    int         split_flit;
    int         split_slot;
    bit         do_split;
    bit         split_32B_disable;
    string      msg; 
    int         max_msg_flit[1:0][2:0];
    int         may_repack;
    bit         did_repack;
    int         ii;
    int         dd;
    base_txn    dat_q[$:4];
    base_txn    dat_split;
    flit68_txn  fgap;
    // Transactions we will randomize to
    h2dreq_c    h2dreq;   d2hreq_c    d2hreq;
    h2ddat_c    h2ddat;   d2hdat_c    d2hdat;
    h2drsp_c    h2drsp;   d2hrsp_c    d2hrsp;
    m2sreq_c    m2sreq;   s2mndr_c    s2mndr;
    m2srwd_c    m2srwd;   s2mdrs_c    s2mdrs;
    // Transactions will pack into slots
                          g0be_f68    g0be;
    h0_f68      h0;       g0_f68      g0; 
    h1_f68      h1;       g1_f68      g1;
    h2_f68      h2;       g2_f68      g2;
    h3_f68      h3;       g3_f68      g3;
    h4_f68      h4;       g4_f68      g4;
    h5_f68      h5;       g5_f68      g5;
    h6_f68      h6;       g6_f68      g6;

    // Flit that we'll pack into
    flit68_txn flit = flit68_txn::type_id::create("flit");
    
    // constant
    max_msg_flit[MEM][cREQ] = p_sequencer.cfg.dir==H2C ? 2 : 0;
    max_msg_flit[MEM][cDAT] = p_sequencer.cfg.dir==H2C ? 1 : 3;
    max_msg_flit[MEM][cRSP] = p_sequencer.cfg.dir==H2C ? 0 : 2;
    max_msg_flit[CCH][cREQ] = p_sequencer.cfg.dir==H2C ? 2 : 4;
    max_msg_flit[CCH][cDAT] = p_sequencer.cfg.dir==H2C ? 4 : 4;
    max_msg_flit[CCH][cRSP] = p_sequencer.cfg.dir==H2C ? 4 : 2;

    // empty NFI interface
    fgap = flit68_txn::type_id::create("fgap");
    fgap.gap = 1'b1;

    // Initial setup (once)
    flit.flitmode = F68;
    flit.dir      = p_sequencer.cfg.dir;

    // Configuration
    split_32B_disable = p_sequencer.cfg.split_32B_disable;

    // Control run length
    while (flit_to_send || flit_to_send==-1 || flit.rollover || flit.rollover_be || dat_split!=null) begin

      // Initialize each flit
      sptr  = 0;
      smpty = '1;
      flit = flit.new_flit;
      cntFLIT = '{default: 0};

      `uvm_info(get_type_name, $sformatf("Building Flit %0d",total_flit_count), UVM_NONE)

      // If we have the upper chunk of a split flit remaining to send and we are trying
      // to end the sequence, accelerate that ASAP
      if (!flit_to_send && dat_split!=null && split_flit!=total_flit_count)
        split_flit = total_flit_count;

      // Randomize txns and pack them until a whole flit is packed
      // Must be careful to pack txns tightly and not violate max messages rules
      while (1) begin
        did_repack = 1'b0;
        do_split   = 1'b0;
        split_slot = -1;
        // detect and pack an ADF (4 data chunks OR 3 data chunks+1 BE) 
        if ((flit.pRollover+flit.pRollover_be)>=4) begin
          r_tt = DATA;
          // if there's a standing split txn and it's randomized to land on an
          // adf, push it forward to the next flit
          if (dat_split!=null && total_flit_count==split_flit)
            split_flit++;
          if (dat_q[0].txn_type == "H2D_DAT") begin
            $cast(h2ddat, dat_q[0]);
            `uvm_info(get_type_name, $sformatf("sptr=%0d -> DATA (%0d)",sptr,dd), UVM_NONE)
            g0      = g0_f68::type_id::create("g0");
            g0.dir  = flit.dir;
            g0.data = h2ddat.dat[128*dd+:128];
            // final assign
            flit.slot[sptr] = g0;
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
            // byte enable slot
            if (d2hdat.be!='1 && sptr==3 && flit.pRollover==3) begin
              `uvm_info(get_type_name, $sformatf("sptr=%0d -> DATA (BEN)",sptr), UVM_NONE)
              g0be      = g0be_f68::type_id::create("g0be");
              g0be.dir  = flit.dir;
              g0be.data = d2hdat.be;
              // final assign
              flit.slot[sptr] = g0be;
              // flit tracking
              smpty[sptr] = 1'b0;
              // pop it
              void'(dat_q.pop_front);
              dd = 0;
            end
            // data slot
            else begin
              `uvm_info(get_type_name, $sformatf("sptr=%0d -> DATA (%0d)",sptr,dd), UVM_NONE)
              g0      = g0_f68::type_id::create("g0");
              g0.dir  = flit.dir;
              g0.data = d2hdat.dat[128*dd+:128];
              // final assign
              flit.slot[sptr] = g0;
              // flit tracking
              smpty[sptr] = 1'b0;
              // pop it
              if (dd==3 && d2hdat.be!='1) begin
                void'(dat_q.pop_front);
                dd = 0;
              end
              else
                dd++;
            end
          end
          else if (dat_q[0].txn_type == "M2S_RWD") begin
            $cast(m2srwd, dat_q[0]);
            // byte enable slot
            if (m2srwd.be!='1 && sptr==3 && flit.pRollover==3) begin
              `uvm_info(get_type_name, $sformatf("sptr=%0d -> DATA (BEN)",sptr), UVM_NONE)
              g0be      = g0be_f68::type_id::create("g0be");
              g0be.dir  = flit.dir;
              g0be.data = m2srwd.be;
              // final assign
              flit.slot[sptr] = g0be;
              // flit tracking
              smpty[sptr] = 1'b0;
              // pop it
              void'(dat_q.pop_front);
              dd = 0;
            end
            // data slot
            else begin
              `uvm_info(get_type_name, $sformatf("sptr=%0d -> DATA (%0d)",sptr,dd), UVM_NONE)
              g0      = g0_f68::type_id::create("g0");
              g0.dir  = flit.dir;
              g0.data = m2srwd.dat[128*dd+:128];
              // final assign
              flit.slot[sptr] = g0;
              // flit tracking
              smpty[sptr] = 1'b0;
              // pop it
              if (dd==3 && m2srwd.be=='1) begin
                void'(dat_q.pop_front);
                dd = 0;
              end
              else
                dd++;
            end
          end
          else if (dat_q[0].txn_type == "S2M_DRS") begin
            $cast(s2mdrs, dat_q[0]);
            `uvm_info(get_type_name, $sformatf("sptr=%0d -> DATA (%0d)",sptr,dd), UVM_NONE)
            g0      = g0_f68::type_id::create("g0");
            g0.dir  = flit.dir;
            g0.data = s2mdrs.dat[128*dd+:128];
            // final assign
            flit.slot[sptr] = g0;
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
        end
        // start new (txns) 
        else if (!sptr || !dat_q.size) begin
          // randomize first
          void'(this.randomize);
          // Handle 32B chunks that need to be packed; randomly
          // set the slot to be packed in so that the header is
          // not always packed in H-Slot, which would always happen
          // if you just match the flit
          if (dat_split!=null && total_flit_count==split_flit && 
              split_slot==-1 && !sptr) 
          begin
            // Slots 1-3 are OR will be taken, put the header in Slot 0
            if ((r_tt inside {H2DDAT, D2HDAT, S2MDRS}) || ((flit.pRollover+flit.pRollover_be)==3)) begin
              split_slot = 0;
            end
            // There may be some rollover, put the header in Slot 0 or any available
            else begin
              void'(std::randomize(split_slot) with { 
                split_slot inside {0,[1+flit.pRollover+flit.pRollover_be:3]}; 
              });
            end
          end
          // Make sure we don't accidentally insert a data txn if this is the split flit,
          // which would then disallow us from inserting the split txn
          if (total_flit_count==split_flit && signed'(sptr)<split_slot)
            void'(this.randomize with {!(r_tt inside {M2SRWD, S2MDRS, H2DDAT, D2HDAT});});
          // Mark condition when we can insert the split txn
          else if (total_flit_count==split_flit && sptr==split_slot) begin
            do_split = 1'b1;
            r_nt     = 1;
            case (dat_split.txn_type)
              "H2D_DAT" : begin
                            r_tt = H2DDAT;
                            if (!sptr)
                              void'(randomize(r_fmt) with {r_fmt inside {__H1, __H2};});
                            else
                              void'(randomize(r_fmt) with {r_fmt inside {__G2, __G4};});
                          end
              "D2H_DAT" : begin
                            r_tt = D2HDAT;
                            if (!sptr)
                              void'(randomize(r_fmt) with {r_fmt inside {__H0, __H1};});
                            else
                              r_fmt = __G2;
                          end
              "S2M_DRS" : begin
                            r_tt  = S2MDRS;
                            r_fmt = !sptr ? __H3 : __G4;
                          end
            endcase
          end
          // Create new txns based on txn type
          case (r_tt) inside
            M2SREQ : if (cntFLIT[MEM][cREQ]<max_msg_flit[MEM][cREQ]) begin
                       // ensure tightly packed slotset
                       attempt_tight_pack;
                       // pack it 
                       case (r_fmt)
                         __H5 : 
                         begin
                           h5 = h5_f68::type_id::create("h5");
                           h5.create_objects(flit.dir, 1'b1);
                           void'(h5.randomize);
                           void'(h5.pack_slot);
                           // final assign
                           flit.slot[sptr] = h5;
                         end
                         __G4 : 
                         begin
                           g4 = g4_f68::type_id::create("g4");
                           g4.create_objects(flit.dir, 1'b1);
                           void'(g4.randomize);
                           void'(g4.pack_slot);
                           // final assign
                           flit.slot[sptr] = g4;
                         end
                       endcase
                       // flit tracking
                       smpty[sptr] = 1'b0;
                       cntFLIT[MEM][cREQ] += r_nt;
                       // sequence tracking
                       txn_count[MEM][cREQ] += r_nt;
                     end
                     else r_tt = NONE;
            M2SRWD : begin
                       // build it
                       m2srwd = m2srwd_c::type_id::create("m2srwd");
                       m2srwd.flitmode = F68;
                       m2srwd.hdr68.val = 1'b1;
                       void'(m2srwd.randomize);
                       dat_q.push_back(m2srwd);
                       // ensure tightly packed slotset
                       attempt_tight_pack;
                       // the specific time we even CAN repack:
                       //   sptr=[2,3], previous slot=G5
                       may_repack = 0;
                       // Step 1: let's see if we even CAN repack
                       if (sptr>1 && flit.slot[sptr-1]!=null && 
                           flit.slot[sptr-1]._fmt==_G5) begin
                         $cast(g5, flit.slot[sptr-1]);
                         // see if M2SRWD is open
                         may_repack = !g5.m2srwd_hdr.val;
                       end
                       // Step 2: if we can repack and that's selected, do that
                       if (may_repack && r_rpk) begin
                         did_repack = 1'b1;
                         // going back to repack
                         g5.m2srwd_h = m2srwd;
                         void'(g5.pack_slot);
                         // final assign
                         flit.slot[--sptr] = g5;
                       end
                       // Step 3: if we can't/don't want to repack then create
                       // the new slot
                       else begin
                         case (r_fmt)
                           __H4 :
                           begin
                             h4 = h4_f68::type_id::create("h4");
                             h4.m2srwd_h = m2srwd;
                             void'(h4.randomize);
                             void'(h4.pack_slot);
                             // final assign
                             flit.slot[sptr] = h4;
                           end
                           __G5 :
                           begin
                             g5 = g5_f68::type_id::create("g5");
                             g5.m2srwd_h = m2srwd;
                             g5.h2drsp   = '0;
                             void'(g5.pack_slot);
                             // final assign
                             flit.slot[sptr] = g5;
                           end
                         endcase
                       end
                       // flit tracking
                       smpty[sptr] = 1'b0;
                       cntFLIT[MEM][cDAT] += r_nt;
                       // sequence tracking
                       txn_count[MEM][cDAT] += r_nt;
                     end
            S2MNDR : if (cntFLIT[MEM][cRSP]<max_msg_flit[MEM][cRSP]) begin
                       // r_nt + current count could exceed max; cap it at max
                       if ((cntFLIT[MEM][cRSP]+r_nt)>max_msg_flit[MEM][cRSP])
                         r_nt = max_msg_flit[MEM][cRSP]-cntFLIT[MEM][cRSP];
                       // ensure tightly packed slotset
                       attempt_tight_pack;
                       // the specific time we even CAN repack:
                       //   sptr=1, previous slot=H0, r_nt=1
                       may_repack = 0; 
                       // Step 1: let's see if we even CAN repack
                       if (sptr==1 && flit.slot[0]!=null && 
                           flit.slot[0]._fmt==_H0 && r_nt==1) 
                       begin
                         $cast(h0, flit.slot[0]);
                         // see if S2MNDR is open
                         may_repack = !h0.s2mndr.val;
                       end
                       // Step 2: if we can repack and that's selected, do that
                       if (may_repack && r_rpk) begin
                         did_repack = 1'b1;
                         // build it
                         s2mndr = s2mndr_c::type_id::create("s2mndr");
                         s2mndr.flitmode = F68;
                         s2mndr.ndr68.val = 1'b1;
                         void'(s2mndr.randomize);
                         // going back to repack
                         sptr = 0;
                         h0.s2mndr = s2mndr.ndr68;
                         void'(h0.pack_slot);
                         // final assign
                         flit.slot[sptr] = h0;
                       end
                       // Step 3: if we can't/don't want to repack then create
                       // the new slot
                       else begin
                         case (r_fmt)
                           __H0 :
                           begin
                             // build it
                             s2mndr = s2mndr_c::type_id::create("s2mndr");
                             s2mndr.flitmode = F68;
                             s2mndr.ndr68.val = 1'b1;
                             void'(s2mndr.randomize);
                             // pack it
                             h0 = h0_f68::type_id::create("h0");
                             h0.dir = flit.dir;
                             h0.s2mndr = s2mndr.ndr68;
                             h0.d2hrsp = {'0, '0};
                             h0.d2hdat_hdr = '0;
                             void'(h0.randomize);
                             void'(h0.pack_slot);
                             // final assign
                             flit.slot[sptr] = h0;
                           end
                           __H3 :
                           begin
                             // build it
                             s2mndr = s2mndr_c::type_id::create("s2mndr");
                             s2mndr.flitmode = F68;
                             s2mndr.ndr68.val = 1'b1;
                             void'(s2mndr.randomize);
                             // pack it
                             h3 = h3_f68::type_id::create("h3");
                             h3.dir = flit.dir;
                             h3.s2mndr = s2mndr.ndr68;
                             h3.s2mdrs_hdr = '0;
                             void'(h3.randomize);
                             void'(h3.pack_slot);
                             // final assign
                             flit.slot[sptr] = h3;
                           end
                           __H4 :
                           begin
                             // build it
                             h4 = h4_f68::type_id::create("h4");
                             h4.dir = flit.dir;
                             for (ii=0; ii<2; ii++) begin
                               s2mndr = s2mndr_c::type_id::create("s2mndr");
                               s2mndr.flitmode = F68;
                               s2mndr.ndr68.val = 1'b1;
                               void'(s2mndr.randomize);
                               // pack it
                               h4.s2mndr[ii] = ii<r_nt ? s2mndr.ndr68 : '0;
                             end
                             void'(h4.randomize);
                             void'(h4.pack_slot);
                             // final assign
                             flit.slot[sptr] = h4;
                           end
                           __G4 :
                           begin
                             // build it
                             g4 = g4_f68::type_id::create("g4");
                             g4.dir = flit.dir;
                             for (ii=0; ii<2; ii++) begin
                               s2mndr = s2mndr_c::type_id::create("s2mndr");
                               s2mndr.flitmode = F68;
                               s2mndr.ndr68.val = 1'b1;
                               void'(s2mndr.randomize);
                               // pack it
                               g4.s2mndr[ii] = ii<r_nt ? s2mndr.ndr68 : '0;
                             end
                             g4.s2mdrs_hdr = '0;
                             void'(g4.pack_slot);
                             // final assign
                             flit.slot[sptr] = g4;
                           end
                           __G5 :
                           begin
                             // build it
                             g5 = g5_f68::type_id::create("g5");
                             g5.dir = flit.dir;
                             for (ii=0; ii<2; ii++) begin
                               s2mndr = s2mndr_c::type_id::create("s2mndr");
                               s2mndr.flitmode = F68;
                               s2mndr.ndr68.val = 1'b1;
                               void'(s2mndr.randomize);
                               // pack it
                               g5.s2mndr[ii] = ii<r_nt ? s2mndr.ndr68 : '0;
                             end
                             void'(g5.pack_slot);
                             // final assign
                             flit.slot[sptr] = g5;
                           end
                         endcase
                         // flit tracking
                         smpty[sptr] = 1'b0;
                         cntFLIT[MEM][cRSP] += r_nt;
                         // sequence tracking
                         txn_count[MEM][cRSP] += r_nt;
                       end
                     end
                     else r_tt = NONE;
            S2MDRS : begin
                       // ensure tightly packed slotset
                       attempt_tight_pack;
                       // build it; if it's split txn upper chunk, use that
                       if (do_split) begin
                         $cast(s2mdrs, dat_split);
                         // "remove" the split txn and insert it as a
                         // regular txn on the data queue
                         s2mdrs.chunkval = 1;
                         dat_split = null;
                       end
                       else begin
                         s2mdrs = s2mdrs_c::type_id::create("s2mdrs"); 
                         s2mdrs.flitmode = F68;
                         s2mdrs.hdr68.val = 1'b1;
                         // only allow one outstanding split txn
                         if (dat_split != null)
                           s2mdrs.txfer_64B = 1'b1;
                         // disallow split txn when trying to end sequence or
                         // global configuration disables it
                         else if (!flit_to_send || split_32B_disable)
                           s2mdrs.txfer_64B = 1'b1;
                         // Now randomize
                         void'(s2mdrs.randomize);
                         // Choose when to send upper chunk if split
                         if (!s2mdrs.txfer_64B)
                           split_flit = total_flit_count + $urandom_range(1,10); 
                       end
                       // the specific time we even CAN repack:
                       //   sptr=1,     previous slot=H3, r_nt=1
                       //   sptr=[2,3], previous slot=G4, r_nt=1
                       may_repack = 0; 
                       // Step 1: let's see if we even CAN repack
                       if (sptr==1 && flit.slot[0]!=null && 
                           flit.slot[0]._fmt==_H3 && r_nt==1) 
                       begin
                         $cast(h3, flit.slot[0]);
                         // see if S2MDRS is open
                         may_repack = !h3.s2mdrs_hdr.val;
                       end
                       else if (sptr>1 && flit.slot[sptr-1]!=null && 
                                flit.slot[sptr-1]._fmt==_G4 && r_nt==1) 
                       begin
                         $cast(g4, flit.slot[sptr-1]);
                         // see if S2MDRS is open
                         may_repack = !g4.s2mdrs_hdr.val;
                       end
                       // Step 2: if we can repack and that's selected, do that
                       if (may_repack && r_rpk) begin
                         did_repack = 1'b1;
                         if (!(--sptr)) begin
                           h3.s2mdrs_h = s2mdrs;
                           void'(h3.pack_slot);
                           // final assign
                           flit.slot[sptr] = h3;
                         end
                         else begin
                           g4.s2mdrs_h = s2mdrs;
                           void'(g4.pack_slot);
                           // final assign
                           flit.slot[sptr] = g4;
                         end
                         // push onto q or split object
                         if (s2mdrs.txfer_64B)
                           dat_q.push_back(s2mdrs);
                         else if (!s2mdrs.chunkval)
                           dat_split = s2mdrs;
                       end
                       // Step 3: if we can't/don't want to repack then create
                       // the new slot
                       else begin
                         case (r_fmt)
                           __H3 :
                           begin
                             // pack it
                             h3 = h3_f68::type_id::create("h3");
                             h3.dir = flit.dir;
                             h3.s2mdrs_h = s2mdrs;
                             h3.s2mndr = '0;
                             void'(h3.randomize);
                             void'(h3.pack_slot);
                             // final assign
                             flit.slot[sptr] = h3;
                             // push onto q or split object
                             if (s2mdrs.txfer_64B)
                               dat_q.push_back(s2mdrs);
                             else if (!s2mdrs.chunkval)
                               dat_split = s2mdrs;
                           end
                           __H5 :
                           begin
                             // pack it
                             h5 = h5_f68::type_id::create("h5");
                             h5.dir = flit.dir;
                             for (ii=0; ii<2; ii++) begin
                               // build it
                               s2mdrs = s2mdrs_c::type_id::create("s2mdrs");
                               s2mdrs.flitmode = F68;
                               s2mdrs.hdr68.val = 1'b1;
                               s2mdrs.txfer_64B = 1'b1;
                               void'(s2mdrs.randomize);
                               h5.s2mdrs_h[ii] = s2mdrs;
                               // push onto q
                               dat_q.push_back(s2mdrs);
                             end
                             void'(h5.randomize);
                             void'(h5.pack_slot);
                             // final assign
                             flit.slot[sptr] = h5;
                           end
                           __G4 :
                           begin
                             // pack it
                             g4 = g4_f68::type_id::create("g4");
                             g4.dir = flit.dir;
                             g4.s2mdrs_h = s2mdrs;
                             g4.s2mndr = {'0, '0};
                             void'(g4.randomize);
                             void'(g4.pack_slot);
                             // final assign
                             flit.slot[sptr] = g4;
                             // push onto q or split object
                             if (s2mdrs.txfer_64B)
                               dat_q.push_back(s2mdrs);
                             else if (!s2mdrs.chunkval)
                               dat_split = s2mdrs;
                           end
                           __G6 :
                           begin
                             // pack it
                             g6 = g6_f68::type_id::create("g6");
                             g6.dir = flit.dir;
                             for (ii=0; ii<3; ii++) begin
                               // build it
                               s2mdrs = s2mdrs_c::type_id::create("s2mdrs");
                               s2mdrs.flitmode = F68;
                               s2mdrs.hdr68.val = 1'b1;
                               s2mdrs.txfer_64B = 1'b1;
                               void'(s2mdrs.randomize);
                               if (ii<r_nt) begin
                                 g6.s2mdrs_h[ii] = s2mdrs;
                                 // push onto q
                                 dat_q.push_back(s2mdrs);
                               end
                               else
                                 g6.s2mdrs_hdr[ii] = '0;
                             end
                             void'(g6.randomize);
                             void'(g6.pack_slot);
                             // final assign
                             flit.slot[sptr] = g6;
                           end
                         endcase
                         // flit tracking
                         smpty[sptr] = 1'b0;
                         cntFLIT[MEM][cDAT] += r_nt;
                         // sequence tracking
                         txn_count[MEM][cDAT] += r_nt;
                       end
                     end
            H2DREQ : if (cntFLIT[CCH][cREQ]<max_msg_flit[CCH][cREQ]) begin
                       // ensure tightly packed slotset
                       attempt_tight_pack;
                       // build it
                       h2dreq = h2dreq_c::type_id::create("h2dreq");
                       h2dreq.flitmode = F68;
                       h2dreq.req68.val = 1'b1;
                       void'(h2dreq.randomize);
                       // the specific time we even CAN repack:
                       //   sptr=1,     previous slot=H0
                       //   sptr=[2,3], previous slot=G2
                       may_repack = 0; 
                       // Step 1: let's see if we even CAN repack
                       if (sptr==1 && flit.slot[0]!=null && 
                           flit.slot[0]._fmt==_H0)
                       begin
                         $cast(h0, flit.slot[0]);
                         // see if H2DREQ is open
                         may_repack = !h0.h2dreq.val;
                       end
                       else if (sptr>1 && flit.slot[sptr-1]!=null && 
                                flit.slot[sptr-1]._fmt==_G2)
                       begin
                         $cast(g2, flit.slot[sptr-1]);
                         // see if H2DREQ is open
                         may_repack = !g2.h2dreq.val;
                       end
                       // Step 2: if we can repack and that's selected, do that
                       if (may_repack && r_rpk) begin
                         did_repack = 1'b1;
                         if (!(--sptr)) begin
                           h0.h2dreq = h2dreq.req68;
                           void'(h0.pack_slot);
                           // final assign
                           flit.slot[sptr] = h0;
                         end
                         else begin
                           g2.h2dreq = h2dreq.req68;
                           void'(g2.pack_slot);
                           // final assign
                           flit.slot[sptr] = g2;
                         end
                       end
                       // Step 3: if we can't/don't want to repack then create
                       // the new slot
                       else begin
                         case (r_fmt)
                           __H0 : 
                           begin
                             h0 = h0_f68::type_id::create("h0");
                             h0.dir = flit.dir;
                             h0.h2dreq = h2dreq.req68;
                             h0.h2drsp = '0;
                             void'(h0.randomize);
                             void'(h0.pack_slot);
                             // final assign
                             flit.slot[sptr] = h0;
                           end
                           __H2 : 
                           begin
                             h2 = h2_f68::type_id::create("h2");
                             h2.dir = flit.dir;
                             h2.h2dreq     = h2dreq.req68;
                             h2.h2ddat_hdr = '0;
                             void'(h2.randomize);
                             void'(h2.pack_slot);
                             // final assign
                             flit.slot[sptr] = h2;
                           end
                           __G2 : 
                           begin
                             g2 = g2_f68::type_id::create("g2");
                             g2.dir = flit.dir;
                             g2.h2dreq     = h2dreq.req68;
                             g2.h2ddat_hdr = '0;
                             g2.h2drsp     = '0;
                             void'(g2.pack_slot);
                             // final assign
                             flit.slot[sptr] = g2;
                           end
                         endcase
                       end
                       // flit tracking
                       smpty[sptr] = 1'b0;
                       cntFLIT[CCH][cREQ] += r_nt;
                       // sequence tracking
                       txn_count[CCH][cREQ] += r_nt;
                     end
                     else r_tt = NONE;
            H2DDAT : begin
                       // ensure tightly packed slotset
                       attempt_tight_pack;
                       // build it; if it's split txn upper chunk, use that
                       if (do_split) begin
                         $cast(h2ddat, dat_split);
                         // "remove" the split txn and insert it as a
                         // regular txn on the data queue
                         h2ddat.hdr68.ch = 1;
                         dat_split = null;
                       end
                       else begin
                         h2ddat = h2ddat_c::type_id::create("h2ddat");
                         h2ddat.flitmode = F68;
                         h2ddat.hdr68.val = 1'b1;
                         // only allow one outstanding split txn
                         if (dat_split != null)
                           h2ddat.txfer_64B = 1'b1;
                         // disallow split txn when trying to end sequence or
                         // global configuration disables it
                         else if (!flit_to_send || split_32B_disable)
                           h2ddat.txfer_64B = 1'b1;
                         // Now randomize
                         void'(h2ddat.randomize);
                         // Send low chunk now
                         if (!h2ddat.txfer_64B)
                           h2ddat.hdr68.ch = 1'b0;
                       end
                       // the specific time we even CAN repack:
                       //   sptr=1,     previous slot=[H1,H2], r_nt=1
                       //   sptr=[2,3], previous slot=[G2,G4], r_nt=1
                       //   sptr=[2,3], previous slot=G3
                       may_repack = 0; 
                       // Step 1: let's see if we even CAN repack
                       if (sptr==1 && flit.slot[0]!=null && 
                           flit.slot[0]._fmt==_H1 && r_nt==1)
                       begin
                         $cast(h1, flit.slot[0]);
                         // see if H2DDAT is open
                         may_repack = !h1.h2ddat_hdr.val;
                       end
                       else if (sptr==1 && flit.slot[0]!=null && 
                           flit.slot[0]._fmt==_H2 && r_nt==1)
                       begin
                         $cast(h2, flit.slot[0]);
                         // see if H2DDAT is open
                         may_repack = !h2.h2ddat_hdr.val;
                       end
                       else if (sptr>1 && flit.slot[sptr-1]!=null && 
                                flit.slot[sptr-1]._fmt==_G2 && r_nt==1)
                       begin
                         $cast(g2, flit.slot[sptr-1]);
                         // see if H2DDAT is open
                         may_repack = !g2.h2ddat_hdr.val;
                       end
                       else if (sptr>1 && flit.slot[sptr-1]!=null && 
                                flit.slot[sptr-1]._fmt==_G4 && r_nt==1)
                       begin
                         $cast(g4, flit.slot[sptr-1]);
                         // see if H2DDAT is open
                         may_repack = !g4.h2ddat_hdr.val;
                       end
                       else if (sptr>1 && flit.slot[sptr-1]!=null && 
                                flit.slot[sptr-1]._fmt==_G3)
                       begin
                         $cast(g3, flit.slot[sptr-1]);
                         // see if H2DDAT is open
                         may_repack = !g3.h2ddat_hdr[0].val;
                       end
                       // Step 2: if we can repack and that's selected, do that
                       if (may_repack && r_rpk) begin
                         did_repack = 1'b1;
                         if (!(--sptr)) begin
                           if (flit.slot[sptr]._fmt==_H1) begin
                             h1.h2ddat_h = h2ddat;
                             void'(h1.pack_slot);
                             // final assign
                             flit.slot[sptr] = h1;
                           end
                           else begin
                             h2.h2ddat_h = h2ddat;
                             void'(h2.pack_slot);
                             // final assign
                             flit.slot[sptr] = h2;
                           end
                           // push onto q or split object
                           if (h2ddat.txfer_64B)
                             dat_q.push_back(h2ddat);
                           else if (!h2ddat.hdr68.ch)
                             dat_split = h2ddat;
                         end
                         else if (flit.slot[sptr]._fmt==_G2) begin
                           g2.h2ddat_h = h2ddat;
                           void'(g2.pack_slot);
                           // final assign
                           flit.slot[sptr] = g2;
                           // push onto q or split object
                           if (h2ddat.txfer_64B)
                             dat_q.push_back(h2ddat);
                           else if (!h2ddat.hdr68.ch)
                             dat_split = h2ddat;
                         end
                         else if (flit.slot[sptr]._fmt==_G4) begin
                           g4.h2ddat_h = h2ddat;
                           void'(g4.pack_slot);
                           // final assign
                           flit.slot[sptr] = g4;
                           // push onto q or split object
                           if (h2ddat.txfer_64B)
                             dat_q.push_back(h2ddat);
                           else if (!h2ddat.hdr68.ch)
                             dat_split = h2ddat;
                         end
                         else begin //_G3
                           for (ii=0; ii<r_nt; ii++) begin
                             h2ddat = h2ddat_c::type_id::create("h2ddat");
                             h2ddat.flitmode  = F68;
                             h2ddat.hdr68.val = 1'b1;
                             h2ddat.txfer_64B = 1'b1;
                             void'(h2ddat.randomize);
                             // pack it
                             g3.h2ddat_h[ii] = h2ddat;
                             // push onto q
                             dat_q.push_back(h2ddat);
                           end
                           // final assign
                           flit.slot[sptr] = g3;
                         end
                       end
                       // Step 3: if we can't/don't want to repack then create
                       // the new slot
                       else begin
                         case (r_fmt)
                           __H1 : 
                           begin
                             h1 = h1_f68::type_id::create("h1");
                             h1.dir = flit.dir;
                             h1.h2ddat_h = h2ddat;
                             h1.h2drsp = {'0, '0};
                             void'(h1.randomize);
                             void'(h1.pack_slot);
                             // final assign
                             flit.slot[sptr] = h1;
                             // push onto q or split object
                             if (h2ddat.txfer_64B)
                               dat_q.push_back(h2ddat);
                             else if (!h2ddat.hdr68.ch)
                               dat_split = h2ddat;
                           end
                           __H2 : 
                           begin
                             h2 = h2_f68::type_id::create("h2");
                             h2.dir = flit.dir;
                             h2.h2dreq   = '0;
                             h2.h2ddat_h = h2ddat;
                             void'(h2.randomize);
                             void'(h2.pack_slot);
                             // final assign
                             flit.slot[sptr] = h2;
                             // push onto q or split object
                             if (h2ddat.txfer_64B)
                               dat_q.push_back(h2ddat);
                             else if (!h2ddat.hdr68.ch)
                               dat_split = h2ddat;
                           end
                           __H3 : 
                           begin
                             h3 = h3_f68::type_id::create("h3");
                             h3.create_objects(flit.dir, 4'hF>>(4-r_nt));
                             void'(h3.randomize);
                             void'(h3.pack_slot);
                             // final assign
                             flit.slot[sptr] = h3;
                             // push onto q
                             for (ii=0; ii<r_nt; ii++)
                               dat_q.push_back(h3.h2ddat_h[ii]);
                           end
                           __G2 : 
                           begin
                             g2 = g2_f68::type_id::create("g2");
                             g2.dir = flit.dir;
                             g2.h2dreq   = '0;
                             g2.h2ddat_h = h2ddat;
                             g2.h2drsp   = '0;
                             void'(g2.pack_slot);
                             // final assign
                             flit.slot[sptr] = g2;
                             // push onto q or split object
                             if (h2ddat.txfer_64B)
                               dat_q.push_back(h2ddat);
                             else if (!h2ddat.hdr68.ch)
                               dat_split = h2ddat;
                           end
                           __G3 : 
                           begin
                             g3 = g3_f68::type_id::create("g3");
                             g3.create_objects(flit.dir, 5'h0F>>(4-r_nt));
                             void'(g3.randomize);
                             void'(g3.pack_slot);
                             // final assign
                             flit.slot[sptr] = g3;
                             // push onto q
                             for (ii=0; ii<r_nt; ii++)
                               dat_q.push_back(g3.h2ddat_h[ii]);
                           end
                           __G4 : 
                           begin
                             g4 = g4_f68::type_id::create("g4");
                             g4.dir = flit.dir;
                             g4.m2sreq   = '0;
                             g4.h2ddat_h = h2ddat;
                             void'(g4.pack_slot);
                             // final assign
                             flit.slot[sptr] = g4;
                             // push onto q or split object
                             if (h2ddat.txfer_64B)
                               dat_q.push_back(h2ddat);
                             else if (!h2ddat.hdr68.ch)
                               dat_split = h2ddat;
                           end
                         endcase
                       end
                       // flit tracking
                       smpty[sptr] = 1'b0;
                       cntFLIT[CCH][cDAT] += r_nt;
                       // sequence tracking
                       txn_count[CCH][cDAT] += r_nt;
                     end
            H2DRSP : if (cntFLIT[CCH][cRSP]<max_msg_flit[CCH][cRSP]) begin
                       // r_nt + current count could exceed max; cap it at max
                       if ((cntFLIT[CCH][cRSP]+r_nt)>max_msg_flit[CCH][cRSP])
                         r_nt = max_msg_flit[CCH][cRSP]-cntFLIT[CCH][cRSP];
                       // ensure tightly packed slotset
                       attempt_tight_pack;
                       // build it
                       h2drsp = h2drsp_c::type_id::create("h2drsp");
                       h2drsp.flitmode = F68;
                       h2drsp.rsp68.val = 1'b1;
                       void'(h2drsp.randomize);
                       // the specific time we even CAN repack:
                       //   sptr=1,     previous slot=H0, r_nt=1
                       //   sptr=[2,3], previous slot=G2, r_nt=1
                       may_repack = 0; 
                       // Step 1: let's see if we even CAN repack
                       if (sptr==1 && flit.slot[0]!=null && 
                           flit.slot[0]._fmt==_H0 && r_nt==1)
                       begin
                         $cast(h0, flit.slot[0]);
                         // see if H2DRSP is open
                         may_repack = !h0.h2drsp.val;
                       end
                       else if (sptr>1 && flit.slot[sptr-1]!=null && 
                                flit.slot[sptr-1]._fmt==_G2 && r_nt==1)
                       begin
                         $cast(g2, flit.slot[sptr-1]);
                         // see if H2DRSP is open
                         may_repack = !g2.h2drsp.val;
                       end
                       // Step 2: if we can repack and that's selected, do that
                       if (may_repack && r_rpk) begin
                         did_repack = 1'b1;
                         if (!(--sptr)) begin
                           h0.h2drsp = h2drsp.rsp68;
                           void'(h0.pack_slot);
                           // final assign
                           flit.slot[sptr] = h0;
                         end
                         else begin
                           g2.h2drsp = h2drsp.rsp68;;
                           void'(g2.pack_slot);
                           // final assign
                           flit.slot[sptr] = g2;
                         end
                       end
                       // Step 3: if we can't/don't want to repack then create
                       // the new slot
                       else begin
                         case (r_fmt)
                           __H0 : 
                           begin
                             h0 = h0_f68::type_id::create("h0");
                             h0.dir = flit.dir;
                             h0.h2dreq = '0;
                             h0.h2drsp = h2drsp.rsp68;
                             void'(h0.randomize);
                             void'(h0.pack_slot);
                             // final assign
                             flit.slot[sptr] = h0;
                           end
                           __H1 : 
                           begin
                             h1 = h1_f68::type_id::create("h1");
                             h1.dir = flit.dir;
                             h1.h2ddat_hdr = '0;
                             for (ii=0; ii<2; ii++) begin
                               h2drsp = h2drsp_c::type_id::create("h2drsp");
                               h2drsp.flitmode = F68;
                               h2drsp.rsp68.val = 1'b1;
                               void'(h2drsp.randomize);
                               // pack it
                               h1.h2drsp[ii] = ii<r_nt ? h2drsp.rsp68 : '0;
                             end
                             void'(h1.randomize);
                             void'(h1.pack_slot);
                             // final assign
                             flit.slot[sptr] = h1;
                           end
                           __G1 : 
                           begin
                             g1 = g1_f68::type_id::create("g1");
                             g1.dir = flit.dir;
                             for (ii=0; ii<4; ii++) begin
                               h2drsp = h2drsp_c::type_id::create("h2drsp");
                               h2drsp.flitmode = F68;
                               h2drsp.rsp68.val = 1'b1;
                               void'(h2drsp.randomize);
                               // pack it
                               g1.h2drsp[ii] = ii<r_nt ? h2drsp.rsp68 : '0;
                             end
                             void'(g1.pack_slot);
                             // final assign
                             flit.slot[sptr] = g1;
                           end
                           __G2 : 
                           begin
                             g2 = g2_f68::type_id::create("g2");
                             g2.dir = flit.dir;
                             g2.h2dreq     = '0;
                             g2.h2ddat_hdr = '0;
                             g2.h2drsp     = h2drsp.rsp68;
                             void'(g2.pack_slot);
                             // final assign
                             flit.slot[sptr] = g2;
                           end
                           __G3 : 
                           begin
                             g3 = g3_f68::type_id::create("g3");
                             g3.h2ddat_hdr = {'0, '0, '0, '0};
                             g3.h2drsp     = h2drsp.rsp68;
                             void'(g3.pack_slot);
                             // final assign
                             flit.slot[sptr] = g3;
                           end
                           __G5 : 
                           begin
                             g5 = g5_f68::type_id::create("g5");
                             g5.dir = flit.dir;
                             g5.m2srwd_hdr = '0;
                             g5.h2drsp     = h2drsp.rsp68;
                             void'(g5.pack_slot);
                             // final assign
                             flit.slot[sptr] = g5;
                           end
                         endcase
                       end
                       // flit tracking
                       smpty[sptr] = 1'b0;
                       cntFLIT[CCH][cRSP] += r_nt;
                       // sequence tracking
                       txn_count[CCH][cRSP] += r_nt;
                     end
                     else r_tt = NONE;
            D2HREQ : if (cntFLIT[CCH][cREQ]<max_msg_flit[CCH][cREQ]) begin
                       // ensure tightly packed slotset
                       attempt_tight_pack;
                       // build it
                       d2hreq = d2hreq_c::type_id::create("d2hreq");
                       d2hreq.flitmode = F68;
                       d2hreq.req68.val = 1'b1;
                       void'(d2hreq.randomize);
                       // the specific time we even CAN repack:
                       //   sptr=[2,3], previous slot=[G1,G2]
                       may_repack = 0; 
                       // Step 1: let's see if we even CAN repack
                       if (sptr>1 && flit.slot[sptr-1]!=null) begin 
                         if (flit.slot[sptr-1]._fmt==_G1) begin
                           $cast(g1, flit.slot[sptr-1]);
                           // see if D2HREQ is open
                           may_repack = !g1.d2hreq.val;
                         end
                         else if (flit.slot[sptr-1]._fmt==_G2) begin
                           $cast(g2, flit.slot[sptr-1]);
                           // see if D2HREQ is open
                           may_repack = !g2.d2hreq.val;
                         end
                       end
                       // Step 2: if we can repack and that's selected, do that
                       if (may_repack && r_rpk) begin
                         did_repack = 1'b1;
                         if (flit.slot[--sptr]._fmt==_G1) begin
                           g1.d2hreq = d2hreq.req68;
                           void'(g1.pack_slot);
                           // final assign
                           flit.slot[sptr] = g1;
                         end
                         else begin
                           g2.d2hreq = d2hreq.req68;
                           void'(g2.pack_slot);
                           // final assign
                           flit.slot[sptr] = g2;
                         end
                       end
                       // Step 3: if we can't/don't want to repack then create
                       // the new slot
                       else begin
                         case (r_fmt)
                           __H1 : 
                           begin
                             h1 = h1_f68::type_id::create("h1");
                             h1.dir = flit.dir;
                             h1.d2hreq     = d2hreq.req68;
                             h1.d2hdat_hdr = '0;
                             void'(h1.randomize);
                             void'(h1.pack_slot);
                             // final assign
                             flit.slot[sptr] = h1;
                           end
                           __G1 : 
                           begin
                             g1 = g1_f68::type_id::create("g1");
                             g1.dir = flit.dir;
                             g1.d2hreq     = d2hreq.req68;
                             g1.d2hrsp     = {'0, '0};
                             void'(g1.pack_slot);
                             // final assign
                             flit.slot[sptr] = g1;
                           end
                           __G2 : 
                           begin
                             g2 = g2_f68::type_id::create("g2");
                             g2.dir = flit.dir;
                             g2.d2hreq     = d2hreq.req68;
                             g2.d2hdat_hdr = '0;
                             g2.d2hrsp     = '0;
                             void'(g2.pack_slot);
                             // final assign
                             flit.slot[sptr] = g2;
                           end
                         endcase
                       end
                       // flit tracking
                       smpty[sptr] = 1'b0;
                       cntFLIT[CCH][cREQ] += r_nt;
                       // sequence tracking
                       txn_count[CCH][cREQ] += r_nt;
                     end
                     else r_tt = NONE;
            D2HDAT : begin
                       // ensure tightly packed slotset
                       attempt_tight_pack;
                       // build it; if it's split txn upper chunk, use that
                       if (do_split) begin
                         $cast(d2hdat, dat_split);
                         // "remove" the split txn and insert it as a
                         // regular txn on the data queue
                         d2hdat.hdr68.ch = 1;
                         dat_split = null;
                       end
                       else begin
                         // build it
                         d2hdat = d2hdat_c::type_id::create("d2hdat");
                         d2hdat.flitmode = F68;
                         d2hdat.hdr68.val = 1'b1;
                         // only allow one outstanding split txn
                         if (dat_split != null)
                           d2hdat.txfer_64B = 1'b1;
                         // disallow split txn when trying to end sequence or
                         // global configuration disables it
                         else if (!flit_to_send || split_32B_disable)
                           d2hdat.txfer_64B = 1'b1;
                         // Now randomize
                         void'(d2hdat.randomize);
                         // Send low chunk now
                         if (!d2hdat.txfer_64B)
                           h2ddat.hdr68.ch = 1'b0;
                       end
                       // the specific time we even CAN repack:
                       //   sptr=1,     previous slot=[H0,H1], r_nt=1
                       //   sptr=1,     previous slot=H2
                       //   sptr=[2,3], previous slot=G2,      r_nt=1
                       may_repack = 0; 
                       // Step 1: let's see if we even CAN repack
                       if (sptr==1 && flit.slot[0]!=null && 
                           flit.slot[0]._fmt==_H0 && r_nt==1)
                       begin
                         $cast(h0, flit.slot[0]);
                         // see if D2HDAT is open
                         may_repack = !h0.d2hdat_hdr.val;
                       end
                       else if (sptr==1 && flit.slot[0]!=null && 
                           flit.slot[0]._fmt==_H1 && r_nt==1)
                       begin
                         $cast(h1, flit.slot[0]);
                         // see if D2HDAT is open
                         may_repack = !h1.d2hdat_hdr.val;
                       end
                       else if (sptr==1 && flit.slot[0]!=null && 
                           flit.slot[0]._fmt==_H2)
                       begin
                         $cast(h2, flit.slot[0]);
                         // see if D2HDAT is open
                         may_repack = !h2.d2hdat_hdr[0].val;
                       end
                       else if (sptr>1 && flit.slot[sptr-1]!=null && 
                                flit.slot[sptr-1]._fmt==_G2 && r_nt==1)
                       begin
                         $cast(g2, flit.slot[sptr-1]);
                         // see if D2HDAT is open
                         may_repack = !g2.d2hdat_hdr.val;
                       end
                       // Step 2: if we can repack and that's selected, do that
                       if (may_repack && r_rpk) begin
                         did_repack = 1'b1;
                         if (!(--sptr)) begin
                           if (flit.slot[sptr]._fmt==_H0) begin
                             h0.d2hdat_h = d2hdat;
                             void'(h0.pack_slot);
                             // final assign
                             flit.slot[sptr] = h0;
                             // push onto q or split object
                             if (d2hdat.txfer_64B)
                               dat_q.push_back(d2hdat);
                             else if (!d2hdat.hdr68.ch)
                               dat_split = d2hdat;
                           end
                           else if (flit.slot[sptr]._fmt==_H1) begin
                             h1.d2hdat_h = d2hdat;
                             void'(h1.pack_slot);
                             // final assign
                             flit.slot[sptr] = h1;
                             // push onto q or split object
                             if (d2hdat.txfer_64B)
                               dat_q.push_back(d2hdat);
                             else if (!d2hdat.hdr68.ch)
                               dat_split = d2hdat;
                           end
                           else begin //_H2
                             for (ii=0; ii<r_nt; ii++) begin
                               d2hdat = d2hdat_c::type_id::create("d2hdat");
                               d2hdat.flitmode  = F68;
                               d2hdat.hdr68.val = 1'b1;
                               d2hdat.txfer_64B = 1'b1;
                               void'(d2hdat.randomize);
                               // pack it
                               h2.d2hdat_h[ii] = d2hdat;
                               // push onto q
                               dat_q.push_back(d2hdat);
                             end
                             // final assign
                             flit.slot[sptr] = h2;
                           end
                         end
                         else begin //_G2
                           g2.d2hdat_h = d2hdat;
                           void'(g2.pack_slot);
                           // final assign
                           flit.slot[sptr] = g2;
                           // push onto q or split object
                           if (d2hdat.txfer_64B)
                             dat_q.push_back(d2hdat);
                           else if (!d2hdat.hdr68.ch)
                             dat_split = d2hdat;
                         end
                       end
                       // Step 3: if we can't/don't want to repack then create
                       // the new slot
                       else begin
                         case (r_fmt)
                           __H0 : 
                           begin
                             h0 = h0_f68::type_id::create("h0");
                             h0.dir = flit.dir;
                             h0.d2hdat_h = d2hdat;
                             h0.d2hrsp = {'0, '0};
                             h0.s2mndr = '0;
                             void'(h0.randomize);
                             void'(h0.pack_slot);
                             // final assign
                             flit.slot[sptr] = h0;
                             // push onto q or split object
                             if (d2hdat.txfer_64B)
                               dat_q.push_back(d2hdat);
                             else if (!d2hdat.hdr68.ch)
                               dat_split = d2hdat;
                           end
                           __H1 : 
                           begin
                             h1 = h1_f68::type_id::create("h1");
                             h1.dir = flit.dir;
                             h1.d2hreq   = '0;
                             h1.d2hdat_h = d2hdat;
                             void'(h1.randomize);
                             void'(h1.pack_slot);
                             // final assign
                             flit.slot[sptr] = h1;
                             // push onto q or split object
                             if (d2hdat.txfer_64B)
                               dat_q.push_back(d2hdat);
                             else if (!d2hdat.hdr68.ch)
                               dat_split = d2hdat;
                           end
                           __H2 : 
                           begin
                             h2 = h2_f68::type_id::create("h2");
                             h2.create_objects(flit.dir, 5'h0F>>(4-r_nt));
                             void'(h2.randomize);
                             void'(h2.pack_slot);
                             // final assign
                             flit.slot[sptr] = h2;
                             // push onto q
                             for (ii=0; ii<r_nt; ii++)
                               dat_q.push_back(h2.d2hdat_h[ii]);
                           end
                           __G2 : 
                           begin
                             g2 = g2_f68::type_id::create("g2");
                             g2.dir = flit.dir;
                             g2.d2hreq   = '0;
                             g2.d2hdat_h = d2hdat;
                             g2.d2hrsp   = '0;
                             void'(g2.pack_slot);
                             // final assign
                             flit.slot[sptr] = g2;
                             // push onto q or split object
                             if (d2hdat.txfer_64B)
                               dat_q.push_back(d2hdat);
                             else if (!d2hdat.hdr68.ch)
                               dat_split = d2hdat;
                           end
                           __G3 : 
                           begin
                             g3 = g3_f68::type_id::create("g3");
                             g3.create_objects(flit.dir, 4'hF>>(4-r_nt));
                             void'(g3.randomize);
                             void'(g3.pack_slot);
                             // final assign
                             flit.slot[sptr] = g3;
                             // push onto q
                             for (ii=0; ii<r_nt; ii++)
                               dat_q.push_back(g3.d2hdat_h[ii]);
                           end
                         endcase
                       end
                       // flit tracking
                       smpty[sptr] = 1'b0;
                       cntFLIT[CCH][cDAT] += r_nt;
                       // sequence tracking
                       txn_count[CCH][cDAT] += r_nt;
                     end
            D2HRSP : if (cntFLIT[CCH][cRSP]<max_msg_flit[CCH][cRSP]) begin
                       // r_nt + current count could exceed max; cap it at max
                       if ((cntFLIT[CCH][cRSP]+r_nt)>max_msg_flit[CCH][cRSP])
                         r_nt = max_msg_flit[CCH][cRSP]-cntFLIT[CCH][cRSP];
                       // ensure tightly packed slotset
                       attempt_tight_pack;
                       // build it
                       d2hrsp = d2hrsp_c::type_id::create("d2hrsp");
                       d2hrsp.flitmode = F68;
                       d2hrsp.rsp68.val = 1'b1;
                       void'(d2hrsp.randomize);
                       // the specific time we even CAN repack:
                       //   sptr=1,     previous slot=H0
                       //   sptr=[2,3], previous slot=G1
                       //   sptr=[2,3], previous slot=G2, r_nt=1
                       may_repack = 0; 
                       // Step 1: let's see if we even CAN repack
                       if (sptr==1 && flit.slot[0]!=null && 
                           flit.slot[0]._fmt==_H0)
                       begin
                         $cast(h0, flit.slot[0]);
                         // see if D2HRSP is open
                         may_repack = !h0.d2hrsp[0].val;
                       end
                       else if (sptr>1 && flit.slot[sptr-1]!=null && 
                                flit.slot[sptr-1]._fmt==_G1)
                       begin
                         $cast(g1, flit.slot[sptr-1]);
                         // see if D2HRSP is open
                         may_repack = !g1.d2hrsp[0].val;
                       end
                       else if (sptr>1 && flit.slot[sptr-1]!=null && 
                                flit.slot[sptr-1]._fmt==_G2 && r_nt==1)
                       begin
                         $cast(g2, flit.slot[sptr-1]);
                         // see if D2HRSP is open
                         may_repack = !g2.d2hrsp.val;
                       end
                       // Step 2: if we can repack and that's selected, do that
                       if (may_repack && r_rpk) begin
                         did_repack = 1'b1;
                         if (!(--sptr)) begin
                           for (ii=0; ii<r_nt; ii++) begin
                             d2hrsp = d2hrsp_c::type_id::create("d2hrsp");
                             d2hrsp.flitmode = F68;
                             d2hrsp.rsp68.val = 1'b1;
                             void'(d2hrsp.randomize);
                             // pack it
                             h0.d2hrsp[ii] = d2hrsp.rsp68;
                           end
                           void'(h0.pack_slot);
                           // final assign
                           flit.slot[sptr] = h0;
                         end
                         else if (flit.slot[sptr]._fmt==_G1) begin
                           for (ii=0; ii<r_nt; ii++) begin
                             d2hrsp = d2hrsp_c::type_id::create("d2hrsp");
                             d2hrsp.flitmode = F68;
                             d2hrsp.rsp68.val = 1'b1;
                             void'(d2hrsp.randomize);
                             // pack it
                             g1.d2hrsp[ii] = d2hrsp.rsp68;
                           end
                           void'(g1.pack_slot);
                           // final assign
                           flit.slot[sptr] = g1;
                         end
                         else begin
                           g2.d2hrsp = d2hrsp.rsp68;
                           void'(g2.pack_slot);
                           // final assign
                           flit.slot[sptr] = g2;
                         end
                       end
                       // Step 3: if we can't/don't want to repack then create
                       // the new slot
                       else begin
                         case (r_fmt)
                           __H0 : 
                           begin
                             h0 = h0_f68::type_id::create("h0");
                             h0.dir = flit.dir;
                             h0.d2hdat_hdr = '0;
                             h0.s2mndr     = '0;
                             for (ii=0; ii<2; ii++) begin
                               d2hrsp = d2hrsp_c::type_id::create("d2hrsp");
                               d2hrsp.flitmode = F68;
                               d2hrsp.rsp68.val = 1'b1;
                               void'(d2hrsp.randomize);
                               // pack it
                               h0.d2hrsp[ii] = ii<r_nt ? d2hrsp.rsp68 : '0;
                             end
                             void'(h0.randomize);
                             void'(h0.pack_slot);
                             // final assign
                             flit.slot[sptr] = h0;
                           end
                           __H2 : 
                           begin
                             h2 = h2_f68::type_id::create("h2");
                             h2.dir = flit.dir;
                             h2.d2hdat_hdr = {'0, '0, '0, '0};
                             h2.d2hrsp     = d2hrsp.rsp68;
                             void'(h2.randomize);
                             void'(h2.pack_slot);
                             // final assign
                             flit.slot[sptr] = h2;
                           end
                           __G1 : 
                           begin
                             g1 = g1_f68::type_id::create("g1");
                             g1.dir = flit.dir;
                             g1.d2hreq = '0;
                             for (ii=0; ii<2; ii++) begin
                               d2hrsp = d2hrsp_c::type_id::create("d2hrsp");
                               d2hrsp.flitmode = F68;
                               d2hrsp.rsp68.val = 1'b1;
                               void'(d2hrsp.randomize);
                               // pack it
                               g1.d2hrsp[ii] = ii<r_nt ? d2hrsp.rsp68 : '0;
                             end
                             void'(g1.pack_slot);
                             // final assign
                             flit.slot[sptr] = g1;
                           end
                           __G2 : 
                           begin
                             g2 = g2_f68::type_id::create("g2");
                             g2.dir = flit.dir;
                             g2.d2hreq     = '0;
                             g2.d2hdat_hdr = '0;
                             g2.d2hrsp     = d2hrsp.rsp68;
                             void'(g2.pack_slot);
                             // final assign
                             flit.slot[sptr] = g2;
                           end
                         endcase
                       end
                       // flit tracking
                       smpty[sptr] = 1'b0;
                       cntFLIT[CCH][cRSP] += r_nt;
                       // sequence tracking
                       txn_count[CCH][cRSP] += r_nt;
                     end
                     else r_tt = NONE;
          endcase 
        end
        // pack continuing data that's not an ADF
        else if (dat_q.size) begin
          r_tt = DATA;
          if (dat_q[0].txn_type == "H2D_DAT") begin
            $cast(h2ddat, dat_q[0]);
            if (!h2ddat.txfer_64B) begin
              if (!h2ddat.hdr68.ch)
                msg = $sformatf("DATA (%0d : CHUNK LO)",dd);
              else begin
                if (dd<2) dd = 2;
                msg = $sformatf("DATA (%0d : CHUNK HI)",dd);
              end
            end
            else begin
              msg = $sformatf("DATA (%0d)",dd);
            end
            `uvm_info(get_type_name, $sformatf("sptr=%0d -> %0s",sptr,msg), UVM_NONE)
            g0      = g0_f68::type_id::create("g0");
            g0.dir  = flit.dir;
            g0.data = h2ddat.dat[128*dd+:128];
            // final assign
            flit.slot[sptr] = g0;
            // flit tracking
            smpty[sptr] = 1'b0;
            // pop it
            if (dd==3 || (dd==1 && !h2ddat.txfer_64B)) begin
              void'(dat_q.pop_front);
              dd = 0;
            end
            else
              dd++;
          end
          else if (dat_q[0].txn_type == "D2H_DAT") begin
            $cast(d2hdat, dat_q[0]);
            if (!d2hdat.txfer_64B) begin
              if (!d2hdat.hdr68.ch)
                if (dd==2) 
                  msg = "DATA (BEN: CHUNK LO)";
                else
                  msg = $sformatf("DATA (%0d: CHUNK LO)",dd);
              else begin
                if (dd<2) dd = 2; //may need to shift data chunk pointer
                if (dd==4) 
                  msg = "DATA (BEN: CHUNK HI)";
                else
                  msg = $sformatf("DATA (%0d: CHUNK HI)",dd);
              end
            end
            else if (dd==4) begin
              msg = "DATA (BEN)";
            end
            else begin
              msg = $sformatf("DATA (%0d)",dd);
            end
            `uvm_info(get_type_name, $sformatf("sptr=%0d -> %0s",sptr,msg), UVM_NONE)
            // byte enable slot : low chunk
            if (!d2hdat.txfer_64B && !d2hdat.hdr68.ch && dd==2) begin
              g0be      = g0be_f68::type_id::create("g0be");
              g0be.dir  = flit.dir;
              g0be.data = d2hdat.be[0+:32];
              // final assign
              flit.slot[sptr] = g0be;
            end
            // byte enable slot : high chunk
            else if (!d2hdat.txfer_64B && d2hdat.hdr68.ch && dd==4) begin
              g0be      = g0be_f68::type_id::create("g0be");
              g0be.dir  = flit.dir;
              g0be.data = d2hdat.be[32+:32];
              // final assign
              flit.slot[sptr] = g0be;
            end
            // byte enable slot : full 
            else if (d2hdat.txfer_64B && dd==4) begin
              g0be      = g0be_f68::type_id::create("g0be");
              g0be.dir  = flit.dir;
              g0be.data = d2hdat.be;
              // final assign
              flit.slot[sptr] = g0be;
            end
            // data slot
            else begin
              g0      = g0_f68::type_id::create("g0");
              g0.dir  = flit.dir;
              g0.data = d2hdat.dat[128*dd+:128];
              // final assign
              flit.slot[sptr] = g0;
              // flit tracking
              smpty[sptr] = 1'b0;
            end
            // flit tracking
            smpty[sptr] = 1'b0;
            // pop it
            if ((!d2hdat.txfer_64B && !d2hdat.hdr68.ch && dd==1 && d2hdat.be==='1) || //low chunk
                (!d2hdat.txfer_64B && !d2hdat.hdr68.ch && dd==2) ||                   //low chunk: BE
                (!d2hdat.txfer_64B && !d2hdat.hdr68.ch && dd==3 && d2hdat.be==='1) || //high chunk
                (!d2hdat.txfer_64B && !d2hdat.hdr68.ch && dd==4) ||                   //high chunk: BE
                (d2hdat.txfer_64B && dd==3 && d2hdat.be==='1) || //full cacheline
                (d2hdat.txfer_64B && dd==4))  //full cacheline: BE
            begin
              void'(dat_q.pop_front);
              dd = 0;
            end
            else
              dd++;
          end
          else if (dat_q[0].txn_type == "M2S_RWD") begin
            $cast(m2srwd, dat_q[0]);
            if (dd == 4) msg = "DATA (BEN)";
            else         msg = $sformatf("DATA (%0d)",dd);
            `uvm_info(get_type_name, $sformatf("sptr=%0d -> %0s",sptr,msg), UVM_NONE)
            if (dd == 4) begin
              g0be      = g0be_f68::type_id::create("g0be");
              g0be.dir  = flit.dir;
              g0be.data = m2srwd.be;
              // final assign
              flit.slot[sptr] = g0be;
            end
            else begin
              g0      = g0_f68::type_id::create("g0");
              g0.dir  = flit.dir;
              g0.data = m2srwd.dat[128*dd+:128];
              // final assign
              flit.slot[sptr] = g0;
            end
            // flit tracking
            smpty[sptr] = 1'b0;
            // pop it
            if (dd==4 || (dd==3 && m2srwd.be==='1)) begin
              void'(dat_q.pop_front);
              dd = 0;
            end
            else
              dd++;
          end
          else if (dat_q[0].txn_type == "S2M_DRS") begin
            $cast(s2mdrs, dat_q[0]);
            if (!s2mdrs.txfer_64B) begin
              if (!s2mdrs.chunkval)
                msg = $sformatf("DATA (%0d : CHUNK LO)",dd);
              else begin
                if (dd<2) dd = 2;
                msg = $sformatf("DATA (%0d : CHUNK HI)",dd);
              end
            end
            else begin
              msg = $sformatf("DATA (%0d)",dd);
            end
            `uvm_info(get_type_name, $sformatf("sptr=%0d -> %0s",sptr,msg), UVM_NONE)
            g0      = g0_f68::type_id::create("g0");
            g0.dir  = flit.dir;
            g0.data = s2mdrs.dat[128*dd+:128];
            // final assign
            flit.slot[sptr] = g0;
            // flit tracking
            smpty[sptr] = 1'b0;
            // pop it
            if (dd==3 || (dd==1 && !s2mdrs.txfer_64B)) begin
              void'(dat_q.pop_front);
              dd = 0;
            end
            else
              dd++;
          end
        end
        // helpful print
        if (did_repack) begin
          `uvm_info(get_type_name, $sformatf("REPACKED: sptr=%0d, txntype=%0s, txn#=%0d",
                                              sptr, r_tt.name, r_nt), UVM_NONE)
        end
        else if (r_tt == NONE) begin
          `uvm_info(get_type_name, $sformatf("sptr=%0d -> NONE",sptr), UVM_NONE)
        end
        else if (r_tt != DATA) begin
          msg = flit.slot[sptr]._fmt.name;
          msg = msg.substr(1, msg.len-1);
          `uvm_info(get_type_name, $sformatf("sptr=%0d, slotfmt=%0d, txntype=%0s, txn#=%0d",
                                              sptr, msg, r_tt.name, r_nt), UVM_NONE)
        end
        // end on last slot
        if (sptr++==3) 
          break;
      end //done building a single flit
  
      // give extended sequences a callback
      pre_pack_flit(flit);

      // now pack it
      flit.pack_flit;

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

      // Fill the entire NFI width
      if (NFI_W>1) begin
        // Only rand at first flit
        if (flit_in_cycle++==0)
          void'(std::randomize(r_flits_in_cycle) with { r_flits_in_cycle inside {[1:NFI_W]}; });
        // Build out this cycle more or send
        if (flit_in_cycle<r_flits_in_cycle) begin
          continue;   
        end
        else 
          flit_in_cycle = 0;
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
  
    end //done sending flits
  
    // Ensure last flit(s) has been sent, which may not be modulo NFI width
    if (flit_q.size)
      super.body();

  endtask

  // Callback
  virtual function void pre_pack_flit(flit68_txn flit); endfunction

  virtual task post_body();
    `uvm_info(get_type_name, $sformatf("Sequence Summary: %0d Empty Flits + %0d Valid Flits = %0d Total Flits",
                               empty_flit_count, valid_flit_count, total_flit_count), UVM_NONE)
  endtask

  // Try to "shift left" AKA tightly pack transactions. This is required because
  // randomization of r_tt might equal NONE or r_tt might randomize to a txn
  // type that cannot be packed (ergo, same as NONE). NONE as a txn type is 
  // required because we DO want empty slots in the stream for testing.
  virtual function void attempt_tight_pack();
    // already as left as possible
    if (!sptr) return;
    // don't pack more tightly between H and G slots 
    else if (sptr==1) return;
    // can shift left 1
    else if (sptr==2 && smpty[1])
      sptr -= 1;
    // can shift left 1 or 2
    else if (sptr==3) begin
      case (smpty[1:2])
        2'b11 : sptr -= 2;
        2'b01 : sptr -= 1;
      endcase
    end
  endfunction

endclass
