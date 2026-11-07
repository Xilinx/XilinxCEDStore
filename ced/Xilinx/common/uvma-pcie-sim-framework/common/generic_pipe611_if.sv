// Written in accordance with PIPE spec Rev. 6.1.1, released Mar. 2022
interface generic_pipe611_if;

  logic        Pclk; //Xilinx MAC drives this 

  // PHY Inputs
  logic        Reset_;
  logic [31:0] TxData;
  logic [ 3:0] TxDataK;
  logic        TxDataValid;
  logic        TxStartBlock;
  logic        TxDetectRxLoopback;
  logic        TxCompliance;
  logic [ 3:0] TxSyncHeader;
  logic [ 3:0] TxElecIdle;
  logic [17:0] TxDeemph;
  logic [ 3:0] PowerDown;
  logic [ 3:0] Rate;
  logic [ 1:0] Width;
  logic [ 4:0] PclkRate;
  logic        RxPolarity;

  // PHY Outputs
  logic [31:0] RxData;
  logic [ 3:0] RxDataK;
  logic        RxDataValid;
  logic        RxStartBlock;
  logic        RxValid; 
  logic        RxElecIdle;
  logic [ 3:0] RxSyncHeader;
  logic [ 2:0] RxStatus;
  logic        PhyStatus;

endinterface
