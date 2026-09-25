// axil_cxl_pm_viral.sv
// AXI-Lite slave register file bridging CPM6 PM and viral signals.
//
// Register map (4 KB, 12-bit address):
//   0x000  PM_IN_LO  [31:0]  cpm6_pm_in[31:0]      WO   (write pulses cpm6_pm_in[31:0]
//                                                         high for one cycle on the bits
//                                                         written as 1; reads return 0)
//   0x004  PM_IN_HI  [1:0]   cpm6_pm_in[33:32]     WO   (bits [31:2] reserved; reads return 0)
//   0x008  PM_OUT_STICKY_LO [31:0] sticky latch of cpm6_pm_out[31:0]   R/WC
//                                  (each bit sets as soon as the matching
//                                  cpm6_pm_out bit pulses; stays set until
//                                  cleared by writing 1 to that bit; a
//                                  coincident hardware pulse wins over a
//                                  same-cycle clear)
//   0x00C  PM_OUT_STICKY_HI [0]    sticky latch of cpm6_pm_out[32]     R/WC
//                                  (bits [31:1] reserved; same semantics
//                                  as PM_OUT_STICKY_LO)
//   0x010  PM_OUT_LO [31:0]  cpm6_pm_out[31:0]     RO
//   0x014  PM_OUT_HI [0]     cpm6_pm_out[32]       RO   (bits [31:1] reserved)
//   0x018  VIRAL     [0]     cpm6_tx_viral         R/W
//                    [1]     cpm6_tx_viral_sent    RO
//                    [4]     cpm6_rx_viral_rcvd    RO
//
// Out-of-range or reads to WO regs return 0xDEAD_DEAD; out-of-range writes are silently dropped.
// All responses are OKAY (2'b00).

