//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : UltraScale+ FPGA PCI Express v4.0 Integrated Block
// File       : BMD_AXIST_INTR_CTRL.v
// Version    : 1.3 
//-----------------------------------------------------------------------------
//----------------------------------------------------------------------------//
//
//
// Project    : Virtex-7 FPGA Gen3 Integrated Block for PCI Express
// File       : BMD_AXIST_INTR_CTRL.v
// Version    : 1.1
//
// Description: Interrupt controller block to trigger the cfg_interrupt pins
//
//--------------------------------------------------------------------------------

`include "pcie_app_uscale_bmd_1024.vh"
`timescale 1ps/1ps
//`include "validation_defines.vh"
(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_INTR_CTRL#(
       parameter        TCQ = 1
)(

  input             user_clk,      // User Clock
  input             reset_n,  // User Reset
  input             mwr_done_i,
  input             mrd_done_i,

  ////// Trigger to generate interrupts (to / from Mem access Block)

  ////input             send_leg_intr,    // Generate Legacy Interrupts
  ////input             send_msi_intr,    // Generate MSI Interrupts
  ////input             gen_msix_intr,   // Generate MSI-X Interrupts
  ////output reg        interrupt_done,  // Indicates whether interrupt is done or in process

  // Legacy Interrupt Interface

  ////input             cfg_interrupt_sent, // Core asserts this signal when it sends out a Legacy interrupt
  ////output reg [3:0]  cfg_interrupt_int,  // 4 Bits for INTA, INTB, INTC, INTD (assert or deassert)


  // MSI Interrupt Interface
  (*mark_debug*) input       [3:0]               cfg_interrupt_msi_enable,
  (*mark_debug*) input                           cfg_interrupt_msi_sent,
  (*mark_debug*) input                           cfg_interrupt_msi_fail,
  (*mark_debug*) output reg  [31:0]              cfg_interrupt_msi_int,
  (*mark_debug*) output reg  [7:0]               cfg_interrupt_msi_function_number,
  (*mark_debug*) output reg  [1:0]               cfg_interrupt_msi_select,

  //MSI-X Interrupt Interface
  (*mark_debug*) input        [3:0]              cfg_interrupt_msix_enable,
  (*mark_debug*) input        [3:0]              cfg_interrupt_msix_mask,
  (*mark_debug*) input        [251:0]            cfg_interrupt_msix_vf_mask,
  (*mark_debug*) input        [251:0]            cfg_interrupt_msix_vf_enable,
  (*mark_debug*) input                           cfg_interrupt_msix_vec_pending_status,
  (*mark_debug*) output reg                      cfg_interrupt_msix_int,
  (*mark_debug*) output reg   [1:0]              cfg_interrupt_msix_vec_pending,

  // Legacy Interrupt Interface
  (*mark_debug*) input                           cfg_interrupt_sent, // Core asserts this signal when it sends out a Legacy interrupt
  (*mark_debug*) output reg   [3:0]              cfg_interrupt_int,  // 4 Bits for INTA, INTB, INTC, INTD (assert or deassert)
  (*mark_debug*) output reg                      interrupt_done,  // Indicates whether interrupt is done or in process
  (*mark_debug*) output reg   [3:0]              cfg_interrupt_pending // For Legacy interrupts

  );
  
  // Detect the rd_done and wr_done transition
  (*mark_debug*) wire rd_done_edge, wr_done_edge;
  (*mark_debug*) reg r_rd_done_edge, r_wr_done_edge;
  (*mark_debug*) reg r_keep = 1'b1; //deassertion of r_keep allows request to trigger new interrupt
  (*mark_debug*) reg r_rd_done, r_wr_done;
  (*mark_debug*) reg [3:0] counter; // state for debug
  
  // Capture rd_done and wr_done positive-to-negative transition
  always @ (posedge user_clk)
  begin
    if (!reset_n) begin
      r_rd_done <=  #TCQ 1'b0;
      r_wr_done <= #TCQ 1'b0;
      r_wr_done_edge <= #TCQ 1'b0;
      r_rd_done_edge <= #TCQ 1'b0;
    end
    else begin
      r_rd_done <= #TCQ mrd_done_i;
      r_wr_done <= #TCQ mwr_done_i; 
      
      if (mwr_done_i & (~r_wr_done)) begin
        r_wr_done_edge <= #TCQ 1'b1;
      end
      else begin
        r_wr_done_edge <= #TCQ r_keep & r_wr_done_edge;
      end
      if (mrd_done_i & (~r_rd_done)) begin
        r_rd_done_edge <= #TCQ 1'b1;
      end
      else begin
        r_rd_done_edge <= #TCQ r_keep & r_rd_done_edge;
      end
    end
  end
  
  assign wr_done_edge = r_wr_done_edge;
  assign rd_done_edge = r_rd_done_edge;

  // Initiate interrupt request
  always @ (posedge user_clk)
  begin
    if(!reset_n) begin
      interrupt_done            <= #TCQ 1'b0;
      cfg_interrupt_int         <= #TCQ 4'b0;
      cfg_interrupt_pending     <= #TCQ 4'b0; 
      cfg_interrupt_msi_int     <= #TCQ 32'b0;
      cfg_interrupt_msi_function_number  <= #TCQ 8'b0;
      cfg_interrupt_msi_select  <= #TCQ 2'b0; 
      cfg_interrupt_msix_int    <= #TCQ 1'b0;
      cfg_interrupt_msix_vec_pending <= #TCQ 2'b0;
      r_keep <=  #TCQ 1'b1;
      counter <= #TCQ 4'b0;
    end
    else begin
    
