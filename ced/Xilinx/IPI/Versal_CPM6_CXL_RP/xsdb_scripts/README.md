# xsdb_scripts: board bring-up and hardware-exercise library

Five TCL packages give an interactive `xsdb` session full control over this
CED's (`Versal_CPM6_CXL_RP`) CXL Root Port hardware over JTAG: board
bring-up and shared design discovery (`design::`), raw register transport
and PL reset-pin control (`control::`), traffic-generator control
(`hwtg::`), performance-counter readout (`perf::`), and PCIe/CXL
configuration-space access (`ecam::`). This directory is copied into the
generated Vivado project (alongside `p.gen`, `p.sim`, ... -- see `run.tcl`),
so it travels with every project this CED produces.

No processor needs to be running on the board: every register these
packages touch is only wired to the PMC's Debug Packet Controller path, the
same one Vivado's own JTAG memory read/write uses.

## Quick start

```
xsdb% source xsdb_scripts/all.tcl
xsdb% design::discover [pwd]
INFO: clock auto-discovered: CLK_HZ=333329987 (333.33 MHz, from cxl1_clk)
INFO: design address map discovered from:
  .../project_8.gen/sources_1/bd/Versal_CPM6_CXL_RP/hw_handoff/Versal_CPM6_CXL_RP.hwh
INFO: NUM_CPI=2 (valid datapath indices: 0 1)
xsdb% design::connect
xsdb% design::program  ;# load the PDI file to the device
xsdb% ecam::connect
xsdb% ecam::setup_ep_bars
xsdb% ecam::setup_hdm decoder
xsdb% hwtg::connect
xsdb% hwtg::load_append 0 "WRITE addr=0x8000000000 repeat=7 addr_k=12 addr_stride=64"
xsdb% hwtg::load_append 0 "READ  addr=0x8000000000 repeat=7 addr_k=12 addr_stride=64"
xsdb% hwtg::start 0
xsdb% hwtg::wait_done 0
xsdb% perf::connect
xsdb% perf::report
```

