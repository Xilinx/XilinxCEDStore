# gpdrv_agent

A generic, reusable driver/monitor agent, extended from `base_agent`, that
drives and observes a single 64-bit generic signal (`sig`) on a `gpdrv_if`.
It isn't tied to any bus protocol — it's meant for driving arbitrary
sideband/GPIO-like wires in a testbench (e.g. straps, mode bits, control/
status signals) where a full protocol-aware agent would be overkill. The 
name "gpdrv" originates from "General Purpose Driver".

## Companion IP Usage
This agent can be used with any signal that needs simple value driving, it
has no limitations based on AMD IP.

## Features
- Drives a value onto a single generic 64-bit signal (`gpdrv_if.sig`),
  decoupled from any specific bus protocol.
- Two drive/sample timing modes selectable via `gpdrv_cfg::sync_control`:
  `SYNC` (driven/sampled through the `cb` clocking block relative to
  `clk`) and `ASYNC` (driven/sampled directly, unclocked).
- `gpdrv_driver::drive_init()` drives a configurable `init_val` before any
  sequence items arrive.
- The built-in monitor continuously watches the signal and publishes a
  `gpdrv_txn` (to both `ap` and `base_ap`) every time its value changes.
- `gpdrv_mon_cb` is a `uvm_callback` hook (`make_specific()`) that the
  monitor invokes on every captured transaction, letting a user enumerate
  `sig` into a human-readable string without subclassing the monitor —
  see `cb/README` for how to attach one.
- `gpdrv_api::drive()` gives a simple blocking call (via `gpdrv_api_seq`)
  to drive an arbitrary 64-bit value through the sequencer.
- Parameterized on both the virtual interface (`VIF`) and transaction
  (`TXN`) types, so users can substitute their own interface/txn
  extensions while reusing the same driver/monitor/agent logic.
- Since it's built on `base_agent`, setting `cfg.activity` to
  `UVM_PASSIVE` turns it into a pure monitor with no driver/sequencer
  (per `gpdrv_if.sv`'s own comment, equivalent to a `gpmon_agent`),
  letting a block-level TB move to a top-level passive TB by changing
  only the config, not the interface.
- `gpdrv_agent_creator::spawn()` helper for one-line agent creation plus
  virtual interface/config registration in `uvm_config_db`.

## Limitations
- Fixed 64-bit signal in `gpdrv_if` (`sig`/`i_sig` are `[63:0]`);
  `gpdrv_cfg::width` only affects txn printing/comparison masking, it
  does not narrow the underlying driven/monitored signal.
- Single scalar signal only — this agent drives/observes one generic
  vector, not a structured or multi-signal bus.
- The monitor only fires on a value change (or, in `SYNC` mode, a clock
  edge where the value differs from the previous sample); it cannot
  represent a "transaction" that re-drives the same value.
- `gpdrv_mon_cb::make_specific()` is a no-op by default — readable
  enumeration of `sig` only appears once a user attaches their own
  callback subclass (see `cb/README`).
- No protocol-level checking: there is no notion of "valid"/handshake
  qualifiers, so timing and meaning of the signal are entirely up to the
  connecting DUT/testbench.

## Files
| File | Purpose |
|---|---|
| `pkg.gpdrv_agent.sv` | Package wrapper; includes all agent source |
| `gpdrv_if.sv` | Generic interface (64-bit signal, clocking block) |
| `gpdrv_cfg.sv` | Agent configuration (width, init value, sync mode) |
| `gpdrv_txn.sv` | Transaction class (signal value, enum strings) |
| `gpdrv_mon_cb.sv` | `uvm_callback` hook for enumerating captured values |
| `gpdrv_monitor.sv` | Watches the signal; publishes `gpdrv_txn` on change |
| `gpdrv_driver.sv` | Drives sequence items onto the signal (sync/async) |
| `gpdrv_api.sv` / `gpdrv_api_seq.sv` | One-shot blocking API to drive a value |
| `gpdrv_agent.sv` | Top-level agent; `spawn()` helper |
| `gpdrv.F` | Compile-order file for the package |
| `cb/README` | Documents how to attach a custom `gpdrv_mon_cb` callback |
