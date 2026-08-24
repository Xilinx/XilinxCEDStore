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
// Project    : Accelerator System Design
// File       : axil_responder.sv
// Version    : 5.0
// Description: This module generates ready/valid response signals for register interface connected to AXIL interface
//-----------------------------------------------------------------------------

`timescale 1ps / 1ps

module axil_responder (

  input  logic          axil_aclk,
  input  logic          axil_aresetn,
  output logic          axil_awready,
  input  logic          axil_awvalid,
  input	 logic [31:0]	axil_awaddr_i,
  output logic          axil_arready,
  input  logic          axil_arvalid,
  input	 logic [31:0]	axil_araddr_i,
  output logic          axil_wready,
  input  logic          axil_wvalid,
  output logic  [1:0]   axil_rresp,
  input  logic          axil_rready,
  output logic          axil_rvalid,
  output logic  [1:0]   axil_bresp,
  input  logic          axil_bready,
  output logic          axil_bvalid,
  
  output logic [31:0]	axil_awaddr_o,
  output logic [31:0]	axil_araddr_o

);

  logic          wr_req;
  logic          rd_req;
  logic          reset_released;
  logic          reset_released_r;  



   //******************************************************************************
  //A write address phase is accepted only when there is no pending read or
  //write transactions. when both read and write transactions occur on the
  //same clock read transaction will get the highest priority and processed
  //first. write transaction will not be accepted until the read transaction
  //is completed. 
  //******************************************************************************



  assign axil_awready = ((~wr_req) && (!(rd_req || axil_arvalid))) && reset_released_r;
  
  assign axil_bresp = 2'b00;
  
  assign axil_rresp = 2'b00;

  assign axil_wready = wr_req && ~axil_bvalid;

  assign axil_arready = ~rd_req && ~wr_req && reset_released_r;
  


//******************************************************************************
  //According to xilinx guide lines after reset the AWREADY and ARREADY siganls
  //should be low atleast for one clock cycle. To achieve this a signal 
  //reset_released is taken and anded with axil_awready and axil_arready signals,
  //so that the output will show a logic '0' when in reset

  //******************************************************************************



  always @(posedge axil_aclk)
  begin
      if(~axil_aresetn) begin
          reset_released   <= 1'b0;
          reset_released_r <= 1'b0;
      end else begin
          reset_released   <= 1'b1;
          reset_released_r <= reset_released;
      end
  end
  
  

  //******************************************************************************

  //AXI Lite trasaction decoding and address latching logic. 
  //when axil_a*valid signal is asserted by the master the address is latched 
  //and wr_req or rd_req signal is asserted until data phase is completed 

  //******************************************************************************



  always @(posedge axil_aclk)
  begin
      if(~axil_aresetn)begin
          wr_req <= 1'b0;
      end else begin
          if(axil_awvalid && axil_awready) begin
              wr_req 		<= 1'b1;
			  axil_awaddr_o <= axil_awaddr_i;
          end else if (axil_bvalid && axil_bready) begin
              wr_req <= 1'b0;
          end else begin
              wr_req <= wr_req;
          end
      end
  end 
  
  always @(posedge axil_aclk)
  begin
      if(~axil_aresetn)begin
          rd_req <= 1'b0;
      end else begin
          if(axil_arvalid && axil_arready) begin
              rd_req 		<= 1'b1;
			  axil_araddr_o <= axil_araddr_i;
          end else if (axil_rvalid && axil_rready) begin
              rd_req <= 1'b0;
          end else begin
              rd_req <= rd_req;
          end
      end
  end 

   //********************************************************************************
   
  //write response channel logic. 
  //This logic will generate BVALID signal for the write transaction. 

  //********************************************************************************



  always @(posedge axil_aclk)
  begin
      if(~axil_aresetn) begin
          axil_bvalid <= 1'b0;
      end else begin
          if(wr_req && axil_wvalid && ~axil_bvalid) begin
              axil_bvalid <= 1'b1;
          end else if(axil_bready) begin
              axil_bvalid <= 1'b0;
          end else begin
              axil_bvalid <= axil_bvalid;
          end
      end
  end 
  
  //******************************************************************************

  //AXI Lite read trasaction processing logic. 

  //******************************************************************************

  always @(posedge axil_aclk)
  begin
      if(~axil_aresetn)
          axil_rvalid <= 1'b0;
      else begin
          if(rd_req) 
			begin
              if(axil_rvalid && axil_rready) 
                  axil_rvalid <= 1'b0;
              else 
                  axil_rvalid <= 1'b1;
            end
		end
	end	

endmodule