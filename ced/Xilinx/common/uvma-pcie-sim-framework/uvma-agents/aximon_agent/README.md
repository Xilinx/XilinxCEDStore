# aximon_agent

A passive AXI4 monitor agent, extended from `base_agent`, that observes an
`aximon_if` and reconstructs bus activity for use by scoreboards, coverage
collectors, or other subscribers. It contains no driver/sequencer — it is
`UVM_PASSIVE`/`UVM_SLAVE` only and never drives the bus.

## Companion IP Usage
This agent can be used with any compatible AXI4 interface, it has no 
limitations based on AMD IP.

## Features
- Monitors all five AXI4 channels: AW, W, B, AR, R.
- Publishes two views of the traffic via `aximon_monitor`:
  - `channel_ap`: one `aximon_txn` per beat/handshake on each channel
    (`info` = `CHANNEL`; `info2` = `AW`, `W`, `B`, `AR` or `R`).
  - `ap` (inherited from `base_monitor`): fully reassembled write
    transactions (AW + all W beats + B) and read transactions
    (AR + all R beats), correlated by ID (`info` = `FULL`; `info2` =
    `WRITE` or `READ`).
- Every `aximon_txn` has `txn_type` = `AXIMON_TXN`; `info`/`info2` (above)
  distinguish full from channel txns and say which channel or direction.
- Every signal of a channel is captured in its txn, including the
  `valid`/`ready` handshake signals (and `buser`). Full txns carry the
  signals of every channel they span.
- Read transactions are tracked per-ARID in in-order queues, so interleaved
  read data across multiple outstanding IDs, and multiple outstanding reads
  with the same ID, are supported.
- Write address/data pairing assumes AXI ordering rules (W beats retire in
  the same order as their AW requests), matching them via FIFO queues.
- Configurable bus widths (`addr_width`, `data_width`, `id_width`, and the
  `aw/ar/r/w/buser_width`s) via `aximon_cfg`; they are copied into each txn
  and used when printing and comparing.
- Basic protocol-error detection: these are reported as an error transaction
  (`info` = `CHANNEL`, `info2` = `R` / `B`) published on `ap` rather than
  dropped silently:
  - an R beat with no matching outstanding ARID (`AXI_ERR_RID_NO_ARID`)
  - a B response with no matching AWID (`AXI_ERR_BID_NO_AWID`)
  - a B response whose AW phase completed but whose W phase has not
    (`AXI_ERR_BID_NO_W`)
- `check_phase` reports transactions still outstanding at the end of the sim:
  reads with no completed R, and writes missing their W data, AW, or B
  response. The reporting level is set per direction by the cfg members
  `outstanding_rd_rpt` and `outstanding_wr_rpt` (`AXI_RPT_HIDDEN`,
  `AXI_RPT_INFO`, `AXI_RPT_WARNING` or `AXI_RPT_ERROR`); both default to
  `AXI_RPT_ERROR`.
- `aximon_agent_creator::spawn()` helper for one-line agent creation plus
  virtual interface/config registration in `uvm_config_db`.
- Stateless protocol checks as concurrent assertions in `aximon_if`, reported
  with `` `uvm_error `` (ID `aximon_if`); see "Interface Protocol Checks".

## Interface Protocol Checks
`aximon_if` has an `aresetn` input (clocked by `clk`) and a set of stateless
assertions. Checks that need per-ID or per-beat tracking (e.g. `wlast`/`rlast`
position, response matching) are not done here.

The interface has width variables (`addr_width`, `data_width`, `id_width`,
`awuser_width`, `aruser_width`, `ruser_width`, `wuser_width`, `buser_width`)
matching the `aximon_cfg` members. `aximon_monitor` copies the cfg values into
them in `start_of_simulation_phase`, so the interface and the agent agree. A
width of 0 means the field is unused and the checks depending on it are
disabled. A DUT may drive only the bits it uses, so X/Z in bits above the
configured width is never an error.

Each time `aresetn` deasserts, the interface sanity-checks the widths and
issues a `` `uvm_fatal `` (ID `aximon_if`) if one is out of range:

