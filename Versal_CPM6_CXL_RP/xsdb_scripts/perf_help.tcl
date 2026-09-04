# perf_help.tcl

namespace eval perf {
  variable COMMANDS {
    connect
    read_ram read_datapath get_ram_entries get_datapath_entries
    reset_ram reset_all
    capture capture_all
    latency bandwidth bandwidth_all
    report report_to_file
    get_raw raw_to_file
  }

  array set CMD_SUMMARY {
    connect       "select the DPC xsdb target"
    read_ram      "read all captured {cnt,tag} entries for one URAM"
    read_datapath "read_ram on all 4 interfaces for one cpi, printing each one's entry count"
    get_ram_entries      "binary-search one URAM's entry count (fast, no entry decode)"
    get_datapath_entries "get_ram_entries on all 4 interfaces for one cpi"
    reset_ram     "reset one URAM's write pointer"
    reset_all     "reset_ram on every interface for the given (default: all) cpi(s)"
    capture       "read all 4 interfaces for one cpi"
    capture_all   "capture, for every requested cpi, in one shared window"
    latency       "read or write latency stats (ns), FIFO-per-tag matched"
    bandwidth     "single-path bandwidth (GB/s) over its own capture span"
    bandwidth_all "combined read+write bandwidth across cpi(s), spanning-window method"
    report        "per-datapath read/write latency tables+histograms, plus a bandwidth summary table; prints only"
    report_to_file "same as report, written to a file instead of stdout"
    get_raw       "nested {cpi -> {iface -> entries}} dict of every captured {cnt,tag} entry"
    raw_to_file   "get_raw, written to fname.ftype (txt/csv/yaml)"
  }

  array set CMD_HELP {}

