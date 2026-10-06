 `include "bind.efuse.sv"
 `include "bind.isr.sv"
 `include "bind.cxl.sv"
 `include "bind.elbi.sv"
 `include "bind.cdo_load.sv"
 `include "bind.perstn.sv"
 `include "bind.lpd_por_n.sv"
 `include "bind.ps_vip.sv"
 `include "bind.cpm_pl_axi.sv"
 `include "bind.cpm_noc_axi.sv"

// Currently only used in RTL sim
`include "cdo_loader_sim_if.sv"

// Set +incdir to point to a location BEFORE this directory such that the project-
// specific test package files are picked up instead of the empty ones. This 
// method allows a standardized tb_top to be used but still have project-specific
// tests.
/* >>> pkg.proj_test_pkg.sv
 *   package proj_test_pkg;
 *     import test_pkg::*;
 *     `include "my_test.sv"
 *   endpackage
 * >>> proj_test_pkg_import.sv
 *   import proj_test_pkg::*;
 */
`include "pkg.proj_test_pkg.sv"

module tb_top;

  timeunit 1ns;
  timeprecision 1ps;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // TB parameters
  import tb_params_pkg::*;

  // ------------------------------------------------------------------ //
  // - These control the physical link connections; ergo you can enable 
  //   a link for training if non-zero, connect a subset of lanes of a 
  //   link, or disable a link entirely if zero
  // - Cannot move these to module definition as it breaks SNPS VIP and 
  //   VCS sim for some reason
  // - Examples 
  //   - Questa: vopt ... -G tb_top/LINK0_WIDTH=4
  //   - VCS   : vcs ... -pvalue tb_top.LINK0_WIDTH=4
  // ------------------------------------------------------------------ //
  parameter LINK0_WIDTH = 8; // max=8; 0 means disable
  parameter LINK1_WIDTH = 0; // max=8; 0 means disable
  // ------------------------------------------------------------------ //

  // Basic prints about physical link
  string msg;
  initial begin
    if (LINK0_WIDTH > 8)
      `uvm_fatal("TB_CFG", "Controller 0 can only use 8 lanes maximum for its link; fatal error")
    else if (LINK0_WIDTH)
      msg = $sformatf("TB configured with %0d lane physical connection to Controller 0", LINK0_WIDTH);
    else begin
      msg = "TB configured with no physical connection to Controller 0";
    end
    `uvm_info("TB_CFG", msg, UVM_NONE)
    // -- //
    if (LINK1_WIDTH > 8)
      `uvm_fatal("TB_CFG", "Controller 1 can only use 8 lanes maximum for its link; fatal error")
    else if (LINK1_WIDTH)
      msg = $sformatf("TB configured with %0d lane physical connection to Controller 1", LINK1_WIDTH);
    else begin
      msg = "TB configured with no physical connection to Controller 1";
    end
    `uvm_info("TB_CFG", msg, UVM_NONE)
  end

  import apci_pkg::*;
  import test_pkg::*; //default tests included with framework
  import proj_test_pkg::*; //addl tests added by users

  // Serial sim wires
  logic [7:0] vip2dut_0_p, vip2dut_0_n;
  logic [7:0] dut2vip_0_p, dut2vip_0_n;
  logic [7:0] vip2dut_1_p, vip2dut_1_n;
  logic [7:0] dut2vip_1_p, dut2vip_1_n;

`ifdef PCIE_LINK_PIPE
  // - assignments are upward referencing from bind modules to PIPE
  // - there are a maximum of 16 lanes, which may be bifurcated into a
  //   two seperate links of max 8 lanes: Link0 => 0:7, Link1 => 8:15
  generic_pipe621_if gen_pipe_if[16]();

  // - Provide some common settings for both links
  // - Provide PIPE clock rates and data widths for PIPE interface match the 
  //   implementation by Versal CPIPE (CPM5+); Avery requires both sides "A" 
  //   and "B" match
  `define COMMON_MPIPE_DEF   \
    .NO_RXSTANDY       (1),  \
    .LOW_PIN_COUNT     (1),  \
    .COMMON_CLOCK      (1),  \
    .COMMON_MODE_V     ('z), \
    .PCLK_AS_PHY_INPUT (1),  \
    .A_SERDES_MODE     (1), \
    .B_SERDES_MODE     (1), \
    .MAX_DATA_WIDTH    (APCI_Width_64bit), \
    .DYNAMIC_PRESET_COEF_UPDATES (0), \
    .A_NUM_LANES       (8), \
    .A_GEN1_DATA_WIDTH(APCI_Width_16bit),  .A_GEN1_CLOCK_RATE(APCI_Pclk_125Mhz),  \
    .A_GEN2_DATA_WIDTH(APCI_Width_16bit),  .A_GEN2_CLOCK_RATE(APCI_Pclk_250Mhz),  \
    .A_GEN3_DATA_WIDTH(APCI_Width_32bit),  .A_GEN3_CLOCK_RATE(APCI_Pclk_250Mhz),  \
    .A_GEN4_DATA_WIDTH(APCI_Width_32bit),  .A_GEN4_CLOCK_RATE(APCI_Pclk_500Mhz),  \
    .A_GEN5_DATA_WIDTH(APCI_Width_32bit),  .A_GEN5_CLOCK_RATE(APCI_Pclk_1000Mhz), \
    .A_GEN6_DATA_WIDTH(APCI_Width_64bit),  .A_GEN6_CLOCK_RATE(APCI_Pclk_1000Mhz), \
    .B_NUM_LANES       (8), \
    .B_GEN1_DATA_WIDTH(APCI_Width_16bit),  .B_GEN1_CLOCK_RATE(APCI_Pclk_125Mhz),  \
    .B_GEN2_DATA_WIDTH(APCI_Width_16bit),  .B_GEN2_CLOCK_RATE(APCI_Pclk_250Mhz),  \
    .B_GEN3_DATA_WIDTH(APCI_Width_32bit),  .B_GEN3_CLOCK_RATE(APCI_Pclk_250Mhz),  \
    .B_GEN4_DATA_WIDTH(APCI_Width_32bit),  .B_GEN4_CLOCK_RATE(APCI_Pclk_500Mhz),  \
    .B_GEN5_DATA_WIDTH(APCI_Width_32bit),  .B_GEN5_CLOCK_RATE(APCI_Pclk_1000Mhz), \
    .B_GEN6_DATA_WIDTH(APCI_Width_64bit),  .B_GEN6_CLOCK_RATE(APCI_Pclk_1000Mhz)

  // vip_if[0] = connected to VIP side of Link 0  | dut_if[0] = connected to DUT side of Link 0
  // vip_if[1] = connected to VIP side of Link 1  | dut_if[1] = connected to DUT side of Link 1
  // Interface width is set to maximum; this will be sliced down later
  apci_pipe_intf vip_if0[8](), dut_if0[8]();
  apci_pipe_intf vip_if1[8](), dut_if1[8]();

  if (LINK0_WIDTH) begin
    // PIPE to PIPE black box for Link 0 (DUT Controller 0)
    // - VIP is on "A" side and DUT on "B" side
    apci_mpipe_box #(`COMMON_MPIPE_DEF) pipe_box_link0 (
      .pipeA(vip_if0),
      .pipeB(dut_if0)
    );
  end

  if (LINK1_WIDTH) begin
    // PIPE to PIPE black box for Link 1 (DUT Controller 1)
    // - VIP is on "A" side and DUT on "B" side
    apci_mpipe_box #(`COMMON_MPIPE_DEF) pipe_box_link1 (
      .pipeA(vip_if1),
      .pipeB(dut_if1)
    );
  end

  // Converts from the generic PIPE interface to Avery-specific PIPE interface
  
  `define RXDATA0(I) {dut_if0[lx].RxData9[I],dut_if0[lx].RxDataK[I],dut_if0[lx].RxData[I*8+:8]}
  `define TXDATA0(I) {dut_if0[lx].TxData9[I],dut_if0[lx].TxDataK[I],dut_if0[lx].TxData[I*8+:8]}
  
  // *** LINK 0 *** //
  for (genvar lx=0; lx<LINK0_WIDTH; lx++) begin
    // --- PHY to MAC --- //
    assign gen_pipe_if[lx].RxCLK              = dut_if0[lx].RxCLK;
    assign gen_pipe_if[lx].RxData[(0*10)+:10] = `RXDATA0(0);
    assign gen_pipe_if[lx].RxData[(1*10)+:10] = `RXDATA0(1);
    assign gen_pipe_if[lx].RxData[(2*10)+:10] = `RXDATA0(2);
    assign gen_pipe_if[lx].RxData[(3*10)+:10] = `RXDATA0(3);
    assign gen_pipe_if[lx].RxData[(4*10)+:10] = `RXDATA0(4);
    assign gen_pipe_if[lx].RxData[(5*10)+:10] = `RXDATA0(5);
    assign gen_pipe_if[lx].RxData[(6*10)+:10] = `RXDATA0(6);
    assign gen_pipe_if[lx].RxData[(7*10)+:10] = `RXDATA0(7);
    assign gen_pipe_if[lx].RxValid            = dut_if0[lx].RxValid;
    assign gen_pipe_if[lx].PhyStatus          = dut_if0[lx].PhyStatus;
    assign gen_pipe_if[lx].RxElecIdle         = dut_if0[lx].RxElecIdle;
    assign gen_pipe_if[lx].RxStatus           = dut_if0[lx].RxStatus;
    assign gen_pipe_if[lx].RxStandbyStatus    = dut_if0[lx].RxStandbyStatus;
    assign gen_pipe_if[lx].P2M_MessageBus     = dut_if0[lx].P2M_MessageBus;
    assign gen_pipe_if[lx].PclkChangeOk       = dut_if0[lx].PclkChangeOk;
    // --- MAC to PHY --- //
    assign `TXDATA0(0)                        = gen_pipe_if[lx].TxData[0*10+:10];
    assign `TXDATA0(1)                        = gen_pipe_if[lx].TxData[1*10+:10];
    assign `TXDATA0(2)                        = gen_pipe_if[lx].TxData[2*10+:10];
    assign `TXDATA0(3)                        = gen_pipe_if[lx].TxData[3*10+:10];
    assign `TXDATA0(4)                        = gen_pipe_if[lx].TxData[4*10+:10];
    assign `TXDATA0(5)                        = gen_pipe_if[lx].TxData[5*10+:10];
    assign `TXDATA0(6)                        = gen_pipe_if[lx].TxData[6*10+:10];
    assign `TXDATA0(7)                        = gen_pipe_if[lx].TxData[7*10+:10];
    assign dut_if0[lx].Rate                   = gen_pipe_if[lx].Rate;
    assign dut_if0[lx].TxElecIdle             = gen_pipe_if[lx].TxElecIdle;
    assign dut_if0[lx].TxDetectRx             = gen_pipe_if[lx].TxDetectRxLoopback;
    assign dut_if0[lx].TxDataValid            = gen_pipe_if[lx].TxDataValid;
    assign dut_if0[lx].PowerDown              = gen_pipe_if[lx].PowerDown;
    assign dut_if0[lx].RxStandby              = gen_pipe_if[lx].RxStandby;
    assign dut_if0[lx].M2P_MessageBus         = gen_pipe_if[lx].M2P_MessageBus;
    assign dut_if0[lx].Width                  = gen_pipe_if[lx].Width;
    assign dut_if0[lx].RxWidth                = gen_pipe_if[lx].RxWidth;
    assign dut_if0[lx].SerDesArch             = gen_pipe_if[lx].SerDesArch;
    assign dut_if0[lx].SRISEnable             = gen_pipe_if[lx].SRISEnable;
    assign dut_if0[lx].PclkRate               = gen_pipe_if[lx].PclkRate;
    assign dut_if0[lx].PclkChangeAck          = gen_pipe_if[lx].PclkChangeAck;
    assign dut_if0[lx].TxCommonModeDisable    = gen_pipe_if[lx].TxCommonModeDisable;
    assign dut_if0[lx].AsyncPowerChangeAck    = gen_pipe_if[lx].AsyncPowerChangeAck;
    assign dut_if0[lx].Pclk                   = gen_pipe_if[lx].Pclk;
    assign dut_if0[lx].Reset_                 = gen_pipe_if[lx].Reset_;
  end
  // MAC requires unused lanes driven low
  for (genvar lx=LINK0_WIDTH; lx<8; lx++) begin
    assign gen_pipe_if[lx].PhyStatus          = '0;
  end
  
  `undef RXDATA0
  `undef TXDATA0
  
  `define RXDATA1(I) {dut_if1[ly].RxData9[I],dut_if1[ly].RxDataK[I],dut_if1[ly].RxData[I*8+:8]}
  `define TXDATA1(I) {dut_if1[ly].TxData9[I],dut_if1[ly].TxDataK[I],dut_if1[ly].TxData[I*8+:8]}
  
  // *** LINK 1 *** //
  for (genvar ly=0; ly<LINK1_WIDTH; ly++) begin
    // --- PHY to MAC --- //
    assign gen_pipe_if[8+ly].RxCLK              = dut_if1[ly].RxCLK;
    assign gen_pipe_if[8+ly].RxData[(0*10)+:10] = `RXDATA1(0);
    assign gen_pipe_if[8+ly].RxData[(1*10)+:10] = `RXDATA1(1);
    assign gen_pipe_if[8+ly].RxData[(2*10)+:10] = `RXDATA1(2);
    assign gen_pipe_if[8+ly].RxData[(3*10)+:10] = `RXDATA1(3);
    assign gen_pipe_if[8+ly].RxData[(4*10)+:10] = `RXDATA1(4);
    assign gen_pipe_if[8+ly].RxData[(5*10)+:10] = `RXDATA1(5);
    assign gen_pipe_if[8+ly].RxData[(6*10)+:10] = `RXDATA1(6);
    assign gen_pipe_if[8+ly].RxData[(7*10)+:10] = `RXDATA1(7);
    assign gen_pipe_if[8+ly].RxValid            = dut_if1[ly].RxValid;
    assign gen_pipe_if[8+ly].PhyStatus          = dut_if1[ly].PhyStatus;
    assign gen_pipe_if[8+ly].RxElecIdle         = dut_if1[ly].RxElecIdle;
    assign gen_pipe_if[8+ly].RxStatus           = dut_if1[ly].RxStatus;
    assign gen_pipe_if[8+ly].RxStandbyStatus    = dut_if1[ly].RxStandbyStatus;
    assign gen_pipe_if[8+ly].P2M_MessageBus     = dut_if1[ly].P2M_MessageBus;
    assign gen_pipe_if[8+ly].PclkChangeOk       = dut_if1[ly].PclkChangeOk;
    // --- MAC to PHY --- //
    assign `TXDATA1(0)                          = gen_pipe_if[8+ly].TxData[0*10+:10];
    assign `TXDATA1(1)                          = gen_pipe_if[8+ly].TxData[1*10+:10];
    assign `TXDATA1(2)                          = gen_pipe_if[8+ly].TxData[2*10+:10];
    assign `TXDATA1(3)                          = gen_pipe_if[8+ly].TxData[3*10+:10];
    assign `TXDATA1(4)                          = gen_pipe_if[8+ly].TxData[4*10+:10];
    assign `TXDATA1(5)                          = gen_pipe_if[8+ly].TxData[5*10+:10];
    assign `TXDATA1(6)                          = gen_pipe_if[8+ly].TxData[6*10+:10];
    assign `TXDATA1(7)                          = gen_pipe_if[8+ly].TxData[7*10+:10];
    assign dut_if1[ly].Rate                     = gen_pipe_if[8+ly].Rate;
    assign dut_if1[ly].TxElecIdle               = gen_pipe_if[8+ly].TxElecIdle;
    assign dut_if1[ly].TxDetectRx               = gen_pipe_if[8+ly].TxDetectRxLoopback;
    assign dut_if1[ly].TxDataValid              = gen_pipe_if[8+ly].TxDataValid;
    assign dut_if1[ly].PowerDown                = gen_pipe_if[8+ly].PowerDown;
    assign dut_if1[ly].RxStandby                = gen_pipe_if[8+ly].RxStandby;
    assign dut_if1[ly].M2P_MessageBus           = gen_pipe_if[8+ly].M2P_MessageBus;
    assign dut_if1[ly].Width                    = gen_pipe_if[8+ly].Width;
    assign dut_if1[ly].RxWidth                  = gen_pipe_if[8+ly].RxWidth;
    assign dut_if1[ly].SerDesArch               = gen_pipe_if[8+ly].SerDesArch;
    assign dut_if1[ly].SRISEnable               = gen_pipe_if[8+ly].SRISEnable;
    assign dut_if1[ly].PclkRate                 = gen_pipe_if[8+ly].PclkRate;
    assign dut_if1[ly].PclkChangeAck            = gen_pipe_if[8+ly].PclkChangeAck;
    assign dut_if1[ly].TxCommonModeDisable      = gen_pipe_if[8+ly].TxCommonModeDisable;
    assign dut_if1[ly].AsyncPowerChangeAck      = gen_pipe_if[8+ly].AsyncPowerChangeAck;
    assign dut_if1[ly].Pclk                     = gen_pipe_if[8+ly].Pclk;
    assign dut_if1[ly].Reset_                   = gen_pipe_if[8+ly].Reset_;
  end
  // EDT-1093458 : MAC requires unused lanes driven low
  for (genvar ly=LINK1_WIDTH; ly<8; ly++) begin
    assign gen_pipe_if[8+ly].PhyStatus          = '0;
  end
  
  `undef RXDATA1
  `undef TXDATA1
