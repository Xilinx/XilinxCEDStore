package params_pkg;

  import cxl31_ll_pkg::*;

  // ----- Knobs -----
  `ifdef NFI_W
    localparam N = `NFI_W;
  `else
    localparam N = 3; 
  `endif

  `ifdef MODE
    localparam flit_mode_t MODE = `MODE;
  `else
    localparam flit_mode_t MODE = F68; 
  `endif
  // -----------------

endpackage
