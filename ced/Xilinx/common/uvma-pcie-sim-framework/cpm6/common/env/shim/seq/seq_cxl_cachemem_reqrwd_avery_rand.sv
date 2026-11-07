// Author: -REDACTED-
// Summary: Sequence of CXL.cache and CXL.memory transactions specific to the Avery VIP
// Description: extends the base cxl sequence and adds a convert and send task only.
class seq_cxl_cachemem_reqrwd_avery_rand extends seq_cxl_base;

  `uvm_object_utils(seq_cxl_cachemem_reqrwd_avery_rand)

  // Should be overwritten, but doesn't have to be
  time watchdog_timeout = 1us;
  int timeout_occurred = 0;

  acxl_msg avery_txn_q[$]; // Avery CXL Message queue

  task convert_and_send();

    // Local, generic transaction
    m2sreq_c m2sreq;
    m2srwd_c m2srwd;

    // Local, avery transaction
    acxl_msg m;

    // Final count of transactions that didn't complete (hopefully 0)
    int avery_txn_incomplete_q[$];

    /**************************************************************************/
    // Convert every AMD Transaction in the base class queue to an Avery Transaction
    /**************************************************************************/
    foreach(txn_q[i]) begin
      case(1)
        /*******************************/
        // Read Requests
        /*******************************/
        $cast(m2sreq, txn_q[i]) : begin
          m = acxl_msg::type_id::create("m");
          m.kind                  = ACXL_MSG_m2s_req;
          if(m2sreq.flitmode == F68) begin
            m.u.m2s_req.addr51_5    = m2sreq.req68.addr;
            m.u.m2s_req.ldid        = m2sreq.req68.ldid;
            m.u.m2s_req.tc          = m2sreq.req68.tc;
            m.u.m2s_req.tag         = m2sreq.req68.tag;
            m.u.m2s_req.metaField   = m2sreq.req68.metafield;
            m.u.m2s_req.metaValue   = m2sreq.req68.metavalue;
            m.u.m2s_req.snpType     = m2sreq.req68.snptype;
            m.u.m2s_req.valid       = m2sreq.req68.val;
            m.u.m2s_req.opcode      = m2sreq.req68.memop;
          end
          if(m2sreq.flitmode == F256) begin
            m.u.m2s_req.addr51_5    = {m2sreq.req256.addr, 1'b0};
            m.u.m2s_req.ldid        = m2sreq.req256.ldid;
            m.u.m2s_req.tc          = m2sreq.req256.tc;
            m.u.m2s_req.tag         = m2sreq.req256.tag;
            m.u.m2s_req.metaField   = m2sreq.req256.metafield;
            m.u.m2s_req.metaValue   = m2sreq.req256.metavalue;
            m.u.m2s_req.snpType     = m2sreq.req256.snptype;
            m.u.m2s_req.valid       = m2sreq.req256.val;
            m.u.m2s_req.opcode      = m2sreq.req256.memop;
          end
        end
        /*******************************/
        // Write Requests
        /*******************************/
        $cast(m2srwd, txn_q[i]) : begin
          m = acxl_msg::type_id::create("m");
          m.kind                  = ACXL_MSG_m2s_reqdata;
          if(m2srwd.flitmode == F68) begin
            m.u.m2s_reqdata.trp       = 0; // AMD hdr68 doesn't have a trp field
            m.u.m2s_reqdata.addr51_6  = m2srwd.hdr68.addr;
            m.u.m2s_reqdata.ldid      = m2srwd.hdr68.ldid;
            m.u.m2s_reqdata.tc        = m2srwd.hdr68.tc;
            m.u.m2s_reqdata.tag       = m2srwd.hdr68.tag;
            m.u.m2s_reqdata.metaField = m2srwd.hdr68.metafield;
            m.u.m2s_reqdata.metaValue = m2srwd.hdr68.metavalue;
            m.u.m2s_reqdata.snpType   = m2srwd.hdr68.snptype;
            m.u.m2s_reqdata.poison    = m2srwd.hdr68.poi;
            m.u.m2s_reqdata.valid     = m2srwd.hdr68.val;
            m.u.m2s_reqdata.opcode    = m2srwd.hdr68.memop;
          end
          if(m2srwd.flitmode == F256) begin
            m.u.m2s_reqdata.trp       = m2srwd.hdr256.trp;
            m.u.m2s_reqdata.addr51_6  = m2srwd.hdr256.addr;
            m.u.m2s_reqdata.ldid      = m2srwd.hdr256.ldid;
            m.u.m2s_reqdata.tc        = m2srwd.hdr256.tc;
            m.u.m2s_reqdata.tag       = m2srwd.hdr256.tag;
            m.u.m2s_reqdata.metaField = m2srwd.hdr256.metafield;
            m.u.m2s_reqdata.metaValue = m2srwd.hdr256.metavalue;
            m.u.m2s_reqdata.snpType   = m2srwd.hdr256.snptype;
            m.u.m2s_reqdata.poison    = m2srwd.hdr256.poi;
            m.u.m2s_reqdata.valid     = m2srwd.hdr256.val;
            m.u.m2s_reqdata.opcode    = m2srwd.hdr256.memop;
          end
          // Load the data payload
          m.be          = m2srwd.be;
          m.bytes       = new[64];
          foreach (m.bytes[ii]) begin
            m.bytes[ii] = m2srwd.dat[ii*8+:8];
          end
        end
        /*******************************/
        // Catch enumeration errors...
        /*******************************/
        default : begin
          `uvm_fatal(get_type_name(), "Transaction type is unsupported, must be either M2S_REQ or M2S_RWD!")
        end
      endcase

      /**************************************************************************/
      // Stack onto the Avery-specific transaction queue
      /**************************************************************************/
      avery_txn_q.push_back(m);

    end

    /**************************************************************************/
    // Send all transactions
    /**************************************************************************/
    `uvm_info(get_type_name(), "Sending all transactions...", UVM_NONE)

    foreach(avery_txn_q[i]) begin
      p_sequencer.api.vip.inject_cxl_msg("tx_bypass_coh", avery_txn_q[i], 0);
    end

    /**************************************************************************/
    // Wait for all transactions to complete
    /**************************************************************************/
    `uvm_info(get_type_name(), "Waiting for all transactions to complete...", UVM_NONE)

    fork
      begin
        foreach(avery_txn_q[i]) begin
        `uvm_info(get_type_name(), $sformatf("Waiting for transaction %d to complete...", i), UVM_NONE)
          avery_txn_q[i].wait_done();
        end
        `uvm_info(get_type_name(), "...all transactions sent normally...", UVM_NONE)
      end
      begin
        `uvm_info(get_type_name(), $sformatf("...waiting %t for all transactions to complete...", watchdog_timeout), UVM_NONE)
        // Watchdog timeout here, forces the fork branch to exit if the transactions don't all complete, which is checked below.
        #watchdog_timeout;
        `uvm_info(get_type_name(), "...watchdog wait timeout occurred...", UVM_NONE)
        timeout_occurred = 1;
      end
    join_any // One of the threads above must complete for this statement to be passed

    /**************************************************************************/
    // Check that all transactions have completed...
    /**************************************************************************/
    if(timeout_occurred) begin
      `uvm_fatal(
        get_type_name(),
        $sformatf(
          "%d of %d transactions failed to complete, the first was transaction number %d", 
          avery_txn_q.sum() with (int'(item.is_done == 1'b0)),
          avery_txn_q.size(),
          avery_txn_q.find_first_index() with (item.is_done == 1'b0)
        )
      )
    end else begin
      `uvm_info(get_type_name(), "All transactions completed.", UVM_NONE)
    end

    `uvm_info(get_type_name(), "...Done!", UVM_NONE)

  endtask

endclass
