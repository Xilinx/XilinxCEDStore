// flit68_tl_assembler = "68B flit (link layer) to transaction layer assembler"
// Description :
//   Takes in flits of data that contain handles to objects and converts them
//   to transaction layer messages and broadcasts those as seen in time order.
//   Note that this issues split txns (32B; half-cacheline) as two txns
//   instead of one. A future enhancement would be to add a control bit to  
//   broadcast them as either one or two txns. The total_* and cnt_* registers
//   work on a full 64B cacheline transaction, however.  For example, the 
//   following should be true:
//     total_d2hdat = cnt_d2hdat_full + cnt_d2hdat_be + cnt_d2hdat_split + 
//                    cnt_d2hdat_split_be
class flit68_tl_assembler#(type T) extends uvm_subscriber#(T);

  `uvm_component_param_utils(flit68_tl_assembler#(T)) 

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"flit68_tl_assembler#(",T::type_name,")"};
  virtual function string get_type_name(); return type_name; endfunction

  bit is_slave;

  uvm_analysis_port#(base_txn)           base_llc_ap; 
  uvm_analysis_port#(base_txn)           base_tl_ap; 
  uvm_analysis_port#(cxl_nfi_credit_txn) cred_ret_ap; 
  uvm_analysis_port#(cxl_nfi_credit_txn) cred_give_ap; 

  uvm_event init_param_rcvd;

  // total txn counters
  int unsigned total_h2dreq, total_h2ddat, total_h2drsp;
  int unsigned total_d2hreq, total_d2hdat, total_d2hrsp;
  int unsigned total_m2sreq, total_m2srwd;
  int unsigned total_s2mndr, total_s2mdrs;
  // detailed txn counters
  int unsigned cnt_m2srwd_full, cnt_m2srwd_be; 
  int unsigned cnt_h2ddat_full, cnt_h2ddat_split;
  int unsigned cnt_s2mdrs_full, cnt_s2mdrs_split;
  int unsigned cnt_d2hdat_full, cnt_d2hdat_be, 
               cnt_d2hdat_split, cnt_d2hdat_split_be;

  // Need to build data messages over multiple slots per flit and even between 
  // multiple flits (need persistence). Also need to keep track of data ordering
  // as it comes in.  To do so, we'll use a bounded queue (size 4) and push handles
  // onto it, then retrieve and cast, popping when that data message is complete.
  base_txn  dat_q[$:5];
  bit [1:0] dat_chunk_ptr;
  bit       s2mdrs_split_ptr;
  bit       be_next;
  bit       d2hdat_split_ch0_be;
  h2ddat_c  h2ddat_h[3:0], h2ddat_h_cur; 
  d2hdat_c  d2hdat_h[3:0], d2hdat_h_cur;
  m2srwd_c  m2srwd_h,      m2srwd_h_cur;
  s2mdrs_c  s2mdrs_h[2:0], s2mdrs_h_cur;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    base_llc_ap  = new("base_llc_ap", this);
    base_tl_ap   = new("base_tl_ap", this);
    cred_ret_ap  = new("cred_ret_ap", this);
    cred_give_ap = new("cred_give_ap", this);
  endfunction

  virtual function void write(T t);
    cxl_nfi_credit_txn c;
    string msg, name;
    int tcnt;
    int jj;
    bit hdr_sz;
    bit hdr_be;
    base_hslot_f68 hbase;
    for (int ii=0; ii<4; ii++) begin
      // Debug printing
      name = t.slot[ii]._fmt.name;
      name = (name=="_G0_BE") ? "BE" : name.substr(1,2);
      msg  = $sformatf("Slot %0d = %0s",ii,name);
      if (dat_q.size)
        msg = {msg, $sformatf(", dat_q.size = %0d, chnk_ptr = %0d", dat_q.size, dat_chunk_ptr)};
      if (t.slot[ii].dat_consumed[1]) begin
        msg = (t.slot[ii].dat_consumed[1])>1 ? {msg, $sformatf(", (M HDR; MDH%0d)",t.slot[ii].dat_consumed[1])} :
                                               {msg, ", (M HDR)"}; //M = mem 
      end
      else if (t.slot[ii].dat_consumed[0]) begin
        msg = (t.slot[ii].dat_consumed[0])>1 ? {msg, $sformatf(", ($ HDR; MDH%0d)",t.slot[ii].dat_consumed[0])} :
                                               {msg, ", ($ HDR)"}; //$ = cache
      end
      // Debug printing
      if (t.slot[ii].empty_slot) begin
        if (t.slot[ii]._fmt inside {[_H0:_H6]}) begin 
          $cast(hbase, t.slot[ii]);
          hdr_sz = hbase.hdr.sz;
          hdr_be = hbase.hdr.be;
          extract_credit_returns(hbase);
        end
        `uvm_info("DEBUG", {" ", msg, " (EMPTY)"}, UVM_HIGH)
        continue;
      end
      case(t.slot[ii]._fmt)
        _RSVD : continue;
        /* LL Control Slots */
        _RETRY, 
        _LLCRD,   
        _IDE, 
        _INIT : begin
                  case (t.slot[ii]._fmt)
                    _LLCRD : extract_credit_returns(t.slot[ii]);
                    _INIT  : begin
                               init_f68 init;
                               if (!$cast(init, t.slot[ii]))
                                 `uvm_fatal(get_type_name, "Invalid $cast to init") 
                               if (init.subtype == _PARAM && init_param_rcvd != null) 
                                 init_param_rcvd.trigger; 
                             end
                  endcase
                  if (t.slot[ii]._fmt == _LLCRD) begin
                    extract_credit_returns(t.slot[ii]);
                  end
                  base_llc_ap.write(t.slot[ii]);
                end
        /* Header Slots */
        _H0 : begin
                h0_f68 h0;
                if (!$cast(h0, t.slot[ii]))
                  `uvm_fatal(get_type_name, "Invalid $cast to h0") 
                if (h0.hdr.sz === 'x || h0.hdr.be === 'x)
                  `uvm_fatal(get_type_name, "Header's sz and/or be are 1'bx; check for mistakes")
                hdr_sz = h0.hdr.sz;
                hdr_be = h0.hdr.be;
                extract_credit_returns(h0);
                if (h0.dir == H2C) begin
                  if (h0.h2dreq_h.req68.val) begin
                    total_h2dreq++;
                    base_tl_ap.write(h0.h2dreq_h);
                    msg = {msg, "(1 H2DREQ)"};
                  end
                  if (h0.h2drsp_h.rsp68.val) begin
                    total_h2drsp++;
                    base_tl_ap.write(h0.h2drsp_h);
                    insert_txn_count(msg, "1 H2DRSP");
                  end
                end 
                else begin
                  for (jj=0,tcnt=0; jj<2; jj++)
                    if (h0.d2hrsp_h[jj].rsp68.val) begin
                      total_d2hrsp++;
                      base_tl_ap.write(h0.d2hrsp_h[jj]);
                      tcnt++;
                    end
                  if (tcnt)
                    insert_txn_count(msg, $sformatf("%0d D2HRSP",tcnt));
                  if (h0.s2mndr_h.ndr68.val) begin
                    total_s2mndr++;
                    base_tl_ap.write(h0.s2mndr_h);
                    insert_txn_count(msg, "1 S2MNDR");
                  end
                  if (h0.d2hdat_hdr.val) begin
                    // ensure we don't double count splits; 
                    // only incr on first chunk
                    if (hdr_sz || !h0.d2hdat_hdr.ch)
                      total_d2hdat++;
                    if (hdr_sz) begin
                      cnt_d2hdat_be   += hdr_be;
                      cnt_d2hdat_full += !hdr_be;
                    end
                    if (!hdr_sz && !h0.d2hdat_hdr.ch) begin
                      d2hdat_split_ch0_be = hdr_be;
                      if (!d2hdat_split_ch0_be)
                        cnt_d2hdat_split++;
                      else
                        cnt_d2hdat_split_be++;
                    end
                    else if ({!hdr_sz, h0.d2hdat_hdr.ch, !d2hdat_split_ch0_be, hdr_be}) 
                    begin
                      cnt_d2hdat_split--;
                      cnt_d2hdat_split_be++;
                    end
                    d2hdat_h[0] = d2hdat_c::type_id::create("d2hdat_h[0]"); 
                    d2hdat_h[0].flitmode = F68;
                    check_queue_full();
                    dat_q.push_back(d2hdat_h[0]);
                    d2hdat_h[0].hdr68 = h0.d2hdat_hdr;
                    d2hdat_h[0].txfer_64B = hdr_sz;
                    if (d2hdat_h[0].txfer_64B) begin //full cacheline
                      d2hdat_h[0].be = !hdr_be ? '1 : 'x;
                    end
                    else begin  // half cacheline (two chunks); specified by chunk valid (ch)
                      d2hdat_h[0].be[63:32] =  d2hdat_h[0].hdr68.ch && !hdr_be ? '1 : 'x;
                      d2hdat_h[0].be[31: 0] = !d2hdat_h[0].hdr68.ch && !hdr_be ? '1 : 'x;
                      if (d2hdat_h[0].hdr68.ch && (dat_q.size==1)) 
                        dat_chunk_ptr = 2;
                    end
                  end
                end
              end 
        _H1 : begin
                h1_f68 h1;
                if (!$cast(h1, t.slot[ii]))
                  `uvm_fatal(get_type_name, "Invalid $cast to h1") 
                if (h1.hdr.sz === 'x || h1.hdr.be === 'x)
                  `uvm_fatal(get_type_name, "Header's sz and/or be are 1'bx; check for mistakes")
                hdr_sz = h1.hdr.sz;
                hdr_be = h1.hdr.be;
                extract_credit_returns(h1);
                if (h1.dir == H2C) begin
                  for (jj=0,tcnt=0; jj<2; jj++)
                    if (h1.h2drsp_h[jj].rsp68.val) begin
                      total_h2drsp++;
                      base_tl_ap.write(h1.h2drsp_h[jj]);
                      tcnt++;
                    end
                  if (tcnt)
                    insert_txn_count(msg, $sformatf("%0d H2DRSP",tcnt));
                  if (h1.h2ddat_hdr.val) begin
                    // ensure we don't double count splits; 
                    // only incr on first chunk
                    if (hdr_sz || !h1.h2ddat_hdr.ch) begin
                      total_h2ddat++;
                    end
                    cnt_h2ddat_full += hdr_sz;
                    if (!hdr_sz && !h1.h2ddat_hdr.ch) begin
                      cnt_h2ddat_split++;
                    end
                    h2ddat_h[0] = h2ddat_c::type_id::create("h2ddat_h[0]"); 
                    h2ddat_h[0].flitmode = F68;
                    check_queue_full();
                    dat_q.push_back(h2ddat_h[0]);
                    h2ddat_h[0].hdr68 = h1.h2ddat_hdr;
                    h2ddat_h[0].txfer_64B = hdr_sz;
                    if (!h2ddat_h[0].txfer_64B && h2ddat_h[0].hdr68.ch && (dat_q.size==1))
                      dat_chunk_ptr = 2;
                  end
                end 
                else begin
                  if (h1.d2hreq_h.req68.val) begin
                    total_d2hreq++;
                    base_tl_ap.write(h1.d2hreq_h);
                    insert_txn_count(msg, "1 D2HREQ");
                  end
                  if (h1.d2hdat_hdr.val) begin
                    // ensure we don't double count splits; 
                    // only incr on first chunk
                    if (hdr_sz || !h1.d2hdat_hdr.ch)
                      total_d2hdat++;
                    if (hdr_sz) begin
                      cnt_d2hdat_be   += hdr_be;
                      cnt_d2hdat_full += !hdr_be;
                    end
                    if (!hdr_sz && !h1.d2hdat_hdr.ch) begin
                      d2hdat_split_ch0_be = hdr_be;
                      if (!d2hdat_split_ch0_be)
                        cnt_d2hdat_split++;
                      else
                        cnt_d2hdat_split_be++;
                    end
                    else if ({!hdr_sz, h1.d2hdat_hdr.ch, !d2hdat_split_ch0_be, hdr_be}) 
                    begin
                      cnt_d2hdat_split--;
                      cnt_d2hdat_split_be++;
                    end
                    d2hdat_h[0] = d2hdat_c::type_id::create("d2hdat_h[0]"); 
                    d2hdat_h[0].flitmode = F68;
                    check_queue_full();
                    dat_q.push_back(d2hdat_h[0]);
                    d2hdat_h[0].hdr68 = h1.d2hdat_hdr;
                    d2hdat_h[0].txfer_64B = hdr_sz;
                    if (d2hdat_h[0].txfer_64B) begin //full cacheline
                      d2hdat_h[0].be = !hdr_be ? '1 : 'x;
                    end
                    else begin  // half cacheline (two chunks); specified by chunk valid (ch)
                      d2hdat_h[0].be[63:32] =  d2hdat_h[0].hdr68.ch && !hdr_be ? '1 : 'x;
                      d2hdat_h[0].be[31: 0] = !d2hdat_h[0].hdr68.ch && !hdr_be ? '1 : 'x;
                      if (d2hdat_h[0].hdr68.ch && (dat_q.size==1)) 
                        dat_chunk_ptr = 2;
                    end
                  end
                end
              end 
        _H2 : begin
                h2_f68 h2;
                if (!$cast(h2, t.slot[ii]))
                  `uvm_fatal(get_type_name, "Invalid $cast to h2") 
                if (h2.hdr.sz === 'x || h2.hdr.be === 'x)
                  `uvm_fatal(get_type_name, "Header's sz and/or be are 1'bx; check for mistakes")
                hdr_sz = h2.hdr.sz;
                hdr_be = h2.hdr.be;
                extract_credit_returns(h2);
                if (h2.dir == H2C) begin
                  if (h2.h2dreq_h.req68.val) begin
                    total_h2dreq++;
                    base_tl_ap.write(h2.h2dreq_h);
                    insert_txn_count(msg, "1 H2DREQ");
                  end
                  if (h2.h2ddat_hdr.val) begin
                    // ensure we don't double count splits; 
                    // only incr on first chunk
                    if (hdr_sz || !h2.h2ddat_hdr.ch) begin
                      total_h2ddat++;
                    end
                    cnt_h2ddat_full += hdr_sz;
                    if (!hdr_sz && !h2.h2ddat_hdr.ch) begin
                      cnt_h2ddat_split++;
                    end
                    h2ddat_h[0] = h2ddat_c::type_id::create("h2ddat_h[0]"); 
                    h2ddat_h[0].flitmode = F68;
                    check_queue_full();
                    dat_q.push_back(h2ddat_h[0]);
                    h2ddat_h[0].hdr68 = h2.h2ddat_hdr;
                    h2ddat_h[0].txfer_64B = hdr_sz;
                    if (!h2ddat_h[0].txfer_64B && h2ddat_h[0].hdr68.ch && (dat_q.size==1))
                      dat_chunk_ptr = 2;
                  end
                end 
                else begin
                  if (h2.d2hrsp_h.rsp68.val) begin
                    total_d2hrsp++;
                    base_tl_ap.write(h2.d2hrsp_h);
                    insert_txn_count(msg, "1 D2HRSP");
                  end
                  // MDH; sz=1, BE=0 ALWAYS 
                  if (!hdr_sz || hdr_be) begin
                    `uvm_fatal(get_type_name, "ANY MDH must always have SZ=1 and BE=0")
                  end
                  else if ((h2.d2hdat_hdr.sum with (int'(item.val==1'b1)))<2)
                    `uvm_fatal(get_type_name, "ANY MDH must always have 2 or more valid data headers")
                  for (jj=0; jj<4; jj++) begin
                    if (h2.d2hdat_hdr[jj].val) begin
                      total_d2hdat++;
                      cnt_d2hdat_full++;
                      d2hdat_h[jj] = d2hdat_c::type_id::create($sformatf("d2hdat_h[%0d]",jj)); 
                      d2hdat_h[jj].flitmode = F68;
                      check_queue_full();
                      dat_q.push_back(d2hdat_h[jj]);
                      d2hdat_h[jj].hdr68 = h2.d2hdat_hdr[jj];
                      d2hdat_h[jj].txfer_64B = 1;
                      d2hdat_h[jj].be = '1;
                    end
                  end
                end
              end 
        _H3 : begin
                h3_f68 h3;
                if (!$cast(h3, t.slot[ii]))
                  `uvm_fatal(get_type_name, "Invalid $cast to h3") 
                if (h3.hdr.sz === 'x || h3.hdr.be === 'x)
                  `uvm_fatal(get_type_name, "Header's sz and/or be are 1'bx; check for mistakes")
                hdr_sz = h3.hdr.sz;
                hdr_be = h3.hdr.be;
                extract_credit_returns(h3);
                if (h3.dir == H2C) begin
                  // MDH; sz=1 ALWAYS (BE illegal for H2DDAT)
                  if (!hdr_sz || hdr_be) begin
                    `uvm_fatal(get_type_name, "ANY MDH must always have SZ=1 and BE=0")
                  end
                  else if ((h3.h2ddat_hdr.sum with (int'(item.val==1'b1)))<2)
                    `uvm_fatal(get_type_name, "ANY MDH must always have 2 or more valid data headers")
                  for (jj=0; jj<4; jj++) begin
                    if (h3.h2ddat_hdr[jj].val) begin
                      total_h2ddat++;
                      cnt_h2ddat_full++;
                      h2ddat_h[jj] = h2ddat_c::type_id::create($sformatf("h2ddat_h[%0d]",jj)); 
                      h2ddat_h[jj].flitmode = F68;
                      check_queue_full();
                      dat_q.push_back(h2ddat_h[jj]);
                      h2ddat_h[jj].hdr68     = h3.h2ddat_hdr[jj];
                      h2ddat_h[jj].txfer_64B = 1'b1;
                    end
                  end
                end 
                else begin
                  if (h3.s2mndr_h.ndr68.val) begin
                    total_s2mndr++;
                    base_tl_ap.write(h3.s2mndr_h);
                    insert_txn_count(msg, "1 S2MNDR");
                  end
                  if (h3.s2mdrs_hdr.val) begin
                    s2mdrs_h[0] = s2mdrs_c::type_id::create("s2mdrs_h[0]");
                    s2mdrs_h[0].flitmode = F68;
                    check_queue_full();
                    dat_q.push_back(s2mdrs_h[0]);
                    s2mdrs_h[0].hdr68 = h3.s2mdrs_hdr;
                    s2mdrs_h[0].txfer_64B = hdr_sz;
                    // ensure we don't double count splits; 
                    // only incr on first chunk
                    if (hdr_sz || !s2mdrs_split_ptr)
                      total_s2mdrs++;
                    if (!hdr_sz && !s2mdrs_split_ptr)
                      cnt_s2mdrs_split++;
                    else if (hdr_sz)
                      cnt_s2mdrs_full++;
                    if (!s2mdrs_h[0].txfer_64B) begin
                      s2mdrs_h[0].chunkval = s2mdrs_split_ptr;
                      s2mdrs_split_ptr = !s2mdrs_split_ptr;
                    end
                  end
                end
              end 
        _H4 : begin
                h4_f68 h4;
                if (!$cast(h4, t.slot[ii]))
                  `uvm_fatal(get_type_name, "Invalid $cast to h4") 
                if (h4.hdr.sz === 'x || h4.hdr.be === 'x)
                  `uvm_fatal(get_type_name, "Header's sz and/or be are 1'bx; check for mistakes")
                hdr_sz = h4.hdr.sz;
                hdr_be = h4.hdr.be;
                extract_credit_returns(h4);
                if (h4.dir == H2C) begin
                  if (h4.m2srwd_hdr.val) begin
                    total_m2srwd++;
                    m2srwd_h = m2srwd_c::type_id::create("m2srwd_h");
                    m2srwd_h.flitmode = F68;
                    check_queue_full();
                    dat_q.push_back(m2srwd_h);
                    m2srwd_h.hdr68 = h4.m2srwd_hdr;
                    if (!hdr_be) begin
                      m2srwd_h.be = '1;
                      cnt_m2srwd_full++;
                    end
                    else
                      cnt_m2srwd_be++;
                  end
                end
                else begin
                  for (jj=0,tcnt=0; jj<2; jj++)
                    if (h4.s2mndr_h[jj].ndr68.val) begin
                      total_s2mndr++;
                      base_tl_ap.write(h4.s2mndr_h[jj]);
                      tcnt++;
                    end
                  if (tcnt)
                    insert_txn_count(msg, $sformatf("%0d S2MNDR",tcnt));
                end
              end 
        _H5 : begin
                h5_f68 h5;
                if (!$cast(h5, t.slot[ii]))
                  `uvm_fatal(get_type_name, "Invalid $cast to h5") 
                if (h5.hdr.sz === 'x || h5.hdr.be === 'x)
                  `uvm_fatal(get_type_name, "Header's sz and/or be are 1'bx; check for mistakes")
                hdr_sz = h5.hdr.sz;
                hdr_be = h5.hdr.be;
                extract_credit_returns(h5);
                if (h5.dir == H2C) begin
                  if (h5.m2sreq_h.req68.val) begin
                    total_m2sreq++;
                    base_tl_ap.write(h5.m2sreq_h);
                    insert_txn_count(msg, "1 M2SREQ");
                  end
                end
                else begin
                  // MDH; sz=1 ALWAYS (BE illegal for S2MDRS)
                  if (!hdr_sz || hdr_be) begin
                    `uvm_fatal(get_type_name, "ANY MDH must always have SZ=1 and BE=0")
                  end
                  else if ((h5.s2mdrs_hdr.sum with (int'(item.val==1'b1)))<2)
                    `uvm_fatal(get_type_name, "ANY MDH must always have 2 or more valid data headers")
                  for (jj=0; jj<2; jj++) begin
                    if (h5.s2mdrs_hdr[jj].val) begin
                      total_s2mdrs++;
                      cnt_s2mdrs_full++;
                      s2mdrs_h[jj] = s2mdrs_c::type_id::create($sformatf("s2mdrs_h[%0d]",jj));
                      s2mdrs_h[jj].flitmode = F68;
                      check_queue_full();
                      dat_q.push_back(s2mdrs_h[jj]);
                      s2mdrs_h[jj].hdr68 = h5.s2mdrs_hdr[jj];
                      s2mdrs_h[jj].txfer_64B = 1;
                    end
                  end
                end
              end 
        _H6 : begin /* H6 is used for IDE */ 
                h5_f68 h6;
                `uvm_warning(get_type_name, "Object got an H6 slot, which is unsupported right now")
                if (!$cast(h6, t.slot[ii]))
                  `uvm_fatal(get_type_name, "Invalid $cast to h6") 
                if (h6.hdr.sz === 'x || h6.hdr.be === 'x)
                  `uvm_fatal(get_type_name, "Header's sz and/or be are 1'bx; check for mistakes")
                hdr_sz = h6.hdr.sz;
                hdr_be = h6.hdr.be;
                extract_credit_returns(h6);
              end
        /* Generic Slots */
        _G1 : begin
                g1_f68 g1;
                if (!$cast(g1, t.slot[ii]))
                  `uvm_fatal(get_type_name, "Invalid $cast to g1") 
                if (g1.dir == H2C) begin
                  for (jj=0,tcnt=0; jj<4; jj++)
                    if (g1.h2drsp_h[jj].rsp68.val) begin
                      total_h2drsp++;
                      base_tl_ap.write(g1.h2drsp_h[jj]);
                      tcnt++;
                    end
                  if (tcnt)
                    insert_txn_count(msg, $sformatf("%0d H2DRSP",tcnt));
                end 
                else begin
                  if (g1.d2hreq_h.req68.val) begin
                    total_d2hreq++;
                    base_tl_ap.write(g1.d2hreq_h);
                    insert_txn_count(msg, "1 D2HREQ");
                  end
                  for (jj=0,tcnt=0; jj<2; jj++)
                    if (g1.d2hrsp_h[jj].rsp68.val) begin
                      total_d2hrsp++;
                      base_tl_ap.write(g1.d2hrsp_h[jj]);
                      tcnt++;
                    end
                  if (tcnt)
                    insert_txn_count(msg, $sformatf("%0d D2HRSP",tcnt));
                end
              end 
        _G2 : begin
                g2_f68 g2;
                if (!$cast(g2, t.slot[ii]))
                  `uvm_fatal(get_type_name, "Invalid $cast to g2") 
                if (g2.dir == H2C) begin
                  if (g2.h2dreq_h.req68.val) begin
                    total_h2dreq++;
                    base_tl_ap.write(g2.h2dreq_h);
                    insert_txn_count(msg, "1 H2DREQ");
                  end
                  if (g2.h2drsp_h.rsp68.val) begin
                    total_h2drsp++;
                    base_tl_ap.write(g2.h2drsp_h);
                    insert_txn_count(msg, "1 H2DRSP");
                  end
                  if (g2.h2ddat_hdr.val) begin
                    // ensure we don't double count splits; 
                    // only incr on first chunk
                    if (hdr_sz || !g2.h2ddat_hdr.ch) begin
                      total_h2ddat++;
                    end
                    cnt_h2ddat_full += hdr_sz;
                    if (!hdr_sz && !g2.h2ddat_hdr.ch) begin
                      cnt_h2ddat_split++;
                    end
                    h2ddat_h[0] = h2ddat_c::type_id::create("h2ddat_h[0]"); 
                    h2ddat_h[0].flitmode = F68;
                    check_queue_full();
                    dat_q.push_back(h2ddat_h[0]);
                    h2ddat_h[0].hdr68 = g2.h2ddat_hdr;
                    h2ddat_h[0].txfer_64B = hdr_sz; 
                    if (!h2ddat_h[0].txfer_64B && h2ddat_h[0].hdr68.ch)
                      dat_chunk_ptr = 2;
                  end
                end 
                else begin
                  if (g2.d2hreq_h.req68.val) begin
                    total_d2hreq++;
                    base_tl_ap.write(g2.d2hreq_h);
                    insert_txn_count(msg, "1 D2HREQ");
                  end
                  if (g2.d2hrsp_h.rsp68.val) begin
                    total_d2hrsp++;
                    base_tl_ap.write(g2.d2hrsp_h);
                    insert_txn_count(msg, "1 D2HRSP");
                  end
                  if (g2.d2hdat_hdr.val) begin
                    // ensure we don't double count splits; 
                    // only incr on first chunk
                    if (hdr_sz || !g2.d2hdat_hdr.ch)
                      total_d2hdat++;
                    if (hdr_sz) begin
                      cnt_d2hdat_be   += hdr_be;
                      cnt_d2hdat_full += !hdr_be;
                    end
                    if (!hdr_sz && !g2.d2hdat_hdr.ch) begin
                      d2hdat_split_ch0_be = hdr_be;
                      if (!d2hdat_split_ch0_be)
                        cnt_d2hdat_split++;
                      else
                        cnt_d2hdat_split_be++;
                    end
                    else if ({!hdr_sz, g2.d2hdat_hdr.ch, !d2hdat_split_ch0_be, hdr_be}) 
                    begin
                      cnt_d2hdat_split--;
                      cnt_d2hdat_split_be++;
                    end
                    d2hdat_h[0] = d2hdat_c::type_id::create("d2hdat_h[0]"); 
                    d2hdat_h[0].flitmode = F68;
                    check_queue_full();
                    dat_q.push_back(d2hdat_h[0]);
                    d2hdat_h[0].hdr68 = g2.d2hdat_hdr;
                    d2hdat_h[0].txfer_64B = hdr_sz;
                    if (d2hdat_h[0].txfer_64B) begin //full cacheline
                      d2hdat_h[0].be = !hdr_be ? '1 : 'x;
                    end
                    else begin  // half cacheline (two chunks); specified by chunk valid (ch)
                      d2hdat_h[0].be[63:32] =  d2hdat_h[0].hdr68.ch && !hdr_be ? '1 : 'x;
                      d2hdat_h[0].be[31: 0] = !d2hdat_h[0].hdr68.ch && !hdr_be ? '1 : 'x;
                      if (d2hdat_h[0].hdr68.ch) 
                        dat_chunk_ptr = 2;
                    end
                  end
                end
              end 
        _G3 : begin
                g3_f68 g3;
                if (!$cast(g3, t.slot[ii]))
                  `uvm_fatal(get_type_name, "Invalid $cast to g3") 
                if (g3.dir == H2C) begin
                  if (g3.h2drsp_h.rsp68.val) begin
                    total_h2drsp++;
                    base_tl_ap.write(g3.h2drsp_h);
                    insert_txn_count(msg, "1 H2DRSP");
                  end
                  // MDH; sz=1 ALWAYS (BE illegal for H2DDAT)
                  if (!hdr_sz || hdr_be) begin
                    `uvm_fatal(get_type_name, "ANY MDH must always have SZ=1 and BE=0")
                  end
                  else if ((g3.h2ddat_hdr.sum with (int'(item.val==1'b1)))<2)
                    `uvm_fatal(get_type_name, "ANY MDH must always have 2 or more valid data headers")
                  for (jj=0; jj<4; jj++) begin
                    if (g3.h2ddat_hdr[jj].val) begin
                      total_h2ddat++;
                      cnt_h2ddat_full++;
                      h2ddat_h[jj] = h2ddat_c::type_id::create($sformatf("h2ddat_h[%0d]",jj)); 
                      h2ddat_h[jj].flitmode = F68;
                      check_queue_full();
                      dat_q.push_back(h2ddat_h[jj]);
                      h2ddat_h[jj].hdr68     = g3.h2ddat_hdr[jj];
                      h2ddat_h[jj].txfer_64B = 1;
                    end
                  end
                end 
                else begin
                  // MDH; sz=1, BE=0 ALWAYS 
                  if (!hdr_sz || hdr_be) begin
                    `uvm_fatal(get_type_name, "ANY MDH must always have SZ=1 and BE=0")
                  end
                  else if ((g3.d2hdat_hdr.sum with (int'(item.val==1'b1)))<2)
                    `uvm_fatal(get_type_name, "ANY MDH must always have 2 or more valid data headers")
                  for (jj=0; jj<4; jj++) begin
                    if (g3.d2hdat_hdr[jj].val) begin
                      total_d2hdat++;
                      cnt_d2hdat_full++;
                      d2hdat_h[jj] = d2hdat_c::type_id::create($sformatf("d2hdat_h[%0d]",jj)); 
                      d2hdat_h[jj].flitmode = F68;
                      check_queue_full();
                      dat_q.push_back(d2hdat_h[jj]);
                      d2hdat_h[jj].hdr68     = g3.d2hdat_hdr[jj];
                      d2hdat_h[jj].txfer_64B = 1;
                      d2hdat_h[jj].be        = '1;
                    end
                  end
                end
              end 
        _G4 : begin
                g4_f68 g4;
                if (!$cast(g4, t.slot[ii]))
                  `uvm_fatal(get_type_name, "Invalid $cast to g4") 
                if (g4.dir == H2C) begin
                  if (g4.m2sreq_h.req68.val) begin
                    total_m2sreq++;
                    base_tl_ap.write(g4.m2sreq_h);
                    insert_txn_count(msg, "1 M2SREQ");
                  end
                  if (g4.h2ddat_hdr.val) begin
                    // ensure we don't double count splits; 
                    // only incr on first chunk
                    if (hdr_sz || !g4.h2ddat_hdr.ch) begin
                      total_h2ddat++;
                    end
                    cnt_h2ddat_full += hdr_sz;
                    if (!hdr_sz && !g4.h2ddat_hdr.ch) begin
                      cnt_h2ddat_split++;
                    end
                    h2ddat_h[0] = h2ddat_c::type_id::create("h2ddat_h[0]"); 
                    h2ddat_h[0].flitmode = F68;
                    check_queue_full();
                    dat_q.push_back(h2ddat_h[0]);
                    h2ddat_h[0].hdr68 = g4.h2ddat_hdr;
                    h2ddat_h[0].txfer_64B = hdr_sz;
                    if (!h2ddat_h[0].txfer_64B && h2ddat_h[0].hdr68.ch)
                      dat_chunk_ptr = 2;
                  end
                end 
                else begin
                  for (jj=0,tcnt=0; jj<2; jj++)
                    if (g4.s2mndr_h[jj].ndr68.val) begin
                      total_s2mndr++;
                      base_tl_ap.write(g4.s2mndr_h[jj]);
                      tcnt++;
                    end
                  if (tcnt) 
                    insert_txn_count(msg, $sformatf("%0d S2MNDR",tcnt));
                  if (g4.s2mdrs_hdr.val) begin
                    s2mdrs_h[0] = s2mdrs_c::type_id::create("s2mdrs_h[0]");
                    s2mdrs_h[0].flitmode = F68;
                    check_queue_full();
                    dat_q.push_back(s2mdrs_h[0]);
                    s2mdrs_h[0].hdr68 = g4.s2mdrs_hdr;
                    s2mdrs_h[0].txfer_64B = hdr_sz;
                    // ensure we don't double count splits; 
                    // only incr on first chunk
                    if (hdr_sz || !s2mdrs_split_ptr)
                      total_s2mdrs++;
                    if (!hdr_sz && !s2mdrs_split_ptr)
                      cnt_s2mdrs_split++;
                    else if (hdr_sz)
                      cnt_s2mdrs_full++;
                    if (!s2mdrs_h[0].txfer_64B) begin
                      s2mdrs_h[0].chunkval = s2mdrs_split_ptr;
                      s2mdrs_split_ptr = !s2mdrs_split_ptr;
                    end
                  end
                end
              end 
        _G5 : begin
                g5_f68 g5;
                if (!$cast(g5, t.slot[ii]))
                  `uvm_fatal(get_type_name, "Invalid $cast to g5") 
                if (g5.dir == H2C) begin
                  if (g5.h2drsp_h.rsp68.val) begin
                    total_h2drsp++;
                    base_tl_ap.write(g5.h2drsp_h);
                    insert_txn_count(msg, "1 H2DRSP");
                  end
                  if (g5.m2srwd_hdr.val) begin
                    total_m2srwd++;
                    m2srwd_h = m2srwd_c::type_id::create("m2srwd_h");
                    m2srwd_h.flitmode = F68;
                    check_queue_full();
                    dat_q.push_back(m2srwd_h);
                    m2srwd_h.hdr68 = g5.m2srwd_hdr;
                    if (!hdr_be) begin
                      m2srwd_h.be = '1;
                      cnt_m2srwd_full++;
                    end
                    else
                      cnt_m2srwd_be++;
                  end
                end 
                else begin
                  for (jj=0,tcnt=0; jj<2; jj++)
                    if (g5.s2mndr_h[jj].ndr68.val) begin
                      total_s2mndr++;
                      base_tl_ap.write(g5.s2mndr_h[jj]);
                      tcnt++;
                    end
                  if (tcnt)
                    insert_txn_count(msg, $sformatf("%0d S2MNDR",tcnt));
                end
              end 
        _G6 : begin
                g6_f68 g6;
                if (!$cast(g6, t.slot[ii]))
                  `uvm_fatal(get_type_name, "Invalid $cast to g6") 
                if (g6.dir == C2H) begin
                  // MDH; sz=1 ALWAYS (BE illegal for S2MDRS)
                  if (!hdr_sz || hdr_be) begin
                    `uvm_fatal(get_type_name, "ANY MDH must always have SZ=1 and BE=0")
                  end
                  else if ((g6.s2mdrs_hdr.sum with (int'(item.val==1'b1)))<2)
                    `uvm_fatal(get_type_name, "ANY MDH must always have 2 or more valid data headers")
                  for (jj=0; jj<3; jj++) begin
                    if (g6.s2mdrs_hdr[jj].val) begin
                      total_s2mdrs++;
                      cnt_s2mdrs_full++;
                      s2mdrs_h[jj] = s2mdrs_c::type_id::create($sformatf("s2mdrs_h[%0d]",jj));
                      s2mdrs_h[jj].flitmode = F68;
                      check_queue_full();
                      dat_q.push_back(s2mdrs_h[jj]);
                      s2mdrs_h[jj].hdr68     = g6.s2mdrs_hdr[jj];
                      s2mdrs_h[jj].txfer_64B = 1;
                    end
                  end
                end 
              end 
        /* Data Slots (Generic) */
        _G0 : begin
                g0_f68 g0;
                if (!$cast(g0, t.slot[ii]))
                  `uvm_fatal(get_type_name, "Invalid $cast to g0") 
                if (dat_q.size == 0) begin
                  `uvm_error(get_type_name, "G0 found without a valid header")
                  return;
                end
                if (g0.dir == H2C) begin
                  if ($cast(h2ddat_h_cur, dat_q[0])) begin
                    h2ddat_h_cur.dat[128*dat_chunk_ptr+:128] = g0.data;
                    if (!h2ddat_h_cur.txfer_64B) begin
                      if (( h2ddat_h_cur.hdr68.ch && dat_chunk_ptr == 3) ||
                          (!h2ddat_h_cur.hdr68.ch && dat_chunk_ptr == 1))
                      begin
                        base_tl_ap.write(h2ddat_h_cur); 
                        dat_chunk_ptr = (h2ddat_h_cur.hdr68.ch && dat_chunk_ptr == 3) ? 0 : 2;
                        void'(dat_q.pop_front());
                        msg = {msg, " (DONE)"};
                      end
                      else
                        dat_chunk_ptr++;
                    end
                    else if (dat_chunk_ptr == 3) begin
                      base_tl_ap.write(h2ddat_h_cur); 
                      dat_chunk_ptr = 0;
                      void'(dat_q.pop_front());
                      msg = {msg, " (DONE)"};
                    end
                    else
                      dat_chunk_ptr++;
                  end
                  else if ($cast(m2srwd_h_cur, dat_q[0])) begin
                    m2srwd_h_cur.dat[128*dat_chunk_ptr+:128] = g0.data;
                    if (dat_chunk_ptr == 3 && m2srwd_h_cur.be !== 'x) begin
                      base_tl_ap.write(m2srwd_h_cur); 
                      dat_chunk_ptr = 0; 
                      void'(dat_q.pop_front());
                      msg = {msg, " (DONE)"};
                    end
                    else begin
                      dat_chunk_ptr++;
                      be_next = 1;
                    end
                  end
                end
                else begin 
                  if ($cast(d2hdat_h_cur, dat_q[0])) begin
                    d2hdat_h_cur.dat[128*dat_chunk_ptr+:128] = g0.data;
                    if (d2hdat_h_cur.txfer_64B) begin
                      if (dat_chunk_ptr == 3 && d2hdat_h_cur.be !== 'x) begin
                        base_tl_ap.write(d2hdat_h_cur);
                        dat_chunk_ptr = 0;
                        void'(dat_q.pop_front());
                        msg = {msg, " (DONE)"};
                      end
                      else begin
                        dat_chunk_ptr++;
                        be_next = 1;
                      end
                    end
                    else if (( d2hdat_h_cur.hdr68.ch && dat_chunk_ptr == 3 && d2hdat_h_cur.be !== 'x) ||
                             (!d2hdat_h_cur.hdr68.ch && dat_chunk_ptr == 1 && d2hdat_h_cur.be !== 'x))
                    begin
                      base_tl_ap.write(d2hdat_h_cur);
                      dat_chunk_ptr = (d2hdat_h_cur.hdr68.ch && dat_chunk_ptr == 3) ? 0 : 2;
                      void'(dat_q.pop_front());
                      msg = {msg, " (DONE)"};
                    end
                    else
                      dat_chunk_ptr++;
                  end
                  else if ($cast(s2mdrs_h_cur, dat_q[0])) begin
                    s2mdrs_h_cur.dat[128*dat_chunk_ptr+:128] = g0.data;
                    if (s2mdrs_h_cur.txfer_64B) begin
                      if (dat_chunk_ptr == 3) begin
                        base_tl_ap.write(s2mdrs_h_cur); 
                        dat_chunk_ptr = 0; 
                        void'(dat_q.pop_front());
                        msg = {msg, " (DONE)"};
                      end
                      else
                        dat_chunk_ptr++;
                    end
                    else if ((!s2mdrs_h_cur.chunkval && dat_chunk_ptr == 1) ||
                             ( s2mdrs_h_cur.chunkval && dat_chunk_ptr == 3))
                    begin
                      base_tl_ap.write(s2mdrs_h_cur); 
                      dat_chunk_ptr = (s2mdrs_h_cur.chunkval && dat_chunk_ptr == 3) ? 0 : 2; 
                      void'(dat_q.pop_front());
                      msg = {msg, " (DONE)"};
                    end
                    else
                      dat_chunk_ptr++;
                  end
                end
              end
        _G0_BE : begin
                g0be_f68 g0_be;
                if (!$cast(g0_be, t.slot[ii]))
                  `uvm_fatal(get_type_name, "Invalid $cast to g0_be") 
                if (g0_be.dir == H2C) begin
                  if($cast(m2srwd_h_cur, dat_q[0])) begin
                    m2srwd_h_cur.be = g0_be.data;
                    base_tl_ap.write(m2srwd_h_cur); 
                    void'(dat_q.pop_front());
                    msg = {msg, " (DONE)"};
                    dat_chunk_ptr = 0; 
                    be_next = 0;
                  end
                end
                else begin
                  if($cast(d2hdat_h_cur, dat_q[0])) begin
                    d2hdat_h_cur.be = g0_be.data;
                    base_tl_ap.write(d2hdat_h_cur); 
                    void'(dat_q.pop_front());
                    msg = {msg, " (DONE)"};
                    dat_chunk_ptr = 0; 
                    be_next = 0;
                  end
                end
              end
      endcase
      `uvm_info("DEBUG", msg, UVM_HIGH)
    end 

    // If we're a slave, tell master what we swallowed so that it can
    // return those credits across the link
    if (is_slave && (t.req_consumed.sum+t.dat_consumed.sum+t.rsp_consumed.sum)) begin
      c = cxl_nfi_credit_txn::type_id::create("c");
      c.req_cred = t.req_consumed;
      c.dat_cred = t.dat_consumed;
      c.rsp_cred = t.rsp_consumed;
      cred_give_ap.write(c);
    end
  endfunction

  virtual function void check_queue_full;
    if (dat_q.size==4 && dat_chunk_ptr==0 && !be_next)
      `uvm_error(get_type_name, "dat_q is already full!")
  endfunction

  // Only header slots and LLCRD flits return credits
  virtual function void extract_credit_returns(slot_base s);
    cxl_nfi_credit_txn t = cxl_nfi_credit_txn::type_id::create("t");
    base_hslot_f68     h;
    llcrd_f68          llcrd;
    if (s._fmt inside {[_H0:_H6]}) begin
      $cast(h, s);
      t.req_cred[h.hdr.reqcrd[3]] = !h.hdr.reqcrd[2:0] ? 0 : 2**(h.hdr.reqcrd[2:0]-1);
      t.dat_cred[h.hdr.datcrd[3]] = !h.hdr.datcrd[2:0] ? 0 : 2**(h.hdr.datcrd[2:0]-1);
      t.rsp_cred[h.hdr.rspcrd[3]] = !h.hdr.rspcrd[2:0] ? 0 : 2**(h.hdr.rspcrd[2:0]-1);
    end
    else begin
      $cast(llcrd, s);
      t.req_cred[llcrd.reqcrd[3]] = !llcrd.reqcrd[2:0] ? 0 : 2**(llcrd.reqcrd[2:0]-1); 
      t.dat_cred[llcrd.datcrd[3]] = !llcrd.datcrd[2:0] ? 0 : 2**(llcrd.datcrd[2:0]-1); 
      t.rsp_cred[llcrd.rspcrd[3]] = !llcrd.rspcrd[2:0] ? 0 : 2**(llcrd.rspcrd[2:0]-1); 
    end
    if ((t.req_cred.sum+t.dat_cred.sum+t.rsp_cred.sum) != 0)
      cred_ret_ap.write(t);
  endfunction

  // Insert s at the end of msg. If msg already is showing txns, then
  // append in a certain away.
  // Ex:
  //   msg = "FOO"; insert_txn_count(msg, $sformatf("3 M2SREQ); -> msg = "FOO (3 M2SREQ)"
  //   msg = "FOO (BAR)"; insert_txn_count(msg, $sformatf("3 M2SREQ); -> msg = "FOO (BAR, 3 M2SREQ)"
  virtual function void insert_txn_count(ref string m, input string s); 
    if (m.getc(m.len-1) == 'd41) //ASCII 41 = ")"
      m = {m.substr(0, m.len-2), ", ", s, ")"}; 
    else
      m = {m, " (", s, ")"};
  endfunction

endclass
