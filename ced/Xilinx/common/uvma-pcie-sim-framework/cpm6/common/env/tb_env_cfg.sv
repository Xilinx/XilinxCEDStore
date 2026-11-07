class tb_env_cfg extends uvm_object;

  `uvm_object_utils(tb_env_cfg)

  function new(string name = "tb_env_cfg");
    super.new(name);
  endfunction

  // ***************************************************
  // ISR end-of-sim control and reporting
  // ***************************************************
  //0=misc, 1=uncorr, 2=corr | 0=info, 1=warn, 2=error, 3=ignore
  bit [1:0]      pl_isr_final[0:2] = '{default: 1}; 
  bit [1:0]      ps_isr_final[0:2] = '{default: 1}; 
  // Controls when to check an IRQ line after an ISR has
  // been triggered; this is necessary because IRQs are
  // coalesced and multiple IRQs can trigger the same line
  // and will be missed if just one line is edge triggerd
  time pl_isr_recheck_time = 1us;
  time ps_isr_recheck_time = 1us;

  // ***************************************************
  // Control optional agent creation and configuration
  // ***************************************************
  // --- CXL --- 
  agent_mode_t   cxl_nfi_agnt_tx[0:1];
  agent_mode_t   cxl_nfi_agnt_rx[0:1];
  agent_mode_t   cxl_cfgsts_agnt[0:1];
  agent_mode_t   cxl_pm_in_agnt [0:1];
  agent_mode_t   cxl_pm_out_agnt[0:1];
  agent_mode_t   cxl_credit_agnt_tx[0:1];
  agent_mode_t   cxl_credit_agnt_rx[0:1];
  // --- ANY --- 
  agent_mode_t   elbi_agnt[0:1];
  agent_mode_t   ps_isr_agnt;
  agent_mode_t   pl_isr_agnt;
  // --- AXI --- 
`ifdef CPM6_RTL
  agent_mode_t   axi_mst_agnt[0:4];
  agent_mode_t   axi_slv_agnt[0:5];
`else
  agent_mode_t   cpm_pl_m_axi_agnt[0:3];
  agent_mode_t   cpm_pl_s_axi_agnt;
  agent_mode_t   cpm_noc_m_axi_agnt[0:1];
  agent_mode_t   cpm_noc_s_axi_agnt;
`endif

  // Print the summary
  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    for (int ii=0; ii<2; ii++) begin
      printer.print_string($sformatf("Controller %0d", ii), {12{"-"}});
      printer.m_scope.down(""); //increase indent
      printer.print_string("cxl_nfi_agnt_tx",    cxl_nfi_agnt_tx[ii].name);
      printer.print_string("cxl_nfi_agnt_rx",    cxl_nfi_agnt_rx[ii].name);
      printer.print_string("cxl_cfgsts_agnt",    cxl_cfgsts_agnt[ii].name);
      printer.print_string("cxl_pm_in_agnt",     cxl_pm_in_agnt[ii].name);
      printer.print_string("cxl_pm_out_agnt",    cxl_pm_out_agnt[ii].name);
      printer.print_string("cxl_credit_agnt_tx", cxl_credit_agnt_tx[ii].name);
      printer.print_string("cxl_credit_agnt_rx", cxl_credit_agnt_rx[ii].name);
      printer.print_string("elbi_agnt",          elbi_agnt[ii].name);
      printer.m_scope.up(); //decrease indent
    end
    printer.print_string("AXI Agents", {12{"-"}});
    printer.m_scope.down(""); //increase indent
`ifdef CPM6_RTL
    foreach (axi_mst_agnt[mm])
      printer.print_string($sformatf("axi_mst_agnt[%0d]",mm), axi_mst_agnt[mm].name);
    foreach (axi_slv_agnt[ss])
      printer.print_string($sformatf("axi_slv_agnt[%0d]",ss), axi_slv_agnt[ss].name);
`else
    foreach (cpm_pl_m_axi_agnt[ss])
      printer.print_string($sformatf("cpm_pl_m_axi_agnt[%0d]",ss), cpm_pl_m_axi_agnt[ss].name);
    printer.print_string("cpm_pl_s_axi_agnt", cpm_pl_s_axi_agnt.name);
    foreach (cpm_noc_m_axi_agnt[ss])
      printer.print_string($sformatf("cpm_noc_m_axi_agnt[%0d]",ss), cpm_noc_m_axi_agnt[ss].name);
    printer.print_string("cpm_noc_s_axi_agnt", cpm_noc_s_axi_agnt.name);
