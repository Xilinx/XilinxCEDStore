# Hardcode this variable so it can't be set from command line
override MAKEFILE_INTERNAL = 0

# Control detailed test printing for specific target
ifdef TEST
 PRINT_DESC := 1
endif

# User may choose to replace PS VIP with QEMU
# via this variable
QEMU_PS ?= 0

# Choose whether to parse Vivado's compile.sh into many 
# libraries or just a single one 
DUT_CLIBS_ALLOWED := ONE MANY
ifndef DUT_CLIBS
 ifdef DEFAULT_DUT_CLIBS
  DUT_CLIBS := $(DEFAULT_DUT_CLIBS)
 else
  DUT_CLIBS := ONE
 endif
endif
BAD_DUT_CLIBS := $(if $(filter $(DUT_CLIBS),$(DUT_CLIBS_ALLOWED)),0,1)

# Default location relative to this directory
# Vivado sims will redefine to whatever necessary
FW_ROOT ?= ../..

TEST_DIR := $(FW_ROOT)/cpm6/common/test
ifndef TEST
 ifdef DEFAULT_TEST
  TEST := $(DEFAULT_TEST)
 else
  TEST := hello_world
 endif
endif

# Whitelist of common/framework tests (from TEST_DIR and its ext*test dirs)
# shown by "lst" with no TEST given. Each word is matched as an anchored
# Perl-compatible regex (grep -P "^pattern$") against candidate test
# basenames, so e.g. "test_.*" or "base_cxl.*" matches multiple tests at
# once. The special value ALL (or all) disables filtering entirely and
# restores the old "print every test" behavior. Project-specific tests
# under ./verif/test are always shown regardless of this list. Wrapper
# Makefiles can override this by setting TEST_WHITELIST before including
# this file.
TEST_WHITELIST ?= hello_world

# Blacklist of project-specific tests (from TESTCASE_TEST_DIR) hidden from
# the "lst" listing, e.g. base tests that should never be run by themselves.
# Each word is matched as an anchored Perl-compatible regex against the test
# basename, same as TEST_WHITELIST. It only affects test printing; it does
# not prevent a blacklisted test from being run, and it does not apply to
# framework tests (see TEST_WHITELIST).
TEST_BLACKLIST ?=

# Validate and set PCIE_LINK
PCIE_LINK_ALLOWED := PIPE SERIAL
ifndef PCIE_LINK
 ifdef DEFAULT_PCIE_LINK
  PCIE_LINK := $(DEFAULT_PCIE_LINK)
 else
  PCIE_LINK := PIPE
 endif
endif
BAD_PCIE_LINK := $(if $(filter $(PCIE_LINK),$(PCIE_LINK_ALLOWED)),0,1)

# Validate and set CPM6_SRC
# Note: VIVADO uses the Vivado clibs for the CPM6 model (plus the SecureIP clib
# when SIM=questa); VIVADO_SECIP is a Vivado project that also adds the
# DECRYPTED CPM6 SecureIP library for any simulator (for debug)
CPM6_SRC_ALLOWED := VIVADO VIVADO_SECIP
ifndef CPM6_SRC
 ifdef DEFAULT_CPM6_SRC
  CPM6_SRC := $(DEFAULT_CPM6_SRC)
 else
  CPM6_SRC := VIVADO
 endif
endif
BAD_CPM6_SRC := $(if $(filter $(CPM6_SRC),$(CPM6_SRC_ALLOWED)),0,1)

# Set variable to use later to compile decrypted SecureIP
DECRYPTED_SIP := $(if $(findstring SECIP,$(CPM6_SRC)),1,0)

# Validate and set verbosity
VERBOSITY_ALLOWED := NONE LOW MEDIUM HIGH DEBUG
VERBOSITY ?= MEDIUM
BAD_VERBOSITY := $(if $(filter $(VERBOSITY),$(VERBOSITY_ALLOWED)),0,1)

# Validate and set GUI options for sim run
GUI_ALLOWED := -1 0 1 2 3
GUI ?= 0
BAD_GUI := $(if $(filter $(GUI),$(GUI_ALLOWED)),0,1)

# Validate and set debug visibility (defualt: on)
DEBUG_ALLOWED := 0 1
ifndef DEBUG
 ifdef DEFAULT_DEBUG
  DEBUG := $(DEFAULT_DEBUG)
 else
  DEBUG := 1
 endif
endif
BAD_DEBUG := $(if $(filter $(DEBUG),$(DEBUG_ALLOWED)),0,1)

# Helpful variable definitions to hack Makefiles
empty=
spc=$(empty) $(empty)
comma=,
plus=+
dot=.
slash=/

# The list of local C files to compile and link for DPI
ifeq (VIVADO,$(findstring VIVADO,$(CPM6_SRC)))
 C_FILES := $(shell find $(FW_SIM_DIR)/c -type f -name "*.c" 2> /dev/null)
 SIM_SO_LIBS := $(foreach so,$(patsubst %.c,%,$(C_FILES)),-sv_lib$(spc)$(so))
else
 C_FILES := $(shell find ./c -type f -name "*.c" 2> /dev/null)
 SIM_SO_LIBS := $(foreach so,$(patsubst %.c,%,$(C_FILES)),-sv_lib$(spc)$(dot)$(so))
endif
SO_FILES := $(patsubst %.c,%.so,$(C_FILES))

# Suppress these errors
#  - QUESTA
VLOG_SUPPRESS += -suppress vlog-2961
VOPT_SUPPRESS += -suppress vopt-12003
VOPT_SUPPRESS += -suppress vopt-7061
VOPT_SUPPRESS += -suppress vopt-7033
VOPT_SUPPRESS += -suppress vopt-10017
VSIM_SUPPRESS += -suppress vsim-7033
VSIM_SUPPRESS += -suppress vsim-3839

# Validate and set SIM
SIM_ALLOWED := questa vcs
ifndef SIM
 ifdef DEFAULT_SIM
  SIM := $(DEFAULT_SIM)
 else
  SIM := questa
 endif
else
 SIM_ARG := 1
endif
BAD_SIM := $(if $(filter $(SIM),$(SIM_ALLOWED)),0,1)

# The cpm6_secip clib is needed when decrypted SecureIP is the DUT, and also
# for any Vivado-based Questa sim, which still relies on the SecureIP library
USE_SIP_CLIB := $(if $(or $(filter 1,$(DECRYPTED_SIP)),$(and $(findstring VIVADO,$(CPM6_SRC)),$(filter questa,$(SIM)))),1,0)

# Control clibs path
CLIBS_PATH := $(if $(findstring VIVADO,$(CPM6_SRC)),$(PROJ_SIM_DIR)/clibs,clibs/$(SIM))
# Define work dir
SIM_WORK_DIR := $(if $(findstring VIVADO,$(CPM6_SRC)),$(PROJ_SIM_DIR),.)

# Questa ini resolution: exactly one ini file may exist; it is the active one.
# Only validated by targets that depend on chk_questa_ini.
QUESTA_INI_NAMES := modelsim.ini questasim.ini questa.ini
QUESTA_INI_FOUND := $(wildcard $(addprefix $(SIM_WORK_DIR)/,$(QUESTA_INI_NAMES)))
QUESTA_INI       := $(abspath $(QUESTA_INI_FOUND))
QUESTA_INI_ARG   := -ini $(QUESTA_INI)

# Default action is submit jobs to LSF. A user can specify LSF as an argument or
# they can set the LSF submission with the DEFAULT_LSF environment variable
ifndef LSF
 ifdef DEFAULT_LSF
  LSF = $(DEFAULT_LSF)
 else
  LSF = 0
 endif
endif

# Depending on simulator, it may be required to link the libraries to the
# commands for compilation, optimization, etc.
VIP_LIBS := uvm avery uvma_agents
VIP_LIBS += $(if $(findstring VIVADO,$(CPM6_SRC)),$(mpty),svt_axi)
SIP_LIBS := cpm6_secip
VIV_LIBS := vivado_dut

