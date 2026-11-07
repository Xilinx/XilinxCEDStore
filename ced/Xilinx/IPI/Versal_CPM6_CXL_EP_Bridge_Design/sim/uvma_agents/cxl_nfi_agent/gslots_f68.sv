// - Contains all generic slot classes G0-G6 for 68B flits
// - Each class is shared between H2C and C2H directions
// - Each slot class contains a struct to pack/unpack messages, and
//   also includes an object handle for messages that don't include data
// - Can specify message to pack through the object handle or the struct,
//   with the object handle taking precedence 
// - Data messages have to be packed and unpacked externally
class g0_f68 extends slot_base;

  `uvm_object_utils(g0_f68)

  function new(string name = "g0_f68");
    super.new(name);
    {hdr_be, hdr_sz} = 'z; //don't care
    _fmt = _G0;
    empty_slot = 1'b0;
  endfunction 

endclass

class g0be_f68 extends slot_base;

  `uvm_object_utils(g0be_f68)

  logic [63:0] rsvd = '0;
  logic [63:0] be;

  function new(string name = "g0be_f68");
    super.new(name);
    _fmt = _G0_BE;
    {hdr_be, hdr_sz} = 'z; //don't care
    empty_slot = 1'b0;
  endfunction 

  // Protected; called by pack/unpack
  virtual protected function void check_rsvd();
    if (rsvd)
      `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
  endfunction

  // Parent classes will call these
  virtual function logic [127:0] pack_slot();
    data = {rsvd, be};
    check_rsvd();
    return data;
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    this.dir = dir;
    if (dat !== 'x) data = dat;
    {rsvd, be} = data;
    check_rsvd();
  endfunction

endclass

class g1_f68 extends slot_base;

  `uvm_object_utils(g1_f68)

  /* H2D/M2S */
  h2drsp68_t h2drsp[3:0]; /**/ rand h2drsp_c h2drsp_h[3:0];

  /* D2H/S2M */
  logic [8:0] rsvd = '0;
  d2hrsp68_t  d2hrsp[1:0]; /**/ rand d2hrsp_c d2hrsp_h[1:0];
  d2hreq68_t  d2hreq;      /**/ rand d2hreq_c d2hreq_h;

  function new(string name = "g1_f68");
    super.new(name);
    _fmt = _G1;
  endfunction 

  virtual function void create_objects(dir_t dir, logic [3:0] set_valid = 'x);
    this.dir = dir;
    if (dir == H2C) begin
      foreach (h2drsp_h[ii]) begin 
        h2drsp_h[ii]           = h2drsp_c::type_id::create($sformatf("h2drsp_h[%0d]",ii));
        h2drsp_h[ii].flitmode  = F68;
        h2drsp_h[ii].rsp68.val = set_valid[ii];
      end
    end
    else begin
      d2hreq_h           = d2hreq_c::type_id::create("d2hreq_h");
      d2hreq_h.flitmode  = F68;
      d2hreq_h.req68.val = set_valid[0];
      foreach (d2hrsp_h[ii]) begin
        d2hrsp_h[ii]           = d2hrsp_c::type_id::create($sformatf("d2hrsp_h[%0d]",ii));
        d2hrsp_h[ii].flitmode  = F68;
        d2hrsp_h[ii].rsp68.val = set_valid[ii+1];
      end
    end
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void set_empty_slot();
    empty_slot = (dir == H2C) ? !(h2drsp.or() with (item.val)) : ~|{d2hrsp.or() with (item.val), d2hreq.val};
    if (dir == H2C) begin
      rsp_consumed[0] = h2drsp.sum() with (int'(item.val));
    end
    else begin
      req_consumed[0] = d2hreq.val;
      rsp_consumed[0] = d2hrsp.sum() with (int'(item.val));
    end
  endfunction

  virtual protected function void set_be_sz();
    {hdr_be, hdr_sz} = 'z; //default to don't care
  endfunction

  virtual protected function void check_tightly_packed();
    bit tightly_packed;
    if (dir == H2C) begin
      casez({h2drsp[0].val, h2drsp[1].val, h2drsp[2].val, h2drsp[3].val})
        4'b01?? : tightly_packed = 1'b0;
        4'b?01? : tightly_packed = 1'b0;
        4'b??01 : tightly_packed = 1'b0;
        default : tightly_packed = 1'b1;
      endcase 
    end
    else
      tightly_packed = ({d2hrsp[0].val, d2hrsp[1].val} != 2'b01);
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual protected function void check_rsvd();
    if (dir == H2C) begin
      if (h2drsp.or() with (item.rsvd))
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    end 
    else begin
      if (|{rsvd, d2hrsp[1].rsvd, d2hrsp[0].rsvd, d2hreq.rsvd1, d2hreq.rsvd0})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    end
  endfunction

  // Parent classes will call these
  virtual function logic [127:0] pack_slot();
    if (dir == H2C) begin
      foreach (h2drsp_h[ii])
        if (h2drsp_h[ii] != null) 
          h2drsp[ii] = h2drsp_h[ii].rsp68;
      data = {h2drsp[3], h2drsp[2], h2drsp[1], h2drsp[0]};
    end
    else begin
      if (d2hreq_h != null)
        d2hreq = d2hreq_h.req68;
      foreach (d2hrsp_h[ii])
        if (d2hrsp_h[ii] != null) 
          d2hrsp[ii] = d2hrsp_h[ii].rsp68;
      data = {rsvd, d2hrsp[1], d2hrsp[0], d2hreq};
    end
    check_tightly_packed();
    check_rsvd();
    set_empty_slot();
    set_be_sz();
    return data;
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    create_objects(dir);
    if (dat !== 'x) data = dat;
    if (dir == H2C) begin
      {h2drsp[3], h2drsp[2], h2drsp[1], h2drsp[0]} = data;
      foreach (h2drsp_h[ii])
        h2drsp_h[ii].rsp68 = h2drsp[ii];
    end
    else begin
      {rsvd, d2hrsp[1], d2hrsp[0], d2hreq} = data;
      d2hreq_h.req68 = d2hreq;
      foreach (d2hrsp_h[ii])
        d2hrsp_h[ii].rsp68 = d2hrsp[ii];
    end
    check_tightly_packed();
    check_rsvd();
    set_empty_slot();
  endfunction

endclass

class g2_f68 extends slot_base;

  `uvm_object_utils(g2_f68)

  /* H2D/M2S */
//logic [7:0]  rsvd;
  h2drsp68_t     h2drsp;     /**/ rand h2drsp_c h2drsp_h;
  h2ddat68_hdr_t h2ddat_hdr; /**/ rand h2ddat_c h2ddat_h;
  h2dreq68_t     h2dreq;     /**/ rand h2dreq_c h2dreq_h;

  /* D2H/S2M */
  logic [11:0]   rsvd = '0;
  d2hrsp68_t     d2hrsp;     /**/ rand d2hrsp_c d2hrsp_h;
  d2hdat68_hdr_t d2hdat_hdr; /**/ rand d2hdat_c d2hdat_h;
  d2hreq68_t     d2hreq;     /**/ rand d2hreq_c d2hreq_h;

  function new(string name = "g2_f68");
    super.new(name);
    _fmt = _G2;
  endfunction 

  virtual function void create_objects(dir_t dir, logic [2:0] set_valid = 'x);
    this.dir = dir;
    if (dir == H2C) begin
      h2dreq_h           = h2dreq_c::type_id::create("h2dreq_h");
      h2dreq_h.flitmode  = F68;
      h2dreq_h.req68.val = set_valid[0];
      h2ddat_h           = h2ddat_c::type_id::create("h2ddat_h");
      h2ddat_h.flitmode  = F68;
      h2ddat_h.hdr68.val = set_valid[1];
      h2drsp_h           = h2drsp_c::type_id::create("h2drsp_h");
      h2drsp_h.flitmode  = F68;
      h2drsp_h.rsp68.val = set_valid[2];
    end
    else begin
      d2hreq_h           = d2hreq_c::type_id::create("d2hreq_h");
      d2hreq_h.flitmode  = F68;
      d2hreq_h.req68.val = set_valid[0];
      d2hdat_h           = d2hdat_c::type_id::create("d2hdat_h");
      d2hdat_h.flitmode  = F68;
      d2hdat_h.hdr68.val = set_valid[1];
      d2hrsp_h           = d2hrsp_c::type_id::create("d2hrsp_h");
      d2hrsp_h.flitmode  = F68;
      d2hrsp_h.rsp68.val = set_valid[2];
    end
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void set_empty_slot();
    empty_slot = (dir == H2C) ? ~|{h2drsp.val, h2ddat_hdr.val, h2dreq.val} : ~|{d2hrsp.val, d2hdat_hdr.val, d2hreq.val};
    if (dir == H2C) begin
      req_consumed[0] = h2dreq.val;
      dat_consumed[0] = h2ddat_hdr.val;
      rsp_consumed[0] = h2drsp.val;
    end
    else begin
      req_consumed[0] = d2hreq.val;
      dat_consumed[0] = d2hdat_hdr.val;
      rsp_consumed[0] = d2hrsp.val;
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

  virtual protected function void check_rsvd();
    if (dir == H2C) begin
      if (|{rsvd[7:0], h2drsp.rsvd, h2ddat_hdr.rsvd, h2dreq.rsvd})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    end 
    else begin
      if (|{rsvd, d2hrsp.rsvd, d2hdat_hdr.rsvd, d2hreq.rsvd1, d2hreq.rsvd0})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    end
  endfunction

  // Parent classes will call these
  virtual function logic [127:0] pack_slot();
    if (dir == H2C) begin
      if (h2dreq_h != null)
        h2dreq = h2dreq_h.req68;
      if (h2ddat_h != null)
        h2ddat_hdr = h2ddat_h.hdr68;
      if (h2drsp_h != null)
        h2drsp = h2drsp_h.rsp68;
      data = {rsvd[7:0], h2drsp, h2ddat_hdr, h2dreq};
    end
    else begin
      if (d2hreq_h != null)
        d2hreq = d2hreq_h.req68;
      if (d2hdat_h != null)
        d2hdat_hdr = d2hdat_h.hdr68;
      if (d2hrsp_h != null)
        d2hrsp = d2hrsp_h.rsp68;
      data = {rsvd, d2hrsp, d2hdat_hdr, d2hreq};
    end
    check_rsvd();
    set_empty_slot();
    set_be_sz();
    return data;
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    create_objects(dir);
    if (dat !== 'x) data = dat;
    if (dir == H2C) begin
      {rsvd[7:0], h2drsp, h2ddat_hdr, h2dreq} = data;
      h2dreq_h.req68 = h2dreq; 
      h2ddat_h.hdr68 = h2ddat_hdr;
      h2drsp_h.rsp68 = h2drsp; 
    end
    else begin
      {rsvd, d2hrsp, d2hdat_hdr, d2hreq} = data;
      d2hreq_h.req68 = d2hreq; 
      d2hdat_h.hdr68 = d2hdat_hdr;
      d2hrsp_h.rsp68 = d2hrsp; 
    end
    check_rsvd();
    set_empty_slot();
  endfunction

endclass

class g3_f68 extends slot_base;

  `uvm_object_utils(g3_f68)

  /* H2D/M2S */
  h2drsp68_t     h2drsp;          /**/ rand h2drsp_c h2drsp_h;
  h2ddat68_hdr_t h2ddat_hdr[3:0]; /**/ rand h2ddat_c h2ddat_h[3:0];

  /* D2H/S2M */
  logic [59:0]   rsvd = '0;
  d2hdat68_hdr_t d2hdat_hdr[3:0]; /**/ rand d2hdat_c d2hdat_h[3:0];

  function new(string name = "g3_f68");
    super.new(name);
    _fmt = _G3;
  endfunction 

  virtual function void create_objects(dir_t dir, logic [4:0] set_valid = 'x);
    this.dir = dir;
    if (dir == H2C) begin
      foreach (h2ddat_h[ii]) begin
        h2ddat_h[ii]           = h2ddat_c::type_id::create($sformatf("h2ddat_h[%0d]",ii));
        h2ddat_h[ii].flitmode  = F68;
        h2ddat_h[ii].hdr68.val = set_valid[ii];
        h2ddat_h[ii].txfer_64B = 1;
      end
      h2drsp_h           = h2drsp_c::type_id::create("h2drsp_h");
      h2drsp_h.flitmode  = F68;
      h2drsp_h.rsp68.val = set_valid[4];
    end
    else begin
      foreach (d2hdat_h[ii]) begin
        d2hdat_h[ii]           = d2hdat_c::type_id::create($sformatf("d2hdat_h[%0d]",ii));
        d2hdat_h[ii].flitmode  = F68;
        d2hdat_h[ii].hdr68.val = set_valid[ii];
        d2hdat_h[ii].be        = '1;
        d2hdat_h[ii].txfer_64B = 1;
      end
    end
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void set_empty_slot();
    empty_slot = (dir == H2C) ? ~|{h2drsp.val, (h2ddat_hdr.or() with (item.val))} : !(d2hdat_hdr.or() with (item.val));
    if (dir == H2C) begin
      dat_consumed[0] = h2ddat_hdr.sum() with (int'(item.val));
      rsp_consumed[0] = h2drsp.val;
    end
    else begin
      dat_consumed[0] = d2hdat_hdr.sum() with (int'(item.val));
    end
  endfunction

  virtual protected function void set_be_sz();
    {hdr_be, hdr_sz} = 2'b01; 
  endfunction

  virtual protected function void check_tightly_packed();
    bit tightly_packed;
    if (dir == H2C) begin
      casez({h2ddat_hdr[0].val, h2ddat_hdr[1].val, h2ddat_hdr[2].val, h2ddat_hdr[3].val})
        4'b01?? : tightly_packed = 1'b0;
        4'b?01? : tightly_packed = 1'b0;
        4'b??01 : tightly_packed = 1'b0;
        default : tightly_packed = 1'b1;
      endcase 
    end
    else begin
      casez({d2hdat_hdr[0].val, d2hdat_hdr[1].val, d2hdat_hdr[2].val, d2hdat_hdr[3].val})
        4'b01?? : tightly_packed = 1'b0;
        4'b?01? : tightly_packed = 1'b0;
        4'b??01 : tightly_packed = 1'b0;
        default : tightly_packed = 1'b1;
      endcase 
    end
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual protected function void check_rsvd();
    if (dir == H2C) begin
      if (|{h2drsp.rsvd, h2ddat_hdr.or() with (item.rsvd)})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
      if (h2ddat_hdr.sum() with (int'(item.val)) <= 1)
        `uvm_error(get_type_name, "MDH must have >1 valid header; see CXL spec")
    end 
    else begin
      if (|{rsvd, d2hdat_hdr.or with (item.rsvd)})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
      if (d2hdat_hdr.sum() with (int'(item.val)) <= 1)
        `uvm_error(get_type_name, "MDH must have >1 valid header; see CXL spec")
    end
  endfunction

  // Parent classes will call these
  virtual function logic [127:0] pack_slot();
    if (dir == H2C) begin    
      if (h2drsp_h != null)
        h2drsp = h2drsp_h.rsp68;
      foreach (h2ddat_h[ii]) begin
        if (h2ddat_h[ii] != null)
          h2ddat_hdr[ii] = h2ddat_h[ii].hdr68;
      end
      data = {h2drsp, h2ddat_hdr[3], h2ddat_hdr[2], h2ddat_hdr[1], h2ddat_hdr[0]};
    end
    else begin
      foreach (d2hdat_h[ii]) begin
        if (d2hdat_h[ii] != null)
          d2hdat_hdr[ii] = d2hdat_h[ii].hdr68;
      end
      data = {rsvd, d2hdat_hdr[3], d2hdat_hdr[2], d2hdat_hdr[1], d2hdat_hdr[0]};
    end
    check_tightly_packed();
    check_rsvd();
    set_empty_slot();
    set_be_sz();
    return data;
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    create_objects(dir);
    if (dat !== 'x) data = dat;
    if (dir == H2C) begin
      {h2drsp, h2ddat_hdr[3], h2ddat_hdr[2], h2ddat_hdr[1], h2ddat_hdr[0]} = data;
      h2drsp_h.rsp68 = h2drsp;
      foreach (h2ddat_hdr[ii]) 
        h2ddat_h[ii].hdr68 = h2ddat_hdr[ii];
    end
    else begin
      {rsvd, d2hdat_hdr[3], d2hdat_hdr[2], d2hdat_hdr[1], d2hdat_hdr[0]} = data;
      foreach (d2hdat_hdr[ii]) 
        d2hdat_h[ii].hdr68 = d2hdat_hdr[ii];
    end
    check_tightly_packed();
    check_rsvd();
    set_empty_slot();
  endfunction

endclass

class g4_f68 extends slot_base;

  `uvm_object_utils(g4_f68)

  /* H2D/M2S */
  logic [15:0]   rsvd1 = '0;
  h2ddat68_hdr_t h2ddat_hdr; /**/ rand h2ddat_c h2ddat_h;
  logic          rsvd0 = '0;
  m2sreq68_t     m2sreq;     /**/ rand m2sreq_c m2sreq_h;

  /* D2H/S2M */
  logic [27:0]   rsvd = '0;
  s2mndr68_t     s2mndr[1:0]; /**/ rand s2mndr_c s2mndr_h[1:0];
  s2mdrs68_hdr_t s2mdrs_hdr;  /**/ rand s2mdrs_c s2mdrs_h;

  function new(string name = "g4_f68");
    super.new(name);
    _fmt = _G4;
  endfunction 

  virtual function void create_objects(dir_t dir, logic [2:0] set_valid = 'x);
    this.dir = dir;
    if (dir == H2C) begin
      m2sreq_h           = m2sreq_c::type_id::create("m2sreq_h");
      m2sreq_h.flitmode  = F68;
      m2sreq_h.req68.val = set_valid[0];
      h2ddat_h           = h2ddat_c::type_id::create("h2ddat_h");
      h2ddat_h.flitmode  = F68;
      h2ddat_h.hdr68.val = set_valid[1];
    end
    else begin
      s2mdrs_h           = s2mdrs_c::type_id::create("s2mdrs_h");
      s2mdrs_h.flitmode  = F68;
      s2mdrs_h.hdr68.val = set_valid[0];
      foreach (s2mndr_h[ii]) begin
        s2mndr_h[ii]           = s2mndr_c::type_id::create($sformatf("s2mndr_h[%0d]",ii));
        s2mndr_h[ii].flitmode  = F68;
        s2mndr_h[ii].ndr68.val = set_valid[ii+1];
      end
    end
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void set_empty_slot();
    empty_slot = (dir == H2C) ? ~|{h2ddat_hdr.val, m2sreq.val} : ~|{s2mdrs_hdr.val, s2mndr.or() with (item.val)};
    if (dir == H2C) begin
      req_consumed[1] = m2sreq.val;
      dat_consumed[0] = h2ddat_hdr.val;
    end
    else begin
      rsp_consumed[1] = s2mndr.sum() with (int'(item.val));
      dat_consumed[1] = s2mdrs_hdr.val;
    end
  endfunction

  virtual protected function void set_be_sz();
    {hdr_be, hdr_sz} = 'z; //default to don't care
    if (dir == H2C && h2ddat_h != null && h2ddat_h.hdr68.val) begin
      hdr_be = 1'b0;
      hdr_sz = h2ddat_h.txfer_64B;
    end
    else if (dir == C2H && s2mdrs_h != null && s2mdrs_h.hdr68.val) begin
      hdr_be = 1'b0;
      hdr_sz = s2mdrs_h.txfer_64B;
    end
  endfunction

  virtual protected function void check_tightly_packed();
    bit tightly_packed = (dir == H2C) ? 1'b1 : ({s2mndr[0].val, s2mndr[1].val} != 2'b01);
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual protected function void check_rsvd();
    if (dir == H2C) begin
      if (|{rsvd1, h2ddat_hdr.rsvd, rsvd0, m2sreq.rsvd})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    end 
    else begin
      if (|{rsvd, s2mdrs_hdr.rsvd})
        `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    end
  endfunction

  // Parent classes will call these
  virtual function logic [127:0] pack_slot();
    if (dir == H2C) begin
      if (m2sreq_h != null)
        m2sreq = m2sreq_h.req68;
      if (h2ddat_h != null)
        h2ddat_hdr = h2ddat_h.hdr68;
      data = {rsvd1, h2ddat_hdr, rsvd0, m2sreq};
    end
    else begin
      if (s2mdrs_h != null) 
        s2mdrs_hdr = s2mdrs_h.hdr68;
      foreach (s2mndr_h[ii])
        if (s2mndr_h[ii] != null)
          s2mndr[ii] = s2mndr_h[ii].ndr68;
      data = {rsvd, s2mndr[0].devload, s2mndr[1], s2mndr[0][27:0], s2mdrs_hdr};
    end
    check_tightly_packed();
    check_rsvd();
    set_empty_slot();
    set_be_sz();
    return data;
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    create_objects(dir);
    if (dat !== 'x) data = dat;
    if (dir == H2C) begin
      {rsvd1, h2ddat_hdr, rsvd0, m2sreq} = data;
      m2sreq_h.req68 = m2sreq;
      h2ddat_h.hdr68 = h2ddat_hdr;
    end
    else begin
      {rsvd, s2mndr[0].devload, s2mndr[1], s2mndr[0][27:0], s2mdrs_hdr} = data;
      s2mdrs_h.hdr68 = s2mdrs_hdr;
      foreach (s2mndr_h[ii])
        s2mndr_h[ii].ndr68 = s2mndr[ii]; 
    end
    check_tightly_packed();
    check_rsvd();
    set_empty_slot();
  endfunction

endclass

class g5_f68 extends slot_base;

  `uvm_object_utils(g5_f68)

  /* H2D/M2S */
  logic [7:0]    rsvd1 = '0;
  h2drsp68_t     h2drsp;     /**/ rand h2drsp_c h2drsp_h;
  logic          rsvd0 = '0;
  m2srwd68_hdr_t m2srwd_hdr; /**/ rand m2srwd_c m2srwd_h;

  /* D2H/S2M */
  logic [67:0] rsvd = '0;
  s2mndr68_t   s2mndr[1:0]; /**/ rand s2mndr_c s2mndr_h[1:0];

  function new(string name = "g5_f68");
    super.new(name);
    _fmt = _G5;
  endfunction 

  virtual function void create_objects(dir_t dir, logic [1:0] set_valid = 'x);
    this.dir = dir;
    if (dir == H2C) begin
      m2srwd_h           = m2srwd_c::type_id::create("m2srwd_h");
      m2srwd_h.flitmode  = F68;
      m2srwd_h.hdr68.val = set_valid[0];
      h2drsp_h           = h2drsp_c::type_id::create("h2drsp_h");
      h2drsp_h.flitmode  = F68;
      h2drsp_h.rsp68.val = set_valid[1];
    end
    else begin
      foreach (s2mndr_h[ii]) begin
        s2mndr_h[ii]           = s2mndr_c::type_id::create($sformatf("s2mndr_h[%0d]",ii));
        s2mndr_h[ii].flitmode  = F68;
        s2mndr_h[ii].ndr68.val = set_valid[ii];
      end
    end
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void set_empty_slot();
    empty_slot = (dir == H2C) ? ~|{h2drsp.val, m2srwd_hdr.val} : !(s2mndr.or() with (item.val));
    if (dir == H2C) begin
      dat_consumed[1] = m2srwd_hdr.val;
      rsp_consumed[0] = h2drsp.val;
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
    bit tightly_packed = (dir == H2C) ? 1'b1 : ({s2mndr[0].val, s2mndr[1].val} != 2'b01);
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual protected function void check_rsvd();
    if (dir == H2C) begin
      if (|{rsvd1, h2drsp.rsvd, rsvd0, m2srwd_hdr.rsvd})
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
      if (h2drsp_h != null)
        h2drsp = h2drsp_h.rsp68;
      if (m2srwd_h != null)
        m2srwd_hdr = m2srwd_h.hdr68;
      data = {rsvd1, h2drsp, rsvd0, m2srwd_hdr};
    end
    else begin
      foreach (s2mndr_h[ii])
        if (s2mndr_h[ii] != null)
          s2mndr[ii] = s2mndr_h[ii].ndr68;
      data = {rsvd, s2mndr[0].devload, s2mndr[1], s2mndr[0][27:0]};
    end
    check_tightly_packed();
    check_rsvd();
    set_empty_slot();
    set_be_sz();
    return data;
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    create_objects(dir);
    if (dat !== 'x) data = dat;
    if (dir == H2C) begin
      {rsvd1, h2drsp, rsvd0, m2srwd_hdr} = data;
      m2srwd_h.hdr68 = m2srwd_hdr;
      h2drsp_h.rsp68 = h2drsp;
    end
    else begin
      {rsvd, s2mndr[0].devload, s2mndr[1], s2mndr[0][27:0]} = data;
      foreach (s2mndr_h[ii])
        s2mndr_h[ii].ndr68 = s2mndr[ii];
    end
    check_tightly_packed();
    check_rsvd();
    set_empty_slot();
  endfunction

endclass

class g6_f68 extends slot_base;

  `uvm_object_utils(g6_f68)

  /* H2D/M2S */ 
  // reserved

  /* D2H/S2M */
  logic [7:0]    rsvd = '0;
  s2mdrs68_hdr_t s2mdrs_hdr[2:0]; /**/ rand s2mdrs_c s2mdrs_h[2:0];

  function new(string name = "g6_f68");
    super.new(name);
    _fmt = _G6;
  endfunction 

  virtual function void create_objects(dir_t dir, logic [2:0] set_valid = 'x);
    this.dir = dir;
    foreach (s2mdrs_h[ii]) begin
      s2mdrs_h[ii]           = s2mdrs_c::type_id::create($sformatf("s2mdrs_h[%0d]",ii));
      s2mdrs_h[ii].flitmode  = F68;
      s2mdrs_h[ii].hdr68.val = set_valid[ii];
      s2mdrs_h[ii].txfer_64B = 1;
    end
  endfunction

  // Protected; called by pack/unpack
  virtual protected function void set_empty_slot();
    empty_slot = !(s2mdrs_hdr.or() with (item.val));
    dat_consumed[1] = s2mdrs_hdr.sum() with (int'(item.val));
  endfunction

  virtual protected function void set_be_sz();
    {hdr_be, hdr_sz} = 2'b01;
  endfunction

  virtual protected function void check_tightly_packed();
    bit tightly_packed;
    casez({s2mdrs_hdr[0].val, s2mdrs_hdr[1].val, s2mdrs_hdr[2].val})
      3'b01?  : tightly_packed = 1'b0;
      3'b?01  : tightly_packed = 1'b0;
      default : tightly_packed = 1'b1;
    endcase
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual protected function void check_rsvd();
    if (|{rsvd, s2mdrs_hdr.or() with (item.rsvd)})
      `uvm_error(get_type_name, "Reserved bits of slot are not 0; see CXL spec")
    if (s2mdrs_hdr.sum() with (int'(item.val)) <= 1)
      `uvm_error(get_type_name, "MDH must have >1 valid header; see CXL spec")
  endfunction

  // Parent classes will call these
  virtual function logic [127:0] pack_slot();
    if (dir == H2C)
      `uvm_fatal(get_type_name, "G6 is reserved in the H2D direction")
    foreach (s2mdrs_h[ii])
      if (s2mdrs_h[ii] != null)
        s2mdrs_hdr[ii] = s2mdrs_h[ii].hdr68;
    data = {rsvd, s2mdrs_hdr[2], s2mdrs_hdr[1], s2mdrs_hdr[0]};
    check_tightly_packed();
    check_rsvd();
    set_empty_slot();
    set_be_sz();
    return data;
  endfunction

  virtual function void unpack_slot(dir_t dir, logic [127:0] dat = 'x);
    create_objects(dir);
    if (dat !== 'x) data = dat;
    if (dir == H2C)
      `uvm_fatal(get_type_name, "G6 is reserved in the H2D direction")
    {rsvd, s2mdrs_hdr[2], s2mdrs_hdr[1], s2mdrs_hdr[0]} = data;
    foreach (s2mdrs_h[ii])
      s2mdrs_h[ii].hdr68 = s2mdrs_hdr[ii];
    check_tightly_packed();
    check_rsvd();
    set_empty_slot();
  endfunction

endclass
