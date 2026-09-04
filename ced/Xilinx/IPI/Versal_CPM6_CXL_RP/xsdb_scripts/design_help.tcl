# design_help.tcl
#
# Command reference: COMMANDS (display order), CMD_SUMMARY (one-liner),
# CMD_HELP (detailed Args/Notes text, optional per command). Printed via
# the shared ::pkg_help (pkg_help.tcl) through the help/h wrappers below.
#
namespace eval design {
  variable COMMANDS {
    discover set_clk_hz
    get_tg_base get_gpio_base get_uram_base get_clk_hz
    get_num_cpi get_cxl_indices
    connect
    program check_link_status
    setup_mio_as_gpio verify_mio drive_mio rmw
  }

  array set CMD_SUMMARY {
    discover             "parse the generated .hwh once:\
custom_axi_tg/axil_gpio4/uram_sdp_4Kx44 base addresses + cxl1_clk frequency"
    set_clk_hz           "manually set/override the CXL clock frequency"
    get_tg_base          "custom_axi_tg base address for a datapath"
    get_gpio_base        "axil_gpio4_0 base address"
    get_uram_base        "uram_sdp_4Kx44 base address for a (cpi, interface) pair"
    get_clk_hz           "the discovered/set cxl1_clk frequency in Hz"
    get_num_cpi          "number of datapaths discovered"
    get_cxl_indices      "list of discovered CXL datapath indices"
    connect              "select the JTAG target (shared by every package)"
    program              "full board bring-up: program boot.pdi/pld.pdi, toggle PERSTN, check the link"
    check_link_status    "read and print CPM6 Ctrl1's link state"
    setup_mio_as_gpio    "configure a MIO pin for GPIO use"
    verify_mio           "verify a MIO-as-GPIO pin's configuration"
    drive_mio            "drive (or pulse) a MIO-as-GPIO output pin"
    rmw                  "generic read-modify-write"
  }

  array set CMD_HELP {}

