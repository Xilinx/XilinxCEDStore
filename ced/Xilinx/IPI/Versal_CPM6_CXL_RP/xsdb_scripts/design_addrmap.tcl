# design_addrmap.tcl
#
# The one .hwh-parsing pass for the whole session: discovers custom_axi_tg
# per-cpi base addresses (for hwtg::), the axil_gpio4_0 base address (for
# hwtg::ext_trigger/ext_trigger_all), uram_sdp_4Kx44 per-(cpi,iface) base addresses (for
# perf::), the cxl1_clk clock frequency (for perf::), and the
# gpio_ext_axil_0 base address and clock frequency (for gpio::). Every other
# package reads these back through the accessors below instead of parsing
# the .hwh itself.

namespace eval design {
  variable TG_BASE        ;# array: cpi -> custom_axi_tg base address
  array set TG_BASE {}
  variable GPIO_BASE_ADDR ""
  variable GPIO_EXT_BASE_ADDR ""  ;# gpio_ext_axil_0 (board LEDs/buttons/switches)
  variable GPIO_EXT_CLK_HZ ""     ;# its CLK_FREQ_HZ; "" until discovered/set
  variable URAM_BASE      ;# array: idx (cpi*4+iface_offset) -> base address
  array set URAM_BASE {}
  variable CLK_HZ ""      ;# "" until discovered/set

  variable IFACE_OFFSET
  array set IFACE_OFFSET {f2a_req 0 f2a_data 1 a2f_data 2 a2f_rsp 3}
}

# Locates the single top-level BD .hwh under a generated project directory.
# Does NOT match the many per-IP .hwh files nested under .../bd/<name>/ip/...
# because those sit one directory level deeper.
proc design::get_hwh_path {proj_dir} {
  set matches [glob -nocomplain -directory $proj_dir -- \
    "*.gen/sources_1/bd/*/hw_handoff/*.hwh"]
  if {[llength $matches] == 0} {
    error "no top-level .hwh found under $proj_dir/*.gen/sources_1/bd/*/hw_handoff/ -- has the block design been generated (generate_target all) yet?"
  }
  if {[llength $matches] > 1} {
    error "multiple .hwh candidates found under $proj_dir: $matches -- pass the exact .hwh path to design::discover instead of a project directory"
  }
  return [lindex $matches 0]
}

