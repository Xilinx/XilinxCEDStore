// To add a specific callback to a specific monitor, create a callback object and then just add it,
// like shown below, probably in the connect_phase;
//
//   uvm_callbacks#(gpmon_monitor#(gpmon_cfg, virtual gpmon_if, gpmon_txn), <cb_type>)::add(agnt.mon,cb);
class negotiated_width_cb extends gpmon_mon_cb#(gpmon_txn);

  `uvm_object_utils(negotiated_width_cb)

  function new(string name = "negotiated_width_cb");
    super.new(name);
  endfunction

  // Take a generic, general purpose transaction, and make it specific
  // by modifying some fields in the transaction so the user can associate
  // it without something instead of just looking at
  virtual function void make_specific(gpmon_txn txn);
    case (txn.sig[2:0]) inside
      3'h0:    txn.sig_enum = "x1";
      3'h1:    txn.sig_enum = "x2";
      3'h2:    txn.sig_enum = "x4";
      3'h3:    txn.sig_enum = "x8";
      3'h4:    txn.sig_enum = "x16";
      default: txn.sig_enum = "Reserved";
    endcase
  endfunction
endclass
