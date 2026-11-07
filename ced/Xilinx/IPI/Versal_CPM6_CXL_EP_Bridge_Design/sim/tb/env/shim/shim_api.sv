class shim_api extends uvm_component;

  `uvm_component_utils(shim_api)

  apci_device vip;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Can send any transaction, which will be >= 1 TLP
  virtual task send_txn(amd_base_tlp tlp);
    amd_cfg_tlp ctlp;
    amd_mem_tlp mtlp;
    case (1'b1)
      $cast(ctlp, tlp) : if (ctlp.is_basic) send_cfg(ctlp);  
                         else               send_cfg_raw(ctlp);
      $cast(mtlp, tlp) : if (mtlp.is_basic) send_mem(mtlp);  
                         else               send_mem_raw(mtlp);
      default : `uvm_fatal(get_type_name, "Unsupported transaction")
    endcase
  endtask

  // Can send any transaction, which will be >= 1 flit(s)
  virtual task send_cxl_txn(amd_cxlbase_tlp tlp);
    amd_cxlmem_tlp mtlp;
    case (1'b1)
      $cast(mtlp, tlp) : if (mtlp.is_basic) send_cxlmem(mtlp);  
                         else               send_cxlmem_raw(mtlp);
      default : `uvm_fatal(get_type_name, "Unsupported transaction")
    endcase
  endtask

  // DESCRIPTION: Send a Mem TLP specifically in basic mode (simple control)
  virtual task send_mem(amd_mem_tlp tlp);
    string msg;
    apci_transaction tr = apci_transaction::type_id::create("tr");
    // Error check
    if (!tlp.is_basic)
      `uvm_fatal(get_type_name, "Trying to send a basic cfg transaction in raw mode")
    // AMD->VIP conversion (shim)
    tr.is_write = !tlp.rd;      
    tr.length   = tlp.length;   
    tr.addr     = tlp.addr;     
    tr.first_be = tlp.f_be;       
    tr.last_be  = tlp.l_be;       
    tr.kind     = APCI_TRANS_mem;
    if (tlp.ide_stream_id !== 8'hx) begin
      tr.user_ctrl.ide_stream_id = tlp.ide_stream_id;
    end
    if (!tlp.rd)
      tr.payload = tlp.data;
    vip.post_transaction(tr);
    if (tlp.blocking == SCHED)
      tr.wait_enter_vc();
    else if (tlp.blocking == SENT)
      tr.wait_issued();
    else if (tlp.blocking == DONE) begin
      tr.wait_done();
      // Report non-SC completion status, if required
      case (tr.err_code)
        apci_transaction::OK      : tlp.cpl_sts = CPL_SC;
        apci_transaction::ERROR   : tlp.cpl_sts = CPL_UR; 
        apci_transaction::RETRY   : tlp.cpl_sts = CPL_RRS;
        apci_transaction::ABORTED : tlp.cpl_sts = CPL_CA;
        default                   : tlp.cpl_sts = NO_CPL; 
      endcase 
      if (!tlp.got_SC) begin
        msg = "Completion status was not Successful Completion (SC)"; 
        case (tlp.cpl_sts_sev)
          UVM_INFO    : `uvm_info   (get_type_name, msg, UVM_LOW)
          UVM_WARNING : `uvm_warning(get_type_name, msg)
          UVM_ERROR   : `uvm_error  (get_type_name, msg)
          UVM_FATAL   : `uvm_fatal  (get_type_name, msg)
        endcase
      end
      // VIP->AMD conversion (un-shim)
      if (tlp.rd) begin
        tlp.data = tr.payload;
        if (!tlp.expected_match) begin
          msg = $sformatf("Read data mismatch: 1st mismatch=DW%0d, total mismatches=%0d",
                          tlp.mismatch_first, tlp.mismatch_cnt);
          case (tlp.mismatch_sev)
            UVM_INFO    : `uvm_info   (get_type_name, msg, UVM_LOW)
            UVM_WARNING : `uvm_warning(get_type_name, msg)
            UVM_ERROR   : `uvm_error  (get_type_name, msg)
            UVM_FATAL   : `uvm_fatal  (get_type_name, msg)
          endcase
        end
      end
    end
  endtask

  // DESCRIPTION: Send a Mem TLP specifically in raw mode (full TLP control)
  virtual task send_mem_raw(amd_mem_tlp tlp);
    // Error check
    if (tlp.is_basic)
      `uvm_fatal(get_type_name, "Trying to send a raw mem transaction in basic mode")
    `uvm_fatal(get_type_name, "method not implemented yet")
  endtask

  // DESCRIPTION: Send a CXL TLP specifically in basic mode (simple control)
  virtual task send_cxlmem(amd_cxlmem_tlp tlp);
    string           msg;
    bit [15:0][31:0] dat;
    apci_transaction tr;
    acxl_msg         m;
    // Error check
    if (!tlp.is_basic)
      `uvm_fatal(get_type_name, "Trying to send a basic cfg transaction in raw mode")
    // AMD->VIP conversion (shim) ; varies on coh member 
    if (tlp.coh == BYPASS_AGENT) begin
      m = acxl_msg::type_id::create("m");
      case (tlp.rd)
        1'b1 :           
        begin
          m.kind = ACXL_MSG_m2s_req;
          m.user_ctrl.spec_read = 0;
          m.u.m2s_req.opcode    = ACXL_M2S_MemRdData;
          m.u.m2s_req.ldid      = 0;
          m.u.m2s_req.tc        = 0;
          m.u.m2s_req.addr51_5  = tlp.addr[51:5];
          m.u.m2s_req.tag       = $urandom_range(0,2**16-1);
          m.u.m2s_req.metaValue = 3; //Don't care
          m.u.m2s_req.metaField = 3; //No-Op
          m.u.m2s_req.snpType   = 0; //No-Op
          m.u.m2s_req.valid     = 1;
        end
        1'b0 :
        begin
          m.kind = ACXL_MSG_m2s_reqdata;
          m.u.m2s_reqdata.opcode = tlp.be[0]=='1 ? ACXL_M2S_MemWr : ACXL_M2S_MemWrPtl;
          m.u.m2s_reqdata.addr51_6  = tlp.addr[51:6];
          m.u.m2s_reqdata.tc        = 0;
          m.u.m2s_reqdata.poison    = 0;
          m.u.m2s_reqdata.tag       = $urandom_range(0,2**16-1);
          m.u.m2s_reqdata.metaValue = 3; //Don't care
          m.u.m2s_reqdata.metaField = 0; //MS0
          m.u.m2s_reqdata.snpType   = 0; //No-Op
          m.u.m2s_reqdata.valid     = 1;
          m.be    = tlp.be[0];
          m.bytes = new[64];
          foreach (m.bytes[ii])
            m.bytes[ii] = tlp.data[0][ii/4][(ii%4)*8+:8];
        end
      endcase
      vip.inject_cxl_msg("tx_bypass_coh", m, 0);
      if (tlp.blocking == SCHED)
        m.wait_sent("tag_assigned");
      else if (tlp.blocking == SENT)
        m.wait_sent("exit_cxl_dl");
      else if (tlp.blocking == DONE) begin
        m.wait_done();
        // VIP->AMD conversion (un-shim)
        if (tlp.rd) begin
          foreach (m.rspData_msgs[ii]) begin 
            foreach (m.rspData_msgs[ii].bytes[jj]) begin
              dat[jj/4][(jj%4)*8+:8] = m.rspData_msgs[ii].bytes[jj];
            end
            tlp.data.push_back(dat);
          end
          if (!tlp.expected_match) begin
            msg = $sformatf("Read data mismatch: 1st mismatch=LINE%0d, total mismatches=%0d",
                            tlp.mismatch_first, tlp.mismatch_cnt);
            case (tlp.mismatch_sev)
              UVM_INFO    : `uvm_info   (get_type_name, msg, UVM_LOW)
              UVM_WARNING : `uvm_warning(get_type_name, msg)
              UVM_ERROR   : `uvm_error  (get_type_name, msg)
              UVM_FATAL   : `uvm_fatal  (get_type_name, msg)
            endcase
          end
        end
      end
    end
    else begin
      tr = apci_transaction::type_id::create("tr");
      if (tlp.coh != USE_AGENT)
        tr.user_ctrl.allocate_if_cache_miss = (tlp.coh==AGENT_ALLOC);
      tr.is_write = !tlp.rd;      
      tr.length   = tlp.length*16; //cachelines to DWORDs
      tr.addr     = tlp.addr;     
      tr.kind     = APCI_TRANS_mem;
      if (!tlp.rd)
        foreach (tlp.data[ii,jj])
          tr.payload.push_back(tlp.data[ii][jj]);
      vip.post_cxl_tr(tr);
      if (tlp.blocking == SCHED)
        tr.wait_enter_vc();
      else if (tlp.blocking == SENT)
        tr.wait_issued();
      else if (tlp.blocking == DONE) begin
        tr.wait_done();
        // Report non-SC completion status, if required
        case (tr.err_code)
          apci_transaction::OK      : tlp.cpl_sts = CPL_SC;
          apci_transaction::ERROR   : tlp.cpl_sts = GENERAL_ERR;
          default                   : tlp.cpl_sts = NO_CPL; 
        endcase 
        if (!tlp.got_SC) begin
          msg = "Transaction was not succesfully completed";
          case (tlp.cpl_sts_sev)
            UVM_INFO    : `uvm_info   (get_type_name, msg, UVM_LOW)
            UVM_WARNING : `uvm_warning(get_type_name, msg)
            UVM_ERROR   : `uvm_error  (get_type_name, msg)
            UVM_FATAL   : `uvm_fatal  (get_type_name, msg)
          endcase
        end
        // VIP->AMD conversion (un-shim)
        if (tlp.rd) begin
          foreach (tr.payload[ii]) begin 
            dat[ii] = tr.payload[ii];
            if (!(ii%16) && ii)
              tlp.data.push_back(dat);
          end
          if (!tlp.expected_match) begin
            msg = $sformatf("Read data mismatch: 1st mismatch=DW%0d, total mismatches=%0d",
                            tlp.mismatch_first, tlp.mismatch_cnt);
            case (tlp.mismatch_sev)
              UVM_INFO    : `uvm_info   (get_type_name, msg, UVM_LOW)
              UVM_WARNING : `uvm_warning(get_type_name, msg)
              UVM_ERROR   : `uvm_error  (get_type_name, msg)
              UVM_FATAL   : `uvm_fatal  (get_type_name, msg)
            endcase
          end
        end
      end
    end
  endtask

  // DESCRIPTION: Send a CXL TLP specifically in raw mode (full TLP control)
  virtual task send_cxlmem_raw(amd_cxlmem_tlp tlp);
    // Error check
    if (tlp.is_basic)
      `uvm_fatal(get_type_name, "Trying to send a raw mem transaction in basic mode")
    `uvm_fatal(get_type_name, "method not implemented yet")
  endtask

  // DESCRIPTION: Send a CXL Mailbox (Primary, Secondary) command and get response
  virtual task send_cxl_mbox_cmd(pcie_device pdev, ref cxl_comp_mbox_cmd_s cmd, input bit pri_mbox = 1);
    amd_mem_tlp      tlp;
    bit [63:0]       tgt_addr;
    cxl_dev_cap_s    s;
    cxl_dev_cap_id_e id = pri_mbox ? PRI_MBX_REGS : SEC_MBX_REGS;  
    int              ii;
    // First, get the address to target from the pdev 
    if (!pdev.get_cxl_dev_cap(id, s)) begin
      `uvm_warning(get_type_name, $sformatf("%0s not found in pdev; exiting ::send_cxl_mbox_cmd", id.name))
      return;
    end
    tgt_addr = s.base;
    tlp = amd_mem_tlp::type_id::create("tlp"); 
    // 1. Confirm doorbell is clear
    do begin
      tlp.build_rd(tgt_addr+'h4, 1, .blocking(DONE));
      send_mem(tlp);
    end while (tlp.data[0][0][0]);
    // 2. Set up command and payload length
    cmd.payload_len = cmd.ipayload.size;
    tlp.build_wr(tgt_addr+'h8, 2, {{cmd.payload_len[15:0], cmd.opcode}, cmd.payload_len[20:16]});
    send_mem(tlp);
    // 3. Set up input payload, if present
    tgt_addr += 'h20;
    while (cmd.payload_len>=8) begin
      tlp.build_wr(tgt_addr, 2, {<<8{ {<<32{cmd.ipayload[ii*8+:8]}} }}); 
      send_mem(tlp);
      tgt_addr += 'h8;
      cmd.payload_len -= 8;
      ii += 1;
    end
    if (cmd.payload_len inside {[5:7]}) begin
      case (cmd.payload_len)
        5 : tlp.build_wr(tgt_addr, 2, {<<8{ {<<32{cmd.ipayload[ii*8+:5],24'h0}} }}); 
        6 : tlp.build_wr(tgt_addr, 2, {<<8{ {<<32{cmd.ipayload[ii*8+:6],16'h0}} }}); 
        7 : tlp.build_wr(tgt_addr, 2, {<<8{ {<<32{cmd.ipayload[ii*8+:7], 8'h0}} }}); 
      endcase
      send_mem(tlp);
      cmd.payload_len = 0;
    end
    else if (cmd.payload_len) begin
      case (cmd.payload_len)
        1 : tlp.build_wr(tgt_addr, 1, {<<8{cmd.ipayload[ii*8+:1],24'h0}}); 
        2 : tlp.build_wr(tgt_addr, 1, {<<8{cmd.ipayload[ii*8+:2],16'h0}}); 
        3 : tlp.build_wr(tgt_addr, 1, {<<8{cmd.ipayload[ii*8+:3], 8'h0}}); 
        4 : tlp.build_wr(tgt_addr, 1, {<<8{cmd.ipayload[ii*8+:4]      }}); 
      endcase
      send_mem(tlp);
      cmd.payload_len = 0;
    end
    // 4. Ring the doorbell
    tgt_addr = s.base;
    tlp.build_wr(tgt_addr+'h4, 1, {32'h1}, .blocking(DONE));
    send_mem(tlp);
    // 5. Poll until the doorbell is clear
    do begin
      tlp.build_rd(tgt_addr+'h4, 1, .blocking(DONE));
      send_mem(tlp);
    end while (tlp.data[0][0][0]);
    // 6. Get command's return code
    tlp.build_rd(tgt_addr+'h14, 1, .blocking(DONE));
    send_mem(tlp);
    cmd.retcode = cxl_comp_mbox_cmd_retcode_e'(tlp.data[0][1:0]);
    // 7. If payload is successful, get the payload length
    if (cmd.retcode == Success) begin
      tlp.build_rd(tgt_addr+'h8, 2, .blocking(DONE));
      send_mem(tlp);
      cmd.payload_len[15: 0] = tlp.data[0][3:2];
      cmd.payload_len[20:16] = tlp.data[1];
    end
    // 8. Get output payload, if present
    tgt_addr += 'h20;
    while (cmd.payload_len>=8) begin
      tlp.build_rd(tgt_addr, 2, .blocking(DONE));
      send_mem(tlp);
      cmd.opayload = new[cmd.opayload.size+8] (cmd.opayload);
      cmd.opayload[ii*8+:8] = {<<8{ {<<32{tlp.data}} }};
      tgt_addr += 'h8;
      cmd.payload_len -= 8;
      ii += 1;
    end
    if (cmd.payload_len inside {[5:7]}) begin
      tlp.build_rd(tgt_addr, 2, .blocking(DONE));
      send_mem(tlp);
      cmd.opayload = new[cmd.opayload.size+8] (cmd.opayload);
      cmd.opayload[ii*8+:8] = {<<8{ {<<32{tlp.data}} }};
      // Trim down to unaligned DW size
      cmd.opayload = new[cmd.opayload.size-(8-cmd.payload_len)];
      cmd.payload_len = 0; 
    end
    else if (cmd.payload_len) begin
      tlp.build_rd(tgt_addr, 1, .blocking(DONE));
      send_mem(tlp);
      cmd.opayload = new[cmd.opayload.size+8] (cmd.opayload);
      cmd.opayload[ii*8+:4] = {<<8{tlp.data[0]}};
      // Trim down to unaligned DW size
      cmd.opayload = new[cmd.opayload.size-(4-cmd.payload_len)];
      cmd.payload_len = 0; 
    end
  endtask

  // DESCRIPTION: Send a Cfg TLP specifically in basic mode (simple control)
  virtual task send_cfg(amd_cfg_tlp tlp);
    string msg;
    apci_transaction tr = apci_transaction::type_id::create("tr");
    // Error check
    if (!tlp.is_basic)
      `uvm_fatal(get_type_name, "Trying to send a basic cfg transaction in raw mode")
    // AMD->VIP conversion (shim)
    tr.is_write = !tlp.rd;      
    tr.bdf      = tlp.dst_bdf;  
    tr.length   = 1;            
    tr.addr     = tlp.addr;     
    tr.first_be = tlp.be;       
    tr.kind     = APCI_TRANS_cfg;
    if (tlp.ide_stream_id !== 8'hx) begin
      tr.user_ctrl.ide_stream_id = tlp.ide_stream_id;
    end
    tr.payload.push_back(tlp.payload[0]);
    vip.post_transaction(tr);
    tr.wait_enter_vc();
    tr.wait_done();
    // VIP->AMD conversion (un-shim)
    if (tlp.rd) begin
      tlp.payload = '{tr.payload[1]};
      tlp.data    = '{tr.payload[1]};
      if (!tlp.expected_match) begin
        msg = $sformatf("Read data mismatch: expected='b%b, actual=0x%0h",tlp.expected,tlp.payload[0]);
        case (tlp.mismatch_sev)
          UVM_INFO    : `uvm_info   (get_type_name, msg, UVM_LOW)
          UVM_WARNING : `uvm_warning(get_type_name, msg)
          UVM_ERROR   : `uvm_error  (get_type_name, msg)
          UVM_FATAL   : `uvm_fatal  (get_type_name, msg)
        endcase
      end
    end
    // Report non-SC completion status, if required
    case (tr.err_code)
      apci_transaction::OK      : tlp.cpl_sts = CPL_SC;
      apci_transaction::ERROR   : tlp.cpl_sts = CPL_UR; 
      apci_transaction::RETRY   : tlp.cpl_sts = CPL_RRS;
      apci_transaction::ABORTED : tlp.cpl_sts = CPL_CA;
      default                   : tlp.cpl_sts = NO_CPL; 
    endcase 
    if (!tlp.got_SC) begin
      msg = "Completion status was not Successful Completion (SC)"; 
      case (tlp.cpl_sts_sev)
        UVM_INFO    : `uvm_info   (get_type_name, msg, UVM_LOW)
        UVM_WARNING : `uvm_warning(get_type_name, msg)
        UVM_ERROR   : `uvm_error  (get_type_name, msg)
        UVM_FATAL   : `uvm_fatal  (get_type_name, msg)
      endcase
    end
  endtask

  // DESCRIPTION: Send a Cfg TLP specifically in raw mode (full TLP control)
  virtual task send_cfg_raw(amd_cfg_tlp tlp);
    // Error check
    if (tlp.is_basic)
      `uvm_fatal(get_type_name, "Trying to send a raw cfg transaction in basic mode")
    `uvm_fatal(get_type_name, "method not implemented yet")
  endtask

  // DESCRIPTION: Read a capability through an easy to use descriptor and offset 
  // and get a raw DW
  virtual task read_cap_dw(bit [15:0] bdf,
                           pcie_capid_e   cap    = CAP_NULL,
                           pcie_ecapid_e  ecap   = ECAP_NULL, 
                           bit [ 7:0]     offset = 0, //units: DW
                           bit [ 3:0]     be     = '1,
                    output bit [31:0]     data,
                    output bit            err); 
    // Must create handles to all objects
    apci_capability     _h;
    // - caps
    apci_cap_type1      type1;
    apci_cap_null       null_;
    apci_cap_power_mgmt pm;
    apci_cap_vital      vpd;
    apci_cap_msi        msi;
    apci_cap_vendor     vendor;
    apci_cap_msix       msix;
    apci_cap_pcie       pcie;
    // - ecaps
    apci_cap_null_ext                 enull;
    apci_cap_aer                      aer;
    apci_cap_vc                       vc;  
    apci_cap_device_serial            dsn;
    apci_cap_power_budget             pwr_bdgt;
    apci_cap_rc_int_link_ctrl         rc_int_lc;
    apci_cap_mfvc                     mfvc;
    apci_cap_rc_link_declaration      rc_ldecl;
    apci_cap_rcrb                     rcrb;
    apci_cap_vsec                     vsec;
    apci_cap_acs                      acs;
    apci_cap_ats                      ats;
    apci_cap_ari                      ari;
    apci_cap_sriov                    sriov;
    apci_cap_mc                       multic;
    apci_cap_pri                      pri;
    apci_cap_resizable_bar            rsz_bar;
    apci_cap_dpa                      dpa;
    apci_cap_tph                      tph_req;
    apci_cap_secondary_pcie           sec_pcie;
    apci_cap_ltr                      ltr;
    apci_cap_pasid                    pasid;
    apci_cap_dpc                      dpc;
    apci_cap_l1_pm_sub                l1_pm_ss;
    apci_cap_ptm                      ptm;
    apci_cap_dvsec                    dvsec;
    apci_cap_mpcie                    mpcie;
    apci_cap_rtr                      rtr;
    apci_cap_frs_q                    frs_q;
    apci_cap_dl_feature               dl_feat;
    apci_cap_vf_resizable_bar         vf_rsz_bar;
    apci_cap_pl_gen4                  pl_gen4;
    apci_cap_pl_gen5                  pl_gen5;
    apci_cap_pl_gen6                  pl_gen6;
    apci_cap_pl_gen4_margin           ln_mrgn;
    apci_cap_hierarchy_id             hier_id;
    apci_cap_alt_protocol             alt_prot;
    apci_cap_flit_log                 flit_log;
    apci_cap_flit_performance_measure flit_perf;
    apci_cap_flit_err_inject          flit_einj;
    apci_cap_native_pcie              npem;
    apci_cap_doe                      doe;
    apci_cap_device3                  dev3;
    apci_cap_sfi                      sfi;
    apci_cap_svc                      svc;
    apci_cap_ide                      ide;
    // Error check
    if (&{offset>=16, cap==CAP_NULL, ecap==ECAP_NULL})
      `uvm_fatal(get_type_name, "Must specify cap, ecap, or an offset in the common cfg space")
    else if (cap!=CAP_NULL && ecap!=ECAP_NULL)
      `uvm_fatal(get_type_name, "Can only specify one capability or ext. capability")
    // AMD->VIP conversion (shim)
    if (cap!=CAP_NULL) begin
      case (cap)
        CAP_NULL    : begin null_   = new();  _h = null_;  end
        CAP_PCI_PM  : begin pm      = new();  _h = pm;     end
        CAP_VPD     : begin vpd     = new();  _h = vpd;    end
        CAP_MSI     : begin msi     = new();  _h = msi;    end
        CAP_MSI_X   : begin msix    = new();  _h = msix;   end
        CAP_VENDOR  : begin vendor  = new();  _h = vendor; end
        CAP_PCI_EXP : begin pcie    = new();  _h = pcie;   end
        default     : `uvm_fatal(get_type_name, "Unsupported capability type") 
      endcase
    end
    else if (ecap!=ECAP_NULL) begin
      case (ecap)
        //'h0-'hF
        ECAP_NULL           : begin enull     = new();  _h = enull;     end
        ECAP_AER            : begin aer       = new();  _h = aer;       end
        ECAP_VC_N_MFVC      : begin vc        = new();  _h = vc;        end
        ECAP_DSN            : begin dsn       = new();  _h = dsn;       end
        ECAP_PWR_BDGT       : begin pwr_bdgt  = new();  _h = pwr_bdgt;  end
        ECAP_RC_LNK_DECL    : begin rc_ldecl  = new();  _h = rc_ldecl;  end
        ECAP_RC_INT_LNK_CTL : begin rc_int_lc = new();  _h = rc_int_lc; end
        ECAP_MFVC           : begin mfvc      = new();  _h = mfvc;      end
        ECAP_VC_Y_MFVC      : begin vc        = new();  _h = vc;        end
        ECAP_RCRB_HDR       : begin rcrb      = new();  _h = rcrb;      end
        ECAP_VENDOR         : begin vsec      = new();  _h = vsec;      end
        ECAP_ACS            : begin acs       = new();  _h = acs;       end 
        ECAP_ARI            : begin ari       = new();  _h = ari;       end 
        //'h10-'h1F
        ECAP_ATS            : begin ats       = new();  _h = ats;       end 
        ECAP_SRIOV          : begin sriov     = new();  _h = sriov;     end 
        ECAP_MCAST          : begin multic    = new();  _h = multic;    end 
        ECAP_PRI            : begin pri       = new();  _h = pri;       end 
        ECAP_RSZ_BAR        : begin rsz_bar   = new();  _h = rsz_bar;   end 
        ECAP_DPA            : begin dpa       = new();  _h = dpa;       end 
        ECAP_TPH_REQ        : begin tph_req   = new();  _h = tph_req;   end 
        ECAP_LTR            : begin ltr       = new();  _h = ltr;       end 
        ECAP_SEC_PCIE       : begin sec_pcie  = new();  _h = sec_pcie;  end 
        ECAP_PASID          : begin pasid     = new();  _h = pasid;     end 
        ECAP_DPC            : begin dpc       = new();  _h = dpc;       end 
        ECAP_L1_PM_SS       : begin l1_pm_ss  = new();  _h = l1_pm_ss;  end 
        ECAP_PTM            : begin ptm       = new();  _h = ptm;       end 
        //'h20-'h2F
        ECAP_MPHY_PCIE      : begin mpcie     = new();  _h = mpcie;     end 
        ECAP_FRS_Q          : begin frs_q     = new();  _h = frs_q;     end 
        ECAP_RTR            : begin rtr       = new();  _h = rtr;       end 
        ECAP_DVSEC          : begin dvsec     = new();  _h = dvsec;     end 
        ECAP_VF_RSZ_BAR     : begin vf_rsz_bar= new();  _h = vf_rsz_bar;end 
        ECAP_DL_FEAT        : begin dl_feat   = new();  _h = dl_feat;   end 
        ECAP_PL_16GTS       : begin pl_gen4   = new();  _h = pl_gen4;   end 
        ECAP_LN_MRGN        : begin ln_mrgn   = new();  _h = ln_mrgn;   end 
        ECAP_HIER_ID        : begin hier_id   = new();  _h = hier_id;   end 
        ECAP_NPEM           : begin npem      = new();  _h = npem;      end 
        ECAP_PL_32GTS       : begin pl_gen5   = new();  _h = pl_gen5;   end 
        ECAP_ALT_PROT       : begin alt_prot  = new();  _h = alt_prot;  end 
        ECAP_SFI            : begin sfi       = new();  _h = sfi;       end 
        ECAP_DOE            : begin doe       = new();  _h = doe;       end
        ECAP_DEV3           : begin dev3      = new();  _h = dev3;      end 
        //'h30-'h3F
        ECAP_IDE            : begin ide       = new();  _h = ide;       end
        ECAP_PL_64GTS       : begin pl_gen6   = new();  _h = pl_gen6;   end 
        ECAP_FLIT_LOG       : begin flit_log  = new();  _h = flit_log;  end 
        ECAP_FLIT_PERF_MEAS : begin flit_perf = new();  _h = flit_perf; end 
        ECAP_FLIT_ERR_INJ   : begin flit_einj = new();  _h = flit_einj; end 
        ECAP_STRMLN_VC      : begin svc       = new();  _h = svc;       end
        default             : `uvm_fatal(get_type_name, "Unsupported ext. capability type") 
      endcase
    end
    else begin
      // Confirmed: Type1 will still send across link if necessary
      type1 = new(); _h = type1;
    end
    _h.configure();
    vip.read_capability(bdf, _h, offset, err, .first_be(be)); 
    data = _h.get_dword(offset);
  endtask

  // DESCRIPTION: Write a capability through an easy to use descriptor and offset
  // and provide a raw DW
  virtual task write_cap_dw(bit [15:0]     bdf,
                            pcie_capid_e   cap    = CAP_NULL,
                            pcie_ecapid_e  ecap   = ECAP_NULL, 
                            bit [ 7:0]     offset = 0, //units=DW
                            bit [ 3:0]     be     = '1,
                            bit [31:0]     data,
                     output bit            err); 
    // Must create handles to all objects
    apci_capability     _h;
    // - caps
    apci_cap_type1      type1;
    apci_cap_null       null_;
    apci_cap_power_mgmt pm;
    apci_cap_vital      vpd;
    apci_cap_msi        msi;
    apci_cap_vendor     vendor;
    apci_cap_msix       msix;
    apci_cap_pcie       pcie;
    // - ecaps
    apci_cap_null_ext                 enull;
    apci_cap_aer                      aer;
    apci_cap_vc                       vc;  
    apci_cap_device_serial            dsn;
    apci_cap_power_budget             pwr_bdgt;
    apci_cap_rc_int_link_ctrl         rc_int_lc;
    apci_cap_mfvc                     mfvc;
    apci_cap_rc_link_declaration      rc_ldecl;
    apci_cap_rcrb                     rcrb;
    apci_cap_vsec                     vsec;
    apci_cap_acs                      acs;
    apci_cap_ats                      ats;
    apci_cap_ari                      ari;
    apci_cap_sriov                    sriov;
    apci_cap_mc                       multic;
    apci_cap_pri                      pri;
    apci_cap_resizable_bar            rsz_bar;
    apci_cap_dpa                      dpa;
    apci_cap_tph                      tph_req;
    apci_cap_secondary_pcie           sec_pcie;
    apci_cap_ltr                      ltr;
    apci_cap_pasid                    pasid;
    apci_cap_dpc                      dpc;
    apci_cap_l1_pm_sub                l1_pm_ss;
    apci_cap_ptm                      ptm;
    apci_cap_dvsec                    dvsec;
    apci_cap_mpcie                    mpcie;
    apci_cap_rtr                      rtr;
    apci_cap_frs_q                    frs_q;
    apci_cap_dl_feature               dl_feat;
    apci_cap_vf_resizable_bar         vf_rsz_bar;
    apci_cap_pl_gen4                  pl_gen4;
    apci_cap_pl_gen5                  pl_gen5;
    apci_cap_pl_gen6                  pl_gen6;
    apci_cap_pl_gen4_margin           ln_mrgn;
    apci_cap_hierarchy_id             hier_id;
    apci_cap_alt_protocol             alt_prot;
    apci_cap_flit_log                 flit_log;
    apci_cap_flit_performance_measure flit_perf;
    apci_cap_flit_err_inject          flit_einj;
    apci_cap_native_pcie              npem;
    apci_cap_doe                      doe;
    apci_cap_device3                  dev3;
    apci_cap_sfi                      sfi;
    apci_cap_svc                      svc;
    apci_cap_ide                      ide;
    // Error check
    if (&{offset>=16, cap==CAP_NULL, ecap==ECAP_NULL})
      `uvm_fatal(get_type_name, "Must specify cap, ecap, or an offset in the common cfg space")
    else if (cap!=CAP_NULL && ecap!=ECAP_NULL)
      `uvm_fatal(get_type_name, "Can only specify one capability or ext. capability")
    // AMD->VIP conversion (shim)
    if (cap!=CAP_NULL) begin
      case (cap)
        CAP_NULL    : begin null_   = new();  _h = null_;  end
        CAP_PCI_PM  : begin pm      = new();  _h = pm;     end
        CAP_VPD     : begin vpd     = new();  _h = vpd;    end
        CAP_MSI     : begin msi     = new();  _h = msi;    end
        CAP_MSI_X   : begin msix    = new();  _h = msix;   end
        CAP_VENDOR  : begin vendor  = new();  _h = vendor; end
        CAP_PCI_EXP : begin pcie    = new();  _h = pcie;   end
        default     : `uvm_fatal(get_type_name, "Unsupported capability type") 
      endcase
    end
    else if (ecap!=ECAP_NULL) begin
      case (ecap)
        //'h0-'hF
        ECAP_NULL           : begin enull     = new();  _h = enull;     end
        ECAP_AER            : begin aer       = new();  _h = aer;       end
        ECAP_VC_N_MFVC      : begin vc        = new();  _h = vc;        end
        ECAP_DSN            : begin dsn       = new();  _h = dsn;       end
        ECAP_PWR_BDGT       : begin pwr_bdgt  = new();  _h = pwr_bdgt;  end
        ECAP_RC_LNK_DECL    : begin rc_ldecl  = new();  _h = rc_ldecl;  end
        ECAP_RC_INT_LNK_CTL : begin rc_int_lc = new();  _h = rc_int_lc; end
        ECAP_MFVC           : begin mfvc      = new();  _h = mfvc;      end
        ECAP_VC_Y_MFVC      : begin vc        = new();  _h = vc;        end
        ECAP_RCRB_HDR       : begin rcrb      = new();  _h = rcrb;      end
        ECAP_VENDOR         : begin vsec      = new();  _h = vsec;      end
        ECAP_ACS            : begin acs       = new();  _h = acs;       end 
        ECAP_ARI            : begin ari       = new();  _h = ari;       end 
        //'h10-'h1F
        ECAP_ATS            : begin ats       = new();  _h = ats;       end 
        ECAP_SRIOV          : begin sriov     = new();  _h = sriov;     end 
        ECAP_MCAST          : begin multic    = new();  _h = multic;    end 
        ECAP_PRI            : begin pri       = new();  _h = pri;       end 
        ECAP_RSZ_BAR        : begin rsz_bar   = new();  _h = rsz_bar;   end 
        ECAP_DPA            : begin dpa       = new();  _h = dpa;       end 
        ECAP_TPH_REQ        : begin tph_req   = new();  _h = tph_req;   end 
        ECAP_LTR            : begin ltr       = new();  _h = ltr;       end 
        ECAP_SEC_PCIE       : begin sec_pcie  = new();  _h = sec_pcie;  end 
        ECAP_PASID          : begin pasid     = new();  _h = pasid;     end 
        ECAP_DPC            : begin dpc       = new();  _h = dpc;       end 
        ECAP_L1_PM_SS       : begin l1_pm_ss  = new();  _h = l1_pm_ss;  end 
        ECAP_PTM            : begin ptm       = new();  _h = ptm;       end 
        //'h20-'h2F
        ECAP_MPHY_PCIE      : begin mpcie     = new();  _h = mpcie;     end 
        ECAP_FRS_Q          : begin frs_q     = new();  _h = frs_q;     end 
        ECAP_RTR            : begin rtr       = new();  _h = rtr;       end 
        ECAP_DVSEC          : begin dvsec     = new();  _h = dvsec;     end 
        ECAP_VF_RSZ_BAR     : begin vf_rsz_bar= new();  _h = vf_rsz_bar;end 
        ECAP_DL_FEAT        : begin dl_feat   = new();  _h = dl_feat;   end 
        ECAP_PL_16GTS       : begin pl_gen4   = new();  _h = pl_gen4;   end 
        ECAP_LN_MRGN        : begin ln_mrgn   = new();  _h = ln_mrgn;   end 
        ECAP_HIER_ID        : begin hier_id   = new();  _h = hier_id;   end 
        ECAP_NPEM           : begin npem      = new();  _h = npem;      end 
        ECAP_PL_32GTS       : begin pl_gen5   = new();  _h = pl_gen5;   end 
        ECAP_ALT_PROT       : begin alt_prot  = new();  _h = alt_prot;  end 
        ECAP_SFI            : begin sfi       = new();  _h = sfi;       end 
        ECAP_DOE            : begin doe       = new();  _h = doe;       end
        ECAP_DEV3           : begin dev3      = new();  _h = dev3;      end 
        //'h30-'h3F
        ECAP_IDE            : begin ide       = new();  _h = ide;       end
        ECAP_PL_64GTS       : begin pl_gen6   = new();  _h = pl_gen6;   end 
        ECAP_FLIT_LOG       : begin flit_log  = new();  _h = flit_log;  end 
        ECAP_FLIT_PERF_MEAS : begin flit_perf = new();  _h = flit_perf; end 
        ECAP_FLIT_ERR_INJ   : begin flit_einj = new();  _h = flit_einj; end 
        ECAP_STRMLN_VC      : begin svc       = new();  _h = svc;       end
        default             : `uvm_fatal(get_type_name, "Unsupported ext. capability type") 
      endcase
    end
    else begin
      // Confirmed: Type1 will still send across link if necessary
      type1 = new(); _h = type1;
    end
    _h.configure();
    _h.set_dword(offset, data, be);
    vip.write_capability(bdf, _h, offset, err, .first_be(be)); 
  endtask

  // DESCRIPTION: Read a capability given a capability object
  virtual task read_cap(bit [15:0]     bdf,
                        cap_foundation cap,
                        bit [ 7:0]     offset = 0, //units: DW
                        bit [ 7:0]     num_dw = 1, //total, from offset
                 output bit            err); 
    bit [7:0] dw_cnt;
    bit       temp_err;
    // AMD capability bases
    cap_base  _cap;
    ecap_base _ecap;
    // Must create handles to all objects
    apci_capability     _h;
    // - caps
    apci_cap_type1      type1;
    apci_cap_null       null_;
    apci_cap_power_mgmt pm;
    apci_cap_vital      vpd;
    apci_cap_msi        msi;
    apci_cap_vendor     vendor;
    apci_cap_msix       msix;
    apci_cap_pcie       pcie;
    // - ecaps
    apci_cap_null_ext                 enull;
    apci_cap_aer                      aer;
    apci_cap_vc                       vc;  
    apci_cap_device_serial            dsn;
    apci_cap_power_budget             pwr_bdgt;
    apci_cap_rc_int_link_ctrl         rc_int_lc;
    apci_cap_mfvc                     mfvc;
    apci_cap_rc_link_declaration      rc_ldecl;
    apci_cap_rcrb                     rcrb;
    apci_cap_vsec                     vsec;
    apci_cap_acs                      acs;
    apci_cap_ats                      ats;
    apci_cap_ari                      ari;
    apci_cap_sriov                    sriov;
    apci_cap_mc                       multic;
    apci_cap_pri                      pri;
    apci_cap_resizable_bar            rsz_bar;
    apci_cap_dpa                      dpa;
    apci_cap_tph                      tph_req;
    apci_cap_secondary_pcie           sec_pcie;
    apci_cap_ltr                      ltr;
    apci_cap_pasid                    pasid;
    apci_cap_dpc                      dpc;
    apci_cap_l1_pm_sub                l1_pm_ss;
    apci_cap_ptm                      ptm;
    apci_cap_dvsec                    dvsec;
    apci_cap_mpcie                    mpcie;
    apci_cap_rtr                      rtr;
    apci_cap_frs_q                    frs_q;
    apci_cap_dl_feature               dl_feat;
    apci_cap_vf_resizable_bar         vf_rsz_bar;
    apci_cap_pl_gen4                  pl_gen4;
    apci_cap_pl_gen5                  pl_gen5;
    apci_cap_pl_gen6                  pl_gen6;
    apci_cap_pl_gen4_margin           ln_mrgn;
    apci_cap_hierarchy_id             hier_id;
    apci_cap_alt_protocol             alt_prot;
    apci_cap_flit_log                 flit_log;
    apci_cap_flit_performance_measure flit_perf;
    apci_cap_flit_err_inject          flit_einj;
    apci_cap_native_pcie              npem;
    apci_cap_doe                      doe;
    apci_cap_device3                  dev3;
    apci_cap_sfi                      sfi;
    apci_cap_svc                      svc;
    // AMD->VIP conversion (shim)
    if ($cast(_cap,cap)) begin 
      if (_cap.cap_id.name=="")
        `uvm_fatal(get_type_name, "Unsupported cap.cap_id assignment")
      case (_cap.cap_id)
        CAP_NULL    : `uvm_fatal(get_type_name, "Cannot have cap.cap_id==CAP_NULL")    
        CAP_PCI_PM  : begin pm      = new();  _h = pm;     end
        CAP_VPD     : begin vpd     = new();  _h = vpd;    end
        CAP_MSI     : begin msi     = new();  _h = msi;    end
        CAP_MSI_X   : begin msix    = new();  _h = msix;   end
        CAP_VENDOR  : begin vendor  = new();  _h = vendor; end 
        CAP_PCI_EXP : begin pcie    = new();  _h = pcie;   end
        /* other caps */
        default : `uvm_fatal(get_type_name, "Unsupported capability type")
      endcase
    end
    else if ($cast(_ecap,cap)) begin
      if (_ecap.cap_id.name=="")
        `uvm_fatal(get_type_name, "Unsupported cap.cap_id assignment")
      case (_ecap.cap_id)
        ECAP_NULL           : `uvm_fatal(get_type_name, "Cannot have cap.cap_id==ECAP_NULL")
        ECAP_AER            : begin aer       = new();  _h = aer;       end
        ECAP_VC_N_MFVC      : begin vc        = new();  _h = vc;        end
        ECAP_DSN            : begin dsn       = new();  _h = dsn;       end
        ECAP_PWR_BDGT       : begin pwr_bdgt  = new();  _h = pwr_bdgt;  end
        ECAP_RC_LNK_DECL    : begin rc_ldecl  = new();  _h = rc_ldecl;  end
        ECAP_RC_INT_LNK_CTL : begin rc_int_lc = new();  _h = rc_int_lc; end
        ECAP_MFVC           : begin mfvc      = new();  _h = mfvc;      end
        ECAP_VC_Y_MFVC      : begin vc        = new();  _h = vc;        end
        ECAP_RCRB_HDR       : begin rcrb      = new();  _h = rcrb;      end
        ECAP_VENDOR         : begin vsec      = new();  _h = vsec;      end
        ECAP_ACS            : begin acs       = new();  _h = acs;       end 
        ECAP_ARI            : begin ari       = new();  _h = ari;       end 
        ECAP_ATS            : begin ats       = new();  _h = ats;       end 
        ECAP_SRIOV          : begin sriov     = new();  _h = sriov;     end 
        ECAP_MCAST          : begin multic    = new();  _h = multic;    end 
        ECAP_PRI            : begin pri       = new();  _h = pri;       end 
        ECAP_RSZ_BAR        : begin rsz_bar   = new();  _h = rsz_bar;   end 
        ECAP_DPA            : begin dpa       = new();  _h = dpa;       end 
        ECAP_TPH_REQ        : begin tph_req   = new();  _h = tph_req;   end 
        ECAP_LTR            : begin ltr       = new();  _h = ltr;       end 
        ECAP_SEC_PCIE       : begin sec_pcie  = new();  _h = sec_pcie;  end 
        ECAP_PASID          : begin pasid     = new();  _h = pasid;     end 
        ECAP_DPC            : begin dpc       = new();  _h = dpc;       end 
        ECAP_L1_PM_SS       : begin l1_pm_ss  = new();  _h = l1_pm_ss;  end 
        ECAP_PTM            : begin ptm       = new();  _h = ptm;       end 
        ECAP_MPHY_PCIE      : begin mpcie     = new();  _h = mpcie;     end 
        ECAP_FRS_Q          : begin frs_q     = new();  _h = frs_q;     end 
        ECAP_RTR            : begin rtr       = new();  _h = rtr;       end 
        ECAP_DVSEC          : begin dvsec     = new();  _h = dvsec;     end 
        ECAP_VF_RSZ_BAR     : begin vf_rsz_bar= new();  _h = vf_rsz_bar;end 
        ECAP_DL_FEAT        : begin dl_feat   = new();  _h = dl_feat;   end 
        ECAP_PL_16GTS       : begin pl_gen4   = new();  _h = pl_gen4;   end 
        ECAP_LN_MRGN        : begin ln_mrgn   = new();  _h = ln_mrgn;   end 
        ECAP_HIER_ID        : begin hier_id   = new();  _h = hier_id;   end 
        ECAP_NPEM           : begin npem      = new();  _h = npem;      end 
        ECAP_PL_32GTS       : begin pl_gen5   = new();  _h = pl_gen5;   end 
        ECAP_ALT_PROT       : begin alt_prot  = new();  _h = alt_prot;  end 
        ECAP_SFI            : begin sfi       = new();  _h = sfi;       end 
        ECAP_DOE            : begin doe       = new();  _h = doe;       end
        ECAP_DEV3           : begin dev3      = new();  _h = dev3;      end 
        ECAP_PL_64GTS       : begin pl_gen6   = new();  _h = pl_gen6;   end 
        ECAP_FLIT_LOG       : begin flit_log  = new();  _h = flit_log;  end 
        ECAP_FLIT_PERF_MEAS : begin flit_perf = new();  _h = flit_perf; end 
        ECAP_FLIT_ERR_INJ   : begin flit_einj = new();  _h = flit_einj; end 
        ECAP_STRMLN_VC      : begin svc       = new();  _h = svc;       end
        default             : `uvm_fatal(get_type_name, "Unsupported ext. capability type") 
      endcase
    end
    _h.configure();
    // Perform N reads using the VIP API so we may populate our shim object
    repeat (num_dw) begin
      vip.read_capability(bdf, _h, offset+dw_cnt, temp_err);
      err |= temp_err;
      dw_cnt++;
    end
    // VIP->AMD conversion (un-shim)
    repeat(num_dw) begin
      dw_cnt--;
      cap.set_dw (offset+dw_cnt, _h.get_dword(offset+dw_cnt));
    end
  endtask

  // DESCRIPTION: Write a capability given a capability object
  //  - FEATURE : If a bit in a DW is 1'bx, we assume that means
  //              a user does not want to modify it, so a user 
  //              can perform RdModWr operations with one API.
  virtual task write_cap(bit [15:0]     bdf,
                         cap_foundation cap,
                         bit [ 7:0]     offset = 0, //units: DW
                         bit [ 7:0]     num_dw = 1, //total, from offset
                  output bit            err); 
    bit   [ 7:0] dw_cnt;
    bit          temp_err;
    bit   [31:0] rd_dw;
    logic [ 7:0] mod_byte;
    logic [ 3:0] fbe;
    // AMD capability bases
    cap_base  _cap;
    ecap_base _ecap;
    // Must create handles to all objects
    apci_capability     _h;
    // - caps
    apci_cap_type1      type1;
    apci_cap_null       null_;
    apci_cap_power_mgmt pm;
    apci_cap_vital      vpd;
    apci_cap_msi        msi;
    apci_cap_vendor     vendor;
    apci_cap_msix       msix;
    apci_cap_pcie       pcie;
    // - ecaps
    apci_cap_null_ext                 enull;
    apci_cap_aer                      aer;
    apci_cap_vc                       vc;  
    apci_cap_device_serial            dsn;
    apci_cap_power_budget             pwr_bdgt;
    apci_cap_rc_int_link_ctrl         rc_int_lc;
    apci_cap_mfvc                     mfvc;
    apci_cap_rc_link_declaration      rc_ldecl;
    apci_cap_rcrb                     rcrb;
    apci_cap_vsec                     vsec;
    apci_cap_acs                      acs;
    apci_cap_ats                      ats;
    apci_cap_ari                      ari;
    apci_cap_sriov                    sriov;
    apci_cap_mc                       multic;
    apci_cap_pri                      pri;
    apci_cap_resizable_bar            rsz_bar;
    apci_cap_dpa                      dpa;
    apci_cap_tph                      tph_req;
    apci_cap_secondary_pcie           sec_pcie;
    apci_cap_ltr                      ltr;
    apci_cap_pasid                    pasid;
    apci_cap_dpc                      dpc;
    apci_cap_l1_pm_sub                l1_pm_ss;
    apci_cap_ptm                      ptm;
    apci_cap_dvsec                    dvsec;
    apci_cap_mpcie                    mpcie;
    apci_cap_rtr                      rtr;
    apci_cap_frs_q                    frs_q;
    apci_cap_dl_feature               dl_feat;
    apci_cap_vf_resizable_bar         vf_rsz_bar;
    apci_cap_pl_gen4                  pl_gen4;
    apci_cap_pl_gen5                  pl_gen5;
    apci_cap_pl_gen6                  pl_gen6;
    apci_cap_pl_gen4_margin           ln_mrgn;
    apci_cap_hierarchy_id             hier_id;
    apci_cap_alt_protocol             alt_prot;
    apci_cap_flit_log                 flit_log;
    apci_cap_flit_performance_measure flit_perf;
    apci_cap_flit_err_inject          flit_einj;
    apci_cap_native_pcie              npem;
    apci_cap_device3                  dev3;
    apci_cap_sfi                      sfi;
    apci_cap_svc                      svc;
    // AMD->VIP conversion (shim)
    if ($cast(_cap,cap)) begin 
      if (_cap.cap_id.name=="")
        `uvm_fatal(get_type_name, "Unsupported cap.cap_id assignment")
      case (_cap.cap_id)
        CAP_NULL    : `uvm_fatal(get_type_name, "Cannot have cap.cap_id==CAP_NULL")    
        CAP_PCI_PM  : begin pm      = new();  _h = pm;     end
        CAP_VPD     : begin vpd     = new();  _h = vpd;    end
        CAP_MSI     : begin msi     = new();  _h = msi;    end
        CAP_MSI_X   : begin msix    = new();  _h = msix;   end
        CAP_VENDOR  : begin vendor  = new();  _h = vendor; end 
        CAP_PCI_EXP : begin pcie    = new();  _h = pcie;   end
        /* other caps */
        default : `uvm_fatal(get_type_name, "Unsupported capability type")
      endcase
    end
    else if ($cast(_ecap,cap)) begin
      if (_ecap.cap_id.name=="")
        `uvm_fatal(get_type_name, "Unsupported cap.cap_id assignment")
      case (_ecap.cap_id)
        ECAP_NULL           : `uvm_fatal(get_type_name, "Cannot have cap.cap_id==ECAP_NULL")
        ECAP_AER            : begin aer       = new();  _h = aer;       end
        ECAP_VC_N_MFVC      : begin vc        = new();  _h = vc;        end
        ECAP_DSN            : begin dsn       = new();  _h = dsn;       end
        ECAP_PWR_BDGT       : begin pwr_bdgt  = new();  _h = pwr_bdgt;  end
        ECAP_RC_LNK_DECL    : begin rc_ldecl  = new();  _h = rc_ldecl;  end
        ECAP_RC_INT_LNK_CTL : begin rc_int_lc = new();  _h = rc_int_lc; end
        ECAP_MFVC           : begin mfvc      = new();  _h = mfvc;      end
        ECAP_VC_Y_MFVC      : begin vc        = new();  _h = vc;        end
        ECAP_RCRB_HDR       : begin rcrb      = new();  _h = rcrb;      end
        ECAP_VENDOR         : begin vsec      = new();  _h = vsec;      end
        ECAP_ACS            : begin acs       = new();  _h = acs;       end 
        ECAP_ARI            : begin ari       = new();  _h = ari;       end 
        ECAP_ATS            : begin ats       = new();  _h = ats;       end 
        ECAP_SRIOV          : begin sriov     = new();  _h = sriov;     end 
        ECAP_MCAST          : begin multic    = new();  _h = multic;    end 
        ECAP_PRI            : begin pri       = new();  _h = pri;       end 
        ECAP_RSZ_BAR        : begin rsz_bar   = new();  _h = rsz_bar;   end 
        ECAP_DPA            : begin dpa       = new();  _h = dpa;       end 
        ECAP_TPH_REQ        : begin tph_req   = new();  _h = tph_req;   end 
        ECAP_LTR            : begin ltr       = new();  _h = ltr;       end 
        ECAP_SEC_PCIE       : begin sec_pcie  = new();  _h = sec_pcie;  end 
        ECAP_PASID          : begin pasid     = new();  _h = pasid;     end 
        ECAP_DPC            : begin dpc       = new();  _h = dpc;       end 
        ECAP_L1_PM_SS       : begin l1_pm_ss  = new();  _h = l1_pm_ss;  end 
        ECAP_PTM            : begin ptm       = new();  _h = ptm;       end 
        ECAP_MPHY_PCIE      : begin mpcie     = new();  _h = mpcie;     end 
        ECAP_FRS_Q          : begin frs_q     = new();  _h = frs_q;     end 
        ECAP_RTR            : begin rtr       = new();  _h = rtr;       end 
        ECAP_DVSEC          : begin dvsec     = new();  _h = dvsec;     end 
        ECAP_VF_RSZ_BAR     : begin vf_rsz_bar= new();  _h = vf_rsz_bar;end 
        ECAP_DL_FEAT        : begin dl_feat   = new();  _h = dl_feat;   end 
        ECAP_PL_16GTS       : begin pl_gen4   = new();  _h = pl_gen4;   end 
        ECAP_LN_MRGN        : begin ln_mrgn   = new();  _h = ln_mrgn;   end 
        ECAP_HIER_ID        : begin hier_id   = new();  _h = hier_id;   end 
        ECAP_NPEM           : begin npem      = new();  _h = npem;      end 
        ECAP_PL_32GTS       : begin pl_gen5   = new();  _h = pl_gen5;   end 
        ECAP_ALT_PROT       : begin alt_prot  = new();  _h = alt_prot;  end 
        ECAP_SFI            : begin sfi       = new();  _h = sfi;       end 
        ECAP_DEV3           : begin dev3      = new();  _h = dev3;      end 
        ECAP_PL_64GTS       : begin pl_gen6   = new();  _h = pl_gen6;   end 
        ECAP_FLIT_LOG       : begin flit_log  = new();  _h = flit_log;  end 
        ECAP_FLIT_PERF_MEAS : begin flit_perf = new();  _h = flit_perf; end 
        ECAP_FLIT_ERR_INJ   : begin flit_einj = new();  _h = flit_einj; end 
        ECAP_STRMLN_VC      : begin svc       = new();  _h = svc;       end 
        default             : `uvm_fatal(get_type_name, "Unsupported ext. capability type") 
      endcase
    end
    _h.configure();
    // Perform N writes using the VIP API 
    repeat (num_dw) begin
      if (cap.get_dw(offset+dw_cnt)==='x) begin
        dw_cnt++;
        continue;
      end
      // fbe[n]=1 //the entire byte is being modified (_cap.data.dws[n][m]=0,1)
      // fbe[n]=0 //the entire byte is not being modified (_cap.data.dws[n][m]=x)
      // fbe[n]=x //some of the byte is being modified (_cap.data.dws[n][m]=0,1,x)->RdModWr
      fbe = 'x;
      for (int ii=0; ii<4; ii++) begin
        case (1'b1)
          ($countbits(cap.get_byte((offset+dw_cnt)*4+ii),'x)   ==8) : fbe[ii] = 1'b0;
          ($countbits(cap.get_byte((offset+dw_cnt)*4+ii),'1,'0)==8) : fbe[ii] = 1'b1;
        endcase
      end
      // If there are mixed use bytes, we must RdModWr 
      if ($countbits(fbe, 'x)) begin
        case (1'b1)
          _cap !=null : read_cap_dw(bdf, .cap(_cap.cap_id),   .offset(offset+dw_cnt), .data(rd_dw), .err(temp_err));
          _ecap!=null : read_cap_dw(bdf, .ecap(_ecap.cap_id), .offset(offset+dw_cnt), .data(rd_dw), .err(temp_err));
        endcase
        err |= temp_err;
        foreach (fbe[ii]) begin
          if (fbe[ii]===1'bx) begin
            fbe[ii] = 1'b1;
            mod_byte = cap.get_byte((offset+dw_cnt)*4+ii);
            foreach (mod_byte[bb])
              rd_dw[ii*8+bb] = mod_byte[bb]===1'bx ? rd_dw[ii*8+bb] : mod_byte[bb];
          end
        end
        _h.set_dword(offset, rd_dw, fbe);
      end
      vip.write_capability(bdf, _h, offset+dw_cnt, temp_err, .first_be(fbe));
      err |= temp_err;
      dw_cnt++;
    end
  endtask

endclass
