================================================================================
 Versal CPM6 CXL Root Port (Versal_CPM6_CXL_RP) - Configurable Example Design
================================================================================

WHAT THIS IS
------------
This CED configures the Versal Premium Gen2 CPM6 hard-IP's Controller 1 as a
Compute Express Link (CXL) Root Port, paired with the license-locked CXL RP
Transaction Layer (TL) IP, and generates a Vivado block diagram from it.
Attach a real CXL Type 3 device to the board, and this design brings the link
up, drives traffic across it, and measures it - on actual silicon.

DESIGN OVERVIEW
----------------
  * CPM6 Ctrl1 is configured as a Gen5x8 (CXL2.0) or Gen6x8 (CXL3.1) CXL
    Root Port.
  * NUM_CPI selects how many CXL protocol-interface (CPI) datapaths are
    instantiated (default 4). Each datapath is a hierarchy
    (cxl_datapath_<N>) containing:
      - pl_axi_cpi_bridge_<N>  - bridges CPI f2a_req/f2a_dat and a2f_dat/
                                  a2f_rsp to a standard AXI interface
      - custom_axi_tg_<N>      - an AXI traffic generator driving that
                                  bridge, with its own AXI-Lite CSR window
  * A shared perf_measurement hierarchy taps all 4 CPI signal groups
    (f2a_req, f2a_data, a2f_data, a2f_rsp) on every active datapath and
    snapshots a {counter,tag} pair into a per-(datapath,interface) URAM on
    every transaction, for post-processed latency/bandwidth reporting.
  * cxl1_clk clocks every datapath's AXI side and the perf-measurement
    block; its frequency is auto-discovered from the generated .hwh (no
    fixed value - depends on CXL_REV/PL0/PL2 reference clock selection).
  * RST_PL (PMC CRP register, fixed address 0xF1260330) carries two fabric
    resets wired into this design: bit 0 (cxl1_rstn) resets every
    datapath's CXL/AXI-side logic plus the perf-monitor viral block; bit 2
    (axil_rstn) resets every custom_axi_tg's CSR side plus the shared GPIO
    block used for synchronized multi-datapath triggering.

ADDRESS MAP
------------
CPM6 Ctrl1 outbound regions expose two fixed PCIe/CXL configuration-space
windows (Local/APU-accessible, independent of other windows used for JTAG 
JTAG bring-up):
  RP (PCIe/CXL config space, local access) ......... 0xE000_0000
  EP (PCIe/CXL config space, remote access) ......... 0xE010_0000

CXL Host-managed Device Memory (HDM) on the attached EP is programmed at a
fixed base of 8 TB (0x800_0000_0000) - safely above the 1 TB an EP typically
advertises, so the assigned range never overlaps host memory below that mark.
EP BARs are placed in an 8 GB low MMIO window by default, falling back to a
256 GB high window if the EP's combined BAR footprint doesn't fit.

Per-CPI PL register windows (systematically assigned, base + index*stride):
  custom_axi_tg_<N>/s_axil   ... 0x0201_0020_0000 + N*0x1_0000, 64 KB each
  perf uram_sdp_4Kx44_<idx>  ... base + idx*0x8000, 32 KB each
                                 (idx = cpi*4 + iface, iface in
                                 f2a_req=0, f2a_data=1, a2f_data=2, a2f_rsp=3)
axil_gpio4_0 (shared multi-datapath trigger GPIO) has its own single base
address. All of the above are read out of the generated project's .hwh, not
hardcoded - see the address-map discovery pass described below.

CONTROLLING THE GENERATED HARDWARE: THE xsdb_scripts TCL PACKAGES
--------------------------------------------------------------------
Once the block diagram above has been generated into a project, xsdb_scripts/
(copied alongside it) gives an interactive xsdb session full control over JTAG
- no processor/software needs to be running on the board:

  design::  - board bring-up (PDI programming, PERSTN toggling, link-status
              check) and the one-time .hwh address-map/clock discovery every
              other package relies on.
  control::  - the raw 32-bit register read/write primitives, plus control of
              the RST_PL bits described above.
  hwtg::    - loads and runs traffic-generator command mnemonics (WRITE/READ/
              WAIT) on each CPI's custom_axi_tg, decodes errors.
  perf::    - reads the per-CPI performance URAMs and reports latency (ns)
              and bandwidth (GB/s), to stdout or to a file.
  ecam::    - reads/decodes PCIe config space and CXL DVSECs at the RP/EP
              windows above; sets up EP BARs and CXL HDM memory ranges.

QUICK START (from an xsdb prompt connected to the JTAG port after generating the design)
------------------------------------------------------------------------------
  xsdb% source xsdb_scripts/all.tcl
  xsdb% design::discover [pwd]
  xsdb% design::connect
  xsdb% design::program  ;# programs boot.pdi/pld.pdi, brings up link
  xsdb% ecam::connect
  xsdb% ecam::setup_ep_bars
  xsdb% ecam::setup_hdm decoder
  xsdb% hwtg::connect
  xsdb% hwtg::load_append 0 "WRITE addr=0x8000000000 repeat=7 addr_k=12 addr_stride=64"
  xsdb% hwtg::load_append 0 "READ  addr=0x8000000000 repeat=7 addr_k=12 addr_stride=64"
  xsdb% hwtg::start 0
  xsdb% hwtg::wait_done 0
  xsdb% perf::connect
  xsdb% perf::report    ;# real latency/bandwidth numbers from hardware

Every package documents itself: run "<pkg>::help" for a command list, or
"<pkg>::help <command>" for detailed usage. Full command reference:
xsdb_scripts/README.md.

REQUIREMENTS
------------
  * Vivado (matching this CED's supported release) with CPM6 + CXL RP TL IP
    license.
  * A Versal Premium Gen2 board with CPM6, JTAG-accessible via hw_server/xsdb.
  * A downstream CXL Type 3 device attached to the link for full hardware
    exercise (traffic generation, performance measurement, HDM setup).
