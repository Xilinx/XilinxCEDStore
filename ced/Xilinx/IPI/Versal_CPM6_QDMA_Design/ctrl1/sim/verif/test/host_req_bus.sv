class host_req_bus extends uvm_component;
`uvm_component_utils(host_req_bus)
  uvm_event req_ev; // notification: "a request arrived"
  mailbox #(host_req_tr) req_mbx; // payload storage
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    req_ev  = new("req_ev");
    req_mbx = new();
  endfunction
endclass