// Base class for command objects for opcode=0x030[0,1] ([Get,Set] Timestamp)
class base_030xh extends cxl_comp_cmd_obj;

  `uvm_object_utils(base_030xh)

  static bit [7:0][7:0] timestamp;

  function new(string name = "base_030xh");
    super.new(name);
  endfunction

endclass