`ifdef MSI

      // MSI
      if (cfg_interrupt_msi_enable == 4'h1) begin
        if ( cfg_interrupt_msi_int == 32'h0 ) begin // make sure there is no outgoing intterrupt
          cfg_interrupt_msi_function_number <= #TCQ 8'b0;
          cfg_interrupt_msi_select <= #TCQ 2'b0;
          r_keep <= 1'b1;
          if (rd_done_edge && wr_done_edge && r_keep) begin // initiate interrupt
            cfg_interrupt_msi_int <= #TCQ 32'h0000_0001; 
            counter <= #TCQ 4'b001;
          end
          else begin // wait for triggering event to happen
            cfg_interrupt_msi_int <= #TCQ cfg_interrupt_msi_int; 
            counter <= #TCQ 4'b010;
          end
        end  // end of cfj_interrupt_msi_int == 0
        else begin
          if (cfg_interrupt_msi_fail && r_keep) begin // error
            cfg_interrupt_msi_int <= #TCQ cfg_interrupt_msi_int;
            r_keep <= #TCQ 1'b1;
            counter <= #TCQ 4'b011;
          end 
          else if (cfg_interrupt_msi_sent && r_keep) begin // interrupt has been issued
            cfg_interrupt_msi_int <= #TCQ 32'h0;
            r_keep <= #TCQ 1'b0;
            counter <= #TCQ 4'b100;
          end
          else begin // wait until interrupt is fired
            cfg_interrupt_msi_int <= #TCQ cfg_interrupt_msi_int;
            r_keep <= #TCQ r_keep;
            counter <= #TCQ 4'b101;
          end
        end //if cfg_interrupt_msi_int
      end // if cfg_interrupt_msi_enable
    else begin // Legacy
`endif
`ifdef MSIX
  // MSI-X
  // Only support single PF, single VF, Internal MSIX Vector Table
  // The MSI-X Vector Table is evenly shared among all VFs belong to 
  // the same PF.
  
    if (cfg_interrupt_msix_enable == 4'h1) begin
	 
      if (cfg_interrupt_msi_int == 32'h0) begin  // make sure there is no outgoing intterrupt
        cfg_interrupt_msi_function_number <= #TCQ 8'h0;
        r_keep <= #TCQ 1'b1;
        if (rd_done_edge && wr_done_edge && r_keep) begin // initiate interrupt
          cfg_interrupt_msi_int <= #TCQ 32'h0000_0001; 
          cfg_interrupt_msix_int <= #TCQ 1'b1;
          cfg_interrupt_msix_vec_pending <= #TCQ 2'b00;
          counter <= #TCQ 4'b1;
        end
        else begin // wait for triggering event to happen
          cfg_interrupt_msi_int <= #TCQ cfg_interrupt_msi_int; 
          cfg_interrupt_msix_int <= #TCQ cfg_interrupt_msix_int;
          counter <= #TCQ 4'b10;
        end  
      end else begin
        if (cfg_interrupt_msi_fail && r_keep) begin // error
          cfg_interrupt_msi_int <= #TCQ cfg_interrupt_msi_int;
          cfg_interrupt_msix_int <= #TCQ 1'b1;
          cfg_interrupt_msix_vec_pending <= #TCQ 2'b00;
          r_keep <=  #TCQ 1'b1;
          counter <= #TCQ 4'b11;
        end
        else begin       
          if (cfg_interrupt_msi_sent) begin  // interrupt has been issued
            cfg_interrupt_msi_int <= #TCQ 32'h0000_0000;
            cfg_interrupt_msix_int <= #TCQ 1'b0;
            r_keep <= #TCQ 1'b0;
            counter <= #TCQ 4'b100;
          end
          else begin // wait until interrupt is fired
            cfg_interrupt_msi_int <= #TCQ cfg_interrupt_msi_int;
            cfg_interrupt_msix_int <= #TCQ cfg_interrupt_msix_int;
            r_keep <= #TCQ r_keep;
            counter <= #TCQ counter;
          end
        end 
      end // end else begin
    end // cfg_interrupt_msix_enable
    else begin // Legacy
`endif
  //else begin // Legacy
    if (cfg_interrupt_int == 4'b0 && cfg_interrupt_pending==4'b0) begin // no outgoing interrupt
      r_keep <= #TCQ 1'b1; 
      if (rd_done_edge && wr_done_edge && r_keep) begin 
        cfg_interrupt_int <= #TCQ 4'b0001; 
        cfg_interrupt_pending <= #TCQ 4'b1;
        counter <= #TCQ 4'b110;
      end
      else begin // wait for event to happen
        cfg_interrupt_int <= #TCQ cfg_interrupt_int; 
        cfg_interrupt_pending <= #TCQ cfg_interrupt_pending;
        counter <= #TCQ 4'b111;
      end
    end
    else if (cfg_interrupt_int != 4'b0 && cfg_interrupt_pending!=4'b0) begin // has unresolved interrupt
      if (cfg_interrupt_sent) begin // first cfg_interrupt_sent assertion: interrupt request is received by PCIE
        cfg_interrupt_int <= #TCQ 4'h0;
        cfg_interrupt_pending <= #TCQ 1'b1;
        r_keep <= #TCQ r_keep;
        counter <= #TCQ 4'b1000;
      end
      else begin // wait for the second assertion
        cfg_interrupt_int <= #TCQ cfg_interrupt_int;
        cfg_interrupt_pending <= #TCQ cfg_interrupt_pending;
        r_keep <= #TCQ r_keep; 
        counter <= #TCQ 4'b1001;
      end
    end
    else if  (cfg_interrupt_int == 4'b0 && cfg_interrupt_pending!=4'b0) begin 
      if (cfg_interrupt_sent) begin // interrupt has been sent to the host
        cfg_interrupt_int <= #TCQ 4'h0;
        cfg_interrupt_pending <= #TCQ 1'b0;
        r_keep <= #TCQ 1'b0;
        counter <= #TCQ 4'b1010;
      end
      else begin // pending interrupt has not been resolved yet
        cfg_interrupt_int <= #TCQ cfg_interrupt_int;
        cfg_interrupt_pending <= #TCQ cfg_interrupt_pending;
        r_keep <= #TCQ r_keep; 
        counter <= #TCQ 4'b1011;
      end        
    end
    else begin // Invalid state
        cfg_interrupt_int <= #TCQ cfg_interrupt_int;
        cfg_interrupt_pending <= #TCQ cfg_interrupt_pending;
        r_keep <= #TCQ r_keep; 
        counter <= #TCQ 4'b1100;    
    end
`ifdef MSIX
  end // legacy
`else
`ifdef MSI
  end // legacy
`endif
`endif
end // reset
end // always
 
/*

    wire         capture_clock;
    
    wire [255:0] capture_data;
    
    wire [ 15:0] capture_trigger;
    

    assign capture_data={
    cfg_interrupt_msi_sent,
    cfg_interrupt_msi_int,
    cfg_interrupt_msi_enable,
    send_msi_intr,
    mwr_done_i,
    mrd_done_i

}
    ;
    
    assign capture_trigger={
    cfg_interrupt_msi_sent,
    send_msi_intr,
    mwr_done_i,
    mrd_done_i
    
    };
    
    
    //`define CHIPSCOPE 1
    //`ifdef CHIPSCOPE
    
    wire [35:0] CONTROL0;
    
    chipscope_icon icon_i (
    
    .CONTROL0(CONTROL0) // INOUT BUS [35:0]
    
    );
    
    
    
    chipscope_ila ila_i (

    .CONTROL(CONTROL0), // INOUT BUS [35:0]
    
    .CLK(user_clk), // IN

    .DATA(capture_data), // IN BUS [255:0]
    
    .TRIG0(capture_trigger) // IN BUS [15:0]
    );
    */

   
endmodule
