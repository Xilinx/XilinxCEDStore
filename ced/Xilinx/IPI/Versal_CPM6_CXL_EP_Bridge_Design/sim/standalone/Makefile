# Self-contained VCS compile/elaborate/simulate targets for the Avery/UVM
# testbench, run entirely from this CED directory (no external regression-
# harness or sim-framework dependency). SIM=questa is not implemented (VCS-only).
#
# Requires: $AVERY_PCIE/$AVERY_SIM (Avery VIP install+license), $AVERY_PLI
# (Avery VCS PLI table+lib), $CPM6_SECUREIP (CPM6 SecureIP netlist),
# VCS X-2025.06(-SP2).

# Path-derived (not CURDIR-relative) so `make -C <builddir> -f <path>` works
# from any CWD; build artifacts land in CWD, not the checked-in tree.
SIM_ROOT      := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))..)
PROJ_DIR      ?= $(SIM_ROOT)/standalone/proj
CTRL          ?= 1
TEST          ?= cxl_ep_brdg_sanity
SEED          ?= random
# Gen5/CXL_2_0 (5) or Gen6/CXL_3_1 (6). Must match the DUT's own build
# (build_project.tcl) - not cross-checked here.
SPEED         ?= 6
# Link width in lanes (4 or 8) - forwarded to both build_project.tcl and
# tb_top.sv's LINK{0,1}_WIDTH. Must match the DUT build; rebuild `project`
# after changing.
WIDTH         ?= 8
CXL_PROTOCOL  := $(if $(filter 5,$(SPEED)),CXL_2_0,CXL_3_1)
UVM_VERBOSITY ?= UVM_MEDIUM
SIM_TIMEOUT   ?= 5000us
GUI           ?= 0
# Read by design_1_bd.tcl at `project:` time. Without this,
# axi_memory_init_{0,1,2,3} default to a full 4GB decode/init window instead
# of the 1KB this test needs, and CXL.mem traffic stalls behind it (looks
# like a hang, not a clear error).
export SIM_QUICK_MEM_INIT ?= 1
PCIE_LINK     ?= PIPE
DEFINES       ?=
PLUSARGS      ?=

# Compiled against the real, non-decrypted CPM6 secure-IP, so needs
# CPM6_VIVADO (not CPM6_RTL) both as a vlogan +define+ and a runtime plusarg.
CPM6_DEFINE   := +define+CPM6_VIVADO
CPM6_PARG     := +CPM6_VIVADO

# Avery's VIP defaults to MAX_DATA_WIDTH=4 (enough for Gen1-5); Gen6's PAM4
# encoding needs 8, else a UVM_FATAL fires mid-sim.
AVERY_DEFINE  := +define+APCI_MAX_DATA_WIDTH=8

ifeq ($(CTRL),0)
  DEFINE_CTRL   := +define+CXL_BRDG_CTRL0
  LINK_GENERICS := -pvalue tb_top.LINK0_WIDTH=$(WIDTH) -pvalue tb_top.LINK1_WIDTH=0
  PARG          := +CTRLR0_EN=1 +CTRLR0_SPEED=$(SPEED) +CTRLR0_FM=1 +CTRLR1_EN=0
  CTRL_NAME     := Controller_0
else
  DEFINE_CTRL   := +define+CXL_BRDG_CTRL1
  LINK_GENERICS := -pvalue tb_top.LINK0_WIDTH=0 -pvalue tb_top.LINK1_WIDTH=$(WIDTH)
  PARG          := +CTRLR0_EN=0 +CTRLR1_EN=1 +CTRLR1_SPEED=$(SPEED) +CTRLR1_FM=1
  CTRL_NAME     := Controller_1
endif

# Vivado-generated DUT compile/elaborate scripts (from build_project.tcl).
DUT_SIM_DIR := $(PROJ_DIR)/design_1.sim/sim_1/behav/vcs

# Vivado's separate "xlnoc" NoC block-design sim source (see xlnoc_glue.v).
XLNOC_SIM_V := $(PROJ_DIR)/design_1.gen/sim_1/bd/xlnoc/sim/xlnoc.v

INCDIRS := +incdir+$(SIM_ROOT)/verif \
           +incdir+$(SIM_ROOT)/verif/test \
           +incdir+$(SIM_ROOT)/tb \
           +incdir+$(SIM_ROOT)/tb/env \
           +incdir+$(SIM_ROOT)/tb/env/shim \
           +incdir+$(SIM_ROOT)/tb/env/shim/seq \
           +incdir+$(SIM_ROOT)/tb/env/shim/caps \
           +incdir+$(SIM_ROOT)/tb/env/shim/ecaps \
           +incdir+$(SIM_ROOT)/tb/env/pcie_cfg \
           +incdir+$(SIM_ROOT)/tb/env/seq/axi_mst \
           +incdir+$(SIM_ROOT)/tb/env/seq/axi_mst/cxl_mbox \
           +incdir+$(SIM_ROOT)/tb/test
