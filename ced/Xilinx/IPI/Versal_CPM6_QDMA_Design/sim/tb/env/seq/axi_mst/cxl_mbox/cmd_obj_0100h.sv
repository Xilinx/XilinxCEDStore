// Command object for opcode=0x0100 (Get Event Records)
// CXL3.1 : 8.2.9.2 Events
//  - The device shall support at least 1 event record within each event log
//  - A CXL memory device that implements the PCI Header Class Code in 8.1.12.1
//    or advertises Memory Device Command support in the Mailbox Capabilities
//    register shall use the Memory Module Event Record format when reporting
//    general device events and shall use either the General Media Event Record
//    or DRAM Event Record when reporting media events.
class cmd_obj_0100h extends cxl_comp_cmd_obj;

  `uvm_object_utils(cmd_obj_0100h)

  // - opayload varies depending on the list of event records 
  // - opayload is 32B + <event records>B
  struct packed {
    bit [ 9:0][7:0] rsvd1;
    bit [ 1:0][7:0] event_record_cnt;
    bit [ 7:0][7:0] last_oflow_event_tstamp;
    bit [ 7:0][7:0] first_oflow_event_tstamp;
    bit [ 1:0][7:0] oflow_err_cnt;
    bit [ 0:0][7:0] rsvd0;
    bit [ 0:0][7:0] flags;
  } opayload;

  typedef enum bit [7:0] {
    INFO, WARNING, FAILURE, FATAL, DYN_CAP
  } event_log_e;

  struct packed {
    event_log_e event_log;
  } ipayload;

  function new(string name = "cmd_obj_0100h");
    super.new(name);
    // set the const
    opcode = cxl_comp_mbox_cmd_opcode_e'('h0100);
  endfunction

  virtual task cmd_specific; 
    ipayload = cmd.ipayload[0];
    case (ipayload.event_log)
      INFO    : ; 
      WARNING : ;
      FAILURE : ;
      FATAL   : ;
      DYN_CAP : ;
    endcase
    cmd.retcode = Success;
  endtask

  virtual function void pack_opayload;
    cmd.opayload = {<<8{opayload}};
  endfunction

endclass
