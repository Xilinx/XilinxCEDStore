// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////

//
// Project    : Versal PCI Express Integrated Block
// File       : pio_intr_ctrl.v
// Version    : 1.0 
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//
// Project    : Ultrascale FPGA Gen4 Integrated Block for PCI Express
// File       : pio_intr_ctrl.v
// Version    : 1.0 
//-----------------------------------------------------------------------------
//
// Description: Interrupt controller block to trigger the cfg_interrupt pins
//
//--------------------------------------------------------------------------------


`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module pio_intr_ctrl#(
       parameter        TCQ = 1
)(

  input             user_clk,      // User Clock
  input             reset_n,  // User Reset

  // Trigger to generate interrupts (to / from Mem access Block)

  input             gen_leg_intr,    // Generate Legacy Interrupts
  input             gen_msi_intr,    // Generate MSI Interrupts
  input             gen_msix_intr,   // Generate MSI-X Interrupts
  output reg        interrupt_done,  // Indicates whether interrupt is done or in process

  // Legacy Interrupt Interface

  input             cfg_interrupt_sent, // Core asserts this signal when it sends out a Legacy interrupt
  output reg [3:0]  cfg_interrupt_int,  // 4 Bits for INTA, INTB, INTC, INTD (assert or deassert)

  // MSI Interrupt Interface

  input             cfg_interrupt_msi_enable,
  input             cfg_interrupt_msi_sent,
  input             cfg_interrupt_msi_fail,

  output reg [31:0] cfg_interrupt_msi_int,

  //MSI-X Interrupt Interface

  input             cfg_interrupt_msix_enable,
  input             cfg_interrupt_msix_sent,
  input             cfg_interrupt_msix_fail,

  output reg        cfg_interrupt_msix_int,
  output reg [63:0] cfg_interrupt_msix_address,
  output reg [31:0] cfg_interrupt_msix_data

  );

  always @ (posedge user_clk)
  begin
    if(!reset_n) begin

      cfg_interrupt_msi_int     <= #TCQ 32'b0;
	  cfg_interrupt_msix_int	<= #TCQ 1'b0;
      cfg_interrupt_msix_address<= #TCQ 64'b0;
	  cfg_interrupt_msix_data   <= #TCQ 32'b0;
	  cfg_interrupt_int         <= #TCQ 4'b0;
      interrupt_done            <= #TCQ 1'b0;

    end
	else begin

	  case ({gen_leg_intr, gen_msi_intr, gen_msix_intr})

	    3'b100 : begin // Generate LEgacy interrupt

	      if(cfg_interrupt_int == 4'h0) begin
	        cfg_interrupt_int <= #TCQ 4'h1;
	      end
	      else
	        cfg_interrupt_int <= #TCQ 4'h0;

	    end //  Generate LEgacy interrupt


	    3'b010 : begin // Generate MSI Interrupt

          if(cfg_interrupt_msi_enable)
	        //cfg_interrupt_msi_int     <= #TCQ 32'hAAAA_AAAA;
	        cfg_interrupt_msi_int     <= #TCQ 32'h0000_0001;
	      else
	        cfg_interrupt_msi_int     <= #TCQ 32'b0;

	    end

	    3'b001 : begin // Generate MSI-X Interrupt

          if (cfg_interrupt_msix_enable) begin
	        cfg_interrupt_msix_int	  <= #TCQ 1'b1;
            cfg_interrupt_msix_address<= #TCQ 64'hAAAA_BBBB_CCCC_DDDD;
	        cfg_interrupt_msix_data   <= #TCQ 32'hDEAD_BEEF;
          end
	      else begin
	        cfg_interrupt_msix_int	  <= #TCQ 1'b0;
            cfg_interrupt_msix_address<= #TCQ 64'b0;
	        cfg_interrupt_msix_data   <= #TCQ 32'b0;
	      end
	    end  // Generate MSI-X Interrupt

		default : begin

          cfg_interrupt_msi_int     <= #TCQ 32'b0;
	      cfg_interrupt_msix_int	<= #TCQ 1'b0;
          cfg_interrupt_msix_address<= #TCQ 64'b0;
	      cfg_interrupt_msix_data   <= #TCQ 32'b0;
	      cfg_interrupt_int         <= #TCQ 4'b0;

        end

	  endcase

	  if((cfg_interrupt_int != 4'h0) ||
		 ((cfg_interrupt_msi_enable) && (cfg_interrupt_msi_sent || cfg_interrupt_msi_fail)) ||
		 ((cfg_interrupt_msix_enable) && (cfg_interrupt_msix_sent || cfg_interrupt_msix_fail)))

	    interrupt_done <= #TCQ 1'b1;
	  else
		interrupt_done <= #TCQ 1'b0;

    end // end of resetelse block
  end

endmodule


