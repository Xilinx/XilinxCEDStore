// Command object for opcode=0x0102 (Get Event Interrupt Policy)
class cmd_obj_0102h extends base_010_23h;

  `uvm_object_utils(cmd_obj_0102h)

  // - opayload is 4B or 5B, from base class

  function new(string name = "cmd_obj_0102h");
    super.new(name);
    // set the const
    opcode = cxl_comp_mbox_cmd_opcode_e'('h0102);
  endfunction

  virtual task cmd_specific; 
    cmd.retcode = Success;
  endtask

  virtual function void pack_opayload;
    cmd.opayload = {<<8{event_irq_policy}};
    // Trim if dynamic capacity not supported
    if (dyn_cap_en) 
      cmd.opayload = new[4] (cmd.opayload);
  endfunction

endclass
