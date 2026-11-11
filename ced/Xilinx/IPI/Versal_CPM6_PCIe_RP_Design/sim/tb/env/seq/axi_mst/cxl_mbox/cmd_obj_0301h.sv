// Command object for opcode=0x0301 (Set Timestamp)
class cmd_obj_0301h extends base_030xh;

  `uvm_object_utils(cmd_obj_0301h)

  function new(string name = "cmd_obj_0301h");
    super.new(name);
    // set the const
    opcode = cxl_comp_mbox_cmd_opcode_e'('h0301);
  endfunction

  virtual task cmd_specific; 
    timestamp = {<<8{cmd.ipayload}}; //8B
    cmd.retcode = Success;
  endtask

endclass
