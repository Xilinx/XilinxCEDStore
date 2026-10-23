// Base class; just create the p_sequencer handle
class vseq_base extends uvm_sequence;

  `uvm_object_utils(vseq_base)
  `uvm_declare_p_sequencer(shim_vsequencer)

  function new(string name = "vseq_base");
    super.new(name);
  endfunction

endclass
