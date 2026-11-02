class global_cfg extends base_cfg;

  `uvm_object_utils(global_cfg)

  bit a2f;

  // GLOBAL specific
  bit viral_en;
  bit fatal_en;
  bit skip_glbl_connection;

  function new(string name = "global_cfg");
    super.new(name);
  endfunction

endclass
