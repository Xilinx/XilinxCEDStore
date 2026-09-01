////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
////////////////////////////////////////////////////////////////////////

module saxil_elbi_registers # (
   parameter  AXIL_ADDR_WIDTH    = 32,
   parameter  AXIL_DATA_WIDTH    = 32
) (
   input           aclk
  ,input           aresetn
  
  /* AXI4-Lite Slave */
  ,input [AXIL_ADDR_WIDTH-1:0]    araddr   //AXI-Lite
  ,input [2:0]     arprot   //AXI-Lite      // unused
  ,input           arvalid  //AXI-Lite
  ,output          arready  //AXI-Lite

  ,output [AXIL_DATA_WIDTH-1:0]   rdata    //AXI-Lite
  ,input           rready   //AXI-Lite
  ,output [1:0]    rresp    //AXI-Lite
  ,output          rvalid   //AXI-Lite

  ,input [AXIL_ADDR_WIDTH-1:0]    awaddr   //AXI-Lite
  ,input [2:0]     awprot   //AXI-Lite      // unused
  ,input           awvalid  //AXI-Lite
  ,output          awready  //AXI-Lite

  ,input [AXIL_DATA_WIDTH-1:0]    wdata    //AXI-Lite
  ,output          wready   //AXI-Lite
  ,input [(AXIL_DATA_WIDTH/8)-1:0]     wstrb    //AXI-Lite
  ,input           wvalid   //AXI-Lite

  ,input           bready   //AXI-Lite
  ,output [1:0]    bresp    //AXI-Lite
  ,output          bvalid   //AXI-Lite

  ,output logic    o_int_override_en        // To give control to the user to override the ack 
  ,output logic    o_ack_ovrd               // To send an ack when override_en is set high
  ,output logic    o_en_elbi_override_en    // To enable override via tha elbi override en pin
);


  localparam W_ADDR = 3'd0, R_ADDR = 2'd0,
             W_PAUS = 3'd1, R_PAUS = 2'd1,
             W_DATA = 3'd2, R_WAIT = 2'd2,
             W_WAIT = 3'd3, R_RESP = 2'd3,
             W_RESP = 3'd4;

  localparam INT_OVERRIDE_EN_OFFSET          = 'h0000_0000;
  localparam ACK_OVRD_OFFSET                 = 'h0000_0004;
  localparam EN_ELBI_OVERRIDE_EN_OFFSET      = 'h0000_0008;

  reg [ 1:0] i_bresp;
  reg [ 1:0] i_rresp;

  reg [ 2:0] w_st;
  reg [ 1:0] r_st;

  reg [AXIL_ADDR_WIDTH-1:0] save_awaddr;
  reg [AXIL_ADDR_WIDTH-1:0] save_araddr;
  reg [AXIL_DATA_WIDTH-1:0] save_rdata;

  // logic       timeout_det;
  // logic [9:0] timeout;
  // logic       timeout_go;
  // logic       timeout_start;

  /* Tie offs */
  assign bresp = i_bresp;
  assign rresp = i_rresp;

  /* Writes */
  logic wr_int_override_en_vld;
  logic wr_ack_ovrd_vld;
  logic wr_en_elbi_override_en_vld;

  assign wr_int_override_en_vld      = (save_awaddr[AXIL_ADDR_WIDTH-1:0] == INT_OVERRIDE_EN_OFFSET      );
  assign wr_ack_ovrd_vld             = (save_awaddr[AXIL_ADDR_WIDTH-1:0] == ACK_OVRD_OFFSET             );
  assign wr_en_elbi_override_en_vld  = (save_awaddr[AXIL_ADDR_WIDTH-1:0] == EN_ELBI_OVERRIDE_EN_OFFSET  );

  /* Reads */
  logic rd_en_elbi_override_en_vld;
  logic rd_ack_ovrd_vld;
  logic rd_int_override_en_vld;

  assign rd_en_elbi_override_en_vld = (save_araddr[AXIL_ADDR_WIDTH-1:0] == INT_OVERRIDE_EN_OFFSET      );
  assign rd_ack_ovrd_vld            = (save_araddr[AXIL_ADDR_WIDTH-1:0] == ACK_OVRD_OFFSET             );
  assign rd_int_override_en_vld     = (save_araddr[AXIL_ADDR_WIDTH-1:0] == EN_ELBI_OVERRIDE_EN_OFFSET  );

  logic int_override_en;
  logic ack_ovrd;
  logic en_elbi_override_en;

  /* Timeout Counter for W_PAUS State */
  // assign timeout_det   = (timeout == '1);
  // assign timeout_start = (w_st==W_ADDR & awvalid && awready) ||
                         // (w_st==W_DATA && wvalid && wready) ||
                         // (r_st==R_ADDR && arvalid && arready) ||
                         // (r_st==R_PAUS);

  // always @(posedge aclk) begin
    // if (!aresetn) begin
      // timeout    <= '0;
      // timeout_go <= 1'b0;
    // end
    // else begin

      // if (timeout_start)
        // timeout_go <= 1'b1;
      // else if ((w_st==W_DATA) || (w_st==W_RESP) || (r_st==R_RESP))
        // timeout_go <= 1'b0;

      // if (timeout_start)
        // timeout <= '0;
      // else if (timeout_go)
        // timeout <= timeout + 1'b1;
    // end
  // end

   /* Write FSM */
   always @(posedge aclk) begin
      if (!aresetn) begin
         w_st           <= W_ADDR;
         i_bresp        <= 2'h0;
         int_override_en <= 1'b0;
         ack_ovrd <= 1'b0;
         en_elbi_override_en <= 1'b0;
      end
      else begin
         case (w_st)
            W_ADDR : if (awvalid && awready) begin
                        w_st        <= W_DATA;
                        save_awaddr <= awaddr;
                     end
            W_DATA : if (wvalid && wready) begin
                        w_st    <= W_RESP;
                        case (1'b1)
                           wr_int_override_en_vld     : int_override_en     <= wdata;
                           wr_ack_ovrd_vld            : ack_ovrd            <= wdata;
                           wr_en_elbi_override_en_vld : en_elbi_override_en <= wdata;
                           /*default : writes to reserved silently discarded*/
                        endcase
                     end
            W_RESP : if (bvalid && bready) begin
                        w_st    <= W_ADDR;
                        i_bresp <= 2'h0;
                     end
         endcase
      end
   end


   assign awready = (w_st == W_ADDR);
   assign  wready = (w_st == W_DATA);
   assign  bvalid = (w_st == W_RESP);

   /* Read FSM */
   always @(posedge aclk) begin
      if (!aresetn) begin
         r_st           <= R_ADDR;
         i_rresp        <= 2'h0;
      end
      else begin
         case (r_st)
            R_ADDR : 
               if (arvalid && arready) begin
                  r_st        <= R_PAUS;
                  save_araddr <= araddr;
               end
            R_PAUS : // if (i_rvld)
               begin
                  r_st <= R_RESP;
                  save_rdata <= '0; //default all 0's first
                  case (1'b1)
                     rd_int_override_en_vld     : save_rdata <= int_override_en;
                     rd_ack_ovrd_vld            : save_rdata <= ack_ovrd;
                     rd_en_elbi_override_en_vld : save_rdata <= en_elbi_override_en;
                  endcase
               end
            R_RESP : 
               if (rvalid && rready) begin
                  r_st    <= R_ADDR;
                  i_rresp <= 2'h0;
               end
         endcase
      end
   end

   assign arready = (r_st == R_ADDR);
   assign rvalid  = (r_st == R_RESP);
   assign rdata   = save_rdata;
   
   assign o_int_override_en = int_override_en;
   assign o_ack_ovrd = ack_ovrd;
   assign o_en_elbi_override_en = en_elbi_override_en;

endmodule : saxil_elbi_registers
