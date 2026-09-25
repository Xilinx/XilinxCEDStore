// - Base Share Class
// - The share object is passed to the driver, monitor, sequencer objects
//   to be used to share dynamic information 
class base_share extends uvm_object;

  `uvm_object_utils(base_share)

  function new(string name = "base_share");
    super.new(name);
  endfunction

endclass
