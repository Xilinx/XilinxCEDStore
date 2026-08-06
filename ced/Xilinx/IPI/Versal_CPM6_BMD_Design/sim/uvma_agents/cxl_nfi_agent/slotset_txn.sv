class slotset_txn extends uvm_object;

  `uvm_object_utils(slotset_txn)

  // a 128b slot can be any of these
  typedef union packed {
    // Slot 0 is special (H-Slot)
    struct packed {
      struct packed {
        logic [107:0] data;
        logic [  3:0] fmt;
      } hslot;
      logic [ 15:0] hdr;
    } s0;
    // Slot 15 is special (PHY layer)
    struct packed {
      logic [47:0] fec; 
      logic [63:0] crc;
      logic [15:0] crd;
    } s15;
    // Slot 7 is special when LOpt 256B flit
    struct packed {
      logic [47:0] crc;
      struct packed {
        logic [75:0] data_lo;
        logic [ 3:0] fmt;
      } gslot;
    } s7_lopt;
    // Slot 8 is special when Lopt 256B flit
    struct packed {
      logic [47:0] s7_data_hi;
      struct packed {
        logic [ 75:0] data_lo;
        logic [  3:0] fmt;
      } hsslot;  
    } s8_lopt;
    // Slot 15 is special when Lopt 256B flit
    struct packed {
      logic [47:0] crc; 
      logic [47:0] fec;
      logic [15:0] s8_data_hi;
      logic [15:0] crd;
    } s15_lopt;
    // Easy slicing for any G-slot
    struct packed {
      logic [123:0] data;
      logic [  3:0] fmt;
    } gslot;
  } u_slot_t;

  typedef union packed {
    // Raw
    logic [511:0] raw;
    // Easily identified slots in a slotset
    u_slot_t [3:0] slot;
  } u_data_t;

  dir_t         dir;

  u_data_t      data;
  logic [  7:0] parity;
  logic         viral;
  logic         valid;
  logic         ready;
  logic [  3:0] dec_sop;
  logic [  3:0] dec_eop;
  logic [  3:0] dec_be;
  logic [  3:0] dec_mem;

  // Slot objects that contain txns
  slot_base_f256 slot[0:3];
  slot_base_f256 lower_slot; //ptr=s15->s8, s8->s7

  // Identifiers
  bit [1:0]   slotset;
  flit_mode_t flitmode;

  // Carryover metadata from previous slotset
  int pRollover;
  int pRollover_sop[$:7];
  int pRollover_eop[$:7];
  bit pRollover_trp[$:7];
  bit pRollover_mem[$:7];
  int pReq_consumed[1:0];
  int pDat_consumed[1:0];
  int pRsp_consumed[1:0];
  // Output metadata from this slotset
  int rollover;
  int rollover_sop[$:7];
  int rollover_eop[$:7];
  bit rollover_trp[$:7];
  bit rollover_mem[$:7];
  int req_consumed[1:0];
  int dat_consumed[1:0];
  int rsp_consumed[1:0];

  function new(string name = "slotset_txn");
    super.new(name);
  endfunction

  // This function goes from raw bits to slot objects with supporting metadata.
  // All slots will be handled in order from lowest to highest in the flit (0->15)
  // unless there is rollover
  virtual function void unpack();

    int         ii;
    int         jj;
    logic [3:0] fmt;
    int         sn; //sn="slot number (of the flit)" [0-15]
    int         sp; //sp="slot pointer (of the slotset)"; [0-3]

    // Copy over rollover from previous slotset to initialize
    rollover     = pRollover;
    rollover_sop = pRollover_sop;
    rollover_eop = pRollover_eop;
    rollover_trp = pRollover_trp;
    rollover_mem = pRollover_mem;

    // Iterate over each slot in time order 
    for (sp=0; sp<4; sp++) begin
      sn = slotset*4+sp;
      // Slot 15 is a special case; for PHY
      if (sn==15) begin
        s15_phy s15 = s15_phy::type_id::create("s15");
        s15.lower_slot = flitmode==F256_LOPT ? lower_slot : null;
        s15.unpack_slot(flitmode, sn, data.slot[sp]);
        slot[sp] = s15; 
      end
      // This conditional means its not implicit data or trailer
      else if (sn==0 || (sn==8&&flitmode==F256_LOPT) || rollover==0) begin
        fmt = sn==0 ? data.slot[sn].s0.hslot.fmt : data.slot[sp].gslot.fmt;
        case (fmt)
          'd0 :  begin
                   m0_hbr m0 = m0_hbr::type_id::create("m0");
                   m0.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m0.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m0;
                 end 
          'd1 :  begin
                   m1_hbr m1 = m1_hbr::type_id::create("m1");
                   m1.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m1.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m1;
                 end 
          'd2 :  begin
                   m2_hbr m2 = m2_hbr::type_id::create("m2");
                   m2.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m2.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m2;
                 end 
          'd3 :  begin
                   m3_hbr m3 = m3_hbr::type_id::create("m3");
                   m3.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m3.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m3;
                 end 
          'd4 :  begin
                   m4_hbr m4 = m4_hbr::type_id::create("m4");
                   m4.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m4.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m4;
                 end 
          'd5 :  begin
                   m5_hbr m5 = m5_hbr::type_id::create("m5");
                   m5.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m5.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m5;
                 end 
          'd6 :  begin
                   m6_hbr m6 = m6_hbr::type_id::create("m6");
                   m6.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m6.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m6;
                 end 
          'd7 :  begin
                   m7_hbr m7 = m7_hbr::type_id::create("m7");
                   m7.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m7.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m7;
                 end 
          'd8 :  begin
                   m8_hbr m8 = m8_hbr::type_id::create("m8");
                   m8.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m8.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m8;
                 end 
          'd9 :  begin
                   m9_hbr m9 = m9_hbr::type_id::create("m9");
                   m9.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m9.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m9;
                 end 
          'd10 : begin
                   m10_hbr m10 = m10_hbr::type_id::create("m10");
                   m10.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m10.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m10;
                 end 
          'd11 : begin
                   m11_hbr m11 = m11_hbr::type_id::create("m11");
                   m11.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m11.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m11;
                 end 
          'd12 : begin
                   m12_hbr m12 = m12_hbr::type_id::create("m12");
                   m12.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m12.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m12;
                   // Check to make sure Hslot packing didn't exceed flit packing rules
                   if (sn==0 && rollover>16 && slot[0].dat_consumed.sum>0)
                     `uvm_error(get_type_name, "Spec violation: DHs packed into Hslot when rollover was >16")
                   check_add_rollover(m12);
                 end 
          'd13 : begin
                   m13_hbr m13 = m13_hbr::type_id::create("m13");
                   m13.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m13.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m13;
                   // Check to make sure Hslot packing didn't exceed flit packing rules
                   if (sn==0 && rollover>16 && slot[0].dat_consumed.sum>0)
                     `uvm_error(get_type_name, "Spec violation: DHs packed into Hslot when rollover was >16")
                   check_add_rollover(m13);
                 end 
          'd14 : begin
                   m14_hbr m14 = m14_hbr::type_id::create("m14");
                   m14.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m14.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m14;
                   // Check to make sure Hslot packing didn't exceed flit packing rules
                   if (sn==0 && rollover>16 && slot[0].dat_consumed.sum>0)
                     `uvm_error(get_type_name, "Spec violation: DHs packed into Hslot when rollover was >16")
                   check_add_rollover(m14);
                 end 
          'd15 : begin
                   m15_hbr m15 = m15_hbr::type_id::create("m15");
                   m15.lower_slot = sn==8&&flitmode==F256_LOPT ? lower_slot : null;
                   m15.unpack_slot(flitmode, sn, data.slot[sp]);
                   slot[sp] = m15;
                   // Check to make sure Hslot packing didn't exceed flit packing rules
                   if (sn==0 && rollover>16 && slot[0].dat_consumed.sum>0)
                     `uvm_error(get_type_name, "Spec violation: DHs packed into Hslot when rollover was >16")
                   check_add_rollover(m15);
                 end 
        endcase
        // Must handle S7-upper if it's an HS-Slot
        if (sn==8 && flitmode==F256_LOPT)
          check_add_lopt_rollover(slot[sp]);
        // Check to make sure rollover max is never exceeded, which would
        // mean something went terribly wrong somewhere
        if (rollover>36)
          `uvm_error(get_type_name, $sformatf("rollover=%0d detected; max CXL spec. allowed=36",rollover))
      end
      // Implicit trailer (the trp queue head is 1)
      else if (rollover && rollover_eop[0]==1 && rollover_trp[0]==1) begin
        f256_trailer trlr = f256_trailer::type_id::create("trlr");
        trlr.data = data.slot[sp];
        slot[sp] = trlr;
        // Decrement the rollover and pop supporting fields of mem/trp
        rollover--;
        foreach (rollover_sop[kk]) rollover_sop[kk]--;
        foreach (rollover_eop[kk]) rollover_eop[kk]--;
        void'(rollover_sop.pop_front); 
        void'(rollover_eop.pop_front); 
        void'(rollover_trp.pop_front); 
        void'(rollover_mem.pop_front); 
      end
      // Implicit data 
      else begin
        f256_data dat = f256_data::type_id::create("dat");
        dat.data = data.slot[sp];
        slot[sp] = dat;
        // Decrement the rollover
        rollover--;
        foreach (rollover_sop[kk]) rollover_sop[kk]--;
        foreach (rollover_eop[kk]) rollover_eop[kk]--;
        // Pop supporting fields on eop 
        if (!rollover_eop[0]) begin
          void'(rollover_sop.pop_front); 
          void'(rollover_eop.pop_front); 
          void'(rollover_trp.pop_front); 
          void'(rollover_mem.pop_front); 
        end
      end
    end

    // Assign slotset credits consumed
    for (ii=0; ii<2; ii++) begin 
      for (jj=0; jj<(slotset==3?3:4); jj++) begin
        req_consumed[ii] += slot[jj].req_consumed[ii];
        dat_consumed[ii] += slot[jj].dat_consumed[ii];
        rsp_consumed[ii] += slot[jj].rsp_consumed[ii];
      end
    end

    // Check the maximum message rules (always)
    check_max_msg_rules();

  endfunction

  // This function takes slot objects and packs it into data, randomly filling
  // open slots (objects with null handles) with randomized empty slots.
  virtual function void pack(slot_base_f256 sa=null, sb=null, sc=null, sd=null);
    int       ii;
    int       jj;
    int       sn; //sn="slot number (of the flit)" [0-15]
    int       sp; //sp="slot pointer (of the slotset)"; [0-3]
    s15_phy   s15;
    bit [3:0] fmt;

    // Copy over rollover from previous slotset to initialize
    rollover     = pRollover;
    rollover_sop = pRollover_sop;
    rollover_eop = pRollover_eop;
    rollover_trp = pRollover_trp;
    rollover_mem = pRollover_mem;

    /* Provide slot object handles if provided, else randomize them */
    for (sp=0; sp<4; sp++) begin
      sn = slotset*4+sp;
      // S15 is special case ; dedicated to PHY
      if (sn==15) begin
        s15 = s15_phy::type_id::create("s15");
        void'(s15.pack_phy(flitmode));
        slot[sp] = s15;
      end
      else begin
        case (sp)
          0 : slot[0] = sa!=null ? sa : create_empty_slot(sn);
          1 : slot[1] = sb!=null ? sb : create_empty_slot(sn);
          2 : slot[2] = sc!=null ? sc : create_empty_slot(sn);
          3 : slot[3] = sd!=null ? sd : create_empty_slot(sn);
        endcase
      end
    end

    // Go from slot objects to actual bits
    foreach (slot[ii]) data.slot[ii] = slot[ii].data;

    // Set other fields on interface
    valid  = 1'b1;
    viral  = 1'b0;

    // Generate parity
    foreach (slot[ii]) begin
      parity[ii*2+0] = ^(slot[ii].data[ 0+:64]);
      parity[ii*2+1] = ^(slot[ii].data[64+:64]);
    end

    // Generate the decode assists
    {dec_sop, dec_eop, dec_be, dec_mem} = '0;
    foreach(slot[ii]) begin
      // Skip over PHY slot
      if (slot[ii].slot_num == 15) break;
      // On a data slot, we need to decrement rollover and potentially drive
      // one or more decode assists 
      if (slot[ii]._fmt inside {_D, _T}) begin
        if (rollover_sop[0] == 1) begin 
          dec_sop[ii] = rollover_sop.pop_front; 
          dec_mem[ii] = rollover_mem.pop_front;
        end
        if (rollover_eop[0] == 1) begin 
          dec_eop[ii] = rollover_eop.pop_front;
          dec_be [ii] = rollover_trp.pop_front;
        end
        // Then decrement counters
        rollover--;
        foreach (rollover_sop[ii]) rollover_sop[ii]--;
        foreach (rollover_eop[ii]) rollover_eop[ii]--;
      end
      // When we get a data header slot, need to add rollover
      else begin
        case (1'b1)
          slot[ii].is_hslot  : fmt = slot[ii].data.hslot.fmt;
          slot[ii].is_hsslot : fmt = slot[ii].data.hsslot.fmt;
          slot[ii].is_gslot  : fmt = slot[ii].data.gslot.fmt;
        endcase
        // Check and add rollover
        if (fmt inside {[12:15]})
          check_add_rollover(slot[ii]);
        // HS-Slots needed to handle rollover carefully
        if (slot[ii].is_hsslot)
          check_add_lopt_rollover(slot[ii]);
      end
    end

    // Assign slotset credits consumed
    for (ii=0; ii<2; ii++) begin 
      for (jj=0; jj<4; jj++) begin
        req_consumed[ii] += slot[jj].req_consumed[ii];
        dat_consumed[ii] += slot[jj].dat_consumed[ii];
        rsp_consumed[ii] += slot[jj].rsp_consumed[ii];
      end
    end

    // Check the maximum message rules (always)
    check_max_msg_rules();
    
  endfunction

  // Check the given slot if it adds to rollover and modify this classes
  // members if so
  virtual function void check_add_rollover(slot_base_f256 s);
    bit [3:0] fmt;
    int       ii;
    case (1'b1)
      s.is_hslot  : fmt = s.data.hslot.fmt;
      s.is_hsslot : fmt = s.data.hsslot.fmt;
      s.is_gslot  : fmt = s.data.gslot.fmt;
    endcase
    case (fmt)
      'd12 : 
      begin
        m12_hbr m12;
        $cast(m12, s);
        // Calculate rollover 
        for (ii=0; ii<((m12.is_gslot&&!m12.is_s7_lopt)?4:3); ii++) begin
          if (m12.h2ddat_hdr[ii].val) begin
            rollover_sop.push_back(rollover+1);
            rollover_eop.push_back(rollover+4);
            rollover_trp.push_back(1'b0);
            rollover_mem.push_back(1'b0);
            rollover += 4;
          end
        end
      end
      'd13 : 
      begin
        m13_hbr m13;
        $cast(m13, s);
        // Calculate rollover 
        for (ii=0; ii<4; ii++) begin
          if (m13.d2hdat_hdr[ii].val) begin
            rollover_sop.push_back(rollover+1);
            rollover_eop.push_back(rollover+4+m13.bep[ii]);
            rollover_trp.push_back(m13.bep[ii]);
            rollover_mem.push_back(1'b0);
            rollover += (4+m13.bep[ii]);
          end
        end
      end
      'd14 : 
      begin
        m14_hbr m14;
        $cast(m14, s);
        // Calculate rollover
        if (m14.m2srwd_hdr.val) begin
          rollover_sop.push_back(rollover+1);
          rollover_eop.push_back(rollover+4+m14.trp);
          rollover_trp.push_back(m14.trp);
          rollover_mem.push_back(1'b1);
          rollover += (4+m14.trp);
        end 
      end
      'd15 : 
      begin
        m15_hbr m15;
        $cast(m15, s);
        // Calculate rollover (sn=0 can add to already present rollover)
        if (m15.s2mdrs_hdr[0].val) begin                 
          rollover_sop.push_back(rollover+1);
          rollover_eop.push_back(rollover+4+|m15.trp);
          rollover_trp.push_back(|m15.trp);
          rollover_mem.push_back(1'b1);
          rollover += (4+|m15.trp);
        end
        if (m15.s2mdrs_hdr[1].val) begin 
          rollover_sop.push_back(rollover+1);
          rollover_eop.push_back(rollover+4);
          rollover_trp.push_back(1'b0);
          rollover_mem.push_back(1'b1);
          rollover += 4;
        end
        if (m15.is_gslot && !m15.is_s7_lopt && m15.s2mdrs_hdr[2].val) begin
          rollover_sop.push_back(rollover+1);
          rollover_eop.push_back(rollover+4);
          rollover_trp.push_back(1'b0);
          rollover_mem.push_back(1'b1);
          rollover += 4;
        end
      end
    endcase
  endfunction

  // S8-LOpt can annoyingly add addl. rollover that isn't accounted for when 
  // you handle each slot incrementally in time because S7-upper comes AFTER
  // S8-lower in time, but S7 comes BEFORE S8 when looking at ordering.
  virtual function void check_add_lopt_rollover(slot_base_f256 hs);
    int         i_loc; //i_loc="insert location"
    int         l_loc; //l_loc="last location (i_loc minus one)"
    bit  [47:0] upper;
    bit  [ 3:0] lfmt; //lfmt = "lower fmt"
    int         ii;

    upper = hs.get_split_upper;
    lfmt  = hs.lower_slot.data.gslot.fmt;    

    case (1'b1)
      // Ex: S7=M12 (12,{1,5,9},{4,8,12}) 
      //     S8=M14 (17,{1,5,9,13},{4,8,12,17})
      //     upper> (21,{1,5,9,13,17},{4,8,12,16,21})
      // Ex: S7=M12 (12,{1,5,9},{4,8,12}) 
      //     S8=N/A (12,{1,5,9},{4,8,12})
      //     upper> (16,{1,5,9,13},{4,8,12,16})
      (lfmt==12 && upper[8]) : //H2D-DH[3] valid
      begin
        i_loc = hs.lower_slot.dat_consumed[1];
        l_loc = i_loc-1;
        rollover_sop.insert(i_loc, rollover_eop[l_loc]+1);
        rollover_eop.insert(i_loc, rollover_sop[i_loc]+3);
        rollover_trp.insert(i_loc, 1'b0);
        rollover_mem.insert(i_loc, 1'b0);
        rollover += 4;
        // Shift if S8 had DHs in it, otherwise we just pushed back
        for (ii=i_loc+1; ii<rollover_sop.size; ii++) begin
          rollover_sop[ii] += 4;
          rollover_eop[ii] += 4;
        end
      end
      // There never actually exists a case where S8-LOpt has DHs in it and 
      // S8-upper has BEP present because that would be a violation of flit
      // packing rules. After S7-lower is "sent," the TX would have a rollover 
      // of minimum 16 because valid must be packed tightly e.g. 4'b1011 is
      // invalid, thus we don't have to modify the trp queue in place, but
      // may only have to push onto it.
      // Ex: S7=M12 (16,{1,5,9,13},{4,8,12,16})
      //     S8=N/A (16,{1,5,9,13},{4,8,12,16})
      //     upper> (17,{1,5,9,13},{4,8,12,17})
      // Ex: S7=M12 (19,{1,6,11,16},{5,10,15,19})
      //     S8=N/A (19,{1,6,11,16},{5,10,15,19})
      //     upper> (20,{1,6,11,16},{5,10,15,20})
      (lfmt==13 && hs.lower_slot.data[76] && upper[11]) : 
      begin
        rollover_eop[$-1] += 1;
        rollover_trp[$-1] = 1;
        rollover += 1;
      end
      // This is the most complex case because you can get a valid txn AND 
      // a TRP in the upper portion.
      // Ex: Add 3rd (no prev TRP)
      //     S7=M15 (8, {1,5},{4,8})                   //2 txns, wo TRP
      //     S8=M15 (17,{1,5,9,14},{4,8,13,17})        //2 txns, w TRP
      //     upper> (21,{1,5,9,13,18}),{4,8,12,17,21}) //Add 3rd to S7
      // Ex: Add 3rd (prev TRP)
      //     S7=M15 (9, {1,6},{5,9})                    //2 txns, w TRP
      //     S8=M15 (18,{1,6,10,15},{5,9,14,18})        //2 txns, w TRP
      //     upper> (22,{1,6,10,14,19}),{5,9,13,18,22}) //Add 3rd to S7
      // Ex: Add 3rd+TRP (no prev TRP)
      //     S7=M15 (8, {1,5},{4,8})                    //2 txns, wo TRP
      //     S8=M15 (16,{1,5,9,13},{4,8,12,16})         //2 txns, wo TRP
      //     upper> (21,{1,6,10,14,18}),{5,9,13,17,21}) //Add 3rd+TRP to S7
      (lfmt==15 && upper[4]) : 
      begin
        m15_hbr m15;
        $cast(m15, hs.lower_slot);
        i_loc = m15.dat_consumed[0];
        l_loc = i_loc-1;
        if (!upper[35] || m15.trp[1:0]) begin //Add txn only; either no TRP or TRP already present
          rollover_sop.insert(i_loc, rollover_eop[l_loc]+1);
          rollover_eop.insert(i_loc, rollover_sop[i_loc]+3);
          rollover_trp.insert(i_loc, 1'b0);
          rollover_mem.insert(i_loc, 1'b1);
          rollover += 4;
          // Shift if S8 had DHs in it, otherwise we just pushed back
          for (ii=i_loc+1; ii<rollover_sop.size; ii++) begin
            rollover_sop[ii] += 4;
            rollover_eop[ii] += 4;
          end
        end
        else begin // Add txn and TRP
          // Modify all SOPs and EOPs to account for insertion of TRP
          for (ii=0; ii<rollover_sop.size; ii++) begin
            // All EOPs must change
            rollover_eop[ii] += 1;
            // All SOPs except first change
            rollover_sop[ii] += !ii ? 0 : 1;
          end
          rollover_trp[0] = 1'b1;
          rollover += 1;
          // Now insert txn
          rollover_sop.insert(i_loc, rollover_eop[l_loc]+1);
          rollover_eop.insert(i_loc, rollover_sop[i_loc]+3);
          rollover_trp.insert(i_loc, 1'b0);
          rollover_mem.insert(i_loc, 1'b1);
          rollover += 4;
          // Shift if S8 had DHs in it, otherwise we just pushed back
          for (ii=i_loc+1; ii<rollover_sop.size; ii++) begin
            rollover_sop[ii] += 4;
            rollover_eop[ii] += 4;
          end
        end
      end
    endcase
  endfunction

  // Create and then randomize an empty slot, returning it 
  virtual function slot_base_f256 create_empty_slot(int sn); 
    slot_fmt_t r_slot_fmt;  

    // - Can't pack an empty slot with DHs
    // - H2C should only pack 0,1,4,5, C2H should only pack 2,3,6,7, 
    //   but it shouldn't matter if the slot is empty
    void'(std::randomize(r_slot_fmt) with { 
      dir==H2C -> r_slot_fmt inside {_HBR_M0, _HBR_M1, _HBR_M4, _HBR_M5}; 
      dir==C2H -> r_slot_fmt inside {_HBR_M2, _HBR_M3, _HBR_M6, _HBR_M7}; 
    });
                                                
    case(r_slot_fmt)
      _HBR_M0 : begin
                  m0_hbr m0 = m0_hbr::type_id::create("m0");
                  m0.create_objects(flitmode, sn, '0);
                  void'(m0.randomize);
                  void'(m0.pack_slot);
                  return m0;
                end
      _HBR_M1 : begin
                  m1_hbr m1 = m1_hbr::type_id::create("m1");
                  m1.create_objects(flitmode, sn, '0);
                  void'(m1.randomize);
                  void'(m1.pack_slot);
                  return m1;
                end
      _HBR_M2 : begin
                  m2_hbr m2 = m2_hbr::type_id::create("m2");
                  m2.create_objects(flitmode, sn, '0);
                  void'(m2.randomize);
                  void'(m2.pack_slot);
                  return m2;
                end
      _HBR_M3 : begin
                  m3_hbr m3 = m3_hbr::type_id::create("m3");
                  m3.create_objects(flitmode, sn, '0);
                  void'(m3.randomize);
                  void'(m3.pack_slot);
                  return m3;
                end
      _HBR_M4 : begin
                  m4_hbr m4 = m4_hbr::type_id::create("m4");
                  m4.create_objects(flitmode, sn, '0);
                  void'(m4.randomize);
                  void'(m4.pack_slot);
                  return m4;
                end
      _HBR_M5 : begin
                  m5_hbr m5 = m5_hbr::type_id::create("m5");
                  m5.create_objects(flitmode, sn, '0);
                  void'(m5.randomize);
                  void'(m5.pack_slot);
                  return m5;
                end
      _HBR_M6 : begin
                  m6_hbr m6 = m6_hbr::type_id::create("m6");
                  m6.create_objects(flitmode, sn, '0);
                  void'(m6.randomize);
                  void'(m6.pack_slot);
                  return m6;
                end
      _HBR_M7 : begin
                  m7_hbr m7 = m7_hbr::type_id::create("m7");
                  m7.create_objects(flitmode, sn, '0);
                  void'(m7.randomize);
                  void'(m7.pack_slot);
                  return m7;
                end
    endcase
  endfunction

  // Check to make sure a slotset is tightly packed, meaning that there is no
  // empty slot followed by non-empty slot in a slotset
  virtual function void check_tightly_packed();
    bit [0:3] mpty; 
    mpty[0] = slot[0].empty_slot;
    mpty[1] = slot[1].empty_slot;
    mpty[2] = slot[2].empty_slot;
    mpty[3] = slot[3].empty_slot;
    // Don't look at PHY slot if slotset 3
    if (slotset==3) begin
      case (mpty[0:2]) inside
        3'b10? : `uvm_warning(get_type_name, $sformatf("Slotset 3 not tightly packed: empty_slot[0:2]=%b",mpty[0:2]))
        3'b?10 : `uvm_warning(get_type_name, $sformatf("Slotset 3 not tightly packed: empty_slot[0:2]=%b",mpty[0:2]))
      endcase 
    end
    // Slot0/Slot1 need not be tightly packed
    else if (slotset==0) begin
      case (mpty[1:3]) inside
        3'b10? : `uvm_warning(get_type_name, $sformatf("Slotset 0 not tightly packed: empty_slot[1:3]=%b",mpty[1:3]))
        3'b?10 : `uvm_warning(get_type_name, $sformatf("Slotset 0 not tightly packed: empty_slot[1:3]=%b",mpty[1:3]))
      endcase 
    end
    else begin
      case (mpty) inside
        4'b10?? : `uvm_warning(get_type_name, $sformatf("Slotset %0d not tightly packed: empty_slot[0:3]=%b",slotset,mpty))
        4'b?10? : `uvm_warning(get_type_name, $sformatf("Slotset %0d not tightly packed: empty_slot[0:3]=%b",slotset,mpty))
        4'b??10 : `uvm_warning(get_type_name, $sformatf("Slotset %0d not tightly packed: empty_slot[0:3]=%b",slotset,mpty))
      endcase 
    end
  endfunction

  // Check the maximum message rules, which apply on a 128B rolling group of
  // the 256B flit. Group CD is S8-S14, but LOpt-F256 has Group CD of S7-S14.
  // Parent object has to assign S7 credits consumed to p*_consumed.
  virtual function void check_max_msg_rules();
    // [mem, cache]
    int max_req_128B[1:0] = dir==H2C ? '{4, 2} : '{2, 4}; 
    int max_rsp_128B[1:0] = dir==H2C ? '{3, 6} : '{6, 4};
    int max_dhd_128B[1:0] = dir==H2C ? '{2, 4} : '{3, 4};
    for (int ii=0; ii<2; ii++) begin
      // REQ
      if (max_req_128B[ii] < (pReq_consumed[ii]+req_consumed[ii]))
        `uvm_error(get_type_name, $sformatf("Maximum %0s CXL.%0s REQ message limit violated: %0d consumed > %0d allowed",
                                            dir.name,
                                            !ii ? "cache" : "mem",
                                            pReq_consumed[ii]+req_consumed[ii],
                                            max_req_128B[ii]))
      // DAT
      if (max_dhd_128B[ii] < (pDat_consumed[ii]+dat_consumed[ii]))
        `uvm_error(get_type_name, $sformatf("Maximum %0s CXL.%0s DATA HDR message limit violated: %0d consumed > %0d allowed",
                                            dir.name,
                                            !ii ? "cache" : "mem",
                                            pDat_consumed[ii]+dat_consumed[ii],
                                            max_dhd_128B[ii]))
      // RSP
      if (max_rsp_128B[ii] < (pRsp_consumed[ii]+rsp_consumed[ii]))
        `uvm_error(get_type_name, $sformatf("Maximum %0s CXL.%0s RSP message limit violated: %0d consumed > %0d allowed",
                                            dir.name,
                                            !ii ? "cache" : "mem",
                                            pRsp_consumed[ii]+rsp_consumed[ii],
                                            max_rsp_128B[ii]))
    end   
  endfunction

  // This function is used to copy previous slotset metadata
  // that will be important for this slotset.
  virtual function void continue_flit(slotset_txn t);
    this.pRollover     = t.rollover;
    this.pRollover_sop = t.rollover_sop;
    this.pRollover_eop = t.rollover_eop;
    this.pRollover_trp = t.rollover_trp;
    this.pRollover_mem = t.rollover_mem;
    this.pReq_consumed = t.req_consumed;
    this.pDat_consumed = t.dat_consumed;
    this.pRsp_consumed = t.rsp_consumed;
  endfunction

endclass
