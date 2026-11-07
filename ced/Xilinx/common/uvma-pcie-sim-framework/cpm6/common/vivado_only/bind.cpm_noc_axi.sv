// Drive an aximon_if (IFC) signal-by-signal from the CPM6 AXI ports named
// inst.<PFX>_<signal>. 
`define AXIMON_CONNECT_NOC(IFC, PFX) \
  assign IFC.awaddr  = inst.PFX``_awaddr; \
  assign IFC.awlen   = inst.PFX``_awlen; \
  assign IFC.awsize  = inst.PFX``_awsize; \
  assign IFC.awburst = inst.PFX``_awburst; \
  assign IFC.awcache = inst.PFX``_awcache; \
  assign IFC.awid    = inst.PFX``_awid; \
  assign IFC.awlock  = inst.PFX``_awlock; \
  assign IFC.awprot  = inst.PFX``_awprot; \
  assign IFC.awqos   = inst.PFX``_awqos; \
  assign IFC.awuser  = inst.PFX``_awuser; \
  assign IFC.awvalid = inst.PFX``_awvalid; \
  assign IFC.awready = inst.PFX``_awready; \
  assign IFC.wdata   = inst.PFX``_wdata; \
  assign IFC.wstrb   = inst.PFX``_wstrb; \
  assign IFC.wlast   = inst.PFX``_wlast; \
  assign IFC.wuser   = inst.PFX``_wuser; \
  assign IFC.wvalid  = inst.PFX``_wvalid; \
  assign IFC.wready  = inst.PFX``_wready; \
  assign IFC.bid     = inst.PFX``_bid; \
  assign IFC.bresp   = inst.PFX``_bresp; \
  assign IFC.buser   = inst.PFX``_buser; \
  assign IFC.bvalid  = inst.PFX``_bvalid; \
  assign IFC.bready  = inst.PFX``_bready; \
  assign IFC.araddr  = inst.PFX``_araddr; \
  assign IFC.arburst = inst.PFX``_arburst; \
  assign IFC.arcache = inst.PFX``_arcache; \
  assign IFC.arid    = inst.PFX``_arid; \
  assign IFC.arlen   = inst.PFX``_arlen; \
  assign IFC.arlock  = inst.PFX``_arlock; \
  assign IFC.arprot  = inst.PFX``_arprot; \
  assign IFC.arqos   = inst.PFX``_arqos; \
  assign IFC.arsize  = inst.PFX``_arsize; \
  assign IFC.aruser  = inst.PFX``_aruser; \
  assign IFC.arvalid = inst.PFX``_arvalid; \
  assign IFC.arready = inst.PFX``_arready; \
  assign IFC.rdata   = inst.PFX``_rdata; \
  assign IFC.rid     = inst.PFX``_rid; \
  assign IFC.rresp   = inst.PFX``_rresp; \
  assign IFC.rlast   = inst.PFX``_rlast; \
  assign IFC.ruser   = inst.PFX``_ruser; \
  assign IFC.rvalid  = inst.PFX``_rvalid; \
  assign IFC.rready  = inst.PFX``_rready;

module bind_cpm_noc_axi
  import uvm_pkg::*;
();

  `include "uvm_macros.svh"

  aximon_if cpm_noc_m_axi_if_0();
  aximon_if cpm_noc_m_axi_if_1();
  aximon_if cpm_noc_s_axi_if();

  initial begin
    uvm_config_db#(virtual aximon_if)::set(null, "*", "cpm_noc_m_axi_if[0]", cpm_noc_m_axi_if_0);
    uvm_config_db#(virtual aximon_if)::set(null, "*", "cpm_noc_m_axi_if[1]", cpm_noc_m_axi_if_1);
    uvm_config_db#(virtual aximon_if)::set(null, "*", "cpm_noc_s_axi_if",    cpm_noc_s_axi_if);
  end

  assign cpm_noc_m_axi_if_0.clk = inst.lpd_swclk;
  assign cpm_noc_m_axi_if_1.clk = inst.lpd_swclk;
  assign cpm_noc_s_axi_if.clk   = inst.lpd_swclk;

  // resets (active-low)
  assign cpm_noc_m_axi_if_0.aresetn = inst.lpd_cpm6_por_n;
  assign cpm_noc_m_axi_if_1.aresetn = inst.lpd_cpm6_por_n;
  assign cpm_noc_s_axi_if.aresetn   = inst.lpd_cpm6_por_n;

  // Master AXI (CPM6 towards NoC), two ports
  `AXIMON_CONNECT_NOC(cpm_noc_m_axi_if_0, m_axi0_ps)
  `AXIMON_CONNECT_NOC(cpm_noc_m_axi_if_1, m_axi1_ps)

  // Slave AXI (NoC towards CPM6)
  `AXIMON_CONNECT_NOC(cpm_noc_s_axi_if, s_axi_pcie)

endmodule

`undef AXIMON_CONNECT_NOC
