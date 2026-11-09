// Drive an aximon_if (IFC) signal-by-signal from an AXI interface (SRC)
// with matching signal names. 
`define AXIMON_CONNECT(SRC, IFC) \
  assign IFC.awaddr  = SRC.awaddr; \
  assign IFC.awlen   = SRC.awlen; \
  assign IFC.awsize  = SRC.awsize; \
  assign IFC.awburst = SRC.awburst; \
  assign IFC.awcache = SRC.awcache; \
  assign IFC.awid    = SRC.awid; \
  assign IFC.awlock  = SRC.awlock; \
  assign IFC.awprot  = SRC.awprot; \
  assign IFC.awqos   = SRC.awqos; \
  assign IFC.awuser  = SRC.awuser; \
  assign IFC.awvalid = SRC.awvalid; \
  assign IFC.awready = SRC.awready; \
  assign IFC.wdata   = SRC.wdata; \
  assign IFC.wstrb   = SRC.wstrb; \
  assign IFC.wlast   = SRC.wlast; \
  assign IFC.wuser   = SRC.wuser; \
  assign IFC.wvalid  = SRC.wvalid; \
  assign IFC.wready  = SRC.wready; \
  assign IFC.bid     = SRC.bid; \
  assign IFC.bresp   = SRC.bresp; \
  assign IFC.buser   = SRC.buser; \
  assign IFC.bvalid  = SRC.bvalid; \
  assign IFC.bready  = SRC.bready; \
  assign IFC.araddr  = SRC.araddr; \
  assign IFC.arburst = SRC.arburst; \
  assign IFC.arcache = SRC.arcache; \
  assign IFC.arid    = SRC.arid; \
  assign IFC.arlen   = SRC.arlen; \
  assign IFC.arlock  = SRC.arlock; \
  assign IFC.arprot  = SRC.arprot; \
  assign IFC.arqos   = SRC.arqos; \
  assign IFC.arsize  = SRC.arsize; \
  assign IFC.aruser  = SRC.aruser; \
  assign IFC.arvalid = SRC.arvalid; \
  assign IFC.arready = SRC.arready; \
  assign IFC.rdata   = SRC.rdata; \
  assign IFC.rid     = SRC.rid; \
  assign IFC.rresp   = SRC.rresp; \
  assign IFC.rlast   = SRC.rlast; \
  assign IFC.ruser   = SRC.ruser; \
  assign IFC.rvalid  = SRC.rvalid; \
  assign IFC.rready  = SRC.rready;

module bind_cpm_pl_axi
  import uvm_pkg::*;
();

  `include "uvm_macros.svh"

  // 4x512b AXI-MM masters to PL
  aximon_if cpm_pl_m_axi_if_0();
  aximon_if cpm_pl_m_axi_if_1();
  aximon_if cpm_pl_m_axi_if_2();
  aximon_if cpm_pl_m_axi_if_3();

  // 1x512b AXI-MM slave from PL (master toward CPM6, top FSR)
  aximon_if cpm_pl_s_axi_if();

  // bottom FSR
  assign cpm_pl_m_axi_if_0.clk = inst.aclk0; 
  assign cpm_pl_m_axi_if_1.clk = inst.aclk0;
  // top FSR
  assign cpm_pl_m_axi_if_2.clk = inst.aclk1;
  assign cpm_pl_m_axi_if_3.clk = inst.aclk1;
  assign cpm_pl_s_axi_if.clk = inst.aclk1;

  // resets (active-low, same domain as the clocks above)
  assign cpm_pl_m_axi_if_0.aresetn = inst.arstn0;
  assign cpm_pl_m_axi_if_1.aresetn = inst.arstn0;
  assign cpm_pl_m_axi_if_2.aresetn = inst.arstn1;
  assign cpm_pl_m_axi_if_3.aresetn = inst.arstn1;
  assign cpm_pl_s_axi_if.aresetn   = inst.arstn1;

  `AXIMON_CONNECT(inst.fab_demux_inst.m_axi0,    cpm_pl_m_axi_if_0)
  `AXIMON_CONNECT(inst.fab_demux_inst.m_axi1,    cpm_pl_m_axi_if_1)
  `AXIMON_CONNECT(inst.fab_demux_inst.m_axi2,    cpm_pl_m_axi_if_2)
  `AXIMON_CONNECT(inst.fab_demux_inst.m_axi3,    cpm_pl_m_axi_if_3)
  `AXIMON_CONNECT(inst.fab_demux_inst.s_axi_top, cpm_pl_s_axi_if)

  initial begin
    uvm_config_db#(virtual aximon_if)::set(null, "*", "cpm_pl_m_axi_if[0]", cpm_pl_m_axi_if_0);
    uvm_config_db#(virtual aximon_if)::set(null, "*", "cpm_pl_m_axi_if[1]", cpm_pl_m_axi_if_1);
    uvm_config_db#(virtual aximon_if)::set(null, "*", "cpm_pl_m_axi_if[2]", cpm_pl_m_axi_if_2);
    uvm_config_db#(virtual aximon_if)::set(null, "*", "cpm_pl_m_axi_if[3]", cpm_pl_m_axi_if_3);
    uvm_config_db#(virtual aximon_if)::set(null, "*", "cpm_pl_s_axi_if", cpm_pl_s_axi_if);
  end
endmodule

`undef AXIMON_CONNECT
