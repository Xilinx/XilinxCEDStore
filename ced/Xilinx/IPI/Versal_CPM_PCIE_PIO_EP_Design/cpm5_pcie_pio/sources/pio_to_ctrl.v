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
// File       : pio_to_ctrl.v
// Version    : 1.0 
//-----------------------------------------------------------------------------
//
// Description: Turn-off Control Unit.
//
//--------------------------------------------------------------------------------

`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module pio_to_ctrl #(
  parameter TCQ = 1
 )(

  input      clk,
  input      rst_n,

  input      req_compl,
  input      compl_done,

  input      cfg_power_state_change_interrupt,
  output reg cfg_power_state_change_ack
  );

  reg                 trn_pending;

  //  Check if completion is pending

  always @ (posedge clk)
  begin
    if (!rst_n ) begin
      trn_pending <= #TCQ 1'b0;
    end else begin
      if (!trn_pending && req_compl)
        trn_pending <= #TCQ 1'b1;
      else if (compl_done)
        trn_pending <= #TCQ 1'b0;
    end
  end


  //  Turn-off OK if requested and no transaction is pending


  always @ (posedge clk)
  begin
    if (!rst_n ) begin
      cfg_power_state_change_ack <= 1'b0;
    end else begin
      if ( cfg_power_state_change_interrupt  && !trn_pending)
        cfg_power_state_change_ack <= 1'b1;
      else
        cfg_power_state_change_ack <= 1'b0;
    end
  end


endmodule // pio_to_ctrl
