# This Makefile is designed to work only within a testcase's root directory.
# Thus it can be softlinked, copied, or include-d to said directory; also
# could by called with $> make -f <this-file>. If it needs to be modified,
# then copy it or include it with variables being set first.

# Select simulator
SIM?={{?sim}}
# Vivado project root is down one level (if many found, choose by 'sort' result)
PROJ_ROOT:=$(firstword $(shell find ./ -maxdepth 2 -type f -name "*.xpr" -exec dirname {} \; | sed 's/.\///' | sort -n))
# Vivado project sim directory is in project root
PROJ_SIM_DIR:=$(shell find $(PROJ_ROOT) -type f -name "compile.sh" -and -path "*/behav/$(SIM)/*" -exec dirname {} \;)
# Testcase parent is this directory
TESTCASE_ROOT:=$(shell pwd)
# uvma-pcie-sim-framework root (if present)
ifneq ($(wildcard $(TESTCASE_ROOT)/uvma-pcie-sim-framework),)
 FW_ROOT:=$(TESTCASE_ROOT)/uvma-pcie-sim-framework
endif

# Set relevant variables for a Vivado testcase that next Makefile needs
ifdef FW_ROOT
 include $(FW_ROOT)/sim_common/Makefile.testcase_vars
endif

# Project specific 
# - Configure link connections in TB
# - Vivado doesn't currently output CPM6 SecureIP with compile_simlib
ifeq ($(SIM),questa)
 OPT_EXTRA := -G tb_top/LINK1_WIDTH=8 -G tb_top/LINK0_WIDTH=0
 # ATTN : Must download CPM6 SecureIP from the AMD lounge and set this
 SIP_PATH := /path/to/downloaded/cpm6/secureip 
else ifeq ($(SIM),vcs)
 OPT_EXTRA := -pvalue tb_top.LINK1_WIDTH=8 -pvalue tb_top.LINK0_WIDTH=0
 # ATTN : Vivado delivers the CPM6 SecureIP natively when compiling the
 #        libs, so this is only necessary for internal users for debug
 SIP_PATH := /path/to/debug/cpm6/secureip 
endif

# Number of CPI interfaces generated in this design
NUM_CPI?={{?num_cpi}}

# Define CPI_INST_<n> for each generated datapath so byoc_int_insert.sv only
# binds into instances that exist. Appended to any user-supplied DEFINES.
empty:=
space:=$(empty) $(empty)
comma:=,
CPI_DEFS:=$(foreach n,$(wordlist 1,$(NUM_CPI),0 1 2 3),CPI_INST_$(n))
override DEFINES:=$(subst $(space),$(comma),$(strip \
  $(subst $(comma),$(space),$(DEFINES)) $(CPI_DEFS)))

# Base tests that only exist to be extended; hide them from "make lst"
override TEST_BLACKLIST := base_ced_test base_cpi_cmds_test

# The core Makefile is here; just plug into it
ifneq ($(FW_SIM_DIR),)
 include $(FW_SIM_DIR)/Makefile
endif