DUT_LIBS := $(if $(filter 1,$(USE_SIP_CLIB)),$(SIP_LIBS),) $(if $(filter $(DUT_CLIBS),ONE),$(VIV_LIBS),)
ifeq ($(SIM),questa)
 VIV_CCLIBS := $(shell grep -ohE '\-L [[:alnum:]_]+' $(SIM_WORK_DIR)/*_compile.do 2>/dev/null | sed 's/-L //' | awk '!seen[$$0]++' | tr '\n' ' ')
 VIV_ECLIBS := $(shell grep -ohE '\-L [[:alnum:]_]+' $(SIM_WORK_DIR)/*_elaborate.do 2>/dev/null | sed 's/-L //' | awk '!seen[$$0]++' | tr '\n' ' ')
 ifeq ($(DUT_CLIBS),ONE)
  VIV_ECLIBS := $(filter-out xil_defaultlib,$(VIV_ECLIBS))
 endif
endif
VIP_LIBS_CMD := $(foreach lib,$(VIP_LIBS),-L $(lib))
DUT_LIBS_CMD := $(foreach lib,$(DUT_LIBS) $(VIV_ECLIBS),-L $(lib))

# Default LSF Options
# - Can also try different "span" options i.e. span[hosts=1,block=value,ptile=value]
# - Memory requested
ifeq ($(SIM),questa)
 OPT_MEM_REQ ?= 16
 SIM_MEM_REQ ?= 8
else ifeq ($(SIM),vcs)
 OPT_MEM_REQ ?= 24
 SIM_MEM_REQ ?= $(if $(filter-out 0,$(GUI)),16,8)
endif

# VCS partition compile for the opt step. The first build saves PC_DB; later
# builds reuse it and write only the changed partitions to PC_NEW.
# Both live in SIM_WORK_DIR, next to simv/csrc. Remove them with cln_pc.
PC_JOBS   ?= 8
PC_DB     := pc_db
PC_NEW    := pc_new
PC_BUSY   := .pc_busy
PC_FILES  := $(PC_DB) $(PC_NEW) $(PC_BUSY)
OPT_CORES ?= $(if $(filter vcs,$(SIM)),$(PC_JOBS),1)

# LSF queue for simulation jobs
# Priority: Make override > Environment variable > Default
ifndef LSF_SIM_QUEUE
 ifdef DEFAULT_LSF_SIM_QUEUE
  LSF_SIM_QUEUE = $(DEFAULT_LSF_SIM_QUEUE)
 else
  LSF_SIM_QUEUE = medium
 endif
endif

ifndef REGR_TIMEOUT
 REGR_TIMEOUT := 3600
endif

# A Vivado project VCS sim (using Verdi) needs clibs compiled with -kdb
# Simulating with VCS with DEBUG=1 will try to swap this path into the
# OTHERS line so you can run simulations with OR without visibility
CLIBS_DEBUG_ROOT=/your/path/inserted/here
# By default, get latest SecIP
SIP_PATH ?= /your/path/inserted/here
SIP_FILELIST ?= filelist.f
# Assign version print path for `include file for decrypted CPM6 SecureIP
ifeq (SECIP,$(findstring SECIP,$(CPM6_SRC)))
 VERSION_PRINT_PATH = $(SIP_PATH)
endif

# Give a UVM source code location
UVM_HOME_questa = $(QUESTA_HOME)/verilog_src/uvm-1.1d/src
UVM_HOME_vcs = $(VCS_HOME)/etc/uvm-1.1

# It is assumed that a user calling this Makefile directly 
# is using a specific type of TB: one with only DUT and UVM agents
ifeq ($(lastword $(MAKEFILE_LIST)),Makefile)
 CDEF += +define+CPM6_DUT_AGENTS_ONLY
endif
ifeq ($(DECRYPTED_SIP),1)
 CDEF += +define+CPM6_DECRYPTED_SIP
endif
# Avery requires this define to support N-bytes of PIPE data width
# default is [1,2,4] byte interface, Gen6 requires 8 or 16 bytes
CDEF += +define+APCI_MAX_DATA_WIDTH=8
CDEF += +define+CPM6_$(CPM6_SRC:_SECIP=) +define+PCIE_LINK_$(PCIE_LINK)
ifeq ($(QEMU_PS),1)
 CDEF += +define+QEMU_PS
endif
# Comma separated list of addl. compilation defines
ifdef DEFINES
 CDEF := $(CDEF) +define+
 CDEF := $(strip $(CDEF)$(subst $(comma),$(spc)+define+,$(DEFINES)))
endif

# Grab testcase specified incdir paths
ifdef TESTCASE_INCDIR
 PRE_INCDIR := +incdir+$(subst $(comma),$(spc)+incdir+,$(TESTCASE_INCDIR))
endif

# Grab the PL[0:3] clock frequencies that have been specified in PS Wizard
# so we can pass them in as plusargs, scaled to MHZ as a real
ifneq ($(filter s cos sim sregr regr,$(MAKECMDGOALS)),)
 ifeq (VIVADO,$(findstring VIVADO,$(CPM6_SRC)))
  ifneq ($(filter %pmcps_0_0.v,$(DUT_SV)),)
   PL0_CLK ?= $(shell (grep -o "PL0_REF_CLK.*FREQ_HZ [[:digit:]]*" $(subst ../../../..,$(PROJ_ROOT),$(filter %pmcps_0_0.v,$(DUT_SV))) || echo "0 0 0") | awk '{print $$3}' | sed 's/[[:digit:]]\{3\}/\0\./')
   PL1_CLK ?= $(shell (grep -o "PL1_REF_CLK.*FREQ_HZ [[:digit:]]*" $(subst ../../../..,$(PROJ_ROOT),$(filter %pmcps_0_0.v,$(DUT_SV))) || echo "0 0 0") | awk '{print $$3}' | sed 's/[[:digit:]]\{3\}/\0\./')
   PL2_CLK ?= $(shell (grep -o "PL2_REF_CLK.*FREQ_HZ [[:digit:]]*" $(subst ../../../..,$(PROJ_ROOT),$(filter %pmcps_0_0.v,$(DUT_SV))) || echo "0 0 0") | awk '{print $$3}' | sed 's/[[:digit:]]\{3\}/\0\./')
   PL3_CLK ?= $(shell (grep -o "PL3_REF_CLK.*FREQ_HZ [[:digit:]]*" $(subst ../../../..,$(PROJ_ROOT),$(filter %pmcps_0_0.v,$(DUT_SV))) || echo "0 0 0") | awk '{print $$3}' | sed 's/[[:digit:]]\{3\}/\0\./')
  endif
 endif
endif

ifdef PLUSARGS
 PARG  =+
 PARG :=$(strip $(PARG)$(subst $(comma),$(spc)$(plus),$(PLUSARGS)))
endif
PARG += +CPM6_$(CPM6_SRC:_SECIP=) +PCIE_LINK_$(PCIE_LINK)
ifeq ($(QEMU_PS),1)
 PARG += +QEMU_PS
endif
ifdef PL0_CLK 
 ifneq ($(PL0_CLK),0)
  PARG += +PL0_CLK=$(PL0_CLK)
 endif
endif
ifdef PL1_CLK 
 ifneq ($(PL1_CLK),0)
  PARG += +PL1_CLK=$(PL1_CLK)
 endif
endif
ifdef PL2_CLK 
 ifneq ($(PL2_CLK),0)
  PARG += +PL2_CLK=$(PL2_CLK)
 endif
endif
ifdef PL3_CLK 
 ifneq ($(PL3_CLK),0)
  PARG += +PL3_CLK=$(PL3_CLK)
 endif
endif

# Handle DOFILES: convert comma-separated list to multiple -do arguments
# Example: DOFILES=dofiles/uclirun.do,dofiles/uclirun_dve.do
# Results in: -do /abs/path/dofiles/uclirun.do -do /abs/path/dofiles/uclirun_dve.do
# All paths are converted to absolute paths since simulation runs from a subdirectory
ifdef DOFILES
 # Convert comma-separated list to space-separated, then convert each to absolute path
 _DOFILES_LIST := $(subst $(comma),$(spc),$(DOFILES))
 _DOFILES_ABS := $(foreach f,$(_DOFILES_LIST),$(abspath $(f)))
 DOF_CMD := -do $(subst $(spc),$(spc)-do$(spc),$(_DOFILES_ABS))
endif

# Make it possible to use variations of the uvma-agent repo
# a. env var = UVMA_AGENT_PATH
# b. from framework root (Vivado)
# c. from within this repo (RTL)
ifdef UVMA_AGENT_PATH
 _UVMA_AGENT_PATH := $(UVMA_AGENT_PATH)
else 
 _UVMA_AGENT_PATH := $(FW_ROOT)/uvma-agents
endif

ifndef SEED
 FSTRING= $(spc)
 ifeq ($(SIM),questa)
  SEED =random
  FSEARCH = 'sv_seed[ =]*[0-9]+'
 else ifeq ($(SIM),vcs)
  VCSSEED = +ntb_random_seed_automatic 
  SEED = +ntb_random_seed_automatic 
  FSEARCH = 'random seed used: [0-9]+'
 endif
else 
 ifeq ($(SIM),questa)
  FSEARCH = 'sv_seed[ =]*[0-9]+'
  FSTRING = $(spc)
 else ifeq ($(SIM),vcs)
  VCSSEED = +ntb_random_seed=$(SEED)
  FSEARCH = 'ntb_random_seed=[0-9]+'
  FSTRING = =#variable set to equal sign
 endif
endif

ifeq ($(DEBUG),0)
 ifeq ($(SIM),questa)
  VISCMD = +noacc
 endif
else
 ifeq ($(SIM),questa)
  # n="nets" | p="ports" | r="registers"
  VISCMD = +acc=npr
 else ifeq ($(SIM),vcs)
  CDEBUG = -kdb 
  VISCMD = -kdb=common_elab -debug_access+all
 endif
endif

ifeq (VIVADO,$(findstring VIVADO,$(CPM6_SRC)))
 ifeq ($(SIM),vcs)
  SYNOPSYS_SIM_SETUP_FILES := $(SIM_WORK_DIR)/synopsys_sim.setup.debug
 endif
endif

# Macro to safely move a file only if it exists and source != destination
# Usage: $(call safe_move,source,destination)
define safe_move
 @if [ -f $(1) ] && [ "$(1)" != "$(2)" ]; then \
  mv -f $(1) $(2); \
 fi
endef

# Macro to verify an LSF job completed successfully. Must be used in the same
# shell as the "JOBID=$$(bsub ...)" assignment. Stops the Makefile with a
# helpful message if no job ID came back from bsub, or if the job never ran,
# timed out, or failed (see sim_common/check_job.bash for the exit codes).
# Usage: $(call check_lsf_job,description,errfile,logfile[,ok_rcs])
#  - ok_rcs : space-separated check_job.bash exit codes that do not stop
#             the Makefile (e.g. 1 = job ran but its command returned
#             non-zero, such as a failing test)
define check_lsf_job
if [ -z "$$JOBID" ]; then \
  echo "ERROR: bsub did not return a job ID for the $(1) job."; \
  echo "       LSF may be down or may have rejected the submission."; \
  echo "       Check the bsub output above, or rerun with LSF=0 to run locally."; \
  exit 1; \
fi; \
$(FW_ROOT)/sim_common/check_job.bash $$JOBID; \
rc=$$?; \
if [ $$rc -ne 0 ] && ! echo " $(4) " | grep -q " $$rc "; then \
  echo "ERROR: LSF job $$JOBID ($(1)) did not complete successfully."; \
  case $$rc in \
    1) echo "       The job ran but its command failed or the job was killed.";; \
    2) echo "       The job never started: LSF left it pending and it was killed.";; \
    3) echo "       The job exceeded its maximum run time and was killed.";; \
    4) echo "       LSF no longer knows about the job; it may have been lost.";; \
    *) echo "       check_job.bash returned unexpected exit code $$rc.";; \
  esac; \
  logs=; \
  for f in $(2) $(3); do \
    if [ -f $$f ]; then logs="$$logs $$f"; fi; \
  done; \
  if [ -n "$$logs" ]; then \
    echo "       Check the LSF logfiles for details:$$logs"; \
  fi; \
  echo "       Fix the problem (or rerun with LSF=0 to run locally) and rerun."; \
  exit $$rc; \
fi
endef

# Vivado simulations require the "glbl" module, which we want to resolve
# ONLY when the opt target is ran. We have to do some fancy lookups so
# we can't just rely on Makefile variables (resolved at first pass), so
# we rely on shell itself.
define resolve_glbl
 opt_glbl=; \
 if [ "$(findstring VIVADO,$(CPM6_SRC))" = "VIVADO" ]; then \
  if [ "$(SIM)" = "vcs" ] && [ $(DEBUG) -eq 1 ]; then \
   opt_glbl=$$(grep -o '^xil_defaultlib' $(SIM_WORK_DIR)/synopsys_sim.setup.debug || echo "vivado_dut_KDB").glbl; \
  elif [ "$(SIM)" = "vcs" ] && [ $(DEBUG) -eq 0 ]; then \
   opt_glbl=$$(grep -o '^xil_defaultlib' $(SIM_WORK_DIR)/synopsys_sim.setup || echo "vivado_dut").glbl; \
  elif [ "$(SIM)" = "questa" ]; then \
   opt_glbl="glbl"; \
  fi \
 fi
endef

# Arg 1 controls whether this is used (can be 0,1,$(variable))
define resolve_snps_sim_setup
 if [ "$(findstring VIVADO,$(CPM6_SRC))" = "VIVADO" ] && [ $(or $(1),1) -eq 1 ]; then \
  export SYNOPSYS_SIM_SETUP=synopsys_sim.setup.debug; \
 fi
endef

h help hregr hproj:
	@echo "---Environment Variable Usage"
ifndef DEFAULT_TEST
	@echo "    - DEFAULT_TEST          (unset); given to TEST option"
else
	@echo "    - DEFAULT_TEST ($(DEFAULT_TEST)); given to TEST option"
endif
ifndef DEFAULT_CPM6_SRC
	@echo "    - DEFAULT_CPM6_SRC      (unset); given to CPM6_SRC option"
else
	@echo "    - DEFAULT_CPM6_SRC ($(DEFAULT_CPM6_SRC)); given to CPM6_SRC option"
endif
ifndef DEFAULT_DUT_CLIBS
	@echo "    - DEFAULT_DUT_CLIBS     (unset); given to DUT_CLIBS option"
else
	@echo "    - DEFAULT_DUT_CLIBS ($(DEFAULT_DUT_CLIBS)); given to DUT_CLIBS option"
endif
ifndef DEFAULT_DEBUG
	@echo "    - DEFAULT_DEBUG         (unset); given to DEBUG option"
else
	@echo "    - DEFAULT_DEBUG ($(DEFAULT_DEBUG)); given to DEBUG option"
endif
ifndef DEFAULT_SIM
	@echo "    - DEFAULT_SIM           (unset); given to SIM option"
else
	@echo "    - DEFAULT_SIM ($(DEFAULT_SIM)); given to SIM option"
endif
ifndef DEFAULT_PCIE_LINK
	@echo "    - DEFAULT_PCIE_LINK     (unset); given to PCIE_LINK option"
else
	@echo "    - DEFAULT_PCIE_LINK ($(DEFAULT_PCIE_LINK)); given to PCIE_LINK option"
endif
ifeq ($(MAKEFILE_INTERNAL),1)
ifndef DEFAULT_LSF
	@echo "    - DEFAULT_LSF           (unset); given to LSF option"
else
	@echo "    - DEFAULT_LSF ($(DEFAULT_LSF)); given to LSF option"
endif
ifndef DEFAULT_LSF_SIM_QUEUE
	@echo "    - DEFAULT_LSF_SIM_QUEUE (unset); given to LSF_SIM_QUEUE option"
else
	@echo "    - DEFAULT_LSF_SIM_QUEUE ($(DEFAULT_LSF_SIM_QUEUE)); given to LSF_SIM_QUEUE option"
endif
endif
	@echo "---Simulation Targets"
	@echo "    - c, compile             (step 1 of 3 to run a sim)"
	@echo "    - o, opt                 (step 2 of 3 to run a sim)"
	@echo "    - s, sim                 (step 3 of 3 to run a sim)"
	@echo "    - co                     (alias to c, o in series)"
	@echo "    - os                     (alias to o, s in series)"
	@echo "    - cos                    (alias to c, o, s in series)"
	@echo "    - clean, cln             (clean only simulation outputs)"
	@echo "    - aclean, acln           (all clean; will need to compile, opt, sim again)"
	@echo "    - clean_clibs, cln_clibs (clean compiled libraries)"
	@echo "    - clean_pc, cln_pc       (clean VCS partition compile databases)"
ifeq (VIVADO,$(findstring VIVADO,$(CPM6_SRC)))
	@echo "    - clean_dut, cln_dut     (clean Vivado DUT compiled library)"
endif
	@echo "    - lst [TEST=<name>]      (list all tests or print a specific test description)"
	@echo "    - show_paths             (print all resolved paths affecting the sim)"
	@echo "---Simulation Options"
	@echo "    - CPM6_SRC  | default = $(CPM6_SRC) [$(subst $(spc),$(comma),$(CPM6_SRC_ALLOWED))]"
ifeq (VIVADO,$(findstring VIVADO,$(CPM6_SRC)))
	@echo "    - DUT_CLIBS | default = $(DUT_CLIBS) [$(subst $(spc),$(comma),$(DUT_CLIBS_ALLOWED))]"
endif
	@echo "    - PCIE_LINK | default = $(PCIE_LINK) [$(subst $(spc),$(comma),$(PCIE_LINK_ALLOWED))]"
	@echo "    - TEST      | default = $(TEST); [call lst target to see all] "
	@echo "    - GUI       | default = $(GUI); [$(subst $(spc),$(comma),$(GUI_ALLOWED))]"
	@echo "    - DEBUG     | default = $(DEBUG); [$(subst $(spc),$(comma),$(DEBUG_ALLOWED))]"
	@echo "    - SEED      | default = random"
	@echo "    - DOFILES   | default = none; [comma separated list]"
	@echo "    - SIM       | default = $(SIM); [questa,vcs]"
	@echo "    - DEFINES   | default = none; [comma separated list]"
	@echo "    - PLUSARGS  | default = none; [comma separated list]"
	@echo "    - VERBOSITY | default = MEDIUM; [any UVM verbosity level]"
ifeq ($(MAKEFILE_INTERNAL),1)
	@echo "    - LSF       | default = $(LSF); [1,other]"
	@echo "      - LSF_SIM_QUEUE | (default = $(LSF_SIM_QUEUE)); [LSF queue for sim jobs]"
	@echo "      - OPT_MEM_REQ   | (default = $(OPT_MEM_REQ)); [LSF memory requested in GB]"
	@echo "      - PC_JOBS       | (default = $(PC_JOBS)); [VCS partition compile parallel jobs; also LSF cores for opt]"
	@echo "      - SIM_MEM_REQ   | (default = $(SIM_MEM_REQ)); [LSF memory requested in GB]"
endif
ifdef ADDL_HELP_PRINT
	@echo "---Custom Print"
	@printf "%s\n" $(ADDL_HELP_PRINT)
endif
ifeq ($(MAKECMDGOALS),hregr)
	@echo "---Regression Targets"
	@echo "    - sregr    (simulate regression)"
	@echo "    - regr     (alias to cregr->oregr->sregr)"
	@echo "    - clnregr  (clean all regression)"
	@echo "    - lsregr   (list regression testlists)"
	@echo "    - Required argument to [c,o,s]regr targets"
	@echo "      - TESTLIST = <name> (sregr only)"
	@echo "    - Optional argument to [c,o,s,cln]regr targets"
	@echo "      - REGR_DIR = [LATEST, <some regession>]"
endif

# DESCRIPTION
# Prints every path this Makefile resolves that can affect a simulation,
# plus whether each one currently exists on disk. Meant as a quick
# environment sanity check for users hitting path-related failures.
show_paths:
ifeq (VIVADO,$(findstring VIVADO,$(CPM6_SRC)))
	@echo "---Framework / Testcase Roots"
else
	@echo "---Framework Root"
endif
	@echo "    - FW_ROOT       = $(FW_ROOT) $(if $(wildcard $(FW_ROOT)),[exists],[MISSING])"
ifeq (VIVADO,$(findstring VIVADO,$(CPM6_SRC)))
ifdef TESTCASE_ROOT
	@echo "    - TESTCASE_ROOT = $(TESTCASE_ROOT) $(if $(wildcard $(TESTCASE_ROOT)),[exists],[MISSING])"
else
	@echo "    - TESTCASE_ROOT = (unset)"
endif
endif
ifeq (VIVADO,$(findstring VIVADO,$(CPM6_SRC)))
ifdef PROJ_ROOT
	@echo "    - PROJ_ROOT     = $(PROJ_ROOT) $(if $(wildcard $(PROJ_ROOT)),[exists],[MISSING])"
else
	@echo "    - PROJ_ROOT     = (unset)"
endif
ifdef PROJ_SIM_DIR
	@echo "    - PROJ_SIM_DIR  = $(PROJ_SIM_DIR) $(if $(wildcard $(PROJ_SIM_DIR)),[exists],[MISSING])"
else
	@echo "    - PROJ_SIM_DIR  = (unset)"
endif
endif
	@echo "---Resolved Simulation Paths (depend on CPM6_SRC=$(CPM6_SRC), SIM=$(SIM))"
	@echo "    - SIM_WORK_DIR  = $(SIM_WORK_DIR) $(if $(wildcard $(SIM_WORK_DIR)),[exists],[MISSING])"
	@echo "    - CLIBS_PATH    = $(CLIBS_PATH) $(if $(wildcard $(CLIBS_PATH)),[exists],[MISSING])"
ifeq (VIVADO,$(findstring VIVADO,$(CPM6_SRC)))
	@echo "    - compile.sh    = $(SIM_WORK_DIR)/compile.sh $(if $(wildcard $(SIM_WORK_DIR)/compile.sh),[found],[NOT FOUND])"
endif
ifeq ($(USE_SIP_CLIB),1)
	@echo "---SecureIP Source Paths"
	@echo "    - SIP_PATH      = $(SIP_PATH) $(if $(wildcard $(SIP_PATH)),[exists],[MISSING])"
	@echo '    - SIP_FILELIST  = $(SIP_FILELIST) $(if $(wildcard $(SIP_PATH)/$(SIP_FILELIST)),[exists],[MISSING]) at $$(SIP_PATH)'
endif
ifeq (VIVADO,$(findstring VIVADO,$(CPM6_SRC)))
	@echo "---Debug Clibs (reqd. iff using VCS simulator)"
	@echo "    - CLIBS_DEBUG_ROOT = $(CLIBS_DEBUG_ROOT) $(if $(wildcard $(CLIBS_DEBUG_ROOT)),[exists],[MISSING])"
endif

compile_c_files: $(SO_FILES)

%.so: %.c
ifeq ($(SIM),questa)
	gcc -I"$(QUESTA_HOME)/include" -fPIC -shared -nostartfiles $< -o $@
else ifeq ($(SIM),vcs)
	gcc -I"$(VCS_HOME)/include" -fPIC -shared -nostartfiles $< -o $@
endif

# NOTES 
#  - VCS Info
#    1. VCS requires(!) that you compile the UVM package first. The prerequisites 
#       enforce this without user intervention.
#    2. The LIBRARY_SCAN=TRUE command means VCS will automatically scan the libraries
#       for design units not found, so we don't need to pass -L explicitly.
c compile: compile_c_files chk_uvm_vars chk_cpm6_src chk_prereqs chk_pcie_link chk_debug chk_sim_work_dir chk_questa_ini
ifeq ($(SIM),questa)
# Compile all local TB files; must link to several libraries
	export VERSION_PRINT_PATH=$(VERSION_PRINT_PATH); \
	cd $(SIM_WORK_DIR); vlog -64 $(QUESTA_INI_ARG) -incr -mfcu -sv $(CDEF) -work work -l questa.vlog.log \
      +incdir+$(UVM_HOME_questa) $(VIP_LIBS_CMD) \
      -timescale=1ns/1ps \
      $(PRE_INCDIR) \
      $(COMPILE_EXTRA_PRE) +define+INCLUDE_FW_REPO_INFO \
      -F $(FW_ROOT)/cpm6/common/dotf/tb_files.f \
      $(COMPILE_EXTRA) \
      $(VLOG_SUPPRESS) \
      +define+QUESTA_SIM
else ifeq ($(SIM),vcs)
# Compile all local TB files; must link to several libraries
	export VERSION_PRINT_PATH=$(VERSION_PRINT_PATH); \
	cd $(SIM_WORK_DIR); vlogan -full64 -sverilog -work work -ntb_opts uvm-1.1 -l vcs.vlogan.log \
      -timescale=1ns/1ps \
      $(CDEF) $(CDEBUG) +warn=noCVMBI \
      $(PRE_INCDIR) \
      $(COMPILE_EXTRA_PRE) +define+INCLUDE_FW_REPO_INFO \
      -F $(FW_ROOT)/cpm6/common/dotf/tb_files.f \
      $(COMPILE_EXTRA) \
      +define+VCS_SIM
endif

# Resolve the VCS partition-compile options into the shell variable pc_opts.
# Must run from SIM_WORK_DIR. Messages go to stderr so they stay out of the
# JOBID command substitution.
define resolve_partcomp
pc_opts=""; \
if [ "$(SIM)" = "vcs" ]; then \
  if [ -f $(PC_BUSY) ]; then rm -rf $(PC_DB) $(PC_BUSY); fi; \
  rm -rf $(PC_NEW); \
  if [ -d $(PC_DB) ]; then \
    echo "INFO: PARTCOMP: reusing $(PC_DB); changed partitions go to $(PC_NEW)" >&2; \
    pc_opts="-partcomp -fastpartcomp=j$(PC_JOBS) -partcomp_sharedlib=$(PC_DB) -partcomp_dir=$(PC_NEW)"; \
  else \
    echo "INFO: PARTCOMP: no $(PC_DB) yet; saving a full partition build to it" >&2; \
    touch $(PC_BUSY); \
    pc_opts="-partcomp -fastpartcomp=j$(PC_JOBS) -partcomp_dir=$(PC_DB)"; \
  fi; \
fi
endef

# o opt | variable definitions
ifeq ($(SIM),questa)
o opt: OPT_CMD = vopt -64 $(QUESTA_INI_ARG) $(VISCMD) +nospecify $(VOPT_SUPPRESS) -work work \
                 -l questa.vopt.log tb_top -o tb_top_opt \
                 $(VIP_LIBS_CMD) $(DUT_LIBS_CMD) \
                 $(OPT_EXTRA)
else ifeq ($(SIM),vcs)
o opt: OPT_CMD = vcs -full64 +nospecify -xlrm uniq_prior_final -ntb_opts uvm-1.1 \
                 -l vcs.opt.log work.tb_top +warn=noCNST-PPRW,noRT-NCMUCS,noUNGB $(VISCMD) \
                 $(AVERY_PLI)/lib.linux/libtb_vcs64.a -P $(AVERY_PLI)/tb_vcs64.tab +vpi \
                 +warn=noUII-L -reportstats $(OPT_EXTRA)
endif

o opt: chk_sim chk_debug chk_sim_work_dir chk_questa_ini
ifeq ($(LSF),1)
	@rm -f $(SIM_WORK_DIR)/bsub.opt.$(SIM).*.log
	@echo "INFO: SUBMITTING THE OPTIMIZATION JOB TO LSF"
	@JOBID=$$($(call resolve_snps_sim_setup,$(DEBUG)); \
    $(call resolve_glbl); \
    cd $(SIM_WORK_DIR); \
    $(call resolve_partcomp); \
    bsub -J pvs_cpm6_$@ -q short -n $(OPT_CORES) -app sil_rhel810  \
      -e bsub.opt.$(SIM).error.log -o bsub.opt.$(SIM).output.log \
      -R "span[hosts=1] rusage[mem=$(OPT_MEM_REQ)GB]" \
      $(OPT_CMD) $$pc_opts $$opt_glbl | grep -o '[[:digit:]]*'); \
    sleep 10; \
    echo "INFO: JOB $$JOBID SUBMITTED"; \
    $(call check_lsf_job,optimization,$(SIM_WORK_DIR)/bsub.opt.$(SIM).error.log,$(SIM_WORK_DIR)/bsub.opt.$(SIM).output.log)
else
	$(call resolve_snps_sim_setup,$(DEBUG)); \
    $(call resolve_glbl); \
    cd $(SIM_WORK_DIR); $(call resolve_partcomp); eval $(OPT_CMD) $$pc_opts $$opt_glbl
endif
	@cd $(SIM_WORK_DIR); rm -f $(PC_BUSY)

ifeq ($(SIM),questa)
 ifdef DOFILES
  DOCMD += $(DOF_CMD)
 endif
 VIEWMODE = $(if $(filter $(GUI),-1 0),-batch,-gui)
 ifneq ($(filter $(GUI),-1 0 3),)
  ifeq ($(GUI),-1)
   DOCMD += -do \"log -r /tb_top/*\"
  endif
   DOCMD += -do \"run -all\"
  ifneq ($(GUI),-3)
   DOCMD += -do \"quit\"
  endif
 else ifeq ($(GUI),2)
  DOCMD += -do \"run 0\"
 endif
 LSF_SIM_APP=sil_rhel810
 LOGFILE=questa.vsim.log
 PRE_SIM_CMD += if [ -f $(SIM_WORK_DIR)/nocattrs.dat ]; then ln -s ../nocattrs.dat $(ODIR)/nocattrs.dat; fi;
 SIM_CMD = vsim -64 $(VIEWMODE) $(VSIM_SUPPRESS) -work ../work tb_top_opt \
           -l $(LOGFILE) +UVM_VERBSOITY=UVM_$(VERBOSITY) \
           $(QUESTA_INI_ARG) $(SIM_SO_LIBS) \
           $(VIP_LIBS_CMD) $(DUT_LIBS_CMD) $(SIM_EXTRA) \
           -sv_seed $(SEED) +UVM_TESTNAME=$(TEST) \
           $(DOCMD) -permit_unmatched_virtual_intf \
           -pli $(AVERY_PLI)/lib.linux/libtb_ms64.a $(PARG)
else ifeq ($(SIM),vcs)
 LSF_SIM_APP=sil_rhel810
 ifdef DOFILES
  DOCMD += $(DOF_CMD)
 else
  DOCMD += -do uclirun.do
 endif
 VIEWMODE = $(if $(filter $(GUI),-1 0),-ucli,-gui)
 LOGFILE=vcs.sim.log
 PRE_SIM_CMD = @if [ ! -f $(SIM_WORK_DIR)/simv ]; then echo "ERROR: No simulation executable"; exit 1; fi;
 PRE_SIM_CMD += ln -s ../synopsys_sim.setup $(ODIR); touch $(ODIR)/uclirun.do;
 ifeq ($(GUI),-1)
  PRE_SIM_CMD += echo "fsdbDumpvars 0 \"tb_top\" +all +trace_process" >> $(ODIR)/uclirun.do;
 endif
 ifneq ($(filter $(GUI),-1 0 3),)
  PRE_SIM_CMD += echo "run" >> $(ODIR)/uclirun.do;
 else ifeq ($(GUI),2)
  PRE_SIM_CMD += echo "run 0" >> $(ODIR)/uclirun.do;
 endif
 PRE_SIM_CMD += if [ -f $(SIM_WORK_DIR)/nocattrs.dat ]; then ln -s ../nocattrs.dat $(ODIR)/nocattrs.dat; fi;
 SIM_CMD = ../simv -no_save -l $(LOGFILE) -reportstats -licqueue -licwait 1 \
           $(VCSSEED) $(SIM_SO_LIBS) $(SIM_EXTRA) \
           +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=UVM_$(VERBOSITY) \
           $(VIEWMODE) $(DOCMD) -reportstats $(PARG)
endif

s sim: ODIR:=$(SIM_WORK_DIR)/$(TEST)_$(shell date +"%m%d%y_%Hh%Mm%Ss")
s sim: chk_pli chk_sim chk_verb chk_gui chk_sim_work_dir chk_questa_ini
ifeq ($(LSF),1)
	@mkdir $(ODIR)
	@$(PRE_SIM_CMD)
	@echo "INFO: SUBMITTING THE SIMULATION JOB TO LSF"
	@JOBID=$$(cd $(ODIR); \
    bsub -J pvs_cpm6_$@ -q $(LSF_SIM_QUEUE) -app $(LSF_SIM_APP) \
      -e bsub.sim.$(SIM).error.log \
      -o bsub.sim.$(SIM).output.log \
      -R "rusage[mem=$(SIM_MEM_REQ)GB]" \
      -M $(SIM_MEM_REQ)GB \
      $(SIM_CMD) | grep -o '[[:digit:]]*'); \
	sleep 10; \
	echo "INFO: JOB $$JOBID SUBMITTED"; \
	$(call check_lsf_job,simulation,$(ODIR)/bsub.sim.$(SIM).error.log,$(ODIR)/bsub.sim.$(SIM).output.log,1)
else
	@mkdir $(ODIR)
	@$(PRE_SIM_CMD)
	cd $(ODIR); eval $(SIM_CMD)
endif
	@$(MAKE) LOGFILE=$(ODIR)/$(LOGFILE) ODIR=$(subst $(shell pwd)/,,$(ODIR)) --no-print-directory -- PARENT_CMD=$@ --print_results

# This target should remove all simulation metadata
clean cln: QUESTA_FILES=vsim.wlf vsim_stacktrace.vstf *questa.vsim.log
clean cln: VCS_FILES=vcs_hdrs.h novas* inter.fsdb ucli.key *vcs.sim.log vc_hdrs.h
clean cln: chk_sim_work_dir
clean cln:
	@echo "INFO: Removing all test runs"
	cd $(SIM_WORK_DIR); rm -rf `find . -maxdepth 1 -type d -name "*[0-9][0-9]m[0-9][0-9]s" | grep -v regr`
ifndef SIM_ARG
	@echo "INFO: Removing all simulation metadata files"
	cd $(SIM_WORK_DIR); rm -f $(QUESTA_FILES) $(VCS_FILES)
else
	@echo "INFO: Removing all simulator specific simulation metadata files"
ifeq ($(SIM),questa)
	cd $(SIM_WORK_DIR); rm -f $(QUESTA_FILES)
else ifeq ($(SIM),vcs)
	cd $(SIM_WORK_DIR); rm -f $(VCS_FILES)
else
	$(error "ERROR: Invalid value for the SIM variable")
endif
endif

# This should remove all compilation, elab, and sim metadata
aclean acln: QUESTA_FILES=work *bsub*questa*log *questa*log
aclean acln: VCS_FILES=workvcs simv.* csrc $(PC_FILES) verdi_config_file sysBusyPLog \
                       verdiLog simv simv_regr* bsub*vcs*log vcs*log AN.DB
aclean acln: clean chk_sim_work_dir
ifndef SIM_ARG
	cd $(SIM_WORK_DIR); rm -rf $(QUESTA_FILES) $(VCS_FILES)
else
ifeq ($(SIM),questa)
	cd $(SIM_WORK_DIR); rm -rf $(QUESTA_FILES)
else ifeq ($(SIM),vcs)
	cd $(SIM_WORK_DIR); rm -rf $(VCS_FILES)
else
	$(error "ERROR: Invalid value for the SIM variable")
endif
endif

clean_clibs cln_clibs: chk_sim_work_dir
	cd $(SIM_WORK_DIR); rm -rf $(PC_FILES)
ifeq (VIVADO,$(findstring VIVADO,$(CPM6_SRC)))
	@echo "INFO: Removing all compiled libraries"
	cd $(SIM_WORK_DIR); rm -rf clibs
else ifndef SIM_ARG
	@echo "INFO: Removing all compiled libraries"
	cd $(SIM_WORK_DIR); rm -rf clibs
else
	@echo "INFO: Removing all simulator specific compiled libraries"
ifeq ($(SIM),questa)
	cd $(SIM_WORK_DIR); rm -rf clibs/questa
else ifeq ($(SIM),vcs)
	cd $(SIM_WORK_DIR); rm -rf clibs/vcs
else
	$(error "ERROR: Invalid value for the SIM variable")
endif
endif

clean_dut cln_dut: chk_sim_work_dir
	cd $(SIM_WORK_DIR); rm -rf $(PC_FILES)
ifeq (VIVADO,$(findstring VIVADO,$(CPM6_SRC)))
	@echo "INFO: Removing Vivado DUT compiled library"
	cd $(SIM_WORK_DIR); rm -rf clibs/*vivado_dut*
endif

# Remove only the partition compile databases; the next opt is a full build
clean_pc cln_pc: chk_sim_work_dir
ifeq ($(SIM),questa)
	@echo "INFO: SIM=questa has no partition compile databases; nothing to be done"
else
	@echo "INFO: Removing partition compile databases"
	cd $(SIM_WORK_DIR); rm -rf $(PC_FILES)
endif

# Print the description of a specific test or print all tests
lst: EXT_TEST_DIRS = $(wildcard $(TEST_DIR)/ext*test)
lst: TESTCASE_TEST_DIR := $(shell find $(TESTCASE_ROOT)/verif -maxdepth 1 -type d -name test 2>/dev/null)
lst: TESTFILE = $(shell find $(TEST_DIR) $(TESTCASE_TEST_DIR) -type f -name $(TEST).sv)
lst: 
ifdef PRINT_DESC
	@if [ -z $(TESTFILE) ]; then \
      echo "ERROR: File $(TEST).sv not in $(TEST_DIR) or its subdirs"; \
    else \
      $(eval ENDLINE:=`grep -n '|\*/' $(TESTFILE) | cut -f1 -d:`) \
      if [ -z $(ENDLINE) ]; then \
        echo "$(TEST): DESCRIPTION not present"; \
      else \
        sed -n "2,$(ENDLINE)p" $(TESTFILE); \
      fi; \
	fi
else
	@echo -n "// "; printf "%.0s*" {1..80}; echo " //"
	@echo -e "// - Potential tests to run, listed from director(ies):"
	@echo -e "//   - $(shell realpath --relative-to=$(shell pwd) $(TEST_DIR))"
	@if [ ! -z $(TESTCASE_TEST_DIR) ]; then \
      echo -e "//   - $$(realpath --relative-to=$(shell pwd) $(TESTCASE_TEST_DIR))"; \
	fi
	@echo -e "// - Get the description of a specific test by giving to this target e.g."
	@echo -e "//   - $$> make lst TEST=<testname>"
	@echo -e "// - Specify using TEST argument when running s/sim target e.g."
	@echo -e "//   - $$> make s TEST=<testname>"
	@echo -e "// - Framework tests are filtered by TEST_WHITELIST = \"$(TEST_WHITELIST)\""
	@echo -e "//   (each word is a regex - ALL/all disables filtering) "
	@if [ ! -z "$(TEST_BLACKLIST)" ]; then \
      echo -e "// - Project tests are hidden by TEST_BLACKLIST = \"$(TEST_BLACKLIST)\""; \
	fi
	@echo -n "// "; printf "%.0s*" {1..80}; echo " //"
	@CANDIDATES=$$(ls -p $(TEST_DIR) | egrep -v '/|pkg|server|other' | sed 's/\.sv//'); \
    for t in $$CANDIDATES; do \
      if [ "$$(echo $(TEST_WHITELIST) | tr '[:upper:]' '[:lower:]')" = "all" ]; then MATCH=1; \
      else \
        MATCH=0; \
        for pat in $(TEST_WHITELIST); do \
          echo "$$t" | grep -Pq "^$$pat$$" 2>/dev/null && MATCH=1; \
        done; \
      fi; \
      if [ "$$MATCH" = "1" ]; then \
        if [ "$$t" = "$(TEST)" ]; then echo "* $$t (default)"; else echo "* $$t"; fi; \
      fi; \
    done
	@for dir in $(EXT_TEST_DIRS); do \
      CANDIDATES=$$(ls -p $$dir | egrep -v 'other|info' | sed 's/\.sv//'); \
      MATCHES=""; \
      for t in $$CANDIDATES; do \
        if [ "$$(echo $(TEST_WHITELIST) | tr '[:upper:]' '[:lower:]')" = "all" ]; then MATCH=1; \
        else \
          MATCH=0; \
          for pat in $(TEST_WHITELIST); do \
            echo "$$t" | grep -Pq "^$$pat$$" 2>/dev/null && MATCH=1; \
          done; \
        fi; \
        if [ "$$MATCH" = "1" ]; then \
          if [ "$$t" = "$(TEST)" ]; then MATCHES="$$MATCHES* $$t (default)\n"; \
          else MATCHES="$$MATCHES* $$t\n"; fi; \
        fi; \
      done; \
      if [ -n "$$MATCHES" ]; then \
        echo "- `cat $$dir/info`" | sed 's/^/\* /'; \
        printf "$$MATCHES"; \
      fi; \
    done
	@if [[ ! -z "$(TESTCASE_TEST_DIR)" ]]; then \
      echo -e "* - Project Specific Tests"; \
      tests=$$(find $(TESTCASE_TEST_DIR) -type f -name "*sv" -printf '%f\n'); \
      if [[ -z "$$tests" ]]; then echo "* (none)"; \
      else \
        for test in $$tests; do \
          t=$${test%.sv}; \
          echo "$$test" | grep -q 'pkg\.' && continue; \
          HIDE=0; \
          for pat in $(TEST_BLACKLIST); do \
            echo "$$t" | grep -Pq "^$$pat$$" 2>/dev/null && HIDE=1; \
          done; \
          if [ "$$HIDE" = "0" ]; then echo "* $$t"; fi; \
        done; \
      fi; \
	fi
	@echo -e ""
endif

co : c o 
os : o s 
cos: c o s

chk_prereqs: COMMON_CMD=--no-print-directory LSF=$(LSF) -- --check_clibs_prereq
chk_prereqs: chk_lib_refs $(SYNOPSYS_SIM_SETUP_FILES)
	@$(MAKE) PREQ=uvm         PREQ_TGT=uvm                       $(COMMON_CMD)
	@$(MAKE) PREQ=uvma_agents PREQ_TGT=uvma                      $(COMMON_CMD)
	@$(MAKE) PREQ=avery       PREQ_TGT=avery                     $(COMMON_CMD)
	@$(MAKE) PREQ=vivado_dut  PREQ_TGT=vivado_dut                $(COMMON_CMD)
	if [ "$(USE_SIP_CLIB)" = "1" ]; then \
     $(MAKE) PREQ=cpm6_secip                       PREQ_TGT=cpm6_secip $(COMMON_CMD); \
	fi

chk_cpm6_src:
ifeq ($(BAD_CPM6_SRC),1)
	$(error Invalid value for CPM6_SRC: "$(CPM6_SRC)". Allowed options are: $(CPM6_SRC_ALLOWED))
endif

chk_sim_work_dir:
ifeq ($(strip $(SIM_WORK_DIR)),)
	$(error SIM_WORK_DIR is empty; PROJ_SIM_DIR must be set when CPM6_SRC=$(CPM6_SRC))
endif
	@if [ ! -d "$(SIM_WORK_DIR)" ]; then \
      echo "ERROR: Directory $(SIM_WORK_DIR) (variable SIM_WORK_DIR) does not exist"; \
      exit 1; \
	fi

chk_questa_ini:
ifeq ($(SIM),questa)
 ifeq ($(QUESTA_INI_FOUND),)
	$(error No Questa ini found in $(SIM_WORK_DIR); expected one of: $(QUESTA_INI_NAMES))
 else ifneq ($(words $(QUESTA_INI_FOUND)),1)
	$(error Multiple Questa ini files found in $(SIM_WORK_DIR): $(notdir $(QUESTA_INI_FOUND)); keep only one)
 endif
endif

# Verify the SecureIP directory and filelist exist before the cpm6_secip clib
# is created (and before any compile job is submitted to LSF)
chk_cpm6_secip_filelist:
	@if [ ! -d "$(SIP_PATH)" ]; then \
      echo "ERROR: Directory $(SIP_PATH) (variable SIP_PATH) does not exist"; \
      exit 1; \
	elif [ ! -f "$(SIP_PATH)/$(SIP_FILELIST)" ]; then \
      echo "ERROR: Filelist $(SIP_PATH)/$(SIP_FILELIST) (variables SIP_PATH/SIP_FILELIST) does not exist"; \
      exit 1; \
	fi

chk_pcie_link:
ifeq ($(BAD_PCIE_link),1)
	$(error Invalid value for PCIE_LIKE: "$(PCIE_LINK)". Allowed options are: $(PCIE_LINK_ALLOWED))
endif

chk_sim:
ifeq ($(BAD_SIM),1)
	$(error Invalid value for SIM: "$(SIM)". Allowed options are: $(SIM_ALLOWED))
endif

chk_debug:
ifeq ($(BAD_DEBUG),1)
	$(error Invalid value for DEBUG: "$(DEBUG)". Allowed options are: $(DEBUG_ALLOWED))
endif

chk_verb:
ifeq ($(BAD_VERBOSITY),1)
	$(error Invalid value for VERBOSITY: "$(VERBOSITY)". Allowed options are: $(VERBOSITY_ALLOWED))
endif

chk_gui:
ifeq ($(BAD_GUI),1)
	$(error Invalid value for GUI: "$(GUI)". Allowed options are: $(GUI_ALLOWED))
endif

chk_dut_clibs:
ifeq ($(BAD_DUT_CLIBS),1)
	$(error Invalid value for DUT_CLIBS: "$(DUT_CLIBS)". Allowed options are: $(DUT_CLIBS_ALLOWED))
endif

# This is the required Avery PLI, but users can override by setting REQD_AVERY_PLI=any
REQD_AVERY_PLI?=2025.3_1
chk_pli:
ifndef AVERY_PLI
	$(error "AVERY_PLI env variable MUST be set to run simulations")
else ifeq (,$(wildcard $(AVERY_PLI)/.))
	$(error "AVERY_PLI env variable is set to $(AVERY_PLI), which is not a valid directory")
else ifneq ($(REQD_AVERY_PLI),any)
ifeq (,$(findstring $(REQD_AVERY_PLI),$(AVERY_PLI)))
	$(error "AVERY_PLI env variable must be set to <path>/avery_pli-$(REQD_AVERY_PLI)")
endif
endif

# Make phony so this will always run so we just have to update 
.PHONY : $(SIM_WORK_DIR)/synopsys_sim.setup.debug
$(SIM_WORK_DIR)/synopsys_sim.setup.debug: chk_sim_work_dir
	@cp $(SIM_WORK_DIR)/synopsys_sim.setup $(SIM_WORK_DIR)/synopsys_sim.setup.tmp
	@sed -i 's/vivado_dut/vivado_dut_KDB/g' $(SIM_WORK_DIR)/synopsys_sim.setup.tmp
	@build=$$(grep -oE "OTHERS.*builds/[^/]+" $(SIM_WORK_DIR)/synopsys_sim.setup.tmp | cut -d/ -f4); \
	if [[ $$build == *"PRIME"* ]]; then \
	  libFolder="PRIME"; \
	else \
	  libFolder=$$(echo $$build | sed -e 's:_: :'g | awk '{print $$1}'); \
	fi; \
	if [ -d $(CLIBS_DEBUG_ROOT)/$$libFolder/$$build ]; then \
		sed -i "s|OTHERS=.*|OTHERS=$(CLIBS_DEBUG_ROOT)/$$libFolder/$$build/synopsys_sim.setup|" $(SIM_WORK_DIR)/synopsys_sim.setup.tmp; \
	else \
		sed -i "s|OTHERS=.*|OTHERS=$(CLIBS_DEBUG_ROOT)/$$libFolder/latest/synopsys_sim.setup|" $(SIM_WORK_DIR)/synopsys_sim.setup.tmp; \
	fi
	@mv $(SIM_WORK_DIR)/synopsys_sim.setup.tmp $@

chk_lib_refs: VIV_COMP_FILE := $(if $(filter $(SIM),questa),$(wildcard $(SIM_WORK_DIR)/*_compile.do),$(SIM_WORK_DIR)/compile.sh)
chk_lib_refs: LIB_FILE := $(if $(filter $(SIM),questa),$(QUESTA_INI),$(SIM_WORK_DIR)/synopsys_sim.setup)
chk_lib_refs: REF_CHAR := $(if $(filter $(SIM),questa),=,:)
chk_lib_refs: chk_dut_clibs chk_sim_work_dir chk_questa_ini
ifeq ($(USE_SIP_CLIB),0)
	@sed -i '/cpm6_secip/d' $(LIB_FILE)
endif
ifeq ($(SIM),questa)
ifeq (VIVADO, $(findstring VIVADO,$(CPM6_SRC)))
ifeq ($(DUT_CLIBS),MANY)
	@sed -i '/^vivado_dut/d' $(LIB_FILE)
	@for clib in $(shell grep -Eo '\-work [[:alnum:]_]+' $(VIV_COMP_FILE) | cut -d ' ' -f2 | sort -u | tr '\n' ' '); do \
      physname=`basename $(CLIBS_PATH)`/vivado_dut/$$clib; \
      if [ $$(grep -c "^$$clib " $(LIB_FILE)) -eq 0 ]; then \
        sed -i "/AutoLibMapping/a $$clib $(REF_CHAR) $$physname" $(LIB_FILE); \
      fi \
	done
endif
endif
	@echo "INFO: Checking to make sure all compiled libraries are referenced in $(LIB_FILE)"
	for clib in $(VIP_LIBS) $(DUT_LIBS); do \
      physname=`basename $(CLIBS_PATH)`/$$clib; \
      if [ $$(grep -c "^$$clib " $(LIB_FILE)) -eq 0 ]; then \
        sed -i "/AutoLibMapping/a $$clib $(REF_CHAR) $$physname" $(LIB_FILE); \
      fi \
	done
	@if [ -n "$$(grep -A1 'AutoLibMapping' $(LIB_FILE) | tail -1)" ]; then \
      sed -i "/AutoLibMapping/G" $(LIB_FILE); \
	fi
else ifeq ($(SIM),vcs)
ifeq (VIVADO, $(findstring VIVADO,$(CPM6_SRC)))
	@rm -rf $(SIM_WORK_DIR)/vcs_lib
	@sed -i '/vcs_lib/d' $(LIB_FILE)
ifeq ($(DUT_CLIBS),MANY)
	@rm -rf $(CLIBS_PATH)/vivado_dut/AN.DB
	@sed -i '/^vivado_dut/d' $(LIB_FILE)
	@for clib in $(shell grep -Eo '\-work [[:alnum:]_]+' $(VIV_COMP_FILE) | cut -d ' ' -f2 | sort -u | tr '\n' ' '); do \
      physname=`basename $(CLIBS_PATH)`/vivado_dut/$$clib; \
      if [ $$(grep -c "^$$clib " $(LIB_FILE)) -eq 0 ]; then \
        sed -i "/OTHERS/i $$clib $(REF_CHAR) $$physname" $(LIB_FILE); \
      fi \
	done
endif
endif
	@if [ $$(grep -c "^work > default" $(LIB_FILE)) -eq 0 ]; then \
      sed -i '1i work > default' $(LIB_FILE); \
	fi
	@if [ $$(grep -c "^default : workvcs" $(LIB_FILE)) -eq 0 ]; then \
      sed -i '1a default : workvcs' $(LIB_FILE); \
	fi
	@echo "INFO: Checking to make sure all compiled libraries are referenced in $(LIB_FILE)"
	for clib in $(VIP_LIBS) $(DUT_LIBS); do \
      physname=`basename $(CLIBS_PATH)`/$$clib; \
      if [ $$(grep -c "$$clib " $(LIB_FILE)) -eq 0 ]; then \
        sed -i "/OTHERS/i $$clib $(REF_CHAR) $$physname" $(LIB_FILE); \
      fi \
	done
endif

chk_uvm_vars: chk_sim
ifeq ($(SIM),questa)
	@if [ -z $(QUESTA_HOME) ]; then \
      echo "FATAL: QUESTA_HOME env var not set"; \
      exit 1; \
    elif [ ! -d $(UVM_HOME_questa) ]; then \
      echo "FATAL: $(UVM_HOME_questa) does not resolve to a directory"; \
      exit 1; \
	fi
else ifeq ($(SIM),vcs)
	@if [ -z $(VCS_HOME) ]; then \
      echo "FATAL: VCS_HOME env var not set"; \
      exit 1; \
    elif [ ! -d $(UVM_HOME_vcs) ]; then \
      echo "FATAL: $(UVM_HOME_vcs) does not resolve to a directory"; \
      exit 1; \
	fi
endif

# ----------------------------------------------------------------------------
# Pseudo-hidden targets
#  - These are here so that other targets can call them but it's not expected
#    that any user will explicitly call them
# ----------------------------------------------------------------------------

# DESCRIPTION
# This prints all relevant test run information and then calls the python script 
# that parses the logfile for error strings and summarizes the test results to 
# the terminal
# - PARENT_CMD = whoever called this recipe
--print_results: TESTSEED=$(shell grep -i -o -E $(FSEARCH) $(LOGFILE) 2>/dev/null | sed 's/.*$(FSTRING)\([[:digit:]]\+\)/\1/')
--print_results:
	@echo -n "// "; printf "%.0s-" {1..80}; echo " //"
	@echo "// OUTPUT DIR   = $(ODIR)"
	@echo "// TEST NAME    = $(TEST)"
	@if [ -e "$(LOGFILE)" ]; then \
      echo "// SEED         = $(TESTSEED)"; \
      echo "// RUN AGAIN    = make $(PARENT_CMD) TEST=$(TEST) SEED=$(TESTSEED) GUI=1"; \
      echo -n '// '; \
      $(FW_ROOT)/sim_common/sim_parselog.py $(SIM) $(LOGFILE); \
    else \
      echo "// RUN AGAIN    = make s TEST=$(TEST) GUI=1"; \
      echo -n "// "; printf "%.0s-" {1..80}; echo " //" ; \
      echo "// No logfile exists, check what went wrong"; \
	fi
	@echo -n "// "; printf "%.0s-" {1..80}; echo " //"

# DESCRIPTION
# This will create the Avery and UVM library for either Questa or VCS. This target
# will only be called by super-users and probably very infrequently. The SNPS VIP
# requires defining the UVM_DISABLE_AUTO_ITEM_RECORDING macro.
--create_uvm_clib: chk_sim chk_uvm_vars chk_sim_work_dir chk_questa_ini
ifeq ($(SIM),questa)
	@if [ ! -d $(CLIBS_PATH)/uvm ]; then \
      mkdir -p $(CLIBS_PATH); \
      vlib $(CLIBS_PATH)/uvm; \
    fi
	if [ ! -z $(FORCE) ]; then \
      rm -rf $(CLIBS_PATH)/uvm/*; \
	fi
	if [ ! -f $(CLIBS_PATH)/uvm/_vmake ] || [ ! -z $(FORCE) ]; then \
      cd $(SIM_WORK_DIR); vlog -64 $(QUESTA_INI_ARG) -sv -work uvm +incdir+$(UVM_HOME_questa) \
        $(UVM_HOME_questa)/uvm.sv $(UVM_HOME_questa)/dpi/uvm_dpi.cc \
        +define+UVM_DISABLE_AUTO_ITEM_RECORDING \
        -l clibs/vlog.uvm.log \
        -ccflags "-DQUESTA" -ccwarn off \
        -timescale=1ps/1ps \
        -stats=+perf+verbose; \
	fi
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vlog.uvm.log,$(CLIBS_PATH)/vlog.uvm.log)
else ifeq ($(SIM),vcs)
	if [ ! -d $(CLIBS_PATH)/uvm ]; then \
      mkdir -p $(CLIBS_PATH)/uvm; \
	fi
	if [ ! -z $(FORCE) ]; then \
      rm -rf $(CLIBS_PATH)/uvm/*; \
	fi
	if [ ! -f $(CLIBS_PATH)/uvm/AN.DB/vloganopts.db ] || [ ! -z $(FORCE) ]; then \
      cd $(SIM_WORK_DIR); vlogan -full64 -sverilog -work uvm -ntb_opts uvm-1.1 -timescale=1ps/1ps \
      -l clibs/vlogan.uvm.log +define+UVM_DISABLE_AUTO_ITEM_RECORDING; \
	fi
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vlogan.uvm.log,$(CLIBS_PATH)/vlogan.uvm.log)
endif

# DESCRIPTION
# This will check if the PREQ clib has been created for a specific simulator 
# and if it hasn't, it will actually go call the PREQ_TGT rceipe.
--check_clibs_prereq: chk_sim
ifeq ($(SIM),questa)
	@if [ ! -f $(CLIBS_PATH)/$(PREQ)/_vmake ]; then \
      $(MAKE) --no-print-directory -- --create_$(PREQ_TGT)_clib; \
    fi
else ifeq ($(SIM),vcs)
	@if [ ! -f $(CLIBS_PATH)/$(PREQ)/AN.DB/vloganopts.db ]; then \
      $(MAKE) --no-print-directory -- --create_$(PREQ_TGT)_clib; \
    fi
endif

# DESCRIPTION
# This will create the Avery and UVM library for either Questa or VCS. This target
# will only be called by super-users and probably very infrequently.
--create_avery_clib: chk_sim chk_uvm_vars chk_sim_work_dir chk_questa_ini
	@$(MAKE) PREQ=uvm PREQ_TGT=uvm --no-print-directory -- --check_clibs_prereq
ifeq ($(SIM),questa)
	@if [ ! -d $(CLIBS_PATH)/avery ]; then \
      mkdir -p $(CLIBS_PATH); \
      vlib $(CLIBS_PATH)/avery; \
	fi
	if [ ! -z $(FORCE) ]; then \
      rm -rf $(CLIBS_PATH)/avery/*; \
	fi
	if [ ! -f $(CLIBS_PATH)/avery/_vmake ] || [ ! -z $(FORCE) ]; then \
      cd $(SIM_WORK_DIR); vlog -64 $(QUESTA_INI_ARG) -sv -mfcu -L uvm -work avery +incdir+$(UVM_HOME_questa) \
        -f $(FW_ROOT)/common/vip/avery_pciecxl_questa.f \
        +define+APCI_MAX_DATA_WIDTH=8 \
        -l clibs/vlog.avery.log \
        -stats=+perf+verbose; \
	fi
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vlog.avery.log,$(CLIBS_PATH)/vlog.avery.log)
else ifeq ($(SIM),vcs)
	@if [ ! -d $(CLIBS_PATH)/avery ]; then \
      mkdir -p $(CLIBS_PATH)/avery; \
	fi
	if [ ! -z $(FORCE) ]; then \
      rm -rf $(CLIBS_PATH)/avery/*; \
	fi
	if [ ! -f $(CLIBS_PATH)/avery/AN.DB/vloganopts.db ] || [ ! -z $(FORCE) ]; then \
      cd $(SIM_WORK_DIR); vlogan -full64 -sverilog -work avery -ntb_opts uvm-1.1 -l clibs/vlogan.avery.log \
        +define+APCI_MAX_DATA_WIDTH=8 \
        -f $(FW_ROOT)/common/vip/avery_pciecxl_vcs.f; \
	fi
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vlogan.avery.log,$(CLIBS_PATH)/vlogan.avery.log)
endif

# DESCRIPTION
# This will create the Synopsys VIP library for either Questa or VCS. This target
# will only be called by super-users and probably very infrequently.
#  - General Info
#    1. Synopsys VIP has a strange way of getting compiled and does pretty
#       much everything through `includes, so you have to have a file that
#       `includes their "first" include, then everything cascades
#  - Questa Info
#    1. Synopsys VIP has a strange way of getting compiled and does pretty
--create_snps_clib: chk_sim chk_uvm_vars chk_sim_work_dir chk_questa_ini
	@$(MAKE) PREQ=uvm PREQ_TGT=uvm --no-print-directory -- --check_clibs_prereq
ifeq ($(SIM),questa)
	if [ ! -z $(FORCE) ]; then \
      rm -rf $(CLIBS_PATH)/svt_axi; \
	fi
	if [ ! -d $(CLIBS_PATH)/svt_axi ]; then \
      mkdir -p $(CLIBS_PATH); \
      vlib $(CLIBS_PATH)/svt_axi; \
	fi
	if [ ! -f $(CLIBS_PATH)/svt_axi/_vmake ] || [ ! -z $(FORCE) ]; then \
      cd $(SIM_WORK_DIR); vlog -64 $(QUESTA_INI_ARG) -incr -mfcu -sv -work svt_axi -l clibs/vlog.svt_axi.log \
        -timescale=1ns/1ps \
        +define+SVT_EXCLUDE_METHODOLOGY_PKG_INCLUDE \
        -L uvm +incdir+$(UVM_HOME_questa) +define+QUESTA +define+SVT_COMMON_ENCRYPT \
        -f $(FW_ROOT)/common/vip/snps_amba_vip.f \
        $(FW_ROOT)/cpm6/common/dotf/svt_axi.sv \
        +incdir+$(FW_ROOT)/cpm6/common/dotf \
        +incdir+$(DESIGNWARE_HOME)/vip/svt/common/latest/sverilog/src/mti \
        +incdir+$(DESIGNWARE_HOME)/vip/svt/amba_svt/latest/sverilog/src/mti; \
	fi
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vlog.svt_axi.log,$(CLIBS_PATH)/vlog.svt_axi.log)
else ifeq ($(SIM),vcs)
	if [ ! -d $(CLIBS_PATH)/svt_axi ]; then \
      mkdir -p $(CLIBS_PATH)/svt_axi; \
	fi
	if [ ! -z $(FORCE) ]; then \
      rm -rf $(CLIBS_PATH)/svt_axi/*; \
	fi
	if [ ! -f $(CLIBS_PATH)/svt_axi/AN.DB/vloganopts.db ] || [ ! -z $(FORCE) ]; then \
      echo "pwd = `pwd`"; \
      cd $(SIM_WORK_DIR); vlogan -full64 -sverilog -work svt_axi -ntb_opts uvm-1.1 \
        -l clibs/vlogan.svt_axi.log \
        -f $(FW_ROOT)/common/vip/snps_amba_vip.f \
        $(FW_ROOT)/cpm6/common/dotf/svt_axi.sv \
        +incdir+$(FW_ROOT)/cpm6/common/dotf \
        +incdir+$(DESIGNWARE_HOME)/vip/svt/common/latest/sverilog/src/vcs \
        +incdir+$(DESIGNWARE_HOME)/vip/svt/amba_svt/latest/sverilog/src/vcs; \
	fi
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vlogan.svt_axi.log,$(CLIBS_PATH)/vlogan.svt_axi.log)
endif

# DESCRIPTION
# This will create the CPM6 SecureIP library for Questa and/or VCS. This target
# will only be called by super-users or innately and probably very infrequently.
#  - Questa Info
#    1. The library mapping should already be contained in the Questa .ini file
#   - VCS Info
#    1. The library mapping should already be contained in synopsys_sim.setup
# Internal decrypted SecureIP releases only ever ship filelist.f. The
# external (lounge) release gained a Vivado-2026.1-specific filelist once
# that Vivado version changed how the SIP sources are packaged, so detect
# it from the Vivado-generated compile.sh for the current sim work dir.
--create_cpm6_secip_clib : CPM6_SECIP_CMD_Q = vlog -64 -sv -mfcu -work cpm6_secip \
                                              -F $(SIP_PATH)/$(SIP_FILELIST) \
                                              -l clibs/vlog.cpm6_secip.log \
                                              -stats=+perf+verbose
--create_cpm6_secip_clib : CPM6_SECIP_CMD_S = vlogan -full64 -sverilog -work cpm6_secip \
                                              -F $(SIP_PATH)/$(SIP_FILELIST) \
                                              -timescale=1ns/1ps -kdb \
                                              -l clibs/vlogan.cpm6_secip.log
--create_cpm6_secip_clib: chk_sim chk_sim_work_dir chk_cpm6_secip_filelist
ifeq ($(SIM),questa)
	if [ ! -z $(FORCE) ]; then \
      rm -rf $(CLIBS_PATH)/cpm6_secip; \
	fi
	if [ ! -d $(CLIBS_PATH)/cpm6_secip ]; then \
      mkdir -p $(CLIBS_PATH); \
      vlib $(CLIBS_PATH)/cpm6_secip; \
	fi
ifeq ($(LSF),1)
	if [ ! -f $(CLIBS_PATH)/cpm6_secip/_vmake ] || [ ! -z $(FORCE) ]; then \
      rm -f $(CLIBS_PATH)/bsub.cpm6_secip.*; \
      echo "INFO: SUBMITTING THE CPM6 SECUREIP COMPILATION JOB TO LSF"; \
      cd $(SIM_WORK_DIR); \
      JOBID=$$(bsub -q short -app sil_rhel810 -e $(CLIBS_PATH)/bsub.cpm6_secip.err \
      -o $(CLIBS_PATH)/bsub.cpm6_secip.log \
      -R "rusage[mem=8GB]" \
      $(CPM6_SECIP_CMD_Q) | grep -o '[[:digit:]]*'); \
      sleep 10; \
      echo "INFO: JOB $$JOBID SUBMITTED"; \
      $(call check_lsf_job,cpm6_secip library compile,$(CLIBS_PATH)/bsub.cpm6_secip.err,$(CLIBS_PATH)/bsub.cpm6_secip.log); \
    fi
else
	cd $(SIM_WORK_DIR); eval $(CPM6_SECIP_CMD_Q)
endif
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vlog.cpm6_secip.log,$(CLIBS_PATH)/vlog.cpm6_secip.log)
else ifeq ($(SIM),vcs)
	if [ ! -d $(CLIBS_PATH)/cpm6_secip ]; then \
      mkdir -p $(CLIBS_PATH)/cpm6_secip; \
	fi
	if [ ! -z $(FORCE) ]; then \
      rm -rf $(CLIBS_PATH)/cpm6_secip/*; \
	fi
ifeq ($(LSF),1)
	if [ ! -f $(CLIBS_PATH)/cpm6_secip/AN.DB/vloganopts.db ] || [ ! -z $(FORCE) ]; then \
      rm -f $(CLIBS_PATH)/bsub.cpm6_secip.*; \
      echo "INFO: SUBMITTING THE CPM6 SECUREIP COMPILATION JOB TO LSF"; \
      cd $(SIM_WORK_DIR); \
      JOBID=$$(bsub -q short -app sil_rhel810 -e clibs/bsub.cpm6_secip.err \
      -o clibs/bsub.cpm6_secip.log \
      -R "rusage[mem=8GB]" \
      $(CPM6_SECIP_CMD_S) | grep -o '[[:digit:]]*'); \
      sleep 10; \
      echo "INFO: JOB $$JOBID SUBMITTED"; \
      $(call check_lsf_job,cpm6_secip library compile,clibs/bsub.cpm6_secip.err,clibs/bsub.cpm6_secip.log); \
    fi
else
	cd $(SIM_WORK_DIR); eval $(CPM6_SECIP_CMD_S)
endif
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vlogan.cpm6_secip.log,$(CLIBS_PATH)/vlogan.cpm6_secip.log)
endif

# DESCRIPTION
# This will compile a Vivado project into one or more libraries using
# one of two strategies:
# 1) if DUT_CLIBS==ONE -> compile everything into a single library
#    called "vivado_dut" using the the variables DUT_SV+DUT_INCD and 
#    DUT_VHDL, which are built by a different Makefile by slurping them 
#    out of compile.sh. 
# 2) if DUT_CLIBS==MANY -> compile everything into multiple libraries
#    by running an external script. This parses compile.sh and grabs the
#    library name, incdirs, and files and compiling into vivado_dut/<library>.
# -------------------------------------------------------------------------
# This is simply an alias target
--create_vivado_dut_clib: chk_sim $(CLIBS_PATH)/vivado_dut/PASS_SV \
                                  $(CLIBS_PATH)/vivado_dut/PASS_VHDL \
                                  $(CLIBS_PATH)/vivado_dut_KDB/PASS_SV \
                                  $(CLIBS_PATH)/vivado_dut_KDB/PASS_VHDL

$(CLIBS_PATH)/vivado_dut/PASS_SV: \
  VIVADO_DUT_CMD_Q = vlog -64 -sv -mfcu -stats=+perf+verbose \
                     -work vivado_dut \
                     $(foreach lib,$(VIV_CCLIBS),-L $(lib)) \
                     $(DUT_SV) $(DUT_INCD) \
                     -l clibs/vlog.vivado_dut.log
$(CLIBS_PATH)/vivado_dut/PASS_SV $(CLIBS_PATH)/vivado_dut_KDB/PASS_SV: \
  VIVADO_DUT_CMD_S = vlogan -full64 -sverilog \
                     -work vivado_dut \
                     $(DUT_SV) $(DUT_INCD) \
                     -l clibs/vlogan.vivado_dut.log
$(CLIBS_PATH)/vivado_dut/PASS_SV: $(PROJ_SIM_DIR)/compile.sh chk_sim_work_dir
ifneq ($(DUT_SV),)
ifeq ($(SIM),questa)
	if [ ! -d $(CLIBS_PATH)/vivado_dut ]; then \
      mkdir -p $(CLIBS_PATH); \
      if [ "$(DUT_CLIBS)" = "MANY" ]; then \
        mkdir -p $(CLIBS_PATH)/vivado_dut; \
      else \
        vlib $(CLIBS_PATH)/vivado_dut; \
      fi; \
	fi
ifeq ($(DUT_CLIBS),MANY)
	cd $(SIM_WORK_DIR); \
    $(FW_ROOT)/sim_common/vivado_dut_compile.bash $(notdir $(wildcard $(SIM_WORK_DIR)/*_compile.do)) $(SIM) -sv $(wordlist 1,5,$(VIVADO_DUT_CMD_Q))
else
	cd $(SIM_WORK_DIR); eval $(VIVADO_DUT_CMD_Q)
endif
	@tail -1 $(CLIBS_PATH)/vlog.vivado_dut.log | grep -q 'Errors: 0'
	if [ $$? -eq 0 ]; then \
      touch $(CLIBS_PATH)/vivado_dut/PASS_SV; \
	fi
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vlog.vivado_dut.log,$(CLIBS_PATH)/vlog.vivado_dut.log)
else ifeq ($(SIM),vcs)
ifeq ($(DEBUG),0)
# build vivado_dut library WITHOUT -kdb
	if [ ! -d $(CLIBS_PATH)/vivado_dut ]; then \
      mkdir -p $(CLIBS_PATH)/vivado_dut; \
	fi
ifeq ($(DUT_CLIBS),MANY)
	cd $(SIM_WORK_DIR); \
    $(FW_ROOT)/sim_common/vivado_dut_compile.bash compile.sh $(SIM) -sv $(wordlist 1,3,$(VIVADO_DUT_CMD_S)) 
else
	cd $(SIM_WORK_DIR); eval $(VIVADO_DUT_CMD_S)
endif
	@tail -1 $(CLIBS_PATH)/vlogan.vivado_dut.log | grep -q 'CPU time' 
	if [ $$? -eq 0 ]; then \
      touch $(CLIBS_PATH)/vivado_dut/PASS_SV; \
	fi
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vlogan.vivado_dut.log,$(CLIBS_PATH)/vlogan.vivado_dut.log)
endif
endif
endif

$(CLIBS_PATH)/vivado_dut_KDB/PASS_SV: $(PROJ_SIM_DIR)/compile.sh chk_sim_work_dir
ifneq ($(DUT_SV),)
ifeq ($(SIM),questa)
# do nothing
else ifeq ($(SIM),vcs)
ifeq ($(DEBUG),1)
# build vivado_dut library WITH -kdb
	if [ ! -d $(CLIBS_PATH)/vivado_dut_KDB ]; then \
      mkdir -p $(CLIBS_PATH)/vivado_dut_KDB; \
	fi
ifeq ($(DUT_CLIBS),MANY)
	$(call resolve_snps_sim_setup); \
    cd $(SIM_WORK_DIR); \
    $(FW_ROOT)/sim_common/vivado_dut_compile.bash compile.sh $(SIM) -sv $(wordlist 1,3,$(VIVADO_DUT_CMD_S)) -kdb 
else
	$(call resolve_snps_sim_setup); \
    cd $(SIM_WORK_DIR); \
    eval $(subst vivado_dut,vivado_dut_KDB,$(VIVADO_DUT_CMD_S)) -kdb
endif
	@tail -1 $(CLIBS_PATH)/vlogan.vivado_dut_KDB.log | grep -q 'CPU time' 
	if [ $$? -eq 0 ]; then \
      touch $(CLIBS_PATH)/vivado_dut_KDB/PASS_SV; \
	fi
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vlogan.vivado_dut_KDB.log,$(CLIBS_PATH)/vlogan.vivado_dut_KDB.log)
endif
endif
endif

$(CLIBS_PATH)/vivado_dut/PASS_VHDL: \
  VIVADO_DUT_CMD_Q = vcom -64 -stats=+perf+verbose \
                     -work vivado_dut $(DUT_VHDL) \
                     -l clibs/vcom.vivado_dut.log
$(CLIBS_PATH)/vivado_dut/PASS_VHDL $(CLIBS_PATH)/vivado_dut_KDB/PASS_VHDL: \
  VIVADO_DUT_CMD_S = vhdlan -full64 \
                     -work vivado_dut $(DUT_VHDL) \
                     -l clibs/vhdlan.vivado_dut.log
$(CLIBS_PATH)/vivado_dut/PASS_VHDL: $(PROJ_SIM_DIR)/compile.sh chk_sim_work_dir
ifneq ($(DUT_VHDL),)
ifeq ($(SIM),questa)
	if [ ! -d $(CLIBS_PATH)/vivado_dut ]; then \
      mkdir -p $(CLIBS_PATH); \
      if [ "$(DUT_CLIBS)" = "MANY" ]; then \
        mkdir -p $(CLIBS_PATH)/vivado_dut; \
      else \
        vlib $(CLIBS_PATH)/vivado_dut; \
      fi; \
	fi
ifeq ($(DUT_CLIBS),MANY)
	cd $(SIM_WORK_DIR); \
    $(FW_ROOT)/sim_common/vivado_dut_compile.bash $(notdir $(wildcard $(SIM_WORK_DIR)/*_compile.do)) $(SIM) -vhd $(wordlist 1,3,$(VIVADO_DUT_CMD_Q))
else
	cd $(SIM_WORK_DIR); eval $(VIVADO_DUT_CMD_Q)
endif
	@tail -1 $(CLIBS_PATH)/vcom.vivado_dut.log | grep -q 'Errors: 0'
	if [ $$? -eq 0 ]; then \
      touch $(CLIBS_PATH)/vivado_dut/PASS_VHDL; \
	fi
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vcom.vivado_dut.log,$(CLIBS_PATH)/vcom.vivado_dut.log)
else ifeq ($(SIM),vcs)
ifeq ($(DEBUG),0)
# build vivado_dut library WITHOUT -kdb
	if [ ! -d $(CLIBS_PATH)/vivado_dut ]; then \
      mkdir -p $(CLIBS_PATH)/vivado_dut; \
	fi
ifeq ($(DUT_CLIBS),MANY)
	cd $(SIM_WORK_DIR); \
    $(FW_ROOT)/sim_common/vivado_dut_compile.bash compile.sh $(SIM) -vhd $(wordlist 1,2,$(VIVADO_DUT_CMD_S)) 
else
	cd $(SIM_WORK_DIR); eval $(VIVADO_DUT_CMD_S)
endif
	@tail -1 $(CLIBS_PATH)/vhdlan.vivado_dut.log | grep -q 'Parsing' 
	if [ $$? -eq 0 ]; then \
      touch $(CLIBS_PATH)/vivado_dut/PASS_VHDL; \
	fi
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vhdlan.vivado_dut.log,$(CLIBS_PATH)/vhdlan.vivado_dut.log)
endif
endif
endif

$(CLIBS_PATH)/vivado_dut_KDB/PASS_VHDL: $(PROJ_SIM_DIR)/compile.sh chk_sim_work_dir
ifneq ($(DUT_VHDL),)
ifeq ($(SIM),questa)
# do nothing
else ifeq ($(SIM),vcs)
ifeq ($(DEBUG),1)
# build vivado_dut library WITH -kdb
	if [ ! -d $(CLIBS_PATH)/vivado_dut_KDB ]; then \
      mkdir -p $(CLIBS_PATH)/vivado_dut_KDB; \
	fi
ifeq ($(DUT_CLIBS),MANY)
	$(call resolve_snps_sim_setup); \
    cd $(SIM_WORK_DIR); \
    $(FW_ROOT)/sim_common/vivado_dut_compile.bash compile.sh $(SIM) -vhd $(wordlist 1,2,$(VIVADO_DUT_CMD_S)) -kdb 
else
# No idea why this command returns an error code, so just ignore it
	-$(call resolve_snps_sim_setup); \
    cd $(SIM_WORK_DIR); \
    eval $(subst vivado_dut,vivado_dut_KDB,$(VIVADO_DUT_CMD_S)) -kdb
endif
	@tail -1 $(CLIBS_PATH)/vhdlan.vivado_dut_KDB.log | grep -q 'Parsing' 
	if [ $$? -eq 0 ]; then \
      touch $(CLIBS_PATH)/vivado_dut_KDB/PASS_VHDL; \
	fi
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vhdlan.vivado_dut_KDB.log,$(CLIBS_PATH)/vhdlan.vivado_dut_KDB.log)
endif
endif
endif

# Pick and choose some agents from the uvma-agents repo (can overrwrite)
UVMA_AGENTS?=base cxl_nfi cxl_credit reset gpmon gpdrv elbi aximon
UVMA_AGENTS_CMD=$(foreach agnt,$(UVMA_AGENTS),-F $(_UVMA_AGENT_PATH)/$(agnt)_agent/$(agnt).F)
--create_uvma_clib: chk_sim chk_uvm_vars chk_sim_work_dir
	@$(MAKE) PREQ=uvm PREQ_TGT=uvm --no-print-directory -- --check_clibs_prereq
	@if [ ! -d $(_UVMA_AGENT_PATH) ]; then \
      echo "FATAL: $(_UVMA_AGENT_PATH) does not resolve to a directory"; \
      exit 1; \
	fi
ifeq ($(SIM),questa)
	if [ ! -z $(FORCE) ]; then \
      rm -rf $(CLIBS_PATH)/uvma_agents; \
	fi
	if [ ! -d $(CLIBS_PATH)/uvma_agents ]; then \
      mkdir -p $(CLIBS_PATH); \
      vlib $(CLIBS_PATH)/uvma_agents; \
	fi
	if [ ! -f $(CLIBS_PATH)/uvma_agents/_vmake ] || [ ! -z $(FORCE) ]; then \
      cd $(SIM_WORK_DIR); \
      vlog -64 -incr -mfcu -sv -work uvma_agents -l clibs/vlog.uvma_agents.log \
        -timescale=1ns/1ps \
        +define+TIME_BASE_PKG \
        +define+TIMEUNIT_BASE_PKG=1ps \
        +define+TIMEPREC_BASE_PKG=1ps \
        -L uvm +incdir+$(UVM_HOME_questa) $(UVMA_AGENTS_CMD); \
	fi
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vlog.uvma_agents.log,$(CLIBS_PATH)/vlog.uvma_agents.log)
else ifeq ($(SIM),vcs)
	if [ ! -d $(CLIBS_PATH)/uvma_agents ]; then \
      mkdir -p $(CLIBS_PATH)/uvma_agents; \
	fi
	if [ ! -z $(FORCE) ]; then \
      rm -rf $(CLIBS_PATH)/uvma_agents/*; \
	fi
	if [ ! -f $(CLIBS_PATH)/uvma_agents/AN.DB/vloganopts.db ] || [ ! -z $(FORCE) ]; then \
      cd $(SIM_WORK_DIR); \
      vlogan -full64 -sverilog -work uvma_agents -ntb_opts uvm-1.1 \
        -l clibs/vlogan.uvma_agents.log \
        -timescale=1ns/1ps -kdb \
        +define+TIME_BASE_PKG \
        +define+TIMEUNIT_BASE_PKG=1ps \
        +define+TIMEPREC_BASE_PKG=1ps \
        $(UVMA_AGENTS_CMD); \
	fi
	$(call safe_move,$(SIM_WORK_DIR)/clibs/vlogan.uvma_agents.log,$(CLIBS_PATH)/vlogan.uvma_agents.log)
endif

# ----------------------------------------------------------------------------
# Regression targets
#   sregr : simulate regression suite
#   clnregr : clean all regression runs
#   lsregr : list all regression testlists
#   regr : runs all steps; analgous to c; o; sregr
# 
#  Set `TESTLISTS_REGR_DIR` in your local makefile equal to your pvs-ip path
#   that holds your regression files.
#  Pass `TESTLIST` with your intended regression testlist
#  
# ----------------------------------------------------------------------------
# Create or use old regression directory: must start with "regr_"
ifdef REGR_DIR
 ifeq ($(REGR_DIR),LATEST)
  NREGR_DIR:=$(shell ls -d -ltu regr_* | awk '{print $$9}' | head -n 1)
 else
  NREGR_DIR:=$(REGR_DIR)
 endif
else
 NREGR_DIR:=regr_$(shell date +"%m%d%y_%Hh%Mm%Ss")
endif

# Compile, optimize, and run regression with optional YAML defines
regr: SHELL := /bin/bash
regr:
ifndef TESTLIST
	@echo "ERROR: Must pass TESTLIST=<name> to $@ target"
else
	@if ! YAML_DEFINES=$$($(PARSE_REGR_YAML) $(TL) --mode defines); then \
		exit 1; \
	fi; \
	if [ -n "$$YAML_DEFINES" ] && [ -n "$(DEFINES)" ]; then \
		COMBINED="$$YAML_DEFINES,$(DEFINES)"; \
	elif [ -n "$$YAML_DEFINES" ]; then \
		COMBINED="$$YAML_DEFINES"; \
	elif [ -n "$(DEFINES)" ]; then \
		COMBINED="$(DEFINES)"; \
	else \
		COMBINED=""; \
	fi; \
	if [ -n "$$COMBINED" ]; then \
		echo "INFO: Compiling with defines: $$COMBINED"; \
		$(MAKE) c DEFINES="$$COMBINED" --no-print-directory; \
	else \
		$(MAKE) c --no-print-directory; \
	fi; \
	$(MAKE) o --no-print-directory; \
	$(MAKE) sregr TESTLIST=$(TESTLIST) --no-print-directory
endif

# Default to testlists_regr if TESTLISTS_REGR_DIR is not set
TESTLISTS_REGR_DIR ?= testlists_regr

# Look for testlist: first try TESTLISTS_REGR_DIR with .yaml suffix,
# then fall back to literal path
ifneq ($(wildcard $(TESTLISTS_REGR_DIR)/$(TESTLIST).yaml),)
 TL=$(TESTLISTS_REGR_DIR)/$(TESTLIST).yaml
else
 TL=$(TESTLIST)
endif

PARSELOG := $(FW_ROOT)/sim_common/sim_parselog.py
PARSE_REGR_YAML := $(FW_ROOT)/sim_common/parse_regr_yaml.py

# sregr simulator-specific settings
ifeq ($(SIM),questa)
 SREGR_SIM_CMD = vsim -64 -batch $(VSIM_SUPPRESS) -work ../../work tb_top_opt \
                 $(QUESTA_INI_ARG) \
                 $(VIP_LIBS_CMD) $(DUT_LIBS_CMD) \
                 -permit_unmatched_virtual_intf \
                 -pli $(AVERY_PLI)/lib.linux/libtb_ms64.a \
                 -do "run -all; quit -f"
 SREGR_SEED_FLAG = -sv_seed$(spc)
 SREGR_LOGFILE = questa.vsim.log
 SREGR_SIM_CHECK = work/tb_top_opt
 SREGR_SIM_LABEL = questa
else ifeq ($(SIM),vcs)
 SREGR_SIM_CMD = ../../simv -no_save -ucli -reportstats -licqueue -licwait 1 -do ../uclirun.do
 SREGR_SEED_FLAG = +ntb_random_seed=
 SREGR_LOGFILE = vcsrun.log
 SREGR_SIM_CHECK = simv
 SREGR_SIM_LABEL = vcs
endif

sregr: SHELL := /bin/bash
sregr: chk_sim_work_dir chk_questa_ini
sregr:
ifndef TESTLIST
	@echo "ERROR: Must pass TESTLIST=<name> to $@ target"
else
	@if [ ! -e $(SIM_WORK_DIR)/$(SREGR_SIM_CHECK) ]; then \
		echo "ERROR: Simulation executable does not exist; run 'make c; make o' first"; \
		exit 1; \
	fi
	@if [ ! -d $(SIM_WORK_DIR)/$(NREGR_DIR) ]; then mkdir -p $(SIM_WORK_DIR)/$(NREGR_DIR); fi
	@if [ ! -f $(TL) ]; then \
		echo "ERROR: Testlist $(TL) does not exist"; \
		exit 1; \
	fi
	@set -e; \
	TMP_PARSED=$$(mktemp /tmp/regr_parsed.XXXXXX); \
	$(PARSE_REGR_YAML) $(TL) > $$TMP_PARSED || { rm -f $$TMP_PARSED; exit 1; }; \
	cd $(SIM_WORK_DIR); \
	for f in *.cdo *.mem; do \
		if [ -f "$$f" ] && [ ! -e "$(NREGR_DIR)/$$f" ]; then \
			ln -sf "../$$f" "$(NREGR_DIR)/$$f"; \
		fi; \
	done; \
	if [ -d "cdo" ] && [ ! -e "$(NREGR_DIR)/cdo" ]; then \
		ln -sf "../cdo" "$(NREGR_DIR)/cdo"; \
	fi; \
	if [ "$(SIM)" = "vcs" ]; then echo "run" > $(NREGR_DIR)/uclirun.do; fi; \
	SIM_CMD="$(SREGR_SIM_CMD)"; \
	rand=$$((RANDOM)); \
	TOTAL_TESTS=0; \
	RUNDIRS=""; \
	SIM_TIMEOUT_MIN=$$(( $(REGR_TIMEOUT) / 60 )); \
	logfile=$(SREGR_LOGFILE); \
	echo "INFO: Launching all sims now"; \
	while IFS=$$'\t' read testname iter test_plusargs; do \
		echo "INFO: Regression Tests | testname=$$testname, iter=$$iter"; \
		while [ $$iter -gt 0 ]; do \
			TOTAL_TESTS=$$((TOTAL_TESTS+1)); \
			seed=$$((((RANDOM<<17)|(RANDOM<<2)|(RANDOM&3)))); \
			rundir=$$testname.$$seed; \
			RUNDIRS="$$RUNDIRS $$rundir"; \
			FULL_CMD="$$SIM_CMD \
				$(SREGR_SEED_FLAG)$$seed \
				-l $$logfile \
				+BASE_PATH=../../cdo \
				+UVM_TESTNAME=$$testname \
				+UVM_VERBOSITY=UVM_$(VERBOSITY) \
				$(SIM_SO_LIBS) $(SIM_EXTRA) $(PARG) $$test_plusargs"; \
			if [ "$(LSF)" != "1" ]; then \
				mkdir $(NREGR_DIR)/$$rundir; \
				cd $(NREGR_DIR)/$$rundir; \
				timeout $(REGR_TIMEOUT) bash -c "$${FULL_CMD}" > /dev/null 2>&1 & \
				cd ../..; \
			else \
				echo "#!/bin/bash" > $(NREGR_DIR)/job$$rand.$$TOTAL_TESTS; \
				echo "mkdir $$rundir" >> $(NREGR_DIR)/job$$rand.$$TOTAL_TESTS; \
				echo "cd $$rundir" >> $(NREGR_DIR)/job$$rand.$$TOTAL_TESTS; \
				echo "$$FULL_CMD" >> $(NREGR_DIR)/job$$rand.$$TOTAL_TESTS; \
				chmod 755 $(NREGR_DIR)/job$$rand.$$TOTAL_TESTS; \
			fi; \
			iter=$$((iter-1)); \
		done; \
	done < $$TMP_PARSED; \
	rm -f $$TMP_PARSED; \
	if [ "$(LSF)" != "1" ]; then \
		echo "INFO: Launched $$TOTAL_TESTS sims that run locally"; \
	else \
		echo "INFO: Launching $$TOTAL_TESTS sims on LSF"; \
		cd $(NREGR_DIR); \
		bsub -J "$$rand[1-$$TOTAL_TESTS]" -W $$SIM_TIMEOUT_MIN \
			-app sil_rhel810 -R "rusage[mem=2GB]" \
			-o bsub.%J.%I.output.log -e bsub.%J.%I.error.log \
			job$$rand.\$$LSB_JOBINDEX; \
		sleep 10; \
		cd ..; \
	fi; \
	echo "INFO: Waiting until all sims are complete"; \
	TIME=0; H=0; M=0; S=0; \
	if [ "$(LSF)" != "1" ]; then \
		wait $$(jobs -rp); \
		echo "INFO: All sims are complete"; \
	else \
		nactive=$$TOTAL_TESTS; \
		max_exit=0; \
		while [ "$$nactive" -gt 0 ]; do \
			sleep 5; \
			TIME=$$((TIME+5)); \
			H=$$((TIME/3600)); \
			M=$$(((TIME - H * 3600) / 60)); \
			S=$$((TIME - H * 3600 - M * 60)); \
			nactive=$$(bjobs -J "$$rand" -noheader 2>/dev/null | wc -l); \
			njobs=$$((TOTAL_TESTS - nactive)); \
			nexit=$$(bjobs -a -J "$$rand" -noheader 2>/dev/null | grep -c 'EXIT' || true); \
			[ "$$nexit" -gt "$$max_exit" ] && max_exit=$$nexit; \
			nexit=$$max_exit; \
			ndone=$$((njobs - nexit)); \
			if [[ $$H -eq 0 && $$M -eq 0 && $$((S % 10)) -eq 0 ]]; then \
				printf "INFO: %1d:%02d:%02d | %d/%d completed: %d DONE, %d EXIT\n" \
					$$H $$M $$S $$njobs $$TOTAL_TESTS $$ndone $$nexit; \
			elif [[ $$H -eq 0 && $$M -le 5 && $$S -eq 0 ]]; then \
				printf "INFO: %1d:%02d:%02d | %d/%d completed: %d DONE, %d EXIT\n" \
					$$H $$M $$S $$njobs $$TOTAL_TESTS $$ndone $$nexit; \
			elif [[ $$H -eq 0 && $$((M % 10)) -eq 0 && $$S -eq 0 ]]; then \
				printf "INFO: %1d:%02d:%02d | %d/%d completed: %d DONE, %d EXIT\n" \
					$$H $$M $$S $$njobs $$TOTAL_TESTS $$ndone $$nexit; \
			elif [[ $$H -ne 0 && $$((M % 15)) -eq 0 && $$S -eq 0 ]]; then \
				printf "INFO: %1d:%02d:%02d | %d/%d completed: %d DONE, %d EXIT\n" \
					$$H $$M $$S $$njobs $$TOTAL_TESTS $$ndone $$nexit; \
			fi; \
		done; \
		printf "INFO: %1d:%02d:%02d | %d/%d completed: %d DONE, %d EXIT\n" \
			$$H $$M $$S $$njobs $$TOTAL_TESTS $$ndone $$nexit; \
	fi; \
	echo "INFO: Collecting regression results"; \
	SUMMARY_FILE=SUMMARY_$$(date +"%m%d%y_%Hh%Mm%Ss"); \
	echo "JOB ARRAY: $$rand" >> $(NREGR_DIR)/$$SUMMARY_FILE; \
	echo "TESTLIST: $(TESTLIST)" >> $(NREGR_DIR)/$$SUMMARY_FILE; \
	cd $(NREGR_DIR); \
	for rundir in $$RUNDIRS; do \
		echo -n "  " >> $$SUMMARY_FILE; \
		$(PARSELOG) $(SREGR_SIM_LABEL) $$rundir/$$logfile $$SUMMARY_FILE; \
	done; \
	cd ..; \
	echo "INFO: Regression results in file $(SIM_WORK_DIR)/$(NREGR_DIR)/$$SUMMARY_FILE"; \
	PASS_CNT=$$(grep -c 'PASS' $(NREGR_DIR)/$$SUMMARY_FILE || true); \
	echo "REGRESSION SUMMARY: $$PASS_CNT/$$TOTAL_TESTS PASSED"
endif

clnregr: TESTS=$(shell find $(NREGR_DIR) -maxdepth 1 -type d -name "*[[:digit:]]" -printf '%f ')
clnregr: chk_sim_work_dir
clnregr:
ifdef REGR_DIR
	@echo "INFO: Cleaning all simulation test data from $(NREGR_DIR); can still run regression"
	@cd $(SIM_WORK_DIR)/$(NREGR_DIR); \
    rm -f bsub* SUMMARY* job*; \
    rm -rf $(TESTS)
else
	@echo "INFO: Cleaning ALL regression data"
	cd $(SIM_WORK_DIR); \
	rm -rf regr_*
endif

lsregr:
	@echo -e "***************************************************************************************"
	@echo -e "*** Potential testlists to run, listed from directory: $(TESTLISTS_REGR_DIR)"
	@echo -e "*** Specify using TESTLIST argument when running sregr target"
	@echo -e "***************************************************************************************"
	@ls $(TESTLISTS_REGR_DIR)/*.yaml 2>/dev/null | xargs -n1 basename | sed 's/\.yaml$$//; s/^/\* /'
