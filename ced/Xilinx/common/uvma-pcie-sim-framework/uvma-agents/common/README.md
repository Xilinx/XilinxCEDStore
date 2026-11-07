# common

This directory holds shared, non-agent-specific utilities used across the other agents' testbenches and simulation flows in this repo. Unlike the other top-level directories, `common/` is not a UVM agent itself — it's infrastructure that per-agent `sim/` testbenches pull in for reporting and running simulations.

## Contents
| File | Purpose |
|---|---|
| `custom_report_server.sv` | A `uvm_report_server` subclass that shortens the filename shown in UVM_INFO/WARNING/ERROR/FATAL message headers to just the basename instead of the full filepath. |
| `Makefile.sim` | A shared Makefile providing common compile/opt/sim/clean targets for QuestaSim and VCS, plus test listing and pass/fail summary reporting. |
| `sim_parselog.py` | A script that scans a simulation log for UVM's WARNING/ERROR/FATAL count summary and prints a colorized one-line PASS/FAIL result. |

## Usage

### custom_report_server.sv
`custom_report_server` extends `uvm_report_server` and overrides `compose_message()`. The body of `compose_message()` is otherwise a direct copy of the base UVM implementation (`base/uvm_report_server.svh`) — the only change is that every place the base class embeds the raw `filename` argument into the message header, this override instead embeds `fname_substr(filename)`. `fname_substr()` walks the string backward from the end looking for the last `/` and returns everything after it (or the whole string if there's no `/`), so a long absolute path like `/proj/.../my_agent/sv/my_driver.sv` prints as just `my_driver.sv` in the `UVM_INFO my_driver.sv(42) @ ...` header instead of the full path. No other behavior of the report server (severity counting, actions, hooks, etc.) is touched.

A test wires this in by constructing the custom server and registering it as the global report server, typically in `build_phase` of a test base class:
```systemverilog
class test_base extends uvm_test;
    custom_report_server my_srvr;
    virtual function void build_phase(uvm_phase phase);
      my_srvr = new;
      uvm_report_server::set_server(my_srvr);
    ...
endclass
```

### Makefile.sim
`Makefile.sim` is meant to be `include`d by each agent's own `sim/Makefile`, which is expected to set variables such as `ROOT_PATH`, `TEST`, and `COMP_FILES` before including it (the file references `$(ROOT_PATH)/base_agent/base.F`, `$(ROOT_PATH)/common/sim_parselog.py`, and `$(COMP_FILES)` without defining them itself). It supports two simulators, selected via `SIM` (`questa` or `vcs`), and exposes these targets:
- `c`/`compile` — runs `vlog` (Questa) or `vlogan` (VCS) against `base_agent/base.F` plus `$(COMP_FILES)` and the testbench top (`$(TOP_FILE).sv`).
- `o`/`opt` — runs `vopt` (Questa) or `vcs` (VCS) to elaborate/optimize the compiled design into a snapshot.
- `s`/`sim` — runs `vsim` (Questa) or `./simv` (VCS) with `+UVM_TESTNAME=$(TEST)`, `+UVM_VERBOSITY`, and seed/GUI handling, then automatically invokes the internal `--print_results` target.
- `cos` — alias that runs `c o s` in sequence.
- `lst` — lists candidate tests in `TEST_DIR`, or (with `PRINT_DESC`) prints a test's leading comment block as its description.
- `cln`/`clean` — removes simulator-generated logs, work libraries, and scratch directories (`work`, `csrc`, `simv.daidir`, etc.).
- `h`/`help` — prints the available targets and current option values (with an optional `ADDL_HELP_PRINT` hook for agent-specific extra help text).

Other supported variables include `GUI`, `SEED`, `VERBOSITY`, `DEFINES` (comma-separated `+define+`), `PLUSARGS` (comma-separated `+` plusargs), and `LSF`. The internal `--print_results` target extracts the random seed actually used from the log, prints a re-run command line, and then shells out to `sim_parselog.py $(LOGFILE)` to print the pass/fail summary.

### sim_parselog.py
Invoked by `Makefile.sim`'s `--print_results` target as `sim_parselog.py <logfile>`. It scans the given log line-by-line (using `^` as the line prefix for `simv.log`/VCS logs, or `^# ` for Questa `transcript`-style logs) for UVM's own end-of-run summary lines — `UVM_WARNING :`, `UVM_ERROR :`, and `UVM_FATAL :` followed by a count — and captures the last-seen count for each. Based on those three counts it prints one colorized `TEST RESULTS = ...` line:
- `ERROR OCCURED` if none of the three counts were found in the log (simulation likely crashed/aborted before printing UVM's summary).
- `PASS` if fatals, errors, and warnings are all 0.
- `PASS WITH N WARNINGS` if fatals/errors are 0 but warnings are non-zero.
- `FAIL WITH N ERRORS` if errors are non-zero.
- `FATAL` if fatals are non-zero (and errors are 0).
