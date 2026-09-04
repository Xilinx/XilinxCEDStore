# hwtg_help.tcl
#
# Command reference: COMMANDS (display order), CMD_SUMMARY (one-liner),
# CMD_HELP (detailed Args/Notes text, optional per command). Printed via
# the shared ::pkg_help (pkg_help.tcl) through the help/h wrappers below.

namespace eval hwtg {
  variable COMMANDS {
    connect
    load_append load_at load_interactive load_from_file
    read_cmd read_all dump_to_file
    parse_errors clear_errors
    start stop soft_reset status wait_done tg_cfg
    ext_trigger ext_trigger_all
  }

  array set CMD_SUMMARY {
    connect          "select the DPC xsdb target"
    load_append      "program at the next free index"
    load_at          "program (or reprogram) a specific index"
    load_interactive "prompts for index/opcode/fields on stdin"
    load_from_file   "one mnemonic per line, loaded in file order via load_append"
    read_cmd         "disassemble one committed command"
    read_all         "print+disassemble every committed command (0..TG_DONE_PTR-1)"
    dump_to_file     "read_all, written in load_from_file format"
    parse_errors     "decode TG_BRESP_ERROR's sticky bits plus any per-command SLVERR/invalid-response entries"
    clear_errors     "clear the sticky TG_BRESP_ERROR log (W1C)"
    start            "start the datapath (must be IDLE or ALL_RESPONDED)"
    stop             "request stop (state moves to STOPPING until drain completes)"
    soft_reset       "clear programmed state (iRAM content untouched)"
    status           "human-readable TG_STATUS dump"
    wait_done        "poll until ALL_RESPONDED/IDLE"
    tg_cfg           "live-read TG_CFG (max_commands/axi_id_width/etc.)"
    ext_trigger      "via axil_gpio4, pulse tg_start on the given datapath(s) on the same clock edge"
    ext_trigger_all  "ext_trigger, defaulting to every discovered datapath"
  }

  # Shared grammar block for every command that takes/produces a mnemonic
  # "OPCODE key=val ..." line (load_append/load_at/load_interactive/
  # load_from_file, and indirectly read_cmd/read_all/dump_to_file). Kept in
  # sync by hand with hwtg_asm.tcl's ASM_KEYS and hwtg_pkg.tcl's FIELDS.
  proc field_grammar_text {} {
    return [join {
      {Command line grammar: "OPCODE key=val key=val ..." (opcode required;}
      {unknown key/opcode is a hard error). Values are decimal or}
      {0x-prefixed hex. Opcodes: WRITE, READ, WAIT. "addr" is REQUIRED on}
      {WRITE/READ (a hard error if omitted); every other key is optional --}
      {defaulting to 0, EXCEPT "be_k" on WRITE, which defaults to 7 (always}
      {full WSTRB) instead of 0.}
      {}
      {WRITE fields:}
      {  addr         REQUIRED. 48-bit start address (packed into}
      {               addr_hi[15:0]:addr_lo[31:0])}
      {  id           4-bit start_id (only [AXI_ID_WIDTH-1:0] actually used)}
      {  id_stride    4-bit; id_next = id + id_stride (when id_mode=0)}
      {  id_mode      1-bit; 0=stride, 1=lfsr8}
      {  repeat       12-bit repeat_count}
      {  addr_k       5-bit; moving-address-bits count, legal range 0..26}
      {               (27..31 silently clamp to 26 at commit)}
      {  addr_stride  32-bit; addr_next = addr + addr_stride (when addr_mode=0)}
      {  addr_mode    1-bit; 0=stride, 1=lfsr27}
      {  be_k         3-bit; default 7 (always full WSTRB) if omitted.}
      {               0..6 select a partial-byte-enable probability instead,}
      {               7=always full WSTRB}
      {  poison       1-bit WUSER poison bit}
      {  data_start   32-bit data pattern start value (data_mode=0, counter}
      {               mode); ignored if data_mode=1}
      {  data_stride  32-bit data pattern stride (data_mode=0, counter mode);}
      {               ignored if data_mode=1}
      {  data_mode    1-bit; 0=counter, 1=lfsr64}
      {}
      {READ fields:}
      {  addr, id, id_stride, repeat, addr_k, addr_stride, addr_mode -- same}
      {  meaning as WRITE (addr is REQUIRED here too; be_k does not apply}
      {  to READ)}
      {  aruser_cmd   2-bit raw passthrough to the bridge}
      {}
      {WAIT fields: none.}
      {}
      {Examples:}
      {  WRITE addr=0x1000 id=0 id_stride=1 repeat=100 addr_k=4 addr_stride=64 be_k=7 poison=0 data_start=0x0 data_stride=1}
      {  READ  addr=0x2000 id=1 id_stride=1 repeat=50 addr_k=0 addr_stride=64 aruser_cmd=0}
      {  WAIT}
    } "\n"]
  }

