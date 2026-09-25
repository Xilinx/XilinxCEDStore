// MODULE : custom_axi_tg_iram
//
// DESCRIPTION:
// Thin wrapper around the Vivado XPM_MEMORY_SDPRAM macro that holds the
// custom_axi_tg instruction RAM.  Port A is write-only and belongs to the
// AXI-Lite programming path (custom_axi_tg_csr); port B is read-only and is
// shared between the fetch sequencer and the AXI-Lite iRAM readback path.  The
// two never contend: the CSR block only reads the iRAM while the TG is IDLE.
//
// DETAILS:
//  - IRAM_WIDTH is 192, which is the smallest 32-bit multiple that holds the
//    178-bit instruction word.  A Versal RAMB36E5 in SDP mode is 512 deep by
//    72 wide, so 512 x 192 occupies EXACTLY 3 RAMB36E5 (192 <= 3 x 72 = 216);
//    two BRAMs is not an option because 2 x 72 = 144 is below 178.  Rounding
//    down to 192 rather than filling all 216 bits costs nothing in BRAM and
//    saves one AXI-Lite write and one AXI-Lite read per command - 6 32-bit
//    slices instead of 7.
//  - The depth is always 512 even though MAX_COMMANDS is 32: a 192-bit-wide
//    memory occupies 3 RAMB36E5 regardless of depth, so the full depth is
//    free and lets MAX_COMMANDS be raised to 512 with a one-line change.
//  - READ_LATENCY_B = 2 turns the BRAM output register ON, which is required
//    to close 333 MHz.
//  - enb MUST BE FREE-RUNNING WHILE FETCHING.  The sequencer issues one fetch
//    per cycle, so enb is simply iram_ren and addrb may change every cycle.
//    doutb for the address presented at cycle F is valid at F+2, with no
//    gating and no dead cycles between fetches - regceb is tied high so the
//    output stage advances unconditionally.  Pulsing enb instead would stall
//    the pipeline and is not supported by the sequencer's fixed 2-cycle
//    fetch-latency assumption.
//
// RESTRICTIONS:
//  - Single clock only (CLOCKING_MODE = "common_clock"); everything in this IP
//    lives in the AXI master clock domain.  This is what lets the fetch
//    pipeline run at one address per cycle: there is no synchroniser anywhere
//    in the fetch path.
//  - Whole-word writes only (BYTE_WRITE_WIDTH_A == WRITE_DATA_WIDTH_A).
//
// ACRONYMS:
//  - SDP  = simple dual port
//  - iRAM = instruction RAM

module custom_axi_tg_iram #(
  parameter int IRAM_WIDTH = 192,
  parameter int IRAM_DEPTH = 512       // full BRAM depth, always 512
)(
  input                         clk,    // single clock: dest_clk
  input                         rstn,
  input                         wea,
  input        [           8:0] addra,
  input        [IRAM_WIDTH-1:0] dina,
  input                         enb,
  input        [           8:0] addrb,
  output logic [IRAM_WIDTH-1:0] doutb   // READ_LATENCY_B = 2
);

  xpm_memory_sdpram #(
    .MEMORY_SIZE        (IRAM_DEPTH*IRAM_WIDTH), // 512*192 = 98304 -> 3 RAMB36E5
    .MEMORY_PRIMITIVE   ("block"),               // force BRAM, not LUTRAM/URAM
    .CLOCKING_MODE      ("common_clock"),        // both ports on clk
    .ECC_MODE           ("no_ecc"),
    .MEMORY_INIT_FILE   ("none"),
    .MEMORY_INIT_PARAM  (""),
    .USE_MEM_INIT       (1),                     // zero-init for deterministic sim
    .WAKEUP_TIME        ("disable_sleep"),
    .AUTO_SLEEP_TIME    (0),
    .MESSAGE_CONTROL    (0),
    .CASCADE_HEIGHT     (0),
    .WRITE_DATA_WIDTH_A (IRAM_WIDTH),
    .BYTE_WRITE_WIDTH_A (IRAM_WIDTH),            // whole-word write only
    .ADDR_WIDTH_A       (9),
    .RST_MODE_A         ("SYNC"),
    .READ_DATA_WIDTH_B  (IRAM_WIDTH),
    .ADDR_WIDTH_B       (9),
    .READ_RESET_VALUE_B ("0"),
    .READ_LATENCY_B     (2),                     // output register ON
    .WRITE_MODE_B       ("no_change"),
    .RST_MODE_B         ("SYNC")
  ) i_xpm_sdpram (
    .sleep              (1'b0),
    // Port A - write only (AXI-Lite commit path)
    .clka               (clk),
    .ena                (wea),
    .wea                (wea),
    .addra              (addra),
    .dina               (dina),
    .injectsbiterra     (1'b0),
    .injectdbiterra     (1'b0),
    // Port B - read only (fetch sequencer / AXI-Lite readback)
    .clkb               (clk),
    .rstb               (~rstn),
    .enb                (enb),
    .regceb             (1'b1),
    .addrb              (addrb),
    .doutb              (doutb),
    .sbiterrb           (/* unconnected - no_ecc */),
    .dbiterrb           (/* unconnected - no_ecc */)
  );

  `ifndef SYNTHESIS
  //synthesis off
  initial begin
    if (IRAM_DEPTH != 512)
      $fatal(1, $sformatf({"custom_axi_tg_iram: IRAM_DEPTH=%0d is invalid; the ",
                           "iRAM is always 512 deep (a Versal 36Kb BRAM is ",
                           "512x72 in SDP mode)"}, IRAM_DEPTH));
    if ((IRAM_WIDTH % 32 != 0) || (IRAM_WIDTH > 216))
      $fatal(1, $sformatf({"custom_axi_tg_iram: IRAM_WIDTH=%0d is invalid; it ",
                           "must be a whole number of 32-bit AXI-Lite slices ",
                           "and fit in 3 RAMB36E5 (3 x 72 = 216 bits)"},
                          IRAM_WIDTH));
  end
  //synthesis on
  `endif

endmodule