  set CMD_HELP(discover) [join {
    {Args:}
    {  [proj_dir_or_hwh_path] -- a generated project directory (the parent}
    {  of p.gen/p.sim/...) or the exact top-level block-design .hwh file}
    {  path. Default: "./".}
    {}
    {Notes:}
    {  - No hardware/JTAG connection required; this only parses the .hwh XML.}
    {  - Populates: per-cpi custom_axi_tg base addresses, axil_gpio4_0's}
    {    base address, per-(cpi,iface) uram_sdp_4Kx44 base addresses, and}
    {    the cxl1_clk clock frequency.}
    {  - Warns (doesn't error) if the clock line isn't found -- address-map}
    {    discovery must still succeed either way; call set_clk_hz manually}
    {    in that case.}
    {  - Errors if the .hwh can't be found/is ambiguous, or if no}
    {    custom_axi_tg instances are present (e.g. NUM_CPI=0).}
    {  - Run design::get_cxl_indices / design::get_num_cpi afterwards}
    {    to see what was discovered.}
  } "\n"]

  set CMD_HELP(set_clk_hz) [join {
    {Args:}
    {  hz -- clock frequency in Hz (e.g. 333329987), numeric.}
    {}
    {Overrides/replaces whatever design::discover auto-discovered, or use}
    {this if auto-discovery warned that cxl1_clk wasn't found. Required}
    {before perf::latency/perf::bandwidth/perf::bandwidth_all/perf::report}
    {will produce ns/GB-s figures.}
  } "\n"]

  set CMD_HELP(get_tg_base) [join {
    {Args:}
    {  cpi -- datapath index}
    {}
    {Returns custom_axi_tg_<cpi>'s base address (used by hwtg::). Errors}
    {if design::discover hasn't been run, or cpi doesn't exist.}
  } "\n"]

  set CMD_HELP(get_gpio_base) [join {
    {No args.}
    {}
    {Returns axil_gpio4_0's base address (used by hwtg::ext_trigger/}
    {ext_trigger_all).}
    {Errors if design::discover hasn't found it.}
  } "\n"]

  set CMD_HELP(get_uram_base) [join {
    {Args:}
    {  cpi   -- datapath index}
    {  iface -- one of: f2a_req f2a_data a2f_data a2f_rsp}
    {}
    {Returns the uram_sdp_4Kx44 base address for that (cpi, iface) pair}
    {(used by perf::). Internally converts (cpi, iface) to the hardware}
    {instance index so callers never need to know that encoding.}
  } "\n"]

  set CMD_HELP(get_clk_hz) [join {
    {No args.}
    {}
    {Returns the cxl1_clk frequency in Hz (auto-discovered by}
    {design::discover, or manually set via design::set_clk_hz). Errors if}
    {neither has happened.}
  } "\n"]

  set CMD_HELP(get_num_cpi) [join {
    {No args. Returns the number of datapaths discovered by}
    {design::discover.}
  } "\n"]

  set CMD_HELP(get_cxl_indices) [join {
    {No args. Returns the list of discovered CXL datapath indices}
    {(0..num_cpi-1).}
  } "\n"]

  set CMD_HELP(connect) [join {
    {Args:}
    {  [target] -- either:}
    {    - an xsdb `targets -set -filter {name =~ "<pattern>"}` match}
    {      string, or}
    {    - a plain integer target index, in which case this does}
    {      `targets -set <index>` directly (no filter).}
    {    Default: {*Versal*xc2vp*}.}
    {}
    {Notes:}
    {  - Board/hw_server-session specific: run `targets` yourself first to}
    {    see what your JTAG chain actually enumerates, and pass whichever}
    {    form (pattern or index) matches it.}
    {  - Prints the specific target index and name actually landed on (e.g.}
    {    "target 4 (Cortex-A72 #0)"), parsed from `targets`' own listing --}
    {    same convention ecam::/hwtg::/perf::connect follow.}
    {  - The ONE connect command system-wide. Must be called (successfully)}
    {    before any control::/hwtg::/perf::/ecam:: register access will work.}
    {  - Independent of design::program's own target selection}
    {    (design::TARGET_INDEX / `targets <index>`), which is only used for}
    {    PDI programming.}
  } "\n"]

  set CMD_HELP(program) [join {
    {No args.}
    {}
    {Programs ./boot.pdi and ./pld.pdi from the current directory}
    {(existence-checked first), toggles PERSTN both externally (to the EP,}
    {MIO 41) and internally (to the RP, via a PS_GPIO/MIO19 IRQ workaround),}
    {then checks CPM6 Ctrl1's link via check_link_status. Returns 1/0 for}
    {link-up without raising an error on link-down. Uses}
    {design::TARGET_INDEX (default 1, i.e. `targets 1`, "the Versal root")}
    {for its own target selection -- board/session-specific, run `targets`}
    {yourself if index 1 doesn't select the right target on your chain.}
  } "\n"]

  set CMD_HELP(check_link_status) [join {
    {No args.}
    {}
    {Reads and prints CPM6 Ctrl1's link state (L0/speed/width), data-link-}
    {layer state, VLSM mode, and Flit mode. Hardcoded to Ctrl1 -- this CED}
    {never uses Ctrl0. Returns 1 if the link is up}
    {(smlh_link_up && rdlh_link_up), 0 otherwise.}
  } "\n"]

  set CMD_HELP(setup_mio_as_gpio) [join {
    {Args:}
    {  pin      -- MIO pin number (0-51)}
    {  dir      -- "in" or "out"}
    {  [dfault] -- initial output value (0/1); required when dir=out}
    {}
    {Configures PMC_IOU_SLCR L0/L1/L2 muxing to route the pin through}
    {GPIO1, and sets up PS_GPIO direction/output-enable/initial-value}
    {registers for the requested direction.}
  } "\n"]

  set CMD_HELP(verify_mio) [join {
    {Args:}
    {  pin     -- MIO pin number (0-51)}
    {  dir     -- "in" or "out"}
    {  [value] -- 0 or 1: also verify the pin's live DATA_RO bit matches}
    {             this value. Default: -1 (skip this check).}
    {}
    {Reads back the mux/direction/output-enable/tristate registers}
    {setup_mio_as_gpio configures and confirms they match. Returns 1 if}
    {all checks pass, 0 on any failure (prints the reason).}
  } "\n"]

  set CMD_HELP(drive_mio) [join {
    {Args:}
    {  pin    -- MIO pin number (0-51), must already be configured as a GPIO}
    {           output via setup_mio_as_gpio}
    {  action -- one of: hi, lo, pulse_hi (lo->hi), pulse_lo (hi->lo)}
    {}
    {Calls verify_mio first to confirm the pin is a properly configured}
    {output, then drives it via the MASK_DATA register, reading back}
    {DATA_RO after each phase to confirm the write took effect.}
  } "\n"]

  set CMD_HELP(rmw) [join {
    {Args:}
    {  addr  -- register address}
    {  mask  -- bits being modified (1 = write this bit, 0 = preserve it)}
    {  value -- new value for the masked bits}
    {}
    {Generic read-modify-write: read, clear the masked bits, OR in the}
    {masked bits of value, write back.}
  } "\n"]

  proc help {{cmd ""}} { return [::pkg_help design $cmd] }
  proc h {{cmd ""}} { return [help $cmd] }
}
