// (c) Copyright 2009-2018, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
////////////////////////////////////////////////////////////

 
`timescale 1 ns / 1 ps
 
module i2s_transmitter_v1_0_10_ser
#(
  parameter pDWIDTH = 24, // I2S Data Width
  parameter integer PART = 1,
  parameter integer AUD_SAMPLE_SIZE = 24
)
(
  // Audio Clock
  input                   iMClk,
  input                   iMRst,
  
  // I2S Timing In
  input                   iLRClk,
  input                   iSClk,
  input                   iJustfied, 
  input                   iLeft_Right,
  
  // I2S Data Out
  output                  oSData,
  
  // Audio Input
  output                  oAudReady,
  input                   iAudValid,
  input [(2*pDWIDTH)-1:0] iAudData
);

logic               nAudReady;

logic               rLRClkIn;
logic               rLRClkDelayed;
logic               nSClkFallingEdge;
logic               nSClkRisingEdge;
logic               rSClkDelayed;
logic               nLRClkDelayed_jus;
logic [pDWIDTH-1:0] rSDataBuffer;
//logic [31:0]        rSDataOut;

logic [255: 0] rSDataOut_part;
logic [31 : 0] rSDataOut;


assign nSClkFallingEdge = !iSClk & rSClkDelayed;
assign nSClkRisingEdge = iSClk  & !rSClkDelayed;

assign nLRClkDelayed_jus = iJustfied ? iLRClk : rLRClkDelayed;

always_ff @(posedge iMClk)
begin
  // Default
  rSClkDelayed        <= iSClk;
  
  if (iMRst) begin
    rLRClkDelayed     <=  1'b0;
    rLRClkIn          <=  1'b0;
    rSDataOut         <= 32'b0;
    rSDataOut_part    <= 256'b0;
  end
  else begin
    
    if (nSClkRisingEdge) begin
      rLRClkIn   <= iLRClk;
      rLRClkDelayed   <= rLRClkIn;
    end
    
    if (nSClkFallingEdge) begin
      if ( nLRClkDelayed_jus ^ rLRClkIn) begin
        if (iJustfied ^ iLRClk) begin
          // Right channel
          if (iAudValid) begin
	     rSDataOut_part <= {{iAudData[33:32]},{iAudData[63:60]},{iAudData[36+:AUD_SAMPLE_SIZE]},{(250-AUD_SAMPLE_SIZE){1'b0}}};
	     rSDataOut <= iLeft_Right ? {{(32-pDWIDTH){1'b0}},{iAudData[pDWIDTH+:pDWIDTH]}}: {{iAudData[pDWIDTH+:pDWIDTH]},{(32-pDWIDTH){1'b0}}};
            //rSDataOut <= rSDataBuffer;
          end
        end
        else begin
          // Left channel
          if (iAudValid) begin
            rSDataBuffer <= iAudData[pDWIDTH+:pDWIDTH];
	    rSDataOut_part <=  {{iAudData[1:0]},{iAudData[31:28]},{iAudData[4+:AUD_SAMPLE_SIZE]},{(250-AUD_SAMPLE_SIZE){1'b0}}};
	    rSDataOut <= iLeft_Right ? {{(32-pDWIDTH){1'b0}},{iAudData[0+:pDWIDTH]}}: {{iAudData[0+:pDWIDTH]},{(32-pDWIDTH){1'b0}}};
            //rSDataOut <= iAudData[0+:pDWIDTH];
          end
        end
      end
      else begin
        rSDataOut     <= rSDataOut << 1;
	rSDataOut_part <= rSDataOut_part << 1;
      end
    end
  end
end

always_comb
begin
  // Default
  nAudReady = 1'b0;
  
  if (nSClkFallingEdge) begin
    if (rLRClkIn ^ rLRClkDelayed) begin
      if (iJustfied ^ rLRClkIn)
        // Right channel channel
        nAudReady = 1'b1;
    end
  end
end

assign oAudReady = nAudReady;
//assign oSData    = rSDataOut[31];
assign oSData    = (PART == 1)? rSDataOut_part[255] : rSDataOut[31];


endmodule


// (c) Copyright 2009-2018, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
////////////////////////////////////////////////////////////
 
`timescale 1ns / 1ps

module i2s_transmitter_v1_0_10_axi
#(
  parameter pVERSION_NR = 32'h00010000,
  parameter p32BIT_LR = 0
)
(
  // AXI4-Lite bus (cpu control)
  input             iAxiClk,
  input             iAxiResetn,
  // - Write address
  input             iAxi_AWValid,
  output reg        oAxi_AWReady,
  input      [ 7:0] iAxi_AWAddr,
  // - Write data
  input             iAxi_WValid,
  output reg        oAxi_WReady,
  input      [31:0] iAxi_WData,
  // - Write response
  output reg        oAxi_BValid,
  input             iAxi_BReady,
  output reg [ 1:0] oAxi_BResp,
  // - Read address   
  input             iAxi_ARValid,
  output reg        oAxi_ARReady,
  input      [ 7:0] iAxi_ARAddr,
  // - Read data/response
  output reg        oAxi_RValid,
  input             iAxi_RReady, 
  output reg [31:0] oAxi_RData,
  output reg [ 1:0] oAxi_RResp,
  
  output            oIRQ,
  
  input      [31:0] iCoreConfig,
  output            oEnable,
  output            oJustify,
  output            oNormal_extd,
  output            oLeft_Right,
  output            oValidity,
  output     [ 7:0] oSclkDiv,
  
  output     [ 2:0] oChMuxSelect_01,
  output     [ 2:0] oChMuxSelect_23,
  output     [ 2:0] oChMuxSelect_45,
  output     [ 2:0] oChMuxSelect_67,
  
  input             iAudioUnderflow,
  input             iAesBlockComplete,
  input             iAesBlockSyncError,
  input             iAesChannelStatusChanged,
  output            oClearAesChannelStatus,
  input     [191:0] iAesChannelStatus
);

// AXI Bus responses
localparam cAXI4_RESP_OKAY   = 2'b00; // Okay
localparam cAXI4_RESP_SLVERR = 2'b10; // Slave error

// Register map addresses
localparam cADDR_VER          = 'h00; // Version register
localparam cADDR_CFG          = 'h04; // Configuration register
localparam cADDR_CTRL         = 'h08; // Control register
localparam cADDR_VALIDITY     = 'h0C; // Validity override register

localparam cADDR_IRQ_CTRL     = 'h10; // Interrupt Control
localparam cADDR_IRQ_STS      = 'h14; // Interrupt Status

localparam cADDR_I2S_TIMCTRL  = 'h20; // I2S Timing Control

localparam cADDR_CH_01_CTRL   = 'h30; // Audio Channel 0/1 Control
localparam cADDR_CH_23_CTRL   = 'h34; // Audio Channel 2/3 Control
localparam cADDR_CH_45_CTRL   = 'h38; // Audio Channel 4/5 Control
localparam cADDR_CH_67_CTRL   = 'h3C; // Audio Channel 6/7 Control

localparam cADDR_PATGEN_CTRL  = 'h40; // Audio Pattern Generator Control

localparam cADDR_AES_CHSTS_0  = 'h50; // AES Channel Status 0 
localparam cADDR_AES_CHSTS_1  = 'h54; // AES Channel Status 1
localparam cADDR_AES_CHSTS_2  = 'h58; // AES Channel Status 2
localparam cADDR_AES_CHSTS_3  = 'h5C; // AES Channel Status 3
localparam cADDR_AES_CHSTS_4  = 'h60; // AES Channel Status 4
localparam cADDR_AES_CHSTS_5  = 'h64; // AES Channel Status 5


logic [ 31:0] rVersionNr;
logic         rEnable;
logic         rLeft_Right;
logic         rJustify;
logic         rNormal_extd;
logic         rValidity;
logic [  7:0] rSclkDiv;

// IRQ signals
localparam cIRQ_GLOBAL       = 31;
localparam cIRQ_AES_BLKCMPLT = 0;
localparam cIRQ_AES_BSYNCERR = 1;
localparam cIRQ_AES_CHSTSUPD = 2;
localparam cIRQ_AUD_UFLOW    = 3;

logic         rIrq;
logic [ 31:0] rIrqEnables;
logic [ 30:0] rIrqStatus;
logic [ 31:0] rClearIrqs;


logic [  2:0] rChannelMux_01;
logic [  2:0] rChannelMux_23;
logic [  2:0] rChannelMux_45;
logic [  2:0] rChannelMux_67;

logic         rClearAesChannelStatus;
logic [191:0] rAesChannelStatus;


// Input Capture
always_ff @(posedge iAxiClk)
begin
  if (!iAxiResetn) begin
    rAesChannelStatus   <= 192'h0;
  end
  else begin
    if (iAesChannelStatusChanged) begin
      rAesChannelStatus <= iAesChannelStatus;
    end
  end
end

// IRQ Generation
always_ff @(posedge iAxiClk)
begin
  // AES Block complete (192 frames)
  if (iAesBlockComplete) begin
    rIrqStatus[cIRQ_AES_BLKCMPLT]   <= 1'b1;
  end
  else begin
    if (rClearIrqs[cIRQ_AES_BLKCMPLT]) begin
      rIrqStatus[cIRQ_AES_BLKCMPLT] <= 1'b0;
    end
  end
  
  // AES Block Synchronization Error Detected
  if (iAesBlockSyncError) begin
    rIrqStatus[cIRQ_AES_BSYNCERR]   <= 1'b1;
  end
  else begin
    if (rClearIrqs[cIRQ_AES_BSYNCERR]) begin
      rIrqStatus[cIRQ_AES_BSYNCERR] <= 1'b0;
    end
  end
  
  // AES Captured Channel Status Changed
  if (iAesChannelStatusChanged) begin
    rIrqStatus[cIRQ_AES_CHSTSUPD]   <= 1'b1;
  end
  else begin
    if (rClearIrqs[cIRQ_AES_CHSTSUPD]) begin
      rIrqStatus[cIRQ_AES_CHSTSUPD] <= 1'b0;
    end
  end
  
  // Audio Underflow Detected
  if (iAudioUnderflow) begin
    rIrqStatus[cIRQ_AUD_UFLOW]   <= 1'b1;
  end
  else begin
    if (rClearIrqs[cIRQ_AUD_UFLOW]) begin
      rIrqStatus[cIRQ_AUD_UFLOW] <= 1'b0;
    end
  end
  
