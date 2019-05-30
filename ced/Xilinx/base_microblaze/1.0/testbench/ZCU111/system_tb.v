//-----------------------------------------------------------------------------
// system_tb.v
//-----------------------------------------------------------------------------

`timescale 1 ns/10 ps

module system_tb
  (
  );


  wire fpga_0_RS232_Uart_1_sin_pin;
  wire fpga_0_RS232_Uart_1_sout_pin;
  wire [7:0] led_8bits_tri_o;
  
  reg sysclk_300_clk_n;
  reg sysclk_300_clk_p;
  reg reset;
  
base_mb_wrapper base_mb_wrapper(
    .led_8bits_tri_o(led_8bits_tri_o),
    .reset(reset),
    .uart2_pl_rxd(fpga_0_RS232_Uart_1_sin_pin),
    .uart2_pl_txd(fpga_0_RS232_Uart_1_sout_pin),
    .default_sysclk1_300mhz_clk_n(sysclk_300_clk_n),
    .default_sysclk1_300mhz_clk_p(sysclk_300_clk_p)
  );

  // Clock and reset generation

    initial
      begin
      
         sysclk_300_clk_p <= 1'b0;
         sysclk_300_clk_n <= 1'b1;
        reset <= 1'b1;
        #600 reset <= 1'b0;
        $display("INITIAL");
      end
      
      
  always #1.665 sysclk_300_clk_p <= ~sysclk_300_clk_p;
  always #1.665 sysclk_300_clk_n <= ~sysclk_300_clk_n;

  
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

