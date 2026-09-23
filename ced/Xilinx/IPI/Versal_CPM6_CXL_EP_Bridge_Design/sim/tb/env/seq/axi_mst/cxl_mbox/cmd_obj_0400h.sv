// Command object for opcode=0x0400 (Get Supported Logs)
class cmd_obj_0400h extends cxl_comp_cmd_obj;

  `uvm_object_utils(cmd_obj_0400h)

  // - Variable payload depending on the number of log entries
  // - Each log entry is 20B: 16B for UUID and 4B for log size
  struct packed {
    bit [ 5:0][7:0] rsvd;
    bit [ 1:0][7:0] num_of_supp_log_entries;
  } opayload;

  typedef struct packed {
    bit [3:0][7:0] log_size;
    log_uuid_e     uuid;
  } log_entry_e; 

  log_entry_e log[$:6];

  function new(string name = "cmd_obj_0400h");
    super.new(name);
    // set the const
    opcode = cxl_comp_mbox_cmd_opcode_e'('h0400);
    // CEL is always supported
    opayload.num_of_supp_log_entries = 1;
    log.push_back({{32{1'bx}}, CEL}); //must parse all commands to get size
  endfunction

  virtual task cmd_specific; 
    cmd.retcode = Success;
  endtask

  virtual function void calc_log_size(log_uuid_e uuid);
    int qi[$];
    case (uuid)
      CEL     : begin
                  qi = log.find_first_index with (item.uuid==uuid);
                  log[qi[0]].log_size = parent.cmd_obj.size*4;
                end
      default : `uvm_fatal(get_type_name, $sformatf("UUID=0x%h... not supported",uuid))
    endcase
  endfunction

  virtual function void pack_opayload;
    cmd.opayload = {<<8{opayload}};
    // -- // 
    foreach (log[ii]) begin
      calc_log_size(log[ii].uuid);
      cmd.opayload = new[cmd.opayload.size+20] (cmd.opayload);
      for (int bb=0; bb<20; bb++)
        cmd.opayload[cmd.opayload.size-20+bb] = log[ii][bb*8+:8];
    end
  endfunction

endclass
