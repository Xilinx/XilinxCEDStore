// PACKAGE : custom_axi_tg_pkg
//
// DESCRIPTION:
// Shared constants for custom_axi_tg: the instruction-word bit layout, the
// opcode and run-state encodings, the AXI response codes and the bit positions
// of the TG_BRESP_ERROR sticky log.  These are gathered in one place so that
// the AXI-Lite assembly logic (custom_axi_tg_csr), the fetch sequencer
// (custom_axi_tg_seq) and both dispatchers cannot drift apart.
//
// DETAILS:
// The instruction word is a FIXED-WIDTH UNION: identical physical width for all
// opcodes, fields overlaid per opcode, and the field positions do NOT shrink
// with AXI_ADDRESS_WIDTH / AXI_ID_WIDTH.  Holding the layout fixed at the
// maximum widths keeps a compiled program portable across parameterisations.
// Every field is wholly contained inside one 32-bit AXI-Lite slice, so
// software can pack each programming word independently.
//
// Layout notes:
//  - Opcode 2'b11 is RESERVED and not executable.  Committing it returns
//    SLVERR + ERR_RSVD_OPCODE.
//  - The run state is 3 bits wide because the drain phase needs its own state
//    (ST_STOPPING) distinct from both running and idle.
//  - IRAM_WIDTH is 192 = 6 slices.  The 12-bit repeat_count sits in the hole
//    at [59:48] rather than taking a slice of its own, which is what keeps the
//    word to six 32-bit AXI-Lite writes instead of seven.
//
// ACRONYMS:
//  - IW   = instruction word
//  - LSB  = least significant bit position of a field
//  - iRAM = instruction RAM

package custom_axi_tg_pkg;

  //--------------------------------------------------------------------------
  // Instruction word geometry and field positions
  //--------------------------------------------------------------------------
  localparam int IRAM_WIDTH          = 192;   // 6 x 32b slices; still 3 RAMB36E5
  localparam int IRAM_DEPTH          = 512;   // full BRAM depth (a 36Kb BRAM is 512x72)
  localparam int IRAM_SLICES         = 6;     // 192/32 AXI-Lite words per command

  localparam int IW_OPCODE_LSB       =   0;   // 2b, all opcodes
  localparam int IW_ADDR_MODE        =   2;   // 1b, WRITE/READ
  localparam int IW_ID_MODE          =   3;   // 1b, WRITE/READ
  localparam int IW_DATA_MODE        =   4;   // 1b, WRITE
  localparam int IW_WUSER_POISON     =   5;   // 1b, WRITE
  localparam int IW_ARUSER_CMD_LSB   =   6;   // 2b, READ
  localparam int IW_ADDR_K_LSB       =   8;   // 5b, WRITE/READ (0..26 after clamp)
  localparam int IW_BE_K_LSB         =  13;   // 3b, WRITE      (0..6)
  localparam int IW_START_ID_LSB     =  16;   // 4b, WRITE/READ
  localparam int IW_ID_STRIDE_LSB    =  20;   // 4b, WRITE/READ
  localparam int IW_ADDR_HI_LSB      =  32;   // 16b, start_address[47:32]
  localparam int IW_REPEAT_LSB       =  48;   // 12b, WRITE/READ
  localparam int IW_ADDR_LO_LSB      =  64;   // 32b, start_address[31:0]
  localparam int IW_ADDR_STRIDE_LSB  =  96;   // 32b, WRITE/READ
  localparam int IW_DATA_START_LSB   = 128;   // 32b, WRITE
  localparam int IW_DATA_STRIDE_LSB  = 160;   // 32b, WRITE

  localparam int ADDR_K_MAX          =  26;   // values above this clamp at commit
  // be_prob_k has no analogous max: all 8 encodings of its 3-bit field are
  // legal (0..6 select a partial-BE probability, 7 forces WSTRB='1 always).

  //--------------------------------------------------------------------------
  // Opcodes.  OP_RSVD is NOT executable: a commit of it is rejected with
  // SLVERR, so the sequencer can never fetch one.  Defensively, the fetch
  // router treats OP_RSVD exactly like OP_WAIT - the safe direction, since a
  // WAIT only drains and cannot generate traffic.
  //--------------------------------------------------------------------------
  localparam logic [1:0] OP_WRITE = 2'b00,
                         OP_READ  = 2'b01,
                         OP_WAIT  = 2'b10,
                         OP_RSVD  = 2'b11;

  //--------------------------------------------------------------------------
  // Exported run state (TG_STATUS.STATE / o_state).
  // STOPPING exists because a stopped-but-draining TG is none of the other
  // four: it is not IDLE (transactions outstanding), not IN_PROG (not
  // issuing), and labelling it ALL_REQUESTED would falsely imply the program
  // completed normally.
  //--------------------------------------------------------------------------
  localparam logic [2:0] ST_IDLE          = 3'd0,
                         ST_IN_PROG       = 3'd1,
                         ST_ALL_REQUESTED = 3'd2,
                         ST_ALL_RESPONDED = 3'd3,
                         ST_STOPPING      = 3'd4;

  //--------------------------------------------------------------------------
  // AXI response codes
  //--------------------------------------------------------------------------
  localparam logic [1:0] RESP_OKAY   = 2'b00,
                         RESP_EXOKAY = 2'b01,
                         RESP_SLVERR = 2'b10,
                         RESP_DECERR = 2'b11;

  //--------------------------------------------------------------------------
  // TG_BRESP_ERROR bit positions (also used as FIRST_ERR_CODE values)
  //--------------------------------------------------------------------------
  localparam int ERR_GAP            = 0;  // write to entry N>0, entry N-1 unprogrammed
  localparam int ERR_RSVD_OPCODE    = 1;  // commit of opcode 2'b11
  localparam int ERR_BUSY_IRAM      = 2;  // iRAM / TG_DONE_PTR access while running
  localparam int ERR_IDX_RANGE      = 3;  // cmd_idx >= MAX_COMMANDS
  localparam int ERR_ASSY_IDX       = 4;  // slice write targeted another command
  localparam int ERR_UNMAPPED       = 5;  // unmapped or non-word-aligned access
  localparam int ERR_RSVD_SLICE     = 6;  // access to +0x18 or +0x1C in a command
  localparam int ERR_DONE_PTR_RANGE = 7;  // TG_DONE_PTR beyond the programmed region
  localparam int ERR_START_BUSY     = 8;  // TG_CTRL.START=1 while busy
  localparam int ERR_SOFT_RST_BUSY  = 9;  // TG_CTRL.SOFT_RESET=1 while busy

  localparam int ERR_BITS           = 10; // width of the sticky log

  //--------------------------------------------------------------------------
  // Misc
  //--------------------------------------------------------------------------
  localparam logic [31:0] TG_ID_VALUE   = 32'h5447_0200;  // "TG", version 2.0
  localparam logic [31:0] TG_BUSY_RDATA = 32'h4255_5359;  // ASCII "BUSY", 'B' in [31:24]

endpackage
