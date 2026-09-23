package cxl_nfi_other_pkg;

  typedef enum bit {CCH, MEM} prot_t;

  typedef enum {VLOW, LOW, MEDIUM, HIGH, VHIGH, VVHIGH, RAND, NONE} backpressure_ctl_t;
  typedef enum {H2C, C2H} dir_t; //"Host2Card" and "Card2Host
  typedef enum bit [1:0] {ANYC, REQC, DATC, RSPC} credit_op_t;
  
  // Cannot overload operators, so must have unique names, use _ prefix as a keyword indicator that
  // these are generic, to be referred by name only. We will use this single typedef for all 68B
  // or 256B slots.
  typedef enum {// 68B flit mode
                _H0, _H1, _H2, _H3, _H4, _H5, _H6,                    
                _G0, _G1, _G2, _G3, _G4, _G5, _G6, _G0_BE, 
                _RETRY, _LLCRD, _IDE, _INIT,
                _RSVD, 
                // 256B flit mode
    /*DATA*/    _D, 
    /*TRAILER*/ _T, 
                _HBR_M0, _HBR_M1, _HBR_M2 , _HBR_M3 , _HBR_M4 , _HBR_M5 , _HBR_M6 , _HBR_M7,
                _HBR_M8, _HBR_M9, _HBR_M10, _HBR_M11, _HBR_M12, _HBR_M13, _HBR_M14, _HBR_M15,
                _S15_PHY} slot_fmt_t;  
  
endpackage