  # Per-command detailed help. Anything not listed here falls back to just
  # the one-line summary from CMD_SUMMARY.
  array set CMD_HELP {}

  set CMD_HELP(connect) [join {
    {No args.}
    {}
    {Selects the DPC (PMC Debug Packet Controller) xsdb target, printing}
    {the specific target index and name landed on (e.g. "target 2 (DPC)").}
    {Independent of design::connect -- it's purely a board-specific}
    {target-selection step.}
  } "\n"]

  set CMD_HELP(load_append) [join [list \
    "Args:" \
    "  cpi   -- datapath index (must exist per design::discover; see" \
    "           design::get_cxl_indices)" \
    "  line  -- mnemonic command line, see grammar below" \
    "" \
    "Programs at the next free (unprogrammed) index on that datapath;" \
    "errors if the iRAM is full (MAX_COMMANDS=32) or the datapath isn't" \
    "IDLE." \
    "" \
    [field_grammar_text] \
  ] "\n"]

  set CMD_HELP(load_at) [join [list \
    "Args:" \
    "  cpi   -- datapath index" \
    "  idx   -- iRAM index to program (0..MAX_COMMANDS-1); must be the" \
    "           next contiguous index (idx-1 already programmed), or 0" \
    "  line  -- mnemonic command line, see grammar below" \
    "" \
    "Reprogramming an already-programmed idx is allowed (as long as it's a" \
    "committed, contiguous slot); the datapath must be IDLE." \
    "" \
    [field_grammar_text] \
  ] "\n"]

  set CMD_HELP(load_interactive) [join [list \
    "Args:" \
    "  cpi -- datapath index" \
    "" \
    "Prompts on stdin for: index (blank = append), opcode (WRITE/READ/WAIT)," \
    "then each field valid for that opcode (blank = default 0). See the" \
    "field grammar below for what each field means and its legal range." \
    "" \
    [field_grammar_text] \
  ] "\n"]

  set CMD_HELP(load_from_file) [join [list \
    "Args:" \
    "  cpi   -- datapath index" \
    "  path  -- file containing one mnemonic command per line (blank lines" \
    "           and lines starting with '#' are skipped)" \
    "" \
    "Each line is loaded in file order via hwtg::load_append (i.e. always" \
    "appended, never at an explicit index)." \
    "" \
    [field_grammar_text] \
  ] "\n"]

  set CMD_HELP(read_cmd) [join {
    {Args:}
    {  cpi -- datapath index}
    {  idx -- iRAM index to read back (0..TG_DONE_PTR-1)}
    {}
    {Returns the disassembled mnemonic line for that index (same grammar as}
    {load_append/load_at -- see "hwtg::help load_append"). Requires the}
    {datapath be IDLE (readback shares the sequencer's port B).}
  } "\n"]

  set CMD_HELP(read_all) [join {
    {Args:}
    {  cpi -- datapath index}
    {}
    {Disassembles every committed command, idx 0 through TG_DONE_PTR-1 (see}
    {"hwtg::help load_append" for the grammar), printing them along the way.}
    {Returns them as a list of mnemonic lines. Requires the datapath be}
    {IDLE.}
  } "\n"]

  set CMD_HELP(dump_to_file) [join {
    {Args:}
    {  cpi  -- datapath index}
    {  path -- output file path (overwritten)}
    {}
    {Writes the result of hwtg::read_all, one mnemonic line per line, in}
    {the same format hwtg::load_from_file expects.}
  } "\n"]

  set CMD_HELP(parse_errors) [join {
    {Args:}
    {  cpi -- datapath index}
    {}
    {Decodes TG_BRESP_ERROR's sticky bits (hwtg::ERR_NAMES): ERR_GAP,}
    {ERR_RSVD_OPCODE, ERR_BUSY_IRAM, ERR_IDX_RANGE, ERR_ASSY_IDX,}
    {ERR_UNMAPPED, ERR_RSVD_SLICE, ERR_DONE_PTR_RANGE, ERR_START_BUSY,}
    {ERR_SOFT_RST_BUSY -- plus the first-error index/code -- plus, for}
    {every committed command 0..TG_DONE_PTR-1, any per-command SLVERR (with}
    {the first invalid transaction # and AXI ID) or non-OKAY response seen.}
    {Returns the list of active sticky error names.}
  } "\n"]

  set CMD_HELP(clear_errors) [join {
    {Args:}
    {  cpi -- datapath index}
    {}
    {Write-1-to-clear on TG_BRESP_ERROR (all 10 sticky bits). Does not}
    {affect per-command status words.}
  } "\n"]

  set CMD_HELP(start) [join {
    {Args:}
    {  cpi -- datapath index}
    {}
    {Writes TG_CTRL=0x1. Only legal from state IDLE or ALL_RESPONDED}
    {(errors otherwise).}
  } "\n"]

  set CMD_HELP(stop) [join {
    {Args:}
    {  cpi -- datapath index}
    {}
    {Writes TG_CTRL=0x0, requesting a stop. State moves to STOPPING until}
    {the in-flight drain completes; poll hwtg::status / hwtg::wait_done.}
  } "\n"]

  set CMD_HELP(soft_reset) [join {
    {Args:}
    {  cpi -- datapath index}
    {}
    {Writes TG_CTRL=0x2. Only legal from state IDLE or ALL_RESPONDED}
    {(matches the hardware's own ERR_SOFT_RST_BUSY check). Clears}
    {programmed state (hwtg::next_free_index resets to 0); iRAM contents}
    {themselves are left untouched.}
  } "\n"]

  set CMD_HELP(status) [join {
    {Args:}
    {  cpi -- datapath index}
    {}
    {Prints and returns the raw TG_STATUS word, decoded: state}
    {(IDLE/IN_PROG/ALL_REQUESTED/ALL_RESPONDED/STOPPING), cur_cmd_ptr,}
    {done_ptr (from TG_DONE_PTR), wr_busy, rd_busy, wr_ring_empty/full,}
    {rd_ring_empty/full, start_busy_err, any_cmd_err.}
  } "\n"]

  set CMD_HELP(wait_done) [join {
    {Args:}
    {  cpi          -- datapath index}
    {  [timeout_s]  -- seconds to poll before raising an error. Default: 5.}
    {}
    {Polls hwtg::run_state_name every 50ms until it reports ALL_RESPONDED}
    {or IDLE, or the timeout elapses.}
  } "\n"]

  set CMD_HELP(tg_cfg) [join {
    {Args:}
    {  cpi -- datapath index}
    {}
    {Live-reads TG_CFG and returns a dict: axi_address_width,}
    {axi_id_width, axi_axil_sync, max_commands, ring_depth, cpq_depth. Use}
    {this if you suspect the hwtg_pkg.tcl constants (e.g. MAX_COMMANDS)}
    {have drifted from the live hardware build.}
  } "\n"]

  set CMD_HELP(ext_trigger) [join {
    {Args:}
    {  cpi_list -- list of datapath indices to trigger (e.g. {0 2}); each}
    {             must be 0..3, axil_gpio4's 4 output bits. Required --}
    {             errors if omitted/empty (use ext_trigger_all for every}
    {             discovered datapath).}
    {}
    {Pulses tg_start on every listed datapath on the SAME clock edge via}
    {axil_gpio4's external i_start pins (GPIO_MODE/GPIO_GPIO), instead of}
    {looping each TG's own AXI-Lite TG_CTRL.START (N separate, skewed}
    {transactions). Requires design::discover to have found axil_gpio4_0's}
    {base address. Automatically puts the targeted GPIO bits into}
    {self-clearing pulse mode first, so no separate "release i_start" step}
    {is needed.}
  } "\n"]

  set CMD_HELP(ext_trigger_all) [join {
    {Args:}
    {  [cpi_list] -- default: every datapath from design::get_cxl_indices.}
    {}
    {Same as ext_trigger, but defaults to every discovered datapath instead}
    {of requiring cpi_list.}
  } "\n"]

  proc help {{cmd ""}} { return [::pkg_help hwtg $cmd] }
  proc h {{cmd ""}} { return [help $cmd] }
}
