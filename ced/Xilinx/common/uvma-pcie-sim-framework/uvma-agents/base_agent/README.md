# base_agent

The shared, parameterized foundation that every function-specific agent in
this repo extends. `base_agent#()` wires together a set of base classes —
`base_cfg`, `base_txn`, `base_monitor`, `base_driver`, `base_sequencer`,
`base_share`, and `base_api` — via type parameters, so a concrete agent
gets a fully-connected UVM agent (config, monitor, optional driver/sequencer,
optional BFM-style API) just by extending these classes and passing its own
types into `base_agent#(VIF,CFG,SHR,REQ,RSP,TXN,DRV,SQR,MON,API)`. Because
every derived class inherits from a common base with virtual methods, code
written against the base handle works polymorphically against any derived
type — e.g. a scoreboard or subscriber built around `base_txn` (or one of
the generic scoreboards below) can accept, `sprint`, and `compare` any
protocol-specific transaction derived from it without knowing its concrete
type.

## Features
- `base_cfg` exposes `activity` (`UVM_ACTIVE`/`UVM_PASSIVE`) and `component`
  (`UVM_MASTER`/`UVM_SLAVE`) enums, with `is_active`/`is_passive`/
  `is_master`/`is_slave` helpers; these gate what `base_agent::build_phase`
  actually constructs.
- `base_agent::build_phase` always creates `mon` and `shr`; creates `drv`
  and `sqr` only `if (is_active)`; creates `api` only
  `if (is_master && !cfg.disable_api)`. `shr` is published into
  `uvm_config_db` for the monitor/driver/sequencer to pick back up.
- `base_agent::connect_phase` routes every txn coming out of the monitor's
  `ap`/`base_ap` through internal "append" imp ports that stamp
  `cfg.addl_txn_info`/`cfg.compare_addl_txn_info` onto the transaction
  before re-publishing it on the agent's own `ap`/`base_ap` — unless
  `cfg.disable_mon_ap_connect`/`disable_mon_baseap_connect` suppress it.
- For an active slave agent, the monitor's `ap` is also connected to the
  sequencer's `analysis_export`/`analysis_fifo`, giving reactive sequences
  (via `p_sequencer`) a blocking-`get` path to what was just observed on
  the bus so they can shape a response.
- `base_txn` is the root `uvm_sequence_item`: `txn_type`, `uid`, `info`/
  `info2`/`info3`, `timestamp`, and an `addl_info[$:4]` queue, with working
  `do_copy`/`do_print`/`do_compare` (respecting `compare_info`/
  `compare_addl_info` depth controls) and a `stamp()` method. `hash()` is a
  stub that warns and returns 0 — real agents must override it to use
  `base_hash_sb`.
- `base_driver` supplies a default `run_phase` (`get_next_item` /
  `drive_item` / `item_done`) plus `waiting`/`processing` status bits;
  derived agents only need to fill in `drive_init()`/`drive_item()`.
- `base_monitor`/`base_driver`/`base_sequencer` all pull their `cfg`
  (and `vif`, `shr` where applicable) from `uvm_config_db` in `build_phase`
  and `uvm_fatal` if any handle is missing.
- `base_share` is an intentionally empty `uvm_object` — a single handle
  type distributed to the monitor/driver/sequencer for passing dynamic,
  agent-specific runtime state between them; derived agents extend it to
  add whatever fields they need.
- `base_api` holds only a `sqr` handle; derived agents extend it to add
  BFM-style tasks/functions (e.g. `write()`/`read()`) that build and start
  sequences on that sequencer.
- Every class defines a `const static string type_name` (since
  `uvm_component_param_utils`/`uvm_object_utils` don't generate
  `get_type_name()` for parameterized classes), so heavily-templated agent
  stacks still print readable type names in UVM logs.

## Scoreboard Base Classes
`other/` provides generic, protocol-agnostic scoreboard bases that operate
purely through `TXN::compare()`/`hash()`, each with a different matching
strategy:
- `base_hash_sb#(TXN)`: keys expected transactions by `TXN::hash()` in an
  associative array (with a duplicate-count map for repeated hashes) and
  looks up actual transactions by hash — order-independent, but requires
  every derived `TXN` to override `hash()` meaningfully.
- `base_in_order_sb#(TXN)`: keeps expected transactions in a queue and
  compares an actual transaction starting from the front; if the match
  isn't the very first entry, it flags an out-of-order error and discards
  everything up to and including the match.
- `base_out_order_sb#(TXN)`: keeps expected transactions in a queue with no
  ordering assumption, searches the whole queue for a match, and on a
  miscompare reports the closest (fewest-mismatch) candidate.
- `print_sb#(TXN)`: not a comparator — a `uvm_subscriber` that simply
  stamps and `uvm_info`-prints every transaction it receives, useful as a
  lightweight debug tap.

## Limitations
- `base_driver::drive_init()`/`drive_item()` are empty virtual methods, not
  pure virtual (the code notes VCS complained about pure virtual here), so
  a derived driver that forgets to override `drive_item()` compiles fine
  but silently drives nothing.
- `base_share` and `base_api` are empty scaffolding; all real behavior must
  be added by the derived agent — `base_agent` itself contains no protocol
  logic.
- `base_txn::hash()` defaults to a warning + `0`, so `base_hash_sb` is not
  usable out of the box until a derived transaction overrides it.
- `cfg` must already be set or available via `uvm_config_db` before
  `build_phase`; `base_agent` provides no default/example configuration.
- The active-slave reactive path only wires the plumbing (monitor ->
  sequencer analysis FIFO); it does not supply any base reactive sequence,
  so each derived agent must write its own `p_sequencer`-based sequence to
  consume it.
- The scoreboard base classes are not protocol-aware — they trust
  `compare_info`/`compare_addl_info` on the transaction (set from
  `base_cfg`) to decide what fields are actually checked.

## Files
| File | Purpose |
|---|---|
| `pkg.base_agent.sv` | Package wrapper; includes cfg/share/txn/driver/monitor/sequencer/api/agent |
| `base_cfg.sv` | Agent configuration: activity/component enums, uid, addl txn info, disable switches |
| `base_share.sv` | Empty shared-state object handle passed to driver/monitor/sequencer |
| `base_txn.sv` | Root transaction class: `do_copy`/`do_print`/`do_compare`, `hash()`, `stamp()` |
| `base_driver.sv` | Parameterized `uvm_driver`; default get/drive/item_done loop; drive hooks |
| `base_monitor.sv` | Parameterized `uvm_monitor`; pulls cfg/vif/shr; exposes `ap`/`base_ap` |
| `base_sequencer.sv` | Parameterized `uvm_sequencer`; `analysis_export`/`analysis_fifo` for reactive sequences |
| `base_api.sv` | Holds the sequencer handle for BFM-style task wrappers in derived agents |
| `base_agent.sv` | Top-level agent; build/connect wiring gated by activity/component |
| `base.F` | Compile-order file for `base_agent` plus `other/` scoreboard package |
| `other/pkg.base_sb.sv` | Package wrapper for the generic scoreboard base classes |
| `other/base_hash_sb.sv` | Hash-keyed, order-independent scoreboard |
| `other/base_in_order_sb.sv` | Queue-based scoreboard enforcing expected order |
| `other/base_out_order_sb.sv` | Queue-based scoreboard, no order assumption, best-match reporting |
| `other/print_sb.sv` | `uvm_subscriber` that prints every transaction received (not a comparator) |