`endif
    printer.m_scope.up(); //decrease indent
    printer.print_string("ISRs", {12{"-"}});
    printer.m_scope.down(""); //increase indent
    printer.print_string("pl_isr_agnt", pl_isr_agnt.name);
    if (pl_isr_agnt == ACTIVE_AGNT) begin
      printer.m_scope.down(""); //increase indent
      printer.print_string("recheck_time", $sformatf("%0t",pl_isr_recheck_time));
      printer.m_scope.up(); //decrease indent
    end
    printer.print_string("ps_isr_agnt", ps_isr_agnt.name);
    if (pl_isr_agnt == ACTIVE_AGNT) begin
      printer.m_scope.down(""); //increase indent
      printer.print_string("recheck_time", $sformatf("%0t",ps_isr_recheck_time));
      printer.m_scope.up(); //decrease indent
    end
    printer.m_scope.up(); //decrease indent
  endfunction

  // Field-by-field compare
  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    tb_env_cfg t;
    do_compare = super.do_compare(rhs, comparer);
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_compare got an object that wasn't extended from tb_env_cfg")

    do_compare &= comparer.compare_field_int("pl_isr_recheck_time",
                    pl_isr_recheck_time, t.pl_isr_recheck_time, $bits(time));
    do_compare &= comparer.compare_field_int("ps_isr_recheck_time",
                    ps_isr_recheck_time, t.ps_isr_recheck_time, $bits(time));

    foreach (pl_isr_final[ii])
      do_compare &= comparer.compare_field_int($sformatf("pl_isr_final[%0d]",ii),
                      pl_isr_final[ii], t.pl_isr_final[ii], 2);
    foreach (ps_isr_final[ii])
      do_compare &= comparer.compare_field_int($sformatf("ps_isr_final[%0d]",ii),
                      ps_isr_final[ii], t.ps_isr_final[ii], 2);

    foreach (cxl_nfi_agnt_tx[ii])
      do_compare &= comparer.compare_field_int($sformatf("cxl_nfi_agnt_tx[%0d]",ii),
                      cxl_nfi_agnt_tx[ii], t.cxl_nfi_agnt_tx[ii], $bits(agent_mode_t));
    foreach (cxl_nfi_agnt_rx[ii])
      do_compare &= comparer.compare_field_int($sformatf("cxl_nfi_agnt_rx[%0d]",ii),
                      cxl_nfi_agnt_rx[ii], t.cxl_nfi_agnt_rx[ii], $bits(agent_mode_t));
    foreach (cxl_cfgsts_agnt[ii])
      do_compare &= comparer.compare_field_int($sformatf("cxl_cfgsts_agnt[%0d]",ii),
                      cxl_cfgsts_agnt[ii], t.cxl_cfgsts_agnt[ii], $bits(agent_mode_t));
    foreach (cxl_pm_in_agnt[ii])
      do_compare &= comparer.compare_field_int($sformatf("cxl_pm_in_agnt[%0d]",ii),
                      cxl_pm_in_agnt[ii], t.cxl_pm_in_agnt[ii], $bits(agent_mode_t));
    foreach (cxl_pm_out_agnt[ii])
      do_compare &= comparer.compare_field_int($sformatf("cxl_pm_out_agnt[%0d]",ii),
                      cxl_pm_out_agnt[ii], t.cxl_pm_out_agnt[ii], $bits(agent_mode_t));
    foreach (cxl_credit_agnt_tx[ii])
      do_compare &= comparer.compare_field_int($sformatf("cxl_credit_agnt_tx[%0d]",ii),
                      cxl_credit_agnt_tx[ii], t.cxl_credit_agnt_tx[ii], $bits(agent_mode_t));
    foreach (cxl_credit_agnt_rx[ii])
      do_compare &= comparer.compare_field_int($sformatf("cxl_credit_agnt_rx[%0d]",ii),
                      cxl_credit_agnt_rx[ii], t.cxl_credit_agnt_rx[ii], $bits(agent_mode_t));
    foreach (elbi_agnt[ii])
      do_compare &= comparer.compare_field_int($sformatf("elbi_agnt[%0d]",ii),
                      elbi_agnt[ii], t.elbi_agnt[ii], $bits(agent_mode_t));

    do_compare &= comparer.compare_field_int("ps_isr_agnt",
                    ps_isr_agnt, t.ps_isr_agnt, $bits(agent_mode_t));
    do_compare &= comparer.compare_field_int("pl_isr_agnt",
                    pl_isr_agnt, t.pl_isr_agnt, $bits(agent_mode_t));

`ifdef CPM6_RTL
    foreach (axi_mst_agnt[ii])
      do_compare &= comparer.compare_field_int($sformatf("axi_mst_agnt[%0d]",ii),
                      axi_mst_agnt[ii], t.axi_mst_agnt[ii], $bits(agent_mode_t));
    foreach (axi_slv_agnt[ii])
      do_compare &= comparer.compare_field_int($sformatf("axi_slv_agnt[%0d]",ii),
                      axi_slv_agnt[ii], t.axi_slv_agnt[ii], $bits(agent_mode_t));
`else
    foreach (cpm_pl_m_axi_agnt[ii])
      do_compare &= comparer.compare_field_int($sformatf("cpm_pl_m_axi_agnt[%0d]",ii),
                      cpm_pl_m_axi_agnt[ii], t.cpm_pl_m_axi_agnt[ii], $bits(agent_mode_t));
    do_compare &= comparer.compare_field_int("cpm_pl_s_axi_agnt",
                    cpm_pl_s_axi_agnt, t.cpm_pl_s_axi_agnt, $bits(agent_mode_t));
    foreach (cpm_noc_m_axi_agnt[ii])
      do_compare &= comparer.compare_field_int($sformatf("cpm_noc_m_axi_agnt[%0d]",ii),
                      cpm_noc_m_axi_agnt[ii], t.cpm_noc_m_axi_agnt[ii], $bits(agent_mode_t));
    do_compare &= comparer.compare_field_int("cpm_noc_s_axi_agnt",
                    cpm_noc_s_axi_agnt, t.cpm_noc_s_axi_agnt, $bits(agent_mode_t));
`endif
  endfunction

  // Returns 1 if this object is unmodified from a freshly constructed one
  virtual function bit is_default();
    tb_env_cfg default_cfg = new("default_cfg");
    return this.compare(default_cfg);
  endfunction

endclass
