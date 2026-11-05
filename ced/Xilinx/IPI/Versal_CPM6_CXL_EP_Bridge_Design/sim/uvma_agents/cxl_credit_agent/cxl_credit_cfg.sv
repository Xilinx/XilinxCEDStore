class cxl_credit_cfg extends base_cfg;

  `uvm_object_utils(cxl_credit_cfg)

  bit mon_indi;            //monitor broadcasts several cxl_credit_txns, not one cxl_credit_bus_txn
  bit cmp_zero;            //compare all (even zero) credits in cxl_credit_bus_txn.do_compare
  bit broadcast_all;       //send all txns out analysis ports, not only nonzero
  bit mst_use_credit_pool; //iff a MASTER, this will add credits to pool from impl port and 
                           //start the pool sequence to transmit and subtract from pool

  function new(string name = "cxl_credit_cfg");
    super.new(name);
  endfunction

endclass