module axil_cxl_pm_viral (
  input  logic        s_axi_aclk,
  input  logic        s_axi_aresetn,   // synchronous, active-low

  // Write address channel
  input  logic [11:0] s_axil_awaddr,
  input  logic [2:0]  s_axil_awprot,
  input  logic        s_axil_awvalid,
  output logic        s_axil_awready,

  // Write data channel
  input  logic [31:0] s_axil_wdata,
  input  logic [3:0]  s_axil_wstrb,
  input  logic        s_axil_wvalid,
  output logic        s_axil_wready,

  // Write response channel
  output logic [1:0]  s_axil_bresp,
  output logic        s_axil_bvalid,
  input  logic        s_axil_bready,

  // Read address channel
  input  logic [11:0] s_axil_araddr,
  input  logic [2:0]  s_axil_arprot,
  input  logic        s_axil_arvalid,
  output logic        s_axil_arready,

  // Read data channel
  output logic [31:0] s_axil_rdata,
  output logic [1:0]  s_axil_rresp,
  output logic        s_axil_rvalid,
  input  logic        s_axil_rready,

  // CPM6 PM status — read-only via AXI-Lite
  input  logic [32:0] cpm6_pm_out,

  // CPM6 PM control — read-write via AXI-Lite
  output logic [33:0] cpm6_pm_in,

  // Viral signaling
  output logic        cpm6_tx_viral,
  input  logic        cpm6_tx_viral_sent,
  input  logic        cpm6_rx_viral_rcvd
);

  // -------------------------------------------------------------------------
  // Address constants
  // -------------------------------------------------------------------------
  localparam logic [11:0] ADDR_PM_IN_LO         = 12'h000;
  localparam logic [11:0] ADDR_PM_IN_HI         = 12'h004;
  localparam logic [11:0] ADDR_PM_OUT_STICKY_LO = 12'h008;
  localparam logic [11:0] ADDR_PM_OUT_STICKY_HI = 12'h00C;
  localparam logic [11:0] ADDR_PM_OUT_LO        = 12'h010;
  localparam logic [11:0] ADDR_PM_OUT_HI        = 12'h014;
  localparam logic [11:0] ADDR_VIRAL            = 12'h018;

  // -------------------------------------------------------------------------
  // R/W register storage
  // -------------------------------------------------------------------------
  logic [31:0] reg_pm_in_lo_pulse;   // one-cycle pulse of bits written to PM_IN_LO
  logic [1:0]  reg_pm_in_hi;
  logic        reg_tx_viral;
  logic [32:0] reg_pm_out_sticky;   // R/W1C latch for cpm6_pm_out[32:0]

  assign cpm6_pm_in    = {reg_pm_in_hi, reg_pm_in_lo_pulse};
  assign cpm6_tx_viral = reg_tx_viral;

  // -------------------------------------------------------------------------
  // Write path — AW and W channels captured independently
  //
  // awready/wready are deasserted while a BRESP is outstanding so that at
  // most one write transaction is in flight at a time.
  // -------------------------------------------------------------------------
  logic        aw_pend, w_pend;
  logic [11:0] aw_addr_q;
  logic [31:0] w_data_q;
  logic [3:0]  w_strb_q;
  logic        bvalid_r;

  logic        wr_exec;

  assign wr_exec = aw_pend & w_pend;

  assign s_axil_awready = ~aw_pend & ~bvalid_r;
  assign s_axil_wready  = ~w_pend  & ~bvalid_r;
  assign s_axil_bvalid  = bvalid_r;
  assign s_axil_bresp   = 2'b00;

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      aw_pend   <= 1'b0;
      w_pend    <= 1'b0;
      bvalid_r  <= 1'b0;
    end else begin
      // AW channel
      if (s_axil_awvalid && s_axil_awready) begin
        aw_pend   <= 1'b1;
        aw_addr_q <= s_axil_awaddr;
      end
      else if (wr_exec)
        aw_pend <= 1'b0;

      // W channel
      if (s_axil_wvalid && s_axil_wready) begin
        w_pend   <= 1'b1;
        w_data_q <= s_axil_wdata;
        w_strb_q <= s_axil_wstrb;
      end
      else if (wr_exec)
        w_pend <= 1'b0;

      // B channel
      if (wr_exec)
        bvalid_r <= 1'b1;
      else if (s_axil_bready)
        bvalid_r <= 1'b0;
    end
  end

  // -------------------------------------------------------------------------
  // PM_IN_LO pulse generation — reg_pm_in_lo_pulse is high for exactly one
  // cycle after a write, reflecting only the bits written as 1 (masked by
  // wstrb); it self-clears every cycle that isn't itself a PM_IN_LO write.
  // -------------------------------------------------------------------------
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      reg_pm_in_lo_pulse <= '0;
    end
    else if (wr_exec && aw_addr_q == ADDR_PM_IN_LO) begin
      reg_pm_in_lo_pulse[7:0]   <= w_strb_q[0] ? w_data_q[7:0]   : 8'h00;
      reg_pm_in_lo_pulse[15:8]  <= w_strb_q[1] ? w_data_q[15:8]  : 8'h00;
      reg_pm_in_lo_pulse[23:16] <= w_strb_q[2] ? w_data_q[23:16] : 8'h00;
      reg_pm_in_lo_pulse[31:24] <= w_strb_q[3] ? w_data_q[31:24] : 8'h00;
    end else begin
      reg_pm_in_lo_pulse <= '0;
    end
  end

  // -------------------------------------------------------------------------
  // PM_OUT_STICKY_LO/HI R/WC sticky latch — each bit sets as soon as the
  // matching cpm6_pm_out bit pulses and holds until software writes a 1 to
  // that bit to clear it. A hardware set on the same cycle as a software
  // clear takes priority, so a new event can never be silently swallowed by
  // a racing clear.
  // -------------------------------------------------------------------------
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      reg_pm_out_sticky[31:0] <= '0;
    end else begin
      for (int i = 0; i < 32; i++) begin
        if (cpm6_pm_out[i])
          reg_pm_out_sticky[i] <= 1'b1;
        else if (wr_exec && aw_addr_q == ADDR_PM_OUT_STICKY_LO &&
                 w_strb_q[i/8] && w_data_q[i])
          reg_pm_out_sticky[i] <= 1'b0;
      end
    end
  end

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)
      reg_pm_out_sticky[32] <= 1'b0;
    else if (cpm6_pm_out[32])
      reg_pm_out_sticky[32] <= 1'b1;
    else if (wr_exec && aw_addr_q == ADDR_PM_OUT_STICKY_HI && w_strb_q[0] && w_data_q[0])
      reg_pm_out_sticky[32] <= 1'b0;
  end

  // -------------------------------------------------------------------------
  // Register write execution (fires one cycle after both AW and W captured)
  // -------------------------------------------------------------------------
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      reg_pm_in_hi <= '0;
      reg_tx_viral <= 1'b0;
    end
    else if (wr_exec) begin
      case (aw_addr_q)
        ADDR_PM_IN_HI: begin
          if (w_strb_q[0]) reg_pm_in_hi <= w_data_q[1:0];
        end
        ADDR_VIRAL: begin
          if (w_strb_q[0]) reg_tx_viral <= w_data_q[0];
        end
        default: ; // RO, WO-pulse (PM_IN_LO handled above), and unknown addresses
      endcase
    end
  end

  // -------------------------------------------------------------------------
  // Read path
  // -------------------------------------------------------------------------
  logic [31:0] rd_data_mux;

  always_comb begin
    case (s_axil_araddr)
      ADDR_PM_IN_LO:         rd_data_mux = 32'h0000_0000; // write-only
      ADDR_PM_IN_HI:         rd_data_mux = 32'h0000_0000; // write-only
      ADDR_PM_OUT_STICKY_LO: rd_data_mux = reg_pm_out_sticky[31:0];
      ADDR_PM_OUT_STICKY_HI: rd_data_mux = {31'b0, reg_pm_out_sticky[32]};
      ADDR_PM_OUT_LO:        rd_data_mux = cpm6_pm_out[31:0];
      ADDR_PM_OUT_HI:        rd_data_mux = {31'b0, cpm6_pm_out[32]};
      ADDR_VIRAL:            rd_data_mux = {27'b0, cpm6_rx_viral_rcvd, 2'b0,
                                             cpm6_tx_viral_sent, reg_tx_viral};
      default:               rd_data_mux = 32'hDEAD_DEAD;
    endcase
  end

  assign s_axil_arready = ~s_axil_rvalid;
  assign s_axil_rresp   = 2'b00;

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      s_axil_rvalid <= 1'b0;
      s_axil_rdata  <= '0;
    end
    else if (s_axil_arvalid && s_axil_arready) begin
      s_axil_rvalid <= 1'b1;
      s_axil_rdata  <= rd_data_mux;
    end
    else if (s_axil_rready) begin
      s_axil_rvalid <= 1'b0;
    end
  end

endmodule
