class m0_hbr extends slot_base_f256;

  `uvm_object_utils(m0_hbr)

  const bit [3:0] fmt = 4'd0;

  logic [11:0] rsvd = '0;
  h2drsp256_t  h2drsp; /**/ rand h2drsp_c h2drsp_h; //G
  h2dreq256_t  h2dreq; /**/ rand h2dreq_c h2dreq_h; //HS|H

  function new(string name = "m0_hbr");
    super.new(name);
    _fmt      = _HBR_M0;
    data[3:0] = 'd0;
  endfunction

  virtual function void create_objects(flit_mode_t fm, bit [3:0] sn, logic [1:0] set_valid = 'x);
    {flitmode, slot_num} = {fm, sn};
    h2dreq_h             = h2dreq_c::type_id::create("h2dreq_h");
    h2dreq_h.flitmode    = F256;
    h2dreq_h.req256.val  = set_valid[0];
    if (is_gslot && !is_s7_lopt) begin
      h2drsp_h            = h2drsp_c::type_id::create("h2drsp_h");
      h2drsp_h.flitmode   = F256;
      h2drsp_h.rsp256.val = set_valid[1];
    end
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void set_slot_consumed();
    empty_slot = is_gslot ? ~|{h2drsp.val, h2dreq.val} : !h2dreq.val;
    req_consumed[0] = h2dreq.val;
    rsp_consumed[0] = is_gslot && h2drsp.val;
  endfunction

  //get_slot_consumed_upr not relevant

  virtual protected function void check_rsvd();
    bit          err;
    string       str; 
    // Check txns
    if (h2dreq.rsvd) 
      `uvm_error(get_type_name, "Reserved bits of h2dreq are not 0")
    if (is_gslot && !is_s7_lopt && h2drsp.rsvd)
      `uvm_error(get_type_name, "Reserved bits of h2drsp are not 0")
    // Check upper reserved bits
    case (1'b1)
      is_hsslot  : begin 
                     str = "HS"; 
                     err = |data.hsslot.s8_lwr[79:76]; 
                   end 
      is_hslot   : begin 
                     str = "H";  
                     err = |data.hslot.data[111-:36]; 
                   end
      is_s7_lopt : /*check upper only, not present here*/;
      is_gslot   : begin 
                     str = "G";  
                     err = |rsvd;
                   end
    endcase
    if (err)
      `uvm_error(get_type_name, {"Upper bits of ",str," slot are not 0"})
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr);
    logic [11:0] rsvd;
    h2drsp256_t  h2drsp;
    // If we're S7 (G-Slot), S8 has called us...
    if (is_s7_lopt) begin
      {rsvd, h2drsp} = {upr, 4'hx};
      // Check txn 
      if (h2drsp.rsvd)
        `uvm_error(get_type_name, "Reserved bits of h2drsp are not 0")
      // Check upper reserved bits
      if (rsvd)
        `uvm_error(get_type_name, "Upper bits of LOpt-S8 (Slot 7) are not 0")
    end
    // ....else we're S8 (HS-Slot), S15 has called us
    else if (upr[15:0])
      `uvm_error(get_type_name, "Upper bits of LOpt-S15 (Slot 8) are not 0")
  endfunction

  /* Set slot_num and flitmode before calling any methods */

  /* User called methods */
  // It is expected users will use these flows to pack or unpack a slot with (randomized) data
  // - Packing: <h>.create_objects(<flitmode>, <slotnum>, <val>); <h>.copy(<object>); <h>.randomize; <h>.pack_slot;
  // - Unpacking: <h>.unpack_slot(<flitmode>, <slotnum>, <data>);

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    if (h2dreq_h != null) h2dreq = h2dreq_h.req256;
    if (h2drsp_h != null) h2drsp = h2drsp_h.rsp256;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, 4'h0, h2dreq, fmt}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {'0, h2dreq, fmt, 16'h0}; //HDR set to all 0's
      is_s7_lopt : data.gslot  = {upr_6B, h2drsp[3:0], h2dreq, fmt}; //upper=CRC
      is_gslot   : data.gslot  = {'0, h2drsp, h2dreq, fmt};
    endcase
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    return data;
  endfunction
  
  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    // create handles
    create_objects(fm, sn);
    // unpack to internal variables
    case (1'b1)
      is_hsslot  :                h2dreq  = data.hsslot.s8_lwr;
      is_hslot   :                h2dreq  = data.hslot.data;
      is_s7_lopt :  {h2drsp[3:0], h2dreq} = data.s7_lopt.s7_lwr;
      is_gslot   : {rsvd, h2drsp, h2dreq} = data.gslot.data;
    endcase
    // copy internal variables to handles
    h2dreq_h.req256 = h2dreq;
    case (1'b1)
      is_s7_lopt : h2drsp_h.rsp256[3:0] = h2drsp[3:0];
      is_gslot   : h2drsp_h.rsp256 = h2drsp;
    endcase
    // perform checks and set status members
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
  endfunction

endclass

class m1_hbr extends slot_base_f256;

  `uvm_object_utils(m1_hbr)

  const bit [3:0] fmt = 4'd1;

  logic [3:0] rsvd = '0;
  h2drsp256_t h2drsp[2:0]; /**/ rand h2drsp_c h2drsp_h[2:0]; //HS|H (2), G (3)

  function new(string name = "m1_hbr");
    super.new(name);
    _fmt      = _HBR_M1;
    data[3:0] = 'd1;
  endfunction

  virtual function void create_objects(flit_mode_t fm, bit [3:0] sn, logic [2:0] set_valid = 'x);
    {flitmode, slot_num} = {fm, sn};
    foreach (h2drsp_h[ii]) begin
      if (ii==2 && (!is_gslot || is_s7_lopt)) continue;
      h2drsp_h[ii]            = h2drsp_c::type_id::create($sformatf("h2drsp_h[%0d]",ii));
      h2drsp_h[ii].flitmode   = F256;
      h2drsp_h[ii].rsp256.val = set_valid[ii];
    end
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void set_slot_consumed();
    empty_slot = (is_gslot && !is_s7_lopt) ? !(h2drsp.or with (item.val)) : ~|{h2drsp[1].val, h2drsp[0].val}; 
    rsp_consumed[0] = (is_gslot && !is_s7_lopt) ? h2drsp.sum with (int'(item.val)) : h2drsp[1].val + h2drsp[0].val;
  endfunction

  virtual protected function bit [4:0] get_slot_consumed_upr(logic [47:0] upr);
    return (is_s7_lopt && upr[4] ? 5'b0_11_01 : '0);
  endfunction

  // Upper is used when Slot 8 or Slot 15 (LOpt only) call their check_rsvd 
  // functions
  virtual protected function void check_rsvd();
    bit    err;
    string str;
    // Check txns
    if (h2drsp[0].rsvd) 
      `uvm_error(get_type_name, "Reserved bits of h2drsp[0] are not 0")
    if (is_split_slot) begin
      if (h2drsp[1].rsvd[0])
        `uvm_error(get_type_name, "Reserved bits of h2drsp[1] are not 0")
    end
    else if (h2drsp[1].rsvd) 
      `uvm_error(get_type_name, "Reserved bits of h2drsp[1] are not 0")
    if (is_gslot && !is_s7_lopt && h2drsp[2].rsvd)
      `uvm_error(get_type_name, "Reserved bits of h2drsp[2] are not 0")
    // Check upper reserved bits
    case (1'b1)
      is_hsslot  : /* check upper only, not present here*/;
      is_hslot   : begin 
                     str = "H";  
                     err = |data.hslot.data[111-:28]; 
                   end
      is_s7_lopt : /*check upper only, not present here*/;
      is_gslot   : begin 
                     str = "G";  
                     err = |rsvd;
                   end
    endcase
    if (err)
      `uvm_error(get_type_name, {"Upper bits of ",str," slot are not 0"})
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr);
    logic [3:0] rsvdh;
    h2drsp256_t h2drsp;
    logic [3:0] rsvdl;
    // If we're S7 (G-Slot), S8 has called us...
    if (is_s7_lopt) begin
      {rsvdh, h2drsp, rsvdl} = upr;
      // Check txn 
      if (rsvdl)
        `uvm_error(get_type_name, "Reserved bits of h2drsp[1] are not 0")
      if (h2drsp.rsvd)
        `uvm_error(get_type_name, "Reserved bits of h2drsp[2] are not 0")
      // Check upper reserved bits
      if (rsvdh)
        `uvm_error(get_type_name, "Upper bits of LOpt-S8 (Slot 7) are not 0")
    end
    // ....else we're S8 (HS-Slot), S15 has called us
    else if (upr[15:0])
      `uvm_error(get_type_name, "Upper bits of LOpt-S15 (Slot 8) are not 0")
   endfunction

  virtual protected function void check_tightly_packed();
    bit       tightly_packed = 1'b1;
    bit [0:2] valid = {h2drsp[0].val, h2drsp[1].val, is_gslot && !is_s7_lopt && h2drsp[2].val};
    casez(valid)
      3'b01?  : tightly_packed = 1'b0;
      3'b?01  : tightly_packed = 1'b0;
    endcase
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual protected function void check_tightly_packed_upr(logic [47:0] upr);
    bit       tightly_packed = 1'b1;
    bit [0:2] valid = {h2drsp[0].val, h2drsp[1].val, is_s7_lopt && upr[4]};
    casez(valid)
      3'b01?  : tightly_packed = 1'b0;
      3'b?01  : tightly_packed = 1'b0;
    endcase
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  /* Set slot_num and flitmode before calling any methods */

  /* User called methods */
  // It is expected users will use these flows to pack or unpack a slot with (randomized) data
  // - Packing: <h>.create_objects(<flitmode>, <slotnum>, <val>); <h>.copy(<object>); <h>.randomize; <h>.pack_slot;
  // - Unpacking: <h>.unpack_slot(<flitmode>, <slotnum>, <data>);

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    if (h2drsp_h[0] != null) h2drsp[0] = h2drsp_h[0].rsp256;
    if (h2drsp_h[1] != null) h2drsp[1] = h2drsp_h[1].rsp256;
    if (h2drsp_h[2] != null) h2drsp[2] = h2drsp_h[2].rsp256;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, h2drsp[1][35:0], h2drsp[0], fmt}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {'0, h2drsp[1], h2drsp[0], fmt, 16'h0}; //HDR set to all 0's
      is_s7_lopt : data.gslot  = {upr_6B, h2drsp[1][35:0], h2drsp[0], fmt}; //upper=CRC
      is_gslot   : data.gslot  = {'0, h2drsp[2], h2drsp[1], h2drsp[0], fmt};
    endcase
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    return data;
  endfunction
  
  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    // create handles
    create_objects(fm, sn);
    // unpack to internal variables
    case (1'b1)
      is_hslot      :                  {h2drsp[1], h2drsp[0]} = data.hslot.data;
      is_split_slot :            {h2drsp[1][35:0], h2drsp[0]} = data.split.lower;
      is_gslot      : {rsvd, h2drsp[2], h2drsp[1], h2drsp[0]} = data.gslot.data;
    endcase
    // copy internal variables to handles
    h2drsp_h[0].rsp256 = h2drsp[0];
    if (is_split_slot)
      h2drsp_h[1].rsp256[35:0] = h2drsp[1][35:0];
    else
      h2drsp_h[1].rsp256 = h2drsp[1];
    if (is_gslot && !is_s7_lopt)
      h2drsp_h[2].rsp256 = h2drsp[2];
    // perform checks and set status members
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[2]] += ctupl[1:0];
        2 : dat_consumed[ctupl[2]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[2]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
  endfunction

endclass

class m2_hbr extends slot_base_f256;

  `uvm_object_utils(m2_hbr)

  const bit [3:0] fmt = 4'd2;

  d2hrsp256_t d2hrsp[1:0]; /**/ rand d2hrsp_c d2hrsp_h[1:0]; //H (1), G (2)
  d2hreq256_t d2hreq;      /**/ rand d2hreq_c d2hreq_h;      //HS

  function new(string name = "m2_hbr");
    super.new(name);
    _fmt      = _HBR_M2;
    data[3:0] = 'd2;
  endfunction

  virtual function void create_objects(flit_mode_t fm, bit [3:0] sn, logic [2:0] set_valid = 'x);
    {flitmode, slot_num} = {fm, sn};
    d2hreq_h             = d2hreq_c::type_id::create("d2hreq_h");
    d2hreq_h.flitmode    = F256;
    d2hreq_h.req256.val  = set_valid[0]; 
    if (!is_hsslot) begin
      foreach (d2hrsp_h[ii]) begin
        if ((ii==1 && !is_gslot) || is_s7_lopt) continue;
        d2hrsp_h[ii]            = d2hrsp_c::type_id::create($sformatf("d2hrsp_h[%0d]",ii));
        d2hrsp_h[ii].flitmode   = F256;
        d2hrsp_h[ii].rsp256.val = set_valid[ii+1];
      end
    end
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void set_slot_consumed();
    case (1'b1)
      is_hslot      : empty_slot = !d2hreq.val && !d2hrsp[0].val;
      is_split_slot : empty_slot = !d2hreq.val;
      is_gslot      : empty_slot = !d2hreq.val && !d2hrsp[0].val && !d2hrsp[1].val;
    endcase
    req_consumed[0] = d2hreq.val;
    if (is_hslot) 
     rsp_consumed[0] = d2hrsp[0].val;
    else if (is_gslot && !is_s7_lopt) 
     rsp_consumed[0] = d2hrsp[0].val + d2hrsp[1].val;
  endfunction

  virtual protected function bit [4:0] get_slot_consumed_upr(logic [47:0] upr);
    if (is_s7_lopt) begin
      get_slot_consumed_upr[4:2] = 3'b0_11;
      get_slot_consumed_upr[1:0] = upr[0]+upr[24];
    end
    else
      return '0;
  endfunction

  virtual protected function void check_rsvd();
    bit         err;
    string      str;
    // Check txns
    if (d2hreq.rsvd0 || d2hreq.rsvd1) 
      `uvm_error(get_type_name, "Reserved bits of d2hreq are not 0")
    if ((is_hslot || (is_gslot && !is_s7_lopt)) && d2hrsp[0].rsvd) 
      `uvm_error(get_type_name, "Reserved bits of d2hrsp[0] are not 0")
    if (is_gslot && !is_s7_lopt && d2hrsp[1].rsvd) 
      `uvm_error(get_type_name, "Reserved bits of d2hrsp[1] are not 0")
    // Check upper reserved bits
    if (is_hslot) begin
      str = "H";
      err = |data.hslot.data[111-:8];
    end
    if (err)
      `uvm_error(get_type_name, {"Upper bits of ",str," slot are not 0"})
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr); 
    d2hrsp256_t d2hrsp[1:0];
    // If we're S7 (G-Slot), S8 has called us...
    if (is_s7_lopt) begin
      {d2hrsp[1], d2hrsp[0]} = upr;
      // Check txn 
      if (d2hrsp[0].rsvd)
        `uvm_error(get_type_name, "Reserved bits of d2hrsp[0] are not 0")
      if (d2hrsp[1].rsvd)
        `uvm_error(get_type_name, "Reserved bits of d2hrsp[1] are not 0")
    end
    // ....else we're S8 (HS-Slot), S15 has called us
    else if (upr[15:0])
      `uvm_error(get_type_name, "Upper bits of LOpt-S15 (Slot 8) are not 0")
  endfunction

  virtual protected function void check_tightly_packed();
    if (is_gslot && !is_s7_lopt && !d2hrsp[0].val && d2hrsp[1].val)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual function void check_tightly_packed_upr(logic [47:0] upr);
    if (is_s7_lopt && !upr[0] && upr[24])
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  /* Set slot_num and flitmode before calling any methods */

  /* User called methods */
  // It is expected users will use these flows to pack or unpack a slot with (randomized) data
  // - Packing: <h>.create_objects(<flitmode>, <slotnum>, <val>); <h>.copy(<object>); <h>.randomize; <h>.pack_slot;
  // - Unpacking: <h>.unpack_slot(<flitmode>, <slotnum>, <data>);

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    if (d2hreq_h    != null) d2hreq    = d2hreq_h.req256;
    if (d2hrsp_h[0] != null) d2hrsp[0] = d2hrsp_h[0].rsp256;
    if (d2hrsp_h[1] != null) d2hrsp[1] = d2hrsp_h[1].rsp256;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, d2hreq, fmt}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {'0, d2hrsp[0], d2hreq, fmt, 16'h0}; //HDR set to all 0's
      is_s7_lopt : data.gslot  = {upr_6B, d2hreq, fmt}; //upper=CRC
      is_gslot   : data.gslot  = {d2hrsp[1], d2hrsp[0], d2hreq, fmt};
    endcase
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    return data;
  endfunction
  
  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    // create handles
    create_objects(fm, sn);
    // unpack to internal variables
    case (1'b1)
      is_hslot      :            {d2hrsp[0], d2hreq} = data.hslot.data;
      is_split_slot :                       {d2hreq} = data.split.lower;
      is_gslot      : {d2hrsp[1], d2hrsp[0], d2hreq} = data.gslot.data;
    endcase
    // copy internal variables to handles
    d2hreq_h.req256 = d2hreq;
    if (is_hslot || (is_gslot && !is_s7_lopt)) 
      d2hrsp_h[0].rsp256 = d2hrsp[0];
    if (is_gslot && !is_s7_lopt)
      d2hrsp_h[1].rsp256 = d2hrsp[1];
    // perform checks and set status members
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
  endfunction

endclass

class m3_hbr extends slot_base_f256;

  `uvm_object_utils(m3_hbr)

  const bit [3:0] fmt = 4'd3;

  logic [27:0] rsvd = '0;
  d2hrsp256_t  d2hrsp[3:0]; /**/ rand d2hrsp_c d2hrsp_h[3:0]; //HS (3), H|G (4)

  function new(string name = "m3_hbr");
    super.new(name);
    _fmt      = _HBR_M3;
    data[3:0] = 'd3;
  endfunction

  virtual function void create_objects(flit_mode_t fm, bit [3:0] sn, logic [3:0] set_valid = 'x);
    {flitmode, slot_num} = {fm, sn};
    foreach (d2hrsp_h[ii]) begin
      if (ii==3 && is_split_slot) continue;
      d2hrsp_h[ii]            = d2hrsp_c::type_id::create($sformatf("d2hrsp_h[%0d]",ii));
      d2hrsp_h[ii].flitmode   = F256;
      d2hrsp_h[ii].rsp256.val = set_valid[ii];
    end
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void set_slot_consumed();
    if (is_hsslot) begin 
      empty_slot = ~|{d2hrsp[2].val, d2hrsp[1].val, d2hrsp[0].val};
      rsp_consumed[0] = d2hrsp[2].val + d2hrsp[1].val + d2hrsp[0].val;
    end
    else begin
      empty_slot = !(d2hrsp.or with (item.val));
      rsp_consumed[0] = d2hrsp.sum with (int'(item.val));
    end
  endfunction

  virtual protected function void check_rsvd();
    bit    err;
    string str;
    // Check txns
    foreach (d2hrsp[ii]) begin
      if (ii==3 && is_split_slot) continue;
      if (d2hrsp[ii].rsvd) `uvm_error(get_type_name, $sformatf("Reserved bits of d2hrsp[%0d] are not 0",ii))
    end
    // Check upper reserved bits
    case (1'b1)
      is_hsslot  : begin
                     str = "HS";
                     err = |data.hsslot.s8_lwr[79:76];
                   end
      is_hslot   : begin
                     str = "H";
                     err = |data.hslot.data[111-:12];
                   end
      is_s7_lopt : /*check upper only, not present here*/;
      is_gslot   : begin
                     str = "G";
                     err = |rsvd;
                   end
    endcase
    if (err)
      `uvm_error(get_type_name, {"Upper bits of ",str," slot are not 0"})
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr); 
    logic [27:0] rsvd;
    d2hrsp256_t  d2hrsp;
    // If we're S7 (G-Slot), S8 has called us...
    if (is_s7_lopt) begin
      {rsvd, d2hrsp} = {upr, 4'hx};
      // Check txn 
      if (d2hrsp.rsvd)
        `uvm_error(get_type_name, "Reserved bits of d2hrsp are not 0")
      // Check upper reserved bits
      if (rsvd)
        `uvm_error(get_type_name, "Upper bits of LOpt-S8 (Slot 7) are not 0")
    end
    // ....else we're S8 (HS-Slot), S15 has called us
    else if (upr[15:0])
      `uvm_error(get_type_name, "Upper bits of LOpt-S15 (Slot 8) are not 0")
  endfunction

  virtual protected function void check_tightly_packed();
    bit       tightly_packed = 1;
    bit [0:3] valid = {d2hrsp[0].val, d2hrsp[1].val, d2hrsp[2].val, !is_hsslot && d2hrsp[3].val};
    casez(valid)
      4'b01?? : tightly_packed = 1'b0;
      4'b?01? : tightly_packed = 1'b0;
      4'b??01 : tightly_packed = 1'b0;
    endcase
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  /* Set slot_num and flitmode before calling any methods */

  /* User called methods */
  // It is expected users will use these flows to pack or unpack a slot with (randomized) data
  // - Packing: <h>.create_objects(<flitmode>, <slotnum>, <val>); <h>.copy(<object>); <h>.randomize; <h>.pack_slot;
  // - Unpacking: <h>.unpack_slot(<flitmode>, <slotnum>, <data>);

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    if (d2hrsp_h[0] != null) d2hrsp[0] = d2hrsp_h[0].rsp256;
    if (d2hrsp_h[1] != null) d2hrsp[1] = d2hrsp_h[1].rsp256;
    if (d2hrsp_h[2] != null) d2hrsp[2] = d2hrsp_h[2].rsp256;
    if (d2hrsp_h[3] != null) d2hrsp[3] = d2hrsp_h[3].rsp256;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, 4'h0, d2hrsp[2], d2hrsp[1], d2hrsp[0], fmt}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {'0, d2hrsp[3], d2hrsp[2], d2hrsp[1], d2hrsp[0], fmt, 16'h0}; //HDR set to all 0's
      is_s7_lopt : data.gslot  = {upr_6B, d2hrsp[3][3:0], d2hrsp[2], d2hrsp[1], d2hrsp[0], fmt}; //upper=CRC
      is_gslot   : data.gslot  = {'0, d2hrsp[3], d2hrsp[2], d2hrsp[1], d2hrsp[0], fmt};
    endcase
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    return data;
  endfunction
  
  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    // create handles
    create_objects(fm, sn);
    // unpack to internal variables
    case (1'b1)
      is_hsslot  :                        {d2hrsp[2], d2hrsp[1], d2hrsp[0]} = data.hsslot.s8_lwr;
      is_hslot   : {rsvd[11:0], d2hrsp[3], d2hrsp[2], d2hrsp[1], d2hrsp[0]} = data.hslot.data;
      is_s7_lopt :        {d2hrsp[3][3:0], d2hrsp[2], d2hrsp[1], d2hrsp[0]} = data.s7_lopt.s7_lwr;
      is_gslot   :       {rsvd, d2hrsp[3], d2hrsp[2], d2hrsp[1], d2hrsp[0]} = data.gslot.data;
    endcase
    // copy internal variables to handles
    d2hrsp_h[0].rsp256 = d2hrsp[0];
    d2hrsp_h[1].rsp256 = d2hrsp[1];
    d2hrsp_h[2].rsp256 = d2hrsp[2];
    case (1'b1)
      is_s7_lopt : d2hrsp_h[3].rsp256[3:0] = d2hrsp[3][3:0];
      is_gslot   : d2hrsp_h[3].rsp256 = d2hrsp[3];
    endcase
    // perform checks and set status members
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
  endfunction

endclass

class m4_hbr extends slot_base_f256;

  `uvm_object_utils(m4_hbr)

  const bit [3:0] fmt = 4'd4;

  logic [23:0] rsvd = '0;
  m2sreq256_t  m2sreq; /**/ rand m2sreq_c m2sreq_h; //HS (8 bit zero ext), H|G

  function new(string name = "m4_hbr");
    super.new(name);
    _fmt      = _HBR_M4;
    data[3:0] = 'd4;
  endfunction

  virtual function void create_objects(flit_mode_t fm, bit [3:0] sn, logic set_valid = 'x);
    {flitmode, slot_num} = {fm, sn};
    m2sreq_h             = m2sreq_c::type_id::create("m2sreq_h");
    m2sreq_h.flitmode    = F256;
    m2sreq_h.req256.val  = set_valid;
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void set_slot_consumed();
    empty_slot = !m2sreq.val;
    req_consumed[1] = m2sreq.val;
  endfunction

  virtual protected function void check_rsvd();
    bit    err;
    string str;
    // Check txns
    if ((is_hslot || (is_gslot && !is_s7_lopt)) && m2sreq.rsvd)
      `uvm_error(get_type_name, "Reserved bits of m2sreq are not 0")
    // Check upper reserved bits
    case (1'b1)
      is_hsslot  : /*check upper only, not present here*/;
      is_hslot  : begin str = "H"; err = |rsvd[7:0]; end
      is_s7_lopt : /*check upper only, not present here*/;
      is_gslot  : begin str = "G"; err = |rsvd;      end
    endcase
    if (err)
      `uvm_error(get_type_name, {"Upper bits of ",str," slot are not 0"})
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr); 
    // If we're S7 (G-Slot), S8 has called us...
    if (is_s7_lopt) begin
      // Check txn 
      if (upr[21:15])
        `uvm_error(get_type_name, "Reserved bits of m2sreq are not 0")
      // Check upr reserved bits
      if (upr[47-:24])
        `uvm_error(get_type_name, "Upper bits of LOpt-S8 (Slot 7) are not 0")
    end
    // ....else we're S8 (HS-Slot), S15 has called us
    else if (upr[15])
      `uvm_error(get_type_name, "Upper bits of LOpt-S15 (Slot 8) are not 0")
  endfunction

  /* Set slot_num and flitmode before calling any methods */

  /* User called methods */
  // It is expected users will use these flows to pack or unpack a slot with (randomized) data
  // - Packing: <h>.create_objects(<flitmode>, <slotnum>, <val>); <h>.copy(<object>); <h>.randomize; <h>.pack_slot;
  // - Unpacking: <h>.unpack_slot(<flitmode>, <slotnum>, <data>);

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    if (m2sreq_h != null) m2sreq = m2sreq_h.req256;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, m2sreq[75:0], fmt}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {'0, m2sreq, fmt, 16'h0}; //HDR set to all 0's
      is_s7_lopt : data.gslot  = {upr_6B, m2sreq[75:0], fmt}; //upper=CRC
      is_gslot   : data.gslot  = {'0, m2sreq, fmt};
    endcase
    check_rsvd();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    return data;
  endfunction
  
  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    // create handles
    create_objects(fm, sn);
    // unpack to internal variables
    case (1'b1)
      is_hslot      : {rsvd[7:0], m2sreq} = data.hslot.data;
      is_split_slot :      {m2sreq[75:0]} = data.split.lower;
      is_gslot      :      {rsvd, m2sreq} = data.gslot.data;
    endcase
    // copy internal variables to handles
    if (is_split_slot)
      m2sreq_h.req256[75:0] = m2sreq[75:0];
    else
      m2sreq_h.req256 = m2sreq;
    // perform checks and set status members
    check_rsvd();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
  endfunction

endclass

class m5_hbr extends slot_base_f256;

  `uvm_object_utils(m5_hbr)

  const bit [3:0] fmt = 4'd5;

  logic [3:0]   rsvd = '0;
  m2sbirsp256_t m2sbirsp[2:0]; /**/ rand m2sbirsp_c m2sbirsp_h[2:0]; //HS|H (2), G (3)

  function new(string name = "m5_hbr");
    super.new(name);
    _fmt      = _HBR_M5;
    data[3:0] = 'd5;
  endfunction

  virtual function void create_objects(flit_mode_t fm, bit [3:0] sn, logic [2:0] set_valid = 'x);
    {flitmode, slot_num} = {fm, sn};
    foreach (m2sbirsp_h[ii]) begin
      if (ii==2 && (!is_gslot || is_s7_lopt)) continue;
      m2sbirsp_h[ii]              = m2sbirsp_c::type_id::create($sformatf("m2sbirsp_h[%0d]",ii));
      m2sbirsp_h[ii].flitmode     = F256;
      m2sbirsp_h[ii].birsp256.val = set_valid[ii];
    end
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void set_slot_consumed();
    empty_slot = is_gslot && !is_s7_lopt ? !(m2sbirsp.or with (item.val)) : 
                                           ~|{m2sbirsp[1].val, m2sbirsp[0].val};
    rsp_consumed[1] = is_gslot && !is_s7_lopt ? m2sbirsp.sum with (int'(item.val)) : 
                                                m2sbirsp[1].val+m2sbirsp[0].val;
  endfunction

  virtual function bit [4:0] get_slot_consumed_upr(logic [47:0] upr);
    get_slot_consumed_upr[4:2] = 3'b1_11;
    get_slot_consumed_upr[1:0] = is_s7_lopt && upr[4];
  endfunction

  virtual protected function void check_rsvd();
    bit    err;
    string str;
    // Check txns
    if (m2sbirsp[0].rsvd)
      `uvm_error(get_type_name, "Reserved bits of m2sbirsp[0] are not 0")
    if (is_split_slot) begin
      if (m2sbirsp[1].rsvd[4:0])
        `uvm_error(get_type_name, "Reserved bits of m2sbirsp[1] are not 0")
    end
    else if (m2sbirsp[1].rsvd)
      `uvm_error(get_type_name, "Reserved bits of m2sbirsp[1] are not 0")
    if (is_gslot && !is_s7_lopt && m2sbirsp[2].rsvd)
      `uvm_error(get_type_name, "Reserved bits of m2sbirsp[2] are not 0")
    // Check upper reserved bits
    case (1'b1)
      is_hsslot  : /*check upper only, not present here*/
      is_hslot   : begin
                     str = "H";
                     err = |data.hslot.data[111-:28];
                   end
      is_s7_lopt : /*check upper only, not present here*/;
      is_gslot   : begin
                     str = "G";
                     err = |rsvd;
                   end
    endcase
    if (err)
      `uvm_error(get_type_name, {"Upper bits of ",str," slot are not 0"})
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr); 
    logic [3:0]   rsvdh;
    m2sbirsp256_t m2sbirsp;
    logic [3:0]   rsvdl;
    // If we're S7 (G-Slot), S8 has called us...
    if (is_s7_lopt) begin
      {rsvdh, m2sbirsp, rsvdl} = upr;
      // Check txn 
      if (rsvdl)
        `uvm_error(get_type_name, "Reserved bits of m2sbirsp[1] are not 0")
      if (m2sbirsp.rsvd)
        `uvm_error(get_type_name, "Reserved bits of m2sbirsp[2] are not 0")
      // Check upper reserved bits
      if (rsvdh)
        `uvm_error(get_type_name, "Upper bits of LOpt-S8 (Slot 7) are not 0")
    end
    // ....else we're S8 (HS-Slot), S15 has called us
    else begin
      // Check txn
      if (upr[3:0])
        `uvm_error(get_type_name, "Reserved bits of m2sbirsp[1] are not 0")
      // Check upper reserved bits
      if (upr[15:4])
        `uvm_error(get_type_name, "Upper bits of LOpt-S15 (Slot 8) are not 0")
    end
  endfunction

  virtual protected function void check_tightly_packed();
    bit       tightly_packed = 1'b1;
    bit [0:2] valid = {m2sbirsp[0].val, m2sbirsp[1].val, is_gslot && !is_s7_lopt && m2sbirsp[2].val}; 
    casez(valid)
      3'b01?  : tightly_packed = 1'b0;
      3'b?01  : tightly_packed = 1'b0;
    endcase
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual function void check_tightly_packed_upr(logic [47:0] upr);
    bit       tightly_packed = 1'b1;
    bit [0:2] valid = {m2sbirsp[0].val, m2sbirsp[1].val, is_s7_lopt && upr[4]}; 
    casez(valid)
      3'b01?  : tightly_packed = 1'b0;
      3'b?01  : tightly_packed = 1'b0;
    endcase
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  /* Set slot_num and flitmode before calling any methods */

  /* User called methods */
  // It is expected users will use these flows to pack or unpack a slot with (randomized) data
  // - Packing: <h>.create_objects(<flitmode>, <slotnum>, <val>); <h>.copy(<object>); <h>.randomize; <h>.pack_slot;
  // - Unpacking: <h>.unpack_slot(<flitmode>, <slotnum>, <data>);

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    if (m2sbirsp_h[0] != null) m2sbirsp[0] = m2sbirsp_h[0].birsp256;
    if (m2sbirsp_h[1] != null) m2sbirsp[1] = m2sbirsp_h[1].birsp256;
    if (m2sbirsp_h[2] != null) m2sbirsp[2] = m2sbirsp_h[2].birsp256;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, m2sbirsp[1][35:0], m2sbirsp[0], fmt}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {'0, m2sbirsp[1], m2sbirsp[0], fmt, 16'h0}; //HDR set to all 0's
      is_s7_lopt : data.gslot  = {upr_6B, m2sbirsp[1][35:0], m2sbirsp[0], fmt}; //upper=CRC
      is_gslot   : data.gslot  = {'0, m2sbirsp[2], m2sbirsp[1], m2sbirsp[0], fmt};
    endcase
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    return data;
  endfunction
  
  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    // create handles
    create_objects(fm, sn);
    // unpack to internal variables
    case (1'b1)
      is_hslot      :                    {m2sbirsp[1], m2sbirsp[0]} = data.hslot.data;
      is_split_slot :              {m2sbirsp[1][35:0], m2sbirsp[0]} = data.split.lower;
      is_gslot      : {rsvd, m2sbirsp[2], m2sbirsp[1], m2sbirsp[0]} = data.gslot.data;
    endcase
    // copy internal variables to handles
    m2sbirsp_h[0].birsp256 = m2sbirsp[0];
    if (is_split_slot)
      m2sbirsp_h[1].birsp256[35:0] = m2sbirsp[1][35:0];
    else
      m2sbirsp_h[1].birsp256 = m2sbirsp[1];
    if (is_gslot && !is_s7_lopt) 
      m2sbirsp_h[2].birsp256 = m2sbirsp[2];
    // perform checks and set status members
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
  endfunction

endclass

class m6_hbr extends slot_base_f256;

  `uvm_object_utils(m6_hbr)

  const bit [3:0] fmt = 4'd6;

  s2mndr256_t   s2mndr;   /**/ rand s2mndr_c   s2mndr_h;   //G
  s2mbisnp256_t s2mbisnp; /**/ rand s2mbisnp_c s2mbisnp_h; //HS|H

  function new(string name = "m6_hbr");
    super.new(name);
    _fmt      = _HBR_M6;
    data[3:0] = 'd6;
  endfunction

  virtual function void create_objects(flit_mode_t fm, bit [3:0] sn, logic [1:0] set_valid = 'x);
    {flitmode, slot_num}    = {fm, sn};
    s2mbisnp_h              = s2mbisnp_c::type_id::create("s2mbisnp_h");
    s2mbisnp_h.flitmode     = F256;
    s2mbisnp_h.bisnp256.val = set_valid[0];
    if (is_gslot && !is_s7_lopt) begin
      s2mndr_h = s2mndr_c::type_id::create("s2mndr_h");
      s2mndr_h.flitmode   = F256;
      s2mndr_h.ndr256.val = set_valid[1];
    end
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void set_slot_consumed();
    empty_slot = is_gslot && !is_s7_lopt ? ~|{s2mndr.val, s2mbisnp.val} : !s2mbisnp.val;
    req_consumed[1] = s2mbisnp.val; 
    rsp_consumed[1] = (is_gslot && !is_s7_lopt && s2mndr.val);
  endfunction

  virtual function bit [4:0] get_slot_consumed_upr(logic [47:0] upr);
    get_slot_consumed_upr[4:2] = 3'b1_01;
    get_slot_consumed_upr[1:0] = is_s7_lopt && upr[8];
  endfunction

  virtual protected function void check_rsvd();
    bit    err;
    string str;
    // Check txns
    if (is_split_slot) begin
      if (s2mbisnp.rsvd[0])
      `uvm_error(get_type_name, "Reserved bits of s2mbisnp are not 0")
    end
    else if (s2mbisnp.rsvd)
      `uvm_error(get_type_name, "Reserved bits of s2mbisnp are not 0")
    if (is_gslot && !is_s7_lopt && s2mndr.rsvd)
      `uvm_error(get_type_name, "Reserved bits of s2mndr are not 0")
    // Check upper reserved bits
    case (1'b1)
      is_hsslot  : /* check upper only, not present here*/;
      is_hslot   : begin
                     str = "H";
                     err = |data.hslot.data[111-:24];
                   end
      is_s7_lopt : /*check upper only, not present here*/;
      is_gslot   : /*no upper reserved bits*/;
    endcase
    if (err)
      `uvm_error(get_type_name, {"Upper bits of ",str," slot are not 0"})
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr);
    logic [7:0] rsvd;
    s2mndr256_t s2mndr;
    // If we're S7 (G-Slot), S8 has called us...
    if (is_s7_lopt) begin
      {s2mndr, rsvd} = upr;
      // Check txn 
      if (rsvd)
        `uvm_error(get_type_name, "Reserved bits of s2mbisnp are not 0")
      if (s2mndr.rsvd)
        `uvm_error(get_type_name, "Reserved bits of s2mndr are not 0")
    end
    // ....else we're S8 (HS-Slot), S15 has called us
    else begin
      if (upr[7:0])
        `uvm_error(get_type_name, "Reserved bits of s2mbisnp are not 0")
      if (upr[15:8])
      `uvm_error(get_type_name, "Upper bits of LOpt-S15 (Slot 8) are not 0")
    end
  endfunction

  /* Set slot_num and flitmode before calling any methods */

  /* User called methods */
  // It is expected users will use these flows to pack or unpack a slot with (randomized) data
  // - Packing: <h>.create_objects(<flitmode>, <slotnum>, <val>); <h>.copy(<object>); <h>.randomize; <h>.pack_slot;
  // - Unpacking: <h>.unpack_slot(<flitmode>, <slotnum>, <data>);

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    if (s2mbisnp_h != null) s2mbisnp = s2mbisnp_h.bisnp256;
    if (s2mndr_h   != null) s2mndr   = s2mndr_h.ndr256;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, s2mbisnp[75:0], fmt}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {'0, s2mbisnp, fmt, 16'h0}; //HDR set to all 0's
      is_s7_lopt : data.gslot  = {upr_6B, s2mbisnp[75:0], fmt}; //upper=CRC
      is_gslot   : data.gslot  = {s2mndr, s2mbisnp, fmt};
    endcase
    check_rsvd();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    return data;
  endfunction
  
  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    // create handles
    create_objects(fm, sn);
    // unpack to internal variables
    case (1'b1)
      is_hslot      :         {s2mbisnp} = data.hslot.data;
      is_split_slot :   {s2mbisnp[75:0]} = data.split.lower;
      is_gslot      : {s2mndr, s2mbisnp} = data.gslot.data;
    endcase
    // copy internal variables to handles
    if (is_split_slot)
      s2mbisnp_h.bisnp256[75:0] = s2mbisnp[75:0];
    else
      s2mbisnp_h.bisnp256 = s2mbisnp;
    if (is_gslot && !is_s7_lopt) 
      s2mndr_h.ndr256 = s2mndr;
    // perform checks and set status members
    check_rsvd();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
  endfunction

endclass

class m7_hbr extends slot_base_f256;

  `uvm_object_utils(m7_hbr)

  const bit [3:0] fmt = 4'd7;

  logic [3:0] rsvd = '0;
  s2mndr256_t s2mndr[2:0]; /**/ rand s2mndr_c s2mndr_h[2:0]; //HS|H (2), G (3)

  function new(string name = "m7_hbr");
    super.new(name);
    _fmt      = _HBR_M7;
    data[3:0] = 'd7;
  endfunction

  virtual function void create_objects(flit_mode_t fm, bit [3:0] sn, logic [2:0] set_valid = 'x);
    {flitmode, slot_num} = {fm, sn};
    foreach (s2mndr_h[ii]) begin
      if (ii==2 && (!is_gslot || is_s7_lopt)) continue;
      s2mndr_h[ii]            = s2mndr_c::type_id::create($sformatf("s2mndr_h[%0d]",ii));
      s2mndr_h[ii].flitmode   = F256;
      s2mndr_h[ii].ndr256.val = set_valid[ii];
    end
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void set_slot_consumed();
    empty_slot = is_gslot && !is_s7_lopt ? !(s2mndr.or with (item.val)) : 
                                          ~|{s2mndr[1].val, s2mndr[0].val};
    rsp_consumed[1] = is_gslot && !is_s7_lopt ? s2mndr.sum with (int'(item.val)) : 
                                                s2mndr[1].val+s2mndr[0].val;
  endfunction

  virtual function bit [4:0] get_slot_consumed_upr(logic [47:0] upr);
    get_slot_consumed_upr[4:2] = 3'b1_11;
    get_slot_consumed_upr[1:0] = is_s7_lopt && upr[4];
  endfunction

  virtual protected function void check_rsvd();
    bit    err;
    string str;
    // Check txns
    if (s2mndr[0].rsvd)
      `uvm_error(get_type_name, "Reserved bits of s2mndr[0] are not 0")
    if (is_split_slot) begin
      if (s2mndr[1].rsvd[5:0])
        `uvm_error(get_type_name, "Reserved bits of s2mndr[1] are not 0")
    end
    else if (s2mndr[1].rsvd)
      `uvm_error(get_type_name, "Reserved bits of s2mndr[1] are not 0")
    if (is_gslot && !is_s7_lopt && s2mndr[2].rsvd)
      `uvm_error(get_type_name, "Reserved bits of s2mndr[2] are not 0")
    // Check upper reserved bits
    case (1'b1)
      is_hsslot  : /*check upper only, not present here*/;
      is_hslot   : begin
                     str = "H";
                     err = |data.hslot.data[111-:28];
                   end
      is_s7_lopt : /*check upper only, not present here*/;
      is_gslot   : begin
                     str = "G";
                     err = |rsvd;
                   end
    endcase
    if (err)
      `uvm_error(get_type_name, {"Upper bits of ",str," slot are not 0"})
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr);
    logic [3:0] rsvdh;
    s2mndr256_t s2mndr;
    logic [3:0] rsvdl;
    // If we're S7 (G-Slot), S8 has called us...
    if (is_s7_lopt) begin
      {rsvdh, s2mndr, rsvdl} = upr;
      // Check txn 
      if (rsvdl)
        `uvm_error(get_type_name, "Reserved bits of s2mndr[1] are not 0")
      if (s2mndr.rsvd)
        `uvm_error(get_type_name, "Reserved bits of s2mndr[2] are not 0")
      // Check upper reserved bits
      if (rsvdh)
        `uvm_error(get_type_name, "Upper bits of LOpt-S8 (Slot 7) are not 0")
    end
    // ....else we're S8 (HS-Slot), S15 has called us
    else begin
      if (upr[3:0])
        `uvm_error(get_type_name, "Reserved bits of s2mndr[1] are not 0")
      if (upr[15:4])
        `uvm_error(get_type_name, "Upper bits of LOpt-S15 (Slot 8) are not 0")
    end
  endfunction

  virtual protected function void check_tightly_packed();
    bit       tightly_packed = 1'b1;
    bit [0:2] valid = {s2mndr[0].val, s2mndr[1].val, is_gslot && is_s7_lopt && s2mndr[2].val};
    casez(valid)
      3'b01?  : tightly_packed = 1'b0;
      3'b?01  : tightly_packed = 1'b0;
    endcase
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual function void check_tightly_packed_upr(logic [47:0] upr);
    bit       tightly_packed = 1'b1;
    bit [0:2] valid = {s2mndr[0].val, s2mndr[1].val, is_s7_lopt && upr[4]};
    casez(valid)
      3'b01?  : tightly_packed = 1'b0;
      3'b?01  : tightly_packed = 1'b0;
    endcase
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  /* Set slot_num and flitmode before calling any methods */

  /* User called methods */
  // It is expected users will use these flows to pack or unpack a slot with (randomized) data
  // - Packing: <h>.create_objects(<flitmode>, <slotnum>, <val>); <h>.copy(<object>); <h>.randomize; <h>.pack_slot;
  // - Unpacking: <h>.unpack_slot(<flitmode>, <slotnum>, <data>);

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    if (s2mndr_h[0] != null) s2mndr[0] = s2mndr_h[0].ndr256;
    if (s2mndr_h[1] != null) s2mndr[1] = s2mndr_h[1].ndr256;
    if (s2mndr_h[2] != null) s2mndr[2] = s2mndr_h[2].ndr256;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, s2mndr[1][35:0], s2mndr[0], fmt}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {'0, s2mndr[1], s2mndr[0], fmt, 16'h0}; //HDR set to all 0's
      is_s7_lopt : data.gslot  = {upr_6B, s2mndr[1][35:0], s2mndr[0], fmt}; //upper=CRC
      is_gslot   : data.gslot  = {'0, s2mndr[2], s2mndr[1], s2mndr[0], fmt};
    endcase
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    return data;
  endfunction
  
  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    // create handles
    create_objects(fm, sn);
    // unpack to internal variables
    case (1'b1)
      is_hslot      :                  {s2mndr[1], s2mndr[0]} = data.hslot.data;
      is_split_slot :            {s2mndr[1][35:0], s2mndr[0]} = data.split.lower;
      is_gslot      : {rsvd, s2mndr[2], s2mndr[1], s2mndr[0]} = data.gslot.data;
    endcase
    // copy internal variables to handles
    s2mndr_h[0].ndr256 = s2mndr[0];
    if (is_split_slot)
      s2mndr_h[1].ndr256[35:0] = s2mndr[1][35:0];
    else
      s2mndr_h[1].ndr256 = s2mndr[1];
    if (is_gslot && !is_s7_lopt) 
      s2mndr_h[2].ndr256 = s2mndr[2];
    // perform checks and set status members
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
  endfunction

endclass

// Special Case: For Gslot, this is Rsvd, but for H/HS-Slot this is LLCTRL;
class m8_hbr extends slot_base_f256;

  `uvm_object_utils(m8_hbr)

  const bit [3:0] fmt = 4'd8;

  function new(string name = "m8_hbr");
    super.new(name);
    _fmt          = _HBR_M8;
    data.llcm.fmt = 'd8;
    data.llcm.rsvd = '0;
  endfunction

  virtual function void create_objects(flit_mode_t fm, bit [3:0] sn);
    {flitmode, slot_num} = {fm, sn};
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void check_rsvd();
    bit    err;
    string msg, bits;
    // This slot type cannot be in G-slot 
    check_position();
    // Check always reserved fields
    if (data.llcm.rsvd) 
      `uvm_error(get_type_name, "Reserved bits [15:12] of LLCTRL slot are not 0")
    // Check reserved fields of each type (note: HS-Slot only has 80 bits of payload)
    case ({data.llcm.llctrl, data.llcm.subtype}) 
      {IDE_F256,  4'h0} : begin 
                            msg  = "IDE.Idle";
                            bits = "95:0";
                            err  = |data.llcm.payload;
                          end
      {IDE_F256,  4'h1} : begin 
                            msg  = "IDE.Start"; 
                            bits = "95:0";
                            err  = |data.llcm.payload;
                          end
      {IDE_F256,  4'h4} : begin 
                            msg  = "IDE.Stop";
                            bits = "95:0";
                            err  = |data.llcm.payload;
                          end
      {IBE_F256,  4'h0} : begin
                            msg  = "InBandErr.Viral";  
                            bits = "95:0";
                            err  = |data.llcm.payload;
                          end
      {IBE_F256,  4'h1} : begin 
                            msg  = "InBandErr.Poison"; 
                            bits = is_hslot ? "95:4" : "63:4";  
                            err  = is_hslot ? |data.llcm.payload[95:4] : |data.llcm.payload[63:4];  
                          end
      {INIT_F256, 4'h8} : begin 
                            msg  = "Init.Param";    
                            bits = "95:0";
                            err  = |data.llcm.payload;
                          end
      default : `uvm_error(get_type_name, $sformatf("LLCTRL='h%0h and Subtype='h%0h are not valid", 
                                          data.llcm.llctrl, 
                                          data.llcm.subtype))
    endcase
    if (err)
      `uvm_error(get_type_name, $sformatf("Payload reserved bits [%0s] of %0s are not 0", bits, msg))
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr);
    bit    err;
    string msg, bits;
    // We're S8 (HS-Slot), S15 has called us
    // upper=Payload[79:64]
    bits = "79:64";
    case ({data.llcm.llctrl, data.llcm.subtype}) 
      {IDE_F256,  4'h0} : begin msg = "IDE.Idle";         err = |upr[15:0]; end
      {IDE_F256,  4'h1} : begin msg = "IDE.Start";        err = |upr[15:0]; end
      {IDE_F256,  4'h4} : begin msg = "IDE.Stop";         err = |upr[15:0]; end
      {IBE_F256,  4'h0} : begin msg = "InBandErr.Viral";  err = |upr[15:0]; end
      {IBE_F256,  4'h1} : begin msg = "InBandErr.Poison"; err = |upr[15:0]; end
      {INIT_F256, 4'h8} : begin msg = "Init.Param";       err = |upr[15:0]; end
    endcase
    if (err)
      `uvm_error(get_type_name, $sformatf("Payload reserved bits [%0s] of %0s are not 0", bits, msg))
  endfunction

  virtual protected function void check_position();
    if (!is_gslot) begin
      case (data.llcm.llctrl)
        IDE_F256  : if (!is_hslot) `uvm_error(get_type_name, "IDE LLCTRL message only supported in H-Slot")
        INIT_F256 : if (!is_hslot) `uvm_error(get_type_name, "INIT LLCTRL message only supported in H-Slot")
      endcase
    end
    else
      `uvm_fatal(get_type_name, $sformatf("Cannot send a LLCM in a G-Slot (Slot %0d)", slot_num))
  endfunction

  virtual function void set_details(llctrl_f256_t llctrl, bit [3:0] subtype, bit [95:0] payload); 
    data.llcm.llctrl  = llctrl;
    data.llcm.subtype = subtype;
    data.llcm.payload = payload;
  endfunction

  /* Set slot_num and flitmode before calling any methods */

  /* User called methods */
  // It is expected users will use these flows to pack or unpack a slot with (randomized) data
  // - Packing: <h>.create_objects(<flitmode>, <slotnum>); <h>.set_details(<a>,<b>,<c>); <h>.pack_slot;
  // - Unpacking: <h>.unpack_slot(<flitmode>, <slotnum>, <data>);

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, data.llcm[79:0]}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {data.llcm, 16'h0}; //HDR set to all 0's
    endcase
    check_rsvd();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    return data;
  endfunction

  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    {flitmode, slot_num} = {fm, sn};
    // perform checks and set status members
    check_rsvd();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
  endfunction

endclass

class m9_hbr extends slot_base_f256;

  `uvm_object_utils(m9_hbr)

  const bit [3:0] fmt = 4'd9;

  function new(string name = "m9_hbr");
    super.new(name);
    _fmt       = _HBR_M9;
    data[3:0]  = 'd9;
    empty_slot = 1;
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void check_rsvd();
    case (1'b1)
      is_hslot : 
        if (data.hslot.data)
          `uvm_error(get_type_name, "Reserved bits are not all 0")
      is_split_slot : 
        if (data.split.lower)
          `uvm_error(get_type_name, "Reserved bits are not all 0")
      is_gslot : 
        if (data.gslot.data)
          `uvm_error(get_type_name, "Reserved bits are not all 0")
    endcase
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr);
    // If we're S7 (G-Slot), S8 has called us...
    if (is_s7_lopt) begin
      if (|upr)  
        `uvm_error(get_type_name, "Upper bits of LOpt-S8 (Slot 7) are not 0")
    end 
    // ....else we're S8 (HS-Slot), S15 has called us
    else if (upr[15:0])
      `uvm_error(get_type_name, "Upper bits of LOpt-S15 (Slot 8) are not 0")
  endfunction

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, 76'h0, fmt}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {'0, fmt, 16'h0}; //HDR set to all 0's
      is_s7_lopt : data.gslot  = {upr_6B, 76'h0, fmt}; //upper=CRC
      is_gslot   : data.gslot  = {'0, fmt};
    endcase
    check_rsvd();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    return data;
  endfunction

  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    {flitmode, slot_num} = {fm, sn};
    // perform checks and set status members
    check_rsvd();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
  endfunction

endclass

class m10_hbr extends slot_base_f256;

  `uvm_object_utils(m10_hbr)

  const bit [3:0] fmt = 4'd10;

  function new(string name = "m10_hbr");
    super.new(name);
    _fmt       = _HBR_M10;
    data[3:0]  = 'd10;
    empty_slot = 1;
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void check_rsvd();
    case (1'b1)
      is_hslot : 
        if (data.hslot.data)
          `uvm_error(get_type_name, "Reserved bits are not all 0")
      is_split_slot : 
        if (data.split.lower)
          `uvm_error(get_type_name, "Reserved bits are not all 0")
      is_gslot : 
        if (data.gslot.data)
          `uvm_error(get_type_name, "Reserved bits are not all 0")
    endcase
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr);
    // If we're S7 (G-Slot), S8 has called us...
    if (is_s7_lopt) begin
      if (|upr)  
        `uvm_error(get_type_name, "Upper bits of LOpt-S8 (Slot 7) are not 0")
    end 
    // ....else we're S8 (HS-Slot), S15 has called us
    else if (upr[15:0])
      `uvm_error(get_type_name, "Upper bits of LOpt-S15 (Slot 8) are not 0")
  endfunction

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, 76'h0, fmt}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {'0, fmt, 16'h0}; //HDR set to all 0's
      is_s7_lopt : data.gslot  = {upr_6B, 76'h0, fmt}; //upper=CRC
      is_gslot   : data.gslot  = {'0, fmt};
    endcase
    check_rsvd();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    return data;
  endfunction

  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    {flitmode, slot_num} = {fm, sn};
    // perform checks and set status members
    check_rsvd();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
  endfunction

endclass

class m11_hbr extends slot_base_f256;

  `uvm_object_utils(m11_hbr)

  const bit [3:0] fmt = 4'd11;

  function new(string name = "m11_hbr");
    super.new(name);
    _fmt       = _HBR_M11;
    data[3:0]  = 'd11;
    empty_slot = 1;
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void check_rsvd();
    case (1'b1)
      is_hslot : 
        if (data.hslot.data)
          `uvm_error(get_type_name, "Reserved bits are not all 0")
      is_split_slot : 
        if (data.split.lower)
          `uvm_error(get_type_name, "Reserved bits are not all 0")
      is_gslot : 
        if (data.gslot.data)
          `uvm_error(get_type_name, "Reserved bits are not all 0")
    endcase
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr);
    // If we're S7 (G-Slot), S8 has called us...
    if (is_s7_lopt) begin
      if (|upr)  
        `uvm_error(get_type_name, "Upper bits of LOpt-S8 (Slot 7) are not 0")
    end 
    // ....else we're S8 (HS-Slot), S15 has called us
    else if (upr[15:0])
      `uvm_error(get_type_name, "Upper bits of LOpt-S15 (Slot 8) are not 0")
  endfunction

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, 76'h0, fmt}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {'0, fmt, 16'h0}; //HDR set to all 0's
      is_s7_lopt : data.gslot  = {upr_6B, 76'h0, fmt}; //upper=CRC
      is_gslot   : data.gslot  = {'0, fmt};
    endcase
    check_rsvd();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    return data;
  endfunction

  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    {flitmode, slot_num} = {fm, sn};
    // perform checks and set status members
    check_rsvd();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
  endfunction

endclass

class m12_hbr extends slot_base_f256;

  `uvm_object_utils(m12_hbr)

  const bit [3:0] fmt = 4'd12;

  logic [11:0]    rsvd = '0;
  h2ddat256_hdr_t h2ddat_hdr[3:0]; /**/ rand h2ddat_c h2ddat_h[3:0]; //HS|H (3), G (4) 

  function new(string name = "m12_hbr");
    super.new(name);
    _fmt      = _HBR_M12;
    data[3:0] = 'd12;
  endfunction

  virtual function void create_objects(flit_mode_t fm, bit [3:0] sn, logic [3:0] set_valid = 'x);
    {flitmode, slot_num} = {fm, sn};
    foreach (h2ddat_h[ii]) begin
      if (ii==3 && (!is_gslot || is_s7_lopt)) continue;
      h2ddat_h[ii]            = h2ddat_c::type_id::create($sformatf("h2ddat_h[%0d]",ii));
      h2ddat_h[ii].flitmode   = F256;
      h2ddat_h[ii].hdr256.val = set_valid[ii];
    end
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void set_slot_consumed();
    empty_slot = is_gslot && !is_s7_lopt ? !(h2ddat_hdr.or with (item.val)) : 
                                           ~|{h2ddat_hdr[2].val, h2ddat_hdr[1].val, h2ddat_hdr[0].val};
    dat_consumed[0] = is_gslot && !is_s7_lopt  ? h2ddat_hdr.sum with (int'(item.val)) : 
                                                 h2ddat_hdr[2].val+h2ddat_hdr[1].val+h2ddat_hdr[0].val;
  endfunction

  virtual function bit [4:0] get_slot_consumed_upr(logic [47:0] upr);
    get_slot_consumed_upr[4:2] = 3'b0_10;
    get_slot_consumed_upr[1:0] = is_s7_lopt && upr[8];
  endfunction

  virtual protected function void check_rsvd();
    bit    err;
    string str;
    // Check txns
    if (h2ddat_hdr[0].rsvd)
      `uvm_error(get_type_name, "Reserved bits of h2ddat_hdr[0] are not 0")
    if (h2ddat_hdr[1].rsvd)
      `uvm_error(get_type_name, "Reserved bits of h2ddat_hdr[1] are not 0")
    if (is_split_slot) begin
      if (h2ddat_hdr[2].rsvd[0])
        `uvm_error(get_type_name, "Reserved bits of h2ddat_hdr[2] are not 0")
    end
    else if (h2ddat_hdr[2].rsvd)
      `uvm_error(get_type_name, "Reserved bits of h2ddat_hdr[2] are not 0")
    if (is_gslot && !is_s7_lopt && h2ddat_hdr[3].rsvd)
      `uvm_error(get_type_name, "Reserved bits of h2ddat_hdr[3] are not 0")
    // Check upper reserved bits
    case (1'b1)
      is_hsslot  : /*check upper only, not present here*/;
      is_hslot   : begin
                     str = "H";
                     err = |data.hslot.data[111-:24];
                   end
      is_s7_lopt : /*check upper only, not present here*/;
      is_gslot   : begin
                     str = "G";
                     err = |rsvd;
                   end
    endcase
    if (err)
      `uvm_error(get_type_name, {"Upper bits of ",str," slot are not 0"})
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr);
    logic [11:0]    rsvdh;
    h2ddat256_hdr_t h2ddat_hdr;
    logic [ 7:0]    rsvdl;
    // If we're S7 (G-Slot), S8 has called us...
    if (is_s7_lopt) begin
      {rsvdh, h2ddat_hdr, rsvdl} = upr;
      // Check txn 
      if (rsvdl)
        `uvm_error(get_type_name, "Reserved bits of h2ddat_hdr[2] are not 0")
      if (h2ddat_hdr.rsvd)
        `uvm_error(get_type_name, "Reserved bits of h2ddat_hdr[3] are not 0")
      // Check upper reserved bits
      if (rsvdh)
        `uvm_error(get_type_name, "Upper bits of LOpt-S8 (Slot 7) are not 0")
    end
    // ....else we're S8 (HS-Slot), S15 has called us
    else begin
      if (upr[7:0])
        `uvm_error(get_type_name, "Reserved bits of h2ddat_hdr[2] are not 0")
      if (upr[15:8])
        `uvm_error(get_type_name, "Upper bits of LOpt-S15 (Slot 8) are not 0")
    end
  endfunction

  virtual protected function void check_tightly_packed();
    bit       tightly_packed = 1;
    bit [0:3] valid = {h2ddat_hdr[0].val, 
                       h2ddat_hdr[1].val,   
                       h2ddat_hdr[2].val, 
                       is_gslot && !is_s7_lopt && h2ddat_hdr[3].val};
    casez(valid)
      4'b01?? : tightly_packed = 1'b0;
      4'b?01? : tightly_packed = 1'b0;
      4'b??01 : tightly_packed = 1'b0;
    endcase
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual function void check_tightly_packed_upr(logic [47:0] upr);                        
    bit       tightly_packed = 1;
    bit [0:3] valid = {h2ddat_hdr[0].val, 
                       h2ddat_hdr[1].val,   
                       h2ddat_hdr[2].val, 
                       is_s7_lopt && upr[8]};
    casez(valid)
      4'b01?? : tightly_packed = 1'b0;
      4'b?01? : tightly_packed = 1'b0;
      4'b??01 : tightly_packed = 1'b0;
    endcase
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  /* Set slot_num and flitmode before calling any methods */

  /* User called methods */
  // It is expected users will use these flows to pack or unpack a slot with (randomized) data
  // - Packing: <h>.create_objects(<flitmode>, <slotnum>, <val>); <h>.copy(<object>); <h>.randomize; <h>.pack_slot;
  // - Unpacking: <h>.unpack_slot(<flitmode>, <slotnum>, <data>);

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    if (h2ddat_h[0] != null) h2ddat_hdr[0] = h2ddat_h[0].hdr256;
    if (h2ddat_h[1] != null) h2ddat_hdr[1] = h2ddat_h[1].hdr256;
    if (h2ddat_h[2] != null) h2ddat_hdr[2] = h2ddat_h[2].hdr256;
    if (h2ddat_h[3] != null) h2ddat_hdr[3] = h2ddat_h[3].hdr256;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, h2ddat_hdr[2][19:0], h2ddat_hdr[1], h2ddat_hdr[0], fmt}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {'0, h2ddat_hdr[2], h2ddat_hdr[1], h2ddat_hdr[0], fmt, 16'h0}; //HDR set to all 0's
      is_s7_lopt : data.gslot  = {upr_6B, h2ddat_hdr[2][19:0], h2ddat_hdr[1], h2ddat_hdr[0], fmt}; //upper=CRC
      is_gslot   : data.gslot  = {'0, h2ddat_hdr[3], h2ddat_hdr[2], h2ddat_hdr[1], h2ddat_hdr[0], fmt};
    endcase
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    return data;
  endfunction
  
  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    // create handles
    create_objects(fm, sn);
    // unpack to internal variables
    case (1'b1)
      is_hslot      :                      {h2ddat_hdr[2], h2ddat_hdr[1], h2ddat_hdr[0]} = data.hslot.data;
      is_split_slot :                {h2ddat_hdr[2][19:0], h2ddat_hdr[1], h2ddat_hdr[0]} = data.split.lower;
      is_gslot      : {rsvd, h2ddat_hdr[3], h2ddat_hdr[2], h2ddat_hdr[1], h2ddat_hdr[0]} = data.gslot.data;
    endcase
    // copy internal variables to handles
    h2ddat_h[0].hdr256 = h2ddat_hdr[0];
    h2ddat_h[1].hdr256 = h2ddat_hdr[1];
    if (is_split_slot)
      h2ddat_h[2].hdr256[19:0] = h2ddat_hdr[2][19:0];
    else
      h2ddat_h[2].hdr256 = h2ddat_hdr[2];
    if (is_gslot && !is_s7_lopt) 
      h2ddat_h[3].hdr256 = h2ddat_hdr[3];
    // perform checks and set status members
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
  endfunction

endclass

class m13_hbr extends slot_base_f256;

  `uvm_object_utils(m13_hbr)

  const bit [3:0] fmt = 4'd13;

  logic [27:0]    rsvd = '0;
  d2hdat256_hdr_t d2hdat_hdr[3:0]; /**/ rand d2hdat_c d2hdat_h[3:0]; //HS (3), H|G (4)

  bit [3:0] bep;

  function new(string name = "m13_hbr");
    super.new(name);
    _fmt      = _HBR_M13;
    data[3:0] = 'd13;
  endfunction

  virtual function void create_objects(flit_mode_t fm, bit [3:0] sn, logic [3:0] set_valid = 'x);
    {flitmode, slot_num} = {fm, sn};
    foreach (d2hdat_h[ii]) begin
      if (ii==3 && is_hsslot) continue;
      d2hdat_h[ii]            = d2hdat_c::type_id::create($sformatf("d2hdat_h[%0d]",ii));
      d2hdat_h[ii].flitmode   = F256;
      d2hdat_h[ii].hdr256.val = set_valid[ii];
    end
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void set_slot_consumed();
    empty_slot = is_gslot || is_hslot ? !(d2hdat_hdr.or with (item.val)) : 
                                        ~|{d2hdat_hdr[2].val, d2hdat_hdr[1].val, d2hdat_hdr[0].val};
    dat_consumed[0] = is_gslot || is_hslot ? d2hdat_hdr.sum with (int'(item.val)) :
                                             d2hdat_hdr[2].val+d2hdat_hdr[1].val+d2hdat_hdr[0].val;
  endfunction

  virtual protected function void check_rsvd();
    bit    err;
    string str;
    // Check txns
    if (d2hdat_hdr[0].rsvd)
      `uvm_error(get_type_name, "Reserved bits of d2hdat_hdr[0] are not 0")
    if (d2hdat_hdr[1].rsvd)
      `uvm_error(get_type_name, "Reserved bits of d2hdat_hdr[1] are not 0")
    if (d2hdat_hdr[2].rsvd)
      `uvm_error(get_type_name, "Reserved bits of d2hdat_hdr[2] are not 0")
    if ((is_hslot || (is_gslot && !is_s7_lopt)) && d2hdat_hdr[3].rsvd)
      `uvm_error(get_type_name, "Reserved bits of d2hdat_hdr[3] are not 0")
    // Check upper reserved bits
    case (1'b1)
      is_hsslot  : begin
                     str = "HS";
                     err = |data.hsslot.s8_lwr[79:76];
                   end
      is_hslot   : begin
                     str = "H";
                     err = |rsvd[11:0];
                   end
      is_s7_lopt : /*check upper only, not present here*/;
      is_gslot   : begin
                     str = "G";
                     err = |rsvd;
                   end
    endcase
    if (err)
      `uvm_error(get_type_name, {"Upper bits of ",str," slot are not 0"})
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr);
    logic [27:0]    rsvd;
    d2hdat256_hdr_t d2hdat_hdr;
    // If we're S7 (G-Slot), S8 has called us...
    if (is_s7_lopt) begin
      {rsvd, d2hdat_hdr} = {upr, 4'hx};
      // Check txn 
      if (d2hdat_hdr.rsvd)
        `uvm_error(get_type_name, "Reserved bits of d2hdat_hdr are not 0")
      // Check upper reserved bits
      if (rsvd)
        `uvm_error(get_type_name, "Upper bits of LOpt-S8 (Slot 7) are not 0")
    end
    // ....else we're S8 (HS-Slot), S15 has called us
    else if (upr[15:0])
      `uvm_error(get_type_name, "Upper bits of LOpt-S15 (Slot 8) are not 0")
  endfunction

  virtual protected function void check_tightly_packed();
    bit       tightly_packed = 1;
    bit [0:3] valid = {d2hdat_hdr[0].val, 
                       d2hdat_hdr[1].val, 
                       d2hdat_hdr[2].val, 
                       !is_hsslot && d2hdat_hdr[3].val};
    casez(valid)
      4'b01?? : tightly_packed = 1'b0;
      4'b?01? : tightly_packed = 1'b0;
      4'b??01 : tightly_packed = 1'b0;
    endcase
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual protected function void set_trailers();
    for (int ii=0; ii<(is_split_slot?3:4); ii++)
      bep[ii] = (d2hdat_hdr[ii].bep && d2hdat_hdr[ii].val);
  endfunction

  /* Set slot_num and flitmode before calling any methods */

  /* User called methods */
  // It is expected users will use these flows to pack or unpack a slot with (randomized) data
  // - Packing: <h>.create_objects(<flitmode>, <slotnum>, <val>); <h>.copy(<object>); <h>.randomize; <h>.pack_slot;
  // - Unpacking: <h>.unpack_slot(<flitmode>, <slotnum>, <data>);

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    if (d2hdat_h[0] != null) d2hdat_hdr[0] = d2hdat_h[0].hdr256;
    if (d2hdat_h[1] != null) d2hdat_hdr[1] = d2hdat_h[1].hdr256;
    if (d2hdat_h[2] != null) d2hdat_hdr[2] = d2hdat_h[2].hdr256;
    if (d2hdat_h[3] != null) d2hdat_hdr[3] = d2hdat_h[3].hdr256;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, 4'h0, d2hdat_hdr[2], d2hdat_hdr[1], d2hdat_hdr[0], fmt}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {'0, d2hdat_hdr[3], d2hdat_hdr[2], d2hdat_hdr[1], d2hdat_hdr[0], fmt, 16'h0}; //HDR set to all 0's
      is_s7_lopt : data.gslot  = {upr_6B, d2hdat_hdr[3][3:0], d2hdat_hdr[2], d2hdat_hdr[1], d2hdat_hdr[0], fmt}; //upper=CRC
      is_gslot   : data.gslot  = {'0, d2hdat_hdr[3], d2hdat_hdr[2], d2hdat_hdr[1], d2hdat_hdr[0], fmt};
    endcase
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    set_trailers();
    return data;
  endfunction
  
  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    // create handles
    create_objects(fm, sn);
    // unpack to internal variables
    case (1'b1)
      is_hsslot  :                            {d2hdat_hdr[2], d2hdat_hdr[1], d2hdat_hdr[0]} = data.hsslot.s8_lwr;
      is_hslot   : {rsvd[11:0], d2hdat_hdr[3], d2hdat_hdr[2], d2hdat_hdr[1], d2hdat_hdr[0]} = data.hslot.data;
      is_s7_lopt :        {d2hdat_hdr[3][3:0], d2hdat_hdr[2], d2hdat_hdr[1], d2hdat_hdr[0]} = data.s7_lopt.s7_lwr;
      is_gslot   :       {rsvd, d2hdat_hdr[3], d2hdat_hdr[2], d2hdat_hdr[1], d2hdat_hdr[0]} = data.gslot.data;
    endcase
    // copy internal variables to handles
    d2hdat_h[0].hdr256 = d2hdat_hdr[0];
    d2hdat_h[1].hdr256 = d2hdat_hdr[1];
    d2hdat_h[2].hdr256 = d2hdat_hdr[2];
    if (is_gslot && is_s7_lopt) 
      d2hdat_h[3].hdr256[3:0] = d2hdat_hdr[3][3:0];
    else if (is_hslot || (is_gslot && !is_s7_lopt)) 
      d2hdat_h[3].hdr256 = d2hdat_hdr[3];
    // perform checks and set status members
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    set_trailers();
  endfunction

endclass

class m14_hbr extends slot_base_f256;

  `uvm_object_utils(m14_hbr)

  const bit [3:0] fmt = 4'd14;

  logic [23:0]    rsvd = '0;
  m2srwd256_hdr_t m2srwd_hdr; /**/ rand m2srwd_c m2srwd_h; //HS (12 bit zero ext), H|G

  bit trp;

  function new(string name = "m14_hbr");
    super.new(name);
    _fmt      = _HBR_M14;
    data[3:0] = 'd14;
  endfunction

  virtual function void create_objects(flit_mode_t fm, bit [3:0] sn, logic set_valid = 'x);
    {flitmode, slot_num} = {fm, sn};
    m2srwd_h             = m2srwd_c::type_id::create("m2srwd_h");
    m2srwd_h.flitmode    = F256;
    m2srwd_h.hdr256.val  = set_valid;
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void set_slot_consumed();
    empty_slot      = !m2srwd_hdr.val;
    dat_consumed[1] = m2srwd_hdr.val;
  endfunction

  virtual protected function void check_rsvd();
    bit    err;
    string str;
    // Check txns
    if ((is_hslot || (is_gslot && !is_s7_lopt)) && m2srwd_hdr.rsvd)
      `uvm_error(get_type_name, "Reserved bits of m2srwd_hdr are not 0")
    // Check upper reserved bits
    case (1'b1)
      is_hsslot  : /*check upper only, not present here*/;
      is_hslot   : begin
                     str = "H";
                     err = |rsvd[3:0];
                   end
      is_s7_lopt : /*check upper only, not present here*/;
      is_gslot   : begin
                     str = "G";
                     err = |rsvd;
                   end
    endcase
    if (err)
      `uvm_error(get_type_name, {"Upper bits of ",str," slot are not 0"})
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr);
    // If we're S7 (G-Slot), S8 has called us...
    if (is_s7_lopt) begin
      // Check txn 
      if (upr[25:17])
        `uvm_error(get_type_name, "Reserved bits of d2hrsp[0] are not 0")
      // Check upper reserved bits
      if (upr[47-:20])
        `uvm_error(get_type_name, "Upper bits of LOpt-S8 (Slot 7) are not 0")
    end
    // ....else we're S8 (HS-Slot), S15 has called us
    // - do nothing -
  endfunction

  virtual protected function void set_trailers();
    trp = (m2srwd_hdr.trp && m2srwd_hdr.val);
  endfunction

  /* Set slot_num and flitmode before calling any methods */

  /* User called methods */
  // It is expected users will use these flows to pack or unpack a slot with (randomized) data
  // - Packing: <h>.create_objects(<flitmode>, <slotnum>, <val>); <h>.copy(<object>); <h>.randomize; <h>.pack_slot;
  // - Unpacking: <h>.unpack_slot(<flitmode>, <slotnum>, <data>);

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    if (m2srwd_h != null) m2srwd_hdr = m2srwd_h.hdr256;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, m2srwd_hdr[75:0], fmt}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {'0, m2srwd_hdr, fmt, 16'h0}; //HDR set to all 0's
      is_s7_lopt : data.gslot  = {upr_6B, m2srwd_hdr[75:0], fmt}; //upper=CRC
      is_gslot   : data.gslot  = {'0, m2srwd_hdr, fmt};
    endcase
    check_rsvd();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    set_trailers();
    return data;
  endfunction
  
  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    // create handles
    create_objects(fm, sn);
    // unpack to internal variables
    case (1'b1)
      is_hslot      : {rsvd[3:0], m2srwd_hdr} = data.hslot.data; 
      is_split_slot :      {m2srwd_hdr[75:0]} = data.split.lower; 
      is_gslot      :      {rsvd, m2srwd_hdr} = data.gslot.data; 
    endcase
    // copy internal variables to handles
    if (is_split_slot)
      m2srwd_h.hdr256[75:0] = m2srwd_hdr[75:0];
    else
      m2srwd_h.hdr256 = m2srwd_hdr;
    // perform checks and set status members
    check_rsvd();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    set_trailers();
  endfunction

endclass

class m15_hbr extends slot_base_f256;

  `uvm_object_utils(m15_hbr)

  const bit [3:0] fmt = 4'd15;

  logic [3:0]     rsvd = '0;
  s2mdrs256_hdr_t s2mdrs_hdr[2:0]; /**/ rand s2mdrs_c s2mdrs_h[2:0]; //HS|H (2), G (3)

  bit [2:0] trp;

  function new(string name = "m15_hbr");
    super.new(name);
    _fmt      = _HBR_M15;
    data[3:0] = 'd15;
  endfunction

  virtual function void create_objects(flit_mode_t fm, bit [3:0] sn, logic [2:0] set_valid = 'x);
    {flitmode, slot_num} = {fm, sn};
    foreach (s2mdrs_h[ii]) begin
      if (ii==2 && (!is_gslot || is_s7_lopt)) continue;
      s2mdrs_h[ii]            = s2mdrs_c::type_id::create($sformatf("s2mdrs_h[%0d]",ii));
      s2mdrs_h[ii].flitmode   = F256;
      s2mdrs_h[ii].hdr256.val = set_valid[ii];
    end
  endfunction

  /* Protected methods - called by pack/unpack */

  virtual protected function void set_slot_consumed();
    empty_slot = is_gslot && !is_s7_lopt ? !(s2mdrs_hdr.or with (item.val)) : 
                                           ~|{s2mdrs_hdr[1].val, s2mdrs_hdr[0].val};
    dat_consumed[1] = is_gslot && !is_s7_lopt ? s2mdrs_hdr.sum with (int'(item.val)) : 
                                                s2mdrs_hdr[1].val+s2mdrs_hdr[0].val; 
  endfunction

  virtual function bit [4:0] get_slot_consumed_upr(logic [47:0] upr); return '0;
    return (is_s7_lopt && upr[4] ? 5'b1_10_01 : '0);
  endfunction

  virtual protected function void check_rsvd();
    bit    err;
    string str;
    // Check txns
    if (s2mdrs_hdr[0].rsvd)
      `uvm_error(get_type_name, "Reserved bits of s2mdrs_hdr[0] are not 0")
    if (is_split_slot) begin
      if (s2mdrs_hdr[1].rsvd[3:0])
        `uvm_error(get_type_name, "Reserved bits of s2mdrs_hdr[1] are not 0")
    end
    else if (s2mdrs_hdr[1].rsvd)
      `uvm_error(get_type_name, "Reserved bits of s2mdrs_hdr[1] are not 0")
    if (is_gslot && !is_s7_lopt && s2mdrs_hdr[2].rsvd)
      `uvm_error(get_type_name, "Reserved bits of s2mdrs_hdr[2] are not 0")
    // Check upper reserved bits
    case (1'b1)
      is_hsslot  : /*check upper only, not present here*/;
      is_hslot   : begin
                     str = "H";
                     err = |data.hslot.data[111-:28];
                   end
      is_s7_lopt : /*check upper only, not present here*/;
      is_gslot   : begin
                     str = "G";
                     err = |rsvd;
                   end
    endcase
    if (err)
      `uvm_error(get_type_name, {"Upper bits of ",str," slot are not 0"})
  endfunction

  virtual function void check_rsvd_upr(logic [47:0] upr);
    logic [3:0]     rsvdh;
    s2mdrs256_hdr_t s2mdrs_hdr;
    logic [3:0]     rsvdl;
    // If we're S7 (G-Slot), S8 has called us...
    if (is_s7_lopt) begin
      {rsvd, s2mdrs_hdr, rsvdl} = upr;
      // Check txn 
      if (rsvdl)
        `uvm_error(get_type_name, "Reserved bits of s2mdrs_hdr[1] are not 0")
      if (s2mdrs_hdr.rsvd)
        `uvm_error(get_type_name, "Reserved bits of s2mdrs_hdr[2] are not 0")
      // Check upper reserved bits
      if (rsvdh)
        `uvm_error(get_type_name, "Upper bits of LOpt-S8 (Slot 7) are not 0")
    end
    // ....else we're S8 (HS-Slot), S15 has called us
    else begin
      // Check txn 
      if (upr[3:0])
        `uvm_error(get_type_name, "Reserved bits of s2mdrs_hdr[1] are not 0")
      // Check upper reserved bits
      if (upr[15:4])
        `uvm_error(get_type_name, "Upper bits of LOpt-S15 (Slot 8) are not 0")
    end
  endfunction

  virtual protected function void check_tightly_packed();
    bit       tightly_packed = 1'b1;
    bit [0:2] valid = {s2mdrs_hdr[0].val, 
                       s2mdrs_hdr[1].val, 
                       is_gslot && !is_s7_lopt && s2mdrs_hdr[2].val};
    casez(valid)
      3'b01?  : tightly_packed = 1'b0;
      3'b?01  : tightly_packed = 1'b0;
    endcase
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual protected function void check_tightly_packed_upr(logic [47:0] upr);
    bit       tightly_packed = 1'b1;
    bit [0:2] valid = {s2mdrs_hdr[0].val, 
                       s2mdrs_hdr[1].val, 
                       is_s7_lopt && upr[4]};
    casez(valid)
      3'b01?  : tightly_packed = 1'b0;
      3'b?01  : tightly_packed = 1'b0;
    endcase
    if (!tightly_packed)
      `uvm_error(get_type_name, "Slot not tightly packed, see CXL spec: 'Flit Packing Rules'")
  endfunction

  virtual protected function void set_trailers();
    for (int ii=0; ii<((is_gslot&&!is_s7_lopt)?3:2); ii++)
      trp[ii] = (s2mdrs_hdr[ii].trp && s2mdrs_hdr[ii].val);
  endfunction

  /* Set slot_num and flitmode before calling any methods */

  /* User called methods */
  // It is expected users will use these flows to pack or unpack a slot with (randomized) data
  // - Packing: <h>.create_objects(<flitmode>, <slotnum>, <val>); <h>.copy(<object>); <h>.randomize; <h>.pack_slot;
  // - Unpacking: <h>.unpack_slot(<flitmode>, <slotnum>, <data>);

  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B = '0);
    bit [4:0] ctupl;
    if (s2mdrs_h[0] != null) s2mdrs_hdr[0] = s2mdrs_h[0].hdr256;
    if (s2mdrs_h[1] != null) s2mdrs_hdr[1] = s2mdrs_h[1].hdr256;
    if (s2mdrs_h[2] != null) s2mdrs_hdr[2] = s2mdrs_h[2].hdr256;
    case (1'b1)
      is_hsslot  : data.hsslot = {upr_6B, s2mdrs_hdr[1][35:0], s2mdrs_hdr[0], fmt}; //upper=cont. S7 (must provide valid upr_6B)
      is_hslot   : data.hslot  = {'0, s2mdrs_hdr[1], s2mdrs_hdr[0], fmt, 16'h0}; //HDR set to all 0's
      is_s7_lopt : data.gslot  = {upr_6B, s2mdrs_hdr[1][35:0], s2mdrs_hdr[0], fmt}; //upper=CRC
      is_gslot   : data.gslot  = {'0, s2mdrs_hdr[2], s2mdrs_hdr[1], s2mdrs_hdr[0], fmt};
    endcase
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    set_trailers();
    return data;
  endfunction
  
  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x);
    bit [4:0] ctupl;
    // pass in args
    if (dat !== 'x) data = dat;
    // create handles
    create_objects(fm, sn);
    // unpack to internal variables
    case (1'b1)
      is_hslot      :                      {s2mdrs_hdr[1], s2mdrs_hdr[0]} = data.hslot.data;
      is_split_slot :                {s2mdrs_hdr[1][35:0], s2mdrs_hdr[0]} = data.split.lower;
      is_gslot      : {rsvd, s2mdrs_hdr[2], s2mdrs_hdr[1], s2mdrs_hdr[0]} = data.gslot.data;
    endcase
    // copy internal variables to handles
    s2mdrs_h[0].hdr256 = s2mdrs_hdr[0];
    if (is_split_slot)
      s2mdrs_h[1].hdr256[35:0] = s2mdrs_hdr[1][35:0];
    else
      s2mdrs_h[1].hdr256 = s2mdrs_hdr[1];
    if (is_gslot && !is_s7_lopt) 
      s2mdrs_h[2].hdr256 = s2mdrs_hdr[2];
    // perform checks and set status members
    check_rsvd();
    check_tightly_packed();
    set_slot_consumed();
    if (is_hsslot) begin
      lower_slot.check_rsvd_upr(get_split_upper);
      lower_slot.check_tightly_packed_upr(get_split_upper);
      ctupl = lower_slot.get_slot_consumed_upr(get_split_upper);
      case (ctupl[3:2])
        1 : req_consumed[ctupl[4]] += ctupl[1:0];
        2 : dat_consumed[ctupl[4]] += ctupl[1:0];
        3 : rsp_consumed[ctupl[4]] += ctupl[1:0];
      endcase 
      empty_slot &= !(ctupl[3:2] && ctupl[1:0]);
    end
    set_trailers();
  endfunction

endclass

class f256_data extends slot_base_f256;

  `uvm_object_utils(f256_data)

  function new(string name = "f256_data");
    super.new(name);
    _fmt       = _D;
    empty_slot = 1'b0;
  endfunction

endclass

class f256_trailer extends slot_base_f256;

  `uvm_object_utils(f256_trailer)

  function new(string name = "f256_trailer");
    super.new(name);
    _fmt       = _T;
    empty_slot = 1'b0;
  endfunction

endclass

// Special case: Slot15 is reserved for PHY layer
class s15_phy extends slot_base_f256;

  `uvm_object_utils(s15_phy)

  logic empty_flit = 'x;

  function new(string name = "s15_phy");
    super.new(name);
    slot_num   = 15;
    _fmt       = _S15_PHY;
    empty_slot = 1'b1;
  endfunction 

  virtual function logic [127:0] pack_phy(flit_mode_t  fm, 
                                          bit   [15:0] crd = '0,
                                          logic [63:0] crc = 'x, //F256=8B, F256_LOPT=6B
                                          logic [47:0] fec = 'x, 
                                          bit   [15:0] upr_2B = '0); //F256_LOPT only
    flitmode = fm;
    // Randomize if not provided
    crc = (crc==='x) ? '0 : (crc==='z ? {$urandom, $urandom} : crc);
    fec = (fec==='x) ? '0 : (fec==='z ? {$urandom, $urandom} : fec);
    if (flitmode == F256_LOPT) 
      data.s15_lopt = {crc[47:0], fec, upr_2B, crd};
    else
      data.s15 = {fec, crc, crd};
    // Fill in the credits to integer arrays
    parse_credits();
    // Check the upper part of HS-Slot
    if (flitmode == F256_LOPT)
      lower_slot.check_rsvd_upr(data.s15_lopt.s8_upr);
    return data;
  endfunction

  // sn is unused because that's hardcoded, but must match func prototype in base class
  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x); 
    bit [4:0] ctupl;
    flitmode = fm;
    if (sn != 15) `uvm_error(get_type_name, "sn (slot number) argument must be 15")
    if (dat !== 'x) data = dat;
    // Fill in the credits to integer arrays
    parse_credits();
    // Check the upper part of HS-Slot
    if (flitmode == F256_LOPT)
      lower_slot.check_rsvd_upr(data.s15_lopt.s8_upr);
  endfunction

  // Convert combined credit field to integers : negative consumed credits means adding credits
  virtual function void parse_credits();
    empty_flit = (data.s15.crd[4:0] == 'h01); 
    /* REQ */
    if (data.s15.crd[4] == 0) begin //CXL.cache
      case (data.s15.crd[3:0]) inside
        'h0,'h1 : /*no credits*/;
        'h4,'h9 : req_consumed[CCH] = -1;
        'h5,'hA : req_consumed[CCH] = -4;
        'h6,'hB : req_consumed[CCH] = -8;
        'h7,'hC : req_consumed[CCH] = -12;
        'h8,'hD : req_consumed[CCH] = -16;
        default : `uvm_error(get_type_name, $sformatf("CRD[4:0] = 'h%h is reserved",data.s15.crd[4:0]))
      endcase
    end
    else begin //CXL.mem
      case (data.s15.crd[3:0]) inside
        'h4,'h9 : req_consumed[MEM] = -1;
        'h5,'hA : req_consumed[MEM] = -4;
        'h6,'hB : req_consumed[MEM] = -8;
        'h7,'hC : req_consumed[MEM] = -12;
        'h8,'hD : req_consumed[MEM] = -16;
        default : `uvm_error(get_type_name, $sformatf("CRD[4:0] = 'h%h is reserved",data.s15.crd[4:0]))
      endcase
    end
    /* DAT */
    if (data.s15.crd[9] == 0) begin //CXL.cache
      case (data.s15.crd[8:5]) inside
        'h0     : /*no credits*/;
        'h4,'h9 : dat_consumed[CCH] = -1;
        'h5,'hA : dat_consumed[CCH] = -4;
        'h6,'hB : dat_consumed[CCH] = -8;
        'h7,'hC : dat_consumed[CCH] = -12;
        'h8,'hD : dat_consumed[CCH] = -16;
        default : `uvm_error(get_type_name, $sformatf("CRD[9:5] = 'h%h is reserved",data.s15.crd[9:5]))
      endcase
    end
    else begin //CXL.mem
      case (data.s15.crd[8:5]) inside
        'h4,'h9 : dat_consumed[MEM] = -1;
        'h5,'hA : dat_consumed[MEM] = -4;
        'h6,'hB : dat_consumed[MEM] = -8;
        'h7,'hC : dat_consumed[MEM] = -12;
        'h8,'hD : dat_consumed[MEM] = -16;
        default : `uvm_error(get_type_name, $sformatf("CRD[9:5] = 'h%h is reserved",data.s15.crd[9:5]))
      endcase
    end
    /* RSP */
    if (data.s15.crd[14] == 0) begin //CXL.cache
      case (data.s15.crd[13:10]) inside
        'h0     : /*no credits*/;
        'h4,'h9 : rsp_consumed[CCH] = -1;
        'h5,'hA : rsp_consumed[CCH] = -4;
        'h6,'hB : rsp_consumed[CCH] = -8;
        'h7,'hC : rsp_consumed[CCH] = -12;
        'h8,'hD : rsp_consumed[CCH] = -16;
        default : `uvm_error(get_type_name, $sformatf("CRD[14:10] = 'h%h is reserved",data.s15.crd[14:10]))
      endcase
    end
    else begin //CXL.mem
      case (data.s15.crd[13:10]) inside
        'h4,'h9 : rsp_consumed[MEM] = -1;
        'h5,'hA : rsp_consumed[MEM] = -4;
        'h6,'hB : rsp_consumed[MEM] = -8;
        'h7,'hC : rsp_consumed[MEM] = -12;
        'h8,'hD : rsp_consumed[MEM] = -16;
        default : `uvm_error(get_type_name, $sformatf("CRD[14:10] = 'h%h is reserved",data.s15.crd[14:10]))
      endcase
    end
    if (data.s15.crd[15])
      `uvm_error(get_type_name, "CRD[15] is reserved and not 0")
  endfunction

  /* Helper functions to grab certain fields */

  virtual function logic [15:0] get_s8_upper();
    return (flitmode==F256_LOPT ? data.s15_lopt.s8_upr : 'x);
  endfunction

  virtual function logic [15:0] get_crd();
    return data.s15.crd;
  endfunction

endclass
