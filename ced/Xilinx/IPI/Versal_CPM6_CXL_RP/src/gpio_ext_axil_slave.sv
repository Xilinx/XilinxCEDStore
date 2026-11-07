// MODULE : gpio_ext_axil_slave
//
// DESCRIPTION:
// AXI4-Lite slave controlling 8 LEDs and reading 4 pushbuttons and 4 DIP
// switches. Intended to be added directly to a Versal block design (via "Add
// Module...") and driven from the NOC. All AXI4-Lite ports carry
// X_INTERFACE_INFO/X_INTERFACE_PARAMETER attributes so Vivado infers the
// S_AXI bus interface and the CLK/RST association.
//
// AXI BEHAVIOR:
//  - Reads and writes are each limited to one outstanding transaction; a read
//    and a write may be in flight at the same time.
//  - AWREADY/WREADY assert together, for one cycle, only after both AWVALID
//    and WVALID have been seen with no write response pending. ARREADY
//    asserts for one cycle after ARVALID is seen with no read response
//    pending. No READY depends combinationally on a VALID.
//  - Responses are registered and issued the cycle after the handshake.
//  - WSTRB is honored per byte lane. A write with WSTRB=0 has no effect.
//  - Unmapped, misaligned, and read-only-register-write accesses return
//    SLVERR (reads return 0). Reserved bits read as 0 and ignore writes.
//
// REGISTER MAP (4 KB window; offsets are byte addresses):
//  0x000 LED_VAL   [7:0]  R/W  LED value (static mode) or enable (blink/PWM)
//  0x004 LED_MODE  [31:0] R/W  per-LED nibble, LED i at [4i+3:4i]:
//                              nibble[1:0] 0=static 1=blink 2=PWM 3=static,
//                              nibble[3:2] reserved
//  0x008 BTN       [3:0]  RO   debounced pushbuttons (1 = pressed)
//  0x00C SW        [3:0]  RO   debounced DIP switches (1 = on)
//  0x010 LED_CNT0  [31:0] R/W  LED 0 blink/PWM control; LED_CNTi = 0x010+4*i
//   ...                        blink: reload value N, LED toggles every N+1
//  0x02C LED_CNT7              clocks
//                              PWM: [6:0] duty in percent, 0..100, any value
//                              above 100 is fully on
//  0x030 BTN_IRQ_STATUS [3:0] RW1C  sticky pushbutton event
//  0x034 BTN_IRQ_ENABLE [3:0] R/W   per-bit interrupt enable
//  0x038 BTN_IRQ_EDGE   [7:0] R/W   bits [2i+1:2i] for pushbutton i:
//                                   0=off 1=rising 2=falling 3=both (reset)
//  0x03C SW_IRQ_STATUS  [3:0] RW1C  same as BTN_IRQ_STATUS, for switches
//  0x040 SW_IRQ_ENABLE  [3:0] R/W
//  0x044 SW_IRQ_EDGE    [7:0] R/W
//  0x048 SOFT_RESET     [0]   WO    write 1 to reset the block (self-clearing,
//                                   reads 0)
//
// LED MODES:
//  static  LED = LED_VAL[i]
//  blink   LED_VAL[i]=0 holds the LED off; =1 toggles it every LED_CNTi+1
//          clocks, starting from off
//  PWM     LED_VAL[i]=0 holds the LED off; =1 drives it with the duty cycle
//          in LED_CNTi[6:0] at PWM_HZ with 1% resolution. All PWM LEDs share
//          one time base.
//
// INTERRUPTS: btn_irq and switch_irq are high while any enabled status bit
// is set. any_irq is their OR. All are active high, level, and registered.
// The first sample after reset never produces an event.
//
// SOFT RESET: writing 1 to SOFT_RESET[0] resets everything except the AXI
// handshake and response logic, one clock after the write is accepted. All
// registers return to their reset values, the LED, blink and PWM state
// restarts, the interrupt outputs clear, and the debouncers re-load their
// first sample without producing an event. The triggering write itself
// completes with OKAY. SOFT_RESET[31:1] are reserved and ignore writes.

