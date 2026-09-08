# ecam_help.tcl

namespace eval ecam {
  variable COMMANDS {
    connect
    cfg_read cfg_write
    id read_bars
    walk_caps walk_ext_caps
    find_cxl show_cxl
    setup_ep_bars setup_hdm
    report
  }

  array set CMD_SUMMARY {
    connect       "select the Cortex-A72 #0 (APU) xsdb target and clear its registers"
    cfg_read      "raw 32-bit config-space read"
    cfg_write     "raw 32-bit config-space write"
    id            "Vendor ID / Device ID"
    read_bars     "read and decode every BAR"
    walk_caps     "walk the standard PCI capability list"
    walk_ext_caps "walk the PCIe extended capability list"
    find_cxl      "find CXL DVSEC entries (Vendor ID 0x1E98)"
    show_cxl      "verbose DWORD-by-DWORD dump/decode of one or every CXL DVSEC"
    setup_ep_bars "size and place the EP's BARs into host MMIO space, widen the RP's prefetch window to match"
    setup_hdm     "program HDM range(s) via the DVSEC Range registers or the HDM Decoder Capability"
    report        "id/read_bars/walk_caps/walk_ext_caps across rp and/or ep"
  }

  array set CMD_HELP {}

  set CMD_HELP(connect) [join {
    {No args.}
    {}
    {Selects the Cortex-A72 #0 (APU) xsdb target via a name filter and runs}
    {"rst -proc -clear-registers" on it, printing the specific target index}
    {and name landed on (e.g. "target 4 (Cortex-A72 #0)"). Some ecam::}
    {workflows on real hardware need the APU target}
    {specifically to reach EP config space / Component Registers via iATU.}
    {}
    {Independent of design::connect -- it's purely a board-specific}
    {target-selection step, not this package's shared}
    {register-access prerequisite.}
  } "\n"]

  set CMD_HELP(cfg_read) [join {
    {Args:}
    {  target -- "rp" or "ep"}
    {  offset -- byte offset into that target's config space}
    {}
    {Raw 32-bit config-space read via control::rd32.}
  } "\n"]

  set CMD_HELP(cfg_write) [join {
    {Args:}
    {  target -- "rp" or "ep"}
    {  offset -- byte offset into that target's config space}
    {  value  -- 32-bit value to write}
    {}
    {Raw 32-bit config-space write via control::wr32.}
  } "\n"]

  set CMD_HELP(id) [join {
    {Args:}
    {  [target] -- "rp", "ep", or "both". Default: both.}
    {}
    {Errors if offset 0 reads all-Fs (no device present) on a single,}
    {explicit target; on "both" an absent target is skipped instead}
    {("(unavailable: ...)"), and a per-target section header (with that}
    {target's ECAM base address) is printed first. Prints the Vendor ID /}
    {Device ID; returns nothing.}
  } "\n"]

  set CMD_HELP(read_bars) [join {
    {Args:}
    {  [target] -- "rp", "ep", or "both". Default: both.}
    {}
    {Reads and decodes every BAR (rp has 2 slots -- Type 1 header, BAR0/}
    {BAR1 only; ep has 6 -- Type 0 header, BAR0-BAR5). A 64-bit BAR's}
    {upper word is reported, not re-decoded as its own BAR. A Root Port's}
    {own BARs are of limited standalone interest -- the genuinely useful}
    {CXL address data (HDM decoder ranges) lives in the CXL Device DVSEC}
    {instead, via ecam::show_cxl. On "both" an absent target is skipped}
    {instead of erroring, with a per-target section header first. Prints}
    {only; returns nothing.}
  } "\n"]

  set CMD_HELP(walk_caps) [join {
    {Args:}
    {  [target] -- "rp", "ep", or "both". Default: both.}
    {}
    {Walks the standard PCI capability list starting at offset 0x34}
    {(loop-safe: stops and warns if it detects a cycle). On "both" an}
    {absent target is skipped instead of erroring, with a per-target}
    {section header first. Prints only; returns nothing.}
  } "\n"]

  set CMD_HELP(walk_ext_caps) [join {
    {Args:}
    {  [target] -- "rp", "ep", or "both". Default: both.}
    {}
    {Walks the PCIe extended capability list starting at offset 0x100}
    {(same loop protection). Any entry that's a Designated Vendor-Specific}
    {Extended Capability (cap_id 0x0023) belonging to the CXL Consortium}
    {(DVSEC Header 1 Vendor ID 0x1E98) is printed with its specific CXL}
    {DVSEC name and ID (e.g. "Register Locator DVSEC (ID=0x8)") instead of}
    {the generic "Designated Vendor-Specific Extended (DVSEC)" label. On}
    {"both" an absent target is skipped instead of erroring, with a}
    {per-target section header first -- and, since a "both" scan has no}
    {single list to hand back, returns nothing in that case. A single,}
    {explicit target still returns its list of {offset cap_id version name}
    {next} dicts (ecam::find_cxl needs it) -- calling this directly at the}
    {interactive prompt with a single target will echo that list; wrap in}
    {`set _ [ecam::walk_ext_caps rp]` to suppress.}
  } "\n"]

  set CMD_HELP(find_cxl) [join {
    {Args:}
    {  target     -- "rp" or "ep"}
    {  [ext_caps] -- a pre-fetched walk_ext_caps result; normally omitted}
    {               (avoids walking, and printing, the extended capability}
    {               list a second time if you already have one)}
    {}
    {Filters the extended capability list down to Designated}
    {Vendor-Specific Extended Capabilities (cap_id 0x0023) whose DVSEC}
    {Header 1 Vendor ID is the CXL Consortium's (0x1E98). Purely a data}
    {filter -- prints nothing itself (ecam::walk_ext_caps already prints}
    {each CXL DVSEC's specific name/ID inline as it walks the list; use}
    {ecam::show_cxl for the verbose per-DWORD dump). Returns the list --}
    {calling this directly at the interactive prompt will echo it; wrap in}
    {`set _ [ecam::find_cxl ...]` to suppress.}
  } "\n"]

  set CMD_HELP(show_cxl) [join {
    {Args:}
    {  [target]     -- "rp", "ep", or "both". Default: both.}
    {  [dvsec_spec] -- if given, only the matching CXL DVSEC(s) are shown.}
    {                 A value that's a valid CXL DVSEC ID (0x0, 0x2-0x5,}
    {                 0x7-0xA) is looked up by DVSEC ID; anything else is}
    {                 treated as a raw dvsec_offset (real offsets are}
    {                 always >= 0x100, so there's no ambiguity). Default:}
    {                 every CXL DVSEC found.}
    {}
    {Verbose DWORD-by-DWORD dump of every CXL DVSEC on the target(s): a}
    {summary block (DVSEC ID/name, revision, length) followed by every}
    {DWORD labeled by its packed sub-registers, with field-level decode for}
    {the three most useful DVSEC IDs: 0x0000 PCIe DVSEC for CXL Devices}
    {(cache/IO/mem capable+enable, PM/reset capability bits, HDM decoder}
    {Range1/Range2 base+size), 0x0007 PCIe DVSEC for Flex Bus Port}
    {(cache/IO/mem capable+enable, 68B-Flit-and-VH capable/enabled),}
    {0x0008 Register Locator DVSEC (BIR + block-type + offset per register}
    {block). Any other DVSEC ID gets the labeled DW dump only. On "both" an}
    {absent target, or one with no matching DVSEC, is noted and skipped}
    {rather than erroring; a single, explicit target with no match still}
    {errors. Prints only; returns nothing.}
  } "\n"]

  set CMD_HELP(setup_ep_bars) [join {
    {No args -- always operates on the ep's BARs and the rp's prefetch}
    {window (this CED has exactly one of each; see design::check_link_status}
    {for the same fixed-target convention).}
    {}
    {Performs the BAR sizing and address assignment system firmware would}
    {normally do during PCIe enumeration. Errors if the ep isn't present.}
    {}
    {Pass 1 (discover): probes each of the ep's 6 BAR registers (cfg offset}
    {0x10-0x24) via the standard PCI all-1s sizing trick, restoring each}
    {BAR's original value immediately after sizing. Only 64-bit Memory BARs}
    {are supported -- the host MMIO windows handed out sit entirely above}
    {4 GB, so a 32-bit BAR, an I/O BAR, or a reserved Type field is a hard}
    {error. Errors if the total BAR footprint doesn't fit in either window.}
    {}
    {Pass 2 (place): assigns each sized BAR the next address that's a}
    {multiple of its own size (natural alignment, as PCI requires),}
    {starting at the low 8 GB window (0x6_0000_0000) -- or the high 256 GB}
    {window (0x8_0000_0000) if the footprint doesn't fit in the low one.}
    {Neither window is ever split across BARs.}
    {}
    {Finally widens the rp's Type 1 Prefetchable Memory Base/Limit registers}
    {(cfg offsets 0x24/0x28/0x2C) to a 1MB-aligned range covering every}
    {assigned BAR, and sets Memory Space Enable (Command register, cfg}
    {offset 0x4, bit 1) on both the ep and the rp. Prints every BAR found,}
    {every address assigned, and the final window; returns nothing.}
  } "\n"]

  set CMD_HELP(setup_hdm) [join {
    {Args:}
    {  mode -- "range" or "decoder" (required).}
    {}
    {Sets up CXL Host-managed Device Memory on the ep, well above the 1 TB a}
    {device typically advertises so the assigned range never overlaps host}
    {memory below that mark. Errors if the ep isn't present. "decoder" mode}
    {errors immediately, with a "call ecam::setup_ep_bars first" message, if}
    {ecam::setup_ep_bars hasn't already run successfully this session (its}
    {Component Register block is only reachable via the ep's own BAR).}
    {}
    {"range": programs the PCIe DVSEC for CXL Devices' own Range 1 (and}
    {Range 2, if HDM_Count=2 -- placed immediately after Range 1 so the two}
    {form one contiguous window) Base registers, then sets Mem_Enable and}
    {Config_Lock (WRITE-ONCE -- Range Base and other RWL fields become}
    {read-only until a Conventional Reset). Errors if Mem_Capable isn't set,}
    {HDM_Count isn't 1 or 2, a range's Memory_Info_Valid is 0, Config_Lock}
    {is already set, or any range's (combined) size exceeds 8 TB.}
    {}
    {"decoder": walks to the Register Locator DVSEC's Component Registers}
    {block (via the ep's own BAR, resolved from ecam::setup_ep_bars), then}
    {the CXL Capability array within it, to find the CXL HDM Decoder}
    {Capability structure. Sets Mem_Enable/Config_Lock (same as "range"),}
    {then programs Decoder 0 with a single Base=8 TB / Size=combined-range}
    {entry (so two DVSEC ranges are represented as one contiguous decoder,}
    {same as "range" mode), parks any remaining decoders at Base=Size=0,}
    {commits every decoder (polls Committed/Error_Not_Committed, erroring}
    {if a commit doesn't resolve within 50ms), and sets HDM_Decoder_Enable}
    {in the Global Control register. Errors if the combined size exceeds}
    {8 TB, or if the Register Locator DVSEC/Component Registers block/HDM}
    {Decoder Capability can't be found.}
    {}
    {Both modes print every step and finish with ecam::show_cxl ep 0x0 to}
    {show the DVSEC's final state; "decoder" additionally prints every}
    {implemented decoder's programmed state. Prints only; returns nothing.}
  } "\n"]

  set CMD_HELP(report) [join {
    {Args:}
    {  [target] -- "rp", "ep", or "both". Default: both.}
    {}
    {Runs id/read_bars/walk_caps/walk_ext_caps across the given target(s),}
    {skipping (not erroring on) any target that isn't present -- CXL DVSECs}
    {are identified inline by walk_ext_caps's own printing; call}
    {ecam::show_cxl for the verbose per-DWORD dump. A pure display command}
    {-- prints only, returns nothing; call the individual commands}
    {directly if you need their data back.}
  } "\n"]

  proc help {{cmd ""}} { return [::pkg_help ecam $cmd] }
  proc h {{cmd ""}} { return [help $cmd] }
}