//  foreach (rIrqStatus[i]) begin
//    if (rIrqEnables[cIRQ_GLOBAL]) begin
//      if (rIrqStatus[i] & rIrqEnables[i]) begin
//        rIrq   <= 1'b1;
//      end
//    end
//  end
  
//  if (rClearIrqs[cIRQ_GLOBAL]) begin
//    rIrq       <= 1'b0;
//  end

  if (rIrqEnables[cIRQ_GLOBAL]) begin
     rIrq <= (rIrqStatus[cIRQ_AES_BLKCMPLT] & rIrqEnables[cIRQ_AES_BLKCMPLT]) || 
             (rIrqStatus[cIRQ_AES_BSYNCERR] & rIrqEnables[cIRQ_AES_BSYNCERR]) || 
             (rIrqStatus[cIRQ_AES_CHSTSUPD] & rIrqEnables[cIRQ_AES_CHSTSUPD]) || 
             (rIrqStatus[cIRQ_AUD_UFLOW] & rIrqEnables[cIRQ_AUD_UFLOW]);
  end
  
  if (!iAxiResetn) begin
    rIrqStatus <= 'h0;
    rIrq       <= 1'b0;
  end
end


////////////////////////////////////////////////////////
// Write channel

typedef enum { sWriteReset,
               sWriteAddr,
               sWriteData,
               sWriteResp
             } tStmAXI4L_Write;
             
tStmAXI4L_Write stmWrite;

logic [7:0] rWriteAddr;

// Statemachine for taking care of the write signals
always_ff @(posedge iAxiClk)
begin
  if (!iAxiResetn)
  begin
    oAxi_AWReady        <= 1'b0;
    oAxi_WReady         <= 1'b0;
    oAxi_BValid         <= 1'b0;
    rWriteAddr          <=  'h0;
    stmWrite            <= sWriteReset;
  end
  else
  begin
    case (stmWrite) 
      sWriteReset :
      begin
        oAxi_AWReady    <= 1'b1;
        oAxi_WReady     <= 1'b0;
        oAxi_BValid     <= 1'b0;
        stmWrite        <= sWriteAddr;
      end
      
      sWriteAddr :
      begin
        oAxi_AWReady    <= 1'b1;
        if (iAxi_AWValid)
        begin
          oAxi_AWReady  <= 1'b0;
          oAxi_WReady   <= 1'b1;
          rWriteAddr    <= iAxi_AWAddr;
          stmWrite      <= sWriteData;
        end
      end
      
      sWriteData :
      begin
        oAxi_WReady     <= 1'b1;
        
        if (iAxi_WValid)
        begin
          oAxi_WReady   <= 1'b0;
          oAxi_BValid   <= 1'b1;
          stmWrite      <= sWriteResp;
        end
      end
      
      sWriteResp :
      begin
        oAxi_BValid     <= 1'b1;
        if (iAxi_BReady)
        begin
          oAxi_BValid   <= 1'b0;
          stmWrite      <= sWriteReset;
        end
      end 
      
      default :
        stmWrite        <= sWriteReset;
    endcase
  end
end

// Write address decoder
always_ff @(posedge iAxiClk)
begin
  if (!iAxiResetn)
  begin
    oAxi_BResp        <= cAXI4_RESP_OKAY;
    rEnable           <= 1'b0;
    rJustify          <= 1'b0;
    rNormal_extd      <= p32BIT_LR;
    rLeft_Right       <= 1'b0;
    rValidity         <= 1'b0;
    rSclkDiv          <= 'h0;
    rIrqEnables       <= 32'b0;
    
    rChannelMux_01    <= 'h1;
    rChannelMux_23    <= 'h2;
    rChannelMux_45    <= 'h3;
    rChannelMux_67    <= 'h4;
        
    rVersionNr        <= pVERSION_NR;
  end
  else
  begin
    // Defaults
    rClearIrqs        <= 'h0;
    rClearAesChannelStatus <= 1'b0;
    
    if (oAxi_WReady && iAxi_WValid)
    begin
      oAxi_BResp      <= cAXI4_RESP_OKAY;
      
      case (rWriteAddr)
        cADDR_VER :
        begin
        end
        
        cADDR_CTRL :
        begin
          rEnable      <= iAxi_WData[0];
          rJustify     <= iAxi_WData[1];
          rLeft_Right  <= iAxi_WData[2];
        //  rNormal_extd <= iAxi_WData[3];
        end

        cADDR_VALIDITY :
        begin
          rValidity     <= iAxi_WData[0];
        end
        
        cADDR_IRQ_CTRL :
        begin
          rIrqEnables[31]  <= iAxi_WData [31];
          rIrqEnables[3:0] <= iAxi_WData [3:0];
        end
        
        cADDR_IRQ_STS :
        begin
          rClearIrqs  <= iAxi_WData;
        end
        
        cADDR_I2S_TIMCTRL :
        begin
          rSclkDiv       <= iAxi_WData[7:0];
        end
        
        cADDR_CH_01_CTRL :
        begin
          rChannelMux_01 <= iAxi_WData[2:0];
        end
        
        cADDR_CH_23_CTRL :
        begin
          rChannelMux_23 <= iAxi_WData[2:0];
        end
        
        cADDR_CH_45_CTRL :
        begin
          rChannelMux_45 <= iAxi_WData[2:0];
        end
        
        cADDR_CH_67_CTRL :
        begin
          rChannelMux_67 <= iAxi_WData[2:0];
        end
        
        cADDR_AES_CHSTS_0 :
        begin
          rClearAesChannelStatus <= 1'b1;
        end
        
        cADDR_AES_CHSTS_1 :
        begin
          rClearAesChannelStatus <= 1'b1;
        end
        
        cADDR_AES_CHSTS_2 :
        begin
          rClearAesChannelStatus <= 1'b1;
        end 
        
        cADDR_AES_CHSTS_3 :
        begin
          rClearAesChannelStatus <= 1'b1;
        end
        
        cADDR_AES_CHSTS_4 :
        begin
          rClearAesChannelStatus <= 1'b1;
        end
        
        cADDR_AES_CHSTS_5 :
        begin
          rClearAesChannelStatus <= 1'b1;
        end

        default :
          oAxi_BResp <= cAXI4_RESP_SLVERR;
      endcase
    end
  end
end

////////////////////////////////////////////////////////
// Read channel

typedef enum { sReadReset,
               sReadAddr,
               sDecodeAddr,
               sReadData
             } tStmAXI4L_Read;
             
tStmAXI4L_Read stmRead;

logic        ReadAddrNOK;
logic [ 7:0] rReadAddr;
logic [31:0] nReadData;

// Statemachine for taking care of the read signals
always_ff @(posedge iAxiClk)
begin
  if (!iAxiResetn)
  begin
    oAxi_ARReady        <= 1'b0;    
    oAxi_RResp          <= cAXI4_RESP_OKAY;
    oAxi_RValid         <= 1'b0;
    oAxi_RData          <=  'h0;
    rReadAddr           <=  'h0;
    stmRead             <= sReadReset;
  end
  else
  begin
    case (stmRead) 
      sReadReset :
      begin
        oAxi_ARReady    <= 1'b1;
        oAxi_RResp      <= cAXI4_RESP_OKAY;
        oAxi_RValid     <= 1'b0;
        oAxi_RData      <=  'h0;
        rReadAddr       <=  'h0;
        stmRead         <= sReadAddr;
      end
      
      sReadAddr :
      begin
        oAxi_ARReady    <= 1'b1;
        if (iAxi_ARValid)
        begin
          oAxi_ARReady  <= 1'b0;
          rReadAddr     <= iAxi_ARAddr;
          stmRead       <= sDecodeAddr;
        end
      end
      
      sDecodeAddr :
      begin
        if (ReadAddrNOK)
          oAxi_RResp    <= cAXI4_RESP_SLVERR;
        else
          oAxi_RResp    <= cAXI4_RESP_OKAY;
          
        oAxi_RData      <= nReadData;
        oAxi_RValid     <= 1'b1;
        stmRead         <= sReadData;
      end
      
      sReadData :
      begin
        oAxi_RValid     <= 1'b1;
        if (iAxi_RReady)
        begin
          oAxi_RValid   <= 1'b0;
          stmRead       <= sReadReset;
        end
      end
      
      default :
        stmRead         <= sReadReset;
    endcase
  end
end