module gpio_ext_axil_slave #(
  parameter int CLK_FREQ_HZ = 250_000_000,
  parameter int DEBOUNCE_MS = 10,
  parameter int PWM_HZ      = 1_000
)(
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET s_axi_aresetn" *)
  input                s_axi_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
  input                s_axi_aresetn,

  // Write address channel
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI AWADDR" *)
  input  [11:0]        s_axi_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI AWPROT" *)
  input  [ 2:0]        s_axi_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI AWVALID" *)
  input                s_axi_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI AWREADY" *)
  output logic         s_axi_awready,

  // Write data channel
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI WDATA" *)
  input  [31:0]        s_axi_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI WSTRB" *)
  input  [ 3:0]        s_axi_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI WVALID" *)
  input                s_axi_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI WREADY" *)
  output logic         s_axi_wready,

  // Write response channel
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI BRESP" *)
  output logic [ 1:0]  s_axi_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI BVALID" *)
  output logic         s_axi_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI BREADY" *)
  input                s_axi_bready,

  // Read address channel
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI ARADDR" *)
  input  [11:0]        s_axi_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI ARPROT" *)
  input  [ 2:0]        s_axi_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI ARVALID" *)
  input                s_axi_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI ARREADY" *)
  output logic         s_axi_arready,

  // Read data channel
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RDATA" *)
  output logic [31:0]  s_axi_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RRESP" *)
  output logic [ 1:0]  s_axi_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RVALID" *)
  output logic         s_axi_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RREADY" *)
  input                s_axi_rready,

  // Board pins
  output logic [7:0]   gpio_led,
  input        [3:0]   gpio_pb,
  input        [3:0]   gpio_dip,

  // Interrupts
  (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 btn_irq INTERRUPT" *)
  (* X_INTERFACE_PARAMETER = "SENSITIVITY LEVEL_HIGH" *)
  output logic         btn_irq,
  (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 switch_irq INTERRUPT" *)
  (* X_INTERFACE_PARAMETER = "SENSITIVITY LEVEL_HIGH" *)
  output logic         switch_irq,
  (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 any_irq INTERRUPT" *)
  (* X_INTERFACE_PARAMETER = "SENSITIVITY LEVEL_HIGH" *)
  output logic         any_irq
);

  localparam int PWM_STEPS   = 100;
  localparam int STEP_CYCLES = CLK_FREQ_HZ / (PWM_HZ * PWM_STEPS);
  localparam int STEP_W      = (STEP_CYCLES > 1) ? $clog2(STEP_CYCLES) : 1;

`ifndef SYNTHESIS
  //synthesis off
  initial begin
    if (STEP_CYCLES < 1)
      $fatal(1, $sformatf("PWM_HZ=%0d too high for CLK_FREQ_HZ=%0d",
                          PWM_HZ, CLK_FREQ_HZ));
  end
  //synthesis on
`endif

  localparam logic [11:0] ADDR_LED_VAL        = 12'h000;
  localparam logic [11:0] ADDR_LED_MODE       = 12'h004;
  localparam logic [11:0] ADDR_BTN            = 12'h008;
  localparam logic [11:0] ADDR_SW             = 12'h00C;
  localparam logic [11:0] ADDR_LED_CNT0       = 12'h010;
  //     ...              ...             ...         //
  localparam logic [11:0] ADDR_LED_CNT7       = 12'h02C;
  localparam logic [11:0] ADDR_BTN_IRQ_STATUS = 12'h030;
  localparam logic [11:0] ADDR_BTN_IRQ_ENABLE = 12'h034;
  localparam logic [11:0] ADDR_BTN_IRQ_EDGE   = 12'h038;
  localparam logic [11:0] ADDR_SW_IRQ_STATUS  = 12'h03C;
  localparam logic [11:0] ADDR_SW_IRQ_ENABLE  = 12'h040;
  localparam logic [11:0] ADDR_SW_IRQ_EDGE    = 12'h044;
  localparam logic [11:0] ADDR_SOFT_RESET     = 12'h048;

  localparam logic [1:0] OKAY   = 2'b00;
  localparam logic [1:0] SLVERR = 2'b10;

  localparam logic [1:0] MODE_BLINK = 2'd1;
  localparam logic [1:0] MODE_PWM   = 2'd2;

  // Reset for everything except the AXI handshake and response logic
  logic core_rstn;

  // --------------------------------------------------------------------
  // Registers
  // --------------------------------------------------------------------
  logic [ 7:0] led_val;
  logic [ 1:0] led_mode [8];
  logic [31:0] led_cnt  [8];

  // Index 0 = pushbuttons, 1 = DIP switches
  logic [3:0] grp_stat [2];
  logic [3:0] grp_en   [2];
  logic [7:0] grp_edge [2];
  logic [3:0] grp_db   [2];
  logic       grp_irq  [2];

  // --------------------------------------------------------------------
  // Debouncers
  // --------------------------------------------------------------------
  logic [3:0] btn_db;
  logic [3:0] sw_db;
  logic       btn_vld;
  logic       sw_vld;

  gpio_ext_debounce #(
    .WIDTH       (4),
    .CLK_FREQ_HZ (CLK_FREQ_HZ),
    .DEBOUNCE_MS (DEBOUNCE_MS)
  ) u_btn_debounce (
    .clk  (s_axi_aclk),
    .rstn (core_rstn),
    .din  (gpio_pb),
    .dout (btn_db),
    .vld  (btn_vld)
  );

  gpio_ext_debounce #(
    .WIDTH       (4),
    .CLK_FREQ_HZ (CLK_FREQ_HZ),
    .DEBOUNCE_MS (DEBOUNCE_MS)
  ) u_sw_debounce (
    .clk  (s_axi_aclk),
    .rstn (core_rstn),
    .din  (gpio_dip),
    .dout (sw_db),
    .vld  (sw_vld)
  );

  assign grp_db[0] = btn_db;
  assign grp_db[1] = sw_db;

  // --------------------------------------------------------------------
  // Write channel: one outstanding write at a time
  // --------------------------------------------------------------------
  logic wr_go;  // AW and W handshake together in this cycle

  assign s_axi_awready = wr_go;
  assign s_axi_wready  = wr_go;

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)
      wr_go <= 1'b0;
    else if (wr_go)
      wr_go <= 1'b0;
    else
      wr_go <= s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid;
  end

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)
      s_axi_bvalid <= 1'b0;
    else if (wr_go)
      s_axi_bvalid <= 1'b1;
    else if (s_axi_bready)
      s_axi_bvalid <= 1'b0;
  end

  // Write address decode (only used while wr_go is high)
  logic       wr_led_val;
  logic       wr_led_mode;
  logic       wr_soft_rst;
  logic [7:0] wr_led_cnt;
  logic [1:0] wr_irq_stat;
  logic [1:0] wr_irq_en;
  logic [1:0] wr_irq_edge;
  logic       wr_hit;

  always_comb begin
    wr_led_val  = 1'b0;
    wr_led_mode = 1'b0;
    wr_soft_rst = 1'b0;
    wr_led_cnt  = '0;
    wr_irq_stat = '0;
    wr_irq_en   = '0;
    wr_irq_edge = '0;
    if (s_axi_awaddr[1:0] == 2'b00) begin
      case (s_axi_awaddr)
        ADDR_LED_VAL:        wr_led_val     = 1'b1;
        ADDR_LED_MODE:       wr_led_mode    = 1'b1;
        ADDR_BTN_IRQ_STATUS: wr_irq_stat[0] = 1'b1;
        ADDR_BTN_IRQ_ENABLE: wr_irq_en[0]   = 1'b1;
        ADDR_BTN_IRQ_EDGE:   wr_irq_edge[0] = 1'b1;
        ADDR_SW_IRQ_STATUS:  wr_irq_stat[1] = 1'b1;
        ADDR_SW_IRQ_ENABLE:  wr_irq_en[1]   = 1'b1;
        ADDR_SW_IRQ_EDGE:    wr_irq_edge[1] = 1'b1;
        ADDR_SOFT_RESET:     wr_soft_rst    = 1'b1;
        default: begin
          for (int i = 0; i < 8; i++)
            if (s_axi_awaddr == ADDR_LED_CNT0 + 12'(4 * i))
              wr_led_cnt[i] = 1'b1;
        end
      endcase
    end
  end

  assign wr_hit = wr_led_val | wr_led_mode | wr_soft_rst | (|wr_led_cnt) |
                  (|wr_irq_stat) | (|wr_irq_en) | (|wr_irq_edge);

  // core_rstn follows s_axi_aresetn and is also pulled low for one clock,
  // starting the cycle after the write handshake, by a write of 1 to
  // SOFT_RESET[0]
  always_ff @(posedge s_axi_aclk) begin
    core_rstn <= s_axi_aresetn &&
                 !(wr_go && wr_soft_rst && s_axi_wstrb[0] && s_axi_wdata[0]);
  end

  // bresp is qualified by bvalid, so it needs no reset
  always_ff @(posedge s_axi_aclk) begin
    if (wr_go)
      s_axi_bresp <= wr_hit ? OKAY : SLVERR;
  end

  always_ff @(posedge s_axi_aclk) begin
    if (!core_rstn) begin
      led_val <= '0;
      for (int i = 0; i < 8; i++) begin
        led_mode[i] <= '0;
        led_cnt[i]  <= '0;
      end
    end
    else if (wr_go) begin
      if (wr_led_val && s_axi_wstrb[0])
        led_val <= s_axi_wdata[7:0];
      for (int i = 0; i < 8; i++) begin
        // Nibbles 2k and 2k+1 share byte lane k
        if (wr_led_mode && s_axi_wstrb[i/2])
          led_mode[i] <= s_axi_wdata[4*i +: 2];
        for (int b = 0; b < 4; b++)
          if (wr_led_cnt[i] && s_axi_wstrb[b])
            led_cnt[i][8*b +: 8] <= s_axi_wdata[8*b +: 8];
      end
    end
  end

  // --------------------------------------------------------------------
  // Read channel: one outstanding read at a time
  // --------------------------------------------------------------------
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)
      s_axi_arready <= 1'b0;
    else
      s_axi_arready <= s_axi_arvalid && !s_axi_rvalid && !s_axi_arready;
  end

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)
      s_axi_rvalid <= 1'b0;
    else if (s_axi_arready)
      s_axi_rvalid <= 1'b1;
    else if (s_axi_rready)
      s_axi_rvalid <= 1'b0;
  end

  logic [31:0] rd_data;
  logic        rd_hit;
  logic [ 2:0] rd_cnt_idx;

  assign rd_cnt_idx = 3'((s_axi_araddr - ADDR_LED_CNT0) >> 2);

  always_comb begin
    rd_data = '0;
    rd_hit  = 1'b1;
    if (s_axi_araddr[1:0] != 2'b00)
      rd_hit = 1'b0;
    else begin
      case (s_axi_araddr)
        ADDR_LED_VAL:        rd_data[7:0] = led_val;
        ADDR_LED_MODE: begin
          for (int i = 0; i < 8; i++)
            rd_data[4*i +: 2] = led_mode[i];
        end
        ADDR_BTN:            rd_data[3:0] = btn_db;
        ADDR_SW:             rd_data[3:0] = sw_db;
        ADDR_BTN_IRQ_STATUS: rd_data[3:0] = grp_stat[0];
        ADDR_BTN_IRQ_ENABLE: rd_data[3:0] = grp_en[0];
        ADDR_BTN_IRQ_EDGE:   rd_data[7:0] = grp_edge[0];
        ADDR_SW_IRQ_STATUS:  rd_data[3:0] = grp_stat[1];
        ADDR_SW_IRQ_ENABLE:  rd_data[3:0] = grp_en[1];
        ADDR_SW_IRQ_EDGE:    rd_data[7:0] = grp_edge[1];
        ADDR_SOFT_RESET:     rd_data      = '0;
        default: begin
          if (s_axi_araddr inside {[ADDR_LED_CNT0 : ADDR_LED_CNT7]})
            rd_data = led_cnt[rd_cnt_idx];
          else
            rd_hit = 1'b0;
        end
      endcase
    end
  end

  // rdata/rresp are qualified by rvalid, so they need no reset
  always_ff @(posedge s_axi_aclk) begin
    if (s_axi_arready) begin
      s_axi_rdata <= rd_data;
      s_axi_rresp <= rd_hit ? OKAY : SLVERR;
    end
  end

  // --------------------------------------------------------------------
  // Interrupt groups
  // --------------------------------------------------------------------
  for (genvar g = 0; g < 2; g++) begin : g_irq
    logic [3:0] stat_q;
    logic [3:0] en_q;
    logic [7:0] edge_q;
    logic [3:0] prev;
    logic [3:0] evt;
    logic [3:0] clr;
    logic       vld;
    logic       vld_q;

    assign vld = (g == 0) ? btn_vld : sw_vld;

    // prev is qualified by vld_q, which rises one cycle after the first
    // debounced sample is loaded, so that sample never causes an event
    always_ff @(posedge s_axi_aclk) begin
      prev <= grp_db[g];
    end

    always_ff @(posedge s_axi_aclk) begin
      if (!core_rstn)
        vld_q <= 1'b0;
      else
        vld_q <= vld;
    end

    for (genvar b = 0; b < 4; b++) begin : g_evt
      assign evt[b] = vld_q &&
                      ((edge_q[2*b]   &&  grp_db[g][b] && !prev[b]) ||
                       (edge_q[2*b+1] && !grp_db[g][b] &&  prev[b]));
    end

    for (genvar b = 0; b < 4; b++) begin : g_clr
      assign clr[b] = wr_go && wr_irq_stat[g] && s_axi_wstrb[0] &&
                      s_axi_wdata[b];
    end

    // A new event wins over a coincident clear
    always_ff @(posedge s_axi_aclk) begin
      if (!core_rstn) begin
        stat_q <= '0;
        en_q   <= '0;
        edge_q <= '1;
      end
      else begin
        stat_q <= (stat_q & ~clr) | evt;
        if (wr_go && wr_irq_en[g] && s_axi_wstrb[0])
          en_q <= s_axi_wdata[3:0];
        if (wr_go && wr_irq_edge[g] && s_axi_wstrb[0])
          edge_q <= s_axi_wdata[7:0];
      end
    end

    assign grp_stat[g] = stat_q;
    assign grp_en[g]   = en_q;
    assign grp_edge[g] = edge_q;
    assign grp_irq[g]  = |(stat_q & en_q);
  end

  always_ff @(posedge s_axi_aclk) begin
    if (!core_rstn) begin
      btn_irq    <= 1'b0;
      switch_irq <= 1'b0;
      any_irq    <= 1'b0;
    end
    else begin
      btn_irq    <= grp_irq[0];
      switch_irq <= grp_irq[1];
      any_irq    <= grp_irq[0] || grp_irq[1];
    end
  end

  // --------------------------------------------------------------------
  // LED engine
  // --------------------------------------------------------------------
  // PWM time base shared by all LEDs: pwm_step counts 0..PWM_STEPS-1, one
  // step every STEP_CYCLES clocks
  logic [STEP_W-1:0] step_cnt;
  logic [       6:0] pwm_step;

  always_ff @(posedge s_axi_aclk) begin
    if (!core_rstn) begin
      step_cnt <= '0;
      pwm_step <= '0;
    end
    else if (step_cnt == STEP_W'(STEP_CYCLES - 1)) begin
      step_cnt <= '0;
      pwm_step <= (pwm_step == 7'(PWM_STEPS - 1)) ? 7'd0 : pwm_step + 7'd1;
    end
    else
      step_cnt <= step_cnt + 1'b1;
  end

  for (genvar i = 0; i < 8; i++) begin : g_led
    logic        blink_run;
    logic [31:0] blink_cnt;
    logic        blink_q;
    logic        led_d;

    assign blink_run = led_val[i] && (led_mode[i] == MODE_BLINK);

    // While not blinking the counter tracks LED_CNT, so enabling the
    // blink starts a full period. blink_cnt and blink_q are reloaded
    // whenever blink_run is low, so they need no reset.
    always_ff @(posedge s_axi_aclk) begin
      if (!blink_run) begin
        blink_cnt <= led_cnt[i];
        blink_q   <= 1'b0;
      end
      else if (blink_cnt == '0) begin
        blink_cnt <= led_cnt[i];
        blink_q   <= ~blink_q;
      end
      else
        blink_cnt <= blink_cnt - 1'b1;
    end

    always_comb begin
      case (led_mode[i])
        MODE_BLINK: led_d = blink_q;
        MODE_PWM:   led_d = led_val[i] && (pwm_step < led_cnt[i][6:0]);
        default:    led_d = led_val[i];
      endcase
    end

    always_ff @(posedge s_axi_aclk) begin
      gpio_led[i] <= led_d;
    end
  end

endmodule
