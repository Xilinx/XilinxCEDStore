# -----------------------------------------------------------------------------
# All parent Makefiles should have this common code and agent-specific defaults
# -----------------------------------------------------------------------------
ifdef TEST
 PRINT_DESC = 1
endif
TEST = issue_test
SIM = questa
COMP_FILES = -F ../elbi.F 
ROOT_PATH = ../..
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Specific variables that define commands that are dependent on the above
# -----------------------------------------------------------------------------
ifeq ($(SIM),questa)
 GUI_DO = log -r /tb_top/*; do dofile/elbi.do;
 GUI_DO += run -a
endif

# -----------------------------------------------------------------------------
# All targets are captured here in the template
# -----------------------------------------------------------------------------
include $(ROOT_PATH)/common/Makefile.sim
