// This module is translating between the Vivado generated CPM6 instance 
// to the UVM interfaces used in the uvma-pcie-sim-framework for CXL. This 
// is specifically designed to be bound at the CPM6 uni-sim instance level 
// e.g.
//   bind CPM6 bind_cxl#(CONTROLLER_0_CXL_MODE, BOT_PL_MUX_MODE,
//                       CONTROLLER_1_CXL_MODE, TOP_PL_MUX_MODE) bind_cxl();
module bind_cxl
import uvm_pkg::*;
#(parameter CTRL0_CXL_MODE, BOT_PL_MUX_MODE,
            CTRL1_CXL_MODE, TOP_PL_MUX_MODE)
();

  `include "uvm_macros.svh"

  // Basic parameter checking
  initial begin
    if (CTRL0_CXL_MODE=="ON"&&BOT_PL_MUX_MODE!="CXL")
      `uvm_fatal("CPM6_PARAMS", "Parameters incorrect | Controller 0=CXL mode, BOT_PL_MUX!=CXL mode")
    if (CTRL1_CXL_MODE=="ON"&&TOP_PL_MUX_MODE!="CXL")
      `uvm_fatal("CPM6_PARAMS", "Parameters incorrect | Controller 1=CXL mode, TOP_PL_MUX!=CXL mode")
  end
  
  cxl_nfi_agent_if    nfi_tx_0(), nfi_tx_1();
  cxl_nfi_agent_if    nfi_rx_0(), nfi_rx_1();
  cxl_credit_agent_if crd_tx_0(), crd_tx_1();
  cxl_credit_agent_if crd_rx_0(), crd_rx_1();
  gpmon_if            cfgsts_0(), cfgsts_1();
  gpmon_if            pm_out_0(), pm_out_1();
  gpdrv_if             pm_in_0(),  pm_in_1();

  initial begin
    // C0
    uvm_config_db#(virtual cxl_credit_agent_if)::set(null, "*", "vif_cxl_rx_crd[0]", crd_rx_0);
    uvm_config_db#(virtual cxl_nfi_agent_if)   ::set(null, "*", "vif_cxl_rx_nfi[0]", nfi_rx_0);
    uvm_config_db#(virtual gpdrv_if)           ::set(null, "*", "vif_cxl_pm_in[0]" ,  pm_in_0);
    uvm_config_db#(virtual gpmon_if)           ::set(null, "*", "vif_cxl_pm_out[0]", pm_out_0);
    uvm_config_db#(virtual gpmon_if)           ::set(null, "*", "vif_cxl_cfgsts[0]", cfgsts_0);
    uvm_config_db#(virtual cxl_credit_agent_if)::set(null, "*", "vif_cxl_tx_crd[0]", crd_tx_0);
    uvm_config_db#(virtual cxl_nfi_agent_if)   ::set(null, "*", "vif_cxl_tx_nfi[0]", nfi_tx_0);
    // C1
    uvm_config_db#(virtual cxl_credit_agent_if)::set(null, "*", "vif_cxl_rx_crd[1]", crd_rx_1);
    uvm_config_db#(virtual cxl_nfi_agent_if)   ::set(null, "*", "vif_cxl_rx_nfi[1]", nfi_rx_1);
    uvm_config_db#(virtual gpdrv_if)           ::set(null, "*", "vif_cxl_pm_in[1]" ,  pm_in_1);
    uvm_config_db#(virtual gpmon_if)           ::set(null, "*", "vif_cxl_pm_out[1]", pm_out_1);
    uvm_config_db#(virtual gpmon_if)           ::set(null, "*", "vif_cxl_cfgsts[1]", cfgsts_1);
    uvm_config_db#(virtual cxl_credit_agent_if)::set(null, "*", "vif_cxl_tx_crd[1]", crd_tx_1);
    uvm_config_db#(virtual cxl_nfi_agent_if)   ::set(null, "*", "vif_cxl_tx_nfi[1]", nfi_tx_1);
  end

  // ----------------
  // Controller 0 
  // ----------------

  if (CTRL0_CXL_MODE == "ON") begin

    // CXL Remote Credit (from link partner)
    assign crd_rx_0.clk = inst.cxl0_clk; 
    assign crd_rx_0.vld = inst.cxl0_rx_credit_valid;
    assign crd_rx_0.req = inst.cxl0_rx_credit_req;
    assign crd_rx_0.dat = inst.cxl0_rx_credit_data;
    assign crd_rx_0.rsp = inst.cxl0_rx_credit_rsp;
    
    // CXL Local Credit (to link partner)
    assign crd_tx_0.clk = inst.cxl0_clk;
    initial begin
      wait (crd_tx_0.agent_driven);
      force inst.cxl0_tx_credit_valid = crd_tx_0.vld;
      force inst.cxl0_tx_credit_req   = crd_tx_0.req;
      force inst.cxl0_tx_credit_data  = crd_tx_0.dat;
      force inst.cxl0_tx_credit_rsp   = crd_tx_0.rsp;
    end
    
    // Config/Status Bus
    assign cfgsts_0.clk        = inst.cxl0_clk;
    assign cfgsts_0.sig[ 0+:2] = inst.cxl0_flit_mode;
    assign cfgsts_0.sig[ 2+:8] = inst.cxl0_error;
    assign cfgsts_0.sig[10+:1] = inst.cxl0_reset;
    assign cfgsts_0.sig[11+:1] = inst.cxl0_dev_cache_en;
    assign cfgsts_0.sig[12+:8] = inst.cxl0_dev_mem_en;
    assign cfgsts_0.sig[20+:8] = inst.cxl0_dev_rst_mem_clr_enable;
    assign cfgsts_0.sig[28+:1] = inst.cxl0_bi_enable;
    assign cfgsts_0.sig[29+:8] = inst.cxl0_initiate_cxl_rst;
    assign cfgsts_0.sig[37+:1] = inst.cxl0_disable_caching;
    assign cfgsts_0.sig[38+:1] = inst.cxl0_initiate_cache_wr_invld;
    assign cfgsts_0.sig[39+:1] = inst.cxl0_mdh_disable;
    assign cfgsts_0.sig[40+:1] = inst.cxl0_io_en;
    assign cfgsts_0.sig[41+:1] = inst.cxl0_link_up;
    assign cfgsts_0.sig[42+:1] = inst.cxl0_emd_enable;
    assign cfgsts_0.sig[43+:4] = inst.cxl0_vlsm_mc_state;
    assign cfgsts_0.sig[47+:8] = inst.cxl0_mld_hot_rst_active;
    
    // CXL Power Mgmt (out)
    assign pm_out_0.clk       = inst.cxl0_clk;
    assign pm_out_0.sig[32:0] = inst.cxl0_pm_out;

    // CXL Power Mgmt (in)
    assign pm_in_0.clk       = inst.cxl0_clk;
    assign pm_in_0.sig[33:0] = inst.cxl0_pm_in;

    // NFI Rx (from link)
    assign nfi_rx_0.clk     = inst.cxl0_clk;
    assign nfi_rx_0.data    = inst.cxl0_rx_data;   
    assign nfi_rx_0.parity  = inst.cxl0_rx_parity;
    assign nfi_rx_0.valid   = inst.cxl0_rx_valid; 
    assign nfi_rx_0.viral   = inst.cxl0_rx_viral; 
    assign nfi_rx_0.adf     = inst.cxl0_rx_adf;   
    // - Slotset 2
    assign nfi_rx_0.dec_sop[2] = inst.cxl0_rx_dec_assists[(2*16+12)+:4]; 
    assign nfi_rx_0.dec_eop[2] = inst.cxl0_rx_dec_assists[(2*16+ 8)+:4]; 
    assign nfi_rx_0.dec_be [2] = inst.cxl0_rx_dec_assists[(2*16+ 4)+:4]; 
    assign nfi_rx_0.dec_mem[2] = inst.cxl0_rx_dec_assists[(2*16+ 0)+:4]; 
    // - Slotset 1
    assign nfi_rx_0.dec_sop[1] = inst.cxl0_rx_dec_assists[(1*16+12)+:4]; 
    assign nfi_rx_0.dec_eop[1] = inst.cxl0_rx_dec_assists[(1*16+ 8)+:4]; 
    assign nfi_rx_0.dec_be [1] = inst.cxl0_rx_dec_assists[(1*16+ 4)+:4]; 
    assign nfi_rx_0.dec_mem[1] = inst.cxl0_rx_dec_assists[(1*16+ 0)+:4]; 
    // - Slotset 0
    assign nfi_rx_0.dec_sop[0] = inst.cxl0_rx_dec_assists[(0*16+12)+:4]; 
    assign nfi_rx_0.dec_eop[0] = inst.cxl0_rx_dec_assists[(0*16+ 8)+:4]; 
    assign nfi_rx_0.dec_be [0] = inst.cxl0_rx_dec_assists[(0*16+ 4)+:4]; 
    assign nfi_rx_0.dec_mem[0] = inst.cxl0_rx_dec_assists[(0*16+ 0)+:4]; 
    // Agent cannot backpressure CPM6, but agent monitor requires this
    assign nfi_rx_0.ready = '1;
    
    // NFI Tx (towards link)
    assign nfi_tx_0.clk   = inst.cxl0_clk;
    assign nfi_tx_0.ready = inst.cxl0_tx_ready;
    initial begin
      wait (nfi_tx_0.agent_driven);
      force inst.cxl0_pl_ready  = 1; //sideband; could be from gpdrv_if
      force inst.cxl0_tx_data   = nfi_tx_0.data;  
      force inst.cxl0_tx_parity = nfi_tx_0.parity;
      force inst.cxl0_tx_valid  = nfi_tx_0.valid;
      force inst.cxl0_tx_viral  = nfi_tx_0.viral;
      force inst.cxl0_tx_adf    = nfi_tx_0.adf;
      force inst.cxl0_tx_last   = nfi_tx_0.last;
    end
    // Decode assists not used on transmit path, so tie-off
    assign nfi_tx_0.dec_sop = '0;
    assign nfi_tx_0.dec_eop = '0;
    assign nfi_tx_0.dec_mem = '0;
    assign nfi_tx_0.dec_be  = '0;

  end

  // ----------------
  // Controller 1 
  // ----------------

  if (CTRL1_CXL_MODE == "ON") begin

    // CXL Remote Credit (from link partner)
    assign crd_rx_1.clk = inst.cxl1_clk; 
    assign crd_rx_1.vld = inst.cxl1_rx_credit_valid;
    assign crd_rx_1.req = inst.cxl1_rx_credit_req;
    assign crd_rx_1.dat = inst.cxl1_rx_credit_data;
    assign crd_rx_1.rsp = inst.cxl1_rx_credit_rsp;
    
    // CXL Local Credit (to link partner)
    assign crd_tx_1.clk = inst.cxl1_clk;
    initial begin
      wait (crd_tx_1.agent_driven);
      force inst.cxl1_tx_credit_valid = crd_tx_1.vld;
      force inst.cxl1_tx_credit_req   = crd_tx_1.req;
      force inst.cxl1_tx_credit_data  = crd_tx_1.dat;
      force inst.cxl1_tx_credit_rsp   = crd_tx_1.rsp;
    end
    
    // Config/Status Bus
    assign cfgsts_1.clk        = inst.cxl1_clk;
    assign cfgsts_1.sig[ 0+:2] = inst.cxl1_flit_mode;
    assign cfgsts_1.sig[ 2+:8] = inst.cxl1_error;
    assign cfgsts_1.sig[10+:1] = inst.cxl1_reset;
    assign cfgsts_1.sig[11+:1] = inst.cxl1_dev_cache_en;
    assign cfgsts_1.sig[12+:8] = inst.cxl1_dev_mem_en;
    assign cfgsts_1.sig[20+:8] = inst.cxl1_dev_rst_mem_clr_enable;
    assign cfgsts_1.sig[28+:1] = inst.cxl1_bi_enable;
    assign cfgsts_1.sig[29+:8] = inst.cxl1_initiate_cxl_rst;
    assign cfgsts_1.sig[37+:1] = inst.cxl1_disable_caching;
    assign cfgsts_1.sig[38+:1] = inst.cxl1_initiate_cache_wr_invld;
    assign cfgsts_1.sig[39+:1] = inst.cxl1_mdh_disable;
    assign cfgsts_1.sig[40+:1] = inst.cxl1_io_en;
    assign cfgsts_1.sig[41+:1] = inst.cxl1_link_up;
    assign cfgsts_1.sig[42+:1] = inst.cxl1_emd_enable;
    assign cfgsts_1.sig[43+:4] = inst.cxl1_vlsm_mc_state;
    assign cfgsts_1.sig[47+:8] = inst.cxl1_mld_hot_rst_active;
    
    // CXL Power Mgmt (out)
    assign pm_out_1.clk       = inst.cxl1_clk;
    assign pm_out_1.sig[32:0] = inst.cxl1_pm_out;

    // CXL Power Mgmt (in)
    assign pm_in_1.clk       = inst.cxl1_clk;
    assign pm_in_1.sig[33:0] = inst.cxl1_pm_in;

    // NFI Rx (from link)
    assign nfi_rx_1.clk     = inst.cxl1_clk;
    assign nfi_rx_1.data    = inst.cxl1_rx_data;   
    assign nfi_rx_1.parity  = inst.cxl1_rx_parity;
    assign nfi_rx_1.valid   = inst.cxl1_rx_valid; 
    assign nfi_rx_1.viral   = inst.cxl1_rx_viral; 
    assign nfi_rx_1.adf     = inst.cxl1_rx_adf;   
    // - Slotset 2
    assign nfi_rx_1.dec_sop[2] = inst.cxl1_rx_dec_assists[(2*16+12)+:4]; 
    assign nfi_rx_1.dec_eop[2] = inst.cxl1_rx_dec_assists[(2*16+ 8)+:4]; 
    assign nfi_rx_1.dec_be [2] = inst.cxl1_rx_dec_assists[(2*16+ 4)+:4]; 
    assign nfi_rx_1.dec_mem[2] = inst.cxl1_rx_dec_assists[(2*16+ 0)+:4]; 
    // - Slotset 1
    assign nfi_rx_1.dec_sop[1] = inst.cxl1_rx_dec_assists[(1*16+12)+:4]; 
    assign nfi_rx_1.dec_eop[1] = inst.cxl1_rx_dec_assists[(1*16+ 8)+:4]; 
    assign nfi_rx_1.dec_be [1] = inst.cxl1_rx_dec_assists[(1*16+ 4)+:4]; 
    assign nfi_rx_1.dec_mem[1] = inst.cxl1_rx_dec_assists[(1*16+ 0)+:4]; 
    // - Slotset 0
    assign nfi_rx_1.dec_sop[0] = inst.cxl1_rx_dec_assists[(0*16+12)+:4]; 
    assign nfi_rx_1.dec_eop[0] = inst.cxl1_rx_dec_assists[(0*16+ 8)+:4]; 
    assign nfi_rx_1.dec_be [0] = inst.cxl1_rx_dec_assists[(0*16+ 4)+:4]; 
    assign nfi_rx_1.dec_mem[0] = inst.cxl1_rx_dec_assists[(0*16+ 0)+:4]; 
    // Agent cannot backpressure CPM6, but agent monitor requires this
    assign nfi_rx_1.ready = '1;
    
    // NFI Tx (towards link)
    assign nfi_tx_1.clk   = inst.cxl1_clk;
    assign nfi_tx_1.ready = inst.cxl1_tx_ready;
    initial begin
      wait (nfi_tx_1.agent_driven);
      force inst.cxl1_pl_ready  = 1; //sideband; could be from gpdrv_if
      force inst.cxl1_tx_data   = nfi_tx_1.data;  
      force inst.cxl1_tx_parity = nfi_tx_1.parity;
      force inst.cxl1_tx_valid  = nfi_tx_1.valid;
      force inst.cxl1_tx_viral  = nfi_tx_1.viral;
      force inst.cxl1_tx_adf    = nfi_tx_1.adf;
      force inst.cxl1_tx_last   = nfi_tx_1.last;
    end
    // Decode assists not used on transmit path, so tie-off
    assign nfi_tx_1.dec_sop = '0;
    assign nfi_tx_1.dec_eop = '0;
    assign nfi_tx_1.dec_mem = '0;
    assign nfi_tx_1.dec_be  = '0;

  end

endmodule
