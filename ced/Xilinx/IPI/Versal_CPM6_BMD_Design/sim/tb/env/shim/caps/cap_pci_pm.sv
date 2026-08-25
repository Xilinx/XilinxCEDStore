class cap_pci_pm extends cap_base;

  `uvm_object_utils(cap_pci_pm)

  // -------------------- 
  // Capability Registers
  // -------------------- 

  typedef struct packed {
    logic [4:0] PME_support;
    logic       D2_support;
    logic       D1_support;
    logic [2:0] aux_current;
    logic       dev_spec_init;
    logic       immed_readiness_on_ret_to_D0;
    logic       PME_clock;
    logic [2:0] version;
  } pwr_mgmt_caps_s; 
  
  typedef struct packed {
    logic [1:0] undefined;
    logic [5:0] rsdvd21to16;
    logic       PME_status;
    logic [1:0] data_scale;
    logic [3:0] data_select;
    logic       PME_en;
    logic [3:0] rsvd7to4;
    logic       no_soft_reset;
    logic       rsvd2;
    logic [1:0] powerstate;
  } pmcsr_s;

  // -------------------- 
  // The capability's data: to read or write
  // -------------------- 

  // 3 ways to access the data
  // a) data.cap...   (referenced by name)
  // b) data.bytes[n] (a byte offset)
  // b) data.dws[n]   (a DW offset)
  union packed {
    logic [7:0][ 7:0] bytes;
    logic [1:0][31:0] dws;
    struct packed {
      logic [7:0]     data; //optional register field
      pmcsr_s         pmcsr;
      pwr_mgmt_caps_s pmc;
      logic [7:0]     next_cap_ptr;
      logic [7:0]     cap_id;
    } cap;
  } data;

  // -------------------- 
  // Each register field's attributes
  // -------------------- 
    
  struct { 
    struct {
      field_attr_t undefined                    = {4, 23, 22, ACC_RO,         ACC_UNSPEC, 'x, 'x,  'x};
      field_attr_t PME_status                   = {4, 15, 15, ACC_RW1CS,      ACC_UNSPEC, 'x, 'x,  'x};
      field_attr_t data_scale                   = {4, 14, 13, ACC_RW,         ACC_RO,     'x, 'b0, 'x};
      field_attr_t data_select                  = {4, 12, 9,  ACC_RW,         ACC_RO,     'x, 'b0, 'x};
      field_attr_t PME_en                       = {4, 8,  8,  ACC_RW|ACC_RWS, ACC_UNSPEC, 'x, 'x,  'x};
      field_attr_t no_soft_reset                = {4, 3,  3,  ACC_RO,         ACC_UNSPEC, 'x, 'x,  'b1};
      field_attr_t powerstate                   = {4, 1,  0,  ACC_RW,         ACC_UNSPEC, 'x, 'x,  'x};
    } pmcsr;
    // -- //
    struct {
      field_attr_t PME_support                  = {2, 15, 11, ACC_RO, ACC_UNSPEC, 'x,    'x, 'x};
      field_attr_t D2_support                   = {2, 10, 10, ACC_RO, ACC_UNSPEC, 'x,    'x, 'x};
      field_attr_t D1_support                   = {2, 9,  9,  ACC_RO, ACC_UNSPEC, 'x,    'x, 'x};
      field_attr_t aux_current                  = {2, 8,  6,  ACC_RO, ACC_UNSPEC, 'x,    'x, 'x};
      field_attr_t dev_spec_init                = {2, 5,  5,  ACC_RO, ACC_UNSPEC, 'x,    'x, 'x};
      field_attr_t immed_readiness_on_ret_to_D0 = {2, 4,  4,  ACC_RO, ACC_UNSPEC, 'x,    'x, 'x};
      field_attr_t PME_clock                    = {2, 3,  3,  ACC_RO, ACC_UNSPEC, 'b1,   'x, 'x};
      field_attr_t version                      = {2, 2,  0,  ACC_RO, ACC_UNSPEC, 'b011, 'x, 'x};
    } pmc; 
  } attrs; 

  function new(string name = "cap_pci_pm");
    super.new(name);
    cap_id = CAP_PCI_PM;
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

endclass
