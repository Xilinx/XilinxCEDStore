# gpmon_agent

A passive "general purpose monitor" agent, extended from `base_agent`, that
watches a single flat `[63:0]` vector on `gpmon_if` and reports each change
as a `gpmon_txn`. It contains no driver/sequencer — it is
`UVM_PASSIVE`/`UVM_SLAVE` only. On its own the interface carries no protocol
semantics; meaning is added by attaching callback classes (see `cb/`) that
decode the raw bits into a human-readable string.

## Companion IP Usage
`gpmon_if` itself is protocol-agnostic — it is just a clocked bit vector and
can be wired to any status/debug signal. The bundled callback classes in
`cb/`, however, decode fields that match PCIe link-training/status
encodings (LTSSM state, negotiated speed/width, DL/link-up status, function
enables). The package comment describes these as "part of the status
interface that go to the PL," i.e. status ports exposed by an AMD PCIe
controller/core (e.g. a Versal CPM/PCIe hard IP). Any other bus or wire can
still be monitored by writing a custom callback instead of the bundled ones.
Custom or pre-packaged callback classes can be specified in each application
to uniquify and provide context to each transaction; these callbacks may be
IP-specific.

## Features
- Samples `gpmon_if.sig` and publishes a `gpmon_txn` only when its value
  changes (compares against the previous sample each iteration).
- `cfg.sync_control` selects `SYNC` (change detected relative to
  `vif.cb`, sampled on `posedge clk`) or `ASYNC` (triggers directly off any
  transition of `sig`, independent of the clock).
- `cfg.drop_first` discards the first observed transition, useful for
  ignoring the X-to-valid transition at reset/startup.
- Callback-based decode: `gpmon_mon_cb#(TXN)::make_specific()` is invoked on
  every sample via a hand-rolled `uvm_register_cb`-style macro (needed
  because the built-in macro can't handle parameterized types), letting
  callbacks fill in `txn.sig_enum` / `txn.ml_sig_enum` without requiring a
  bespoke monitor or transaction type per signal.
- Ships six ready-made callbacks in `cb/` for common PCIe status signals:
  - `ltssm_cb` — decodes `sig[5:0]` into the LTSSM state name (Detect,
    Polling, Configuration, Recovery, L0/L1/L2, Loopback, Hot Reset,
    Recovery.Eq phases, etc.).
  - `current_speed_cb` — decodes `sig[2:0]` into the negotiated link speed
    (Gen1 - Gen5).
  - `negotiated_width_cb` — decodes `sig[2:0]` into the negotiated link
    width (x1 - x16).
  - `link_status_cb` — decodes `sig[1:0]` into receiver-detect/training/
    DL-init link status.
  - `link_down_cb` — decodes `sig[0]` into a link up/down string.
  - `function_status_cb` — decodes `sig[3:0]` into I/O space, memory
    space, bus-master, and INTx enable bits for a function.
  - See `cb/README` for how to attach a callback (or write your own) to a
    `gpmon_monitor` — none of these are built in automatically.
- Publishes each `gpmon_txn` on `ap` and the corresponding `base_txn` on
  `base_ap`, matching the dual-analysis-port pattern used elsewhere in this
  agent library.
- `gpmon_agent_creator::spawn()` helper for one-line agent creation plus
  virtual interface/config registration in `uvm_config_db`.
- Configurable comparison/print width (`cfg.width`) and print radix/value
  used by `gpmon_txn::do_print`/`do_compare`.

## Limitations
- `gpmon_if` carries a single opaque bit vector with no address/data
  channels or protocol framing; correctly decoding it depends entirely on
  the attached callback knowing the right bit positions for that signal.
- Bundled `cb/` callbacks assume fixed bit widths/positions (e.g. LTSSM at
  `sig[5:0]`, speed/width at `sig[2:0]`) matching one particular PCIe
  status-port layout; if the monitored signal uses a different mapping the
  decode is silently wrong, since there is no cross-check against an actual
  PCIe capability register.
- Callbacks must be created and attached manually via
  `uvm_callbacks#(...)::add()`; nothing in `gpmon_agent`/`gpmon_monitor`
  attaches them automatically (see `cb/README`).
- `txn.ml_sig_enum` is cleared after every publish (since the transaction
  object is reused, not re-`new`-ed), so a callback that wants multi-line
  output must repopulate it on every call.
- Monitor-only: cannot drive or inject values onto `sig`.

## Files
| File | Purpose |
|---|---|
| `pkg.gpmon_agent.sv` | Package wrapper; includes all agent source and the `cb/` callbacks |
| `gpmon_if.sv` | Interface: clocked `[63:0]` signal bus with a clocking block |
| `gpmon_cfg.sv` | Agent configuration (width, sync/async control, print options, drop-first) |
| `gpmon_txn.sv` | Transaction class (raw value plus decoded `sig_enum`/`ml_sig_enum`) |
| `gpmon_mon_cb.sv` | Base callback class defining `make_specific()` |
| `gpmon_monitor.sv` | Sampling logic; change detection; callback dispatch; publishes to `ap`/`base_ap` |
| `gpmon_agent.sv` | Top-level agent and `spawn()` helper |
| `gpmon.F` | Compile-order file for the package |
| `cb/current_speed_cb.sv` | Decodes negotiated link speed (Gen1 - Gen5) |
| `cb/function_status_cb.sv` | Decodes I/O space, memory space, bus-master, INTx enables |
| `cb/link_down_cb.sv` | Decodes link up/down |
| `cb/link_status_cb.sv` | Decodes receiver-detect/training/DL-init link status |
| `cb/ltssm_cb.sv` | Decodes LTSSM state |
| `cb/negotiated_width_cb.sv` | Decodes negotiated link width (x1 - x16) |
| `cb/README` | Explains that callbacks must be manually attached to a `gpmon_agent` |
