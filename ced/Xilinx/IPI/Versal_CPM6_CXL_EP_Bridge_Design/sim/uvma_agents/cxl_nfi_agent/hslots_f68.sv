// - Contains all header slot classes H0-H6 for 68B flits
// - Each class is shared between H2C and C2H directions
// - Each slot class contains a struct to pack/unpack messages, and
//   also includes an object handle for messages that don't include data
// - Can specify message to pack through the object handle or the struct,
//   with the object handle taking precedence 
// - Data messages have to be packed and unpacked externally
class base_hslot_f68 extends slot_base;

  `uvm_object_utils(base_hslot_f68)

         flit68_hdr_t hdr = 'x;
  rand r_flit68_hdr_t rand_hdr;

  // 0: cache, 1: mem
  int unsigned max_reqcrd[0:1] = '{'0, '0};
  int unsigned max_datcrd[0:1] = '{'0, '0};
  int unsigned max_rspcrd[0:1] = '{'0, '0};

  function new(string name = "base_hslot_f68");
    super.new(name);
  endfunction

  // Extended classes should implement
  virtual function logic [127:0] pack_slot(); return 0; endfunction

  constraint c_fmt3to1_nodata {
    // Can't randomize to a data slot
    rand_hdr.fmt.slot3 != G0;
    rand_hdr.fmt.slot2 != G0;
    rand_hdr.fmt.slot1 != G0;
    // G6 is RSVD for H2D
    (dir == H2C) -> { rand_hdr.fmt.slot3 != G6;
                      rand_hdr.fmt.slot2 != G6;
                      rand_hdr.fmt.slot1 != G6; }
  }
  constraint c_fmt0_nomac {
    rand_hdr.fmt.slot0 != H6;
  }
  // Can't randomize to an MDH, because MDH must have >1 valid 
  constraint c_fmt3to1_nomdh {
    rand_hdr.fmt.slot3 != G3;
    rand_hdr.fmt.slot2 != G3;
    rand_hdr.fmt.slot1 != G3;
    (dir == C2H) -> { rand_hdr.fmt.slot3 != G6;
                      rand_hdr.fmt.slot2 != G6;
                      rand_hdr.fmt.slot1 != G6; }
  }
  constraint c_randcred {
    if      (max_reqcrd[rand_hdr.reqcrd[3]] == 0) { rand_hdr.reqcrd[2:0] == 3'h0; } 
    else if (max_reqcrd[rand_hdr.reqcrd[3]] == 1) { rand_hdr.reqcrd[2:0] <= 3'h1; }
    else if (max_reqcrd[rand_hdr.reqcrd[3]] == 2) { rand_hdr.reqcrd[2:0] <= 3'h2; }
    else if (max_reqcrd[rand_hdr.reqcrd[3]] <  4) { rand_hdr.reqcrd[2:0] <= 3'h3; }
    else if (max_reqcrd[rand_hdr.reqcrd[3]] <  8) { rand_hdr.reqcrd[2:0] <= 3'h4; }
    else if (max_reqcrd[rand_hdr.reqcrd[3]] < 16) { rand_hdr.reqcrd[2:0] <= 3'h5; }
    else if (max_reqcrd[rand_hdr.reqcrd[3]] < 32) { rand_hdr.reqcrd[2:0] <= 3'h6; }
    else if (max_reqcrd[rand_hdr.reqcrd[3]] < 64) { rand_hdr.reqcrd[2:0] <= 3'h7; }

    if      (max_datcrd[rand_hdr.datcrd[3]] == 0) { rand_hdr.datcrd[2:0] == 3'h0; } 
    else if (max_datcrd[rand_hdr.datcrd[3]] == 1) { rand_hdr.datcrd[2:0] <= 3'h1; }
    else if (max_datcrd[rand_hdr.datcrd[3]] == 2) { rand_hdr.datcrd[2:0] <= 3'h2; }
    else if (max_datcrd[rand_hdr.datcrd[3]] <  4) { rand_hdr.datcrd[2:0] <= 3'h3; }
    else if (max_datcrd[rand_hdr.datcrd[3]] <  8) { rand_hdr.datcrd[2:0] <= 3'h4; }
    else if (max_datcrd[rand_hdr.datcrd[3]] < 16) { rand_hdr.datcrd[2:0] <= 3'h5; }
    else if (max_datcrd[rand_hdr.datcrd[3]] < 32) { rand_hdr.datcrd[2:0] <= 3'h6; }
    else if (max_datcrd[rand_hdr.datcrd[3]] < 64) { rand_hdr.datcrd[2:0] <= 3'h7; }

    if      (max_rspcrd[rand_hdr.rspcrd[3]] == 0) { rand_hdr.rspcrd[2:0] == 3'h0; } 
    else if (max_rspcrd[rand_hdr.rspcrd[3]] == 1) { rand_hdr.rspcrd[2:0] <= 3'h1; }
    else if (max_rspcrd[rand_hdr.rspcrd[3]] == 2) { rand_hdr.rspcrd[2:0] <= 3'h2; }
    else if (max_rspcrd[rand_hdr.rspcrd[3]] <  4) { rand_hdr.rspcrd[2:0] <= 3'h3; }
    else if (max_rspcrd[rand_hdr.rspcrd[3]] <  8) { rand_hdr.rspcrd[2:0] <= 3'h4; }
    else if (max_rspcrd[rand_hdr.rspcrd[3]] < 16) { rand_hdr.rspcrd[2:0] <= 3'h5; }
    else if (max_rspcrd[rand_hdr.rspcrd[3]] < 32) { rand_hdr.rspcrd[2:0] <= 3'h6; }
    else if (max_rspcrd[rand_hdr.rspcrd[3]] < 64) { rand_hdr.rspcrd[2:0] <= 3'h7; }
  }

  function void post_randomize();
    if (hdr.datcrd === 'x)    hdr.datcrd    = rand_hdr.datcrd;  
    if (hdr.reqcrd === 'x)    hdr.reqcrd    = rand_hdr.reqcrd;  
    if (hdr.rspcrd === 'x)    hdr.rspcrd    = rand_hdr.rspcrd;  
    if (hdr.rsvd1 === 'x)     hdr.rsvd1     = rand_hdr.rsvd1;  
    if (hdr.fmt.slot3 === 'x) hdr.fmt.slot3 = rand_hdr.fmt.slot3;
    if (hdr.fmt.slot2 === 'x) hdr.fmt.slot2 = rand_hdr.fmt.slot2;
    if (hdr.fmt.slot1 === 'x) hdr.fmt.slot1 = rand_hdr.fmt.slot1;
    if (hdr.fmt.slot0 === 'x) hdr.fmt.slot0 = rand_hdr.fmt.slot0;
    // sz and be are hardcoded to randomize to 1'bx to catch error, because we
    // cannot just randomize it, it must be set appropriately
    if (hdr.sz === 'x)        hdr.sz        = 1'bx; 
    if (hdr.be === 'x)        hdr.be        = 1'bx; 
    if (hdr.ak === 'x)        hdr.ak        = rand_hdr.ak;  
    if (hdr.rsvd0 === 'x)     hdr.rsvd0     = rand_hdr.rsvd0;  
    hdr.Type = PROTOCOL; //constant for these set of messages
  endfunction

  virtual protected function void check_rsvd();
    if (|{hdr.rsvd0, hdr.rsvd1})
      `uvm_error(get_type_name, $sformatf("FLIT HDR=0x%0h; Reserved bits of flit header are not 0; see CXL spec",hdr))
  endfunction

  // Checks that G3 or D2H.G6 has sz and !be 
  virtual protected function void check_mdh();
    bit mdh_sz_err = 1'b0;
    bit mdh_be_err = 1'b0;
    if (!hdr.sz) begin
      if ((dir == H2C && _fmt == _H3) || (dir == C2H && (_fmt inside {_H2, _H5})))
        mdh_sz_err = 1'b1;
      if (hdr.fmt.slot1 == G3 || (dir == C2H && hdr.fmt.slot1 == G6))
        mdh_sz_err = 1'b1;
      else if (hdr.fmt.slot2 == G3 || (dir == C2H && hdr.fmt.slot2 == G6))
        mdh_sz_err = 1'b1;
      else if (hdr.fmt.slot3 == G3 || (dir == C2H && hdr.fmt.slot3 == G6))
        mdh_sz_err = 1'b1;
    end
    if (hdr.be) begin
      if ((dir == H2C && _fmt == _H3) || (dir == C2H && (_fmt inside {_H2, _H5})))
        mdh_be_err = 1'b1;
      if (hdr.fmt.slot1 == G3 || (dir == C2H && hdr.fmt.slot1 == G6))
        mdh_be_err = 1'b1;
      else if (hdr.fmt.slot2 == G3 || (dir == C2H && hdr.fmt.slot2 == G6))
        mdh_be_err = 1'b1;
      else if (hdr.fmt.slot3 == G3 || (dir == C2H && hdr.fmt.slot3 == G6))
        mdh_be_err = 1'b1;
    end
    if (mdh_sz_err)
      `uvm_error(get_type_name, "MDH cannot send 32B chunk (hdr.sz); see CXL spec")
    if (mdh_be_err)
      `uvm_error(get_type_name, "MDH cannot send BE (!hdr.be); see CXL spec")
  endfunction

