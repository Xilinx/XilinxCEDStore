class elbi_monitor#(type CFG, type VIF, type TXN, type SHR) extends base_monitor#(CFG,VIF,TXN,SHR);

  `uvm_component_param_utils(elbi_monitor#(CFG,VIF,TXN,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"elbi_monitor#(",
                                   CFG::type_name,",",
                                   "VIF,",
                                   TXN::type_name,",",
                                   SHR::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    base_txn btxn[0:2];
    TXN      reqt = TXN::type_id::create("reqt");
    TXN      rspt = TXN::type_id::create("rspt");
    TXN      cmbt = TXN::type_id::create("cmbt");

    // constants
    reqt.req             = 1'b1;
    rspt.rsp             = 1'b1;
    {cmbt.req, cmbt.rsp} = 2'b11;
    reqt.uid             = cfg.uid;
    rspt.uid             = cfg.uid;
    cmbt.uid             = cfg.uid;

    // give uid to share object as well
    shr.uid = cfg.uid;

    // assign to base handles
    btxn[0] = reqt;
    btxn[1] = rspt;
    btxn[2] = cmbt;
  
    // NOTE 
    // This assumes one outstanding txn on ELBI interface, not one per function.
    fork
      // requests only
      forever begin
        @(posedge vif.clk iff vif.req_trigger);
        reqt.lbc_ext_addr             = vif.lbc_ext_addr;
        reqt.lbc_ext_dout             = vif.lbc_ext_dout;
        reqt.lbc_ext_valid            = vif.lbc_ext_valid;
        reqt.lbc_ext_cs               = vif.lbc_ext_cs;
        reqt.lbc_ext_wr               = vif.lbc_ext_wr;
        reqt.lbc_ext_rd               = vif.lbc_ext_rd;
        reqt.lbc_ext_dbi_access       = vif.lbc_ext_dbi_access;
        reqt.lbc_ext_cxl_mbar0_access = vif.lbc_ext_cxl_mbar0_access;
        reqt.lbc_ext_rom_access       = vif.lbc_ext_rom_access;
        reqt.lbc_ext_io_access        = vif.lbc_ext_io_access;
        reqt.lbc_ext_bar_num          = vif.lbc_ext_bar_num;
        reqt.lbc_ext_vfunc_num        = vif.lbc_ext_vfunc_num;
        reqt.lbc_ext_vfunc_active     = vif.lbc_ext_vfunc_active;
        // Broadcast
        ap.write(reqt);
        base_ap.write(btxn[0]);
        // Must wait for response to avoid re-entrance if required 
        repeat (|reqt.lbc_ext_cs) @(posedge vif.clk iff vif.rsp_trigger);
      end
      // responses only
      forever begin
        @(posedge vif.clk iff vif.rsp_trigger);
        rspt.ext_lbc_override_en = vif.ext_lbc_override_en;
        rspt.ext_lbc_ack         = vif.ext_lbc_ack;
        rspt.ext_lbc_din         = vif.ext_lbc_din;
        // Broadcast
        ap.write(rspt);
        base_ap.write(btxn[1]);
      end
      // requests and respones
      forever begin
        @(posedge vif.clk iff vif.req_trigger);
        cmbt.lbc_ext_addr             = vif.lbc_ext_addr;
        cmbt.lbc_ext_dout             = vif.lbc_ext_dout;
        cmbt.lbc_ext_valid            = vif.lbc_ext_valid;
        cmbt.lbc_ext_cs               = vif.lbc_ext_cs;
        cmbt.lbc_ext_wr               = vif.lbc_ext_wr;
        cmbt.lbc_ext_rd               = vif.lbc_ext_rd;
        cmbt.lbc_ext_dbi_access       = vif.lbc_ext_dbi_access;
        cmbt.lbc_ext_cxl_mbar0_access = vif.lbc_ext_cxl_mbar0_access;
        cmbt.lbc_ext_rom_access       = vif.lbc_ext_rom_access;
        cmbt.lbc_ext_io_access        = vif.lbc_ext_io_access;
        cmbt.lbc_ext_bar_num          = vif.lbc_ext_bar_num;
        cmbt.lbc_ext_vfunc_num        = vif.lbc_ext_vfunc_num;
        cmbt.lbc_ext_vfunc_active     = vif.lbc_ext_vfunc_active;
        // If not externally targeted, need to check if override
        if (!cmbt.lbc_ext_cs) begin
          @(posedge vif.clk); 
          cmbt.ext_lbc_override_en = vif.ext_lbc_override_en;
          if (!cmbt.ext_lbc_override_en) continue;
        end
        @(posedge vif.clk iff vif.rsp_trigger);
        cmbt.ext_lbc_override_en = vif.ext_lbc_override_en;
        cmbt.ext_lbc_ack         = vif.ext_lbc_ack;
        cmbt.ext_lbc_din         = vif.ext_lbc_din;
        // Broadcast
        ap.write(cmbt);
        base_ap.write(btxn[2]);
      end
    join_none
  endtask

endclass
