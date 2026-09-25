// MODULE : custom_axi_tg_reg_space
//
// DESCRIPTION:
// AXI4-Lite slave protocol plus the ONLY clock-domain crossing in this IP.  It
// mirrors axi_cpi_bridge_reg_space.sv's handshake style and signal names so
// that the CDC constraint file can be lifted almost verbatim; the register
// decode itself is factored out into custom_axi_tg_csr so that every CDC flop
// lives inside this one module and a single SCOPED_TO_REF XDC covers them all.
//
// DETAILS:
//  - Every register, the whole iRAM, the status array and every FSM live in the
//    DESTINATION (AXI master) domain.  This block is only a single-outstanding
//    req/ack shuttle, so exactly four single-bit toggles (rreq, rack, wreq,
//    wack) and three quasi-static buses ever cross clocks.
//  - The regbus is a level/pulse protocol rather than the bridge's fixed
//    one-cycle do_capture_*_d, because the dest-side latency is variable: one
//    cycle for a CSR, five for an iRAM read.
//      regbus_req   : level, asserted once the request is captured in the dest
//                     domain, held until regbus_done
//      regbus_done  : one-cycle pulse; regbus_rdata / regbus_resp valid with it
//  - The AXI-Lite read and write FSMs are independent, so a small dest-side
//    arbiter serialises them onto the single regbus.  Reads win a tie; the
//    loser waits one transaction, which is irrelevant on a programming port.
//
// RESTRICTIONS:
//  - Single outstanding read and single outstanding write.
//  - When AXI_AXIL_SYNC == 1, axil_clk and dest_clk MUST be driven from the
//    same net; the synchronisers are removed and only an edge detector remains.
//    Both clock pins exist in every configuration so the BD symbol is stable.
//
// ACRONYMS:
//  - a2d = axil-clock domain to dest-clock domain
//  - a   = axil clock | d = dest clock

