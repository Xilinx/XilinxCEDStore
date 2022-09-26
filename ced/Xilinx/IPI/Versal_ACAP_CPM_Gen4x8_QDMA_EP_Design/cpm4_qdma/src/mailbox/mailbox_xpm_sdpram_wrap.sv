`ifndef MAILBOX_XPM_SDPRAM_WRAP_SV
`define MAILBOX_XPM_SDPRAM_WRAP_SV

// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////
/*
XPM_MEMORY instantiation template for simple dual port RAM configurations
Refer to the targeted device family architecture libraries guide for XPM_MEMORY documentation
=======================================================================================================================

Parameter usage table, organized as follows:
+---------------------------------------------------------------------------------------------------------------------+
| Parameter name          | Data type          | Restrictions, if applicable                                          |
|---------------------------------------------------------------------------------------------------------------------|
| Description                                                                                                         |
+---------------------------------------------------------------------------------------------------------------------+
+---------------------------------------------------------------------------------------------------------------------+
| MEMORY_SIZE             | Integer            | Must be integer multiple of [WRITE|READ]_DATA_WIDTH_[A|B]            |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the total memory array size, in bits.                                                                       |
| For example, enter 65536 for a 2kx32 RAM.                                                                           |
| When ECC is enabled and set to "encode_only", then the memory size has to be multiples of READ_DATA_WIDTH_B         |
| When ECC is enabled and set to "decode_only", then the memory size has to be multiples of WRITE_DATA_WIDTH_A        |
+---------------------------------------------------------------------------------------------------------------------+
| MEMORY_PRIMITIVE        | String             | Must be "auto", "distributed", "block" or "ultra"                    |
|---------------------------------------------------------------------------------------------------------------------|
| Designate the memory primitive (resource type) to use:                                                              |
|   "auto": Allow Vivado Synthesis to choose                                                                          |
|   "distributed": Distributed memory                                                                                 |
|   "block": Block memory                                                                                             |
|   "ultra": Ultra RAM memory                                                                                         |
+---------------------------------------------------------------------------------------------------------------------+
| CLOCKING_MODE           | String             | Must be "common_clock" or "independent_clock"                        |
|---------------------------------------------------------------------------------------------------------------------|
| Designate whether port A and port B are clocked with a common clock or with independent clocks:                     |
|   "common_clock": Common clocking; clock both port A and port B with clka                                           |
|   "independent_clock": Independent clocking; clock port A with clka and port B with clkb                            |
+---------------------------------------------------------------------------------------------------------------------+
| MEMORY_INIT_FILE        | String             | Must be exactly "none" or the name of the file (in quotes)           |
|---------------------------------------------------------------------------------------------------------------------|
| Specify "none" (including quotes) for no memory initialization, or specify the name of a memory initialization file:|
|   Enter only the name of the file with .mem extension, including quotes but without path (e.g. "my_file.mem").      |
|   File format must be ASCII and consist of only hexadecimal values organized into the specified depth by            |
|   narrowest data width generic value of the memory.  See the Memory File (MEM) section for more                     |
|   information on the syntax. Initialization of memory happens through the file name specified only when parameter   |
|   MEMORY_INIT_PARAM value is equal to "".                                                                           |
|   When using XPM_MEMORY in a project, add the specified file to the Vivado project as a design source.              |
+---------------------------------------------------------------------------------------------------------------------+
| MEMORY_INIT_PARAM       | String             | Must be exactly "" or the string of hex characters (in quotes)       |
|---------------------------------------------------------------------------------------------------------------------|
| Specify "" or "0" (including quotes) for no memory initialization through parameter, or specify the string          |
| containing the hex characters.Enter only hex characters and each location separated by delimiter(,).                |
| Parameter format must be ASCII and consist of only hexadecimal values organized into the specified depth by         |
| narrowest data width generic value of the memory.  For example, if the narrowest data width is 8, and the depth of  |
| memory is 8 locations, then the parameter value should be passed as shown below.                                    |
|   parameter MEMORY_INIT_PARAM = "AB,CD,EF,1,2,34,56,78"                                                             |
|                                  |                   |                                                              |
|                                  0th                7th                                                             |
|                                location            location                                                         |
+---------------------------------------------------------------------------------------------------------------------+
| USE_MEM_INIT            | Integer             | Must be 0 or 1                                                      |
|---------------------------------------------------------------------------------------------------------------------|
| Specify 1 to enable the generation of below message and 0 to disable the generation of below message completely.    |
| Note: This message gets generated only when there is no Memory Initialization specified either through file or      |
| Parameter.                                                                                                          |
|    INFO : MEMORY_INIT_FILE and MEMORY_INIT_PARAM together specifies no memory initialization.                       |
|    Initial memory contents will be all 0's                                                                          |
+---------------------------------------------------------------------------------------------------------------------+
| WAKEUP_TIME             | String             | Must be "disable_sleep" or "use_sleep_pin"                           |
|---------------------------------------------------------------------------------------------------------------------|
| Specify "disable_sleep" to disable dynamic power saving option, and specify "use_sleep_pin" to enable the           |
| dynamic power saving option                                                                                         |
+---------------------------------------------------------------------------------------------------------------------+
| MESSAGE_CONTROL         | Integer            | Must be 0 or 1                                                       |
|---------------------------------------------------------------------------------------------------------------------|
| Specify 1 to enable the dynamic message reporting such as collision warnings, and 0 to disable the message reporting|
+---------------------------------------------------------------------------------------------------------------------+
| USE_EMBEDDED_CONSTRAINT | Integer            | Must be 0 or 1                                                       |
|---------------------------------------------------------------------------------------------------------------------|
| Specify 1 to enable the set_false_path constraint addition between clka of Distributed RAM and doutb_reg on clkb    |
+---------------------------------------------------------------------------------------------------------------------+
| WRITE_DATA_WIDTH_A      | Integer            | Must be > 0                                                          |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the width of the port A write data input port dina, in bits.                                                |
| When ECC is enabled and set to "encode_only" or "both_encode_and_decode", then WRITE_DATA_WIDTH_A has to be         |
| multiples of 64-bits                                                                                                |
| When ECC is enabled and set to "decode_only", then WRITE_DATA_WIDTH_A has to be multiples of 72-bits                |
+---------------------------------------------------------------------------------------------------------------------+
| BYTE_WRITE_WIDTH_A      | Integer            | Must be 8, 9, or the value of WRITE_DATA_WIDTH_A                     |
|---------------------------------------------------------------------------------------------------------------------|
| To enable byte-wide writes on port A, specify the byte width, in bits:                                              |
|   8: 8-bit byte-wide writes, legal when WRITE_DATA_WIDTH_A is an integer multiple of 8                              |
|   9: 9-bit byte-wide writes, legal when WRITE_DATA_WIDTH_A is an integer multiple of 9                              |
| Or to enable word-wide writes on port A, specify the same value as for WRITE_DATA_WIDTH_A.                          |
+---------------------------------------------------------------------------------------------------------------------+
| ADDR_WIDTH_A            | Integer            | Must be >= ceiling of log2(MEMORY_SIZE/WRITE_DATA_WIDTH_A)           |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the width of the port A address port addra, in bits.                                                        |
| Must be large enough to access the entire memory from port A, i.e. >= $clog2(MEMORY_SIZE/WRITE_DATA_WIDTH_A).       |
+---------------------------------------------------------------------------------------------------------------------+
| READ_DATA_WIDTH_B       | Integer            | Must be > 0                                                          |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the width of the port B read data output port doutb, in bits.                                               |
| When ECC is enabled and set to "encode_only", then READ_DATA_WIDTH_B has to be multiples of 72-bits                 |
| When ECC is enabled and set to "decode_only" or "both_encode_and_decode", then READ_DATA_WIDTH_B has to be          |
| multiples of 64-bits                                                                                                |
+---------------------------------------------------------------------------------------------------------------------+
| ADDR_WIDTH_B            | Integer            | Must be >= ceiling of log2(MEMORY_SIZE/READ_DATA_WIDTH_B)            |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the width of the port B address port addrb, in bits.                                                        |
| Must be large enough to access the entire memory from port B, i.e. >= $clog2(MEMORY_SIZE/READ_DATA_WIDTH_B).        |
+---------------------------------------------------------------------------------------------------------------------+
| READ_RESET_VALUE_B      | String             |                                                                      |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the reset value of the port B final output register stage in response to rstb input port is assertion.      |
| As this parameter is a string, please specify the hex values inside double quotes. As an example,                   |
| If the read data width is 8, then specify READ_RESET_VALUE_B = "EA";                                                |
| When ECC is enabled, then reset value is not supported                                                              |
+---------------------------------------------------------------------------------------------------------------------+
| READ_LATENCY_B          | Integer             | Must be >= 0 for distributed memory, or >= 1 for block memory       |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the number of register stages in the port B read data pipeline. Read data output to port doutb takes this   |
| number of clkb cycles (clka when CLOCKING_MODE is "common_clock").                                                  |
| To target block memory, a value of 1 or larger is required: 1 causes use of memory latch only; 2 causes use of      |
| output register. To target distributed memory, a value of 0 or larger is required: 0 indicates combinatorial output.|
| Values larger than 2 synthesize additional flip-flops that are not retimed into memory primitives.                  |
+---------------------------------------------------------------------------------------------------------------------+
| WRITE_MODE_B            | String              | Must be "write_first", "read_first", or "no_change".                |
|                                               | For distributed memory, must be "read_first".                       |
|---------------------------------------------------------------------------------------------------------------------|
| Designate the write mode of port B:                                                                                 |
|   "write_first": Write-first write mode                                                                             |
|   "read_first": Read-first write mode                                                                               |
|   "no_change": No-change write mode                                                                                 |
| Distributed memory configurations require read-first write mode."write_first" mode is compatible only with UltraRAM |
+---------------------------------------------------------------------------------------------------------------------+
| ECC_MODE                | String              | Must be "no_ecc", "encode_only", "decode_only"                      |
|                                               | or "both_encode_and_decode".                                        |
|---------------------------------------------------------------------------------------------------------------------|
| Specify ECC mode on both ports of the memory primitive                                                              |
+---------------------------------------------------------------------------------------------------------------------+
| AUTO_SLEEP_TIME         | Integer             | Must be 0 or 3-15                                                   |
|---------------------------------------------------------------------------------------------------------------------|
| Number of clk[a|b] cycles to auto-sleep, if feature is available in architecture                                    |
|   0 : Disable auto-sleep feature                                                                                    |
|   3-15 : Number of auto-sleep latency cycles                                                                        |
|   Do not change from the value provided in the template instantiation                                               |
+---------------------------------------------------------------------------------------------------------------------+

Port usage table, organized as follows:
+---------------------------------------------------------------------------------------------------------------------+
| Port name      | Direction | Size, in bits                         | Domain | Sense       | Handling if unused      |
|---------------------------------------------------------------------------------------------------------------------|
| Description                                                                                                         |
+---------------------------------------------------------------------------------------------------------------------+
+---------------------------------------------------------------------------------------------------------------------+
| sleep          | Input     | 1                                     |        | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| sleep signal to enable the dynamic power saving feature.                                                            |
+---------------------------------------------------------------------------------------------------------------------+
| clka           | Input     | 1                                     |        | Rising edge | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Clock signal for port A. Also clocks port B when parameter CLOCKING_MODE is "common_clock".                         |
+---------------------------------------------------------------------------------------------------------------------+
| ena            | Input     | 1                                     | clka   | Active-high | Tie to 1'b1             |
|---------------------------------------------------------------------------------------------------------------------|
| Memory enable signal for port A.                                                                                    |
| Must be high on clock cycles when write operations are initiated. Pipelined internally.                             |
+---------------------------------------------------------------------------------------------------------------------+
| wea            | Input     | WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A | clka   | Active-high | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Write enable vector for port A input data port dina. 1 bit wide when word-wide writes are used.                     |
| In byte-wide write configurations, each bit controls the writing one byte of dina to address addra.                 |
| For example, to synchronously write only bits [15:8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be 4'b0010.   |
+---------------------------------------------------------------------------------------------------------------------+
| addra          | Input     | ADDR_WIDTH_A                          | clka   |             | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Address for port A write operations.                                                                                |
+---------------------------------------------------------------------------------------------------------------------+
| dina           | Input     | WRITE_DATA_WIDTH_A                    | clka   |             | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Data input for port A write operations.                                                                             |
+---------------------------------------------------------------------------------------------------------------------+
| injectsbiterra | Input     | 1                                     | clka   | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Controls single bit error injection on input data when ECC enabled (Error injection capability is not available in  |
| "decode_only" mode).                                                                                                |
+---------------------------------------------------------------------------------------------------------------------+
| injectdbiterra | Input     | 1                                     | clka   | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Controls double bit error injection on input data when ECC enabled (Error injection capability is not available in  |
| "decode_only" mode).                                                                                                |
+---------------------------------------------------------------------------------------------------------------------+
| clkb           | Input     | 1                                     |        | Rising edge | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Clock signal for port B when parameter CLOCKING_MODE is "independent_clock".                                        |
| Unused when parameter CLOCKING_MODE is "common_clock".                                                              |
+---------------------------------------------------------------------------------------------------------------------+
| rstb           | Input     | 1                                     | *      | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Reset signal for the final port B output register stage.                                                            |
| Synchronously resets output port doutb to the value specified by parameter READ_RESET_VALUE_B.                      |
+---------------------------------------------------------------------------------------------------------------------+
| enb            | Input     | 1                                     | *      | Active-high | Tie to 1'b1             |
|---------------------------------------------------------------------------------------------------------------------|
| Memory enable signal for port B.                                                                                    |
| Must be high on clock cycles when read operations are initiated. Pipelined internally.                              |
+---------------------------------------------------------------------------------------------------------------------+
| regceb         | Input     | 1                                     | *      | Active-high | Tie to 1'b1             |
|---------------------------------------------------------------------------------------------------------------------|
| Clock Enable for the last register stage on the output data path.                                                   |
+---------------------------------------------------------------------------------------------------------------------+
| addrb          | Input     | ADDR_WIDTH_B                          | *      |             | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Address for port B read operations.                                                                                 |
+---------------------------------------------------------------------------------------------------------------------+
| doutb          | Output    | READ_DATA_WIDTH_B                     | *      |             | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Data output for port B read operations.                                                                             |
+---------------------------------------------------------------------------------------------------------------------+
| sbiterrb       | Output    | 1                                     | *      | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Status signal to indicate single bit error occurrence on the data output of port B.                                 |
+---------------------------------------------------------------------------------------------------------------------+
| dbiterrb       | Output    | 1                                     | *      | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Status signal to indicate double bit error occurrence on the data output of port B.                                 |
+---------------------------------------------------------------------------------------------------------------------+
| * clka when parameter CLOCKING_MODE is "common_clock". clkb when parameter CLOCKING_MODE is "independent_clock".    |
+---------------------------------------------------------------------------------------------------------------------+
*/

