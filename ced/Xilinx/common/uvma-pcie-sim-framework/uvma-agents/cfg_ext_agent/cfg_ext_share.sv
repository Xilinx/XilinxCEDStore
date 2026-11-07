class cfg_ext_share extends base_share;

  `uvm_object_utils(cfg_ext_share)

  // Associative array for passive slaves
  bit [7:0] cfgspace[bit [11:0]];

  function new(string name = "cfg_ext_share");
    super.new(name);
  endfunction

  function bit poke_dword(bit [11:0] addr, bit [31:0] data);
    if (addr[1:0] != 2'h0) begin
      `uvm_warning(get_type_name, "To poke a dword, use a dword aligned address")
      return 1'b0;
    end
    else begin
      {cfgspace[addr+3], cfgspace[addr+2]} = {data[31:24], data[23:16]};
      {cfgspace[addr+1], cfgspace[addr  ]} = {data[15: 8], data[ 7: 0]};
      return 1'b1;
    end
  endfunction

  function bit poke_hword(bit [11:0] addr, bit [15:0] data);
    if (addr[1:0] != 2'h0 && addr[1:0] != 2'h2) begin
      `uvm_warning(get_type_name, "To poke a hword, use a hword aligned address")
      return 1'b0;
    end
    else begin
      {cfgspace[addr+1], cfgspace[addr]} = {data[15:8], data[7:0]};
      return 1'b1;
    end
  endfunction

  function bit poke_byte(bit [11:0] addr, bit [7:0] data);
    cfgspace[addr] = data; 
    return 1'b1;
  endfunction

  function bit [31:0] peek_dword(bit [11:0] addr);
    bit [31:0] ret;
    if (addr[1:0] != 2'h0)
      `uvm_fatal(get_type_name, "Must align to dword boundary when calling peek_dword")
    else begin
      ret[ 0+:8] = cfgspace.exists(addr)   ? cfgspace[addr]   : 8'h0; 
      ret[ 8+:8] = cfgspace.exists(addr+1) ? cfgspace[addr+1] : 8'h0; 
      ret[16+:8] = cfgspace.exists(addr+2) ? cfgspace[addr+2] : 8'h0; 
      ret[24+:8] = cfgspace.exists(addr+3) ? cfgspace[addr+3] : 8'h0; 
      if (!(cfgspace.exists(addr+3)&&cfgspace.exists(addr+2)&&cfgspace.exists(addr+1)&&cfgspace.exists(addr)))
        `uvm_warning(get_type_name, $sformatf("The dword at address 0x%0h does not fully exist, returning zeroes for undefined bytes", addr))
      return ret;
    end
  endfunction

  function bit [15:0] peek_hword(bit [11:0] addr);
    bit [15:0] ret;
    if (addr[1:0] != 2'h0 && addr[1:0] != 2'h2)
      `uvm_fatal(get_type_name, "Must align to hword boundary when calling peek_hword")
    else begin
      ret[ 0+:8] = cfgspace.exists(addr)   ? cfgspace[addr]   : 8'h0; 
      ret[ 8+:8] = cfgspace.exists(addr+1) ? cfgspace[addr+1] : 8'h0; 
      if (!(cfgspace.exists(addr+1)&&cfgspace.exists(addr)))
        `uvm_warning(get_type_name, $sformatf("The hword at address 0x%0h does not fully exist, returning zeroes for undefined bytes", addr))
      return ret;
    end
  endfunction

  function bit [7:0] peek_byte(bit [11:0] addr);
    bit [7:0] ret = cfgspace.exists(addr) ? cfgspace[addr] : 8'h0; 
    if (!cfgspace.exists(addr))
      `uvm_warning(get_type_name, $sformatf("The byte at address 0x%0h does not fully exist, returning zeroes for undefined byte", addr))
    return ret;
  endfunction

endclass
