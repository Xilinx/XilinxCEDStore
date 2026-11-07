// To add a specific callback to a specific monitor, create a callback object and then just add it,
// like shown below, probably in the connect_phase;
//
//   uvm_callbacks#(gpmon_monitor#(gpmon_cfg, virtual gpmon_if, gpmon_txn), <cb_type>)::add(agnt.mon,cb);
class function_status_cb extends gpmon_mon_cb#(gpmon_txn);

  `uvm_object_utils(function_status_cb)

  function new(string name = "function_status_cb");
    super.new(name);
  endfunction

  // Take a generic, general purpose transaction, and make it specific
  // by modifying some fields in the transaction so the user can associate
  // it without something instead of just looking at
  virtual function void make_specific(gpmon_txn txn);
    string str; 
    str = {     "I/O Space ", txn.sig[0] ? "Ena" : "Dis", ","};
    str = {str, "Mem Space ", txn.sig[1] ? "Ena" : "Dis", ","};
    str = {str, "Bus Mastr ", txn.sig[2] ? "Ena" : "Dis", ","};
    str = {str, "INTx ",      txn.sig[3] ? "Ena" : "Dis"};
    txn.sig_enum = str;
  endfunction
endclass
