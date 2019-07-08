//-----------------------------------------------------------------------------
// system_tb.v
//-----------------------------------------------------------------------------

`timescale 1 ns/10 ps

module system_tb
  (
  );

  //real sys_clk_pin_PERIOD = 8000.000000;
  //real sys_rst_pin_LENGTH = 160000;

  wire fpga_0_RS232_Uart_1_sin_pin;
  wire fpga_0_RS232_Uart_1_sout_pin;
  wire [7:0] led_8bits_tri_o;
  
  reg sys_diff_clock_clk_n;
  reg sys_diff_clock_clk_p;
  reg reset;
  
microblaze_design_wrapper microblaze_design_wrapper(
    .led_8bits_tri_o(led_8bits_tri_o),
    .reset(reset),
    .rs232_uart_rxd(fpga_0_RS232_Uart_1_sin_pin),
    .rs232_uart_txd(fpga_0_RS232_Uart_1_sout_pin),
    .sys_diff_clock_clk_n(sys_diff_clock_clk_n),
    .sys_diff_clock_clk_p(sys_diff_clock_clk_p)
  );

  // Clock and reset generation

    initial
      begin
      
         sys_diff_clock_clk_p <= 1'b0;
         sys_diff_clock_clk_n <= 1'b1;
        reset <= 1'b1;
        #600 reset <= 1'b0;
        $display("INITIAL");
      end
      
      
  always #2.5 sys_diff_clock_clk_p <= ~sys_diff_clock_clk_p;
  always #2.5 sys_diff_clock_clk_n <= ~sys_diff_clock_clk_n;
  

	
  

    /****************************************************************************
     *
     * Standard-in and Standard-out implementation
     * UART receiver module
     * - writes to output file for stdout
     * Serial_baudclock should be the UART core's clock frequency / 3
     * e.g. clock frequency = 8ns = 125000000Hz
     * therefore serial baudclock = 1/(125000000/3) * 10^9 = 24ns 
     * finally, 24/2 = 12ns 
     ****************************************************************************/
  
    // UART receiver signals
    reg serial0_baudclock;
    reg serial0_reset;
    // Display Testbench Messages on/off Flags
    wire          uart0_MsgOn;
    // UART messages
    initial force uart0_MsgOn = 1; // Set to 0 to turn off
    initial begin
      serial0_baudclock = 0;
      serial0_reset = 1;
      #100 serial0_reset = 0;
    end
  
    always #271.267 serial0_baudclock <= ~serial0_baudclock;
  
    uart_rcvr_wrapper 
      #("Uart0.output") 
     uart_rcvr_wrapper_0
    (
     .uart_msgon(uart0_MsgOn),
     .uart_sin(fpga_0_RS232_Uart_1_sin_pin),
     .uart_sout(fpga_0_RS232_Uart_1_sout_pin),
     .clock(serial0_baudclock),
     .reset(serial0_reset)
    );
  
     
  // END USER CODE

endmodule

