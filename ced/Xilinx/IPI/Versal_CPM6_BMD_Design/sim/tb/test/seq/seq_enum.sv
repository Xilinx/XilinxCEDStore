class seq_enum extends vseq_base;

  `uvm_object_utils(seq_enum)
  `uvm_register_cb(seq_enum, seq_enum_callback)

  time enum_timeout = 250us;

  // provide handles to common objects that callbacks can use
  tb_env_cfg     env_cfg;
  tb_env         env;
  dut_config     dut_cfg;
  generic_config vip_cfg;   

  // RP DUT only 
  bit        skip_enum_seq;
  bit [47:0] ecam_base;
  bit [ 7:0] bus_base;

  function new(string name = "seq_enum");
    super.new(name);
  endfunction

  virtual task body();
    // Control auto bus enum to happen or not to support co-sim
    p_sequencer.vip.set("auto_enum", !$test$plusargs("AVERY_CPM6_COSIM"));
    // callback 
    `uvm_do_callbacks(seq_enum, seq_enum_callback, pre_start(this))
    // call "start"
    if (is_rp_vip) rp_vip_start; else rp_dut_start;
    // callback 
    `uvm_do_callbacks(seq_enum, seq_enum_callback, post_start(this))
    if (!$test$plusargs("AVERY_CPM6_COSIM")) begin
      // do enumeration
      if (is_rp_vip) 
        rp_vip_enum; 
      else begin
        if (skip_enum_seq)
          `uvm_info(get_type_name, "skip_enum_seq=1, not running PCIe enumeration sequence", UVM_NONE)
        else
          rp_dut_enum;
      end
      // callback 
      `uvm_do_callbacks(seq_enum, seq_enum_callback, post_enum(this))
    end
  endtask

  virtual function bit is_rp_vip;
    return (&{dut_cfg.ctrlr_en[0], 
              dut_cfg.pcie_cfg[0].pcie_cap.pcie_cap.dev_port_type==pcie_config::EP} 
            ||
            &{dut_cfg.ctrlr_en[1], 
              dut_cfg.pcie_cfg[1].pcie_cap.pcie_cap.dev_port_type==pcie_config::EP});
  endfunction 

  // ------------------------------ //
  // Methods: VIP as RP, DUT as EP
  // ------------------------------ //
      
  // - RP VIP : Call "start" as a precursor to enumeration
  // - EP DUT : N/A
  virtual task rp_vip_start;
    p_sequencer.vip.set("start_bfm");
    p_sequencer.vip.wait_event("bfm_started", 1us, "RC BFM didn't start successfully");
  endtask

  // - RP VIP : Use the API to initiate enumeration
  // - EP DUT : N/A
  virtual task rp_vip_enum;
    // initiate enumeration
    p_sequencer.vip.wait_event("bus_enum_done", 
                               enum_timeout, 
                               $sformatf("Bus enumeration failed to complete in %t", enum_timeout));
    if (!p_sequencer.vip.get("bus_enum_ok"))
      `uvm_fatal(get_type_name, "Bus enumeration completed, but result not 'ok'")
  endtask

  // ------------------------------ //
  // Methods: DUT as RP, VIP as EP
  // ------------------------------ //

  // RP DUT : N/A
  // EP VIP : Call start as precursor to enumeration 
  virtual task rp_dut_start;
    p_sequencer.vip.set("start_bfm");
    p_sequencer.vip.wait_event("bfm_started", 1us, "EP BFM didn't start successfully");
  endtask

  virtual task rp_dut_enum;
    seq_ps_pcie_enum seq_enum;
    /* 
     * Querying the VIP before beginning the enumeration sequence is
     * technically cheating, as enumeration should be an entirely
     * root side process, but just move on for now.
     */
    // wait until VIP confirms DLL is up 
    p_sequencer.vip.port_wait_event(0, "dl_up", 50us, "Bus didn't reach dl_up in 50us");
    // wait until VIP confirms L0 is reached
    p_sequencer.vip.port_wait_event(0, "L0", 50us, "Bus didn't reach L0 in 50us");
    // start enumeration
    `uvm_info(get_type_name, $sformatf("Using ECAM base=0x%h and Bus base=0x%h for enumeration", ecam_base, bus_base), UVM_LOW)
    seq_enum = seq_ps_pcie_enum::type_id::create("seq_enum");
    seq_enum.set_ctrlr(dut_cfg.ctrlr_en[1]);
    {seq_enum.ecam_base, seq_enum.bus_base} = {ecam_base, bus_base};
`ifdef CPM6_RTL
    seq_enum.start(p_sequencer.axi_env.master[M_AXIMM_PS_128].sequencer);
`else
    seq_enum.start(p_sequencer.ps_vip_vsqr);
`endif
    // Add objects to container
    foreach (seq_enum.pdev[ii])
      env.shim.container.add_pdev(seq_enum.pdev[ii]);
  endtask

endclass
