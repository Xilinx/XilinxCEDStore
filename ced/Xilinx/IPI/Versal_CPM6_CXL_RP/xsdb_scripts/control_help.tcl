# control_help.tcl

namespace eval control {
  variable COMMANDS {
    rd32 wr32
    pl_rst_status pl_rst_set pl_rst_assert pl_rst_deassert pl_rst_pulse pl_rst_pulse_all
  }

  array set CMD_SUMMARY {
    rd32             "read one 32-bit word"
    wr32             "write one 32-bit word"
    pl_rst_status    "display RST_PL and what each bit resets in this design"
    pl_rst_set       "write the full 4-bit RST_PL value"
    pl_rst_assert    "assert one RST_PL bit"
    pl_rst_deassert  "deassert one RST_PL bit"
    pl_rst_pulse     "assert then deassert one RST_PL bit"
    pl_rst_pulse_all "pulse all 4 RST_PL bits together (0/2 wired, 1/3 unwired)"
  }

  array set CMD_HELP {}

  set CMD_HELP(rd32) [join {
    {Args:}
    {  addr -- register address}
    {}
    {Reads one 32-bit word via `mrd -force $addr 1`. Requires}
    {design::connect to have been called.}
  } "\n"]

  set CMD_HELP(wr32) [join {
    {Args:}
    {  addr  -- register address}
    {  value -- 32-bit value to write}
    {}
    {Writes one 32-bit word via `mwr -force`. Requires design::connect to}
    {have been called.}
  } "\n"]

  set CMD_HELP(pl_rst_status) [join {
    {No args.}
    {}
    {Reads and prints RST_PL (fixed address 0xF1260330), decoded bit-by-bit}
    {against what it actually resets in this design: bit 0 (cxl1_rstn)}
    {covers every cxl_datapath_N's CXL/AXI-side reset (the bridge and the}
    {traffic generator's m_axi side) plus the perf-monitor viral block;}
    {bit 2 (axil_rstn) covers every custom_axi_tg_N's CSR-side reset plus}
    {axil_gpio4_0; bits 1 and 3 are unconnected in this design.}
  } "\n"]

  set CMD_HELP(pl_rst_set) [join {
    {Args:}
    {  bits -- full 4-bit RST_PL value to write directly}
    {}
    {No safety checks beyond masking to 4 bits -- prefer pl_rst_assert/}
    {pl_rst_deassert/pl_rst_pulse for single-bit operations.}
  } "\n"]

  set CMD_HELP(pl_rst_assert) [join {
    {Args:}
    {  bit -- RST_PL bit to set (0-3)}
    {}
    {Read-modify-write; reads back afterward and errors if the bit didn't}
    {take. Warns (doesn't error) if the bit isn't wired to anything in}
    {this design (bits 1 and 3).}
  } "\n"]

  set CMD_HELP(pl_rst_deassert) [join {
    {Args:}
    {  bit -- RST_PL bit to clear (0-3)}
    {}
    {Read-modify-write; reads back afterward and errors if the bit didn't}
    {take. Warns (doesn't error) if the bit isn't wired to anything in}
    {this design (bits 1 and 3).}
  } "\n"]

  set CMD_HELP(pl_rst_pulse) [join {
    {Args:}
    {  bit -- RST_PL bit to pulse (0-3)}
    {}
    {Assert then immediately deassert one bit. No configurable pulse width}
    {-- the JTAG round-trip between the two writes is already slow enough}
    {relative to the reset logic to act as an adequate pulse.}
  } "\n"]

  set CMD_HELP(pl_rst_pulse_all) [join {
    {No args.}
    {}
    {Pulses all 4 RST_PL bits together -- bits 0 and 2 (cxl1_rstn +}
    {axil_rstn) reset the traffic generator/perf-monitor datapath without a}
    {full design::program PDI reload; bits 1 and 3 are not wired to any net}
    {in this design, so pulsing them has no observable effect. Each wired}
    {bit passes through its own independent 2-stage CDC synchronizer, so}
    {this does not guarantee the wired domains release on exactly the same}
    {cycle -- only the register write itself is simultaneous.}
  } "\n"]

  proc help {{cmd ""}} { return [::pkg_help control $cmd] }
  proc h {{cmd ""}} { return [help $cmd] }
}
