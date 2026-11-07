import "DPI-C" function longint unsigned date();

// Command object for opcode=0x0300 (Get Timestamp)
class cmd_obj_0300h extends base_030xh;

  `uvm_object_utils(cmd_obj_0300h)

  function new(string name = "cmd_obj_0300h");
    super.new(name);
    // set the const
    opcode = cxl_comp_mbox_cmd_opcode_e'('h0300);
  endfunction

  virtual task cmd_specific; 
    cmd.retcode = Success;
  endtask

  virtual function void pack_opayload;
    longint unsigned new_timestamp = (timestamp ? date()*1e9 : 0);
    cmd.opayload = {<<8{new_timestamp}};
  endfunction

endclass
