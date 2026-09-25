## =============================================================================
## Makefile - CPM6 QDMA Gen6 PIPE Simulation (CTRL1 EP)
## =============================================================================
## Usage:
##   make cos                                       -- compile + optimize + simulate
##   make cos DEBUG=1 DUMP=1 VERDI=1                -- with FSDB waveform dump (Verdi)
##   make cos DUMP=1                                -- with VPD waveform dump
##   make s   TEST=<test_name>                      -- re-simulate only
##   make clean                                     -- clean sim outputs
##   make aclean                                    -- clean everything (keep clibs)
##   make fullclean                                 -- factory reset
##   make distclean                                 -- wipe all compiled libs (uvm, avery, uvma_agents, cpm6_secip, Vivado vcs_lib), full rebuild
## =============================================================================

## ----------------------------------------------------------------------------
## TEST -- change to run a different test. This CED ships one test
## (sim/verif/test/test_qdma_h2c_c2h_mm_Mfnc_MQ.sv): PF-only, multi-queue,
## H2C+C2H MM DMA. See that file's plusarg list (NUM_PF_TEST/NUM_Q_TEST/PIDX/
## DMA_BYTE_CNT/IRQ_EN/DIRECTION/NUM_DMA_PORTS) to scale or narrow a run.
## ----------------------------------------------------------------------------
TEST  ?= test_qdma_h2c_c2h_mm_Mfnc_MQ
DUMP  ?= 1
VERDI ?= 1
## SEED -- reproduce an exact prior run. Defaults to a known-good seed (see
## below) rather than an automatic one, so repeat launches don't land on an
## untested random timing profile by default; override with SEED=<N> or
## SEED=automatic (via SEED_ARG below) to use VCS's own automatic seed, or
## SEED=<other N> to replay a different prior run's "NOTE: automatic random
## seed used: <N>" line from vcs.sim.log.
##
## 439119098: known-good seed for this config -- clears PCIe bus enumeration
## and SR-IOV VF discovery within the fixed wait_event(bus_enum_done, 500000 ns)
## timeout at NUM_VF_TEST=8. Bus-enum completion within that window is
## seed-sensitive at this VF count; an automatic seed may occasionally exceed
## the timeout in this identical config.
SEED  ?= 439119098
SEED_ARG := $(if $(SEED),+ntb_random_seed=$(SEED),+ntb_random_seed_automatic)
## PARG_EXTRA -- free-form additional plusargs appended after the fixed PARG
## list (see test_qdma_h2c_c2h_mm_Mfnc_MQ.sv for the full plusarg list this
## test honors). Default below is the 1PF+8VF/PIDX=7 config used for the
## WB-drain-fix validation arc -- override with PARG_EXTRA="..." for a
## different config.
PARG_EXTRA ?= +NUM_PF_TEST=1 +NUM_VF_TEST=8 +NUM_Q_TEST=1 +PIDX=7 +DMA_BYTE_CNT=512 +DIRECTION=BOTH
## DUMP_START_TIME -- delay FSDB dump start past CDO load (completes ~313-314us)
## so the waveform isn't dominated by the CDO-load phase, which isn't useful for
## post-CDO DMA/descriptor-path debug. Only applies to the DUMP=1 VERDI=1 (FSDB)
## path.
DUMP_START_TIME ?= 362us
## RUN_DURATION -- bounds the final `run` command in uclirun.do to a fixed,
## explicit amount of additional simulated time instead of an open-ended
## `run` (which only stops when something internal to the test/UVM calls
## $finish -- e.g. a completion watchdog -- so the actual wall-clock and
## simulated-time extent of an open-ended run is not controlled by the
## caller). Empty (default) keeps the open-ended `run`. Set to a time value
## with unit (e.g. RUN_DURATION=450us) to force a hard, known stop point
## for targeted debug capture, independent of whatever the test's own
## watchdog/completion logic does.
RUN_DURATION ?=
## ----------------------------------------------------------------------------
## DEBUG -- controls -kdb / -debug_access+all. Both cost real elaboration and
## runtime simulation speed (full debug visibility disables VCS's speed
## optimizations), so they're off by default. Set DEBUG=1 for interactive
## Verdi debug or FSDB waveform dumping (DUMP=1 VERDI=1 requires DEBUG=1).
## ----------------------------------------------------------------------------
DEBUG ?= 1
KDB_FLAG := $(if $(filter 1,$(DEBUG)),-kdb,)
DBG_FLAG := $(if $(filter 1,$(DEBUG)),-debug_access+all,)

