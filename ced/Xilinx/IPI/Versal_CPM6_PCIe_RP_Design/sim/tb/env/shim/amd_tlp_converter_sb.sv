class amd_tlp_converter_sb extends apci_tlp_sb;

  `uvm_component_utils(amd_tlp_converter_sb)

  amd_mem_tlp amd_mem_tlp_queue[$];

  function new(string name = "amd_tlp_converter_sb", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void write_req(apci_tlp t);
    super.write_req(t);
    if (t.is_mem32() || t.is_mem64())
      amd_mem_tlp_queue.push_back(convert_vip_to_amd_mem(t));
  endfunction

  virtual function void write_rsp(apci_tlp t);
    super.write_rsp(t);
  endfunction

  local function amd_mem_tlp convert_vip_to_amd_mem(apci_tlp vip_tlp);
    amd_mem_tlp amd;
    bit [63:0] addr;
    int        length;
    bit [3:0]  fbe, lbe;

    amd = amd_mem_tlp::type_id::create("amd_tlp");

    if (vip_tlp.is_mem32()) begin
      addr   = {32'h0, vip_tlp.u.mem32.addr};
      length = vip_tlp.u.mem32.length;
      fbe    = vip_tlp.u.mem32.fbe;
      lbe    = vip_tlp.u.mem32.lbe;
    end
    else if (vip_tlp.is_mem64()) begin
      addr   = vip_tlp.u.mem64.addr;
      length = vip_tlp.u.mem64.length;
      fbe    = vip_tlp.u.mem64.fbe;
      lbe    = vip_tlp.u.mem64.lbe;
    end

    // Payload present → write; no payload → read
    if (vip_tlp.payload.size() > 0)
      amd.build_wr(addr, length, vip_tlp.payload, fbe, lbe);
    else
      amd.build_rd(addr, length, fbe, lbe);

    if (vip_tlp.is_flit_mode !== 1'bx)
      amd.fm = vip_tlp.is_flit_mode;

    return amd;
  endfunction

  virtual function void print_amd_tlp(amd_mem_tlp amd, int idx);
    string msg;
    msg = $sformatf("\n--- AMD TLP Format for index %0d ---", idx);
    msg = {msg, $sformatf("\n  Direction: %s", amd.rd ? "READ" : "WRITE")};
    msg = {msg, $sformatf("\n  Address:   0x%016h", amd.addr)};
    msg = {msg, $sformatf("\n  Length:    %0d DW",  amd.length)};
    msg = {msg, $sformatf("\n  First BE:  0x%h",    amd.f_be)};
    msg = {msg, $sformatf("\n  Last BE:   0x%h",    amd.l_be)};
    msg = {msg, $sformatf("\n  Flit Mode: %0b",     amd.fm)};
    msg = {msg, $sformatf("\n  Basic Mode:%0b",     amd.is_basic)};
    if (!amd.rd && amd.data.size() > 0) begin
      msg = {msg, $sformatf("\n  Payload: %0d DW",  amd.data.size())};
      for (int i = 0; i < amd.data.size(); i++) begin
        if (i % 4 == 0) msg = {msg, $sformatf("\n    [%04d]:", i)};
        msg = {msg, $sformatf(" %08h", amd.data[i])};
      end
    end
    msg = {msg, "\n"};
    `uvm_info(get_type_name(), msg, UVM_MEDIUM)
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info(get_type_name(),$sformatf("Printing AMD specific TLP with %0d packets",amd_mem_tlp_queue.size()), UVM_LOW)
    foreach (amd_mem_tlp_queue[i]) begin
      `uvm_info(get_type_name(), "calling print_amd_tlp method", UVM_LOW)
      print_amd_tlp(amd_mem_tlp_queue[i], i);
    end
    `uvm_info(get_type_name(),
      "\n======================End of AMD TLP report phase====================\n",
      UVM_LOW)
  endfunction

endclass
