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
      // Reset the macro to prevent collision
      `undef THISHEADER
      case(1)
        /*******************************/
        // Read Requests
        /*******************************/
        $cast(m2sreq, txn_q[i]) : begin
          m = acxl_msg::type_id::create("m");
          m.kind                  = ACXL_MSG_m2s_req;
          if(m2sreq.flitmode == F68) begin
            `define THISHEADER m2sreq.req68
            m.u.m2s_req.addr51_5    = `THISHEADER.addr;
          end
          if(m2sreq.flitmode == F256) begin
            `define THISHEADER m2sreq.req256
            m.u.m2s_req.addr51_5    = {`THISHEADER.addr, 1'b0};
          end
          m.u.m2s_req.ldid        = `THISHEADER.ldid;
          m.u.m2s_req.tc          = `THISHEADER.tc;
          m.u.m2s_req.tag         = `THISHEADER.tag;
          m.u.m2s_req.metaField   = `THISHEADER.metafield;
          m.u.m2s_req.metaValue   = `THISHEADER.metavalue;
          m.u.m2s_req.snpType     = `THISHEADER.snptype;
          m.u.m2s_req.valid       = `THISHEADER.val;
          // memop and opcode enumeration encodings are the same. Reference:
          // AMD CXL Enumeration: uvma-agents/cxl_nfi_agent/pkg.cxl31_tl_pkg.sv (only supports CXL 3.1)
          // Avery CXL Enumeration: /tools/installs/avery/apciexactor/2025.1_cxl/src/acxl_enum.svh (definitions up through 3.2)
          m.u.m2s_req.opcode      = `THISHEADER.memop;
        end
        /*******************************/
        // Write Requests
        /*******************************/
        $cast(m2srwd, txn_q[i]) : begin
          m = acxl_msg::type_id::create("m");
          m.kind                  = ACXL_MSG_m2s_reqdata;
          if(m2srwd.flitmode == F68) begin
            `define THISHEADER m2srwd.hdr68
            m.u.m2s_reqdata.trp       = 0; // AMD hdr68 doesn't have a trp field
          end
          if(m2srwd.flitmode == F256) begin
            `define THISHEADER m2srwd.hdr256
            m.u.m2s_reqdata.trp       = m2srwd.hdr256.trp;
          end
          m.u.m2s_reqdata.addr51_6  = `THISHEADER.addr;
          m.u.m2s_reqdata.ldid      = `THISHEADER.ldid;
          m.u.m2s_reqdata.tc        = `THISHEADER.tc;
          m.u.m2s_reqdata.tag       = `THISHEADER.tag;
          m.u.m2s_reqdata.metaField = `THISHEADER.metafield;
          m.u.m2s_reqdata.metaValue = `THISHEADER.metavalue;
          m.u.m2s_reqdata.snpType   = `THISHEADER.snptype;
          m.u.m2s_reqdata.poison    = `THISHEADER.poi;
          m.u.m2s_reqdata.valid     = `THISHEADER.val;
          // memop and opcode enumeration encodings are the same. Reference:
          // AMD CXL Enumeration: uvma-agents/cxl_nfi_agent/pkg.cxl31_tl_pkg.sv
          // Avery CXL Enumeration: /tools/installs/avery/apciexactor/2025.1_cxl/src/acxl_enum.svh
          m.u.m2s_reqdata.opcode    = `THISHEADER.memop;
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