//  xpm_memory_sdpram   : In order to incorporate this function into the design, the following instance declaration
//       Verilog        : needs to be placed in the body of the design code.  The default values for the parameters
//       instance       : may be changed to meet design requirements.  The instance name (xpm_memory_sdpram)
//     declaration      : and/or the port declarations within the parenthesis may be changed to properly reference and
//         code         : connect this function to the design.  All inputs and outputs must be connected.

//  <--Cut the following instance declaration and paste it into the design-->

// xpm_memory_sdpram: Simple Dual Port RAM
// Xilinx Parameterized Macro, Version 2017.3
`include "mailbox_defines.svh"
//import mailbox_global_defines_pkg::*;

`timescale 1ns/1ps

module qdma_v2_0_1_mailbox_xpm_sdpram_wrap
  #(
    parameter MEM_W=128,
    parameter ADR_W=9,  
    parameter WBE_W=1,
    parameter PAR_W=MEM_W/8,  
    parameter ECC_ENABLE=1,  
    parameter PARITY_ENABLE=0,  
    parameter RDT_FFOUT=1		// rdt flop-out
  ) (
  input logic                  clk,
  input logic                  rst,    
  input logic  [WBE_W-1:0]     we,
  input logic  [ADR_W-1:0]     wad,
  input logic  [MEM_W-1:0]     wdt,
  input logic  [PAR_W-1:0]     wpar,    
  input logic                  re,
  input logic  [ADR_W-1:0]     rad,
  output logic [MEM_W-1:0]     rdt,
  output logic [PAR_W-1:0]     rpar,    
  output logic                 sbe,
  output logic                 dbe
);


