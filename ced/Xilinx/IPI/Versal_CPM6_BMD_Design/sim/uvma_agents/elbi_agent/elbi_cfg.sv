class elbi_cfg extends base_cfg;

  `uvm_object_utils(elbi_cfg)

  function new(string name = "elbi_cfg");
    super.new(name);
  endfunction

  bit shared_responder;

endclass
