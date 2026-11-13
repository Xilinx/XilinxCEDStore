// Base class for all logs to extend from 
class base_log extends uvm_object;

  `uvm_object_utils(base_log)

  cseq_cxl_mbox parent;

  function new(string name = "base_log");
    super.new(name);
  endfunction

endclass
