class slot_base_f256 extends slot_base;

  `uvm_object_utils(slot_base_f256)

  bit [3:0]     slot_num; 
  flit_mode_t   flitmode;

  // relevant for F256_LOPT (Slot 8 [HS-Slot] and Slot 15 [PHY Slot]), this
  // points to the lower slot handle
  slot_base_f256 lower_slot;
  
  // 128 bits (bits within slots can be various things, or shifted around)
  union packed {
    // HS-Slot (Slot 8 in F256_LOPT)
    struct packed {
      logic [127:80] s7_upr;
      logic [ 79: 4] s8_lwr;
      logic [  3: 0] fmt;
    } hsslot;
    // H-Slot
    struct packed {
      logic [111:4] data;
      logic [  3:0] fmt;
      logic [ 15:0] hdr;
    } hslot;
    // G-Slot
    struct packed {
      logic [127:4] data;
      logic [  3:0] fmt;
    } gslot;
    // G-Slot (Slot 7 in F256_LOPT)
    struct packed {
      logic [127:80] crc;
      logic [ 79: 4] s7_lwr;
      logic [  3: 0] fmt;
    } s7_lopt;
    // Split slot (different way to refer to S7/S8-LOpt 
    struct packed {
      logic [127:80] upper;
      logic [ 79: 4] lower;
      logic [  3: 0] fmt;
    } split;
    // Slot 15 (F256)
    struct packed {
      logic [47:0] fec;
      logic [63:0] crc;
      logic [15:0] crd;
    } s15;
    // Slot 15 (F256_LOPT)
    struct packed {
      logic [47:0] fec;
      logic [47:0] crc;
      logic [15:0] s8_upr;
      logic [15:0] crd;
    } s15_lopt;
    // LLCTRL 
    struct packed {
      logic [15:0]   unused;
      logic [95:0]   payload;
      logic [ 3:0]   rsvd;
      logic [ 3:0]   subtype;
      llctrl_f256_t  llctrl;
      logic [ 3:0]   fmt;
    } llcm;
    // Trailers
    union packed {  
      struct packed {
        logic [31:0] rsvd;
        logic [31:0] trailer2;
        logic [31:0] trailer1;
        logic [31:0] trailer0;
      } m2srwd;
      struct packed {
        logic [31:0] rsvd;
        logic [31:0] emd2;
        logic [31:0] emd1;
        logic [31:0] emd0;
      } s2mdrs;
      struct packed {
        logic [63:0] rsvd;
        logic [63:0] be;
      } d2hdh;
    } trp;
  } data;

  function new(string name = "slot_base_f256");
    super.new(name);
  endfunction

  virtual function bit is_hsslot();
    return (slot_num==8 && flitmode==F256_LOPT);
  endfunction
 
  virtual function bit is_hslot();
    return (!slot_num);
  endfunction

  virtual function bit is_gslot();
    return (!is_hslot && !is_hsslot && slot_num!=15);
  endfunction

  virtual function bit is_s7_lopt();
    return (slot_num==7 && flitmode==F256_LOPT);
  endfunction

  virtual function bit is_split_slot();
    return (slot_num inside {7,8} && flitmode==F256_LOPT);
  endfunction

  // Pure virtual functions except by name
  virtual function void unpack_slot(flit_mode_t fm, bit [3:0] sn, logic [127:0] dat = 'x); endfunction
  virtual function logic [127:0] pack_slot(bit [47:0] upr_6B); return '0;                  endfunction
  // all slots call these during pack/unpack
  virtual function void set_slot_consumed();                                               endfunction
  virtual function void check_rsvd();                                                      endfunction
  virtual function void check_tightly_packed();                                            endfunction
  // if a slot is a split slot, they call the function to the lower slot's implementation
  virtual function bit [4:0] get_slot_consumed_upr(logic [47:0] upr); return '0;           endfunction //ret tuple: 4=(0=cache,1=mem), 3:2={0=na,1=req,2=dat,3=rsp}, 1:0=cnt,
  virtual function void check_rsvd_upr(logic [47:0] upr);                                  endfunction
  virtual function void check_tightly_packed_upr(logic [47:0] upr);                        endfunction
  

  /* Helper functions to grab certain fields */

  // Get the lowest 76 bits (skip over fmt); for S7-LOpt or S8-LOpt
  virtual function logic [75:0] get_split_lower();
    return data.split.lower;
  endfunction

  // Get the highest 48 bits ; for S7-LOpt (CRC) or S8-LOpt (S7 continued)
  virtual function logic [47:0] get_split_upper();
    return data.split.upper;
  endfunction

endclass
