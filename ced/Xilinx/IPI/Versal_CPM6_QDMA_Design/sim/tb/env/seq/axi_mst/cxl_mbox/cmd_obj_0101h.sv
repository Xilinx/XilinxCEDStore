// Command object for opcode=0x0101 (Clear Event Records)
class cmd_obj_0101h extends cxl_comp_cmd_obj;

  `uvm_object_utils(cmd_obj_0101h)

  typedef enum bit [7:0] {
    INFO, WARNING, FAILURE, FATAL, DYN_CAP
  } event_log_e;

  typedef struct packed {
    bit [7:1] rsvd;
    bit       clr_all_events;
  } clr_event_flags_s;

  // - ipayload varies with the number of event record handles
  // - the fixed portion is 6B and each event record handle is 2B
  struct packed {
    bit [2:0][7:0]     rsvd; 
    clr_event_flags_s  clr_event_flags; 
    bit [0:0][7:0]     num_of_event_rec_handles;
    event_log_e        event_log;
  } ipayload;

  bit [15:0] handles[];

  function new(string name = "cmd_obj_0101h");
    super.new(name);
    // set the const
    opcode = cxl_comp_mbox_cmd_opcode_e'('h0101);
  endfunction

  virtual task cmd_specific; 
    // fixed portion
    ipayload = {<<8{cmd.ipayload[0:5]}};
    // variable portion; swizzle the bytes
    for (int ii=0; ii<ipayload.num_of_event_rec_handles; ii++) begin
      handles[ii][0+:8] = cmd.ipayload[6+ii*2];
      handles[ii][8+:8] = cmd.ipayload[7+ii*2];
    end
    cmd.retcode = Success;
  endtask

endclass
