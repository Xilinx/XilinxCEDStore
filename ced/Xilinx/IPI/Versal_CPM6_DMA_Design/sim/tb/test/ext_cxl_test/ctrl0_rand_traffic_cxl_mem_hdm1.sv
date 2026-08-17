class ctrl0_rand_traffic_cxl_mem_hdm1 extends rand_traffic_cxl_mem_hdm1;

  `uvm_component_utils(ctrl0_rand_traffic_cxl_mem_hdm1)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    this_idx = 0;
  endfunction

endclass
