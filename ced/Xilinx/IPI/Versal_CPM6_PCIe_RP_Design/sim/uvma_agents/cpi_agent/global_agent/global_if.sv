// This interface conforms to CPI Spec Rev1.0, 02/2023
interface global_if#(parameter P=1);

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  wire clk;

  // Init
  wire txcon_req;
  wire rxcon_ack;
  wire rxdiscon_nack;
  wire rx_empty;

  // RAS
  wire fatal;
  wire viral;

  // IDE
  wire [P-1:0] epoch_id;
  wire [P-1:0] epoch_commit;
  wire [P-1:0] epoch_reject;

  // Don't touch
  logic         i_txcon_req     = 'z;
  logic         i_rxcon_ack     = 'z;
  logic         i_rxdiscon_nack = 'z;
  logic         i_rx_empty      = 'z;
  logic         i_fatal         = 'z;
  logic         i_viral         = 'z;
  logic [P-1:0] i_epoch_id      = 'z;
  logic [P-1:0] i_epoch_commit  = 'z;
  logic [P-1:0] i_epoch_reject  = 'z;

  // Need to make this assign so the driver of block level TBs can drive
  // the i_* nets directly via the agent configured as a master, then
  // can move to top level TB and switch to an agent configured as a
  // passive slave and not have to worry about changing the interface,
  // only the configuration object
  assign txcon_req     = i_txcon_req;
  assign rxcon_ack     = i_rxcon_ack;
  assign rxdiscon_nack = i_rxdiscon_nack;
  assign rx_empty      = i_rx_empty;
  assign fatal         = i_fatal;
  assign viral         = i_viral;
  assign epoch_id      = i_epoch_id;
  assign epoch_commit  = i_epoch_commit;
  assign epoch_reject  = i_epoch_reject;

  // Master agent will drive some of the i_* signals
  // Active slave agent will drive some other i_* signals
  clocking cb @(posedge clk);
    default input #1step output posedge;
    output i_txcon_req, 
           i_rxcon_ack, 
           i_rxdiscon_nack, 
           i_rx_empty,
           i_fatal, 
           i_viral,
           i_epoch_id,
           i_epoch_commit,
           i_epoch_reject;
  endclocking

  /* ASSERTIONS */
  bit       en_assert = 1'b0;
  bit       viral_en; 
  bit       fatal_en; 

  // Auto-enable assertions
  initial begin
    wait({txcon_req,rxcon_ack} === 2'h0);
    en_assert = 1'b1;
  end

  always@(posedge viral iff !viral_en) 
    `uvm_error("interface_check", "global_if noticed a viral assertion that shouldn't occur")

  always@(posedge fatal iff !fatal_en) 
    `uvm_error("interface_check", "global_if noticed a fatal assertion that shouldn't occur")

endinterface
