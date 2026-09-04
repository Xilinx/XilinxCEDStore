// DESCRIPTION :
//   Instantiating the language template for a single URAM from Vivado and
//   adding some wrapper logic so the memory operates in a specific manner.
//   The write logic operates as an ordered memory with just a valid and 
//   data and then an AXI-Lite interface reads the data out of the memory
//   and can reset the write pointer with ANY write. 32kB of addressable
//   memory.
module uram_sdp_4Kx44 (
  input        clk,
  /* FIFO Write to populate URAM */ 
  input        write,
  input [43:0] wdata,
  // AXI-Lite to read URAM and reset wptr */
  //  - Write Address Channel
  input              s_axil_awvalid,
  output logic       s_axil_awready,
  input       [14:0] s_axil_awaddr,
  input       [ 2:0] s_axil_awprot,
  // - Write Data Channel
  input              s_axil_wvalid,
  output logic       s_axil_wready,
  input       [63:0] s_axil_wdata,
  input       [ 7:0] s_axil_wstrb,
  // - Write Response Channel
  output logic       s_axil_bvalid,
  input              s_axil_bready,
  output logic [1:0] s_axil_bresp,
  // - Read Address Channel
  input              s_axil_arvalid,
  output logic       s_axil_arready,
  input       [14:0] s_axil_araddr,
  input       [ 2:0] s_axil_arprot,
  // - Read Data Channel
  output logic        s_axil_rvalid,
  input               s_axil_rready,
  output logic [63:0] s_axil_rdata,
  output logic [ 1:0] s_axil_rresp

);

  localparam logic [1:0] OKAY   = 2'b00,
                         EXOKAY = 2'b01, 
                         SLVERR = 2'b10, 
                         DECERR = 2'b11;

  typedef enum logic [1:0] {WRITE_IDLE, WRITE_DATA, WRITE_RESP} wstate_e;
  typedef enum logic [1:0] {READ_IDLE, READ_DATA, READ_RESP} rstate_e;

  wstate_e      wstate;
  rstate_e      rstate;

  logic         wen;
  logic [12: 0] waddr; //4096=URAM full
  logic [71:44] unused_rdata;
  logic [43: 0] rdata;
  logic [11: 0] raddr; 
  logic         rd_oor; //oor="out of range"
  logic [ 1:0]  rd_lat; //lat="latency" 

  logic ar_done; 
  logic  r_done; 
  logic aw_done; 
  logic  w_done; 
  logic  b_done; 

  assign ar_done = s_axil_arvalid && s_axil_arready;
  assign  r_done = s_axil_rvalid  && s_axil_rready;
  assign aw_done = s_axil_awvalid && s_axil_awready;
  assign  w_done = s_axil_wvalid  && s_axil_wready;
  assign  b_done = s_axil_bvalid  && s_axil_bready;

  assign raddr = s_axil_araddr[3+:12]; //64b (8B) aligned accesses

  assign wen = write && !waddr[12];

  always @(posedge clk) begin
    if (b_done)
      waddr <= 0;
    else if (wen)
      waddr <= waddr + 1;
  end

  /* AXI Write */
  always @(posedge clk) begin
    case (wstate)
      WRITE_IDLE : 
        begin
          s_axil_awready <= 1'b1;
          if (aw_done) begin
            s_axil_awready <= 1'b0;
            wstate <= WRITE_DATA;
          end
        end
      WRITE_DATA : 
        begin
          s_axil_wready <= 1'b1;
          if (w_done) begin
            s_axil_wready <= 1'b0;
            wstate <= WRITE_RESP;
          end
        end
      WRITE_RESP : 
        begin
          s_axil_bvalid <= 1'b1;
          if (b_done) begin
            s_axil_bvalid <= 1'b0;
            wstate <= WRITE_IDLE;
          end
        end
    endcase
  end
  // Writes always OKAY
  assign s_axil_bresp = OKAY;

  /* AXI Read */
  always @(posedge clk) begin
    case (rstate)
      READ_IDLE : 
        begin
          s_axil_arready <= 1'b1;
          if (ar_done) begin
            s_axil_arready <= 1'b0;
            rstate <= READ_DATA;
            rd_oor <= !(raddr<waddr);
            rd_lat <= 1;
          end
        end
      READ_DATA : 
        begin
          rd_lat <= rd_lat - 1;
          if (!rd_lat) begin
            s_axil_rdata <= rd_oor ? '0 : rdata;
            rstate <= READ_RESP; 
          end
        end
      READ_RESP : 
        begin
          s_axil_rvalid <= 1'b1;
          if (r_done) begin
            s_axil_rvalid <= 1'b0;
            rstate <= READ_IDLE;
          end
        end
    endcase
  end
  // Reads always OKAY
  assign s_axil_rresp = OKAY;

  // NOTES:
  //  - Two cycles of read latency due to OREG_B="TRUE"
  //  - One cycle of write latency
  URAM288E5_BASE #(
      .AUTO_SLEEP_LATENCY(8),              // Latency requirement to enter sleep mode
      .AVG_CONS_INACTIVE_CYCLES(10),       // Average consecutive inactive cycles when is SLEEP for power est
      .BWE_MODE_A("PARITY_INDEPENDENT"),   // Port A Byte write control
      .BWE_MODE_B("PARITY_INDEPENDENT"),   // Port B Byte write control
      .EN_AUTO_SLEEP_MODE("FALSE"),        // Enable to automatically enter sleep mode
      .EN_ECC_RD_A("FALSE"),               // Port A ECC encoder
      .EN_ECC_RD_B("FALSE"),               // Port B ECC encoder
      .EN_ECC_WR_A("FALSE"),               // Port A ECC decoder
      .EN_ECC_WR_B("FALSE"),               // Port B ECC decoder                      
      .INIT_FILE("NONE"),                  // URAM initialization file
      .IREG_PRE_A("FALSE"),                // Optional Port A input pipeline registers
      .IREG_PRE_B("FALSE"),                // Optional Port B input pipeline registers
      .IS_CLK_INVERTED(1'b0),              // Optional inverter for CLK
      .IS_EN_A_INVERTED(1'b0),             // Optional inverter for Port A enable
      .IS_EN_B_INVERTED(1'b0),             // Optional inverter for Port B enable
      .IS_RDB_WR_A_INVERTED(1'b0),         // Optional inverter for Port A read/write select
      .IS_RDB_WR_B_INVERTED(1'b0),         // Optional inverter for Port B read/write select
      .IS_RST_A_INVERTED(1'b0),            // Optional inverter for Port A reset
      .IS_RST_B_INVERTED(1'b0),            // Optional inverter for Port B reset
      .OREG_A("FALSE"),                    // Optional Port A output pipeline registers
      .OREG_B("TRUE"),                     // Optional Port B output pipeline registers
      .OREG_ECC_A("FALSE"),                // Port A ECC decoder output
      .OREG_ECC_B("FALSE"),                // Port B ECC decoder output
      .PR_SAVE_DATA("FALSE"),              // Skip initialization after partial reconfiguration
      .READ_WIDTH_A(72),                   // Port A Read width
      .READ_WIDTH_B(72),                   // Port B Read width
      .RST_MODE_A("SYNC"),                 // Port A reset mode
      .RST_MODE_B("SYNC"),                 // Port B reset mode
      .USE_EXT_CE_A("FALSE"),              // Enable Port A external CE inputs for output regs
      .USE_EXT_CE_B("FALSE"),              // Enable Port B external CE inputs for output regs
      .WRITE_WIDTH_A(72),                  // Port A Write width
      .WRITE_WIDTH_B(72)                   // Port B Write width
   ) URAM288E5_BASE_inst (
      .CLK(clk),                           // 1-bit input: Clock source
      // A Port = Write
      .EN_A(wen),                          // 1-bit input: Port A enable
      .BWE_A(9'h7F),                       // 9-bit input: Port A Byte-write enable
      .RDB_WR_A(1'b1),                     // 1-bit input: Port A read/write select
      .DIN_A({{(72-44){1'b0}}, wdata}),    // 72-bit input: Port A write data input
      .ADDR_A({11'h0, waddr[11:0], 3'h0}), // 26-bit input: Port A address
      .DOUT_A(),                           // 72-bit output: Port A read data output
      // B Port = Read
      .EN_B(ar_done),                 // 1-bit input: Port B enable
      .BWE_B(9'h0),                   // 9-bit input: Port B Byte-write enable
      .RDB_WR_B(1'b0),                // 1-bit input: Port B read/write select
      .DIN_B('0),                     // 72-bit input: Port B write data input
      .ADDR_B({11'h0, raddr, 3'h0}),  // 26-bit input: Port B address
      .DOUT_B({unused_rdata, rdata}), // 72-bit output: Port B read data output
      // Tieoffs/Unused
      .DBITERR_A(), 
      .DBITERR_B(),   
      .SBITERR_A(), 
      .SBITERR_B(),  
      .INJECT_DBITERR_A(1'b0), 
      .INJECT_DBITERR_B(1'b0), 
      .INJECT_SBITERR_A(1'b0), 
      .INJECT_SBITERR_B(1'b0), 
      .OREG_CE_A(1'b0),
      .OREG_CE_B(1'b0),   
      .OREG_ECC_CE_A(1'b0),    
      .OREG_ECC_CE_B(1'b0),   
      .RST_A(1'b0),     
      .RST_B(1'b0),      
      .SLEEP(1'b0)     
   );

  // Initialization for sim
  initial begin
    wstate  <= WRITE_IDLE;
    rstate  <= READ_IDLE;
    waddr   <= 0;
    s_axil_awready <= 0;
    s_axil_wready  <= 0;
    s_axil_bvalid  <= 0;
    s_axil_arready <= 0;
    s_axil_rvalid  <= 0;
  end

endmodule
