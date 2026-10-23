// Command object for opcode=0x0103 (Set Event Interrupt Policy)
class cmd_obj_0103h extends base_010_23h;

  `uvm_object_utils(cmd_obj_0103h)

  // - ipayload is either 4 or 5B, from base class

  function new(string name = "cmd_obj_0103h");
    super.new(name);
    // set the const
    opcode = cxl_comp_mbox_cmd_opcode_e'('h0103);
  endfunction

  virtual task cmd_specific; 
    log_irq_setting_s dyncap_prev = event_irq_policy.dyncap_event_log; 
    event_irq_policy = {<<8{cmd.ipayload}};
    // Payload may be 4 or 5B; so must account for smaller size
    if (cmd.ipayload.size==4) 
      event_irq_policy.dyncap_event_log = dyncap_prev;
    cmd.retcode = Success;
  endtask

endclass
