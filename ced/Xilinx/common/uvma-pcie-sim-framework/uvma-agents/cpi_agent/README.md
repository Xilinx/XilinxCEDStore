# cpi_agent

A composite UVM agent that connects to a Compute Express Link (CXL) Cache/Mem
Protocol Interface (CPI) with the ability to drive and/or monitor sets of 
A2F or F2A channels. conforming to "CPI Spec Rev1.0, 02/2023". The interface 
carries CXL.cache and CXL.mem semantics (opcodes, upstream/downstream ports, 
A2F/F2A directions) over four independent channels: GLOBAL (connection 
management and RAS), REQ (requests), DATA (data payloads), and RSP (responses). 

`cpi_agent` itself contains no driver or monitor of its own — it is a
container that instantiates one `global_agent`, and configurable numbers
(0-8 each) of `req_agent`, `data_agent`, and `rsp_agent` sub-agents, wires
their sequencers into a `cpi_vsequencer` virtual sequencer, and fans out a
shared `cpi_cfg` configuration object to each child. Two `cpi_agent`
instances are needed to model a full CPI interface: one for the A2F
direction and one for F2A (set via `cfg.a2f`). See `images/cpi_agent.drawio`
for a block diagram (open with draw.io).

## Companion IP Usage
This agent implements the CPI Spec Rev1.0 (02/2023) channel protocols and is
not tied to any specific AMD IP; it can be used with any DUT/fabric that
implements a compliant CPI port. However, the AMD CXL Transaction Layer IP
targeted for devices with CPM6 exposes CPI interface(s) that this was intended 
to test.

## Features
- Composite/container agent: `cpi_agent#(REQ,DATA,RSP,P)` parameterizes the
  number of REQ/DATA/RSP sub-agent instances (max 8 each) and spawns them via
  `*_agent_creator::spawn()`, propagating a single `cpi_cfg` down to each
  child's per-channel `cfg` (activity, master/slave, port, CXL.cache/CXL.mem
  support, blocking mode, PBR/flit-mode enables, IDE epoch support, credit
  policy, parity enables, etc.).
- `cpi_vsequencer` aggregates the GLOBAL/REQ/DATA/RSP child sequencers so a
  single `cpi_base_vseq`-derived virtual sequence can drive/observe all
  channels together; `cpi_base_vseq::body()` refuses to run until the GLOBAL
  channel's `conn_state` reaches `CONNECTED`.
- GLOBAL channel (`global_agent`) manages the CPI connect/disconnect
  handshake (`txcon_req`/`rxcon_ack`/`rxdiscon_nack`), RAS signaling
  (`viral`/`fatal`), and an active-slave-only `rx_empty` indication generated
  once total per-channel credit counters across REQ/DATA/RSP return to their
  initial marks.
- REQ/DATA/RSP channels (`req_agent`/`data_agent`/`rsp_agent`) each implement
  the CPI credit-based flow control handshake independently: shared credits
  plus 16 dedicated credits per protocol (CXL.cache/CXL.mem) per VC-ID,
  tracked in `*_share.credit_cnt_ded`/`credit_cnt_shr` and rolled up into the
  GLOBAL channel's totals via a `global_share` handle (`gshr`).
- `*_init_crd_slv_seq` (REQ/DATA/RSP only): an active-slave startup sequence
  that drains the configured initial credit pool (`cfg.init_credit_ded`,
  `cfg.init_credit_shr`) onto the interface as single-cycle credit-return
  transactions, then triggers `init_crd_done`; `cpi_agent::run_phase` waits
  on all children's `init_crd_done` events before declaring the interface's
  initial credits fully returned. GLOBAL has no equivalent sequence because
  it carries no credit-based flow control of its own (only connection
  state and RAS) — there is nothing to initialize.
- `*_api`/`*_api_seq` per channel provide an `issue_msg()`/`control_*()`
  task for masters that checks channel connection state and credit
  availability before issuing a transaction, and computes command/address/
  data/byte-enable parity (with optional error injection) on the way out.
- Interface-level SVA in each `*_if.sv` auto-checks command parity (when
  enabled), the blocking handshake (`*_block`/`*_txblock_crd_flow` vs.
  configured `blocking` delay), and (GLOBAL) unexpected `viral`/`fatal`
  assertions.
- `*_monitor` reconstructs both transfer and credit-return transactions,
  decrementing/incrementing the local and global credit counters and
  flagging `credit_underflow` if a transfer consumes a credit that was
  never granted.

## Limitations
- Blocking (`*_block`/`*_txblock_crd_flow`) and early-valid
  (`*_early_valid`) signaling are tied off/not driven by any channel's
  default sequences — masters only deassert `is_valid` in response to
  block, they don't originate it.
- DATA channel only supports single-beat 64B transfers: `data_hdr_sep` and
  `txfer_32b_en` (32B transfers) are defined in `data_cfg` but not acted on
  by the driver/monitor.
- IDE Containment Mode is not supported on the GLOBAL channel
  (`epoch_id`/`epoch_commit`/`epoch_reject` are wired on `global_if` but
  unused); per-message IDE epoch fields on REQ/DATA are only populated when
  `cfg.ide_epoch_support` is set.
- Credits are assumed to be consumed/returned strictly in order per
  sub-agent; there is no independent credit pool that could allow
  out-of-order (e.g. DED-then-SHR) return sequencing.
- Maximum of 8 instances each of REQ/DATA/RSP sub-agents per `cpi_agent`
  (VCS elaboration constraint on the underlying interface arrays).
- `rsp_if` restricts `rsp_vc_id`/`rsp_rxcrd_vc_id` to VC-ID 0 via assertion
  (per CPI spec), so RSP credits are effectively single-VC despite sharing
  the same dedicated-credit array shape as REQ/DATA.

## Files
| File | Purpose |
|---|---|
| `pkg.cpi_agent.sv` | Package wrapper; includes `cpi_cfg`/`cpi_vsequencer`/`cpi_base_vseq`/`cpi_agent` and imports all four sub-agent packages |
| `pkg.cpi_common.sv` | Shared enums (`api_msg_t`, `port_t`, `generic_ctl_t`, `conn_state_t`, `conn_action_t`) used across all sub-agents |
| `cpi_if.sv` | Top-level interface; instantiates `global_if` plus `req_if[0:7]`/`data_if[0:7]`/`rsp_if[0:7]` arrays and clock fan-out |
| `cpi_cfg.sv` | Composite configuration object fanned out to every child agent's `cfg` |
| `cpi_agent.sv` | Top-level container agent; spawns/configures child agents, wires shared state, waits for initial credit return |
| `cpi_vsequencer.sv` | Virtual sequencer aggregating the GLOBAL/REQ/DATA/RSP child sequencers |
| `cpi_base_vseq.sv` | Base virtual sequence; gates on GLOBAL channel reaching `CONNECTED` |
| `cpi.F` | Compile-order file for the composite package and its four sub-agent packages |
| `global_agent/` | GLOBAL-channel sub-agent: connect/disconnect handshake, RAS (viral/fatal), rx_empty; no credit flow control |
| `req_agent/` | Request-channel sub-agent: CXL.cache/CXL.mem request headers, credit-based flow control, initial-credit drain sequence |
| `data_agent/` | Data-channel sub-agent: 64B data payload + header, byte-enable/poison/parity, credit-based flow control |
| `rsp_agent/` | Response-channel sub-agent: CXL.cache/CXL.mem response headers, credit-based flow control (single VC-ID) |
