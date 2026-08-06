// flit256_tl_assembler = "256B flit (link layer) to transaction layer assembler"
// Description :
//   Takes in slotsets of data that contain handles to objects and converts them
//   to transaction layer messages and broadcasts those as seen in time order.
class flit256_tl_assembler#(type T) extends uvm_subscriber#(T);

  `uvm_component_param_utils(flit256_tl_assembler#(T)) 

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"flit256_tl_assembler#(",T::type_name,")"};
  virtual function string get_type_name(); return type_name; endfunction

  bit is_slave;

  uvm_analysis_port#(base_txn)       base_llc_ap; 
  uvm_analysis_port#(base_txn)       base_tl_ap; 
  uvm_analysis_port#(cxl_nfi_credit_txn) cred_ret_ap; 
  uvm_analysis_port#(cxl_nfi_credit_txn) cred_give_ap; 

  flit_mode_t flitmode;
  bit [1:0]   ssptr;

  uvm_event init_param_rcvd;

  // Need to build data messages over multiple slots per flit and even between 
  // multiple flits (need persistence). Also need to keep track of data ordering
  // as it comes in.  To do so, we'll use a bounded queue (size 4) and push handles
  // onto it, then retrieve and cast, popping when that data message is complete.
  base_txn  dat_q[$:7];
  bit [1:0] dat_chunk_ptr = 'd0;
  h2ddat_c  h2ddat_h[3:0], h2ddat_h_cur; 
  d2hdat_c  d2hdat_h[3:0], d2hdat_h_cur;
  m2srwd_c  m2srwd_h,      m2srwd_h_cur;
  s2mdrs_c  s2mdrs_h[2:0], s2mdrs_h_cur;

  logic [ 0:2] s2mdrs_trp_sav[$:5]; //to help identify when/what to pop
  logic [31:0] s2mdrs_trailer[$:2]; //can have up to two trailers LEAD their data

  function new(string name, uvm_component parent);
    super.new(name, parent);
    base_llc_ap  = new("base_llc_ap", this);
    base_tl_ap   = new("base_tl_ap", this);
    cred_ret_ap  = new("cred_ret_ap", this);
    cred_give_ap = new("cred_give_ap", this);
  endfunction

  virtual function void write(T t);
    string             msg, fmt, ofmt;
    bit                rsvd_now; //some LLCMs have subsequent slots as reserved
    bit [3:0]          slotnum;
    int                ii;
    cxl_nfi_credit_txn c;
    // Loop over each slot of slotset
    for (ii=0,slotnum=(ssptr++)*4; ii<4; ii++,slotnum++) begin
      // Debug printing
      fmt = t.slot[ii]._fmt.name;
      if (fmt.getc(1) == "D")
        ofmt = "DATA";
      else if (fmt.getc(1) == "T")
        ofmt = "TRAILER";
      else if (slotnum==15)
        ofmt = flitmode==F256_LOPT ? "PHY_HSCONT" : "PHY";
      else if (slotnum==8 && flitmode==F256_LOPT) begin
        ofmt = {"HS", (fmt.getc(fmt.len-2)=="M") ? fmt.substr(fmt.len-1, fmt.len-1) : 
                                                   fmt.substr(fmt.len-2, fmt.len-1)}; 
        if (ofmt == "HS8")      ofmt = "HS8 (LLCTRL)";
        else if (ofmt == "HS9") ofmt = "HS9 (RSVD)";
      end
      else if (fmt.getc(fmt.len-2)=="M") begin //_HBR_M[0-9]
        ofmt = string'({!slotnum ? "H":"G", fmt.getc(fmt.len-1)});
        if (ofmt == "H8")                       ofmt = "H8 (LLCTRL)";
        else if (ofmt.getc(1) inside {"8","9"}) ofmt = {ofmt, " (RSVD)"};
      end
      else begin //_HBR_M[10-15]
        ofmt = {!slotnum ? "H":"G", fmt.substr(fmt.len-2, fmt.len-1)};
        if (ofmt.getc(2) inside {"0","1"}) ofmt = {ofmt, " (RSVD)"};
      end
      msg = $sformatf("Slot %0d = %0s", slotnum, ofmt);
      if (t.slot[ii].dat_consumed[MEM]) 
        msg = {msg, $sformatf(" (M HDR:%0d)", t.slot[ii].dat_consumed[MEM])};  
      else if (t.slot[ii].dat_consumed[CCH])
        msg = {msg, $sformatf(" ($ HDR:%0d)", t.slot[ii].dat_consumed[CCH])};  
      if (dat_q.size) begin
        msg = {msg, $sformatf(", dat_q.size = %0d, dat_chunk_ptr = %0d", dat_q.size, dat_chunk_ptr)};
      end
      // An LLCM message has been received and all slots should be reserved
      if (rsvd_now && t.slot[ii].slot_num!=15 && |t.slot[ii].data)  
        `uvm_error(get_type_name, $sformatf("A LLCM was rcvd and subsequent slot %0d was not reserved", 
                                  t.slot[ii].slot_num));
      // Parse through each slot now
      case (t.slot[ii]._fmt) 
        _S15_PHY : begin
                     cxl_nfi_credit_txn crd = cxl_nfi_credit_txn::type_id::create("crd");
                     for (int jj=0; jj<2; jj++) begin
                       crd.req_cred[jj] = -1*t.slot[ii].req_consumed[jj]; 
                       crd.dat_cred[jj] = -1*t.slot[ii].dat_consumed[jj]; 
                       crd.rsp_cred[jj] = -1*t.slot[ii].rsp_consumed[jj]; 
                     end
                     if ((crd.req_cred.sum+crd.dat_cred.sum+crd.rsp_cred.sum) != 0)
                       cred_ret_ap.write(crd);
                   end 
        _D       : begin
                     if ($cast(h2ddat_h_cur, dat_q[0])) begin
                       h2ddat_h_cur.dat[128*dat_chunk_ptr+:128] = t.slot[ii].data;
                       if (dat_chunk_ptr == 3) begin
                         base_tl_ap.write(h2ddat_h_cur);
                         void'(dat_q.pop_front());
                         msg = {msg, ", ($ DONE)"};
                         dat_chunk_ptr = 0;
                       end
                       else
                         dat_chunk_ptr++;
                     end
                     else if ($cast(m2srwd_h_cur, dat_q[0])) begin
                       m2srwd_h_cur.dat[128*dat_chunk_ptr+:128] = t.slot[ii].data;
                       if (!m2srwd_h_cur.hdr256.trp && dat_chunk_ptr==3) begin
                         m2srwd_h_cur.be = '1; //implied
                         base_tl_ap.write(m2srwd_h_cur);
                         void'(dat_q.pop_front());
                         msg = {msg, ", (M DONE)"};
                         dat_chunk_ptr = 0;
                       end
                       else
                         dat_chunk_ptr++;
                     end
                     else if ($cast(d2hdat_h_cur, dat_q[0])) begin
                       d2hdat_h_cur.dat[128*dat_chunk_ptr+:128] = t.slot[ii].data;
                       if (!d2hdat_h_cur.hdr256.bep && dat_chunk_ptr == 3) begin
                         d2hdat_h_cur.be = '1; //implied
                         base_tl_ap.write(d2hdat_h_cur);
                         void'(dat_q.pop_front());
                         msg = {msg, ", ($ DONE)"};
                         dat_chunk_ptr = 0;
                       end
                       else
                         dat_chunk_ptr++;
                     end
                     else if ($cast(s2mdrs_h_cur, dat_q[0])) begin
                       s2mdrs_h_cur.dat[128*dat_chunk_ptr+:128] = t.slot[ii].data;
                       // trailer is coming
                       if (dat_chunk_ptr==3 && $countones(s2mdrs_trp_sav[0]))
                         dat_chunk_ptr++;
                       // no trailer or we already got it
                       else if (dat_chunk_ptr==3) begin
                         if (s2mdrs_trailer.size)
                           s2mdrs_h_cur.emd = s2mdrs_trailer.pop_front;
                         base_tl_ap.write(s2mdrs_h_cur);
                         void'(dat_q.pop_front);
                         void'(s2mdrs_trp_sav.pop_front);
                         msg = {msg, ", (M DONE)"};
                         dat_chunk_ptr = 0;
                       end
                       else
                         dat_chunk_ptr++;
                     end
                   end 
        _T       : begin
                     if ($cast(m2srwd_h_cur, dat_q[0])) begin
                       if (m2srwd_h_cur.hdr256.memop inside {MemWrPtl, MemWrPtlTEE}) begin
                         m2srwd_h_cur.be[31: 0] = t.slot[ii].data.trp.m2srwd.trailer0;
                         m2srwd_h_cur.be[63:32] = t.slot[ii].data.trp.m2srwd.trailer1;
                         if (m2srwd_h_cur.hdr256.metafield == ExtMetaState) begin
                           m2srwd_h_cur.emd = t.slot[ii].data.trp.m2srwd.trailer2;
                         end
                       end
                       else if (m2srwd_h_cur.hdr256.metafield == ExtMetaState) begin
                         m2srwd_h_cur.be  = '1; //implied
                         m2srwd_h_cur.emd = t.slot[ii].data.trp.m2srwd.trailer0;
                       end
                       base_tl_ap.write(m2srwd_h_cur);
                       void'(dat_q.pop_front());
                       msg = {msg, ", (M DONE)"};
                     end
                     else if ($cast(d2hdat_h_cur, dat_q[0])) begin
                       d2hdat_h_cur.be = t.slot[ii].data.trp.d2hdh.be;
                       base_tl_ap.write(d2hdat_h_cur);
                       void'(dat_q.pop_front());
                       msg = {msg, ", ($ DONE)"};
                     end
                     else if ($cast(s2mdrs_h_cur, dat_q[0])) begin
                       case (s2mdrs_trp_sav.pop_front) inside
                         // 3 txns: 1 emd
                         3'b100 : begin
                                    s2mdrs_h_cur.emd = t.slot[ii].data[0+:32];
                                    s2mdrs_trailer.push_back('x);
                                    s2mdrs_trailer.push_back('x);
                                  end
                         3'b010 : begin
                                    s2mdrs_trailer.push_back(t.slot[ii].data[0+:32]);
                                    s2mdrs_trailer.push_back('x);
                                  end
                         3'b001 : begin
                                    s2mdrs_trailer.push_back('x);
                                    s2mdrs_trailer.push_back(t.slot[ii].data[0+:32]);
                                  end
                         // 3 txns: 2 emd
                         3'b110 : begin
                                    s2mdrs_h_cur.emd = t.slot[ii].data[0+:32];
                                    s2mdrs_trailer.push_back(t.slot[ii].data[32+:32]);
                                    s2mdrs_trailer.push_back('x);
                                  end
                         3'b101 : begin
                                    s2mdrs_h_cur.emd = t.slot[ii].data[0+:32];
                                    s2mdrs_trailer.push_back('x);
                                    s2mdrs_trailer.push_back(t.slot[ii].data[32+:32]);
                                  end
                         3'b011 : begin
                                    s2mdrs_trailer.push_back(t.slot[ii].data[ 0+:32]);
                                    s2mdrs_trailer.push_back(t.slot[ii].data[32+:32]);
                                  end
                         // 3 txns: 3 emd
                         3'b111 : begin
                                    s2mdrs_h_cur.emd = t.slot[ii].data[0+:32];
                                    s2mdrs_trailer.push_back(t.slot[ii].data[32+:32]);
                                    s2mdrs_trailer.push_back(t.slot[ii].data[64+:32]);
                                  end
                         // 2 txns: 1 emd
                         3'b10? : begin
                                    s2mdrs_h_cur.emd = t.slot[ii].data[0 +:32];
                                    s2mdrs_trailer.push_back('x);
                                  end
                         3'b01? : begin
                                    s2mdrs_trailer.push_back(t.slot[ii].data[0 +:32]);
                                  end
                         // 2 txns: 2 emd
                         3'b11? : begin
                                    s2mdrs_h_cur.emd = t.slot[ii].data[0+:32];
                                    s2mdrs_trailer.push_back(t.slot[ii].data[32+:32]);
                                  end
                         // 1 txn: 1 emd
                         3'b1?? : begin
                                    s2mdrs_h_cur.emd = t.slot[ii].data[0 +:32];
                                  end
                       endcase
                       // We waited to pop off the last txn until this trailer, 
                       // whether it specifically had a trp or not
                       base_tl_ap.write(s2mdrs_h_cur);
                       void'(dat_q.pop_front());
                       msg = {msg, ", (M DONE)"};
                     end
                   end 
        _HBR_M0  : begin
                     m0_hbr m0;
                     $cast(m0, t.slot[ii]);
                     if (m0.h2dreq_h.req256.val) 
                       base_tl_ap.write(m0.h2dreq_h);
                     if (m0.is_gslot) 
                       if (m0.h2drsp_h.rsp256.val) 
                         base_tl_ap.write(m0.h2drsp_h);
                   end 
        _HBR_M1  : begin
                     m1_hbr m1;
                     $cast(m1, t.slot[ii]);
                     if (m1.h2drsp_h[0].rsp256.val) 
                       base_tl_ap.write(m1.h2drsp_h[0]);
                     if (m1.h2drsp_h[1].rsp256.val) 
                       base_tl_ap.write(m1.h2drsp_h[1]);
                     if (m1.is_gslot)
                       if (m1.h2drsp_h[2].rsp256.val) 
                         base_tl_ap.write(m1.h2drsp_h[2]);
                   end 
        _HBR_M2  : begin
                     m2_hbr m2;
                     $cast(m2, t.slot[ii]);
                     if (m2.d2hreq_h.req256.val) 
                       base_tl_ap.write(m2.d2hreq_h);
                     if (m2.is_hslot || m2.is_gslot)
                       if (m2.d2hrsp_h[0].rsp256.val) 
                         base_tl_ap.write(m2.d2hrsp_h[0]);
                     if (m2.is_gslot)
                       if (m2.d2hrsp_h[1].rsp256.val) 
                         base_tl_ap.write(m2.d2hrsp_h[1]);
                   end 
        _HBR_M3  : begin
                     m3_hbr m3;
                     $cast(m3, t.slot[ii]);
                     if (m3.d2hrsp_h[0].rsp256.val) 
                       base_tl_ap.write(m3.d2hrsp_h[0]);
                     if (m3.d2hrsp_h[1].rsp256.val) 
                       base_tl_ap.write(m3.d2hrsp_h[1]);
                     if (m3.d2hrsp_h[2].rsp256.val) 
                       base_tl_ap.write(m3.d2hrsp_h[2]);
                     if (m3.is_hslot || m3.is_gslot)
                       if (m3.d2hrsp_h[3].rsp256.val) 
                         base_tl_ap.write(m3.d2hrsp_h[3]);
                   end 
        _HBR_M4  : begin
                     m4_hbr m4;
                     $cast(m4, t.slot[ii]);
                     if (m4.m2sreq_h.req256.val) 
                       base_tl_ap.write(m4.m2sreq_h);
                   end 
        _HBR_M5  : begin
                     m5_hbr m5;
                     $cast(m5, t.slot[ii]);
                     if (m5.m2sbirsp_h[0].birsp256.val) 
                       base_tl_ap.write(m5.m2sbirsp_h[0]);
                     if (m5.m2sbirsp_h[1].birsp256.val) 
                       base_tl_ap.write(m5.m2sbirsp_h[1]);
                     if (m5.is_gslot) 
                       if (m5.m2sbirsp_h[2].birsp256.val) 
                         base_tl_ap.write(m5.m2sbirsp_h[2]);
                   end 
        _HBR_M6  : begin
                     m6_hbr m6;
                     $cast(m6, t.slot[ii]);
                     if (m6.s2mbisnp_h.bisnp256.val) 
                       base_tl_ap.write(m6.s2mbisnp_h);
                     if (m6.is_gslot)
                       if (m6.s2mndr_h.ndr256.val) 
                         base_tl_ap.write(m6.s2mndr_h);
                   end 
        _HBR_M7  : begin
                     m7_hbr m7;
                     $cast(m7, t.slot[ii]);
                     if (m7.s2mndr_h[0].ndr256.val) 
                       base_tl_ap.write(m7.s2mndr_h[0]);
                     if (m7.s2mndr_h[1].ndr256.val) 
                       base_tl_ap.write(m7.s2mndr_h[1]);
                     if (m7.is_gslot)
                       if (m7.s2mndr_h[2].ndr256.val) 
                         base_tl_ap.write(m7.s2mndr_h[2]);
                   end 
        _HBR_M8  : begin
                     m8_hbr m8;
                     $cast(m8, t.slot[ii]);
                     base_llc_ap.write(m8);
                     if (init_param_rcvd != null &&
                         m8.data.llcm.llctrl==INIT_F256 && 
                         m8.data.llcm.subtype==8)
                     begin
                       init_param_rcvd.trigger;
                     end
                     rsvd_now = (m8.data.llcm.llctrl==IDE_F256 &&
                                 m8.data.llcm.subtype==4'h3);
                   end 
        _HBR_M9  : /*rsvd*/;
        _HBR_M10 : /*rsvd*/;
        _HBR_M11 : /*rsvd*/;
        _HBR_M12 : begin
                     m12_hbr m12;
                     $cast(m12, t.slot[ii]);
                     if (m12.h2ddat_h[0].hdr256.val)
                       dat_q.push_back(m12.h2ddat_h[0]);
                     if (m12.h2ddat_h[1].hdr256.val)
                       dat_q.push_back(m12.h2ddat_h[1]);
                     if (m12.h2ddat_h[2].hdr256.val)
                       dat_q.push_back(m12.h2ddat_h[2]);
                     if (m12.is_gslot)
                       if (m12.h2ddat_h[3].hdr256.val)
                         dat_q.push_back(m12.h2ddat_h[3]);
                   end 
        _HBR_M13 : begin
                     m13_hbr m13;
                     $cast(m13, t.slot[ii]);
                     if (m13.d2hdat_h[0].hdr256.val)
                       dat_q.push_back(m13.d2hdat_h[0]);
                     if (m13.d2hdat_h[1].hdr256.val)
                       dat_q.push_back(m13.d2hdat_h[1]);
                     if (m13.d2hdat_h[2].hdr256.val)
                       dat_q.push_back(m13.d2hdat_h[2]);
                     if (m13.is_hslot || m13.is_gslot)
                       if (m13.d2hdat_h[3].hdr256.val)
                         dat_q.push_back(m13.d2hdat_h[3]);
                   end 
        _HBR_M14 : begin
                     m14_hbr m14;
                     $cast(m14, t.slot[ii]);
                     if (m14.m2srwd_h.hdr256.val)
                       dat_q.push_back(m14.m2srwd_h);
                   end 
        _HBR_M15 : begin
                     m15_hbr     m15;
                     logic [0:2] trps;
                     $cast(m15, t.slot[ii]);
                     trps[0] = m15.s2mdrs_h[0].hdr256.val ? m15.s2mdrs_h[0].hdr256.trp : 1'bz;
                     trps[1] = m15.s2mdrs_h[1].hdr256.val ? m15.s2mdrs_h[1].hdr256.trp : 1'bz;
                     trps[2] = m15.is_gslot && m15.s2mdrs_h[2].hdr256.val ? 
                                   m15.s2mdrs_h[2].hdr256.trp : 1'bz;
                     if (m15.s2mdrs_h[0].hdr256.val) begin
                       dat_q.push_back(m15.s2mdrs_h[0]);
                       s2mdrs_trp_sav.push_back(trps);
                     end
                     if (m15.s2mdrs_h[1].hdr256.val) begin
                       dat_q.push_back(m15.s2mdrs_h[1]);
                       s2mdrs_trp_sav.push_back('z);
                     end 
                     if (m15.is_gslot && m15.s2mdrs_h[2].hdr256.val) begin
                       dat_q.push_back(m15.s2mdrs_h[2]);
                       s2mdrs_trp_sav.push_back('z);
                     end 
                   end 
        default  : `uvm_error(get_type_name, $sformatf("Slot %0d : unexpected slot fmt = %0s", ii, fmt))
      endcase
      
    end //for loop; each slot of slotset

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

endclass
