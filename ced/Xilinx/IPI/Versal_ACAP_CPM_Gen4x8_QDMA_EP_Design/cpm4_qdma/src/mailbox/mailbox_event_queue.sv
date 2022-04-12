`ifndef MAILBOX_EVENT_QUEUE_SV
`define MAILBOX_EVENT_QUEUE_SV
//TODO: invalid the entry when a VF is resetted while a packet are pending
//(in fsm)
`include "mailbox_defines.svh"
//import mailbox_global_defines_pkg::*;

`timescale 1ns/1ps
module qdma_v2_0_1_mailbox_event_queue
#(
  parameter QUEUE_DEPTH = 256, // Event queue depth
  parameter EVENT_W     = 8    // Event queue data width
)
(
  input                clk,
  input                rst,
  input [EVENT_W-1:0]  i_event,
  input                i_push,
  input                i_pop,
  output [EVENT_W-1:0] o_event,
  output  logic        o_vld,
  //error status for debugging
  output  logic        eq_overflow,
  output  logic        eq_underflow
);


localparam EQ_MEM_W         = EVENT_W;
localparam EQ_MEM_PAR_W     = 1; 
localparam EQ_MEM_DEPTH     = QUEUE_DEPTH;
localparam EQ_MEM_ADR_W     = $clog2(EQ_MEM_DEPTH);
localparam EQ_MEM_FFOUT     = 1;
localparam EQ_MEM_R_LATENCY = EQ_MEM_FFOUT + 1;


reg  [EQ_MEM_ADR_W:0]       wrptr;
reg  [EQ_MEM_ADR_W:0]       rdptr;
reg                         eq_full;
reg  [EQ_MEM_R_LATENCY-1:0] rd_dly;

wire                  wr_en;
wire [EQ_MEM_ADR_W:0] wrptr_nxt;
wire [EQ_MEM_ADR_W:0] rdptr_nxt;


mailbox_xpm_sdpram_if # (
    .MEM_W         (EQ_MEM_W), 
    .ADR_W         (EQ_MEM_ADR_W), 
    .WBE_W         (1) 
) eq_mem ();

/*******************************************************************************/
// Implementation
/*******************************************************************************/

/* Write pointer operation */
assign wr_en = i_push;
assign wrptr_nxt = (wrptr + 1'b1);

always_ff@(posedge clk) 
  if(rst) 
    wrptr <= {EQ_MEM_ADR_W+1{1'b0}};
  else 
    wrptr <= wr_en ? wrptr_nxt : wrptr;

/* FIFO is full when read/write pointers are equal but MSB bit inverted */
wire eq_full_nxt   = (wr_en) ?
                     ((wrptr_nxt[EQ_MEM_ADR_W] ^ rdptr[EQ_MEM_ADR_W]) &
                     (wrptr_nxt[EQ_MEM_ADR_W-1:0] == rdptr[EQ_MEM_ADR_W-1:0])) :
                     ((wrptr[EQ_MEM_ADR_W] ^ rdptr[EQ_MEM_ADR_W]) &
                     (wrptr[EQ_MEM_ADR_W-1:0] == rdptr[EQ_MEM_ADR_W-1:0]));

always_ff@(posedge clk)
  if (rst)
    eq_full <= 1'b1;
  else
    eq_full <= eq_full_nxt;

always @(posedge clk)
  if (rst)
    eq_overflow <= 1'b0;
  else
    eq_overflow <= wr_en & eq_full;


assign eq_underflow = 1'b0; //TODO add underflow detection
/*Memory write control*/
always_ff@(posedge clk)
  if(rst) begin
    eq_mem.we  <= 1'b0;
    eq_mem.wad <= {EQ_MEM_ADR_W{1'b0}};
    eq_mem.wdt <= {EQ_MEM_W{1'b0}};
  end else begin
    eq_mem.we  <= wr_en;
    eq_mem.wad <= wrptr[EQ_MEM_ADR_W-1:0];
    eq_mem.wdt <= i_event;
  end
  
/*Read pointer operation*/
// Always fetch the oldest event from the FIFO 
// FIFO is empty when read/write pointers are exactly equal
wire eq_empty  = (wrptr[EQ_MEM_ADR_W:0] == rdptr[EQ_MEM_ADR_W:0]);
wire rd_en_nxt = ~(eq_empty | o_vld | (|rd_dly)|eq_mem.re);

assign o_event = eq_mem.rdt;
always_ff@(posedge clk)
  if(rst)
    rdptr <= {EQ_MEM_ADR_W+1{1'b0}};
  else
    rdptr <= (i_pop & o_vld) ? (rdptr + 1'b1) : rdptr;

// Memory read operation 
always@(posedge clk)
  if(rst) begin
    eq_mem.re  <= 1'b0;
    eq_mem.rad <= '0;
  end
  else begin
    eq_mem.re  <= rd_en_nxt;
    eq_mem.rad <= rdptr[EQ_MEM_ADR_W-1:0];
  end

generate if (EQ_MEM_R_LATENCY > 1) begin: GEN_RD_LAT_GT_1
always_ff @(posedge clk)
  if (rst)
    rd_dly <= {EQ_MEM_R_LATENCY{1'b0}};
  else
    rd_dly <= {rd_dly[EQ_MEM_R_LATENCY-2:0], eq_mem.re};

end
endgenerate

generate if (EQ_MEM_R_LATENCY == 1) begin: GEN_RD_LAT_EQ_1
always_ff @(posedge clk)
  if (rst)
    rd_dly <= 1'b0;
  else
    rd_dly <= eq_mem.re;

end
endgenerate

always_ff@(posedge clk)
  if(rst)
    o_vld <= '0;
  else 
    o_vld <= i_pop ? '0 :
             rd_dly[EQ_MEM_R_LATENCY-1] ? 1'b1 : o_vld ;

/*******************************************************************************/
// memory instance
/*******************************************************************************/
qdma_v2_0_1_mailbox_xpm_sdpram_wrap 
  #(
    .MEM_W         (EQ_MEM_W), 
    .ADR_W         (EQ_MEM_ADR_W), 
    .WBE_W         (1 ), 
    //.PAR_W         (MEM_W/8 ), 
//Chris Edit    .ECC_ENABLE    (1), 
    .ECC_ENABLE    (0), 
    .PARITY_ENABLE (0), 
    .RDT_FFOUT     (EQ_MEM_FFOUT)           
  ) u_eq_mem (
  .clk (clk ), 
  .rst (rst ), 
  .we  (eq_mem.we  ), 
  .wad (eq_mem.wad ), 
  .wdt (eq_mem.wdt ), 
  .wpar(eq_mem.wpar), 
  .re  (eq_mem.re  ), 
  .rad (eq_mem.rad ), 
  .rdt (eq_mem.rdt ), 
  .rpar(eq_mem.rpar), 
  .sbe (eq_mem.sbe ), 
  .dbe (eq_mem.dbe )
);

endmodule
`endif