// Read address decoder
always_comb
begin
  ReadAddrNOK        = 1'b0;
  nReadData          =  'h0;
  case (rReadAddr)
    cADDR_VER :
    begin
      nReadData      = rVersionNr;
    end
    
    cADDR_CFG :
    begin
      nReadData      = iCoreConfig;
    end
    
    cADDR_CTRL :
    begin
      nReadData[0]   = rEnable;
      nReadData[1]   = rJustify;
      nReadData[2]   = rLeft_Right;
      nReadData[3]   = rNormal_extd;
    end

    cADDR_VALIDITY :
    begin
      nReadData[0]   = rValidity;
    end
    
    cADDR_IRQ_CTRL :
    begin
      nReadData      = rIrqEnables;
    end
    
    cADDR_IRQ_STS :
    begin
      nReadData      = {1'b0, rIrqStatus};
    end
        
    cADDR_I2S_TIMCTRL :
    begin
      nReadData[7:0] = rSclkDiv;
    end
        
    cADDR_CH_01_CTRL :
    begin
      nReadData[2:0] = rChannelMux_01;
    end
    
    cADDR_CH_23_CTRL :
    begin
      nReadData[2:0] = rChannelMux_23;
    end
    
    cADDR_CH_45_CTRL :
    begin
      nReadData[2:0] = rChannelMux_45;
    end
    
    cADDR_CH_67_CTRL :
    begin
      nReadData[2:0] = rChannelMux_67;
    end
    
    cADDR_AES_CHSTS_0 :
    begin
      nReadData      = rAesChannelStatus[31:0];
    end
    
    cADDR_AES_CHSTS_1 :
    begin
      nReadData      = rAesChannelStatus[63:32];
    end
    
    cADDR_AES_CHSTS_2 :
    begin
      nReadData      = rAesChannelStatus[95:64];
    end
    
    cADDR_AES_CHSTS_3 :
    begin
      nReadData      = rAesChannelStatus[127:96];
    end
    
    cADDR_AES_CHSTS_4 :
    begin
      nReadData      = rAesChannelStatus[159:128];
    end
    
    cADDR_AES_CHSTS_5 :
    begin
      nReadData      = rAesChannelStatus[191:160];
    end
 
    default : 
      ReadAddrNOK    = 1'b1;
  endcase  
end

// Assign the outputs
assign oIRQ           = rIrq;

assign oEnable        = rEnable;
assign oJustify       = rJustify;
assign oNormal_extd   = rNormal_extd;
assign oLeft_Right    = rLeft_Right;
assign oValidity      = rValidity;
assign oSclkDiv       = rSclkDiv;

assign oChMuxSelect_01 = rChannelMux_01;
assign oChMuxSelect_23 = rChannelMux_23;
assign oChMuxSelect_45 = rChannelMux_45;
assign oChMuxSelect_67 = rChannelMux_67;

assign oClearAesChannelStatus = rClearAesChannelStatus;

endmodule


// (c) Copyright 2009-2018, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
////////////////////////////////////////////////////////////


 
`timescale 1 ns / 1 ps
 
module i2s_transmitter_v1_0_10_timgen
#(
  parameter pDWIDTH = 24, // I2S Data Width
  parameter integer PART = 1
)
(
  // Audio Clock
  input        iMClk,
  input        iMRst,
  
  // Timing Ctrl
  input  [7:0] iSClkDiv,
  input        iJustfied,
  input        iNormal_extd,
  
  // Timing Output
  output       oLRClk,
  output       oSClk
);

logic [7:0]  rDivCounter;
logic        rSClk;
logic        rSClkEnable;
logic        rSClkEnable_temp1;
logic        rSClkEnable_temp2;

logic        rLRClk;
logic        rLRClk_256;
logic [15:0] rLRClkCounter;
logic [15:0] rLRClkCounter_256;

//wire  [5:0]  clk_cntr_val;

localparam CNTR_WIDTH = (PART == 1)? 10 : 5;
wire  [CNTR_WIDTH : 0] clk_cntr_val;

//Justified,Extended 32 bit = 32 clocks, else same as Data width
assign clk_cntr_val = (iJustfied  | iNormal_extd ) ? 6'd31 : (pDWIDTH-1);

always_ff @(posedge iMClk)
begin
  // Default
  rSClkEnable     <= 1'b0;
  
  if (iMRst) begin
    rSClk         <= 1'b0;
    rDivCounter   <= 'h0;
    rLRClk        <= 1'b0;
    rLRClkCounter <= 'h0;
  end
  else begin
    if (rDivCounter == 'h0) begin
      rSClkEnable <= 1'b1;
      rSClkEnable_temp1 <= rSClkEnable;
      rSClkEnable_temp2 <= rSClkEnable_temp1;
    end
    
    if (rDivCounter < iSClkDiv-1) begin
      rDivCounter <= rDivCounter + 1;
    end
    else begin
      rDivCounter <= 'h0;
    end
    
    if (rSClkEnable) begin
      rSClk       <= ~rSClk;
      
      if (rSClk) begin
        if (rLRClkCounter < clk_cntr_val) begin
          rLRClkCounter <= rLRClkCounter + 1;
        end
        else begin
          rLRClk        <= ~rLRClk;
          rLRClkCounter <= 'h0;
        end
      end
    end
  end
end

always @(posedge rSClk) begin
if (rSClkEnable_temp2) begin
if (rLRClkCounter_256 < clk_cntr_val) begin
  rLRClkCounter_256 <= rLRClkCounter_256 + 1;
end
else begin
  rLRClk_256        <= ~rLRClk_256;
  rLRClkCounter_256 <= 'h0;
end
end
else begin
rLRClk_256        <= 'h0;
rLRClkCounter_256 <= 'h0;
end
end

assign oSClk  = rSClk;
assign oLRClk = (PART == 1)? rLRClk_256 : rLRClk;

endmodule


// (c) Copyright 2009-2018, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
////////////////////////////////////////////////////////////
 
`timescale 1 ns / 1 ps
 
module i2s_transmitter_v1_0_10_aes_dec
#(

parameter pCHANNELS = 8,
parameter PART = 1

)
(
  // Audio Clock
  input          iClk,
  input          iRst,
  
  // AXI-Stream Audio In
  input  [ 31:0] iAxis_TData,
  input          iAxis_TValid,

  input          iAxis_TValid_other,
  input  [ 2:0]  iAxis_TID,
  
  // Control In
  input          iClearChannelStatus,
  
  // AES Status Out
  output         oAesBlockComplete,
  output         oAesBlockSyncError,
  output         oAesChannelStatusChange,
  output [191:0] oAesChannelStatus
);


localparam cAES_PARITY_BIT = 31;
localparam cAES_CHSTS_BIT  = 30;
localparam cAES_USER_BIT   = 29;
localparam cAES_VLD_BIT    = 28;

//localparam cAES_PREAMB_BSYNC   = 4'b0001; // Start of AES Block (B/Z)
//localparam cAES_PREAMB_SF1SYNC = 4'b0010; // Subframe 1 (M/X)
//localparam cAES_PREAMB_SF2SYNC = 4'b0011; // Subframe 2 (W/Y)

localparam cAES_PREAMB_BSYNC   = (PART == 1)? 4'b0000 : 4'b0001; // Start of AES Block (B/Z)
localparam cAES_PREAMB_SF1SYNC = (PART == 1)? 4'b0001 : 4'b0010; // Subframe 1 (M/X)
localparam cAES_PREAMB_SF2SYNC = (PART == 1)? 4'b0010 : 4'b0011; // Subframe 2 (W/Y)


typedef enum {
  sWaitForBlockStart,
  sRun
} tStmAesDecode;

tStmAesDecode stmAesDecode;


logic [191:0] rChannelStatusIn;
logic [191:0] rChannelStatusCapt;
logic [191:0] rUserDataIn;
logic [191:0] rUserDataCapt;

logic [  3:0] nAesPreambleIn;
logic [  7:0] rAudioFrameCount;
logic         rAesLastFrame;
logic         rAesBlockComplete;
logic         rAesBlockSyncError_int;
logic         rAesBlockSyncError;

logic [  3:0] rChannelStatusDiff;
logic         rAesChannelStatusChange;

logic [2:0]   id_count;
logic [2:0]   id_count1;
logic id_miss;
logic id_miss_err;
logic id_check;
logic [  7:0] rAudioFrameCount_other;
logic         rAesLastFrame_other;
logic rAesBlockSyncError_other;
logic pre_check_mode;


assign nAesPreambleIn = iAxis_TData[3:0];

always_ff @(posedge iClk)
begin
  // Default
  rAesBlockComplete       <= 1'b0;
  rAesChannelStatusChange <= 1'b0;
  rChannelStatusDiff      <= 4'h0;
  
  if (iAxis_TValid) begin
    rChannelStatusIn      <= {iAxis_TData[cAES_CHSTS_BIT], rChannelStatusIn[$size(rChannelStatusIn)-1:1]};
    //rUserDataIn           <= {iAxis_TData[cAES_USER_BIT], rUserDataIn[$size(rUserDataIn)-1:1]};
  end
  
  if (rAesLastFrame) begin
    rChannelStatusCapt <= rChannelStatusIn;
    //rUserDataCapt      <= rUserDataIn;
    rAesBlockComplete  <= 1'b1;
  end
  
  // To ease timing the comparing of the channel status is 
  // split into 4 separate groups of 48bits (192/4) 
  foreach (rChannelStatusDiff[i]) begin
    if (rAesLastFrame) begin
      if (rChannelStatusCapt[i*48+:48] != rChannelStatusIn[i*48+:48]) begin
        rChannelStatusDiff[i] <= 1'b1;
      end
    end
    // Merge the compare results from the groups into a single status indication
    if (rChannelStatusDiff[i]) begin
      rAesChannelStatusChange <= 1'b1;
    end
  end
  
  if (iClearChannelStatus || iRst) begin
    rChannelStatusCapt <= 192'h0;
  end
end


always_ff @(posedge iClk)
begin
    if (iRst) begin
      id_count <= 3'b0;
      id_check <= 1'b0;
      id_count1 <= 3'b0;
      end
    else if ((iAxis_TValid || iAxis_TValid_other) && !id_check) begin
       id_count <= iAxis_TID;
       id_check <= 1'b1;
       id_count1 <= iAxis_TID;
    end
    else if ((iAxis_TValid || iAxis_TValid_other) && id_check) begin
         id_count1 <= iAxis_TID;
         if (id_count == pCHANNELS-1)
            id_count <= 3'b0;
         else
            id_count <= id_count + 1;
    end
    
end

always_ff @(posedge iClk)
begin
    if (iRst)
     id_miss <= 1'b0;
    else if ((iAxis_TValid || iAxis_TValid_other) && id_check) begin
      if (id_count1 != id_count) //(id_count + 1))
         id_miss <= 1'b1;
    end     
    else     
        id_miss <= 1'b0;
end

