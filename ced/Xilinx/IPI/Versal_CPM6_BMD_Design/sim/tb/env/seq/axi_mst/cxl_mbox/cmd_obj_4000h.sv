// Command object for opcode=0x4000 (Identify Memory Device)
class cmd_obj_4000h extends cxl_comp_cmd_obj;

  `uvm_object_utils(cmd_obj_4000h)

  struct packed {
    bit [ 1:0][7:0] dyn_cap_event_log_sz;
    bit [ 0:0][7:0] qos_telem_caps;
    bit [ 0:0][7:0] pois_handle_caps;
    bit [ 1:0][7:0] inj_pois_lim;
    bit [ 2:0][7:0] pois_list_max_media_err_rec;
    bit [ 3:0][7:0] lsa_sz;
    bit [ 1:0][7:0] fatal_event_log_sz;
    bit [ 1:0][7:0] fail_event_log_sz;
    bit [ 1:0][7:0] warn_event_log_sz;
    bit [ 1:0][7:0] info_event_log_sz;
    bit [ 7:0][7:0] part_align;
    bit [ 7:0][7:0] per_only_cap; //multiples of 256MB
    bit [ 7:0][7:0] vol_only_cap; //multiples of 256MB
    bit [ 7:0][7:0] total_cap;    //multiples of 256MB
    bit [15:0][7:0] fw_revision;
  } opayload;

  function new(string name = "cmd_obj_4000h");
    super.new(name);
    // set the const
    opcode = cxl_comp_mbox_cmd_opcode_e'('h4000);
    // init some fields 
    opayload.lsa_sz             = 1280; //minimum, per CXL spec
    opayload.fatal_event_log_sz = 1;
    opayload.fail_event_log_sz  = 1;
    opayload.warn_event_log_sz  = 1;
    opayload.info_event_log_sz  = 1;
    opayload.fw_revision = "SIM.XILINX.0.0";
  endfunction

  virtual task cmd_specific; 
    cmd.retcode = Success;
  endtask

  virtual function void pack_opayload;
    cmd.opayload = {<<8{opayload}};
    foreach (cmd.opayload[ii])
      `uvm_info(get_type_name, $sformatf("opayload[%0d] = 0x%h",ii,cmd.opayload[ii]), UVM_NONE)
  endfunction

endclass
