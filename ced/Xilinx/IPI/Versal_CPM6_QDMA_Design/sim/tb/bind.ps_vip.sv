// Not all methods are implemented here (yet). To find the APIs, refer to 
// the PSX VIP Confluence page or go to a Vivado project's source file:
//   <project>.gen/.../versal_cips_ps_vip_v1_0_1*_apis.sv
interface ps_vip_api_if
  import uvm_pkg::*;
  import ps_vip_api_pkg::*;
();

  `include "uvm_macros.svh"

  task por_reset(bit value);
    inst.por_reset(value);
  endtask

  task pl_gen_reset(bit [3:0] value);
    inst.pl_gen_reset(value);
  endtask

  task pl_gen_clock(bit [1:0] clkid, real freq_mhz);
    inst.pl_gen_clock(clkid, freq_mhz);
  endtask

  task ps_gen_clock(bit [4:0] clkid, real freq_mhz);
    inst.ps_gen_clock(clkid, freq_mhz);
  endtask

  task gen_cips_ps_vip_clock(int freq_mhz);
    inst.gen_cips_ps_vip_clock(freq_mhz);
  endtask

  task cpm_gen_clock(int freq_mhz);
    inst.cpm_gen_clock(freq_mhz);
  endtask

  task cpm_osc_clk_div2_gen_clock(int freq_mhz);
    inst.cpm_osc_clk_div2_gen_clock(freq_mhz);
  endtask

  task set_debug_level_info(int level);
    inst.set_debug_level_info(level);
  endtask

  // This task is attempting to set the passthrough routing where the slave
  // port is the AXI slave that then gets connected to the AXI master. This
  // is confusing when you're calling a simple API that really isn't an AXI
  // slave at all, but that's just how the PS VIP works.
  task set_routing_config(ps_route_slv_e slv, ps_route_mst_e mst, bit en);
    string slv_str, mst_str;
    if (slv.name()=="") 
      `uvm_fatal("ps_vip_api_if::set_routing_config", "Argument 'slv' is an enumerated type; invalid value given")
    case (slv) 
      NOC_PS_PCI_AXI_0 : slv_str = "NOCPSPCIAXI0";  
      CPM_PS_AXI_0     : slv_str = "CPMPSAXI0";
      CPM_PS_AXI_1     : slv_str = "CPMPSAXI1";
      default          : slv_str = slv.name;
    endcase
    if (mst.name()=="") 
      `uvm_fatal("ps_vip_api_if::set_routing_config", "Argument 'mst' is an enumerated type; invalid value given")
    case (mst)
      PS_NOC_PCI_AXI_0 : mst_str = "PSNOCPCIAXI0";
      PS_NOC_PCI_AXI_1 : mst_str = "PSNOCPCIAXI1";
      PS_CPM_PCIE_AXI  : mst_str = "PSCPMPCIEAXI";
      PS_CPM_CFG       : mst_str = "PSCPMCFG";
      default          : mst_str = mst.name;
    endcase
    inst.set_routing_config(slv_str, mst_str, en);
  endtask

  task get_routing_config;
    inst.get_routing_config;
  endtask

  task en_multi_clock_support;
    inst.en_multi_clock_support;
  endtask

  task en_pmc_alias_region;
    inst.en_pmc_alias_region;
  endtask

  task write_data_32(ps_route_slv_e mst, bit [43:0] addr, logic [31:0] data, output logic [1:0] rsp); 
    if (mst.name()=="") 
      `uvm_fatal("ps_vip_api_if::write_data_32", "Argument 'mst' is an enumerated type; invalid value given")
    else if (!(mst inside {NOC_API, A72_API, R5_API}))
      `uvm_fatal("ps_vip_api_if::write_data_32", "Argument 'mst' must be NOC_API, A72_API, or R5_API")
    else
      inst.write_data_32(mst.name(), addr, data, rsp);
  endtask

  task read_data_32(ps_route_slv_e mst, bit [43:0] addr, output logic [31:0] data, output logic [1:0] rsp); 
    if (mst.name()=="") 
      `uvm_fatal("ps_vip_api_if::read_data_32", "Argument 'mst' is an enumerated type; invalid value given")
    else if (!(mst inside {NOC_API, A72_API, R5_API}))
      `uvm_fatal("ps_vip_api_if::read_data_32", "Argument 'mst' must be NOC_API, A72_API, or R5_API")
    else
      inst.read_data_32(mst.name(), addr, data, rsp);
  endtask

  task write_data_128(ps_route_slv_e mst, bit [43:0] addr, logic [127:0] data, output logic [1:0] rsp, input bit [4:0] nbytes = 16); 
    if (mst.name()=="") 
      `uvm_fatal("ps_vip_api_if::write_data_128", "Argument 'mst' is an enumerated type; invalid value given")
    else if (!(mst inside {NOC_API, A72_API, R5_API}))
      `uvm_fatal("ps_vip_api_if::write_data_128", "Argument 'mst' must be NOC_API, A72_API, or R5_API")
    else
      inst.write_data(mst.name(), addr, nbytes, data, rsp);
  endtask

  task read_data_128(ps_route_slv_e mst, bit [43:0] addr, output logic [127:0] data, output logic [1:0] rsp, input bit [4:0] nbytes = 16); 
    if (mst.name()=="") 
      `uvm_fatal("ps_vip_api_if::read_data_128", "Argument 'mst' is an enumerated type; invalid value given")
    else if (!(mst inside {NOC_API, A72_API, R5_API}))
      `uvm_fatal("ps_vip_api_if::read_data_128", "Argument 'mst' must be NOC_API, A72_API, or R5_API")
    else
      inst.read_data(mst.name(), addr, nbytes, data, rsp);
  endtask

endinterface

// This module is designed to be bound into the PSX VIP module. The
// embedded ps_vip_api_if acts as a passthrough container to the PSX
// VIP's built-in APIs so that a UVM TB can call them. This module
// also calls some of the APIs in a common manner. The bind definition
// should be:
//   bind versal_cips_ps_vip_0 bind_ps_vip bind_ps_vip();
module bind_ps_vip
  import uvm_pkg::*;
  import ps_vip_api_pkg::*;
();

  timeunit      1ns;
  timeprecision 1ns;

  `include "uvm_macros.svh"

  ps_vip_api_if ps_vip_api();

  initial
    uvm_config_db#(virtual ps_vip_api_if)::set(null, "*", "ps_vip_api", ps_vip_api); 

  real freq[4];
  initial begin
    ps_vip_api.pl_gen_reset('0); //assert all PL RESETs
    #1us;
    `uvm_info("PS_VIP_API", "Deasserting all 4 PL RESET_N", UVM_NONE)
    ps_vip_api.pl_gen_reset('1); //deassert all PL RESETs
    foreach (freq[ii]) begin
      if ($value$plusargs({$sformatf("PL%0d_CLK",ii),"=%f"},freq[ii])) begin
        `uvm_info("PLUSARG", $sformatf("PL%0d clock frequency specified as +PL%0d_CLK=%f",ii,ii,freq[ii]), UVM_NONE)
        `uvm_info("PS_VIP_API", $sformatf("Instructing PS VIP to generate PL%0d clock as %f MHz",ii,freq[ii]), UVM_NONE)
        ps_vip_api.pl_gen_clock(ii,freq[ii]);
      end
    end
  end

  string msg;
  initial begin
    ps_vip_api.set_debug_level_info(0);     //set debug level to NONE
    ps_vip_api.por_reset(0);                //assert PS VIP internal reset
    ps_vip_api.en_multi_clock_support;      //set: individual clocks per interface versus cips_ps_vip_clk for all
    `uvm_info("PS_VIP_API", "Setting PS VIP internal clock=1000MHz", UVM_NONE)
    ps_vip_api.gen_cips_ps_vip_clock(1000); //selected at random
    #1us;
    ps_vip_api.por_reset(1);                                  //deassert PS VIP internal reset     
    `uvm_info("PS_VIP_API", "Setting LPDCPMINREFCLK=60MHz", UVM_NONE)
    ps_vip_api.cpm_gen_clock(60);                             //LPDCPMINREFCLK (27-60 MHz; CPM6 PLL refclk)
    `uvm_info("PS_VIP_API", "Setting CPMOSCCLKDIV2=230MHz", UVM_NONE)
    ps_vip_api.cpm_osc_clk_div2_gen_clock(230);               //CPMOSCCLKDIV2 (nominal=200MHz; +-15%)
    `uvm_info("PS_VIP_API", "Setting LPD_CPM_TOP_SW_CLK=1000MHz", UVM_NONE)
    ps_vip_api.ps_gen_clock(PSCLK__LPD_CPM_TOP_SW_CLK, 1000); //LPD_CPM_TOP_SW_CLK (550-1150 MHz)
    msg = {"Note: To enable PS VIP to actually initiate or steer traffic, you must grab ",
           "the 'ps_vip_api' virtual interface handle from the cfg db and then call ",
           "'ps_vip_api.set_routing_config(A, B, 1'b1);' in the test."};
    `uvm_info("PS_VIP_API", msg, UVM_NONE)
  end

endmodule
