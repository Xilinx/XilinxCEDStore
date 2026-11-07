// Base class for command objects for opcode=0x010[2,3] ([Get,Set] Event Interrupt Policy)
class base_010_23h extends cxl_comp_cmd_obj;

  `uvm_object_utils(base_010_23h)

  bit dyn_cap_en;

  typedef enum bit [7:0] {
    INFO, WARNING, FAILURE, FATAL, DYN_CAP
  } event_log_e;

  typedef enum bit [1:0] {NONE, MSI_MSIX, FW_IRQ, RSVD} irq_mode_e;

  typedef struct packed {
    bit [7:4]   irq_msg_num;
    bit [3:2]   rsvd;
    irq_mode_e  irq_mode;
  } log_irq_setting_s;

  static struct packed {
    log_irq_setting_s  dyncap_event_log;
    log_irq_setting_s  fatal_event_log;
    log_irq_setting_s  fail_event_log;
    log_irq_setting_s  warn_event_log;
    log_irq_setting_s  info_event_log;
  } event_irq_policy;

  function new(string name = "base_010_23h");
    super.new(name);
  endfunction

endclass
