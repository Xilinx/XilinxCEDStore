// (c) Copyright 2023 Advanced Micro Devices, Inc. All rights reserved.
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
/******************************************************************************

File name:
Rev:
Description:

-- (c) Copyright 1995 - 2023 AMD, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of AMD, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- AMD, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) AMD shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or AMD had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- AMD products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of AMD products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
*******************************************************************************/
`timescale 1 ps / 1 ps

(* DowngradeIPIdentifiedWarnings="yes" *)
module axi4svideo_bridge_v1_0_17_sync_cell
#(
    parameter   C_SYNC_STAGE        = 2,
    parameter   C_DW                = 4,
    parameter   pTCQ                = 100
)
(
  input  wire  [C_DW-1:0]                 src_data,

  input  wire                             dest_clk,
  output wire  [C_DW-1:0]                 dest_data
);

  xpm_cdc_array_single #(
    // Common module parameters
    .DEST_SYNC_FF   (C_SYNC_STAGE),
    .SIM_ASSERT_CHK (0), 
    .SRC_INPUT_REG  (0),
    .WIDTH          (C_DW)
  ) xpm_cdc_array_single_inst (
    .src_clk  (1'b0),  
    .src_in   (src_data),
    .dest_clk (dest_clk),
    .dest_out (dest_data)
  );

endmodule



// (c) Copyright 2015, 2023 Advanced Micro Devices, Inc. All rights reserved.
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
//--------------------------------------------------------------------------
//  Module Description:
//  This file contains various utility modules used within the bridge.
//
//  Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------

`timescale 1ps/1ps
`default_nettype none
(* DowngradeIPIdentifiedWarnings="yes" *)

module axi_remapper_tx_v1_0_fifo_async #(
  parameter C_ADDR_WIDTH = 10,
  parameter C_DATA_WIDTH = 8
) (
  // System Signals
  input  wire WR_CLK,               // Write clock            
  input  wire RD_CLK,               // Read clock             
  input  wire RESET,                // Reset synchronous to WR_CLK

  // FIFO write signals
  input  wire [C_DATA_WIDTH-1:0]
              WR_DATA,              // Write data
  input  wire WR_EN,                // Write enable                
  output wire [C_ADDR_WIDTH:0]
              WR_DATA_COUNT,        // Write count
  output wire WR_BUSY,              // Write reset busy
  output wire WR_FULL,              // Full      
  output wire WR_OVERFLOW,          // Overflow

  // FIFO read signals
  output wire [C_DATA_WIDTH-1:0]
              RD_DATA,              // Read data
  input  wire RD_EN,                // Read enable              
  output wire [C_ADDR_WIDTH:0] 
              RD_DATA_COUNT,        // Read count
  output wire RD_BUSY,              // Read reset busy
  output wire RD_EMPTY,             // Empty                   
  output wire RD_UNDERFLOW          // Underflow
);

// xpm_fifo_async: Asynchronous FIFO
// AMD Parameterized Macro, Version 2017.3
xpm_fifo_async # (
  .FIFO_MEMORY_TYPE          ("auto"),           //string; "auto", "block", or "distributed";
  .ECC_MODE                  ("no_ecc"),         //string; "no_ecc" or "en_ecc";
  .RELATED_CLOCKS            (0),                //positive integer; 0 or 1
  .FIFO_WRITE_DEPTH          (2**C_ADDR_WIDTH),  //positive integer
  .WRITE_DATA_WIDTH          (C_DATA_WIDTH),     //positive integer
  .WR_DATA_COUNT_WIDTH       (C_ADDR_WIDTH+1),   //positive integer
  .PROG_FULL_THRESH          (),                 //positive integer
  .FULL_RESET_VALUE          (1),                //positive integer; 0 or 1
  .READ_MODE                 ("fwft"),           //string; "std" or "fwft";
  .FIFO_READ_LATENCY         (0),                //positive integer;
  .READ_DATA_WIDTH           (C_DATA_WIDTH),     //positive integer
  .RD_DATA_COUNT_WIDTH       (C_ADDR_WIDTH+1),   //positive integer
  .PROG_EMPTY_THRESH         (),                 //positive integer
  .DOUT_RESET_VALUE          ("0"),              //string
  .CDC_SYNC_STAGES           (4),                //positive integer
  .WAKEUP_TIME               (0)                 //positive integer; 0 or 2;
) XPM_FIFO_ASYNC_INST (
  .rst              (RESET),
  .wr_clk           (WR_CLK),
  .wr_en            (WR_EN),
  .din              (WR_DATA),
  .full             (WR_FULL),
  .overflow         (WR_OVERFLOW),
  .wr_rst_busy      (WR_BUSY),
  .rd_clk           (RD_CLK),
  .rd_en            (RD_EN),
  .dout             (RD_DATA),
  .empty            (RD_EMPTY),
  .underflow        (RD_UNDERFLOW),
  .rd_rst_busy      (RD_BUSY),
  .prog_full        (),
  .wr_data_count    (WR_DATA_COUNT),
  .prog_empty       (),
  .rd_data_count    (RD_DATA_COUNT),
  .sleep            (1'b0),
  .injectsbiterr    (1'b0),
  .injectdbiterr    (1'b0),
  .sbiterr          (),
  .dbiterr          ()
);

endmodule

module axi_remapper_tx_v1_0_fifo_sync #(
  parameter C_ADDR_WIDTH = 10,
  parameter C_DATA_WIDTH = 8
) (
  // System Signals
  input  wire CLK,                  // Clock            
  input  wire RESET,                // Reset synchronous to CLK

  // FIFO write signals
  input  wire [C_DATA_WIDTH-1:0]
              WR_DATA,              // Write data
  input  wire WR_EN,                // Write enable                
  output wire [C_ADDR_WIDTH:0]
              WR_DATA_COUNT,        // Write count
  output wire WR_BUSY,              // Write reset busy
  output wire WR_FULL,              // Full      
  output wire WR_OVERFLOW,          // Overflow

  // FIFO read signals
  output wire [C_DATA_WIDTH-1:0]
              RD_DATA,              // Read data
  input  wire RD_EN,                // Read enable              
  output wire [C_ADDR_WIDTH:0] 
              RD_DATA_COUNT,        // Read count
  output wire RD_BUSY,              // Read reset busy
  output wire RD_EMPTY,             // Empty                   
  output wire RD_UNDERFLOW          // Underflow
);

// xpm_fifo_sync: Synchronous FIFO
// AMD Parameterized Macro, Version 2017.3
xpm_fifo_sync # (
  .FIFO_MEMORY_TYPE          ("auto"),           //string; "auto", "block", or "distributed";
  .ECC_MODE                  ("no_ecc"),         //string; "no_ecc" or "en_ecc";
  .FIFO_WRITE_DEPTH          (2**C_ADDR_WIDTH),  //positive integer
  .WRITE_DATA_WIDTH          (C_DATA_WIDTH),     //positive integer
  .WR_DATA_COUNT_WIDTH       (C_ADDR_WIDTH+1),   //positive integer
  .PROG_FULL_THRESH          (),                 //positive integer
  .FULL_RESET_VALUE          (1),                //positive integer; 0 or 1
  .READ_MODE                 ("fwft"),           //string; "std" or "fwft";
  .FIFO_READ_LATENCY         (0),                //positive integer;
  .READ_DATA_WIDTH           (C_DATA_WIDTH),     //positive integer
  .RD_DATA_COUNT_WIDTH       (C_ADDR_WIDTH+1),   //positive integer
  .PROG_EMPTY_THRESH         (),                 //positive integer
  .DOUT_RESET_VALUE          ("0"),              //string
  .WAKEUP_TIME               (0)                 //positive integer; 0 or 2;
) XPM_FIFO_SYNC_INST (
  .rst              (RESET),
  .wr_clk           (CLK),
  .wr_en            (WR_EN),
  .din              (WR_DATA),
  .full             (WR_FULL),
  .overflow         (WR_OVERFLOW),
  .wr_rst_busy      (WR_BUSY),
  .rd_en            (RD_EN),
  .dout             (RD_DATA),
  .empty            (RD_EMPTY),
  .underflow        (RD_UNDERFLOW),
  .rd_rst_busy      (RD_BUSY),
  .prog_full        (),
  .wr_data_count    (WR_DATA_COUNT),
  .prog_empty       (),
  .rd_data_count    (RD_DATA_COUNT),
  .sleep            (1'b0),
  .injectsbiterr    (1'b0),
  .injectdbiterr    (1'b0),
  .sbiterr          (),
  .dbiterr          ()
);

endmodule

module axi_remapper_tx_v1_0_cdc_single #(
  parameter C_SYNC_FF = 4
) (
  input  wire CLK_IN,
  input  wire DAT_IN,
  output wire DAT_OUT
);

xpm_cdc_single #(
  .DEST_SYNC_FF   (C_SYNC_FF),
  .SIM_ASSERT_CHK (0), 
  .SRC_INPUT_REG  (0) 
) xpm_cdc_single_inst (
  .src_clk  (1'b0),  
  .src_in   (DAT_IN),
  .dest_clk (CLK_IN),
  .dest_out (DAT_OUT)
);

endmodule

`default_nettype wire


// (c) Copyright 2016, 2023 Advanced Micro Devices, Inc. All rights reserved.
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
//--------------------------------------------------------------------------
//  Module Description:
//  This module remaps YUV 4:2:0 from 2 components at the input to 3
//  components at the output.
//
//  Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------

`timescale 1ps/1ps
`default_nettype none
(* DowngradeIPIdentifiedWarnings="yes" *)

module axi_remapper_tx_v1_0_remap #(
  parameter C_FAMILY                 = "virtex6",
  parameter C_PIXELS_PER_CLOCK       = 1,   // Pixels per clock [1,2,4, 8]
  parameter C_COMPONENTS_PER_PIXEL   = 3,   // Components per pixel [1,2,3,4]
  parameter C_S_AXIS_COMPONENT_WIDTH = 8,   // AXIS video component width [8,10,12,16]
  parameter C_S_AXIS_TDATA_WIDTH     = 24,  // AXIS video tdata width
  parameter C_ADDR_WIDTH             = 10   // FIFO address width 
) (
  input   wire ACLK,               
  input   wire ACLKEN,              
  input   wire ARESETN,              

  // Control
  input   wire REMAP_IN,

  // Slave Interface
  input   wire [C_S_AXIS_TDATA_WIDTH-1:0]
               TDATA_IN,
  input   wire TVALID_IN,       
  output  wire TREADY_OUT,      
  input   wire TUSER_IN,        
  input   wire TLAST_IN,        
  input   wire FID_IN,          

  // Master Interface
  output  wire [C_S_AXIS_TDATA_WIDTH-1:0]
               TDATA_OUT,
  output  wire TVALID_OUT,       
  input   wire TREADY_IN,      
  output  wire TUSER_OUT,        
  output  wire TLAST_OUT,        
  output  wire FID_OUT,
  output  reg  REMAP_TLAST_ADV,

  // Status
  output  wire FIFO_OVERFLOW_OUT,
  output  wire FIFO_UNDERFLOW_OUT
);

localparam C_BITS_PER_PIXEL = 2 * C_S_AXIS_COMPONENT_WIDTH;
localparam C_STATE_IDLE   = 0,
           C_STATE_ACTIVE = 1,
           C_STATE_EVEN   = 2,
           C_STATE_ODD    = 3,
           C_STATE_WAIT   = 4,
           C_STATE_ERROR  = 5;

// Internal signals
reg  [C_S_AXIS_TDATA_WIDTH-1:0]
     aclk_tdata_even, aclk_tdata_even_dly, aclk_tdata_odd;
reg  aclk_tuser, aclk_tuser_dly;
reg  aclk_tlast;
reg  aclk_tlast_dly;
reg  aclk_fid, aclk_fid_dly;

reg  aclk_line_phase;
wire aclk_xfer_si;
wire aclk_xfer_mi;

wire [C_PIXELS_PER_CLOCK*C_S_AXIS_COMPONENT_WIDTH:0]
     aclk_wr_data;
reg  aclk_wr_en;
wire [C_PIXELS_PER_CLOCK*C_S_AXIS_COMPONENT_WIDTH:0]
     aclk_rd_data;
wire aclk_rd_en;
wire aclk_remap;

reg  [2:0] aclk_state;
reg  [2:0] aclk_next;

wire reset;
reg  [3:0] reset_pulse;

wire underflow;
wire overflow;
// Assignments
assign aclk_xfer_si = TVALID_IN  & TREADY_OUT;
assign aclk_xfer_mi = TVALID_OUT & TREADY_IN;
assign aclk_rd_en   = (aclk_state > C_STATE_IDLE) & aclk_line_phase & aclk_xfer_mi;
assign reset        = (~ARESETN) || (|reset_pulse);

// Synchronize control input
axi_remapper_tx_v1_0_cdc_single
CDC_SINGLE_INST (
  .CLK_IN(ACLK),
  .DAT_IN(REMAP_IN),
  .DAT_OUT(aclk_remap)
);

