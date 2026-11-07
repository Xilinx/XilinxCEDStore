# -----------------------------------------------------------------------------
# All parent Makefiles should have this common code and agent-specific defaults
# -----------------------------------------------------------------------------
ifdef TEST
 PRINT_DESC = 1
endif
TEST = full_test
SIM = questa
COMP_FILES = -F ../cxl_credit.F 
ROOT_PATH = ../..
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Specific variables that define commands that are dependent on the above
# -----------------------------------------------------------------------------
ifeq ($(SIM),questa)
 GUI_DO = log /tb_top/vld; \
          log /tb_top/req_prot; log /tb_top/req_crd; \
          log /tb_top/dat_prot; log /tb_top/dat_crd; \
          log /tb_top/rsp_prot; log /tb_top/rsp_crd;
 GUI_DO += do sigs.do;
 ifeq ($(GUI),2)
  GUI_DO += run -a;
 endif
endif

# -----------------------------------------------------------------------------
# All targets are captured here in the template
# -----------------------------------------------------------------------------
include $(ROOT_PATH)/common/Makefile.sim
