module aximon_connect(cpm6_axi512_fab_mst_if vif_master, aximon_if vif_monitor);
    // Write Address Channel
    assign vif_monitor.awaddr  = {'0, vif_master.awaddr};
    assign vif_monitor.awlen   = {'0, vif_master.awlen};
    assign vif_monitor.awsize  = {'0, vif_master.awsize};
    assign vif_monitor.awburst = {'0, vif_master.awburst};
    assign vif_monitor.awcache = {'0, vif_master.awcache};
    assign vif_monitor.awid    = {'0, vif_master.awid};
    assign vif_monitor.awlock  = {'0, vif_master.awlock};
    assign vif_monitor.awprot  = {'0, vif_master.awprot};
    assign vif_monitor.awqos   = {'0, vif_master.awqos};
    assign vif_monitor.awuser  = {'0, vif_master.awuser};
    assign vif_monitor.awvalid = {'0, vif_master.awvalid};
    assign vif_monitor.awready = {'0, vif_master.awready};
    
    // Write Data Channel
    assign vif_monitor.wdata  = {'0, vif_master.wdata};
    assign vif_monitor.wstrb  = {'0, vif_master.wstrb};
    assign vif_monitor.wlast  = {'0, vif_master.wlast};
    assign vif_monitor.wuser  = {'0, vif_master.wuser};
    assign vif_monitor.wvalid = {'0, vif_master.wvalid};
    assign vif_monitor.wready = {'0, vif_master.wready};
    
    // Write Response Channel
    assign vif_monitor.bid    = {'0, vif_master.bid};
    assign vif_monitor.bresp  = {'0, vif_master.bresp};
    assign vif_monitor.buser  = {'0, vif_master.buser};
    assign vif_monitor.bvalid = {'0, vif_master.bvalid};
    assign vif_monitor.bready = {'0, vif_master.bready};
    
    // Read Address Channel
    assign vif_monitor.araddr  = {'0, vif_master.araddr};
    assign vif_monitor.arburst = {'0, vif_master.arburst};
    assign vif_monitor.arcache = {'0, vif_master.arcache};
    assign vif_monitor.arid    = {'0, vif_master.arid};
    assign vif_monitor.arlen   = {'0, vif_master.arlen};
    assign vif_monitor.arlock  = {'0, vif_master.arlock};
    assign vif_monitor.arprot  = {'0, vif_master.arprot};
    assign vif_monitor.arqos   = {'0, vif_master.arqos};
    assign vif_monitor.arsize  = {'0, vif_master.arsize};
    assign vif_monitor.aruser  = {'0, vif_master.aruser};
    assign vif_monitor.arvalid = {'0, vif_master.arvalid};
    assign vif_monitor.arready = {'0, vif_master.arready};
    
    // Read Data Channel
    assign vif_monitor.rdata  = {'0, vif_master.rdata};
    assign vif_monitor.rid    = {'0, vif_master.rid};
    assign vif_monitor.rresp  = {'0, vif_master.rresp};
    assign vif_monitor.rlast  = {'0, vif_master.rlast};
    assign vif_monitor.ruser  = {'0, vif_master.ruser};
    assign vif_monitor.rvalid = {'0, vif_master.rvalid};
    assign vif_monitor.rready = {'0, vif_master.rready};
endmodule

module bind_cpm_pl_axi
  import uvm_pkg::*;
();

  `include "uvm_macros.svh"

  aximon_if cpm_pl_axi_if_0();
  aximon_if cpm_pl_axi_if_1();
  aximon_if cpm_pl_axi_if_2();
  aximon_if cpm_pl_axi_if_3();

  assign cpm_pl_axi_if_0.clk = inst.aclk0;
  assign cpm_pl_axi_if_1.clk = inst.aclk0;
  assign cpm_pl_axi_if_2.clk = inst.aclk0;
  assign cpm_pl_axi_if_3.clk = inst.aclk0;

  aximon_connect u_0 (inst.fab_demux_inst.m_axi0, cpm_pl_axi_if_0);
  aximon_connect u_1 (inst.fab_demux_inst.m_axi1, cpm_pl_axi_if_1);
  aximon_connect u_2 (inst.fab_demux_inst.m_axi2, cpm_pl_axi_if_2);
  aximon_connect u_3 (inst.fab_demux_inst.m_axi3, cpm_pl_axi_if_3);

  initial begin
    uvm_config_db#(virtual aximon_if)::set(null, "*", "cpm_pl_axi_if[0]", cpm_pl_axi_if_0);
    uvm_config_db#(virtual aximon_if)::set(null, "*", "cpm_pl_axi_if[1]", cpm_pl_axi_if_1);
    uvm_config_db#(virtual aximon_if)::set(null, "*", "cpm_pl_axi_if[2]", cpm_pl_axi_if_2);
    uvm_config_db#(virtual aximon_if)::set(null, "*", "cpm_pl_axi_if[3]", cpm_pl_axi_if_3);
  end
endmodule
