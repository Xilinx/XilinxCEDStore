// This class converts between cxl_nfi_agent's credit txns and
// cxl_credit_agent's txns, which is necessary when the credit
// agent returns credits, not the cxl_nfi_agent (as flits) 
class cxl_credit_shim extends uvm_component;

  `uvm_component_utils(cxl_credit_shim)

  `uvm_analysis_imp_decl(_nfi2crd)
  `uvm_analysis_imp_decl(_crd2nfi)

  uvm_analysis_imp_nfi2crd #(cxl_nfi_credit_txn, cxl_credit_shim) impl_nfi2crd;
  uvm_analysis_imp_crd2nfi #(cxl_credit_bus_txn, cxl_credit_shim) impl_crd2nfi;
  
  uvm_analysis_port #(cxl_credit_bus_txn) ap_crd;
  uvm_analysis_port #(cxl_nfi_credit_txn) ap_nfi_from_rx;
  uvm_analysis_port #(cxl_nfi_credit_txn) ap_nfi_from_tx;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    impl_nfi2crd = new ("impl_nfi2crd", this);
    impl_crd2nfi = new ("impl_crd2nfi", this);
    ap_crd         = new("ap_crd", this); 
    ap_nfi_from_rx = new("ap_nfi_from_rx", this); 
    ap_nfi_from_tx = new("ap_nfi_from_tx", this); 
  endfunction

  // Converts a cxl_nfi_credit_tn to cxl_credit_bus_txn
  function void write_nfi2crd(cxl_nfi_credit_txn t);
    cxl_credit_bus_txn T = cxl_credit_bus_txn::type_id::create("T");
    {T.vld, T.use_sideband} = 2'b11;
    // CXL.mem
    T.req_cred[1] = t.req_cred[1];
    T.dat_cred[1] = t.dat_cred[1];
    T.rsp_cred[1] = t.rsp_cred[1];
    // CXL.cache
    T.req_cred[0] = t.req_cred[0];
    T.dat_cred[0] = t.dat_cred[0];
    T.rsp_cred[0] = t.rsp_cred[0];
    // Send it
    if (T.req_cred.sum || T.dat_cred.sum || T.rsp_cred.sum) begin
      ap_crd.write(T);
    end
  endfunction

  function void write_crd2nfi(cxl_credit_bus_txn t);
    int req, dat, rsp;
    cxl_nfi_credit_txn T = cxl_nfi_credit_txn::type_id::create("T");
    if (t.vld) begin
      if (t.get_mem_credits(req, dat, rsp)) begin
        T.req_cred[1] = req;
        T.dat_cred[1] = dat;
        T.rsp_cred[1] = rsp;
      end
      if (t.get_cch_credits(req, dat, rsp)) begin
        T.req_cred[0] = req;
        T.dat_cred[0] = dat;
        T.rsp_cred[0] = rsp;
      end
    end
    // Send it
    if (T.req_cred.sum || T.dat_cred.sum || T.rsp_cred.sum) begin
      case (1'b1)
        // Got txn from the link partner (rx credit agent)
        (t.uid.substr(0,1)=="Rx") : ap_nfi_from_rx.write(T);
        // Got txn from our side i.e. we sent across link (tx credit agent)
        (t.uid.substr(0,1)=="Tx") : ap_nfi_from_tx.write(T);
        default : `uvm_fatal(get_type_name(), $sformatf("Unexpected t.uid = %0s", t.uid))
      endcase
    end
  endfunction

endclass
