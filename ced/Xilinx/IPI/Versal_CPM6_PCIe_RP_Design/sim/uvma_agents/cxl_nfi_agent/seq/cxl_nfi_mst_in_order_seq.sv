// This sequence is designed such that it will wait to pop flit txns off the 
// queue until there are credits available for it or a certain amount of time.
// It is assumed that the user wants to send a set of flits in a specific order. 
// A user must populate the flit_q before starting the sequence on the sequencer. 
// This sequence handles sending multiples of flits (68B mode) or subset of flits
// (256B mode) in a clock cycle. 
class cxl_nfi_mst_in_order_seq#(parameter NFI_W=3) extends cxl_nfi_mst_base_seq#(NFI_W);

  `uvm_object_param_utils(cxl_nfi_mst_in_order_seq#(NFI_W))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("cxl_nfi_mst_in_order_seq#(%0d)",NFI_W);
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name = "cxl_nfi_mst_in_order_seq");
    super.new(name);
  endfunction

  // These are per NFI txn (per clock cycle) trackers to make sure
  // we don't overflow when sending due to having enough credits to
  // send N of M slotsets, but not M of M, because credits are 
  // decremented when the NFI txn is sent, not when allocated here.
  int txn_req_consumed[1:0];
  int txn_dat_consumed[1:0];
  int txn_rsp_consumed[1:0];

  virtual task body();
    // Exit if flit_q hasn't been populated
    if (!flit_q.size) begin
      `uvm_warning(get_type_name, "Sequence called when there are no flits to send")
      return;
    end
    // Drain the flit_q
    case (p_sequencer.cfg.flitmode) inside
      F68                   : send_all_flit68;
      F256, F256_LOPT, FPBR : send_all_flit256;
      default : `uvm_fatal(get_type_name, $sformatf("Sequence does not support %0s flitmode", p_sequencer.cfg.flitmode.name))
    endcase

  endtask

  // Check if the queue's head consumes more credits than are available
  // 1 means we have enough credits to send, 0 means we don't
  virtual function bit have_q_head_credits();
    return ((flit_q[0].req_consumed[0] <= (p_sequencer.shr.avl_req_credit[0]-txn_req_consumed[0])) &&
            (flit_q[0].req_consumed[1] <= (p_sequencer.shr.avl_req_credit[1]-txn_req_consumed[1])) &&
            (flit_q[0].dat_consumed[0] <= (p_sequencer.shr.avl_dat_credit[0]-txn_dat_consumed[0])) &&
            (flit_q[0].dat_consumed[1] <= (p_sequencer.shr.avl_dat_credit[1]-txn_dat_consumed[1])) &&
            (flit_q[0].rsp_consumed[0] <= (p_sequencer.shr.avl_rsp_credit[0]-txn_rsp_consumed[0])) &&
            (flit_q[0].rsp_consumed[1] <= (p_sequencer.shr.avl_rsp_credit[1]-txn_rsp_consumed[1])));
  endfunction

  virtual task send_all_flit68();
    flit68_txn          f68;
    cxl_nfi_txn#(NFI_W) txn;
    // Send transactions until entire flit_q is empty
    while(flit_q.size) begin
      txn = cxl_nfi_txn#(NFI_W)::type_id::create("txn"); 
      start_item(txn);
      // Initialize
      txn_req_consumed = '{default: 0};
      txn_dat_consumed = '{default: 0};
      txn_rsp_consumed = '{default: 0};
      // Iterate over the entire NFI interface one-by-one (flits)
      for (int ii=0; ii<NFI_W; ii++) begin
        if (!flit_q.size) begin
          txn.data[ii]     = '0;
          txn.parity[ii]   = '0;
          txn.adf[ii]      = 1'b0;
          txn.last[ii]     = 1'b0;
          txn.valid[ii]    = 1'b0;
          txn.viral[ii]    = 1'b0;
          txn.dec_sop[ii]  = 4'h0;
          txn.dec_eop[ii]  = 4'h0;
          txn.dec_be[ii]   = 4'h0;
          txn.dec_mem[ii]  = 4'h0;
        end
        else begin
          // A gap marker will zero out the rest of the NFI
          if (flit_q[0].gap) begin 
            txn.data[ii]     = '0;
            txn.parity[ii]   = '0;
            txn.adf[ii]      = '0;
            txn.last[ii]     = '0;
            txn.viral[ii]    = '0;
            txn.valid[ii]    = '0;
            txn.dec_sop[ii]  = '0;
            txn.dec_eop[ii]  = '0;
            txn.dec_be[ii]   = '0;
            txn.dec_mem[ii]  = '0;
            if (ii==(NFI_W-1)) void'(flit_q.pop_front);
          end
          else begin
            // wait 100 cycles for credits
            if (!ignore_avail_credits) wait_for_credits(100);
            // pop it and send it
            $cast(f68, flit_q.pop_front);
            txn.data[ii]     = f68.flit;
            txn.parity[ii]   = f68.parity;
            txn.adf[ii]      = f68.adf;
            txn.last[ii]     = f68.last;
            txn.viral[ii]    = f68.viral;
            txn.valid[ii]    = f68.valid;
            txn.dec_sop[ii]  = f68.dec_sop;
            txn.dec_eop[ii]  = f68.dec_eop;
            txn.dec_be[ii]   = f68.dec_be;
            txn.dec_mem[ii]  = f68.dec_mem;
            // Copy credits consumed over
            txn.req_consumed[ii] = f68.req_consumed;
            txn.dat_consumed[ii] = f68.dat_consumed;
            txn.rsp_consumed[ii] = f68.rsp_consumed;
            // Per NFI txn tracking
            txn_req_consumed[1] += f68.req_consumed[1];
            txn_req_consumed[0] += f68.req_consumed[0];
            txn_dat_consumed[1] += f68.dat_consumed[1];
            txn_dat_consumed[0] += f68.dat_consumed[0];
            txn_rsp_consumed[1] += f68.rsp_consumed[1];
            txn_rsp_consumed[0] += f68.rsp_consumed[0];
          end
        end
      end
      finish_item(txn);
    end
  endtask

  virtual task send_all_flit256();
    flit256_txn         f256;
    cxl_nfi_txn#(NFI_W) txn;
    int                 ptr;
    // Send transactions until entire flit_q is empty and all
    // slotsets have been sent. A flit will always take more 
    // than one NFI cycle to completely send it. 
    while(flit_q.size || ptr) begin
      txn = cxl_nfi_txn#(NFI_W)::type_id::create("txn"); 
      start_item(txn);
      // These fields unused in 256B flit mode
      {txn.last, txn.adf} = '0;
      // Initialize
      txn_req_consumed = '{default: 0};
      txn_dat_consumed = '{default: 0};
      txn_rsp_consumed = '{default: 0};
      // Iterate over the entire NFI interface one-by-one (slotset)
      for (int ii=0; ii<NFI_W; ii++) begin
        // NFI3 needs to be able to handle invalid upper slotsets 
        if (!flit_q.size && ptr==4) begin
          txn.data[ii]     = '0;
          txn.parity[ii]   = '0;
          txn.valid[ii]    = '0;
          txn.viral[ii]    = '0;
          txn.dec_sop[ii]  = '0;
          txn.dec_eop[ii]  = '0;
          txn.dec_be[ii]   = '0;
          txn.dec_mem[ii]  = '0;
        end
        // A gap marker will zero out the rest of the NFI
        else if (flit_q.size && flit_q[0].gap) begin
          txn.data[ii]     = '0;
          txn.parity[ii]   = '0;
          txn.valid[ii]    = '0;
          txn.viral[ii]    = '0;
          txn.dec_sop[ii]  = '0;
          txn.dec_eop[ii]  = '0;
          txn.dec_be[ii]   = '0;
          txn.dec_mem[ii]  = '0;
          if (ii==(NFI_W-1)) void'(flit_q.pop_front);
        end
        else begin
          if (ptr inside {0,4}) begin
            // wait 100 cycles for credits
            if (!ignore_avail_credits) wait_for_credits(100);
            // pop it and start sending it
            $cast(f256, flit_q.pop_front);
            ptr = 0;
          end
          txn.data[ii]     = f256.slotset[ptr].data;
          txn.parity[ii]   = f256.slotset[ptr].parity;
          txn.viral[ii]    = f256.slotset[ptr].viral;
          txn.valid[ii]    = f256.slotset[ptr].valid;
          txn.dec_sop[ii]  = f256.slotset[ptr].dec_sop;
          txn.dec_eop[ii]  = f256.slotset[ptr].dec_eop;
          txn.dec_be[ii]   = f256.slotset[ptr].dec_be;
          txn.dec_mem[ii]  = f256.slotset[ptr].dec_mem;
          // Copy credits consumed over from each slotset
          txn.req_consumed[ii] = f256.slotset[ptr].req_consumed;
          txn.dat_consumed[ii] = f256.slotset[ptr].dat_consumed;
          txn.rsp_consumed[ii] = f256.slotset[ptr].rsp_consumed;
          // Per NFI txn tracking
          txn_req_consumed[1] += f256.slotset[ptr].req_consumed[1];
          txn_req_consumed[0] += f256.slotset[ptr].req_consumed[0];
          txn_dat_consumed[1] += f256.slotset[ptr].dat_consumed[1];
          txn_dat_consumed[0] += f256.slotset[ptr].dat_consumed[0];
          txn_rsp_consumed[1] += f256.slotset[ptr].rsp_consumed[1];
          txn_rsp_consumed[0] += f256.slotset[ptr].rsp_consumed[0];
          ptr++;
        end
      end
      ptr = ptr%4;
      finish_item(txn);
    end
  endtask

  virtual task wait_for_credits(int wait_to);
    int    waits;
    string str;
    // If there aren't enough credits available at head of queue, pause 
    // and don't send any flits. If credits don't become available, we'll
    // still issue the txn, but issue a warning.
    waits = 0;
    while (!have_q_head_credits) begin
      p_sequencer.wait_cycles(1);
      waits++;
      if (waits==wait_to) begin
        str = $sformatf("Waited for credits to send a flit for %0d cycles;",wait_to);
        str = {str, " sent it without credits"};
        `uvm_warning(get_type_name, str)
        break;
      end
    end
  endtask

endclass
