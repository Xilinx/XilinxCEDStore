// MODULE : gpio_ext_debounce
//
// DESCRIPTION:
// Debouncer for WIDTH asynchronous, active-high inputs (pushbuttons, DIP
// switches). Each input is passed through a 2-FF synchronizer, then a
// per-bit saturating counter must see the synchronized input differ from the
// debounced output for DEBOUNCE_MS in a row before the output flips. Any
// sample that agrees with the current output restarts that bit's counter.
//
// After reset the debounced output loads the first synchronized sample
// directly (no debounce delay), and 'vld' goes high on the same edge. 'dout'
// is only meaningful while 'vld' is high.
//
// PARAMETERS:
//  WIDTH        number of inputs
//  CLK_FREQ_HZ  frequency of clk in Hz
//  DEBOUNCE_MS  required stable time in milliseconds

module gpio_ext_debounce #(
  parameter int WIDTH       = 4,
  parameter int CLK_FREQ_HZ = 250_000_000,
  parameter int DEBOUNCE_MS = 10
)(
  input                    clk,
  input                    rstn,  // synchronous, active-low
  input        [WIDTH-1:0] din,   // asynchronous
  output logic [WIDTH-1:0] dout,
  output logic             vld
);

  // Number of consecutive differing samples needed to flip an output bit
  localparam int DEB_CYCLES = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;
  localparam int CNT_W      = (DEB_CYCLES > 1) ? $clog2(DEB_CYCLES) : 1;

  localparam logic [CNT_W-1:0] CNT_MAX = CNT_W'(DEB_CYCLES - 1);

`ifndef SYNTHESIS
  //synthesis off
  initial begin
    if (WIDTH < 1)
      $fatal(1, $sformatf("Invalid parameter WIDTH=%0d, must be >=1", WIDTH));
    if (DEB_CYCLES < 1)
      $fatal(1, $sformatf("DEBOUNCE_MS=%0d at CLK_FREQ_HZ=%0d is <1 cycle",
                          DEBOUNCE_MS, CLK_FREQ_HZ));
  end
  //synthesis on
`endif

  (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] sync_q1;
  (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] sync_q2;

  logic [CNT_W-1:0] cnt  [WIDTH];
  logic [WIDTH-1:0] flip;
  logic [      1:0] warm;
  logic             first;

  always_ff @(posedge clk) begin
    sync_q1 <= din;
    sync_q2 <= sync_q1;
  end

  // Wait for two clocks after reset so sync_q2 holds a real sample
  always_ff @(posedge clk) begin
    if (!rstn)
      warm <= 2'b00;
    else
      warm <= {warm[0], 1'b1};
  end

  assign first = (warm == 2'b01);

  always_comb begin
    for (int i = 0; i < WIDTH; i++)
      flip[i] = vld && (sync_q2[i] != dout[i]) && (cnt[i] == CNT_MAX);
  end

  always_ff @(posedge clk) begin
    if (!rstn) begin
      vld <= 1'b0;
      for (int i = 0; i < WIDTH; i++)
        cnt[i] <= '0;
    end
    else begin
      vld <= vld | first;
      for (int i = 0; i < WIDTH; i++) begin
        if (!vld || flip[i] || (sync_q2[i] == dout[i]))
          cnt[i] <= '0;
        else
          cnt[i] <= cnt[i] + 1'b1;
      end
    end
  end

  // dout is qualified by vld, so it needs no reset
  always_ff @(posedge clk) begin
    if (first)
      dout <= sync_q2;
    else
      dout <= dout ^ flip;
  end

endmodule
