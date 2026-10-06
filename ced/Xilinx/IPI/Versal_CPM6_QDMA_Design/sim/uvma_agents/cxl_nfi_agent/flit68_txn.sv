class flit68_txn extends flit_base_txn;

  `uvm_object_utils(flit68_txn)

  // Pay attention to the ordering here
  // This union allows different ways to reference the same underlying data; easy slicing
  typedef union packed {
    // Raw
    logic [511:0] raw;
    // Slots
    logic [3:0][127:0] slot;
    // Flit header (protocol flits only)
    struct packed {
      logic [511:384] gslot3;
      logic [383:256] gslot2;
      logic [255:128] gslot1;
      logic [127: 32] hslot;
      flit68_hdr_t    hdr;
    } protocol;
    // Control flit (llctrl field) 
    struct packed {
      logic [511:36] other1;
      llctrl_t       llctrl;
      logic [ 31: 0] hdr;
    } control;
  } u_data_t;

  // Copied over directly from interface
  u_data_t      flit; //union for easier parsing
  logic [  7:0] parity;
  logic         viral;
  logic         valid;
  logic         ready;
  logic         adf;
  logic         last;
  logic [  3:0] dec_sop;
  logic [  3:0] dec_eop;
  logic [  3:0] dec_be;
  logic [  3:0] dec_mem;

  //unpack_flit converts raw bits to ext. objects
  //pack_flit can use these ext. objects to pack to flit member
  slot_base slot[3:0]; 

  /* Carryover from previous flit */
  int       pRollover;
  bit       pRollover_be;  //if set, BE is present
  bit       pAssist_mem;   //for decode assist, was the prev header CXL.mem
  /* Output rollover from this flit */
  bit       rollover_locked;
  int       rollover;
  bit       rollover_be;
  bit       assist_mem;

  function new(string name = "flit68_txn");
    super.new(name);
    txn_type = "FLIT68_TXN";
    flitmode = F68;
  endfunction

  /* The monitor calls this to go from raw slotset data (just bits) to slot objects
     that contain metadata for better/faster/easier parsing */
  virtual function void unpack_flit();

    bit g0_is_be;

    /* First, we handle rollover from previous flit(s) */
    // All data flit : Rollover >= 4
    if (pRollover >= 4) begin
      g0_f68 g0[0:3];
      foreach (g0[ii]) begin
        g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
        g0[ii].dir  = dir;
        g0[ii].data = flit.slot[ii];
        slot[ii] = g0[ii];
      end 
      rollover    = pRollover-4;
      rollover_be = (pRollover == 4 && pRollover_be);
      return;
    end
    // All data flit with BE; Rollover = 3, Rollover_BE = 1
    else if (pRollover == 3 && pRollover_be) begin //1,2,3,BE 
      g0be_f68  g0_be;
      g0_f68    g0[0:2]; 
      foreach (g0[ii]) begin
        g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
        g0[ii].dir  = dir;
        g0[ii].data = flit.slot[ii];
        slot[ii]    = g0[ii];
      end
      g0_be = g0be_f68::type_id::create("g0_be");
      g0_be.unpack_slot(dir, flit.slot[3]);
      slot[3] = g0_be;
      rollover    = 0;
      rollover_be = 1'b0;
      return;
    end
    /* Before moving on to protocol flits with rollover (not all data flit), handle control flits */
    else if (flit.protocol.hdr.Type == CONTROL) begin
      slot_rsvd rsvd[3:1];
      case(flit.control.llctrl)
        LLCRD   : begin
                    llcrd_f68 llcrd = llcrd_f68::type_id::create("llcrd");
                    llcrd.unpack_slot(dir, flit.slot[0]); 
                    slot[0] = llcrd;
                  end
        RETRY   : begin
                    retry_f68 retry = retry_f68::type_id::create("retry");
                    retry.unpack_slot(dir, flit.slot[0]); 
                    slot[0] = retry;
                  end
        IDE     : begin
                    ide_f68 ide = ide_f68::type_id::create("ide");
                    ide.unpack_slot(dir, flit.slot[0]); 
                    slot[0] = ide;
                  end
        INIT    : begin
                    init_f68 init = init_f68::type_id::create("init");
                    init.unpack_slot(dir, flit.slot[0]); 
                    slot[0] = init;
                  end
        default : `uvm_error(get_type_name, $sformatf("Invalid value 'b%b of llctrl", flit.control.llctrl))
      endcase
      foreach(rsvd[ii]) begin
        rsvd[ii]      = slot_rsvd::type_id::create($sformatf("rsvd[%0d]",ii));
        rsvd[ii].data = flit.slot[ii];
        rsvd[ii].check_rsvd();
        slot[ii] = rsvd[ii];
      end
      if (pRollover+pRollover_be >= 4)
        `uvm_error(get_type_name, "A control flit was received when an all data flit was expected")
      // Pass on the rollover untouched
      rollover    = pRollover;
      rollover_be = pRollover_be;
      return;
    end
    // Rollover that ends in this flit (not an all data flit)
    // Rollover inside {1,2,3}; potential Rollover_BE = 1 iff Rollover inside {1,2}
    else if (pRollover) begin
      g0be_f68  g0_be;
      g0_f68    g0[1:3]; 
      foreach (g0[ii]) begin
        g0[ii]      = g0_f68::type_id::create($sformatf("g0[%0d]",ii));
        g0[ii].dir  = dir;
        g0[ii].data = flit.slot[ii];
        slot[ii] = g0[ii];
        if (pRollover == ii)
          break;
      end
      // pRollover inside {1,2} and BE set
      if (pRollover_be) begin
        g0_be = g0be_f68::type_id::create("g0_be");
        g0_be.unpack_slot(dir, flit.slot[pRollover+1]);
        slot[pRollover+1] = g0_be;
      end
    end
    // Rollover = 0, but Rollover_BE = 1
    else if (pRollover_be) begin
      g0be_f68 g0_be = g0be_f68::type_id::create("g0_be");
      g0_be.unpack_slot(dir, flit.slot[1]);
      slot[1] = g0_be;
    end

    /* Now, handle header */
    case (flit.protocol.hdr.fmt.slot0)
      H0 : begin 
             h0_f68 h0 = h0_f68::type_id::create("h0");
             h0.unpack_slot(dir, flit.slot[0]);
             slot[0] = h0; 
             if (dir == H2C) begin
               rollover    = 0;
               rollover_be = 1'b0;
             end
             else begin
               g0_is_be = h0.d2hdat_hdr.val && (pRollover+pRollover_be==0) && !h0.hdr.sz && h0.hdr.be;
               if (!h0.hdr.sz) begin
                 rollover    = (pRollover+pRollover_be) <= 1 ?    0 : h0.d2hdat_hdr.val*(pRollover+pRollover_be-1);
                 rollover_be = (pRollover+pRollover_be) == 0 ? 1'b0 : h0.d2hdat_hdr.val*flit.protocol.hdr.be;
               end
               else begin
                 rollover    = h0.d2hdat_hdr.val*(4-3+(pRollover+pRollover_be));
                 rollover_be = h0.d2hdat_hdr.val*flit.protocol.hdr.be;
               end
             end
           end
      H1 : begin 
             h1_f68 h1 = h1_f68::type_id::create("h1");
             h1.unpack_slot(dir, flit.slot[0]);
             slot[0] = h1; 
             if (dir == H2C) begin
               rollover_be = 1'b0;
               if (!h1.hdr.sz) rollover = (pRollover+pRollover_be) <= 1 ? 0 : h1.h2ddat_hdr.val*(pRollover+pRollover_be-1);
               else            rollover = h1.h2ddat_hdr.val*(4-3+(pRollover+pRollover_be));
             end
             else begin
               g0_is_be = h1.d2hdat_hdr.val && (pRollover+pRollover_be==0) && !h1.hdr.sz && h1.hdr.be;
               if (!h1.hdr.sz) begin
                 rollover    = (pRollover+pRollover_be) <= 1 ?    0 : h1.d2hdat_hdr.val*(pRollover+pRollover_be-1);
                 rollover_be = (pRollover+pRollover_be) == 0 ? 1'b0 : h1.d2hdat_hdr.val*flit.protocol.hdr.be;
               end
               else begin
                 rollover    = h1.d2hdat_hdr.val*(4-3+(pRollover+pRollover_be));
                 rollover_be = h1.d2hdat_hdr.val*flit.protocol.hdr.be;
               end
             end
           end
      H2 : begin 
             h2_f68 h2 = h2_f68::type_id::create("h2");
             h2.unpack_slot(dir, flit.slot[0]);
             slot[0] = h2; 
             if (dir == H2C) begin
               rollover_be = 1'b0;
               if (!h2.hdr.sz) rollover = (pRollover+pRollover_be) <= 1 ? 0 : h2.h2ddat_hdr.val*(pRollover+pRollover_be-1);
               else            rollover = h2.h2ddat_hdr.val*(4-3+(pRollover+pRollover_be));
             end
             else begin //mdh (2-4 txns)
               rollover    = ((h2.d2hdat_hdr.sum with (int'(item.val)))*4)-3+pRollover+pRollover_be;
               rollover_be = 1'b0;
             end
           end
      H3 : begin 
             h3_f68 h3 = h3_f68::type_id::create("h3");
             h3.unpack_slot(dir, flit.slot[0]);
             slot[0] = h3; 
             rollover_be = 1'b0;
             if (dir == H2C) //mdh (2-4 txns)
               rollover = ((h3.h2ddat_hdr.sum with (int'(item.val)))*4)-3+pRollover+pRollover_be;
             else if (!flit.protocol.hdr.sz)
               rollover = (pRollover+pRollover_be) <= 1 ? 0 : h3.s2mdrs_hdr.val*(pRollover+pRollover_be-1);
             else
               rollover = h3.s2mdrs_hdr.val*(4-3+(pRollover+pRollover_be));
           end
      H4 : begin 
             h4_f68 h4 = h4_f68::type_id::create("h4");
             h4.unpack_slot(dir, flit.slot[0]);
             slot[0] = h4; 
             rollover = (dir == H2C) ? h4.m2srwd_hdr.val*(4-3+(pRollover+pRollover_be)) : 0;
             rollover_be = (dir == H2C) ? h4.m2srwd_hdr.val*flit.protocol.hdr.be : 1'b0;
           end
      H5 : begin 
             h5_f68 h5 = h5_f68::type_id::create("h5");
             h5.unpack_slot(dir, flit.slot[0]);
             slot[0] = h5; 
             rollover = (dir == H2C) ? 0 : ((h5.s2mdrs_hdr.sum with (int'(item.val)))*4)-3+pRollover+pRollover_be;
             rollover_be = 1'b0;
           end
      H6 : begin 
             h6_f68 h6 = h6_f68::type_id::create("h6");
             h6.unpack_slot(dir, flit.slot[0]);
             slot[0] = h6; 
             rollover = 0;
             rollover_be = 1'b0;
           end
      default : `uvm_error(get_type_name, $sformatf("Header slot has invalid slot_fmt value: 'b%b",flit.protocol.hdr.fmt.slot0))
    endcase

    // If rollover has been set, the generic slots shouldn't override
    rollover_locked = (|rollover);

    /* Now handle remaining slots in this flit */
    /* Function also sets future flit's rollover */
    case (pRollover+pRollover_be)
      2 : build_generic_slot(3);
      1 : begin
            build_generic_slot(3);
            build_generic_slot(2);
          end
      0 : begin
            // D2H Data can be 32B AND have BE; the ONLY txn that can do so
            // This means it's possible to have HDR G0 G0 G0_BE in one flit
            // when there's no rollover present, so we must mark slot 3 if
            // it's a G0_BE
            build_generic_slot(3, g0_is_be);
            build_generic_slot(2);
            build_generic_slot(1);
          end
    endcase

    /* Perform some quick error checking */
    if (!disable_tight_pack_check) check_tightly_packed();

   /* Take each slot and sum so credit tracking can occur */
   calc_credit_consumed_for_flit(slot[0], slot[1], slot[2], slot[3]);
  endfunction

  /* Supporting function that unpack_flit calls on generic slots, depending
     on input rollover */
  virtual function void build_generic_slot(int ptr, bit g0_is_be = 1'b0);
    gslot_fmt_t fmt;
    case (ptr)
      3       : fmt = flit.protocol.hdr.fmt.slot3;
      2       : fmt = flit.protocol.hdr.fmt.slot2;
      1       : fmt = flit.protocol.hdr.fmt.slot1;
      default : `uvm_fatal(get_type_name, $sformatf("Bad argument value %0d to build_generic_slot",ptr))
    endcase
    case (fmt)
      G0 : begin
             if (g0_is_be) begin
               g0be_f68 g0_be = g0be_f68::type_id::create("g0_be");
               g0_be.unpack_slot(dir, flit.slot[ptr]);
               slot[ptr] = g0_be;
             end
             else begin
               g0_f68 g0 = g0_f68::type_id::create("g0");
               {g0.dir, g0.data} = {dir, flit.slot[ptr]};
               slot[ptr] = g0;
             end
           end
      G1 : begin
             g1_f68 g1 = g1_f68::type_id::create("g1");
             g1.unpack_slot(dir, flit.slot[ptr]);
             slot[ptr] = g1;
           end
      G2 : begin
             g2_f68 g2 = g2_f68::type_id::create("g2");
             g2.unpack_slot(dir, flit.slot[ptr]);
             slot[ptr] = g2;
             if (!rollover_locked) begin
               rollover_be = (dir == C2H && g2.d2hdat_hdr.val && flit.protocol.hdr.be);
               if (!flit.protocol.hdr.sz)
                 rollover = (dir == H2C) ? g2.h2ddat_hdr.val*(ptr-1) : g2.d2hdat_hdr.val*(ptr-1); 
               else
                 rollover = (dir == H2C) ? g2.h2ddat_hdr.val*(4-3+ptr) : g2.d2hdat_hdr.val*(4-3+ptr); 
             end
           end
      G3 : begin
             g3_f68 g3 = g3_f68::type_id::create("g3");
             g3.unpack_slot(dir, flit.slot[ptr]);
             slot[ptr] = g3;
             if (!rollover_locked) begin //mdh (2-4 txn); never any BE or !SZ 
               rollover_be = 1'b0; 
               if (dir == H2C) rollover = ((g3.h2ddat_hdr.sum with (int'(item.val)))*4)-3+ptr;
               else            rollover = ((g3.d2hdat_hdr.sum with (int'(item.val)))*4)-3+ptr;
             end
           end
      G4 : begin
             g4_f68 g4 = g4_f68::type_id::create("g4");
             g4.unpack_slot(dir, flit.slot[ptr]);
             slot[ptr] = g4;
             if (!rollover_locked) begin 
               rollover_be = 1'b0;
               if (!flit.protocol.hdr.sz)
                 rollover = (dir == H2C) ? g4.h2ddat_hdr.val*(ptr-1) : g4.s2mdrs_hdr.val*(ptr-1); 
               else begin
                 rollover = (dir == H2C) ? g4.h2ddat_hdr.val*(4-3+ptr) : g4.s2mdrs_hdr.val*(4-3+ptr); 
               end
             end
           end
      G5 : begin
             g5_f68 g5 = g5_f68::type_id::create("g5");
             g5.unpack_slot(dir, flit.slot[ptr]);
             slot[ptr] = g5;
             if (!rollover_locked) begin 
               rollover = (dir == H2C) ? g5.m2srwd_hdr.val*(4-3+ptr) : 0;
               if (dir == H2C && g5.m2srwd_hdr.val && flit.protocol.hdr.be)
                 rollover_be = 1'b1;
             end
           end
      G6 : begin
             g6_f68 g6 = g6_f68::type_id::create("g6");
             g6.unpack_slot(dir, flit.slot[ptr]);
             slot[ptr] = g6;
             if (!rollover_locked) begin 
               if (dir == H2C) rollover = 0;
               else            rollover = ((g6.s2mdrs_hdr.sum with (int'(item.val)))*4)-3+ptr;
             end
           end
      default : `uvm_fatal(get_type_name, $sformatf("Slot %0d format of 'b%b is reserved", ptr, fmt))
    endcase
    // If rollover has been set, previous slots shouldn't modify
    rollover_locked = (|rollover); 
  endfunction

  /* Supporting function that unpack_flit calls on a fully unpacked flit */
  virtual function void check_tightly_packed();
    bit tightly_packed = 1'b1;;
    casez({slot[1].empty_slot, slot[2].empty_slot, slot[3].empty_slot})
      3'b10?  : tightly_packed = 1'b0; 
      3'b110  : tightly_packed = 1'b0; 
      3'b010  : tightly_packed = 1'b0;
    endcase
    if (!tightly_packed) 
      `uvm_info(get_type_name, "Flit is not tightly packed, messages should be left-aligned in slots; see CXL spec 'Flit Packing Rules'", UVM_NONE);
  endfunction

  /* A master agent user typically calls this to go from TL to LL */
  // This function allows a user to pack a flit by specifying the slots as arguments
  // to the function or as handles to objects in this object. Priority is given to 
  // the arguments passed to this function.
  // Identical Examples:
  //   1. flit.pack_flit(h4, g3); 
  //   2. {flit.slot[0], flit.slot[1]} = {h4, g3};
  //      flit.pack_flit();       
  virtual function void pack_flit(slot_base s0=null, s1=null, s2=null, s3=null);

    bit   [3:0]    dataslot;
    bit   [3:0]    empty_slot;
    logic [3:0]    hdr_be;
    logic [3:0]    hdr_sz;
    base_hslot_f68 hslot;

    // If arg is null, assign from slot handle
    if (s0 == null) s0 = slot[0];
    if (s1 == null) s1 = slot[1];
    if (s2 == null) s2 = slot[2];
    if (s3 == null) s3 = slot[3];

    valid = 1'b1;

    // Sum the credits consumed of each slot to get a total for the flit
    calc_credit_consumed_for_flit(s0, s1, s2, s3);
    /* If user is sending a Protocol flit and the slot 0 header specified the slot 1-3 
     * formats but user kept them as reserved, that must mean user wants them as empty. 
     * If the user is sending a Protocol flit and specified slot 1-3 but kept slot 0 as 
     * "reserved", we must generate an empty header with the correct slot 0-3 formats. We 
     * must generate a fully correct flit here as a convenience instead of just making a
     * user build raw flits.
    */
    // slot 0 has been specified, build necessary slots 1-3 if empty and build hdr fields
    if (s0 != null) begin
      this.dir      = s0.dir;
      hdr_be[0]     = s0.hdr_be;
      hdr_sz[0]     = s0.hdr_sz;
      flit.slot[0]  = s0.data;
      empty_slot[0] = s0.empty_slot;
      if (s0._fmt inside {[_H0:_H6]}) begin
        if (s1 == null) begin //slot1 not given 
          {hdr_be[1], hdr_sz[1]} = build_empty_gslot(1);
          empty_slot[1] = 1'b1;
        end
        else begin //slot1 given
          empty_slot[1] = s1.empty_slot;
          flit.slot[1]  = s1.data;
          case (s1._fmt)
            _G0, _G0_BE : flit.protocol.hdr.fmt.slot1 = G0; 
            _G1         : flit.protocol.hdr.fmt.slot1 = G1; 
            _G2         : flit.protocol.hdr.fmt.slot1 = G2; 
            _G3         : flit.protocol.hdr.fmt.slot1 = G3; 
            _G4         : flit.protocol.hdr.fmt.slot1 = G4; 
            _G5         : flit.protocol.hdr.fmt.slot1 = G5; 
            _G6         : flit.protocol.hdr.fmt.slot1 = G6; 
          endcase
          hdr_be[1] = s1.hdr_be;
          hdr_sz[1] = s1.hdr_sz;
        end
        if (s2 == null) begin //slot2 not given
          {hdr_be[2], hdr_sz[2]} = build_empty_gslot(2);
          empty_slot[2] = 1'b1;
        end
        else begin //slot2 given
          empty_slot[2] = s2.empty_slot;
          flit.slot[2]  = s2.data;
          case (s2._fmt)
            _G0, _G0_BE : flit.protocol.hdr.fmt.slot2 = G0; 
            _G1         : flit.protocol.hdr.fmt.slot2 = G1; 
            _G2         : flit.protocol.hdr.fmt.slot2 = G2; 
            _G3         : flit.protocol.hdr.fmt.slot2 = G3; 
            _G4         : flit.protocol.hdr.fmt.slot2 = G4; 
            _G5         : flit.protocol.hdr.fmt.slot2 = G5; 
            _G6         : flit.protocol.hdr.fmt.slot2 = G6; 
          endcase
          hdr_be[2] = s2.hdr_be;
          hdr_sz[2] = s2.hdr_sz;
        end
        if (s3 == null) begin //slot3 not given
          {hdr_be[3], hdr_sz[3]} = build_empty_gslot(3);
          empty_slot[3] = 1'b1;
        end
        else begin //slot3 given
          empty_slot[3] = s3.empty_slot;
          flit.slot[3]  = s3.data;
          case (s3._fmt)
            _G0, _G0_BE : flit.protocol.hdr.fmt.slot3 = G0; 
            _G1         : flit.protocol.hdr.fmt.slot3 = G1; 
            _G2         : flit.protocol.hdr.fmt.slot3 = G2; 
            _G3         : flit.protocol.hdr.fmt.slot3 = G3; 
            _G4         : flit.protocol.hdr.fmt.slot3 = G4; 
            _G5         : flit.protocol.hdr.fmt.slot3 = G5; 
            _G6         : flit.protocol.hdr.fmt.slot3 = G6; 
          endcase
          hdr_be[3] = s3.hdr_be;
          hdr_sz[3] = s3.hdr_sz;
        end
        // Set sz/be bits 
        if ($countbits(hdr_be, 'x))
          `uvm_error(get_type_name, "At least 1 slot has not specified its hdr_be reqmts, check for a mistake")
        if ($countbits(hdr_sz, 'x))
          `uvm_error(get_type_name, "At least 1 slot has not specified its hdr_sz reqmts, check for a mistake")
        // --- //
        if ($countbits(hdr_be, '1) && $countbits(hdr_be, '0))
          `uvm_error(get_type_name, "Conflict in flit for hdr.be value")
        else if ($countbits(hdr_be, '0))
          flit.protocol.hdr.be = 1'b0;
        else if ($countbits(hdr_be, '1))
          flit.protocol.hdr.be = 1'b1;
        else if ($countbits(hdr_be, 'z) == 4) //all 4 slots don't care (no data headers)
          flit.protocol.hdr.be = $urandom_range(0,1); 
        // --- //
        if ($countbits(hdr_sz, '1) && $countbits(hdr_sz, '0))
          `uvm_error(get_type_name, "Conflict in flit for hdr.sz value")
        else if ($countbits(hdr_sz, '0))
          flit.protocol.hdr.sz = 1'b0;
        else if ($countbits(hdr_sz, '1))
          flit.protocol.hdr.sz = 1'b1;
        else if ($countbits(hdr_sz, 'z) == 4) //all 4 slots don't care (no data headers)
          flit.protocol.hdr.sz = $urandom_range(0,1); 
      end
      // This is an ADF
      else begin
        empty_slot[3:1] = '0;
        flit.slot[1] = s1.data;
        flit.slot[2] = s2.data;
        flit.slot[3] = s3.data;
      end
    end
    // slot 1-3 has been specified, build necessary empty slot 0
    else if (s1 != null || s2 != null || s3 != null)
    begin
      {hdr_be[0], hdr_sz[0]} = 'z; 
      // Set the dir 
      if (s1 != null) begin
        flit.slot[1] = s1.data;
        this.dir     = s1.dir;
      end
      if (s2 != null) begin
        flit.slot[2] = s2.data;
        this.dir     = s2.dir;
      end
      if (s3 != null) begin
        flit.slot[3] = s3.data;
        this.dir     = s3.dir;
      end
      // Create slot 0
      empty_slot[0] = 1'b1;
      hslot = build_empty_hslot();
      /* Make sure created slot 0's hdr.fmt.slot* fields are correct if slot* was 
       * specified by the user or create the randomized type, empty slot if it 
       * wasn't.
       */
      // Slot 1
      if (s1 != null) begin
        empty_slot[1] = s1.empty_slot;
        set_hdr_slot_fmt_from_gen(1, hslot, s1._fmt);
        hdr_be[1] = s1.hdr_be;
        hdr_sz[1] = s1.hdr_sz;
      end
      else begin
        empty_slot[1] = 1'b1;
        {hdr_be[1], hdr_sz[1]} = build_empty_gslot(1, hslot.hdr.fmt.slot1);
      end
      // Slot 2
      if (s2 != null) begin
        empty_slot[2] = s2.empty_slot;
        set_hdr_slot_fmt_from_gen(2, hslot, s2._fmt);
        hdr_be[2] = s2.hdr_be;
        hdr_sz[2] = s2.hdr_sz;
      end
      else begin
        empty_slot[2] = 1'b1;
        {hdr_be[2], hdr_sz[2]} = build_empty_gslot(2, hslot.hdr.fmt.slot2);
      end
      // Slot 3
      if (s3 != null) begin
        empty_slot[3] = s3.empty_slot;
        set_hdr_slot_fmt_from_gen(3, hslot, s3._fmt);
        hdr_be[3] = s3.hdr_be;
        hdr_sz[3] = s3.hdr_sz;
      end
      else begin
        empty_slot[3] = 1'b1;
        {hdr_be[3], hdr_sz[3]} = build_empty_gslot(3, hslot.hdr.fmt.slot3);
      end
      /* Must set header's sz/be fields appropriately. There are 4 slots in a 
       * flit, and all slots control the values of sz/be. An x in hdr_sz or 
       * hdr_be means it was unset, a z is a don't care, and a single slot 
         should have either 1 or 0 set, else there is a conflict. The sz/be
         fields are only necessary when there is a valid data header.
       */
      if ($countbits(hdr_be, 'x))
        `uvm_error(get_type_name, "At least 1 slot has not specified its hdr_be reqmts, check for a mistake")
      if ($countbits(hdr_sz, 'x))
        `uvm_error(get_type_name, "At least 1 slot has not specified its hdr_sz reqmts, check for a mistake")
      // --- //
      if ($countbits(hdr_be, '1) && $countbits(hdr_be, '0))
        `uvm_error(get_type_name, "Conflict in flit for hdr.be value")
      else if ($countbits(hdr_be, '0))
        hslot.hdr.be = 1'b0;
      else if ($countbits(hdr_be, '1))
        hslot.hdr.be = 1'b1;
      else if ($countbits(hdr_be, 'z) == 4) //all 4 slots don't care (no data headers)
        hslot.hdr.be = $urandom_range(0,1); 
      // --- //
      if ($countbits(hdr_sz, '1) && $countbits(hdr_sz, '0))
        `uvm_error(get_type_name, "Conflict in flit for hdr.sz value")
      else if ($countbits(hdr_sz, '0))
        hslot.hdr.sz = 1'b0;
      else if ($countbits(hdr_sz, '1))
        hslot.hdr.sz = 1'b1;
      else if ($countbits(hdr_sz, 'z) == 4) //all 4 slots don't care (no data headers)
        hslot.hdr.sz = $urandom_range(0,1); 
      /* Finally, slot 0 is correctly created and assigned to the flit */
      flit.slot[0] = hslot.pack_slot();
    end
    // no slots have been specified, user must want an empty flit 
    else begin
      empty_slot = '1;
      // Create slot 0
      hslot = build_empty_hslot();
      hslot.hdr.sz = 1;
      hslot.hdr.be = 0;
      flit.slot[0] = hslot.pack_slot();
      // Create slots 1 and 3 to the randomized formats of slot 0
      void'(build_empty_gslot(1));
      void'(build_empty_gslot(2));
      void'(build_empty_gslot(3));
    end
    // Set if flit is empty
    empty_flit = &empty_slot;
    // 1 bit of parity for each 64 bits
    foreach(parity[ii])
      parity[ii] = ^flit.raw[ii*64+:64];
    // Set viral to 0 right now, could be added in the future
    viral = '0;
    // Check if adf needs to be set based on flit composition
    dataslot[0] = (s0 != null) ? (s0._fmt inside {_G0,_G0_BE}) : 1'b0;
    dataslot[1] = (s1 != null) ? (s1._fmt inside {_G0,_G0_BE}) : 1'b0;
    dataslot[2] = (s2 != null) ? (s2._fmt inside {_G0,_G0_BE}) : 1'b0;
    dataslot[3] = (s3 != null) ? (s3._fmt inside {_G0,_G0_BE}) : 1'b0;
    adf = &dataslot;
    /* Build the decode assists */
    dec_sop = '0;
    dec_eop = '0;
    dec_be  = '0;
    dec_mem = '0;
    // -- Handle eop/be 
    // All data flit (hit when MDH (no BE) OR else Slot3 HDR)
    if (pRollover >= 4) begin
      dec_eop[(pRollover+3)%4] = !pRollover_be;
    end
    // All data flit with BE; Rollover = 3, Rollover_BE = 1
    else if (pRollover == 3 && pRollover_be) begin //1,2,3,BE 
      dec_eop[3] = 1'b1;
      dec_be [3] = 1'b1;
    end
    // Flit ending here; pRollover = {1,2,3} or pRolloverBE iff pRollover = {1,2}
    else if ((pRollover+pRollover_be) != 0) begin
      dec_eop[pRollover+pRollover_be] = 1'b1;
      dec_be [pRollover+pRollover_be] = pRollover_be;
    end
    // -- Handle sop/mem
    // -- Calculate rollover at same time
    assist_mem = 1'b0; 
    // All data flit
    if (pRollover >= 4) begin
      dec_sop[pRollover%4] = 1'b1;
      dec_mem[pRollover%4] = pAssist_mem;
      rollover = pRollover-4;
      rollover_be = pRollover_be;
    end
    // A data header is in this flit, now we need to find it
    else if (dat_consumed.sum) begin
      // Found HDR in Slot 0, must account for rollover for SOP
      if (s0 != null && s0.dat_consumed.sum) begin
        dec_sop[pRollover+pRollover_be+1] = 1'b1;
        dec_mem[pRollover+pRollover_be+1] = |s0.dat_consumed[1];
        rollover    = (s0.dat_consumed.sum*(flit.protocol.hdr.sz?4:2))-3+pRollover+pRollover_be;
        rollover_be = flit.protocol.hdr.be;
        // A 32B txfer could calculate negative rollover, which is impossible, should be zero
        if (rollover < 0) rollover = 0;
      end
      else if (slot[0] != null && slot[0].dat_consumed.sum) begin
        dec_sop[pRollover+pRollover_be+1] = 1'b1;
        dec_mem[pRollover+pRollover_be+1] = |slot[0].dat_consumed[1];
        rollover    = (slot[0].dat_consumed.sum*(flit.protocol.hdr.sz?4:2))-3+pRollover+pRollover_be;
        rollover_be = flit.protocol.hdr.be;
        // A 32B txfer could calculate negative rollover, which is impossible, should be zero
        if (rollover < 0) rollover = 0;
      end
      // Found HDR in Slot 1 (no rollover)
      else if (s1 != null && s1.dat_consumed.sum) begin
        dec_sop[2] = 1'b1;
        dec_mem[2] = |s1.dat_consumed[1];
        rollover    = (s1.dat_consumed.sum*(flit.protocol.hdr.sz?4:2))-2;
        rollover_be = flit.protocol.hdr.be;
      end
      else if (slot[1] != null && slot[1].dat_consumed.sum) begin
        dec_sop[2] = 1'b1;
        dec_mem[2] = |slot[1].dat_consumed[1];
        rollover    = (slot[1].dat_consumed.sum*(flit.protocol.hdr.sz?4:2))-2;
        rollover_be = flit.protocol.hdr.be;
      end
      // Found HDR in Slot 2 (no rollover)
      else if (s2 != null && s2.dat_consumed.sum) begin
        dec_sop[3] = 1'b1;
        dec_mem[3] = |s2.dat_consumed[1];
        rollover    = (s2.dat_consumed.sum*(flit.protocol.hdr.sz?4:2))-1;
        rollover_be = flit.protocol.hdr.be;
      end
      else if (slot[2] != null && slot[2].dat_consumed.sum) begin
        dec_sop[3] = 1'b1;
        dec_mem[3] = |slot[2].dat_consumed[1];
        rollover    = (slot[2].dat_consumed.sum*(flit.protocol.hdr.sz?4:2))-1;
        rollover_be = flit.protocol.hdr.be;
      end
      // Found HDR in Slot 3 (no rollover)
      else if (s3 != null && s3.dat_consumed.sum) begin
        rollover    = (s3.dat_consumed.sum*(flit.protocol.hdr.sz?4:2));
        rollover_be = flit.protocol.hdr.be;
        assist_mem  = s3.dat_consumed[1];
      end
      else if (slot[3] != null && slot[3].dat_consumed.sum) begin
        rollover    = (slot[3].dat_consumed.sum*(flit.protocol.hdr.sz?4:2));
        rollover_be = flit.protocol.hdr.be;
        assist_mem  = slot[3].dat_consumed[1];
      end
    end
    // Check if last can be set based on flit composition
    last = (rollover+rollover_be<4);
  endfunction

  // This function builds an empty header slot
  virtual function base_hslot_f68 build_empty_hslot();
      slot_fmt_t slotfmt;
      // Create slot 0
      void'(std::randomize(slotfmt) with {slotfmt inside {[_H0:_H5]};
                                          // No MDH 
                                          this.dir == H2C -> slotfmt != _H3; 
                                          this.dir == C2H -> !(slotfmt inside {_H2,_H5}); 
                                         });
      case (slotfmt)
        _H0 : begin
                h0_f68 h0 = h0_f68::type_id::create("h0");
                h0.create_objects(this.dir, '0);
                void'(h0.randomize());
                void'(h0.pack_slot());
                build_empty_hslot = h0;
              end
        _H1 : begin
                h1_f68 h1 = h1_f68::type_id::create("h1");
                h1.create_objects(this.dir, '0);
                void'(h1.randomize());
                void'(h1.pack_slot());
                build_empty_hslot = h1;
              end
        _H2 : begin
                h2_f68 h2 = h2_f68::type_id::create("h2");
                h2.create_objects(this.dir, '0);
                void'(h2.randomize());
                void'(h2.pack_slot());
                build_empty_hslot = h2;
              end
        _H3 : begin
                h3_f68 h3 = h3_f68::type_id::create("h3");
                h3.create_objects(this.dir, '0);
                void'(h3.randomize());
                void'(h3.pack_slot());
                build_empty_hslot = h3;
              end
        _H4 : begin
                h4_f68 h4 = h4_f68::type_id::create("h4");
                h4.create_objects(this.dir, '0);
                void'(h4.randomize());
                void'(h4.pack_slot());
                build_empty_hslot = h4;
              end
        _H5 : begin
                h5_f68 h5 = h5_f68::type_id::create("h5");
                h5.create_objects(this.dir, '0);
                void'(h5.randomize());
                void'(h5.pack_slot());
                build_empty_hslot = h5;
              end
      endcase
  endfunction

  // This function builds an empty slot, dependent on the slot format given
  // in the flit header of the flit.slot[0] if this_fmt == 'x or of this_fmt itself
  // if this_fmt != 'x
  // Restriction --> ptr = [1:3]
  // Returns {hdr_be, hdr_sz} 
  virtual function logic [1:0] build_empty_gslot(bit [1:0] ptr, logic [2:0] this_fmt = 'x);
    bit [2:0] fmt;
    if (ptr == 0) return 'x;
    fmt = (this_fmt === 'x) ? flit.slot[0][8+((ptr-1)*3)+:3] : this_fmt;
    case (fmt)
      G1 : begin
        g1_f68 g1 = g1_f68::type_id::create("g1");
        g1.create_objects(this.dir, '0);
        void'(g1.randomize());
        flit.slot[ptr] = g1.pack_slot();
        build_empty_gslot = {g1.hdr_be, g1.hdr_sz}; 
      end
      G2 : begin
        g2_f68 g2 = g2_f68::type_id::create("g2");
        g2.create_objects(this.dir, '0);
        void'(g2.randomize());
        flit.slot[ptr] = g2.pack_slot();
        build_empty_gslot = {g2.hdr_be, g2.hdr_sz}; 
      end
      G3 : begin
        g3_f68 g3 = g3_f68::type_id::create("g3");
        g3.create_objects(this.dir, '0);
        void'(g3.randomize());
        flit.slot[ptr] = g3.pack_slot();
        build_empty_gslot = {g3.hdr_be, g3.hdr_sz}; 
      end
      G4 : begin
        g4_f68 g4 = g4_f68::type_id::create("g4");
        g4.create_objects(this.dir, '0);
        void'(g4.randomize());
        flit.slot[ptr] = g4.pack_slot();
        build_empty_gslot = {g4.hdr_be, g4.hdr_sz}; 
      end
      G5 : begin
        g5_f68 g5 = g5_f68::type_id::create("g5");
        g5.create_objects(this.dir, '0);
        void'(g5.randomize());
        flit.slot[ptr] = g5.pack_slot();
        build_empty_gslot = {g5.hdr_be, g5.hdr_sz}; 
      end
      G6 : begin
        g6_f68 g6 = g6_f68::type_id::create("g6");
        g6.create_objects(this.dir, '0);
        void'(g6.randomize());
        flit.slot[ptr] = g6.pack_slot();
        build_empty_gslot = {g6.hdr_be, g6.hdr_sz}; 
      end
      default : `uvm_fatal(get_type_name, "Invalid selection")
    endcase
  endfunction

  /* Supporting function for pack_flit. Set flit header slot format fields (in Slot 0)
     from (ptr) generic slot type */
  virtual function void set_hdr_slot_fmt_from_gen(bit [1:0] ptr, base_hslot_f68 hdr_slot, slot_fmt_t fmt);
    gslot_fmt_t gfmt;
    case (fmt)
      _G0, _G0_BE : gfmt = G0;
      _G1         : gfmt = G1;
      _G2         : gfmt = G2;
      _G3         : gfmt = G3;
      _G4         : gfmt = G4;
      _G5         : gfmt = G5;
      _G6         : gfmt = G6;
    endcase
    case (ptr)
      0 : `uvm_warning(get_type_name, "Shouldn't call this function with ptr=0")
      1 : hdr_slot.hdr.fmt.slot1 = gfmt;
      2 : hdr_slot.hdr.fmt.slot2 = gfmt;
      3 : hdr_slot.hdr.fmt.slot3 = gfmt;
    endcase
  endfunction

  // Sum the credits consumed by each slot to get the total for a flit. Can
  // pass in slot_base handles or use the local slot_base handles.
  virtual function void calc_credit_consumed_for_flit(slot_base s0 = null, 
                                                      slot_base s1 = null, 
                                                      slot_base s2 = null, 
                                                      slot_base s3 = null
  );
    string str;
    // [mem, cache]
    // Check messages in a flit (CXL spec: 4.2.5)
    int max_req[1:0];
    int max_rsp[1:0];
    int max_dhd[1:0];

    if (s0==null && s1==null && s2==null && s3==null) return;

    // Slot 0
    if (s0 != null) begin
      dir = s0.dir;
      foreach (req_consumed[ii]) req_consumed[ii] += s0.req_consumed[ii];
      foreach (dat_consumed[ii]) dat_consumed[ii] += s0.dat_consumed[ii];
      foreach (rsp_consumed[ii]) rsp_consumed[ii] += s0.rsp_consumed[ii];
    end
    // Slot 1
    if (s1 != null) begin
      dir = s1.dir;
      foreach (req_consumed[ii]) req_consumed[ii] += s1.req_consumed[ii];
      foreach (dat_consumed[ii]) dat_consumed[ii] += s1.dat_consumed[ii];
      foreach (rsp_consumed[ii]) rsp_consumed[ii] += s1.rsp_consumed[ii];
    end
    // Slot 2
    if (s2 != null) begin
      dir = s2.dir;
      foreach (req_consumed[ii]) req_consumed[ii] += s2.req_consumed[ii];
      foreach (dat_consumed[ii]) dat_consumed[ii] += s2.dat_consumed[ii];
      foreach (rsp_consumed[ii]) rsp_consumed[ii] += s2.rsp_consumed[ii];
    end
    // Slot 3
    if (s3 != null) begin
      dir = s3.dir;
      foreach (req_consumed[ii]) req_consumed[ii] += s3.req_consumed[ii];
      foreach (dat_consumed[ii]) dat_consumed[ii] += s3.dat_consumed[ii];
      foreach (rsp_consumed[ii]) rsp_consumed[ii] += s3.rsp_consumed[ii];
    end

    max_req = (dir == H2C) ? '{2, 2} : '{0, 4};
    max_rsp = (dir == H2C) ? '{0, 4} : '{2, 2};
    max_dhd = (dir == H2C) ? '{1, 4} : '{3, 4};

    str = "Maximum messages per flit violation: ";
    foreach (req_consumed[ii]) 
      if (req_consumed[ii] > max_req[ii])
        `uvm_error(get_type_name, {str,$sformatf("%0s CXL.%0s REQ, allowed: %0d, actual: %0d",
                                       dir.name,
                                       !ii?"cache":"mem",
                                       max_req[ii],
                                       req_consumed[ii])})
    foreach (rsp_consumed[ii]) 
      if (rsp_consumed[ii] > max_rsp[ii])
        `uvm_error(get_type_name, {str,$sformatf("%0s CXL.%0s RSP, allowed: %0d, actual: %0d",
                                       dir.name,
                                       !ii?"cache":"mem",
                                       max_rsp[ii],
                                       rsp_consumed[ii])})
    foreach (dat_consumed[ii]) 
      if (dat_consumed[ii] > max_dhd[ii])
        `uvm_error(get_type_name, {str,$sformatf("%0s CXL.%0s DATA HDR, allowed: %0d, actual: %0d",
                                       dir.name,
                                       !ii?"cache":"mem",
                                       max_dhd[ii],
                                       dat_consumed[ii])})
  endfunction

  // May be useful to help call for debug
  virtual function void print_slots();
    string str;
    str = "Printing data from slots:\n";
    str = {str,$sformatf("Slot 0 = 0x%0h\n",flit.slot[0])};
    str = {str,$sformatf("Slot 1 = 0x%0h\n",flit.slot[1])};
    str = {str,$sformatf("Slot 2 = 0x%0h\n",flit.slot[2])};
    str = {str,$sformatf("Slot 3 = 0x%0h\n",flit.slot[3])};
    `uvm_info(get_type_name, str, UVM_LOW)
  endfunction

  // Create a new flit and copy the rollover from last flit
  virtual function flit68_txn new_flit();
    flit68_txn n               = flit68_txn::type_id::create("n");
    n.flitmode                 = this.flitmode;
    n.dir                      = this.dir;
    n.disable_tight_pack_check = this.disable_tight_pack_check;
    n.pRollover                = this.rollover;
    n.pRollover_be             = this.rollover_be;
    n.pAssist_mem              = this.assist_mem;
    return n;
  endfunction

endclass
