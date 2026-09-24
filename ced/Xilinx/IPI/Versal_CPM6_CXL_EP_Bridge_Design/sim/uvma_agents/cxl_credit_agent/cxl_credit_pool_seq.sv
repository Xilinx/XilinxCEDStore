// This sequence is designed to be run on the sequencer and pull
// credits from the share object and send them when agent is a
// UVM_MASTER
class cxl_credit_pool_seq extends uvm_sequence#(cxl_credit_bus_txn);

  `uvm_object_utils(cxl_credit_pool_seq)
  `uvm_declare_p_sequencer(cxl_credit_sequencer);

  function new(string name = "cxl_credit_pool_seq");
    super.new(name);
  endfunction
 
  rand bit       req_mem;
  rand bit       dat_mem;
  rand bit       rsp_mem;

  rand bit [6:0] req_crd;
  rand bit [6:0] dat_crd;
  rand bit [6:0] rsp_crd;

  constraint c_valid {
    // Valid decimal values
    req_crd inside {0, 1, 2, 4, 8, 16, 32, 64}; 
    dat_crd inside {0, 1, 2, 4, 8, 16, 32, 64}; 
    rsp_crd inside {0, 1, 2, 4, 8, 16, 32, 64}; 
    // If only .mem available, return .mem
    // If only .cache available, return .cache
    // Otherwise, just randomly choose which to return
    // -- req
    req_crd <= p_sequencer.shr.req_credit_pool[req_mem];
    if (p_sequencer.shr.req_credit_pool[1] && !p_sequencer.shr.req_credit_pool[0])
      req_mem == 1;
    else if (!p_sequencer.shr.req_credit_pool[1] && p_sequencer.shr.req_credit_pool[0])
      req_mem == 0;
    // -- dat
    dat_crd <= p_sequencer.shr.dat_credit_pool[dat_mem];
    if (p_sequencer.shr.dat_credit_pool[1] && !p_sequencer.shr.dat_credit_pool[0])
      dat_mem == 1;
    else if (!p_sequencer.shr.dat_credit_pool[1] && p_sequencer.shr.dat_credit_pool[0])
      dat_mem == 0;
    // -- rsp
    rsp_crd <= p_sequencer.shr.rsp_credit_pool[rsp_mem];
    if (p_sequencer.shr.rsp_credit_pool[1] && !p_sequencer.shr.rsp_credit_pool[0])
      rsp_mem == 1;
    else if (!p_sequencer.shr.rsp_credit_pool[1] && p_sequencer.shr.rsp_credit_pool[0])
      rsp_mem == 0;
  }

  // Its own constraint to enable/disable easily
  constraint c_no_rand_0 {
    |p_sequencer.shr.req_credit_pool.sum -> req_crd != 0;
    |p_sequencer.shr.dat_credit_pool.sum -> dat_crd != 0;
    |p_sequencer.shr.rsp_credit_pool.sum -> rsp_crd != 0;
  }
  
  // Its own constraint to enable/disable easily
  constraint c_max_possible {
    if (|p_sequencer.shr.req_credit_pool.sum) {
      p_sequencer.shr.req_credit_pool[req_mem]>=64              -> req_crd==64;
      p_sequencer.shr.req_credit_pool[req_mem] inside {[32:63]} -> req_crd==32;
      p_sequencer.shr.req_credit_pool[req_mem] inside {[16:31]} -> req_crd==16;
      p_sequencer.shr.req_credit_pool[req_mem] inside {[ 8:15]} -> req_crd==8;
      p_sequencer.shr.req_credit_pool[req_mem] inside {[ 4: 7]} -> req_crd==4;
      p_sequencer.shr.req_credit_pool[req_mem] inside {[ 2: 3]} -> req_crd==2;
      p_sequencer.shr.req_credit_pool[req_mem]==1               -> req_crd==1;
    }
    if (|p_sequencer.shr.dat_credit_pool.sum) {
      p_sequencer.shr.dat_credit_pool[dat_mem]>=64              -> dat_crd==64;
      p_sequencer.shr.dat_credit_pool[dat_mem] inside {[32:63]} -> dat_crd==32;
      p_sequencer.shr.dat_credit_pool[dat_mem] inside {[16:31]} -> dat_crd==16;
      p_sequencer.shr.dat_credit_pool[dat_mem] inside {[ 8:15]} -> dat_crd==8;
      p_sequencer.shr.dat_credit_pool[dat_mem] inside {[ 4: 7]} -> dat_crd==4;
      p_sequencer.shr.dat_credit_pool[dat_mem] inside {[ 2: 3]} -> dat_crd==2;
      p_sequencer.shr.dat_credit_pool[dat_mem]==1               -> dat_crd==1;
    }
    if (|p_sequencer.shr.rsp_credit_pool.sum) {
      p_sequencer.shr.rsp_credit_pool[rsp_mem]>=64              -> rsp_crd==64;
      p_sequencer.shr.rsp_credit_pool[rsp_mem] inside {[32:63]} -> rsp_crd==32;
      p_sequencer.shr.rsp_credit_pool[rsp_mem] inside {[16:31]} -> rsp_crd==16;
      p_sequencer.shr.rsp_credit_pool[rsp_mem] inside {[ 8:15]} -> rsp_crd==8;
      p_sequencer.shr.rsp_credit_pool[rsp_mem] inside {[ 4: 7]} -> rsp_crd==4;
      p_sequencer.shr.rsp_credit_pool[rsp_mem] inside {[ 2: 3]} -> rsp_crd==2;
      p_sequencer.shr.rsp_credit_pool[rsp_mem]==1               -> rsp_crd==1;
    }
  }

  virtual task body();
    cxl_credit_bus_txn t = cxl_credit_bus_txn::type_id::create("t");
    forever begin
      // Wait until there is at least 1 credit to return
      while (!p_sequencer.shr.any_credits) p_sequencer.wait_cycles(1);
      // Not sure why any other sequence would have the sqr, but grab it anyways
      p_sequencer.grab(this);
      // Send the txn
      start_item(t);
      void'(this.randomize);
      t.vld = 1'b1;
      t.req = {req_mem, t.convert2enc(req_crd)}; 
      t.dat = {dat_mem, t.convert2enc(dat_crd)}; 
      t.rsp = {rsp_mem, t.convert2enc(rsp_crd)}; 
      finish_item(t);
      p_sequencer.shr.req_credit_pool[req_mem] -= req_crd;
      p_sequencer.shr.dat_credit_pool[dat_mem] -= dat_crd;
      p_sequencer.shr.rsp_credit_pool[rsp_mem] -= rsp_crd;
      // Ungrab the sqr
      p_sequencer.ungrab(this);
    end
  endtask

endclass
