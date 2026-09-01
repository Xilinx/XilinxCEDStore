// LIMITATIONS: Only works with Avery VIP
class seq_hot_reset extends vseq_base;

  `uvm_object_utils(seq_hot_reset)

  // VIP Port 0 goes with DUT Controller 0...
  int port; 

  function new(string name = "seq_hot_reset");
    super.new(name);
  endfunction

  virtual task pre_body();
    // Check if handles have been assigned
    if (p_sequencer.cdo_load_done==null)
      `uvm_fatal(get_type_name, "member 'cdo_load_done' is null")
    // Must get this interface
    if (p_sequencer.cdo_loader_vif==null)
      `uvm_fatal(get_type_name, "member 'cdo_loader_vif' is null")
  endtask

  virtual task body();
    string msg;
    bit    cdo_loaded;

    // Assert HotReset and wait to reach LTSSM.HotReset
    p_sequencer.vip.port_set(port, "to_hot_reset"); 
    msg = "LTSSM enters HotReset -> 3.25ms timeout hit";
    p_sequencer.vip.port_wait_ltssm(port, APCI_LTSSM_hot_reset, 3.25ms, msg);
    `uvm_info(get_type_name, $sformatf("Port %0d reached HotReset",port), UVM_LOW)

    // Provide a timeout for CDO to load
    fork 
      begin
        #125us;
        if (!cdo_loaded)
          `uvm_fatal(get_type_name, "CDO did not load within 125us")
      end
    join_none

    fork
      // Exit HotReset and wait to reach LTSSM.L0
      begin : ltssm_transition
        p_sequencer.vip.port_set(port, "exit_hot_reset"); 
        msg = "LTSSM enters L0 -> 1ms timeout hit";
        p_sequencer.vip.port_wait_event(port, "L0", 1ms, msg);
        `uvm_info(get_type_name, $sformatf("Port %0d reached L0",port), UVM_LOW)
      end
      // Start loading CDO
      begin : cdo_load
        p_sequencer.cdo_loader_vif.assert_go;
        p_sequencer.cdo_load_done.wait_trigger;
        `uvm_info(get_type_name, "CDO load completed", UVM_LOW)
        cdo_loaded = 1;
      end
    join
    
  endtask

endclass