module custom_axi_tg_reg_space #(
  parameter bit AXI_AXIL_SYNC = 1'b0    // 1 = axil_clk == dest_clk, bypass sync
)(
  // source domain (AXI-Lite)
  input               axil_clk,
  input               axil_rstn,
  // destination domain (AXI master)
  input               dest_clk,
  input               dest_rstn,
  // dest-domain register bus
  output logic        regbus_req,      // level, held until regbus_done
  output logic        regbus_we,
  output logic [15:0] regbus_addr,
  output logic [31:0] regbus_wdata,
  output logic [ 3:0] regbus_wstrb,
  input               regbus_done,     // 1-cycle pulse
  input        [31:0] regbus_rdata,
  input        [ 1:0] regbus_resp,
  // AXI4-Lite AW channel (write address)
  input               s_axil_awvalid,
  output logic        s_axil_awready,
  input        [15:0] s_axil_awaddr,
  input        [ 2:0] s_axil_awprot,
  // AXI4-Lite W channel (write data)
  input               s_axil_wvalid,
  output logic        s_axil_wready,
  input        [31:0] s_axil_wdata,
  input        [ 3:0] s_axil_wstrb,
  // AXI4-Lite B channel (write response)
  output logic        s_axil_bvalid,
  input               s_axil_bready,
  output logic [ 1:0] s_axil_bresp,
  // AXI4-Lite AR channel (read address)
  input               s_axil_arvalid,
  output logic        s_axil_arready,
  input        [15:0] s_axil_araddr,
  input        [ 2:0] s_axil_arprot,
  // AXI4-Lite R channel (read data)
  output logic        s_axil_rvalid,
  input               s_axil_rready,
  output logic [ 1:0] s_axil_rresp,
  output logic [31:0] s_axil_rdata
);

  // AXI4-Lite response codes
  localparam OKAY   = 2'b00,
             SLVERR = 2'b10;

  // State machine for single outstanding read
  enum logic [1:0] {READ_IDLE, READ_A2D, READ_D2A, READ_PEND} read_state;

  // State machine for single outstanding write
  enum logic [2:0] {WRITE_IDLE, WRITE_DATA, WRITE_A2D, WRITE_D2A, WRITE_PEND}
       write_state;

  logic [15:0] captured_araddr_a;
  logic [15:0] captured_araddr_d;
  logic [ 1:0] capture_rresp;
  logic [31:0] capture_rdata;

  logic [15:0] captured_awaddr_a;
  logic [15:0] captured_awaddr_d;
  logic [31:0] captured_wdata_a;
  logic [31:0] captured_wdata_d;
  logic [ 3:0] captured_wstrb_a;
  logic [ 3:0] captured_wstrb_d;
  logic [ 1:0] capture_bresp;

  logic        ar_done;
  logic        r_done;
  logic        aw_done;
  logic        w_done;
  logic        b_done;

  assign ar_done = s_axil_arvalid && s_axil_arready;
  assign r_done  = s_axil_rvalid  && s_axil_rready;
  assign aw_done = s_axil_awvalid && s_axil_awready;
  assign w_done  = s_axil_wvalid  && s_axil_wready;
  assign b_done  = s_axil_bvalid  && s_axil_bready;

  // AXI-L clock and destination clock may be different domains.
  // a = "axi-l clock" | d = "dest clock"
  // Sync the fact that a txn has occurred from A to D, and then sync the done
  // case from D to A, for both AXI-Lite reads and AXI-Lite writes.
  logic a2d_rreq_a, a2d_rreq_d;
  logic a2d_rack_a, a2d_rack_d;
  logic a2d_rreq_d_pulse;

  logic a2d_wreq_a, a2d_wreq_d;
  logic a2d_wack_a, a2d_wack_d;
  logic a2d_wreq_d_pulse;

  generate
  if (AXI_AXIL_SYNC) begin : g_axil_sync
    // s_axil_aclk is guaranteed identical to m_axi_aclk.  No synchronizers.
    logic a2d_rreq_q, a2d_wreq_q;

    assign a2d_rreq_d = a2d_rreq_a;
    assign a2d_rack_a = a2d_rack_d;
    assign a2d_wreq_d = a2d_wreq_a;
    assign a2d_wack_a = a2d_wack_d;

    // A 1-flop edge detector is still needed to turn the level request into the
    // single-cycle capture pulse the dest-domain handler expects.
    always_ff @(posedge dest_clk) begin
      if (!dest_rstn) begin
        a2d_rreq_q <= 1'b0;
        a2d_wreq_q <= 1'b0;
      end
      else begin
        a2d_rreq_q <= a2d_rreq_a;
        a2d_wreq_q <= a2d_wreq_a;
      end
    end

    assign a2d_rreq_d_pulse = a2d_rreq_a ^ a2d_rreq_q;
    assign a2d_wreq_d_pulse = a2d_wreq_a ^ a2d_wreq_q;
  end
  else begin : g_axil_async
    (* ASYNC_REG = "TRUE" *) logic a2d_rreq_sync_0, a2d_rreq_sync_1,
                                   a2d_rreq_sync_2;
    (* ASYNC_REG = "TRUE" *) logic a2d_rack_sync_0, a2d_rack_sync_1;
    (* ASYNC_REG = "TRUE" *) logic a2d_wreq_sync_0, a2d_wreq_sync_1,
                                   a2d_wreq_sync_2;
    (* ASYNC_REG = "TRUE" *) logic a2d_wack_sync_0, a2d_wack_sync_1;

    // Sync-ing the read request from A into D
    always_ff @(posedge dest_clk) begin
      a2d_rreq_sync_0 <= a2d_rreq_a;
      a2d_rreq_sync_1 <= a2d_rreq_sync_0;
      a2d_rreq_sync_2 <= a2d_rreq_sync_1;
    end

    assign a2d_rreq_d       = a2d_rreq_sync_1;
    assign a2d_rreq_d_pulse = a2d_rreq_sync_1 ^ a2d_rreq_sync_2;

    // Sync-ing the read ack from D into A
    always_ff @(posedge axil_clk) begin
      a2d_rack_sync_0 <= a2d_rack_d;
      a2d_rack_sync_1 <= a2d_rack_sync_0;
    end

    assign a2d_rack_a = a2d_rack_sync_1;

    // Sync-ing the write request from A into D
    always_ff @(posedge dest_clk) begin
      a2d_wreq_sync_0 <= a2d_wreq_a;
      a2d_wreq_sync_1 <= a2d_wreq_sync_0;
      a2d_wreq_sync_2 <= a2d_wreq_sync_1;
    end

    assign a2d_wreq_d       = a2d_wreq_sync_1;
    assign a2d_wreq_d_pulse = a2d_wreq_sync_1 ^ a2d_wreq_sync_2;

    // Sync-ing the write ack from D into A
    always_ff @(posedge axil_clk) begin
      a2d_wack_sync_0 <= a2d_wack_d;
      a2d_wack_sync_1 <= a2d_wack_sync_0;
    end

    assign a2d_wack_a = a2d_wack_sync_1;
  end
  endgenerate

  //--------------------------------------------------------------------------
  // Destination-domain shuttle.  One regbus transaction at a time; reads win a
  // tie against writes.
  //--------------------------------------------------------------------------
  enum logic [1:0] {D_IDLE, D_RD, D_WR} dest_state;

  logic rd_pend, wr_pend;

  always_ff @(posedge dest_clk) begin
    if (!dest_rstn) begin
      dest_state        <= D_IDLE;
      rd_pend           <= 1'b0;
      wr_pend           <= 1'b0;
      regbus_req        <= 1'b0;
      regbus_we         <= 1'b0;
      regbus_addr       <= 16'h0000;
      regbus_wdata      <= 32'h0000_0000;
      regbus_wstrb      <= 4'h0;
      a2d_rack_d        <= 1'b0;
      a2d_wack_d        <= 1'b0;
      capture_rdata     <= 32'h0000_0000;
      capture_rresp     <= OKAY;
      capture_bresp     <= OKAY;
      captured_araddr_d <= 16'h0000;
      captured_awaddr_d <= 16'h0000;
      captured_wdata_d  <= 32'h0000_0000;
      captured_wstrb_d  <= 4'h0;
    end
    else begin
      // Data will be stable, sample from A into D on a posedge pulse
      if (a2d_rreq_d_pulse && a2d_rreq_d) begin
        captured_araddr_d <= captured_araddr_a;
        rd_pend           <= 1'b1;
      end
      if (a2d_wreq_d_pulse && a2d_wreq_d) begin
        captured_awaddr_d <= captured_awaddr_a;
        captured_wdata_d  <= captured_wdata_a;
        captured_wstrb_d  <= captured_wstrb_a;
        wr_pend           <= 1'b1;
      end

      case (dest_state)
        D_IDLE : begin
          if (rd_pend) begin
            regbus_req  <= 1'b1;
            regbus_we   <= 1'b0;
            regbus_addr <= captured_araddr_d;
            dest_state  <= D_RD;
          end
          else if (wr_pend) begin
            regbus_req   <= 1'b1;
            regbus_we    <= 1'b1;
            regbus_addr  <= captured_awaddr_d;
            regbus_wdata <= captured_wdata_d;
            regbus_wstrb <= captured_wstrb_d;
            dest_state   <= D_WR;
          end
        end

        D_RD : begin
          if (regbus_done) begin
            regbus_req    <= 1'b0;
            capture_rdata <= regbus_rdata;
            capture_rresp <= regbus_resp;
            rd_pend       <= 1'b0;
            a2d_rack_d    <= 1'b1;
            dest_state    <= D_IDLE;
          end
        end

        D_WR : begin
          if (regbus_done) begin
            regbus_req    <= 1'b0;
            capture_bresp <= regbus_resp;
            wr_pend       <= 1'b0;
            a2d_wack_d    <= 1'b1;
            dest_state    <= D_IDLE;
          end
        end

        default : dest_state <= D_IDLE;
      endcase

      // Deassert ack once the source has deasserted its request
      if (a2d_rreq_d_pulse && !a2d_rreq_d)
        a2d_rack_d <= 1'b0;
      if (a2d_wreq_d_pulse && !a2d_wreq_d)
        a2d_wack_d <= 1'b0;
    end
  end

  //--------------------------------------------------------------------------
  // Read state machine - supports a single outstanding read and crosses clock
  // domains A2D for the request and D2A for the data
  //--------------------------------------------------------------------------
  always_ff @(posedge axil_clk) begin
    if (!axil_rstn) begin
      read_state     <= READ_IDLE;
      s_axil_rvalid  <= 1'b0;
      s_axil_arready <= 1'b0;
      s_axil_rresp   <= OKAY;
      s_axil_rdata   <= 32'h0000_0000;
      a2d_rreq_a     <= 1'b0;
    end
    else begin
      case (read_state)
        READ_IDLE :
          begin
            s_axil_arready <= 1'b1;
            if (ar_done) begin
              s_axil_arready    <= 1'b0;
              captured_araddr_a <= s_axil_araddr;
              read_state        <= READ_A2D;
            end
          end
        READ_A2D :
          begin
            a2d_rreq_a <= 1'b1;
            if (a2d_rack_a)
              read_state <= READ_D2A;
          end
        READ_D2A :
          begin
            a2d_rreq_a <= 1'b0;
            if (!a2d_rack_a)
              read_state <= READ_PEND;
          end
        READ_PEND :
          begin
            s_axil_rvalid <= 1'b1;
            {s_axil_rresp, s_axil_rdata} <= {capture_rresp, capture_rdata};
            if (r_done) begin
              s_axil_rvalid <= 1'b0;
              read_state    <= READ_IDLE;
            end
          end
        default : read_state <= READ_IDLE;
      endcase
    end
  end

  //--------------------------------------------------------------------------
  // Write state machine - supports a single outstanding write and crosses clock
  // domains A2D for the request and D2A for the response
  //--------------------------------------------------------------------------
  always_ff @(posedge axil_clk) begin
    if (!axil_rstn) begin
      write_state    <= WRITE_IDLE;
      s_axil_bvalid  <= 1'b0;
      s_axil_awready <= 1'b0;
      s_axil_wready  <= 1'b0;
      s_axil_bresp   <= OKAY;
      a2d_wreq_a     <= 1'b0;
    end
    else begin
      case (write_state)
        WRITE_IDLE :
          begin
            s_axil_awready <= 1'b1;
            // Capture AW when it arrives
            if (aw_done) begin
              s_axil_awready    <= 1'b0;
              captured_awaddr_a <= s_axil_awaddr;
              write_state       <= WRITE_DATA;
            end
          end
        WRITE_DATA :
          begin
            s_axil_wready <= 1'b1;
            // Capture W when it arrives
            if (w_done) begin
              s_axil_wready    <= 1'b0;
              captured_wdata_a <= s_axil_wdata;
              captured_wstrb_a <= s_axil_wstrb;
              write_state      <= WRITE_A2D;
            end
          end
        WRITE_A2D :
          begin
            a2d_wreq_a <= 1'b1;
            if (a2d_wack_a)
              write_state <= WRITE_D2A;
          end
        WRITE_D2A :
          begin
            a2d_wreq_a <= 1'b0;
            if (!a2d_wack_a)
              write_state <= WRITE_PEND;
          end
        WRITE_PEND :
          begin
            s_axil_bvalid <= 1'b1;
            s_axil_bresp  <= capture_bresp;
            if (b_done) begin
              s_axil_bvalid <= 1'b0;
              write_state   <= WRITE_IDLE;
            end
          end
        default : write_state <= WRITE_IDLE;
      endcase
    end
  end

endmodule
