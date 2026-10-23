/* DESCRIPTION
 * This class exists to deassert resets and load the CPM6 CDO, after which 
 * useful work should be performed. This is a sort of smoke-test for a 
 * basic simulation to work.
|*/
class test_init extends test_base;

  `uvm_component_utils(test_init)

  time cdo_timeout = 100us;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    string parg_timeout, parg_delay, parg_scale; 
    // This sets the timeout (sim_timeout)
    super.end_of_elaboration_phase(phase);
    // Set a CDO timeout, can be overridden by extended tests or plusarg
    // Plusarg is the higher priority
    if ($value$plusargs("CDO_TIMEOUT=%s", parg_timeout)) begin
      `uvm_info("PLUSARG", $sformatf("CDO timeout overridden by +CDO_TIMEOUT=%0s",parg_timeout), UVM_NONE)
      parg_scale = parg_timeout.substr(parg_timeout.len-2, parg_timeout.len-1);
      parg_delay = parg_timeout.substr(0                 , parg_timeout.len-3);
      case (parg_scale)
        "ps"    : cdo_timeout = 1ps*parg_delay.atoi;
        "ns"    : cdo_timeout = 1ns*parg_delay.atoi;
        "us"    : cdo_timeout = 1us*parg_delay.atoi;
        "ms"    : cdo_timeout = 1ms*parg_delay.atoi;
        default : `uvm_fatal("PLUSARG", {"Invalid plusarg +CDO_TIMEOUT=",parg_timeout,"; scale must be [ps,ns,us,ms]"})
      endcase 
    end 
    // Ensure our sim won't timeout if CDO timeout exceeds it
    if (cdo_timeout > timeout) begin
      `uvm_info("PLUSARG", $sformatf("CDO timeout exceeds sim timeout, increasing sim timeout to match"), UVM_NONE)
      uvm_top.set_timeout(cdo_timeout, 1);
    end
  endfunction

  virtual task reset_phase(uvm_phase phase);
    super.reset_phase(phase);
    phase.raise_objection(this);
    
    #100ns;
    `uvm_info("TSTINFO", "Deasserting LPD_POR_N and waiting 1us to permeate", UVM_NONE)
    env.lpd_por_n_agnt.api.set_reset(DEASSERT, ASYNC);
    #1us;

`ifdef CPM6_RTL
    // Trigger CDO loading to commence
    `uvm_info("TSTINFO", "Triggering CDO loader to commence programming the CPM6 CDO", UVM_NONE)
    cdo_loader_vif.assert_go;
`endif

    // Deassert PERSTN if link is to be enabled
    fork
      begin
        `uvm_info("TSTINFO", "Deasserting PERST_N for Controller 0", UVM_NONE)
        env.perstn_agnt[0].api.set_reset(DEASSERT, ASYNC);
      end
      begin
        `uvm_info("TSTINFO", "Deasserting PERST_N for Controller 1", UVM_NONE)
        env.perstn_agnt[1].api.set_reset(DEASSERT, ASYNC);
      end
    join

    /* Wait until CDO load is completed */
    fork
      begin : cdo_timeout_proc
        #(cdo_timeout);
        `uvm_fatal("TSTINFO", $sformatf("CDO load didn't complete in %0t; debug further", cdo_timeout))
      end
      begin
        cdo_load_done.wait_trigger;
        `uvm_info("TSTINFO", "CDO load completed", UVM_MEDIUM)
        post_cdo_load;
        disable cdo_timeout_proc;
      end
    join_any

`ifdef CPM6_RTL
    // Deassert all PS AXI interface aresetn
    env.ps_axi_reset_agnt.api.set_reset(DEASSERT, ASYNC);
`endif
    
    phase.drop_objection(this);
  endtask

  // Provide some callbacks for extended classes (tasks; can consume time)
  virtual task post_cdo_load();  endtask

endclass
