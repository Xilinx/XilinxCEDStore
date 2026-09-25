class flit256_txn extends flit_base_txn;

  `uvm_object_utils(flit256_txn)

  // a 256B flit is composed of 4 slotsets
  slotset_txn slotset[0:3];
  
  // a 256B flit will have handles to 16 slot objects
  slot_base_f256 slot[0:15];

  function new(string name = "flit256_txn");
    super.new(name);
    txn_type = "FLIT256_TXN";
    foreach (slotset[ii]) begin
      slotset[ii] = slotset_txn::type_id::create($sformatf("slotset[%0d]",ii));
      slotset[ii].slotset = ii;
    end
  endfunction

  /* The monitor calls this to go from raw slotset data (just bits) to slot objects
     that contain metadata for better/faster/easier parsing */
  virtual function void unpack_slotset(bit [1:0] ptr);
  
    // Give flitmode and dir to child
    slotset[ptr].flitmode = flitmode;
    slotset[ptr].dir      = dir;

    // It is assumed the caller has already assign the data to the slotset object
    // Ex. flit.slotset[ptr].data = 512'h....; flit.unpack_slotset(ptr);
    slotset[ptr].unpack;

    // Assign the handles to this parent class
    slot[ptr*4+0] = slotset[ptr].slot[0];
    slot[ptr*4+1] = slotset[ptr].slot[1];
    slot[ptr*4+2] = slotset[ptr].slot[2];
    slot[ptr*4+3] = slotset[ptr].slot[3];

    // Add each slotset's credits consumed for the flit
    for (int ii=0; ii<2; ii++) begin
      req_consumed[ii] += slotset[ptr].req_consumed[ii];
      dat_consumed[ii] += slotset[ptr].dat_consumed[ii];
      rsp_consumed[ii] += slotset[ptr].rsp_consumed[ii];
      // And also summarize credits returned from S15 
      if (ptr==3) begin
        req_returned[ii] = -1*slotset[ptr].slot[3].req_consumed[ii];
        dat_returned[ii] = -1*slotset[ptr].slot[3].dat_consumed[ii];
        rsp_returned[ii] = -1*slotset[ptr].slot[3].rsp_consumed[ii];
      end
    end

    // Perform some quick error checking
    if (!disable_tight_pack_check) slotset[ptr].check_tightly_packed();

  endfunction

  /* A master agent will call this to go from TL to LL */
  // This function allows for easy packing of an entire flit, although it just
  // packs into slotsets under the hood. Users can leave the arguments null and 
  // assign to the slot[0:15] handles instead before calling this function; that's
  // also valid.
  virtual function void pack(slot_base_f256  s0=null,  s1=null,  s2=null,  s3=null,
                                             s4=null,  s5=null,  s6=null,  s7=null,
                                             s8=null,  s9=null, s10=null, s11=null, 
                                            s12=null, s13=null, s14=null, s15=null);

    // Give flitmode to child
    foreach (slotset[ii]) begin
      slotset[ii].flitmode = flitmode;
      slotset[ii].dir      = dir;
    end

    // If arg is null, assign local variable to slot handle
    if (s0 == null) s0 = slot[0];   if (s8  == null) s8  = slot[8];
    if (s1 == null) s1 = slot[1];   if (s9  == null) s9  = slot[9];
    if (s2 == null) s2 = slot[2];   if (s10 == null) s10 = slot[10];
    if (s3 == null) s3 = slot[3];   if (s11 == null) s11 = slot[11];
    if (s4 == null) s4 = slot[4];   if (s12 == null) s12 = slot[12];
    if (s5 == null) s5 = slot[5];   if (s13 == null) s13 = slot[13];
    if (s6 == null) s6 = slot[6];   if (s14 == null) s14 = slot[14];
    if (s7 == null) s7 = slot[7];   if (s15 == null) s15 = slot[15];

    // Assign handles to slot objects and pack into data member; do addl.
    // checking and randomization for null handles
    /* flit-to-flit accnted by new_flit*/ slotset[0].pack( s0,  s1,  s2,  s3);  
    slotset[1].continue_flit(slotset[0]); slotset[1].pack( s4,  s5,  s6,  s7);  
    slotset[2].continue_flit(slotset[1]); slotset[2].pack( s8,  s9, s10, s11); 
    slotset[3].continue_flit(slotset[2]); slotset[3].pack(s12, s13, s14, s15);

    // Check if this flit was completely empty
    empty_flit = 1'b1; 
    foreach (slotset[ii]) begin
      if (empty_flit) begin
        foreach (slotset[ii].slot[jj]) begin
          if (!slotset[ii].slot[jj].empty_slot) begin
            empty_flit = 1'b0;
            break;
          end
        end
      end
    end
 
    // Perform some quick error checking
    if (!disable_tight_pack_check) 
      foreach (slotset[ii])
        slotset[ii].check_tightly_packed();
  
  endfunction

  // Create a new flit and copy the rollover from last flit
  virtual function flit256_txn new_flit();
    flit256_txn n = flit256_txn::type_id::create("n");
    n.flitmode                 = this.flitmode;
    n.dir                      = this.dir;
    n.disable_tight_pack_check = this.disable_tight_pack_check;
    // Copy metadata over
    n.slotset[0].continue_flit(this.slotset[3]);
    return n;
  endfunction

endclass

