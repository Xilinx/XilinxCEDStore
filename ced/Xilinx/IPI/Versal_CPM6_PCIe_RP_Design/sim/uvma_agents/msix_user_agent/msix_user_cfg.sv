class msix_user_cfg extends base_cfg;

  `uvm_object_utils(msix_user_cfg)

  bit            print_vf_always;

  function new(string name = "msix_user_cfg");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    msix_user_cfg _rhs;
    super.do_copy(rhs); 
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      print_vf_always = _rhs.print_vf_always;
    end
  endfunction

endclass
