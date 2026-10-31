typedef class shim_api; //forward typedef so compilation can continue

class shim_vsequencer extends uvm_sequencer;

  `uvm_component_utils(shim_vsequencer)

  // Sequences may need to use api or vip directly; parent reqd. to assign
  shim_api           api;
  apci_device        vip;
  flit_mode_t        flitmode;
`ifdef CPM6_RTL
  svt_axi_system_env axi_env; //wrapper of all AXI agents
`else
  ps_vip_vsequencer  ps_vip_vsqr;
`endif

  // Sequences may need those handles
          uvm_event         cdo_load_done;
  virtual cdo_loader_sim_if cdo_loader_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
`ifdef CPM6_RTL
    // For triggering CDO loading
    if (!uvm_config_db#(virtual cdo_loader_sim_if)::get(this, "", "cdo_loader_vif", cdo_loader_vif))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'cdo_loader_vif' from cfg db")
`endif
    // For checking CDO load done
    if (!uvm_config_db#(uvm_event)::get(this, "", "cdo_load_done", cdo_load_done))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'cdo_load_done' from cfg db")
  endfunction

  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    // Final check before starting to consume time
    if (api==null)
      `uvm_fatal(get_type_name, "Must assign 'api' handle to a valid object by this point")
    if (vip==null)
      `uvm_fatal(get_type_name, "Must assign 'vip' handle to a valid object by this point")
`ifdef CPM6_RTL
    if (axi_env==null)
      `uvm_fatal(get_type_name, "Must assign 'axi_env' handle to a valid object by this point")
`else
    if (ps_vip_vsqr==null)
      `uvm_fatal(get_type_name, "Must assign 'ps_vip_vsqr' handle to a valid object by this point")
`endif
  endfunction

endclass
