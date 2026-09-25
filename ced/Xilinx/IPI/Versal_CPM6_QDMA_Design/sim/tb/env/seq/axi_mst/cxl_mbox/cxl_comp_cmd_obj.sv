// Base class for all commands to extend from so they can access the common method
class cxl_comp_cmd_obj extends uvm_object;

  `uvm_object_utils(cxl_comp_cmd_obj)

  cseq_cxl_mbox parent;

  // unique identifier; assigned in constructor (Questa errors if const)
  cxl_comp_mbox_cmd_opcode_e opcode;

  // snapshot the latest command
  cxl_comp_mbox_cmd_s cmd;

  // create a reference in extended class constructor
  cxl_comp_mbox_cmd_value_s cmd_ref;

  // CEL entry
  cel_cmd_effect_s cmd_effect; 

  function new(string name = "cxl_cmd_obj");
    super.new(name);
  endfunction

  // Just a local alias
  const bit MMIO = 1'b1;

  // Mailbox register offsets for reference
  typedef enum bit [31:0] {
    MBOX_CTRL           = 'h4,
    MBOX_COMMAND        = 'h8,
    MBOX_STATUS         = 'h10,
    MBOX_PAYLOAD_BASE   = 'h20
  } mbox_offset_e;

  // callback; extended classes should implement
  virtual task perform; 
    // copy the command and reference from parent to local
    cmd     = parent.cmd;
    cmd_ref = parent.cmd_ref[opcode]; 
    if (cmd.opcode!=opcode) begin
      `uvm_error(get_type_name, "Wrong object's 'perform' method got called; debug TB further")
      return;
    end
    // do something command specific
    cmd_specific;
    pack_opayload;
    // common methods
    set_opayload;
    set_opayload_len;
    set_retcode;
    // complete the handling
    clear_doorbell;
  endtask

  // extended classes should implement this callback
  virtual task cmd_specific; endtask

  virtual function void pack_opayload; endfunction

  // ----------------------------
  // Common methods; extended classes needn't touch, they just need to
  // modify the cmd struct
  // ----------------------------


  virtual function void set_opayload;
    bit [31:0] addr = parent.cxl_mbox_base_addr+MBOX_PAYLOAD_BASE;
    foreach (cmd.opayload[ii]) begin
      // Unroll endianness
      parent.mbox[MMIO][parent.cxl_mbox_pf][parent.cxl_mbox_bar][addr][(ii%4)*8+:8] = cmd.opayload[ii];
      // Bytes to DW
      if (ii!=0 && !((ii+1)%4)) addr+=4;
    end
  endfunction

  virtual function void set_opayload_len;
    bit [31:0] addr         = parent.cxl_mbox_base_addr+MBOX_COMMAND;
    bit [20:0] opayload_len = cmd.opayload.size;
    parent.mbox[MMIO][parent.cxl_mbox_pf][parent.cxl_mbox_bar][addr][31:16] = opayload_len[15: 0];
    addr+=4;
    parent.mbox[MMIO][parent.cxl_mbox_pf][parent.cxl_mbox_bar][addr][ 4: 0] = opayload_len[20:16];
  endfunction

  virtual function void set_retcode;
    bit [31:0] addr = parent.cxl_mbox_base_addr+MBOX_STATUS+4;
    parent.mbox[MMIO][parent.cxl_mbox_pf][parent.cxl_mbox_bar][addr][15:0] = cmd.retcode;
  endfunction
  
  virtual function void clear_doorbell;
    bit [31:0] addr = parent.cxl_mbox_base_addr+MBOX_CTRL;
    `uvm_info(get_type_name, $sformatf("Clearing doorbell for command %0s (0x%h)", cmd.opcode.name, cmd.opcode), UVM_NONE)
    parent.mbox[MMIO][parent.cxl_mbox_pf][parent.cxl_mbox_bar][addr][0] = 1'b0;
    ->parent.doorbell_clr;
  endfunction

endclass