`else
  apci_pipe_intf vip_if0[8]();
  apci_pipe_intf vip_if1[8]();

  // - Provide some common settings for both links
  // - Provide PIPE clock rates and data widths for PIPE interface match the 
  //   implementation by Versal CPIPE (CPM5+); Avery requires both sides "A" 
  //   and "B" match
  `define COMMON_PHY_DEF \
    .NO_RXSTANDY       (1),  \
    .LOW_PIN_COUNT     (1),  \
    .COMMON_CLOCK      (1),  \
    .COMMON_MODE_V     ('z), \
    .PCLK_AS_PHY_INPUT (1),  \
    .SERDES_MODE       (1),  \
    .LOW_PIN_COUNT     (1),  \
    .DYNAMIC_PRESET_COEF_UPDATES (0), \
    .NUM_LANES (8), \
    .GEN1_DATA_WIDTH(APCI_Width_16bit), .GEN1_CLOCK_RATE(APCI_Pclk_125Mhz),  \
    .GEN2_DATA_WIDTH(APCI_Width_16bit), .GEN2_CLOCK_RATE(APCI_Pclk_250Mhz),  \
    .GEN3_DATA_WIDTH(APCI_Width_32bit), .GEN3_CLOCK_RATE(APCI_Pclk_250Mhz),  \
    .GEN4_DATA_WIDTH(APCI_Width_32bit), .GEN4_CLOCK_RATE(APCI_Pclk_500Mhz),  \
    .GEN5_DATA_WIDTH(APCI_Width_32bit), .GEN5_CLOCK_RATE(APCI_Pclk_1000Mhz), \
    .GEN6_DATA_WIDTH(APCI_Width_64bit), .GEN6_CLOCK_RATE(APCI_Pclk_1000Mhz), \
    .PAM4_2BIT_ENCODE(0)

  // Keep unused upper lanes disconnected
  if (LINK0_WIDTH!=8)
    assign {dut2vip_0_p[7:LINK0_WIDTH], dut2vip_0_n[7:LINK0_WIDTH]} = 'z;

  if (LINK0_WIDTH) begin
    apci_phy #(`COMMON_PHY_DEF) vip_phy0 (
      // Agent to PHY IF
      .pifs     (vip_if0),
      // Agent receive
      .rxp      (dut2vip_0_p),
      .rxn      (dut2vip_0_n),
      // Agent transmit
      .txp      (vip2dut_p[0]),
      .txn      (vip2dut_n[0]),
      // Tie to 1 if unused
      .clkreq_n (1'b1)
    );  
  end

  // Keep unused upper lanes disconnected
  if (LINK1_WIDTH!=8)
    assign {dut2vip_1_p[7:LINK1_WIDTH], dut2vip_1_n[7:LINK1_WIDTH]} = 'z;

  if (LINK1_WIDTH) begin
    apci_phy #(`COMMON_PHY_DEF) vip_phy1 (
      // Agent to PHY IF
      .pifs     (vip_if1),
      // Agent receive
      .rxp      (dut2vip_1_p),
      .rxn      (dut2vip_1_n),
      // Agent transmit
      .txp      (vip2dut_1_p),
      .txn      (vip2dut_1_n),
      // Tie to 1 if unused
      .clkreq_n (1'b1)
    );  
  end

`endif

  // 100 MHz clock generators
  bit refclk_0_p, refclk_0_n;
  assign refclk_0_n = !refclk_0_p;
  // Add some clock phase randomization
  initial if (LINK0_WIDTH) begin
    #($urandom_range(0,9)*1ns);
    #($urandom_range(0,999)*1ps);
    forever refclk_0_p = #5ns !refclk_0_p; 
  end
  bit refclk_1_p, refclk_1_n;
  assign refclk_1_n = !refclk_1_p;
  // Add some clock phase randomization
  initial if (LINK1_WIDTH) begin
    #($urandom_range(0,9)*1ns);
    #($urandom_range(0,999)*1ps);
    forever refclk_1_p = #5ns !refclk_1_p; 
  end
  `include "cpm6_vivado_binds.sv"
  `include "dut_inst.sv"

  // The agent is a SV class object that can function as a multi-port RC or single port RP/EP
  // The UVM env will grab the virtual interface and attach it to the respective object
  for (genvar i=0; i<LINK0_WIDTH; i++) initial
    uvm_config_db#(virtual apci_pipe_intf)::set(null, "*", $sformatf("vip_vif[0][%0d]",i), vip_if0[i]);
  for (genvar i=0; i<LINK1_WIDTH; i++) initial
    uvm_config_db#(virtual apci_pipe_intf)::set(null, "*", $sformatf("vip_vif[1][%0d]",i), vip_if1[i]);

  initial begin
    uvm_config_db#(int)::set(null, "*", "LINK0_WIDTH", LINK0_WIDTH);
    uvm_config_db#(int)::set(null, "*", "LINK1_WIDTH", LINK1_WIDTH);
`ifdef PCIE_LINK_PIPE
    uvm_config_db#(int)::set(null, "*", "PIPE_SIM", 1);
`else
    uvm_config_db#(int)::set(null, "*", "PIPE_SIM", 0);
`endif
  end

  initial run_test("");

endmodule
