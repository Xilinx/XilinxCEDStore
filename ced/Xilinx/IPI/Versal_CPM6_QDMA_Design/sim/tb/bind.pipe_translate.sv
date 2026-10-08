// This module is translating between the AMD MAC to a generic PIPE interface.
// Theoretically, the MAC uses the PIPE standard interface, but this provides
// an upward referenced assignment to the top level generic PIPE interface and
// aligns the signal naming conventions to the PIPE standard, so it is easy
// to connect a link partner (usually a VIP).
// 
// This module is designed to be bound at a higher level and then navigate
// down to the hierarchy as displayed.  The hierarchy differs between RTL
// and Vivado outputs.
module bind_pipe_translate;

`ifdef CPM6_RTL
  `define ISO_WRAP   i_cpm6_iso_wrap
`else
  `define ISO_WRAP   BUT.uut.Icpm6_atom_X1Y0_R0.Icpm6_core_top.i_cpm6_iso_wrap
`endif
  `define CORE_0     `ISO_WRAP.i_cpm6_pcie_core_0
  `define CORE_1     `ISO_WRAP.i_cpm6_pcie_core_1
  `define DEST_MOD_0 `CORE_0.i_pcie_sim_override
  `define DEST_MOD_1 `CORE_1.i_pcie_sim_override
  `define PIPE0      `DEST_MOD_0.if_pcie_pipe
  `define PIPE1      `DEST_MOD_1.if_pcie_pipe

  timeunit 1ns;
  timeprecision 100ps;

  // ------------------------------------------------------ //
  // -------------------- Link 0 -------------------------- //
  // ------------------------------------------------------ //

  // clk-gen
  bit pipe_clk_0;
 
  assign `DEST_MOD_0.tb_ref_pipe_clk = pipe_clk_0;
 
  initial begin
    force `DEST_MOD_0.override = 1;
    forever pipe_clk_0 = #0.5ns !pipe_clk_0;
  end
 
  // per-lane of link 0
  for (genvar lx=0; lx<8; lx++) begin 
    // --- PHY to MAC --- //
    assign `DEST_MOD_0.tb_pipe_rx_clk[lx]        = gen_pipe_if[lx].RxCLK;
    assign `PIPE0.phy_mac_rxdata[lx*80+:80]      = gen_pipe_if[lx].RxData;
    assign `PIPE0.phy_mac_rxvalid   [lx]         = gen_pipe_if[lx].RxValid;
    assign `PIPE0.phy_mac_phystatus [lx]         = gen_pipe_if[lx].PhyStatus;
    assign `PIPE0.phy_mac_rxelecidle[lx]         = gen_pipe_if[lx].RxElecIdle;
    assign `PIPE0.phy_mac_rxstatus  [lx*3+:3]    = gen_pipe_if[lx].RxStatus;
    assign `PIPE0.phy_mac_rxstandbystatus[lx]    = gen_pipe_if[lx].RxStandbyStatus;
    assign `PIPE0.phy_mac_messagebus[lx*8+:8]    = gen_pipe_if[lx].P2M_MessageBus;
    assign `PIPE0.phy_mac_pclkchangeok[lx]       = gen_pipe_if[lx].PclkChangeOk;
    // --- MAC to PHY --- //
    assign gen_pipe_if[lx].TxData              = `PIPE0.mac_phy_txdata[lx*80+:80];
    assign gen_pipe_if[lx].Rate                = `PIPE0.mac_phy_rate;
    assign gen_pipe_if[lx].TxElecIdle          = `PIPE0.mac_phy_txelecidle[lx*4+:4];
    assign gen_pipe_if[lx].TxDetectRxLoopback  = `PIPE0.mac_phy_txdetectrx_loopback[lx];
    assign gen_pipe_if[lx].TxDataValid         = `PIPE0.mac_phy_txdatavalid[lx];
    assign gen_pipe_if[lx].PowerDown           = `PIPE0.mac_phy_powerdown;
    assign gen_pipe_if[lx].RxStandby           = `PIPE0.mac_phy_rxstandby[lx];
    assign gen_pipe_if[lx].M2P_MessageBus      = `PIPE0.mac_phy_messagebus[lx*8+:8];
    assign gen_pipe_if[lx].Width               = `PIPE0.mac_phy_width;
    assign gen_pipe_if[lx].RxWidth             = `PIPE0.mac_phy_rxwidth;
    assign gen_pipe_if[lx].SerDesArch          = `PIPE0.mac_phy_serdes_arch;
    assign gen_pipe_if[lx].SRISEnable          = `PIPE0.mac_phy_sris_enable;
    assign gen_pipe_if[lx].PclkRate            = `PIPE0.mac_phy_pclk_rate;
    assign gen_pipe_if[lx].PclkChangeAck       = `PIPE0.mac_phy_pclkchangeack[lx];
    assign gen_pipe_if[lx].TxCommonModeDisable = `PIPE0.mac_phy_txcommonmode_disable;
    assign gen_pipe_if[lx].AsyncPowerChangeAck = `PIPE0.mac_phy_asyncpowerchangeack;
    assign gen_pipe_if[lx].Pclk                = `CORE_0.pipe_tx_clk;
    assign gen_pipe_if[lx].Reset_              = `CORE_0.pcie_por_rst_n;
  end

  // ------------------------------------------------------ //
  // -------------------- Link 1 -------------------------- //
  // ------------------------------------------------------ //

  // clk-gen
  bit pipe_clk_1;
  
  assign `DEST_MOD_1.tb_ref_pipe_clk = pipe_clk_1;

  initial begin
    force `DEST_MOD_1.override = 1;
    forever pipe_clk_1 = #0.5ns !pipe_clk_1;
  end

  // per-lane of link 1
  for (genvar ly=0; ly<8; ly++) begin 
    // --- PHY to MAC --- //
    assign `DEST_MOD_1.tb_pipe_rx_clk[ly]        = gen_pipe_if[8+ly].RxCLK;
    assign `PIPE1.phy_mac_rxdata[ly*80+:80]      = gen_pipe_if[8+ly].RxData;
    assign `PIPE1.phy_mac_rxvalid   [ly]         = gen_pipe_if[8+ly].RxValid;
    assign `PIPE1.phy_mac_phystatus [ly]         = gen_pipe_if[8+ly].PhyStatus;
    assign `PIPE1.phy_mac_rxelecidle[ly]         = gen_pipe_if[8+ly].RxElecIdle;
    assign `PIPE1.phy_mac_rxstatus  [ly*3+:3]    = gen_pipe_if[8+ly].RxStatus;
    assign `PIPE1.phy_mac_rxstandbystatus[ly]    = gen_pipe_if[8+ly].RxStandbyStatus;
    assign `PIPE1.phy_mac_messagebus[ly*8+:8]    = gen_pipe_if[8+ly].P2M_MessageBus;
    assign `PIPE1.phy_mac_pclkchangeok[ly]       = gen_pipe_if[8+ly].PclkChangeOk;
    // --- MAC to PHY --- //
    assign gen_pipe_if[8+ly].TxData              = `PIPE1.mac_phy_txdata[ly*80+:80];
    assign gen_pipe_if[8+ly].Rate                = `PIPE1.mac_phy_rate;
    assign gen_pipe_if[8+ly].TxElecIdle          = `PIPE1.mac_phy_txelecidle[ly*4+:4];
    assign gen_pipe_if[8+ly].TxDetectRxLoopback  = `PIPE1.mac_phy_txdetectrx_loopback[ly];
    assign gen_pipe_if[8+ly].TxDataValid         = `PIPE1.mac_phy_txdatavalid[ly];
    assign gen_pipe_if[8+ly].PowerDown           = `PIPE1.mac_phy_powerdown;
    assign gen_pipe_if[8+ly].RxStandby           = `PIPE1.mac_phy_rxstandby[ly]; 
    assign gen_pipe_if[8+ly].M2P_MessageBus      = `PIPE1.mac_phy_messagebus[ly*8+:8];
    assign gen_pipe_if[8+ly].Width               = `PIPE1.mac_phy_width;
    assign gen_pipe_if[8+ly].RxWidth             = `PIPE1.mac_phy_rxwidth;
    assign gen_pipe_if[8+ly].SerDesArch          = `PIPE1.mac_phy_serdes_arch;
    assign gen_pipe_if[8+ly].SRISEnable          = `PIPE1.mac_phy_sris_enable;
    assign gen_pipe_if[8+ly].PclkRate            = `PIPE1.mac_phy_pclk_rate;
    assign gen_pipe_if[8+ly].PclkChangeAck       = `PIPE1.mac_phy_pclkchangeack[ly];
    assign gen_pipe_if[8+ly].TxCommonModeDisable = `PIPE1.mac_phy_txcommonmode_disable;
    assign gen_pipe_if[8+ly].AsyncPowerChangeAck = `PIPE1.mac_phy_asyncpowerchangeack;
    assign gen_pipe_if[8+ly].Pclk                = `CORE_1.pipe_tx_clk;
    assign gen_pipe_if[8+ly].Reset_              = `CORE_1.pcie_por_rst_n;
  end

  `undef ISO_WRAP
  `undef CORE_0
  `undef CORE_1
  `undef DEST_MOD_0
  `undef DEST_MOD_1
  `undef PIPE0
  `undef PIPE1

endmodule
