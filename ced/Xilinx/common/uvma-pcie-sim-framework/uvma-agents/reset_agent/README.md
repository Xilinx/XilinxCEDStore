# reset_agent

An agent, extended from `base_agent`, that drives and/or observes a single
reset net exposed by `reset_if`. Per `reset_cfg`'s defaults it is
`UVM_ACTIVE`/`UVM_MASTER`, so it builds a `reset_driver` and sequencer and is
normally used to assert, deassert, and pulse a DUT reset from the testbench
via `reset_api`. The same code can be repointed to `UVM_PASSIVE` (and/or
`UVM_SLAVE`) purely by changing `reset_cfg.activity`/`component` — the
interface itself never changes — so it can equally be used monitor-only to
observe a reset driven by something else (e.g. the DUT or a top-level TB).
The `reset` signal is active-low by default (`active_val = ACTIVE_LO` in
`reset_cfg`), matching this repo's active-low synchronous reset convention
for RTL, but polarity is fully configurable per instance to active-high.

## Companion IP Usage
This agent can be used with any DUT reset input or output, it has no
limitations based on AMD IP — `reset_if` is a single generic `reset`/`clk`
pair with no protocol-specific fields.

## Features
- Drives `ASSERT`, `DEASSERT`, `ASSERT_PULSE`, and `DEASSERT_PULSE` actions
  through `reset_api` (`set_reset`, `set_reset_pulse_cycles`,
  `set_reset_pulse_time`).
- Each assert/deassert edge is independently driveable `SYNC` (via the
  interface's `cb` clocking block, aligned to `posedge clk`) or `ASYNC`
  (direct drive); requesting `SYNC` when `reset_cfg.has_clk` is `0` is a
  `uvm_fatal`.
- Pulse actions take a configurable hold length as either `hold_cycles`
  (clock cycles, checked via the clocking block) or `hold_time` (an
  absolute delay), with `hold_cycles` taking precedence when both are set;
  these are plain (non-`rand`) fields on `reset_txn`/`reset_api_seq`, so the
  caller supplies the value (e.g. from its own randomization) rather than
  the agent solving it via `randomize()`.
- `drive_init` forces the net to `cfg.active_val` at the start of
  simulation, so the reset begins in the asserted state.
- Redundant direction requests (e.g. `ASSERT` while already asserted) raise
  a `uvm_warning`; a pulse request issued from the "wrong" starting state
  degrades to a single opposite-direction edge instead of a true pulse.
- `reset_monitor` continuously watches `vif.reset` and emits one
  `reset_txn` per transition, classifying it as `ASSERT`, `DEASSERT`,
  `WENT_X`, or `WENT_Z` relative to `cfg.active_val`, published on both the
  typed `ap` and the `base_ap`.
- Per-instance polarity (`active_val`: `ACTIVE_LO`/`ACTIVE_HI`) and
  clocked/clockless (`has_clk`) behavior configured via `reset_cfg`.
- `reset_agent_creator::spawn()` helper for one-line agent creation plus
  virtual interface/config registration in `uvm_config_db`.

## Limitations
- Single-bit reset only: `reset_if` models one `reset` wire and one `clk`;
  there is no support for a multi-bit/vectorized reset bus within one agent
  instance.
- `hold_cycles`/`hold_time` are plain fields, not declared `rand` — the
  agent provides no built-in constrained-random pulse-width generation;
  any randomization must happen in the caller before invoking the API.
- A clockless reset (`has_clk = 0`) combined with a `SYNC` assert/deassert
  request is a `uvm_fatal` rather than a graceful fallback to async.
- The monitor only reports the net's state relative to `active_val` (plus
  `X`/`Z` anomalies) on each transition; it does not timestamp or measure
  pulse widths, nor otherwise analyze reset behavior beyond the edge
  transactions themselves.
- `reset_if` documents that only one driver may drive the `reset` net at a
  time — the agent and any other testbench logic cannot both drive it
  simultaneously.

## Files
| File | Purpose |
|---|---|
| `pkg.reset_agent.sv` | Package wrapper; defines shared enums; includes all agent source |
| `reset_if.sv` | Reset interface (`clk`, `reset`, internal `i_reset` driver net, clocking block) |
| `reset_cfg.sv` | Agent configuration (`has_clk`, `active_val`) |
| `reset_txn.sv` | Transaction class (action, sync/async type, pulse hold cycles/time) |
| `reset_driver.sv` | Drives assert/deassert/pulse actions per `reset_txn`, sync or async |
| `reset_monitor.sv` | Watches `vif.reset`; publishes an `ASSERT`/`DEASSERT`/`WENT_X`/`WENT_Z` `reset_txn` per edge |
| `reset_api.sv` | Sequencer-facing API: `set_reset`, `set_reset_pulse_cycles`, `set_reset_pulse_time` |
| `reset_api_seq.sv` | Sequence used by `reset_api` to send a `reset_txn` to the driver |
| `reset_agent.sv` | Top-level agent; `reset_agent_creator::spawn()` helper |
| `reset.F` | Compile-order file for the package |