localparam DEPTH=2**ADR_W;
 
localparam TOTAL_MEM_W = PARITY_ENABLE ? (MEM_W + PAR_W) : MEM_W;

logic [WBE_W-1:0][TOTAL_MEM_W/WBE_W-1:0]  rdt_sub;
logic [WBE_W-1:0][TOTAL_MEM_W/WBE_W-1:0]  wdata_sub; 

always_comb begin
    for (int i =0 ; i < WBE_W; i = i+1) begin
        if (PARITY_ENABLE) begin
            wdata_sub[i] = {wpar[i*PAR_W/WBE_W +: PAR_W/WBE_W], wdt[i*MEM_W/WBE_W +: MEM_W/WBE_W]};
        end
        else begin
            wdata_sub[i] = wdt[i*MEM_W/WBE_W +: MEM_W/WBE_W];
        end    
    end    
end   

always_comb begin
    for (int i =0 ; i < WBE_W; i = i+1) begin
        if (PARITY_ENABLE) begin
            {rpar[i*PAR_W/WBE_W +: PAR_W/WBE_W], rdt[i*MEM_W/WBE_W +: MEM_W/WBE_W]} = rdt_sub[i];
        end   
        else begin
            rdt[i*MEM_W/WBE_W +: MEM_W/WBE_W]      = rdt_sub[i];
            rpar[i*PAR_W/WBE_W +: PAR_W/WBE_W] = '0;
        end    
    end