| Width | Legal values |
|---|---|
| `addr_width` | 1 to 64 |
| `data_width` | power of 2, 8 to 1024 |
| `id_width` | 0 to 32 (0 = no ID) |
| `awuser_width`, `aruser_width`, `wuser_width`, `ruser_width`, `buser_width` | 0 to 256 (0 = unused) |

So `addr_width` and `data_width` must always be set in the cfg.

| Check | Applies to | Rule |
|---|---|---|
| VALID low in reset | AR, AW, W, R, B | VALID must be low while `aresetn` is low. Starts on the second consecutive reset cycle, so a registered VALID has one cycle to clear. |
| VALID hold | AR, AW, W, R, B | VALID high with READY low must stay high next cycle. |
| Payload hold | AR, AW, W, R, B | All payload signals (including user) must be stable while VALID is high and READY is low. |
| Handshake known | AR, AW, W, R, B | VALID and READY must not be X/Z. |
| Control known | AR, AW, W, R, B | While VALID is high: `burst`/`len`/`size`, `wlast`, `rlast`/`rresp`, `bresp` must not be X/Z. |
| Width-limited known | AR, AW, W, R, B | While VALID is high, the low-order configured bits of `addr`, `id`, `wstrb` and the `*user` signals must not be X/Z. |
| `wdata` known | W | Enabled byte lanes (per `wstrb`) must not be X/Z; disabled lanes may be. |
| `rdata` known | R | Must not be X/Z on OKAY/EXOKAY responses; not checked on SLVERR/DECERR. |
| Burst legal | AR, AW | `burst` is not the reserved `2'b11`. |
| WRAP length | AR, AW | `len` is 1, 3, 7 or 15. |
| FIXED length | AR, AW | `len` is 15 or less. |
| INCR 4KB | AR, AW | A burst must not cross a 4KB boundary, measured from the size-aligned start address. |
| Size legal | AR, AW | `8 << size` must not exceed `data_width`. |
| `wstrb` upper clear | W | No `wstrb` bit above `data_width/8` is set (X tolerated). |

Except for the in-reset check, assertions are disabled until `aresetn` is
known to be high. Setting `data_width` is required for the size, `wstrb` and
`wdata`/`rdata` checks to be active.

## Limitations
- Monitor-only: cannot drive AXI stimulus or respond to it; a separate
  driving agent/BFM is required if the DUT needs its AXI interface excited.
- AW-to-W pairing uses FIFOs (arrival order), not per-ID queues, so it relies
  on the DUT/bus obeying AXI4 write ordering rules (no interleaved write
  data); it does not independently verify that ordering. B responses are
  matched to their writes per ID, in order.
- Fixed maximum widths: `aximon_if` is not parameterized (64-bit address,
  1024-bit data, 32-bit ID, 256-bit user fields). The cfg widths can only be
  narrower, and nothing validates them against the interface.
- Limited reset handling: the interface checks VALID signals against
  `aresetn`, but the monitor never clears its queues, so a DUT reset
  mid-transfer leaves stale entries that can be paired with later traffic.
- `SLVERR`/`DECERR` responses are printed in the txn but not flagged as
  errors.
- The interface has no AXI4 `region` or AXI5 signals. Only stateless protocol
  checks are done (see "Interface Protocol Checks"); stateful rules such as
  `wlast`/`rlast` position and per-ID response ordering are not checked. It
  only samples handshake beats on a single clock.
- No support for AXI4 atomics/exclusive access reporting beyond the raw
  `arlock`/`awlock` fields (no separate exclusive-access checking).
- `aresetn` is an input of the interface and must be connected by whoever
  instantiates it.

## Files
| File | Purpose |
|---|---|
| `pkg.aximon_agent.sv` | Package wrapper; includes all agent source |
| `aximon_if.sv` | AXI4 interface (signals, `mcb` monitor clocking block, protocol assertions) |
| `aximon_cfg.sv` | Agent configuration (bus widths) |
| `aximon_txn.sv` | Transaction class (channel + full txns via `info`/`info2`, errors) |
| `aximon_monitor.sv` | Bus-watching logic; publishes to `channel_ap`/`ap` |
| `aximon_agent.sv` | Top-level agent; `spawn()` helper |
| `aximon.F` | Compile-order file for the package |