endclass

class h0_f68 extends base_hslot_f68;

  `uvm_object_utils(h0_f68)

  /* H2D/M2S */
  h2drsp68_t h2drsp; /**/ rand h2drsp_c h2drsp_h;
  h2dreq68_t h2dreq; /**/ rand h2dreq_c h2dreq_h;

  /* D2H/S2M */
  logic [8:0]    rsvd = '0;
  s2mndr68_t     s2mndr;      /**/ rand s2mndr_c s2mndr_h;
  d2hrsp68_t     d2hrsp[1:0]; /**/ rand d2hrsp_c d2hrsp_h[1:0];
  d2hdat68_hdr_t d2hdat_hdr;  /**/ rand d2hdat_c d2hdat_h;

  function new(string name = "h0_f68");
    super.new(name);
    _fmt = _H0;
  endfunction 

  virtual function void create_objects(dir_t dir, logic [3:0] set_valid = 'x);
    this.dir = dir;
    if (dir == H2C) begin
      h2dreq_h           = h2dreq_c::type_id::create("h2dreq_h");
      h2dreq_h.flitmode  = F68;
      h2dreq_h.req68.val = set_valid[0];
      h2drsp_h           = h2drsp_c::type_id::create("h2drsp_h");
      h2drsp_h.flitmode  = F68;
      h2drsp_h.rsp68.val = set_valid[1];
    end
    else begin
      d2hdat_h           = d2hdat_c::type_id::create("d2hdat_h");
      d2hdat_h.flitmode  = F68;
      d2hdat_h.hdr68.val = set_valid[0];
      foreach (d2hrsp_h[ii]) begin
        d2hrsp_h[ii]           = d2hrsp_c::type_id::create($sformatf("d2hrsp_h[%0d]",ii));
        d2hrsp_h[ii].flitmode  = F68;
        d2hrsp_h[ii].rsp68.val = set_valid[ii+1];
      end
      s2mndr_h           = s2mndr_c::type_id::create("s2mndr_h");
      s2mndr_h.flitmode  = F68;
      s2mndr_h.ndr68.val = set_valid[3];
    end
  endfunction

  // If transmitting, randomize will be called; this saves a step
  function void post_randomize();
    super.post_randomize();
    hdr.fmt.slot0 = H0;
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void set_empty_slot();
    empty_slot = (dir == H2C) ? ~|{h2drsp.val, h2dreq.val} : ~|{s2mndr.val, d2hrsp[1].val, d2hrsp[0].val, d2hdat_hdr.val};
    if (dir == H2C) begin
      req_consumed[0] = h2dreq.val;
      rsp_consumed[0] = h2drsp.val;
    end
    else begin
      dat_consumed[0] = d2hdat_hdr.val;
      rsp_consumed[0] = d2hrsp[1].val + d2hrsp[0].val;
      rsp_consumed[1] = s2mndr.val;
    end
  endfunction

  virtual protected function void set_be_sz();
    {hdr_be, hdr_sz} = 'z; //default to don't care
    if (dir == C2H && d2hdat_h != null && d2hdat_h.hdr68.val) begin
      hdr_be = (d2hdat_h.be != '1);
      hdr_sz = d2hdat_h.txfer_64B;
    end
  endfunction

  virtual protected function void check_tightly_packed();
    bit tightly_packed = (dir == H2C) ? 1'b1 : ({d2hrsp[0].val, d2hrsp[1].val} != 2'b01);
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual protected function void check_rsvd();
    super.check_rsvd();
    if (dir == H2C) begin
      if (|{h2drsp.rsvd, h2dreq.rsvd})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    end
    else begin
      if (|{rsvd, d2hrsp[1].rsvd, d2hrsp[0].rsvd, d2hdat_hdr.rsvd})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    end
  endfunction

  // Parent classes will call these
  virtual function logic [127:0] pack_slot();
    if (dir == H2C) begin
      if (h2dreq_h != null)
        h2dreq = h2dreq_h.req68;
      if (h2drsp_h != null)
        h2drsp = h2drsp_h.rsp68;
      data = {h2drsp, h2dreq, hdr};
    end
    else begin
      if (d2hdat_h != null)
        d2hdat_hdr = d2hdat_h.hdr68;
      foreach (d2hrsp_h[ii])
        if (d2hrsp_h[ii] != null)
          d2hrsp[ii] = d2hrsp_h[ii].rsp68; 
      if (s2mndr_h != null)
        s2mndr = s2mndr_h.ndr68;
      data = {rsvd, s2mndr, d2hrsp[1], d2hrsp[0], d2hdat_hdr, hdr};
    end
    check_tightly_packed();
    check_rsvd();
    check_mdh();
    set_empty_slot();
    set_be_sz();
    return data;
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    create_objects(dir);
    if (dat !== 'x) data = dat;
    if (dir == H2C) begin
      {h2drsp, h2dreq, hdr} = data;
      h2dreq_h.req68 = h2dreq;
      h2drsp_h.rsp68 = h2drsp;
    end
    else begin
      {rsvd, s2mndr, d2hrsp[1], d2hrsp[0], d2hdat_hdr, hdr} = data;
      d2hdat_h.hdr68 = d2hdat_hdr;
      foreach(d2hrsp_h[ii])
        d2hrsp_h[ii].rsp68 = d2hrsp[ii];
      s2mndr_h.ndr68 = s2mndr;
    end
    check_tightly_packed();
    check_rsvd();
    check_mdh();
    set_empty_slot();
  endfunction

endclass

class h1_f68 extends base_hslot_f68;

  `uvm_object_utils(h1_f68)

  /* H2D/M2S */
  logic [7:0]    rsvd = '0;
  h2drsp68_t     h2drsp[1:0]; /**/ rand h2drsp_c h2drsp_h[1:0];
  h2ddat68_hdr_t h2ddat_hdr;  /**/ rand h2ddat_c h2ddat_h;

  /* D2H/S2M */
  d2hdat68_hdr_t d2hdat_hdr; /**/ rand d2hdat_c d2hdat_h;
  d2hreq68_t     d2hreq;     /**/ rand d2hreq_c d2hreq_h;

  function new(string name = "h1_f68");
    super.new(name);
    _fmt = _H1;
  endfunction 

  virtual function void create_objects(dir_t dir, logic [2:0] set_valid = 'x);
    this.dir = dir;
    if (dir == H2C) begin
      h2ddat_h           = h2ddat_c::type_id::create("h2ddat_h");
      h2ddat_h.flitmode  = F68;
      h2ddat_h.hdr68.val = set_valid[0];
      foreach (h2drsp_h[ii]) begin
        h2drsp_h[ii]           = h2drsp_c::type_id::create($sformatf("h2drsp_h[%0d]",ii));
        h2drsp_h[ii].flitmode  = F68;
        h2drsp_h[ii].rsp68.val = set_valid[ii+1];
      end
    end
    else begin
      d2hreq_h           = d2hreq_c::type_id::create("d2hreq_h");
      d2hreq_h.flitmode  = F68;
      d2hreq_h.req68.val = set_valid[0];
      d2hdat_h           = d2hdat_c::type_id::create("d2hdat_h");
      d2hdat_h.flitmode  = F68;
      d2hdat_h.hdr68.val = set_valid[1];
    end
  endfunction

  // If transmitting, randomize will be called; this saves a step
  function void post_randomize();
    super.post_randomize();
    hdr.fmt.slot0 = H1;
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void set_empty_slot();
    empty_slot = (dir == H2C) ? ~|{h2drsp[1].val, h2drsp[0].val, h2ddat_hdr.val} : ~|{d2hdat_hdr.val, d2hreq.val};
    if (dir == H2C) begin
      dat_consumed[0] = h2ddat_hdr.val;
      rsp_consumed[0] = h2drsp[1].val + h2drsp[0].val;
    end 
    else begin
      req_consumed[0] = d2hreq.val;
      dat_consumed[0] = d2hdat_hdr.val;
    end
  endfunction

  virtual protected function void set_be_sz();
    {hdr_be, hdr_sz} = 'z; //default to don't care
    if (dir == H2C && h2ddat_h != null && h2ddat_h.hdr68.val) begin
      hdr_be = 1'b0;
      hdr_sz = h2ddat_h.txfer_64B;
    end
    else if (dir == C2H && d2hdat_h != null && d2hdat_h.hdr68.val) begin
      hdr_be = (d2hdat_h.be != '1);
      hdr_sz = d2hdat_h.txfer_64B;
    end
  endfunction

  virtual protected function void check_tightly_packed();
    bit tightly_packed = (dir == H2C) ? ({h2drsp[0].val, h2drsp[1].val} != 2'b01) : 1'b1;
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual protected function void check_rsvd();
    super.check_rsvd();
    if (dir == H2C) begin
      if (|{rsvd, h2drsp[1].rsvd, h2drsp[0].rsvd, h2ddat_hdr.rsvd})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    end
    else begin
      if (|{d2hdat_hdr.rsvd, d2hreq.rsvd1, d2hreq.rsvd0})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    end
  endfunction

  // Parent classes will call these
  virtual function logic [127:0] pack_slot();
    if (dir == H2C) begin
      if (h2ddat_h != null)
        h2ddat_hdr = h2ddat_h.hdr68;
      foreach(h2drsp_h[ii])
        if (h2drsp_h[ii] != null)
          h2drsp[ii] = h2drsp_h[ii].rsp68;
      data = {rsvd, h2drsp[1], h2drsp[0], h2ddat_hdr, hdr};
    end
    else begin
      if (d2hdat_h != null)
        d2hdat_hdr = d2hdat_h.hdr68;
      if (d2hreq_h != null)
        d2hreq = d2hreq_h.req68;
      data = {d2hdat_hdr, d2hreq, hdr};
    end
    check_tightly_packed();
    check_rsvd();
    check_mdh();
    set_empty_slot();
    set_be_sz();
    return data;
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    create_objects(dir);
    if (dat !== 'x) data = dat;
    if (dir == H2C)  begin
      {rsvd, h2drsp[1], h2drsp[0], h2ddat_hdr, hdr} = data;
      h2ddat_h.hdr68 = h2ddat_hdr;
      foreach (h2drsp_h[ii])
        h2drsp_h[ii].rsp68 = h2drsp[ii];
    end
    else begin
      {d2hdat_hdr, d2hreq, hdr} = data;
      d2hreq_h.req68 = d2hreq;
      d2hdat_h.hdr68 = d2hdat_hdr;
    end
    check_tightly_packed();
    check_rsvd();
    check_mdh();
    set_empty_slot();
  endfunction

endclass

class h2_f68 extends base_hslot_f68;

  `uvm_object_utils(h2_f68)

  logic [7:0] rsvd = '0;

  /* H2D/M2S */
  h2ddat68_hdr_t h2ddat_hdr; /**/ rand h2ddat_c h2ddat_h;
  h2dreq68_t     h2dreq;     /**/ rand h2dreq_c h2dreq_h;

  /* D2H/S2M */
  d2hrsp68_t     d2hrsp;          /**/ rand d2hrsp_c d2hrsp_h;
  d2hdat68_hdr_t d2hdat_hdr[3:0]; /**/ rand d2hdat_c d2hdat_h[3:0];

  function new(string name = "h2_f68");
    super.new(name);
    _fmt = _H2;
  endfunction 

  virtual function void create_objects(dir_t dir, logic [4:0] set_valid = 'x);
    this.dir = dir;
    if (dir == H2C) begin
      h2dreq_h           = h2dreq_c::type_id::create("h2dreq_h");
      h2dreq_h.flitmode  = F68;
      h2dreq_h.req68.val = set_valid[0];
      h2ddat_h           = h2ddat_c::type_id::create("h2ddat_h");
      h2ddat_h.flitmode  = F68;
      h2ddat_h.hdr68.val = set_valid[1];
    end
    else begin
      foreach (d2hdat_h[ii]) begin
        d2hdat_h[ii]           = d2hdat_c::type_id::create($sformatf("d2hdat_h[%0d]",ii));
        d2hdat_h[ii].flitmode  = F68;
        d2hdat_h[ii].hdr68.val = set_valid[ii];
        d2hdat_h[ii].be        = '1;
        d2hdat_h[ii].txfer_64B = 1;
      end
      d2hrsp_h           = d2hrsp_c::type_id::create("d2hrsp_h");
      d2hrsp_h.flitmode  = F68;
      d2hrsp_h.rsp68.val = set_valid[4];
    end
  endfunction

  // If transmitting, randomize will be called; this saves a step
  function void post_randomize();
    super.post_randomize();
    hdr.fmt.slot0 = H2;
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void set_empty_slot();
    empty_slot = (dir == H2C) ? ~|{h2ddat_hdr.val, h2dreq.val} : ~|{d2hrsp.val, d2hdat_hdr.or() with (item.val)};
    if (dir == H2C) begin
      req_consumed[0] = h2dreq.val;
      dat_consumed[0] = h2ddat_hdr.val;
    end 
    else begin
      dat_consumed[0] = d2hdat_hdr.sum() with (int'(item.val));
      rsp_consumed[0] = d2hrsp.val;
    end
  endfunction

  virtual protected function void set_be_sz();
    {hdr_be, hdr_sz} = 'z; //default to don't care
    if (dir == H2C && h2ddat_h != null && h2ddat_h.hdr68.val) begin
      hdr_be = 1'b0;
      hdr_sz = h2ddat_h.txfer_64B;
    end
    else if (dir == C2H) begin 
      hdr_be = 1'b0;
      hdr_sz = 1'b1;
    end
  endfunction

  virtual protected function void check_tightly_packed();
    bit tightly_packed = 1'b1;
    if (dir == C2H) begin
      casez({d2hdat_hdr[0].val, d2hdat_hdr[1].val, d2hdat_hdr[2].val, d2hdat_hdr[3].val})
        4'b01?? : tightly_packed = 1'b0;
        4'b001? : tightly_packed = 1'b0;
        4'b0001 : tightly_packed = 1'b0;
        4'b101? : tightly_packed = 1'b0;
        4'b1001 : tightly_packed = 1'b0;
        4'b1101 : tightly_packed = 1'b0;
        default : tightly_packed = 1'b1;
      endcase 
    end
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual protected function void check_rsvd();
    super.check_rsvd();
    if (dir == H2C) begin
      if (|{rsvd, h2ddat_hdr.rsvd, h2dreq.rsvd})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    end
    else begin
      if (|{rsvd, d2hrsp.rsvd, d2hdat_hdr.or with (item.rsvd)})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
      if (d2hdat_hdr.sum() with (int'(item.val)) <= 1)
        `uvm_error(get_type_name, "MDH must have >1 valid header; see CXL spec")
    end
  endfunction

  // Parent classes will call these
  virtual function logic [127:0] pack_slot();
    if (dir == H2C) begin
      if (h2ddat_h != null)
        h2ddat_hdr = h2ddat_h.hdr68;
      if (h2dreq_h != null)
        h2dreq = h2dreq_h.req68;
      data = {rsvd, h2ddat_hdr, h2dreq, hdr};
    end
    else begin
      foreach (d2hdat_h[ii])
        if (d2hdat_h[ii] != null)
          d2hdat_hdr[ii] = d2hdat_h[ii].hdr68;
      if (d2hrsp_h != null)
        d2hrsp = d2hrsp_h.rsp68;
      data = {rsvd, d2hrsp, d2hdat_hdr[3], d2hdat_hdr[2], d2hdat_hdr[1], d2hdat_hdr[0], hdr};
    end
    check_tightly_packed();
    check_rsvd();
    check_mdh();
    set_empty_slot();
    set_be_sz();
    return data;
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    create_objects(dir);
    if (dat !== 'x) data = dat;
    if (dir == H2C) begin
      {rsvd, h2ddat_hdr, h2dreq, hdr} = data;
      h2dreq_h.req68 = h2dreq;  
      h2ddat_h.hdr68 = h2ddat_hdr;
    end
    else begin
      {rsvd, d2hrsp, d2hdat_hdr[3], d2hdat_hdr[2], d2hdat_hdr[1], d2hdat_hdr[0], hdr} = data;
      d2hrsp_h.rsp68 = d2hrsp;  
      foreach (d2hdat_hdr[ii])
        d2hdat_h[ii].hdr68 = d2hdat_hdr[ii];
    end
    check_tightly_packed();
    check_rsvd();
    check_mdh();
    set_empty_slot();
  endfunction

endclass

class h3_f68 extends base_hslot_f68;

  `uvm_object_utils(h3_f68)

  /* H2D/M2S */
  h2ddat68_hdr_t h2ddat_hdr[3:0]; /**/ rand h2ddat_c h2ddat_h[3:0];

  /* D2H/S2M */
  logic [25:0]   rsvd = '0;
  s2mndr68_t     s2mndr;     /**/ rand s2mndr_c s2mndr_h;
  s2mdrs68_hdr_t s2mdrs_hdr; /**/ rand s2mdrs_c s2mdrs_h;

  function new(string name = "h3_f68");
    super.new(name);
    _fmt = _H3;
  endfunction 

  virtual function void create_objects(dir_t dir, logic [3:0] set_valid = 'x);
    this.dir = dir;
    if (dir == H2C) begin
      foreach (h2ddat_h[ii]) begin
        h2ddat_h[ii]           = h2ddat_c::type_id::create($sformatf("h2ddat_h[%0d]",ii));
        h2ddat_h[ii].flitmode  = F68;
        h2ddat_h[ii].hdr68.val = set_valid[ii];
        h2ddat_h[ii].txfer_64B = 1;
      end
    end
    else begin
      s2mdrs_h           = s2mdrs_c::type_id::create("s2mdrs_h");
      s2mdrs_h.flitmode  = F68;
      s2mdrs_h.hdr68.val = set_valid[0];
      s2mndr_h           = s2mndr_c::type_id::create("s2mndr_h");
      s2mndr_h.flitmode  = F68;
      s2mndr_h.ndr68.val = set_valid[1];
    end
  endfunction

  // If transmitting, randomize will be called; this saves a step
  function void post_randomize();
    super.post_randomize();
    hdr.fmt.slot0 = H3;
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void set_empty_slot();
    empty_slot = (dir == H2C) ? !(h2ddat_hdr.or() with (item.val)) : ~|{s2mndr.val, s2mdrs_hdr.val};
    if (dir == H2C) begin
      dat_consumed[0] = h2ddat_hdr.sum() with (int'(item.val));
    end 
    else begin
      dat_consumed[1] = s2mdrs_hdr.val;
      rsp_consumed[1] = s2mndr.val;
    end
  endfunction

  virtual protected function void set_be_sz();
    {hdr_be, hdr_sz} = 'z; //default to don't care
    if (dir == H2C) begin
      hdr_be = 1'b0;
      hdr_sz = 1'b1;
    end
    else if (s2mdrs_h != null && s2mdrs_h.hdr68.val) begin
      hdr_be = 1'b0;
      hdr_sz = s2mdrs_h.txfer_64B;
    end
  endfunction

  virtual protected function void check_tightly_packed();
    bit tightly_packed = 1'b1;
    if (dir == H2C) begin
      casez({h2ddat_hdr[0].val, h2ddat_hdr[1].val, h2ddat_hdr[2].val, h2ddat_hdr[3].val})
        4'b01?? : tightly_packed = 1'b0;
        4'b001? : tightly_packed = 1'b0;
        4'b0001 : tightly_packed = 1'b0;
        4'b101? : tightly_packed = 1'b0;
        4'b1001 : tightly_packed = 1'b0;
        4'b1101 : tightly_packed = 1'b0;
        default : tightly_packed = 1'b1;
      endcase 
    end
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual protected function void check_rsvd();
    super.check_rsvd();
    if (dir == H2C) begin
      if (h2ddat_hdr.or() with (item.rsvd))
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
      if (h2ddat_hdr.sum() with (int'(item.val)) <= 1)
        `uvm_error(get_type_name, "MDH must have >1 valid header; see CXL spec")
    end
    else begin
      if (|{rsvd, s2mdrs_hdr.rsvd})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    end
  endfunction

  // Parent classes will call these
  virtual function logic [127:0] pack_slot();
    if (dir == H2C) begin
      foreach (h2ddat_h[ii]) 
        if (h2ddat_h[ii] != null)
          h2ddat_hdr[ii] = h2ddat_h[ii].hdr68;
      data = {h2ddat_hdr[3], h2ddat_hdr[2], h2ddat_hdr[1], h2ddat_hdr[0], hdr};
    end
    else begin
      if (s2mdrs_h != null)
        s2mdrs_hdr = s2mdrs_h.hdr68;
      if (s2mndr_h != null)
        s2mndr = s2mndr_h.ndr68;
      data = {rsvd, s2mndr, s2mdrs_hdr, hdr};
    end
    check_tightly_packed();
    check_rsvd();
    check_mdh();
    set_empty_slot();
    set_be_sz();
    return data;
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    create_objects(dir);
    if (dat !== 'x) data = dat;
    if (dir == H2C) begin
      {h2ddat_hdr[3], h2ddat_hdr[2], h2ddat_hdr[1], h2ddat_hdr[0], hdr} = data;
      foreach (h2ddat_hdr[ii])
        h2ddat_h[ii].hdr68 = h2ddat_hdr[ii];
    end
    else begin
      {rsvd, s2mndr, s2mdrs_hdr, hdr} = data;
      s2mdrs_h.hdr68 = s2mdrs_hdr;
      s2mndr_h.ndr68 = s2mndr;
    end
    check_tightly_packed();
    check_rsvd();
    check_mdh();
    set_empty_slot();
  endfunction

endclass

class h4_f68 extends base_hslot_f68;

  `uvm_object_utils(h4_f68)

  /* H2D/M2S */
//logic [7:0]    rsvd; 
  m2srwd68_hdr_t m2srwd_hdr; /**/ rand m2srwd_c m2srwd_h;

  /* D2H/S2M */
  logic [35:0] rsvd = '0;
  s2mndr68_t   s2mndr[1:0]; /**/ rand s2mndr_c s2mndr_h[1:0];

  function new(string name = "h4_f68");
    super.new(name);
    _fmt = _H4;
  endfunction 

  virtual function void create_objects(dir_t dir, logic [1:0] set_valid = 'x);
    this.dir = dir;
    if (dir == H2C) begin
      m2srwd_h           = m2srwd_c::type_id::create("m2srwd_h");
      m2srwd_h.flitmode  = F68;
      m2srwd_h.hdr68.val = set_valid[0];
    end
    else begin
      foreach (s2mndr_h[ii]) begin
        s2mndr_h[ii]           = s2mndr_c::type_id::create($sformatf("s2mndr_h[%0d]",ii));
        s2mndr_h[ii].flitmode  = F68;
        s2mndr_h[ii].ndr68.val = set_valid[ii];
      end
    end
  endfunction

  // If transmitting, randomize will be called; this saves a step
  function void post_randomize();
    super.post_randomize();
    hdr.fmt.slot0 = H4;
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void set_empty_slot();
    empty_slot = (dir == H2C) ? !m2srwd_hdr.val : !(s2mndr.or() with (item.val));
    if (dir == H2C) begin
      dat_consumed[1] = m2srwd_hdr.val;
    end 
    else begin
      rsp_consumed[1] = s2mndr.sum() with (int'(item.val));
    end
  endfunction

  virtual protected function void set_be_sz();
    {hdr_be, hdr_sz} = 'z; //default to don't care
    if (dir == H2C && m2srwd_h != null && m2srwd_h.hdr68.val) begin
      hdr_be = (m2srwd_h.be != '1);
      hdr_sz = 1'b1;
    end
  endfunction

  virtual protected function void check_tightly_packed();
    bit tightly_packed = (dir == H2C) ? 1'b1 : ({s2mndr[0], s2mndr[1]} != 2'b01); 
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual protected function void check_rsvd();
    super.check_rsvd();
    if (dir == H2C) begin
      if (|{rsvd[7:0], m2srwd_hdr.rsvd})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    end
    else begin
      if (rsvd)
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    end
  endfunction

  // Parent classes will call these
  virtual function logic [127:0] pack_slot();
    if (dir == H2C) begin
      if (m2srwd_h != null)
        m2srwd_hdr = m2srwd_h.hdr68;
      data = {rsvd[7:0], m2srwd_hdr, hdr};
    end
    else begin
      foreach (s2mndr_h[ii]) 
        if (s2mndr_h[ii] != null)
          s2mndr[ii] = s2mndr_h[ii].ndr68;
      data = {rsvd, s2mndr[0].devload, s2mndr[1], s2mndr[0][27:0], hdr};
    end
    check_tightly_packed();
    check_rsvd();
    check_mdh();
    set_empty_slot();
    set_be_sz();
    return data;
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    create_objects(dir);
    if (dat !== 'x) data = dat;
    if (dir == H2C) begin
      {rsvd[7:0], m2srwd_hdr, hdr} = data;
      m2srwd_h.hdr68 = m2srwd_hdr;
    end
    else begin
      {rsvd, s2mndr[0].devload, s2mndr[1], s2mndr[0][27:0], hdr} = data;
      foreach (s2mndr_h[ii])
        s2mndr_h[ii].ndr68 = s2mndr[ii];
    end
    check_tightly_packed();
    check_rsvd();
    check_mdh();
    set_empty_slot();
  endfunction

endclass

class h5_f68 extends base_hslot_f68;

  `uvm_object_utils(h5_f68)

  /* H2D/M2S */
//logic [8:0] rsvd;
  m2sreq68_t  m2sreq; /**/ rand m2sreq_c m2sreq_h;

  /* D2H/S2M */
  logic [15:0]   rsvd = '0;
  s2mdrs68_hdr_t s2mdrs_hdr[1:0]; /**/ rand s2mdrs_c s2mdrs_h[1:0];

  function new(string name = "h5_f68");
    super.new(name);
    _fmt = _H5;
  endfunction 

  virtual function void create_objects(dir_t dir, logic [1:0] set_valid = 'x);
    this.dir = dir;
    if (dir == H2C) begin
      m2sreq_h           = m2sreq_c::type_id::create("m2sreq_h");
      m2sreq_h.flitmode  = F68;
      m2sreq_h.req68.val = set_valid[0];
    end
    else begin
      foreach (s2mdrs_h[ii]) begin
        s2mdrs_h[ii]           = s2mdrs_c::type_id::create($sformatf("s2mdrs_h[%0d]",ii));
        s2mdrs_h[ii].flitmode  = F68;
        s2mdrs_h[ii].hdr68.val = set_valid[ii];
        s2mdrs_h[ii].txfer_64B = 1;
      end
    end
  endfunction

  // If transmitting, randomize will be called; this saves a step
  function void post_randomize();
    super.post_randomize();
    hdr.fmt.slot0 = H5;
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void set_empty_slot();
    empty_slot = (dir == H2C) ? !m2sreq.val : !(s2mdrs_hdr.or() with (item.val));
    if (dir == H2C) begin
      req_consumed[1] = m2sreq.val;
    end 
    else begin
      dat_consumed[1] = s2mdrs_hdr.sum() with (int'(item.val));
    end
  endfunction

  virtual protected function void set_be_sz();
    {hdr_be, hdr_sz} = 'z; //default to don't care
    if (dir == C2H) begin
      hdr_be = 1'b0;
      hdr_sz = 1'b1;
    end
  endfunction

  virtual protected function void check_tightly_packed();
    bit tightly_packed = (dir == H2C) ? 1'b1 : ({s2mdrs_hdr[0].val,s2mdrs_hdr[1].val} != 2'b01);
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual protected function void check_rsvd();
    super.check_rsvd();
    if (dir == H2C) begin
      if (|{rsvd[8:0], m2sreq.rsvd})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    end
    else begin
      if (|{rsvd, s2mdrs_hdr[1].rsvd, s2mdrs_hdr[0].rsvd})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
      if (s2mdrs_hdr.sum() with (int'(item.val)) <= 1)
        `uvm_error(get_type_name, "MDH must have >1 valid header; see CXL spec")
    end
  endfunction

  // Parent classes will call these
  virtual function logic [127:0] pack_slot();
    if (dir == H2C) begin
      if (m2sreq_h != null)
        m2sreq = m2sreq_h.req68;
      data = {rsvd[8:0], m2sreq, hdr};
    end
    else begin
      foreach (s2mdrs_h[ii]) 
        if (s2mdrs_h[ii] != null)
          s2mdrs_hdr[ii] = s2mdrs_h[ii].hdr68;
      data = {rsvd, s2mdrs_hdr[1], s2mdrs_hdr[0], hdr};
    end
    check_tightly_packed();
    check_rsvd();
    check_mdh();
    set_empty_slot();
    set_be_sz();
    return data;
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    create_objects(dir);
    if (dat !== 'x) data = dat;
    if (dir == H2C) begin
      {rsvd[8:0], m2sreq, hdr} = data;
      m2sreq_h.req68 = m2sreq;
    end
    else begin
      {rsvd, s2mdrs_hdr[1], s2mdrs_hdr[0], hdr} = data;
      foreach (s2mdrs_hdr[ii])
        s2mdrs_h[ii].hdr68 = s2mdrs_hdr[ii];
    end
    check_tightly_packed();
    check_rsvd();
    check_mdh();
    set_empty_slot();
  endfunction

endclass

class h6_f68 extends base_hslot_f68;

  `uvm_object_utils(h6_f68)

  /* H2D/M2S and D2H/S2M */
  logic [95:0] mac;

  function new(string name = "h6_f68");
    super.new(name);
    _fmt = _H6;
    empty_slot = 1'b0;
  endfunction 

  // Parent classes will call these
  virtual function logic [127:0] pack_slot();
    data = {mac, hdr};
    check_rsvd();
    check_mdh();
    return data;
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    this.dir = dir;
    if (dat !== 'x) data = dat;
    {mac, hdr} = data;
    check_rsvd();
    check_mdh();
  endfunction

endclass
