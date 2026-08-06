class flit256_mst_qpacker_seq#(parameter NFI_W=3) extends cxl_nfi_mst_in_order_seq#(NFI_W);

  `uvm_object_param_utils(flit256_mst_qpacker_seq#(NFI_W))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("flit256_mst_qpacker_seq#(%0d)",NFI_W);
  virtual function string get_type_name(); return type_name; endfunction

  /**** STATISTICS ****/
  int unsigned total_flit_count;
  const int cREQ = 0, cDAT = 1, cRSP = 2;
  int unsigned txn_count[1:0][2:0]; //[1:0] = MEM/CCH, [2:0] = REQ/DAT/RSP

  /**** CONTROL ****/
  /** Per Flit **/
  bit [ 3:0]  sptr;  // Slot Pointer
  bit         sfull; // Slot Full (can't pack anymore)

  /* Odds are employed during each decision; certain txns
   * will be excluded based on conditions that would violate
   * the CXL spec. Default to evenly weighted.
   */
  struct packed {
    // CXL.cache
    int unsigned H2DREQ;
    int unsigned H2DDAT;
    int unsigned H2DRSP;
    int unsigned D2HREQ;
    int unsigned D2HDAT;
    int unsigned D2HRSP;
    // CXL.mem
    int unsigned M2SREQ;
    int unsigned M2SRWD;
    int unsigned M2SBIRSP;
    int unsigned S2MBISNP;
    int unsigned S2MDRS;
    int unsigned S2MNDR;
  } odds;

  int unsigned current_credit[1:0][2:0]; // Intra-flit credit availability variables

  // Per-group txn counts for 128B rolling group maximum enforcement (CXL 3.1 Table 4-18)
  // Index: [0]=Group A (slots 0-3), 
  //        [1]=Group B (slots 4-7), 
  //        [2]=Group C (slots 8-11), 
  //        [3]=Group D (slots 12-14)
  int unsigned gc_h2dreq[4],   gc_h2drsp[4], gc_h2ddat[4];
  int unsigned gc_d2hreq[4],   gc_d2hrsp[4], gc_d2hdat[4];
  int unsigned gc_m2sreq[4],   gc_m2srwd[4], gc_m2sbirsp[4];
  int unsigned gc_s2mbisnp[4], gc_s2mdrs[4], gc_s2mndr[4];

  // Tracks committed (completed) slot contributions; identical to *_q.size()
  int unsigned sc_h2dreq,   sc_h2drsp, sc_h2ddat;
  int unsigned sc_d2hreq,   sc_d2hrsp, sc_d2hdat;
  int unsigned sc_m2sreq,   sc_m2srwd, sc_m2sbirsp;
  int unsigned sc_s2mbisnp, sc_s2mdrs, sc_s2mndr;

  typedef enum {H2DREQ, H2DRSP, H2DDAT, D2HREQ, D2HRSP, D2HDAT, 
                M2SREQ, M2SRWD, M2SBIRSP, S2MNDR, S2MDRS, S2MBISNP,
                // Below not randomized
                NONE, DATA} e_txn_type; 

  rand e_txn_type r_tt; // r_tt="randomized txn type"; potentially randomized N times per slot

  h2dreq_c    h2dreq;   d2hreq_c    d2hreq;
  h2drsp_c    h2drsp;   d2hrsp_c    d2hrsp;
  h2ddat_c    h2ddat;   d2hdat_c    d2hdat;
  m2sreq_c    m2sreq;   s2mndr_c    s2mndr;
  m2srwd_c    m2srwd;   s2mdrs_c    s2mdrs;
  m2sbirsp_c  m2sbirsp; s2mbisnp_c  s2mbisnp;

  // queues of the txns being packed into a slot, cleared at slot start
  h2dreq_c    h2dreq_q[$];   d2hreq_c    d2hreq_q[$]; 
  h2ddat_c    h2ddat_q[$];   d2hdat_c    d2hdat_q[$]; 
  h2drsp_c    h2drsp_q[$];   d2hrsp_c    d2hrsp_q[$];
  m2sreq_c    m2sreq_q[$];   s2mndr_c    s2mndr_q[$];
  m2srwd_c    m2srwd_q[$];   s2mdrs_c    s2mdrs_q[$];
  m2sbirsp_c  m2sbirsp_q[$]; s2mbisnp_c  s2mbisnp_q[$];
  // data txns take multiple slots to pack, so this is an intermediary q
  // that exists across several slots
  base_txn    dat_q[$]; 
  
  /**** CONSTRAINTS ****/
  constraint c_txn {
    // Default Distribution
    r_tt dist {
      /* CXL.cache */
      // H2D
      H2DREQ      := odds.H2DREQ,
      H2DDAT      := odds.H2DDAT,
      H2DRSP      := odds.H2DRSP,
      // D2H
      D2HREQ      := odds.D2HREQ,
      D2HDAT      := odds.D2HDAT,
      D2HRSP      := odds.D2HRSP,
      /* CXL.mem */
      // M2S
      M2SREQ      := odds.M2SREQ,
      M2SRWD      := odds.M2SRWD,
      M2SBIRSP    := odds.M2SBIRSP,
      // S2M
      S2MBISNP    := odds.S2MBISNP,
      S2MDRS      := odds.S2MDRS,
      S2MNDR      := odds.S2MNDR
    };

    // Based on credits and queues
    (!q_avail(H2DREQ  ) || !crd_avail(H2DREQ  ) || !grp_avail(H2DREQ  )) -> r_tt != H2DREQ  ;
    (!q_avail(H2DDAT  ) || !crd_avail(H2DDAT  ) || !grp_avail(H2DDAT  )) -> r_tt != H2DDAT  ;
    (!q_avail(H2DRSP  ) || !crd_avail(H2DRSP  ) || !grp_avail(H2DRSP  )) -> r_tt != H2DRSP  ;
    (!q_avail(D2HREQ  ) || !crd_avail(D2HREQ  ) || !grp_avail(D2HREQ  )) -> r_tt != D2HREQ  ;
    (!q_avail(D2HDAT  ) || !crd_avail(D2HDAT  ) || !grp_avail(D2HDAT  )) -> r_tt != D2HDAT  ;
    (!q_avail(D2HRSP  ) || !crd_avail(D2HRSP  ) || !grp_avail(D2HRSP  )) -> r_tt != D2HRSP  ;
    (!q_avail(M2SREQ  ) || !crd_avail(M2SREQ  ) || !grp_avail(M2SREQ  )) -> r_tt != M2SREQ  ;
    (!q_avail(M2SRWD  ) || !crd_avail(M2SRWD  ) || !grp_avail(M2SRWD  )) -> r_tt != M2SRWD  ;
    (!q_avail(M2SBIRSP) || !crd_avail(M2SBIRSP) || !grp_avail(M2SBIRSP)) -> r_tt != M2SBIRSP;
    (!q_avail(S2MBISNP) || !crd_avail(S2MBISNP) || !grp_avail(S2MBISNP)) -> r_tt != S2MBISNP;
    (!q_avail(S2MDRS  ) || !crd_avail(S2MDRS  ) || !grp_avail(S2MDRS  )) -> r_tt != S2MDRS  ;
    (!q_avail(S2MNDR  ) || !crd_avail(S2MNDR  ) || !grp_avail(S2MNDR  )) -> r_tt != S2MNDR  ;

    // When the specific transaction has all of the following, it is part of the selectable set:
    // - Queue has transactions in it
    // - Credits available to send it
    // - Slot maximum isn't reached
    // - Rolling group maximum isn't reached

    /* CXL.cache */
    // - H2D
    ( sptr && h2dreq_q.size() >= 1) -> r_tt inside {H2DRSP};
    (         h2ddat_q.size() >= 1) -> r_tt inside {H2DDAT};
    (!sptr && h2drsp_q.size() >= 1) -> r_tt inside {H2DRSP};
    ( sptr && h2drsp_q.size() >= 1) -> r_tt inside {H2DREQ, H2DRSP};
    ( sptr && h2drsp_q.size() >= 2) -> r_tt inside {H2DRSP};
    // - D2H
    (         d2hreq_q.size() >= 1) -> r_tt inside {D2HRSP};

    (         d2hdat_q.size() >= 1) -> r_tt inside {D2HDAT};
    (!sptr && d2hrsp_q.size() >= 1) -> r_tt inside {D2HREQ, D2HRSP};
    (!sptr && d2hrsp_q.size() >= 2) -> r_tt inside {D2HRSP};
    ( sptr && d2hrsp_q.size() >= 1) -> r_tt inside {D2HREQ, D2HRSP};
    ( sptr && d2hrsp_q.size() >= 3) -> r_tt inside {D2HRSP};

    /* CXL.mem */
    // - M2S
    (         m2sbirsp_q.size() >= 1) -> r_tt inside {M2SBIRSP};

    // - S2M
    ( sptr && s2mbisnp_q.size() >= 1) -> r_tt inside {S2MNDR};
    (         s2mdrs_q.size() >= 1)   -> r_tt inside {S2MDRS};
    (!sptr && s2mndr_q.size() >= 1)   -> r_tt inside {S2MNDR};
    ( sptr && s2mndr_q.size() >= 1)   -> r_tt inside {S2MNDR, S2MBISNP};
    ( sptr && s2mndr_q.size() >= 2)   -> r_tt inside {S2MNDR};

  }

  function void pre_randomize;
    super.pre_randomize;
    if (odds == '0)
      odds = {12{32'd1}};
  endfunction

  /**** HELPERS ****/

  // This function only returns 1 if a specific txn type has available 
  // transactions to pack i.e. they're in the txn's queue
  function bit q_avail(e_txn_type this_txn);
    case(this_txn)
      // CXL.cache
      // H2D
      H2DREQ    : return (p_sequencer.shr.h2dreq_q.size() > 0);
      H2DDAT    : return (p_sequencer.shr.h2ddat_q.size() > 0);
      H2DRSP    : return (p_sequencer.shr.h2drsp_q.size() > 0);
      // D2H
      D2HREQ    : return (p_sequencer.shr.d2hreq_q.size() > 0);
      D2HDAT    : return (p_sequencer.shr.d2hdat_q.size() > 0);
      D2HRSP    : return (p_sequencer.shr.d2hrsp_q.size() > 0);
      // CXL.mem
      // M2S
      M2SREQ    : return (p_sequencer.shr.m2sreq_q.size() > 0);
      M2SRWD    : return (p_sequencer.shr.m2srwd_q.size() > 0);
      M2SBIRSP  : return (p_sequencer.shr.m2sbirsp_q.size() > 0);
      // S2M
      S2MBISNP  : return (p_sequencer.shr.s2mbisnp_q.size() > 0);
      S2MDRS    : return (p_sequencer.shr.s2mdrs_q.size() > 0);
      S2MNDR    : return (p_sequencer.shr.s2mndr_q.size() > 0);
      default   : return 0; // VCS will choke on these log calls `uvm_fatal(get_type_name, "Invalid argument passed to function")
    endcase
  endfunction

  // This function only returns 1 if a specific txn type has available credits
  function bit crd_avail(e_txn_type this_txn);
    case(this_txn)
      /* CXL.cache */
      // - H2D
      H2DREQ    : return (current_credit[CCH][cREQ] > 0);
      H2DDAT    : return (current_credit[CCH][cDAT] > 0);
      H2DRSP    : return (current_credit[CCH][cRSP] > 0);
      // - D2H                                    
      D2HREQ    : return (current_credit[CCH][cREQ] > 0);
      D2HDAT    : return (current_credit[CCH][cDAT] > 0);
      D2HRSP    : return (current_credit[CCH][cRSP] > 0);
      /* CXL.mem */
      // - M2S                                    
      M2SREQ    : return (current_credit[MEM][cREQ] > 0);
      M2SRWD    : return (current_credit[MEM][cDAT] > 0);
      M2SBIRSP  : return (current_credit[MEM][cRSP] > 0);
      // - S2M                                    
      S2MBISNP  : return (current_credit[MEM][cREQ] > 0);
      S2MDRS    : return (current_credit[MEM][cDAT] > 0);
      S2MNDR    : return (current_credit[MEM][cRSP] > 0);
      default   : return 0; // VCS will choke on these log calls `uvm_fatal(get_type_name, "Invalid argument passed to function")
    endcase
  endfunction

  // This function returns 1 for a specific txn type if that txn type can be 
  // packed on successive iterations WITHIN a slot. 
  function bit slt_avail(e_txn_type this_txn);
    // nothing has been packed i.e. 0th iteration, anything can be packed
    if (&{!h2dreq_q.size, !h2ddat_q.size, !h2drsp_q.size, 
          !m2sreq_q.size, !m2srwd_q.size, !m2sbirsp_q.size,
          !d2hreq_q.size, !d2hdat_q.size, !d2hrsp_q.size, 
          !s2mbisnp_q.size, !s2mdrs_q.size, !s2mndr_q.size})
    begin
      return 1;
    end
    // something already has been packed if we reach here, which
    // severely limits what can be packed next
    case(this_txn)
      /* CXL.cache */
      // - H2D
      H2DREQ    :
          // 1st iter: G0=1-h2dreq+1-h2drsp
          return (sptr && h2drsp_q.size==1 && h2dreq_q.size==0);
      H2DDAT    : 
          // multi-iters: h-slot only allows 3, g-slot allows 4
          return (!sptr && h2ddat_q.size inside {[1:2]}) || 
                 ( sptr && h2ddat_q.size inside {[1:3]});
      H2DRSP    :
                 // 1st iter: h-slot only allows 2
          return (!sptr && h2drsp_q.size==1) ||
                 // 1st,2nd iter: G0=1-h2dreq+1-h2drsp or G1=3-h2drsp
                 ( sptr && ((h2dreq_q.size==1 && h2drsp_q.size==0) || 
                            (h2dreq_q.size==0 && h2drsp_q.size inside {1,2})));

      // - D2H      
      D2HREQ    :
                 // 1st iter: H2: 1-d2hreq+1-d2hrsp
          return (!sptr && d2hrsp_q.size==1 && d2hreq_q.size==0) || 
                 // multi-iters: G2: 1-d2hreq+2-d2hrsp
                 ( sptr && d2hrsp_q.size inside {1,2} && d2hreq_q.size==0);
      D2HDAT    : 
          // header and generic slots allow up to 4
          return (d2hdat_q.size inside {[1:3]});
      D2HRSP    : 
                 // header slot can pack 1 with a d2hreq
          return (!sptr && d2hreq_q.size==1 && d2hrsp_q.size==0) ||
                 // generic slot can pack 2 with a d2hreq
                 ( sptr && d2hreq_q.size==1 && d2hrsp_q.size inside {0,1}) ||
                 // header and generic slot can pack up to 4 without a d2hreq
                 (d2hreq_q.size==0 && d2hrsp_q.size inside {[1:3]});
      /* CXL.mem */
      // - M2S      
      M2SREQ    : return 0;
      M2SRWD    : return 0;
      M2SBIRSP  : 
                 // header slot allows 2 m2sbirsp
          return (!sptr && m2sbirsp_q.size==1) ||
                 // generic slot allows 3 m2sbirsp
                 ( sptr && m2sbirsp_q.size inside {[1:2]});
      // - S2M      
      S2MBISNP  : 
          // only packed in a generic slot with a single s2mndr
          return (sptr && s2mndr_q.size==1 && s2mbisnp_q.size==0);
      S2MDRS    : 
          // header slot only allows 2, generic slot allows 3
          return (!sptr && s2mdrs_q.size==1) ||
                 ( sptr && s2mdrs_q.size inside {1,2});
      S2MNDR    : 
                 // h-slot allows 2-s2mndr
          return (!sptr && s2mndr_q.size==1) ||
                 // multi-iter
                 (sptr && ((s2mbisnp_q.size==1 && s2mndr_q.size==0) || 
                           (s2mbisnp_q.size==0 && s2mndr_q.size inside {1,2})));
      default   : return 0; // VCS will choke on these log calls `uvm_fatal(get_type_name, "Invalid argument passed to function")
    endcase
  endfunction

  // This function only returns 1 if a specific txn type hasn't reached 
  // its 128B group maximum and is one part of determining if addl. txns
  // can be packed into a slot 
  function bit grp_avail(e_txn_type this_txn);
    bit [1:0] cur_grp = sptr/4; 
    bit [1:0] prv_grp = cur_grp-1;
    case(this_txn)
      /* CXL.cache */
      // - H2C
      H2DREQ    : return ((gc_h2dreq[prv_grp] + gc_h2dreq[cur_grp]) < 2);
      H2DDAT    : return ((gc_h2ddat[prv_grp] + gc_h2ddat[cur_grp]) < 4);
      H2DRSP    : return ((gc_h2drsp[prv_grp] + gc_h2drsp[cur_grp]) < 6);
      // - D2H     
      D2HREQ    : return ((gc_d2hreq[prv_grp] + gc_d2hreq[cur_grp]) < 4);
      D2HDAT    : return ((gc_d2hdat[prv_grp] + gc_d2hdat[cur_grp]) < 4);
      D2HRSP    : return ((gc_d2hrsp[prv_grp] + gc_d2hrsp[cur_grp]) < 4);
      /* CXL.mem */
      // - M2S     
      M2SREQ    : return ((gc_m2sreq[prv_grp]   + gc_m2sreq[cur_grp])   < 4);
      M2SRWD    : return ((gc_m2srwd[prv_grp]   + gc_m2srwd[cur_grp])   < 2);
      M2SBIRSP  : return ((gc_m2sbirsp[prv_grp] + gc_m2sbirsp[cur_grp]) < 3);
      // - S2M     
      S2MNDR    : return ((gc_s2mndr[prv_grp]   + gc_s2mndr[cur_grp])   < 6);
      S2MDRS    : return ((gc_s2mdrs[prv_grp]   + gc_s2mdrs[cur_grp])   < 3);
      S2MBISNP  : return ((gc_s2mbisnp[prv_grp] + gc_s2mbisnp[cur_grp]) < 2);
      default   : return 0; // VCS will choke on these log calls `uvm_fatal(get_type_name, "Invalid argument passed to function")
    endcase
  endfunction

  function bit any_avail();
    if (q_avail(H2DREQ  ) && crd_avail(H2DREQ  ) && slt_avail(H2DREQ  ) && grp_avail(H2DREQ  )) return 1;
    if (q_avail(H2DDAT  ) && crd_avail(H2DDAT  ) && slt_avail(H2DDAT  ) && grp_avail(H2DDAT  )) return 1;
    if (q_avail(H2DRSP  ) && crd_avail(H2DRSP  ) && slt_avail(H2DRSP  ) && grp_avail(H2DRSP  )) return 1;
    if (q_avail(D2HREQ  ) && crd_avail(D2HREQ  ) && slt_avail(D2HREQ  ) && grp_avail(D2HREQ  )) return 1;
    if (q_avail(D2HDAT  ) && crd_avail(D2HDAT  ) && slt_avail(D2HDAT  ) && grp_avail(D2HDAT  )) return 1;
    if (q_avail(D2HRSP  ) && crd_avail(D2HRSP  ) && slt_avail(D2HRSP  ) && grp_avail(D2HRSP  )) return 1;
    if (q_avail(M2SREQ  ) && crd_avail(M2SREQ  ) && slt_avail(M2SREQ  ) && grp_avail(M2SREQ  )) return 1;
    if (q_avail(M2SRWD  ) && crd_avail(M2SRWD  ) && slt_avail(M2SRWD  ) && grp_avail(M2SRWD  )) return 1;
    if (q_avail(M2SBIRSP) && crd_avail(M2SBIRSP) && slt_avail(M2SBIRSP) && grp_avail(M2SBIRSP)) return 1;
    if (q_avail(S2MBISNP) && crd_avail(S2MBISNP) && slt_avail(S2MBISNP) && grp_avail(S2MBISNP)) return 1;
    if (q_avail(S2MDRS  ) && crd_avail(S2MDRS  ) && slt_avail(S2MDRS  ) && grp_avail(S2MDRS  )) return 1;
    if (q_avail(S2MNDR  ) && crd_avail(S2MNDR  ) && slt_avail(S2MNDR  ) && grp_avail(S2MNDR  )) return 1;
    // Default
    return 0;
  endfunction

  /**** PRIMARIES ****/
  function new(string name = "flit256_mst_qpacker_seq");
    super.new(name);
  endfunction

  virtual task body();
    flit256_txn flit;
    int         dd;               // 128B chunk index within the current dat_q head (0-3=data, 4=trailer)
    bit [1:0]   s2mdrs_trp_q[$:5]; // TRP count per S2MDRS entry in dat_q, for trailer packing
    bit         has_trp;
    int         d2hrsp_count, s2mdrs_count;

    flit = flit256_txn::type_id::create("flit");
    flit.flitmode = F256;
    flit.dir      = p_sequencer.cfg.dir;

    clear_gc(-1); //clear all to 0

    // This sequence services the shared-object queues forever, until stopped...
    forever begin

      // Wait for available transactions and credits to send a flit or if
      // there are dangling data chunks to send from a previous flit's
      // data header(s)
      while (1) begin
        if (
          (q_avail(H2DREQ  ) && (p_sequencer.shr.avl_req_credit[CCH])) ||
          (q_avail(H2DDAT  ) && (p_sequencer.shr.avl_dat_credit[CCH])) ||
          (q_avail(H2DRSP  ) && (p_sequencer.shr.avl_rsp_credit[CCH])) ||
          (q_avail(D2HREQ  ) && (p_sequencer.shr.avl_req_credit[CCH])) ||
          (q_avail(D2HDAT  ) && (p_sequencer.shr.avl_dat_credit[CCH])) ||
          (q_avail(D2HRSP  ) && (p_sequencer.shr.avl_rsp_credit[CCH])) ||
          (q_avail(M2SREQ  ) && (p_sequencer.shr.avl_req_credit[MEM])) ||
          (q_avail(M2SRWD  ) && (p_sequencer.shr.avl_dat_credit[MEM])) ||
          (q_avail(M2SBIRSP) && (p_sequencer.shr.avl_rsp_credit[MEM])) ||
          (q_avail(S2MBISNP) && (p_sequencer.shr.avl_req_credit[MEM])) ||
          (q_avail(S2MDRS  ) && (p_sequencer.shr.avl_dat_credit[MEM])) ||
          (q_avail(S2MNDR  ) && (p_sequencer.shr.avl_rsp_credit[MEM])) ||
          (dat_q.size() > 0)
        ) break;
        @(posedge p_sequencer.vif.clk);
      end

      `uvm_info(get_type_name(), "Transaction and credits are available.", UVM_DEBUG)

      // Initialize each flit
      sptr  = 0;
      flit = flit.new_flit;

      // Snapshot the current credit count, used within the flit to make 
      // sure credits aren't over-consumed
      current_credit[CCH][cREQ] = p_sequencer.shr.avl_req_credit[CCH];
      current_credit[CCH][cDAT] = p_sequencer.shr.avl_dat_credit[CCH];
      current_credit[CCH][cRSP] = p_sequencer.shr.avl_rsp_credit[CCH];
      current_credit[MEM][cREQ] = p_sequencer.shr.avl_req_credit[MEM];
      current_credit[MEM][cDAT] = p_sequencer.shr.avl_dat_credit[MEM];
      current_credit[MEM][cRSP] = p_sequencer.shr.avl_rsp_credit[MEM];

      /**** Per-Flit Loop ****/
      while(sptr < 15) begin

        // Clear the local queues, only contains transactions for 1 slot at a time
        clear_qs();

        // Clear the slot counters, counts are only valid for the current slot
        clear_scs();

        // Reset the Group Counters when the group boundary rolls over...
        // Group maximums are n and n-1, so can reset n-2
        if (!(sptr%4)) begin
          clear_gc(((sptr+8)/4)%4);
        end
      
        sfull = 0;

        /**** Per-Slot Loop ****/
        while(sfull != 1'b1) begin

          // Randomization is designed to only occur when ANY valid txn
          // is possible to pack, so we catch the pre-determined packing
          // conditions like a DATA slot or any "can't pack" conditions, 
          // which are dependent on 4 things: credit availability, 128B
          // packing max, txn availability, and slot packing max.
          if (sptr && dat_q.size() > 0)
            r_tt = DATA;
          // ENHANCEMENT: below code cannot pack a non-DH txn in Slot 0 when
          // rollover is >16, even though it is allowed by CXL spec.
          else if (!any_avail() || (!sptr && flit.slotset[0].pRollover > 16))
            r_tt = NONE;
          else if (!this.randomize()) begin
            `uvm_fatal("RAND_FAIL", "Randomization of flit256_mst_qpacker_seq failed")
          end

          case(r_tt)

            /** New TXN Slot **/
            H2DREQ    : begin
              h2dreq = p_sequencer.shr.pop_h2dreq();
              // Randomnizing allows for the TXN that is on the queue to not yet be fully filled out
              // and this sequence just handles it.
              void'(h2dreq.randomize());
              h2dreq_q.push_back(h2dreq);
              gc_h2dreq[sptr >> 2]++;
              current_credit[CCH][cREQ]--;
              txn_count[CCH][cREQ]++;
              sc_h2dreq++;
            end
            H2DDAT    : begin
              h2ddat = p_sequencer.shr.pop_h2ddat();
              void'(h2ddat.randomize());
              h2ddat_q.push_back(h2ddat);
              gc_h2ddat[sptr >> 2]++;
              current_credit[CCH][cDAT]--;
              txn_count[CCH][cDAT]++;
              sc_h2ddat++;
            end
            H2DRSP    : begin
              h2drsp = p_sequencer.shr.pop_h2drsp();
              void'(h2drsp.randomize());
              h2drsp_q.push_back(h2drsp);
              gc_h2drsp[sptr >> 2]++;
              current_credit[CCH][cRSP]--;
              txn_count[CCH][cRSP]++;
              sc_h2drsp++;
            end
            D2HREQ    : begin
              d2hreq = p_sequencer.shr.pop_d2hreq();
              void'(d2hreq.randomize());
              d2hreq_q.push_back(d2hreq);
              gc_d2hreq[sptr >> 2]++;
              current_credit[CCH][cREQ]--;
              txn_count[CCH][cREQ]++;
              sc_d2hreq++;
            end
            D2HDAT    : begin
              d2hdat = p_sequencer.shr.pop_d2hdat();
              void'(d2hdat.randomize());
              d2hdat_q.push_back(d2hdat);
              gc_d2hdat[sptr >> 2]++;
              current_credit[CCH][cDAT]--;
              txn_count[CCH][cDAT]++;
              sc_d2hdat++;
            end
            D2HRSP    : begin
              d2hrsp = p_sequencer.shr.pop_d2hrsp();
              void'(d2hrsp.randomize());
              d2hrsp_q.push_back(d2hrsp);
              gc_d2hrsp[sptr >> 2]++;
              current_credit[CCH][cRSP]--;
              txn_count[CCH][cRSP]++;
              sc_d2hrsp++;
            end
            M2SREQ    : begin
              m2sreq = p_sequencer.shr.pop_m2sreq();
              void'(m2sreq.randomize());
              m2sreq_q.push_back(m2sreq);
              gc_m2sreq[sptr >> 2]++;
              current_credit[MEM][cREQ]--;
              txn_count[MEM][cREQ]++;
              sc_m2sreq++;
            end
            M2SRWD    : begin
              m2srwd = p_sequencer.shr.pop_m2srwd();
              void'(m2srwd.randomize());
              m2srwd_q.push_back(m2srwd);
              gc_m2srwd[sptr >> 2]++;
              txn_count[MEM][cDAT]++;
              current_credit[MEM][cDAT]--;
              sc_m2srwd++;
            end
            M2SBIRSP  : begin
              m2sbirsp = p_sequencer.shr.pop_m2sbirsp();
              void'(m2sbirsp.randomize());
              m2sbirsp_q.push_back(m2sbirsp);
              gc_m2sbirsp[sptr >> 2]++;
              current_credit[MEM][cRSP]--;
              txn_count[MEM][cRSP]++;
              sc_m2sbirsp++;
            end
            S2MBISNP  : begin
              s2mbisnp = p_sequencer.shr.pop_s2mbisnp();
              void'(s2mbisnp.randomize());
              s2mbisnp_q.push_back(s2mbisnp);
              gc_s2mbisnp[sptr >> 2]++;
              current_credit[MEM][cREQ]--;
              txn_count[MEM][cREQ]++;
              sc_s2mbisnp++;
            end
            S2MDRS    : begin
              s2mdrs = p_sequencer.shr.pop_s2mdrs();
              void'(s2mdrs.randomize());
              s2mdrs_q.push_back(s2mdrs);
              gc_s2mdrs[sptr >> 2]++;
              current_credit[MEM][cDAT]--;
              txn_count[MEM][cDAT]++;
              sc_s2mdrs++;
            end
            S2MNDR    : begin
              s2mndr = p_sequencer.shr.pop_s2mndr();
              void'(s2mndr.randomize());
              s2mndr_q.push_back(s2mndr);
              gc_s2mndr[sptr >> 2]++;
              current_credit[MEM][cRSP]--;
              txn_count[MEM][cRSP]++;
              sc_s2mndr++;
            end

            /** DATA Slot **/
            DATA      : sfull = 1; // DATA slots are always exactly one slot wide

            /** NONE: group maxes or constraint exhaustion left no valid type **/
            NONE      : sfull = 1; // slot will be zero-filled in Per-Slot Pack

            /** Error Handling **/
            default   : `uvm_fatal(get_type_name(), "body() per-slot loop > an unsupported TXN Type was passed.")
          endcase

        end // while(sfull != 1)

        /**** Per-Slot Pack ****/
        begin : per_slot_pack
          m0_hbr  m0;  m1_hbr  m1;  m2_hbr  m2;  m3_hbr  m3;
          m4_hbr  m4;  m5_hbr  m5;  m6_hbr  m6;  m7_hbr  m7;
          m12_hbr m12; m13_hbr m13; m14_hbr m14; m15_hbr m15;
          f256_data    dat;
          f256_trailer trlr;

          /* DATA slot: one 128B chunk or trailer popped from dat_q head */
          if (r_tt == DATA) begin
            print_slot_info(sptr, $sformatf("%s DATA", dat_q[0].txn_type));
            if (dat_q[0].txn_type == "H2D_DAT") begin
              h2ddat_c hdat; $cast(hdat, dat_q[0]);
              dat      = f256_data::type_id::create("dat");
              dat.data = hdat.dat[128*dd+:128];
              flit.slot[sptr] = dat;
              if (dd == 3) begin void'(dat_q.pop_front()); dd = 0; end
              else         dd++;
            end
            else if (dat_q[0].txn_type == "D2H_DAT") begin
              d2hdat_c ddat; $cast(ddat, dat_q[0]);
              if (dd == 4) begin
                trlr      = f256_trailer::type_id::create("trlr");
                trlr.data = ddat.be;
                flit.slot[sptr] = trlr;
                void'(dat_q.pop_front()); 
                dd = 0;
              end 
              else begin
                dat      = f256_data::type_id::create("dat");
                dat.data = ddat.dat[128*dd+:128];
                flit.slot[sptr] = dat;
                if (dd == 3 && !ddat.hdr256.bep) begin void'(dat_q.pop_front()); dd = 0; end
                else                                   dd++;
              end
            end
            else if (dat_q[0].txn_type == "M2S_RWD") begin
              m2srwd_c rwd; $cast(rwd, dat_q[0]);
              if (dd == 4) begin
                trlr = f256_trailer::type_id::create("trlr");
                if (rwd.hdr256.memop inside {MemWrPtl, MemWrPtlTEE}) begin
                  trlr.data[0 +:64] = rwd.be;
                  trlr.data[64+:32] = {32{rwd.hdr256.metafield==ExtMetaState}}&rwd.emd;
                  trlr.data[96+:32] = '0;
                end 
                else begin
                  trlr.data = rwd.emd;
                end
                flit.slot[sptr] = trlr;
                void'(dat_q.pop_front()); 
                dd = 0;
              end 
              else begin
                dat      = f256_data::type_id::create("dat");
                dat.data = rwd.dat[128*dd+:128];
                flit.slot[sptr] = dat;
                if (dd == 3 && !rwd.hdr256.trp) begin void'(dat_q.pop_front()); dd = 0; end
                else                                  dd++;
              end
            end
            else if (dat_q[0].txn_type == "S2M_DRS") begin
              s2mdrs_c drs; $cast(drs, dat_q[0]);
              if (dd == 4) begin
                bit [0:2] s2mdrs_trp;
                bit [1:0] trp_cnt;
                s2mdrs_c  tmp;
                trlr      = f256_trailer::type_id::create("trlr");
                trlr.data = '0;
                trp_cnt   = s2mdrs_trp_q[0];
                for (int jj = 0; jj < trp_cnt; jj++) begin
                  $cast(tmp, dat_q[jj]); s2mdrs_trp[jj] = tmp.hdr256.trp;
                end
                if (s2mdrs_trp[0]) begin
                  $cast(tmp, dat_q[0]); 
                  trlr.data[0+:32] = tmp.emd;
                  if (s2mdrs_trp[1]) begin
                    $cast(tmp, dat_q[1]); 
                    trlr.data[32+:32] = tmp.emd;
                    if (s2mdrs_trp[2]) begin 
                      $cast(tmp, dat_q[2]); 
                      trlr.data[64+:32] = tmp.emd; 
                    end
                  end 
                  else if (s2mdrs_trp[2]) begin
                    $cast(tmp, dat_q[2]); 
                    trlr.data[32+:32] = tmp.emd;
                  end
                end 
                else if (s2mdrs_trp[1]) begin
                  $cast(tmp, dat_q[1]); 
                  trlr.data[0+:32] = tmp.emd;
                  if (s2mdrs_trp[2]) begin 
                    $cast(tmp, dat_q[2]); 
                    trlr.data[32+:32] = tmp.emd; 
                  end
                end 
                else begin
                  $cast(tmp, dat_q[2]); trlr.data[0+:32] = tmp.emd;
                end
                flit.slot[sptr] = trlr;
                void'(dat_q.pop_front()); 
                void'(s2mdrs_trp_q.pop_front()); 
                dd = 0;
              end 
              else begin
                dat      = f256_data::type_id::create("dat");
                dat.data = drs.dat[128*dd+:128];
                flit.slot[sptr] = dat;
                if (dd == 3 && !s2mdrs_trp_q[0]) begin
                  void'(dat_q.pop_front()); 
                  void'(s2mdrs_trp_q.pop_front()); 
                  dd = 0;
                end 
                else 
                  dd++;
              end
            end
          end
          /* Protocol slots: determine format from local queue contents */
          else if (h2dreq_q.size()) begin : H0_G0
            m0 = m0_hbr::type_id::create("m0");
            {m0.flitmode, m0.slot_num} = {F256, sptr};
            m0.h2dreq = h2dreq_q.pop_front().req256;
            m0.h2drsp = h2drsp_q.size() ? h2drsp_q.pop_front().rsp256 : '0;
            void'(m0.pack_slot()); flit.slot[sptr] = m0;
            print_slot_info(sptr, $sformatf("M0 [%0d H2DREQ + %0d H2DRSP]", sc_h2dreq, sc_h2drsp));
          end
          else if (h2drsp_q.size()) begin : H1_G1
            // H2DRSP should randomize either G0 or G1, if no H2DREQ unless it's a header slot or
            // there are more than one H2DRSPs
            if ($urandom_range(1) || !sptr || h2drsp_q.size() > 1) begin : SEL_G1_H1
              m1 = m1_hbr::type_id::create("m1");
              {m1.flitmode, m1.slot_num} = {F256, sptr};
              for (int ii = 0; ii < (sptr ? 3 : 2); ii++)
                m1.h2drsp[ii] = ii < h2drsp_q.size() ? h2drsp_q[ii].rsp256 : '0;
              void'(m1.pack_slot()); flit.slot[sptr] = m1;
              print_slot_info(sptr, $sformatf("M1 [%0d H2DRSP]", sc_h2drsp));
            end else begin : SEL_G0
              m0 = m0_hbr::type_id::create("m0");
              {m0.flitmode, m0.slot_num} = {F256, sptr};
              m0.h2dreq = '0; // Zeroize the REQ spot...
              m0.h2drsp = h2drsp_q.pop_front().rsp256; // Pack the RSP spot...
              void'(m0.pack_slot()); flit.slot[sptr] = m0;
              print_slot_info(sptr, $sformatf("M0 [0 H2DREQ + %0d H2DRSP]", sc_h2drsp));
            end
          end
          else if (d2hreq_q.size()) begin : H2_G2
            m2 = m2_hbr::type_id::create("m2");
            {m2.flitmode, m2.slot_num} = {F256, sptr};
            m2.d2hreq = d2hreq_q.pop_front().req256;
            if (d2hrsp_q.size() > (sptr ? 2 : 1)) `uvm_fatal("D2HRSP_LOST", "The d2hrsp_q is bigger that what will be packed, resulting in lost transactions.")
            d2hrsp_count = d2hrsp_q.size();
            for (int ii = 0; ii < (sptr ? 2 : 1); ii++) begin
              if (ii < d2hrsp_count) begin
                m2.d2hrsp[ii] = d2hrsp_q.pop_front().rsp256;
              end else m2.d2hrsp[ii] = '0;
            end
            if (d2hrsp_q.size()) `uvm_fatal("D2HRSP_LOST H2_G2", "The d2hrsp_q still contains contents which will now be thrown away")
            void'(m2.pack_slot()); flit.slot[sptr] = m2;
            print_slot_info(sptr, $sformatf("M2 [%0d D2HREQ + %0d D2HRSP]", sc_d2hreq, sc_d2hrsp));
          end
          else if (d2hrsp_q.size()) begin : H3_G3
            d2hrsp_count = d2hrsp_q.size();
            // D2HRSP should randomize either M2 or M3, if no D2HREQ or
            // we're packing a header slot and there is more than one D2HRSP
            if ($urandom_range(1) || (!sptr && d2hrsp_q.size() > 1) || (sptr && d2hrsp_q.size() > 2)) begin : SEL_M3
              m3 = m3_hbr::type_id::create("m3");
              {m3.flitmode, m3.slot_num} = {F256, sptr};
              for (int ii = 0; ii < 4; ii++)
                if (ii < d2hrsp_count) begin
                  m3.d2hrsp[ii] = d2hrsp_q.pop_front().rsp256;
                end else m3.d2hrsp[ii] = '0;
              if (d2hrsp_q.size()) `uvm_fatal("D2HRSP_LOST SEL_M3", "The d2hrsp_q still contains contents which will now be thrown away")
              void'(m3.pack_slot()); flit.slot[sptr] = m3;
              print_slot_info(sptr, $sformatf("M3 [%0d D2HRSP]", sc_d2hrsp));
            end else begin : SEL_M2
              m2 = m2_hbr::type_id::create("m2");
              {m2.flitmode, m2.slot_num} = {F256, sptr};
              m2.d2hreq = '0; // Zeroize the REQ spot...
              for (int ii = 0; ii < (sptr ? 2 : 1); ii++) // Pack the RSP spot...
                if (ii < d2hrsp_count) begin
                  m2.d2hrsp[ii] = d2hrsp_q.pop_front().rsp256;
                end else m2.d2hrsp[ii] = '0;
              if (d2hrsp_q.size()) `uvm_fatal("D2HRSP_LOST SEL_M2", "The d2hrsp_q still contains contents which will now be thrown away")
              void'(m2.pack_slot()); flit.slot[sptr] = m2;
              print_slot_info(sptr, $sformatf("M2 [0 D2HREQ + %0d D2HRSP]", sc_d2hrsp));
            end
          end
          else if (m2sreq_q.size()) begin : H4_G4
            m4 = m4_hbr::type_id::create("m4");
            {m4.flitmode, m4.slot_num} = {F256, sptr};
            m4.m2sreq = m2sreq_q.pop_front().req256;
            void'(m4.pack_slot()); flit.slot[sptr] = m4;
            print_slot_info(sptr, $sformatf("M4 [%0d M2SREQ]", sc_m2sreq));
          end
          else if (m2sbirsp_q.size()) begin : H5_G5
            m5 = m5_hbr::type_id::create("m5");
            {m5.flitmode, m5.slot_num} = {F256, sptr};
            for (int ii = 0; ii < (sptr ? 3 : 2); ii++)
              m5.m2sbirsp[ii] = ii < m2sbirsp_q.size() ? m2sbirsp_q[ii].birsp256 : '0;
            void'(m5.pack_slot()); flit.slot[sptr] = m5;
            print_slot_info(sptr, $sformatf("M5 [%0d M2SBIRSP]", sc_m2sbirsp));
          end
          else if (s2mbisnp_q.size()) begin : H6_G6
            m6 = m6_hbr::type_id::create("m6");
            {m6.flitmode, m6.slot_num} = {F256, sptr};
            m6.s2mbisnp = s2mbisnp_q.pop_front().bisnp256;
            m6.s2mndr   = s2mndr_q.size() ? s2mndr_q.pop_front().ndr256 : '0;
            void'(m6.pack_slot()); flit.slot[sptr] = m6;
            print_slot_info(sptr, $sformatf("M6 [%0d S2MBISNP + %0d S2MNDR]", sc_s2mbisnp, sc_s2mndr));
          end
          else if (s2mndr_q.size()) begin : M7_or_G6
            // S2MNDR should randomize either G6 or G7, if no S2MBISNP and there is only one S2MNDR
            if ($urandom_range(1) || !sptr || s2mndr_q.size() > 1) begin : SEL_M7
              m7 = m7_hbr::type_id::create("m7");
              {m7.flitmode, m7.slot_num} = {F256, sptr};
              for (int ii = 0; ii < (sptr ? 3 : 2); ii++)
                m7.s2mndr[ii] = ii < s2mndr_q.size() ? s2mndr_q[ii].ndr256 : '0;
              void'(m7.pack_slot()); flit.slot[sptr] = m7;
              print_slot_info(sptr, $sformatf("M7 [%0d S2MNDR]", sc_s2mndr));
            end else begin : SEL_G6
              m6 = m6_hbr::type_id::create("m6");
              {m6.flitmode, m6.slot_num} = {F256, sptr};
              m6.s2mbisnp = '0; // Zeroize the BI spot...
              m6.s2mndr   = s2mndr_q.pop_front().ndr256; // Pack the NDR spot...
              void'(m6.pack_slot()); flit.slot[sptr] = m6;
              print_slot_info(sptr, $sformatf("M6 [0 S2MBISNP + %0d S2MNDR]", sc_s2mndr));
            end
          end
          else if (h2ddat_q.size()) begin : H12_G12
            m12 = m12_hbr::type_id::create("m12");
            {m12.flitmode, m12.slot_num} = {F256, sptr};
            for (int ii = 0; ii < (sptr ? 4 : 3); ii++) begin
              if (ii < h2ddat_q.size()) begin
                m12.h2ddat_hdr[ii] = h2ddat_q[ii].hdr256; dat_q.push_back(h2ddat_q[ii]);
              end else m12.h2ddat_hdr[ii] = '0;
            end
            void'(m12.pack_slot()); flit.slot[sptr] = m12;
            print_slot_info(sptr, "M12");
          end
          else if (d2hdat_q.size()) begin : H13_G13
            m13 = m13_hbr::type_id::create("m13");
            {m13.flitmode, m13.slot_num} = {F256, sptr};
            for (int ii = 0; ii < 4; ii++) begin
              if (ii < d2hdat_q.size()) begin
                m13.d2hdat_hdr[ii] = d2hdat_q[ii].hdr256; dat_q.push_back(d2hdat_q[ii]);
              end else m13.d2hdat_hdr[ii] = '0;
            end
            void'(m13.pack_slot()); flit.slot[sptr] = m13;
            print_slot_info(sptr, "M13");
          end
          else if (m2srwd_q.size()) begin : H14_G14
            m14 = m14_hbr::type_id::create("m14");
            {m14.flitmode, m14.slot_num} = {F256, sptr};
            m14.m2srwd_hdr = m2srwd_q[0].hdr256;
            dat_q.push_back(m2srwd_q.pop_front());
            void'(m14.pack_slot()); flit.slot[sptr] = m14;
            print_slot_info(sptr, $sformatf("M14 [%0d M2SRWD + %0d M2SREQ]", sc_m2srwd, sc_m2sreq));
          end
          else if (s2mdrs_q.size()) begin : H15_G15
            has_trp = 1'b0;
            m15 = m15_hbr::type_id::create("m15");
            {m15.flitmode, m15.slot_num} = {F256, sptr};
            s2mdrs_count = s2mdrs_q.size();
            for (int ii = 0; ii < (sptr ? 3 : 2); ii++) begin
              if (ii < s2mdrs_count) begin
                has_trp |= s2mdrs_q[0].hdr256.trp;
                m15.s2mdrs_hdr[ii] = s2mdrs_q[0].hdr256; dat_q.push_back(s2mdrs_q.pop_front());
              end else m15.s2mdrs_hdr[ii] = '0;
            end
            void'(m15.pack_slot()); flit.slot[sptr] = m15;
            // First entry carries the group count; remaining carry 0 (no trailer lookup)
            for (int ii = 0; ii < s2mdrs_count; ii++)
              s2mdrs_trp_q.push_back(!ii && has_trp ? s2mdrs_count : 0);
            print_slot_info(sptr, $sformatf("M15 [%0d S2MDRS]", sc_s2mdrs));
          end
          else begin
            print_slot_info(sptr, "NONE");
          end

          sptr++;
        end // begin : per_slot_pack

      end // while(sptr < 15)

      if(
        (current_credit[CCH][cREQ] == p_sequencer.shr.avl_req_credit[CCH][cREQ]) &&
        (current_credit[CCH][cDAT] == p_sequencer.shr.avl_dat_credit[CCH][cDAT]) &&
        (current_credit[CCH][cRSP] == p_sequencer.shr.avl_rsp_credit[CCH][cRSP]) &&
        (current_credit[MEM][cREQ] == p_sequencer.shr.avl_req_credit[MEM][cREQ]) &&
        (current_credit[MEM][cDAT] == p_sequencer.shr.avl_dat_credit[MEM][cDAT]) &&
        (current_credit[MEM][cRSP] == p_sequencer.shr.avl_rsp_credit[MEM][cRSP])
      ) `uvm_fatal(get_type_name(), "All current and original credit counts are exactly the same, something is wrong");

      // Push Flit onto Base Queue
      flit.pack;
      flit_q.push_back(flit);

      // Send the Flit
      super.body();

      // Increment Flit Counter
      total_flit_count++;

    end

  endtask

  function void print_slot_info(int slotnumber, string slotinfo);
    // Print the slot packing info
    `uvm_info(get_type_name(), $sformatf("Slot %02d - %s", slotnumber, slotinfo), UVM_HIGH)
  endfunction

  function void clear_qs();
    h2dreq_q   = {}; h2drsp_q   = {}; h2ddat_q   = {};
    d2hreq_q   = {}; d2hrsp_q   = {}; d2hdat_q   = {};
    m2sreq_q   = {}; m2srwd_q   = {}; m2sbirsp_q = {};
    s2mbisnp_q = {}; s2mdrs_q   = {}; s2mndr_q   = {};
  endfunction

  function void clear_scs();
    sc_h2dreq   = 0; sc_h2drsp = 0; sc_h2ddat   = 0;
    sc_d2hreq   = 0; sc_d2hrsp = 0; sc_d2hdat   = 0;
    sc_m2sreq   = 0; sc_m2srwd = 0; sc_m2sbirsp = 0;
    sc_s2mbisnp = 0; sc_s2mdrs = 0; sc_s2mndr   = 0;
  endfunction

  // -1 passed to this function means clear ALL gcs
  function void clear_gc(bit [2:0] p);
    if (&p) begin
      gc_h2dreq   = '{default: 0}; gc_h2drsp = '{default: 0}; gc_h2ddat   = '{default: 0};
      gc_d2hreq   = '{default: 0}; gc_d2hrsp = '{default: 0}; gc_d2hdat   = '{default: 0};
      gc_m2sreq   = '{default: 0}; gc_m2srwd = '{default: 0}; gc_m2sbirsp = '{default: 0};
      gc_s2mbisnp = '{default: 0}; gc_s2mdrs = '{default: 0}; gc_s2mndr   = '{default: 0};
    end
    else if (p[2])
      `uvm_fatal(get_type_name, $sformatf("Invalid argument p=%0d, valid range is [-1:3]",p))
    else begin
      gc_h2dreq[p]   = 0; gc_h2drsp[p] = 0; gc_h2ddat[p]   = 0;
      gc_d2hreq[p]   = 0; gc_d2hrsp[p] = 0; gc_d2hdat[p]   = 0;
      gc_m2sreq[p]   = 0; gc_m2srwd[p] = 0; gc_m2sbirsp[p] = 0;
      gc_s2mbisnp[p] = 0; gc_s2mdrs[p] = 0; gc_s2mndr[p]   = 0;
    end
  endfunction

endclass