  set CMD_HELP(connect) [join {
    {No args.}
    {}
    {Selects the DPC (PMC Debug Packet Controller) xsdb target, printing}
    {the specific target index and name landed on (e.g. "target 2 (DPC)").}
    {Independent of design::connect -- it's purely a board-specific}
    {target-selection step.}
  } "\n"]

  set CMD_HELP(read_ram) [join {
    {Args:}
    {  cpi   -- datapath index (0..design::get_num_cpi-1)}
    {  iface -- one of: f2a_req f2a_data a2f_data a2f_rsp}
    {}
    {Prints "INFO: This may take several minutes." first -- up to}
    {MAX_ENTRIES=4096 individual AXI-Lite reads over JTAG, one per entry.}
    {Reads entries idx=0,1,2,... via AXI-Lite until an all-zero word is}
    {seen (hardware guarantee: any index at/beyond the write pointer reads}
    {back '0), or MAX_ENTRIES=4096 is reached. Prints a one-line summary}
    {("Datapath N | IFACE | Entries: n") before returning. Returns a list}
    {of {cnt tag} dicts in write (arrival) order.}
  } "\n"]

  set CMD_HELP(read_datapath) [join {
    {Args:}
    {  cpi -- datapath index}
    {}
    {Prints "INFO: This may take several minutes." first, then calls}
    {perf::read_ram for all 4 interfaces on cpi (each of which prints its}
    {own such notice too, plus its own "Datapath N | IFACE | Entries: n"}
    {summary line). Purely a display command -- prints only, returns}
    {nothing; call perf::capture instead if you need the entries back.}
  } "\n"]

  set CMD_HELP(get_ram_entries) [join {
    {Args:}
    {  cpi   -- datapath index}
    {  iface -- one of: f2a_req f2a_data a2f_data a2f_rsp}
    {}
    {Fast alternative to perf::read_ram when you only need the entry COUNT,}
    {not the decoded {cnt tag} entries themselves: binary-searches the}
    {write-pointer boundary (same hardware guarantee read_ram relies on --}
    {any index at/beyond the write pointer reads back all-zero) in}
    {ceil(log2(MAX_ENTRIES+1))=12 probes instead of up to MAX_ENTRIES=4096}
    {reads. Prints the same one-line summary as read_ram ("Datapath N |}
    {IFACE | Entries: n"), but returns just the count (an integer), not a}
    {list of entries.}
  } "\n"]

  set CMD_HELP(get_datapath_entries) [join {
    {Args:}
    {  cpi -- datapath index}
    {}
    {Calls perf::get_ram_entries for all 4 interfaces on cpi, so every}
    {interface prints its own "Datapath N | IFACE | Entries: n" summary}
    {line (via binary search, not a full linear read). Purely a display}
    {command -- prints only, returns nothing.}
  } "\n"]

  set CMD_HELP(reset_ram) [join {
    {Args:}
    {  cpi   -- datapath index}
    {  iface -- one of: f2a_req f2a_data a2f_data a2f_rsp}
    {}
    {Writes 0 to the URAM's own base address. ANY completed AXI-Lite write}
    {resets that URAM's write pointer to 0 -- this is the only "reset"}
    {mechanism; there is no dedicated control/status register for this}
    {block.}
  } "\n"]

  set CMD_HELP(reset_all) [join {
    {Args:}
    {  [cpi_list] -- default: every cpi from design::get_cxl_indices.}
    {}
    {Calls perf::reset_ram for all 4 interfaces on each listed cpi.}
  } "\n"]

  set CMD_HELP(capture) [join {
    {Args:}
    {  cpi -- datapath index}
    {}
    {There is no start/stop/done register for this block -- capture is}
    {inherently continuous whenever valid CXL transactions occur; this just}
    {reads all 4 interfaces (each printing its own perf::read_ram entry-}
    {count summary). Returns a dict keyed by interface name -> list of}
    {{cnt tag} entries. freerun_cnt32 is 32 bits and rolls over roughly}
    {every 12-17 seconds depending on clock frequency.}
  } "\n"]

  set CMD_HELP(capture_all) [join {
    {Args:}
    {  [cpi_list] -- default: every cpi.}
    {}
    {The multi-cpi form of capture: reads every requested cpi back-to-back}
    {(minimal skew) -- so bandwidth_all/report see data from one shared}
    {window instead of independently-timed ones.}
  } "\n"]

  set CMD_HELP(latency) [join {
    {Args:}
    {  cpi  -- datapath index}
    {  path -- "read" (f2a_req -> a2f_data) or "write" (f2a_data -> a2f_rsp)}
    {}
    {Reads both interfaces' URAMs, then FIFO-per-tag-matches each source}
    {entry to the OLDEST not-yet-consumed destination entry sharing its}
    {12-bit tag (tags repeat across a capture window, so global arrival}
    {order or naive value-equality would mismatch in-flight transactions).}
    {Deltas are computed on the shared 32-bit freerun_cnt32 counter with}
    {rollover correction; any delta exceeding half the counter's rollover}
    {period is treated as a bad/rollover-crossed match and excluded.}
    {Requires design::get_clk_hz to be set. Returns/prints n, min_ns,}
    {avg_ns, max_ns, median_ns, stddev_ns (sample, n-1), unmatched_src,}
    {unmatched_dst.}
  } "\n"]

  set CMD_HELP(bandwidth) [join {
    {Args:}
    {  cpi   -- datapath index}
    {  iface -- one of: f2a_req f2a_data a2f_data a2f_rsp}
    {}
    {bytes = (entry count) * 64 (fixed CPI/CXL beat width). span = last}
    {entry's freerun_cnt32 value minus the first entry's (rollover}
    {corrected). rate = bytes / (span / CLK_HZ). Requires >=2 captured}
    {entries on that interface.}
  } "\n"]

  set CMD_HELP(bandwidth_all) [join {
    {Args:}
    {  [cpi_list] -- default: every cpi.}
    {}
    {Per cpi, computes ONE bandwidth figure per logical path (write:}
    {f2a_data -> a2f_rsp, read: f2a_req -> a2f_data) -- NOT one per raw}
    {interface, which would double-count the same bytes on both the}
    {request and response side and mix their separate timing windows.}
    {bytes = completed-transfer count (the response-side interface's entry}
    {count) * 64; span = first REQUEST's freerun_cnt32 tick to the last}
    {RESPONSE's tick (rollover corrected). A path with no matched request/}
    {response entries is skipped, not errored.}
    {}
    {Every path across every listed cpi that produced a figure is then}
    {combined using the SPANNING-WINDOW method, not a sum of independently}
    {measured per-path GB/s figures (traffic generators aren't guaranteed}
    {to overlap in time, which would overstate throughput): total_bytes =}
    {sum of every part's own bytes; span = latest last-tick across every}
    {part minus earliest first-tick across every part (rollover}
    {corrected); combined_rate = total_bytes / that one span. Valid because}
    {every path shares the SAME freerun_cnt32 instance. Returns a dict:}
    {per_path (each cpi/path's own bandwidth result) and combined}
    {(n_parts, total_bytes, span_ticks, span_s, gbps).}
    {}
    {This is the printing wrapper around perf::compute_bandwidth_all (data-}
    {only, no printing). perf::report calls perf::compute_bandwidth_all}
    {directly instead of this command, so it can present the same data as}
    {its own "Bandwidth Summary" table rather than these per-line prints.}
    {}
    {perf::report also passes an extra, internal cache argument to}
    {perf::compute_bandwidth_all so each cpi's 4 interfaces are read once}
    {and shared with the latency section -- not part of either command's}
    {public interface; call bandwidth_all with just cpi_list (or nothing)}
    {for direct/interactive use.}
  } "\n"]

  set CMD_HELP(report) [join {
    {Args:}
    {  [cpi_list] -- default: every cpi.}
    {}
    {Errors immediately (before touching any hardware) if design::get_clk_hz}
    {isn't set -- latency (ns) can't be computed from raw counter deltas}
    {without it. Call design::discover (auto-discovery) or}
    {design::set_clk_hz <hz> manually first.}
    {}
    {Otherwise prints "INFO: This may take several minutes." first (always}
    {to stdout, even when called via perf::report_to_file -- it's a live}
    {status notice, not part of the saved report content). Orchestrator:}
    {for each cpi, prints a "Datapath N" section with a}
    {one-row ASCII table (Entries | Min | Max | Median | Std. Dev., all ns),}
    {a full-width "-" rule separating the table from the "#"-bar histogram}
    {below it (up to 10 bins spanning min..max ns, counts aligned under the}
    {table's Entries column), for both Write (f2a_data -> a2f_rsp) and Read}
    {(f2a_req -> a2f_data) latency -- printing "(no entries -- <reason>)"}
    {instead of erroring for a subsection that couldn't compute latency}
    {(insufficient data, no tag-matched pairs, etc. -- the actual}
    {perf::compute_latency error text is shown, not a generic message).}
    {}
    {After every cpi's sections, prints a "Bandwidth Summary" ASCII table:}
    {one row per cpi ("CPI instance N") plus a final "Total" row, and two}
    {columns (Write Bandwidth (GB/s), Read Bandwidth (GB/s)). A cpi/path}
    {with no matched request/response entries shows "-" instead of}
    {erroring. The Total row combines only the write-side parts for its}
    {column and only the read-side parts for the other (via}
    {perf::combine_bandwidth), NOT perf::compute_bandwidth_all's single}
    {overall "combined" figure, which spans both directions together.}
    {}
    {Purely a display command -- prints only, returns nothing; call}
    {perf::compute_latency/perf::compute_bandwidth_all directly if you need}
    {the underlying data back.}
  } "\n"]

  set CMD_HELP(report_to_file) [join {
    {Args:}
    {  [cpi_list] -- default: every cpi.}
    {  [filename] -- default: "latency_report.txt".}
    {}
    {Identical to perf::report, but writes the whole report (tables,}
    {histograms, and the bandwidth summary lines normally seen on the}
    {console) to filename instead of stdout. Prints a one-line}
    {confirmation ("INFO: latency report for cpi(s) ... written to ...")}
    {to stdout once done. Overwrites filename if it already exists.}
    {Returns nothing.}
  } "\n"]

  set CMD_HELP(get_raw) [join {
    {Args:}
    {  [cpi_list] -- default: every cpi.}
    {}
    {Returns a nested dict: cpi -> iface -> list of {cnt tag} entry dicts,}
    {for all 4 interfaces on each listed cpi -- the same shape}
    {perf::capture_all returns, under a name suited to the raw-export}
    {workflow perf::raw_to_file builds on.}
  } "\n"]

  set CMD_HELP(raw_to_file) [join {
    {Args:}
    {  [cpi_list] -- default: every cpi.}
    {  [ftype]    -- "txt" (default), "csv", or "yaml". Errors immediately}
    {               (before touching the filesystem) if not one of these.}
    {  [fname]    -- default: "raw_report". Anything from the first "." in}
    {               fname onward is stripped, then ".<ftype>" is appended}
    {               -- so fname.ftype is always the actual output file.}
    {}
    {Writes perf::get_raw's data in the requested format:}
    {  txt  -- "Datapath N" sections, one "IFACE (n entries)" block each,}
    {          one "idx I: tag=T count=C" line per entry.}
    {  csv  -- header "cpi,iface,idx,tag,count", one data row per entry}
    {          (interfaces with no entries contribute no rows).}
    {  yaml -- "datapath_N:" mapping to one "iface:" key per interface,}
    {          each a list of {idx, tag, count} entries ("[]" if empty).}
    {Prints a one-line confirmation to stdout once written. Returns}
    {nothing.}
  } "\n"]

  proc help {{cmd ""}} { return [::pkg_help perf $cmd] }
  proc h {{cmd ""}} { return [help $cmd] }
}
