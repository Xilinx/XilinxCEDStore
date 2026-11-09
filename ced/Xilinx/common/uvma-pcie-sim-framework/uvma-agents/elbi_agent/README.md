# elbi_agent

The ELBI ("External Local Bus Interface") agent is a sideband register-access 
port designed to connect to the AMD CPM6 IP — separate from the main PCIe TLP 
datapath — used to read/write vendor- or application-specific registers. The 
CPM6 IP is a master of this interface, so this agent is designed to act as either 
a passive or reactive slave (with memory model), depending on testing intention.

This agent is a hybrid: `elbi_monitor` always passively reconstructs every
request and response on the bus. `elbi_driver`, however, only drives the
**response** side of a transaction (`ext_lbc_ack`, `ext_lbc_din`,
`ext_lbc_override_en`) — it is used when `elbi_cfg` is configured as
`UVM_SLAVE`+`UVM_ACTIVE`, turning the agent into an active register
*responder* driven by `elbi_slv_base_seq` against the in-memory model in
`elbi_share`. It does not drive the request side (address/data/valid/cs/
access-select); that must come from the DUT or an external requester (see
`sim/tb_top.sv`, which hand-rolls a separate `elbi_master_if` for this
purpose since the agent has no master-mode driving logic).

## Companion IP Usage
This agent was intended to work only with the AMD CPM6 IP.

## Features
- `elbi_monitor` publishes three views of bus activity per transaction:
  requests only (`req_ap`, split by `elbi_agent::steer_txn` into
  `reqext_ap`/`reqint_ap` based on `lbc_ext_cs`), responses only
  (`rsp_ap`), and a combined request+response view (`cmb_ap`).
- Request/response boundaries are edge-detected in `elbi_if.sv`
  (`req_trigger` off `lbc_ext_valid`/`lbc_ext_cs`, `rsp_trigger` off
  `ext_lbc_ack`), so the monitor only samples on real activity.
- Optional active-slave "responder" mode: when `elbi_cfg` is
  `UVM_SLAVE`+`UVM_ACTIVE`, `elbi_agent` auto-starts `elbi_slv_base_seq`,
  which pulls monitored requests from an analysis FIFO, looks them up in
  `elbi_share`, and drives the ack/data response back via `elbi_driver`.
- `elbi_share` models 5 independent, configurable register apertures/spaces
  (APP, MBAR0, IO, EROM, DBI) keyed by physical function (and BAR where
  applicable), each with a configurable uninitialized-access behavior
  (ZEROES/ONES/X/RAND/ERROR/FATAL) and a configurable response delay.
- Byte-enable-qualified partial-DWORD reads/writes are supported, including
  automatic QWORD-boundary address advance when the upper-DW enables are
  set.
- `shared_responder` in `elbi_cfg` toggles the interface `select` line so
  the agent's responses can be muxed alongside another responder (e.g.
  real RTL) driving the same `elbi_if`.
- `elbi_if.sv` carries self-checking SVA (override-enable unused, at most
  one aperture-select active, legal byte-enable patterns, no simultaneous
  read+write) that latch off after first failure to avoid log flooding.
- `elbi_agent_creator::spawn()` helper for one-line agent creation plus
  virtual interface/config registration in `uvm_config_db`.

## Limitations
- No master-mode driving: `elbi_driver` never drives the request-side
  signals (address/data/valid/cs/access-selects), so a `UVM_MASTER`
  configured `elbi_agent` cannot currently stimulate requests on its own.
- The monitor assumes a single outstanding transaction on the interface at
  a time (explicit note in `elbi_monitor.sv`); overlapping/pipelined
  requests are not modeled.
- `ext_lbc_ack` is treated as "any bit rising = good" across the full
  8-bit bus rather than decoded per requesting PF, so responses are not
  explicitly correlated back to a specific PF bit.
- `elbi_slv_base_seq` silently drops any request that doesn't match a
  configured aperture in `elbi_share` (no response, no error txn raised).
- Convenience API sequence/class files (`elbi_api_seq.sv`, `elbi_api.sv`)
  are referenced only as commented-out "enhancement" placeholders in
  `pkg.elbi_agent.sv` — not yet implemented.

## Files
| File | Purpose |
|---|---|
| `pkg.elbi_agent.sv` | Package wrapper; includes all agent source |
| `elbi_if.sv` | ELBI interface (signals, clocking blocks, protocol-checking SVA) |
| `elbi_cfg.sv` | Agent configuration (component/activity from `base_cfg`, `shared_responder`) |
| `elbi_txn.sv` | Transaction class (request + response fields, print/copy/compare) |
| `elbi_share.sv` | Configurable in-memory register model (APP/MBAR0/IO/EROM/DBI apertures) |
| `elbi_driver.sv` | Drives ELBI response signals (`ext_lbc_ack`/`ext_lbc_din`/override) |
| `elbi_monitor.sv` | Observes `elbi_if`; reconstructs request/response/combined transactions |
| `elbi_slv_base_seq.sv` | Default responder sequence: matches requests to apertures via `elbi_share` |
| `elbi_agent.sv` | Top-level agent; analysis port steering; `spawn()` helper |
| `elbi.F` | Compile-order file for the package |
