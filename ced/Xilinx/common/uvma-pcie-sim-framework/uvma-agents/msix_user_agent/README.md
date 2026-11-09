# msix_user_agent

An agent, extended from `base_agent`, for the MSI-X "user" sideband
interface (`msix_user_if`): a request/grant handshake that lets user-side
logic ask the PCIe core's MSI-X module to send an interrupt, check pending
status, or clear pending status, without the user logic building the PCIe
TLP itself. Per `msix_user_if.sv`, the interface carries `user_func_num`
(PF, 3 bits), `user_vfunc_num`/`user_vfunc_active` (VF number + valid bit),
`user_vector_num` (11-bit MSI-X vector), `user_operation` (2-bit opcode:
`SEND_IRQ`/`CHK_PEND`/`CLR_PEND`), the `user_req`/`user_grant` handshake
pair, and a `user_error` status bit.

Like all `base_agent`-derived agents here, activity/role default to
`UVM_ACTIVE`/`UVM_MASTER` (from `base_cfg`, unchanged by `msix_user_cfg`),
so out of the box this agent drives the interface: `msix_user_driver`
drives the request-side signals (`i_user_func_num`, `i_user_vfunc_num`,
`i_user_vfunc_active`, `i_user_vector_num`, `i_user_operation`,
`i_user_req`) on the `dcb` clocking block and waits for `user_grant` on
`mcb` before dropping `user_req` (one outstanding request at a time). The
monitor (`msix_user_monitor`) always runs, independent of activity, and
watches both sides of the handshake. The interface's own comments state
that an active-slave (responder) role is not supported — only
active-master (driving) or passive-slave (monitor-only) are.

## Companion IP Usage
`msix_user_agent.sv` states this agent drives "the CPM6 MSI-X module that
is delivered within CPM6" — i.e. it targets the MSI-X user interface
exposed by AMD's CPM6 (PCIe6.0/CXL3.1) PCIe/CXL hard IP block.

## Features
- Drives the MSI-X request fields as a master by default: PF (`user_func_num`),
  optional VF (`user_vfunc_num`/`user_vfunc_active`), vector
  (`user_vector_num`), and operation (`user_operation`), then asserts
  `user_req` and waits for `user_grant` before deasserting it.
- `msix_user_api::drive(pf, vf, vec, op)` gives a one-line call for
  issuing a request; `vf` defaults to `'x`, which the API interprets as
  "no VF" (`user_vfunc_active = 0`).
- Monitor forks two independent watchers off the `mcb` clocking block: one
  captures a txn on `user_req` (tagged `"REQ"`, gated so the next capture
  waits for `user_grant`), the other captures a txn on every `user_grant`
  (tagged `"GNT"`). `msix_user_agent::steer_txn()` routes these to separate
  `req_ap`/`gnt_ap` analysis ports based on that tag.
- `msix_user_txn::do_print()` decodes `user_operation` into
  `SEND_IRQ`/`CHK_PEND`/`CLR_PEND` and only prints/compares the VF fields
  when `user_vfunc_active` is set (or `cfg.print_vf_always` forces it).
- The interface exposes a `select` bit and `agent_driven` flag so a
  block-level TB can drive `i_user_*` directly through the agent
  configured as master, then move to a top-level TB with the agent as a
  passive slave, without changing the interface — only the config.
- `msix_user_agent_creator::spawn()` helper for one-line agent creation
  plus virtual interface/config registration in `uvm_config_db`.

## Limitations
- Active-slave (auto-responding to requests with a grant) is explicitly
  called out as unsupported in `msix_user_if.sv`; the driver only ever
  drives the request side, never `user_grant`/`user_error`.
- No timeout on the request/grant handshake: both `msix_user_driver` and
  `msix_user_monitor` block indefinitely (`@(... iff user_grant)`) if the
  DUT never grants.
- `user_error` is captured and printed on the txn but is never checked or
  flagged as a protocol error by the monitor.
- Only one request may be outstanding at a time (enforced by the driver
  waiting on `user_grant` before issuing the next), matching the "one
  outstanding a time" comment in `msix_user_driver.sv`.

## Files
| File | Purpose |
|---|---|
| `pkg.msix_user_agent.sv` | Package wrapper; includes all agent source; defines `msix_op_e` |
| `msix_user_if.sv` | MSI-X user sideband interface (signals, `dcb`/`mcb` clocking blocks) |
| `msix_user_cfg.sv` | Agent configuration (`print_vf_always`) |
| `msix_user_txn.sv` | Transaction class (fields, print/compare, operation decode) |
| `msix_user_driver.sv` | Drives request-side signals, waits for grant |
| `msix_user_monitor.sv` | Watches req/grant events, publishes tagged `"REQ"`/`"GNT"` txns |
| `msix_user_api.sv` | `drive(pf, vf, vec, op)` convenience task |
| `msix_user_api_seq.sv` | Sequence used by the API to issue a single txn |
| `msix_user_agent.sv` | Top-level agent; `req_ap`/`gnt_ap` steering; `spawn()` helper |
| `msix_user.F` | Compile-order file for the package |
