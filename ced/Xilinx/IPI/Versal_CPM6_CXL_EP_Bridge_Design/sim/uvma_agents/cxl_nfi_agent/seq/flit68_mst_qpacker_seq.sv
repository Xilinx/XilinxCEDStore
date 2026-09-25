class flit68_mst_qpacker_seq#(parameter NFI_W=3) extends cxl_nfi_mst_in_order_seq#(NFI_W);

  `uvm_object_param_utils(flit68_mst_qpacker_seq#(NFI_W))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("flit68_mst_qpacker_seq#(%0d)",NFI_W);
  virtual function string get_type_name(); return type_name; endfunction

  const int cREQ = 0, cDAT = 1, cRSP = 2;

  /**** STATISTICS ****/
  int unsigned total_flit_count;
  int unsigned txn_count[1:0][2:0]; //[1:0] = MEM/CCH, [2:0] = REQ/DAT/RSP

  /**** CONTROL ****/
  bit         disable_d2hdat_be;

  /** Per Flit **/
  bit [ 1:0]  sptr;  // Slot Pointer
  bit         sfull; // Slot Full
  flit68_txn  flit;

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
    int unsigned S2MDRS;
    int unsigned S2MNDR;
  } odds;

  int unsigned current_credit[1:0][2:0]; // Intra-flit credit snapshot

  // Per-flit transaction counters (enforce per-flit maximums per CXL 3.1 Section 4.2.5)
  // H2D: H2DREQ<=2, H2DRSP<=4, H2DDAT<=4, M2SREQ<=2, M2SRWD<=1
  // D2H: D2HREQ<=4, D2HRSP<=2, D2HDAT<=4, S2MNDR<=2, S2MDRS<=3
  int unsigned fc_h2dreq, fc_h2drsp, fc_h2ddat;
  int unsigned fc_d2hreq, fc_d2hrsp, fc_d2hdat;
  int unsigned fc_m2sreq, fc_m2srwd;
  int unsigned fc_s2mndr, fc_s2mdrs;

  // Per-slot transaction counters (how many of each type packed into the current slot)
  int unsigned sc_h2dreq, sc_h2drsp, sc_h2ddat;
  int unsigned sc_d2hreq, sc_d2hrsp, sc_d2hdat;
  int unsigned sc_m2sreq, sc_m2srwd;
  int unsigned sc_s2mndr, sc_s2mdrs;

  typedef enum {H2DREQ, H2DDAT, H2DRSP, D2HREQ, D2HDAT, D2HRSP,
                M2SREQ, M2SRWD, S2MDRS, S2MNDR,
                // Below values cannot randomized
                NONE, DATA} e_txn_type;

  rand e_txn_type r_tt; // randomized txn type; potentially rand multiple times per slot

  h2dreq_c    h2dreq;   d2hreq_c    d2hreq;
  h2drsp_c    h2drsp;   d2hrsp_c    d2hrsp;
  h2ddat_c    h2ddat;   d2hdat_c    d2hdat;
  m2sreq_c    m2sreq;   s2mndr_c    s2mndr;
  m2srwd_c    m2srwd;   s2mdrs_c    s2mdrs;

  h2dreq_c    h2dreq_q[$];   d2hreq_c    d2hreq_q[$]; // Per-slot queues of the transactions to pack
  h2ddat_c    h2ddat_q[$];   d2hdat_c    d2hdat_q[$]; // Not every type is used per slot...
  h2drsp_c    h2drsp_q[$];   d2hrsp_c    d2hrsp_q[$];
  m2sreq_c    m2sreq_q[$];   s2mndr_c    s2mndr_q[$];
  m2srwd_c    m2srwd_q[$];   s2mdrs_c    s2mdrs_q[$];
  base_txn    dat_q[$];

  /**** CONSTRAINTS ****/
  constraint c_txn_type {
    // If randomization is called, the packing respects the provided odds
    r_tt dist {
      /* CXL.cache */
      // - H2D
      H2DREQ      := odds.H2DREQ,
      H2DDAT      := odds.H2DDAT,
      H2DRSP      := odds.H2DRSP,
      // - D2H
      D2HREQ      := odds.D2HREQ,
      D2HDAT      := odds.D2HDAT,
      D2HRSP      := odds.D2HRSP,
      /* CXL.mem */
      // - M2S
      M2SREQ      := odds.M2SREQ,
      M2SRWD      := odds.M2SRWD,
      // - S2M
      S2MDRS      := odds.S2MDRS,
      S2MNDR      := odds.S2MNDR
    };

    // Based on credits and queues
    |{!q_avail(H2DREQ), !crd_avail(H2DREQ), !grp_avail(H2DREQ)}                     -> r_tt != H2DREQ;
    |{!q_avail(H2DDAT), !crd_avail(H2DDAT), !grp_avail(H2DDAT), !mdh_avail(H2DDAT)} -> r_tt != H2DDAT;
    |{!q_avail(H2DRSP), !crd_avail(H2DRSP), !grp_avail(H2DRSP)}                     -> r_tt != H2DRSP;
    |{!q_avail(D2HREQ), !crd_avail(D2HREQ), !grp_avail(D2HREQ)}                     -> r_tt != D2HREQ;
    |{!q_avail(D2HDAT), !crd_avail(D2HDAT), !grp_avail(D2HDAT), !mdh_avail(D2HDAT)} -> r_tt != D2HDAT;
    |{!q_avail(D2HRSP), !crd_avail(D2HRSP), !grp_avail(D2HRSP)}                     -> r_tt != D2HRSP;
    |{!q_avail(M2SREQ), !crd_avail(M2SREQ), !grp_avail(M2SREQ)}                     -> r_tt != M2SREQ;
    |{!q_avail(M2SRWD), !crd_avail(M2SRWD), !grp_avail(M2SRWD)}                     -> r_tt != M2SRWD;
    |{!q_avail(S2MNDR), !crd_avail(S2MNDR), !grp_avail(S2MNDR)}                     -> r_tt != S2MNDR;
    |{!q_avail(S2MDRS), !crd_avail(S2MDRS), !grp_avail(S2MDRS), !mdh_avail(S2MDRS)} -> r_tt != S2MDRS;

    // Given the complex nature of F68 packing, I'm just going to build up
    // constraints from each iteration (what's been previously packed) instead 
    // of excluding based on txn type. At the zeroth iteration, anything can
    // be packed, so only need to start excluding at the first iteration.
    if (!sptr) {
      /* H2C */
      // 1st iteration
      check_h2c_qs(.cache_req(1)) -> r_tt inside {H2DRSP, H2DDAT};
      check_h2c_qs(.cache_dat(1)) -> r_tt inside {H2DREQ, H2DDAT, H2DRSP};
      check_h2c_qs(.cache_rsp(1)) -> r_tt inside {H2DREQ, H2DDAT, H2DRSP};
      // 2nd iteration
      check_h2c_qs(.cache_dat(1), .cache_rsp(1)) -> r_tt==H2DRSP;
      check_h2c_qs(.cache_dat(2))                -> r_tt==H2DDAT;
      check_h2c_qs(.cache_rsp(2))                -> r_tt==H2DDAT;
      // 3rd iteration
      check_h2c_qs(.cache_dat(3)) -> r_tt==H2DDAT;
      /* C2H */
      // 1st iteration
      check_c2h_qs(.cache_req(1)) -> r_tt inside {D2HDAT};
      check_c2h_qs(.cache_dat(1)) -> r_tt inside {D2HREQ, D2HDAT, D2HRSP, S2MNDR};
      check_c2h_qs(.cache_rsp(1)) -> r_tt inside {D2HDAT, D2HRSP, S2MNDR};
      check_c2h_qs(.mem_ndr(1))   -> r_tt inside {D2HDAT, D2HRSP, S2MDRS, S2MNDR};
      check_c2h_qs(.mem_drs(1))   -> r_tt inside {S2MDRS, S2MNDR};
      // 2nd iteration
      check_c2h_qs(.cache_dat(1), .cache_rsp(1)) -> r_tt inside {D2HDAT, D2HRSP, S2MNDR};
      check_c2h_qs(.cache_rsp(2))                -> r_tt inside {D2HDAT, S2MNDR};
      check_c2h_qs(.cache_dat(1), .mem_ndr(1))   -> r_tt==D2HRSP;
      check_c2h_qs(.cache_rsp(1), .mem_ndr(1))   -> r_tt inside {D2HDAT, D2HRSP};
      check_c2h_qs(.cache_dat(2))                -> r_tt inside {D2HDAT, D2HRSP};
      // 3rd iteration
      check_c2h_qs(.cache_dat(1), .cache_rsp(2))              -> r_tt==S2MNDR;
      check_c2h_qs(.cache_dat(1), .cache_rsp(1), .mem_ndr(1)) -> r_tt==D2HRSP;
      check_c2h_qs(.cache_rsp(2), .mem_ndr(1))                -> r_tt==D2HDAT;
      check_c2h_qs(.cache_dat(3))                             -> r_tt inside {D2HDAT, D2HRSP};
      check_c2h_qs(.cache_dat(2), .cache_rsp(1))              -> r_tt==D2HDAT; 
      // 4th iteration
      check_c2h_qs(.cache_dat(3), .cache_rsp(1)) -> r_tt==D2HDAT;
      check_c2h_qs(.cache_dat(4))                -> r_tt==D2HRSP;
    } else {
      /* H2C */
      // 1st iteration
      check_h2c_qs(.cache_req(1)) -> r_tt inside {H2DRSP, H2DDAT};
      check_h2c_qs(.cache_dat(1)) -> r_tt inside {H2DREQ, H2DDAT, H2DRSP, M2SREQ};
      check_h2c_qs(.cache_rsp(1)) -> r_tt inside {H2DREQ, H2DDAT, H2DRSP, M2SRWD};
      check_h2c_qs(.mem_req(1))   -> r_tt==H2DDAT;
      check_h2c_qs(.mem_rwd(1))   -> r_tt==H2DRSP;
      // 2nd iteration
      check_h2c_qs(.cache_req(1), .cache_rsp(1)) -> r_tt==H2DDAT;
      check_h2c_qs(.cache_req(1), .cache_dat(1)) -> r_tt==H2DRSP;
      check_h2c_qs(.cache_dat(1), .cache_rsp(1)) -> r_tt inside {H2DREQ, H2DDAT};
      check_h2c_qs(.cache_dat(2))                -> r_tt inside {H2DDAT, H2DRSP};
      check_h2c_qs(.cache_rsp(2))                -> r_tt==H2DRSP;
      // 3rd iteration
      check_h2c_qs(.cache_dat(2), .cache_rsp(1)) -> r_tt==H2DDAT;
      check_h2c_qs(.cache_dat(3))                -> r_tt inside {H2DDAT, H2DRSP};
      check_h2c_qs(.cache_dat(3), .cache_rsp(1)) -> r_tt==H2DDAT;
      check_h2c_qs(.cache_rsp(3))                -> r_tt==H2DRSP;
      // 4th iteration
      check_h2c_qs(.cache_dat(4)) -> r_tt==H2DRSP;
      /* C2H */
      // 1st iteration
      check_c2h_qs(.cache_req(1)) -> r_tt inside {D2HDAT, D2HRSP};
      check_c2h_qs(.cache_dat(1)) -> r_tt inside {D2HREQ, D2HDAT, D2HRSP};
      check_c2h_qs(.cache_rsp(1)) -> r_tt inside {D2HREQ, D2HDAT, D2HRSP};
      check_c2h_qs(.mem_drs(1))   -> r_tt inside {S2MDRS, S2MNDR};
      check_c2h_qs(.mem_ndr(1))   -> r_tt inside {S2MDRS, S2MNDR};
      // 2nd iteration
      check_c2h_qs(.cache_rsp(2))                 -> r_tt==D2HREQ;
      check_c2h_qs(.cache_req(1), .cache_rsp(1))  -> r_tt inside {D2HRSP,D2HDAT};
      check_c2h_qs(.cache_dat(1), .cache_rsp(1))  -> r_tt==D2HREQ;
      check_c2h_qs(.cache_req(1), .cache_dat(1))  -> r_tt==D2HRSP;
      check_c2h_qs(.cache_dat(2))                 -> r_tt==D2HDAT;
      check_c2h_qs(.mem_drs(2))                   -> r_tt==S2MDRS;
      check_c2h_qs(.mem_ndr(2))                   -> r_tt==S2MDRS;
      check_c2h_qs(.mem_ndr(1), .mem_drs(1))      -> r_tt==S2MNDR;
      // 3rd iteration
      check_c2h_qs(.cache_dat(3)) -> r_tt==D2HDAT;
    }
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
      H2DREQ  : return (p_sequencer.shr.h2dreq_q.size() > 0);
      H2DDAT  : return (p_sequencer.shr.h2ddat_q.size() > 0);
      H2DRSP  : return (p_sequencer.shr.h2drsp_q.size() > 0);
      // D2H
      D2HREQ  : return (p_sequencer.shr.d2hreq_q.size() > 0);
      D2HDAT  : return (p_sequencer.shr.d2hdat_q.size() > 0);
      D2HRSP  : return (p_sequencer.shr.d2hrsp_q.size() > 0);
      // CXL.mem
      // M2S
      M2SREQ  : return (p_sequencer.shr.m2sreq_q.size() > 0);
      M2SRWD  : return (p_sequencer.shr.m2srwd_q.size() > 0);
      // S2M
      S2MDRS  : return (p_sequencer.shr.s2mdrs_q.size() > 0);
      S2MNDR  : return (p_sequencer.shr.s2mndr_q.size() > 0);
      default : return 0; // VCS will fatal on `uvm_fatal due to function in constraint
    endcase
  endfunction

  // This function only returns 1 if a specific txn type has available credits
  function bit crd_avail(e_txn_type this_txn);
    case(this_txn)
      // CXL.cache
      // H2D
      H2DREQ  : return (current_credit[CCH][cREQ] > 0);
      H2DDAT  : return (current_credit[CCH][cDAT] > 0);
      H2DRSP  : return (current_credit[CCH][cRSP] > 0);
      // D2H
      D2HREQ  : return (current_credit[CCH][cREQ] > 0);
      D2HDAT  : return (current_credit[CCH][cDAT] > 0);
      D2HRSP  : return (current_credit[CCH][cRSP] > 0);
      // CXL.mem
      // M2S
      M2SREQ  : return (current_credit[MEM][cREQ] > 0);
      M2SRWD  : return (current_credit[MEM][cDAT] > 0);
      // S2M
      S2MDRS  : return (current_credit[MEM][cDAT] > 0);
      S2MNDR  : return (current_credit[MEM][cRSP] > 0);
      default : return 0; // VCS will fatal on `uvm_fatal due to function in constraint
    endcase
  endfunction

  // This function returns 1 for a specific txn type if that txn type can be 
  // packed on successive iterations WITHIN a slot. 
  function bit slt_avail(e_txn_type this_txn);
    // nothing has been packed i.e. 0th iteration, anything can be packed
    if (&{!h2dreq_q.size, !h2ddat_q.size, !h2drsp_q.size, 
          !m2sreq_q.size, !m2srwd_q.size,                  
          !d2hreq_q.size, !d2hdat_q.size, !d2hrsp_q.size, 
                          !s2mdrs_q.size, !s2mndr_q.size})
    begin
      return 1;
    end
    // something already has been packed if we reach here, which
    // severely limits what can be packed next
    case(this_txn)
      /* CXL.cache */
      // - H2D
      H2DREQ    : if (!sptr)
                    return (check_h2c_qs(.cache_rsp(1)) ||
                            check_h2c_qs(.cache_dat(1)));
                  else
                    return (check_h2c_qs(.cache_dat(1)) ||
                            check_h2c_qs(.cache_dat(1), .cache_rsp(1)) ||
                            check_h2c_qs(.cache_rsp(1)));

      H2DDAT    : if (!sptr)
                    return (check_h2c_qs(.cache_rsp(1)) ||
                            check_h2c_qs(.cache_rsp(2)) ||
                            check_h2c_qs(.cache_req(1)) ||
                            check_h2c_qs(.cache_dat(1)) ||
                            check_h2c_qs(.cache_dat(2)) ||
                            check_h2c_qs(.cache_dat(3)));
                  else
                    return (check_h2c_qs(.cache_req(1)) ||
                            check_h2c_qs(.cache_req(1), .cache_rsp(1)) ||
                            check_h2c_qs(.cache_rsp(1)) ||
                            check_h2c_qs(.cache_rsp(1), .cache_dat(1)) ||
                            check_h2c_qs(.cache_rsp(1), .cache_dat(2)) ||
                            check_h2c_qs(.cache_rsp(1), .cache_dat(3)) ||
                            check_h2c_qs(.cache_dat(1)) ||
                            check_h2c_qs(.cache_dat(2)) ||
                            check_h2c_qs(.cache_dat(3)) ||
                            check_h2c_qs(.cache_req(1)));

      H2DRSP    : if (!sptr)
                    return (check_h2c_qs(.cache_req(1)) ||
                            check_h2c_qs(.cache_dat(1)) ||
                            check_h2c_qs(.cache_dat(1), .cache_rsp(1)) ||
                            check_h2c_qs(.cache_rsp(1)));
                  else
                    return (check_h2c_qs(.cache_rsp(1)) ||
                            check_h2c_qs(.cache_rsp(2)) ||
                            check_h2c_qs(.cache_rsp(3)) ||
                            check_h2c_qs(.cache_req(1)) ||
                            check_h2c_qs(.cache_req(1), .cache_dat(1)) ||
                            check_h2c_qs(.cache_dat(1)) ||
                            check_h2c_qs(.cache_dat(2)) ||
                            check_h2c_qs(.cache_dat(3)) ||
                            check_h2c_qs(.mem_rwd(1)));

      // - D2H
      D2HREQ    : if (!sptr)
                    return (check_c2h_qs(.cache_dat(1)));
                  else
                    return (check_c2h_qs(.cache_rsp(1)) ||
                            check_c2h_qs(.cache_rsp(2)) ||
                            check_c2h_qs(.cache_dat(1)) ||
                            check_c2h_qs(.cache_dat(1), .cache_rsp(1)) ||
                            check_c2h_qs(.cache_rsp(1)));

      D2HDAT    : if (!sptr)
                    return (check_c2h_qs(.cache_rsp(1)) ||
                            check_c2h_qs(.cache_rsp(2)) ||
                            check_c2h_qs(.cache_rsp(1), .mem_ndr(1)) ||
                            check_c2h_qs(.cache_rsp(2), .mem_ndr(1)) ||
                            check_c2h_qs(.mem_ndr(1)) ||
                            check_c2h_qs(.cache_req(1)) ||
                            check_c2h_qs(.cache_dat(1)) ||
                            check_c2h_qs(.cache_dat(2)) ||
                            check_c2h_qs(.cache_dat(3)) ||
                            check_c2h_qs(.cache_rsp(1), .cache_dat(1)) ||
                            check_c2h_qs(.cache_rsp(1), .cache_dat(2)) ||
                            check_c2h_qs(.cache_rsp(1), .cache_dat(3)));
                  else
                    return (check_c2h_qs(.cache_req(1)) ||
                            check_c2h_qs(.cache_req(1), .cache_rsp(1)) ||
                            check_c2h_qs(.cache_rsp(1)) ||
                            check_c2h_qs(.cache_dat(1)) ||
                            check_c2h_qs(.cache_dat(2)) ||
                            check_c2h_qs(.cache_dat(3)));

      D2HRSP    : if (!sptr)
                    return (check_c2h_qs(.cache_dat(1)) ||
                            check_c2h_qs(.cache_dat(1), .mem_ndr(1)) ||
                            check_c2h_qs(.mem_ndr(1)) ||
                            check_c2h_qs(.cache_rsp(1)) ||
                            check_c2h_qs(.cache_rsp(1), .cache_dat(1)) ||
                            check_c2h_qs(.cache_rsp(1), .cache_dat(1), .mem_ndr(1)) ||
                            check_c2h_qs(.cache_rsp(1), .mem_ndr(1)) ||
                            check_c2h_qs(.cache_dat(1)) ||
                            check_c2h_qs(.cache_dat(2)) ||
                            check_c2h_qs(.cache_dat(3)) ||
                            check_c2h_qs(.cache_dat(4)));
                  else
                    return (check_c2h_qs(.cache_req(1)) ||
                            check_c2h_qs(.cache_req(1), .cache_rsp(1)) ||
                            check_c2h_qs(.cache_rsp(1)) ||
                            check_c2h_qs(.cache_req(1), .cache_dat(1)) ||
                            check_c2h_qs(.cache_dat(1)));

      /* CXL.mem */
      // - M2S
      M2SREQ    : if (!sptr) 
                    return 0;
                  else 
                    return (check_h2c_qs(.cache_dat(1)));

      M2SRWD    : if (!sptr) 
                    return 0;
                  else 
                    return (check_h2c_qs(.cache_rsp(1)));
      // - S2M
      S2MDRS    : if (!sptr) 
                    return (check_c2h_qs(.mem_ndr(1)) ||
                            check_c2h_qs(.mem_drs(1)));
                  else 
                    return (check_c2h_qs(.mem_ndr(1)) ||
                            check_c2h_qs(.mem_ndr(2)) ||
                            check_c2h_qs(.mem_drs(1)) ||
                            check_c2h_qs(.mem_drs(2)));

      S2MNDR    : if (!sptr) 
                    return (check_c2h_qs(.cache_dat(1)) ||
                            check_c2h_qs(.cache_dat(1), .cache_rsp(1)) ||
                            check_c2h_qs(.cache_dat(1), .cache_rsp(2)) ||
                            check_c2h_qs(.cache_rsp(1)) ||
                            check_c2h_qs(.cache_rsp(2)) ||
                            check_c2h_qs(.mem_drs(1)) ||
                            check_c2h_qs(.mem_ndr(1)));
                  else 
                    return (check_c2h_qs(.mem_drs(1)) ||
                            check_c2h_qs(.mem_drs(1), .mem_ndr(1)) ||
                            check_c2h_qs(.mem_ndr(1)));

      default : return 0; // VCS will fatal on `uvm_fatal due to function in constraint
    endcase
  endfunction

  function bit grp_avail(e_txn_type this_txn);
    // Per-flit maximums from CXL 3.1 Section 4.2.5 
    case(this_txn)
      H2DREQ : return (fc_h2dreq < 2);
      H2DDAT : return (fc_h2ddat < 4);
      H2DRSP : return (fc_h2drsp < 4);
      D2HREQ : return (fc_d2hreq < 4);
      D2HDAT : return (fc_d2hdat < 4);
      D2HRSP : return (fc_d2hrsp < 2);
      M2SREQ : return (fc_m2sreq < 2);
      M2SRWD : return (fc_m2srwd < 1);
      S2MDRS : return (fc_s2mdrs < 3);
      S2MNDR : return (fc_s2mndr < 2);
      default : return 0;
    endcase
  endfunction

  // This function is called to fully resolve MDH availability by potentially
  // randomizing the object at the head of the shared queue. Randomizing the
  // object takes members inside it that may be 'x and assigns them to valid
  // values, which is a feature of the object itself.
  function void mdh_resolve();
    // D2HDAT
    if (p_sequencer.shr.d2hdat_q.size && p_sequencer.shr.d2hdat_q[0].be==='x)
    begin
      void'(p_sequencer.shr.d2hdat_q[0].randomize with 
            // Enhancement: need to support split chunks. remove this
            // "with" constraint when split chunks are supported in 
            // this sequence 
            {p_sequencer.shr.d2hdat_q[0].txfer_64B==1'b1;});
   end
   // H2DDAT : Enhancement: need to support splits
 //if (p_sequencer.shr.h2ddat_q.size && p_sequencer.shr.h2ddat_q[0].txfer_64B==='x)
 //   void'(p_sequencer.shr.h2ddat_q[0].randomize);
   // S2MDRS : Enhancement: need to support splits
 //if (p_sequencer.shr.s2mdrs_q.size && p_sequencer.shr.s2mdrs_q[0].txfer_64B==='x)
 //   void'(p_sequencer.shr.s2mdrs_q[0].randomize);
  endfunction

  // An MDH slot, per CXL spec, MUST contain only 64B, non-BE txns (in flit 
  // header, BE=0 and SZ=1). Thus, when a slot is randomly getting filled with
  // contents, an MDH can only be selected if the 1st txn and every subsequent
  // txn is NOT split and NOT BE. This applies to the only txn types that must 
  // support split and/or BE with MDH slot formats:
  // H2DDAT : BE
  // D2HDAT : BE and SPLIT
  // S2MDRS : SPLIT
  function bit mdh_avail(e_txn_type this_txn);
    case(this_txn)
      D2HDAT  : begin
                  // 1st txn makes no limitation
                  if (!d2hdat_q.size) return 1;
                  // Check if previous and next are NOT BE
                  return (d2hdat_q[$].be==='1 && 
                          p_sequencer.shr.d2hdat_q.size &&
                          p_sequencer.shr.d2hdat_q[0].be==='1);
                    // Enhancement: needs to support splits
                end
      H2DDAT  : return 1; // Enhancement: needs to support BE
      S2MDRS  : return 1; // Enhancement: needs to support splits
      default : return 0; // nonsensical: no other types are MDH
    endcase
  endfunction

  function bit any_avail();
    if (&{q_avail(H2DREQ),crd_avail(H2DREQ),slt_avail(H2DREQ),grp_avail(H2DREQ)}) 
    begin
      return 1;
    end
    if (&{q_avail(H2DDAT),crd_avail(H2DDAT),slt_avail(H2DDAT),grp_avail(H2DDAT),mdh_avail(H2DDAT)})
    begin
      return 1;
    end
    if (&{q_avail(H2DRSP),crd_avail(H2DRSP),slt_avail(H2DRSP),grp_avail(H2DRSP)}) 
    begin
      return 1;
    end
    if (&{q_avail(D2HREQ),crd_avail(D2HREQ),slt_avail(D2HREQ),grp_avail(D2HREQ)}) 
    begin
      return 1;
    end
    if (&{q_avail(D2HDAT),crd_avail(D2HDAT),slt_avail(D2HDAT),grp_avail(D2HDAT),mdh_avail(D2HDAT)})
    begin
      return 1;
    end
    if (&{q_avail(D2HRSP),crd_avail(D2HRSP),slt_avail(D2HRSP),grp_avail(D2HRSP)}) 
    begin
      return 1;
    end
    if (&{q_avail(M2SREQ),crd_avail(M2SREQ),slt_avail(M2SREQ),grp_avail(M2SREQ)}) 
    begin
      return 1;
    end
    if (&{q_avail(M2SRWD),crd_avail(M2SRWD),slt_avail(M2SRWD),grp_avail(M2SRWD)}) 
    begin
      return 1;
    end
    if (&{q_avail(S2MDRS),crd_avail(S2MDRS),slt_avail(S2MDRS),grp_avail(S2MDRS),mdh_avail(S2MDRS)})
    begin
      return 1;
    end
    if (&{q_avail(S2MNDR),crd_avail(S2MNDR),slt_avail(S2MNDR),grp_avail(S2MNDR)}) 
    begin
      return 1;
    end
    // Default
    return 0;
  endfunction

  /**** PRIMARIES ****/
  function new(string name = "flit68_mst_qpacker_seq");
    super.new(name);
  endfunction

  virtual task body();
    int        dd; // 16B chunk index into dat_q[0].dat (0-3 for 64B, 0-1 for 32B; +1 for G0_BE)

    flit = flit68_txn::type_id::create("flit");
    flit.flitmode = F68;
    flit.dir      = p_sequencer.cfg.dir;

    // This sequence services the shared-object queues forever, until stopped...
    forever begin

      // Wait for available transactions and credits to send a flit, or if there are dangling data words to send
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
          (q_avail(S2MDRS  ) && (p_sequencer.shr.avl_dat_credit[MEM])) ||
          (q_avail(S2MNDR  ) && (p_sequencer.shr.avl_rsp_credit[MEM])) ||
          (dat_q.size() > 0)
        ) break;
        @(posedge p_sequencer.vif.clk);
      end

      // Initialize each flit
      flit = flit.new_flit;

      // Clear the flit counters; which are used to make sure flit maxes aren't
      // exceeded
      clear_fc();

      // Snapshot the current credit count, used within the flit to make 
      // sure credits aren't over-consumed
      current_credit[CCH][cREQ] = p_sequencer.shr.avl_req_credit[CCH];
      current_credit[CCH][cDAT] = p_sequencer.shr.avl_dat_credit[CCH];
      current_credit[CCH][cRSP] = p_sequencer.shr.avl_rsp_credit[CCH];
      current_credit[MEM][cREQ] = p_sequencer.shr.avl_req_credit[MEM];
      current_credit[MEM][cDAT] = p_sequencer.shr.avl_dat_credit[MEM];
      current_credit[MEM][cRSP] = p_sequencer.shr.avl_rsp_credit[MEM];

      /**** Per-Flit Loop ****/
      while (1) begin

        // Clear the local queues, only contains transactions for 1 slot at a time
        clear_qs();

        // Clear the slot counters, counts are only valid for the current slot
        clear_scs();

        sfull = 0;
        
        /**** Per-Slot Loop ****/
        while (!sfull) begin

          // We may need to fully resolve a txn in the head of a shared queue
          // to determine if we pack it in an MDH, so we will randomize it in
          // the shared queue itself.
          mdh_resolve();

          // Randomization is designed to only occur when ANY valid txn
          // is possible to pack, so we catch the pre-determined packing
          // conditions like a DATA slot or any "can't pack" conditions, 
          // which are dependent on 4 things: credit availability, flit
          // packing max, txn availability, and slot packing max.
          if ((flit.pRollover+flit.pRollover_be)>=4 || (sptr && dat_q.size()))
            r_tt = DATA; 
          else if (!any_avail)
            r_tt = NONE;
          else if (!this.randomize()) begin
            `uvm_fatal("RAND_FAIL", "Randomization of flit68_mst_qpacker_seq failed")
          end

          case(r_tt)
            /** New TXN Slot **/
            // Randomizing allows for the TXN that is on the queue to not yet be fully filled out
            // and this sequence just handles it.
            H2DREQ    : begin
              h2dreq = p_sequencer.shr.pop_h2dreq();
              void'(h2dreq.randomize());
              h2dreq_q.push_back(h2dreq);
              fc_h2dreq++;
              current_credit[CCH][cREQ]--;
              txn_count[CCH][cREQ]++;
              sc_h2dreq++;
            end
            H2DDAT    : begin
              h2ddat = p_sequencer.shr.pop_h2ddat();
              // "randomize with" constraint based on Split 32B configuration
              if (p_sequencer.cfg.split_32B_disable) begin
                void'(h2ddat.randomize with {h2ddat.txfer_64B==1'b1;});
                if (!h2ddat.txfer_64B)
                  `uvm_fatal(get_type_name, "32B txfers not supported in sequence")
              end
              else begin
                `uvm_fatal(get_type_name, "32B txfers not supported in sequence")
                void'(h2ddat.randomize);
              end
              if (h2ddat.txfer_64B==1'b0) begin
                `uvm_fatal(get_type_name, "32B txfers not supported in sequence")
              end
              h2ddat_q.push_back(h2ddat);
              fc_h2ddat++;
              current_credit[CCH][cDAT]--;
              txn_count[CCH][cDAT]++;
              sc_h2ddat++;
            end
            H2DRSP    : begin
              h2drsp = p_sequencer.shr.pop_h2drsp();
              void'(h2drsp.randomize());
              h2drsp_q.push_back(h2drsp);
              fc_h2drsp++;
              current_credit[CCH][cRSP]--;
              txn_count[CCH][cRSP]++;
              sc_h2drsp++;
            end
            D2HREQ    : begin
              d2hreq = p_sequencer.shr.pop_d2hreq();
              void'(d2hreq.randomize());
              d2hreq_q.push_back(d2hreq);
              fc_d2hreq++;
              current_credit[CCH][cREQ]--;
              txn_count[CCH][cREQ]++;
              sc_d2hreq++;
            end
            D2HDAT    : begin
              d2hdat = p_sequencer.shr.pop_d2hdat();
              // "randomize with" constraint based on Split 32B configuration
              if (p_sequencer.cfg.split_32B_disable) begin
                void'(d2hdat.randomize with {d2hdat.txfer_64B==1'b1;});
                if (!d2hdat.txfer_64B)
                  `uvm_fatal(get_type_name, "32B txfers not supported in sequence")
              end
              else begin
                `uvm_fatal(get_type_name, "32B txfers not supported in sequence")
                void'(d2hdat.randomize);
              end
              if (d2hdat.txfer_64B==1'b0) begin
                `uvm_fatal(get_type_name, "32B txfers not supported in sequence")
              end
              d2hdat_q.push_back(d2hdat);
              fc_d2hdat++;
              current_credit[CCH][cDAT]--;
              txn_count[CCH][cDAT]++;
              sc_d2hdat++;
            end
            D2HRSP    : begin
              d2hrsp = p_sequencer.shr.pop_d2hrsp();
              void'(d2hrsp.randomize());
              d2hrsp_q.push_back(d2hrsp);
              fc_d2hrsp++;
              current_credit[CCH][cRSP]--;
              txn_count[CCH][cRSP]++;
              sc_d2hrsp++;
            end
            M2SREQ    : begin
              m2sreq = p_sequencer.shr.pop_m2sreq();
              void'(m2sreq.randomize());
              m2sreq_q.push_back(m2sreq);
              fc_m2sreq++;
              current_credit[MEM][cREQ]--;
              txn_count[MEM][cREQ]++;
              sc_m2sreq++;
            end
            M2SRWD    : begin
              m2srwd = p_sequencer.shr.pop_m2srwd();
              void'(m2srwd.randomize);
              m2srwd_q.push_back(m2srwd);
              fc_m2srwd++;
              txn_count[MEM][cDAT]++;
              current_credit[MEM][cDAT]--;
              sc_m2srwd++;
            end
            S2MDRS    : begin
              s2mdrs = p_sequencer.shr.pop_s2mdrs();
              // "randomize with" constraint based on Split 32B configuration
              if (p_sequencer.cfg.split_32B_disable) begin
                void'(s2mdrs.randomize with {s2mdrs.txfer_64B==1'b1;});
                if (!s2mdrs.txfer_64B)
                  `uvm_fatal(get_type_name, "32B txfers not supported in sequence")
              end
              else begin
                `uvm_fatal(get_type_name, "32B txfers not supported in sequence")
                void'(s2mdrs.randomize);
              end
              if (s2mdrs.txfer_64B==1'b0) begin
                `uvm_fatal(get_type_name, "32B txfers not supported in sequence")
              end
              s2mdrs_q.push_back(s2mdrs);
              fc_s2mdrs++;
              current_credit[MEM][cDAT]--;
              txn_count[MEM][cDAT]++;
              sc_s2mdrs++;
            end
            S2MNDR    : begin
              s2mndr = p_sequencer.shr.pop_s2mndr();
              void'(s2mndr.randomize());
              s2mndr_q.push_back(s2mndr);
              fc_s2mndr++;
              current_credit[MEM][cRSP]--;
              txn_count[MEM][cRSP]++;
              sc_s2mndr++;
            end

            /** DATA Slot **/
            DATA      : sfull = 1; // DATA slots are always exactly one slot wide

            /** NONE: slot at max, flit at max, no credits, no txns **/
            NONE      : sfull = 1; // slot will be zero-filled in Per-Slot Pack

            /** Error Handling **/
            default   : `uvm_fatal(get_type_name(), "body() per-slot loop > an unsupported TXN Type was passed.")
          endcase

        end // while(!sfull)

        /**** Per-Slot Pack ****/
        begin : per_slot_pack
          h0_f68 h0; h1_f68 h1; h2_f68 h2; h3_f68 h3; h4_f68 h4; 
          h5_f68 h5; h6_f68 h6; 
          g0_f68 g0; g1_f68 g1; g2_f68 g2; g3_f68 g3; g4_f68 g4;
          g5_f68 g5; g6_f68 g6; g0be_f68 g0be;

          // DATA slots
          if (r_tt == DATA) begin : DATA_SLOTS
            `uvm_info(get_type_name(), $sformatf("dat_q has %0d TXNs in it.", dat_q.size()), UVM_DEBUG)
            print_slot_info(sptr, $sformatf("%s DATA %0d", dat_q[0].txn_type, dd));
            if (dat_q[0].txn_type == "H2D_DAT") begin : PACK_H2DDAT_DW
              h2ddat_c hdat; $cast(hdat, dat_q[0]);
              g0      = g0_f68::type_id::create("g0");
              g0.dir  = flit.dir;
              g0.data = hdat.dat[128*dd+:128];
              flit.slot[sptr] = g0;
              if (dd == (hdat.txfer_64B ? 3 : 1)) begin void'(dat_q.pop_front()); dd = 0; end
              else                                      dd++;
            end
            else if (dat_q[0].txn_type == "D2H_DAT") begin : PACK_D2HDAT_DW
              d2hdat_c ddat; $cast(ddat, dat_q[0]);
              if (dd == 4) begin
                g0be      = g0be_f68::type_id::create("g0be");
                g0be.dir  = flit.dir;
                g0be.data = {64'h0,ddat.be};
                flit.slot[sptr] = g0be;
              end else begin
                g0      = g0_f68::type_id::create("g0");
                g0.dir  = flit.dir;
                g0.data = ddat.dat[128*dd+:128];
                flit.slot[sptr] = g0;
              end
              if (dd == 4 || (dd == 3 && ddat.be == '1)) begin
                void'(dat_q.pop_front()); // Discard the top of the queue; fully sent
                dd = 0;
              end else dd++;
            end
            else if (dat_q[0].txn_type == "M2S_RWD") begin : PACK_M2SRWD_DW
              m2srwd_c rwd; $cast(rwd, dat_q[0]);
              if (dd == 4) begin
                g0be      = g0be_f68::type_id::create("g0be");
                g0be.dir  = flit.dir;
                g0be.data = {64'h0,rwd.be};
                flit.slot[sptr] = g0be;
              end else begin
                g0      = g0_f68::type_id::create("g0");
                g0.dir  = flit.dir;
                g0.data = rwd.dat[128*dd+:128];
                flit.slot[sptr] = g0;
              end
              if (dd == 4 || (dd == 3 && rwd.be == '1)) begin
                void'(dat_q.pop_front()); // Discard the top of the queue; fully sent
                dd = 0;
              end else dd++;
            end
            else if (dat_q[0].txn_type == "S2M_DRS") begin : PACK_S2MDRS_DW
              s2mdrs_c drs; $cast(drs, dat_q[0]);
              g0      = g0_f68::type_id::create("g0");
              g0.dir  = flit.dir;
              g0.data = drs.dat[128*dd+:128];
              flit.slot[sptr] = g0;
              if (dd == (drs.txfer_64B ? 3 : 1)) begin void'(dat_q.pop_front()); dd = 0; end
              else                                     dd++;
            end
            else begin
              `uvm_fatal("DATA_NO_DECODE", $sformatf("Transaction %s type doesn't contain a DATA payload.", dat_q[0].txn_type))
            end
          end
          /* PROTOCOL slots */
          else if (!sptr) begin : HEADER_SLOTS
            // H2C Transactions
            case (1'b1)
              |sc_m2sreq              : pack_h2c_h5;
              |sc_m2srwd              : pack_h2c_h4;
              sc_h2ddat>1             : pack_h2c_h3;
              sc_h2drsp>1             : pack_h2c_h1;
              sc_h2dreq&&sc_h2ddat    : pack_h2c_h2;
              sc_h2drsp==1&&sc_h2ddat : pack_h2c_h1;
              sc_h2dreq&&sc_h2drsp    : pack_h2c_h0;
              // if we've gotten here, there's a randomization needed between
              // multiple slot formats - H0/H1 (h2drsp), H1/H2 (h2ddat), H0/H2 (h2dreq)
              // - because there exists more than one valid packing option
              |sc_h2drsp : if ($urandom_range(1)) pack_h2c_h1;
                           else                   pack_h2c_h0;
              |sc_h2ddat : if ($urandom_range(1)) pack_h2c_h2;
                           else                   pack_h2c_h1;
              |sc_h2dreq : if ($urandom_range(1)) pack_h2c_h2;
                           else                   pack_h2c_h0;
            endcase
            // C2H Transactions
            case (1'b1)
              sc_s2mndr>1             : pack_c2h_h4;
              sc_s2mdrs>1             : pack_c2h_h5;
              |sc_s2mdrs              : pack_c2h_h3;
              sc_d2hrsp>1             : pack_c2h_h0;
              sc_d2hdat>1             : pack_c2h_h2;
              |sc_d2hreq              : pack_c2h_h1;
              sc_d2hdat&&sc_s2mndr    : pack_c2h_h0;
              sc_d2hrsp&&sc_s2mndr    : pack_c2h_h0;
              sc_d2hrsp               : pack_c2h_h0;
              // if we've gotten here, there's a randomization needed between
              // multiple slot formats - H0/H1 (D2HDAT), H0/H3/H4 (S2MNDR) -
              // - because there exists more than one valid packing option
              |sc_d2hdat : if ($urandom_range(1)) pack_c2h_h0;
                           else                   pack_c2h_h1;
              |sc_s2mndr : case ($urandom_range(2))
                             0 : pack_c2h_h0;
                             1 : pack_c2h_h3;
                             2 : pack_c2h_h4;
                           endcase
            endcase

          end 
          else begin : GENERIC_SLOTS
            case (1'b1)
              // H2C Transactions
              sc_h2drsp>1          : pack_h2c_g1;
              sc_h2ddat>1          : pack_h2c_g3;
              |sc_m2srwd           : pack_h2c_g5;
              |sc_m2sreq           : pack_h2c_g4;
              |sc_h2dreq           : pack_h2c_g2;
              sc_h2ddat&&sc_h2drsp : pack_h2c_g2;
              // if we've gotten here, there's a randomization needed between
              // multiple slot formats - G2/G4 (H2DDAT), G2/G5 (D2HRSP) -
              // - because there exists more than one valid packing option
              |sc_h2ddat : if ($urandom_range(1)) pack_h2c_g2;
                           else                   pack_h2c_g4;
              |sc_h2drsp : if ($urandom_range(1)) pack_h2c_g2;
                           else                   pack_h2c_g5;
              // C2H Transactions
              sc_s2mdrs>1          : pack_c2h_g6;
              |sc_s2mdrs           : pack_c2h_g4;
              sc_d2hrsp>1          : pack_c2h_g1;
              sc_d2hdat>1          : pack_c2h_g3;
              |sc_d2hdat           : pack_c2h_g2;
              // if we've gotten here, there's a randomization needed between
              // multiple slot formats - G1/G2 (D2HREQ, D2HRSP), G4/G5 (S2MNDR) -
              // - because there exists more than one valid packing option
              sc_d2hreq||sc_d2hrsp : if ($urandom_range(1)) pack_c2h_g1;
                                     else                   pack_c2h_g2;
              |sc_s2mndr           : if ($urandom_range(1)) pack_c2h_g4;
                                     else                   pack_c2h_g5;
            endcase
          end

          if (sptr==3) begin
            sptr++;
            break;
          end
          else 
            sptr++;

        end // begin : per_slot_pack

      end // while (1) with break -> while (sptr < 4)

      if(
        (current_credit[CCH][cREQ] == p_sequencer.shr.avl_req_credit[CCH][cREQ]) &&
        (current_credit[CCH][cDAT] == p_sequencer.shr.avl_dat_credit[CCH][cDAT]) &&
        (current_credit[CCH][cRSP] == p_sequencer.shr.avl_rsp_credit[CCH][cRSP]) &&
        (current_credit[MEM][cREQ] == p_sequencer.shr.avl_req_credit[MEM][cREQ]) &&
        (current_credit[MEM][cDAT] == p_sequencer.shr.avl_dat_credit[MEM][cDAT]) &&
        (current_credit[MEM][cRSP] == p_sequencer.shr.avl_rsp_credit[MEM][cRSP])
      ) `uvm_fatal(get_type_name(), "All current and original credit counts are exactly the same, something is wrong");

      // Push Flit onto Base Queue
      flit.pack_flit();
      flit_q.push_back(flit);

      // Send the Flit
      super.body();

      // Increment Flit Counter
      total_flit_count++;

    end // forever begin
  endtask

  /**** LOWER-LEVELS ****/
  function void print_slot_info(int slotnumber, string slotinfo);
    // Print the slot packing info
    `uvm_info(get_type_name(), $sformatf("Slot %02d - %s", slotnumber, slotinfo), UVM_HIGH)
  endfunction

  function void clear_qs();
    string msg;
    if (!check_h2c_qs() || !check_c2h_qs()) begin
      if (sc_h2dreq) msg = {msg.len?{msg,", "}:"", $sformatf("h2dreq=%0d", sc_h2dreq)};
      if (sc_h2ddat) msg = {msg.len?{msg,", "}:"", $sformatf("h2ddat=%0d", sc_h2ddat)};
      if (sc_h2drsp) msg = {msg.len?{msg,", "}:"", $sformatf("h2drsp=%0d", sc_h2drsp)};
      if (sc_d2hreq) msg = {msg.len?{msg,", "}:"", $sformatf("d2hreq=%0d", sc_d2hreq)};
      if (sc_d2hdat) msg = {msg.len?{msg,", "}:"", $sformatf("d2hdat=%0d", sc_d2hdat)};
      if (sc_d2hrsp) msg = {msg.len?{msg,", "}:"", $sformatf("d2hrsp=%0d", sc_d2hrsp)};
      if (sc_m2sreq) msg = {msg.len?{msg,", "}:"", $sformatf("m2sreq=%0d", sc_m2sreq)};
      if (sc_m2srwd) msg = {msg.len?{msg,", "}:"", $sformatf("m2srwd=%0d", sc_m2srwd)};
      if (sc_s2mdrs) msg = {msg.len?{msg,", "}:"", $sformatf("s2mdrs=%0d", sc_s2mdrs)};
      if (sc_s2mndr) msg = {msg.len?{msg,", "}:"", $sformatf("s2mndr=%0d", sc_s2mndr)};
      `uvm_fatal(get_type_name(), {"New slot determination started, but local queue(s) from previous slot still have txns: ", msg});

    end

    h2dreq_q = {}; h2drsp_q = {}; h2ddat_q = {};
    d2hreq_q = {}; d2hrsp_q = {}; d2hdat_q = {};
    m2sreq_q = {}; m2srwd_q = {};
    s2mdrs_q = {}; s2mndr_q = {};
  endfunction

  function void clear_scs();
    // These counters are only used for printing packing information...
    sc_h2dreq = 0; sc_h2drsp = 0; sc_h2ddat = 0;
    sc_d2hreq = 0; sc_d2hrsp = 0; sc_d2hdat = 0;
    sc_m2sreq = 0; sc_m2srwd = 0;
    sc_s2mdrs = 0; sc_s2mndr = 0;
  endfunction

  function void clear_fc();
    fc_h2dreq = '{default: 0}; fc_h2ddat = '{default: 0}; fc_h2drsp = '{default: 0};
    fc_d2hreq = '{default: 0}; fc_d2hdat = '{default: 0}; fc_d2hrsp = '{default: 0}; 
    fc_m2sreq = '{default: 0}; fc_m2srwd = '{default: 0}; 
    fc_s2mdrs = '{default: 0}; fc_s2mndr = '{default: 0};
  endfunction

  // Due to the complex nature of F68 packing, this is a convenience function
  // to check if the qs have EXACTLY this amount of elements in them. A 'x is
  // a don't care for that element. This is h2c (host-2-card) so this only
  // handles H2D and M2S txns.
  function bit check_h2c_qs(
    logic cache_req=0, logic [2:0] cache_dat=0, logic [1:0] cache_rsp=0,
    logic   mem_req=0, logic         mem_rwd=0
  );
    return (cache_req==='x || cache_req==h2dreq_q.size) &&
           (cache_dat==='x || cache_dat==h2ddat_q.size) &&
           (cache_rsp==='x || cache_rsp==h2drsp_q.size) &&
           (  mem_req==='x ||   mem_req==m2sreq_q.size) &&
           (  mem_rwd==='x ||   mem_rwd==m2srwd_q.size);
  endfunction

  // Due to the complex nature of F68 packing, this is a convenience function
  // to check if the qs have EXACTLY this amount of elements in them. A 'x is
  // a don't care for that element. This is c2h (card-2-host) so this only
  // handles D2H and S2M txns.
  function bit check_c2h_qs(
    logic     cache_req=0, logic [2:0] cache_dat=0, logic [1:0] cache_rsp=0,
    logic [1:0] mem_ndr=0, logic [1:0] mem_drs=0
  );
    return (cache_req==='x || cache_req==d2hreq_q.size) &&
           (cache_dat==='x || cache_dat==d2hdat_q.size) &&
           (cache_rsp==='x || cache_rsp==d2hrsp_q.size) &&
           (  mem_ndr==='x ||   mem_ndr==s2mndr_q.size) &&
           (  mem_drs==='x ||   mem_drs==s2mdrs_q.size);
  endfunction

  /**** Slot Type Packers ****/
  /** H2C **/
  function void pack_h2c_h0();
    h0_f68 h0 = h0_f68::type_id::create("h0");
    h0.create_objects(flit.dir, {1'b1>>(1-sc_h2drsp),1'b1>>(1-sc_h2dreq)});
    // 1x CXL.cache REQ
    if (sc_h2dreq) begin
      h0.h2dreq_h = h2dreq_q.pop_front();
    end
    // 1x CXL.cache RSP
    if (sc_h2drsp) begin
      h0.h2drsp_h = h2drsp_q.pop_front();
    end
    void'(h0.randomize);
    void'(h0.pack_slot);
    flit.slot[sptr] = h0;
    print_slot_info(sptr, $sformatf("H0 [%0d H2DREQ + %0d H2DRSP]", sc_h2dreq, sc_h2drsp));
  endfunction

  function void pack_h2c_h1();
    h1_f68 h1 = h1_f68::type_id::create("h1");
    h1.create_objects(flit.dir, {2'b11>>(2-sc_h2drsp),1'b1>>(1-sc_h2ddat)});
    // 1x CXL.cache DAT
    if (sc_h2ddat) begin
      h1.h2ddat_h   = h2ddat_q[0];
      dat_q.push_back(h2ddat_q.pop_front()); // TODO Split Mode
    end
    // 2x CXL.cache RSP
    foreach (h1.h2drsp_h[ii]) begin
      if (ii < sc_h2drsp) begin
        h1.h2drsp_h[ii] = h2drsp_q.pop_front();
      end
    end
    void'(h1.randomize);
    void'(h1.pack_slot);
    flit.slot[sptr] = h1;
    print_slot_info(sptr, $sformatf("H1 [%0d H2DDAT + %0d H2DRSP]", sc_h2ddat, sc_h2drsp));
  endfunction

  function void pack_h2c_h2();
    h2_f68 h2 = h2_f68::type_id::create("h2");
    h2.create_objects(flit.dir, {1'b1>>(1-sc_h2ddat),1'b1>>(1-sc_h2dreq)});
    // 1x CXL.cache REQ
    if (sc_h2dreq) begin
      h2.h2dreq_h = h2dreq_q.pop_front();
    end
    // 1x CXL.cache DAT
    if (sc_h2ddat) begin
      h2.h2ddat_h = h2ddat_q[0];
      dat_q.push_back(h2ddat_q.pop_front()); // TODO support split mode
    end
    void'(h2.randomize);
    void'(h2.pack_slot);
    flit.slot[sptr] = h2;
    print_slot_info(sptr, $sformatf("H2 [%0d H2DREQ + %0d H2DDAT]", sc_h2dreq, sc_h2ddat));
  endfunction

  function void pack_h2c_h3();
    h3_f68 h3 = h3_f68::type_id::create("h3");
    h3.create_objects(flit.dir, 4'hf>>(4-sc_h2ddat));
    // 4x CXL.cache DAT
    foreach (h3.h2ddat_h[ii]) begin
      if (ii<sc_h2ddat) begin
        h3.h2ddat_h[ii] = h2ddat_q[0];
        dat_q.push_back(h2ddat_q.pop_front()); // TODO Split Mode
      end 
    end
    void'(h3.randomize);
    void'(h3.pack_slot);
    flit.slot[sptr] = h3;
    print_slot_info(sptr, $sformatf("H3 [%0d H2DDAT]", sc_h2ddat));
  endfunction

  function void pack_h2c_h4();
    h4_f68 h4 = h4_f68::type_id::create("h4");
    h4.create_objects(flit.dir, {1'b1>>(1-sc_m2srwd)});
    // 1x CXL.mem REQ
    if (sc_m2srwd) begin
      h4.m2srwd_h = m2srwd_q[0];
      dat_q.push_back(m2srwd_q.pop_front());
    end 
    void'(h4.randomize);
    void'(h4.pack_slot);
    flit.slot[sptr] = h4;
    print_slot_info(sptr, $sformatf("H4 [%0d M2SRWD]", sc_m2srwd));
  endfunction

  function void pack_h2c_h5();
    h5_f68 h5 = h5_f68::type_id::create("h5");
    h5.create_objects(flit.dir, {1'b1>>(1-sc_m2sreq)});
    // 1x CXL.mem REQ
    if (sc_m2sreq) begin
      h5.m2sreq_h = m2sreq_q.pop_front();
    end 
    void'(h5.randomize);
    void'(h5.pack_slot);
    flit.slot[sptr] = h5;
    print_slot_info(sptr, $sformatf("H5 [%0d M2SREQ]", sc_m2sreq));
  endfunction

  function void pack_h2c_g1();
    g1_f68 g1 = g1_f68::type_id::create("g1");
    g1.create_objects(flit.dir, 4'hf>>(4-sc_h2drsp));
    // 4x CXL.cache RSP
    foreach (g1.h2drsp_h[ii]) begin
      if (ii < sc_h2drsp) begin
        g1.h2drsp_h[ii] = h2drsp_q.pop_front();
      end 
    end
    void'(g1.randomize);
    void'(g1.pack_slot);
    flit.slot[sptr] = g1;
    print_slot_info(sptr, $sformatf("G1 [%0d H2DRSP]", sc_h2drsp));
  endfunction

  function void pack_h2c_g2();
    g2_f68 g2 = g2_f68::type_id::create("g2");
    g2.create_objects(flit.dir, {1'b1>>(1-sc_h2drsp), 1'b1>>(1-sc_h2ddat), 1'b1>>(1-sc_h2dreq)});
    // 1x CXL.cache REQ
    if (sc_h2dreq) begin
      g2.h2dreq_h = h2dreq_q.pop_front();
    end 
    // 1x CXL.cache DAT
    if (sc_h2ddat) begin
      g2.h2ddat_h = h2ddat_q[0];
      dat_q.push_back(h2ddat_q.pop_front());
    end 
    // 1x CXL.cache RSP
    if (sc_h2drsp) begin
      g2.h2drsp_h = h2drsp_q.pop_front();
    end 
    void'(g2.randomize);
    void'(g2.pack_slot);
    flit.slot[sptr] = g2;
    print_slot_info(sptr, $sformatf("G2 [%0d H2DREQ + %0d H2DDAT + %0d H2DRSP]", sc_h2dreq, sc_h2ddat, sc_h2drsp));
  endfunction

  function void pack_h2c_g3();
    g3_f68 g3 = g3_f68::type_id::create("g3");
    g3.create_objects(flit.dir, {1'b1>>(1-sc_h2drsp), 4'hf>>(4-sc_h2ddat)});
    // 4x CXL.cache DAT
    foreach (g3.h2ddat_h[ii]) begin
      if (ii < sc_h2ddat) begin
        g3.h2ddat_h[ii] = h2ddat_q[0];
        dat_q.push_back(h2ddat_q.pop_front());
      end
    end
    // 1x CXL.cache RSP
    if (sc_h2drsp) begin
      g3.h2drsp_h = h2drsp_q.pop_front();
    end 
    void'(g3.randomize);
    void'(g3.pack_slot);
    flit.slot[sptr] = g3;
    print_slot_info(sptr, $sformatf("G3 [%0d H2DDAT + %0d H2DRSP]", sc_h2ddat, sc_h2drsp));
  endfunction

  function void pack_h2c_g4();
    g4_f68 g4 = g4_f68::type_id::create("g4");
    g4.create_objects(flit.dir, {1'b1>>(1-sc_h2ddat), 1'b1>>(1-sc_m2sreq)});
    // 1x CXL.mem REQ
    if (sc_m2sreq) begin
      g4.m2sreq_h = m2sreq_q.pop_front();
    end
    // 1x CXL.cache DAT
    if (sc_h2ddat) begin
      g4.h2ddat_h = h2ddat_q[0];
      dat_q.push_back(h2ddat_q.pop_front());
    end 
    void'(g4.randomize);
    void'(g4.pack_slot);
    flit.slot[sptr] = g4;
    print_slot_info(sptr, $sformatf("G4 [%0d M2SREQ + %0d H2DDAT]", sc_m2sreq, sc_h2ddat));
  endfunction

  function void pack_h2c_g5();
    g5_f68 g5 = g5_f68::type_id::create("g5");
    g5.create_objects(flit.dir, {1'b1>>(1-sc_h2drsp), 1'b1>>(1-sc_m2srwd)});
    // 1x CXL.mem DAT
    if (sc_m2srwd) begin
      g5.m2srwd_h = m2srwd_q[0];
      dat_q.push_back(m2srwd_q.pop_front());
    end 
    // 1x CXL.mem RSP
    if (sc_h2drsp) begin
      g5.h2drsp_h = h2drsp_q.pop_front();
    end 
    void'(g5.randomize);
    void'(g5.pack_slot);
    flit.slot[sptr] = g5;
    print_slot_info(sptr, $sformatf("G5 [%0d M2SRWD + %0d H2DRSP]", sc_m2srwd, sc_h2drsp));
  endfunction

  /** C2H **/
  function void pack_c2h_h0();
    h0_f68 h0 = h0_f68::type_id::create("h0");
    h0.create_objects(flit.dir, {1'b1>>(1-sc_s2mndr),2'b11>>(2-sc_d2hrsp),1'b1>>(1-sc_d2hdat)});
    // 1x CXL.cache DAT
    if (sc_d2hdat) begin
      h0.d2hdat_h = d2hdat_q[0];
      dat_q.push_back(d2hdat_q.pop_front()); // TODO Split Mode
    end 
    // 2x CXL.cache RSP
    foreach (h0.d2hrsp_h[ii]) begin
      if (ii < sc_d2hrsp) begin
        h0.d2hrsp_h[ii] = d2hrsp_q.pop_front();
      end 
    end
    // 1x CXL.mem RSP
    if (sc_s2mndr) begin
      h0.s2mndr_h = s2mndr_q.pop_front();
    end 
    void'(h0.randomize);
    void'(h0.pack_slot);
    flit.slot[sptr] = h0;
    print_slot_info(sptr, $sformatf("H0 [%0d D2HDAT + %0d D2HRSP + %0d S2MNDR]", sc_d2hdat, sc_d2hrsp, sc_s2mndr));
  endfunction

  function void pack_c2h_h1();
    h1_f68 h1 = h1_f68::type_id::create("h1");
    h1.create_objects(flit.dir, {1'b1>>(1-sc_d2hdat), 1'b1>>(1-sc_d2hreq)});
    // 1x CXL.cache REQ
    if (sc_d2hreq) begin
      h1.d2hreq_h = d2hreq_q.pop_front();
    end 
    // 1x CXL.cache DAT
    if (sc_d2hdat) begin
      h1.d2hdat_h   = d2hdat_q[0];
      dat_q.push_back(d2hdat_q.pop_front()); // TODO Split Mode
    end 
    void'(h1.randomize);
    void'(h1.pack_slot);
    flit.slot[sptr] = h1;
    print_slot_info(sptr, $sformatf("H1 [%0d D2HREQ + %0d D2HDAT]", sc_d2hreq, sc_d2hdat));
  endfunction

  function void pack_c2h_h2();
    h2_f68 h2 = h2_f68::type_id::create("h2");
    h2.create_objects(flit.dir, {1'b1>>(1-sc_d2hrsp),4'hf>>(4-sc_d2hdat)});
    // 4x CXL.cache DAT
    foreach (h2.d2hdat_h[ii]) begin
      if (ii < sc_d2hdat) begin
        h2.d2hdat_h[ii] = d2hdat_q[0];
        dat_q.push_back(d2hdat_q.pop_front()); // TODO Split Mode
      end 
    end
    // 1x CXL.cache RSP
    if (sc_d2hrsp) begin
      h2.d2hrsp_h = d2hrsp_q.pop_front();
    end 
    void'(h2.randomize);
    void'(h2.pack_slot);
    flit.slot[sptr] = h2;
    print_slot_info(sptr, $sformatf("H2 [%0d D2HDAT + %0d D2HRSP]", sc_d2hdat, sc_d2hrsp));
  endfunction

  function void pack_c2h_h3();
    h3_f68 h3 = h3_f68::type_id::create("h3");
    h3.create_objects(flit.dir, {1'b1>>(1-sc_s2mndr), 1'b1>>(1-sc_s2mdrs)});
    // 1x CXL.mem DAT
    if (sc_s2mdrs) begin
      h3.s2mdrs_h = s2mdrs_q[0];
      dat_q.push_back(s2mdrs_q.pop_front()); // TODO Split Mode
    end
    // 1x CXL.mem RSP
    if (sc_s2mndr) begin
      h3.s2mndr_h = s2mndr_q.pop_front();
    end 
    void'(h3.randomize);
    void'(h3.pack_slot);
    flit.slot[sptr] = h3;
    print_slot_info(sptr, $sformatf("H3 [%0d S2MDRS + %0d S2MNDR]", sc_s2mdrs, sc_s2mndr));
  endfunction

  function void pack_c2h_h4();
    h4_f68 h4 = h4_f68::type_id::create("h4");
    h4.create_objects(flit.dir, {2'b11>>(2-sc_s2mndr)});
    // 2x CXL.mem RSP
    foreach (h4.s2mndr_h[ii]) begin
      if (ii < sc_s2mndr) begin
        h4.s2mndr_h[ii] = s2mndr_q.pop_front();
      end 
    end
    void'(h4.randomize);
    void'(h4.pack_slot);
    flit.slot[sptr] = h4;
    print_slot_info(sptr, $sformatf("H4 [%0d S2MNDR]", sc_s2mndr));
  endfunction

  function void pack_c2h_h5();
    h5_f68 h5 = h5_f68::type_id::create("h5");
    h5.create_objects(flit.dir, {2'b11>>(2-sc_s2mdrs)});
    // 2x CXL.mem DAT
    foreach (h5.s2mdrs_h[ii]) begin
      if (ii < sc_s2mdrs) begin
        h5.s2mdrs_h[ii] = s2mdrs_q[0];
        dat_q.push_back(s2mdrs_q.pop_front()); // TODO Split Mode
      end 
    end
    void'(h5.randomize);
    void'(h5.pack_slot);
    flit.slot[sptr] = h5;
    print_slot_info(sptr, $sformatf("h5 [%0d S2MDRS]", sc_s2mndr));
  endfunction

  function void pack_c2h_g1();
    g1_f68 g1 = g1_f68::type_id::create("g1");
    g1.create_objects(flit.dir, {2'b11>>(2-sc_d2hrsp),1'b1>>(1-sc_d2hreq)});
    if (sc_d2hreq) begin
      g1.d2hreq_h = d2hreq_q.pop_front();
    end
    foreach (g1.d2hrsp_h[ii]) begin
      if (ii < sc_d2hrsp) begin
        g1.d2hrsp_h[ii] = d2hrsp_q.pop_front();
      end
    end
    void'(g1.randomize);
    void'(g1.pack_slot);
    flit.slot[sptr] = g1;
    print_slot_info(sptr, $sformatf("G1 [%0d D2HREQ + %0d D2HRSP]", sc_d2hreq, sc_d2hrsp));
  endfunction

  function void pack_c2h_g2();
    g2_f68 g2 = g2_f68::type_id::create("g2");
    g2.create_objects(flit.dir, {1'b1>>(1-sc_d2hrsp),1'b1>>(1-sc_d2hdat),1'b1>>(1-sc_d2hreq)});
    if (sc_d2hreq) begin
      g2.d2hreq_h = d2hreq_q.pop_front();
    end
    if (sc_d2hdat) begin
      g2.d2hdat_h = d2hdat_q[0];
      dat_q.push_back(d2hdat_q.pop_front()); // TODO Split Mode
    end 
    if (sc_d2hrsp) begin
      g2.d2hrsp_h = d2hrsp_q.pop_front();
    end
    void'(g2.randomize);
    void'(g2.pack_slot);
    flit.slot[sptr] = g2;
    print_slot_info(sptr, $sformatf("G2 [%0d D2HREQ + %0d D2HDAT + %0d D2HRSP]", sc_d2hreq, sc_d2hdat, sc_d2hrsp));
  endfunction

  function void pack_c2h_g3();
    g3_f68 g3 = g3_f68::type_id::create("g3");
    g3.create_objects(flit.dir, {4'hf>>(4-sc_d2hdat)});
    foreach (g3.d2hdat_h[ii]) begin
      if (ii < sc_d2hdat) begin
        g3.d2hdat_h[ii] = d2hdat_q[0];
        dat_q.push_back(d2hdat_q.pop_front()); // TODO Split Mode
      end
    end
    void'(g3.randomize);
    void'(g3.pack_slot);
    flit.slot[sptr] = g3;
    print_slot_info(sptr, $sformatf("G3 [%0d D2HDAT]", sc_d2hdat));
  endfunction

  function void pack_c2h_g4();
    g4_f68 g4 = g4_f68::type_id::create("g4");
    g4.create_objects(flit.dir, {2'b11>>(2-sc_s2mndr), 1'b1>>(1-sc_s2mdrs)});
    if (sc_s2mdrs) begin
      g4.s2mdrs_h = s2mdrs_q[0];
      dat_q.push_back(s2mdrs_q.pop_front()); // TODO Split Mode
    end 
    foreach (g4.s2mndr_h[ii]) begin
      if (ii < sc_s2mndr) begin
        g4.s2mndr_h[ii] = s2mndr_q.pop_front();
      end
    end
    void'(g4.randomize);
    void'(g4.pack_slot);
    flit.slot[sptr] = g4;
    print_slot_info(sptr, $sformatf("G4 [%0d S2MDRS + %0d S2MNDR]", sc_s2mdrs, sc_s2mndr));
  endfunction

  function void pack_c2h_g5();
    g5_f68 g5 = g5_f68::type_id::create("g5");
    g5.create_objects(flit.dir, {2'b11>>(2-sc_s2mndr)});
    foreach (g5.s2mndr_h[ii]) begin
      if (ii < sc_s2mndr) begin
        g5.s2mndr_h[ii] = s2mndr_q.pop_front();
      end
    end
    void'(g5.randomize);
    void'(g5.pack_slot);
    flit.slot[sptr] = g5;
    print_slot_info(sptr, $sformatf("G5 [%0d S2MNDR]", sc_s2mndr));
  endfunction

  function void pack_c2h_g6();
    g6_f68 g6 = g6_f68::type_id::create("g6");
    g6.create_objects(flit.dir, {3'b111>>(3-sc_s2mdrs)});
    foreach (g6.s2mdrs_h[ii]) begin
      if (ii < sc_s2mdrs) begin
        g6.s2mdrs_h[ii] = s2mdrs_q[0];
        dat_q.push_back(s2mdrs_q.pop_front()); // TODO Split Mode
      end
    end
    void'(g6.randomize);
    void'(g6.pack_slot);
    flit.slot[sptr] = g6;
    print_slot_info(sptr, $sformatf("G6 [%0d S2MDRS]", sc_s2mdrs));
  endfunction

endclass
