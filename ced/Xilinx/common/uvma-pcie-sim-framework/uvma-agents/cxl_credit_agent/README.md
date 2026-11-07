# cxl_credit_agent

A UVM agent, extended from `base_agent`, that drives or monitors a small
credit-return bus (`vld`/`req`/`dat`/`rsp`). Per the header comment in
`cxl_credit_agent.sv`, it models "the credit interface as described of
CPM6 for CXL" — i.e. an AMD CPM6-internal credit-return interface for the
CXL.cache and CXL.mem protocols, not the CXL-spec ALMP/link-layer credit
init messages and not CXL.io. Each of `req`/`dat`/`rsp` is a 4-bit field:
bit[3] selects protocol (`0`=CXL.cache, `1`=CXL.mem, per
`cxl_credit_txn::do_print`) and bits[2:0] carry a log2-scale encoded
credit count (0, 1, 2, 4, 8, 16, 32, 64) via `convert2dec`/`convert2enc`.
The three channels correspond to the Request, Data, and Response virtual
channels being credited.

The agent can be configured as `UVM_MASTER`/`UVM_SLAVE` and
`UVM_ACTIVE`/`UVM_PASSIVE` (`cxl_credit_cfg extends base_cfg`, defaults
`UVM_ACTIVE`/`UVM_MASTER`, per `base_agent`'s `is_master`/`is_active`
gating). As an active master it drives credit returns onto the bus
(via `cxl_credit_api`/`cxl_credit_api_seq`, or autonomously via
`cxl_credit_pool_seq` if `cfg.mst_use_credit_pool`); as a
passive/slave agent it only monitors and publishes observed credit
activity for scoreboards or other subscribers.

## Companion IP Usage
This agent is applicable to only AMD's CPM6 IP, and only when configured in
CXL mode. This is not a generic agent that could be used with any DUT.

## Features
- `cxl_credit_agent_if` exposes `vld`/`req[3:0]`/`dat[3:0]`/`rsp[3:0]`
  plus separate driver (`dcb`) and monitor (`mcb`) clocking blocks; the
  interface drives internal `i_*` nets that are `assign`ed onto the real
  nets so the same interface can be reused unmodified between a
  block-level TB (agent as active master) and a top-level TB (agent
  switched to passive slave) — only `cxl_credit_cfg` needs to change.
- Two transaction types:
  - `cxl_credit_bus_txn`: the wire-level transaction (`vld`+`req`+`dat`+
    `rsp` for one bus cycle); used by the driver/sequencer/API and as
    the monitor's combined output. Provides `get_mem_credits()` /
    `get_cch_credits()` to split a cycle's fields by protocol, and a
    `use_sideband` mode (`req_cred[1:0]`/`dat_cred[1:0]`/`rsp_cred[1:0]`
    int arrays) for feeding the credit pool with amounts >64 or with
    both protocols at once, without being limited by the 3-bit
    log2 encoding.
  - `cxl_credit_txn`: a narrower, single-channel transaction (one
    `credit[3:0]` field + an `info` tag of `"REQ"`/`"DATA"`/`"RSP"`);
    used for the monitor's per-channel decomposed broadcast mode and
    for feeding credits into another agent's pool via `impl_pool`.
- `cxl_credit_monitor` has two broadcast modes selected by `cfg.mon_indi`:
  combined `cxl_credit_bus_txn` (default, published on both `ap` and
  `base_ap`) or three decomposed `cxl_credit_txn`s, one per channel
  (published on `base_ap` only). `cfg.broadcast_all` controls whether
  zero-credit cycles are still published.
- `cxl_credit_share` holds `req_credit_pool[1:0]`/`dat_credit_pool[1:0]`/
  `rsp_credit_pool[1:0]` (indexed by protocol: `[1]`=CXL.mem,
  `[0]`=CXL.cache) and an `any_credits()` helper. The agent's
  `impl_pool`/`impl_pool_bus` analysis imports let any monitored
  transaction (from this or another agent instance) accumulate into
  these pools via `write_pool`/`write_pool_bus`.
- `cxl_credit_pool_seq` runs automatically in `run_phase` when the agent
  is `UVM_MASTER`+`UVM_ACTIVE` and `cfg.mst_use_credit_pool` is set: it
  waits for `shr.any_credits`, grabs the sequencer, randomly selects an
  encodable amount/protocol per channel (bounded by what's actually in
  the pool), and drains the pool one driven beat at a time.
- `cxl_credit_api` (`issue_mem_txns`/`issue_cch_txns`/`issue_txns`) lets
  a test directly request a specific number of CXL.mem and/or CXL.cache
  req/dat/rsp credits be returned; `cxl_credit_api_seq` issues however
  many bus beats are needed (splitting by the log2 encoding) until the
  requested totals are fully sent.
- `cxl_credit_agent_creator::spawn()` helper for one-line agent creation
  plus virtual interface/config registration in `uvm_config_db`.

## Limitations
- Only CXL.cache and CXL.mem credit channels are modeled; CXL.io is not
  represented anywhere in the interface or transaction classes.
- No ALMP or Arb/Mux link-layer framing is modeled — this is a flat
  valid/req/dat/rsp credit-return bus specific to CPM6's internal
  interface, not a decode of any CXL-spec-defined wire format.
- A single driven beat is capped at 64 credits per channel (3-bit log2
  encoding); returning larger amounts still requires multiple beats
  (the `use_sideband` >64 path only feeds the abstract credit pool via
  `impl_pool_bus`, it is not a literal wire encoding).
- The driver's race-avoidance between asserting and de-asserting `vld`
  (`if (vif.mcb.vld != req.vld) @(vif.dcb);`) is a simple one-cycle
  wait, not a full handshake — it assumes the far end samples within
  one clock.
- `cxl_credit_bus_txn::do_compare` skips comparing a channel's credit
  field when it is zero unless `cfg.cmp_zero`/`t.cmp_zero` is set, so a
  transaction that dropped a credit return to zero can be silently
  treated as a match.
- No configurable bus width — `req`/`dat`/`rsp` are fixed at `[3:0]`.

## Files
| File | Purpose |
|---|---|
| `pkg.cxl_credit_agent.sv` | Package wrapper; includes all agent source |
| `cxl_credit_agent_if.sv` | Credit bus interface (`vld`/`req`/`dat`/`rsp`, driver/monitor clocking blocks) |
| `cxl_credit_cfg.sv` | Agent configuration (monitor mode, compare mode, credit-pool usage) |
| `cxl_credit_share.sv` | Shared credit pools (`req`/`dat`/`rsp`, per protocol) |
| `cxl_credit_txn.sv` | Single-channel credit transaction (credit value + REQ/DATA/RSP tag) |
| `cxl_credit_bus_txn.sv` | Wire-level transaction (all three channels for one bus cycle) |
| `cxl_credit_sequencer.sv` | Sequencer; provides `wait_cycles()` off the monitor clocking block |
| `cxl_credit_monitor.sv` | Bus-watching logic; publishes combined or per-channel txns |
| `cxl_credit_driver.sv` | Drives `cxl_credit_bus_txn`s onto the interface |
| `cxl_credit_pool_seq.sv` | Autonomous sequence that drains the shared credit pools |
| `cxl_credit_api_seq.sv` | Sequence backing the API; splits requested credit totals into beats |
| `cxl_credit_api.sv` | User-facing API (`issue_mem_txns`/`issue_cch_txns`/`issue_txns`) |
| `cxl_credit_agent.sv` | Top-level agent; credit-pool bookkeeping; `spawn()` helper |
| `cxl_credit.F` | Compile-order file for the package |
