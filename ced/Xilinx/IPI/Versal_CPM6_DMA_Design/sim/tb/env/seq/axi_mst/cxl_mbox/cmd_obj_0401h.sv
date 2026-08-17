// Command object for opcode=0x0401 (Get Log)
class cmd_obj_0401h extends cxl_comp_cmd_obj;

  `uvm_object_utils(cmd_obj_0401h)

  // - Variable opayload depending on the ipayload's UUID, 
  //   offset, and length 
  // - ipayload is 24B
  struct packed {
    bit [ 3:0][7:0]  len;
    bit [ 3:0][7:0]  offset;
    log_uuid_e       log_id;
  } ipayload;

  function new(string name = "cmd_obj_0401h");
    super.new(name);
    // set the const
    opcode = cxl_comp_mbox_cmd_opcode_e'('h0401);
  endfunction

  virtual task cmd_specific; 
    string msg;
    // -- 
    ipayload = {<<8{cmd.ipayload}};
    // -- 
    msg = "'Get Log' (0x0401) command received; ";
    msg = {msg, $sformatf("UUID=0x%h...%0s",ipayload[127-:16],ipayload.log_id.name)};
    msg = {msg, $sformatf(" | offset=%0d | length=%0d",ipayload.offset, ipayload.len)};
    `uvm_info(get_type_name, msg, UVM_LOW)
    // -- 
    case (ipayload.log_id)
      CEL     : cmd.retcode = Success;
      default : cmd.retcode = InvalidLog;
    endcase
    if (ipayload.offset%4) begin
      msg = $sformatf("ipayload.offset=%0d; sequence can't handle unaligned accesses",
                      ipayload.offset);
      `uvm_fatal(get_type_name, msg) 
    end
    else if (ipayload.offset) begin
      msg = $sformatf("ipayload.offset=%0d; sequence can't handle non-zero offsets",
                      ipayload.offset);
      `uvm_fatal(get_type_name, msg) 
    end
    else if (ipayload.len != (parent.cmd_obj.size*4)) begin
      msg = $sformatf("#cmds=%0d times 4 should equal ipayload.len=%0d; investigate",
                      parent.cmd_obj.size, ipayload.len);
      `uvm_fatal(get_type_name, msg) 
    end
  endtask

  virtual function void pack_opayload;
    case (ipayload.log_id)
      CEL     :  foreach (parent.cmd_obj[ii]) begin
                   cel_entry_s entry = {parent.cmd_obj[ii].cmd_effect, 
                                        parent.cmd_obj[ii].opcode};
                   cmd.opayload = new[cmd.opayload.size+4] (cmd.opayload);
                   cmd.opayload[cmd.opayload.size-4] = entry[ 0+:8];
                   cmd.opayload[cmd.opayload.size-3] = entry[ 8+:8];
                   cmd.opayload[cmd.opayload.size-2] = entry[16+:8];
                   cmd.opayload[cmd.opayload.size-1] = entry[24+:8];
                 end
      default : cmd.opayload = {}; 
    endcase
  endfunction

endclass