# path may be either a project directory (p, the parent of p.gen/p.sim/...)
# or the exact .hwh file. Populates TG_BASE, GPIO_BASE_ADDR, URAM_BASE,
# CLK_HZ, GPIO_EXT_BASE_ADDR and GPIO_EXT_CLK_HZ.
proc design::discover {args} {
  variable TG_BASE
  variable GPIO_BASE_ADDR
  variable GPIO_EXT_BASE_ADDR
  variable GPIO_EXT_CLK_HZ
  variable URAM_BASE
  variable CLK_HZ

  chk::nargs design::discover $args 0 1 "?project_dir|hwh_file?"
  lassign $args path
  if {$path eq ""} { set path ./ }
  if {![file exists $path]} {
    error "design::discover: path '$path' does not exist -- expected a generated project directory or the exact top-level .hwh file"
  }
  set hwh_path [expr {[file isdirectory $path] ? [get_hwh_path $path] : $path}]

  set fh [open $hwh_path r]
  set data [read $fh]
  close $fh
  set lines [split $data "\n"]

  array unset TG_BASE
  array set TG_BASE {}
  array unset URAM_BASE
  array set URAM_BASE {}
  set GPIO_BASE_ADDR ""
  set GPIO_EXT_BASE_ADDR ""
  set GPIO_EXT_CLK_HZ ""
  set CLK_HZ ""

  # Every custom_axi_tg instance is named cxl_datapath_<N>_custom_axi_tg_<N>
  # by run.tcl's create_hier_cell_cxl_datapath, so the index appears twice
  # in its own instance name -- the backreference keeps this from matching
  # some other, unrelated instance.
  set cpi_indices {}
  foreach line $lines {
    if {[regexp {MODTYPE="custom_axi_tg"} $line] &&
        [regexp {INSTANCE="cxl_datapath_([0-9]+)_custom_axi_tg_\1"} $line -> idx]} {
      lappend cpi_indices $idx
    }
  }
  if {[llength $cpi_indices] == 0} {
    error "no custom_axi_tg instances found in $hwh_path -- wrong file, or NUM_CPI=0?"
  }
  foreach idx [lsort -unique -integer $cpi_indices] {
    set inst "cxl_datapath_${idx}_custom_axi_tg_${idx}"
    set base ""
    foreach line $lines {
      if {[string first "INSTANCE=\"$inst\"" $line] >= 0 &&
          [regexp {SLAVEBUSINTERFACE="s_axil"} $line] &&
          [regexp {BASEVALUE="(0x[0-9a-fA-F]+)"} $line -> hexval]} {
        set base $hexval
        break
      }
    }
    if {$base eq ""} {
      error "found custom_axi_tg instance $idx in $hwh_path but no s_axil MEMRANGE for it"
    }
    set TG_BASE($idx) [expr {$base}]
  }

  foreach line $lines {
    if {[string first "INSTANCE=\"axil_gpio4_0\"" $line] >= 0 &&
        [regexp {SLAVEBUSINTERFACE="S_AXI"} $line] &&
        [regexp {BASEVALUE="(0x[0-9a-fA-F]+)"} $line -> hexval]} {
      set GPIO_BASE_ADDR [expr {$hexval}]
      break
    }
  }
  if {$GPIO_BASE_ADDR eq ""} {
    puts "WARNING: axil_gpio4_0 base address not found in $hwh_path; hwtg::ext_trigger_all will be unavailable"
  }

  foreach line $lines {
    if {[string first "INSTANCE=\"gpio_ext_axil_0\"" $line] >= 0 &&
        [regexp {SLAVEBUSINTERFACE="S_AXI"} $line] &&
        [regexp {BASEVALUE="(0x[0-9a-fA-F]+)"} $line -> hexval]} {
      set GPIO_EXT_BASE_ADDR [expr {$hexval}]
      break
    }
  }
  if {$GPIO_EXT_BASE_ADDR eq ""} {
    puts "WARNING: gpio_ext_axil_0 base address not found in $hwh_path; gpio:: will be unavailable"
  }

  # The block's CLK_FREQ_HZ parameter is the clock its blink/PWM/debounce
  # timing is built from (run.tcl sets it from the axil_clk frequency); it
  # appears on the PARAMETER lines under the block's own MODULE tag.
  set in_gpio_ext 0
  foreach line $lines {
    if {[regexp {<MODULE } $line]} {
      set in_gpio_ext [expr {[string first "INSTANCE=\"gpio_ext_axil_0\"" $line] >= 0}]
    } elseif {$in_gpio_ext &&
              [regexp {<PARAMETER NAME="CLK_FREQ_HZ" VALUE="([0-9]+)"} $line -> hz]} {
      set GPIO_EXT_CLK_HZ $hz
      break
    }
  }
  if {$GPIO_EXT_CLK_HZ eq "" && $GPIO_EXT_BASE_ADDR ne ""} {
    # Fall back to the PL clock the block runs from
    foreach line $lines {
      if {[regexp {NAME="pl2_ref_clk"} $line] &&
          [regexp {CLKFREQUENCY="([0-9]+)"} $line -> hz]} {
        set GPIO_EXT_CLK_HZ $hz
        break
      }
    }
  }
  if {$GPIO_EXT_CLK_HZ eq "" && $GPIO_EXT_BASE_ADDR ne ""} {
    puts "WARNING: gpio_ext_axil_0 clock frequency not found in $hwh_path -- gpio::led_blink will error until you call design::set_ext_gpio_clk_hz <hz> manually."
  }

  # perf_measurement/uram_sdp_4Kx44_<idx> flattens to
  # perf_measurement_uram_sdp_4Kx44_<idx> -- no backreference needed since
  # this hierarchy is a single top-level cell, not per-CPI.
  set uram_indices {}
  foreach line $lines {
    if {[regexp {MODTYPE="uram_sdp_4Kx44"} $line] &&
        [regexp {INSTANCE="perf_measurement_uram_sdp_4Kx44_([0-9]+)"} $line -> idx]} {
      lappend uram_indices $idx
    }
  }
  foreach idx [lsort -unique -integer $uram_indices] {
    set inst "perf_measurement_uram_sdp_4Kx44_${idx}"
    set base ""
    foreach line $lines {
      if {[string first "INSTANCE=\"$inst\"" $line] >= 0 &&
          [regexp {SLAVEBUSINTERFACE="s_axil"} $line] &&
          [regexp {BASEVALUE="(0x[0-9a-fA-F]+)"} $line -> hexval]} {
        set base $hexval
        break
      }
    }
    if {$base eq ""} {
      error "found uram_sdp_4Kx44 instance $idx in $hwh_path but no s_axil MEMRANGE for it"
    }
    set URAM_BASE($idx) [expr {$base}]
  }
  if {[llength $uram_indices] == 0} {
    puts "WARNING: no uram_sdp_4Kx44 instances found in $hwh_path; perf:: will be unavailable"
  }

  # cxl1_clk drives perf_measurement/clk AND every cxl_datapath_N/m_axi_aclk
  # (run.tcl: both via `connect_bd_net -net cxl1_clk`) -- authoritative for
  # the perf-monitor's freerun_cnt32 tick rate.
  foreach line $lines {
    if {[regexp {NAME="cxl1_clk"} $line] &&
        [regexp {CLKFREQUENCY="([0-9]+)"} $line -> hz]} {
      set CLK_HZ $hz
      break
    }
  }
  if {$CLK_HZ eq ""} {
    puts "WARNING: no PORT with NAME=\"cxl1_clk\" found in $hwh_path -- clock frequency auto-discovery failed."
    puts "WARNING: perf::latency / perf::bandwidth will error until you call design::set_clk_hz <hz> manually."
  } else {
    puts "INFO: clock auto-discovered: CLK_HZ=$CLK_HZ ([format %.2f [expr {$CLK_HZ / 1e6}]] MHz, from cxl1_clk)"
  }

  puts "INFO: design address map discovered from:"
  puts "  $hwh_path"
  puts "INFO: NUM_CPI=[get_num_cpi] (valid datapath indices: [get_cxl_indices])"
  return
}

