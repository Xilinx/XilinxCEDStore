module bind_cpm_noc_axi
  import uvm_pkg::*;
();

  `include "uvm_macros.svh"

  aximon_if cpm_noc_axi_if_0();
  aximon_if cpm_noc_axi_if_1();

  initial begin
    uvm_config_db#(virtual aximon_if)::set(null, "*", "cpm_noc_axi_if[0]", cpm_noc_axi_if_0);
    uvm_config_db#(virtual aximon_if)::set(null, "*", "cpm_noc_axi_if[1]", cpm_noc_axi_if_1);
  end

  assign cpm_noc_axi_if_0.clk = inst.lpd_swclk;
  assign cpm_noc_axi_if_1.clk = inst.lpd_swclk;

  always_comb begin
    // Write Address Channel
    cpm_noc_axi_if_0.awaddr  = {'0, inst.m_axi0_ps_awaddr};
    cpm_noc_axi_if_0.awlen   = {'0, inst.m_axi0_ps_awlen};
    cpm_noc_axi_if_0.awsize  = {'0, inst.m_axi0_ps_awsize};
    cpm_noc_axi_if_0.awburst = {'0, inst.m_axi0_ps_awburst};
    cpm_noc_axi_if_0.awcache = {'0, inst.m_axi0_ps_awcache};
    cpm_noc_axi_if_0.awid    = {'0, inst.m_axi0_ps_awid};
    cpm_noc_axi_if_0.awlock  = {'0, inst.m_axi0_ps_awlock};
    cpm_noc_axi_if_0.awprot  = {'0, inst.m_axi0_ps_awprot};
    cpm_noc_axi_if_0.awqos   = {'0, inst.m_axi0_ps_awqos};
    cpm_noc_axi_if_0.awuser  = {'0, inst.m_axi0_ps_awuser};
    cpm_noc_axi_if_0.awvalid = {'0, inst.m_axi0_ps_awvalid};
    cpm_noc_axi_if_0.awready = {'0, inst.m_axi0_ps_awready};
    
    // Write Data Channel
    cpm_noc_axi_if_0.wdata  = {'0, inst.m_axi0_ps_wdata};
    cpm_noc_axi_if_0.wstrb  = {'0, inst.m_axi0_ps_wstrb};
    cpm_noc_axi_if_0.wlast  = {'0, inst.m_axi0_ps_wlast};
    cpm_noc_axi_if_0.wuser  = {'0, inst.m_axi0_ps_wuser};
    cpm_noc_axi_if_0.wvalid = {'0, inst.m_axi0_ps_wvalid};
    cpm_noc_axi_if_0.wready = {'0, inst.m_axi0_ps_wready};
    
    // Write Response Channel
    cpm_noc_axi_if_0.bid    = {'0, inst.m_axi0_ps_bid};
    cpm_noc_axi_if_0.bresp  = {'0, inst.m_axi0_ps_bresp};
    cpm_noc_axi_if_0.buser  = {'0, inst.m_axi0_ps_buser};
    cpm_noc_axi_if_0.bvalid = {'0, inst.m_axi0_ps_bvalid};
    cpm_noc_axi_if_0.bready = {'0, inst.m_axi0_ps_bready};
    
    // Read Address Channel
    cpm_noc_axi_if_0.araddr  = {'0, inst.m_axi0_ps_araddr};
    cpm_noc_axi_if_0.arburst = {'0, inst.m_axi0_ps_arburst};
    cpm_noc_axi_if_0.arcache = {'0, inst.m_axi0_ps_arcache};
    cpm_noc_axi_if_0.arid    = {'0, inst.m_axi0_ps_arid};
    cpm_noc_axi_if_0.arlen   = {'0, inst.m_axi0_ps_arlen};
    cpm_noc_axi_if_0.arlock  = {'0, inst.m_axi0_ps_arlock};
    cpm_noc_axi_if_0.arprot  = {'0, inst.m_axi0_ps_arprot};
    cpm_noc_axi_if_0.arqos   = {'0, inst.m_axi0_ps_arqos};
    cpm_noc_axi_if_0.arsize  = {'0, inst.m_axi0_ps_arsize};
    cpm_noc_axi_if_0.aruser  = {'0, inst.m_axi0_ps_aruser};
    cpm_noc_axi_if_0.arvalid = {'0, inst.m_axi0_ps_arvalid};
    cpm_noc_axi_if_0.arready = {'0, inst.m_axi0_ps_arready};
    
    // Read Data Channel
    cpm_noc_axi_if_0.rdata  = {'0, inst.m_axi0_ps_rdata};
    cpm_noc_axi_if_0.rid    = {'0, inst.m_axi0_ps_rid};
    cpm_noc_axi_if_0.rresp  = {'0, inst.m_axi0_ps_rresp};
    cpm_noc_axi_if_0.rlast  = {'0, inst.m_axi0_ps_rlast};
    cpm_noc_axi_if_0.ruser  = {'0, inst.m_axi0_ps_ruser};
    cpm_noc_axi_if_0.rvalid = {'0, inst.m_axi0_ps_rvalid};
    cpm_noc_axi_if_0.rready = {'0, inst.m_axi0_ps_rready};

    // Write Address Channel
    cpm_noc_axi_if_1.awaddr  = {'0, inst.m_axi1_ps_awaddr};
    cpm_noc_axi_if_1.awlen   = {'0, inst.m_axi1_ps_awlen};
    cpm_noc_axi_if_1.awsize  = {'0, inst.m_axi1_ps_awsize};
    cpm_noc_axi_if_1.awburst = {'0, inst.m_axi1_ps_awburst};
    cpm_noc_axi_if_1.awcache = {'0, inst.m_axi1_ps_awcache};
    cpm_noc_axi_if_1.awid    = {'0, inst.m_axi1_ps_awid};
    cpm_noc_axi_if_1.awlock  = {'0, inst.m_axi1_ps_awlock};
    cpm_noc_axi_if_1.awprot  = {'0, inst.m_axi1_ps_awprot};
    cpm_noc_axi_if_1.awqos   = {'0, inst.m_axi1_ps_awqos};
    cpm_noc_axi_if_1.awuser  = {'0, inst.m_axi1_ps_awuser};
    cpm_noc_axi_if_1.awvalid = {'0, inst.m_axi1_ps_awvalid};
    cpm_noc_axi_if_1.awready = {'0, inst.m_axi1_ps_awready};
    
    // Write Data Channel
    cpm_noc_axi_if_1.wdata  = {'0, inst.m_axi1_ps_wdata};
    cpm_noc_axi_if_1.wstrb  = {'0, inst.m_axi1_ps_wstrb};
    cpm_noc_axi_if_1.wlast  = {'0, inst.m_axi1_ps_wlast};
    cpm_noc_axi_if_1.wuser  = {'0, inst.m_axi1_ps_wuser};
    cpm_noc_axi_if_1.wvalid = {'0, inst.m_axi1_ps_wvalid};
    cpm_noc_axi_if_1.wready = {'0, inst.m_axi1_ps_wready};
    
    // Write Response Channel
    cpm_noc_axi_if_1.bid    = {'0, inst.m_axi1_ps_bid};
    cpm_noc_axi_if_1.bresp  = {'0, inst.m_axi1_ps_bresp};
    cpm_noc_axi_if_1.buser  = {'0, inst.m_axi1_ps_buser};
    cpm_noc_axi_if_1.bvalid = {'0, inst.m_axi1_ps_bvalid};
    cpm_noc_axi_if_1.bready = {'0, inst.m_axi1_ps_bready};
    
    // Read Address Channel
    cpm_noc_axi_if_1.araddr  = {'0, inst.m_axi1_ps_araddr};
    cpm_noc_axi_if_1.arburst = {'0, inst.m_axi1_ps_arburst};
    cpm_noc_axi_if_1.arcache = {'0, inst.m_axi1_ps_arcache};
    cpm_noc_axi_if_1.arid    = {'0, inst.m_axi1_ps_arid};
    cpm_noc_axi_if_1.arlen   = {'0, inst.m_axi1_ps_arlen};
    cpm_noc_axi_if_1.arlock  = {'0, inst.m_axi1_ps_arlock};
    cpm_noc_axi_if_1.arprot  = {'0, inst.m_axi1_ps_arprot};
    cpm_noc_axi_if_1.arqos   = {'0, inst.m_axi1_ps_arqos};
    cpm_noc_axi_if_1.arsize  = {'0, inst.m_axi1_ps_arsize};
    cpm_noc_axi_if_1.aruser  = {'0, inst.m_axi1_ps_aruser};
    cpm_noc_axi_if_1.arvalid = {'0, inst.m_axi1_ps_arvalid};
    cpm_noc_axi_if_1.arready = {'0, inst.m_axi1_ps_arready};
    
    // Read Data Channel
    cpm_noc_axi_if_1.rdata  = {'0, inst.m_axi1_ps_rdata};
    cpm_noc_axi_if_1.rid    = {'0, inst.m_axi1_ps_rid};
    cpm_noc_axi_if_1.rresp  = {'0, inst.m_axi1_ps_rresp};
    cpm_noc_axi_if_1.rlast  = {'0, inst.m_axi1_ps_rlast};
    cpm_noc_axi_if_1.ruser  = {'0, inst.m_axi1_ps_ruser};
    cpm_noc_axi_if_1.rvalid = {'0, inst.m_axi1_ps_rvalid};
    cpm_noc_axi_if_1.rready = {'0, inst.m_axi1_ps_rready};
  end

endmodule