end    

`ifndef MAILBOX_SOFT_IP
    // HARD IP
    genvar var_i;
    generate
    for (var_i =0 ; var_i < WBE_W; var_i = var_i+1)
    begin : mem_simple_dport_ram_inst_loop
        qdma_v2_0_1_mem_simple_dport_ram #(
            .MEM_W (TOTAL_MEM_W/WBE_W),
            .ADR_W (ADR_W),
            .DEPTH (DEPTH),
            .RDT_FFOUT(RDT_FFOUT)
        ) mem_simple_dport_ram_inst (
            .clk    (clk),
            .we     (we[var_i]),
            .wad    (wad),
            .wdt    (wdata_sub[var_i]),
            .re     (re),
            .rad    (rad),
            .rdt    (rdt_sub[var_i])
        );
    end
    endgenerate

    assign  sbe = 1'b0;
    assign  dbe = 1'b0;

`else
    // SOFT IP
//    localparam MEMORY_PRIMITIVE = (DEPTH >= 2048)                     ? "ultra" : 
//                                  ((DEPTH < 2048) && (DEPTH >= 64))   ? "block" :
//                                                                        "distributed";
    localparam MEMORY_PRIMITIVE = "block";

    localparam ECC_MODE         = ECC_ENABLE ? ((MEMORY_PRIMITIVE == "ultra")        ? "both_encode_and_decode" :
                                                (MEMORY_PRIMITIVE == "block")        ? "both_encode_and_decode" :
                                                                                       "no_ecc")      : 
                                                                                       "no_ecc";
                                     
    localparam WRITE_MODE_B     = "read_first";

    localparam READ_LATENCY_B   = RDT_FFOUT+1; 
    localparam MEMORY_SIZE      = TOTAL_MEM_W/WBE_W * DEPTH;


    logic [WBE_W-1:0]    sbe_sub, dbe_sub;

    // Generate the read enable of Port B
    logic                enb, enb_nxt, enb_stop;
    logic [2:0]          read_latency_b_cnt, read_latency_b_cnt_nxt;

    always_comb begin
        if (re) begin
            enb_nxt = 1'b1;
        end 
        else if (enb_stop) begin
            enb_nxt = 1'b0;
        end   
        else begin
            enb_nxt = enb;
        end    
    end  

    assign enb_stop = (read_latency_b_cnt == READ_LATENCY_B);

    // Counter for the read latency B
    always_comb begin
        if (re) begin
            read_latency_b_cnt_nxt = 4'h1;
        end 
        else if (enb_stop) begin
            read_latency_b_cnt_nxt = 4'h0;
        end   
        else if (enb) begin
            read_latency_b_cnt_nxt = read_latency_b_cnt+1;
        end    
        else begin
            read_latency_b_cnt_nxt = read_latency_b_cnt;
        end    
    end    

    always_ff@(posedge clk, posedge rst)    
    begin 
        if (rst) begin
            enb                 <= 1'b0;
            read_latency_b_cnt  <= 0;
        end
        else begin
            enb                 <= enb_nxt;
            read_latency_b_cnt  <= read_latency_b_cnt_nxt;
        end
    end  

    genvar var_i;
    generate
    for (var_i =0 ; var_i < WBE_W; var_i = var_i+1)
    begin : xpm_memory_sdpram_inst_loop    
        xpm_memory_sdpram # (
        
          // Common module parameters
          .MEMORY_SIZE             (MEMORY_SIZE),           //positive integer
          .MEMORY_PRIMITIVE        (MEMORY_PRIMITIVE),      //string; "auto", "distributed", "block" or "ultra";
          .CLOCKING_MODE           ("common_clock"),        //string; "common_clock", "independent_clock" 
          .MEMORY_INIT_FILE        ("none"),                //string; "none" or "<filename>.mem" 
          .MEMORY_INIT_PARAM       (""    ),                //string;
          .USE_MEM_INIT            (1),                     //integer; 0,1
          .WAKEUP_TIME             ("disable_sleep"),       //string; "disable_sleep" or "use_sleep_pin" 
          .MESSAGE_CONTROL         (0),                     //integer; 0,1
          .ECC_MODE                (ECC_MODE),              //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
          .AUTO_SLEEP_TIME         (0),                     //Do not Change
        //  .USE_EMBEDDED_CONSTRAINT (0),                     //integer: 0,1
        
          // Port A module parameters
