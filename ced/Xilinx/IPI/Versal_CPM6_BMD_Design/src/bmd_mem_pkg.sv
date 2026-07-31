package bmd_mem_pkg;

localparam logic [6:0]      MAX_CSR         = 7'h19;

//////////////////////////////////////////////////////////////////
//                       Device Control
//////////////////////////////////////////////////////////////////
localparam logic [6:0]      DCSR1           = 7'h00; // Byte: 000h
localparam logic [6:0]      DCSR2           = 7'h01; // Byte: 004h

//////////////////////////////////////////////////////////////////
//                        TLP Control
//////////////////////////////////////////////////////////////////
localparam logic [6:0]      WDMATLPA        = 7'h02; // Byte: 008h
localparam logic [6:0]      WDMATLPS        = 7'h03; // Byte: 00Ch
localparam logic [6:0]      WDMATLPUA       = 7'h04; // Byte: 010h
localparam logic [6:0]      WDMATLPC        = 7'h05; // Byte: 014h
localparam logic [6:0]      WDMATLPP        = 7'h06; // Byte: 018h
localparam logic [6:0]      RDMATLPP        = 7'h07; // Byte: 01Ch
localparam logic [6:0]      RDMATLPA        = 7'h08; // Byte: 020h
localparam logic [6:0]      RDMATLPS        = 7'h09; // Byte: 024h
localparam logic [6:0]      RDMATLPUA       = 7'h0A; // Byte: 028h
localparam logic [6:0]      RDMATLPC        = 7'h0B; // Byte: 02Ch
localparam logic [6:0]      DMATLPTYPE      = 7'h18; // Byte: 060h
localparam logic [6:0]      DMAEXT          = 7'h11; // Byte: 044h
localparam logic [6:0]      DMAEXT2         = 7'h12; // Byte: 048h
localparam logic [6:0]      DMAMSIX         = 7'h19; // Byte: 064h

//////////////////////////////////////////////////////////////////
//                        TLP Prefixes
//////////////////////////////////////////////////////////////////
localparam logic [6:0]      DMATPH          = 7'h0C; // Byte: 030h
localparam logic [6:0]      WDMAIDE         = 7'h0D; // Byte: 034h
localparam logic [6:0]      RDMAIDE         = 7'h0E; // Byte: 038h
localparam logic [6:0]      WDMAPASID       = 7'h0F; // Byte: 03Ch
localparam logic [6:0]      RDMAPASID       = 7'h10; // Byte: 040h

//////////////////////////////////////////////////////////////////
//                  Performance & Statistics
//////////////////////////////////////////////////////////////////
localparam logic [6:0]      WDMAPERF        = 7'h13; // Byte: 04Ch
localparam logic [6:0]      RDMAPERF        = 7'h14; // Byte: 050h
localparam logic [6:0]      RDMASTAT1       = 7'h15; // Byte: 054h
localparam logic [6:0]      RDMASTAT2       = 7'h16; // Byte: 058h
localparam logic [6:0]      RDMASTAT3       = 7'h17; // Byte: 05Ch

endpackage