always_ff @(posedge iClk)
begin
  // Default
  //rAesLastFrame_other      <= 1'b0;
  rAesBlockSyncError_other <= 1'b0;
  
 // if (iAxis_TValid_other && iAxis_TID == pCHANNELS-1) begin
 //   if (rAudioFrameCount_other < 191) begin
 //     rAudioFrameCount_other <= rAudioFrameCount_other + 1;
 //   end
 //   else begin
 //     // Last frame of the AES block
 //     rAesLastFrame_other    <= 1'b1;
 //     rAudioFrameCount_other <= 0;
 //   end
 // end
  
  if (rAudioFrameCount == 1 && iAxis_TValid_other && pre_check_mode) begin
    // Check if we're in sync
    if (((nAesPreambleIn != cAES_PREAMB_SF2SYNC) && (iAxis_TID[0] == 1'b1)) ||  
        ((nAesPreambleIn != cAES_PREAMB_BSYNC) && (iAxis_TID[0] == 1'b0))) begin //2
      // Out of sync
      rAesBlockSyncError_other <= 1'b1;
    end
  end

  if (rAudioFrameCount != 1 && iAxis_TValid_other && pre_check_mode) begin
    // Check if we're in sync
    if (((nAesPreambleIn != cAES_PREAMB_SF2SYNC) && (iAxis_TID[0] == 1'b1)) ||  
        ((nAesPreambleIn != cAES_PREAMB_SF1SYNC) && (iAxis_TID[0] == 1'b0))) begin //2
      // Out of sync
      rAesBlockSyncError_other <= 1'b1;
    end
  end


  end

always_ff @(posedge iClk)
begin
  // Default
  rAesLastFrame      <= 1'b0;
  rAesBlockSyncError_int <= 1'b0;
  
  if (iAxis_TValid) begin
    if (rAudioFrameCount < 191) begin
      rAudioFrameCount <= rAudioFrameCount + 1;
    end
    else begin
      // Last frame of the AES block
      rAesLastFrame    <= 1'b1;
      rAudioFrameCount <= 0;
    end
  end
  
  case (stmAesDecode)
    sWaitForBlockStart : begin
      rAudioFrameCount <= 1;
      if (iAxis_TValid) begin
        if (nAesPreambleIn == cAES_PREAMB_BSYNC) begin
          stmAesDecode <= sRun;
          pre_check_mode <= 1'b1;
        end
      end
    end
    
    sRun : begin
      if (rAesBlockSyncError_other) begin
          stmAesDecode       <= sWaitForBlockStart;
          pre_check_mode     <= 1'b0;
      end
      else begin
      if (iAxis_TValid) begin
        if (nAesPreambleIn == cAES_PREAMB_BSYNC) begin
          // Check if we're in sync
          if (rAudioFrameCount != 0) begin
            // Out of sync
            rAesBlockSyncError_int <= 1'b1;
            rAudioFrameCount   <= 1;
          end
        end

        if (rAudioFrameCount == 0) begin
          // Check if we're in sync
          if (nAesPreambleIn != cAES_PREAMB_BSYNC) begin
            // Out of sync
            rAesBlockSyncError_int <= 1'b1;
            pre_check_mode     <= 1'b0;
            stmAesDecode       <= sWaitForBlockStart;
          end
        end
      end
      end
    end
    
    default : begin
      stmAesDecode <= sWaitForBlockStart;
    end
  endcase
  
  if (iRst) begin
    rAudioFrameCount <= 0;
    pre_check_mode <= 1'b0;
    stmAesDecode     <= sWaitForBlockStart;
  end
end



always_ff @(posedge iClk)
begin
  if (iRst) begin
     rAesBlockSyncError <= 1'b0;
  end
  else begin
     rAesBlockSyncError <= rAesBlockSyncError_int | rAesBlockSyncError_other | id_miss;
  end
end

assign oAesBlockComplete       = rAesBlockComplete;
assign oAesBlockSyncError      = rAesBlockSyncError;
assign oAesChannelStatusChange = rAesChannelStatusChange;

assign oAesChannelStatus       = rChannelStatusCapt;

endmodule


// (c) Copyright 2009-2018, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
////////////////////////////////////////////////////////////
//

`timescale 1 ns / 1 ps

module i2s_transmitter_v1_0_10_async_fifo
#(
 parameter integer C_AXIS_DATA_WIDTH = 32,
 parameter integer C_AXIS_ID_WIDTH = 3,
 parameter integer C_AXIS_DATA_COUNT_WIDTH = 8,
 parameter integer C_FIFO_DEPTH = 128,
 parameter integer PART = 1
)
(
input s_aclk,
input s_areset,
input s_validity,

input  s_axis_tvalid,
output s_axis_tready,
input [C_AXIS_DATA_WIDTH - 1 : 0] s_axis_tdata,
input [C_AXIS_ID_WIDTH - 1 : 0] s_axis_tid,

output [C_AXIS_DATA_COUNT_WIDTH - 1:0] axis_wr_data_count,

input m_aclk,

output m_axis_tvalid,
input  m_axis_tready,
output [C_AXIS_DATA_WIDTH - 1:0] m_axis_tdata,
output [C_AXIS_ID_WIDTH - 1:0] m_axis_tid,

output [C_AXIS_DATA_COUNT_WIDTH - 1:0] axis_rd_data_count
);

localparam C_DATA_WIDTH = C_AXIS_DATA_WIDTH + C_AXIS_ID_WIDTH;
localparam cAES_VLD_BIT    = 28;

wire [C_DATA_WIDTH - 1:0] din;
wire [C_DATA_WIDTH - 1:0] dout;
wire [C_AXIS_DATA_WIDTH - 1:0] s_axis_tdata_int;
wire wr_en;
wire rd_en;
wire full;
wire empty;
wire data_valid;
wire validity;

assign validity = (!s_axis_tdata[cAES_VLD_BIT]) | s_validity;

assign s_axis_tdata_int [27:4] = validity ? s_axis_tdata[27:4] : 24'b0;  
assign s_axis_tdata_int [3:0] = s_axis_tdata [3:0];
assign s_axis_tdata_int [31:28] = s_axis_tdata [31:28];

assign din = {s_axis_tdata_int, s_axis_tid};
assign m_axis_tdata = dout[C_DATA_WIDTH-1 : C_AXIS_ID_WIDTH];
assign m_axis_tid   = dout[C_AXIS_ID_WIDTH-1 : 0];

reg [9:0] count;
reg pulse;


// below counter is to hold write fifo for 1024 clocks 
// so that 512 serail bits reads gets completed before next write

always @(posedge s_aclk) begin
if (s_areset) begin
 count <= 0;
 pulse <= 0;
end else if (count == 1023) begin
        count <= 0;
        pulse <= 1; // Generate a pulse when count resets to 0
    end else if (count <= 8) begin
        count <= count + 1;
        pulse <= 1; // Keep pulse high while count is less than or equal to 7
    end else begin
        count <= count + 1;
        pulse <= 0; // Pulse goes low when count exceeds 7
    end
end

assign s_axis_tready = (PART == 1)? !full && pulse : !full;
//assign s_axis_tready = !full;
assign wr_en = s_axis_tvalid && s_axis_tready;

assign m_axis_tvalid = data_valid;
//assign m_axis_tvalid = !empty;
assign rd_en = m_axis_tvalid && m_axis_tready;


xpm_fifo_async # (

   .FIFO_MEMORY_TYPE        ("block"),
   .ECC_MODE                ("no_ecc"),              
   .RELATED_CLOCKS          (0),                     
   .FIFO_WRITE_DEPTH        (C_FIFO_DEPTH),          
   .WRITE_DATA_WIDTH        (C_DATA_WIDTH),          
   .WR_DATA_COUNT_WIDTH     (C_AXIS_DATA_COUNT_WIDTH),      
   .PROG_FULL_THRESH        (10),                    
   .FULL_RESET_VALUE        (1),                     
   .READ_MODE               ("fwft"),             
   .FIFO_READ_LATENCY       (0),            
   .READ_DATA_WIDTH         (C_DATA_WIDTH),          
   .RD_DATA_COUNT_WIDTH     (C_AXIS_DATA_COUNT_WIDTH),      
   .PROG_EMPTY_THRESH       (10),                    
   .USE_ADV_FEATURES        ("1F1F"),
   .DOUT_RESET_VALUE        ("0"),                   
   .CDC_SYNC_STAGES         (2),  
   .WAKEUP_TIME             (0)                      


) xpm_fifo_async_inst (

  .rst              (s_areset),
  .wr_clk           (s_aclk),
  .wr_en            (wr_en), //when ready & not full
  .din              (din),
  .full             (full),

  .overflow         (),
  .prog_full        (),
  .wr_data_count    (axis_wr_data_count),
  .almost_full      (),
  .wr_ack           (),
  .wr_rst_busy      (),

  .rd_clk           (m_aclk),
  .rd_en            (rd_en),
  .dout             (dout),
  .empty            (empty),

  .underflow        (),
  .rd_rst_busy      (),
  .prog_empty       (),
  .rd_data_count    (axis_rd_data_count),
  .almost_empty     (),
  .data_valid       (data_valid),
  .sleep            (1'b0),
  .injectsbiterr    (1'b0),
  .injectdbiterr    (1'b0),
  .sbiterr          (),
  .dbiterr          ()

);


endmodule 


// (c) Copyright 2009-2018, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
////////////////////////////////////////////////////////////

 
`timescale 1 ns / 1 ps
 
module i2s_transmitter_v1_0_10_sys
#(
  parameter pIS_I2S_MASTER = 1,
  parameter pNUM_I2S_CHANNELS = 4,
  parameter pI2S_DWIDTH = 24,
  parameter pFIFO_DEPTH = 128,
  parameter p32BIT_LR = 0,
  parameter integer PART = 1
)
(
  // Clocks and Resets
  input         iAxiClk,    // AXI Lite Clock
  input         iAxiResetn, // AXI Lite Resetn
  
  input         iMClk,      // Audio Master Clock
  input         iMRst,      // Audio Master Reset
  
  input         iAxisClk,   // AXI Stream Clock
  input         iAxisResetn,// AXI Stream Resetn
  
  // AXI4-Lite bus (cpu control)
  // - Write address
  input         iAxi_AWValid,
  output        oAxi_AWReady,
  input  [7:0] iAxi_AWAddr,
  // - Write data
  input         iAxi_WValid,
  output        oAxi_WReady,
  input  [31:0] iAxi_WData,
  // - Write response
  output        oAxi_BValid,
  input         iAxi_BReady,
  output [ 1:0] oAxi_BResp,
  // - Read address   
  input         iAxi_ARValid,
  output        oAxi_ARReady,
  input  [7:0] iAxi_ARAddr,
  // - Read data/response
  output        oAxi_RValid,
  input         iAxi_RReady, 
  output [31:0] oAxi_RData,
  output [ 1:0] oAxi_RResp,
  
  // IRQ
  output        oIRQ,
  
  // I2S Master Timing Out
  output        oLRClk,
  output        oSClk,
  
  // I2S Slave Timing In
  input         iLRClk,
  input         iSClk,
  
  // I2S Data Out
  output        oSData_0,
  output        oSData_1,
  output        oSData_2,
  output        oSData_3,
  
  // AXIS Audio In
  input  [31:0] iAxis_TData,
  input  [ 2:0] iAxis_TID,
  input         iAxis_TValid,
  output        oAxis_TReady,
  
  // AXIS FIFO Status
  output [15:0] oFifoWDataCount,
  output [15:0] oFifoRDataCount
);

genvar i;

function integer clogb2;
    input [31:0] value;
    begin
        value = value - 1;
        for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1) begin
            value = value >> 1;
        end
    end
endfunction

localparam pCORE_VERSION = 32'h00010000;
localparam pFIFO_READ_THRESHOLD = pFIFO_DEPTH/2;
localparam COUNT_WIDTH = clogb2(pFIFO_DEPTH)+1;

localparam I2SWIDTH_TIME = (PART == 1)? 256 : pI2S_DWIDTH;
localparam I2SWIDTH_AUD = (PART == 1)? 32 : pI2S_DWIDTH;

logic [ 31:0] aclk_nCoreConfig;
logic         aclk_nEnable;
logic         aclk_nJustify;
logic         aclk_nNormal_extd;
logic         aclk_nLeft_Right;
logic         axis_nEnable;
logic         aclk_nValidity;
logic         axis_nValidity;
logic [7:0]   aclk_nSclkDiv;

logic [2:0]   aclk_nChMuxSelect[4];

logic         aclk_nAudioUnderflow;
logic         aclk_nAesBlockComplete;
logic         aclk_nAesBlockSyncError;
logic         aclk_nAesChannelStatusChanged;
logic         aclk_nClearAesChannelStatus;
logic [191:0] aclk_nAesChannelStatus;

logic         axis_nAxis_TValid_ToAesDec;
logic         axis_nAxis_TValid_ToAesDec_other;
logic         axis_nAxis_TValid_ToFIFO;
logic         axis_nAxis_TReady_FromFIFO;
logic         axis_rAxis_InhibFIFOWrite;
logic         axis_rAxis_FIFOReset;
logic         axis_rAxis_Ready;
logic         axis_nMClkInReset;
logic [COUNT_WIDTH-1:0]   axis_nFIFOWriteDataCount;
logic [15:0]  axis_nFIFOWriteDataCountOut;

logic         axis_nAesBlockComplete;
logic         axis_nAesBlockSyncError;
logic         axis_nAesChannelStatusChanged;
logic         axis_nClearAesChannelStatus;
logic [191:0] axis_nAesChannelStatus;

logic         mclk_nLRClkFromTimGen;
logic         mclk_nSClkFromTimGen;

logic         mclk_nLRClk;
logic         mclk_nSClk;
logic [ 3:0]  mclk_nSDO;


logic [1:0]   mclk_rEnableSync;
logic         mclk_nEnable;
logic         mclk_nJustify;
logic         mclk_nNormal_extd;
logic         mclk_nLeft_Right;
logic [7:0]   mclk_nSclkDiv;
logic [23:0]  mclk_rSampleDelta;
logic [23:0]  mclk_rMaxSampleThresh;
logic [2:0]   mclk_nChMuxSelect[pNUM_I2S_CHANNELS];
logic [3:0]   mclk_rChMuxSelect[(2*pNUM_I2S_CHANNELS)];

logic [31:0]  mclk_nAxis_TData;
logic [2:0]   mclk_nAxis_TID;
logic         mclk_nAxis_TValid;
logic         mclk_nAxis_TReady; 

logic [COUNT_WIDTH-1:0]                       mclk_nFIFOReadDataCount;
logic [15:0]                      mclk_nFIFOReadDataCountOut;
logic                             mclk_rAudioUnderflow;
logic                             mclk_rReadFromFIFO;
logic                             mclk_rReadFIFOInitDone;
logic                             mclk_rReadCh0;
logic                             mclk_rAudioUnderflowInhib;
logic [pI2S_DWIDTH-1:0]           mclk_rWaveGenCounter;

logic [(2*pNUM_I2S_CHANNELS)-1:0] mclk_rAudValid;
logic [pNUM_I2S_CHANNELS-1:0]     mclk_nAudValid;
logic [pNUM_I2S_CHANNELS-1:0]     mclk_nAudCapt;
logic [I2SWIDTH_AUD-1:0]           mclk_rAudData [(2*pNUM_I2S_CHANNELS)];
logic [(2*I2SWIDTH_AUD)-1:0]       mclk_nAudData [pNUM_I2S_CHANNELS];


always_comb
begin
  aclk_nCoreConfig = 'h0;
  
  aclk_nCoreConfig[0]    = pIS_I2S_MASTER;
  aclk_nCoreConfig[11:8] = 2*pNUM_I2S_CHANNELS;
  aclk_nCoreConfig[16]   = (pI2S_DWIDTH == 24) ? 1'b1 : 1'b0;
end

i2s_transmitter_v1_0_10_axi
#(
  .pVERSION_NR(pCORE_VERSION),
  .p32BIT_LR(p32BIT_LR)
)
I2S_TX_V1_0_AXI_INST
(
  // AXI4-Lite bus (cpu control)
  .iAxiClk                  (iAxiClk),
  .iAxiResetn               (iAxiResetn),
  // - Write address
  .iAxi_AWValid             (iAxi_AWValid),
  .oAxi_AWReady             (oAxi_AWReady),
  .iAxi_AWAddr              (iAxi_AWAddr[7:0]),
  // - Write data
  .iAxi_WValid              (iAxi_WValid),
  .oAxi_WReady              (oAxi_WReady),
  .iAxi_WData               (iAxi_WData),
  // - Write response
  .oAxi_BValid              (oAxi_BValid),
  .iAxi_BReady              (iAxi_BReady),
  .oAxi_BResp               (oAxi_BResp),
  // - Read address   
  .iAxi_ARValid             (iAxi_ARValid),
  .oAxi_ARReady             (oAxi_ARReady),
  .iAxi_ARAddr              (iAxi_ARAddr[7:0]),
  // - Read data/response
  .oAxi_RValid              (oAxi_RValid),
  .iAxi_RReady              (iAxi_RReady), 
  .oAxi_RData               (oAxi_RData),
  .oAxi_RResp               (oAxi_RResp),
  // In/Out signals
  .oIRQ                     (oIRQ),
  
  .iCoreConfig              (aclk_nCoreConfig),
  .oEnable                  (aclk_nEnable),
  .oJustify                 (aclk_nJustify),
  .oNormal_extd             (aclk_nNormal_extd),
  .oLeft_Right              (aclk_nLeft_Right),  
  .oValidity                (aclk_nValidity),
  .oSclkDiv                 (aclk_nSclkDiv),
  
  .oChMuxSelect_01          (aclk_nChMuxSelect[0]),
  .oChMuxSelect_23          (aclk_nChMuxSelect[1]),
  .oChMuxSelect_45          (aclk_nChMuxSelect[2]),
  .oChMuxSelect_67          (aclk_nChMuxSelect[3]),
  
  .iAudioUnderflow          (aclk_nAudioUnderflow),
  .iAesBlockComplete        (aclk_nAesBlockComplete),
  .iAesBlockSyncError       (aclk_nAesBlockSyncError),
  .iAesChannelStatusChanged (aclk_nAesChannelStatusChanged),
  .oClearAesChannelStatus   (aclk_nClearAesChannelStatus),
  .iAesChannelStatus        (aclk_nAesChannelStatus)
);


generate
  for (i=0; i<pNUM_I2S_CHANNELS; i++) begin
    // Not necessarily the correct CDC to use, but it's the simplest one.
    // Signals are used as data output selection to the I2S.
    // In specific scenarios when the bits are changing it could 
    // trigger an underflow or a glitch on the data output
    // Normally the signals remain static during operation.
    xpm_cdc_array_single #(
      .DEST_SYNC_FF   (2),
      .SIM_ASSERT_CHK (0),
      .SRC_INPUT_REG  (1),
      .WIDTH          ($size(aclk_nChMuxSelect[i]))
    )
    CDC_CHMUX_INST (
      .src_clk   (iAxiClk),
      .src_in    (aclk_nChMuxSelect[i]),
      
      .dest_clk  (iMClk),
      .dest_out  (mclk_nChMuxSelect[i])
    );
  end
endgenerate

// Not necessarily the correct CDC to use, but it's the simplest one
// Signals are settings which are set initially when the module is disabled
// and remain static during operation.
xpm_cdc_array_single #(
  .DEST_SYNC_FF   (2),
  .SIM_ASSERT_CHK (0),
  .SRC_INPUT_REG  (1),
  .WIDTH          ($size(aclk_nSclkDiv))
)
CDC_SCLKDIV_INST (
  .src_clk   (iAxiClk),
  .src_in    (aclk_nSclkDiv),
  
  .dest_clk  (iMClk),
  .dest_out  (mclk_nSclkDiv)
);

xpm_cdc_single #(
  .DEST_SYNC_FF   (2),
  .SIM_ASSERT_CHK (0),
  .SRC_INPUT_REG  (1)
)
CDC_ENABLE_MCLK_INST (
  .src_clk   (iAxiClk),
  .src_in    (aclk_nEnable),
  
  .dest_clk  (iMClk),
  .dest_out  (mclk_nEnable)
);

xpm_cdc_single #(
  .DEST_SYNC_FF   (2),
  .SIM_ASSERT_CHK (0),
  .SRC_INPUT_REG  (1)
)
CDC_JUSTIFY_MCLK_INST (
  .src_clk   (iAxiClk),
  .src_in    (aclk_nJustify),
  
  .dest_clk  (iMClk),
  .dest_out  (mclk_nJustify)
);

xpm_cdc_single #(
  .DEST_SYNC_FF   (2),
  .SIM_ASSERT_CHK (0),
  .SRC_INPUT_REG  (1)
)
CDC_NORMAL_EXTD_MCLK_INST (
  .src_clk   (iAxiClk),
  .src_in    (aclk_nNormal_extd),
  
  .dest_clk  (iMClk),
  .dest_out  (mclk_nNormal_extd)
);

xpm_cdc_single #(
  .DEST_SYNC_FF   (2),
  .SIM_ASSERT_CHK (0),
  .SRC_INPUT_REG  (1)
)
CDC_LR_MCLK_INST (
  .src_clk   (iAxiClk),
  .src_in    (aclk_nLeft_Right),
  
  .dest_clk  (iMClk),
  .dest_out  (mclk_nLeft_Right)
);
xpm_cdc_single #(
  .DEST_SYNC_FF   (2),
  .SIM_ASSERT_CHK (0),
  .SRC_INPUT_REG  (1)
)
CDC_ENABLE_AXIS_INST (
  .src_clk   (iAxiClk),
  .src_in    (aclk_nEnable),
  
  .dest_clk  (iAxisClk),
  .dest_out  (axis_nEnable)
);

