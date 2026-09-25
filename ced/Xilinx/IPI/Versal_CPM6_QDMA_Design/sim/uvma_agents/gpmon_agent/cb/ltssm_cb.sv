// To add a specific callback to a specific monitor, create a callback object and then just add it,
// like shown below, probably in the connect_phase;
//
//   uvm_callbacks#(gpmon_monitor#(gpmon_cfg, virtual gpmon_if, gpmon_txn), <cb_type>)::add(agnt.mon,cb);
class ltssm_cb extends gpmon_mon_cb#(gpmon_txn);

  `uvm_object_utils(ltssm_cb)

  function new(string name = "ltssm_cb");
    super.new(name);
  endfunction

  // Take a generic, general purpose transaction, and make it specific
  // by modifying some fields in the transaction so the user can associate
  // it without something instead of just looking at
  virtual function void make_specific(gpmon_txn txn);
    case (txn.sig[5:0]) inside
      6'h00:   txn.sig_enum = "Detect.Quiet";
      6'h01:   txn.sig_enum = "Detect.Active";
      6'h02:   txn.sig_enum = "Polling.Active";
      6'h03:   txn.sig_enum = "Polling.Compliance";
      6'h04:   txn.sig_enum = "Polling.Configuration";
      6'h05:   txn.sig_enum = "Configuration.Linkwidth.Start";
      6'h06:   txn.sig_enum = "Configuration.Linkwidth.Accept";
      6'h07:   txn.sig_enum = "Configuration.Lanenum.Accept";
      6'h08:   txn.sig_enum = "Configuration.Lanenum.Wait";
      6'h09:   txn.sig_enum = "Configuration.Complete";
      6'h0A:   txn.sig_enum = "Configuration.Idle";
      6'h0B:   txn.sig_enum = "Recovery.RcvrLock";
      6'h0C:   txn.sig_enum = "Recovery.Speed";
      6'h0D:   txn.sig_enum = "Recovery.RcvrCfg";
      6'h0E:   txn.sig_enum = "Recovery.Idle";
      6'h10:   txn.sig_enum = "L0";
      [6'h11:6'h16] : txn.sig_enum = "Reserved";
      6'h17:   txn.sig_enum = "L1.Entry";
      6'h18:   txn.sig_enum = "L1.Idle";
      6'h19:   txn.sig_enum = "L23.Idle";
      6'h1A:   txn.sig_enum = "L23.TxWake";
      6'h20:   txn.sig_enum = "Disabled";
      6'h21:   txn.sig_enum = "Loopback_Entry_Master";
      6'h22:   txn.sig_enum = "Loopback_Active_Master";
      6'h23:   txn.sig_enum = "Loopback_Exit_Master";
      6'h24:   txn.sig_enum = "Loopback_Entry_Slave";
      6'h25:   txn.sig_enum = "Loopback_Active_Slave";
      6'h26:   txn.sig_enum = "Loopback_Exit_Slave";
      6'h27:   txn.sig_enum = "Hot_Reset";
      6'h28:   txn.sig_enum = "Recovery_Eq_Phase0";
      6'h29:   txn.sig_enum = "Recovery_Eq_Phase1";
      6'h2A:   txn.sig_enum = "Recovery_Eq_Phase2";
      6'h2B:   txn.sig_enum = "Recovery_Eq_Phase3";
      default: txn.sig_enum = "Unknown";
    endcase
  endfunction
endclass
