package shim_register_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  // Many fields can have multiple access types, so make this a bit field
  typedef enum bit [9:0] {
    ACC_UNSPEC = (1<<0),
    ACC_HWINIT = (1<<1),
    ACC_RO     = (1<<2),  
    ACC_RW     = (1<<3),    
    ACC_RW1C   = (1<<4), 
    ACC_ROS    = (1<<5),    
    ACC_RWS    = (1<<6), 
    ACC_RW1CS  = (1<<7), 
    ACC_RSVDP  = (1<<8), 
    ACC_RSVDZ  = (1<<9)
  } field_acc_t; 

  typedef struct packed {
    int          byte_offset;  //offset from base
    int          hi;           //high bit of field in register
    int          lo;           //low bit of field in register
    field_acc_t  acc;          //PF access type
    field_acc_t  vf_acc;       //VF access type
    int          must;         //not always used 
    int          must_vf;      //not always used 
    int          must_at_flit; //not always used
  } field_attr_t;

endpackage
