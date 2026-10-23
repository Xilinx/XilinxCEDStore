class cxl_pm_in_cb extends gpdrv_mon_cb#(gpdrv_txn);

  `uvm_object_utils(cxl_pm_in_cb)

  bit dut_cxl_host;

  logic [33:0] last_val;

  function new(string name = "cxl_pm_in_cb");
    super.new(name);
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

  virtual function void make_specific(gpdrv_txn txn);
    if (dut_cxl_host)
      host_make_specific(txn);
    else
      device_make_specific(txn);
  endfunction

  virtual function void host_make_specific(gpdrv_txn txn);
    // PMRsp/PMGo VDM
    `check_add_radix(0, "PMRsp VDM Send Req'd")
    `check_add_radix(1, "PMGo VDM Send Req'd")
    if (txn.sig[0] || txn.sig[1])
      `check_add_radix(33:2, "PCIE LTR", 1, hex)
    else begin
      // GPF VDMs
      `check_add_radix(2, "GPF Phase-1 Req VDM Send Req'd")
      `check_add_radix(3, "GPF Phase-2 Req VDM Send Req'd")
      `check_add_radix(4, "GPF Phase-1 Powerfail Imminent")
      `check_add_radix(5, "GPF Phase-1 Cache Flush")
      `check_add_radix(6, "GPF Phase-1 Cache Flush Error")
      // ResetPrep VDM
      `check_add_radix(7, "ResetPrep Req VDM Send Req'd")
      case(txn.sig[15:8])
        8'h1   : `check_add_str(15:8, "ResetType='h1 (Transition from S0 to S1)")
        8'h3   : `check_add_str(15:8, "ResetType='h3 (Transition from S0 to S3)")
        8'h4   : `check_add_str(15:8, "ResetType='h4 (Transition from S0 to S4)")
        8'h5   : `check_add_str(15:8, "ResetType='h5 (Transition from S0 to S5)")
        8'h10  : `check_add_str(15:8, "ResetType='h10 (SystemReset)")
        default: `check_add_raw(15:8, $sformatf("[15:8] : ResetType='h%0h (Invalid)", txn.sig[15:8]))
      endcase
      case(txn.sig[23:16])
        8'h0   : `check_add_str(23:16, "PrepType='h0 (General Prep)")
        default: `check_add_raw(23:16, $sformatf("[23:16] : PrepType='h%0h (Invalid)", txn.sig[23:16]))
      endcase
      // Power state
      `check_add_radix(24, "Enter L1 Power State")
    end
    // Save
    last_val = txn.sig;
  endfunction

  virtual function void device_make_specific(gpdrv_txn txn);
    `uvm_fatal(get_type_name, "cxl_pm_in_cb: device mode field decode has not been added yet")
  endfunction

  `undef check_add_radix
  `undef check_add_str
  `undef check_add_raw

endclass
