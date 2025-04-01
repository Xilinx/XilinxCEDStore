/* - Converts AXI-Lite interface to a simple read/write register interface, meaning
     this module basically handles all AXI protocol handshaking and just gives the
     register interface a write/read interface
   - Only handles 1 outstanding AXI-Lite transaction at a time
   - Does not handle valid write addr and write data in the same cycle, logic blocks
     to require two cycles
   - Doesn't use A*PROT
   - Register slave must deassert rvalid when rdone is asserted
*/
module axil_to_reg#(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
)(
  /* AXI-Lite Slave */
  // Global
  input aclk,
  input aresetn,
  // Write Addr
  input                   s_axil_awvalid,
  output logic            s_axil_awready,
  input  [ADDR_WIDTH-1:0] s_axil_awaddr,
  input            [ 2:0] s_axil_awprot,
  // Write Data
  input                     s_axil_wvalid,
  output logic              s_axil_wready,
  input    [DATA_WIDTH-1:0] s_axil_wdata,
  input  [DATA_WIDTH/8-1:0] s_axil_wstrb,
  // Write Resp
  output  logic s_axil_bvalid,
  input         s_axil_bready,
  output  [1:0] s_axil_bresp,
  // Read Addr
  input                   s_axil_arvalid,
  output logic            s_axil_arready,
  input  [ADDR_WIDTH-1:0] s_axil_araddr,
  input            [ 2:0] s_axil_arprot,
  // Read Data
  output                  s_axil_rvalid,
  input                   s_axil_rready,
  output [DATA_WIDTH-1:0] s_axil_rdata,
  output            [1:0] s_axil_rresp,
  /* Register Master */
  // Write 
  output                          wen,
  output logic [ADDR_WIDTH-1:0]   waddr,
  output       [DATA_WIDTH-1:0]   wdata,
  output       [DATA_WIDTH/8-1:0] wbe,
  // Read
  output                        ren,
  input                         rvalid,
  output                        rdone,
  output logic [ADDR_WIDTH-1:0] raddr,
  input        [DATA_WIDTH-1:0] rdata
);
  
  always_ff @(posedge aclk) begin
    
    if (!aresetn)
      s_axil_awready <= 1'b1;
    else if (s_axil_awvalid & s_axil_awready) begin
      s_axil_awready <= 1'b0;
      waddr          <= s_axil_awaddr;
    end
    else if (s_axil_bvalid & s_axil_bready)
      s_axil_awready <= 1'b1;

    if (!aresetn)
      s_axil_wready <= 1'b0;
    else if (s_axil_awvalid & s_axil_awready)
      s_axil_wready <= 1'b1;
    else if (s_axil_wvalid & s_axil_wready)
      s_axil_wready <= 1'b0;

    if (s_axil_wvalid & s_axil_wready)
      s_axil_bvalid <= 1'b1;
    else if (s_axil_bvalid & s_axil_bready)
      s_axil_bvalid <= 1'b0;

    if (!aresetn)
      s_axil_arready <= 1'b1;
    else if (s_axil_arvalid & s_axil_arready) begin
      s_axil_arready <= 1'b0;
      raddr <= s_axil_araddr;
    end
    else if (s_axil_rvalid & s_axil_rready)
      s_axil_arready <= 1'b1;
  end

  assign wen   = s_axil_wvalid & s_axil_wready;
  assign wdata = s_axil_wdata;
  assign wbe   = s_axil_wstrb;

  assign ren           = s_axil_arvalid & s_axil_arready;
  assign s_axil_rvalid = rvalid;
  assign s_axil_rdata  = rdata;
  assign rdone         = s_axil_rvalid & s_axil_rready;
  
  /* Constants */
  assign s_axil_bresp = 2'b00; 
  assign s_axil_rresp = 2'b00; 

endmodule
