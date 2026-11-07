class reset_cfg extends base_cfg;

  `uvm_object_utils(reset_cfg)

  // Defaults
  //   - has a clock to either sync assert and/or deassert
  //   - active low reset
  bit                 has_clk    = 1'b1;
  active_hi_lo_enum   active_val = ACTIVE_LO;

  function new(string name = "reset_cfg");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    reset_cfg _rhs;
    super.do_copy(rhs); 
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      has_clk    = _rhs.has_clk;
      active_val = _rhs.active_val;
    end
  endfunction

endclass
