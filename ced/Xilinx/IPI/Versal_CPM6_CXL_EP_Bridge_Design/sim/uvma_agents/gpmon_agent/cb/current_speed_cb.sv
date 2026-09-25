// To add a specific callback to a specific monitor, create a callback object and then just add it,
// like shown below, probably in the connect_phase;
//
//   uvm_callbacks#(gpmon_monitor#(gpmon_cfg, virtual gpmon_if, gpmon_txn), <cb_type>)::add(agnt.mon,cb);
class current_speed_cb extends gpmon_mon_cb#(gpmon_txn);

  `uvm_object_utils(current_speed_cb)

  function new(string name = "current_speed_cb");
    super.new(name);
  endfunction

  // Take a generic, general purpose transaction, and make it specific
  // by modifying some fields in the transaction so the user can associate
  // it without something instead of just looking at
  virtual function void make_specific(gpmon_txn txn);
    case (txn.sig[2:0]) inside
      3'h0:    txn.sig_enum = "Gen1 : 2.5 GT/s";
      3'h1:    txn.sig_enum = "Gen2 : 5.0 GT/s";
      3'h2:    txn.sig_enum = "Gen3 : 8.0 GT/s";
      3'h3:    txn.sig_enum = "Gen4 : 16.0 GT/s";
      3'h4:    txn.sig_enum = "Gen5 : 32.0 GT/s";
      default: txn.sig_enum = "Reserved";
    endcase
  endfunction
endclass