`source xsdb_scripts/all.tcl` is the only command needed to load everything
-- it sources `design.tcl`, `control.tcl`, `hwtg.tcl`, `perf.tcl`, and
`ecam.tcl` in that dependency order. Each of those individual files can
also be sourced on its own (they each check their own dependencies and
error with the exact `source` command to run if something's missing), but
`all.tcl` is the normal entry point.

**Dependency order:** `design::` -> `control::` -> {`hwtg::`, `perf::`,
`ecam::`} (the last three don't depend on each other). `design::` has no
dependency on anything else -- it's the foundation:
- **There is no single, shared "connect" command.** Every package has its
  own `::connect` (`design::`/`ecam::`/`hwtg::`/`perf::`), each selecting
  whichever xsdb target *that package's own* register accesses actually
  need: a board/root pattern for `design::`, the DPC for `hwtg::`/`perf::`,
  the Cortex-A72 #0 (APU) for `ecam::`. xsdb only has ONE current target at
  a time, and these four `::connect` commands don't coordinate with each
  other -- calling one silently changes the target another package's
  accesses were relying on. Call whichever package's `::connect` you need
  immediately before using that package's commands (see the quick start
  above). There's no code-level gate enforcing any of this; an unselected/
  wrong target just fails at the `mrd`/`mwr` call itself instead.
- `design::discover` is the **one** `.hwh`-parsing pass for the whole
  session. It populates the address map and CXL clock frequency that
  `hwtg::` and `perf::` read back through `design::`'s accessors --
  neither package parses the `.hwh` itself.

**`design::connect`'s target is board/hw_server-session specific.** Run
`targets` yourself first to see what your JTAG chain actually enumerates,
and pass whichever form matches it if the default (`*Versal*xc2vp*`)
doesn't work for your setup: a `-filter` name-match pattern, e.g.
`design::connect {*xcvp1902*}`, or a plain integer target index, e.g.
`design::connect 1` (does `targets -set 1` directly, no filter). Every
`::connect` command (`design::`/`ecam::`/`hwtg::`/`perf::`) prints the
specific target index and name it landed on, e.g. `INFO: perf connected to
target 2 (DPC)` -- parsed from `targets`' own listing, since `targets -set
-filter ...` itself returns nothing useful to print.

`design::discover` only needs the generated project's `.hwh`; it works
without a board attached, so command files can be validated (indices/
fields checked) before you ever touch hardware. Trying to talk to a
datapath index the project wasn't generated with fails immediately, e.g.
in a NUM_CPI=2 project:

```
xsdb% hwtg::load_append 3 "WAIT"
datapath 3 does not exist in this design (valid indices: 0 1) -- call design::discover first if this looks wrong
```

## Command reference and help

Every package documents itself: `<pkg>::help` (alias `<pkg>::h`) with no
argument lists every command in that package; with a command name, it
prints that command's detailed usage (Args/Notes). There is no global/
combined help command -- e.g.:

```
xsdb% design::help
xsdb% hwtg::help load_append
```

The full per-command reference is also summarized below, grouped by
package.

## `design::` -- board bring-up and shared discovery

Board bring-up (PDI programming, PERSTN/MIO control, link-status checking)
plus the JTAG connect command and the `.hwh` discovery pass every other
package reads from.

| command | summary |
| --- | --- |
| `design::discover {?proj_dir_or_hwh_path?}` | parse the generated `.hwh` once: `custom_axi_tg`/`axil_gpio4`/`uram_sdp_4Kx44` base addresses + `cxl1_clk` frequency |
| `design::set_clk_hz hz` | manually set/override the CXL clock frequency |
| `design::get_tg_base cpi` | `custom_axi_tg` base address for a datapath |
| `design::get_gpio_base` | `axil_gpio4_0` base address |
| `design::get_uram_base cpi iface` | `uram_sdp_4Kx44` base address for a (cpi, interface) pair |
| `design::get_clk_hz` | the discovered/set `cxl1_clk` frequency in Hz |
| `design::get_num_cpi` | number of datapaths discovered |
| `design::get_cxl_indices` | list of discovered CXL datapath indices |
| `design::connect {?target?}` | select the JTAG target -- a `-filter` pattern, or a plain integer index (shared by every package) |
| `design::program` | full board bring-up: program `boot.pdi`/`pld.pdi`, toggle PERSTN, check the link |
| `design::check_link_status` | read and print CPM6 Ctrl1's link state |
| `design::setup_mio_as_gpio pin dir ?dfault?` | configure a MIO pin for GPIO use |
| `design::verify_mio pin dir ?value?` | verify a MIO-as-GPIO pin's configuration |
| `design::drive_mio pin action` | drive (or pulse) a MIO-as-GPIO output pin |
| `design::rmw addr mask value` | generic read-modify-write |

`design::program` takes `./boot.pdi` and `./pld.pdi` from the current
directory (both existence-checked before anything is programmed), toggles
PERSTN both externally (to the EP, MIO 41) and internally (to the RP, via
a PS_GPIO/MIO19 IRQ workaround), then checks CPM6 **Ctrl1** specifically
(this CED's `design.xml`: "utilizing Controller 1 within CPM6" -- there is
no Ctrl0 to select, `design::check_link_status` is hardcoded to Ctrl1) and
returns 1/0 for link-up without raising an error on link-down, so the
caller can decide how to react:

```
xsdb% design::program
INFO: selected target 1
Programming the device...
Assert PERSTN externally (to EP)...
Toggle PERSTN internally to initialize RP...
Deassert PERSTN externally (to EP)...
Check if the link is up...
[design:INFO] Ctrlr1:
[design:INFO]   Link state       : L0 at Gen6x8 (smlh_link_up=1)
[design:INFO]   Data link layer  : UP (rdlh_link_up=1)
[design:INFO]   VLSM mc/io       : mc=RESET, io=RESET
[design:INFO]   Flit mode        : 256B Flit
```

`design::TARGET_INDEX` (default `1`, i.e. `targets 1` / "the Versal root")
is `design::program`'s own target-selection convention -- board/session-
specific, run `targets` yourself if index 1 doesn't select the right
target on your chain. It's independent of `design::connect`'s
pattern-based target selection.

`setup_mio_as_gpio`, `verify_mio`, `drive_mio`, and `check_link_status` are
all usable standalone; `check_link_status`'s controller is hardcoded to
Ctrl1. `rmw` is a plain, generic read-modify-write.

## `control::` -- register transport and PL reset pins

The one place `mrd`/`mwr` are actually issued from, plus display/control of
the PMC's `RST_PL` fabric-reset register.

| command | summary |
| --- | --- |
| `control::rd32 addr` | read one 32-bit word |
| `control::wr32 addr value` | write one 32-bit word |
| `control::pl_rst_status` | display RST_PL and what each bit resets in this design |
| `control::pl_rst_set bits` | write the full 4-bit RST_PL value |
| `control::pl_rst_assert bit` | assert one RST_PL bit |
| `control::pl_rst_deassert bit` | deassert one RST_PL bit |
| `control::pl_rst_pulse bit` | assert then deassert one RST_PL bit |
| `control::pl_rst_pulse_all` | pulse all 4 RST_PL bits together (bits 0/2 wired, 1/3 unwired) |

`RST_PL` (PMC CRP register, fixed address `0xF1260330`) has two bits this
design actually wires: bit 0 (`cxl1_rstn`) resets every `cxl_datapath_N`'s
CXL/AXI-side logic (the bridge and the traffic generator's `m_axi` side)
plus the perf-monitor viral block; bit 2 (`axil_rstn`) resets every
`custom_axi_tg_N`'s CSR-side logic plus `axil_gpio4_0`. Bits 1 and 3 exist
in the register but aren't connected to anything here. `pl_rst_pulse_all`
pulses all 4 bits (0-3) together -- a quick way to reset the traffic
generator/perf-monitor datapath without a full `design::program` PDI
reload -- note it does **not** guarantee the wired domains release on
exactly the same cycle (each bit passes through its own independent CDC
synchronizer), unlike `hwtg::ext_trigger`'s genuinely
single-cycle-synchronous GPIO pulse. Pulsing bits 1/3 has no observable
effect since they aren't wired to anything, but the register write still
touches them.

**This is a completely different mechanism from `design::program`'s
PERSTN/MIO toggling** -- different register, different signal path. Don't
confuse the two.

## `hwtg::` -- traffic-generator control

Loads and runs `custom_axi_tg` command mnemonics, polls run state, and
decodes sticky errors -- one instance per CPI datapath.

### Command mnemonic format

One instruction per line: `OPCODE key=val key=val ...`. `addr` is
**required** on WRITE/READ (a hard error if omitted); every other key is
optional and defaults to 0, **except** `be_k` on WRITE, which defaults to 7
(always full WSTRB) instead. Values may be decimal or `0x`-prefixed hex.

```
WRITE addr=0x1000 id=0 id_stride=1 repeat=100 addr_k=4 addr_stride=64 be_k=7 poison=0 data_start=0x0 data_stride=1
READ  addr=0x2000 id=1 id_stride=1 repeat=50 addr_k=0 addr_stride=64 aruser_cmd=0
WAIT
```

Fields (see `src/ip_repo/custom_axi_tg/src/custom_axi_tg_pkg.sv` for the
authoritative bit layout):

| key | opcodes | meaning |
| --- | --- | --- |
| `addr` | WRITE, READ | **required.** 48-bit start_address |
| `id` | WRITE, READ | 4-bit start_id (only `[AXI_ID_WIDTH-1:0]` used) |
| `id_stride` | WRITE, READ | id_next = id + id_stride (id_mode=0) |
| `id_mode` | WRITE, READ | 0=stride, 1=lfsr8 |
| `repeat` | WRITE, READ | repeat_count (12-bit) |
| `addr_k` | WRITE, READ | moving-address-bits count, 0..26 (27..31 silently clamp to 26 at commit) |
| `addr_stride` | WRITE, READ | addr_next = addr + addr_stride (addr_mode=0) |
| `addr_mode` | WRITE, READ | 0=stride, 1=lfsr27 |
| `be_k` | WRITE | **default 7** (always full WSTRB) if omitted. 0..6 select a partial-byte-enable probability instead |
| `poison` | WRITE | WUSER poison bit |
| `data_start`, `data_stride` | WRITE | data pattern (data_mode=0, counter); ignored if data_mode=1 (lfsr64) |
| `data_mode` | WRITE | 0=counter, 1=lfsr64 |
| `aruser_cmd` | READ | raw 2-bit passthrough to the bridge |

### Commands

| command | summary |
| --- | --- |
| `hwtg::connect` | select the DPC xsdb target |
| `hwtg::load_append cpi line` | program at the next free index |
| `hwtg::load_at cpi idx line` | program (or reprogram) a specific index |
| `hwtg::load_interactive cpi` | prompts for index/opcode/fields on stdin |
| `hwtg::load_from_file cpi path` | one mnemonic per line, loaded in file order via `load_append` |
| `hwtg::read_cmd cpi idx` | disassemble one committed command |
| `hwtg::read_all cpi` | print+disassemble every committed command (`0..TG_DONE_PTR-1`) |
| `hwtg::dump_to_file cpi path` | `read_all`, written in `load_from_file` format |
| `hwtg::parse_errors cpi` | decode `TG_BRESP_ERROR`'s sticky bits plus any per-command SLVERR/invalid-response entries |
| `hwtg::clear_errors cpi` | clear the sticky `TG_BRESP_ERROR` log (W1C) |
| `hwtg::start cpi` / `hwtg::stop cpi` / `hwtg::soft_reset cpi` | run control |
| `hwtg::status cpi` | human-readable `TG_STATUS` dump |
| `hwtg::wait_done cpi {?timeout_s 5?}` | poll until `ALL_RESPONDED`/`IDLE` |
| `hwtg::tg_cfg cpi` | live-read `TG_CFG` (max_commands/axi_id_width/etc.) |
| `hwtg::ext_trigger cpi_list` | via `axil_gpio4`, pulse `tg_start` on the given datapath(s) (e.g. `{0 2}`) on the *same clock edge*, instead of looping each TG's own AXI-Lite `TG_CTRL.START` (which would be N separate, skewed transactions) |
| `hwtg::ext_trigger_all {?cpi_list?}` | `ext_trigger`, defaulting to every discovered datapath |

## `perf::` -- performance URAM latency/bandwidth statistics

Reads the per-CPI, per-interface Performance URAMs (`f2a_req`/`f2a_data`/
`a2f_data`/`a2f_rsp`, each an ordered log of `{counter, tag}` snapshots
taken whenever a CXL transaction passes) and turns them into latency and
bandwidth figures.

| command | summary |
| --- | --- |
| `perf::connect` | select the DPC xsdb target |
| `perf::read_ram cpi iface` | read all captured `{cnt,tag}` entries for one URAM |
| `perf::read_datapath cpi` | `read_ram` on all 4 interfaces for one cpi, printing each one's entry count |
| `perf::get_ram_entries cpi iface` | binary-search one URAM's entry count (12 probes, no entry decode) |
| `perf::get_datapath_entries cpi` | `get_ram_entries` on all 4 interfaces for one cpi |
| `perf::reset_ram cpi iface` | reset one URAM's write pointer |
| `perf::reset_all {?cpi_list?}` | `reset_ram` on every interface for the given (default: all) cpi(s) |
| `perf::capture cpi` | read all 4 interfaces for one cpi |
| `perf::capture_all {?cpi_list?}` | `capture`, for every requested cpi, in one shared window |
| `perf::latency cpi path` | `read` (`f2a_req`->`a2f_data`) or `write` (`f2a_data`->`a2f_rsp`) latency stats (ns), FIFO-per-tag matched |
| `perf::bandwidth cpi iface` | single-path bandwidth (GB/s) over its own capture span |
| `perf::bandwidth_all {?cpi_list?}` | combined read+write bandwidth across cpi(s), spanning-window method (not summed) |
| `perf::report {?cpi_list?}` | per-datapath read/write latency tables+histograms, plus a bandwidth summary table; prints only |
| `perf::report_to_file {?cpi_list?} {?filename?}` | same as `report`, written to `filename` (default `latency_report.txt`) instead of stdout |
| `perf::get_raw {?cpi_list?}` | nested `{cpi -> {iface -> entries}}` dict of every captured `{cnt,tag}` entry |
| `perf::raw_to_file {?cpi_list?} {?ftype?} {?fname?}` | `get_raw`, written to `fname.ftype` (`ftype`: `txt` default, `csv`, or `yaml`) |

Each URAM is an ordered log, not a live counter array: `waddr` auto-
increments on every captured transaction, and the hardware forces reads at
or beyond the write pointer to all-zero -- a real, deterministic
end-of-data marker `perf::read_ram` relies on (linear scan, stopping at the
first zero) and `perf::get_ram_entries` relies on too, but via binary
search instead -- it only needs the entry COUNT, not every entry's decoded
value, so it bisects the same 0..MAX_ENTRIES range in `ceil(log2(4097))=12`
probes instead of up to 4096. This assumes no legitimately-written entry
ever itself decodes to raw 0 (`cnt=0` and `tag=0` at once), same as
`read_ram`'s linear scan already does -- binary search just relies on that
assumption more heavily, since a false zero mid-search silently returns the
wrong count rather than just stopping one entry early. There's no control/status
register for this block at all: "reset" is any completed AXI-Lite write to
the URAM's own base address, and "capture" is inherently continuous
whenever valid CXL transactions occur (there's no start/stop/done bit to
poll). Every `perf::read_ram` call (directly, or via `capture`/
`capture_all`/`read_datapath`) prints a one-line summary, `Datapath N |
IFACE | Entries: n`. `perf::latency`/`perf::bandwidth`/`perf::bandwidth_all`/
`perf::report` read the same URAMs silently (no `Entries: n` lines) so their
own summary lines (latency stats, bandwidth, or the report's tables/
histograms) aren't buried in read_ram noise.

Tags (12 bits) repeat within a capture window, so `perf::latency` matches
each source entry to the **oldest not-yet-consumed** destination entry
sharing its tag (FIFO-per-tag), not global arrival order. `freerun_cnt32`
is a single 32-bit counter shared by every path in the design.

`perf::bandwidth_all` (and the data-only `perf::compute_bandwidth_all` it
wraps) computes bandwidth per **logical path** (write: `f2a_data`->`a2f_rsp`,
read: `f2a_req`->`a2f_data`), not per raw interface -- treating the
request-side and response-side interfaces as two independent bandwidth
parts would double-count the same bytes and mix their separate timing
windows, which makes no sense. For each path: bytes = the completed-transfer
count (the response-side interface's entry count) x 64; span runs from the
first **request**'s `freerun_cnt32` tick to the last **response**'s tick
(rollover corrected). Every path across every listed cpi can then be
combined over **one** shared span (earliest first-tick to latest last-tick
across all parts) rather than summing each path's independently-measured
rate -- traffic across different paths isn't guaranteed to overlap in time,
and summing independent rates would overstate the true aggregate throughput.

`perf::report`'s "Bandwidth Summary" table applies this combine **per
column**, not once overall: the `Total` row's Write Bandwidth cell combines
only the write-side parts across every listed cpi, and its Read Bandwidth
cell combines only the read-side parts -- two separate
`perf::combine_bandwidth` calls, not `perf::compute_bandwidth_all`'s single
"combined" figure (which spans both directions together and is what
`perf::bandwidth_all` prints as "combined bandwidth across N path(s)").
A cpi with no matched entries for a given path shows `-` in that cell
instead of erroring.

`perf::report` errors immediately -- before touching any hardware -- if
`design::get_clk_hz` isn't set, since latency (ns) can't be computed from
raw counter deltas without it; call `design::discover` (auto-discovery) or
`design::set_clk_hz <hz>` first. `perf::read_ram`/`perf::read_datapath`/
`perf::report` each print `"INFO: This may take several minutes."` right at
the start (always to real stdout, even when called via
`perf::report_to_file`, since it's a live status notice and not part of the
saved report content). Each per-datapath latency table is followed by a
full-width `-` rule separating it from its histogram below. A subsection
with no computable latency prints `"(no entries -- <reason>)"` using
`perf::compute_latency`'s actual error text (not a generic message) --
except the `-- run perf::capture first` suggestion on the "insufficient
data" case is stripped in this table view specifically, since it's
redundant across a multi-cpi/path report; `perf::latency` called directly
still shows that suggestion in full. `perf::report` ends with a blank line,
not a banner.

## `ecam::` -- PCIe/CXL configuration-space access

Reads BARs, walks the standard PCI capability list and the PCIe extended
capability list, and finds/decodes CXL DVSEC structures, against two fixed
configuration-space windows: this design's own Root Port (`rp`, Type 1
header, base `0xE0000000`) and the one downstream CXL device attached to
the link (`ep`, Type 0 header, base `0xE0100000`). These are fixed
platform addresses, not `.hwh`-discovered -- unrelated to the `0xFC`
CPM6-DBI register windows referenced elsewhere on this platform.

**Not true bus/device/function ECAM.** This design is a fixed,
single-function Root Port wired to one downstream device -- there's no bus
topology to enumerate, so `ecam::` is really two fixed
config-space-shaped register windows, not `{bus,dev,func}`-indexed access.

| command | summary |
| --- | --- |
| `ecam::connect` | select the Cortex-A72 #0 (APU) xsdb target and clear its registers |
| `ecam::cfg_read target offset` | raw 32-bit config-space read |
| `ecam::cfg_write target offset value` | raw 32-bit config-space write |
| `ecam::id {?target?}` | Vendor ID / Device ID |
| `ecam::read_bars {?target?}` | read and decode every BAR (`rp` has 2 slots, `ep` has 6) |
| `ecam::walk_caps {?target?}` | walk the standard PCI capability list (offset `0x34`) |
| `ecam::walk_ext_caps {?target?}` | walk the PCIe extended capability list (offset `0x100`) |
| `ecam::find_cxl target` | find CXL DVSEC entries (Vendor ID `0x1E98`) |
| `ecam::show_cxl {?target?} {?dvsec_spec?}` | verbose DWORD-by-DWORD dump/decode of one or every CXL DVSEC |
| `ecam::setup_ep_bars` | size and place the ep's BARs into host MMIO space, widen the rp's prefetch window to match |
| `ecam::setup_hdm mode` | program HDM range(s), `mode` is "range" or "decoder" |
| `ecam::report {?target?}` | `id`/`read_bars`/`walk_caps`/`walk_ext_caps` across `rp` and/or `ep` (default: both) |

`cfg_read`/`cfg_write` take a single `target`, `rp` or `ep`. `id`/
`read_bars`/`walk_caps`/`walk_ext_caps`/`show_cxl`/`report` take an optional
`target` of `rp`, `ep`, or `both` (also the default, i.e. no argument) -- on
`both` an absent target is skipped rather than erroring, and a one-line
section header (with that target's ECAM base address) is printed first. A
Root Port's own BARs are of limited standalone interest (they map its own
Component Registers, not CXL traffic) -- the genuinely useful CXL address
data (HDM decoder ranges) lives in the CXL Device DVSEC (`0x0000`) on the
`ep` side instead, via `ecam::show_cxl`, which also decodes `0x0007` (PCIe
DVSEC for Flex Bus Port) and `0x0008` (Register Locator DVSEC); any other
DVSEC ID gets a labeled-DWORD dump only. `show_cxl`'s optional second
argument filters to one DVSEC: a value that's a valid CXL DVSEC ID (`0x0`,
`0x2`-`0x5`, `0x7`-`0xA`) is looked up by ID, anything else is treated as a
raw `dvsec_offset` (real offsets are always `>= 0x100`, so there's no
ambiguity).

`ecam::setup_ep_bars` performs the BAR sizing/placement system firmware
would normally do during PCIe enumeration -- it must run before anything
that accesses the ep's BAR-mapped memory (e.g. CXL Component Registers
reached via a Register Locator DVSEC block). It probes the ep's 6 BAR
registers (only 64-bit Memory BARs are supported), places each in a host
MMIO window (an 8 GB low window by default, falling back to a 256 GB high
window if the footprint doesn't fit), widens the rp's Type 1 Prefetchable
Memory Base/Limit registers to cover them, and sets Memory Space Enable on
both. No args -- this CED has exactly one ep and one rp.

`ecam::setup_hdm {range|decoder}` sets up CXL Host-managed Device Memory on
the ep at a fixed base of 8 TB (well above the 1 TB a device typically
advertises, so the assigned range never overlaps host memory below that
mark) -- if the device populates two HDM ranges, both modes make them one
contiguous window rather than leaving the second range unused. `range`
programs the PCIe DVSEC for CXL Devices' own Range Base registers directly,
then sets Mem_Enable and Config_Lock (write-once -- the Range Base
registers become read-only until a Conventional Reset). `decoder` instead
walks to the CXL HDM Decoder Capability behind a Component Register BAR --
it errors immediately (`call ecam::setup_ep_bars first`) unless
`ecam::setup_ep_bars` has already run successfully this session, since
that's the only way its Component Register block is reachable -- and
programs a single decoder with the combined size of every DVSEC range.
Both modes finish by printing `ecam::show_cxl ep 0x0`; `decoder` also
prints every implemented decoder's programmed state.

Every register read is printed as one tabular line, `CFG | TAG | offset =
value : {description}` (`TAG` is `HEADER` for offset `< 0x40`, `CAP` for
standard PCI capabilities, or `ECAP` for anything on the PCIe extended
capability list). A CXL DVSEC is also an extended capability (tagged `ECAP`
too), but its generic "Designated Vendor-Specific Extended (DVSEC)" label
is replaced inline with its specific CXL DVSEC name and `(ID=0x...)` --
`ecam::walk_ext_caps` peeks at the DVSEC header itself while walking the
list, so it prints once, not once generically and once again by name (use
`ecam::show_cxl` for a full verbose per-DWORD dump instead of this one-line
summary). `ecam::report` returns nothing (it's a pure display command --
call the individual commands directly if you need their data back):

```
xsdb% ecam::report

RP : Local Access | ECAM Base: 0xE0000000
------------------------------------------
CFG | HEADER | 0x000 = 0x12341E98 : {Device ID, Vendor ID}
CFG | HEADER | 0x010 = 0x0000000C : {BAR0: Memory, 64b, pre-fetchable}
CFG | HEADER | 0x014 = 0x00000000 : {BAR1: Upper}
CFG | CAP    | 0x040 = 0x00005005 : {MSI}
CFG | CAP    | 0x050 = 0x00000010 : {PCI Express}
CFG | ECAP   | 0x100 = 0x14010001 : {Advanced Error Reporting (AER)}
CFG | ECAP   | 0x140 = 0x18010023 : {PCIe DVSEC for Flex Bus Port (ID=0x7)}

EP : Remote Access | ECAM Base: 0xE0100000
-------------------------------------------
  (unavailable: ecam target 'ep' reads all-Fs at offset 0 -- no device present (link down, or nothing attached for 'ep'))
```

## Known limitation

`control_xsdb.tcl`'s `rd32` parses `mrd`'s printed return value (last
whitespace-separated token). This has not been validated against a live
`xsdb` session in this repository -- confirm the parse matches your xsdb
version's `mrd -force <addr> 1` output, and adjust `control::rd32` if it
doesn't. `perf::rd64` builds on this same primitive, reading a 64-bit URAM
entry as two 32-bit words (`addr`, `addr+4`) reassembled `(hi<<32)|lo` --
worth a spot-check against one known entry on real hardware, since if the
low/high word order is reversed, it's a one-line swap in `perf::rd64`.