# cxl_mbox/ and pcie_cfg/axi_mst dirs needed for bare `include`s reachable
# only via these incdirs (base_log.sv, dut_reg_pkg.svh, seq_base_ps_axi32.sv, etc).

.PHONY: help project compile c optimize o elaborate simulate s cos clean cln

help:
	@echo "Targets: project | compile (c) | optimize (o, aka elaborate) | simulate (s) | cos | clean (cln)"
	@echo "Vars: CTRL=0|1 (default 1) TEST=<name> (default cxl_ep_brdg_sanity)"
	@echo "      PCIE_LINK=PIPE|SERIAL (default PIPE)  DEFINES=<+define+...list>  PLUSARGS=<+arg...list>"
	@echo "      SEED=<n>|random  SIM_TIMEOUT=<n><unit>  GUI=0|1  PROJ_DIR=<path>"
	@echo "      SPEED=5|6 (default 6)  WIDTH=4|8 (default 8) - 'project' rebuild required after changing either"

project:
	vivado -mode batch -source $(dir $(lastword $(MAKEFILE_LIST)))build_project.tcl -tclargs $(PROJ_DIR) $(CTRL_NAME) $(CXL_PROTOCOL) X$(WIDTH)

$(DUT_SIM_DIR)/compile.sh:
	$(error DUT project not built yet - run 'make project' first (needs Vivado); expected $@)

# Files under sim/tb/ never `include`-d anywhere, so passed explicitly to
# vlogan (package/interface/bind-module defs with no includer). Order
# matches this design's own tb_files.f, though VCS resolves package
# deps regardless of order.
#  - seq_base_isr_src.sv deliberately NOT listed: already `include`-d inside
#    axi_mst_seq_pkg.svh.
#  - cseq_core_bd_ide_cfg_mb.sv deliberately NOT listed: not needed for
#    cxl_ep_brdg_sanity.
TB_ORPHAN_FILES := $(SIM_ROOT)/tb/env/seq/axi_mst/cxl_mbox/cxl_mbox_pkg.svh \
                    $(SIM_ROOT)/tb/env/pcie_cfg/pcie_cfg_pkg.svh \
                    $(SIM_ROOT)/tb/env/shim/shim_register_pkg.svh \
                    $(SIM_ROOT)/tb/env/shim/caps/shim_caps_pkg.svh \
                    $(SIM_ROOT)/tb/env/shim/ecaps/shim_ecaps_pkg.svh \
                    $(SIM_ROOT)/tb/env/shim/shim_enum_pkg.svh \
                    $(SIM_ROOT)/tb/env/shim/shim_device_pkg.svh \
                    $(SIM_ROOT)/tb/env/seq/axi_mst/axi_mst_seq_pkg.svh \
                    $(SIM_ROOT)/tb/env/shim/shim_pkg.svh \
                    $(SIM_ROOT)/tb/env/env_pkg.svh \
                    $(SIM_ROOT)/tb/test/other/socket_dpi_pkg.sv \
                    $(SIM_ROOT)/tb/test/test_pkg.svh \
                    $(SIM_ROOT)/tb/generic_pipe621_if.sv \
                    $(SIM_ROOT)/tb/bind.pipe_translate.sv \
                    $(SIM_ROOT)/tb/bind.fast_sim.sv

compile c: $(DUT_SIM_DIR)/compile.sh
	@echo "--- [1/2] Compiling DUT (Vivado-generated compile.sh) ---"
	cd $(DUT_SIM_DIR) && ./compile.sh
	@echo "--- [2/2] Compiling Avery VIP + CPM6 SecureIP + UVM agents + this testbench ---"
	# uvma_agents.f needs -F (rebases its nested per-agent filelists);
	# cpm6_sip.f/avery_vcs.f use $ENV_VAR-anchored paths, so -f is fine.
	# uvm_pkg.sv must be compiled explicitly before anything that imports it.
	vlogan -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps \
	  +define+PCIE_LINK_$(PCIE_LINK) \
	  $(CPM6_DEFINE) $(DEFINE_CTRL) $(AVERY_DEFINE) $(DEFINES) $(INCDIRS) \
	  +incdir+$(VCS_HOME)/etc/uvm-1.2/vcs +incdir+$(VCS_HOME)/etc/uvm-1.2/verdi \
	  $(VCS_HOME)/etc/uvm-1.2/uvm_pkg.sv \
	  $(VCS_HOME)/etc/uvm-1.2/vcs/uvm_custom_install_vcs_recorder.sv \
	  $(VCS_HOME)/etc/uvm-1.2/verdi/uvm_custom_install_verdi_recorder.sv \
	  -f $(SIM_ROOT)/cpm6_sip.f \
	  -f $(SIM_ROOT)/avery_vcs.f \
	  -F $(SIM_ROOT)/uvma_agents.f \
	  $(TB_ORPHAN_FILES) \
	  $(SIM_ROOT)/tb/tb_top.sv \
	  -l vlogan.tb.log
	@echo "--- [2b/2] Compiling xlnoc (NoC Packet Switch sim model) + its glue - see xlnoc_glue.v ---"
	vlogan -full64 -sverilog -timescale=1ns/1ps \
	  $(XLNOC_SIM_V) \
	  $(SIM_ROOT)/tb/xlnoc_glue.v \
	  -l vlogan.xlnoc.log

