# cfg_ext_agent

Models the AMD/Xilinx PCIe hard-IP "Configuration Extend" interface — the
out-of-band request/response bus a PCIe integrated block uses to hand off
reads and writes of extended/vendor-defined configuration-space registers to
user logic. `cfg_ext_register_number`/`cfg_ext_function_number` identify the
dword and function being accessed, `cfg_ext_write_received`/`write_data`/
`write_byte_enable` carry a write, and `cfg_ext_read_received` paired with
`cfg_ext_read_data`/`read_data_valid` carries a read and its (possibly
delayed) response. Extended from `base_agent`, it uses no dedicated
`cfg_ext_cfg` — role is selected purely through `base_cfg`'s
`activity`/`component` enums (default `UVM_ACTIVE`/`UVM_MASTER`):
- **Active master** — `cfg_ext_api`'s `write()`/`read()` tasks generate
  WRITE/READ_REQ items that `cfg_ext_driver` drives, playing the role of the
  PCIe core issuing config-extend requests.
- **Active slave** — `cfg_ext_agent::start_of_simulation_phase` auto-starts
  `cfg_ext_slv_base_seq`, a reactive sequence that consumes monitored
  requests and drives READ_RSP data back, playing the role of the user's
  extended-config-space logic.
- **Passive** (`UVM_PASSIVE`) — only `cfg_ext_monitor` is built; it observes
  the bus and reconstructs transactions without driving anything.

## Companion IP Usage
The Configuration Extend Interface is exposed by AMD/Xilinx PCIe hard IP -
applicable to UltraScale+ Integrated Block for PCIe and Versal CPM4,CPM5) - 
for implementing extended config space in user logic. This agent is IP-specific 
to that interface.

## Features
- Represents WRITE / READ_REQ / READ_RSP as three `info` variants of a single
  `cfg_ext_txn`, all carried over one interface.
- `cfg_ext_api::write()`/`read()` give master-mode sequences simple,
  dword-oriented tasks; both fatal if `addr[1:0] != 0` since the interface
  is dword-addressed via `register_number`, and `write()`/`read()` do the
  address-to-`register_number` (`addr[11:2]`) conversion internally.
- `cfg_ext_driver` splits drive tasks by role exactly as the interface's
  in-file comments dictate: `drive_write`/`drive_read_req` are master-only,
  `drive_read_rsp` is active-slave-only.
- `cfg_ext_slv_base_seq` is a reactive responder: it blocks on
  `p_sequencer.analysis_fifo.get()`, applies writes and produces read data
  through `cfg_ext_share` (`poke_byte`/`peek_dword`), and replies after a
  randomized `rd_rsp_delay` (`$urandom(9)` cycles). It is auto-started by the
  agent only `if (is_slave && is_active)`, and can be swapped via the UVM
  factory.
- `cfg_ext_share` models a byte-addressable 4KB extended config space
  (`bit [11:0]` address) with `poke_byte/hword/dword` and
  `peek_byte/hword/dword`; unwritten bytes are zero-filled with a
  `uvm_warning` rather than silently returning `X`.
- `cfg_ext_monitor` reconstructs transactions from the bus and, for a
  READ_REQ, waits up to `'h4_0000` clocks for the matching
  `cfg_ext_read_data_valid`, tagging `txn.info2 = "TIMEOUT"` if the response
  never arrives instead of hanging.
- `cfg_ext_rsp_if` is a separate companion interface with its own built-in
  write-memory and randomized-delay read responder processes, so a real
  driving master can be exercised and snooped by a purely passive
  `cfg_ext_agent` without needing an active-slave responder in the testbench.
- `cfg_ext_if`'s split between the driven `cfg_ext_*` nets and the `i_cfg_ext_*`
  signals (documented in-file) lets the same passive monitor work whether a
  block-level TB drives `i_*` directly through a master agent, or a top-level
  TB drives the real signals externally — only the `cfg` object changes.

## Limitations
- No `cfg_ext_cfg.sv`: role/behavior is controlled entirely by generic
  `base_cfg` `activity`/`component` enums; there are no cfg_ext-specific
  knobs (e.g. no per-function-number checking enable, no way to disable
  read or write handling independently).
- `cfg_ext_share`'s `cfgspace` is a single flat byte map; it does not
  partition storage by `cfg_ext_function_number`, so multi-function extended
  config space is not modeled distinctly per function.
- `cfg_ext_api` only exposes dword-granular reads and byte-enable-qualified
  dword writes; there is no way to issue a read with partial byte enables
  (matching the real interface, which has none for reads).
- The slave responder always answers with the current `shr` contents after a
  `$urandom(9)`-cycle delay; it has no mechanism to model error/UR
  completions or a configurable, deterministic delay profile.
- The monitor's read-response timeout (`'h4_0000` clocks) is a hardcoded
  constant, not exposed through any config object.

## Files
| File | Purpose |
|---|---|
| `pkg.cfg_ext_agent.sv` | Package wrapper; includes both interfaces and all agent source |
| `cfg_ext_if.sv` | Primary interface: request signals owned by the master, response signals owned by the active slave, clocking block `cb` |
| `cfg_ext_rsp_if.sv` | Companion interface with a built-in write-memory + randomized-delay read responder, for snooping a real master |
| `cfg_ext_txn.sv` | Transaction class; WRITE/READ_REQ/READ_RSP variants selected via `info`, plus `rd_rsp_delay` |
| `cfg_ext_share.sv` | Shared byte-addressable extended-config-space model (`poke_*`/`peek_*`) used by the slave responder sequence |
| `cfg_ext_driver.sv` | Drives WRITE/READ_REQ (master) and READ_RSP (active slave) items onto the interface |
| `cfg_ext_monitor.sv` | Reconstructs WRITE/READ_REQ/READ_RSP transactions, with read-response timeout detection |
| `cfg_ext_api.sv` | Master-mode `write()`/`read()` tasks built on `cfg_ext_api_seq` |
| `cfg_ext_api_seq.sv` | Sequence that builds a WRITE or READ_REQ `cfg_ext_txn` from `cfg_ext_api` arguments |
| `cfg_ext_slv_base_seq.sv` | Default active-slave responder sequence; consumes monitored requests, drives read responses |
| `cfg_ext_agent.sv` | Top-level agent; auto-starts the slave responder sequence when `is_slave && is_active`; `cfg_ext_agent_creator::spawn()` helper |
| `cfg_ext.F` | Compile-order file for the package |
