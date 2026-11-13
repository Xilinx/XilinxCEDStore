// Summary: Sequence of CXL.cache and CXL.memory transactions.
// Description: written for both CXL.cache and CXL.mem transactions, currently restricted to CXL.mem.
//    Initial Controls in the sequence include:
//      - Total number of transactions to send
//      - Rd/Wr distribution (0/100, 50/50, 100/0, etc)
//      - Delay distribution between TLPs
//      - Address range(s)
//      - Distribution of partial Wrs (writes with byte enables)
//      - Enablement of extended meta data (EMD)
//    Refer to CXL spec Appendix C.2 and C.4 for valid request/response combinations for CXL.mem 
class seq_cxl_base extends vseq_base;

  `uvm_object_utils(seq_cxl_base)

  // REQUIRED
  int txn_total;
  struct packed {
    bit cache;  // Disable ALL cxl.cache Ops
    bit mem;    // Disable ALL cxl.mem Ops
    bit inv;    // Disable Inversion Ops
    bit spec;   // Disable Speculative Ops
    bit tee;    // Disable Trusted Execution Environment Ops
  } dis_ops_flags;

  // OPTIONAL
  struct packed {
    int m2s_req;
    int m2s_rwd;
    int m2s_birsp;
    int h2d_req;
    int h2d_dat;
    int h2d_rsp;
  } odds; // If unset, defaults to even-weight of odds

  pcie_device pdev; // Tied from the test, the sequence will discover the HDM regions

  flit_mode_t flitmode;

  typedef enum {M2SREQ, M2SRWD} tt_types;
  rand tt_types r_tt[$];
  rand bit [15:0] r_tag[$];
  rand bit r_hdm_select[$];

  int unsigned count_m2sreq = 0;
  int unsigned count_m2srwd = 0;

  // The storage queue of randomized transactions
  base_txn txn_q[$];

  constraint c_txn_type {
    r_tt.size() == txn_total;

    foreach(r_tt[i]){
      r_tt[i] dist {
        M2SREQ := odds.m2s_req,
        M2SRWD := odds.m2s_rwd
      };
    }
  }

  constraint c_tag {
    r_tag.size() == txn_total;

    // Make sure the tags are all unique
    unique { r_tag };
  }

  constraint c_hdm {
    r_hdm_select.size() == txn_total;

    // If only one HDM region is active, keep the select limited
    foreach(r_hdm_select[i]){
      (pdev.cxl_hdm.size() == 1) -> r_hdm_select[i] == 0;
    }
  }

  function new(string name = get_type_name());
    super.new(name);
  endfunction

  function void pre_randomize();                                                                                                                                                                                                                            
    // Check that the pdev handle is set to something before randomization...
    if(pdev == null) begin
      `uvm_fatal(get_type_name(), "The pdev handle must be tied to the EP object.")
    end

    // Check that one of the constraint disable flags is set
    if ($bits(dis_ops_flags)'(dis_ops_flags) == 0) begin
      dis_ops_flags = {$bits(dis_ops_flags){1'b1}}; // Disable all "extra" operations
      dis_ops_flags.cache = 1'b0;
      dis_ops_flags.mem = 1'b0;
    end

    // Handle if the odds struct is not set to anything which will throw an error
    // and evenly distribute odds...
    if ($bits(odds)'(odds) == 0) begin
      odds = {$bits(odds){1}}; // Equal weight of odds for all types
    end
  endfunction 

  virtual task body();

    flitmode = p_sequencer.flitmode;

    `uvm_info(get_type_name(), "body begin...", UVM_NONE)

    // Initially randomize this sequence
    this.randomize;

    `uvm_info(get_type_name(), $sformatf("Total transaction count %d", r_tt.size()), UVM_NONE)

    // Build the generic transaction queue...
    foreach(r_tt[i]) begin
      spawn_generic_transaction(r_tt[i], r_tag[i], r_hdm_select[i]);
    end

    `uvm_info(get_type_name(), $sformatf("Total M2SREQ count %0d", count_m2sreq), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("Total M2SRWD count %0d", count_m2srwd), UVM_NONE)

    convert_and_send(); // Virtual task, must be overwritten in the extended class

    `uvm_info(get_type_name(), "...body end", UVM_NONE)

  endtask

  virtual task spawn_generic_transaction(tt_types this_tt, bit[15:0] this_tag, bit this_hdm);

    //      this is C.2 and C.4 table stuffs.
    //      There is an EMD bit that comes out on the PL which could be monitored.
    //
    //      Set the constraint_mode to turn on EMD fields.
    //      txn.c_noemd.constraint_mode(0);
    //      Set the constraint_mode to turn off EMD fields.
    //      txn.c_noemd.constraint_mode(1);

    // Local, single address range
    bit [63:0] c_upper_addr = pdev.cxl_hdm[this_hdm].base + pdev.cxl_hdm[this_hdm].sz - 1;
    bit [63:0] c_lower_addr = pdev.cxl_hdm[this_hdm].base;

    // Local, single transaction
    m2sreq_c m2sreq = m2sreq_c::type_id::create("m2sreq");
    m2srwd_c m2srwd = m2srwd_c::type_id::create("m2srwd");

    `uvm_info(get_type_name(), $sformatf("Steering TXN to HDM %d", this_hdm), UVM_NONE)

    // Branch the object created based on the local random transaction type
    case(this_tt)
      /*******************************/
      // Read Requests
      /*******************************/
      M2SREQ: begin
        // Branch based on flit mode
        if(flitmode == F68) begin
          m2sreq.flitmode = F68; // Flit mode enumeration in pkg.cxl31_ll_pkg.sv
          m2sreq.req68.val = 1'b1;
          void'(m2sreq.randomize() with {
            rand_req68.addr inside {[c_lower_addr[51:5]:c_upper_addr[51:5]]};
            rand_req68.tag == this_tag;
            // Top-level Constraints (Big Hammer)
            dis_ops_flags.cache == 1  -> !(rand_req68.memop inside {MemClnEvct, MemRdFwd, MemWrFwd}); // Disable CXL.cache-only ops
            dis_ops_flags.mem   == 1  -> !(rand_req68.memop inside {MemInv, MemRd, MemRdData, MemRdTEE, MemRdDataTEE, MemSpecRd, MemInvNT, MemSpecRdTEE, TEUpdate}); // Disable CXL.mem-only ops
            // CXL.cache Constraints (Little Hammer)
            // CXL.mem Constraints (Little Hammer)
            dis_ops_flags.inv == 1  -> !(rand_req68.memop inside {MemInv, MemInvNT});
            dis_ops_flags.spec == 1 -> !(rand_req68.memop inside {MemSpecRd, MemSpecRdTEE});
            dis_ops_flags.tee == 1  -> !(rand_req68.memop inside {MemRdTEE, MemRdDataTEE, MemSpecRdTEE, TEUpdate});
          });
        end else begin
          m2sreq.flitmode = F256; // Flit mode enumeration in pkg.cxl31_ll_pkg.sv
          m2sreq.req256.val = 1'b1;
          void'(m2sreq.randomize() with {
            rand_req256.addr inside {[c_lower_addr[51:6]:c_upper_addr[51:6]]};
            rand_req256.tag == this_tag;
            // Top-level Constraints (Big Hammer)
            dis_ops_flags.cache == 1  -> !(rand_req256.memop inside {MemClnEvct, MemRdFwd, MemWrFwd}); // Disable CXL.cache-only ops
            dis_ops_flags.mem   == 1  -> !(rand_req256.memop inside {MemInv, MemRd, MemRdData, MemRdTEE, MemRdDataTEE, MemSpecRd, MemInvNT, MemSpecRdTEE, TEUpdate}); // Disable CXL.mem-only ops
            // CXL.cache Constraints (Little Hammer)
            // CXL.mem Constraints (Little Hammer)
            dis_ops_flags.inv == 1  -> !(rand_req256.memop inside {MemInv, MemInvNT});
            dis_ops_flags.spec == 1 -> !(rand_req256.memop inside {MemSpecRd, MemSpecRdTEE});
            dis_ops_flags.tee == 1  -> !(rand_req256.memop inside {MemRdTEE, MemRdDataTEE, MemSpecRdTEE, TEUpdate});
          });
        end
        // Push onto the queue
        txn_q.push_back(m2sreq);
        count_m2sreq++;
      end
      /*******************************/
      // Write Requests
      /*******************************/
      M2SRWD: begin
        // Disable EMD (for now)
        m2srwd.c_noemd.constraint_mode(1);

        // Branch based on flit mode
        if(flitmode == F68) begin
          m2srwd.flitmode = F68; // Flit mode enumeration in pkg.cxl31_ll_pkg.sv
          m2srwd.hdr68.val = 1'b1;
          void'(m2srwd.randomize() with {
            rand_hdr68.addr inside {[c_lower_addr[51:6]:c_upper_addr[51:6]]};
            rand_hdr68.tag == this_tag;
            // Top-level Constraints (Big Hammer)
            dis_ops_flags.cache == 1  -> !(rand_hdr68.memop inside {BIConflict});
            dis_ops_flags.mem == 1    -> !(rand_hdr68.memop inside {MemRdFill, MemWrTEE, MemWrPtlTEE, MemRdFillTEE});
            // CXL.cache Constraints (Little Hammer)
            // CXL.mem Constraints (Little Hammer)
            dis_ops_flags.tee == 1  -> !(rand_hdr68.memop inside {MemWrTEE, MemWrPtlTEE, MemRdFillTEE});
          });
        end else begin
          m2srwd.flitmode = F256; // Flit mode enumeration in pkg.cxl31_ll_pkg.sv
          m2srwd.hdr256.val = 1'b1;
          void'(m2srwd.randomize() with {
            rand_hdr256.addr inside {[c_lower_addr[51:6]:c_upper_addr[51:6]]};
            rand_hdr256.tag == this_tag;
            // Top-level Constraints (Big Hammer)
            dis_ops_flags.cache == 1  -> !(rand_hdr256.memop inside {BIConflict}); // Disable CXL.cache-only ops
            dis_ops_flags.mem == 1    -> !(rand_hdr256.memop inside {MemRdFill, MemWrTEE, MemWrPtlTEE, MemRdFillTEE}); // Disable CXL.mem-only ops
            // CXL.cache Constraints (Little Hammer)
            // CXL.mem Constraints (Little Hammer)
            dis_ops_flags.tee == 1  -> !(rand_hdr256.memop inside {MemWrTEE, MemWrPtlTEE, MemRdFillTEE});
          });
        end
        // Push onto the queue
        txn_q.push_back(m2srwd);
        count_m2srwd++;
      end
      /*******************************/
      // Catch enumeration errors...
      /*******************************/
      default: begin
        `uvm_fatal(get_type_name(), "The sequence tried to generate an M2S transaction that isn't supported. Please check the constraints.")
      end
    endcase

  endtask

  virtual task convert_and_send();
    // Must define in extended class
    `uvm_fatal(get_type_name(), "The convert_and_send() virtual task must be written by the extender of this class.")
  endtask

endclass

