/* DESCRIPTION
 * This class creates the tb_env object, the DUT and VIP config objects,
 * and provides convenience printing methods. It also sets a default 
 * timeout, randomizes the DUT and VIP config objects and applies their
 * settings, and gives handles to some important events and interfaces.
|*/

class test_base extends uvm_test;

  `uvm_component_utils(test_base)

  custom_report_server my_srvr;
  uvm_event            cdo_load_done;

  generic_config vip_cfg;
  dut_config     dut_cfg;
  tb_env         env;
  tb_env_cfg     env_cfg;

`ifdef CPM6_VIVADO
  virtual ps_vip_api_if ps_vip_api;
`endif

  cseq_cpm6_pcie_core_mbox core_mbox[0:1]; //MMIO/Cfg Mailbox (per controller)

  time timeout = 200us;

`ifdef CPM6_RTL
  virtual cpm6_demux_sel_if demux_sel_vif;
  virtual cdo_loader_sim_if cdo_loader_vif;
`endif

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    my_srvr = new;
    uvm_report_server::set_server(my_srvr);
    super.build_phase(phase);
    // By default, the env cfg will not be set up and it won't 
    // be put in the cfg db. A user can specify the below
    // `include via incdir to take precedence over the empty one.
    env_cfg = tb_env_cfg::type_id::create("env_cfg");
    `include "setup_env_cfg.sv"
    if (env_cfg != null)
      uvm_config_db#(tb_env_cfg)::set(this, "env", "env_cfg", env_cfg);
    // These control all agent setup before time=0
    vip_cfg = generic_config::type_id::create("vip_cfg");
    vip_cfg.settings_logfile = "vip_config.txt";
    dut_cfg = dut_config::type_id::create("dut_cfg");
    dut_cfg.settings_logfile = "dut_config.txt";
    // Structure
    env = tb_env::type_id::create("env", this);
    // Every test needs handle to this event
    if (!uvm_config_db#(uvm_event)::get(this, "", "cdo_load_done", cdo_load_done))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'cdo_load_done' from cfg db")
`ifdef CPM6_RTL
    // Every RTL test needs to trigger CDO loading
    if (!uvm_config_db#(virtual cdo_loader_sim_if)::get(this, "", "cdo_loader_vif", cdo_loader_vif))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'cdo_loader_vif' from cfg db")
    // Every RTL test needs to configure PL demux settings
    if (!uvm_config_db#(virtual cpm6_demux_sel_if)::get(this, "", "demux_sel_vif", demux_sel_vif))
      `uvm_fatal("CFGDB_NOGET", "Could not get 'demux_sel_vif' from cfg db")
`endif
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    string sim_timeout, sim_delay, sim_scale;
    super.end_of_elaboration_phase(phase);
    // Set a simulation timeout, can be overridden by extended tests or plusarg
    // Plusarg is the higher priority
    if ($value$plusargs("SIM_TIMEOUT=%s",sim_timeout)) begin
      `uvm_info("PLUSARG", $sformatf("Simulation timeout overridden by +SIM_TIMEOUT=%0s",sim_timeout), UVM_NONE)
      sim_scale = sim_timeout.substr(sim_timeout.len-2, sim_timeout.len-1);
      sim_delay = sim_timeout.substr(0                , sim_timeout.len-3);
      case (sim_scale)
        "ps"    : timeout = 1ps*sim_delay.atoi;
        "ns"    : timeout = 1ns*sim_delay.atoi;
        "us"    : timeout = 1us*sim_delay.atoi;
        "ms"    : timeout = 1ms*sim_delay.atoi;
        default : `uvm_fatal("PLUSARG", {"Invalid plusarg +SIM_TIMEOUT=",sim_timeout,"; scale must be [ps,ns,us,ms]"}) 
      endcase
    end
    uvm_top.set_timeout(timeout, 1);
  endfunction

  // From base/uvm_task_phase.svh:
  //   "
  /*   Base class for all task phases.
   *   It forks a call to <uvm_phase::exec_task()>
   *   for each component in the hierarchy.
   *  
   *   The completion of the task does not imply, nor is it required for, 
   *   the end of phase. Once the phase completes, any remaining forked 
   *   <uvm_phase::exec_task()> threads are forcibly and immediately killed.
   *   "
   */
  // Note that the last sentence means if you fork-join_none a process in a 
  // phase, it will be killed automatically. So we must use this method
  // to keep processes after a phase has completed.
  virtual function void phase_started(uvm_phase phase);
    case (phase.get_name)
      "pre_reset" : 
       begin
         fork
           forever begin
             `uvm_info("HRTBEAT", $sformatf("Heartbeat at %0t",$time), UVM_LOW)
             #25us; 
           end
         join_none
       end
    endcase
  endfunction

  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    // Randomize the top level DUT and VIP configuration right before simulation start
    // Extended tests must configure their DUT and VIP configurations statically before this point
    if ($test$plusargs("CPM6_RTL"))
      `uvm_info("TSTINFO", "Randomizing DUT and VIP configuration and applying the result", UVM_NONE)
    else
      `uvm_info("TSTINFO", "Randomizing VIP configuration and applying the result", UVM_NONE)
    // -- Randomize DUT config (potentially) and apply results
    dut_cfg.resolve_cdo_source;
    if (dut_cfg.rand_me && !dut_cfg.randomize) begin
      `uvm_fatal("RAND_FAIL", "DUT config object randomization has failed")
    end
    dut_cfg.create_test_cdo; 
    dut_cfg.resolve_gt_config;
    env.setup_pl_vip(dut_cfg);
    // -- Randomize VIP config and apply results
    if (!vip_cfg.randomize)
      `uvm_fatal("RAND_FAIL", "VIP config object randomization has failed")
    else begin
      env.shim.setup_vip(vip_cfg);
    end
    // Print the topology as the last thing before consuming sim time
    uvm_top.print_topology();
    factory.print(0); //useful if doing object overrides
  endfunction

  virtual task pre_reset_phase(uvm_phase phase);
    `uvm_info("RUNSTATE", "--- Entering pre_reset_phase --- ", UVM_MEDIUM)
`ifdef CPM6_VIVADO 
  `ifndef QEMU_PS
    if (!uvm_config_db#(virtual ps_vip_api_if)::get(this, "", "ps_vip_api", ps_vip_api)) 
      `uvm_fatal("CFGDB_NOGET", "Could not get 'ps_vip_api' from cfg db")
  `endif 
`elsif CPM6_RTL
    // Initialize all VIP AXI-MM slave mems to '0
    foreach (env.vip_axi_slv_mem[ii])
      env.vip_axi_slv_mem[ii].set_meminit(svt_mem::ZEROES); 
`endif
  endtask

  virtual task reset_phase(uvm_phase phase);
    `uvm_info("RUNSTATE", "--- Entering reset_phase --- ", UVM_MEDIUM)
  endtask

  virtual task post_reset_phase(uvm_phase phase);
    `uvm_info("RUNSTATE", "--- Entering post_reset_phase ---", UVM_MEDIUM)
  endtask

  virtual task pre_configure_phase(uvm_phase phase);
    `uvm_info("RUNSTATE", "--- Entering pre_configure_phase ---", UVM_MEDIUM)
  endtask

  virtual task configure_phase(uvm_phase phase);
    `uvm_info("RUNSTATE", "--- Entering configure_phase ---", UVM_MEDIUM)
  endtask

  virtual task post_configure_phase(uvm_phase phase);
    `uvm_info("RUNSTATE", "--- Entering post_configure_phase ---", UVM_MEDIUM)
  endtask

  virtual task pre_main_phase(uvm_phase phase);
    `uvm_info("RUNSTATE", "--- Entering pre_main_phase ---", UVM_MEDIUM)
  endtask

  virtual task main_phase(uvm_phase phase);
    `uvm_info("RUNSTATE", "--- Entering main_phase ---", UVM_MEDIUM)
  endtask

  virtual task post_main_phase(uvm_phase phase);
    `uvm_info("RUNSTATE", "--- Entering post_main_phase ---", UVM_MEDIUM)
  endtask
  
  virtual task pre_shutdown_phase(uvm_phase phase);
    `uvm_info("RUNSTATE", "--- Entering pre_shutdown_phase ---", UVM_MEDIUM)
  endtask

  virtual task post_shutdown_phase(uvm_phase phase);
    `uvm_info("RUNSTATE", "--- Entering post_shutdown_phase ---", UVM_MEDIUM)
  endtask

`ifdef CPM6_VIVADO 
  `ifndef QEMU_PS
  /* Helper functions that will allows users to check in tests that emulate
   * modifying the CDO file of a Vivado project manually, which cannot be 
   * checked into GitHub.
   */

  // DESCRIPTION: Write a single DW
  virtual task cdo_write(bit [31:0] addr, bit [31:0] data);
    logic [1:0] rsp;
    ps_vip_api.set_routing_config(R5_API, PS_CPM_CFG, 1'b1);
    ps_vip_api.write_data_32(R5_API, addr, data, rsp);
    if (rsp !== 2'b00)
      `uvm_fatal({get_type_name,"::cdo_write"}, $sformatf("Write | 0x%h = 0x%h | BRESP != OKAY", addr, data))
    ps_vip_api.set_routing_config(R5_API, PS_CPM_CFG, 1'b0);
  endtask

  // DESCRIPTION: Write each bit of a single DW iff mask[ii]=1 by performing a 
  // RdModWr operation
  virtual task cdo_mask_write(bit [31:0] addr, bit [31:0] mask, bit [31:0] data);
    logic [ 1:0] rsp;
    logic [31:0] rdata;
    ps_vip_api.set_routing_config(R5_API, PS_CPM_CFG, 1'b1);
    ps_vip_api.read_data_32(R5_API, addr, rdata, rsp);
    if (rsp !== 2'b00)
      `uvm_fatal({get_type_name,"::cdo_mask_write"}, $sformatf("Read | 0x%h = 0x%h | RRESP != OKAY", addr, rdata))
    foreach (mask[ii])
      if (!mask[ii])
        data[ii] = rdata[ii]; 
    ps_vip_api.write_data_32(R5_API, addr, data, rsp);
    if (rsp !== 2'b00)
      `uvm_fatal({get_type_name,"::cdo_mask_write"}, $sformatf("Write | 0x%h = 0x%h | BRESP != OKAY", addr, data))
    ps_vip_api.set_routing_config(R5_API, PS_CPM_CFG, 1'b0);
  endtask

  // DESCRIPTION: Intuitively look at data and if data[ii]=x then assume that
  // bit is a don't care, meaning leave it alone. This method smartly performs 
  // a RdModWr but allows the caller to easily just specify which bits they
  // care about without having to manually specify a mask. This doesn't do
  // anything that you can't already do with RdModWr, it just does it easier.
  // Examples:
  //  - set bits   -> cdo_write_smart(addr,  (2'b11<<12) | 'x);
  //  - clr bits   -> cdo_write_smart(addr, ~(2'b11<<12) | 'x);
  //  - mixed bits -> cdo_write_smart(addr, {'x, 2'b10, 12'hx});
  virtual task cdo_write_smart(bit [31:0] addr, logic [31:0] data);
    logic [ 1:0] rsp;
    logic [31:0] rdata;
    bit   [31:0] wdata;
    ps_vip_api.set_routing_config(R5_API, PS_CPM_CFG, 1'b1);
    if ($countbits(data, 'x) != 32) begin
      ps_vip_api.read_data_32(R5_API, addr, rdata, rsp);
      if (rsp !== 2'b00)
        `uvm_fatal({get_type_name,"::cdo_mask_write"}, $sformatf("Read | 0x%h = 0x%h | RRESP != OKAY", addr, rdata))
      foreach (data[ii])
        wdata[ii] = data[ii]===1'bx ? rdata[ii] : data[ii]; 
    end
    else begin
      wdata = data;
    end
    ps_vip_api.write_data_32(R5_API, addr, wdata, rsp);
    if (rsp !== 2'b00)
      `uvm_fatal({get_type_name,"::cdo_mask_write"}, $sformatf("Write | 0x%h = 0x%h | BRESP != OKAY", addr, wdata))
    ps_vip_api.set_routing_config(R5_API, PS_CPM_CFG, 1'b0);
  endtask
  `endif
`endif

endclass