proc design::get_num_cpi {} { return [llength [get_cxl_indices]] }

proc design::get_cxl_indices {} {
  variable TG_BASE
  return [lsort -integer [array names TG_BASE]]
}

proc design::get_tg_base {cpi} {
  variable TG_BASE
  if {![info exists TG_BASE($cpi)]} {
    error "datapath $cpi does not exist in this design (valid indices: [get_cxl_indices]) -- call design::discover first if this looks wrong"
  }
  return $TG_BASE($cpi)
}

proc design::get_trig_gpio_base {} {
  variable GPIO_BASE_ADDR
  if {$GPIO_BASE_ADDR eq ""} {
    error "axil_gpio4_0 base address is not loaded -- call design::discover first"
  }
  return $GPIO_BASE_ADDR
}

proc design::get_ext_gpio_base {} {
  variable GPIO_EXT_BASE_ADDR
  if {$GPIO_EXT_BASE_ADDR eq ""} {
    error "gpio_ext_axil_0 base address is not loaded -- call design::discover first"
  }
  return $GPIO_EXT_BASE_ADDR
}

proc design::get_ext_gpio_clk_hz {} {
  variable GPIO_EXT_CLK_HZ
  if {$GPIO_EXT_CLK_HZ eq ""} {
    error "gpio_ext_axil_0 clock frequency is not set -- call design::discover (auto-discovery) or design::set_ext_gpio_clk_hz <hz> manually"
  }
  return $GPIO_EXT_CLK_HZ
}

proc design::set_ext_gpio_clk_hz {args} {
  variable GPIO_EXT_CLK_HZ
  chk::nargs design::set_ext_gpio_clk_hz $args 1 1 "hz"
  lassign $args hz
  chk::posnum design::set_ext_gpio_clk_hz hz $hz
  set GPIO_EXT_CLK_HZ $hz
  puts "INFO: gpio_ext_axil_0 clock manually set to $GPIO_EXT_CLK_HZ ([format %.2f [expr {$GPIO_EXT_CLK_HZ / 1e6}]] MHz)"
}

proc design::get_uram_base {cpi iface} {
  variable IFACE_OFFSET
  variable URAM_BASE
  set cpi [chk::int design::get_uram_base cpi $cpi 0]
  if {![info exists IFACE_OFFSET($iface)]} {
    error "unknown perf interface '$iface' (expected one of: [array names IFACE_OFFSET])"
  }
  set idx [expr {$cpi * 4 + $IFACE_OFFSET($iface)}]
  if {![info exists URAM_BASE($idx)]} {
    error "perf uram for cpi=$cpi iface=$iface (idx=$idx) does not exist in this design (valid cpi indices: [get_cxl_indices]) -- call design::discover first if this looks wrong"
  }
  return $URAM_BASE($idx)
}

proc design::get_clk_hz {} {
  variable CLK_HZ
  if {$CLK_HZ eq ""} {
    error "CLK_HZ is not set -- call design::discover (auto-discovery) or design::set_clk_hz <hz> manually"
  }
  return $CLK_HZ
}

proc design::set_clk_hz {args} {
  variable CLK_HZ
  chk::nargs design::set_clk_hz $args 1 1 "hz"
  lassign $args hz
  chk::posnum design::set_clk_hz hz $hz
  set CLK_HZ $hz
  puts "INFO: CLK_HZ manually set to $CLK_HZ ([format %.2f [expr {$CLK_HZ / 1e6}]] MHz)"
}
