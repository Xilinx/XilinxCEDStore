// This module is translating between the Vivado generated CPM6 instance's
// internal CDO loader to create information that's relevant to the sim.
// 
// This module is designed to be bound at the SIP instance-level and then 
// navigate down to the hierarchy as displayed. 
module bind_cdo_load
  import uvm_pkg::*;
// -- // 
#(parameter string CDO_FILE)
();

  `include "uvm_macros.svh"

  // DEST_MOD => "destination module"
  `define DEST_MOD i_cpm_sim_cfg_wrap.u_cpm_sim_cfg

  initial
    // Put in config db so TB is aware
    uvm_config_db#(string)::set(null, "*", "cpm6_cdo_file", CDO_FILE);

  // Create an event to notify TB when CDO is done loading
  uvm_event cdo_load_done;
  initial begin
    cdo_load_done = new("cdo_load_done");
    uvm_config_db#(uvm_event)::set(null, "*", "cdo_load_done", cdo_load_done);
    forever begin
      @(posedge `DEST_MOD.wr_trans_outstanding);
      wait(`DEST_MOD.cdo_programming_done==1);
      cdo_load_done.trigger;
    end
  end

  `undef DEST_MOD

endmodule
