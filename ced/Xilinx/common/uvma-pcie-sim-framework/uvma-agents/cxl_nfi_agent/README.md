# cxl_nfi_agent

A UVM agent, extended from `base_agent`, that models CXL.cache and CXL.mem
transaction-layer traffic carried over AMD's flit-mode link interface, known
as the native flite interface (NFI). The interface presents the link as N 
parallel 64B chunks (`cxl_nfi_agent_if`, parameterized by `NFI_W`), where a 
68B Flit Mode link spreads a flit across multiple such chunks and a 256B Flit 
Mode link sends one 64B "slotset" per chunk, four slotsets forming a flit. 
The agent can act as a driving master (link partner sending flits) or a 
reactive slave (backpressuring via `ready`), and supports both flit widths 
from a single agent class, selected via `cxl_nfi_cfg::flitmode`.

## Companion IP Usage
This agent targets AMD's internal CXL.cache/CXL.mem flit-mode link-layer
interface; it is not a generic CXL agent and assumes the NFI signal set
(`data`/`valid`/`ready`/`dec_sop`/`dec_eop`/`dec_be`/`dec_mem`/etc.) defined
in `cxl_nfi_agent_if`.

## Features
- Layered transaction model: CXL.cache/CXL.mem transaction-layer messages
  (`cache_txns.sv`, `mem_txns.sv` — `h2dreq_c`, `h2ddat_c`, `h2drsp_c`,
  `d2hreq_c`, `d2hdat_c`, `d2hrsp_c`, `m2sreq_c`, `m2srwd_c`, `m2sbirsp_c`,
  `s2mndr_c`, `s2mdrs_c`, `s2mbisnp_c`) are packed into link-layer flit
  "slots" (`gslots_f68`/`hslots_f68`/`llslots_f68` for 68B flits;
  `slots_f256` M0-M15 slot formats for 256B flits), which are in turn
  assembled into full `flit68_txn`/`flit256_txn` objects and driven onto
  the NFI as `cxl_nfi_txn`.
- Same layering runs in reverse on receive: the monitor unpacks raw flit
  bits into slot objects, and `flit68_tl_assembler`/`flit256_tl_assembler`
  reconstitute transaction-layer messages (handling multi-slot/multi-flit
  data messages, MDH slots with 2+ packed data headers, and 32B/64B split
  transfers) before broadcasting them out analysis ports.
- Full CXL flit-layer credit management: request/data/response credit
  tracking per protocol (CXL.cache vs CXL.mem) in `cxl_nfi_share`, enforced
  by the driver and cross-checked by the monitor; initial credit exchange
  and steady-state credit return are handled by dedicated sequences.
- Sequence library covering common flows: link initialization
  (`cxl_nfi_mst_init_seq`), periodic credit return
  (`cxl_nfi_mst_crd_give_seq`), in-order flit transmission from a
  pre-built queue (`cxl_nfi_mst_in_order_seq`), fully-random flit
  generation respecting credits and per-flit CXL packing limits
  (`flit68_mst_rand_seq`/`flit256_mst_rand_seq`), "qpacker" sequences that
  drain the `cxl_nfi_share` transaction queues into legally-packed flits
  (`flit68_mst_qpacker_seq`/`flit256_mst_qpacker_seq`), and a reactive
  slave sequence with configurable backpressure profiles
  (`cxl_nfi_slv_seq`).
- `flit68_api`/`flit256_api` give a user-facing `issue_msg()`/`issue_msg_mdh()`
  call to send one (or several MDH-packed) transaction-layer messages into
  a specific slot/flit position without having to hand-build flits.
- Spec-conformance checking built in: tight-packing checks, per-flit and
  per-128B maximum-message-count checks (CXL 3.1 Section 4.2.5), and
  interface-level assertions in `cxl_nfi_agent_if` (max valid count,
  decode-assist alignment, right-alignment, X/Z checks).
- Supports both 68B and 256B Flit Mode (including 256B LOpt split-slot
  handling) from one agent/config; `UNSPEC` mode builds both flit-width
  subsystems so a single agent can be reused across link modes.

## Limitations
  transaction pre/post-randomize, print, copy, and compare methods) and is
  not functional.
- Several transaction classes have `do_compare` left unimplemented
  (`uvm_warning` and hardcoded fail), so scoreboard comparisons on these
  txn types cannot rely on the built-in UVM comparer.
- `m2sbirsp_c`/BIRsp handling is only supported in 256B flit mode; it
  `uvm_fatal`s if used in 68B flit mode, matching the CXL restriction that
  BIRsp isn't defined for 68B flits.
- H6 (IDE) header slot handling in the 68B TL assembler is present but
  flagged with a `uvm_warning` as unsupported/incomplete.
- The credit-give path in F68 mode returns credits only via LLCRD control
  flits or as an off-band `cxl_nfi_credit_txn`; there is no support for
  any other CXL credit-return mechanism.

## Files
| File | Purpose |
|---|---|
| `cache_txns.sv`, `mem_txns.sv` | CXL.cache / CXL.mem transaction-layer message classes (68B and 256B field variants, per-message randomization/print/copy/compare) |
| `slotset_txn.sv`, `cxl_nfi_credit_txn.sv`, `cxl_nfi_txn.sv` | 256B slotset container, credit-return txn, and the raw NFI-width txn driven on the interface |
| `cxl_nfi_agent.sv`, `cxl_nfi_agent_if.sv`, `cxl_nfi_cfg.sv`, `cxl_nfi_driver.sv`, `cxl_nfi_monitor.sv`, `cxl_nfi_sequencer.sv`, `cxl_nfi_share.sv` | Agent core: top-level agent (spawns flit68/flit256 subsystems), NFI interface + assertions, config, driver, monitor, sequencer, and shared credit/queue state |
| `flit_base_txn.sv`, `flit68_txn.sv`, `flit68_tl_assembler.sv`, `flit68_api.sv`, `gslots_f68.sv`, `hslots_f68.sv`, `llslots_f68.sv`, `slot_base.sv` | 68B Flit Mode: flit txn/packing, LL-to-TL assembler, user-facing API, G/H/LL-control slot classes |
| `flit256_txn.sv`, `flit256_tl_assembler.sv`, `flit256_api.sv`, `slot_base_f256.sv`, `slots_f256.sv` | 256B Flit Mode: flit/slotset txn/packing, LL-to-TL assembler, user-facing API, generic M0-M15 slot classes |
| `pkg.cxl31_tl_pkg.sv`, `pkg.cxl31_ll_pkg.sv`, `pkg.cxl_nfi_other_pkg.sv`, `pkg.cxl_nfi_agent.sv` | Package wrappers: CXL 3.1 transaction-layer field enums/structs, link-layer flit-header enums/structs, agent-wide enums, and the agent package `\`include` order |
| `seq/*.sv` | Sequence library: base classes, link init, credit give, in-order/rand/qpacker flit generation, and the reactive slave sequence |
| `cxl_nfi.F` | Compile-order file for the package |