xpm_cdc_single #(
  .DEST_SYNC_FF   (2),
  .SIM_ASSERT_CHK (0),
  .SRC_INPUT_REG  (1)
)
CDC_VALIDITY_AXISCLK_INST (
  .src_clk   (iAxiClk),
  .src_in    (aclk_nValidity),
  
  .dest_clk  (iAxisClk),
  .dest_out  (axis_nValidity)
);

// Not necessarily the correct CDC to use, but it's the simplest one.
// ChannelStatus is clocked in when aclk_nAesChannelStatusChanged is asserted (in I2sTransmitter_axi).
// aclk_nAesChannelStatusChanged pulse generation has more register stages with respect to the channelstatus (4 instead of 2)
// so it is guaranteed that the channelstatus bits are captured correctly in the AXI lite Clock domain.
xpm_cdc_array_single #(
  .DEST_SYNC_FF   (2),
  .SIM_ASSERT_CHK (0),
  .SRC_INPUT_REG  (1),
  .WIDTH          ($size(axis_nAesChannelStatus))
)
CDC_AESCHSTS_INST (
  .src_clk   (iAxisClk),
  .src_in    (axis_nAesChannelStatus),
  
  .dest_clk  (iAxiClk),
  .dest_out  (aclk_nAesChannelStatus)
);


