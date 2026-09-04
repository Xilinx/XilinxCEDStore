# perf_pkg.tcl
#
# Constants mirrored from the Performance URAM RTL. Keep in sync by hand
# with: src/uram_sdp_4Kx44.sv (entry layout, depth, addr decode),
# src/cpi_perf_snapshot.sv (concat = {cnt, tag[11:0]} packing),
# src/freerun_cnt32.sv (32-bit counter), run.tcl (perf_iface_map naming
# offsets).

namespace eval perf {
  variable MAX_ENTRIES  4096   ;# raddr/waddr are 12 bits
  variable ENTRY_STRIDE 8      ;# bytes; araddr[3+:12] = raddr

  # Entry = 44 bits in the low bits of a 64-bit read word: {cnt[31:0], tag[11:0]}
  variable CNT_SHIFT 12
  variable CNT_MASK  0xFFFFFFFF
  variable TAG_MASK  0xFFF

  variable IFACE_NAMES {f2a_req f2a_data a2f_data a2f_rsp}

  # Latency pairing (CXL bridge topology): FIFO-per-tag within each pair
  variable LATENCY_PATHS
  array set LATENCY_PATHS {
    read  {f2a_req  a2f_data}
    write {f2a_data a2f_rsp}
  }

  variable FREERUN_WIDTH 32          ;# src/freerun_cnt32.sv
  variable BYTES_PER_XFER 64         ;# custom_axi_tg.sv AXI_DATA_WIDTH=512 bits

  # A tag-matched delta (or a bandwidth span) exceeding this fraction of the
  # freerun_cnt32 rollover period is treated as a bad/rollover-crossed match
  # and excluded rather than reported -- named here instead of inlined so
  # it's tunable without hunting through pair_latency/combine_bandwidth.
  variable ROLLOVER_REJECT_FRACTION 0.5
}
