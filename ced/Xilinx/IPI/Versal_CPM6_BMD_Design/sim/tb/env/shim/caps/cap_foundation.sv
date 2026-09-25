// Empty class so caps and ecaps can extend from a singular base
class cap_foundation extends uvm_object;

  `uvm_object_utils(cap_foundation)

  function new(string name = "cap_foundation");
    super.new(name);
  endfunction

  // callback methods
  virtual function logic [ 7:0] get_byte(int offset);                    endfunction
  virtual function void         set_byte(int offset, logic [7:0] data);  endfunction
  virtual function logic [31:0] get_dw  (int offset);                    endfunction
  virtual function void         set_dw  (int offset, logic [31:0] data); endfunction

endclass