optimize o elaborate:
	# compile.sh vlogans the DUT into its own vcs_lib/ libraries (separate
	# from our "work" lib). Map every one of them in synopsys_sim.setup, not
	# just xil_defaultlib - some IP compiles into its own per-version
	# library (e.g. cpm6_v1_0_9), which would otherwise silently fall
	# through to the stale precompiled version in VIVADO_CLIBS's
	# OTHERS= chain (Error-[CFCIL-NS]).
	@if [ -z "$(VIVADO_CLIBS)" ]; then \
	  echo "ERROR: VIVADO_CLIBS is not set - see ../README.md"; \
	  exit 1; \
	fi
	@( echo "LIBRARY_SCAN=TRUE"; \
	   for d in $(DUT_SIM_DIR)/vcs_lib/*/; do \
	     lib=$$(basename $$d); \
	     echo "$$lib : $(DUT_SIM_DIR)/vcs_lib/$$lib"; \
	   done; \
	   echo "OTHERS=$(VIVADO_CLIBS)/synopsys_sim.setup" ) > synopsys_sim.setup
	# -top xil_defaultlib.glbl: UNISIM/XPM primitives reference `glbl` via
	# implicit upward hierarchical name; compile.sh compiles it but doesn't
	# add it as a co-top without this flag.
	# -P .../tb_vcs.tab + libtb_vcs64.a: Avery's encrypted sources call
	# Avery-specific PLI functions VCS has no builtin for.
	vcs -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps \
	  +vpi -P $(AVERY_PLI)/tb_vcs.tab $(AVERY_PLI)/lib.linux/libtb_vcs64.a \
	  $(LINK_GENERICS) -debug_access+all \
	  -top tb_top -top xlnoc_glue -top xil_defaultlib.glbl -o tb_top_opt \
	  -l vcs.elab.log

simulate s:
	# Vivado's simulate.sh runs from $(DUT_SIM_DIR), where several IP sim
	# models' $fopen-by-relative-path data files (nocattrs.dat, DDR PHY
	# *.vh) live. Our tb_top_opt runs from here instead, so symlink them in -
	# otherwise sim crashes via a bare $finish at time 0 (no UVM_ERROR/FATAL
	# raised), which would silently report RESULT = PASS below.
	@for f in $(DUT_SIM_DIR)/*.dat $(DUT_SIM_DIR)/*.vh; do \
	  [ -e "$$f" ] || continue; \
	  dst="./$$(basename "$$f")"; \
	  [ "$$(readlink -f "$$f")" = "$$(readlink -f "$$dst")" ] || ln -sf "$$f" . ; \
	done
	# *.mem (GT quad config): dut_config.sv hardcodes "../bd_*gt_quad_*.mem",
	# one directory above CWD - placed there, not flat-symlinked, to avoid
	# its own `cp -f` failing ("are the same file").
	@for f in $(DUT_SIM_DIR)/*gt_quad_*.mem; do \
	  [ -e "$$f" ] && ln -sf "$$f" .. ; \
	done
	# *.cdo (CPM6/PMCPS config): same one-level-up placement, for the same reason.
	@for f in $(DUT_SIM_DIR)/*.cdo; do \
	  [ -e "$$f" ] && ln -sf "$$f" .. ; \
	done
	# NOTE: a bare "$$finish called from" match is NOT treated as failure -
	# every passing run ends that way too. The real check is the missing
	# "--- UVM Report Summary ---", which only happens on an out-of-band kill.
	./tb_top_opt \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(UVM_VERBOSITY) \
	  $(CPM6_PARG) $(PARG) $(PLUSARGS) +SIM_TIMEOUT=$(SIM_TIMEOUT) \
	  $(if $(filter-out random,$(SEED)),+ntb_random_seed=$(SEED),+ntb_random_seed_automatic) \
	  $(if $(filter 1,$(GUI)),-gui,) \
	  -l $(TEST).sim.log ; \
	if grep -qE "UVM_ERROR *: *[1-9]|UVM_FATAL *: *[1-9]" $(TEST).sim.log || \
	   grep -qE "^Fatal:" $(TEST).sim.log || \
	   ! grep -q -- "--- UVM Report Summary ---" $(TEST).sim.log; then \
	  echo "RESULT = FAIL ($(TEST).sim.log)"; \
	else \
	  echo "RESULT = PASS ($(TEST).sim.log)"; \
	fi

cos: compile elaborate simulate

clean cln:
	rm -rf csrc simv* vc_hdrs.h *.log *.vpd DVEfiles ucli.key work AN.DB tb_top_opt*