//Chris Edit .WRITE_DATA_WIDTH_A      (TOTAL_MEM_W/WBE_W),     //positive integer
//Chris Edit .BYTE_WRITE_WIDTH_A      (TOTAL_MEM_W/WBE_W),     //integer; 8, 9, or WRITE_DATA_WIDTH_A value
//DATA_WIDTH must be minimum 64-bit
          .WRITE_DATA_WIDTH_A      (((TOTAL_MEM_W/WBE_W) < 64) ? 64 : (TOTAL_MEM_W/WBE_W)),     //positive integer
          .BYTE_WRITE_WIDTH_A      (((TOTAL_MEM_W/WBE_W) < 64) ? 64 : (TOTAL_MEM_W/WBE_W)),     //integer; 8, 9, or WRITE_DATA_WIDTH_A value
          .ADDR_WIDTH_A            (ADR_W),                 //positive integer
        
          // Port B module parameters
//          .READ_DATA_WIDTH_B       (TOTAL_MEM_W/WBE_W),     //positive integer
          .ADDR_WIDTH_B            (ADR_W),                 //positive integer
          .READ_RESET_VALUE_B      ("0"),                   //string
          .READ_LATENCY_B          (READ_LATENCY_B),        //non-negative integer
          .WRITE_MODE_B            (WRITE_MODE_B)           //string; "write_first", "read_first", "no_change" 
        
        ) xpm_memory_sdpram_inst (
        
          // Common module ports
          .sleep          (1'b0),
        
          // Port A module ports
          .clka           (clk),
          .ena            (we[var_i]),
          .wea            (we[var_i]),
          .addra          (wad),
          .dina           (wdata_sub[var_i]),
          .injectsbiterra (1'b0),
          .injectdbiterra (1'b0),
        
          // Port B module ports
          .clkb           (clk),
          .rstb           (rst),
          .enb            (re),
          .regceb         (enb),
          .addrb          (rad),
          .doutb          (rdt_sub[var_i]),
          .sbiterrb       (sbe_sub[var_i]),
          .dbiterrb       (dbe_sub[var_i])
        );
    end
    endgenerate

    assign    sbe = |sbe_sub;
    assign    dbe = |dbe_sub;

`endif

endmodule 

`endif   // MAILBOX_XPM_SDPRAM_WRAP_SV
				