// Reset pulse
always @(posedge ACLK) begin
  // Load 
  if ((aclk_state == C_STATE_ERROR) ||
      (aclk_line_phase && aclk_tuser))
    reset_pulse <= 4'b1111;

  // Shift 
  else
    reset_pulse <= {1'b0, reset_pulse[3:1]};
end

// State machine
always @(posedge ACLK) begin
  if (reset) begin
    aclk_state <= C_STATE_IDLE;
  end else if (ACLKEN) begin
    aclk_state <= aclk_next;
  end
end

always @(*) begin
  aclk_next = C_STATE_IDLE;

  case (aclk_state) 
    // Idle
    // State machine is idle
    // Activate state machine only after first start of frame sample on SI
    C_STATE_IDLE:
      if (aclk_xfer_si & aclk_remap & (TUSER_IN & ~FID_IN)) 
        if (TLAST_IN)
          aclk_next = C_STATE_ERROR; // Early or Late EOL
        else 
          aclk_next = C_STATE_EVEN;
      else
        aclk_next = C_STATE_IDLE;

    // Active
    // State machine waiting for even sample on SI
    // Pipeline is empty
    C_STATE_ACTIVE:
      if (aclk_xfer_si)
        if (TLAST_IN)
          aclk_next = C_STATE_ERROR; // Early or Late EOL
        else
          aclk_next = C_STATE_EVEN;
      else
        aclk_next = C_STATE_ACTIVE;

    // Even sample
    // State machine waiting for odd sample on SI
    // Pipeline is even only
    C_STATE_EVEN:
      if (aclk_xfer_si)
        if (TUSER_IN) 
          aclk_next = C_STATE_ERROR; // Early or Late SOF
        else
          aclk_next = C_STATE_ODD;
      else 
        aclk_next = C_STATE_EVEN;

    // Odd sample
    // State machine waiting to push sample on MI
    // Pipeline is even/odd pair
    C_STATE_ODD:
      // No stall or backpressure
      if(aclk_xfer_si & aclk_xfer_mi & TLAST_IN)
        aclk_next = C_STATE_ODD;
      else if (aclk_xfer_si & aclk_xfer_mi)
       // if (TLAST_IN)
       //   aclk_next = C_STATE_ERROR; // Early or Late EOL
       // else
          aclk_next = C_STATE_EVEN;
      // Stall on SI
      else if (aclk_xfer_mi)
        aclk_next = C_STATE_ACTIVE;
      // Backpressure on MI
      else if (aclk_xfer_si)
       // if (TLAST_IN)
       //   aclk_next = C_STATE_ERROR; // Early or Late EOL
       // else
          aclk_next = C_STATE_WAIT;
      // NOOP
      else 
        aclk_next = C_STATE_ODD;

    // Wait for MI 
    // State machine waiting to push sample on MI
    // There is already another even sample pending from the next pair
    // Pipeline is full
    C_STATE_WAIT:
      if (aclk_xfer_mi && aclk_tlast_dly)
        aclk_next = C_STATE_ODD;
      else if (aclk_xfer_mi)
        aclk_next = C_STATE_EVEN;
      else
        aclk_next = C_STATE_WAIT;

    // Error condition
    default:
      aclk_next = C_STATE_IDLE;

  endcase
end

// Register inputs
always @(posedge ACLK) begin
  if (reset) begin
    aclk_tuser <= 1'b0;
    aclk_tlast <= 1'b0;
    aclk_tlast_dly <= 1'b0;
    aclk_fid   <= 1'b0;
    REMAP_TLAST_ADV  <= 1'b0;
  end
  else if (ACLKEN) begin
    if (aclk_xfer_si) begin
      // Even sample
      if (aclk_state == C_STATE_IDLE || aclk_state == C_STATE_ACTIVE) begin
        aclk_tdata_even     <= TDATA_IN;
        aclk_tuser          <= TUSER_IN;
        aclk_fid            <= FID_IN;
        aclk_tlast          <= 1'b0;
        aclk_tlast_dly      <= 1'b0;
      end
      // Odd sample
      else if (aclk_state == C_STATE_EVEN) begin
        aclk_tlast          <= TLAST_IN;
        aclk_tdata_odd      <= TDATA_IN;
      end
      // Check for backpressure
      else if (aclk_state == C_STATE_ODD) begin
        // No backpressure
        if(TLAST_IN)
            REMAP_TLAST_ADV     <= 1'b1;
        
        if (aclk_xfer_mi) begin
          aclk_tdata_even     <= TDATA_IN;
          aclk_tuser          <= TUSER_IN;
          aclk_fid            <= FID_IN;
          if(aclk_tlast_dly)
            aclk_tlast_dly      <= 1'b0;
          else if(TLAST_IN) begin
            aclk_tlast          <= TLAST_IN;
            aclk_tlast_dly      <= 1'b1;
          end
        end 
        // Has backpressure, store even sample 
        else begin
          aclk_tdata_even_dly <= TDATA_IN;
          aclk_tuser_dly      <= TUSER_IN;
          aclk_fid_dly        <= FID_IN;
          aclk_tlast_dly      <= TLAST_IN;
        end
      end
    end

    else if (aclk_xfer_mi) begin
      // Load stored even sample
      if (aclk_state == C_STATE_WAIT) begin
        aclk_tdata_even     <= aclk_tdata_even_dly;
        aclk_tuser          <= aclk_tuser_dly;
        aclk_fid            <= aclk_fid_dly;
       // if(aclk_tlast_dly & aclk_tlast) begin
       //     aclk_tlast          <= 1'b0;
       //     aclk_tlast_dly      <= 1'b0;
       // end
       if(aclk_tlast_dly) begin
            aclk_tlast          <= 1'b1;
            aclk_tlast_dly      <= 1'b0;
       end
      end
    end

  end
end

// Extract odd chroma to write into FIFO
generate 
if (C_PIXELS_PER_CLOCK == 1) begin : generate_1ppc_fifo_wr_data
  assign aclk_wr_data = {aclk_tlast,
                         aclk_tdata_odd [C_S_AXIS_COMPONENT_WIDTH                    +: C_S_AXIS_COMPONENT_WIDTH]};
end
else if (C_PIXELS_PER_CLOCK == 2) begin : generate_2ppc_fifo_wr_data
  assign aclk_wr_data = {aclk_tlast,
                         aclk_tdata_odd [1*C_BITS_PER_PIXEL+C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                         aclk_tdata_even[1*C_BITS_PER_PIXEL+C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH]};
end
else if (C_PIXELS_PER_CLOCK == 4) begin : generate_4ppc_fifo_wr_data
  assign aclk_wr_data = {aclk_tlast,
                         aclk_tdata_odd [3*C_BITS_PER_PIXEL+C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                         aclk_tdata_odd [1*C_BITS_PER_PIXEL+C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                         aclk_tdata_even[3*C_BITS_PER_PIXEL+C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                         aclk_tdata_even[1*C_BITS_PER_PIXEL+C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH]};
end
else if (C_PIXELS_PER_CLOCK == 8) begin : generate_8ppc_fifo_wr_data
  assign aclk_wr_data = {aclk_tlast,
                         aclk_tdata_odd [7*C_BITS_PER_PIXEL+C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                         aclk_tdata_odd [5*C_BITS_PER_PIXEL+C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                         aclk_tdata_odd [3*C_BITS_PER_PIXEL+C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                         aclk_tdata_odd [1*C_BITS_PER_PIXEL+C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                         aclk_tdata_even[7*C_BITS_PER_PIXEL+C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                         aclk_tdata_even[5*C_BITS_PER_PIXEL+C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                         aclk_tdata_even[3*C_BITS_PER_PIXEL+C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                         aclk_tdata_even[1*C_BITS_PER_PIXEL+C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH]};
end
endgenerate

// Generate the line phase
// Phase 0 - even line
// Phase 1 - odd line
always @(posedge ACLK) begin
  if (reset) begin
    aclk_line_phase <= 1'b0;
  end
  else if (ACLKEN) begin
    // Line phase
    if (aclk_state == C_STATE_IDLE)
      aclk_line_phase <= 1'b0;
    else if (aclk_xfer_mi & TLAST_OUT)
      aclk_line_phase <= aclk_line_phase + 1'b1;
  end
end

// FIFO write enable logic
always @(posedge ACLK) begin
  if (reset) begin
    aclk_wr_en <= 1'b0;
  end
  else if (ACLKEN) begin
    if ((aclk_xfer_si & ~aclk_line_phase & (aclk_state == C_STATE_EVEN)                   ) || 
        (~aclk_line_phase & aclk_tlast_dly & aclk_xfer_mi & (aclk_state == C_STATE_WAIT)  ) ||
        (~aclk_line_phase & aclk_xfer_si & TLAST_IN & (aclk_state == C_STATE_WAIT)        ) ||
        (~aclk_line_phase & aclk_xfer_si & aclk_xfer_mi & TLAST_IN & (aclk_state == C_STATE_ODD)))
      aclk_wr_en <= 1'b1;
    else
      aclk_wr_en <= 1'b0;
  end
end

// Instantiate FIFO
// Used to buffer chroma samples for odd pixels on every even line
// The depth of the fifo needs to be half the line length
axi_remapper_tx_v1_0_fifo_sync #(
  .C_ADDR_WIDTH     (C_ADDR_WIDTH),
  .C_DATA_WIDTH     (C_PIXELS_PER_CLOCK*C_S_AXIS_COMPONENT_WIDTH+1)
) FIFO_INST (
  .CLK              (ACLK),                          
  .RESET            (reset),                        

  .WR_DATA          (aclk_wr_data),
  .WR_EN            (aclk_wr_en), 
  .WR_DATA_COUNT    (),         
  .WR_BUSY          (),
  .WR_FULL          (),                                 
  .WR_OVERFLOW      (overflow),

  .RD_DATA          (aclk_rd_data),  
  .RD_EN            (aclk_rd_en),                              
  .RD_DATA_COUNT    (),
  .RD_BUSY          (),
  .RD_EMPTY         (),                                
  .RD_UNDERFLOW     (underflow)                             
);

// Output assignments
assign TVALID_OUT = (aclk_remap) ? (aclk_state == C_STATE_ODD || aclk_state == C_STATE_WAIT)
                                 : TVALID_IN;
assign TREADY_OUT = (aclk_remap) ? (aclk_state != C_STATE_WAIT) 
                                 : TREADY_IN;
assign TUSER_OUT  = (aclk_remap) ? (aclk_tuser)
                                 : TUSER_IN;
assign TLAST_OUT  = (aclk_remap) ? (aclk_line_phase ? aclk_rd_data[C_PIXELS_PER_CLOCK*C_S_AXIS_COMPONENT_WIDTH] : aclk_tlast)
                                 : TLAST_IN;
assign FID_OUT    = (aclk_remap) ? (aclk_fid)
                                 : FID_IN;

assign FIFO_UNDERFLOW_OUT    = (aclk_remap) ? (underflow)
                                 : 1'b0;
assign FIFO_OVERFLOW_OUT    = (aclk_remap) ? (overflow)
                                 : 1'b0;
generate 
if (C_PIXELS_PER_CLOCK == 1) begin: generate_tdata_1ppc
  assign TDATA_OUT = (aclk_remap) ? (aclk_line_phase ? {aclk_tdata_odd [0                        +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_rd_data   [0                        +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[0                        +: C_S_AXIS_COMPONENT_WIDTH]}
                                                     :
                                                       {aclk_tdata_odd [0                        +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[0                        +: 2*C_S_AXIS_COMPONENT_WIDTH]})
                                  :
                                    (TDATA_IN);
end
else if (C_PIXELS_PER_CLOCK == 2) begin: generate_tdata_2ppc
  assign TDATA_OUT = (aclk_remap) ? (aclk_line_phase ? {aclk_tdata_odd [1*C_BITS_PER_PIXEL       +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_rd_data   [C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_odd [0*C_BITS_PER_PIXEL       +: C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_even[1*C_BITS_PER_PIXEL       +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_rd_data   [0                        +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[0*C_BITS_PER_PIXEL       +: C_S_AXIS_COMPONENT_WIDTH]}
                                                     :
                                                       {aclk_tdata_odd [1*C_BITS_PER_PIXEL       +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_odd [0*C_BITS_PER_PIXEL       +: 2*C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_even[1*C_BITS_PER_PIXEL       +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[0*C_BITS_PER_PIXEL       +: 2*C_S_AXIS_COMPONENT_WIDTH]})
                                  :
                                    (TDATA_IN);
end
else if (C_PIXELS_PER_CLOCK == 4) begin: generate_tdata_4ppc
  assign TDATA_OUT = (aclk_remap) ? (aclk_line_phase ? {aclk_tdata_odd [3*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_rd_data   [3*C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_odd [2*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_odd [1*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_rd_data   [2*C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_odd [0*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_even[3*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_rd_data   [C_S_AXIS_COMPONENT_WIDTH   +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[2*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_even[1*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_rd_data   [0                          +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[0*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH]}
                                                     :
                                                       {aclk_tdata_odd [3*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_odd [2*C_BITS_PER_PIXEL         +: 2*C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_odd [1*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_odd [0*C_BITS_PER_PIXEL         +: 2*C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_even[3*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[2*C_BITS_PER_PIXEL         +: 2*C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_even[1*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[0*C_BITS_PER_PIXEL         +: 2*C_S_AXIS_COMPONENT_WIDTH]})
                                  :
                                    (TDATA_IN);
end
else if (C_PIXELS_PER_CLOCK == 8) begin: generate_tdata_8ppc
  assign TDATA_OUT = (aclk_remap) ? (aclk_line_phase ? {aclk_tdata_odd [7*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_rd_data   [7*C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_odd [6*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                                                                                                 
                                                        aclk_tdata_odd [5*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_rd_data   [6*C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_odd [4*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_odd [3*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_rd_data   [5*C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_odd [2*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_odd [1*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_rd_data   [4*C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_odd [0*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_even[7*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_rd_data   [3*C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[6*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_even[5*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_rd_data   [2*C_S_AXIS_COMPONENT_WIDTH +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[4*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_even[3*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_rd_data   [C_S_AXIS_COMPONENT_WIDTH   +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[2*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_even[1*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_rd_data   [0                          +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[0*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH]}
                                                     :
                                                       {aclk_tdata_odd [7*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_odd [6*C_BITS_PER_PIXEL         +: 2*C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_odd [5*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_odd [4*C_BITS_PER_PIXEL         +: 2*C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_odd [3*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_odd [2*C_BITS_PER_PIXEL         +: 2*C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_odd [1*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_odd [0*C_BITS_PER_PIXEL         +: 2*C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_even[7*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[6*C_BITS_PER_PIXEL         +: 2*C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_even[5*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[4*C_BITS_PER_PIXEL         +: 2*C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_even[3*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[2*C_BITS_PER_PIXEL         +: 2*C_S_AXIS_COMPONENT_WIDTH],

                                                        aclk_tdata_even[1*C_BITS_PER_PIXEL         +: C_S_AXIS_COMPONENT_WIDTH],
                                                        aclk_tdata_even[0*C_BITS_PER_PIXEL         +: 2*C_S_AXIS_COMPONENT_WIDTH]})
                                  :
                                    (TDATA_IN);
end
endgenerate

endmodule

`default_nettype wire


// (c) Copyright 2023 Advanced Micro Devices, Inc. All rights reserved.
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

// this module converts PPC and is used for YUV420 and also for normal PPC
// conversions to eliminate external remapper in systems
`timescale 1ns/1ps
`define SYNC_STAGE_AXI 3
module axi_remapper_tx_v1_0_ppc_converter 
# (
  parameter C_IN_PIXELS_PER_CLOCK    = 4,   // Pixels per clock [1,2,4, 8]
  parameter C_S_AXIS_TDATA_WIDTH     = 24,  // AXIS video tdata width
  parameter C_MAX_BPC                = 16,
  parameter C_HDMI_MODE              = 1
)
(

  input   wire aclk             ,               
  input   wire aresetn          ,              

  // Control
  input   wire [3:0] ppc        ,
  input   wire [1:0] vid_format ,

  // Slave Interface
  input   wire [C_S_AXIS_TDATA_WIDTH-1:0]
               video_in_tdata   ,
  input   wire video_in_tvalid  ,          
  output  wire video_out_tready ,      
  input   wire video_in_tuser   ,        
  input   wire video_in_tlast   ,        
  input   wire fid_in           ,         
  input   wire remap_tlast_adv  ,

  // Master Interface
  output  reg  [C_S_AXIS_TDATA_WIDTH-1:0]
               video_out_tdata  ,
  output  reg  video_out_tvalid ,       
  input   wire video_in_tready  ,      
  output  reg  video_out_tuser  ,        
  output  reg  video_out_tlast  ,        
  output  reg  fid_out           

);

wire                             valid_input_tran;
wire                             valid_output_tran;
reg  [C_S_AXIS_TDATA_WIDTH-1: 0] video_in_tdata_q;
reg                              video_in_tlast_q;
reg                              fid_in_q       ;
reg                              ppc_convert_count_start_flag;
reg                              video_out_tready_int;

assign valid_input_tran     = video_in_tvalid & video_out_tready_int;
assign valid_output_tran    = video_out_tvalid & video_in_tready;
assign video_out_tready     = video_out_tready_int & video_in_tready;
generate 
if((C_IN_PIXELS_PER_CLOCK == 8) && (C_HDMI_MODE == 1))
begin
    reg  ppc_convert_count;
    reg  ppc_convert_count_next;
    always @(posedge aclk)
    begin
        if(~aresetn)
        begin
            ppc_convert_count               <=  1'd0            ;
            ppc_convert_count_start_flag    <=  1'd0            ;
        end
        else if(video_in_tready)
        begin
            if(ppc_convert_count == 1'd1)   
            begin
                ppc_convert_count               <=   1'd0;
                ppc_convert_count_start_flag    <=   1'd0;
            end
            else
            begin
                ppc_convert_count               <=   ppc_convert_count_next;
                ppc_convert_count_start_flag    <=   1'd1;
            end
        end
    
        if(~aresetn)
        begin
            video_in_tdata_q                <=  1'd0            ;
            video_in_tlast_q                <=  1'd0            ;
            fid_in_q                        <=  1'd0            ;
        end
        else if(valid_input_tran)
        begin
            video_in_tdata_q    <=  video_in_tdata;
            video_in_tlast_q    <=  video_in_tlast;
            fid_in_q            <=  fid_in        ;
        end
    end
   
    always @(*)
    begin
        if(valid_output_tran && (ppc_convert_count == 1'd0) && video_in_tlast_q && remap_tlast_adv)   
            ppc_convert_count_next      =   1'b0;
        else if(valid_output_tran)
            ppc_convert_count_next      =   ppc_convert_count + 1'd1;
        else
            ppc_convert_count_next      =   ppc_convert_count;
    end

    always @(posedge aclk)
    begin
        if(~aresetn)
        begin
            video_out_tdata     <=  {C_S_AXIS_TDATA_WIDTH{1'b0}};
            video_out_tvalid    <=  1'b0;
            video_out_tready_int    <=  1'b1;
            video_out_tuser     <=  1'b0;
            video_out_tlast     <=  1'b0;
            fid_out             <=  1'b0;
        end
        else if(video_in_tready || (video_out_tready_int && ~ppc_convert_count_next))
        begin

            casex ({valid_input_tran,ppc_convert_count_next})    
                2'b10:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata[4*2*C_MAX_BPC-1:0] : (vid_format==2'b11) ? video_in_tdata[4*C_MAX_BPC-1:0] : video_in_tdata[4*3*C_MAX_BPC-1:0];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int<=  ~(video_in_tvalid & video_out_tready) & ~valid_output_tran;
                    video_out_tuser     <=  video_in_tuser;
                    video_out_tlast     <=  video_in_tlast & remap_tlast_adv;
                    fid_out             <=  fid_in;
                end
                2'bx1:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[8*2*C_MAX_BPC-1:4*2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[8*C_MAX_BPC-1:4*C_MAX_BPC] : video_in_tdata_q[8*3*C_MAX_BPC-1:4*3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int<=  1'b1;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  video_in_tlast_q;
                    fid_out             <=  fid_in_q        ;
                end
                default:
                begin
                   video_out_tdata     <=  {C_S_AXIS_TDATA_WIDTH{1'b0}};
                   video_out_tvalid    <=  1'b0;
                   video_out_tready_int<=  1'b1;
                   video_out_tuser     <=  1'b0;
                   video_out_tlast     <=  1'b0;
                   fid_out             <=  1'b0;
                end
            endcase
        end
    end
end
else if((C_IN_PIXELS_PER_CLOCK == 4) && (C_HDMI_MODE == 1))
begin
    reg valid_output_tran_flag;
    always @(posedge aclk)
    begin
        if(~aresetn)
        begin
            video_in_tdata_q                <=  1'd0            ;
            video_in_tlast_q                <=  1'd0            ;
            fid_in_q                        <=  1'd0            ;
        end
        else if(valid_input_tran)
        begin
            video_in_tdata_q    <=  video_in_tdata;
            video_in_tlast_q    <=  video_in_tlast;
            fid_in_q            <=  fid_in        ;
        end
    end

    always @(posedge aclk)
    begin
        if(~aresetn)
            valid_output_tran_flag  <=  1'd0               ;
        else if(valid_output_tran)
            valid_output_tran_flag  <=  1'd1               ;
    end

    
    always @(posedge aclk)
    begin
        if(~aresetn)
        begin
            video_out_tdata     <=  {C_S_AXIS_TDATA_WIDTH{1'b0}};
            video_out_tvalid    <=  1'b0;
            video_out_tready_int    <=  1'b1;
            video_out_tuser     <=  1'b0;
            video_out_tlast     <=  1'b0;
            fid_out             <=  1'b0;
        end
        else if(video_in_tready || (video_out_tready_int && ~valid_output_tran_flag))
        begin
            if(valid_input_tran)
            begin
                video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata[4*2*C_MAX_BPC-1:0] : (vid_format==2'b11) ? video_in_tdata[4*C_MAX_BPC-1:0] : video_in_tdata[4*3*C_MAX_BPC-1:0];
                video_out_tvalid    <=  valid_input_tran && valid_output_tran ? valid_output_tran_flag : 1'b1;
                video_out_tready_int<=  1'b1;
                video_out_tuser     <=  video_in_tuser;
                video_out_tlast     <=  video_in_tlast;
                fid_out             <=  fid_in;
            end
            else
            begin
                video_out_tdata     <=  {C_S_AXIS_TDATA_WIDTH{1'b0}};
                video_out_tvalid    <=  1'b0;
                video_out_tready_int    <=  1'b1;
                video_out_tuser     <=  1'b0;
                video_out_tlast     <=  1'b0;
                fid_out             <=  1'b0;
            end
        end
    end
end

else if(C_IN_PIXELS_PER_CLOCK == 8)
begin
    reg  [3:0]   ppc_convert_count;
    reg  [3:0]   ppc_convert_count_next;
    always @(posedge aclk)
    begin
        if(~aresetn)
        begin
            ppc_convert_count               <=  4'd0            ;
            ppc_convert_count_start_flag    <=  1'd0            ;
        end
        else if(video_in_tready)
        begin
            ppc_convert_count               <=   ppc_convert_count_next;
            ppc_convert_count_start_flag    <=   1'd1;
        end
    
        if(~aresetn)
        begin
            video_in_tdata_q                <=  1'd0            ;
            video_in_tlast_q                <=  1'd0            ;
            fid_in_q                        <=  1'd0            ;
        end
        else if(valid_input_tran)
        begin
            video_in_tdata_q    <=  video_in_tdata;
            video_in_tlast_q    <=  video_in_tlast;
            fid_in_q            <=  fid_in        ;
        end
    end

    always @(*)
    begin
        if(video_in_tvalid && video_in_tuser && video_out_tready && (|(ppc_convert_count)))
            ppc_convert_count_next      =   4'd0;
        else if(valid_output_tran && ((((ppc == 4'd1) && (ppc_convert_count == 4'd7)) || ((ppc == 4'd1) && video_in_tlast_q && remap_tlast_adv && (ppc_convert_count == 4'd3))) ||
                                 (((ppc == 4'd2) && (ppc_convert_count == 4'd3)) || ((ppc == 4'd2) && video_in_tlast_q && remap_tlast_adv && (ppc_convert_count == 4'd1))) ||
                                 (((ppc == 4'd4) && (ppc_convert_count == 4'd1)) || ((ppc == 4'd4) && video_in_tlast_q && remap_tlast_adv && (ppc_convert_count == 4'd0)))))
            ppc_convert_count_next      =   4'd0;
        else if(valid_output_tran)
            ppc_convert_count_next      =   ppc_convert_count + 4'd1;
        else
            ppc_convert_count_next      =   ppc_convert_count;
    end
    
    always @(posedge aclk)
    begin
        if(~aresetn)
        begin
            video_out_tdata     <=  {C_S_AXIS_TDATA_WIDTH{1'b0}};
            video_out_tvalid    <=  1'b0;
            video_out_tready_int    <=  1'b1;
            video_out_tuser     <=  1'b0;
            video_out_tlast     <=  1'b0;
            fid_out             <=  1'b0;
        end

        else if(video_in_tready || (video_out_tready_int && (ppc_convert_count_next == 4'd0) && (~ppc[3])))
        begin
            casex ({valid_input_tran,ppc,ppc_convert_count_next})    
                9'b100010000:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata[2*C_MAX_BPC-1:0] : (vid_format==2'b11) ? video_in_tdata[C_MAX_BPC-1:0] : video_in_tdata[3*C_MAX_BPC-1:0];
                    video_out_tvalid    <=  video_in_tvalid;
                    video_out_tready_int<=  ~(video_in_tvalid & video_out_tready) & ~valid_output_tran;
                    video_out_tuser     <=  video_in_tuser;
                    video_out_tlast     <=  1'b0;
                    fid_out             <=  fid_in;
                end
                9'bx00010001:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[2*2*C_MAX_BPC-1:2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[2*C_MAX_BPC-1:C_MAX_BPC] : video_in_tdata_q[2*3*C_MAX_BPC-1:3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int    <=  1'b0;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  1'b0;
                    fid_out             <=  fid_in_q;
                end
                9'bx00010010:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[3*2*C_MAX_BPC-1:2*2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[3*C_MAX_BPC-1:2*C_MAX_BPC] : video_in_tdata_q[3*3*C_MAX_BPC-1:2*3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int    <=  1'b0;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  1'b0;
                    fid_out             <=  fid_in_q;
                end
                9'bx00010011:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[4*2*C_MAX_BPC-1:3*2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[4*C_MAX_BPC-1:3*C_MAX_BPC] : video_in_tdata_q[4*3*C_MAX_BPC-1:3*3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int    <=  1'b0;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  video_in_tlast_q & remap_tlast_adv;
                    fid_out             <=  fid_in_q;
                end
                9'bx00010100:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[5*2*C_MAX_BPC-1:4*2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[5*C_MAX_BPC-1:4*C_MAX_BPC] : video_in_tdata_q[5*3*C_MAX_BPC-1:4*3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int    <=  1'b0;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  1'b0;
                    fid_out             <=  fid_in_q;
                end
                9'bx00010101:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[6*2*C_MAX_BPC-1:5*2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[6*C_MAX_BPC-1:5*C_MAX_BPC] : video_in_tdata_q[6*3*C_MAX_BPC-1:5*3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int    <=  1'b0;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  1'b0;
                    fid_out             <=  fid_in_q;
                end
                9'bx00010110:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[7*2*C_MAX_BPC-1:6*2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[7*C_MAX_BPC-1:6*C_MAX_BPC] : video_in_tdata_q[7*3*C_MAX_BPC-1:6*3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int    <=  1'b0;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  1'b0;
                    fid_out             <=  fid_in_q;
                end
                9'bx00010111:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[8*2*C_MAX_BPC-1:7*2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[8*C_MAX_BPC-1:7*C_MAX_BPC] : video_in_tdata_q[8*3*C_MAX_BPC-1:7*3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int    <=  1'b1;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  video_in_tlast_q;
                    fid_out             <=  fid_in_q;
                end
                9'b100100000:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata[2*2*C_MAX_BPC-1:0] : (vid_format==2'b11) ? video_in_tdata[2*C_MAX_BPC-1:0] : video_in_tdata[2*3*C_MAX_BPC-1:0];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int<=  ~(video_in_tvalid & video_out_tready) & ~valid_output_tran;
                    video_out_tuser     <=  video_in_tuser;
                    video_out_tlast     <=  1'b0;
                    fid_out             <=  fid_in;
                end
                9'bx00100001:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[4*2*C_MAX_BPC-1:2*2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[4*C_MAX_BPC-1:2*C_MAX_BPC] : video_in_tdata_q[4*3*C_MAX_BPC-1:2*3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int    <=  1'b0;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  video_in_tlast_q & remap_tlast_adv;
                    fid_out             <=  fid_in_q;
                end
                9'bx00100010:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[6*2*C_MAX_BPC-1:4*2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[6*C_MAX_BPC-1:4*C_MAX_BPC] : video_in_tdata_q[6*3*C_MAX_BPC-1:4*3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int    <=  1'b0;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  1'b0;
                    fid_out             <=  fid_in_q;
                end
                9'bx00100011:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[8*2*C_MAX_BPC-1:6*2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[8*C_MAX_BPC-1:6*C_MAX_BPC] : video_in_tdata_q[8*3*C_MAX_BPC-1:6*3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int    <=  1'b1;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  video_in_tlast_q;
                    fid_out             <=  fid_in_q;
                end
                9'b101000000:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata[4*2*C_MAX_BPC-1:0] : (vid_format==2'b11) ? video_in_tdata[4*C_MAX_BPC-1:0] : video_in_tdata[4*3*C_MAX_BPC-1:0];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int<=  ~(video_in_tvalid & video_out_tready) & ~valid_output_tran;
                    video_out_tuser     <=  video_in_tuser;
                    video_out_tlast     <=  video_in_tlast & remap_tlast_adv;
                    fid_out             <=  fid_in;
                end
                9'bx01000001:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[8*2*C_MAX_BPC-1:4*2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[8*C_MAX_BPC-1:4*C_MAX_BPC] : video_in_tdata_q[8*3*C_MAX_BPC-1:4*3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int    <=  1'b1;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  video_in_tlast_q;
                    fid_out             <=  fid_in_q;
                end
                9'b11000xxxx:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata[8*2*C_MAX_BPC-1:0] : (vid_format==2'b11) ? video_in_tdata[8*C_MAX_BPC-1:0] : video_in_tdata[8*3*C_MAX_BPC-1:0];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int<=  1'b1;
                    video_out_tuser     <=  video_in_tuser;
                    video_out_tlast     <=  video_in_tlast;
                    fid_out             <=  fid_in;
                end
                default:
                begin
                    video_out_tdata     <=  {C_S_AXIS_TDATA_WIDTH{1'b0}};
                    video_out_tvalid    <=  1'b0;
                    video_out_tready_int    <=  1'b1;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  1'b0;
                    fid_out             <=  1'b0;
                end
            endcase
        end
    end
end
else if(C_IN_PIXELS_PER_CLOCK == 4)
begin
    reg  [3:0]   ppc_convert_count;
    reg  [3:0]   ppc_convert_count_next;
    reg          valid_output_tran_flag;
    reg          video_in_tready_q;
    always @(posedge aclk)
    begin
        if(~aresetn)
        begin
            ppc_convert_count               <=   4'd0           ;
            ppc_convert_count_start_flag    <=   1'd0           ;
        end
        else if(video_in_tready)
        begin
            ppc_convert_count               <=   ppc_convert_count_next;
            ppc_convert_count_start_flag    <=   1'd1;
        end
    
        if(~aresetn)
        begin
            video_in_tdata_q                <=  1'd0            ;
            video_in_tlast_q                <=  1'd0            ;
            fid_in_q                        <=  1'd0            ;
        end
        else if(valid_input_tran)
        begin
            video_in_tdata_q    <=  video_in_tdata;
            video_in_tlast_q    <=  video_in_tlast;
            fid_in_q            <=  fid_in        ;
        end
    end

    always @(posedge aclk)
    begin
        if(~aresetn)
            valid_output_tran_flag  <=  1'd0               ;
        else if(valid_output_tran)
            valid_output_tran_flag  <=  1'd1               ;

        if(~aresetn)
            video_in_tready_q       <=  1'd0               ;
        else
            video_in_tready_q       <=  video_in_tready    ;
    end

    always @(*)
    begin
        if(video_in_tvalid && video_in_tuser && video_out_tready && (|(ppc_convert_count)))
            ppc_convert_count_next      =   4'd0;
        else if(valid_output_tran && ((((ppc == 4'd1) && (ppc_convert_count == 4'd3)) || ((ppc == 4'd1) && video_in_tlast_q && remap_tlast_adv && (ppc_convert_count == 4'd1))) ||
                                 (((ppc == 4'd2) && (ppc_convert_count == 4'd1)) || ((ppc == 4'd2) && video_in_tlast_q && remap_tlast_adv && (ppc_convert_count == 4'd0))) || 
                                 (((ppc == 4'd4) && (ppc_convert_count == 4'd0)))))
            ppc_convert_count_next      =   4'd0;
        else if(valid_output_tran)
            ppc_convert_count_next      =   ppc_convert_count + 4'd1;
        else
            ppc_convert_count_next      =   ppc_convert_count;
    end

    
    always @(posedge aclk)
    begin
        if(~aresetn)
        begin
            video_out_tdata     <=  {C_S_AXIS_TDATA_WIDTH{1'b0}};
            video_out_tvalid    <=  1'b0;
            video_out_tready_int    <=  1'b1;
            video_out_tuser     <=  1'b0;
            video_out_tlast     <=  1'b0;
            fid_out             <=  1'b0;
        end
        else if(video_in_tready || (video_out_tready_int && ((ppc != 4'd4) || ~valid_output_tran_flag) && (ppc_convert_count_next == 4'd0)))
        begin
            casex ({valid_input_tran,ppc,ppc_convert_count_next})    
                9'b100010000:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata[2*C_MAX_BPC-1:0] : (vid_format==2'b11) ? video_in_tdata[C_MAX_BPC-1:0] : video_in_tdata[3*C_MAX_BPC-1:0];
                    video_out_tvalid    <=  video_in_tvalid;
                    video_out_tready_int<=  ~(video_in_tvalid & video_out_tready) & ~valid_output_tran;
                    video_out_tuser     <=  video_in_tuser;
                    video_out_tlast     <=  1'b0;
                    fid_out             <=  fid_in;
                end
                9'bx00010001:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[2*2*C_MAX_BPC-1:2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[2*C_MAX_BPC-1:C_MAX_BPC] : video_in_tdata_q[2*3*C_MAX_BPC-1:3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int    <=  1'b0;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  video_in_tlast_q & remap_tlast_adv;
                    fid_out             <=  fid_in_q;
                end
                9'bx00010010:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[3*2*C_MAX_BPC-1:2*2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[3*C_MAX_BPC-1:2*C_MAX_BPC] : video_in_tdata_q[3*3*C_MAX_BPC-1:2*3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int    <=  1'b0;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  1'b0;
                    fid_out             <=  fid_in_q;
                end
                9'bx00010011:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[4*2*C_MAX_BPC-1:3*2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[4*C_MAX_BPC-1:3*C_MAX_BPC] : video_in_tdata_q[4*3*C_MAX_BPC-1:3*3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int    <=  1'b1;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  video_in_tlast_q;
                    fid_out             <=  fid_in_q;
                end
                9'b100100000:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata[2*2*C_MAX_BPC-1:0] : (vid_format==2'b11) ? video_in_tdata[2*C_MAX_BPC-1:0] : video_in_tdata[2*3*C_MAX_BPC-1:0];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int<=  ~(video_in_tvalid & video_out_tready) & ~valid_output_tran;
                    video_out_tuser     <=  video_in_tuser;
                    video_out_tlast     <=  video_in_tlast & remap_tlast_adv;
                    fid_out             <=  fid_in;
                end
                9'bx00100001:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata_q[4*2*C_MAX_BPC-1:2*2*C_MAX_BPC] : (vid_format==2'b11) ? video_in_tdata_q[4*C_MAX_BPC-1:2*C_MAX_BPC] : video_in_tdata_q[4*3*C_MAX_BPC-1:2*3*C_MAX_BPC];
                    video_out_tvalid    <=  1'b1;
                    video_out_tready_int    <=  1'b1;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  video_in_tlast_q;
                    fid_out             <=  fid_in_q;
                end
                9'b10100xxxx:
                begin
                    video_out_tdata     <=  (vid_format==2'b10) ? video_in_tdata[4*2*C_MAX_BPC-1:0] : (vid_format==2'b11) ? video_in_tdata[4*C_MAX_BPC-1:0] : video_in_tdata[4*3*C_MAX_BPC-1:0];
                    video_out_tvalid    <=  valid_input_tran && valid_output_tran && ~video_in_tready_q ? valid_output_tran_flag : 1'b1;
                    video_out_tready_int<=  1'b1;
                    video_out_tuser     <=  video_in_tuser;
                    video_out_tlast     <=  video_in_tlast;
                    fid_out             <=  fid_in;
                end
                default:
                begin
                    video_out_tdata     <=  {C_S_AXIS_TDATA_WIDTH{1'b0}};
                    video_out_tvalid    <=  1'b0;
                    video_out_tready_int    <=  1'b1;
                    video_out_tuser     <=  1'b0;
                    video_out_tlast     <=  1'b0;
                    fid_out             <=  1'b0;
                end
            endcase
        end
    end
end

endgenerate

endmodule



// (c) Copyright 2023 Advanced Micro Devices, Inc. All rights reserved.
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

// this module instantiates a YUV420 remapper and PPC converter
`timescale 1ns/1ps
`define SYNC_STAGE_AXI 3
module axi_remapper_tx_v1_0_top 
# (
  parameter C_FAMILY                     = "virtex6",
  parameter C_INPUT_PIXELS_PER_CLOCK           = 1,   // Pixels per clock [1,2,4, 8]
  parameter C_COMPONENTS_PER_PIXEL       = 3,   // Pixels per clock [1,2,4, 8]
  parameter C_S_AXIS_COMPONENT_WIDTH     = 8,   // AXIS video component width [8,10,12,16]
//  parameter C_S_AXIS_TDATA_WIDTH         = 24,  // AXIS video tdata width
  parameter C_ADDR_WIDTH_PIXEL_REMAP_420 = 10,  // AXIS video tdata width
  parameter C_YUV420_REMAP_EN            = 0,   // AXIS video tdata width
  parameter C_PPC_CONVERT_EN             = 0,    // AXIS video tdata width
  parameter C_DSC_EN                     = 0,
  parameter C_DP_MODE                    = 0,
  parameter C_HDMI_MODE                  = 1
)
(

  input   wire ACLK,               
  input   wire ACLKEN,              
  input   wire ARESETN,              

  input   wire 	locked,
  // Control
  input   wire YUV420_REMAP_EN,
  input   wire [3:0] OUTPUT_PPC,
  input   wire [1:0] VID_FORMAT,
  input   wire DSC_EN,

  // Slave Interface
  input   wire [(C_INPUT_PIXELS_PER_CLOCK * C_S_AXIS_COMPONENT_WIDTH * 3)-1:0]
               TDATA_IN,
  input   wire TVALID_IN,       
  output  wire TREADY_OUT,      
  input   wire [(C_DSC_EN*13) : 0]TUSER_IN,        
  input   wire TLAST_IN,        
  input   wire FID_IN,          

  // Master Interface
  output   wire [((C_DP_MODE * C_INPUT_PIXELS_PER_CLOCK * C_S_AXIS_COMPONENT_WIDTH * 3)+(C_HDMI_MODE * 4 * C_S_AXIS_COMPONENT_WIDTH * 3))-1:0]
               TDATA_OUT,
  output  wire TVALID_OUT,       
  input   wire TREADY_IN,      
  output  wire TUSER_OUT,        
  output  wire TLAST_OUT,        
  output  wire FID_OUT, 

  // Status
  output  wire REMAP_FIFO_OVERFLOW_OUT,
  output  wire REMAP_FIFO_UNDERFLOW_OUT


);

wire locked_sync;
reg locked_sync_dly;
reg [15:0] reset_pulse;
wire reset_gen;
wire dsc_en_sync;

assign reset_gen = reset_pulse[0];

generate if(C_DSC_EN)
begin : DSC_EN_S
    axi_remapper_tx_v1_0_cdc_single
    DSC_CDC_SINGLE_INST (
      .CLK_IN(ACLK),
      .DAT_IN(DSC_EN),
      .DAT_OUT(dsc_en_sync)
    );
end
else
begin
    assign dsc_en_sync  =   1'b0;
end
endgenerate

axi_remapper_tx_v1_0_cdc_single
CDC_SINGLE_INST (
  .CLK_IN(ACLK),
  .DAT_IN(locked),
  .DAT_OUT(locked_sync)
);
always @(posedge ACLK) begin
	locked_sync_dly <= locked_sync; 
end

always @(posedge ACLK) begin
	if(~ARESETN) begin
		reset_pulse <= 16'd0;	
	end
	else begin
		if(locked_sync_dly && (~locked_sync)) begin
			reset_pulse  <= 16'hFFFF;
		end
		else begin
			reset_pulse <= {1'b0,reset_pulse[15:1]};	
		end
	end	
end

parameter C_S_AXIS_TDATA_WIDTH = C_INPUT_PIXELS_PER_CLOCK * C_S_AXIS_COMPONENT_WIDTH * 3;
parameter C_M_AXIS_TDATA_WIDTH = 4 * C_S_AXIS_COMPONENT_WIDTH * 3;

wire [C_S_AXIS_TDATA_WIDTH-1 : 0]  TDATA_OUT_r        ;
wire [C_S_AXIS_TDATA_WIDTH-1 : 0]  tdata_to_remap     ;
wire                               tvalid_to_remap    ;
wire                               tready_from_remap  ;
wire                               tuser_to_remap     ;
wire                               tlast_to_remap     ;
wire                               fid_to_remap       ;

wire [C_S_AXIS_TDATA_WIDTH-1 : 0]  tdata_from_remap   ;
wire                               tvalid_from_remap  ;
wire                               tready_to_remap    ; 
wire                               tuser_from_remap   ;
wire                               tlast_from_remap   ;
wire                               fid_from_remap     ;

wire [C_S_AXIS_TDATA_WIDTH-1 : 0]  tdata_to_ppc     ;
wire                               tvalid_to_ppc    ;
wire                               tready_from_ppc  ;
wire                               tuser_to_ppc     ;
wire                               tlast_to_ppc     ;
wire                               fid_to_ppc       ;

wire [C_S_AXIS_TDATA_WIDTH-1 : 0]  tdata_from_ppc   ;
wire                               tvalid_from_ppc  ;
wire                               tready_to_ppc    ; 
wire                               tuser_from_ppc   ;
wire                               tlast_from_ppc   ;
wire                               fid_from_ppc     ;
wire                               REMAP_TLAST_ADV  ;

assign TDATA_OUT = (C_HDMI_MODE == 1) ? TDATA_OUT_r[C_M_AXIS_TDATA_WIDTH-1 : 0] : TDATA_OUT_r;

generate 
if(C_YUV420_REMAP_EN)
begin
    assign tdata_to_remap   =  TDATA_IN             ;
    assign tvalid_to_remap  =  TVALID_IN            ;
    assign TREADY_OUT       =  dsc_en_sync ? TREADY_IN : tready_from_remap      ;
//    assign TREADY_OUT       =  tready_from_remap    ;
    assign tuser_to_remap   =  TUSER_IN             ;
    assign tlast_to_remap   =  TLAST_IN             ;
    assign fid_to_remap     =  FID_IN               ;   

    assign tdata_to_ppc     =  tdata_from_remap     ;
    assign tvalid_to_ppc    =  tvalid_from_remap    ;
    assign tready_to_remap  =  tready_from_ppc      ;
    assign tuser_to_ppc     =  tuser_from_remap     ;
    assign tlast_to_ppc     =  tlast_from_remap     ;
    assign fid_to_ppc       =  fid_from_remap       ;
end
else
begin
    assign tdata_to_ppc     =  TDATA_IN             ;
    assign tvalid_to_ppc    =  TVALID_IN            ;
    assign TREADY_OUT       =  dsc_en_sync ? TREADY_IN : tready_from_ppc      ;
//    assign TREADY_OUT       =  tready_from_ppc      ;
    assign tuser_to_ppc     =  TUSER_IN             ;
    assign tlast_to_ppc     =  TLAST_IN             ;
    assign fid_to_ppc       =  FID_IN               ;
	assign REMAP_TLAST_ADV  =  1'b0                 ;
	assign REMAP_FIFO_OVERFLOW_OUT  = 1'b0;
	assign REMAP_FIFO_UNDERFLOW_OUT = 1'b0;

end
endgenerate 


generate
if(C_PPC_CONVERT_EN)
begin
    assign TDATA_OUT_r      = dsc_en_sync ? {{8{TUSER_IN[12]}} & TDATA_IN[(8*12)-1 :((8*12)-8)], {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[10]}} & TDATA_IN[(8*10)-1 :((8*10)-8)], {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[11]}} & TDATA_IN[(8*11)-1 :((8*11)-8)], {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[9]}} & TDATA_IN[(8*9)-1 :((8*9)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[7]}} & TDATA_IN[(8*7)-1 :((8*7)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[8]}} & TDATA_IN[(8*8)-1 :((8*8)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[6]}} & TDATA_IN[(8*6)-1 :((8*6)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[4]}} & TDATA_IN[(8*4)-1 :((8*4)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[5]}} & TDATA_IN[(8*5)-1 :((8*5)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[3]}} & TDATA_IN[(8*3)-1 :((8*3)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[1]}} & TDATA_IN[(8*1)-1 :((8*1)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[2]}} & TDATA_IN[(8*2)-1 :((8*2)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}}} :  tdata_from_ppc       ;
    assign TVALID_OUT       = dsc_en_sync ? TVALID_IN :  tvalid_from_ppc      ;
    assign tready_to_ppc    = dsc_en_sync ? TREADY_IN :  TREADY_IN            ;
    assign TUSER_OUT        = dsc_en_sync ? TUSER_IN[0]  :  tuser_from_ppc       ;
    assign TLAST_OUT        = dsc_en_sync ? TLAST_IN  :  tlast_from_ppc       ;
    assign FID_OUT          = dsc_en_sync ? FID_IN    :  fid_from_ppc         ;

end
else
begin
    assign TDATA_OUT_r      = dsc_en_sync ? {{8{TUSER_IN[12]}}& TDATA_IN[(8*12)-1 :((8*12)-8)], {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[10]}}& TDATA_IN[(8*10)-1 :((8*10)-8)], {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[11]}}& TDATA_IN[(8*11)-1 :((8*11)-8)], {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[9]}} & TDATA_IN[(8*9)-1 :((8*9)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[7]}} & TDATA_IN[(8*7)-1 :((8*7)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[8]}} & TDATA_IN[(8*8)-1 :((8*8)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[6]}} & TDATA_IN[(8*6)-1 :((8*6)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[4]}} & TDATA_IN[(8*4)-1 :((8*4)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[5]}} & TDATA_IN[(8*5)-1 :((8*5)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[3]}} & TDATA_IN[(8*3)-1 :((8*3)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[1]}} & TDATA_IN[(8*1)-1 :((8*1)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}},
                                             {8{TUSER_IN[2]}} & TDATA_IN[(8*2)-1 :((8*2)-8)] , {(C_S_AXIS_COMPONENT_WIDTH-8){1'b0}}} :  tdata_to_ppc       ;
    assign TVALID_OUT       = dsc_en_sync ? TVALID_IN :  tvalid_to_ppc      ;
    assign tready_from_ppc    = dsc_en_sync ? TREADY_IN :  TREADY_IN            ;
    assign TUSER_OUT        = dsc_en_sync ? TUSER_IN[0]  :  tuser_to_ppc       ;
    assign TLAST_OUT        = dsc_en_sync ? TLAST_IN  :  tlast_to_ppc       ;
    assign FID_OUT          = dsc_en_sync ? FID_IN    :  fid_to_ppc         ;
//    assign TDATA_OUT_r      =  tdata_to_ppc       ;
//    assign TVALID_OUT       =  tvalid_to_ppc      ;
//    assign tready_from_ppc  =  TREADY_IN            ;
//    assign TUSER_OUT        =  tuser_to_ppc       ;
//    assign TLAST_OUT        =  tlast_to_ppc       ;
//    assign FID_OUT          =  fid_to_ppc         ;
	
end
endgenerate


generate 
if(C_YUV420_REMAP_EN)
begin
axi_remapper_tx_v1_0_remap #(
  .C_FAMILY                 (C_FAMILY),
  .C_PIXELS_PER_CLOCK       (C_INPUT_PIXELS_PER_CLOCK),
  .C_COMPONENTS_PER_PIXEL   (3),
  .C_S_AXIS_COMPONENT_WIDTH (C_S_AXIS_COMPONENT_WIDTH),
  .C_S_AXIS_TDATA_WIDTH     (C_S_AXIS_TDATA_WIDTH),
  .C_ADDR_WIDTH             (C_ADDR_WIDTH_PIXEL_REMAP_420)
) REMAP_420_INST (
  .ACLK                     (ACLK                       ),               
  .ACLKEN                   (ACLKEN                     ),              
  .ARESETN                  (ARESETN &  (~reset_gen)    ),

  .REMAP_IN                 (YUV420_REMAP_EN            ),

  .TDATA_IN                 (tdata_to_remap             ),
  .TVALID_IN                (tvalid_to_remap            ),       
  .TREADY_OUT               (tready_from_remap          ),      
  .TUSER_IN                 (tuser_to_remap             ),
  .TLAST_IN                 (tlast_to_remap             ),
  .FID_IN                   (fid_to_remap               ),
                                                         
  .TDATA_OUT                (tdata_from_remap           ),
  .TVALID_OUT               (tvalid_from_remap          ),
  .TREADY_IN                (tready_to_remap            ),
  .TUSER_OUT                (tuser_from_remap           ),
  .TLAST_OUT                (tlast_from_remap           ),
  .FID_OUT                  (fid_from_remap             ),
  .REMAP_TLAST_ADV          (REMAP_TLAST_ADV            ),

  .FIFO_OVERFLOW_OUT        (REMAP_FIFO_OVERFLOW_OUT    ),
  .FIFO_UNDERFLOW_OUT       (REMAP_FIFO_UNDERFLOW_OUT   )
);
end

//if(C_YUV420_REMAP_EN || C_PPC_CONVERT_EN)
if(C_PPC_CONVERT_EN)
begin
axi_remapper_tx_v1_0_ppc_converter  #(
   .C_IN_PIXELS_PER_CLOCK(C_INPUT_PIXELS_PER_CLOCK),
   .C_S_AXIS_TDATA_WIDTH(C_S_AXIS_TDATA_WIDTH),
   .C_MAX_BPC(C_S_AXIS_COMPONENT_WIDTH),
   .C_HDMI_MODE(C_HDMI_MODE)
)  ppc_converter_inst (
  .aclk               (ACLK             ),
  .aresetn            (ARESETN &  (~reset_gen)    ),
  .ppc                (OUTPUT_PPC       ),
  .remap_tlast_adv    (REMAP_TLAST_ADV  ),
  .vid_format         (VID_FORMAT       ),
  .fid_in             (fid_to_ppc       ),
  .video_in_tdata     (tdata_to_ppc     ),
  .video_in_tvalid    (tvalid_to_ppc    ),
  .video_out_tready   (tready_from_ppc  ),
  .video_in_tuser     (tuser_to_ppc     ),
  .video_in_tlast     (tlast_to_ppc     ),
  .video_out_tdata    (tdata_from_ppc   ),
  .video_out_tvalid   (tvalid_from_ppc  ),
  .video_in_tready    (tready_to_ppc    ),
  .video_out_tuser    (tuser_from_ppc   ),
  .video_out_tlast    (tlast_from_ppc   ),
  .fid_out            (fid_from_ppc     ) 
);
end
endgenerate
endmodule



// (c) Copyright 2023 Advanced Micro Devices, Inc. All rights reserved.
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

// this module instantiates a AXI4S to Video Out Bridge IP
`timescale 1ps/1ps
`define SYNC_STAGE_AXI 3
module axi4svideo_bridge_v1_0_17 
# (
    parameter C_FAMILY = "virtex7",
    parameter pTCQ = 100,
    parameter pPIXELS_PER_CLOCK = 4,
    parameter pBPC              = 16,
    parameter pCOLOROMETRY      = 3,
    parameter pTDATA_NUM_BYTES  = 24,
    parameter pUG934_COMPLIANCE = 0,
    parameter pENABLE_DSC       = 0,
    parameter pENABLE_420       = 0,
    parameter pARB_RES_EN       = 0,
    parameter pINPUT_PIXELS_PER_CLOCK  = 8,
    parameter pSTART_DSC_BYTE_FROM_LSB = 0,
    parameter pPPC_CONVERT_EN   = 0
)
(

// AXI4-streaming interface
  input   wire                  aclk,                // axi-4 S clock
  input   wire                  rst,                 // general reset
  input   wire                  aclken,              // axi-4 clock enable
  input   wire                  aresetn,             // axi-4 reset active low
  input   wire [pTDATA_NUM_BYTES-1:0] video_in_tdata , // axi-4 S data
  input   wire                  video_in_tvalid, // axi-4 S valid 
  output  wire                  video_in_tready, // axi-4 S ready 
  input   wire                  video_in_tuser , // axi-4 S start of field
  input   wire                  video_in_tlast , // axi-4 S end of line
  input   wire                  fid,                 // Field ID, sampled on SOF
  
  input   wire                  soft_reset,             // axi-4 reset active low
// video output interface
  input   wire                  vid_io_out_clk ,        // clock for video output
  input   wire                  vid_io_out_ce,              // video clock enable


  output  wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       tx_vid_enable   , // video data enable
  output  wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       tx_vid_vsync      ,     // video vertical sync
  output  wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       tx_vid_hsync      ,     // video horizontal sync
  output  wire     [36*pPIXELS_PER_CLOCK - 1:0]                          tx_vid_pixel,
  
// Register/VTG Interface
  input   wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       vtiming_in_vsync,       // vsync from the video timing generator
  input   wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       vtiming_in_hsync,
  input   wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       vtiming_in_vblank,
  input   wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       vtiming_in_hblank,
  input   wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       vtiming_in_active_video,
  input   wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       vtiming_in_field_id,
  output  wire                                   vtg_ce,
  // output status bits
  output  wire                  locked,
  output  wire                  underflow,
  output  wire                  overflow,


  // SW prog inputs from DP Controller
  input   wire  [2:0]            vid_format,  // RGB/YUV = 2'b00; YUV422 = 2'b01; YUV420 = 2'b10; Y-Only = 2'b11;
  input   wire  [2+(pPIXELS_PER_CLOCK/8):0]            ppc,            // pixels per clock : 2'b100 = 4; 2'b010 = 2; 2'b001 = 1
  
  output  wire                   tx_vid_clk, // = vid_io_out_clk;
  output  wire                   tx_vid_reset,// = rst;
  output  wire                   tx_odd_even, //= 1'b0;
  output  wire                   sof_state_out,
  input   wire [15:0]            vtg_hactive,
  input   wire [15:0]            axi_tran_per_horiz_line,
  input   wire                   enable_dsc


);

wire [35:0] tx_vid_pixel0, tx_vid_pixel1, tx_vid_pixel2, tx_vid_pixel3;

core #(
 .C_FAMILY (C_FAMILY),
 .pTCQ (pTCQ),
 .pPIXELS_PER_CLOCK (pPIXELS_PER_CLOCK),
 .pBPC (pBPC),
 .pCOLOROMETRY (pCOLOROMETRY),
 .pTDATA_NUM_BYTES  (pTDATA_NUM_BYTES),
 .pUG934_COMPLIANCE (pUG934_COMPLIANCE),
 .pENABLE_DSC       (pENABLE_DSC),
 .pENABLE_420       (pENABLE_420),
 .pARB_RES_EN       (pARB_RES_EN),
 .pINPUT_PIXELS_PER_CLOCK  (pINPUT_PIXELS_PER_CLOCK),
 .pSTART_DSC_BYTE_FROM_LSB (pSTART_DSC_BYTE_FROM_LSB),
 .pPPC_CONVERT_EN   (pPPC_CONVERT_EN)
 ) dut (
   .aclk (aclk),
   .rst (rst),
   .aclken (aclken),
   .aresetn (aresetn),
   .video_in_tdata (video_in_tdata),
   .video_in_tvalid (video_in_tvalid),
   .video_in_tready (video_in_tready),
   .video_in_tuser (video_in_tuser),
   .video_in_tlast (video_in_tlast),
   .fid (fid),
   .soft_reset (soft_reset),
   .vid_io_out_clk (vid_io_out_clk),
   .vid_io_out_ce (vid_io_out_ce),
   .tx_vid_enable (tx_vid_enable),
   .tx_vid_vsync (tx_vid_vsync),
   .tx_vid_hsync (tx_vid_hsync),
   .tx_vid_pixel0 (tx_vid_pixel0),
   .tx_vid_pixel1 (tx_vid_pixel1),
   .tx_vid_pixel2 (tx_vid_pixel2),
   .tx_vid_pixel3 (tx_vid_pixel3),
   .vtiming_in_vsync (vtiming_in_vsync),
   .vtiming_in_hsync (vtiming_in_hsync),
   .vtiming_in_vblank (vtiming_in_vblank),
   .vtiming_in_hblank (vtiming_in_hblank),
   .vtiming_in_active_video (vtiming_in_active_video),
   .vtiming_in_field_id (vtiming_in_field_id),
   .vtg_ce (vtg_ce),
   .locked (locked),
   .underflow (underflow),
   .overflow (overflow),
   .vid_format (vid_format),
   .ppc (ppc),
   .tx_vid_clk (tx_vid_clk),
   .tx_vid_reset (tx_vid_reset),
   .tx_odd_even (tx_odd_even),
   .sof_state_out (sof_state_out),
   .vtg_hactive (vtg_hactive),
   .axi_tran_per_horiz_line (axi_tran_per_horiz_line),
   .enable_dsc (enable_dsc)
   );

generate
if (pPIXELS_PER_CLOCK == 4) begin
assign tx_vid_pixel = {tx_vid_pixel3,tx_vid_pixel2,tx_vid_pixel1,tx_vid_pixel0};
end
else if (pPIXELS_PER_CLOCK == 2) begin
assign tx_vid_pixel = {tx_vid_pixel1,tx_vid_pixel0};
end
else if (pPIXELS_PER_CLOCK == 1) begin
assign tx_vid_pixel = tx_vid_pixel0;
end
endgenerate

endmodule


// (c) Copyright 2023 Advanced Micro Devices, Inc. All rights reserved.
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

// this module instantiates a AXI4S to Video Out Bridge IP
`timescale 1ps/1ps
`define SYNC_STAGE_AXI 3
module core 
# (
    parameter C_FAMILY = "virtex7",
    parameter pTCQ = 100,
    parameter pPIXELS_PER_CLOCK = 4,
    parameter pBPC              = 16,
    parameter pCOLOROMETRY      = 3,
    parameter pTDATA_NUM_BYTES  = 24,
    parameter pUG934_COMPLIANCE = 0,
    parameter pENABLE_DSC       = 0,
    parameter pENABLE_420       = 0,
    parameter pARB_RES_EN       = 0,
    parameter pINPUT_PIXELS_PER_CLOCK  = 8,
    parameter pSTART_DSC_BYTE_FROM_LSB = 0,
    parameter pPPC_CONVERT_EN   = 0
)
(

// AXI4-streaming interface
  input   wire                  aclk,                // axi-4 S clock
  input   wire                  rst,                 // general reset
  input   wire                  aclken,              // axi-4 clock enable
  input   wire                  aresetn,             // axi-4 reset active low
  input   wire [pTDATA_NUM_BYTES-1:0] video_in_tdata , // axi-4 S data
  input   wire                  video_in_tvalid, // axi-4 S valid 
  output  wire                  video_in_tready, // axi-4 S ready 
  input   wire                  video_in_tuser , // axi-4 S start of field
  input   wire                  video_in_tlast , // axi-4 S end of line
  input   wire                  fid,                 // Field ID, sampled on SOF
  
  input   wire                  soft_reset,             // axi-4 reset active low
// video output interface
  input   wire                  vid_io_out_clk ,        // clock for video output
  input   wire                  vid_io_out_ce,              // video clock enable


  output  wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       tx_vid_enable   , // video data enable
  output  wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       tx_vid_vsync      ,     // video vertical sync
  output  wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       tx_vid_hsync      ,     // video horizontal sync
  output  wire     [35:0]                        tx_vid_pixel0,    // video data at DDR rate
  output  wire     [35:0]                        tx_vid_pixel1,    // video data at DDR rate
  output  wire     [35:0]                        tx_vid_pixel2,    // video data at DDR rate
  output  wire     [35:0]                        tx_vid_pixel3,    // video data at DDR rate
  output  wire     [47:0]                        tx_vid_pixel4,    // video data at DDR rate
  output  wire     [47:0]                        tx_vid_pixel5,    // video data at DDR rate
  output  wire     [47:0]                        tx_vid_pixel6,    // video data at DDR rate
  output  wire     [47:0]                        tx_vid_pixel7,    // video data at DDR rate
  
// Register/VTG Interface
  input   wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       vtiming_in_vsync,       // vsync from the video timing generator
  input   wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       vtiming_in_hsync,
  input   wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       vtiming_in_vblank,
  input   wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       vtiming_in_hblank,
  input   wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       vtiming_in_active_video,
  input   wire     [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]       vtiming_in_field_id,
  output  wire                                   vtg_ce,
  // output status bits
  output  wire                  locked,
  output  wire                  underflow,
  output  wire                  overflow,


  // SW prog inputs from DP Controller
  input   wire  [2:0]            vid_format,  // RGB/YUV = 2'b00; YUV422 = 2'b01; YUV420 = 2'b10; Y-Only = 2'b11;
  input   wire  [2+(pPIXELS_PER_CLOCK/8):0]            ppc,            // pixels per clock : 2'b100 = 4; 2'b010 = 2; 2'b001 = 1
  
  output  wire                   tx_vid_clk, // = vid_io_out_clk;
  output  wire                   tx_vid_reset,// = rst;
  output  wire                   tx_odd_even, //= 1'b0;
  output  wire                   sof_state_out,
  input   wire [15:0]            vtg_hactive,
  input   wire [15:0]            axi_tran_per_horiz_line,
  input   wire                   enable_dsc


);


wire [31:0]        vb_status;
wire [16*pPIXELS_PER_CLOCK*3-1 :0] video_in_tdata_zeropad_non_arb;
wire [16*pPIXELS_PER_CLOCK*3-1 :0] f_vid_data_non_arb;
wire [(16*pPIXELS_PER_CLOCK*3)-1 :0] video_in_tdata_zeropad_arb;
wire [(16*pPIXELS_PER_CLOCK*3)-1 :0] f_vid_data_arb;
wire [16*8*3-1 :0] f_vid_data;
wire [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]           f_vid_vsync;
wire [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]           f_vid_hsync;
wire [(pPIXELS_PER_CLOCK*pARB_RES_EN)-pARB_RES_EN:0]           f_vid_active_video;
wire               yuv420_remap_en;
wire  [2+(pPIXELS_PER_CLOCK/8):0]    ppc_aclk;            // pixels per clock : 2'b100 = 4; 2'b010 = 2; 2'b001 = 1
wire  [3:0]                  ppc_aclk_to_remap;
wire  [2:0]        vid_format_aclk;  // RGB/YUV = 2'b00; YUV422 = 2'b01; YUV420 = 2'b10; Y-Only = 2'b11;
wire  [2:0]        vid_format_vid_clk;  // RGB/YUV = 2'b00; YUV422 = 2'b01; YUV420 = 2'b10; Y-Only = 2'b11;
wire [(pINPUT_PIXELS_PER_CLOCK*pBPC*3)-1:0]       video_out_tdata_from_remap ; // axi-4 S data
wire                        video_out_tvalid_from_remap; // axi-4 S valid 
wire                        video_in_tready_to_remap   ; // axi-4 S ready 
wire                        video_out_tuser_from_remap ; // axi-4 S start of field
wire                        video_out_tlast_from_remap ; // axi-4 S end of line
wire                        video_in_tready_from_remap; // axi-4 S ready 
wire                        video_in_tready_from_dsc; // axi-4 S ready 

assign yuv420_remap_en  =   (vid_format_aclk == 3'b100);

/////////////////////////////////////////// 
// AXI4 to Video out bridge
 axi4svideo_bridge_v1_0_17_sync_cell #(.C_SYNC_STAGE(`SYNC_STAGE_AXI), .C_DW(1), .pTCQ(100)) 
 sync_cell_aresetn_inst    (.src_data(soft_reset), .dest_clk(aclk), .dest_data(i_sync_soft_reset_aclk));

 axi4svideo_bridge_v1_0_17_sync_cell #(.C_SYNC_STAGE(`SYNC_STAGE_AXI), .C_DW(1), .pTCQ(100)) 
 sync_cell_vid_rst_inst    (.src_data(soft_reset), .dest_clk(vid_io_out_clk), .dest_data(i_sync_soft_reset_vidclk));

 axi4svideo_bridge_v1_0_17_sync_cell #(.C_SYNC_STAGE(`SYNC_STAGE_AXI), .C_DW(3), .pTCQ(100)) 
 sync_cell_vid_format_aclk    (.src_data(vid_format), .dest_clk(aclk), .dest_data(vid_format_aclk));

 axi4svideo_bridge_v1_0_17_sync_cell #(.C_SYNC_STAGE(`SYNC_STAGE_AXI), .C_DW(3), .pTCQ(100)) 
 sync_cell_vid_format_vid_clk    (.src_data(vid_format), .dest_clk(vid_io_out_clk), .dest_data(vid_format_vid_clk));

 axi4svideo_bridge_v1_0_17_sync_cell #(.C_SYNC_STAGE(`SYNC_STAGE_AXI), .C_DW((pPIXELS_PER_CLOCK/8)+3), .pTCQ(100)) 
 sync_cell_ppc_aclk    (.src_data(ppc), .dest_clk(aclk), .dest_data(ppc_aclk));

 assign i_sync_aresetn = ((~i_sync_soft_reset_aclk) & aresetn);
 assign i_sync_rst = ((i_sync_soft_reset_vidclk) | rst);

 assign ppc_aclk_to_remap   =   {{(1-(pPIXELS_PER_CLOCK/8)){1'b0}},ppc_aclk};

generate if((pENABLE_DSC == 0) && (pARB_RES_EN == 0))
begin
 assign video_in_tdata_zeropad_non_arb = {{((48*pINPUT_PIXELS_PER_CLOCK)-(pINPUT_PIXELS_PER_CLOCK*pBPC*3)){1'b0}},video_out_tdata_from_remap};
 assign video_in_tready        = video_in_tready_from_remap;

 assign f_vid_data = {{(384-(16*pPIXELS_PER_CLOCK*3)){1'b0}},f_vid_data_non_arb};

 v_axi4s_vid_out_v4_0_19  #(
    .C_FAMILY(C_FAMILY),
    .C_PIXELS_PER_CLOCK(pPIXELS_PER_CLOCK),
    .C_COMPONENTS_PER_PIXEL(3),
    .C_S_AXIS_COMPONENT_WIDTH(16),
    .C_NATIVE_COMPONENT_WIDTH(16),
    .C_NATIVE_DATA_WIDTH(pPIXELS_PER_CLOCK*48),
    .C_S_AXIS_TDATA_WIDTH(pPIXELS_PER_CLOCK*48),
    .C_ADDR_WIDTH(11),
    .C_HAS_ASYNC_CLK(1),
    .C_HYSTERESIS_LEVEL(1024),
    .C_VTG_MASTER_SLAVE(0)
  )  inst (
    .aclk               (aclk),
    .aclken             (aclken),
    .aresetn            (i_sync_aresetn),
    .s_axis_video_tdata (video_in_tdata_zeropad_non_arb),
    .s_axis_video_tvalid(video_out_tvalid_from_remap),
    .s_axis_video_tready(video_in_tready_to_remap),
    .s_axis_video_tuser (video_out_tuser_from_remap),
    .s_axis_video_tlast (video_out_tlast_from_remap),
    .fid                ('b0),
    .vid_io_out_clk     (vid_io_out_clk),
    .vid_io_out_ce      (1'b1),
    .vid_io_out_reset   (i_sync_rst),
    .vid_active_video   (f_vid_active_video),
    .vid_vsync          (f_vid_vsync),
    .vid_hsync          (f_vid_hsync),
    .vid_vblank         (/*NC*/),
    .vid_hblank         (/*NC*/),
    .vid_field_id       (/*NC*/),
    .vid_data           (f_vid_data_non_arb),
    .vtg_vsync          (vtiming_in_vsync),
    .vtg_hsync          (vtiming_in_hsync),
    .vtg_vblank         (vtiming_in_vblank),
    .vtg_hblank         (vtiming_in_hblank),
    .vtg_active_video   (vtiming_in_active_video),
    .vtg_field_id       (vtiming_in_field_id),
    .vtg_ce             (vtg_ce),
    .locked             (locked),
    .overflow           (overflow),
    .underflow          (underflow),
    .sof_state_out      (sof_state_out),
    .status             (vb_status)
  );
end
else if((pENABLE_DSC == 0) && (pARB_RES_EN == 1))
begin
 assign video_in_tdata_zeropad_arb = {{((48*pPIXELS_PER_CLOCK)-(pINPUT_PIXELS_PER_CLOCK*pBPC*3)){1'b0}},video_out_tdata_from_remap};
 assign video_in_tready        = video_in_tready_from_remap;

 assign f_vid_data = {{(384-(16*pPIXELS_PER_CLOCK*3)){1'b0}},f_vid_data_arb};

 v_axi4s_vid_out_v4_0_19  #(
    .C_FAMILY(C_FAMILY),
    .C_PIXELS_PER_CLOCK(pPIXELS_PER_CLOCK),
    .C_COMPONENTS_PER_PIXEL(3),
    .C_S_AXIS_COMPONENT_WIDTH(16),
    .C_NATIVE_COMPONENT_WIDTH(16),
    .C_NATIVE_DATA_WIDTH(pPIXELS_PER_CLOCK*48),
    .C_S_AXIS_TDATA_WIDTH(pPIXELS_PER_CLOCK*48),
    .C_ADDR_WIDTH(11),
    .C_HAS_ASYNC_CLK(1),
    .C_HYSTERESIS_LEVEL(1024),
    .C_VTG_MASTER_SLAVE(0),
    .C_ARBITRARY_RES_EN(pARB_RES_EN)
  )  inst (
    .aclk               (aclk),
    .aclken             (aclken),
    .aresetn            (i_sync_aresetn),
    .s_axis_video_tdata (video_in_tdata_zeropad_arb),
    .s_axis_video_tvalid(video_out_tvalid_from_remap),
    .s_axis_video_tready(video_in_tready_to_remap),
    .s_axis_video_tuser (video_out_tuser_from_remap),
    .s_axis_video_tlast (video_out_tlast_from_remap),
    .fid                ('b0),
    .vid_io_out_clk     (vid_io_out_clk),
    .vid_io_out_ce      (1'b1),
    .vid_io_out_reset   (i_sync_rst),
    .vid_active_video_arb   (f_vid_active_video),
    .vid_vsync_arb          (f_vid_vsync),
    .vid_hsync_arb          (f_vid_hsync),
    .vid_vblank             (/*NC*/),
    .vid_hblank             (/*NC*/),
    .vid_field_id_arb       (/*NC*/),
    .vid_data_arb           (f_vid_data_arb),
    .vtg_vsync_arb          (vtiming_in_vsync),
    .vtg_hsync_arb          (vtiming_in_hsync),
    .vtg_vblank_arb         (vtiming_in_vblank),
    .vtg_hblank_arb         (vtiming_in_hblank),
    .vtg_active_video_arb   (vtiming_in_active_video),
    .vtg_field_id_arb       (vtiming_in_field_id),
    .vtg_ce                 (vtg_ce),
    .video_format           (vid_format_aclk[1:0]), 
    .locked                 (locked),
    .overflow               (overflow),
    .underflow              (underflow),
    .sof_state_out          (sof_state_out),
    .status                 (vb_status)
  );
end
else
begin
 assign video_in_tdata_zeropad_non_arb = {{(192-(pTDATA_NUM_BYTES)){1'b0}},video_in_tdata};
 assign video_in_tready        = video_in_tready_from_dsc;
 assign f_vid_data = {192'd0,f_vid_data_non_arb};

 reg    sof_state_out_int;

 assign sof_state_out = sof_state_out_int;
 always @(posedge aclk) begin
   if(~i_sync_aresetn)
   begin
     sof_state_out_int <= 1'b0;
   end
   else if (video_in_tuser && video_in_tvalid && video_in_tready_from_dsc)
   begin
     sof_state_out_int <= ~sof_state_out_int;
   end
 end
 

 v_dp_axi4s_vid_out_v1_0_9  #(
    .C_FAMILY(C_FAMILY),
    .C_PIXELS_PER_CLOCK(4),
    .C_COMPONENTS_PER_PIXEL(3),
    .C_S_AXIS_COMPONENT_WIDTH(16),
    .C_NATIVE_COMPONENT_WIDTH(16),
    .C_NATIVE_DATA_WIDTH(192),
    .C_S_AXIS_TDATA_WIDTH(192),
    .C_ADDR_WIDTH(11),
    .C_HAS_ASYNC_CLK(1),
    .C_HYSTERESIS_LEVEL(1024),
    .C_VTG_MASTER_SLAVE(0)
  )  inst (
    .aclk               (aclk),
    .aclken             (aclken),
    .aresetn            (i_sync_aresetn),
    .s_axis_video_tdata (video_in_tdata_zeropad_non_arb),
    .s_axis_video_tvalid(video_in_tvalid),
    .s_axis_video_tready(video_in_tready_from_dsc),
    .s_axis_video_tuser (video_in_tuser),
    .s_axis_video_tlast (video_in_tlast),
    .fid                ('b0),
    .vid_io_out_clk     (vid_io_out_clk),
    .vid_io_out_ce      (1'b1),
    .vid_io_out_reset   (i_sync_rst),
    .vid_active_video   (f_vid_active_video),
    .vid_vsync          (f_vid_vsync),
    .vid_hsync          (f_vid_hsync),
    .vid_vblank         (/*NC*/),
    .vid_hblank         (/*NC*/),
    .vid_field_id       (/*NC*/),
    .vid_data           (f_vid_data_non_arb),
    .vtg_vsync          (vtiming_in_vsync),
    .vtg_hsync          (vtiming_in_hsync),
    .vtg_vblank         (vtiming_in_vblank),
    .vtg_hblank         (vtiming_in_hblank),
    .vtg_active_video   (vtiming_in_active_video),
    .vtg_field_id       (vtiming_in_field_id),
    .vtg_ce             (vtg_ce),
    .locked             (locked),
    .overflow           (overflow),
    .underflow          (underflow),
    .status             (vb_status),
    .vtg_hactive        (vtg_hactive),
    .axi_tran_per_horiz_line (axi_tran_per_horiz_line),
    .enable_dsc         (enable_dsc)

  );
end
endgenerate


axi_remapper_tx_v1_0_top  #(
   .C_FAMILY(C_FAMILY),
   .C_INPUT_PIXELS_PER_CLOCK(pINPUT_PIXELS_PER_CLOCK),
   .C_S_AXIS_COMPONENT_WIDTH(pBPC),
   .C_YUV420_REMAP_EN(pENABLE_420),
   .C_PPC_CONVERT_EN(pPPC_CONVERT_EN),
   .C_DP_MODE(1),
   .C_HDMI_MODE(0)
)  remapper_inst (
   .ACLK                       (aclk                           ),
   .ACLKEN                     (aclken                         ),
   .ARESETN                    (i_sync_aresetn                 ),
   .YUV420_REMAP_EN            (yuv420_remap_en                ),
   .OUTPUT_PPC                 (ppc_aclk_to_remap              ),
   .VID_FORMAT                 (vid_format_aclk[1:0]           ),
   .TDATA_IN                   (video_in_tdata                 ),
   .TVALID_IN                  (video_in_tvalid                ),
   .TREADY_OUT                 (video_in_tready_from_remap     ),
   .TUSER_IN                   (video_in_tuser                 ),
   .TLAST_IN                   (video_in_tlast                 ),
   .FID_IN                     (1'b0                           ),
   .TDATA_OUT                  (video_out_tdata_from_remap     ),
   .TVALID_OUT                 (video_out_tvalid_from_remap    ),
   .TREADY_IN                  (video_in_tready_to_remap       ),
   .TUSER_OUT                  (video_out_tuser_from_remap     ),
   .TLAST_OUT                  (video_out_tlast_from_remap     ),
   .FID_OUT                    (),
   .REMAP_FIFO_OVERFLOW_OUT    (),
   .REMAP_FIFO_UNDERFLOW_OUT   ()  
);


reg [5:0]  bpp;
reg [4:0]  bits_per_colr;
reg [47:0] f_pixel0;
reg [47:0] f_pixel1;
reg [47:0] f_pixel2;
reg [47:0] f_pixel3;
reg [47:0] f_pixel4;
reg [47:0] f_pixel5;
reg [47:0] f_pixel6;
reg [47:0] f_pixel7;

reg [15:0] f_pixel_0_c0;
reg [15:0] f_pixel_0_c1;
reg [15:0] f_pixel_0_c2;

reg [15:0] f_pixel_1_c0;
reg [15:0] f_pixel_1_c1;
reg [15:0] f_pixel_1_c2;

reg [15:0] f_pixel_2_c0;
reg [15:0] f_pixel_2_c1;
reg [15:0] f_pixel_2_c2;

reg [15:0] f_pixel_3_c0;
reg [15:0] f_pixel_3_c1;
reg [15:0] f_pixel_3_c2;


//   // Decode misc0 BPC bits to get actual Bits per component 
//
//   always @(*)
//   begin
//     case(bpc)
//      3'b001 : bits_per_colr = 5'd8;
//      3'b010 : bits_per_colr = 5'd10;
//      3'b011 : bits_per_colr = 5'd12;
//      3'b100 : bits_per_colr = 5'd16;
//      default :  bits_per_colr = 5'd8;
//     endcase
//   end //always 


   // Based on format get 3 or 2 or 1 colors 
   localparam Y_ONLY = 2'b11;
   localparam YUV422 = 2'b10;
   localparam YUV444 = 2'b01;
   localparam RGB    = 2'b00;
//   always @(*)
//   begin
//      case(vid_format) 
//          Y_ONLY : begin
//              bpp = bits_per_colr; //8,10,12,16
//          end
//          YUV422 : begin
//              bpp = 2*bits_per_colr;//16,20,24,32
//          end
//          RGB : begin
//              bpp = 3*bits_per_colr; //24,30,36,48
//          end
//          YUV444 : bpp = 3*bits_per_colr; //24,30,36,48
//      endcase
//   end

   reg  [pPIXELS_PER_CLOCK-1:0]  f_vid_vsync_ph0;       
   reg  [pPIXELS_PER_CLOCK-1:0]  f_vid_hsync_ph0;       
   reg  [pPIXELS_PER_CLOCK-1:0]  f_vid_active_video_ph0;

   reg  [pPIXELS_PER_CLOCK-1:0]  f_vid_vsync_ph1;      
   reg  [pPIXELS_PER_CLOCK-1:0]  f_vid_hsync_ph1;      
   reg  [pPIXELS_PER_CLOCK-1:0]  f_vid_active_video_ph1;

// pBPC : Interface is generated for pBPC 
// bpc  : Active Bits out of pBPC. Always pBPC >= bpc

//assert if bpc > pBPC 
// DP native video is R G B while AXI4 S is R B G 
// DP native video is Cr Y Cb  while AXI4 S is Cr Cb Y 
    generate 
    if(pUG934_COMPLIANCE == 1 && pPIXELS_PER_CLOCK == 8)
    begin
    always @(posedge vid_io_out_clk)
    begin
      case(vid_format_vid_clk[1:0])
       RGB,YUV444 : begin
         f_pixel0 <= #pTCQ {f_vid_data[pBPC*3-1:pBPC*2],{(16-pBPC){1'b0}},  f_vid_data[pBPC*1-1:pBPC*0],{(16-pBPC){1'b0}},  f_vid_data[pBPC*2-1:pBPC*1],{(16-pBPC){1'b0}}}; 
         f_pixel1 <= #pTCQ {f_vid_data[pBPC*6-1:pBPC*5],{(16-pBPC){1'b0}},  f_vid_data[pBPC*4-1:pBPC*3],{(16-pBPC){1'b0}},   f_vid_data[pBPC*5-1:pBPC*4],{(16-pBPC){1'b0}}}; 
         f_pixel2 <= #pTCQ {f_vid_data[pBPC*9-1:pBPC*8],{(16-pBPC){1'b0}},  f_vid_data[pBPC*7-1:pBPC*6],{(16-pBPC){1'b0}},   f_vid_data[pBPC*8-1:pBPC*7],{(16-pBPC){1'b0}}}; 
         f_pixel3 <= #pTCQ {f_vid_data[pBPC*12-1:pBPC*11],{(16-pBPC){1'b0}},f_vid_data[pBPC*10-1:pBPC*9],{(16-pBPC){1'b0}}, f_vid_data[pBPC*11-1:pBPC*10],{(16-pBPC){1'b0}}};

         f_pixel4 <= #pTCQ {f_vid_data[pBPC*15-1:pBPC*14],{(16-pBPC){1'b0}},  f_vid_data[pBPC*13-1:pBPC*12],{(16-pBPC){1'b0}},  f_vid_data[pBPC*14-1:pBPC*13],{(16-pBPC){1'b0}}}; 
         f_pixel5 <= #pTCQ {f_vid_data[pBPC*18-1:pBPC*17],{(16-pBPC){1'b0}},  f_vid_data[pBPC*16-1:pBPC*15],{(16-pBPC){1'b0}},  f_vid_data[pBPC*17-1:pBPC*16],{(16-pBPC){1'b0}}}; 
         f_pixel6 <= #pTCQ {f_vid_data[pBPC*21-1:pBPC*20],{(16-pBPC){1'b0}},  f_vid_data[pBPC*19-1:pBPC*18],{(16-pBPC){1'b0}},  f_vid_data[pBPC*20-1:pBPC*19],{(16-pBPC){1'b0}}}; 
         f_pixel7 <= #pTCQ {f_vid_data[pBPC*24-1:pBPC*23],{(16-pBPC){1'b0}},  f_vid_data[pBPC*22-1:pBPC*21],{(16-pBPC){1'b0}},  f_vid_data[pBPC*23-1:pBPC*22],{(16-pBPC){1'b0}}};
       end
       YUV422 : begin
         f_pixel0 <= #pTCQ {f_vid_data[(pBPC*2)-1:pBPC*1],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*1)-1:pBPC*0],{(32-pBPC){1'b0}}}; 
         f_pixel1 <= #pTCQ {f_vid_data[(pBPC*4)-1:pBPC*3],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*3)-1:pBPC*2],{(32-pBPC){1'b0}}}; 
         f_pixel2 <= #pTCQ {f_vid_data[(pBPC*6)-1:pBPC*5],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*5)-1:pBPC*4],{(32-pBPC){1'b0}}}; 
         f_pixel3 <= #pTCQ {f_vid_data[(pBPC*8)-1:pBPC*7],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*7)-1:pBPC*6],{(32-pBPC){1'b0}}}; 

         f_pixel4 <= #pTCQ {f_vid_data[(pBPC*10)-1:pBPC* 9],{(16-pBPC){1'b0}}, f_vid_data[(pBPC* 9)-1:pBPC* 8],{(32-pBPC){1'b0}}}; 
         f_pixel5 <= #pTCQ {f_vid_data[(pBPC*12)-1:pBPC*11],{(16-pBPC){1'b0}}, f_vid_data[(pBPC*11)-1:pBPC*10],{(32-pBPC){1'b0}}}; 
         f_pixel6 <= #pTCQ {f_vid_data[(pBPC*14)-1:pBPC*13],{(16-pBPC){1'b0}}, f_vid_data[(pBPC*13)-1:pBPC*12],{(32-pBPC){1'b0}}}; 
         f_pixel7 <= #pTCQ {f_vid_data[(pBPC*16)-1:pBPC*15],{(16-pBPC){1'b0}}, f_vid_data[(pBPC*15)-1:pBPC*14],{(32-pBPC){1'b0}}}; 

       end
       Y_ONLY : begin
         f_pixel0 <= #pTCQ {f_vid_data[(pBPC*1)-1:pBPC*0],{(48-pBPC){1'b0}}}; 
         f_pixel1 <= #pTCQ {f_vid_data[(pBPC*2)-1:pBPC*1],{(48-pBPC){1'b0}}}; 
         f_pixel2 <= #pTCQ {f_vid_data[(pBPC*3)-1:pBPC*2],{(48-pBPC){1'b0}}}; 
         f_pixel3 <= #pTCQ {f_vid_data[(pBPC*4)-1:pBPC*3],{(48-pBPC){1'b0}}};

         f_pixel4 <= #pTCQ {f_vid_data[(pBPC*5)-1:pBPC*4],{(48-pBPC){1'b0}}}; 
         f_pixel5 <= #pTCQ {f_vid_data[(pBPC*6)-1:pBPC*5],{(48-pBPC){1'b0}}}; 
         f_pixel6 <= #pTCQ {f_vid_data[(pBPC*7)-1:pBPC*6],{(48-pBPC){1'b0}}}; 
         f_pixel7 <= #pTCQ {f_vid_data[(pBPC*8)-1:pBPC*7],{(48-pBPC){1'b0}}}; 
       end
       default : begin
         f_pixel0 <= #pTCQ {f_vid_data[(pBPC*3)-1:pBPC*2],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*2)-1:pBPC*1],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*1)-1:pBPC*0],{(16-pBPC){1'b0}}}; 
         f_pixel1 <= #pTCQ {f_vid_data[(pBPC*6)-1:pBPC*5],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*5)-1:pBPC*4],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*4)-1:pBPC*3],{(16-pBPC){1'b0}}}; 
         f_pixel2 <= #pTCQ {f_vid_data[(pBPC*9)-1:pBPC*8],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*8)-1:pBPC*7],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*7)-1:pBPC*6],{(16-pBPC){1'b0}}}; 
         f_pixel3 <= #pTCQ {f_vid_data[(pBPC*12)-1:pBPC*11],{(16-pBPC){1'b0}}, f_vid_data[(pBPC*11)-1:pBPC*10],{(16-pBPC){1'b0}}, f_vid_data[(pBPC*10)-1:pBPC*9],{(16-pBPC){1'b0}}};

         f_pixel4 <= #pTCQ {f_vid_data[pBPC*15-1:pBPC*14],{(16-pBPC){1'b0}},   f_vid_data[pBPC*14-1:pBPC*13],{(16-pBPC){1'b0}},   f_vid_data[pBPC*13-1:pBPC*12],{(16-pBPC){1'b0}}};
         f_pixel5 <= #pTCQ {f_vid_data[pBPC*18-1:pBPC*17],{(16-pBPC){1'b0}},   f_vid_data[pBPC*17-1:pBPC*16],{(16-pBPC){1'b0}},   f_vid_data[pBPC*16-1:pBPC*15],{(16-pBPC){1'b0}}};
         f_pixel6 <= #pTCQ {f_vid_data[pBPC*21-1:pBPC*20],{(16-pBPC){1'b0}},   f_vid_data[pBPC*20-1:pBPC*19],{(16-pBPC){1'b0}},   f_vid_data[pBPC*19-1:pBPC*18],{(16-pBPC){1'b0}}};
         f_pixel7 <= #pTCQ {f_vid_data[pBPC*24-1:pBPC*23],{(16-pBPC){1'b0}},   f_vid_data[pBPC*23-1:pBPC*22],{(16-pBPC){1'b0}},   f_vid_data[pBPC*22-1:pBPC*21],{(16-pBPC){1'b0}}};
       end
      endcase 
     f_vid_vsync_ph0        <= #pTCQ f_vid_vsync;
     f_vid_hsync_ph0        <= #pTCQ f_vid_hsync;
     f_vid_active_video_ph0 <= #pTCQ f_vid_active_video;
   end
   end
   else if(pUG934_COMPLIANCE == 1 && pPIXELS_PER_CLOCK == 4)
   begin
   always @(posedge vid_io_out_clk)
   begin
     case(vid_format_vid_clk[1:0])
      RGB,YUV444 : begin
        if(enable_dsc)
        begin
           if(pSTART_DSC_BYTE_FROM_LSB == 0)
           begin
               f_pixel0 <= #pTCQ {f_vid_data[95:88],{8{1'b0}},  f_vid_data[63:56],{8{1'b0}},  f_vid_data[31:24],{8{1'b0}}}; 
               f_pixel1 <= #pTCQ {f_vid_data[87:80],{8{1'b0}},  f_vid_data[55:48],{8{1'b0}},  f_vid_data[23:16],{8{1'b0}}}; 
               f_pixel2 <= #pTCQ {f_vid_data[79:72],{8{1'b0}},  f_vid_data[47:40],{8{1'b0}},  f_vid_data[15: 8],{8{1'b0}}}; 
               f_pixel3 <= #pTCQ {f_vid_data[71:64],{8{1'b0}},  f_vid_data[39:32],{8{1'b0}},  f_vid_data[ 7: 0],{8{1'b0}}};
           end
           else
           begin
               f_pixel0 <= #pTCQ {f_vid_data[ 7: 0],{8{1'b0}},  f_vid_data[39:32],{8{1'b0}},  f_vid_data[71:64],{8{1'b0}}}; 
               f_pixel1 <= #pTCQ {f_vid_data[15: 8],{8{1'b0}},  f_vid_data[47:40],{8{1'b0}},  f_vid_data[79:72],{8{1'b0}}}; 
               f_pixel2 <= #pTCQ {f_vid_data[23:16],{8{1'b0}},  f_vid_data[55:48],{8{1'b0}},  f_vid_data[87:80],{8{1'b0}}}; 
               f_pixel3 <= #pTCQ {f_vid_data[31:24],{8{1'b0}},  f_vid_data[63:56],{8{1'b0}},  f_vid_data[95:88],{8{1'b0}}};
           end

           //f_pixel0 <= #pTCQ {f_vid_data[pBPC*12-1:pBPC*11],{(16-pBPC){1'b0}},  f_vid_data[pBPC*8-1:pBPC*7],{(16-pBPC){1'b0}},  f_vid_data[pBPC*4-1:pBPC*3],{(16-pBPC){1'b0}}}; 
           //f_pixel1 <= #pTCQ {f_vid_data[pBPC*11-1:pBPC*10],{(16-pBPC){1'b0}},  f_vid_data[pBPC*7-1:pBPC*6],{(16-pBPC){1'b0}},   f_vid_data[pBPC*3-1:pBPC*2],{(16-pBPC){1'b0}}}; 
           //f_pixel2 <= #pTCQ {f_vid_data[pBPC*10-1:pBPC*9],{(16-pBPC){1'b0}},  f_vid_data[pBPC*6-1:pBPC*5],{(16-pBPC){1'b0}},   f_vid_data[pBPC*2-1:pBPC*1],{(16-pBPC){1'b0}}}; 
           //f_pixel3 <= #pTCQ {f_vid_data[pBPC*9-1:pBPC*8],{(16-pBPC){1'b0}},  f_vid_data[pBPC*5-1:pBPC*4],{(16-pBPC){1'b0}}, f_vid_data[pBPC*1-1:pBPC*0],{(16-pBPC){1'b0}}};
        end
        else
        begin
           f_pixel0 <= #pTCQ {f_vid_data[pBPC*3-1:pBPC*2],{(16-pBPC){1'b0}},  f_vid_data[pBPC*1-1:pBPC*0],{(16-pBPC){1'b0}},  f_vid_data[pBPC*2-1:pBPC*1],{(16-pBPC){1'b0}}}; 
           f_pixel1 <= #pTCQ {f_vid_data[pBPC*6-1:pBPC*5],{(16-pBPC){1'b0}},  f_vid_data[pBPC*4-1:pBPC*3],{(16-pBPC){1'b0}},   f_vid_data[pBPC*5-1:pBPC*4],{(16-pBPC){1'b0}}}; 
           f_pixel2 <= #pTCQ {f_vid_data[pBPC*9-1:pBPC*8],{(16-pBPC){1'b0}},  f_vid_data[pBPC*7-1:pBPC*6],{(16-pBPC){1'b0}},   f_vid_data[pBPC*8-1:pBPC*7],{(16-pBPC){1'b0}}}; 
           f_pixel3 <= #pTCQ {f_vid_data[pBPC*12-1:pBPC*11],{(16-pBPC){1'b0}},f_vid_data[pBPC*10-1:pBPC*9],{(16-pBPC){1'b0}}, f_vid_data[pBPC*11-1:pBPC*10],{(16-pBPC){1'b0}}};
        end
      end
      YUV422 : begin
        f_pixel0 <= #pTCQ {f_vid_data[(pBPC*2)-1:pBPC*1],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*1)-1:pBPC*0],{(32-pBPC){1'b0}}}; 
        f_pixel1 <= #pTCQ {f_vid_data[(pBPC*4)-1:pBPC*3],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*3)-1:pBPC*2],{(32-pBPC){1'b0}}}; 
        f_pixel2 <= #pTCQ {f_vid_data[(pBPC*6)-1:pBPC*5],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*5)-1:pBPC*4],{(32-pBPC){1'b0}}}; 
        f_pixel3 <= #pTCQ {f_vid_data[(pBPC*8)-1:pBPC*7],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*7)-1:pBPC*6],{(32-pBPC){1'b0}}}; 
      end
      Y_ONLY : begin
        f_pixel0 <= #pTCQ {f_vid_data[(pBPC*1)-1:pBPC*0],{(48-pBPC){1'b0}}}; 
        f_pixel1 <= #pTCQ {f_vid_data[(pBPC*2)-1:pBPC*1],{(48-pBPC){1'b0}}}; 
        f_pixel2 <= #pTCQ {f_vid_data[(pBPC*3)-1:pBPC*2],{(48-pBPC){1'b0}}}; 
        f_pixel3 <= #pTCQ {f_vid_data[(pBPC*4)-1:pBPC*3],{(48-pBPC){1'b0}}}; 
      end
      default : begin
        f_pixel0 <= #pTCQ {f_vid_data[(pBPC*3)-1:pBPC*2],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*2)-1:pBPC*1],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*1)-1:pBPC*0],{(16-pBPC){1'b0}}}; 
        f_pixel1 <= #pTCQ {f_vid_data[(pBPC*6)-1:pBPC*5],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*5)-1:pBPC*4],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*4)-1:pBPC*3],{(16-pBPC){1'b0}}}; 
        f_pixel2 <= #pTCQ {f_vid_data[(pBPC*9)-1:pBPC*8],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*8)-1:pBPC*7],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*7)-1:pBPC*6],{(16-pBPC){1'b0}}}; 
        f_pixel3 <= #pTCQ {f_vid_data[(pBPC*12)-1:pBPC*11],{(16-pBPC){1'b0}}, f_vid_data[(pBPC*11)-1:pBPC*10],{(16-pBPC){1'b0}}, f_vid_data[(pBPC*10)-1:pBPC*9],{(16-pBPC){1'b0}}}; 
      end
     endcase 
    f_vid_vsync_ph0        <= #pTCQ f_vid_vsync;
    f_vid_hsync_ph0        <= #pTCQ f_vid_hsync;
    f_vid_active_video_ph0 <= #pTCQ f_vid_active_video;
   end
   end
   else if(pUG934_COMPLIANCE == 1 && pPIXELS_PER_CLOCK == 2)
   begin
   always @(posedge vid_io_out_clk)
   begin
     case(vid_format_vid_clk[1:0])
      RGB,YUV444 : begin
        if(enable_dsc)
        begin
           if(pSTART_DSC_BYTE_FROM_LSB == 0)
           begin
               f_pixel0 <= #pTCQ {f_vid_data[47:40],{8{1'b0}},  f_vid_data[31:24],{8{1'b0}},  f_vid_data[15: 8],{8{1'b0}}}; 
               f_pixel1 <= #pTCQ {f_vid_data[39:32],{8{1'b0}},  f_vid_data[23:16],{8{1'b0}},  f_vid_data[ 7: 0],{8{1'b0}}}; 
               f_pixel2 <= #pTCQ 48'd0; 
               f_pixel3 <= #pTCQ 48'd0;
           end
           else
           begin
               f_pixel0 <= #pTCQ {f_vid_data[ 7: 0],{8{1'b0}},  f_vid_data[23:16],{8{1'b0}},  f_vid_data[39:32],{8{1'b0}}}; 
               f_pixel1 <= #pTCQ {f_vid_data[15: 8],{8{1'b0}},  f_vid_data[31:24],{8{1'b0}},  f_vid_data[47:40],{8{1'b0}}}; 
               f_pixel2 <= #pTCQ 48'd0; 
               f_pixel3 <= #pTCQ 48'd0;
           end

           //f_pixel0 <= #pTCQ {f_vid_data[pBPC*6-1:pBPC*5],{(16-pBPC){1'b0}},  f_vid_data[pBPC*4-1:pBPC*3],{(16-pBPC){1'b0}},  f_vid_data[pBPC*2-1:pBPC*1],{(16-pBPC){1'b0}}}; 
           //f_pixel1 <= #pTCQ {f_vid_data[pBPC*5-1:pBPC*4],{(16-pBPC){1'b0}},  f_vid_data[pBPC*3-1:pBPC*2],{(16-pBPC){1'b0}},   f_vid_data[pBPC*1-1:pBPC*0],{(16-pBPC){1'b0}}}; 
           //f_pixel2 <= #pTCQ 48'd0; 
           //f_pixel3 <= #pTCQ 48'd0; 
        end
        else
        begin
           f_pixel0 <= #pTCQ {f_vid_data[pBPC*3-1:pBPC*2],{(16-pBPC){1'b0}},  f_vid_data[pBPC*1-1:pBPC*0],{(16-pBPC){1'b0}},  f_vid_data[pBPC*2-1:pBPC*1],{(16-pBPC){1'b0}}}; 
           f_pixel1 <= #pTCQ {f_vid_data[pBPC*6-1:pBPC*5],{(16-pBPC){1'b0}},  f_vid_data[pBPC*4-1:pBPC*3],{(16-pBPC){1'b0}},   f_vid_data[pBPC*5-1:pBPC*4],{(16-pBPC){1'b0}}}; 
           f_pixel2 <= #pTCQ {f_vid_data[pBPC*9-1:pBPC*8],{(16-pBPC){1'b0}},  f_vid_data[pBPC*7-1:pBPC*6],{(16-pBPC){1'b0}},   f_vid_data[pBPC*8-1:pBPC*7],{(16-pBPC){1'b0}}}; 
           f_pixel3 <= #pTCQ {f_vid_data[pBPC*12-1:pBPC*11],{(16-pBPC){1'b0}},f_vid_data[pBPC*10-1:pBPC*9],{(16-pBPC){1'b0}}, f_vid_data[pBPC*11-1:pBPC*10],{(16-pBPC){1'b0}}};
        end
      end
      YUV422 : begin
        f_pixel0 <= #pTCQ {f_vid_data[(pBPC*2)-1:pBPC*1],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*1)-1:pBPC*0],{(32-pBPC){1'b0}}}; 
        f_pixel1 <= #pTCQ {f_vid_data[(pBPC*4)-1:pBPC*3],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*3)-1:pBPC*2],{(32-pBPC){1'b0}}}; 
        f_pixel2 <= #pTCQ {f_vid_data[(pBPC*6)-1:pBPC*5],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*5)-1:pBPC*4],{(32-pBPC){1'b0}}}; 
        f_pixel3 <= #pTCQ {f_vid_data[(pBPC*8)-1:pBPC*7],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*7)-1:pBPC*6],{(32-pBPC){1'b0}}}; 
      end
      Y_ONLY : begin
        f_pixel0 <= #pTCQ {f_vid_data[(pBPC*1)-1:pBPC*0],{(48-pBPC){1'b0}}}; 
        f_pixel1 <= #pTCQ {f_vid_data[(pBPC*2)-1:pBPC*1],{(48-pBPC){1'b0}}}; 
        f_pixel2 <= #pTCQ {f_vid_data[(pBPC*3)-1:pBPC*2],{(48-pBPC){1'b0}}}; 
        f_pixel3 <= #pTCQ {f_vid_data[(pBPC*4)-1:pBPC*3],{(48-pBPC){1'b0}}}; 
      end
      default : begin
        f_pixel0 <= #pTCQ {f_vid_data[(pBPC*3)-1:pBPC*2],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*2)-1:pBPC*1],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*1)-1:pBPC*0],{(16-pBPC){1'b0}}}; 
        f_pixel1 <= #pTCQ {f_vid_data[(pBPC*6)-1:pBPC*5],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*5)-1:pBPC*4],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*4)-1:pBPC*3],{(16-pBPC){1'b0}}}; 
        f_pixel2 <= #pTCQ {f_vid_data[(pBPC*9)-1:pBPC*8],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*8)-1:pBPC*7],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*7)-1:pBPC*6],{(16-pBPC){1'b0}}}; 
        f_pixel3 <= #pTCQ {f_vid_data[(pBPC*12)-1:pBPC*11],{(16-pBPC){1'b0}}, f_vid_data[(pBPC*11)-1:pBPC*10],{(16-pBPC){1'b0}}, f_vid_data[(pBPC*10)-1:pBPC*9],{(16-pBPC){1'b0}}}; 
      end
     endcase 
    f_vid_vsync_ph0        <= #pTCQ f_vid_vsync;
    f_vid_hsync_ph0        <= #pTCQ f_vid_hsync;
    f_vid_active_video_ph0 <= #pTCQ f_vid_active_video;
   end
   end
   else if(pUG934_COMPLIANCE == 1)
   begin
   always @(posedge vid_io_out_clk)
   begin
     case(vid_format_vid_clk[1:0])
      RGB,YUV444 : begin
        if(enable_dsc)
        begin
           if(pSTART_DSC_BYTE_FROM_LSB == 0)
           begin
               f_pixel0 <= #pTCQ {f_vid_data[23:16],{8{1'b0}},  f_vid_data[15: 8],{8{1'b0}},  f_vid_data[ 7: 0],{8{1'b0}}}; 
               f_pixel1 <= #pTCQ 48'd0; 
               f_pixel2 <= #pTCQ 48'd0; 
               f_pixel3 <= #pTCQ 48'd0; 
           end
           else
           begin
               f_pixel0 <= #pTCQ {f_vid_data[ 7: 0],{8{1'b0}},  f_vid_data[15: 8],{8{1'b0}},  f_vid_data[23:16],{8{1'b0}}}; 
               f_pixel1 <= #pTCQ 48'd0; 
               f_pixel2 <= #pTCQ 48'd0; 
               f_pixel3 <= #pTCQ 48'd0; 
           end
           
           //f_pixel0 <= #pTCQ {f_vid_data[pBPC*3-1:pBPC*2],{(16-pBPC){1'b0}},  f_vid_data[pBPC*2-1:pBPC*1],{(16-pBPC){1'b0}},  f_vid_data[pBPC*1-1:pBPC*0],{(16-pBPC){1'b0}}}; 
           //f_pixel1 <= #pTCQ 48'd0; 
           //f_pixel2 <= #pTCQ 48'd0; 
           //f_pixel3 <= #pTCQ 48'd0; 
        end
        else
        begin
           f_pixel0 <= #pTCQ {f_vid_data[pBPC*3-1:pBPC*2],{(16-pBPC){1'b0}},  f_vid_data[pBPC*1-1:pBPC*0],{(16-pBPC){1'b0}},  f_vid_data[pBPC*2-1:pBPC*1],{(16-pBPC){1'b0}}}; 
           f_pixel1 <= #pTCQ {f_vid_data[pBPC*6-1:pBPC*5],{(16-pBPC){1'b0}},  f_vid_data[pBPC*4-1:pBPC*3],{(16-pBPC){1'b0}},   f_vid_data[pBPC*5-1:pBPC*4],{(16-pBPC){1'b0}}}; 
           f_pixel2 <= #pTCQ {f_vid_data[pBPC*9-1:pBPC*8],{(16-pBPC){1'b0}},  f_vid_data[pBPC*7-1:pBPC*6],{(16-pBPC){1'b0}},   f_vid_data[pBPC*8-1:pBPC*7],{(16-pBPC){1'b0}}}; 
           f_pixel3 <= #pTCQ {f_vid_data[pBPC*12-1:pBPC*11],{(16-pBPC){1'b0}},f_vid_data[pBPC*10-1:pBPC*9],{(16-pBPC){1'b0}}, f_vid_data[pBPC*11-1:pBPC*10],{(16-pBPC){1'b0}}};
        end
      end
      YUV422 : begin
        f_pixel0 <= #pTCQ {f_vid_data[(pBPC*2)-1:pBPC*1],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*1)-1:pBPC*0],{(32-pBPC){1'b0}}}; 
        f_pixel1 <= #pTCQ {f_vid_data[(pBPC*4)-1:pBPC*3],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*3)-1:pBPC*2],{(32-pBPC){1'b0}}}; 
        f_pixel2 <= #pTCQ {f_vid_data[(pBPC*6)-1:pBPC*5],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*5)-1:pBPC*4],{(32-pBPC){1'b0}}}; 
        f_pixel3 <= #pTCQ {f_vid_data[(pBPC*8)-1:pBPC*7],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*7)-1:pBPC*6],{(32-pBPC){1'b0}}}; 
      end
      Y_ONLY : begin
        f_pixel0 <= #pTCQ {f_vid_data[(pBPC*1)-1:pBPC*0],{(48-pBPC){1'b0}}}; 
        f_pixel1 <= #pTCQ {f_vid_data[(pBPC*2)-1:pBPC*1],{(48-pBPC){1'b0}}}; 
        f_pixel2 <= #pTCQ {f_vid_data[(pBPC*3)-1:pBPC*2],{(48-pBPC){1'b0}}}; 
        f_pixel3 <= #pTCQ {f_vid_data[(pBPC*4)-1:pBPC*3],{(48-pBPC){1'b0}}}; 
      end
      default : begin
        f_pixel0 <= #pTCQ {f_vid_data[(pBPC*3)-1:pBPC*2],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*2)-1:pBPC*1],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*1)-1:pBPC*0],{(16-pBPC){1'b0}}}; 
        f_pixel1 <= #pTCQ {f_vid_data[(pBPC*6)-1:pBPC*5],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*5)-1:pBPC*4],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*4)-1:pBPC*3],{(16-pBPC){1'b0}}}; 
        f_pixel2 <= #pTCQ {f_vid_data[(pBPC*9)-1:pBPC*8],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*8)-1:pBPC*7],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*7)-1:pBPC*6],{(16-pBPC){1'b0}}}; 
        f_pixel3 <= #pTCQ {f_vid_data[(pBPC*12)-1:pBPC*11],{(16-pBPC){1'b0}}, f_vid_data[(pBPC*11)-1:pBPC*10],{(16-pBPC){1'b0}}, f_vid_data[(pBPC*10)-1:pBPC*9],{(16-pBPC){1'b0}}}; 
      end
     endcase 
    f_vid_vsync_ph0        <= #pTCQ f_vid_vsync;
    f_vid_hsync_ph0        <= #pTCQ f_vid_hsync;
    f_vid_active_video_ph0 <= #pTCQ f_vid_active_video;
   end
   end
   else
   begin
    always @(posedge vid_io_out_clk)
    begin
      case(vid_format_vid_clk[1:0])
       RGB,YUV444 : begin
         f_pixel0 <= #pTCQ {f_vid_data[pBPC*3-1:pBPC*2],{(16-pBPC){1'b0}},  f_vid_data[pBPC*1-1:pBPC*0],{(16-pBPC){1'b0}},  f_vid_data[pBPC*2-1:pBPC*1],{(16-pBPC){1'b0}}}; 
         f_pixel1 <= #pTCQ {f_vid_data[pBPC*6-1:pBPC*5],{(16-pBPC){1'b0}},  f_vid_data[pBPC*4-1:pBPC*3],{(16-pBPC){1'b0}},   f_vid_data[pBPC*5-1:pBPC*4],{(16-pBPC){1'b0}}}; 
         f_pixel2 <= #pTCQ {f_vid_data[pBPC*9-1:pBPC*8],{(16-pBPC){1'b0}},  f_vid_data[pBPC*7-1:pBPC*6],{(16-pBPC){1'b0}},   f_vid_data[pBPC*8-1:pBPC*7],{(16-pBPC){1'b0}}}; 
         f_pixel3 <= #pTCQ {f_vid_data[pBPC*12-1:pBPC*11],{(16-pBPC){1'b0}},f_vid_data[pBPC*10-1:pBPC*9],{(16-pBPC){1'b0}}, f_vid_data[pBPC*11-1:pBPC*10],{(16-pBPC){1'b0}}}; 
       end
       default : begin
         f_pixel0 <= #pTCQ {f_vid_data[(pBPC*3)-1:pBPC*2],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*2)-1:pBPC*1],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*1)-1:pBPC*0],{(16-pBPC){1'b0}}}; 
         f_pixel1 <= #pTCQ {f_vid_data[(pBPC*6)-1:pBPC*5],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*5)-1:pBPC*4],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*4)-1:pBPC*3],{(16-pBPC){1'b0}}}; 
         f_pixel2 <= #pTCQ {f_vid_data[(pBPC*9)-1:pBPC*8],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*8)-1:pBPC*7],{(16-pBPC){1'b0}},   f_vid_data[(pBPC*7)-1:pBPC*6],{(16-pBPC){1'b0}}}; 
         f_pixel3 <= #pTCQ {f_vid_data[(pBPC*12)-1:pBPC*11],{(16-pBPC){1'b0}}, f_vid_data[(pBPC*11)-1:pBPC*10],{(16-pBPC){1'b0}}, f_vid_data[(pBPC*10)-1:pBPC*9],{(16-pBPC){1'b0}}}; 
       end
      endcase 
     f_vid_vsync_ph0        <= #pTCQ f_vid_vsync;
     f_vid_hsync_ph0        <= #pTCQ f_vid_hsync;
     f_vid_active_video_ph0 <= #pTCQ f_vid_active_video;
    end
   end
   endgenerate
// based on pixels per clock, some of the ports have to be commented
assign tx_vid_pixel0 = ((vid_format_vid_clk == 2'b00) || (vid_format_vid_clk == 2'b01)) ? {f_pixel0[47:(48-pBPC)],{(12-pBPC){1'b0}},f_pixel0[31:(32-pBPC)],{(12-pBPC){1'b0}},f_pixel0[15:(16-pBPC)],{(12-pBPC){1'b0}}} : ((vid_format_vid_clk == 2'b10) ? {f_pixel0[31:(32-pBPC)],{(12-pBPC){1'b0}},12'b0,f_pixel0[47:(48-pBPC)],{(12-pBPC){1'b0}}} : {f_pixel0[47:(48-pBPC)],{(36-pBPC){1'b0}}});
assign tx_vid_pixel1 = ((vid_format_vid_clk == 2'b00) || (vid_format_vid_clk == 2'b01)) ? {f_pixel1[47:(48-pBPC)],{(12-pBPC){1'b0}},f_pixel1[31:(32-pBPC)],{(12-pBPC){1'b0}},f_pixel1[15:(16-pBPC)],{(12-pBPC){1'b0}}} : ((vid_format_vid_clk == 2'b10) ? {f_pixel1[31:(32-pBPC)],{(12-pBPC){1'b0}},12'b0,f_pixel1[47:(48-pBPC)],{(12-pBPC){1'b0}}} : {f_pixel1[47:(48-pBPC)],{(36-pBPC){1'b0}}});
assign tx_vid_pixel2 = ((vid_format_vid_clk == 2'b00) || (vid_format_vid_clk == 2'b01)) ? {f_pixel2[47:(48-pBPC)],{(12-pBPC){1'b0}},f_pixel2[31:(32-pBPC)],{(12-pBPC){1'b0}},f_pixel2[15:(16-pBPC)],{(12-pBPC){1'b0}}} : ((vid_format_vid_clk == 2'b10) ? {f_pixel2[31:(32-pBPC)],{(12-pBPC){1'b0}},12'b0,f_pixel2[47:(48-pBPC)],{(12-pBPC){1'b0}}} : {f_pixel2[47:(48-pBPC)],{(36-pBPC){1'b0}}});
assign tx_vid_pixel3 = ((vid_format_vid_clk == 2'b00) || (vid_format_vid_clk == 2'b01)) ? {f_pixel3[47:(48-pBPC)],{(12-pBPC){1'b0}},f_pixel3[31:(32-pBPC)],{(12-pBPC){1'b0}},f_pixel3[15:(16-pBPC)],{(12-pBPC){1'b0}}} : ((vid_format_vid_clk == 2'b10) ? {f_pixel3[31:(32-pBPC)],{(12-pBPC){1'b0}},12'b0,f_pixel3[47:(48-pBPC)],{(12-pBPC){1'b0}}} : {f_pixel3[47:(48-pBPC)],{(36-pBPC){1'b0}}});
assign tx_vid_pixel4 = f_pixel4;
assign tx_vid_pixel5 = f_pixel5;
assign tx_vid_pixel6 = f_pixel6;
assign tx_vid_pixel7 = f_pixel7;

assign tx_vid_vsync = f_vid_vsync_ph0;
assign tx_vid_hsync = f_vid_hsync_ph0;
assign tx_vid_enable = f_vid_active_video_ph0;

assign tx_vid_clk = vid_io_out_clk;
assign tx_vid_reset = rst;
assign tx_odd_even = 1'b0;

endmodule 

 
 
 //   always @(posedge vid_io_out_clk)
//   begin
//     case({bits_per_colr,vid_format})  // these are stable; Add it XDC
//        {5'd8,Y_ONLY} : begin
//           f_pixel0 <= #pTCQ {f_vid_data[7:0],40'b0};
//           f_pixel1 <= #pTCQ {f_vid_data[pBPC*3+7:pBPC*3],40'b0};
//           f_pixel2 <= #pTCQ {f_vid_data[pBPC*6+7:pBPC*6],40'b0};
//           f_pixel3 <= #pTCQ {f_vid_data[pBPC*9+7:pBPC*9],40'b0};
//        end
//        {5'd10,Y_ONLY} : begin
//           f_pixel0 <= #pTCQ {f_vid_data[9:0],38'b0};
//           f_pixel1 <= #pTCQ {f_vid_data[pBPC*3+9:pBPC*3],38'b0};
//           f_pixel2 <= #pTCQ {f_vid_data[pBPC*6+9:pBPC*6],38'b0};
//           f_pixel3 <= #pTCQ {f_vid_data[pBPC*9+9:pBPC*9],38'b0};
//        end      
//        {5'd12,Y_ONLY} : begin
//           f_pixel0 <= #pTCQ {f_vid_data[11:0],36'b0};
//           f_pixel1 <= #pTCQ {f_vid_data[pBPC*3+11:pBPC*3],36'b0};
//           f_pixel2 <= #pTCQ {f_vid_data[pBPC*6+11:pBPC*6],36'b0};
//           f_pixel3 <= #pTCQ {f_vid_data[pBPC*9+11:pBPC*9],36'b0};
//        end           
//        {5'd16,Y_ONLY} : begin
//           f_pixel0 <= #pTCQ {f_vid_data[15:0],32'b0};
//           f_pixel1 <= #pTCQ {f_vid_data[pBPC*3+15:pBPC*3],32'b0};
//           f_pixel2 <= #pTCQ {f_vid_data[pBPC*6+15:pBPC*6],32'b0};
//           f_pixel3 <= #pTCQ {f_vid_data[pBPC*9+15:pBPC*9],32'b0};
//        end             
//
//        // 422 : Cr/Cb(bits 47:32) Y(Bits 31:16),16 zeros
//        {5'd8,YUV422} : begin
//            // Example for pBPC = 10; AXIS data width = 10*3*4 = 120
//            // On AXI4 Streaming                                         Native Video
//            // Pixel0          Cb/Cr : [17:10] Y : [7:0]                 Cb/Cr : [47:40]   Y : [31:24]
//            // Pixel1          Cb/Cr : [47:40] Y : [37:30]               Cb/Cr : [47:40]   Y : [31:24]
//            // Pixel2          Cb/Cr : [77:70] Y : [67:60]               Cb/Cr : [47:40]   Y : [31:24]
//            // Pixel2          Cb/Cr : [107:100] Y : [97:90]               Cb/Cr : [47:40]   Y : [31:24]
//
//           f_pixel0 <= #pTCQ {f_vid_data[pBPC*1+7 :pBPC*1] ,8'b0,f_vid_data[pBPC*0+7:pBPC*0+0],8'b0,16'b0}; 
//           f_pixel1 <= #pTCQ {f_vid_data[pBPC*4+7 :pBPC*4] ,8'b0,f_vid_data[pBPC*3+7:pBPC*3+0],8'b0,16'b0};
//           f_pixel2 <= #pTCQ {f_vid_data[pBPC*7+7 :pBPC*7] ,8'b0,f_vid_data[pBPC*6+7:pBPC*6+0],8'b0,16'b0};
//           f_pixel3 <= #pTCQ {f_vid_data[pBPC*10+7:pBPC*10],8'b0,f_vid_data[pBPC*9+7:pBPC*9+0],8'b0,16'b0};
//        end  
//        {5'd10,YUV422} : begin
//           f_pixel0 <= #pTCQ {f_vid_data[pBPC+9 :pBPC*1]   ,6'b0,f_vid_data[pBPC*0+9:pBPC*0+0],6'b0,16'b0}; 
//           f_pixel1 <= #pTCQ {f_vid_data[pBPC*4+9:pBPC*4]  ,6'b0,f_vid_data[pBPC*3+9:pBPC*3+0],6'b0,16'b0};
//           f_pixel2 <= #pTCQ {f_vid_data[pBPC*7+9:pBPC*7]  ,6'b0,f_vid_data[pBPC*6+9:pBPC*6+0],6'b0,16'b0};
//           f_pixel3 <= #pTCQ {f_vid_data[pBPC*10+9:pBPC*10],6'b0,f_vid_data[pBPC*9+9:pBPC*9+0],6'b0,16'b0};
//
//        end       
//        {5'd12,YUV422} : begin
//           f_pixel0 <= #pTCQ {f_vid_data[pBPC+11 :pBPC*1]   ,4'b0,f_vid_data[pBPC*0+11:pBPC*0+0],4'b0,16'b0}; 
//           f_pixel1 <= #pTCQ {f_vid_data[pBPC*4+11:pBPC*4]  ,4'b0,f_vid_data[pBPC*3+11:pBPC*3+0],4'b0,16'b0};
//           f_pixel2 <= #pTCQ {f_vid_data[pBPC*7+11:pBPC*7]  ,4'b0,f_vid_data[pBPC*6+11:pBPC*6+0],4'b0,16'b0};
//           f_pixel3 <= #pTCQ {f_vid_data[pBPC*10+11:pBPC*10],4'b0,f_vid_data[pBPC*9+11:pBPC*9+0],4'b0,16'b0};
//        end           
//        //generate
//        //if(pBPC=16) 
//        {5'd16,YUV422} : begin
//            // assert if pBPC < 16 
//           f_pixel0 <= #pTCQ {f_vid_data[pBPC+16 :pBPC*1]   ,f_vid_data[pBPC*0+16:pBPC*0+0],16'b0}; 
//           f_pixel1 <= #pTCQ {f_vid_data[pBPC*4+16:pBPC*4]  ,f_vid_data[pBPC*3+16:pBPC*3+0],16'b0};
//           f_pixel2 <= #pTCQ {f_vid_data[pBPC*7+16:pBPC*7]  ,f_vid_data[pBPC*6+16:pBPC*6+0],16'b0};
//           f_pixel3 <= #pTCQ {f_vid_data[pBPC*10+16:pBPC*10],f_vid_data[pBPC*9+16:pBPC*9+0],16'b0};
//        end         
//        //endgenerate
//        // RGB : R/Cr(47:32) G/Y (31:16) B/Cb (15:0) on DP side
//        // on AXI 4 S interface : R/Cr B/Cb G/Y 
//        {5'd8,RGB},{5'd8,YUV444} : begin   // 8BPC  
//           f_pixel0 <= #pTCQ {f_vid_data[pBPC*2+7:pBPC*2],8'b0,f_vid_data[pBPC*0+7:pBPC*0+0],8'b0,f_vid_data[pBPC*1+7:pBPC*1],8'b0}; 
//           f_pixel1 <= #pTCQ {f_vid_data[pBPC*5+7:pBPC*5],8'b0,f_vid_data[pBPC*3+7:pBPC*3+0],8'b0,f_vid_data[pBPC*4+7:pBPC*4],8'b0};
//           f_pixel2 <= #pTCQ {f_vid_data[pBPC*8+7:pBPC*8],8'b0,f_vid_data[pBPC*6+7:pBPC*6+0],8'b0,f_vid_data[pBPC*7+7:pBPC*7],8'b0};
//           f_pixel3 <= #pTCQ {f_vid_data[pBPC*11+7:pBPC*11],8'b0,f_vid_data[pBPC*9+7:pBPC*9+0],8'b0,f_vid_data[pBPC*10+7:pBPC*10],8'b0};
//        end   
//        {5'd10,RGB},{5'd10,YUV444} : begin// 10BPC
//           f_pixel0 <= #pTCQ {f_vid_data[pBPC*2+9:pBPC*2],6'b0,f_vid_data[pBPC*0+9:pBPC*0+0],6'b0,f_vid_data[pBPC*1+9:pBPC*1],6'b0}; 
//           f_pixel1 <= #pTCQ {f_vid_data[pBPC*5+9:pBPC*5],6'b0,f_vid_data[pBPC*3+9:pBPC*3+0],6'b0,f_vid_data[pBPC*4+9:pBPC*4],6'b0};
//           f_pixel2 <= #pTCQ {f_vid_data[pBPC*8+9:pBPC*8],6'b0,f_vid_data[pBPC*6+9:pBPC*6+0],6'b0,f_vid_data[pBPC*7+9:pBPC*7],6'b0};
//           f_pixel3 <= #pTCQ {f_vid_data[pBPC*11+9:pBPC*11],6'b0,f_vid_data[pBPC*9+9:pBPC*9+0],6'b0,f_vid_data[pBPC*10+9:pBPC*10],6'b0};
//        end      
//        {5'd12,RGB},{5'd12,YUV444} : begin// 12BPC
//           f_pixel0 <= #pTCQ {f_vid_data[pBPC*2+11:pBPC*2],4'b0,f_vid_data[pBPC*0+11:pBPC*0+0],4'b0,f_vid_data[pBPC*1+11:pBPC*1],4'b0}; 
//           f_pixel1 <= #pTCQ {f_vid_data[pBPC*5+11:pBPC*5],4'b0,f_vid_data[pBPC*3+11:pBPC*3+0],4'b0,f_vid_data[pBPC*4+11:pBPC*4],4'b0};
//           f_pixel2 <= #pTCQ {f_vid_data[pBPC*8+11:pBPC*8],4'b0,f_vid_data[pBPC*6+11:pBPC*6+0],4'b0,f_vid_data[pBPC*7+11:pBPC*7],4'b0};
//           f_pixel3 <= #pTCQ {f_vid_data[pBPC*11+11:pBPC*11],4'b0,f_vid_data[pBPC*9+11:pBPC*9+0],4'b0,f_vid_data[pBPC*10+11:pBPC*10],4'b0};
//        end           
//        {5'd16,RGB},{5'd16,YUV444} : begin // 16BPC
//           f_pixel0 <= #pTCQ {f_vid_data[pBPC*2+15:pBPC*2],f_vid_data[pBPC*0+15:pBPC*0+0],f_vid_data[pBPC*1+15:pBPC*1]}; 
//           f_pixel1 <= #pTCQ {f_vid_data[pBPC*5+15:pBPC*5],f_vid_data[pBPC*3+15:pBPC*3+0],f_vid_data[pBPC*4+15:pBPC*4]};
//           f_pixel2 <= #pTCQ {f_vid_data[pBPC*8+15:pBPC*8],f_vid_data[pBPC*6+15:pBPC*6+0],f_vid_data[pBPC*7+15:pBPC*7]};
//           f_pixel3 <= #pTCQ {f_vid_data[pBPC*11+15:pBPC*11],f_vid_data[pBPC*9+15:pBPC*9+0],f_vid_data[pBPC*10+15:pBPC*10]};
//        end  
//     endcase                           
     
//     f_pixel0 <= #pTCQ f_vid_data[1*bpp-1:0];
//     f_pixel1 <= #pTCQ f_vid_data[2*bpp-1:1*bpp];
//     f_pixel2 <= #pTCQ f_vid_data[3*bpp-1:2*bpp];
//     f_pixel3 <= #pTCQ f_vid_data[4*bpp-1:3*bpp];

//     f_vid_vsync_ph0        <= #pTCQ f_vid_vsync;
//     f_vid_hsync_ph0        <= #pTCQ f_vid_hsync;
//     f_vid_active_video_ph0 <= #pTCQ f_vid_active_video;
//   end

// instantiate the AXI4 to Video out IP
//v_axi4s_vid_out_bd_wrapper 
////# (
////     .C_video_in_DATA_WIDTH(16),
////     .C_video_in_FORMAT(),
////     .VID_OUT_DATA_WIDTH(192),
////     .C_video_in_TDATA_WIDTH(192),
////     .RAM_ADDR_BITS(10),
////     .HYSTERESIS_LEVEL(12), // default
////     .FILL_GUARDBAND(3),
////     .vtiming_in_MASTER_SLAVE(0)
////)
//
//v_axi4s_vid_out_v4_0_17_inst(
//// AXI4-streaming interface
//       .aclk                        (aclk),                // axi-4 S clock
//       .rst                         (rst),                 // general reset
//       .aclken                      (aclken),              // axi-4 clock enable
//       .aresetn                     (aresetn),             // axi-4 reset active low
//       .video_in_tdata              (video_in_tdata),  // axi-4 S data if width is less than actual, zeros are appended by tool
//       .video_in_tvalid             (video_in_tvalid), // axi-4 S valid 
//       .video_in_tready             (video_in_tready), // axi-4 S ready 
//       .video_in_tuser              (video_in_tuser),  // axi-4 S start of field
//       .video_in_tlast              (video_in_tlast),  // axi-4 S end of line
//       .fid                         ('b0),                 // Field ID, sampled on SOF
//  
//// video output interface
//       .vid_io_out_clk              (vid_io_out_clk),               // clock for video output
//       .vid_io_out_ce               (1'b1),               // video clock enable
//       .vid_io_out_active_video     (f_vid_active_video), // video data enable
//       .vid_io_out_vsync            (f_vid_vsync),        // video vertical sync
//       .vid_io_out_hsync            (f_vid_hsync),        // video horizontal sync
//       .vid_io_out_vblank           (/*NC*/),             // video vertical blank
//       .vid_io_out_hblank           (/*NC*/),             // video horizontal blank
//       .vid_io_out_field            (/*NC*/),             // video field ID
//       .vid_io_out_data             (f_vid_data),         // video data at DDR rate
//  
//// Register/VTG Interface
//       .vtiming_in_vsync            (vtiming_in_vsync),        // vsync from the video timing generator
//       .vtiming_in_hsync            (vtiming_in_hsync),
//       .vtiming_in_vblank           (vtiming_in_vblank),
//       .vtiming_in_hblank           (vtiming_in_hblank),
//       .vtiming_in_active_video     (vtiming_in_active_video),
//       .vtiming_in_field            (vtiming_in_field_id),
//       .vtg_ce                      (vtg_ce),
//  // output status bits
//       .locked                      (locked),
//       .wr_error                    (wr_error),
//       .empty                       (/*NC*/)
//);



