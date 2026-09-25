class cxl_pm_out_cb extends gpmon_mon_cb#(gpmon_txn);

  `uvm_object_utils(cxl_pm_out_cb)

  bit dut_cxl_host;

  logic [32:0] last_val;

  function new(string name = "cxl_pm_out_cb");
    super.new(name);
  endfunction

  virtual function void make_specific(gpmon_txn txn);
    if (dut_cxl_host)
      host_make_specific(txn);
    else
      device_make_specific(txn);
  endfunction

  // Make macro printing sensible
  local function string retValRadix(string i, int value);
    case (i)
      "bin"  : return $sformatf("'b%0b",value);
      "hex"  : return $sformatf("'h%0h",value);
      "dec"  : return $sformatf(  "%0d",value);
    endcase
    `uvm_fatal(get_type_name, $sformatf("method input i=\"%0s\" is invalid", i))
  endfunction

  // These macros add a string in the transaction for sensible printing to the user
  // F = "field"
  // M = "message"
  // S = "skip diff check"
  // R = "radix"  (default: binary)
  `define check_add_radix(F, M, S=0, R=bin) \
    if ((last_val[F]!==txn.sig[F]) || S) begin \
      txn.ml_sig_enum.push_back($sformatf("[%0s] : %0s = %0s", `"F`", M, retValRadix(`"R`",txn.sig[F]))); \
    end 

  `define check_add_str(F, M, S=0) \
    if ((last_val[F]!==txn.sig[F]) || S) begin \
      txn.ml_sig_enum.push_back({"[",`"F`","] : ",M}); \
    end 

  `define check_add_raw(F, M, S=0) \
    if ((last_val[F]!==txn.sig[F]) || S) begin \
      txn.ml_sig_enum.push_back(M); \
    end 

  virtual function void host_make_specific(gpmon_txn txn);
    // PMREQ VDM
    if (txn.sig[0]) begin
      `check_add_radix(0, "PMREQ Req VDM Rx'd")
      `check_add_radix(32:1, "PCIE LTR", 1, hex)
    end
    else begin
      `check_add_radix(0, "PMREQ Req VDM Rx'd")
      // GPF VDMs
      `check_add_radix(1, "GPF Phase-1 Rsp VDM Rx'd")
      `check_add_radix(2, "GPF Phase-2 Rsp VDM Rx'd")
      `check_add_radix(3, "GPF Phase-1->Cache Flush Error")
      // ResetPrep VDM
      `check_add_radix(4, "ResetPrep Rsp VDM Rx'd")
      // CXL Error VDM
      `check_add_radix(5, "CXL Error VDM Rx'd")
      // CXL Error VDM sub-field
      `check_add_raw(9:6, $sformatf("[9:6] : CXL Error Firmware IRQ Vector = 'h%0h", txn.sig[9:6]))
      `check_add_radix(11, "GPF Capable Peer")
      // Ack from pm_in
      `check_add_radix(24, "Ack for cxl_pm_in Req")
    end
    // Save
    last_val = txn.sig;
  endfunction

  virtual function void device_make_specific(gpmon_txn txn);
    // GPF VDMs
    `check_add_radix(0, "GPF Phase-1 Req VDM Rx'd")
    `check_add_radix(1, "GPF Phase-2 Req VDM Rx'd")
    `check_add_radix(2, "GPF Phase-1->Powerfail Imminent")
    `check_add_radix(3, "GPF Phase-1->Initiate Cache Flush")
    `check_add_radix(4, "GPF Phase-2->Cache Flush Error")
    // ResetPrep VDM
    `check_add_radix(5, "ResetPrep Req VDM Rx'd")
    case(txn.sig[13:6])
      8'h1   : `check_add_str(13:6, "ResetType='h1 (Transition from S0 to S1)")
      8'h3   : `check_add_str(13:6, "ResetType='h3 (Transition from S0 to S3)")
      8'h4   : `check_add_str(13:6, "ResetType='h4 (Transition from S0 to S4)")
      8'h5   : `check_add_str(13:6, "ResetType='h5 (Transition from S0 to S5)")
      8'h10  : `check_add_str(13:6, "ResetType='h10 (SystemReset)")
      default: `check_add_raw(13:6, $sformatf("[13:6] : ResetType='h%0h (Invalid)", txn.sig[13:6]))
    endcase
    case(txn.sig[21:14])
      8'h0   : `check_add_str(21:14, "PrepType='h0 (General Prep)")
      default: `check_add_raw(21:14, $sformatf("[21:14] : PrepType='h%0h (Invalid)", txn.sig[21:14]))
    endcase
    // PMReq/Rsp/GO VDM
    `check_add_radix(22, "PMREQ Rsp VDM Rx'd")
    `check_add_radix(23, "PMREQ GO VDM Rx'd")
    // Ack from pm_in
    `check_add_radix(24, "Ack for cxl_pm_in Req")
    // Save
    last_val = txn.sig;
  endfunction

  `undef check_add_radix
  `undef check_add_str
  `undef check_add_raw

endclass
