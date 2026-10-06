//=============================================================================
// DOE (Data Object Exchange) Extended Capability
// PCIe Extended Capability ID: 0x2E
//=============================================================================
class ecap_doe extends ecap_base;

  `uvm_object_utils(ecap_doe)

  //--- DW Offset Constants (for use with shim_api) ---
  localparam int DW_HDR        = 0;   // 0x00: Extended Capability Header
  localparam int DW_CAP        = 1;   // 0x04: DOE Capabilities
  localparam int DW_CTRL       = 2;   // 0x08: DOE Control
  localparam int DW_STATUS     = 3;   // 0x0C: DOE Status
  localparam int DW_WR_MBOX    = 4;   // 0x10: DOE Write Data Mailbox
  localparam int DW_RD_MBOX    = 5;   // 0x14: DOE Read Data Mailbox

  // -------------------- 
  // Capability Registers
  // -------------------- 

  typedef struct packed {
    logic [31:12] rsvd31to12;        // [31:12] Reserved
    logic [10:0]  doe_intr_msg_num;  // [11:1] DOE Interrupt Message Number
    logic         doe_intr_sup;      // [0] DOE Interrupt Support
  } doe_cap_s;

  typedef struct packed {
    logic [31:2]  rsvd31to2;
    logic         doe_intr_en;       // [1] DOE Interrupt Enable
    logic         doe_abort;         // [0] DOE Abort
  } doe_ctrl_s;
  
  typedef struct packed {
    logic [31:2]  rsvd31to2;
    logic         doe_error;         // [1] DOE Error
    logic         doe_busy;          // [0] DOE Busy
  } doe_stts_s;

  typedef struct packed {
    logic [31:0]  data;              // Write Data Mailbox
  } doe_wr_mbox_s;

  typedef struct packed {
    logic [31:0]  data;              // Read Data Mailbox
  } doe_rd_mbox_s;

  // -------------------- 
  // The capability's data: to read or write
  // -------------------- 

  union packed {
    logic [23:0][ 7:0] bytes;
    logic [ 5:0][31:0] dws;
    struct packed {
      doe_rd_mbox_s rd_mbox;
      doe_wr_mbox_s wr_mbox;
      doe_stts_s    status;
      doe_ctrl_s    control;
      doe_cap_s     cap;
      ecap_hdr_s    hdr;
    } cap;
  } data;

  // -------------------- 
  // Each register field's attributes
  // -------------------- 
    
  struct { 
    struct {
      field_attr_t rsvd31to12        = {'h4, 31, 12, ACC_RSVDZ, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t doe_intr_msg_num  = {'h4, 11,  1, ACC_RO,    ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t doe_intr_sup      = {'h4,  0,  0, ACC_RO,    ACC_UNSPEC, 'x, 'x, 'x};
    } cap;
    struct {
      field_attr_t rsvd31to2         = {'h8, 31,  2, ACC_RSVDZ, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t doe_intr_en       = {'h8,  1,  1, ACC_RW,    ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t doe_abort         = {'h8,  0,  0, ACC_RW,    ACC_UNSPEC, 'x, 'x, 'x};
    } control;
    struct {
      field_attr_t rsvd31to2         = {'hC, 31,  2, ACC_RSVDZ, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t doe_error         = {'hC,  1,  1, ACC_RW1C,  ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t doe_busy          = {'hC,  0,  0, ACC_RO,    ACC_UNSPEC, 'x, 'x, 'x};
    } status;
    struct {
      field_attr_t data              = {'h10, 31, 0, ACC_RW,    ACC_UNSPEC, 'x, 'x, 'x};
    } wr_mbox;
    struct {
      field_attr_t data              = {'h14, 31, 0, ACC_RO,    ACC_UNSPEC, 'x, 'x, 'x};
    } rd_mbox;
  } attrs; 

  function new(string name = "ecap_doe");
    super.new(name);
    cap_id = ECAP_DOE;
  endfunction

  virtual function logic [7:0] get_byte(int offset);
    return data.bytes[offset];
  endfunction

  virtual function void set_byte(int offset, logic [7:0] data); 
    this.data.bytes[offset] = data;
  endfunction

  virtual function logic [31:0] get_dw(int offset);
    return data.dws[offset];
  endfunction

  virtual function void set_dw(int offset, logic [31:0] data); 
    this.data.dws[offset] = data;
  endfunction

  //--- Helper functions for common operations ---

  // Send DOE Abort
  function void set_abort();
    data.cap.control.doe_abort = 1'b1;
  endfunction

  // Check if DOE is busy
  function bit is_busy();
    return data.cap.status.doe_busy;
  endfunction

  // Check if DOE has error
  function bit has_error();
    return data.cap.status.doe_error;
  endfunction

  // Set interrupt enable
  function void set_intr_en(bit en);
    data.cap.control.doe_intr_en = en;
  endfunction

endclass