ifeq ($(DUMP)$(VERDI),11)
  ifneq ($(DEBUG),1)
    $(error DUMP=1 VERDI=1 (FSDB waveform dump) requires DEBUG=1. Got DUMP=$(DUMP) VERDI=$(VERDI) DEBUG=$(DEBUG). Either set DEBUG=1 (FSDB+waveform, slower) or DUMP=1 without VERDI (VPD dump, no DEBUG needed))
  endif
endif

## ----------------------------------------------------------------------------
## Auto-detect Vivado project (works regardless of project name)
## ----------------------------------------------------------------------------
PROJ_ROOT  := $(shell find ../ -maxdepth 2 -name "*.xpr" -exec dirname {} \; 2>/dev/null | head -1)
# -path ".../simv.daidir" -prune excludes VCS's own internal debug-info path
# mirror (sim/simv.daidir/scsim.db.dir/cfg/<full absolute source path>/...),
# left behind by a prior compile/link in sim/. That mirror can itself end in
# ".../sim_1/behav/vcs", so without the prune a stale simv.daidir can outrank
# the real Vivado sim dir here and make _check_vivado report a false
# "compile.sh not found" against a path that was never the real target.
VIVADO_SIM := $(shell find $(PROJ_ROOT) -path "*/simv.daidir" -prune -o -path "*/sim_1/behav/vcs" -type d -print 2>/dev/null | head -1)
CLIBS      := $(abspath clibs)
SIM_SETUP  := $(abspath sim_setup.setup)

