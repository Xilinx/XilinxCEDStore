// To add a specific callback to a specific monitor, create a callback object and then just add it,
// like shown below, probably in the connect_phase;
//
//   uvm_callbacks#(gpmon_monitor#(gpmon_cfg, virtual gpmon_if, gpmon_txn), <cb_type>)::add(agnt.mon,cb);
class link_down_cb extends gpmon_mon_cb#(gpmon_txn);

  `uvm_object_utils(link_down_cb)

  function new(string name = "link_down_cb");
    super.new(name);
  endfunction

  // Take a generic, general purpose transaction, and make it specific
  // by modifying some fields in the transaction so the user can associate
  // it without something instead of just looking at
  virtual function void make_specific(gpmon_txn txn);
    case (txn.sig[0]) inside
      1'h0:   txn.sig_enum = "Link is down";
      1'h1:   txn.sig_enum = "Link is up";
    endcase
  endfunction
endclass