xpm_cdc_pulse #(
  .DEST_SYNC_FF   (4),
  .REG_OUTPUT     (1),
  .RST_USED       (1),
  .SIM_ASSERT_CHK (0)
)
CDC_AESCHSTSUPD_INST (
  .src_clk    (iAxisClk),
  .src_rst    (~iAxisResetn),
  .src_pulse  (axis_nAesChannelStatusChanged),
  
  .dest_clk   (iAxiClk),
  .dest_rst   (~iAxiResetn),
  .dest_pulse (aclk_nAesChannelStatusChanged)
);

xpm_cdc_pulse #(
  .DEST_SYNC_FF   (2),
  .REG_OUTPUT     (1),
  .RST_USED       (1),
  .SIM_ASSERT_CHK (0)
)
CDC_AESBLKCMPLT_INST (
  .src_clk    (iAxisClk),
  .src_rst    (~iAxisResetn),
  .src_pulse  (axis_nAesBlockComplete),
  
  .dest_clk   (iAxiClk),
  .dest_rst   (~iAxiResetn),
  .dest_pulse (aclk_nAesBlockComplete)
);

xpm_cdc_pulse #(
  .DEST_SYNC_FF   (2),
  .REG_OUTPUT     (1),
  .RST_USED       (1),
  .SIM_ASSERT_CHK (0)
)
CDC_AESBSYNCERR_INST (
  .src_clk    (iAxisClk),
  .src_rst    (~iAxisResetn),
  .src_pulse  (axis_nAesBlockSyncError),
  
  .dest_clk   (iAxiClk),
  .dest_rst   (~iAxiResetn),
  .dest_pulse (aclk_nAesBlockSyncError)
);

xpm_cdc_pulse #(
  .DEST_SYNC_FF   (2),
  .REG_OUTPUT     (1),
  .RST_USED       (1),
  .SIM_ASSERT_CHK (0)
)
CDC_AESCLRCHSTS_INST (
  .src_clk    (iAxiClk),
  .src_rst    (~iAxiResetn),
  .src_pulse  (aclk_nClearAesChannelStatus),
  
  .dest_clk   (iAxisClk),
  .dest_rst   (~iAxisResetn),
  .dest_pulse (axis_nClearAesChannelStatus)
);

xpm_cdc_pulse #(
  .DEST_SYNC_FF   (2),
  .REG_OUTPUT     (1),
  .RST_USED       (1),
  .SIM_ASSERT_CHK (0)
)
CDC_AUDUFLOW_INST (
  .src_clk    (iMClk),
  .src_rst    (iMRst),
  .src_pulse  (mclk_rAudioUnderflow),
  
  .dest_clk   (iAxiClk),
  .dest_rst   (~iAxiResetn),
  .dest_pulse (aclk_nAudioUnderflow)
);


xpm_cdc_async_rst #(
  .DEST_SYNC_FF    (2),
  .RST_ACTIVE_HIGH (1)
)
CDC_MRST_INST (
  .src_arst  (iMRst),
  
  .dest_clk  (iAxisClk),
  .dest_arst (axis_nMClkInReset)
);


always_comb
begin
  case (iAxis_TID)
    3'h0 : // Audio Channel 0
      begin
      axis_nAxis_TValid_ToAesDec = iAxis_TValid & oAxis_TReady;
      axis_nAxis_TValid_ToAesDec_other = 1'b0;
      end
    default:
    begin
      axis_nAxis_TValid_ToAesDec = 1'b0;
      axis_nAxis_TValid_ToAesDec_other = iAxis_TValid & oAxis_TReady;
      end
  endcase
end

//always_comb
//begin
//  case (iAxis_TID)
//    3'h0 : // Audio Channel 0
//      axis_nAxis_TValid_ToAesDec = iAxis_TValid & oAxis_TReady;
//    
//    default:
//      axis_nAxis_TValid_ToAesDec = 1'b0;
//  endcase
//end

i2s_transmitter_v1_0_10_aes_dec
#(
 .pCHANNELS (2*pNUM_I2S_CHANNELS),
 .PART (PART)

)
I2S_TX_V1_0_AES_DECODE_INST
(
  .iClk                    (iAxisClk),
  .iRst                    (~iAxisResetn || ~axis_nEnable),
  
  // AXI-Stream Audio In
  .iAxis_TData             (iAxis_TData),
  .iAxis_TValid            (axis_nAxis_TValid_ToAesDec),
  .iAxis_TValid_other      (axis_nAxis_TValid_ToAesDec_other),
  .iAxis_TID               (iAxis_TID),
  
  // Control In
  .iClearChannelStatus     (axis_nClearAesChannelStatus),
  
  // AES Status Out
  .oAesBlockComplete       (axis_nAesBlockComplete),
  .oAesBlockSyncError      (axis_nAesBlockSyncError),
  .oAesChannelStatusChange (axis_nAesChannelStatusChanged),
  .oAesChannelStatus       (axis_nAesChannelStatus)
);

always_ff @(posedge iAxisClk)
begin
    axis_rAxis_Ready          <= 1'b1;
    axis_rAxis_InhibFIFOWrite <= 1'b0;
    axis_rAxis_FIFOReset      <= 1'b0;
  
  if (!iAxisResetn || axis_nMClkInReset) begin
    axis_rAxis_InhibFIFOWrite <= 1'b1;
    axis_rAxis_FIFOReset      <= 1'b1;
    
    if (!iAxisResetn) begin
      axis_rAxis_Ready        <= 1'b0; 
    end
  end
end

assign axis_nAxis_TValid_ToFIFO = (axis_rAxis_InhibFIFOWrite) ? 1'b0 : iAxis_TValid;
assign oAxis_TReady             = (axis_rAxis_InhibFIFOWrite) ? axis_rAxis_Ready : axis_nAxis_TReady_FromFIFO;

assign oFifoWDataCount = axis_nFIFOWriteDataCountOut;
assign oFifoRDataCount = mclk_nFIFOReadDataCountOut;
always_comb
begin
  axis_nFIFOWriteDataCountOut = 'h0;
  axis_nFIFOWriteDataCountOut = axis_nFIFOWriteDataCount;
  
  mclk_nFIFOReadDataCountOut  = 'h0;
  mclk_nFIFOReadDataCountOut  = mclk_nFIFOReadDataCount;
