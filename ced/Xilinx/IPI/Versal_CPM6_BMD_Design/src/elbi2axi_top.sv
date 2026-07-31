//-----------------------------------------------------------------------------
//
// (c) Copyright 1995, 2007, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
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
//
//-----------------------------------------------------------------------------
//
// Project    : CPM6
// File       : elbi2axi_top.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

// cpm6_interface.svh (compiled as part of CPM6 IP) provides:
//   pcie6_elbi_pl_if, axil_intf_defs_cpm6, and all other CPM6 interfaces

/////////////////////////////////////////////////////////////////////////////
`ifndef XPREG
`define XPREG(clk, reset_n, q,d,rstval)          \
    always @(posedge clk)                        \
    begin                                        \
     if (reset_n == 1'b0)                        \
         q <= #(TCQ) rstval;                     \
     else                                        \
         q <= #(TCQ)  d;                         \
     end
`endif
/////////////////////////////////////////////////////////////////////////////

module elbi2axi_top # (
    parameter TCQ         = 0
   ,parameter TIMEOUT     = 1024
   ,parameter AXIL_ADDR_WIDTH    = 64
   ,parameter AXIL_DATA_WIDTH    = 64
   ,parameter AXIL_AXUSER_WIDTH  = 8
   // Parameters related to BAR NUM, and other destination
) (
   input                           elbi2axil_clk   // PL AXIMM Clock
  ,input                           elbi2axil_rstn  // PL AXIMM Reset

  ,axil_intf_defs_cpm6.slave           pl_axil_regs_if  // AXI-L interface for registers
  ,pcie6_elbi_pl_if.s                  pl_pcie1_elbi_if // ELBI Interface
  ,axil_intf_defs_cpm6.master          pl_elbi_axil_if  // AXI-L Interface
);

  // for AXI responses
  localparam RESP_SUCCESS = 2'b00;
  localparam RESP_EXOKAY = 2'b01;   // Not used
  localparam RESP_SLVERR = 2'b10;   // Not used
  localparam RESP_DECERR = 2'b11;   // Not used

   typedef enum {
      IDLE,
      W_WAIT,
      R_WAIT,
      W_RESP,
      R_RESP
   } state_e;

state_e w_st, next_w_st;

// for watchdog timer
logic [7:0] cntr;
logic start_timeout_cntr, cntr_timeout;

logic valid_incoming_req, write_req, read_req;
logic lbc_ext_cs_ord_wire, lbc_ext_cs_ord_reg;
logic lbc_ext_valid_ord_wire, lbc_ext_valid_ord_reg;

logic [2:0]  pfunc_num_wire;
logic [7:0]  pfnum_wire, pfnum_reg;
logic [AXIL_ADDR_WIDTH-1:0] awaddr_wire, awaddr_reg;
logic [2:0]  awprot_wire, awprot_reg;
logic [AXIL_AXUSER_WIDTH-1:0] awuser_wire, awuser_reg;
logic        awvalid_wire, awvalid_reg;
logic [AXIL_DATA_WIDTH-1:0] wdata_wire, wdata_reg;
logic [(AXIL_DATA_WIDTH/8)-1:0] wstrb_wire, wstrb_reg;
logic [AXIL_AXUSER_WIDTH-1:0] wuser_wire, wuser_reg;
logic        wvalid_wire, wvalid_reg;
logic        bready_wire, bready_reg;
logic [AXIL_ADDR_WIDTH-1:0] araddr_wire, araddr_reg;
logic [2:0]  arprot_wire, arprot_reg;
logic [AXIL_AXUSER_WIDTH-1:0] aruser_wire, aruser_reg;
logic        arvalid_wire, arvalid_reg;
logic [(AXIL_DATA_WIDTH/8)-1:0] rstrb_wire, rstrb_reg;
logic        rready_wire, rready_reg;

logic ack_success_aximm_wire, ack_success_aximm_reg;
logic ack_err_aximm_wire, ack_err_aximm_reg;
logic [63:0] elbi_din_reg, ext_lbc_din_wire;

logic success_re, error_re, error_re_reg;

// from internal register module
logic int_ack_override_en;
logic o_ack_ovrd;
logic o_en_elbi_override_en;

// counter to send ack for appropriate amount of cycles
logic [1:0] elbi_cntr, elbi_timeout;
logic elbi_start_timeout_cntr, elbi_cntr_timeout;

   /* Conditions and assignments used in the FSM */
   assign lbc_ext_cs_ord_wire = (|pl_pcie1_elbi_if.lbc_ext_cs);
   assign lbc_ext_valid_ord_wire = (|pl_pcie1_elbi_if.lbc_ext_valid);

   `XPREG(elbi2axil_clk, elbi2axil_rstn, lbc_ext_cs_ord_reg, lbc_ext_cs_ord_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, lbc_ext_valid_ord_reg, lbc_ext_valid_ord_wire, 'd0)

   // EDT-1079061: new requests will be qualified via the valid and cs rising edge.
   assign valid_incoming_req = (lbc_ext_cs_ord_wire && ~lbc_ext_cs_ord_reg)
                            && (lbc_ext_valid_ord_wire && ~lbc_ext_valid_ord_reg)
                            && (w_st==IDLE);
   assign write_req = (|pl_pcie1_elbi_if.lbc_ext_wr);
   assign read_req = (|pl_pcie1_elbi_if.lbc_ext_rd);
   assign pfunc_num_wire = pl_pcie1_elbi_if.lbc_ext_cs==8'h01 ? 3'b000:
                           pl_pcie1_elbi_if.lbc_ext_cs==8'h02 ? 3'b001:
                           pl_pcie1_elbi_if.lbc_ext_cs==8'h04 ? 3'b010:
                           pl_pcie1_elbi_if.lbc_ext_cs==8'h08 ? 3'b011:
                           pl_pcie1_elbi_if.lbc_ext_cs==8'h10 ? 3'b100:
                           pl_pcie1_elbi_if.lbc_ext_cs==8'h20 ? 3'b101:
                           pl_pcie1_elbi_if.lbc_ext_cs==8'h40 ? 3'b110:
                           pl_pcie1_elbi_if.lbc_ext_cs==8'h80 ? 3'b111:
                                                                3'b000;

   /* Registering the inputs */
   `XPREG(elbi2axil_clk, elbi2axil_rstn, pfnum_reg, pfnum_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, awaddr_reg, awaddr_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, awprot_reg, awprot_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, awuser_reg, awuser_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, awvalid_reg, awvalid_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, bready_reg, bready_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, wdata_reg, wdata_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, wstrb_reg, wstrb_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, wuser_reg, wuser_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, wvalid_reg, wvalid_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, araddr_reg, araddr_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, arprot_reg, arprot_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, aruser_reg, aruser_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, arvalid_reg, arvalid_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, rready_reg, rready_wire, 'd0)
   `XPREG(elbi2axil_clk, elbi2axil_rstn, rstrb_reg, rstrb_wire, 'd0)

   /* Registering the outputs */
   `XPREG(elbi2axil_clk, elbi2axil_rstn, elbi_din_reg, ext_lbc_din_wire, 'd0)

   /* Next State Assignment */
   `XPREG(elbi2axil_clk, elbi2axil_rstn, w_st, next_w_st, IDLE)

   /* FSM */
   always_comb begin
      next_w_st = IDLE;
      start_timeout_cntr = 1'b0;
      ack_success_aximm_wire = 1'b0;
      ack_err_aximm_wire = 1'b0;
      awaddr_wire = 'd0;
      awprot_wire = 'd0;
      awuser_wire = 'd0;
      awvalid_wire = 'd0;
      wdata_wire = 'd0;
      wstrb_wire = 'd0;
      wuser_wire = 'd0;
      wvalid_wire = 'd0;
      bready_wire = 'd0;
      araddr_wire = 'd0;
      arprot_wire = 'd0;
      aruser_wire = 'd0;
      arvalid_wire = 'd0;
      rstrb_wire = 'd0;
      rready_wire = 'd0;
      pfnum_wire = pfnum_reg;
      ext_lbc_din_wire = 'd0;
      case (w_st)
         IDLE:
            // Start new request on valid incoming req while the ack is not sent
            if (valid_incoming_req && ~(|pl_pcie1_elbi_if.ext_lbc_ack)) begin
               pfnum_wire = pl_pcie1_elbi_if.lbc_ext_cs;
               if (write_req) begin
                  next_w_st = W_WAIT;
                  start_timeout_cntr = 1'b0; // since we expect a response, clr cntr and start watchdog timer from next state to get out if response not received
                  awvalid_wire = 1'b1;
                  wvalid_wire = 1'b1;
                  awaddr_wire = {pl_pcie1_elbi_if.lbc_ext_bar_num,
                                 pfunc_num_wire,
                                 pl_pcie1_elbi_if.lbc_ext_vfunc_num,
                                 pl_pcie1_elbi_if.lbc_ext_addr};
                  awuser_wire = {pl_pcie1_elbi_if.lbc_ext_dbi_access,
                                 pl_pcie1_elbi_if.lbc_ext_cxl_mbar0_access,
                                 pl_pcie1_elbi_if.lbc_ext_rom_access,
                                 pl_pcie1_elbi_if.lbc_ext_io_access,
                                 pl_pcie1_elbi_if.lbc_ext_vfunc_active};
                  wuser_wire = {pl_pcie1_elbi_if.lbc_ext_dbi_access,
                                 pl_pcie1_elbi_if.lbc_ext_cxl_mbar0_access,
                                 pl_pcie1_elbi_if.lbc_ext_rom_access,
                                 pl_pcie1_elbi_if.lbc_ext_io_access,
                                 pl_pcie1_elbi_if.lbc_ext_vfunc_active};
                  wdata_wire = pl_pcie1_elbi_if.lbc_ext_dout;
                  wstrb_wire = pl_pcie1_elbi_if.lbc_ext_wr;
               end else if (read_req) begin
                  next_w_st = R_WAIT;
                  start_timeout_cntr = 1'b0; // since we expect a response, clr cntr and start watchdog timer from next state to get out if response not received
                  arvalid_wire = 1'b1;
                  rstrb_wire = pl_pcie1_elbi_if.lbc_ext_rd;
                  araddr_wire = {pl_pcie1_elbi_if.lbc_ext_bar_num,
                                 pfunc_num_wire,
                                 pl_pcie1_elbi_if.lbc_ext_vfunc_num,
                                 pl_pcie1_elbi_if.lbc_ext_addr};
                  aruser_wire = {pl_pcie1_elbi_if.lbc_ext_dbi_access,
                                 pl_pcie1_elbi_if.lbc_ext_cxl_mbar0_access,
                                 pl_pcie1_elbi_if.lbc_ext_rom_access,
                                 pl_pcie1_elbi_if.lbc_ext_io_access,
                                 pl_pcie1_elbi_if.lbc_ext_vfunc_active};
               end
               // To get out of following error conditions where valid_incoming_req is set, but
               // 1. elbi_wr == 0 and elbi_rd == 0, i.e. read or write request with no byte enables
               else if (cntr_timeout) begin
                  start_timeout_cntr = 1'b0;
                  ack_err_aximm_wire = 1'b1;
                  next_w_st = IDLE;
               end else begin
                  start_timeout_cntr = 1'b1; // since we expect a response, start watchdog timer to get out if response not received
                  next_w_st = IDLE;
               end
            end
            else begin
               pfnum_wire = pfnum_reg;
               start_timeout_cntr = 1'b0;
               ack_err_aximm_wire = 1'b0;
               ack_success_aximm_wire = 1'b0;
               ext_lbc_din_wire = elbi_din_reg;
               next_w_st = IDLE;
            end
         W_WAIT:
            // Come out of the state when either timeout expires or successfully received both write ready
            if (pl_elbi_axil_if.wready) begin
               next_w_st = W_RESP;
               bready_wire = 1'b1;
               start_timeout_cntr = 1'b0; // since we expect a response, clr cntr and start watchdog timer from next state to get out if response not received
            end else if (cntr_timeout) begin
               start_timeout_cntr = 1'b0;
               ack_err_aximm_wire = 1'b1;
               next_w_st = IDLE;
            end else begin
               pfnum_wire = pfnum_reg;
               start_timeout_cntr = 1'b1; // since we expect a response, start watchdog timer to get out if response not received
               next_w_st = W_WAIT;
               awvalid_wire = awvalid_reg;
               wvalid_wire = wvalid_reg;
               awaddr_wire = awaddr_reg;
               awuser_wire = awuser_reg;
               wuser_wire = wuser_reg;
               wdata_wire = wdata_reg;
               wstrb_wire = wstrb_reg;
            end
         R_WAIT:
            // Come out of the state when either timeout expires or successfully received read ready
            if (pl_elbi_axil_if.arready) begin
               next_w_st = R_RESP;
               rstrb_wire = rstrb_reg;
               rready_wire = 1'b1;
               start_timeout_cntr = 1'b0; // since we expect a response, clr cntr and start watchdog timer from next state to get out if response not received
            end else if (cntr_timeout) begin
               start_timeout_cntr = 1'b0;
               ack_err_aximm_wire = 1'b1;
               next_w_st = IDLE;
            end else begin
               pfnum_wire = pfnum_reg;
               start_timeout_cntr = 1'b1; // since we expect a response, start watchdog timer to get out if response not received
               next_w_st = R_WAIT;
               arvalid_wire = arvalid_reg;
               araddr_wire = araddr_reg;
               aruser_wire = aruser_reg;
               rstrb_wire = rstrb_reg;
            end
         W_RESP:
            if (pl_elbi_axil_if.bvalid) begin
               if (pl_elbi_axil_if.bresp==RESP_SUCCESS)
                  ack_success_aximm_wire = 1'b1;
               else
                  ack_err_aximm_wire = 1'b1;
               next_w_st = IDLE;
            end else if (cntr_timeout) begin
               start_timeout_cntr = 1'b0;
               ack_err_aximm_wire = 1'b1;
               next_w_st = IDLE;
            end else begin
               pfnum_wire = pfnum_reg;
               bready_wire = bready_reg;
               start_timeout_cntr = 1'b1; // since we expect a response, start watchdog timer to get out if response not received
               next_w_st = W_RESP;
            end
         R_RESP:
            if (pl_elbi_axil_if.rvalid) begin
               next_w_st = IDLE;
               rstrb_wire = rstrb_reg;
               if (pl_elbi_axil_if.rresp==RESP_SUCCESS) begin
                  ack_success_aximm_wire = 1'b1;
                  case (rstrb_reg)
                     8'b00000000 : ext_lbc_din_wire[63: 0] = 'd0; // Write Request
                     8'b00001111 : ext_lbc_din_wire[31: 0] = pl_elbi_axil_if.rdata[31: 0]; // Lower DWORD
                     8'b11110000 : ext_lbc_din_wire[63:32] = pl_elbi_axil_if.rdata[63:32]; // Upper DWORD
                     8'b11111111 : ext_lbc_din_wire[63: 0] = pl_elbi_axil_if.rdata[63: 0]; // All Bytes
                     default: ext_lbc_din_wire[63: 0] = pl_elbi_axil_if.rdata[63: 0];
                  endcase
               end else
                  ack_err_aximm_wire = 1'b1;
            end else if (cntr_timeout) begin
               start_timeout_cntr = 1'b0;
               ack_err_aximm_wire = 1'b1;
               next_w_st = IDLE;
            end else begin
               rstrb_wire = rstrb_reg;
               pfnum_wire = pfnum_reg;
               rready_wire = rready_reg;
               start_timeout_cntr = 1'b1; // since we expect a response, start watchdog timer to get out if response not received
               next_w_st = R_RESP;
            end
         default: next_w_st = IDLE;
      endcase
   end

   /* Counter for watchdog timer */
   always @ (posedge elbi2axil_clk) begin
      if (~elbi2axil_rstn)
         cntr <= 'd0;
      else begin
         if (cntr_timeout)
            cntr <= 'd0;
         else if (start_timeout_cntr)
            cntr <= cntr + 1'b1;
         else cntr <= 'd0;
      end
   end

   /* Timeout */
   assign cntr_timeout = (cntr==TIMEOUT);

`XPREG(elbi2axil_clk, elbi2axil_rstn, ack_success_aximm_reg, ack_success_aximm_wire, 1'b0)
`XPREG(elbi2axil_clk, elbi2axil_rstn, ack_err_aximm_reg,     ack_err_aximm_wire,     1'b0)

   assign success_re = ack_success_aximm_wire && ~ack_success_aximm_reg;
   assign error_re = ack_err_aximm_wire && ~ack_err_aximm_reg;

   // setting timeout for number of cycles of ack
   always @ (posedge elbi2axil_clk) begin
      if (~elbi2axil_rstn) begin
         elbi_timeout <= 2'b00;
         elbi_start_timeout_cntr <= 1'b0;
      end
      else begin
         if (success_re) begin
            elbi_timeout <= 2'b10;
            elbi_start_timeout_cntr <= 1'b1;
         end else if (error_re) begin
            elbi_timeout <= 2'b01;
            elbi_start_timeout_cntr <= 1'b1;
         end else if (elbi_cntr_timeout) begin
            elbi_timeout <= 2'b00;
            elbi_start_timeout_cntr <= 1'b0;
         end
      end
   end

   /* Counter for appropriate cycles of ack */
   always @ (posedge elbi2axil_clk) begin
      if (~elbi2axil_rstn) begin
         elbi_cntr <= 'd0;
      end
      else begin
         if (elbi_cntr_timeout)
            elbi_cntr <= 'd0;
         else if (elbi_start_timeout_cntr)
            elbi_cntr <= elbi_cntr + 1'b1;
      end
   end

   /* Timeout */
   assign elbi_cntr_timeout = (elbi_cntr==elbi_timeout);

   // Internal Register module
   saxil_elbi_registers # (
      .AXIL_ADDR_WIDTH (AXIL_ADDR_WIDTH),
      .AXIL_DATA_WIDTH (AXIL_DATA_WIDTH)
   ) u_saxil_elbi_registers (
      .aclk    (elbi2axil_clk)
     ,.aresetn (elbi2axil_rstn)

     ,.araddr  (pl_axil_regs_if.araddr)
     ,.arprot  (pl_axil_regs_if.arprot)
     ,.arvalid (pl_axil_regs_if.arvalid)
     ,.arready (pl_axil_regs_if.arready)

     ,.rdata   (pl_axil_regs_if.rdata)
     ,.rready  (pl_axil_regs_if.rready)
     ,.rresp   (pl_axil_regs_if.rresp)
     ,.rvalid  (pl_axil_regs_if.rvalid)

     ,.awaddr  (pl_axil_regs_if.awaddr)
     ,.awprot  (pl_axil_regs_if.awprot)
     ,.awvalid (pl_axil_regs_if.awvalid)
     ,.awready (pl_axil_regs_if.awready)

     ,.wdata   (pl_axil_regs_if.wdata)
     ,.wready  (pl_axil_regs_if.wready)
     ,.wstrb   (pl_axil_regs_if.wstrb)
     ,.wvalid  (pl_axil_regs_if.wvalid)

     ,.bready  (pl_axil_regs_if.bready)
     ,.bresp   (pl_axil_regs_if.bresp)
     ,.bvalid  (pl_axil_regs_if.bvalid)

     ,.o_int_override_en      (int_ack_override_en)
     ,.o_ack_ovrd             (o_ack_ovrd)
     ,.o_en_elbi_override_en  (o_en_elbi_override_en)
   );

`XPREG(elbi2axil_clk, elbi2axil_rstn, error_re_reg,     error_re,     1'b0)

   /* Send output Ack */
   assign pl_pcie1_elbi_if.ext_lbc_ack = int_ack_override_en ? o_ack_ovrd : {8{~elbi_cntr_timeout}} & pfnum_reg;
   // assign pl_pcie1_elbi_if.ext_lbc_override_en = o_en_elbi_override_en;
   assign pl_pcie1_elbi_if.ext_lbc_override_en = error_re_reg; // as per EDT-1079061. since this pin is not used by the core anymore,
                                                               // its behaviour in cpm has been modified to indicate error.
   assign pl_pcie1_elbi_if.ext_lbc_din = elbi_din_reg;

   assign pl_elbi_axil_if.awaddr = awaddr_reg;
   assign pl_elbi_axil_if.awprot = awprot_reg;
   assign pl_elbi_axil_if.awuser = awuser_reg;
   assign pl_elbi_axil_if.awvalid = awvalid_reg;
   assign pl_elbi_axil_if.bready = bready_reg;
   assign pl_elbi_axil_if.wdata = wdata_reg;
   assign pl_elbi_axil_if.wstrb = wstrb_reg;
   assign pl_elbi_axil_if.wuser = wuser_reg;
   assign pl_elbi_axil_if.wvalid = wvalid_reg;
   assign pl_elbi_axil_if.araddr = araddr_reg;
   assign pl_elbi_axil_if.arprot = arprot_reg;
   assign pl_elbi_axil_if.aruser = aruser_reg;
   assign pl_elbi_axil_if.arvalid = arvalid_reg;
   assign pl_elbi_axil_if.rready = rready_reg;

endmodule