## ----------------------------------------------------------------------------
## Auto-detect link width and lane rate from defines file generated by CED
## ----------------------------------------------------------------------------
DEFINES_FILE := $(shell find $(PROJ_ROOT) -name "defines.sv" 2>/dev/null | head -1)
WIDTH        := $(shell grep -o "LINK_WIDTH = [0-9]*" "$(DEFINES_FILE)" 2>/dev/null | awk '{print $$3}')
WIDTH        ?= 4
LANE_RATE    := $(shell grep -o 'LANE_RATE.*"[^"]*"' "$(DEFINES_FILE)" 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')

ifeq ($(LANE_RATE),64.0_GT/s)
  CTRL_SPEED := 6
  # CTRL_FM selects flit SIZE, not whether flit mode is on (flit is mandatory
  # for Gen5/Gen6 regardless): 0=256B flit, 1=68B flit.
  CTRL_FM    := 0
else ifeq ($(LANE_RATE),32.0_GT/s)
  CTRL_SPEED := 5
  CTRL_FM    := 0
else
  CTRL_SPEED := 4
  CTRL_FM    := 0
endif

## ----------------------------------------------------------------------------
## Auto-detect PL0 clock from Vivado-generated file
## ----------------------------------------------------------------------------
PMCPS_V := $(shell find $(PROJ_ROOT) -name "*pmcps_0_0.v" 2>/dev/null | head -1)
ifneq ($(PMCPS_V),)
  PL0_CLK := $(shell grep -o "PL0_REF_CLK.*FREQ_HZ [0-9]*" "$(PMCPS_V)" 2>/dev/null | \
              awk '{print $$3}' | sed 's/[0-9]\{6\}$$/.\0/' | head -1)
# +PL0_CLK is consumed by tb/bind.ps_vip.sv as MHz (ps_vip_api.pl_gen_clock's
# freq_mhz arg), so the FREQ_HZ value must shift 6 digits (Hz->MHz), not 3
# (Hz->kHz). The 3-digit form previously here produced a value 1000x too
# high (e.g. 249997.498 "MHz" instead of 249.997498 MHz).
endif

## ----------------------------------------------------------------------------
## Compilation defines
## ----------------------------------------------------------------------------
# VF_OFFSET_OVERRIDE=4: this IP build's generated VFGX_FIRST_VF_OFFSET is 4
# (see qdma_ced_test.gen/.../msix_params.vh), not NUM_PFS. Without this,
# cpm6_qdma_params_pkg.sv's VF_OFFSET defaults to NUM_PFS and any VF-aware
# test resolves fnc->pfn/vfn against the wrong function numbers.
CDEF := +define+CPM6_VIVADO         \
        +define+PCIE_LINK_PIPE       \
        +define+CPM6_DECRYPTED_SIP   \
        +define+APCI_MAX_DATA_WIDTH=8 \
        +define+VCS_SIM               \
        +define+VF_OFFSET_OVERRIDE=4

## ----------------------------------------------------------------------------
## Simulation plusargs
## ----------------------------------------------------------------------------
# NOTE: this is a CTRL1-only CED (see ../../init.tcl) -- CTRLR0 stays
# disabled and LINK0_WIDTH=0 in the opt step below. Inherited backwards
# (CTRLR0 enabled, CTRLR1 disabled) from the ctrl0 Makefile this was ported
# from; fixed 2026-08-11 alongside sim/verif/dut_inst.sv, which guards on
# tb_top.LINK1_WIDTH != 0 and would never instantiate the DUT with the old values.
PARG  := +CTRLR0_EN=0
PARG  += +CTRLR1_EN=1
PARG  += +CTRLR0_SPEED=$(CTRL_SPEED)
PARG  += +CTRLR0_FM=$(CTRL_FM)
PARG  += +CTRLR1_SPEED=$(CTRL_SPEED)
PARG  += +CTRLR1_FM=$(CTRL_FM)
PARG  += +CDO_TIMEOUT=400us
PARG  += +SIM_TIMEOUT=5000us
PARG  += +CPM6_VIVADO
PARG  += +PCIE_LINK_PIPE
ifneq ($(PL0_CLK),)
  PARG += +PL0_CLK=$(PL0_CLK)
endif

## ----------------------------------------------------------------------------
## C shared libraries -- relative from sim/ODIR/ where simv runs
## ----------------------------------------------------------------------------
SIM_SO := -sv_lib ../lib/date -sv_lib ../lib/socket_dpi

## =============================================================================
## TARGETS
## =============================================================================

.PHONY: h help cos c compile o opt s sim smoke clean cln aclean acln fullclean distclean

h help:
	@echo "======================================================="
	@echo " CPM6 QDMA Gen6 PIPE Simulation (CTRL1 EP)"
	@echo "======================================================="
	@echo ""
	@echo " Prerequisites:"
	@echo "   1. Load VCS module       : module switch vcs/X-2025.06-SP2"
	@echo "   2. Load Avery module     : module load averyvip/2025.3_1"
	@echo "                              (sets AVERY_PLI, AVERY_PCIE, AVERY_SIM)"
	@echo "   3. Set CPM6 Secure IP   : setenv CPM6_SECUREIP <path>"
	@echo "                              (download separately, see README)"
	@echo "   4. Create project from CED in Vivado"
	@echo "   5. Set Compiled Libraries Dir in Vivado (2026.1 clibs)"
	@echo "   6. Run launch_simulation -scripts_only in Vivado"
	@echo ""
	@echo " Targets:"
	@echo "   make cos      - Compile + Optimize + Simulate"
	@echo "   make c        - Compile only"
	@echo "   make o        - Optimize only"
	@echo "   make s        - Simulate only"
	@echo "   make smoke    - Run the smoke test (test_qdma_h2c_c2h_mm_Mfnc_MQ) only"
	@echo "   make clean    - Clean simulation outputs"
	@echo "   make aclean   - Clean (keeps pre-compiled clibs)"
	@echo "   make fullclean- Factory reset"
	@echo ""
	@echo " Options:"
	@echo "   TEST=<name>  Test name (default: $(TEST))"
	@echo "   DUMP=<0|1>   Waveform dump: 0=off, 1=on (default: $(DUMP))"
	@echo "   VERDI=<0|1>  Simulator: 0=batch VCS, 1=interactive Verdi GUI (default: $(VERDI))"
	@echo "                (DUMP=1 VERDI=1 -> FSDB dump to waves.fsdb (requires DEBUG=1),"
	@echo "                 DUMP=1 VERDI=0 -> VPD dump to inter.vpd)"
	@echo "   DEBUG=<0|1>  -kdb / -debug_access+all: 0=off (faster, default), 1=on (default: $(DEBUG))"
	@echo "   SEED=<N>     Reproduce an exact prior run's seed (default: automatic, see SEED comment)"
	@echo "   PARG_EXTRA=<plusargs>  Additional plusargs appended after the fixed PARG list"
	@echo "                (e.g. \"+NUM_PF_TEST=1 +NUM_Q_TEST=1 +PIDX=50 +DMA_BYTE_CNT=4096 +DIRECTION=BOTH\")"
	@echo "   DUMP_START_TIME=<time>  Delay FSDB dump start past CDO load (default: $(DUMP_START_TIME))"
	@echo ""
	@echo " Auto-detected:"
	@echo "   Project    : $(PROJ_ROOT)"
	@echo "   Width      : $(WIDTH)"
	@echo "   Lane Rate  : $(LANE_RATE)"
	@echo "   Speed      : $(CTRL_SPEED)"
	@echo "   Flit Mode  : $(CTRL_FM)"
	@echo "   PL0_CLK    : $(PL0_CLK)"

cos: c o s

## ---------------------------------------------------------------------------
## COMPILE
## ---------------------------------------------------------------------------
c compile: _check_env _check_vivado
	@echo ""
	@echo "=== COMPILE STEP 1/3: UVM + uvma_agents Libraries ==="
	@if [ ! -d $(CLIBS)/uvm ]; then \
	    mkdir -p $(CLIBS)/uvm; \
	    SYNOPSYS_SIM_SETUP=$(abspath vcs_lib_map.setup) \
	    vlogan -full64 -sverilog -work uvm -ntb_opts uvm-1.1 \
	           -timescale=1ps/1ps $(KDB_FLAG) \
	           +define+UVM_DISABLE_AUTO_ITEM_RECORDING \
	           -l $(CLIBS)/vlogan.uvm.log; \
	    echo "    UVM compiled"; \
	else \
	    echo "    UVM already compiled -- skipping"; \
	fi
	@if [ ! -d $(CLIBS)/uvma_agents ]; then \
	    mkdir -p $(CLIBS)/uvma_agents; \
	    SYNOPSYS_SIM_SETUP=$(abspath vcs_lib_map.setup) \
	    vlogan -full64 -sverilog -work uvma_agents -ntb_opts uvm-1.1 \
	           -timescale=1ns/1ps $(KDB_FLAG) \
	           +define+TIME_BASE_PKG \
	           +define+TIMEUNIT_BASE_PKG=1ps \
	           +define+TIMEPREC_BASE_PKG=1ps \
	           -l $(CLIBS)/vlogan.uvma_agents.log \
	           -F uvma_agents.f; \
	    echo "    uvma_agents compiled"; \
	else \
	    echo "    uvma_agents already compiled -- skipping"; \
	fi
	@if [ ! -d $(CLIBS)/avery ]; then \
	    mkdir -p $(CLIBS)/avery; \
	    SYNOPSYS_SIM_SETUP=$(abspath vcs_lib_map.setup) \
	    vlogan -full64 -sverilog -work avery -ntb_opts uvm-1.1 $(KDB_FLAG) \
	           +define+APCI_MAX_DATA_WIDTH=8 \
	           -l $(CLIBS)/vlogan.avery.log \
	           -f avery_vcs.f; \
	    echo "    avery compiled"; \
	else \
	    echo "    avery already compiled -- skipping"; \
	fi
	@echo ""
	@echo "=== COMPILE STEP 2/3: Vivado DUT ==="
	@if [ ! -f $(VIVADO_SIM)/vcs_lib/xil_defaultlib/work.lib++ ]; then \
	    echo "    Running Vivado compile.sh ..."; \
	    cd $(VIVADO_SIM) && bash compile.sh; \
	    echo "    Vivado DUT compiled"; \
	else \
	    echo "    Vivado DUT already compiled -- skipping"; \
	fi
	@echo "    Generating VCS library setup ..."
	@$(MAKE) --no-print-directory _gen_sim_setup
	@if [ ! -d $(CLIBS)/cpm6_secip ]; then \
	    mkdir -p $(CLIBS)/cpm6_secip; \
	    SYNOPSYS_SIM_SETUP=$(SIM_SETUP) \
	    vlogan -full64 -sverilog -work cpm6_secip \
	           -timescale=1ns/1ps $(KDB_FLAG) \
	           -l $(CLIBS)/vlogan.cpm6_secip.log \
	           -F cpm6_sip.f; \
	    echo "    cpm6_secip compiled"; \
	else \
	    echo "    cpm6_secip already compiled -- skipping"; \
	fi
	@echo ""
	@echo "=== COMPILE STEP 3/3: Top-level Testbench ==="
	# to-do item for future consideration: the explicit ordering below
	# (pcie_str_pkg.sv / pcie_intf_pkg.sv / bmd_mem_pkg.sv) is carried over
	# from BMD's package compile-order dependencies. None of these three
	# files exist in a QDMA design; keep this ordering hook only if QDMA's
	# own top-level src/ (once authored) has an analogous ordering-sensitive
	# package, updating the filenames accordingly -- otherwise this can
	# collapse to the single glob below.
	$(eval PROJ_PKGS := \
	    $(shell find $(PROJ_ROOT) -path "*/imports/src/*_pkg.sv" 2>/dev/null | sort))
	SYNOPSYS_SIM_SETUP=$(SIM_SETUP) \
	vlogan -full64 -sverilog -work work -ntb_opts uvm-1.1 \
	       -timescale=1ns/1ps $(KDB_FLAG) +warn=noCVMBI \
	       $(CDEF) \
	       -l vcs.vlogan.log \
	       $(PROJ_PKGS) \
	       -f tb_files.f
	@echo "    Testbench compiled"

## ---------------------------------------------------------------------------
_gen_sim_setup:
	@echo "LIBRARY_SCAN=TRUE"                              >  sim_setup.setup
	@echo "work        : $(abspath workvcs)"               >> sim_setup.setup
	@echo "uvm         : $(CLIBS)/uvm"                     >> sim_setup.setup
	@echo "avery       : $(CLIBS)/avery"       >> sim_setup.setup
	@echo "uvma_agents : $(CLIBS)/uvma_agents" >> sim_setup.setup
	@echo "cpm6_secip  : $(CLIBS)/cpm6_secip"  >> sim_setup.setup
	@for lib in $(VIVADO_SIM)/vcs_lib/*/; do \
	    libname=$$(basename $$lib); \
	    echo "$$libname : $$(realpath $$lib)"              >> sim_setup.setup; \
	done
	@VIVADO_OTHERS=$$(grep "^OTHERS=" $(VIVADO_SIM)/synopsys_sim.setup 2>/dev/null | \
	                  sed 's/OTHERS=//' | head -1); \
	 if [ -n "$$VIVADO_OTHERS" ]; then \
	    echo "OTHERS=$$VIVADO_OTHERS"                      >> sim_setup.setup; \
	 fi
	@echo "    sim_setup.setup generated"

## ---------------------------------------------------------------------------
## OPTIMIZE
## ---------------------------------------------------------------------------
# Do not add $(KDB_FLAG) (-kdb) to this link/elaboration step. -kdb requires
# every linked library -- including the central SWIP-shipped Xilinx/VHDL
# precompiled libraries this project's OTHERS= chain resolves against (e.g.
# VCOMPONENTS) -- to also be -kdb-compiled; they are not, and -kdb here
# fails elaboration with Error-[ANA-KDB-ICS] Incompatible VHDL database
# Found ('VCOMPONENTS' design unit isn't generated with -kdb). $(DBG_FLAG)
# (-debug_access+all) alone is the correct flag for FSDB waveform dumping;
# -kdb is only needed for interactive GUI-mode Verdi debug.
o opt: _check_env _check_setup
	@echo ""
	@echo "=== OPTIMIZE STEP 2/3: Linking ==="
	SYNOPSYS_SIM_SETUP=$(SIM_SETUP) \
	vcs -j4 -full64 +nospecify -xlrm uniq_prior_final -ntb_opts uvm-1.1 \
	    -l vcs.opt.log \
	    work.tb_top xil_defaultlib.glbl \
	    +warn=noCNST-PPRW,noRT-NCMUCS,noUNGB \
	    $(DBG_FLAG) \
	    $(AVERY_PLI)/lib.linux/libtb_vcs64.a \
	    -P $(AVERY_PLI)/tb_vcs64.tab +vpi \
	    +warn=noUII-L -reportstats \
	    -pvalue tb_top.LINK0_WIDTH=0 \
	    -pvalue tb_top.LINK1_WIDTH=$(WIDTH)
	@echo "    Optimization complete -- simv created"

## ---------------------------------------------------------------------------
## SIMULATE
## ---------------------------------------------------------------------------
s sim: _check_env _check_simv _check_setup
	@echo ""
	@echo "=== SIMULATE STEP 3/3: Running $(TEST) ==="
	@echo "    Width   : $(WIDTH)"
	@echo "    PL0_CLK : $(PL0_CLK)"
	@echo "    DUMP    : $(DUMP)"
	@echo "    VERDI   : $(VERDI)"
	@cp $(VIVADO_SIM)/*.cdo . 2>/dev/null || true
	@cp $(VIVADO_SIM)/*.mem . 2>/dev/null || true
	@for f in bd_*_cpm6_0_0_sim_text.cdo; do [ -e "$$f" ] && ln -sf "$$f" cpm6_qdma_sim_text.cdo && break; done 2>/dev/null || true
	@rm -f uclirun.do
	@if [ "$(DUMP)" = "1" ]; then \
	    if [ "$(VERDI)" = "1" ]; then \
	        echo '# Delay dump start past CDO load -- see DUMP_START_TIME (Makefile).' >> uclirun.do; \
	        echo 'run $(DUMP_START_TIME)' >> uclirun.do; \
	        echo 'fsdbDumpfile "waves.fsdb"' >> uclirun.do; \
	        echo '# depth 0 dumps ONLY tb_top''s own signals, nothing beneath it -- this must' >> uclirun.do; \
	        echo '# reach real hierarchy. Depth 9 reaches CPM_INST (the CPM6 hard-IP instance,' >> uclirun.do; \
	        echo '# tb_top.ctrl_inst.dut_inst.ctrl1_qdma_ep_i.ctrl1_ep_i.ps_wizard_0.inst.cpm6_0.inst.CPM_INST)' >> uclirun.do; \
	        echo '# as an opaque boundary (its own ports, not its internals) -- CPM6 is a huge' >> uclirun.do; \
	        echo '# SECUREIP block and a full recursive dump into it is impractically large/slow.' >> uclirun.do; \
	        echo 'fsdbDumpvars 9 tb_top +all +mda +packedmda +struct' >> uclirun.do; \
	        echo '# CPM6 hard-IP CDO-load scope only (SIP_CPM6_INST.i_cpm_sim_cfg_wrap.u_cpm_sim_cfg,' >> uclirun.do; \
	        echo '# see sim/tb/bind.cdo_load.sv) -- requires decrypted CPM6.v/cpm6_00{1,2}.sv' >> uclirun.do; \
	        echo '# (cpm6_sip.f pointing at .sv, not .svp) or this scope will not resolve.' >> uclirun.do; \
	        echo 'fsdbDumpvars +all tb_top.ctrl_inst.dut_inst.ctrl1_qdma_ep_i.ctrl1_ep_i.ps_wizard_0.inst.cpm6_0.inst.CPM_INST.SIP_CPM6_INST.i_cpm_sim_cfg_wrap.u_cpm_sim_cfg +mda +packedmda +struct' >> uclirun.do; \
	        echo '# cpm6_qdma_0 is a SIBLING BD cell of ps_wizard_0 (not nested under it) --' >> uclirun.do; \
	        echo '# depth 9 from tb_top only reaches cpm6_qdma_0/inst, one level above any' >> uclirun.do; \
	        echo '# real QDMA IP RTL (scheduler/dsc_fetch/channel_manager/credit counters).' >> uclirun.do; \
	        echo '# Full depth here is required for any QDMA-internal debug (2026-09-03,' >> uclirun.do; \
	        echo '# C2H completion-stall RCA -- depth-9-only waveform had none of this.' >> uclirun.do; \
	        echo '# fsdbDumpvars syntax is [depth] [instance] [options] -- depth must be a' >> uclirun.do; \
	        echo '# number, not "+all" (that silently parses as depth 0 / no descendants,' >> uclirun.do; \
	        echo '# the exact mistake this line originally copied from the CDO-load scope' >> uclirun.do; \
	        echo '# line below -- confirmed via vcs.sim.log: "Begin traversing ... layer (0)"' >> uclirun.do; \
	        echo '# with zero children in the resulting FSDB scope tree, no Verdi error).' >> uclirun.do; \
	        echo 'fsdbDumpvars 999 tb_top.ctrl_inst.dut_inst.ctrl1_qdma_ep_i.ctrl1_ep_i.cpm6_qdma_0.inst +all +mda +packedmda +struct' >> uclirun.do; \
	    else \
	        echo 'dump -file inter.vpd -type VPD' >> uclirun.do; \
	        echo 'dump -add tb_top -depth 0' >> uclirun.do; \
	    fi; \
	fi
	@echo "run $(RUN_DURATION)" >> uclirun.do
	@echo "quit" >> uclirun.do
	@ODIR=$(TEST)_$$(date +"%m%d%y_%Hh%Mm%Ss"); \
	 mkdir -p $$ODIR; \
	 cp $(VIVADO_SIM)/*.dat $$ODIR/ 2>/dev/null || true; \
	 export SYNOPSYS_SIM_SETUP=$(SIM_SETUP); \
	 cd $$ODIR && ../simv \
	    -no_save \
	    -l vcs.sim.log \
	    -reportstats \
	    -licqueue -licwait 1 \
	    $(SEED_ARG) \
	    $(SIM_SO) \
	    +UVM_TESTNAME=$(TEST) \
	    +UVM_VERBOSITY=UVM_MEDIUM \
	    -ucli -do ../uclirun.do \
	    $(PARG) $(PARG_EXTRA); \
	 echo ""; \
	 echo "//-------------------------------------------//"; \
	 echo "// TEST : $(TEST)"; \
	 grep -E "UVM_ERROR|UVM_FATAL|\[TEST_DONE\]" vcs.sim.log | tail -5; \
	 echo "// LOG  : sim/$$ODIR/vcs.sim.log"; \
	 echo "//-------------------------------------------//"

## ---------------------------------------------------------------------------
## SMOKE
## ---------------------------------------------------------------------------
smoke:
	@$(MAKE) --no-print-directory s TEST=test_qdma_h2c_c2h_mm_Mfnc_MQ

## ---------------------------------------------------------------------------
## CLEAN
## ---------------------------------------------------------------------------
clean cln:
	@rm -f *.log *.cdo *.mem uclirun.do ucli.key simv vc_hdrs.h novas* waves.fsdb inter.vpd
	@rm -rf csrc simv.daidir workvcs verdi_config_file
	@echo "Cleaned simulation outputs"

aclean acln: clean
	@rm -rf sim_setup.setup clibs/uvm
	@echo "Full clean done (pre-compiled clibs preserved)"

fullclean:
	@echo "======================================================="
	@echo " FULL CLEAN -- resets to factory state"
	@echo " Pre-compiled clibs preserved"
	@echo "======================================================="
	@rm -rf workvcs sim_setup.setup clibs/uvm
	@rm -rf simv simv.daidir simv.vdb csrc verdiLog
	@rm -f *.log *.cdo *.mem uclirun.do ucli.key vc_hdrs.h novas* waves.fsdb inter.vpd
	@find . -maxdepth 1 -type d -name "test_*" -exec rm -rf {} + 2>/dev/null || true
	@echo "Full clean complete"

distclean: fullclean
	@echo "======================================================="
	@echo " DIST CLEAN -- removes ALL generated/compiled libraries"
	@echo " (uvm, avery, uvma_agents, cpm6_secip, Vivado vcs_lib)"
	@echo " Next 'make cos' will recompile everything from scratch"
	@echo "======================================================="
	@rm -rf clibs work.lib++
	@if [ -n "$(VIVADO_SIM)" ]; then \
	    rm -rf $(VIVADO_SIM)/vcs_lib; \
	    mkdir -p $(VIVADO_SIM)/vcs_lib; \
	    rm -f $(VIVADO_SIM)/*.log $(VIVADO_SIM)/.tmp_log; \
	fi
	@echo "Dist clean complete"

## ---------------------------------------------------------------------------
## Internal checks
## ---------------------------------------------------------------------------
_check_env:
	@if [ -z "$(AVERY_PLI)" ]; then \
	    echo ""; echo "ERROR: AVERY_PLI not set. Load Avery module (averyvip/2025.3_1)."; echo ""; exit 1; fi
	@if [ -z "$(AVERY_PCIE)" ]; then \
	    echo ""; echo "ERROR: AVERY_PCIE not set. Load Avery module (averyvip/2025.3_1)."; echo ""; exit 1; fi
	@if [ -z "$(AVERY_SIM)" ]; then \
	    echo ""; echo "ERROR: AVERY_SIM not set. Load Avery module (averyvip/2025.3_1)."; echo ""; exit 1; fi
	@if [ -z "$(VCS_HOME)" ]; then \
	    echo ""; echo "ERROR: VCS_HOME not set. Load VCS module."; echo ""; exit 1; fi
	@if [ -z "$(CPM6_SECUREIP)" ]; then \
	    echo ""; echo "ERROR: CPM6_SECUREIP not set."; \
	    echo "       Download CPM6 Secure IP and set: setenv CPM6_SECUREIP <path>"; echo ""; exit 1; fi
	@if [ -z "$(VIVADO_SIM)" ]; then \
	    echo ""; echo "ERROR: Vivado project not found in ../"; \
	    echo "       Create project from CED in Vivado first."; echo ""; exit 1; fi

_check_vivado:
	@if [ ! -f "$(VIVADO_SIM)/compile.sh" ]; then \
	    echo ""; echo "ERROR: compile.sh not found."; \
	    echo "       Run launch_simulation -scripts_only in Vivado first."; echo ""; exit 1; fi

_check_simv:
	@if [ ! -f "simv" ]; then \
	    echo ""; echo "ERROR: simv not found. Run 'make c o' first."; echo ""; exit 1; fi

_check_setup:
	@if [ ! -f "sim_setup.setup" ]; then \
	    echo ""; echo "ERROR: sim_setup.setup not found. Run 'make c' first."; echo ""; exit 1; fi