end
//----------- Replacing with XPM ASYNC_FIFO-----------------
//i2stransmitter_axis_fifo_gen
//#(
//
//)
//AXIS_FIFO_INST
//(
//  // Write side
//  .s_aclk             (iAxisClk),
//  .s_aresetn          (~axis_rAxis_FIFOReset),
//  
//  .s_axis_tvalid      (axis_nAxis_TValid_ToFIFO),
//  .s_axis_tready      (axis_nAxis_TReady_FromFIFO),
//  .s_axis_tdata       (iAxis_TData),
//  .s_axis_tid         (iAxis_TID),
//  
//  .axis_wr_data_count (axis_nFIFOWriteDataCount),
//  
//  // Read side
//  .m_aclk             (iMClk),
//  
//  .m_axis_tvalid      (mclk_nAxis_TValid),
//  .m_axis_tready      (mclk_nAxis_TReady),
//  .m_axis_tdata       (mclk_nAxis_TData),
//  .m_axis_tid         (mclk_nAxis_TID),
//  
//  .axis_rd_data_count (mclk_nFIFOReadDataCount)
//);
//---------------------------------------------------------

i2s_transmitter_v1_0_10_async_fifo
#(
 .C_AXIS_DATA_WIDTH(32),
 .C_AXIS_ID_WIDTH(3),
 .C_AXIS_DATA_COUNT_WIDTH(COUNT_WIDTH),
 .C_FIFO_DEPTH(pFIFO_DEPTH),
 .PART(PART)
) AXIS_FIFO_INST
(
  // Write side
  .s_aclk             (iAxisClk),
  .s_areset           (axis_rAxis_FIFOReset || ~axis_nEnable),
  .s_validity         (axis_nValidity),
  
  .s_axis_tvalid      (axis_nAxis_TValid_ToFIFO),
  .s_axis_tready      (axis_nAxis_TReady_FromFIFO),
  .s_axis_tdata       (iAxis_TData),
  .s_axis_tid         (iAxis_TID),
  
  .axis_wr_data_count (axis_nFIFOWriteDataCount),
  
  // Read side
  .m_aclk             (iMClk),
  
  .m_axis_tvalid      (mclk_nAxis_TValid),
  .m_axis_tready      (mclk_nAxis_TReady),
  .m_axis_tdata       (mclk_nAxis_TData),
  .m_axis_tid         (mclk_nAxis_TID),
  
  .axis_rd_data_count (mclk_nFIFOReadDataCount)
);

typedef enum {
  sIdle,
  sWaitForFIFOLoad,
  sSyncFIFO,
  sWaitForI2sShiftReg
} tStmAudChCtrl; 
tStmAudChCtrl stmAudChCtrl;


assign mclk_nAxis_TReady = mclk_rReadFromFIFO;

always_ff @(posedge iMClk)
begin
  foreach (mclk_nChMuxSelect[i]) begin
    case (mclk_nChMuxSelect[i])
      3'b000 : begin // Disabled
        mclk_rChMuxSelect[2*i]     <= 4'b0000; // Disabled
        mclk_rChMuxSelect[(2*i)+1] <= 4'b0000; // Disabled
      end
      
      3'b001 : begin // AXIS Channel 0/1
        mclk_rChMuxSelect[2*i]     <= 4'b1000; // AXIS Channel 0
        mclk_rChMuxSelect[(2*i)+1] <= 4'b1001; // AXIS Channel 1
      end
      
      3'b010 : begin // AXIS Channel 2/3
        mclk_rChMuxSelect[2*i]     <= 4'b1010; // AXIS Channel 2
        mclk_rChMuxSelect[(2*i)+1] <= 4'b1011; // AXIS Channel 3
      end
      
      3'b011 : begin // AXIS Channel 4/5
        mclk_rChMuxSelect[2*i]     <= 4'b1100; // AXIS Channel 4
        mclk_rChMuxSelect[(2*i)+1] <= 4'b1101; // AXIS Channel 5
      end
      
      3'b100 : begin // AXIS Channel 6/7
        mclk_rChMuxSelect[2*i]     <= 4'b1110; // AXIS Channel 6
        mclk_rChMuxSelect[(2*i)+1] <= 4'b1111; // AXIS Channel 7
      end
      
      3'b101 : begin // WaveForm Generator
        mclk_rChMuxSelect[2*i]     <= 4'b0001; // Waveform Generator
        mclk_rChMuxSelect[(2*i)+1] <= 4'b0001; // Waveform Generator
      end
      
      default : begin // Unknown
        mclk_rChMuxSelect[2*i]     <= 4'b0000; // Disabled
        mclk_rChMuxSelect[(2*i)+1] <= 4'b0000; // Disabled
      end
    endcase
  end
    
  // Default
  mclk_rAudioUnderflow         <= 1'b0;
      
  if (mclk_nAudCapt[0]) begin
    if (mclk_rReadFIFOInitDone && !mclk_rAudioUnderflowInhib) begin
      if (!(&mclk_rAudValid)) begin
        // Underflow
        mclk_rAudioUnderflow   <= 1'b1;
      end
    end
    
    // Waveform Generator
    mclk_rWaveGenCounter <= mclk_rWaveGenCounter + 1;
  end
  
  case (stmAudChCtrl)
    sIdle : begin
      mclk_rReadFromFIFO        <= 1'b0;
      mclk_rReadFIFOInitDone    <= 1'b0;
      mclk_rReadCh0             <= 1'b0;
      mclk_rAudioUnderflowInhib <= 1'b1;
      stmAudChCtrl              <= sWaitForFIFOLoad;
    end
    
    sWaitForFIFOLoad : begin
      if (mclk_nFIFOReadDataCountOut >= pFIFO_READ_THRESHOLD) begin
        stmAudChCtrl            <= sSyncFIFO;
      end
    end
    
    sSyncFIFO : begin
      if (!mclk_rReadFromFIFO) begin
        if (mclk_nAxis_TValid) begin
          if (mclk_nAxis_TID != 3'h0) begin
            mclk_rReadFromFIFO   <= 1'b1;
          end
          else begin
            mclk_rReadFIFOInitDone <= 1'b1;
            
            // Issue read for Audio Channel 0?
            if (mclk_rReadCh0) begin 
              mclk_rReadFromFIFO <= 1'b1;
              mclk_rReadCh0      <= 1'b0; // Clear flag
            end
            else begin 
              // Stop at Audio Channel 0
              stmAudChCtrl  <= sWaitForI2sShiftReg;
            end
          end
        end //mclk_nAxis_TValid
      end //!mclk_rReadFromFIFO
      else begin
        mclk_rReadFromFIFO    <= 1'b0;
      end
    end
    
    sWaitForI2sShiftReg : begin
      // Synchronize with the I2S Shift Register
      if (mclk_nAudCapt[0]) begin
        mclk_rAudioUnderflowInhib <= 1'b0;
        if (mclk_nAxis_TValid) begin
          mclk_rReadFromFIFO  <= 1'b1;
        end
        else begin
          mclk_rReadCh0       <= 1'b1;
        end
        stmAudChCtrl          <= sSyncFIFO;
      end
    end
    
    default : begin
      stmAudChCtrl            <= sIdle;
    end
  endcase
  
  if (iMRst || ~mclk_nEnable) begin
    mclk_rReadCh0             <= 1'b0;
    mclk_rReadFIFOInitDone    <= 1'b0;
    mclk_rAudioUnderflowInhib <= 1'b1;
    mclk_rReadFromFIFO        <= 1'b0;
    mclk_rWaveGenCounter      <= 'h0;
    stmAudChCtrl              <= sIdle;
  end
end

generate
  for (i=0; i<(2*pNUM_I2S_CHANNELS); i++) begin
    always_ff @(posedge iMClk)
    begin
      if (mclk_nAudCapt[0]) begin
        mclk_rAudValid[i]           <= 1'b0;
      end
      
      if (mclk_rReadFIFOInitDone) begin
        if (!mclk_rAudValid[i]) begin
          casez (mclk_rChMuxSelect[i])
            4'b0000 : begin // Disabled
              mclk_rAudData[i]      <= 'h0;
              mclk_rAudValid[i]     <= 1'b1;
            end
            
            4'b0001 : begin // Waveform Generator
              mclk_rAudData[i]      <= mclk_rWaveGenCounter;
              mclk_rAudValid[i]     <= 1'b1;
            end
            
            4'b1??? : begin // AXIS Channel
              if (mclk_nAxis_TValid && mclk_nAxis_TReady) begin
                if (mclk_nAxis_TID == mclk_rChMuxSelect[i][2:0]) begin
                  mclk_rAudData[i]  <= (PART == 1)? mclk_nAxis_TData[(I2SWIDTH_AUD-1):0] : mclk_nAxis_TData[27-:pI2S_DWIDTH];
                  mclk_rAudValid[i] <= 1'b1;
                end
              end
            end
            
            default : begin
              // Should not get here
              // Disabled
              mclk_rAudData[i]      <= 'h0;
              mclk_rAudValid[i]     <= 1'b1;
            end
          endcase
        end // mclk_rAudValid
      end // mclk_rReadFIFOInitDone
      
      if (iMRst || ~mclk_nEnable) begin
        mclk_rAudValid[i] <= 1'b0;
      end
    end
  end
endgenerate

// Combine the left and right channels for each I2S channel
generate
  for (i=0; i<(2*pNUM_I2S_CHANNELS); i++) begin
    if (i%2 == 0) begin
      assign mclk_nAudData[i/2]  = {mclk_rAudData[i+1], mclk_rAudData[i]};
      assign mclk_nAudValid[i/2] = mclk_rAudValid[i+1] & mclk_rAudValid[i];
    end
  end
endgenerate

// I2S Shift Registers
generate
  for (i=0; i<pNUM_I2S_CHANNELS; i++) begin 
    i2s_transmitter_v1_0_10_ser
    #(
      .pDWIDTH   (I2SWIDTH_AUD),
      .PART      (PART),
      .AUD_SAMPLE_SIZE(pI2S_DWIDTH)
    )
    I2S_TX_V1_0_SER_INST
    (
      .iMClk     (iMClk),
      .iMRst     ((iMRst | ~mclk_nEnable)),
      .iJustfied (mclk_nJustify),
      .iLeft_Right(mclk_nLeft_Right),

      .iLRClk    (mclk_nLRClk),
      .iSClk     (mclk_nSClk),
      .oSData    (mclk_nSDO[i]),
      
      .iAudValid (mclk_nAudValid[i]),
      .oAudReady (mclk_nAudCapt[i]),
      .iAudData  (mclk_nAudData[i])
     );
  end
