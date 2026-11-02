// - Written in accordance with PIPE spec Rev. 6.2.1, released May 2023
// - There are two PIPE interfaces for PCIe: known as the "Original PIPE
//   Architecture" (OP) and the "SerDes Architecture" (SA). The SA is newer 
//   and implements minimal digital logic compared to OP.
// - The interface as a whole has common signals and signals ONLY present
//   in the OP or the SA.
interface generic_pipe621_if;

  // "PClk as PHY Output" not supported for >=PCIe5.0
  logic        Pclk; 

  // -----------------------------------------------
  // Command Interface 
  // -----------------------------------------------
  // - PHY inputs
  //   - common
  logic        SerDesArch;
  logic        SRISEnable;
  logic        TxDetectRxLoopback; //N/A for SerDesArch
  logic        TxCommonModeDisable;
  logic [ 3:0] TxElecIdle;
  logic        Reset_;
  logic [ 3:0] PowerDown;
  logic [ 3:0] Rate;
  logic [ 1:0] Width;
  logic [ 4:0] PclkRate;
  logic        RxStandby;
  //   - Original PIPE only
  logic        TxCompliance;
  logic [ 3:0] TxSyncHeader;
  // - PHY outputs
  //   - common
  logic        RxStandbyStatus;
  //   - Original PIPE only
  logic [ 3:0] RxSyncHeader;

  // -----------------------------------------------
  // Status Interface 
  // -----------------------------------------------
  // - PHY inputs
  logic        PclkChangeAck;
  logic        AsyncPowerChangeAck;
  // - PHY outputs
  logic        RxValid; 
  logic        PhyStatus;
  logic        RxElecIdle;
  logic [ 2:0] RxStatus;
  logic        PclkChangeOk;

  // -----------------------------------------------
  // Message Bus Interface 
  // M2P="MAC to PHY", P2M="PHY to MAC"
  // -----------------------------------------------
  // - PHY inputs
  logic [7:0] M2P_MessageBus; 
  // - PHY outputs
  logic [7:0] P2M_MessageBus;

  // -----------------------------------------------
  // Data Interface
  // -----------------------------------------------
  // - PHY Inputs 
  //   - common
  logic [79:0] TxData;
  logic        TxDataValid;
  //   - SerDes only
  //   - Original PIPE only
  logic [ 3:0] TxDataK;
  logic        TxStartBlock;
  // -----------------------------------------------
  // - PHY Outputs
  //   - common
  logic [79:0] RxData;
  //   - SerDes only
  logic        RxCLK;
  logic [ 1:0] RxWidth;
  //   - Original PIPE only
  logic [ 3:0] RxDataK;
  logic        RxDataValid;
  logic        RxStartBlock;

endinterface
