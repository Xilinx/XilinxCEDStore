/* DESCRIPTION
 * This class exists just to prove a simulation that consumes time can run
 * successfully and the DUT can be instantiated in the testbench.
|*/
class hello_world extends uvm_test;

  `uvm_component_utils(hello_world)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    // No CDO needed for this sim
    uvm_config_db#(string)::set(null, "*", "cdo_file", "none");
  endfunction

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    phase.raise_objection(this);
    `uvm_info("DEBUG", "HELLO WORLD!", UVM_NONE)
    #1us;
    `uvm_info("DEBUG", "GOODBYE, CRUEL WORLD!", UVM_NONE)
    phase.drop_objection(this);
  endtask

endclass