endgenerate

// I2S Data Outputs
assign oSData_0 = mclk_nSDO[0];
generate
  if (pNUM_I2S_CHANNELS >= 2) begin
    assign oSData_1 = mclk_nSDO[1];
  end
  else begin
    assign oSData_1 = 1'b0;
  end
  
  if (pNUM_I2S_CHANNELS >= 3) begin
    assign oSData_2 = mclk_nSDO[2];
  end
  else begin
    assign oSData_2 = 1'b0;
  end
  
  if (pNUM_I2S_CHANNELS >= 4) begin
    assign oSData_3 = mclk_nSDO[3];
  end
  else begin
    assign oSData_3 = 1'b0;
  end
endgenerate

// I2S Timing Generation
generate
  if (pIS_I2S_MASTER == 1) begin
    assign mclk_nLRClk = mclk_nLRClkFromTimGen;
    assign mclk_nSClk  = mclk_nSClkFromTimGen;
    
    i2s_transmitter_v1_0_10_timgen
    #(
      .pDWIDTH  (I2SWIDTH_TIME),
      .PART (PART)
    )
    I2S_TX_V1_0_TIMGEN_INST
    (
      .iMClk    (iMClk),
      .iMRst    ((iMRst | ~mclk_nEnable)),
      
      .iSClkDiv (mclk_nSclkDiv),
      .iJustfied(mclk_nJustify),
      .iNormal_extd(mclk_nNormal_extd),
      
      .oLRClk   (mclk_nLRClkFromTimGen),
      .oSClk    (mclk_nSClkFromTimGen)
    );
    
  end
  else begin // I2S Slave
    assign mclk_nLRClk = iLRClk;
    assign mclk_nSClk  = iSClk;
  end
endgenerate

assign oLRClk = mclk_nLRClk;
assign oSClk  = mclk_nSClk;

endmodule


// (c) Copyright 2009-2018, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
////////////////////////////////////////////////////////////
//

`timescale 1 ns / 1 ps
 
module i2s_transmitter_v1_0_10
#(
  parameter C_IS_MASTER = 1,
  parameter C_NUM_CHANNELS = 4,
  parameter C_DWIDTH = 24,
  parameter C_DEPTH = 128,
  parameter C_32BIT_LR = 0,
  parameter integer PART = 1 
)
(
  // Clocks and Resets
  input         s_axi_ctrl_aclk,    // AXI Lite Clock
  input         s_axi_ctrl_aresetn, // AXI Lite Resetn
  
  input         aud_mclk,           // Audio Master Clock
  input         aud_mrst,           // Audio Master Reset
  
  input         s_axis_aud_aclk,    // AXI Stream Clock
  input         s_axis_aud_aresetn, // AXI Stream Resetn
  
  // AXI4-Lite bus (cpu control)
  // - Write address
  input         s_axi_ctrl_awvalid,
  output        s_axi_ctrl_awready,
  input  [7:0] s_axi_ctrl_awaddr,
  // - Write data
  input         s_axi_ctrl_wvalid,
  output        s_axi_ctrl_wready,
  input  [31:0] s_axi_ctrl_wdata,
  // - Write response
  output        s_axi_ctrl_bvalid,
  input         s_axi_ctrl_bready,
  output [ 1:0] s_axi_ctrl_bresp,
  // - Read address   
  input         s_axi_ctrl_arvalid,
  output        s_axi_ctrl_arready,
  input  [7:0] s_axi_ctrl_araddr,
  // - Read data/response
  output        s_axi_ctrl_rvalid,
  input         s_axi_ctrl_rready, 
  output [31:0] s_axi_ctrl_rdata,
  output [ 1:0] s_axi_ctrl_rresp,
  
  // IRQ
  output        irq,
  
  // I2S Master Timing Out
  output        lrclk_out,
  output        sclk_out,
  
  // I2S Slave Timing In
  input         lrclk_in,
  input         sclk_in,
  
  // I2S Data Out
  output        sdata_0_out,
  output        sdata_1_out,
  output        sdata_2_out,
  output        sdata_3_out,
  
  // AXIS Audio In
  input  [31:0] s_axis_aud_tdata,
  input  [ 2:0] s_axis_aud_tid,
  input         s_axis_aud_tvalid,
  output        s_axis_aud_tready,
  
  // AXIS FIFO Status
  output [15:0] fifo_wrdata_count,
  output [15:0] fifo_rdata_count
);


wire sdata_0_out_w, sdata_1_out_w, sdata_2_out_w, sdata_3_out_w, lrclk_out_w;
reg sdata_0_out_r, sdata_1_out_r, sdata_2_out_r, sdata_3_out_r, lrclk_out_r;
reg sdata_0_out_r_neg, sdata_1_out_r_neg, sdata_2_out_r_neg, sdata_3_out_r_neg, lrclk_out_r_neg;



always @ (negedge sclk_out )
 begin
  if(aud_mrst) begin
   sdata_0_out_r_neg <= 0;
   sdata_1_out_r_neg <= 0;
   sdata_2_out_r_neg <= 0;
   sdata_3_out_r_neg <= 0;
   lrclk_out_r_neg   <= 0;
  end
  else begin
   sdata_0_out_r_neg <= sdata_0_out_w;
   sdata_1_out_r_neg <= sdata_1_out_w;
   sdata_2_out_r_neg <= sdata_2_out_w;
   sdata_3_out_r_neg <= sdata_3_out_w;
   lrclk_out_r_neg   <= lrclk_out_w;
  end
 end 


always @ (posedge sclk_out )
 begin
  if(aud_mrst) begin
   sdata_0_out_r <= 0;
   sdata_1_out_r <= 0;
   sdata_2_out_r <= 0;
   sdata_3_out_r <= 0;
   lrclk_out_r   <= 0;
  end
  else begin
   sdata_0_out_r <= sdata_0_out_r_neg;
   sdata_1_out_r <= sdata_1_out_r_neg;
   sdata_2_out_r <= sdata_2_out_r_neg;
   sdata_3_out_r <= sdata_3_out_r_neg;
   lrclk_out_r   <= lrclk_out_r_neg;
  end
 end 

assign sdata_0_out = sdata_0_out_r;
assign sdata_1_out = sdata_1_out_r;
assign sdata_2_out = sdata_2_out_r;
assign sdata_3_out = sdata_3_out_r;
assign lrclk_out = lrclk_out_r;



i2s_transmitter_v1_0_10_sys
#(
  .pIS_I2S_MASTER    (C_IS_MASTER),
  .pNUM_I2S_CHANNELS (C_NUM_CHANNELS),
  .pI2S_DWIDTH       (C_DWIDTH),
  .pFIFO_DEPTH       (C_DEPTH),
  .p32BIT_LR         (C_32BIT_LR),
  .PART              (PART) 
)
I2S_TX_V1_0_SYS_INST
(
  // Clock and Resets
  .iAxiClk         (s_axi_ctrl_aclk),    // AXI Lite Clock
  .iAxiResetn      (s_axi_ctrl_aresetn), // AXI Lite Resetn
  
  .iMClk           (aud_mclk), // Audio Master Clock
  .iMRst           (aud_mrst), // Audio Master Reset
  
  .iAxisClk        (s_axis_aud_aclk),    // AXI Stream Clock
  .iAxisResetn     (s_axis_aud_aresetn), // AXI Stream Resetn
  
  // AXI4-Lite bus (cpu control)
  .iAxi_AWValid    (s_axi_ctrl_awvalid),
  .oAxi_AWReady    (s_axi_ctrl_awready),
  .iAxi_AWAddr     (s_axi_ctrl_awaddr),
  
  .iAxi_WValid     (s_axi_ctrl_wvalid),
  .oAxi_WReady     (s_axi_ctrl_wready),
  .iAxi_WData      (s_axi_ctrl_wdata),
  
  .oAxi_BValid     (s_axi_ctrl_bvalid),
  .iAxi_BReady     (s_axi_ctrl_bready),
  .oAxi_BResp      (s_axi_ctrl_bresp),
  
  .iAxi_ARValid    (s_axi_ctrl_arvalid),
  .oAxi_ARReady    (s_axi_ctrl_arready),
  .iAxi_ARAddr     (s_axi_ctrl_araddr),
  
  .oAxi_RValid     (s_axi_ctrl_rvalid),
  .iAxi_RReady     (s_axi_ctrl_rready),
  .oAxi_RData      (s_axi_ctrl_rdata),
  .oAxi_RResp      (s_axi_ctrl_rresp),
  
  // Interrupt 
  .oIRQ            (irq),
  
  // I2S Master Timing Out
  .oLRClk          (lrclk_out_w),
  .oSClk           (sclk_out),
  
  // I2S Slave Timing In
  .iLRClk          (lrclk_in),
  .iSClk           (sclk_in),
  
  // I2S Data Out
  .oSData_0        (sdata_0_out_w),
  .oSData_1        (sdata_1_out_w),
  .oSData_2        (sdata_2_out_w),
  .oSData_3        (sdata_3_out_w),
  
  // AXIS Audio In
  .iAxis_TData     (s_axis_aud_tdata),
  .iAxis_TID       (s_axis_aud_tid),
  .iAxis_TValid    (s_axis_aud_tvalid),
  .oAxis_TReady    (s_axis_aud_tready),
  
  // AXIS FIFO Status
  .oFifoWDataCount (fifo_wrdata_count),
  .oFifoRDataCount (fifo_rdata_count)
);

endmodule


